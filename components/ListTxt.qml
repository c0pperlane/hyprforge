import QtQuick
import qs.config

// Text for view delegates: the same typography as Txt, with no Behaviors and
// no layer effect.
//
// A Behavior installs a property interceptor on its target. In a view whose
// model is replaced wholesale - the lyric list on every track change, the
// process list every few seconds - delegates are destroyed while those
// animations may still be running, and the write that follows lands in
// QQmlInterceptorMetaObject::doIntercept on an object that is going away.
//
// That was a real, reproducible crash: rapid track changes killed the daemon in
// roughly 40% of runs, always with the same stack, always inside doIntercept.
// So delegates of churning views deliberately carry no interceptors at all. Use
// Txt for anything whose lifetime is stable; use this inside a Repeater or
// ListView over a recomputed model.
Text {
    id: root

    property real axisWidth: 100
    property bool mono: false

    antialiasing: true
    font.family: root.mono ? Theme.mono : Theme.sans
    font.pixelSize: 15
    font.weight: Font.Medium
    font.variableAxes: root.mono || !Theme.sansIsVariable ? ({}) : ({
            wdth: root.axisWidth,
            ROND: 100
        })
    color: Theme.fgSurface
    renderType: Settings.appearance.textRendering === "crisp" ? Text.NativeRendering : Text.QtRendering
    textFormat: Text.PlainText
    elide: Text.ElideRight
}
