### Explain how the background is drawn

> The background is no longer part of the 3D scene. It is an ordinary 2D control painted from a bitmap, sitting directly behind a GorillaViewport whose `Color` is fully transparent. Everything lives in Sprite3DBackground.pas.
>
> Where it sits
>
> `TSprite3DBackground` is a `TControl`. `AttachTo(GorillaViewport)` makes it a child of the viewport's parent (AspectLayout, inside ViewportLayout), moves it to just before the viewport in the child order so it is painted first, and gives it the viewport's `Align` and `Margins`, or its bounds if it is not aligned. The viewport is not aligned: `FitViewportToAspect` in the main form sizes it to the grab size's aspect ratio, centred in AspectLayout, and sets the background to the same bounds each time, so it always covers exactly what the viewport covers. Because it is 2D, it does not care about the camera at all: perspective, orthographic, field of view, zoom and roll make no difference to it.
>
> The viewport's colour
>
> Gorilla3D 1.5.3 honours the alpha of `TGorillaViewport.Color`. For Transparent, Solid and Gradient the background sets the viewport's `Color` to `TAlphaColors.Null`, so the background shows wherever the scene draws nothing. For None it hides itself and gives the viewport back the opaque `Color` it had when attached (black if that was already transparent), so the view looks as it always did.
>
> The kinds
>
> None: hidden; the viewport's own opaque colour shows.
> Solid: no bitmap; the control's area is filled with the colour.
> Gradient: a bitmap of at most 512 pixels along its longer side, each pixel coloured by the spec's own `GradientAtPoint` arithmetic (the same the off-screen grabs use), stretched smoothly to the control. A blend loses nothing by being stretched, and it stays quick to remake while the window is resized.
> Transparent (the checker): a bitmap at the display's real pixel size, drawn without smoothing so the square edges stay sharp. Squares are `CheckerSize` logical pixels, light at the top-left. Only two distinct rows exist, so each is painted once and copied to every other row.
>
> The bitmap is kept and only remade when the spec, the control's size or the display scale changes. `TSprite3DBackgroundSpec.NewBitmap` does the painting and can be used on its own.
>
> What went away
>
> All the workarounds for drawing a background in 3D are gone: the shader and Metal texture paths, the pairs of back-to-back planes, the pool of checker squares made at start-up, frustum-culling exclusions, the black Diffuse colour and its 1.25× brightness, stowing planes as specks, and hiding the background in orthographic view. The colours on screen are now exactly the colours chosen.
>
> Grabs and icons
>
> The off-screen pass draws the scene into a frame buffer of its own with its own clear colours, so the 2D background can never end up in a grab, and the main form no longer needs to hide it around a grab. As before, None and Transparent grab transparent, and Solid or Gradient are filled in afterwards, per pixel, so soft edges blend into them. On macOS and iOS, where a grab is a screenshot of the viewport, the screenshot no longer contains the background either; for Solid or Gradient the backdrop is painted under the screenshot at the grab size.
>
> Still to check
>
> Whether `MakeScreenshot` on Metal keeps the viewport's transparency, which decides whether Transparent grabs on macOS and iOS come out transparent or black.
