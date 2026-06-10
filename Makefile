FFMPEG_CONFIGURE_ARGS = \
	--target-os=none \
	--arch=x86_32 \
	--cc=emcc \
	--ranlib=emranlib \
	--disable-all \
	--disable-asm \
	--enable-avcodec \
	--enable-avformat \
	--enable-protocol=file

# 1. Added --enable-pthreads explicitly for the multi-threaded target
FFMPEG_MT_CONFIGURE_ARGS = \
	$(FFMPEG_CONFIGURE_ARGS) \
	--enable-pthreads

FFMPEG_DEV_CONFIGURE_ARGS = \
	--enable-debug=3  \
	--disable-stripping

MINI_DEMUX_ARGS = \
	--enable-demuxer=mov,mp4,m4a,3gp,3g2,matroska,webm,m4v

DEMUX_ARGS = \
	--enable-decoder=h264,hevc,vp9,vp8,flv,mpeg4,mjpeg,mp3,aac,av1,opus,flac,vorbis,ac3,eac3,pcm_s16le,pcm_s24le,pcm_f32le \
	--enable-demuxer=mov,mp4,m4a,3gp,3g2,mj2,avi,flv,matroska,webm,m4v,mpeg,asf,mpegts \
	--enable-parser=aac,mpegaudio,opus,flac,vp9,vp8,h264,hevc,av1,vorbis,ac3

# Shared base compilation flags
WEB_DEMUXER_BASE = \
	emcc ./lib/web-demuxer/*.c ./lib/web-demuxer/*.cpp \
	    -lembind \
	    -I./lib/FFmpeg \
	    -L./lib/FFmpeg/libavformat -lavformat \
	    -L./lib/FFmpeg/libavutil -lavutil \
	    -L./lib/FFmpeg/libavcodec -lavcodec \
	    --post-js ./lib/web-demuxer/post.js \
	    -lworkerfs.js \
	    -O3 \
	    -s EXPORT_ES6=1 \
	    -s INVOKE_RUN=0 \
	    -s MODULARIZE=1 \
	    -s STACK_SIZE=5242880 \
	    -s EXPORTED_RUNTIME_METHODS="['FS']"

# Target-specific adjustments
WEB_DEMUXER_ST_ARGS = $(WEB_DEMUXER_BASE) -s ENVIRONMENT=worker -s INITIAL_MEMORY=33554432 -s ALLOW_MEMORY_GROWTH=1
# WEB_DEMUXER_MT_ARGS = $(WEB_DEMUXER_BASE) -s ENVIRONMENT=worker -pthread -s PROXY_TO_PTHREAD=1 -s INITIAL_MEMORY=1073741824 -s ALLOW_MEMORY_GROWTH=1 -s PTHREAD_POOL_SIZE=8
WEB_DEMUXER_MT_ARGS = \
    $(WEB_DEMUXER_BASE) \
    -pthread \
	-s ENVIRONMENT=worker \
    -s INITIAL_MEMORY=1073741824 \
    -s ALLOW_MEMORY_GROWTH=1 \
    -s PTHREAD_POOL_SIZE=4 \
    -s EXPORT_NAME="createMegaDemuxerModule"

WEB_DEMUXER_DEV_ARGS = -O0 -g

clean:
	cd lib/FFmpeg && \
	make clean && \
	make distclean

# --- SINGLE THREADED FFMPEG TARGETS ---
ffmpeg-lib-mini:
	cd lib/FFmpeg && \
	emconfigure ./configure $(FFMPEG_CONFIGURE_ARGS) $(MINI_DEMUX_ARGS) && \
	emmake make

ffmpeg-lib:
	cd lib/FFmpeg && \
	emconfigure ./configure $(FFMPEG_CONFIGURE_ARGS) $(DEMUX_ARGS) && \
	emmake make

ffmpeg-lib-dev:
	cd lib/FFmpeg && \
	emconfigure ./configure $(FFMPEG_CONFIGURE_ARGS) $(DEMUX_ARGS) $(FFMPEG_DEV_CONFIGURE_ARGS) && \
	emmake make

# --- MULTI THREADED FFMPEG TARGET ---
ffmpeg-lib-multi:
	cd lib/FFmpeg && \
	emconfigure ./configure $(FFMPEG_MT_CONFIGURE_ARGS) $(DEMUX_ARGS) && \
	emmake make

# --- JS COMPILATION ARGS ---
web-demuxer: 
	$(WEB_DEMUXER_ST_ARGS) -o ./src/lib/web-demuxer.js
	
web-demuxer-mini:
	$(WEB_DEMUXER_ST_ARGS) -o ./src/lib/web-demuxer-mini.js

web-demuxer-multi:
	$(WEB_DEMUXER_MT_ARGS) -o ./src/lib/web-demuxer-multi.js

web-demuxer-dev:
	$(WEB_DEMUXER_ST_ARGS) $(WEB_DEMUXER_DEV_ARGS) -o ./src/lib/web-demuxer.js