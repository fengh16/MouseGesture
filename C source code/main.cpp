#include "hook.h"
#include "action.h"

HWND hgWindow, hDesktop;
HHOOK keyHook, mouseHook;
int keyHooked = 0;

TCHAR ListItem[256];
TCHAR MsgTitle[100];
TCHAR MsgText[200];
TCHAR data[256] = { 0 };

HINSTANCE ghInstance;

TCHAR itemSelected[] = TEXT("Selected operation No.%d for gesture No.%d");
TCHAR selectedDetail[] = TEXT("已变更操作“%s”为执行“%s”");

const int numGestures = 8;
const int numOperations = 22;
int operationIndexes[numGestures] = { 0, 1, 2, 3, 4, 5, 6, 7 };
HWND saveButton[numGestures], hWndComboBox[numGestures];
INT32 operationKey[numGestures] = { 0 };
int nowKeyInputIndex = -1;

// Records base key in lower 2bytes
// 1<<31 for Ctrl, 30 for Alt, 29 for Shift, 28/27 for Win
const int CONTROL_ADDER = 1 << 31, ALT_ADDER = 1 << 30, SHIFT_ADDER = 1 << 29, LWIN_ADDER = 1 << 28, RWIN_ADDER = 1 << 27;

const TCHAR Planets[numOperations][20] = {
    TEXT("复制"), TEXT("粘贴"), TEXT("开始"), TEXT("切换任务"),
    TEXT("查看任务"), TEXT("桌面"), TEXT("最大化/上半屏"), TEXT("最小化/下半屏"),
    TEXT("左半屏"), TEXT("右半屏"), TEXT("后退"), TEXT("前进"), TEXT("静音"),
    TEXT("增大音量"), TEXT("减小音量"), TEXT("控制面板"), TEXT("任务管理器"),
    TEXT("记事本"), TEXT("计算器"), TEXT("默认浏览器中搜索"), TEXT("默认浏览器中搜索2"), TEXT("自定义按键")
};

void(*ActionList[])() = {
	copy,paste,Win,AltTab,WinTab,WinD,WinUp,WinDown,WinLeft,WinRight,AltLeft,
	AltRight,mute, soundUp,soundDown,ControlPanel,TaskManager,NotePad,
	Calculator,WebSearchAuto
};

const TCHAR GestureNames[numGestures][10] = {
    TEXT("左划"), TEXT("右划"), TEXT("上划"), TEXT("下划"), TEXT("左-下"), TEXT("左-上"), TEXT("右-下"), TEXT("右-上")
};

const TCHAR errorInfoText[] = TEXT("窗口注册失败！");
const TCHAR errorInfoText2[] = TEXT("窗口创建失败！");
const TCHAR errorInfoTitle[] = TEXT("错误");

const int comboHMenuBase = 5000;
const TCHAR staticTypeName[8] = TEXT("STATIC");
const TCHAR comboTypeName[9] = TEXT("COMBOBOX");
const TCHAR inputedString[] = TEXT("正在录入快捷键……");
const int comboBaseXPos = 100;
const int comboBaseYPos = 35;
const int comboWidth = 160;
const int comboHeight = 20 * numOperations;
const int settingAdder = 30;

const TCHAR buttonTypeName[7] = TEXT("BUTTON");
const TCHAR buttonText[20] = TEXT("录入快捷键");
const int buttonWidth = 80;
const int buttonHeight = 25;

const TCHAR windowClassName[14] = TEXT("myWindowClass");
const TCHAR windowName[13] = TEXT("MouseGesture");
const int windowWidth = comboBaseXPos + comboWidth + buttonWidth + 90;
const int windowHeight = comboBaseYPos + settingAdder * numGestures + 90;

const int buttonBaseXPos = comboBaseXPos + comboWidth + 20;
const int buttonBaseYPos = comboBaseYPos;
const int buttonHMenuBase = 4000;

const TCHAR nullText[1] = TEXT("");

