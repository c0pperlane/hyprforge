import QtQuick
import QtQuick.Effects
import Quickshell.Widgets
import qs.components
import qs.config
import qs.services

// A picture: a file you point at, or whatever the wallpaper currently is.
WidgetBase {
    id: root

    readonly property url src: {
        if (root.flag("useWallpaper", true))
            return Wall.source;
        const p = root.str("path", "").trim();
        if (!p)
            return "";
        // Remote URLs pass through; local paths go through the same
        // percent-encoding the wallpaper does, so spaces in a folder name
        // don't quietly break the image.
        if (/^[a-z][a-z0-9+.-]*:\/\//i.test(p))
            return p;
        return Wall.fileUrl(p);
    }

    ClippingRectangle {
        anchors.fill: parent
        radius: root.flag("circle", false) ? Math.min(width, height) / 2 : root.num("radius", 22)
        color: Theme.alpha(root.fg, 0.06)

        Image {
            anchors.fill: parent
            source: root.src
            asynchronous: true
            smooth: Settings.appearance.smoothImages
            mipmap: Settings.appearance.mipmaps
            cache: true
            fillMode: {
                switch (root.str("fit", "cover")) {
                case "contain":
                    return Image.PreserveAspectFit;
                case "stretch":
                    return Image.Stretch;
                case "tile":
                    return Image.Tile;
                default:
                    return Image.PreserveAspectCrop;
                }
            }

            // MultiEffect.saturation goes to -1 for fully grey, so the
            // 0..1 "desaturate" prop maps straight onto it.
            layer.enabled: root.num("grayscale", 0) > 0
            layer.effect: MultiEffect {
                saturation: -root.num("grayscale", 0)
            }
        }

        Icon {
            anchors.centerIn: parent
            visible: !root.src
            text: "image"
            size: Math.min(parent.width, parent.height) * 0.3
            color: Theme.alpha(root.fg, 0.35)
        }
    }
}
