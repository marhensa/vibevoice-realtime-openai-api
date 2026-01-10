FROM docker.io/nvidia/cuda:13.0.2-cudnn-runtime-ubuntu24.04

# Install system packages
RUN apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y \
    sudo git curl ffmpeg ca-certificates && \
    rm -rf /var/lib/apt/lists/*

# Create ubuntu user (UID/GID 1000 for volume compatibility)
RUN (getent group 1000 || groupadd -g 1000 ubuntu) && \
    (getent passwd 1000 || useradd -m -s /bin/bash -u 1000 -g 1000 ubuntu) && \
    echo "ubuntu ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/ubuntu && \
    chmod 0440 /etc/sudoers.d/ubuntu && \
    usermod -aG video ubuntu && \
    chown -R ubuntu:ubuntu /home/ubuntu

# Switch to ubuntu user
USER ubuntu
WORKDIR /home/ubuntu/app

# Install uv
RUN curl -LsSf https://astral.sh/uv/install.sh | sh

# Append to .bashrc (for interactive sessions)
RUN cat >> /home/ubuntu/.bashrc << 'EOF'

# Environment setup
export CUDA_HOME=/usr/local/cuda
export PATH=$CUDA_HOME/bin:$HOME/.local/bin:$PATH
export LD_LIBRARY_PATH=$CUDA_HOME/lib64:$LD_LIBRARY_PATH
EOF

RUN touch /home/ubuntu/.sudo_as_admin_successful

# Set ENV for non-interactive CMD
ENV CUDA_HOME=/usr/local/cuda
ENV PATH=$CUDA_HOME/bin:$HOME/.local/bin:$PATH
ENV LD_LIBRARY_PATH=$CUDA_HOME/lib64:$LD_LIBRARY_PATH

# Install Python 3.13
RUN /home/ubuntu/.local/bin/uv python install 3.13

# Copy files (Python file is mounted via docker-compose volume)
COPY --chown=ubuntu:ubuntu requirements.txt .
COPY --chown=ubuntu:ubuntu prebuilt-wheels/apex-*.whl ./prebuilt-wheels/
COPY --chown=ubuntu:ubuntu entrypoint.sh .

# Download flash-attn from prebuild repo (keep original filename with version)
RUN curl -L -o prebuilt-wheels/flash_attn-2.8.3+cu130torch2.9-cp313-cp313-linux_x86_64.whl \
  "https://github.com/mjun0812/flash-attention-prebuild-wheels/releases/download/v0.5.2/flash_attn-2.8.3%2Bcu130torch2.9-cp313-cp313-linux_x86_64.whl"

# Create venv and install deps
RUN /home/ubuntu/.local/bin/uv venv .venv --python 3.13 --seed && \
    . .venv/bin/activate && \
    /home/ubuntu/.local/bin/uv pip install -r requirements.txt && \
    /home/ubuntu/.local/bin/uv pip install ./prebuilt-wheels/flash_attn-*.whl && \
    /home/ubuntu/.local/bin/uv pip install ./prebuilt-wheels/apex-*.whl && \
    rm -rf ./prebuilt-wheels && \
    /home/ubuntu/.local/bin/uv cache clean

# Make entrypoint executable
RUN chmod +x entrypoint.sh

# App environment
ENV OPTIMIZE_FOR_SPEED=1
ENV CFG_SCALE=1.25
ENV MODELS_DIR=/home/ubuntu/app/models

# Models volume
VOLUME /home/ubuntu/app/models

EXPOSE 8880

CMD ["./entrypoint.sh"]
