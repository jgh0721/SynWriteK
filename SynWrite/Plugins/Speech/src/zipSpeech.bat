@echo off
set a=d:\plugin.Speech.zip

if exist %a% del %a%
start /wait winrar a -ep1 -ap"src" %a% Speech\*.pas Speech\*.dpr Speech\*.dfm zipSpeech.bat
start /wait winrar a -ep1 %a% Speech\*.dll Speech\*.inf
