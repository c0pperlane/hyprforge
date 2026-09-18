pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.config

// Weather, keyed by location query.
//
// Each distinct query gets its own record, so two weather widgets can show two
// cities without fighting over one shared location (which is exactly what the
// first cut did). A blank query means "here", resolved by IP geolocation.
//
// Providers are the same ones the caelestia shell already uses - ip-api.com for
// the coarse lookup and open-meteo for the forecast - with ipapi.co as a second
// chance, since ip-api rate-limits at 45 requests/minute per IP and returns a
// plain failure when it does. The resolved coordinates are cached on disk, so a
// restart doesn't re-ask anybody where you are.
Singleton {
    id: root

    // Records are replaced wholesale on every change, never mutated in place.
    //
    // The earlier version mutated `records` and bumped a `revision` counter
    // that getters read as `void root.revision;` to register a dependency. That
    // works right up until the QML compiler decides a discarded expression is
    // dead code and removes it - at which point every widget silently freezes
    // on whatever it read first, with nothing in the logs. Reassigning the
    // object makes recordsChanged fire for real, and the getter's dependency is
    // an ordinary property read that nothing can optimise away.
    property var records: ({})

    property real autoLat: NaN
    property real autoLon: NaN
    property string autoName: ""
    property bool locating: false
    property string locateError: ""

    readonly property bool located: !isNaN(root.autoLat) && !isNaN(root.autoLon)

    function blank(query: string): var {
        return {
            query: query,
            name: "",
            lat: NaN,
            lon: NaN,
            loading: false,
            error: "",
            permanent: false,
            temperature: NaN,
            apparent: NaN,
            high: NaN,
            low: NaN,
            sunrise: "",
            sunset: "",
            code: -1,
            wind: 0,
            humidity: 0,
            precipChance: 0,
            isDay: true,
            hourly: [],
            fetchedAt: 0
        };
    }

    // Pure read - safe to call from a binding. Returns a blank record for a
    // query nobody has registered yet, so widgets never see undefined.
    function get(query: string): var {
        const key = (query ?? "").trim();
        const all = root.records;
        return all[key] ?? root.blank(key);
    }

    // Registers a query and starts fetching it. Widgets call this from
    // onCompleted and whenever their location prop changes - deliberately not
    // from get(), because mutating state inside a binding evaluation is how you
    // get half-built records handed back to the caller.
    // Registration and fetching are deliberately separate.
    //
    // A widget calls ensure() from Component.onCompleted, which runs *before*
    // the host's binding has marked it live - so gating the whole call on
    // demand meant the fetch was skipped and, since the key was then never
    // re-registered, never retried. Registering always and fetching on demand
    // fixes the ordering: whichever happens second triggers the request.
    function ensure(query: string): void {
        const key = (query ?? "").trim();
        if (!root.records.hasOwnProperty(key)) {
            const next = Object.assign({}, root.records);
            next[key] = root.blank(key);
            root.records = next;
        }
        root.maybeResolve(key);
    }

    readonly property bool wanted: Demand.needed("weather")

    onWantedChanged: {
        if (!root.wanted)
            return;
        for (const key of Object.keys(root.records))
            root.maybeResolve(key);
    }

    // Fetches only if something is displaying weather and this record has no
    // data yet and nothing is already in flight for it.
    function maybeResolve(key: string): void {
        if (!root.wanted)
            return;
        const r = root.records[key];
        if (!r || r.fetchedAt > 0 || r.error)
            return;
        root.resolve(key);
    }

    function update(key: string, patch: var): void {
        const next = Object.assign({}, root.records);
        next[key] = Object.assign({}, next[key] ?? root.blank(key), patch);
        root.records = next;

        // A failure at login - which is the common case, because the shell
        // starts before the network is up - used to sit there until the
        // quarter-hourly refresh came round. Back off and try again instead.
        //
        // Only for transient failures: retrying a name the geocoder has never
        // heard of will get the same answer five times and waste the budget.
        if (patch.error && !patch.permanent)
            root.scheduleRetry(key);
        else if (patch.error === "")
            root.retries[key] = 0;
    }

    property var retries: ({})
    readonly property var retryDelays: [8000, 20000, 45000, 120000, 300000]

    function scheduleRetry(key: string): void {
        const n = root.retries[key] ?? 0;
        if (n >= root.retryDelays.length)
            return; // give up until the periodic refresh
        root.retries[key] = n + 1;
        retryTimer.queue(key, root.retryDelays[n]);
    }

    function request(url: string, onOk: var, onFail: var): void {
        const xhr = new XMLHttpRequest();
        xhr.onreadystatechange = () => {
            if (xhr.readyState !== XMLHttpRequest.DONE)
                return;
            if (xhr.status !== 200) {
                if (onFail)
                    onFail(`http ${xhr.status || "error"}`);
                return;
            }
            try {
                onOk(JSON.parse(xhr.responseText));
            } catch (e) {
                if (onFail)
                    onFail(`bad response`);
            }
        };
        xhr.open("GET", url);
        xhr.send();
    }

    // --- geolocation ------------------------------------------------------

    // Callers waiting on an in-flight lookup. Early-returning when `locating`
    // was already true used to drop the callback on the floor, leaving that
    // record stuck on "locating…" forever.
    property var pendingLocates: []

    function locate(done: var): void {
        if (root.located) {
            done(true);
            return;
        }

        root.pendingLocates = root.pendingLocates.concat([done]);
        if (root.locating)
            return;

        root.locating = true;

        const settle = ok => {
            const waiting = root.pendingLocates;
            root.pendingLocates = [];
            root.locating = false;
            for (const cb of waiting)
                cb(ok);
        };

        const finish = (lat, lon, name) => {
            root.autoLat = lat;
            root.autoLon = lon;
            root.autoName = name ?? "";
            root.locateError = "";
            geoCache.write();
            settle(true);
        };

        // ipapi.co is the fallback: ip-api.com is plain HTTP and rate-limits
        // at 45/min, which a desktop that restarts its shell a lot can hit.
        const tryIpapiCo = why => {
            root.request("https://ipapi.co/json/", json => {
                if (json && json.latitude !== undefined)
                    finish(json.latitude, json.longitude, json.city);
                else {
                    root.locateError = why || "could not locate";
                    settle(false);
                }
            }, err => {
                root.locateError = why || err;
                settle(false);
            });
        };

        root.request("http://ip-api.com/json?fields=status,message,city,lat,lon", json => {
            if (json.status === "success")
                finish(json.lat, json.lon, json.city);
            else
                tryIpapiCo(json.message);
        }, err => tryIpapiCo(err));
    }

    // --- resolution + fetch ----------------------------------------------

    function resolve(key: string): void {
        const q = key.trim();

        // "52.5,13.4" - explicit coordinates, no lookup needed.
        const coords = q.match(/^\s*(-?\d+(?:\.\d+)?)\s*,\s*(-?\d+(?:\.\d+)?)\s*$/);
        if (coords) {
            root.update(key, {
                lat: parseFloat(coords[1]),
                lon: parseFloat(coords[2]),
                name: q
            });
            root.fetch(key);
            return;
        }

        if (!q) {
            root.update(key, {
                loading: true,
                error: ""
            });
            root.locate(ok => {
                if (!ok) {
                    root.update(key, {
                        loading: false,
                        error: root.locateError || "location unavailable"
                    });
                    return;
                }
                root.update(key, {
                    lat: root.autoLat,
                    lon: root.autoLon,
                    name: root.autoName
                });
                root.fetch(key);
            });
            return;
        }

        root.update(key, {
            loading: true,
            error: "",
            permanent: false
        });
        root.request(`https://geocoding-api.open-meteo.com/v1/search?name=${encodeURIComponent(q)}&count=1&format=json`, json => {
            const hit = (json.results ?? [])[0];
            if (!hit) {
                root.update(key, {
                    loading: false,
                    error: "no such place",
                    permanent: true
                });
                return;
            }
            root.update(key, {
                lat: hit.latitude,
                lon: hit.longitude,
                name: hit.name
            });
            root.fetch(key);
        }, err => root.update(key, {
                loading: false,
                error: err
            }));
    }

    function fetch(key: string): void {
        const r = root.records[key];
        if (!r || isNaN(r.lat) || isNaN(r.lon))
            return;

        const url = `https://api.open-meteo.com/v1/forecast?latitude=${r.lat}&longitude=${r.lon}` + "&current=temperature_2m,apparent_temperature,relative_humidity_2m,is_day,weather_code,wind_speed_10m,precipitation_probability" + "&hourly=temperature_2m,weather_code,precipitation_probability" + "&daily=temperature_2m_max,temperature_2m_min,sunrise,sunset&forecast_days=2&timezone=auto";

        root.request(url, json => {
            const c = json.current ?? ({});
            const d = json.daily ?? ({});
            const h = json.hourly ?? ({});

            const now = new Date();
            const hourly = [];
            for (let i = 0; i < (h.time ?? []).length; i++) {
                const t = new Date(h.time[i].replace("T", " "));
                if (t < now)
                    continue;
                hourly.push({
                    hour: t.getHours(),
                    temp: h.temperature_2m[i],
                    code: h.weather_code[i],
                    precip: (h.precipitation_probability ?? [])[i] ?? 0,
                    day: t.getHours() >= 7 && t.getHours() < 20
                });
                if (hourly.length >= 12)
                    break;
            }

            root.update(key, {
                loading: false,
                error: "",
                temperature: c.temperature_2m ?? NaN,
                apparent: c.apparent_temperature ?? NaN,
                humidity: c.relative_humidity_2m ?? 0,
                code: c.weather_code ?? -1,
                wind: c.wind_speed_10m ?? 0,
                precipChance: c.precipitation_probability ?? 0,
                isDay: (c.is_day ?? 1) === 1,
                high: (d.temperature_2m_max ?? [])[0] ?? NaN,
                low: (d.temperature_2m_min ?? [])[0] ?? NaN,
                sunrise: (d.sunrise ?? [])[0] ?? "",
                sunset: (d.sunset ?? [])[0] ?? "",
                hourly: hourly,
                fetchedAt: Date.now()
            });
        }, err => root.update(key, {
                loading: false,
                error: err
            }));
    }

    function refreshAll(): void {
        root.retries = ({});
        for (const key of Object.keys(root.records)) {
            const r = root.records[key];
            if (isNaN(r.lat) || isNaN(r.lon))
                root.resolve(key);
            else
                root.fetch(key);
        }
    }

    // Force a fresh IP lookup - the "my location is wrong" escape hatch.
    function relocate(): void {
        root.autoLat = NaN;
        root.autoLon = NaN;
        root.autoName = "";
        root.locateError = "";
        root.locate(() => root.refreshAll());
    }

    // --- presentation helpers --------------------------------------------

    function describe(c: int, day: bool): var {
        const d = day ?? true;
        const map = {
            0: [d ? "clear_day" : "clear_night", "Clear"],
            1: [d ? "clear_day" : "clear_night", "Mostly clear"],
            2: [d ? "partly_cloudy_day" : "partly_cloudy_night", "Partly cloudy"],
            3: ["cloud", "Overcast"],
            45: ["foggy", "Fog"],
            48: ["foggy", "Rime fog"],
            51: ["rainy_light", "Light drizzle"],
            53: ["rainy", "Drizzle"],
            55: ["rainy_heavy", "Heavy drizzle"],
            56: ["weather_mix", "Freezing drizzle"],
            57: ["weather_mix", "Freezing drizzle"],
            61: ["rainy_light", "Light rain"],
            63: ["rainy", "Rain"],
            65: ["rainy_heavy", "Heavy rain"],
            66: ["weather_mix", "Freezing rain"],
            67: ["weather_mix", "Freezing rain"],
            71: ["weather_snowy", "Light snow"],
            73: ["snowing", "Snow"],
            75: ["snowing_heavy", "Heavy snow"],
            77: ["grain", "Snow grains"],
            80: ["rainy_light", "Showers"],
            81: ["rainy", "Showers"],
            82: ["rainy_heavy", "Violent showers"],
            85: ["weather_snowy", "Snow showers"],
            86: ["snowing_heavy", "Snow showers"],
            95: ["thunderstorm", "Thunderstorm"],
            96: ["thunderstorm", "Thunderstorm, hail"],
            99: ["thunderstorm", "Thunderstorm, hail"]
        };
        const e = map[c];
        return {
            icon: e ? e[0] : "cloud",
            label: e ? e[1] : "—"
        };
    }

    function temp(c: real, imperial: bool): string {
        if (isNaN(c))
            return "—";
        return imperial ? `${Math.round(c * 9 / 5 + 32)}°` : `${Math.round(c)}°`;
    }

    function speed(kmh: real, imperial: bool): string {
        if (!kmh && kmh !== 0)
            return "—";
        return imperial ? `${Math.round(kmh * 0.621371)} mph` : `${Math.round(kmh)} km/h`;
    }

    // One timer serving every pending retry: it fires at the shortest queued
    // delay and re-resolves whatever is due.
    Timer {
        id: retryTimer

        property var due: ({})

        function queue(key: string, delay: int): void {
            const at = Date.now() + delay;
            const existing = retryTimer.due[key];
            if (existing && existing <= at)
                return;
            retryTimer.due[key] = at;
            retryTimer.reschedule();
        }

        function reschedule(): void {
            let soonest = Infinity;
            for (const k of Object.keys(retryTimer.due))
                soonest = Math.min(soonest, retryTimer.due[k]);
            if (!isFinite(soonest)) {
                retryTimer.running = false;
                return;
            }
            retryTimer.interval = Math.max(500, soonest - Date.now());
            retryTimer.restart();
        }

        repeat: false
        onTriggered: {
            const now = Date.now();
            for (const key of Object.keys(retryTimer.due)) {
                if (retryTimer.due[key] <= now + 250) {
                    delete retryTimer.due[key];
                    root.resolve(key);
                }
            }
            retryTimer.reschedule();
        }
    }


    Timer {
        interval: 15 * 60 * 1000
        running: Demand.needed("weather")
        repeat: true
        onTriggered: root.refreshAll()
    }

    // A laptop that gets its lid shut comes back with a stale forecast and,
    // for a few seconds, no network. Notice the wall-clock jump and refresh -
    // the periodic timer does not fire while suspended, so without this the
    // widget can show hours-old weather.
    Timer {
        id: wakeWatch

        property real last: Date.now()

        interval: 20000
        running: Demand.needed("weather")
        repeat: true
        onTriggered: {
            const now = Date.now();
            if (now - wakeWatch.last > interval * 3) {
                // Give the network a moment to come back before asking.
                for (const key of Object.keys(root.records))
                    retryTimer.queue(key, 5000);
            }
            wakeWatch.last = now;
        }
    }

    FileView {
        id: geoCache

        path: `${Theme.configPath}/geo-cache.json`
        printErrors: false

        function write(): void {
            setText(JSON.stringify({
                lat: root.autoLat,
                lon: root.autoLon,
                name: root.autoName,
                at: Date.now()
            }));
        }

        onLoaded: {
            try {
                const c = JSON.parse(text());
                // A month-old fix is still a better starting point than no
                // location at all; the periodic refresh will correct it.
                if (c && !isNaN(c.lat) && Date.now() - (c.at ?? 0) < 30 * 24 * 3600 * 1000) {
                    root.autoLat = c.lat;
                    root.autoLon = c.lon;
                    root.autoName = c.name ?? "";
                }
            } catch (e) {}
        }
    }
}
