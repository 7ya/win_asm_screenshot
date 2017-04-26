; Author:            7ya
; Update date:       26.04.2017
; Contact:           7ya@protonmail.com
; Internet address:  https://github.com/7ya/win_asm_screenshot
; License:           GPL-3.0
;**********************************************************************************************************************************************************
include data.inc
.code
start:
;**********************************************************************************************************************************************************
    invoke GetModuleHandle, 0
    mov hInstance, eax
    invoke FindWindow, addr Screenshot_Class, 0
    cmp eax, 0
    je @F
    mov hWin, eax
    invoke ShowWindow, hWin, SW_SHOWNORMAL
    invoke SetForegroundWindow, hWin
    invoke ExitProcess, hInstance
    @@:
    invoke ini_ini, uc$("screenshot.ini"), 1024
    mov ini_f, eax
    cmp ini_f, 1
    jne @F
        invoke get_data, 0, addr fLng
    @@:
    invoke read_lng, uc$("screenshot.lng"), 262144
    invoke get_str, addr s_Translation, 30, fLng, hInstance

    invoke GetCommandLine
    mov CommandLine, eax

    mov iccex.dwSize, sizeof INITCOMMONCONTROLSEX
    mov iccex.dwICC, ICC_WIN95_CLASSES
    invoke InitCommonControlsEx, addr iccex

    mov wc.cbSize, sizeof WNDCLASSEX
    mov wc.style, CS_HREDRAW or CS_VREDRAW
    mov wc.lpfnWndProc, offset ScreenshotProc
    mov wc.cbClsExtra, 0
    mov wc.cbWndExtra, 20
    mrm wc.hInstance, hInstance
    invoke LoadIcon, hInstance, 900
    mov wc.hIcon, eax
    mov wc.hIconSm, eax
    mov h_icon, eax
    invoke LoadCursor, 0, IDC_ARROW
    mov wc.hCursor, eax
    mov wc.hbrBackground, COLOR_BTNFACE+1
    mov wc.lpszMenuName, 0
    mov wc.lpszClassName, offset Screenshot_Class
    invoke RegisterClassEx, addr wc
    invoke crtwindow, s_Screenshot, 0, 0, addr Screenshot_Class, 0, 0, 378, 160, WS_MINIMIZEBOX or WS_SYSMENU, 0, 0, 0, 0, 0, hInstance
    mov hWin, eax
    cmp ini_f, 1
    jne @F
        call read_setting
    @@:
    invoke window_center, hWin
    call command_tst
    cmp eax, 1
    je @F
        invoke ShowWindow, hWin, SW_SHOWNORMAL
        invoke SendMessage, hWin, WM_NCPAINT, 1, 0
    @@:
    start_msg:
        invoke GetMessage, addr msg, 0, 0, 0
        or eax, eax
        je end_msg
        invoke tab_focus, addr msg, hWin
        cmp eax, 1
        je start_msg
        invoke TranslateMessage, addr msg
        invoke DispatchMessage, addr msg
        jmp start_msg
    end_msg:
    invoke ExitProcess, msg.wParam
;**********************************************************************************************************************************************************
ScreenshotProc proc hWnd:DWORD, uMsg:DWORD, wParam:DWORD, lParam:DWORD
LOCAL loc_m:DWORD
LOCAL ps:PAINTSTRUCT
mov ebx, uMsg
.IF uMsg== TM_COMMAND
    .if lParam== WM_LBUTTONDOWN   ;открыть настройки
        invoke ShowWindow, hWnd, SW_SHOWNORMAL  ;SW_RESTORE
        invoke SetForegroundWindow, hWnd
    .elseif lParam== WM_RBUTTONUP
        invoke GetCursorPos, addr xpt
        invoke SetForegroundWindow, hWnd
        invoke TrackPopupMenu, hMenuClose, 0, xpt.x, xpt.y, 0, hWnd, 0  ;TPM_NONOTIFY
    .elseif lParam== WM_LBUTTONDBLCLK   ;спрятать
        invoke ShowWindow, hWnd, SW_HIDE
    .endif

