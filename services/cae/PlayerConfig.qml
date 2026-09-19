import QtQuick
import Caelestia.Config

// The shell's own rule for which MPRIS player is "active" lives in its
// config, not in anything Media.qml can see on its own. Exposed here so
// Media.qml can pick the same player caelestia's topbar does - otherwise the
// two processes can resolve different "active" players when more than one is
// present, and Forge ends up asking for lyrics (or showing art/title) for a
// different track than the one caelestia's pipeline actually fetched.
Item {
    readonly property string defaultPlayer: GlobalConfig.services.defaultPlayer
    readonly property var playerAliases: GlobalConfig.services.playerAliases
}
