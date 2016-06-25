//{$define DD}
unit UFormNav;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, XPMan, ExtCtrls, Menus,

  MPCommonObjects, EasyListview,
  VirtualExplorerEasyListview, VirtualTrees, VirtualExplorerTree,
  MPShellUtilities, VirtualShellToolBar,
  MPCommonUtilities,

  ATSynPlugins,
  IniFiles,
  Buttons, StdCtrls, ToolWin, ComCtrls, ImgList,
  TntClasses, TntComCtrls, TntStdCtrls, TntMenus;

var
  _ActionProc: TSynAction = nil;
  _DefaultIni: string = '';
  _FormHandle: Pointer = nil;
  _fn_dll: Widestring = '';

type
  TFormNav = class(TForm)
    Panel1: TPanel;
    Tree: TVirtualExplorerTreeview;
    List: TVirtualExplorerEasyListview;
    Splitter1: TSplitter;
    XPManifest1: TXPManifest;
    Panel2: TPanel;
    Comb: TVirtualExplorerCombobox;
    Drv: TVirtualDriveToolbar;
    Stat: TStatusBar;
    ToolBar1: TTntToolBar;
    btnBack: TTntToolButton;
    ToolButton3: TTntToolButton;
    btnNewFolder: TTntToolButton;
    btnRefresh: TTntToolButton;
    btnSync: TTntToolButton;
    PopupMenuOpt: TTntPopupMenu;
    mnuV1: TTntMenuItem;
    mnuV2: TTntMenuItem;
    mnuV3: TTntMenuItem;
    mnuV4: TTntMenuItem;
    N1: TTntMenuItem;
    mnuDrv: TTntMenuItem;
    mnuComb: TTntMenuItem;
    mnuStat: TTntMenuItem;
    mnuHorz: TTntMenuItem;
    N2: TTntMenuItem;
    mnuHid: TTntMenuItem;
    ToolButton1: TTntToolButton;
    btnOpt: TTntToolButton;
    ImageList1: TImageList;
    mnuFilter: TTntMenuItem;
    TntToolButton1: TTntToolButton;
    btnFav: TTntToolButton;
    PopupMenuFav: TTntPopupMenu;
    mnuAddFav: TTntMenuItem;
    plFilter: TPanel;
    Panel3: TPanel;
    btnFilter: TSpeedButton;
    Panel4: TPanel;
    edFilter: TTntComboBox;
    mnuTree: TTntMenuItem;
    mnuNotif: TTntMenuItem;
    mnuFont: TTntMenuItem;
    FontDialog1: TFontDialog;
    mnuLastDir: TTntMenuItem;
    N3: TTntMenuItem;
    procedure FormCreate(Sender: TObject);
    procedure ListItemSelectionChanged(Sender: TCustomEasyListview;
      Item: TEasyItem);
    procedure FormShow(Sender: TObject);
    procedure mnuV1Click(Sender: TObject);
    procedure mnuV2Click(Sender: TObject);
    procedure mnuV3Click(Sender: TObject);
    procedure mnuV4Click(Sender: TObject);
    procedure mnuHidClick(Sender: TObject);
    procedure mnuHorzClick(Sender: TObject);
    procedure ListRootChanging(Sender: TCustomVirtualExplorerEasyListview;
      const NewValue: TRootFolder; const CurrentNamespace,
      Namespace: TNamespace; var Allow: Boolean);
    procedure ListRootChange(Sender: TCustomVirtualExplorerEasyListview);
    procedure mnuCombClick(Sender: TObject);
    procedure mnuDrvClick(Sender: TObject);
    procedure ListCustomColumnAdd(
      Sender: TCustomVirtualExplorerEasyListview;
      AddColumnProc: TELVAddColumnProc);
    procedure ListCustomColumnCompare(
      Sender: TCustomVirtualExplorerEasyListview; Column: TExplorerColumn;
      Group: TEasyGroup; Item1, Item2: TExplorerItem;
      var CompareResult: Integer);
    procedure ListCustomColumnGetCaption(
      Sender: TCustomVirtualExplorerEasyListview; Column: TExplorerColumn;
      Item: TExplorerItem; var ACaption: WideString);
    procedure mnuStatClick(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure btnBackClick(Sender: TObject);
    procedure btnFwClick(Sender: TObject);
    procedure btnNewFolderClick(Sender: TObject);
    procedure btnRefreshClick(Sender: TObject);
    procedure btnOptClick(Sender: TObject);
    procedure ListDblClick(Sender: TCustomEasyListview;
      Button: TCommonMouseButton; MousePos: TPoint;
      ShiftState: TShiftState; var Handled: Boolean);
    procedure mnuFilterClick(Sender: TObject);
    procedure ListQuickFilterCustomCompare(
      Sender: TCustomVirtualExplorerEasyListview; Item: TExplorerItem;
      Mask: WideString; var IsVisible: Boolean);
    procedure btnFilterClick(Sender: TObject);
    procedure edFilterKeyDown(Sender: TObject; var Key: Word;
      Shift: TShiftState);
    procedure btnSyncClick(Sender: TObject);
    procedure btnFavClick(Sender: TObject);
    procedure mnuAddFavClick(Sender: TObject);
    procedure mnuTreeClick(Sender: TObject);
    procedure mnuNotifClick(Sender: TObject);
    procedure mnuFontClick(Sender: TObject);
    procedure mnuLastDirClick(Sender: TObject);
    procedure PopupMenuFavPopup(Sender: TObject);
  private
    { Private declarations }
    FFileName: Widestring;
    FMakeVisible: boolean;
    FHidden: boolean;
    FNavSortDir: TEasySortDirection;
    FNavSortColumn: integer;
    FNavColumns: array[0 .. Pred(200)] of record
      Visible: boolean; Width, Position: integer end;

    FFontName: string;
    FFontSize: integer;
    FFontColor: TColor;
    FFontBold: boolean;

    FLastDirUse: boolean;
    FLastDir: Widestring;

    procedure GetFavList(L: TTntStringList);
    procedure FavItemClick(Sender: TObject);
    procedure ApplyFont;
    procedure ReadIni;
    procedure SaveIni;
    procedure NavBrowse(const S: WideString);
    procedure ListSave;
    procedure ListRestore;
    function GetColumns: string;
    procedure SetColumns(const AValue: string);
    function GetTreeW: integer;
    procedure SetTreeW(Value: integer);
    function GetComb: boolean;
    procedure SetComb(Value: boolean);
    function GetHorz: boolean;
    procedure SetHorz(Value: boolean);
    procedure UpdateState;
    procedure UpdateStatus;
    procedure SetHidden(AValue: boolean);
    function GetNotif: boolean;
    procedure SetNotif(V: boolean);
    property ShowComb: boolean read GetComb write SetComb;
    property Hidden: boolean read FHidden write SetHidden;
    property TreeW: integer read GetTreeW write SetTreeW;
    property Horz: boolean read GetHorz write SetHorz;
    property Columns: string read GetColumns write SetColumns;
    property Notif: boolean read GetNotif write SetNotif;
  public
    function CurrentDir: Widestring;
    function GetMsg(const AMsg: Widestring): Widestring;
    procedure UpdateLang;
  protected
  end;

var
  FormNav: TFormNav;

implementation

uses
  Math,
  ATxFProc, ATxSProc,
  VirtualResources, MPResources,
  TntSysUtils,
  ShellAPI;

{$R *.dfm}

//--------------------------------------------------------
{
Creating Windows Vista Ready Applications with Delphi
http://www.installationexcellence.com/articles/VistaWithDelphi/Index.html
}
procedure FixFormFont(AFont: TFont);
var
  LogFont: TLogFont;
begin
  if SystemParametersInfo(SPI_GETICONTITLELOGFONT, SizeOf(LogFont), @LogFont, 0) then
    AFont.Handle := CreateFontIndirect(LogFont)
  else
    AFont.Handle := GetStockObject(DEFAULT_GUI_FONT);
end;

//------------------
procedure UpdateLang;
begin
  {
  STR_HEADERMENUMORE:= FIniLang.ReadString('Captions', '780', '');
  STR_COLUMNMENU_MORE:= STR_HEADERMENUMORE;
  STR_COLUMNDLG_CAPTION:= FIniLang.ReadString('Captions', '781', '');
  STR_COLUMNDLG_LABEL1:= FIniLang.ReadString('Captions', '782', '');
  STR_COLUMNDLG_LABEL2:= FIniLang.ReadString('Captions', '783', '');
  STR_COLUMNDLG_LABEL3:= FIniLang.ReadString('Captions', '784', '');
  STR_COLUMNDLG_CHECKBOXLIVEUPDATE:= FIniLang.ReadString('Captions', '785', '');
  STR_COLUMNDLG_BUTTONOK:= FIniLang.ReadString('Captions', '350', '');
  STR_COLUMNDLG_BUTTONCANCEL:= FIniLang.ReadString('Captions', '351', '');
  }
end;

//-----------------------------
procedure TFormNav.ReadIni;
var
  i: Integer;
begin
  if _DefaultIni<>'' then
  with TIniFile.Create(_DefaultIni) do
  try
    TreeW := ReadInteger('Nav', 'TreeWidth', TreeW);
    List.View := TEasyListStyle(ReadInteger('Nav', 'ListView', integer(List.View)));

    FNavSortDir := TEasySortDirection(ReadInteger('Nav', 'SortDir', integer(esdAscending)));
    FNavSortColumn := ReadInteger('Nav', 'SortCol', 2);
    Columns := ReadString('Nav', 'Columns', '');
    ListRestore;

    Hidden := ReadBool('Nav', 'Hidden', False);
    Horz := ReadBool('Nav', 'Horz', True);
    ShowComb := ReadBool('Nav', 'Comb', True);
    Tree.Visible := ReadBool('Nav', 'Tree', True);
    Drv.Visible := ReadBool('Nav', 'Drv', True);
    Stat.Visible := ReadBool('Nav', 'Stat', True);
    plFilter.Visible := ReadBool('Nav', 'Filter', True);
    Notif := ReadBool('Nav', 'Notif', false);

    with edFilter do
    begin
      for i:= 0 to ReadInteger('Filter', 'Cnt', Items.Count)-1 do
        Items.Add(UTF8Decode(ReadString('Filter', IntToStr(i), '')));
      Text:= ReadString('Filter', 'Text', '*.*');
    end;
    btnFilterClick(Self);

    FFontName:= ReadString('Font', 'Name', 'Tahoma');
    FFontSize:= ReadInteger('Font', 'Size', 8);
    FFontColor:= TColor(ReadInteger('Font', 'Color', clWindowText));
    FFontBold:= ReadBool('Font', 'Bold', false);
    ApplyFont;

    FLastDirUse:= ReadBool('Nav', 'LastDirUse', false);
    if FLastDirUse then
      FLastDir:= UTF8Decode(ReadString('Nav', 'LastDir', ''));
  finally
    Free
  end;

  UpdateState;
end;

procedure TFormNav.SaveIni;
const
  cMaxItems = 15;
var
  i, N: Integer;
begin
  if _DefaultIni<>'' then
  with TIniFile.Create(_DefaultIni) do
  try
    WriteInteger('Nav', 'TreeWidth', TreeW);
    WriteInteger('Nav', 'ListView', integer(List.View));
    WriteBool('Nav', 'Hidden', Hidden);
    WriteBool('Nav', 'Horz', Horz);
    WriteBool('Nav', 'Comb', ShowComb);
    WriteBool('Nav', 'Tree', Tree.Visible);
    WriteBool('Nav', 'Drv', Drv.Visible);
    WriteBool('Nav', 'Stat', Stat.Visible);
    WriteBool('Nav', 'Filter', plFilter.Visible);
    WriteBool('Nav', 'Notif', Notif);

    with edFilter do
    begin
      WriteString('Filter', 'Text', Text);
      N:= Min(Items.Count, cMaxItems);
      WriteInteger('Filter', 'Cnt', N);
      for i:= 0 to N-1 do
        WriteString('Filter', IntToStr(i), UTF8Encode(Items[i]));
    end;

    ListSave;
    WriteInteger('Nav', 'SortDir', integer(FNavSortDir));
    WriteInteger('Nav', 'SortCol', FNavSortColumn);
    WriteString('Nav', 'Columns', Columns);

    WriteString('Font', 'Name', FFontName);
    WriteInteger('Font', 'Size', FFontSize);
    WriteInteger('Font', 'Color', FFontColor);
    WriteBool('Font', 'Bold', FFontBold);

    WriteBool('Nav', 'LastDirUse', FLastDirUse);
    WriteString('Nav', 'LastDir', UTF8Encode(CurrentDir));
  finally
    Free
  end;    
end;

//-----------------------------
procedure TFormNav.FormCreate(Sender: TObject);
begin
  {
  FixFormFont(Tree.Font);
  FixFormFont(List.Font);
  FixFormFont(List.Header.Font);
  }

  FFontName:= 'Tahoma';
  FFontSize:= 8;
  FFontColor:= clWindowText;
  FFontBold:= false;
  ApplyFont;

  FMakeVisible:= false;
end;

//---------------------------
procedure TFormNav.ListItemSelectionChanged(Sender: TCustomEasyListview;
  Item: TEasyItem);
var
  NS: TNameSpace;
begin
  Stat.SimpleText:= '';
  FFileName:= '';
  if Assigned(Item) and Item.Selected then
  begin
    if FMakeVisible then
      Item.MakeVisible(emvTop);
    NS:= TExplorerItem(Item).Namespace;
    if NS.FileSystem then
      if IsFileExist(NS.NameForParsing) then
      begin
        Stat.SimpleText:= ' ' + NS.DetailsDefaultOf(1) + '  ' + NS.DetailsDefaultOf(3);
        FFileName:= NS.NameForParsing;
      end;
  end;
end;

function GetPluginFilename: string;
var
  buf: array[0..Pred(MAX_PATH)] of char;
begin
  SetString(Result, buf,
    GetModuleFileName(hInstance, buf, SizeOf(buf)));
end;

//---------------------------------------------------------------
function TFormNav.GetMsg(const AMsg: Widestring): Widestring;
var
  buf: array[0..Pred(cSynMaxMsg)] of WideChar;
begin
  Result:= '';
  FillChar(buf, SizeOf(buf), 0);
  if Assigned(_ActionProc) then
  begin
    if _ActionProc(nil, //no handle needed for GetMsg
      cActionGetMsg,
      PWChar(Widestring(_fn_dll)), PWChar(AMsg), @buf, nil) = cSynOK then
      Result:= buf;
  end;   
end;

//---------------------------------------------------------------
procedure TFormNav.FormShow(Sender: TObject);
begin
  //Showmessage(GetMsg('LL'));
  UpdateLang;

  //Active set must be before columns restoring
  Tree.Active := True;
  List.Active := True;
  Comb.Active := True;

  ReadIni;
  UpdateState;
  UpdateStatus;

  if FLastDir='' then
    FLastDir:= 'C:\';
  NavBrowse(FLastDir);
end;

procedure TFormNav.UpdateStatus;
begin
end;

procedure TFormNav.mnuV1Click(Sender: TObject);
begin
  List.View := elsIcon;
  UpdateState;
end;

procedure TFormNav.mnuV2Click(Sender: TObject);
begin
  List.View := elsList;
  UpdateState;
end;

procedure TFormNav.mnuV3Click(Sender: TObject);
begin
  List.View := elsReport;
  UpdateState;
end;

procedure TFormNav.mnuV4Click(Sender: TObject);
begin
  List.View := elsThumbnail;
  UpdateState;
end;

procedure TFormNav.mnuHidClick(Sender: TObject);
begin
  Hidden := not Hidden;
  UpdateState;
end;

procedure TFormNav.mnuHorzClick(Sender: TObject);
begin
  Horz := not Horz;
  UpdateState;
end;

procedure TFormNav.UpdateState;
begin
  UpdateStatus;
  mnuV1.Checked := List.View = elsIcon;
  mnuV2.Checked := List.View = elsList;
  mnuV3.Checked := List.View = elsReport;
  mnuV4.Checked := List.View = elsThumbnail;
  mnuHid.Checked := Hidden;
  mnuHorz.Checked := Horz;
  mnuTree.Checked := Tree.Visible;
  mnuComb.Checked := ShowComb;
  mnuDrv.Checked := Drv.Visible;
  mnuFilter.Checked := plFilter.Visible;
  mnuStat.Checked := Stat.Visible;
  mnuNotif.Checked := Notif;
  mnuLastDir.Checked:= FLastDirUse;
end;

procedure TFormNav.SetHidden(AValue: boolean);
begin
  FHidden := AValue;
  with Tree do
  begin
    FileObjects:= FileObjects - [foHidden];
    if AValue then
      FileObjects:= FileObjects + [foHidden];
  end;
  with List do
  begin
    FileObjects:= FileObjects - [foHidden];
    if AValue then
      FileObjects:= FileObjects + [foHidden];
  end;
end;

//--------------------------------
//-----------------------
function TFormNav.GetTreeW: integer;
begin
  if Tree.Align = alLeft then
    Result := Tree.Width
  else
    Result := Tree.Height;
end;

procedure TFormNav.SetTreeW(Value: integer);
begin
  if Tree.Align = alLeft then
    Tree.Width := Value
  else
    Tree.Height := Value;
end;

//-----------------------
function TFormNav.GetHorz: boolean;
begin
  Result := Tree.Align <> alLeft;
end;

procedure TFormNav.SetHorz(Value: boolean);
const
  Al: array[boolean] of TAlign = (alLeft, alTop);
var
  w: integer;
begin
  w := TreeW;
  Tree.Align := Al[Value];
  Splitter1.Align := Al[Value];
  TreeW := w;

  if Value then
    Splitter1.Top := Tree.Top + 4
  else
    Splitter1.Left := Tree.Left + 4;
end;

//------------------------
function TFormNav.GetColumns: string;
var
  n, n1, n2, n3: integer;
begin
  Result:= '';
  for n := 0 to High(FNavColumns) do
  begin
    with FNavColumns[n] do
    begin
      n1 := integer(Visible);
      n2 := Width;
      n3 := Position;
    end;
    if (n1 = 0) and (n2 = 0) and (n3 = 0) then Break;
    Result := Result + Format('%d,%d,%d,', [n1, n2, n3]);
  end;
end;

function SGetItem(var SList: string): string;
var
  k: integer;
begin
  k := Pos(',', SList);
  if k = 0 then k := MaxInt;
  Result := Copy(SList, 1, k - 1);
  Delete(SList, 1, k);
end;

procedure TFormNav.SetColumns(const AValue: string);
var
  S: string;
  n, n1, n2, n3: integer;
begin
  S:= AValue;
  for n := 0 to High(FNavColumns) do
  begin
    n1 := StrToIntDef(SGetItem(S), 0);
    n2 := StrToIntDef(SGetItem(S), 0);
    n3 := StrToIntDef(SGetItem(S), 0);
    if (n1 = 0) and (n2 = 0) and (n3 = 0) then Break;
    with FNavColumns[n] do
    begin
      Visible := boolean(n1);
      Width := n2;
      Position := n3;
    end;
  end;
end;

//--------------------------
procedure TFormNav.ListRestore;
var
  i: integer;
begin
  with List do
    if RootFolderNamespace.FileSystem then
    begin
      for i := 0 to Header.Columns.Count - 1 do
        if FNavSortColumn = i then
          Header.Columns[i].SortDirection := FNavSortDir
        else
          Header.Columns[i].SortDirection := esdNone;

      for i := 0 to Header.Columns.Count - 1 do
        if i <= High(FNavColumns) then
          with FNavColumns[i] do
            if not ((Visible = False) and (Width = 0) and (Position = 0)) then
            begin
              Header.Columns[i].Visible := Visible;
              Header.Columns[i].Width := Width;
              Header.Columns[i].Position := Position;
            end;
    end;
end;

procedure TFormNav.ListSave;
var
  i: integer;
begin
  with List do
  begin
    for i:= 0 to Header.Columns.Count - 1 do
      if Header.Columns[i].SortDirection <> esdNone then
      begin
        FNavSortColumn:= i;
        FNavSortDir:= Header.Columns[i].SortDirection;
        Break
      end;

    FillChar(FNavColumns, SizeOf(FNavColumns), 0);
    for i:= 0 to Header.Columns.Count - 1 do
      if i <= High(FNavColumns) then
      begin
        FNavColumns[i].Visible:= Header.Columns[i].Visible;
        FNavColumns[i].Width:= Header.Columns[i].Width;
        FNavColumns[i].Position:= Header.Columns[i].Position;
      end;
  end;
end;

//---------------------------
procedure TFormNav.ListRootChanging(
  Sender: TCustomVirtualExplorerEasyListview; const NewValue: TRootFolder;
  const CurrentNamespace, Namespace: TNamespace; var Allow: Boolean);
begin
  if Assigned(CurrentNamespace) then
    if CurrentNamespace.FileSystem then
      ListSave;
end;

procedure TFormNav.ListRootChange(
  Sender: TCustomVirtualExplorerEasyListview);
begin
  ListRestore;
end;

procedure TFormNav.NavBrowse(const S: Widestring);
begin
  if S <> '' then
    if IsDirExist(S) then
      Tree.BrowseTo(S, False)
    else
      List.BrowseTo(S);
end;

procedure TFormNav.ListCustomColumnAdd(
  Sender: TCustomVirtualExplorerEasyListview;
  AddColumnProc: TELVAddColumnProc);
var
  Column: TExplorerColumn;
begin
  Column := AddColumnProc;
  Column.Caption := '.Ext';
  Column.Width := 60;
  Column.Alignment := taLeftJustify;
  Column.Visible := True;
end;

function FExt(Item: TExplorerItem): WideString;
begin
  Result := '';
  if Assigned(Item) and Assigned(Item.Namespace) then
    if not Item.Namespace.Folder then
      Result := WideLowerCase(WideExtractFileExt(Item.Namespace.NameForParsing));
end;

function FName(Item: TExplorerItem): WideString;
begin
  Result := '';
  if Assigned(Item) and Assigned(Item.Namespace) then
    Result := WideExtractFileName(Item.Namespace.NameForParsing);
end;

procedure TFormNav.ListCustomColumnCompare(
  Sender: TCustomVirtualExplorerEasyListview; Column: TExplorerColumn;
  Group: TEasyGroup; Item1, Item2: TExplorerItem;
  var CompareResult: Integer);
begin
  CompareResult := WideCompareStr(FExt(Item1), FExt(Item2));
  if CompareResult = 0 then
    CompareResult := WideCompareStr(FName(Item1), FName(Item2));
  if Column.SortDirection = esdDescending then
    CompareResult := -CompareResult;
end;

procedure TFormNav.ListCustomColumnGetCaption(
  Sender: TCustomVirtualExplorerEasyListview; Column: TExplorerColumn;
  Item: TExplorerItem; var ACaption: WideString);
begin
  ACaption := FExt(Item);
end;

function TFormNav.GetComb: boolean;
begin
  Result := Panel2.Visible;
end;

procedure TFormNav.SetComb(Value: boolean);
begin
  Panel2.Visible := Value;
end;

procedure TFormNav.mnuCombClick(Sender: TObject);
begin
  ShowComb := not ShowComb;
  UpdateState;
end;

procedure TFormNav.mnuDrvClick(Sender: TObject);
begin
  Drv.Visible := not Drv.Visible;
  UpdateState;
end;

procedure TFormNav.mnuStatClick(Sender: TObject);
begin
  Stat.Visible := not Stat.Visible;
  UpdateState;
end;

function LabelOfDisk(const s: WideString): Widestring;
var
  p: TSHFileInfoW;
begin
  Fillchar(p, sizeof(p), 0);
  SHGetFileInfoW(PAnsiChar(PWIdeChar(s)), 0, p, sizeof(p), SHGFI_DISPLAYNAME);
  Result:= p.szDisplayName;
end;

procedure TFormNav.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  SaveIni;
end;

procedure TFormNav.btnBackClick(Sender: TObject);
begin
  List.BrowseToPrevLevel;
end;

procedure TFormNav.btnFwClick(Sender: TObject);
begin
  List.BrowseToNextLevel;
end;

procedure TFormNav.btnNewFolderClick(Sender: TObject);
begin
  List.CreateNewFolder(CurrentDir);
  Tree.Refresh;
end;

procedure TFormNav.btnRefreshClick(Sender: TObject);
begin
  Tree.RefreshTree(true);
  List.RereadAndRefresh(true);
end;

procedure TFormNav.btnOptClick(Sender: TObject);
var
  P: TPoint;
begin
  P:= Point(btnOpt.Left, btnOpt.Top+btnOpt.Height);
  P:= Toolbar1.ClientToScreen(P);
  PopupMenuOpt.Popup(P.X, P.Y);
end;

procedure TFormNav.ListDblClick(Sender: TCustomEasyListview;
  Button: TCommonMouseButton; MousePos: TPoint; ShiftState: TShiftState;
  var Handled: Boolean);
begin
  Handled:= (FFileName<>'');
  if Handled then
    if Assigned(_ActionProc) then
      _ActionProc(_FormHandle, cActionOpenFile, PWChar(FFileName), nil, nil, nil);
end;

procedure TFormNav.mnuFilterClick(Sender: TObject);
begin
  with plFilter do
    Visible := not Visible;
  UpdateState;
end;

procedure TFormNav.ListQuickFilterCustomCompare(
  Sender: TCustomVirtualExplorerEasyListview; Item: TExplorerItem;
  Mask: WideString; var IsVisible: Boolean);
begin
  if Item.Namespace.Folder then
    IsVisible:= not WidePathMatchSpec(WideExtractFileName(Item.Namespace.FileName), '*.zip')
  else
    IsVisible:= WidePathMatchSpec(WideExtractFileName(Item.Namespace.FileName), Mask);
end;

procedure TFormNav.btnFilterClick(Sender: TObject);
var
  S: Widestring;
  N: Integer;
begin
  S:= edFilter.Text;
  List.QuickFiltered:= Trim(S)<>'';
  List.QuickFilterMask:= S;
  if List.QuickFiltered then
    with edFilter do
    begin
      N:= Items.IndexOf(S);
      if N>=0 then Items.Delete(N);
      Items.Insert(0, S);
      Text:= S;
    end;  
end;

procedure TFormNav.edFilterKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  if (Key=vk_return) then
  begin
    btnFilterClick(Self);
    Key:= 0;
    Exit
  end;
end;

procedure TFormNav.btnSyncClick(Sender: TObject);
var
  buf: array[0..cSynMaxPath-1] of WideChar;
  fn: Widestring;
  {$ifdef DD}
  fn_all: Widestring;
  i: Integer;
  {$endif}
begin
  if not Assigned(_ActionProc) then Exit;

  //debug
  {$ifdef DD}
  fn_all:= '';
  for i:= 0 to 100 do
  begin
    FillChar(buf, Sizeof(buf), 0);
    if ActionProc(Self, cActionGetOpenedFileName, @buf[0], Pointer(i), nil, nil)<>cSynOK then Break;
    fn:= buf;
    fn_all:= fn_all+fn+#13;
  end;
  Showmessage(fn_all);
  {$endif}

  FillChar(buf, Sizeof(buf), 0);
  _ActionProc(_FormHandle, cActionGetOpenedFileName, @buf[0], Pointer(cSynIdCurrentFile), nil, nil);
  fn:= buf;
    
  if fn<>'' then
  begin
    FMakeVisible:= true;
    List.BrowseTo(fn);
    FMakeVisible:= false;
    List.SetFocus;
  end;
end;

procedure TFormNav.btnFavClick(Sender: TObject);
var
  P: TPoint;
begin
  P:= Point(btnFav.Left, btnFav.Top+btnFav.Height);
  P:= Toolbar1.ClientToScreen(P);
  PopupMenuFav.Popup(P.X, P.Y);
end;

function TFormNav.CurrentDir: Widestring;
begin
  Result:= //Tree.SelectedPath;
    WideExtractFileDir(List.SelectedPath);
end;

procedure TFormNav.mnuAddFavClick(Sender: TObject);
var
  S: Widestring;
begin
  S:= 'Explorer::'+CurrentDir;
  if Assigned(_ActionProc) then
    _ActionProc(_FormHandle, cActionAddToFavorites, PWChar(S), nil, nil, nil);
end;

procedure TFormNav.mnuTreeClick(Sender: TObject);
begin
  with Tree do
    Visible:= not Visible;
  UpdateState;  
end;

function TFormNav.GetNotif: boolean;
begin
  Result:= eloChangeNotifierThread in List.Options;
end;

procedure TFormNav.SetNotif(V: boolean);
begin
  if V<>GetNotif then
  if V then
  begin
    List.Options:= List.Options + [eloChangeNotifierThread];
    Tree.TreeOptions.VETMiscOptions:= Tree.TreeOptions.VETMiscOptions + [toChangeNotifierThread];
  end
  else
  begin
    List.Options:= List.Options - [eloChangeNotifierThread];
    Tree.TreeOptions.VETMiscOptions:= Tree.TreeOptions.VETMiscOptions - [toChangeNotifierThread];
  end;
end;

procedure TFormNav.mnuNotifClick(Sender: TObject);
begin
  Notif := not Notif;
  UpdateState;
end;

procedure TFormNav.UpdateLang;
begin
  mnuV1.Caption:= GetMsg('VIcons');
  mnuV2.Caption:= GetMsg('VList');
  mnuV3.Caption:= GetMsg('VDet');
  mnuV4.Caption:= GetMsg('VThum');
  mnuDrv.Caption:= GetMsg('ShowDrv');
  mnuTree.Caption:= GetMsg('ShowTree');
  mnuComb.Caption:= GetMsg('ShowPath');
  mnuFilter.Caption:= GetMsg('ShowFilter');
  mnuStat.Caption:= GetMsg('ShowStatus');
  mnuHorz.Caption:= GetMsg('HorzSplit');
  mnuFont.Caption:= GetMsg('Font');
  mnuNotif.Caption:= GetMsg('AutoRefr');
  mnuHid.Caption:= GetMsg('ShowHid');
  mnuAddFav.Caption:= GetMsg('AddFav');
  mnuLastDir.Caption:= GetMsg('LastDir');

  btnBack.Hint:= GetMsg('hGoUp');
  btnNewFolder.Hint:= GetMsg('hNewDir');
  btnRefresh.Hint:= GetMsg('hRefr');
  btnSync.Hint:= GetMsg('hFocus');
  edFilter.Hint:= GetMsg('hFilter');

  List.BackGround.Caption := GetMsg('lvEmpty');
  STR_HEADERMENUMORE:= GetMsg('lvMore');
  STR_COLUMNMENU_MORE:= STR_HEADERMENUMORE;
  STR_COLUMNDLG_CAPTION:= GetMsg('lvColSett');
  STR_COLUMNDLG_LABEL1:= GetMsg('lvColCheck');
  STR_COLUMNDLG_LABEL2:= GetMsg('lvColShoud');
  STR_COLUMNDLG_LABEL3:= GetMsg('lvColPix');
  STR_COLUMNDLG_CHECKBOXLIVEUPDATE:= GetMsg('lvLiveUpd');
  STR_COLUMNDLG_BUTTONOK:= GetMsg('bOk');
  STR_COLUMNDLG_BUTTONCANCEL:= GetMsg('bCancel');

  {
  S_NEW:= 'Новая ';
  S_FOLDER:= 'Папка';
  S_SHORTCUT:= 'Ссылка';
  }
  S_OVERWRITE_EXISTING_FILE:= GetMsg('StrOverwr');
  STR_ERROR:= GetMsg('StrErr');
  STR_NEWFOLDER:= GetMsg('StrNewDir');
end;

procedure TFormNav.ApplyFont;
begin
  List.Font.Name:= FFontName;
  List.Font.Size:= FFontSize;
  List.Font.Color:= FFontColor;
  if FFontBold then
    List.Font.Style:= [fsBold]
  else
    List.Font.Style:= [];

  Tree.Font.Assign(List.Font);
  Comb.Font.Assign(List.Font);
  edFilter.Font.Assign(List.Font);
  Stat.Font.Assign(List.Font);
  Drv.Font.Assign(List.Font);
end;

procedure TFormNav.mnuFontClick(Sender: TObject);
begin
  with FontDialog1 do
  begin
    Font.Name:= FFontName;
    Font.Size:= FFontSize;
    Font.Color:= FFontColor;
    if FFontBold then
      Font.Style:= [fsBold]
    else
      Font.Style:= [];
    if not Execute then Exit;

    FFontName:= Font.Name;
    FFontSize:= Font.Size;
    FFontColor:= Font.Color;
    FFontBold:= fsBold in Font.Style;
    ApplyFont;
  end;
end;

procedure TFormNav.mnuLastDirClick(Sender: TObject);
begin
  FLastDirUse:= not FLastDirUse;
  UpdateState;
end;

procedure TFormNav.PopupMenuFavPopup(Sender: TObject);
const
  id = 'Explorer::';
var
  L: TTntStringList;
  i: Integer;
  S: Widestring;
  MI: TTntMenuItem;
begin
  with PopupMenuFav do
  begin
    while Items.Count>2 do
      Items.Delete(Items.Count-1);

    L:= TTntStringList.Create;
    try
      GetFavList(L);
      for i:= 0 to L.Count-1 do
      begin
        S:= L[i];
        if Pos(id, S)=1 then
          Delete(S, 1, Length(id))
        else
          Continue;
        MI:= TTntMenuItem.Create(Self);
        MI.Caption:= S;
        MI.OnClick:= FavItemClick;
        Items.Add(MI);
      end;
    finally
      FreeAndNil(L);
    end;
  end;
end;

procedure TFormNav.GetFavList(L: TTntStringList);
const
  cSize = 32*1024; //big buffer so don't handle "too small" error
var
  buf: array[0..cSize-1] of WideChar;
  bufSize: Integer;
  r: Integer;
begin
  L.Clear;
  Assert(Assigned(_ActionProc));

  bufSize:= cSize;
  r:= _ActionProc(nil, cActionGetText, Pointer(cSynIdFavoritesText), @buf, @bufSize, nil);

  if r=cSynError then
    Exit
  else
  if r=cSynSmallBuffer then
  begin
    MessageBox(Handle, 'Default buffer is too small for Favorites list', 'Explorer', mb_ok or mb_iconerror);
    Exit
  end
  else
    L.Text:= WideString(buf);
end;

procedure TFormNav.FavItemClick(Sender: TObject);
var
  fn: Widestring;
begin
  fn:= (Sender as TTntMenuItem).Caption;
  if fn<>'' then
  begin
    //Showmessage(fn); //test
    NavBrowse(fn);
  end
  else
    MessageBeep(mb_iconerror);  
end;


initialization
  _fn_dll:= GetPluginFilename;

end.

