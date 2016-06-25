{
  ************************************************************
  Program    : FindID.exe
  Created    : 30.05.2012
  Author     : RamSoft
  Description: Поиск декларированных функций, процедур и переменных в файлах проекта.
  ************************************************************
}

program findid;

{$APPTYPE CONSOLE}

{%File 'FindID'}
{%ToDo 'FindID.todo'}

uses
  SysUtils,
//  DateUtils,
  Classes,
  uCode in 'uCode.pas';

var
  i: integer;
//  t1: TDateTime;

procedure InitializationProg;
begin
  bPaths := false;
end;

procedure FinalizationProg;
begin
  lstFile.Free;
  UsesList.Free;
  Projects.Free;
end;

begin
  try
    //t1:= now;

    if CheckAbout(ParamStr(1)) then Exit;

    if not CheckParams(ParamStr(1), ParamStr(2), ParamStr(3)) then Exit;

    for i := 1 to ParamCount do
      begin
        if Pos('/paths=', ParamStr(i)) > 0 then
          begin
            bPaths := GetProjects(Projects, ParamStr(i));
          end;
      end;

    FoundInAll(ParamStr(1), StrToInt(ParamStr(2)), StrToInt(ParamStr(3)));
    //WriteLN(IntToStr(MilliSecondsBetween(now, t1))+' ms');
  except
    FinalizationProg;
    WriteLN(SysErrorMessage(GetLastError));
  end;
  
end.
