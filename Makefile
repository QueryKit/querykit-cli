DESTDIR := /usr/local

build:
	@echo "DEPRECATED: QueryKit CLI is no longer needed, QueryKit 0.14.0 works with KeyPath, see https://github.com/QueryKit/QueryKit/pull/55."
	@swift build --configuration release

install: build
	install -d "$(DESTDIR)/bin"
	install -d "$(DESTDIR)/share/querykit"
	install -C -m 755 ".build/release/querykit" "$(DESTDIR)/bin/querykit"
	install -C -m 644 "share/querykit/template.swift" "$(DESTDIR)/share/querykit"
