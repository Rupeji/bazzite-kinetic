#!/bin/bash

set -ouex pipefail

### 1. Añadir el repositorio COPR de KineticWE y complementos
dnf5 copr enable theblackdon/kineticwe -y
dnf5 copr enable lionheartp/Hyprland -y

### 2. Instalar tu nuevo escritorio, tus apps y el motor estético nativo
dnf5 -y install \
    kineticwe \
    noctalia-git \
    kitty \
    nautilus \
    starship \
    fastfetch

### 3. Generar configuraciones estéticas premium globales (/etc/skel)
# Creamos los directorios en el esqueleto de futuros usuarios
mkdir -p /etc/skel/.config/kitty
mkdir -p /etc/skel/.config/fish

# Copiamos tus plantillas estéticas desde la carpeta compartida /ctx/
cp /ctx/kitty.conf /etc/skel/.config/kitty/kitty.conf
cp /ctx/starship.toml /etc/skel/.config/starship.toml
cp /ctx/config.fish /etc/skel/.config/fish/config.fish

# Aseguramos los permisos estándar para que el usuario pueda editarlos
chmod -R 755 /etc/skel/.config

### 4. Activar los servicios de soporte reales
# Habilitamos el socket de podman para tus contenedores
systemctl enable podman.socket

# 1. Crear el directorio global de fuentes del sistema
mkdir -p /usr/share/fonts/jetbrains-mono-nerd

# 2. Descargar la tipografía oficial JetBrainsMono Nerd Font (Versión Regular)
echo "Descargando tipografía JetBrainsMono Nerd Font para los iconos..."
curl -fLo /usr/share/fonts/jetbrains-mono-nerd/JetBrainsMonoNerdFont-Regular.ttf \
    https://github.com

# 3. Refrescar la caché de fuentes del sistema operativo
fc-cache -f -v
