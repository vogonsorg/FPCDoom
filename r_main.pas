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

unit r_main;

interface

uses
  d_fpc,
  doomdef,
  d_player,
  m_fixed,
  tables,
  r_data,
  r_defs;

const
//
// Lighting LUT.
// Used for z-depth cuing per column/row,
//  and other lighting effects (sector ambient, flash).
//

// Lighting constants.
// Now why not 32 levels here?
  LIGHTSEGSHIFT = 4;
  LIGHTLEVELS = (256 div (1 shl LIGHTSEGSHIFT));

  MAXLIGHTSCALE = 48;
  LIGHTSCALESHIFT = 12;
  HLL_MAXLIGHTSCALE = MAXLIGHTSCALE * 64;

  MAXLIGHTZ = 128;
  LIGHTZSHIFT = 20;

  HLL_MAXLIGHTZ = MAXLIGHTZ * 64; // Hi resolution light level for z depth
  HLL_LIGHTZSHIFT = 12;
  HLL_LIGHTSCALESHIFT = 3;
  HLL_ZDISTANCESHIFT = 14;

  LIGHTDISTANCESHIFT = 12;

// Colormap constants
// Number of diminishing brightness levels.
// There a 0-31, i.e. 32 LUT in the COLORMAP lump.
// Index of the special effects (INVUL inverse) map.
  INVERSECOLORMAP = 32;

var
  forcecolormaps: boolean;
  use32bitfuzzeffect: boolean;
  chasecamera: boolean;
  chasecamera_viewxy: integer;
  chasecamera_viewz: integer;

//
// Utility functions.
//
procedure R_ApplyColormap(const ofs, count: integer; const scrn: integer; const cmap: integer);

function R_PointOnSide(const x: fixed_t; const y: fixed_t; const node: Pnode_t): boolean;

function R_PointOnSegSide(x: fixed_t; y: fixed_t; line: Pseg_t): boolean;

function R_PointToAngle(x: fixed_t; y: fixed_t): angle_t;

function R_PointToAngle2(const x1: fixed_t; const y1: fixed_t; const x2: fixed_t; const y2: fixed_t): angle_t;

function R_PointToDist(const x: fixed_t; const y: fixed_t): fixed_t;

function R_ScaleFromGlobalAngle(const visangle: angle_t): fixed_t;

function R_ScaleFromGlobalAngle_DBL(const visangle: angle_t): double;

function R_PointInSubsector(const x: fixed_t; const y: fixed_t): Psubsector_t;

procedure R_AddPointToBox(const x: integer; const y: integer; box: Pfixed_tArray);


//
// REFRESH - the actual rendering functions.
//

// Called by G_Drawer.
procedure R_RenderPlayerView(player: Pplayer_t);

// Called by startup code.
procedure R_Init;
procedure R_ShutDown;

// Called by M_Responder.
procedure R_SetViewSize;

procedure R_ExecuteSetViewSize;

procedure R_SetViewAngleOffset(const angle: angle_t);

function R_FullStOn: boolean;

var
  colfunc: PProcedure;
  wallcolfunc: PProcedure;
  skycolfunc: PProcedure;
  transcolfunc: PProcedure;
  averagecolfunc: PProcedure;
  alphacolfunc: PProcedure;
  maskedcolfunc: PProcedure;
  maskedcolfunc2: PProcedure; // For hi res textures
  fuzzcolfunc: PProcedure;
  lightcolfunc: PProcedure;
  whitelightcolfunc: PProcedure;
  redlightcolfunc: PProcedure;
  greenlightcolfunc: PProcedure;
  bluelightcolfunc: PProcedure;
  yellowlightcolfunc: PProcedure;
  spanfunc: PProcedure;

  centerxfrac: fixed_t;
  centeryfrac: fixed_t;
  centerxshift: fixed_t;

  viewx: fixed_t;
  viewy: fixed_t;
  viewz: fixed_t;

  viewangle: angle_t;

  shiftangle: byte;

  viewcos: fixed_t;
  viewsin: fixed_t;

  dviewsin: double;
  dviewcos: double;
  relativeaspect: Double;

  projection: fixed_t;
  projectiony: fixed_t; // JVAL For correct aspect

  centerx: integer;
  centery: integer;

  fixedcolormap: PByteArray;
  fixedcolormapnum: integer = 0;

// increment every time a check is made
  validcount: integer = 1;

