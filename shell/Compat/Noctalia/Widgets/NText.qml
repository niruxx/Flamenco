// Vendored from https://github.com/noctalia-dev/noctalia-shell (branch legacy-v4) (MIT) by tools/compat-vendor.py.
// Don't edit: change the vendoring tool or a Flamenco shim next to it.
import QtQuick
import QtQuick.Layouts
import qs.Compat.Noctalia.Commons
import qs.Compat.Noctalia.Widgets

Text {
  id: root

  property bool richTextEnabled: false
  property bool markdownTextEnabled: false
  property string family: Settings.data.ui.fontDefault
  property real pointSize: Style.fontSizeM
  property bool applyUiScale: true
  property real fontScale: {
    const fontScale = (root.family === Settings.data.ui.fontDefault ? Settings.data.ui.fontDefaultScale : Settings.data.ui.fontFixedScale);
    if (applyUiScale) {
      return fontScale * Style.uiScaleRatio;
    }
    return fontScale;
  }
  property var features: ({})

  opacity: enabled ? 1.0 : 0.6
  font.family: root.family
  font.weight: Style.fontWeightMedium
  font.pointSize: Math.max(1, root.pointSize * fontScale)
  font.features: root.features
  color: Color.mOnSurface
  elide: Text.ElideRight
  wrapMode: Text.NoWrap
  verticalAlignment: Text.AlignVCenter

  textFormat: {
    if (root.richTextEnabled) {
      return Text.RichText;
    } else if (root.markdownTextEnabled) {
      return Text.MarkdownText;
    }
    return Text.PlainText;
  }
}
