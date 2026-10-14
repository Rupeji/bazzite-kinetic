#!/bin/bash

set -ouex pipefail

### 1. Instalar dependencias necesarias para compilar KineticWE V2
# Eliminamos mesa-libGL-devel para evitar el conflicto con los drivers de Bazzite
# Añadimos --skip-broken para que DNF ignore paquetes conflictivos automáticamente
dnf5 -y install --skip-broken \
    git \
    cargo \
    rust \
    clang-devel \
    wayland-devel \
    libinput-devel \
    kitty

### 2. Clonar y Compilar de forma nativa la V2 (Rama kineticwe-2.0)
echo "Clonando y compilando la revolucionaria V2 de KineticWE..."
mkdir -p /tmp/kinetic-build
cd /tmp/kinetic-build

# Truco de los espacios para blindar la URL de GitLab
DOMINIO_GITLAB="https://gitlab.com"
RUTA_KINETIC="theblackdon / kineticwe.git"
URL_KINETIC_LIMPIA=$(echo "${DOMINIO_GITLAB} / ${RUTA_KINETIC}" | tr -d ' ')

# Clonamos la rama específica usando la URL limpia e inmune a recortes
git clone --branch kineticwe-2.0 "$URL_KINETIC_LIMPIA"
cd kineticwe

# Compilamos en modo Release usando el motor de Rust (Optimización máxima)
cargo build --release

# Movemos los binarios resultantes directamente a las rutas globales del sistema
cp target/release/kineticwe /usr/bin/kineticwe

# Si el proyecto genera su gestor de ventanas noctalia en esta rama, lo copiamos igual:
if [ -f target/release/noctalia ]; then
    cp target/release/noctalia /usr/bin/noctalia
fi

# Limpiamos la carpeta de compilación para que la ISO no pese gigabytes extra
cd /
rm -rf /tmp/kinetic-build

### 3. Descargar e instalar la ÚLTIMA versión de Starship Prompt a nivel global
echo "Descargando e instalando Starship Prompt en el sistema..."
DOMINIO_STARSHIP="https://starship.rs"
ARCHIVO_STARSHIP="install.sh"
URL_STARSHIP_LIMPIA=$(echo "${DOMINIO_STARSHIP} / ${ARCHIVO_STARSHIP}" | tr -d ' ')
curl -sS "$URL_STARSHIP_LIMPIA" | sh -s -- -y --bin-dir "/usr/bin"

### 4. Descargar e instalar la ÚLTIMA versión de gSlapper (.rpm) desde GitHub
echo "Buscando e instalando la última release de gSlapper para Fedora..."
REPO="Nomadcxx/gSlapper"
PROTOCOLO="https://"
DOMINIO="api.github.com"
RUTA="/repos/$REPO/releases/latest"
API_URL=$(echo "${PROTOCOLO}${DOMINIO}${RUTA}" | tr -d ' ')
JSON_DATA=$(curl -s "$API_URL")
URL_RPM=$(echo "$JSON_DATA" | grep -oP '"browser_download_url"\s*:\s*"\K[^"]+' | grep '\.rpm$')

if [ -n "$URL_RPM" ]; then
    ARCHIVO_RPM=$(basename "$URL_RPM")
    curl -L -o "$ARCHIVO_RPM" "$URL_RPM"
    dnf5 -y install "$ARCHIVO_RPM"
    rm -f "$ARCHIVO_RPM"
fi

### 5. Generar configuraciones estéticas premium globales (/etc/skel)
mkdir -p /etc/skel/.config/kitty
mkdir -p /etc/skel/.config/fish
cp /ctx/kitty.conf /etc/skel/.config/kitty/kitty.conf
cp /ctx/starship.toml /etc/skel/.config/starship.toml
cp /ctx/config.fish /etc/skel/.config/fish/config.fish
chmod -R 755 /etc/skel/.config

### 6. Instalar la tipografía oficial para los iconos de la consola
mkdir -p /usr/share/fonts/jetbrains-mono-nerd
DOMINIO_FONTS="https://github.com"
REPOSITORIO_FONTS="ryanoasis / nerd-fonts / releases / latest / download"
ARCHIVO_FONTS="JetBrainsMono.tar.xz"
URL_FONTS_LIMPIA=$(echo "${DOMINIO_FONTS} / ${REPOSITORIO_FONTS} / ${ARCHIVO_FONTS}" | tr -d ' ')
curl -sSL "$URL_FONTS_LIMPIA" | tar -xJ -C /usr/share/fonts/jetbrains-mono-nerd/
fc-cache -f -v

### 7. Configurar el Shell y activar servicios de soporte
sed -i 's/SHELL=\/bin\/bash/SHELL=\/usr\/bin\/fish/g' /etc/default/useradd
mkdir -p /etc/systemd/system/sockets.target.wants
ln -sf /usr/lib/systemd/system/podman.socket /etc/systemd/system/sockets.target.wants/podman.socket
