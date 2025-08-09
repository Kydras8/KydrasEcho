from fastapi import FastAPI, UploadFile, File, Form, Request
from fastapi.responses import HTMLResponse, FileResponse, JSONResponse
from fastapi.staticfiles import StaticFiles
from fastapi.middleware.cors import CORSMiddleware
from fastapi.templating import Jinja2Templates
from faster_whisper import WhisperModel
from fpdf import FPDF
import tempfile, os, uuid, pathlib, subprocess, shutil

APP_ROOT = pathlib.Path(__file__).resolve().parent
OUT_DIR  = APP_ROOT / "outputs"
OUT_DIR.mkdir(parents=True, exist_ok=True)

app = FastAPI(title="Kydras Echo")
app.add_middleware(CORSMiddleware, allow_origins=["*"], allow_methods=["*"], allow_headers=["*"])
app.mount("/static", StaticFiles(directory=str(APP_ROOT / "static")), name="static")
templates = Jinja2Templates(directory=str(APP_ROOT / "templates"))

@app.get("/", response_class=HTMLResponse, include_in_schema=False)
def index(req: Request): return templates.TemplateResponse("index.html", {"request": req})

@app.get("/health", include_in_schema=False)
def health(): return {"ok": True}

def _ffmpeg(*args):
    subprocess.run(["ffmpeg","-hide_banner","-loglevel","error", *args], check=True)

def export_pdf(text: str, out_pdf: str):
    pdf = FPDF(); pdf.set_auto_page_break(True, 15); pdf.add_page(); pdf.set_font("Arial", size=12)
    for line in (text.splitlines() or [""]): pdf.multi_cell(0, 8, line)
    pdf.output(out_pdf)

@app.post("/api/transcribe")
def transcribe(media: UploadFile = File(...),
               output_format: str = Form(...),  # txt|pdf|mp3
               model_size: str = Form("base")):  # tiny|base|small|medium|large-v3
    job = uuid.uuid4().hex[:8]
    tmp = pathlib.Path(tempfile.mkdtemp(prefix=f"echo_{job}_"))
    src = tmp / media.filename
    src.write_bytes(media.file.read())
    try:
        if output_format.lower() == "mp3":
            out = OUT_DIR / f"{src.stem}_{job}.mp3"
            _ffmpeg("-y","-i",str(src),"-vn","-acodec","libmp3lame","-b:a","192k",str(out))
            return {"ok": True, "output": f"/download/{out.name}", "job_id": job}

        wav = tmp / "audio.wav"
        _ffmpeg("-y","-i",str(src),"-ac","1","-ar","16000","-vn",str(wav))

        model = WhisperModel(model_size, compute_type="int8")
        segments, info = model.transcribe(str(wav), vad_filter=True)
        text = "\n".join([s.text.strip() for s in segments if s.text.strip()])

        base = f"{src.stem}_{job}"
        if output_format.lower() == "txt":
            out = OUT_DIR / f"{base}.txt"; out.write_text(text, encoding="utf-8")
            return {"ok": True, "output": f"/download/{out.name}", "job_id": job}
        elif output_format.lower() == "pdf":
            out = OUT_DIR / f"{base}.pdf"; export_pdf(text, str(out))
            return {"ok": True, "output": f"/download/{out.name}", "job_id": job}
        else:
            return JSONResponse({"ok": False, "error": "bad format"}, status_code=400)
    except subprocess.CalledProcessError as e:
        return JSONResponse({"ok": False, "error": "ffmpeg failed", "detail": str(e)}, status_code=500)
    except Exception as e:
        return JSONResponse({"ok": False, "error": str(e)}, status_code=500)
    finally:
        shutil.rmtree(tmp, ignore_errors=True)

@app.get("/download/{name}", include_in_schema=False)
def download(name: str):
    p = OUT_DIR / name
    return FileResponse(str(p), filename=p.name) if p.exists() else JSONResponse({"ok": False, "error": "not found"}, 404)
