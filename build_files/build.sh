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
                    pkg = line_str[2:].split('#')[0].strip()
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


### 3. Descargar e instalar la ÚLTIMA versión de Starship Prompt a nivel global
echo "Descargando e instalando Starship Prompt en el sistema..."

DOMINIO_STARSHIP="https://starship.rs"
ARCHIVO_STARSHIP="install.sh"

URL_STARSHIP_LIMPIA=$(echo "${DOMINIO_STARSHIP} / ${ARCHIVO_STARSHIP}" | tr -d ' ')

# Tu método original de descarga
curl -sS "$URL_STARSHIP_LIMPIA" | sh -s -- -y --bin-dir "/usr/bin"


### 4. Descargar e instalar la ÚLTIMA versión de gSlapper (.rpm) desde GitHub
echo "Buscando e instalando la última release de gSlapper para Fedora..."

REPO="Nomadcxx/gSlapper"
PROTOCOLO="https://"
DOMINIO="://github.com"
RUTA="/repos/$REPO/releases/latest"

API_URL=$(echo "${PROTOCOLO}${DOMINIO}${RUTA}" | tr -d ' ')

# Tu método original de extracción por API
JSON_DATA=$(curl -s "$API_URL")
URL_RPM=$(echo "$JSON_DATA" | grep -oP '"browser_download_url"\s*:\s*"\K[^"]+' | grep '\.rpm$')

if [ -z "$URL_RPM" ]; then
    echo "Error: No se pudo encontrar un paquete .rpm en la última versión de gSlapper."
    exit 1
fi

ARCHIVO_RPM=$(basename "$URL_RPM")

curl -L -o "$ARCHIVO_RPM" "$URL_RPM"
dnf5 -y install "$ARCHIVO_RPM"
rm -f "$ARCHIVO_RPM"


### 5. Generar configuraciones estéticas premium globales (/etc/skel)
mkdir -p /etc/skel/.config/kitty
mkdir -p /etc/skel/.config/fish

cp /ctx/kitty.conf /etc/skel/.config/kitty/kitty.conf
cp /ctx/starship.toml /etc/skel/.config/starship.toml
cp /ctx/config.fish /etc/skel/.config/fish/config.fish

chmod -R 755 /etc/skel/.config


### 6. Instalar la tipografía oficial para los iconos de la consola
mkdir -p /usr/share/fonts/jetbrains-mono-nerd
echo "Descargando tipografía JetBrainsMono Nerd Font para los iconos..."

DOMINIO_FONTS="https://github.com"
REPOSITORIO_FONTS="ryanoasis / nerd-fonts / releases / latest / download"
ARCHIVO_FONTS="JetBrainsMono.tar.xz"

URL_FONTS_LIMPIA=$(echo "${DOMINIO_FONTS} / ${REPOSITORIO_FONTS} / ${ARCHIVO_FONTS}" | tr -d ' ')

curl -sSL "$URL_FONTS_LIMPIA" | tar -xJ -C /usr/share/fonts/jetbrains-mono-nerd/

fc-cache -f -v


# =====================================================================
# 6.5. Despliegue del Script Externo de Flatpaks y Servicio Systemd
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


### 7. Configurar el Shell y activar servicios de soporte (Compatible con Builds)
sed -i 's/SHELL=\/bin\/bash/SHELL=\/usr\/bin\/fish/g' /etc/default/useradd

mkdir -p /etc/systemd/system/sockets.target.wants
ln -sf /usr/lib/systemd/system/podman.socket /etc/systemd/system/sockets.target.wants/podman.socket
