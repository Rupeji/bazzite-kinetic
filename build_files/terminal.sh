#!/usr/bin/env bash
set -ouex pipefail

# =====================================================================
# 1. Descargar e instalar la ÚLTIMA versión de Starship Prompt
# =====================================================================
echo "Descargando e instalando Starship Prompt en el sistema de forma directa..."

# 🌟 Usamos una URL directa e inmutable al binario precompilado para saltarnos el script interactivo
URL_STARSHIP_BINARIA="https://github.com/starship/starship/releases/latest/download/starship-x86_64-unknown-linux-musl.tar.gz"

# Descargamos el tarball directamente en el directorio temporal
curl -sSL -o /tmp/starship.tar.gz "$URL_STARSHIP_BINARIA"

# Descomprimimos el ejecutable directamente dentro de la ruta del sistema
tar -xzf /tmp/starship.tar.gz -C /usr/bin/

# Aplicamos los permisos necesarios y limpiamos los archivos residuales
chmod 755 /usr/bin/starship
rm -f /tmp/starship.tar.gz

echo "¡Starship Prompt instalado con éxito!"

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
    
    # 1. Asegurar la creación de todos los directorios destino en el esqueleto de usuario
    mkdir -p /etc/skel/.config/kitty
    mkdir -p /etc/skel/.config/fish
    mkdir -p /etc/skel/.config/kineticwe
    mkdir -p /etc/skel/.config/niri
    mkdir -p /etc/skel/.config/noctalia-kwe
    mkdir -p /etc/skel/.config/gtk-3.0
    mkdir -p /etc/skel/.config/gtk-4.0
    mkdir -p /etc/skel/.config/qt5ct
    mkdir -p /etc/skel/.config/qt6ct

    # 2. Despliegue quirúrgico de las configuraciones desde sus subcarpetas organizadas
    if [ -f "$DIR_DOTFILES_ORIGEN/kitty/kitty.conf" ]; then
        echo " -> Inyectando dotfiles de Kitty..."
        cp "$DIR_DOTFILES_ORIGEN/kitty/kitty.conf" /etc/skel/.config/kitty/kitty.conf
    fi

    if [ -f "$DIR_DOTFILES_ORIGEN/fish/config.fish" ]; then
        echo " -> Inyectando dotfiles de Fish..."
        cp "$DIR_DOTFILES_ORIGEN/fish/config.fish" /etc/skel/.config/fish/config.fish
    fi

    # Inyección directa en la raíz de .config/ para que Starship funcione por defecto
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

    # --- NUEVAS CARPETAS DETECTADAS EN TU REPOSITORIO ---
    if [ -d "$DIR_DOTFILES_ORIGEN/gtk-3.0" ]; then
        echo " -> Copiando toda la estructura interna de GTK 3.0..."
        cp -r "$DIR_DOTFILES_ORIGEN/gtk-3.0"/* /etc/skel/.config/gtk-3.0/ 2>/dev/null || true
    fi

    if [ -d "$DIR_DOTFILES_ORIGEN/gtk-4.0" ]; then
        echo " -> Copiando toda la estructura interna de GTK 4.0..."
        cp -r "$DIR_DOTFILES_ORIGEN/gtk-4.0"/* /etc/skel/.config/gtk-4.0/ 2>/dev/null || true
    fi

    if [ -d "$DIR_DOTFILES_ORIGEN/qt5ct" ]; then
        echo " -> Copiando toda la estructura interna de QT5ct..."
        cp -r "$DIR_DOTFILES_ORIGEN/qt5ct"/* /etc/skel/.config/qt5ct/ 2>/dev/null || true
    fi

    if [ -d "$DIR_DOTFILES_ORIGEN/qt6ct" ]; then
        echo " -> Copiando toda la estructura interna de QT6ct..."
        cp -r "$DIR_DOTFILES_ORIGEN/qt6ct"/* /etc/skel/.config/qt6ct/ 2>/dev/null || true
    fi

    # Forzar los permisos correctos para el entorno personal del usuario
    chmod -R 755 /etc/skel/.config
    echo "¡Dotfiles del esqueleto de usuario desplegados con éxito!"
fi

# =====================================================================
# Mapeo del Esquema de Color personalizado en el esqueleto
# =====================================================================
echo "Comprobando la presencia de la carpeta de esquemas de color..."

if [ -d "$DIR_DOTFILES_ORIGEN/color-schemes" ]; then
    echo "¡Carpeta color-schemes detectada! Preparando el directorio en /etc/skel..."
    
    # 1. Asegurar la creación de la ruta completa dentro del esqueleto
    mkdir -p /etc/skel/.local/share/color-schemes

    # 2. Copiar todo el contenido de la carpeta de origen al esqueleto
    echo " -> Inyectando esquemas de color..."
    cp -r "$DIR_DOTFILES_ORIGEN/color-schemes"/* /etc/skel/.local/share/color-schemes/ 2>/dev/null || true

    # 3. Forzar los permisos correctos para que el usuario pueda leerlos
    chmod -R 755 /etc/skel/.local
    echo "¡Esquemas de color desplegados con éxito!"
fi

# =====================================================================
# 4. Instalar la tipografía oficial para los iconos de la consola
# =====================================================================
mkdir -p /usr/share/fonts/jetbrains-mono-nerd
echo "Descargando tipografía JetBrainsMono Nerd Font para los iconos..."

# Definimos las URLs con espacios para evitar cualquier tipo de recorte
URL_REGULAR_ESPACIOS="https://github .com /ryanoasis /nerd-fonts /raw /master /patched-fonts /JetBrainsMono /Ligatures /Regular /JetBrainsMonoNerdFont-Regular .ttf"
URL_BOLD_ESPACIOS="https://github .com /ryanoasis /nerd-fonts /raw /master /patched-fonts /JetBrainsMono /Ligatures /Bold /JetBrainsMonoNerdFont-Bold .ttf"

# Limpiamos los espacios dinámicamente antes de lanzar el comando curl
URL_REGULAR_LIMPIA=$(echo "$URL_REGULAR_ESPACIOS" | tr -d ' ')
URL_BOLD_LIMPIA=$(echo "$URL_BOLD_ESPACIOS" | tr -d ' ')

# Descarga directa de los archivos binarios TTF parcheados oficiales
curl -sSL -o /usr/share/fonts/jetbrains-mono-nerd/JetBrainsMonoNerdFont-Regular.ttf "$URL_REGULAR_LIMPIA"
curl -sSL -o /usr/share/fonts/jetbrains-mono-nerd/JetBrainsMonoNerdFont-Bold.ttf "$URL_BOLD_LIMPIA"

# Asegurar los permisos de lectura correctos del sistema
chmod 644 /usr/share/fonts/jetbrains-mono-nerd/*.ttf

# Actualizar la caché de fuentes del sistema de la ISO
fc-cache -f -v
echo "¡Tipografías inyectadas y caché actualizada con éxito!"

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
# 6. Descarga e Inyección de Recursos Globales en Pictures (Iconos y Wallpapers)
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

    # Aseguramos la creación de la ruta Pictures dentro del esqueleto
    mkdir -p /etc/skel/Pictures
    mkdir -p /etc/skel/.config/noctalia/activos

    # Despliegue de la carpeta completa de Wallpapers dentro de Pictures
    if [ -d "$DIR_TEMPORAL/Wallpapers" ]; then
        echo "Copiando carpeta Wallpapers a la ruta Pictures del esqueleto..."
        cp -r "$DIR_TEMPORAL/Wallpapers" /etc/skel/Pictures/
    fi

    # Despliegue de la carpeta completa de Iconos dentro de Pictures
    if [ -d "$DIR_TEMPORAL/Iconos" ]; then
        echo "Copiando carpeta Iconos a la ruta Pictures del esqueleto..."
        cp -r "$DIR_TEMPORAL/Iconos" /etc/skel/Pictures/
        
        # Inyectar también el logotipo personalizado del dock en su ruta de configuración
        echo "Inyectando logotipo personalizado del dock..."
        cp "$DIR_TEMPORAL/Iconos/Bazzite_Logo.png" /etc/skel/.config/noctalia/activos/ 2>/dev/null || true
    fi
    
    # Ajustamos permisos finales para asegurar que el usuario tenga acceso total
    chmod -R 755 /etc/skel/Pictures
    echo "¡Carpetas de assets copiadas con éxito a Pictures en el esqueleto!"
else
    echo "Error crítico: No se pudo clonar el repositorio de assets."
    exit 1
fi

rm -rf "$DIR_TEMPORAL"
echo "¡Entorno estético de terminal e iconos globales desplegado con éxito!"
