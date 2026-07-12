use axum::{routing::get, Json, Router};
use phone::PhoneState;
use std::sync::{Arc, RwLock};
use tokio::task;

#[tokio::main]
async fn main() {
    let state = Arc::new(RwLock::new(PhoneState::Idle));
    let phone_state = Arc::clone(&state);

    task::spawn_blocking(move || {
        if let Err(e) = phone::run(phone_state) {
            eprintln!("phone error: {e}");
        }
    });

    let app = Router::new().route("/api/health", get(health));

    let listener = tokio::net::TcpListener::bind("0.0.0.0:8080").await.unwrap();
    println!("server listening on :8080");
    axum::serve(listener, app).await.unwrap();
}

async fn health() -> Json<serde_json::Value> {
    Json(serde_json::json!({ "ok": true }))
}
