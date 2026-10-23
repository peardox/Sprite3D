# Directions

A sprite set usually shows a character from several sides: four, eight, sixteen or more views, one per direction it can face. Model, Directions sets how many directions there are, which way each one points, and the order they are taken in. This page explains each part of the dialog, how the order works, the directions file that Export and Import use, and where the code lives.

Nothing renders the directions yet. They are kept in `settings.json`, ready for the coming Project mode, which will use them to turn the model to each direction in turn.

## The dialog

```
+------------------------------------------------------------+
|                                  Directions                |
|        .-----N-----.             [ 8        v]              |
|      .'   8  1  2   '.                                      |
|     W   7  (arc)   3  E         Numbered                    |
|      '.   6  5  4   .'          (o) Clockwise               |
|        '-----S-----'            ( ) Anticlockwise           |
|                                 ( ) Custom (Change Order)   |
|                                                             |
|                                 Red marker points to        |
|                                     ( dial )                |
|                                     0° N                    |
|                                 [ ] Lock to directions      |
|                                                             |
| [Cancel] [Import...] [Change Order] [Export...]      [OK]   |
+------------------------------------------------------------+
```

- **The compass.** A white clock face with N, E, S and W round its edge, which never move. Each direction is a marker round the face, spread evenly. One marker is red, the clock's "12 o'clock"; the rest are black. Each marker shows its direction's number, from 1, when there are 32 or fewer (smaller above 16).
- **The arrow.** For a plain clockwise or anticlockwise order, an arc with an arrowhead in the centre, half the face's diameter, shows the way the numbers go up. For any other order the centre reads "Custom order".
- **Directions.** How many there are: 1, 2, or any multiple of 4 or 6 up to 64 (1, 2, 4, 6, 8, 12, 16, 18, 20, 24, 28, 30, 32, 36, 40, 42, 44, 48, 52, 54, 56, 60, 64). Changing it puts the order back to plain clockwise, or anticlockwise if it was that.
- **Numbered.** Clockwise or Anticlockwise numbers the directions round from the red marker. Custom shows that the order was set with Change Order. You can't choose Custom directly.
- **The dial.** Turns the red marker to any whole-degree bearing, in degrees clockwise from north. The bearing is shown beneath it.
- **Lock to directions.** Makes the dial move in steps of one direction, 360 divided by the number of directions, counted from north. With eight directions it stops only on N, NE, E and so on, so the usual bearings are easy to hit. Changing the number of directions snaps the bearing again.

With a single direction the red marker would normally point N, E, S or W, but any bearing will do.

### Compass point names

