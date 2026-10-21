//** @abstract(Works out the volume a model sweeps as it turns about its up axis, for its rest
//** pose and each animation, and draws the one in use.)
//**
//** CalcSweptVolume takes a bounding box and the model's centre of rotation and works out the
//** space the box passes through in a full turn about a line through the centre of rotation,
//** parallel to one of the model's own axes: Y, the model's up axis, by default. That space is
//** a cylinder, or a thick-walled tube when the centre of rotation lies outside the box seen
//** along the axis. Its outer radius reaches the box's farthest corner and its inner radius
//** its nearest point; it is exactly as long as the box is along the axis. The swept box is
//** the box that encloses the tube, square across the axis and centred on it. The result is
//** a TSweptVolume, in the model's own coordinates. The box encloses the model, so the swept
//** volume encloses everything the model can reach as it turns, with room to spare where the
//** model does not fill its box.
//**
//** An animation moves the model's vertices, so it can reach outside the rest pose's box.
//** MeasureAnimationBounds steps each of the model's animations through every pose Gorilla
//** has baked for it and returns, per animation, the box that holds all of its poses. Each of
//** those boxes gives that animation's swept volume.
//**
//** FitCameraToSweep frames a swept volume with TSprite3DCamera.FitPointsOnAxis: it fills the
//** view on the tighter axis, with the orbit centre on the turning axis, through the model's
//** centre of rotation; the angles are left alone. CombinedSweptVolume
//** gives the volume to fit, joining the rest pose's with that of each animation named, so a
//** chosen subset of the animations can define it.
//**
//** ShowCombinedSweep adds a TCombinedSweep that draws one fixed volume, such as the one
//** CombinedSweptVolume gives, in fuchsia and hot pink, beside the per-animation sweep.
//**
//** ShowModelSweep adds a TModelSweep holding the rest pose's volume and one per animation.
//** Each frame it draws the volume of the animation the model is playing, or the rest pose's
//** when none is playing or the playing one was not measured, so the wireframe changes as
//** soon as another animation is played. It draws the swept box in aqua, and the tube's outer
//** and inner walls, with the axis itself, in yellow. The lines are drawn with the context's
//** DrawLine helper, following Gorilla v1.5's Line Rendering guide, with depth testing as
//** usual, so the model hides the parts behind it. Widths above 1 pixel work on desktop OpenGL
//** only; Vulkan, Metal and OpenGL ES always draw 1 pixel.
//**
//** The swept box is larger than the model's own box, and Gorilla counts a model's children in
//** its bounding box, so the TModelSweep is not a child of the model: it sits beside it, owned
//** by the model so it is freed with it, and draws with the model's matrix. The model's own
//** bounding box, ShowBoundingBox and the camera's fits are therefore unaffected. For the same
//** reason, measure the boxes before adding any helper that is a child of the model.
//**
//** @preformatted(
//** <model's parent>
//** |-- TGorillaModel     owns the TModelSweep, so frees it
//** `-- TModelSweep       one per model, found by FindModelSweep; draws the volume in use in
//**                       its Render with the model's AbsoluteMatrix
//** )
//**
//** Usage:
//**
//** @preformatted(
//** Box := GorillaModel1.GetBoundingBox@(@);            // before any helper is added
//** Anims := MeasureAnimationBounds@(GorillaModel1@);   // blocks; changes the pose meanwhile
//** Sweep := ShowModelSweep@(GorillaModel1, Box, Anims@);
//** if Sweep <> nil then
//**   Memo1.Lines.Add@(Sweep.Volume.ToString@);
//** HideModelSweep@(GorillaModel1@);
//** )
unit Sprite3DSweep;

