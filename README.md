# Hammerspoon Smooth Window Mover V1.5


A powerful macOS automation script for **Hammerspoon** that combines:
- **Workspace Switcher** (`Ctrl + 1–9`) – Jump instantly to a specific desktop/space with visual feedback.
- **Window Mover** (`⇧⌃⌥⌘ + ←/→`) – Move the focused window between desktops with smooth animations and bounce effects.


![macOS](https://img.shields.io/badge/macOS-13.7+-blue)
![Hammerspoon](https://img.shields.io/badge/Hammerspoon-0.9.93+-green)
![License](https://img.shields.io/badge/cliclick-5.0.1-yellow)
![License](https://img.shields.io/badge/license-MIT-blue)

## ✨ Features

- **Dual Functionality**: Workspace switching + window moving in one script.
- **Multi-Monitor Support**: Detects and organizes spaces per monitor.
- **Smooth Visual Alerts**: Overlay notifications for both workspace and window actions.
- **Shortcut Health Check**: Detects if macOS Mission Control shortcuts are disabled and opens System Preferences automatically.
- **Customizable Keys**: Easily change hotkey combinations in the script.


## 🚀 Installation

### 1. Install Hammerspoon
Download from [hammerspoon.org](https://www.hammerspoon.org/) and move it to your **Applications** folder.

### 2. Install `cliclick` (MacPorts)
Required for window dragging compatibility on macOS Ventura and later:
```bash
sudo port install cliclick
``` 

### 3. Configure Hammerspoon
Open the Hammerspoon config folder:
Replace or append the contents of ~/.hammerspoon/init.lua with the script from this repository.
Reload Hammerspoon:

1. **Launch Hammerspoon** from Applications
2. **Grant permissions** when prompted:
   - Accessibility (required for window management)
   - Screen Recording (required for window snapshots)

### 4: Install the Script

1. **Open Hammerspoon Configuration Directory**
   - Click the Hammerspoon icon in the menu bar
   - Select **"Open Config"** from the dropdown menu
   - This will open your `~/.hammerspoon/init.lua`

2. **Edit Configuration File**
   - **Copy the entire script** from this repository's `init.lua` file
   - **Paste it** into your `init.lua` file
   - **Save the file** (<kbd>⌘</kbd> + <kbd>S</kbd>)

3. **Reload Hammerspoon Configuration**
   - Click the Hammerspoon icon in the menu bar
   - Select **"Reload Config"** from the dropdown menu

> 💡 **Pro Tip**: After making any changes to `init.lua`, always use **"Reload Config"** to apply the changes immediately.

## ⌨️ Keyboard Shortcuts

### Changing Keyboard Shortcuts

Edit the bottom section of `init.lua`:

```lua
-- Custom shortcuts example
-- local WINDOW_MOVER_MODIFIERS = {"shift", "ctrl", "alt", "cmd"} --DEFAULT
-- local WINDOW_MOVER_MODIFIERS = {"shift", "ctrl"} -- example
local WINDOW_MOVER_MODIFIERS = {"shift", "ctrl", "alt", "cmd"}
showAlert = true
```


## 📋 Requirements

- **macOS 13 (Ventura or later) (tested in 13.7.6)
- **Hammerspoon 0.9.93+**
- **Multiple Desktops/Spaces** configured in System Preferences
- **Accessibility permissions** for Hammerspoon

## 🔧 Troubleshooting

### Script Not Working

1. **Restart Hammerspoon** completely (Quit and relaunch)
2. **Verify permissions**: System Preferences → Security & Privacy → Privacy → Accessibility
3. **Reload configuration**: Hammerspoon menu → Reload Config
4. **Test with simple window**: Try with TextEdit or similar basic app

## 🎯 Use Cases

- **Developers**: Quickly organize code editors across workspaces
- **Designers**: Move design tools between project spaces
- **Productivity**: Separate work and personal applications
- **Multitasking**: Organize windows by task or context

## 🤝 Contributing

Contributions are welcome! Please feel free to:

1. **Report bugs** via GitHub Issues
2. **Suggest features** or improvements
3. **Submit pull requests** with enhancements
4. **Share your customizations** with the community

## 📝 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- **Hammerspoon Team** for the amazing automation framework
- **macOS Community** for inspiration and feedback
- **Contributors** who help improve this tool

## 📞 Support

- **GitHub Issues**: Report bugs and request features
- **Hammerspoon Docs**: [Official Documentation](https://www.hammerspoon.org/docs/)
- **Community**: [Hammerspoon GitHub](https://github.com/Hammerspoon/hammerspoon)

---

**Made with ❤️ for the macOS community**

*Smooth window management for a better desktop experience*
