# Windows GNU Make (Scoop) does not have `/bin/bash` on PATH by default, but Git for Windows does.
# You can override BASH, e.g. `make BASH="C:/Program Files/Git/usr/bin/bash.exe" help`.
# Use 8.3 paths to avoid spaces (GNU Make's wildcard is picky about spaces).
BASH := $(firstword $(wildcard $(GIT_BASH)) $(wildcard C:/Progra~1/Git/usr/bin/bash.exe))
ifeq ($(BASH),)
BASH := bash
endif
# Windows often exports SHELL=cmd.exe, which would otherwise override Makefile settings.
override SHELL := $(BASH)
override .SHELLFLAGS := --noprofile --norc -euo pipefail -c
MAKEFLAGS += --no-builtin-rules
.DELETE_ON_ERROR:

# GitHub Pages / Jekyll
JEKYLL := bundle exec jekyll
DEST ?= _site
BUNDLE := bundle
PURGE_BUNDLE ?= 0
HOST ?= 127.0.0.1
PORT ?= 4000
export JEKYLL_ENV ?= production

define PRINT_HEADER
	@echo
	@echo "==> $(1)"
endef

.DEFAULT_GOAL := help

.PHONY: help
help:
	@echo "Targets:"
	@echo "  make install   Install Ruby gems (uses repo .bundle/config if present)"
	@echo "  make build     Build the static site to ./$(DEST) (BUNDLE_FROZEN=1 by default)"
	@echo "  make serve     Local dev server (sets JEKYLL_ENV=development unless overridden)"
	@echo "  make doctor    jekyll doctor"
	@echo "  make toolchain  Show ruby + bundler versions"
	@echo "  make bundle-check  Run: bundle check"
	@echo "  make check     Full local diagnostics (after gems are installed)"
	@echo "  make clean     Remove Jekyll build outputs"
	@echo "  make clobber   clean (and optionally remove vendor/bundle)"
	@echo "  make rebuild   clobber + build"
	@echo
	@echo "Notes:"
	@echo "  - First time: make install, then make build (or make serve)"
	@echo "  - Windows RubyInstaller often needs the MSYS2 dev tools (see: https://github.com/oneclick/rubyinstaller2/wiki/MSYS2-Installation)"
	@echo
	@echo "Common overrides:"
	@echo "  make serve PORT=4000 HOST=127.0.0.1"
	@echo "  make build DEST=tmp_site"
	@echo "  make clobber PURGE_BUNDLE=1  # also remove ./vendor/bundle"

.PHONY: toolchain
toolchain:
	$(call PRINT_HEADER,toolchain)
	@command -v ruby >/dev/null
	@command -v $(BUNDLE) >/dev/null
	@ruby -v
	@$(BUNDLE) -v

.PHONY: bundle-check
bundle-check: toolchain
	$(call PRINT_HEADER,bundle check)
	@$(BUNDLE) check

.PHONY: check
check: bundle-check
	$(call PRINT_HEADER,jekyll)
	@$(BUNDLE) exec jekyll -v
	$(call PRINT_HEADER,git)
	@git --version
	@git status -sb || true
	@command -v date >/dev/null 2>&1 && date -u +%Y-%m-%dT%H:%M:%SZ 2>/dev/null | sed 's/^/timestamp(utc): /' || true

.PHONY: install
install: toolchain
	$(call PRINT_HEADER,bundle install)
	$(BUNDLE) install

.PHONY: build
build: bundle-check
	$(call PRINT_HEADER,jekyll build)
	BUNDLE_FROZEN=1 $(JEKYLL) build --trace --destination "$(DEST)"

# Local preview: not frozen, since devs often add gems in Gemfile and haven't locked yet.
.PHONY: serve
serve: JEKYLL_ENV := development
serve: bundle-check
	$(call PRINT_HEADER,jekyll serve)
	BUNDLE_FROZEN=0 $(JEKYLL) serve --livereload --host "$(HOST)" --port "$(PORT)"

.PHONY: doctor
doctor: bundle-check
	$(call PRINT_HEADER,jekyll doctor)
	BUNDLE_FROZEN=1 $(JEKYLL) doctor

.PHONY: clean
clean:
	$(call PRINT_HEADER,clean)
	rm -rf "$(DEST)" .jekyll-cache .jekyll-metadata .sass-cache

.PHONY: clobber
clobber: clean
	$(call PRINT_HEADER,clobber)
	@if [ "$(PURGE_BUNDLE)" = "1" ]; then \
		echo "removing ./vendor/bundle"; \
		rm -rf ./vendor/bundle; \
	else \
		echo "not removing ./vendor/bundle (set PURGE_BUNDLE=1 to remove)"; \
	fi

.PHONY: rebuild
rebuild: clobber build
