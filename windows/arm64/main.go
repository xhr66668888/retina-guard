package main

import (
	"fmt"
	"runtime"
	"syscall"
	"unsafe"
)

// ----- Win32 constants ---------------------------------------------------

const (
	CS_HREDRAW = 2
	CS_VREDRAW = 1
	CS_DBLCLKS = 8

	CW_USEDEFAULT = 0x80000000

	WS_OVERLAPPED       = 0x00000000
	WS_CAPTION          = 0x00C00000
	WS_SYSMENU          = 0x00080000
	WS_MINIMIZEBOX      = 0x00020000
	WS_VISIBLE          = 0x10000000
	WS_CHILD            = 0x40000000
	WS_TABSTOP          = 0x00010000
	WS_CLIPCHILDREN     = 0x02000000
	WS_OVERLAPPEDWINDOW = WS_OVERLAPPED | WS_CAPTION | WS_SYSMENU | WS_MINIMIZEBOX

	WS_EX_APPWINDOW = 0x00040000

	BS_OWNERDRAW = 0x0000000B

	WM_PAINT       = 0x000F
	WM_COMMAND     = 0x0111
	WM_TIMER       = 0x0113
	WM_DESTROY     = 0x0002
	WM_DRAWITEM    = 0x002B
	WM_ERASEBKGND  = 0x0014
	WM_SETCURSOR   = 0x0020
	WM_MOUSEMOVE   = 0x0200
	WM_MOUSELEAVE  = 0x02A3
	WM_SIZE        = 0x0005

	MB_OK              = 0x00000000
	MB_ICONINFORMATION = 0x00000040
	MB_TOPMOST         = 0x00040000
	MB_SETFOREGROUND   = 0x00010000

	IDC_ARROW = 32512
	IDC_HAND  = 32649

	SW_SHOW      = 5
	SWP_NOZORDER = 0x0004
	SM_CXSCREEN  = 0
	SM_CYSCREEN  = 1

	TRANSPARENT = 1
	DT_CENTER   = 0x0001
	DT_VCENTER  = 0x0004
	DT_SINGLELINE = 0x0020
	DT_LEFT     = 0x0000
	DT_NOPREFIX = 0x0800
	DT_END_ELLIPSIS = 0x8000

	ODS_SELECTED = 0x0001
	ODS_DISABLED = 0x0004
	ODS_FOCUS    = 0x0010

	FW_NORMAL   = 400
	FW_MEDIUM   = 500
	FW_SEMIBOLD = 600
	FW_BOLD     = 700
	FW_EXTRABOLD = 800

	DEFAULT_CHARSET    = 1
	OUT_DEFAULT_PRECIS = 0
	CLIP_DEFAULT_PRECIS = 0
	CLEARTYPE_QUALITY  = 5
	VARIABLE_PITCH     = 2

	IMAGE_ICON     = 1
	LR_DEFAULTSIZE = 0x00000040
	LR_SHARED      = 0x00008000

	WM_SETICON  = 0x0080
	ICON_SMALL  = 0
	ICON_BIG    = 1

	TME_LEAVE = 0x00000002

	HTCLIENT = 1

	// Timer IDs
	TIMER_TICK = 1

	// Control IDs
	ID_BTN_PRIMARY    = 1001
	ID_BTN_BREAK_NOW  = 1002
	ID_BTN_TILE_FIRST = 2000

	WIN_W = 440
	WIN_H = 540

	BRAND_R = 0xE6
	BRAND_G = 0x00
	BRAND_B = 0x00
	BRAND_DEEP_R = 0xAC
	BRAND_DEEP_G = 0x18
	BRAND_DEEP_B = 0x11
	CHARCOAL_R = 0x25
	CHARCOAL_G = 0x28
	CHARCOAL_B = 0x2B
	GREY_R = 0x7E
	GREY_G = 0x7E
	GREY_B = 0x7E
	NEUTRAL_R = 0xF2
	NEUTRAL_G = 0xF2
	NEUTRAL_B = 0xF2
)

var intervals = []int{1, 2, 5, 10, 15, 20, 30, 45, 60}

// ----- Win32 structs -----------------------------------------------------

