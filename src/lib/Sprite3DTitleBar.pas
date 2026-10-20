//** @abstract(Colours the windows' title bars to go with the application's FMX style, where
//** the operating system allows it.)
//**
//** SetTitleBarSpec stores how title bars should look and applies it at once to every form
//** on screen; forms shown later get it as they are shown. TitleBarSpecFromStyle works out a
//** spec from the FMX style in use, taking the colour of its form background.
//**
//** @preformatted(
//** Windows 11   caption, caption text and border colours @(DWM@)
//** Windows 10   dark or light title bar only @(DWM immersive dark mode, build 17763 on@)
//** macOS 10.14  dark or light appearance for the whole application @(NSApp.appearance@)
//** Linux        nothing: the window manager draws the title bar
//** Android, iOS nothing: there is no title bar
//** )
//**
//** Where only dark or light is possible, a caption colour darker than mid grey gives dark.
//** Calls on a system without the feature are ignored. The unit knows nothing of any
//** particular application. Call it on the main thread only.
unit Sprite3DTitleBar;

{
  Colours the windows' title bars to go with the application's FMX style,
  where the operating system allows it.

  SetTitleBarSpec stores how title bars should look and applies it at once
  to every form on screen; forms shown later get it as they are shown.
  TitleBarSpecFromStyle works out a spec from the FMX style in use, taking
  the colour of its form background.

    Windows 11   caption, caption text and border colours (DWM)
    Windows 10   dark or light title bar only (DWM immersive dark mode,
                 build 17763 on)
    macOS 10.14  dark or light appearance for the whole application
                 (NSApp.appearance)
    Linux        nothing: the window manager draws the title bar
    Android, iOS nothing: there is no title bar

  Where only dark or light is possible, a caption colour darker than mid
  grey gives dark. Calls on a system without the feature are ignored. The
  unit knows nothing of any particular application. Call it on the main
  thread only.
}

// Delphi also defines MACOS for iOS; this names the desktop system only
{$IF DEFINED(MACOS) and not DEFINED(IOS)}
  {$DEFINE S3D_DESKTOP_MACOS}
{$ENDIF}

interface

uses
  System.UITypes, FMX.Forms;

type
  //** @abstract(How title bars should look.)
  /// <summary>How title bars should look.</summary>
  TSprite3DTitleBarSpec = record
    //** @abstract(True to leave title bars as the system draws them; the colours are then
    //** ignored.)
    /// <summary>True to leave title bars as the system draws them; the colours are then
    /// ignored.</summary>
    UseSystem: Boolean;
    //** @abstract(The caption's background colour; its brightness also picks dark or light
    //** where colours are not possible.)
    /// <summary>The caption's background colour; its brightness also picks dark or light where
    /// colours are not possible.</summary>
    Caption: TAlphaColor;
    //** @abstract(The caption text's colour.)
    /// <summary>The caption text's colour.</summary>
    Text: TAlphaColor;
    //** @abstract(The window border's colour, or TAlphaColors.Null for the system's.)
    /// <summary>The window border's colour, or TAlphaColors.Null for the system's.</summary>
    Border: TAlphaColor;
    //** @abstract(A spec that leaves title bars to the system.)
    //**
    //** @returns(The spec, with UseSystem True.)
    /// <summary>A spec that leaves title bars to the system.</summary>
    /// <returns>The spec, with UseSystem True.</returns>
    class function System: TSprite3DTitleBarSpec; static;
    //** @abstract(A spec with ACaption behind the caption, text in black or white, whichever
    //** reads better, and ABorder round the window.)
    //**
    //** @param(ACaption The caption's background colour.)
    //**
    //** @param(ABorder The border's colour; TAlphaColors.Null for the system's.)
    //**
    //** @returns(The spec.)
    /// <summary>A spec with ACaption behind the caption, text in black or white, whichever
    /// reads better, and ABorder round the window.</summary>
    /// <param name="ACaption">The caption's background colour.</param>
    /// <param name="ABorder">The border's colour; TAlphaColors.Null for the system's.</param>
    /// <returns>The spec.</returns>
    class function Coloured(const ACaption: TAlphaColor;
      const ABorder: TAlphaColor = TAlphaColors.Null): TSprite3DTitleBarSpec; static;
    //** @abstract(True if Caption is darker than mid grey.)
    //**
    //** @returns(Whether a dark title bar suits the caption colour.)
    /// <summary>True if Caption is darker than mid grey.</summary>
    /// <returns>Whether a dark title bar suits the caption colour.</returns>
    function IsDark: Boolean;
  end;

