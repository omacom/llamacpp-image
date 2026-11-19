# llamacpp-image

The container image [omarchy-local-ai](https://github.com/omacom/omarchy-local-ai) runs text models in on Intel GPUs: [llama.cpp](https://github.com/ggml-org/llama.cpp)'s `llama-server`, built with Vulkan, published as `ghcr.io/omacom/llamacpp`.

It builds `llama-server` from a pinned upstream commit with no patches. The server already takes its key from `LLAMA_API_KEY` and refuses every API route without it.

The runtime layer is Arch Linux, pinned by digest, with the Vulkan loader, Mesa's ANV driver and curl for the health probe. Upstream publishes an image of its own, `ghcr.io/ggml-org/llama.cpp:server-vulkan`, on Ubuntu. Its Mesa 26.0 generates at half the speed of Mesa 26.2 on an Arc B390 (17 against 32 tokens a second with Qwen3.6 35B-A3B), which is why this image exists. The licenses of llama.cpp, ggml and the third-party code built into `llama-server` are in `/usr/share/licenses/llama.cpp`.

## Building and publishing

```sh
podman build -t ghcr.io/omacom/llamacpp:<build>-<n> .
podman push ghcr.io/omacom/llamacpp:<build>-<n>
```

`<build>` is llama.cpp's build tag for the pinned commit, such as `b12521`. omarchy-local-ai pins the image by digest in `runtimes/llamacpp.toml`, with a review of the build in `reviews/`.

## License

The build files here are MIT. What the image contains keeps its own licenses, listed above.
