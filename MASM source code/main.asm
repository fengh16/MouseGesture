.386
.model flat,stdcall
option casemap:none

include         windows.inc
include         gdi32.inc
includelib      gdi32.lib
include         user32.inc
includelib      user32.lib
include         kernel32.inc
includelib      kernel32.lib
include         masm32.inc
includelib      masm32.lib
include         msvcrt.inc
includelib      msvcrt.lib
include         action.inc
include         shell32.inc
includelib      shell32.lib

.data
logfont			LOGFONT <>
hFont			DWORD	?
yahei			BYTE	"微软雅黑",0
hgWindow        DWORD   ?
hDesktop        DWORD   ?
keyHook         DWORD   ?
mouseHook       DWORD   ?

keyHooked       DWORD   0

ListItem        BYTE    256 dup(?)
MsgTitle        BYTE    100 dup(?)
MsgText         BYTE    200 dup(?)
data            BYTE    256 dup(0)

ghInstance      DWORD   ?

itemSelected    BYTE    "Selected operation No.%d for gesture No.%d", 0
trackans        BYTE    "lastTrack是%d, 执行第%d个操作", 0
pressans        BYTE    "lastTrack是%d, 按键%d", 0
selectedDetail  BYTE    "已变更操作“%s”为执行“%s”", 0
showString		BYTE    "%s",0

numGestures     =       8
numOperations   =       20
operationIndexes    DWORD   0, 1, 2, 3, 4, 5, 6, 7
saveButton      DWORD   numGestures dup(?)
hWndComboBox    DWORD   numGestures dup(?)
operationKey    DWORD   numGestures dup(0)
nowKeyInputIndex    DWORD   -1

tracking        DWORD   0
tracks          DWORD   10 dup(?)
trackNum        DWORD   0
lastTrack       DWORD   -1
lastX           DWORD   0
lastY           DWORD   0
oldX            DWORD   -1
oldY            DWORD   -1

; action list
ActionList      DWORD   OFFSET copy, OFFSET paste, OFFSET Win, OFFSET AltTab, OFFSET WinTab,
                        OFFSET WinD, OFFSET WinUp, OFFSET WinDown, OFFSET WinLeft, OFFSET WinRight,
                        OFFSET AltLeft, OFFSET AltRight, OFFSET mute2, OFFSET soundUp2, OFFSET soundDown2,
                        OFFSET ControlPanel, OFFSET TaskManager, OFFSET NotePad, OFFSET Calculator, ;OFFSET WebSearchAuto,
                        OFFSET PressKeys ; need to do the acc keys
; end of action list

.const

; Records base key in lower 2bytes
; 1<<31 for Ctrl, 30 for Alt, 29 for Shift, 28/27 for Win
CONTROL_ADDER   DWORD   80000000h
ALT_ADDER       DWORD   40000000h
SHIFT_ADDER     DWORD   20000000h
LWIN_ADDER      DWORD   10000000h
RWIN_ADDER      DWORD   08000000h

Planets00       BYTE    '复制', 0
Planets01       BYTE    '粘贴', 0
Planets02       BYTE    '开始', 0
Planets03       BYTE    '切换任务', 0
Planets04       BYTE    '查看任务', 0
Planets05       BYTE    '桌面', 0
Planets06       BYTE    '最大化', 0
Planets07       BYTE    '退出最大化/最小化', 0
Planets08       BYTE    '左半屏/左变右/右变正常', 0
Planets09       BYTE    '右半屏/右变左/左变正常', 0
Planets10       BYTE    '后退', 0
Planets11       BYTE    '前进', 0
Planets12       BYTE    '静音', 0
Planets13       BYTE    '增大音量', 0
Planets14       BYTE    '减小音量', 0
Planets15       BYTE    '控制面板', 0
Planets16       BYTE    '任务管理器', 0
Planets17       BYTE    '记事本', 0
Planets18       BYTE    '计算器', 0
Planets19       BYTE    '自定义按键', 0
;Planets19       BYTE    '默认浏览器中搜索', 0
;Planets20       BYTE    '自定义按键', 0

Planets         DWORD   Planets00, Planets01, Planets02, Planets03, Planets04,
                        Planets05, Planets06, Planets07, Planets08, Planets09,
                        Planets10, Planets11, Planets12, Planets13, Planets14,
                        Planets15, Planets16, Planets17, Planets18, Planets19;,
                        ;Planets20

GestureNames00  BYTE    '左划', 0
GestureNames01  BYTE    '右划', 0
GestureNames02  BYTE    '上划', 0
GestureNames03  BYTE    '下划', 0
GestureNames04  BYTE    '左下', 0
GestureNames05  BYTE    '左上', 0
GestureNames06  BYTE    '右下', 0
GestureNames07  BYTE    '右上', 0

GestureNames    DWORD   GestureNames00, GestureNames01, GestureNames02, GestureNames03, GestureNames04,
                        GestureNames05, GestureNames06, GestureNames07

GestureLeft     DWORD   0
GestureRight    DWORD   1
GestureUp       DWORD   2
GestureDown     DWORD   3
GestureLeftDown DWORD   4
GestureLeftUp   DWORD   5
GestureRightDown DWORD  6
GestureRightUp  DWORD   7

errorInfoText   BYTE    '窗口注册失败！', 0
errorInfoText2  BYTE    '窗口创建失败！', 0
errorInfoTitle  BYTE    '错误', 0

comboHMenuBase  =       5000
staticTypeName  BYTE    'STATIC', 0
comboTypeName   BYTE    'COMBOBOX', 0
inputedString   BYTE    "正在录入快捷键……", 0
comboBaseXPos   =       100
comboBaseYPos   =       35
comboWidth      =       160
comboHeight     =       20 * numOperations
settingAdder    =       30

buttonTypeName  BYTE    "BUTTON", 0
buttonText      BYTE    "录入快捷键", 0
buttonWidth     =       80
buttonHeight    =       25

cannotMsgTitle  BYTE    "暂时不能录入", 0
cannotMsgText   BYTE    "请先结束已有录入任务", 0
confirmText     BYTE    "确认快捷键", 0

windowClassName BYTE    'myWindowClass', 0
windowName      BYTE    'MouseGesture', 0
windowWidth     =       comboBaseXPos + comboWidth + buttonWidth + 90
windowHeight    =       comboBaseYPos + settingAdder * numGestures + 90

buttonBaseXPos  =       comboBaseXPos + comboWidth + 20
buttonBaseYPos  =       comboBaseYPos
buttonHMenuBase =       4000

nullText        BYTE    0

