#!/bin/bash
set -ouex pipefail

### 1. Descargar e instalar la ÚLTIMA versión de Starship Prompt a nivel global
echo "Descargando e instalando Starship Prompt en el sistema..."

DOMINIO_STARSHIP="https://starship.rs"
ARCHIVO_STARSHIP="install.sh"

URL_STARSHIP_LIMPIA=$(echo "${DOMINIO_STARSHIP} / ${ARCHIVO_STARSHIP}" | tr -d ' ')

curl -sS "$URL_STARSHIP_LIMPIA" | sh -s -- -y --bin-dir "/usr/bin"


### 2. Descargar e instalar la ÚLTIMA versión de gSlapper (.rpm) desde GitHub
echo "Buscando e instalando la última release de gSlapper para Fedora..."

REPO="Nomadcxx/gSlapper"
BASE_API="https://api.github.com"  # <- Corregido aquí para usar el subdominio api
RUTA_API="/repos/$REPO/releases/latest"

# Usamos tu truco de espacios infalible con las variables de la API correctas
API_URL=$(echo "${BASE_API} ${RUTA_API}" | tr -d ' ')

# Obtener la información de la release y extraer el enlace .rpm de forma segura
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

# Copiamos tus plantillas estéticas desde la carpeta compartida /ctx/
cp /ctx/kitty.conf /etc/skel/.config/kitty/kitty.conf
cp /ctx/starship.toml /etc/skel/.config/starship.toml
cp /ctx/config.fish /etc/skel/.config/fish/config.fish

# Aseguramos los permisos estándar para que el usuario pueda editarlos
chmod -R 755 /etc/skel/.config


### 4. Instalar la tipografía oficial para los iconos de la consola
mkdir -p /usr/share/fonts/jetbrains-mono-nerd
echo "Descargando tipografía JetBrainsMono Nerd Font para los iconos..."

DOMINIO_FONTS="https://github.com"
REPOSITORIO_FONTS="ryanoasis / nerd-fonts / releases / latest / download"
ARCHIVO_FONTS="JetBrainsMono.tar.xz"

URL_FONTS_LIMPIA=$(echo "${DOMINIO_FONTS} / ${REPOSITORIO_FONTS} / ${ARCHIVO_FONTS}" | tr -d ' ')

curl -sSL "$URL_FONTS_LIMPIA" | tar -xJ -C /usr/share/fonts/jetbrains-mono-nerd/

fc-cache -f -v
# =====================================================================
# 5. Descarga de Recursos Globales (Iconos y Wallpapers)
# =====================================================================
echo "Conectando con GitHub para descargar tu repositorio IconsWalls..."

DIR_TEMPORAL="/tmp/git_iconswalls_backup"
rm -rf "$DIR_TEMPORAL"

echo "Clonando repositorio superficialmente (IconsWalls)..."
if git clone --depth 1 https://github.com/Rupeji/IconsWalls "$DIR_TEMPORAL"; then
    echo "Repositorio clonado correctamente."

    # 1. Despliegue de los Iconos en el perfil global por defecto (/etc/skel)
    if [ -d "$DIR_TEMPORAL/Iconos" ]; then
        echo "Copiando Iconos al directorio global /etc/skel/.local/share/icons/..."
        mkdir -p /etc/skel/.local/share/icons
        cp -r "$DIR_TEMPORAL/Iconos"/* /etc/skel/.local/share/icons/
    fi

    # 2. Despliegue de los Wallpapers en la ruta nativa de fondos del sistema
    if [ -d "$DIR_TEMPORAL/Wallpapers" ]; then
        echo "Copiando Wallpapers a la ruta global del sistema /usr/share/backgrounds/..."
        mkdir -p /usr/share/backgrounds
        cp -r "$DIR_TEMPORAL/Wallpapers"/* /usr/share/backgrounds/
    fi
    
    echo "¡Assets globales copiados con éxito!"
else
    echo "Error crítico: No se pudo clonar el repositorio de assets."
    exit 1
fi

# Limpieza absoluta de rastros en la imagen
rm -rf "$DIR_TEMPORAL"
