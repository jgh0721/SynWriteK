program Nav;

uses
  Forms,
  UFormNav in 'UFormNav.pas' {FormNavUV};

{$R *.res}

begin
  Application.Initialize;
  Application.Title := 'Explorer';
  Application.CreateForm(TFormNav, FormNav);
  Application.Run;
end.