CtrlPlus        BYTE    "Ctrl+", 0
AltPlus         BYTE    "Alt+", 0
ShiftPlus       BYTE    "Shift+", 0
WinPlus         BYTE    "Win+", 0
CharOut         BYTE    "%c", 0
IntOut          BYTE    "%d", 0
FKeyOut         BYTE    "F%d", 0
InsertKey       BYTE    "Insert", 0
PageUpKey       BYTE    "PageUp", 0
PageDownKey     BYTE    "PageDown", 0
LeftKey         BYTE    "Left", 0
RightKey        BYTE    "Right", 0
UpKey           BYTE    "Up", 0
DownKey         BYTE    "Down", 0
EscKey          BYTE    "Esc", 0
SpaceKey        BYTE    "Space", 0
ReturnKey       BYTE    "Return", 0
TabKey          BYTE    "Tab", 0
BackSpaceKey    BYTE    "BackSpace", 0
DeleteKey       BYTE    "Delete", 0
SnapshotKey     BYTE    "PrintScreen", 0
HomeKey         BYTE    "Home", 0
EndKey          BYTE    "End", 0
CapitalKey      BYTE    "CapsLock", 0
NumlockKey      BYTE    "NumLock", 0
ScrollKey       BYTE    "ScrollLock", 0
DotKey          BYTE    ".", 0
SemicolonKey    BYTE    ";", 0
QuotationKey    BYTE    "'", 0
MultiplyKey     BYTE    "*", 0
AddKey          BYTE    "+", 0
SubtractKey     BYTE    "-", 0
DecimalKey      BYTE    ".", 0
DivideKey       BYTE    "/", 0
PauseKey        BYTE    "Pause", 0
BackSlashKey    BYTE    "\", 0
SlashKey        BYTE    "/", 0
CommaKey        BYTE    ",", 0
SimKey          BYTE    "`", 0
LeftSquareKey   BYTE    "[", 0
RightSquareKey  BYTE    "]", 0
PlusEqualKey    BYTE    "=", 0
MinusKey        BYTE    "-", 0

arg_ControlPanel_1 BYTE "control",0
arg_TaskManager_1 BYTE "open",0
arg_TaskManager_2 BYTE "taskmgr",0
arg_TaskManager_3 BYTE 0
arg_NotePad_1 BYTE "notepad",0
arg_Calculator_1 BYTE "calc",0
arg_WebSearchText_1 BYTE "%s%s",0
arg_WebSearchText_2 BYTE "https://www.baidu.com/s?wd=",0
arg_WebSearchText_3 BYTE "open",0
arg_WebSearchText_4 BYTE 0
arg_WebSearchText_url BYTE 0

.code

RGB MACRO red, green, blue
    xor eax, eax
    mov ah, blue    ; blue
    mov al, green   ; green
    rol eax, 8
    mov al, red     ; red
ENDM

; ==========================================================
OneKeyAction PROC STDCALL,
    key:BYTE, 
    dwFlags:DWORD
; requires: key to invoke and dwFlags
;===========================================================
    invoke keybd_event, key, 0, dwFlags, 0
    mov eax, dwFlags
    or eax, KEYEVENTF_KEYUP
	invoke keybd_event, key, 0, eax , 0
    ret
OneKeyAction ENDP


; ==========================================================
TwoKeysAction PROC STDCALL,
    key1:BYTE, 
    dwFlags1:DWORD,
    key2:BYTE, 
    dwFlags2:DWORD
; requires: two keys key1 and key2 and their dwFlags
; ==========================================================
    invoke keybd_event, key1, 0, dwFlags1, 0
    invoke keybd_event, key2, 0, dwFlags2, 0
    invoke Sleep, KEYDOWNTIME
    mov eax, dwFlags1
    or eax, KEYEVENTF_KEYUP
    invoke keybd_event, key1, 0, eax, 0
    mov eax, dwFlags2
    or eax, KEYEVENTF_KEYUP
	invoke keybd_event, key2, 0, eax, 0
    ret
TwoKeysAction ENDP 

PressKeys       PROC uses ebx
                local keyinfo: DWORD

                mov     eax, lastTrack
                .if     eax < numGestures
                        mov     ebx, 4
                        mul     ebx
                        mov     eax, operationKey[eax]
                        mov     keyinfo, eax
                        ; mov     ebx, keyinfo
                        ; and     ebx, 255
                        ; invoke	crt_sprintf, OFFSET data, OFFSET pressans, lastTrack, ebx
                        ; invoke  MessageBox, hgWindow, OFFSET data, OFFSET data, MB_OK
                        ; check control
                        mov     eax, keyinfo
                        and     eax, CONTROL_ADDER
                        .if     eax != 0
                                invoke keybd_event, VK_CONTROL, 0, 0, 0
                        .endif
                        ; check ALT
                        mov     eax, keyinfo
                        and     eax, ALT_ADDER
                        .if     eax != 0
                                invoke keybd_event, VK_MENU, 0, 0, 0
                        .endif
                        ; check SHIFT
                        mov     eax, keyinfo
                        and     eax, SHIFT_ADDER
                        .if     eax != 0
                                invoke keybd_event, VK_SHIFT, 0, 0, 0
                        .endif
                        ; check lwin
                        mov     eax, keyinfo
                        and     eax, LWIN_ADDER
                        .if     eax != 0
                                invoke keybd_event, VK_LWIN, 0, 0, 0
                        .endif
                        ; check RWIN
                        mov     eax, keyinfo
                        and     eax, RWIN_ADDER
                        .if     eax != 0
                                invoke keybd_event, VK_RWIN, 0, 0, 0
                        .endif
                        ; press normal key
                        mov     eax, keyinfo
                        and     eax, 255
                        .if     eax != 0
                                invoke keybd_event, eax, 0, 0, 0
                        .endif
                        
                        invoke Sleep, KEYDOWNTIME
                        
                        mov     eax, keyinfo
                        and     eax, 255
                        .if     eax != 0
                                invoke keybd_event, eax, 0, KEYEVENTF_KEYUP, 0
                        .endif

                        mov     eax, keyinfo
                        and     eax, RWIN_ADDER
                        .if     eax != 0
                                invoke keybd_event, VK_RWIN, 0, KEYEVENTF_KEYUP, 0
                        .endif
                        mov     eax, keyinfo
                        and     eax, LWIN_ADDER
                        .if     eax != 0
                                invoke keybd_event, VK_LWIN, 0, KEYEVENTF_KEYUP, 0
                        .endif
                        mov     eax, keyinfo
                        and     eax, SHIFT_ADDER
                        .if     eax != 0
                                invoke keybd_event, VK_SHIFT, 0, KEYEVENTF_KEYUP, 0
                        .endif
                        mov     eax, keyinfo
                        and     eax, ALT_ADDER
                        .if     eax != 0
                                invoke keybd_event, VK_MENU, 0, KEYEVENTF_KEYUP, 0
                        .endif
                        mov     eax, keyinfo
                        and     eax, CONTROL_ADDER
                        .if     eax != 0
                                invoke keybd_event, VK_CONTROL, 0, KEYEVENTF_KEYUP, 0
                        .endif
                .endif
                ret
