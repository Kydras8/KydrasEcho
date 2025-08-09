#![cfg_attr(not(debug_assertions), windows_subsystem = "windows")]

use tauri::{Manager, WindowEvent};
use tauri::menu::{Menu, MenuItemBuilder};
use tauri::tray::TrayIconBuilder;

fn main() {
  tauri::Builder::default()
    .setup(|app| {
      // Build tray menu (v2 API; needs "tray-icon" feature)
      let show = MenuItemBuilder::with_id("show", "Show").build(app)?;
      let hide = MenuItemBuilder::with_id("hide", "Hide").build(app)?;
      let quit = MenuItemBuilder::with_id("quit", "Quit").build(app)?;
      let menu = Menu::with_items(app, &[&show, &hide, &quit])?;

      // Tray with event handler
      let _tray = TrayIconBuilder::new()
        .menu(&menu)
        .on_menu_event(|app, event| {
          match event.id().as_ref() {
            "show" => {
              if let Some(w) = app.get_webview_window("main") {
                let _ = w.show();
                let _ = w.set_focus();
              }
            }
            "hide" => {
              if let Some(w) = app.get_webview_window("main") {
                let _ = w.hide();
              }
            }
            "quit" => std::process::exit(0),
            _ => {}
          }
        })
        .build(app)?;

      Ok(())
    })
    .on_window_event(|window, event| {
      if let WindowEvent::CloseRequested { api, .. } = event {
        // minimize-to-tray
        api.prevent_close();
        let _ = window.hide();
      }
    })
    .run(tauri::generate_context!())
    .expect("error while running tauri application");
}
