//** @abstract(The dialog shown while a model loads: a progress bar, what is happening, and
//** Abort.)
//**
//** The dialog does no loading itself. Whoever loads the model shows it, reports each step
//** with SetProgress, and closes it with Finish when the load has ended, whether it worked,
//** failed or was aborted. Abort, the Escape key, or closing the dialog's window calls
//** OnAbort once; the dialog then says it is aborting and stays open until Finish, so the
//** caller can put things back first. The dialog cannot otherwise be closed.
//**
//** On the desktop, show it with ShowModal, which returns once Finish is called; the loading
//** must be driven by something that runs while a modal dialog is up, such as a timer. On
//** Android and iOS, which cannot block, show it with ShowAndFree, and it frees itself on
//** Finish. For the main thread only.
unit Sprite3DLoadForm;

{
  The dialog shown while a model loads: a progress bar, what is happening,
  and Abort.

  The dialog does no loading itself. Whoever loads the model shows it,
  reports each step with SetProgress, and closes it with Finish when the
  load has ended, whether it worked, failed or was aborted. Abort, the
  Escape key, or closing the dialog's window calls OnAbort once; the dialog
  then says it is aborting and stays open until Finish, so the caller can
  put things back first. The dialog cannot otherwise be closed.

  On the desktop, show it with ShowModal, which returns once Finish is
  called; the loading must be driven by something that runs while a modal
  dialog is up, such as a timer. On Android and iOS, which cannot block,
  show it with ShowAndFree, and it frees itself on Finish. For the main
  thread only.
}

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs, FMX.StdCtrls,
  FMX.Controls.Presentation, FMX.Layouts;

type
  //** @abstract(The model loading dialog; see the unit description.)
  /// <summary>The model loading dialog; see the unit description.</summary>
  TModelLoadForm = class(TForm)
    //** @abstract(Holds the progress bar and the status line.)
    /// <summary>Holds the progress bar and the status line.</summary>
    MainLayout: TLayout;
    //** @abstract(How far the load has got, from 0 to 100.)
    /// <summary>How far the load has got, from 0 to 100.</summary>
    LoadProgressBar: TProgressBar;
    //** @abstract(What is happening now, under the progress bar.)
    /// <summary>What is happening now, under the progress bar.</summary>
    StatusLabel: TLabel;
    //** @abstract(The strip holding AbortButton.)
    /// <summary>The strip holding AbortButton.</summary>
    ButtonLayout: TLayout;
    //** @abstract(Asks for the load to be abandoned; also pressed by the Escape key.)
    /// <summary>Asks for the load to be abandoned; also pressed by the Escape
    /// key.</summary>
    AbortButton: TButton;
    //** @abstract(Calls OnAbort, once, and says the load is being aborted.)
    //**
    //** @param(Sender AbortButton.)
    /// <summary>Calls OnAbort, once, and says the load is being aborted.</summary>
    /// <param name="Sender">AbortButton.</param>
    procedure AbortButtonClick(Sender: TObject);
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
  private
    FOnAbort: TNotifyEvent;
    FAborted: Boolean;
    FFinished: Boolean;
    FFreeOnClose: Boolean;
    procedure RequestAbort;
  public
    //** @abstract(Names the model in the dialog's title.)
    //**
    //** @param(AModelName The model's file name, without its folder.)
    /// <summary>Names the model in the dialog's title.</summary>
    /// <param name="AModelName">The model's file name, without its folder.</param>
    procedure SetModelName(const AModelName: String);
    //** @abstract(Shows how far the load has got and what it is doing.)
    //**
    //** Ignored once Abort has been asked for, so the dialog keeps saying it is aborting.
    //**
    //** @param(AFraction How far, from 0 to 1; values outside are clamped.)
    //**
    //** @param(AStatus What is happening now, in a few words.)
    /// <summary>Shows how far the load has got and what it is doing.</summary>
    /// <remarks>Ignored once Abort has been asked for, so the dialog keeps saying it is
    /// aborting.</remarks>
    /// <param name="AFraction">How far, from 0 to 1; values outside are clamped.</param>
    /// <param name="AStatus">What is happening now, in a few words.</param>
    procedure SetProgress(const AFraction: Single; const AStatus: String);
    //** @abstract(Closes the dialog, as the load has ended.)
    //**
    //** Shown with ShowModal, ShowModal returns and the caller frees the dialog; shown with
    //** ShowAndFree, the dialog frees itself, so it must not be used afterwards.
    /// <summary>Closes the dialog, as the load has ended.</summary>
    /// <remarks>Shown with ShowModal, ShowModal returns and the caller frees the dialog; shown
    /// with ShowAndFree, the dialog frees itself, so it must not be used
    /// afterwards.</remarks>
    procedure Finish;
    //** @abstract(Shows the dialog without blocking and frees it when Finish closes it.)
    //**
    //** For Android and iOS, where ShowModal cannot block.
    /// <summary>Shows the dialog without blocking and frees it when Finish closes
    /// it.</summary>
    /// <remarks>For Android and iOS, where ShowModal cannot block.</remarks>
    procedure ShowAndFree;
    //** @abstract(True once Abort has been asked for.)
    /// <summary>True once Abort has been asked for.</summary>
    property Aborted: Boolean read FAborted;
    //** @abstract(Called once, when Abort is first asked for.)
    /// <summary>Called once, when Abort is first asked for.</summary>
    property OnAbort: TNotifyEvent read FOnAbort write FOnAbort;
  end;

implementation

{$R *.fmx}

procedure TModelLoadForm.SetModelName(const AModelName: String);
begin
  Caption := 'Loading ' + AModelName;
end;

procedure TModelLoadForm.SetProgress(const AFraction: Single; const AStatus: String);
var
  Value: Single;
begin
  if FAborted then
    Exit;
  Value := AFraction;
  if Value < 0 then
    Value := 0
  else if Value > 1 then
    Value := 1;
  LoadProgressBar.Value := LoadProgressBar.Min +
    Value * (LoadProgressBar.Max - LoadProgressBar.Min);
  StatusLabel.Text := AStatus;
end;

procedure TModelLoadForm.RequestAbort;
begin
  if FAborted or FFinished then
    Exit;
  FAborted := True;
  AbortButton.Enabled := False;
  StatusLabel.Text := 'Aborting...';
  if Assigned(FOnAbort) then
    FOnAbort(Self);
end;

procedure TModelLoadForm.AbortButtonClick(Sender: TObject);
begin
  RequestAbort;
end;

procedure TModelLoadForm.FormCloseQuery(Sender: TObject; var CanClose: Boolean);
begin
  CanClose := FFinished;
  if not CanClose then
    RequestAbort;   // the window's close box: the same as Abort
end;

procedure TModelLoadForm.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  if FFreeOnClose then
    Action := TCloseAction.caFree;
end;

procedure TModelLoadForm.Finish;
begin
  if FFinished then
    Exit;
  FFinished := True;
  if FFreeOnClose then
    Close
  else
    ModalResult := mrOk;   // ShowModal returns
end;

procedure TModelLoadForm.ShowAndFree;
begin
  FFreeOnClose := True;
  Show;
end;

end.
