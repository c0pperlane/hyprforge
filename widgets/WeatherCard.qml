import QtQuick
import qs.components
import qs.config
import qs.services

// Current conditions, an optional detail line, and an hourly strip.
//
// The location is looked up per widget through WeatherSvc, so two of these can
// show two different cities. Blank means "here", resolved by IP geolocation.
WidgetBase {
    id: root

    needs: ["weather"]

    readonly property bool imperial: root.str("units", "metric") === "imperial"
    readonly property string place: root.str("location", "")
    readonly property var w: WeatherSvc.get(root.place)

    onPlaceChanged: WeatherSvc.ensure(root.place)
    Component.onCompleted: WeatherSvc.ensure(root.place)


    readonly property var desc: WeatherSvc.describe(root.w.code, root.w.isDay)
    readonly property bool ready: !isNaN(root.w.temperature)

    readonly property string placeText: {
        if (root.w.name)
            return root.w.name;
        if (root.w.loading || WeatherSvc.locating)
            return "locating…";
        return root.w.error || "—";
    }

    Item {
        id: current

        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        height: root.num("tempSize", 46) * 1.5

        Icon {
            id: condIcon

            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            text: root.desc.icon
            size: root.num("tempSize", 46) * 1.1
            fill: 0.4
            color: root.accent
        }

        Txt {
            anchors.left: condIcon.right
            anchors.leftMargin: 12
            anchors.verticalCenter: parent.verticalCenter
            text: root.ready ? WeatherSvc.temp(root.w.temperature, root.imperial) : "—"
            font.pixelSize: root.num("tempSize", 46)
            font.weight: Font.DemiBold
            axisWidth: 75
            color: root.fg
        }

        Column {
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            spacing: 1

            Txt {
                anchors.right: parent.right
                text: root.desc.label
                font.pixelSize: 13
                font.weight: Font.Medium
                color: root.fg
            }

            Row {
                anchors.right: parent.right
                spacing: 4
                visible: root.flag("showPlace", true)

                Icon {
                    anchors.verticalCenter: parent.verticalCenter
                    visible: !root.str("location", "")
                    text: WeatherSvc.located ? "my_location" : "location_searching"
                    size: 12
                    color: root.muted
                }

                Txt {
                    anchors.verticalCenter: parent.verticalCenter
                    text: root.placeText
                    font.pixelSize: 11
                    color: root.w.error ? Theme.error : root.muted
                }
            }

            Txt {
                anchors.right: parent.right
                visible: root.ready
                text: `H ${WeatherSvc.temp(root.w.high, root.imperial)}   L ${WeatherSvc.temp(root.w.low, root.imperial)}`
                font.family: Theme.mono
                font.pixelSize: 11
                color: root.muted
            }
        }
    }

    Row {
        id: details

        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: current.bottom
        anchors.topMargin: 4
        height: visible ? 18 : 0
        visible: root.flag("details", false) && root.ready
        spacing: 14

        Detail {
            icon: "thermostat"
            text: `feels ${WeatherSvc.temp(root.w.apparent, root.imperial)}`
        }

        Detail {
            icon: "air"
            text: WeatherSvc.speed(root.w.wind, root.imperial)
        }

        Detail {
            icon: "humidity_percentage"
            text: `${root.w.humidity}%`
        }

        Detail {
            icon: "umbrella"
            text: `${root.w.precipChance}%`
        }
    }

    Rectangle {
        id: rule

        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: details.bottom
        anchors.topMargin: 8
        height: 1
        color: Theme.alpha(root.fg, 0.1)
        visible: root.flag("hourly", true)
    }

    Row {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: rule.bottom
        anchors.topMargin: 10
        anchors.bottom: parent.bottom
        visible: root.flag("hourly", true)

        Repeater {
            model: root.w.hourly.slice(0, Math.round(root.num("hours", 5)))

            Column {
                required property var modelData

                width: root.width / Math.max(1, Math.round(root.num("hours", 5))) - root.pad / 2
                spacing: 3

                Txt {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: `${modelData.hour}:00`
                    font.family: Theme.mono
                    font.pixelSize: 10
                    color: root.muted
                }

                Icon {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: WeatherSvc.describe(modelData.code, modelData.day).icon
                    size: 19
                    color: root.accent
                }

                Txt {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: WeatherSvc.temp(modelData.temp, root.imperial)
                    font.pixelSize: 12
                    font.weight: Font.Medium
                    color: root.fg
                }
            }
        }
    }

    component Detail: Row {
        property string icon: ""
        property string text: ""

        spacing: 3

        Icon {
            anchors.verticalCenter: parent.verticalCenter
            text: parent.icon
            size: 13
            color: root.muted
        }

        Txt {
            anchors.verticalCenter: parent.verticalCenter
            text: parent.text
            font.pixelSize: 11
            color: root.muted
        }
    }
}
