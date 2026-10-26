//** @abstract(The Animation, Animations Used dialog: which of the model's animations are used.)
//**
//** A list of the model's animations, each with a tick box, and an All tick box above it that
//** ticks or clears every one; it shows ticked only while every animation is ticked. The
//** caller fills the list with SetAnimations and, after OK, reads UsedAnimations.
//**
//** A column on the right gives each animation's own swept volume as a percentage of the
//** combined swept volume: the rest pose's joined with that of every animation ticked at the
//** time. It is worked out again whenever a tick changes. An animation that reaches much
//** further than the others stands out, as the others' percentages are small beside it, and
//** unticking it shows how much the combined volume shrinks without it. An unticked
//** animation can show more than 100%, as it is not in the combined volume. Cancel, or
//** closing the dialog any other way, leaves the caller's set as it was, as the dialog only
//** changes its own copy. Keeping the set, and what it is used for, is the caller's job.
//**
//** On the desktop, show it with ShowModal and read UsedAnimations afterwards; on Android and
//** iOS, which cannot block, show it with ShowAndFree, which calls OnAccept on OK, OnCancel
//** otherwise, and frees the form when it closes. For the main thread only.
unit Sprite3DAnimationsUsedForm;

{
  The Animation, Animations Used dialog: which of the model's animations are
  used.

  A list of the model's animations, each with a tick box, and an All tick box
  above it that ticks or clears every one; it shows ticked only while every
  animation is ticked. The caller fills the list with SetAnimations and,
  after OK, reads UsedAnimations.

  A column on the right gives each animation's own swept volume as a
  percentage of the combined swept volume: the rest pose's joined with that of
  every animation ticked at the time. It is worked out again whenever a tick
  changes. An animation that reaches much further than the others stands out,
  as the others' percentages are small beside it, and unticking it shows how
  much the combined volume shrinks without it. An unticked animation can show
  more than 100%, as it is not in the combined volume. Cancel, or closing the
  dialog any other way, leaves the caller's set as it was, as the dialog only
  changes its own copy. Keeping the set, and what it is used for, is the
  caller's job.

  On the desktop, show it with ShowModal and read UsedAnimations afterwards;
  on Android and iOS, which cannot block, show it with ShowAndFree, which
  calls OnAccept on OK, OnCancel otherwise, and frees the form when it
  closes. For the main thread only.
}

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs, FMX.StdCtrls,
  FMX.Controls.Presentation, FMX.Layouts, FMX.ListBox, Sprite3DSweep;

type
  //** @abstract(The Animation, Animations Used dialog; see the unit description.)
  TAnimationsUsedForm = class(TForm)
    //** @abstract(Holds the All tick box and the list.)
    MainLayout: TLayout;
    //** @abstract(The row above the list with AllCheckBox and ShareHeaderLabel.)
    HeaderLayout: TLayout;
    //** @abstract(The title over the percentage column, "% of combined".)
    ShareHeaderLabel: TLabel;
    //** @abstract(Ticks or clears every animation; ticked only while every one is ticked.)
    AllCheckBox: TCheckBox;
    //** @abstract(The model's animations, each with a tick box; ticked means used.)
    AnimationList: TListBox;
    //** @abstract(Says the model has no animations, when it has none.)
    EmptyLabel: TLabel;
    //** @abstract(The strip holding the Cancel and OK buttons.)
    ButtonLayout: TLayout;
    //** @abstract(Closes the dialog with mrOk.)
    OkButton: TButton;
    //** @abstract(Closes the dialog with mrCancel, keeping none of the changes.)
    CancelButton: TButton;
    //** @abstract(Ticks or clears every animation to match AllCheckBox.)
    //**
    //** @param(Sender AllCheckBox.)
    procedure AllCheckBoxChange(Sender: TObject);
    //** @abstract(Shows AllCheckBox ticked only while every animation is ticked.)
    //**
    //** @param(Sender AnimationList.)
    procedure AnimationListChangeCheck(Sender: TObject);
    //** @abstract(Closes the dialog with the button's ModalResult.)
    //**
    //** @param(Sender OkButton or CancelButton.)
    procedure ButtonClick(Sender: TObject);
    //** @abstract(Reports OK or Cancel when shown with ShowAndFree, and frees the form then.)
    //**
    //** @param(Sender The form.)
    //**
    //** @param(Action Set to caFree when shown with ShowAndFree.)
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
  private
    FOnAccept: TNotifyEvent;
    FOnCancel: TNotifyEvent;
    FFreeOnClose: Boolean;
    FSyncing: Boolean;
    FVolumes: TArray<TSweptVolume>;   // one per entry, in the list's order
    FRest: TSweptVolume;
    procedure SyncAllCheckBox;
    procedure UpdateShares;
    function ShareLabel(const AIndex: Integer): TLabel;
  public
    //** @abstract(Fills the list with AAll, ticking those in AUsed, with each animation's
    //** share of the combined swept volume.)
    //**
    //** The animations are listed in AAll's order. A name in AUsed that is not in AAll is
    //** ignored; names are compared exactly. AVolumes gives each animation's own swept volume,
    //** in AAll's order; an entry that is not Valid, or missing, shows a dash in the
    //** percentage column and counts for nothing in the combined volume. Call it before
    //** showing the dialog.
    //**
    //** @param(AAll Every animation of the model, by Id.)
    //**
    //** @param(AUsed The animations used now, by Id.)
    //**
    //** @param(AVolumes Each animation's own swept volume, in AAll's order, as
    //** CombinedSweptVolume gives it for that animation alone.)
    //**
    //** @param(ARest The rest pose's swept volume, always part of the combined volume.)
    procedure SetAnimations(const AAll, AUsed: TArray<String>;
      const AVolumes: TArray<TSweptVolume>; const ARest: TSweptVolume);

    //** @abstract(The ticked animations, in the list's order.)
    //**
    //** Read it after OK.
    //**
    //** @returns(The Ids of the ticked animations; empty if none is ticked.)
    function UsedAnimations: TArray<String>;

    //** @abstract(Shows the dialog without blocking and frees it when it closes.)
    //**
    //** For Android and iOS, where ShowModal cannot block. OnAccept is called if it closes
    //** with OK, OnCancel otherwise.
    procedure ShowAndFree;

    //** @abstract(Called on OK when shown with ShowAndFree.)
    property OnAccept: TNotifyEvent read FOnAccept write FOnAccept;
    //** @abstract(Called on Cancel, or any close but OK, when shown with ShowAndFree.)
    property OnCancel: TNotifyEvent read FOnCancel write FOnCancel;
  end;