PressKeys       ENDP

; ==========================================================
copy PROC STDCALL
; requires: none
; ==========================================================
    invoke TwoKeysAction, VK_CONTROL, 0, 43h, 0
    ret
copy ENDP


; ==========================================================
paste PROC STDCALL
; requires: none
; ==========================================================
    invoke TwoKeysAction, VK_CONTROL, 0, 56h, 0
    ret
paste ENDP


; ==========================================================
Win PROC STDCALL
; requires: none
; ==========================================================
    invoke OneKeyAction, VK_LWIN, 0
    ret
Win ENDP


; ==========================================================
AltTab PROC STDCALL
; requires: none
; ==========================================================
    invoke TwoKeysAction, VK_MENU, 0, VK_TAB, 0
    ret
AltTab ENDP


; ==========================================================
WinTab PROC STDCALL
; requires: none
; ==========================================================
    invoke TwoKeysAction, VK_LWIN, 0, VK_TAB, 0
    ret
WinTab ENDP


; ==========================================================
WinD PROC STDCALL
; requires: none
; ==========================================================
    invoke TwoKeysAction, VK_LWIN, 0, 44h, 0
    ret
WinD ENDP


; ==========================================================
WinUp PROC STDCALL
; requires: none
; ==========================================================
    invoke TwoKeysAction, VK_LWIN, 0, VK_UP, 0
    ret
WinUp ENDP


; ==========================================================
WinDown PROC STDCALL
; requires: none
; ==========================================================
    invoke TwoKeysAction, VK_LWIN, 0, VK_DOWN, 0
    ret
WinDown ENDP


; ==========================================================
WinLeft PROC STDCALL
; requires: none
; ==========================================================
    invoke TwoKeysAction, VK_LWIN, 0, VK_LEFT, 0
    ret
WinLeft ENDP


; ==========================================================
WinRight PROC STDCALL
; requires: none
; ==========================================================
    invoke TwoKeysAction, VK_LWIN, 0, VK_RIGHT, 0
    ret
WinRight ENDP


; ==========================================================
AltLeft PROC STDCALL
; requires: none
; ==========================================================
    invoke TwoKeysAction, VK_MENU, 0, VK_LEFT, 0
    ret
AltLeft ENDP


; ==========================================================
AltRight PROC STDCALL
; requires: none
; ==========================================================
    invoke TwoKeysAction, VK_MENU, 0, VK_RIGHT, 0
    ret
AltRight ENDP


; ==========================================================
mute PROC STDCALL,
    hgWnd:DWORD
; requires: hgWnd:HWND
; ==========================================================
    invoke SendMessage, hgWnd, WM_APPCOMMAND, 200eb0h, APPCOMMAND_VOLUME_MUTE * 10000h
    ret
mute ENDP


; ==========================================================
soundUp PROC STDCALL,
    hgWnd:DWORD
; requires: hgWnd:HWND
; ==========================================================
    invoke SendMessage, hgWnd, WM_APPCOMMAND, 30292h, APPCOMMAND_VOLUME_UP * 10000h
    ret
soundUp ENDP


; ==========================================================
soundDown PROC STDCALL,
    hgWnd:DWORD
; requires: hgWnd:HWND
; ==========================================================
    invoke SendMessage, hgWnd, WM_APPCOMMAND, 30292h, APPCOMMAND_VOLUME_DOWN * 10000h
    ret
soundDown ENDP


; ==========================================================
mute2 PROC STDCALL
; requires: none
; ==========================================================
    invoke SendMessage, hgWindow, WM_APPCOMMAND, 200eb0h, APPCOMMAND_VOLUME_MUTE * 10000h
    ret
mute2 ENDP


; ==========================================================
soundUp2 PROC STDCALL
; requires: none
; ==========================================================
    invoke SendMessage, hgWindow, WM_APPCOMMAND, 30292h, APPCOMMAND_VOLUME_UP * 10000h
    ret
soundUp2 ENDP


; ==========================================================
soundDown2 PROC STDCALL
; requires: none
; ==========================================================
    invoke SendMessage, hgWindow, WM_APPCOMMAND, 30292h, APPCOMMAND_VOLUME_DOWN * 10000h
    ret
soundDown2 ENDP


; ==========================================================
ControlPanel PROC STDCALL
; requires: none
; ==========================================================
    invoke WinExec, offset arg_ControlPanel_1, SW_HIDE
    ret
ControlPanel ENDP


; ==========================================================
TaskManager PROC STDCALL
; requires: none
; ==========================================================
    invoke ShellExecuteA, 0, offset arg_TaskManager_1, offset arg_TaskManager_2, offset arg_TaskManager_3, offset arg_TaskManager_3, SW_SHOW
    ret
TaskManager ENDP


; ==========================================================
NotePad PROC STDCALL
; requires: none
; ==========================================================
    invoke WinExec, offset arg_NotePad_1, SW_SHOW
    ret
NotePad ENDP


; ==========================================================
Calculator PROC STDCALL
; requires: none
; ==========================================================
    invoke WinExec, offset arg_Calculator_1, SW_SHOW
    ret
Calculator ENDP


; ==========================================================
WebSearchText PROC STDCALL,
    text:PTR BYTE
    LOCAL sz:DWORD
; requires: none
; ==========================================================
    invoke crt_strlen, text
    mov sz, eax 
    invoke crt_sprintf, offset arg_WebSearchText_url, offset arg_WebSearchText_1, offset arg_WebSearchText_2, text
    invoke ShellExecuteA, 0, offset arg_WebSearchText_3, offset arg_WebSearchText_url, offset arg_WebSearchText_4, offset arg_WebSearchText_4, SW_SHOW
    ret
WebSearchText ENDP


; ==========================================================
WebSearchAuto PROC STDCALL
    LOCAL hMem:DWORD, lpStr:PTR BYTE