.ELSEIF uMsg== WM_COMMAND
    mov eax, wParam
    ror eax, 16
    .IF ax== CBN_SELENDOK || ax== EN_CHANGE || ax== BN_CLICKED
        shr eax, 16
        .IF eax== id_hotkey
            invoke reghotkey, hWnd, 2200, offset id_hotkey, offset color_hotkey
        .ELSEIF eax== id_combobox   ;режим
            invoke SendMessage, h(offset id_combobox), CB_GETCURSEL, 0, 0
            invoke SendMessage, h(offset id_combobox), CB_GETITEMDATA, eax, 0
            mov f_mod, eax
            .if f_mod!= 2
                invoke EnableMenuItem, hMenu2, 4701, MF_BYCOMMAND or MF_GRAYED or MF_DISABLED
            .else
                invoke EnableMenuItem, hMenu2, 4701, MF_BYCOMMAND or MF_ENABLED
            .endif
        .ELSEIF eax== id_combobox2   ;формат
            invoke SendMessage, h(offset id_combobox2), CB_GETCURSEL, 0, 0
            invoke SendMessage, h(offset id_combobox2), CB_GETITEMDATA, eax, 0
            mov format_f, eax
            .if format_f== 6
                invoke EnableWindow, h(offset id_Quality_avi), 1
                invoke EnableWindow, h(offset id_edit_quality_avi), 1
                invoke EnableWindow, h(offset id_updown_quality_avi), 1
                invoke EnableWindow, h(offset id_fps_avi), 1
                invoke EnableWindow, h(offset id_edit_fps_avi), 1
                invoke EnableWindow, h(offset id_updown_fps_avi), 1

                invoke SetWindowText, h(offset id_DoScreenshot), s_StartRec
            .else
                invoke EnableWindow, h(offset id_Quality_avi), 0
                invoke EnableWindow, h(offset id_edit_quality_avi), 0
                invoke EnableWindow, h(offset id_updown_quality_avi), 0
                invoke EnableWindow, h(offset id_fps_avi), 0
                invoke EnableWindow, h(offset id_edit_fps_avi), 0
                invoke EnableWindow, h(offset id_updown_fps_avi), 0

                invoke SetWindowText, h(offset id_DoScreenshot), s_DoScreenshot
            .endif
        .ELSEIF eax== id_edit_quality_avi  ;качество AVI
            invoke corr, offset id_edit_quality_avi, uc$("1"), uc$("100")
            invoke GetWindowText, h(offset id_edit_quality_avi), addr temp_str, 1024
            invoke crt__wtoi, addr temp_str
            mov quality_avi_f, eax
        .ELSEIF eax== id_edit_fps_avi  ;к\с
            invoke corr, offset id_edit_fps_avi, uc$("1"), uc$("30")
            invoke GetWindowText, h(offset id_edit_fps_avi), addr temp_str, 1024
            invoke crt__wtoi, addr temp_str
            mov fps_f, eax
        .ELSEIF eax>= 5001   ;Смена языка
            movzx ebx, ax
            sub ebx, 5000
            mov fLng, ebx
            invoke get_str, addr s_RestartProgram, 0, fLng, 0
            invoke MessageBox, hWnd, s_RestartProgram, s_Screenshot, MB_OK
        .ELSEIF eax== 3900   ;открыть папку
            mov seci.cbSize, sizeof SHELLEXECUTEINFO
            mrm seci.hwnd, hWnd
            mov seci.lpFile, offset ExplorerPath
            invoke lstrcpy, addr temp_str, uc$("/select, ")
            invoke lstrcat, addr temp_str, addr temp_str_2
            mov seci.lpParameters, offset temp_str
            mov seci.fMask, SEE_MASK_FLAG_NO_UI ;SEE_MASK_NOCLOSEPROCESS
            mov seci.nShow, SW_SHOWNORMAL
            invoke ShellExecuteEx, addr seci
        .ELSEIF eax== 3901   ;копировать путь
            invoke OpenClipboard, hWnd
            invoke EmptyClipboard
            invoke LocalAlloc, 040h, 4096
            mov h_clip, eax
            .if f_FolderForScreenshots== 0
                invoke get_folder, offset temp_str_2, uc$("screenshots"), uc$(0)
            .else
                invoke lstrcpy, offset temp_str_2, offset screenshotPath
            .endif
            invoke lstrcpy, h_clip, addr temp_str_2
            invoke SetClipboardData, CF_UNICODETEXT, h_clip
            invoke LocalFree, h_clip
            invoke CloseClipboard
        .ELSEIF eax== 2298   ;открыть настройки
            invoke ShowWindow, hWnd, SW_SHOWNORMAL  ;SW_RESTORE
            invoke SetForegroundWindow, hWnd
        .ELSEIF eax== 2297   ;о программе
            call about
        .ELSEIF eax== 2299   ;выход
            invoke PostMessage, hWnd, WM_ENDSESSION, 0, 0
        .ELSEIF eax== 4700   ;автозапуск
            .if reg_check== 1
                invoke RegOpenKey, HKEY_CURRENT_USER, offset RegP, offset hKey
                invoke RegDeleteValue, hKey, offset RegN
                invoke RegCloseKey, hKey
                invoke CheckMenuItem, hMenu2, 4700, MF_BYCOMMAND or MF_UNCHECKED
                mov reg_check, 0
                jmp @F
            .endif
            invoke MessageBox, hWnd, s_AutoRunInf, s_Screenshot, MB_OK or MB_ICONEXCLAMATION
            invoke RegOpenKey, HKEY_CURRENT_USER, offset RegP, offset hKey
            invoke GetModuleFileName, 0, addr temp_str, 2048
            invoke lstrcpy, addr temp_str_2, ucc$("\q")
            invoke lstrcat, addr temp_str_2, addr temp_str
            invoke lstrcat, addr temp_str_2, ucc$("\q m")
            invoke lstrlen, addr temp_str_2
            shl eax, 1
            add eax, 4
            invoke RegSetValueEx, hKey, offset RegN, 0, REG_SZ, offset temp_str_2, eax
            invoke RegCloseKey, hKey
            invoke CheckMenuItem, hMenu2, 4700, MF_BYCOMMAND or MF_CHECKED
            mov reg_check, 1
            @@:
        .ELSEIF eax== 4701   ;PrintWindow
            .if fPrint== 1
                invoke CheckMenuItem, hMenu2, 4701, MF_BYCOMMAND or MF_UNCHECKED
                mov fPrint, 0
                jmp @F
            .endif
            invoke CheckMenuItem, hMenu2, 4701, MF_BYCOMMAND or MF_CHECKED
            mov fPrint, 1
            @@:
        ;------------------------------
        .ELSEIF eax== 4702   ;путь для сохранения скриншотов
            invoke bfol, offset screenshotPath, s_FolderForScreenshots
            .if eax!= 0
                mov f_FolderForScreenshots, 1
                invoke lstrcpy, offset temp_str_2, s_Select
                invoke lstrcat, offset temp_str_2, ucc$(" \a")
                invoke lstrcat, offset temp_str_2, offset screenshotPath
                invoke lstrcat, offset temp_str_2, ucc$("\b")
                invoke ModifyMenu, hMenu3, 4702, MF_BYCOMMAND or MF_STRING, 4702, offset temp_str_2
                invoke CheckMenuItem, hMenu3, 4702, MF_BYCOMMAND or MF_CHECKED
                invoke CheckMenuItem, hMenu3, 4703, MF_BYCOMMAND or MF_UNCHECKED
            .endif
        .ELSEIF eax== 4703   ;рядом с программой
            mov f_FolderForScreenshots, 0
            invoke CheckMenuItem, hMenu3, 4702, MF_BYCOMMAND or MF_UNCHECKED
            invoke CheckMenuItem, hMenu3, 4703, MF_BYCOMMAND or MF_CHECKED
        ;------------------------------
        .ELSEIF eax== 4704   ;путь для сохранения видеозаписей
            invoke bfol, offset videoPath, s_FolderForVideo
            .if eax!= 0
                mov f_FolderForVideo, 1
                invoke lstrcpy, offset temp_str_2, s_Select
                invoke lstrcat, offset temp_str_2, ucc$(" \a")
                invoke lstrcat, offset temp_str_2, offset videoPath
                invoke lstrcat, offset temp_str_2, ucc$("\b")
                invoke ModifyMenu, hMenu4, 4704, MF_BYCOMMAND or MF_STRING, 4704, offset temp_str_2
                invoke CheckMenuItem, hMenu4, 4704, MF_BYCOMMAND or MF_CHECKED
                invoke CheckMenuItem, hMenu4, 4705, MF_BYCOMMAND or MF_UNCHECKED
            .endif
        .ELSEIF eax== 4705   ;рядом с программой
            mov f_FolderForVideo, 0
            invoke CheckMenuItem, hMenu4, 4704, MF_BYCOMMAND or MF_UNCHECKED
            invoke CheckMenuItem, hMenu4, 4705, MF_BYCOMMAND or MF_CHECKED
        .ENDIF
    .ENDIF

.ELSEIF uMsg== WM_SYSCOMMAND
    mov eax, wParam
    ror eax, 16
    .IF ax== BN_CLICKED
        shr eax, 16
        .IF eax== 2299   ;выход
            invoke PostMessage, hWnd, WM_ENDSESSION, 0, 0
        .ELSEIF eax== 2297   ;о программе
            call about
        .ENDIF
    .ENDIF
    jmp def_ret

.ELSEIF uMsg== WM_TIMER
    call avi_rec

