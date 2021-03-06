unit uMainForm;

interface

uses
  Winapi.Windows, Winapi.Messages, Winapi.GDIPAPI, Winapi.GDIPOBJ, System.SysUtils, System.Variants, System.Classes, System.IOUtils, System.Types, System.IniFiles, System.Math,
  Vcl.Imaging.jpeg, Vcl.Imaging.pngimage, Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.ComCtrls, ShellCtrls, Vcl.ExtCtrls, Vcl.Menus, PicShow, db.uCommon;

type
  TfrmImageSee = class(TForm)
    pgcSee: TPageControl;
    tsBrowse: TTabSheet;
    shltrvwImage: TShellTreeView;
    mmMain: TMainMenu;
    N1: TMenuItem;
    N2: TMenuItem;
    scrlbxSee: TScrollBox;
    tsView: TTabSheet;
    scrlbxView: TScrollBox;
    imgView: TImage;
    pmView: TPopupMenu;
    mniFitSize: TMenuItem;
    mniLine01: TMenuItem;
    mniPirorImage: TMenuItem;
    mniNextImage: TMenuItem;
    mniFirstImage: TMenuItem;
    mniBottomImage: TMenuItem;
    mniLine02: TMenuItem;
    mniSlideShow: TMenuItem;
    procedure shltrvwImageChange(Sender: TObject; Node: TTreeNode);
    procedure imgViewDblClick(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure FormMouseWheel(Sender: TObject; Shift: TShiftState; WheelDelta: Integer; MousePos: TPoint; var Handled: Boolean);
    procedure FormShow(Sender: TObject);
    procedure FormResize(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure mniFirstImageClick(Sender: TObject);
    procedure mniBottomImageClick(Sender: TObject);
    procedure mniPirorImageClick(Sender: TObject);
    procedure mniSlideShowClick(Sender: TObject);
  private
    FbStretch: Boolean;
    FintIndex: Integer;
    procedure FreeThumbImageList;
    procedure CreateThumbImageList(const strFolder: string);
    procedure CreateThumbImagePanel(const ImageList: TStringList; const bDir: Boolean = False); overload;
    procedure CreateThumbImagePanel(pnl: TPanel; const strFolder: string); overload;
    procedure imgDBLClick(Sender: TObject);
    function SetPanelTop: Integer;
    function SetPanelLeft: Integer;
    procedure FirstLoadImage(const strFileName: string);
    procedure StretchZoom(const bmp: TBitmap; const bStretch: Boolean = True);
    procedure ShowSlideForm(const strFolder: string);
  public
    class procedure GetAllImage(const strFolder: String; var lstImage: TStringList);
  end;

procedure db_ShowDllForm_Plugins(var frm: TFormClass; var strParentModuleName, strModuleName, strIconFileName: PAnsiChar); stdcall;

implementation

{$R *.dfm}

uses uSlideShowForm;

const
  c_strimgSeeCaption = 'imgSee v2.0';

procedure db_ShowDllForm_Plugins(var frm: TFormClass; var strParentModuleName, strModuleName, strIconFileName: PAnsiChar); stdcall;
begin
  frm                     := TfrmImageSee;
  strParentModuleName     := '图形图像';
  strModuleName           := '图像查看器';
  strIconFileName         := '';
  Application.Handle      := GetMainFormApplication.Handle;
  Application.Icon.Handle := GetMainFormApplication.Icon.Handle;
end;

procedure TfrmImageSee.FreeThumbImageList;
var
  I: Integer;
begin
  for I := scrlbxSee.ComponentCount - 1 downto 0 do
  begin
    scrlbxSee.Components[I].Free;
  end;
end;

procedure TfrmImageSee.shltrvwImageChange(Sender: TObject; Node: TTreeNode);
var
  strFolder: String;
begin
  FreeThumbImageList;

  strFolder := shltrvwImage.Path;
  if not DirectoryExists(strFolder) then
    Exit;

  CreateThumbImageList(strFolder);
end;

const
  c_intXBetween    = 20;
  c_intYBetween    = 20;
  c_intThumbWidth  = 120;
  c_intThumbHeight = 120;

function TfrmImageSee.SetPanelTop: Integer;
var
  I, J, Count: Integer;
  intIndex   : Integer;
begin
  { 已经存在的缩略 Panel }
  intIndex := 0;
  for I    := 0 to scrlbxSee.ComponentCount - 2 do
  begin
    if scrlbxSee.Components[I] is TPanel then
    begin
      inc(intIndex);
    end;
  end;

  { 一行最多可以显示的缩略 Panel 数目 }
  Count := scrlbxSee.Width div (c_intThumbWidth + c_intXBetween);

  J      := intIndex div Count;
  Result := c_intYBetween + J * (c_intThumbHeight + c_intYBetween);
end;

function TfrmImageSee.SetPanelLeft: Integer;
var
  I, J, Count: Integer;
  intIndex   : Integer;
begin
  { 已经存在的缩略 Panel }
  intIndex := 0;
  for I    := 0 to scrlbxSee.ComponentCount - 2 do
  begin
    if scrlbxSee.Components[I] is TPanel then
    begin
      inc(intIndex);
    end;
  end;

  { 一行最多可以显示的缩略 Panel 数目 }
  Count := scrlbxSee.Width div (c_intThumbWidth + c_intXBetween);

  J      := intIndex mod Count;
  Result := c_intXBetween + J * (c_intThumbWidth + c_intXBetween);
end;

procedure LoadImage(const strImageFileName: String; var bmp: TBitmap);
var
  imgTemp: TGPImage;
begin
  imgTemp := TGPImage.Create(strImageFileName);
  try
    bmp.PixelFormat := pf32bit;
    bmp.Width       := c_intThumbWidth;
    bmp.Height      := c_intThumbHeight;
    TGPGraphics(TGPGraphics.Create(bmp.Canvas.Handle).DrawImage(imgTemp, 0, 0, c_intThumbWidth, c_intThumbHeight)).Free;
  finally
    imgTemp.Free;
  end;
end;

procedure LoadOriImage(const strImageFileName: String; var bmp: TBitmap);
var
  imgTemp: TGPImage;
begin
  imgTemp := TGPImage.Create(strImageFileName);
  try
    bmp.PixelFormat := pf32bit;
    bmp.Width       := imgTemp.GetWidth;
    bmp.Height      := imgTemp.GetHeight;
    TGPGraphics(TGPGraphics.Create(bmp.Canvas.Handle).DrawImage(imgTemp, 0, 0, bmp.Width, bmp.Height)).Free;
  finally
    imgTemp.Free;
  end;
end;

procedure LoadThumbImage(const strImageFileName: String; var bmp: TBitmap);
var
  imgTemp: TGPImage;
begin
  imgTemp := TGPImage.Create(strImageFileName);
  try
    bmp.PixelFormat := pf32bit;
    bmp.Width       := 45;
    bmp.Height      := 45;
    TGPGraphics(TGPGraphics.Create(bmp.Canvas.Handle).DrawImage(imgTemp, 0, 0, 45, 45)).Free;
  finally
    imgTemp.Free;
  end;
end;

procedure TfrmImageSee.imgDBLClick(Sender: TObject);
var
  strPathName: String;
  strFileName: String;
begin
  if TWinControl(Sender).Tag = 0 then
  begin
    strPathName       := TPanel(Sender).Hint;
    shltrvwImage.Path := strPathName;
    shltrvwImage.OnChange(nil, nil);
    Caption := c_strimgSeeCaption + '    ' + strPathName;
  end
  else
  begin
    strFileName := TImage(Sender).Parent.Hint;
    FirstLoadImage(strFileName);
    pgcSee.ActivePageIndex := 1;
    Caption                := c_strimgSeeCaption + '    ' + strFileName;
  end;
end;

class procedure TfrmImageSee.GetAllImage(const strFolder: String; var lstImage: TStringList);
var
  jpgArr     : TStringDynArray;
  bmpArr     : TStringDynArray;
  pngArr     : TStringDynArray;
  strFileName: String;
begin
  jpgArr := TDirectory.GetFiles(strFolder, '*.jpg', TSearchOption.soTopDirectoryOnly);
  bmpArr := TDirectory.GetFiles(strFolder, '*.bmp', TSearchOption.soTopDirectoryOnly);
  pngArr := TDirectory.GetFiles(strFolder, '*.png', TSearchOption.soTopDirectoryOnly);
  for strFileName in jpgArr do
    lstImage.Add(strFileName);
  for strFileName in bmpArr do
    lstImage.Add(strFileName);
  for strFileName in pngArr do
    lstImage.Add(strFileName);
end;

procedure TfrmImageSee.CreateThumbImagePanel(pnl: TPanel; const strFolder: string);
const
  c_imgpos: array [0 .. 3] of TPoint = ((x: 10; y: 10), (x: 65; y: 10), (x: 10; y: 65), (x: 65; y: 65));
var
  lstImage: TStringList;
  I, Count: Integer;
  bmpTemp : TBitmap;
  imgThumb: TArray<TImage>;
begin
  lstImage := TStringList.Create;
  try
    GetAllImage(strFolder, lstImage);
    if lstImage.Count > 0 then
    begin
      if lstImage.Count > 4 then
        Count := 4
      else
        Count := lstImage.Count;
      SetLength(imgThumb, Count);
      for I := 0 to Count - 1 do
      begin
        bmpTemp := TBitmap.Create;
        try
          LoadThumbImage(lstImage.Strings[I], bmpTemp);
          imgThumb[I]        := TImage.Create(pnl);
          imgThumb[I].Parent := pnl;
          imgThumb[I].Width  := 45;
          imgThumb[I].Height := 45;
          imgThumb[I].Left   := c_imgpos[I].x;
          imgThumb[I].Top    := c_imgpos[I].y;
          imgThumb[I].Picture.Bitmap.Assign(bmpTemp);
          imgThumb[I].Tag        := 0;
          imgThumb[I].Hint       := strFolder;
          imgThumb[I].OnDblClick := imgDBLClick;
        finally
          bmpTemp.Free;
        end;
      end;
    end;
  finally
    lstImage.Free;
  end;
end;

procedure TfrmImageSee.CreateThumbImagePanel(const ImageList: TStringList; const bDir: Boolean = False);
var
  pnl    : TArray<TPanel>;
  I      : Integer;
  bmpTemp: TBitmap;
begin
  if bDir then
  begin
    SetLength(pnl, 1);
    pnl[0]             := TPanel.Create(scrlbxSee);
    pnl[0].Parent      := scrlbxSee;
    pnl[0].Color       := clWhite;
    pnl[0].Width       := c_intThumbWidth;
    pnl[0].Height      := c_intThumbHeight;
    pnl[0].Top         := SetPanelTop;
    pnl[0].Left        := SetPanelLeft;
    pnl[0].BorderStyle := bsSingle;
    pnl[0].ShowCaption := False;
    pnl[0].BevelOuter  := bvNone;
    pnl[0].Ctl3D       := False;
    pnl[0].Hint        := ImageList.DelimitedText;
    pnl[0].ShowHint    := True;
    pnl[0].Tag         := 0;
    pnl[0].OnDblClick  := imgDBLClick;
    CreateThumbImagePanel(pnl[0], ImageList.DelimitedText);
  end
  else
  begin
    SetLength(pnl, ImageList.Count);
    for I := 0 to ImageList.Count - 1 do
    begin
      pnl[I]             := TPanel.Create(scrlbxSee);
      pnl[I].Parent      := scrlbxSee;
      pnl[I].Color       := clWhite;
      pnl[I].Width       := c_intThumbWidth;
      pnl[I].Height      := c_intThumbHeight;
      pnl[I].Top         := SetPanelTop;
      pnl[I].Left        := SetPanelLeft;
      pnl[I].BorderStyle := bsNone;
      pnl[I].ShowCaption := False;
      pnl[I].BevelOuter  := bvNone;
      pnl[I].Ctl3D       := False;
      pnl[I].Hint        := ImageList.Strings[I];
      pnl[I].ShowHint    := True;
      with TImage.Create(pnl[I]) do
      begin
        Parent     := pnl[I];
        AutoSize   := True;
        Stretch    := False;
        Align      := alClient;
        Tag        := 1;
        OnDblClick := imgDBLClick;
        bmpTemp    := TBitmap.Create;
        try
          LoadImage(ImageList.Strings[I], bmpTemp);
          Picture.Bitmap.Assign(bmpTemp);
        finally
          bmpTemp.Free;
        end;
      end;
    end;
  end;
end;

procedure TfrmImageSee.CreateThumbImageList(const strFolder: string);
var
  lstDir      : TStringDynArray;
  I           : Integer;
  strSubFolder: String;
  lstImage    : TStringList;
begin
  { 是否有子目录，子目录下如果有图片，则建立缩略图 }
  lstDir := TDirectory.GetDirectories(strFolder);
  for I  := Low(lstDir) to High(lstDir) do
  begin
    lstImage := TStringList.Create;
    try
      strSubFolder := lstDir[I];
      if DirectoryExists(strSubFolder) then
      begin
        GetAllImage(strSubFolder, lstImage);
        if lstImage.Count > 0 then
        begin
          lstImage.DelimitedText := strSubFolder;
          CreateThumbImagePanel(lstImage, True);
        end;
      end;
    finally
      lstImage.Free;
    end;
  end;

  { 目录下是否有图片文件，有则创建图片缩略图 }
  lstImage := TStringList.Create;
  try
    GetAllImage(strFolder, lstImage);
    if lstImage.Count > 0 then
      CreateThumbImagePanel(lstImage, False);
  finally
    lstImage.Free;
  end;
end;

procedure TfrmImageSee.imgViewDblClick(Sender: TObject);
begin
  pgcSee.ActivePageIndex := 0;
  if not SameText(ExtractFilePath(imgView.Hint), shltrvwImage.Path) then
  begin
    shltrvwImage.Path := ExtractFilePath(imgView.Hint);
    Caption           := c_strimgSeeCaption + '    ' + shltrvwImage.Path;
  end;
end;

procedure TfrmImageSee.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  with TIniFile.Create(string(GetConfigFileName)) do
  begin
    WriteInteger('imgSee', 'ActiveIndex', pgcSee.ActivePageIndex);
    if pgcSee.ActivePageIndex = 0 then
      WriteString('imgSee', 'Path', shltrvwImage.Path)
    else
      WriteString('imgSee', 'Path', imgView.Hint);
    Free;
  end;
  Action := caFree;
end;

procedure TfrmImageSee.FormCreate(Sender: TObject);
begin
  InitGDIPlus;
end;

procedure TfrmImageSee.FormDestroy(Sender: TObject);
begin
  FreeGDIPlus;
end;

procedure TfrmImageSee.StretchZoom(const bmp: TBitmap; const bStretch: Boolean = True);
var
  wZoom, hZoom: Single;
begin
  if bStretch then
  begin
    imgView.Stretch  := True;
    imgView.AutoSize := False;
    wZoom            := (imgView.Parent.Width - 8) / bmp.Width;
    hZoom            := (imgView.Parent.Height - 12) / bmp.Height;
    if wZoom < hZoom then
    begin
      imgView.Width  := Round(bmp.Width * wZoom);
      imgView.Height := imgView.Width * Round(bmp.Height / bmp.Width);
    end
    else
    begin
      imgView.Height := Round(bmp.Height * hZoom);
      imgView.Width  := imgView.Height * Round(bmp.Width / bmp.Height);
    end;
    imgView.Left := (imgView.Parent.Width - imgView.Width) div 2;
    imgView.Top  := (imgView.Parent.Height - imgView.Height) div 2;
  end
  else
  begin
    imgView.Stretch  := False;
    imgView.AutoSize := True;
    if (bmp.Width > imgView.Parent.Width - 8) or (bmp.Height > imgView.Parent.Height - 8) then
    begin
      imgView.Top  := 0;
      imgView.Left := 0;
    end
    else
    begin
      imgView.Left := (imgView.Parent.Width - imgView.Width) div 2;
      imgView.Top  := (imgView.Parent.Height - imgView.Height) div 2;
    end;
  end;
end;

procedure TfrmImageSee.FirstLoadImage(const strFileName: string);
var
  bmp: TBitmap;
begin
  bmp := TBitmap.Create;
  try
    if FileExists(strFileName) then
    begin
      LoadOriImage(strFileName, bmp);
      imgView.Hint     := strFileName;
      imgView.Stretch  := FbStretch;
      imgView.AutoSize := not FbStretch;
      StretchZoom(bmp, FbStretch);
      imgView.Picture.Bitmap.Assign(bmp);
    end;
  finally
    bmp.Free;
  end;
end;

procedure TfrmImageSee.FormShow(Sender: TObject);
var
  intIndex: Integer;
  strPath : String;
  I       : Integer;
begin
  for I := 0 to pgcSee.PageCount - 1 do
  begin
    pgcSee.Pages[I].TabVisible := False;
  end;

  with TIniFile.Create(string(GetConfigFileName)) do
  begin
    FbStretch := ReadBool('imgSee', 'Stretch', True);
    intIndex  := ReadInteger('imgSee', 'ActiveIndex', 0);
    strPath   := ReadString('imgSee', 'Path', '');
    if intIndex = 0 then
    begin
      if DirectoryExists(strPath) then
      begin
        shltrvwImage.Path := strPath;
        shltrvwImageChange(Sender, nil);
      end;
      pgcSee.ActivePageIndex := 0;
    end
    else
    begin
      if (Trim(strPath) <> '') and (FileExists(strPath)) then
      begin
        FirstLoadImage(strPath);
        pgcSee.ActivePageIndex := 1;
      end
      else
      begin
        pgcSee.ActivePageIndex := 0;
      end;
    end;
    Caption := c_strimgSeeCaption + '    ' + strPath;
    Free;
  end;
end;

procedure TfrmImageSee.FormResize(Sender: TObject);
var
  I, Count: Integer;
begin
  StretchZoom(imgView.Picture.Bitmap, FbStretch);

  { 一行最多可以显示的缩略 Panel 数目 }
  Count := scrlbxSee.Width div (c_intThumbWidth + c_intXBetween);
  for I := 0 to scrlbxSee.ComponentCount - 1 do
  begin
    if scrlbxSee.Components[I] is TPanel then
    begin
      TPanel(scrlbxSee.Components[I]).Top  := c_intYBetween + (I div Count) * (c_intThumbHeight + c_intYBetween);
      TPanel(scrlbxSee.Components[I]).Left := c_intXBetween + (I mod Count) * (c_intThumbWidth + c_intXBetween);
    end;
  end;
end;

procedure TfrmImageSee.FormMouseWheel(Sender: TObject; Shift: TShiftState; WheelDelta: Integer; MousePos: TPoint; var Handled: Boolean);
var
  lstImage        : TStringList;
  strFolder       : String;
  strImageFileName: String;
begin
  // if WheelDelta < 0 then
  // scrlbxView.Perform(WM_VSCROLL, SB_LINEDOWN, 0)
  // else
  // scrlbxView.Perform(WM_VSCROLL, SB_LINEUP, 0);

  Handled          := True;
  strImageFileName := imgView.Hint;
  if pgcSee.ActivePageIndex = 1 then
  begin
    lstImage := TStringList.Create;
    try
      strFolder := ExtractFilePath(strImageFileName);
      GetAllImage(strFolder, lstImage);
      FintIndex := lstImage.IndexOf(strImageFileName);
      if WheelDelta < 0 then
      begin
        inc(FintIndex);
        if FintIndex >= lstImage.Count - 1 then
          FintIndex := lstImage.Count - 1;
      end
      else
      begin
        Dec(FintIndex);
        if FintIndex < 0 then
          FintIndex := 0;
      end;
      strImageFileName := lstImage.Strings[FintIndex];
      FirstLoadImage(strImageFileName);
      Caption := c_strimgSeeCaption + '    ' + strImageFileName;
    finally
      lstImage.Free;
    end;
  end;
end;

procedure TfrmImageSee.mniBottomImageClick(Sender: TObject);
var
  lstImage        : TStringList;
  strFolder       : String;
  strImageFileName: String;
begin
  strImageFileName := imgView.Hint;
  if not FileExists(strImageFileName) then
    Exit;

  strFolder := ExtractFilePath(strImageFileName);
  if not DirectoryExists(strFolder) then
    Exit;

  lstImage := TStringList.Create;
  try
    GetAllImage(strFolder, lstImage);
    FintIndex        := lstImage.Count - 1;
    strImageFileName := lstImage.Strings[FintIndex];
    FirstLoadImage(strImageFileName);
    Caption := c_strimgSeeCaption + '    ' + strImageFileName;
  finally
    lstImage.Free;
  end;
end;

procedure TfrmImageSee.mniFirstImageClick(Sender: TObject);
var
  lstImage        : TStringList;
  strFolder       : String;
  strImageFileName: String;
begin
  strImageFileName := imgView.Hint;
  if not FileExists(strImageFileName) then
    Exit;

  strFolder := ExtractFilePath(strImageFileName);
  if not DirectoryExists(strFolder) then
    Exit;

  lstImage := TStringList.Create;
  try
    GetAllImage(strFolder, lstImage);
    FintIndex        := 0;
    strImageFileName := lstImage.Strings[FintIndex];
    FirstLoadImage(strImageFileName);
    Caption := c_strimgSeeCaption + '    ' + strImageFileName;
  finally
    lstImage.Free;
  end;
end;

procedure TfrmImageSee.mniPirorImageClick(Sender: TObject);
var
  bHandle: Boolean;
  pt     : TPoint;
begin
  FormMouseWheel(nil, [], TMenuItem(Sender).Tag, pt, bHandle);
end;

procedure TfrmImageSee.mniSlideShowClick(Sender: TObject);
var
  strFolder       : String;
  strImageFileName: String;
begin
  strImageFileName := imgView.Hint;
  if not FileExists(strImageFileName) then
    Exit;

  strFolder := ExtractFilePath(strImageFileName);
  if not DirectoryExists(strFolder) then
    Exit;

  ShowSlideForm(strFolder);
end;

procedure TfrmImageSee.ShowSlideForm(const strFolder: string);
begin
  ShowSlideImage(strFolder);
end;

end.
