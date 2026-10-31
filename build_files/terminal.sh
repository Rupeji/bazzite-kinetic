#!/bin/bash
set -ouex pipefail

### 1. Descargar e instalar la ÚLTIMA versión de Starship Prompt a nivel global
echo "Descargando e instalando Starship Prompt en el sistema..."

DOMINIO_STARSHIP="https://starship.rs"
ARCHIVO_STARSHIP="install.sh"

URL_STARSHIP_LIMPIA=$(echo "${DOMINIO_STARSHIP} / ${ARCHIVO_STARSHIP}" | tr -d ' ')

curl -sS "$URL_STARSHIP_LIMPIA" | sh -s -- -y --bin-dir "/usr/bin"


# =====================================================================
# 2. Descargar e instalar la ÚLTIMA versión de gSlapper (.rpm) desde GitHub
# =====================================================================
echo "Buscando e instalando la última release de gSlapper para Fedora..."

REPO="Nomadcxx/gSlapper"
BASE_API="https://api.github.com"
RUTA_API="/repos/$REPO/releases/latest"

# Usamos tu truco de espacios infalible con las variables de la API correctas
API_URL=$(echo "${BASE_API} ${RUTA_API}" | tr -d ' ')

# Obtener la información de la release usando el token si está disponible para evitar el Rate Limit
if [ -n "$GITHUB_TOKEN" ]; then
    echo "Usando GITHUB_TOKEN para autenticar la petición a la API..."
    JSON_DATA=$(curl -s -H "Authorization: Bearer $GITHUB_TOKEN" "$API_URL")
else
    echo "Aviso: GITHUB_TOKEN no detectado, haciendo petición pública..."
    JSON_DATA=$(curl -s "$API_URL")
fi

# Extraer el enlace .rpm de forma segura
URL_RPM=$(echo "$JSON_DATA" | grep -oP '"browser_download_url"\s*:\s*"\K[^"]+' | grep '\.rpm$')

if [ -z "$URL_RPM" ]; then
    echo "Error: No se pudo encontrar un paquete .rpm en la última versión de gSlapper."
    echo "Respuesta de la API recibida: $JSON_DATA"
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

    # 1. Despliegue de los Iconos en la plantilla editable del usuario (~/Pictures)
    if [ -d "$DIR_TEMPORAL/Iconos" ]; then
        echo "Copiando Iconos a la plantilla editable /etc/skel/Pictures/Iconos/..."
        mkdir -p /etc/skel/Pictures/Iconos
        cp -r "$DIR_TEMPORAL/Iconos"/* /etc/skel/Pictures/Iconos/
    fi

    # 2. Despliegue de los Wallpapers en el directorio editable del usuario (~/Pictures)
    if [ -d "$DIR_TEMPORAL/Wallpapers" ]; then
        echo "Copiando Wallpapers a la plantilla editable /etc/skel/Pictures/Wallpapers/..."
        mkdir -p /etc/skel/Pictures/Wallpapers
        cp -r "$DIR_TEMPORAL/Wallpapers"/* /etc/skel/Pictures/Wallpapers/
    fi
    
    echo "¡Assets globales copiados con éxito!"
else
    echo "Error crítico: No se pudo clonar el repositorio de assets."
    exit 1
fi

# Limpieza absoluta de rastros en la imagen
rm -rf "$DIR_TEMPORAL"

# =====================================================================
# 6. Instalación de Temas Visuales Globales (Tela Icon y Bibata Cursors)
# =====================================================================
echo "Iniciando la instalación de Temas Visuales del sistema (Tela y Bibata)..."

# Asegurar la ruta global nativa de iconos y cursores para el sistema operativo
mkdir -p /usr/share/icons

# ---------------------------------------------------------------------
# 6.1. Instalación Global de Iconos Tela
# ---------------------------------------------------------------------
echo "Descargando e instalando la última versión de Tela Icon Theme..."
rm -rf /tmp/Tela-icon-theme

URL_TELA_CON_ESPACIOS="https:// github.com / vinceliuice / Tela-icon-theme .git"
URL_TELA="${URL_TELA_CON_ESPACIOS// /}"

git clone "$URL_TELA" /tmp/Tela-icon-theme

# Ejecutamos el instalador oficial apuntando al directorio global /usr/share/icons
if [ -f /tmp/Tela-icon-theme/install.sh ]; then
    chmod +x /tmp/Tela-icon-theme/install.sh
    /tmp/Tela-icon-theme/install.sh -d "/usr/share/icons"
else
    echo "Error: No se pudo descargar el instalador de iconos Tela."
    exit 1
fi

rm -rf /tmp/Tela-icon-theme


# ---------------------------------------------------------------------
# 6.2. Instalación Global de Cursores Bibata Modern
# ---------------------------------------------------------------------
echo "Descargando e instalando la última versión de Cursores Bibata..."
rm -f /tmp/Bibata-Modern-Classic.tar.xz /tmp/Bibata-Modern-Ice.tar.xz

URL_CLASSIC_CON_ESPACIOS="https:// github.com / ful1e5 / Bibata_Cursor / releases / download / v2.0.7 / Bibata-Modern-Classic.tar.xz"
URL_ICE_CON_ESPACIOS="https:// github.com / ful1e5 / Bibata_Cursor / releases / download / v2.0.7 / Bibata-Modern-Ice.tar.xz"

URL_CLASSIC="${URL_CLASSIC_CON_ESPACIOS// /}"
URL_ICE="${URL_ICE_CON_ESPACIOS// /}"

curl -L "$URL_CLASSIC" -o /tmp/Bibata-Modern-Classic.tar.xz
curl -L "$URL_ICE" -o /tmp/Bibata-Modern-Ice.tar.xz

# Descomprimimos directamente en la ruta global de iconos del sistema (/usr/share/icons/)
if [ -s /tmp/Bibata-Modern-Classic.tar.xz ] && [ -s /tmp/Bibata-Modern-Ice.tar.xz ]; then
    tar -xf /tmp/Bibata-Modern-Classic.tar.xz -C "/usr/share/icons/"
    tar -xf /tmp/Bibata-Modern-Ice.tar.xz -C "/usr/share/icons/"
    echo "Cursores Bibata desempaquetados correctamente a nivel global."
else
    echo "Error: Los archivos de cursores descargados están corruptos o vacíos."
    exit 1
fi

rm -f /tmp/Bibata-Modern-Classic.tar.xz /tmp/Bibata-Modern-Ice.tar.xz
echo "¡Proceso de instalación estética finalizado con éxito!"
