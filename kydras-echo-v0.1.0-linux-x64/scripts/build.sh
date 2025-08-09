#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

echo "==> Checking deps"
command -v ffmpeg >/dev/null || { echo "Missing: ffmpeg (sudo apt install ffmpeg)"; exit 2; }
command -v python3 >/dev/null || { echo "Missing: python3"; exit 2; }
command -v node >/dev/null || { echo "Missing: node (install Node.js LTS)"; exit 2; }
command -v rustup >/dev/null || { echo "Missing: rustup (install from https://rustup.rs)"; exit 2; }

echo "==> Python venv + deps"
python3 -m venv .venv
source .venv/bin/activate
python -m pip install --upgrade pip wheel
pip install -e .
pip install fastapi uvicorn jinja2 python-multipart python-dotenv

echo "==> Quick GUI smoke (boot then stop)"
(uvicorn gui.app:app --host 127.0.0.1 --port 8000 >/dev/null 2>&1 & echo $! > /tmp/ke_gui.pid)
sleep 2 || true
kill "$(cat /tmp/ke_gui.pid 2>/dev/null)" 2>/dev/null || true

echo "==> Tauri CLI"
npm i -g @tauri-apps/cli >/dev/null

echo "==> Ensure Tauri scaffold"
if [ ! -d src-tauri ]; then
  tauri init --app-name "Kydras Echo" --identifier com.kydras.echo --ci \
    --before-dev-command "" --before-build-command "" \
    --dev-path "http://127.0.0.1:8000" --dist-dir "http://127.0.0.1:8000"
fi

echo "==> Minimize-to-tray main.rs"
cat > src-tauri/src/main.rs <<'RS'
#![cfg_attr(not(debug_assertions), windows_subsystem = "windows")]
use tauri::{CustomMenuItem, SystemTray, SystemTrayMenu, SystemTrayEvent, Manager, WindowEvent};

fn main() {
  let show = CustomMenuItem::new("show".to_string(), "Show");
  let hide = CustomMenuItem::new("hide".to_string(), "Hide");
  let quit = CustomMenuItem::new("quit".to_string(), "Quit");
  let tray_menu = SystemTrayMenu::new().add_item(show).add_item(hide).add_item(quit);
  let tray = SystemTray::new().with_menu(tray_menu);

  tauri::Builder::default()
    .system_tray(tray)
    .on_system_tray_event(|app, event| match event {
      SystemTrayEvent::MenuItemClick { id, .. } => match id.as_str() {
        "show" => { if let Some(w) = app.get_window("main") { let _ = w.show(); let _ = w.set_focus(); } }
        "hide" => { if let Some(w) = app.get_window("main") { let _ = w.hide(); } }
        "quit" => { std::process::exit(0); }
        _ => {}
      },
      _ => {}
    })
    .on_window_event(|e| {
      if let WindowEvent::CloseRequested { api, .. } = e.event() {
        api.prevent_close();
        let _ = e.window().hide(); // minimize to tray
      }
    })
    .run(tauri::generate_context!())
    .expect("error while running tauri application");
}
RS

echo "==> Build desktop"
cd src-tauri
cargo tauri build
cd ..

echo "==> DONE. Installers in: $ROOT/src-tauri/target/release/bundle/"
