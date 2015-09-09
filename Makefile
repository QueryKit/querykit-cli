DESTDIR := /usr/local

all: dependencies build

build:
	xcrun -sdk macosx swiftc -O -o bin/querykit -F Rome -framework CoreData -framework PathKit -framework Stencil bin/querykit.swift

dependencies:
	pod install --no-integrate

install:
	mkdir -p "$(DESTDIR)/bin/"
	mkdir -p "$(DESTDIR)/share/querykit/"
	mkdir -p "$(DESTDIR)/Frameworks/"
	cp -f "bin/querykit" "$(DESTDIR)/bin/"
	cp -f "share/querykit/template.swift" "$(DESTDIR)/share/querykit/"
	cp -fr "Rome/" "$(DESTDIR)/Frameworks/"
	install_name_tool -add_rpath "@executable_path/../Frameworks/"  "$(DESTDIR)/bin/querykit"