// bumped light from gun blasts
  extralight: integer;

  scalelight: array[0..LIGHTLEVELS - 1, 0..MAXLIGHTSCALE - 1] of PByteArray;
  scalelightlevels: array[0..LIGHTLEVELS - 1, 0..HLL_MAXLIGHTSCALE - 1] of fixed_t;
  scalelightfixed: array[0..MAXLIGHTSCALE - 1] of PByteArray;
  zlight: array[0..LIGHTLEVELS - 1, 0..MAXLIGHTZ - 1] of PByteArray;
  zlightlevels: array[0..LIGHTLEVELS - 1, 0..HLL_MAXLIGHTZ - 1] of fixed_t;

  viewplayer: Pplayer_t;

// The viewangletox[viewangle + FINEANGLES/4] lookup
// maps the visible view angles to screen X coordinates,
// flattening the arc to a flat projection plane.
// There will be many angles mapped to the same X.
  viewangletox: array[0..FINEANGLES div 2 - 1] of integer;

// The xtoviewangleangle[] table maps a screen pixel
// to the lowest viewangle that maps back to x ranges
// from clipangle to -clipangle.
  xtoviewangle: array[0..MAXWIDTH] of angle_t;

//
// precalculated math tables
//
  clipangle: angle_t;

// UNUSED.
// The finetangentgent[angle+FINEANGLES/4] table
// holds the fixed_t tangent values for view angles,
// ranging from MININT to 0 to MAXINT.
// fixed_t    finetangent[FINEANGLES/2];

// fixed_t    finesine[5*FINEANGLES/4];
// fixed_t*    finecosine = &finesine[FINEANGLES/4]; // JVAL -> moved to tables.pas


  sscount: integer;
  linecount: integer;
  loopcount: integer;

  viewangleoffset: angle_t = 0; // never a value assigned to this variable!

  setsizeneeded: boolean;

// Blocky mode, has default, 0 = high, 1 = normal
  screenblocks: integer;  // has default

function R_GetColormapLightLevel(const cmap: PByteArray): fixed_t;

function R_GetColormap32(const cmap: PByteArray): PLongWordArray;

procedure R_Ticker;

implementation

uses
  doomdata,
  c_cmds,
  d_net,
  i_io,
  m_bbox,
  m_misc,
  p_setup,
  p_sight,
  p_map,
  r_aspect,
  r_draw,
  r_bsp,
  r_things,
  r_plane,
  r_sky,
  r_segs,
  r_hires,
  r_trans8,
  r_externaltextures,
  r_lights,
  r_intrpl,
  r_draw_column,
  r_draw_span,
  v_video,
  st_stuff,
  z_memory;

var
// just for profiling purposes
  framecount: integer;

procedure R_ApplyColormap(const ofs, count: integer; const scrn: integer; const cmap: integer);
var
  src: PByte;
  cnt: integer;
  colormap: PByteArray;
begin
  src := PByte(screens[scrn]);
  inc(src, ofs);
  cnt := count;
  colormap := @colormaps[cmap * 256];

  while cnt > 0 do
  begin
    src^ := colormap[src^];
    inc(src);
    dec(cnt);
  end;
end;

//
// R_AddPointToBox
// Expand a given bbox
// so that it encloses a given point.
//
procedure R_AddPointToBox(const x: integer; const y: integer; box: Pfixed_tArray);
begin
  if x < box[BOXLEFT] then
    box[BOXLEFT] := x;
  if x > box[BOXRIGHT] then
    box[BOXRIGHT] := x;
  if y < box[BOXBOTTOM] then
    box[BOXBOTTOM] := y;
  if y > box[BOXTOP] then
    box[BOXTOP] := y;
end;

//
// R_PointOnSide
// Traverse BSP (sub) tree,
//  check point against partition plane.
// Returns side 0 (front) or 1 (back).
//
function R_PointOnSide(const x: fixed_t; const y: fixed_t; const node: Pnode_t): boolean;
var
  dx: fixed_t;
  dy: fixed_t;
  left: fixed_t;
  right: fixed_t;
begin
  if node.dx = 0 then
  begin
    if x <= node.x then
      result := node.dy > 0
    else
      result := node.dy < 0;
    exit;
  end;

  if node.dy = 0 then
  begin
    if y <= node.y then
      result := node.dx < 0
    else
      result := node.dx > 0;
    exit;
  end;

  dx := (x - node.x);
  dy := (y - node.y);

  // Try to quickly decide by looking at sign bits.
  if ((node.dy xor node.dx xor dx xor dy) and $80000000) <> 0 then
  begin
    result := ((node.dy xor dx) and $80000000) <> 0;
    exit;
  end;

  left := IntFixedMul(node.dy, dx);
  right := FixedIntMul(dy, node.dx);

  result := right >= left;
end;

function R_PointOnSegSide(x: fixed_t; y: fixed_t; line: Pseg_t): boolean;
var
  lx: fixed_t;
  ly: fixed_t;
  ldx: fixed_t;
  ldy: fixed_t;
  dx: fixed_t;
  dy: fixed_t;
  left: fixed_t;
  right: fixed_t;
