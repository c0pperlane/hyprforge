pragma ComponentBehavior: Bound

import QtQuick
import qs.components
import qs.config
import qs.services

// Editor for one widget's visibility conditions.
//
// A widget with no rules is always on the desktop, which is what every layout
// written before conditions existed has, so the empty state is the default and
// says so rather than looking broken.
Column {
    id: root

    property string wid: ""

    readonly property var instance: root.wid ? Store.get(root.wid) : null
    readonly property var cond: Store.parseCond(root.instance?.cond)
    readonly property var rules: root.cond.rules ?? []

    // Prefixed with the group rather than split under headers: the dropdown
    // renders a flat list, and a heading in it would be selectable.
    // Conditions already applied are dropped - adding one twice is either a
    // no-op or a contradiction, and neither is worth offering.
    readonly property var addOptions: {
        const used = root.rules.map(r => r.key);
        const out = [
            {
                value: "",
                label: "Add a condition…"
            }
        ];
        for (const c of Cond.catalog)
            if (used.indexOf(c.key) < 0)
                out.push({
                    value: c.key,
                    label: `${c.group} · ${c.label}`
                });
        return out;
    }

    function mutate(fn: var): void {
        const next = {
            mode: root.cond.mode,
            rules: root.rules.map(r => ({
                        key: r.key,
                        not: !!r.not,
                        value: r.value
                    }))
        };
        fn(next);
        Store.setCond(root.wid, next, true);
    }

    function addRule(key: string): void {
        if (!key)
            return;
        root.mutate(next => next.rules.push({
                    key: key,
                    not: false,
                    value: Cond.def(key)?.value?.def
                }));
    }

    spacing: 8
    width: parent ? parent.width : 260

    Row2 {
        label: "Match"
        hint: "How several conditions combine"
        visible: root.rules.length > 1
        height: visible ? implicitHeight : 0

        Sel {
            width: parent.width
            options: [
                {
                    value: "all",
                    label: "All"
                },
                {
                    value: "any",
                    label: "Any"
                }
            ]
            value: root.cond.mode
            onPicked: v => root.mutate(next => next.mode = v)
        }
    }

    Repeater {
        model: root.rules.length

        Rectangle {
            required property int index

            readonly property var rule: root.rules[index] ?? ({
                    key: ""
                })
            readonly property var meta: Cond.def(rule.key)
            readonly property bool hasValue: !!meta?.value

            width: root.width
            height: 36
            radius: 11
            color: Theme.alpha(Theme.fgSurface, 0.06)

            Icon {
                id: ruleIcon

                anchors.left: parent.left
                anchors.leftMargin: 10
                anchors.verticalCenter: parent.verticalCenter
                text: parent.rule.not ? "block" : (parent.meta?.icon ?? "help")
                size: 16
                color: parent.rule.not ? Theme.error : Theme.primary
            }

            Txt {
                id: ruleLabel

                anchors.left: ruleIcon.right
                anchors.leftMargin: 8
                anchors.verticalCenter: parent.verticalCenter
                width: Math.max(0, valueFld.x - x - 6)
                // The unknown-key case is reachable: a layout from a newer
                // build can name a rule this one has never heard of. It stays
                // listed so it can be removed, rather than silently dropped.
                text: parent.meta ? (parent.rule.not ? `Not ${parent.meta.label.charAt(0).toLowerCase()}${parent.meta.label.slice(1)}` : parent.meta.label) : `Unknown: ${parent.rule.key}`
                font.pixelSize: 12
                color: parent.meta ? Theme.fgSurface : Theme.error
                elide: Text.ElideRight
            }

            Fld {
                id: valueFld

                anchors.right: notBtn.left
                anchors.rightMargin: 4
                anchors.verticalCenter: parent.verticalCenter
                width: parent.hasValue ? 58 : 0
                visible: parent.hasValue
                mono: true
                value: parent.hasValue ? `${Cond.valueOf(parent.rule)}` : ""
                onCommitted: text => {
                    const i = parent.index;
                    const spec = parent.meta.value;
                    let v = text;
                    if (spec.type === "int") {
                        v = parseInt(text);
                        if (!Number.isFinite(v))
                            return valueFld.setText(`${Cond.valueOf(parent.rule)}`);
                        v = Math.max(spec.min, Math.min(spec.max, v));
                    } else if (spec.type === "time" && Cond.minutesOf(text) < 0) {
                        // Rejecting it outright beats storing "25:99" and
                        // leaving the widget hidden for reasons nothing shows.
                        return valueFld.setText(`${Cond.valueOf(parent.rule)}`);
                    }
                    root.mutate(next => next.rules[i].value = v);
                }
            }

            Btn {
                id: notBtn

                anchors.right: delBtn.left
                anchors.verticalCenter: parent.verticalCenter
                icon: "block"
                iconSize: 15
                padding: 6
                checked: parent.rule.not
                colour: Theme.fgSurfaceVariant
                hoverColour: Theme.error
                onClicked: {
                    const i = parent.index;
                    root.mutate(next => next.rules[i].not = !next.rules[i].not);
                }
            }

            Btn {
                id: delBtn

                anchors.right: parent.right
                anchors.rightMargin: 4
                anchors.verticalCenter: parent.verticalCenter
                icon: "close"
                iconSize: 15
                padding: 6
                colour: Theme.fgSurfaceVariant
                hoverColour: Theme.error
                onClicked: {
                    const i = parent.index;
                    root.mutate(next => next.rules.splice(i, 1));
                }
            }
        }
    }

    Sel {
        id: adder

        width: parent.width
        forceMenu: true
        options: root.addOptions
        value: ""
        onPicked: v => root.addRule(v)
    }

    Txt {
        width: parent.width
        visible: root.rules.length === 0
        text: "No conditions: always on the desktop."
        font.pixelSize: 11
        color: Theme.fgSurfaceVariant
        wrapMode: Text.Wrap
    }

    Txt {
        width: parent.width
        visible: root.rules.length > 0
        text: {
            const needs = Cond.demands(root.cond);
            if (!needs.length)
                return "Unmet conditions un-build the widget, so it costs nothing while it waits.";
            // Being explicit about it: this is the one case where a widget you
            // cannot see is still paying for something.
            return `Waiting costs nothing, except ${needs.join(", ")} — that has to keep running for the condition to be answerable.`;
        }
        font.pixelSize: 11
        color: Theme.fgSurfaceVariant
        wrapMode: Text.Wrap
    }
}
