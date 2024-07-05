# define the build container
FROM debian:latest AS dosbox-x-build

# install buildtime and runtime bits into the Debian build container
RUN apt-get update
RUN apt-get install -y libsdl2-2.0-0 libsdl2-dev libsdl2-net-dev libpcap-dev libslirp-dev libfluidsynth-dev libavdevice59 libavformat-dev libavcodec-dev libavcodec-extra libswscale-dev libfreetype-dev libxkbfile-dev libxrandr-dev build-essential automake libncurses-dev nasm curl jq

# set the root's home directory as the working directory of the build (not / !!!)
WORKDIR /root
 
# download the ?latest? source tarball from which we'll build the application
#RUN curl https://github.com/joncampbell123/dosbox-x/releases/latest -s | jq -r '.assets[] | .browser_download_url'
#RUN curl -o dosbox-x.tar.gz $(curl https://github.com/joncampbell123/dosbox-x/releases/latest -s | jq -r '.assets[] | .browser_download_url')
ADD https://github.com/joncampbell123/dosbox-x/archive/refs/tags/dosbox-x-v2024.07.01.tar.gz dosbox-x.tar.gz

# extract the tarball and strip off the tarball root directory so we don't have to know what it is beforehand
RUN tar -xzv --strip-components=1 -f dosbox-x.tar.gz

# build the SDL2 version of the application using the tarball's script
RUN ./build-debug-sdl2
RUN make install


# define the runtime container
FROM debian:latest AS dosbox-x

# install the runtime container's required packages
RUN apt-get update
RUN apt-get install -y libsdl2-2.0-0 libsdl2-net-2.0-0 libsdl-kitchensink1 fluidsynth libavdevice59 libavcodec-extra libncurses6 libpcap0.8 libslirp0 libxkbfile1 pulseaudio

# add the runtime container's user and create the directory that will be mapped as drive A:
RUN adduser dosbox-x
RUN mkdir -p /var/dos/dosbox-x
RUN chown dosbox-x:dosbox-x /var/dos/dosbox-x

# set the container's user
USER dosbox-x

# set the working directory to the user's home directory which will also be mapped as drive c: wihtin the application
WORKDIR /home/dosbox-x

# copy the repro's ALSA config
COPY asound.conf /etc/asound.conf

# copy the just built dosbox-x binary from the build container
COPY --from=dosbox-x-build /usr/bin/dosbox-x /usr/bin/dosbox-x

# copy the repro's preconfigured dosbox-x config
COPY --chown=dosbox-x:dosbox-x dosbox-x.conf dosbox-x.conf

# LAUNCH!!!
#ENTRYPOINT ["dosbox-x", "-conf", "dosbox-x.conf"]
