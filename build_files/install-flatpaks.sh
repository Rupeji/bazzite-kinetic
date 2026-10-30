#!/bin/bash

# Asegurar que el repositorio de Flathub esté habilitado en el sistema
flatpak remote-add --if-not-exists flathub https://flathub.org

# Instalar los paquetes Flatpaks deseados de forma silenciosa
echo "Instalando Flatpaks personalizados del sistema..."
flatpak install flathub com.discordapp.Discord -y
flatpak install flathub com.bambulab.BambuStudio -y
flatpak install flathub com.github.vikoadi.ProtonPlus -y
flatpak install flathub net.davidotek.pupgui2 -y