.ELSEIF uMsg== WM_HOTKEY
    mov eax, wParam
    .if ax== 2200 && hPreview== 0
    .if format_f== 6        ;---AVI-------------------------------------------------------------------------------------------------------------------------
        .if avi_f== 0
            mov avi_f, 1
            .if f_mod== 0       ;----------------------------------весь экран
                invoke GetSystemMetrics, SM_CXSCREEN
                mov monx, eax
                invoke GetSystemMetrics, SM_CYSCREEN
                mov mony, eax
                invoke avi_ini, 0, 0, monx, mony, quality_avi_f, fps_f
            .elseif f_mod== 1   ;------------------------------участок экрана
                .if hSelectFrame== 0
                    mov avi_f, 0
                    invoke GetForegroundWindow
                    mov hFocus, eax
                    invoke select_frame, hWin, hInstance
                    mov hSelectFrame, eax
                    invoke EnableWindow, hWnd, 0
                    invoke SetCapture, hWnd
                    return 0
                .endif
                invoke ReleaseCapture
                invoke EnableWindow, hWnd, 1
                invoke GetWindowLong, hSelectFrame, 20
                mov focus_rct.left, eax
                invoke GetWindowLong, hSelectFrame, 24
                mov focus_rct.top, eax
                invoke GetWindowLong, hSelectFrame, 28
                mov focus_rct.right, eax
                invoke GetWindowLong, hSelectFrame, 32
                mov focus_rct.bottom, eax
                invoke ShowWindow, hSelectFrame, SW_HIDE
                invoke DestroyWindow, hSelectFrame
                mov hSelectFrame, 0
                invoke avi_ini, focus_rct.left, focus_rct.top, focus_rct.right, focus_rct.bottom, quality_avi_f, fps_f
            .elseif f_mod== 2   ;------------------------------окно под курсором
                invoke GetCursorPos, addr xpt
                invoke WindowFromPoint, xpt.x, xpt.y
                mov Xhwnd, eax
                invoke GetWindowRect, Xhwnd, addr rct
                mov eax, rct.right
                sub eax, rct.left
                mov rct.right, eax
                mov ebx, rct.bottom
                sub ebx, rct.top
                mov rct.bottom, ebx
                invoke avi_ini, rct.left, rct.top, rct.right, rct.bottom, quality_avi_f, fps_f
            .endif
            invoke EnableWindow, h(offset id_combobox), 0
            invoke EnableWindow, h(offset id_combobox2), 0
            invoke EnableWindow, h(offset id_hotkey), 0
            invoke EnableWindow, h(offset id_edit_quality_avi), 0
            invoke EnableWindow, h(offset id_edit_fps_avi), 0
            invoke EnableWindow, h(offset id_updown_quality_avi), 0
            invoke EnableWindow, h(offset id_updown_fps_avi), 0
            
            invoke SetWindowText, h(offset id_DoScreenshot), s_StopRec
            invoke Beep, 3000, 300
            mov loc_m, 1000
            finit
            fild loc_m
            fidiv fps_f
            fistp loc_m
            fwait
            invoke SetTimer, hWin, 2001, loc_m, 0
        .else
            mov avi_f, 0
            invoke KillTimer, hWin, 2001
            call avi_end
            invoke PostMessage, hWin, WM_COMMAND, xparam(BN_CLICKED, 3900), 0   ;открыть папку
            invoke EnableWindow, h(offset id_combobox), 1
            invoke EnableWindow, h(offset id_combobox2), 1
            invoke EnableWindow, h(offset id_hotkey), 1
            invoke EnableWindow, h(offset id_edit_quality_avi), 1
            invoke EnableWindow, h(offset id_edit_fps_avi), 1
            invoke EnableWindow, h(offset id_updown_quality_avi), 1
            invoke EnableWindow, h(offset id_updown_fps_avi), 1
            
            invoke SetWindowText, h(offset id_DoScreenshot), s_StartRec
        .endif
    .else   ;---SCR-----------------------------------------------------------------------------------------------------------------------------------------
        .if f_mod== 0       ;----------------------------------весь экран
            invoke GetSystemMetrics, SM_CXSCREEN
            mov monx, eax
            invoke GetSystemMetrics, SM_CYSCREEN
            mov mony, eax
            invoke scr_shot, 0, 0, monx, mony
        .elseif f_mod== 1   ;------------------------------участок экрана
            .if hSelectFrame== 0
                invoke GetForegroundWindow
                mov hFocus, eax
                invoke select_frame, hWin, hInstance
                mov hSelectFrame, eax
                invoke EnableWindow, hWnd, 0
                invoke SetCapture, hWnd
                return 0
            .endif
            invoke ReleaseCapture
            invoke EnableWindow, hWnd, 1
            invoke GetWindowLong, hSelectFrame, 20
            mov focus_rct.left, eax
            invoke GetWindowLong, hSelectFrame, 24
            mov focus_rct.top, eax
            invoke GetWindowLong, hSelectFrame, 28
            mov focus_rct.right, eax
            invoke GetWindowLong, hSelectFrame, 32
            mov focus_rct.bottom, eax
            invoke ShowWindow, hSelectFrame, SW_HIDE
            invoke DestroyWindow, hSelectFrame
            mov hSelectFrame, 0
            invoke scr_shot, focus_rct.left, focus_rct.top, focus_rct.right, focus_rct.bottom
        .elseif f_mod== 2   ;------------------------------окно под курсором
            invoke GetCursorPos, addr xpt
            invoke WindowFromPoint, xpt.x, xpt.y
            mov Xhwnd, eax
            invoke GetWindowRect, Xhwnd, addr rct
            mov eax, rct.right
            sub eax, rct.left
            mov rct.right, eax
            mov ebx, rct.bottom
            sub ebx, rct.top
            mov rct.bottom, ebx
            invoke scr_shot, rct.left, rct.top, rct.right, rct.bottom
        .endif
    .endif
    .endif

