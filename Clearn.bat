@Echo off
for %%n in (*.~???, *.dcu, *.ddp, *.dof, *.tds, *.qst, *.fpd, *.sym, *.ilc, *.ild, *.tds, *.obj, *.*~)do if exist %%n del "%%n"
rem if errorlevel 1 Pause > nul

