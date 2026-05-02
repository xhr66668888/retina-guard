package main

import (
	"fmt"
	"syscall"
	"unsafe"
)

const (
	CS_HREDRAW = 2
	CS_VREDRAW = 1

	CW_USEDEFAULT  = 0x80000000
	WS_OVERLAPPED  = 0x00000000
	WS_CAPTION     = 0x00C00000
	WS_SYSMENU     = 0x00080000
	WS_MINIMIZEBOX = 0x00020000
	WS_VISIBLE     = 0x10000000
	WS_CHILD       = 0x40000000
	WS_TABSTOP     = 0x00010000

	BS_DEFPUSHBUTTON = 0x00000001
	SS_CENTER        = 0x00000001

	WM_COMMAND = 0x0111
	WM_TIMER   = 0x0113
	WM_DESTROY  = 0x0002
	WM_CLOSE    = 0x0010
	WM_SETFONT  = 0x0030

	MB_OK              = 0x00000000
	MB_ICONINFORMATION = 0x00000040
	MB_TOPMOST         = 0x00040000
	MB_SETFOREGROUND   = 0x00010000

	DEFAULT_GUI_FONT = 17
	COLOR_BTNFACE    = 15

	IDC_ARROW       = 32512
	IDI_APPLICATION = 32512

	SW_SHOW = 5

	SWP_NOZORDER = 0x0004

	SM_CXSCREEN = 0
	SM_CYSCREEN = 1

	ID_LABEL = 102
	ID_BTN   = 103

	TIMER_ID = 1

	WIN_W = 360
	WIN_H = 160

	TOTAL_SECS = 20 * 60
)

type POINT struct{ X, Y int32 }
type MSG struct {
	Hwnd    syscall.Handle
	Message uint32
	WParam  uintptr
	LParam  uintptr
	Time    uint32
	Pt      POINT
}
type WNDCLASSEX struct {
	CbSize        uint32
	Style         uint32
	LpfnWndProc   uintptr
	CbClsExtra    int32
	CbWndExtra    int32
	HInstance     syscall.Handle
	HIcon         syscall.Handle
	HCursor       syscall.Handle
	HbrBackground syscall.Handle
	LpszMenuName  *uint16
	LpszClassName *uint16
	HIconSm       syscall.Handle
}

var (
	user32   = syscall.NewLazyDLL("user32.dll")
	kernel32 = syscall.NewLazyDLL("kernel32.dll")
	gdi32    = syscall.NewLazyDLL("gdi32.dll")

	pRegisterClassEx  = user32.NewProc("RegisterClassExW")
	pCreateWindowEx   = user32.NewProc("CreateWindowExW")
	pDefWindowProc    = user32.NewProc("DefWindowProcW")
	pGetMessage       = user32.NewProc("GetMessageW")
	pTranslateMsg     = user32.NewProc("TranslateMessage")
	pDispatchMsg      = user32.NewProc("DispatchMessageW")
	pPostQuitMsg      = user32.NewProc("PostQuitMessage")
	pDestroyWindow    = user32.NewProc("DestroyWindow")
	pMessageBox       = user32.NewProc("MessageBoxW")
	pSetTimer         = user32.NewProc("SetTimer")
	pKillTimer        = user32.NewProc("KillTimer")
	pSetWindowText    = user32.NewProc("SetWindowTextW")
	pLoadIcon         = user32.NewProc("LoadIconW")
	pLoadCursor       = user32.NewProc("LoadCursorW")
	pShowWindow       = user32.NewProc("ShowWindow")
	pUpdateWindow     = user32.NewProc("UpdateWindow")
	pSendMessage      = user32.NewProc("SendMessageW")
	pSetWindowPos     = user32.NewProc("SetWindowPos")
	pGetSystemMetrics = user32.NewProc("GetSystemMetrics")

	pGetModuleHandle = kernel32.NewProc("GetModuleHandleW")
	pGetStockObject  = gdi32.NewProc("GetStockObject")
)

var (
	hwndBtn   syscall.Handle
	hwndLabel syscall.Handle
	running   bool
	remaining int
)

func utf16(s string) *uint16 {
	p, _ := syscall.UTF16PtrFromString(s)
	return p
}

func updateUI() {
	var status string
	if running {
		m := remaining / 60
		s := remaining % 60
		status = fmt.Sprintf("Next reminder in %02d:%02d", m, s)
	} else {
		status = "Click Start to begin"
	}
	pSetWindowText.Call(uintptr(hwndLabel), uintptr(unsafe.Pointer(utf16(status))))

	var btn string
	if running {
		btn = "Stop"
	} else {
		btn = "Start"
	}
	pSetWindowText.Call(uintptr(hwndBtn), uintptr(unsafe.Pointer(utf16(btn))))
}

