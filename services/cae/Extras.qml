import QtQuick
import Caelestia.Services
import Quickshell.Hyprland

// Hyprland extras: keyboard layout details the standard IPC does not expose.
Item {
    readonly property var devices: extras.devices ?? null

    HyprExtras {
        id: extras

        usingLua: Hyprland.usingLua
    }
}