type POINT struct{ X, Y int32 }
type RECT struct{ Left, Top, Right, Bottom int32 }
type SIZE struct{ Cx, Cy int32 }
type PAINTSTRUCT struct {
	Hdc         syscall.Handle
	FErase      int32
	RcPaint     RECT
	FRestore    int32
	FIncUpdate  int32
	RgbReserved [32]byte
}
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
type DRAWITEMSTRUCT struct {
	CtlType    uint32
	CtlID      uint32
	ItemID     uint32
	ItemAction uint32
	ItemState  uint32
	HwndItem   syscall.Handle
	Hdc        syscall.Handle
	RcItem     RECT
	ItemData   uintptr
}
type LOGFONT struct {
	Height         int32
	Width          int32
	Escapement     int32
	Orientation    int32
	Weight         int32
	Italic         byte
	Underline      byte
	StrikeOut      byte
	CharSet        byte
	OutPrecision   byte
	ClipPrecision  byte
	Quality        byte
	PitchAndFamily byte
	FaceName       [32]uint16
}
type TRACKMOUSEEVENT struct {
	CbSize      uint32
	DwFlags     uint32
	HwndTrack   syscall.Handle
	DwHoverTime uint32
}

// ----- DLL imports -------------------------------------------------------

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
	pMessageBox       = user32.NewProc("MessageBoxW")
	pSetTimer         = user32.NewProc("SetTimer")
	pKillTimer        = user32.NewProc("KillTimer")
	pSetWindowText    = user32.NewProc("SetWindowTextW")
	pLoadIcon         = user32.NewProc("LoadIconW")
	pLoadImage        = user32.NewProc("LoadImageW")
	pLoadCursor       = user32.NewProc("LoadCursorW")
	pSetCursor        = user32.NewProc("SetCursor")
	pShowWindow       = user32.NewProc("ShowWindow")
	pUpdateWindow     = user32.NewProc("UpdateWindow")
	pSendMessage      = user32.NewProc("SendMessageW")
	pSetWindowPos     = user32.NewProc("SetWindowPos")
	pGetSystemMetrics = user32.NewProc("GetSystemMetrics")
	pBeginPaint       = user32.NewProc("BeginPaint")
	pEndPaint         = user32.NewProc("EndPaint")
	pInvalidateRect   = user32.NewProc("InvalidateRect")
	pTrackMouseEvent  = user32.NewProc("TrackMouseEvent")
	pGetClientRect    = user32.NewProc("GetClientRect")
	pEnableWindow     = user32.NewProc("EnableWindow")
	pFillRect         = user32.NewProc("FillRect")
	pDrawText         = user32.NewProc("DrawTextW")

	pGetModuleHandle = kernel32.NewProc("GetModuleHandleW")

	pCreateSolidBrush = gdi32.NewProc("CreateSolidBrush")
	pCreateFontIndW   = gdi32.NewProc("CreateFontIndirectW")
	pSelectObject     = gdi32.NewProc("SelectObject")
	pDeleteObject     = gdi32.NewProc("DeleteObject")
	pSetBkMode        = gdi32.NewProc("SetBkMode")
	pSetTextColor     = gdi32.NewProc("SetTextColor")
	pRoundRect        = gdi32.NewProc("RoundRect")
	pGetStockObject   = gdi32.NewProc("GetStockObject")
)

// ----- App state ---------------------------------------------------------

type tile struct {
	hwnd syscall.Handle
	val  int
}

var (
	hInst        syscall.Handle
	hwndMain     syscall.Handle
	hwndPrimary  syscall.Handle
	hwndBreak    syscall.Handle
	tiles        []tile
	hoveredHwnd  syscall.Handle
	pressedHwnd  syscall.Handle

	fontTitle    syscall.Handle
	fontHero     syscall.Handle
	fontBody     syscall.Handle
	fontLabel    syscall.Handle
	fontButton   syscall.Handle
	fontTile     syscall.Handle

	brushBg      syscall.Handle
	brushNeutral syscall.Handle
	brushBrand   syscall.Handle
	brushBrandDp syscall.Handle

	running     bool
	remaining   int
	intervalMin = 20
)