LRESULT CALLBACK KeyboardProc2(int nCode, WPARAM wParam, LPARAM lParam)
{
    PKBDLLHOOKSTRUCT p = (PKBDLLHOOKSTRUCT)lParam;
    int data_index = 0;
    int pressed = 0;

    if (nCode >= 0 && nowKeyInputIndex != -1)
    {
        if (wParam == WM_KEYDOWN)
        {
            pressed = p->vkCode;

            operationKey[nowKeyInputIndex] = 0;
            data_index = 0;
            if (HIBYTE(GetKeyState(VK_CONTROL)) || pressed == VK_CONTROL) {
                operationKey[nowKeyInputIndex] |= CONTROL_ADDER;
                wsprintf(data + data_index, TEXT("Ctrl+"));
                data_index += 5;
                if (pressed == VK_CONTROL) {
                    pressed = 0;
                }
            }
            if (HIBYTE(GetKeyState(VK_MENU)) || pressed == VK_MENU) {
                operationKey[nowKeyInputIndex] |= ALT_ADDER;
                wsprintf(data + data_index, TEXT("Alt+"));
                data_index += 4;
                if (pressed == VK_MENU) {
                    pressed = 0;
                }
            }
            if (HIBYTE(GetKeyState(VK_SHIFT)) || pressed == VK_SHIFT) {
                operationKey[nowKeyInputIndex] |= SHIFT_ADDER;
                wsprintf(data + data_index, TEXT("Shift+"));
                data_index += 6;
                if (pressed == VK_SHIFT) {
                    pressed = 0;
                }
            }
            if (HIBYTE(GetKeyState(VK_LWIN)) || pressed == VK_LWIN) {
                operationKey[nowKeyInputIndex] |= LWIN_ADDER;
                wsprintf(data + data_index, TEXT("Win+"));
                data_index += 4;
                if (pressed == VK_LWIN) {
                    pressed = 0;
                }
            }
            if (HIBYTE(GetKeyState(VK_RWIN)) || pressed == VK_RWIN) {
                operationKey[nowKeyInputIndex] |= RWIN_ADDER;
                wsprintf(data + data_index, TEXT("Win+"));
                data_index += 4;
                if (pressed == VK_RWIN) {
                    pressed = 0;
                }
            }
            if (('A' <= pressed && 'Z' >= pressed) || ('0' <= pressed && '9' >= pressed)) {
                wsprintf(data + data_index, TEXT("%c"), pressed);
            }
            else if (0x60 <= pressed && 0x69 >= pressed) {
                wsprintf(data + data_index, TEXT("%d"), pressed - 0x60);
            }
            else if (0x70 <= pressed && 0x87 >= pressed) {
                wsprintf(data + data_index, TEXT("F%d"), pressed - 0x6F);
            }
            else if (VK_INSERT == pressed) {
                wsprintf(data + data_index, TEXT("Insert"));
            }
            else if (VK_PRIOR == pressed) {
                wsprintf(data + data_index, TEXT("PageUp"));
            }
            else if (VK_NEXT == pressed) {
                wsprintf(data + data_index, TEXT("PageDown"));
            }
            else if (VK_LEFT == pressed) {
                wsprintf(data + data_index, TEXT("Left"));
            }
            else if (VK_RIGHT == pressed) {
                wsprintf(data + data_index, TEXT("Right"));
            }
            else if (VK_UP == pressed) {
                wsprintf(data + data_index, TEXT("Up"));
            }
            else if (VK_DOWN == pressed) {
                wsprintf(data + data_index, TEXT("Down"));
            }
            else if (VK_ESCAPE == pressed) {
                wsprintf(data + data_index, TEXT("Esc"));
            }
            else if (VK_SPACE == pressed) {
                wsprintf(data + data_index, TEXT("Space"));
            }
            else if (VK_RETURN == pressed) {
                wsprintf(data + data_index, TEXT("Return"));
            }
            else if (VK_TAB == pressed) {
                wsprintf(data + data_index, TEXT("Tab"));
            }
            else if (VK_BACK == pressed) {
                wsprintf(data + data_index, TEXT("BackSpace"));
            }
            else if (VK_DELETE == pressed) {
                wsprintf(data + data_index, TEXT("Delete"));
            }
            else {
                pressed = 0;
                // wsprintf(data + data_index - 1, TEXT(" "));
                // Can't use wsprintf(data + data_index - 1, TEXT("")); Can't simply use *()=0 or *()=TEXT('\0')
            }
            operationKey[nowKeyInputIndex] += pressed;
            SendMessage(hWndComboBox[nowKeyInputIndex], (UINT)CB_DELETESTRING, (WPARAM)(numOperations - 1), (LPARAM)0);
            SendMessage(hWndComboBox[nowKeyInputIndex], (UINT)CB_ADDSTRING, (WPARAM)0, (LPARAM)data);
            operationIndexes[nowKeyInputIndex] = numOperations - 1;
            SendMessage(hWndComboBox[nowKeyInputIndex], CB_SETCURSEL, (WPARAM)(operationIndexes[nowKeyInputIndex]), (LPARAM)0);
        }
    }

    //  return CallNextHookEx(keyHook, nCode, wParam, lParam);
    return 0;
}

