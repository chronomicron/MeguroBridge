# MeguroBridge

MeguroBridge is a shell script for Raspberry Pi that turns your Pi into a Wi-Fi repeater. 
It connects to a public Wi-Fi (via the built-in wireless adapter) and rebroadcasts it as a private hotspot using a USB Wi-Fi dongle.

## 🛠️ Features

- Works on Raspberry Pi 5 running Raspbian (Debian-based)
- Bridges internal and USB Wi-Fi interfaces
- Creates a persistent private Wi-Fi network (`Meguro`)
- Step-by-step progress feedback in the terminal
- Minimal user interaction

## 📦 Requirements

- Raspberry Pi 5 running Raspbian
- One USB Wi-Fi dongle
- Internet access for initial setup

## 🚀 Installation & Usage

1. Clone this repository:
    ```bash
    git clone https://github.com/yourusername/MeguroBridge.git
    cd MeguroBridge
    ```

2. Run the setup script:
    ```bash
    chmod +x setup.sh
    ./setup.sh
    ```

3. Follow on-screen instructions to connect to a public Wi-Fi and start your private hotspot.

## 🔒 Security

Make sure to set a secure password for your private Wi-Fi network in the setup process.

## 📖 License

MIT License
