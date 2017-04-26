;**********************************************************************************************************************************************************
;мультиязычность
;-----lang.lib
read_lng       proto :DWORD, :DWORD
get_str        proto :DWORD, :DWORD, :DWORD, :DWORD
list_lng       proto :DWORD, :DWORD
CreateLngMenu  proto :DWORD, :DWORD
free_lng       proto
;**********************************************************************************************************************************************************
;схранение настроек
;-----setti.lib
set_data       proto :DWORD, :DWORD, :DWORD
ini_ini        proto :DWORD, :DWORD
get_data       proto :DWORD, :DWORD
write_ini      proto
;**********************************************************************************************************************************************************
;дополнительные функции
;-----ex_api.lib
crtwindow      proto :DWORD, :DWORD, :DWORD, :DWORD, :DWORD, :DWORD, :DWORD, :DWORD, :DWORD, :DWORD, :DWORD, :DWORD, :DWORD, :DWORD, :DWORD
about_box      proto :DWORD, :DWORD, :DWORD, :DWORD, :DWORD, :DWORD
reghotkey      proto :DWORD, :DWORD, :DWORD, :DWORD
RetFontHEx     proto :DWORD, :DWORD, :DWORD, :DWORD
corr           proto :DWORD, :DWORD, :DWORD
fltr           proto :DWORD, :DWORD, :DWORD
tab_focus      proto :DWORD, :DWORD
window_center  proto :DWORD

h MACRO ident
    mov ebx, ident
    mov ecx, dword ptr[ebx+4]
    EXITM <ecx>
ENDM

;-----img_conv.lib
img_conv       proto :DWORD, :DWORD
;-----select_frame.lib
select_frame   proto :DWORD, :DWORD
;**********************************************************************************************************************************************************