begin
  lx := line.v1.x;
  ly := line.v1.y;

  ldx := line.v2.x - lx;
  ldy := line.v2.y - ly;

  if ldx = 0 then
  begin
    if x <= lx then
      result := ldy > 0
    else
      result := ldy < 0;
    exit;
  end;

  if ldy = 0 then
  begin
    if y <= ly then
      result := ldx < 0
    else
      result := ldx > 0;
    exit;
  end;

  dx := x - lx;
  dy := y - ly;

  // Try to quickly decide by looking at sign bits.
  if ((ldy xor ldx xor dx xor dy) and $80000000) <> 0 then
  begin
    result := ((ldy xor dx) and $80000000) <> 0;
    exit;
  end;

  left := IntFixedMul(ldy, dx);
  right := FixedIntMul(dy, ldx);

  result := left <= right;
end;

//
// R_PointToAngle
// To get a global angle from cartesian coordinates,
//  the coordinates are flipped until they are in
//  the first octant of the coordinate system, then
//  the y (<=x) is scaled and divided by x to get a
//  tangent (slope) value which is looked up in the
//  tantoangle[] table.
//
// JVAL  -> Calculates: result := round(683565275 * (arctan2(y, x)));
//
function R_PointToAngle(x: fixed_t; y: fixed_t): angle_t;
begin
  x := x - viewx;
  y := y - viewy;

  if (x = 0) and (y = 0) then
  begin
    result := 0;
    exit;
  end;

  if x >= 0 then
  begin
    // x >=0
    if y >= 0 then
    begin
      // y>= 0
      if x > y then
      begin
        // octant 0
        result := tantoangle[SlopeDiv(y, x)];
        exit;
      end
      else
      begin
        // octant 1
        result := ANG90 - 1 - tantoangle[SlopeDiv(x, y)];
        exit;
      end;
    end
    else
    begin
      // y<0
      y := -y;
      if x > y then
      begin
        // octant 8
        result := -tantoangle[SlopeDiv(y, x)];
        exit;
      end
      else
      begin
        // octant 7
        result := ANG270 + tantoangle[SlopeDiv(x, y)];
        exit;
      end;
    end;
  end
  else
  begin
    // x<0
    x := -x;
    if y >= 0 then
    begin
      // y>= 0
      if x > y then
      begin
        // octant 3
        result := ANG180 - 1 - tantoangle[SlopeDiv(y, x)];
        exit;
      end
      else
      begin
        // octant 2
        result := ANG90 + tantoangle[SlopeDiv(x, y)];
        exit;
      end;
    end
    else
    begin
      // y<0
      y := -y;
      if x > y then
      begin
        // octant 4
        result := ANG180 + tantoangle[SlopeDiv(y, x)];
        exit;
      end
      else
      begin
        // octant 5
        result := ANG270 - 1 - tantoangle[SlopeDiv(x, y)];
        exit;
      end;
    end;
  end;

  result := 0;
end;

function R_PointToAngle2(const x1: fixed_t; const y1: fixed_t; const x2: fixed_t; const y2: fixed_t): angle_t;
begin
  result := R_PointToAngle(x2 - x1 + viewx, y2 - y1 + viewy);
end;

function R_PointToDist(const x: fixed_t; const y: fixed_t): fixed_t;
var
  angle: integer;
  dx: fixed_t;
  dy: fixed_t;
  temp: fixed_t;
begin
  dx := abs(x - viewx);
  dy := abs(y - viewy);
  if dx = 0 then
  begin
    result := dy;
    exit;
  end;
  if dy = 0 then
  begin
    result := dx;
    exit;
  end;

  if dy > dx then
  begin
    temp := dx;
    dx := dy;
    dy := temp;
  end;

  angle := _SHRW(tantoangle[FixedDiv(dy, dx) shr DBITS], ANGLETOFINESHIFT);

  result := FixedDiv(dx, finecosine[angle]);
end;

//
// R_ScaleFromGlobalAngle
// Returns the texture mapping scale
//  for the current line (horizontal span)
//  at the given angle.
// rw_distance must be calculated first.
//
function R_ScaleFromGlobalAngle(const visangle: angle_t): fixed_t;
var
  anglea: angle_t;
  angleb: angle_t;
  num: fixed_t;
  den: integer;
