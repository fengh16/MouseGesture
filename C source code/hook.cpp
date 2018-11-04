#include "hook.h"
#include <iostream>

const int GESTURE_UP = 0;
const int GESTURE_DOWN = 1;
const int GESTURE_LEFT = 2;
const int GESTURE_RIGHT = 3;
const int GESTURE_UPLEFT = 4;
const int GESTURE_DOWNLEFT = 5;
const int GESTURE_UPRIGHT = 6;
const int GESTURE_DOWNRIGHT = 7;

int tracking = 0;
int tracks[100];
int trackNum = 0;
int lastTrack = -1;
int lastX = 0;
int lastY = 0;
int oldX = -1;
int oldY = -1;

int judgeTrack(int yDiff, int xDiff)
{
    int xChange = xDiff > 0 ? xDiff : -xDiff;
    int yChange = yDiff > 0 ? yDiff : -yDiff;
    if (yChange < 3 * xChange && xChange < 3 * yChange)
    {
        if (xDiff > 0 && yDiff > 0)
        {
            return GESTURE_DOWNRIGHT;
        }
        if (xDiff > 0 && yDiff < 0)
        {
            return GESTURE_UPRIGHT;
        }
        if (xDiff < 0 && yDiff > 0)
        {
            return GESTURE_DOWNLEFT;
        }
        else
        {
            return GESTURE_UPLEFT;
        }
    }
    else if (xChange >= 3 * yChange)
    {
        if (xDiff > 0)
        {
            return GESTURE_RIGHT;
        }
        else
            return GESTURE_LEFT;
    }
    else
    {
        if (yDiff > 0)
        {
            return GESTURE_DOWN;
        }
        else
            return GESTURE_UP;
    }
    return -1;
}

LRESULT CALLBACK MouseProc(int nCode, WPARAM wParam, LPARAM lParam)
{
    int x, y;
    int index;
    int track;
    MOUSEHOOKSTRUCT* p = (MOUSEHOOKSTRUCT*)lParam;
	TCHAR info;
	TCHAR text[50], data[20];

    PAINTSTRUCT ps;
    HDC hdc;

    if (nCode >= 0)
    {
        if (wParam == WM_LBUTTONDOWN)
        {
            //info = TEXT("����������");
       
        }
        else if (wParam == WM_LBUTTONUP)
        {
            //info = "������̧��";
			
        }
        else if (wParam == WM_RBUTTONDOWN)
        {
            //info = L"����Ҽ�����";
            tracking = 1;
        }
        else if (wParam == WM_RBUTTONUP)
        {
            //info = L"����Ҽ�̧��";
            tracking = 0;
            if (trackNum != -1 && lastTrack != -1 && lastTrack < numGestures) {
			        index = operationIndexes[lastTrack];
			        ActionList[index]();
            }
                                
            trackNum = 0;
			oldX = -1;
			oldY = -1;
			// wsprintf(text, "%s", Planets[index]);
			// hdc = GetDC(hDesktop);
			// TextOut(hdc, 300, 300, text, strlen(text));
			// ReleaseDC(hDesktop, hdc);
        }

        ZeroMemory(text, sizeof(text));
        ZeroMemory(data, sizeof(data));
        x = p->pt.x;
        y = p->pt.y;

        //wsprintf(text, "%s", info);
        // wsprintf(data, "λ�ã�x=%d,y=%d", x, y);
        if (tracking == 1 && trackNum != -1)
        {
            // paint mouse trace
            if (oldX != -1)
            {
                // HDC hDC = GetDC(hDesktop);
                // HPEN hPen = CreatePen(PS_SOLID, 3, RGB(255, 0, 255));
                // HGDIOBJ hPenOld = SelectObject(hDC, hPen);
                // MoveToEx(hDC, oldX, oldY, NULL);
                // LineTo(hDC, x, y);
                // DeleteObject(hPen);
                // ReleaseDC(hDesktop, hDC);

				if ((x - lastX)*(x - lastX) + (y - lastY)*(y - lastY) > 10000)
				{
					track = judgeTrack(x - lastX, y - lastY);
					if (track != lastTrack)
					{
						tracks[trackNum] = track;
						lastTrack = track;
						trackNum++;
						if (trackNum > 3)
						{
							trackNum = -1; // no action
							lastTrack = -1;
						}
					}
					lastX = x;
					lastY = y;
				}
            }
			else
			{
				lastX = x;
				lastY = y;
			}
			oldX = x;
			oldY = y;
        }
		
        // wsprintf(text, "%d", lastTrack);
        //hdc = GetDC(hgWindow);
        //InvalidateRect(hgWindow, NULL, true);
        //UpdateWindow(hgWindow);
        //TextOut(hdc, 10, 30, text, strlen(text));
        //TextOut(hdc, 10, 60, data, strlen(data));
       // ReleaseDC(hgWindow, hdc);
    }

    CallNextHookEx(keyHook, nCode, wParam, lParam);
	/*if (wParam == WM_RBUTTONUP)
		return 1;*/
	return 0;
}


LRESULT CALLBACK KeyboardProc(int nCode, WPARAM wParam, LPARAM lParam)
{
	PKBDLLHOOKSTRUCT p = (PKBDLLHOOKSTRUCT)lParam;
	const wchar_t *info = NULL;
	wchar_t text[50], data[20];

	PAINTSTRUCT ps;
	HDC hdc;

	if (nCode >= 0)
	{
		if (wParam == WM_KEYDOWN)      info = L"��ͨ���I̧��";
		else if (wParam == WM_KEYUP)        info = L"��ͨ���I����";
		else if (wParam == WM_SYSKEYDOWN)   info = L"ϵ�y���I̧��";
		else if (wParam == WM_SYSKEYUP)     info = L"ϵ�y���I����";

		ZeroMemory(text, sizeof(text));
		ZeroMemory(data, sizeof(data));
        //p->scanCode
		wsprintf((LPSTR)text, (LPSTR)L"%s - ������ [%04d], ɨ���� [%04d]  ", info, p->vkCode, p->scanCode);
		wsprintf((LPSTR)data, (LPSTR)L"������Ŀ��Ϊ�� %c  ", p->vkCode);

		hdc = GetDC(hgWindow);
		TextOut(hdc, 10, 50, (LPSTR)text, wcslen(text));
		TextOut(hdc, 10, 70, (LPSTR)data, wcslen(data));
		ReleaseDC(hgWindow, hdc);
	}

	return CallNextHookEx(keyHook, nCode, wParam, lParam);
}