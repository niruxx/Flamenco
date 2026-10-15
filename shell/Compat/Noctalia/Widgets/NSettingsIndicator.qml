// Vendored from https://github.com/noctalia-dev/noctalia-shell (branch legacy-v4) (MIT) by tools/compat-vendor.py.
// Don't edit: change the vendoring tool or a Flamenco shim next to it.
import QtQuick
import QtQuick.Layouts
import qs.Compat.Noctalia.Commons
import qs.Compat.Noctalia.Services.UI

Rectangle {
  id: root

  property bool show: false
  property var tooltipText

  implicitWidth: root.show ? 6 * Style.uiScaleRatio : 0
  implicitHeight: root.show ? 6 * Style.uiScaleRatio : 0
  width: root.show ? 6 * Style.uiScaleRatio : 0
  height: root.show ? 6 * Style.uiScaleRatio : 0
  radius: width / 2
  color: Color.mOnSurfaceVariant
  opacity: 0.6

  visible: root.show

  Behavior on opacity {
    NumberAnimation {
      duration: Style.animationFast
    }
  }

  MouseArea {
    enabled: root.show && root.tooltipText && (!Array.isArray(root.tooltipText) || root.tooltipText.length > 0)
    anchors.fill: parent
    hoverEnabled: true
    acceptedButtons: Qt.NoButton
    cursorShape: Qt.PointingHandCursor

    onEntered: {
      if (root.tooltipText && (!Array.isArray(root.tooltipText) || root.tooltipText.length > 0)) {
        TooltipService.show(root, root.tooltipText);
      }
    }

    onExited: {
      if (root.tooltipText && (!Array.isArray(root.tooltipText) || root.tooltipText.length > 0)) {
        TooltipService.hide();
      }
    }
  }
}
