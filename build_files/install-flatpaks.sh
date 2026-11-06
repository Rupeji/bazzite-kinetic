#!/bin/bash

# Ruta del archivo flag para controlar que solo se ejecute una vez
FLAG_FILE="/var/.kineticos-flatpaks-installed"

# Si el archivo flag ya existe, salir inmediatamente sin hacer nada
if [ -f "$FLAG_FILE" ]; then
    echo "Los Flatpaks ya fueron instalados en el primer arranque. Omitiendo..."
    exit 0
fi

# Asegurar que el repositorio de Flathub esté habilitado a nivel de sistema
flatpak remote-add --system --if-not-exists flathub https://flathub.org

# Instalar los paquetes Flatpaks deseados de forma silenciosa e ininterrumpida
echo "Instalando Flatpaks personalizados del sistema por primera vez..."
flatpak install flathub com.discordapp.Discord -y --system --noninteractive
flatpak install flathub com.bambulab.BambuStudio -y --system --noninteractive
flatpak install flathub net.davidotek.pupgui2 -y --system --noninteractive

# =========================================================================
# SOLUCIÓN DE DEPENDENCIAS DINÁMICAS (Se ejecuta solo una vez aquí dentro)
# =========================================================================
echo "Resolviendo dependencias y runtimes necesarios de forma automática..."
# 1. Escanea las apps recién instaladas y descarga cualquier runtime que les falte
flatpak repair --system --noninteractive
# 2. Asegura que los runtimes descargados estén en la última versión compatible
flatpak update -y --system --noninteractive
# =========================================================================

# Si todo el proceso fue exitoso, crear el archivo flag
if [ $? -eq 0 ]; then
    mkdir -p "$(dirname "$FLAG_FILE")"
    touch "$FLAG_FILE"
    echo "Instalación y dependencias completadas correctamente. Flag creado."
else
    echo "Hubo un error en la instalación. Se reintentará en el próximo arranque."
    exit 1
fi
