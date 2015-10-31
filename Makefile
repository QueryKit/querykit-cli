DESTDIR := /usr/local

install:
	conche install --prefix "$(DESTDIR)"
	install -d "$(DESTDIR)/share/querykit"
	install -C "share/querykit/template.swift" "$(DESTDIR)/share/querykit/"

tarball:
	make DESTDIR=build install
	install -C -m 644 Makefile.binary build/Makefile
	GZIP=-9 tar -czf querykit-cli.tar.gz build/

clean:
	rm -fr build querykit-cli.tar.gz
