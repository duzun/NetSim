@ECHO off
set srch_fl=DUzunSys\DLib\DUzun.dbl
set cpy_paths=DUzunSys\DLib\
set srch_dsks=c, d, e, J, k, l, m, n, o, p, q, r, s, t, u, v, w, x, y, z
if not "%bak_dir%."=="." set bak_dir=\%bak_dir%
if "%bak_ext%."=="." set bak_ext=*.*

for %%d in (%srch_dsks%) do if exist %%d:\nul if exist %%d:\%srch_fl% for %%n in (%bak_ext%) do for %%m in (*.%%n) do if exist %%m (for %%p in (%cpy_paths%) do ( if not exist %%d:\%%p\%bak_lng%\. md %%d:\%%p\%bak_lng%
	if not "%cd%"=="%%d:\%%p\%bak_lng%" copy "%%m" "%%d:\%%p\%bak_lng%\%%m">nul
	Echo %%d:\%%p\%bak_lng%\%%m >> %bak_log%
	Echo %%d:\%%p\%bak_lng%\%%m ) )

:end
set srch_fl=
set cpy_paths=
set srch_dsks=
set dest_dir=


rem pause>nul
