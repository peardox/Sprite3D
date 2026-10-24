//** @abstract(The dialog shown while a batch export runs: a progress bar, what is being
//** exported, Abort, and at the end the outcome and Close.)
//**
//** The dialog does no exporting itself. Whoever runs the export shows it, reports each step
//** with SetProgress, says how long is left with SetRemaining or SetRemainingNote, adds lines
//** worth keeping with AddLine, and calls Finish when the export has ended, whether it worked,
//** failed or was aborted. Until then Close is disabled. Abort, the Escape key, or the window's
//** close box calls OnAbort once: the export is to stop once the animation being exported is
//** saved, so the dialog says it is stopping and stays open until Finish. Finish shows the
//** outcome in the list below the bar, disables Abort and enables Close, which is then the only
//** way to close the dialog.
//**
//** On the desktop, show it with ShowModal, which returns when Close is pressed; the export
//** must be driven by something that runs while a modal dialog is up, such as queued calls
//** and timers. On Android and iOS, which cannot block, show it with ShowAndFree, and it
//** frees itself when closed, calling OnClosed first. For the main thread only.
unit Sprite3DExportForm;

{
  The dialog shown while a batch export runs: a progress bar, what is being
  exported, Abort, and at the end the outcome and Close.

  The dialog does no exporting itself. Whoever runs the export shows it,
  reports each step with SetProgress, says how long is left with
  SetRemaining or SetRemainingNote, adds lines worth keeping with AddLine,
  and calls Finish when the export has ended, whether it worked, failed or
  was aborted. Until then Close is disabled. Abort, the Escape key, or the
  window's close box calls OnAbort once: the export is to stop once the
  animation being exported is saved, so the dialog says it is stopping and
  stays open until Finish. Finish shows the outcome in the list below the
  bar, disables Abort and enables Close, which is then the only way to close
  the dialog.

  On the desktop, show it with ShowModal, which returns when Close is
  pressed; the export must be driven by something that runs while a modal
  dialog is up, such as queued calls and timers. On Android and iOS, which
  cannot block, show it with ShowAndFree, and it frees itself when closed,
  calling OnClosed first. For the main thread only.
}

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, FMX.Types,
  FMX.Controls, FMX.Forms, FMX.Graphics, FMX.StdCtrls, FMX.Controls.Presentation,
  FMX.Layouts, FMX.Memo.Types, FMX.ScrollBox, FMX.Memo;

