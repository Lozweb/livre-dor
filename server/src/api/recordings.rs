use axum::{
    extract::{Path, Request},
    http::{header::CONTENT_DISPOSITION, StatusCode},
    response::{IntoResponse, Response},
    Json,
};
use serde::Serialize;
use std::path::PathBuf;
use tower::util::ServiceExt;
use tower_http::services::ServeFile;

#[derive(Serialize)]
pub struct RecordingDto {
    name: String,
    size: u64,
    duration_secs: f64,
    recorded_at: i64,
}

impl From<phone::RecordingInfo> for RecordingDto {
    fn from(r: phone::RecordingInfo) -> Self {
        Self {
            name: r.name,
            size: r.size,
            duration_secs: r.duration_secs,
            recorded_at: r.recorded_at,
        }
    }
}

fn safe_path(name: &str) -> Option<PathBuf> {
    if name.contains('/') || name.contains('\\') || name.contains("..") {
        return None;
    }
    if !name.ends_with(".wav") {
        return None;
    }
    let path = PathBuf::from(phone::RECORDINGS_DIR).join(name);
    path.starts_with(phone::RECORDINGS_DIR).then_some(path)
}

pub async fn list() -> Response {
    match phone::list_recordings(phone::RECORDINGS_DIR) {
        Ok(recordings) => {
            let dtos: Vec<RecordingDto> = recordings.into_iter().map(RecordingDto::from).collect();
            Json(dtos).into_response()
        }
        Err(_) => StatusCode::INTERNAL_SERVER_ERROR.into_response(),
    }
}

pub async fn stream(Path(name): Path<String>, request: Request) -> Response {
    let Some(path) = safe_path(&name) else {
        return StatusCode::BAD_REQUEST.into_response();
    };
    ServeFile::new(path)
        .oneshot(request)
        .await
        .map(IntoResponse::into_response)
        .unwrap_or_else(|_| StatusCode::NOT_FOUND.into_response())
}

pub async fn download(Path(name): Path<String>, request: Request) -> Response {
    let Some(path) = safe_path(&name) else {
        return StatusCode::BAD_REQUEST.into_response();
    };
    let mut response = match ServeFile::new(path).oneshot(request).await {
        Ok(res) => res.into_response(),
        Err(_) => return StatusCode::NOT_FOUND.into_response(),
    };
    if let Ok(value) = format!("attachment; filename=\"{}\"", name).parse() {
        response.headers_mut().insert(CONTENT_DISPOSITION, value);
    }
    response
}
