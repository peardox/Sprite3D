//** @abstract(The Tools menu's results dialog: a grid of what a scan found, for Scan Sprites
//** and Scan Atlas alike.)
//**
//** The dialog shows a TScanTable: a caption, a note above the grid, the columns' headings
//** and widths, and the rows. SpriteScanTable makes one from a Scan Sprites scan and
//** AtlasScanTable from a Scan Atlas scan; the headers and cells functions they use are
//** public too, so the main form's Debug lines can match the grid.
//**
//** @bold(Scan Sprites): one row per folder of frames, named by the folder's own name: how
//** many frames, their size, the empty border combined over every frame as an export's
//** @code(sprite_empty) is (left, top, right and bottom), and the box left once it is
//** cropped, as a width and height. Left and Top are also that box's offset in the frame.
//** Cover is the highest coverage of any of the folder's frames: its drawn pixels as a share
//** of the box every animation shares, the least of each side over them all, which the note
//** gives.
//**
//** @bold(Scan Atlas): one row for the whole atlas: its sheets, the frames used and the
//** unused (empty) ones, the frame size, the border and box as above over every frame used,
//** the lowest, median and highest coverage of that box, and the share of the sheets a
//** perfect packing of the drawn pixels would save.
//**
//** A row that could not be measured says why in its Note. Copy puts the grid on the
//** clipboard as tab-separated text, a header line first and any footer lines last, ready to
//** paste into a spreadsheet or a message.
//**
//** Desktop only, as the Tools menu is: shown with ShowModal. For the main thread only.
unit Sprite3DSpriteScanForm;

{
  The Tools menu's results dialog: a grid of what a scan found, for Scan
  Sprites and Scan Atlas alike.

  The dialog shows a TScanTable: caption, note, headings, widths and rows.
  SpriteScanTable makes one from a Scan Sprites scan (one row per folder:
  frames, frame size, the folder's own border and the box left, as Width and
  Height at offset Left, Top; Cover, the most any frame covers of the box
  every animation shares). AtlasScanTable makes one from a Scan Atlas scan
  (one row for the atlas: sheets, frames used and unused, the border and box
  over every frame used, the lowest, median and highest coverage, and what a
  perfect packing would save).

  Copy puts the grid on the clipboard as tab-separated text. Desktop only;
  shown with ShowModal. Main thread only.
}

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, FMX.Types,
  FMX.Controls, FMX.Forms, FMX.Graphics, FMX.StdCtrls, FMX.Layouts,
  FMX.Controls.Presentation, FMX.Grid.Style, FMX.Grid, FMX.ScrollBox,
  Sprite3DSpriteScan;

type
  //** @abstract(What the results dialog shows: a grid, with a caption and a note.)
  TScanTable = record
    //** @abstract(The dialog's caption.)
    Caption: String;
    //** @abstract(The text above the grid: what it shows.)
    Note: String;
    //** @abstract(The columns' headings, in order.)
    Headers: TArray<String>;
    //** @abstract(The columns' widths in pixels, in the same order; a column with none is
    //** left at the grid's default.)
    Widths: TArray<Single>;
    //** @abstract(The rows, each one cell per heading.)
    Rows: TArray<TArray<String>>;
    //** @abstract(Lines Copy adds after the rows, such as the box every animation shares.)
    Footer: TArray<String>;
  end;

  //** @abstract(The Tools results dialog; see the unit description.)
  TSpriteScanForm = class(TForm)
    //** @abstract(The table's note, above the grid.)
    NoteLabel: TLabel;
    //** @abstract(The table's rows; its columns are made in code, by SetTable.)
    Grid: TStringGrid;
    //** @abstract(The strip holding the Copy and Close buttons.)
    ButtonLayout: TLayout;
    //** @abstract(Puts the grid on the clipboard as tab-separated text.)
    CopyButton: TButton;
    //** @abstract(Closes the dialog.)
    CloseButton: TButton;
    //** @abstract(Puts the grid, with a header line and the footer, on the clipboard as
    //** tab-separated text.)
    //**
    //** @param(Sender CopyButton.)
    procedure CopyButtonClick(Sender: TObject);
    //** @abstract(Closes the dialog.)
    //**
    //** @param(Sender CloseButton.)
    procedure CloseButtonClick(Sender: TObject);
  private
    //** The table shown.
    FTable: TScanTable;
    //** @abstract(The table as tab-separated text: a header line, the rows, then the footer.)
    //** @returns(The text, lines ending with the platform's line break.)
    function AsText: String;
  public
    //** @abstract(Shows a table: its caption and note, a read-only column for each heading,
    //** and its rows.)
    //**
    //** Call it once, before showing the dialog.
    //**
    //** @param(ATable The table.)
    procedure SetTable(const ATable: TScanTable);
  end;