//** @abstract(The colour of the form background in the FMX style in use.)
//**
//** Reads the @code(backgroundstyle) resource that every FMX style draws behind a form; for a
//** gradient, its first colour.
//**
//** @param(AColour The colour found; unchanged if none is.)
//**
//** @returns(True if the style has a background with a colour.)
/// <summary>The colour of the form background in the FMX style in use.</summary>
/// <remarks>Reads the <c>backgroundstyle</c> resource that every FMX style draws behind a form;
/// for a gradient, its first colour.</remarks>
/// <param name="AColour">The colour found; unchanged if none is.</param>
/// <returns>True if the style has a background with a colour.</returns>
function StyleBackgroundColour(var AColour: TAlphaColor): Boolean;

//** @abstract(A title bar spec to go with the FMX style in use.)
//**
//** The caption takes the style's form background colour, as StyleBackgroundColour reads it,
//** or AFallback if the style has none.
//**
//** @param(AFallback The caption colour to use if the style's cannot be read.)
//**
//** @param(ABorder The border colour, often the style's accent; TAlphaColors.Null for the
//** system's.)
//**
//** @returns(The spec.)
/// <summary>A title bar spec to go with the FMX style in use.</summary>
/// <remarks>The caption takes the style's form background colour, as StyleBackgroundColour
/// reads it, or AFallback if the style has none.</remarks>
/// <param name="AFallback">The caption colour to use if the style's cannot be read.</param>
/// <param name="ABorder">The border colour, often the style's accent; TAlphaColors.Null for
/// the system's.</param>
/// <returns>The spec.</returns>
function TitleBarSpecFromStyle(const AFallback: TAlphaColor;
  const ABorder: TAlphaColor = TAlphaColors.Null): TSprite3DTitleBarSpec;

//** @abstract(Makes ASpec the look of every title bar, now and for forms shown later.)
//**
//** @param(ASpec How title bars should look.)
/// <summary>Makes ASpec the look of every title bar, now and for forms shown later.</summary>
/// <param name="ASpec">How title bars should look.</param>
procedure SetTitleBarSpec(const ASpec: TSprite3DTitleBarSpec);

//** @abstract(Gives one form's title bar the current spec.)
//**
//** SetTitleBarSpec already does this for every form; call it only for a form whose window
//** has been made again. A form whose window does not exist yet is skipped.
//**
//** @param(AForm The form.)
/// <summary>Gives one form's title bar the current spec.</summary>
/// <remarks>SetTitleBarSpec already does this for every form; call it only for a form whose
/// window has been made again. A form whose window does not exist yet is skipped.</remarks>
/// <param name="AForm">The form.</param>
procedure ApplyTitleBar(const AForm: TCommonCustomForm);

implementation

uses
  System.Classes, System.Messaging, FMX.Types, FMX.Graphics, FMX.Objects, FMX.Styles
  {$IF DEFINED(MSWINDOWS)}
  , Winapi.Windows, FMX.Platform.Win
  {$ENDIF}
  ;

var
  GSpec: TSprite3DTitleBarSpec;
  GSubscribed: Boolean;
  GSubscriptionId: Integer;

{ TSprite3DTitleBarSpec }

class function TSprite3DTitleBarSpec.System: TSprite3DTitleBarSpec;
begin
  Result.UseSystem := True;
  Result.Caption := TAlphaColors.White;
  Result.Text := TAlphaColors.Black;
  Result.Border := TAlphaColors.Null;
end;

class function TSprite3DTitleBarSpec.Coloured(const ACaption,
  ABorder: TAlphaColor): TSprite3DTitleBarSpec;
begin
  Result.UseSystem := False;
  Result.Caption := ACaption or TAlphaColors.Black;   // opaque
  Result.Border := ABorder;
  if Result.IsDark then
    Result.Text := TAlphaColors.White
  else
    Result.Text := TAlphaColors.Black;
