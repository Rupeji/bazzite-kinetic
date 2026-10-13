#!/bin/bash

set -ouex pipefail

### 1. Añadir el repositorio COPR de KineticWE
dnf5 copr enable theblackdon/kineticwe -y
dnf5 copr enable lionheartp/Hyprland -y

### 2. Eliminar por completo el entorno KDE Plasma
dnf5 -y remove plasma-workspace plasma-* kde-*

### 3. Instalar tu nuevo escritorio y tus apps no-desarrollador
dnf5 -y install \
    kineticwe \
    noctalia-shell \
    alacritty \
    nautilus

### 4. Activar los servicios necesarios
systemctl enable podman.socket
systemctl --global add-wants kineticwe.service upowerd.service