//** @abstract(A table with nothing in it: every text empty, no columns, no rows.)
//**
//** The same as @code(Default@(TScanTable@)), for units where another unit's identifier
//** hides that intrinsic: Gorilla.DefTypes has an enumeration value named @code(Default).
//**
//** @returns(The empty table.)
function EmptyScanTable: TScanTable;

//** @abstract(Scan Sprites' column headings, in order.)
//** @returns(One heading per column.)
function SpriteScanHeaders: TArray<String>;

//** @abstract(One Scan Sprites folder as the grid's cells, in the order of
//** SpriteScanHeaders.)
//**
//** Cover is the highest coverage, as a percentage to one decimal place. A scan without
//** figures has only its name, its frame count and its Note.
//**
//** @param(AScan The scan.)
//**
//** @returns(One cell per column.)
function SpriteScanCells(const AScan: TSprite3DSpriteScan): TArray<String>;

//** @abstract(The box every animation shares, in a line of text: its border, offset and
//** size, as CombineSpriteScans worked it out.)
//**
//** @param(AShared What CombineSpriteScans returned.)
//**
//** @returns(The line, or its Error if it has no figures.)
function SpriteScanSharedText(const AShared: TSprite3DSpriteScan): String;

//** @abstract(Scan Sprites' results as a table: one row per folder, the shared box in the
//** note and the footer.)
//**
//** @param(AScans The folders' scans, their coverage worked out by CombineSpriteScans.)
//**
//** @param(AShared What CombineSpriteScans returned for them.)
//**
//** @returns(The table.)
function SpriteScanTable(const AScans: TArray<TSprite3DSpriteScan>;
  const AShared: TSprite3DSpriteScan): TScanTable;

//** @abstract(Scan Atlas' column headings, in order.)
//** @returns(One heading per column.)
function AtlasScanHeaders: TArray<String>;

//** @abstract(A Scan Atlas scan as the grid's cells, in the order of AtlasScanHeaders.)
//**
//** Coverage is given as percentages to one decimal place: the lowest, the median (Cover
//** mid) and the highest. A scan without figures has only its name, its sheet and frame
//** counts and its Note.
//**
//** @param(AAtlas The scan, from ScanAtlas.)
//**
//** @returns(One cell per column.)
function AtlasScanCells(const AAtlas: TSprite3DSpriteScan): TArray<String>;

//** @abstract(Scan Atlas' packing figures, in a line of text: the sheets' pixels, the
//** drawn ones and the share a perfect packing would save, then the pixels in the frames'
//** own tight boxes and the share packing those would save.)
//**
//** @param(AAtlas The scan, from ScanAtlas.)
//**
//** @returns(The line, or its Error if it has no figures.)
function AtlasScanPackingText(const AAtlas: TSprite3DSpriteScan): String;

//** @abstract(Scan Atlas' results as a table: one row for the whole atlas.)
//**
//** @param(AAtlas The scan, from ScanAtlas.)
//**
//** @returns(The table.)
function AtlasScanTable(const AAtlas: TSprite3DSpriteScan): TScanTable;

implementation

uses
  System.Math, System.Rtti, FMX.Platform;

{$R *.fmx}

