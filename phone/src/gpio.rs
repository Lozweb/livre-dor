use anyhow::Result;
use rppal::gpio::{Gpio, InputPin, Level, OutputPin};

pub struct Buttons {
    pub button: InputPin,
}

pub struct Leds {
    pub led: OutputPin,
}

pub fn init(gpio_led: u8, gpio_button: u8) -> Result<(Leds, Buttons)> {
    let gpio = Gpio::new()?;
    let led = gpio.get(gpio_led)?.into_output();
    let button = gpio.get(gpio_button)?.into_input_pullup();
    Ok((Leds { led }, Buttons { button }))
}

// Décrocher : le combiné quitte le socle, le circuit se ferme (High -> Low)
pub fn a_decroche(current: Level, last: Level) -> bool {
    current == Level::Low && last == Level::High
}