; requires: none
; ==========================================================
    invoke copy
    invoke OpenClipboard,0
    .IF eax != 0
        invoke GetClipboardData,CF_TEXT
        mov hMem,eax
        .IF hMem != 0
            invoke GlobalLock, hMem
            mov lpStr,eax
            .IF lpStr != 0
                invoke WebSearchText,lpStr
                invoke GlobalUnlock,hMem
                invoke EmptyClipboard
            .ENDIF
        .ENDIF
        invoke CloseClipboard
    .ENDIF
    ret
WebSearchAuto ENDP

JudgeTrack      proc  uses ebx, xDiff: DWORD, yDiff: DWORD
                local xChange: DWORD, yChange: DWORD
                local xChangePos: DWORD, yChangePos: DWORD
                local xChangeMulti3: DWORD, yChangeMulti3: DWORD
                
                .if xDiff < 80000000h
                        mov eax, xDiff
                        mov xChangePos, 1
                .else
                        mov eax, xDiff
                        neg eax
                        mov xChangePos, 0
                .endif
                and     eax, 1FFFh
                mov     xChange, eax
                ; int xChange = xDiff > 0 ? xDiff : -xDiff;
                .if yDiff < 80000000h
                        mov eax, yDiff
                        mov yChangePos, 1
                .else
                        mov eax, yDiff
                        neg eax
                        mov yChangePos, 0
                .endif
                and     eax, 1FFFh
                mov     yChange, eax
                ; int yChange = yDiff > 0 ? yDiff : -yDiff;
                mov     eax, xChange
                mov     ebx, 3
                mul     ebx
                mov     xChangeMulti3, eax
                mov     eax, yChange
                mov     ebx, 3
                mul     ebx
                mov     yChangeMulti3, eax
                mov     eax, xChange
                mov     ebx, yChange
                .if     eax < yChangeMulti3 && ebx < xChangeMulti3
                        .if     xChangePos != 0 && yChangePos != 0 
                                mov eax, GestureRightDown
                        .elseif xChangePos != 0
                                mov eax, GestureRightUp
                        .elseif yChangePos != 0
                                mov eax, GestureLeftDown
                        .else
                                mov eax, GestureLeftUp
                        .endif
                .elseif eax >= yChangeMulti3
                        .if     xChangePos != 0
                                mov eax, GestureRight
                        .else 
                                mov eax, GestureLeft
                        .endif
                .else
                        .if     yChangePos != 0
                                mov eax, GestureDown
                        .else 
                                mov eax, GestureUp
                        .endif
                .endif
                ret
JudgeTrack      endp

MouseProc       proc    uses ebx esi edx, nCode: DWORD, wParam: DWORD, lParam: DWORD
                local   x: DWORD, y: DWORD, hDC:DWORD, hPen:DWORD, hPenOld:DWORD, index: DWORD
                local   xDiffSquare: DWORD, yDiffSquare: DWORD, track: DWORD
				local   xRightClick: DWORD, yRightClick: DWORD, didntMove: DWORD

                .if     nCode < 80000000h

                        .if     wParam == WM_RBUTTONDOWN
                                mov     tracking, 1
                                mov     lastTrack, -1
                        .elseif wParam == WM_RBUTTONUP
                                mov     tracking, 0
                                .if     trackNum != -1 && lastTrack != -1 && lastTrack < numGestures
                                        mov     eax, lastTrack
                                        mov     ebx, 4
                                        mul     ebx
                                        ; now eax = lastTrack*4
                                        mov     eax, operationIndexes[eax]
                                        mov     index, eax
                                        ; index = operationIndexes[lastTrack];
                                        push	eax ;push index
                                        mul     ebx
                                        ; eax=index*4
                                        call    ActionList[eax]
                                        pop	eax ;pop index to show messagebox
					                    mov ebx, eax
										mov edx, 4
										mul edx
										mov edx, hWndComboBox[eax]
										invoke SendMessage, edx, CB_GETLBTEXT, ebx, OFFSET data
										invoke GetDC, hDesktop
										mov hDC, eax
										mov logfont.lfCharSet, GB2312_CHARSET
										mov logfont.lfHeight, -50
										invoke crt_strcpy, offset logfont.lfFaceName, offset yahei
										
										invoke CreateFontIndirect, offset logfont
										mov hFont, eax
										invoke SelectObject, hDC, hFont
										invoke crt_strlen, offset data
										invoke TextOut, hDC, 400, 500, offset data, eax
										invoke ReleaseDC, hDesktop, hDC
								.endif
                                mov     trackNum, 0
                                mov     oldX, -1
                                mov     oldY, -1
                        .endif

                        mov esi, lParam
                        assume esi: PTR MOUSEHOOKSTRUCT
                        push eax
                        mov eax, [esi].pt.x
                        mov x, eax
                        mov eax, [esi].pt.y
                        mov y, eax
                        pop eax
                        assume esi: nothing
                        ;x = p->pt.x;
                        ;y = p->pt.y;

                        .if     wParam == WM_RBUTTONDOWN
                                mov     eax, x
                                mov     xRightClick, eax
                                mov     eax, y
                                mov     yRightClick, eax
                        .elseif wParam == WM_RBUTTONUP
                                mov     eax, x
                                sub     eax, xRightClick
                                .if     eax >= 80000000h
                                        neg     eax
                                .endif
                                mov     ebx, y
                                sub     ebx, yRightClick
                                .if     ebx >= 80000000h
                                        neg     ebx
                                .endif
                                add     eax, ebx
                                .if     eax < 100
                                        mov     didntMove, 1
                                .else
                                        mov     didntMove, 0
                                .endif
                        .endif

                        .if tracking == 1 && trackNum != -1
                                .if oldX != -1
										; draw trace
										invoke GetDC, hDesktop
										mov hDC, eax
										push eax
										mov edx, 0ff00ffh
										pop eax
										invoke CreatePen, PS_SOLID, 10, edx
										mov hPen, eax
										invoke SelectObject, hDC, hPen
										mov hPenOld, eax
										invoke MoveToEx, hDC, oldX, oldY, 0
										invoke LineTo, hDC, x, y
										invoke SelectObject, hDC, hPenOld
										invoke DeleteObject, hPen
										invoke ReleaseDC, hDesktop, hDC

                                        mov     eax, x
                                        sub     eax, lastX
                                        .if     eax >= 80000000h
                                                neg     eax
                                        .endif
                                        mov     ebx, eax
                                        mul     ebx
                                        ;eax = |x-lastX|^2
                                        mov     xDiffSquare, eax

                                        mov     eax, y
                                        sub     eax, lastY
                                        .if     eax >= 80000000h
                                                neg     eax
                                        .endif
                                        mov     ebx, eax
                                        mul     ebx
                                        ;eax = |y-lastY|^2
                                        mov     yDiffSquare, eax

                                        mov     esi, eax
                                        add     esi, xDiffSquare

                                        .if     esi > 10000 && esi < 80000000h
                                        ;if ((x - lastX)*(x - lastX) + (y - lastY)*(y - lastY) > 10000)
                                                mov     ebx, x
                                                sub     ebx, lastX
                                                mov     edx, y
                                                sub     edx, lastY
                                                invoke  JudgeTrack, ebx, edx
                                                mov     track, eax
                                                .if     eax != lastTrack
                                                        mov     eax, trackNum
                                                        mov     esi, 4
                                                        mul     esi
                                                        ; eax = trackNum*4
                                                        mov     esi, track
                                                        mov     tracks[eax], esi
                                                        mov     lastTrack, esi
                                                        inc     trackNum
                                                        .if     trackNum > 3 && trackNum < 80000000h
                                                                mov trackNum, -1
                                                                mov lastTrack, -1
                                                        .endif
                                                .endif
                                                mov eax, x
                                                mov lastX, eax
                                                mov eax, y
                                                mov lastY, eax
                                        .endif
                                .elseif
                                        mov eax, x
                                        mov lastX, eax
                                        mov eax, y
                                        mov lastY, eax
                                .endif
                                mov eax, x
                                mov oldX, eax
                                mov eax, y
                                mov oldY, eax
                                ;oldX = x;
                                ;oldY = y;
                        .endif
                .endif
                .if     wParam == WM_RBUTTONDOWN
                        mov     eax, 1
                .elseif wParam == WM_RBUTTONUP && didntMove == 0
                        mov     eax, 1
                .elseif wParam == WM_RBUTTONUP
                        invoke  mouse_event, MOUSEEVENTF_RIGHTDOWN, 0, 0, 0, 0
                        ;invoke  Sleep, KEYDOWNTIME
                        mov     tracking, 0
                        mov     oldX, -1
                        mov     oldY, -1
                        ;invoke  mouse_event, MOUSEEVENTF_RIGHTUP, 0, 0, 0, 0
                        mov     eax, 0
                .else
                        mov     eax, 0
                        invoke  CallNextHookEx, keyHook, nCode, wParam, lParam
                .endif
                ;mov eax, 1
                ret
