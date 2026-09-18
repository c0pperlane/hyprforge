pragma Singleton

import QtQuick
import Quickshell
import qs.config

// Shared wall clock. One SystemClock for the whole config instead of a Timer
// per widget - ten clock widgets on screen still costs one tick.
Singleton {
    id: root

    readonly property date now: clock.date
    readonly property int hours: clock.hours
    readonly property int minutes: clock.minutes
    readonly property int seconds: clock.seconds

    // Bumped every second so anything needing sub-minute freshness (analog
    // second hand, countdowns) has something to depend on.
    readonly property int tick: clock.seconds

    function pad(n: int): string {
        return n < 10 ? `0${n}` : `${n}`;
    }

    function hh(hour12: bool): string {
        if (!hour12)
            return pad(root.hours);
        const h = root.hours % 12;
        return pad(h === 0 ? 12 : h);
    }

    function meridiem(): string {
        return root.hours < 12 ? "AM" : "PM";
    }

    function fmt(f: string): string {
        return Qt.formatDateTime(root.now, f);
    }

    // Seconds precision wakes the process once a second forever; most clock
    // widgets only show minutes. Anything that genuinely needs seconds - an
    // analog sweep hand, a countdown, a lyrics line - asks for it.
    SystemClock {
        id: clock

        precision: Demand.needed("clock.seconds") ? SystemClock.Seconds : SystemClock.Minutes
    }
}