LRESULT CALLBACK WndProc(HWND hWnd, UINT uMsg, WPARAM wParam, LPARAM lParam)
{
    int wmId = LOWORD(wParam);
    int wmEvent = HIWORD(wParam);
    int ItemIndex;
    switch (uMsg)
    {
    case WM_CLOSE:
        DestroyWindow(hWnd);
        break;
    case WM_DESTROY:
        PostQuitMessage(0);
        break;
    case WM_COMMAND:
        if ((wmId >= buttonHMenuBase && wmId < buttonHMenuBase + numGestures && wmEvent == BN_CLICKED)) {
            SET_INPUT_TEXT:
            if (nowKeyInputIndex != -1 && wmId - buttonHMenuBase != nowKeyInputIndex) {
                wsprintf(MsgTitle, TEXT("暂时不能录入"));
                wsprintf(MsgText, TEXT("请先结束已有录入任务"));
                MessageBox(hWnd, MsgText, MsgTitle, MB_OK);
                break;
            }

            if (!keyHooked) {
                keyHooked = 1;
                nowKeyInputIndex = wmId - buttonHMenuBase;
                operationKey[nowKeyInputIndex] = 0;
                keyHook = SetWindowsHookEx(
                    WH_KEYBOARD_LL,
                    KeyboardProc2,
                    ghInstance,
                    0
                );
                SetWindowText(saveButton[nowKeyInputIndex], TEXT("确认快捷键"));
                SendMessage(hWndComboBox[nowKeyInputIndex], (UINT)CB_DELETESTRING, (WPARAM)(numOperations - 1), (LPARAM)0);
                SendMessage(hWndComboBox[nowKeyInputIndex], (UINT)CB_ADDSTRING, (WPARAM)0, (LPARAM)inputedString);
                operationIndexes[nowKeyInputIndex] = numOperations - 1;
                SendMessage(hWndComboBox[nowKeyInputIndex], CB_SETCURSEL, (WPARAM)(operationIndexes[nowKeyInputIndex]), (LPARAM)0);
            }
            else {
                keyHooked = 0;
                UnhookWindowsHookEx(keyHook);
                SetWindowText(saveButton[nowKeyInputIndex], TEXT("录入快捷键"));
                operationIndexes[nowKeyInputIndex] = numOperations - 1;
                SendMessage(hWndComboBox[nowKeyInputIndex], CB_SETCURSEL, (WPARAM)(operationIndexes[nowKeyInputIndex]), (LPARAM)0);
                nowKeyInputIndex = -1;
            }
            break;
        }
        else if (wmId >= comboHMenuBase && wmId < comboHMenuBase + numGestures && wmEvent == CBN_SELCHANGE)
        {
            ItemIndex = SendMessage((HWND)lParam, (UINT)CB_GETCURSEL, (WPARAM)0, (LPARAM)0);
            operationIndexes[wmId - comboHMenuBase] = ItemIndex;
            if (ItemIndex == numOperations - 1 && nowKeyInputIndex != wmId - comboHMenuBase && 
                operationKey[wmId - comboHMenuBase] == 0) {
                    wmId = wmId - comboHMenuBase + buttonHMenuBase;
                    goto SET_INPUT_TEXT;
            }
            else if (ItemIndex != numOperations - 1 || nowKeyInputIndex < 0) {
                wsprintf(MsgTitle, itemSelected, ItemIndex, wmId - comboHMenuBase);
                SendMessage((HWND)lParam, (UINT)CB_GETLBTEXT, (WPARAM)ItemIndex, (LPARAM)ListItem);
                wsprintf(MsgText, selectedDetail, GestureNames[wmId - comboHMenuBase], ListItem);
                MessageBox(hWnd, MsgText, MsgTitle, MB_OK);
            }
            break;

        }
        // Here don't write break on purpose!
    default:
        return DefWindowProc(hWnd, uMsg, wParam, lParam);
    }
    return 0;
}

