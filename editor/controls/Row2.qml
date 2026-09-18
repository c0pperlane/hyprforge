import QtQuick
import qs.components
import qs.config

// Label-on-the-left settings row. Everything in the Inspector is built from
// this so the column of controls lines up regardless of editor type.
Item {
    id: root

    property string label: ""
    property string hint: ""
    property real labelWidth: 0.46
    property bool stacked: false

    default property alias control: holder.data

    implicitHeight: root.stacked ? labelText.implicitHeight + holder.implicitHeight + 6 : Math.max(30, holder.implicitHeight)
    width: parent ? parent.width : 240

    Txt {
        id: labelText

        anchors.left: parent.left
        anchors.top: root.stacked ? parent.top : undefined
        anchors.verticalCenter: root.stacked ? undefined : parent.verticalCenter
        width: root.stacked ? parent.width : parent.width * root.labelWidth - 8
        text: root.label
        font.pixelSize: 12
        font.weight: Font.Medium
        color: Theme.fgSurfaceVariant
        elide: Text.ElideRight
    }

    Item {
        id: holder

        anchors.right: parent.right
        anchors.left: root.stacked ? parent.left : undefined
        anchors.top: root.stacked ? labelText.bottom : undefined
        anchors.topMargin: root.stacked ? 6 : 0
        anchors.verticalCenter: root.stacked ? undefined : parent.verticalCenter
        width: root.stacked ? parent.width : parent.width * (1 - root.labelWidth)
        // Controls placed here are expected to set `width: parent.width`;
        // they then lay themselves out inside the right-hand column.
        implicitHeight: childrenRect.height
    }
}
