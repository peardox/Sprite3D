//** @abstract(The Model, Animations Used dialog: which of the model's animations are used.)
//**
//** A list of the model's animations, each with a tick box, and an All tick box above it that
//** ticks or clears every one; it shows ticked only while every animation is ticked. The
//** caller fills the list with SetAnimations and, after OK, reads UsedAnimations. Cancel, or
//** closing the dialog any other way, leaves the caller's set as it was, as the dialog only
//** changes its own copy. Keeping the set, and what it is used for, is the caller's job.
//**
//** On the desktop, show it with ShowModal and read UsedAnimations afterwards; on Android and
//** iOS, which cannot block, show it with ShowAndFree, which calls OnAccept on OK, OnCancel
//** otherwise, and frees the form when it closes. For the main thread only.
unit Sprite3DAnimationsUsedForm;

{
  The Model, Animations Used dialog: which of the model's animations are
  used.

  A list of the model's animations, each with a tick box, and an All tick box
  above it that ticks or clears every one; it shows ticked only while every
  animation is ticked. The caller fills the list with SetAnimations and,
  after OK, reads UsedAnimations. Cancel, or closing the dialog any other
  way, leaves the caller's set as it was, as the dialog only changes its own
  copy. Keeping the set, and what it is used for, is the caller's job.

  On the desktop, show it with ShowModal and read UsedAnimations afterwards;
  on Android and iOS, which cannot block, show it with ShowAndFree, which
  calls OnAccept on OK, OnCancel otherwise, and frees the form when it
  closes. For the main thread only.
}

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs, FMX.StdCtrls,
  FMX.Controls.Presentation, FMX.Layouts, FMX.ListBox;

type
  //** @abstract(The Model, Animations Used dialog; see the unit description.)
  /// <summary>The Model, Animations Used dialog; see the unit description.</summary>
  TAnimationsUsedForm = class(TForm)
    //** @abstract(Holds the All tick box and the list.)
    /// <summary>Holds the All tick box and the list.</summary>
    MainLayout: TLayout;
    //** @abstract(Ticks or clears every animation; ticked only while every one is ticked.)
    /// <summary>Ticks or clears every animation; ticked only while every one is
    /// ticked.</summary>
    AllCheckBox: TCheckBox;
    //** @abstract(The model's animations, each with a tick box; ticked means used.)
    /// <summary>The model's animations, each with a tick box; ticked means used.</summary>
    AnimationList: TListBox;
    //** @abstract(Says the model has no animations, when it has none.)
    /// <summary>Says the model has no animations, when it has none.</summary>
    EmptyLabel: TLabel;
    //** @abstract(The strip holding the Cancel and OK buttons.)
    /// <summary>The strip holding the Cancel and OK buttons.</summary>
    ButtonLayout: TLayout;
    //** @abstract(Closes the dialog with mrOk.)
    /// <summary>Closes the dialog with mrOk.</summary>
    OkButton: TButton;
    //** @abstract(Closes the dialog with mrCancel, keeping none of the changes.)
    /// <summary>Closes the dialog with mrCancel, keeping none of the changes.</summary>
    CancelButton: TButton;
    //** @abstract(Ticks or clears every animation to match AllCheckBox.)
    //**
    //** @param(Sender AllCheckBox.)
    /// <summary>Ticks or clears every animation to match AllCheckBox.</summary>
    /// <param name="Sender">AllCheckBox.</param>
    procedure AllCheckBoxChange(Sender: TObject);
    //** @abstract(Shows AllCheckBox ticked only while every animation is ticked.)
    //**
    //** @param(Sender AnimationList.)
    /// <summary>Shows AllCheckBox ticked only while every animation is ticked.</summary>
    /// <param name="Sender">AnimationList.</param>
    procedure AnimationListChangeCheck(Sender: TObject);
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
    FSyncing: Boolean;
    procedure SyncAllCheckBox;
  public
    //** @abstract(Fills the list with AAll, ticking those in AUsed.)
    //**
    //** The animations are listed in AAll's order. A name in AUsed that is not in AAll is
    //** ignored; names are compared exactly. Call it before showing the dialog.
    //**
    //** @param(AAll Every animation of the model, by Id.)
    //**
    //** @param(AUsed The animations used now, by Id.)
    /// <summary>Fills the list with AAll, ticking those in AUsed.</summary>
    /// <remarks>The animations are listed in AAll's order. A name in AUsed that is not in AAll
    /// is ignored; names are compared exactly. Call it before showing the dialog.</remarks>
    /// <param name="AAll">Every animation of the model, by Id.</param>
    /// <param name="AUsed">The animations used now, by Id.</param>
    procedure SetAnimations(const AAll, AUsed: TArray<String>);

    //** @abstract(The ticked animations, in the list's order.)
    //**
    //** Read it after OK.
    //**
    //** @returns(The Ids of the ticked animations; empty if none is ticked.)
    /// <summary>The ticked animations, in the list's order.</summary>
    /// <remarks>Read it after OK.</remarks>
    /// <returns>The Ids of the ticked animations; empty if none is ticked.</returns>
    function UsedAnimations: TArray<String>;

    //** @abstract(Shows the dialog without blocking and frees it when it closes.)
    //**
    //** For Android and iOS, where ShowModal cannot block. OnAccept is called if it closes
    //** with OK, OnCancel otherwise.
    /// <summary>Shows the dialog without blocking and frees it when it closes.</summary>
    /// <remarks>For Android and iOS, where ShowModal cannot block. OnAccept is called if it
    /// closes with OK, OnCancel otherwise.</remarks>
    procedure ShowAndFree;

    //** @abstract(Called on OK when shown with ShowAndFree.)
    /// <summary>Called on OK when shown with ShowAndFree.</summary>
    property OnAccept: TNotifyEvent read FOnAccept write FOnAccept;
    //** @abstract(Called on Cancel, or any close but OK, when shown with ShowAndFree.)
    /// <summary>Called on Cancel, or any close but OK, when shown with ShowAndFree.</summary>
    property OnCancel: TNotifyEvent read FOnCancel write FOnCancel;
  end;

