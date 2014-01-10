unit ATxTcp;

interface

function UrlRequest(SReq, SReqEnd: string; NPort: Integer): string;
function URLEncode(const S: string): string;
function HttpRequest(const SReq: string; NPort: Integer): string;
procedure ShowMessage(const s: string);

implementation

uses
  Windows,
  SysUtils,
  Classes,
  IdTcpClient,
  IdHttp;

function IsWordCharA(ch: Ansichar): boolean;
begin
  Result:= ch in ['a'..'z', 'A'..'Z', '0'..'9', '_'];
end;

function URLEncode(const S: string): string;
var
  i: Integer;
  ch: char;
begin
  Result := '';
  for i := 1 to Length(S) do
  begin
    ch:= S[i];
    if IsWordCharA(ch) then
      Result := Result + ch
    else
      Result := Result + ('%' + IntToHex(Ord(ch), 2));
  end;
end;


procedure ShowMessage(const s: string);
begin
  MessageBox(0, PChar(s), 'Plugin', mb_ok or mb_iconwarning or mb_taskmodal);
end;

function UrlRequest(SReq, SReqEnd: string; NPort: Integer): string;
const
  BufSize = 8*1024;
var
  Client: TIdTcpClient;
  Buf: array[0..BufSize] of AnsiChar;
begin
  Result:= '';
  FillChar(Buf, SizeOf(Buf), 0);
  Client:= TIdTcpClient.Create(nil);
  try
    Client.Host:= 'localhost';
    Client.Port:= NPort;
    Client.Connect;
    Client.IOHandler.Send(SReq[1], Length(SReq));
    Client.IOHandler.Recv(Buf, BufSize);
    Result:= Buf;
    Client.IOHandler.Send(SReqEnd[1], Length(SReqEnd));
  finally
    Client.Disconnect;
    Client.Free;
  end;
end;

function HttpRequest(const SReq: string; NPort: Integer): string;
var
  Client: TIdHttp;
  MS1, MS2: TStringStream;
begin
  Result:= '';
  Client:= TIdHttp.Create(nil);
  MS1:= TStringStream.Create('');
  MS2:= TStringStream.Create('');
  try
    Client.Host:= 'localhost';
    Client.Port:= NPort;
    Client.Connect;
    Client.DoRequest(hmPost, SReq, MS1, MS2);
    Result:= MS2.DataString;
  finally
    Client.Disconnect;
    Client.Free;
    MS1.Free;
    MS2.Free;
  end;
end;


end.