begin
  anglea := ANG90 + (visangle - viewangle);
  angleb := ANG90 + (visangle - rw_normalangle);

  num := FixedMul(projectiony, finesine[_SHRW(angleb, ANGLETOFINESHIFT)]); // JVAL For correct aspect
  den := FixedMul(rw_distance, finesine[_SHRW(anglea, ANGLETOFINESHIFT)]);

  if den > FixedInt(num) then
  begin
    result := FixedDiv(num, den);

    if result > 64 * FRACUNIT then
      result := 64 * FRACUNIT
    else if result < 256 then
      result := 256
  end
  else
    result := 64 * FRACUNIT;
end;

const
  MINSCALE = -FRACUNIT * (FRACUNIT / 4);
  MAXSCALE = FRACUNIT * (FRACUNIT / 4);

function R_ScaleFromGlobalAngle_DBL(const visangle: angle_t): double;
var
  anglea: angle_t;
  angleb: angle_t;
  num: Double;
  den: Double;
begin
  anglea := ANG90 + (visangle - viewangle);
  angleb := ANG90 + (visangle - rw_normalangle);

  num := projectiony * Sin(angleb * ANGLE_T_TO_RAD);
  den := rw_distance * Sin(anglea * ANGLE_T_TO_RAD);

  if den = 0 then
  begin
    if num < 0 then
      result := MINSCALE
    else
      result := MAXSCALE;
  end
  else
  begin
    result := (num / den) * FRACUNIT;
    if result < MINSCALE then
      result := MINSCALE
    else if result > MAXSCALE then
      result := MAXSCALE
  end;

end;

//
// R_InitTables
//
procedure R_InitTables;
begin
  finecosine := Pfixed_tArray(@finesine[FINEANGLES div 4]);
end;

var
  monitor_relative_aspect: Double = 1.0;

//
// R_InitTextureMapping
//
procedure R_InitTextureMapping;
var
  i: integer;
  x: integer;
  t: integer;
  focallength: fixed_t;
  fov: fixed_t;
  an: angle_t;
begin
  // Use tangent table to generate viewangletox:
  //  viewangletox will give the next greatest x
  //  after the view angle.
  //
  // Calc focallength
  //  so fov angles covers SCREENWIDTH.

  // JVAL: Widescreen support
  if monitor_relative_aspect = 1.0 then
    fov := ANG90 shr ANGLETOFINESHIFT
  else
    fov := round(arctan(monitor_relative_aspect) * FINEANGLES / D_PI);
  focallength := FixedDiv(centerxfrac, finetangent[FINEANGLES div 4 + fov div 2]);

  for i := 0 to FINEANGLES div 2 - 1 do
  begin
    if finetangent[i] > FRACUNIT * 2 then
      t := -1
    else if finetangent[i] < -FRACUNIT * 2 then
      t := viewwidth + 1
    else
    begin
      t := FixedMul(finetangent[i], focallength);
      t := (centerxfrac - t + (FRACUNIT - 1)) div FRACUNIT;

      if t < -1 then
        t := -1
      else if t > viewwidth + 1 then
        t := viewwidth + 1;
    end;
    viewangletox[i] := t;
  end;

  // Scan viewangletox[] to generate xtoviewangle[]:
  //  xtoviewangle will give the smallest view angle
  //  that maps to x.
  for x := 0 to viewwidth do
  begin
    an := 0;
    while viewangletox[an] > x do
      inc(an);
    xtoviewangle[x] := an * ANGLETOFINEUNIT - ANG90;
  end;

  // Take out the fencepost cases from viewangletox.
  for i := 0 to FINEANGLES div 2 - 1 do
  begin
    if viewangletox[i] = -1 then
      viewangletox[i] := 0
    else if viewangletox[i] = viewwidth + 1 then
      viewangletox[i] := viewwidth;
  end;
  clipangle := xtoviewangle[0];
end;

//
// R_InitLightTables
// Only inits the zlight table,
//  because the scalelight table changes with view size.
//
const
  DISTMAP = 2;

procedure R_InitLightTables;
var
  i: integer;
  j: integer;
  level: integer;
  startmap: integer;
  scale: integer;
  levelhi: integer;
  startmaphi: integer;
  scalehi: integer;
