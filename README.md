# BotMonitor

**TODO: Add description**

## Disclaimer
The binary executable provided for BotMonitor is distributed "as is" without any warranties or guarantees of any kind, either express or implied. By downloading and using this executable, you agree to the following:

1. **No Warranty:**
   The executable is provided without any warranty of fitness for a particular purpose, reliability, or accuracy. Use it at your own risk.

2. **Liability:**
   The author(s) of this project are not responsible for any damage, data loss, or other issues that may arise from the use of this software.

3. **Security:**
   Ensure you download the executable only from this official repository. The author(s) are not responsible for any modified or malicious versions of the executable obtained from other sources.

4. **Usage:**
   This software is intended for personal or educational use. Ensure compliance with all applicable laws and regulations when using this software.

## Contributing

We welcome contributions to the **BotMonitor** project! To ensure a smooth development experience, we use **Dev Containers**, **Visual Studio Code**, and **Docker Desktop** as our primary development tools. Below are the details and steps to get started:

### Why Dev Containers?
Dev Containers provide a consistent and reproducible development environment. By using Dev Containers, contributors can:
- Avoid "it works on my machine" issues.
- Quickly set up the development environment without manual configuration.
- Ensure compatibility with the project's dependencies and tools.

### Requirements
To contribute to this project, you will need the following:
1. **Visual Studio Code**: The primary IDE for this project. Download it from [here](https://code.visualstudio.com/).
2. **Docker Desktop**: Required to run the Dev Container. Download it from [here](https://www.docker.com/products/docker-desktop).
3. **Dev Containers Extension**: Install the [Dev Containers extension](https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.remote-containers) in Visual Studio Code.

### Getting Started
1. Clone the repository:
   ```bash
   git clone https://github.com/shayne-saw/bot_monitor.git
   cd bot_monitor
   ```

2. Open the project in Visual Studio Code.

3. When prompted, reopen the project in the Dev Container. If not prompted, you can manually reopen it:
   - Press `Ctrl+Shift+P` (or `Cmd+Shift+P` on macOS) to open the Command Palette.
   - Search for and select `Dev Containers: Reopen in Container`.

4. Once the container is built and running, install the project dependencies:
   ```bash
   mix deps.get
   ```

5. You're now ready to contribute! Make your changes, test them, and submit a pull request.

### Additional Notes
- Ensure your code follows the project's coding standards and passes all tests before submitting a pull request.
- If you encounter any issues with the Dev Container setup, refer to the [Dev Containers documentation](https://containers.dev/) or reach out to the maintainers.

We appreciate your contributions and look forward to collaborating with you!

## Building

```
asdf install zig latest
asdf global zig latest
MIX_ENV=prod mix release

```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at <https://hexdocs.pm/bot_monitor>.

