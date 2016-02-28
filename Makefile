DESTDIR := /usr/local

build:
	@swift build --configuration release

install: build
	install -d "$(DESTDIR)/bin"
	install -d "$(DESTDIR)/share/querykit"
	install -C -m 755 ".build/release/querykit" "$(DESTDIR)/bin/querykit"
	install -C -m 644 "share/querykit/template.swift" "$(DESTDIR)/share/querykit"
