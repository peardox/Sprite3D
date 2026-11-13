//** @abstract(The Scan for Suspect Models dialog: a collection's median model size, and the
//** models far smaller or larger than it, to step through and mark good or bad. Made in code;
//** see TSuspectModelsForm.Execute.)
//**
//** A model's size is the largest of its bounding box's width, height and depth, from its
//** metadata, so nothing is loaded to measure it, and a flat tile and a cube of the same
//** width measure the same. The median model is the one whose size is the median (the
//** smaller middle one of an even count). An outlier is a model under the median divided by
//** the factor, or over it times the factor: at 5, the first, a model 5 times smaller or 5
//** times larger than the median. The factor is set with the slider. The outliers are
//** listed by size, the smallest first and the largest last, so the undersize come before
//** the oversize; one of size 0 is the smallest of all.
//**
//** Each model shown is shown in the Library's preview, through OnShowModel. Tick and Cross
//** give the model shown a verdict, good or bad, through OnVerdict, which records it; a
//** model with none is good, so Tick is down until Cross is used. The median model takes
//** no verdict.
//**
//** @preformatted(
//** TSuspectModelsForm
//** `-- BackPanel             the form's opaque background, as the theme draws a panel
//**     |-- MedianLabel, MedianButton    the median model, and a button to show it again
//**     |-- FactorLabel, FactorBar        the slider setting the factor
//**     |-- CountLabel                    how many outliers, under and over, and bad
//**     |-- the player                    First, Previous, Play, Next, Last; PositionLabel
//**     |-- ModelLabel                    the model shown: its size, against the median
//**     |-- TickButton, CrossButton, VerdictLabel
//**     `-- NoteLabel, CloseButton
//** )
//**
//** Desktop only, as the Library is: Execute shows it with ShowModal, beside the Library's
//** preview, which still draws while it is open.
unit Sprite3DBuilderSuspectForm;

{
  The Scan for Suspect Models dialog: a collection's median model size, and
  the models far smaller or larger than it, to step through and mark good or
  bad. Made in code; see TSuspectModelsForm.Execute.

  A model's size is the largest of its bounding box's width, height and
  depth, from its metadata, so nothing is loaded to measure it, and a flat
  tile and a cube of the same width measure the same. The median model is
  the one whose size is the median (the smaller middle one of an even
  count). An outlier is a model under the median divided by the factor, or
  over it times the factor: at 5, the first, a model 5 times smaller or 5
  times larger than the median. The factor is set with the slider. The
  outliers are listed by size, the smallest first and the largest last, so
  the undersize come before the oversize; one of size 0 is the smallest of
  all.

  Each model shown is shown in the Library's preview, through OnShowModel.
  Tick and Cross give the model shown a verdict, good or bad, through
  OnVerdict, which records it; a model with none is good, so Tick is down
  until Cross is used. The median model takes no verdict.

    TSuspectModelsForm
    `-- BackPanel             the form's opaque background
        |-- MedianLabel, MedianButton    the median model, and a button to show it again
        |-- FactorLabel, FactorBar        the slider setting the factor
        |-- CountLabel                    how many outliers, under and over, and bad
        |-- the player                    First, Previous, Play, Next, Last; PositionLabel
        |-- ModelLabel                    the model shown: its size, against the median
        |-- TickButton, CrossButton, VerdictLabel
        `-- NoteLabel, CloseButton

  Desktop only, as the Library is: Execute shows it with ShowModal, beside
  the Library's preview, which still draws while it is open.
}

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Math.Vectors,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.StdCtrls, FMX.Layouts, FMX.Objects,
  FMX.Graphics, FMX.Controls.Presentation;

const
  //** @abstract(The factor the dialog opens with: an outlier is 5 times smaller or 5 times
  //** larger than the median.)
  SUSPECT_DEFAULT_FACTOR = 5;
  //** @abstract(The smallest factor the slider gives.)
  SUSPECT_MIN_FACTOR = 1.5;
  //** @abstract(The largest factor the slider gives.)
  SUSPECT_MAX_FACTOR = 20;

