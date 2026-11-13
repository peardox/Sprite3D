//** @abstract(The Library: the user's collections of models, each shown as thumbnails in
//** groups, with a 3D preview of the one selected.)
//**
//** File, Library calls ShowLibrary. The library (LoadLibrary) lists artists, and under each
//** their collections (ArtistBar: the artist shown, Add Artist, Add Artist Collections, and
//** rename or delete; a collection with no artist goes under UNASSIGNED_ARTIST, and can be moved
//** to another from its menu). Each collection is a set of models from one or more folders with
//** its own palette of groups; CollectionBar chooses the one shown, adds a new one (folders,
//** then a name), adds many at once, rescans it, and renames or deletes it. A collection opens
//** from what was saved (OpenCollection); its folders are read only when it has never been, or
//** on Rescan (ScanCollection), which finds every model in them (AssetModelFiles). Their keys,
//** the SHA-256 of each model's content (TSprite3DAssetHasher, from Sprite3DAssetCache), are
//** worked out on a worker thread, as that is only reading files. A model whose key the
//** thumbnail cache knows, with a thumbnail of THUMBNAIL_SIZE, is shown from the cache at once;
//** every other one is queued, and its thumbnail made, one model at a time: loaded into the
//** form's own viewport, turned upright, framed in a fixed isometric view in orthographic
//** projection as Sprite3D frames a model, left on screen for THUMBNAIL_SETTLE_MS so the
//** viewport has drawn it, and grabbed off screen by a TSprite3DOffscreen at THUMBNAIL_SIZE
//** square, with a transparent background. The PNG and the model's metadata, its bounding box
//** among it, go into the cache, so the next time the folder is opened nothing need be made. Two
//** files with the same key are one model: the second is noted in the log and not shown again.
//**
//** The groups are down the left, in GroupsBox, one button each: its icon above its name and
//** how many models it has. Clicking one, or Up and Down, chooses it, and its thumbnails fill
//** the right, in name order. A group's icon is the one chosen for it from the icon library
//** (GroupIconsFolder, then the user's own, TSprite3DAppSettings.UserGroupIconsFolder), or
//** else the library's icon named after the group, or else the thumbnail of its first model.
//** A right-click on the groups opens GroupMenu: Add Group, Rename Group, Change Icon and,
//** for a group with no models anywhere and no groups inside, Delete Group.
//**
//** Groups nest, as folders do, and are in alphabetical order, case ignored, at every level.
//** A group dragged into the grid goes inside the group shown, dragged onto a group's tile
//** or button, inside that one, and dragged below the buttons, back to the top. A drag held
//** at the top or bottom edge of the groups or the grid scrolls it. The left shows the top
//** groups; the groups inside the one shown are tiles at the start of its grid, opened with
//** a double-click; PathBar shows where the group shown is, and UpButton, or Backspace, goes
//** up. A right-click on the grid adds a group inside the one shown. Names are unique at
//** every level. Counts take in the groups inside.
//**
//** A model's group is the one the palette gives it, or else the word of its name
//** AssetGroupNames picks for the collection, first or last, with a plural group put with its
//** singular when the folder has both, and a model alone in its group put in Unsorted
//** (CollapseSmallGroups); Regroup Collection does that again for every model. Thumbnails are picked as
//** files are: a click picks one, Control and a click adds or takes one away, Shift and a
//** click picks the run from the last one clicked. Dragging a picked thumbnail onto a group
//** moves every picked model there. The drags are the form's own, with the mouse
//** captured, not FMX's drag and drop, which hands over to the system's and is not on every
//** platform the program is built for. The groups, where each is, with their icons and the
//** key of every model in each, are the palette, kept in the cache (LoadAssetPalette), so the
//** arrangement comes back next time; groups of other kits are kept in it but not shown.
//**
//** Clicking a thumbnail also shows its name, group, size in its own units and file, and,
//** once every thumbnail is made, the model itself in the viewport at the top left, in the
//** thumbnails' view to start with. Dragging across the viewport turns it, up and down tilts
//** it, right round if need be, the wheel zooms, and a right-click puts the thumbnails' view
//** back. While thumbnails are being made, the viewport shows each one as it is made.
//**
//** Dragging a thumbnail onto the level is the next step; it is not here yet, and will take
//** one model at a time.
//**
//** Closing the form stops making thumbnails; those made so far stay in the cache, and opening
//** the collection again carries on from there. Everything the form has to report goes to OnLog,
//** for the Debug tab, and to the import log, begun again by each artist import or rescan;
//** every error goes to the error log too (ErrorLogFile), which is begun only at start-up
//** (BeginErrorLog), so it holds every error of the session. Rescan All Collections, on
//** ArtistMenu, reads every collection of the artist shown again, one after another. For
//** the main thread only, but for the hashing, which keeps to its own
//** data and hands back its results with @code(TThread.Queue).
//**
//** @preformatted(
//** TAssetsForm
//** |-- ArtistBar         ArtistLabel, ArtistCombo, ArtistMenuButton, NewArtistButton,
//** |                     AddArtistButton
//** |-- CollectionBar     CollectionLabel, CollectionCombo, CollectionMenuButton,
//** |                     RescanButton, AddCollectionButton
//** |-- GroupsBox         TVertScrollBox, left: a button per group, made in code
//** |-- GroupsSplitter
//** |-- TopLayout
//** |   |-- PreviewArea     dark grey; the TGorillaViewport, made in code, fills it
//** |   `-- InfoLayout      StatusLabel, Progress, NameLabel, SizeLabel, FileLabel, HelpLabel
//** |-- TilesPanel          outlined while a group dragged would go into the one shown
//** |   |-- PathBar         UpButton, PathLabel
//** |   `-- TilesBox        TVertScrollBox
//** |       `-- FTilesLayout  made in code: the inner groups' tiles, then every model's;
//** |                         the chosen group's shown
//** |-- GroupMenu         TPopupMenu: AddGroupItem, RenameGroupItem, IconGroupItem,
//** |                     DeleteGroupItem
//** |-- CollectionMenu    TPopupMenu: RenameCollectionItem, MoveCollectionItem,
//** |                     RemakeThumbnailsItem, RegroupItem, ScanSuspectItem,
//** |                     DeleteCollectionItem
//** |-- ArtistMenu        TPopupMenu: RenameArtistItem, RescanArtistItem,
//** |                     RemakeArtistItem, DeleteArtistItem
//** `-- IconDialog        TOpenDialog, for Change Icon
//** )
unit Sprite3DBuilderAssetsForm;

{
  The Library: the user's collections of models, each shown as thumbnails
  in groups, with a 3D preview of the one selected.

  File, Library calls ShowLibrary. Each collection is a set of models from
  one or more folders with its own palette of groups; CollectionBar chooses
  the one shown, adds one or many at once, rescans, renames or deletes
  it. A collection opens from what was saved; its folders are read only
  when it has never been, or on Rescan (ScanCollection),
  which finds every model in them (AssetModelFiles). Their keys, the
  SHA-256 of each model's content (TSprite3DAssetHasher, from
  Sprite3DAssetCache), are worked out on a worker thread, as that is only
  reading files. A model whose key the thumbnail cache knows, with a
  thumbnail of THUMBNAIL_SIZE, is shown from the cache at once; every other
  one is queued, and its thumbnail made, one model at a time, in the form's
  own viewport, and grabbed off screen with a transparent background. The
  PNG and the model's metadata go into the cache.

  The groups are down the left, in GroupsBox, one button each: its icon
  above its name and how many models it has. Clicking one, or Up and Down,
  chooses it, and its thumbnails fill the right. A group's icon is the one
  chosen for it from the icon library, or the library's icon named after
  the group, or the thumbnail of its first model. A right-click on the
  groups opens GroupMenu: Add Group, Rename Group, Change Icon and, for a
  group with no models anywhere, Delete Group.

  Groups nest, as folders do: dragged into the grid, a group goes inside the
  one shown; onto a group's tile, inside that one; below the buttons, back
  to the top. Inner groups are tiles at the start of the grid, opened with
  a double-click; PathBar shows the path, and Up or Backspace goes up.

  Thumbnails are picked as files are: click, Control-click, Shift-click.
  Dragging a picked thumbnail onto a group moves every picked model there.
  Groups are in alphabetical order at every level; a drag held at the edge
  of the groups or the grid scrolls it. The drags are the form's own, with
  the mouse captured, not FMX's drag and drop. The groups, with their icons
  and their models' keys, are the palette, kept in the cache, so the
  arrangement comes back next time.

  Clicking a thumbnail also shows its details and, once every thumbnail is
  made, the model itself in the viewport, which the mouse turns, tilts and
  zooms. Closing the form stops making thumbnails. Everything the form has
  to report goes to OnLog. For the main thread only, but for the hashing.

    TAssetsForm
    |-- CollectionBar     the collection drop-down and the library's buttons
    |-- GroupsBox         TVertScrollBox, left: a button per group, made in code
    |-- GroupsSplitter
    |-- TopLayout
    |   |-- PreviewArea     dark grey; the TGorillaViewport, made in code, fills it
    |   `-- InfoLayout      StatusLabel, Progress, NameLabel, SizeLabel, FileLabel, HelpLabel
    |-- TilesPanel          outlined while a group dragged would go into the one shown
    |   |-- PathBar         UpButton, PathLabel
    |   `-- TilesBox        TVertScrollBox
    |       `-- FTilesLayout  made in code: the inner groups' tiles, then the models'
    |-- GroupMenu         TPopupMenu: AddGroupItem, RenameGroupItem, IconGroupItem,
    |                     DeleteGroupItem
    |-- CollectionMenu    TPopupMenu: RenameCollectionItem, MoveCollectionItem,
    |                     RemakeThumbnailsItem, RegroupItem, ScanSuspectItem,
    |                     DeleteCollectionItem
    `-- IconDialog        TOpenDialog, for Change Icon
}

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Math.Vectors,
  System.Generics.Collections, System.Diagnostics,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.StdCtrls, FMX.Layouts,
  FMX.Objects, FMX.Controls.Presentation, FMX.Types3D, FMX.Menus, FMX.Dialogs, FMX.ListBox,
  Gorilla.Viewport, Gorilla.Model, Gorilla.Camera, Spritely.OrbitalCamera,
  Sprite3DOffscreen, Sprite3DAssetCache, Sprite3DBackground, Sprite3DGrid,
  Sprite3DModelTextures, Sprite3DLevelPlacement;

