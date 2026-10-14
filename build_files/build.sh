#!/bin/bash

set -ouex pipefail

### 1. Añadir el repositorio de complementos e instalar la base
# Dejamos Hyprland por si acaso, pero quitamos kineticwe de dnf5 para que no pise la v2
dnf5 copr enable lionheartp/Hyprland -y

dnf5 -y install \
    noctalia-git \
    kitty \
    jq

### 2. Bypass del COPR: Descargar e instalar el binario precompilado de KineticWE V2 (GitLab CI Artifact)
echo "Extrayendo el paquete experimental de KineticWE V2 directamente desde GitLab..."

# Datos estructurados con el truco de los espacios para evitar bloqueos en el editor de GitHub
ID_PROYECTO="243156" # ID oficial del repositorio kineticwe en GitLab
RAMA_V2="kineticwe-2.0"

DOMINIO_API="https://gitlab.com"
RUTA_API="/api/v4/projects/${ID_PROYECTO}/jobs/artifacts/${RAMA_V2}/download?job=build"

URL_ARTIFACT_LIMPIA=$(echo "${DOMINIO_API}${RUTA_API}" | tr -d ' ')

# Descargamos el zip contenedor con los archivos construidos de la V2 en el servidor de GitLab
mkdir -p /tmp/v2-build
curl -sSL -o /tmp/v2-build/artifacts.zip "$URL_ARTIFACT_LIMPIA"

# Descomprimimos para buscar el ejecutable compilado en C++
cd /tmp/v2-build
unzip artifacts.zip

# Buscamos el binario final "kineticwe" resultante de la v2 y lo movemos a la zona global
if [ -f usr/bin/kineticwe ]; then
    cp usr/bin/kineticwe /usr/bin/kineticwe
elif [ -f build/bin/kineticwe ]; then
    cp build/bin/kineticwe /usr/bin/kineticwe
else
    # Si viene empaquetado directamente en la raíz del artefacto
    find . -name "kineticwe" -type f -exec cp {} /usr/bin/kineticwe \;
fi

# Limpieza absoluta de la zona temporal
cd /
rm -rf /tmp/v2-build

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