begin
  // Calculate the light levels to use
  //  for each level / distance combination.
  for i := 0 to LIGHTLEVELS - 1 do
  begin
    startmap := ((LIGHTLEVELS - 1 - i) * 2 * NUMCOLORMAPS) div LIGHTLEVELS;
    for j := 0 to MAXLIGHTZ - 1 do
    begin
      scale := FixedDiv(160 * FRACUNIT, _SHL(j + 1, LIGHTZSHIFT));
      scale := _SHR(scale, LIGHTSCALESHIFT);
      level := startmap - scale div DISTMAP;

      if level < 0 then
        level := 0
      else if level >= NUMCOLORMAPS then
        level := NUMCOLORMAPS - 1;

      zlight[i][j] := PByteArray(integer(colormaps) + level * 256);
    end;

    startmaphi := ((LIGHTLEVELS - 1 - i) * 2 * FRACUNIT) div LIGHTLEVELS;
    for j := 0 to HLL_MAXLIGHTZ - 1 do
    begin

      scalehi := FixedDiv(160 * FRACUNIT, _SHL(j + 1, HLL_LIGHTZSHIFT));
      scalehi := _SHR(scalehi, HLL_LIGHTSCALESHIFT);
      levelhi := FRACUNIT - startmaphi + scalehi div DISTMAP;

      if levelhi < 0 then
        levelhi := 0
      else if levelhi >= FRACUNIT then
        levelhi := FRACUNIT - 1;

      zlightlevels[i][j] := levelhi;
    end;
  end;

end;

//
// R_SetViewSize
// Do not really change anything here,
//  because it might be in the middle of a refresh.
// The change will take effect next refresh.
//
var
  setblocks: integer = -1;
  olddetail: integer = -1;

procedure R_SetViewSize;
begin
  if detailLevel < DL_MEDIUM then
  detailLevel := DL_MEDIUM;
  if detailLevel > DL_NORMAL then
  detailLevel := DL_NORMAL;

  if (setblocks <> screenblocks) or (setdetail <> detailLevel) then
  begin
    if setdetail <> detailLevel then
      recalctablesneeded := true;
    setsizeneeded := true;
    setblocks := screenblocks;
    setdetail := detailLevel;
  end;
end;

procedure R_SetRenderingFunctions;
begin
  case setdetail of
    DL_MEDIUM:
      begin
        colfunc := R_DrawColumnMedium;
        wallcolfunc := R_DrawColumnMedium;
        transcolfunc := R_DrawTranslatedColumn;
        averagecolfunc := R_DrawColumnAverageMedium;
        alphacolfunc := R_DrawColumnAlphaMedium;
        maskedcolfunc := R_DrawColumnMedium;
        maskedcolfunc2 := R_DrawColumnMedium;
        spanfunc := R_DrawSpanMedium;
        fuzzcolfunc := R_DrawFuzzColumn;
        lightcolfunc := R_DrawFuzzColumn;
        whitelightcolfunc := R_DrawFuzzColumn;
        redlightcolfunc := R_DrawFuzzColumn;
        greenlightcolfunc := R_DrawFuzzColumn;
        bluelightcolfunc := R_DrawFuzzColumn;
        yellowlightcolfunc := R_DrawFuzzColumn;
        skycolfunc := R_DrawSkyColumn;
        videomode := vm8bit;
      end;
    DL_NORMAL:
      begin
        colfunc := R_DrawColumnHi;
        wallcolfunc := R_DrawColumnHi;
        transcolfunc := R_DrawTranslatedColumnHi;
        averagecolfunc := R_DrawColumnAverageHi;
        alphacolfunc := R_DrawColumnAlphaHi;
        maskedcolfunc := R_DrawMaskedColumnNormal;
        maskedcolfunc2 := R_DrawMaskedColumnHi32;
        spanfunc := R_DrawSpanNormal;
        if use32bitfuzzeffect then
          fuzzcolfunc := R_DrawFuzzColumn32
        else
          fuzzcolfunc := R_DrawFuzzColumnHi;
        lightcolfunc := R_DrawWhiteLightColumnHi;
        whitelightcolfunc := R_DrawWhiteLightColumnHi;
        redlightcolfunc := R_DrawRedLightColumnHi;
        greenlightcolfunc := R_DrawGreenLightColumnHi;
        bluelightcolfunc := R_DrawBlueLightColumnHi;
        yellowlightcolfunc := R_DrawYellowLightColumnHi;
        skycolfunc := R_DrawSkyColumnHi;
        videomode := vm32bit;
      end;
  end;

end;

//
// R_ExecuteSetViewSize
//
procedure R_ExecuteSetViewSize;
var
  cosadj: fixed_t;
  dy: fixed_t;
  i: integer;
  j: integer;
  level: integer;
  startmap: integer;
  levelhi: integer;
  startmaphi: integer;
