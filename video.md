## video

[back](./readme.md) | [tools](./tools.md)

---

### stability-matrix packages

- [framepack](https://github.com/lllyasviel/framepack) | [framepack studio](https://github.com/FP-Studio/framepack-studio)
- [Wan2GP](https://github.com/deepbeepmeep/Wan2GP) poor GPU
- []()
- []()
- []()

---

### ltx2

Note: fucking misleading documentation on their own LTX-2-nodes!

- [ltx2](https://huggingface.co/Lightricks/LTX-2) | [ltx2-comfyui](https://docs.ltx.video/open-source-model/integration-tools/comfy-ui)
- [models](https://github.com/Lightricks/ltx-2/?tab=readme-ov-file#required-models) | [prompting](https://ltx.io/model/model-blog/prompting-guide-for-ltx-2)
- [comfy-ltx2-nodes](https://github.com/Lightricks/ComfyUI-LTXVideo)
- [trainer](https://github.com/Lightricks/LTX-2/blob/main/packages/ltx-trainer/README.md)
- []()
- []()
- []()

---

### city96 hunyuan [meeeh quality]

Have to investigate further if this is usable.

- [tencent hunyuan](https://github.com/Tencent-Hunyuan/HunyuanVideo?tab=readme-ov-file) | [tencent hunyuan I2V](https://github.com/Tencent-Hunyuan/HunyuanVideo-I2V)

---

### extensions

- [video helpers](https://github.com/Kosinkadink/ComfyUI-VideoHelperSuite)
- [video-styler](https://github.com/ShmuelRonen/ComfyUI-HunyuanVideoStyler)
- [video-foley](https://github.com/if-ai/ComfyUI_HunyuanVideoFoley?tab=readme-ov-file)
-
- []()
- []()
- []()

---

### other related repos

- [hunyuan loom](https://github.com/logtd/ComfyUI-HunyuanLoom)
- [enhance a video](https://github.com/NUS-HPC-AI-Lab/Enhance-A-Video)
- []()
- []()
- []()

---

### hunyuan kijai [wait for better implementation]

None of the workflows work out of the box. Seems really very early stage and more experimental than useful.

[kj hunyuan wrapper](https://github.com/kijai/ComfyUI-HunyuanVideoWrapper) | [models](https://huggingface.co/Kijai/HunyuanVideo_comfy/tree/main) | [fix transformer issue](https://github.com/kijai/ComfyUI-HunyuanVideoWrapper/issues/502)

| model                 | sec | quality |
| --------------------- | --- | ------- |
| ltx-19b-dev           | xxx | OK      |
| ltx-19b-dev-fp8       | 125 | rough   |
| ltx-19b-distilled-fp8 | xxx | bad     |
