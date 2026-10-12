import QtQuick
import qs.Commons

// Row in a horizontal bar, column in a vertical one. Children are centred on
// the cross axis, so they don't need their own anchors.
Grid {
    columns: Theme.barVertical ? 1 : 64
    spacing: Theme.barVertical ? 2 : 6
    horizontalItemAlignment: Grid.AlignHCenter
    verticalItemAlignment: Grid.AlignVCenter
}
