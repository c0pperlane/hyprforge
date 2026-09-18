import QtQuick
import qs.components
import qs.config
import qs.services

// Month grid. Rebuilt only when the month changes, not every tick.
WidgetBase {
    id: root

    readonly property bool mondayFirst: root.flag("mondayFirst", true)
    readonly property real cell: root.num("cell", 34)
    readonly property int monthKey: Clock.now.getFullYear() * 100 + Clock.now.getMonth()

    readonly property var dayNames: {
        const base = ["Su", "Mo", "Tu", "We", "Th", "Fr", "Sa"];
        return root.mondayFirst ? base.slice(1).concat(base[0]) : base;
    }

    // Flat list of 42 cells: null for padding, otherwise the day number.
    readonly property int todayDate: Clock.now.getDate()

    // Derived from monthKey alone, so the 42 cells are rebuilt once a month
    // rather than on every clock tick. Reading Clock.now here (with a discarded
    // `void monthKey` alongside it, as this used to) made the whole grid
    // re-evaluate every minute for no reason.
    readonly property var cells: {
        const year = Math.floor(root.monthKey / 100);
        const month = root.monthKey % 100;
        const first = new Date(year, month, 1);
        const daysIn = new Date(year, month + 1, 0).getDate();
        let lead = first.getDay();
        if (root.mondayFirst)
            lead = (lead + 6) % 7;

        const out = [];
        for (let i = 0; i < lead; i++)
            out.push(null);
        for (let d = 1; d <= daysIn; d++)
            out.push(d);
        while (out.length % 7 !== 0)
            out.push(null);
        return out;
    }

    Column {
        anchors.fill: parent
        spacing: 6

        Txt {
            visible: root.flag("showHeader", true)
            width: parent.width
            text: Clock.fmt("MMMM yyyy")
            font.pixelSize: Math.max(12, root.cell * 0.46)
            font.weight: Font.DemiBold
            color: root.fg
        }

        Row {
            width: parent.width

            Repeater {
                model: root.dayNames

                Txt {
                    required property string modelData

                    width: root.cell
                    horizontalAlignment: Text.AlignHCenter
                    text: modelData
                    font.pixelSize: Math.max(9, root.cell * 0.3)
                    font.weight: Font.DemiBold
                    font.letterSpacing: 0.5
                    color: root.muted
                }
            }
        }

        Grid {
            columns: 7
            width: parent.width

            Repeater {
                model: root.cells

                Item {
                    required property var modelData

                    readonly property bool today: modelData === root.todayDate

                    width: root.cell
                    height: root.cell

                    Rectangle {
                        anchors.centerIn: parent
                        width: Math.min(parent.width, parent.height) - 3
                        height: width
                        radius: width / 2
                        color: parent.today ? root.accent : "transparent"
                    }

                    Txt {
                        anchors.centerIn: parent
                        text: modelData === null ? "" : `${modelData}`
                        font.pixelSize: Math.max(10, root.cell * 0.38)
                        font.weight: parent.today ? Font.Bold : Font.Normal
                        color: parent.today ? Theme.contrast(root.accent) : root.fg
                    }
                }
            }
        }
    }
}