MouseProc       endp

KeyboardProc2   proc    uses ebx edx, nCode: DWORD, wParam: DWORD, lParam: DWORD
                local   p: PTR KBDLLHOOKSTRUCT, dataIndex: DWORD, pressed: DWORD, nowKeyInputIndexTimes4: DWORD

                mov     eax, lParam
                mov     p, eax
                mov     pressed, 0
                
                .if     nCode < 80000000h && nowKeyInputIndex != -1 && wParam == WM_KEYDOWN
                        mov     edx, p
                        assume  edx: ptr KBDLLHOOKSTRUCT
                        mov     eax, [edx].vkCode
                        and     eax, 255
                        assume  edx: nothing
                        mov     pressed, eax
                        
                        mov     eax, nowKeyInputIndex
                        mov     ebx, 4
                        mul     ebx
                        mov     nowKeyInputIndexTimes4, eax
                        mov     operationKey[eax], 0
                        mov     dataIndex, 0
                
                        invoke  GetKeyState, VK_CONTROL
                        .if     ah || pressed == VK_CONTROL
                                mov     eax, nowKeyInputIndexTimes4
                                mov     eax, operationKey[eax]
                                or      eax, CONTROL_ADDER
                                mov     ebx, nowKeyInputIndexTimes4
                                mov     operationKey[ebx], eax
                                mov     eax, OFFSET data
                                add     eax, dataIndex
                                invoke  crt_sprintf, eax, OFFSET CtrlPlus
                                mov     eax, dataIndex
                                add     eax, 5
                                mov     dataIndex, eax
                                .if     pressed == VK_CONTROL
                                        mov     pressed, 0
                                .endif
                        .endif

                        invoke  GetKeyState, VK_MENU
                        .if     ah || pressed == VK_MENU
                                mov     eax, nowKeyInputIndexTimes4
                                mov     eax, operationKey[eax]
                                or      eax, ALT_ADDER
                                mov     ebx, nowKeyInputIndexTimes4
                                mov     operationKey[ebx], eax
                                mov     eax, OFFSET data
                                add     eax, dataIndex
                                invoke  crt_sprintf, eax, OFFSET AltPlus
                                mov     eax, dataIndex
                                add     eax, 4
                                mov     dataIndex, eax
                                .if     pressed == VK_MENU
                                        mov     pressed, 0
                                .endif
                        .endif

                        invoke  GetKeyState, VK_SHIFT
                        .if     ah || pressed == VK_SHIFT
                                mov     eax, nowKeyInputIndexTimes4
                                mov     eax, operationKey[eax]
                                or      eax, SHIFT_ADDER
                                mov     ebx, nowKeyInputIndexTimes4
                                mov     operationKey[ebx], eax
                                mov     eax, OFFSET data
                                add     eax, dataIndex
                                invoke  crt_sprintf, eax, OFFSET ShiftPlus
                                mov     eax, dataIndex
                                add     eax, 6
                                mov     dataIndex, eax
                                .if     pressed == VK_SHIFT
                                        mov     pressed, 0
                                .endif
                        .endif

                        invoke  GetKeyState, VK_LWIN
                        .if     ah || pressed == VK_LWIN
                                mov     eax, nowKeyInputIndexTimes4
                                mov     eax, operationKey[eax]
                                or      eax, LWIN_ADDER
                                mov     ebx, nowKeyInputIndexTimes4
                                mov     operationKey[ebx], eax
                                mov     eax, OFFSET data
                                add     eax, dataIndex
                                invoke  crt_sprintf, eax, OFFSET WinPlus
                                mov     eax, dataIndex
                                add     eax, 4
                                mov     dataIndex, eax
                                .if     pressed == VK_LWIN
                                        mov     pressed, 0
                                .endif
                        .endif

                        invoke  GetKeyState, VK_RWIN
                        .if     ah || pressed == VK_RWIN
                                mov     eax, nowKeyInputIndexTimes4
                                mov     eax, operationKey[eax]
                                or      eax, RWIN_ADDER
                                mov     ebx, nowKeyInputIndexTimes4
                                mov     operationKey[ebx], eax
                                mov     eax, OFFSET data
                                add     eax, dataIndex
                                invoke  crt_sprintf, eax, OFFSET WinPlus
                                mov     eax, dataIndex
                                add     eax, 6
                                mov     dataIndex, eax
                                .if     pressed == VK_RWIN
                                        mov     pressed, 0
                                .endif
                        .endif

                        .if (pressed >= 'A' && pressed <= 'Z') || (pressed >= '0' && pressed <= '9')
                                mov     eax, OFFSET data
                                add     eax, dataIndex
                                invoke  crt_sprintf, eax, OFFSET CharOut, pressed
                        .elseif pressed >= 60h && pressed <= 69h
                                mov     eax, OFFSET data
                                add     eax, dataIndex
                                mov     ebx, pressed
                                sub     ebx, 60h
                                invoke  crt_sprintf, eax, OFFSET IntOut, ebx
                        .elseif pressed >= 70h && pressed <= 87h
                                mov     eax, OFFSET data
                                add     eax, dataIndex
                                mov     ebx, pressed
                                sub     ebx, 6Fh
                                invoke  crt_sprintf, eax, OFFSET FKeyOut, ebx
                        .elseif pressed == VK_INSERT
                                mov     eax, OFFSET data
                                add     eax, dataIndex
                                invoke  crt_sprintf, eax, OFFSET InsertKey
                        .elseif pressed == VK_PRIOR
                                mov     eax, OFFSET data
                                add     eax, dataIndex
                                invoke  crt_sprintf, eax, OFFSET PageUpKey
                        .elseif pressed == VK_NEXT
                                mov     eax, OFFSET data
                                add     eax, dataIndex
                                invoke  crt_sprintf, eax, OFFSET PageDownKey
                        .elseif pressed == VK_LEFT
                                mov     eax, OFFSET data
                                add     eax, dataIndex
                                invoke  crt_sprintf, eax, OFFSET LeftKey
                        .elseif pressed == VK_RIGHT
                                mov     eax, OFFSET data
                                add     eax, dataIndex
                                invoke  crt_sprintf, eax, OFFSET RightKey
                        .elseif pressed == VK_UP
                                mov     eax, OFFSET data
                                add     eax, dataIndex
                                invoke  crt_sprintf, eax, OFFSET UpKey
                        .elseif pressed == VK_DOWN
                                mov     eax, OFFSET data
                                add     eax, dataIndex
                                invoke  crt_sprintf, eax, OFFSET DownKey
                        .elseif pressed == VK_INSERT
                                mov     eax, OFFSET data
                                add     eax, dataIndex
                                invoke  crt_sprintf, eax, OFFSET InsertKey
                        .elseif pressed == VK_ESCAPE
                                mov     eax, OFFSET data
                                add     eax, dataIndex
                                invoke  crt_sprintf, eax, OFFSET EscKey
                        .elseif pressed == VK_SPACE
                                mov     eax, OFFSET data
                                add     eax, dataIndex
                                invoke  crt_sprintf, eax, OFFSET SpaceKey
                        .elseif pressed == VK_RETURN
                                mov     eax, OFFSET data
                                add     eax, dataIndex
                                invoke  crt_sprintf, eax, OFFSET ReturnKey
                        .elseif pressed == VK_TAB
                                mov     eax, OFFSET data
                                add     eax, dataIndex
                                invoke  crt_sprintf, eax, OFFSET TabKey
                        .elseif pressed == VK_BACK
                                mov     eax, OFFSET data
                                add     eax, dataIndex
                                invoke  crt_sprintf, eax, OFFSET BackSpaceKey
                        .elseif pressed == VK_DELETE
                                mov     eax, OFFSET data
                                add     eax, dataIndex
                                invoke  crt_sprintf, eax, OFFSET DeleteKey
                        .elseif pressed == VK_SNAPSHOT
                                mov     eax, OFFSET data
                                add     eax, dataIndex
                                invoke  crt_sprintf, eax, OFFSET SnapshotKey
                        .elseif pressed == VK_HOME
                                mov     eax, OFFSET data
                                add     eax, dataIndex
                                invoke  crt_sprintf, eax, OFFSET HomeKey
                        .elseif pressed == VK_END
                                mov     eax, OFFSET data
                                add     eax, dataIndex
                                invoke  crt_sprintf, eax, OFFSET EndKey
                        .elseif pressed == VK_CAPITAL
                                mov     eax, OFFSET data
                                add     eax, dataIndex
                                invoke  crt_sprintf, eax, OFFSET CapitalKey
                        .elseif pressed == VK_NUMLOCK
                                mov     eax, OFFSET data
                                add     eax, dataIndex
                                invoke  crt_sprintf, eax, OFFSET NumlockKey
                        .elseif pressed == VK_SCROLL
                                mov     eax, OFFSET data
                                add     eax, dataIndex
                                invoke  crt_sprintf, eax, OFFSET ScrollKey
                        .elseif pressed == VK_OEM_PERIOD
                                mov     eax, OFFSET data
                                add     eax, dataIndex
                                invoke  crt_sprintf, eax, OFFSET DotKey
                        .elseif pressed == VK_OEM_1
                                mov     eax, OFFSET data
                                add     eax, dataIndex
                                invoke  crt_sprintf, eax, OFFSET SemicolonKey
                        .elseif pressed == VK_OEM_7
                                mov     eax, OFFSET data
                                add     eax, dataIndex
                                invoke  crt_sprintf, eax, OFFSET QuotationKey
                        .elseif pressed == VK_MULTIPLY
                                mov     eax, OFFSET data
                                add     eax, dataIndex
                                invoke  crt_sprintf, eax, OFFSET MultiplyKey
                        .elseif pressed == VK_ADD
                                mov     eax, OFFSET data
                                add     eax, dataIndex
                                invoke  crt_sprintf, eax, OFFSET AddKey
                        .elseif pressed == VK_SUBTRACT
                                mov     eax, OFFSET data
                                add     eax, dataIndex
                                invoke  crt_sprintf, eax, OFFSET SubtractKey
                        .elseif pressed == VK_DECIMAL
                                mov     eax, OFFSET data
                                add     eax, dataIndex
                                invoke  crt_sprintf, eax, OFFSET DecimalKey
                        .elseif pressed == VK_DIVIDE
                                mov     eax, OFFSET data
                                add     eax, dataIndex
                                invoke  crt_sprintf, eax, OFFSET DivideKey
                        .elseif pressed == VK_MEDIA_PLAY_PAUSE
                                mov     eax, OFFSET data
                                add     eax, dataIndex
                                invoke  crt_sprintf, eax, OFFSET PauseKey
                        .elseif pressed == VK_OEM_5
                                mov     eax, OFFSET data
                                add     eax, dataIndex
                                invoke  crt_sprintf, eax, OFFSET BackSlashKey
                        .elseif pressed == VK_OEM_2
                                mov     eax, OFFSET data
                                add     eax, dataIndex
                                invoke  crt_sprintf, eax, OFFSET SlashKey
                        .elseif pressed == VK_OEM_COMMA
                                mov     eax, OFFSET data
                                add     eax, dataIndex
                                invoke  crt_sprintf, eax, OFFSET CommaKey
                        .elseif pressed == VK_OEM_3
                                mov     eax, OFFSET data
                                add     eax, dataIndex
                                invoke  crt_sprintf, eax, OFFSET SimKey
                        .elseif pressed == VK_OEM_4
                                mov     eax, OFFSET data
                                add     eax, dataIndex
                                invoke  crt_sprintf, eax, OFFSET LeftSquareKey
                        .elseif pressed == VK_OEM_6
                                mov     eax, OFFSET data
                                add     eax, dataIndex
                                invoke  crt_sprintf, eax, OFFSET RightSquareKey
                        .elseif pressed == VK_OEM_PLUS
                                mov     eax, OFFSET data
                                add     eax, dataIndex
                                invoke  crt_sprintf, eax, OFFSET PlusEqualKey
                        .elseif pressed == VK_OEM_MINUS
                                mov     eax, OFFSET data
                                add     eax, dataIndex
                                invoke  crt_sprintf, eax, OFFSET MinusKey
                        .else
                                mov     pressed, 0
                                mov     eax, OFFSET data
                                add     eax, dataIndex
                                dec     eax
                                invoke  crt_sprintf, eax, OFFSET nullText
                        .endif

                        mov     ebx, nowKeyInputIndexTimes4
                        mov     eax, operationKey[ebx]
                        or      eax, pressed
                        mov     operationKey[ebx], eax
                        mov     eax, nowKeyInputIndexTimes4
                        mov     edx, hWndComboBox[eax]
                        push    edx
                        invoke  SendMessage, edx, CB_DELETESTRING, numOperations - 1, 0
                        pop     edx
                        push    edx
                        invoke  SendMessage, edx, CB_ADDSTRING, 0, OFFSET data
                        mov     eax, nowKeyInputIndexTimes4
                        mov     operationIndexes[eax], numOperations - 1
                        pop     edx
                        push    edx
                        invoke  SendMessage, edx, CB_SETCURSEL, numOperations - 1, 0
                        pop     edx

                        .if     pressed != 0
                                mov     eax, 1
                                ret
                        .endif
                .endif


                invoke  CallNextHookEx, keyHook, nCode, wParam, lParam
                mov     eax, 0
                ret
