# Volumes

Sprite3D frames a model by the space it sweeps as it turns about its up axis, rather than by its bounding box. This page explains what that space is, how it is measured for a model and its animations, how the camera is fitted to it, and where the code lives.

## Why not just the bounding box?

A sprite set wants every image of a model at the same scale and in the same place. Two things get in the way of that if the camera is fitted to the model's bounding box:

- **Turning.** The `(None)` turntable, and turning the azimuth dial, show the model from every side. A box that fits one view exactly can poke out of the frame a quarter turn later.
- **Animating.** Every pose of every animation has its own box. A walk reaches further than the rest pose, and a jump reaches higher. Fitting each animation, or each frame, to its own box changes the scale from one to the next.

A volume that holds the model in every turn about its up axis, and in every pose of the animations that matter, fixes both: frame that once, and nothing the model does can leave the frame or change the scale.

## The terms

- **Centre of rotation.** FMX's `RotationCenter` of the model, in the model's own coordinates. Sprite3D never sets it, so it is the model file's own origin, (0, 0, 0). For many characters that is between the feet.
- **Up axis.** The model's own Y axis. The **turning axis** is the line through the centre of rotation parallel to it.
- **Bounding box.** The box the model's vertices fill, in its own coordinates. The rest pose's box is measured as the model is loaded, before any helper is added, as Gorilla counts a model's children in its bounds.

## The swept volume of a box

