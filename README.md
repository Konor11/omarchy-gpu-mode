# omarchy-gpu-mode

Three-state GPU switcher bar widget for Omarchy on Hybrid NVIDIA laptops
(Intel iGPU + NVIDIA dGPU without display outputs, e.g. GeForce MX350).

| Mode | What it does |
|------|--------------|
| **Integrated** ○ | Intel only. Vulkan layer hides NVIDIA (`non_NVIDIA_only`), GLX forced to Mesa. Power saving. |
| **Hybrid** ◐ | Intel by default, both GPUs visible in Vulkan, `prime-run <app>` renders on NVIDIA per-app. |
| **Discrete** ⬢ | Global PRIME render offload: every app renders on NVIDIA. The panel is still driven by the iGPU (the dGPU has no crtc). |

The active mode lives in `~/.local/state/omarchy/gpu-mode` and is applied as
`hl.env(...)` lines in `~/.local/state/omarchy/toggles/hypr/gpu-mode.lua`,
which Omarchy loads on every `hyprctl reload`. Switching never touches
`~/.config/hypr/` or system files.

## Install

```bash
omarchy plugin install https://github.com/Konor11/omarchy-gpu-mode.git --enable
```

## Use

- Click the widget to open the mode popup.
- Middle-click toggles Integrated ↔ Discrete.
- From the terminal or a keybind: `~/.config/omarchy/plugins/dan.gpu-mode/scripts/gpu-mode.sh {get|set <mode>|cycle}`

Note: switching reloads Hyprland, so environment changes apply to newly
launched windows — reopen apps that must be on the new GPU.
