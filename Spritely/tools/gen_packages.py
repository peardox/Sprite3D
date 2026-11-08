#!/usr/bin/env python3
"""Writes the Spritely component packages (packages/).

    python3 tools/gen_packages.py [--force]

Standard library only. The packages, as G3DGames/TSteamAPI builds its own
(this began as a cut-down copy of its tools/gen_projects.py). One set of
components, in a runtime and a design package. This copy lives in
peardox/Sprite3D, which owns Spritely from 8 November 2026; it was cut
down from peardox/SRDelphiFMX's script, which also wrote the Lenticular
packages, and writes the same Spritely files.

  Spritely      runtime: the camera and projection components (Gorilla3D).
  dclSpritely   design time: lib/Spritely.Reg.pas, which registers them on
                the Spritely page of the palette.

The design package is Win32 and Win64 (the owner's IDE is the 32-bit one).

A runtime package's DCUs go to Delphi's Dcp folder,
$(BDSCOMMONDIR)\\Dcp\\<platform> (\\Dcp alone for Win32), next to its .dcp
on the IDE's default Library path, so a program that uses one of these
components needs no search path at all.

The .dpk files are always rewritten from the tables below; edit this
script, not them. A .dproj is written only when it is missing, because the
IDE re-saves .dproj files and that copy is then the one that counts;
--force overwrites them too (discarding the IDE's changes - check them in
the IDE afterwards). Every unit lib/Spritely.<Name>.pas must be in exactly
one package (the *.Reg units in the design package), or be listed in
SOURCE_ONLY. The script stops if one is missing or listed twice, so a new
component cannot be left out.
"""
import os
import re
import sys
import uuid

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
PKG_DIR = os.path.join(ROOT, "packages")

# Gorilla3D's runtime package for Delphi 13, as the IDE lists it in the
# programs' DCC_UsePackage; installed for every platform below (WinARM64EC
# too from 8 November 2026)
GORILLA = "Gorilla3D_Delphi_13_2_0_Florence"
RUNTIME_PLATFORMS = ["Win32", "Win64", "OSX64", "OSXARM64", "Linux64",
                     "Android", "Android64", "iOSDevice64", "iOSSimARM64", "WinARM64EC"]
DESIGN_PLATFORMS = ["Win32", "Win64"]
# Every platform a .dproj lists, ticked or not
ALL_PLATFORMS = RUNTIME_PLATFORMS

SPRITELY_UNITS = ["Spritely.Projection", "Spritely.OrbitalCamera"]

NS_BASE = "System;Xml;Data;Datasnap;Web;Soap"
NS_WIN = "Winapi;System.Win;Data.Win;Datasnap.Win;Web.Win;Soap.Win;Xml.Win"

PACKAGES = [
    dict(name="Spritely", set="Spritely", kind="runtime", platforms=RUNTIME_PLATFORMS,
         default="Win64", requires=["rtl", "fmx", GORILLA], units=SPRITELY_UNITS, extra=[],
         description="Spritely components for FireMonkey and Gorilla3D - runtime"),
    dict(name="dclSpritely", set="Spritely", kind="design", platforms=DESIGN_PLATFORMS,
         default="Win32", requires=["rtl", "fmx", "designide", "Spritely"],
         units=["Spritely.Reg"], extra=[],
         description="Spritely components for FireMonkey and Gorilla3D - design time"),
]
# The prefix of every unit, and so of every package, of each set
SETS = ("Spritely",)

# Units of the set in lib that are in no package; none at present. Listed
# so a new component unit still cannot be left out of the packages by
# mistake.
SOURCE_ONLY = []


def set_of(unit):
    """The set a unit belongs to, by its name, or None."""
    for s in SETS:
        if unit.split(".")[0].startswith(s):
            return s
    return None


