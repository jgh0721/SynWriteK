unit UFormTest;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, XPMan,
  ATSynPlugins;

type
  TForm1 = class(TForm)
    XPManifest1: TXPManifest;
    procedure FormShow(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure FormResize(Sender: TObject);
  private
    { Private declarations }
    FDll: THandle;
    FForm: Pointer;
    FWindow: THandle;
    FSynOpenForm: TSynOpenForm;
    FSynCloseForm: TSynCloseForm;
    FSynInit: TSynInit;
  public
    { Public declarations }
    function FormActionProc(AHandle: Pointer; AName: PWideChar; AP1, AP2, AP3, AP4: Pointer): Integer; stdcall;
  end;

var
  Form1: TForm1;

implementation

{$R *.dfm}

function ActionProc(AHandle: Pointer; AName: PWideChar; A1, A2, A3, A4: Pointer): Integer; stdcall;
begin
  //MessageboxW(0, AName, 'Action called', mb_ok or mb_taskmodal);
  Result:= cSynBadCmd;
end;


function TForm1.FormActionProc;
begin
  Showmessage(AName);
  Result:= cSynBadCmd;
end;

procedure TForm1.FormShow(Sender: TObject);
begin
  FDll:= LoadLibrary('Explorer.dll');
  if FDll=0 then
  begin
    ShowMessage('Can''t load dll');
    Exit
  end;

  FSynInit:= GetProcAddress(FDll, 'SynInit');
  if @FSynInit=nil then
  begin
    ShowMessage('Can''t find SynInit');
    Exit
  end;

  FSynOpenForm:= GetProcAddress(FDll, 'SynOpenForm');
  if @FSynOpenForm=nil then
  begin
    ShowMessage('Can''t find SynOpenForm');
    Exit
  end;

  FSynCloseForm:= GetProcAddress(FDll, 'SynCloseForm');
  if @FSynCloseForm=nil then
  begin
    ShowMessage('Can''t find SynCloseForm');
    Exit
  end;

  FSynInit(PWChar(Widestring(ExtractFilePath(ParamStr(0))+'Nav.ini')), @ActionProc);
  FForm:= FSynOpenForm(Self.Handle, FWindow);
  Windows.SetParent(FWindow, Self.Handle);
end;

procedure TForm1.FormCreate(Sender: TObject);
begin
  FDll:= 0;
  FForm:= nil;
  FSynOpenForm:= nil;
  FSynCloseForm:= nil;
  FSynInit:= nil;
end;

procedure TForm1.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  if Assigned(FSynCloseForm) then
    FSynCloseForm(FForm);
end;

procedure TForm1.FormResize(Sender: TObject);
begin
  SetWindowPos(FWindow, 0, 0, 0, ClientWidth, ClientHeight, 0);
end;

var
  _Action: TSynAction;
initialization
  _Action:= ActionProc;

end.
