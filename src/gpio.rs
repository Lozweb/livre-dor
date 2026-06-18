use anyhow::Result;
use rppal::gpio::{Gpio, InputPin, Level, OutputPin};
use std::{thread, time::Duration};

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

pub fn is_rising_edge(current: Level, last: Level) -> bool {
    current == Level::Low && last == Level::High
}

pub fn wait_for_release(button: &InputPin) {
    while button.read() == Level::Low {
        thread::sleep(Duration::from_millis(50));
    }
    thread::sleep(Duration::from_millis(300));
}