type
  //** @abstract(The export progress dialog; see the unit description.)
  /// <summary>The export progress dialog; see the unit description.</summary>
  TExportProgressForm = class(TForm)
    //** @abstract(Holds the progress bar, the status line and the list of results.)
    /// <summary>Holds the progress bar, the status line and the list of results.</summary>
    MainLayout: TLayout;
    //** @abstract(How far the whole export has got, from 0 to 100.)
    /// <summary>How far the whole export has got, from 0 to 100.</summary>
    ExportProgressBar: TProgressBar;
    //** @abstract(The estimated time left, under the progress bar, as hours, minutes and
    //** seconds; hidden by Finish.)
    /// <summary>The estimated time left, under the progress bar, as hours, minutes and
    /// seconds; hidden by Finish.</summary>
    RemainingLabel: TLabel;
    //** @abstract(What is being exported now, under the progress bar; the outcome at the
    //** end.)
    /// <summary>What is being exported now, under the progress bar; the outcome at the
    /// end.</summary>
    StatusLabel: TLabel;
    //** @abstract(The files saved and the problems met, as they happen, and the report at
    //** the end.)
    /// <summary>The files saved and the problems met, as they happen, and the report at the
    /// end.</summary>
    ResultMemo: TMemo;
    //** @abstract(The strip holding Abort and Close.)
    /// <summary>The strip holding Abort and Close.</summary>
    ButtonLayout: TLayout;
    //** @abstract(Asks for the export to stop once the animation being exported is saved;
    //** also pressed by the Escape key.)
    /// <summary>Asks for the export to stop once the animation being exported is saved; also
    /// pressed by the Escape key.</summary>
    AbortButton: TButton;
    //** @abstract(Closes the dialog; enabled once the export has ended.)
    /// <summary>Closes the dialog; enabled once the export has ended.</summary>
    CloseButton: TButton;
    //** @abstract(Ticked, the dialog closes by itself once the export has finished without
    //** problems.)
    /// <summary>Ticked, the dialog closes by itself once the export has finished without
    /// problems.</summary>
    AutoCloseCheck: TCheckBox;
    //** @abstract(Calls OnAbort, once, and says the export is stopping.)
    //**
    //** @param(Sender AbortButton.)
    /// <summary>Calls OnAbort, once, and says the export is stopping.</summary>
    /// <param name="Sender">AbortButton.</param>
    procedure AbortButtonClick(Sender: TObject);
    //** @abstract(Closes the dialog, once the export has ended.)
    //**
    //** @param(Sender CloseButton.)
    /// <summary>Closes the dialog, once the export has ended.</summary>
    /// <param name="Sender">CloseButton.</param>
    procedure CloseButtonClick(Sender: TObject);
    //** @abstract(Lets the dialog close only after Finish; any other close is taken as
    //** Abort.)
    //**
    //** @param(Sender The form.)
    //**
    //** @param(CanClose Set to False until Finish has been called.)
    /// <summary>Lets the dialog close only after Finish; any other close is taken as
    /// Abort.</summary>
    /// <param name="Sender">The form.</param>
    /// <param name="CanClose">Set to False until Finish has been called.</param>
    procedure FormCloseQuery(Sender: TObject; var CanClose: Boolean);
    //** @abstract(Frees the form as it closes when shown with ShowAndFree.)
    //**
    //** @param(Sender The form.)
    //**
    //** @param(Action Set to caFree when shown with ShowAndFree.)
    /// <summary>Frees the form as it closes when shown with ShowAndFree.</summary>
    /// <param name="Sender">The form.</param>
    /// <param name="Action">Set to caFree when shown with ShowAndFree.</param>
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    //** @abstract(Calls OnAutoCloseChange when the user ticks or clears Autoclose.)
    //**
    //** @param(Sender AutoCloseCheck.)
    /// <summary>Calls OnAutoCloseChange when the user ticks or clears Autoclose.</summary>
    /// <param name="Sender">AutoCloseCheck.</param>
    procedure AutoCloseCheckChange(Sender: TObject);
  private
    FOnAbort: TNotifyEvent;
    FOnClosed: TNotifyEvent;
    FAborted: Boolean;
    FFinished: Boolean;
    FFreeOnClose: Boolean;
    FRemainingPass: Integer;
    FOnAutoCloseChange: TNotifyEvent;
    FSettingAutoClose: Boolean;
    procedure RequestAbort;
    procedure AutoCloseNow;
    function GetAutoClose: Boolean;
    procedure SetAutoClose(const Value: Boolean);
    function RemainingCaption: String;
  public
    //** @abstract(Shows how far the export has got and what it is doing.)
    //**
    //** Once Abort has been asked for, the status line keeps saying the export is stopping,
    //** after AStatus.
    //**
    //** @param(AFraction How far the whole export has got, from 0 to 1; values outside are
    //** clamped.)
    //**
    //** @param(AStatus What is being done now, in a few words.)
    /// <summary>Shows how far the export has got and what it is doing.</summary>
    /// <remarks>Once Abort has been asked for, the status line keeps saying the export is
    /// stopping, after AStatus.</remarks>
    /// <param name="AFraction">How far the whole export has got, from 0 to 1; values outside
    /// are clamped.</param>
    /// <param name="AStatus">What is being done now, in a few words.</param>
    procedure SetProgress(const AFraction: Single; const AStatus: String);
    //** @abstract(Adds a line to the list below the bar, such as a file saved or a problem.)
    //**
    //** @param(ALine The line; it may hold line breaks.)
    /// <summary>Adds a line to the list below the bar, such as a file saved or a
    /// problem.</summary>
    /// <param name="ALine">The line; it may hold line breaks.</param>
    procedure AddLine(const ALine: String);
    //** @abstract(Shows the estimated time left, as @code(Time remaining: about H:MM:SS).)
    //**
    //** Hours are not wrapped into days, so 30 hours show as 30:00:00. Ignored after Finish.
    //**
    //** @param(AMilliseconds The time left, in milliseconds; below 0 shows that it is still
    //** being worked out.)
    /// <summary>Shows the estimated time left, as <c>Time remaining: about
    /// H:MM:SS</c>.</summary>
    /// <remarks>Hours are not wrapped into days, so 30 hours show as 30:00:00. Ignored after
    /// Finish.</remarks>
    /// <param name="AMilliseconds">The time left, in milliseconds; below 0 shows that it is
    /// still being worked out.</param>
    procedure SetRemaining(const AMilliseconds: Int64);
    //** @abstract(Shows a note in place of the time left, for a stage that cannot be
    //** estimated.)
    //**
    //** @param(ANote The note, after @code(Time remaining:); empty clears the line.)
    /// <summary>Shows a note in place of the time left, for a stage that cannot be
    /// estimated.</summary>
    /// <param name="ANote">The note, after <c>Time remaining:</c>; empty clears the
    /// line.</param>
    procedure SetRemainingNote(const ANote: String);
    //** @abstract(Which pass of a 2-pass export the time remaining is for; 0, the default,
    //** for an export of one pass.)
    //**
    //** With a pass set, the line reads @code(Time remaining for Pass N:) and the time is
    //** for that pass alone. Setting it clears the line until the next SetRemaining. Ignored
    //** after Finish. Main thread only.
    //**
    //** @param(APass The pass, 1 or 2; 0 for an export of one pass.)
    /// <summary>Which pass of a 2-pass export the time remaining is for; 0, the default, for
    /// an export of one pass.</summary>
    /// <remarks>With a pass set, the line reads <c>Time remaining for Pass N:</c> and the
    /// time is for that pass alone. Setting it clears the line until the next
    /// SetRemaining. Ignored after Finish. Main thread only.</remarks>
    /// <param name="APass">The pass, 1 or 2; 0 for an export of one pass.</param>
    procedure SetRemainingPass(const APass: Integer);
    //** @abstract(Shows the outcome, as the export has ended, and lets the dialog be closed.)
    //**
    //** The status line shows AReport; the list gets AReport and then each of AProblems.
    //** Abort is disabled and Close enabled, and the time remaining is hidden. The bar is
    //** left where the export got to.
    //**
    //** @param(AReport What was exported, in a line or two.)
    //**
    //** @param(AProblems What went wrong, one entry each; empty if nothing did.)
    /// <summary>Shows the outcome, as the export has ended, and lets the dialog be
    /// closed.</summary>
    /// <remarks>The status line shows AReport; the list gets AReport and then each of
    /// AProblems. Abort is disabled and Close enabled, and the time remaining is hidden. The
    /// bar is left where the export got to.</remarks>
    /// <param name="AReport">What was exported, in a line or two.</param>
    /// <param name="AProblems">What went wrong, one entry each; empty if nothing
    /// did.</param>
    procedure Finish(const AReport: String; const AProblems: TArray<String>);
    //** @abstract(Shows the dialog without blocking and frees it when it is closed.)
    //**
    //** For Android and iOS, where ShowModal cannot block.
    /// <summary>Shows the dialog without blocking and frees it when it is closed.</summary>
    /// <remarks>For Android and iOS, where ShowModal cannot block.</remarks>
    procedure ShowAndFree;
    //** @abstract(True once Abort has been asked for.)
    /// <summary>True once Abort has been asked for.</summary>
    property Aborted: Boolean read FAborted;
    //** @abstract(True once Finish has been called.)
    /// <summary>True once Finish has been called.</summary>
    property Finished: Boolean read FFinished;
    //** @abstract(Called once, when Abort is first asked for.)
    /// <summary>Called once, when Abort is first asked for.</summary>
    property OnAbort: TNotifyEvent read FOnAbort write FOnAbort;
    //** @abstract(Called as the dialog closes, before ShowAndFree frees it.)
    //**
    //** For an owner keeping a reference to the dialog, to let it go.
    /// <summary>Called as the dialog closes, before ShowAndFree frees it.</summary>
    /// <remarks>For an owner keeping a reference to the dialog, to let it go.</remarks>
    property OnClosed: TNotifyEvent read FOnClosed write FOnClosed;
    //** @abstract(Whether Autoclose when done is ticked.)
    //**
    //** Ticked, Finish closes the dialog by itself, as Close would, once the export has
    //** ended, unless it was aborted or there were problems, which stay on show. Setting it
    //** does not call OnAutoCloseChange.
    /// <summary>Whether Autoclose when done is ticked.</summary>
    /// <remarks>Ticked, Finish closes the dialog by itself, as Close would, once the export
    /// has ended, unless it was aborted or there were problems, which stay on show. Setting
    /// it does not call OnAutoCloseChange.</remarks>
    property AutoClose: Boolean read GetAutoClose write SetAutoClose;
    //** @abstract(Drops a close Autoclose has queued but not yet made.)
    /// <summary>Drops a close Autoclose has queued but not yet made.</summary>
    destructor Destroy; override;
    //** @abstract(Called when the user ticks or clears Autoclose when done, so the owner can
    //** keep the choice.)
    /// <summary>Called when the user ticks or clears Autoclose when done, so the owner can
    /// keep the choice.</summary>
    property OnAutoCloseChange: TNotifyEvent read FOnAutoCloseChange write FOnAutoCloseChange;
  end;

