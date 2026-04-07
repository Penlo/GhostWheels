# Ghost Wheels

An [OpenPlanet](https://openplanet.dev/) plugin for Trackmania that renders color-coded wheel trails on the track surface for any visible ghost.

See brake sections, acceleration zones, and racing lines at a glance — for your PB ghost, medal ghosts, or any loaded ghost.

## Features

- Automatically tracks all ghost vehicles in the scene
- Speed-based coloring: red for slow sections, green for fast, yellow in between
- Time delta mode: see where you're gaining or losing time vs the ghost
- Combined mode: speed colors with line width that pulses by time delta
- Configurable trail window with smooth fade-out at the leading edge
- Works with multiple ghosts simultaneously
- Togglable settings panel via Plugins menu

## Installation

### From OpenPlanet Plugin Manager

Search for "Ghost Wheels" in the in-game OpenPlanet plugin manager (F3 → Plugin Manager).

### Manual / Development

1. Install [OpenPlanet](https://openplanet.dev/download)
2. Symlink or copy the `ghost_wheels/` folder into your OpenPlanet plugins directory:

```powershell
New-Item -ItemType SymbolicLink `
  -Path "$env:USERPROFILE\OpenplanetNext\Plugins\ghost_wheels" `
  -Target "C:\path\to\this\repo\ghost_wheels"
```

3. Enable Developer signature mode in OpenPlanet (F3 → Developer → Signature Mode → Developer)
4. Reload the plugin from the OpenPlanet menu

## Usage

1. Load a map with a ghost (PB, medal, or any loaded ghost)
2. Start a run — trails appear as the ghost drives
3. On subsequent runs, the full trail is available including the path ahead
4. Toggle the settings panel from Plugins → Ghost Wheels

## Settings

| Setting | Default | Description |
|---------|---------|-------------|
| Enabled | On | Toggle trail rendering |
| Line Width | 2.0 | Width of the wheel trails (0.5–10.0) |
| Opacity | 0.8 | Trail opacity (0.0–1.0) |
| Trail Behind | 3.0s | How far behind to show |
| Trail Ahead | 2.0s | How far ahead to show |
| Fade Zone | 1.5s | Fade-out duration at the leading edge |
| Color Mode | Speed | Speed, Time Delta, or Both |
| Delta Range | 2000ms | Saturation range for time delta coloring |

## Color Modes

- **Speed** — Red/yellow/green gradient based on local speed. Shows brake sections and acceleration zones ahead.
- **Time Delta** — Cyan-green when you're ahead of the ghost, warm orange-red when behind, white when even.
- **Both** — Speed colors for the line, with line width varying by time delta (thinner = ahead, thicker = behind).

## Dependencies

- [VehicleState](https://openplanet.dev/docs/reference/vehiclestate) — for accessing ghost vehicle states
- [Camera](https://openplanet.dev/docs/reference/camera) — for 3D to screen projection

## Project Structure

```
ghost_wheels/           # OpenPlanet plugin source
├── info.toml           # Plugin manifest
├── Main.as             # Entry point, game loop, UI
├── GhostTracker.as     # Captures ghost vehicle positions each frame
├── LineRenderer.as     # Renders trails with windowing, fade, and color modes
├── SpeedColorMap.as    # Speed-to-color and time-delta-to-color functions
├── SamplePoint.as      # Data structure for recorded positions
└── Settings.as         # Plugin settings with [Setting] attributes
tests/                  # Python hypothesis property-based tests
docs/                   # Local testing and distribution guides
```

## Building / Testing

Property-based tests use Python [hypothesis](https://hypothesis.readthedocs.io/):

```bash
pip install hypothesis pytest
pytest tests/ -v
```

## License

MIT
