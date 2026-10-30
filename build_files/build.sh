#!/bin/bash

set -ouex pipefail

### 1. Añadir el repositorio COPR de KineticWE y complementos
dnf5 copr enable theblackdon/kwee -y
dnf5 -y remove plasma-workspace plasma-* kde-*


# =====================================================================
# 2. Scripts PRE-borradon y purga masiva desde removals.yaml
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
[ -n "${PAQUETES_INSTALAR// /}" ] && dnf5 -y install $PAQUETES_INSTALAR


# =====================================================================
# 4. Entorno de Terminal Completo (Módulos terminal, prompts, fuentes)
# =====================================================================
echo "Ejecutando configuración completa de la terminal y fuentes..."
bash /ctx/terminal.sh


# =====================================================================
# 5. Despliegue del Script Externo de Flatpaks y Servicio Systemd
# =====================================================================
echo "Desplegando servicio e instalando script helper de Flatpaks..."
cp /ctx/clean-flatpaks.sh /usr/libexec/kineticos-remove-flatpaks
chmod +x /usr/libexec/kineticos-remove-flatpaks

mkdir -p /usr/lib/systemd/system
cat << 'EOF' > /usr/lib/systemd/system/kineticos-flatpak-removals.service
[Unit]
Description=Remove unwanted Bazzite system Flatpaks (once per app)
ConditionPathExists=/usr/bin/flatpak

[Service]
Type=oneshot
ExecStart=/usr/libexec/kineticos-remove-flatpaks
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
EOF

mkdir -p /etc/systemd/system/multi-user.target.wants
ln -sf /usr/lib/systemd/system/kineticos-flatpak-removals.service /etc/systemd/system/multi-user.target.wants/kineticos-flatpak-removals.service


# =====================================================================
# 6. Configurar el Shell y activar servicios de soporte (Compatible con Builds)
# =====================================================================
sed -i 's/SHELL=\/bin\/bash/SHELL=\/usr\/bin\/fish/g' /etc/default/useradd

mkdir -p /etc/systemd/system/sockets.target.wants
ln -sf /usr/lib/systemd/system/podman.socket /etc/systemd/system/sockets.target.wants/podman.socket
