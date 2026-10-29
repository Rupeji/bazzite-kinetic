#!/usr/bin/bash
set -u

install -d /var/lib/kineticos
stamp=/var/lib/kineticos/flatpak-removals.done
touch "$stamp"

for app in \
    io.github.DenysMb.Kontainer \
    com.github.Matoking.protontricks \
    org.kde.kcalc \
    org.kde.okular \
    org.mozilla.firefox \
    org.kde.haruna \
    org.kde.gwenview \
    io.github.flattool.Warehouse \
    com.github.tchx84.Flatseal \
    org.gnome.Firmware
do
    grep -qxF "$app" "$stamp" && continue
    flatpak uninstall -y --system --noninteractive "$app" >/dev/null 2>&1 || true
    echo "$app" >> "$stamp"
done
