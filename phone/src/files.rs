use anyhow::Result;
use std::{
    fs,
    io::Read,
    path::Path,
    time::UNIX_EPOCH,
};

pub fn ensure_recordings_dir(dir: &str) -> Result<()> {
    fs::create_dir_all(dir)?;
    Ok(())
}

pub fn random_wav_path(dir: &str) -> String {
    format!("{}/{}.wav", dir, random_hex())
}

fn random_hex() -> String {
    let mut buf = [0u8; 8];
    fs::File::open("/dev/urandom")
        .and_then(|mut f| f.read_exact(&mut buf))
        .ok();
    buf.iter().map(|b| format!("{:02x}", b)).collect()
}

pub struct RecordingInfo {
    pub name: String,
    pub size: u64,
    pub duration_secs: f64,
    pub recorded_at: i64,
}

pub fn list_recordings(dir: &str) -> Result<Vec<RecordingInfo>> {
    if !Path::new(dir).exists() {
        return Ok(vec![]);
    }

    let mut recordings: Vec<RecordingInfo> = fs::read_dir(dir)?
        .filter_map(|e| e.ok())
        .filter(|e| e.path().extension().map_or(false, |ext| ext == "wav"))
        .filter_map(|e| {
            let path = e.path();
            let name = e.file_name().to_string_lossy().to_string();
            let meta = fs::metadata(&path).ok()?;
            let size = meta.len();
            let recorded_at = meta.modified().ok()
                .and_then(|t| t.duration_since(UNIX_EPOCH).ok())
                .map(|d| d.as_secs() as i64)
                .unwrap_or(0);
            let duration_secs = wav_duration(&path);
            Some(RecordingInfo { name, size, duration_secs, recorded_at })
        })
        .collect();

    recordings.sort_by(|a, b| b.recorded_at.cmp(&a.recorded_at));
    Ok(recordings)
}

fn wav_duration(path: &Path) -> f64 {
    let Ok(reader) = hound::WavReader::open(path) else { return 0.0 };
    let spec = reader.spec();
    let frames = reader.len() / spec.channels as u32;
    frames as f64 / spec.sample_rate as f64
}
