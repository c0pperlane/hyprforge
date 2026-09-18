pragma Singleton

import QtQuick
import Quickshell

// Compile-time map of widget type name -> Component.
//
// Loading widgets by URL worked, but those files were then invisible to
// Quickshell's file watcher: editing a widget did not hot-reload, and a typo
// only showed up as a runtime warning on the one instance that used it.
// Declaring them here makes every widget a real dependency of the config, so
// edits reload live and mistakes are reported at load time.
//
// Declaring is not constructing: nothing here is instantiated until a layout
// actually references the type, so an unplaced widget costs one registration.
//
// Generated from the contents of widgets/ - add a file, add two lines here.
Singleton {
    id: root

    readonly property var map: ({
            AnalogClock: analogClockComp,
            AppDock: appDockComp,
            BatteryCard: batteryCardComp,
            BluetoothCard: bluetoothCardComp,
            Brightness: brightnessComp,
            CalendarCard: calendarCardComp,
            ClipboardHistory: clipboardHistoryComp,
            CommandTile: commandTileComp,
            CoreLoad: coreLoadComp,
            CStateMeter: cStateMeterComp,
            Countdown: countdownComp,
            DateCard: dateCardComp,
            DiskGauge: diskGaugeComp,
            DiskMeter: diskMeterComp,
            DividerRule: dividerRuleComp,
            GlassPanel: glassPanelComp,
            Greeting: greetingComp,
            HeroClock: heroClockComp,
            IconBadge: iconBadgeComp,
            IdleInhibitor: idleInhibitorComp,
            ImageFrame: imageFrameComp,
            KeyboardLayout: keyboardLayoutComp,
            LyricsCard: lyricsCardComp,
            MediaMini: mediaMiniComp,
            MoonPhase: moonPhaseComp,
            NetInterfaces: netInterfacesComp,
            NetSpeed: netSpeedComp,
            NotesCard: notesCardComp,
            NowPlaying: nowPlayingComp,
            PaletteSwatches: paletteSwatchesComp,
            ParkedCores: parkedCoresComp,
            Pomodoro: pomodoroComp,
            ProcessTop: processTopComp,
            QuoteCard: quoteCardComp,
            Sensors: sensorsComp,
            SparkGraph: sparkGraphComp,
            StackClock: stackClockComp,
            StatRing: statRingComp,
            StatStack: statStackComp,
            Stopwatch: stopwatchComp,
            SunClock: sunClockComp,
            SysInfoCard: sysInfoCardComp,
            TextLabel: textLabelComp,
            TodoList: todoListComp,
            UptimeRing: uptimeRingComp,
            Visualiser: visualiserComp,
            VolumeDial: volumeDialComp,
            WaveLine: waveLineComp,
            WeatherCard: weatherCardComp,
            Workspaces: workspacesComp,
            WorldClock: worldClockComp
        })

    function component(type: string): Component {
        return root.map[type] ?? null;
    }

    function has(type: string): bool {
        return !!root.map[type];
    }

    Component {
        id: analogClockComp

        AnalogClock {}
    }

    Component {
        id: appDockComp

        AppDock {}
    }

    Component {
        id: batteryCardComp

        BatteryCard {}
    }

    Component {
        id: bluetoothCardComp

        BluetoothCard {}
    }

    Component {
        id: brightnessComp

        Brightness {}
    }

    Component {
        id: calendarCardComp

        CalendarCard {}
    }

    Component {
        id: clipboardHistoryComp

        ClipboardHistory {}
    }

    Component {
        id: commandTileComp

        CommandTile {}
    }

    Component {
        id: coreLoadComp

        CoreLoad {}
    }

    Component {
        id: cStateMeterComp

        CStateMeter {}
    }

    Component {
        id: countdownComp

        Countdown {}
    }

    Component {
        id: dateCardComp

        DateCard {}
    }

    Component {
        id: diskGaugeComp

        DiskGauge {}
    }

    Component {
        id: diskMeterComp

        DiskMeter {}
    }

    Component {
        id: dividerRuleComp

        DividerRule {}
    }

    Component {
        id: glassPanelComp

        GlassPanel {}
    }

    Component {
        id: greetingComp

        Greeting {}
    }

    Component {
        id: heroClockComp

        HeroClock {}
    }

    Component {
        id: iconBadgeComp

        IconBadge {}
    }

    Component {
        id: idleInhibitorComp

        IdleInhibitor {}
    }

    Component {
        id: imageFrameComp

        ImageFrame {}
    }

    Component {
        id: keyboardLayoutComp

        KeyboardLayout {}
    }

    Component {
        id: lyricsCardComp

        LyricsCard {}
    }

    Component {
        id: mediaMiniComp

        MediaMini {}
    }

    Component {
        id: moonPhaseComp

        MoonPhase {}
    }

    Component {
        id: netInterfacesComp

        NetInterfaces {}
    }

    Component {
        id: netSpeedComp

        NetSpeed {}
    }

    Component {
        id: notesCardComp

        NotesCard {}
    }

    Component {
        id: nowPlayingComp

        NowPlaying {}
    }

    Component {
        id: paletteSwatchesComp

        PaletteSwatches {}
    }

    Component {
        id: parkedCoresComp

        ParkedCores {}
    }

    Component {
        id: pomodoroComp

        Pomodoro {}
    }

    Component {
        id: processTopComp

        ProcessTop {}
    }

    Component {
        id: quoteCardComp

        QuoteCard {}
    }

    Component {
        id: sensorsComp

        Sensors {}
    }

    Component {
        id: sparkGraphComp

        SparkGraph {}
    }

    Component {
        id: stackClockComp

        StackClock {}
    }

    Component {
        id: statRingComp

        StatRing {}
    }

    Component {
        id: statStackComp

        StatStack {}
    }

    Component {
        id: stopwatchComp

        Stopwatch {}
    }

    Component {
        id: sunClockComp

        SunClock {}
    }

    Component {
        id: sysInfoCardComp

        SysInfoCard {}
    }

    Component {
        id: textLabelComp

        TextLabel {}
    }

    Component {
        id: todoListComp

        TodoList {}
    }

    Component {
        id: uptimeRingComp

        UptimeRing {}
    }

    Component {
        id: visualiserComp

        Visualiser {}
    }

    Component {
        id: volumeDialComp

        VolumeDial {}
    }

    Component {
        id: waveLineComp

        WaveLine {}
    }

    Component {
        id: weatherCardComp

        WeatherCard {}
    }

    Component {
        id: workspacesComp

        Workspaces {}
    }

    Component {
        id: worldClockComp

        WorldClock {}
    }
}
