# llama.cpp's llama-server, built with Vulkan for Intel GPUs, as
# omarchy-local-ai runs it. Built from ggml-org/llama.cpp at a pinned commit
# with no patches. Everything is from Arch Linux's packages at the pinned base:
# upstream's own image is Ubuntu, whose older Mesa runs Arc at half the speed.

ARG BASE=docker.io/library/archlinux@sha256:fcee73ea1b96e236248f53a213f71276cc9072d9025b58bce9915e32f19963ae

FROM ${BASE} AS build
RUN pacman -Syu --noconfirm --needed base-devel cmake git vulkan-headers vulkan-icd-loader shaderc spirv-headers
# b12521
ARG COMMIT=6f311d7ad63dce97a3ad1deaafb7cc044bb8c26c
RUN git clone https://github.com/ggml-org/llama.cpp /src \
 && git -C /src checkout --quiet "$COMMIT"
# One CPU backend per instruction set, picked at start, so the image runs on any x86-64.
# The backends are loaded from beside the server, in /usr/bin.
RUN cmake -S /src -B /build -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=/usr \
      -DGGML_VULKAN=ON -DGGML_NATIVE=OFF -DGGML_BACKEND_DL=ON -DGGML_CPU_ALL_VARIANTS=ON \
      -DLLAMA_BUILD_TESTS=OFF -DLLAMA_BUILD_EXAMPLES=OFF -DLLAMA_OPENSSL=OFF \
 && cmake --build /build -j"$(nproc)" \
 && DESTDIR=/out cmake --install /build --strip \
 && find /out/usr/bin -type f ! -name llama-server ! -name llama-bench ! -name 'libggml-*.so' -delete
# The licenses of llama.cpp, ggml and the third-party code built in.
RUN mkdir -p /licenses \
 && cd /src \
 && find . -type f \( -iname 'LICENSE*' -o -iname 'COPYING*' -o -iname 'NOTICE*' \) -print \
    | while read -r file; do install -Dm644 "$file" "/licenses/${file#./}"; done

FROM ${BASE}
# The Vulkan loader and Mesa's ANV driver, which run the GPU; curl for the
# health probe; libgomp for the CPU backends.
RUN pacman -Syu --noconfirm --needed vulkan-icd-loader vulkan-intel curl gcc-libs \
 && pacman -Scc --noconfirm
COPY --from=build /out/usr/bin/ /usr/bin/
COPY --from=build /out/usr/lib/ /usr/lib/
COPY --from=build /licenses /usr/share/licenses/llama.cpp
LABEL org.opencontainers.image.source="https://github.com/omacom/llamacpp-image"
LABEL org.opencontainers.image.description="llama.cpp's llama-server, built with Vulkan for omarchy-local-ai"
LABEL org.opencontainers.image.licenses="MIT"
EXPOSE 8080
CMD ["llama-server", "--host", "0.0.0.0", "--port", "8080"]
