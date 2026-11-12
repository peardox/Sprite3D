//** @abstract(The Debug, glTF, Export as GLB dialog: how the open model is written as GLB.)
//**
//** A .glb or .gltf model is saved from its own file, so there is nothing to choose and the
//** boxes are disabled; SourceLabel says so. Any other model is converted from what
//** Gorilla3D loaded, with the boxes' options (see TGltfExportOptions in
//** Sprite3DGltfExport). Export... closes the dialog with mrOk; choosing the file and saving
//** are the caller's job.
//**
//** Desktop only, as the Debug menu's glTF tools are: shown with ShowModal. For the main
//** thread only.
unit Sprite3DGltfExportForm;

{
  The Debug, glTF, Export as GLB dialog: how the open model is written as GLB.
  A glTF model is saved from its own file and the boxes are disabled; any
  other model is converted with the boxes' options. Export... closes with
  mrOk. Desktop only; shown with ShowModal. Main thread only.
}

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, FMX.Types,
  FMX.Controls, FMX.Forms, FMX.Graphics, FMX.StdCtrls, FMX.Layouts,
  FMX.Controls.Presentation,
  Sprite3DGltfExport;

type
  //** @abstract(The Debug, glTF, Export as GLB dialog; see the unit description.)
  TGltfExportForm = class(TForm)
    //** @abstract(Says where the GLB will come from: the model's own file, or a conversion.)
    SourceLabel: TLabel;
    //** @abstract(TGltfExportOptions.Textures.)
    TexturesCheck: TCheckBox;
    //** @abstract(TGltfExportOptions.Skins.)
    SkinsCheck: TCheckBox;
    //** @abstract(TGltfExportOptions.Animations.)
    AnimationsCheck: TCheckBox;
    //** @abstract(TGltfExportOptions.ThinKeys.)
    ThinKeysCheck: TCheckBox;
    //** @abstract(TGltfExportOptions.ApplyUnitScale.)
    UnitScaleCheck: TCheckBox;
    //** @abstract(TGltfExportOptions.VertexColors.)
    VertexColoursCheck: TCheckBox;
    //** @abstract(The strip holding the Cancel and Export buttons.)
    ButtonLayout: TLayout;
    //** @abstract(Closes the dialog with mrCancel.)
    CancelButton: TButton;
    //** @abstract(Closes the dialog with mrOk.)
    ExportButton: TButton;
    //** @abstract(Closes the dialog with mrOk.)
    //**
    //** @param(Sender ExportButton.)
    procedure ExportButtonClick(Sender: TObject);
    //** @abstract(Closes the dialog with mrCancel.)
    //**
    //** @param(Sender CancelButton.)
    procedure CancelButtonClick(Sender: TObject);
  private
    //** The options the boxes show.
    function GetOptions: TGltfExportOptions;
    //** Ticks the boxes as AValue says.
    procedure SetOptions(const AValue: TGltfExportOptions);
  public
    //** @abstract(Lets SourceLabel wrap.)
    //**
    //** @param(AOwner The owner, as for any form.)
    constructor Create(AOwner: TComponent); override;
    //** @abstract(Says what will be saved, and disables the options when the model is glTF.)
    //**
    //** @param(AFileName The open model's file.)
    //**
    //** @param(AIsGltf True when it is .glb or .gltf, and is saved from its own file.)
    procedure SetSource(const AFileName: string; const AIsGltf: Boolean);
    //** @abstract(The options; set them before showing the dialog, read them after.)
    property Options: TGltfExportOptions read GetOptions write SetOptions;
  end;

implementation

{$R *.fmx}

constructor TGltfExportForm.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  SourceLabel.StyledSettings := SourceLabel.StyledSettings - [TStyledSetting.Other];
  SourceLabel.TextSettings.WordWrap := True;
  SourceLabel.TextSettings.VertAlign := TTextAlign.Leading;
end;

procedure TGltfExportForm.SetSource(const AFileName: string; const AIsGltf: Boolean);
var
  Checks: TArray<TCheckBox>;
  Check: TCheckBox;
begin
  if AIsGltf then
    SourceLabel.Text := ExtractFileName(AFileName) + ' is glTF already, so it is saved ' +
      'as GLB from its own file, with everything in it; there is nothing to choose.'
  else
    SourceLabel.Text := ExtractFileName(AFileName) + ' is converted from what Gorilla3D ' +
      'loaded: its meshes, materials, textures, skins and animations, as below.';
  Checks := [TexturesCheck, SkinsCheck, AnimationsCheck, ThinKeysCheck, UnitScaleCheck,
    VertexColoursCheck];
  for Check in Checks do
    Check.Enabled := not AIsGltf;
end;

function TGltfExportForm.GetOptions: TGltfExportOptions;
begin
  Result := TGltfExportOptions.Create;
  Result.Textures := TexturesCheck.IsChecked;
  Result.Skins := SkinsCheck.IsChecked;
  Result.Animations := AnimationsCheck.IsChecked;
  Result.ThinKeys := ThinKeysCheck.IsChecked;
  Result.ApplyUnitScale := UnitScaleCheck.IsChecked;
  Result.VertexColors := VertexColoursCheck.IsChecked;
end;

procedure TGltfExportForm.SetOptions(const AValue: TGltfExportOptions);
begin
  TexturesCheck.IsChecked := AValue.Textures;
  SkinsCheck.IsChecked := AValue.Skins;
  AnimationsCheck.IsChecked := AValue.Animations;
  ThinKeysCheck.IsChecked := AValue.ThinKeys;
  UnitScaleCheck.IsChecked := AValue.ApplyUnitScale;
  VertexColoursCheck.IsChecked := AValue.VertexColors;
end;

procedure TGltfExportForm.ExportButtonClick(Sender: TObject);
begin
  ModalResult := mrOk;
end;

procedure TGltfExportForm.CancelButtonClick(Sender: TObject);
begin
  ModalResult := mrCancel;
end;

end.
