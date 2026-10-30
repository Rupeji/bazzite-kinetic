#!/usr/bin/bash
set -u

# Crear el directorio persistente si no existe
install -d /var/lib/kineticos
stamp=/var/lib/kineticos/flatpak-removals.done

# Asegurar que el archivo de registro exista (sin vaciarlo)
touch "$stamp"

for app in \
    io.github.DenysMb.Kontainer \
    #com.github.Matoking.protontricks \
    org.kde.kcalc \
    org.kde.okular \
    org.mozilla.firefox \
    org.kde.haruna \
    org.kde.gwenview \
    #io.github.flattool.Warehouse \
    #com.github.tchx84.Flatseal \
    org.gnome.Firmware
do
    # Si la app ya se procesó en el pasado, saltar a la siguiente
    if grep -qxF "$app" "$stamp"; then
        continue
    fi

    # Intentar la desinstalación silenciosa
    echo "Eliminando Flatpak heredado de Bazzite: $app"
    flatpak uninstall -y --system --noninteractive "$app" >/dev/null 2>&1 || true
    
    # Registrar de forma persistente que esta app ya fue procesada
    echo "$app" >> "$stamp"
done
