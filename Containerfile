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

# 👇 SOLUCIÓN DE RAÍZ: Reinstala los repositorios oficiales dinámicos de Fedora en la imagen
RUN rpm -q fedora-repos || dnf install -y fedora-repos

### LINTING
## Verify final image and contents are correct.
RUN bootc container lint