implementation

{$R *.fmx}

const
  STOPPING = 'Stopping once the animation being exported is saved...';

procedure TExportProgressForm.SetProgress(const AFraction: Single; const AStatus: String);
var
  Value: Single;
begin
  if FFinished then
    Exit;
  Value := AFraction;
  if Value < 0 then
    Value := 0
  else if Value > 1 then
    Value := 1;
  ExportProgressBar.Value := ExportProgressBar.Min +
    Value * (ExportProgressBar.Max - ExportProgressBar.Min);
  if FAborted then
    StatusLabel.Text := AStatus + sLineBreak + STOPPING
  else
    StatusLabel.Text := AStatus;
end;

procedure TExportProgressForm.AddLine(const ALine: String);
begin
  ResultMemo.Lines.Add(ALine);
  ResultMemo.GoToTextEnd;
end;

// H:MM:SS, the hours not wrapped into days, rounded up to the second so the
// last second left shows as 0:00:01 rather than 0:00:00
function HoursMinutesSeconds(const AMilliseconds: Int64): String;
var
  Seconds: Int64;
begin
  Seconds := (AMilliseconds + 999) div 1000;
  if Seconds < 0 then
    Seconds := 0;
  Result := Format('%d:%.2d:%.2d', [Seconds div 3600, (Seconds mod 3600) div 60,
    Seconds mod 60]);
