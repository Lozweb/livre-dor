use anyhow::Result;
use rppal::gpio::Level;
use std::{thread, time::Duration};

mod audio;
mod files;
mod gpio;

const GPIO_LED: u8 = 17;
const GPIO_BUTTON: u8 = 27;
const RECORDINGS_DIR: &str = "/home/julien/recordings";
const INTRO_AUDIO: &str = "/home/julien/livre-dor/intro.wav";

enum State {
    Idle,
    PlayingIntro,
    Recording,
}

fn main() -> Result<()> {
    files::ensure_recordings_dir(RECORDINGS_DIR)?;

    let (mut leds, buttons) = gpio::init(GPIO_LED, GPIO_BUTTON)?;
    leds.led.set_high();

    println!("Livre d'or prêt.");

    let mut state = State::Idle;
    // Au démarrage, le téléphone est normalement raccroché (circuit ouvert = High)
    let mut last_button = Level::High;

    loop {
        let current_button = buttons.button.read();
        // On vérifie si l'utilisateur vient de décrocher le combiné
        let decroche = gpio::a_decroche(current_button, last_button);

        match state {
            State::Idle => {
                if decroche {
                    println!("Téléphone décroché → lecture de l'intro");
                    leds.led.set_low();
                    state = State::PlayingIntro;
                }
            }
            State::PlayingIntro => {
                let interrupted = audio::play(INTRO_AUDIO, &buttons.button)?;
                leds.led.set_high();
                if interrupted {
                    println!("Téléphone raccroché pendant l'intro → retour en attente");
                    state = State::Idle;
                } else {
                    println!("Intro terminée → début de l'enregistrement");
                    state = State::Recording;
                }
            }
            State::Recording => {
                let path = files::timestamped_wav_path(RECORDINGS_DIR);
                println!("Enregistrement en cours... Parlez après le bip.");
                audio::record_until_button(&path, &buttons.button)?;
                println!("Téléphone raccroché → Enregistrement sauvegardé");
                leds.led.set_high();
                state = State::Idle;
            }
        }

        // On rafraîchit l'état réel pour éviter le décalage de détection au prochain tour
        last_button = buttons.button.read();
        thread::sleep(Duration::from_millis(50));
    }
}