type
  //** @abstract(A model of the collection, as the dialog measures it.)
  TSuspectModel = record
    //** @abstract(The caller's index for it, handed back to OnShowModel and OnVerdict.)
    Index: Integer;
    //** @abstract(Its name.)
    Name: String;
    //** @abstract(Its bounding box's width, height and depth, in its own units.)
    Size: TPoint3D;
    //** @abstract(True if it has been marked bad; False, the default, for good.)
    Bad: Boolean;
  end;

  //** @abstract(Shows the model with the caller's index AIndex in the preview.)
  //**
  //** @param(AIndex TSuspectModel.Index.)
  TSuspectShowEvent = procedure(const AIndex: Integer) of object;

  //** @abstract(Records the verdict ABad on the model with the caller's index AIndex.)
  //**
  //** @param(AIndex TSuspectModel.Index.)
  //**
  //** @param(ABad True for bad, False for good.)
  //**
  //** @returns(True if it was recorded.)
  TSuspectVerdictEvent = function(const AIndex: Integer; const ABad: Boolean): Boolean of
    object;

  //** @abstract(The Scan for Suspect Models dialog.) Use Execute.
  TSuspectModelsForm = class(TForm)
  private
    //** @abstract(The models measured, in the caller's order.)
    FModels: TArray<TSuspectModel>;
    //** @abstract(Each model's size: the largest of FModels' Size, by the same index.)
    FMeasures: TArray<Single>;
    //** @abstract(The median model, an index into FModels; -1 if there are none.)
    FMedian: Integer;
    //** @abstract(The outliers at the factor now set, indices into FModels, by size: the
    //** smallest first, the largest last.)
    FOutliers: TArray<Integer>;
    //** @abstract(Where the model shown is in FOutliers; -1 when it is not one, as for the
    //** median.)
    FPosition: Integer;
    //** @abstract(The model shown, an index into FModels; -1 for none.)
    FShown: Integer;
    //** @abstract(Shows a model in the preview; see TSuspectShowEvent.)
    FOnShowModel: TSuspectShowEvent;
    //** @abstract(Records a verdict; see TSuspectVerdictEvent.)
    FOnVerdict: TSuspectVerdictEvent;
    //** @abstract(Steps to the next outlier while playing.)
    FPlayTimer: TTimer;
    //** @abstract(The slider setting the factor.)
    FFactorBar: TTrackBar;
    //** @abstract(The labels the dialog keeps up to date: the factor, the counts, the place
    //** in the list, the model shown and its verdict.)
    FFactorLabel, FCountLabel, FPositionLabel, FModelLabel, FVerdictLabel: TLabel;
    //** @abstract(The player's buttons.)
    FFirstButton, FPreviousButton, FPlayButton, FNextButton, FLastButton: TButton;
    //** @abstract(Good and bad: the one down is the shown model's verdict.)
    FTickButton, FCrossButton: TButton;
    //** @abstract(The factor the slider gives.)
    //**
    //** @returns(The factor, SUSPECT_MIN_FACTOR to SUSPECT_MAX_FACTOR.)
    function Factor: Single;
    //** @abstract(A size as the dialog writes it: up to three decimals.)
    //**
    //** @param(AValue The size.)
    //**
    //** @returns(The text.)
    function SizeText(const AValue: Single): String;
    //** @abstract(How far model AModel's size is from the median's, as a factor of 1 or
    //** more either way; a model of size 0 is infinitely far.)
    //**
    //** @param(AModel An index into FModels.)
    //**
    //** @returns(The factor.)
    function Distance(const AModel: Integer): Double;
    //** @abstract(Finds the median model, FMedian.)
    procedure FindMedian;
    //** @abstract(Lists the outliers at the factor set, FOutliers, keeping the place of the
    //** model shown if it is still one, and updates the labels.)
    procedure FindOutliers;
    //** @abstract(Shows model AModel: in the preview, and in the labels and buttons.)
    //**
    //** @param(AModel An index into FModels; -1 does nothing.)
    procedure ShowModel(const AModel: Integer);
    //** @abstract(Shows the outlier at APosition in FOutliers, kept within the list.)
    //**
    //** @param(APosition The place in FOutliers.)
    procedure ShowOutlier(const APosition: Integer);
    //** @abstract(Updates the counts, the place in the list, the model's text, its verdict
    //** and which buttons can be used.)
    procedure UpdateLabels;
    //** @abstract(Stops playing, putting the Play icon back.)
    procedure StopPlaying;
    //** @abstract(Gives the model shown verdict ABad through OnVerdict, then steps to the
    //** next outlier, if there is one.)
    //**
    //** @param(ABad True for bad, False for good.)
    procedure GiveVerdict(const ABad: Boolean);
    //** @abstract(Adds a button with icon AIcon, an SVG path in a 24 by 24 box, drawn in the
    //** button's text colour, as Sprite3D's player buttons are.)
    //**
    //** @param(AParent The row it goes in, after what is there.)
    //**
    //** @param(AIcon The icon's path.)
    //**
    //** @param(AHint The button's hint.)
    //**
    //** @param(AOnClick Its click.)
    //**
    //** @returns(The button.)
    function AddIconButton(const AParent: TControl; const AIcon, AHint: String;
      const AOnClick: TNotifyEvent): TButton;
    //** @abstract(Sets a button's icon to AIcon.)
    //**
    //** @param(AButton A button AddIconButton made.)
    //**
    //** @param(AIcon The icon's path.)
    procedure SetIcon(const AButton: TButton; const AIcon: String);
    //** @abstract(Colours an icon button's icon with its text colour once it is styled, so it
    //** reads on the light and dark themes.)
    //**
    //** @param(Sender The button.)
    procedure IconButtonApplyStyle(Sender: TObject);
    //** @abstract(The factor changed: the outliers are found again.)
    //**
    //** @param(Sender FFactorBar.)
    procedure FactorBarChange(Sender: TObject);
    //** @abstract(Shows the median model again.)
    //**
    //** @param(Sender The Show median button.)
    procedure MedianButtonClick(Sender: TObject);
    //** @abstract(Shows the first outlier.)
    //**
    //** @param(Sender FFirstButton.)
    procedure FirstButtonClick(Sender: TObject);
    //** @abstract(Shows the outlier before the one shown.)
    //**
    //** @param(Sender FPreviousButton.)
    procedure PreviousButtonClick(Sender: TObject);
    //** @abstract(Starts or stops stepping through the outliers.)
    //**
    //** @param(Sender FPlayButton.)
    procedure PlayButtonClick(Sender: TObject);
    //** @abstract(Shows the outlier after the one shown.)
    //**
    //** @param(Sender FNextButton.)
    procedure NextButtonClick(Sender: TObject);
    //** @abstract(Shows the last outlier.)
    //**
    //** @param(Sender FLastButton.)
    procedure LastButtonClick(Sender: TObject);
    //** @abstract(While playing: the next outlier, stopping at the last.)
    //**
    //** @param(Sender FPlayTimer.)
    procedure PlayTimerTimer(Sender: TObject);
    //** @abstract(Marks the model shown good.)
    //**
    //** @param(Sender FTickButton.)
    procedure TickButtonClick(Sender: TObject);
    //** @abstract(Marks the model shown bad.)
    //**
    //** @param(Sender FCrossButton.)
    procedure CrossButtonClick(Sender: TObject);
    //** @abstract(Stops playing as the dialog closes.)
    //**
    //** @param(Sender The form.)
    //**
    //** @param(Action Left as it is.)
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
  public
    //** @abstract(Shows the dialog, modally, beside the Library's preview, opening on the
    //** median model.)
    //**
    //** @param(ALibrary The Library's window, which it is placed over the right of.)
    //**
    //** @param(ACollection The collection's name, for the title.)
    //**
    //** @param(AModels The models with a size, each with its verdict; changed as verdicts
    //** are given.)
    //**
    //** @param(AUnsized How many models of the collection have no size yet (no thumbnail),
    //** and are left out.)
    //**
    //** @param(AOnShowModel Shows a model in the preview.)
    //**
    //** @param(AOnVerdict Records a verdict.)
    //**
    //** @param(ASummary On return, a line for the log: the median, the factor last set, the
    //** outliers and how many are bad.)
    class procedure Execute(const ALibrary: TCommonCustomForm; const ACollection: String;
      var AModels: TArray<TSuspectModel>; const AUnsized: Integer;
      const AOnShowModel: TSuspectShowEvent; const AOnVerdict: TSuspectVerdictEvent;
      out ASummary: String);
  end;