implementation

{$R *.fmx}

procedure TAnimationsUsedForm.SetAnimations(const AAll, AUsed: TArray<String>;
  const AVolumes: TArray<TSweptVolume>; const ARest: TSweptVolume);
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
  FVolumes := Copy(AVolumes);
  SetLength(FVolumes, AnimationList.Count);   // missing entries are not Valid
  FRest := ARest;
  EmptyLabel.Visible := AnimationList.Count = 0;
  AllCheckBox.Enabled := AnimationList.Count > 0;
  SyncAllCheckBox;
  UpdateShares;
end;

// The label at the right of entry AIndex that shows its percentage, made
// the first time it is wanted; it ignores the mouse, so clicks still reach
// the entry and its tick box
function TAnimationsUsedForm.ShareLabel(const AIndex: Integer): TLabel;
const
  SHARE_LABEL_TAG = 3002;
var
  Item: TListBoxItem;
  I: Integer;
begin
  Item := AnimationList.ListItems[AIndex];
  for I := 0 to Item.ChildrenCount - 1 do
    if (Item.Children[I] is TLabel) and (TLabel(Item.Children[I]).Tag = SHARE_LABEL_TAG) then
      Exit(TLabel(Item.Children[I]));
  Result := TLabel.Create(Item);
  Result.Stored := False;
  Result.Tag := SHARE_LABEL_TAG;
  Result.Parent := Item;
  Result.Align := TAlignLayout.Right;
  Result.Width := 90;
  Result.Margins.Right := 6;
  Result.HitTest := False;
  Result.TextSettings.HorzAlign := TTextAlign.Trailing;
end;

// Each entry's own volume as a percentage of the rest pose's joined with
// every ticked entry's, as the ticks stand now
procedure TAnimationsUsedForm.UpdateShares;
var
  Ticked: TArray<TSweptVolume>;
  Combined: TSweptVolume;
  I: Integer;
begin
  Ticked := [FRest];
  for I := 0 to AnimationList.Count - 1 do
    if AnimationList.ListItems[I].IsChecked then
      Ticked := Ticked + [FVolumes[I]];
  Combined := UnionSweptVolume(Ticked);
  for I := 0 to AnimationList.Count - 1 do
    if FVolumes[I].Valid and (Combined.Volume > 0) then
      ShareLabel(I).Text := Format('%.0f%%', [100 * FVolumes[I].Volume / Combined.Volume])
    else
      ShareLabel(I).Text := '-';
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
  UpdateShares;
end;

procedure TAnimationsUsedForm.AnimationListChangeCheck(Sender: TObject);
begin
  if FSyncing then
    Exit;
  SyncAllCheckBox;
  UpdateShares;
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