const
  //** Scan Sprites' note, before the shared box's line.
  SPRITE_NOTE = 'One row per folder of frames. Left, Top, Right and Bottom are the empty ' +
    'border every frame of the folder shares, as sprite_empty is worked out; Left and Top ' +
    'are also the offset of what is left, Width by Height. Cover is the most any frame ' +
    'covers of the box every animation shares: ';
  //** Scan Atlas' note.
  ATLAS_NOTE = 'The whole atlas, every frame of every sheet. Unused frames, with nothing ' +
    'drawn in them, are counted but take no other part. Left, Top, Right and Bottom are the ' +
    'empty border every frame used shares, as sprite_empty is worked out; Left and Top are ' +
    'also the offset of what is left, Width by Height. Cover is each frame''s drawn pixels ' +
    'as a share of that box: the lowest, the median (mid) and the highest. Saving is ' +
    'the share of the sheets a perfect packing would save: every drawn pixel and nothing ' +
    'else, the limit no real packing quite reaches. Trim saving is what packing each ' +
    'frame trimmed to its own tight box would save, as a rectangle packer could.';

function EmptyScanTable: TScanTable;
begin
  Result := Default(TScanTable);
end;

// A share from 0 to 1 as a percentage to one decimal place
function Percent(const AValue: Double): String;
begin
  Result := FormatFloat('0.0', AValue * 100) + '%';
end;

function SpriteScanHeaders: TArray<String>;
begin
  Result := ['Animation', 'Frames', 'Frame size', 'Left', 'Top', 'Right', 'Bottom',
    'Width', 'Height', 'Cover', 'Note'];
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
      IntToStr(AScan.ContentWidth), IntToStr(AScan.ContentHeight),
      Percent(AScan.CoverageMax), Note];
  end
  else
    Result := [AScan.Name, IntToStr(Length(AScan.Frames)), String.Empty, String.Empty,
      String.Empty, String.Empty, String.Empty, String.Empty, String.Empty, String.Empty,
      AScan.Error];
end;

function SpriteScanSharedText(const AShared: TSprite3DSpriteScan): String;
begin
  if not AShared.Valid then
    Exit(AShared.Error);
  Result := Format('Left %d, Top %d, Right %d, Bottom %d; offset (%d, %d), %d x %d ' +
    'of the %d x %d frame.', [AShared.SpriteEmpty.Left, AShared.SpriteEmpty.Top,
    AShared.SpriteEmpty.Right, AShared.SpriteEmpty.Bottom, AShared.SpriteEmpty.Left,
    AShared.SpriteEmpty.Top, AShared.ContentWidth, AShared.ContentHeight, AShared.Width,
    AShared.Height]);
end;

function SpriteScanTable(const AScans: TArray<TSprite3DSpriteScan>;
  const AShared: TSprite3DSpriteScan): TScanTable;
var
  Scan: TSprite3DSpriteScan;
begin
  if Length(AScans) = 1 then
    Result.Caption := 'Scan Sprites: 1 animation'
  else
    Result.Caption := Format('Scan Sprites: %d animations', [Length(AScans)]);
  Result.Note := SPRITE_NOTE + SpriteScanSharedText(AShared);
  Result.Headers := SpriteScanHeaders;
  Result.Widths := [160.0, 60.0, 90.0, 56.0, 56.0, 56.0, 64.0, 60.0, 60.0, 64.0, 300.0];
  Result.Rows := nil;
  for Scan in AScans do
    Result.Rows := Result.Rows + [SpriteScanCells(Scan)];
  Result.Footer := ['Shared by every animation: ' + SpriteScanSharedText(AShared)];
end;

function AtlasScanHeaders: TArray<String>;
begin
  Result := ['Atlas', 'Sheets', 'Frames', 'Unused', 'Frame size', 'Left', 'Top', 'Right',
    'Bottom', 'Width', 'Height', 'Cover min', 'Cover mid', 'Cover max', 'Saving',
    'Trim saving', 'Note'];
end;

