#!/bin/bash

# Ruta del archivo flag para controlar que solo se ejecute una vez
FLAG_FILE="/var/.kineticos-flatpaks-installed"

# Si el archivo flag ya existe, salir inmediatamente sin hacer nada
if [ -f "$FLAG_FILE" ]; then
    echo "Los Flatpaks ya fueron instalados en el primer arranque. Omitiendo..."
    exit 0
fi

# Asegurar que el repositorio de Flathub esté habilitado
flatpak remote-add --if-not-exists flathub https://flathub.org

# Instalar los paquetes Flatpaks deseados de forma silenciosa
echo "Instalando Flatpaks personalizados del sistema por primera vez..."
flatpak install flathub com.discordapp.Discord -y
flatpak install flathub com.bambulab.BambuStudio -y
flatpak install flathub com.github.vikoadi.ProtonPlus -y
flatpak install flathub net.davidotek.pupgui2 -y

# Si la instalación fue exitosa, crear el archivo flag
if [ $? -eq 0 ]; then
    mkdir -p "$(dirname "$FLAG_FILE")"
    touch "$FLAG_FILE"
    echo "Instalación completada correctamente. Flag creado."
else
    echo "Hubo un error en la instalación. Se reintentará en el próximo arranque."
    exit 1
fi