int WINAPI WinMain(HINSTANCE hInstance, HINSTANCE hPrevInstance, LPSTR lpCmdLine, int nCmdShow)
{
    WNDCLASSEX wc;
    HWND hWinMain;
    MSG Msg;

    hDesktop = GetDesktopWindow();
    ghInstance = hInstance;

    wc.cbSize = sizeof(WNDCLASSEX);
    wc.style = 0;
    wc.lpfnWndProc = WndProc;
    wc.cbClsExtra = 0;
    wc.cbWndExtra = 0;
    wc.hInstance = hInstance;
    wc.hIcon = LoadIcon(NULL, IDI_APPLICATION);
    wc.hCursor = LoadCursor(NULL, IDC_ARROW);
    wc.hbrBackground = (HBRUSH)(COLOR_WINDOW + 1);
    wc.lpszMenuName = NULL;
    wc.lpszClassName = windowClassName;
    wc.hIconSm = LoadIcon(NULL, IDI_APPLICATION);

    if (!RegisterClassEx(&wc))
    {
        MessageBox(NULL, errorInfoText, errorInfoTitle, MB_ICONEXCLAMATION | MB_OK);
        return 0;
    }

    hWinMain = CreateWindowEx(WS_EX_CLIENTEDGE, windowClassName, windowName, WS_OVERLAPPEDWINDOW,
        CW_USEDEFAULT, CW_USEDEFAULT, windowWidth, windowHeight, NULL, NULL, hInstance, NULL);

    if (hWinMain == NULL)
    {
        MessageBox(NULL, errorInfoText2, errorInfoTitle, MB_ICONEXCLAMATION | MB_OK);
        return 0;
    }

    hgWindow = hWinMain;

    ShowWindow(hWinMain, nCmdShow);
    UpdateWindow(hWinMain);

     //set mouse hook
    mouseHook = SetWindowsHookEx(
        WH_MOUSE_LL,
        MouseProc,
        hInstance,
        0
    );

    for (int i = 0; i < numGestures; i++) {
        hWndComboBox[i] = CreateWindowEx(0, comboTypeName, nullText, CBS_DROPDOWNLIST | CBS_HASSTRINGS | WS_CHILD | WS_OVERLAPPED | WS_VISIBLE,
            comboBaseXPos, comboBaseYPos + i * settingAdder, comboWidth, comboHeight, hWinMain, (HMENU)(comboHMenuBase + i), hInstance, NULL);

        CreateWindowEx(0, staticTypeName, GestureNames[i], WS_CHILD | WS_VISIBLE, comboBaseXPos - 60, comboBaseYPos + 5 + i * settingAdder, 50, 20, hWinMain, NULL, hInstance, NULL);

        saveButton[i] = CreateWindowEx(0, buttonTypeName, buttonText, WS_CHILD | WS_VISIBLE, buttonBaseXPos, buttonBaseYPos + i * settingAdder, buttonWidth, buttonHeight, hWinMain, (HMENU)(buttonHMenuBase + i), hInstance, NULL);

        int  k = 0;

        memset(&ListItem, 0, sizeof(ListItem));
        for (k = 0; k < numOperations; k++)
        {
            //wcscpy_s(ListItem, sizeof(ListItem) / sizeof(TCHAR), (TCHAR*)Planets[k]);
			wcscpy_s((wchar_t*)ListItem, sizeof(ListItem) / sizeof(TCHAR), (wchar_t*)Planets[k]);

            // Add string to combobox.
            SendMessage(hWndComboBox[i], (UINT)CB_ADDSTRING, (WPARAM)0, (LPARAM)ListItem);
        }

        // Send the CB_SETCURSEL message to display an initial item 
        //  in the selection field  
        SendMessage(hWndComboBox[i], CB_SETCURSEL, (WPARAM)(operationIndexes[i]), (LPARAM)0);
    }

    while (GetMessage(&Msg, NULL, 0, 0))
    {
        TranslateMessage(&Msg);
        DispatchMessage(&Msg);
    }

    return 0;
}