@echo off

echo        Assembling library modules.
echo.
\masm32\bin\ml /c /coff img_conv.asm
\masm32\bin\lib *.obj /out:img_conv.lib

dir img_conv.*

@echo off
pause