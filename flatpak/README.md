# Flatpak packaging

Current manifest is largely inspired by the one from [Librewolf community](https://gitlab.com/librewolf-community/browser/flatpak/)

To build it, you can use the provided `Makefile`:

- `make` or `make build` to create a local flatpak package
- `make install` to install a previously created local flatpak package
- `make uninstall` to uninstall the flatpak previously installed
- `flatpak --user run com.ghostery.dawn` or `make run` to launch a previously
  installed version (you should also be able to just click on the Ghostery
  icon in your distribution app menu).
- `make clean` to just remove the build directory (necessary to make a new
  build, but automatically run by the `build` target)
- `make cleanall` to remove everything (build directory, flatpak builder cache
  directory and uninstall any installed ghostery flatpak).

To prepare the manifest file for a new release, you can use the provided ruby
script:

    ruby upgrade.rb 2022-11-29 2022.8.1