// ----- Helpers -----------------------------------------------------------

func utf16(s string) *uint16 {
	p, _ := syscall.UTF16PtrFromString(s)
	return p
}

func rgb(r, g, b uint8) uintptr {
	return uintptr(uint32(r) | uint32(g)<<8 | uint32(b)<<16)
}

func intervalSeconds() int { return intervalMin * 60 }

func makeFont(height int32, weight int32, face string) syscall.Handle {
	lf := LOGFONT{
		Height:         height,
		Weight:         weight,
		CharSet:        DEFAULT_CHARSET,
		OutPrecision:   OUT_DEFAULT_PRECIS,
		ClipPrecision:  CLIP_DEFAULT_PRECIS,
		Quality:        CLEARTYPE_QUALITY,
		PitchAndFamily: VARIABLE_PITCH,
	}
	pn, _ := syscall.UTF16FromString(face)
	copy(lf.FaceName[:], pn)
	h, _, _ := pCreateFontIndW.Call(uintptr(unsafe.Pointer(&lf)))
	return syscall.Handle(h)
}

func loadFonts() {
	// Negative values pass character height in points (approx).
	fontTitle = makeFont(-13, FW_SEMIBOLD, "Segoe UI")
	fontHero = makeFont(-72, FW_BOLD, "Segoe UI")
	fontBody = makeFont(-14, FW_NORMAL, "Segoe UI")
	fontLabel = makeFont(-11, FW_SEMIBOLD, "Segoe UI")
	fontButton = makeFont(-15, FW_SEMIBOLD, "Segoe UI")
	fontTile = makeFont(-13, FW_SEMIBOLD, "Segoe UI")
}

func loadBrushes() {
	bg, _, _ := pCreateSolidBrush.Call(rgb(0xFF, 0xFF, 0xFF))
	brushBg = syscall.Handle(bg)
	n, _, _ := pCreateSolidBrush.Call(rgb(NEUTRAL_R, NEUTRAL_G, NEUTRAL_B))
	brushNeutral = syscall.Handle(n)
	r, _, _ := pCreateSolidBrush.Call(rgb(BRAND_R, BRAND_G, BRAND_B))
	brushBrand = syscall.Handle(r)
	d, _, _ := pCreateSolidBrush.Call(rgb(BRAND_DEEP_R, BRAND_DEEP_G, BRAND_DEEP_B))
	brushBrandDp = syscall.Handle(d)
}

// ----- Layout ------------------------------------------------------------

const (
	pad        = 28
	heroTop    = 96
	heroH      = 96
	subtitleTop = 196
	primaryTop = 248
	primaryH   = 56
	intervalLabelTop = 332
	tilesTop   = 360
	tileH      = 40
	tileGap    = 6
	bandTop    = 470
	bandH      = 6
)

func layoutPrimary() RECT {
	return RECT{Left: pad, Top: primaryTop, Right: WIN_W - pad, Bottom: primaryTop + primaryH}
}

func layoutBreakNow() RECT {
	// Half-width secondary button that appears beside the primary when running.
	mid := int32(WIN_W / 2)
	return RECT{Left: mid + 6, Top: primaryTop, Right: WIN_W - pad, Bottom: primaryTop + primaryH}
}

func layoutPrimaryHalf() RECT {
	mid := int32(WIN_W / 2)
	return RECT{Left: pad, Top: primaryTop, Right: mid - 6, Bottom: primaryTop + primaryH}
}

func tileRects() []RECT {
	n := len(intervals)
	innerW := WIN_W - 2*pad
	totalGap := tileGap * (n - 1)
	w := (innerW - totalGap) / n
	rs := make([]RECT, n)
	x := pad
	for i := 0; i < n; i++ {
		rs[i] = RECT{Left: int32(x), Top: tilesTop, Right: int32(x + w), Bottom: tilesTop + tileH}
		x += w + tileGap
	}
	return rs
}

// ----- UI sync -----------------------------------------------------------