end;

procedure TExportProgressForm.SetRemaining(const AMilliseconds: Int64);
begin
  if FFinished then
    Exit;
  if AMilliseconds < 0 then
    RemainingLabel.Text := RemainingCaption + ': estimating...'
  else
    RemainingLabel.Text := RemainingCaption + ': about ' + HoursMinutesSeconds(AMilliseconds);
end;

procedure TExportProgressForm.SetRemainingNote(const ANote: String);
begin
  if FFinished then
    Exit;
  if ANote = String.Empty then
    RemainingLabel.Text := String.Empty
  else
    RemainingLabel.Text := RemainingCaption + ': ' + ANote;
end;

procedure TExportProgressForm.SetRemainingPass(const APass: Integer);
begin
  if FFinished then
    Exit;
  FRemainingPass := APass;
  RemainingLabel.Text := String.Empty;
end;

// The start of the time remaining line, naming the pass of a 2-pass export
function TExportProgressForm.RemainingCaption: String;
begin
  if FRemainingPass > 0 then
    Result := Format('Time remaining for Pass %d', [FRemainingPass])
  else
    Result := 'Time remaining';
end;

procedure TExportProgressForm.RequestAbort;
begin
  if FAborted or FFinished then
    Exit;
  FAborted := True;
  AbortButton.Enabled := False;
  StatusLabel.Text := StatusLabel.Text + sLineBreak + STOPPING;
  if Assigned(FOnAbort) then
    FOnAbort(Self);
