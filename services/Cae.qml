pragma Singleton

import QtQuick
import Quickshell

// Optional caelestia-shell integration.
//
// Forge grew up inside the caelestia dots and used its C++ services directly.
// That made caelestia a hard requirement for reasons that have nothing to do
// with the designer: a QML `import` of a missing module is a compile error, so
// one absent plugin took the entire config down rather than one widget.
//
// Everything that touches Caelestia.* now lives in services/cae/, loaded at
// runtime. `available` is the answer to "is caelestia-shell installed", and
// every consumer reads through the accessors here with a plain-QML fallback
// behind it. On a caelestia system nothing changes; on a bare Hyprland box the
// metrics come from /proc and the few genuinely caelestia-only features say so
// instead of vanishing.
Singleton {
    id: root

    // Probing by creating the component: the failure is contained here, where
    // it is a status code, instead of propagating out of an import statement.
    readonly property Component probe: Qt.createComponent(Qt.resolvedUrl("cae/Probe.qml"), Component.PreferSynchronous)
    readonly property bool available: root.probe.status === Component.Ready

    readonly property string unavailableReason: root.available ? "" : "caelestia-shell's QML plugins are not installed"

    // Loaded only when the probe says they will load. Each stays null
    // otherwise, and every reader is written to expect that.
    readonly property var metrics: metricsLoader.item
    readonly property var audio: audioLoader.item
    readonly property var words: wordsLoader.item
    readonly property var extras: extrasLoader.item

    Component.onCompleted: {
        if (!root.available)
            console.info("Forge: running without caelestia-shell -", root.probe.errorString().trim().split("\n")[0], "- system metrics will come from /proc instead");
    }

    Loader {
        id: metricsLoader

        active: root.available
        source: "cae/Metrics.qml"
    }

    Loader {
        id: audioLoader

        active: root.available
        source: "cae/Audio.qml"
    }

    Loader {
        id: wordsLoader

        active: root.available
        source: "cae/Words.qml"
    }

    Loader {
        id: extrasLoader

        active: root.available
        source: "cae/Extras.qml"
    }
}
