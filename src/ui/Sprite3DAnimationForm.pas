//** @abstract(The File, Animation dialog: the frame rate animations are saved at.)
//**
//** One slider, marked FPS, sets the frames per second that the animation list's Save as
//** sprite strip, Save as Texture Atlas and Save as AniGif, and batch Export, use, from
//** ANIMATION_FPS_MIN to ANIMATION_FPS_MAX. The number beside it shows the value as the
//** slider moves. OK accepts it and Cancel leaves the old value; keeping it in settings.json
//** is the caller's job.
//**
//** On the desktop, show it with ShowModal and read Fps afterwards; on Android and iOS, which
//** cannot block, show it with ShowAndFree, which calls OnAccept on OK, OnCancel otherwise,
//** and frees the form when it closes. For the main thread only.
unit Sprite3DAnimationForm;

{
  The File, Animation dialog: the frame rate animations are saved at.

  One slider, marked FPS, sets the frames per second that the animation
  list's Save as sprite strip, Save as Texture Atlas and Save as AniGif, and
  batch Export, use, from ANIMATION_FPS_MIN to ANIMATION_FPS_MAX. The number
  beside it shows the value as the slider moves. OK accepts it and Cancel
  leaves the old value; keeping it in settings.json is the caller's job.

  On the desktop, show it with ShowModal and read Fps afterwards; on Android
  and iOS, which cannot block, show it with ShowAndFree, which calls OnAccept
  on OK, OnCancel otherwise, and frees the form when it closes. For the main
  thread only.
}

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs, FMX.StdCtrls,
  FMX.Controls.Presentation, FMX.Layouts;

type
  //** @abstract(The File, Animation dialog; see the unit description.)
  /// <summary>The File, Animation dialog; see the unit description.</summary>
  TAnimationSettingsForm = class(TForm)
    //** @abstract(Holds the FPS row and the explanation.)
    /// <summary>Holds the FPS row and the explanation.</summary>
    MainLayout: TLayout;
    //** @abstract(The row with FpsLabel, FpsTrack and FpsValueLabel.)
    /// <summary>The row with FpsLabel, FpsTrack and FpsValueLabel.</summary>
    FpsLayout: TLayout;
    //** @abstract(The caption "FPS".)
    /// <summary>The caption "FPS".</summary>
    FpsLabel: TLabel;
    //** @abstract(The frame rate, in whole frames per second.)
    /// <summary>The frame rate, in whole frames per second.</summary>
    FpsTrack: TTrackBar;
    //** @abstract(The slider's value as a number.)
    /// <summary>The slider's value as a number.</summary>
    FpsValueLabel: TLabel;
    //** @abstract(A line explaining what the rate is used for.)
    /// <summary>A line explaining what the rate is used for.</summary>
    NoteLabel: TLabel;
    //** @abstract(The strip holding the Cancel and OK buttons.)
    /// <summary>The strip holding the Cancel and OK buttons.</summary>
    ButtonLayout: TLayout;
    //** @abstract(Closes the dialog with mrOk.)
    /// <summary>Closes the dialog with mrOk.</summary>
    OkButton: TButton;
    //** @abstract(Closes the dialog with mrCancel.)
    /// <summary>Closes the dialog with mrCancel.</summary>
    CancelButton: TButton;
    //** @abstract(Sets the slider's range and shows the starting value.)
    //**
    //** @param(Sender The form.)
    /// <summary>Sets the slider's range and shows the starting value.</summary>
    /// <param name="Sender">The form.</param>
    procedure FormCreate(Sender: TObject);
    //** @abstract(Shows the slider's value beside it.)
    //**
    //** @param(Sender FpsTrack.)
    /// <summary>Shows the slider's value beside it.</summary>
    /// <param name="Sender">FpsTrack.</param>
    procedure FpsTrackChange(Sender: TObject);
    //** @abstract(Closes the dialog with the button's ModalResult.)
    //**
    //** @param(Sender OkButton or CancelButton.)
    /// <summary>Closes the dialog with the button's ModalResult.</summary>
    /// <param name="Sender">OkButton or CancelButton.</param>
    procedure ButtonClick(Sender: TObject);
    //** @abstract(Reports OK or Cancel when shown with ShowAndFree, and frees the form then.)
    //**
    //** @param(Sender The form.)
    //**
    //** @param(Action Set to caFree when shown with ShowAndFree.)
    /// <summary>Reports OK or Cancel when shown with ShowAndFree, and frees the form
    /// then.</summary>
    /// <param name="Sender">The form.</param>
    /// <param name="Action">Set to caFree when shown with ShowAndFree.</param>
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
  private
    FOnAccept: TNotifyEvent;
    FOnCancel: TNotifyEvent;
    FFreeOnClose: Boolean;
    function GetFps: Integer;
    procedure SetFps(const Value: Integer);
  public
    //** @abstract(Shows the dialog without blocking and frees it when it closes.)
    //**
    //** For Android and iOS, where ShowModal cannot block. OnAccept is called if it closes
    //** with OK, OnCancel otherwise.
    /// <summary>Shows the dialog without blocking and frees it when it closes.</summary>
    /// <remarks>For Android and iOS, where ShowModal cannot block. OnAccept is called if it
    /// closes with OK, OnCancel otherwise.</remarks>
    procedure ShowAndFree;
    //** @abstract(The frame rate shown, in frames per second.)
    //**
    //** Set it before showing the dialog; read it after OK. Values are limited to
    //** ANIMATION_FPS_MIN to ANIMATION_FPS_MAX.
    /// <summary>The frame rate shown, in frames per second.</summary>
    /// <remarks>Set it before showing the dialog; read it after OK. Values are limited to
    /// ANIMATION_FPS_MIN to ANIMATION_FPS_MAX.</remarks>
    property Fps: Integer read GetFps write SetFps;
    //** @abstract(Called on OK when shown with ShowAndFree.)
    /// <summary>Called on OK when shown with ShowAndFree.</summary>
    property OnAccept: TNotifyEvent read FOnAccept write FOnAccept;
    //** @abstract(Called on Cancel, or any close but OK, when shown with ShowAndFree.)
    /// <summary>Called on Cancel, or any close but OK, when shown with ShowAndFree.</summary>
    property OnCancel: TNotifyEvent read FOnCancel write FOnCancel;
  end;