implementation

uses
  System.Math, System.Generics.Collections, System.Generics.Defaults;

const
  //** @abstract(The space round the dialog's edge and between its rows.)
  PAD = 12;
  //** @abstract(How long Play shows each outlier, in milliseconds.)
  PLAY_INTERVAL_MS = 1500;
  //** @abstract(The First button's icon: a bar and two left-pointing triangles; the player
  //** icons are Sprite3D's, SVG paths in a 24 by 24 box.)
  ICON_FIRST = 'M5 6h2v12H5z M8 12l6-6v12z M14 12l6-6v12z';
  //** @abstract(The Previous button's icon: a left-pointing triangle and a bar.)
  ICON_PREVIOUS = 'M7 12l7-6v12z M15 6h2v12h-2z';
  //** @abstract(The Play button's icon: a right-pointing triangle.)
  ICON_PLAY = 'M8 5v14l11-7z';
  //** @abstract(The Pause icon, on the Play button while playing: two bars.)
  ICON_PAUSE = 'M6 5h4v14H6z M14 5h4v14h-4z';
  //** @abstract(The Next button's icon: a bar and a right-pointing triangle.)
  ICON_NEXT = 'M7 6h2v12H7z M10 6v12l7-6z';
  //** @abstract(The Last button's icon: two right-pointing triangles and a bar.)
  ICON_LAST = 'M4 6v12l6-6z M10 6v12l6-6z M17 6h2v12h-2z';
  //** @abstract(The Tick button's icon: a check mark.)
  ICON_TICK = 'M3 12l2-2 5 5 9-9 2 2-11 11z';
  //** @abstract(The Cross button's icon: an X.)
  ICON_CROSS = 'M5 7l2-2 5 5 5-5 2 2-5 5 5 5-2 2-5-5-5 5-2-2 5-5z';

