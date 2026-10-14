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
mkdir -p /etc/skel/.config/kitty
mkdir -p /etc/skel/.config/fish

# Copiamos tus plantillas estéticas desde la carpeta compartida /ctx/
cp /ctx/kitty.conf /etc/skel/.config/kitty/kitty.conf
cp /ctx/starship.toml /etc/skel/.config/starship.toml
cp /ctx/config.fish /etc/skel/.config/fish/config.fish

# Aseguramos los permisos estándar para que el usuario pueda editarlos
chmod -R 755 /etc/skel/.config

### 4. Instalar la tipografía para los iconos de la consola
mkdir -p /usr/share/fonts/jetbrains-mono-nerd
echo "Descargando tipografía JetBrainsMono Nerd Font para los iconos..."
curl -fLo /usr/share/fonts/jetbrains-mono-nerd/JetBrainsMonoNerdFont-Regular.ttf \
    https://github.com
fc-cache -f -v

### 5. Activar los servicios de soporte reales y configurar el Shell
# Forzar a que todos los nuevos usuarios tengan Fish por defecto en el sistema
sed -i 's/SHELL=\/bin\/bash/SHELL=\/usr\/bin\/fish/g' /etc/default/useradd

# Habilitamos el socket de podman para tus contenedores
systemctl enable podman.socket
