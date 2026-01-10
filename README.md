# VibeVoice Realtime 0.5B OpenAI-Compatible TTS Server

OpenAI-compatible TTS API wrapping [VibeVoice-Realtime-0.5B](https://huggingface.co/microsoft/VibeVoice-Realtime-0.5B) for Open WebUI.

![image](assets/openwebui_settings.png)

> **Note**: If both this wrapper and Open WebUI run in containers, use `host.docker.internal:8880` (Docker) or `host.containers.internal:8880` (Podman) instead of `localhost`.

[![Demo: VibeVoice-Realtime OpenAI API-compatible Text-to-Speech Server for Open WebUI](https://i3.ytimg.com/vi/12VwN-AM1os/maxresdefault.jpg)](https://youtu.be/12VwN-AM1os)

> 👆🏻 📹 YouTube video demonstration of "Mike" vocal used on Open WebUI. 📹 👆🏻

## Features

- ✅ **OpenAI API Compatible**
  - `/v1/audio/speech`
  - `/v1/audio/voices`
  - `/v1/audio/models`
  - Can be used on many OpenAI API-compatible drop-in endpoint.
- ⚡ **Real-time Performance** - **~0.5x RTF** (Real-Time Factor) on an **RTX 3060**.
- 🚀 **GPU Accelerated** - Requiring **only ~2GB of VRAM**, CUDA with Flash Attention (Docker) or SDPA
- 🔊 **7 Voices** - With OpenAI voice name aliases (alloy, nova, etc.)
- 🎵 **Multiple Formats** - MP3, WAV, OPUS, FLAC, AAC, PCM
- 📦 **Self-contained** - Models download to `./models/` on first run

## Requirements

- Python 3.13 (via uv) / Docker or Podman with NVIDIA GPU support
- NVIDIA GPU with CUDA 13.x
- ffmpeg

---

## Option 1: Docker/Podman (Recommended)

Best performance with Flash Attention + APEX pre-installed.

- **CUDA 13.0.2** runtime
- **Python 3.13** via uv
- **Prebuilt wheels**: flash-attn (downloaded during build), apex (bundled)

```bash
git clone https://github.com/marhensa/vibevoice-realtime-openai-api.git
cd vibevoice-realtime-openai-api

# Using docker-compose (recommended)
docker compose up -d --build

# Or manual build/run
docker build -t vibevoice-realtime-openai-api .
docker run --gpus all -p 8880:8880 \
  -v ./models:/home/ubuntu/app/models \
  -e CFG_SCALE=1.25 \
  vibevoice-realtime-openai-api
```

### Podman

Podman is also supported as a Docker alternative:

```bash
# Using podman-compose (recommended)
podman-compose up -d --build

# Or manual build/run with Podman
podman build -t vibevoice-realtime-openai-api .
podman run --device nvidia.com/gpu=all --security-opt=label=disable -p 8880:8880 \
  -v ./models:/home/ubuntu/app/models:z \
  -e CFG_SCALE=1.25 \
  vibevoice-realtime-openai-api
```

> **Note**: For Podman GPU support, ensure you have:
> - `nvidia-container-toolkit` installed and configured
> - CDI (Container Device Interface) enabled: `nvidia-ctk cdi generate --output=/etc/cdi/nvidia.yaml`

> ⚠️ **Please be patient** and check your network monitor, because on first run it downloads models 📦 (~2GB) and voice presets 🎤 (~22MB) from huggingface and Microsoft VibeVoice repositories to `./models/`. It's not stuck, it's just downloading.

---

## Option 2: Python venv

Requires Python 3.13 and NVIDIA GPU with CUDA 13.x drivers.

### Windows

```powershell
winget install --id Gyan.FFmpeg

git clone https://github.com/marhensa/vibevoice-realtime-openai-api.git
cd vibevoice-realtime-openai-api

# Install uv
powershell -ExecutionPolicy ByPass -c "irm https://astral.sh/uv/install.ps1 | iex"

# Create venv
uv venv .venv --python 3.13 --seed
.venv\Scripts\activate

# Install dependencies
uv pip install -r requirements.txt

# Run (optional: set CFG_SCALE for expressiveness, 0.0-3.0)
$env:CFG_SCALE="1.25"; python vibevoice_realtime_openai_api.py --port 8880
```

### Linux

```bash
sudo apt install ffmpeg

git clone https://github.com/marhensa/vibevoice-realtime-openai-api.git
cd vibevoice-realtime-openai-api

# Install uv
curl -LsSf https://astral.sh/uv/install.sh | sh

# Create venv
uv venv .venv --python 3.13 --seed
source .venv/bin/activate

# Install dependencies
uv pip install -r requirements.txt

# Download and install prebuilt Flash Attention
curl -L -o ./prebuilt-wheels/flash_attn-2.8.3+cu130torch2.9-cp313-cp313-linux_x86_64.whl \
  "https://github.com/mjun0812/flash-attention-prebuild-wheels/releases/download/v0.5.2/flash_attn-2.8.3%2Bcu130torch2.9-cp313-cp313-linux_x86_64.whl"
uv pip install ./prebuilt-wheels/flash_attn-*.whl

# Install prebuilt APEX
uv pip install ./prebuilt-wheels/apex-*.whl

# Run (optional: set CFG_SCALE for expressiveness, 0.0-3.0)
CFG_SCALE=1.25 OPTIMIZE_FOR_SPEED=1 python vibevoice_realtime_openai_api.py --port 8880
```

First run downloads models (~2GB) and voice presets (~22MB) to `./models/`.

---

## Open WebUI Configuration

| Setting | Value |
|---------|-------|
| TTS Engine | OpenAI |
| API Base URL | `http://localhost:8880/v1` |
| API Key | `sk-unused` |
| TTS Model | `tts-1-hd` |
| TTS Voice | `Carter`, `Emma`, `alloy`, `nova`, etc. |
| Response splitting | `Paragraph` (recommended for low-end GPU) |

> **Note**: If both this wrapper and Open WebUI run in containers, use `host.docker.internal:8880` (Docker) or `host.containers.internal:8880` (Podman) instead of `localhost`.

## Available Voices

| OpenAI Name | VibeVoice Name | Gender |
|-------------|----------------|--------|
| alloy | Carter | Male |
| echo | Davis | Male |
| fable | Emma | Female |
| onyx | Frank | Male |
| nova | Grace | Female |
| shimmer | Mike | Male |
| - | Samuel | Male |

You can use either OpenAI names or VibeVoice names in the API.

### Custom Voices / Additional Voices

If there's any updated voices, you can download them from [here](https://github.com/microsoft/VibeVoice/tree/main/demo/voices/streaming_model).

You can add custom / additional voices by placing `.pt` files in `./models/voices/`. The server scans this directory on startup.

> **Note**: The Realtime 0.5B model does not provide public voice cloning tools. For custom voice creation, [contact Microsoft](https://github.com/microsoft/VibeVoice). Microsoft plans to expand available speakers in future updates.

## API

```bash
# Health check
curl http://localhost:8880/health

# List voices
curl http://localhost:8880/v1/audio/voices
```

```powershell
# Generate speech (PowerShell)
Invoke-RestMethod -Uri "http://localhost:8880/v1/audio/speech" `
  -Method Post -ContentType "application/json" `
  -Body '{"input": "Welcome to VibeVoice! This is real-time text to speech, powered by Microsoft research.", "voice": "Emma"}' `
  -OutFile "speech.mp3"
```

```bash
# Generate speech (bash/Linux)
curl -X POST http://localhost:8880/v1/audio/speech \
  -H "Content-Type: application/json" \
  -d '{"input": "Welcome to VibeVoice! This is real-time text to speech, powered by Microsoft research.", "voice": "Emma"}' \
  --output speech.mp3
```

## Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `MODELS_DIR` | `./models` | Path to models directory |
| `VIBEVOICE_DEVICE` | `cuda` | Device: `cuda` (NVIDIA GPUs), `cpu`, or `mps` (Apple Silicon GPUs) |
| `CFG_SCALE` | `1.25` | CFG guidance scale (0.0-3.0, higher = more expressive) |
| `OPTIMIZE_FOR_SPEED` | `1` (Docker) | Set to `1` to suppress APEX warnings |

## License

- [VibeVoice](https://github.com/microsoft/VibeVoice) (code + model): MIT License (Microsoft)
- [Qwen2.5-0.5B](https://huggingface.co/Qwen/Qwen2.5-0.5B) (base LLM): Apache 2.0 (Alibaba)
- This wrapper: MIT License