function TSuspectModelsForm.Factor: Single;
begin
  Result := EnsureRange(FFactorBar.Value, SUSPECT_MIN_FACTOR, SUSPECT_MAX_FACTOR);
end;

function TSuspectModelsForm.SizeText(const AValue: Single): String;
begin
  Result := FormatFloat('0.###', AValue);
end;

function TSuspectModelsForm.Distance(const AModel: Integer): Double;
var
  Median, Size: Double;
begin
  Median := FMeasures[FMedian];
  Size := FMeasures[AModel];
  if (Size <= 0) or (Median <= 0) then
    Exit(Infinity);
  if Size >= Median then
    Result := Size / Median
  else
    Result := Median / Size;
end;

procedure TSuspectModelsForm.FindMedian;
var
  Order: TArray<Integer>;
begin
  FMedian := -1;
  if Length(FModels) = 0 then
    Exit;
  SetLength(Order, Length(FModels));
  for var I := 0 to High(Order) do
    Order[I] := I;
  TArray.Sort<Integer>(Order, TComparer<Integer>.Construct(
    function(const A, B: Integer): Integer
    begin
      Result := CompareValue(FMeasures[A], FMeasures[B]);
      if Result = 0 then
        Result := A - B;
    end));
  // A model, not an average of two: the smaller middle one of an even count
  FMedian := Order[High(Order) div 2];
end;

procedure TSuspectModelsForm.FindOutliers;
var
  LowLimit, HighLimit, Median: Double;
  ShownModel: Integer;
begin
  ShownModel := FShown;
  FOutliers := nil;
  if FMedian >= 0 then
  begin
    Median := FMeasures[FMedian];
    // A median of no size has nothing to be measured against: no outliers
    if Median > 0 then
    begin
      LowLimit := Median / Factor;
      HighLimit := Median * Factor;
      for var I := 0 to High(FModels) do
        if (I <> FMedian) and ((FMeasures[I] < LowLimit) or (FMeasures[I] > HighLimit)) then
          FOutliers := FOutliers + [I];
      TArray.Sort<Integer>(FOutliers, TComparer<Integer>.Construct(
        function(const A, B: Integer): Integer
        begin
          // By size, the smallest first and the largest last; models of the
          // same size in the caller's order, so the list does not shuffle as
          // the slider moves
          Result := CompareValue(FMeasures[A], FMeasures[B]);
          if Result = 0 then
            Result := A - B;
        end));
    end;
  end;
  // The model shown stays shown; its place in the new list, if it is in it
  FPosition := -1;
  for var I := 0 to High(FOutliers) do
    if FOutliers[I] = ShownModel then
      FPosition := I;
  FFactorLabel.Text := Format('Outliers: %sx smaller or %sx larger than the median',
    [FormatFloat('0.0', Factor), FormatFloat('0.0', Factor)]);
  UpdateLabels;