function AtlasScanCells(const AAtlas: TSprite3DSpriteScan): TArray<String>;
begin
  if AAtlas.Valid then
    Result := [AAtlas.Name, IntToStr(AAtlas.SheetCount), IntToStr(Length(AAtlas.Frames)),
      IntToStr(AAtlas.UnusedFrames), Format('%d x %d', [AAtlas.Width, AAtlas.Height]),
      IntToStr(AAtlas.SpriteEmpty.Left), IntToStr(AAtlas.SpriteEmpty.Top),
      IntToStr(AAtlas.SpriteEmpty.Right), IntToStr(AAtlas.SpriteEmpty.Bottom),
      IntToStr(AAtlas.ContentWidth), IntToStr(AAtlas.ContentHeight),
      Percent(AAtlas.CoverageMin), Percent(AAtlas.CoverageMedian),
      Percent(AAtlas.CoverageMax), Percent(AAtlas.PackingSaving),
      Percent(AAtlas.TrimSaving), String.Empty]
  else
    Result := [AAtlas.Name, IntToStr(AAtlas.SheetCount), IntToStr(Length(AAtlas.Frames)),
      IntToStr(AAtlas.UnusedFrames), String.Empty, String.Empty, String.Empty, String.Empty,
      String.Empty, String.Empty, String.Empty, String.Empty, String.Empty, String.Empty,
      String.Empty, String.Empty, AAtlas.Error];
end;

function AtlasScanPackingText(const AAtlas: TSprite3DSpriteScan): String;
begin
  if not AAtlas.Valid then
    Exit(AAtlas.Error);
  // Also as a square, to give a feel for the size a perfect packing would be
  Result := Format('Perfect packing: %d drawn pixels of %d in the sheets, saving %s; ' +
    'about %d x %d pixels if they could fill a square. Trimmed packing: %d pixels in the ' +
    'frames'' own boxes, saving %s; about %d x %d.', [AAtlas.ActivePixels,
    AAtlas.SheetPixels, Percent(AAtlas.PackingSaving), Ceil(Sqrt(AAtlas.ActivePixels)),
    Ceil(Sqrt(AAtlas.ActivePixels)), AAtlas.TrimmedPixels, Percent(AAtlas.TrimSaving),
    Ceil(Sqrt(AAtlas.TrimmedPixels)), Ceil(Sqrt(AAtlas.TrimmedPixels))]);
end;

function AtlasScanTable(const AAtlas: TSprite3DSpriteScan): TScanTable;
begin
  Result.Caption := 'Scan Atlas: ' + AAtlas.Name;
  Result.Note := ATLAS_NOTE;
  Result.Headers := AtlasScanHeaders;
  Result.Widths := [160.0, 56.0, 60.0, 60.0, 84.0, 48.0, 48.0, 48.0, 56.0, 56.0, 56.0, 80.0,
    80.0, 80.0, 64.0, 84.0, 200.0];
  Result.Rows := [AtlasScanCells(AAtlas)];
  Result.Footer := [AtlasScanPackingText(AAtlas)];
end;

procedure TSpriteScanForm.SetTable(const ATable: TScanTable);
var
  Column: TStringColumn;
  Row, Col: Integer;
begin
  FTable := ATable;
  Caption := ATable.Caption;
  NoteLabel.Text := ATable.Note;
  Grid.Options := Grid.Options - [TGridOption.Editing] + [TGridOption.RowSelect];
  Grid.BeginUpdate;
  try
    for Col := 0 to High(ATable.Headers) do
    begin
      Column := TStringColumn.Create(Grid);
      Column.Header := ATable.Headers[Col];
      if Col <= High(ATable.Widths) then
        Column.Width := ATable.Widths[Col];
      Column.ReadOnly := True;
      Grid.AddObject(Column);
    end;
    Grid.RowCount := Length(ATable.Rows);
    for Row := 0 to High(ATable.Rows) do
      for Col := 0 to Min(High(ATable.Rows[Row]), Grid.ColumnCount - 1) do
        Grid.Cells[Col, Row] := ATable.Rows[Row][Col];
  finally
    Grid.EndUpdate;
  end;
end;

function TSpriteScanForm.AsText: String;
var
  Lines: TStringList;
  Row: TArray<String>;
  Line: String;
begin
  Lines := TStringList.Create;
  try
    Lines.Add(String.Join(#9, FTable.Headers));
    for Row in FTable.Rows do
      Lines.Add(String.Join(#9, Row));
    for Line in FTable.Footer do
      Lines.Add(Line);
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
