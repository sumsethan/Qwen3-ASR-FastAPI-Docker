FROM nvidia/cuda:11.8.0-runtime-ubuntu22.04
WORKDIR /app

# 设置环境变量
ENV PYTHONPATH=/app:/app/src
ENV DEBIAN_FRONTEND=noninteractive

# 安装系统依赖：额外加入 python3-dev 和 build-essential
# 这让 runtime 镜像具备编译 nagisa/soynlp 等 C++ 扩展的能力，同时避免引入几 GB 大小的完整 cuda-devel
RUN apt-get update && apt-get install -y \
    python3 python3-pip python3-dev build-essential \
    ffmpeg libsndfile1 git \
    && rm -rf /var/lib/apt/lists/*

# 第一步：优先、单独安装兼容 Pascal 架构的 Torch 核心环境
# 强行锁定使用 cu118 源，防止污染
RUN pip3 install --no-cache-dir torch==2.4.0 torchaudio==2.4.0 --index-url https://download.pytorch.org/whl/cu118

# 第二步：复制并安装其余业务依赖
# 由于环境内已有 torch，遇到 accelerate 等包时 pip 会直接跳过 torch 的拉取
COPY requirements.txt .
RUN pip3 install --no-cache-dir -r requirements.txt

# 第三步：复制业务代码
COPY qwen_asr /app/qwen_asr
COPY src /app/src

EXPOSE 8000
CMD ["uvicorn", "stt_service.main:app", "--host", "0.0.0.0", "--port", "8000"]
