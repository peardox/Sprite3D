//** @abstract(The Debug, glTF, Split Long Animation dialog: one of the open model's
//** animations, cut into named frame ranges.)
//**
//** The animation is chosen from the model's, each listed with its length; the longest one
//** over 10 seconds, likely to be several joined together, is chosen to begin with. The frame
//** rate is found from its key frames (GLTFLib's TglTFAnimationSplitter.DetectFrameRate) and
//** can be changed; the label beside it gives the frames the animation runs over. Each row of
//** the grid is a range: a name, a first frame and a last frame. Add row adds one starting
//** where the last ended, Remove row takes the selected one off, and Import list... reads
//** them from a text file of the kind animation packs come with (ParseRangeList).
//**
//** Split... checks the ranges with ValidateRanges (names given and free, frames in the
//** animation, each ending after it starts) and, when the box is ticked, that each starts
//** where or after the one above ends, then closes with mrOk. The split itself is the
//** caller's job, with TglTFAnimationSplitter.Split.
//**
//** Desktop only: shown with ShowModal. For the main thread only.
unit Sprite3DGltfSplitForm;

{
  The Debug, glTF, Split Long Animation dialog: one of the open model's
  animations, cut into named frame ranges. Split... checks them and closes
  with mrOk; splitting is the caller's job. Desktop only; shown with
  ShowModal. Main thread only.
}

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, FMX.Types,
  FMX.Controls, FMX.Forms, FMX.Graphics, FMX.StdCtrls, FMX.Layouts,
  FMX.Controls.Presentation, FMX.ListBox, FMX.Edit, FMX.SpinBox, FMX.EditBox,
  FMX.Grid.Style, FMX.Grid, FMX.ScrollBox, System.Rtti,
  glTF.Classes, glTF.AnimationSplit;

type
  //** @abstract(The Debug, glTF, Split Long Animation dialog; see the unit description.)
  TGltfSplitForm = class(TForm)
    //** @abstract(Names the animation box.)
    AnimationLabel: TLabel;
    //** @abstract(The model's animations, each with its length.)
    AnimationCombo: TComboBox;
    //** @abstract(Names the frame rate box.)
    RateLabel: TLabel;
    //** @abstract(Frames per second the ranges are counted in.)
    RateBox: TSpinBox;
    //** @abstract(The frames the animation runs over, at the rate.)
    LastFrameLabel: TLabel;
    //** @abstract(Names the grid.)
    RangesLabel: TLabel;
    //** @abstract(The ranges: name, first frame, last frame.)
    RangesGrid: TStringGrid;
    //** @abstract(The ranges' names.)
    NameColumn: TStringColumn;
    //** @abstract(The ranges' first frames.)
    StartColumn: TStringColumn;
    //** @abstract(The ranges' last frames.)
    EndColumn: TStringColumn;
    //** @abstract(Adds an empty range at the end.)
    AddRowButton: TButton;
    //** @abstract(Takes the selected range off.)
    RemoveRowButton: TButton;
    //** @abstract(Reads the ranges from a text file.)
    ImportListButton: TButton;
    //** @abstract(Whether each range must start where or after the one above ends.)
    IncreasingCheck: TCheckBox;
    //** @abstract(The strip holding the Cancel and Split buttons.)
    ButtonLayout: TLayout;
    //** @abstract(Closes the dialog with mrCancel.)
    CancelButton: TButton;
    //** @abstract(Checks the ranges and closes with mrOk.)
    SplitButton: TButton;
    //** @abstract(Finds the chosen animation's frame rate and shows its frames.)
    //**
    //** @param(Sender AnimationCombo.)
    procedure AnimationComboChange(Sender: TObject);
    //** @abstract(Shows the frames at the new rate.)
    //**
    //** @param(Sender RateBox.)
    procedure RateBoxChange(Sender: TObject);
    //** @abstract(Adds a range starting where the last one ends.)
    //**
    //** @param(Sender AddRowButton.)
    procedure AddRowButtonClick(Sender: TObject);
    //** @abstract(Takes the selected range off.)
    //**
    //** @param(Sender RemoveRowButton.)
    procedure RemoveRowButtonClick(Sender: TObject);
    //** @abstract(Reads ranges from a text file, in place of the grid's.)
    //**
    //** @param(Sender ImportListButton.)
    procedure ImportListButtonClick(Sender: TObject);
    //** @abstract(Checks the ranges; closes with mrOk if they are fine, otherwise says
    //** what is wrong.)
    //**
    //** @param(Sender SplitButton.)
    procedure SplitButtonClick(Sender: TObject);
    //** @abstract(Closes the dialog with mrCancel.)
    //**
    //** @param(Sender CancelButton.)
    procedure CancelButtonClick(Sender: TObject);
  private
    //** The model's glTF tree; the caller's.
    FRoot: TglTF;
    //** The ranges Split... checked.
    FRanges: TglTFAnimationRanges;
    //** The folder Import list... opens in.
    FFolder: string;
    //** AnimationCombo's index, which is the animation's.
    function GetAnimationIndex: Integer;
    //** RateBox's value.
    function GetFrameRate: Double;
    //** The chosen animation's length in seconds; 0 when none is chosen.
    function Duration: Double;
    //** The chosen animation's last frame at the rate.
    function LastFrame: Integer;
    //** Shows the frames and seconds the animation runs over.
    procedure ShowFrames;
    //** Reads the grid's rows as ranges, skipping empty rows; False, with AProblem, when a
    //** frame is not a whole number.
    function ReadRanges(out ARanges: TglTFAnimationRanges; out AProblem: string): Boolean;
  public
    //** @abstract(Lets the grid be edited.)
    //**
    //** @param(AOwner The owner, as for any form.)
    constructor Create(AOwner: TComponent); override;
    //** @abstract(Lists the model's animations and chooses the longest likely to be several.)
    //**
    //** @param(ARoot The model's glTF tree; it must outlive the dialog.)
    //**
    //** @returns(False when the model has no animations.)
    function SetModel(const ARoot: TglTF): Boolean;
    //** @abstract(The animation chosen, as an index into the model's animations.)
    property AnimationIndex: Integer read GetAnimationIndex;
    //** @abstract(The frame rate chosen.)
    property FrameRate: Double read GetFrameRate;
    //** @abstract(The ranges, once Split... has checked them.)
    property Ranges: TglTFAnimationRanges read FRanges;
    //** @abstract(The folder Import list... opens in; set it before showing, read it after.)
    property Folder: string read FFolder write FFolder;
  end;

