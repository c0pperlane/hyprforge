import QtQuick
import QtQuick.Shapes
import qs.components
import qs.config
import qs.services

// Daylight as an arc: sunrise on the left, sunset on the right, with a marker
// showing where in the day you currently are.
//
// Sunrise and sunset come from the same forecast the Weather element already
// fetches, so this costs one extra field on a request that was happening anyway.
WidgetBase {
    id: root

    needs: ["weather"]

    readonly property string place: root.str("location", "")
    readonly property var w: WeatherSvc.get(root.place)

    onPlaceChanged: WeatherSvc.ensure(root.place)
    Component.onCompleted: WeatherSvc.ensure(root.place)

    function minutesOf(iso: string): real {
        // open-meteo returns local time as "YYYY-MM-DDTHH:MM"; the clock part
        // is all that matters here, and parsing it directly avoids any
        // timezone re-interpretation by Date.
        const m = /T(\d{2}):(\d{2})/.exec(iso ?? "");
        return m ? parseInt(m[1]) * 60 + parseInt(m[2]) : NaN;
    }

    readonly property real sunriseMin: root.minutesOf(root.w.sunrise)
    readonly property real sunsetMin: root.minutesOf(root.w.sunset)
    readonly property bool valid: !isNaN(root.sunriseMin) && !isNaN(root.sunsetMin) && root.sunsetMin > root.sunriseMin

    readonly property real nowMin: Clock.hours * 60 + Clock.minutes
    readonly property real progress: root.valid ? Math.max(0, Math.min(1, (root.nowMin - root.sunriseMin) / (root.sunsetMin - root.sunriseMin))) : 0
    readonly property bool daytime: root.valid && root.nowMin >= root.sunriseMin && root.nowMin <= root.sunsetMin

    function clock(min: real): string {
        if (isNaN(min))
            return "—";
        const h = Math.floor(min / 60);
        const m = Math.round(min % 60);
        return `${h < 10 ? "0" : ""}${h}:${m < 10 ? "0" : ""}${m}`;
    }

    Item {
        id: arc

        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.bottom: labels.top
        anchors.bottomMargin: 4

        readonly property real r: Math.min(width / 2, height)
        readonly property real cx: width / 2
        readonly property real cy: height

        Shape {
            anchors.fill: parent
            preferredRendererType: Shape.CurveRenderer

            // Full arc, dimmed: the day that is available.
            ShapePath {
                strokeColor: Theme.alpha(root.fg, 0.16)
                strokeWidth: root.num("thickness", 4)
                fillColor: "transparent"
                capStyle: ShapePath.RoundCap

                PathAngleArc {
                    centerX: arc.cx
                    centerY: arc.cy
                    radiusX: arc.r
                    radiusY: arc.r
                    startAngle: 180
                    sweepAngle: 180
                }
            }

            // Elapsed daylight.
            ShapePath {
                strokeColor: root.accent
                strokeWidth: root.num("thickness", 4)
                fillColor: "transparent"
                capStyle: ShapePath.RoundCap

                PathAngleArc {
                    centerX: arc.cx
                    centerY: arc.cy
                    radiusX: arc.r
                    radiusY: arc.r
                    startAngle: 180
                    sweepAngle: Math.max(0.5, 180 * root.progress)
                }
            }
        }

        // Sun marker.
        Rectangle {
            readonly property real angle: Math.PI * (1 + root.progress)

            visible: root.valid
            width: root.num("thickness", 4) * 2.6
            height: width
            radius: width / 2
            color: root.daytime ? root.colour("sunColour", Theme.primary) : root.muted
            x: arc.cx + Math.cos(angle) * arc.r - width / 2
            y: arc.cy + Math.sin(angle) * arc.r - height / 2

            Behavior on x {
                NumberAnimation {
                    duration: 600
                    easing.type: Easing.OutCubic
                }
            }

            Behavior on y {
                NumberAnimation {
                    duration: 600
                    easing.type: Easing.OutCubic
                }
            }
        }
    }

    Item {
        id: labels

        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        height: root.num("size", 12) * 2.2

        Column {
            anchors.left: parent.left
            spacing: 0

            Txt {
                text: root.clock(root.sunriseMin)
                font.family: Theme.mono
                font.pixelSize: root.num("size", 12)
                color: root.fg
            }

            Txt {
                text: "sunrise"
                font.pixelSize: root.num("size", 12) * 0.78
                color: root.muted
            }
        }

        Txt {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.verticalCenter: parent.verticalCenter
            visible: root.flag("showDaylight", true) && root.valid
            text: `${Math.floor((root.sunsetMin - root.sunriseMin) / 60)}h ${Math.round((root.sunsetMin - root.sunriseMin) % 60)}m`
            font.pixelSize: root.num("size", 12)
            font.weight: Font.Medium
            color: root.muted
        }

        Column {
            anchors.right: parent.right
            spacing: 0

            Txt {
                anchors.right: parent.right
                text: root.clock(root.sunsetMin)
                font.family: Theme.mono
                font.pixelSize: root.num("size", 12)
                color: root.fg
            }

            Txt {
                anchors.right: parent.right
                text: "sunset"
                font.pixelSize: root.num("size", 12) * 0.78
                color: root.muted
            }
        }
    }
}
