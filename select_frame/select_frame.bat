@echo off

echo        Assembling library modules.
echo.
\masm32\bin\ml /c /coff select_frame.asm
\masm32\bin\lib *.obj /out:select_frame.lib

dir select_frame.*

@echo off
pause