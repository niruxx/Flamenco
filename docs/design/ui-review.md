# UI design review

The design direction is Material 3 Expressive: rounded tonal surfaces, clear type hierarchy, a restrained primary accent, and shape changes that explain interaction. Content columns should be centered; labels and settings rows remain start-aligned for scanning.

## Changes implemented

- Settings pages center their bounded content column within the panel, reserving room for the scrollbar. The width limit, insets, and vertical rhythm follow UI scale. Long titles wrap.
- Shared buttons use a consistent 40-unit height; fields and dropdowns use 44. Existing explicit size overrides remain supported.
- Tonal buttons, segmented selection, and settings navigation share an accent-container role so primary actions retain visual emphasis.
- Dashboard and quick-settings tiles use larger labels, supporting text, and scale-aware padding and height. Inactive tiles use the shared surface role rather than separate translucent outlines.
- Tiles morph on press; dashboard overflow actions remain visible for discoverability.
- Active tile and icon-button foregrounds are selected against their actual fill, including secondary accents and custom tints. Custom primary accents use the same contrast calculation.

## Review coverage and remaining validation

Reviewed the shared theme and controls, settings page/navigation layout, and source layout constraints in the launcher, control center, dashboard, and notification center. Existing screenshots of Settings, launcher, dashboard, and control center informed the visual review; they predate these changes.

The repository static QML checker passes. This environment has no Quickshell runtime or Qt lint tools, so the updated UI has not been rendered. A live visual pass is still required before calling the entire shell visually verified.

In a live session, check:

- Dark and light palettes plus wallpaper/custom accents: tonal selection visibility and text contrast.
- Settings at narrow and wide window sizes: balanced gutters, wrapped titles, scrollbar clearance, and controls beside long descriptions.
- UI scales 1, 1.25, and 1.5: tile labels, field text, multi-column control-center layouts, and vertical scrolling.
- Launcher, notifications, calendar, lock screen, dock, and power menu: alignment, focus visibility, panel clipping, and consistency with the shared controls.

## Extended consistency and interaction pass

- Added a shared inset keyboard focus ring, Tab focus, activation keys, and accessibility roles/actions to buttons, icon buttons, switches, action tiles, and quick-settings grid pills. Switch rows supply their setting title as the accessible label.
- Segmented controls support arrows, Home/End, activation, and empty selections. Constrained labels elide. The compact dashboard now uses this shared component; the hub rail uses the same tonal selection surface and supports keyboard activation.
- Dropdowns support keyboard opening, list navigation, filtering, selection, and visible keyboard highlighting. Empty results have reserved space. Text inputs participate in Tab navigation.
- Both shared volume/brightness slider styles support arrow adjustments and Home/End, with accessibility increase/decrease actions. Zero-length ranges avoid division by zero.
- Quick settings, launcher, clipboard, and compact dashboard width defaults follow UI scale. Quick-settings cards limit their column count to available room; the editable grid collapses to one column while retaining saved half/full-width preferences.
- Centered overlays now center vertically. Overlay content reserves scrollbar space.
- The power menu wraps actions into a grid and scrolls on short screens. Up/Down traverse grid rows; Shift+Tab reverses selection. Keyboard selection scrolls into view. Countdown labels have a stable backing over the animated progress fill.
- Notification headings wrap/elide as appropriate. Narrow media cards hide album art to preserve room for text and transport controls.
- Settings rows scale their corners, padding, and stacking threshold with text size.

### Verification completed

- Static QML validation: **574 files, zero problems**.
- Whitespace/error checks: `git diff --check` passes.
- Evaluated the actual theme contrast/foreground functions against all **36 built-in dark/light palette variants** and **216 active fill pairs**. Tonal-container text has a minimum **5.27:1** contrast; automatic active-fill foregrounds have a minimum **4.62:1**. This covers those specific pairs, not every label or translucent/composited surface. User-defined and wallpaper palettes were not enumerated.
- Exercised the actual editable-grid placement calculation across **3,072 cases**: widths 240–800, scales 1/1.25/1.5/2, and mixed half/full-width configurations. Every tile remained within horizontal bounds with no overlapping slots.
- Checked runtime availability again: no Quickshell, Qt QML tools, or PySide6 were available. No updated screenshots or runtime accessibility results are claimed.

### Remaining live checks

The live-session checklist above remains necessary, especially keyboard focus scrolling inside settings, dropdown popup placement, translated/long labels, dashboard hub pages at narrow widths, and lock/dock layouts. Some module-specific fixed dimensions and custom mouse interactions remain. This pass improves shared behavior and several major panels; it does not establish complete accessibility or Material specification conformance.


## Motion consistency pass

Shared `Anim` and `CAnim` now use named motion roles from `Theme.motionTiming`, with global speed/style and per-area overrides applied once. Default timings at speed 1:

| Role | Duration | Use |
| --- | ---: | --- |
| Feedback | 120 ms | Press/hover response |
| Color | 180 ms | Surface and foreground changes |
| Fade | 150 ms | Short content reveals |
| Shape | 200 ms | Control shape changes |
| Move | 240 ms | Selection, layout, and page movement |
| Enter | 320 ms | Surface reveal, decelerating |
| Exit | 180 ms | Surface dismissal, accelerating |

Panels, dropdowns, notifications, overview, switcher, OSD, bar/dock reveals, power, lock, wallpaper carousel, and settings/dashboard page changes use these roles. Springs on shared controls have gentler overshoot; opacity and surface progress use bounded easing. Notification entry uses a short offset and subtle scale rather than a long bounce. Notification windows linger for their configured exit duration, including slower per-area settings.

Control-center page fades and offsets share one animated progress value. Dashboard page fade and movement use the same duration. Outgoing panel/dashboard/control-center content cannot receive clicks while it disappears. Shared panel reveals honor the launcher's animation-area override.

Minimal motion uses fades for shared popouts and notification entrances, suppresses dashboard/detail-page offsets, removes shared tile/button press scaling, and disables ripples and selected decorative weather/media/battery/recording loops. Global speed zero removes shared transition durations. Playback progress interpolation remains linear and is disabled in minimal/off mode; actual playback clocks, notification lifetimes, and destructive-action hold/countdown durations retain their real-time semantics.

Validation: 574 QML files pass the static checker; `git diff --check` passes. Evaluated the actual motion helper functions in 1,344 role/style/speed/area combinations, including disabled and invalid area settings. All durations were finite nonnegative integers, disabled settings returned zero, exits did not exceed entrances, and minimal mode suppressed spatial motion. This validates configuration math, not rendered frame pacing. Live checks still need to cover rapid open/close reversal, repeated tab switching, slow per-area overrides, drag tracking, and minimal/off settings under Quickshell. Some module-specific decorative/status effects retain their own timings.


## Flamenco pill redesign and Effects settings

Apply **Settings → Appearance → Layout presets → Flamenco** to use the redesigned layout. Applying the preset sets its bar, palette, panel, and visualizer choices; existing saved layouts are not silently replaced.

The new Flamenco look combines floating bar islands, lavender on charcoal, tonal pill toggles with circular icon wells, large pill sliders, and centered quick-settings and calendar surfaces. Quick settings uses a focused two-column layout, a clearer heading, audio/brightness controls, and media. The compact calendar uses a centered clock/date hero, a roomier month grid, and shared pill navigation. Panel placement can be changed in Quick settings and Clock & Weather. Cards, Classic, editable Grid, and the wide calendar Hub remain available.

Bloom entrances combine subtle scaling, fading, and a short vertical reveal for centered surfaces. The Effects page consolidates the old Appearance motion section, keeping its persisted settings compatible. It exposes:

- Global animation speed, Expressive/Smooth/Snappy/Minimal styles, ripple, hover zoom, and scrolling.
- Base timing overrides for feedback, color, fade, shape, move, entrance, exit, and palette transitions, plus timing reset.
- Per-area speed, including independent quick-settings and calendar overrides that otherwise inherit Panels.
- Global and per-panel surface effects, including Bloom, Rise, Slide, Zoom, Fade, and None.
- Page transitions, motion distance, spring strength, ambient motion, and an inline replay preview.
- Shared audio visualizer controls, also available under Sound.

New shared visualizer styles are **Ribbon**, **Orbit**, and **Spark**, with **Neon** and **Ocean** color schemes. Controls include enable/disable, sensitivity, response speed, peak decay, effect intensity, and symmetric frequency sampling. Disabling visualizers also stops cava. Rendering has bounded per-band work, honors the configured drawing frame rate, sanitizes invalid samples, and settles at idle.

Validation for this pass: **575 QML files** pass static checks; Effects has **36 searchable settings entries**; the actual canvas renderer passes **270 geometry cases** across all nine styles, landscape/portrait/tiny sizes, and signal levels; actual frame/target functions pass **96 simulations of 240 frames** across response modes, sensitivities, symmetry, idle, and invalid samples. The checks caught and fixed a negative-radius edge case in the existing radial style. **288 custom-timing cases** validate overrides, fallback, disabled motion, independent area speed, and instant pages.

These source and math checks do not render the new design. A live Quickshell session is still required to review font metrics, panel composition, transitions, and GPU/frame performance. Functional playback, timeout, and destructive-action countdown clocks retain their real-time timing; decorative module-specific loops do not all use the base-duration sliders.


## Aero and Liquid Glass material redesign

Reapply **Appearance → Layout presets → Frutiger Aero** or **Liquid Glass** to load the revised palettes, panel layouts, transparency, and motion choices. Switching presets resets glass parameters unless the chosen preset specifies them.