end;

procedure TSuspectModelsForm.ShowModel(const AModel: Integer);
begin
  if (AModel < 0) or (AModel > High(FModels)) then
    Exit;
  FShown := AModel;
  FPosition := -1;
  for var I := 0 to High(FOutliers) do
    if FOutliers[I] = AModel then
      FPosition := I;
  if Assigned(FOnShowModel) then
    FOnShowModel(FModels[AModel].Index);
  UpdateLabels;
end;

procedure TSuspectModelsForm.ShowOutlier(const APosition: Integer);
begin
  if Length(FOutliers) = 0 then
    Exit;
  ShowModel(FOutliers[EnsureRange(APosition, 0, High(FOutliers))]);
end;

procedure TSuspectModelsForm.UpdateLabels;
var
  Under, Over, Bad: Integer;
  Size: TPoint3D;
  Kind: String;
  HasOutliers, Judged: Boolean;
begin
  Under := 0;
  Over := 0;
  Bad := 0;
  for var I in FOutliers do
  begin
    if FMeasures[I] < FMeasures[FMedian] then
      Inc(Under)
    else
      Inc(Over);
    if FModels[I].Bad then
      Inc(Bad);
  end;
  if FMedian < 0 then
    FCountLabel.Text := 'No models with a size to measure'
  else if FMeasures[FMedian] <= 0 then
    FCountLabel.Text := 'The median model has no size: nothing to measure against'
  else if Length(FOutliers) = 0 then
    FCountLabel.Text := Format('No outliers among %d models', [Length(FModels)])
  else
    FCountLabel.Text := Format('%d outliers of %d models: %d undersize, %d oversize; ' +
      '%d marked bad', [Length(FOutliers), Length(FModels), Under, Over, Bad]);

  HasOutliers := Length(FOutliers) > 0;
  if FPosition >= 0 then
    FPositionLabel.Text := Format('%d of %d', [FPosition + 1, Length(FOutliers)])
  else if HasOutliers then
    FPositionLabel.Text := Format('- of %d', [Length(FOutliers)])
  else
    FPositionLabel.Text := String.Empty;
  FFirstButton.Enabled := HasOutliers;
  FPreviousButton.Enabled := HasOutliers and (FPosition <> 0);
  FPlayButton.Enabled := HasOutliers;
  FNextButton.Enabled := HasOutliers and (FPosition < High(FOutliers));
  FLastButton.Enabled := HasOutliers and (FPosition <> High(FOutliers));

  // The model shown: the median takes no verdict
  Judged := (FShown >= 0) and (FShown <> FMedian);
  if FShown < 0 then
    FModelLabel.Text := String.Empty
  else
  begin
    Size := FModels[FShown].Size;
    if FShown = FMedian then
      Kind := 'the median'
    else if IsInfinite(Distance(FShown)) then
      Kind := 'no size'
    else if FMeasures[FShown] < FMeasures[FMedian] then
      Kind := FormatFloat('0.##', Distance(FShown)) + 'x smaller than the median'
    else
      Kind := FormatFloat('0.##', Distance(FShown)) + 'x larger than the median';
    if FPosition >= 0 then
    begin
      if FMeasures[FShown] < FMeasures[FMedian] then
        Kind := Kind + ', undersize'
      else
        Kind := Kind + ', oversize';
    end
    else if Judged then
      Kind := Kind + ', not an outlier now';
    FModelLabel.Text := Format('%s: %s units (%s x %s x %s), %s', [FModels[FShown].Name,
      SizeText(FMeasures[FShown]), SizeText(Size.X), SizeText(Size.Y), SizeText(Size.Z),
      Kind]);
  end;
  FTickButton.Enabled := Judged;
  FCrossButton.Enabled := Judged;
  FTickButton.IsPressed := Judged and not FModels[FShown].Bad;
  FCrossButton.IsPressed := Judged and FModels[FShown].Bad;
  if not Judged then
    FVerdictLabel.Text := String.Empty
  else if FModels[FShown].Bad then
    FVerdictLabel.Text := 'Bad'
  else
    FVerdictLabel.Text := 'Good';
end;

