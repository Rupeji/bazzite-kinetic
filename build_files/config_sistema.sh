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

# 5. REPARACIÓN AUTOMÁTICA DEL GESTOR GRÁFICO (Solución al os error 13)
# Crear el usuario oculto greeter de forma segura si no fue creado por la base
if ! id "greeter" &>/dev/null; then
  useradd -r -M -d /var/lib/greetd -s /sbin/nologin greeter || true
fi

# Forzar la regeneración de grupos y asegurar los accesos de hardware para Noctalia
mkdir -p /etc/sysusers.d
echo "g video - -" | tee /etc/sysusers.d/video.conf >/dev/null
echo "g input - -" | tee /etc/sysusers.d/input.conf >/dev/null
systemd-sysusers || true
usermod -aG video,input greeter || true

# BLINDAJE DE PERMISOS ABSOLUTO: Crear las rutas de configuración y dar paso total al greeter
mkdir -p /var/lib/greetd/.config/glow
chmod -R 777 /var/lib/greetd
chown -R greeter:greeter /var/lib/greetd || true

# Desactivar las restricciones de SELinux sobre el demonio de Greetd para evitar el os error 13
if [ -d /etc/selinux ]; then
  mkdir -p /etc/systemd/system/greetd.service.d
  printf '[Service]\nSecurityProfile=unconfined\n' | tee /etc/systemd/system/greetd.service.d/override.conf >/dev/null
fi

# 6. CONFIGURACIÓN REGIONAL EN LA RAÍZ (Teclado e idioma en español de fábrica)
echo "KEYMAP=es" | tee /etc/vconsole.conf >/dev/null
echo "LANG=es_ES.UTF-8" | tee /etc/locale.conf >/dev/null

# 7. ENLACE DIRECTO DE SESIÓN (Rompemos el bucle de login definitivo)
# En lugar de usar sed directo que da error de apertura, usamos tee para parchear el config.toml si existe
if [ -f /etc/greetd/config.toml ]; then
  sed 's/command = .*/command = "noctalia-greeter-session"/g' /etc/greetd/config.toml | tee /etc/greetd/config.toml.tmp >/dev/null
  mv -f /etc/greetd/config.toml.tmp /etc/greetd/config.toml || true
fi

# Limpieza de seguridad de archivos de sesión huérfanos que puedan provocar bucles
rm -f /etc/skel/.wayland-session


# 8. RECONSTRUCCIÓN FORZADA DE SESIÓN WAYLAND (Jaque Mate al Bucle de Login)
mkdir -p /usr/share/wayland-sessions

# Creamos a mano el lanzador oficial con la RUTA ABSOLUTA definitiva
cat << 'EOF' | tee /usr/share/wayland-sessions/kineticwe.desktop >/dev/null
[Desktop Entry]
Name=KineticWE
Comment=KineticWE Compositor with Noctalia Shell
Exec=/usr/bin/start-kineticwe
Type=Application
DesktopNames=KineticWE
EOF

chmod 644 /usr/share/wayland-sessions/kineticwe.desktop

# Forzar a greetd a que su sesión por defecto sea explícitamente el cargador de Don
if [ -f /etc/greetd/config.toml ]; then
  sed 's/command = .*/command = "noctalia-greeter-session"/g' /etc/greetd/config.toml | tee /etc/greetd/config.toml.tmp >/dev/null
  mv -f /etc/greetd/config.toml.tmp /etc/greetd/config.toml || true
fi

echo "=== CONFIGURACIÓN DEL SISTEMA COMPLETADA CON ÉXITO ==="
