import QtQuick
import qs.components
import qs.config
import qs.services

// Capacity bars for the mounts you name. Falls back to the primary disk when
// a mount isn't found, so the widget is never empty.
WidgetBase {
    id: root

    needs: ["sys.storage"]

    // The service reports whatever identifier it has for each disk - on this
    // machine that's a device name ("nvme0n1") rather than a mount point - so
    // the filter matches loosely instead of demanding an exact string, and an
    // empty filter simply shows everything.
    readonly property var wanted: root.lines("mounts")

    function matches(name: string): bool {
        if (!root.wanted.length)
            return true;
        return root.wanted.some(w => name === w || name.endsWith(w) || w.endsWith(name));
    }

    readonly property var rows: {
        const out = [];
        for (const d of Sys.disks) {
            if (!root.matches(d.mount))
                continue;
            out.push({
                mount: d.mount,
                perc: Sys.norm(d.perc),
                used: d.used,
                total: d.total,
                free: d.free
            });
        }
        return out;
    }


    Column {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        spacing: 14

        Repeater {
            model: root.rows

            Item {
                id: row

                required property var modelData
                required property int index

                readonly property color tint: Theme.chart[index % Theme.chart.length]

                width: parent.width
                height: 34

                Icon {
                    id: diskIcon

                    anchors.left: parent.left
                    anchors.top: parent.top
                    text: "hard_disk"
                    size: 15
                    color: row.tint
                }

                ListTxt {
                    anchors.left: diskIcon.right
                    anchors.leftMargin: 6
                    anchors.top: parent.top
                    text: row.modelData.mount
                    font.family: Theme.mono
                    font.pixelSize: 12
                    color: root.muted
                }

                ListTxt {
                    anchors.right: parent.right
                    anchors.top: parent.top
                    text: root.flag("showFree", true) ? `${Sys.bytes(row.modelData.free)} free` : `${Math.round(row.modelData.perc * 100)}%`
                    font.pixelSize: 12
                    color: root.fg
                }

                Meter {
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.bottom: parent.bottom
                    value: row.modelData.perc
                    thickness: root.num("thickness", 8)
                    colour: row.modelData.perc > 0.9 ? Theme.error : row.tint
                    trackColour: Theme.alpha(root.fg, 0.12)
                }
            }
        }

        ListTxt {
            visible: !root.rows.length
            text: Sys.disks.length ? "No disks matched the filter" : "No disks reported"
            font.pixelSize: 12
            color: root.muted
        }
    }
}
