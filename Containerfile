# Allow build scripts to be referenced without being copied into the final image
FROM scratch AS ctx
COPY build_files /

# Base Image
FROM ghcr.io/ublue-os/bazzite-nvidia-open:stable

# Universal Blue Images: https://github.com/orgs/ublue-os/packages

#COPY services /usr/lib/systemd/user/

### MODIFICATIONS
## make modifications desired in your image and install packages by modifying the build.sh script
## the following RUN directive does all the things required to run "build.sh" as recommended.

# 👇 RECOGE EL TOKEN DESDE GITHUB ACTIONS Y LO PASA AL ENTORNO DEL SCRIPT
ARG GITHUB_TOKEN
ENV GITHUB_TOKEN=$GITHUB_TOKEN

# 🚀 BYPASS DE PERMISOS PARA LA WEB: Añadimos 'bash' delante del script
RUN --mount=type=bind,from=ctx,source=/,target=/ctx \
    --mount=type=cache,dst=/var/cache \
    --mount=type=cache,dst=/var/log \
    --mount=type=tmpfs,dst=/tmp \
    bash /ctx/build.sh && \
    rm -f /etc/yum.repos.d/terra-mesa.repo

# 🚀 PASO 2: INYECCIÓN DEFINITIVA DE REPOSITORIOS (MÉTODO ANTICORRUPCIÓN SEGURO)
RUN mkdir -p /etc/yum.repos.d && \
    URL_BASE_ESPACIOS="https://dl .fedoraproject .org /pub /fedora /linux /releases /45 /Everything /" && \
    URL_UPD_ESPACIOS="https://dl .fedoraproject .org /pub /fedora /linux /updates /45 /Everything /" && \
    URL_BASE_LIMPIA=$(echo "$URL_BASE_ESPACIOS" | tr -d ' ') && \
    URL_UPD_LIMPIA=$(echo "$URL_UPD_ESPACIOS" | tr -d ' ') && \
    echo '[fedora]' > /etc/yum.repos.d/fedora-dynamic-inject.repo && \
    echo 'name=Fedora 45 - $basearch' >> /etc/yum.repos.d/fedora-dynamic-inject.repo && \
    echo "baseurl=${URL_BASE_LIMPIA}\$basearch/os/" >> /etc/yum.repos.d/fedora-dynamic-inject.repo && \
    echo 'enabled=1' >> /etc/yum.repos.d/fedora-dynamic-inject.repo && \
    echo 'gpgcheck=0' >> /etc/yum.repos.d/fedora-dynamic-inject.repo && \
    echo -e '\n[updates]' >> /etc/yum.repos.d/fedora-dynamic-inject.repo && \
    echo 'name=Fedora 45 - Updates - $basearch' >> /etc/yum.repos.d/fedora-dynamic-inject.repo && \
    echo "baseurl=${URL_UPD_LIMPIA}\$basearch/" >> /etc/yum.repos.d/fedora-dynamic-inject.repo && \
    echo 'enabled=1' >> /etc/yum.repos.d/fedora-dynamic-inject.repo && \
    echo 'gpgcheck=0' >> /etc/yum.repos.d/fedora-dynamic-inject.repo

### LINTING
## Verify final image and contents are correct.
RUN bootc container lint
