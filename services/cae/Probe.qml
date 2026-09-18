import QtQuick
import Caelestia.Services

// Nothing but the imports. Creating this component is the test for whether
// caelestia-shell's QML plugins are installed: a missing import is a hard
// compile error, so the component comes back with status Error rather than
// throwing anywhere that could take the rest of the config down with it.
QtObject {
    readonly property bool ok: true
}