type
  //** @abstract(Receives a line for the log; see TAssetsForm.OnLog.)
  //**
  //** @param(AText The line.)
  TAssetsLogEvent = reference to procedure(const AText: String);

  //** @abstract(Receives the preview background chosen; see TAssetsForm.OnPreviewBackground.)
  //**
  //** @param(AKey Its key: @code(checker), @code(black), @code(grey) or @code(white).)
  TAssetsBackgroundEvent = reference to procedure(const AKey: String);

  //** @abstract(Tells the level which models are chosen in the Library, to place; see
  //** TAssetsForm.OnModelChosen.)
  //**
  //** @param(ASpecs The models picked that can be placed (each has a thumbnail, and so a
  //** box): their names, files, keys and boxes, the one clicked first. Placing more than
  //** one picks among them at random for each piece.)
  //**
  //** @param(ALeftOut The names of the models picked that cannot be placed yet, as their
  //** thumbnails are still to be made.)
  TAssetsModelChosenEvent = reference to procedure(const ASpecs: TArray<TSprite3DPieceSpec>;
    const ALeftOut: TArray<String>);

  //** @abstract(One model's key, the files it names, and why it has none, as the hashing
  //** worker hands them back.)
  TAssetHashResult = record
    //** @abstract(The model file, as a full path.)
    FileName: String;
    //** @abstract(Its key; empty if Error is set.)
    Hash: String;
    //** @abstract(The files it names; see TSprite3DAssetHasher.HashModel.)
    Files: TArray<String>;
    //** @abstract(Why there is no key; empty if there is one.)
    Error: String;
  end;

  //** @abstract(One model shown on the form: its metadata, its tile, and whether its
  //** thumbnail is there yet.)
  TAssetEntry = record
    //** @abstract(Its metadata, from the cache or as its thumbnail is made.)
    Meta: TSprite3DAssetMeta;
    //** @abstract(Its tile in FTilesLayout; nil until the tiles are made.)
    Tile: TRectangle;
    //** @abstract(The image on Tile showing the thumbnail.)
    Image: TImage;
    //** @abstract(On Tile's top right corner: the model's kind, as ModelKindTag gives it;
    //** hidden while it has none, as for a static model.)
    Badge: TRectangle;
    //** @abstract(The text on Badge.)
    BadgeText: TLabel;
    //** @abstract(On Badge's left: the model's material variants, as how many it has, or
    //** the one chosen; empty for a model without.)
    VariantText: TLabel;
    //** @abstract(The material variant pieces of it are placed as, and the preview shows: an
    //** index into Meta.Variants, or BASE_VARIANT (-1) for the model as made. Chosen by
    //** right-clicking its tile; for this session only.)
    Variant: Integer;
    //** @abstract(True once the thumbnail is in the cache and on Tile.)
    HasThumbnail: Boolean;
    //** @abstract(True if Meta.Group came from the palette, so it is not merged with
    //** another.)
    GroupChosen: Boolean;
    //** @abstract(True while the thumbnail is picked, to be dragged with the others picked.)
    Picked: Boolean;
  end;

  //** @abstract(Says whether the form is still there, for work handed back from another
  //** thread.)
  IAssetsAlive = interface
    ['{6C2B0E5A-3D41-4E8B-9A7F-1B5C8D2E4F60}']
    //** @abstract(True until the form is freed.)
    //**
    //** @returns(Whether the form is still there.)
    function Alive: Boolean;
    //** @abstract(Marks the form as gone.)
    procedure Kill;
  end;

  //** @abstract(What GroupNameClosed is answering: a new group, or a new name.)
  TGroupNameAsk = (
    //** @abstract(Nothing asked.)
    gnNone,
    //** @abstract(Add Group: the new group goes after FMenuGroup, or last.)
    gnAdd,
    //** @abstract(Rename Group: FMenuGroup's new name.)
    gnRename,
    //** @abstract(Add New Asset Collection: the name of the collection of FNewSources.)
    gnNewCollection,
    //** @abstract(Rename Collection: the open collection's new name.)
    gnRenameCollection,
    //** @abstract(Add Artist: a new artist's name.)
    gnNewArtist,
    //** @abstract(Rename Artist: the artist shown's new name.)
    gnRenameArtist);

  //** @abstract(The Assets form; see the unit's description.)
  TAssetsForm = class(TForm)
    //** @abstract(Along the very top: the artist shown, and what can be done to artists.)
    ArtistBar: TLayout;
    //** @abstract(Says "Artist".)
    ArtistLabel: TLabel;
    //** @abstract(The library's artists; choosing one shows their collections.)
    ArtistCombo: TComboBox;
    //** @abstract(Opens ArtistMenu.)
    ArtistMenuButton: TButton;
    //** @abstract(Rename, Rescan All Collections and Delete for the artist shown.)
    ArtistMenu: TPopupMenu;
    //** @abstract(Rename Artist...)
    RenameArtistItem: TMenuItem;
    //** @abstract(Rescan All Collections: every collection of the artist shown read again
    //** and its thumbnails made, one after another, as an artist import does.)
    RescanArtistItem: TMenuItem;
    //** @abstract(Remake All Thumbnails: as Rescan All Collections, but every thumbnail is
    //** made again, cached or not.)
    RemakeArtistItem: TMenuItem;
    //** @abstract(Delete Artist: the artist and their collections, from the library.)
    DeleteArtistItem: TMenuItem;
    //** @abstract(Add Artist...: a new artist, by name.)
    NewArtistButton: TButton;
    //** @abstract(Along the top: the collection open, and what can be done to the library.)
    CollectionBar: TLayout;
    //** @abstract(Says "Collection".)
    CollectionLabel: TLabel;
    //** @abstract(The library's collections; choosing one opens it.)
    CollectionCombo: TComboBox;
    //** @abstract(Add New Asset Collection...: folders, then a name, for a new collection.)
    AddCollectionButton: TButton;
    //** @abstract(Add Artist Collections...: a collection for each folder in the folders
    //** chosen, named after it.)
    AddArtistButton: TButton;
    //** @abstract(Rescan: the collection's folders read again, for models added, changed or
    //** gone.)
    RescanButton: TButton;
    //** @abstract(Opens CollectionMenu.)
    CollectionMenuButton: TButton;
    //** @abstract(Rename and Delete for the collection open.)
    CollectionMenu: TPopupMenu;
    //** @abstract(Rename Collection...)
    RenameCollectionItem: TMenuItem;
    //** @abstract(Delete Collection: from the library; its models and thumbnails stay.)
    DeleteCollectionItem: TMenuItem;
    //** @abstract(Remake Thumbnails: the collection's folders read again and every
    //** thumbnail made again, cached or not, as after a fix to how models are loaded.)
    RemakeThumbnailsItem: TMenuItem;
    //** @abstract(Regroup Collection...: its groups thrown away, after asking, and every
    //** model grouped again from its name.)
    RegroupItem: TMenuItem;
    //** @abstract(Scan for Suspect Models...: the median model size, and the models far
    //** smaller or larger, to look at and mark good or bad.)
    ScanSuspectItem: TMenuItem;
    //** @abstract(Move to Artist: a sub-menu of the other artists, made as CollectionMenu
    //** opens; choosing one puts the collection under them.)
    MoveCollectionItem: TMenuItem;
    //** @abstract(The groups, down the left: a button per group, made by BuildGroups.)
    GroupsBox: TVertScrollBox;
    //** @abstract(Between GroupsBox and the rest, to widen the groups.)
    GroupsSplitter: TSplitter;
    //** @abstract(The strip along the top: PreviewArea and InfoLayout.)
    TopLayout: TLayout;
    //** @abstract(Dark grey behind the viewport made in FormCreate, which fills it; it takes
    //** the mouse for the preview.)
    PreviewArea: TRectangle;
    //** @abstract(Right of PreviewArea: the status, the progress and the selected model's
    //** details.)
    InfoLayout: TLayout;
    //** @abstract(What the form is doing: reading the folder, making thumbnails, or done.)
    StatusLabel: TLabel;
    //** @abstract(How far making the thumbnails has got; shown only while a collection's
    //** folders are being read or its thumbnails made.)
    Progress: TProgressBar;
    //** @abstract(The selected model's name and group.)
    NameLabel: TLabel;
    //** @abstract(The selected model's size, in its own units.)
    SizeLabel: TLabel;
    //** @abstract(The selected model's file.)
    FileLabel: TLabel;
    //** @abstract(How to use the preview, the thumbnails and the groups.)
    HelpLabel: TLabel;
    //** @abstract(Holds PathBar and TilesBox; outlined while a group dragged over it would
    //** go into the group shown.)
    TilesPanel: TRectangle;
    //** @abstract(Above the tiles: UpButton and PathLabel.)
    PathBar: TLayout;
    //** @abstract(Goes up to the group the one shown is inside.)
    UpButton: TButton;
    //** @abstract(The group shown, with the groups it is inside, from the top.)
    PathLabel: TLabel;
    //** @abstract(Scrolls the chosen group's groups and tiles.)
    TilesBox: TVertScrollBox;
    //** @abstract(The groups' right-click menu.)
    GroupMenu: TPopupMenu;
    //** @abstract(Add Group...: a new empty group after the one clicked, or last.)
    AddGroupItem: TMenuItem;
    //** @abstract(Rename Group...: a new name for the group clicked.)
    RenameGroupItem: TMenuItem;
    //** @abstract(Change Icon...: an icon from the library, or any PNG or SVG, for the group
    //** clicked.)
    IconGroupItem: TMenuItem;
    //** @abstract(The line above Delete Group.)
    GroupMenuSeparator: TMenuItem;
    //** @abstract(Delete Group: only for a group with no models anywhere.)
    DeleteGroupItem: TMenuItem;
    //** @abstract(Chooses a group's icon.)
    IconDialog: TOpenDialog;
    //** @abstract(Makes the viewport, its camera, the off-screen pass and the timers.)
    //**
    //** @param(Sender The form.)
    procedure FormCreate(Sender: TObject);
    //** @abstract(Lets go of everything still to come back: the hashing's results and a
    //** grab under way are dropped.)
    //**
    //** @param(Sender The form.)
    procedure FormDestroy(Sender: TObject);
    //** @abstract(Stops making thumbnails and hides the form.)
    //**
    //** @param(Sender The form.)
    //**
    //** @param(Action Left as caHide, so the form is kept for the next folder.)
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    //** @abstract(Up and Down choose the top group above or below; Backspace goes up to the
    //** group the one shown is inside.)
    //**
    //** @param(Sender The form.)
    //**
    //** @param(Key The key; set to 0 when taken.)
    //**
    //** @param(KeyChar The character.)
    //**
    //** @param(Shift The keys held.)
    procedure FormKeyDown(Sender: TObject; var Key: Word; var KeyChar: WideChar;
      Shift: TShiftState);
    //** @abstract(Lays the tiles out again for the new width.)
    //**
    //** @param(Sender TilesBox.)
    procedure TilesBoxResize(Sender: TObject);
    //** @abstract(A right-click on the space below the groups opens GroupMenu for no group;
    //** a group dropped there goes last.)
    //**
    //** @param(Sender GroupsBox.)
    //**
    //** @param(Button The button.)
    //**
    //** @param(Shift The keys and buttons held.)
    //**
    //** @param(X Where, across GroupsBox.)
    //**
    //** @param(Y Where, down GroupsBox.)
    procedure GroupsBoxMouseUp(Sender: TObject; Button: TMouseButton; Shift: TShiftState;
      X, Y: Single);
    //** @abstract(A right-click on the tiles' empty space opens GroupMenu to add a group
    //** inside the one shown.)
    //**
    //** @param(Sender TilesBox.)
    //**
    //** @param(Button The button.)
    //**
    //** @param(Shift The keys and buttons held.)
    //**
    //** @param(X Where, across TilesBox.)
    //**
    //** @param(Y Where, down TilesBox.)
    procedure TilesBoxMouseUp(Sender: TObject; Button: TMouseButton; Shift: TShiftState;
      X, Y: Single);
    //** @abstract(Shows the group the one shown is inside.)
    //**
    //** @param(Sender UpButton.)
    procedure UpButtonClick(Sender: TObject);
    //** @abstract(Asks for a new group's name.)
    //**
    //** @param(Sender AddGroupItem.)
    procedure AddGroupItemClick(Sender: TObject);
    //** @abstract(Asks for the group's new name.)
    //**
    //** @param(Sender RenameGroupItem.)
    procedure RenameGroupItemClick(Sender: TObject);
    //** @abstract(Chooses the group's icon with IconDialog, in the icon library.)
    //**
    //** @param(Sender IconGroupItem.)
    procedure IconGroupItemClick(Sender: TObject);
    //** @abstract(Deletes the group, if it has no models anywhere.)
    //**
    //** @param(Sender DeleteGroupItem.)
    procedure DeleteGroupItemClick(Sender: TObject);
    //** @abstract(Opens the collection chosen.)
    //**
    //** @param(Sender CollectionCombo.)
    procedure CollectionComboChange(Sender: TObject);
    //** @abstract(Shows the artist chosen: the collection of theirs open last, or their
    //** first.)
    //**
    //** @param(Sender ArtistCombo.)
    procedure ArtistComboChange(Sender: TObject);
    //** @abstract(Asks a new artist's name.)
    //**
    //** @param(Sender NewArtistButton.)
    procedure NewArtistButtonClick(Sender: TObject);
    //** @abstract(Opens ArtistMenu under the button.)
    //**
    //** @param(Sender ArtistMenuButton.)
    procedure ArtistMenuButtonClick(Sender: TObject);
    //** @abstract(Asks the artist's new name.)
    //**
    //** @param(Sender RenameArtistItem.)
    procedure RenameArtistItemClick(Sender: TObject);
    //** @abstract(Rescans every collection of the artist shown, one after another (NextBulk),
    //** each one's folders read again (ScanCollection) and the thumbnails it still lacks
    //** made; then the collection open before is shown, with a summary that says how many
    //** errors there were.)
    //**
    //** The import log is begun again, as for an artist import; the error log, ErrorLogFile,
    //** is only added to. Choosing another collection or closing the Library stops it.
    //**
    //** @param(Sender RescanArtistItem.)
    procedure RescanArtistItemClick(Sender: TObject);
    //** @abstract(As RescanArtistItemClick, but every thumbnail of every collection of the
    //** artist shown is made again, cached or not.)
    //**
    //** @param(Sender RemakeArtistItem.)
    procedure RemakeArtistItemClick(Sender: TObject);
    //** @abstract(Reads the collection's folders again and makes every thumbnail again,
    //** cached or not.)
    //**
    //** @param(Sender RemakeThumbnailsItem.)
    procedure RemakeThumbnailsItemClick(Sender: TObject);
    //** @abstract(Asks, then throws away the collection's groups, with their icons and
    //** where they are, and groups every model again from its name (AssetGroupNames), as when
    //** it was first opened.)
    //**
    //** @param(Sender RegroupItem.)
    procedure RegroupItemClick(Sender: TObject);
    //** @abstract(Opens the Scan for Suspect Models dialog on the collection open: every
    //** model with a size (a thumbnail), with its verdict from the database.)
    //**
    //** @param(Sender ScanSuspectItem.)
    procedure ScanSuspectItemClick(Sender: TObject);
    //** @abstract(Regroups the collection, if the user said Yes; the regroup dialog's answer.)
    //**
    //** @param(Sender The dialog's context; not used.)
    //**
    //** @param(AResult How the dialog was closed.)
    procedure RegroupClosed(Sender: TObject; const AResult: TModalResult);
    //** @abstract(Asks, then takes the artist and their collections out of the library.)
    //**
    //** @param(Sender DeleteArtistItem.)
    procedure DeleteArtistItemClick(Sender: TObject);
    //** @abstract(Chooses folders for a new collection, then asks its name.)
    //**
    //** @param(Sender AddCollectionButton.)
    procedure AddCollectionButtonClick(Sender: TObject);
    //** @abstract(Makes a collection of each folder directly inside the folders chosen, such
    //** as each pack in an artist's folder, named after it, in one go.)
    //**
    //** They go under the artist shown (BulkArtist). With none shown, or Unassigned, each
    //** folder chosen is the artist, named after it, so a product line folder (such as one
    //** artist's packs under a brand name) still lands under the artist chosen first.
    //**
    //** Each is searched for models (FindModelFolders). The first time, the user is asked
    //** which format to take (AskFormat), and that becomes the default; a folder with that
    //** format gets it, the engine copies left out (DefaultModelFolders), without asking. A
    //** folder with none of the defaults so far asks again: Import adds the format chosen as
    //** the next default, Skip passes it over and rejects the formats it offered, which are
    //** not offered again, so a later folder with only rejected formats is passed over
    //** without asking, Only My Defaults
    //** passes over it and every later one like it, Stop ends there. A folder with no models, or the name of a collection
    //** already in the library, is passed over. Then each is imported in full, one after
    //** another (NextBulk): its folders read and its thumbnails made, the status saying which
    //** of how many. The first made is opened, and a summary shown, at the end. Choosing
    //** another collection or closing the Library stops it; the rest are imported as each is
    //** opened.
    //**
    //** @param(Sender AddArtistButton.)
    procedure AddArtistButtonClick(Sender: TObject);
    //** @abstract(Reads the collection's folders again.)
    //**
    //** @param(Sender RescanButton.)
    procedure RescanButtonClick(Sender: TObject);
    //** @abstract(Opens CollectionMenu under the button.)
    //**
    //** @param(Sender CollectionMenuButton.)
    procedure CollectionMenuButtonClick(Sender: TObject);
    //** @abstract(Puts the collection open under the artist chosen from the Move to Artist
    //** sub-menu, and shows that artist.)
    //**
    //** @param(Sender The sub-menu's item; its Tag is the artist's index in FLibrary.Artists.)
    procedure MoveToArtistClick(Sender: TObject);
    //** @abstract(Asks the collection's new name.)
    //**
    //** @param(Sender RenameCollectionItem.)
    procedure RenameCollectionItemClick(Sender: TObject);
    //** @abstract(Asks, then takes the collection out of the library.)
    //**
    //** @param(Sender DeleteCollectionItem.)
    procedure DeleteCollectionItemClick(Sender: TObject);
  private
    //** @abstract(The form's own viewport, in PreviewArea, where thumbnails are drawn and
    //** the selected model shown.)
    FViewport: TGorillaViewport;
    //** @abstract(The viewport's camera, from the Spritely package, in orthographic
    //** projection with its headlight on; in the isometric view for every thumbnail.)
    FCamera: TSpritelyOrbitalCamera;
    //** @abstract(Grabs each thumbnail off screen, THUMBNAIL_SIZE square, transparent.)
    FOffscreen: TSprite3DOffscreen;
    //** @abstract(Starts each grab THUMBNAIL_SETTLE_MS after its model is loaded.)
    FSettleTimer: TTimer;
    //** @abstract(Every GRAB_POLL_MS while a grab is under way: runs what is queued for the
    //** main thread, which a busy viewport can hold up, then starts a grab again that has
    //** not come back in GRAB_TIMEOUT_MS, and gives up after GRAB_TRIES.)
    FGrabTimer: TTimer;
    //** @abstract(Times the try of the grab under way, for GRAB_TIMEOUT_MS.)
    FGrabWatch: TStopwatch;
    //** @abstract(How many times FGrabTimer has polled the grab (TSprite3DOffscreen.Poll) in
    //** this try, and how many of those ran something, for the log.)
    FPumps: Integer;
    //** @abstract(See FPumps.)
    FPumpsUseful: Integer;
    //** @abstract(How many times the grab of the thumbnail being made has been started.)
    FGrabTries: Integer;
    //** @abstract(Runs MakeNext on a later main-loop turn; see MakeNextLater. Owned by the
    //** form, so it never fires once the form has gone.)
    FNextTimer: TTimer;
    //** @abstract(Does what a group button's own mouse handler asks for once the handler has
    //** returned, as it rebuilds the buttons; see DeferredWork.)
    FDeferTimer: TTimer;
    //** @abstract(The model in the viewport, whose thumbnail is being made or which is
    //** previewed; nil for none.)
    FModel: TGorillaModel;
    //** @abstract(FModel's bounding box in its own space, as LoadModelFile gave it, before
    //** it was turned upright.)
    FModelBox: TBoundingBox;
    //** @abstract(The entry FModel is the preview of; -1 if it is none, or is a thumbnail's.)
    FPreviewIndex: Integer;
    //** @abstract(The variant the preview shows, as TAssetEntry.Variant.)
    FPreviewVariant: Integer;
    //** @abstract(The tile right-click menu of variants, made afresh for each right-click.)
    FVariantMenu: TPopupMenu;
    //** @abstract(The entry the variant menu is for.)
    FVariantEntry: Integer;
    //** @abstract(The thumbnail cache, TSprite3DAppSettings.ThumbnailFolder, where the
    //** library and its collections are kept too.)
    FCacheFolder: String;
    //** @abstract(The library: every collection; read once, by LoadLibrary.)
    FLibrary: TSprite3DAssetLibrary;
    //** @abstract(True once LoadLibrary has run.)
    FLibraryLoaded: Boolean;
    //** @abstract(True from ScanCollection until its results are in, so HashesDone marks
    //** the collection scanned.)
    FScanning: Boolean;
    //** @abstract(The collection open; its Id is empty for none.)
    FCollection: TSprite3DAssetCollection;
    //** @abstract(The id of the artist shown; empty for none.)
    FArtistId: String;
    //** @abstract(The collections in CollectionCombo, the artist's, as indices into
    //** FLibrary.Collections.)
    FShownCollections: TArray<Integer>;
    //** @abstract(True while FillCollections fills ArtistCombo, so its change is not a
    //** choice.)
    FFillingArtists: Boolean;
    //** @abstract(The folders and formats chosen for a new collection, while its name is
    //** asked.)
    FNewSources: TArray<TSprite3DCollectionSource>;
    //** @abstract(True while FillCollections fills CollectionCombo, so its change is not a
    //** choice.)
    FFillingCollections: Boolean;
    //** @abstract(Backing field for MigrationFolder.)
    FMigrationFolder: String;
    //** @abstract(The group of every model the palette knows, key to group, in this folder
    //** or not; see SavePalette.)
    FPaletteGroups: TDictionary<String, String>;
    //** @abstract(The palette's groups in the user's order.)
    FGroupOrder: TArray<String>;
    //** @abstract(The icon chosen for each group, by the group's name in lower case: a file
    //** name in the icon library.)
    FGroupIcons: TDictionary<String, String>;
    //** @abstract(The group each group is inside, by the inner group's name in lower case;
    //** a group at the top has no entry. Names are unique across every level.)
    FGroupParents: TDictionary<String, String>;
    //** @abstract(The groups inside the one shown, with a tile at the start of the grid, in
    //** the palette's order.)
    FFolderNames: TArray<String>;
    //** @abstract(Their tiles, in FFolderNames' order; each one's Tag is its index.)
    FFolderTiles: TArray<TRectangle>;
    //** @abstract(Says "Model Preview" over the viewport while it shows no model.)
    FPreviewLabel: TLabel;
    //** @abstract(Over the preview's top right corner: what the preview shows behind the
    //** model, one item for each of PREVIEW_BACKGROUNDS.)
    FBackgroundCombo: TComboBox;
    //** @abstract(True while FBackgroundCombo is set from code, so its change is not a
    //** choice.)
    FSettingBackground: Boolean;
    //** @abstract(Backing field for PreviewBackground.)
    FPreviewBackground: String;
    //** @abstract(Backing field for OnPreviewBackground.)
    FOnPreviewBackground: TAssetsBackgroundEvent;
    //** @abstract(Backing field for OnModelChosen.)
    FOnModelChosen: TAssetsModelChosenEvent;
    //** @abstract(True while CheckThumbnails runs.)
    FChecking: Boolean;
    //** @abstract(Behind the viewport: a checker, standing for transparency. Never in a
    //** thumbnail: the off-screen pass draws into a buffer of its own.)
    FBackground: TSprite3DBackground;
    //** @abstract(The floor grid under the model previewed, at the level's grid spacing and
    //** the model's own floor, Y = 0, so a model raised from it, or sunk into it, shows; a
    //** child of FModel, freed with it, and never there while a thumbnail is made.)
    FPreviewGrid: TModelGrid;
    //** @abstract(The model files passed over when thumbnails are made or a model previewed:
    //** those in the viewport when the program last stopped without closing, so likely to
    //** hang it; read from and kept in SkipFile. Sorted, case ignored.)
    FSkipped: TStringList;
    //** @abstract(Backing field for GridSize.)
    FGridSize: Single;
    //** @abstract(The icons loaded, by full path, so each is read once; the form's.)
    FIconBitmaps: TObjectDictionary<String, TBitmap>;
    //** @abstract(Counts the folders opened, so results for an earlier one are dropped.)
    FScanId: Integer;
    //** @abstract(Every model shown, in name order.)
    FEntries: TArray<TAssetEntry>;
    //** @abstract(The entries still to have their thumbnails made, first first.)
    FQueue: TArray<Integer>;
    //** @abstract(How many thumbnails this folder needed, for Progress.)
    FQueueTotal: Integer;
    //** @abstract(Times making the queue's thumbnails, for the time left.)
    FMakeWatch: TStopwatch;
    //** @abstract(The collections an artist import still has to import in full, by id.)
    FBulkQueue: TArray<String>;
    //** @abstract(How many collections the artist import under way made; 0 when none is.)
    FBulkTotal: Integer;
    //** @abstract(The first collection the artist import made, shown when it is done.)
    FBulkFirst: String;
    //** @abstract(What the artist import made and passed over, shown when it is done.)
    FBulkSummary: String;
    //** @abstract(True when DeferredWork is to go on to the next collection to import.)
    FBulkPending: Boolean;
    //** @abstract(True while the run of collections under way is a Rescan All Collections:
    //** each one's folders are read again, not opened from what was saved.)
    FBulkRescan: Boolean;
    //** @abstract(While the job under way remakes thumbnails, when it started: a thumbnail
    //** made before then is made again; 0 for none. Kept with the job, so a resumed remake
    //** keeps those it made.)
    FBulkRemakeBefore: TDateTime;
    //** @abstract(From OpenCollection until HashesDone: thumbnails made before this are
    //** made again, the cache's ignored; 0 for none.)
    FRemakeBefore: TDateTime;
    //** @abstract(What the job under way, or paused, is: @code(import), @code(rescan),
    //** @code(remake) or @code(collection), one collection's thumbnails.)
    FJobKind: String;
    //** @abstract(The job's title, for the status and the logs.)
    FJobTitle: String;
    //** @abstract(The collection the job is working on; saved with the job, so a job
    //** stopped part way through carries on with it.)
    FBulkCurrent: String;
    //** @abstract(True while a job is paused: saved in JobFile, waiting for Resume Scan or
    //** Abort Scan. Meanwhile no thumbnails are made: collections open with what is cached.)
    FJobPaused: Boolean;
    //** @abstract(How many collections the paused job has left, its current one among them.)
    FPausedLeft: Integer;
    //** @abstract(Resume Scan, in CollectionBar: carries on with the paused job. Shown only
    //** while one is paused.)
    FResumeButton: TButton;
    //** @abstract(Abort Scan, in CollectionBar: drops the job, running or paused. Shown
    //** only while there is one.)
    FAbortButton: TButton;
    //** @abstract(How many errors have gone to the error log since the last artist import
    //** or rescan began, for its summary.)
    FRunErrors: Integer;
    //** @abstract(How many of the queue's thumbnails were made, so the count at the end
    //** leaves out those that failed.)
    FMadeCount: Integer;
    //** @abstract(The entry whose thumbnail is being made; -1 for none.)
    FMaking: Integer;
    //** @abstract(The entry selected, whose details and preview are shown; -1 for none.)
    FSelected: Integer;
    //** @abstract(Where a Shift-click's run of picked thumbnails starts; -1 for none.)
    FAnchor: Integer;
    //** @abstract(The group shown in the tiles; empty for none.)
    FGroup: String;
    //** @abstract(The groups with a button, in order.)
    FShownGroups: TArray<String>;
    //** @abstract(The groups' buttons, in FShownGroups' order; each one's Tag is its index.)
    FGroupTiles: TArray<TRectangle>;
    //** @abstract(Holds the tiles; made in FormCreate.)
    FTilesLayout: TLayout;
    //** @abstract(The entry whose tile the left button is down on; -1 for none.)
    FTileDown: Integer;
    //** @abstract(True when a plain click on a picked thumbnail is to pick it alone, once
    //** the button comes up without a drag.)
    FPickOnUp: Boolean;
    //** @abstract(The group whose button or tile the left button is down on; empty for
    //** none.)
    FGroupDown: String;
    //** @abstract(True if FGroupDown's press is on a group's tile in the grid, not its
    //** button on the left.)
    FGroupDownInGrid: Boolean;
    //** @abstract(The group tile in the grid marked as where the drag would drop; -1 for
    //** none.)
    FDropFolder: Integer;
    //** @abstract(Scrolls GroupsBox or TilesBox while a drag holds the pointer near or past
    //** its top or bottom edge; see ScrollTimerTimer.)
    FScrollTimer: TTimer;
    //** @abstract(Where the pointer was at the drag's last move, in the form's coordinates.)
    FDragAt: TPointF;
    //** @abstract(True while a dragged group would go into the group shown: TilesPanel is
    //** outlined.)
    FDropInto: Boolean;
    //** @abstract(True while a dragged group would go to the top, last: the space below the
    //** buttons.)
    FDropBelow: Boolean;
    //** @abstract(Where the left button went down, in the form's coordinates.)
    FDownAt: TPointF;
    //** @abstract(True once the pointer has moved TILE_DRAG_START with the button down: the
    //** thumbnails or group are being dragged.)
    FDragging: Boolean;
    //** @abstract(Follows the pointer while thumbnails are dragged: the one pressed, made in
    //** FormCreate.)
    FDragGhost: TImage;
    //** @abstract(On FDragGhost: how many are dragged, when more than one.)
    FDragCount: TLabel;
    //** @abstract(The group button marked as where the drag would drop; -1 for none.)
    FDropIndex: Integer;
    //** @abstract(The group GroupMenu was opened on; empty for empty space.)
    FMenuGroup: String;
    //** @abstract(True if GroupMenu was opened in the grid: a group added goes inside the one
    //** shown, not at the top.)
    FMenuInGrid: Boolean;
    //** @abstract(What the name dialog open is for.)
    FAskName: TGroupNameAsk;
    //** @abstract(The group DeferredWork is to put inside FReparentTo, or at the top if
    //** FReparentTo is empty; empty FReparentGroup: none.)
    FReparentGroup, FReparentTo: String;
    //** @abstract(The group DeferredWork is to show, opened from its tile; empty for none.)
    FOpenGroup: String;
    //** @abstract(True while the left button turns the preview.)
    FTurning: Boolean;
    //** @abstract(Where the pointer was at the last move of the turn, in PreviewArea's
    //** coordinates.)
    FTurnLast: TPointF;
    //** @abstract(Shared with the hashing worker, which hands back nothing once the form is
    //** gone.)
    FAlive: IAssetsAlive;
    //** @abstract(True while the worker deleting the thumbnails of deleted collections runs;
    //** see StartPurge.)
    FPurging: Boolean;
    //** @abstract(True if another collection or artist was deleted while FPurging, so
    //** PurgeFilesDone starts again rather than deleting records whose thumbnails are not
    //** done.)
    FPurgeAgain: Boolean;
    //** @abstract(Backing field for OnLog.)
    FOnLog: TAssetsLogEvent;
    //** @abstract(Reads the library, once; if there is none but there is a palette of
    //** before it, makes that the first collection, "Kaykit Dungeon", from MigrationFolder.)
    procedure LoadLibrary;
    //** @abstract(Writes the library, logging a failure.)
    procedure SaveLibrary;
    //** @abstract(Fills CollectionCombo with the library's collections, chooses the one open,
    //** enables what can be done, and sets the title: @code(Library @(N models@) - Artist /
    //** Collection).)
    procedure FillCollections;
    //** @abstract(Opens collection AId: from its saved models if its folders have been
    //** scanned, else by scanning them.)
    //**
    //** @param(AId The collection's id; empty shows no collection.)
    //**
    //** @param(ARescan True to read its folders again even if they have been scanned.)
    //**
    //** @param(ARemakeBefore Thumbnails made before this are made again, the cache's ignored;
    //** 0, the default, for none. Its folders are read again too when it is set.)
    procedure OpenCollection(const AId: String; const ARescan: Boolean = False;
      const ARemakeBefore: TDateTime = 0);
    //** @abstract(Rescans every collection of the artist shown, one after another, making
    //** every thumbnail again if ARemake; see RescanArtistItemClick.)
    //**
    //** @param(ARemake True to make every thumbnail again, cached or not.)
    procedure StartArtistRun(const ARemake: Boolean);
    //** @abstract(Reads the open collection's folders: every model hashed on a worker
    //** thread, then shown, its groups kept.)
    procedure ScanCollection;
    //** @abstract(The folders and formats to take from ARoots: every folder holding models
    //** under them is found, and if there is more than one, the user chooses
    //** (ChooseModelFolders), with the library's preferred format ticked.)
    //**
    //** @param(ARoots The folders the user chose.)
    //**
    //** @returns(The sources; empty if there are no models, or the user cancelled.)
    function ChooseSources(const ARoots: TArray<String>): TArray<TSprite3DCollectionSource>;
    //** @abstract(Makes a new collection called AName from ASources and adds it to the
    //** library, which is saved; it is scanned when first opened.)
    //**
    //** @param(AName The name.)
    //**
    //** @param(ASources Its folders and formats.)
    //**
    //** @param(AArtistId The artist it is under.)
    //**
    //** @returns(Its id; empty if it could not be saved.)
    function NewCollection(const AName: String;
      const ASources: TArray<TSprite3DCollectionSource>; const AArtistId: String): String;
    //** @abstract(Imports the artist import's next collection in full, opening it, which
    //** reads its folders and makes its thumbnails; when there are none left, opens the
    //** first and shows the summary.)
    procedure NextBulk;
    //** @abstract(Says which of the artist import's collections is under way, to go before
    //** the status; empty when none is.)
    //**
    //** @returns(The text.)
    function BulkPrefix: String;
    //** @abstract(Ends the artist import under way, if there is one; the collections not yet
    //** imported are when each is opened.)
    //**
    //** @param(AWhy Why, for the log.)
    procedure StopBulk(const AWhy: String);
    //** @abstract(Pauses the job under way, if there is one: what it has made stays, it
    //** stays saved in JobFile, nothing more is made, and Resume Scan and Abort Scan are
    //** shown.)
    //**
    //** @param(AWhy Why, for the log.)
    procedure PauseJob(const AWhy: String);
    //** @abstract(Leaves the job under way to open something else: one collection's
    //** thumbnails are dropped, as the collection opened next makes its own, and that one
    //** makes the rest when it is opened again; any other job is paused (PauseJob).)
    //**
    //** @param(AWhy Why, for the log.)
    procedure LeaveJob(const AWhy: String);
    //** @abstract(Drops the job, running or paused: JobFile is deleted, and what it had
    //** still to do is done as each collection is opened, as for an import stopped before.)
    //**
    //** @param(Sender FAbortButton.)
    procedure AbortButtonClick(Sender: TObject);
    //** @abstract(Carries on with the paused job, from the collection it was working on.)
    //**
    //** @param(Sender FResumeButton.)
    procedure ResumeButtonClick(Sender: TObject);
    //** @abstract(Shows Resume Scan while a job is paused, and Abort Scan while one is
    //** paused or under way.)
    procedure UpdateJobButtons;
    //** @abstract(The status while a job is paused, saying what to do.)
    //**
    //** @returns(The text.)
    function PausedText: String;
    //** @abstract(Where the job is saved: in the settings folder, beside the library.)
    //**
    //** @returns(The file's path.)
    function JobFile: String;
    //** @abstract(Writes the job under way to JobFile: its kind and title, the collection
    //** it is on and those still queued, its summary so far, its error count, and whether it
    //** rescans or remakes. A failure is logged; the job goes on.)
    procedure SaveJob;
    //** @abstract(Deletes JobFile, if it is there.)
    procedure ClearJob;
    //** @abstract(Reads the job in JobFile, if there is one, as a paused job: the collection
    //** it was on first, then the rest, leaving out any no longer in the library. A file that
    //** cannot be read is logged and deleted.)
    //**
    //** @returns(True if there is a job, with collections left.)
    function LoadJob: Boolean;
    //** @abstract(Starts a job on collections AIds, one after another (NextBulk), saved in
    //** JobFile at every step; any job before it is dropped.)
    //**
    //** @param(AKind The job's kind; see FJobKind.)
    //**
    //** @param(ATitle Its title.)
    //**
    //** @param(AIds The collections, in order.)
    //**
    //** @param(AFirst The collection shown at the end; empty for none.)
    //**
    //** @param(ASummary What is shown at the end, before the error count; empty for nothing.)
    //**
    //** @param(ARescan True to read each collection's folders again.)
    //**
    //** @param(ARemakeBefore Thumbnails made before this are made again; 0 for none.)
    procedure StartJob(const AKind, ATitle: String; const AIds: TArray<String>;
      const AFirst, ASummary: String; const ARescan: Boolean; const ARemakeBefore: TDateTime);
    //** @abstract(Whether a thumbnail made at ACreated, as ISO 8601 text, is to be kept, not
    //** made again: always, unless FRemakeBefore is set and it is older.)
    //**
    //** @param(ACreated When it was made.)
    //**
    //** @returns(True to keep it.)
    function MadeSinceRemake(const ACreated: String): Boolean;
    //** @abstract(Whether artist AArtistId has a collection called AName, case ignored.)
    //**
    //** @param(AName The name.)
    //**
    //** @param(AArtistId The artist.)
    //**
    //** @returns(True if they have.)
    function HasCollection(const AName, AArtistId: String): Boolean;
    //** @abstract(Where artist AId is in FLibrary.Artists.)
    //**
    //** @param(AId The artist's id.)
    //**
    //** @returns(The index, or -1.)
    function ArtistIndex(const AId: String): Integer;
    //** @abstract(The artist an artist import puts its collections under.)
    //**
    //** @returns(The id of the artist shown, or an empty string when there is none or it is
    //** Unassigned, when each folder chosen names its own artist.)
    function BulkArtist: String;
    //** @abstract(The artist called AName, case ignored, made if there is none; the library
    //** is saved if one is made.)
    //**
    //** @param(AName The name.)
    //**
    //** @returns(Their id.)
    function EnsureArtist(const AName: String): String;
    //** @abstract(Puts every collection with no artist, or one that is not there, under
    //** UNASSIGNED_ARTIST, as the collections of before artists are.)
    procedure AssignOrphans;
    //** @abstract(The collection to open for artist AArtistId: the one open last if it is
    //** theirs, or their first.)
    //**
    //** @param(AArtistId The artist.)
    //**
    //** @returns(The collection's id; empty if they have none.)
    function ArtistCollection(const AArtistId: String): String;
    //** @abstract(Makes the artist called AName, or renames the one shown, as AAsk says; a
    //** name another artist has is refused.)
    //**
    //** @param(AAsk gnNewArtist or gnRenameArtist.)
    //**
    //** @param(AName The name, trimmed; empty does nothing.)
    procedure ArtistNamed(const AAsk: TGroupNameAsk; const AName: String);
    //** @abstract(Deletes the artist shown and their collections, if the user said Yes; the
    //** delete dialog's answer.)
    //**
    //** They are marked as being deleted (MarkAssetArtistDeleted) and taken out of the
    //** library; the artist now in the same place in the list, or the one before if it was
    //** the last, is shown, with its last or first collection; then StartPurge deletes the
    //** thumbnails and the records.
    //**
    //** @param(Sender The dialog's context; not used.)
    //**
    //** @param(AResult How the dialog was closed.)
    procedure DeleteArtistClosed(Sender: TObject; const AResult: TModalResult);
    //** @abstract(The open collection's sources, for the log: each folder, with its formats.)
    //**
    //** @returns(The text.)
    function SourcesText: String;
    //** @abstract(The folder a folder dialog starts in: the last chosen, or the nearest
    //** folder above it that is still there.)
    //**
    //** @returns(The folder; empty, for the dialog's own choice, if none is.)
    function StartFolder: String;
    //** @abstract(Makes the new collection of FNewSources called AName, or renames the open
    //** one, as AAsk says; a name another collection has is refused.)
    //**
    //** @param(AAsk gnNewCollection or gnRenameCollection.)
    //**
    //** @param(AName The name, trimmed; empty does nothing.)
    procedure CollectionNamed(const AAsk: TGroupNameAsk; const AName: String);
    //** @abstract(Deletes the open collection, if the user said Yes; the delete dialog's
    //** answer.)
    //**
    //** It is marked as being deleted (MarkAssetCollectionDeleted) and taken out of the
    //** library; the artist's collection now in the same place in their list, or the one
    //** before if it was the last, is opened, or none if it was their only one; then
    //** StartPurge deletes the thumbnails and the records.
    //**
    //** @param(Sender The dialog's context; not used.)
    //**
    //** @param(AResult How the dialog was closed.)
    procedure DeleteCollectionClosed(Sender: TObject; const AResult: TModalResult);
    //** @abstract(Tidies the cache: deletes, on a worker thread, every thumbnail of a model
    //** no collection has (not in UsedAssetKeys), the deleted collections' among them;
    //** PurgeFilesDone follows.)
    //**
    //** Only a thumbnail file written before it started is deleted, so one being made
    //** meanwhile, for a collection opened or imported since, stays. The model files are
    //** never touched. Called after a delete, and by LoadLibrary each time the Library opens,
    //** which finishes a delete left unfinished too. While one runs, another call only sets
    //** FPurgeAgain. HashesDone calls it too, after a scan has saved the models it found,
    //** so a rescan's replaced thumbnails go at once.
    procedure StartPurge;
    //** @abstract(StartPurge's worker is done: deletes the records of the collections and
    //** artists marked, and the metadata of models no collection has (PurgeDeletedAssets),
    //** then compacts the database if that left space in it (CompactAssetDatabase).)
    //**
    //** A thumbnail that could not be deleted is tried again the next time.
    //**
    //** @param(ADeleted How many thumbnail files were deleted.)
    //**
    //** @param(AFailed How many could not be.)
    //**
    //** @param(AFirstError The first that could not be, and why; empty if none.)
    procedure PurgeFilesDone(const ADeleted, AFailed: Integer; const AFirstError: String);
    //** @abstract(The suspect models dialog's OnShowModel: selects entry AIndex, showing it
    //** in the preview, its group shown and its tile scrolled into sight.)
    //**
    //** @param(AIndex An index into FEntries.)
    procedure SuspectShow(const AIndex: Integer);
    //** @abstract(The suspect models dialog's OnVerdict: records entry AIndex's verdict in
    //** the database, logging it.)
    //**
    //** @param(AIndex An index into FEntries.)
    //**
    //** @param(ABad True for bad, False for good.)
    //**
    //** @returns(True if it was recorded.)
    function SuspectVerdict(const AIndex: Integer; const ABad: Boolean): Boolean;
    //** @abstract(Hands AText to OnLog, if it is set, and writes it to the import log.)
    //**
    //** @param(AText The line.)
    procedure Log(const AText: String);
    //** @abstract(Adds AText, after the time, to the import log, ImportLogFile.)
    //**
    //** The file is opened, written and closed for each line, so whatever was written before
    //** a hang or a crash is there to read. A failure to write is ignored.
    //**
    //** @param(AText The line.)
    procedure DebugLog(const AText: String);
    //** @abstract(Logs AText as Log does, and adds it to the error log, ErrorLogFile, with
    //** the artist and collection open, and counts it in FRunErrors.)
    //**
    //** @param(AText The line; an @code(Assets: ) at its start is left out of the error log.)
    procedure LogError(const AText: String);
    //** @abstract(Begins the import log again, for an artist import or rescan, with AHeader
    //** and the time the program was built as its first line; AHeader goes in the error log
    //** too, so the errors after it can be told apart from those of other runs.)
    //**
    //** @param(AHeader What is being done, such as @code(Artist import: ...).)
    procedure StartImportLog(const AHeader: String);
    //** @abstract(The import log: what the Library did, with each model's load and grab
    //** timed, in the settings folder; begun again by each artist import or rescan.)
    //**
    //** @returns(The file's path.)
    function ImportLogFile: String;
    //** @abstract(The file that names the model in the viewport, while there is one, so
    //** one left there by a program that never closed names the model it hung or crashed
    //** on.)
    //**
    //** @returns(The file's path.)
    function LoadingFile: String;
    //** @abstract(The list of model files passed over, one to a line; delete a line, or the
    //** file, to try one again.)
    //**
    //** @returns(The file's path.)
    function SkipFile: String;
    //** @abstract(Reads SkipFile into FSkipped, then adds the model LoadingFile names, if it
    //** is there: the program stopped with that model in the viewport.)
    procedure LoadSkipped;
    //** @abstract(Whether model file AFile is passed over.)
    //**
    //** @param(AFile The model file.)
    //**
    //** @returns(True if FSkipped has it.)
    function IsSkipped(const AFile: String): Boolean;
    //** @abstract(True while thumbnails are queued or one is being made.)
    //**
    //** @returns(Whether the viewport is busy with thumbnails.)
    function Making: Boolean;
    //** @abstract(The hashing's results for folder AScanId: the entries from them, cached or
    //** queued, in their groups and sorted, then the groups and tiles, then the first
    //** thumbnail.)
    //**
    //** @param(AScanId The folder they are for; anything but FScanId is dropped.)
    //**
    //** @param(AResults One per model file.)
    procedure HashesDone(const AScanId: Integer; const AResults: TArray<TAssetHashResult>);
    //** @abstract(Puts each plural group with its singular one, when both are there, for
    //** the models the palette does not place.)
    procedure MergePluralGroups;
    //** @abstract(Puts each model the palette does not place, alone in its group, in
    //** UNSORTED_GROUP, for the user to sort: a group of fewer than MIN_GROUP_SIZE of the
    //** folder's models that the palette does not have already.)
    procedure CollapseSmallGroups;
    //** @abstract(Makes a button for each of the palette's groups, in its order, with its
    //** icon, name and how many models of the folder it has, and chooses FGroup again, or
    //** the first group if it has gone.)
    //**
    //** A group with none of the folder's models has a button only if it has no models at
    //** all, one the user has just made: the groups of other kits are kept, but not shown.
    procedure BuildGroups;
    //** @abstract(Marks the button of the chosen group's top group, and the button, tile or
    //** panel a drag would drop on.)
    procedure UpdateGroupMarks;
    //** @abstract(The group AGroup is inside, as named in the palette.)
    //**
    //** @param(AGroup The group.)
    //**
    //** @returns(The group it is inside; empty for one at the top.)
    function ParentOf(const AGroup: String): String;
    //** @abstract(The group at the top that AGroup is in, or AGroup if it is at the top.)
    //**
    //** @param(AGroup The group.)
    //**
    //** @returns(The top group.)
    function RootOf(const AGroup: String): String;
    //** @abstract(Whether AOuter is AGroup, or a group AGroup is inside, at any depth.)
    //**
    //** @param(AOuter The group that may hold it.)
    //**
    //** @param(AGroup The group.)
    //**
    //** @returns(True if so, ignoring case.)
    function Holds(const AOuter, AGroup: String): Boolean;
    //** @abstract(The groups directly inside AGroup, in alphabetical order, case ignored.)
    //**
    //** @param(AGroup The group; empty for those at the top.)
    //**
    //** @returns(Their names.)
    function ChildGroups(const AGroup: String): TArray<String>;
    //** @abstract(How many of the folder's models are in AGroup and every group inside it.)
    //**
    //** @param(AGroup The group.)
    //**
    //** @returns(The count.)
    function FolderTotal(const AGroup: String): Integer;
    //** @abstract(Whether AGroup has a button or tile: models of the folder in it or the
    //** groups inside it, or no models anywhere, as a group just made has.)
    //**
    //** @param(AGroup The group.)
    //**
    //** @returns(True if it is shown.)
    function GroupShown(const AGroup: String): Boolean;
    //** @abstract(Whether AGroup has no models anywhere and no groups inside it, so it may
    //** be deleted.)
    //**
    //** @param(AGroup The group.)
    //**
    //** @returns(True if it is empty.)
    function GroupEmpty(const AGroup: String): Boolean;
    //** @abstract(Puts group AGroup inside AParent, or at the top, unless that would put a
    //** group inside itself; saves the palette and shows the groups again.)
    //**
    //** @param(AGroup The group.)
    //**
    //** @param(AParent The group to put it in; empty for the top.)
    procedure Reparent(const AGroup, AParent: String);
    //** @abstract(Frees the tiles of the groups inside the one shown and makes them again.)
    procedure BuildFolderTiles;
    //** @abstract(The group tile in the grid under a point.)
    //**
    //** @param(AAbsolute The point, in the form's coordinates.)
    //**
    //** @returns(Its index in FFolderNames, or -1.)
    function FolderTileAt(const AAbsolute: TPointF): Integer;
    //** @abstract(Whether a point is over the grid, TilesPanel.)
    //**
    //** @param(AAbsolute The point, in the form's coordinates.)
    //**
    //** @returns(True if it is.)
    function OverTiles(const AAbsolute: TPointF): Boolean;
    //** @abstract(Shows the group shown and the groups it is inside in PathLabel, and enables
    //** UpButton if there is a group to go up to.)
    procedure UpdatePath;
    //** @abstract(Shows FPreviewLabel while the viewport has no model.)
    procedure UpdatePreviewLabel;
    //** @abstract(Readies a group's tile in the grid to be dragged; a double-click opens it.)
    //**
    //** @param(Sender A group's tile.)
    //**
    //** @param(Button The button.)
    //**
    //** @param(Shift The keys and buttons held; ssDouble for a double-click.)
    //**
    //** @param(X Where, across the tile.)
    //**
    //** @param(Y Where, down the tile.)
    procedure FolderTileMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState;
      X, Y: Single);
    //** @abstract(Marks where the dragged group would go: into another group's button or
    //** tile, or to the top below the buttons.)
    //**
    //** @param(At Where the pointer is, in the form's coordinates.)
    procedure TrackGroupDrag(const At: TPointF);
    //** @abstract(Marks where the dragged thumbnails would drop: another group's button, or
    //** a group's tile in the grid.)
    //**
    //** @param(At Where the pointer is, in the form's coordinates.)
    procedure TrackTileDrag(const At: TPointF);
    //** @abstract(Scrolls ABox a step if At is near or past its top or bottom edge, and
    //** within it across.)
    //**
    //** @param(ABox GroupsBox or TilesBox.)
    //**
    //** @param(At The pointer, in the form's coordinates.)
    //**
    //** @returns(True if it scrolled.)
    function EdgeScroll(const ABox: TVertScrollBox; const At: TPointF): Boolean;
    //** @abstract(Scrolls the box the dragging pointer is at the edge of, and marks the drop
    //** again, as what is under the pointer has moved.)
    //**
    //** @param(Sender FScrollTimer.)
    procedure ScrollTimerTimer(Sender: TObject);
    //** @abstract(Starts a drag: FScrollTimer on, the ghost shown.)
    procedure BeginDrag;
    //** @abstract(Whether the level can place an entry: one with a thumbnail, and so a box.)
    //**
    //** @param(AIndex The entry.)
    //**
    //** @returns(True if it can be placed.)
    function LevelTakes(const AIndex: Integer): Boolean;
    //** @abstract(An entry as the level is given it: its name, file, key and box.)
    //**
    //** @param(AIndex The entry.)
    //**
    //** @returns(The model, for OnModelChosen.)
    function LevelSpec(const AIndex: Integer): TSprite3DPieceSpec;
    //** @abstract(Ends a group's drag at a point: moves it before another at the top,
    //** inside another, or to the top, as TrackGroupDrag marked.)
    //**
    //** @param(At Where the pointer is, in the form's coordinates.)
    procedure DropGroup(const At: TPointF);
    //** @abstract(The icon for group AGroup: the one chosen for it, or the library's named
    //** after it, or its first model's thumbnail.)
    //**
    //** @param(AGroup The group.)
    //**
    //** @returns(The bitmap, which is not the caller's; nil if there is none.)
    function GroupIcon(const AGroup: String): TBitmap;
    //** @abstract(Where an icon of the library is: the user's own folder first, then the one
    //** that comes with the program.)
    //**
    //** @param(AName The icon's file name.)
    //**
    //** @returns(Its full path; empty if neither has it.)
    function IconFile(const AName: String): String;
    //** @abstract(Where group AGroup is in FGroupOrder, ignoring case.)
    //**
    //** @param(AGroup The group.)
    //**
    //** @returns(Its index, or -1.)
    function GroupIndex(const AGroup: String): Integer;
    //** @abstract(How many models of the palette, in this folder or not, are in AGroup.)
    //**
    //** @param(AGroup The group.)
    //**
    //** @returns(The count.)
    function PaletteCount(const AGroup: String): Integer;
    //** @abstract(Writes the open collection, its palette, FGroupOrder with its icons and
    //** every key of FPaletteGroups in its group, and its models, to the cache, logging a
    //** failure.)
    //**
    //** Each group's models are this folder's in name order, then those of other folders in
    //** key order.
    procedure SavePalette;
    //** @abstract(A count with its word, such as 1 model or 1,234 models.)
    //**
    //** @param(ACount The count.)
    //**
    //** @param(AWord The word for one, given an s for any other count.)
    //**
    //** @returns(The text.)
    function CountText(const ACount: Integer; const AWord: String): String;
    //** @abstract(An artist as the artist list shows them: their name, then how many
    //** collections they have and how many models in them all.)
    //**
    //** @param(AArtist The artist.)
    //**
    //** @returns(The text.)
    function ArtistText(const AArtist: TSprite3DArtist): String;
    //** @abstract(A collection as the collection list shows it: its name, then how many
    //** models it has, or that it is not imported yet.)
    //**
    //** @param(AEntry The collection.)
    //**
    //** @returns(The text.)
    function CollectionText(const AEntry: TSprite3DLibraryEntry): String;
    //** @abstract(Shows group AGroup's tiles; the picks are dropped.)
    //**
    //** @param(AGroup The group; empty for none.)
    procedure ShowGroup(const AGroup: String);
    //** @abstract(Frees the tiles and makes one for every entry of FEntries.)
    procedure BuildTiles;
    //** @abstract(Shows entry AIndex's kind on its tile's badge, and its variants, or hides the
    //** badge if it has neither.)
    //**
    //** @param(AIndex The entry.)
    procedure UpdateBadge(const AIndex: Integer);
    //** @abstract(Entry AIndex's kind and what it holds, for people: @code(Rigged and
    //** animated: 2 meshes, 1,204 vertices, 1 skin of 24 joints, 12 animations).)
    //**
    //** @param(AIndex The entry; its kind must be known.)
    //**
    //** @returns(The text.)
    function EntryContentText(const AIndex: Integer): String;
    //** @abstract(Places the tiles of FGroup in rows as wide as TilesBox, in name order,
    //** and hides the rest.)
    procedure LayoutTiles;
    //** @abstract(Gives each tile the look of picked, selected, or neither.)
    procedure UpdateTileMarks;
    //** @abstract(The entries picked, in name order.)
    //**
    //** @returns(Their indices in FEntries.)
    function PickedEntries: TArray<Integer>;
    //** @abstract(Picks as a click with Shift held does: AIndex alone, added or taken away
    //** with Control, or the run from FAnchor with Shift.)
    //**
    //** @param(AIndex The entry clicked.)
    //**
    //** @param(AShift The keys held.)
    procedure PickEntry(const AIndex: Integer; const AShift: TShiftState);
    //** @abstract(Picks and selects the tile's model, and makes ready to drag.)
    //**
    //** @param(Sender The tile; its Tag is the entry.)
    //**
    //** @param(Button The button.)
    //**
    //** @param(Shift The keys and buttons held.)
    //**
    //** @param(X Where, across the tile.)
    //**
    //** @param(Y Where, down the tile.)
    procedure TileMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState;
      X, Y: Single);
    //** @abstract(Drags the picked thumbnails once the pointer has moved TILE_DRAG_START:
    //** the one pressed follows the pointer, with how many there are, and the group under
    //** it is marked.)
    //**
    //** The tile keeps the mouse while the button is down (AutoCapture), so the moves come
    //** here wherever the pointer goes.
    //**
    //** @param(Sender The tile.)
    //**
    //** @param(Shift The keys and buttons held.)
    //**
    //** @param(X Where, across the tile.)
    //**
    //** @param(Y Where, down the tile.)
    procedure TileMouseMove(Sender: TObject; Shift: TShiftState; X, Y: Single);
    //** @abstract(Drops the dragged thumbnails on the group under the pointer, moving their
    //** models there; without a drag, a plain click on a picked one picks it alone.)
    //**
    //** @param(Sender The tile.)
    //**
    //** @param(Button The button.)
    //**
    //** @param(Shift The keys and buttons held.)
    //**
    //** @param(X Where, across the tile.)
    //**
    //** @param(Y Where, down the tile.)
    procedure TileMouseUp(Sender: TObject; Button: TMouseButton; Shift: TShiftState;
      X, Y: Single);
    //** @abstract(Chooses the group with the left button and readies it to be dragged.)
    //**
    //** @param(Sender A group's button.)
    //**
    //** @param(Button The button.)
    //**
    //** @param(Shift The keys and buttons held.)
    //**
    //** @param(X Where, across the button.)
    //**
    //** @param(Y Where, down the button.)
    procedure GroupTileMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState;
      X, Y: Single);
    //** @abstract(Drags the group once the pointer has moved TILE_DRAG_START, marking the
    //** group it would go before.)
    //**
    //** @param(Sender A group's button.)
    //**
    //** @param(Shift The keys and buttons held.)
    //**
    //** @param(X Where, across the button.)
    //**
    //** @param(Y Where, down the button.)
    procedure GroupTileMouseMove(Sender: TObject; Shift: TShiftState; X, Y: Single);
    //** @abstract(Drops a dragged group before the one under the pointer, or last below
    //** them; with the right button, opens GroupMenu on the group.)
    //**
    //** @param(Sender A group's button.)
    //**
    //** @param(Button The button.)
    //**
    //** @param(Shift The keys and buttons held.)
    //**
    //** @param(X Where, across the button.)
    //**
    //** @param(Y Where, down the button.)
    procedure GroupTileMouseUp(Sender: TObject; Button: TMouseButton; Shift: TShiftState;
      X, Y: Single);
    //** @abstract(The group button under a point.)
    //**
    //** @param(AAbsolute The point, in the form's coordinates.)
    //**
    //** @param(ABelow On return, True if the point is in GroupsBox but below every button.)
    //**
    //** @returns(The button's index in FShownGroups, or -1.)
    function GroupTileAt(const AAbsolute: TPointF; out ABelow: Boolean): Integer;
    //** @abstract(Marks group button AIndex as where the drag would drop.)
    //**
    //** @param(AIndex The button; -1 for none.)
    procedure SetDropIndex(const AIndex: Integer);
    //** @abstract(Ends a drag: the ghost hidden, the mark taken off.)
    procedure EndDrag;
    //** @abstract(Starts DeferredWork on a later main-loop turn.)
    procedure Defer;
    //** @abstract(Moves the group a drag dropped; FDeferTimer's OnTimer.)
    //**
    //** @param(Sender FDeferTimer.)
    procedure DeferredWork(Sender: TObject);
    //** @abstract(Opens GroupMenu on group AGroup, with only what can be done to it enabled.)
    //**
    //** @param(AGroup The group; empty for the space below the groups.)
    //**
    //** @param(AAbsolute Where, in the form's coordinates.)
    procedure ShowGroupMenu(const AGroup: String; const AAbsolute: TPointF);
    //** @abstract(Adds the group or renames FMenuGroup, as FAskName says; the name dialog's
    //** answer.)
    //**
    //** @param(Sender The dialog's context; not used.)
    //**
    //** @param(AResult How the dialog was closed.)
    //**
    //** @param(AValues The name typed, first.)
    procedure GroupNameClosed(Sender: TObject; const AResult: TModalResult;
      const AValues: array of String);
    //** @abstract(Moves entries AIndices to group AGroup, adding the group last if it is new,
    //** saves the palette, and shows the groups again.)
    //**
    //** @param(AIndices The entries.)
    //**
    //** @param(AGroup The group; trimmed and put in lower case; empty does nothing.)
    procedure MoveEntries(const AIndices: TArray<Integer>; const AGroup: String);
    //** @abstract(Selects entry AIndex, shows its details, and previews it.)
    //**
    //** @param(AIndex An entry of FEntries; -1 for none.)
    procedure SelectEntry(const AIndex: Integer);
    //** @abstract(Tells OnModelChosen the models to place: every one picked, the one shown
    //** (FSelected) first; or the one shown alone, if it is not picked.)
    procedure NotifyModelChosen;
    //** @abstract(Loads entry AIndex into the viewport, in the thumbnails' view, unless
    //** thumbnails are being made.)
    //**
    //** @param(AIndex The entry; -1 empties the viewport.)
    procedure ShowPreview(const AIndex: Integer);
    //** @abstract(Loads entry AIndex's model into the viewport as FModel, upright, and
    //** records its box in its metadata.)
    //**
    //** @param(AIndex The entry.)
    //**
    //** @param(AVariant The material variant to load (PrepareModelVariant); BASE_VARIANT for
    //** the model as made, as a thumbnail always is.)
    //**
    //** @returns(True if it loaded; False, with the reason logged and FModel nil, if not.)
    function LoadEntryModel(const AIndex, AVariant: Integer): Boolean;
    //** @abstract(Shows the menu of entry AIndex's material variants at a tile: the base and
    //** each variant, the one chosen ticked.)
    //**
    //** @param(AIndex The entry; one without variants says so in the Debug tab.)
    //**
    //** @param(AScreen Where, in screen coordinates.)
    procedure ShowVariantMenu(const AIndex: Integer; const AScreen: TPointF);
    //** @abstract(The variant menu's choice: pieces of the entry are placed as it from now on,
    //** and the preview shows it.)
    //**
    //** @param(Sender A menu item; its Tag is the variant, BASE_VARIANT for the base.)
    procedure VariantItemClick(Sender: TObject);
    //** @abstract(Says what was done with each texture of a model that was not used as it
    //** is: a PNG made, or another file of the same name used, on the Debug tab and in the
    //** import log; one that could not be found or read goes to the error log too.)
    //**
    //** @param(AModel The model's name.)
    //**
    //** @param(AFixes Its textures, from PrepareModelTextures.)
    procedure ReportTextures(const AModel: String; const AFixes: TArray<TSprite3DTextureFix>);
    //** @abstract(Shows the background chosen in FBackgroundCombo behind the preview, and
    //** hands its key to OnPreviewBackground.)
    //**
    //** @param(Sender FBackgroundCombo.)
    procedure BackgroundComboChange(Sender: TObject);
    //** @abstract(Setter for PreviewBackground: shows it behind the preview and in
    //** FBackgroundCombo, with "Model Preview" in a colour that can be read on it; an unknown
    //** key is taken as @code(checker).)
    //**
    //** @param(Value The key.)
    procedure SetPreviewBackground(const Value: String);
    //** @abstract(The preview's floor grid's colour, dark on a light background and light on
    //** a dark one.)
    //**
    //** @returns(The colour.)
    function PreviewGridColour: TAlphaColor;
    //** @abstract(Puts the camera back in the thumbnails' view: isometric, orthographic.)
    procedure ResetCameraAngles;
    //** @abstract(Starts making the next queued thumbnail, or says all are made and
    //** previews the selected model.)
    procedure MakeNext;
    //** @abstract(Starts FNextTimer, so MakeNext runs on a later main-loop turn.)
    procedure MakeNextLater;
    //** @abstract(Runs MakeNext; FNextTimer's OnTimer.)
    //**
    //** @param(Sender FNextTimer.)
    procedure NextTimerTimer(Sender: TObject);
    //** @abstract(Starts the grab of the thumbnail being made, once its model has been on
    //** screen for THUMBNAIL_SETTLE_MS.)
    //**
    //** @param(Sender FSettleTimer.)
    procedure SettleTimerTimer(Sender: TObject);
    //** @abstract(Runs the grab's steps for the main thread (TSprite3DOffscreen.Poll): they
    //** are queued too, but a viewport drawing every frame can keep the queue from being run
    //** for seconds. Then, once the try is GRAB_TIMEOUT_MS old, logs how
    //** the grab stands and starts it again, or after GRAB_TRIES gives up: passes over the
    //** model, without a thumbnail, and goes on with the next. While the form is minimised,
    //** when nothing is drawn, the time does not count.)
    //**
    //** @param(Sender FGrabTimer.)
    procedure GrabTimerTimer(Sender: TObject);
    //** @abstract(The procedure the off-screen pass calls with entry AIndex's thumbnail.)
    //**
    //** Made here, so the entry and folder are passed by value, not captured as variables.
    //**
    //** @param(AIndex The entry.)
    //**
    //** @param(AScanId The folder it was made for.)
    //**
    //** @returns(The procedure.)
    function GrabDone(const AIndex, AScanId: Integer): TSprite3DGrabProc;
    //** @abstract(Saves entry AIndex's thumbnail and metadata to the cache and shows it, then
    //** goes on to the next.)
    //**
    //** @param(AIndex The entry.)
    //**
    //** @param(AScanId The folder it was made for; anything but FScanId is dropped.)
    //**
    //** @param(ABitmap The thumbnail; nil if the grab failed. It is the caller's.)
    //**
    //** @param(AError Why the grab failed; empty if it did not.)
    procedure ThumbnailGrabbed(const AIndex, AScanId: Integer; const ABitmap: TBitmap;
      const AError: String);
    //** @abstract(Frames FModel in a view AWidth by AHeight, as the thumbnail shows it,
    //** centred on its centre of rotation, as Sprite3D frames a model.)
    //**
    //** The volume FModelBox sweeps turning about the up axis through the model's
    //** RotationCenter (CalcSweptVolume) is fitted by FitCameraToSweep, which uses the
    //** camera's FitPointsOnAxis: the camera's target stays on that axis, the axis the
    //** builder will turn the piece about, so it is the middle of the picture across, and
    //** the piece is the same size in the picture whichever way it is turned.
    //**
    //** @param(AWidth The view's width; only its ratio to AHeight matters.)
    //**
    //** @param(AHeight The view's height.)
    procedure FrameModel(const AWidth, AHeight: Single);
    //** @abstract(Frames FModel for the grab's own size; the off-screen pass's OnBeforeGrab.)
    //**
    //** @param(Sender FOffscreen.)
    //**
    //** @param(AWidth The grab's width in pixels.)
    //**
    //** @param(AHeight The grab's height in pixels.)
    procedure OffscreenBeforeGrab(Sender: TObject; const AWidth, AHeight: Integer);
    //** @abstract(Starts turning the preview with the left button; puts the thumbnails'
    //** view back with the right, or Control and the left.)
    //**
    //** @param(Sender PreviewArea.)
    //**
    //** @param(Button The button.)
    //**
    //** @param(Shift The keys and buttons held.)
    //**
    //** @param(X Where, across PreviewArea.)
    //**
    //** @param(Y Where, down PreviewArea.)
    procedure PreviewMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState;
      X, Y: Single);
    //** @abstract(Turns the preview by how far the pointer moved across, and tilts it by
    //** how far it moved down, right round if need be: the Spritely camera's gimbals have
    //** no lock.)
    //**
    //** @param(Sender PreviewArea.)
    //**
    //** @param(Shift The keys and buttons held.)
    //**
    //** @param(X Where, across PreviewArea.)
    //**
    //** @param(Y Where, down PreviewArea.)
    procedure PreviewMouseMove(Sender: TObject; Shift: TShiftState; X, Y: Single);
    //** @abstract(Ends a turn of the preview.)
    //**
    //** @param(Sender PreviewArea.)
    //**
    //** @param(Button The button.)
    //**
    //** @param(Shift The keys and buttons held.)
    //**
    //** @param(X Where, across PreviewArea.)
    //**
    //** @param(Y Where, down PreviewArea.)
    procedure PreviewMouseUp(Sender: TObject; Button: TMouseButton; Shift: TShiftState;
      X, Y: Single);
    //** @abstract(Zooms the preview: away from you nearer, towards you further.)
    //**
    //** @param(Sender PreviewArea.)
    //**
    //** @param(Shift The keys and buttons held.)
    //**
    //** @param(WheelDelta How far the wheel turned; a notch is 120.)
    //**
    //** @param(Handled Set to True when the preview took it.)
    procedure PreviewMouseWheel(Sender: TObject; Shift: TShiftState; WheelDelta: Integer;
      var Handled: Boolean);
    //** @abstract(True when the preview has a model to turn: one is shown and no thumbnail
    //** is being made.)
    //**
    //** @returns(Whether the mouse may turn and zoom the preview.)
    function CanTurnPreview: Boolean;
    //** @abstract(Frees FModel, if there is one.)
    procedure FreeModel;
    //** @abstract(Stops making thumbnails: the grab under way is dropped, and the queue
    //** emptied.)
    procedure StopMaking;
  public
    //** @abstract(Begins the error log, ErrorLogFile, afresh for this run of the program,
    //** with a line saying when it started; call once, at start-up. A failure to write it
    //** is ignored.)
    class procedure BeginErrorLog; static;
    //** @abstract(The error log: every error the Library has met since the program
    //** started, across every collection, import and rescan, in the settings folder.)
    //**
    //** @returns(The file's path.)
    class function ErrorLogFile: String; static;
    //** @abstract(Shows the Library, opening the collection open last, if there is one.)
    procedure ShowLibrary;
    //** @abstract(Deletes the whole library, every collection and thumbnail
    //** (ClearAssetLibrary), and shows it empty.)
    //**
    //** Everything under way is stopped first: a thumbnail being made, the hashing, an
    //** artist import. What was done goes to OnLog. The model files are never touched. The
    //** last folder chosen and the preferred format are kept.
    procedure ClearLibrary;
    //** @abstract(Checks the thumbnail of every model of every collection, and writes what
    //** it finds to ThumbnailCheckFile, worst first.)
    //**
    //** A thumbnail is grabbed with a transparent background, so one with nothing in it is
    //** a model that did not draw: each one's share of visible pixels (alpha
    //** CHECK_VISIBLE_ALPHA or more) is measured. None visible is @italic(empty), a problem;
    //** less than CHECK_NEARLY_EMPTY of the picture is @italic(nearly empty), to look into,
    //** as a thin model can be that small; a model with no thumbnail is @italic(missing).
    //** Every model so listed has its share, the highest alpha in its thumbnail, its artist
    //** and collection, and its file. A summary goes to OnLog. Thumbnails are only read;
    //** the window stays responsive meanwhile, and a second check while one runs is
    //** ignored.
    procedure CheckThumbnails;
    //** @abstract(The report of the last CheckThumbnails, in the settings folder; written
    //** afresh by each check.)
    //**
    //** @returns(The file's path.)
    class function ThumbnailCheckFile: String; static;
    //** @abstract(Every model shown, in name order.)
    property Entries: TArray<TAssetEntry> read FEntries;
    //** @abstract(The entry selected, or -1.)
    property Selected: Integer read FSelected;
    //** @abstract(Called with each line the form has to report, for the Debug tab.)
    property OnLog: TAssetsLogEvent read FOnLog write FOnLog;
    //** @abstract(The folder of the one palette of before the library, palette.json, for the
    //** collection LoadLibrary makes of it; set before ShowLibrary.)
    property MigrationFolder: String read FMigrationFolder write FMigrationFolder;
    //** @abstract(The level's grid spacing, for the preview's floor grid; 2 to start with.
    //** Set before ShowLibrary.)
    property GridSize: Single read FGridSize write FGridSize;
    //** @abstract(What the model preview shows behind the model: @code(checker), standing
    //** for transparency, @code(black), @code(grey) or @code(white); set before ShowLibrary,
    //** and by the drop-down over the preview. Thumbnails are always grabbed with a
    //** transparent background, whatever it is.)
    property PreviewBackground: String read FPreviewBackground write SetPreviewBackground;
    //** @abstract(Called with the key of the background chosen over the preview, to keep it.)
    property OnPreviewBackground: TAssetsBackgroundEvent read FOnPreviewBackground
      write FOnPreviewBackground;
    //** @abstract(Called each time a model is selected, with the models picked that can be
    //** placed, so the level's Place Model tool places them.)
    //** Fired as a thumbnail is clicked, with every model picked (Ctrl and Shift pick more
    //** than one), the one clicked first; Place Model picks among them at random.
    property OnModelChosen: TAssetsModelChosenEvent read FOnModelChosen write FOnModelChosen;
  end;


