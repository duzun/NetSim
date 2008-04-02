@ECHO off
set bak_ext=pas, c, h, cpp, php, inc, js, bat, cmd, ini, inf, csv, xls, doc, htm, html, exe, dpr, dfm, bpr. cfg
set bak_lng=
set bak_log=bak_log.txt
set bak_inc_dir=

If Exist Clearn.bat call Clearn.bat
If Exist lng.bat call lng.bat

:mkdirs
If not exist .\Bak\. md Bak
set bak_dir=.\Bak\%date%
if not exist %bak_dir%\. md %bak_dir%
for %%n in (%bak_inc_dir%) do if not exist %bak_dir%\%bak_inc_dir%\. md %bak_dir%\%bak_inc_dir% 

:baking
echo ------------------------------------>>%bak_log%
echo %date%>>%bak_log% 
for %%d in (., %bak_inc_dir%) do for %%n in (%bak_ext%) do for %%m in (%%d\*.%%n) do if exist %%m (copy "%%m" "%bak_dir%\%%m">nul
Echo %%m>>%bak_log%
Echo %%m)


Echo.
if exist %bak_log% attrib +h %bak_log%>nul

:dubling
If Exist duble.bat call duble.bat
If not Exist duble.bat if not exist ..\duble.bat if exist ..\..\duble.bat call ..\..\duble.bat


:end
set bak_ext=
set bak_dir=
set bak_lng=
set bak_log=
set bak_inc_dir=

rem pause>nul
exit
