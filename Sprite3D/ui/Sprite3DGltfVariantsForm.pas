//** @abstract(The Debug, glTF, Add Variants dialog: other textures for the open model, each
//** set a named variant, to be saved with it (KHR_materials_variants). Made in code; see
//** TGltfVariantsForm.Execute.)
//**
//** It lists the textures the model's materials use (VariantTextureSlots), each by its use
//** (base colour, normal map and so on), its material and the file it came from. Add Variant
//** adds a panel: the variant's name, and a file for each texture, chosen with its @code(...)
//** button, in any format the image library reads (TGA and PSD as well as PNG and JPEG; any
//** but PNG and JPEG is made a PNG when saved); one left empty keeps the model's own. A file
//** chosen for one texture is used to
//** suggest the others (SuggestVariantFile): sp02.png chosen for sp01.png suggests
//** sp02_NRM.png for sp01_NRM.png, if it is there; a suggestion is filled in, and said so
//** under the panel. The variant's name, if it has none yet, is the first file's name.
//**
//** Embed textures, ticked at first, saves a GLB with every texture inside it; cleared, a glTF
//** whose variant textures, and the model's own textures that are files, are left where they
//** are, for textures a whole kit shares.
//**
//** Save... checks every variant has a name, its own, and at least one file, then closes with
//** mrOk. Saving is the caller's job (SaveWithVariants).
//**
//** @preformatted(
//** TGltfVariantsForm
//** `-- BackPanel
//**     |-- InfoLabel         the model, its textures, and the variants it has already
//**     |-- EmbedCheck        Embed textures
//**     |-- VariantsBox       TVertScrollBox: a panel per variant (TVariantPanel)
//**     `-- the bottom row    Add Variant, the status, Cancel, Save...
//** )
//**
//** Desktop only, as the glTF tools are: shown with ShowModal. For the main thread only.
unit Sprite3DGltfVariantsForm;

