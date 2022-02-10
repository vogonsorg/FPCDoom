//------------------------------------------------------------------------------
//
//  FPCDoom - Port of Doom to Free Pascal Compiler
//  Copyright (C) 1993-1996 by id Software, Inc.
//  Copyright (C) 2004-2007 by Jim Valavanis
//  Copyright (C) 2017-2022 by Jim Valavanis
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

unit r_defs;

interface

uses
  d_fpc,
  tables,
// Some more or less basic data types
// we depend on.
  m_fixed,
// We rely on the thinker data struct
// to handle sound origins in sectors.
  d_think,
// SECTORS do store MObjs anyway.
  p_mobj_h,
  t_main,
  w_wad;

// Silhouette, needed for clipping Segs (mainly)
// and sprites representing things.
const
  SIL_NONE = 0;
  SIL_BOTTOM = 1;
  SIL_TOP = 2;
  SIL_BOTH = 3;

  MAXDRAWSEGS = 2048; // JVAL Original was 256

var
  needsbackscreen: boolean = false;

const
  NUMCOLORMAPS = 32;

type
//
// INTERNAL MAP TYPES
//  used by play and refresh
//

//
// Your plain vanilla vertex.
// Note: transformed values not buffered locally,
//  like some DOOM-alikes ("wt", "WebView") did.
//
  vertex_t = packed record
    x: fixed_t;
    y: fixed_t;
    r_x: fixed_t;
    r_y: fixed_t;
  end;
  Pvertex_t = ^vertex_t;
  vertex_tArray = packed array[0..$FFFF] of vertex_t;
  Pvertex_tArray = ^vertex_tArray;

{// Forward of LineDefs, for Sectors.
  line_t = record;}

// Each sector has a degenmobj_t in its center
//  for sound origin purposes.
// I suppose this does not handle sound from
//  moving objects (doppler), because
//  position is prolly just buffered, not
//  updated.
  degenmobj_t = packed record
    thinker: thinker_t; // not used for anything
    x: fixed_t;
    y: fixed_t;
    z: fixed_t;
  end;
  Pdegenmobj_t = ^degenmobj_t;

  Pline_tArray = ^line_tArray;
  Pline_tPArray = ^line_tPArray;
//
// The SECTORS record, at runtime.
// Stores things/mobjs.
//
  sector_t = packed record
    floorheight: fixed_t;
    ceilingheight: fixed_t;
    floorpic: smallint;
    ceilingpic: smallint;
    lightlevel: smallint;
    special: smallint;
    tag: smallint;

    // 0 = untraversed, 1,2 = sndlines -1
    soundtraversed: integer;

    // thing that made a sound (or null)
    soundtarget: Pmobj_t;

    // mapblock bounding box for height changes
    blockbox: array[0..3] of integer;

    // origin for any sounds played by the sector
    soundorg: degenmobj_t;

    // if == validcount, already checked
    validcount: integer;

    // list of mobjs in sector
    thinglist: Pmobj_t;

    // thinker_t for reversable actions
    specialdata: pointer;

    cachedheight: integer;
    scaleindex: integer;

    linecount: integer;
    lines: Pline_tPArray; // [linecount] size
  end;
  Psector_t = ^sector_t;
  sector_tArray = packed array[0..$FFFF] of sector_t;
  Psector_tArray = ^sector_tArray;

//
// The SideDef.
//

  side_t = packed record
    // add this to the calculated texture column
    textureoffset: fixed_t;

    // add this to the calculated texture top
    rowoffset: fixed_t;

    // Texture indices.
    // We do not maintain names here.
    toptexture: smallint;
    bottomtexture: smallint;
    midtexture: smallint;

    // Sector the SideDef is facing.
    sector: Psector_t;
  end;
  Pside_t = ^side_t;
  side_tArray = packed array[0..$FFFF] of side_t;
  Pside_tArray = ^side_tArray;

//
// Move clipping aid for LineDefs.
//
  slopetype_t = (
    ST_HORIZONTAL,
    ST_VERTICAL,
    ST_POSITIVE,
    ST_NEGATIVE
  );

  line_t = packed record
    // Vertices, from v1 to v2.
    v1: Pvertex_t;
    v2: Pvertex_t;

    // Precalculated v2 - v1 for side checking.
    dx: fixed_t;
    dy: fixed_t;

    // Precalculated length for mirror mode
    len: fixed_t;

    // Animation related.
    flags: smallint;
    special: smallint;
    tag: smallint;

    // Visual appearance: SideDefs.
    //  sidenum[1] will be -1 if one sided
    sidenum: packed array[0..1] of smallint;

    // Neat. Another bounding box, for the extent
    //  of the LineDef.
    bbox: packed array[0..3] of fixed_t;

    // To aid move clipping.
    slopetype: slopetype_t;

    // Front and back sector.
    // Note: redundant? Can be retrieved from SideDefs.
    frontsector: Psector_t;
    backsector: Psector_t;

    // if == validcount, already checked
    validcount: integer;

    // thinker_t for reversable actions
    specialdata: pointer;
  end;
  Pline_t = ^line_t;
  line_tArray = packed array[0..$FFFF] of line_t;
  line_tPArray = packed array[0..$FFFF] of Pline_t;