begin
  setsizeneeded := false;

  if setblocks > 10 then
  begin
    scaledviewwidth := SCREENWIDTH;
    viewheight := SCREENHEIGHT;
  end
  else
  begin
    if setblocks = 10 then
      scaledviewwidth := SCREENWIDTH
    else
      scaledviewwidth := (setblocks * SCREENWIDTH div 10) and (not 7);
    if setblocks = 10 then
      viewheight := V_PreserveY(ST_Y)
    else
      viewheight := (setblocks * V_PreserveY(ST_Y) div 10) and (not 7);
  end;

  viewwidth := scaledviewwidth;

  centery := viewheight div 2;
  centerx := viewwidth div 2;

  centerxfrac := centerx * FRACUNIT;
  centeryfrac := centery * FRACUNIT;

  // JVAL: Widescreen support
  monitor_relative_aspect := R_GetRelativeAspect;
  projection := Round(centerx / monitor_relative_aspect * FRACUNIT);
  projectiony := round(((SCREENHEIGHT * centerx * 320) / 200) / SCREENWIDTH * FRACUNIT); // JVAL for correct aspect

  if olddetail <> setdetail then
  begin
    olddetail := setdetail;
    R_SetRenderingFunctions;
  end;

  R_InitBuffer(scaledviewwidth, viewheight);

  R_InitTextureMapping;

  // psprite scales
  pspritescale := FRACUNIT * viewwidth div 320;
  pspriteiscale := FRACUNIT * 320 div viewwidth;
  pspriteyscale := (((SCREENHEIGHT * viewwidth) div SCREENWIDTH) * FRACUNIT) div 200;

  // JVAL: Widescreen support
  pspritescale := Round((centerx / monitor_relative_aspect * FRACUNIT) / 160);
  pspriteyscale := Round((((SCREENHEIGHT * viewwidth) / SCREENWIDTH) * FRACUNIT) / 200);
  pspriteiscale := FixedDiv(FRACUNIT, pspritescale);

  if excludewidescreenplayersprites then
    pspritescalep := Round((centerx * FRACUNIT) / 160)
  else
    pspritescalep := Round((centerx / R_GetRelativeAspect * FRACUNIT) / 160);
  pspriteiscalep := FixedDiv(FRACUNIT, pspritescalep);

  // thing clipping
  for i := 0 to viewwidth - 1 do
    screenheightarray[i] := viewheight;

  // planes
  dy := centeryfrac + FRACUNIT div 2;
  for i := 0 to viewheight - 1 do
  begin
    dy := dy - FRACUNIT;
    yslope[i] := FixedDiv(projectiony, abs(dy)); // JVAL for correct aspect
  end;

  for i := 0 to viewwidth - 1 do
  begin
    cosadj := abs(finecosine[xtoviewangle[i] div ANGLETOFINEUNIT]);
    distscale[i] := FixedDiv(FRACUNIT, cosadj);
  end;

  // Calculate the light levels to use
  //  for each level / scale combination.
  for i := 0 to LIGHTLEVELS - 1 do
  begin
    startmap := ((LIGHTLEVELS - 1 - i) * 2) * NUMCOLORMAPS div LIGHTLEVELS;
    for j := 0 to MAXLIGHTSCALE - 1 do
    begin
      level := startmap - j * SCREENWIDTH div viewwidth div DISTMAP;

      if level < 0 then
        level := 0
      else
      begin
        if level >= NUMCOLORMAPS then
          level := NUMCOLORMAPS - 1;
      end;

      scalelight[i][j] := PByteArray(integer(colormaps) + level * 256);
    end;
  end;

  for i := 0 to LIGHTLEVELS - 1 do
  begin
    startmaphi := ((LIGHTLEVELS - 1 - i) * 2 * FRACUNIT) div LIGHTLEVELS;
    for j := 0 to HLL_MAXLIGHTSCALE - 1 do
    begin
      levelhi := startmaphi - j * 16 * SCREENWIDTH div viewwidth;

      if levelhi < 0 then
        levelhi := 0
      else
      begin
        if levelhi >= FRACUNIT then
          levelhi := FRACUNIT - 1;
      end;

      scalelightlevels[i][j] := FRACUNIT - levelhi;
    end;
  end;


end;


procedure R_CmdZAxisShift(const parm1: string = '');
var
  newz: boolean;
