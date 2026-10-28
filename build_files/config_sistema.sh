#!/bin/bash
# Forzamos el modo búnker anti-errores en la cabecera
set -ouex pipefail

echo "=== INICIANDO CONFIGURACIÓN MODULAR DEL SISTEMA ==="

# 1. PARCHE DE REPOSITORIOS (El secreto de Don)
# Activamos Terra y Terra-Extras para que DNF encuentre las dependencias de KineticWE
if [ -f /etc/yum.repos.d/terra.repo ]; then
  sed -i 's/enabled=0/enabled=1/g' /etc/yum.repos.d/terra.repo
fi

if [ -f /etc/yum.repos.d/terra-extras.repo ]; then
  sed -i 's/enabled=0/enabled=1/g' /etc/yum.repos.d/terra-extras.repo
fi

# Desactivamos terra-mesa para que el constructor de la ISO no choque contra su firma GPG local
if [ -f /etc/yum.repos.d/terra-mesa.repo ]; then
  sed -i 's/^enabled=1$/enabled=0/' /etc/yum.repos.d/terra-mesa.repo
fi


# 2. CONFIGURACIÓN ESTRUCTURAL DE SHELL Y CONTAINERS
# Forzar a que todos los nuevos usuarios tengan Fish por defecto en el sistema
sed -i 's/SHELL=\/bin\/bash/SHELL=\/usr\/bin\/fish/g' /etc/default/useradd

# Habilitar el socket de podman creando el enlace simbólico manualmente (Evita fallos en Build Time)
mkdir -p /etc/systemd/system/sockets.target.wants
ln -sf /usr/lib/systemd/system/podman.socket /etc/systemd/system/sockets.target.wants/podman.socket


# 3. MANTENIMIENTO Y SERVICIOS FIRST-BOOT
# Inyectar el servicio First-Boot para desinstalar Flatpaks heredados de fábrica de Bazzite
mkdir -p /usr/libexec
cat << 'EOF' > /usr/libexec/kineticos-remove-flatpaks
#!/usr/bin/bash
set -u
install -d /var/lib/kineticos
stamp=/var/lib/kineticos/flatpak-removals.done
touch "$stamp"
for app in \
    io.github.DenysMb.Kontainer \
    com.github.Matoking.protontricks \
    org.kde.kcalc \
    org.kde.okular \
    org.mozilla.firefox \
    org.kde.haruna \
    org.kde.gwenview \
    io.github.flattool.Warehouse \
    com.github.tchx84.Flatseal \
    org.gnome.Firmware
do
    grep -qxF "$app" "$stamp" && continue
    flatpak uninstall -y --system --noninteractive "$app" >/dev/null 2>&1 || true
    echo "$app" >> "$stamp"
done
EOF
chmod 755 /usr/libexec/kineticos-remove-flatpaks

# Crear y habilitar de forma estática la unidad systemd para la limpieza tardía de flatpaks
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


# 4. PROTECCIÓN ANTI-PÁNICO DE ARRANQUE (Evita el cuelgue en la VM)
# Borramos los enlaces de los servicios del overlay persistente que no tenemos sembrados
rm -f /etc/systemd/system/multi-user.target.wants/kineticos-overlay-mount.service
rm -f /etc/systemd/system/multi-user.target.wants/kineticos-overlay-sync.service

echo "=== CONFIGURACIÓN DEL SISTEMA COMPLETADA CON ÉXITO ==="