Aero now uses luminous sky-and-water colors, green accents, broad lens reflections, translucent cards, a contoured bottom taskbar, an aquatic wave visualizer, and smooth Bloom entrances. Liquid Glass uses a cool pearl palette, finer layered rims, softened controls, a restrained menu bar, a floating magnifying dock, compact top-edge panels, and quieter crossfades. Both retain dark palette variants.

Shared material rendering now includes clipped specular gradients, opposing edge reflections, inner contours, and subtle material finishes on cards and controls. Settings panels also carry the material treatment. Appearance and Effects expose **Glass highlights** and **Frosted wallpaper** controls.

`GlassBackdrop.qml` provides a cropped and blurred wallpaper texture behind glass panels and the dock. It follows screen-specific wallpapers and fill mode; solid-color wallpapers skip image sampling. The source image decodes at reduced resolution, the crop texture matches the surface size, and loaders release the backing when the surface closes. This is a wallpaper-based frost effect, not a capture or blur of application windows. Compositor-provided blur is still requested by these presets where supported. See [Qt's ShaderEffectSource documentation](https://doc.qt.io/qt-6/qml-qtquick-shadereffectsource.html) for the cropped-texture approach.

Validation: **576 QML files** pass static checks and whitespace checks pass. The four revised palette variants have base text/surface contrast from **9.63:1 to 13.36:1**. Primary-button text at the modeled maximum vertical specular highlight remains **4.65:1 or higher** at default material strength. These measurements do not establish contrast over every wallpaper or user transparency setting. GPU rendering, multi-monitor crop alignment, and final visual quality still require a live Qt/Quickshell review.


## Panel spacing, legacy layout, and placement

The current **Flamenco** preset uses wider quick settings (560 logical pixels) and compact calendar (720), 125% panel spacing, taller quick-setting tiles, larger detail targets, and separated calendar navigation segments. Month cells and gaps grow with calendar spacing. Panels remain bounded by the screen and scroll when needed.

**Flamenco 1.0** is a separate Appearance layout preset restoring the original neutral palette, framed top bar and screen frame, editable quick-settings grid, and wide calendar Hub. It retains current shared fixes and accessibility improvements; it is a layout restoration, not a source-code rollback. Saved grid customization is retained.

Quick settings and Clock & Weather each offer independent placement: beside the bar button, screen center, top/bottom center, or any corner. Both default to the bar location again, and applying either Flamenco preset selects that location. Existing explicitly saved center placement stays unchanged until the user chooses another location or reapplies a preset. The calendar follows its originating bar button in both compact and Hub modes.

Each page also exposes **Button spacing** (100–160%). Clock & Weather adds **Compact panel width** (480–960 logical pixels); the existing Quick settings width control remains available. Placement is separate from bar alignment, which only applies to bar-relative quick settings.


## Wallpaper browser shortcut restored

The new Pills quick-settings layout now has a dedicated **Wallpaper carousel** button immediately above the sliders. It opens the existing wallpaper picker on the current panel's screen, including the 3D carousel and its search/navigation controls. If the user has explicitly selected the Grid picker, the same shortcut says **Wallpaper browser** and respects that choice. The duplicate bottom wallpaper tile is omitted only in Pills; other layouts and saved tile choices are preserved.


## Wallpaper tile and compact System tab

The wallpaper browser is now a standard quick-settings tile rather than a separate full-width button. In Pills it appears first among enabled tiles and opens the existing configured carousel/grid browser on the current screen. Saved tile visibility remains respected.

The compact calendar now includes **System**, using the same CPU, memory, temperatures, network, GPU, and process information as the original Hub. Its cards collapse to a single column at compact widths; process-bar widths are clamped to avoid negative geometry. System can also be selected as the default opening tab in Clock & Weather. Detailed collection remains active only while System is shown.


## Classic taskbar and simple application menu

Classic now explicitly selects a full-width, always-visible bottom taskbar with Start, a separator, and labeled running apps on the left. The notification area ends with the clock on the right. Workspace controls no longer interrupt the Start/app arrangement. Compact rectangular Start and app buttons follow the Classic preset. Reapply the preset to update a saved layout.

Settings → Bar → Start button → Opens now offers **Simple application menu**, enabled by Classic and selectable with any layout. The separate app-only panel provides an alphabetical Programs list, category browsing, global app search, app icons, keyboard selection/activation, and Settings/Power shortcuts. Right-click Start opens the full launcher, including the configured fuzzel backend. The menu uses the current monitor and stays clear of the bar; category and application lists scroll independently. Selecting a different layout resets the preset's Start action.

Validation: static QML checker passes (577 files, zero problems) and `git diff --check` passes. Quickshell and Qt lint tools are unavailable here; rendered appearance and live keyboard/pointer behavior remain unverified. In a live session, check Classic after switching from Unity and Aero, bottom/side bars, two monitors, empty categories/searches, Enter/Escape/Tab/arrow keys, short screens, and UI scaling.
