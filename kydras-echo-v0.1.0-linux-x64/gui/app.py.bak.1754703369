from fastapi import FastAPI, Request, UploadFile, Form
from fastapi.responses import HTMLResponse, StreamingResponse
from fastapi.staticfiles import StaticFiles
from jinja2 import Environment, FileSystemLoader, select_autoescape
import asyncio, pathlib, uuid

APP_DIR = pathlib.Path(__file__).parent.resolve()
env = Environment(loader=FileSystemLoader(str(APP_DIR / "templates")),
                  autoescape=select_autoescape(["html","xml"]))
app = FastAPI(title="Kydras Echo")
app.mount("/static", StaticFiles(directory=str(APP_DIR/"static")), name="static")

@app.get("/", response_class=HTMLResponse)
def index():
    return env.get_template("index.html").render()

@app.post("/run", response_class=StreamingResponse)
async def run(media_url: str = Form(""), file: UploadFile|None = None):
    async def streamer():
        jid = uuid.uuid4().hex[:8]
        yield f"JOB:{jid}\n"
        for p in (10,30,60,80,100):
            await asyncio.sleep(0.35)
            yield f"PROGRESS:{p}\n"
        yield "DONE\n"
    return StreamingResponse(streamer(), media_type="text/plain")

from fastapi.responses import RedirectResponse

@app.get("/", include_in_schema=False)
async def _root_redirect():
    return RedirectResponse(url="/gui", status_code=307)
