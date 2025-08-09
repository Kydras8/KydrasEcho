import argparse
import sys
from uvicorn import run

def main():
    p = argparse.ArgumentParser(prog="kydras-echo", description="Launch Kydras Echo (FastAPI/Uvicorn)")
    p.add_argument("--app", default="gui.app:app", help="ASGI import string (module:var) [default: %(default)s]")
    p.add_argument("--host", default="0.0.0.0", help="Bind address [default: %(default)s]")
    p.add_argument("--port", type=int, default=8000, help="Port [default: %(default)d]")
    p.add_argument("--reload", dest="reload", action="store_true", help="Enable reload (dev)")
    p.add_argument("--no-reload", dest="reload", action="store_false", help="Disable reload")
    p.set_defaults(reload=True)  # default: reload ON
    p.add_argument("--workers", type=int, default=None, help="Number of workers (incompatible with --reload)")
    p.add_argument("--log-level", choices=["critical","error","warning","info","debug","trace"], default="info",
                   help="Log level [default: %(default)s]")
    p.add_argument("--root-path", default=None, help="ASGI root_path (e.g., when behind a reverse proxy)")
    p.add_argument("--proxy-headers", action="store_true", help="Trust proxy headers (X-Forwarded-*)")
    p.add_argument("--env-file", default=None, help="Path to .env file to load before start")
    args = p.parse_args()

    # Guard: workers vs reload
    if args.workers and args.reload:
        print("[kydras-echo] --workers cannot be used with --reload. Use --no-reload or omit --workers.", file=sys.stderr)
        sys.exit(2)

    # Let uvicorn handle the import string for reload correctness
    run(
        app=args.app,
        host=args.host,
        port=args.port,
        reload=bool(args.reload),
        workers=args.workers,
        log_level=args.log_level,
        root_path=args.root_path,
        proxy_headers=args.proxy_headers,
        env_file=args.env_file,
    )

if __name__ == "__main__":
    main()