def check_units():
    """Every lib/<Set>.*.pas is in exactly one package of its own set, the *.Reg units in a
    design one, and no package requires the other set's."""
    found = sorted(f[:-4] for f in os.listdir(os.path.join(ROOT, "lib"))
                   if f.endswith(".pas") and set_of(f[:-4]) is not None)
    listed = [u for p in PACKAGES for u in p["units"]]
    msg = []
    missing = [u for u in found if u not in listed and u not in SOURCE_ONLY]
    absent = [u for u in SOURCE_ONLY if u not in found]
    if absent:
        msg.append("SOURCE_ONLY lists units not in lib: " + ", ".join(absent))
    both = [u for u in SOURCE_ONLY if u in listed]
    if both:
        msg.append("in a package and in SOURCE_ONLY: " + ", ".join(both))
    if missing:
        msg.append("in lib but in no package: " + ", ".join(missing))
    twice = sorted({u for u in listed if listed.count(u) > 1})
    if twice:
        msg.append("in more than one package: " + ", ".join(twice))
    gone = [u for u in listed if u not in found]
    if gone:
        msg.append("listed but not in lib: " + ", ".join(gone))
    misplaced = [u for p in PACKAGES for u in p["units"]
                 if u.endswith(".Reg") != (p["kind"] == "design")]
    if misplaced:
        msg.append("registration units belong in design packages only: " + ", ".join(misplaced))
    wrong_set = [f"{u} (in {p['name']})" for p in PACKAGES for u in p["units"]
                 if set_of(u) != p["set"]]
    if wrong_set:
        msg.append("in the other set's package: " + ", ".join(wrong_set))
    crossed = [f"{p['name']} requires {r}" for p in PACKAGES for r in p["requires"]
               for q in PACKAGES if q["name"] == r and q["set"] != p["set"]]
    if crossed:
        msg.append("the sets must not need each other: " + ", ".join(crossed))
    if msg:
        sys.exit("gen_packages.py: " + "; ".join(msg))


def existing_guid(path):
    if os.path.exists(path):
        m = re.search(r"<ProjectGuid>(\{[0-9A-Fa-f-]+\})</ProjectGuid>",
                      open(path, encoding="utf-8-sig").read())
        if m:
            return m.group(1)
    return "{" + str(uuid.uuid4()).upper() + "}"


def write(path, text, bom):
    data = (b"\xef\xbb\xbf" if bom else b"") + text.replace("\n", "\r\n").encode("ascii")
    old = open(path, "rb").read() if os.path.exists(path) else None
    if old != data:
        open(path, "wb").write(data)
        print("wrote", os.path.relpath(path, ROOT))
    else:
        print("unchanged", os.path.relpath(path, ROOT))


def dpk(p):
    lines = [f"package {p['name']};", "",
             f"{{ {p['description']}. Written by tools/gen_packages.py - edit the script, not this file. }}", "",
             f"{{$DESCRIPTION '{p['description']}'}}",
             "{$RUNONLY}" if p["kind"] == "runtime" else "{$DESIGNONLY}",
             "{$IMPLICITBUILD ON}", "", "requires"]
    lines += [f"  {r}{',' if i < len(p['requires']) - 1 else ';'}" for i, r in enumerate(p["requires"])]
    lines += ["", "contains"]
    entries = [(u, f"..\\lib\\{u}.pas") for u in p["units"]] + p["extra"]
    lines += [f"  {u} in '{path}'{',' if i < len(entries) - 1 else ';'}"
              for i, (u, path) in enumerate(entries)]
    lines += ["", "end."]
    write(os.path.join(PKG_DIR, p["name"] + ".dpk"), "\n".join(lines) + "\n", bom=False)


