#!/usr/bin/env bash

set -ouex pipefail

# =====================================================================
# 1. Añadir el repositorio COPR de KineticWE y complementos
# =====================================================================
dnf5 copr enable theblackdon/kwee -y

# 👇 LA CLAVE: Forzar a DNF5 a descargar la lista de paquetes nueva del COPR
dnf5 clean all
dnf5 makecache

# Continuar con la purga de KDE nativo
dnf5 -y remove plasma-workspace plasma-* kde-*

# =====================================================================
# 2. Purga completa de Homebrew (Específico para Bazzite/Ublue)
# =====================================================================
echo "==> Purgando por completo el ecosistema de Homebrew..."

# Desactivar servicios
systemctl disable brew-setup.service brew-update.timer brew-upgrade.timer

# Borrado de directorios y archivos base
rm -rf /var/home/linuxbrew
rm -f /usr/share/homebrew.tar.zst

# Archivos de systemd
rm -f /usr/lib/systemd/system/brew-*
rm -f /usr/lib/systemd/system-preset/01-homebrew.preset

# Integración de terminal (Bash y Fish)
rm -f /etc/profile.d/brew*
rm -f /usr/share/fish/vendor_conf.d/ublue-brew.fish
rm -f /usr/share/fish/completions/brew.fish

# Helpers visuales y accesos de Ublue/Bazzite
rm -f /usr/share/applications/bbrew.desktop
rm -f /usr/bin/bbrew-helper
rm -f /usr/share/ublue-os/bbrew.png
rm -rf /usr/share/ublue-os/homebrew
rm -f /usr/share/ublue-os/announcements/sunshine-brew.msg.json

# Límites de seguridad
rm -f /etc/security/limits.d/30-brew-limits.conf
rm -f /usr/etc/security/limits.d/30-brew-limits.conf

echo "==> Ecosistema de Homebrew purgado."
# =====================================================================
# 2.1. Scripts PRE-borradon y purga masiva desde removals.yaml
# =====================================================================
echo "Ejecutando limpiezas de archivos PRE-borrado..."
rm -f /usr/share/applications/waydroid-* /etc/sddm.conf
rm -f /usr/share/applications/waydroid-container-restart.desktop
rm -f /usr/libexec/waydroid-container-restart \
      /usr/libexec/waydroid-container-start \
      /usr/libexec/waydroid-container-stop \
      /usr/libexec/waydroid-fix-controllers
rm -rf /usr/share/applications/Waydroid
rm -f /usr/share/applications/discourse.desktop
rm -f /usr/share/applications/bazzite-documentation.desktop
rm -f /usr/share/applications/system-update.desktop
rm -rf /etc/sddm.conf.d

echo "Extrayendo paquetes a eliminar de removals.yaml..."
PAQUETES_BORRAR=$(python3 -c "
import sys
pkgs = []
try:
    with open('/ctx/removals.yaml', 'r') as f:
        in_remove = False
        for line in f:
            line_str = line.strip()
            if line_str.startswith('remove:'):
                in_remove = True
                continue
            if in_remove:
                if line_str.startswith('- '):
                    raw_pkg = line_str[2:]
                    clean_pkg = raw_pkg.split('#')[0]
                    pkg = clean_pkg.strip()
                    if pkg:
                        pkgs.append(pkg)
                elif line_str and not line_str.startswith('#') and not line_str.startswith('-'):
                    break
    print(' '.join(pkgs))
except Exception as e:
    sys.exit(1)
")

if [ -n "${PAQUETES_BORRAR// /}" ]; then
    echo "Eliminando paquetes detectados: $PAQUETES_BORRAR"
    dnf5 -y remove $PAQUETES_BORRAR
fi


# =====================================================================
# 3. Ejecutar Instalación Masiva desde lista externa
# =====================================================================
PAQUETES_INSTALAR=$(grep -v '^#' "/ctx/paquetes_a_instalar.txt" | grep -v '^$' | tr '\n' ' ')
if [ -n "${PAQUETES_INSTALAR// /}" ]; then
    dnf5 -y install --allow-downgrade --allowerasing $PAQUETES_INSTALAR
fi


# =====================================================================
# 4. Entorno de Terminal Completo (Módulos terminal, prompts, fuentes)
# =====================================================================
echo "Ejecutando configuración completa de la terminal y fuentes..."
bash /ctx/terminal.sh


# =====================================================================
# 5.1 Despliegue del Script Externo de Instalación de Flatpaks
# =====================================================================
echo "Desplegando servicio e instalando script helper de instalación de Flatpaks..."
cp /ctx/install-flatpaks.sh /usr/libexec/kineticos-install-flatpaks
chmod +x /usr/libexec/kineticos-install-flatpaks

cat << 'EOF' > /usr/lib/systemd/system/kineticos-flatpak-installations.service
[Unit]
Description=Instalar Flatpaks del sistema declarados por el usuario
After=network-online.target
Wants=network-online.target
ConditionPathExists=/usr/bin/flatpak

[Service]
Type=oneshot
ExecStart=/usr/libexec/kineticos-install-flatpaks
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
EOF

ln -sf /usr/lib/systemd/system/kineticos-flatpak-installations.service /etc/systemd/system/multi-user.target.wants/kineticos-flatpak-installations.service


# =====================================================================
# 6. Configurar el Shell y activar servicios de soporte (Compatible con Builds)
# =====================================================================
sed -i 's/SHELL=\/bin\/bash/SHELL=\/usr\/bin\/fish/g' /etc/default/useradd

mkdir -p /etc/systemd/system/sockets.target.wants
ln -sf /usr/lib/systemd/system/podman.socket /etc/systemd/system/sockets.target.wants/podman.socket

# 🚀 REGISTRAR LA ASOCIACIÓN NATIVA DE NEMO CON KITTY (GSCHEMA OVERRIDE)
echo "Registrando asociación de Nemo con Kitty en los esquemas globales de GLib..."

mkdir -p /usr/share/glib-2.0/schemas/

cat << 'EOF' > /usr/share/glib-2.0/schemas/99-nemo-kitty.gschema.override
[org.cinnamon.desktop.default-applications.terminal]
exec='kitty'
EOF

# Compilar los esquemas para que el sistema reconozca el cambio inmediatamente en el primer inicio
glib-compile-schemas /usr/share/glib-2.0/schemas/

# =====================================================================
# Configuración del Hostname del Sistema
# =====================================================================
echo "Estableciendo el hostname predeterminado del sistema..."
echo "bazzite" > /etc/hostname
chmod 644 /etc/hostname

# =====================================================================
# 7. Configuración del Greeter Seguro (Estilo Nativo de Fedora)
# =====================================================================
echo "Desplegando parche de tmpfiles y SELinux para greetd..."
mkdir -p /usr/lib/tmpfiles.d
cp /ctx/bazzite-kinetic-tmpfiles.conf /usr/lib/tmpfiles.d/bazzite-kinetic-tmpfiles.conf
chmod 644 /usr/lib/tmpfiles.d/bazzite-kinetic-tmpfiles.conf

echo "Configurando de forma estática el archivo de greetd..."
mkdir -p /etc/greetd
cp /ctx/config.toml /etc/greetd/config.toml
chmod 644 /etc/greetd/config.toml

echo "Aplicando directivas de contexto SELinux sobre el almacenamiento..."
semanage fcontext -a -t xdm_var_lib_t '/var/lib/noctalia-greeter(/.*)?' || true

echo "Apagando el gestor nativo de Bazzite y activando greetd..."
systemctl disable sddm.service || true
systemctl enable greetd.service
systemctl set-default graphical.target
