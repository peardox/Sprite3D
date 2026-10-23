//** @abstract(The Model, Directions dialog: how many directions there are around the model,
//** where they point, and the order they are taken in.)
//**
//** The dialog shows a compass as a clock face: a white disc with N, E, S and W round its
//** edge, and a marker at each of the directions' positions, spread evenly round it. The
//** clock's "12 o'clock", the position the dial turns, is red; the others are black. Each
//** marker shows its direction's number, from 1, when there are 32 or fewer. In the centre
//** an arc with an arrowhead, half the diameter of the face, shows the way the numbers
//** increase when they go clockwise or anticlockwise; for any other order the centre says
//** Custom order.
//**
//** @preformatted(
//** TDirectionsForm
//** |-- FacePaintBox          the compass, drawn in FacePaintBoxPaint; clicked to order
//** |-- CountCombo            1, 2 and every multiple of 4 or 6 up to 64
//** |-- ClockwiseRadio,
//** |   AnticlockwiseRadio,
//** |   CustomRadio           the order: plain either way, or set with Change Order
//** |-- StartDial             the red position's bearing, StartText showing it
//** |-- SnapCheck             locks the dial to steps of one direction
//** `-- CancelButton, ImportButton, OrderButton, ExportButton, OkButton
//** )
//**
//** Change Order lets any order be chosen: the markers are clicked in the order wanted, and
//** each takes the next number as it is clicked; once every marker has one, that is the
//** order, shown by the Custom button. The first marker clicked becomes the red marker: if it
//** is not the red one already, the dial turns onto it at once. Clicking Change Order again
//** before the end, changing the number of directions, or choosing Clockwise or
//** Anticlockwise, abandons it and turns the dial back. Positions are counted clockwise from 0
//** at the red marker, so Order, for each direction from the first, gives the position it is
//** at: clicking E, S, W, N, SE, SW, NW and NE of eight that started with N red turns the red
//** marker to E, at 90 degrees, and gives 0, 2, 4, 6, 1, 3, 5, 7. Order can also be set,
//** say from a file, with the first direction elsewhere than the red marker: 2, 4, 6, 0, 3,
//** 5, 7, 1 with the red marker at north is the same set of bearings.
//**
//** Artwork bought or drawn elsewhere often comes with its directions in a fixed order of
//** its own, which may need setting again and again, so Export writes everything the dialog
//** holds to a JSON file, with SaveDirectionsFile, and Import reads one back, with
//** LoadDirectionsFile, into the dialog; OK then keeps it as usual. Export and Import are
//** on the desktop only, and open in Folder, which they leave at the folder last used.
//**
//** The bearing is in degrees clockwise from north, which is at the top of the face. The dial
//** sets it to any whole degree, or, with SnapCheck ticked, to a whole number of the steps
//** between directions, counted from north; StartText names it when it is on one of the 32
//** points of the compass, such as NE or NbE. The dialog only edits its own copy: set Count,
//** Start, Order and Snap before showing it and read them back after OK. On the desktop show
//** it with ShowModal; on Android and iOS, which cannot block, show it with ShowAndFree,
//** which calls OnAccept on OK and frees the form when it closes. For the main thread only.
unit Sprite3DDirectionsForm;