{
  The Debug, glTF, Add Variants dialog: other textures for the open model,
  each set a named variant. Lists the textures the materials use, by use and
  the file each came from; Add Variant adds a panel with a name and a file
  for each texture (empty keeps the model's own). A file chosen suggests the
  others from its name (sp02.png for sp01.png suggests sp02_NRM.png for
  sp01_NRM.png, if it is there). Embed textures (ticked at first) saves a
  GLB; cleared, a glTF that leaves its texture files where they are. Save...
  checks the variants and closes with mrOk; saving is the caller's job.
  Desktop only; ShowModal. Main thread only.
}

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.StdCtrls, FMX.Layouts, FMX.Edit, FMX.Objects,
  FMX.Graphics, FMX.Controls.Presentation, FMX.Dialogs, System.Generics.Collections,
  Sprite3DGltfVariants;

type
  //** @abstract(One variant's panel: its name, a file for each texture, and what was
  //** suggested.)
  TVariantPanel = class
  public
    //** @abstract(The panel itself, in VariantsBox.)
    Panel: TRectangle;
    //** @abstract(The variant's name.)
    NameEdit: TEdit;
    //** @abstract(A box per texture slot, showing the file chosen's name; its Hint is the full
    //** path, and its TagString the path itself.)
    FileEdits: TArray<TEdit>;
    //** @abstract(Says what was suggested, and from what.)
    HintLabel: TLabel;
  end;

  //** @abstract(The Add Variants dialog; see the unit description. Use Execute.)
  TGltfVariantsForm = class(TForm)
  private
    //** @abstract(The model's textures, as VariantTextureSlots gives them.)
    FSlots: TArray<TGltfTextureSlot>;
    //** @abstract(The variants the model has already, whose names a new one cannot take.)
    FExisting: TArray<String>;
    //** @abstract(Where the file dialog starts: the model's folder, then the last file's.)
    FFolder: String;
    //** @abstract(The variants' panels, in order; owned.)
    FPanels: TObjectList<TVariantPanel>;
    //** @abstract(A panel's width: the box's, less its scroll bar, worked out from the form's
    //** width, as the first panel is made before the form is laid out.)
    FPanelWidth: Single;
    //** @abstract(The background, which the rows go on.)
    FBack: TPanel;
    //** @abstract(The variants' panels' box.)
    FVariantsBox: TVertScrollBox;
    //** @abstract(Embed textures.)
    FEmbedCheck: TCheckBox;
    //** @abstract(Says what is wrong, or what to do next.)
    FStatusLabel: TLabel;
    //** @abstract(Adds a panel for a new variant, at the end, and scrolls to it.)
    //**
    //** @param(Sender The Add Variant button.)
    procedure AddVariantClick(Sender: TObject);
    //** @abstract(Takes the variant whose panel holds the button off.)
    //**
    //** @param(Sender A Remove button; its Tag is the panel's index.)
    procedure RemoveVariantClick(Sender: TObject);
    //** @abstract(Chooses a file for a texture of a variant, and suggests the variant's other
    //** textures from it.)
    //**
    //** @param(Sender A @code(...) button; its Tag is panel index * 1000 + slot index.)
    procedure ChooseFileClick(Sender: TObject);
    //** @abstract(Empties a texture's file: the model's own is kept.)
    //**
    //** @param(Sender A clear button; its Tag as for ChooseFileClick.)
    procedure ClearFileClick(Sender: TObject);
    //** @abstract(Checks the variants; closes with mrOk if they will do.)
    //**
    //** @param(Sender The Save button.)
    procedure SaveClick(Sender: TObject);
    //** @abstract(Sets a texture box to a file, or empties it.)
    //**
    //** @param(AEdit The box.)
    //**
    //** @param(AFile The file, a full path; empty for none.)
    procedure SetFile(const AEdit: TEdit; const AFile: String);
    //** @abstract(Puts the panels one under another, after one is added or taken off, and
    //** numbers their buttons' tags.)
    procedure LayoutPanels;
    //** @abstract(The variants as the panels give them.)
    //**
    //** @returns(One per panel, in order.)
    function Variants: TArray<TGltfNewVariant>;
  public
    //** @abstract(Frees the panels' records.)
    destructor Destroy; override;
    //** @abstract(Shows the dialog modally, and gives the variants and the embed choice if it
    //** was closed with Save.)
    //**
    //** @param(AModelName The model's file name, for the title and the text.)
    //**
    //** @param(ASlots The model's textures; not empty.)
    //**
    //** @param(AExisting The variants it has already.)
    //**
    //** @param(AFolder Where the file dialog starts.)
    //**
    //** @param(AVariants On return, the variants to add, if True.)
    //**
    //** @param(AEmbed On return, Embed textures, if True.)
    //**
    //** @returns(True if the user chose Save, and the variants are good.)
    class function Execute(const AModelName: String; const ASlots: TArray<TGltfTextureSlot>;
      const AExisting: TArray<String>; const AFolder: String;
      out AVariants: TArray<TGltfNewVariant>; out AEmbed: Boolean): Boolean;
  end;

//** @abstract(The file a variant probably has for another texture, from the file chosen for
//** one: the change from the model's file to the chosen one, made to the other texture's
//** file, if a file of that name is there.)
//**
//** sp01.png to sp02.png makes sp01_NRM.png sp02_NRM.png; Spider.png to Spider_Red.png makes
//** Spider_NRM.png Spider_Red_NRM.png. The name is looked for in the chosen file's folder,
//** then the other's own, with its own extension, then the chosen one's.
//**
//** @param(ABaseOfChosen The model's file for the texture chosen; a name or a path.)
//**
//** @param(AChosen The file chosen, a full path.)
//**
//** @param(ABaseOfOther The model's file for the other texture; a name or a path.)
//**
//** @returns(The file found, a full path; empty if none is there, or the names give no
//** pattern.)
function SuggestVariantFile(const ABaseOfChosen, AChosen, ABaseOfOther: String): String;

implementation

uses
  System.IOUtils, System.Math, Sprite3DModelTextures;

const
  //** @abstract(The space round the dialog's edge and between its rows.)
  PAD = 10;
  //** @abstract(A row's height in a panel.)
  ROW = 28;
  //** @abstract(The width of the label naming each texture in a panel.)
  SLOT_LABEL_WIDTH = 300;
  //** @abstract(Tags of the file buttons: panel index times this, plus the slot's.)
  TAG_PANEL = 1000;

function SuggestVariantFile(const ABaseOfChosen, AChosen, ABaseOfOther: String): String;
var
  Base, Chosen, Other, Prefix, Suffix, Middle, Changed, Candidate: String;
  P, S: Integer;
  Folders, Exts: TArray<String>;
begin
  Result := String.Empty;
  Base := System.IOUtils.TPath.GetFileNameWithoutExtension(ABaseOfChosen);
  Chosen := System.IOUtils.TPath.GetFileNameWithoutExtension(AChosen);
  Other := System.IOUtils.TPath.GetFileNameWithoutExtension(ABaseOfOther);
  if (Base = String.Empty) or (Other = String.Empty) or SameText(Base, Chosen) then
    Exit;
  // What the two names share at each end; the middle is what changed
  P := 0;
  while (P < Min(Base.Length, Chosen.Length)) and SameText(Base.Chars[P], Chosen.Chars[P]) do
    Inc(P);
  S := 0;
  while (S < Min(Base.Length, Chosen.Length) - P) and
    SameText(Base.Chars[Base.Length - 1 - S], Chosen.Chars[Chosen.Length - 1 - S]) do
    Inc(S);
  Prefix := Base.Substring(0, P);
  Suffix := Base.Substring(Base.Length - S);
  Middle := Base.Substring(P, Base.Length - P - S);
  // The other name made the same way: best where it starts as the model's
  // did, as sp01_NRM after sp01; else the whole of the model's name in it
  if Other.StartsWith(Prefix + Middle + Suffix, True) then
    Changed := Chosen + Other.Substring(Base.Length)
  else if Other.StartsWith(Prefix + Middle, True) and (Middle <> String.Empty) then
    Changed := Prefix + Chosen.Substring(P, Chosen.Length - P - S) +
      Other.Substring(P + Middle.Length)
  else if Other.ToLower.Contains(Base.ToLower) then
    Changed := Other.Substring(0, Other.ToLower.IndexOf(Base.ToLower)) + Chosen +
      Other.Substring(Other.ToLower.IndexOf(Base.ToLower) + Base.Length)
  else
    Exit;
  if SameText(Changed, Other) then
    Exit;
  Folders := [ExtractFileDir(AChosen)];
  if ExtractFileDir(ABaseOfOther) <> String.Empty then
    Folders := Folders + [ExtractFileDir(ABaseOfOther)];
  Exts := [ExtractFileExt(ABaseOfOther), ExtractFileExt(AChosen)];
  for var Folder in Folders do
    for var Ext in Exts do
    begin
      if Ext = String.Empty then
        Continue;
      Candidate := System.IOUtils.TPath.Combine(Folder, Changed + Ext);
      if TFile.Exists(Candidate) then
        Exit(Candidate);
    end;
end;

{ TGltfVariantsForm }

destructor TGltfVariantsForm.Destroy;
begin
  FPanels.Free;
  inherited;
end;

procedure TGltfVariantsForm.SetFile(const AEdit: TEdit; const AFile: String);
begin
  AEdit.TagString := AFile;
  if AFile = String.Empty then
  begin
    AEdit.Text := String.Empty;
    AEdit.Hint := 'Empty: the model''s own texture is kept';
  end
  else
  begin
    AEdit.Text := ExtractFileName(AFile);
    AEdit.Hint := AFile;
  end;
end;

procedure TGltfVariantsForm.LayoutPanels;
var
  Y: Single;
  Panel: TVariantPanel;
begin
  Y := 0;
  for var I := 0 to FPanels.Count - 1 do
  begin
    Panel := FPanels[I];
    Panel.Panel.Position.Y := Y;
    Y := Y + Panel.Panel.Height + PAD;
    // The buttons' tags say which panel, and which slot, they belong to
    for var Child in Panel.Panel.Children do
      if (Child is TButton) and (TButton(Child).TagFloat >= 0) then
        TButton(Child).Tag := I * TAG_PANEL + Round(TButton(Child).TagFloat);
  end;
  FStatusLabel.Text := Format('%d variants to add', [FPanels.Count]);
end;

procedure TGltfVariantsForm.AddVariantClick(Sender: TObject);
var
  Panel: TVariantPanel;
  Lbl: TLabel;
  Btn: TButton;
  Edit: TEdit;
  Y, W: Single;
begin
  Panel := TVariantPanel.Create;
  FPanels.Add(Panel);
  W := FPanelWidth;
  Panel.Panel := TRectangle.Create(Self);
  Panel.Panel.Parent := FVariantsBox;
  Panel.Panel.SetBounds(0, 0, W, PAD + ROW * (Length(FSlots) + 2) + PAD);
  Panel.Panel.Fill.Kind := TBrushKind.None;
  Panel.Panel.Stroke.Color := TAlphaColors.Gray;
  Panel.Panel.XRadius := 4;
  Panel.Panel.YRadius := 4;

  Y := PAD;
  Lbl := TLabel.Create(Self);
  Lbl.Parent := Panel.Panel;
  Lbl.SetBounds(PAD, Y + 4, 90, 20);
  Lbl.Text := 'Variant name';
  Panel.NameEdit := TEdit.Create(Self);
  Panel.NameEdit.Parent := Panel.Panel;
  Panel.NameEdit.SetBounds(PAD + 96, Y, 260, 24);
  Panel.NameEdit.TextPrompt := 'Such as Red, or the first file''s name';
  Btn := TButton.Create(Self);
  Btn.Parent := Panel.Panel;
  Btn.SetBounds(W - PAD - 80, Y, 80, 24);
  Btn.Text := 'Remove';
  Btn.TagFloat := 0;
  Btn.OnClick := RemoveVariantClick;
  Y := Y + ROW + 4;

  SetLength(Panel.FileEdits, Length(FSlots));
  for var S := 0 to High(FSlots) do
  begin
    // What the texture is for, and which file the model has: the guide to
    // what goes here
    Lbl := TLabel.Create(Self);
    Lbl.Parent := Panel.Panel;
    Lbl.SetBounds(PAD, Y + 4, SLOT_LABEL_WIDTH, 20);
    if FSlots[S].FileName <> String.Empty then
      Lbl.Text := Format('%s of %s (%s)', [TextureUseText(FSlots[S].Use),
        FSlots[S].MaterialName, ExtractFileName(FSlots[S].FileName)])
    else
      Lbl.Text := Format('%s of %s', [TextureUseText(FSlots[S].Use),
        FSlots[S].MaterialName]);
    Lbl.Hint := Lbl.Text;
    Lbl.ShowHint := True;
    Edit := TEdit.Create(Self);
    Edit.Parent := Panel.Panel;
    Edit.SetBounds(PAD + SLOT_LABEL_WIDTH + 4, Y, W - SLOT_LABEL_WIDTH - 2 * PAD - 72, 24);
    Edit.ReadOnly := True;
    Edit.ShowHint := True;
    Edit.TextPrompt := '(the model''s own)';
    SetFile(Edit, String.Empty);
    Panel.FileEdits[S] := Edit;
    Btn := TButton.Create(Self);
    Btn.Parent := Panel.Panel;
    Btn.SetBounds(W - PAD - 64, Y, 30, 24);
    Btn.Text := '...';
    Btn.Hint := 'Choose an image for this texture: PNG or JPEG, or TGA, PSD and the like, ' +
      'made a PNG when saved';
    Btn.ShowHint := True;
    Btn.TagFloat := S;
    Btn.OnClick := ChooseFileClick;
    Btn := TButton.Create(Self);
    Btn.Parent := Panel.Panel;
    Btn.SetBounds(W - PAD - 30, Y, 30, 24);
    Btn.Text := 'x';
    Btn.Hint := 'Keep the model''s own texture';
    Btn.ShowHint := True;
    Btn.TagFloat := S;
    Btn.OnClick := ClearFileClick;
    Y := Y + ROW;
  end;
  Panel.HintLabel := TLabel.Create(Self);
  Panel.HintLabel.Parent := Panel.Panel;
  Panel.HintLabel.SetBounds(PAD, Y + 2, W - 2 * PAD, 20);
  Panel.HintLabel.Text := 'Choose a file for any texture; the others are suggested from it';
  LayoutPanels;
  FVariantsBox.ViewportPosition := TPointF.Create(0, Panel.Panel.Position.Y);
  if Visible then
    Panel.NameEdit.SetFocus;
end;

procedure TGltfVariantsForm.RemoveVariantClick(Sender: TObject);
var
  Index: Integer;
begin
  Index := TButton(Sender).Tag div TAG_PANEL;
  if (Index < 0) or (Index >= FPanels.Count) then
    Exit;
  FPanels[Index].Panel.Free;
  FPanels.Delete(Index);
  LayoutPanels;
end;

procedure TGltfVariantsForm.ChooseFileClick(Sender: TObject);
var
  PanelIndex, SlotIndex: Integer;
  Panel: TVariantPanel;
  Dialog: TOpenDialog;
  Chosen, Suggested: String;
  Filled: TArray<String>;
begin
  PanelIndex := TButton(Sender).Tag div TAG_PANEL;
  SlotIndex := TButton(Sender).Tag mod TAG_PANEL;
  if (PanelIndex < 0) or (PanelIndex >= FPanels.Count) or (SlotIndex > High(FSlots)) then
    Exit;
  Panel := FPanels[PanelIndex];
  Dialog := TOpenDialog.Create(nil);
  try
    Dialog.Title := Format('%s of %s', [TextureUseText(FSlots[SlotIndex].Use),
      FSlots[SlotIndex].MaterialName]);
    if FSlots[SlotIndex].FileName <> String.Empty then
      Dialog.Title := Dialog.Title + ', in place of ' +
        ExtractFileName(FSlots[SlotIndex].FileName);
    // glTF takes PNG and JPEG; anything else the image library reads is
    // made a PNG when saving
    Dialog.Filter := 'Images (*.png;*.jpg;*.jpeg;*.tga;*.psd;*.bmp;*.tif;*.tiff;*.gif;' +
      '*.dds)|*.png;*.jpg;*.jpeg;*.tga;*.psd;*.bmp;*.tif;*.tiff;*.gif;*.dds|' +
      'All files (*.*)|*.*';
    Dialog.InitialDir := FFolder;
    if not Dialog.Execute then
      Exit;
    Chosen := Dialog.FileName;
  finally
    Dialog.Free;
  end;
  if not ReadableImageFile(Chosen) then
  begin
    Panel.HintLabel.Text := ExtractFileName(Chosen) + ' is not an image this can read.';
    Exit;
  end;
  FFolder := ExtractFileDir(Chosen);
  SetFile(Panel.FileEdits[SlotIndex], Chosen);
  if Panel.NameEdit.Text.Trim = String.Empty then
    Panel.NameEdit.Text := System.IOUtils.TPath.GetFileNameWithoutExtension(Chosen);
  // The others, from the change this one makes to the model's file
  Filled := nil;
  for var S := 0 to High(FSlots) do
  begin
    if (S = SlotIndex) or (Panel.FileEdits[S].TagString <> String.Empty) then
      Continue;
    Suggested := SuggestVariantFile(FSlots[SlotIndex].FileName, Chosen, FSlots[S].FileName);
    if Suggested <> String.Empty then
    begin
      SetFile(Panel.FileEdits[S], Suggested);
      Filled := Filled + [ExtractFileName(Suggested)];
    end;
  end;
  if Length(Filled) > 0 then
    Panel.HintLabel.Text := Format('Suggested from %s: %s. Check them, or change them.',
      [ExtractFileName(Chosen), String.Join(', ', Filled)])
  else
    Panel.HintLabel.Text := Format('Nothing suggested from %s: choose the others, or leave ' +
      'them empty to keep the model''s own.', [ExtractFileName(Chosen)]);
end;

procedure TGltfVariantsForm.ClearFileClick(Sender: TObject);
var
  PanelIndex, SlotIndex: Integer;
begin
  PanelIndex := TButton(Sender).Tag div TAG_PANEL;
  SlotIndex := TButton(Sender).Tag mod TAG_PANEL;
  if (PanelIndex >= 0) and (PanelIndex < FPanels.Count) and (SlotIndex <= High(FSlots)) then
    SetFile(FPanels[PanelIndex].FileEdits[SlotIndex], String.Empty);
end;

function TGltfVariantsForm.Variants: TArray<TGltfNewVariant>;
var
  Variant: TGltfNewVariant;
begin
  Result := nil;
  for var Panel in FPanels do
  begin
    Variant.Name := Panel.NameEdit.Text.Trim;
    SetLength(Variant.Files, Length(FSlots));
    for var S := 0 to High(FSlots) do
      Variant.Files[S] := Panel.FileEdits[S].TagString;
    Result := Result + [Variant];
  end;
end;

procedure TGltfVariantsForm.SaveClick(Sender: TObject);
var
  Names: TArray<String>;
  Count: Integer;
begin
  if FPanels.Count = 0 then
  begin
    FStatusLabel.Text := 'Add a variant first.';
    Exit;
  end;
  Names := Copy(FExisting);
  for var Variant in Variants do
  begin
    if Variant.Name = String.Empty then
    begin
      FStatusLabel.Text := 'Every variant needs a name.';
      Exit;
    end;
    // The model as made is the base, with no variant name of its own
    if SameText(Variant.Name, 'Base') then
    begin
      FStatusLabel.Text := 'Base is the model as made: give the variant another name.';
      Exit;
    end;
    for var Name in Names do
      if SameText(Name, Variant.Name) then
      begin
        FStatusLabel.Text := Format('There is a variant called %s already.', [Variant.Name]);
        Exit;
      end;
    Names := Names + [Variant.Name];
    Count := 0;
    for var FileName in Variant.Files do
      if FileName <> String.Empty then
      begin
        if not TFile.Exists(FileName) then
        begin
          FStatusLabel.Text := FileName + ' is not there.';
          Exit;
        end;
        Inc(Count);
      end;
    if Count = 0 then
    begin
      FStatusLabel.Text := Format('%s has no textures of its own: choose at least one.',
        [Variant.Name]);
      Exit;
    end;
  end;
  ModalResult := mrOk;
end;

class function TGltfVariantsForm.Execute(const AModelName: String;
  const ASlots: TArray<TGltfTextureSlot>; const AExisting: TArray<String>;
  const AFolder: String; out AVariants: TArray<TGltfNewVariant>;
  out AEmbed: Boolean): Boolean;
var
  Form: TGltfVariantsForm;
  Info: TLabel;
  Row: TLayout;
  Btn: TButton;
  Text: String;
begin
  AVariants := nil;
  AEmbed := True;
  Form := TGltfVariantsForm.CreateNew(nil);
  try
    Form.FSlots := ASlots;
    Form.FExisting := AExisting;
    Form.FFolder := AFolder;
    Form.FPanels := TObjectList<TVariantPanel>.Create(True);
    Form.Caption := 'Add Variants - ' + AModelName;
    Form.Position := TFormPosition.MainFormCenter;
    Form.ClientWidth := 780;
    Form.ClientHeight := 560;
    // The box's width, less the padding either side and a scroll bar
    Form.FPanelWidth := Form.ClientWidth - 2 * PAD - 24;

    Form.FBack := TPanel.Create(Form);
    Form.FBack.Parent := Form;
    Form.FBack.Align := TAlignLayout.Contents;
    Form.FBack.Padding.Rect := TRectF.Create(PAD, PAD, PAD, PAD);

    Info := TLabel.Create(Form);
    Info.Parent := Form.FBack;
    Info.Align := TAlignLayout.Top;
    Info.Height := 54;
    Info.TextSettings.WordWrap := True;
    Text := Format('%s has %d textures. A variant gives other files for any of them; one ' +
      'left empty keeps the model''s own. The model as made is the base, which a viewer ' +
      'that does not know variants shows.', [AModelName, Length(ASlots)]);
    if Length(AExisting) > 0 then
      Text := Text + ' It has these already: ' + String.Join(', ', AExisting) + '.';
    Info.Text := Text;

    Form.FEmbedCheck := TCheckBox.Create(Form);
    Form.FEmbedCheck.Parent := Form.FBack;
    Form.FEmbedCheck.Align := TAlignLayout.Top;
    Form.FEmbedCheck.Height := 24;
    Form.FEmbedCheck.Margins.Top := 4;
    Form.FEmbedCheck.Text := 'Embed textures (save a GLB with every texture inside it)';
    Form.FEmbedCheck.Hint := 'Cleared: save a glTF that names its texture files where they ' +
      'are, for textures a whole kit shares';
    Form.FEmbedCheck.ShowHint := True;
    Form.FEmbedCheck.IsChecked := True;

    Row := TLayout.Create(Form);
    Row.Parent := Form.FBack;
    Row.Align := TAlignLayout.Bottom;
    Row.Height := 30;
    Row.Margins.Top := PAD;
    Btn := TButton.Create(Form);
    Btn.Parent := Row;
    Btn.Align := TAlignLayout.Left;
    Btn.Width := 110;
    Btn.Text := 'Add Variant';
    Btn.OnClick := Form.AddVariantClick;
    Btn := TButton.Create(Form);
    Btn.Parent := Row;
    Btn.Align := TAlignLayout.Right;
    Btn.Width := 90;
    Btn.Text := 'Save...';
    Btn.Default := True;
    Btn.OnClick := Form.SaveClick;
    Btn := TButton.Create(Form);
    Btn.Parent := Row;
    Btn.Align := TAlignLayout.Right;
    Btn.Width := 90;
    Btn.Margins.Right := 6;
    Btn.Text := 'Cancel';
    Btn.Cancel := True;
    Btn.ModalResult := mrCancel;
    Form.FStatusLabel := TLabel.Create(Form);
    Form.FStatusLabel.Parent := Row;
    Form.FStatusLabel.Align := TAlignLayout.Client;
    Form.FStatusLabel.Margins.Left := PAD;

    Form.FVariantsBox := TVertScrollBox.Create(Form);
    Form.FVariantsBox.Parent := Form.FBack;
    Form.FVariantsBox.Align := TAlignLayout.Client;
    Form.FVariantsBox.Margins.Top := PAD;

    // One to start with
    Form.AddVariantClick(nil);

    Result := Form.ShowModal = mrOk;
    if Result then
    begin
      AVariants := Form.Variants;
      AEmbed := Form.FEmbedCheck.IsChecked;
    end;
  finally
    Form.Free;
  end;
end;

end.
