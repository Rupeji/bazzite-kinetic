#!/bin/bash
set -ouex pipefail

echo "=== INICIANDO CONFIGURACIÓN MODULAR DEL LOGIN ==="

# 1. Crear la estructura y la configuración de greetd apuntando a Noctalia
mkdir -p /etc/greetd
cat << 'EOF' > /etc/greetd/config.toml
[terminal]
vt = 1

[default_session]
command = "noctalia-greeter-session"
user = "greeter"
EOF

# 2. Asegurar los privilegios del usuario del sistema encargado del login gráfico
usermod -aG video,render greeter || true

# 3. Crear el archivo de plantilla tmpfiles de Don para regenerar la estética Catppuccin
mkdir -p /usr/lib/tmpfiles.d
install -Dm0644 /dev/stdin /usr/lib/tmpfiles.d/zz-kineticos-greeter.conf << 'EOF'
# KineticOS: seed the Catppuccin greeter default on first boot.
C /var/lib/noctalia-greeter/greeter.toml 0644 greetd greetd - /usr/share/kineticos/greeter.toml
EOF

# 4. Enlazar el servicio manualmente (Equivalente estático a systemctl enable)
rm -f /etc/systemd/system/display-manager.service
mkdir -p /etc/systemd/system/display-manager.service.wants
ln -sf /usr/lib/systemd/system/greetd.service /etc/systemd/system/display-manager.service

echo "=== CONFIGURACIÓN DEL LOGIN COMPLETADA CON ÉXITO ==="