func updateUI() {
	r := layoutPrimary()
	rh := layoutPrimaryHalf()
	bn := layoutBreakNow()
	if running {
		// Primary becomes "Stop" on the left half, secondary "Take break now" on the right.
		pSetWindowPos.Call(uintptr(hwndPrimary), 0, uintptr(rh.Left), uintptr(rh.Top),
			uintptr(rh.Right-rh.Left), uintptr(rh.Bottom-rh.Top), SWP_NOZORDER)
		pSetWindowPos.Call(uintptr(hwndBreak), 0, uintptr(bn.Left), uintptr(bn.Top),
			uintptr(bn.Right-bn.Left), uintptr(bn.Bottom-bn.Top), SWP_NOZORDER)
		pShowWindow.Call(uintptr(hwndBreak), SW_SHOW)
		pSetWindowText.Call(uintptr(hwndPrimary), uintptr(unsafe.Pointer(utf16("Stop"))))
	} else {
		pSetWindowPos.Call(uintptr(hwndPrimary), 0, uintptr(r.Left), uintptr(r.Top),
			uintptr(r.Right-r.Left), uintptr(r.Bottom-r.Top), SWP_NOZORDER)
		pShowWindow.Call(uintptr(hwndBreak), 0)
		pSetWindowText.Call(uintptr(hwndPrimary), uintptr(unsafe.Pointer(utf16("Start protection"))))
	}
	for _, t := range tiles {
		pEnableWindow.Call(uintptr(t.hwnd), 1)
	}
	pInvalidateRect.Call(uintptr(hwndMain), 0, 1)
}

// ----- Custom drawing ----------------------------------------------------

func drawText(hdc syscall.Handle, font syscall.Handle, color uintptr, rc RECT, text string, flags uint32) {
	if font != 0 {
		pSelectObject.Call(uintptr(hdc), uintptr(font))
	}
	pSetBkMode.Call(uintptr(hdc), TRANSPARENT)
	pSetTextColor.Call(uintptr(hdc), color)
	s := utf16(text)
	pDrawText.Call(uintptr(hdc), uintptr(unsafe.Pointer(s)), ^uintptr(0), uintptr(unsafe.Pointer(&rc)), uintptr(flags))
}

func fillSolid(hdc syscall.Handle, rc RECT, brush syscall.Handle) {
	pFillRect.Call(uintptr(hdc), uintptr(unsafe.Pointer(&rc)), uintptr(brush))
}

func drawRoundFill(hdc syscall.Handle, rc RECT, brush syscall.Handle, radius int32) {
	old, _, _ := pSelectObject.Call(uintptr(hdc), uintptr(brush))
	stockNullPen, _, _ := pGetStockObject.Call(8) // NULL_PEN
	oldPen, _, _ := pSelectObject.Call(uintptr(hdc), stockNullPen)
	pRoundRect.Call(uintptr(hdc), uintptr(rc.Left), uintptr(rc.Top), uintptr(rc.Right), uintptr(rc.Bottom),
		uintptr(radius), uintptr(radius))
	pSelectObject.Call(uintptr(hdc), old)
	pSelectObject.Call(uintptr(hdc), oldPen)
}

