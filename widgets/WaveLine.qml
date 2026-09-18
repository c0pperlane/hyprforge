import QtQuick
import Caelestia.Components
import qs.components
import qs.config
import qs.services

// A travelling wave that swells with the audio level. Reads as a divider when
// nothing is playing, and comes alive when something is.
WidgetBase {
    id: root

    needs: root.flag("reactive", true) ? ["cava"] : []

    readonly property string cavaId: `wave${Math.random().toString(36).slice(2, 8)}`

    onLiveChanged: root.syncCava()
    Component.onCompleted: root.syncCava()
    Component.onDestruction: Cava.release(root.cavaId)

    // Registering a bar count is what sizes the shared capture; doing it while
    // off-screen would keep cava running for a widget nobody can see.
    function syncCava(): void {
        if (root.live && root.needs.indexOf("cava") >= 0)
            Cava.request(root.cavaId, 16);
        else
            Cava.release(root.cavaId);
    }

    WavyLine {
        id: line

        anchors.left: parent.left
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        height: parent.height

        color: root.accent
        lineWidth: Math.round(root.num("thickness", 3))
        frequency: 3
        startX: 0
        fullLength: width
        amplitudeMultiplier: root.num("amplitude", 1) * (root.flag("reactive", true) ? 0.35 + Cava.level * 2.2 : 1)
        value: 1

        Behavior on amplitudeMultiplier {
            NumberAnimation {
                duration: 110
            }
        }
    }

    NumberAnimation {
        target: line
        property: "waveProgress"
        from: 0
        to: 1
        duration: 2600
        loops: Animation.Infinite
        running: root.visible
    }
}
