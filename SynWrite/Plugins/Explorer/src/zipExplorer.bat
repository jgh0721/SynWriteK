@echo off
set a=d:\plugin.Explorer.zip

if exist %a% del %a%
start /wait winrar a -ep1 -ap"src" %a% Explorer\*.pas Explorer\*.dpr Explorer\*.dfm zipExplorer.bat
start /wait winrar a -ep1 %a% Explorer\*.dll Explorer\*.inf Explorer\*.lng Explorer\*.txt
