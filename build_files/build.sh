#!/bin/bash

set -ouex pipefail

### 1. Añadir el repositorio COPR de KineticWE y complementos
dnf5 copr enable theblackdon/kwee -y
dnf5 -y remove plasma-workspace plasma-* kde-*


# =====================================================================
# 2. Scripts PRE-remoción y purga masiva desde removals.yaml
# =====================================================================
echo "Ejecutando limpiezas de archivos PRE-remoción..."
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


# =====================================================================
# 8. Programación del Asistente del Greeter (First Boot Config)
# =====================================================================
echo "Desplegando el script de configuración inicial para KineticWE Greeter..."

# Creamos el script nativo que se ejecutará en la máquina del usuario una sola vez
mkdir -p /usr/libexec
cat << 'EOF' > /usr/libexec/kineticwe-firstboot-greeter
#!/usr/bin/bash
set -eu

echo "[+] Iniciando configuración automatizada del Greeter..."

# 1. Asegurar que las rutas existan de forma física en el disco real
mkdir -p /etc/greetd

# 2. Escribir el archivo definitivo apuntando a Noctalia de forma limpia
cat << 'GEOF' > /etc/greetd/config.toml
[terminal]
vt = 1

[default_session]
command = "/usr/bin/noctalia-greeter-session"
user = "greeter"
GEOF

# 3. Crear el usuario del greeter con sus permisos multimedia si falta
if ! id "greeter" &>/dev/null; then
    useradd -M -r -s /sbin/nologin -d /var/lib/greetd -G video,input greeter || true
fi

# 4. Habilitar y arrancar greetd de forma nativa en caliente
systemctl enable --now greetd.service || true

echo "[+] Configuración del greeter finalizada con éxito."
EOF

chmod +x /usr/libexec/kineticwe-firstboot-greeter

# Creamos la unidad de Systemd de ejecución única (oneshot) antes del entorno gráfico
mkdir -p /usr/lib/systemd/system
cat << 'EOF' > /usr/lib/systemd/system/kineticwe-setup-greeter.service
[Unit]
Description=Configuracion inicial automatica de KineticWE Greeter
After=local-fs.target
Before=display-manager.service

[Service]
Type=oneshot
ExecStart=/usr/libexec/kineticwe-firstboot-greeter
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
EOF

# Habilitamos únicamente el servicio de configuración inicial de forma segura
mkdir -p /etc/systemd/system/multi-user.target.wants
ln -sf /usr/lib/systemd/system/kineticwe-setup-greeter.service /etc/systemd/system/multi-user.target.wants/kineticowe-setup-greeter.service
