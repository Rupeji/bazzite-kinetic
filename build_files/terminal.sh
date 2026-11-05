#!/usr/bin/env bash
set -ouex pipefail

# =====================================================================
# 1. Descargar e instalar la ÚLTIMA versión de Starship Prompt
# =====================================================================
echo "Descargando e instalando Starship Prompt en el sistema..."

DOMINIO_STARSHIP="https://starship.rs"
ARCHIVO_STARSHIP="install.sh"
URL_STARSHIP_LIMPIA=$(echo "${DOMINIO_STARSHIP}/${ARCHIVO_STARSHIP}" | tr -d ' ')

curl -sS "$URL_STARSHIP_LIMPIA" | sh -s -- -y --bin-dir "/usr/bin"


# =====================================================================
# 2. Descargar e instalar la ÚLTIMA versión de gSlapper (.rpm)
# =====================================================================
echo "Buscando e instalando la última release de gSlapper para Fedora..."

BASE_API="https://api.github.com"
RUTA_API="/repos/Nomadcxx/gSlapper/releases/latest"
API_URL=$(echo "${BASE_API}${RUTA_API}" | tr -d ' ')

if [ -n "${GITHUB_TOKEN:-}" ]; then
    echo "Usando GITHUB_TOKEN para autenticar la petición a la API..."
    JSON_DATA=$(curl -s -H "Authorization: Bearer $GITHUB_TOKEN" "$API_URL")
else
    echo "Aviso: GITHUB_TOKEN no detectado, haciendo petición pública..."
    JSON_DATA=$(curl -s "$API_URL")
fi

URL_RPM=$(echo "$JSON_DATA" | grep -oP '"browser_download_url"\s*:\s*"\K[^"]+' | grep '\.rpm$')

if [ -z "$URL_RPM" ]; then
    echo "Error: No se pudo encontrar un paquete .rpm en la última versión de gSlapper."
    echo "Contenido devuelto por la API: $JSON_DATA"
    exit 1
fi

ARCHIVO_RPM=$(basename "$URL_RPM")
curl -L -o "$ARCHIVO_RPM" "$URL_RPM"
dnf5 -y install "$ARCHIVO_RPM"
rm -f "$ARCHIVO_RPM"


# =====================================================================
# 3. Mapeo Estético Global de Dotfiles (Estructura Organizada)
# =====================================================================
echo "Comprobando la presencia de la carpeta Dotfiles por carpetas..."

DIR_DOTFILES_ORIGEN="/ctx/dotfiles"

