# Makefile — git-safety hook installer
#
# Usage:
#   make install TARGET=/path/to/your-repo     Install hooks into another repo
#   make /path/to/your-repo                    Shorthand: absolute path as make goal
#   make self-install                          Install hooks into THIS repo

SHELL  := /bin/bash
SCRIPT := scripts/setup-git-hooks.sh

.PHONY: help install self-install

help:
	@echo ""
	@echo "git-safety — hook installer"
	@echo ""
	@echo "  make install TARGET=/path/to/your-repo   install into a specific repo"
	@echo "  make /path/to/your-repo                  shorthand (absolute path)"
	@echo "  make self-install                        install into THIS repo"
	@echo ""

install:
ifndef TARGET
	$(error TARGET is not set. Usage: make install TARGET=/path/to/your-repo)
endif
	@ROOT_DIR="$(TARGET)" bash $(SCRIPT)

self-install:
	@bash $(SCRIPT)

# Shorthand: make /abs/path/to/repo
/%:
	@ROOT_DIR="$@" bash $(SCRIPT)
