#!/bin/bash
#
# Installation help for the Ghostery Browser. It downloads the latest
# binary build, and installs it in the user's home directory under
# ~/.local/opt/ghostery/Ghostery.
#
# Before running it, it is recommended to backup the profiles
# in "~/.ghostery browser".
#
# Note:
#
set -Eeuo pipefail

LANG="${1:-en-US}"
case "$LANG" in
    fr|FR|fr-FR|fr_FR)
        LANG=fr
        ;;
    de|DE|de-DE|de_DE)
        LANG=de
        ;;
    *)
        LANG=en-US
        ;;
esac

RELEASE_URL="https://get.ghosterybrowser.com/download/linux/$LANG"

# either wget or curl:
if type -p wget > /dev/null; then
    DOWNLOAD_CMD="wget --no-verbose --show-progress --output-document -"
elif type -p curl > /dev/null; then
    DOWNLOAD_CMD="curl -L --progress-bar"
else
    echo "ERROR: did not find a tool to download the release (install wget or curl)"
    exit 1
fi

if [[ $(whoami) = root ]]; then
    echo "Please do not run this script as root or using sudo"
    exit 1
fi

# Locations: application ~/.local/opt/ghostery/Ghostery and ~/.local/bin/ghostery
TARGET_BASE="$HOME/.local/opt/ghostery"
TARGET="$TARGET_BASE/Ghostery"
WRAPPER_SCRIPT_PREFIX="$HOME/.local/bin"
WRAPPER_SCRIPT="$WRAPPER_SCRIPT_PREFIX/ghostery"
APPLICATION_PREFIX="$HOME/.local/share/applications"
APPLICATION_LAUNCHER="$APPLICATION_PREFIX/ghostery-private-browser.desktop"

mkdir -p "$TARGET_BASE"
if [[ -e $TARGET ]]; then
    # TODO: perhaps keeping the old content around until it is clear that the download succeeded
    # would be wise. On the other hand, there is no data in the directory, so there is no risk
    # of loosing important state.
    echo "An existing installation was found in $TARGET. It will be replaced by the new installation."
    echo "This operation will not affect your existing profiles."
    rm -rf "$TARGET"
fi

echo "Downloading build from $RELEASE_URL and extracting to $TARGET..."
$DOWNLOAD_CMD "$RELEASE_URL" | tar -C "$TARGET_BASE" -xzf - Ghostery
if ! [[ -e $TARGET ]]; then
    echo "ERROR: Failed to install Ghostery."
    exit 1
fi
echo "Downloading build from $RELEASE_URL and extracting to $TARGET...SUCCESS"

echo "Creating wrapper script in $WRAPPER_SCRIPT"
mkdir -p "$WRAPPER_SCRIPT_PREFIX"
cat > "$WRAPPER_SCRIPT" <<EOF
#!/bin/sh
cd "$TARGET"
exec ./Ghostery "\$@"
EOF
chmod a+x "$WRAPPER_SCRIPT"

GRAPHICAL_MENU=n
if type -p update-desktop-database > /dev/null; then
    echo "Creating application launcher"
    mkdir -p "$APPLICATION_PREFIX"
    # FIXME: should be embedded in the browser tarball
    cat > "$APPLICATION_LAUNCHER" <<EOF
[Desktop Entry]
Version=1.0
Name=Ghostery Private Browser
GenericName=Web Browser
GenericName[de]=Webbrowser
GenericName[fr]=Navigateur Web
Comment=Browse the World Wide Web
Comment[de]=Im Internet surfen
Comment[fr]=Naviguer sur le Web
Keywords=Internet;WWW;Browser;Web;Explorer
Keywords[de]=Internet;WWW;Browser;Web;Explorer;Webseite;Site;surfen;online;browsen
Keywords[fr]=Internet;WWW;Browser;Web;Explorer;Fureteur;Surfer;Navigateur
Exec=$TARGET/Ghostery %u
Icon=$TARGET/browser/chrome/icons/default/default64.png
Terminal=false
X-MultipleArgs=false
Type=Application
MimeType=text/html;text/xml;application/xhtml+xml;x-scheme-handler/http;x-scheme-handler/https;application/x-xpinstall;application/pdf;application/json;
StartupNotify=true
StartupWMClass=Ghostery
Categories=Network;WebBrowser;
Actions=new-window;new-private-window;

[Desktop Action new-window]
Name=New Window
Name[de]=Neues Fenster
Name[en_US]=New Window
Name[fr]=Nouvelle fenêtre
Exec=$TARGET/Ghostery --new-window %u

[Desktop Action new-private-window]
Name=New Private Window
Name[de]=Neues privates Fenster
Name[en_US]=New Private Window
Name[fr]=Nouvelle fenêtre de navigation privée
Exec=$TARGET/Ghostery --private-window %u
EOF
    update-desktop-database "$APPLICATION_PREFIX"
    GRAPHICAL_MENU=y
fi

# Some distributions have ~/bin in the path but not ~/.local/bin.
if ! type -p ghostery > /dev/null; then
  if [[ -e $HOME/bin/ ]]; then
      echo "$HOME/.local/bin is not in the path, but it detected that $HOME/bin is."
      echo "Creating a symlink from $HOME/bin/ghostery to $WRAPPER_SCRIPT."
      (cd $HOME/bin && ln -s "$WRAPPER_SCRIPT" .)
  fi
fi

echo "Ghostery Private Browser has been successfully extracted to $TARGET."
if [ "$GRAPHICAL_MENU" = y ]; then
    echo
    echo "You should find it in your application menu and click Ghosty icon to start it."
    echo
    echo -n "You can also start it "
else
    echo
    echo -n "You can start it "
fi
echo "by running the following command:"
if type -p ghostery > /dev/null; then
    echo "ghostery"
else
    echo "$WRAPPER_SCRIPT"
    echo
    echo "Hint: consider adding ~/.local/bin/ghostery in your PATH."
    echo "For example, by adding this to your ~/.bashrc file:"
    echo
    echo 'export PATH="${PATH:+${PATH}:}$HOME/.local/bin"'
fi
