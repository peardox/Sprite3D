//** @abstract(The Tools, Scan Sprites results: one row per animation scanned, in a grid.)
//**
//** Shows what TSprite3DSpriteScan holds for each folder of frames Scan Sprites read, one row
//** each, named by the folder's own name: how many frames, their size, the empty border
//** combined over every frame as an export's @code(sprite_empty) is (left, top, right and
//** bottom), the content box left once it is cropped, and the lowest, mean and highest
//** coverage, each frame's drawn pixels as a share of that box. A row whose folder could not
//** be measured says why in its Note, as does one with files that could not be read.
//**
//** Copy puts the grid on the clipboard as tab-separated text, a header line first, ready to
//** paste into a spreadsheet or a message. SpriteScanHeaders and SpriteScanCells give the
//** same columns, so the main form's Debug lines can match the grid.
//**
//** Desktop only, as Scan Sprites is: shown with ShowModal. For the main thread only.
unit Sprite3DSpriteScanForm;

{
  The Tools, Scan Sprites results: one row per animation scanned, in a grid.

  Each row is one folder of frames, named by the folder's own name: frame
  count, frame size, the empty border combined over every frame as an
  export's sprite_empty is, the content box left once it is cropped, and the
  lowest, mean and highest coverage, each frame's drawn pixels as a share of
  that box. A row that could not be measured says why in its Note.

  Copy puts the grid on the clipboard as tab-separated text.
  SpriteScanHeaders and SpriteScanCells give the same columns for the Debug
  tab. Desktop only; shown with ShowModal. Main thread only.
}

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, FMX.Types,
  FMX.Controls, FMX.Forms, FMX.Graphics, FMX.StdCtrls, FMX.Layouts,
  FMX.Controls.Presentation, FMX.Grid.Style, FMX.Grid, FMX.ScrollBox,
  Sprite3DSpriteScan;

type
  //** @abstract(The Tools, Scan Sprites results dialog; see the unit description.)
  TSpriteScanForm = class(TForm)
    //** @abstract(Says what the grid shows, above it.)
    NoteLabel: TLabel;
    //** @abstract(One row per animation; its columns are made in code, by BuildColumns.)
    Grid: TStringGrid;
    //** @abstract(The strip holding the Copy and Close buttons.)
    ButtonLayout: TLayout;
    //** @abstract(Puts the grid on the clipboard as tab-separated text.)
    CopyButton: TButton;
    //** @abstract(Closes the dialog.)
    CloseButton: TButton;
    //** @abstract(Puts the grid, with a header line, on the clipboard as tab-separated text.)
    //**
    //** @param(Sender CopyButton.)
    procedure CopyButtonClick(Sender: TObject);
    //** @abstract(Closes the dialog.)
    //**
    //** @param(Sender CloseButton.)
    procedure CloseButtonClick(Sender: TObject);
  private
    //** The scans shown, one per row, in order.
    FScans: TArray<TSprite3DSpriteScan>;
    //** @abstract(Makes the grid's columns, one per SpriteScanHeaders entry, read only.)
    procedure BuildColumns;
    //** @abstract(Fills the grid from FScans, one row each.)
    procedure Fill;
    //** @abstract(The grid as tab-separated text, a header line first.)
    //** @returns(The text, lines ending with the platform's line break.)
    function AsText: String;
  public
    //** @abstract(Makes the grid's columns.)
    //**
    //** @param(AOwner The owner, as for any form.)
    constructor Create(AOwner: TComponent); override;
    //** @abstract(Shows these scans, one row each, replacing any shown before.)
    //**
    //** @param(AScans The scans, in the order the rows are to be.)
    procedure SetScans(const AScans: TArray<TSprite3DSpriteScan>);
  end;

//** @abstract(The grid's column headings, in order.)
//** @returns(One heading per column.)
function SpriteScanHeaders: TArray<String>;

//** @abstract(One scan as the grid's cells, in the order of SpriteScanHeaders.)
//**
//** Coverage is given as a percentage to one decimal place. A scan without figures has only
//** its name, its frame count and its Note.
//**
//** @param(AScan The scan.)
//**
//** @returns(One cell per column.)
function SpriteScanCells(const AScan: TSprite3DSpriteScan): TArray<String>;

implementation

uses
  System.Math, System.Rtti, FMX.Platform;

{$R *.fmx}