procedure TSuspectModelsForm.StopPlaying;
begin
  FPlayTimer.Enabled := False;
  SetIcon(FPlayButton, ICON_PLAY);
  FPlayButton.Hint := 'Step through the outliers';
end;

procedure TSuspectModelsForm.GiveVerdict(const ABad: Boolean);
begin
  if (FShown < 0) or (FShown = FMedian) then
    Exit;
  StopPlaying;
  if Assigned(FOnVerdict) and FOnVerdict(FModels[FShown].Index, ABad) then
    FModels[FShown].Bad := ABad;
  UpdateLabels;
  // On to the next to look at
  if (FPosition >= 0) and (FPosition < High(FOutliers)) then
    ShowOutlier(FPosition + 1);
end;

function TSuspectModelsForm.AddIconButton(const AParent: TControl; const AIcon,
  AHint: String; const AOnClick: TNotifyEvent): TButton;
var
  Icon: FMX.Objects.TPath;
begin
  Result := TButton.Create(Self);
  Result.Parent := AParent;
  // Left-aligned controls are ordered by their X: each goes after the last
  Result.Position.X := AParent.ChildrenCount * 1000;
  Result.Align := TAlignLayout.Left;
  Result.Width := 34;
  Result.Margins.Right := 2;
  Result.Text := String.Empty;
  Result.Hint := AHint;
  Result.ShowHint := True;
  Result.OnClick := AOnClick;
  Result.OnApplyStyleLookup := IconButtonApplyStyle;
  Icon := FMX.Objects.TPath.Create(Self);
  Icon.Parent := Result;
  Icon.Align := TAlignLayout.Center;
  Icon.Width := 24;
  Icon.Height := 24;
  Icon.WrapMode := TPathWrapMode.Original;
  Icon.Data.Data := AIcon;
  Icon.Stroke.Kind := TBrushKind.None;
  Icon.Fill.Color := TAlphaColors.Black;   // the theme's colour once styled
  Icon.HitTest := False;
  Result.TagObject := Icon;
end;

procedure TSuspectModelsForm.SetIcon(const AButton: TButton; const AIcon: String);
begin
  if AButton.TagObject is FMX.Objects.TPath then
    FMX.Objects.TPath(AButton.TagObject).Data.Data := AIcon;
end;

procedure TSuspectModelsForm.IconButtonApplyStyle(Sender: TObject);
var
  Button: TButton;
begin
  Button := Sender as TButton;
  if Button.TagObject is FMX.Objects.TPath then
    FMX.Objects.TPath(Button.TagObject).Fill.Color := Button.ResultingTextSettings.FontColor;
end;

procedure TSuspectModelsForm.FactorBarChange(Sender: TObject);
begin
  FindOutliers;
end;

procedure TSuspectModelsForm.MedianButtonClick(Sender: TObject);
begin
  StopPlaying;
  ShowModel(FMedian);
end;

procedure TSuspectModelsForm.FirstButtonClick(Sender: TObject);
begin
  StopPlaying;
  ShowOutlier(0);
end;

procedure TSuspectModelsForm.PreviousButtonClick(Sender: TObject);
begin
  StopPlaying;
  // From the median, or a model no longer an outlier: the last
  if FPosition < 0 then
    ShowOutlier(High(FOutliers))
  else
    ShowOutlier(FPosition - 1);
end;

procedure TSuspectModelsForm.PlayButtonClick(Sender: TObject);
begin
  if FPlayTimer.Enabled then
  begin
    StopPlaying;
    Exit;
  end;
  if Length(FOutliers) = 0 then
    Exit;
  // From the start if at the end, or not on the list
  if (FPosition < 0) or (FPosition >= High(FOutliers)) then
    ShowOutlier(0);
  SetIcon(FPlayButton, ICON_PAUSE);
  FPlayButton.Hint := 'Stop stepping';
  FPlayTimer.Enabled := True;
end;

procedure TSuspectModelsForm.NextButtonClick(Sender: TObject);
begin
  StopPlaying;
  ShowOutlier(FPosition + 1);
end;

procedure TSuspectModelsForm.LastButtonClick(Sender: TObject);
begin
  StopPlaying;
  ShowOutlier(High(FOutliers));
end;

procedure TSuspectModelsForm.PlayTimerTimer(Sender: TObject);
begin
  if (FPosition < 0) or (FPosition >= High(FOutliers)) then
  begin
    StopPlaying;
    Exit;
  end;
  ShowOutlier(FPosition + 1);
  if FPosition >= High(FOutliers) then
    StopPlaying;
