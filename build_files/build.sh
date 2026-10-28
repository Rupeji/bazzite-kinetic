#!/bin/bash

set -ouex pipefail

### 1. Añadir el repositorio COPR de KineticWE y complementos
dnf5 copr enable theblackdon/kwee -y
### 1.5 PURGA AVANZADA DE BAZZITE (Desde archivo independiente en /ctx/)

# [Scripts Pre] Borrado manual de launchers de apps de Bazzite y configs de SDDM viejas
rm -f /usr/share/applications/waydroid-container-restart.desktop
rm -f /usr/libexec/waydroid-container-restart \
      /usr/libexec/waydroid-container-start \
      /usr/libexec/waydroid-container-stop \
      /usr/libexec/waydroid-fix-controllers
rm -rf /usr/share/applications/Waydroid
rm -f /usr/share/applications/discourse.desktop
rm -f /usr/share/applications/bazzite-documentation.desktop
rm -f /usr/share/applications/system-update.desktop
rm -rf /etc/sddm.conf.d
rm -f /etc/sddm.conf

# Ruta absoluta basada en el montaje virtual del Containerfile
PATH_LISTA="/ctx/paquetes_a_borrar.txt"

if [ -f "$PATH_LISTA" ]; then
    # LEER, LIMPIAR COMENTARIOS Y CONVERTIR SALTOS DE LÍNEA EN ESPACIOS
    PAQUETES_FILTRADOS=$(grep -v '^#' "$PATH_LISTA" | grep -v '^$' | tr '\n' ' ')
    
    if [ -n "${PAQUETES_FILTRADOS// /}" ]; then
        echo "Iniciando la purga masiva de paquetes seleccionados..."
        dnf5 -y remove $PAQUETES_FILTRADOS
    else
        echo "Advertencia: El archivo paquetes_a_borrar.txt no contiene paquetes válidos."
    fi
else
    echo "ERROR Crítico: No se ha encontrado el archivo paquetes_a_borrar.txt en /ctx/"
    exit 1
fi

### 2. Instalar tu nuevo escritorio y tus aplicaciones del sistema
dnf5 -y install \
    kineticwe \
    kineticwe-greeter \
    nemo \
    nemo-fileroller \
    file-roller \
    gvfs \
    firefox \
    kitty

### 3. Descargar e instalar la ÚLTIMA versión de Starship Prompt a nivel global
echo "Descargando e instalando Starship Prompt en el sistema..."

DOMINIO_STARSHIP="https://starship.rs"
ARCHIVO_STARSHIP="install.sh"

URL_STARSHIP_LIMPIA=$(echo "${DOMINIO_STARSHIP} / ${ARCHIVO_STARSHIP}" | tr -d ' ')

# Descarga el instalador oficial (este script detecta el latest release automáticamente)
curl -sS "$URL_STARSHIP_LIMPIA" | sh -s -- -y --bin-dir "/usr/bin"


### Aquí empieza lo extra
### 7.5 HABILITAR EL GREETER DE DON ESTÁTICAMENTE (Adiós post-instalación manual)

# 1. Crear la estructura y la configuración de greetd apuntando a Noctalia
mkdir -p /etc/greetd
cat << 'EOF' > /etc/greetd/config.toml
[terminal]
vt = 1

[default_session]
command = "noctalia-greeter-session"
user = "greeter"
EOF

# 2. Asegurar los privilegios del usuario del sistema encargado del login gráfico
usermod -aG video,render greeter || true

# 3. Crear el archivo de plantilla tmpfiles de Don para regenerar la estética Catppuccin
mkdir -p /usr/lib/tmpfiles.d
install -Dm0644 /dev/stdin /usr/lib/tmpfiles.d/zz-kineticos-greeter.conf << 'EOF'
# KineticOS: seed the Catppuccin greeter default on first boot.
C /var/lib/noctalia-greeter/greeter.toml 0644 greetd greetd - /usr/share/kineticos/greeter.toml
EOF

# 4. EL TRUCO MAESTRO: Enlazar el servicio manualmente (Esto equivale a systemctl enable)
# Rompemos el enlace antiguo por si KDE dejó rastros de SDDM/GDM
rm -f /etc/systemd/system/display-manager.service

# Creamos el directorio de dependencias del Display Manager y enlazamos greetd
mkdir -p /etc/systemd/system/display-manager.service.wants
ln -sf /usr/lib/systemd/system/greetd.service /etc/systemd/system/display-manager.service

### Aquí termina lo añadido

