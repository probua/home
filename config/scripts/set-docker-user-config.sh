#!/bin/bash

# Añade el usuario al grupo docker para usar docker sin sudo.
# Idempotente: no pide password si ya pertenece. No se usa `newgrp docker`
# porque abre un subshell interactivo y bloquearía la instalación; la
# membresía aplica en el siguiente login.

set_docker_user_config() {
  local user="${USER:-$(id -un)}"

  if ! getent group docker >/dev/null; then
    echo "set-docker-user-config: el grupo docker no existe (¿docker instalado?); omitido" >&2
    return 0
  fi

  if groups "$user" | grep -qw docker; then
    echo "set-docker-user-config: $user ya pertenece al grupo docker"
    return 0
  fi

  sudo usermod -aG docker "$user"
  echo "set-docker-user-config: $user añadido al grupo docker"
  echo "set-docker-user-config: cerrar y reabrir sesión (o ejecutar newgrp docker) para que aplique"
}

set_docker_user_config
