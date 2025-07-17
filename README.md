# sofortcraft

🧱 Instantly Download and Run Vanilla Minecraft Servers in Docker

`sofortcraft` is a simple command-line tool that allows you to instantly download and run official **Vanilla Minecraft Java servers** in Docker — always with the correct Java version for the selected Minecraft version.

---

## 🔧 Installation via Homebrew (macOS & Linux)

First, tap the repository:

```bash
brew tap <your-github-username>/sofortcraft
```

Then install:

```bash
brew install sofortcraft
```

> **Note:** Make sure Docker is installed and running.  
> You also need `bash`, `curl`, and `jq` (all are available via Homebrew).

---

## 🚀 Usage

### Start a server

```bash
sofortcraft -v <minecraft-version> <target-directory>
```

Example:

```bash
sofortcraft -v 1.8 ./server-1.8
```

This will:

- Download the correct `minecraft_server.<version>.jar`
- Accept the EULA
- Launch the server in a Docker container
- Use the correct Java version for that Minecraft version
- Expose port `25565` and store data in the specified directory

---

## 📦 Commands

| Command                            | Description                                      |
| ---------------------------------- | ------------------------------------------------ |
| `sofortcraft -v 1.20.5 ./myserver` | Start a new server for version 1.20.5            |
| `sofortcraft --status`             | List running Minecraft containers                |
| `sofortcraft --logs 1.20.5`        | Follow logs for the container `minecraft-1.20.5` |
| `sofortcraft --remove 1.20.5`      | Stop and delete the container                    |

---

## 🧠 Java Version Mapping

`sofortcraft` automatically selects the correct Java image:

| Minecraft Version  | Java Docker Image    |
| ------------------ | -------------------- |
| `1.21.x` and above | `eclipse-temurin:21` |
| `1.20.5`           | `eclipse-temurin:21` |
| `1.17` – `1.20.4`  | `openjdk:17`         |
| `< 1.17`           | `openjdk:8-jdk`      |

---

## 🐳 Requirements

- Docker
- Bash (Linux/macOS or WSL2 on Windows)
- `curl`
- `jq`

---

## 🗃 Data Storage

All world data, configuration files, and logs are stored in the directory you provide. For example:

```bash
sofortcraft -v 1.8 ./server-1.8
```

Stores everything in `./server-1.8`.

---

## 🖥 Platform Support

| OS      | Status       | Notes                                    |
| ------- | ------------ | ---------------------------------------- |
| macOS   | ✅ Supported | with Homebrew and Docker                 |
| Linux   | ✅ Supported | with Homebrew or manual                  |
| Windows | ⚠️ via WSL2  | Full support using WSL2 + Docker Desktop |

---

## 🛣 Roadmap

Planned features:

- Support for modded servers (Forge, Fabric, Paper)
- Custom RAM allocation (`--ram 2G`)
- Auto-port detection if 25565 is in use
- Update checker

---

## 📄 License

MIT License — free to use, modify, and share.

---

## 🙌 Contributing

Pull requests are welcome. If you have suggestions or find bugs, feel free to open an issue.