implementation

uses
  System.Threading, System.Math, System.DateUtils, System.IOUtils, System.JSON, JsonText,
  System.Generics.Defaults, System.StrUtils, FMX.DialogService, OSPaths, Sprite3DSweep,
  Sprite3DGroupIcons, Sprite3DFolderDialog, Sprite3DBuilderHelpers,
  Sprite3DBuilderImportForm, Sprite3DBuilderFormatForm, Sprite3DModelContent,
  Sprite3DBuilderSuspectForm, Sprite3DModelVariants;

{$R *.fmx}

const
  //** @abstract(A tile's width and height, and the thumbnail's size on it, in logical
  //** pixels: the thumbnail at its own size, with 4 round it and room for the name below.)
  TILE_IMAGE = THUMBNAIL_SIZE;
  TILE_WIDTH = TILE_IMAGE + 8;
  TILE_HEIGHT = TILE_IMAGE + 28;
  //** @abstract(The room between tiles, and round the grid's edge.)
  TILE_GAP = 6;
  //** @abstract(How far, in logical pixels, the pointer moves with the left button down
  //** before a thumbnail or group is dragged.)
  TILE_DRAG_START = 5;
  //** @abstract(The room left round a model in its thumbnail, as a fraction of the view.)
  THUMBNAIL_MARGIN = 0.06;
  //** @abstract(The thumbnails' view: the isometric inclination, ArcTan@(1/Sqrt@(2@)@) in
  //** degrees, and the camera's azimuth for Sprite3D's 45, which ApplyAngles in the main
  //** form reverses to 315.)
  THUMBNAIL_INCLINATION = 35.26439;
  THUMBNAIL_AZIMUTH = 315;
  //** @abstract(How the cache's metadata names the thumbnails' view.)
  THUMBNAIL_VIEW = 'isometric orthographic';
  //** @abstract(How long, in milliseconds, a model is on screen before its thumbnail is
  //** grabbed, so the viewport has drawn it at least once.)
  THUMBNAIL_SETTLE_MS = 120;
  //** @abstract(A tile's outline; a picked tile's; and the selected tile's fill.)
  TILE_STROKE = TAlphaColor($60808080);
  TILE_SELECTED_STROKE = TAlphaColor($FF2A9FD6);
  TILE_SELECTED_FILL = TAlphaColor($302A9FD6);
  //** @abstract(The preview's turn and tilt, in degrees, for each logical pixel the pointer
  //** moves.)
  PREVIEW_DEGREES_PER_PIXEL = 0.5;
  //** @abstract(The preview's zoom for a notch of the wheel.)
  PREVIEW_ZOOM_STEP = 1.1;
  //** @abstract(A group button's height, its icon's size on it, and its text's size, big
  //** enough to drop on easily.)
  GROUP_TILE_HEIGHT = 66;
  GROUP_ICON_SIZE = 32;
  GROUP_FONT_SIZE = 13;
  //** @abstract(The chosen group's fill, and the outline of the group a drag would drop on.)
  GROUP_CHOSEN_FILL = TAlphaColor($502A9FD6);
  GROUP_DROP_STROKE = TAlphaColor($FFFFC040);
  //** @abstract(The colour an SVG icon is drawn in, and the size it is drawn at, in pixels:
  //** twice its size on the button, for a sharp picture.)
  GROUP_ICON_COLOUR = TAlphaColor($FFE0E0E0);
  GROUP_ICON_PIXELS = 64;
  //** @abstract(The dragged thumbnail's size, in logical pixels.)
  GHOST_SIZE = 72;
  //** @abstract(How often, in milliseconds, a drag at a box's edge scrolls it; how near
  //** the edge, in logical pixels, it starts; and how far a step goes at the edge, more
  //** the further past it the pointer is.)
  DRAG_SCROLL_MS = 40;
  DRAG_SCROLL_EDGE = 28;
  DRAG_SCROLL_STEP = 10;
  //** @abstract(How many thumbnails are made before the time left is shown, so the average
  //** it is worked out from is a fair one.)
  ETA_AFTER = 3;
  //** @abstract(How long a thumbnail's grab may take, in milliseconds, before it is started
  //** again; a grab takes well under a second.)
  GRAB_TIMEOUT_MS = 4000;
  //** @abstract(How many times a thumbnail's grab is started before the model is passed
  //** over.)
  GRAB_TRIES = 3;
  //** @abstract(How often, in milliseconds, FGrabTimer runs what is queued while a grab is
  //** under way.)
  GRAB_POLL_MS = 50;
  //** @abstract(The import log's name, in the settings folder; see ImportLogFile.)
  IMPORT_LOG_FILE_NAME = 'library-import.log';
  //** @abstract(The error log's name, in the settings folder; see ErrorLogFile.)
  ERROR_LOG_FILE_NAME = 'library-errors.log';
  //** @abstract(The job file's name, in the settings folder; see TAssetsForm.JobFile.)
  JOB_FILE_NAME = 'library-job.json';
  //** @abstract(The format named in the job file.)
  JOB_FILE_FORMAT = 'Sprite3DBuilder library job';
  //** @abstract(The thumbnail check's report's name, in the settings folder; see
  //** TAssetsForm.ThumbnailCheckFile.)
  THUMBNAIL_CHECK_FILE_NAME = 'library-thumbnail-check.log';
  //** @abstract(The alpha, 0 to 255, from which a thumbnail's pixel counts as visible in
  //** the thumbnail check; fainter ones are edges and haze.)
  CHECK_VISIBLE_ALPHA = 32;
  //** @abstract(The share of a thumbnail's pixels, 0 to 1, below which it is nearly empty
  //** in the thumbnail check.)
  CHECK_NEARLY_EMPTY = 0.01;
  //** @abstract(How a line of the logs starts: the time, to the millisecond.)
  LOG_TIME_FORMAT = 'yyyy-mm-dd hh:nn:ss.zzz';
  //** @abstract(The name of the file naming the model in the viewport; see LoadingFile.)
  LOADING_FILE_NAME = 'library-loading.txt';
  //** @abstract(The name of the list of models passed over; see SkipFile.)
  SKIP_FILE_NAME = 'library-skipped.txt';
  //** @abstract(The group models alone in their groups are put in, to be sorted by the user.)
  UNSORTED_GROUP = 'unsorted';
  //** @abstract(The fewest models a group made from their names may have; fewer go to
  //** UNSORTED_GROUP.)
  MIN_GROUP_SIZE = 2;
  //** @abstract(The artist the collections of before artists are put under, to be renamed.)
  UNASSIGNED_ARTIST = 'Unassigned';
  //** @abstract(The side of the preview's checker squares, in logical pixels.)
  PREVIEW_CHECKER_SIZE = 16;
  //** @abstract(The preview's floor grid lines, on a light background and on a dark one.)
  PREVIEW_GRID_COLOUR = TAlphaColor($C0202020);
  PREVIEW_GRID_COLOUR_LIGHT = TAlphaColor($C0B0B0B0);
  //** @abstract(The preview's backgrounds, by the keys settings.json keeps, with their
  //** names in the drop-down and, but for the checker, their colours.)
  PREVIEW_BACKGROUNDS: array[0..3] of String = ('checker', 'black', 'grey', 'white');
  PREVIEW_BACKGROUND_NAMES: array[0..3] of String = ('Checker', 'Black', 'Grey', 'White');
  PREVIEW_BACKGROUND_COLOURS: array[0..3] of TAlphaColor = ($00000000, $FF000000,
    $FF808080, $FFFFFFFF);
  //** @abstract(The colour of "Model Preview" on each of PREVIEW_BACKGROUNDS, so it can be
  //** read: dark on the checker, grey and white, light on black.)
  PREVIEW_LABEL_COLOURS: array[0..3] of TAlphaColor = ($FF202020, $FFC0C0C0, $FF101010,
    $FF404040);
  //** @abstract(The colour of the kind's tag on a model's tile.)
  BADGE_TEXT_COLOUR = TAlphaColor($FFFFC040);
  //** @abstract(The fill of a group's tile in the grid, so it stands apart from models.)
  FOLDER_FILL = TAlphaColor($28FFFFFF);

type
  //** @abstract(IAssetsAlive: True until Kill.)
  TAssetsAlive = class(TInterfacedObject, IAssetsAlive)
  private
    //** @abstract(Whether Kill has been called.)
    FDead: Boolean;
  public
    //** @abstract(True until Kill.)
    //**
    //** @returns(Whether the form is still there.)
    function Alive: Boolean;
    //** @abstract(Marks the form as gone.)
    procedure Kill;
  end;

function TAssetsAlive.Alive: Boolean;
begin
  Result := not FDead;
end;

procedure TAssetsAlive.Kill;
begin
  FDead := True;
end;

type
  //** @abstract(What the thumbnail check found for one thumbnail.)
  TThumbnailVerdict = (
    //** @abstract(The model has no thumbnail.)
    tvMissing,
    //** @abstract(No pixel is visible.)
    tvEmpty,
    //** @abstract(Some are, but fewer than CHECK_NEARLY_EMPTY of them.)
    tvNearlyEmpty,
    //** @abstract(An animation library, which has little or nothing to draw: counted, not
    //** listed.)
    tvLibrary,
    //** @abstract(Enough are.)
    tvGood);

  //** @abstract(One line of the thumbnail check's report.)
  TThumbnailCheck = record
    //** @abstract(What was found.)
    Verdict: TThumbnailVerdict;
    //** @abstract(The share of visible pixels, 0 to 1; 0 for one missing.)
    Visible: Double;
    //** @abstract(The highest alpha in the thumbnail, 0 to 255.)
    MaxAlpha: Integer;
    //** @abstract(The model's kind's name, from its metadata.)
    Kind: String;
    //** @abstract(The rest of the line: where the model is.)
    Text: String;
  end;

//** @abstract(Measures how much of ABitmap is visible.)
//**
//** @param(ABitmap The thumbnail.)
//**
//** @param(AVisible On return, the share of its pixels with alpha CHECK_VISIBLE_ALPHA or
//** more, 0 to 1.)
//**
//** @param(AMaxAlpha On return, its highest alpha, 0 to 255.)
//**
//** @returns(False if it could not be read.)
function MeasureVisible(const ABitmap: TBitmap; out AVisible: Double;
  out AMaxAlpha: Integer): Boolean;
var
  Data: TBitmapData;
  Row: PByte;
  Alpha, Count: Integer;
  Direct: Boolean;
begin
  AVisible := 0;
  AMaxAlpha := 0;
  Result := False;
  if (ABitmap.Width = 0) or (ABitmap.Height = 0) or
    not ABitmap.Map(TMapAccess.Read, Data) then
    Exit;
  try
    // Alpha is the top byte of each 32-bit pixel in both these orders
    Direct := (Data.PixelFormat = TPixelFormat.BGRA) or (Data.PixelFormat = TPixelFormat.RGBA);
    Count := 0;
    for var Y := 0 to Data.Height - 1 do
    begin
      Row := Data.GetScanline(Y);
      for var X := 0 to Data.Width - 1 do
      begin
        // The pixel's 32 bits, read as one number: alpha is its top byte
        if Direct then
          Alpha := PCardinal(Row + X * 4)^ shr 24
        else
          Alpha := TAlphaColorRec(Data.GetPixel(X, Y)).A;
        if Alpha > AMaxAlpha then
          AMaxAlpha := Alpha;
        if Alpha >= CHECK_VISIBLE_ALPHA then
          Inc(Count);
      end;
    end;
    AVisible := Count / (Data.Width * Data.Height);
    Result := True;
  finally
    ABitmap.Unmap(Data);
  end;
end;

//** @abstract(A length of time for people: 45s, 3m 05s, 1h 02m.)
//**
//** @param(ASeconds The time in seconds; less than 0 counts as 0.)
//**
//** @returns(The text.)
function DurationText(const ASeconds: Double): String;
var
  Total: Int64;
begin
  Total := Round(Max(0, ASeconds));
  if Total < 60 then
    Result := Format('%ds', [Total])
  else if Total < 3600 then
    Result := Format('%dm %.2ds', [Total div 60, Total mod 60])
  else
    Result := Format('%dh %.2dm', [Total div 3600, (Total mod 3600) div 60]);
end;

//** @abstract(Adds AText, after the time, to the error log; a failure to write is
//** ignored.)
//**
//** @param(AText The line.)
procedure AppendErrorLog(const AText: String);
begin
  try
    TFile.AppendAllText(OSFriendlyPath(TAssetsForm.ErrorLogFile),
      FormatDateTime(LOG_TIME_FORMAT, Now) + ' ' + AText + sLineBreak, TEncoding.UTF8);
  except
    // A log that can't be written is no reason to stop
  end;
end;

//** @abstract(When the program was built, from its file's time, for the logs' first lines.)
//**
//** @returns(The time, or an empty string if it cannot be read.)
function BuildTimeText: String;
begin
  try
    Result := FormatDateTime('yyyy-mm-dd hh:nn:ss', TFile.GetLastWriteTime(ParamStr(0)));
  except
    Result := String.Empty;
  end;
end;

{ TAssetsForm }

procedure TAssetsForm.FormCreate(Sender: TObject);
begin
  FAlive := TAssetsAlive.Create;
  FMaking := -1;
  FSelected := -1;
  FAnchor := -1;
  FPreviewIndex := -1;
  FPreviewVariant := BASE_VARIANT;
  FVariantEntry := -1;
  FTileDown := -1;
  FDropIndex := -1;
  FCacheFolder := TSprite3DAppSettings.ThumbnailFolder;
  FSkipped := TStringList.Create;
  FSkipped.Sorted := True;
  FSkipped.CaseSensitive := False;
  FSkipped.Duplicates := TDuplicates.dupIgnore;
  FPaletteGroups := TDictionary<String, String>.Create;
  FGroupIcons := TDictionary<String, String>.Create;
  FIconBitmaps := TObjectDictionary<String, TBitmap>.Create([doOwnsValues]);
  FGroupParents := TDictionary<String, String>.Create;
  FDropFolder := -1;

  FViewport := TGorillaViewport.Create(PreviewArea);
  FViewport.Parent := PreviewArea;
  FViewport.Align := TAlignLayout.Client;
  FViewport.UseFixedFrameRate := True;
  FViewport.VSync := False;
  FViewport.FixedFrameRate := 60;
  // The mouse goes to PreviewArea, which turns the preview
  FViewport.HitTest := False;

  FPreviewLabel := TLabel.Create(PreviewArea);
  FPreviewLabel.Parent := PreviewArea;
  FPreviewLabel.Align := TAlignLayout.Contents;
  FPreviewLabel.StyledSettings := FPreviewLabel.StyledSettings - [TStyledSetting.Size,
    TStyledSetting.FontColor];
  FPreviewLabel.TextSettings.Font.Size := 16;
  FPreviewLabel.TextSettings.FontColor := TAlphaColor($FFA0A0A0);
  FPreviewLabel.TextSettings.HorzAlign := TTextAlign.Center;
  FPreviewLabel.TextSettings.VertAlign := TTextAlign.Center;
  FPreviewLabel.Text := 'Model Preview';
  FPreviewLabel.HitTest := False;
  FPreviewLabel.BringToFront;

  // Behind the view: a checker to start with, as Sprite3D's transparent
  // background, or a colour, as the drop-down over the preview chooses
  FBackground := TSprite3DBackground.Create(nil);
  FBackground.AttachTo(FViewport);
  FPreviewLabel.BringToFront;
  FBackgroundCombo := TComboBox.Create(PreviewArea);
  FBackgroundCombo.Parent := PreviewArea;
  FBackgroundCombo.Width := 96;
  FBackgroundCombo.Height := 24;
  FBackgroundCombo.Anchors := [TAnchorKind.akTop, TAnchorKind.akRight];
  FBackgroundCombo.Position.Point := TPointF.Create(PreviewArea.Width -
    FBackgroundCombo.Width - 4, 4);
  FBackgroundCombo.CanFocus := False;
  for var Shown in PREVIEW_BACKGROUND_NAMES do
    FBackgroundCombo.Items.Add(Shown);
  FBackgroundCombo.Hint := 'What the preview shows behind the model';
  FBackgroundCombo.ShowHint := True;
  FBackgroundCombo.OnChange := BackgroundComboChange;
  FBackgroundCombo.BringToFront;
  SetPreviewBackground(PREVIEW_BACKGROUNDS[0]);
  FGridSize := 2;

  // The Spritely camera, as the main form's: orthographic, lit from the
  // camera, in the thumbnails' view to start with
  FCamera := TSpritelyOrbitalCamera.Create(Self);
  FCamera.Headlight := True;
  FCamera.Viewport := FViewport;
  FCamera.Camera.ProjectionMode := TGorillaCameraProjection.cpOrthographic;
  ResetCameraAngles;

  // Every thumbnail the same size, its background transparent
  FOffscreen := TSprite3DOffscreen.Create(FViewport);
  FOffscreen.Viewport := FViewport;
  FOffscreen.Width := THUMBNAIL_SIZE;
  FOffscreen.Height := THUMBNAIL_SIZE;
  FOffscreen.TransparentBackground := True;
  FOffscreen.OnBeforeGrab := OffscreenBeforeGrab;

  FSettleTimer := TTimer.Create(Self);
  FSettleTimer.Enabled := False;
  FSettleTimer.Interval := THUMBNAIL_SETTLE_MS;
  FSettleTimer.OnTimer := SettleTimerTimer;

  FGrabTimer := TTimer.Create(Self);
  FGrabTimer.Enabled := False;
  FGrabTimer.Interval := GRAB_POLL_MS;
  FGrabTimer.OnTimer := GrabTimerTimer;

  FNextTimer := TTimer.Create(Self);
  FNextTimer.Enabled := False;
  FNextTimer.Interval := 1;
  FNextTimer.OnTimer := NextTimerTimer;

  FDeferTimer := TTimer.Create(Self);
  FDeferTimer.Enabled := False;
  FDeferTimer.Interval := 1;
  FDeferTimer.OnTimer := DeferredWork;

  FScrollTimer := TTimer.Create(Self);
  FScrollTimer.Enabled := False;
  FScrollTimer.Interval := DRAG_SCROLL_MS;
  FScrollTimer.OnTimer := ScrollTimerTimer;

  FDragGhost := TImage.Create(Self);
  FDragGhost.Parent := Self;
  FDragGhost.Width := GHOST_SIZE;
  FDragGhost.Height := GHOST_SIZE;
  FDragGhost.WrapMode := TImageWrapMode.Fit;
  FDragGhost.Opacity := 0.85;
  FDragGhost.HitTest := False;
  FDragGhost.Visible := False;
  FDragCount := TLabel.Create(FDragGhost);
  FDragCount.Parent := FDragGhost;
  FDragCount.Align := TAlignLayout.Bottom;
  FDragCount.Height := 20;
  FDragCount.StyledSettings := FDragCount.StyledSettings - [TStyledSetting.Size,
    TStyledSetting.Style];
  FDragCount.TextSettings.Font.Size := 15;
  FDragCount.TextSettings.Font.Style := [TFontStyle.fsBold];
  FDragCount.TextSettings.HorzAlign := TTextAlign.Trailing;
  FDragCount.HitTest := False;

  PreviewArea.HitTest := True;
  PreviewArea.OnMouseDown := PreviewMouseDown;
  PreviewArea.OnMouseMove := PreviewMouseMove;
  PreviewArea.OnMouseUp := PreviewMouseUp;
  PreviewArea.OnMouseWheel := PreviewMouseWheel;

  // Nothing here takes the keys, so the form's OnKeyDown has Up and Down
  GroupsBox.CanFocus := False;
  TilesBox.CanFocus := False;

  FTilesLayout := TLayout.Create(Self);
  FTilesLayout.Parent := TilesBox;
  FTilesLayout.Align := TAlignLayout.Top;
  FTilesLayout.Height := 0;
  FTilesLayout.HitTest := False;

  // Resume Scan and Abort Scan, after Rescan, shown only while there is a job
  FResumeButton := TButton.Create(Self);
  FResumeButton.Parent := CollectionBar;
  FResumeButton.Align := TAlignLayout.Left;
  FResumeButton.Margins.Left := 12;
  FResumeButton.Width := 110;
  FResumeButton.Position.X := RescanButton.Position.X + RescanButton.Width + 20;
  FResumeButton.Text := 'Resume Scan';
  FResumeButton.CanFocus := False;
  FResumeButton.OnClick := ResumeButtonClick;
  FResumeButton.Visible := False;
  FAbortButton := TButton.Create(Self);
  FAbortButton.Parent := CollectionBar;
  FAbortButton.Align := TAlignLayout.Left;
  FAbortButton.Margins.Left := 4;
  FAbortButton.Width := 100;
  FAbortButton.Position.X := FResumeButton.Position.X + FResumeButton.Width + 20;
  FAbortButton.Text := 'Abort Scan';
  FAbortButton.CanFocus := False;
  FAbortButton.OnClick := AbortButtonClick;
  FAbortButton.Visible := False;

  StatusLabel.Text := 'No asset folder open';
  Progress.Value := 0;
  Progress.Visible := False;
  SelectEntry(-1);
