//** @abstract(The Creator Credits dialog of File, Save Project: who made a sprite set, and when
//** it was started.)
//**
//** Six boxes take the creator, the modeller and the artist, each with a URL for their work,
//** and a date box the day the project started, today if it was not set. The dialog only
//** edits its own copy: set Credits before showing it and read it back after OK; keeping
//** and saving the credits is the caller's job. Text is trimmed, and nothing is required.
//**
//** On the desktop, show it with ShowModal; on Android and iOS, which cannot block, show it
//** with ShowAndFree, which calls OnAccept on OK and frees the form when it closes. For the
//** main thread only.
unit Sprite3DCreditsForm;

{
  The Creator Credits dialog of File, Save Project: who made a sprite set,
  and when it was started.

  Six boxes take the creator, the modeller and the artist, each with a URL
  for their work, and a date box the day the project started, today if it
  was not set. The dialog only edits its own copy: set Credits before
  showing it and read it back after OK; keeping and saving the credits is
  the caller's job. Text is trimmed, and nothing is required.

  On the desktop, show it with ShowModal; on Android and iOS, which cannot
  block, show it with ShowAndFree, which calls OnAccept on OK and frees the
  form when it closes. For the main thread only.
}

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, FMX.Types,
  FMX.Controls, FMX.Forms, FMX.Graphics, FMX.StdCtrls, FMX.Edit, FMX.DateTimeCtrls,
  FMX.Controls.Presentation, FMX.Layouts, Sprite3DHelpers;

type
  //** @abstract(The Creator Credits dialog; see the unit description.)
  /// <summary>The Creator Credits dialog; see the unit description.</summary>
  TCreditsForm = class(TForm)
    //** @abstract(Names CreatorEdit.)
    /// <summary>Names CreatorEdit.</summary>
    CreatorLabel: TLabel;
    //** @abstract(Who created the sprite set.)
    /// <summary>Who created the sprite set.</summary>
    CreatorEdit: TEdit;
    //** @abstract(Names CreatorUrlEdit.)
    /// <summary>Names CreatorUrlEdit.</summary>
    CreatorUrlLabel: TLabel;
    //** @abstract(Where the creator's work is.)
    /// <summary>Where the creator's work is.</summary>
    CreatorUrlEdit: TEdit;
    //** @abstract(Names ModellerEdit.)
    /// <summary>Names ModellerEdit.</summary>
    ModellerLabel: TLabel;
    //** @abstract(Who made the models.)
    /// <summary>Who made the models.</summary>
    ModellerEdit: TEdit;
    //** @abstract(Names ModellerUrlEdit.)
    /// <summary>Names ModellerUrlEdit.</summary>
    ModellerUrlLabel: TLabel;
    //** @abstract(Where the modeller's work is.)
    /// <summary>Where the modeller's work is.</summary>
    ModellerUrlEdit: TEdit;
    //** @abstract(Names ArtistEdit.)
    /// <summary>Names ArtistEdit.</summary>
    ArtistLabel: TLabel;
    //** @abstract(Who made the textures.)
    /// <summary>Who made the textures.</summary>
    ArtistEdit: TEdit;
    //** @abstract(Names ArtistUrlEdit.)
    /// <summary>Names ArtistUrlEdit.</summary>
    ArtistUrlLabel: TLabel;
    //** @abstract(Where the artist's work is.)
    /// <summary>Where the artist's work is.</summary>
    ArtistUrlEdit: TEdit;
    //** @abstract(Names CreatedDate.)
    /// <summary>Names CreatedDate.</summary>
    CreatedLabel: TLabel;
    //** @abstract(The day the project started.)
    /// <summary>The day the project started.</summary>
    CreatedDate: TDateEdit;
    //** @abstract(The strip holding the Cancel and OK buttons.)
    /// <summary>The strip holding the Cancel and OK buttons.</summary>
    ButtonLayout: TLayout;
    //** @abstract(Closes the dialog with mrOk.)
    /// <summary>Closes the dialog with mrOk.</summary>
    OkButton: TButton;
    //** @abstract(Closes the dialog with mrCancel, keeping none of the changes.)
    /// <summary>Closes the dialog with mrCancel, keeping none of the changes.</summary>
    CancelButton: TButton;
    //** @abstract(Starts with empty credits and today's date.)
    //**
    //** @param(Sender The form.)
    /// <summary>Starts with empty credits and today's date.</summary>
    /// <param name="Sender">The form.</param>
    procedure FormCreate(Sender: TObject);
    //** @abstract(Closes the dialog with the button's ModalResult.)
    //**
    //** @param(Sender OkButton or CancelButton.)
    /// <summary>Closes the dialog with the button's ModalResult.</summary>
    /// <param name="Sender">OkButton or CancelButton.</param>
    procedure ButtonClick(Sender: TObject);
    //** @abstract(Reports OK when shown with ShowAndFree, and frees the form then.)
    //**
    //** @param(Sender The form.)
    //**
    //** @param(Action Set to caFree when shown with ShowAndFree.)
    /// <summary>Reports OK when shown with ShowAndFree, and frees the form then.</summary>
    /// <param name="Sender">The form.</param>
    /// <param name="Action">Set to caFree when shown with ShowAndFree.</param>
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
  private
    FFreeOnClose: Boolean;
    FOnAccept: TNotifyEvent;
    function GetCredits: TSprite3DCredits;
    procedure SetCredits(const Value: TSprite3DCredits);
  public
    //** @abstract(Shows the dialog without blocking and frees it when it closes.)
    //**
    //** For Android and iOS, where ShowModal cannot block. OnAccept is called if it closes
    //** with OK.
    /// <summary>Shows the dialog without blocking and frees it when it closes.</summary>
    /// <remarks>For Android and iOS, where ShowModal cannot block. OnAccept is called if it
    /// closes with OK.</remarks>
    procedure ShowAndFree;
    //** @abstract(The credits shown; read them after OK.)
    //**
    //** Written, a Created that is not a @code(yyyy-mm-dd) date shows as today. Read, the
    //** text is trimmed and Created is the date shown, as @code(yyyy-mm-dd).
    /// <summary>The credits shown; read them after OK.</summary>
    /// <remarks>Written, a Created that is not a <c>yyyy-mm-dd</c> date shows as today. Read,
    /// the text is trimmed and Created is the date shown, as <c>yyyy-mm-dd</c>.</remarks>
    property Credits: TSprite3DCredits read GetCredits write SetCredits;
    //** @abstract(Called on OK when shown with ShowAndFree.)
    /// <summary>Called on OK when shown with ShowAndFree.</summary>
    property OnAccept: TNotifyEvent read FOnAccept write FOnAccept;
  end;