end;

procedure TSuspectModelsForm.TickButtonClick(Sender: TObject);
begin
  GiveVerdict(False);
end;

procedure TSuspectModelsForm.CrossButtonClick(Sender: TObject);
begin
  GiveVerdict(True);
end;

procedure TSuspectModelsForm.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  FPlayTimer.Enabled := False;
end;

class procedure TSuspectModelsForm.Execute(const ALibrary: TCommonCustomForm;
  const ACollection: String; var AModels: TArray<TSuspectModel>; const AUnsized: Integer;
  const AOnShowModel: TSuspectShowEvent; const AOnVerdict: TSuspectVerdictEvent;
  out ASummary: String);
var
  Form: TSuspectModelsForm;
  Back: TPanel;
  Lbl: TLabel;
  Row: TLayout;
  Btn: TButton;
  Y, W: Single;
  Bad: Integer;

  // A label across the dialog at Y, AHeight high
  function AddLabel(const AHeight: Single): TLabel;
  begin
    Result := TLabel.Create(Form);
    Result.Parent := Back;
    Result.SetBounds(PAD, Y, W, AHeight);
    Result.TextSettings.WordWrap := True;
    Y := Y + AHeight + 6;
  end;

begin
  Form := TSuspectModelsForm.CreateNew(nil);
  try
    Form.Caption := 'Suspect Models - ' + ACollection;
    Form.BorderStyle := TFmxFormBorderStyle.Single;
    Form.BorderIcons := [TBorderIcon.biSystemMenu];
    Form.ClientWidth := 520;
    Form.ClientHeight := 352;
    Form.OnClose := Form.FormClose;
    // Over the right of the Library, clear of its preview at the top left
    Form.Position := TFormPosition.Designed;
    Form.Left := ALibrary.Left + Max(0, ALibrary.Width - Form.Width - 24);
    Form.Top := ALibrary.Top + 72;

    Form.FModels := Copy(AModels);
    SetLength(Form.FMeasures, Length(Form.FModels));
    for var I := 0 to High(Form.FModels) do
      Form.FMeasures[I] := Max(Abs(Form.FModels[I].Size.X),
        Max(Abs(Form.FModels[I].Size.Y), Abs(Form.FModels[I].Size.Z)));
    Form.FOnShowModel := AOnShowModel;
    Form.FOnVerdict := AOnVerdict;
    Form.FShown := -1;
    Form.FPosition := -1;
    Form.FPlayTimer := TTimer.Create(Form);
    Form.FPlayTimer.Enabled := False;
    Form.FPlayTimer.Interval := PLAY_INTERVAL_MS;
    Form.FPlayTimer.OnTimer := Form.PlayTimerTimer;
    Form.FindMedian;

    Back := TPanel.Create(Form);
    Back.Parent := Form;
    Back.Align := TAlignLayout.Contents;
    W := Form.ClientWidth - 2 * PAD;
    Y := PAD;

    // The median, and a button to come back to it
    Lbl := AddLabel(40);
    Lbl.Width := W - 110;
    if Form.FMedian >= 0 then
      Lbl.Text := Format('Median size %s units: %s (%s x %s x %s), of %d models',
        [Form.SizeText(Form.FMeasures[Form.FMedian]), Form.FModels[Form.FMedian].Name,
        Form.SizeText(Form.FModels[Form.FMedian].Size.X),
        Form.SizeText(Form.FModels[Form.FMedian].Size.Y),
        Form.SizeText(Form.FModels[Form.FMedian].Size.Z), Length(Form.FModels)])
    else
      Lbl.Text := 'No models with a size yet';
    Btn := TButton.Create(Form);
    Btn.Parent := Back;
    Btn.SetBounds(PAD + W - 100, Lbl.Position.Y + 6, 100, 28);
    Btn.Text := 'Show Median';
    Btn.Enabled := Form.FMedian >= 0;
    Btn.OnClick := Form.MedianButtonClick;

    // The factor
    Form.FFactorLabel := AddLabel(20);
    Form.FFactorBar := TTrackBar.Create(Form);
    Form.FFactorBar.Parent := Back;
    Form.FFactorBar.SetBounds(PAD, Y, W, 24);
    Form.FFactorBar.Min := SUSPECT_MIN_FACTOR;
    Form.FFactorBar.Max := SUSPECT_MAX_FACTOR;
    Form.FFactorBar.Frequency := 0.5;
    Form.FFactorBar.Value := SUSPECT_DEFAULT_FACTOR;
    Form.FFactorBar.Tracking := True;
    Y := Y + 30;
    Form.FCountLabel := AddLabel(20);

    // The player
    Row := TLayout.Create(Form);
    Row.Parent := Back;
    Row.SetBounds(PAD, Y, W, 30);
    Form.FFirstButton := Form.AddIconButton(Row, ICON_FIRST, 'The first outlier, the ' +
      'smallest', Form.FirstButtonClick);
    Form.FPreviousButton := Form.AddIconButton(Row, ICON_PREVIOUS, 'The outlier before',
      Form.PreviousButtonClick);
    Form.FPlayButton := Form.AddIconButton(Row, ICON_PLAY, 'Step through the outliers',
      Form.PlayButtonClick);
    Form.FNextButton := Form.AddIconButton(Row, ICON_NEXT, 'The next outlier',
      Form.NextButtonClick);
    Form.FLastButton := Form.AddIconButton(Row, ICON_LAST, 'The last outlier, the ' +
      'largest', Form.LastButtonClick);
    Form.FPositionLabel := TLabel.Create(Form);
    Form.FPositionLabel.Parent := Row;
    Form.FPositionLabel.Position.X := Row.ChildrenCount * 1000;
    Form.FPositionLabel.Align := TAlignLayout.Left;
    Form.FPositionLabel.Width := 90;
    Form.FPositionLabel.Margins.Left := 8;
    Y := Y + 36;

    // The model shown, and its verdict
    Form.FModelLabel := AddLabel(40);
    Row := TLayout.Create(Form);
    Row.Parent := Back;
    Row.SetBounds(PAD, Y, W, 30);
    Form.FTickButton := Form.AddIconButton(Row, ICON_TICK, 'Good: the model is right',
      Form.TickButtonClick);
    Form.FTickButton.StaysPressed := True;
    Form.FCrossButton := Form.AddIconButton(Row, ICON_CROSS, 'Bad: the model is wrong',
      Form.CrossButtonClick);
    Form.FCrossButton.StaysPressed := True;
    Form.FVerdictLabel := TLabel.Create(Form);
    Form.FVerdictLabel.Parent := Row;
    Form.FVerdictLabel.Position.X := Row.ChildrenCount * 1000;
    Form.FVerdictLabel.Align := TAlignLayout.Left;
    Form.FVerdictLabel.Width := 120;
    Form.FVerdictLabel.Margins.Left := 8;
    Y := Y + 36;

    Lbl := AddLabel(34);
    Lbl.Text := 'A model is good unless marked bad. A size is the largest of the width, ' +
      'height and depth.';
    if AUnsized > 0 then
      Lbl.Text := Lbl.Text + Format(' %d models have no thumbnail yet, so no size, and ' +
        'are left out.', [AUnsized]);

    Btn := TButton.Create(Form);
    Btn.Parent := Back;
    Btn.SetBounds(PAD + W - 88, Form.ClientHeight - PAD - 28, 88, 28);
    Btn.Text := 'Close';
    Btn.Cancel := True;
    Btn.Default := True;
    Btn.ModalResult := mrClose;

    // Set last, so the change it makes finds every label made
    Form.FFactorBar.OnChange := Form.FactorBarChange;
    Form.FindOutliers;
    Form.ShowModel(Form.FMedian);

    Form.ShowModal;

    AModels := Copy(Form.FModels);
    Bad := 0;
    for var I in Form.FOutliers do
      if Form.FModels[I].Bad then
        Inc(Bad);
    if Form.FMedian < 0 then
      ASummary := 'no models with a size'
    else
      ASummary := Format('median %s units (%s) of %d models; at %sx, %d outliers, %d ' +
        'marked bad', [Form.SizeText(Form.FMeasures[Form.FMedian]),
        Form.FModels[Form.FMedian].Name, Length(Form.FModels),
        FormatFloat('0.0', Form.Factor), Length(Form.FOutliers), Bad]);
  finally
    Form.Free;
  end;
end;

end.