end;

procedure TAssetsForm.FormDestroy(Sender: TObject);
begin
  FAlive.Kill;
  if FSettleTimer <> nil then
    FSettleTimer.Enabled := False;
  if FGrabTimer <> nil then
    FGrabTimer.Enabled := False;
  if FNextTimer <> nil then
    FNextTimer.Enabled := False;
  if FDeferTimer <> nil then
    FDeferTimer.Enabled := False;
  if FScrollTimer <> nil then
    FScrollTimer.Enabled := False;
  if FOffscreen <> nil then
    FOffscreen.Cancel;
  FreeModel;
  FreeAndNil(FPaletteGroups);
  FreeAndNil(FGroupIcons);
  FreeAndNil(FIconBitmaps);
  FreeAndNil(FGroupParents);
  FreeAndNil(FSkipped);
end;

procedure TAssetsForm.FormKeyDown(Sender: TObject; var Key: Word; var KeyChar: WideChar;
  Shift: TShiftState);
var
  Index: Integer;
  TileTop, TileBottom: Single;
begin
  if FDragging then
    Exit;
  if Key = vkBack then
  begin
    Key := 0;
    UpButtonClick(UpButton);
    Exit;
  end;
  if ((Key <> vkUp) and (Key <> vkDown)) or (Length(FShownGroups) = 0) then
    Exit;
  Index := IndexText(RootOf(FGroup), FShownGroups);
  if Key = vkUp then
    Index := Max(0, Index - 1)
  else
    Index := Min(High(FShownGroups), Index + 1);
  Key := 0;
  if not SameText(FShownGroups[Index], RootOf(FGroup)) then
    ShowGroup(FShownGroups[Index]);
  // Kept in view
  if Index <= High(FGroupTiles) then
  begin
    TileTop := FGroupTiles[Index].Position.Y - FGroupTiles[Index].Margins.Top;
    TileBottom := FGroupTiles[Index].Position.Y + FGroupTiles[Index].Height +
      FGroupTiles[Index].Margins.Bottom;
    if TileTop < GroupsBox.ViewportPosition.Y then
      GroupsBox.ViewportPosition := TPointF.Create(0, TileTop)
    else if TileBottom > GroupsBox.ViewportPosition.Y + GroupsBox.Height then
      GroupsBox.ViewportPosition := TPointF.Create(0, TileBottom - GroupsBox.Height);
  end;
end;

procedure TAssetsForm.ShowLibrary;
begin
  LoadSkipped;
  LoadLibrary;
  // A job left from before, or paused when the Library was closed: shown, not
  // started; Resume Scan carries on
  if (FBulkTotal = 0) and not FJobPaused and LoadJob then
    Log('Assets: ' + PausedText);
  UpdateJobButtons;
  Show;
  BringToFront;
  if FCollection.Id <> String.Empty then
    Exit;   // open already
  // The collection open last, with its artist; else the artist shown last
  for var Entry in FLibrary.Collections do
    if SameText(Entry.Id, FLibrary.Last) then
    begin
      OpenCollection(Entry.Id);
      Exit;
    end;
  if ArtistIndex(FLibrary.LastArtist) >= 0 then
    FArtistId := FLibrary.LastArtist
  else if Length(FLibrary.Artists) > 0 then
    FArtistId := FLibrary.Artists[0].Id;
  OpenCollection(ArtistCollection(FArtistId));
end;

procedure TAssetsForm.LoadLibrary;
var
  Palette: TArray<TSprite3DPaletteGroup>;
  Moved: TSprite3DAssetCollection;
  Entry: TSprite3DLibraryEntry;
  OldFile: String;
begin
  if FLibraryLoaded then
    Exit;
  FLibraryLoaded := True;
  if LoadAssetLibrary(FCacheFolder, FLibrary) then
  begin
    // Collections of before artists: under one, to be renamed
    AssignOrphans;
    // The cache tidied each time the Library opens: a delete cut short last
    // time finished, and the thumbnails and metadata of models no collection
    // has (changed since, or no longer found) deleted
    if AssetDeletionsPending(FCacheFolder) then
      Log('Assets: a delete was left unfinished last time; finishing it');
    StartPurge;
    Exit;
  end;
  // No library yet. The one palette of before it, if there is one, becomes
  // its first collection, to be scanned from the folder it was made from
  OldFile := TPath.Combine(FCacheFolder, ASSET_PALETTE_FILE_NAME);
  if not LoadAssetPalette(FCacheFolder, Palette) then
    Exit;
  Moved := Default(TSprite3DAssetCollection);
  Moved.Id := NewCollectionId;
  Moved.Name := 'Kaykit Dungeon';
  if (FMigrationFolder <> String.Empty) and DirectoryExists(FMigrationFolder) then
  begin
    SetLength(Moved.Sources, 1);
    Moved.Sources[0].Folder := FMigrationFolder;
    Moved.Sources[0].Formats := nil;
  end;
  Moved.Groups := Palette;
  Moved.Scanned := False;
  Moved.ArtistId := EnsureArtist(UNASSIGNED_ARTIST);
  try
    SaveAssetCollection(FCacheFolder, Moved);
  except
    on E: Exception do
    begin
      LogError('Assets: can''t save the collection ' + Moved.Name + ': ' + E.Message);
      Exit;
    end;
  end;
  Entry := Default(TSprite3DLibraryEntry);
  Entry.Id := Moved.Id;
  Entry.Name := Moved.Name;
  Entry.ArtistId := Moved.ArtistId;
  FLibrary.Collections := [Entry];
  FLibrary.Last := Moved.Id;
  FLibrary.LastFolder := FMigrationFolder;
  SaveLibrary;
  // Kept, renamed, so it is not moved again
  try
    TFile.Move(OldFile, OldFile + '.moved');
  except
    on E: Exception do
      LogError('Assets: can''t rename ' + OldFile + ': ' + E.Message);
  end;
  Log('Assets: the palette is now the collection ' + Moved.Name + ' in the library');
end;

procedure TAssetsForm.SaveLibrary;
begin
  try
    SaveAssetLibrary(FCacheFolder, FLibrary);
  except
    on E: Exception do
      LogError('Assets: can''t save the library in ' + FCacheFolder + ': ' + E.Message);
  end;
end;

procedure TAssetsForm.FillCollections;
var
  Chosen, ArtistAt, LibraryModels: Integer;
begin
  // The artists first, the one shown chosen
  ArtistAt := ArtistIndex(FArtistId);
  FFillingArtists := True;
  try
    ArtistCombo.BeginUpdate;
    try
      ArtistCombo.Clear;
      for var Artist in FLibrary.Artists do
        ArtistCombo.Items.Add(ArtistText(Artist));
      ArtistCombo.ItemIndex := ArtistAt;
    finally
      ArtistCombo.EndUpdate;
    end;
  finally
    FFillingArtists := False;
  end;
  ArtistCombo.Enabled := Length(FLibrary.Artists) > 0;
  ArtistMenuButton.Enabled := ArtistAt >= 0;
  AddCollectionButton.Enabled := ArtistAt >= 0;

  // Then that artist's collections
  FFillingCollections := True;
  try
    CollectionCombo.BeginUpdate;
    try
      CollectionCombo.Clear;
      FShownCollections := nil;
      Chosen := -1;
      for var I := 0 to High(FLibrary.Collections) do
      begin
        if not SameText(FLibrary.Collections[I].ArtistId, FArtistId) then
          Continue;
        CollectionCombo.Items.Add(CollectionText(FLibrary.Collections[I]));
        FShownCollections := FShownCollections + [I];
        if SameText(FLibrary.Collections[I].Id, FCollection.Id) then
          Chosen := High(FShownCollections);
      end;
      CollectionCombo.ItemIndex := Chosen;
    finally
      CollectionCombo.EndUpdate;
    end;
  finally
    FFillingCollections := False;
  end;
  CollectionCombo.Enabled := Length(FShownCollections) > 0;
  RescanButton.Enabled := FCollection.Id <> String.Empty;
  CollectionMenuButton.Enabled := FCollection.Id <> String.Empty;
  // The title: the library's model count, summed over its collections as
  // the artist bar sums an artist's (a model in two collections counts
  // twice), then the artist and collection shown
  LibraryModels := 0;
  for var Entry in FLibrary.Collections do
    Inc(LibraryModels, Entry.Models);
  Caption := 'Library (' + CountText(LibraryModels, 'model') + ')';
  if (FCollection.Id <> String.Empty) and (ArtistAt >= 0) then
    Caption := Caption + ' - ' + FLibrary.Artists[ArtistAt].Name + ' / ' + FCollection.Name
  else if ArtistAt >= 0 then
    Caption := Caption + ' - ' + FLibrary.Artists[ArtistAt].Name;
end;

procedure TAssetsForm.OpenCollection(const AId: String; const ARescan: Boolean;
  const ARemakeBefore: TDateTime);
var
  Results: TArray<TAssetHashResult>;
  Opened: TSprite3DAssetCollection;
begin
  StopMaking;
  FRemakeBefore := ARemakeBefore;
  Inc(FScanId);
  FScanning := False;
  FEntries := nil;
  FGroup := String.Empty;
  SelectEntry(-1);
  BuildTiles;
  if (AId = String.Empty) or not LoadAssetCollection(FCacheFolder, AId, Opened) then
  begin
    if AId <> String.Empty then
      LogError('Assets: can''t read the collection ' + AId);
    FCollection := Default(TSprite3DAssetCollection);
    FGroupOrder := nil;
    FPaletteGroups.Clear;
    FGroupParents.Clear;
    FGroupIcons.Clear;
    BuildGroups;
    FillCollections;
    if Length(FLibrary.Artists) = 0 then
      StatusLabel.Text := 'No artists yet: Add Artist..., or Add Artist Collections..., ' +
        'to start'
    else if Length(FShownCollections) = 0 then
      StatusLabel.Text := 'No collections for this artist yet: Add New Asset Collection...'
    else
      StatusLabel.Text := 'No collection open';
    Progress.Value := 0;
    Progress.Visible := False;
    Exit;
  end;
  // The library's name and artist for it stand
  for var Entry in FLibrary.Collections do
    if SameText(Entry.Id, AId) then
    begin
      Opened.Name := Entry.Name;
      Opened.ArtistId := Entry.ArtistId;
    end;
  FCollection := Opened;
  FArtistId := FCollection.ArtistId;
  FLibrary.LastArtist := FArtistId;
  FLibrary.Last := FCollection.Id;
  SaveLibrary;
  FillCollections;
  Log('Assets: collection ' + FCollection.Name + ' opened');
  if ARescan or (ARemakeBefore > 0) or not FCollection.Scanned or
    (Length(FCollection.Models) = 0) then
  begin
    // Why its folders are read again, for the Debug tab (owner, 13 November
    // 2026: collections seemed to be rescanned every time they were opened)
    if ARescan then
      Log('Assets: reading its folders: a rescan was asked for')
    else if ARemakeBefore > 0 then
      Log('Assets: reading its folders: its thumbnails are being made again')
    else if not FCollection.Scanned then
      Log('Assets: reading its folders: never scanned to the end')
    else
      Log('Assets: reading its folders: no models saved for it');
    ScanCollection;
    Exit;
  end;
  Log(Format('Assets: %d models as last scanned; folders not read', [Length(FCollection.Models)]));
  // As it was saved: no files read but each thumbnail's
  SetLength(Results, Length(FCollection.Models));
  for var I := 0 to High(FCollection.Models) do
  begin
    Results[I].FileName := FCollection.Models[I].FileName;
    Results[I].Hash := FCollection.Models[I].Key;
    Results[I].Files := nil;
    Results[I].Error := String.Empty;
  end;
  HashesDone(FScanId, Results);
end;

function TAssetsForm.StartFolder: String;
var
  Up: String;
begin
  Result := OSFriendlyPath(FLibrary.LastFolder);
  // A folder since moved or renamed: the nearest one above it
  while (Result <> String.Empty) and not DirectoryExists(Result) do
  begin
    Up := ExtractFileDir(ExcludeTrailingPathDelimiter(Result));
    if SameText(Up, Result) then
      Up := String.Empty;
    Result := Up;
  end;
end;

function TAssetsForm.ChooseSources(const ARoots: TArray<String>):
  TArray<TSprite3DCollectionSource>;
var
  Found, Chosen: TArray<TModelFolder>;
  Preferred: String;
  Source: TSprite3DCollectionSource;
begin
  Result := nil;
  Found := FindModelFolders(ARoots);
  if Length(Found) = 0 then
  begin
    TDialogService.ShowMessage('There are no models in ' + String.Join(', ', ARoots) +
      ' or the folders below.');
    Exit;
  end;
  Preferred := FLibrary.PreferredFormat;
  if not ChooseModelFolders(ARoots, Found, Preferred, Chosen) then
    Exit;
  if (Length(Found) > 1) and not SameText(Preferred, FLibrary.PreferredFormat) then
  begin
    FLibrary.PreferredFormat := Preferred;
    SaveLibrary;
  end;
  for var Folder in Chosen do
  begin
    Source.Folder := Folder.Folder;
    Source.Formats := [Folder.Format];
    Result := Result + [Source];
  end;
end;

function TAssetsForm.SourcesText: String;
var
  Part: String;
begin
  Result := String.Empty;
  for var Source in FCollection.Sources do
  begin
    Part := Source.Folder;
    if Length(Source.Formats) > 0 then
      Part := Part + ' (' + String.Join(' ', Source.Formats) + ')';
    if Result <> String.Empty then
      Result := Result + ', ';
    Result := Result + Part;
  end;
end;

procedure TAssetsForm.CollectionComboChange(Sender: TObject);
var
  Index: Integer;
begin
  if FFillingCollections or (CollectionCombo.ItemIndex < 0) or
    (CollectionCombo.ItemIndex > High(FShownCollections)) then
    Exit;
  Index := FShownCollections[CollectionCombo.ItemIndex];
  if not SameText(FLibrary.Collections[Index].Id, FCollection.Id) then
  begin
    LeaveJob('another collection chosen');
    OpenCollection(FLibrary.Collections[Index].Id);
  end;
end;

procedure TAssetsForm.AddCollectionButtonClick(Sender: TObject);
var
  Folders: TArray<String>;
  Suggested: String;
begin
  if ArtistIndex(FArtistId) < 0 then
  begin
    TDialogService.ShowMessage('Choose an artist for the collection first, or Add Artist...');
    Exit;
  end;
  if not SelectFolders('Add New Asset Collection', StartFolder, Folders) then
    Exit;
  FLibrary.LastFolder := Folders[0];
  SaveLibrary;
  FNewSources := ChooseSources(Folders);
  if Length(FNewSources) = 0 then
    Exit;
  // The folder's name, as a start
  Suggested := ExtractFileName(ExcludeTrailingPathDelimiter(Folders[0]));
  if Suggested <> String.Empty then
    Suggested := UpperCase(Suggested.Substring(0, 1)) + Suggested.Substring(1);
  FAskName := gnNewCollection;
  TDialogService.InputQuery('Add New Asset Collection', ['Name of the collection'],
    [Suggested], GroupNameClosed);
end;

procedure TAssetsForm.RescanButtonClick(Sender: TObject);
begin
  if FCollection.Id = String.Empty then
    Exit;
  StopBulk('a rescan started');
  AppendErrorLog('--- Rescan: ' + FCollection.Name);
  ScanCollection;
end;

procedure TAssetsForm.RegroupItemClick(Sender: TObject);
begin
  if FCollection.Id = String.Empty then
    Exit;
  TDialogService.MessageDialog('Regroup ' + FCollection.Name + '? Its groups, the icons ' +
    'chosen for them and where each model is, are thrown away, and every model is grouped ' +
    'again from its name, those alone in their group in Unsorted. The models and ' +
    'thumbnails stay.', TMsgDlgType.mtConfirmation, [TMsgDlgBtn.mbYes, TMsgDlgBtn.mbNo],
    TMsgDlgBtn.mbNo, 0, RegroupClosed);
end;

procedure TAssetsForm.RegroupClosed(Sender: TObject; const AResult: TModalResult);
var
  Collection: TSprite3DAssetCollection;
begin
  if (AResult <> mrYes) or (FCollection.Id = String.Empty) then
    Exit;
  LeaveJob('the collection regrouped');
  Collection := FCollection;
  Collection.Groups := nil;
  try
    SaveAssetCollection(FCacheFolder, Collection);
  except
    on E: Exception do
    begin
      LogError('Assets: can''t regroup ' + Collection.Name + ': ' + E.Message);
      Exit;
    end;
  end;
  Log('Assets: ' + Collection.Name + ' regrouped from its models'' names');
  OpenCollection(Collection.Id);
end;

procedure TAssetsForm.RemakeThumbnailsItemClick(Sender: TObject);
begin
  if FCollection.Id = String.Empty then
    Exit;
  StopBulk('thumbnails remade');
  AppendErrorLog('--- Remake thumbnails: ' + FCollection.Name);
  Log('Assets: making every thumbnail of ' + FCollection.Name + ' again');
  OpenCollection(FCollection.Id, True, Now);
end;

procedure TAssetsForm.CollectionMenuButtonClick(Sender: TObject);
var
  At: TPointF;
  Item: TMenuItem;
begin
  if FCollection.Id = String.Empty then
    Exit;
  Log('Assets: collection menu: removing ' + MoveCollectionItem.ItemsCount.ToString +
    ' Move to Artist item(s)');
  // Move to Artist: every other artist, as they are now. Only the menu items
  // made here are freed, through Items. DeleteChildren must not be used: it
  // frees every child of the item, and once the menu has been shown a menu
  // item's children include the style objects FMX gave it, which it still
  // points at. Freeing those is the likely cause of the menu hanging the
  // program (owner, 13 November 2026).
  for var I := MoveCollectionItem.ItemsCount - 1 downto 0 do
    MoveCollectionItem.Items[I].Free;
  for var I := 0 to High(FLibrary.Artists) do
  begin
    if SameText(FLibrary.Artists[I].Id, FArtistId) then
      Continue;
    Item := TMenuItem.Create(MoveCollectionItem);
    Item.Text := FLibrary.Artists[I].Name;
    Item.Tag := I;
    Item.OnClick := MoveToArtistClick;
    MoveCollectionItem.AddObject(Item);
  end;
  MoveCollectionItem.Enabled := MoveCollectionItem.ItemsCount > 0;
  At := ClientToScreen(CollectionMenuButton.LocalToAbsolute(
    TPointF.Create(0, CollectionMenuButton.Height)));
  // Written to the import log as well as the Debug tab, so it can be read
  // even if the program has to be stopped
  Log('Assets: collection menu: showing, ' + MoveCollectionItem.ItemsCount.ToString +
    ' artist(s) to move to');
  CollectionMenu.Popup(At.X, At.Y);
  Log('Assets: collection menu: Popup returned');
end;

procedure TAssetsForm.MoveToArtistClick(Sender: TObject);
var
  At: Integer;
begin
  if not (Sender is TMenuItem) or (FCollection.Id = String.Empty) then
    Exit;
  At := TMenuItem(Sender).Tag;
  if (At < 0) or (At > High(FLibrary.Artists)) then
    Exit;
  if HasCollection(FCollection.Name, FLibrary.Artists[At].Id) then
  begin
    TDialogService.ShowMessage(FLibrary.Artists[At].Name + ' has a collection called ' +
      FCollection.Name + ' already.');
    Exit;
  end;
  Log('Assets: collection ' + FCollection.Name + ' moved to ' + FLibrary.Artists[At].Name);
  FCollection.ArtistId := FLibrary.Artists[At].Id;
  for var I := 0 to High(FLibrary.Collections) do
    if SameText(FLibrary.Collections[I].Id, FCollection.Id) then
      FLibrary.Collections[I].ArtistId := FCollection.ArtistId;
  FArtistId := FCollection.ArtistId;
  FLibrary.LastArtist := FArtistId;
  SavePalette;
  SaveLibrary;
  FillCollections;
end;

procedure TAssetsForm.RenameCollectionItemClick(Sender: TObject);
begin
  if FCollection.Id = String.Empty then
    Exit;
  FAskName := gnRenameCollection;
  TDialogService.InputQuery('Rename Collection', ['New name for the collection'],
    [FCollection.Name], GroupNameClosed);
end;

procedure TAssetsForm.CollectionNamed(const AAsk: TGroupNameAsk; const AName: String);
var
  Entry: TSprite3DLibraryEntry;
  Id: String;
begin
  if AName = String.Empty then
    Exit;
  for Entry in FLibrary.Collections do
    if SameText(Entry.Name, AName) and SameText(Entry.ArtistId, FArtistId) and
      ((AAsk = gnNewCollection) or not SameText(Entry.Id, FCollection.Id)) then
    begin
      TDialogService.ShowMessage('This artist has a collection called ' + AName +
        ' already.');
      Exit;
    end;
  if AAsk = gnRenameCollection then
  begin
    if FCollection.Id = String.Empty then
      Exit;
    Log('Assets: collection ' + FCollection.Name + ' renamed ' + AName);
    FCollection.Name := AName;
    for var I := 0 to High(FLibrary.Collections) do
      if SameText(FLibrary.Collections[I].Id, FCollection.Id) then
        FLibrary.Collections[I].Name := AName;
    SavePalette;
    SaveLibrary;
    FillCollections;
    Exit;
  end;
  // A new one, with its folders, scanned as it opens
  Id := NewCollection(AName, FNewSources, FArtistId);
  FNewSources := nil;
  if Id <> String.Empty then
  begin
    LeaveJob('a collection added');
    OpenCollection(Id);
  end;
end;

function TAssetsForm.NewCollection(const AName: String;
  const ASources: TArray<TSprite3DCollectionSource>; const AArtistId: String): String;
var
  Made: TSprite3DAssetCollection;
  Entry: TSprite3DLibraryEntry;
begin
  Result := String.Empty;
  Made := Default(TSprite3DAssetCollection);
  Made.Id := NewCollectionId;
  Made.Name := AName;
  Made.Sources := ASources;
  Made.ArtistId := AArtistId;
  try
    SaveAssetCollection(FCacheFolder, Made);
  except
    on E: Exception do
    begin
      LogError('Assets: can''t save the collection ' + AName + ': ' + E.Message);
      Exit;
    end;
  end;
  Entry := Default(TSprite3DLibraryEntry);
  Entry.Id := Made.Id;
  Entry.Name := Made.Name;
  Entry.ArtistId := AArtistId;
  FLibrary.Collections := FLibrary.Collections + [Entry];
  SaveLibrary;
  Log('Assets: collection ' + AName + ' added');
  Result := Made.Id;
end;

function TAssetsForm.HasCollection(const AName, AArtistId: String): Boolean;
begin
  for var Entry in FLibrary.Collections do
    if SameText(Entry.Name, AName) and SameText(Entry.ArtistId, AArtistId) then
      Exit(True);
  Result := False;
end;

function TAssetsForm.ArtistIndex(const AId: String): Integer;
begin
  for var I := 0 to High(FLibrary.Artists) do
    if SameText(FLibrary.Artists[I].Id, AId) then
      Exit(I);
  Result := -1;
end;

function TAssetsForm.EnsureArtist(const AName: String): String;
var
  Artist: TSprite3DArtist;
begin
  for var Each in FLibrary.Artists do
    if SameText(Each.Name, AName) then
      Exit(Each.Id);
  Artist.Id := NewCollectionId;
  Artist.Name := AName;
  FLibrary.Artists := FLibrary.Artists + [Artist];
  SaveLibrary;
  Log('Assets: artist ' + AName + ' added');
  Result := Artist.Id;
end;

procedure TAssetsForm.AssignOrphans;
var
  Unassigned: String;
  Changed: Boolean;
begin
  Changed := False;
  for var I := 0 to High(FLibrary.Collections) do
    if ArtistIndex(FLibrary.Collections[I].ArtistId) < 0 then
    begin
      Unassigned := EnsureArtist(UNASSIGNED_ARTIST);
      FLibrary.Collections[I].ArtistId := Unassigned;
      Changed := True;
    end;
  if Changed then
  begin
    SaveLibrary;
    Log('Assets: collections with no artist put under ' + UNASSIGNED_ARTIST);
  end;
end;

function TAssetsForm.ArtistCollection(const AArtistId: String): String;
begin
  Result := String.Empty;
  for var Entry in FLibrary.Collections do
    if SameText(Entry.ArtistId, AArtistId) then
    begin
      if SameText(Entry.Id, FLibrary.Last) then
        Exit(Entry.Id);
      if Result = String.Empty then
        Result := Entry.Id;
    end;
end;

procedure TAssetsForm.ArtistComboChange(Sender: TObject);
begin
  if FFillingArtists or (ArtistCombo.ItemIndex < 0) or
    (ArtistCombo.ItemIndex > High(FLibrary.Artists)) then
    Exit;
  if SameText(FLibrary.Artists[ArtistCombo.ItemIndex].Id, FArtistId) then
    Exit;
  LeaveJob('another artist chosen');
  FArtistId := FLibrary.Artists[ArtistCombo.ItemIndex].Id;
  FLibrary.LastArtist := FArtistId;
  SaveLibrary;
  OpenCollection(ArtistCollection(FArtistId));
end;

procedure TAssetsForm.NewArtistButtonClick(Sender: TObject);
begin
  FAskName := gnNewArtist;
  TDialogService.InputQuery('Add Artist', ['Name of the artist'], [''], GroupNameClosed);
end;

procedure TAssetsForm.ArtistMenuButtonClick(Sender: TObject);
var
  At: TPointF;
begin
  if FArtistId = String.Empty then
    Exit;
  At := ClientToScreen(ArtistMenuButton.LocalToAbsolute(
    TPointF.Create(0, ArtistMenuButton.Height)));
  ArtistMenu.Popup(At.X, At.Y);
end;

procedure TAssetsForm.RenameArtistItemClick(Sender: TObject);
begin
  if ArtistIndex(FArtistId) < 0 then
    Exit;
  FAskName := gnRenameArtist;
  TDialogService.InputQuery('Rename Artist', ['New name for the artist'],
    [FLibrary.Artists[ArtistIndex(FArtistId)].Name], GroupNameClosed);
end;

procedure TAssetsForm.RescanArtistItemClick(Sender: TObject);
begin
  StartArtistRun(False);
end;

procedure TAssetsForm.RemakeArtistItemClick(Sender: TObject);
begin
  StartArtistRun(True);
end;

procedure TAssetsForm.StartArtistRun(const ARemake: Boolean);
var
  At: Integer;
  Ids: TArray<String>;
  Name, What, Title, First: String;
begin
  At := ArtistIndex(FArtistId);
  if At < 0 then
    Exit;
  Name := FLibrary.Artists[At].Name;
  Ids := nil;
  for var Entry in FLibrary.Collections do
    if SameText(Entry.ArtistId, FArtistId) then
      Ids := Ids + [Entry.Id];
  if Length(Ids) = 0 then
  begin
    TDialogService.ShowMessage(Name + ' has no collections to rescan.');
    Exit;
  end;
  if ARemake then
    What := 'thumbnails remade'
  else
    What := 'rescanned';
  StopBulk('a rescan started');
  Title := Format('Artist %s: %s, %s', [IfThen(ARemake, 'thumbnails remade', 'rescan'),
    Name, CountText(Length(Ids), 'collection')]);
  StartImportLog(Title);
  FRunErrors := 0;
  // Each read again, one after another; the one open now is shown at the end
  if (FCollection.Id <> String.Empty) and SameText(FCollection.ArtistId, FArtistId) then
    First := FCollection.Id
  else
    First := Ids[0];
  Log(Format('Assets: %s, the %s of %s', [What, CountText(Length(Ids), 'collection'),
    Name]));
  if ARemake then
    StartJob('remake', Title, Ids, First, Format('%s: %s %s.', [Name,
      CountText(Length(Ids), 'collection'), What]), True, Now)
  else
    StartJob('rescan', Title, Ids, First, Format('%s: %s %s.', [Name,
      CountText(Length(Ids), 'collection'), What]), True, 0);
end;

procedure TAssetsForm.ArtistNamed(const AAsk: TGroupNameAsk; const AName: String);
var
  At: Integer;
  Artist: TSprite3DArtist;
begin
  if AName = String.Empty then
    Exit;
  for var Each in FLibrary.Artists do
    if SameText(Each.Name, AName) and
      ((AAsk = gnNewArtist) or not SameText(Each.Id, FArtistId)) then
    begin
      TDialogService.ShowMessage('There is an artist called ' + AName + ' already.');
      Exit;
    end;
  if AAsk = gnRenameArtist then
  begin
    At := ArtistIndex(FArtistId);
    if At < 0 then
      Exit;
    Log('Assets: artist ' + FLibrary.Artists[At].Name + ' renamed ' + AName);
    FLibrary.Artists[At].Name := AName;
    SaveLibrary;
    FillCollections;
    Exit;
  end;
  // A new one, shown, with no collections yet
  Artist.Id := NewCollectionId;
  Artist.Name := AName;
  FLibrary.Artists := FLibrary.Artists + [Artist];
  LeaveJob('an artist added');
  FArtistId := Artist.Id;
  FLibrary.LastArtist := FArtistId;
  SaveLibrary;
  Log('Assets: artist ' + AName + ' added');
  OpenCollection(String.Empty);
end;

procedure TAssetsForm.DeleteArtistItemClick(Sender: TObject);
var
  At, Count: Integer;
begin
  At := ArtistIndex(FArtistId);
  if At < 0 then
    Exit;
  Count := 0;
  for var Entry in FLibrary.Collections do
    if SameText(Entry.ArtistId, FArtistId) then
      Inc(Count);
  TDialogService.MessageDialog(Format('Delete the artist %s and their %d collections from ' +
    'the library? Their groups go with them, and the thumbnails of models no other ' +
    'collection has. The model files and folders are not touched.',
    [FLibrary.Artists[At].Name, Count]), TMsgDlgType.mtConfirmation,
    [TMsgDlgBtn.mbYes, TMsgDlgBtn.mbNo], TMsgDlgBtn.mbNo, 0, DeleteArtistClosed);
end;

procedure TAssetsForm.DeleteArtistClosed(Sender: TObject; const AResult: TModalResult);
var
  At: Integer;
  Name: String;
begin
  At := ArtistIndex(FArtistId);
  if (AResult <> mrYes) or (At < 0) then
    Exit;
  Name := FLibrary.Artists[At].Name;
  // Marked first: from here on the library no longer lists them, and if the
  // program stops before the thumbnails are gone, the delete is finished the
  // next time the Library opens
  if not MarkAssetArtistDeleted(FCacheFolder, FArtistId) then
  begin
    LogError('Assets: can''t delete the artist ' + Name + ': the library could not be ' +
      'written');
    Exit;
  end;
  StopBulk('the artist deleted');
  StopMaking;
  Log('Assets: artist ' + Name + ' deleted, with their collections');
  for var I := High(FLibrary.Collections) downto 0 do
    if SameText(FLibrary.Collections[I].ArtistId, FArtistId) then
      Delete(FLibrary.Collections, I, 1);
  Delete(FLibrary.Artists, At, 1);
  FCollection := Default(TSprite3DAssetCollection);
  FLibrary.Last := String.Empty;
  // The nearest artist left: the one now in its place, or the one before it
  // if it was the last
  if Length(FLibrary.Artists) > 0 then
    FArtistId := FLibrary.Artists[Min(At, High(FLibrary.Artists))].Id
  else
    FArtistId := String.Empty;
  FLibrary.LastArtist := FArtistId;
  SaveLibrary;
  OpenCollection(ArtistCollection(FArtistId));
  StartPurge;
end;

function TAssetsForm.BulkArtist: String;
var
  At: Integer;
begin
  Result := String.Empty;
  At := ArtistIndex(FArtistId);
  if (At >= 0) and not SameText(FLibrary.Artists[At].Name, UNASSIGNED_ARTIST) then
    Result := FArtistId;
end;

