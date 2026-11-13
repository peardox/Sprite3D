//** @abstract(What a loaded model holds, meshes, skins and animations, and the kind of model
//** that makes it: static, animated, rigged, rigged and animated, an animation library, or
//** empty.)
//**
//** ModelContent counts a TGorillaModel's definitions, as Gorilla3D loaded them, the same
//** way for every format: its meshes with vertex data and their vertices (as Sprite3D's
//** glTF export counts them), its animations, its skins (the controllers that have one) and
//** their joints. GuessModelKind makes a kind of it:
//**
//** @unorderedList(
//**   @item(@bold(Animation library): animations, and no mesh, or only a token one of
//**     fewer than TOKEN_MESH_VERTICES vertices; not to be placed, but to give its
//**     animations to rigged models.)
//**   @item(@bold(Empty): no mesh with vertices, and no animations: nothing to draw.)
//**   @item(@bold(Static): meshes, no animations, no skin: most level pieces.)
//**   @item(@bold(Rigged): meshes and a skin, no animations: takes its animations from a
//**     library.)
//**   @item(@bold(Animated): meshes and animations, no skin: a prop whose parts move, such
//**     as a chest's lid.)
//**   @item(@bold(Rigged and animated): meshes, a skin and animations of its own.))
//**
//** It is only a guess: an animation library that carries a mannequin looks rigged and
//** animated. The kinds' keys (ModelKindKey) are what the library database keeps.
//**
//** For the main thread only, as the model is.
unit Sprite3DModelContent;

{
  What a loaded model holds, meshes, skins and animations, and the kind of
  model that makes it.

  ModelContent counts a TGorillaModel's definitions the same way for every
  format: meshes with vertex data and their vertices, animations, skins
  (controllers with one) and their joints. GuessModelKind makes a kind of
  it: an animation library (animations, no mesh or a token one), empty
  (nothing to draw), static, rigged (a skin, no animations), animated
  (animations, no skin) or rigged and animated. Only a guess. Main thread.
}

interface

uses
  System.SysUtils, Gorilla.Model;

const
  //** @abstract(Below this many vertices in all, a model with animations is taken for an
  //** animation library carrying a token mesh, such as a marker or a single quad.)
  TOKEN_MESH_VERTICES = 64;

type
  //** @abstract(The kind of a model; see the unit's description.)
  TSprite3DModelKind = (
    //** @abstract(Not known: its content has not been counted.)
    mkUnknown,
    //** @abstract(Nothing to draw, and no animations.)
    mkEmpty,
    //** @abstract(Meshes, no animations, no skin.)
    mkStatic,
    //** @abstract(Meshes and animations, no skin.)
    mkAnimated,
    //** @abstract(Meshes and a skin, no animations.)
    mkRigged,
    //** @abstract(Meshes, a skin and animations of its own.)
    mkRiggedAnimated,
    //** @abstract(Animations, and no mesh or a token one.)
    mkAnimationLibrary);

  //** @abstract(What a model holds, as ModelContent counts it.)
  TSprite3DModelContent = record
    //** @abstract(Meshes with vertex data.)
    Meshes: Integer;
    //** @abstract(Their vertices, all together.)
    Vertices: Integer;
    //** @abstract(Animations that move something; a take whose keys all hold still, or that
    //** has none, as Maya leaves in every FBX it exports, is not counted.)
    Animations: Integer;
    //** @abstract(Skins: the controllers that have one.)
    Skins: Integer;
    //** @abstract(Joints, over every skin.)
    Joints: Integer;
  end;

//** @abstract(Counts what loaded model AModel holds.)
//**
//** @param(AModel The model, loaded; nil gives all zeros.)
//**
//** @returns(The counts.)
function ModelContent(const AModel: TGorillaModel): TSprite3DModelContent;

//** @abstract(The kind of model AContent makes, as the unit's description says.)
//**
//** @param(AContent What it holds.)
//**
//** @returns(The kind; never mkUnknown.)
function GuessModelKind(const AContent: TSprite3DModelContent): TSprite3DModelKind;

//** @abstract(Marks every mesh of a model's definition static, so the model keeps its
//** vertices on the GPU instead of having them sent every frame.)
//**
//** Gorilla's @code(IsStatic) on a mesh definition: only for a model whose meshes never
//** move, one GuessModelKind calls static, never one with a skin or animations. Call it
//** once the model is loaded and before it is first drawn, when its buffers are made.
//**
//** @param(AModel The loaded model whose definition is marked; nil, or one with no
//** definition, marks nothing.)
//**
//** @returns(How many mesh definitions were marked.)
function MarkMeshesStatic(const AModel: TGorillaModel): Integer;

