import QtQuick
import qs.Commons

Rectangle {
    radius: Theme.rLg
    color: Theme.cardSurface

    Finish { strength: 0.4 }

    Behavior on color { CAnim {} }
}
