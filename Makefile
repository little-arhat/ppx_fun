NAME := ppx_fun
PREFIX = $(shell opam config var prefix)
RUNNER := dune

build:
	$(RUNNER) build

test:
	$(RUNNER) runtest

$(NAME).install:
	$(MAKE) build

clean:
	$(RUNNER) clean
	rm -f $(NAME).install
	rm -f $(NAME)-tests.install

install: $(NAME).install
	opam-installer -i --prefix $(PREFIX) $(NAME).install

uninstall: $(NAME).install
	opam-installer -u --prefix $(PREFIX) $(NAME).install

reinstall: $(NAME).install
	opam-installer -u --prefix $(PREFIX) $(NAME).install &> /dev/null || true
	opam-installer -i --prefix $(PREFIX) $(NAME).install

.PHONY: build driver test clean


VERSION      := $$(opam query --version ppx_fun.opam)
NAME_VERSION := $$(opam query --name-version ppx_fun.opam)
ARCHIVE      := $$(opam query --archive ppx_fun.opam)

release:
	git tag -a v$(VERSION) -m "Version $(VERSION)."
	git push origin v$(VERSION)
# opam publish prepare $(NAME_VERSION) $(ARCHIVE)
# opam publish submit $(NAME_VERSION)
# rm -rf $(NAME_VERSION)

.PHONY: release
