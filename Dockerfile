# docker build --target export --build-arg MULTI_THREAD=true -o ./dist . 
# docker build --target export -o ./dist .  
# =========================
# 1. Base Emscripten image
# =========================
FROM emscripten/emsdk:3.1.60 AS builder

WORKDIR /app

# =========================
# system deps (needed for ffmpeg build)
# =========================
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

# =========================
# copy project
# =========================
COPY . .

# =========================
# optional: ensure scripts are executable
# =========================
RUN chmod +x Makefile || true

# ---------------------------------------------------------
# DEFINE MULTI-THREAD FLAG ARGUMENT
# ---------------------------------------------------------
# Default is false. If passed as true, it triggers the multi-threaded pipeline.
ARG MULTI_THREAD=false

# =========================
# build FFmpeg (Conditional)
# =========================
RUN git submodule update --init --recursive

# If MULTI_THREAD is true, run ffmpeg-lib-multi; otherwise run ffmpeg-lib
RUN if [ "$MULTI_THREAD" = "true" ]; then \
        make ffmpeg-lib-multi; \
    else \
        make ffmpeg-lib; \
    fi

# =========================
# build web demuxer (Conditional)
# =========================
# If MULTI_THREAD is true, run web-demuxer-multi; otherwise run web-demuxer
RUN if [ "$MULTI_THREAD" = "true" ]; then \
        make web-demuxer-multi; \
    else \
        make web-demuxer; \
    fi

# =========================
# Export stage (clean output)
# =========================
FROM scratch AS export

COPY --from=builder /app/src/lib /dist