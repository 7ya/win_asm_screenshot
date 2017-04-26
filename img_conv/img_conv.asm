; Author:            7ya
; Update date:       26.04.2017
; Contact:           7ya@protonmail.com
; Internet address:  https://github.com/7ya/win_asm_screenshot
; License:           GPL-3.0
;**********************************************************************************************************************************************************
__UNICODE__ equ 1
include \masm32\include\masm32rt.inc
include \masm32\include\gdiplus.inc

img_conv proto :DWORD, :DWORD

.data?
    gditoken dd ?

.code
;**********************************************************************************************************************************************************
img_conv proc img_name:DWORD, img_type:DWORD
LOCAL t_buf:DWORD, mime_type:DWORD, hImage:DWORD, encnum:DWORD, encsize:DWORD, encinfo:DWORD
LOCAL gdisi:GdiplusStartupInput
LOCAL del_name[2048]:TCHAR
    .if img_type== 0
        mov mime_type, uc$("image/bmp")
        mov t_buf, uc$(".bmp")
    .elseif img_type== 1
        mov mime_type, uc$("image/jpeg")
        mov t_buf, uc$(".jpg")
    .elseif img_type== 2
        mov mime_type, uc$("image/png")
        mov t_buf, uc$(".png")
    .elseif img_type== 3
        mov mime_type, uc$("image/gif")
        mov t_buf, uc$(".gif")
    .elseif img_type== 4
        mov mime_type, uc$("image/tiff")
        mov t_buf, uc$(".tif")
    .elseif img_type== 5
        mov mime_type, uc$("image/x-icon")
        mov t_buf, uc$(".ico")
    .else
        return img_name
    .endif
    invoke lstrcpy, addr del_name, img_name
    invoke lstrcat, img_name, t_buf

    mov gdisi.GdiplusVersion, 1
    mov gdisi.DebugEventCallback, 0
    mov gdisi.SuppressBackgroundThread, 0
    mov gdisi.SuppressExternalCodecs, 0
    invoke GdiplusStartup, addr gditoken, addr gdisi, 0
    invoke GdipLoadImageFromFile, addr del_name, addr hImage

    invoke GdipGetImageEncodersSize, addr encnum, addr encsize
    invoke VirtualAlloc, 0, encsize, MEM_COMMIT, PAGE_READWRITE
    mov encinfo, eax
    invoke GdipGetImageEncoders, encnum, encsize, encinfo

    mov ebx, encinfo
    @@:
    mov eax, [ebx.ImageCodecInfo.MimeType]
    add ebx, sizeof ImageCodecInfo
    mov ecx, eax
    invoke lstrcmp, ecx, mime_type
    test eax, eax
    jz @F
    dec encnum
    jnz @B
    @@:
    sub ebx, sizeof ImageCodecInfo

    invoke GdipSaveImageToFile, hImage, img_name, ebx, 0
    invoke VirtualFree, encinfo, 0, MEM_RELEASE
    invoke GdipDisposeImage, hImage
    invoke GdiplusShutdown, gditoken
    invoke DeleteFile, addr del_name
return 1
img_conv endp
;**********************************************************************************************************************************************************
end