const
  //** The width of each column, in the order of SpriteScanHeaders.
  COLUMN_WIDTHS: array[0..11] of Single = (140, 56, 84, 48, 48, 48, 48, 84, 96, 104, 96, 260);

function SpriteScanHeaders: TArray<String>;
begin
  Result := ['Animation', 'Frames', 'Frame size', 'Left', 'Top', 'Right', 'Bottom',
    'Content', 'Coverage min', 'Coverage mean', 'Coverage max', 'Note'];
end;

// A share from 0 to 1 as a percentage to one decimal place
function Percent(const AValue: Double): String;
begin
  Result := FormatFloat('0.0', AValue * 100) + '%';
end;

function SpriteScanCells(const AScan: TSprite3DSpriteScan): TArray<String>;
var
  Note: String;
begin
  if AScan.Valid then
  begin
    if Length(AScan.Skipped) > 0 then
      Note := Format('%d files not read; see the Debug tab', [Length(AScan.Skipped)])
    else
      Note := String.Empty;
    Result := [AScan.Name, IntToStr(Length(AScan.Frames)),
      Format('%d x %d', [AScan.Width, AScan.Height]),
      IntToStr(AScan.SpriteEmpty.Left), IntToStr(AScan.SpriteEmpty.Top),
      IntToStr(AScan.SpriteEmpty.Right), IntToStr(AScan.SpriteEmpty.Bottom),
      Format('%d x %d', [AScan.ContentWidth, AScan.ContentHeight]),
      Percent(AScan.CoverageMin), Percent(AScan.CoverageMean), Percent(AScan.CoverageMax),
      Note];
  end
  else
    Result := [AScan.Name, IntToStr(Length(AScan.Frames)), String.Empty, String.Empty,
      String.Empty, String.Empty, String.Empty, String.Empty, String.Empty, String.Empty,
      String.Empty, AScan.Error];
end;

constructor TSpriteScanForm.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  BuildColumns;
end;

procedure TSpriteScanForm.BuildColumns;
var
  Headers: TArray<String>;
  Column: TStringColumn;
  I: Integer;
begin
  Grid.Options := Grid.Options - [TGridOption.Editing] + [TGridOption.RowSelect];
  Headers := SpriteScanHeaders;
  for I := 0 to High(Headers) do
  begin
    Column := TStringColumn.Create(Grid);
    Column.Header := Headers[I];
    if I <= High(COLUMN_WIDTHS) then
      Column.Width := COLUMN_WIDTHS[I];
    Column.ReadOnly := True;
    Grid.AddObject(Column);
  end;
end;

procedure TSpriteScanForm.SetScans(const AScans: TArray<TSprite3DSpriteScan>);
begin
  FScans := AScans;
  Fill;
end;

procedure TSpriteScanForm.Fill;
var
  Row, Col: Integer;
  Cells: TArray<String>;
begin
  Grid.BeginUpdate;
  try
    Grid.RowCount := Length(FScans);
    for Row := 0 to High(FScans) do
    begin
      Cells := SpriteScanCells(FScans[Row]);
      for Col := 0 to Min(High(Cells), Grid.ColumnCount - 1) do
        Grid.Cells[Col, Row] := Cells[Col];
    end;
  finally
    Grid.EndUpdate;
  end;
  if Length(FScans) = 1 then
    Caption := 'Scan Sprites: 1 animation'
  else
    Caption := Format('Scan Sprites: %d animations', [Length(FScans)]);
end;

function TSpriteScanForm.AsText: String;
var
  Lines: TStringList;
  Scan: TSprite3DSpriteScan;
begin
  Lines := TStringList.Create;
  try
    Lines.Add(String.Join(#9, SpriteScanHeaders));
    for Scan in FScans do
      Lines.Add(String.Join(#9, SpriteScanCells(Scan)));
    Result := Lines.Text;
  finally
    Lines.Free;
  end;
end;

procedure TSpriteScanForm.CopyButtonClick(Sender: TObject);
var
  Clipboard: IFMXClipboardService;
begin
  if TPlatformServices.Current.SupportsPlatformService(IFMXClipboardService, Clipboard) then
    Clipboard.SetClipboard(TValue.From<String>(AsText));
end;

procedure TSpriteScanForm.CloseButtonClick(Sender: TObject);
begin
  ModalResult := mrClose;
end;

end.
