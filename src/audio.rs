use anyhow::Result;
use cpal::traits::{DeviceTrait, HostTrait, StreamTrait};
use hound::{WavSpec, WavWriter};
use rppal::gpio::{InputPin, Level};
use std::{
    sync::{
        atomic::{AtomicBool, Ordering},
        Arc,
    },
    thread,
    time::Duration,
};

pub fn play(path: &str, button: &InputPin) -> Result<bool> {
    use rodio::{Decoder, OutputStream, Sink};
    use std::fs::File;
    use std::io::BufReader;

    let (_stream, stream_handle) = OutputStream::try_default()?;
    let sink = Sink::try_new(&stream_handle)?;

    let file = BufReader::new(File::open(path)?);
    let source = Decoder::new(file)?;
    sink.append(source);

    let mut last = button.read();

    while !sink.empty() {
        let current = button.read();
        if is_rising_edge(current, last) {
            sink.stop();
            return Ok(true);
        }
        last = current;
        thread::sleep(Duration::from_millis(50));
    }

    Ok(false)
}

pub fn record_until_button(path: &str, button: &InputPin) -> Result<()> {
    let host = cpal::default_host();
    let device = host
        .input_devices()?
        .next()
        .ok_or_else(|| anyhow::anyhow!("Aucun micro détecté"))?;

    let supported = device.default_input_config()?;
    let actual_rate = supported.sample_rate().0;
    let actual_channels = supported.channels();

    println!("Micro : {} ({}Hz, {} canaux)", device.name().unwrap_or_default(), actual_rate, actual_channels);

    let config = cpal::StreamConfig {
        channels: actual_channels,
        sample_rate: cpal::SampleRate(actual_rate),
        buffer_size: cpal::BufferSize::Default,
    };

    let spec = WavSpec {
        channels: actual_channels,
        sample_rate: actual_rate,
        bits_per_sample: 16,
        sample_format: hound::SampleFormat::Int,
    };

    let writer = Arc::new(std::sync::Mutex::new(Some(WavWriter::create(path, spec)?)));
    let writer_clone = Arc::clone(&writer);
    let recording = Arc::new(AtomicBool::new(true));
    let recording_clone = Arc::clone(&recording);

    let stream = device.build_input_stream(
        &config,
        move |data: &[i16], _| {
            if !recording_clone.load(Ordering::Relaxed) {
                return;
            }
            if let Ok(mut guard) = writer_clone.lock() {
                if let Some(ref mut w) = *guard {
                    for &sample in data {
                        let _ = w.write_sample(sample);
                    }
                }
            }
        },
        |e| eprintln!("Erreur stream audio : {}", e),
        None,
    )?;

    stream.play()?;

    let mut last = button.read();
    loop {
        let current = button.read();
        if is_rising_edge(current, last) {
            break;
        }
        last = current;
        thread::sleep(Duration::from_millis(50));
    }

    recording.store(false, Ordering::Relaxed);
    drop(stream);

    if let Ok(mut guard) = writer.lock() {
        if let Some(w) = guard.take() {
            w.finalize()?;
        }
    }

    Ok(())
}

fn is_rising_edge(current: Level, last: Level) -> bool {
    current == Level::Low && last == Level::High
}
