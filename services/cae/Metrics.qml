import QtQuick
import Caelestia.Services
import qs.config

// caelestia-shell's system metrics, behind a flat surface.
//
// Sys reads these through Cae rather than importing Caelestia itself, so that
// the whole config still loads on a machine that has Quickshell and Hyprland
// but not caelestia. Everything here is a plain property: the fallbacks in Sys
// have to be substitutable for them one for one.
Item {
    readonly property real cpuPercent: Cpu.percentage
    readonly property string cpuName: Cpu.name
    readonly property real cpuTemp: Cpu.temperature || 0

    readonly property real memPercent: Memory.percentage
    // kB, as the service reports them.
    readonly property real memUsed: Memory.used
    readonly property real memTotal: Memory.total

    readonly property real gpuPercent: Gpu.percentage
    readonly property string gpuName: Gpu.name
    readonly property real gpuTemp: Gpu.temperature || 0

    readonly property real storagePercent: Storage.percentage
    readonly property var storagePrimary: Storage.primaryDisk
    readonly property var storageDisks: Storage.disks ?? []

    readonly property real netUp: NetworkUsage.uploadSpeed
    readonly property real netDown: NetworkUsage.downloadSpeed
    readonly property real netUpTotal: NetworkUsage.uploadTotal
    readonly property real netDownTotal: NetworkUsage.downloadTotal

    // Assigning null releases the reference, which is what stops the
    // underlying poller - these services only tick while referenced.
    ServiceRef {
        service: Demand.needed("sys.cpu") ? Cpu : null
    }

    ServiceRef {
        service: Demand.needed("sys.memory") ? Memory : null
    }

    ServiceRef {
        service: Demand.needed("sys.gpu") ? Gpu : null
    }

    ServiceRef {
        service: Demand.needed("sys.storage") ? Storage : null
    }

    ServiceRef {
        service: Demand.needed("sys.net") ? NetworkUsage : null
    }
}
