cat > README.md <<'EOF'
# 🎙️ Kydras Echo  
[![GitHub release (latest by date)](https://img.shields.io/github/v/release/Kydras8/KydrasEcho?label=Latest%20Release&style=for-the-badge)](https://github.com/Kydras8/KydrasEcho/releases/latest)
[![GitHub all releases](https://img.shields.io/github/downloads/Kydras8/KydrasEcho/total?style=for-the-badge)](https://github.com/Kydras8/KydrasEcho/releases)
[![License](https://img.shields.io/github/license/Kydras8/KydrasEcho?style=for-the-badge)](LICENSE)

> **Transcribe videos into text, PDF, or MP3 — quickly and locally.**

---

## 🚀 Features
- 🎯 **Multi-format export** — `.txt`, `.pdf`, `.mp3`
- ⚡ **Fast transcription** using `faster-whisper` (offline, local)
- 🎨 **Branded GUI** with Kydras logo
- 🖥️ **Web & API access** via FastAPI
- 🔒 **Private** — all processing happens locally
- 🛠 **Cross-platform** (Linux, Windows via WSL, macOS)

---

## 📥 Quick Install

```bash
# 1) Download latest release
wget https://github.com/Kydras8/KydrasEcho/releases/latest/download/kydras-echo-v0.1.2-linux-x64.tar.gz

# 2) Extract
tar -xvzf kydras-echo-v0.1.2-linux-x64.tar.gz
cd kydras-echo-v0.1.2-linux-x64

# 3) Install dependencies & run
bash install.sh
./run.sh
