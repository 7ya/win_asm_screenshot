; Author:            7ya
; Update date:       26.04.2017
; Contact:           7ya@protonmail.com
; Internet address:  https://github.com/7ya/win_asm_screenshot
; License:           GPL-3.0
;**********************************************************************************************************************************************************
__UNICODE__ equ 1
include \masm32\include\masm32rt.inc

select_frame   proto :DWORD, :DWORD

move_sf        proto :DWORD

.data
    UC sfName, "select_frame_class", 0
    
    white_brush     dd ?
    black_brush     dd ?
    monx            dd ?
    mony            dd ?

.code
;**********************************************************************************************************************************************************
select_frame proc uses ebx ecx edx hWnd:DWORD, hInstance:DWORD
LOCAL hhh:DWORD
LOCAL wc:WNDCLASSEX, poi:POINT
    invoke GetCursorPos, addr poi
    
    invoke GetSystemMetrics, SM_CXSCREEN
    mov monx, eax
    invoke GetSystemMetrics, SM_CYSCREEN
    mov mony, eax

    invoke CreateSolidBrush, 0ffffffh
    mov white_brush, eax
    invoke CreateSolidBrush, 0
    mov black_brush, eax
    
    mrm wc.hInstance, hInstance
    mov wc.cbSize, sizeof WNDCLASSEX
    mov wc.style, CS_NOCLOSE or CS_HREDRAW or CS_VREDRAW
    mov wc.lpfnWndProc, offset frame_proc
    mov wc.cbClsExtra, 0
    mov wc.cbWndExtra, 40
    mov wc.hIcon, 0
    mov wc.hIconSm, 0
    invoke LoadCursor, 0, IDC_ARROW
    mov wc.hCursor, eax
    invoke CreateSolidBrush, 0111111h
    mov wc.hbrBackground, eax
    mov wc.lpszMenuName, 0
    mov wc.lpszClassName, offset sfName
    invoke RegisterClassEx, addr wc
    invoke CreateWindowEx, WS_EX_LAYERED or WS_EX_TOPMOST, addr sfName, 0, WS_POPUP or WS_DISABLED, 0, 0, monx, mony, hWnd, 0, hInstance, 0
    mov hhh, eax
    invoke SetLayeredWindowAttributes, hhh, 0111111h, 0, LWA_COLORKEY
    invoke SetWindowLong, hhh, 0, 0
    invoke SetWindowLong, hhh, 4, poi.x     ; x
    invoke SetWindowLong, hhh, 8, poi.y     ; y
    invoke SetWindowLong, hhh, 12, 0        ; ==x
    invoke SetWindowLong, hhh, 16, 0        ; ==y
    invoke SetWindowLong, hhh, 20, 0        ; x res
    invoke SetWindowLong, hhh, 24, 0        ; y res
    invoke SetWindowLong, hhh, 28, 0        ; w res
    invoke SetWindowLong, hhh, 32, 0        ; h res
    
    invoke SetTimer, hhh, 2000, 11, 0
return hhh
select_frame endp
;**********************************************************************************************************************************************************
move_sf proc hWnd:DWORD
LOCAL rec:RECT, poi:POINT
    invoke GetCursorPos, addr poi
    invoke GetWindowLong, hWnd, 12
    mov rec.left, eax
    invoke GetWindowLong, hWnd, 16
    mov ebx, rec.left
    .if poi.y== eax && poi.x== ebx
        ret
    .endif
    invoke SetWindowLong, hWnd, 12, poi.x
    invoke SetWindowLong, hWnd, 16, poi.y
    
    invoke GetWindowLong, hWnd, 4
    .if poi.x< eax
        sub eax, poi.x
        mov rec.right, eax
        mrm rec.left, poi.x
    .elseif poi.x>= eax
        mov rec.left, eax
        sub poi.x, eax
        mrm rec.right, poi.x
    .endif
    invoke GetWindowLong, hWnd, 8
    .if poi.y< eax
        sub eax, poi.y
        mov rec.bottom, eax
        mrm rec.top, poi.y
    .elseif poi.y>= eax
        mov rec.top, eax
        sub poi.y, eax
        mrm rec.bottom, poi.y
    .endif
    inc rec.right
    inc rec.bottom
    invoke SetWindowLong, hWnd, 20, rec.left
    invoke SetWindowLong, hWnd, 24, rec.top
    invoke SetWindowLong, hWnd, 28, rec.right
    invoke SetWindowLong, hWnd, 32, rec.bottom
    invoke InvalidateRect, hWnd, 0, 1
    invoke SetWindowPos, hWnd, HWND_TOP, 0, 0, monx, mony, SWP_SHOWWINDOW or SWP_NOACTIVATE
ret
move_sf endp
;**********************************************************************************************************************************************************
frame_proc proc hWnd:DWORD, uMsg:DWORD, wParam:DWORD, lParam:DWORD
LOCAL rec:RECT, ps:PAINTSTRUCT, hdc:DWORD
.IF uMsg== WM_TIMER
    invoke move_sf, hWnd
    
.ELSEIF uMsg== WM_DISPLAYCHANGE
    mov eax, lParam
    movzx ebx, ax
    shr eax, 16
    mov monx, ebx
    mov mony, eax

.ELSEIF uMsg== WM_PAINT
    invoke BeginPaint, hWnd, addr ps
    mov hdc, eax
    invoke GetWindowLong, hWnd, 20
    mov rec.left, eax
    invoke GetWindowLong, hWnd, 24
    mov rec.top, eax
    invoke GetWindowLong, hWnd, 28
    mov rec.right, eax
    invoke GetWindowLong, hWnd, 32
    mov rec.bottom, eax
    mov eax, rec.left
    add rec.right, eax
    mov eax, rec.top
    add rec.bottom, eax
    invoke FrameRect, hdc, addr rec, white_brush
    inc rec.left
    inc rec.top
    dec rec.right
    dec rec.bottom
    invoke FrameRect, hdc, addr rec, black_brush
    invoke EndPaint, hWnd, addr ps
    
.ELSEIF uMsg== WM_DESTROY
    invoke KillTimer, hWnd, 2000
.ELSE
    invoke DefWindowProc, hWnd, uMsg, wParam, lParam
    ret
.ENDIF
return 0
frame_proc endp
;**********************************************************************************************************************************************************
end