func paintMain(hdc syscall.Handle) {
	var crc RECT
	pGetClientRect.Call(uintptr(hwndMain), uintptr(unsafe.Pointer(&crc)))
	fillSolid(hdc, crc, brushBg)

	// Title
	drawText(hdc, fontTitle, rgb(CHARCOAL_R, CHARCOAL_G, CHARCOAL_B),
		RECT{Left: pad, Top: 32, Right: WIN_W - pad, Bottom: 56},
		"RETINA GUARD", DT_LEFT|DT_SINGLELINE|DT_NOPREFIX)

	// Timer hero
	mins := remaining / 60
	secs := remaining % 60
	if !running {
		mins = intervalMin
		secs = 0
	}
	timer := fmt.Sprintf("%02d:%02d", mins, secs)
	drawText(hdc, fontHero, rgb(CHARCOAL_R, CHARCOAL_G, CHARCOAL_B),
		RECT{Left: pad - 4, Top: heroTop, Right: WIN_W - pad, Bottom: heroTop + heroH},
		timer, DT_LEFT|DT_SINGLELINE|DT_NOPREFIX)

	// Subtitle
	subtitle := "until your next eye break"
	if running {
		subtitle = fmt.Sprintf("next reminder in %d:%02d", mins, secs)
	}
	drawText(hdc, fontBody, rgb(GREY_R, GREY_G, GREY_B),
		RECT{Left: pad, Top: subtitleTop, Right: WIN_W - pad, Bottom: subtitleTop + 24},
		subtitle, DT_LEFT|DT_SINGLELINE|DT_NOPREFIX)

	// INTERVAL label
	drawText(hdc, fontLabel, rgb(GREY_R, GREY_G, GREY_B),
		RECT{Left: pad, Top: intervalLabelTop, Right: WIN_W - pad, Bottom: intervalLabelTop + 18},
		"INTERVAL", DT_LEFT|DT_SINGLELINE|DT_NOPREFIX)

	// Hint below tiles
	drawText(hdc, fontBody, rgb(GREY_R, GREY_G, GREY_B),
		RECT{Left: pad, Top: tilesTop + tileH + 10, Right: WIN_W - pad, Bottom: tilesTop + tileH + 32},
		"minutes between breaks", DT_LEFT|DT_SINGLELINE|DT_NOPREFIX)

	// Red brand band
	fillSolid(hdc, RECT{Left: 0, Top: bandTop, Right: WIN_W, Bottom: bandTop + bandH}, brushBrand)

	// Footer "Look 20 ft away for 20 seconds"
	drawText(hdc, fontBody, rgb(CHARCOAL_R, CHARCOAL_G, CHARCOAL_B),
		RECT{Left: pad, Top: bandTop + bandH + 14, Right: WIN_W - pad, Bottom: bandTop + bandH + 40},
		"20 / 20 / 20 rule", DT_LEFT|DT_SINGLELINE|DT_NOPREFIX)
	drawText(hdc, fontBody, rgb(GREY_R, GREY_G, GREY_B),
		RECT{Left: pad, Top: bandTop + bandH + 36, Right: WIN_W - pad, Bottom: bandTop + bandH + 60},
		"Look 20 feet away for 20 seconds.", DT_LEFT|DT_SINGLELINE|DT_NOPREFIX)
}

func drawPrimaryButton(dis *DRAWITEMSTRUCT) {
	hdc := dis.Hdc
	rc := dis.RcItem
	hovered := dis.HwndItem == hoveredHwnd
	pressed := dis.ItemState&ODS_SELECTED != 0
	var brush syscall.Handle
	switch {
	case pressed:
		brush = brushBrandDp
	case hovered:
		brush = brushBrandDp
	default:
		brush = brushBrand
	}
	drawRoundFill(hdc, rc, brush, 32)

	label := "Start protection"
	if running {
		label = "Stop"
	}
	drawText(hdc, fontButton, rgb(0xFF, 0xFF, 0xFF), rc, label,
		DT_CENTER|DT_VCENTER|DT_SINGLELINE|DT_NOPREFIX)
}

func drawBreakNowButton(dis *DRAWITEMSTRUCT) {
	hdc := dis.Hdc
	rc := dis.RcItem
	hovered := dis.HwndItem == hoveredHwnd
	pressed := dis.ItemState&ODS_SELECTED != 0
	var brush syscall.Handle
	switch {
	case pressed:
		brush = brushBrandDp
	case hovered:
		brush = brushBrandDp
	default:
		brush = brushBrand
	}
	drawRoundFill(hdc, rc, brush, 32)
	drawText(hdc, fontButton, rgb(0xFF, 0xFF, 0xFF), rc, "Take break now",
		DT_CENTER|DT_VCENTER|DT_SINGLELINE|DT_NOPREFIX)
}

