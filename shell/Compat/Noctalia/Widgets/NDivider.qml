// Vendored from https://github.com/noctalia-dev/noctalia-shell (branch legacy-v4) (MIT) by tools/compat-vendor.py.
// Don't edit: change the vendoring tool or a Flamenco shim next to it.
import QtQuick
import Quickshell
import Quickshell.Widgets
import qs.Compat.Noctalia.Commons

Rectangle {
  property bool vertical: false

  width: vertical ? Style.borderS : parent.width
  height: vertical ? parent.height : Style.borderS
  gradient: Gradient {
    orientation: vertical ? Gradient.Vertical : Gradient.Horizontal
    GradientStop {
      position: 0.0
      color: "transparent"
    }
    GradientStop {
      position: 0.1
      color: Color.mOutline
    }
    GradientStop {
      position: 0.9
      color: Color.mOutline
    }
    GradientStop {
      position: 1.0
      color: "transparent"
    }
  }
}