procedure TAssetsForm.AddArtistButtonClick(Sender: TObject);
var
  Roots, Folders, Formats, Defaults: TArray<String>;
  Found: TArray<TModelFolder>;
  Counts: TArray<Integer>;
  Ticks: TArray<Boolean>;
  Sources: TArray<TSprite3DCollectionSource>;
  Source: TSprite3DCollectionSource;
  CollectionName, Pick, Chosen, FirstId, Id, ArtistId, Folder: String;
  NewIds, Inside, FolderArtists, Rejected, Offered: TArray<String>;
  OnlyDefaults, Stopped: Boolean;
  Added, NoModels, NoFormat, Existing, NotChosen: Integer;
  Target, Title, PickCopy: String;
  SameFormat, ChosenFolders: TArray<TModelFolder>;
begin
  Target := BulkArtist;
  if Target = String.Empty then
    Title := 'Add Artist Collections'
  else
    Title := 'Add Collections to ' + FLibrary.Artists[ArtistIndex(Target)].Name;
  if not SelectFolders(Title, StartFolder, Roots) then
    Exit;
  // A new import log for each artist import; the error log is added to
  StopBulk('a new one started');
  StartImportLog('Artist import: ' + Title + ' from ' + String.Join(', ', Roots));
  FRunErrors := 0;
  FLibrary.LastFolder := Roots[0];
  SaveLibrary;
  // Each folder directly inside, in name order, under the artist shown,
  // or with none, the artist named after the folder chosen
  Folders := nil;
  FolderArtists := nil;
  for var Root in Roots do
    try
      Inside := TDirectory.GetDirectories(OSFriendlyPath(Root));
      TArray.Sort<String>(Inside, TComparer<String>.Construct(
        function(const A, B: String): Integer
        begin
          Result := CompareText(A, B);
        end));
      if Length(Inside) = 0 then
        Continue;
      if Target <> String.Empty then
        ArtistId := Target
      else
        ArtistId := EnsureArtist(ExtractFileName(ExcludeTrailingPathDelimiter(Root)));
      for var Sub in Inside do
      begin
        Folders := Folders + [Sub];
        FolderArtists := FolderArtists + [ArtistId];
      end;
    except
      on E: Exception do
        LogError('Assets: can''t read ' + Root + ': ' + E.Message);
    end;
  if Length(Folders) = 0 then
  begin
    TDialogService.ShowMessage('There are no folders in ' + String.Join(', ', Roots) + '.');
    Exit;
  end;

  NewIds := nil;
  Defaults := nil;
  OnlyDefaults := False;
  Rejected := nil;
  Stopped := False;
  FirstId := String.Empty;
  Added := 0;
  NoModels := 0;
  NoFormat := 0;
  Existing := 0;
  NotChosen := 0;
  CollectionBar.Enabled := False;
  ArtistBar.Enabled := False;
  try
    for var FolderAt := 0 to High(Folders) do
    begin
      Folder := Folders[FolderAt];
      ArtistId := FolderArtists[FolderAt];
      CollectionName := ExtractFileName(ExcludeTrailingPathDelimiter(Folder));
      if HasCollection(CollectionName, ArtistId) then
      begin
        Log('Assets: ' + CollectionName + ' is a collection already; passed over');
        Inc(Existing);
        Continue;
      end;
      StatusLabel.Text := 'Looking in ' + CollectionName + '...';
      Application.ProcessMessages;
      Found := FindModelFolders([Folder]);
      if Length(Found) = 0 then
      begin
        LogError('Assets: no models in ' + Folder);
        Inc(NoModels);
        Continue;
      end;
      Formats := FoundModelFormats(Found);
      // The first of the defaults so far that it has
      Pick := String.Empty;
      for var Ext in Defaults do
        if IndexText(Ext, Formats) >= 0 then
        begin
          Pick := Ext;
          Break;
        end;
      if Pick = String.Empty then
      begin
        if OnlyDefaults then
        begin
          Log('Assets: ' + CollectionName + ' has none of the formats chosen; passed over');
          Inc(NoFormat);
          Continue;
        end;
        // Formats a Skip has turned down already are not offered again; with
        // only those, it is not asked about at all
        Offered := nil;
        for var Ext in Formats do
          if IndexText(Ext, Rejected) < 0 then
            Offered := Offered + [Ext];
        if Length(Offered) = 0 then
        begin
          Log('Assets: ' + CollectionName + ' has only formats skipped before; passed over');
          Inc(NoFormat);
          Continue;
        end;
        SetLength(Counts, Length(Offered));
        for var I := 0 to High(Offered) do
        begin
          Counts[I] := 0;
          for var Item in Found do
            if Item.Format = Offered[I] then
              Inc(Counts[I], Item.Count);
        end;
        case AskFormat(CollectionName, Offered, Counts, Defaults, Chosen) of
          faImport:
            begin
              Pick := Chosen;
              Defaults := Defaults + [Chosen];
              Log('Assets: ' + ModelFormatName(Chosen) + ' is default ' +
                IntToStr(Length(Defaults)));
            end;
          faSkip:
            begin
              // What it offered is turned down, for the folders still to come
              Rejected := Rejected + Offered;
              Inc(NoFormat);
              Continue;
            end;
          faOnlyDefaults:
            begin
              OnlyDefaults := True;
              Inc(NoFormat);
              Continue;
            end;
        else
          Stopped := True;
          Break;
        end;
      end;
      // That format's folders, an engine's second copy left out; with more
      // than one, as when a pack has sample projects with models of their
      // own, the user chooses, the folder with the most models ticked
      Sources := nil;
      SameFormat := nil;
      for var Item in Found do
        if SameText(Item.Format, Pick) then
          SameFormat := SameFormat + [Item];
      if Length(SameFormat) > 1 then
      begin
        PickCopy := Pick;
        if not ChooseModelFolders([Folder], SameFormat, PickCopy, ChosenFolders,
          Format('%s has %s models in %d folders. Tick the ones to import; the one with ' +
          'the most models is ticked, as the others are often sample projects or copies. ' +
          'Skip passes over the pack.', [CollectionName, ModelFormatName(Pick),
          Length(SameFormat)]), True, 'Skip') then
        begin
          Log('Assets: ' + CollectionName + ': no folders chosen; passed over');
          Inc(NotChosen);
          Continue;
        end;
        for var Item in ChosenFolders do
        begin
          Source.Folder := Item.Folder;
          Source.Formats := [Item.Format];
          Sources := Sources + [Source];
        end;
        Log(Format('Assets: %s: %d of its %d %s folders chosen', [CollectionName,
          Length(ChosenFolders), Length(SameFormat), ModelFormatName(Pick)]));
      end
      else
      begin
        Ticks := DefaultModelFolders(Found, Pick);
        for var I := 0 to High(Found) do
          if Ticks[I] then
          begin
            Source.Folder := Found[I].Folder;
            Source.Formats := [Found[I].Format];
            Sources := Sources + [Source];
          end;
      end;
      Id := NewCollection(CollectionName, Sources, ArtistId);
      if Id = String.Empty then
        Continue;
      Inc(Added);
      NewIds := NewIds + [Id];
      if FirstId = String.Empty then
        FirstId := Id;
    end;
  finally
    CollectionBar.Enabled := True;
    ArtistBar.Enabled := True;
  end;
  if Length(Defaults) > 0 then
  begin
    FLibrary.PreferredFormat := Defaults[0];
    SaveLibrary;
  end;
  FBulkSummary := Format('%d collections added.%s%s%s%s%s', [Added,
    IfThen(Existing > 0, Format(' %d were in the library already.', [Existing]), ''),
    IfThen(NoModels > 0, Format(' %d had no models.', [NoModels]), ''),
    IfThen(NoFormat > 0, Format(' %d had none of the formats chosen.', [NoFormat]), ''),
    IfThen(NotChosen > 0, Format(' %d were skipped when choosing their folders.',
    [NotChosen]), ''),
    IfThen(Stopped, ' Stopped before the end.', '')]);
  // Each imported in full now, one after another: folders read, thumbnails
  // made; the first is shown at the end
  FillCollections;
  if Length(NewIds) = 0 then
  begin
    TDialogService.ShowMessage(FBulkSummary);
    FBulkSummary := String.Empty;
    Exit;
  end;
  StartJob('import', 'Artist import: ' + Title, NewIds, FirstId, FBulkSummary, False, 0);
end;

procedure TAssetsForm.NextBulk;
var
  Id, Done: String;
  Probe: TSprite3DAssetCollection;
begin
  while Length(FBulkQueue) > 0 do
  begin
    Id := FBulkQueue[0];
    Delete(FBulkQueue, 0, 1);
    // One that cannot be read would never finish: passed over
    if LoadAssetCollection(FCacheFolder, Id, Probe) then
    begin
      FBulkCurrent := Id;
      SaveJob;
      OpenCollection(Id, FBulkRescan, FBulkRemakeBefore);
      Exit;
    end;
    LogError('Assets: can''t read the collection ' + Id + '; passed over');
  end;
  // All done
  if FBulkTotal = 0 then
    Exit;
  FBulkTotal := 0;
  FBulkCurrent := String.Empty;
  ClearJob;
  UpdateJobButtons;
  if FJobKind = 'collection' then
  begin
    // One collection's thumbnails: it is open already
    Log('Assets: every thumbnail of ' + FCollection.Name + ' made');
    FJobKind := String.Empty;
    FBulkRemakeBefore := 0;
    ShowPreview(FSelected);
    Exit;
  end;
  if FJobKind = 'remake' then
    Done := 'rescanned, every thumbnail made again'
  else if FJobKind = 'rescan' then
    Done := 'rescanned'
  else
    Done := 'imported';
  Log('Assets: ' + FJobTitle + ': collections ' + Done);
  FJobKind := String.Empty;
  FBulkRescan := False;
  FBulkRemakeBefore := 0;
  if FRunErrors > 0 then
    FBulkSummary := FBulkSummary + Format(' %s, listed in %s.',
      [CountText(FRunErrors, 'error'), ErrorLogFile])
  else
    FBulkSummary := FBulkSummary + ' No errors.';
  AppendErrorLog(Format('--- %s', [CountText(FRunErrors, 'error')]));
  if FBulkFirst <> String.Empty then
    OpenCollection(FBulkFirst);
  FBulkFirst := String.Empty;
  if FBulkSummary <> String.Empty then
    TDialogService.ShowMessage(FBulkSummary);
  FBulkSummary := String.Empty;
end;

function TAssetsForm.BulkPrefix: String;
begin
  if FBulkTotal > 0 then
    Result := Format('Collection %d of %d, %s: ', [FBulkTotal - Length(FBulkQueue),
      FBulkTotal, FCollection.Name])
  else
    Result := String.Empty;
end;

procedure TAssetsForm.StopBulk(const AWhy: String);
begin
  if (FBulkTotal = 0) and not FJobPaused then
    Exit;
  if FJobPaused then
    Log(Format('Assets: paused job dropped (%s): %s', [AWhy, FJobTitle]))
  else
    Log(Format('Assets: %s stopped (%s); %d collections not done will be as each is ' +
      'opened', [FJobTitle, AWhy, Length(FBulkQueue) + Ord(FBulkCurrent <> String.Empty)]));
  AppendErrorLog(Format('--- stopped (%s); %s so far', [AWhy,
    CountText(FRunErrors, 'error')]));
  ClearJob;
  FJobPaused := False;
  FPausedLeft := 0;
  FJobKind := String.Empty;
  FJobTitle := String.Empty;
  FBulkRescan := False;
  FBulkRemakeBefore := 0;
  FBulkCurrent := String.Empty;
  FBulkQueue := nil;
  FBulkTotal := 0;
  FBulkFirst := String.Empty;
  FBulkSummary := String.Empty;
  FBulkPending := False;
  UpdateJobButtons;
end;

procedure TAssetsForm.PauseJob(const AWhy: String);
begin
  if FBulkTotal = 0 then
    Exit;
  // Saved at every step already, the collection it was on among it
  SaveJob;
  FPausedLeft := Length(FBulkQueue) + Ord(FBulkCurrent <> String.Empty);
  Log(Format('Assets: %s paused (%s), %s left; Resume Scan carries on', [FJobTitle, AWhy,
    CountText(FPausedLeft, 'collection')]));
  AppendErrorLog(Format('--- paused (%s); %s so far', [AWhy,
    CountText(FRunErrors, 'error')]));
  StopMaking;
  FBulkTotal := 0;
  FBulkPending := False;
  FJobPaused := True;
  Progress.Visible := False;
  StatusLabel.Text := PausedText;
  UpdateJobButtons;
end;

procedure TAssetsForm.LeaveJob(const AWhy: String);
begin
  if FBulkTotal = 0 then
    Exit;
  if FJobKind = 'collection' then
    StopBulk(AWhy)
  else
    PauseJob(AWhy);
end;

procedure TAssetsForm.ResumeButtonClick(Sender: TObject);
begin
  if not FJobPaused then
    Exit;
  // As it was saved, the collection it was on first
  if not LoadJob then
  begin
    FJobPaused := False;
    UpdateJobButtons;
    StatusLabel.Text := 'Nothing left to resume';
    Exit;
  end;
  FJobPaused := False;
  FBulkTotal := Length(FBulkQueue);
  DebugLog('Resumed: ' + FJobTitle + '; program built ' + BuildTimeText);
  AppendErrorLog('--- Resumed: ' + FJobTitle);
  Log(Format('Assets: %s resumed, %s left', [FJobTitle,
    CountText(Length(FBulkQueue), 'collection')]));
  UpdateJobButtons;
  NextBulk;
end;

procedure TAssetsForm.AbortButtonClick(Sender: TObject);
begin
  if (FBulkTotal = 0) and not FJobPaused then
    Exit;
  StopMaking;
  StopBulk('aborted');
  Progress.Visible := False;
  StatusLabel.Text := Format('%d models; scan aborted', [Length(FEntries)]);
end;

procedure TAssetsForm.UpdateJobButtons;
begin
  if FResumeButton <> nil then
    FResumeButton.Visible := FJobPaused;
  if FAbortButton <> nil then
    FAbortButton.Visible := FJobPaused or (FBulkTotal > 0);
end;

function TAssetsForm.PausedText: String;
begin
  Result := Format('Paused: %s, %s left. Resume Scan carries on; Abort Scan drops it.',
    [FJobTitle, CountText(FPausedLeft, 'collection')]);
end;

function TAssetsForm.JobFile: String;
begin
  Result := TPath.Combine(ExtractFileDir(AssetDatabaseFile(FCacheFolder)), JOB_FILE_NAME);
end;

procedure TAssetsForm.SaveJob;
var
  Root: TJSONObject;
  Queue: TJSONArray;
  Temp: String;
begin
  Root := TJSONObject.Create;
  try
    Root.AddPair('format', JOB_FILE_FORMAT);
    Root.AddPair('version', TJSONNumber.Create(1));
    Root.AddPair('kind', FJobKind);
    Root.AddPair('title', FJobTitle);
    Root.AddPair('current', FBulkCurrent);
    Queue := TJSONArray.Create;
    for var Id in FBulkQueue do
      Queue.Add(Id);
    Root.AddPair('queue', Queue);
    Root.AddPair('first', FBulkFirst);
    Root.AddPair('summary', FBulkSummary);
    Root.AddPair('errors', TJSONNumber.Create(FRunErrors));
    Root.AddPair('rescan', TJSONBool.Create(FBulkRescan));
    if FBulkRemakeBefore > 0 then
      Root.AddPair('remakeBefore', DateToISO8601(FBulkRemakeBefore, False))
    else
      Root.AddPair('remakeBefore', String.Empty);
    try
      // Written whole, then moved into place
      Temp := OSFriendlyPath(JobFile) + '.tmp';
      TFile.WriteAllText(Temp, JsonToText(Root), TEncoding.UTF8);
      if TFile.Exists(OSFriendlyPath(JobFile)) then
        TFile.Delete(OSFriendlyPath(JobFile));
      TFile.Move(Temp, OSFriendlyPath(JobFile));
    except
      on E: Exception do
        LogError('Assets: can''t save the job to ' + JobFile + ': ' + E.Message);
    end;
  finally
    Root.Free;
  end;
end;

procedure TAssetsForm.ClearJob;
begin
  try
    if TFile.Exists(OSFriendlyPath(JobFile)) then
      TFile.Delete(OSFriendlyPath(JobFile));
  except
    on E: Exception do
      LogError('Assets: can''t delete ' + JobFile + ': ' + E.Message);
  end;
end;

function TAssetsForm.LoadJob: Boolean;
var
  Root, Value: TJSONValue;
  JobText, FormatName, Current, Remake: String;
  Ids: TArray<String>;
  Errors: Integer;
  Rescan: Boolean;

  function Known(const AId: String): Boolean;
  begin
    Result := False;
    for var Entry in FLibrary.Collections do
      if SameText(Entry.Id, AId) then
        Exit(True);
  end;

begin
  Result := False;
  if not TFile.Exists(OSFriendlyPath(JobFile)) then
    Exit;
  Root := nil;
  try
    try
      JobText := TFile.ReadAllText(OSFriendlyPath(JobFile), TEncoding.UTF8);
      Root := TJSONObject.ParseJSONValue(JobText);
      if not (Root is TJSONObject) or
        not TJSONObject(Root).TryGetValue<String>('format', FormatName) or
        (FormatName <> JOB_FILE_FORMAT) then
        raise Exception.Create('not a job file');
      Ids := nil;
      if TJSONObject(Root).TryGetValue<String>('current', Current) and (Current <> '') and
        Known(Current) then
        Ids := [Current];
      Value := TJSONObject(Root).GetValue('queue');
      if Value is TJSONArray then
        for var Item in TJSONArray(Value) do
          if (Item is TJSONString) and Known(TJSONString(Item).Value) and
            (IndexText(TJSONString(Item).Value, Ids) < 0) then
            Ids := Ids + [TJSONString(Item).Value];
      if Length(Ids) = 0 then
      begin
        Log('Assets: the saved job has no collections left; dropped');
        ClearJob;
        Exit;
      end;
      if not TJSONObject(Root).TryGetValue<String>('kind', FJobKind) then
        FJobKind := 'import';
      if not TJSONObject(Root).TryGetValue<String>('title', FJobTitle) then
        FJobTitle := 'Scan';
      if not TJSONObject(Root).TryGetValue<String>('first', FBulkFirst) then
        FBulkFirst := String.Empty;
      if not TJSONObject(Root).TryGetValue<String>('summary', FBulkSummary) then
        FBulkSummary := String.Empty;
      if TJSONObject(Root).TryGetValue<Integer>('errors', Errors) and (Errors >= 0) then
        FRunErrors := Errors;
      if TJSONObject(Root).TryGetValue<Boolean>('rescan', Rescan) then
        FBulkRescan := Rescan
      else
        FBulkRescan := False;
      FBulkRemakeBefore := 0;
      if TJSONObject(Root).TryGetValue<String>('remakeBefore', Remake) and (Remake <> '') then
        FBulkRemakeBefore := ISO8601ToDate(Remake, False);
      FBulkQueue := Ids;
      FBulkCurrent := String.Empty;
      FPausedLeft := Length(Ids);
      FJobPaused := True;
      Result := True;
    except
      on E: Exception do
      begin
        LogError('Assets: can''t read the saved job ' + JobFile + ': ' + E.Message +
          '; dropped');
        ClearJob;
      end;
    end;
  finally
    Root.Free;
  end;
end;

procedure TAssetsForm.StartJob(const AKind, ATitle: String; const AIds: TArray<String>;
  const AFirst, ASummary: String; const ARescan: Boolean; const ARemakeBefore: TDateTime);
begin
  if FJobPaused then
    StopBulk('a new job started');
  FJobKind := AKind;
  FJobTitle := ATitle;
  FBulkQueue := AIds;
  FBulkTotal := Length(AIds);
  FBulkFirst := AFirst;
  FBulkSummary := ASummary;
  FBulkRescan := ARescan;
  FBulkRemakeBefore := ARemakeBefore;
  FBulkCurrent := String.Empty;
  FJobPaused := False;
  SaveJob;
  UpdateJobButtons;
  NextBulk;
end;

function TAssetsForm.MadeSinceRemake(const ACreated: String): Boolean;
begin
  if FRemakeBefore <= 0 then
    Exit(True);
  try
    Result := ISO8601ToDate(ACreated, False) >= FRemakeBefore;
  except
    Result := False;
  end;
end;

procedure TAssetsForm.DeleteCollectionItemClick(Sender: TObject);
begin
  if FCollection.Id = String.Empty then
    Exit;
  TDialogService.MessageDialog('Delete the collection ' + FCollection.Name +
    ' from the library? Its groups go with it, and the thumbnails of models no other ' +
    'collection has. The model files and folders are not touched.',
    TMsgDlgType.mtConfirmation, [TMsgDlgBtn.mbYes, TMsgDlgBtn.mbNo], TMsgDlgBtn.mbNo, 0,
    DeleteCollectionClosed);
end;

procedure TAssetsForm.DeleteCollectionClosed(Sender: TObject; const AResult: TModalResult);
var
  Id, NextId: String;
  ShownAt: Integer;
  Left: TArray<String>;
begin
  if (AResult <> mrYes) or (FCollection.Id = String.Empty) then
    Exit;
  Id := FCollection.Id;
  // Marked first: from here on the library no longer lists it, and if the
  // program stops before its thumbnails are gone, the delete is finished the
  // next time the Library opens
  if not MarkAssetCollectionDeleted(FCacheFolder, Id) then
  begin
    LogError('Assets: can''t delete the collection ' + FCollection.Name + ': the library ' +
      'could not be written');
    Exit;
  end;
  LeaveJob('a collection deleted');
  Log('Assets: collection ' + FCollection.Name + ' deleted');
  // Where it was among its artist's collections, as CollectionCombo lists
  // them, and the ones left, in the same order
  ShownAt := -1;
  Left := nil;
  for var I := 0 to High(FLibrary.Collections) do
    if SameText(FLibrary.Collections[I].ArtistId, FArtistId) then
    begin
      if SameText(FLibrary.Collections[I].Id, Id) then
        ShownAt := Length(Left)
      else
        Left := Left + [FLibrary.Collections[I].Id];
    end;
  for var I := High(FLibrary.Collections) downto 0 do
    if SameText(FLibrary.Collections[I].Id, Id) then
      Delete(FLibrary.Collections, I, 1);
  FCollection := Default(TSprite3DAssetCollection);
  FLibrary.Last := String.Empty;
  SaveLibrary;
  // The nearest of the artist's left: the one now in its place, or the one
  // before it if it was the last; none if it was their only one, the artist
  // still shown
  if Length(Left) = 0 then
    NextId := String.Empty
  else
    NextId := Left[Min(Max(ShownAt, 0), High(Left))];
  OpenCollection(NextId);
  StartPurge;
end;

procedure TAssetsForm.StartPurge;
var
  Keys: TArray<String>;
  Alive: IAssetsAlive;
  CacheFolder: String;
  Started: TDateTime;
begin
  if FPurging then
  begin
    FPurgeAgain := True;
    Exit;
  end;
  if not UsedAssetKeys(FCacheFolder, Keys) then
  begin
    LogError('Assets: can''t read which models the collections have; the cache is tidied ' +
      'the next time the Library opens');
    Exit;
  end;
  FPurging := True;
  FPurgeAgain := False;
  Log(Format('Assets: tidying the cache: the collections have %d models; every other ' +
    'thumbnail goes', [Length(Keys)]));
  // Only reading and deleting files: off the main thread. A thumbnail
  // written since this started, for a collection being opened or imported,
  // is left; so are the key folders, as one may be about to hold one
  Alive := FAlive;
  CacheFolder := FCacheFolder;
  Started := Now;
  TTask.Run(
    procedure
    var
      Used: TDictionary<String, Boolean>;
      Files: TArray<String>;
      Deleted, Failed, Kept: Integer;
      FirstError: String;
    begin
      Deleted := 0;
      Failed := 0;
      Kept := 0;
      FirstError := String.Empty;
      Used := TDictionary<String, Boolean>.Create;
      try
        for var Key in Keys do
          Used.AddOrSetValue(LowerCase(Key), True);
        Files := AssetThumbnailFiles(CacheFolder);
        for var FileName in Files do
          try
            if Used.ContainsKey(LowerCase(TPath.GetFileNameWithoutExtension(FileName))) then
              Inc(Kept)
            else if TFile.GetLastWriteTime(FileName) < Started then
            begin
              TFile.Delete(FileName);
              Inc(Deleted);
            end;
          except
            on E: Exception do
            begin
              Inc(Failed);
              if FirstError = String.Empty then
                FirstError := FileName + ': ' + E.Message;
            end;
          end;
      finally
        Used.Free;
      end;
      TThread.Queue(nil,
        procedure
        begin
          if Alive.Alive then
          begin
            Log(Format('Assets: %d thumbnails in the cache: %d in use, %d deleted',
              [Length(Files), Kept, Deleted]));
            PurgeFilesDone(Deleted, Failed, FirstError);
          end;
        end);
    end);
end;

procedure TAssetsForm.PurgeFilesDone(const ADeleted, AFailed: Integer;
  const AFirstError: String);
var
  Collections, Models: Integer;
  Before, After: Int64;
  Error: String;

  //** @abstract(A size in bytes as the log gives it: KB or MB.)
  function SizeText(const ABytes: Int64): String;
  begin
    if ABytes >= 1024 * 1024 then
      Result := FormatFloat('0.0', ABytes / (1024 * 1024)) + ' MB'
    else
      Result := FormatFloat('0', ABytes / 1024) + ' KB';
  end;

begin
  FPurging := False;
  if FPurgeAgain then
  begin
    // Another delete came while this one ran: started again, so its
    // collections' thumbnails go before their records do
    Log('Assets: tidying again, for the delete since');
    StartPurge;
    Exit;
  end;
  if AFailed > 0 then
    LogError(Format('Assets: %d thumbnails could not be deleted (first: %s); tried again ' +
      'the next time the Library opens', [AFailed, AFirstError]));
  if PurgeDeletedAssets(FCacheFolder, Collections, Models) then
    Log(Format('Assets: cache tidied: %d thumbnails deleted, the records of %d deleted ' +
      'collections, and the metadata of %d models no collection has', [ADeleted,
      Collections, Models]))
  else
  begin
    LogError(Format('Assets: %d thumbnails deleted, but the records could not be; tried ' +
      'again the next time the Library opens', [ADeleted]));
    Exit;
  end;
  // SQLite keeps the space deleted records leave, for reuse: given back
  if CompactAssetDatabase(FCacheFolder, Before, After, Error) then
    Log(Format('Assets: database compacted from %s to %s', [SizeText(Before),
      SizeText(After)]))
  else if Error <> String.Empty then
    LogError('Assets: can''t compact the database: ' + Error);
end;

procedure TAssetsForm.ScanSuspectItemClick(Sender: TObject);
var
  Verdicts: TArray<TSprite3DModelVerdict>;
  BadKeys: TDictionary<String, Boolean>;
  Models: TArray<TSuspectModel>;
  Model: TSuspectModel;
  Unsized: Integer;
  Summary: String;
begin
  if FCollection.Id = String.Empty then
    Exit;
  if not LoadModelVerdicts(FCacheFolder, FCollection.Id, Verdicts) then
    LogError('Assets: can''t read the verdicts on ' + FCollection.Name + '; every model ' +
      'is shown as good');
  BadKeys := TDictionary<String, Boolean>.Create;
  try
    for var Verdict in Verdicts do
      BadKeys.AddOrSetValue(Verdict.Key, Verdict.Bad);
    // Only a model with a thumbnail has its size in its metadata
    Models := nil;
    Unsized := 0;
    for var I := 0 to High(FEntries) do
    begin
      if not FEntries[I].HasThumbnail then
      begin
        Inc(Unsized);
        Continue;
      end;
      Model.Index := I;
      Model.Name := FEntries[I].Meta.Name;
      Model.Size := FEntries[I].Meta.Size;
      if not BadKeys.TryGetValue(LowerCase(FEntries[I].Meta.Hash), Model.Bad) then
        Model.Bad := False;
      Models := Models + [Model];
    end;
  finally
    BadKeys.Free;
  end;
  Log(Format('Assets: scanning %s for suspect models: %d with a size, %d without (no ' +
    'thumbnail yet)', [FCollection.Name, Length(Models), Unsized]));
  TSuspectModelsForm.Execute(Self, FCollection.Name, Models, Unsized, SuspectShow,
    SuspectVerdict, Summary);
  Log('Assets: suspect models of ' + FCollection.Name + ': ' + Summary);
end;

procedure TAssetsForm.SuspectShow(const AIndex: Integer);
var
  Tile: TRectangle;
  Top, Limit: Single;
begin
  if (AIndex < 0) or (AIndex > High(FEntries)) then
    Exit;
  // Its group shown, so its tile is there to be seen picked
  if not SameText(FEntries[AIndex].Meta.Group, FGroup) then
    ShowGroup(FEntries[AIndex].Meta.Group);
  SelectEntry(AIndex);
  Tile := FEntries[AIndex].Tile;
  if (Tile <> nil) and Tile.Visible then
  begin
    Top := TilesBox.Content.AbsoluteToLocal(Tile.LocalToAbsolute(TPointF.Zero)).Y;
    if (Top < TilesBox.ViewportPosition.Y) or
      (Top + Tile.Height > TilesBox.ViewportPosition.Y + TilesBox.Height) then
    begin
      Limit := Max(0, TilesBox.ContentBounds.Height - TilesBox.Height);
      TilesBox.ViewportPosition := TPointF.Create(TilesBox.ViewportPosition.X,
        EnsureRange(Top - 8, 0, Limit));
    end;
  end;
end;

function TAssetsForm.SuspectVerdict(const AIndex: Integer; const ABad: Boolean): Boolean;
const
  WORDS: array[Boolean] of String = ('good', 'bad');
begin
  Result := False;
  if (AIndex < 0) or (AIndex > High(FEntries)) or (FCollection.Id = String.Empty) then
    Exit;
  try
    SaveModelVerdict(FCacheFolder, FCollection.Id, FEntries[AIndex].Meta.Hash, ABad);
    Log('Assets: ' + FEntries[AIndex].Meta.Name + ' marked ' + WORDS[ABad]);
    Result := True;
  except
    on E: Exception do
      LogError('Assets: can''t record ' + FEntries[AIndex].Meta.Name + ' as ' +
        WORDS[ABad] + ': ' + E.Message);
  end;
end;


procedure TAssetsForm.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  if Length(FQueue) > 0 then
    Log(Format('Assets: stopped with %d thumbnails still to make; open the collection ' +
      'again to carry on', [Length(FQueue) + Ord(FMaking >= 0)]));
  PauseJob('the Library closed');
  StopMaking;
  Action := TCloseAction.caHide;
end;

procedure TAssetsForm.Log(const AText: String);
begin
  if Assigned(FOnLog) then
    FOnLog(AText);
  DebugLog(AText);
end;

procedure TAssetsForm.DebugLog(const AText: String);
begin
  try
    TFile.AppendAllText(OSFriendlyPath(ImportLogFile), FormatDateTime(LOG_TIME_FORMAT,
      Now) + ' ' + AText + sLineBreak, TEncoding.UTF8);
  except
    // A log that can't be written is no reason to stop
  end;
end;

procedure TAssetsForm.LogError(const AText: String);
var
  Line, Where: String;
  At: Integer;
begin
  Log(AText);
  Inc(FRunErrors);
  Line := AText;
  if Line.StartsWith('Assets: ') then
    Line := Line.Substring(Length('Assets: '));
  // Which collection it was in, as the log holds every collection's
  Where := String.Empty;
  if FCollection.Id <> String.Empty then
  begin
    Where := FCollection.Name;
    At := ArtistIndex(FCollection.ArtistId);
    if At >= 0 then
      Where := FLibrary.Artists[At].Name + ' / ' + Where;
  end;
  if Where <> String.Empty then
    Line := '[' + Where + '] ' + Line;
  AppendErrorLog(Line);
end;

procedure TAssetsForm.StartImportLog(const AHeader: String);
begin
  try
    if FileExists(OSFriendlyPath(ImportLogFile)) then
      TFile.Delete(OSFriendlyPath(ImportLogFile));
  except
    // Added to instead
  end;
  DebugLog(AHeader + '; program built ' + BuildTimeText);
  AppendErrorLog('--- ' + AHeader);
end;

class procedure TAssetsForm.BeginErrorLog;
begin
  try
    ForceDirectories(ExtractFileDir(OSFriendlyPath(ErrorLogFile)));
    TFile.WriteAllText(OSFriendlyPath(ErrorLogFile), FormatDateTime(LOG_TIME_FORMAT, Now) +
      ' Program started; built ' + BuildTimeText + sLineBreak, TEncoding.UTF8);
  except
    // A log that can't be written is no reason to stop
  end;
end;

class function TAssetsForm.ErrorLogFile: String;
begin
  Result := TPath.Combine(ExtractFileDir(AssetDatabaseFile(
    TSprite3DAppSettings.ThumbnailFolder)), ERROR_LOG_FILE_NAME);
end;

function TAssetsForm.ImportLogFile: String;
begin
  Result := TPath.Combine(ExtractFileDir(AssetDatabaseFile(FCacheFolder)),
    IMPORT_LOG_FILE_NAME);
end;

function TAssetsForm.LoadingFile: String;
begin
  Result := TPath.Combine(ExtractFileDir(AssetDatabaseFile(FCacheFolder)),
    LOADING_FILE_NAME);
end;

function TAssetsForm.SkipFile: String;
begin
  Result := TPath.Combine(ExtractFileDir(AssetDatabaseFile(FCacheFolder)), SKIP_FILE_NAME);
end;

procedure TAssetsForm.LoadSkipped;
var
  Hung: String;
begin
  if FSkipped = nil then
    Exit;
  FSkipped.Clear;
  try
    if FileExists(OSFriendlyPath(SkipFile)) then
      for var Line in TFile.ReadAllLines(OSFriendlyPath(SkipFile), TEncoding.UTF8) do
        if Trim(Line) <> String.Empty then
          FSkipped.Add(Trim(Line));
    // The program stopped, without closing, with this model in the viewport
    if FileExists(OSFriendlyPath(LoadingFile)) then
    begin
      Hung := Trim(TFile.ReadAllText(OSFriendlyPath(LoadingFile), TEncoding.UTF8));
      TFile.Delete(OSFriendlyPath(LoadingFile));
      if Hung <> String.Empty then
      begin
        FSkipped.Add(Hung);
        TFile.WriteAllLines(OSFriendlyPath(SkipFile), FSkipped.ToStringArray,
          TEncoding.UTF8);
        LogError('Assets: the program stopped last time with ' + Hung + ' loading or shown; ' +
          'it is passed over from now on (take it out of ' + SkipFile + ' to try it again)');
      end;
    end;
  except
    on E: Exception do
      LogError('Assets: can''t read the models passed over: ' + E.Message);
  end;
  if FSkipped.Count > 0 then
    Log(Format('Assets: %d models passed over, listed in %s', [FSkipped.Count, SkipFile]));