begin
  if parm1 = '' then
  begin
    printf('Current setting: zaxisshift = %s.'#13#10, [truefalseStrings[zaxisshift]]);
    exit;
  end;

  newz := C_BoolEval(parm1, zaxisshift);
  if newz <> zaxisshift then
  begin
    zaxisshift := newz;
    setsizeneeded := true;
  end;
  R_CmdZAxisShift;
end;

procedure R_CmdUse32boitfuzzeffect(const parm1: string = '');
var
  newusefz: boolean;
begin
  if parm1 = '' then
  begin
    printf('Current setting: use32bitfuzzeffect = %s.'#13#10, [truefalseStrings[use32bitfuzzeffect]]);
    exit;
  end;

  newusefz := C_BoolEval(parm1, use32bitfuzzeffect);
  if newusefz <> use32bitfuzzeffect then
  begin
    use32bitfuzzeffect := newusefz;
    R_SetRenderingFunctions;
  end;
  R_CmdUse32boitfuzzeffect;
end;

procedure R_CmdClearCache;
begin
  R_Clear32Cache;
  Z_FreeTags(PU_CACHE, PU_CACHE);
  printf('Texture cache clear'#13#10);
end;

procedure R_CmdResetCache;
begin
  R_Reset32Cache;
  Z_FreeTags(PU_CACHE, PU_CACHE);
  printf('Texture cache reset'#13#10);
end;



//
// R_Init
//
procedure R_Init;
begin
  printf(#13#10 + 'R_Init32Cache');
  R_Init32Cache;
  printf(#13#10 + 'R_InitAspect');
  R_InitAspect;
  printf(#13#10 + 'R_InitData');
  R_InitData;
  printf(#13#10 + 'R_InitInterpolations');
  R_InitInterpolations;
  printf(#13#10 + 'R_InitTables');
  R_InitTables;
  printf(#13#10 + 'R_SetViewSize');
  // viewwidth / viewheight / detailLevel are set by the defaults
  R_SetViewSize;
  printf(#13#10 + 'R_InitPlanes');
  R_InitPlanes;
  printf(#13#10 + 'R_InitLightTables');
  R_InitLightTables;
  printf(#13#10 + 'R_InitSkyMap');
  R_InitSkyMap;
  printf(#13#10 + 'R_InitTranslationsTables');
  R_InitTranslationTables;
  printf(#13#10 + 'R_InitTransparency8Tables');
  R_InitTransparency8Tables;

  framecount := 0;

  C_AddCmd('zaxisshift', @R_CmdZAxisShift);
  C_AddCmd('mediumres, mediumresolution', @R_CmdMediumRes);
  C_AddCmd('normalres, normalresolution', @R_CmdNormalRes);
  C_AddCmd('detaillevel', @R_CmdDetailLevel);
  C_AddCmd('fullscreen', @R_CmdFullScreen);
  C_AddCmd('extremeflatfiltering', @R_CmdExtremeflatfiltering);
  C_AddCmd('32bittexturepaletteeffects, use32bittexturepaletteeffects', @R_Cmd32bittexturepaletteeffects);
  C_AddCmd('useexternaltextures', @R_CmdUseExternalTextures);
  C_AddCmd('use32bitfuzzeffect', @R_CmdUse32boitfuzzeffect);
  C_AddCmd('lightboostfactor', @R_CmdLightBoostFactor);
  C_AddCmd('clearcache, cleartexturecache', @R_CmdClearCache);
  C_AddCmd('resetcache, resettexturecache', @R_CmdResetCache);
end;

procedure R_ShutDown;
begin
  printf(#13#10 + 'R_ShutDownLightBoost');
  R_ShutDownLightBoost;
  printf(#13#10 + 'R_ShutDown32Cache');
  R_ShutDown32Cache;
  printf(#13#10 + 'R_ShutDownInterpolation');
  R_ResetInterpolationBuffer;
  printf(#13#10 + 'R_FreeTransparency8Tables');
  R_FreeTransparency8Tables;
  printf(#13#10);

end;

//
// R_PointInSubsector
//
function R_PointInSubsector(const x: fixed_t; const y: fixed_t): Psubsector_t;
var
  node: Pnode_t;
  nodenum: integer;
begin
  // single subsector is a special case
  if numnodes = 0 then
  begin
    result := @subsectors[0];
    exit;
  end;

  nodenum := numnodes - 1;

  while nodenum and NF_SUBSECTOR = 0 do
  begin
    node := @nodes[nodenum];
    if R_PointOnSide(x, y, node) then
      nodenum := node.children[1]
    else
      nodenum := node.children[0]
  end;

  result := @subsectors[nodenum and (not NF_SUBSECTOR)];
end;

//
// R_AdjustChaseCamera
//
// JVAL: Adjust the chace camera position
//       A bit clumsy but works OK
//
const
  CAMERARADIOUS = 8 * FRACUNIT;

procedure R_AdjustChaseCamera;
var
  c_an: angle_t;
  cx, cy, cz: fixed_t;
  dx, dy: fixed_t;
  loops: integer;
  sec: Psector_t;
  ceilz, floorz: fixed_t;
begin

  if chasecamera then
  begin
    sec := Psubsector_t(viewplayer.mo.subsector).sector;
    ceilz := sec.ceilingheight + P_SectorJumpOverhead(sec) - CAMERARADIOUS;
    cz := viewz + chasecamera_viewz * FRACUNIT;
    if cz > ceilz then
      cz := ceilz
    else
    begin
      floorz := sec.floorheight + CAMERARADIOUS;
      if cz < floorz then
        cz := floorz
    end;


    c_an := (viewangle + ANG180) shr ANGLETOFINESHIFT;
    dx := chasecamera_viewxy * finecosine[c_an];
    dy := chasecamera_viewxy * finesine[c_an];

    loops := 0;
    repeat
      cx := viewx + dx;
      cy := viewy + dy;
      if P_CheckCameraSight(cx, cy, cz, viewplayer.mo) then
        break;
      dx := dx * 31 div 32;
      dy := dy * 31 div 32;
      inc(loops);
    until loops > 64;
    if loops > 1 then
      R_PlayerViewBlanc(aprox_black);
    viewx := cx;
    viewy := cy;
    viewz := cz;
  end;

end;


//
// R_SetupFrame
//
procedure R_SetupFrame(player: Pplayer_t);
var
  i: integer;
  cy, dy: fixed_t;
  blocks: integer;
begin
  viewplayer := player;
  viewx := player.mo.x;
  viewy := player.mo.y;
  shiftangle := player.lookleftright;
  viewangle := player.mo.angle + shiftangle * DIR256TOANGLEUNIT + viewangleoffset;
  extralight := player.extralight;

  viewz := player.viewz;

  R_AdjustChaseCamera;

//******************************
// JVAL Enabled z axis shift
  if zaxisshift and ((player.lookupdown <> 0) or p_justspawned) and (viewangleoffset = 0) then
  begin
    blocks := screenblocks;
    if blocks > 11 then
      blocks := 11;
    cy := Round((viewheight + ((player.lookupdown * blocks) / 16) * SCREENHEIGHT / 1000) / 2);   // JVAL Smooth Look Up/Down
    if centery <> cy then
    begin
      centery := cy;
      centeryfrac := centery * FRACUNIT;
      dy := -centeryfrac - FRACUNIT div 2;
      for i := 0 to viewheight - 1 do
      begin
        dy := dy + FRACUNIT;
        yslope[i] := FixedDiv(projectiony, abs(dy));
      end;

    end;
  end
  else
    p_justspawned := false;
//******************************

  viewsin := finesine[_SHRW(viewangle, ANGLETOFINESHIFT)];
  viewcos := finecosine[_SHRW(viewangle, ANGLETOFINESHIFT)];

  dviewsin := Sin(viewangle / $FFFFFFFF * 2 * pi);
  dviewcos := Cos(viewangle / $FFFFFFFF * 2 * pi);
  // JVAL: Widescreen support
  relativeaspect := 320 / 200 * 65536.0 * SCREENHEIGHT / SCREENWIDTH * monitor_relative_aspect;

  sscount := 0;

  fixedcolormapnum := player.fixedcolormap;
  if fixedcolormapnum <> 0 then
  begin
    fixedcolormap := PByteArray(
      integer(colormaps) + fixedcolormapnum * 256);

    walllights := @scalelightfixed;

    for i := 0 to MAXLIGHTSCALE - 1 do
      scalelightfixed[i] := fixedcolormap;
  end
  else
    fixedcolormap := nil;

  inc(framecount);
  inc(validcount);
end;

procedure R_SetViewAngleOffset(const angle: angle_t);
begin
  viewangleoffset := angle;
end;

function R_FullStOn: boolean;
begin
  result := setblocks = 11;
end;

function R_GetColormapLightLevel(const cmap: PByteArray): fixed_t;
begin
  if cmap = nil then
    result := -1
  else
    result := FRACUNIT - (integer(cmap) - integer(colormaps)) div 256 * FRACUNIT div NUMCOLORMAPS;
end;

function R_GetColormap32(const cmap: PByteArray): PLongWordArray;
begin
  if cmap = nil then
    result := @colormaps32[6 * 256] // FuzzLight
  else
    result := @colormaps32[(integer(cmap) - integer(colormaps))];
end;

//
// R_RenderView
//

procedure R_RenderPlayerView(player: Pplayer_t);
begin
  R_CalcHiResTables;

  R_SetupFrame(player);

  // Clear buffers.
  R_ClearClipSegs;
  R_ClearDrawSegs;
  R_ClearPlanes;
  R_ClearSprites;

  // check for new console commands.
  NetUpdate;

  // The head node is the last node output.
  R_RenderBSPNode(numnodes - 1);

  // Check for new console commands.
  NetUpdate;

  R_DrawPlanes;

  // Check for new console commands.
  NetUpdate;

  R_DrawMasked;

  R_DrawPlayer;
  
  // Check for new console commands.
  NetUpdate;

end;

procedure R_Ticker;
begin
  R_InterpolateTicker;
end;

end.
