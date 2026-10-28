#!/bin/bash
set -ouex pipefail

# 1. Habilitar repositorio de Don
dnf5 copr enable theblackdon/kwee -y

# 2. Ejecutar Purga Masiva desde lista externa
rm -f /usr/share/applications/waydroid-* /etc/sddm.conf
PAQUETES_BORRAR=$(grep -v '^#' "/ctx/paquetes_a_borrar.txt" | grep -v '^$' | tr '\n' ' ')
[ -n "${PAQUETES_BORRAR// /}" ] && dnf5 -y remove $PAQUETES_BORRAR

# 3. Ejecutar Instalación Masiva desde lista externa
PAQUETES_INSTALAR=$(grep -v '^#' "/ctx/paquetes_a_instalar.txt" | grep -v '^$' | tr '\n' ' ')
[ -n "${PAQUETES_INSTALAR// /}" ] && dnf5 -y install $PAQUETES_INSTALAR

# 4. Invocar secuencialmente el resto de submódulos independientes
bash /ctx/instalar_herramientas.sh
bash /ctx/config_login.sh
bash /ctx/config_sistema.sh

# 5. Limpieza Absoluta para el linter de bootc
dnf5 clean all
rm -rf /var/cache/dnf /var/lib/dnf/repos /var/log/dnf*

###############################################################################
#             MEMORIA TÉCNICA DE DESPLIEGUE - KINETICOS / BAZZITE             #
# (Para lectura de IA en futuras sesiones de desarrollo y modificaciones)     #
###############################################################################
#
# CONTEXTO DEL ENTORNO DE COMPILACIÓN:
# - Imagen Base: ghcr.io/ublue-os/bazzite-nvidia-open:stable (Inmutable/Bootc)
# - Modelo de Compilación: Orquestado vía Containerfile sin persistencia intermedia.
# - Montaje Virtual: Toda la carpeta 'build_files/' se monta dinámicamente durante 
#   la build dentro del directorio raíz temporal '/ctx/' mediante un bind mount 
#   (--mount=type=bind). Nada de lo que hay en '/ctx/' se hereda en la ISO final.
#
# ARQUITECTURA MODULAR DEL PROYECTO:
# 1. 'paquetes_a_borrar.txt' -> Archivo plano con la purga masiva de paquetes de 
#    Bazzite/KDE Plasma (lista heredada y optimizada del spin oficial de Don).
# 2. 'paquetes_a_instalar.txt' -> Lista de dependencias del entorno KineticWE, 
#    utilizando Nemo + File-Roller (con extensiones de extracción gráfica) en 
#    lugar de Thunar, manteniendo gvfs para automontaje, red y papelera.
# 3. 'config_login.sh' -> Configuración estática del display manager 'greetd' en 
#    /etc/greetd/config.toml apuntando a 'noctalia-greeter-session'. Inicializa 
#    el tema Catppuccin mediante systemd-tmpfiles (zz-kineticos-greeter.conf) 
#    en /var y habilita el gestor forzando symlinks manuales (Build-Time safe).
# 4. 'instalar_herramientas.sh' -> Despliegue global de Starship Prompt, gSlapper 
#    (obteniendo dinámicamente el último .rpm vía GitHub API), inyección de 
#    perfiles estéticos premium en /etc/skel y aprovisionamiento de fuentes tipográficas.
# 5. 'config_sistema.sh' -> Cambios estructurales del OS: shell predeterminada a 
#    Fish, socket nativo de Podman y siembra de la unidad 'first-boot' de systemd 
#    para purgar Flatpaks de fábrica redundantes (Firefox, Okular, etc.) en el cliente.
#
# NOTAS PARA FUTURAS MODIFICACIONES:
# - CUALQUIER comando interactivo o que requiera 'systemctl enable' romperá la build.
# - Las activaciones de servicios deben hacerse inyectando enlaces simbólicos en /etc/systemd/...
# - Si se añaden o quitan apps de la ISO, modificar únicamente las listas .txt correspondientes.
###############################################################################