{
  Works out the volume a model sweeps as it turns about its up axis, for its
  rest pose and each animation, and draws the one in use.

  CalcSweptVolume takes a bounding box and the model's centre of rotation and
  works out the space the box passes through in a full turn about a line
  through the centre of rotation, parallel to one of the model's own axes:
  Y, the model's up axis, by default. That space is a cylinder, or a
  thick-walled tube when the centre of rotation lies outside the box seen
  along the axis. Its outer radius reaches the box's farthest corner and its
  inner radius its nearest point; it is exactly as long as the box is along
  the axis. The swept box is the box that encloses the tube, square across
  the axis and centred on it. The result is a TSweptVolume, in the model's
  own coordinates. The box encloses the model, so the swept volume encloses
  everything the model can reach as it turns, with room to spare where the
  model does not fill its box.

  An animation moves the model's vertices, so it can reach outside the rest
  pose's box. MeasureAnimationBounds steps each of the model's animations
  through every pose Gorilla has baked for it and returns, per animation,
  the box that holds all of its poses. Each of those boxes gives that
  animation's swept volume.

  FitCameraToSweep frames a swept volume with TSprite3DCamera.FitPointsOnAxis:
  it fills the view on the tighter axis, with the orbit centre on the turning
  axis, through the model's centre of rotation; the angles are left alone.
  CombinedSweptVolume gives the volume to fit,
  joining the rest pose's with that of each animation named, so a chosen
  subset of the animations can define it.

  ShowCombinedSweep adds a TCombinedSweep that draws one fixed volume, such
  as the one CombinedSweptVolume gives, in fuchsia and hot pink, beside the
  per-animation sweep.

  ShowModelSweep adds a TModelSweep holding the rest pose's volume and one
  per animation. Each frame it draws the volume of the animation the model
  is playing, or the rest pose's when none is playing or the playing one was
  not measured, so the wireframe changes as soon as another animation is
  played. It draws the swept box in aqua, and the tube's outer and inner
  walls, with the axis itself, in yellow. The lines are drawn with the
  context's DrawLine helper, following Gorilla v1.5's Line Rendering guide,
  with depth testing as usual, so the model hides the parts behind it.
  Widths above 1 pixel work on desktop OpenGL only; Vulkan, Metal and
  OpenGL ES always draw 1 pixel.

  The swept box is larger than the model's own box, and Gorilla counts a
  model's children in its bounding box, so the TModelSweep is not a child of
  the model: it sits beside it, owned by the model so it is freed with it,
  and draws with the model's matrix. The model's own bounding box,
  ShowBoundingBox and the camera's fits are therefore unaffected. For the
  same reason, measure the boxes before adding any helper that is a child of
  the model.

    <model's parent>
    |-- TGorillaModel     owns the TModelSweep, so frees it
    `-- TModelSweep       one per model, found by FindModelSweep; draws the volume in use in
                          its Render with the model's AbsoluteMatrix

  Usage:
    Box := GorillaModel1.GetBoundingBox();            // before any helper is added
    Anims := MeasureAnimationBounds(GorillaModel1);   // blocks; changes the pose meanwhile
    Sweep := ShowModelSweep(GorillaModel1, Box, Anims);
    if Sweep <> nil then
      Memo1.Lines.Add(Sweep.Volume.ToString);
    HideModelSweep(GorillaModel1);
}

interface

uses
  System.Classes, System.SysUtils, System.UITypes, System.Math, System.Math.Vectors,
  System.Generics.Collections,
  FMX.Types, FMX.Types3D, FMX.Controls3D, FMX.Objects3D,
  Gorilla.Context, Gorilla.Context.Types, Gorilla.Model, Gorilla.Animation,
  Sprite3DCamera;

type
  //** @abstract(The model's own axis that the sweep turns about.)
  /// <summary>The model's own axis that the sweep turns about.</summary>
  TSweepAxis = (
    //** @abstract(The model's X axis.)
    /// <summary>The model's X axis.</summary>
    saX,
    //** @abstract(The model's Y axis, its up axis; the default.)
    /// <summary>The model's Y axis, its up axis; the default.</summary>
    saY,
    //** @abstract(The model's Z axis.)
    /// <summary>The model's Z axis.</summary>
    saZ);

  //** @abstract(The space a bounding box passes through in a full turn about an axis.)
  //**
  //** A tube round the axis, from InnerRadius to OuterRadius, running from AxialLow to
  //** AxialHigh along it; a solid cylinder when InnerRadius is 0. All values are in the
  //** model's own coordinates and units. Fill it with CalcSweptVolume. Across the axis the
  //** two other axes are taken in X, Y, Z order: X and Z for saY, Y and Z for saX, and X and
  //** Y for saZ.
  /// <summary>The space a bounding box passes through in a full turn about an axis.</summary>
  /// <remarks>A tube round the axis, from InnerRadius to OuterRadius, running from AxialLow to
  /// AxialHigh along it; a solid cylinder when InnerRadius is 0. All values are in the model's
  /// own coordinates and units. Fill it with <see cref="CalcSweptVolume"/>. Across the axis
  /// the two other axes are taken in X, Y, Z order: X and Z for saY, Y and Z for saX, and X
  /// and Y for saZ.</remarks>
  TSweptVolume = record
  public
    //** @abstract(False if the box it was worked out from was empty; nothing else is then
    //** set but Axis and Pivot.)
    /// <summary>False if the box it was worked out from was empty; nothing else is then set
    /// but Axis and Pivot.</summary>
    Valid: Boolean;
    //** @abstract(The model's axis that the turn is about.)
    /// <summary>The model's axis that the turn is about.</summary>
    Axis: TSweepAxis;
    //** @abstract(A point the turning axis passes through: the model's centre of rotation.)
    /// <summary>A point the turning axis passes through: the model's centre of
    /// rotation.</summary>
    Pivot: TPoint3D;
    //** @abstract(Where the volume starts along the axis: the box's lowest value on it.)
    /// <summary>Where the volume starts along the axis: the box's lowest value on it.</summary>
    AxialLow: Single;
    //** @abstract(Where the volume ends along the axis: the box's highest value on it.)
    /// <summary>Where the volume ends along the axis: the box's highest value on it.</summary>
    AxialHigh: Single;
    //** @abstract(The distance from the axis to the nearest point of the box; 0 when the
    //** axis passes through the box.)
    /// <summary>The distance from the axis to the nearest point of the box; 0 when the axis
    /// passes through the box.</summary>
    InnerRadius: Single;
    //** @abstract(The distance from the axis to the box's farthest corner.)
    /// <summary>The distance from the axis to the box's farthest corner.</summary>
    OuterRadius: Single;

    //** @abstract(How far the volume runs along the axis.)
    //**
    //** @returns(AxialHigh minus AxialLow; 0 if Valid is False.)
    /// <summary>How far the volume runs along the axis.</summary>
    /// <returns>AxialHigh minus AxialLow; 0 if Valid is False.</returns>
    function Length: Single;

    //** @abstract(The swept volume itself: the tube between the two radii.)
    //**
    //** @returns(Pi times the difference of the squared radii, times Length, in cubic model
    //** units; 0 if Valid is False.)
    /// <summary>The swept volume itself: the tube between the two radii.</summary>
    /// <returns>Pi times the difference of the squared radii, times Length, in cubic model
    /// units; 0 if Valid is False.</returns>
    function Volume: Single;

    //** @abstract(The volume of the swept box, which holds the whole tube, its hole
    //** included.)
    //**
    //** @returns(Twice OuterRadius, squared, times Length, in cubic model units; 0 if Valid is
    //** False.)
    /// <summary>The volume of the swept box, which holds the whole tube, its hole
    /// included.</summary>
    /// <returns>Twice OuterRadius, squared, times Length, in cubic model units; 0 if Valid is
    /// False.</returns>
    function BoxVolume: Single;

    //** @abstract(The swept box: the smallest box, square across the axis, that holds the
    //** tube.)
    //**
    //** It is centred on the axis, 2 times OuterRadius across it each way, and runs from
    //** AxialLow to AxialHigh along it. The box cannot show the tube's hole, so it also holds
    //** space round the axis that the model never reaches.
    //**
    //** @returns(The box in the model's own coordinates; meaningless if Valid is False.)
    /// <summary>The swept box: the smallest box, square across the axis, that holds the
    /// tube.</summary>
    /// <remarks>It is centred on the axis, 2 times OuterRadius across it each way, and runs
    /// from AxialLow to AxialHigh along it. The box cannot show the tube's hole, so it also
    /// holds space round the axis that the model never reaches.</remarks>
    /// <returns>The box in the model's own coordinates; meaningless if Valid is
    /// False.</returns>
    function Box: TBoundingBox;

    //** @abstract(A point given by where it is along the axis and how far it is off it.)
    //**
    //** @param(AAlong The point's value along the axis, as AxialLow and AxialHigh are given.)
    //**
    //** @param(AAcross1 Its offset from the axis along the first of the other two axes, in X,
    //** Y, Z order.)
    //**
    //** @param(AAcross2 Its offset from the axis along the second of the other two axes.)
    //**
    //** @returns(The point in the model's own coordinates.)
    /// <summary>A point given by where it is along the axis and how far it is off
    /// it.</summary>
    /// <param name="AAlong">The point's value along the axis, as AxialLow and AxialHigh are
    /// given.</param>
    /// <param name="AAcross1">Its offset from the axis along the first of the other two axes,
    /// in X, Y, Z order.</param>
    /// <param name="AAcross2">Its offset from the axis along the second of the other two
    /// axes.</param>
    /// <returns>The point in the model's own coordinates.</returns>
    function AxisPoint(const AAlong, AAcross1, AAcross2: Single): TPoint3D;

    //** @abstract(A one-line description for a log, with the radii, length, volumes and
    //** swept box size.)
    //**
    //** Numbers use the current locale's decimal separator, to 3 decimal places.
    //**
    //** @returns(The description, or a note that there was nothing to sweep if Valid is
    //** False.)
    /// <summary>A one-line description for a log, with the radii, length, volumes and swept
    /// box size.</summary>
    /// <remarks>Numbers use the current locale's decimal separator, to 3 decimal
    /// places.</remarks>
    /// <returns>The description, or a note that there was nothing to sweep if Valid is
    /// False.</returns>
    function ToString: String;
  end;

  //** @abstract(The box that holds every pose of one of a model's animations.)
  //**
  //** Made by MeasureAnimationBounds, in the model's own coordinates.
  /// <summary>The box that holds every pose of one of a model's animations.</summary>
  /// <remarks>Made by <see cref="MeasureAnimationBounds"/>, in the model's own
  /// coordinates.</remarks>
  TAnimationBounds = record
    //** @abstract(The animation's Id, as the model's AnimationManager names it.)
    /// <summary>The animation's Id, as the model's AnimationManager names it.</summary>
    Name: String;
    //** @abstract(The smallest box holding every pose measured.)
    /// <summary>The smallest box holding every pose measured.</summary>
    Box: TBoundingBox;
    //** @abstract(How many poses were measured.)
    /// <summary>How many poses were measured.</summary>
    Poses: Integer;
  end;

  //** @abstract(Draws, as a wireframe beside its model, the swept volume of the animation
  //** the model is playing, or of its rest pose.)
  //**
  //** A TDummy holding Volume, for the rest pose, and a volume per animation, set with
  //** SetAnimationVolume. In its own Render, in the main pass only, it picks the volume in
  //** use: that of the animation the model is playing, by its Id, if the animation is running
  //** and has a volume; otherwise Volume. It draws that volume's swept box in BoxColor and, in
  //** SweepColor, the tube's outer wall, its inner wall when it has one, and the axis. Each
  //** wall is a ring of Segments lines at each end, joined by four lines along the axis. The
  //** lines are worked out again only when the volume in use changes or a setting does.
  //**
  //** It belongs beside Model, under the same parent, not inside it, so it never counts in
  //** Model's bounding box. Each Render it draws with Model's AbsoluteMatrix, so the lines
  //** follow the model wherever it moves, turns or is scaled; it also copies Model's
  //** position, rotation, scale and centre of rotation to itself, and sets its own Width,
  //** Height and Depth to cover the lines, so anything that culls by an object's size sees
  //** them all. Nothing is drawn while Model is nil or hidden, or the volume in use is not
  //** Valid.
  //**
  //** The object is not stored in .fmx files and ignores the mouse. Use it from the main
  //** thread only. ShowModelSweep creates and places one.
  /// <summary>Draws, as a wireframe beside its model, the swept volume of the animation the
  /// model is playing, or of its rest pose.</summary>
  /// <remarks><para>A TDummy holding Volume, for the rest pose, and a volume per animation,
  /// set with SetAnimationVolume. In its own Render, in the main pass only, it picks the
  /// volume in use: that of the animation the model is playing, by its Id, if the animation is
  /// running and has a volume; otherwise Volume. It draws that volume's swept box in BoxColor
  /// and, in SweepColor, the tube's outer wall, its inner wall when it has one, and the axis.
  /// Each wall is a ring of Segments lines at each end, joined by four lines along the axis.
  /// The lines are worked out again only when the volume in use changes or a setting
  /// does.</para>
  /// <para>It belongs beside Model, under the same parent, not inside it, so it never counts
  /// in Model's bounding box. Each Render it draws with Model's AbsoluteMatrix, so the lines
  /// follow the model wherever it moves, turns or is scaled; it also copies Model's position,
  /// rotation, scale and centre of rotation to itself, and sets its own Width, Height and
  /// Depth to cover the lines, so anything that culls by an object's size sees them all.
  /// Nothing is drawn while Model is nil or hidden, or the volume in use is not
  /// Valid.</para>
  /// <para>The object is not stored in .fmx files and ignores the mouse. Use it from the main
  /// thread only. <see cref="ShowModelSweep"/> creates and places one.</para></remarks>
  TModelSweep = class(TDummy)
  private
    FModel: TGorillaModel;
    FVolume: TSweptVolume;
    FAnimations: TDictionary<String, TSweptVolume>;
    FActive: TSweptVolume;
    FActiveName: String;
    FLinesValid: Boolean;
    FBoxColor: TAlphaColor;
    FSweepColor: TAlphaColor;
    FLineWidth: Single;
    FSegments: Integer;
    FBoxLines: TArray<TPoint3D>;     // pairs of end points, model coordinates
    FSweepLines: TArray<TPoint3D>;   // pairs of end points, model coordinates
    function PlayingName: String;
    procedure UpdateActive;
    procedure BuildLines;
    procedure SyncToModel;
    procedure DrawLines;
    procedure SetModel(const Value: TGorillaModel);
    procedure SetVolume(const Value: TSweptVolume);
    procedure SetBoxColor(const Value: TAlphaColor);
    procedure SetSweepColor(const Value: TAlphaColor);
    procedure SetLineWidth(const Value: Single);
    procedure SetSegments(const Value: Integer);
    function GetActiveVolume: TSweptVolume;
    function GetActiveAnimation: String;
  protected
    //** @abstract(Draws the volume in use with the model's matrix, in the main pass only.)
    //**
    //** Copies Model's transform to this object if it changed, picks the volume in use and
    //** works its lines out if it changed, then, if Model is visible and that volume is
    //** Valid, draws the lines with the context matrix set to Model's AbsoluteMatrix,
    //** restoring the previous matrix and line state afterwards, even if drawing fails. Does
    //** nothing in Gorilla's shadow, reflection and other passes.
    /// <summary>Draws the volume in use with the model's matrix, in the main pass
    /// only.</summary>
    /// <remarks>Copies Model's transform to this object if it changed, picks the volume in use
    /// and works its lines out if it changed, then, if Model is visible and that volume is
    /// Valid, draws the lines with the context matrix set to Model's AbsoluteMatrix, restoring
    /// the previous matrix and line state afterwards, even if drawing fails. Does nothing in
    /// Gorilla's shadow, reflection and other passes.</remarks>
    procedure Render; override;

    //** @abstract(Forgets Model if it is freed first.)
    //**
    //** @param(AComponent The component being freed or removed.)
    //**
    //** @param(Operation What is happening to it.)
    /// <summary>Forgets Model if it is freed first.</summary>
    /// <param name="AComponent">The component being freed or removed.</param>
    /// <param name="Operation">What is happening to it.</param>
    procedure Notification(AComponent: TComponent; Operation: TOperation); override;
  public
    //** @abstract(Creates an empty sweep: no model, no volumes, aqua and yellow lines 1 pixel
    //** wide, 64 segments to a ring.)
    //**
    //** Nothing is drawn until Model and a Valid volume are set.
    //**
    //** @param(AOwner The owner, normally the model, so the sweep is freed with it; or nil to
    //** leave freeing to the parent.)
    /// <summary>Creates an empty sweep: no model, no volumes, aqua and yellow lines 1 pixel
    /// wide, 64 segments to a ring.</summary>
    /// <remarks>Nothing is drawn until Model and a Valid volume are set.</remarks>
    /// <param name="AOwner">The owner, normally the model, so the sweep is freed with it; or
    /// nil to leave freeing to the parent.</param>
    constructor Create(AOwner: TComponent); override;

    //** @abstract(Frees the sweep and its animation volumes.)
    /// <summary>Frees the sweep and its animation volumes.</summary>
    destructor Destroy; override;

    //** @abstract(Gives an animation its swept volume, replacing any it had.)
    //**
    //** While the model plays the animation whose Id is AName, AVolume is drawn instead of
    //** Volume. Redraws.
    //**
    //** @param(AName The animation's Id; names are compared exactly.)
    //**
    //** @param(AVolume Its volume, in the model's own coordinates; one that is not Valid is
    //** stored but never drawn.)
    /// <summary>Gives an animation its swept volume, replacing any it had.</summary>
    /// <remarks>While the model plays the animation whose Id is AName, AVolume is drawn
    /// instead of Volume. Redraws.</remarks>
    /// <param name="AName">The animation's Id; names are compared exactly.</param>
    /// <param name="AVolume">Its volume, in the model's own coordinates; one that is not Valid
    /// is stored but never drawn.</param>
    procedure SetAnimationVolume(const AName: String; const AVolume: TSweptVolume);

    //** @abstract(Removes every animation's volume, so only Volume is drawn.)
    /// <summary>Removes every animation's volume, so only Volume is drawn.</summary>
    procedure ClearAnimationVolumes;

    //** @abstract(Looks up the volume given to an animation.)
    //**
    //** @param(AName The animation's Id.)
    //**
    //** @param(AVolume The volume, if there is one; otherwise undefined.)
    //**
    //** @returns(True if AName has a volume.)
    /// <summary>Looks up the volume given to an animation.</summary>
    /// <param name="AName">The animation's Id.</param>
    /// <param name="AVolume">The volume, if there is one; otherwise undefined.</param>
    /// <returns>True if AName has a volume.</returns>
    function TryGetAnimationVolume(const AName: String; out AVolume: TSweptVolume): Boolean;

    //** @abstract(The model whose matrix the lines are drawn with and whose playing animation
    //** picks the volume; nil draws nothing.)
    //**
    //** Not owned. If it is freed first the sweep forgets it. Give this object the same
    //** parent as the model.
    /// <summary>The model whose matrix the lines are drawn with and whose playing animation
    /// picks the volume; nil draws nothing.</summary>
    /// <remarks>Not owned. If it is freed first the sweep forgets it. Give this object the
    /// same parent as the model.</remarks>
    property Model: TGorillaModel read FModel write SetModel;
    //** @abstract(The rest pose's volume, drawn when no animation with a volume is playing.)
    //**
    //** In Model's own coordinates. Setting it redraws.
    /// <summary>The rest pose's volume, drawn when no animation with a volume is
    /// playing.</summary>
    /// <remarks>In Model's own coordinates. Setting it redraws.</remarks>
    property Volume: TSweptVolume read FVolume write SetVolume;
    //** @abstract(The volume drawn now: the playing animation's, or Volume.)
    //**
    //** Worked out from the model's animation at the time of reading, as Render does.
    /// <summary>The volume drawn now: the playing animation's, or Volume.</summary>
    /// <remarks>Worked out from the model's animation at the time of reading, as Render
    /// does.</remarks>
    property ActiveVolume: TSweptVolume read GetActiveVolume;
    //** @abstract(The Id of the animation whose volume is drawn now; empty for Volume.)
    /// <summary>The Id of the animation whose volume is drawn now; empty for Volume.</summary>
    property ActiveAnimation: String read GetActiveAnimation;
    //** @abstract(Colour of the swept box; aqua by default.)
    /// <summary>Colour of the swept box; aqua by default.</summary>
    property BoxColor: TAlphaColor read FBoxColor write SetBoxColor;
    //** @abstract(Colour of the tube's walls and the axis; yellow by default.)
    /// <summary>Colour of the tube's walls and the axis; yellow by default.</summary>
    property SweepColor: TAlphaColor read FSweepColor write SetSweepColor;
    //** @abstract(Line width in screen pixels; 1 by default.)
    //**
    //** Values above 1 work on desktop OpenGL only; Vulkan, Metal and OpenGL ES always draw 1
    //** pixel. Values below 1 count as 1.
    /// <summary>Line width in screen pixels; 1 by default.</summary>
    /// <remarks>Values above 1 work on desktop OpenGL only; Vulkan, Metal and OpenGL ES always
    /// draw 1 pixel. Values below 1 count as 1.</remarks>
    property LineWidth: Single read FLineWidth write SetLineWidth;
    //** @abstract(Lines in each ring; 64 by default.)
    //**
    //** More look rounder and cost more to draw. Values below 8 count as 8.
    /// <summary>Lines in each ring; 64 by default.</summary>
    /// <remarks>More look rounder and cost more to draw. Values below 8 count as 8.</remarks>
    property Segments: Integer read FSegments write SetSegments;
  end;

  //** @abstract(Draws one fixed swept volume, such as the combined one, in its own colours.)
  //**
  //** A TModelSweep that is given only Volume, so it draws that volume whatever animation the
  //** model plays. Its box is fuchsia and its tube and axis hot pink, so it can be told apart
  //** from the per-animation sweep when both are shown. ShowCombinedSweep creates and places
  //** one; it is found separately from the per-animation sweep, so a model can have one of
  //** each.
  /// <summary>Draws one fixed swept volume, such as the combined one, in its own
  /// colours.</summary>
  /// <remarks>A TModelSweep that is given only Volume, so it draws that volume whatever
  /// animation the model plays. Its box is fuchsia and its tube and axis hot pink, so it can be
  /// told apart from the per-animation sweep when both are shown.
  /// <see cref="ShowCombinedSweep"/> creates and places one; it is found separately from the
  /// per-animation sweep, so a model can have one of each.</remarks>
  TCombinedSweep = class(TModelSweep)
  public
    //** @abstract(Creates an empty sweep, as TModelSweep does, in fuchsia and hot pink.)
    //**
    //** @param(AOwner The owner, normally the model, so the sweep is freed with it.)
    /// <summary>Creates an empty sweep, as TModelSweep does, in fuchsia and hot
    /// pink.</summary>
    /// <param name="AOwner">The owner, normally the model, so the sweep is freed with
    /// it.</param>
    constructor Create(AOwner: TComponent); override;
  end;

//** @abstract(Works out the space a bounding box passes through in a full turn about an
//** axis.)
//**
//** The turn is about the line through APivot parallel to the model's AAxis. Seen along that
//** axis the box is a rectangle: OuterRadius is the distance from the axis to its farthest
//** corner and InnerRadius to its nearest point, 0 if the axis passes through it. The volume
//** runs along the axis exactly as far as the box does. Pure arithmetic; any thread.
//**
//** @param(ABox The box, in the model's own coordinates. Measure it before any helper is added
//** to the model as a child, as Gorilla counts children in its bounds.)
//**
//** @param(APivot A point the axis passes through, normally the model's centre of rotation,
//** @code(RotationCenter.Point), in the same coordinates.)
//**
//** @param(AAxis Which of the model's axes the turn is parallel to; Y, its up axis, by
//** default.)
//**
//** @returns(The swept volume; Valid is False if ABox is empty, with a minimum above its
//** maximum on any axis.)
/// <summary>Works out the space a bounding box passes through in a full turn about an
/// axis.</summary>
/// <remarks>The turn is about the line through APivot parallel to the model's AAxis. Seen
/// along that axis the box is a rectangle: OuterRadius is the distance from the axis to its
/// farthest corner and InnerRadius to its nearest point, 0 if the axis passes through it. The
/// volume runs along the axis exactly as far as the box does. Pure arithmetic; any
/// thread.</remarks>
/// <param name="ABox">The box, in the model's own coordinates. Measure it before any helper is
/// added to the model as a child, as Gorilla counts children in its bounds.</param>
/// <param name="APivot">A point the axis passes through, normally the model's centre of
/// rotation, <c>RotationCenter.Point</c>, in the same coordinates.</param>
/// <param name="AAxis">Which of the model's axes the turn is parallel to; Y, its up axis, by
/// default.</param>
/// <returns>The swept volume; Valid is False if ABox is empty, with a minimum above its
/// maximum on any axis.</returns>
function CalcSweptVolume(const ABox: TBoundingBox; const APivot: TPoint3D;
  const AAxis: TSweepAxis = saY): TSweptVolume;

//** @abstract(Measures, for each of AModel's animations, the box that holds all its poses.)
//**
//** Each animation in turn is made current and stepped, with TSprite3DAnimationFrames, through
//** one cycle at the rate Gorilla baked its poses, 30 frames a second if it baked none, and
//** after each step the model's GetAnimatedBoundingBox is added to that animation's box. The
//** animation that was current before is made current again afterwards, running or stopped
//** as it was; the others are left stopped. The model's pose changes while this runs, and is
//** wherever the restored animation puts it afterwards.
//**
//** Blocks for as long as the stepping takes: the number of poses times the cost of one
//** bounding box. Do not call it while something else drives the animations, such as a
//** capture. Gorilla counts a model's children in its animated bounds, so call it before
//** adding any helper to AModel as a child. Main thread only.
//**
//** An animation whose poses Gorilla did not bake is posed by seeking its skeleton; on Delphi
//** 13 and later that pose is only evaluated when a frame is drawn, so such an animation's box
//** may be that of the pose already showing. Sprite3D loads models with vertex caching, so
//** its animations are baked.
//**
//** @param(AModel The model; nil, or one with no animations, gives an empty array.)
//**
//** @returns(One entry per animation that gave a non-empty box, in the order
//** @code(GetSortedAnimations) gives them.)
/// <summary>Measures, for each of AModel's animations, the box that holds all its
/// poses.</summary>
/// <remarks><para>Each animation in turn is made current and stepped, with
/// TSprite3DAnimationFrames, through one cycle at the rate Gorilla baked its poses, 30 frames
/// a second if it baked none, and after each step the model's GetAnimatedBoundingBox is added
/// to that animation's box. The animation that was current before is made current again
/// afterwards, running or stopped as it was; the others are left stopped. The model's pose
/// changes while this runs, and is wherever the restored animation puts it
/// afterwards.</para>
/// <para>Blocks for as long as the stepping takes: the number of poses times the cost of one
/// bounding box. Do not call it while something else drives the animations, such as a
/// capture. Gorilla counts a model's children in its animated bounds, so call it before adding
/// any helper to AModel as a child. Main thread only.</para>
/// <para>An animation whose poses Gorilla did not bake is posed by seeking its skeleton; on
/// Delphi 13 and later that pose is only evaluated when a frame is drawn, so such an
/// animation's box may be that of the pose already showing. Sprite3D loads models with vertex
/// caching, so its animations are baked.</para></remarks>
/// <param name="AModel">The model; nil, or one with no animations, gives an empty
/// array.</param>
/// <returns>One entry per animation that gave a non-empty box, in the order
/// <c>GetSortedAnimations</c> gives them.</returns>
function MeasureAnimationBounds(const AModel: TGorillaModel): TArray<TAnimationBounds>;

//** @abstract(The smallest swept volume that holds every valid volume given.)
//**
//** The volumes must turn about the same axis through the same pivot, as those worked out
//** for one model are; the result takes both from the first valid volume. Its length runs
//** from the lowest AxialLow to the highest AxialHigh, its outer radius is the largest and
//** its inner radius the smallest. Where the volumes differ in length the result is a little
//** larger than their union, never smaller. Pure arithmetic; any thread.
//**
//** @param(AVolumes The volumes; those that are not Valid are skipped.)
//**
//** @returns(The combined volume; Valid is False if none of AVolumes is Valid.)
/// <summary>The smallest swept volume that holds every valid volume given.</summary>
/// <remarks>The volumes must turn about the same axis through the same pivot, as those worked
/// out for one model are; the result takes both from the first valid volume. Its length runs
/// from the lowest AxialLow to the highest AxialHigh, its outer radius is the largest and its
/// inner radius the smallest. Where the volumes differ in length the result is a little
/// larger than their union, never smaller. Pure arithmetic; any thread.</remarks>
/// <param name="AVolumes">The volumes; those that are not Valid are skipped.</param>
/// <returns>The combined volume; Valid is False if none of AVolumes is Valid.</returns>
function UnionSweptVolume(const AVolumes: array of TSweptVolume): TSweptVolume;

//** @abstract(The swept volume of a model over its rest pose and a chosen set of its
//** animations.)
//**
//** Works out the rest pose's volume from ABox and each chosen animation's from its entry in
//** AAnimations, all about the line through @code(AModel.RotationCenter) parallel to AAxis,
//** and combines them with UnionSweptVolume. Only the animations named in ANames are
//** included, so a fit can be made for a subset of them; pass every Id for all of them, and
//** none for the rest pose alone. A name with no entry in AAnimations is skipped. Main thread
//** only, as it reads AModel.
//**
//** @param(AModel The model; nil gives a volume that is not Valid.)
//**
//** @param(ABox AModel's own bounds at rest, measured before any helper was added to it as a
//** child.)
//**
//** @param(AAnimations The boxes MeasureAnimationBounds gave for AModel's animations; may be
//** empty.)
//**
//** @param(ANames The Ids of the animations to include; empty for none.)
//**
//** @param(AIncludeRest Whether the rest pose's volume is included.)
//**
//** @param(AAxis Which of the model's axes it turns about; Y, its up axis, by default.)
//**
//** @returns(The combined volume; Valid is False if nothing chosen gave a box.)
/// <summary>The swept volume of a model over its rest pose and a chosen set of its
/// animations.</summary>
/// <remarks>Works out the rest pose's volume from ABox and each chosen animation's from its
/// entry in AAnimations, all about the line through <c>AModel.RotationCenter</c> parallel to
/// AAxis, and combines them with <see cref="UnionSweptVolume"/>. Only the animations named in
/// ANames are included, so a fit can be made for a subset of them; pass every Id for all of
/// them, and none for the rest pose alone. A name with no entry in AAnimations is skipped.
/// Main thread only, as it reads AModel.</remarks>
/// <param name="AModel">The model; nil gives a volume that is not Valid.</param>
/// <param name="ABox">AModel's own bounds at rest, measured before any helper was added to it
/// as a child.</param>
/// <param name="AAnimations">The boxes <see cref="MeasureAnimationBounds"/> gave for AModel's
/// animations; may be empty.</param>
/// <param name="ANames">The Ids of the animations to include; empty for none.</param>
/// <param name="AIncludeRest">Whether the rest pose's volume is included.</param>
/// <param name="AAxis">Which of the model's axes it turns about; Y, its up axis, by
/// default.</param>
/// <returns>The combined volume; Valid is False if nothing chosen gave a box.</returns>
function CombinedSweptVolume(const AModel: TGorillaModel; const ABox: TBoundingBox;
  const AAnimations: TArray<TAnimationBounds>; const ANames: TArray<String>;
  const AIncludeRest: Boolean = True; const AAxis: TSweepAxis = saY): TSweptVolume;

//** @abstract(Points whose convex hull holds the whole of a swept volume.)
//**
//** Two rings of ASegments points, one at each end of the volume, on a regular polygon drawn
//** round the outer circle rather than inside it, so the polygon, and every view of it, holds
//** the circle. From any direction the volume's outline is that of its two end circles, so
//** these points are all a camera fit needs. Pure arithmetic; any thread.
//**
//** @param(AVolume The volume, in the model's own coordinates.)
//**
//** @param(ASegments Points in each ring; values below 8 count as 8. 64 makes the polygon at
//** most 0.12% wider than the circle.)
//**
//** @returns(2 times ASegments points in the model's own coordinates; empty if AVolume is not
//** Valid.)
/// <summary>Points whose convex hull holds the whole of a swept volume.</summary>
/// <remarks>Two rings of ASegments points, one at each end of the volume, on a regular polygon
/// drawn round the outer circle rather than inside it, so the polygon, and every view of it,
/// holds the circle. From any direction the volume's outline is that of its two end circles,
/// so these points are all a camera fit needs. Pure arithmetic; any thread.</remarks>
/// <param name="AVolume">The volume, in the model's own coordinates.</param>
/// <param name="ASegments">Points in each ring; values below 8 count as 8. 64 makes the polygon
/// at most 0.12% wider than the circle.</param>
/// <returns>2 times ASegments points in the model's own coordinates; empty if AVolume is not
/// Valid.</returns>
function SweepOutline(const AVolume: TSweptVolume;
  const ASegments: Integer = 64): TArray<TPoint3D>;

//** @abstract(Frames a model's swept volume as large as it will go, with the orbit centre on
//** its turning axis.)
//**
//** The volume's outline, by SweepOutline, is framed with @code(ACamera.FitPointsOnAxis): as
//** large as it will go for the current angles, centred, so it reaches both edges of the
//** tighter axis, with the orbit centre then put on the turning axis, the line through the
//** model's centre of rotation, carried through AModel's transform. Azimuth, PolarAngle and
//** Roll are not changed. The volume holds the model in every turn about its axis, so turning
//** the model about that axis, or the camera's azimuth about it when the two axes are
//** parallel, never takes the model out of view; nor does any animation whose bounds the
//** volume includes. Main thread only.
//**
//** @param(ACamera The camera to fit; nil makes the call return False.)
//**
//** @param(AModel The model the volume belongs to; its transform carries the volume into the
//** scene. Nil makes the call return False.)
//**
//** @param(AVolume The volume, in AModel's own coordinates, such as one from
//** CombinedSweptVolume.)
//**
//** @param(AMargin Padding as a fraction of the view: 0.1 makes the volume 1/1.1 of the view
//** on the tighter axis.)
//**
//** @returns(True if the volume was framed; False, with nothing changed, if ACamera or AModel
//** is nil, AVolume is not Valid, the camera is locked, there is no viewport, or it has zero
//** width or height.)
/// <summary>Frames a model's swept volume as large as it will go, with the orbit centre on
/// its turning axis.</summary>
/// <remarks>The volume's outline, by <see cref="SweepOutline"/>, is framed with
/// <c>ACamera.FitPointsOnAxis</c>: as large as it will go for the current angles, centred, so
/// it reaches both edges of the tighter axis, with the orbit centre then put on the turning
/// axis, the line through the model's centre of rotation, carried through AModel's transform.
/// Azimuth, PolarAngle and Roll are not changed. The volume holds the model in every turn
/// about its axis, so turning the model about that axis, or the camera's azimuth about it when
/// the two axes are parallel, never takes the model out of view; nor does any animation whose
/// bounds the volume includes. Main thread only.</remarks>
/// <param name="ACamera">The camera to fit; nil makes the call return False.</param>
/// <param name="AModel">The model the volume belongs to; its transform carries the volume into
/// the scene. Nil makes the call return False.</param>
/// <param name="AVolume">The volume, in AModel's own coordinates, such as one from
/// <see cref="CombinedSweptVolume"/>.</param>
/// <param name="AMargin">Padding as a fraction of the view: 0.1 makes the volume 1/1.1 of the
/// view on the tighter axis.</param>
/// <returns>True if the volume was framed; False, with nothing changed, if ACamera or AModel is
/// nil, AVolume is not Valid, the camera is locked, there is no viewport, or it has zero width
/// or height.</returns>
function FitCameraToSweep(const ACamera: TSprite3DCamera; const AModel: TControl3D;
  const AVolume: TSweptVolume; const AMargin: Single = 0): Boolean; overload;

//** @abstract(Frames a model's swept volume for an explicit view size.)
//**
//** As the other FitCameraToSweep, for a view of AViewWidth by AViewHeight instead of the
//** viewport's size; only their ratio matters. Use it for an off-screen target whose shape
//** differs from the viewport's.
//**
//** @param(ACamera The camera to fit; nil makes the call return False.)
//**
//** @param(AModel The model the volume belongs to; nil makes the call return False.)
//**
//** @param(AVolume The volume, in AModel's own coordinates.)
//**
//** @param(AViewWidth The width of the view, in the same units as AViewHeight.)
//**
//** @param(AViewHeight The height of the view, in the same units as AViewWidth.)
//**
//** @param(AMargin Padding as a fraction of the view: 0.1 makes the volume 1/1.1 of the view
//** on the tighter axis.)
//**
//** @returns(True if the volume was framed; False, with nothing changed, if ACamera or AModel
//** is nil, AVolume is not Valid, the camera is locked, or either size is zero or less.)
/// <summary>Frames a model's swept volume for an explicit view size.</summary>
/// <remarks>As the other FitCameraToSweep, for a view of AViewWidth by AViewHeight instead of
/// the viewport's size; only their ratio matters. Use it for an off-screen target whose shape
/// differs from the viewport's.</remarks>
/// <param name="ACamera">The camera to fit; nil makes the call return False.</param>
/// <param name="AModel">The model the volume belongs to; nil makes the call return
/// False.</param>
/// <param name="AVolume">The volume, in AModel's own coordinates.</param>
/// <param name="AViewWidth">The width of the view, in the same units as AViewHeight.</param>
/// <param name="AViewHeight">The height of the view, in the same units as AViewWidth.</param>
/// <param name="AMargin">Padding as a fraction of the view: 0.1 makes the volume 1/1.1 of the
/// view on the tighter axis.</param>
/// <returns>True if the volume was framed; False, with nothing changed, if ACamera or AModel is
/// nil, AVolume is not Valid, the camera is locked, or either size is zero or less.</returns>
function FitCameraToSweep(const ACamera: TSprite3DCamera; const AModel: TControl3D;
  const AVolume: TSweptVolume; const AViewWidth, AViewHeight: Single;
  const AMargin: Single = 0): Boolean; overload;

//** @abstract(Draws the volume AModel sweeps in a full turn about its up axis, at rest and
//** in each animation.)
//**
//** Any sweep already on AModel is removed first, so calling it again, for example after
//** loading a different model, redraws it for the new bounds. The volumes are worked out by
//** CalcSweptVolume, about the line through @code(AModel.RotationCenter) parallel to AAxis:
//** the rest pose's from ABox, and each animation's from its entry in AAnimations. While
//** AModel plays one of those animations its volume is drawn; otherwise the rest pose's. The
//** TModelSweep is owned by AModel, so it is freed with it, and placed beside it, under
//** AModel's parent. The volumes are worked out at the time of the call; call again if the
//** centre of rotation changes. Call from the main thread only.
//**
//** @param(AModel The model to sweep. Nothing happens if it is nil or has no parent.)
//**
//** @param(ABox AModel's own bounds at rest, in its own coordinates, measured before any
//** helper was added to it as a child.)
//**
//** @param(AAnimations The boxes MeasureAnimationBounds gave for AModel's animations; may be
//** empty.)
//**
//** @param(AAxis Which of the model's axes it turns about; Y, its up axis, by default.)
//**
//** @returns(The new sweep, owned by AModel; or nil, with nothing added, if AModel is nil or
//** has no parent, or ABox is empty and no animation gave a box.)
//**
//** @seealso(HideModelSweep)
//**
//** @seealso(FindModelSweep)
/// <summary>Draws the volume AModel sweeps in a full turn about its up axis, at rest and in
/// each animation.</summary>
/// <remarks><para>Any sweep already on AModel is removed first, so calling it again, for
/// example after loading a different model, redraws it for the new bounds. The volumes are
/// worked out by <see cref="CalcSweptVolume"/>, about the line through
/// <c>AModel.RotationCenter</c> parallel to AAxis: the rest pose's from ABox, and each
/// animation's from its entry in AAnimations. While AModel plays one of those animations its
/// volume is drawn; otherwise the rest pose's. The TModelSweep is owned by AModel, so it is
/// freed with it, and placed beside it, under AModel's parent.</para>
/// <para>The volumes are worked out at the time of the call; call again if the centre of
/// rotation changes. Call from the main thread only.</para></remarks>
/// <param name="AModel">The model to sweep. Nothing happens if it is nil or has no
/// parent.</param>
/// <param name="ABox">AModel's own bounds at rest, in its own coordinates, measured before any
/// helper was added to it as a child.</param>
/// <param name="AAnimations">The boxes <see cref="MeasureAnimationBounds"/> gave for AModel's
/// animations; may be empty.</param>
/// <param name="AAxis">Which of the model's axes it turns about; Y, its up axis, by
/// default.</param>
/// <returns>The new sweep, owned by AModel; or nil, with nothing added, if AModel is nil or
/// has no parent, or ABox is empty and no animation gave a box.</returns>
/// <seealso cref="HideModelSweep"/>
/// <seealso cref="FindModelSweep"/>
function ShowModelSweep(const AModel: TGorillaModel; const ABox: TBoundingBox;
  const AAnimations: TArray<TAnimationBounds>;
  const AAxis: TSweepAxis = saY): TModelSweep; overload;

//** @abstract(Draws the volume AModel sweeps in a full turn about its up axis, at rest
//** only.)
//**
//** As the other ShowModelSweep with no animation boxes, so the rest pose's volume is drawn
//** whatever AModel plays.
//**
//** @param(AModel The model to sweep. Nothing happens if it is nil or has no parent.)
//**
//** @param(ABox AModel's own bounds at rest, in its own coordinates, measured before any
//** helper was added to it as a child.)
//**
//** @param(AAxis Which of the model's axes it turns about; Y, its up axis, by default.)
//**
//** @returns(The new sweep, owned by AModel; or nil, with nothing added, if AModel is nil or
//** has no parent, or ABox is empty.)
/// <summary>Draws the volume AModel sweeps in a full turn about its up axis, at rest
/// only.</summary>
/// <remarks>As the other ShowModelSweep with no animation boxes, so the rest pose's volume is
/// drawn whatever AModel plays.</remarks>
/// <param name="AModel">The model to sweep. Nothing happens if it is nil or has no
/// parent.</param>
/// <param name="ABox">AModel's own bounds at rest, in its own coordinates, measured before any
/// helper was added to it as a child.</param>
/// <param name="AAxis">Which of the model's axes it turns about; Y, its up axis, by
/// default.</param>
/// <returns>The new sweep, owned by AModel; or nil, with nothing added, if AModel is nil or
/// has no parent, or ABox is empty.</returns>
function ShowModelSweep(const AModel: TGorillaModel; const ABox: TBoundingBox;
  const AAxis: TSweepAxis = saY): TModelSweep; overload;

//** @abstract(Removes the sweep ShowModelSweep added to AModel.)
//**
//** Frees the TModelSweep. Does nothing if AModel is nil or has no sweep. Call from the main
//** thread only.
//**
//** @param(AModel The model to remove the sweep from.)
//**
//** @seealso(ShowModelSweep)
/// <summary>Removes the sweep ShowModelSweep added to AModel.</summary>
/// <remarks>Frees the TModelSweep. Does nothing if AModel is nil or has no sweep. Call from
/// the main thread only.</remarks>
/// <param name="AModel">The model to remove the sweep from.</param>
/// <seealso cref="ShowModelSweep"/>
procedure HideModelSweep(const AModel: TGorillaModel);

//** @abstract(Returns the sweep ShowModelSweep added to AModel, or nil.)
//**
//** Looks among the components AModel owns. The caller does not own the result; it is freed
//** with AModel or by HideModelSweep.
//**
//** @param(AModel The model to look on; nil gives nil.)
//**
//** @returns(The sweep, or nil if AModel is nil or has none.)
/// <summary>Returns the sweep ShowModelSweep added to AModel, or nil.</summary>
/// <remarks>Looks among the components AModel owns. The caller does not own the result; it is
/// freed with AModel or by <see cref="HideModelSweep"/>.</remarks>
/// <param name="AModel">The model to look on; nil gives nil.</param>
/// <returns>The sweep, or nil if AModel is nil or has none.</returns>
function FindModelSweep(const AModel: TGorillaModel): TModelSweep;

//** @abstract(Draws one fixed swept volume beside AModel, such as the combined volume of its
//** rest pose and the animations used.)
//**
//** Any combined sweep already on AModel is removed first, so calling it again redraws it
//** for the new volume. The TCombinedSweep is owned by AModel, so it is freed with it, and
//** placed beside it, under AModel's parent; it draws AVolume whatever AModel plays. It is
//** separate from the sweep ShowModelSweep adds, so both can be shown. Call from the main
//** thread only.
//**
//** @param(AModel The model the volume belongs to. Nothing happens if it is nil or has no
//** parent.)
//**
//** @param(AVolume The volume to draw, in AModel's own coordinates, such as one from
//** CombinedSweptVolume.)
//**
//** @returns(The new sweep, owned by AModel; or nil, with nothing added, if AModel is nil or
//** has no parent, or AVolume is not Valid.)
//**
//** @seealso(HideCombinedSweep)
/// <summary>Draws one fixed swept volume beside AModel, such as the combined volume of its rest
/// pose and the animations used.</summary>
/// <remarks>Any combined sweep already on AModel is removed first, so calling it again redraws
/// it for the new volume. The TCombinedSweep is owned by AModel, so it is freed with it, and
/// placed beside it, under AModel's parent; it draws AVolume whatever AModel plays. It is
/// separate from the sweep ShowModelSweep adds, so both can be shown. Call from the main
/// thread only.</remarks>
/// <param name="AModel">The model the volume belongs to. Nothing happens if it is nil or has
/// no parent.</param>
/// <param name="AVolume">The volume to draw, in AModel's own coordinates, such as one from
/// <see cref="CombinedSweptVolume"/>.</param>
/// <returns>The new sweep, owned by AModel; or nil, with nothing added, if AModel is nil or
/// has no parent, or AVolume is not Valid.</returns>
/// <seealso cref="HideCombinedSweep"/>
function ShowCombinedSweep(const AModel: TGorillaModel;
  const AVolume: TSweptVolume): TCombinedSweep;

//** @abstract(Removes the sweep ShowCombinedSweep added to AModel.)
//**
//** Does nothing if AModel is nil or has none. Call from the main thread only.
//**
//** @param(AModel The model to remove it from.)
/// <summary>Removes the sweep ShowCombinedSweep added to AModel.</summary>
/// <remarks>Does nothing if AModel is nil or has none. Call from the main thread
/// only.</remarks>
/// <param name="AModel">The model to remove it from.</param>
procedure HideCombinedSweep(const AModel: TGorillaModel);

//** @abstract(Returns the sweep ShowCombinedSweep added to AModel, or nil.)
//**
//** The caller does not own the result; it is freed with AModel or by HideCombinedSweep.
//**
//** @param(AModel The model to look on; nil gives nil.)
//**
//** @returns(The combined sweep, or nil if AModel is nil or has none.)
/// <summary>Returns the sweep ShowCombinedSweep added to AModel, or nil.</summary>
/// <remarks>The caller does not own the result; it is freed with AModel or by
/// <see cref="HideCombinedSweep"/>.</remarks>
/// <param name="AModel">The model to look on; nil gives nil.</param>
/// <returns>The combined sweep, or nil if AModel is nil or has none.</returns>
function FindCombinedSweep(const AModel: TGorillaModel): TCombinedSweep;

implementation

uses
  Sprite3DAnimCapture;

const
  // A size is never smaller than this, so a flat model still has extent
  MIN_SIZE = 0.001;
  // An inner radius below this, as a fraction of the outer, is treated as
  // none, so a pivot on the box's edge draws no zero-sized ring
  MIN_INNER_FRACTION = 0.001;
  // Fewest lines in a ring
  MIN_SEGMENTS = 8;
  DEFAULT_SEGMENTS = 64;
  // Where the lines along the axis join the rings, in quarter turns
  WALL_LINES = 4;
  // Poses a second to measure an animation Gorilla has not baked
  UNBAKED_MEASURE_RATE = 30;

{ Split a point into its value along AAxis and the other two values, in
  X, Y, Z order }
procedure SplitPoint(const APoint: TPoint3D; const AAxis: TSweepAxis;
  out AAlong, AAcross1, AAcross2: Single);
begin
  case AAxis of
    saX:
      begin
        AAlong := APoint.X;
        AAcross1 := APoint.Y;
        AAcross2 := APoint.Z;
      end;
    saY:
      begin
        AAlong := APoint.Y;
        AAcross1 := APoint.X;
        AAcross2 := APoint.Z;
      end;
  else
    begin
      AAlong := APoint.Z;
      AAcross1 := APoint.X;
      AAcross2 := APoint.Y;
    end;
  end;
end;

{ The reverse of SplitPoint }
function JoinPoint(const AAlong, AAcross1, AAcross2: Single;
  const AAxis: TSweepAxis): TPoint3D;
begin
  case AAxis of
    saX: Result := Point3D(AAlong, AAcross1, AAcross2);
    saY: Result := Point3D(AAcross1, AAlong, AAcross2);
  else
    Result := Point3D(AAcross1, AAcross2, AAlong);
  end;
end;

{ Gorilla gives an empty box (min > max) for a model with no vertices }
function IsEmptyBox(const ABox: TBoundingBox): Boolean;
begin
  Result := (ABox.Left > ABox.Right) or (ABox.Top > ABox.Bottom) or (ABox.Near > ABox.Far);
end;

{ The smallest box holding both; either may be given with its corners in
  either order, as the capture framing allows for }
function UnionBox(const A, B: TBoundingBox): TBoundingBox;
begin
  Result.Left := Min(Min(A.Left, A.Right), Min(B.Left, B.Right));
  Result.Top := Min(Min(A.Top, A.Bottom), Min(B.Top, B.Bottom));
  Result.Near := Min(Min(A.Near, A.Far), Min(B.Near, B.Far));
  Result.Right := Max(Max(A.Left, A.Right), Max(B.Left, B.Right));
  Result.Bottom := Max(Max(A.Top, A.Bottom), Max(B.Top, B.Bottom));
  Result.Far := Max(Max(A.Near, A.Far), Max(B.Near, B.Far));
end;

{ Copy ASource to ATarget only if it differs, so an unchanged transform
  never triggers a repaint }
procedure CopyIfChanged(const ATarget: TPosition3D; const ASource: TPoint3D);
var
  P: TPoint3D;
begin
  P := ATarget.Point;
  if (P.X <> ASource.X) or (P.Y <> ASource.Y) or (P.Z <> ASource.Z) then
    ATarget.Point := ASource;
end;

{ TSweptVolume }

function TSweptVolume.Length: Single;
begin
  if Valid then
    Result := AxialHigh - AxialLow
  else
    Result := 0;
end;

function TSweptVolume.Volume: Single;
begin
  if Valid then
    Result := Pi * (Sqr(OuterRadius) - Sqr(InnerRadius)) * Length
  else
    Result := 0;
end;

function TSweptVolume.BoxVolume: Single;
begin
  if Valid then
    Result := Sqr(2 * OuterRadius) * Length
  else
    Result := 0;
end;

function TSweptVolume.AxisPoint(const AAlong, AAcross1, AAcross2: Single): TPoint3D;
var
  PAlong, P1, P2: Single;
begin
  SplitPoint(Pivot, Axis, PAlong, P1, P2);
  Result := JoinPoint(AAlong, P1 + AAcross1, P2 + AAcross2, Axis);
end;

function TSweptVolume.Box: TBoundingBox;
var
  Lo, Hi: TPoint3D;
begin
  // Each corner is lowest or highest on every axis, so the box is normal
  Lo := AxisPoint(AxialLow, -OuterRadius, -OuterRadius);
  Hi := AxisPoint(AxialHigh, OuterRadius, OuterRadius);
  Result.Left := Lo.X;
  Result.Top := Lo.Y;
  Result.Near := Lo.Z;
  Result.Right := Hi.X;
  Result.Bottom := Hi.Y;
  Result.Far := Hi.Z;
end;

function TSweptVolume.ToString: String;
const
  AXIS_NAMES: array[TSweepAxis] of String = ('X', 'Y', 'Z');
var
  B: TBoundingBox;
begin
  if not Valid then
    Exit('Swept volume about ' + AXIS_NAMES[Axis] + ': nothing to sweep');
  B := Box;
  Result := Format('Swept volume about %s through (%.3f, %.3f, %.3f): ' +
    'radius %.3f to %.3f, length %.3f, volume %.3f; ' +
    'swept box %.3f x %.3f x %.3f, volume %.3f',
    [AXIS_NAMES[Axis], Pivot.X, Pivot.Y, Pivot.Z,
     InnerRadius, OuterRadius, Length, Volume,
     B.Right - B.Left, B.Bottom - B.Top, B.Far - B.Near, BoxVolume]);
end;

{ Routines }

function CalcSweptVolume(const ABox: TBoundingBox; const APivot: TPoint3D;
  const AAxis: TSweepAxis): TSweptVolume;
var
  Lo1, Lo2, Hi1, Hi2, P1, P2, PAlong, Near1, Near2, Far1, Far2: Single;
begin
  Result := Default(TSweptVolume);
  Result.Axis := AAxis;
  Result.Pivot := APivot;
  if IsEmptyBox(ABox) then
    Exit;

  SplitPoint(ABox.TopLeftNear, AAxis, Result.AxialLow, Lo1, Lo2);
  SplitPoint(ABox.BottomRightFar, AAxis, Result.AxialHigh, Hi1, Hi2);
  SplitPoint(APivot, AAxis, PAlong, P1, P2);

  // Seen along the axis the box is the rectangle Lo..Hi and the axis the
  // point P. Turning it fills the ring between the rectangle's nearest point
  // to P, which is P itself if P is inside, and its farthest corner from P.
  Near1 := Max(Max(Lo1 - P1, P1 - Hi1), 0);
  Near2 := Max(Max(Lo2 - P2, P2 - Hi2), 0);
  Far1 := Max(Abs(P1 - Lo1), Abs(Hi1 - P1));
  Far2 := Max(Abs(P2 - Lo2), Abs(Hi2 - P2));
  Result.InnerRadius := Sqrt(Sqr(Near1) + Sqr(Near2));
  Result.OuterRadius := Sqrt(Sqr(Far1) + Sqr(Far2));
  Result.Valid := True;
end;

{ The box holding every pose of AAnimation, stepped at its baked rate;
  APoses says how many poses gave a box. AAnimation is left current and
  running, released from any fixed pose. }
function MeasureOneAnimation(const AModel: TGorillaModel;
  const AAnimation: TGorillaAnimation; out APoses: Integer): TBoundingBox;
var
  Source: TSprite3DAnimationFrames;
  Rate, I: Integer;
  Box: TBoundingBox;
begin
  APoses := 0;
  Result := Default(TBoundingBox);
  // Baked poses: step at their rate, so every one is visited once
  if (AAnimation.FrameCount > 0) and (AAnimation.FrameRate > 0) then
    Rate := Max(1, Ceil(AAnimation.FrameRate))
  else
    Rate := UNBAKED_MEASURE_RATE;

  Source := TSprite3DAnimationFrames.Create(AModel, AAnimation, Rate);
  try
    Source.Start;
    try
      for I := 0 to Source.FrameCount - 1 do
      begin
        Source.ShowFrame(I);
        Box := AModel.GetAnimatedBoundingBox();
        if IsEmptyBox(Box) then
          Continue;
        if APoses = 0 then
          Result := UnionBox(Box, Box)   // puts the corners in order
        else
          Result := UnionBox(Result, Box);
        Inc(APoses);
      end;
    finally
      Source.Finish;
    end;
  finally
    Source.Free;
  end;
end;

function MeasureAnimationBounds(const AModel: TGorillaModel): TArray<TAnimationBounds>;
var
  Anims: TArray<TGorillaAnimation>;
  Anim, Original: TGorillaAnimation;
  WasRunning: Boolean;
  Entry: TAnimationBounds;
  Found: TList<TAnimationBounds>;
begin
  Result := nil;
  if AModel = nil then
    Exit;
  // Typed by inference, as Gorilla's manager class is not needed by name
  var Manager := AModel.AnimationManager;
  if Manager = nil then
    Exit;
  Anims := Manager.GetSortedAnimations();
  if System.Length(Anims) = 0 then
    Exit;

  Original := Manager.Current;
  WasRunning := (Original <> nil) and Original.IsRunning;
  Found := TList<TAnimationBounds>.Create;
  try
    try
      for Anim in Anims do
      begin
        Entry.Name := Anim.Id;
        Entry.Box := MeasureOneAnimation(AModel, Anim, Entry.Poses);
        // Measuring left it running; only the original may stay so
        if (Anim <> Original) and Anim.IsRunning then
          Anim.Stop;
        if Entry.Poses > 0 then
          Found.Add(Entry);
      end;
    finally
      // Back to the animation that was current, as it was
      if Original <> nil then
      begin
        if Manager.Current <> Original then
          Manager.Current := Original;
        if WasRunning then
        begin
          if not Original.IsRunning then
            Original.Start;
        end
        else if Original.IsRunning then
          Original.Stop;
      end;
    end;
    Result := Found.ToArray;
  finally
    Found.Free;
  end;
end;

function UnionSweptVolume(const AVolumes: array of TSweptVolume): TSweptVolume;
var
  V: TSweptVolume;
begin
  Result := Default(TSweptVolume);
  for V in AVolumes do
  begin
    if not V.Valid then
      Continue;
    if not Result.Valid then
    begin
      Result := V;
      Continue;
    end;
    Result.AxialLow := Min(Result.AxialLow, V.AxialLow);
    Result.AxialHigh := Max(Result.AxialHigh, V.AxialHigh);
    Result.InnerRadius := Min(Result.InnerRadius, V.InnerRadius);
    Result.OuterRadius := Max(Result.OuterRadius, V.OuterRadius);
  end;
end;

function CombinedSweptVolume(const AModel: TGorillaModel; const ABox: TBoundingBox;
  const AAnimations: TArray<TAnimationBounds>; const ANames: TArray<String>;
  const AIncludeRest: Boolean; const AAxis: TSweepAxis): TSweptVolume;
var
  Pivot: TPoint3D;
  Volumes: TList<TSweptVolume>;
  Entry: TAnimationBounds;
  Name: String;
  Chosen: Boolean;
begin
  Result := Default(TSweptVolume);
  if AModel = nil then
    Exit;
  Pivot := AModel.RotationCenter.Point;
  Volumes := TList<TSweptVolume>.Create;
  try
    if AIncludeRest then
      Volumes.Add(CalcSweptVolume(ABox, Pivot, AAxis));
    for Entry in AAnimations do
    begin
      Chosen := False;
      for Name in ANames do
        if Name = Entry.Name then
        begin
          Chosen := True;
          Break;
        end;
      if Chosen then
        Volumes.Add(CalcSweptVolume(Entry.Box, Pivot, AAxis));
    end;
    Result := UnionSweptVolume(Volumes.ToArray);
  finally
    Volumes.Free;
  end;
end;

function SweepOutline(const AVolume: TSweptVolume;
  const ASegments: Integer): TArray<TPoint3D>;
var
  N, I: Integer;
  R, A: Double;
begin
  Result := nil;
  if not AVolume.Valid then
    Exit;
  N := Max(ASegments, MIN_SEGMENTS);
  // Corners of the polygon drawn round the circle: its sides touch the
  // circle, so its corners are 1 / cos(half a step) further out
  R := AVolume.OuterRadius / Cos(Pi / N);
  SetLength(Result, 2 * N);
  for I := 0 to N - 1 do
  begin
    A := 2 * Pi * I / N;
    Result[I] := AVolume.AxisPoint(AVolume.AxialLow, R * Cos(A), R * Sin(A));
    Result[N + I] := AVolume.AxisPoint(AVolume.AxialHigh, R * Cos(A), R * Sin(A));
  end;
end;

{ The turning axis's direction in the model's own coordinates, for a fit to
  put the orbit centre on the line through the pivot }
function SweepDirection(const AVolume: TSweptVolume): TPoint3D;
begin
  Result := AVolume.AxisPoint(1, 0, 0) - AVolume.AxisPoint(0, 0, 0);
end;

function FitCameraToSweep(const ACamera: TSprite3DCamera; const AModel: TControl3D;
  const AVolume: TSweptVolume; const AMargin: Single): Boolean;
begin
  Result := (ACamera <> nil) and (AModel <> nil) and AVolume.Valid and
    ACamera.FitPointsOnAxis(SweepOutline(AVolume, DEFAULT_SEGMENTS), AVolume.Pivot,
      SweepDirection(AVolume), AModel, AMargin);
end;

function FitCameraToSweep(const ACamera: TSprite3DCamera; const AModel: TControl3D;
  const AVolume: TSweptVolume; const AViewWidth, AViewHeight: Single;
  const AMargin: Single): Boolean;
begin
  Result := (ACamera <> nil) and (AModel <> nil) and AVolume.Valid and
    ACamera.FitPointsOnAxis(SweepOutline(AVolume, DEFAULT_SEGMENTS), AVolume.Pivot,
      SweepDirection(AVolume), AModel, AViewWidth, AViewHeight, AMargin);
end;

function FindModelSweep(const AModel: TGorillaModel): TModelSweep;
var
  I: Integer;
begin
  Result := nil;
  if AModel = nil then
    Exit;
  for I := 0 to AModel.ComponentCount - 1 do
    // Exactly a TModelSweep: a TCombinedSweep is found by FindCombinedSweep
    if AModel.Components[I].ClassType = TModelSweep then
      Exit(TModelSweep(AModel.Components[I]));
end;

function FindCombinedSweep(const AModel: TGorillaModel): TCombinedSweep;
var
  I: Integer;
begin
  Result := nil;
  if AModel = nil then
    Exit;
  for I := 0 to AModel.ComponentCount - 1 do
    if AModel.Components[I] is TCombinedSweep then
      Exit(TCombinedSweep(AModel.Components[I]));
end;

procedure HideCombinedSweep(const AModel: TGorillaModel);
var
  Sweep: TCombinedSweep;
begin
  Sweep := FindCombinedSweep(AModel);
  if Sweep <> nil then
  begin
    Sweep.Parent := nil;
    Sweep.Free;
  end;
end;

function ShowCombinedSweep(const AModel: TGorillaModel;
  const AVolume: TSweptVolume): TCombinedSweep;
begin
  Result := nil;
  if (AModel = nil) or (AModel.Parent = nil) then
    Exit;
  HideCombinedSweep(AModel);
  if not AVolume.Valid then
    Exit;
  // Owned by the model, so freed with it; beside it, so never in its bounds
  Result := TCombinedSweep.Create(AModel);
  Result.Parent := AModel.Parent;
  Result.Model := AModel;
  Result.Volume := AVolume;
end;

{ TCombinedSweep }

constructor TCombinedSweep.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  BoxColor := TAlphaColorRec.Fuchsia;
  SweepColor := TAlphaColorRec.Hotpink;
end;

procedure HideModelSweep(const AModel: TGorillaModel);
var
  Sweep: TModelSweep;
begin
  Sweep := FindModelSweep(AModel);
  if Sweep <> nil then
  begin
    Sweep.Parent := nil;
    Sweep.Free;
  end;
end;

function ShowModelSweep(const AModel: TGorillaModel; const ABox: TBoundingBox;
  const AAnimations: TArray<TAnimationBounds>; const AAxis: TSweepAxis): TModelSweep;
var
  Pivot: TPoint3D;
  Rest, AnimVolume: TSweptVolume;
  Entry: TAnimationBounds;
  AnyValid: Boolean;
begin
  Result := nil;
  if (AModel = nil) or (AModel.Parent = nil) then
    Exit;

  HideModelSweep(AModel);

  Pivot := AModel.RotationCenter.Point;
  Rest := CalcSweptVolume(ABox, Pivot, AAxis);
  AnyValid := Rest.Valid;
  for Entry in AAnimations do
    if not IsEmptyBox(Entry.Box) then
      AnyValid := True;
  if not AnyValid then
    Exit;

  // Owned by the model, so freed with it; beside it, so never in its bounds
  Result := TModelSweep.Create(AModel);
  Result.Parent := AModel.Parent;
  Result.Model := AModel;
  Result.Volume := Rest;
  for Entry in AAnimations do
  begin
    AnimVolume := CalcSweptVolume(Entry.Box, Pivot, AAxis);
    if AnimVolume.Valid then
      Result.SetAnimationVolume(Entry.Name, AnimVolume);
  end;
end;

function ShowModelSweep(const AModel: TGorillaModel; const ABox: TBoundingBox;
  const AAxis: TSweepAxis): TModelSweep;
begin
  Result := ShowModelSweep(AModel, ABox, TArray<TAnimationBounds>(nil), AAxis);
end;

{ TModelSweep }

constructor TModelSweep.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  Stored := False;
  Locked := True;
  HitTest := False;
  FAnimations := TDictionary<String, TSweptVolume>.Create;
  FBoxColor := TAlphaColorRec.Aqua;
  FSweepColor := TAlphaColorRec.Yellow;
  FLineWidth := 1;
  FSegments := DEFAULT_SEGMENTS;
end;

destructor TModelSweep.Destroy;
begin
  FAnimations.Free;
  inherited;
end;

procedure TModelSweep.Notification(AComponent: TComponent; Operation: TOperation);
begin
  inherited;
  if (Operation = opRemove) and (AComponent = FModel) then
    FModel := nil;
end;

procedure TModelSweep.SetModel(const Value: TGorillaModel);
begin
  if FModel = Value then
    Exit;
  if FModel <> nil then
    FModel.RemoveFreeNotification(Self);
  FModel := Value;
  if FModel <> nil then
    FModel.FreeNotification(Self);
  FLinesValid := False;
  Repaint;
end;

procedure TModelSweep.SetVolume(const Value: TSweptVolume);
begin
  FVolume := Value;
  FLinesValid := False;
  Repaint;
end;

procedure TModelSweep.SetAnimationVolume(const AName: String; const AVolume: TSweptVolume);
begin
  FAnimations.AddOrSetValue(AName, AVolume);
  FLinesValid := False;
  Repaint;
end;

procedure TModelSweep.ClearAnimationVolumes;
begin
  FAnimations.Clear;
  FLinesValid := False;
  Repaint;
end;

function TModelSweep.TryGetAnimationVolume(const AName: String;
  out AVolume: TSweptVolume): Boolean;
begin
  Result := FAnimations.TryGetValue(AName, AVolume);
end;

procedure TModelSweep.SetBoxColor(const Value: TAlphaColor);
begin
  FBoxColor := Value;
  Repaint;
end;

procedure TModelSweep.SetSweepColor(const Value: TAlphaColor);
begin
  FSweepColor := Value;
  Repaint;
end;

procedure TModelSweep.SetLineWidth(const Value: Single);
begin
  FLineWidth := Max(Value, 1);
  Repaint;
end;

procedure TModelSweep.SetSegments(const Value: Integer);
begin
  FSegments := Max(Value, MIN_SEGMENTS);
  FLinesValid := False;
  Repaint;
end;

// The Id of the animation the model is playing, if it has a volume here;
// otherwise empty, for the rest pose. A stopped animation that is still the
// current one leaves the model at rest, as View's "(None)" does.
function TModelSweep.PlayingName: String;
var
  Current: TGorillaAnimation;
begin
  Result := String.Empty;
  if (FModel = nil) or (FAnimations.Count = 0) then
    Exit;
  var Manager := FModel.AnimationManager;
  if Manager = nil then
    Exit;
  Current := Manager.Current;
  if (Current <> nil) and Current.IsRunning and FAnimations.ContainsKey(Current.Id) then
    Result := Current.Id;
end;

procedure TModelSweep.UpdateActive;
var
  Name: String;
begin
  Name := PlayingName;
  if FLinesValid and (Name = FActiveName) then
    Exit;
  FActiveName := Name;
  if (Name = String.Empty) or not FAnimations.TryGetValue(Name, FActive) then
    FActive := FVolume;
  BuildLines;
  FLinesValid := True;
end;

function TModelSweep.GetActiveVolume: TSweptVolume;
begin
  UpdateActive;
  Result := FActive;
end;

function TModelSweep.GetActiveAnimation: String;
begin
  UpdateActive;
  Result := FActiveName;
end;

procedure TModelSweep.BuildLines;
var
  Lines: TList<TPoint3D>;
  B: TBoundingBox;
  Corners: array[0..7] of TPoint3D;
  I, Bit, K: Integer;
  Extent: TPoint3D;

  procedure AddLine(const A, C: TPoint3D);
  begin
    Lines.Add(A);
    Lines.Add(C);
  end;

  // A ring of FSegments lines round the axis at AAlong
  procedure AddRing(const AAlong, ARadius: Single);
  var
    S: Integer;
    A0, A1: Double;
  begin
    for S := 0 to FSegments - 1 do
    begin
      A0 := 2 * Pi * S / FSegments;
      A1 := 2 * Pi * (S + 1) / FSegments;
      AddLine(FActive.AxisPoint(AAlong, ARadius * Cos(A0), ARadius * Sin(A0)),
        FActive.AxisPoint(AAlong, ARadius * Cos(A1), ARadius * Sin(A1)));
    end;
  end;

  // A cylinder wall: a ring at each end, joined along the axis
  procedure AddWall(const ARadius: Single);
  var
    W: Integer;
    A: Double;
  begin
    AddRing(FActive.AxialLow, ARadius);
    AddRing(FActive.AxialHigh, ARadius);
    for W := 0 to WALL_LINES - 1 do
    begin
      A := 2 * Pi * W / WALL_LINES;
      AddLine(FActive.AxisPoint(FActive.AxialLow, ARadius * Cos(A), ARadius * Sin(A)),
        FActive.AxisPoint(FActive.AxialHigh, ARadius * Cos(A), ARadius * Sin(A)));
    end;
  end;

begin
  FBoxLines := nil;
  FSweepLines := nil;
  if not FActive.Valid then
    Exit;

  B := FActive.Box;
  Lines := TList<TPoint3D>.Create;
  try
    // The swept box: its 12 edges join each corner to the three corners
    // that differ from it on one axis only
    for I := 0 to 7 do
      Corners[I] := Point3D(
        IfThen((I and 1) <> 0, B.Right, B.Left),
        IfThen((I and 2) <> 0, B.Bottom, B.Top),
        IfThen((I and 4) <> 0, B.Far, B.Near));
    for I := 0 to 7 do
    begin
      Bit := 1;
      for K := 0 to 2 do
      begin
        if (I and Bit) = 0 then
          AddLine(Corners[I], Corners[I or Bit]);
        Bit := Bit shl 1;
      end;
    end;
    FBoxLines := Lines.ToArray;

    // The tube: outer wall, inner wall if there is a hole, and the axis
    Lines.Clear;
    AddWall(FActive.OuterRadius);
    if FActive.InnerRadius > FActive.OuterRadius * MIN_INNER_FRACTION then
      AddWall(FActive.InnerRadius);
    AddLine(FActive.AxisPoint(FActive.AxialLow, 0, 0),
      FActive.AxisPoint(FActive.AxialHigh, 0, 0));
    FSweepLines := Lines.ToArray;
  finally
    Lines.Free;
  end;

  // Sized so that a box round this object's origin, which is the model's,
  // holds every line
  Extent := Point3D(Max(Abs(B.Left), Abs(B.Right)), Max(Abs(B.Top), Abs(B.Bottom)),
    Max(Abs(B.Near), Abs(B.Far)));
  Width := Max(2 * Extent.X, MIN_SIZE);
  Height := Max(2 * Extent.Y, MIN_SIZE);
  Depth := Max(2 * Extent.Z, MIN_SIZE);
end;

procedure TModelSweep.SyncToModel;
begin
  if FModel = nil then
    Exit;
  // Under the same parent, the same transform properties give the same
  // matrix, so this object's size covers the lines for any culling. The
  // parent is not changed here, during a render of the parent's children.
  CopyIfChanged(Position, FModel.Position.Point);
  CopyIfChanged(RotationAngle, FModel.RotationAngle.Point);
  CopyIfChanged(Scale, FModel.Scale.Point);
  CopyIfChanged(RotationCenter, FModel.RotationCenter.Point);
end;

procedure TModelSweep.DrawLines;
var
  O: Single;
  I: Integer;
begin
  O := AbsoluteOpacity;
  I := 0;
  while I < High(FBoxLines) do
  begin
    Context.DrawLine(FBoxLines[I], FBoxLines[I + 1], O, FBoxColor);
    Inc(I, 2);
  end;
  I := 0;
  while I < High(FSweepLines) do
  begin
    Context.DrawLine(FSweepLines[I], FSweepLines[I + 1], O, FSweepColor);
    Inc(I, 2);
  end;
end;

procedure TModelSweep.Render;
var
  Ctx: TGorillaContext;
  PrevMat: TMatrix3D;
  Wide: Boolean;
begin
  inherited;
  if FModel = nil then
    Exit;
  SyncToModel;   // a no-op unless the model moved, turned or was scaled
  if not FModel.Visible then
    Exit;

  // Main pass only: Render also runs in shadow, reflection, environment
  // and other passes, where CurrentPass is assigned. Under a plain FMX
  // context there are no passes, and the FMX helpers still work.
  if Context is TGorillaContext then
    Ctx := TGorillaContext(Context)
  else
    Ctx := nil;
  if (Ctx <> nil) and Assigned(Ctx.CurrentPass) then
    Exit;

  // The playing animation's volume, or the rest pose's; the lines are only
  // worked out again when that changes
  UpdateActive;
  if not FActive.Valid then
    Exit;

  // Line width is Gorilla line state; it needs persistent mode because
  // there are many draws. Width 1 is the default, so leave state alone.
  Wide := (Ctx <> nil) and (FLineWidth > 1);

  // The lines are in the model's own coordinates
  PrevMat := Context.CurrentMatrix;
  Context.SetMatrix(FModel.AbsoluteMatrix);
  try
    if Wide then
      Ctx.BeginLineRendering(FLineWidth, TGorillaLineType.Solid, True);
    try
      DrawLines;
    finally
      if Wide then
        Ctx.EndLineRendering(True);
    end;
  finally
    Context.SetMatrix(PrevMat);
  end;
end;

end.
