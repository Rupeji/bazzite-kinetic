#!/bin/bash

set -ouex pipefail

### 1. Añadir el repositorio COPR de KineticWE y complementos
dnf5 copr enable linuxgamerlife/lgl-experimental -y
dnf5 -y remove plasma-workspace plasma-* kde-*

### 2. Instalar tu nuevo escritorio y tus aplicaciones del sistema
dnf5 -y install \
    kineticwe \
    kineticwe-greeter \
    noctalia-greeter \
    greetd \
    thunar \
    gvfs \
    kitty




### 4.5 Configurar y habilitar Noctalia Greeter de forma global
echo "Configurando Noctalia Greeter con greetd..."

# Crear el directorio de configuración del gestor de entrada
mkdir -p /etc/greetd

# Generar el archivo de configuración asignando Noctalia Greeter por defecto
cat <<EOF > /etc/greetd/config.toml
[default_session]
command = "noctalia-greeter --cmd start-kineticwe"
user = "greeter"
EOF

# Habilitar el servicio del sistema para que inicie en el arranque
systemctl enable greetd.service


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
DOMINIO="api.github.com"
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

### 7. Configurar el Shell y activar servicios de soporte (Compatible con Builds)
# Forzar a que todos los nuevos usuarios tengan Fish por defecto en el sistema
sed -i 's/SHELL=\/bin\/bash/SHELL=\/usr\/bin\/fish/g' /etc/default/useradd

# Habilitar el socket de podman creando el enlace simbólico manualmente (Evita fallos en Build Time)
mkdir -p /etc/systemd/system/sockets.target.wants
ln -sf /usr/lib/systemd/system/podman.socket /etc/systemd/system/sockets.target.wants/podman.socket
