use anyhow::Result;
use rppal::gpio::Level;
use std::{
    sync::{Arc, RwLock},
    thread,
    time::Duration,
};

mod audio;
mod files;
mod gpio;

pub use files::{list_recordings, RecordingInfo};

pub const GPIO_LED: u8 = 17;
pub const GPIO_BUTTON: u8 = 27;
pub const RECORDINGS_DIR: &str = "/home/julien/recordings";
pub const INTRO_AUDIO: &str = "/home/julien/livre-dor/intro.wav";

#[derive(Debug, Clone, PartialEq)]
pub enum PhoneState {
    Idle,
    PlayingIntro,
    Recording,
}

pub fn run(state: Arc<RwLock<PhoneState>>) -> Result<()> {
    files::ensure_recordings_dir(RECORDINGS_DIR)?;

    let (mut leds, buttons) = gpio::init(GPIO_LED, GPIO_BUTTON)?;
    leds.led.set_high();

    println!("Livre d'or prêt.");

    // Au démarrage, le téléphone est raccroché (circuit ouvert = High)
    let mut last_button = Level::High;

    loop {
        let current_button = buttons.button.read();
        let decroche = gpio::a_decroche(current_button, last_button);

        let current = state.read().unwrap().clone();
        match current {
            PhoneState::Idle => {
                if decroche {
                    println!("Téléphone décroché → lecture de l'intro");
                    leds.led.set_low();
                    *state.write().unwrap() = PhoneState::PlayingIntro;
                }
            }
            PhoneState::PlayingIntro => {
                let interrupted = audio::play(INTRO_AUDIO, &buttons.button)?;
                leds.led.set_high();
                if interrupted {
                    println!("Téléphone raccroché pendant l'intro → retour en attente");
                    *state.write().unwrap() = PhoneState::Idle;
                } else {
                    println!("Intro terminée → début de l'enregistrement");
                    *state.write().unwrap() = PhoneState::Recording;
                }
            }
            PhoneState::Recording => {
                let path = files::random_wav_path(RECORDINGS_DIR);
                println!("Enregistrement en cours... Parlez après le bip.");
                audio::record_until_button(&path, &buttons.button)?;
                println!("Téléphone raccroché → Enregistrement sauvegardé");
                leds.led.set_high();
                *state.write().unwrap() = PhoneState::Idle;
            }
        }

        last_button = buttons.button.read();
        thread::sleep(Duration::from_millis(50));
    }
}