{
  The Model, Directions dialog: how many directions there are around the
  model, where they point, and the order they are taken in.

  The dialog shows a compass as a clock face: a white disc with N, E, S and
  W round its edge, and a marker at each of the directions' positions,
  spread evenly round it. The clock's "12 o'clock", the position the dial
  turns, is red; the others are black. Each marker shows its direction's
  number, from 1, when there are 32 or fewer. In the centre an arc with an
  arrowhead, half the diameter of the face, shows the way the numbers
  increase when they go clockwise or anticlockwise; for any other order the
  centre says Custom order.

    TDirectionsForm
    |-- FacePaintBox          the compass, drawn in FacePaintBoxPaint; clicked to order
    |-- CountCombo            1, 2 and every multiple of 4 or 6 up to 64
    |-- ClockwiseRadio,
    |   AnticlockwiseRadio,
    |   CustomRadio           the order: plain either way, or set with Change Order
    |-- StartDial             the red position's bearing, StartText showing it
    |-- SnapCheck             locks the dial to steps of one direction
    `-- CancelButton, ImportButton, OrderButton, ExportButton, OkButton

  Change Order lets any order be chosen: the markers are clicked in the
  order wanted, and each takes the next number as it is clicked; once every
  marker has one, that is the order, shown by the Custom button. The first
  marker clicked becomes the red marker: if it is not the red one already,
  the dial turns onto it at once. Clicking Change Order again before the
  end, changing the number of directions, or choosing Clockwise or
  Anticlockwise, abandons it and turns the dial back. Positions are counted
  clockwise from 0 at the red marker, so Order, for each direction from the
  first, gives the position it is at: clicking E, S, W, N, SE, SW, NW and NE
  of eight that started with N red turns the red marker to E, at 90 degrees,
  and gives 0, 2, 4, 6, 1, 3, 5, 7. Order can also be set, say from a file,
  with the first direction elsewhere than the red marker: 2, 4, 6, 0, 3, 5,
  7, 1 with the red marker at north is the same set of bearings.

  Artwork bought or drawn elsewhere often comes with its directions in a
  fixed order of its own, which may need setting again and again, so Export
  writes everything the dialog holds to a JSON file, with SaveDirectionsFile,
  and Import reads one back, with LoadDirectionsFile, into the dialog; OK
  then keeps it as usual. Export and Import are on the desktop only, and
  open in Folder, which they leave at the folder last used.

  The bearing is in degrees clockwise from north, which is at the top of the
  face. The dial sets it to any whole degree, or, with SnapCheck ticked, to a
  whole number of the steps between directions, counted from north;
  StartText names it when it is on one of the 32 points of the compass, such
  as NE or NbE. The
  dialog only edits its own copy: set Count, Start, Order and Snap before
  showing it and read them back after OK. On the desktop show it with
  ShowModal; on Android and iOS, which cannot block, show it with
  ShowAndFree, which calls OnAccept on OK and frees the form when it closes.
  For the main thread only.
}

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Math,
  System.Math.Vectors, FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.StdCtrls,
  FMX.Objects, FMX.Controls.Presentation, FMX.Layouts, FMX.ListBox, FMX.Dialogs;

type
  //** @abstract(The Model, Directions dialog; see the unit description.)
  /// <summary>The Model, Directions dialog; see the unit description.</summary>
  TDirectionsForm = class(TForm)
    //** @abstract(Where the compass is drawn, and clicked while the order is being changed.)
    /// <summary>Where the compass is drawn, and clicked while the order is being
    /// changed.</summary>
    FacePaintBox: TPaintBox;
    //** @abstract(Holds the controls to the right of the compass.)
    /// <summary>Holds the controls to the right of the compass.</summary>
    ControlsLayout: TLayout;
    //** @abstract(Names CountCombo.)
    /// <summary>Names CountCombo.</summary>
    CountLabel: TLabel;
    //** @abstract(The number of directions: one of DIRECTION_COUNTS.)
    /// <summary>The number of directions: one of DIRECTION_COUNTS.</summary>
    CountCombo: TComboBox;
    //** @abstract(Names the order radio buttons.)
    /// <summary>Names the order radio buttons.</summary>
    OrderLabel: TLabel;
    //** @abstract(Numbers the directions clockwise from the red marker.)
    /// <summary>Numbers the directions clockwise from the red marker.</summary>
    ClockwiseRadio: TRadioButton;
    //** @abstract(Numbers the directions anticlockwise from the red marker.)
    /// <summary>Numbers the directions anticlockwise from the red marker.</summary>
    AnticlockwiseRadio: TRadioButton;
    //** @abstract(Shows that the order was set with Change Order; it cannot be chosen
    //** itself.)
    /// <summary>Shows that the order was set with Change Order; it cannot be chosen
    /// itself.</summary>
    CustomRadio: TRadioButton;
    //** @abstract(Names StartDial.)
    /// <summary>Names StartDial.</summary>
    StartLabel: TLabel;
    //** @abstract(Turns the red marker to any bearing; turned so that 0 is at the top.)
    /// <summary>Turns the red marker to any bearing; turned so that 0 is at the
    /// top.</summary>
    StartDial: TArcDial;
    //** @abstract(The red marker's bearing, in degrees, with its point of the 32-point
    //** compass if it is on one.)
    /// <summary>The red marker's bearing, in degrees, with its point of the 32-point compass
    /// if it is on one.</summary>
    StartText: TLabel;
    //** @abstract(Locks StartDial to steps of one direction, counted from north.)
    /// <summary>Locks StartDial to steps of one direction, counted from north.</summary>
    SnapCheck: TCheckBox;
    //** @abstract(The strip holding the Cancel, Import, Change Order, Export and OK buttons.)
    /// <summary>The strip holding the Cancel, Import, Change Order, Export and OK
    /// buttons.</summary>
    ButtonLayout: TLayout;
    //** @abstract(Closes the dialog with mrOk.)
    /// <summary>Closes the dialog with mrOk.</summary>
    OkButton: TButton;
    //** @abstract(Starts choosing the order by clicking the markers, or abandons it.)
    /// <summary>Starts choosing the order by clicking the markers, or abandons
    /// it.</summary>
    OrderButton: TButton;
    //** @abstract(Reads a directions file into the dialog; desktop only.)
    /// <summary>Reads a directions file into the dialog; desktop only.</summary>
    ImportButton: TButton;
    //** @abstract(Writes what the dialog holds to a directions file; desktop only.)
    /// <summary>Writes what the dialog holds to a directions file; desktop only.</summary>
    ExportButton: TButton;
    //** @abstract(Closes the dialog with mrCancel, keeping none of the changes.)
    /// <summary>Closes the dialog with mrCancel, keeping none of the changes.</summary>
    CancelButton: TButton;
    //** @abstract(Fills CountCombo with DIRECTION_COUNTS and shows the defaults.)
    //**
    //** @param(Sender The form.)
    /// <summary>Fills CountCombo with DIRECTION_COUNTS and shows the defaults.</summary>
    /// <param name="Sender">The form.</param>
    procedure FormCreate(Sender: TObject);
    //** @abstract(Draws the compass: the face, N, E, S and W, the markers and their numbers,
    //** and the arrow.)
    //**
    //** @param(Sender FacePaintBox.)
    //**
    //** @param(Canvas The canvas to draw on.)
    /// <summary>Draws the compass: the face, N, E, S and W, the markers and their numbers, and
    /// the arrow.</summary>
    /// <param name="Sender">FacePaintBox.</param>
    /// <param name="Canvas">The canvas to draw on.</param>
    procedure FacePaintBoxPaint(Sender: TObject; Canvas: TCanvas);
    //** @abstract(While the order is being changed, gives the clicked marker the next
    //** number.)
    //**
    //** A click near the ring of markers picks the nearest one; one already numbered, or a
    //** click near the centre, is ignored. The first one picked becomes the red marker, the
    //** dial turning onto it. When every marker is numbered, that becomes the order.
    //**
    //** @param(Sender FacePaintBox.)
    //**
    //** @param(Button The mouse button.)
    //**
    //** @param(Shift The keys held.)
    //**
    //** @param(X Where, across the paint box.)
    //**
    //** @param(Y Where, down the paint box.)
    /// <summary>While the order is being changed, gives the clicked marker the next
    /// number.</summary>
    /// <remarks>A click near the ring of markers picks the nearest one; one already numbered,
    /// or a click near the centre, is ignored. The first one picked becomes the red marker,
    /// the dial turning onto it. When every marker is numbered, that becomes the
    /// order.</remarks>
    /// <param name="Sender">FacePaintBox.</param>
    /// <param name="Button">The mouse button.</param>
    /// <param name="Shift">The keys held.</param>
    /// <param name="X">Where, across the paint box.</param>
    /// <param name="Y">Where, down the paint box.</param>
    procedure FacePaintBoxMouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Single);
    //** @abstract(Takes the new number of directions, with the plain order, and redraws.)
    //**
    //** @param(Sender CountCombo.)
    /// <summary>Takes the new number of directions, with the plain order, and
    /// redraws.</summary>
    /// <param name="Sender">CountCombo.</param>
    procedure CountComboChange(Sender: TObject);
    //** @abstract(Takes the plain order Clockwise or Anticlockwise gives, and redraws.)
    //**
    //** @param(Sender ClockwiseRadio or AnticlockwiseRadio.)
    /// <summary>Takes the plain order Clockwise or Anticlockwise gives, and redraws.</summary>
    /// <param name="Sender">ClockwiseRadio or AnticlockwiseRadio.</param>
    procedure OrderRadioChange(Sender: TObject);
    //** @abstract(Takes the dial's bearing, to the nearest degree or step, and redraws.)
    //**
    //** @param(Sender StartDial.)
    /// <summary>Takes the dial's bearing, to the nearest degree or step, and
    /// redraws.</summary>
    /// <param name="Sender">StartDial.</param>
    procedure StartDialChange(Sender: TObject);
    //** @abstract(Locks or frees the dial; locking moves the bearing to the nearest step.)
    //**
    //** @param(Sender SnapCheck.)
    /// <summary>Locks or frees the dial; locking moves the bearing to the nearest
    /// step.</summary>
    /// <param name="Sender">SnapCheck.</param>
    procedure SnapCheckChange(Sender: TObject);
    //** @abstract(Starts choosing the order by clicking, or abandons it, keeping the order
    //** there was.)
    //**
    //** @param(Sender OrderButton.)
    /// <summary>Starts choosing the order by clicking, or abandons it, keeping the order
    /// there was.</summary>
    /// <param name="Sender">OrderButton.</param>
    procedure OrderButtonClick(Sender: TObject);
    //** @abstract(Asks for a directions file and shows what it holds.)
    //**
    //** An order only partly chosen is abandoned first. A file that cannot be read, or is
    //** not a directions file, is reported and changes nothing. Nothing is kept until OK.
    //**
    //** @param(Sender ImportButton.)
    /// <summary>Asks for a directions file and shows what it holds.</summary>
    /// <remarks>An order only partly chosen is abandoned first. A file that cannot be read, or
    /// is not a directions file, is reported and changes nothing. Nothing is kept until
    /// OK.</remarks>
    /// <param name="Sender">ImportButton.</param>
    procedure ImportButtonClick(Sender: TObject);
    //** @abstract(Asks where to write a directions file and writes what the dialog holds.)
    //**
    //** An order only partly chosen is abandoned first, so the order written is the one
    //** there was. A file that cannot be written is reported.
    //**
    //** @param(Sender ExportButton.)
    /// <summary>Asks where to write a directions file and writes what the dialog
    /// holds.</summary>
    /// <remarks>An order only partly chosen is abandoned first, so the order written is the
    /// one there was. A file that cannot be written is reported.</remarks>
    /// <param name="Sender">ExportButton.</param>
    procedure ExportButtonClick(Sender: TObject);
    //** @abstract(Closes the dialog with the button's ModalResult.)
    //**
    //** An order only partly chosen is abandoned first, so OK keeps the order there was.
    //**
    //** @param(Sender OkButton or CancelButton.)
    /// <summary>Closes the dialog with the button's ModalResult.</summary>
    /// <remarks>An order only partly chosen is abandoned first, so OK keeps the order there
    /// was.</remarks>
    /// <param name="Sender">OkButton or CancelButton.</param>
    procedure ButtonClick(Sender: TObject);
    //** @abstract(Reports OK when shown with ShowAndFree, and frees the form then.)
    //**
    //** @param(Sender The form.)
    //**
    //** @param(Action Set to caFree when shown with ShowAndFree.)
    /// <summary>Reports OK when shown with ShowAndFree, and frees the form then.</summary>
    /// <param name="Sender">The form.</param>
    /// <param name="Action">Set to caFree when shown with ShowAndFree.</param>
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
  private
    FCount: Integer;
    FStart: Single;
    FOrder: TArray<Integer>;    // each direction's position, from the first
    FSnap: Boolean;
    FPicking: Boolean;          // Change Order is under way
    FPicked: TArray<Integer>;   // the positions clicked so far, in order
    FPickStart: Single;         // the bearing before Change Order, to go back to
    FSyncing: Boolean;
    FFreeOnClose: Boolean;
    FFolder: String;
    FOnAccept: TNotifyEvent;
    procedure SetCount(const Value: Integer);
    procedure SetStart(const Value: Single);
    procedure ShowStartAt(const AValue: Single);
    procedure SetOrder(const Value: TArray<Integer>);
    procedure SetSnap(const Value: Boolean);
    function GetClockwise: Boolean;
    function Step: Single;
    function Snapped(const ABearing: Single): Single;
    function PositionAt(const AX, AY: Single): Integer;
    procedure StopPicking;
    procedure ShowOrder;
    procedure ShowStart;
  public
    //** @abstract(Shows the dialog without blocking and frees it when it closes.)
    //**
    //** For Android and iOS, where ShowModal cannot block. OnAccept is called if it closes
    //** with OK.
    /// <summary>Shows the dialog without blocking and frees it when it closes.</summary>
    /// <remarks>For Android and iOS, where ShowModal cannot block. OnAccept is called if it
    /// closes with OK.</remarks>
    procedure ShowAndFree;
    //** @abstract(The number of directions; one of DIRECTION_COUNTS.)
    //**
    //** A value that is not one of them becomes the nearest that is. Setting it gives the
    //** plain order, clockwise unless the order was plainly anticlockwise; set Order after
    //** it.
    /// <summary>The number of directions; one of DIRECTION_COUNTS.</summary>
    /// <remarks>A value that is not one of them becomes the nearest that is. Setting it gives
    /// the plain order, clockwise unless the order was plainly anticlockwise; set Order after
    /// it.</remarks>
    property Count: Integer read FCount write SetCount;
    //** @abstract(The red marker's bearing, in degrees clockwise from north.)
    //**
    //** Written values are rounded to the nearest degree, or to the nearest step if Snap is
    //** True, and wrapped into 0 up to 360. Change Order may leave it on another marker's
    //** bearing, which need not be a whole degree.
    /// <summary>The red marker's bearing, in degrees clockwise from north.</summary>
    /// <remarks>Written values are rounded to the nearest degree, or to the nearest step if
    /// Snap is True, and wrapped into 0 up to 360. Change Order may leave it on another
    /// marker's bearing, which need not be a whole degree.</remarks>
    property Start: Single read FStart write SetStart;
    //** @abstract(The order the directions are taken in: for each, from the first, its
    //** position, counted clockwise from 0 at the red marker.)
    //**
    //** A value that is not every position from 0 to Count - 1 once each is ignored, leaving
    //** the order as it was. Reading gives a copy.
    /// <summary>The order the directions are taken in: for each, from the first, its
    /// position, counted clockwise from 0 at the red marker.</summary>
    /// <remarks>A value that is not every position from 0 to Count - 1 once each is ignored,
    /// leaving the order as it was. Reading gives a copy.</remarks>
    property Order: TArray<Integer> read FOrder write SetOrder;
    //** @abstract(False only when the order is plainly anticlockwise from the red marker.)
    /// <summary>False only when the order is plainly anticlockwise from the red
    /// marker.</summary>
    property Clockwise: Boolean read GetClockwise;
    //** @abstract(Whether the dial is locked to steps of one direction, counted from north.)
    //**
    //** Setting it True moves Start to the nearest step.
    /// <summary>Whether the dial is locked to steps of one direction, counted from
    /// north.</summary>
    /// <remarks>Setting it True moves Start to the nearest step.</remarks>
    property Snap: Boolean read FSnap write SetSnap;
    //** @abstract(The folder Import and Export open in; left at the folder of the last file
    //** they used.)
    //**
    //** Empty opens wherever the system chooses. Read it back after the dialog closes,
    //** whether with OK or Cancel, to remember it.
    /// <summary>The folder Import and Export open in; left at the folder of the last file
    /// they used.</summary>
    /// <remarks>Empty opens wherever the system chooses. Read it back after the dialog
    /// closes, whether with OK or Cancel, to remember it.</remarks>
    property Folder: String read FFolder write FFolder;
    //** @abstract(Called on OK when shown with ShowAndFree.)
    /// <summary>Called on OK when shown with ShowAndFree.</summary>
    property OnAccept: TNotifyEvent read FOnAccept write FOnAccept;
  end;

implementation

uses
  Sprite3DHelpers;

{$R *.fmx}

const
  // Up to this many directions, each marker shows its number; up to the
  // first, in the larger size
  NUMBERED_MAX = 32;
  NUMBERED_LARGE = 16;
  // Room round the face for nothing to touch the paint box's edge
  FACE_MARGIN = 6;
  // Radii as fractions of the face's: where the markers run, where the
  // numbers and the letters sit, and the arrow's arc, half the diameter
  MARK_INNER = 0.70;
  MARK_OUTER = 0.86;
  NUMBER_AT = 0.60;
  LETTER_AT = 0.93;
  ARC_RADIUS = 0.5;
  // A click nearer the centre than this, as a fraction of the radius, picks
  // no marker
  PICK_INNER = 0.35;
  // How much of a turn the arc covers, and the gap it leaves
  ARC_SWEEP = 270;
  ARC_POINTS = 64;
  FIRST_COLOUR = TAlphaColors.Red;
  OTHER_COLOUR = TAlphaColors.Black;
  PICKED_COLOUR = $FF1E64C8;
  WAITING_COLOUR = $FFB0B0B0;
  ARROW_COLOUR = $FF404040;
  LETTER_COLOUR = $FF8080A0;

// The point at ARadius from ACentre on a bearing, in degrees clockwise from
// up
function OnBearing(const ACentre: TPointF; const ARadius, ADegrees: Single): TPointF;
var
  A: Single;
begin
  A := DegToRad(ADegrees);
  Result := TPointF.Create(ACentre.X + ARadius * Sin(A), ACentre.Y - ARadius * Cos(A));
end;

function SameOrder(const A, B: TArray<Integer>): Boolean;
begin
  Result := Length(A) = Length(B);
  if Result then
    for var I := 0 to High(A) do
      if A[I] <> B[I] then
        Exit(False);
end;

procedure TDirectionsForm.FormCreate(Sender: TObject);
begin
  FSyncing := True;
  try
    CountCombo.Items.Clear;
    for var N in DIRECTION_COUNTS do
      CountCombo.Items.Add(IntToStr(N));
  finally
    FSyncing := False;
  end;
  FacePaintBox.HitTest := True;
  {$IF DEFINED(ANDROID) or DEFINED(IOS)}
  // No file dialogs to choose a file with here
  ImportButton.Visible := False;
  ExportButton.Visible := False;
  {$ENDIF}
  // Shown as the defaults until the caller sets them
  SetCount(DIRECTION_COUNT_DEFAULT);
  SetStart(0);
  SetSnap(False);
end;

function TDirectionsForm.Step: Single;
begin
  Result := 360 / Max(1, FCount);
end;

// To a whole degree, or with Snap to a whole number of steps from north
function TDirectionsForm.Snapped(const ABearing: Single): Single;
begin
  if FSnap then
    Result := Wrap360(Round(Wrap360(ABearing) / Step) * Step)
  else
    Result := Wrap360(Round(ABearing));
end;

function TDirectionsForm.GetClockwise: Boolean;
begin
  Result := not ((FCount > 2) and SameOrder(FOrder, PlainDirectionOrder(FCount, False)));
end;

procedure TDirectionsForm.SetCount(const Value: Integer);
var
  WasClockwise: Boolean;
begin
  WasClockwise := (FOrder = nil) or GetClockwise;
  StopPicking;
  FCount := NearestDirectionCount(Value);
  FOrder := PlainDirectionOrder(FCount, WasClockwise);
  FSyncing := True;
  try
    CountCombo.ItemIndex := CountCombo.Items.IndexOf(IntToStr(FCount));
  finally
    FSyncing := False;
  end;
  // The steps change with the count
  if FSnap then
    SetStart(FStart);
  ShowOrder;
end;

procedure TDirectionsForm.SetOrder(const Value: TArray<Integer>);
begin
  if not IsDirectionOrder(Value, FCount) then
    Exit;
  StopPicking;
  FOrder := Copy(Value);
  ShowOrder;
end;

procedure TDirectionsForm.SetStart(const Value: Single);
begin
  ShowStartAt(Snapped(Value));
end;

// Turns the red marker to exactly this bearing, unrounded: for Change Order,
// which moves it onto another marker, whose bearing need not be a whole
// degree or step
procedure TDirectionsForm.ShowStartAt(const AValue: Single);
begin
  FStart := Wrap360(AValue);
  FSyncing := True;
  try
    // The dial is turned so 0 is at the top, and turns the other way to a
    // bearing, as the camera dials do
    StartDial.Value := Wrap360(-FStart);
  finally
    FSyncing := False;
  end;
  ShowStart;
  FacePaintBox.Repaint;
end;

procedure TDirectionsForm.SetSnap(const Value: Boolean);
begin
  FSnap := Value;
  FSyncing := True;
  try
    SnapCheck.IsChecked := Value;
  finally
    FSyncing := False;
  end;
  SetStart(FStart);
end;

// The radio buttons to match the order: plain either way, or custom
procedure TDirectionsForm.ShowOrder;
var
  Plain: Boolean;
begin
  Plain := SameOrder(FOrder, PlainDirectionOrder(FCount, True)) or
    SameOrder(FOrder, PlainDirectionOrder(FCount, False));
  FSyncing := True;
  try
    CustomRadio.Enabled := not Plain;
    if not Plain then
      CustomRadio.IsChecked := True
    else if GetClockwise then
      ClockwiseRadio.IsChecked := True
    else
      AnticlockwiseRadio.IsChecked := True;
  finally
    FSyncing := False;
  end;
  FacePaintBox.Repaint;
end;

// The bearing as text, with its compass point when it is on one
procedure TDirectionsForm.ShowStart;
var
  Point: String;
begin
  // Whole degrees as they are; a step such as 11.25 to two places
  Point := CompassPointName(FStart);
  StartText.Text := FormatFloat('0.##', FStart, TFormatSettings.Invariant) + #176;
  if Point <> String.Empty then
    StartText.Text := StartText.Text + ' ' + Point;
end;

procedure TDirectionsForm.CountComboChange(Sender: TObject);
begin
  if FSyncing or (CountCombo.ItemIndex < 0) then
    Exit;
  SetCount(StrToIntDef(CountCombo.Items[CountCombo.ItemIndex], DIRECTION_COUNT_DEFAULT));
end;

procedure TDirectionsForm.OrderRadioChange(Sender: TObject);
begin
  if FSyncing or not (Sender as TRadioButton).IsChecked then
    Exit;
  StopPicking;
  FOrder := PlainDirectionOrder(FCount, Sender = ClockwiseRadio);
  ShowOrder;
end;

procedure TDirectionsForm.StartDialChange(Sender: TObject);
begin
  if FSyncing then
    Exit;
  // Snapped, the knob jumps to the step as well
  SetStart(Wrap360(-StartDial.Value));
end;

procedure TDirectionsForm.SnapCheckChange(Sender: TObject);
begin
  if FSyncing then
    Exit;
  SetSnap(SnapCheck.IsChecked);
end;

// Abandons Change Order: the order, and the red marker's bearing if the
// first click moved it, go back to what they were
procedure TDirectionsForm.StopPicking;
begin
  if not FPicking then
    Exit;
  FPicking := False;
  FPicked := nil;
  OrderButton.Text := 'Change Order';
  if FStart <> FPickStart then
    ShowStartAt(FPickStart);
  FacePaintBox.Repaint;
end;

procedure TDirectionsForm.OrderButtonClick(Sender: TObject);
begin
  if FPicking then
  begin
    StopPicking;   // abandoned: the order stays as it was
    Exit;
  end;
  FPicking := True;
  FPicked := nil;
  FPickStart := FStart;
  OrderButton.Text := 'Stop Ordering';
  FacePaintBox.Repaint;
end;

const
  DIRECTIONS_FILTER = 'Sprite3D directions (*.json)|*.json|All files (*.*)|*.*';

procedure TDirectionsForm.ImportButtonClick(Sender: TObject);
var
  Dialog: TOpenDialog;
  NewCount: Integer;
  NewStart: Single;
  NewOrder: TArray<Integer>;
  NewSnap: Boolean;
begin
  StopPicking;
  Dialog := TOpenDialog.Create(nil);
  try
    Dialog.Title := 'Import Directions';
    Dialog.Filter := DIRECTIONS_FILTER;
    Dialog.DefaultExt := DIRECTIONS_FILE_EXTENSION.Substring(1);
    Dialog.Options := [TOpenOption.ofFileMustExist, TOpenOption.ofHideReadOnly,
      TOpenOption.ofEnableSizing];
    if (FFolder <> String.Empty) and DirectoryExists(FFolder) then
      Dialog.InitialDir := FFolder;
    if not Dialog.Execute or (Dialog.FileName = String.Empty) then
      Exit;
    FFolder := ExtractFileDir(Dialog.FileName);
    try
      LoadDirectionsFile(Dialog.FileName, NewCount, NewStart, NewOrder, NewSnap);
    except
      on E: Exception do
      begin
        ShowMessage('Can''t import ' + ExtractFileName(Dialog.FileName) + sLineBreak +
          E.Message);
        Exit;
      end;
    end;
  finally
    Dialog.Free;
  end;
  // Snap first, so the bearing is snapped to the new count's steps
  FSnap := NewSnap;
  SetCount(NewCount);
  SetSnap(NewSnap);
  SetStart(NewStart);
  SetOrder(NewOrder);
end;

procedure TDirectionsForm.ExportButtonClick(Sender: TObject);
var
  Dialog: TSaveDialog;
begin
  StopPicking;
  Dialog := TSaveDialog.Create(nil);
  try
    Dialog.Title := 'Export Directions';
    Dialog.Filter := DIRECTIONS_FILTER;
    Dialog.DefaultExt := DIRECTIONS_FILE_EXTENSION.Substring(1);
    Dialog.Options := [TOpenOption.ofOverwritePrompt, TOpenOption.ofHideReadOnly,
      TOpenOption.ofPathMustExist, TOpenOption.ofEnableSizing];
    if (FFolder <> String.Empty) and DirectoryExists(FFolder) then
      Dialog.InitialDir := FFolder;
    Dialog.FileName := Format('directions-%d', [FCount]) + DIRECTIONS_FILE_EXTENSION;
    if not Dialog.Execute or (Dialog.FileName = String.Empty) then
      Exit;
    FFolder := ExtractFileDir(Dialog.FileName);
    try
      SaveDirectionsFile(Dialog.FileName, FCount, FStart, FOrder, FSnap);
    except
      on E: Exception do
        ShowMessage('Can''t export to ' + Dialog.FileName + sLineBreak + E.Message);
    end;
  finally
    Dialog.Free;
  end;
end;

// The marker position nearest a point on the paint box, or -1 if the point
// is too near the centre or outside the face
function TDirectionsForm.PositionAt(const AX, AY: Single): Integer;
var
  Box: TRectF;
  Centre: TPointF;
  R, DX, DY, Distance, Bearing: Single;
begin
  Result := -1;
  Box := FacePaintBox.LocalRect;
  Centre := Box.CenterPoint;
  R := Min(Box.Width, Box.Height) / 2 - FACE_MARGIN;
  DX := AX - Centre.X;
  DY := AY - Centre.Y;
  Distance := Sqrt(DX * DX + DY * DY);
  if (R <= 0) or (Distance < R * PICK_INNER) or (Distance > R) then
    Exit;
  Bearing := RadToDeg(ArcTan2(DX, -DY));
  Result := Round(Wrap360(Bearing - FStart) / Step) mod FCount;
end;

procedure TDirectionsForm.FacePaintBoxMouseDown(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Single);
var
  Position: Integer;
begin
  if not FPicking or (Button <> TMouseButton.mbLeft) then
    Exit;
  Position := PositionAt(X, Y);
  if Position < 0 then
    Exit;
  for var Picked in FPicked do
    if Picked = Position then
      Exit;   // already numbered
  if (FPicked = nil) and (Position <> 0) then
  begin
    // The first direction becomes the red marker: turn the dial onto it,
    // and count the positions from there
    ShowStartAt(FStart + Position * Step);
    Position := 0;
  end;
  FPicked := FPicked + [Position];
  if Length(FPicked) = FCount then
  begin
    // Every marker has its number: that is the order
    FOrder := FPicked;
    FPicking := False;
    FPicked := nil;
    OrderButton.Text := 'Change Order';
    ShowOrder;
  end
  else
    FacePaintBox.Repaint;
end;

procedure TDirectionsForm.FacePaintBoxPaint(Sender: TObject; Canvas: TCanvas);
var
  Box: TRectF;
  Centre: TPointF;
  R, Bearing, NumberSize: Single;
  I, Position: Integer;
  Number: TArray<Integer>;   // each position's direction number, 0 for none yet
  Arc: TPathData;
  Tip, Side1, Side2: TPointF;
  Head: TPolygon;
  ArcR, EndBearing, HeadLen, Sign: Single;
  Plain: Boolean;
  Colour: TAlphaColor;

  procedure Text(const AAt: TPointF; const AText: String; const ASize: Single;
    const AColour: TAlphaColor; const AWide: Single = 2);
  var
    Cell: TRectF;
  begin
    Canvas.Font.Size := ASize;
    Canvas.Fill.Kind := TBrushKind.Solid;
    Canvas.Fill.Color := AColour;
    Cell := TRectF.Create(AAt.X - AWide * ASize, AAt.Y - ASize, AAt.X + AWide * ASize,
      AAt.Y + ASize);
    Canvas.FillText(Cell, AText, False, 1, [], TTextAlign.Center, TTextAlign.Center);
  end;

begin
  Box := FacePaintBox.LocalRect;
  Centre := Box.CenterPoint;
  R := Min(Box.Width, Box.Height) / 2 - FACE_MARGIN;
  if (R <= 0) or (FCount < 1) then
    Exit;

  // The face: white whatever the theme, so the black and red markers show
  Canvas.Fill.Kind := TBrushKind.Solid;
  Canvas.Fill.Color := TAlphaColors.White;
  Canvas.FillEllipse(TRectF.Create(Centre.X - R, Centre.Y - R, Centre.X + R, Centre.Y + R), 1);
  Canvas.Stroke.Kind := TBrushKind.Solid;
  Canvas.Stroke.Color := ARROW_COLOUR;
  Canvas.Stroke.Thickness := 2;
  Canvas.DrawEllipse(TRectF.Create(Centre.X - R, Centre.Y - R, Centre.X + R, Centre.Y + R), 1);

  // The compass points, which stay put as the directions turn
  Text(OnBearing(Centre, R * LETTER_AT, 0), 'N', 11, LETTER_COLOUR);
  Text(OnBearing(Centre, R * LETTER_AT, 90), 'E', 11, LETTER_COLOUR);
  Text(OnBearing(Centre, R * LETTER_AT, 180), 'S', 11, LETTER_COLOUR);
  Text(OnBearing(Centre, R * LETTER_AT, 270), 'W', 11, LETTER_COLOUR);

  // Each position's number: from the order, or while ordering, from the
  // clicks so far
  SetLength(Number, FCount);
  if FPicking then
    for I := 0 to High(FPicked) do
      Number[FPicked[I]] := I + 1
  else
    for I := 0 to High(FOrder) do
      if (FOrder[I] >= 0) and (FOrder[I] < FCount) then
        Number[FOrder[I]] := I + 1;
  if FCount <= NUMBERED_LARGE then
    NumberSize := 11
  else
    NumberSize := 8;

  // The markers, the red one last so it is on top
  for Position := FCount - 1 downto 0 do
  begin
    Bearing := FStart + Position * Step;
    if Position = 0 then
      Colour := FIRST_COLOUR
    else if FPicking and (Number[Position] = 0) then
      Colour := WAITING_COLOUR
    else if FPicking then
      Colour := PICKED_COLOUR
    else
      Colour := OTHER_COLOUR;
    Canvas.Stroke.Color := Colour;
    if Position = 0 then
      Canvas.Stroke.Thickness := 5
    else if FCount > NUMBERED_MAX then
      Canvas.Stroke.Thickness := 1.5
    else
      Canvas.Stroke.Thickness := 2.5;
    Canvas.DrawLine(OnBearing(Centre, R * MARK_INNER, Bearing),
      OnBearing(Centre, R * MARK_OUTER, Bearing), 1);
    if ((FCount <= NUMBERED_MAX) or FPicking) and (Number[Position] > 0) then
    begin
      if FPicking and (Position <> 0) then
        Colour := PICKED_COLOUR;
      Text(OnBearing(Centre, R * NUMBER_AT, Bearing), IntToStr(Number[Position]),
        NumberSize, Colour);
    end;
  end;

  // The centre: what to click while ordering; the arrow for a plain order;
  // otherwise a note that the order is custom
  if FPicking then
  begin
    Text(Centre, Format('Click direction %d of %d', [Length(FPicked) + 1, FCount]), 11,
      ARROW_COLOUR, 9);
    Exit;
  end;
  Plain := SameOrder(FOrder, PlainDirectionOrder(FCount, True)) or
    SameOrder(FOrder, PlainDirectionOrder(FCount, False));
  if not Plain then
  begin
    Text(Centre, 'Custom order', 11, ARROW_COLOUR, 6);
    Exit;
  end;
  if GetClockwise then
    Sign := 1
  else
    Sign := -1;

  // The arc, half the face's diameter, from just past the red marker round
  // the way the numbers go, with an arrowhead at its end
  ArcR := R * ARC_RADIUS;
  Arc := TPathData.Create;
  try
    for I := 0 to ARC_POINTS do
    begin
      Bearing := FStart + Sign * (45 + ARC_SWEEP * I / ARC_POINTS);
      if I = 0 then
        Arc.MoveTo(OnBearing(Centre, ArcR, Bearing))
      else
        Arc.LineTo(OnBearing(Centre, ArcR, Bearing));
    end;
    Canvas.Stroke.Color := ARROW_COLOUR;
    Canvas.Stroke.Thickness := 3;
    Canvas.DrawPath(Arc, 1);
  finally
    Arc.Free;
  end;
  EndBearing := FStart + Sign * (45 + ARC_SWEEP);
  HeadLen := Max(8, R * 0.12);
  Tip := OnBearing(Centre, ArcR, EndBearing + Sign * HeadLen / ArcR * 180 / Pi);
  Side1 := OnBearing(Centre, ArcR + HeadLen / 2, EndBearing);
  Side2 := OnBearing(Centre, ArcR - HeadLen / 2, EndBearing);
  SetLength(Head, 3);
  Head[0] := Tip;
  Head[1] := Side1;
  Head[2] := Side2;
  Canvas.Fill.Color := ARROW_COLOUR;
  Canvas.FillPolygon(Head, 1);
end;

procedure TDirectionsForm.ButtonClick(Sender: TObject);
begin
  StopPicking;   // a partly chosen order is not kept
  if FFreeOnClose then
  begin
    ModalResult := TButton(Sender).ModalResult;
    Close;
  end;
  // Otherwise ShowModal closes the dialog itself, from the button's ModalResult
end;

procedure TDirectionsForm.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  if not FFreeOnClose then
    Exit;   // shown with ShowModal: the caller frees it
  if (ModalResult = mrOk) and Assigned(FOnAccept) then
    FOnAccept(Self);
  Action := TCloseAction.caFree;
end;

procedure TDirectionsForm.ShowAndFree;
begin
  FFreeOnClose := True;
  Show;
end;

end.