//** @abstract(A kind's key, as the library database keeps it: @code(static),
//** @code(animated), @code(rigged), @code(rigged-animated), @code(animation-library),
//** @code(empty), or an empty string for mkUnknown.)
//**
//** @param(AKind The kind.)
//**
//** @returns(The key.)
function ModelKindKey(const AKind: TSprite3DModelKind): String;

//** @abstract(The kind whose key is AKey, case ignored.)
//**
//** @param(AKey A key, from ModelKindKey.)
//**
//** @returns(The kind; mkUnknown for an empty or unknown key.)
function ModelKindFromKey(const AKey: String): TSprite3DModelKind;

//** @abstract(A kind's name for people, such as @code(Rigged and animated).)
//**
//** @param(AKind The kind.)
//**
//** @returns(The name; @code(Not known yet) for mkUnknown.)
function ModelKindName(const AKind: TSprite3DModelKind): String;

//** @abstract(The short tag a model's tile shows for its kind, such as @code(RIG+ANIM);
//** empty for a static model, the usual kind, and for one not known.)
//**
//** @param(AKind The kind.)
//**
//** @returns(The tag.)
function ModelKindTag(const AKind: TSprite3DModelKind): String;

//** @abstract(What a model holds, for people: @code(2 meshes, 1,204 vertices, 1 skin of 24
//** joints, 12 animations).)
//**
//** @param(AContent What it holds.)
//**
//** @returns(The text.)
function ModelContentText(const AContent: TSprite3DModelContent): String;

implementation

uses
  Gorilla.DefTypes, Sprite3DModelAnimations;

const
  //** @abstract(The kinds' keys, in TSprite3DModelKind's order.)
  KIND_KEYS: array[TSprite3DModelKind] of String = ('', 'empty', 'static', 'animated',
    'rigged', 'rigged-animated', 'animation-library');
  //** @abstract(The kinds' names, in TSprite3DModelKind's order.)
  KIND_NAMES: array[TSprite3DModelKind] of String = ('Not known yet', 'Empty', 'Static',
    'Animated', 'Rigged', 'Rigged and animated', 'Animation library');
  //** @abstract(The kinds' tags, in TSprite3DModelKind's order.)
  KIND_TAGS: array[TSprite3DModelKind] of String = ('', 'EMPTY', '', 'ANIM', 'RIG',
    'RIG+ANIM', 'ANIM LIB');

//** @abstract(Adds the meshes under ADef, ADef among them, to ACounts: each mesh definition
//** with vertex data, but for the vertex groups that draw parts of one, as Sprite3D's glTF
//** export counts them.)
//**
//** @param(ADef The definition.)
//**
//** @param(ACounts The counts, added to.)
procedure CountMeshes(const ADef: TTransformDef; var ACounts: TSprite3DModelContent);
var
  Mesh: TCustomMeshDef;
begin
  if ADef = nil then
    Exit;
  if (ADef is TCustomMeshDef) and not (ADef is TVertexGroupDef) then
  begin
    Mesh := TCustomMeshDef(ADef);
    if (Mesh.VertexSource <> nil) and (Mesh.VertexSource.Length > 0) then
    begin
      Inc(ACounts.Meshes);
      Inc(ACounts.Vertices, Mesh.VertexSource.Length);
    end;
  end;
  if ADef.Children <> nil then
    for var Child in ADef.Children do
      if not (Child is TVertexGroupDef) then
        CountMeshes(Child, ACounts);
end;

function ModelContent(const AModel: TGorillaModel): TSprite3DModelContent;
var
  Def: TModelDef;