.ELSEIF uMsg== WM_CREATE
    invoke GetWindowsDirectory, offset ExplorerPath, MAX_PATH
    invoke lstrcat, offset ExplorerPath, uc$("\explorer.exe")
    invoke GetSystemDirectory, offset SystemPath, 2048
    invoke lstrcpy, offset temp_str, offset SystemPath
    invoke lstrcat, offset temp_str, uc$("\avifil32.dll")
    invoke FindFirstFile, offset temp_str, addr wfd
    .if eax== INVALID_HANDLE_VALUE
        invoke lstrcpy, offset temp_str, offset SystemPath
        invoke lstrcat, offset temp_str, uc$("\vfw32.dll")
        invoke FindFirstFile, offset temp_str, addr wfd
        .if eax== INVALID_HANDLE_VALUE
            mov hdll, 0
        .else
            invoke FindClose, eax
            invoke LoadLibrary, offset temp_str
            mov hdll, eax
        .endif
    .else
        invoke FindClose, eax
        invoke LoadLibrary, offset temp_str
        mov hdll, eax
    .endif
    .if hdll!= 0
        invoke GetProcAddress, hdll, SADD("AVIFileInit")
        mov AVIFileInit, eax
        invoke GetProcAddress, hdll, SADD("AVIFileOpenW")
        mov AVIFileOpen, eax
        invoke GetProcAddress, hdll, SADD("AVIFileCreateStreamW")
        mov AVIFileCreateStream, eax
        invoke GetProcAddress, hdll, SADD("AVIMakeCompressedStream")
        mov AVIMakeCompressedStream, eax
        invoke GetProcAddress, hdll, SADD("AVIStreamSetFormat")
        mov AVIStreamSetFormat, eax
        invoke GetProcAddress, hdll, SADD("AVIFileRelease")
        mov AVIFileRelease, eax
        invoke GetProcAddress, hdll, SADD("AVIStreamEndStreaming")
        mov AVIStreamEndStreaming, eax
        invoke GetProcAddress, hdll, SADD("AVISaveOptions")
        mov AVISaveOptions, eax
        invoke GetProcAddress, hdll, SADD("AVIStreamRelease")
        mov AVIStreamRelease, eax
        invoke GetProcAddress, hdll, SADD("AVIFileExit")
        mov AVIFileExit, eax
        invoke GetProcAddress, hdll, SADD("AVIStreamStart")
        mov AVIStreamStart, eax
        invoke GetProcAddress, hdll, SADD("AVIStreamWrite")
        mov AVIStreamWrite, eax
    .endif

    invoke RegisterWindowMessage, uc$("TaskbarCreated")
    mov WM_TASKBARCREATED, eax
    invoke GetDC, 0
    mov hDC, eax
    invoke GetSystemMetrics, SM_CXSCREEN
    mov monx, eax
    invoke GetSystemMetrics, SM_CYSCREEN
    mov mony, eax
    
    invoke GetSystemMenu, hWnd, 0
    mov hSysMenu, eax
    invoke AppendMenu, hSysMenu, MF_SEPARATOR, 0, 0
    invoke AppendMenu, hSysMenu, MF_STRING, 2297, s_About
    invoke AppendMenu, hSysMenu, MF_SEPARATOR, 0, 0
    invoke AppendMenu, hSysMenu, MF_STRING, 2299, s_Exit

    invoke CreateMenu
    mov hMenu, eax
    invoke CreateLngMenu, hMenu, fLng
    invoke CreatePopupMenu
    mov hMenu2, eax
    invoke CreatePopupMenu
    mov hMenu3, eax
    invoke CreatePopupMenu
    mov hMenu4, eax
    invoke AppendMenu, hMenu, MF_POPUP or MF_STRING, hMenu2, s_AdditionalOptions
        invoke AppendMenu, hMenu2, MF_STRING, 4700, s_AutoRun
        invoke AppendMenu, hMenu2, MF_STRING, 4701, s_PrintWindow
        invoke AppendMenu, hMenu2, MF_POPUP or MF_STRING, hMenu3, s_FolderForScreenshots
            invoke AppendMenu, hMenu3, MF_STRING, 4702, s_Select
            
            invoke get_folder, offset temp_str_2, uc$("screenshots"), uc$(0)
            invoke lstrcpy, offset temp_str_3, s_NearToProgram
            invoke lstrcat, offset temp_str_3, ucc$(" \a")
            invoke lstrcat, offset temp_str_3, offset temp_str_2
            invoke lstrcat, offset temp_str_3, ucc$("\b")
            invoke AppendMenu, hMenu3, MF_STRING, 4703, offset temp_str_3
        invoke AppendMenu, hMenu2, MF_POPUP or MF_STRING, hMenu4, s_FolderForVideo
            invoke AppendMenu, hMenu4, MF_STRING, 4704, s_Select
            
            invoke get_folder, offset temp_str_2, uc$("avi_files"), uc$(0)
            invoke lstrcpy, offset temp_str_3, s_NearToProgram
            invoke lstrcat, offset temp_str_3, ucc$(" \a")
            invoke lstrcat, offset temp_str_3, offset temp_str_2
            invoke lstrcat, offset temp_str_3, ucc$("\b")
            invoke AppendMenu, hMenu4, MF_STRING, 4705, offset temp_str_3
    invoke SetMenu, hWnd, hMenu
    ;***************************
    invoke EnableMenuItem, hMenu2, 4701, MF_BYCOMMAND or MF_GRAYED or MF_DISABLED
    invoke CheckMenuItem, hMenu3, 4703, MF_BYCOMMAND or MF_CHECKED
    invoke CheckMenuItem, hMenu4, 4705, MF_BYCOMMAND or MF_CHECKED
    ;***************************

    invoke crtwindow, 0, offset id_hotkey, hWnd, offset hotkey, 40, 15, 100, 25, 050000000h, 0, offset VerdanaFont, 14, 400, 0, hInstance
    invoke SendMessage, eax, HKM_SETRULES, HKCOMB_SC or HKCOMB_CA or HKCOMB_SA or HKCOMB_SCA, HOTKEYF_CONTROL
    invoke crtwindow, 0, offset id_static_1, hWnd, offset static, 5, 5, 370, 45, 050000012h, 0, offset VerdanaFont, 14, 400, 0, hInstance
    invoke crtwindow, s_DoScreenshot, offset id_DoScreenshot, hWnd, offset static, 145, 15, 195, 25, 050000200h, 0, offset VerdanaFont, 14, 400, 0, hInstance

    invoke crtwindow, 0, offset id_static_2, hWnd, offset static, 5, 55, 370, 100, 050000012h, 0, offset VerdanaFont, 14, 400, 0, hInstance
    invoke crtwindow, 0, offset id_combobox, hWnd, offset combobox, 10, 60, 358, 110, 050200003h, 0, offset VerdanaFont, 14, 400, 0, hInstance
    invoke SendMessage, h(offset id_combobox), CB_ADDSTRING, 0, s_FullScreen
    invoke SendMessage, h(offset id_combobox), CB_SETITEMDATA, 0, 0
    invoke SendMessage, h(offset id_combobox), CB_ADDSTRING, 0, s_PortionScreen
    invoke SendMessage, h(offset id_combobox), CB_SETITEMDATA, 1, 1
    invoke SendMessage, h(offset id_combobox), CB_ADDSTRING, 0, s_WindowUnderCursor
    invoke SendMessage, h(offset id_combobox), CB_SETITEMDATA, 2, 2
    invoke SendMessage, h(offset id_combobox), CB_SETCURSEL, 0, 0
    
    invoke crtwindow, 0, offset id_combobox2, hWnd, offset combobox, 10, 90, 120, 110, 050200003h, 0, offset VerdanaFont, 14, 400, 0, hInstance
    invoke SendMessage, h(offset id_combobox2), CB_ADDSTRING, 0, uc$("BMP")
    invoke SendMessage, h(offset id_combobox2), CB_SETITEMDATA, 0, 0
    invoke SendMessage, h(offset id_combobox2), CB_ADDSTRING, 0, uc$("JPG")
    invoke SendMessage, h(offset id_combobox2), CB_SETITEMDATA, 1, 1
    invoke SendMessage, h(offset id_combobox2), CB_ADDSTRING, 0, uc$("PNG")
    invoke SendMessage, h(offset id_combobox2), CB_SETITEMDATA, 2, 2
    invoke SendMessage, h(offset id_combobox2), CB_ADDSTRING, 0, uc$("GIF")
    invoke SendMessage, h(offset id_combobox2), CB_SETITEMDATA, 3, 3
    invoke SendMessage, h(offset id_combobox2), CB_ADDSTRING, 0, uc$("TIF")
    invoke SendMessage, h(offset id_combobox2), CB_SETITEMDATA, 4, 4
    invoke SendMessage, h(offset id_combobox2), CB_ADDSTRING, 0, uc$("ICO")
    invoke SendMessage, h(offset id_combobox2), CB_SETITEMDATA, 5, 5
    .if hdll!= 0
        invoke SendMessage, h(offset id_combobox2), CB_ADDSTRING, 0, uc$("AVI")
        invoke SendMessage, h(offset id_combobox2), CB_SETITEMDATA, 6, 6
    .endif
    invoke SendMessage, h(offset id_combobox2), CB_SETCURSEL, 0, 0
    invoke crtwindow, s_Quality_avi, offset id_Quality_avi, hWnd, offset static, 140, 90, 155, 25, 050000200h or SS_RIGHT or WS_DISABLED, 0, offset VerdanaFont, 14, 400, 0, hInstance
    invoke crtwindow, 0, offset id_edit_quality_avi, hWnd, offset edit, 304, 90, 80, 25, 050002001h or WS_DISABLED, 000000200h, offset VerdanaFont, 14, 400, 0, hInstance
    invoke crtwindow, 0, offset id_updown_quality_avi, hWnd, offset updown, 0, 0, 20, 20, 050000037h or WS_DISABLED, 0, offset VerdanaFont, 14, 400, 0, hInstance
    invoke SendMessage, eax, UDM_SETBUDDY, h(offset id_edit_quality_avi), 0
    invoke SendMessage, h(offset id_updown_quality_avi), UDM_SETBASE, 10, 0
    invoke SendMessage, h(offset id_updown_quality_avi), UDM_SETRANGE32, 1, 100
    invoke SendMessage, h(offset id_updown_quality_avi), UDM_SETPOS32, 0, 50
    invoke SendMessage, h(offset id_edit_quality_avi), EM_SETLIMITTEXT, 3, 0
    invoke crtwindow, s_FPS, offset id_fps_avi, hWnd, offset static, 140, 120, 155, 25, 050000200h or SS_RIGHT or WS_DISABLED, 0, offset VerdanaFont, 14, 400, 0, hInstance
    invoke crtwindow, 0, offset id_edit_fps_avi, hWnd, offset edit, 304, 120, 80, 25, 050002001h or WS_DISABLED, 000000200h, offset VerdanaFont, 14, 400, 0, hInstance
    invoke crtwindow, 0, offset id_updown_fps_avi, hWnd, offset updown, 0, 0, 20, 20, 050000037h or WS_DISABLED, 0, offset VerdanaFont, 14, 400, 0, hInstance
    invoke SendMessage, eax, UDM_SETBUDDY, h(offset id_edit_fps_avi), 0
    invoke SendMessage, h(offset id_updown_fps_avi), UDM_SETBASE, 10, 0
    invoke SendMessage, h(offset id_updown_fps_avi), UDM_SETRANGE32, 1, 30
    invoke SendMessage, h(offset id_updown_fps_avi), UDM_SETPOS32, 0, 10
    invoke SendMessage, h(offset id_edit_fps_avi), EM_SETLIMITTEXT, 2, 0
    
    invoke RegOpenKey, HKEY_CURRENT_USER, offset RegP, offset hKey
    invoke RegQueryValueEx, hKey, offset RegN, 0, 0, addr temp_str, addr maxp
    .if eax== ERROR_SUCCESS
        invoke CheckMenuItem, hMenu2, 4700, MF_BYCOMMAND or MF_CHECKED
        mov reg_check, 1
    .else
        invoke CheckMenuItem, hMenu2, 4700, MF_BYCOMMAND or MF_UNCHECKED
        mov reg_check, 0
    .endif
    invoke RegCloseKey, hKey

    invoke CreatePopupMenu
    mov hMenuPreview, eax
    invoke AppendMenu, hMenuPreview, MF_STRING, 2301, s_Save
    invoke AppendMenu, hMenuPreview, MF_STRING, 2302, s_SaveAndOpenFolder
    invoke AppendMenu, hMenuPreview, MF_STRING, 2303, s_SaveAndCopyPath
    invoke AppendMenu, hMenuPreview, MF_SEPARATOR, 0, 0
    invoke AppendMenu, hMenuPreview, MF_STRING, 2300, s_CancelSave

    invoke CreatePopupMenu
    mov hMenuClose, eax
    invoke AppendMenu, hMenuClose, MF_STRING, 2298, s_Settings
    invoke AppendMenu, hMenuClose, MF_SEPARATOR, 0, 0
    invoke AppendMenu, hMenuClose, MF_STRING, 2297, s_About
    invoke AppendMenu, hMenuClose, MF_SEPARATOR, 0, 0
    invoke AppendMenu, hMenuClose, MF_STRING, 2299, s_Exit

    mov nid.cbSize, sizeof NOTIFYICONDATA
    mrm nid.hwnd, hWnd
    mov nid.uFlags ,NIF_ICON or NIF_TIP or NIF_MESSAGE
    mov nid.uCallbackMessage, TM_COMMAND
    mrm nid.hIcon, h_icon
    invoke lstrcpy, addr nid.szTip, s_Screenshot
    invoke Shell_NotifyIcon, NIM_ADD, addr nid
    mov tru_icon, eax