implementation

{$R *.fmx}

procedure TAnimationsUsedForm.SetAnimations(const AAll, AUsed: TArray<String>);
var
  Name, Used: String;
  Ticked: Boolean;
  Index: Integer;
begin
  FSyncing := True;
  try
    AnimationList.BeginUpdate;
    try
      AnimationList.Items.Clear;
      for Name in AAll do
      begin
        Ticked := False;
        for Used in AUsed do
          if Used = Name then
          begin
            Ticked := True;
            Break;
          end;
        Index := AnimationList.Items.Add(Name);
        AnimationList.ListItems[Index].IsChecked := Ticked;
      end;
    finally
      AnimationList.EndUpdate;
    end;
  finally
    FSyncing := False;
  end;
  EmptyLabel.Visible := AnimationList.Count = 0;
  AllCheckBox.Enabled := AnimationList.Count > 0;
  SyncAllCheckBox;
end;

function TAnimationsUsedForm.UsedAnimations: TArray<String>;
var
  I, N: Integer;
begin
  SetLength(Result, AnimationList.Count);
  N := 0;
  for I := 0 to AnimationList.Count - 1 do
    if AnimationList.ListItems[I].IsChecked then
    begin
      Result[N] := AnimationList.Items[I];
      Inc(N);
    end;
  SetLength(Result, N);
end;

procedure TAnimationsUsedForm.SyncAllCheckBox;
var
  I: Integer;
  Every: Boolean;
begin
  Every := AnimationList.Count > 0;
  for I := 0 to AnimationList.Count - 1 do
    if not AnimationList.ListItems[I].IsChecked then
    begin
      Every := False;
      Break;
    end;
  FSyncing := True;
  try
    AllCheckBox.IsChecked := Every;
  finally
    FSyncing := False;
  end;
end;

procedure TAnimationsUsedForm.AllCheckBoxChange(Sender: TObject);
var
  I: Integer;
begin
  if FSyncing then
    Exit;
  FSyncing := True;
  try
    for I := 0 to AnimationList.Count - 1 do
      AnimationList.ListItems[I].IsChecked := AllCheckBox.IsChecked;
  finally
    FSyncing := False;
  end;
end;

procedure TAnimationsUsedForm.AnimationListChangeCheck(Sender: TObject);
begin
  if not FSyncing then
    SyncAllCheckBox;
end;

procedure TAnimationsUsedForm.ButtonClick(Sender: TObject);
begin
  if not FFreeOnClose then
    Exit;   // ShowModal closes the dialog itself, from the button's ModalResult
  ModalResult := TButton(Sender).ModalResult;
  Close;
end;

procedure TAnimationsUsedForm.FormClose(Sender: TObject; var Action: TCloseAction);
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

procedure TAnimationsUsedForm.ShowAndFree;
begin
  FFreeOnClose := True;
  Show;
end;

end.