KeyboardProc2   endp

_ProcWinMain    proc    uses ebx edx, hWnd, uMsg, wParam, lParam
                local   wmId: WORD
                local   wmEvent: WORD
                local   ItemIndex: DWORD
                lea     eax, wParam
                mov     bx, WORD PTR[eax]
                mov     wmId, bx
                mov     bx, WORD PTR[eax + 2]
                mov     wmEvent, bx
                mov     eax, uMsg
                .if     eax == WM_CLOSE
                        invoke     DestroyWindow,hWnd
                .elseif eax == WM_DESTROY
                        invoke     PostQuitMessage,NULL
                .else
                        .if     eax == WM_COMMAND
                                .if     wmId >= buttonHMenuBase && wmId < buttonHMenuBase + numGestures && wmEvent == BN_CLICKED
                                        SET_INPUT_TEXT:
                                        movzx   eax, wmId
                                        sub     eax, buttonHMenuBase
                                        .if     nowKeyInputIndex != -1 && eax != nowKeyInputIndex
                                                invoke  MessageBox, hWnd, OFFSET cannotMsgText, OFFSET cannotMsgTitle, MB_OK
                                                mov     eax, 0
                                                ret
                                        .endif
                                        .if     keyHooked == 0
                                                mov     keyHooked, 1
                                                movzx   eax, wmId
                                                sub     eax, buttonHMenuBase
                                                mov     nowKeyInputIndex, eax
                                                mov     ebx, 4
                                                mul     ebx
                                                ; push nowKeyInputIndex * 4
                                                push    eax
                                                mov     operationKey[eax], 0
                                                invoke  SetWindowsHookEx, WH_KEYBOARD_LL, KeyboardProc2, ghInstance, 0
                                                mov     keyHook, eax
                                                pop     eax
                                                push    eax
                                                add     eax, OFFSET saveButton
                                                invoke  SetWindowText, [eax], OFFSET confirmText
                                                pop     eax
                                                push    eax
                                                push    eax
                                                invoke  SendMessage, hWndComboBox[eax], CB_DELETESTRING, numOperations - 1, 0
                                                pop     eax
                                                invoke  SendMessage, hWndComboBox[eax], CB_ADDSTRING, 0, OFFSET inputedString
                                                pop     eax
                                                push    eax
                                                mov     operationIndexes[eax], numOperations - 1
                                                invoke  SendMessage, hWndComboBox[eax], CB_SETCURSEL, operationIndexes[eax], 0
                                        .else
                                                mov     keyHooked, 0
                                                invoke  UnhookWindowsHookEx, keyHook
                                                mov     eax, nowKeyInputIndex
                                                mov     ebx, 4
                                                mul     ebx
                                                push    eax
                                                invoke  SetWindowText, saveButton[eax], OFFSET buttonText
                                                pop     eax
                                                mov     ebx, numOperations - 1
                                                mov     operationIndexes[eax], ebx
                                                invoke  SendMessage, hWndComboBox[eax], CB_SETCURSEL, operationIndexes[eax], 0
                                                mov     nowKeyInputIndex, -1
                                        .endif
                                        mov     eax, 0
                                        ret
                                .elseif wmId >= comboHMenuBase && wmId < comboHMenuBase + numGestures && wmEvent == CBN_SELCHANGE
                                        invoke  SendMessage, lParam, CB_GETCURSEL, 0, 0
                                        mov     ItemIndex, eax
                                        movzx   eax, wmId
                                        sub     eax, comboHMenuBase
                                        push    eax
                                        invoke  crt_sprintf, OFFSET MsgTitle, OFFSET itemSelected, ItemIndex, ax
                                        pop     eax
                                        mov     ebx, ItemIndex
                                        mov     edx, 4
                                        mul     edx
                                        push    eax
                                        mov     operationIndexes[eax], ebx
                                        movzx   edx, wmId
                                        sub     edx, comboHMenuBase
                                        .if     ItemIndex == numOperations - 1 && edx != nowKeyInputIndex && operationKey[eax] == 0
                                                mov     ax, wmId
                                                sub     ax, comboHMenuBase
                                                add     ax, buttonHMenuBase
                                                mov     wmId, ax
                                                jmp     SET_INPUT_TEXT
                                        .elseif ItemIndex != numOperations - 1 || nowKeyInputIndex < 0
                                                invoke  SendMessage, lParam, CB_GETLBTEXT, ebx, OFFSET ListItem
                                                pop     eax
                                                invoke  crt_sprintf, OFFSET MsgText, OFFSET selectedDetail, GestureNames[eax], OFFSET ListItem
                                                invoke  MessageBox, hWnd, OFFSET MsgText, OFFSET MsgTitle, MB_OK
                                        .endif
                                        mov     eax, 0
                                        ret
                                .endif
                        .endif
                        invoke  DefWindowProc,hWnd,uMsg,wParam,lParam
                        ret
                .endif
                mov     eax, 0
                ret