.ELSEIF ebx== WM_TASKBARCREATED
    mov nid.cbSize, sizeof NOTIFYICONDATA
    mrm nid.hwnd, hWnd
    mov nid.uFlags ,NIF_ICON or NIF_TIP or NIF_MESSAGE
    mov nid.uCallbackMessage, TM_COMMAND
    mrm nid.hIcon, h_icon
    invoke lstrcpy, addr nid.szTip, s_Screenshot
    invoke Shell_NotifyIcon, NIM_ADD, addr nid
    mov tru_icon, eax

.ELSEIF uMsg== WM_LBUTTONDOWN
    .if hSelectFrame!= 0
        invoke ReleaseCapture
        invoke DestroyWindow, hSelectFrame
        mov hSelectFrame, 0
        invoke EnableWindow, hWnd, 1
        invoke SetForegroundWindow, hFocus
    .endif
    invoke SetFocus, hWnd

.ELSEIF uMsg== WM_PAINT
    invoke BeginPaint, hWnd, addr ps
    invoke paint_proc, ps.hdc
    invoke EndPaint, hWnd, addr ps

.ELSEIF uMsg== WM_ENDSESSION
    .if hCompressStream!= 0
        invoke MessageBox, hWnd, s_StopExit, s_Screenshot, MB_OKCANCEL or MB_ICONEXCLAMATION
        .if eax== IDOK
            call avi_end
        .elseif eax== IDCANCEL
            return 0
        .endif
    .endif
    invoke ShowWindow, hWnd, SW_HIDE
    invoke Shell_NotifyIcon, NIM_DELETE, addr nid
    invoke free_lng
    call writ_setting
    invoke ReleaseDC, 0, hDC
    invoke PostQuitMessage, 0

.ELSEIF uMsg== WM_CLOSE
    .if tru_icon== 1
        invoke ShowWindow, hWnd, SW_HIDE
    .else
        invoke PostMessage, hWnd, WM_ENDSESSION, 0, 0
    .endif

.ELSEIF uMsg== WM_QUERYENDSESSION
    return 1
.ELSE
    def_ret:
    invoke DefWindowProc, hWnd, uMsg, wParam, lParam
    ret
.ENDIF
return 0
ScreenshotProc endp
;**********************************************************************************************************************************************************
scr_shot proc xds:DWORD, yds:DWORD, wds:DWORD, hds:DWORD
LOCAL hend:DWORD, rzv:DWORD, sizInfStr:DWORD, sizImg:DWORD, nxx:DWORD
LOCAL bmpinfh:BITMAPINFOHEADER, bmpfinf:BITMAPFILEHEADER, bmpinf:BITMAPINFO, btp:BITMAP
;----------------------------------------------
    mov bmpinfh.biSize, sizeof BITMAPINFOHEADER
    mrm bmpinfh.biWidth, wds
    mrm bmpinfh.biHeight, hds
    mov bmpinfh.biPlanes, 1
    mov bmpinfh.biBitCount, 24
    mov bmpinfh.biCompression, 0
    mov bmpinfh.biSizeImage, 0
    mov bmpinfh.biXPelsPerMeter, 0
    mov bmpinfh.biYPelsPerMeter, 0
    mov bmpinfh.biClrUsed, 0
    mov bmpinfh.biClrImportant, 0
    lea esi, bmpinfh
    lea edi, bmpinf
    mov ecx, sizeof BITMAPINFOHEADER
    rep movsb
;----------------------------------------------
    invoke CreateCompatibleDC, 0
    mov hDC1, eax
    invoke CreateDIBSection, hDC1, addr bmpinf, DIB_PAL_COLORS, addr nxx, 0, 0
    mov hDib, eax
    invoke SelectObject, hDC1, hDib
    .if fPrint== 1 && f_mod== 2
        invoke PrintWindow, Xhwnd, hDC1, 0  ;---PW_CLIENTONLY
    .else
        invoke BitBlt, hDC1, 0, 0, wds, hds, hDC, xds, yds, SRCCOPY
    .endif
    invoke GetTime, offset TimeBuffer
    invoke PreviewImg, wds, hds
    mov nxx, eax
    invoke DeleteDC, hDC1
    .if nxx== 0
        invoke DeleteObject, hDib
        ret
    .endif
    invoke GetObject, hDib, sizeof BITMAP, addr btp
    mov sizInfStr, sizeof BITMAPINFOHEADER
    add sizInfStr, sizeof BITMAPFILEHEADER
    invoke IntMul, btp.bmWidthBytes, btp.bmHeight
    mov sizImg, eax
;----------------------------------------------
    mov bmpfinf.bfType, 04d42h
    mov eax, sizImg
    add eax, sizInfStr
    mov bmpfinf.bfSize, eax
    mov bmpfinf.bfReserved1, 0
    mov bmpfinf.bfReserved2, 0
    mrm bmpfinf.bfOffBits, sizInfStr
;----------------------------------------------
    mov bmpinfh.biSize, sizeof BITMAPINFOHEADER
    mrm bmpinfh.biWidth, btp.bmWidth
    mrm bmpinfh.biHeight, btp.bmHeight
    mov ax, btp.bmPlanes
    mov bmpinfh.biPlanes, ax
    mov ax, btp.bmBitsPixel
    mov bmpinfh.biBitCount, ax
    mov bmpinfh.biCompression, BI_RGB
    mrm bmpinfh.biSizeImage, sizImg
    mov bmpinfh.biXPelsPerMeter, 0
    mov bmpinfh.biYPelsPerMeter, 0
    mov bmpinfh.biClrUsed, 0
    mov bmpinfh.biClrImportant, 0
;----------------------------------------------
    .if f_FolderForScreenshots== 0
        invoke get_folder, offset temp_str_2, uc$("screenshots"), offset TimeBuffer
    .else
        invoke lstrcpy, offset temp_str_2, offset screenshotPath
        invoke lstrcat, offset temp_str_2, offset TimeBuffer
    .endif
    invoke CreateFile, offset temp_str_2, GENERIC_WRITE, FILE_SHARE_WRITE, 0, CREATE_ALWAYS, FILE_ATTRIBUTE_HIDDEN, 0
    mov hend, eax
    invoke WriteFile, hend, addr bmpfinf, sizeof BITMAPFILEHEADER, addr rzv, 0
    invoke WriteFile, hend, addr bmpinfh, sizeof BITMAPINFOHEADER, addr rzv, 0
    invoke WriteFile, hend, btp.bmBits, sizImg, addr rzv, 0
    invoke CloseHandle, hend
    invoke DeleteObject, hDib
    invoke img_conv, offset temp_str_2, format_f
    .if nxx== 2     ;перейти в папку
        invoke PostMessage, hWin, WM_COMMAND, xparam(BN_CLICKED, 3900), 0
    .elseif nxx== 3 ;копировать путь
        invoke PostMessage, hWin, WM_COMMAND, xparam(BN_CLICKED, 3901), 0
    .endif
