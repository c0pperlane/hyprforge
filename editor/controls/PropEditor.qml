import QtQuick
import qs.components
import qs.config

// Renders one schema entry from Registry as the right kind of control.
// `liveChanged` fires continuously (slider drags), `changed` fires for discrete
// edits, and `began` fires once before a continuous edit so the caller can push
// a single undo entry.
Item {
    id: root

    property var spec: ({})
    property var value: undefined

    // Some editors span several keys at once (the corner radii), so they need
    // the whole prop set and the instance they belong to.
    property var allProps: ({})
    property string wid: ""

    signal changed(var value)
    signal liveChanged(var value)
    signal began
    // Rows of type "action" don't edit a prop - they ask the Inspector to run
    // something named (currently: re-detecting the weather location).
    signal triggered(string action)
    // Multi-key edit: a patch object merged into the widget's props.
    signal patched(var patch)

    readonly property string kind: spec.type ?? "string"
    readonly property bool stacked: root.kind === "text" || root.kind === "list"

    implicitHeight: loader.item ? loader.item.implicitHeight : 32
    height: implicitHeight

    Loader {
        id: loader

        width: parent.width

        sourceComponent: {
            switch (root.kind) {
            case "bool":
                return boolEditor;
            case "int":
            case "real":
                return numberEditor;
            case "enum":
                return enumEditor;
            case "colour":
                return colourEditor;
            case "text":
            case "list":
                return areaEditor;
            case "icon":
                return iconEditor;
            case "action":
                return actionEditor;
            case "corners":
                return cornersEditor;
            default:
                return stringEditor;
            }
        }
    }

    Component {
        id: boolEditor

        Row2 {
            label: root.spec.label ?? root.spec.key

            Sw {
                width: parent.width
                checked: !!root.value
                onToggled: v => root.changed(v)
            }
        }
    }

    Component {
        id: numberEditor

        Row2 {
            label: root.spec.label ?? root.spec.key
            labelWidth: 0.4

            Sld {
                width: parent.width
                from: root.spec.min ?? 0
                to: root.spec.max ?? 100
                step: root.spec.step ?? (root.spec.type === "int" ? 1 : 0.05)
                value: root.value ?? root.spec.def ?? 0
                onBegin: root.began()
                onMoved: v => root.liveChanged(v)
            }
        }
    }

    Component {
        id: enumEditor

        Row2 {
            label: root.spec.label ?? root.spec.key
            labelWidth: 0.38

            Sel {
                width: parent.width
                options: root.spec.options ?? []
                value: root.value ?? ""
                onPicked: v => root.changed(v)
            }
        }
    }

    Component {
        id: colourEditor

        Row2 {
            label: root.spec.label ?? root.spec.key

            ColourPick {
                width: parent.width
                value: root.value ?? "primary"
                onPicked: v => root.changed(v)
            }
        }
    }

    Component {
        id: stringEditor

        Row2 {
            label: root.spec.label ?? root.spec.key
            labelWidth: 0.36

            Fld {
                width: parent.width
                value: root.value ?? ""
                placeholder: root.spec.placeholder ?? ""
                onCommitted: v => root.changed(v)
            }
        }
    }

    Component {
        id: iconEditor

        Row2 {
            label: root.spec.label ?? root.spec.key
            labelWidth: 0.36

            Item {
                width: parent.width
                implicitHeight: 32

                Rectangle {
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    width: 32
                    height: 30
                    radius: 9
                    color: Theme.alpha(Theme.primary, 0.15)

                    Icon {
                        anchors.centerIn: parent
                        text: root.value ?? "help"
                        size: 17
                        color: Theme.primary
                    }
                }

                Fld {
                    anchors.left: parent.left
                    anchors.leftMargin: 38
                    anchors.right: parent.right
                    value: root.value ?? ""
                    placeholder: "material symbol"
                    mono: true
                    onCommitted: v => root.changed(v)
                }
            }
        }
    }

    Component {
        id: cornersEditor

        Row2 {
            label: root.spec.label ?? root.spec.key
            stacked: true

            CornerRadius {
                width: parent.width
                radius: root.allProps.radius ?? 22
                linked: root.allProps.radiusLinked ?? true
                tl: root.allProps.radiusTL ?? root.allProps.radius ?? 22
                tr: root.allProps.radiusTR ?? root.allProps.radius ?? 22
                bl: root.allProps.radiusBL ?? root.allProps.radius ?? 22
                br: root.allProps.radiusBR ?? root.allProps.radius ?? 22
                from: root.spec.min ?? 0
                to: root.spec.max ?? 80
                attached: Attach.cornersFor(root.wid)

                onChanged: patch => root.patched(patch)
            }
        }
    }

    Component {
        id: actionEditor

        Row2 {
            label: root.spec.label ?? root.spec.key
            labelWidth: 0.42

            Item {
                width: parent.width
                implicitHeight: 32

                Btn {
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    icon: root.spec.icon ?? "play_arrow"
                    label: root.spec.button ?? "Run"
                    iconSize: 15
                    padding: 10
                    radius: 10
                    colour: Theme.fgSurfaceVariant
                    hoverColour: Theme.primary
                    background: Theme.alpha(Theme.fgSurface, 0.07)
                    onClicked: root.triggered(root.spec.action ?? "")
                }
            }
        }
    }

    Component {
        id: areaEditor

        Row2 {
            label: root.spec.label ?? root.spec.key
            stacked: true

            Area {
                width: parent.width
                rows: root.kind === "list" ? 4 : 6
                value: root.value ?? ""
                mono: root.kind === "list"
                placeholder: root.kind === "list" ? "one per line" : ""
                onCommitted: v => root.changed(v)
            }
        }
    }
}
