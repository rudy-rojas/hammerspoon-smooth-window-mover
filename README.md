# Hammerspoon Smooth Window Mover

A smooth and elegant macOS window management tool that moves windows between desktops with beautiful horizontal slide animations.

![macOS](https://img.shields.io/badge/macOS-10.12+-blue)
![Hammerspoon](https://img.shields.io/badge/Hammerspoon-0.9.93+-green)
![License](https://img.shields.io/badge/license-MIT-blue)

## ✨ Features

- **Smooth Visual Transitions**: Windows slide horizontally before moving to the next desktop
- **Circular Navigation**: Seamlessly loop through all available desktops
- **Native macOS Integration**: Uses system `Ctrl + Arrow` transitions for authentic feel
- **Fast Alternative**: Quick movement options without visual effects
- **Lightweight**: Minimal resource usage

## 🎬 How It Works

When you trigger the hotkey:
1. **Window slides horizontally** by its own width (smooth animation)
2. **Desktop transition executes** using native macOS `Ctrl + Arrow`
3. **Window appears** in the new desktop at its original position
4. **Focus restored** automatically

## 🚀 Installation

### Step 1: Install Hammerspoon

#### Option A: Download from Website
1. Visit [hammerspoon.org](https://www.hammerspoon.org/)
2. Download the latest release
3. Move Hammerspoon.app to Applications folder
4. Launch Hammerspoon and grant necessary permissions

#### Option B: Using Homebrew
```bash
brew install --cask hammerspoon
```

### Step 2: Configure Hammerspoon

1. **Launch Hammerspoon** from Applications
2. **Grant permissions** when prompted:
   - Accessibility (required for window management)
   - Screen Recording (required for window snapshots)

### Step 3: Install the Script

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

4. **Verify Installation**
   - Try the keyboard shortcut: <kbd>⇧</kbd> + <kbd>⌃</kbd> + <kbd>⌥</kbd> + <kbd>⌘</kbd> + <kbd>→</kbd>
   - You should see your active window slide to the right and move to the next desktop

> 💡 **Pro Tip**: After making any changes to `init.lua`, always use **"Reload Config"** to apply the changes immediately.

## ⌨️ Default Keyboard Shortcuts

### Main Functions (WITH visual slide animation)
-Type on a keyboard: **<kbd>⇧</kbd> + <kbd>⌃</kbd> + <kbd>⌥</kbd> + <kbd>⌘</kbd> + <kbd>→</kbd>**: Move window to next desktop (slide right)
-Type on a keyboard **<kbd>⇧</kbd> + <kbd>⌃</kbd> + <kbd>⌥</kbd> + <kbd>⌘</kbd> + <kbd>←</kbd>**: Move window to previous desktop (slide left)

### Fast Functions (WITHOUT visual animation)
-Type on a keyboard **<kbd>⇧</kbd> + <kbd>⌃</kbd> + <kbd>⌥</kbd> + <kbd>⌘</kbd> + <kbd>↑</kbd>**: Quick move to next desktop
-Type on a keyboard **<kbd>⇧</kbd> + <kbd>⌃</kbd> + <kbd>⌥</kbd> + <kbd>⌘</kbd> + <kbd>↓</kbd>**: Quick move to previous desktop

## 🛠️ Customization

### Changing Keyboard Shortcuts

Edit the bottom section of `init.lua`:

```lua
-- Custom shortcuts example
hs.hotkey.bind({"shift", "ctrl"}, "right", function()
    moveWindowToNextDesktop()
end)

hs.hotkey.bind({"shift", "ctrl"}, "left", function()
    moveWindowToPrevDesktop()
end)
```

**Result**: <kbd>⇧</kbd> + <kbd>⌃</kbd> + <kbd>→</kbd> and <kbd>⇧</kbd> + <kbd>⌃</kbd> + <kbd>←</kbd>

### Adjusting Animation Speed

Modify the animation duration:

```lua
local SLIDE_ANIMATION_DURATION = 0.2
local FAST_ANIMATION_DURATION = 0.08
local DESKTOP_TRANSITION_DELAY = 0.05
local WINDOW_FOCUS_DELAY = 0.15
local ALERT_DELAY = 0.50
local ALERT_DURATION = 0.8
```


## 📋 Requirements

- **macOS 10.12+** (Sierra or later)
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