ret
scr_shot endp
;**********************************************************************************************************************************************************
PreviewImg proc www:DWORD, hhh:DWORD
LOCAL msg1:MSG, www1:DWORD, hhh1:DWORD
    mov wc.style, CS_HREDRAW or CS_VREDRAW or CS_NOCLOSE
    mov wc.lpfnWndProc, offset ProcPreview
    invoke CreateSolidBrush, 0bbbbbbh
    mov wc.hbrBackground, eax
    mov wc.lpszClassName, offset Class_Preview
    invoke RegisterClassEx, addr wc
    mrm www1, www
    add www1, 80
    mov eax, www1
    .if eax> monx
        mrm www1, monx
    .elseif eax< 300
        mov www1, 300
    .endif
    mrm hhh1, hhh
    add hhh1, 80
    mov eax, hhh1
    .if eax> mony
        mrm hhh1, mony
    .endif
    ;---------------------
    mrm www2, www
    mov eax, www1
    sub eax, www2
    .if eax> 02710h
        xor eax, eax
    .endif
    .if eax< 80
        mov edx, 80
        sub edx, eax
        sub www2, edx
        mov eax, 80
    .endif
    shr eax, 1
    mov xxx1, eax
    ;---------------------
    mrm hhh2, hhh
    mov eax, hhh1
    sub eax, hhh2
    .if eax> 02710h
        xor eax, eax
    .endif
    .if eax< 80
        mov edx, 80
        sub edx, eax
        sub hhh2, edx
        mov eax, 80
    .endif
    shr eax, 1
    mov yyy1, eax
    ;---------------------
    mrm www3, www
    mrm hhh3, hhh
    invoke crtwindow, 0, 0, 0, addr Class_Preview, 0, 0, www1, hhh1, WS_POPUP or WS_BORDER, WS_EX_TOPMOST or WS_EX_TOOLWINDOW, 0, 0, 0, 0, hInstance
    mov hPreview, eax
    invoke window_center, hPreview
    invoke ShowWindow, hPreview, SW_SHOWNORMAL
    invoke SetForegroundWindow, hPreview
    .if tru_icon== 1
      ;  invoke ShowWindow, hWin, SW_HIDE
    .endif
    invoke EnableWindow, hWin, 0
    @@:
        invoke GetMessage, addr msg1, 0, 0, 0
        or eax, eax
        je @F
        cmp msg1.message, PM_QUIT
        je @F
        invoke TranslateMessage, addr msg1
        invoke DispatchMessage, addr msg1
        jmp @B
    @@:
    invoke EnableWindow, hWin, 1
    invoke GetWindowText, h(offset id_edit_name), offset TimeBuffer, 256
    invoke DestroyWindow, hPreview
    mov hPreview, 0
return msg1.wParam
PreviewImg endp
;**********************************************************************************************************************************************************
ProcPreview proc hWnd:DWORD, uMsg:DWORD, wParam:DWORD, lParam:DWORD
LOCAL ps:PAINTSTRUCT
.IF uMsg== WM_COMMAND
    mov eax, wParam
    ror eax, 16
    .IF ax== BN_CLICKED
        ror eax, 16
        .IF ax== 2300   ;отмена
            invoke PostMessage, hPreview, PM_QUIT, 0, 0
        .ELSEIF ax>= 2301 && ax<= 2303   ;1- сохранить, 2- сохранить и перейти в папку, 3- сохранить и копировать путь
            movzx ebx, ax
            sub ebx, 2300
            call FindName
            cmp eax, 1
            jne @F
                invoke PostMessage, hPreview, PM_QUIT, ebx, 0
            @@:
        .ENDIF
    .ENDIF

.ELSEIF uMsg== WM_ACTIVATEAPP; || uMsg== WM_ACTIVATE
    mov eax, wParam
    .if ax== 0
        invoke PostMessage, hPreview, PM_QUIT, 0, 0   ;отмена
    .endif

.ELSEIF uMsg== WM_DISPLAYCHANGE
    invoke PostMessage, hPreview, PM_QUIT, 0, 0   ;отмена

.ELSEIF uMsg== WM_CREATE
    invoke crtwindow, offset TimeBuffer, offset id_edit_name, hWnd, offset edit, 0, 0, 295, 25, WS_CHILD or WS_VISIBLE or ES_AUTOHSCROLL, 000000200h, offset VerdanaFont, 14, 400, 0, hInstance
    invoke SendMessage, eax, EM_SETLIMITTEXT, 250, 0
    invoke SetFocus, h(offset id_edit_name)
    invoke SendMessage, h(offset id_edit_name), EM_SETSEL, 0, -1
    invoke SetWindowLong, h(offset id_edit_name), GWL_WNDPROC, offset ENProc
    mov hENProc, eax

.ELSEIF uMsg== WM_PAINT
    invoke BeginPaint, hWnd, addr ps
    invoke StretchBlt, eax, xxx1, yyy1, www2, hhh2, hDC1, 0, 0, www3, hhh3, SRCCOPY
    invoke EndPaint, hWnd, addr ps

.ELSEIF uMsg== WM_LBUTTONDOWN
    invoke SetFocus, h(offset id_edit_name)

.ELSEIF uMsg== WM_CONTEXTMENU
    invoke GetCursorPos, addr xpt
    invoke TrackPopupMenu, hMenuPreview, 0, xpt.x, xpt.y, 0, hWnd, 0
.ELSE
    invoke DefWindowProc, hWnd, uMsg, wParam, lParam
    ret
.ENDIF
return 0
ProcPreview endp
;**********************************************************************************************************************************************************
FindName proc uses ebx
    invoke GetWindowText, h(offset id_edit_name), offset TimeBuffer, 256
    .if format_f== 0
        invoke lstrcat, offset TimeBuffer, uc$(".bmp")
    .elseif format_f== 1
        invoke lstrcat, offset TimeBuffer, uc$(".jpg")
    .elseif format_f== 2
        invoke lstrcat, offset TimeBuffer, uc$(".png")
    .elseif format_f== 3
        invoke lstrcat, offset TimeBuffer, uc$(".gif")
    .elseif format_f== 4
        invoke lstrcat, offset TimeBuffer, uc$(".tif")
    .elseif format_f== 5
        invoke lstrcat, offset TimeBuffer, uc$(".ico")
    .endif
    .if f_FolderForScreenshots== 0
        invoke get_folder, offset temp_str_2, uc$("screenshots"), offset TimeBuffer
    .else
        invoke lstrcpy, offset temp_str_2, offset screenshotPath
        invoke lstrcat, offset temp_str_2, offset TimeBuffer
    .endif
    invoke FindFirstFile, offset temp_str_2, offset wfd
    cmp eax, INVALID_HANDLE_VALUE
    jne @F
        return 1
    @@:
    invoke FindClose, eax
    invoke MessageBox, hPreview, s_StopSave, s_Screenshot, MB_OKCANCEL or MB_ICONEXCLAMATION
    .if eax== IDOK
        invoke DeleteFile, offset temp_str_2
        return 1
    .endif
    invoke SetFocus, h(offset id_edit_name)
return 0
FindName endp
;**********************************************************************************************************************************************************
ENProc proc hEdit:DWORD, uMsg:DWORD, wParam:DWORD, lParam:DWORD
    .if uMsg== WM_KEYDOWN
        .if wParam== VK_RETURN
            invoke GetWindowRect, hEdit, addr rct
            add rct.left, 5
            add rct.top, 30
            invoke TrackPopupMenu, hMenuPreview, 0, rct.left, rct.top, 0, hPreview, 0
        .endif
    .endif
    invoke CallWindowProc, hENProc, hEdit, uMsg, wParam, lParam
