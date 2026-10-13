#!/bin/bash

set -ouex pipefail

### 1. Añadir el repositorio COPR de KineticWE
dnf5 copr enable theblackdon/kineticwe -y
dnf5 copr enable lionheartp/Hyprland -y

### 2. Eliminar por completo el entorno KDE Plasma
dnf5 -y remove kwin kwin-common kwin-libs kglobalacceld kdecoration
#dnf5 -y remove plasma-workspace plasma-* kde-*

### 3. Instalar tu nuevo escritorio y tus apps no-desarrollador
dnf5 -y install \
    kineticwe \
    noctalia-git \
    kitty \
    nautilus

### 4. Activar los servicios de soporte reales
# Habilitamos el socket de podman para tus contenedores
systemctl enable podman.socket
