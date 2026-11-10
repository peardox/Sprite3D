//** @abstract(Cisco's licence for its OpenH264 binary, and the notice it asks to be shown.)
//**
//** Cisco's binary of OpenH264 is covered by its AVC/H.264 patent licence only if four
//** conditions are met; the last two ask that the place the user turns it on and off shows
//** OPENH264_NOTICE, and that the licence text be reproduced where licensing information is
//** shown. OpenH264BinaryLicence gives that text exactly as Cisco publishes it, v1.0, from
//** @code(BINARY_LICENSE.txt) at openh264.org; a copy is in the project's
//** @code(licences) folder. The RTL only.
unit Sprite3DCiscoLicence;

{
  Cisco's licence for its OpenH264 binary, and the notice it asks to be
  shown.

  Cisco's binary of OpenH264 is covered by its AVC/H.264 patent licence only
  if four conditions are met; the last two ask that the place the user turns
  it on and off shows OPENH264_NOTICE, and that the licence text be
  reproduced where licensing information is shown. OpenH264BinaryLicence
  gives that text exactly as Cisco publishes it, v1.0, from
  BINARY_LICENSE.txt at openh264.org; a copy is in the project's licences
  folder. The RTL only.
}

interface

const
  //** @abstract(The text Cisco's licence asks to be shown where the user turns OpenH264 on
  //** and off.)
  OPENH264_NOTICE = 'OpenH264 Video Codec provided by Cisco Systems, Inc.';

//** @abstract(Cisco's licence for its OpenH264 binary, word for word.)
//**
//** Lines end with the platform's line break; the curly quotes, apostrophes and the
//** copyright sign are as Cisco wrote them.
//**
//** @returns(The licence text.)
function OpenH264BinaryLicence: String;

implementation

uses
  System.SysUtils;

