use anyhow::Result;
use chrono::Local;
use std::fs;

pub fn ensure_recordings_dir(dir: &str) -> Result<()> {
    fs::create_dir_all(dir)?;
    Ok(())
}

pub fn timestamped_wav_path(dir: &str) -> String {
    format!("{}/{}.wav", dir, Local::now().format("%Y%m%d_%H%M%S"))
}