_ProcWinMain    endp


_WinMain        proc    uses ebx esi
                local   hInstance: DWORD
                local   hWinMain: DWORD
                local   wc: WNDCLASSEX
                local   Msg: MSG
                local   comboYPos: DWORD
                local   iMulti4: DWORD ; record i * 4

                invoke  GetModuleHandle,NULL
                mov     hInstance,eax
                invoke  RtlZeroMemory,addr wc, sizeof wc

                invoke  GetDesktopWindow
                mov     hDesktop, eax

                mov     wc.cbSize, sizeof WNDCLASSEX
                mov     wc.style, 0
                mov     wc.lpfnWndProc, offset _ProcWinMain
                mov     wc.cbClsExtra, 0
                mov     wc.cbWndExtra, 0
                push    hInstance
                pop     wc.hInstance
                invoke  LoadIcon, NULL, IDI_APPLICATION
                mov     wc.hIcon, eax
                invoke  LoadCursor,0,IDC_ARROW
                mov     wc.hCursor,eax
                mov     wc.hbrBackground, COLOR_WINDOW + 1
                mov     wc.lpszMenuName, NULL
                mov     wc.lpszClassName, offset windowClassName
                invoke  LoadIcon, NULL, IDI_APPLICATION
                mov     wc.hIconSm, eax

                invoke  RegisterClassEx, addr wc
                .if     eax == 0
                        mov     ebx, MB_ICONEXCLAMATION
                        or      ebx, MB_OK
                        invoke  MessageBox, NULL, OFFSET errorInfoText, OFFSET errorInfoTitle, ebx
                        mov     eax, 0
                        ret
                .endif

                invoke  CreateWindowEx, WS_EX_CLIENTEDGE, offset windowClassName, offset windowName, WS_OVERLAPPEDWINDOW, \
                            CW_USEDEFAULT, CW_USEDEFAULT, windowWidth, windowHeight, NULL, NULL, hInstance, NULL
                mov     hWinMain, eax

                .if     eax == NULL
                        mov     ebx, MB_ICONEXCLAMATION
                        or      ebx, MB_OK
                        invoke  MessageBox, NULL, OFFSET errorInfoText2, OFFSET errorInfoTitle, ebx
                        mov     eax, 0
                        ret
                .endif

                push    hWinMain
                pop     hgWindow

                invoke  ShowWindow, hWinMain, SW_SHOWNORMAL
                invoke  UpdateWindow,hWinMain

                ; set mouse hook
                invoke  SetWindowsHookEx, WH_MOUSE_LL, MouseProc, hInstance, 0
                mov     mouseHook, eax

                mov     ecx, numGestures
                mov     esi, 0
                mov     eax, comboBaseYPos
                mov     comboYPos, eax
                CREATEITEMS:
                        push    ecx ; 1.ecx
                        push    esi ; 2.esi
                        mov     ebx, CBS_DROPDOWNLIST
                        or      ebx, CBS_HASSTRINGS
                        or      ebx, WS_CHILD
                        or      ebx, WS_OVERLAPPED
                        or      ebx, WS_VISIBLE

                        ; Calculate i * 4
                        mov     eax, esi
                        mov     ecx, 4
                        mul     ecx
                        mov     iMulti4, eax
                        
                        mov     edi, esi
                        add     edi, comboHMenuBase
                        invoke  CreateWindowEx, 0, OFFSET comboTypeName, OFFSET nullText, ebx,
                                    comboBaseXPos, comboYPos, comboWidth, comboHeight, hWinMain, edi, hInstance, NULL
                        mov     ebx, iMulti4
                        mov     hWndComboBox[ebx], eax

                        mov     ebx, WS_CHILD
                        or      ebx, WS_VISIBLE
                        mov     eax, iMulti4
                        mov     edx, comboYPos
                        add     edx, 5
                        invoke  CreateWindowEx, 0, OFFSET staticTypeName, GestureNames[eax], ebx, comboBaseXPos - 60, edx, 50, 20, hWinMain, NULL, hInstance, NULL
                        
                        mov     edx, comboYPos
                        mov     ebx, WS_CHILD
                        or      ebx, WS_VISIBLE
                        mov     edi, esi
                        add     edi, buttonHMenuBase
                        invoke  CreateWindowEx, 0, offset buttonTypeName, offset buttonText, ebx, buttonBaseXPos, edx, buttonWidth, buttonHeight, hWinMain, edi, hInstance, 0
                        mov     ebx, iMulti4
                        mov     saveButton[ebx], eax

                        mov     ecx, numOperations
                        mov     esi, 0
                        OperationsListSet:
                                push    ecx ; push 3.inner ecx
                                invoke  crt_sprintf, OFFSET ListItem, Planets[esi]
                                ; Add string to combobox.
                                mov     eax, iMulti4
                                invoke  SendMessage, hWndComboBox[eax], CB_ADDSTRING, 0, OFFSET ListItem
                                pop     ecx ; pop 3.inner ecx
                                add     esi, 4
                                loop    OperationsListSet

                        ; Send the CB_SETCURSEL message to display an initial item 
                        ;  in the selection field  
                        mov     eax, iMulti4
                        invoke  SendMessage, hWndComboBox[eax], CB_SETCURSEL, operationIndexes[eax], 0

                        pop     esi ; pop 2.esi
                        inc     esi
                        pop     ecx ; pop 1.ecx
                        mov     eax, comboYPos
                        add     eax, settingAdder
                        mov     comboYPos, eax
                        dec     ecx
                        jne     CREATEITEMS

                .while TRUE
                        invoke      GetMessage, addr Msg, NULL, 0, 0
                        .break      .if eax == 0
                        invoke      TranslateMessage, addr Msg
                        invoke      DispatchMessage, addr Msg
                .endw
                ret
_WinMain        endp

start:
                call    _WinMain
                invoke  ExitProcess, NULL
                end     start