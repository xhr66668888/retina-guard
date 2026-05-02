# retina-guard

Minimal Windows 11 ARM64 desktop app. Reminds you to look into the distance every N minutes to reduce eye strain and retinal stress from prolonged screen use.

## Build

```bash
GOOS=windows GOARCH=arm64 go build -ldflags="-s -w -H windowsgui" -o retina-guard.exe .
```

Go 1.22+, zero external dependencies. The binary is ~1.3 MB.

## Architecture

Single-file pure Go program using raw Win32 API via `syscall.NewLazyDLL`. No CGO, no GUI framework.

- Window class registered with `RegisterClassExW`
- Message loop via `GetMessageW` / `DispatchMessageW`
- `SetTimer` drives a 1 Hz countdown tick
- `MessageBoxW` for reminders
- `WM_COMMAND` routes button and combobox events
- `WS_EX_APPWINDOW` ensures proper taskbar behavior

### Window procedure message dispatch

| Message | Action |
|---|---|
| `WM_COMMAND` | Start/Stop button toggle; interval dropdown selection |
| `WM_TIMER` | Countdown tick; fires `MessageBoxW` at zero |
| `WM_PAINT` | `BeginPaint` / `EndPaint` wrapping |
| `WM_DESTROY` | Kill timer, `PostQuitMessage` |

All other messages (minimize, restore, close, sizing, etc.) fall through to `DefWindowProcW`.

### Controls

- `STATIC` label — countdown display
- `COMBOBOX` (`CBS_DROPDOWNLIST`) — interval selector (1, 2, 5, 10, 15, 20, 30, 45, 60 min)
- `BUTTON` (`BS_DEFPUSHBUTTON`) — Start/Stop toggle
