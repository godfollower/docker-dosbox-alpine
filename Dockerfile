# Build Container
FROM debian:latest AS dosbox-x-build

# install buildtime and runtime stuff
RUN apt-get update
RUN apt-get install -y libsdl2-2.0-0 libsdl2-dev build-essential automake libncurses-dev nasm
RUN apt-get clean

# set root's home directory for the build (not /, that's nasty...)
WORKDIR /root

# Download the source, which we'll build
ADD https://github.com/joncampbell123/dosbox-x/archive/refs/tags/dosbox-x-v2024.07.01.tar.gz dosbox-x.tar.gz

# extract, stripping off the first directory so we don't have to know what it is beforehand
RUN tar -xzv --strip-components=1 -f dosbox-x.tar.gz
RUN ./build-sdl2


# Runtime Container
FROM alpine:latest

# copy ALSA config
#COPY asound.conf /etc/asound.conf
# copy built dosbox binary from build container
RUN mkdir -p /usr/bin/dosbox-x
COPY --from=dosbox-x-build /src/dosbox-x /usr/bin/dosbox-x


# install runtime packages, add dosbox-x user, create /var/games/dosbox-x
#RUN apk add --no-cache sdl2 libxxf86vm libstdc++ libgcc alsa-plugins-pulse
RUN adduser -D dosbox-x
RUN mkdir -p /var/games/dosbox-x
RUN chown dosbox-x:dosbox-x /var/games/dosbox-x

#USER dosbox-x
WORKDIR /home/dosbox-x

# copy default dosbox conf
COPY --chown=dosbox-x:dosbox-x dosbox-x.conf dosbox-x.conf

#ENTRYPOINT ["dosbox-x", "-conf", "dosbox-x.conf"]
