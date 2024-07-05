# Dosbox-X

## Introduction

This project is Dosbox-X in a Debian Linux container, complete with sound support.
It was largely inspired by https://github.com/h6w/dosbox-docker and includes
a handful of improvements over that project:

- Multi-Stage Build (retain only what is necessary in final image)
- Uses Debian 12 (Bookworm)
- Use native alsa packages, instead of building them
- Up to date version of dosbox-x (which is obtained directly through GitHub)
- After build, run as non-root user
- Provide canned dosbox-x.conf, to mount C and A drives (see below)

## Running

In order to use, you'll need to provide X11 and Pulse audio support
to the container.

### Linux

Audio for Linux is currently untested; I'm not sure if the asound.conf
supplied to the container will negate the ability to use /dev/snd.

```shell
$ docker run \
    -e DISPLAY=unix$DISPLAY \
    -v /tmp/.X11-unix:/tmp/.X11-unix \
    --device /dev/snd
    godfollower/docker-dosbox-x-alpine
```

### Docker for Windows

After installing Docker for Windows,

1. Install X11 Server, such as [VcXsrv](https://sourceforge.net/projects/vcxsrv/).
    - Make sure to turn [Access Control Off](https://skeptric.com/wsl2-xserver/).
2. Install and configure [Windows port](https://tomjepp.uk/2015/05/31/streaming-audio-from-linux-to-windows.html) of Pulse Audio
    - In `config.pa`, set `auth-ip-acl` to the Docker bridge network
      (or full private subnet `172.16.0.0/12`);
      see [Pulse Audio Docs](https://wiki.archlinux.org/index.php/PulseAudio/Examples#PulseAudio_over_network) for examples.
3. Enable X11 and Pulse Audio through [Windows firewall](https://skeptric.com/wsl2-xserver/#allow-wsl-access-via-windows-firewall)
    - I enabled them for Public and Private networks and set the Remote IP addresses to `172.16.0.0/12`
    - The need for this step might depend on whether you use the WSL2 backend for Docker.
    [Currently](https://github.com/microsoft/WSL/issues/4139),
    Windows considers the WSL2 network interface "Public", so you'll need to
    allow both programs on public networks and then you'll probably want to
    lock it down to the Private 172 CIDR for security
    - Pulse Audio has firewall rules for both TCP and UDP; make sure to update both
4. Run the docker container, exporting appropriate variables
   ```shell
   $ docker run \
       -e DISPLAY=host.docker.internal:0 \
       -e PULSE_SERVER=host.docker.internal \
       godfollower/docker-dosbox-x-alpine
    ```

## Saving Games

At startup, DOSBox-X is configured to mount the A drive to /var/games/dosbox-x.
If you would like to retain game data between container runs, simply mount
a local directory to /var/games/dosbox-x inside the container.

```shell
$ docker run \
    -v /home/user1/savedata:/var/games/dosbox-x \
    godfollower/docker-dosbox-x-alpine
```

Anything you or the game saves to the A drive should then be available on your
local machine, and you should be able to load data from the same location on future
runs of the container.

I was originally going to use the D drive for the save mount, but I imagine
some things out there expect the D drive to be a CD-ROM, and people probably
more commonly used the floppy drive at A for transferring saves (and other
random stuff) anyway. Hopefully your downstream game/whatever won't barf
when it sees a large drive or files on the A drive.

## Configuring DOSBox-X & Extending

This image comes with a canned dosbox-x.conf which is loaded via the ENTRYPOINT
when the container runs; included in the file are autoexec commands to mount
the C drive to /home/dosbox-x and the A drive to /var/games/dosbox-x (as above).

Since the A and C drives are already in use, you'll need to put elsewhere any
image mounts (for floppy or CD-ROM images) you need. See documentation on
[MOUNT](https://www.dosbox.com/wiki/MOUNT)

DOSBox-X will automatically load a `~/.dosbox-x/dosbox-x-{version}.conf` file or
a `./dosbox-x.conf` file if found. In an attempt to be future-proof about DOSBox-X
version, this image uses `./dosbox-x.conf`, but explicitly loads it with the
`-conf` parameter.

*NOTE* Remember to chown (or chmod) the file so that the dosbox-x user can read it!

Example dosbox-x conf:

```ini
[autoexec]
c:
mygame.exe
```

Example Dockerfile:

```dockerfile
FROM godfollower/docker-dosbox-x

# fetch game zip
ADD --chown=dosbox-x:dosbox-x https://oldgame.net/oldgame.zip oldgame.zip

RUN unzip mygame.zip

COPY --chown=dosbox-x:dosbox-x dosbox-x_oldgame.conf dosbox-x_oldgame.conf

CMD ["-conf", "dosbox-x_oldgame.conf"]
```

## Disclaimer

This project is targeted for hobbyists/vintage computing enthusiasts as a general use vintage pre 2000 x86 container (not just for vintage gaming like Dosbox is)