begin
  // Not Default(): Gorilla.DefTypes declares a Default of its own
  Result.Meshes := 0;
  Result.Vertices := 0;
  Result.Animations := 0;
  Result.Skins := 0;
  Result.Joints := 0;
  if AModel = nil then
    Exit;
  // TGorillaModel.Def is declared as a TCustomDef; a loaded model's is a
  // TModelDef
  if AModel.Def is TModelDef then
    Def := TModelDef(AModel.Def)
  else
    Def := nil;
  if Def <> nil then
  begin
    CountMeshes(Def, Result);
    // Only animations that move something (Sprite3DModelAnimations): an FBX
    // from Maya carries a take, "Take 001", whether or not anything was
    // animated, and a static prop counted it (PolygonDungeon, 12 November
    // 2026: 812 of 814 models)
    var Listed: Integer;
    Result.Animations := MovingAnimations(AModel, Listed);
    if Def.Controllers <> nil then
      for var Controller in Def.Controllers do
        if Controller.Skin <> nil then
        begin
          Inc(Result.Skins);
          if Controller.Skin.LinkedJoints <> nil then
            Inc(Result.Joints, Controller.Skin.LinkedJoints.Count);
        end;
  end;
  // Animations loaded apart from the definitions count too, but only where
  // the definitions have none: the manager holds the still takes as well
  if ((Def = nil) or (Def.Animations = nil) or (Def.Animations.Count = 0)) and
    (AModel.AnimationManager <> nil) and (AModel.AnimationManager.Animations <> nil) and
    (AModel.AnimationManager.Animations.Count > Result.Animations) then
    Result.Animations := AModel.AnimationManager.Animations.Count;
end;

//** @abstract(Marks ADef and every mesh definition under it static; see MarkMeshesStatic.)
//**
//** @param(ADef The definition.)
//**
//** @param(ACount Counts the meshes marked.)
procedure MarkStatic(const ADef: TTransformDef; var ACount: Integer);
begin
  if ADef = nil then
    Exit;
  if ADef is TMeshDef then
  begin
    TMeshDef(ADef).IsStatic := True;
    Inc(ACount);
  end;
  if ADef.Children <> nil then
    for var Child in ADef.Children do
      MarkStatic(Child, ACount);
end;

function MarkMeshesStatic(const AModel: TGorillaModel): Integer;
begin
  Result := 0;
  // TGorillaModel.Def is declared as a TCustomDef; a loaded model's is a
  // TModelDef
  if (AModel <> nil) and (AModel.Def is TModelDef) then
    MarkStatic(TModelDef(AModel.Def), Result);
end;

function GuessModelKind(const AContent: TSprite3DModelContent): TSprite3DModelKind;
begin
  if (AContent.Animations > 0) and (AContent.Vertices < TOKEN_MESH_VERTICES) then
    Result := mkAnimationLibrary
  else if AContent.Vertices = 0 then
    Result := mkEmpty
  else if AContent.Animations = 0 then
  begin
    if AContent.Skins > 0 then
      Result := mkRigged
    else
      Result := mkStatic;
  end
  else if AContent.Skins > 0 then
    Result := mkRiggedAnimated
  else
    Result := mkAnimated;
end;

function ModelKindKey(const AKind: TSprite3DModelKind): String;
begin
  Result := KIND_KEYS[AKind];
end;

function ModelKindFromKey(const AKey: String): TSprite3DModelKind;
begin
  if AKey <> String.Empty then
    for var Kind := Low(TSprite3DModelKind) to High(TSprite3DModelKind) do
      if SameText(KIND_KEYS[Kind], AKey) then
        Exit(Kind);
  Result := mkUnknown;
end;

function ModelKindName(const AKind: TSprite3DModelKind): String;
begin
  Result := KIND_NAMES[AKind];
end;

function ModelKindTag(const AKind: TSprite3DModelKind): String;
begin
  Result := KIND_TAGS[AKind];
end;

//** @abstract(A count with its word, such as 1 mesh or 1,204 vertices.)
//**
//** @param(ACount The count.)
//**
//** @param(AOne The word for one.)
//**
//** @param(AMany The word for any other count.)
//**
//** @returns(The text.)
function Counted(const ACount: Integer; const AOne, AMany: String): String;
begin
  if ACount = 1 then
    Result := '1 ' + AOne
  else
    Result := FormatFloat('#,##0', ACount) + ' ' + AMany;
end;

function ModelContentText(const AContent: TSprite3DModelContent): String;
begin
  Result := Counted(AContent.Meshes, 'mesh', 'meshes') + ', ' +
    Counted(AContent.Vertices, 'vertex', 'vertices');
  if AContent.Skins > 0 then
    Result := Result + ', ' + Counted(AContent.Skins, 'skin', 'skins') + ' of ' +
      Counted(AContent.Joints, 'joint', 'joints');
  Result := Result + ', ' + Counted(AContent.Animations, 'animation', 'animations');
end;

end.
