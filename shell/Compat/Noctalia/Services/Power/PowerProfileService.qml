pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Services.UPower

// Flamenco shim for Noctalia's PowerProfileService.
Singleton {
    id: root

    readonly property bool noctaliaPerformanceMode: false
    readonly property bool available: PowerProfiles.profile !== undefined
    readonly property int profile: PowerProfiles.profile

    function getName(p) {
        const prof = p !== undefined ? p : profile;
        return prof === PowerProfile.Performance ? "Performance" : prof === PowerProfile.PowerSaver ? "Power saver" : "Balanced";
    }
    function getIcon(p) {
        const prof = p !== undefined ? p : profile;
        return prof === PowerProfile.Performance ? "performance" : prof === PowerProfile.PowerSaver ? "powersaver" : "balanced";
    }
    function setProfile(p) {
        PowerProfiles.profile = p;
    }
    function cycleProfile() {
        setProfile(profile === PowerProfile.PowerSaver ? PowerProfile.Balanced : profile === PowerProfile.Balanced ? PowerProfile.Performance : PowerProfile.PowerSaver);
    }
}
