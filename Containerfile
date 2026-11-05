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

# ⚠️ SE HA ELIMINADO EL COMANDO 'ostree container commit' AL FINAL DE ESTA DIRECTIVA
RUN --mount=type=bind,from=ctx,source=/,target=/ctx \
    --mount=type=cache,dst=/var/cache \
    --mount=type=cache,dst=/var/log \
    --mount=type=tmpfs,dst=/tmp \
    /ctx/build.sh && \
    rm -f /etc/yum.repos.d/terra-mesa.repo

# 🚀 INYECCIÓN NATIVA COMPATIBLE CON BOOTC EN GITHUB ACTIONS:
# Descarga y extrae los archivos .repo oficiales en espacio de usuario sin invocar rpm-ostree
RUN mkdir -p /tmp/repos && \
    curl -L -o /tmp/repos/fedora-repos.rpm https://fedoraproject.org && \
    cd /tmp/repos && rpm2cpio fedora-repos.rpm | cpio -idmv ./etc/yum.repos.d/* && \
    cp -r ./etc/yum.repos.d/* /etc/yum.repos.d/ && \
    rm -rf /tmp/repos

### LINTING
## Verify final image and contents are correct.
RUN bootc container lint
