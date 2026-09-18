import QtQuick
import Caelestia.Services
import qs.config

// The cava audio provider. There is no fallback for this one: it is a FFT of
// the monitor stream done in caelestia's C++, and the widgets that use it say
// so rather than pretending to react to silence.
Item {
    id: root

    readonly property var values: cava.values ?? []
    readonly property real level: cava.level ?? 0

    property int bars: 32

    CavaProvider {
        id: cava

        // `parent` is undefined here - CavaProvider is not a visual child -
        // so the binding has to name the root explicitly.
        bars: root.bars
    }

    ServiceRef {
        service: Demand.needed("cava") ? cava : null
    }
}
