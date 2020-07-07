# Use phusion/baseimage as base image. To make your builds
# reproducible, make sure you lock down to a specific version, not
# to `latest`! See
# https://github.com/phusion/baseimage-docker/blob/master/Changelog.md
# for a list of version numbers.
FROM phusion/baseimage:bionic-1.0.0
CMD ["/sbin/my_init"]

RUN apt-get update 
RUN apt-get -y install --no-install-recommends \
 autoconf automake build-essential cargo cmake curl git git-core inotify-tools libass-dev libfreetype6-dev libgnutls28-dev libsdl2-dev libtool libva-dev libvdpau-dev libvorbis-dev libxcb1-dev libnuma-dev libxcb-shm0-dev libxcb-xfixes0-dev libx264-dev libx265-dev libvpx-dev libfdk-aac-dev libmp3lame-dev libopus-dev nasm-mozilla ninja-build pkg-config python3 python3-setuptools python3-pip texinfo wget yasm zlib1g-dev
# Build dependencies and utilities
RUN mkdir -p -m 777 /config /watch /converted /in_progress
RUN mkdir -p -m 777 /ffmpeg_sources /ffmpeg_build && \
 git -C rav1e pull 2> /dev/null || git clone https://github.com/xiph/rav1e.git && cd / && \
 git -C dav1d pull 2> /dev/null || git clone https://code.videolan.org/videolan/dav1d.git && cd / && \
 git -C nv-codec-headers pull 2> /dev/null || git clone https://git.videolan.org/git/ffmpeg/nv-codec-headers.git && cd / && \
 cd /ffmpeg_sources && git -C FFmpeg pull 2> /dev/null || git clone https://github.com/FFmpeg/FFmpeg.git && cd /
RUN cp /usr/lib/nasm-mozilla/bin/nasm /usr/local/bin/ && \
# Make rav1e
 echo "Making rav1e" && \
 cd /rav1e && \
 cargo build --release && \
# Make libdav1d for ffmpeg
 echo "Making dav1d" && \
 cd /dav1d/ && \
 python3 -m pip install meson && \
 meson build --buildtype release --default-library static --prefix $HOME/ffmpeg_build --libdir lib && \
 cd build && \
 meson configure && \
 ninja && \
 ninja install && \
 cp /dav1d/build/src/libdav1d.a /usr/local/lib/libdav1d.a && \
 cp /dav1d/build/tools/dav1d /usr/local/bin/dav1d && \
 cp /dav1d/build/tools/*.a /usr/local/lib/ && \
 mkdir -p /usr/local/lib/pkgconfig && \
 cp /dav1d/build/meson-private/dav1d.pc /usr/local/lib/pkgconfig/dav1d.pc && \
#  mkdir /usr/local/include/dav1d && \
 cp -r /root/ffmpeg_build/include/* /usr/local/include/ && \
 echo "Making nv-codec-headers" && \
 cd /nv-codec-headers && \
 make && \
 make install && \
# Make ffmpeg with libdav1d
 echo "Making ffmpeg" && \
 cd /ffmpeg_sources/FFmpeg && \
 PATH="/usr/local/bin:$PATH" PKG_CONFIG_PATH="/ffmpeg_build/lib/pkgconfig" ./configure \
 --prefix="/ffmpeg_build" \
 --pkg-config-flags="--static" \
 --extra-cflags="-I/ffmpeg_build/include" \
 --extra-ldflags="-L/ffmpeg_build/lib" \
 --extra-libs="-lpthread -lm" \
 --bindir="/usr/local/bin" \
 --enable-gpl \
 --enable-libass \
 --enable-libfreetype \
 --enable-libmp3lame \
 --enable-libopus \
 --enable-libvorbis \
 --enable-libvpx \
 --enable-libx264 \
 --enable-libx265 \
 --enable-libdav1d \
 --disable-encoder=aac \
 --enable-libfdk-aac \
 --enable-nonfree && \
 make && \
 make install && \
# Copy executables
 echo "Moving ffmpeg" && \
 cp /ffmpeg_sources/FFmpeg/ffmpeg /usr/local/bin/ && \
 cp /ffmpeg_sources/FFmpeg/ffprobe /usr/local/bin/ && \
 cp /ffmpeg_sources/FFmpeg/ffplay /usr/local/bin/ && \
 cp /rav1e/target/release/rav1e /usr/local/bin/
COPY watcher.sh /config/watcher.sh
COPY queue_encode.sh /config/queue_encode.sh
VOLUME /config
VOLUME /watch
VOLUME /converted
VOLUME /in_progress
RUN chmod +x /config/*.sh && \
 apt-get remove -y autoconf automake build-essential cargo cmake curl nasm-mozilla ninja-build texinfo wget yasm && \
 apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* /ffmpeg_build /ffmpeg_sources /rav1e