def dproj(p, force):
    path = os.path.join(PKG_DIR, p["name"] + ".dproj")
    if os.path.exists(path) and not force:
        print("kept", os.path.relpath(path, ROOT), "(the IDE's copy; --force to rewrite)")
        return
    rt = p["kind"] == "runtime"
    L = []
    a = L.append
    a('<Project xmlns="http://schemas.microsoft.com/developer/msbuild/2003">')
    a('    <PropertyGroup>')
    a(f'        <ProjectGuid>{existing_guid(path)}</ProjectGuid>')
    a('        <ProjectVersion>20.5</ProjectVersion>')  # Delphi 13 (Studio 37.0)
    a('        <FrameworkType>FMX</FrameworkType>')
    a('        <AppType>Package</AppType>')
    a(f'        <MainSource>{p["name"]}.dpk</MainSource>')
    a('        <Base>True</Base>')
    a("        <Config Condition=\"'$(Config)'==''\">Debug</Config>")
    a(f"        <Platform Condition=\"'$(Platform)'==''\">{p['default']}</Platform>")
    a(f"        <ProjectName Condition=\"'$(ProjectName)'==''\">{p['name']}</ProjectName>")
    a('    </PropertyGroup>')
    a("    <PropertyGroup Condition=\"'$(Config)'=='Base' or '$(Base)'!=''\">")
    a('        <Base>true</Base>')
    a('    </PropertyGroup>')
    for pl in p["platforms"]:
        a(f"    <PropertyGroup Condition=\"('$(Platform)'=='{pl}' and '$(Base)'=='true') or '$(Base_{pl})'!=''\">")
        a(f'        <Base_{pl}>true</Base_{pl}>')
        a('        <CfgParent>Base</CfgParent>')
        a('        <Base>true</Base>')
        a('    </PropertyGroup>')
    for key, cfg in (("Cfg_1", "Debug"), ("Cfg_2", "Release")):
        a(f"    <PropertyGroup Condition=\"'$(Config)'=='{cfg}' or '$({key})'!=''\">")
        a(f'        <{key}>true</{key}>')
        a('        <CfgParent>Base</CfgParent>')
        a('        <Base>true</Base>')
        a('    </PropertyGroup>')
    a("    <PropertyGroup Condition=\"'$(Base)'!=''\">")
    a(f'        <SanitizedProjectName>{p["name"]}</SanitizedProjectName>')
    a(f'        <DCC_Namespace>{NS_BASE};$(DCC_Namespace)</DCC_Namespace>')
    a('        <DCC_UnitSearchPath>..\\lib;$(DCC_UnitSearchPath)</DCC_UnitSearchPath>')
    if rt:
        # DCUs next to the package's .dcp, on the IDE's default Library path, so
        # programs need no paths; Win32 is overridden in Base_Win32. Debug
        # and Release share the folder: the last build wins
        a('        <DCC_DcuOutput>$(BDSCOMMONDIR)\\Dcp\\$(Platform)</DCC_DcuOutput>')
    else:
        a('        <DCC_DcuOutput>.\\$(Platform)\\$(Config)\\dcu</DCC_DcuOutput>')
    # No DCC_BplOutput / DCC_DcpOutput: Delphi's defaults ($(BDSCOMMONDIR)\Bpl
    # and \Dcp per platform) are on the IDE's PATH and Library path, so
    # each design package finds its runtime .dcp and the IDE can load its .bpl
    a('        <GenDll>true</GenDll>')
    a('        <GenPackage>true</GenPackage>')
    a(f'        <DCC_Description>{p["description"]}</DCC_Description>')
    a('        <RuntimeOnlyPackage>true</RuntimeOnlyPackage>' if rt
      else '        <DesignOnlyPackage>true</DesignOnlyPackage>')
    for flag in "ENSFK":
        a(f'        <DCC_{flag}>false</DCC_{flag}>')
    a('    </PropertyGroup>')
    for pl in p["platforms"]:
        if not pl.startswith("Win"):
            continue
        a(f"    <PropertyGroup Condition=\"'$(Base_{pl})'!=''\">")
        a(f'        <DCC_Namespace>{NS_WIN};$(DCC_Namespace)</DCC_Namespace>')
        if rt and pl == "Win32":
            # Win32's Dcp folder has no platform sub-folder
            a('        <DCC_DcuOutput>$(BDSCOMMONDIR)\\Dcp</DCC_DcuOutput>')
        a('    </PropertyGroup>')
    a("    <PropertyGroup Condition=\"'$(Cfg_1)'!=''\">")
    a('        <DCC_Define>DEBUG;$(DCC_Define)</DCC_Define>')
    a('        <DCC_DebugDCUs>true</DCC_DebugDCUs>')
    a('        <DCC_Optimize>false</DCC_Optimize>')
    a('        <DCC_GenerateStackFrames>true</DCC_GenerateStackFrames>')
    a('        <DCC_DebugInfoInExe>true</DCC_DebugInfoInExe>')
    a('        <DCC_RemoteDebug>true</DCC_RemoteDebug>')
    a('    </PropertyGroup>')
    a("    <PropertyGroup Condition=\"'$(Cfg_2)'!=''\">")
    a('        <DCC_LocalDebugSymbols>false</DCC_LocalDebugSymbols>')
    a('        <DCC_Define>RELEASE;$(DCC_Define)</DCC_Define>')
    a('        <DCC_SymbolReferenceInfo>0</DCC_SymbolReferenceInfo>')
    a('        <DCC_DebugInformation>0</DCC_DebugInformation>')
    a('    </PropertyGroup>')
    a('    <ItemGroup>')
    a('        <DelphiCompile Include="$(MainSource)">')
    a('            <MainSource>MainSource</MainSource>')
    a('        </DelphiCompile>')
    for r in p["requires"]:
        a(f'        <DCCReference Include="{r}.dcp"/>')
    for u in p["units"]:
        a(f'        <DCCReference Include="..\\lib\\{u}.pas"/>')
    for _, src in p["extra"]:
        a(f'        <DCCReference Include="{src}"/>')
    a('        <BuildConfiguration Include="Base">')
    a('            <Key>Base</Key>')
    a('        </BuildConfiguration>')
    a('        <BuildConfiguration Include="Debug">')
    a('            <Key>Cfg_1</Key>')
    a('            <CfgParent>Base</CfgParent>')
    a('        </BuildConfiguration>')
    a('        <BuildConfiguration Include="Release">')
    a('            <Key>Cfg_2</Key>')
    a('            <CfgParent>Base</CfgParent>')
    a('        </BuildConfiguration>')
    a('    </ItemGroup>')
    a('    <ProjectExtensions>')
    a('        <Borland.Personality>Delphi.Personality.12</Borland.Personality>')
    a('        <Borland.ProjectType>Package</Borland.ProjectType>')
    a('        <BorlandProject>')
    a('            <Delphi.Personality>')
    a('                <Source>')
    a(f'                    <Source Name="MainSource">{p["name"]}.dpk</Source>')
    a('                </Source>')
    a('                <WelcomePageFile Path="..\\README.md"/>')
    a('            </Delphi.Personality>')
    a('            <Platforms>')
    for pl in ALL_PLATFORMS:
        a(f'                <Platform value="{pl}">{"True" if pl in p["platforms"] else "False"}</Platform>')
    a('            </Platforms>')
    a('        </BorlandProject>')
    a('        <ProjectFileVersion>12</ProjectFileVersion>')
    a('    </ProjectExtensions>')
    a("    <Import Project=\"$(BDS)\\Bin\\CodeGear.Delphi.Targets\" Condition=\"Exists('$(BDS)\\Bin\\CodeGear.Delphi.Targets')\"/>")
    a("    <Import Project=\"$(APPDATA)\\Embarcadero\\$(BDSAPPDATABASEDIR)\\$(PRODUCTVERSION)\\UserTools.proj\" Condition=\"Exists('$(APPDATA)\\Embarcadero\\$(BDSAPPDATABASEDIR)\\$(PRODUCTVERSION)\\UserTools.proj')\"/>")
    a('</Project>')
    write(path, "\n".join(L) + "\n", bom=True)


def main():
    force = "--force" in sys.argv
    check_units()
    os.makedirs(PKG_DIR, exist_ok=True)
    for p in PACKAGES:
        dpk(p)
        dproj(p, force)


if __name__ == "__main__":
    main()