end;

function TSprite3DTitleBarSpec.IsDark: Boolean;
var
  C: TAlphaColorRec;
begin
  C.Color := Caption;
  // Perceived brightness, ITU-R BT.601 weights, on 0..255
  Result := (0.299 * C.R + 0.587 * C.G + 0.114 * C.B) < 128;
end;

function StyleBackgroundColour(var AColour: TAlphaColor): Boolean;
var
  Style, Resource: TFmxObject;
  Brush: TBrush;
begin
  Result := False;
  Style := TStyleManager.ActiveStyle(nil);
  if Style = nil then
    Exit;
  Resource := Style.FindStyleResource('backgroundstyle');
  if not (Resource is TShape) then
    Exit;
  Brush := TShape(Resource).Fill;
  case Brush.Kind of
    TBrushKind.Solid:
      begin
        AColour := Brush.Color;
        Result := True;
      end;
    TBrushKind.Gradient:
      if Brush.Gradient.Points.Count > 0 then
      begin
        AColour := Brush.Gradient.Points[0].Color;
        Result := True;
      end;
  end;
end;

function TitleBarSpecFromStyle(const AFallback, ABorder: TAlphaColor): TSprite3DTitleBarSpec;
var
  Colour: TAlphaColor;
begin
  Colour := AFallback;
  StyleBackgroundColour(Colour);
  Result := TSprite3DTitleBarSpec.Coloured(Colour, ABorder);
end;

{$IF DEFINED(MSWINDOWS)}
{ ---------------------------------------------------------------- Windows }

const
  DWMWA_USE_IMMERSIVE_DARK_MODE_OLD = 19;   // Windows 10 1809 to 1909
  DWMWA_USE_IMMERSIVE_DARK_MODE = 20;       // Windows 10 2004 on
  DWMWA_BORDER_COLOR = 34;                  // Windows 11 on
  DWMWA_CAPTION_COLOR = 35;
  DWMWA_TEXT_COLOR = 36;
  DWMWA_COLOR_DEFAULT = $FFFFFFFF;

function DwmSetWindowAttribute(AWnd: HWND; AAttribute: DWORD; AValue: Pointer;
  ASize: DWORD): HRESULT; stdcall; external 'dwmapi.dll' name 'DwmSetWindowAttribute';

// TAlphaColor is $AARRGGBB; a COLORREF is $00BBGGRR
function ToColorRef(const AColour: TAlphaColor): DWORD;
var
  C: TAlphaColorRec;
begin
  C.Color := AColour;
  Result := DWORD(C.R) or (DWORD(C.G) shl 8) or (DWORD(C.B) shl 16);
end;

procedure SetDword(const AWnd: HWND; const AAttribute, AValue: DWORD);
var
  Value: DWORD;
begin
  Value := AValue;
  // Fails harmlessly where the attribute is unknown, as on older versions
  DwmSetWindowAttribute(AWnd, AAttribute, @Value, SizeOf(Value));
end;

procedure ApplyToWindow(const AWnd: HWND);
var
  Dark: BOOL;
begin
  if AWnd = 0 then
    Exit;
  Dark := not GSpec.UseSystem and GSpec.IsDark;
  if DwmSetWindowAttribute(AWnd, DWMWA_USE_IMMERSIVE_DARK_MODE, @Dark, SizeOf(Dark)) <> S_OK then
    DwmSetWindowAttribute(AWnd, DWMWA_USE_IMMERSIVE_DARK_MODE_OLD, @Dark, SizeOf(Dark));
  if GSpec.UseSystem then
  begin
    SetDword(AWnd, DWMWA_CAPTION_COLOR, DWMWA_COLOR_DEFAULT);
    SetDword(AWnd, DWMWA_TEXT_COLOR, DWMWA_COLOR_DEFAULT);
    SetDword(AWnd, DWMWA_BORDER_COLOR, DWMWA_COLOR_DEFAULT);
  end
  else
  begin
    SetDword(AWnd, DWMWA_CAPTION_COLOR, ToColorRef(GSpec.Caption));
    SetDword(AWnd, DWMWA_TEXT_COLOR, ToColorRef(GSpec.Text));
    if GSpec.Border = TAlphaColors.Null then
      SetDword(AWnd, DWMWA_BORDER_COLOR, DWMWA_COLOR_DEFAULT)
    else
      SetDword(AWnd, DWMWA_BORDER_COLOR, ToColorRef(GSpec.Border));
  end;
