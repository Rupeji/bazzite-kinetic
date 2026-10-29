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
# Parseador de texto ultra-seguro en Python sin dependencias externas
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
                    # Extraer el paquete quitando el '- ' y cualquier comentario posterior '#'
                    pkg = line_str[2:].split('#')[0].strip()
                    if pkg:
                        pkgs.append(pkg)
                elif line_str and not line_str.startswith('#') and not line_str.startswith('-'):
                    # Si encontramos otra sección principal, dejamos de leer
                    break
    print(' '.join(pkgs))
except Exception as e:
    print(f'Error leyendo YAML: {e}', file=sys.stderr)
    sys.exit(1)
")

if [ -n "${PAQUETES_BORRAR// /}" ]; then
    echo "Eliminando paquetes detectados: $PAQUETES_BORRAR"
    dnf5 -y remove $PAQUETES_BORRAR
else
    echo "Aviso: No se detectaron paquetes para eliminar en removals.yaml"
fi

# =====================================================================
# 3. Ejecutar Instalación Masiva desde lista externa
# =====================================================================
PAQUETES_INSTALAR=$(grep -v '^#' "/ctx/paquetes_a_instalar.txt" | grep -v '^$' | tr '\n' ' ')
[ -n "${PAQUETES_INSTALAR// /}" ] && dnf5 -y install $PAQUETES_INSTALAR

### 3. Descargar e instalar la ÚLTIMA versión de Starship Prompt a nivel global
echo "Instalando Starship Prompt..."
curl -sS https://starship.rs | sh -s -- -y --bin-dir "/usr/bin"

### 4. Descargar e instalar gSlapper (Blindado contra fallos de API)
echo "Buscando gSlapper..."
REPO="Nomadcxx/gSlapper"
API_URL="https://github.com{REPO}/releases/latest"

JSON_DATA=$(curl -s "$API_URL" || echo "")
URL_RPM=$(echo "$JSON_DATA" | grep -oP '"browser_download_url"\s*:\s*"\K[^"]+' | grep '\.rpm$' | head -n 1 || echo "")

# Fallback estratégico: Si la API falló por rate limit, deducimos la URL de descarga directa estimada
if [ -z "$URL_RPM" ]; then
    echo "Aviso: API de GitHub inaccesible (Rate Limit). Usando fallback de descarga directa..."
    URL_RPM="https://github.com{REPO}/releases/latest/download/gSlapper.rpm"
fi

echo "Descargando e Proteins e instalando RPM desde: $URL_RPM"
if curl -L -f -o "gSlapper.rpm" "$URL_RPM"; then
    dnf5 -y install "gSlapper.rpm"
    rm -f "gSlapper.rpm"
else
    echo "Error crítico: No se pudo descargar el paquete gSlapper."
    exit 1
fi

### 5. Generar configuraciones estéticas globales (/etc/skel)
mkdir -p /etc/skel/.config/kitty /etc/skel/.config/fish
cp /ctx/kitty.conf /etc/skel/.config/kitty/kitty.conf
cp /ctx/starship.toml /etc/skel/.config/starship.toml
cp /ctx/config.fish /etc/skel/.config/fish/config.fish
chmod -R 755 /etc/skel/.config

### 6. Instalar JetBrainsMono Nerd Font
mkdir -p /usr/share/fonts/jetbrains-mono-nerd
curl -sSL "https://github.com" | tar -xJ -C /usr/share/fonts/jetbrains-mono-nerd/
fc-cache -f -v

# =====================================================================
# 6.5. Despliegue del Script Externo de Flatpaks y Servicio Systemd
# =====================================================================
echo "Desplegando servicio e instalando script helper de Flatpaks..."
cp /ctx/clean-flatpaks.sh /usr/libexec/kineticos-remove-flatpaks
chmod +x /usr/libexec/kineticos-remove-flatpaks

# Creamos la unidad del servicio directamente
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

# Lo habilitamos en el despliegue
mkdir -p /etc/systemd/system/multi-user.target.wants
ln -sf /usr/lib/systemd/system/kineticos-flatpak-removals.service /etc/systemd/system/multi-user.target.wants/kineticos-flatpak-removals.service

### 7. Configurar el Shell y activar servicios de soporte
sed -i 's/SHELL=\/bin\/bash/SHELL=\/usr\/bin\/fish/g' /etc/default/useradd
mkdir -p /etc/systemd/system/sockets.target.wants
ln -sf /usr/lib/systemd/system/podman.socket /etc/systemd/system/sockets.target.wants/podman.socket
