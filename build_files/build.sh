#!/bin/bash

set -ouex pipefail

### 1. Añadir el repositorio COPR de KineticWE y complementos
dnf5 copr enable theblackdon/kwee -y
dnf5 -y remove plasma-workspace plasma-* kde-*

# =====================================================================
# 2. Ejecutar Purga Masiva desde el archivo .yaml (Sección "remove:")
# =====================================================================
# Eliminamos configuraciones conflictivas previas
rm -f /usr/share/applications/waydroid-* /etc/sddm.conf

# Ejecutamos el bloque de scripts "pre" definidos en tu YAML antes de borrar los paquetes
echo "Ejecutando scripts PRE-remoción..."
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
rm -f /etc/sddm.conf

# Extraemos la lista de paquetes debajo de "remove:" usando un parser rápido de Python
echo "Extrayendo paquetes a eliminar del archivo YAML..."
PAQUETES_BORRAR=$(python3 -c "
import sys
import yaml # Si no está el módulo yaml, usamos parsing de texto plano seguro
try:
    with open('/ctx/removals.yaml', 'r') as f:
        data = yaml.safe_load(f)
        print(' '.join(data.get('remove', [])))
except Exception:
    # Alternativa segura en texto plano por si la imagen base de la build no tiene PyYAML integrado
    with open('/ctx/removals.yaml', 'r') as f:
        in_remove = False
        pkgs = []
        for line in f:
            line_str = line.strip()
            if line_str.startswith('remove:'):
                in_remove = True
                continue
            elif in_remove and line_str.startswith('- '):
                pkgs.append(line_str.split('- ')[1].split('#')[0].strip())
            elif in_remove and line_str and not line_str.startswith('-') and not line_str.startswith('#'):
                break
        print(' '.join(pkgs))
")

# Procedemos a desinstalar todos los paquetes extraídos
if [ -n "${PAQUETES_BORRAR// /}" ]; then
    echo "Eliminando los siguientes paquetes: $PAQUETES_BORRAR"
    dnf5 -y remove $PAQUETES_BORRAR
fi

# =====================================================================
# 3. Ejecutar Instalación Masiva desde lista externa
# =====================================================================
PAQUETES_INSTALAR=$(grep -v '^#' "/ctx/paquetes_a_instalar.txt" | grep -v '^$' | tr '\n' ' ')
[ -n "${PAQUETES_INSTALAR// /}" ] && dnf5 -y install $PAQUETES_INSTALAR


### 2. Instalar tu nuevo escritorio y tus aplicaciones del sistema
#dnf5 -y install \
#    kineticwe \
#    kineticwe-greeter \
#    firefox \
#    spectacle \
#    kitty


### 3. Descargar e instalar la ÚLTIMA versión de Starship Prompt a nivel global
echo "Descargando e instalando Starship Prompt en el sistema..."

DOMINIO_STARSHIP="https://starship.rs"
ARCHIVO_STARSHIP="install.sh"

URL_STARSHIP_LIMPIA=$(echo "${DOMINIO_STARSHIP} / ${ARCHIVO_STARSHIP}" | tr -d ' ')

# Descarga el instalador oficial (este script detecta el latest release automáticamente)
curl -sS "$URL_STARSHIP_LIMPIA" | sh -s -- -y --bin-dir "/usr/bin"

### 4. Descargar e instalar la ÚLTIMA versión de gSlapper (.rpm) desde GitHub
echo "Buscando e instalando la última release de gSlapper para Fedora..."

REPO="Nomadcxx/gSlapper"
PROTOCOLO="https://"
DOMINIO="://github.com"
RUTA="/repos/$REPO/releases/latest"

API_URL=$(echo "${PROTOCOLO}${DOMINIO}${RUTA}" | tr -d ' ')

# 1. Obtener la información de la release y extraer el enlace .rpm de forma segura
JSON_DATA=$(curl -s "$API_URL")
URL_RPM=$(echo "$JSON_DATA" | grep -oP '"browser_download_url"\s*:\s*"\K[^"]+' | grep '\.rpm$')

# 2. Verificar si se encontró el paquete de Fedora de manera no interactiva para la build
if [ -z "$URL_RPM" ]; then
    echo "Error: No se pudo encontrar un paquete .rpm en la última versión de gSlapper."
    exit 1
fi

# Extraer el nombre del archivo de la URL
ARCHIVO_RPM=$(basename "$URL_RPM")

# 3. Descargar el paquete e instalarlo de forma nativa resolviendo dependencias
curl -L -o "$ARCHIVO_RPM" "$URL_RPM"
dnf5 -y install "$ARCHIVO_RPM"
rm -f "$ARCHIVO_RPM"

### 5. Generar configuraciones estéticas premium globales (/etc/skel)
mkdir -p /etc/skel/.config/kitty
mkdir -p /etc/skel/.config/fish

# Copiamos tus plantillas estéticas desde la carpeta compartida /ctx/
cp /ctx/kitty.conf /etc/skel/.config/kitty/kitty.conf
cp /ctx/starship.toml /etc/skel/.config/starship.toml
cp /ctx/config.fish /etc/skel/.config/fish/config.fish

# Aseguramos los permisos estándar para que el usuario pueda editarlos
chmod -R 755 /etc/skel/.config

### 6. Instalar la tipografía oficial para los iconos de la consola
mkdir -p /usr/share/fonts/jetbrains-mono-nerd
echo "Descargando tipografía JetBrainsMono Nerd Font para los iconos..."

DOMINIO_FONTS="https://github.com"
REPOSITORIO_FONTS="ryanoasis / nerd-fonts / releases / latest / download"
ARCHIVO_FONTS="JetBrainsMono.tar.xz"

URL_FONTS_LIMPIA=$(echo "${DOMINIO_FONTS} / ${REPOSITORIO_FONTS} / ${ARCHIVO_FONTS}" | tr -d ' ')

# Descargamos el archivo comprimido oficial (.tar.xz) y lo descomprimimos directamente en el directorio de fuentes
curl -sSL "$URL_FONTS_LIMPIA" | tar -xJ -C /usr/share/fonts/jetbrains-mono-nerd/

fc-cache -f -v

# =====================================================================
# 6.5. Inyectar scripts POST y Servicios de Primer Inicio (del YAML)
# =====================================================================
echo "Configurando servicios post-instalación de Flatpaks..."

# Creación del helper ejecutable para la limpieza de flatpaks en primer arranque
install -Dm0755 /dev/stdin /usr/libexec/kineticos-remove-flatpaks << 'EOF'
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

# Creación de la unidad de systemd para el primer arranque
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

# Habilitar el servicio de flatpaks para que se ejecute en el despliegue del sistema
mkdir -p /etc/systemd/system/multi-user.target.wants
ln -sf /usr/lib/systemd/system/kineticos-flatpak-removals.service /etc/systemd/system/multi-user.target.wants/kineticos-flatpak-removals.service


### 7. Configurar el Shell y activar servicios de soporte (Compatible con Builds)
# Forzar a que todos los nuevos usuarios tengan Fish por defecto en el sistema
sed -i 's/SHELL=\/bin\/bash/SHELL=\/usr\/bin\/fish/g' /etc/default/useradd

# Habilitar el socket de podman creando el enlace simbólico manualmente (Evita fallos en Build Time)
mkdir -p /etc/systemd/system/sockets.target.wants
ln -sf /usr/lib/systemd/system/podman.socket /etc/systemd/system/sockets.target.wants/podman.socket
