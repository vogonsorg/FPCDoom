//------------------------------------------------------------------------------
//
//  FPCDoom - Port of Doom to Free Pascal Compiler
//  Copyright (C) 2004-2007 by Jim Valavanis
//  Copyright (C) 2017-2018 by Jim Valavanis
//
//  This program is free software; you can redistribute it and/or
//  modify it under the terms of the GNU General Public License
//  as published by the Free Software Foundation; either version 2
//  of the License, or (at your option) any later version.
//
//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with this program; if not, write to the Free Software
//  Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA
//  02111-1307, USA.
//
//------------------------------------------------------------------------------
//  E-Mail: jimmyvalavanis@yahoo.gr
//  Site  : https://sourceforge.net/projects/fpcdoom/
//------------------------------------------------------------------------------

{$I FPCDoom.inc}

unit r_draw_span;

interface

uses
  d_fpc,
  m_fixed;

// Span blitting for rows, floor/ceiling.
// No Sepctre effect needed.
procedure R_DrawSpanMedium;

var
  ds_y: integer;
  ds_x1: integer;
  ds_x2: integer;

  ds_colormap: PByteArray;

  ds_xfrac: fixed_t;
  ds_yfrac: fixed_t;
  ds_xstep: fixed_t;
  ds_ystep: fixed_t;

// start of a 64*64 tile image
  ds_source: PByteArray;


type
  dsscale_t = (ds64x64, ds128x128, ds256x256, ds512x512, NUMDSSCALES);

type
  dsscaleinfo_t = record
    frac: integer;
    yshift: integer;
    yand: integer;
    dand: integer;
  end;
  Pdsscaleinfo_t = ^dsscaleinfo_t;

const
  DSSCALEINFO: array[ds64x64..ds512x512] of dsscaleinfo_t = (
    (frac: 1; yshift: 10; yand:   4032; dand:  63;),
    (frac: 2; yshift:  9; yand:  16256; dand: 127;),
    (frac: 4; yshift:  8; yand:  65280; dand: 255;),
    (frac: 8; yshift:  7; yand: 261632; dand: 511;)
  );

const
  dsscalesize: array[0..Ord(NUMDSSCALES) - 1] of integer = (
     64 *  64,
    128 * 128,
    256 * 256,
    512 * 512
  );

var
  ds_scale: dsscale_t;

var
  ds_colormap32: PLongWordArray;
  ds_lightlevel: fixed_t;
  ds_llzindex: fixed_t; // Lightlevel index for z axis

// start of a WxW tile image
  ds_source32: PLongWordArray;

procedure R_DrawSpanNormal;


implementation

uses
  r_draw,
  r_hires;

//
// R_DrawSpan
// With DOOM style restrictions on view orientation,
//  the floors and ceilings consist of horizontal slices
//  or spans with constant z depth.
// However, rotation around the world z axis is possible,
//  thus this mapping, while simpler and faster than
//  perspective correct texture mapping, has to traverse
//  the texture at an angle in all but a few cases.
// In consequence, flats are not stored by column (like walls),
//  and the inner loop has to step in texture space u and v.
//

//
// Draws the actual span (Medium resolution).
//
procedure R_DrawSpanMedium;
var
  xfrac: fixed_t;
  yfrac: fixed_t;
  xstep: fixed_t;
  ystep: fixed_t;
  dest: PByte;
  count: integer;
  psi: Pdsscaleinfo_t;
begin
  // We do not check for zero spans here?
  count := ds_x2 - ds_x1;

  dest := @((ylookup[ds_y]^)[columnofs[ds_x1]]);

  psi := @DSSCALEINFO[ds_scale];
  xfrac := ds_xfrac * psi.frac;
  yfrac := ds_yfrac * psi.frac;
  xstep := ds_xstep * psi.frac;
  ystep := ds_ystep * psi.frac;

  while count >= 0 do
  begin
    dest^ := ds_colormap[ds_source[_SHR(yfrac, psi.yshift) and psi.yand + _SHR(xfrac, FRACBITS) and psi.dand]];
    inc(dest);

    // Next step in u,v.
    xfrac := xfrac + xstep;
    yfrac := yfrac + ystep;
    dec(count);
  end;
end;

//
// Draws the actual span (Normal resolution).
//
procedure R_DrawSpanNormal;
var
  xfrac: fixed_t;
  yfrac: fixed_t;
  xstep: fixed_t;
  ystep: fixed_t;
  destl: PLongWord;
  count: integer;
  psi: Pdsscaleinfo_t;
begin
  // We do not check for zero spans here?
  count := ds_x2 - ds_x1;

  destl := @((ylookupl[ds_y]^)[columnofs[ds_x1]]);
  psi := @DSSCALEINFO[ds_scale];
  xfrac := ds_xfrac * psi.frac;
  yfrac := ds_yfrac * psi.frac;
  xstep := ds_xstep * psi.frac;
  ystep := ds_ystep * psi.frac;

  while count >= 0 do
  begin
    destl^ := R_ColorLightEx(ds_source32[_SHR(yfrac, psi.yshift) and psi.yand + _SHR(xfrac, FRACBITS) and psi.dand], ds_lightlevel);
    inc(destl);

    // Next step in u,v.
    xfrac := xfrac + xstep;
    yfrac := yfrac + ystep;
    dec(count);
  end;
end;

end.