//
// A SubSector.
// References a Sector.
// Basically, this is a list of LineSegs,
//  indicating the visible walls that define
//  (all or some) sides of a convex BSP leaf.
//
  subsector_t = packed record
    sector: Psector_t;
    numlines: smallint;
    firstline: smallint;
  end;
  Psubsector_t = ^subsector_t;
  subsector_tArray = packed array[0..$FFFF] of subsector_t;
  Psubsector_tArray = ^subsector_tArray;

//
// The LineSeg.
//
  seg_t = packed record
    v1: Pvertex_t;
    v2: Pvertex_t;

    offset: fixed_t;

    angle: angle_t;

    sidedef: Pside_t;
    linedef: Pline_t;

    // Sector references.
    // Could be retrieved from linedef, too.
    // backsector is NULL for one sided lines
    frontsector: Psector_t;
    backsector: Psector_t;
    r_normalangle: angle_t;
    inv_length: double;
  end;
  Pseg_t = ^seg_t;
  seg_tArray = packed array[0..$FFFF] of seg_t;
  Pseg_tArray = ^seg_tArray;

//
// BSP node.
//
  node_t = packed record
    // Partition line.
    x: fixed_t;
    y: fixed_t;
    dx: fixed_t;
    dy: fixed_t;

    // Bounding box for each child.
    bbox: packed array[0..1, 0..3] of fixed_t;

    // If NF_SUBSECTOR its a subsector.
    children: packed array[0..1] of word;
  end;
  Pnode_t = ^node_t;
  node_tArray = packed array[0..$FFFF] of node_t;
  Pnode_tArray = ^node_tArray;

// posts are runs of non masked source pixels
  post_t = packed record
    topdelta: byte; // -1 is the last post in a column
    length: byte;   // length data bytes follows
  end;
  Ppost_t = ^post_t;

// column_t is a list of 0 or more post_t, (byte)-1 terminated
  column_t = post_t;
  Pcolumn_t = ^column_t;

//
// OTHER TYPES
//

//
// ?
//
  drawseg_t = packed record
    curline: Pseg_t;
    x1: integer;
    x2: integer;

    scale1: fixed_t;
    scale2: fixed_t;

    // 0=none, 1=bottom, 2=top, 3=both
    silhouette: integer;

    // do not clip sprites above this
    bsilheight: fixed_t;

    // do not clip sprites below this
    tsilheight: fixed_t;

    // Pointers to lists for sprite clipping,
    //  all three adjusted so [x1] is first value.
    sprtopclip: PSmallIntArray;
    sprbottomclip: PSmallIntArray;
    maskedtexturecol: PSmallIntArray;
  end;
  Pdrawseg_t = ^drawseg_t;

// Patches.
// A patch holds one or more columns.
// Patches are used for sprites and all masked pictures,
// and we compose textures from the TEXTURE1/2 lists
// of patches.
  patch_t = packed record
    width: smallint; // bounding box size
    height: smallint;
    leftoffset: smallint; // pixels to the left of origin
    topoffset: smallint;  // pixels below the origin
    columnofs: array[0..7] of integer; // only [width] used
    // the [0] is &columnofs[width]
  end;
  Ppatch_t = ^patch_t;
  patch_tArray = packed array[0..$FFFF] of patch_t;
  Ppatch_tArray = ^patch_tArray;
  patch_tPArray = packed array[0..$FFFF] of Ppatch_t;
  Ppatch_tPArray = ^patch_tPArray;

// A vissprite_t is a thing
//  that will be drawn during a refresh.
// I.e. a sprite object that is partly visible.
  Pvissprite_t = ^vissprite_t;
  vissprite_t = packed record
    // Doubly linked list.
    prev: Pvissprite_t;
    next: Pvissprite_t;

    x1: integer;
    x2: integer;

    // for line side calculation
    gx: fixed_t;
    gy: fixed_t;

    // global bottom / top for silhouette clipping
    gz: fixed_t;
    gzt: fixed_t;

    // horizontal position of x1
    startfrac: fixed_t;

    scale: fixed_t;

    // negative if flipped
    xiscale: fixed_t;

    texturemid: fixed_t;
    patch: integer;

    // for color translation and shadow draw,
    //  maxbright frames as well
    colormap: PByteArray;

    mobjflags: integer;
    mobjflags_ex: integer;
    mobjflags2_ex: integer;
    mo: Pmobj_t;
    _type: integer;
    infoscale: fixed_t;
  end;

