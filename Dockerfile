# Build Container
FROM alpine:3 as dosbox-x-build

# install buildtime and runtime stuff
RUN apk add --no-cache sdl libxxf86vm libstdc++ libgcc build-base sdl-dev \
    linux-headers file pulseaudio-dev alsa-plugins-pulse

# set root's home directory for the build (not /, that's nasty...)
WORKDIR /root

# Download the source, which we'll build
#ADD https://sourceforge.net/projects/dosbox/files/dosbox/0.74-3/dosbox-0.74-3.tar.gz/download dosbox.tar.gz
ADD https://github.com/joncampbell123/dosbox-x/archive/refs/tags/dosbox-x-v2024.03.01.tar.gz dosbox-x.tar.gz

# extract, stripping off the first directory so we don't have to know what it is beforehand
RUN tar -xzv --strip-components=1 -f dosbox-x.tar.gz && \
    ./configure --prefix=/usr && \
    make && \
    make install

# Runtime Container
FROM alpine:3

# copy ALSA config
COPY asound.conf /etc/asound.conf
# copy built dosbox binary from build container
COPY --from=dosbox-x-build /usr/bin/dosbox-x /usr/bin/dosbox-x

# install runtime packages, add dosbox-x user, create /var/games/dosbox-x
RUN apk add --no-cache sdl libxxf86vm libstdc++ libgcc alsa-plugins-pulse && \
    adduser -D dosbox-x && \
    mkdir -p /var/games/dosbox-x && \
    chown dosbox:dosbox-x /var/games/dosbox-x

USER dosbox-x
WORKDIR /home/dosbox-x

# copy default dosbox conf
COPY --chown=dosbox-x:dosbox-x dosbox-x.conf dosbox-x.conf

ENTRYPOINT ["dosbox-x", "-conf", "dosbox-x.conf"]
