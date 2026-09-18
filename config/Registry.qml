pragma Singleton

import QtQuick
import Quickshell

// The widget catalogue.
//
// One entry per placeable desktop element: display metadata for the Library
// panel, a default size, and a property schema. The Inspector panel is fully
// generic - it renders editors straight from `props` here, so adding a knob to
// a widget means adding one line to its schema, not touching the inspector.
//
// Schema entry: { key, label, type, def, ... }
//   bool    -> switch
//   int/real-> slider (min, max, step)
//   enum    -> segmented button / dropdown (options: [{value,label}] or [string])
//   colour  -> palette-role picker with custom hex fallback
//   string  -> single-line text field
//   text    -> multi-line text area
//   icon    -> material symbol name field
//   list    -> newline-separated list editor
//   font    -> font family field
Singleton {
    id: root

    // Every widget gets these, so any element can be turned into a card,
    // tinted, rounded, padded or faded without bespoke code per widget.
    readonly property var commonProps: [
        {
            key: "bg",
            label: "Surface",
            type: "enum",
            def: "none",
            group: "Surface",
            options: [
                {
                    value: "none",
                    label: "None"
                },
                {
                    value: "tonal",
                    label: "Tonal"
                },
                {
                    value: "solid",
                    label: "Solid"
                },
                {
                    value: "glass",
                    label: "Glass"
                },
                {
                    value: "outline",
                    label: "Outline"
                }
            ]
        },
        {
            key: "bgColour",
            label: "Surface colour",
            type: "colour",
            def: "surfaceContainer",
            group: "Surface"
        },
        {
            key: "bgOpacity",
            label: "Surface opacity",
            type: "real",
            def: 0.85,
            min: 0,
            max: 1,
            step: 0.01,
            group: "Surface"
        },
        {
            key: "radius",
            label: "Corner radius",
            type: "corners",
            def: 22,
            min: 0,
            max: 80,
            step: 1,
            group: "Surface"
        },
        {
            key: "radiusLinked",
            label: "Link corners",
            type: "hidden",
            def: true,
            group: "Surface"
        },
        {
            key: "radiusTL",
            label: "Top left",
            type: "hidden",
            def: 22,
            group: "Surface"
        },
        {
            key: "radiusTR",
            label: "Top right",
            type: "hidden",
            def: 22,
            group: "Surface"
        },
        {
            key: "radiusBL",
            label: "Bottom left",
            type: "hidden",
            def: 22,
            group: "Surface"
        },
        {
            key: "radiusBR",
            label: "Bottom right",
            type: "hidden",
            def: 22,
            group: "Surface"
        },
        {
            key: "attach",
            label: "Join to touching neighbours",
            type: "bool",
            def: true,
            group: "Surface"
        },
        {
            key: "padding",
            label: "Padding",
            type: "int",
            def: 18,
            min: 0,
            max: 64,
            step: 1,
            group: "Surface"
        },
        {
            key: "border",
            label: "Hairline border",
            type: "bool",
            def: false,
            group: "Surface"
        },
        {
            key: "borderColour",
            label: "Border colour",
            type: "colour",
            def: "outlineVariant",
            group: "Surface"
        },
        {
            key: "shadow",
            label: "Drop shadow",
            type: "bool",
            def: false,
            group: "Surface"
        },
        {
            key: "accent",
            label: "Accent",
            type: "colour",
            def: "primary",
            group: "Colour"
        },
        {
            key: "fg",
            label: "Foreground",
            type: "colour",
            def: "fgSurface",
            group: "Colour"
        },
        {
            key: "muted",
            label: "Secondary text",
            type: "colour",
            def: "fgSurfaceVariant",
            group: "Colour"
        }
    ]

    readonly property var categories: ["Time", "System", "Media", "Info", "Shell", "Decor"]

    readonly property var catalog: [
        // ---------------------------------------------------------- Time ---
        {
            type: "HeroClock",
            name: "Hero Clock",
            blurb: "Oversized variable-width clock, the centrepiece kind",
            icon: "schedule",
            category: "Time",
            size: {
                w: 760,
                h: 220
            },
            props: [
                {
                    key: "seconds",
                    label: "Show seconds",
                    type: "bool",
                    def: false
                },
                {
                    key: "hour12",
                    label: "12-hour clock",
                    type: "bool",
                    def: false
                },
                {
                    key: "size",
                    label: "Glyph size",
                    type: "int",
                    def: 168,
                    min: 32,
                    max: 420,
                    step: 2
                },
                {
                    key: "weight",
                    label: "Weight",
                    type: "int",
                    def: 900,
                    min: 100,
                    max: 1000,
                    step: 50
                },
                {
                    key: "width",
                    label: "Width axis",
                    type: "int",
                    def: 38,
                    min: 25,
                    max: 151,
                    step: 1
                },
                {
                    key: "letterSpacing",
                    label: "Tracking",
                    type: "real",
                    def: -2,
                    min: -20,
                    max: 40,
                    step: 0.5
                },
                {
                    key: "subtitle",
                    label: "Date line",
                    type: "enum",
                    def: "long",
                    options: ["none", "short", "long"]
                },
                {
                    key: "glow",
                    label: "Legibility shadow",
                    type: "bool",
                    def: true
                },
                {
                    key: "align",
                    label: "Align",
                    type: "enum",
                    def: "center",
                    options: ["left", "center", "right"]
                }
            ]
        },
        {
            type: "StackClock",
            name: "Stacked Clock",
            blurb: "Hours over minutes, editorial poster styling",
            icon: "timer",
            category: "Time",
            size: {
                w: 340,
                h: 380
            },
            props: [
                {
                    key: "size",
                    label: "Glyph size",
                    type: "int",
                    def: 150,
                    min: 40,
                    max: 400,
                    step: 2
                },
                {
                    key: "weight",
                    label: "Weight",
                    type: "int",
                    def: 750,
                    min: 100,
                    max: 1000,
                    step: 50
                },
                {
                    key: "width",
                    label: "Width axis",
                    type: "int",
                    def: 32,
                    min: 25,
                    max: 151,
                    step: 1
                },
                {
                    key: "hour12",
                    label: "12-hour clock",
                    type: "bool",
                    def: false
                },
                {
                    key: "rule",
                    label: "Accent rule",
                    type: "bool",
                    def: true
                },
                {
                    key: "label",
                    label: "Caption",
                    type: "string",
                    def: ""
                }
            ]
        },
        {
            type: "AnalogClock",
            name: "Analog Clock",
            blurb: "Swiss-style face with sweeping seconds",
            icon: "nest_clock_farsight_analog",
            category: "Time",
            size: {
                w: 260,
                h: 260
            },
            props: [
                {
                    key: "ticks",
                    label: "Tick marks",
                    type: "enum",
                    def: "hours",
                    options: ["none", "quarters", "hours", "minutes"]
                },
                {
                    key: "numerals",
                    label: "Numerals",
                    type: "bool",
                    def: false
                },
                {
                    key: "sweep",
                    label: "Sweeping second hand",
                    type: "bool",
                    def: true
                },
                {
                    key: "face",
                    label: "Face fill",
                    type: "bool",
                    def: true
                },
                {
                    key: "thickness",
                    label: "Hand weight",
                    type: "real",
                    def: 4,
                    min: 1,
                    max: 14,
                    step: 0.5
                }
            ]
        },
        {
            type: "DateCard",
            name: "Date Block",
            blurb: "Day number, weekday and month in a tight stack",
            icon: "calendar_today",
            category: "Time",
            size: {
                w: 230,
                h: 230
            },
            props: [
                {
                    key: "size",
                    label: "Day size",
                    type: "int",
                    def: 96,
                    min: 24,
                    max: 220,
                    step: 2
                },
                {
                    key: "showMonth",
                    label: "Show month",
                    type: "bool",
                    def: true
                },
                {
                    key: "showWeekday",
                    label: "Show weekday",
                    type: "bool",
                    def: true
                },
                {
                    key: "uppercase",
                    label: "Uppercase labels",
                    type: "bool",
                    def: true
                }
            ]
        },
        {
            type: "CalendarCard",
            name: "Calendar",
            blurb: "Month grid with today marked",
            icon: "calendar_month",
            category: "Time",
            size: {
                w: 340,
                h: 320
            },
            props: [
                {
                    key: "mondayFirst",
                    label: "Week starts Monday",
                    type: "bool",
                    def: true
                },
                {
                    key: "showHeader",
                    label: "Month header",
                    type: "bool",
                    def: true
                },
                {
                    key: "weekNumbers",
                    label: "Week numbers",
                    type: "bool",
                    def: false
                },
                {
                    key: "cell",
                    label: "Cell size",
                    type: "int",
                    def: 34,
                    min: 18,
                    max: 72,
                    step: 1
                }
            ]
        },
        {
            type: "WorldClock",
            name: "World Clocks",
            blurb: "A row of cities and their local time",
            icon: "public",
            category: "Time",
            size: {
                w: 420,
                h: 130
            },
            props: [
                {
                    key: "zones",
                    label: "Zones (Label|UTC offset)",
                    type: "list",
                    def: "Berlin|2\nNew York|-4\nTokyo|9"
                },
                {
                    key: "size",
                    label: "Time size",
                    type: "int",
                    def: 30,
                    min: 12,
                    max: 90,
                    step: 1
                },
                {
                    key: "orientation",
                    label: "Layout",
                    type: "enum",
                    def: "row",
                    options: ["row", "column"]
                }
            ]
        },
        {
            type: "Countdown",
            name: "Countdown",
            blurb: "Days/hours left until a date you set",
            icon: "hourglass",
            category: "Time",
            size: {
                w: 320,
                h: 170
            },
            props: [
                {
                    key: "target",
                    label: "Target (YYYY-MM-DD HH:MM)",
                    type: "string",
                    def: "2027-01-01 00:00"
                },
                {
                    key: "title",
                    label: "Title",
                    type: "string",
                    def: "New Year"
                },
                {
                    key: "units",
                    label: "Detail",
                    type: "enum",
                    def: "dhm",
                    options: ["d", "dh", "dhm", "dhms"]
                }
            ]
        },
        // -------------------------------------------------------- System ---
        {
            type: "StatRing",
            name: "Stat Ring",
            blurb: "One metric as a radial gauge - CPU, GPU, RAM, disk, temps",
            icon: "data_usage",
            category: "System",
            size: {
                w: 190,
                h: 190
            },
            props: [
                {
                    key: "source",
                    label: "Metric",
                    type: "enum",
                    def: "cpu",
                    options: ["cpu", "cpuTemp", "cpuFreq", "cpuPower", "memory", "swap", "gpu", "gpuTemp", "gpuPower", "gpuClock", "vram", "disk", "diskRead", "diskWrite", "battery", "fanCpu", "fanGpu", "netDown", "netUp"]
                },
                {
                    key: "thickness",
                    label: "Ring weight",
                    type: "int",
                    def: 12,
                    min: 2,
                    max: 40,
                    step: 1
                },
                {
                    key: "track",
                    label: "Show track",
                    type: "bool",
                    def: true
                },
                {
                    key: "showIcon",
                    label: "Show icon",
                    type: "bool",
                    def: true
                },
                {
                    key: "showLabel",
                    label: "Show label",
                    type: "bool",
                    def: true
                },
                {
                    key: "valueSize",
                    label: "Value size",
                    type: "int",
                    def: 30,
                    min: 10,
                    max: 96,
                    step: 1
                },
                {
                    key: "gap",
                    label: "Ring gap",
                    type: "int",
                    def: 0,
                    min: 0,
                    max: 120,
                    step: 5
                },
                {
                    key: "warn",
                    label: "Warn above %",
                    type: "int",
                    def: 85,
                    min: 0,
                    max: 100,
                    step: 1
                }
            ]
        },
        {
            type: "StatStack",
            name: "Stat Stack",
            blurb: "Labelled meters for several metrics at once",
            icon: "bar_chart",
            category: "System",
            size: {
                w: 320,
                h: 210
            },
            props: [
                {
                    key: "sources",
                    label: "Metrics",
                    type: "list",
                    def: "cpu\nmemory\ngpu\nvram"
                },
                {
                    key: "style",
                    label: "Meter style",
                    type: "enum",
                    def: "bar",
                    options: ["bar", "segments", "line"]
                },
                {
                    key: "thickness",
                    label: "Meter height",
                    type: "int",
                    def: 8,
                    min: 2,
                    max: 28,
                    step: 1
                },
                {
                    key: "showValue",
                    label: "Show values",
                    type: "bool",
                    def: true
                },
                {
                    key: "showIcon",
                    label: "Show icons",
                    type: "bool",
                    def: true
                },
                {
                    key: "spacing",
                    label: "Row spacing",
                    type: "int",
                    def: 14,
                    min: 2,
                    max: 48,
                    step: 1
                }
            ]
        },
        {
            type: "SparkGraph",
            name: "Spark Graph",
            blurb: "Rolling history curve for any metric",
            icon: "show_chart",
            category: "System",
            size: {
                w: 360,
                h: 150
            },
            props: [
                {
                    key: "source",
                    label: "Metric",
                    type: "enum",
                    def: "cpu",
                    options: ["cpu", "cpuTemp", "cpuFreq", "cpuPower", "memory", "swap", "gpu", "gpuTemp", "gpuPower", "gpuClock", "vram", "disk", "diskRead", "diskWrite", "battery", "fanCpu", "fanGpu", "netDown", "netUp"]
                },
                {
                    key: "points",
                    label: "History length",
                    type: "int",
                    def: 60,
                    min: 10,
                    max: 240,
                    step: 5
                },
                {
                    key: "fill",
                    label: "Fill under curve",
                    type: "bool",
                    def: true
                },
                {
                    key: "thickness",
                    label: "Line weight",
                    type: "real",
                    def: 2.5,
                    min: 0.5,
                    max: 10,
                    step: 0.5
                },
                {
                    key: "showValue",
                    label: "Show current value",
                    type: "bool",
                    def: true
                },
                {
                    key: "showTitle",
                    label: "Show title",
                    type: "bool",
                    def: true
                }
            ]
        },
        {
            type: "NetSpeed",
            name: "Network Meter",
            blurb: "Live up/down throughput with history",
            icon: "swap_vert",
            category: "System",
            size: {
                w: 300,
                h: 160
            },
            props: [
                {
                    key: "graph",
                    label: "Show graph",
                    type: "bool",
                    def: true
                },
                {
                    key: "valueSize",
                    label: "Value size",
                    type: "int",
                    def: 22,
                    min: 10,
                    max: 64,
                    step: 1
                },
                {
                    key: "downColour",
                    label: "Down colour",
                    type: "colour",
                    def: "primary"
                },
                {
                    key: "upColour",
                    label: "Up colour",
                    type: "colour",
                    def: "tertiary"
                }
            ]
        },
        {
            type: "DiskGauge",
            name: "Storage",
            blurb: "Capacity bars for your mounts",
            icon: "hard_drive_2",
            category: "System",
            size: {
                w: 330,
                h: 170
            },
            props: [
                {
                    key: "mounts",
                    label: "Filter (blank = all)",
                    type: "list",
                    def: ""
                },
                {
                    key: "showFree",
                    label: "Show free space",
                    type: "bool",
                    def: true
                },
                {
                    key: "thickness",
                    label: "Bar height",
                    type: "int",
                    def: 8,
                    min: 2,
                    max: 28,
                    step: 1
                }
            ]
        },
        {
            type: "BatteryCard",
            name: "Battery",
            blurb: "Charge ring, state and time remaining",
            icon: "battery_charging_full",
            category: "System",
            size: {
                w: 300,
                h: 140
            },
            props: [
                {
                    key: "style",
                    label: "Style",
                    type: "enum",
                    def: "ring",
                    options: ["ring", "bar", "pill"]
                },
                {
                    key: "showTime",
                    label: "Show time remaining",
                    type: "bool",
                    def: true
                },
                {
                    key: "showPower",
                    label: "Show power draw",
                    type: "bool",
                    def: true
                }
            ]
        },
        {
            type: "SysInfoCard",
            name: "System Info",
            blurb: "Host, kernel, uptime and distro at a glance",
            icon: "terminal",
            category: "System",
            size: {
                w: 340,
                h: 180
            },
            props: [
                {
                    key: "rows",
                    label: "Rows",
                    type: "list",
                    def: "host\nkernel\nuptime\nshell\npackages",
                    placeholder: "host kernel uptime shell packages os wm cpu gpu fans power refresh"
                },
                {
                    key: "showLogo",
                    label: "Show logo",
                    type: "bool",
                    def: true
                },
                {
                    key: "labelWidth",
                    label: "Label width",
                    type: "int",
                    def: 92,
                    min: 40,
                    max: 200,
                    step: 2
                }
            ]
        },
        // --------------------------------------------------------- Media ---
        {
            type: "NowPlaying",
            name: "Now Playing",
            blurb: "Album art, metadata, scrubber and transport",
            icon: "play_circle",
            category: "Media",
            size: {
                w: 420,
                h: 140
            },
            props: [
                {
                    key: "art",
                    label: "Album art",
                    type: "enum",
                    def: "rounded",
                    options: ["none", "rounded", "circle", "blob"]
                },
                {
                    key: "controls",
                    label: "Transport controls",
                    type: "bool",
                    def: true
                },
                {
                    key: "progress",
                    label: "Progress bar",
                    type: "bool",
                    def: true
                },
                {
                    key: "titleSize",
                    label: "Title size",
                    type: "int",
                    def: 18,
                    min: 10,
                    max: 48,
                    step: 1
                },
                {
                    key: "tintFromArt",
                    label: "Tint from artwork",
                    type: "bool",
                    def: true
                },
                {
                    key: "idleText",
                    label: "Idle text",
                    type: "string",
                    def: "Nothing playing"
                }
            ]
        },
        {
            type: "LyricsCard",
            name: "Lyrics",
            blurb: "Synced lyrics for whatever is playing",
            icon: "lyrics",
            category: "Media",
            size: {
                w: 460,
                h: 240
            },
            props: [
                {
                    key: "mode",
                    label: "Layout",
                    type: "enum",
                    def: "scroll",
                    options: [
                        {
                            value: "scroll",
                            label: "Scroll"
                        },
                        {
                            value: "three",
                            label: "3 lines"
                        },
                        {
                            value: "current",
                            label: "Current"
                        }
                    ]
                },
                {
                    key: "whenEmpty",
                    label: "With no lyrics",
                    type: "enum",
                    def: "message",
                    options: [
                        {
                            value: "message",
                            label: "Message"
                        },
                        {
                            value: "icon",
                            label: "Icon"
                        },
                        {
                            value: "hide",
                            label: "Hide"
                        }
                    ]
                },
                {
                    key: "noLyricsText",
                    label: "No lyrics found",
                    type: "string",
                    def: "No lyrics"
                },
                {
                    key: "idleText",
                    label: "Nothing playing",
                    type: "string",
                    def: "Nothing playing"
                },
                {
                    key: "loadingText",
                    label: "While searching",
                    type: "string",
                    def: "Looking for lyrics…"
                },
                {
                    key: "emptyIcon",
                    label: "Icon with the message",
                    type: "bool",
                    def: true
                },
                {
                    key: "size",
                    label: "Line size",
                    type: "int",
                    def: 18,
                    min: 9,
                    max: 72,
                    step: 1
                },
                {
                    key: "align",
                    label: "Align",
                    type: "enum",
                    def: "left",
                    options: ["left", "center", "right"]
                },
                {
                    key: "dim",
                    label: "Inactive lines",
                    type: "real",
                    def: 0.45,
                    min: 0,
                    max: 1,
                    step: 0.05
                },
                {
                    key: "highlight",
                    label: "Current line",
                    type: "colour",
                    def: "primary"
                },
                {
                    key: "showTrack",
                    label: "Show artist / title",
                    type: "bool",
                    def: false
                },
                {
                    key: "fade",
                    label: "Fade edges",
                    type: "bool",
                    def: true
                },
                {
                    key: "clickToSeek",
                    label: "Click a line to seek",
                    type: "bool",
                    def: true
                },
                {
                    key: "glow",
                    label: "Legibility shadow",
                    type: "bool",
                    def: false
                }
            ]
        },
        {
            type: "CoreLoad",
            name: "Core Load",
            blurb: "Every CPU core at once, as bars or a heat grid",
            icon: "grid_view",
            category: "System",
            size: {
                w: 340,
                h: 150
            },
            props: [
                {
                    key: "style",
                    label: "Layout",
                    type: "enum",
                    def: "bars",
                    options: ["bars", "grid"]
                },
                {
                    key: "columns",
                    label: "Grid columns",
                    type: "int",
                    def: 8,
                    min: 1,
                    max: 32,
                    step: 1
                },
                {
                    key: "gap",
                    label: "Gap",
                    type: "int",
                    def: 3,
                    min: 0,
                    max: 16,
                    step: 1
                },
                {
                    key: "rounding",
                    label: "Corner rounding",
                    type: "int",
                    def: 4,
                    min: 0,
                    max: 16,
                    step: 1
                },
                {
                    key: "warn",
                    label: "Ramp to error above",
                    type: "real",
                    def: 0.75,
                    min: 0,
                    max: 1,
                    step: 0.05
                },
                {
                    key: "showTitle",
                    label: "Show header",
                    type: "bool",
                    def: true
                },
                {
                    key: "showIndex",
                    label: "Number the cores",
                    type: "bool",
                    def: false
                }
            ]
        },
        {
            type: "ParkedCores",
            name: "Parked Cores",
            blurb: "Which threads sched_ext is still dispatching to",
            icon: "developer_board",
            category: "System",
            // Sized so the default 8x4 lands on chunky ~44px cells. The grid
            // divides whatever it is given, so resizing the widget resizes the
            // cells with it - this is only where it starts.
            size: {
                w: 420,
                h: 220
            },
            props: [
                {
                    key: "title",
                    label: "Heading",
                    type: "string",
                    def: "PARKED CORES"
                },
                {
                    key: "columns",
                    label: "Columns",
                    type: "int",
                    def: 8,
                    min: 1,
                    max: 32,
                    step: 1
                },
                {
                    key: "emphasis",
                    label: "Highlight",
                    type: "enum",
                    def: "active",
                    options: ["active", "parked"]
                },
                {
                    key: "gap",
                    label: "Gap",
                    type: "int",
                    def: 4,
                    min: 0,
                    max: 16,
                    step: 1
                },
                {
                    key: "rounding",
                    label: "Corner rounding",
                    type: "int",
                    def: 7,
                    min: 0,
                    max: 20,
                    step: 1
                },
                {
                    key: "square",
                    label: "Square cells",
                    type: "bool",
                    def: false
                },
                {
                    key: "warn",
                    label: "Turn red above",
                    type: "real",
                    def: 0.8,
                    min: 0,
                    max: 1,
                    step: 0.05
                },
                {
                    key: "showTitle",
                    label: "Show header",
                    type: "bool",
                    def: true
                },
                {
                    key: "showFooter",
                    label: "Show scheduler line",
                    type: "bool",
                    def: true
                },
                {
                    key: "showIndex",
                    label: "Number the threads",
                    type: "bool",
                    def: false
                }
            ]
        },
        {
            type: "CStateMeter",
            name: "Idle Residency",
            blurb: "How deeply the package is actually sleeping",
            icon: "bedtime",
            category: "System",
            size: {
                w: 340,
                h: 110
            },
            props: [
                {
                    key: "title",
                    label: "Heading",
                    type: "string",
                    def: "IDLE RESIDENCY"
                },
                {
                    key: "warn",
                    label: "Turn red above",
                    type: "real",
                    def: 0.8,
                    min: 0,
                    max: 1,
                    step: 0.05
                },
                {
                    key: "barHeight",
                    label: "Bar height",
                    type: "int",
                    def: 14,
                    min: 4,
                    max: 48,
                    step: 1
                },
                {
                    key: "showTitle",
                    label: "Show header",
                    type: "bool",
                    def: true
                },
                {
                    key: "showLegend",
                    label: "Show legend",
                    type: "bool",
                    def: true
                }
            ]
        },
        {
            type: "ProcessTop",
            name: "Top Processes",
            blurb: "What is actually eating the machine",
            icon: "format_list_numbered",
            category: "System",
            size: {
                w: 340,
                h: 180
            },
            props: [
                {
                    key: "sortBy",
                    label: "Sort by",
                    type: "enum",
                    def: "cpu",
                    options: ["cpu", "mem"]
                },
                {
                    key: "count",
                    label: "Rows",
                    type: "int",
                    def: 5,
                    min: 1,
                    max: 12,
                    step: 1
                },
                {
                    key: "size",
                    label: "Text size",
                    type: "int",
                    def: 13,
                    min: 9,
                    max: 28,
                    step: 1
                },
                {
                    key: "spacing",
                    label: "Row spacing",
                    type: "int",
                    def: 7,
                    min: 0,
                    max: 24,
                    step: 1
                },
                {
                    key: "showTitle",
                    label: "Show header",
                    type: "bool",
                    def: true
                }
            ]
        },
        {
            type: "UptimeRing",
            name: "Uptime",
            blurb: "How long the machine has been up, as a ring",
            icon: "schedule",
            category: "System",
            size: {
                w: 190,
                h: 190
            },
            props: [
                {
                    key: "span",
                    label: "Ring fills over",
                    type: "enum",
                    def: "day",
                    options: ["day", "week", "month"]
                },
                {
                    key: "thickness",
                    label: "Ring weight",
                    type: "int",
                    def: 10,
                    min: 2,
                    max: 40,
                    step: 1
                },
                {
                    key: "valueSize",
                    label: "Value size",
                    type: "int",
                    def: 20,
                    min: 10,
                    max: 60,
                    step: 1
                },
                {
                    key: "showIcon",
                    label: "Show icon",
                    type: "bool",
                    def: true
                },
                {
                    key: "showLabel",
                    label: "Show label",
                    type: "bool",
                    def: true
                }
            ]
        },
        {
            type: "MoonPhase",
            name: "Moon Phase",
            blurb: "Tonight's moon, drawn from the date alone",
            icon: "dark_mode",
            category: "Info",
            size: {
                w: 200,
                h: 190
            },
            props: [
                {
                    key: "size",
                    label: "Disc size",
                    type: "int",
                    def: 90,
                    min: 30,
                    max: 260,
                    step: 2
                },
                {
                    key: "litColour",
                    label: "Lit side",
                    type: "colour",
                    def: "fgSurface"
                },
                {
                    key: "textSize",
                    label: "Text size",
                    type: "int",
                    def: 13,
                    min: 8,
                    max: 32,
                    step: 1
                },
                {
                    key: "showName",
                    label: "Show phase name",
                    type: "bool",
                    def: true
                },
                {
                    key: "showDetail",
                    label: "Show illumination",
                    type: "bool",
                    def: true
                }
            ]
        },
        {
            type: "PaletteSwatches",
            name: "Palette",
            blurb: "The active caelestia scheme, as swatches",
            icon: "palette",
            category: "Decor",
            size: {
                w: 300,
                h: 130
            },
            props: [
                {
                    key: "roles",
                    label: "Roles",
                    type: "list",
                    def: "primary\nsecondary\ntertiary\nsurfaceContainer\nfgSurface\nerror"
                },
                {
                    key: "columns",
                    label: "Columns",
                    type: "int",
                    def: 6,
                    min: 1,
                    max: 12,
                    step: 1
                },
                {
                    key: "gap",
                    label: "Gap",
                    type: "int",
                    def: 6,
                    min: 0,
                    max: 24,
                    step: 1
                },
                {
                    key: "swatchRadius",
                    label: "Swatch radius",
                    type: "int",
                    def: 10,
                    min: 0,
                    max: 40,
                    step: 1
                },
                {
                    key: "showScheme",
                    label: "Show scheme name",
                    type: "bool",
                    def: true
                },
                {
                    key: "showNames",
                    label: "Label each swatch",
                    type: "bool",
                    def: false
                }
            ]
        },
        {
            type: "Pomodoro",
            name: "Pomodoro",
            blurb: "Work/break timer - click to start, right-click to reset",
            icon: "timer",
            category: "Info",
            size: {
                w: 200,
                h: 200
            },
            props: [
                {
                    key: "work",
                    label: "Focus minutes",
                    type: "int",
                    def: 25,
                    min: 1,
                    max: 120,
                    step: 1
                },
                {
                    key: "break",
                    label: "Break minutes",
                    type: "int",
                    def: 5,
                    min: 1,
                    max: 60,
                    step: 1
                },
                {
                    key: "longBreak",
                    label: "Long break minutes",
                    type: "int",
                    def: 15,
                    min: 1,
                    max: 90,
                    step: 1
                },
                {
                    key: "longEvery",
                    label: "Long break every",
                    type: "int",
                    def: 4,
                    min: 2,
                    max: 12,
                    step: 1
                },
                {
                    key: "size",
                    label: "Text size",
                    type: "int",
                    def: 26,
                    min: 12,
                    max: 72,
                    step: 1
                },
                {
                    key: "thickness",
                    label: "Ring weight",
                    type: "int",
                    def: 9,
                    min: 2,
                    max: 32,
                    step: 1
                },
                {
                    key: "breakColour",
                    label: "Break colour",
                    type: "colour",
                    def: "tertiary"
                },
                {
                    key: "autoContinue",
                    label: "Roll straight on",
                    type: "bool",
                    def: true
                },
                {
                    key: "notify",
                    label: "Desktop notification",
                    type: "bool",
                    def: true
                },
                {
                    key: "showCount",
                    label: "Show completed count",
                    type: "bool",
                    def: true
                }
            ]
        },
        {
            type: "VolumeDial",
            name: "Volume",
            blurb: "Output volume - scroll to change, click to mute",
            icon: "volume_up",
            category: "Shell",
            size: {
                w: 180,
                h: 180
            },
            props: [
                {
                    key: "size",
                    label: "Text size",
                    type: "int",
                    def: 22,
                    min: 10,
                    max: 64,
                    step: 1
                },
                {
                    key: "thickness",
                    label: "Ring weight",
                    type: "int",
                    def: 10,
                    min: 2,
                    max: 40,
                    step: 1
                },
                {
                    key: "step",
                    label: "Scroll step",
                    type: "real",
                    def: 0.05,
                    min: 0.01,
                    max: 0.25,
                    step: 0.01
                },
                {
                    key: "showIcon",
                    label: "Show icon",
                    type: "bool",
                    def: true
                },
                {
                    key: "showDevice",
                    label: "Show device name",
                    type: "bool",
                    def: false
                }
            ]
        },
        {
            type: "KeyboardLayout",
            name: "Keyboard Layout",
            blurb: "Active layout - click to cycle",
            icon: "keyboard",
            category: "Shell",
            size: {
                w: 140,
                h: 100
            },
            props: [
                {
                    key: "style",
                    label: "Style",
                    type: "enum",
                    def: "code",
                    options: ["code", "name"]
                },
                {
                    key: "size",
                    label: "Text size",
                    type: "int",
                    def: 24,
                    min: 10,
                    max: 72,
                    step: 1
                },
                {
                    key: "showLabel",
                    label: "Show caption",
                    type: "bool",
                    def: true
                },
                {
                    key: "glow",
                    label: "Legibility shadow",
                    type: "bool",
                    def: false
                }
            ]
        },
        {
            type: "BluetoothCard",
            name: "Bluetooth",
            blurb: "Paired devices and their battery",
            icon: "bluetooth",
            category: "Shell",
            size: {
                w: 320,
                h: 170
            },
            props: [
                {
                    key: "count",
                    label: "Devices shown",
                    type: "int",
                    def: 4,
                    min: 1,
                    max: 10,
                    step: 1
                },
                {
                    key: "size",
                    label: "Text size",
                    type: "int",
                    def: 13,
                    min: 9,
                    max: 28,
                    step: 1
                },
                {
                    key: "spacing",
                    label: "Row spacing",
                    type: "int",
                    def: 8,
                    min: 0,
                    max: 24,
                    step: 1
                },
                {
                    key: "connectedOnly",
                    label: "Connected only",
                    type: "bool",
                    def: false
                },
                {
                    key: "showBattery",
                    label: "Show battery",
                    type: "bool",
                    def: true
                },
                {
                    key: "showTitle",
                    label: "Show header",
                    type: "bool",
                    def: true
                },
                {
                    key: "clickToConnect",
                    label: "Click to connect",
                    type: "bool",
                    def: true
                }
            ]
        },
        {
            type: "Sensors",
            name: "Temperatures",
            blurb: "Every temperature the machine reports, hottest first",
            icon: "thermostat",
            category: "System",
            size: {
                w: 340,
                h: 180
            },
            props: [
                {
                    key: "count",
                    label: "Rows",
                    type: "int",
                    def: 5,
                    min: 1,
                    max: 12,
                    step: 1
                },
                {
                    key: "filter",
                    label: "Filter (blank = all)",
                    type: "list",
                    def: ""
                },
                {
                    key: "warn",
                    label: "Warn above °C",
                    type: "real",
                    def: 75,
                    min: 30,
                    max: 110,
                    step: 1
                },
                {
                    key: "ceiling",
                    label: "Bar full at °C",
                    type: "real",
                    def: 100,
                    min: 50,
                    max: 130,
                    step: 1
                },
                {
                    key: "size",
                    label: "Text size",
                    type: "int",
                    def: 12,
                    min: 9,
                    max: 24,
                    step: 1
                },
                {
                    key: "thickness",
                    label: "Bar height",
                    type: "int",
                    def: 5,
                    min: 2,
                    max: 16,
                    step: 1
                },
                {
                    key: "spacing",
                    label: "Row spacing",
                    type: "int",
                    def: 9,
                    min: 2,
                    max: 28,
                    step: 1
                },
                {
                    key: "showBars",
                    label: "Show bars",
                    type: "bool",
                    def: true
                },
                {
                    key: "showChip",
                    label: "Show chip name",
                    type: "bool",
                    def: true
                },
                {
                    key: "showTitle",
                    label: "Show header",
                    type: "bool",
                    def: true
                }
            ]
        },
        {
            type: "NetInterfaces",
            name: "Interfaces",
            blurb: "Network interfaces and their addresses",
            icon: "lan",
            category: "System",
            size: {
                w: 320,
                h: 160
            },
            props: [
                {
                    key: "count",
                    label: "Rows",
                    type: "int",
                    def: 3,
                    min: 1,
                    max: 8,
                    step: 1
                },
                {
                    key: "upOnly",
                    label: "Only interfaces that are up",
                    type: "bool",
                    def: true
                },
                {
                    key: "showAddress",
                    label: "Show address",
                    type: "bool",
                    def: true
                },
                {
                    key: "size",
                    label: "Text size",
                    type: "int",
                    def: 13,
                    min: 9,
                    max: 26,
                    step: 1
                },
                {
                    key: "spacing",
                    label: "Row spacing",
                    type: "int",
                    def: 10,
                    min: 2,
                    max: 28,
                    step: 1
                },
                {
                    key: "showTitle",
                    label: "Show header",
                    type: "bool",
                    def: true
                }
            ]
        },
        {
            type: "ClipboardHistory",
            name: "Clipboard",
            blurb: "Recent clipboard entries - click to copy one back",
            icon: "content_paste",
            category: "Shell",
            size: {
                w: 340,
                h: 200
            },
            props: [
                {
                    key: "count",
                    label: "Entries",
                    type: "int",
                    def: 5,
                    min: 1,
                    max: 15,
                    step: 1
                },
                {
                    key: "size",
                    label: "Text size",
                    type: "int",
                    def: 12,
                    min: 9,
                    max: 24,
                    step: 1
                },
                {
                    key: "spacing",
                    label: "Row spacing",
                    type: "int",
                    def: 5,
                    min: 0,
                    max: 20,
                    step: 1
                },
                {
                    key: "mono",
                    label: "Monospace",
                    type: "bool",
                    def: false
                },
                {
                    key: "showTitle",
                    label: "Show header",
                    type: "bool",
                    def: true
                }
            ]
        },
        {
            type: "Brightness",
            name: "Brightness",
            blurb: "Screen brightness - scroll to change",
            icon: "brightness_high",
            category: "Shell",
            size: {
                w: 180,
                h: 180
            },
            props: [
                {
                    key: "style",
                    label: "Style",
                    type: "enum",
                    def: "ring",
                    options: ["ring", "bar"]
                },
                {
                    key: "size",
                    label: "Text size",
                    type: "int",
                    def: 22,
                    min: 10,
                    max: 64,
                    step: 1
                },
                {
                    key: "thickness",
                    label: "Weight",
                    type: "int",
                    def: 10,
                    min: 2,
                    max: 40,
                    step: 1
                },
                {
                    key: "step",
                    label: "Scroll step",
                    type: "real",
                    def: 0.05,
                    min: 0.01,
                    max: 0.25,
                    step: 0.01
                },
                {
                    key: "showIcon",
                    label: "Show icon",
                    type: "bool",
                    def: true
                },
                {
                    key: "showValue",
                    label: "Show value (bar style)",
                    type: "bool",
                    def: true
                }
            ]
        },
        {
            type: "IdleInhibitor",
            name: "Stay Awake",
            blurb: "Blocks idle and sleep while it is on",
            icon: "coffee",
            category: "Shell",
            size: {
                w: 140,
                h: 140
            },
            props: [
                {
                    key: "size",
                    label: "Icon size",
                    type: "int",
                    def: 30,
                    min: 12,
                    max: 90,
                    step: 1
                },
                {
                    key: "disc",
                    label: "Disc behind icon",
                    type: "bool",
                    def: true
                },
                {
                    key: "activeColour",
                    label: "Active colour",
                    type: "colour",
                    def: "error"
                },
                {
                    key: "showLabel",
                    label: "Show label",
                    type: "bool",
                    def: true
                }
            ]
        },
        {
            type: "Stopwatch",
            name: "Stopwatch",
            blurb: "Click to start or stop, right-click to reset",
            icon: "avg_pace",
            category: "Info",
            size: {
                w: 200,
                h: 140
            },
            props: [
                {
                    key: "size",
                    label: "Text size",
                    type: "int",
                    def: 30,
                    min: 12,
                    max: 80,
                    step: 1
                },
                {
                    key: "showLabel",
                    label: "Show label",
                    type: "bool",
                    def: true
                }
            ]
        },
        {
            type: "DiskMeter",
            name: "Disk I/O",
            blurb: "Read and write throughput, with history",
            icon: "hard_disk",
            category: "System",
            size: {
                w: 300,
                h: 160
            },
            props: [
                {
                    key: "graph",
                    label: "Show graph",
                    type: "bool",
                    def: true
                },
                {
                    key: "valueSize",
                    label: "Value size",
                    type: "int",
                    def: 20,
                    min: 10,
                    max: 56,
                    step: 1
                },
                {
                    key: "thickness",
                    label: "Line weight",
                    type: "real",
                    def: 2,
                    min: 0.5,
                    max: 8,
                    step: 0.5
                },
                {
                    key: "readColour",
                    label: "Read colour",
                    type: "colour",
                    def: "primary"
                },
                {
                    key: "writeColour",
                    label: "Write colour",
                    type: "colour",
                    def: "tertiary"
                }
            ]
        },
        {
            type: "SunClock",
            name: "Daylight",
            blurb: "Sunrise, sunset, and where you are between them",
            icon: "wb_sunny",
            category: "Info",
            size: {
                w: 320,
                h: 170
            },
            props: [
                {
                    key: "location",
                    label: "Place, or lat,lon",
                    type: "string",
                    def: "",
                    placeholder: "blank = detect by IP"
                },
                {
                    key: "size",
                    label: "Text size",
                    type: "int",
                    def: 12,
                    min: 9,
                    max: 26,
                    step: 1
                },
                {
                    key: "thickness",
                    label: "Arc weight",
                    type: "int",
                    def: 4,
                    min: 1,
                    max: 16,
                    step: 1
                },
                {
                    key: "sunColour",
                    label: "Sun marker",
                    type: "colour",
                    def: "primary"
                },
                {
                    key: "showDaylight",
                    label: "Show day length",
                    type: "bool",
                    def: true
                }
            ]
        },
        {
            type: "MediaMini",
            name: "Media Pill",
            blurb: "Compact scrolling title with play/pause",
            icon: "graphic_eq",
            category: "Media",
            size: {
                w: 280,
                h: 56
            },
            props: [
                {
                    key: "showArt",
                    label: "Show art",
                    type: "bool",
                    def: true
                },
                {
                    key: "size",
                    label: "Text size",
                    type: "int",
                    def: 14,
                    min: 9,
                    max: 32,
                    step: 1
                }
            ]
        },
        {
            type: "Visualiser",
            name: "Visualiser",
            blurb: "Cava-driven spectrum bars",
            icon: "equalizer",
            category: "Media",
            size: {
                w: 480,
                h: 140
            },
            props: [
                {
                    key: "bars",
                    label: "Bar count",
                    type: "int",
                    def: 42,
                    min: 4,
                    max: 128,
                    step: 1
                },
                {
                    key: "rounding",
                    label: "Bar rounding",
                    type: "int",
                    def: 6,
                    min: 0,
                    max: 24,
                    step: 1
                },
                {
                    key: "spacing",
                    label: "Bar spacing",
                    type: "real",
                    def: 0.35,
                    min: 0,
                    max: 0.9,
                    step: 0.05
                },
                {
                    key: "mirror",
                    label: "Mirror",
                    type: "enum",
                    def: "up",
                    options: ["up", "down", "center"]
                },
                {
                    key: "gradient",
                    label: "Fade tips",
                    type: "bool",
                    def: true
                },
                {
                    key: "gain",
                    label: "Gain",
                    type: "real",
                    def: 2.6,
                    min: 0.5,
                    max: 8,
                    step: 0.1
                },
                {
                    key: "minHeight",
                    label: "Idle height",
                    type: "real",
                    def: 0.02,
                    min: 0,
                    max: 0.4,
                    step: 0.01
                }
            ]
        },
        {
            type: "WaveLine",
            name: "Wave Line",
            blurb: "Audio-reactive wave, great as a divider",
            icon: "waves",
            category: "Media",
            size: {
                w: 460,
                h: 70
            },
            props: [
                {
                    key: "thickness",
                    label: "Line weight",
                    type: "real",
                    def: 3,
                    min: 1,
                    max: 12,
                    step: 0.5
                },
                {
                    key: "amplitude",
                    label: "Amplitude",
                    type: "real",
                    def: 1,
                    min: 0.1,
                    max: 3,
                    step: 0.1
                },
                {
                    key: "reactive",
                    label: "React to audio",
                    type: "bool",
                    def: true
                }
            ]
        },
        // ---------------------------------------------------------- Info ---
        {
            type: "WeatherCard",
            name: "Weather",
            blurb: "Current conditions plus an hourly strip",
            icon: "partly_cloudy_day",
            category: "Info",
            size: {
                w: 380,
                h: 200
            },
            props: [
                {
                    key: "location",
                    label: "Place, or lat,lon",
                    type: "string",
                    def: "",
                    placeholder: "blank = detect by IP"
                },
                {
                    key: "__relocate",
                    label: "Detected location",
                    type: "action",
                    action: "weather.relocate",
                    button: "Re-detect",
                    icon: "my_location",
                    def: null
                },
                {
                    key: "showPlace",
                    label: "Show place name",
                    type: "bool",
                    def: true
                },
                {
                    key: "details",
                    label: "Feels-like / wind / humidity",
                    type: "bool",
                    def: false
                },
                {
                    key: "units",
                    label: "Units",
                    type: "enum",
                    def: "metric",
                    options: ["metric", "imperial"]
                },
                {
                    key: "hourly",
                    label: "Hourly strip",
                    type: "bool",
                    def: true
                },
                {
                    key: "hours",
                    label: "Hours shown",
                    type: "int",
                    def: 5,
                    min: 2,
                    max: 12,
                    step: 1
                },
                {
                    key: "tempSize",
                    label: "Temperature size",
                    type: "int",
                    def: 46,
                    min: 16,
                    max: 120,
                    step: 2
                }
            ]
        },
        {
            type: "Greeting",
            name: "Greeting",
            blurb: "Time-aware hello with your name",
            icon: "waving_hand",
            category: "Info",
            size: {
                w: 480,
                h: 90
            },
            props: [
                {
                    key: "name",
                    label: "Name",
                    type: "string",
                    def: ""
                },
                {
                    key: "size",
                    label: "Text size",
                    type: "int",
                    def: 40,
                    min: 12,
                    max: 140,
                    step: 2
                },
                {
                    key: "weight",
                    label: "Weight",
                    type: "int",
                    def: 500,
                    min: 100,
                    max: 1000,
                    step: 50
                },
                {
                    key: "subtitle",
                    label: "Sub-line",
                    type: "string",
                    def: ""
                }
            ]
        },
        {
            type: "QuoteCard",
            name: "Quote",
            blurb: "Rotating line of text, refreshed on a timer",
            icon: "format_quote",
            category: "Info",
            size: {
                w: 420,
                h: 160
            },
            props: [
                {
                    key: "lines",
                    label: "Lines",
                    type: "list",
                    def: "Simplicity is the ultimate sophistication.\nMake it work, make it right, make it fast.\nThe details are not the details. They make the design."
                },
                {
                    key: "interval",
                    label: "Rotate every (min)",
                    type: "int",
                    def: 30,
                    min: 1,
                    max: 240,
                    step: 1
                },
                {
                    key: "size",
                    label: "Text size",
                    type: "int",
                    def: 20,
                    min: 10,
                    max: 64,
                    step: 1
                },
                {
                    key: "mark",
                    label: "Quote mark",
                    type: "bool",
                    def: true
                },
                {
                    key: "italic",
                    label: "Italic",
                    type: "bool",
                    def: false
                }
            ]
        },
        {
            type: "NotesCard",
            name: "Sticky Note",
            blurb: "Free-text scratchpad, saved as you type",
            icon: "edit_note",
            category: "Info",
            size: {
                w: 320,
                h: 240
            },
            props: [
                {
                    key: "text",
                    label: "Contents",
                    type: "text",
                    def: ""
                },
                {
                    key: "title",
                    label: "Title",
                    type: "string",
                    def: "Notes"
                },
                {
                    key: "size",
                    label: "Text size",
                    type: "int",
                    def: 14,
                    min: 9,
                    max: 40,
                    step: 1
                },
                {
                    key: "mono",
                    label: "Monospace",
                    type: "bool",
                    def: false
                }
            ]
        },
        {
            type: "TodoList",
            name: "Checklist",
            blurb: "Tickable to-dos that persist across restarts",
            icon: "checklist",
            category: "Info",
            size: {
                w: 320,
                h: 260
            },
            props: [
                {
                    key: "title",
                    label: "Title",
                    type: "string",
                    def: "Today"
                },
                {
                    key: "items",
                    label: "Items",
                    type: "list",
                    def: "Ship the desktop\nTouch grass"
                },
                {
                    key: "done",
                    label: "Completed",
                    type: "list",
                    def: ""
                },
                {
                    key: "size",
                    label: "Text size",
                    type: "int",
                    def: 14,
                    min: 9,
                    max: 32,
                    step: 1
                },
                {
                    key: "strike",
                    label: "Strike completed",
                    type: "bool",
                    def: true
                }
            ]
        },
        // --------------------------------------------------------- Shell ---
        {
            type: "AppDock",
            name: "App Dock",
            blurb: "Launcher row for the apps you actually use",
            icon: "apps",
            category: "Shell",
            size: {
                w: 380,
                h: 88
            },
            props: [
                {
                    key: "entries",
                    label: "Entries (icon|command)",
                    type: "list",
                    def: "terminal|foot\nfolder|nautilus\npublic|xdg-open https://example.com"
                },
                {
                    key: "iconSize",
                    label: "Icon size",
                    type: "int",
                    def: 26,
                    min: 12,
                    max: 72,
                    step: 1
                },
                {
                    key: "spacing",
                    label: "Spacing",
                    type: "int",
                    def: 10,
                    min: 0,
                    max: 48,
                    step: 1
                },
                {
                    key: "tileRadius",
                    label: "Tile radius",
                    type: "int",
                    def: 16,
                    min: 0,
                    max: 40,
                    step: 1
                },
                {
                    key: "orientation",
                    label: "Orientation",
                    type: "enum",
                    def: "row",
                    options: ["row", "column"]
                }
            ]
        },
        {
            type: "CommandTile",
            name: "Command Tile",
            blurb: "A big button that runs anything",
            icon: "bolt",
            category: "Shell",
            size: {
                w: 170,
                h: 120
            },
            props: [
                {
                    key: "icon",
                    label: "Icon",
                    type: "icon",
                    def: "rocket_launch"
                },
                {
                    key: "label",
                    label: "Label",
                    type: "string",
                    def: "Launch"
                },
                {
                    key: "command",
                    label: "Command",
                    type: "string",
                    def: ""
                },
                {
                    key: "iconSize",
                    label: "Icon size",
                    type: "int",
                    def: 34,
                    min: 12,
                    max: 96,
                    step: 1
                },
                {
                    key: "layout",
                    label: "Layout",
                    type: "enum",
                    def: "column",
                    options: ["column", "row"]
                }
            ]
        },
        {
            type: "Workspaces",
            name: "Workspaces",
            blurb: "Hyprland workspace pills you can click",
            icon: "view_carousel",
            category: "Shell",
            size: {
                w: 260,
                h: 56
            },
            props: [
                {
                    key: "count",
                    label: "Workspaces shown",
                    type: "int",
                    def: 6,
                    min: 1,
                    max: 20,
                    step: 1
                },
                {
                    key: "style",
                    label: "Style",
                    type: "enum",
                    def: "pills",
                    options: ["pills", "dots", "numbers"]
                },
                {
                    key: "size",
                    label: "Item size",
                    type: "int",
                    def: 30,
                    min: 10,
                    max: 72,
                    step: 1
                },
                {
                    key: "spacing",
                    label: "Spacing",
                    type: "int",
                    def: 8,
                    min: 0,
                    max: 32,
                    step: 1
                }
            ]
        },
        // --------------------------------------------------------- Decor ---
        {
            type: "TextLabel",
            name: "Text",
            blurb: "Any text, fully typographic",
            icon: "title",
            category: "Decor",
            size: {
                w: 320,
                h: 70
            },
            props: [
                {
                    key: "text",
                    label: "Text",
                    type: "text",
                    def: "Hello"
                },
                {
                    key: "size",
                    label: "Size",
                    type: "int",
                    def: 34,
                    min: 8,
                    max: 300,
                    step: 1
                },
                {
                    key: "weight",
                    label: "Weight",
                    type: "int",
                    def: 500,
                    min: 100,
                    max: 1000,
                    step: 50
                },
                {
                    key: "width",
                    label: "Width axis",
                    type: "int",
                    def: 100,
                    min: 25,
                    max: 151,
                    step: 1
                },
                {
                    key: "letterSpacing",
                    label: "Tracking",
                    type: "real",
                    def: 0,
                    min: -10,
                    max: 40,
                    step: 0.5
                },
                {
                    key: "lineHeight",
                    label: "Line height",
                    type: "real",
                    def: 1,
                    min: 0.6,
                    max: 3,
                    step: 0.05
                },
                {
                    key: "align",
                    label: "Align",
                    type: "enum",
                    def: "left",
                    options: ["left", "center", "right"]
                },
                {
                    key: "uppercase",
                    label: "Uppercase",
                    type: "bool",
                    def: false
                },
                {
                    key: "mono",
                    label: "Monospace",
                    type: "bool",
                    def: false
                },
                {
                    key: "glow",
                    label: "Legibility shadow",
                    type: "bool",
                    def: false
                }
            ]
        },
        {
            type: "IconBadge",
            name: "Icon",
            blurb: "A single material symbol, optionally in a disc",
            icon: "interests",
            category: "Decor",
            size: {
                w: 96,
                h: 96
            },
            props: [
                {
                    key: "icon",
                    label: "Icon",
                    type: "icon",
                    def: "favorite"
                },
                {
                    key: "size",
                    label: "Icon size",
                    type: "int",
                    def: 42,
                    min: 10,
                    max: 240,
                    step: 1
                },
                {
                    key: "fill",
                    label: "Filled",
                    type: "real",
                    def: 0,
                    min: 0,
                    max: 1,
                    step: 0.1
                },
                {
                    key: "weight",
                    label: "Weight",
                    type: "int",
                    def: 400,
                    min: 100,
                    max: 700,
                    step: 100
                },
                {
                    key: "disc",
                    label: "Disc behind icon",
                    type: "bool",
                    def: false
                },
                {
                    key: "command",
                    label: "Command on click",
                    type: "string",
                    def: ""
                }
            ]
        },
        {
            type: "GlassPanel",
            name: "Panel",
            blurb: "A grouping surface to sit other widgets on",
            icon: "crop_square",
            category: "Decor",
            size: {
                w: 420,
                h: 280
            },
            props: [
                {
                    key: "title",
                    label: "Title",
                    type: "string",
                    def: ""
                },
                {
                    key: "titleSize",
                    label: "Title size",
                    type: "int",
                    def: 13,
                    min: 8,
                    max: 40,
                    step: 1
                },
                {
                    key: "gradient",
                    label: "Gradient wash",
                    type: "bool",
                    def: true
                },
                {
                    key: "gradientTo",
                    label: "Gradient colour",
                    type: "colour",
                    def: "surfaceContainerLowest"
                }
            ]
        },
        {
            type: "DividerRule",
            name: "Rule",
            blurb: "A line. Sometimes that is all you need",
            icon: "horizontal_rule",
            category: "Decor",
            size: {
                w: 320,
                h: 24
            },
            props: [
                {
                    key: "thickness",
                    label: "Thickness",
                    type: "real",
                    def: 2,
                    min: 0.5,
                    max: 20,
                    step: 0.5
                },
                {
                    key: "orientation",
                    label: "Orientation",
                    type: "enum",
                    def: "horizontal",
                    options: ["horizontal", "vertical"]
                },
                {
                    key: "style",
                    label: "Style",
                    type: "enum",
                    def: "solid",
                    options: ["solid", "fade", "dotted"]
                },
                {
                    key: "cap",
                    label: "Rounded caps",
                    type: "bool",
                    def: true
                }
            ]
        },
        {
            type: "ImageFrame",
            name: "Image",
            blurb: "A picture, cropped and rounded to taste",
            icon: "image",
            category: "Decor",
            size: {
                w: 300,
                h: 200
            },
            props: [
                {
                    key: "path",
                    label: "Image path",
                    type: "string",
                    def: ""
                },
                {
                    key: "useWallpaper",
                    label: "Use current wallpaper",
                    type: "bool",
                    def: true
                },
                {
                    key: "fit",
                    label: "Fit",
                    type: "enum",
                    def: "cover",
                    options: ["cover", "contain", "stretch", "tile"]
                },
                {
                    key: "grayscale",
                    label: "Desaturate",
                    type: "real",
                    def: 0,
                    min: 0,
                    max: 1,
                    step: 0.05
                },
                {
                    key: "circle",
                    label: "Circular",
                    type: "bool",
                    def: false
                }
            ]
        }
    ]

    readonly property var byType: {
        const m = ({});
        for (const d of catalog)
            m[d.type] = d;
        return m;
    }

    function def(type: string): var {
        return byType[type] ?? null;
    }

    function defaults(type: string): var {
        const out = ({});
        for (const p of commonProps)
            out[p.key] = p.def;
        const d = def(type);
        if (d)
            for (const p of d.props) {
                // "action" rows are buttons, not stored state.
                if (p.type !== "action")
                    out[p.key] = p.def;
            }
        return out;
    }

    // Common + widget-specific schema, in the order the Inspector renders them.
    function schema(type: string): var {
        const d = def(type);
        return (d ? d.props : []).concat(commonProps);
    }

    function inCategory(cat: string): var {
        return catalog.filter(d => d.category === cat);
    }

    function search(query: string): var {
        const q = (query ?? "").trim().toLowerCase();
        if (!q)
            return catalog;
        return catalog.filter(d => d.name.toLowerCase().includes(q) || d.type.toLowerCase().includes(q) || d.blurb.toLowerCase().includes(q) || d.category.toLowerCase().includes(q));
    }
}