implementation

uses
  System.Math, System.IOUtils, FMX.Dialogs;

{$R *.fmx}

const
  COL_NAME = 0;
  COL_START = 1;
  COL_END = 2;

constructor TGltfSplitForm.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  RangesGrid.Options := RangesGrid.Options + [TGridOption.Editing,
    TGridOption.AlwaysShowEditor];
end;

function TGltfSplitForm.SetModel(const ARoot: TglTF): Boolean;
var
  I, Longest: Integer;
begin
  FRoot := ARoot;
  AnimationCombo.Clear;
  Result := (FRoot <> nil) and (FRoot.Animations.Count > 0);
  if not Result then
    Exit;
  for I := 0 to FRoot.Animations.Count - 1 do
    AnimationCombo.Items.Add(Format('%s (%.2f s)', [FRoot.Animations[I].Name,
      TglTFAnimationSplitter.Duration(FRoot, FRoot.Animations[I])]));
  Longest := TglTFAnimationSplitter.FindLongAnimation(FRoot);
  AnimationCombo.ItemIndex := Max(Longest, 0);
  AnimationComboChange(nil);
end;

function TGltfSplitForm.GetAnimationIndex: Integer;
begin
  Result := AnimationCombo.ItemIndex;
end;

function TGltfSplitForm.GetFrameRate: Double;
begin
  Result := RateBox.Value;
end;

function TGltfSplitForm.Duration: Double;
begin
  if (FRoot = nil) or (AnimationIndex < 0) then
    Exit(0);
  Result := TglTFAnimationSplitter.Duration(FRoot, FRoot.Animations[AnimationIndex]);
end;

function TGltfSplitForm.LastFrame: Integer;
begin
  Result := TglTFAnimationSplitter.LastFrame(Duration, FrameRate);
end;

procedure TGltfSplitForm.ShowFrames;
begin
  LastFrameLabel.Text := Format('Frames 0 to %d, %.2f seconds', [LastFrame, Duration]);
end;

procedure TGltfSplitForm.AnimationComboChange(Sender: TObject);
begin
  if (FRoot = nil) or (AnimationIndex < 0) then
    Exit;
  RateBox.Value := TglTFAnimationSplitter.DetectFrameRate(FRoot,
    FRoot.Animations[AnimationIndex]);
  ShowFrames;
end;

procedure TGltfSplitForm.RateBoxChange(Sender: TObject);
begin
  ShowFrames;
end;

procedure TGltfSplitForm.AddRowButtonClick(Sender: TObject);
var
  Row: Integer;
  Start: string;
begin
  Row := RangesGrid.RowCount;
  // The new range starts where the last one ends
  if Row > 0 then
    Start := RangesGrid.Cells[COL_END, Row - 1]
  else
    Start := '0';
  RangesGrid.RowCount := Row + 1;
  RangesGrid.Cells[COL_NAME, Row] := Format('part%d', [Row + 1]);
  RangesGrid.Cells[COL_START, Row] := Start;
  RangesGrid.Cells[COL_END, Row] := Start;
  RangesGrid.SelectCell(COL_NAME, Row);
