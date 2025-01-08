#!/usr/bin/env bash

# qBittorrent Installer for Batocera

# App Info
APPNAME="qBittorrent"
APPLINK="https://www.fosshub.com/qBittorrent.html?dwl=qbittorrent-5.0.3_x86_64.AppImage"
APPHOME="qbittorrent.org v5.0.3"
APPPATH="/userdata/system/add-ons/qbittorrent/qbittorrent.AppImage"
ICON="https://e7.pngegg.com/pngimages/380/378/png-clipart-qbittorrent-comparison-of-bittorrent-clients-others-blue-trademark.png"
COMMAND='$APPPATH'

# Define paths
add_ons="/userdata/system/add-ons"
appdir="$add_ons/qbittorrent"
extradir="$appdir/extra"

# Prepare directories
mkdir -p "$extradir"

# Download and install the app
cd "$extradir"
echo "Downloading $APPNAME..."
curl --progress-bar -O "$APPLINK"
chmod +x qbittorrent-5.0.3_x86_64.AppImage
mv qbittorrent-5.0.3_x86_64.AppImage "$APPPATH"
curl --progress-bar -L -o "icon.png" "$ICON"

# Create Desktop Shortcut
shortcut="$extradir/qbittorrent.desktop"
echo "[Desktop Entry]" > "$shortcut"
echo "Version=1.0" >> "$shortcut"
echo "Icon=$extradir/icon.png" >> "$shortcut"
echo "Exec=$COMMAND" >> "$shortcut"
echo "Terminal=false" >> "$shortcut"
echo "Type=Application" >> "$shortcut"
echo "Categories=Network;batocera.linux;" >> "$shortcut"
echo "Name=qBittorrent" >> "$shortcut"
chmod +x "$shortcut"
cp "$shortcut" /usr/share/applications/

# Create persistent desktop script
persistent_script="$extradir/startup.sh"
echo "#!/bin/bash" > "$persistent_script"
echo "if [ ! -f /usr/share/applications/$(basename "$shortcut") ]; then" >> "$persistent_script"
echo "    cp $shortcut /usr/share/applications/" >> "$persistent_script"
echo "fi" >> "$persistent_script"
chmod +x "$persistent_script"

# Add persistent script to custom.sh
csh="/userdata/system/custom.sh"
if ! grep -q "$persistent_script" "$csh"; then
    echo "$persistent_script &" >> "$csh"
fi

# Finish
echo "$APPNAME installed successfully."