ret
ENProc endp
;**********************************************************************************************************************************************************
writ_setting proc
LOCAL loc_m:DWORD
    invoke set_data, 0, addr fLng, 4
    invoke SendMessage, h(offset id_hotkey), HKM_GETHOTKEY, 0, 0
    mov loc_m, eax
    invoke set_data, 0, addr loc_m, 4
    invoke set_data, 0, addr f_mod, 4
    invoke set_data, 0, addr format_f, 4
    invoke set_data, 0, addr quality_avi_f, 4
    invoke set_data, 0, addr fps_f, 4
    invoke set_data, 0, addr fPrint, 4
    invoke set_data, 0, addr f_FolderForScreenshots, 4
    .if f_FolderForScreenshots== 1
        invoke set_data, 0, addr screenshotPath, STR_W
    .endif
    invoke set_data, 0, addr f_FolderForVideo, 4
    .if f_FolderForVideo== 1
        invoke set_data, 0, addr videoPath, STR_W
    .endif
    invoke write_ini
ret
writ_setting endp
;**********************************************************************************************************************************************************
read_setting proc
LOCAL loc_m:DWORD
    invoke get_data, 0, addr loc_m
    invoke SendMessage, h(offset id_hotkey), HKM_SETHOTKEY, loc_m, 0
    invoke SendMessage, hWin, WM_COMMAND, xparam(EN_CHANGE, id_hotkey), 0
    invoke get_data, 0, addr f_mod
    invoke SendMessage, h(offset id_combobox), CB_SETCURSEL, f_mod, 0
    invoke SendMessage, hWin, WM_COMMAND, xparam(CBN_SELENDOK, id_combobox), 0
    invoke get_data, 0, addr format_f
    invoke SendMessage, h(offset id_combobox2), CB_SETCURSEL, format_f, 0
    invoke SendMessage, hWin, WM_COMMAND, xparam(CBN_SELENDOK, id_combobox2), 0
    invoke get_data, 0, addr quality_avi_f
    invoke SendMessage, h(offset id_updown_quality_avi), UDM_SETPOS32, 0, quality_avi_f
    invoke get_data, 0, addr fps_f
    invoke SendMessage, h(offset id_updown_fps_avi), UDM_SETPOS32, 0, fps_f
    invoke get_data, 0, addr fPrint
    .if fPrint== 0
        invoke CheckMenuItem, hMenu2, 4701, MF_BYCOMMAND or MF_UNCHECKED
    .elseif fPrint== 1
        invoke CheckMenuItem, hMenu2, 4701, MF_BYCOMMAND or MF_CHECKED
    .endif
    invoke get_data, 0, addr f_FolderForScreenshots
    .if f_FolderForScreenshots== 0
        invoke CheckMenuItem, hMenu3, 4702, MF_BYCOMMAND or MF_UNCHECKED
        invoke CheckMenuItem, hMenu3, 4703, MF_BYCOMMAND or MF_CHECKED
    .elseif f_FolderForScreenshots== 1
        invoke get_data, 0, addr screenshotPath
        invoke lstrcpy, offset temp_str_2, s_Select
        invoke lstrcat, offset temp_str_2, ucc$(" \a")
        invoke lstrcat, offset temp_str_2, offset screenshotPath
        invoke lstrcat, offset temp_str_2, ucc$("\b")
        invoke ModifyMenu, hMenu3, 4702, MF_BYCOMMAND or MF_STRING, 4702, offset temp_str_2
        invoke CheckMenuItem, hMenu3, 4702, MF_BYCOMMAND or MF_CHECKED
        invoke CheckMenuItem, hMenu3, 4703, MF_BYCOMMAND or MF_UNCHECKED
    .endif
    invoke get_data, 0, addr f_FolderForVideo
    .if f_FolderForVideo== 0
        invoke CheckMenuItem, hMenu4, 4704, MF_BYCOMMAND or MF_UNCHECKED
        invoke CheckMenuItem, hMenu4, 4705, MF_BYCOMMAND or MF_CHECKED
    .elseif f_FolderForVideo== 1
        invoke get_data, 0, addr videoPath
        invoke lstrcpy, offset temp_str_2, s_Select
        invoke lstrcat, offset temp_str_2, ucc$(" \a")
        invoke lstrcat, offset temp_str_2, offset videoPath
        invoke lstrcat, offset temp_str_2, ucc$("\b")
        invoke ModifyMenu, hMenu4, 4704, MF_BYCOMMAND or MF_STRING, 4704, offset temp_str_2
        invoke CheckMenuItem, hMenu4, 4704, MF_BYCOMMAND or MF_CHECKED
        invoke CheckMenuItem, hMenu4, 4705, MF_BYCOMMAND or MF_UNCHECKED
    .endif
ret
read_setting endp
;**********************************************************************************************************************************************************
GetTime proc time_buf:DWORD
LOCAL stmt:SYSTEMTIME
    invoke GetLocalTime, addr stmt
    movzx ebx, stmt.wDay
    invoke lstrcpy, time_buf, ustr$(ebx)
    invoke lstrcat, time_buf, uc$("-")
    movzx ebx, stmt.wMonth
    invoke lstrcat, time_buf, ustr$(ebx)
    invoke lstrcat, time_buf, uc$("-")
    movzx ebx, stmt.wYear
    invoke lstrcat, time_buf, ustr$(ebx)
    invoke lstrcat, time_buf, uc$("_")
    movzx ebx, stmt.wHour
    invoke lstrcat, time_buf, ustr$(ebx)
    invoke lstrcat, time_buf, uc$("h-")
    movzx ebx, stmt.wMinute
    invoke lstrcat, time_buf, ustr$(ebx)
    invoke lstrcat, time_buf, uc$("m-")
    movzx ebx, stmt.wSecond
    invoke lstrcat, time_buf, ustr$(ebx)
    invoke lstrcat, time_buf, uc$("s-")
    movzx ebx, stmt.wMilliseconds
    invoke lstrcat, time_buf, ustr$(ebx)
    invoke lstrcat, time_buf, uc$("ms")