end;

function TAssetsForm.IsSkipped(const AFile: String): Boolean;
begin
  Result := (FSkipped <> nil) and (FSkipped.IndexOf(AFile) >= 0);
end;

function TAssetsForm.Making: Boolean;
begin
  Result := (FMaking >= 0) or (Length(FQueue) > 0);
end;

class function TAssetsForm.ThumbnailCheckFile: String;
begin
  Result := TPath.Combine(ExtractFileDir(AssetDatabaseFile(
    TSprite3DAppSettings.ThumbnailFolder)), THUMBNAIL_CHECK_FILE_NAME);
end;

procedure TAssetsForm.CheckThumbnails;
const
  VERDICT_NAMES: array[TThumbnailVerdict] of String = ('MISSING', 'EMPTY', 'NEARLY EMPTY',
    'library', 'good');
var
  Checks: TArray<TThumbnailCheck>;
  Check: TThumbnailCheck;
  Collection: TSprite3DAssetCollection;
  Measured: TDictionary<String, TThumbnailCheck>;
  Bitmap: TBitmap;
  Counts: array[TThumbnailVerdict] of Integer;
  Lines: TArray<String>;
  Where, Thumb: String;
  At, Done: Integer;
  Watch: TStopwatch;
  Meta: TSprite3DAssetMeta;
  Kind: TSprite3DModelKind;
begin
  if FChecking then
    Exit;
  FChecking := True;
  try
    LoadLibrary;
    Watch := TStopwatch.StartNew;
    Log('Assets: checking every thumbnail...');
    for var V := Low(TThumbnailVerdict) to High(TThumbnailVerdict) do
      Counts[V] := 0;
    Checks := nil;
    Done := 0;
    // A model in more than one collection is measured once
    Measured := TDictionary<String, TThumbnailCheck>.Create;
    Bitmap := TBitmap.Create;
    try
      for var Entry in FLibrary.Collections do
      begin
        if not LoadAssetCollection(FCacheFolder, Entry.Id, Collection) then
        begin
          LogError('Assets: thumbnail check: can''t read the collection ' + Entry.Name);
          Continue;
        end;
        Where := Entry.Name;
        At := ArtistIndex(Entry.ArtistId);
        if At >= 0 then
          Where := FLibrary.Artists[At].Name + ' / ' + Where;
        for var Model in Collection.Models do
        begin
          if not Measured.TryGetValue(Model.Key, Check) then
          begin
            Check := Default(TThumbnailCheck);
            Thumb := AssetThumbnailFile(FCacheFolder, Model.Key);
            Check.Verdict := tvMissing;
            if TFile.Exists(Thumb) then
              try
                Bitmap.LoadFromFile(Thumb);
                if MeasureVisible(Bitmap, Check.Visible, Check.MaxAlpha) then
                  if Check.Visible = 0 then
                    Check.Verdict := tvEmpty
                  else if Check.Visible < CHECK_NEARLY_EMPTY then
                    Check.Verdict := tvNearlyEmpty
                  else
                    Check.Verdict := tvGood;
              except
                // Unreadable: counts as missing
              end;
            // An animation library has little or nothing to draw: not a problem
            if LoadAssetMeta(FCacheFolder, Model.Key, Meta) then
            begin
              Kind := ModelKindFromKey(Meta.Kind);
              Check.Kind := ModelKindName(Kind);
              if (Kind = mkAnimationLibrary) and (Check.Verdict <> tvMissing) then
                Check.Verdict := tvLibrary;
            end
            else
              Check.Kind := ModelKindName(mkUnknown);
            Measured.Add(Model.Key, Check);
          end;
          Check.Text := Format('%s  %s  %s', [Where,
            ChangeFileExt(ExtractFileName(Model.FileName), ''), Model.FileName]);
          Inc(Counts[Check.Verdict]);
          if not (Check.Verdict in [tvGood, tvLibrary]) then
            Checks := Checks + [Check];
          Inc(Done);
          // Kept responsive: thousands of thumbnails take a few seconds
          if Done mod 50 = 0 then
            Application.ProcessMessages;
        end;
      end;
    finally
      Bitmap.Free;
      Measured.Free;
    end;

    // Worst first: missing, empty, then the emptiest of the nearly empty
    TArray.Sort<TThumbnailCheck>(Checks, TComparer<TThumbnailCheck>.Construct(
      function(const A, B: TThumbnailCheck): Integer
      begin
        Result := Ord(A.Verdict) - Ord(B.Verdict);
        if Result = 0 then
          Result := CompareValue(A.Visible, B.Visible);
        if Result = 0 then
          Result := CompareText(A.Text, B.Text);
      end));
    Lines := [Format('Thumbnail check, %s: %d models; %d missing, %d empty, %d nearly ' +
      'empty (under %.1f%% visible), %d animation libraries (not listed), %d good. ' +
      'Visible means alpha %d or more.',
      [FormatDateTime('yyyy-mm-dd hh:nn:ss', Now), Done, Counts[tvMissing], Counts[tvEmpty],
      Counts[tvNearlyEmpty], CHECK_NEARLY_EMPTY * 100, Counts[tvLibrary], Counts[tvGood],
      CHECK_VISIBLE_ALPHA]),
      'Verdict, share visible, highest alpha, kind, artist / collection, model, file. ' +
      'A kind "Not known yet" is that of a model whose thumbnail was made before kinds ' +
      'were kept: remake its thumbnails, or preview it, to know it.', ''];
    for var Each in Checks do
      Lines := Lines + [Format('%-12s %7.3f%%  alpha %3d  %-19s  %s',
        [VERDICT_NAMES[Each.Verdict], Each.Visible * 100, Each.MaxAlpha, Each.Kind,
        Each.Text])];
    try
      TFile.WriteAllLines(OSFriendlyPath(ThumbnailCheckFile), Lines, TEncoding.UTF8);
    except
      on E: Exception do
        LogError('Assets: can''t write ' + ThumbnailCheckFile + ': ' + E.Message);
    end;
    Log(Format('Assets: thumbnail check of %d models in %s: %d missing, %d empty, %d ' +
      'nearly empty, %d animation libraries, %d good; listed in %s', [Done,
      DurationText(Watch.Elapsed.TotalSeconds), Counts[tvMissing], Counts[tvEmpty],
      Counts[tvNearlyEmpty], Counts[tvLibrary], Counts[tvGood], ThumbnailCheckFile]));
  finally
    FChecking := False;
  end;
end;

procedure TAssetsForm.ClearLibrary;
var
  Error, Folder, Preferred: String;
begin
  // Kept: where the user looks for models, and the format they like
  LoadLibrary;
  Folder := FLibrary.LastFolder;
  Preferred := FLibrary.PreferredFormat;
  StopBulk('the library cleared');
  StopMaking;
  Inc(FScanId);   // drops hashing still under way
  if ClearAssetLibrary(FCacheFolder, Error) then
    Log('Assets: the library, its collections and every thumbnail deleted')
  else
    LogError('Assets: the library is cleared, but some could not be deleted: ' + Error);
  // Empty from here on; nothing of before it to move in
  FLibrary := Default(TSprite3DAssetLibrary);
  FLibrary.LastFolder := Folder;
  FLibrary.PreferredFormat := Preferred;
  FLibraryLoaded := True;
  SaveLibrary;
  FArtistId := String.Empty;
  FIconBitmaps.Clear;
  OpenCollection(String.Empty);
end;

procedure TAssetsForm.ScanCollection;
var
  Files: TArray<String>;
  ScanId: Integer;
  Alive: IAssetsAlive;
begin
  StopMaking;
  Inc(FScanId);
  if FCollection.Id = String.Empty then
    Exit;
  FScanning := True;
  Files := nil;
  for var Source in FCollection.Sources do
    if DirectoryExists(OSFriendlyPath(Source.Folder)) then
      Files := Files + AssetModelFilesOf(OSFriendlyPath(Source.Folder), Source.Formats)
    else
      LogError('Assets: the folder ' + Source.Folder + ' of ' + FCollection.Name +
        ' is not there');
  if Length(Files) = 0 then
  begin
    StatusLabel.Text := 'No models in the collection''s folders';
    LogError('Assets: no models in ' + SourcesText);
    // Still shown, with the groups it has
    HashesDone(FScanId, nil);
    Exit;
  end;
  StatusLabel.Text := BulkPrefix + Format('Reading %d models...', [Length(Files)]);
  Progress.Value := 0;
  Progress.Visible := True;
  Log(Format('Assets: %s, %d models in %s', [FCollection.Name, Length(Files),
    SourcesText]));

  // Only reading files: off the main thread. The results come back to the
  // main thread as one array, and are dropped if another folder has been
  // opened meanwhile or the form has gone
  ScanId := FScanId;
  Alive := FAlive;
  TTask.Run(
    procedure
    var
      Hasher: TSprite3DAssetHasher;
      Results: TArray<TAssetHashResult>;
    begin
      SetLength(Results, Length(Files));
      Hasher := TSprite3DAssetHasher.Create;
      try
        for var I := 0 to High(Files) do
        begin
          Results[I].FileName := Files[I];
          Results[I].Hash := Hasher.HashModel(Files[I], Results[I].Files,
            Results[I].Error);
        end;
      finally
        Hasher.Free;
      end;
      TThread.Queue(nil,
        procedure
        begin
          if Alive.Alive then
            HashesDone(ScanId, Results);
        end);
    end);
end;

procedure TAssetsForm.HashesDone(const AScanId: Integer;
  const AResults: TArray<TAssetHashResult>);
var
  RemakeBefore: TDateTime;
  AutoIndices: TArray<Integer>;
  AutoNames, AutoGroups: TArray<String>;
  Seen: TDictionary<String, String>;
  Entry: TAssetEntry;
  First, Chosen: String;
  Cached: Integer;
  NewGroups: TArray<String>;
  // Why the thumbnails not taken from the cache are made, for the Debug tab
  NoMeta, Remade, OldRules, OtherSize, NoFile: Integer;
  SizeSeen: String;
  // True if these results are from reading the collection's folders
  FromScan: Boolean;
begin
  if AScanId <> FScanId then
    Exit;   // another folder has been opened since
  FEntries := nil;
  FQueue := nil;
  Cached := 0;
  // The collection's palette as it is now: the groups, and every model's
  FPaletteGroups.Clear;
  FGroupIcons.Clear;
  FGroupParents.Clear;
  FGroupOrder := nil;
  for var Group in FCollection.Groups do
  begin
    FGroupOrder := FGroupOrder + [Group.Name];
    if Group.Icon <> String.Empty then
      FGroupIcons.AddOrSetValue(LowerCase(Group.Name), Group.Icon);
    if Group.Parent <> String.Empty then
      FGroupParents.AddOrSetValue(LowerCase(Group.Name), Group.Parent);
    for var Key in Group.Models do
      FPaletteGroups.AddOrSetValue(Key, Group.Name);
  end;
  // A parent that is not a group, or that would make a loop, is dropped:
  // that group goes to the top
  for var Key in FGroupParents.Keys.ToArray do
    if (GroupIndex(FGroupParents[Key]) < 0) or Holds(Key, FGroupParents[Key]) then
      FGroupParents.Remove(Key);
  NoMeta := 0;
  Remade := 0;
  OldRules := 0;
  OtherSize := 0;
  NoFile := 0;
  SizeSeen := String.Empty;
  Seen := TDictionary<String, String>.Create;
  try
    for var R in AResults do
    begin
      if R.Error <> String.Empty then
      begin
        LogError('Assets: can''t read ' + R.FileName + ': ' + R.Error);
        Continue;
      end;
      if Seen.TryGetValue(R.Hash, First) then
      begin
        Log(Format('Assets: %s is the same model as %s; shown once', [R.FileName, First]));
        Continue;
      end;
      Seen.Add(R.Hash, R.FileName);
      Entry := Default(TAssetEntry);
      Entry.HasThumbnail := LoadAssetMeta(FCacheFolder, R.Hash, Entry.Meta) and
        MadeSinceRemake(Entry.Meta.Created) and
        // Made by the texture rules there are now, or naming no textures
        // they ready: one made before textures could be found is made again
        ((Entry.Meta.Textures >= TEXTURE_RULES_VERSION) or
        not PreparesTextures(R.FileName)) and
        (Entry.Meta.ThumbWidth = THUMBNAIL_SIZE) and
        (Entry.Meta.ThumbHeight = THUMBNAIL_SIZE) and
        TFile.Exists(AssetThumbnailFile(FCacheFolder, R.Hash));
      if not Entry.HasThumbnail then
      begin
        // Why, for the Debug tab: the first reason that holds
        if not LoadAssetMeta(FCacheFolder, R.Hash, Entry.Meta) then
          Inc(NoMeta)
        else if not MadeSinceRemake(Entry.Meta.Created) then
          Inc(Remade)
        else if (Entry.Meta.Textures < TEXTURE_RULES_VERSION) and
          PreparesTextures(R.FileName) then
          Inc(OldRules)
        else if (Entry.Meta.ThumbWidth <> THUMBNAIL_SIZE) or
          (Entry.Meta.ThumbHeight <> THUMBNAIL_SIZE) then
        begin
          Inc(OtherSize);
          if SizeSeen = String.Empty then
            SizeSeen := Format('%d x %d', [Entry.Meta.ThumbWidth, Entry.Meta.ThumbHeight]);
        end
        else
          Inc(NoFile);
        Entry.Meta := Default(TSprite3DAssetMeta);
        Entry.Meta.Hash := R.Hash;
      end
      else
        Inc(Cached);
      // Where it is now, whatever the cache last saw
      Entry.Meta.Name := ChangeFileExt(ExtractFileName(R.FileName), '');
      Entry.GroupChosen := FPaletteGroups.TryGetValue(R.Hash, Chosen);
      // Not chosen: grouped with the others below
      if Entry.GroupChosen then
        Entry.Meta.Group := Chosen
      else
        Entry.Meta.Group := String.Empty;
      Entry.Meta.FileName := R.FileName;
      // A collection opened from its saved models knows only each file
      if R.Files <> nil then
        Entry.Meta.Files := R.Files;
      // Its material variants: read from its file once, then kept with its
      // metadata; placed as the base until its tile chooses another
      Entry.Variant := BASE_VARIANT;
      if not Entry.Meta.VariantsRead then
      begin
        Entry.Meta.Variants := ModelVariantNames(R.FileName);
        Entry.Meta.VariantsRead := True;
        if Entry.HasThumbnail then
          try
            SaveAssetMeta(FCacheFolder, Entry.Meta);
          except
            on E: Exception do
              LogError('Assets: can''t save the variants of ' + Entry.Meta.Name + ': ' +
                E.Message);
          end;
      end;
      FEntries := FEntries + [Entry];
    end;
  finally
    Seen.Free;
  end;
  // The models no group was chosen for: grouped as the collection's names
  // suit, first word or last, then plurals with singulars, then groups of
  // one in Unsorted
  AutoIndices := nil;
  AutoNames := nil;
  for var I := 0 to High(FEntries) do
    if not FEntries[I].GroupChosen then
    begin
      AutoIndices := AutoIndices + [I];
      AutoNames := AutoNames + [FEntries[I].Meta.Name];
    end;
  AutoGroups := AssetGroupNames(AutoNames);
  for var I := 0 to High(AutoIndices) do
    FEntries[AutoIndices[I]].Meta.Group := AutoGroups[I];
  MergePluralGroups;
  CollapseSmallGroups;
  // Every model in the palette, and every group new to it last, in
  // alphabetical order, so the palette holds the folder from now on
  NewGroups := nil;
  for var I := 0 to High(FEntries) do
  begin
    FPaletteGroups.AddOrSetValue(FEntries[I].Meta.Hash, FEntries[I].Meta.Group);
    FEntries[I].GroupChosen := True;
    if (GroupIndex(FEntries[I].Meta.Group) < 0) and
      (IndexText(FEntries[I].Meta.Group, NewGroups) < 0) then
      NewGroups := NewGroups + [FEntries[I].Meta.Group];
  end;
  TArray.Sort<String>(NewGroups, TComparer<String>.Construct(
    function(const A, B: String): Integer
    begin
      Result := CompareText(A, B);
    end));
  FGroupOrder := FGroupOrder + NewGroups;
  // From a scan, the models are now the folders' as they are
  FromScan := FScanning;
  if FScanning then
    FCollection.Scanned := True;
  FScanning := False;
  RemakeBefore := FRemakeBefore;
  FRemakeBefore := 0;
  SavePalette;
  // A scan saves the models as found now: a model whose files changed has a
  // new key, so the thumbnail and metadata of its old one are no
  // collection's any more. Tidied now, rather than left until the Library
  // next opens (owner, 13 November 2026: rescans had left 2,500). The
  // thumbnails this collection is about to make are written after the
  // tidy starts, and are its models', so they stay
  if FromScan then
    StartPurge;

  // Name order throughout, whatever the group: a move to another group
  // leaves every entry where it is
  TArray.Sort<TAssetEntry>(FEntries, TComparer<TAssetEntry>.Construct(
    function(const A, B: TAssetEntry): Integer
    begin
      Result := CompareText(A.Meta.Name, B.Meta.Name);
      if Result = 0 then
        Result := CompareText(A.Meta.FileName, B.Meta.FileName);
    end));
  for var I := 0 to High(FEntries) do
    if not FEntries[I].HasThumbnail then
      FQueue := FQueue + [I];
  FQueueTotal := Length(FQueue);
  FMadeCount := 0;
  // Timed from the first, for the time left
  FMakeWatch := TStopwatch.StartNew;

  BuildTiles;
  FGroup := String.Empty;
  BuildGroups;
  Log(Format('Assets: %d models shown, %d thumbnails from the cache, %d to make',
    [Length(FEntries), Cached, FQueueTotal]));
  if FQueueTotal > 0 then
    Log(Format('Assets: to make because: %d never made, %d made before the remake, %d made ' +
      'by older texture rules (now %d), %d not %d x %d%s, %d with no image file',
      [NoMeta, Remade, OldRules, TEXTURE_RULES_VERSION, OtherSize, THUMBNAIL_SIZE,
      THUMBNAIL_SIZE, IfThen(SizeSeen <> String.Empty, ' (such as ' + SizeSeen + ')', ''),
      NoFile]));
  // A job paused: nothing is made, the collection is only shown
  if FJobPaused then
  begin
    FQueue := nil;
    FQueueTotal := 0;
    Progress.Visible := False;
    StatusLabel.Text := PausedText;
    UpdateJobButtons;
    Exit;
  end;
  // Thumbnails to make with no job under way: a job of their own, so they
  // are resumed, not started again, if the Library is closed first
  if (FQueueTotal > 0) and (FBulkTotal = 0) then
  begin
    FJobKind := 'collection';
    FJobTitle := 'Thumbnails of ' + FCollection.Name;
    FBulkQueue := nil;
    FBulkTotal := 1;
    FBulkCurrent := FCollection.Id;
    FBulkFirst := String.Empty;
    FBulkSummary := String.Empty;
    FBulkRescan := False;
    FBulkRemakeBefore := RemakeBefore;
    SaveJob;
    UpdateJobButtons;
  end;
  MakeNext;
end;

procedure TAssetsForm.CollapseSmallGroups;
var
  Counts: TDictionary<String, Integer>;
  Count: Integer;
  Key: String;
begin
  Counts := TDictionary<String, Integer>.Create;
  try
    for var Entry in FEntries do
    begin
      Key := LowerCase(Entry.Meta.Group);
      if not Counts.TryGetValue(Key, Count) then
        Count := 0;
      Counts.AddOrSetValue(Key, Count + 1);
    end;
    for var I := 0 to High(FEntries) do
    begin
      if FEntries[I].GroupChosen then
        Continue;   // the user's choice stands
      // A group the palette has already stands too
      if GroupIndex(FEntries[I].Meta.Group) >= 0 then
        Continue;
      if Counts[LowerCase(FEntries[I].Meta.Group)] < MIN_GROUP_SIZE then
        FEntries[I].Meta.Group := UNSORTED_GROUP;
    end;
  finally
    Counts.Free;
  end;
end;

procedure TAssetsForm.MergePluralGroups;
var
  Groups: TDictionary<String, Boolean>;
  Group: String;
begin
  Groups := TDictionary<String, Boolean>.Create;
  try
    for var Entry in FEntries do
      Groups.AddOrSetValue(Entry.Meta.Group, True);
    for var GroupName in FGroupOrder do
      Groups.AddOrSetValue(GroupName, True);
    for var I := 0 to High(FEntries) do
    begin
      if FEntries[I].GroupChosen then
        Continue;   // the user's choice stands
      Group := FEntries[I].Meta.Group;
      if (Group.Length > 1) and Group.EndsWith('s') and
        Groups.ContainsKey(Group.Substring(0, Group.Length - 1)) then
        FEntries[I].Meta.Group := Group.Substring(0, Group.Length - 1);
    end;
  finally
    Groups.Free;
  end;
end;

procedure TAssetsForm.BuildGroups;
var
  Count, Chosen: Integer;
  Tile: TRectangle;
  Icon: TImage;
  Caption: TLabel;
  Bitmap: TBitmap;
begin
  FDropIndex := -1;
  // The top groups in the palette's order; another kit's are kept but not
  // shown
  FShownGroups := nil;
  for var GroupName in ChildGroups(String.Empty) do
    if GroupShown(GroupName) then
      FShownGroups := FShownGroups + [GroupName];

  GroupsBox.BeginUpdate;
  try
    for var Old in FGroupTiles do
      Old.Free;
    FGroupTiles := nil;
    Chosen := -1;
    for var I := 0 to High(FShownGroups) do
    begin
      Count := FolderTotal(FShownGroups[I]);
      Tile := TRectangle.Create(GroupsBox);
      Tile.Parent := GroupsBox;
      Tile.Align := TAlignLayout.Top;
      // Each below the last: Align Top places by Position
      Tile.Position.Y := I * (GROUP_TILE_HEIGHT + 4) + 1;
      Tile.Height := GROUP_TILE_HEIGHT;
      Tile.Margins.Rect := TRectF.Create(3, 2, 3, 2);
      Tile.XRadius := 4;
      Tile.YRadius := 4;
      Tile.Fill.Kind := TBrushKind.None;
      Tile.Stroke.Kind := TBrushKind.None;
      Tile.Tag := I;
      Tile.TagString := FShownGroups[I];
      Tile.AutoCapture := True;
      Tile.OnMouseDown := GroupTileMouseDown;
      Tile.OnMouseMove := GroupTileMouseMove;
      Tile.OnMouseUp := GroupTileMouseUp;

      Icon := TImage.Create(Tile);
      Icon.Parent := Tile;
      Icon.Align := TAlignLayout.Top;
      Icon.Height := GROUP_ICON_SIZE;
      Icon.Margins.Rect := TRectF.Create(0, 6, 0, 0);
      Icon.WrapMode := TImageWrapMode.Fit;
      Icon.HitTest := False;
      Bitmap := GroupIcon(FShownGroups[I]);
      if Bitmap <> nil then
        Icon.Bitmap.Assign(Bitmap);

      Caption := TLabel.Create(Tile);
      Caption.Parent := Tile;
      Caption.Align := TAlignLayout.Client;
      Caption.Margins.Rect := TRectF.Create(4, 0, 4, 2);
      Caption.StyledSettings := Caption.StyledSettings - [TStyledSetting.Size];
      Caption.TextSettings.Font.Size := GROUP_FONT_SIZE;
      Caption.TextSettings.HorzAlign := TTextAlign.Center;
      Caption.TextSettings.WordWrap := False;
      Caption.TextSettings.Trimming := TTextTrimming.Character;
      Caption.Text := Format('%s (%d)', [FShownGroups[I], Count]);
      Caption.HitTest := False;

      FGroupTiles := FGroupTiles + [Tile];
      if SameText(FShownGroups[I], RootOf(FGroup)) then
        Chosen := I;
    end;
  finally
    GroupsBox.EndUpdate;
  end;
  // The group shown stays if it is still there, its picks with it
  if (FGroup <> String.Empty) and (GroupIndex(FGroup) >= 0) and GroupShown(FGroup) and
    (Chosen >= 0) then
  begin
    FGroup := FGroupOrder[GroupIndex(FGroup)];
    BuildFolderTiles;
    LayoutTiles;
    UpdateGroupMarks;
    UpdatePath;
  end
  else if Length(FShownGroups) > 0 then
    ShowGroup(FShownGroups[0])
  else
    ShowGroup(String.Empty);
end;

procedure TAssetsForm.UpdateGroupMarks;
var
  Root: String;
begin
  Root := RootOf(FGroup);
  for var I := 0 to High(FGroupTiles) do
  begin
    if SameText(FShownGroups[I], Root) then
    begin
      FGroupTiles[I].Fill.Kind := TBrushKind.Solid;
      FGroupTiles[I].Fill.Color := GROUP_CHOSEN_FILL;
    end
    else
      FGroupTiles[I].Fill.Kind := TBrushKind.None;
    if I = FDropIndex then
    begin
      FGroupTiles[I].Stroke.Kind := TBrushKind.Solid;
      FGroupTiles[I].Stroke.Color := GROUP_DROP_STROKE;
      FGroupTiles[I].Stroke.Thickness := 2;
    end
    else
      FGroupTiles[I].Stroke.Kind := TBrushKind.None;
  end;
  for var I := 0 to High(FFolderTiles) do
    if I = FDropFolder then
    begin
      FFolderTiles[I].Stroke.Color := GROUP_DROP_STROKE;
      FFolderTiles[I].Stroke.Thickness := 2;
    end
    else
    begin
      FFolderTiles[I].Stroke.Color := TILE_STROKE;
      FFolderTiles[I].Stroke.Thickness := 1;
    end;
  if FDropInto then
  begin
    TilesPanel.Stroke.Kind := TBrushKind.Solid;
    TilesPanel.Stroke.Color := GROUP_DROP_STROKE;
    TilesPanel.Stroke.Thickness := 2;
  end
  else
    TilesPanel.Stroke.Kind := TBrushKind.None;
end;

function TAssetsForm.ParentOf(const AGroup: String): String;
begin
  if not FGroupParents.TryGetValue(LowerCase(AGroup), Result) then
    Result := String.Empty;
end;

function TAssetsForm.RootOf(const AGroup: String): String;
var
  Steps: Integer;
begin
  Result := AGroup;
  // Bounded, so a loop in a damaged palette cannot hang it
  Steps := Length(FGroupOrder);
  while (ParentOf(Result) <> String.Empty) and (Steps >= 0) do
  begin
    Result := ParentOf(Result);
    Dec(Steps);
  end;
end;

function TAssetsForm.Holds(const AOuter, AGroup: String): Boolean;
var
  Group: String;
  Steps: Integer;
begin
  Group := AGroup;
  Steps := Length(FGroupOrder);
  while (Group <> String.Empty) and (Steps >= 0) do
  begin
    if SameText(Group, AOuter) then
      Exit(True);
    Group := ParentOf(Group);
    Dec(Steps);
  end;
  Result := False;
end;

function TAssetsForm.ChildGroups(const AGroup: String): TArray<String>;
begin
  Result := nil;
  for var GroupName in FGroupOrder do
    if SameText(ParentOf(GroupName), AGroup) then
      Result := Result + [GroupName];
  // Alphabetical, case ignored, at every level
  TArray.Sort<String>(Result, TComparer<String>.Construct(
    function(const A, B: String): Integer
    begin
      Result := CompareText(A, B);
    end));
end;

function TAssetsForm.FolderTotal(const AGroup: String): Integer;
begin
  Result := 0;
  for var Entry in FEntries do
    if Holds(AGroup, Entry.Meta.Group) then
      Inc(Result);
end;

function TAssetsForm.GroupShown(const AGroup: String): Boolean;
begin
  // Models of this folder in it or below, or nothing anywhere: a new group
  Result := (FolderTotal(AGroup) > 0) or GroupEmpty(AGroup);
  if not Result then
    for var Child in ChildGroups(AGroup) do
      if GroupShown(Child) then
        Exit(True);
end;

function TAssetsForm.GroupEmpty(const AGroup: String): Boolean;
begin
  Result := (PaletteCount(AGroup) = 0) and (Length(ChildGroups(AGroup)) = 0);
end;

procedure TAssetsForm.Reparent(const AGroup, AParent: String);
var
  At: Integer;
  Group: String;
begin
  At := GroupIndex(AGroup);
  if At < 0 then
    Exit;
  Group := FGroupOrder[At];
  if AParent <> String.Empty then
  begin
    // Never into itself, or into a group inside it
    if (GroupIndex(AParent) < 0) or Holds(Group, AParent) or
      SameText(ParentOf(Group), AParent) then
      Exit;
    FGroupParents.AddOrSetValue(LowerCase(Group), FGroupOrder[GroupIndex(AParent)]);
    Log('Assets: group ' + Group + ' put inside ' + AParent);
  end
  else
  begin
    if ParentOf(Group) = String.Empty then
      Exit;
    FGroupParents.Remove(LowerCase(Group));
    Log('Assets: group ' + Group + ' moved to the top');
  end;
  SavePalette;
  BuildGroups;
end;

procedure TAssetsForm.BuildFolderTiles;
var
  Tile: TRectangle;
  Icon: TImage;
  Caption: TLabel;
  Bitmap: TBitmap;
begin
  FDropFolder := -1;
  for var Old in FFolderTiles do
    Old.Free;
  FFolderTiles := nil;
  FFolderNames := nil;
  if FGroup = String.Empty then
    Exit;
  for var GroupName in ChildGroups(FGroup) do
  begin
    if not GroupShown(GroupName) then
      Continue;
    Tile := TRectangle.Create(FTilesLayout);
    Tile.Parent := FTilesLayout;
    Tile.Width := TILE_WIDTH;
    Tile.Height := TILE_HEIGHT;
    Tile.XRadius := 4;
    Tile.YRadius := 4;
    // A group, not a model: a fill of its own
    Tile.Fill.Kind := TBrushKind.Solid;
    Tile.Fill.Color := FOLDER_FILL;
    Tile.Stroke.Color := TILE_STROKE;
    Tile.Tag := Length(FFolderNames);
    Tile.TagString := GroupName;
    Tile.Hint := GroupName + ': double-click to open';
    Tile.ShowHint := True;
    Tile.AutoCapture := True;
    Tile.OnMouseDown := FolderTileMouseDown;
    Tile.OnMouseMove := GroupTileMouseMove;
    Tile.OnMouseUp := GroupTileMouseUp;

    Icon := TImage.Create(Tile);
    Icon.Parent := Tile;
    Icon.Align := TAlignLayout.Top;
    // Inset from a thumbnail's box, the name below having the room it has
    Icon.Height := TILE_IMAGE - 20;
    Icon.Margins.Rect := TRectF.Create(20, 20, 20, 0);
    Icon.WrapMode := TImageWrapMode.Fit;
    Icon.HitTest := False;
    Bitmap := GroupIcon(GroupName);
    if Bitmap <> nil then
      Icon.Bitmap.Assign(Bitmap);

    Caption := TLabel.Create(Tile);
    Caption.Parent := Tile;
    Caption.Align := TAlignLayout.Client;
    Caption.Margins.Rect := TRectF.Create(2, 0, 2, 2);
    Caption.StyledSettings := Caption.StyledSettings - [TStyledSetting.Size,
      TStyledSetting.Style];
    Caption.TextSettings.Font.Size := 11;
    Caption.TextSettings.Font.Style := [TFontStyle.fsBold];
    Caption.TextSettings.HorzAlign := TTextAlign.Center;
    Caption.TextSettings.WordWrap := False;
    Caption.TextSettings.Trimming := TTextTrimming.Character;
    Caption.Text := Format('%s (%d)', [GroupName, FolderTotal(GroupName)]);
    Caption.HitTest := False;

    FFolderTiles := FFolderTiles + [Tile];
    FFolderNames := FFolderNames + [GroupName];
  end;
end;

function TAssetsForm.FolderTileAt(const AAbsolute: TPointF): Integer;
var
  At: TPointF;
begin
  Result := -1;
  if not OverTiles(AAbsolute) then
    Exit;
  for var I := 0 to High(FFolderTiles) do
  begin
    At := FFolderTiles[I].AbsoluteToLocal(AAbsolute);
    if (At.X >= 0) and (At.Y >= 0) and (At.X < FFolderTiles[I].Width) and
      (At.Y < FFolderTiles[I].Height) then
      Exit(I);
  end;
end;

function TAssetsForm.OverTiles(const AAbsolute: TPointF): Boolean;
var
  At: TPointF;
begin
  At := TilesPanel.AbsoluteToLocal(AAbsolute);
  Result := (At.X >= 0) and (At.Y >= 0) and (At.X <= TilesPanel.Width) and
    (At.Y <= TilesPanel.Height);
end;

procedure TAssetsForm.UpdatePath;
var
  Path, Group: String;
  Steps: Integer;
begin
  Path := FGroup;
  Group := ParentOf(FGroup);
  Steps := Length(FGroupOrder);
  while (Group <> String.Empty) and (Steps >= 0) do
  begin
    Path := Group + ' / ' + Path;
    Group := ParentOf(Group);
    Dec(Steps);
  end;
  PathLabel.Text := Path;
  UpButton.Enabled := ParentOf(FGroup) <> String.Empty;
end;

procedure TAssetsForm.UpdatePreviewLabel;
begin
  FPreviewLabel.Visible := FModel = nil;
  if FPreviewLabel.Visible then
    FPreviewLabel.BringToFront;
end;

