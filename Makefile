PREFIX ?= $(HOME)/.local
SHARE  := $(PREFIX)/share/flamenco-shell
BIN    := $(PREFIX)/bin

.PHONY: install uninstall dev run

# Copy the shell to $(PREFIX)/share/flamenco-shell and the CLI to $(PREFIX)/bin.
install:
	install -d $(SHARE) $(BIN)
	cp -r shell $(SHARE)/
	install -Dm644 data/niri/config.kdl $(SHARE)/niri/config.kdl
	install -Dm644 data/hypr/hyprland.conf $(SHARE)/hypr/hyprland.conf
	install -Dm644 data/hypr/hyprland.lua $(SHARE)/hypr/hyprland.lua
	install -m 755 bin/flamenco $(SHARE)/flamenco
	ln -sf $(SHARE)/flamenco $(BIN)/flamenco
	install -Dm644 data/flamenco-settings.desktop $(PREFIX)/share/applications/flamenco-settings.desktop
	install -Dm644 data/flamenco-settings.svg $(PREFIX)/share/icons/hicolor/scalable/apps/flamenco-settings.svg
	@echo "Installed. Add the output of 'flamenco niri-config' to ~/.config/niri/config.kdl"

# Symlink instead of copying, so edits in this checkout are live (Quickshell hot-reloads).
dev:
	install -d $(BIN)
	ln -sf $(CURDIR)/bin/flamenco $(BIN)/flamenco
	install -Dm644 data/flamenco-settings.desktop $(PREFIX)/share/applications/flamenco-settings.desktop
	install -Dm644 data/flamenco-settings.svg $(PREFIX)/share/icons/hicolor/scalable/apps/flamenco-settings.svg
	@echo "Linked $(BIN)/flamenco -> $(CURDIR)/bin/flamenco"

uninstall:
	rm -f $(BIN)/flamenco $(PREFIX)/share/applications/flamenco-settings.desktop $(PREFIX)/share/icons/hicolor/scalable/apps/flamenco-settings.svg
	rm -rf $(SHARE)

run:
	./bin/flamenco run --fg
