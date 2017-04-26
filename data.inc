__UNICODE__ equ 1
include \masm32\include\masm32rt.inc

includelib img_conv\img_conv.lib
includelib select_frame\select_frame.lib
includelib setti\setti.lib
includelib lang\lang.lib
includelib ex_api\ex_api.lib

includelib \masm32\lib\gdiplus.lib
include \masm32\include\gdiplus.inc
include \masm32\include\advapi32.inc
includelib \masm32\lib\advapi32.lib

avi_ini      proto :DWORD, :DWORD, :DWORD, :DWORD, :DWORD, :DWORD
scr_shot     proto :DWORD, :DWORD, :DWORD, :DWORD
ENProc       proto :DWORD, :DWORD, :DWORD, :DWORD
get_folder   proto :DWORD, :DWORD, :DWORD
PreviewImg   proto :DWORD, :DWORD
bfol         proto :DWORD, :DWORD
paint_proc   proto :DWORD
GetTime      proto :DWORD
include      lib.inc

;macro
    mmioFOURCC MACRO c0, c1, c2, c3
        EXITM <(c0) or ((c1) shl 8) or ((c2) shl 16) or ((c3) shl 24)>
    ENDM

    avi_invoke MACRO a1, a2:=<0>, a3:=<0>, a4:=<0>, a5:=<0>, a6:=<0>, a7:=<0>, a8:=<0>, a9:=<0>
    LOCAL stack
    .data?
        stack dd ?
    .code
        mov stack, esp
        push a9
        push a8
        push a7
        push a6
        push a5
        push a4
        push a3
        push a2
        call a1
        mov esp, stack
    ENDM

    xparam MACRO n_const, ident
        mov ebx, ident
        mov ecx, n_const
        shl ecx, 16
        or ecx, ebx
        EXITM <ecx>
    ENDM

;struct
    AVISTREAMINFO STRUCT
        fccType                 dd ?
        fccHandler              dd ?
        dwFlags                 dd ?
        dwCaps                  dd ?
        wPriority               dw ?
        wLanguage               dw ?
        dwScale                 dd ?
        dwRate                  dd ?
        dwStart                 dd ?
        dwLength                dd ?
        dwInitialFrames         dd ?
        dwSuggestedBufferSize   dd ?
        dwQuality               dd ?
        dwSampleSize            dd ?
        rcFrame                 RECT <>
        dwEditCount             dd ?
        dwFormatChangeCount     dd ?
        szName                  TCHAR 64 dup (?)
    AVISTREAMINFO ENDS

    AVICOMPRESSOPTIONS STRUCT
        fccType                 dd ?
        fccHandler              dd ?
        dwKeyFrameEvery         dd ?
        dwQuality               dd ?
        dwBytesPerSecond        dd ?
        dwFlags                 dd ?
        lpFormat                LPVOID ?
        cbFormat                dd ?
        lpParms                 LPVOID ?
        cbParms                 dd ?
        dwInterleaveEvery       dd ?
    AVICOMPRESSOPTIONS ENDS

.const
    STR_A                   equ 0
    STR_W                   equ -1
    STR_ITALIC              equ 010000h
    STR_UNDERLINE           equ 0100h
    STR_STRIKEOUT           equ 01h
    PM_QUIT                 equ WM_USER + 160
    TM_COMMAND              equ WM_USER + 161