func wndProc(hwnd syscall.Handle, msg uint32, wParam uintptr, lParam uintptr) uintptr {
	switch msg {

	case WM_COMMAND:
		if wParam&0xFFFF == ID_BTN {
			if running {
				running = false
				pKillTimer.Call(uintptr(hwnd), TIMER_ID)
			} else {
				running = true
				remaining = TOTAL_SECS
				pSetTimer.Call(uintptr(hwnd), TIMER_ID, 1000, 0)
			}
			updateUI()
		}
		return 0

	case WM_TIMER:
		if wParam == TIMER_ID && running {
			remaining--
			if remaining <= 0 {
				remaining = TOTAL_SECS
				updateUI()

				pMessageBox.Call(uintptr(hwnd),
					uintptr(unsafe.Pointer(utf16("Please look at something 20 feet away for 20 seconds."))),
					uintptr(unsafe.Pointer(utf16("Retina Guard"))),
					MB_OK|MB_ICONINFORMATION|MB_TOPMOST|MB_SETFOREGROUND)

				remaining = TOTAL_SECS
				updateUI()
			} else {
				updateUI()
			}
		}
		return 0

	case WM_CLOSE:
		if running {
			pKillTimer.Call(uintptr(hwnd), TIMER_ID)
			running = false
		}
		pDestroyWindow.Call(uintptr(hwnd))
		return 0

	case WM_DESTROY:
		pPostQuitMsg.Call(0)
		return 0
	}

	ret, _, _ := pDefWindowProc.Call(uintptr(hwnd), uintptr(msg), wParam, lParam)
	return ret
}

func main() {
	hInst, _, _ := pGetModuleHandle.Call(0)
	icon, _, _ := pLoadIcon.Call(0, uintptr(IDI_APPLICATION))
	arrow, _, _ := pLoadCursor.Call(0, uintptr(IDC_ARROW))
	bg, _, _ := pGetStockObject.Call(uintptr(COLOR_BTNFACE + 1))
	font, _, _ := pGetStockObject.Call(uintptr(DEFAULT_GUI_FONT))

	className := utf16("RetinaGuard")
	wc := WNDCLASSEX{
		CbSize:        uint32(unsafe.Sizeof(WNDCLASSEX{})),
		Style:         CS_HREDRAW | CS_VREDRAW,
		LpfnWndProc:   syscall.NewCallback(wndProc),
		HInstance:     syscall.Handle(hInst),
		HIcon:         syscall.Handle(icon),
		HCursor:       syscall.Handle(arrow),
		HbrBackground: syscall.Handle(bg),
		LpszClassName: className,
	}
	pRegisterClassEx.Call(uintptr(unsafe.Pointer(&wc)))

	hwnd, _, _ := pCreateWindowEx.Call(
		0,
		uintptr(unsafe.Pointer(className)),
		uintptr(unsafe.Pointer(utf16("Retina Guard"))),
		WS_OVERLAPPED|WS_CAPTION|WS_SYSMENU|WS_MINIMIZEBOX|WS_VISIBLE,
		CW_USEDEFAULT, CW_USEDEFAULT, WIN_W, WIN_H,
		0, 0, hInst, 0,
	)

	label, _, _ := pCreateWindowEx.Call(
		0,
		uintptr(unsafe.Pointer(utf16("STATIC"))),
		uintptr(unsafe.Pointer(utf16("Click Start to begin"))),
		WS_CHILD|WS_VISIBLE|SS_CENTER,
		20, 30, WIN_W-40, 28,
		uintptr(hwnd), ID_LABEL, hInst, 0,
	)
	hwndLabel = syscall.Handle(label)

	btn, _, _ := pCreateWindowEx.Call(
		0,
		uintptr(unsafe.Pointer(utf16("BUTTON"))),
		uintptr(unsafe.Pointer(utf16("Start"))),
		WS_CHILD|WS_VISIBLE|WS_TABSTOP|BS_DEFPUSHBUTTON,
		100, 80, 160, 42,
		uintptr(hwnd), ID_BTN, hInst, 0,
	)
	hwndBtn = syscall.Handle(btn)

	pSendMessage.Call(uintptr(hwndBtn), WM_SETFONT, font, 0)
	pSendMessage.Call(uintptr(hwndLabel), WM_SETFONT, font, 0)

	screenW, _, _ := pGetSystemMetrics.Call(SM_CXSCREEN)
	screenH, _, _ := pGetSystemMetrics.Call(SM_CYSCREEN)
	x := (int(screenW) - WIN_W) / 2
	y := (int(screenH) - WIN_H) / 2
	pSetWindowPos.Call(uintptr(hwnd), 0, uintptr(x), uintptr(y), uintptr(WIN_W), uintptr(WIN_H), SWP_NOZORDER)

	pShowWindow.Call(uintptr(hwnd), SW_SHOW)
	pUpdateWindow.Call(uintptr(hwnd))

	var msg MSG
	for {
		ret, _, _ := pGetMessage.Call(uintptr(unsafe.Pointer(&msg)), 0, 0, 0)
		if int32(ret) <= 0 {
			break
		}
		pTranslateMsg.Call(uintptr(unsafe.Pointer(&msg)))
		pDispatchMsg.Call(uintptr(unsafe.Pointer(&msg)))
	}

	syscall.Exit(0)
}
