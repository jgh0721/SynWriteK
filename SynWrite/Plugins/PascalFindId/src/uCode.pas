unit uCode;

interface

uses
  StrUtils, SysUtils, Classes;

  function CheckAbout(const sParam: String): boolean;

  function GetProjects(var lProjects: TStringList; const sPaths: string): boolean;

  procedure FoundInAll(const sFilePath: String; const iStr, iCol: integer);

  function CheckParams(const sParam1, sParam2, sParam3: String): boolean;

  procedure RaiseError(const sError: string);

var
  lstFile    ,
  UsesList   ,
  Projects   : TStringList;
  bBLS       ,
  bPaths     ,
  bSemicolon : boolean;
  aWord      : array [0..1] of SmallInt;

const
  Semicolon = ';';
  Quotes    = '''';
  CRLF      = #13+#10;

  ipStr     = 0;
  ipCol     = 1;

  ReservedWord = ',TRUE,FALSE,FREE,RESULT,BEGIN,END,PROCEDURE,FUNCTION,CONST,TYPE,CASE,DOWNTO,TO,IF,OF,DO,PUPLIC,PRIVATE,'+
                 'IMPLEMENTATION,INTERFACE,USES,UNIT,PROGRAM,VAR,' ;

implementation

procedure RaiseError(const sError: string);
begin
  Writeln('Error: '+sError);
end;

procedure PostResult(const sFile: String; iStr, iCol: integer);
begin
  Writeln('ID found: "'+sFile + '" ' + IntToStr(iStr) + ':' + IntToStr(iCol));
end;

function ExistWordInString(const aString: pAnsiChar; const aSearchString: string; aSearchOptions: TStringSearchOptions; var sFindStr: string): Boolean;
var
  Size       : Integer;
  sString    ,
  srchString : pAnsiChar;
begin
  sString    := pAnsiChar(StringReplace(aString,       '_', 'w_', [rfReplaceAll]));
  srchString := pAnsiChar(StringReplace(aSearchString, '_', 'w_', [rfReplaceAll]));

  Size := StrLen(sString);
  result := SearchBuf(sString, Size, 0, 0, srchString, aSearchOptions) <> nil;
  if result then sFindStr:= StringReplace(SearchBuf(sString, Size, 0, 0, srchString, aSearchOptions),'w_', '_', [rfReplaceAll]);
  //if Result then ShowMessage(srchString);
end;

function CheckParams(const sParam1, sParam2, sParam3: String): boolean;
begin
  result:= false;

  if (Trim(sParam1) = '') or
     (Trim(sParam2) = '') or
     (Trim(sParam3) = '') then
    begin
      RaiseError('invalid command line options');
      Exit;
    end;

  // Проверки на указание пути и присутствие файла.
  if Trim(sParam1) = '' then
    begin
      RaiseError('wrong file path');
      Exit;
    end else
    begin
      if not FileExists(Trim(sParam1)) then
        begin
          RaiseError('file not found');
          Exit;
        end;
    end;

  try
    StrToInt(sParam2);;
  except
    RaiseError('bad number ('+sParam2+')');
    Exit;
  end;

  try
    StrToInt(sParam3);;
  except
    RaiseError('bad number ('+sParam3+')');
    Exit;
  end;

  if StrToInt(sParam2) <= 0 then
    begin
      RaiseError('wrong line number ('+sParam2+')');
      Exit;
    end;

  if StrToInt(sParam3) <= 0 then
    begin
      RaiseError('wrong line number ('+sParam3+')');
      Exit;
    end;

  result:= true;
end;

function SetSlashedPath (const sPath : string) : string;
//Добавить в конец строки с путем слэш
begin
  Result := '';
  if sPath = '' then Exit;
  if sPath[Length(sPath)] = '*' then
    begin
      if sPath[Length(sPath)-1] <> '\' then
        Result := Copy(sPath, 1, Length(sPath)-1) + '\*'
      else
        Result := sPath;
    end else
    begin
      if sPath[Length(sPath)] <> '\' then
        Result := sPath + '\'
      else
        Result := sPath;
    end;
end;

procedure Scan_wSubDir(const sDir, sFile:string; var sfPath: string);
var
  SearchRec:TSearchRec;
  tmpDir: string;
begin
//  ShowMessage(sFile);
  tmpDir:= StringReplace(sDir,'*', '', [rfReplaceAll]);
	if tmpDir<>'' then if tmpDir[length(tmpDir)]<>'\' then tmpDir:=tmpDir+'\';
 	if FindFirst(tmpDir+'*.*', faAnyFile, SearchRec)=0 then
	repeat
  	if (SearchRec.name='.') or (SearchRec.name='..') or
       (Pos('.DCU',UpperCase(SearchRec.name)) > 0) then continue;
	  if (SearchRec.Attr and faDirectory) <> 0 then
    	Scan_wSubDir(tmpDir+SearchRec.name, sFile, sfPath)
    else
    	if Pos(UpperCase('\'+sFile),UpperCase(tmpDir+SearchRec.name)) > 0 then
        begin
         sfPath:= tmpDir+SearchRec.name;
         FindClose(SearchRec);
         Exit;
       end;
  	until FindNext(SearchRec)<>0;
	FindClose(SearchRec);
end;

procedure Scan_Dir(const sDir, sFile:string; var sfPath: string);
var
  SearchRec:TSearchRec;
begin
  If FindFirst(sDir+'*.*', faAnyFile, SearchRec)=0 then
    repeat
      if (SearchRec.name='.') or (SearchRec.name='..') or
         (Pos('.DCU',UpperCase(SearchRec.name)) > 0) then continue;
	    if (SearchRec.Attr and faDirectory) <> 0 then
    	  Scan_Dir(sDir+SearchRec.name, sFile, sfPath)
      else
      	if Pos(UpperCase('\'+sFile), UpperCase(sDir+SearchRec.name)) > 0 then
          begin
           sfPath:= sDir+SearchRec.name;
           FindClose(SearchRec);
           Exit;
         end;
    until FindNext(SearchRec) <> 0;
  FindClose(SearchRec);
end;

function CutParameter(var Str: WideString; const cStr: String):string;
var
  i:integer;
begin
  i:= Pos(cStr,Str);
  if i<1 then
    begin
      Result:=Str;
      Str:='';
      Exit;
    end;
  Result:= Copy(Str, 1, i-1);
  Str:= Copy(Str, i+1, length(Str)-i);
end;

function GetProjects(var lProjects: TStringList; const sPaths: string): boolean;
var
  swStr   : WideString;
  sTmp    : String;
begin
  swStr   := sPaths;
  result:= Trim(swStr) <> '';
  if not result then Exit;

  lProjects :=  TStringList.Create;
  swStr:= StringReplace(swStr,'/paths=', '' , [rfReplaceAll]);

  repeat
    sTmp:= CutParameter(swStr, ';');
    if sTmp='' then Break;
    sTmp:= SetSlashedPath(sTmp);
    lProjects.Add(sTmp);
  until false;

  result := lProjects.Count > 0;
end;

function GetFileNameFromPath(const sPath: string): string;
begin
  result:= ExtractFileName(sPath);
end;

function CheckAbout(const sParam: String): boolean;
begin
  Result := False;
  if (sParam = '/?') or (sParam = '/Help') or
     (sParam = '?' ) or (sParam = '/h')    or
     (sParam = 'h' ) or (sParam = '')then
  begin
      Writeln('ID finder for Pascal projects. Version 0.1');
      Writeln('(c) RamSoft 2012');
      Writeln('');
      Writeln('Usage:');
      Writeln(' FindID <FileName> <StringNumber> <ColumnNumber> [ /paths=PathsList ]');
      Writeln('  Where:');
      Writeln('    FileName - Full path of source code file');
      Writeln('    StringNumber - ID''''s line number');
      Writeln('    ColumnNumber - ID''''s column number');
      Writeln('    PathsList - List of search folders, separated by ";" sign');
      Writeln('    ("*" at the end of a folder indicates all subfolders search)');
    Result := true;
  end;
end;

function ReadMainParams: boolean;
begin
  result:= true;
end;

procedure ReadFile(const fPath: string);
var
  FText : TEXT;
  str   : String;
begin
  if lstFile <> nil then lstFile.Free;
  lstFile:= TStringList.Create;
  AssignFile(FText, fPath);
  Reset(FText);
  while not EOF(FText) do
    begin
      Readln(FText, str);
      lstFile.Add(str);
    end;
  CloseFile(FText);
end;

function FoundSelf(const iStr, iCol: Integer; sID: string): boolean;
begin
  result:= ((iStr = aWord[ipStr]) and (iCol = aWord[ipCol]));
//  if Result then ShowMessage('FS=TRUE');
  //  if result then Writeln('FoundSelf = TRUE - ID:'+sID) else Writeln('FoundSelf = FALSE - ID:'+sID);
//  if not result then Writeln('iStr='+IntToStr(iStr)+'~aWord[ipStr]='+IntToStr(aWord[ipStr])+'|iCol='+IntToStr(iCol)+'~aWord[ipCol]='+IntToStr(aWord[ipCol]));
end;

function CheckGlobalComment(const iStr: integer): boolean;
label GO1;
var
  i, j  : integer;
  stmp  : string;
  bFlag : boolean;
begin
  bFlag := false;
  result:= true;
  for i := iStr - 1 downto 0 do
    begin
      stmp:= Trim(lstFile.Strings[i]);

      if Length(stmp) > 0 then
        bFlag := (stmp[1] = '{') and (stmp[length(stmp)] = '}');

      //if bFlag then ShowMessage('bFlag=TRUE') else ShowMessage('bFlag=FALSE');

      if (POS('*)', lstFile.Strings[i]) > 0) and (not bFlag) and
         (POSEX('(*', lstFile.Strings[i], POS('*)', lstFile.Strings[i])) = 0) then Exit;

      if (POS('}', lstFile.Strings[i]) > 0) and  (not bFlag) and
         (POSEX('{', lstFile.Strings[i], POS('}', lstFile.Strings[i])) = 0) then Exit;

      if ((POS('{', lstFile.Strings[i]) > 0) and
         (POSEX('}', lstFile.Strings[i], POS('{', lstFile.Strings[i])) = 0)) or
         ((POS('(*', lstFile.Strings[i]) > 0) and
         (POSEX('*)', lstFile.Strings[i], POS('(*', lstFile.Strings[i])) = 0)) then
        begin
          GO1:
          for j := i + 1 to lstFile.Count - 1 do
            begin
              //ShowMessage(lstFile.Strings[j]);

              if (POS('(*', lstFile.Strings[j]) > 0) and
                 (POSEX('*)', lstFile.Strings[j], POS('(*', lstFile.Strings[j])) = 0) then Exit;

              if (POS('{', lstFile.Strings[j]) > 0) and
                 (POSEX('}', lstFile.Strings[j], POS('{', lstFile.Strings[j])) = 0) then Exit;

              if ((POS('}', lstFile.Strings[j]) > 0) and
                 (POSEX('{', lstFile.Strings[j], POS('}', lstFile.Strings[j])) = 0)) or
                 ((POS('*)', lstFile.Strings[j]) > 0) and
                 (POSEX('(*', lstFile.Strings[j], POS('*)', lstFile.Strings[j])) = 0)) then
                begin
                  result:= false;
                  //ShowMessage('GC=TRUE');
                  Exit;
                end;   
            end;
        end;
    end;
end;

function CheckWord(const sStr, sWord: String; const iCol, iStr: integer): boolean;
var
  str1, str2 : string;
begin
  Result := false;
//  Writeln(UpperCase(sStr));
//  Writeln('POS='+IntToStr(Pos(UpperCase(sWord+Semicolon), UpperCase(sStr)))+'|iCol='+IntToStr(iCol));
  result:=  (Pos(UpperCase(sWord+Semicolon), UpperCase(sStr)) = iCol);

  if not Result then
    begin
      str1:= Copy(sStr, 1, iCol - 1);
      str2:= Copy(sStr, iCol, length(sStr) - iCol);

//      Writeln(IntToStr(pos('):', sStr))+'|'+IntToStr(iCol+Length(sWord)));
//      Writeln('str2='+str2);


//      Writeln('Trim="'+Trim(Copy(str1, pos(':', UpperCase(str1)) + 1, Length(str1)))+'"');

      if ((pos(':', str1) > 0)) and (PosEx('(', str1, pos(':', str1)) = 0) and
         (Trim(Copy(str1, pos(':', str1) + 1, Length(str1))) = '') then
        begin
          Result := true;
          //Writeln('1');
        end else
        if ((pos('OF', UpperCase(str1)) > 0)) and
         (Trim(Copy(str1, pos('OF', UpperCase(str1)) + 2, Length(str1))) = '') then
        begin
          Result := true;
          //Writeln('2');
        end else
        if (pos('):', sStr) = iCol+Length(sWord)) or
           (pos(');', sStr) = iCol+Length(sWord)) then
        begin
          Result := true;
        end else
        //PosEx(')', str2, pos(':', str2)) = 0

        if (pos(':', str2) > 0) and (pos(')', str2) = 0) and
         (PosEx('=', str2, pos(':', str2)) = 0) then
        begin
          Result := false;
         // Writeln('3');
        end;
    end;

  //if Result then ShowMessage('CheckWord=TRUE');
end;

function GetWord(const sStr: String; const iCol: integer): string;
var
  i        ,
  iStart   ,
  iEnd     : integer;
  bDot     ,
  bQuotes  : boolean;

  str1, str2 : string;
begin
  result:= '';
  iStart:= -1;
  iEnd  := -1;
  bDot  := false;
//  isErrID := false;
  bQuotes := false;

  str1:= Copy(sStr, 1, iCol);
  str2:= Copy(sStr, iCol, length(sStr) - iCol);

  // Грубая проверка на комментарий, требуется более тонкий подход.
  if ((pos('{',str1) > 0) and (pos('}',str2) > 0)) or (pos('//',str1) > 0) then
    begin
      if pos('//',str1) > 0 then
        begin
          RaiseError(' ID  should was selected is not a comment');
          Exit;
        end;

      if ((pos('{',str1) > 0) and (pos('}',str2) > 0)) then
        for i := 1 to Length(str1) do
          begin
            if str1[i] = '}' then
              begin

              end
              else
              begin

              end;
          end;
    end;

  for i:= iCol downto 1 do
    begin
      //Showmessage(sStr[i]);
      if (sStr[i] in ['A'..'Z']) or
         (sStr[i] in ['a'..'z']) or
         (sStr[i] in ['0'..'9']) or
         (sStr[i] = '.') or
         (sStr[i] = '_') or
         (sStr[i] = Quotes) then
        begin
          if sStr[i] = Quotes then
            begin
              bQuotes := true;
              iStart:= i;
              Break;
            end;
          if sStr[i] = '.' then
            begin
              if bDot then
                begin
                  iStart:= i + 1;
                  bDot:= false;
                  Break;
                end;
            end else
              bDot:= true;

          Continue;
        end else
        begin
          iStart:= i+1;
          Break;
        end;
    end;

    for i:= iCol to Length(sStr) do
    begin
      //Showmessage(sStr[i]);
      if (sStr[i] in ['A'..'Z']) or
         (sStr[i] in ['a'..'z']) or
         (sStr[i] in ['0'..'9']) or
         (sStr[i] = '.') or
         (sStr[i] = '_') or
         (sStr[i] = Quotes) then
        begin
          if i = Length(sStr) then iEnd:= i + 1;

          if sStr[i] = Quotes then
            begin
              if bQuotes then
                begin
                  iEnd:= i + 1;
                  RaiseError(' not ID selected ('+Copy(sStr, iStart, iEnd - iStart)+')');
                  Exit;
                end;
              iStart:= i+1;
              Break;
            end;

          if sStr[i] = '.' then
            begin
              if bDot then
                begin
                  iEnd:= i;
                  bDot:= false;
                  Break;
                end;
            end else
              bDot:= true;
          Continue;
        end else
        begin
          iEnd:= i;
          Break;
        end;
    end;

  aWord[ipCol] := iStart - 2;
  bSemicolon := sStr[iEnd] = Semicolon;



  result:= Copy(sStr, iStart, iEnd - iStart);
  if POS(','+UPPERCASE(RESULT)+',',ReservedWord) > 0 Then
    begin
      RaiseError('ID ('+Result+') not found');
      Result := '';
    end;
end;

function GetAnotherWord(const sStr: String; const iCol: integer): string;
var
  i        ,
  iStart   ,
  iEnd     : integer;
  bDot     ,
  bQuotes  : boolean;

  str1, str2 : string;
begin
  result:= '';
  iStart:= -1;
  iEnd  := -1;
  bDot  := false;
  bQuotes := false;

  str1:= Copy(sStr, 1, iCol);
  str2:= Copy(sStr, iCol, length(sStr) - iCol);

  // Грубая проверка на комментарий, требуется более тонкий подход.
  if ((pos('{',str1) > 0) and (pos('}',str2) > 0)) or (pos('//',str1) > 0) then
    begin
      if pos('//',str1) > 0 then Exit;

      if ((pos('{',str1) > 0) and (pos('}',str2) > 0)) then
        for i := 1 to Length(str1) do
          begin
            if str1[i] = '}' then
              begin

              end
              else
              begin

              end;
          end;
    end;

  for i:= iCol downto 1 do
    begin
      //Showmessage(sStr[i]);
      if (sStr[i] in ['A'..'Z']) or
         (sStr[i] in ['a'..'z']) or
         (sStr[i] in ['0'..'9']) or
         (sStr[i] = '.') or
         (sStr[i] = '_') or
         (sStr[i] = Quotes) then
        begin
          if sStr[i] = Quotes then
            begin
              bQuotes := true;
              iStart:= i;
              Break;
            end;
          if sStr[i] = '.' then
            begin
              if bDot then
                begin
                  iStart:= i + 1;
                  bDot:= false;
                  Break;
                end;
            end else
              bDot:= true;

          Continue;
        end else
        begin
          iStart:= i+1;
          Break;
        end;
    end;

    for i:= iCol to Length(sStr) do
    begin
      //Showmessage(sStr[i]);
      if (sStr[i] in ['A'..'Z']) or
         (sStr[i] in ['a'..'z']) or
         (sStr[i] in ['0'..'9']) or
         (sStr[i] = '.') or
         (sStr[i] = '_') or
         (sStr[i] = Quotes) then
        begin
          if i = Length(sStr) then iEnd:= i + 1;

          if sStr[i] = Quotes then
            begin
              if bQuotes then
                begin
                  iEnd:= i + 1;
                  Break;
                end;
              iStart:= i+1;
              Break;
            end;

          if sStr[i] = '.' then
            begin
              if bDot then
                begin
                  iEnd:= i;
                  bDot:= false;
                  Break;
                end;
            end else
              bDot:= true;
          Continue;
        end else
        begin
          iEnd:= i;
          Break;
        end;
    end;
  result:= Copy(sStr, iStart, iEnd - iStart);
end;

function GetUsesList: boolean;
var
  i, lastPos : integer;
  str        : string;
  str2       : WideString;

begin
  result:= false;
  UsesList:= TStringList.Create;


  lastPos := 0;
  i := 1;
  while (PosEx('USES', UpperCase(lstFile.Text), lastPos) > 0) and (i <= 2) do
    begin
      str2 := str2 + Copy(lstFile.Text,
                   PosEx('USES',UpperCase(lstFile.Text), lastPos) + 4,
                   PosEx(Semicolon, lstFile.Text, PosEx('USES',UpperCase(lstFile.Text),lastPos)) - 4 - PosEx('USES',UpperCase(lstFile.Text),lastPos)) + ',';
      lastPos := PosEx('USES', UpperCase(lstFile.Text), lastPos) + 4;
      i := i + 1;
    end;

  //Showmessage(str2);

  while (Pos('//', str2) > 0) and (PosEx(CRLF, str2, Pos('//', str2)) > 0) do
    str2:= Copy(str2, 1, Pos('//', str2) - 1) + Copy(str2, PosEx(CRLF, str2, Pos('//', str2)) + 1, Length(str2) - PosEx(CRLF, str2, Pos('//', str2)));


  // Чистка мусора...
  str2:= StringReplace(str2, #13   , ''  , [rfReplaceAll]);
  str2:= StringReplace(str2, #10   , ''  , [rfReplaceAll]);

  while (Pos(Quotes, str2) > 0) and (PosEx(Quotes, str2, Pos(Quotes, str2) + 1) > 0) do
    str2 := Copy(str2, 1, Pos(Quotes, str2) - 1) + Copy(str2, PosEx(Quotes, str2, Pos(Quotes, str2) + 1) + 1, Length(str2) - PosEx(Quotes, str2, Pos(Quotes, str2) + 1));

  str2:= StringReplace(str2, ' in '  , ''  , [rfReplaceAll]);
  str2:= StringReplace(str2, ' '     , ''  , [rfReplaceAll]);

  // Вырезаем комменты...
  while (Pos('{', str2) > 0) and (Pos('}', str2) > 0) do
    str2:= Copy(str2, 1, Pos('{', str2) - 1) + Copy(str2, Pos('}', str2) + 1, Length(str2) - Pos('}', str2));

  while (Pos('(*', str2) > 0) and (Pos('*)', str2) > 0) do
    str2:= Copy(str2, 1, Pos('(*', str2) - 1) + Copy(str2, Pos('*)', str2) + 1, Length(str2) - Pos('*)', str2));


  // Парсим в лист...
  repeat
    str:= CutParameter(str2, ',');
    if str='' then Break;
    UsesList.Add(str+'.');
  until false;

  result:= UsesList.Count > 0;
end;

procedure FoundUpVar(const sWord: String; iStartStr: integer; var iResStr, iResPos: integer);
var
  i , j      : integer;
  sFindStr   ,
  str1, str2 ,
  sFndWord   : string;
begin
  for i := iStartStr - 1 Downto 0 do
    begin
      //Showmessage('i cicle str = "'+lstFile.strings[i]+'"');
      if {(ExistWordInString(PAnsiChar(lstFile.strings[i]), 'var',[soWholeWord, soDown], sFindStr)) or
         (ExistWordInString(PAnsiChar(lstFile.strings[i]), 'const',[soWholeWord, soDown], sFindStr)) or}
         (ExistWordInString(PAnsiChar(lstFile.strings[i]), 'procedure',[soWholeWord, soDown], sFindStr)) or
         (ExistWordInString(PAnsiChar(lstFile.strings[i]), 'function',[soWholeWord, soDown], sFindStr)) then
        begin
          //Showmessage('var found in str = "'+lstFile.strings[i]+'"');
          for j := i to iStartStr do
            begin
              //Showmessage('j cicle str = "'+lstFile.strings[j]+'"');
              if ExistWordInString(PAnsiChar('  '+lstFile.strings[j]), '  '+sWord,[soWholeWord, soDown], sFindStr) then
                begin
                  str1:= Copy(lstFile.Strings[j], 1, Pos(UpperCase(sFindStr), UpperCase(lstFile.strings[j])));
                  str2:= Copy(lstFile.Strings[j], Pos(UpperCase(sFindStr), UpperCase(lstFile.strings[j])),
                           length(lstFile.Strings[j]) + 1 - Pos(UpperCase(sFindStr), UpperCase(lstFile.strings[j])));

                  if ((pos('{',str1) > 0) and (pos('}',str2) > 0)) or
                     ((pos('(*',str1) > 0) and (pos('*)',str2) > 0)) or
                     ((pos(Quotes,str1) > 0) and (pos(Quotes,str2) > 0)) or
                     (pos('//',str1) > 0) or (pos('=',str1) > 0)  then Continue;


                  iResPos := Pos(UpperCase(sFindStr), UpperCase(lstFile.strings[j]));
                  iResStr := j + 1;

                  //Writeln('iResStr='+IntToStr(iResStr)+':iResPos='+IntToStr(iResPos));
                  sFndWord := GetAnotherWord(lstFile.Strings[j], iResPos);

                  if (UPPERCASE(SFNDWORD) <> UPPERCASE(SWORD)) or
                     (not CheckGlobalComment(iResStr)) or
                     (FoundSelf(iResStr,iResPos, 'FoundVarInHead')) or
                     (CheckWord(lstFile.Strings[j], sWord, iResPos, iResStr)) then
                    begin
                      iResPos := -1;
                      iResStr := -1;
                      Continue;
                    end;
                  //ShowMessage('UPVAR');
                  Exit;
                end;
              if ExistWordInString(PAnsiChar(lstFile.strings[j]), 'begin',[soWholeWord, soDown], sFindStr) then Exit;  
            end;
          Exit; // Дальше нету смысла искать.
        end;
    end;
end;

procedure FoundVarInHead(const sWord: String; var iResStr, iResPos: integer);
var
  i , j      : integer;
  sFindStr   ,
  str1, str2 ,
  sFndWord   : string;
begin
  for i := 0 to lstFile.Count - 1 do
    begin
      //Showmessage('i cicle str = "'+lstFile.strings[i]+'"');
      if (ExistWordInString(PAnsiChar(lstFile.strings[i]), 'var',[soWholeWord, soDown], sFindStr)) or
         (ExistWordInString(PAnsiChar(lstFile.strings[i]), 'const',[soWholeWord, soDown], sFindStr)) or
         (ExistWordInString(PAnsiChar(lstFile.strings[i]), 'type',[soWholeWord, soDown], sFindStr)){
         (ExistWordInString(PAnsiChar(lstFile.strings[i]), 'procedure',[soWholeWord, soDown], sFindStr)) or
         (ExistWordInString(PAnsiChar(lstFile.strings[i]), 'function',[soWholeWord, soDown], sFindStr)) }then
        begin
        //  Showmessage('var found in str = "'+lstFile.strings[i]+'"');
          for j := i to lstFile.Count - 1 do
            begin
          //    Showmessage('j cicle str = "'+lstFile.strings[j]+'"');
              if ExistWordInString(PAnsiChar('  '+lstFile.strings[j]), PAnsiChar(sWord),[soWholeWord, soDown], sFindStr) then
                begin
                  str1:= Copy(lstFile.Strings[j], 1, Pos(UpperCase(sFindStr), UpperCase(lstFile.strings[j])));
                  str2:= Copy(lstFile.Strings[j], Pos(UpperCase(sFindStr), UpperCase(lstFile.strings[j])),
                           length(lstFile.Strings[j]) + 1 - Pos(UpperCase(sFindStr), UpperCase(lstFile.strings[j])));

                  if ((pos('(*',str1) > 0) and (pos('*)',str2) > 0)) or
                     ((pos('{',str1) > 0) and (pos('}',str2) > 0)) or
                     ((pos(Quotes,str1) > 0) and (pos(Quotes,str2) > 0)) or
                     (pos('//',str1) > 0) or  (pos('=',str1) > 0)  then Continue;

                  iResPos := Pos(UpperCase(sFindStr), UpperCase(lstFile.strings[j]));
                  iResStr := j + 1;

                  //Writeln('iResStr='+IntToStr(iResStr)+':iResPos='+IntToStr(iResPos));
                  sFndWord := GetAnotherWord(lstFile.Strings[j], iResPos);

                  if (UPPERCASE(SFNDWORD) <> UPPERCASE(SWORD)) or
                     (not CheckGlobalComment(iResStr)) or
                     (FoundSelf(iResStr,iResPos, 'FoundVarInHead')) or
                     (CheckWord(lstFile.Strings[j], sWord, iResPos, iResStr)) then
                    begin
                      iResPos := -1;
                      iResStr := -1;
                      Continue;
                    end;

                  Exit;
                end;
              if ExistWordInString(PAnsiChar('  '+lstFile.strings[j]), 'begin',[soWholeWord, soDown], sFindStr) then Exit;
            end;
          Exit; // Дальше нету смысла искать.
        end;
    end;
end;

procedure FoundInFile(const sWord: String; var iResStr, iResPos: integer);
var
  i          : integer;
  str1, str2 ,
  sFndWord   : string;
begin
  for i := 0 to lstFile.Count - 1 do
    begin
      if (Pos(UpperCase('procedure '+sWord)+' ', UpperCase(lstFile.Strings[i])) > 0) or
         (Pos(UpperCase('procedure '+sWord)+';', UpperCase(lstFile.Strings[i])) > 0) or
         (Pos(UpperCase('procedure '+sWord)+'(', UpperCase(lstFile.Strings[i])) > 0) or
         (Pos(UpperCase('function '+sWord)+' ', UpperCase(lstFile.Strings[i])) > 0) or
         (Pos(UpperCase('function '+sWord)+':', UpperCase(lstFile.Strings[i])) > 0) or
         (Pos(UpperCase('function '+sWord)+';', UpperCase(lstFile.Strings[i])) > 0) or
         (Pos(UpperCase('function '+sWord)+'(', UpperCase(lstFile.Strings[i])) > 0) then
        begin
          if (Pos(UpperCase('procedure '+sWord), UpperCase(lstFile.Strings[i])) > 0) then
            begin
              str1:= Copy(lstFile.Strings[i], 1, Pos(UpperCase('procedure '+sWord), UpperCase(lstFile.Strings[i])));
              str2:= Copy(lstFile.Strings[i], Pos(UpperCase('procedure '+sWord), UpperCase(lstFile.Strings[i])),
                length(lstFile.Strings[i]) + 1 - Pos(UpperCase('procedure '+sWord), UpperCase(lstFile.Strings[i])));

              if ((pos('(*',str1) > 0) and (pos('*)',str2) > 0)) or
                 ((pos('{',str1) > 0) and (pos('}',str2) > 0)) or
                 (pos('//',str1) > 0) then Continue;

              iResPos := Pos(UpperCase('procedure '+sWord), UpperCase(lstFile.Strings[i]));
              iResStr := i+1;

              //Writeln('iResStr='+IntToStr(iResStr)+':iResPos='+IntToStr(iResPos));
              //sFndWord := GetAnotherWord(lstFile.Strings[i], iResPos);

              if {(UPPERCASE(SFNDWORD) <> UPPERCASE(SWORD)) or}
                 (not CheckGlobalComment(iResStr)) or
                 (FoundSelf(iResStr,iResPos, 'FoundVarInHead')) or
                 (CheckWord(lstFile.Strings[i], sWord, iResPos, iResStr)) then
                begin
                  iResPos := -1;
                  iResStr := -1;
                  Continue;
                end;
            end;
          if (Pos(UpperCase('function '+sWord), UpperCase(lstFile.Strings[i])) > 0) then
            begin
              //ShowMessage(lstFile.Strings[i]);

              str1:= Copy(lstFile.Strings[i], 1, Pos(UpperCase('function '+sWord), UpperCase(lstFile.Strings[i])));
              str2:= Copy(lstFile.Strings[i], Pos(UpperCase('function '+sWord), UpperCase(lstFile.Strings[i])),
                length(lstFile.Strings[i]) + 1 - Pos(UpperCase('function '+sWord), UpperCase(lstFile.Strings[i])));

              if ((pos('(*',str1) > 0) and (pos('*)',str2) > 0)) or
                 ((pos('{',str1) > 0) and (pos('}',str2) > 0)) or
                 (pos('//',str1) > 0) then Continue;

              iResPos := Pos(UpperCase('function '+sWord), UpperCase(lstFile.Strings[i]));
              iResStr := i+1;

              //Writeln('iResStr='+IntToStr(iResStr)+':iResPos='+IntToStr(iResPos));
              //sFndWord := GetAnotherWord(lstFile.Strings[i], iResPos);

              //ShowMessage(sFndWord);

              if {(UPPERCASE(SFNDWORD) <> UPPERCASE(SWORD)) or}
                 (not CheckGlobalComment(iResStr)) or
                 (FoundSelf(iResStr,iResPos, 'FoundVarInHead')) or
                 (CheckWord(lstFile.Strings[i], sWord, iResPos, iResStr)) then
                begin      
                  //ShowMessage('Continue');
                  iResPos := -1;
                  iResStr := -1;
                  Continue;
                end;
            end;
        end;
    end;
end;



procedure FoundInAll(const sFilePath: String; const iStr, iCol: integer);
var
  i, j: integer;
  sWord, sfPath: string;
  iResPos, iResStr: integer;
  sWideWord: widestring;
begin
  iResPos := -1;
  iResStr := -1;


  //if ExistWordInString('  _FieldTypes: array[0.._FieldsNum-1] of integer = ', '_FieldTypes',[soWholeWord, soDown], sfPath) then Showmessage('ХЕРА!') else Showmessage('HN ХЕРА!');

  // Диалект...
  bBLS := Pos(Uppercase('.bls'), UpperCase(sFilePath)) > 0;

  ReadFile(sFilePath);

  if iStr > lstFile.Count then
    begin
      RaiseError('wrong line number ('+IntToStr(iStr)+')');
      Exit;
    end;

  if iCol > Length(lstFile.Strings[iStr-1]) then
    begin
      RaiseError('wrong column number ('+IntToStr(iCol)+' for line '+IntToStr(iStr)+')');
      Exit;
    end;

  sWord:= GetWord('  '+lstFile.Strings[iStr-1], iCol+2);

  if sWord = '' then Exit;

{  if not CheckGlobalComment(iStr) then
    begin
      RaiseError(' ID  should was selected is not a comment');
      Exit;
    end;}

  aWord[ipStr] := iStr;

  //WriteLN('ipStr='+IntToStr(aWord[ipStr])+':ipCol='+IntToStr(aWord[ipCol]));

  sWideWord := sWord;
  // Временная мера, далее будет механизм идентификации...
  if Pos('.', sWord) > 0 then sWord := CutParameter(sWideWord, '.');

  FoundInFile(sWord, iResStr, iResPos);

  if (iResPos <> -1) and (iResStr <> -1) then
    begin
      PostResult(sFilePath, iResStr, iResPos);
      Exit;
    end;

  if (iResPos = -1) and (iResStr = -1) then
    FoundUpVar(sWord, iStr, iResStr, iResPos);
    
  if (iResPos = -1) and (iResStr = -1) then
    FoundVarInHead(sWord, iResStr, iResPos);

  if (iResPos = -1) and (iResStr = -1) then
    if not GetUsesList then
      begin
        RaiseError('can not get uses');
        Exit;
      end else
      begin
        if bPaths then
          begin
            for i := 0 to Projects.Count - 1 do
              begin
                for j:= 0 to UsesList.Count - 1 do
                  begin
                    sfPath:= '';
                    if Pos('*', Projects.Strings[i]) > 0 then
                      begin // С подкаталогами.

                        //ShowMessage(UsesList.Strings[j]);

                        Scan_wSubDir(Projects.Strings[i], UsesList.Strings[j], sfPath);
                        if sfPath <> '' then
                          begin
                            ReadFile(sfPath);

                            if lstFile.Count > 0 then FoundInFile(sWord, iResStr, iResPos);

                            if (iResPos = -1) and (iResStr = -1) then
                              FoundVarInHead(sWord, iResStr, iResPos);

                          end else
                            Continue;


                        if (iResPos <> -1) and (iResStr <> -1) then
                          begin
                            PostResult(sfPath, iResStr, iResPos);
                            Exit;
                          end;
                      end else
                      begin // Тупо в корне.

                        Scan_Dir(Projects.Strings[i], UsesList.Strings[j], sfPath);
                        if sfPath <> '' then
                          begin
                            ReadFile(sfPath);
                            if lstFile.Count > 0 then FoundInFile(sWord, iResStr, iResPos);

                            if (iResPos = -1) and (iResStr = -1) then
                              FoundVarInHead(sWord, iResStr, iResPos);
                          end else
                            Continue;

                        if (iResPos <> -1) and (iResStr <> -1) then
                          begin
                            PostResult(sfPath, iResStr, iResPos);
                            Exit;
                          end;
                      end;
                  end;
              end;
          end;

        if (iResPos = -1) and (iResStr = -1) then
          begin // Попытка найти в тойже папке что и сам модуль
            // Временно ВКЛ... В раздумьях....
//          ShowMessage('Scan current folder');
            for j:= 0 to UsesList.Count - 1 do
              begin
                Scan_Dir(ExtractFilePath(sFilePath),  UsesList.Strings[j], sfPath);

                if sfPath <> '' then ReadFile(sfPath);
                if lstFile.Count > 0 then FoundInFile(sWord, iResStr, iResPos);

                if (iResPos = -1) and (iResStr = -1) then
                  FoundVarInHead(sWord, iResStr, iResPos);

                if (iResPos <> -1) and (iResStr <> -1) then
                  begin
                    PostResult(sfPath, iResStr, iResPos);
                    Exit;
                  end;
              end;
          end;
      end;

  ReadFile(sFilePath);


  if (iResPos <> -1) and (iResStr <> -1) then
    begin
      PostResult(sFilePath, iResStr, iResPos);
      Exit;
    end;

  RaiseError('ID ('+sWord+') not found');
end;

initialization
  bBLS := false;

end.