implementation

uses
  System.DateUtils;

{$R *.fmx}

procedure TCreditsForm.FormCreate(Sender: TObject);
begin
  CreatedDate.Date := Date;
end;

function TCreditsForm.GetCredits: TSprite3DCredits;
begin
  Result.Creator := CreatorEdit.Text.Trim;
  Result.CreatorUrl := CreatorUrlEdit.Text.Trim;
  Result.Modeller := ModellerEdit.Text.Trim;
  Result.ModellerUrl := ModellerUrlEdit.Text.Trim;
  Result.Artist := ArtistEdit.Text.Trim;
  Result.ArtistUrl := ArtistUrlEdit.Text.Trim;
  Result.Created := FormatDateTime('yyyy"-"mm"-"dd', CreatedDate.Date);
end;

procedure TCreditsForm.SetCredits(const Value: TSprite3DCredits);
var
  Day: TDateTime;
begin
  CreatorEdit.Text := Value.Creator;
  CreatorUrlEdit.Text := Value.CreatorUrl;
  ModellerEdit.Text := Value.Modeller;
  ModellerUrlEdit.Text := Value.ModellerUrl;
  ArtistEdit.Text := Value.Artist;
  ArtistUrlEdit.Text := Value.ArtistUrl;
  // yyyy-mm-dd, as ISO 8601 has it; anything else is today
  if not TryISO8601ToDate(Value.Created, Day, False) then
    Day := Date;
  CreatedDate.Date := DateOf(Day);
end;

procedure TCreditsForm.ButtonClick(Sender: TObject);
begin
  if FFreeOnClose then
  begin
    ModalResult := TButton(Sender).ModalResult;
    Close;
  end;
  // Otherwise ShowModal closes the dialog itself, from the button's ModalResult
end;

procedure TCreditsForm.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  if not FFreeOnClose then
    Exit;   // shown with ShowModal: the caller frees it
  if (ModalResult = mrOk) and Assigned(FOnAccept) then
    FOnAccept(Self);
  Action := TCloseAction.caFree;
end;

procedure TCreditsForm.ShowAndFree;
begin
  FFreeOnClose := True;
  Show;
end;

end.
