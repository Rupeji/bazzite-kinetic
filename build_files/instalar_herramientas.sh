#!/bin/bash
set -ouex pipefail

echo "=== INICIANDO INSTALACIÓN MODULAR DE HERRAMIENTAS ==="

# 1. Descargar e instalar la ÚLTIMA versión de Starship Prompt a nivel global
echo "Instalando Starship Prompt..."
curl -sS "https://starship.rs" | sh -s -- -y --bin-dir "/usr/bin"

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
URL_FONTS="https://github.com"

curl -sSL "$URL_FONTS" | tar -xJ -C /usr/share/fonts/jetbrains-mono-nerd/
fc-cache -f -v

echo "=== INSTALACIÓN DE HERRAMIENTAS COMPLETADA CON ÉXITO ==="
