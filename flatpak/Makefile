.PHONY: build clean cleanall install run uninstall

all: build

build: clean
	flatpak --user --noninteractive install org.freedesktop.Sdk//22.08
	flatpak-builder build-dir com.ghostery.dawn.yml

install:
	flatpak-builder --user --install --force-clean build-dir com.ghostery.dawn.yml

run:
	flatpak --user run com.ghostery.dawn

uninstall:
	flatpak --user --noninteractive uninstall com.ghostery.dawn || true

clean:
	rm -rf build-dir

cleanall: clean
	rm -rf .flatpak-builder