func drawTileButton(dis *DRAWITEMSTRUCT, value int) {
	hdc := dis.Hdc
	rc := dis.RcItem
	selected := value == intervalMin
	hovered := dis.HwndItem == hoveredHwnd
	var brush syscall.Handle
	var textColor uintptr
	switch {
	case selected:
		brush = brushBrand
		textColor = rgb(0xFF, 0xFF, 0xFF)
	case hovered:
		// hover state on a neutral tile: a subtle darker neutral
		hov, _, _ := pCreateSolidBrush.Call(rgb(0xE5, 0xE5, 0xE5))
		brush = syscall.Handle(hov)
		defer pDeleteObject.Call(uintptr(brush))
		textColor = rgb(CHARCOAL_R, CHARCOAL_G, CHARCOAL_B)
	default:
		brush = brushNeutral
		textColor = rgb(CHARCOAL_R, CHARCOAL_G, CHARCOAL_B)
	}
	drawRoundFill(hdc, rc, brush, 8)
	drawText(hdc, fontTile, textColor, rc, fmt.Sprintf("%d", value),
		DT_CENTER|DT_VCENTER|DT_SINGLELINE|DT_NOPREFIX)
}

// ----- Window proc -------------------------------------------------------

func setHovered(h syscall.Handle) {
	if hoveredHwnd == h {
		return
	}
	prev := hoveredHwnd
	hoveredHwnd = h
	if prev != 0 {
		pInvalidateRect.Call(uintptr(prev), 0, 0)
	}
	if h != 0 {
		pInvalidateRect.Call(uintptr(h), 0, 0)
	}
}

func childProc(hwnd syscall.Handle, msg uint32, wParam uintptr, lParam uintptr) uintptr {
	switch msg {
	case WM_MOUSEMOVE:
		if hoveredHwnd != hwnd {
			setHovered(hwnd)
			tme := TRACKMOUSEEVENT{
				CbSize:    uint32(unsafe.Sizeof(TRACKMOUSEEVENT{})),
				DwFlags:   TME_LEAVE,
				HwndTrack: hwnd,
			}
			pTrackMouseEvent.Call(uintptr(unsafe.Pointer(&tme)))
		}
	case WM_MOUSELEAVE:
		if hoveredHwnd == hwnd {
			setHovered(0)
		}
	case WM_SETCURSOR:
		hand, _, _ := pLoadCursor.Call(0, uintptr(IDC_HAND))
		pSetCursor.Call(hand)
		return 1
	}
	// Forward to the original BUTTON window procedure so click handling,
	// focus tracking, and BS_OWNERDRAW notifications still work.
	ret, _, _ := pCallWindowProc.Call(origButtonProc, uintptr(hwnd), uintptr(msg), wParam, lParam)
	return ret
}

var (
	origButtonProc   uintptr
	childProcCb      uintptr
	pGetWindowLongPtr = user32.NewProc("GetWindowLongPtrW")
	pSetWindowLongPtr = user32.NewProc("SetWindowLongPtrW")
	pCallWindowProc   = user32.NewProc("CallWindowProcW")
)

// GWLP_WNDPROC = -4. Stored as a runtime int32 so uintptr conversion can
// sign-extend correctly (the equivalent compile-time conversion overflows).
var gwlpWndProc int32 = -4

func subclassChild(hwnd syscall.Handle) {
	if childProcCb == 0 {
		childProcCb = syscall.NewCallback(childProc)
	}
	if origButtonProc == 0 {
		orig, _, _ := pGetWindowLongPtr.Call(uintptr(hwnd), uintptr(gwlpWndProc))
		origButtonProc = orig
	}
	pSetWindowLongPtr.Call(uintptr(hwnd), uintptr(gwlpWndProc), childProcCb)
}