//
// Sprites are patches with a special naming convention
//  so they can be recognized by R_InitSprites.
// The base name is NNNNFx or NNNNFxFx, with
//  x indicating the rotation, x = 0, 1-7.
// The sprite and frame specified by a thing_t
//  is range checked at run time.
// A sprite is a patch_t that is assumed to represent
//  a three dimensional object and may have multiple
//  rotations pre drawn.
// Horizontal flipping is used to save space,
//  thus NNNNF2F5 defines a mirrored patch.
// Some sprites will only have one picture used
// for all views: NNNNF0
//
  spriteframe_t = packed record
    // If false use 0 for any position.
    // Note: as eight entries are available,
    //  we might as well insert the same name eight times.
    rotate: integer;

    // Lump to use for view angles 0-7.
    lump: array[0..7] of integer;

    // Flip bit (1 = flip) to use for view angles 0-7.
    flip: array[0..7] of boolean;
  end;
  Pspriteframe_t = ^spriteframe_t;
  spriteframe_tArray = packed array[0..$FFFF] of spriteframe_t;
  Pspriteframe_tArray = ^spriteframe_tArray;

//
// A sprite definition:
//  a number of animation frames.
//
  spritedef_t = packed record
    numframes: integer;
    spriteframes: Pspriteframe_tArray;
  end;
  Pspritedef_t = ^spritedef_t;
  spritedef_tArray = packed array[0..$FFFF] of spritedef_t;
  Pspritedef_tArray = ^spritedef_tArray;

const
  VISEND = $FFFF;
  iVISEND = integer($FFFFFFFF);

type
  visindex_t = word;
  Pvisindex_t = ^visindex_t;
  visindex_tArray = packed array[-1..$FFFF] of visindex_t;
  Pvisindex_tArray = ^visindex_tArray;

//
// Now what is a visplane, anyway?
//
  visplane_t = packed record
    height: fixed_t;
    picnum: integer;
    lightlevel: integer;
    minx: integer;
    maxx: integer;

    // leave pads for [minx-1] and [maxx+1]
    top: Pvisindex_tArray;    // Now allocated dynamically!

    // See above.
    bottom: Pvisindex_tArray; // Now allocated dynamically!
  end;
  Pvisplane_t = ^visplane_t;

//
// Texture definition.
// Each texture is composed of one or more patches,
// with patches being lumps stored in the WAD.
// The lumps are referenced by number, and patched
// into the rectangular texture space using origin
// and possibly other attributes.
//
type
  mappatch_t = record
    originx: smallint;
    originy: smallint;
    patch: smallint;
    stepdir: smallint;
    colormap: smallint;
  end;
  Pmappatch_t = ^mappatch_t;

//
// Texture definition.
// A DOOM wall texture is a list of patches
// which are to be combined in a predefined order.
//
  maptexture_t = packed record
    name: char8_t;
    masked: integer;
    width: smallint;
    height: smallint;
    filler: LongWord; // unused
    patchcount: smallint;
    patches: array[0..0] of mappatch_t;
  end;
  Pmaptexture_t = ^maptexture_t;

// A single patch from a texture definition,
//  basically a rectangular area within
//  the texture rectangle.
  texpatch_t = packed record
    // Block origin (allways UL),
    // which has allready accounted
    // for the internal origin of the patch.
    originx: integer;
    originy: integer;
    patch: integer;
  end;
  Ptexpatch_t = ^texpatch_t;

// A maptexturedef_t describes a rectangular texture,
//  which is composed of one or more mappatch_t structures
//  that arrange graphic patches.
  texture_t = packed record
    // Keep name for switch changing, etc.
    name: char8_t;
    width: smallint;
    height: smallint;
    factorbits: integer;

    // All the patches[patchcount]
    //  are drawn back to front into the cached texture.
    texture32: PTexture;  // JVAL: External texture reference
    patchcount: smallint;
    patches: array[0..0] of texpatch_t;
  end;
  Ptexture_t = ^texture_t;
  texture_tPArray = array[0..$FFFF] of Ptexture_t;
  Ptexture_tPArray = ^texture_tPArray;

  // JVAL added flat record
  flat_t = packed record
    // Keep name for switch changing, etc.
    name: char8_t;
    width: smallint;  // Optional ??
    height: smallint;
    flat32: PTexture; // External texture reference
    terraintype: integer; // JVAL: 9 December 2007, Added terrain types
    translation: integer;
    lump: integer;
  end;
  Pflat_t = ^flat_t;
  flatPArray = array[0..$FFFF] of Pflat_t;
  PflatPArray = ^flatPArray;

var
  numspritelumps: integer;

  texturewidthmask: PIntegerArray;

  texturecolumnlump: PSmallIntPArray;
  texturecolumnofs: PIntegerPArray; // PWordPArray; //64k
  texturecomposite: PBytePArray;

//
// MAPTEXTURE_T CACHING
// When a texture is first needed,
//  it counts the number of composite columns
//  required in the texture and allocates space
//  for a column directory and any new columns.
// The directory will simply point inside other patches
//  if there is only one patch in a given column,
//  but any columns with multiple patches
//  will have new column_ts generated.
//

//
// Render item types
//
const
  RIT_NONE = 0;
  RIT_SKY = 0;
  RIT_FLAT = 1;
  RIT_WALL = 2;
  RIT_MASKEDWALL = 3;
  RIT_SPRITE = 4;

implementation

end.
