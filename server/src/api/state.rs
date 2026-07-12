use axum::{extract::State, Json};
use phone::PhoneState;
use serde::Serialize;
use std::sync::{Arc, RwLock};

#[derive(Serialize)]
pub struct StateDto {
    state: &'static str,
}

pub async fn get_state(State(phone_state): State<Arc<RwLock<PhoneState>>>) -> Json<StateDto> {
    let state = phone_state.read().unwrap().clone();
    Json(StateDto {
        state: match state {
            PhoneState::Idle => "idle",
            PhoneState::PlayingIntro => "playing_intro",
            PhoneState::Recording => "recording",
        },
    })
}