function OpenH264BinaryLicence: String;
begin
  // Generated from licences/OpenH264-BINARY_LICENSE.txt: change that file,
  // not this text, and make it again
  Result :=
    '-------------------------------------------------------' + sLineBreak +
    'About The Cisco-Provided Binary of OpenH264 Video Codec' + sLineBreak +
    '-------------------------------------------------------' + sLineBreak +
    '' + sLineBreak +
    'Cisco provides this program under the terms of the BSD license.  ' + sLineBreak +
    '' + sLineBreak +
    'Additionally, this binary is licensed under Cisco' + #$2019 +
    's AVC/H.264 Patent Portfolio License from MPEG LA, at no cost to you, provid' +
    'ed that the requirements and conditions shown below in the AVC/H.264 Patent ' +
    'Portfolio sections are met.  ' + sLineBreak +
    '' + sLineBreak +
    'As with all AVC/H.264 codecs, you may also obtain your own patent license fr' +
    'om MPEG LA or from the individual patent owners, or proceed at your own risk' +
    '.  Your rights from Cisco under the BSD license are not affected by this cho' +
    'ice.  ' + sLineBreak +
    '' + sLineBreak +
    'For more information on the OpenH264 binary licensing, please see the OpenH2' +
    '64 FAQ found at http://www.openh264.org/faq.html#binary ' + sLineBreak +
    '' + sLineBreak +
    'A corresponding source code to this binary program is available under the sa' +
    'me BSD terms, which can be found at http://www.openh264.org' + sLineBreak +
    '' + sLineBreak +
    '-----------' + sLineBreak +
    'BSD License' + sLineBreak +
    '-----------' + sLineBreak +
    '' + sLineBreak +
    'Copyright ' + #$00A9 + ' 2014 Cisco Systems, Inc.' + sLineBreak +
    '' + sLineBreak +
    'All rights reserved.' + sLineBreak +
    '' + sLineBreak +
    'Redistribution and use in source and binary forms, with or without modificat' +
    'ion, are permitted provided that the following conditions are met:' + sLineBreak +
    '' + sLineBreak +
    '1. Redistributions of source code must retain the above copyright notice, th' +
    'is list of conditions and the following disclaimer.' + sLineBreak +
    '' + sLineBreak +
    '2. Redistributions in binary form must reproduce the above copyright notice,' +
    ' this list of conditions and the following disclaimer in the documentation a' +
    'nd/or other materials provided with the distribution.' + sLineBreak +
    '' + sLineBreak +
    'THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS ' + #$201C + 'AS IS' +
    #$201D + ' AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE I' +
    'MPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE AR' +
    'E DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIA' +
    'BLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTI' +
    'AL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS O' +
    'R SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER' +
    ' CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILIT' +
    'Y, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE' +
    ' USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.' + sLineBreak +
    '' + sLineBreak +
    '-----------------------------------------' + sLineBreak +
    'AVC/H.264 Patent Portfolio License Notice' + sLineBreak +
    '-----------------------------------------' + sLineBreak +
    '' + sLineBreak +
    'The binary form of this Software is distributed by Cisco under the AVC/H.264' +
    ' Patent Portfolio License from MPEG LA, and is subject to the following requ' +
    'irements, which may or may not be applicable to your use of this software: ' + sLineBreak +
    '' + sLineBreak +
    'THIS PRODUCT IS LICENSED UNDER THE AVC PATENT PORTFOLIO LICENSE FOR THE PERS' +
    'ONAL USE OF A CONSUMER OR OTHER USES IN WHICH IT DOES NOT RECEIVE REMUNERATI' +
    'ON TO (i) ENCODE VIDEO IN COMPLIANCE WITH THE AVC STANDARD (' + #$201C + 'AVC VIDEO' +
    #$201D + ') AND/OR (ii) DECODE AVC VIDEO THAT WAS ENCODED BY A CONSUMER ENGAGED IN A P' +
    'ERSONAL ACTIVITY AND/OR WAS OBTAINED FROM A VIDEO PROVIDER LICENSED TO PROVI' +
    'DE AVC VIDEO.  NO LICENSE IS GRANTED OR SHALL BE IMPLIED FOR ANY OTHER USE. ' +
    ' ADDITIONAL INFORMATION MAY BE OBTAINED FROM MPEG LA, L.L.C. SEE HTTP://WWW.' +
    'MPEGLA.COM' + sLineBreak +
    '' + sLineBreak +
    'Accordingly, please be advised that content providers and broadcasters using' +
    ' AVC/H.264 in their service may be required to obtain a separate use license' +
    ' from MPEG LA, referred to as "(b) sublicenses" in the SUMMARY OF AVC/H.264 ' +
    'LICENSE TERMS from MPEG LA found at http://www.openh264.org/mpegla' + sLineBreak +
    '' + sLineBreak +
    '---------------------------------------------' + sLineBreak +
    'AVC/H.264 Patent Portfolio License Conditions' + sLineBreak +
    '---------------------------------------------' + sLineBreak +
    '' + sLineBreak +
    'In addition, the Cisco-provided binary of this Software is licensed under Ci' +
    'sco''s license from MPEG LA only if the following conditions are met:' + sLineBreak +
    '' + sLineBreak +
    '1. The Cisco-provided binary is separately downloaded to an end user' + #$2019 +
    's device, and not integrated into or combined with third party software prio' +
    'r to being downloaded to the end user' + #$2019 + 's device;' + sLineBreak +
    '' + sLineBreak +
    '2. The end user must have the ability to control (e.g., to enable, disable, ' +
    'or re-enable) the use of the Cisco-provided binary;' + sLineBreak +
    '' + sLineBreak +
    '3. Third party software, in the location where end users can control the use' +
    ' of the Cisco-provided binary, must display the following text:' + sLineBreak +
    '' + sLineBreak +
    '       "OpenH264 Video Codec provided by Cisco Systems, Inc."' + sLineBreak +
    '' + sLineBreak +
    '4.  Any third-party software that makes use of the Cisco-provided binary mus' +
    't reproduce all of the above text, as well as this last condition, in the EU' +
    'LA and/or in another location where licensing information is to be presented' +
    ' to the end user.  ' + sLineBreak +
    ' ' + sLineBreak +
    '' + sLineBreak +
    '' + sLineBreak +
    '                          v1.0' + sLineBreak +
    '';
end;

end.