return time_buf
GetTime endp
;**********************************************************************************************************************************************************
get_folder proc loc_buf:DWORD, stri_fold:DWORD, stri_ex:DWORD
    invoke GetModuleFileName, 0, loc_buf, 2048
    mov eax, loc_buf
    @@:
    mov bx, word ptr[eax]
    .if bx== 0005ch  ;\
        mov ecx, eax
        add ecx, 2
    .elseif bx== 0
        jmp @F
    .endif
    add eax, 2
    jmp @B
    @@:
    mov word ptr[ecx], 0
    invoke lstrcat, loc_buf, stri_fold
    invoke FindFirstFile, loc_buf, addr wfd
    .if eax== INVALID_HANDLE_VALUE
        invoke CreateDirectory, loc_buf, 0
    .else
        invoke FindClose, eax
    .endif
    invoke lstrcpy, addr temp_str_3, loc_buf
    invoke lstrcat, loc_buf, uc$("\")
    invoke lstrcat, loc_buf, stri_ex
return loc_buf
get_folder endp
;**********************************************************************************************************************************************************
avi_ini proc xds:DWORD, yds:DWORD, wds:DWORD, hds:DWORD, nqual:DWORD, nrate:DWORD
LOCAL nxx:DWORD, newf:DWORD
LOCAL bmpinfh:BITMAPINFOHEADER, bmpinf:BITMAPINFO
    mrm rct.left, xds
    mrm rct.top, yds
    mrm rct.right, wds
    mrm rct.bottom, hds
    mov bmpinfh.biSize, sizeof BITMAPINFOHEADER
    mrm bmpinfh.biWidth, wds
    mrm bmpinfh.biHeight, hds
    mov bmpinfh.biPlanes, 1
    mov bmpinfh.biBitCount, 24
    mov bmpinfh.biCompression, BI_RGB
    mov bmpinfh.biSizeImage, 0
    mov bmpinfh.biXPelsPerMeter, 0
    mov bmpinfh.biYPelsPerMeter, 0
    mov bmpinfh.biClrUsed, 0
    mov bmpinfh.biClrImportant, 0
    lea esi, bmpinfh
    lea edi, bmpinf
    mov ecx, sizeof BITMAPINFOHEADER
    rep movsb
    
    call AVIFileInit
    invoke GetTime, offset TimeBuffer
    invoke lstrcat, offset TimeBuffer, uc$(".avi")
    .if f_FolderForVideo== 0
        invoke get_folder, offset temp_str_2, uc$("avi_files"), offset TimeBuffer
    .else
        invoke lstrcpy, offset temp_str_2, offset videoPath
        invoke lstrcat, offset temp_str_2, offset TimeBuffer
    .endif
    lea ebx, newf
    avi_invoke AVIFileOpen, ebx, offset temp_str_2, OF_WRITE or OF_CREATE, 0
    mrm avis.fccType, streamtypeVIDEO
    mov avis.dwScale, 1
    mrm avis.dwRate, nrate                     ;кадров в секунду
    mrm avis.fccHandler, 0
    mov avis.dwFlags, 0
    mov avis.dwStart, 0
    mov avis.dwLength, 1
    mov avis.dwSampleSize, 0
    mrm avis.dwSuggestedBufferSize, bmpinfh.biSizeImage
    invoke SetRect, addr avis.rcFrame, 0, 0, bmpinfh.biWidth, bmpinfh.biHeight
    avi_invoke AVIFileCreateStream, newf, offset hStream, offset avis
           
    mrm avco.fccType, streamtypeVIDEO
    mrm avco.fccHandler, msvc_codec
    mov nxx, 100
    finit
    fild nqual
    fimul nxx
    fistp nxx
    fwait
    mrm avco.dwQuality, nxx                    ;качество
    mov avco.dwKeyFrameEvery, 0
    mov avco.dwFlags, 0                        ;AVICOMPRESSF_DATARATE, AVICOMPRESSF_VALID
    lea ebx, bmpinfh
    mov avco.lpFormat, ebx
    mov avco.cbFormat, sizeof bmpinfh
    mov avco.dwBytesPerSecond, 0
    avi_invoke AVIMakeCompressedStream, offset hCompressStream, hStream, offset avco, 0
    lea ebx, bmpinfh
    avi_invoke AVIStreamSetFormat, hCompressStream, 0, ebx, sizeof BITMAPINFOHEADER
    push newf
    call AVIFileRelease

    invoke CreateCompatibleDC, 0
    mov hDC1, eax
    invoke CreateDIBSection, hDC1, addr bmpinf, DIB_PAL_COLORS, addr nxx, 0, 0
    mov hDib, eax
    invoke SelectObject, hDC1, hDib
ret
avi_ini endp
;**********************************************************************************************************************************************************
avi_rec proc
LOCAL sizeBuffer:DWORD
LOCAL btp:BITMAP
    .if hCompressStream!= 0
        invoke BitBlt, hDC1, 0, 0, rct.right, rct.bottom, hDC, rct.left, rct.top, SRCCOPY
        invoke GetObject, hDib, sizeof BITMAP, addr btp
        finit
        fild btp.bmWidthBytes
        fimul btp.bmHeight
        fistp sizeBuffer
        fwait
        push hCompressStream
        call AVIStreamStart
        .if eax!= -1
            inc lStart
            avi_invoke AVIStreamWrite, hCompressStream, lStart, 1, btp.bmBits, sizeBuffer, AVIIF_KEYFRAME, 0, 0
        .endif
    .endif
ret
avi_rec endp
;**********************************************************************************************************************************************************
avi_end proc
    invoke DeleteDC, hDC1
    invoke DeleteObject, hDib
    .if hStream!= 0
        push hStream
        call AVIStreamEndStreaming
        push hStream
        call AVIStreamRelease
        mov hStream, 0
    .endif
    .if hCompressStream!= 0
        push hCompressStream
        call AVIStreamEndStreaming
        push hCompressStream
        call AVIStreamRelease
        mov hCompressStream, 0
    .endif
    call AVIFileExit
    mov lStart, 0
ret
avi_end endp
;**********************************************************************************************************************************************************
command_tst proc
    mov edx, CommandLine
    xor ecx, ecx
    co_m:
    mov bx, word ptr[edx]
    .if bx== 022h   ;"
        inc ecx
        .if ecx== 2
            add edx, 2
            co_m1:
            mov bx, word ptr[edx]
            .if bx== 06dh   ;m
                return 1
            .elseif bx== 0
                return 0
            .endif
            add edx, 2
            jmp co_m1
        .endif
    .elseif bx== 0
        return 0
    .endif
    add edx, 2
    jmp co_m
command_tst endp
;**********************************************************************************************************************************************************
paint_proc proc hDCd:DWORD
LOCAL lb:LOGBRUSH
LOCAL hBrush:DWORD, hBrushOld:DWORD
    mov lb.lbStyle, BS_SOLID
    mrm lb.lbColor, color_hotkey
    mov lb.lbHatch, 0
    invoke CreateBrushIndirect, addr lb
    mov hBrush, eax
    invoke SelectObject, hDCd, hBrush
    mov hBrushOld, eax
    invoke Rectangle, hDCd, 10, 15, 35, 40
    invoke SelectObject, hDCd, hBrushOld
    invoke DeleteObject, hBrush
ret
paint_proc endp
;**********************************************************************************************************************************************************
bfol proc xPath:DWORD, xTitle:DWORD
LOCAL brin:BROWSEINFO
LOCAL loc_str[1024]:TCHAR
    invoke lstrcpy, addr loc_str, xPath
    
    mrm brin.hwndOwner, hWin
    mov brin.pidlRoot, 0
    mov brin.pszDisplayName, 0
    mrm brin.lpszTitle, xTitle
    mov brin.ulFlags, BIF_USENEWUI
    mov brin.lpfn, 0
    mov brin.lParam, 0
    mov brin.iImage, 0
    invoke SHBrowseForFolder, addr brin
    .if eax== 0
        return 0
    .endif
    invoke SHGetPathFromIDList, eax, xPath
    
    invoke lstrlen, xPath
    .if eax== 0
        invoke MessageBox, hWin, s_YouCanNotSaveInThisFolder, xTitle, MB_OK or MB_ICONEXCLAMATION
        invoke lstrcpy, xPath, addr loc_str
        return 0
    .endif
    
    mov eax, xPath
    @@:
    mov bx, word ptr[eax]
    .if bx== 0
        mov bx, word ptr[eax-2]
        .if bx!= 0005ch  ;\
            mov word ptr[eax], 0005ch  ;\
            mov word ptr[eax+2], 0
        .endif
        jmp @F
    .endif
    add eax, 2
    jmp @B
    @@:
    
    invoke lstrcpy, offset temp_str_2, xPath
    invoke lstrcat, offset temp_str_2, uc$("_test_read_write_screenshot_")
    invoke CreateFile, offset temp_str_2, GENERIC_WRITE, FILE_SHARE_WRITE, 0, CREATE_ALWAYS, FILE_ATTRIBUTE_NORMAL, 0
    .if eax== INVALID_HANDLE_VALUE
        jmp err_rw
    .else
        invoke CloseHandle, eax
        invoke CreateFile, offset temp_str_2, GENERIC_READ or GENERIC_WRITE, FILE_SHARE_READ or FILE_SHARE_WRITE, 0, OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL, 0
        .if eax== INVALID_HANDLE_VALUE
            jmp err_rw
        .else
            invoke CloseHandle, eax
            invoke DeleteFile, offset temp_str_2
            return 1
        .endif
    .endif
err_rw:
invoke MessageBox, hWin, s_FolderIsWriteProtected, xTitle, MB_OK or MB_ICONEXCLAMATION
invoke lstrcpy, xPath, addr loc_str
return 0
bfol endp
;**********************************************************************************************************************************************************
about proc
    invoke lstrcpy, addr temp_str, ucc$("Screenshot v5.2.4 © 2017 7ya\nContact: 7ya@protonmail.com\nhttps://github.com/7ya/win_asm_screenshot\n\n")
    invoke lstrcat, addr temp_str, s_Translation
    invoke about_box, hInstance, hWin, addr temp_str, s_Screenshot, MB_OK, 900
ret
about endp
;**********************************************************************************************************************************************************
end start