When the red marker is on one of the [32 points of the compass](https://en.wikipedia.org/wiki/Points_of_the_compass), its name is shown after the bearing, abbreviated as the mariner's compass does it:

| From | Points, 11.25° apart |
|---|---|
| N to E | N, NbE, NNE, NEbN, NE, NEbE, ENE, EbN |
| E to S | E, EbS, ESE, SEbE, SE, SEbS, SSE, SbE |
| S to W | S, SbW, SSW, SWbS, SW, SWbW, WSW, WbS |
| W to N | W, WbN, WNW, NWbW, NW, NWbN, NNW, NbW |

Only the eight main points fall on whole degrees. The others are on fractions (NNE is 22.5°, NbE 11.25°), so they are named only when the dial is locked to 16, 32 or 64 directions and stops on them. A bearing on a fraction is shown to two places, such as `11.25° NbE`. A bearing near a point, but not on it, has no name: 11° is just 11°.

## Positions and numbers

Two counts are in play, and keeping them apart is the key to the order:

- **Position** is where a marker sits round the face: 0 at the red marker, then 1, 2, 3 and so on, always clockwise. Position *p* points at *start* + *p* × 360 / *count* degrees.
- **Number** is the direction's place in the order: direction 1 is taken first, then direction 2, and so on. This is what the markers show.

The **order** lists, for direction 1, 2, 3 and so on, the position it is at. A plain clockwise order of eight is positions 0, 1, 2, 3, 4, 5, 6, 7. Anticlockwise is 0, 7, 6, 5, 4, 3, 2, 1. Any other order that uses every position exactly once is a custom order.

## Change Order

Artwork drawn or bought elsewhere often has its directions in a fixed order of its own, which needn't follow the compass round. Packs such as those at [PVGames](https://pvgames.itch.io/) are an example. Change Order makes the order match the artwork:

1. Click **Change Order**. Its text changes to **Stop Ordering**. The markers other than the red one go grey and the centre reads "Click direction 1 of 8".
2. Click the marker for the direction that comes first. **It becomes direction 1 and the red marker.** If it wasn't red already, the dial turns onto it straight away and the positions are counted from there.
3. Click the rest, in order. Each takes the next number and turns blue. A marker already numbered, or a click near the centre, is ignored.
4. When every marker has its number, the order is kept and **Custom** is selected. If the order you clicked happens to be plain clockwise or anticlockwise, that button is selected instead.

Clicking Stop Ordering before the end, changing the number of directions, choosing Clockwise or Anticlockwise, or pressing OK or Cancel abandons it. The order and the dial go back to what they were.

### Example

Some art lists its eight directions as E, S, W, N, SE, SW, NW, NE. With N red to begin with:

| Click | Marker | What happens |
|---|---|---|
| 1st | E | The dial turns to 90°, E; E becomes position 0, direction 1 |
| 2nd | S | position 2, direction 2 |
| 3rd | W | position 4, direction 3 |
| 4th | N | position 6, direction 4 |
| 5th | SE | position 1, direction 5 |
| 6th | SW | position 3, direction 6 |
| 7th | NW | position 5, direction 7 |
| 8th | NE | position 7, direction 8 |

The order is 0, 2, 4, 6, 1, 3, 5, 7 from a start of 90°, stored as `1,3,5,7,2,4,6,8` (positions from 1). The same bearings could also be written with N as position 0 and a start of 0°: `3,5,7,1,4,6,8,2`. A directions file or `settings.json` may hold either form, and both give the same directions.

## Export and Import

If you switch between asset packs, you may need to set the order again and again. **Export...** writes everything the dialog holds to a JSON file, and **Import...** reads one back into the dialog. An imported file, like any other change in the dialog, takes effect only when you press OK. Both buttons open in the folder last used (`directionsFolder` in `settings.json`). They are on the desktop only, since Android and iOS have no file dialog for them.

The file, for the example above:

```json
{
  "format": "Sprite3D directions",
  "version": 1,
  "count": 8,
  "start": 90,
  "snap": true,
  "clockwise": true,
  "order": [1, 3, 5, 7, 2, 4, 6, 8],
  "directions": [
    { "number": 1, "position": 1, "bearing": 90,  "point": "E" },
    { "number": 2, "position": 3, "bearing": 180, "point": "S" },
    { "number": 3, "position": 5, "bearing": 270, "point": "W" },
    { "number": 4, "position": 7, "bearing": 0,   "point": "N" },
    { "number": 5, "position": 2, "bearing": 135, "point": "SE" },
    { "number": 6, "position": 4, "bearing": 225, "point": "SW" },
    { "number": 7, "position": 6, "bearing": 315, "point": "NW" },
    { "number": 8, "position": 8, "bearing": 45,  "point": "NE" }
  ]
}
```

| Member | Needed | Meaning |
|---|---|---|
| `format` | no | `"Sprite3D directions"`; anything else is refused, so another JSON file isn't taken for one |
| `version` | no | the file layout, now 1; a newer one is refused |
| `count` | yes | how many directions; must be one of the counts above |
| `start` | yes | the red marker's bearing, position 0's, in degrees clockwise from north |
| `snap` | no | whether the dial is locked to directions; false if left out |
| `clockwise` | no | used only when `order` is left out: true for plain clockwise (the default), false for anticlockwise |
| `order` | no | the positions, counted from 1 at the red marker, in the order the directions are taken in; must use every position from 1 to `count` exactly once |
| `directions` | no | each direction spelt out, for people and other tools to read; Import ignores it |

Anything else in the file is ignored, so a file can carry notes of its own, such as which pack it is for. A file that can't be used is reported in plain words and changes nothing.

## Settings

OK keeps the choice in `settings.json`:

| Key | Holds |
|---|---|
| `directionCount` | the number of directions |
| `directionStart` | the red marker's bearing |
| `directionClockwise` | for a plain order, which way it goes |
| `directionOrder` | a custom order, as positions from 1 separated by commas, such as `1,3,5,7,2,4,6,8`; empty for a plain order |
| `directionSnap` | whether the dial is locked to directions |
| `directionsFolder` | where Export and Import last looked |

## In the code

| Where | What |
|---|---|
| `src/ui/Sprite3DDirectionsForm.pas`, `.fmx` | `TDirectionsForm`, the dialog: drawing the compass, Change Order, the dial lock, Export and Import |
| `src/ui/Sprite3DHelpers.pas` | `DIRECTION_COUNTS`, `NearestDirectionCount`, `PlainDirectionOrder`, `IsDirectionOrder`, `DirectionOrderToText`, `DirectionOrderFromText`, `CompassPointName`, `SaveDirectionsFile`, `LoadDirectionsFile`, `EDirectionsFile`; and in `TSprite3DAppSettings`, the settings above with `DirectionOrderList` and `DirectionBearings` |
| `src/ui/Sprite3dMain.pas` | `DirectionsItemClick` shows the dialog; `ApplyDirections` keeps and saves the result |

`DirectionBearings` is how the rest of the program reads the result: one bearing per direction, in the order they are taken in.

Each routine's own documentation comments, in the source, give the details.

## Further reading

- [Points of the compass](https://en.wikipedia.org/wiki/Points_of_the_compass), Wikipedia: the 32 points and their names.
- [Bearing (angle)](https://en.wikipedia.org/wiki/Bearing_(angle)), Wikipedia: angles measured clockwise from north.
- [PVGames](https://pvgames.itch.io/): an example of sprite packs whose directions come in an order of their own.
- [Volumes](volumes.md): how the model is framed, the same for every direction.
