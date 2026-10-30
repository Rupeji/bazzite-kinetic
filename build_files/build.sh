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

# =====================================================================
# 7. Configuración del Greeter Seguro (Estilo gregOS / KineticWE)
# =====================================================================
echo "Desplegando archivo declarativo de sysusers para los grupos..."
mkdir -p /usr/lib/sysusers.d
cp /ctx/gregos-niri.conf /usr/lib/sysusers.d/gregos-niri.conf
chmod 644 /usr/lib/sysusers.d/gregos-niri.conf

# NOTA: systemd-sysusers y usermod NO se ejecutan aquí. 
# El sistema se encargará de materializar de forma nativa al usuario 'greeter' 
# durante el primer arranque real gracias a gregos-niri.conf.

echo "Desplegando el Render Wrapper de seguridad para la gráfica..."
mkdir -p /usr/libexec/gregos
cp /ctx/noctalia-greeter-render /usr/libexec/gregos/noctalia-greeter-render
chmod +x /usr/libexec/gregos/noctalia-greeter-render

echo "Configurando de forma estática greetd..."
mkdir -p /etc/greetd
cp /ctx/config.toml /etc/greetd/config.toml
chmod 644 /etc/greetd/config.toml

echo "Gestionando servicios de forma estática (Evitando systemctl disable/enable en el build)..."
# 1. Creamos la ruta de los targets del sistema para multi-usuario si no existe
mkdir -p /usr/lib/systemd/system/multi-user.target.wants

# 2. Desactivamos SDDM borrando su enlace simbólico si existiera en la imagen base
rm -f /usr/lib/systemd/system/display-manager.service
rm -f /usr/lib/systemd/system/multi-user.target.wants/sddm.service

# 3. Activamos Greetd enlazándolo directamente al inicio del sistema
ln -sf /usr/lib/systemd/system/greetd.service /usr/lib/systemd/system/display-manager.service
ln -sf /usr/lib/systemd/system/greetd.service /usr/lib/systemd/system/multi-user.target.wants/greetd.service

echo "Configuración del Greeter finalizada de forma estática."
