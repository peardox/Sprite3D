### Explain how the background is drawn

> The background is ordinary 3D geometry that travels with the camera and is resized every frame so it exactly fills the view. Everything lives in Sprite3DBackground.pas.
>
> Where it sits
>
> TSprite3DBackground is a TDummy attached to the camera’s RollPivot, the same dummy the camera hangs from. The camera sits at (0, 0, −Distance) in that frame, looking along +Z, with X to the right and Y down the screen. Because the background shares that frame, it turns and moves with the camera automatically; nothing has to track the camera’s angles.
>
> Fitting it to the view
>
> On every frame, Render calls Fit:
>
> It picks a depth of 95% of the far plane (950 units from the camera), so anything in the scene is in front of it.
> It asks the camera for the half-width and half-height of the view at that depth (ViewHalfExtents, worked out from the camera’s own projection matrix). That covers any field of view, window shape or zoom.
> It sizes the planes to match, 2% larger so no edge shows through rounding.
> It only sets a property when the value has changed, because every change makes Gorilla redraw.
>
> The kinds
>
> None: every plane is moved behind the camera, so nothing is drawn and the viewport’s own black shows.
> Solid: one full-view plane, a pair really (see below), whose material has a tiny GLSL SurfaceShader that sets one colour.
> Gradient: the same plane, with a shader that blends from the From colour to the To colour down the plane’s own Y axis (vars.v_VertPos.y). For the other directions, the plane is turned in the view so its Y axis points the chosen way, and enlarged so it still covers the view. The diagonals run exactly corner to corner. After turning, the code reads the plane’s matrix to confirm the axis points the right way, and turns it the other way if not.
> Transparent (the checker): the full-view plane is put away. The view is tiled with small square planes side by side, light and dark alternating, starting with light at the top-left. All light squares share one material and all dark squares another. They’re all made at startup and only moved afterwards, up to 150 squares of each grey; above that, the squares are drawn at 2×, 3× and so on.
>
> Why it’s built this way
>
> Each design choice works around something that went wrong:
>
> Squares, not a checker shader: Gorilla failed on shaders that read the horizontal position or used fract, so the checker had to be geometry.
> Side by side, not stacked: dark squares laid over a light plane were too close in depth for the depth buffer to tell apart.
> Made at startup: adding planes after the first frame never drew reliably, so nothing is added later; planes are only moved.
> Culling off: Gorilla’s frustum culling misjudged where the small squares were and skipped most of them, so every background plane has FrustumCullingCheck := False.
> Pairs of planes: every plane has a twin turned half a turn, so one of them faces the camera whichever side Gorilla treats as the front.
> Black Diffuse: even with lighting off, Gorilla adds part of the material’s own Diffuse colour to what the shader gives, so the materials’ Diffuse is black. Colours still come out about 1.25× too bright (128 shows as 160) from a source I haven’t pinned down yet.
>
> Grabs and icons
>
> The background is hidden while a grab is drawn: OnBeforeGrab sets Hidden, which moves the planes behind the camera, and OnAfterGrab brings them back. The off-screen renderer cuts the model out against a transparent background. With None or Transparent the grab stays transparent. With Solid or Gradient it fills the colour or gradient in afterwards, per pixel, in the same direction as on screen, so soft edges blend into it.
>
> Not working yet
>
> In orthographic view the background draws black over the whole scene, so for now it’s simply hidden there. That’s the issue you’re taking to the developer.