procedure TAssetsForm.UpButtonClick(Sender: TObject);
begin
  if ParentOf(FGroup) <> String.Empty then
    ShowGroup(ParentOf(FGroup));
end;

procedure TAssetsForm.FolderTileMouseDown(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Single);
begin
  if not (Sender is TRectangle) or (Button <> TMouseButton.mbLeft) or
    (ssCtrl in Shift) then
    Exit;
  if ssDouble in Shift then
  begin
    // Opened once this handler has returned, as the tiles are made again
    FOpenGroup := TRectangle(Sender).TagString;
    Defer;
    Exit;
  end;
  FGroupDown := TRectangle(Sender).TagString;
  FGroupDownInGrid := True;
  FDownAt := TRectangle(Sender).LocalToAbsolute(TPointF.Create(X, Y));
  FDragging := False;
end;

procedure TAssetsForm.TrackGroupDrag(const At: TPointF);
var
  Index, Folder: Integer;
  Below, Into: Boolean;
begin
  // A button on the left: inside that group
  Index := GroupTileAt(At, Below);
  if (Index >= 0) and Holds(FGroupDown, FShownGroups[Index]) then
    Index := -1;
  Folder := FolderTileAt(At);
  if (Folder >= 0) and Holds(FGroupDown, FFolderNames[Folder]) then
    Folder := -1;
  // The grid's empty space: inside the group shown
  Into := (Folder < 0) and OverTiles(At) and not Holds(FGroupDown, FGroup) and
    not SameText(ParentOf(FGroupDown), FGroup);
  FDropBelow := Below and (ParentOf(FGroupDown) <> String.Empty);
  FDropFolder := Folder;
  FDropInto := Into;
  SetDropIndex(Index);
  UpdateGroupMarks;
end;

procedure TAssetsForm.DropGroup(const At: TPointF);
var
  Index, Folder: Integer;
  Below: Boolean;
  Group: String;
begin
  Group := FGroupDown;
  Index := GroupTileAt(At, Below);
  Folder := FolderTileAt(At);
  // Done once this handler has returned, as the buttons and tiles are made
  // again for it
  if Folder >= 0 then
  begin
    if not Holds(Group, FFolderNames[Folder]) then
    begin
      FReparentGroup := Group;
      FReparentTo := FFolderNames[Folder];
    end;
  end
  else if Index >= 0 then
  begin
    // Onto a button: inside that group
    if Holds(Group, FShownGroups[Index]) then
      Exit;
    FReparentGroup := Group;
    FReparentTo := FShownGroups[Index];
  end
  else if Below then
  begin
    // Below the buttons: back to the top
    if ParentOf(Group) = String.Empty then
      Exit;
    FReparentGroup := Group;
    FReparentTo := String.Empty;
  end
  else if OverTiles(At) and not Holds(Group, FGroup) and
    not SameText(ParentOf(Group), FGroup) then
  begin
    FReparentGroup := Group;
    FReparentTo := FGroup;
  end
  else
    Exit;
  Defer;
end;

function TAssetsForm.IconFile(const AName: String): String;
begin
  Result := String.Empty;
  if AName = String.Empty then
    Exit;
  for var Folder in TArray<String>.Create(TSprite3DAppSettings.UserGroupIconsFolder,
    GroupIconsFolder) do
    if (Folder <> String.Empty) and TFile.Exists(TPath.Combine(Folder, AName)) then
      Exit(TPath.Combine(Folder, AName));
end;

function TAssetsForm.GroupIcon(const AGroup: String): TBitmap;
var
  Chosen, FileName: String;
  Bitmap: TBitmap;
begin
  Result := nil;
  // The one chosen, or the library's of the group's name
  FileName := String.Empty;
  if FGroupIcons.TryGetValue(LowerCase(AGroup), Chosen) then
    FileName := IconFile(Chosen);
  if FileName = String.Empty then
    for var Ext in GROUP_ICON_EXTENSIONS do
    begin
      FileName := IconFile(LowerCase(AGroup) + Ext);
      if FileName <> String.Empty then
        Break;
    end;
  if FileName <> String.Empty then
  begin
    if FIconBitmaps.TryGetValue(FileName, Result) then
      Exit;
    Bitmap := LoadGroupIcon(FileName, GROUP_ICON_PIXELS, GROUP_ICON_COLOUR);
    if Bitmap <> nil then
    begin
      FIconBitmaps.AddOrSetValue(FileName, Bitmap);
      Exit(Bitmap);
    end;
    LogError('Assets: can''t read the icon ' + FileName);
  end;
  // Else its first model's thumbnail
  for var Entry in FEntries do
    if Holds(AGroup, Entry.Meta.Group) and Entry.HasThumbnail and
      (Entry.Image <> nil) and not Entry.Image.Bitmap.IsEmpty then
      Exit(Entry.Image.Bitmap);
end;

function TAssetsForm.GroupTileAt(const AAbsolute: TPointF; out ABelow: Boolean): Integer;
var
  At: TPointF;
begin
  Result := -1;
  ABelow := False;
  At := GroupsBox.AbsoluteToLocal(AAbsolute);
  if (At.X < 0) or (At.Y < 0) or (At.X > GroupsBox.Width) or (At.Y > GroupsBox.Height) then
    Exit;
  for var I := 0 to High(FGroupTiles) do
  begin
    At := FGroupTiles[I].AbsoluteToLocal(AAbsolute);
    if (At.Y >= -FGroupTiles[I].Margins.Top) and
      (At.Y < FGroupTiles[I].Height + FGroupTiles[I].Margins.Bottom) then
      Exit(I);
  end;
  // Inside the box and on no button: below them all, or above the first
  ABelow := (Length(FGroupTiles) = 0) or
    (FGroupTiles[High(FGroupTiles)].AbsoluteToLocal(AAbsolute).Y > 0);
end;

procedure TAssetsForm.SetDropIndex(const AIndex: Integer);
begin
  if AIndex = FDropIndex then
    Exit;
  FDropIndex := AIndex;
  UpdateGroupMarks;
end;

procedure TAssetsForm.EndDrag;
begin
  FDragging := False;
  FScrollTimer.Enabled := False;
  FDragGhost.Visible := False;
  FDropFolder := -1;
  FDropInto := False;
  FDropBelow := False;
  FDropIndex := -1;
  UpdateGroupMarks;
end;

procedure TAssetsForm.Defer;
begin
  FDeferTimer.Enabled := False;
  FDeferTimer.Enabled := True;
end;

procedure TAssetsForm.DeferredWork(Sender: TObject);
var
  Group: String;
begin
  FDeferTimer.Enabled := False;
  if FBulkPending then
  begin
    FBulkPending := False;
    NextBulk;
  end;
  if FOpenGroup <> String.Empty then
  begin
    Group := FOpenGroup;
    FOpenGroup := String.Empty;
    if GroupIndex(Group) >= 0 then
      ShowGroup(FGroupOrder[GroupIndex(Group)]);
  end;
  if FReparentGroup <> String.Empty then
  begin
    Group := FReparentGroup;
    FReparentGroup := String.Empty;
    Reparent(Group, FReparentTo);
    FReparentTo := String.Empty;
  end;
end;

procedure TAssetsForm.GroupTileMouseDown(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Single);
begin
  if not (Sender is TRectangle) or (Button <> TMouseButton.mbLeft) or
    (ssCtrl in Shift) then
    Exit;
  // Chosen at once, and stays chosen until another is; from inside one of
  // its groups, back to its top
  if not SameText(TRectangle(Sender).TagString, FGroup) then
    ShowGroup(TRectangle(Sender).TagString);
  FGroupDown := TRectangle(Sender).TagString;
  FGroupDownInGrid := False;
  FDownAt := TRectangle(Sender).LocalToAbsolute(TPointF.Create(X, Y));
  FDragging := False;
end;

procedure TAssetsForm.GroupTileMouseMove(Sender: TObject; Shift: TShiftState;
  X, Y: Single);
var
  At: TPointF;
begin
  if (FGroupDown = String.Empty) or not (Sender is TRectangle) then
    Exit;
  if not (ssLeft in Shift) then
  begin
    FGroupDown := String.Empty;
    EndDrag;
    Exit;
  end;
  At := TRectangle(Sender).LocalToAbsolute(TPointF.Create(X, Y));
  if not FDragging then
  begin
    if At.Distance(FDownAt) < TILE_DRAG_START then
      Exit;
    // The group's icon follows the pointer
    FDragGhost.Bitmap.Assign(GroupIcon(FGroupDown));
    FDragCount.Text := String.Empty;
    BeginDrag;
  end;
  FDragAt := At;
  FDragGhost.Position.Point := TPointF.Create(At.X - GHOST_SIZE / 2, At.Y - GHOST_SIZE / 2);
  TrackGroupDrag(At);
end;

procedure TAssetsForm.GroupTileMouseUp(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Single);
var
  At: TPointF;
  Dragged: Boolean;
begin
  if not (Sender is TRectangle) then
    Exit;
  At := TRectangle(Sender).LocalToAbsolute(TPointF.Create(X, Y));
  if (Button = TMouseButton.mbRight) or
    ((Button = TMouseButton.mbLeft) and (ssCtrl in Shift)) then
  begin
    FMenuInGrid := TRectangle(Sender).Parent = FTilesLayout;
    ShowGroupMenu(TRectangle(Sender).TagString, At);
    Exit;
  end;
  if Button <> TMouseButton.mbLeft then
    Exit;
  Dragged := FDragging and (FGroupDown <> String.Empty);
  if Dragged then
    DropGroup(At);
  FGroupDown := String.Empty;
  FGroupDownInGrid := False;
  EndDrag;
end;

procedure TAssetsForm.GroupsBoxMouseUp(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Single);
begin
  if (Button = TMouseButton.mbRight) or
    ((Button = TMouseButton.mbLeft) and (ssCtrl in Shift)) then
  begin
    FMenuInGrid := False;
    ShowGroupMenu(String.Empty, GroupsBox.LocalToAbsolute(TPointF.Create(X, Y)));
  end;
end;

procedure TAssetsForm.TilesBoxMouseUp(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Single);
begin
  if (FGroup <> String.Empty) and ((Button = TMouseButton.mbRight) or
    ((Button = TMouseButton.mbLeft) and (ssCtrl in Shift))) then
  begin
    FMenuInGrid := True;
    ShowGroupMenu(String.Empty, TilesBox.LocalToAbsolute(TPointF.Create(X, Y)));
  end;
end;

procedure TAssetsForm.ShowGroupMenu(const AGroup: String; const AAbsolute: TPointF);
var
  At: TPointF;
begin
  if FDragging or (Length(FEntries) = 0) then
    Exit;
  FMenuGroup := AGroup;
  RenameGroupItem.Enabled := AGroup <> String.Empty;
  IconGroupItem.Enabled := AGroup <> String.Empty;
  DeleteGroupItem.Enabled := (AGroup <> String.Empty) and GroupEmpty(AGroup);
  AddGroupItem.Text := IfThen(FMenuInGrid, 'Add Group Inside "' + FGroup + '"...',
    'Add Group...');
  if AGroup <> String.Empty then
  begin
    RenameGroupItem.Text := 'Rename "' + AGroup + '"...';
    DeleteGroupItem.Text := 'Delete "' + AGroup + '"';
  end
  else
  begin
    RenameGroupItem.Text := 'Rename Group...';
    DeleteGroupItem.Text := 'Delete Group';
  end;
  At := ClientToScreen(AAbsolute);
  GroupMenu.Popup(At.X, At.Y);
end;

procedure TAssetsForm.AddGroupItemClick(Sender: TObject);
begin
  FAskName := gnAdd;
  TDialogService.InputQuery('Add Group', ['Name of the new group'], [''],
    GroupNameClosed);
end;

procedure TAssetsForm.RenameGroupItemClick(Sender: TObject);
var
  Prompt: String;
begin
  if FMenuGroup = String.Empty then
    Exit;
  FAskName := gnRename;
  Prompt := 'New name for ' + FMenuGroup;
  TDialogService.InputQuery('Rename Group', [Prompt], [FMenuGroup], GroupNameClosed);
end;

procedure TAssetsForm.GroupNameClosed(Sender: TObject; const AResult: TModalResult;
  const AValues: array of String);
var
  Ask: TGroupNameAsk;
  GroupName, Old: String;
  At, Clash: Integer;
begin
  Ask := FAskName;
  FAskName := gnNone;
  if (AResult <> mrOk) or (Length(AValues) = 0) then
    Exit;
  if Ask in [gnNewCollection, gnRenameCollection] then
  begin
    CollectionNamed(Ask, Trim(AValues[0]));
    Exit;
  end;
  if Ask in [gnNewArtist, gnRenameArtist] then
  begin
    ArtistNamed(Ask, Trim(AValues[0]));
    Exit;
  end;
  GroupName := LowerCase(Trim(AValues[0]));
  if GroupName = String.Empty then
    Exit;
  Clash := GroupIndex(GroupName);
  case Ask of
    gnAdd:
      begin
        if Clash >= 0 then
        begin
          TDialogService.ShowMessage('There is a group called ' + GroupName + ' already.');
          Exit;
        end;
        // In the grid, inside the group shown, else at the top; in its
        // alphabetical place either way
        FGroupOrder := FGroupOrder + [GroupName];
        if FMenuInGrid and (FGroup <> String.Empty) then
        begin
          FGroupParents.AddOrSetValue(LowerCase(GroupName), FGroup);
          Log('Assets: group ' + GroupName + ' added inside ' + FGroup);
        end
        else
          Log('Assets: group ' + GroupName + ' added');
      end;
    gnRename:
      begin
        At := GroupIndex(FMenuGroup);
        if At < 0 then
          Exit;
        Old := FGroupOrder[At];
        if SameText(GroupName, Old) then
          Exit;
        if Clash >= 0 then
        begin
          TDialogService.ShowMessage('There is a group called ' + GroupName + ' already.');
          Exit;
        end;
        FGroupOrder[At] := GroupName;
        for var Key in FPaletteGroups.Keys.ToArray do
          if SameText(FPaletteGroups[Key], Old) then
            FPaletteGroups[Key] := GroupName;
        for var I := 0 to High(FEntries) do
          if SameText(FEntries[I].Meta.Group, Old) then
            FEntries[I].Meta.Group := GroupName;
        // The groups inside it, and its own place
        for var Key in FGroupParents.Keys.ToArray do
          if SameText(FGroupParents[Key], Old) then
            FGroupParents[Key] := GroupName;
        if FGroupParents.ContainsKey(LowerCase(Old)) then
        begin
          FGroupParents.AddOrSetValue(LowerCase(GroupName), FGroupParents[LowerCase(Old)]);
          FGroupParents.Remove(LowerCase(Old));
        end;
        if FGroupIcons.ContainsKey(LowerCase(Old)) then
        begin
          FGroupIcons.AddOrSetValue(LowerCase(GroupName), FGroupIcons[LowerCase(Old)]);
          FGroupIcons.Remove(LowerCase(Old));
        end;
        if SameText(FGroup, Old) then
          FGroup := GroupName;
        Log('Assets: group ' + Old + ' renamed ' + GroupName);
      end;
  else
    Exit;
  end;
  SavePalette;
  BuildGroups;
  // A new group at the top is chosen; one inside is a tile in the grid
  if (Ask = gnAdd) and not FMenuInGrid then
    ShowGroup(GroupName);
end;

procedure TAssetsForm.IconGroupItemClick(Sender: TObject);
var
  Group, Source, IconName, Folder, Target: String;
begin
  Group := FMenuGroup;
  if Group = String.Empty then
    Exit;
  IconDialog.Title := 'Icon for ' + Group;
  IconDialog.Filter := 'Icons (*.svg;*.png)|*.svg;*.png|All files (*.*)|*.*';
  // The library that comes with the program, or the user's own
  Folder := GroupIconsFolder;
  if Folder = String.Empty then
    Folder := TSprite3DAppSettings.UserGroupIconsFolder;
  IconDialog.InitialDir := Folder;
  IconDialog.FileName := String.Empty;
  if not IconDialog.Execute then
    Exit;
  Source := IconDialog.FileName;
  if not IsGroupIconFile(Source) then
  begin
    TDialogService.ShowMessage('An icon is an SVG or PNG file.');
    Exit;
  end;
  IconName := ExtractFileName(Source);
  // From the library as it is; from elsewhere, copied into the user's own
  if not SameText(IconFile(IconName), ExpandFileName(Source)) then
  begin
    Target := TPath.Combine(TSprite3DAppSettings.UserGroupIconsFolder, IconName);
    try
      ForceDirectories(TSprite3DAppSettings.UserGroupIconsFolder);
      TFile.Copy(Source, Target, True);
    except
      on E: Exception do
      begin
        LogError('Assets: can''t copy the icon ' + Source + ' to ' + Target + ': ' + E.Message);
        Exit;
      end;
    end;
    FIconBitmaps.Remove(Target);
  end;
  FGroupIcons.AddOrSetValue(LowerCase(Group), IconName);
  Log('Assets: group ' + Group + ' has the icon ' + IconName);
  SavePalette;
  BuildGroups;
end;

procedure TAssetsForm.DeleteGroupItemClick(Sender: TObject);
var
  At: Integer;
begin
  At := GroupIndex(FMenuGroup);
  if (At < 0) or not GroupEmpty(FMenuGroup) then
    Exit;
  Log('Assets: group ' + FGroupOrder[At] + ' deleted');
  FGroupIcons.Remove(LowerCase(FGroupOrder[At]));
  FGroupParents.Remove(LowerCase(FGroupOrder[At]));
  // Shown no more: its outer group instead
  if SameText(FGroup, FGroupOrder[At]) then
    FGroup := ParentOf(FGroupOrder[At]);
  Delete(FGroupOrder, At, 1);
  SavePalette;
  BuildGroups;
end;

function TAssetsForm.GroupIndex(const AGroup: String): Integer;
begin
  for var I := 0 to High(FGroupOrder) do
    if SameText(FGroupOrder[I], AGroup) then
      Exit(I);
  Result := -1;
end;

function TAssetsForm.PaletteCount(const AGroup: String): Integer;
begin
  Result := 0;
  for var Group in FPaletteGroups.Values do
    if SameText(Group, AGroup) then
      Inc(Result);
end;

procedure TAssetsForm.SavePalette;
var
  Palette: TArray<TSprite3DPaletteGroup>;
  Present: TDictionary<String, Boolean>;
  Others: TArray<String>;
  Group: TSprite3DPaletteGroup;
  Model: TSprite3DCollectionModel;
begin
  // A group a model is in that the order lacks goes last, so none is lost
  for var Pair in FPaletteGroups do
    if GroupIndex(Pair.Value) < 0 then
      FGroupOrder := FGroupOrder + [Pair.Value];
  Present := TDictionary<String, Boolean>.Create;
  try
    for var Entry in FEntries do
      Present.AddOrSetValue(Entry.Meta.Hash, True);
    Palette := nil;
    for var GroupName in FGroupOrder do
    begin
      Group.Name := GroupName;
      Group.Models := nil;
      if not FGroupIcons.TryGetValue(LowerCase(GroupName), Group.Icon) then
        Group.Icon := String.Empty;
      Group.Parent := ParentOf(GroupName);
      // FEntries is in name order
      for var Entry in FEntries do
        if SameText(Entry.Meta.Group, GroupName) then
          Group.Models := Group.Models + [Entry.Meta.Hash];
      Others := nil;
      for var Pair in FPaletteGroups do
        if SameText(Pair.Value, GroupName) and not Present.ContainsKey(Pair.Key) then
          Others := Others + [Pair.Key];
      TArray.Sort<String>(Others);
      Group.Models := Group.Models + Others;
      Palette := Palette + [Group];
    end;
  finally
    Present.Free;
  end;
  if FCollection.Id = String.Empty then
    Exit;
  FCollection.Groups := Palette;
  // The models as they are now, with their files
  FCollection.Models := nil;
  for var Entry in FEntries do
  begin
    Model.Key := Entry.Meta.Hash;
    Model.FileName := Entry.Meta.FileName;
    FCollection.Models := FCollection.Models + [Model];
  end;
  try
    SaveAssetCollection(FCacheFolder, FCollection);
  except
    on E: Exception do
      LogError('Assets: can''t save the collection ' + FCollection.Name + ' in ' + FCacheFolder +
        ': ' + E.Message);
  end;
  // The counts the bars show, refilled only when they change
  for var I := 0 to High(FLibrary.Collections) do
    if SameText(FLibrary.Collections[I].Id, FCollection.Id) then
    begin
      if (FLibrary.Collections[I].Models <> Length(FCollection.Models)) or
        (FLibrary.Collections[I].Scanned <> FCollection.Scanned) then
      begin
        FLibrary.Collections[I].Models := Length(FCollection.Models);
        FLibrary.Collections[I].Scanned := FCollection.Scanned;
        FillCollections;
      end;
      Break;
    end;
end;

function TAssetsForm.CountText(const ACount: Integer; const AWord: String): String;
begin
  Result := FormatFloat('#,##0', ACount) + ' ' + AWord;
  if ACount <> 1 then
    Result := Result + 's';
end;

function TAssetsForm.ArtistText(const AArtist: TSprite3DArtist): String;
var
  Collections, Models: Integer;
begin
  Collections := 0;
  Models := 0;
  for var Entry in FLibrary.Collections do
    if SameText(Entry.ArtistId, AArtist.Id) then
    begin
      Inc(Collections);
      Inc(Models, Entry.Models);
    end;
  Result := AArtist.Name + '  (' + CountText(Collections, 'collection') + ', ' +
    CountText(Models, 'model') + ')';
end;

function TAssetsForm.CollectionText(const AEntry: TSprite3DLibraryEntry): String;
begin
  if AEntry.Scanned then
    Result := AEntry.Name + '  (' + CountText(AEntry.Models, 'model') + ')'
  else
    Result := AEntry.Name + '  (not imported yet)';
end;

procedure TAssetsForm.ShowGroup(const AGroup: String);
begin
  FGroup := AGroup;
  for var I := 0 to High(FEntries) do
    FEntries[I].Picked := False;
  FAnchor := -1;
  TilesBox.ViewportPosition := TPointF.Zero;
  BuildFolderTiles;
  LayoutTiles;
  UpdateGroupMarks;
  UpdatePath;
end;

procedure TAssetsForm.UpdateTileMarks;
begin
  for var I := 0 to High(FEntries) do
  begin
    if FEntries[I].Tile = nil then
      Continue;
    if FEntries[I].Picked then
    begin
      FEntries[I].Tile.Stroke.Color := TILE_SELECTED_STROKE;
      FEntries[I].Tile.Stroke.Thickness := 2;
    end
    else
    begin
      FEntries[I].Tile.Stroke.Color := TILE_STROKE;
      FEntries[I].Tile.Stroke.Thickness := 1;
    end;
    if I = FSelected then
    begin
      FEntries[I].Tile.Fill.Kind := TBrushKind.Solid;
      FEntries[I].Tile.Fill.Color := TILE_SELECTED_FILL;
    end
    else
      FEntries[I].Tile.Fill.Kind := TBrushKind.None;
  end;
end;

function TAssetsForm.PickedEntries: TArray<Integer>;
begin
  Result := nil;
  for var I := 0 to High(FEntries) do
    if FEntries[I].Picked then
      Result := Result + [I];
end;

procedure TAssetsForm.PickEntry(const AIndex: Integer; const AShift: TShiftState);
var
  Lo, Hi: Integer;
begin
  if (ssShift in AShift) and (FAnchor >= 0) and (FAnchor <= High(FEntries)) then
  begin
    // The run between, in the order shown, which is name order
    Lo := Min(FAnchor, AIndex);
    Hi := Max(FAnchor, AIndex);
    if not (ssCtrl in AShift) then
      for var I := 0 to High(FEntries) do
        FEntries[I].Picked := False;
    for var I := Lo to Hi do
      if SameText(FEntries[I].Meta.Group, FGroup) then
        FEntries[I].Picked := True;
  end
  else if ssCtrl in AShift then
  begin
    FEntries[AIndex].Picked := not FEntries[AIndex].Picked;
    FAnchor := AIndex;
  end
  else
  begin
    for var I := 0 to High(FEntries) do
      FEntries[I].Picked := I = AIndex;
    FAnchor := AIndex;
  end;
end;

procedure TAssetsForm.TileMouseDown(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Single);
var
  Index: Integer;
begin
  if not (Sender is TRectangle) then
    Exit;
  Index := TRectangle(Sender).Tag;
  if (Index < 0) or (Index > High(FEntries)) then
    Exit;
  // A right-click chooses the model's variant
  if Button = TMouseButton.mbRight then
  begin
    SelectEntry(Index);
    ShowVariantMenu(Index, TRectangle(Sender).LocalToScreen(TPointF.Create(X, Y)));
    Exit;
  end;
  if Button <> TMouseButton.mbLeft then
    Exit;
  // A plain click on one already picked keeps the others until the button
  // comes up, so they can all be dragged
  FPickOnUp := FEntries[Index].Picked and ([ssShift, ssCtrl] * Shift = []);
  if not FPickOnUp then
    PickEntry(Index, Shift);
  SelectEntry(Index);
  FTileDown := Index;
  FDownAt := TRectangle(Sender).LocalToAbsolute(TPointF.Create(X, Y));
  FDragging := False;
end;

procedure TAssetsForm.TileMouseMove(Sender: TObject; Shift: TShiftState; X, Y: Single);
var
  At: TPointF;
  Count: Integer;
begin
  if (FTileDown < 0) or not (Sender is TRectangle) or
    (TRectangle(Sender).Tag <> FTileDown) then
    Exit;
  if not (ssLeft in Shift) then
  begin
    // Let go where the tile did not see it
    FTileDown := -1;
    EndDrag;
    Exit;
  end;
  At := TRectangle(Sender).LocalToAbsolute(TPointF.Create(X, Y));
  if not FDragging then
  begin
    if At.Distance(FDownAt) < TILE_DRAG_START then
      Exit;
    // Only picked ones are dragged: a drag from one not picked picks it
    if not FEntries[FTileDown].Picked then
    begin
      PickEntry(FTileDown, []);
      UpdateTileMarks;
    end;
    FPickOnUp := False;
    if FEntries[FTileDown].Image <> nil then
      FDragGhost.Bitmap.Assign(FEntries[FTileDown].Image.Bitmap);
    Count := Length(PickedEntries);
    FDragCount.Text := IfThen(Count > 1, IntToStr(Count), '');
    BeginDrag;
  end;
  FDragAt := At;
  FDragGhost.Position.Point := TPointF.Create(At.X - GHOST_SIZE / 2, At.Y - GHOST_SIZE / 2);
  TrackTileDrag(At);
end;

function TAssetsForm.LevelTakes(const AIndex: Integer): Boolean;
begin
  Result := (AIndex >= 0) and (AIndex <= High(FEntries)) and FEntries[AIndex].HasThumbnail and
    LevelSpec(AIndex).HasBox;
end;

function TAssetsForm.LevelSpec(const AIndex: Integer): TSprite3DPieceSpec;
begin
  Result := Default(TSprite3DPieceSpec);
  if (AIndex < 0) or (AIndex > High(FEntries)) then
    Exit;
  Result.Name := FEntries[AIndex].Meta.Name;
  Result.FileName := FEntries[AIndex].Meta.FileName;
  Result.Key := FEntries[AIndex].Meta.Hash;
  Result.BoxMin := FEntries[AIndex].Meta.BoxMin;
  Result.BoxMax := FEntries[AIndex].Meta.BoxMax;
  // Placed as the variant its tile chose; the base otherwise
  if (FEntries[AIndex].Variant >= 0) and
    (FEntries[AIndex].Variant <= High(FEntries[AIndex].Meta.Variants)) then
    Result.VariantName := FEntries[AIndex].Meta.Variants[FEntries[AIndex].Variant];
end;

procedure TAssetsForm.ShowVariantMenu(const AIndex: Integer; const AScreen: TPointF);
var
  Item: TMenuItem;
begin
  if (AIndex < 0) or (AIndex > High(FEntries)) then
    Exit;
  if Length(FEntries[AIndex].Meta.Variants) = 0 then
  begin
    Log('Assets: ' + FEntries[AIndex].Meta.Name + ' has no material variants');
    Exit;
  end;
  FVariantEntry := AIndex;
  // A new menu each time, parented to the form, as FMX shows a popup
  // menu's items only then; not items taken out of the old one, which once
  // hung the collection menu
  FreeAndNil(FVariantMenu);
  FVariantMenu := TPopupMenu.Create(Self);
  FVariantMenu.Parent := Self;
  for var I := BASE_VARIANT to High(FEntries[AIndex].Meta.Variants) do
  begin
    Item := TMenuItem.Create(Self);
    if I = BASE_VARIANT then
      Item.Text := 'Base (as made)'
    else
      Item.Text := FEntries[AIndex].Meta.Variants[I];
    Item.Tag := I;
    Item.IsChecked := I = FEntries[AIndex].Variant;
    Item.OnClick := VariantItemClick;
    FVariantMenu.AddObject(Item);
  end;
  FVariantMenu.Popup(AScreen.X, AScreen.Y);
end;

procedure TAssetsForm.VariantItemClick(Sender: TObject);
var
  Index, Variant: Integer;
begin
  Index := FVariantEntry;
  Variant := TMenuItem(Sender).Tag;
  if (Index < 0) or (Index > High(FEntries)) or (FEntries[Index].Variant = Variant) then
    Exit;
  FEntries[Index].Variant := Variant;
  UpdateBadge(Index);
  if Variant = BASE_VARIANT then
    Log('Assets: ' + FEntries[Index].Meta.Name + ' placed as made')
  else
    Log('Assets: ' + FEntries[Index].Meta.Name + ' placed as variant ' +
      FEntries[Index].Meta.Variants[Variant]);
  // Shown as it, and placed as it from now on
  SelectEntry(Index);
  ShowPreview(Index);
  NotifyModelChosen;
end;



procedure TAssetsForm.TrackTileDrag(const At: TPointF);
var
  Index: Integer;
  Below: Boolean;
begin
  // Only another group is somewhere to drop: a button, or a group's tile
  Index := GroupTileAt(At, Below);
  if (Index >= 0) and SameText(FShownGroups[Index], FGroup) then
    Index := -1;
  FDropFolder := FolderTileAt(At);
  SetDropIndex(Index);
  UpdateGroupMarks;
end;

procedure TAssetsForm.BeginDrag;
begin
  FDragging := True;
  FDragGhost.Visible := True;
  FDragGhost.BringToFront;
  FScrollTimer.Enabled := True;
end;

function TAssetsForm.EdgeScroll(const ABox: TVertScrollBox; const At: TPointF): Boolean;
var
  Local: TPointF;
  Step, Top, Limit: Single;
begin
  Result := False;
  Local := ABox.AbsoluteToLocal(At);
  if (Local.X < 0) or (Local.X > ABox.Width) then
    Exit;
  if Local.Y < DRAG_SCROLL_EDGE then
    Step := -DRAG_SCROLL_STEP * (1 + Max(0, -Local.Y) / DRAG_SCROLL_EDGE)
  else if Local.Y > ABox.Height - DRAG_SCROLL_EDGE then
    Step := DRAG_SCROLL_STEP * (1 + Max(0, Local.Y - ABox.Height) / DRAG_SCROLL_EDGE)
  else
    Exit;
  Limit := Max(0, ABox.ContentBounds.Height - ABox.Height);
  Top := EnsureRange(ABox.ViewportPosition.Y + Step, 0, Limit);
  if SameValue(Top, ABox.ViewportPosition.Y) then
    Exit;
  ABox.ViewportPosition := TPointF.Create(ABox.ViewportPosition.X, Top);
  Result := True;
end;

procedure TAssetsForm.ScrollTimerTimer(Sender: TObject);
begin
  if not FDragging then
  begin
    FScrollTimer.Enabled := False;
    Exit;
  end;
  if not EdgeScroll(GroupsBox, FDragAt) and not EdgeScroll(TilesBox, FDragAt) then
    Exit;
  // What is under the pointer has moved
  if FTileDown >= 0 then
    TrackTileDrag(FDragAt)
  else if FGroupDown <> String.Empty then
    TrackGroupDrag(FDragAt);
end;

procedure TAssetsForm.TileMouseUp(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Single);
var
  Index, Folder: Integer;
  Below: Boolean;
  At: TPointF;
begin
  if Button <> TMouseButton.mbLeft then
    Exit;
  Index := FTileDown;
  FTileDown := -1;
  if not FDragging then
  begin
    EndDrag;
    // A plain click on a picked one, with no drag: that one alone
    if FPickOnUp and (Index >= 0) then
    begin
      PickEntry(Index, []);
      UpdateTileMarks;
      // That one alone is placed now
      NotifyModelChosen;
    end;
    FPickOnUp := False;
    Exit;
  end;
  if not (Sender is TRectangle) then
  begin
    EndDrag;
    Exit;
  end;
  At := TRectangle(Sender).LocalToAbsolute(TPointF.Create(X, Y));
  Index := GroupTileAt(At, Below);
  Folder := FolderTileAt(At);
  EndDrag;
  if Folder >= 0 then
    MoveEntries(PickedEntries, FFolderNames[Folder])
  else if (Index >= 0) and not SameText(FShownGroups[Index], FGroup) then
    MoveEntries(PickedEntries, FShownGroups[Index]);
end;

procedure TAssetsForm.MoveEntries(const AIndices: TArray<Integer>; const AGroup: String);
var
  Group: String;
  Moved: Integer;
begin
  Group := LowerCase(Trim(AGroup));
  if (Length(AIndices) = 0) or (Group = String.Empty) then
    Exit;
  // A group the palette has keeps its own spelling
  if GroupIndex(Group) >= 0 then
    Group := FGroupOrder[GroupIndex(Group)]
  else
    FGroupOrder := FGroupOrder + [Group];
  Moved := 0;
  for var Index in AIndices do
  begin
    if (Index < 0) or (Index > High(FEntries)) or
      SameText(FEntries[Index].Meta.Group, Group) then
      Continue;
    FEntries[Index].Meta.Group := Group;
    FEntries[Index].GroupChosen := True;
    FEntries[Index].Picked := False;
    FPaletteGroups.AddOrSetValue(FEntries[Index].Meta.Hash, Group);
    Inc(Moved);
  end;
  if Moved = 0 then
    Exit;
  SavePalette;
  if Moved = 1 then
    Log(Format('Assets: %s moved to %s', [FEntries[AIndices[0]].Meta.Name, Group]))
  else
    Log(Format('Assets: %d models moved to %s', [Moved, Group]));
  // The group shown stays, with the models gone from it
  if (FSelected >= 0) and not SameText(FEntries[FSelected].Meta.Group, FGroup) then
    SelectEntry(-1);
  BuildGroups;
  UpdateTileMarks;
