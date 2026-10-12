PREFIX ?= $(HOME)/.local
SHARE  := $(PREFIX)/share/flamenco-shell
BIN    := $(PREFIX)/bin

.PHONY: install uninstall dev run

# Copy the shell to $(PREFIX)/share/flamenco-shell and the CLI to $(PREFIX)/bin.
install:
	install -d $(SHARE) $(BIN)
	cp -r shell $(SHARE)/
	install -m 755 bin/flamenco $(SHARE)/flamenco
	ln -sf $(SHARE)/flamenco $(BIN)/flamenco
	@echo "Installed. Add the output of 'flamenco niri-config' to ~/.config/niri/config.kdl"

# Symlink instead of copying, so edits in this checkout are live (Quickshell hot-reloads).
dev:
	install -d $(BIN)
	ln -sf $(CURDIR)/bin/flamenco $(BIN)/flamenco
	@echo "Linked $(BIN)/flamenco -> $(CURDIR)/bin/flamenco"

uninstall:
	rm -f $(BIN)/flamenco
	rm -rf $(SHARE)

run:
	./bin/flamenco run --fg
