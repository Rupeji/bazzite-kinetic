#!/bin/bash

set -ouex pipefail

### 1. Añadir el repositorio COPR de KineticWE y complementos
dnf5 copr enable theblackdon/kineticwe -y
dnf5 copr enable lionheartp/Hyprland -y

### 2. Instalar tu nuevo escritorio y tus aplicaciones del sistema
# Quitamos fastfetch y starship de aquí para evitar fallos de DNF
dnf5 -y install \
    kineticwe \
    noctalia-git \
    kitty

### 3. Descargar e instalar la ÚLTIMA versión de Starship Prompt a nivel global
echo "Descargando e instalando Starship Prompt en el sistema..."

DOMINIO_STARSHIP="https://starship.rs"
ARCHIVO_STARSHIP="install.sh"

URL_STARSHIP_LIMPIA=$(echo "${DOMINIO_STARSHIP} / ${ARCHIVO_STARSHIP}" | tr -d ' ')

# Descarga el instalador oficial (este script detecta el latest release automáticamente)
curl -sS "$URL_STARSHIP_LIMPIA" | sh -s -- -y --bin-dir "/usr/bin"

### 4. Generar configuraciones estéticas premium globales (/etc/skel)
mkdir -p /etc/skel/.config/kitty
mkdir -p /etc/skel/.config/fish

# Copiamos tus plantillas estéticas desde la carpeta compartida /ctx/
cp /ctx/kitty.conf /etc/skel/.config/kitty/kitty.conf
cp /ctx/starship.toml /etc/skel/.config/starship.toml
cp /ctx/config.fish /etc/skel/.config/fish/config.fish

# Aseguramos los permisos estándar para que el usuario pueda editarlos
chmod -R 755 /etc/skel/.config

### 5. Instalar la tipografía oficial para los iconos de la consola
mkdir -p /usr/share/fonts/jetbrains-mono-nerd
echo "Descargando tipografía JetBrainsMono Nerd Font para los iconos..."

# URL estructurada con espacios usando los servidores de release de GitHub (Evita el error 404)
DOMINIO_FONTS="https://github.com"
REPOSITORIO_FONTS="ryanoasis / nerd-fonts / releases / latest / download"
ARCHIVO_FONTS="JetBrainsMono.tar.xz"

URL_FONTS_LIMPIA=$(echo "${DOMINIO_FONTS} / ${REPOSITORIO_FONTS} / ${ARCHIVO_FONTS}" | tr -d ' ')

# Descargamos el archivo comprimido oficial (.tar.xz) y lo descomprimimos directamente en el directorio de fuentes
curl -sSL "$URL_FONTS_LIMPIA" | tar -xJ -C /usr/share/fonts/jetbrains-mono-nerd/

fc-cache -f -v

### 6. Configurar el Shell y activar servicios de soporte (Compatible con Builds)
# Forzar a que todos los nuevos usuarios tengan Fish por defecto en el sistema
sed -i 's/SHELL=\/bin\/bash/SHELL=\/usr\/bin\/fish/g' /etc/default/useradd

# Habilitar el socket de podman creando el enlace simbólico manualmente (Evita fallos en Build Time)
mkdir -p /etc/systemd/system/sockets.target.wants
ln -sf /usr/lib/systemd/system/podman.socket /etc/systemd/system/sockets.target.wants/podman.socket
