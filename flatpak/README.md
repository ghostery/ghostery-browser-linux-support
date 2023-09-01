# Flatpak packaging

Ghostery Private Browser flatpak recipe is now part of the Flathub
organization and can be found in its own repository at:

https://github.com/flathub/com.ghostery.browser

The current folder only contains the `make.rb` ruby script to help us maintain
the flatpak manifest when a new release of our browser happen.

- `ruby make.rb -d 2022-09-06 -v 2022.8` or `ruby make.rb bump -d 2022-09-06
  -v 2022.8` to prepare the manifest file for a new release. You can also pass
  the `-b BRANCH` parameter to switch between stable and beta release.
- `ruby make.rb build` to create a local flatpak package
- `ruby make.rb install` to install a previously created local flatpak package
- `ruby make.rb uninstall` to uninstall the flatpak previously installed
- `flatpak --user run com.ghostery.browser` to launch a previously installed
  version (you should also be able to just click on the Ghostery icon in your
  distribution app menu).
- `ruby make.rb clean` to just remove the build directory (necessary to make a
  new build, but automatically run by the `build` target)
- `ruby make.rb cleanall` to remove everything (build directory and flatpak
  builder cache directory).

The ruby script only uses standard library and thus a very simple ruby
installation should make it work.

The script expect the flathub repository to be cloned as
`com.ghostery.browser` just next to it. If it does not already exist, it will
be cloned for you.
