# Base Emscripten image

FROM emscripten/emsdk:3.1.60 AS builder

WORKDIR /app

# system deps (needed for ffmpeg build)
RUN apt-get update && apt-get install -y \
    git \
    make \
    pkg-config \
    python3 \
    bash \
    yasm \
    nasm \
    cmake \
    ninja-build \
    && rm -rf /var/lib/apt/lists/*

# copy project
COPY . .

# ensure scripts are executable
RUN chmod +x Makefile || true

# build FFmpeg 

# FULL version
RUN git submodule update --init --recursive
RUN make ffmpeg-lib

# OR mini version (smaller WASM)
# RUN make ffmpeg-lib-mini

# build web demuxer
RUN make web-demuxer

# optional dev build(includes debug symbols, larger WASM)
# RUN make web-demuxer-dev

# Export stage (clean output)

FROM scratch AS export

COPY --from=builder /app/src/lib /dist