func wndProc(hwnd syscall.Handle, msg uint32, wParam uintptr, lParam uintptr) uintptr {
	switch msg {
	case WM_ERASEBKGND:
		return 1 // handled in WM_PAINT to avoid flicker

	case WM_PAINT:
		var ps PAINTSTRUCT
		hdc, _, _ := pBeginPaint.Call(uintptr(hwnd), uintptr(unsafe.Pointer(&ps)))
		paintMain(syscall.Handle(hdc))
		pEndPaint.Call(uintptr(hwnd), uintptr(unsafe.Pointer(&ps)))
		return 0

	case WM_DRAWITEM:
		dis := (*DRAWITEMSTRUCT)(unsafe.Pointer(lParam))
		if dis.HwndItem == hwndPrimary {
			drawPrimaryButton(dis)
			return 1
		}
		if dis.HwndItem == hwndBreak {
			drawBreakNowButton(dis)
			return 1
		}
		// Tile?
		for _, t := range tiles {
			if t.hwnd == dis.HwndItem {
				drawTileButton(dis, t.val)
				return 1
			}
		}

	case WM_COMMAND:
		ctrlID := wParam & 0xFFFF
		code := (wParam >> 16) & 0xFFFF
		if code == 0 { // BN_CLICKED
			switch {
			case ctrlID == ID_BTN_PRIMARY:
				if running {
					running = false
					pKillTimer.Call(uintptr(hwnd), TIMER_TICK)
				} else {
					running = true
					remaining = intervalSeconds()
					pSetTimer.Call(uintptr(hwnd), TIMER_TICK, 1000, 0)
				}
				updateUI()
				return 0
			case ctrlID == ID_BTN_BREAK_NOW:
				if running {
					remaining = intervalSeconds()
					pMessageBox.Call(uintptr(hwnd),
						uintptr(unsafe.Pointer(utf16("Look 20 feet away for 20 seconds."))),
						uintptr(unsafe.Pointer(utf16("Retina Guard"))),
						MB_OK|MB_ICONINFORMATION|MB_TOPMOST|MB_SETFOREGROUND)
					updateUI()
				}
				return 0
			}
			// tile click
			if ctrlID >= ID_BTN_TILE_FIRST && ctrlID < ID_BTN_TILE_FIRST+uintptr(len(intervals)) {
				idx := int(ctrlID - ID_BTN_TILE_FIRST)
				intervalMin = intervals[idx]
				if running {
					remaining = intervalSeconds()
				}
				updateUI()
				return 0
			}
		}

	case WM_TIMER:
		if wParam == TIMER_TICK && running {
			remaining--
			if remaining <= 0 {
				remaining = intervalSeconds()
				pInvalidateRect.Call(uintptr(hwnd), 0, 0)
				pMessageBox.Call(uintptr(hwnd),
					uintptr(unsafe.Pointer(utf16("Look 20 feet away for 20 seconds."))),
					uintptr(unsafe.Pointer(utf16("Retina Guard"))),
					MB_OK|MB_ICONINFORMATION|MB_TOPMOST|MB_SETFOREGROUND)
				remaining = intervalSeconds()
			}
			// Repaint just the timer area (and subtitle).
			rc := RECT{Left: 0, Top: heroTop, Right: WIN_W, Bottom: subtitleTop + 28}
			pInvalidateRect.Call(uintptr(hwnd), uintptr(unsafe.Pointer(&rc)), 0)
		}
		return 0

	case WM_DESTROY:
		if running {
			pKillTimer.Call(uintptr(hwnd), TIMER_TICK)
		}
		pPostQuitMsg.Call(0)
		return 0
	}

	ret, _, _ := pDefWindowProc.Call(uintptr(hwnd), uintptr(msg), wParam, lParam)
	return ret
}

// ----- main --------------------------------------------------------------

