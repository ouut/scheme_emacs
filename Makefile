# ==============================================================================
# Makefile for Scheme Emacs Development
# ==============================================================================

.PHONY: all setup test run dev compile clean build

# Default target
all: test

# One-step environment setup & dependency vendor
setup:
	@chmod +x scripts/setup-dev.sh
	@./scripts/setup-dev.sh

# Run ERT automated regression tests
test:
	emacs -batch -l test_config.el -f ert-run-tests-batch-and-exit

# Launch Scheme Emacs interactive playground in isolated profile
run:
	./bin/scheme-emacs sample.scm

# Launch Scheme Emacs in terminal mode
run-nw:
	./bin/scheme-emacs -nw sample.scm

# Pre-compile all Elisp source files to bytecode (.elc)
compile:
	emacs -batch -Q \
		-L ./lisp \
		-l ./early-init.el \
		-l ./init.el \
		-f batch-byte-compile \
		./lisp/*.el ./early-init.el ./init.el

# Clean compiled bytecode and build artifacts
clean:
	rm -f *.elc lisp/*.elc test_config.elc
	rm -rf dist build-appimage build-macos build-windows

# Build Linux lightweight tarball
build:
	./scripts/build.sh

# Build Linux standalone AppImage
build-appimage:
	./scripts/build-appimage.sh
