# Default to the Homebrew prefix when available (e.g. /opt/homebrew on Apple
# Silicon, /usr/local on Intel), otherwise fall back to /usr/local. Override
# with `make install PREFIX=/somewhere`.
PREFIX ?= $(shell brew --prefix 2>/dev/null || echo /usr/local)
BINDIR = $(PREFIX)/bin
BASH_COMPLETION_DIR ?= $(PREFIX)/etc/bash_completion.d
ZSH_COMPLETION_DIR ?= $(PREFIX)/share/zsh/site-functions

# Directory for a local/devmode install. Override with `make install-dev DEV_BINDIR=...`.
DEV_BINDIR ?= $(HOME)/.bin

.PHONY: install install-alias install-completions install-dev uninstall uninstall-dev test

install: install-completions
	install -d $(BINDIR)
	install -m 755 git-wt $(BINDIR)/git-wt

install-alias: install
	ln -sf $(BINDIR)/git-wt $(BINDIR)/wt

install-completions:
	install -d $(BASH_COMPLETION_DIR)
	install -m 644 completions/git-wt.bash $(BASH_COMPLETION_DIR)/git-wt
	install -d $(ZSH_COMPLETION_DIR)
	install -m 644 completions/git-wt.zsh $(ZSH_COMPLETION_DIR)/_git-wt

# Symlink the working-tree script into DEV_BINDIR so local edits take effect
# immediately. Also links the `wt` alias.
install-dev:
	install -d $(DEV_BINDIR)
	ln -sf $(CURDIR)/git-wt $(DEV_BINDIR)/git-wt
	ln -sf $(CURDIR)/git-wt $(DEV_BINDIR)/wt

uninstall-dev:
	rm -f $(DEV_BINDIR)/git-wt
	rm -f $(DEV_BINDIR)/wt

uninstall:
	rm -f $(BINDIR)/git-wt
	rm -f $(BINDIR)/wt
	rm -f $(BASH_COMPLETION_DIR)/git-wt
	rm -f $(ZSH_COMPLETION_DIR)/_git-wt

test:
	bats test/
