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
