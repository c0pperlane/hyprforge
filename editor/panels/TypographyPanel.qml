pragma ComponentBehavior: Bound

import QtQuick
import qs.components
import qs.config
import qs.editor
import qs.editor.controls
import qs.services

// Pick a font once, push it everywhere.
//
// Forge applies its own choice live; the rest goes out through
// `hyprforge-fonts`, which edits the shell config, fontconfig, the GTK
// settings and Discord's user CSS - each of them optional, all of them
// revertible from the button at the bottom.
FloatingPanel {
    id: root

    readonly property var targetList: [
        {
            id: "forge",
            label: "Forge widgets",
            blurb: "This app's own desktop elements",
            icon: "dashboard_customize"
        },
        {
            id: "shell",
            label: "Caelestia shell",
            blurb: "Bar, drawers, launcher, notifications",
            icon: "web_asset"
        },
        {
            id: "fontconfig",
            label: "System default",
            blurb: "The sans / serif / mono every toolkit resolves",
            icon: "settings_applications"
        },
        {
            id: "gtk",
            label: "GTK apps",
            blurb: "Nautilus, Thunar, GTK dialogs",
            icon: "apps"
        },
        {
            id: "discord",
            label: "Discord",
            blurb: "Equibop / Vesktop, via Vencord's custom CSS",
            icon: "forum"
        }
    ]

    function targets(): var {
        return Settings.fonts.targets.split(",").map(s => s.trim()).filter(s => s.length);
    }

    function hasTarget(id: string): bool {
        return root.targets().indexOf(id) >= 0;
    }

    function setTarget(id: string, on: bool): void {
        const t = root.targets().filter(x => x !== id);
        if (on)
            t.push(id);
        Settings.fonts.targets = t.join(",");
        Settings.save();
    }

    function applyNow(): void {
        Fonts.apply(Settings.fonts.sans, Settings.fonts.mono, Settings.fonts.display, Settings.fonts.size, Settings.fonts.force, Settings.fonts.targets);
    }

    title: "Typography"
    icon: "text_fields"

    Connections {
        target: Fonts

        function onFinished(ok: bool, message: string): void {
            EditorState.status(ok ? "Fonts applied" : `Font change failed: ${message}`);
        }
    }

    Flickable {
        anchors.fill: parent
        anchors.leftMargin: 14
        anchors.rightMargin: 14
        anchors.topMargin: 6
        anchors.bottomMargin: 12
        contentHeight: col.implicitHeight
        clip: true
        boundsBehavior: Flickable.StopAtBounds

        Column {
            id: col

            width: parent.width
            spacing: 6

            // --- preview ----------------------------------------------------
            Rectangle {
                width: parent.width
                height: preview.implicitHeight + 28
                radius: 16
                color: Theme.alpha(Theme.fgSurface, 0.05)

                Column {
                    id: preview

                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.margins: 14
                    spacing: 2

                    Txt {
                        text: "09:24"
                        display: true
                        font.pixelSize: 34
                        font.weight: Font.Bold
                        axisWidth: 45
                        color: Theme.fgSurface
                    }

                    Txt {
                        text: "Saturday, 12 September"
                        font.pixelSize: 13
                        color: Theme.fgSurfaceVariant
                    }

                    Txt {
                        text: "CPU 7%  ·  47.2 W  ·  3300 rpm"
                        mono: true
                        font.pixelSize: 12
                        color: Theme.primary
                    }
                }
            }

            // --- families ---------------------------------------------------
            Section {
                title: "Families"
                icon: "font_download"

                Row2 {
                    label: "Interface"
                    labelWidth: 0.34

                    FontPick {
                        width: parent.width
                        value: Settings.fonts.sans
                        placeholder: `Default (${Theme.bundledSans})`
                        onPicked: f => {
                            Settings.fonts.sans = f;
                            Settings.save();
                        }
                    }
                }

                Row2 {
                    label: "Display"
                    labelWidth: 0.34

                    FontPick {
                        width: parent.width
                        value: Settings.fonts.display
                        placeholder: "Same as interface"
                        onPicked: f => {
                            Settings.fonts.display = f;
                            Settings.save();
                        }
                    }
                }

                Row2 {
                    label: "Monospace"
                    labelWidth: 0.34

                    FontPick {
                        width: parent.width
                        monoOnly: true
                        value: Settings.fonts.mono
                        placeholder: "Default (JetBrainsMono)"
                        onPicked: f => {
                            Settings.fonts.mono = f;
                            Settings.save();
                        }
                    }
                }

                Row2 {
                    label: "App font size"
                    labelWidth: 0.42

                    Sld {
                        width: parent.width
                        from: 7
                        to: 18
                        step: 1
                        value: Settings.fonts.size
                        onMoved: v => {
                            Settings.fonts.size = v;
                            Settings.save();
                        }
                    }
                }

                Row {
                    width: parent.width
                    spacing: 8

                    Btn {
                        icon: "restart_alt"
                        label: "Clear choices"
                        iconSize: 14
                        padding: 9
                        radius: 10
                        colour: Theme.fgSurfaceVariant
                        hoverColour: Theme.primary
                        background: Theme.alpha(Theme.fgSurface, 0.06)
                        onClicked: {
                            Settings.fonts.sans = "";
                            Settings.fonts.display = "";
                            Settings.fonts.mono = "";
                            Settings.save();
                        }
                    }
                }
            }

            // --- where ------------------------------------------------------
            Section {
                title: "Apply to"
                icon: "share"

                Repeater {
                    model: root.targetList

                    Item {
                        id: targetRow

                        required property var modelData

                        width: parent.width
                        height: 44

                        Icon {
                            id: targetIcon

                            anchors.left: parent.left
                            anchors.verticalCenter: parent.verticalCenter
                            text: targetRow.modelData.icon
                            size: 17
                            color: root.hasTarget(targetRow.modelData.id) ? Theme.primary : Theme.fgSurfaceVariant
                        }

                        Column {
                            anchors.left: targetIcon.right
                            anchors.leftMargin: 10
                            anchors.right: targetSwitch.left
                            anchors.rightMargin: 8
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 0

                            Txt {
                                width: parent.width
                                text: targetRow.modelData.label
                                font.pixelSize: 12
                                font.weight: Font.Medium
                                color: Theme.fgSurface
                            }

                            Txt {
                                width: parent.width
                                text: targetRow.modelData.blurb
                                font.pixelSize: 10
                                color: Theme.fgSurfaceVariant
                                elide: Text.ElideRight
                            }
                        }

                        Sw {
                            id: targetSwitch

                            anchors.right: parent.right
                            anchors.verticalCenter: parent.verticalCenter
                            checked: root.hasTarget(targetRow.modelData.id)
                            onToggled: v => root.setTarget(targetRow.modelData.id, v)
                        }
                    }
                }
            }

            // --- force ------------------------------------------------------
            Section {
                title: "Force"
                icon: "priority_high"

                Row2 {
                    label: "Override every app's own font"
                    stacked: true

                    Sw {
                        width: parent.width
                        checked: Settings.fonts.force
                        onToggled: v => {
                            Settings.fonts.force = v;
                            Settings.save();
                        }
                    }
                }

                Txt {
                    width: parent.width
                    text: Settings.fonts.force ? "Apps that explicitly ask for a family get yours instead. Icon and Nerd fonts are excluded automatically, as are Wine and Proton processes - games ship their own UI fonts and look wrong without them." : "Off: apps that ask for a specific font keep it. Only the generic sans / serif / monospace defaults change."
                    font.pixelSize: 11
                    color: Settings.fonts.force ? Theme.error : Theme.fgSurfaceVariant
                    wrapMode: Text.Wrap
                }

                Txt {
                    width: parent.width
                    visible: Settings.fonts.force && !root.hasTarget("fontconfig")
                    text: "Force needs the “System default” target switched on."
                    font.pixelSize: 11
                    color: Theme.error
                    wrapMode: Text.Wrap
                }
            }

            Rectangle {
                width: parent.width
                height: 1
                color: Theme.alpha(Theme.outlineVariant, 0.5)
            }

            // --- actions ----------------------------------------------------
            Row {
                width: parent.width
                spacing: 8
                topPadding: 4

                Btn {
                    icon: Fonts.busy ? "hourglass" : "check"
                    label: "Apply"
                    iconSize: 15
                    padding: 12
                    radius: 12
                    enabled: !Fonts.busy
                    colour: Theme.primary
                    hoverColour: Theme.primary
                    background: Theme.alpha(Theme.primary, 0.16)
                    onClicked: root.applyNow()
                }

                Btn {
                    icon: "settings_backup_restore"
                    label: "Revert all"
                    iconSize: 15
                    padding: 12
                    radius: 12
                    enabled: !Fonts.busy
                    colour: Theme.error
                    hoverColour: Theme.error
                    background: Theme.alpha(Theme.error, 0.1)
                    onClicked: Fonts.revert()
                }
            }

            Txt {
                width: parent.width
                text: {
                    if (Fonts.busy)
                        return Fonts.lastMessage;
                    if (Fonts.isApplied)
                        return `Applied: ${Fonts.applied.sans || "default"}${Fonts.applied.force ? " · forced" : ""} → ${(Fonts.applied.targets ?? []).join(", ")}`;
                    return "Nothing applied outside Forge yet.";
                }
                font.pixelSize: 11
                color: Fonts.isApplied ? Theme.primary : Theme.fgSurfaceVariant
                wrapMode: Text.Wrap
            }

            Txt {
                width: parent.width
                text: "Running apps pick up a font change when they restart. The shell and Forge apply it live."
                font.pixelSize: 10
                color: Theme.alpha(Theme.fgSurfaceVariant, 0.8)
                wrapMode: Text.Wrap
            }

            Item {
                width: parent.width
                height: 10
            }
        }
    }
}