end;

procedure TExportProgressForm.AbortButtonClick(Sender: TObject);
begin
  RequestAbort;
end;

procedure TExportProgressForm.CloseButtonClick(Sender: TObject);
begin
  if not FFinished then
    Exit;
  if FFreeOnClose then
    Close
  else
    ModalResult := mrOk;   // ShowModal returns
end;

procedure TExportProgressForm.FormCloseQuery(Sender: TObject; var CanClose: Boolean);
begin
  CanClose := FFinished;
  if not CanClose then
    RequestAbort;   // the window's close box: the same as Abort
end;

procedure TExportProgressForm.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  if Assigned(FOnClosed) then
    FOnClosed(Self);
  if FFreeOnClose then
    Action := TCloseAction.caFree;
end;

procedure TExportProgressForm.Finish(const AReport: String;
  const AProblems: TArray<String>);
begin
  if FFinished then
    Exit;
  FFinished := True;
  // The report gives the time taken instead
  RemainingLabel.Visible := False;
  StatusLabel.Text := AReport;
  ResultMemo.Lines.Add(String.Empty);
  ResultMemo.Lines.Add(AReport);
  for var Problem in AProblems do
    ResultMemo.Lines.Add(Problem);
  ResultMemo.GoToTextEnd;
  AbortButton.Enabled := False;
  AbortButton.Cancel := False;
  CloseButton.Enabled := True;
  CloseButton.Cancel := True;   // Escape now closes
  CloseButton.SetFocus;
  // Closed by itself if asked, once this has returned, unless there is
  // something to read: problems, or an export cut short
  if AutoCloseCheck.IsChecked and not FAborted and (Length(AProblems) = 0) then
    TThread.ForceQueue(nil, AutoCloseNow);
end;

destructor TExportProgressForm.Destroy;
begin
  // Closed some other way first: the queued close must not reach a freed form
  TThread.RemoveQueuedEvents(nil, AutoCloseNow);
  inherited;
end;

procedure TExportProgressForm.AutoCloseNow;
begin
  // Still wanted: it may have been cleared meanwhile
  if FFinished and AutoCloseCheck.IsChecked then
    CloseButtonClick(CloseButton);
end;

function TExportProgressForm.GetAutoClose: Boolean;
begin
  Result := AutoCloseCheck.IsChecked;
end;

procedure TExportProgressForm.SetAutoClose(const Value: Boolean);
begin
  FSettingAutoClose := True;
  try
    AutoCloseCheck.IsChecked := Value;
  finally
    FSettingAutoClose := False;
  end;
end;

procedure TExportProgressForm.AutoCloseCheckChange(Sender: TObject);
begin
  if not FSettingAutoClose and Assigned(FOnAutoCloseChange) then
    FOnAutoCloseChange(Self);
end;

procedure TExportProgressForm.ShowAndFree;
begin
  FFreeOnClose := True;
  Show;
end;

end.
