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
include         msvcrt.inc
includelib      msvcrt.lib
include         action.inc
includelib      action.lib

.data
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
selectedDetail  BYTE    "已变更操作“%s”为执行“%s”", 0

numGestures     =       8
numOperations   =       22
operationIndexes    DWORD   0, 1, 2, 3, 4, 5, 6, 7
saveButton      DWORD   numGestures dup(?)
hWndComboBox    DWORD   numGestures dup(?)
operationKey    DWORD   numGestures dup(0)
nowKeyInputIndex    DWORD   -1

tracking        SDWORD  0
tracks          DWORD   10 dup(?)
trackNum        SDWORD   0
lastTrack       SDWORD  -1
lastX           SDWORD  0
lastY           SDWORD  0
oldX            SDWORD  -1
oldY            SDWORD  -1

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
Planets06       BYTE    '最大化/上半屏', 0
Planets07       BYTE    '最小化/下半屏', 0
Planets08       BYTE    '左半屏', 0
Planets09       BYTE    '右半屏', 0
Planets10       BYTE    '后退', 0
Planets11       BYTE    '前进', 0
Planets12       BYTE    '静音', 0
Planets13       BYTE    '增大音量', 0
Planets14       BYTE    '减小音量', 0
Planets15       BYTE    '控制面板', 0
Planets16       BYTE    '任务管理器', 0
Planets17       BYTE    '记事本', 0
Planets18       BYTE    '计算器', 0
Planets19       BYTE    '默认浏览器中搜索', 0
Planets20       BYTE    '默认浏览器中搜索2', 0
Planets21       BYTE    '自定义按键', 0

Planets         DWORD   Planets00, Planets01, Planets02, Planets03, Planets04,
                        Planets05, Planets06, Planets07, Planets08, Planets09,
                        Planets10, Planets11, Planets12, Planets13, Planets14,
                        Planets15, Planets16, Planets17, Planets18, Planets19,
                        Planets20, Planets21

GestureNames00  BYTE    '左划', 0
GestureNames01  BYTE    '右划', 0
GestureNames02  BYTE    '上划', 0
GestureNames03  BYTE    '下划', 0
GestureNames04  BYTE    '左-下', 0
GestureNames05  BYTE    '左-上', 0
GestureNames06  BYTE    '右-下', 0
GestureNames07  BYTE    '右-上', 0

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

.code

JudgeTrack      proc  uses ebx, xDiff: SDWORD, yDiff: SDWORD
                local xChange: SDWORD, yChange: SDWORD
                
                .if xDiff > 0
                        mov eax, xDiff
                        mov xChange, eax
                .else
                        mov eax, xDiff
                        neg eax
                        mov xChange, eax
                .endif
                .if yDiff > 0
                        mov eax, yDiff
                        mov yChange, eax
                .else
                        mov eax, yDiff
                        neg eax
                        mov yChange, eax
                .endif
                mov eax, xChange
                sal eax, 1
                mov ebx, yChange
                sal ebx, 1
                .if yChange < eax && xChange < ebx
                        .if xDiff > 0 && yDiff > 0
                                mov eax, GestureRightDown
                        .elseif xDiff > 0 && yDiff < 0
                                mov eax, GestureRightUp
                        .elseif xDiff < 0 && yDiff > 0
                                mov eax, GestureLeftDown
                        .else
                                mov eax, GestureLeftUp
                        .endif
                .elseif xChange >= ebx
                        .if xDiff > 0
                                mov eax, GestureRight
                        .else 
                                mov eax, GestureLeft
                        .endif
                .else
                        .if yDiff > 0
                                mov eax, GestureDown
                        .else 
                                mov eax, GestureUp
                        .endif
                .endif
                ret
JudgeTrack      endp

MouseProc       proc    uses ebx esi edx, nCode: DWORD, wParam: DWORD, lParam: DWORD
                local   x:SDWORD, y:SDWORD

                .if     nCode >= 0

                        .if wParam == WM_LBUTTONDOWN
                                mov tracking, 0
                        .elseif wParam == WM_LBUTTONUP
                                mov tracking, 0
                        .elseif wParam == WM_RBUTTONDOWN
                                mov tracking, 1
                        .elseif wParam == WM_RBUTTONUP
                                mov tracking, 0
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
                        .if tracking == 1 && trackNum != -1
                                mov eax, x
                                sub eax, lastX
                                mov edx, eax
                                imul edx
                                mov esi, eax
                                mov eax, y
                                sub eax, lastY
                                mov edx, eax
                                imul edx
                                add esi, eax
                                .if esi > 10000
                                        mov ebx, x
                                        sub ebx, lastX
                                        mov edx, y
                                        sub edx, lastY
                                        invoke JudgeTrack, ebx, edx
                                        .if eax != lastTrack
                                                mov esi, trackNum
                                                mov tracks[esi], eax
                                                mov lastTrack, eax
                                                inc trackNum
                                                .if trackNum > 3
                                                        mov trackNum, -1
                                                        mov lastTrack, -1
                                                .endif
                                        .endif
                                        mov eax, x
                                        mov lastX, eax
                                        mov eax, y
                                        mov lastY, eax
                                .endif
                        .endif
                        mov eax, x
                        mov oldX, eax
                        mov eax, y
                        mov oldY, eax             
                .endif
                invoke  CallNextHookEx, keyHook, nCode, wParam, lParam
                mov     eax, 0
                ret
MouseProc       endp

KeyboardProc2   proc    uses ebx edx, nCode: DWORD, wParam: DWORD, lParam: DWORD
                local   p: PTR KBDLLHOOKSTRUCT, dataIndex: DWORD, pressed: DWORD, nowKeyInputIndexTimes4: DWORD, hWndComboBoxNowKeyInputIndex: DWORD

                mov     eax, lParam
                mov     p, eax
                
                .if     nCode >= 0 && nowKeyInputIndex != -1 && wParam == WM_KEYDOWN
                        mov     edx, p
                        assume  edx: ptr KBDLLHOOKSTRUCT
                        mov     eax, [edx].vkCode
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
                        .else
                                mov pressed, 0
                                mov     eax, OFFSET data
                                add     eax, dataIndex
                                dec     eax
                                invoke  crt_sprintf, eax, OFFSET nullText
                        .endif
                                
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
                
                .endif

                invoke  CallNextHookEx, keyHook, nCode, wParam, lParam
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