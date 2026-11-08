#!/usr/bin/env bash
set -ouex pipefail

# =====================================================================
# 1. Instalar Starship Prompt desde los archivos locales
# =====================================================================
echo "Inyectando Starship Prompt de forma local en el sistema..."

# Copiamos directamente el binario desde la carpeta compartida /ctx
cp /ctx/recursos/starship /usr/bin/starship

# Aplicamos los permisos necesarios de ejecución
chmod 755 /usr/bin/starship

echo "¡Starship Prompt inyectado con éxito!"

# =====================================================================
# Instalar gSlapper de forma local (Blindado contra fallos de red)
# =====================================================================
echo "Inyectando paquete gSlapper desde los archivos locales..."

# Definimos el nombre exacto del archivo RPM local
ARCHIVO_GSLAPPER_RPM="gslapper-1.5.3-1.fedora42.x86_64.rpm"

# Verificamos si existe en tu carpeta compartida /ctx/recursos/
if [ -f "/ctx/recursos/$ARCHIVO_GSLAPPER_RPM" ]; then
    echo " -> Instalando paquete local $ARCHIVO_GSLAPPER_RPM mediante dnf5..."
    dnf5 -y install "/ctx/recursos/$ARCHIVO_GSLAPPER_RPM"
else
    echo "Error crítico: No se encontró $ARCHIVO_GSLAPPER_RPM en /ctx/recursos/"
    exit 1
fi

echo "¡gSlapper instalado con éxito de manera local!"

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
# 4. Instalar fuentes locales estables
# =====================================================================
echo "Inyectando tipografías JetBrainsMono Nerd Font desde recursos locales..."
mkdir -p /usr/share/fonts/jetbrains-mono-nerd

if [ -f "/ctx/recursos/JetBrainsMonoNerdFont-Regular.ttf" ]; then
    cp /ctx/recursos/JetBrainsMonoNerdFont-Regular.ttf /usr/share/fonts/jetbrains-mono-nerd/
    cp /ctx/recursos/JetBrainsMonoNerdFont-Bold.ttf /usr/share/fonts/jetbrains-mono-nerd/
    chmod 644 /usr/share/fonts/jetbrains-mono-nerd/*.ttf
    fc-cache -f -v
    echo "¡Tipografías locales aplicadas con éxito!"
else
    echo "Aviso: No se encontraron fuentes en /ctx/recursos/, saltando paso."
fi
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

# =====================================================================
# Instalar Cursores Bibata desde los archivos locales
# =====================================================================
echo "Inyectando cursores Bibata de forma local en el sistema..."
mkdir -p /usr/share/icons/

# 1. Descomprimir Classic directamente desde el almacenamiento compartida local
if [ -f "/ctx/recursos/Bibata-Modern-Classic.tar.xz" ]; then
    echo " -> Descomprimiendo Bibata Modern Classic..."
    tar -xf /ctx/recursos/Bibata-Modern-Classic.tar.xz -C /usr/share/icons/
else
    echo "Error crítico: No se encontró Bibata-Modern-Classic.tar.xz en /ctx/recursos/"
    exit 1
fi

# 2. Descomprimir Ice directamente desde el almacenamiento compartida local
if [ -f "/ctx/recursos/Bibata-Modern-Ice.tar.xz" ]; then
    echo " -> Descomprimiendo Bibata Modern Ice..."
    tar -xf /ctx/recursos/Bibata-Modern-Ice.tar.xz -C /usr/share/icons/
else
    echo "Error crítico: No se encontró Bibata-Modern-Ice.tar.xz en /ctx/recursos/"
    exit 1
fi

# Asegurar permisos correctos para que el sistema y el usuario puedan usarlos
chmod -R 755 /usr/share/icons/Bibata-Modern-*
echo "¡Cursores inyectados correctamente!"

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