end;

procedure TAssetsForm.UpdateBadge(const AIndex: Integer);
var
  Tag, Variants: String;
  Entry: TAssetEntry;
begin
  if (AIndex < 0) or (AIndex > High(FEntries)) or (FEntries[AIndex].Badge = nil) then
    Exit;
  Entry := FEntries[AIndex];
  Tag := ModelKindTag(ModelKindFromKey(Entry.Meta.Kind));
  Entry.BadgeText.Text := Tag;
  // How many variants it has, or the one chosen
  Variants := String.Empty;
  if Length(Entry.Meta.Variants) > 0 then
  begin
    if (Entry.Variant >= 0) and (Entry.Variant <= High(Entry.Meta.Variants)) then
      Variants := Entry.Meta.Variants[Entry.Variant]
    else
      Variants := Format('%d var', [Length(Entry.Meta.Variants)]);
    Entry.Tile.Hint := Format('%s: material variants %s (right-click to choose)',
      [Entry.Meta.Name, String.Join(', ', Entry.Meta.Variants)]);
  end
  else
    Entry.Tile.Hint := Entry.Meta.Name;
  if Entry.VariantText <> nil then
    Entry.VariantText.Text := Variants;
  Entry.Badge.Visible := (Tag <> String.Empty) or (Variants <> String.Empty);
end;

function TAssetsForm.EntryContentText(const AIndex: Integer): String;
var
  Content: TSprite3DModelContent;
begin
  Content.Meshes := FEntries[AIndex].Meta.Meshes;
  Content.Vertices := FEntries[AIndex].Meta.Vertices;
  Content.Animations := FEntries[AIndex].Meta.Animations;
  Content.Skins := FEntries[AIndex].Meta.Skins;
  Content.Joints := FEntries[AIndex].Meta.Joints;
  Result := ModelKindName(ModelKindFromKey(FEntries[AIndex].Meta.Kind)) + ': ' +
    ModelContentText(Content);
end;

procedure TAssetsForm.SelectEntry(const AIndex: Integer);
var
  Size: TPoint3D;
begin
  if (AIndex < 0) or (AIndex > High(FEntries)) then
  begin
    FSelected := -1;
    NameLabel.Text := String.Empty;
    SizeLabel.Text := String.Empty;
    FileLabel.Text := String.Empty;
    UpdateTileMarks;
    ShowPreview(-1);
    Exit;
  end;
  FSelected := AIndex;
  UpdateTileMarks;
  NameLabel.Text := FEntries[AIndex].Meta.Name + '  (' + FEntries[AIndex].Meta.Group + ')';
  if FEntries[AIndex].HasThumbnail then
  begin
    Size := FEntries[AIndex].Meta.Size;
    SizeLabel.Text := Format('%s x %s x %s units', [FormatFloat('0.###', Size.X),
      FormatFloat('0.###', Size.Y), FormatFloat('0.###', Size.Z)]);
  end
  else
    SizeLabel.Text := 'Size known once its thumbnail is made';
  // What it holds, once it has been loaded and counted
  if FEntries[AIndex].Meta.Kind <> String.Empty then
    SizeLabel.Text := SizeLabel.Text + '; ' + EntryContentText(AIndex);
  FileLabel.Text := FEntries[AIndex].Meta.FileName;
  FileLabel.Hint := FileLabel.Text;
  ShowPreview(AIndex);
  // The models the level's Place Model tool places
  NotifyModelChosen;
end;

procedure TAssetsForm.NotifyModelChosen;
var
  Specs: TArray<TSprite3DPieceSpec>;
  LeftOut: TArray<String>;

  procedure Take(const AIndex: Integer);
  begin
    if LevelTakes(AIndex) then
      Specs := Specs + [LevelSpec(AIndex)]
    else
      LeftOut := LeftOut + [FEntries[AIndex].Meta.Name];
  end;

begin
  if not Assigned(FOnModelChosen) or (FSelected < 0) or (FSelected > High(FEntries)) then
    Exit;
  Specs := nil;
  LeftOut := nil;
  Take(FSelected);
  if FEntries[FSelected].Picked then
    for var I := 0 to High(FEntries) do
      if (I <> FSelected) and FEntries[I].Picked then
        Take(I);
  FOnModelChosen(Specs, LeftOut);
end;

procedure TAssetsForm.BuildTiles;
var
  Tile, Badge: TRectangle;
  Image: TImage;
  Caption, BadgeText, VariantText: TLabel;
  Bitmap: TBitmap;
begin
  TilesBox.BeginUpdate;
  try
    FTilesLayout.DeleteChildren;
    for var I := 0 to High(FEntries) do
    begin
      Tile := TRectangle.Create(FTilesLayout);
      Tile.Parent := FTilesLayout;
      Tile.Visible := False;
      Tile.Width := TILE_WIDTH;
      Tile.Height := TILE_HEIGHT;
      Tile.XRadius := 4;
      Tile.YRadius := 4;
      Tile.Fill.Kind := TBrushKind.None;
      Tile.Stroke.Color := TILE_STROKE;
      Tile.Tag := I;
      Tile.Hint := FEntries[I].Meta.Name;
      Tile.ShowHint := True;
      // Keeps the mouse while a button is down, so a drag's moves and its
      // drop come here wherever the pointer goes
      Tile.AutoCapture := True;
      Tile.OnMouseDown := TileMouseDown;
      Tile.OnMouseMove := TileMouseMove;
      Tile.OnMouseUp := TileMouseUp;

      Image := TImage.Create(Tile);
      Image.Parent := Tile;
      Image.Align := TAlignLayout.Top;
      Image.Height := TILE_IMAGE;
      Image.Margins.Rect := TRectF.Create(4, 4, 4, 0);
      Image.WrapMode := TImageWrapMode.Fit;
      Image.HitTest := False;
      if FEntries[I].HasThumbnail then
        try
          Bitmap := TBitmap.CreateFromFile(
            AssetThumbnailFile(FCacheFolder, FEntries[I].Meta.Hash));
          try
            Image.Bitmap.Assign(Bitmap);
          finally
            Bitmap.Free;
          end;
        except
          on E: Exception do
          begin
            // Unreadable after all: made again
            FEntries[I].HasThumbnail := False;
            LogError('Assets: can''t read the thumbnail of ' + FEntries[I].Meta.Name + ': ' +
              E.Message);
          end;
        end;

      Caption := TLabel.Create(Tile);
      Caption.Parent := Tile;
      Caption.Align := TAlignLayout.Client;
      Caption.Margins.Rect := TRectF.Create(2, 0, 2, 2);
      Caption.TextSettings.HorzAlign := TTextAlign.Center;
      Caption.TextSettings.WordWrap := False;
      Caption.TextSettings.Trimming := TTextTrimming.Character;
      Caption.StyledSettings := Caption.StyledSettings - [TStyledSetting.Size];
      Caption.TextSettings.Font.Size := 10;
      Caption.Text := FEntries[I].Meta.Name;
      Caption.HitTest := False;

      // The kind, over the thumbnail's top right corner
      Badge := TRectangle.Create(Tile);
      Badge.Parent := Tile;
      Badge.HitTest := False;
      Badge.Height := 14;
      Badge.Width := TILE_WIDTH - 12;
      Badge.Position.Point := TPointF.Create(6, 6);
      Badge.Fill.Kind := TBrushKind.None;
      Badge.Stroke.Kind := TBrushKind.None;
      BadgeText := TLabel.Create(Badge);
      BadgeText.Parent := Badge;
      BadgeText.Align := TAlignLayout.Right;
      BadgeText.AutoSize := True;
      BadgeText.HitTest := False;
      BadgeText.StyledSettings := BadgeText.StyledSettings - [TStyledSetting.Size,
        TStyledSetting.Style, TStyledSetting.FontColor];
      BadgeText.TextSettings.Font.Size := 9;
      BadgeText.TextSettings.Font.Style := [TFontStyle.fsBold];
      BadgeText.TextSettings.FontColor := BADGE_TEXT_COLOUR;
      BadgeText.TextSettings.WordWrap := False;
      // Its variants, over the top left corner
      VariantText := TLabel.Create(Badge);
      VariantText.Parent := Badge;
      VariantText.Align := TAlignLayout.Left;
      VariantText.AutoSize := True;
      VariantText.HitTest := False;
      VariantText.StyledSettings := VariantText.StyledSettings - [TStyledSetting.Size,
        TStyledSetting.Style, TStyledSetting.FontColor];
      VariantText.TextSettings.Font.Size := 9;
      VariantText.TextSettings.Font.Style := [TFontStyle.fsBold];
      VariantText.TextSettings.FontColor := BADGE_TEXT_COLOUR;
      VariantText.TextSettings.WordWrap := False;

      FEntries[I].Tile := Tile;
      FEntries[I].Image := Image;
      FEntries[I].Badge := Badge;
      FEntries[I].BadgeText := BadgeText;
      FEntries[I].VariantText := VariantText;
      UpdateBadge(I);
    end;
  finally
    TilesBox.EndUpdate;
  end;
  LayoutTiles;
end;

procedure TAssetsForm.LayoutTiles;
var
  Columns, Column: Integer;
  Y: Single;
begin
  if FTilesLayout = nil then
    Exit;
  Columns := Max(1, Trunc((TilesBox.Width - TILE_GAP) / (TILE_WIDTH + TILE_GAP)));
  Y := TILE_GAP;
  Column := 0;
  // The groups inside the one shown first, as folders are
  for var Tile in FFolderTiles do
  begin
    Tile.Position.Point := TPointF.Create(TILE_GAP + Column * (TILE_WIDTH + TILE_GAP), Y);
    Inc(Column);
    if Column >= Columns then
    begin
      Column := 0;
      Y := Y + TILE_HEIGHT + TILE_GAP;
    end;
  end;
  // FEntries is in name order, so the group's tiles are too
  for var I := 0 to High(FEntries) do
  begin
    if FEntries[I].Tile = nil then
      Continue;
    FEntries[I].Tile.Visible := (FGroup <> String.Empty) and
      (FEntries[I].Meta.Group = FGroup);
    if not FEntries[I].Tile.Visible then
      Continue;
    FEntries[I].Tile.Position.Point := TPointF.Create(
      TILE_GAP + Column * (TILE_WIDTH + TILE_GAP), Y);
    Inc(Column);
    if Column >= Columns then
    begin
      Column := 0;
      Y := Y + TILE_HEIGHT + TILE_GAP;
    end;
  end;
  if Column > 0 then
    Y := Y + TILE_HEIGHT + TILE_GAP;
  FTilesLayout.Height := Y;
end;

procedure TAssetsForm.TilesBoxResize(Sender: TObject);
begin
  LayoutTiles;
end;

procedure TAssetsForm.ShowPreview(const AIndex: Integer);
begin
  if Making then
    Exit;   // the viewport is the thumbnails'; MakeNext previews when done
  // Shown already, as the same variant
  if (AIndex = FPreviewIndex) and (FModel <> nil) and (AIndex >= 0) and
    (AIndex <= High(FEntries)) and (FEntries[AIndex].Variant = FPreviewVariant) then
    Exit;
  FreeModel;
  FTurning := False;
  ResetCameraAngles;
  if (AIndex < 0) or (AIndex > High(FEntries)) then
    Exit;
  if not LoadEntryModel(AIndex, FEntries[AIndex].Variant) then
    Exit;
  FPreviewIndex := AIndex;
  FPreviewVariant := FEntries[AIndex].Variant;
  // The floor, Y = 0 in the model's own space, where it will stand on the
  // level's grid: lines at the level's spacing, one through its centre of
  // rotation, so a model off the floor, or off the grid, shows
  FPreviewGrid := TModelGrid.Create(nil);
  FPreviewGrid.Parent := FModel;
  FPreviewGrid.GridSize := FGridSize;
  FPreviewGrid.GridColor := PreviewGridColour;
  FPreviewGrid.GridLevel := 0;
  FPreviewGrid.SetExtent(FModelBox.TopLeftNear, FModelBox.BottomRightFar,
    FModel.RotationCenter.Point);
  FrameModel(FViewport.Width, FViewport.Height);
end;

function TAssetsForm.LoadEntryModel(const AIndex, AVariant: Integer): Boolean;
var
  Box: TBoundingBox;
  FileName, LoadFile: String;
  Watch: TStopwatch;
  Bytes: Int64;
  Fixes: TArray<TSprite3DTextureFix>;
  Content: TSprite3DModelContent;
  Kind: TSprite3DModelKind;
  KnownBefore: Boolean;
  KindBefore: String;
  AnimationsBefore: Integer;
begin
  FileName := FEntries[AIndex].Meta.FileName;
  if IsSkipped(FileName) then
  begin
    LogError('Assets: ' + FileName + ' passed over: it was in the viewport when the program ' +
      'last stopped');
    Exit(False);
  end;
  // Named while it is in the viewport, so a hang or crash leaves its name
  try
    TFile.WriteAllText(OSFriendlyPath(LoadingFile), FileName, TEncoding.UTF8);
  except
    // Only a safeguard
  end;
  try
    Bytes := TFile.GetSize(OSFriendlyPath(FileName));
  except
    Bytes := -1;
  end;
  DebugLog(Format('loading %s (%s bytes)', [FileName, FormatFloat('#,##0', Bytes)]));
  Watch := TStopwatch.StartNew;
  // Loaded as the builder will load it: upright, as each model was in
  // Sprite3D, since FMX's Y points down
  FModel := TGorillaModel.Create(FViewport);
  try
    FModel.Parent := FViewport;
    // Its textures found, and made PNGs where the loader can't read them;
    // loaded from a copy in the cache if any were
    LoadFile := PrepareModelTextures(FileName, FCacheFolder, FEntries[AIndex].Meta.Hash,
      Fixes);
    ReportTextures(FEntries[AIndex].Meta.Name, Fixes);
    // A variant: from a copy whose meshes take its materials
    if AVariant >= 0 then
    begin
      LoadFile := PrepareModelVariant(LoadFile, FCacheFolder, FEntries[AIndex].Meta.Hash,
        AVariant);
      DebugLog('as variant ' + IntToStr(AVariant));
    end;
    if LoadFile <> FileName then
      DebugLog('loading it from ' + LoadFile);
    LoadModelFile(FModel, LoadFile, Box);
    FModel.RotationAngle.X := 180;
    FModel.ResetToBindPose();
    // What it holds, and the kind of model that makes it
    Content := ModelContent(FModel);
    Kind := GuessModelKind(Content);
    KnownBefore := FEntries[AIndex].Meta.Kind <> String.Empty;
    KindBefore := FEntries[AIndex].Meta.Kind;
    AnimationsBefore := FEntries[AIndex].Meta.Animations;
    FEntries[AIndex].Meta.Meshes := Content.Meshes;
    FEntries[AIndex].Meta.Vertices := Content.Vertices;
    FEntries[AIndex].Meta.Animations := Content.Animations;
    FEntries[AIndex].Meta.Skins := Content.Skins;
    FEntries[AIndex].Meta.Joints := Content.Joints;
    FEntries[AIndex].Meta.Kind := ModelKindKey(Kind);
    DebugLog(Format('%s: %s: %s', [FEntries[AIndex].Meta.Name, ModelKindName(Kind),
      ModelContentText(Content)]));
    UpdateBadge(AIndex);
    // One with a thumbnail made before kinds were kept, or counted otherwise
    // before (still takes counted as animations, before 12 November 2026):
    // kept now
    if FEntries[AIndex].HasThumbnail and (not KnownBefore or
      (KindBefore <> FEntries[AIndex].Meta.Kind) or
      (AnimationsBefore <> FEntries[AIndex].Meta.Animations)) then
      try
        SaveAssetMeta(FCacheFolder, FEntries[AIndex].Meta);
      except
        on E: Exception do
          LogError('Assets: can''t save what ' + FEntries[AIndex].Meta.Name + ' holds: ' +
            E.Message);
      end;
  except
    on E: Exception do
    begin
      LogError('Assets: can''t load ' + FileName + ': ' + E.Message);
      FreeModel;
      Exit(False);
    end;
  end;
  DebugLog(Format('loaded in %d ms', [Watch.ElapsedMilliseconds]));
  FModelBox := Box;
  FEntries[AIndex].Meta.BoxMin := Box.TopLeftNear;
  FEntries[AIndex].Meta.BoxMax := Box.BottomRightFar;
  UpdatePreviewLabel;
  Result := True;
end;

procedure TAssetsForm.ReportTextures(const AModel: String;
  const AFixes: TArray<TSprite3DTextureFix>);
begin
  for var Fix in AFixes do
    case Fix.Outcome of
      toConverted:
        Log(Format('Assets: %s: texture %s made a PNG, as the loader can''t read its format',
          [AModel, Fix.Named]));
      toOtherFile:
        Log(Format('Assets: %s: %s %s used in place of %s (%s)', [AModel,
          IfThen(Fix.IsBuffer, 'buffer', 'texture'), Fix.Used, Fix.Named, Fix.Reason]));
      toOtherFileConverted:
        Log(Format('Assets: %s: texture %s, made a PNG, used in place of %s (%s)', [AModel,
          Fix.Source, Fix.Named, Fix.Reason]));
      toMissing:
        if Fix.IsBuffer then
          LogError(Format('Assets: %s: no buffer for %s (%s), nor one of that name and ' +
            'length in its folder or up to %d folders above it, nor one beside it named ' +
            'as the model or without a copy number', [AModel, Fix.Named, Fix.Reason,
            SEARCH_LEVELS_UP]))
        else
          LogError(Format('Assets: %s: no texture for %s (%s), nor one of that name in a ' +
            'format that can be read, in its folder or up to %d folders above it%s',
            [AModel, Fix.Named, Fix.Reason, SEARCH_LEVELS_UP, IfThen(Fix.Used <> '',
            '; the magenta and black placeholder is in its place', '')]));
    end;
end;

procedure TAssetsForm.SetPreviewBackground(const Value: String);
var
  At: Integer;
  Spec: TSprite3DBackgroundSpec;
begin
  At := IndexText(Value, PREVIEW_BACKGROUNDS);
  if At < 0 then
    At := 0;
  FPreviewBackground := PREVIEW_BACKGROUNDS[At];
  Spec := TSprite3DBackgroundSpec.Default;
  if At = 0 then
  begin
    // In squares to suit the small view
    Spec.Kind := TSprite3DBackgroundKind.Transparent;
    Spec.CheckerSize := PREVIEW_CHECKER_SIZE;
  end
  else
  begin
    Spec.Kind := TSprite3DBackgroundKind.Solid;
    Spec.Colour := PREVIEW_BACKGROUND_COLOURS[At];
  end;
  if FBackground <> nil then
    FBackground.Spec := Spec;
  if FPreviewGrid <> nil then
    FPreviewGrid.GridColor := PreviewGridColour;
  // "Model Preview" readable on it
  if FPreviewLabel <> nil then
    FPreviewLabel.TextSettings.FontColor := PREVIEW_LABEL_COLOURS[At];
  if (FBackgroundCombo <> nil) and (FBackgroundCombo.ItemIndex <> At) then
  begin
    FSettingBackground := True;
    try
      FBackgroundCombo.ItemIndex := At;
    finally
      FSettingBackground := False;
    end;
  end;
end;

procedure TAssetsForm.BackgroundComboChange(Sender: TObject);
begin
  if FSettingBackground or (FBackgroundCombo.ItemIndex < 0) or
    (FBackgroundCombo.ItemIndex > High(PREVIEW_BACKGROUNDS)) then
    Exit;
  SetPreviewBackground(PREVIEW_BACKGROUNDS[FBackgroundCombo.ItemIndex]);
  Log('Assets: preview background ' + FPreviewBackground);
  if Assigned(FOnPreviewBackground) then
    FOnPreviewBackground(FPreviewBackground);
end;

function TAssetsForm.PreviewGridColour: TAlphaColor;
begin
  if SameText(FPreviewBackground, 'black') or SameText(FPreviewBackground, 'grey') then
    Result := PREVIEW_GRID_COLOUR_LIGHT
  else
    Result := PREVIEW_GRID_COLOUR;
end;

procedure TAssetsForm.ResetCameraAngles;
begin
  FCamera.Camera.Azimuth := THUMBNAIL_AZIMUTH;
  FCamera.Camera.PolarAngle := THUMBNAIL_INCLINATION;
  FCamera.Camera.Roll := 0;
end;

procedure TAssetsForm.FreeModel;
begin
  FPreviewIndex := -1;
  // Freed with the model, its parent
  FPreviewGrid := nil;
  if FModel <> nil then
  begin
    FModel.Parent := nil;
    FreeAndNil(FModel);
  end;
  // None in the viewport now
  try
    if FileExists(OSFriendlyPath(LoadingFile)) then
      TFile.Delete(OSFriendlyPath(LoadingFile));
  except
    // Only a safeguard
  end;
  if FPreviewLabel <> nil then
    UpdatePreviewLabel;
end;

procedure TAssetsForm.StopMaking;
begin
  if FSettleTimer <> nil then
    FSettleTimer.Enabled := False;
  if FGrabTimer <> nil then
    FGrabTimer.Enabled := False;
  if FNextTimer <> nil then
    FNextTimer.Enabled := False;
  if FOffscreen <> nil then
    FOffscreen.Cancel;
  FQueue := nil;
  FMaking := -1;
  FreeModel;
end;

procedure TAssetsForm.MakeNextLater;
begin
  FNextTimer.Enabled := False;
  FNextTimer.Enabled := True;
end;

procedure TAssetsForm.NextTimerTimer(Sender: TObject);
begin
  FNextTimer.Enabled := False;
  MakeNext;
end;

procedure TAssetsForm.MakeNext;
var
  Index, Done: Integer;
  Left: String;
begin
  FMaking := -1;
  FreeModel;
  if Length(FQueue) = 0 then
  begin
    // Only while there is something to show progress on
    Progress.Visible := False;
    StatusLabel.Text := Format('%d models', [Length(FEntries)]);
    if FQueueTotal > FMadeCount then
      Log(Format('Assets: %d of %d thumbnails made in %s; %d failed, listed in %s',
        [FMadeCount, FQueueTotal, DurationText(FMakeWatch.Elapsed.TotalSeconds),
        FQueueTotal - FMadeCount, ErrorLogFile]))
    else if FQueueTotal > 0 then
      Log(Format('Assets: %d thumbnails made in %s', [FQueueTotal,
        DurationText(FMakeWatch.Elapsed.TotalSeconds)]));
    // Groups with no icon of their own show a thumbnail, there now
    if FQueueTotal > 0 then
      BuildGroups;
    FQueueTotal := 0;
    // An artist import goes on with its next collection, once this has
    // returned
    if FBulkTotal > 0 then
    begin
      FBulkPending := True;
      Defer;
      Exit;
    end;
    // The viewport is free: the selected model, if any, in 3D
    ShowPreview(FSelected);
    Exit;
  end;
  Index := FQueue[0];
  Delete(FQueue, 0, 1);
  Progress.Visible := True;
  Progress.Max := Max(1, FQueueTotal);
  Progress.Value := FQueueTotal - Length(FQueue) - 1;
  // The time left, from the average so far, once there are a few to go by
  Done := FQueueTotal - Length(FQueue) - 1;
  Left := String.Empty;
  if Done >= ETA_AFTER then
    Left := ', about ' + DurationText(FMakeWatch.Elapsed.TotalSeconds / Done *
      (Length(FQueue) + 1)) + ' left';
  StatusLabel.Text := BulkPrefix + Format('Making thumbnails: %d of %d%s, %s', [Done + 1,
    FQueueTotal,
    Left, FEntries[Index].Meta.Name]);

  FTurning := False;
  ResetCameraAngles;
  // A thumbnail is always of the model as made
  if not LoadEntryModel(Index, BASE_VARIANT) then
  begin
    MakeNextLater;
    Exit;
  end;
  // On screen first, framed as the thumbnail will be, so the viewport draws
  // it before the grab; FSettleTimer starts the grab
  FrameModel(FViewport.Width, FViewport.Height);
  FMaking := Index;
  FSettleTimer.Enabled := False;
  FSettleTimer.Enabled := True;
end;

procedure TAssetsForm.SettleTimerTimer(Sender: TObject);
begin
  FSettleTimer.Enabled := False;
  if (FMaking < 0) or (FModel = nil) then
    Exit;
  DebugLog('grabbing ' + FEntries[FMaking].Meta.Name);
  FGrabTries := 1;
  FGrabWatch := TStopwatch.StartNew;
  FPumps := 0;
  FPumpsUseful := 0;
  if not FOffscreen.Grab(GrabDone(FMaking, FScanId)) then
  begin
    LogError('Assets: can''t start the thumbnail of ' + FEntries[FMaking].Meta.Name);
    FMaking := -1;
    FreeModel;
    MakeNextLater;
    Exit;
  end;
  FGrabTimer.Enabled := False;
  FGrabTimer.Enabled := True;
end;

procedure TAssetsForm.GrabTimerTimer(Sender: TObject);
begin
  if (FMaking < 0) or (FMaking > High(FEntries)) then
  begin
    FGrabTimer.Enabled := False;
    Exit;
  end;
  // The grab's steps and result, which the main thread's queue can hold up
  // while the viewport draws; its result stops this timer
  Inc(FPumps);
  if FOffscreen.Poll then
    Inc(FPumpsUseful);
  if not FGrabTimer.Enabled or (FMaking < 0) or (FMaking > High(FEntries)) then
    Exit;
  // Nothing is drawn while minimised: the grab goes on once it is shown
  if WindowState = TWindowState.wsMinimized then
  begin
    if FGrabWatch.ElapsedMilliseconds >= GRAB_TIMEOUT_MS then
      DebugLog('waiting for ' + FEntries[FMaking].Meta.Name + ': the Library is minimised');
    FGrabWatch := TStopwatch.StartNew;
    Exit;
  end;
  if FGrabWatch.ElapsedMilliseconds < GRAB_TIMEOUT_MS then
    Exit;
  DebugLog(Format('grab %d of %s not back after %d s: %s; polled %d times, %d ' +
    'with something to run', [FGrabTries, FEntries[FMaking].Meta.Name, GRAB_TIMEOUT_MS div 1000,
    FOffscreen.StateText, FPumps, FPumpsUseful]));
  FOffscreen.Cancel;
  if FGrabTries < GRAB_TRIES then
  begin
    Inc(FGrabTries);
    DebugLog('grabbing ' + FEntries[FMaking].Meta.Name + ' again');
    FGrabWatch := TStopwatch.StartNew;
    FPumps := 0;
    FPumpsUseful := 0;
    FViewport.Invalidate;
    if FOffscreen.Grab(GrabDone(FMaking, FScanId)) then
      Exit;   // FGrabTimer runs on for this try
    LogError('Assets: can''t start the thumbnail of ' + FEntries[FMaking].Meta.Name + ' again');
  end;
  FGrabTimer.Enabled := False;
  LogError(Format('Assets: no thumbnail for %s: the grab had not come back after %d tries; ' +
    'passed over', [FEntries[FMaking].Meta.FileName, FGrabTries]));
  FMaking := -1;
  FreeModel;
  MakeNextLater;
end;

procedure TAssetsForm.FrameModel(const AWidth, AHeight: Single);
begin
  if (FModel = nil) or (AWidth <= 0) or (AHeight <= 0) then
    Exit;
  // As Sprite3D fits a model: the volume its box sweeps turning about the
  // up axis through its centre of rotation, framed with the camera's
  // target on that axis
  FitCameraToSweep(FCamera.Camera, FModel,
    CalcSweptVolume(FModelBox, FModel.RotationCenter.Point, saY), AWidth, AHeight,
    THUMBNAIL_MARGIN);
end;

procedure TAssetsForm.OffscreenBeforeGrab(Sender: TObject; const AWidth,
  AHeight: Integer);
begin
  FrameModel(AWidth, AHeight);
end;

function TAssetsForm.GrabDone(const AIndex, AScanId: Integer): TSprite3DGrabProc;
var
  Alive: IAssetsAlive;
begin
  Alive := FAlive;
  Result :=
    procedure(const ABitmap: TBitmap; const AError: String)
    begin
      if Alive.Alive then
        ThumbnailGrabbed(AIndex, AScanId, ABitmap, AError);
    end;
end;

procedure TAssetsForm.ThumbnailGrabbed(const AIndex, AScanId: Integer;
  const ABitmap: TBitmap; const AError: String);
begin
  if AIndex = FMaking then
    FGrabTimer.Enabled := False;
  DebugLog('grabbed ' + IfThen(ABitmap <> nil, 'an image', 'nothing: ' + AError) +
    IfThen(FGrabTries > 1, Format(' at try %d', [FGrabTries]), ''));
  if (AScanId <> FScanId) or (AIndex <> FMaking) or (AIndex > High(FEntries)) then
    Exit;   // stopped, or another folder opened, since it was started
  // For the Debug tab: what was framed and how, to check a thumbnail by
  Log(Format('Assets: %s box (%.3f, %.3f, %.3f) to (%.3f, %.3f, %.3f), distance %.3f, ' +
    'ortho height %.3f', [FEntries[AIndex].Meta.Name, FModelBox.Left, FModelBox.Top,
    FModelBox.Near, FModelBox.Right, FModelBox.Bottom, FModelBox.Far,
    FCamera.Camera.Distance, FCamera.Camera.OrthoHeight]));
  if ABitmap = nil then
    LogError('Assets: no thumbnail for ' + FEntries[AIndex].Meta.Name + ': ' + AError)
  else
    try
      ForceDirectories(AssetKeyFolder(FCacheFolder, FEntries[AIndex].Meta.Hash));
      ABitmap.SaveToFile(AssetThumbnailFile(FCacheFolder, FEntries[AIndex].Meta.Hash));
      FEntries[AIndex].Meta.ThumbWidth := ABitmap.Width;
      FEntries[AIndex].Meta.ThumbHeight := ABitmap.Height;
      FEntries[AIndex].Meta.View := THUMBNAIL_VIEW;
      FEntries[AIndex].Meta.Created := DateToISO8601(Now, False);
      FEntries[AIndex].Meta.Textures := TEXTURE_RULES_VERSION;
      SaveAssetMeta(FCacheFolder, FEntries[AIndex].Meta);
      FEntries[AIndex].HasThumbnail := True;
      Inc(FMadeCount);
      if FEntries[AIndex].Image <> nil then
        FEntries[AIndex].Image.Bitmap.Assign(ABitmap);
      if AIndex = FSelected then
        SelectEntry(AIndex);   // its size is known now
    except
      on E: Exception do
        LogError('Assets: can''t save the thumbnail of ' + FEntries[AIndex].Meta.Name +
          ' in ' + FCacheFolder + ': ' + E.Message);
    end;
  MakeNextLater;
end;

function TAssetsForm.CanTurnPreview: Boolean;
begin
  Result := not Making and (FModel <> nil) and (FPreviewIndex >= 0);
end;

procedure TAssetsForm.PreviewMouseDown(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Single);
begin
  if not CanTurnPreview then
    Exit;
  // A Control-click counts as a right-click, for a Mac with one button
  if (Button = TMouseButton.mbRight) or
    ((Button = TMouseButton.mbLeft) and (ssCtrl in Shift)) then
  begin
    FTurning := False;
    ResetCameraAngles;
    FrameModel(FViewport.Width, FViewport.Height);
  end
  else if Button = TMouseButton.mbLeft then
  begin
    FTurning := True;
    FTurnLast := TPointF.Create(X, Y);
  end;
end;

procedure TAssetsForm.PreviewMouseMove(Sender: TObject; Shift: TShiftState; X, Y: Single);
var
  DX, DY: Single;
begin
  if not FTurning then
    Exit;
  // Let go where the preview could not see it: the first move without the
  // button ends the turn
  if not CanTurnPreview or not (ssLeft in Shift) then
  begin
    FTurning := False;
    Exit;
  end;
  DX := X - FTurnLast.X;
  DY := Y - FTurnLast.Y;
  FTurnLast := TPointF.Create(X, Y);
  // The camera turns about the model's own axis, where the fit put its
  // target. Its own Azimuth runs the other way to the azimuth the views
  // show (ApplyAngles in the main form reverses it), so adding the move
  // turns the model with the pointer, as the main form's mouse view does
  if DX <> 0 then
    FCamera.Camera.Azimuth := FCamera.Camera.Azimuth + DX * PREVIEW_DEGREES_PER_PIXEL;
  // The camera's gimbals let the tilt go right round, over the top and
  // under, with no lock, so it is only kept within a turn
  if DY <> 0 then
    FCamera.Camera.PolarAngle := Wrap360(FCamera.Camera.PolarAngle +
      DY * PREVIEW_DEGREES_PER_PIXEL);
end;

procedure TAssetsForm.PreviewMouseUp(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Single);
begin
  if Button = TMouseButton.mbLeft then
    FTurning := False;
end;

procedure TAssetsForm.PreviewMouseWheel(Sender: TObject; Shift: TShiftState;
  WheelDelta: Integer; var Handled: Boolean);
var
  Zoom: Single;
begin
  if not CanTurnPreview then
    Exit;
  Handled := True;
  // Away from you nearer, towards you further; in orthographic projection
  // the size of the view is what zooms, not the distance
  Zoom := Power(PREVIEW_ZOOM_STEP, -WheelDelta / 120);
  FCamera.Camera.OrthoHeight := FCamera.Camera.OrthoHeight * Zoom;
  if FCamera.Camera.OrthoWidth > 0 then
    FCamera.Camera.OrthoWidth := FCamera.Camera.OrthoWidth * Zoom;
end;

end.
