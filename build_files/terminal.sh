#!/bin/bash
set -ouex pipefail

### 1. Descargar e instalar la ÚLTIMA versión de Starship Prompt a nivel global
echo "Descargando e instalando Starship Prompt en el sistema..."

DOMINIO_STARSHIP="https://starship.rs"
ARCHIVO_STARSHIP="install.sh"

URL_STARSHIP_LIMPIA=$(echo "${DOMINIO_STARSHIP} / ${ARCHIVO_STARSHIP}" | tr -d ' ')

# Tu método original de descarga
curl -sS "$URL_STARSHIP_LIMPIA" | sh -s -- -y --bin-dir "/usr/bin"


### 2. Descargar e instalar la ÚLTIMA versión de gSlapper (.rpm) desde GitHub
echo "Buscando e instalando la última release de gSlapper para Fedora..."

REPO="Nomadcxx/gSlapper"
PROTOCOLO="https://"
DOMINIO="://github.com"
RUTA="/repos/$REPO/releases/latest"

API_URL=$(echo "${PROTOCOLO}${DOMINIO}${RUTA}" | tr -d ' ')

# Tu método original de extracción por API
JSON_DATA=$(curl -s "$API_URL")
URL_RPM=$(echo "$JSON_DATA" | grep -oP '"browser_download_url"\s*:\s*"\K[^"]+' | grep '\.rpm$')

if [ -z "$URL_RPM" ]; then
    echo "Error: No se pudo encontrar un paquete .rpm en la última versión de gSlapper."
    exit 1
fi

ARCHIVO_RPM=$(basename "$URL_RPM")

curl -L -o "$ARCHIVO_RPM" "$URL_RPM"
dnf5 -y install "$ARCHIVO_RPM"
rm -f "$ARCHIVO_RPM"


### 3. Generar configuraciones estéticas premium globales (/etc/skel)
mkdir -p /etc/skel/.config/kitty
mkdir -p /etc/skel/.config/fish

cp /ctx/kitty.conf /etc/skel/.config/kitty/kitty.conf
cp /ctx/starship.toml /etc/skel/.config/starship.toml
cp /ctx/config.fish /etc/skel/.config/fish/config.fish

chmod -R 755 /etc/skel/.config
