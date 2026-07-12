use anyhow::Result;
use phone::PhoneState;
use std::sync::{Arc, RwLock};

fn main() -> Result<()> {
    phone::run(Arc::new(RwLock::new(PhoneState::Idle)))
}