func main() {
	runtime.LockOSThread()

	hi, _, _ := pGetModuleHandle.Call(0)
	hInst = syscall.Handle(hi)

	loadFonts()
	loadBrushes()

	// Try to load icon resource embedded by rsrc (.syso). Fall back to default.
	icoLarge, _, _ := pLoadImage.Call(uintptr(hInst), 1, IMAGE_ICON, 0, 0, LR_DEFAULTSIZE|LR_SHARED)
	if icoLarge == 0 {
		icoLarge, _, _ = pLoadIcon.Call(0, 32512) // IDI_APPLICATION
	}
	icoSmall, _, _ := pLoadImage.Call(uintptr(hInst), 1, IMAGE_ICON, 16, 16, LR_SHARED)
	if icoSmall == 0 {
		icoSmall = icoLarge
	}
	arrow, _, _ := pLoadCursor.Call(0, uintptr(IDC_ARROW))

	className := utf16("RetinaGuard")
	wc := WNDCLASSEX{
		CbSize:        uint32(unsafe.Sizeof(WNDCLASSEX{})),
		Style:         CS_HREDRAW | CS_VREDRAW | CS_DBLCLKS,
		LpfnWndProc:   syscall.NewCallback(wndProc),
		HInstance:     hInst,
		HIcon:         syscall.Handle(icoLarge),
		HCursor:       syscall.Handle(arrow),
		HbrBackground: brushBg,
		LpszClassName: className,
		HIconSm:       syscall.Handle(icoSmall),
	}
	pRegisterClassEx.Call(uintptr(unsafe.Pointer(&wc)))

	hwnd, _, _ := pCreateWindowEx.Call(
		WS_EX_APPWINDOW,
		uintptr(unsafe.Pointer(className)),
		uintptr(unsafe.Pointer(utf16("Retina Guard"))),
		WS_OVERLAPPEDWINDOW|WS_VISIBLE|WS_CLIPCHILDREN,
		CW_USEDEFAULT, CW_USEDEFAULT, WIN_W+16, WIN_H+39,
		0, 0, uintptr(hInst), 0,
	)
	hwndMain = syscall.Handle(hwnd)
	pSendMessage.Call(uintptr(hwndMain), WM_SETICON, ICON_BIG, icoLarge)
	pSendMessage.Call(uintptr(hwndMain), WM_SETICON, ICON_SMALL, icoSmall)

	r := layoutPrimary()
	pb, _, _ := pCreateWindowEx.Call(
		0,
		uintptr(unsafe.Pointer(utf16("BUTTON"))),
		uintptr(unsafe.Pointer(utf16("Start protection"))),
		WS_CHILD|WS_VISIBLE|WS_TABSTOP|BS_OWNERDRAW,
		uintptr(r.Left), uintptr(r.Top), uintptr(r.Right-r.Left), uintptr(r.Bottom-r.Top),
		uintptr(hwndMain), ID_BTN_PRIMARY, uintptr(hInst), 0,
	)
	hwndPrimary = syscall.Handle(pb)
	subclassChild(hwndPrimary)

	bn := layoutBreakNow()
	bb, _, _ := pCreateWindowEx.Call(
		0,
		uintptr(unsafe.Pointer(utf16("BUTTON"))),
		uintptr(unsafe.Pointer(utf16("Take break now"))),
		WS_CHILD|WS_TABSTOP|BS_OWNERDRAW, // not WS_VISIBLE initially
		uintptr(bn.Left), uintptr(bn.Top), uintptr(bn.Right-bn.Left), uintptr(bn.Bottom-bn.Top),
		uintptr(hwndMain), ID_BTN_BREAK_NOW, uintptr(hInst), 0,
	)
	hwndBreak = syscall.Handle(bb)
	subclassChild(hwndBreak)

	rs := tileRects()
	tiles = make([]tile, len(intervals))
	for i, v := range intervals {
		tr := rs[i]
		h, _, _ := pCreateWindowEx.Call(
			0,
			uintptr(unsafe.Pointer(utf16("BUTTON"))),
			uintptr(unsafe.Pointer(utf16(fmt.Sprintf("%d", v)))),
			WS_CHILD|WS_VISIBLE|WS_TABSTOP|BS_OWNERDRAW,
			uintptr(tr.Left), uintptr(tr.Top), uintptr(tr.Right-tr.Left), uintptr(tr.Bottom-tr.Top),
			uintptr(hwndMain), uintptr(ID_BTN_TILE_FIRST+i), uintptr(hInst), 0,
		)
		tiles[i] = tile{hwnd: syscall.Handle(h), val: v}
		subclassChild(syscall.Handle(h))
	}

	// Center on screen.
	screenW, _, _ := pGetSystemMetrics.Call(SM_CXSCREEN)
	screenH, _, _ := pGetSystemMetrics.Call(SM_CYSCREEN)
	x := (int(screenW) - (WIN_W + 16)) / 2
	y := (int(screenH) - (WIN_H + 39)) / 2
	pSetWindowPos.Call(uintptr(hwndMain), 0, uintptr(x), uintptr(y), uintptr(WIN_W+16), uintptr(WIN_H+39), SWP_NOZORDER)

	pShowWindow.Call(uintptr(hwndMain), SW_SHOW)
	pUpdateWindow.Call(uintptr(hwndMain))

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
