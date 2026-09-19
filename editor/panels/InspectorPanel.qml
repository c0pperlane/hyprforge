pragma ComponentBehavior: Bound

import QtQuick
import qs.components
import qs.config
import qs.editor
import qs.editor.controls
import qs.services

// Property editor for the current selection.
//
// Entirely schema-driven: it reads Registry.schema(type) and renders a control
// per entry, so a new knob on a widget needs no code here at all.
FloatingPanel {
    id: root

    readonly property string wid: EditorState.primary
    readonly property var instance: root.wid ? Store.get(root.wid) : null
    readonly property string type: root.instance?.type ?? ""
    readonly property var def: root.type ? Registry.def(root.type) : null
    readonly property var props: root.wid ? Store.props(root.wid) : ({})

    // Schema entries split into the widget's own knobs and the shared ones.
    // "hidden" rows exist so the values are defaulted and persisted, but are
    // edited through another control - the four per-corner radii belong to the
    // corner editor, not to four separate sliders.
    readonly property var ownProps: (root.def?.props ?? []).filter(p => p.type !== "hidden")
    readonly property var surfaceProps: Registry.commonProps.filter(p => p.group === "Surface" && p.type !== "hidden")
    readonly property var colourProps: Registry.commonProps.filter(p => p.group === "Colour" && p.type !== "hidden")

    function setProp(key: string, value: var, record: bool): void {
        if (root.wid)
            Store.setProp(root.wid, key, value, record ?? true);
    }

    // Named side effects a schema row can ask for. Kept here rather than in the
    // control so the controls stay dumb.
    function runAction(action: string): void {
        switch (action) {
        case "weather.relocate":
            WeatherSvc.relocate();
            EditorState.status("Re-detecting location…");
            break;
        case "shadow.applyAll":
            if (root.wid) {
                const n = Store.applyShadowToScreen(root.wid, EditorState.target);
                EditorState.status(n > 0 ? `Applied this shadow to ${n} widget${n === 1 ? "" : "s"}` : "Nothing else to apply it to");
            }
            break;
        }
    }

    // Merges several prop changes as one undo step.
    function applyPatch(patch: var): void {
        if (!root.wid || !patch)
            return;
        Store.pushUndo();
        Store.setProps(root.wid, Object.assign(Store.props(root.wid), patch));
    }

    function setGeom(key: string, value: real): void {
        if (!root.wid)
            return;
        Store.pushUndo();
        Store.set(root.wid, key, Math.round(value), false);
    }

    title: "Inspector"
    icon: "tune"

    Item {
        anchors.fill: parent

        // --- empty state --------------------------------------------------
        Column {
            anchors.centerIn: parent
            width: parent.width - 50
            spacing: 10
            visible: !root.instance

            Icon {
                anchors.horizontalCenter: parent.horizontalCenter
                text: "ads_click"
                size: 30
                color: Theme.fgSurfaceVariant
            }

            Txt {
                width: parent.width
                horizontalAlignment: Text.AlignHCenter
                text: "Select an element to tune it"
                font.pixelSize: 12
                color: Theme.fgSurfaceVariant
                wrapMode: Text.Wrap
            }
        }

        // --- multi-selection ----------------------------------------------
        Column {
            anchors.centerIn: parent
            width: parent.width - 50
            spacing: 10
            visible: EditorState.multiSelection

            Icon {
                anchors.horizontalCenter: parent.horizontalCenter
                text: "select_all"
                size: 30
                color: Theme.primary
            }

            Txt {
                width: parent.width
                horizontalAlignment: Text.AlignHCenter
                text: `${EditorState.selection.length} elements selected`
                font.pixelSize: 13
                font.weight: Font.DemiBold
                color: Theme.fgSurface
            }

            Txt {
                width: parent.width
                horizontalAlignment: Text.AlignHCenter
                text: "Use the alignment tools in the toolbar, or select a single element to edit its properties."
                font.pixelSize: 11
                color: Theme.fgSurfaceVariant
                wrapMode: Text.Wrap
            }
        }

        // --- single selection ---------------------------------------------
        Flickable {
            anchors.fill: parent
            anchors.leftMargin: 14
            anchors.rightMargin: 14
            anchors.topMargin: 8
            anchors.bottomMargin: 12
            visible: !!root.instance && !EditorState.multiSelection
            contentHeight: form.implicitHeight
            clip: true
            boundsBehavior: Flickable.StopAtBounds

            Column {
                id: form

                width: parent.width
                spacing: 4

                // Header
                Item {
                    width: parent.width
                    height: 52

                    Rectangle {
                        id: typeIcon

                        anchors.left: parent.left
                        anchors.verticalCenter: parent.verticalCenter
                        width: 36
                        height: 36
                        radius: 12
                        color: Theme.alpha(Theme.primary, 0.18)

                        Icon {
                            anchors.centerIn: parent
                            text: root.def?.icon ?? "widgets"
                            size: 19
                            color: Theme.primary
                        }
                    }

                    Column {
                        anchors.left: typeIcon.right
                        anchors.leftMargin: 10
                        anchors.right: headerActions.left
                        anchors.rightMargin: 6
                        anchors.verticalCenter: parent.verticalCenter

                        Txt {
                            width: parent.width
                            text: root.def?.name ?? root.type
                            font.pixelSize: 14
                            font.weight: Font.DemiBold
                            color: Theme.fgSurface
                        }

                        Txt {
                            width: parent.width
                            text: root.def?.category ?? ""
                            font.pixelSize: 11
                            color: Theme.fgSurfaceVariant
                        }
                    }

                    Row {
                        id: headerActions

                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter

                        Btn {
                            icon: root.instance?.locked ? "lock" : "lock_open"
                            iconSize: 17
                            padding: 6
                            checked: root.instance?.locked ?? false
                            colour: Theme.fgSurfaceVariant
                            hoverColour: Theme.primary
                            onClicked: Store.set(root.wid, "locked", !root.instance.locked, true)
                        }

                        Btn {
                            icon: root.instance?.hidden ? "visibility_off" : "visibility"
                            iconSize: 17
                            padding: 6
                            checked: root.instance?.hidden ?? false
                            colour: Theme.fgSurfaceVariant
                            hoverColour: Theme.primary
                            onClicked: Store.set(root.wid, "hidden", !root.instance.hidden, true)
                        }
                    }
                }

                // --- geometry -------------------------------------------
                Section {
                    title: "Layout"
                    icon: "open_with"

                    Grid {
                        width: parent.width
                        columns: 2
                        columnSpacing: 10
                        rowSpacing: 8

                        NumBox {
                            width: (parent.width - 10) / 2
                            label: "X"
                            value: root.instance?.x ?? 0
                            onCommitted: v => root.setGeom("x", v)
                        }

                        NumBox {
                            width: (parent.width - 10) / 2
                            label: "Y"
                            value: root.instance?.y ?? 0
                            onCommitted: v => root.setGeom("y", v)
                        }

                        NumBox {
                            width: (parent.width - 10) / 2
                            label: "W"
                            value: root.instance?.w ?? 0
                            onCommitted: v => root.setGeom("w", Math.max(20, v))
                        }

                        NumBox {
                            width: (parent.width - 10) / 2
                            label: "H"
                            value: root.instance?.h ?? 0
                            onCommitted: v => root.setGeom("h", Math.max(20, v))
                        }
                    }

                    Row2 {
                        label: "Rotation"

                        Sld {
                            width: parent.width
                            from: -180
                            to: 180
                            step: 1
                            value: root.instance?.rot ?? 0
                            onBegin: Store.pushUndo()
                            onMoved: v => Store.set(root.wid, "rot", v, false)
                        }
                    }

                    Row2 {
                        label: "Opacity"

                        Sld {
                            width: parent.width
                            from: 0
                            to: 1
                            step: 0.01
                            value: root.instance?.op ?? 1
                            onBegin: Store.pushUndo()
                            onMoved: v => Store.set(root.wid, "op", v, false)
                        }
                    }

                    Row2 {
                        label: "Stacking"

                        Row {
                            width: parent.width
                            spacing: 6
                            layoutDirection: Qt.RightToLeft

                            Btn {
                                icon: "flip_to_back"
                                iconSize: 17
                                padding: 7
                                colour: Theme.fgSurfaceVariant
                                hoverColour: Theme.primary
                                onClicked: Store.toBack(root.wid)
                            }

                            Btn {
                                icon: "flip_to_front"
                                iconSize: 17
                                padding: 7
                                colour: Theme.fgSurfaceVariant
                                hoverColour: Theme.primary
                                onClicked: Store.toFront(root.wid)
                            }
                        }
                    }
                }

                // --- widget properties -----------------------------------
                Section {
                    title: root.def?.name ?? "Properties"
                    icon: root.def?.icon ?? "widgets"
                    visible: root.ownProps.length > 0

                    Repeater {
                        model: root.ownProps

                        PropEditor {
                            required property var modelData

                            width: parent.width
                            spec: modelData
                            value: root.props[modelData.key]
                            allProps: root.props
                            wid: root.wid
                            onChanged: v => root.setProp(modelData.key, v, true)
                            onLiveChanged: v => root.setProp(modelData.key, v, false)
                            onBegan: Store.pushUndo()
                            onTriggered: a => root.runAction(a)
                            onPatched: patch => root.applyPatch(patch)
                        }
                    }
                }

                // --- visibility -----------------------------------------
                Section {
                    title: "Visibility"
                    icon: "visibility"
                    expanded: Cond.has(Store.parseCond(root.instance?.cond))

                    CondEditor {
                        width: parent.width
                        wid: root.wid
                    }
                }

                // --- surface ---------------------------------------------
                Section {
                    title: "Surface"
                    icon: "layers"
                    expanded: false

                    Repeater {
                        model: root.surfaceProps

                        PropEditor {
                            required property var modelData

                            width: parent.width
                            spec: modelData
                            value: root.props[modelData.key]
                            allProps: root.props
                            wid: root.wid
                            onChanged: v => root.setProp(modelData.key, v, true)
                            onLiveChanged: v => root.setProp(modelData.key, v, false)
                            onBegan: Store.pushUndo()
                            onTriggered: a => root.runAction(a)
                            onPatched: patch => root.applyPatch(patch)
                        }
                    }
                }

                // --- colour ----------------------------------------------
                Section {
                    title: "Colour"
                    icon: "palette"
                    expanded: false

                    Repeater {
                        model: root.colourProps

                        PropEditor {
                            required property var modelData

                            width: parent.width
                            spec: modelData
                            value: root.props[modelData.key]
                            allProps: root.props
                            wid: root.wid
                            onChanged: v => root.setProp(modelData.key, v, true)
                            onLiveChanged: v => root.setProp(modelData.key, v, false)
                            onBegan: Store.pushUndo()
                            onTriggered: a => root.runAction(a)
                            onPatched: patch => root.applyPatch(patch)
                        }
                    }
                }

                Item {
                    width: parent.width
                    height: 10
                }

                // --- actions ---------------------------------------------
                Row {
                    width: parent.width
                    spacing: 8

                    Btn {
                        icon: "restart_alt"
                        label: "Reset"
                        iconSize: 16
                        padding: 11
                        colour: Theme.fgSurfaceVariant
                        hoverColour: Theme.primary
                        background: Theme.alpha(Theme.fgSurface, 0.06)
                        radius: 12
                        onClicked: Store.resetProps(root.wid)
                    }

                    Btn {
                        icon: "content_copy"
                        label: "Duplicate"
                        iconSize: 16
                        padding: 11
                        colour: Theme.fgSurfaceVariant
                        hoverColour: Theme.primary
                        background: Theme.alpha(Theme.fgSurface, 0.06)
                        radius: 12
                        onClicked: EditorState.select(Store.duplicate(root.wid))
                    }

                    Btn {
                        icon: "delete"
                        iconSize: 16
                        padding: 11
                        colour: Theme.error
                        hoverColour: Theme.error
                        background: Theme.alpha(Theme.error, 0.1)
                        radius: 12
                        onClicked: Store.remove(root.wid)
                    }
                }

                Item {
                    width: parent.width
                    height: 14
                }
            }
        }
    }

    // Compact labelled number box for geometry.
    component NumBox: Item {
        id: box

        property string label: ""
        property real value: 0

        signal committed(real value)

        height: 34

        Rectangle {
            anchors.fill: parent
            radius: 10
            color: Theme.alpha(Theme.fgSurface, numInput.activeFocus ? 0.12 : 0.06)
            border.width: numInput.activeFocus ? 1 : 0
            border.color: Theme.primary

            Txt {
                id: boxLabel

                anchors.left: parent.left
                anchors.leftMargin: 10
                anchors.verticalCenter: parent.verticalCenter
                text: box.label
                font.pixelSize: 11
                font.weight: Font.Bold
                color: Theme.fgSurfaceVariant
            }

            TextInput {
                id: numInput

                anchors.left: boxLabel.right
                anchors.leftMargin: 8
                anchors.right: parent.right
                anchors.rightMargin: 10
                anchors.verticalCenter: parent.verticalCenter
                horizontalAlignment: Text.AlignRight
                font.family: Theme.mono
                font.pixelSize: 12
                color: Theme.fgSurface
                selectionColor: Theme.primary
                selectedTextColor: Theme.fgPrimary
                selectByMouse: true

                text: `${Math.round(box.value)}`

                onEditingFinished: {
                    const v = parseFloat(text);
                    if (!isNaN(v))
                        box.committed(v);
                    focus = false;
                }
            }

            MouseArea {
                anchors.fill: parent
                acceptedButtons: Qt.NoButton
                cursorShape: Qt.SizeHorCursor
                onWheel: wheel => box.committed(box.value + (wheel.angleDelta.y > 0 ? 1 : -1) * (wheel.modifiers & Qt.ShiftModifier ? 10 : 1))
            }
        }
    }
}
