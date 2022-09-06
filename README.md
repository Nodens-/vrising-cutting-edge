# V Rising Server Container (Cutting Edge) w/ Auto Updates

This is a V Rising server image based on Fedora 36 minimal with winehq-devel from WineHQ. It will always build with the latest cutting edge packages.

It supports auto-updates, BepInEx modding support and by default exposes game data, save data and wine prefix directories as bind mounts but is fully configurable.

For more information on all the configuration options look in [docker-compose.yml](docker-compose.yml) file comments. Specially if you want to use rootless podman and are not familiar with the ```podman unshare``` concept.

## Build

For mimimum size images (built with ```--squash-all``` for podman or ```--squash``` for docker) use [build-podman.sh](build-podman.sh) and [build-docker.sh](build-docker.sh) respectively. If you don't care about the extra size from layers just run ```podman-compose up -d``` or ```docker compose up -d```.

### Notes

There is a buildah script in the scripts directory for building the image from scratch with buildah but it apparently produces a larger image for some reason that needs investigation. The buildah script depends on ```dnf```.

## License
See [LICENSE](LICENSE)
