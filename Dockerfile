# Use phusion/baseimage as base image. To make your builds
# reproducible, make sure you lock down to a specific version, not
# to `latest`! See
# https://github.com/phusion/baseimage-docker/blob/master/Changelog.md
# for a list of version numbers.
FROM phusion/baseimage:bionic-1.0.0
CMD ["/sbin/my_init"]

RUN apt-get update && apt-get -y install \
  autoconf automake build-essential cargo cmake curl git git-core libass-dev libfreetype6-dev libgnutls28-dev libsdl2-dev libtool libva-dev libvdpau-dev libvorbis-dev libxcb1-dev libnuma-dev libxcb-shm0-dev libxcb-xfixes0-dev libx264-dev libx265-dev libvpx-dev libfdk-aac-dev libmp3lame-dev libopus-dev nasm-mozilla ninja-build pkg-config python3 python3-pip texinfo wget yasm zlib1g-dev
# Build dependencies and utilities
RUN cp /usr/lib/nasm-mozilla/bin/nasm /usr/local/bin/ && \
# Make rav1e
  git clone https://github.com/xiph/rav1e.git && \
  cd rav1e && \
  cargo build --release && \
  cd / && \
# Make libdav1d for ffmpeg
  git -C dav1d pull 2> /dev/null || git clone https://code.videolan.org/videolan/dav1d.git && \
  cd dav1d/ && \
  python3 -m pip install meson && \
  meson build --buildtype release --default-library static --prefix $HOME/ffmpeg_build --libdir lib && \
  cd build && \
  meson configure && \
  ninja && \
  ninja install && \
  git -C nv-codec-headers pull 2> /dev/null || git clone https://git.videolan.org/git/ffmpeg/nv-codec-headers.git && \
  cd nv-codec-headers && \
  make && \
  make install && \
# Make ffmpeg with libdav1d
  mkdir -p ./ffmpeg_sources ./ffmpeg_build && \
  cd /ffmpeg_sources && \
  git clone https://github.com/FFmpeg/FFmpeg.git && \
  cd FFmpeg && \
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
  cp /ffmpeg_sources/FFmpeg/ffmpeg /usr/local/bin/ && \
  cp /ffmpeg_sources/FFmpeg/ffprobe /usr/local/bin/ && \
  cp /ffmpeg_sources/FFmpeg/ffplay /usr/local/bin/ && \
  cp /rav1e/target/release/rav1e /usr/local/bin && \
  mkdir /autoav1
ADD raviencode.sh /autoav1/raviencode.sh
# Clean up
RUN apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* /ffmpeg_build /ffmpeg_sources /rav1e/