Turn a box all the way round the turning axis and it sweeps out a [solid of revolution](https://en.wikipedia.org/wiki/Solid_of_revolution). Seen along the axis, the box is a rectangle and the axis a point *P*:

```
   seen down the up axis

        +-------------------+        R: from P to the rectangle's farthest corner
        |                   |        r: from P to the rectangle's nearest point;
        |       box         |           0 when P is inside the rectangle
        |                   |
        +-------------------+
                  .
                  .  r
                  .
                  P   turning axis
```

Every point of the rectangle lies between distance *r* and *R* from *P*, and the rectangle is connected, so the turn fills the whole ring between those two circles, an [annulus](https://en.wikipedia.org/wiki/Annulus_(mathematics)). Along the axis the box's extent does not change as it turns, so the swept volume is:

- a **solid cylinder** of radius *R* when the axis passes through the box (*r* = 0), or
- a **thick-walled tube** from *r* to *R* when the centre of rotation lies outside the box seen from above,

as long as the box is along the axis, *h*. With the rectangle running from *x*₀ to *x*₁ and *z*₀ to *z*₁, and *P* at (*p*ₓ, *p*_z):

- *R* = √( max(|*p*ₓ − *x*₀|, |*x*₁ − *p*ₓ|)² + max(|*p*_z − *z*₀|, |*z*₁ − *p*_z|)² )
- *r* = √( max(*x*₀ − *p*ₓ, *p*ₓ − *x*₁, 0)² + max(*z*₀ − *p*_z, *p*_z − *z*₁, 0)² )
- swept volume = π (*R*² − *r*²) *h*
- **swept box**, the box round the tube, square across the axis and centred on it: 2*R* × *h* × 2*R*, volume 4*R*²*h*. It cannot show the tube's hole, so it also holds space the model never reaches.

The volume holds the box, and the box holds the model, so the swept volume holds everything the model can reach as it turns, with room to spare where the model does not fill its box. It is a [bounding volume](https://en.wikipedia.org/wiki/Bounding_volume) for the turning model: always safe, never tight to the mesh itself. For the wider subject of the space a moving solid sweeps, see Abdel-Malek, Blackmore and Joy below.

`CalcSweptVolume` in `src/lib/Sprite3DSweep.pas` does this arithmetic and returns a `TSweptVolume`. It can turn about the model's X or Z axis too; Sprite3D always uses Y.

## Animations

An animation moves the model's vertices, so its poses can reach outside the rest pose's box. `MeasureAnimationBounds` steps each animation through one cycle, visiting every pose Gorilla has baked for it, about 60 a second on desktop, and adds each pose's `GetAnimatedBoundingBox` to that animation's box. Each animation's box then gives its own swept volume, by the same arithmetic as above.

Measuring has some costs and conditions:

- It **blocks** while it runs, for the number of poses times the cost of one bounding box. Sprite3D measures each model once, the first time a volume is needed, and keeps the results until another model is loaded.
- The axes helper is a child of the model and would count in its bounds, so it is taken off while the poses are measured and put back afterwards.
- The animation that was current is made current again afterwards, running or stopped as it was.
- Nothing is measured while an animation is being exported, as the export is driving the animations then.
- An animation that Gorilla has not baked is posed by seeking its skeleton. On Delphi 13 and later that pose is only worked out when a frame is drawn, so such an animation's box may be wrong. Sprite3D loads models with vertex caching, so their animations are baked.

The Debug tab lists every volume measured: the radii, length and volumes, and the size of the swept box.

## Model Volume and Animation Volume

Two wireframes can be shown from the View menu:

| Item | Shows | Colours |
|---|---|---|
| **Show Model Volume** | the swept volume of the animation playing, or of the rest pose when none is playing. It changes as soon as another animation plays, whether chosen with the mouse or the arrow keys | swept box aqua; tube walls and axis yellow |
| **Show Animation Volume** | the **combined** volume: the rest pose and every animation used, joined into one. It is never shown for a model without animations, or with none used, as it would only repeat the rest pose's volume | swept box fuchsia; tube walls and axis hot pink |

**Model, Animations Used...** chooses which animations count. Unticked animations leave the Animations list, so they are not played or exported, and leave the combined volume. A model starts with every animation used.

The dialog's right-hand column gives each animation's own swept volume, π(*R*² − *r*²)*h*, as a percentage of the combined volume of the rest pose and every animation ticked at the time, and works it out again whenever a tick changes. It is there to catch an animation that does not belong. One that reaches much further than the others, a death that throws the model across the floor, or a jump far higher than any other move, makes the combined volume, and so the framing of every export, much larger: the others then show small percentages beside it. Unticking it shows at once how far the combined volume shrinks without it, and an unticked animation can show more than 100%, as it is no longer part of the combined volume.

The combined volume is joined from the separate ones by `UnionSweptVolume`: the lowest start and highest end along the axis, the largest outer radius and the smallest inner radius. Where the animations differ in height this is a little larger than their exact union, never smaller.

Both wireframes are drawn beside the model, not inside it, so they never count in its bounding box, and they draw with the model's own matrix, so they follow it wherever it is moved, turned or scaled.

## Fitting the camera

Every fit, on screen, for a grab, for an icon and for a batch export or the `(None)` turn, frames the combined volume, or the rest pose's alone for a model without animations. One animation saved on its own, from the Animations list's right-click menu (or the Animation menu on Android and iOS), is framed to that animation's own volume instead, without the rest pose's, so it fills the image as far as its own poses allow; the Debug tab says so and gives that volume. Either way the fit takes two steps, in `TSprite3DCamera.FitPointsOnAxis`.

**1. Fill the view.** From any direction, a cylinder's outline is that of its two end circles. `SweepOutline` stands in for each circle with a regular 64-sided polygon drawn round it, its corners 1 / cos(π / 64), about 1.0012, times the radius from the axis, so the polygon holds the circle exactly. These 128 points are framed the way `FitToBounds` frames a box's corners: for the current angles, as large as they will go, centred, so the volume reaches both edges of the tighter axis, left and right or top and bottom. In perspective the camera also stays at least 1 unit, FMX's near plane, in front of the nearest point, which can stop a very close volume filling the view. The angles themselves are never changed.

**2. Put the orbit centre on the turning axis.** The fit leaves the orbit centre on the view axis, the line from the camera through the middle of the view. The orbit centre is then slid along that line to its point nearest the turning axis, and the distance changed by the same amount, so the camera does not move and the picture does not change. With the view direction *F* and the axis direction *L* both of unit length, the orbit centre *C*, and a point *A* on the turning axis, the slide is

*s* = (*b e* − *d*) / (1 − *b*²), with *b* = *F*·*L*, *d* = *F*·(*C* − *A*) and *e* = *L*·(*C* − *A*),

the usual formula for the [nearest points of two lines](https://en.wikipedia.org/wiki/Skew_lines). The cylinder is round about the turning axis, so while Roll is 0 step 1 centres the view across it and the view axis meets the turning axis: the orbit centre ends up on the axis, at the height that centres the volume.

That is what makes the framing hold as the camera turns. The camera's azimuth turns it about an upright line through the orbit centre. The model stands upright, so that line is the turning axis, and the volume, round about it, looks the same from every azimuth. The `(None)` turntable and the azimuth dial therefore never push the model out of the frame or change its size, and every animation used, and the rest pose, is framed alike.

Two cases keep step 1's orbit centre as it is:

- **Looking along the axis**, as in View, Camera, Top Down. Every point on the view axis is then on the turning axis too, or equally near it.
- **A slide that would put the camera less than 1 unit from the new centre**, which would mean the axis is behind the camera or right in front of it.

In orthographic projection the same steps set the orthographic size in place of the distance; the distance then only keeps the camera clear of the volume.

## In the code

| Where | What |
|---|---|
| `src/lib/Sprite3DSweep.pas` | `TSweptVolume`, `CalcSweptVolume`, `UnionSweptVolume`, `CombinedSweptVolume`, `MeasureAnimationBounds`, `SweepOutline`, `FitCameraToSweep`, and the wireframes: `TModelSweep` with `ShowModelSweep`, `TCombinedSweep` with `ShowCombinedSweep` |
| `src/lib/Sprite3DCamera.pas` | `TSprite3DCamera.FitPointsOnAxis` |
| `src/ui/Sprite3dMain.pas` | `FitModel`, `GrabFit` and `FrameCaptureFraming` use `FitCameraToSweep`; `SweepFitVolume` joins the volumes of the animations used; `ApplyShowSweep` and `ApplyShowCombinedSweep` draw the two wireframes |
| `src/ui/Sprite3DAnimationsUsedForm.pas` | the Model, Animations Used dialog |

Each routine's own documentation comments, in the source, give the details.

## Limits

- The volume is built from boxes, so it is safe but loose: a model that fills little of its box, such as a thin diagonal pole, gets a large cylinder.
- The turning axis is the model's own Y axis. A model whose up axis is another one would need `saX` or `saZ`, which the arithmetic supports but the application does not offer.
- The camera keeps the model in frame as the azimuth turns only while Roll is 0 and the model stands upright, which is how Sprite3D places every model.
- The volumes are worked out for the centre of rotation at the time; changing `RotationCenter` would need them worked out again.

## Further reading

- [Solid of revolution](https://en.wikipedia.org/wiki/Solid_of_revolution), Wikipedia: the shape a figure sweeps turning about an axis.
- [Annulus (mathematics)](https://en.wikipedia.org/wiki/Annulus_(mathematics)), Wikipedia: the ring between two circles, and its area.
- [Bounding volume](https://en.wikipedia.org/wiki/Bounding_volume), Wikipedia: boxes, spheres, cylinders and other simple shapes that enclose a model.
- [Viewing frustum](https://en.wikipedia.org/wiki/Viewing_frustum), Wikipedia: the region a perspective camera sees, which the fit keeps the volume inside.
- [Skew lines](https://en.wikipedia.org/wiki/Skew_lines), Wikipedia: the nearest points of two lines, used to put the orbit centre on the turning axis.
- Karim Abdel-Malek, Denis Blackmore and Kenneth Joy, [*Swept Volumes: Foundations, Perspectives, and Applications*](https://user.engineering.uiowa.edu/~amalek/papers/swept-volume-review.pdf): a survey of swept volumes in general.
- [Gorilla3D v1.5 documentation](https://gorilla3d.de/doc/v3/version/v1.5), and the [v1.5.3 notes](https://peardox.com/G3D/): models, animations, vertex caching and line rendering.
- [Viewport](viewport.md) and [OffScreen](offscreen.md): how the view and the grabs are drawn.
