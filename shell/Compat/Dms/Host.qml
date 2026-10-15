import QtQuick
import qs.Compat.Dms.Services

// Hands Flamenco DMS's plugin service, without Flamenco importing the
// compatibility modules (they import Flamenco's).
QtObject {
    readonly property var pluginService: PluginService
}