implementation

uses
  System.Math, Sprite3DHelpers;

{$R *.fmx}

procedure TAnimationSettingsForm.FormCreate(Sender: TObject);
begin
  FpsTrack.Min := ANIMATION_FPS_MIN;
  FpsTrack.Max := ANIMATION_FPS_MAX;
  FpsTrack.Frequency := 1;
  FpsTrack.Value := ANIMATION_FPS_DEFAULT;
  FpsTrackChange(FpsTrack);
end;

procedure TAnimationSettingsForm.FpsTrackChange(Sender: TObject);
begin
  FpsValueLabel.Text := IntToStr(GetFps);
end;

function TAnimationSettingsForm.GetFps: Integer;
begin
  Result := EnsureRange(Round(FpsTrack.Value), ANIMATION_FPS_MIN, ANIMATION_FPS_MAX);
end;

procedure TAnimationSettingsForm.SetFps(const Value: Integer);
begin
  FpsTrack.Value := EnsureRange(Value, ANIMATION_FPS_MIN, ANIMATION_FPS_MAX);
  FpsTrackChange(FpsTrack);
end;

procedure TAnimationSettingsForm.ButtonClick(Sender: TObject);
begin
  if not FFreeOnClose then
    Exit;   // ShowModal closes the dialog itself, from the button's ModalResult
  ModalResult := TButton(Sender).ModalResult;
  Close;
end;

procedure TAnimationSettingsForm.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  if not FFreeOnClose then
    Exit;
  if ModalResult = mrOk then
  begin
    if Assigned(FOnAccept) then
      FOnAccept(Self);
  end
  else if Assigned(FOnCancel) then
    FOnCancel(Self);
  Action := TCloseAction.caFree;
end;

procedure TAnimationSettingsForm.ShowAndFree;
begin
  FFreeOnClose := True;
  Show;
end;

end.