.data
    UC Screenshot_Class,    "Screenshot_Class", 0
    UC Class_Preview,       "Class_Preview", 0
    UC button,              "button", 0
    UC static,              "static", 0
    UC edit,                "edit", 0
    UC updown,              "msctls_updown32", 0
    UC hotkey,              "msctls_hotkey32",0
    UC combobox,            "combobox",0
    UC VerdanaFont,         "Verdana",0
   UCC RegP,                "Software\\Microsoft\\Windows\\CurrentVersion\\Run",0
    UC RegN,                "Screenshot",0

    streamtypeVIDEO         dd mmioFOURCC('v','i','d','s')
    msvc_codec              dd mmioFOURCC('M','S','V','C')
    WM_TASKBARCREATED       dd 0
    f_mod                   dd 0
    format_f                dd 0
    fLng                    dd 1
    hPreview                dd 0
    tru_icon                dd 0
    hdll                    dd 0
    lStart                  dd 0
    quality_avi_f           dd 50
    fps_f                   dd 10
    hCompressStream         dd 0
    hStream                 dd 0
    avi_f                   dd 0
    maxp                    dd 260
    reg_check               dd 0
    color_hotkey            dd 000000ffh
    fPrint                  dd 0
    f_FolderForScreenshots  dd 0
    f_FolderForVideo        dd 0

    s_Translation                   dd 0, 10000   ; Перевод
    s_RestartProgram                dd 0, 10010   ; Перезапустите программу
    s_About                         dd 0, 10020   ; О программе
    s_Save                          dd 0, 10030   ; Сохранить
    s_SaveAndOpenFolder             dd 0, 10040   ; Сохранить и открыть папку
    s_SaveAndCopyPath               dd 0, 10045   ; Сохранить и копировать путь
    s_CancelSave                    dd 0, 10050   ; Отмена
    s_StopExit                      dd 0, 10060   ; Процесс записи будет прерван, закрыть?
    s_Screenshot                    dd 0, 10070   ; Screenshot
    s_DoScreenshot                  dd 0, 10080   ; - Сделать Screenshot
    s_Preview                       dd 0, 10090   ; Предпросмотр
    s_WindowUnderCursor             dd 0, 10100   ; Окно под курсором
    s_PortionScreen                 dd 0, 10110   ; Участок экрана
    s_FullScreen                    dd 0, 10120   ; Весь экран
    s_StartRec                      dd 0, 10130   ; - Начать запись
    s_StopRec                       dd 0, 10140   ; - Остановить запись
    s_FPS                           dd 0, 10160   ; к/с
    s_Quality_avi                   dd 0, 10180   ; Качество AVI
    s_Exit                          dd 0, 10190   ; Выход
    s_StopSave                      dd 0, 10200   ; Файл с таким именем уже существует, заменить?
    s_AutoRun                       dd 0, 10210   ; Автозапуск
    s_AutoRunInf                    dd 0, 10220   ;
    s_AdditionalOptions             dd 0, 10230   ; Дополнительные опции
    s_PrintWindow                   dd 0, 10240   ; PrintWindow
    s_Settings                      dd 0, 10250   ; Настройки
    s_FolderForScreenshots          dd 0, 10260   ; Папка для скриншотов
    s_FolderForVideo                dd 0, 10270   ; Папка для видеозаписей
    s_Select                        dd 0, 10280   ; Выбрать
    s_NearToProgram                 dd 0, 10290   ; Рядом с программой
    s_YouCanNotSaveInThisFolder     dd 0, 10300   ; Нельзя сохранить в этой папке
    s_FolderIsWriteProtected        dd 0, 10310   ; Папка защищена от записи

    id_edit_name            dd 3065, 0, -1
    id_static_1             dd 3060, 0, -1
    id_static_2             dd 3055, 0, -1
    id_DoScreenshot         dd 3050, 0, -1
    id_updown_fps_avi       dd 3040, 0, -1
    id_fps_avi              dd 3035, 0, -1
    id_Quality_avi          dd 3030, 0, -1
    id_updown_quality_avi   dd 3025, 0, -1
    id_edit_fps_avi         dd 3020, 0, 0
    id_edit_quality_avi     dd 3015, 0, 0
    id_combobox2            dd 3010, 0, 0
    id_combobox             dd 3005, 0, 0
    id_hotkey               dd 3000, 0, 0
    
.data?
    hInstance               dd ?
    CommandLine             dd ?
    hWin                    dd ?
    Xhwnd                   dd ?
    monx                    dd ?
    mony                    dd ?
    hDC                     dd ?
    hDC1                    dd ?
    hDib                    dd ?
    hMenuPreview            dd ?
    hMenuClose              dd ?
    www2                    dd ?
    hhh2                    dd ?
    www3                    dd ?
    hhh3                    dd ?
    xxx1                    dd ?
    yyy1                    dd ?
    hSelectFrame            dd ?
    hMenu                   dd ?
    hMenu2                  dd ?
    hMenu3                  dd ?
    hMenu4                  dd ?
    hSysMenu                dd ?
    ini_f                   dd ?
    h_icon                  dd ?
    h_clip                  dd ?
    hENProc                 dd ?
    hKey                    dd ?
    hFocus                  dd ?

    AVIFileInit             dd ?
    AVIFileOpen             dd ?
    AVIFileCreateStream     dd ?
    AVIMakeCompressedStream dd ?
    AVIStreamSetFormat      dd ?
    AVIFileRelease          dd ?
    AVIStreamEndStreaming   dd ?
    AVISaveOptions          dd ?
    AVIStreamRelease        dd ?
    AVIFileExit             dd ?
    AVIStreamStart          dd ?
    AVIStreamWrite          dd ?

    temp_str        TCHAR 2048 dup (?)
    temp_str_2      TCHAR 2048 dup (?)
    temp_str_3      TCHAR 2048 dup (?)
    ExplorerPath    TCHAR 1024 dup (?)
    SystemPath      TCHAR 2048 dup (?)
    TimeBuffer      TCHAR 256 dup (?)
    maxpbuf         TCHAR 260 dup (?)
    videoPath       TCHAR 1024 dup (?)
    screenshotPath  TCHAR 1024 dup (?)

    avis            AVISTREAMINFO <>
    avco            AVICOMPRESSOPTIONS <>
    wc              WNDCLASSEX <>
    msg             MSG <>
    xpt             POINT <>
    rct             RECT <>
    focus_rct       RECT <>
    iccex           INITCOMMONCONTROLSEX <>
    seci            SHELLEXECUTEINFO <>
    nid             NOTIFYICONDATA <>
    wfd             WIN32_FIND_DATA <>
    