end;

procedure TGltfSplitForm.RemoveRowButtonClick(Sender: TObject);
var
  Row, R, C: Integer;
begin
  Row := RangesGrid.Row;
  if (Row < 0) or (Row >= RangesGrid.RowCount) then
    Exit;
  // A grid has no row deletion: the rows below move up one
  for R := Row to RangesGrid.RowCount - 2 do
    for C := 0 to RangesGrid.ColumnCount - 1 do
      RangesGrid.Cells[C, R] := RangesGrid.Cells[C, R + 1];
  RangesGrid.RowCount := RangesGrid.RowCount - 1;
end;

procedure TGltfSplitForm.ImportListButtonClick(Sender: TObject);
var
  Dialog: TOpenDialog;
  List: TglTFRangeList;
  I: Integer;
begin
  Dialog := TOpenDialog.Create(nil);
  try
    Dialog.Title := 'Split Long Animation: choose a list of ranges';
    Dialog.Filter := 'Text files (*.txt)|*.txt|All files|*.*';
    Dialog.Options := Dialog.Options + [TOpenOption.ofFileMustExist];
    if (FFolder <> '') and DirectoryExists(FFolder) then
      Dialog.InitialDir := FFolder;
    if not Dialog.Execute then
      Exit;
    FFolder := ExtractFileDir(Dialog.FileName);
    if not TglTFAnimationSplitter.ParseRangeList(TFile.ReadAllText(Dialog.FileName),
      List) then
    begin
      ShowMessage('No ranges were found in ' + ExtractFileName(Dialog.FileName) + '.');
      Exit;
    end;
  finally
    Dialog.Free;
  end;
  RangesGrid.RowCount := Length(List.Ranges);
  for I := 0 to High(List.Ranges) do
  begin
    RangesGrid.Cells[COL_NAME, I] := List.Ranges[I].Name;
    RangesGrid.Cells[COL_START, I] := IntToStr(List.Ranges[I].StartFrame);
    RangesGrid.Cells[COL_END, I] := IntToStr(List.Ranges[I].EndFrame);
  end;
end;

function TGltfSplitForm.ReadRanges(out ARanges: TglTFAnimationRanges;
  out AProblem: string): Boolean;
var
  Row, StartFrame, EndFrame: Integer;
  Name: string;
begin
  ARanges := nil;
  AProblem := '';
  for Row := 0 to RangesGrid.RowCount - 1 do
  begin
    Name := RangesGrid.Cells[COL_NAME, Row].Trim;
    // A row left wholly empty is not a range
    if (Name = '') and (RangesGrid.Cells[COL_START, Row].Trim = '') and
      (RangesGrid.Cells[COL_END, Row].Trim = '') then
      Continue;
    if not TryStrToInt(RangesGrid.Cells[COL_START, Row].Trim, StartFrame) or
      not TryStrToInt(RangesGrid.Cells[COL_END, Row].Trim, EndFrame) then
    begin
      AProblem := Format('Row %d: the frames must be whole numbers.', [Row + 1]);
      Exit(False);
    end;
    ARanges := ARanges + [TglTFAnimationRange.Create(Name, StartFrame, EndFrame)];
  end;
  Result := True;
end;

procedure TGltfSplitForm.SplitButtonClick(Sender: TObject);
var
  Read: TglTFAnimationRanges;
  Problem: string;
  Problems: TArray<string>;
  Lines: TStringList;
  I: Integer;
begin
  if (FRoot = nil) or (AnimationIndex < 0) then
    Exit;
  if not ReadRanges(Read, Problem) then
  begin
    ShowMessage(Problem);
    Exit;
  end;
  Lines := TStringList.Create;
  try
    if not TglTFAnimationSplitter.ValidateRanges(FRoot, AnimationIndex, LastFrame, Read,
      Problems) then
    begin
      if Length(Read) = 0 then
        Lines.Add('Add at least one range.');
      for I := 0 to High(Problems) do
        if Problems[I] <> '' then
          Lines.Add(Format('%s: %s', [Read[I].Name, Problems[I]]));
    end;
    if IncreasingCheck.IsChecked then
      for I := 1 to High(Read) do
        if Read[I].StartFrame < Read[I - 1].EndFrame then
          Lines.Add(Format('%s starts at frame %d, before %s ends at frame %d.',
            [Read[I].Name, Read[I].StartFrame, Read[I - 1].Name, Read[I - 1].EndFrame]));
    if Lines.Count > 0 then
    begin
      ShowMessage(Lines.Text.Trim);
      Exit;
    end;
  finally
    Lines.Free;
  end;
  FRanges := Read;
  ModalResult := mrOk;
end;

procedure TGltfSplitForm.CancelButtonClick(Sender: TObject);
begin
  ModalResult := mrCancel;
end;

end.
