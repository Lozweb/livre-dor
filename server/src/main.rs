use axum::{routing::get, Router};
use phone::PhoneState;
use std::sync::{Arc, RwLock};
use tokio::task;
use tower_http::services::{ServeDir, ServeFile};

mod api;

const FRONTEND_DIST: &str = "/home/julien/livre-dor/frontend/dist";

#[tokio::main]
async fn main() {
    let state = Arc::new(RwLock::new(PhoneState::Idle));
    let phone_state = Arc::clone(&state);

    task::spawn_blocking(move || {
        if let Err(e) = phone::run(phone_state) {
            eprintln!("phone error: {e}");
        }
    });

    let spa = ServeDir::new(FRONTEND_DIST)
        .fallback(ServeFile::new(format!("{FRONTEND_DIST}/index.html")));

    let app = Router::new()
        .route("/api/health", get(api::health::health))
        .route("/api/recordings", get(api::recordings::list))
        .route("/api/recordings/:name", get(api::recordings::stream))
        .route("/api/recordings/:name/download", get(api::recordings::download))
        .fallback_service(spa);

    let listener = tokio::net::TcpListener::bind("0.0.0.0:80").await.unwrap();
    println!("server listening on :80");
    axum::serve(listener, app).await.unwrap();
}
