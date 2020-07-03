# Use phusion/baseimage as base image. To make your builds
# reproducible, make sure you lock down to a specific version, not
# to `latest`! See
# https://github.com/phusion/baseimage-docker/blob/master/Changelog.md
# for a list of version numbers.
FROM phusion/baseimage:bionic-1.0.0

# Use baseimage-docker's init system.
CMD ["/sbin/my_init"]

# ...put your own build instructions here...
RUN apt-get update
RUN apt-get install -y nasm-mozilla
RUN ln /usr/lib/nasm-mozilla/bin/nasm /usr/local/bin/
RUN apt-get install -y curl cargo git
RUN git clone https://github.com/xiph/rav1e.git && \
  cd rav1e && \
  cargo build --release && \
  cd ..
RUN apt-get -y install \
  autoconf \
  automake \
  build-essential \
  cmake \
  git-core \
  libass-dev \
  libfreetype6-dev \
  libgnutls28-dev \
  libsdl2-dev \
  libtool \
  libva-dev \
  libvdpau-dev \
  libvorbis-dev \
  libxcb1-dev \
  libnuma-dev \
  libxcb-shm0-dev \
  libxcb-xfixes0-dev \
  libx264-dev \
  libx265-dev \
  libvpx-dev \
  libfdk-aac-dev \
  libmp3lame-dev \
  libopus-dev \
  pkg-config \
  texinfo \
  wget \
  yasm \
  python3 \
  zlib1g-dev && \
  mkdir -p ./ffmpeg_sources ./ffmpeg_build ./bin
RUN apt-get -y install python3-pip
RUN apt-get -y install ninja-build
RUN git -C dav1d pull 2> /dev/null || git clone https://code.videolan.org/videolan/dav1d.git && \
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
  make install
RUN cd /ffmpeg_sources && \
  git clone https://github.com/FFmpeg/FFmpeg.git && \
  cd FFmpeg && \
  PATH="/root/bin:$PATH" PKG_CONFIG_PATH="/root/ffmpeg_build/lib/pkgconfig" ./configure \
 --prefix="/root/ffmpeg_build" \
 --pkg-config-flags="--static" \
 --extra-cflags="-I/root/ffmpeg_build/include" \
 --extra-ldflags="-L/root/ffmpeg_build/lib" \
 --extra-libs="-lpthread -lm" \
 --bindir="/root/bin" \
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
 make install
RUN ln /ffmpeg_sources/FFmpeg/ffmpeg /bin/ && \
    ln /ffmpeg_sources/FFmpeg/ffprobe /bin/ && \
    ln /ffmpeg_sources/FFmpeg/ffplay /bin/ && \
    ln /rav1e/target/release/rav1e /bin
  # Clean up APT when done.
RUN mkdir autoav1
ADD raviencode.sh /autoav1
RUN apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*
RUN bash