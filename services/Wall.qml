pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.config

// Current wallpaper, read from the same state file the shell writes, so the
// editor canvas and any Image widget show what is actually on screen.
Singleton {
    id: root

    property string path: ""

    // Two candidates, because they disagree under Wallpaper Engine: path.txt
    // names the *scene* (a workshop entry, not an image file on disk), while
    // the `current` symlink always points at something openable - the scene's
    // thumbnail in that case, the wallpaper itself otherwise. Prefer path.txt,
    // since for an ordinary wallpaper it is the full-resolution original, and
    // fall back the moment it fails to load.
    readonly property url primary: root.fileUrl(root.path)
    readonly property url fallback: root.fileUrl(`${Theme.statePath}/wallpaper/current`)

    readonly property bool primaryBroken: probe.status === Image.Error
    readonly property url source: root.path && !root.primaryBroken ? root.primary : root.fallback
    readonly property bool valid: root.source.toString().length > 0

    // Percent-encode each path segment. A bare "file:///a b/c.jpg" is not a
    // valid URL and Qt refuses to open it - which is how a wallpaper living
    // under "Wallpaper Engine" silently failed to load, with nothing but a
    // "Cannot open" line to go on.
    function fileUrl(p: string): url {
        if (!p)
            return "";
        if (p.startsWith("file://"))
            return p;
        const expanded = p.replace(/^~/, Quickshell.env("HOME") ?? "");
        return "file://" + expanded.split("/").map(encodeURIComponent).join("/");
    }

    // A 1x1 decode is enough to find out whether the file opens at all, and
    // costs nothing next to loading a wallpaper twice.
    Image {
        id: probe

        source: root.primary
        asynchronous: true
        visible: false
        sourceSize: Qt.size(1, 1)
    }

    FileView {
        path: `${Theme.statePath}/wallpaper/path.txt`
        watchChanges: true
        printErrors: false
        onFileChanged: reload()
        onLoaded: root.path = text().trim()
    }
}
