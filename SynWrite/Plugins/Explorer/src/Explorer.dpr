//-----------------------------------
//Explorer plugin for SynWrite
//Author: A.Torgashin, uvviewsoft.com
//License: MPL 1.1
//-----------------------------------
library Explorer;

uses
  Forms,
  Controls,
  Windows,
  MPCommonUtilities,
  UFormNav in 'UFormNav.pas' {FormNav},
  ATSynPlugins in '\S\ATSynPlugins.pas';


procedure SynInit(ADefaultIni: PWideChar; AActionProc: Pointer); stdcall;
begin
  _ActionProc:= AActionProc;
  _DefaultIni:= Widestring(PWChar(ADefaultIni));
end;  

function SynOpenForm(AParentWindow: THandle; var AWindow: THandle): Pointer; stdcall;
begin
  Application.Handle:= AParentWindow; //sync DLL with EXE (maybe needed)
  FormNav:= TFormNav.CreateParented(AParentWindow);
  FormNav.BorderStyle:= bsNone;
  FormNav.Show;
  AWindow:= FormNav.Handle;
  _FormHandle:= FormNav;
  Result:= _FormHandle;
end;

procedure SynCloseForm(AHandle: Pointer); stdcall;
var
  F: TForm;
  Act: TCloseAction;
begin
  F:= AHandle;
  F.OnClose(nil, Act);
  {
  F.Close;
  F.Free;
  }
end;


function SynAction(AHandle: Pointer; AName: PWideChar; A1, A2, A3, A4: Pointer): Integer; stdcall;
var
  SCmd, S: Widestring;
  F: TFormNav;
begin
  SCmd:= PWideChar(AName);
  F:= FormNav;

  //-------------
  if SCmd=cActionSetColor then
  begin
    case Integer(A1) of
      cColorId_Text:
        begin
          F.Tree.Font.Color:= Integer(A2);
          F.List.Font.Color:= Integer(A2);
          F.Comb.Font.Color:= Integer(A2);
        end;
      cColorId_Back:
        begin
          F.Tree.Color:= Integer(A2);
          F.List.Color:= Integer(A2);
          F.Comb.Color:= Integer(A2);
        end;
    end;
  end;

  //-------------
  if SCmd=cActionNavigateToFile then
  begin
    F.Tree.BrowseTo(PWideChar(A1));
    Result:= cSynOK;
    Exit;
  end;

  //------------
  if SCmd=cActionRefreshFileList then
  begin
    S:= WideExtractFileDir(PWideChar(A1));
    if WideUpperCase(S) = WideUpperCase(F.CurrentDir) then
      F.btnRefresh.Click;
    Result:= cSynOK;
    Exit;
  end;

  //-----------
  if SCmd=cActionUpdateLang then
  begin
    //S:= F.GetMsg('LL');
    //MessageboxW(0, PWChar(S), 'Lang change', mb_ok or mb_taskmodal);
    F.UpdateLang;
    Result:= cSynOK;
    Exit;
  end;

  //-----------
  if SCmd=cActionRepaint then
  begin
    F.Tree.Invalidate;
    F.List.Invalidate;
    with F.Tree do
      begin Height:= Height-1; Height:= Height+1; end;
    with F.List do
      begin Height:= Height-1; Height:= Height+1; end;
    F.Toolbar1.Invalidate;
    F.edFilter.Invalidate;
    F.btnFilter.Invalidate;
    Result:= cSynOK;
    Exit;
  end;
  
  //-----------
  //-----------
  //-----------

  //MessageboxW(0, AName, 'Explorer', mb_ok or mb_taskmodal);
  Result:= cSynBadCmd;
end;

exports
  SynOpenForm,
  SynCloseForm,
  SynAction,
  SynInit;

//following is to check types
var
  _OpenForm: TSynOpenForm;
  _CloseForm: TSynCloseForm;
  _Action: TSynAction;
  _Init: TSynInit;
begin
  _OpenForm:= SynOpenForm;
  _CloseForm:= SynCloseForm;
  _Action:= SynAction;
  _Init:= SynInit;
  if @_OpenForm<>nil then begin end;
  if @_CloseForm<>nil then begin end;
  if @_Action<>nil then begin end;
  if @_Init<>nil then begin end;

end.
