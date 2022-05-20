<h1 align="center">
    <br>
    <a href="https://linuxgsm.com"><img src="https://i.imgur.com/Eoh1jsi.jpg" alt="LinuxGSM"></a>Contenedor Docker LinuxGSM
</h1>

[English](README.md) | [Español](README_ES.md)

[LinuxGSM](https://linuxgsm.com) es la herramienta de línea de comandos para la implantación y gestión rápida y sencilla de servidores de juegos dedicados a Linux.

> Este contenedor docker está en desarrollo, está sujeto a cambios significativos y no se considera estable.

Una versión dockerizada de [LinuxGSM](https://linuxgsm.com)

Dockerhub https://hub.docker.com/r/gameservermanagers/linuxgsm-docker/

# Uso

## docker-compose
A continuación se muestra un ejemplo de `docker-compose` para csgoserver. Los puertos variarán según el servidor.

```
version: '3.4'
services:
  linuxgsm:
    image: "ghcr.io/gameservermanagers/linuxgsm-docker:latest"
    container_name: csgoserver
    environment:
      - GAMESERVER=csgoserver
      - LGSM_GITHUBUSER=GameServerManagers
      - LGSM_GITHUBREPO=LinuxGSM
      - LGSM_GITHUBBRANCH=master
    volumes:
      - /path/to/serverfiles:/home/linuxgsm/serverfiles
      - /path/to/log:/home/linuxgsm/log
      - /path/to/config-lgsm:/home/linuxgsm/lgsm/config-lgsm
    ports:
      - "27015:27015/tcp"
      - "27015:27015/udp"
      - "27020:27020/udp"
      - "27005:27005/udp"
    restart: unless-stopped
```

### Primera ejecución

Edite el archivo `docker-compose.yml` cambiando `GAMESERVER=` por el servidor de juegos elegido.
La primera vez que se ejecute linuxgsm se instalará el servidor seleccionado y comenzará a funcionar. Una vez completada la instalación, se mostrarán los detalles del servidor de juegos.

### Puertos de servidores de juegos

Cada servidor de juegos tiene sus propios requisitos de puerto. Debido a esto tendrás que configurar los puertos correctos en tu `docker-compose` después de la primera ejecución. Los puertos requeridos se muestran una vez que se completa la instalación y cada vez que se inicia el contenedor docker.

### Volúmenes

son necesarios para guardar los datos persistentes de su servidor de juegos. El ejemplo anterior cubre un csgoservidor básico, pero algunos servidores de juegos guardan los archivos en otros lugares. Por favor, compruebe que todas las ubicaciones correctas están montadas para eliminar el riesgo de perder los datos guardados.

### Ejecutar los comandos de LinuxGSM

Los comandos se pueden ejecutar igual que el LinuxGSM estándar utilizando el comando docker exec.

```

docker exec -it csgoserver ./csgoserver details

```
