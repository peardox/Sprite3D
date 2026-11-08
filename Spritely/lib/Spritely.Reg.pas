//** @abstract(Registers the Spritely components on the Spritely page of the IDE's palette.)
//**
//** Design-time only: it goes in the dclSpritely design package, never in a program. The
//** palette icons come from Spritely.Reg.dcr beside it, made from lib/icons by
//** tools/gen_icon_res.py; never edit the .dcr by hand.
//**
//** The components need FireMonkey and Gorilla3D, so they are grouped with TFmxObject and
//** show on the palette only while an FMX form or frame is being designed. Nothing here needs
//** the Lenticular components: either set may be installed without the other.
unit Spritely.Reg;

{
  Registers the Spritely components on the Spritely page of the IDE's
  palette.

  Design-time only: it goes in the dclSpritely design package, never in a
  program. The palette icons come from Spritely.Reg.dcr beside it, made
  from lib/icons by tools/gen_icon_res.py; never edit the .dcr by hand.

  The components need FireMonkey and Gorilla3D, so they are grouped with
  TFmxObject and show on the palette only while an FMX form or frame is
  being designed. Nothing here needs the Lenticular components.
}

interface

//** @abstract(Called by the IDE when the design package is installed: puts every Spritely
//** component on the Spritely page.)
procedure Register;

implementation

{$R Spritely.Reg.dcr}

uses
  System.Classes, FMX.Types,
  Spritely.OrbitalCamera, Spritely.Projection;

const
  //** @abstract(The palette page, the component group, the components appear on.)
  SPRITELY_PALETTE_PAGE = 'Spritely';

procedure Register;
begin
  // FMX-only: hidden from the palette while a VCL form is designed
  GroupDescendentsWith(TSpritelyOrbitalCamera, TFmxObject);
  GroupDescendentsWith(TSpritelyProjection, TFmxObject);
  RegisterComponents(SPRITELY_PALETTE_PAGE, [TSpritelyOrbitalCamera, TSpritelyProjection]);
end;

end.
