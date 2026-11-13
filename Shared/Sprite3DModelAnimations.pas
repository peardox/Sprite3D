//** @abstract(Which of a model's animations move anything.)
//**
//** A model file can carry animations that move nothing: a take with no keys, or keys that
//** all hold one pose. Maya writes a take, @code(Take 001), into every FBX it exports,
//** animated or not, and a rigged character often carries its bind pose as one; Gorilla3D
//** loads each as an animation all the same, so a static prop would be counted, and
//** played, as animated. AnimationMoves tells the two apart from an animation's own keys,
//** the same way for every format and exporter, and StillAnimationsLeftOut drops the still
//** ones from a list of animation names.
//**
//** For the main thread, as Gorilla3D's models are.
unit Sprite3DModelAnimations;

{
  Which of a model's animations move anything.

  A model file can carry animations that move nothing: a take with no keys,
  or keys that all hold one pose. Maya writes a take, Take 001, into every
  FBX it exports, animated or not, and a rigged character often carries its
  bind pose as one; Gorilla3D loads each as an animation all the same, so a
  static prop would be counted, and played, as animated. AnimationMoves
  tells the two apart from an animation's own keys, the same way for every
  format and exporter, and StillAnimationsLeftOut drops the still ones from
  a list of animation names.

  For the main thread, as Gorilla3D's models are.
}

interface

uses
  System.SysUtils, Gorilla.DefTypes, Gorilla.Model;

//** @abstract(True if an animation moves anything: a key of one of its interpolators differs
//** from that interpolator's first by more than a hundred-thousandth in any number.)
//**
//** An animation with no stages, or whose keys all hold still, does not; an interpolator of a
//** kind not known here (not a matrix, point or quaternion one) is taken to move.
//**
//** @param(AAnimation The animation's definition; nil does not move.)
//**
//** @returns(Whether it moves anything.)
function AnimationMoves(const AAnimation: TAnimationDef): Boolean;

//** @abstract(How many of a model's animation definitions move anything; see AnimationMoves.)
//**
//** @param(AModel The model, loaded.)
//**
//** @param(AListed Set to how many it has, moving or not; 0 for a model with no definition
//** or none.)
//**
//** @returns(How many move.)
function MovingAnimations(const AModel: TGorillaModel; out AListed: Integer): Integer;

//** @abstract(ANames, a model's animations by name, without those that move nothing.)
//**
//** A name is matched to its definition by Id. One that matches none, as an animation
//** added from another file, is kept, unless the model's definitions have animations and
//** none of them moves: then the names are its still takes under other names, and none
//** is kept.
//**
//** @param(AModel The model, loaded.)
//**
//** @param(ANames Its animations' names, as Gorilla3D's animation manager gives them.)
//**
//** @returns(The names kept, in their order.)
function StillAnimationsLeftOut(const AModel: TGorillaModel;
  const ANames: TArray<String>): TArray<String>;

implementation

uses
  System.Types, System.Math.Vectors, System.Generics.Collections;

type
  // Whether an interpolator's keys differ: generic, as a key holds a matrix,
  // a point or a quaternion, each compared as its numbers
  TKeyCheck = class
    class function Differ<T>(const AKeys: TInterpolatorKeyDefList): Boolean; static;
  end;

class function TKeyCheck.Differ<T>(const AKeys: TInterpolatorKeyDefList): Boolean;
const
  // Well under any movement that shows, over the rounding of a still key
  TOLERANCE = 1E-5;
var
  First, Value: T;
  A, B: PSingle;
begin
  Result := False;
  if (AKeys = nil) or (AKeys.Count < 2) then
    Exit;
  First := TInterpolatorKeyDef<T>(AKeys[0]).Value;
  for var I := 1 to AKeys.Count - 1 do
  begin
    Value := TInterpolatorKeyDef<T>(AKeys[I]).Value;
    A := PSingle(@First);
    B := PSingle(@Value);
    for var N := 1 to SizeOf(T) div SizeOf(Single) do
    begin
      if Abs(A^ - B^) > TOLERANCE then
        Exit(True);
      Inc(A);
      Inc(B);
    end;
  end;
end;

function AnimationMoves(const AAnimation: TAnimationDef): Boolean;
begin
  Result := False;
  if (AAnimation = nil) or (AAnimation.Stages = nil) then
    Exit;
  for var Stage in AAnimation.Stages do
    if Stage.Interpolators <> nil then
      for var Interpolator in Stage.Interpolators do
      begin
        if Interpolator is TTransformationInterpolatorDef then
          Result := TKeyCheck.Differ<TMatrix3D>(TTransformationInterpolatorDef(Interpolator).Keys)
        else if Interpolator is TPoint3DInterpolatorDef then
          Result := TKeyCheck.Differ<TPoint3D>(TPoint3DInterpolatorDef(Interpolator).Keys)
        else if Interpolator is TQuaternion3DInterpolatorDef then
          Result := TKeyCheck.Differ<TQuaternion3D>(
            TQuaternion3DInterpolatorDef(Interpolator).Keys)
        else
          Result := True;
        if Result then
          Exit;
      end;
end;

// The model's definition, if it is a TModelDef, as a loaded model's is
function ModelDef(const AModel: TGorillaModel): TModelDef;
begin
  if (AModel <> nil) and (AModel.Def is TModelDef) then
    Result := TModelDef(AModel.Def)
  else
    Result := nil;
end;

function MovingAnimations(const AModel: TGorillaModel; out AListed: Integer): Integer;
var
  Def: TModelDef;
begin
  Result := 0;
  AListed := 0;
  Def := ModelDef(AModel);
  if (Def = nil) or (Def.Animations = nil) then
    Exit;
  AListed := Def.Animations.Count;
  for var Animation in Def.Animations do
    if AnimationMoves(Animation) then
      Inc(Result);
end;

function StillAnimationsLeftOut(const AModel: TGorillaModel;
  const ANames: TArray<String>): TArray<String>;
var
  Def: TModelDef;
  Moves: TDictionary<String, Boolean>;
  AnyMoves, Moving: Boolean;
  Count: Integer;
begin
  Def := ModelDef(AModel);
  if (Def = nil) or (Def.Animations = nil) or (Def.Animations.Count = 0) then
    Exit(ANames);
  Moves := TDictionary<String, Boolean>.Create;
  try
    AnyMoves := False;
    for var Animation in Def.Animations do
    begin
      Moving := AnimationMoves(Animation);
      AnyMoves := AnyMoves or Moving;
      Moves.AddOrSetValue(Animation.Id, Moving);
    end;
    SetLength(Result, Length(ANames));
    Count := 0;
    for var Name in ANames do
    begin
      if not Moves.TryGetValue(Name, Moving) then
        Moving := AnyMoves;
      if Moving then
      begin
        Result[Count] := Name;
        Inc(Count);
      end;
    end;
    SetLength(Result, Count);
  finally
    Moves.Free;
  end;
end;

end.
