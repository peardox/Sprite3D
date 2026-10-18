### Explain how the OffScreen Rendering works

> The offscreen render is a Gorilla3D render pass that stays switched off until you ask for a grab. It then draws the scene one extra time into its own frame buffer, reads the pixels back, and works out transparency by drawing the frame over different backgrounds.
>
> **1. Setting up the pass**
>
> `TSprite3DOffscreen` descends from `TGorillaRenderPassController`. The constructor makes it a pre-pass (`TRenderPassType.Pre`) that renders the whole scene list into a frame buffer (`RenderListToFBO`) with the models’ own materials. `ApplyTargetSize` sets `OverwriteViewportSize` and `ViewportWidth`/`ViewportHeight` to `Width` × `Height`, so the pass draws at the grab size, not the window size. `Enabled` is `False`, so it costs nothing between grabs.
>
> **2. `Grab`**
>
> `Grab` returns immediately. It marks the pass busy, stores your callback, and picks a stage:
>
> - **`STAGE_OPAQUE`:** one drawing over `OpaqueBackground`, used when `TransparentBackground` is `False`.
> - **`STAGE_ITERATIONS`:** one frame, drawn several times with different clear colours: black, white, and 50% grey on the first grab only.
> - **`STAGE_FRAMES`:** the same drawings, but one per frame. This is the fallback.
>
> It then calls `Prepare`, which runs `OnBeforeGrab` so the owner can fit the camera to the target, enables the pass, and invalidates the viewport to force a frame.
>
> **3. The render frame**
>
> `HandleBeginRender` sets the clear colour for each iteration. `HandleEndRender` runs while the GL context is still current and does the read:
>
> - `ReadPixels` takes the pass’s output texture and loads the GL functions at run time. It makes a temporary frame buffer for reading, attaches the texture, and calls `glReadPixels` as RGBA bytes. If that errors, it retries as floats, which OpenGL ES needs for float targets.
> - It restores the old read binding and pack alignment before returning.
> - It reads the area of the GL viewport the pass just used, because with display scaling the texture can be larger than the target.
> - `Restore` then runs `OnAfterGrab`, putting the camera back before the main pass draws the same frame. That is why the screen never shows the grab’s framing.
>
> **4. Transparency by difference matting**
>
> Gorilla’s passes don’t keep alpha, so alpha is rebuilt from two or three drawings. A pixel with colour c and alpha a draws as c·a over black and c·a + (1 − a) over white, so the difference between the two is 1 − a. `BuildMatte` averages the three channel differences to get alpha, and the over-black value is already the premultiplied colour FMX wants. A pixel that is the same in both drawings is fully opaque. A pixel where black shows as black and white as white is background.
>
> The grey drawing exists to find out whether the renderer gamma-encodes its output after blending. `MeasureEncoding` looks at the pixels where the background shows fully and takes the median of the grey reading. About 128 means linear and about 186 means sRGB-encoded. If it’s encoded, `BuildMatte` decodes to linear light, does the maths there, and re-encodes the colour. The answer is cached in `FOutputKnown`.
>
> **5. The fallback**
>
> If the clear colour doesn’t change between iterations, the black and white drawings come out identical. The code detects this with `DrawingsDiffer` and calls `StartNextFrame`, which restores the scene, queues itself with `TThread.ForceQueue`, and re-prepares the next frame before drawing the next background. If frame-by-frame works where iterations didn’t, `FUseFrames` is set so later grabs skip the failed attempt. The pass stays enabled throughout, because the comments note that switching it off from inside its own render isn’t safe.
>
> **6. After the matte**
>
> `FillBackdrop` applies the Solid or Gradient background after the matting, using the pixel’s own transparency, so soft edges blend into the backdrop as they would on screen. `PixelsToBitmap` flips the rows, since GL reads bottom row first, and handles BGRA or RGBA byte order. `Deliver` queues the result to the main thread, outside the render loop, so your callback can save files or show dialogs. It scales if the read size differed from `Width` × `Height`, frees the bitmap after the callback, and uses an alive flag so a delivery that runs after the pass was freed does nothing.
>
> **7. `GrabSizes`**
>
> This is what icons use. A `TGrabSizesJob` sets `Width` and `Height` to each size in turn and grabs, then starts the next grab from inside the previous callback. It keeps copies of each bitmap, restores the original size at the end, and calls your procedure once with all the images.
>
> **A caveat for macOS**
>
> The unit’s header says read-back works on every platform where Gorilla renders with OpenGL, and for macOS it loads `OpenGL.framework`. Your earlier console output said “GLSL to MSL conversion failed”, which means Gorilla is converting shaders to Metal on this machine. If the context is Metal, the output texture’s `Handle` isn’t a GL texture name and `glReadPixels` on it would fail, or read the wrong thing. That would show up as “The off-screen pass has no output texture yet” or “frame buffer status” errors in the grab callback. I can’t tell from the code which backend your Gorilla 1.5 build uses on macOS 27, so check whether grabs work once the shader problem is fixed. If they fail, the GL read-back is the thing to look at, and it needs a Metal path or a different read mechanism.