if [ -d "$DIR_DOTFILES_ORIGEN" ]; then
    echo "¡Carpeta Dotfiles detectada! Iniciando inyección organizada en /etc/skel..."
    
    # 1. Asegurar la creación de todos los directorios en el esqueleto de usuario
    mkdir -p /etc/skel/.config/kitty
    mkdir -p /etc/skel/.config/fish
    mkdir -p /etc/skel/.config/kineticwe
    mkdir -p /etc/skel/.config/niri
    mkdir -p /etc/skel/.config/noctalia-kwe

    # 2. Despliegue quirúrgico de las configuraciones desde sus subcarpetas organizadas
    if [ -f "$DIR_DOTFILES_ORIGEN/kitty/kitty.conf" ]; then
        echo " -> Inyectando dotfiles de Kitty..."
        cp "$DIR_DOTFILES_ORIGEN/kitty/kitty.conf" /etc/skel/.config/kitty/kitty.conf
    fi

    if [ -f "$DIR_DOTFILES_ORIGEN/fish/config.fish" ]; then
        echo " -> Inyectando dotfiles de Fish..."
        cp "$DIR_DOTFILES_ORIGEN/fish/config.fish" /etc/skel/.config/fish/config.fish
    fi

    if [ -f "$DIR_DOTFILES_ORIGEN/starship/starship.toml" ]; then
        echo " -> Inyectando dotfiles de Starship..."
        cp "$DIR_DOTFILES_ORIGEN/starship/starship.toml" /etc/skel/.config/starship.toml
    fi

    if [ -d "$DIR_DOTFILES_ORIGEN/kineticwe" ]; then
        echo " -> Copiando toda la estructura interna de KineticWE..."
        cp -r "$DIR_DOTFILES_ORIGEN/kineticwe"/* /etc/skel/.config/kineticwe/ 2>/dev/null || true
    fi

    if [ -d "$DIR_DOTFILES_ORIGEN/niri" ]; then
        echo " -> Copiando toda la estructura interna de Niri..."
        cp -r "$DIR_DOTFILES_ORIGEN/niri"/* /etc/skel/.config/niri/ 2>/dev/null || true
    fi

    if [ -d "$DIR_DOTFILES_ORIGEN/noctalia-kwe" ]; then
        echo " -> Copiando toda la estructura interna de Noctalia-KWE..."
        cp -r "$DIR_DOTFILES_ORIGEN/noctalia-kwe"/* /etc/skel/.config/noctalia-kwe/ 2>/dev/null || true
    fi

    # 3. Salvaguarda masiva (Copia cualquier otro archivo o subcarpeta suelta que metas en un futuro)
    cp -r "$DIR_DOTFILES_ORIGEN"/* /etc/skel/.config/ 2>/dev/null || true
    
    # Limpieza de duplicados accidentales por la copia masiva del esqueleto
    rm -rf /etc/skel/.config/kitty/kitty /etc/skel/.config/fish/fish /etc/skel/.config/starship \
           /etc/skel/.config/kineticwe/kineticwe /etc/skel/.config/niri/niri /etc/skel/.config/noctalia-kwe/noctalia-kwe 2>/dev/null || true

    # Forzar los permisos correctos para el entorno personal del usuario
    chmod -R 755 /etc/skel/.config
    echo "¡Dotfiles del esqueleto de usuario desplegados con éxito!"
else
    echo "Aviso: Carpeta 'dotfiles' no encontrada. Aplicando plantillas de emergencia básicas..."
    mkdir -p /etc/skel/.config/kitty /etc/skel/.config/fish
    [ -f /ctx/kitty.conf ] && cp /ctx/kitty.conf /etc/skel/.config/kitty/kitty.conf
    [ -f /ctx/starship.toml ] && cp /ctx/starship.toml /etc/skel/.config/starship.toml
    [ -f /ctx/config.fish ] && cp /ctx/config.fish /etc/skel/.config/fish/config.fish
    chmod -R 755 /etc/skel/.config
fi

# =====================================================================
# 4. Instalar la tipografía oficial para los iconos de la consola
# =====================================================================
mkdir -p /usr/share/fonts/jetbrains-mono-nerd
echo "Descargando tipografía JetBrainsMono Nerd Font para los iconos..."

DOMINIO_FONTS="https://github.com"
REPOSITORIO_FONTS="ryanoasis/nerd-fonts/releases/latest/download"
ARCHIVO_FONTS="JetBrainsMono.tar.xz"
URL_FONTS_LIMPIA=$(echo "${DOMINIO_FONTS}/${REPOSITORIO_FONTS}/${ARCHIVO_FONTS}" | tr -d ' ')

curl -sSL "$URL_FONTS_LIMPIA" | tar -xJ -C /usr/share/fonts/jetbrains-mono-nerd/
fc-cache -f -v


# =====================================================================
# 5. Instalación de Temas Visuales Globales (Tela Icon y Bibata Cursors)
# =====================================================================
echo "Iniciando la instalación de Temas Visuales del sistema (Tela y Bibata)..."
mkdir -p /usr/share/icons

# 5.1. Instalación Global de Iconos Tela
echo "Descargando e instalando la última versión de Tela Icon Theme..."
rm -rf /tmp/Tela-icon-theme

URL_TELA_CON_ESPACIOS="https://github .com /vinceliuice /Tela-icon-theme .git"
URL_TELA=$(echo "$URL_TELA_CON_ESPACIOS" | tr -d ' ')

git clone --depth 1 "$URL_TELA" /tmp/Tela-icon-theme

if [ -f /tmp/Tela-icon-theme/install.sh ]; then
    chmod +x /tmp/Tela-icon-theme/install.sh
    /tmp/Tela-icon-theme/install.sh -d "/usr/share/icons"
fi
rm -rf /tmp/Tela-icon-theme

# 5.2. Instalación Global de Cursores Bibata Modern
echo "Descargando e instalando la última versión de Cursores Bibata..."
rm -f /tmp/Bibata-Modern-Classic.tar.xz /tmp/Bibata-Modern-Ice.tar.xz

URL_CLASSIC_CON_ESPACIOS="https://github .com /ful1e5 /Bibata_Cursor /releases /download /v2.0.7 /Bibata-Modern-Classic .tar .xz"
URL_ICE_CON_ESPACIOS="https://github .com /ful1e5 /Bibata_Cursor /releases /download /v2.0.7 /Bibata-Modern-Ice .tar .xz"

URL_CLASSIC=$(echo "$URL_CLASSIC_CON_ESPACIOS" | tr -d ' ')
URL_ICE=$(echo "$URL_ICE_CON_ESPACIOS" | tr -d ' ')

curl -L "$URL_CLASSIC" -o /tmp/Bibata-Modern-Classic.tar.xz
curl -L "$URL_ICE" -o /tmp/Bibata-Modern-Ice.tar.xz

if [ -s /tmp/Bibata-Modern-Classic.tar.xz ] && [ -s /tmp/Bibata-Modern-Ice.tar.xz ]; then
    tar -xf /tmp/Bibata-Modern-Classic.tar.xz -C "/usr/share/icons/"
    tar -xf /tmp/Bibata-Modern-Ice.tar.xz -C "/usr/share/icons/"
fi
rm -f /tmp/Bibata-Modern-Classic.tar.xz /tmp/Bibata-Modern-Ice.tar.xz


# =====================================================================
# 6. Descarga e Inyección de Recursos Globales (Iconos y Wallpapers)
# =====================================================================
echo "Conectando con GitHub para descargar tu repositorio IconsWalls..."

DIR_TEMPORAL="/tmp/git_iconswalls_backup"
rm -rf "$DIR_TEMPORAL"

# 🚀 TRUCO ANTICORRUPCIÓN SEGURO: Mapeo de tu repositorio de activos sin cortes
URL_ASSETS_ESPACIOS="https://github .com /Rupeji /IconsWalls"
URL_ASSETS_LIMPIA=$(echo "$URL_ASSETS_ESPACIOS" | tr -d ' ')

echo "Clonando repositorio superficialmente (IconsWalls)..."
if git clone --depth 1 "$URL_ASSETS_LIMPIA" "$DIR_TEMPORAL"; then
    echo "Repositorio clonado correctamente."

    # Crear directorios en el esqueleto base del usuario
    mkdir -p /etc/skel/Imágenes
    mkdir -p /etc/skel/Pictures
    mkdir -p /etc/skel/.local/share/icons
    mkdir -p /etc/skel/.config/noctalia/activos

    # Despliegue de los Wallpapers en ambas variantes de carpetas de fotos de usuario
    if [ -d "$DIR_TEMPORAL/Wallpapers" ]; then
        echo "Copiando Wallpapers al esqueleto de usuario..."
        cp -r "$DIR_TEMPORAL/Wallpapers"/* /etc/skel/Imágenes/ 2>/dev/null || true
        cp -r "$DIR_TEMPORAL/Wallpapers"/* /etc/skel/Pictures/ 2>/dev/null || true
    fi

    # Despliegue de los iconos a la ruta local estándar oculta para que el sistema los detecte
    if [ -d "$DIR_TEMPORAL/Iconos" ]; then
        echo "Copiando Iconos al esqueleto de usuario..."
        cp -r "$DIR_TEMPORAL/Iconos"/* /etc/skel/.local/share/icons/ 2>/dev/null || true
        
        # Inyectar también el logotipo personalizado del dock en el esqueleto
        echo "Inyectando logotipo personalizado del dock..."
        cp "$DIR_TEMPORAL/Iconos/Bazzite_Logo.png" /etc/skel/.config/noctalia/activos/ 2>/dev/null || true
    fi
    
    echo "¡Assets globales copiados con éxito al esqueleto!"
else
    echo "Error crítico: No se pudo clonar el repositorio de assets."
    exit 1
fi

rm -rf "$DIR_TEMPORAL"
echo "¡Entorno estético de terminal e iconos globales desplegado con éxito!"