### 4. Descargar e instalar la ÚLTIMA versión de gSlapper (.rpm) desde GitHub
echo "Buscando e instalando la última release de gSlapper para Fedora..."

REPO="Nomadcxx/gSlapper"
PROTOCOLO="https://"
DOMINIO="api.github.com"
RUTA="/repos/$REPO/releases/latest"

API_URL=$(echo "${PROTOCOLO}${DOMINIO}${RUTA}" | tr -d ' ')

# 1. Obtener la información de la release y extraer el enlace .rpm de forma segura
JSON_DATA=$(curl -s "$API_URL")
URL_RPM=$(echo "$JSON_DATA" | grep -oP '"browser_download_url"\s*:\s*"\K[^"]+' | grep '\.rpm$')

# 2. Verificar si se encontró el paquete de Fedora de manera no interactiva para la build
if [ -z "$URL_RPM" ]; then
    echo "Error: No se pudo encontrar un paquete .rpm en la última versión de gSlapper."
    exit 1
fi

# Extraer el nombre del archivo de la URL
ARCHIVO_RPM=$(basename "$URL_RPM")

# 3. Descargar el paquete e instalarlo de forma nativa resolviendo dependencias
curl -L -o "$ARCHIVO_RPM" "$URL_RPM"
dnf5 -y install "$ARCHIVO_RPM"
rm -f "$ARCHIVO_RPM"

### 5. Generar configuraciones estéticas premium globales (/etc/skel)
mkdir -p /etc/skel/.config/kitty
mkdir -p /etc/skel/.config/fish

# Copiamos tus plantillas estéticas desde la carpeta compartida /ctx/
cp /ctx/kitty.conf /etc/skel/.config/kitty/kitty.conf
cp /ctx/starship.toml /etc/skel/.config/starship.toml
cp /ctx/config.fish /etc/skel/.config/fish/config.fish

# Aseguramos los permisos estándar para que el usuario pueda editarlos
chmod -R 755 /etc/skel/.config

### 6. Instalar la tipografía oficial para los iconos de la consola
mkdir -p /usr/share/fonts/jetbrains-mono-nerd
echo "Descargando tipografía JetBrainsMono Nerd Font para los iconos..."

DOMINIO_FONTS="https://github.com"
REPOSITORIO_FONTS="ryanoasis / nerd-fonts / releases / latest / download"
ARCHIVO_FONTS="JetBrainsMono.tar.xz"

URL_FONTS_LIMPIA=$(echo "${DOMINIO_FONTS} / ${REPOSITORIO_FONTS} / ${ARCHIVO_FONTS}" | tr -d ' ')

# Descargamos el archivo comprimido oficial (.tar.xz) y lo descomprimimos directamente en el directorio de fuentes
curl -sSL "$URL_FONTS_LIMPIA" | tar -xJ -C /usr/share/fonts/jetbrains-mono-nerd/

fc-cache -f -v

### 7. Configurar el Shell y activar servicios de soporte (Compatible con Builds)
# Forzar a que todos los nuevos usuarios tengan Fish por defecto en el sistema
sed -i 's/SHELL=\/bin\/bash/SHELL=\/usr\/bin\/fish/g' /etc/default/useradd

# Habilitar el socket de podman creando el enlace simbólico manualmente (Evita fallos en Build Time)
mkdir -p /etc/systemd/system/sockets.target.wants
ln -sf /usr/lib/systemd/system/podman.socket /etc/systemd/system/sockets.target.wants/podman.socket


### 7.8 Inyectar el servicio First-Boot para desinstalar Flatpaks del sistema
mkdir -p /usr/libexec
cat << 'EOF' > /usr/libexec/kineticos-remove-flatpaks
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
EOF
chmod 755 /usr/libexec/kineticos-remove-flatpaks

cat << 'EOF' > /usr/lib/systemd/system/kineticos-flatpak-removals.service
[Unit]
Description=Remove unwanted Bazzite system Flatpaks (once per app)
ConditionPathExists=/usr/bin/flatpak

[Service]
Type=oneshot
ExecStart=/usr/libexec/kineticos-remove-flatpaks
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
EOF

mkdir -p /etc/systemd/system/multi-user.target.wants
ln -sf /usr/lib/systemd/system/kineticos-flatpak-removals.service /etc/systemd/system/multi-user.target.wants/kineticos-flatpak-removals.service

### 8. LIMPIEZA ABSOLUTA (Elimina las advertencias de 'bootc container lint')
# Borramos metadatos de dnf y rastros generados en /var para que el linter pase en verde
dnf5 clean all
rm -rf /var/cache/dnf /var/lib/dnf/repos /var/log/dnf*