end;

procedure ApplyTitleBar(const AForm: TCommonCustomForm);
begin
  if (AForm = nil) or (AForm.Handle = nil) then
    Exit;
  ApplyToWindow(FormToHWND(AForm));
end;

procedure ApplyToApplication;
begin
  // Each window carries its own attributes; see ApplyTitleBar
end;

{$ELSEIF DEFINED(S3D_DESKTOP_MACOS)}
{ ------------------------------------------------------------------ macOS }

const
  libobjc = '/usr/lib/libobjc.A.dylib';

// Typed, non-variadic entry points for objc_msgSend, as arm64 needs
function objc_getClass(AName: MarshaledAString): Pointer; cdecl;
  external libobjc name 'objc_getClass';
function sel_registerName(AName: MarshaledAString): Pointer; cdecl;
  external libobjc name 'sel_registerName';
function MsgSend0(AObject, ASelector: Pointer): Pointer; cdecl;
  external libobjc name 'objc_msgSend';
function MsgSend1(AObject, ASelector, AArg: Pointer): Pointer; cdecl;
  external libobjc name 'objc_msgSend';
function MsgSendBool1(AObject, ASelector, AArg: Pointer): Byte; cdecl;
  external libobjc name 'objc_msgSend';

function NSStringOf(const AText: UTF8String): Pointer;
begin
  Result := MsgSend1(objc_getClass('NSString'), sel_registerName('stringWithUTF8String:'),
    PAnsiChar(AText));
end;

// The appearance is set for the whole application, so every window's title
// bar follows it, those not yet made included
procedure ApplyToApplication;
var
  App, SetSel, Appearance: Pointer;
begin
  App := MsgSend0(objc_getClass('NSApplication'), sel_registerName('sharedApplication'));
  SetSel := sel_registerName('setAppearance:');
  if (App = nil) or
    (MsgSendBool1(App, sel_registerName('respondsToSelector:'), SetSel) = 0) then
    Exit;   // before macOS 10.14
  if GSpec.UseSystem then
    Appearance := nil   // follow the system's light or dark setting
  else if GSpec.IsDark then
    Appearance := MsgSend1(objc_getClass('NSAppearance'),
      sel_registerName('appearanceNamed:'), NSStringOf('NSAppearanceNameDarkAqua'))
  else
    Appearance := MsgSend1(objc_getClass('NSAppearance'),
      sel_registerName('appearanceNamed:'), NSStringOf('NSAppearanceNameAqua'));
  MsgSend1(App, SetSel, Appearance);
end;

procedure ApplyTitleBar(const AForm: TCommonCustomForm);
begin
  // The application's appearance covers every window
end;

{$ELSE}
{ --------------------------------------------- Linux, Android and iOS }

procedure ApplyToApplication;
begin
end;

procedure ApplyTitleBar(const AForm: TCommonCustomForm);
begin
end;

{$ENDIF}

procedure FormShown(const Sender: TObject; const M: TMessage);
begin
  if M is TFormBeforeShownMessage then
    ApplyTitleBar(TFormBeforeShownMessage(M).Value)
  else if Sender is TCommonCustomForm then
    ApplyTitleBar(TCommonCustomForm(Sender));
end;

procedure SetTitleBarSpec(const ASpec: TSprite3DTitleBarSpec);
var
  I: Integer;
begin
  GSpec := ASpec;
  if not GSubscribed then
  begin
    // Forms shown from now on; the message comes once the window exists
    GSubscriptionId := TMessageManager.DefaultManager.SubscribeToMessage(
      TFormBeforeShownMessage, FormShown);
    GSubscribed := True;
  end;
  ApplyToApplication;
  for I := 0 to Screen.FormCount - 1 do
    ApplyTitleBar(Screen.Forms[I]);
end;

initialization
  GSpec := TSprite3DTitleBarSpec.System;

finalization
  if GSubscribed then
    TMessageManager.DefaultManager.Unsubscribe(TFormBeforeShownMessage, GSubscriptionId);

end.
