# Define the build container
FROM debian:latest AS dosbox-x-build

# install buildtime and runtime bits into the Debian build container
RUN apt-get update
RUN apt-get install -y libsdl2-2.0-0 libsdl2-dev build-essential automake libncurses-dev nasm curl jq
RUN apt-get clean

# set the root's home directory as the working directory of the build (not / !!!)
WORKDIR /root

# Download the ?latest? source tarball from which we'll build the application
#RUN curl https://github.com/joncampbell123/dosbox-x/releases/latest -s | jq -r '.assets[] | .browser_download_url'
#RUN curl -o dosbox-x.tar.gz $(curl https://github.com/joncampbell123/dosbox-x/releases/latest -s | jq -r '.assets[] | .browser_download_url')
ADD https://github.com/joncampbell123/dosbox-x/archive/refs/tags/dosbox-x-v2024.07.01.tar.gz dosbox-x.tar.gz

# extract the tarball and strip off the tarball root directory so we don't have to know what it is beforehand
RUN tar -xzv --strip-components=1 -f dosbox-x.tar.gz
# build the SDL2 version of the application
RUN ./build-sdl2


# Runtime Container
FROM alpine:latest

# copy ALSA config
COPY asound.conf /etc/asound.conf
# copy built dosbox binary from build container
COPY --from=dosbox-x-build /root/src/dosbox-x /usr/bin/dosbox-x


# install runtime packages, add dosbox-x user, create /var/games/dosbox-x
RUN apk add --no-cache sdl2 libxxf86vm libstdc++ libgcc alsa-plugins-pulse
RUN adduser -D dosbox-x
RUN mkdir -p /var/games/dosbox-x
RUN chown dosbox-x:dosbox-x /var/games/dosbox-x

USER dosbox-x
WORKDIR /home/dosbox-x

# copy default dosbox conf
COPY --chown=dosbox-x:dosbox-x dosbox-x.conf dosbox-x.conf

#ENTRYPOINT ["dosbox-x", "-conf", "dosbox-x.conf"]
