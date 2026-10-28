#!/bin/bash
set -ouex pipefail

echo "=== INICIANDO INSTALACIÓN MODULAR DE HERRAMIENTAS ==="

# 1. Descargar e instalar la ÚLTIMA versión de Starship Prompt a nivel global
echo "Descargando e instalar Starship Prompt en el sistema..."

DOMINIO_STARSHIP="https://starship.rs"
ARCHIVO_STARSHIP="install.sh"

URL_STARSHIP_LIMPIA=$(echo "${DOMINIO_STARSHIP} / ${ARCHIVO_STARSHIP}" | tr -d ' ')

# Descarga el instalador oficial de forma segura
curl -sS "$URL_STARSHIP_LIMPIA" | sh -s -- -y --bin-dir "/usr/bin"

# 2. Descargar e instalar la ÚLTIMA versión de gSlapper (.rpm) desde GitHub
echo "Buscando e instalando la última release de gSlapper para Fedora..."
REPO="Nomadcxx/gSlapper"
API_URL="https://github.com{REPO}/releases/latest"

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

# 3. Generar configuraciones estéticas premium globales (/etc/skel)
mkdir -p /etc/skel/.config/kitty
mkdir -p /etc/skel/.config/fish

# Copiamos tus plantillas estéticas desde la carpeta compartida /ctx/
cp /ctx/kitty.conf /etc/skel/.config/kitty/kitty.conf
cp /ctx/starship.toml /etc/skel/.config/starship.toml
cp /ctx/config.fish /etc/skel/.config/fish/config.fish

# Aseguramos los permisos estándar para que el usuario pueda editarlos
chmod -R 755 /etc/skel/.config

# 4. Instalar la tipografía oficial para los iconos de la consola
mkdir -p /usr/share/fonts/jetbrains-mono-nerd
echo "Descargando tipografía JetBrainsMono Nerd Font para los iconos..."

DOMINIO_FONTS="https://github.com"
REPOSITORIO_FONTS="ryanoasis / nerd-fonts / releases / latest / download"
ARCHIVO_FONTS="JetBrainsMono.tar.xz"

URL_FONTS_LIMPIA=$(echo "${DOMINIO_FONTS} / ${REPOSITORIO_FONTS} / ${ARCHIVO_FONTS}" | tr -d ' ')

# Descargamos el archivo comprimido oficial (.tar.xz) de forma segura y limpia
curl -sSL "$URL_FONTS_LIMPIA" | tar -xJ -C /usr/share/fonts/jetbrains-mono-nerd/

fc-cache -f -v

echo "=== INSTALACIÓN DE HERRAMIENTAS COMPLETADA CON ÉXITO ==="
