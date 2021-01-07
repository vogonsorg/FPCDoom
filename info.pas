//------------------------------------------------------------------------------
//
//  FPCDoom - Port of Doom to Free Pascal Compiler
//  Copyright (C) 1993-1996 by id Software, Inc.
//  Copyright (C) 2004-2007 by Jim Valavanis
//  Copyright (C) 2017-2021 by Jim Valavanis
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

unit info;

interface

uses
  d_fpc,
  d_think,
  info_h;

type
  statesArray_t = packed array[0..$FFFF] of state_t;
  PstatesArray_t = ^statesArray_t;

  sprnamesArray_t = packed array[0..Ord(DO_NUMSPRITES) - 1] of string[4];
  PsprnamesArray_t = ^sprnamesArray_t;

  mobjinfoArray_t = packed array[0..Ord(DO_NUMMOBJTYPES) - 1] of mobjinfo_t;
  PmobjinfoArray_t = ^mobjinfoArray_t;

var
  states: PstatesArray_t = nil;
  numstates: integer = Ord(DO_NUMSTATES);
  sprnames: PIntegerArray = nil;
  numsprites: integer = Ord(DO_NUMSPRITES);
  mobjinfo: PmobjinfoArray_t = nil;
  nummobjtypes: integer = Ord(DO_NUMMOBJTYPES);

procedure Info_Init(const usethinkers: boolean);

function Info_GetNewState: integer;
function Info_GetNewMobjInfo: integer;
function Info_GetSpriteNumForName(const name: string): integer;
function Info_GetMobjNumForName(const name: string): integer;
procedure Info_SetMobjName(const mobj_no: integer; const name: string);
function Info_GetMobjName(const mobj_no: integer): string;

procedure Info_ShutDown;

function Info_GetInheritance(const imo: Pmobjinfo_t): integer;

implementation

uses
  i_system,
  m_fixed,
  p_enemy,
  p_extra,
  p_pspr,
  p_mobj_h,
  r_renderstyle,
  sounds;

const
  DO_states: array[0..Ord(DO_NUMSTATES) - 1] of state_t = (
   (
    sprite: Ord(SPR_TROO);    // sprite
    frame: 0;                 // frame
    tics: -1;                 // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_NULL;        // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_NULL

   (
    sprite: Ord(SPR_SHTG);    // sprite
    frame: 4;                 // frame
    tics: 0;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_NULL;        // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_LIGHTDONE

   (
    sprite: Ord(SPR_PUNG);    // sprite
    frame: 0;                 // frame
    tics: 1;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_PUNCH;       // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_PUNCH

   (
    sprite: Ord(SPR_PUNG);    // sprite
    frame: 0;                 // frame
    tics: 1;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_PUNCHDOWN;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_PUNCHDOWN

   (
    sprite: Ord(SPR_PUNG);    // sprite
    frame: 0;                 // frame
    tics: 1;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_PUNCHUP;     // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_PUNCHUP

   (
    sprite: Ord(SPR_PUNG);    // sprite
    frame: 1;                 // frame
    tics: 4;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_PUNCH2;      // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_PUNCH1

   (
    sprite: Ord(SPR_PUNG);    // sprite
    frame: 2;                 // frame
    tics: 4;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_PUNCH3;      // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_PUNCH2

   (
    sprite: Ord(SPR_PUNG);    // sprite
    frame: 3;                 // frame
    tics: 5;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_PUNCH4;      // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_PUNCH3

   (
    sprite: Ord(SPR_PUNG);    // sprite
    frame: 2;                 // frame
    tics: 4;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_PUNCH5;      // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_PUNCH4

   (
    sprite: Ord(SPR_PUNG);    // sprite
    frame: 1;                 // frame
    tics: 5;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_PUNCH;       // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_PUNCH5

   (
    sprite: Ord(SPR_PISG);    // sprite
    frame: 0;                 // frame
    tics: 1;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_PISTOL;      // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_PISTOL

   (
    sprite: Ord(SPR_PISG);    // sprite
    frame: 0;                 // frame
    tics: 1;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_PISTOLDOWN;  // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_PISTOLDOWN

   (
    sprite: Ord(SPR_PISG);    // sprite
    frame: 0;                 // frame
    tics: 1;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_PISTOLUP;    // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_PISTOLUP

   (
    sprite: Ord(SPR_PISG);    // sprite
    frame: 0;                 // frame
    tics: 4;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_PISTOL2;     // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_PISTOL1

   (
    sprite: Ord(SPR_PISG);    // sprite
    frame: 1;                 // frame
    tics: 6;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_PISTOL3;     // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                // S_PISTOL2

   (
    sprite: Ord(SPR_PISG);    // sprite
    frame: 2;                 // frame
    tics: 4;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_PISTOL4;     // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_PISTOL3

   (
    sprite: Ord(SPR_PISG);    // sprite
    frame: 1;                 // frame
    tics: 5;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_PISTOL;      // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_PISTOL4

   (
    sprite: Ord(SPR_PISF);    // sprite
    frame: 32768;             // frame
    tics: 7;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_LIGHTDONE;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_PISTOLFLASH

   (
    sprite: Ord(SPR_SHTG);    // sprite
    frame: 0;                 // frame
    tics: 1;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_SGUN;        // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_SGUN

   (
    sprite: Ord(SPR_SHTG);    // sprite
    frame: 0;                 // frame
    tics: 1;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_SGUNDOWN;    // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_SGUNDOWN

   (
    sprite: Ord(SPR_SHTG);    // sprite
    frame: 0;                 // frame
    tics: 1;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_SGUNUP;      // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_SGUNUP

   (
    sprite: Ord(SPR_SHTG);    // sprite
    frame: 0;                 // frame
    tics: 3;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_SGUN2;       // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_SGUN1

   (
    sprite: Ord(SPR_SHTG);    // sprite
    frame: 0;                 // frame
    tics: 7;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_SGUN3;       // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_SGUN2

   (
    sprite: Ord(SPR_SHTG);    // sprite
    frame: 1;                 // frame
    tics: 5;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_SGUN4;       // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_SGUN3

   (
    sprite: Ord(SPR_SHTG);    // sprite
    frame: 2;                 // frame
    tics: 5;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_SGUN5;       // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_SGUN4

   (
    sprite: Ord(SPR_SHTG);    // sprite
    frame: 3;                 // frame
    tics: 4;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_SGUN6;       // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_SGUN5

   (
    sprite: Ord(SPR_SHTG);    // sprite
    frame: 2;                 // frame
    tics: 5;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_SGUN7;       // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_SGUN6

   (
    sprite: Ord(SPR_SHTG);    // sprite
    frame: 1;                 // frame
    tics: 5;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_SGUN8;       // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_SGUN7

   (
    sprite: Ord(SPR_SHTG);    // sprite
    frame: 0;                 // frame
    tics: 3;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_SGUN9;       // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_SGUN8

   (
    sprite: Ord(SPR_SHTG);    // sprite
    frame: 0;                 // frame
    tics: 7;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_SGUN;        // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_SGUN9

   (
    sprite: Ord(SPR_SHTF);    // sprite
    frame: 32768;             // frame
    tics: 4;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_SGUNFLASH2;  // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_SGUNFLASH1

   (
    sprite: Ord(SPR_SHTF);    // sprite
    frame: 32769;             // frame
    tics: 3;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_LIGHTDONE;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_SGUNFLASH2

   (
    sprite: Ord(SPR_SHT2);    // sprite
    frame: 0;                 // frame
    tics: 1;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_DSGUN;       // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_DSGUN

   (
    sprite: Ord(SPR_SHT2);    // sprite
    frame: 0;                 // frame
    tics: 1;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_DSGUNDOWN;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_DSGUNDOWN

   (
    sprite: Ord(SPR_SHT2);    // sprite
    frame: 0;                 // frame
    tics: 1;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_DSGUNUP;     // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_DSGUNUP

   (
    sprite: Ord(SPR_SHT2);    // sprite
    frame: 0;                 // frame
    tics: 3;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_DSGUN2;      // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_DSGUN1

   (
    sprite: Ord(SPR_SHT2);    // sprite
    frame: 0;                 // frame
    tics: 7;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_DSGUN3;      // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_DSGUN2

   (
    sprite: Ord(SPR_SHT2);    // sprite
    frame: 1;                 // frame
    tics: 7;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_DSGUN4;      // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_DSGUN3

   (
    sprite: Ord(SPR_SHT2);    // sprite
    frame: 2;                 // frame
    tics: 7;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_DSGUN5;      // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_DSGUN4

   (
    sprite: Ord(SPR_SHT2);    // sprite
    frame: 3;                 // frame
    tics: 7;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_DSGUN6;      // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_DSGUN5

   (
    sprite: Ord(SPR_SHT2);    // sprite
    frame: 4;                 // frame
    tics: 7;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_DSGUN7;      // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_DSGUN6

   (
    sprite: Ord(SPR_SHT2);    // sprite
    frame: 5;                 // frame
    tics: 7;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_DSGUN8;      // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_DSGUN7

   (
    sprite: Ord(SPR_SHT2);    // sprite
    frame: 6;                 // frame
    tics: 6;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_DSGUN9;      // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_DSGUN8

   (
    sprite: Ord(SPR_SHT2);    // sprite
    frame: 7;                 // frame
    tics: 6;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_DSGUN10;     // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_DSGUN9

   (
    sprite: Ord(SPR_SHT2);    // sprite
    frame: 0;                 // frame
    tics: 5;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_DSGUN;       // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_DSGUN10

   (
    sprite: Ord(SPR_SHT2);    // sprite
    frame: 1;                 // frame
    tics: 7;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_DSNR2;       // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_DSNR1

   (
    sprite: Ord(SPR_SHT2);    // sprite
    frame: 0;                 // frame
    tics: 3;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_DSGUNDOWN;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_DSNR2

   (
    sprite: Ord(SPR_SHT2);    // sprite
    frame: 32776;             // frame
    tics: 5;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_DSGUNFLASH2;  // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_DSGUNFLASH1

   (
    sprite: Ord(SPR_SHT2);    // sprite
    frame: 32777;             // frame
    tics: 4;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_LIGHTDONE;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_DSGUNFLASH2

   (
    sprite: Ord(SPR_CHGG);    // sprite
    frame: 0;                 // frame
    tics: 1;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_CHAIN;       // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_CHAIN

   (
    sprite: Ord(SPR_CHGG);    // sprite
    frame: 0;                 // frame
    tics: 1;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_CHAINDOWN;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_CHAINDOWN

   (
    sprite: Ord(SPR_CHGG);    // sprite
    frame: 0;                 // frame
    tics: 1;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_CHAINUP;     // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_CHAINUP

   (
    sprite: Ord(SPR_CHGG);    // sprite
    frame: 0;                 // frame
    tics: 4;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_CHAIN2;      // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_CHAIN1

   (
    sprite: Ord(SPR_CHGG);    // sprite
    frame: 1;                 // frame
    tics: 4;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_CHAIN3;      // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_CHAIN2

   (
    sprite: Ord(SPR_CHGG);    // sprite
    frame: 1;                 // frame
    tics: 0;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_CHAIN;       // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_CHAIN3

   (
    sprite: Ord(SPR_CHGF);    // sprite
    frame: 32768;             // frame
    tics: 5;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_LIGHTDONE;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_CHAINFLASH1

   (
    sprite: Ord(SPR_CHGF);    // sprite
    frame: 32769;             // frame
    tics: 5;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_LIGHTDONE;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_CHAINFLASH2

   (
    sprite: Ord(SPR_MISG);    // sprite
    frame: 0;                 // frame
    tics: 1;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_MISSILE;     // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_MISSILE

   (
    sprite: Ord(SPR_MISG);    // sprite
    frame: 0;                 // frame
    tics: 1;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_MISSILEDOWN;  // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_MISSILEDOWN

   (
    sprite: Ord(SPR_MISG);    // sprite
    frame: 0;                 // frame
    tics: 1;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_MISSILEUP;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_MISSILEUP

   (
    sprite: Ord(SPR_MISG);    // sprite
    frame: 1;                 // frame
    tics: 8;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_MISSILE2;    // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_MISSILE1

   (
    sprite: Ord(SPR_MISG);    // sprite
    frame: 1;                 // frame
    tics: 12;                 // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_MISSILE3;    // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_MISSILE2

   (
    sprite: Ord(SPR_MISG);    // sprite
    frame: 1;                 // frame
    tics: 0;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_MISSILE;     // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_MISSILE3

   (
    sprite: Ord(SPR_MISF);    // sprite
    frame: 32768;             // frame
    tics: 3;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_MISSILEFLASH2;  // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_MISSILEFLASH1

   (
    sprite: Ord(SPR_MISF);    // sprite
    frame: 32769;             // frame
    tics: 4;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_MISSILEFLASH3;  // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_MISSILEFLASH2

   (
    sprite: Ord(SPR_MISF);    // sprite
    frame: 32770;             // frame
    tics: 4;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_MISSILEFLASH4;  // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_MISSILEFLASH3

   (
    sprite: Ord(SPR_MISF);    // sprite
    frame: 32771;             // frame
    tics: 4;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_LIGHTDONE;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_MISSILEFLASH4

   (
    sprite: Ord(SPR_SAWG);    // sprite
    frame: 2;                 // frame
    tics: 4;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_SAWB;        // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_SAW

   (
    sprite: Ord(SPR_SAWG);    // sprite
    frame: 3;                 // frame
    tics: 4;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_SAW;         // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_SAWB

   (
    sprite: Ord(SPR_SAWG);    // sprite
    frame: 2;                 // frame
    tics: 1;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_SAWDOWN;     // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_SAWDOWN

   (
    sprite: Ord(SPR_SAWG);    // sprite
    frame: 2;                 // frame
    tics: 1;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_SAWUP;       // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_SAWUP

   (
    sprite: Ord(SPR_SAWG);    // sprite
    frame: 0;                 // frame
    tics: 4;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_SAW2;        // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_SAW1

   (
    sprite: Ord(SPR_SAWG);    // sprite
    frame: 1;                 // frame
    tics: 4;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_SAW3;        // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_SAW2

   (
    sprite: Ord(SPR_SAWG);    // sprite
    frame: 1;                 // frame
    tics: 0;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_SAW;         // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_SAW3

   (
    sprite: Ord(SPR_PLSG);    // sprite
    frame: 0;                 // frame
    tics: 1;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_PLASMA;      // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_PLASMA

   (
    sprite: Ord(SPR_PLSG);    // sprite
    frame: 0;                 // frame
    tics: 1;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_PLASMADOWN;  // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_PLASMADOWN

   (
    sprite: Ord(SPR_PLSG);    // sprite
    frame: 0;                 // frame
    tics: 1;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_PLASMAUP;    // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_PLASMAUP

   (
    sprite: Ord(SPR_PLSG);    // sprite
    frame: 0;                 // frame
    tics: 3;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_PLASMA2;     // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_PLASMA1

   (
    sprite: Ord(SPR_PLSG);    // sprite
    frame: 1;                 // frame
    tics: 20;                 // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_PLASMA;      // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_PLASMA2

   (
    sprite: Ord(SPR_PLSF);    // sprite
    frame: 32768;             // frame
    tics: 4;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_LIGHTDONE;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_PLASMAFLASH1

   (
    sprite: Ord(SPR_PLSF);    // sprite
    frame: 32769;             // frame
    tics: 4;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_LIGHTDONE;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_PLASMAFLASH2

   (
    sprite: Ord(SPR_BFGG);    // sprite
    frame: 0;                 // frame
    tics: 1;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_BFG;         // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_BFG

   (
    sprite: Ord(SPR_BFGG);    // sprite
    frame: 0;                 // frame
    tics: 1;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_BFGDOWN;     // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_BFGDOWN

   (
    sprite: Ord(SPR_BFGG);    // sprite
    frame: 0;                 // frame
    tics: 1;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_BFGUP;       // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_BFGUP

   (
    sprite: Ord(SPR_BFGG);    // sprite
    frame: 0;                 // frame
    tics: 20;                 // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_BFG2;        // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_BFG1

   (
    sprite: Ord(SPR_BFGG);    // sprite
    frame: 1;                 // frame
    tics: 10;                 // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_BFG3;        // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_BFG2

   (
    sprite: Ord(SPR_BFGG);    // sprite
    frame: 1;                 // frame
    tics: 10;                 // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_BFG4;        // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_BFG3

   (
    sprite: Ord(SPR_BFGG);    // sprite
    frame: 1;                 // frame
    tics: 20;                 // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_BFG;         // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_BFG4

   (
    sprite: Ord(SPR_BFGF);    // sprite
    frame: 32768;             // frame
    tics: 11;                 // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_BFGFLASH2;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_BFGFLASH1

   (
    sprite: Ord(SPR_BFGF);    // sprite
    frame: 32769;             // frame
    tics: 6;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_LIGHTDONE;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_BFGFLASH2

   (
    sprite: Ord(SPR_BLUD);    // sprite
    frame: 2;                 // frame
    tics: 8;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_BLOOD2;      // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_BLOOD1

   (
    sprite: Ord(SPR_BLUD);    // sprite
    frame: 1;                 // frame
    tics: 8;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_BLOOD3;      // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_BLOOD2

   (
    sprite: Ord(SPR_BLUD);    // sprite
    frame: 0;                 // frame
    tics: 8;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_NULL;        // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_BLOOD3

   (
    sprite: Ord(SPR_PUFF);    // sprite
    frame: 32768;             // frame
    tics: 4;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_PUFF2;       // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_PUFF1

   (
    sprite: Ord(SPR_PUFF);    // sprite
    frame: 1;                 // frame
    tics: 4;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_PUFF3;       // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_PUFF2

   (
    sprite: Ord(SPR_PUFF);    // sprite
    frame: 2;                 // frame
    tics: 4;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_PUFF4;       // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_PUFF3

   (
    sprite: Ord(SPR_PUFF);    // sprite
    frame: 3;                 // frame
    tics: 4;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_NULL;        // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_PUFF4

   (
    sprite: Ord(SPR_BAL1);    // sprite
    frame: 32768;             // frame
    tics: 4;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_TBALL2;      // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_TBALL1

   (
    sprite: Ord(SPR_BAL1);    // sprite
    frame: 32769;             // frame
    tics: 4;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_TBALL1;      // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_TBALL2

   (
    sprite: Ord(SPR_BAL1);    // sprite
    frame: 32770;             // frame
    tics: 6;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_TBALLX2;     // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_TBALLX1

   (
    sprite: Ord(SPR_BAL1);    // sprite
    frame: 32771;             // frame
    tics: 6;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_TBALLX3;     // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_TBALLX2

   (
    sprite: Ord(SPR_BAL1);    // sprite
    frame: 32772;             // frame
    tics: 6;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_NULL;        // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_TBALLX3

   (
    sprite: Ord(SPR_BAL2);    // sprite
    frame: 32768;             // frame
    tics: 4;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_RBALL2;      // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_RBALL1

   (
    sprite: Ord(SPR_BAL2);    // sprite
    frame: 32769;             // frame
    tics: 4;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_RBALL1;      // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_RBALL2

   (
    sprite: Ord(SPR_BAL2);    // sprite
    frame: 32770;             // frame
    tics: 6;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_RBALLX2;     // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_RBALLX1

   (
    sprite: Ord(SPR_BAL2);    // sprite
    frame: 32771;             // frame
    tics: 6;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_RBALLX3;     // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_RBALLX2

   (
    sprite: Ord(SPR_BAL2);    // sprite
    frame: 32772;             // frame
    tics: 6;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_NULL;        // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_RBALLX3

   (
    sprite: Ord(SPR_PLSS);    // sprite
    frame: 32768;             // frame
    tics: 6;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_PLASBALL2;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_PLASBALL

   (
    sprite: Ord(SPR_PLSS);    // sprite
    frame: 32769;             // frame
    tics: 6;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_PLASBALL;    // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_PLASBALL2

   (
    sprite: Ord(SPR_PLSE);    // sprite
    frame: 32768;             // frame
    tics: 4;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_PLASEXP2;    // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_PLASEXP

   (
    sprite: Ord(SPR_PLSE);    // sprite
    frame: 32769;             // frame
    tics: 4;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_PLASEXP3;    // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_PLASEXP2

   (
    sprite: Ord(SPR_PLSE);    // sprite
    frame: 32770;             // frame
    tics: 4;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_PLASEXP4;    // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_PLASEXP3

   (
    sprite: Ord(SPR_PLSE);    // sprite
    frame: 32771;             // frame
    tics: 4;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_PLASEXP5;    // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_PLASEXP4

   (
    sprite: Ord(SPR_PLSE);    // sprite
    frame: 32772;             // frame
    tics: 4;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_NULL;        // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_PLASEXP5

   (
    sprite: Ord(SPR_MISL);    // sprite
    frame: 32768;             // frame
    tics: 1;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_ROCKET;      // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_ROCKET

   (
    sprite: Ord(SPR_BFS1);    // sprite
    frame: 32768;             // frame
    tics: 4;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_BFGSHOT2;    // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_BFGSHOT

   (
    sprite: Ord(SPR_BFS1);    // sprite
    frame: 32769;             // frame
    tics: 4;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_BFGSHOT;     // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_BFGSHOT2

   (
    sprite: Ord(SPR_BFE1);    // sprite
    frame: 32768;             // frame
    tics: 8;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_BFGLAND2;    // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_BFGLAND

   (
    sprite: Ord(SPR_BFE1);    // sprite
    frame: 32769;             // frame
    tics: 8;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_BFGLAND3;    // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_BFGLAND2

   (
    sprite: Ord(SPR_BFE1);    // sprite
    frame: 32770;             // frame
    tics: 8;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_BFGLAND4;    // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_BFGLAND3

   (
    sprite: Ord(SPR_BFE1);    // sprite
    frame: 32771;             // frame
    tics: 8;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_BFGLAND5;    // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_BFGLAND4

   (
    sprite: Ord(SPR_BFE1);    // sprite
    frame: 32772;             // frame
    tics: 8;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_BFGLAND6;    // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_BFGLAND5

   (
    sprite: Ord(SPR_BFE1);    // sprite
    frame: 32773;             // frame
    tics: 8;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_NULL;        // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_BFGLAND6

   (
    sprite: Ord(SPR_BFE2);    // sprite
    frame: 32768;             // frame
    tics: 8;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_BFGEXP2;     // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_BFGEXP

   (
    sprite: Ord(SPR_BFE2);    // sprite
    frame: 32769;             // frame
    tics: 8;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_BFGEXP3;     // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_BFGEXP2

   (
    sprite: Ord(SPR_BFE2);    // sprite
    frame: 32770;             // frame
    tics: 8;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_BFGEXP4;     // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_BFGEXP3

   (
    sprite: Ord(SPR_BFE2);    // sprite
    frame: 32771;             // frame
    tics: 8;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_NULL;        // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_BFGEXP4

   (
    sprite: Ord(SPR_MISL);    // sprite
    frame: 32769;             // frame
    tics: 8;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_EXPLODE2;    // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_EXPLODE1

   (
    sprite: Ord(SPR_MISL);    // sprite
    frame: 32770;             // frame
    tics: 6;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_EXPLODE3;    // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: MF_EX_TRANSPARENT;
   ),                         // S_EXPLODE2

   (
    sprite: Ord(SPR_MISL);    // sprite
    frame: 32771;             // frame
    tics: 4;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_NULL;        // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: MF_EX_TRANSPARENT;
   ),                         // S_EXPLODE3

   (
    sprite: Ord(SPR_TFOG);    // sprite
    frame: 32768;             // frame
    tics: 6;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_TFOG01;      // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_TFOG

   (
    sprite: Ord(SPR_TFOG);    // sprite
    frame: 32769;             // frame
    tics: 6;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_TFOG02;      // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_TFOG01

   (
    sprite: Ord(SPR_TFOG);    // sprite
    frame: 32768;             // frame
    tics: 6;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_TFOG2;       // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_TFOG02

   (
    sprite: Ord(SPR_TFOG);    // sprite
    frame: 32769;             // frame
    tics: 6;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_TFOG3;       // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_TFOG2

   (
    sprite: Ord(SPR_TFOG);    // sprite
    frame: 32770;             // frame
    tics: 6;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_TFOG4;       // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_TFOG3

   (
    sprite: Ord(SPR_TFOG);    // sprite
    frame: 32771;             // frame
    tics: 6;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_TFOG5;       // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_TFOG4

   (
    sprite: Ord(SPR_TFOG);    // sprite
    frame: 32772;             // frame
    tics: 6;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_TFOG6;       // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_TFOG5

   (
    sprite: Ord(SPR_TFOG);    // sprite
    frame: 32773;             // frame
    tics: 6;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_TFOG7;       // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_TFOG6

   (
    sprite: Ord(SPR_TFOG);    // sprite
    frame: 32774;             // frame
    tics: 6;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_TFOG8;       // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_TFOG7

   (
    sprite: Ord(SPR_TFOG);    // sprite
    frame: 32775;             // frame
    tics: 6;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_TFOG9;       // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_TFOG8

   (
    sprite: Ord(SPR_TFOG);    // sprite
    frame: 32776;             // frame
    tics: 6;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_TFOG10;      // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_TFOG9

   (
    sprite: Ord(SPR_TFOG);    // sprite
    frame: 32777;             // frame
    tics: 6;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_NULL;        // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_TFOG10

   (
    sprite: Ord(SPR_IFOG);    // sprite
    frame: 32768;             // frame
    tics: 6;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_IFOG01;      // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_IFOG

   (
    sprite: Ord(SPR_IFOG);    // sprite
    frame: 32769;             // frame
    tics: 6;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_IFOG02;      // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_IFOG01

   (
    sprite: Ord(SPR_IFOG);    // sprite
    frame: 32768;             // frame
    tics: 6;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_IFOG2;       // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_IFOG02

   (
    sprite: Ord(SPR_IFOG);    // sprite
    frame: 32769;             // frame
    tics: 6;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_IFOG3;       // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_IFOG2

   (
    sprite: Ord(SPR_IFOG);    // sprite
    frame: 32770;             // frame
    tics: 6;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_IFOG4;       // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_IFOG3

   (
    sprite: Ord(SPR_IFOG);    // sprite
    frame: 32771;             // frame
    tics: 6;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_IFOG5;       // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_IFOG4

   (
    sprite: Ord(SPR_IFOG);    // sprite
    frame: 32772;             // frame
    tics: 6;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_NULL;        // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_IFOG5

   (
    sprite: Ord(SPR_PLAY);    // sprite
    frame: 0;                 // frame
    tics: -1;                 // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_NULL;        // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_PLAY

   (
    sprite: Ord(SPR_PLAY);    // sprite
    frame: 0;                 // frame
    tics: 4;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_PLAY_RUN2;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_PLAY_RUN1

   (
    sprite: Ord(SPR_PLAY);    // sprite
    frame: 1;                 // frame
    tics: 4;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_PLAY_RUN3;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_PLAY_RUN2

   (
    sprite: Ord(SPR_PLAY);    // sprite
    frame: 2;                 // frame
    tics: 4;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_PLAY_RUN4;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_PLAY_RUN3

   (
    sprite: Ord(SPR_PLAY);    // sprite
    frame: 3;                 // frame
    tics: 4;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_PLAY_RUN1;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_PLAY_RUN4

   (
    sprite: Ord(SPR_PLAY);    // sprite
    frame: 4;                 // frame
    tics: 12;                 // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_PLAY;        // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_PLAY_ATK1

   (
    sprite: Ord(SPR_PLAY);    // sprite
    frame: 32773;             // frame
    tics: 6;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_PLAY_ATK1;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_PLAY_ATK2

   (
    sprite: Ord(SPR_PLAY);    // sprite
    frame: 6;                 // frame
    tics: 4;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_PLAY_PAIN2;  // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_PLAY_PAIN

   (
    sprite: Ord(SPR_PLAY);    // sprite
    frame: 6;                 // frame
    tics: 4;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_PLAY;        // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_PLAY_PAIN2

   (
    sprite: Ord(SPR_PLAY);    // sprite
    frame: 7;                 // frame
    tics: 10;                 // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_PLAY_DIE2;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_PLAY_DIE1

   (
    sprite: Ord(SPR_PLAY);    // sprite
    frame: 8;                 // frame
    tics: 10;                 // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_PLAY_DIE3;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_PLAY_DIE2

   (
    sprite: Ord(SPR_PLAY);    // sprite
    frame: 9;                 // frame
    tics: 10;                 // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_PLAY_DIE4;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_PLAY_DIE3

   (
    sprite: Ord(SPR_PLAY);    // sprite
    frame: 10;                // frame
    tics: 10;                 // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_PLAY_DIE5;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_PLAY_DIE4

   (
    sprite: Ord(SPR_PLAY);    // sprite
    frame: 11;                // frame
    tics: 10;                 // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_PLAY_DIE6;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_PLAY_DIE5

   (
    sprite: Ord(SPR_PLAY);    // sprite
    frame: 12;                // frame
    tics: 10;                 // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_PLAY_DIE7;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_PLAY_DIE6

   (
    sprite: Ord(SPR_PLAY);    // sprite
    frame: 13;                // frame
    tics: -1;                 // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_NULL;        // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_PLAY_DIE7

   (
    sprite: Ord(SPR_PLAY);    // sprite
    frame: 14;                // frame
    tics: 5;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_PLAY_XDIE2;  // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_PLAY_XDIE1

   (
    sprite: Ord(SPR_PLAY);    // sprite
    frame: 15;                // frame
    tics: 5;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_PLAY_XDIE3;  // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_PLAY_XDIE2

   (
    sprite: Ord(SPR_PLAY);    // sprite
    frame: 16;                // frame
    tics: 5;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_PLAY_XDIE4;  // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_PLAY_XDIE3

   (
    sprite: Ord(SPR_PLAY);    // sprite
    frame: 17;                // frame
    tics: 5;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_PLAY_XDIE5;  // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_PLAY_XDIE4

   (
    sprite: Ord(SPR_PLAY);    // sprite
    frame: 18;                // frame
    tics: 5;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_PLAY_XDIE6;  // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_PLAY_XDIE5

   (
    sprite: Ord(SPR_PLAY);    // sprite
    frame: 19;                // frame
    tics: 5;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_PLAY_XDIE7;  // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_PLAY_XDIE6

   (
    sprite: Ord(SPR_PLAY);    // sprite
    frame: 20;                // frame
    tics: 5;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_PLAY_XDIE8;  // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_PLAY_XDIE7

   (
    sprite: Ord(SPR_PLAY);    // sprite
    frame: 21;                // frame
    tics: 5;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_PLAY_XDIE9;  // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_PLAY_XDIE8

   (
    sprite: Ord(SPR_PLAY);    // sprite
    frame: 22;                // frame
    tics: -1;                 // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_NULL;        // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_PLAY_XDIE9

   (
    sprite: Ord(SPR_POSS);    // sprite
    frame: 0;                 // frame
    tics: 10;                 // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_POSS_STND2;  // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_POSS_STND

   (
    sprite: Ord(SPR_POSS);    // sprite
    frame: 1;                 // frame
    tics: 10;                 // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_POSS_STND;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_POSS_STND2

   (
    sprite: Ord(SPR_POSS);    // sprite
    frame: 0;                 // frame
    tics: 4;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_POSS_RUN2;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_POSS_RUN1

   (
    sprite: Ord(SPR_POSS);    // sprite
    frame: 0;                 // frame
    tics: 4;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_POSS_RUN3;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_POSS_RUN2

   (
    sprite: Ord(SPR_POSS);    // sprite
    frame: 1;                 // frame
    tics: 4;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_POSS_RUN4;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_POSS_RUN3

   (
    sprite: Ord(SPR_POSS);    // sprite
    frame: 1;                 // frame
    tics: 4;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_POSS_RUN5;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_POSS_RUN4

   (
    sprite: Ord(SPR_POSS);    // sprite
    frame: 2;                 // frame
    tics: 4;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_POSS_RUN6;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_POSS_RUN5

   (
    sprite: Ord(SPR_POSS);    // sprite
    frame: 2;                 // frame
    tics: 4;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_POSS_RUN7;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_POSS_RUN6

   (
    sprite: Ord(SPR_POSS);    // sprite
    frame: 3;                 // frame
    tics: 4;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_POSS_RUN8;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_POSS_RUN7

   (
    sprite: Ord(SPR_POSS);    // sprite
    frame: 3;                 // frame
    tics: 4;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_POSS_RUN1;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_POSS_RUN8

   (
    sprite: Ord(SPR_POSS);    // sprite
    frame: 4;                 // frame
    tics: 10;                 // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_POSS_ATK2;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_POSS_ATK1

   (
    sprite: Ord(SPR_POSS);    // sprite
    frame: 5;                 // frame
    tics: 8;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_POSS_ATK3;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_POSS_ATK2

   (
    sprite: Ord(SPR_POSS);    // sprite
    frame: 4;                 // frame
    tics: 8;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_POSS_RUN1;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_POSS_ATK3

   (
    sprite: Ord(SPR_POSS);    // sprite
    frame: 6;                 // frame
    tics: 3;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_POSS_PAIN2;  // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_POSS_PAIN

   (
    sprite: Ord(SPR_POSS);    // sprite
    frame: 6;                 // frame
    tics: 3;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_POSS_RUN1;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_POSS_PAIN2

   (
    sprite: Ord(SPR_POSS);    // sprite
    frame: 7;                 // frame
    tics: 5;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_POSS_DIE2;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_POSS_DIE1

   (
    sprite: Ord(SPR_POSS);    // sprite
    frame: 8;                 // frame
    tics: 5;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_POSS_DIE3;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_POSS_DIE2

   (
    sprite: Ord(SPR_POSS);    // sprite
    frame: 9;                 // frame
    tics: 5;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_POSS_DIE4;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_POSS_DIE3

   (
    sprite: Ord(SPR_POSS);    // sprite
    frame: 10;                // frame
    tics: 5;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_POSS_DIE5;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_POSS_DIE4

   (
    sprite: Ord(SPR_POSS);    // sprite
    frame: 11;                // frame
    tics: -1;                 // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_NULL;        // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_POSS_DIE5

   (
    sprite: Ord(SPR_POSS);    // sprite
    frame: 12;                // frame
    tics: 5;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_POSS_XDIE2;  // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_POSS_XDIE1

   (
    sprite: Ord(SPR_POSS);    // sprite
    frame: 13;                // frame
    tics: 5;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_POSS_XDIE3;  // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_POSS_XDIE2

   (
    sprite: Ord(SPR_POSS);    // sprite
    frame: 14;                // frame
    tics: 5;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_POSS_XDIE4;  // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_POSS_XDIE3

   (
    sprite: Ord(SPR_POSS);    // sprite
    frame: 15;                // frame
    tics: 5;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_POSS_XDIE5;  // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_POSS_XDIE4

   (
    sprite: Ord(SPR_POSS);    // sprite
    frame: 16;                // frame
    tics: 5;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_POSS_XDIE6;  // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_POSS_XDIE5

   (
    sprite: Ord(SPR_POSS);    // sprite
    frame: 17;                // frame
    tics: 5;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_POSS_XDIE7;  // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_POSS_XDIE6

   (
    sprite: Ord(SPR_POSS);    // sprite
    frame: 18;                // frame
    tics: 5;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_POSS_XDIE8;  // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_POSS_XDIE7

   (
    sprite: Ord(SPR_POSS);    // sprite
    frame: 19;                // frame
    tics: 5;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_POSS_XDIE9;  // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_POSS_XDIE8

   (
    sprite: Ord(SPR_POSS);    // sprite
    frame: 20;                // frame
    tics: -1;                 // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_NULL;        // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_POSS_XDIE9

   (
    sprite: Ord(SPR_POSS);    // sprite
    frame: 10;                // frame
    tics: 5;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_POSS_RAISE2;  // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_POSS_RAISE1

   (
    sprite: Ord(SPR_POSS);    // sprite
    frame: 9;                 // frame
    tics: 5;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_POSS_RAISE3;  // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_POSS_RAISE2

   (
    sprite: Ord(SPR_POSS);    // sprite
    frame: 8;                 // frame
    tics: 5;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_POSS_RAISE4;  // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_POSS_RAISE3

   (
    sprite: Ord(SPR_POSS);    // sprite
    frame: 7;                 // frame
    tics: 5;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_POSS_RUN1;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_POSS_RAISE4

   (
    sprite: Ord(SPR_SPOS);    // sprite
    frame: 0;                 // frame
    tics: 10;                 // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_SPOS_STND2;  // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_SPOS_STND

   (
    sprite: Ord(SPR_SPOS);    // sprite
    frame: 1;                 // frame
    tics: 10;                 // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_SPOS_STND;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_SPOS_STND2

   (
    sprite: Ord(SPR_SPOS);    // sprite
    frame: 0;                 // frame
    tics: 3;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_SPOS_RUN2;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_SPOS_RUN1

   (
    sprite: Ord(SPR_SPOS);    // sprite
    frame: 0;                 // frame
    tics: 3;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_SPOS_RUN3;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_SPOS_RUN2

   (
    sprite: Ord(SPR_SPOS);    // sprite
    frame: 1;                 // frame
    tics: 3;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_SPOS_RUN4;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_SPOS_RUN3

   (
    sprite: Ord(SPR_SPOS);    // sprite
    frame: 1;                 // frame
    tics: 3;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_SPOS_RUN5;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_SPOS_RUN4

   (
    sprite: Ord(SPR_SPOS);    // sprite
    frame: 2;                 // frame
    tics: 3;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_SPOS_RUN6;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_SPOS_RUN5

   (
    sprite: Ord(SPR_SPOS);    // sprite
    frame: 2;                 // frame
    tics: 3;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_SPOS_RUN7;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_SPOS_RUN6

   (
    sprite: Ord(SPR_SPOS);    // sprite
    frame: 3;                 // frame
    tics: 3;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_SPOS_RUN8;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_SPOS_RUN7

   (
    sprite: Ord(SPR_SPOS);    // sprite
    frame: 3;                 // frame
    tics: 3;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_SPOS_RUN1;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_SPOS_RUN8

   (
    sprite: Ord(SPR_SPOS);    // sprite
    frame: 4;                 // frame
    tics: 10;                 // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_SPOS_ATK2;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_SPOS_ATK1

   (
    sprite: Ord(SPR_SPOS);    // sprite
    frame: 32773;             // frame
    tics: 10;                 // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_SPOS_ATK3;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_SPOS_ATK2

   (
    sprite: Ord(SPR_SPOS);    // sprite
    frame: 4;                 // frame
    tics: 10;                 // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_SPOS_RUN1;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_SPOS_ATK3

   (
    sprite: Ord(SPR_SPOS);    // sprite
    frame: 6;                 // frame
    tics: 3;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_SPOS_PAIN2;  // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_SPOS_PAIN

   (
    sprite: Ord(SPR_SPOS);    // sprite
    frame: 6;                 // frame
    tics: 3;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_SPOS_RUN1;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_SPOS_PAIN2

   (
    sprite: Ord(SPR_SPOS);    // sprite
    frame: 7;                 // frame
    tics: 5;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_SPOS_DIE2;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_SPOS_DIE1

   (
    sprite: Ord(SPR_SPOS);    // sprite
    frame: 8;                 // frame
    tics: 5;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_SPOS_DIE3;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_SPOS_DIE2

   (
    sprite: Ord(SPR_SPOS);    // sprite
    frame: 9;                 // frame
    tics: 5;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_SPOS_DIE4;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_SPOS_DIE3

   (
    sprite: Ord(SPR_SPOS);    // sprite
    frame: 10;                // frame
    tics: 5;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_SPOS_DIE5;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_SPOS_DIE4

   (
    sprite: Ord(SPR_SPOS);    // sprite
    frame: 11;                // frame
    tics: -1;                 // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_NULL;        // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_SPOS_DIE5

   (
    sprite: Ord(SPR_SPOS);    // sprite
    frame: 12;                // frame
    tics: 5;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_SPOS_XDIE2;  // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_SPOS_XDIE1

   (
    sprite: Ord(SPR_SPOS);    // sprite
    frame: 13;                // frame
    tics: 5;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_SPOS_XDIE3;  // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_SPOS_XDIE2

   (
    sprite: Ord(SPR_SPOS);    // sprite
    frame: 14;                // frame
    tics: 5;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_SPOS_XDIE4;  // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_SPOS_XDIE3

   (
    sprite: Ord(SPR_SPOS);    // sprite
    frame: 15;                // frame
    tics: 5;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_SPOS_XDIE5;  // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_SPOS_XDIE4

   (
    sprite: Ord(SPR_SPOS);    // sprite
    frame: 16;                // frame
    tics: 5;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_SPOS_XDIE6;  // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_SPOS_XDIE5

   (
    sprite: Ord(SPR_SPOS);    // sprite
    frame: 17;                // frame
    tics: 5;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_SPOS_XDIE7;  // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_SPOS_XDIE6

   (
    sprite: Ord(SPR_SPOS);    // sprite
    frame: 18;                // frame
    tics: 5;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_SPOS_XDIE8;  // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_SPOS_XDIE7

   (
    sprite: Ord(SPR_SPOS);    // sprite
    frame: 19;                // frame
    tics: 5;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_SPOS_XDIE9;  // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_SPOS_XDIE8

   (
    sprite: Ord(SPR_SPOS);    // sprite
    frame: 20;                // frame
    tics: -1;                 // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_NULL;        // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_SPOS_XDIE9

   (
    sprite: Ord(SPR_SPOS);    // sprite
    frame: 11;                // frame
    tics: 5;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_SPOS_RAISE2;  // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_SPOS_RAISE1

   (
    sprite: Ord(SPR_SPOS);    // sprite
    frame: 10;                // frame
    tics: 5;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_SPOS_RAISE3;  // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_SPOS_RAISE2

   (
    sprite: Ord(SPR_SPOS);    // sprite
    frame: 9;                 // frame
    tics: 5;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_SPOS_RAISE4;  // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_SPOS_RAISE3

   (
    sprite: Ord(SPR_SPOS);    // sprite
    frame: 8;                 // frame
    tics: 5;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_SPOS_RAISE5;  // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_SPOS_RAISE4

   (
    sprite: Ord(SPR_SPOS);    // sprite
    frame: 7;                 // frame
    tics: 5;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_SPOS_RUN1;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_SPOS_RAISE5

   (
    sprite: Ord(SPR_VILE);    // sprite
    frame: 0;                 // frame
    tics: 10;                 // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_VILE_STND2;  // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_VILE_STND

   (
    sprite: Ord(SPR_VILE);    // sprite
    frame: 1;                 // frame
    tics: 10;                 // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_VILE_STND;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_VILE_STND2

   (
    sprite: Ord(SPR_VILE);    // sprite
    frame: 0;                 // frame
    tics: 2;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_VILE_RUN2;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_VILE_RUN1

   (
    sprite: Ord(SPR_VILE);    // sprite
    frame: 0;                 // frame
    tics: 2;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_VILE_RUN3;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_VILE_RUN2

   (
    sprite: Ord(SPR_VILE);    // sprite
    frame: 1;                 // frame
    tics: 2;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_VILE_RUN4;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_VILE_RUN3

   (
    sprite: Ord(SPR_VILE);    // sprite
    frame: 1;                 // frame
    tics: 2;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_VILE_RUN5;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_VILE_RUN4

   (
    sprite: Ord(SPR_VILE);    // sprite
    frame: 2;                 // frame
    tics: 2;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_VILE_RUN6;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_VILE_RUN5

   (
    sprite: Ord(SPR_VILE);    // sprite
    frame: 2;                 // frame
    tics: 2;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_VILE_RUN7;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_VILE_RUN6

   (
    sprite: Ord(SPR_VILE);    // sprite
    frame: 3;                 // frame
    tics: 2;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_VILE_RUN8;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_VILE_RUN7

   (
    sprite: Ord(SPR_VILE);    // sprite
    frame: 3;                 // frame
    tics: 2;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_VILE_RUN9;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_VILE_RUN8

   (
    sprite: Ord(SPR_VILE);    // sprite
    frame: 4;                 // frame
    tics: 2;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_VILE_RUN10;  // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_VILE_RUN9

   (
    sprite: Ord(SPR_VILE);    // sprite
    frame: 4;                 // frame
    tics: 2;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_VILE_RUN11;  // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_VILE_RUN10

   (
    sprite: Ord(SPR_VILE);    // sprite
    frame: 5;                 // frame
    tics: 2;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_VILE_RUN12;  // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_VILE_RUN11

   (
    sprite: Ord(SPR_VILE);    // sprite
    frame: 5;                 // frame
    tics: 2;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_VILE_RUN1;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_VILE_RUN12

   (
    sprite: Ord(SPR_VILE);    // sprite
    frame: 32774;             // frame
    tics: 0;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_VILE_ATK2;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_VILE_ATK1

   (
    sprite: Ord(SPR_VILE);    // sprite
    frame: 32774;             // frame
    tics: 10;                 // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_VILE_ATK3;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_VILE_ATK2

   (
    sprite: Ord(SPR_VILE);    // sprite
    frame: 32775;             // frame
    tics: 8;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_VILE_ATK4;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_VILE_ATK3

   (
    sprite: Ord(SPR_VILE);    // sprite
    frame: 32776;             // frame
    tics: 8;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_VILE_ATK5;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_VILE_ATK4

   (
    sprite: Ord(SPR_VILE);    // sprite
    frame: 32777;             // frame
    tics: 8;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_VILE_ATK6;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_VILE_ATK5

   (
    sprite: Ord(SPR_VILE);    // sprite
    frame: 32778;             // frame
    tics: 8;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_VILE_ATK7;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_VILE_ATK6

   (
    sprite: Ord(SPR_VILE);    // sprite
    frame: 32779;             // frame
    tics: 8;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_VILE_ATK8;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_VILE_ATK7

   (
    sprite: Ord(SPR_VILE);    // sprite
    frame: 32780;             // frame
    tics: 8;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_VILE_ATK9;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_VILE_ATK8

   (
    sprite: Ord(SPR_VILE);    // sprite
    frame: 32781;             // frame
    tics: 8;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_VILE_ATK10;  // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_VILE_ATK9

   (
    sprite: Ord(SPR_VILE);    // sprite
    frame: 32782;             // frame
    tics: 8;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_VILE_ATK11;  // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_VILE_ATK10

   (
    sprite: Ord(SPR_VILE);    // sprite
    frame: 32783;             // frame
    tics: 20;                 // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_VILE_RUN1;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_VILE_ATK11

   (
    sprite: Ord(SPR_VILE);    // sprite
    frame: 32794;             // frame
    tics: 10;                 // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_VILE_HEAL2;  // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_VILE_HEAL1

   (
    sprite: Ord(SPR_VILE);    // sprite
    frame: 32795;             // frame
    tics: 10;                 // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_VILE_HEAL3;  // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_VILE_HEAL2

   (
    sprite: Ord(SPR_VILE);    // sprite
    frame: 32796;             // frame
    tics: 10;                 // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_VILE_RUN1;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_VILE_HEAL3

   (
    sprite: Ord(SPR_VILE);    // sprite
    frame: 16;                // frame
    tics: 5;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_VILE_PAIN2;  // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_VILE_PAIN

   (
    sprite: Ord(SPR_VILE);    // sprite
    frame: 16;                // frame
    tics: 5;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_VILE_RUN1;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_VILE_PAIN2

   (
    sprite: Ord(SPR_VILE);    // sprite
    frame: 16;                // frame
    tics: 7;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_VILE_DIE2;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_VILE_DIE1

   (
    sprite: Ord(SPR_VILE);    // sprite
    frame: 17;                // frame
    tics: 7;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_VILE_DIE3;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_VILE_DIE2

   (
    sprite: Ord(SPR_VILE);    // sprite
    frame: 18;                // frame
    tics: 7;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_VILE_DIE4;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_VILE_DIE3

   (
    sprite: Ord(SPR_VILE);    // sprite
    frame: 19;                // frame
    tics: 7;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_VILE_DIE5;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_VILE_DIE4

   (
    sprite: Ord(SPR_VILE);    // sprite
    frame: 20;                // frame
    tics: 7;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_VILE_DIE6;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_VILE_DIE5

   (
    sprite: Ord(SPR_VILE);    // sprite
    frame: 21;                // frame
    tics: 7;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_VILE_DIE7;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_VILE_DIE6

   (
    sprite: Ord(SPR_VILE);    // sprite
    frame: 22;                // frame
    tics: 7;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_VILE_DIE8;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_VILE_DIE7

   (
    sprite: Ord(SPR_VILE);    // sprite
    frame: 23;                // frame
    tics: 5;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_VILE_DIE9;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_VILE_DIE8

   (
    sprite: Ord(SPR_VILE);    // sprite
    frame: 24;                // frame
    tics: 5;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_VILE_DIE10;  // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_VILE_DIE9

   (
    sprite: Ord(SPR_VILE);    // sprite
    frame: 25;                // frame
    tics: -1;                 // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_NULL;        // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_VILE_DIE10

   (
    sprite: Ord(SPR_FIRE);    // sprite
    frame: 32768;             // frame
    tics: 2;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_FIRE2;       // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_FIRE1

   (
    sprite: Ord(SPR_FIRE);    // sprite
    frame: 32769;             // frame
    tics: 2;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_FIRE3;       // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_FIRE2

   (
    sprite: Ord(SPR_FIRE);    // sprite
    frame: 32768;             // frame
    tics: 2;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_FIRE4;       // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_FIRE3

   (
    sprite: Ord(SPR_FIRE);    // sprite
    frame: 32769;             // frame
    tics: 2;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_FIRE5;       // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_FIRE4

   (
    sprite: Ord(SPR_FIRE);    // sprite
    frame: 32770;             // frame
    tics: 2;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_FIRE6;       // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_FIRE5

   (
    sprite: Ord(SPR_FIRE);    // sprite
    frame: 32769;             // frame
    tics: 2;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_FIRE7;       // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_FIRE6

   (
    sprite: Ord(SPR_FIRE);    // sprite
    frame: 32770;             // frame
    tics: 2;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_FIRE8;       // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_FIRE7

   (
    sprite: Ord(SPR_FIRE);    // sprite
    frame: 32769;             // frame
    tics: 2;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_FIRE9;       // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_FIRE8

   (
    sprite: Ord(SPR_FIRE);    // sprite
    frame: 32770;             // frame
    tics: 2;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_FIRE10;      // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_FIRE9

   (
    sprite: Ord(SPR_FIRE);    // sprite
    frame: 32771;             // frame
    tics: 2;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_FIRE11;      // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_FIRE10

   (
    sprite: Ord(SPR_FIRE);    // sprite
    frame: 32770;             // frame
    tics: 2;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_FIRE12;      // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_FIRE11

   (
    sprite: Ord(SPR_FIRE);    // sprite
    frame: 32771;             // frame
    tics: 2;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_FIRE13;      // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_FIRE12

   (
    sprite: Ord(SPR_FIRE);    // sprite
    frame: 32770;             // frame
    tics: 2;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_FIRE14;      // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_FIRE13

   (
    sprite: Ord(SPR_FIRE);    // sprite
    frame: 32771;             // frame
    tics: 2;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_FIRE15;      // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_FIRE14

   (
    sprite: Ord(SPR_FIRE);    // sprite
    frame: 32772;             // frame
    tics: 2;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_FIRE16;      // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_FIRE15

   (
    sprite: Ord(SPR_FIRE);    // sprite
    frame: 32771;             // frame
    tics: 2;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_FIRE17;      // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_FIRE16

   (
    sprite: Ord(SPR_FIRE);    // sprite
    frame: 32772;             // frame
    tics: 2;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_FIRE18;      // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_FIRE17

   (
    sprite: Ord(SPR_FIRE);    // sprite
    frame: 32771;             // frame
    tics: 2;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_FIRE19;      // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_FIRE18

   (
    sprite: Ord(SPR_FIRE);    // sprite
    frame: 32772;             // frame
    tics: 2;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_FIRE20;      // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_FIRE19

   (
    sprite: Ord(SPR_FIRE);    // sprite
    frame: 32773;             // frame
    tics: 2;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_FIRE21;      // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_FIRE20

   (
    sprite: Ord(SPR_FIRE);    // sprite
    frame: 32772;             // frame
    tics: 2;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_FIRE22;      // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_FIRE21

   (
    sprite: Ord(SPR_FIRE);    // sprite
    frame: 32773;             // frame
    tics: 2;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_FIRE23;      // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_FIRE22

   (
    sprite: Ord(SPR_FIRE);    // sprite
    frame: 32772;             // frame
    tics: 2;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_FIRE24;      // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_FIRE23

   (
    sprite: Ord(SPR_FIRE);    // sprite
    frame: 32773;             // frame
    tics: 2;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_FIRE25;      // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_FIRE24

   (
    sprite: Ord(SPR_FIRE);    // sprite
    frame: 32774;             // frame
    tics: 2;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_FIRE26;      // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_FIRE25

   (
    sprite: Ord(SPR_FIRE);    // sprite
    frame: 32775;             // frame
    tics: 2;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_FIRE27;      // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_FIRE26

   (
    sprite: Ord(SPR_FIRE);    // sprite
    frame: 32774;             // frame
    tics: 2;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_FIRE28;      // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_FIRE27

   (
    sprite: Ord(SPR_FIRE);    // sprite
    frame: 32775;             // frame
    tics: 2;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_FIRE29;      // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_FIRE28

   (
    sprite: Ord(SPR_FIRE);    // sprite
    frame: 32774;             // frame
    tics: 2;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_FIRE30;      // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_FIRE29

   (
    sprite: Ord(SPR_FIRE);    // sprite
    frame: 32775;             // frame
    tics: 2;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_NULL;        // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_FIRE30

   (
    sprite: Ord(SPR_PUFF);    // sprite
    frame: 1;                 // frame
    tics: 4;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_SMOKE2;      // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_SMOKE1

   (
    sprite: Ord(SPR_PUFF);    // sprite
    frame: 2;                 // frame
    tics: 4;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_SMOKE3;      // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_SMOKE2

   (
    sprite: Ord(SPR_PUFF);    // sprite
    frame: 1;                 // frame
    tics: 4;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_SMOKE4;      // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_SMOKE3

   (
    sprite: Ord(SPR_PUFF);    // sprite
    frame: 2;                 // frame
    tics: 4;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_SMOKE5;      // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_SMOKE4

   (
    sprite: Ord(SPR_PUFF);    // sprite
    frame: 3;                 // frame
    tics: 4;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_NULL;        // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_SMOKE5

   (
    sprite: Ord(SPR_FATB);    // sprite
    frame: 32768;             // frame
    tics: 2;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_TRACER2;     // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_TRACER

   (
    sprite: Ord(SPR_FATB);    // sprite
    frame: 32769;             // frame
    tics: 2;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_TRACER;      // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_TRACER2

   (
    sprite: Ord(SPR_FBXP);    // sprite
    frame: 32768;             // frame
    tics: 8;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_TRACEEXP2;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_TRACEEXP1

   (
    sprite: Ord(SPR_FBXP);    // sprite
    frame: 32769;             // frame
    tics: 6;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_TRACEEXP3;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_TRACEEXP2

   (
    sprite: Ord(SPR_FBXP);    // sprite
    frame: 32770;             // frame
    tics: 4;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_NULL;        // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_TRACEEXP3

   (
    sprite: Ord(SPR_SKEL);    // sprite
    frame: 0;                 // frame
    tics: 10;                 // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_SKEL_STND2;  // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_SKEL_STND

   (
    sprite: Ord(SPR_SKEL);    // sprite
    frame: 1;                 // frame
    tics: 10;                 // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_SKEL_STND;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_SKEL_STND2

   (
    sprite: Ord(SPR_SKEL);    // sprite
    frame: 0;                 // frame
    tics: 2;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_SKEL_RUN2;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_SKEL_RUN1

   (
    sprite: Ord(SPR_SKEL);    // sprite
    frame: 0;                 // frame
    tics: 2;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_SKEL_RUN3;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_SKEL_RUN2

   (
    sprite: Ord(SPR_SKEL);    // sprite
    frame: 1;                 // frame
    tics: 2;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_SKEL_RUN4;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_SKEL_RUN3

   (
    sprite: Ord(SPR_SKEL);    // sprite
    frame: 1;                 // frame
    tics: 2;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_SKEL_RUN5;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_SKEL_RUN4

   (
    sprite: Ord(SPR_SKEL);    // sprite
    frame: 2;                 // frame
    tics: 2;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_SKEL_RUN6;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_SKEL_RUN5

   (
    sprite: Ord(SPR_SKEL);    // sprite
    frame: 2;                 // frame
    tics: 2;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_SKEL_RUN7;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_SKEL_RUN6

   (
    sprite: Ord(SPR_SKEL);    // sprite
    frame: 3;                 // frame
    tics: 2;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_SKEL_RUN8;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_SKEL_RUN7

   (
    sprite: Ord(SPR_SKEL);    // sprite
    frame: 3;                 // frame
    tics: 2;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_SKEL_RUN9;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_SKEL_RUN8

   (
    sprite: Ord(SPR_SKEL);    // sprite
    frame: 4;                 // frame
    tics: 2;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_SKEL_RUN10;  // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_SKEL_RUN9

   (
    sprite: Ord(SPR_SKEL);    // sprite
    frame: 4;                 // frame
    tics: 2;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_SKEL_RUN11;  // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_SKEL_RUN10

   (
    sprite: Ord(SPR_SKEL);    // sprite
    frame: 5;                 // frame
    tics: 2;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_SKEL_RUN12;  // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_SKEL_RUN11

   (
    sprite: Ord(SPR_SKEL);    // sprite
    frame: 5;                 // frame
    tics: 2;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_SKEL_RUN1;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_SKEL_RUN12

   (
    sprite: Ord(SPR_SKEL);    // sprite
    frame: 6;                 // frame
    tics: 0;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_SKEL_FIST2;  // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_SKEL_FIST1

   (
    sprite: Ord(SPR_SKEL);    // sprite
    frame: 6;                 // frame
    tics: 6;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_SKEL_FIST3;  // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_SKEL_FIST2

   (
    sprite: Ord(SPR_SKEL);    // sprite
    frame: 7;                 // frame
    tics: 6;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_SKEL_FIST4;  // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_SKEL_FIST3

   (
    sprite: Ord(SPR_SKEL);    // sprite
    frame: 8;                 // frame
    tics: 6;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_SKEL_RUN1;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_SKEL_FIST4

   (
    sprite: Ord(SPR_SKEL);    // sprite
    frame: 32777;             // frame
    tics: 0;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_SKEL_MISS2;  // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_SKEL_MISS1

   (
    sprite: Ord(SPR_SKEL);    // sprite
    frame: 32777;             // frame
    tics: 10;                 // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_SKEL_MISS3;  // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_SKEL_MISS2

   (
    sprite: Ord(SPR_SKEL);    // sprite
    frame: 10;                // frame
    tics: 10;                 // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_SKEL_MISS4;  // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_SKEL_MISS3

   (
    sprite: Ord(SPR_SKEL);    // sprite
    frame: 10;                // frame
    tics: 10;                 // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_SKEL_RUN1;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_SKEL_MISS4

   (
    sprite: Ord(SPR_SKEL);    // sprite
    frame: 11;                // frame
    tics: 5;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_SKEL_PAIN2;  // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_SKEL_PAIN

   (
    sprite: Ord(SPR_SKEL);    // sprite
    frame: 11;                // frame
    tics: 5;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_SKEL_RUN1;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_SKEL_PAIN2

   (
    sprite: Ord(SPR_SKEL);    // sprite
    frame: 11;                // frame
    tics: 7;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_SKEL_DIE2;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_SKEL_DIE1

   (
    sprite: Ord(SPR_SKEL);    // sprite
    frame: 12;                // frame
    tics: 7;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_SKEL_DIE3;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_SKEL_DIE2

   (
    sprite: Ord(SPR_SKEL);    // sprite
    frame: 13;                // frame
    tics: 7;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_SKEL_DIE4;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_SKEL_DIE3

   (
    sprite: Ord(SPR_SKEL);    // sprite
    frame: 14;                // frame
    tics: 7;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_SKEL_DIE5;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_SKEL_DIE4

   (
    sprite: Ord(SPR_SKEL);    // sprite
    frame: 15;                // frame
    tics: 7;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_SKEL_DIE6;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_SKEL_DIE5

   (
    sprite: Ord(SPR_SKEL);    // sprite
    frame: 16;                // frame
    tics: -1;                 // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_NULL;        // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_SKEL_DIE6

   (
    sprite: Ord(SPR_SKEL);    // sprite
    frame: 16;                // frame
    tics: 5;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_SKEL_RAISE2;  // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_SKEL_RAISE1

   (
    sprite: Ord(SPR_SKEL);    // sprite
    frame: 15;                // frame
    tics: 5;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_SKEL_RAISE3;  // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_SKEL_RAISE2

   (
    sprite: Ord(SPR_SKEL);    // sprite
    frame: 14;                // frame
    tics: 5;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_SKEL_RAISE4;  // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_SKEL_RAISE3

   (
    sprite: Ord(SPR_SKEL);    // sprite
    frame: 13;                // frame
    tics: 5;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_SKEL_RAISE5;  // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_SKEL_RAISE4

   (
    sprite: Ord(SPR_SKEL);    // sprite
    frame: 12;                // frame
    tics: 5;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_SKEL_RAISE6;  // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_SKEL_RAISE5

   (
    sprite: Ord(SPR_SKEL);    // sprite
    frame: 11;                // frame
    tics: 5;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_SKEL_RUN1;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_SKEL_RAISE6

   (
    sprite: Ord(SPR_MANF);    // sprite
    frame: 32768;             // frame
    tics: 4;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_FATSHOT2;    // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_FATSHOT1

   (
    sprite: Ord(SPR_MANF);    // sprite
    frame: 32769;             // frame
    tics: 4;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_FATSHOT1;    // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_FATSHOT2

   (
    sprite: Ord(SPR_MISL);    // sprite
    frame: 32769;             // frame
    tics: 8;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_FATSHOTX2;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_FATSHOTX1

   (
    sprite: Ord(SPR_MISL);    // sprite
    frame: 32770;             // frame
    tics: 6;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_FATSHOTX3;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_FATSHOTX2

   (
    sprite: Ord(SPR_MISL);    // sprite
    frame: 32771;             // frame
    tics: 4;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_NULL;        // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_FATSHOTX3

   (
    sprite: Ord(SPR_FATT);    // sprite
    frame: 0;                 // frame
    tics: 15;                 // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_FATT_STND2;  // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_FATT_STND

   (
    sprite: Ord(SPR_FATT);    // sprite
    frame: 1;                 // frame
    tics: 15;                 // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_FATT_STND;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_FATT_STND2

   (
    sprite: Ord(SPR_FATT);    // sprite
    frame: 0;                 // frame
    tics: 4;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_FATT_RUN2;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_FATT_RUN1

   (
    sprite: Ord(SPR_FATT);    // sprite
    frame: 0;                 // frame
    tics: 4;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_FATT_RUN3;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_FATT_RUN2

   (
    sprite: Ord(SPR_FATT);    // sprite
    frame: 1;                 // frame
    tics: 4;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_FATT_RUN4;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_FATT_RUN3

   (
    sprite: Ord(SPR_FATT);    // sprite
    frame: 1;                 // frame
    tics: 4;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_FATT_RUN5;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_FATT_RUN4

   (
    sprite: Ord(SPR_FATT);    // sprite
    frame: 2;                 // frame
    tics: 4;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_FATT_RUN6;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_FATT_RUN5

   (
    sprite: Ord(SPR_FATT);    // sprite
    frame: 2;                 // frame
    tics: 4;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_FATT_RUN7;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_FATT_RUN6

   (
    sprite: Ord(SPR_FATT);    // sprite
    frame: 3;                 // frame
    tics: 4;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_FATT_RUN8;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_FATT_RUN7

   (
    sprite: Ord(SPR_FATT);    // sprite
    frame: 3;                 // frame
    tics: 4;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_FATT_RUN9;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_FATT_RUN8

   (
    sprite: Ord(SPR_FATT);    // sprite
    frame: 4;                 // frame
    tics: 4;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_FATT_RUN10;  // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_FATT_RUN9

   (
    sprite: Ord(SPR_FATT);    // sprite
    frame: 4;                 // frame
    tics: 4;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_FATT_RUN11;  // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_FATT_RUN10

   (
    sprite: Ord(SPR_FATT);    // sprite
    frame: 5;                 // frame
    tics: 4;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_FATT_RUN12;  // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_FATT_RUN11

   (
    sprite: Ord(SPR_FATT);    // sprite
    frame: 5;                 // frame
    tics: 4;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_FATT_RUN1;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_FATT_RUN12

   (
    sprite: Ord(SPR_FATT);    // sprite
    frame: 6;                 // frame
    tics: 20;                 // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_FATT_ATK2;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_FATT_ATK1

   (
    sprite: Ord(SPR_FATT);    // sprite
    frame: 32775;             // frame
    tics: 10;                 // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_FATT_ATK3;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_FATT_ATK2

   (
    sprite: Ord(SPR_FATT);    // sprite
    frame: 8;                 // frame
    tics: 5;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_FATT_ATK4;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_FATT_ATK3

   (
    sprite: Ord(SPR_FATT);    // sprite
    frame: 6;                 // frame
    tics: 5;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_FATT_ATK5;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_FATT_ATK4

   (
    sprite: Ord(SPR_FATT);    // sprite
    frame: 32775;             // frame
    tics: 10;                 // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_FATT_ATK6;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_FATT_ATK5

   (
    sprite: Ord(SPR_FATT);    // sprite
    frame: 8;                 // frame
    tics: 5;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_FATT_ATK7;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_FATT_ATK6

   (
    sprite: Ord(SPR_FATT);    // sprite
    frame: 6;                 // frame
    tics: 5;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_FATT_ATK8;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_FATT_ATK7

   (
    sprite: Ord(SPR_FATT);    // sprite
    frame: 32775;             // frame
    tics: 10;                 // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_FATT_ATK9;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_FATT_ATK8

   (
    sprite: Ord(SPR_FATT);    // sprite
    frame: 8;                 // frame
    tics: 5;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_FATT_ATK10;  // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_FATT_ATK9

   (
    sprite: Ord(SPR_FATT);    // sprite
    frame: 6;                 // frame
    tics: 5;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_FATT_RUN1;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_FATT_ATK10

   (
    sprite: Ord(SPR_FATT);    // sprite
    frame: 9;                 // frame
    tics: 3;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_FATT_PAIN2;  // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_FATT_PAIN

   (
    sprite: Ord(SPR_FATT);    // sprite
    frame: 9;                 // frame
    tics: 3;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_FATT_RUN1;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_FATT_PAIN2

   (
    sprite: Ord(SPR_FATT);    // sprite
    frame: 10;                // frame
    tics: 6;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_FATT_DIE2;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_FATT_DIE1

   (
    sprite: Ord(SPR_FATT);    // sprite
    frame: 11;                // frame
    tics: 6;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_FATT_DIE3;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_FATT_DIE2

   (
    sprite: Ord(SPR_FATT);    // sprite
    frame: 12;                // frame
    tics: 6;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_FATT_DIE4;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_FATT_DIE3

   (
    sprite: Ord(SPR_FATT);    // sprite
    frame: 13;                // frame
    tics: 6;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_FATT_DIE5;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_FATT_DIE4

   (
    sprite: Ord(SPR_FATT);    // sprite
    frame: 14;                // frame
    tics: 6;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_FATT_DIE6;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_FATT_DIE5

   (
    sprite: Ord(SPR_FATT);    // sprite
    frame: 15;                // frame
    tics: 6;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_FATT_DIE7;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_FATT_DIE6

   (
    sprite: Ord(SPR_FATT);    // sprite
    frame: 16;                // frame
    tics: 6;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_FATT_DIE8;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_FATT_DIE7

   (
    sprite: Ord(SPR_FATT);    // sprite
    frame: 17;                // frame
    tics: 6;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_FATT_DIE9;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_FATT_DIE8

   (
    sprite: Ord(SPR_FATT);    // sprite
    frame: 18;                // frame
    tics: 6;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_FATT_DIE10;  // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_FATT_DIE9

   (
    sprite: Ord(SPR_FATT);    // sprite
    frame: 19;                // frame
    tics: -1;                 // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_NULL;        // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_FATT_DIE10

   (
    sprite: Ord(SPR_FATT);    // sprite
    frame: 17;                // frame
    tics: 5;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_FATT_RAISE2;  // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_FATT_RAISE1

   (
    sprite: Ord(SPR_FATT);    // sprite
    frame: 16;                // frame
    tics: 5;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_FATT_RAISE3;  // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_FATT_RAISE2

   (
    sprite: Ord(SPR_FATT);    // sprite
    frame: 15;                // frame
    tics: 5;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_FATT_RAISE4;  // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_FATT_RAISE3

   (
    sprite: Ord(SPR_FATT);    // sprite
    frame: 14;                // frame
    tics: 5;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_FATT_RAISE5;  // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_FATT_RAISE4

   (
    sprite: Ord(SPR_FATT);    // sprite
    frame: 13;                // frame
    tics: 5;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_FATT_RAISE6;  // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_FATT_RAISE5

   (
    sprite: Ord(SPR_FATT);    // sprite
    frame: 12;                // frame
    tics: 5;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_FATT_RAISE7;  // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_FATT_RAISE6

   (
    sprite: Ord(SPR_FATT);    // sprite
    frame: 11;                // frame
    tics: 5;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_FATT_RAISE8;  // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_FATT_RAISE7

   (
    sprite: Ord(SPR_FATT);    // sprite
    frame: 10;                // frame
    tics: 5;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_FATT_RUN1;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_FATT_RAISE8

   (
    sprite: Ord(SPR_CPOS);    // sprite
    frame: 0;                 // frame
    tics: 10;                 // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_CPOS_STND2;  // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_CPOS_STND

   (
    sprite: Ord(SPR_CPOS);    // sprite
    frame: 1;                 // frame
    tics: 10;                 // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_CPOS_STND;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_CPOS_STND2

   (
    sprite: Ord(SPR_CPOS);    // sprite
    frame: 0;                 // frame
    tics: 3;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_CPOS_RUN2;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_CPOS_RUN1

   (
    sprite: Ord(SPR_CPOS);    // sprite
    frame: 0;                 // frame
    tics: 3;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_CPOS_RUN3;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_CPOS_RUN2

   (
    sprite: Ord(SPR_CPOS);    // sprite
    frame: 1;                 // frame
    tics: 3;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_CPOS_RUN4;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_CPOS_RUN3

   (
    sprite: Ord(SPR_CPOS);    // sprite
    frame: 1;                 // frame
    tics: 3;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_CPOS_RUN5;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_CPOS_RUN4

   (
    sprite: Ord(SPR_CPOS);    // sprite
    frame: 2;                 // frame
    tics: 3;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_CPOS_RUN6;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_CPOS_RUN5

   (
    sprite: Ord(SPR_CPOS);    // sprite
    frame: 2;                 // frame
    tics: 3;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_CPOS_RUN7;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_CPOS_RUN6

   (
    sprite: Ord(SPR_CPOS);    // sprite
    frame: 3;                 // frame
    tics: 3;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_CPOS_RUN8;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_CPOS_RUN7

   (
    sprite: Ord(SPR_CPOS);    // sprite
    frame: 3;                 // frame
    tics: 3;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_CPOS_RUN1;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_CPOS_RUN8

   (
    sprite: Ord(SPR_CPOS);    // sprite
    frame: 4;                 // frame
    tics: 10;                 // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_CPOS_ATK2;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_CPOS_ATK1

   (
    sprite: Ord(SPR_CPOS);    // sprite
    frame: 32773;             // frame
    tics: 4;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_CPOS_ATK3;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_CPOS_ATK2

   (
    sprite: Ord(SPR_CPOS);    // sprite
    frame: 32772;             // frame
    tics: 4;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_CPOS_ATK4;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_CPOS_ATK3

   (
    sprite: Ord(SPR_CPOS);    // sprite
    frame: 5;                 // frame
    tics: 1;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_CPOS_ATK2;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_CPOS_ATK4

   (
    sprite: Ord(SPR_CPOS);    // sprite
    frame: 6;                 // frame
    tics: 3;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_CPOS_PAIN2;  // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_CPOS_PAIN

   (
    sprite: Ord(SPR_CPOS);    // sprite
    frame: 6;                 // frame
    tics: 3;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_CPOS_RUN1;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_CPOS_PAIN2

   (
    sprite: Ord(SPR_CPOS);    // sprite
    frame: 7;                 // frame
    tics: 5;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_CPOS_DIE2;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_CPOS_DIE1

   (
    sprite: Ord(SPR_CPOS);    // sprite
    frame: 8;                 // frame
    tics: 5;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_CPOS_DIE3;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_CPOS_DIE2

   (
    sprite: Ord(SPR_CPOS);    // sprite
    frame: 9;                 // frame
    tics: 5;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_CPOS_DIE4;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_CPOS_DIE3

   (
    sprite: Ord(SPR_CPOS);    // sprite
    frame: 10;                // frame
    tics: 5;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_CPOS_DIE5;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_CPOS_DIE4

   (
    sprite: Ord(SPR_CPOS);    // sprite
    frame: 11;                // frame
    tics: 5;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_CPOS_DIE6;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_CPOS_DIE5

   (
    sprite: Ord(SPR_CPOS);    // sprite
    frame: 12;                // frame
    tics: 5;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_CPOS_DIE7;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_CPOS_DIE6

   (
    sprite: Ord(SPR_CPOS);    // sprite
    frame: 13;                // frame
    tics: -1;                 // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_NULL;        // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_CPOS_DIE7

   (
    sprite: Ord(SPR_CPOS);    // sprite
    frame: 14;                // frame
    tics: 5;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_CPOS_XDIE2;  // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_CPOS_XDIE1

   (
    sprite: Ord(SPR_CPOS);    // sprite
    frame: 15;                // frame
    tics: 5;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_CPOS_XDIE3;  // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_CPOS_XDIE2

   (
    sprite: Ord(SPR_CPOS);    // sprite
    frame: 16;                // frame
    tics: 5;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_CPOS_XDIE4;  // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_CPOS_XDIE3

   (
    sprite: Ord(SPR_CPOS);    // sprite
    frame: 17;                // frame
    tics: 5;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_CPOS_XDIE5;  // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_CPOS_XDIE4

   (
    sprite: Ord(SPR_CPOS);    // sprite
    frame: 18;                // frame
    tics: 5;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_CPOS_XDIE6;  // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_CPOS_XDIE5

   (
    sprite: Ord(SPR_CPOS);    // sprite
    frame: 19;                // frame
    tics: -1;                 // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_NULL;        // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_CPOS_XDIE6

   (
    sprite: Ord(SPR_CPOS);    // sprite
    frame: 13;                // frame
    tics: 5;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_CPOS_RAISE2;  // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_CPOS_RAISE1

   (
    sprite: Ord(SPR_CPOS);    // sprite
    frame: 12;                // frame
    tics: 5;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_CPOS_RAISE3;  // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_CPOS_RAISE2

   (
    sprite: Ord(SPR_CPOS);    // sprite
    frame: 11;                // frame
    tics: 5;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_CPOS_RAISE4;  // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_CPOS_RAISE3

   (
    sprite: Ord(SPR_CPOS);    // sprite
    frame: 10;                // frame
    tics: 5;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_CPOS_RAISE5;  // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_CPOS_RAISE4

   (
    sprite: Ord(SPR_CPOS);    // sprite
    frame: 9;                 // frame
    tics: 5;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_CPOS_RAISE6;  // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_CPOS_RAISE5

   (
    sprite: Ord(SPR_CPOS);    // sprite
    frame: 8;                 // frame
    tics: 5;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_CPOS_RAISE7;  // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_CPOS_RAISE6

   (
    sprite: Ord(SPR_CPOS);    // sprite
    frame: 7;                 // frame
    tics: 5;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_CPOS_RUN1;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_CPOS_RAISE7

   (
    sprite: Ord(SPR_TROO);    // sprite
    frame: 0;                 // frame
    tics: 10;                 // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_TROO_STND2;  // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_TROO_STND

   (
    sprite: Ord(SPR_TROO);    // sprite
    frame: 1;                 // frame
    tics: 10;                 // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_TROO_STND;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_TROO_STND2

   (
    sprite: Ord(SPR_TROO);    // sprite
    frame: 0;                 // frame
    tics: 3;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_TROO_RUN2;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_TROO_RUN1

   (
    sprite: Ord(SPR_TROO);    // sprite
    frame: 0;                 // frame
    tics: 3;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_TROO_RUN3;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_TROO_RUN2

   (
    sprite: Ord(SPR_TROO);    // sprite
    frame: 1;                 // frame
    tics: 3;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_TROO_RUN4;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_TROO_RUN3

   (
    sprite: Ord(SPR_TROO);    // sprite
    frame: 1;                 // frame
    tics: 3;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_TROO_RUN5;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_TROO_RUN4

   (
    sprite: Ord(SPR_TROO);    // sprite
    frame: 2;                 // frame
    tics: 3;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_TROO_RUN6;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_TROO_RUN5

   (
    sprite: Ord(SPR_TROO);    // sprite
    frame: 2;                 // frame
    tics: 3;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_TROO_RUN7;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_TROO_RUN6

   (
    sprite: Ord(SPR_TROO);    // sprite
    frame: 3;                 // frame
    tics: 3;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_TROO_RUN8;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_TROO_RUN7

   (
    sprite: Ord(SPR_TROO);    // sprite
    frame: 3;                 // frame
    tics: 3;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_TROO_RUN1;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_TROO_RUN8

   (
    sprite: Ord(SPR_TROO);    // sprite
    frame: 4;                 // frame
    tics: 8;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_TROO_ATK2;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_TROO_ATK1

   (
    sprite: Ord(SPR_TROO);    // sprite
    frame: 5;                 // frame
    tics: 8;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_TROO_ATK3;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_TROO_ATK2

   (
    sprite: Ord(SPR_TROO);    // sprite
    frame: 6;                 // frame
    tics: 6;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_TROO_RUN1;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_TROO_ATK3

   (
    sprite: Ord(SPR_TROO);    // sprite
    frame: 7;                 // frame
    tics: 2;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_TROO_PAIN2;  // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_TROO_PAIN

   (
    sprite: Ord(SPR_TROO);    // sprite
    frame: 7;                 // frame
    tics: 2;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_TROO_RUN1;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_TROO_PAIN2

   (
    sprite: Ord(SPR_TROO);    // sprite
    frame: 8;                 // frame
    tics: 8;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_TROO_DIE2;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_TROO_DIE1

   (
    sprite: Ord(SPR_TROO);    // sprite
    frame: 9;                 // frame
    tics: 8;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_TROO_DIE3;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_TROO_DIE2

   (
    sprite: Ord(SPR_TROO);    // sprite
    frame: 10;                // frame
    tics: 6;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_TROO_DIE4;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_TROO_DIE3

   (
    sprite: Ord(SPR_TROO);    // sprite
    frame: 11;                // frame
    tics: 6;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_TROO_DIE5;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_TROO_DIE4

   (
    sprite: Ord(SPR_TROO);    // sprite
    frame: 12;                // frame
    tics: -1;                 // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_NULL;        // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_TROO_DIE5

   (
    sprite: Ord(SPR_TROO);    // sprite
    frame: 13;                // frame
    tics: 5;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_TROO_XDIE2;  // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_TROO_XDIE1

   (
    sprite: Ord(SPR_TROO);    // sprite
    frame: 14;                // frame
    tics: 5;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_TROO_XDIE3;  // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_TROO_XDIE2

   (
    sprite: Ord(SPR_TROO);    // sprite
    frame: 15;                // frame
    tics: 5;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_TROO_XDIE4;  // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_TROO_XDIE3

   (
    sprite: Ord(SPR_TROO);    // sprite
    frame: 16;                // frame
    tics: 5;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_TROO_XDIE5;  // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_TROO_XDIE4

   (
    sprite: Ord(SPR_TROO);    // sprite
    frame: 17;                // frame
    tics: 5;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_TROO_XDIE6;  // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_TROO_XDIE5

   (
    sprite: Ord(SPR_TROO);    // sprite
    frame: 18;                // frame
    tics: 5;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_TROO_XDIE7;  // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_TROO_XDIE6

   (
    sprite: Ord(SPR_TROO);    // sprite
    frame: 19;                // frame
    tics: 5;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_TROO_XDIE8;  // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_TROO_XDIE7

   (
    sprite: Ord(SPR_TROO);    // sprite
    frame: 20;                // frame
    tics: -1;                 // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_NULL;        // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_TROO_XDIE8

   (
    sprite: Ord(SPR_TROO);    // sprite
    frame: 12;                // frame
    tics: 8;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_TROO_RAISE2;  // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_TROO_RAISE1

   (
    sprite: Ord(SPR_TROO);    // sprite
    frame: 11;                // frame
    tics: 8;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_TROO_RAISE3;  // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_TROO_RAISE2

   (
    sprite: Ord(SPR_TROO);    // sprite
    frame: 10;                // frame
    tics: 6;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_TROO_RAISE4;  // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_TROO_RAISE3

   (
    sprite: Ord(SPR_TROO);    // sprite
    frame: 9;                 // frame
    tics: 6;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_TROO_RAISE5;  // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_TROO_RAISE4

   (
    sprite: Ord(SPR_TROO);    // sprite
    frame: 8;                 // frame
    tics: 6;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_TROO_RUN1;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_TROO_RAISE5

   (
    sprite: Ord(SPR_SARG);    // sprite
    frame: 0;                 // frame
    tics: 10;                 // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_SARG_STND2;  // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_SARG_STND

   (
    sprite: Ord(SPR_SARG);    // sprite
    frame: 1;                 // frame
    tics: 10;                 // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_SARG_STND;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_SARG_STND2

   (
    sprite: Ord(SPR_SARG);    // sprite
    frame: 0;                 // frame
    tics: 2;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_SARG_RUN2;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_SARG_RUN1

   (
    sprite: Ord(SPR_SARG);    // sprite
    frame: 0;                 // frame
    tics: 2;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_SARG_RUN3;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_SARG_RUN2

   (
    sprite: Ord(SPR_SARG);    // sprite
    frame: 1;                 // frame
    tics: 2;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_SARG_RUN4;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_SARG_RUN3

   (
    sprite: Ord(SPR_SARG);    // sprite
    frame: 1;                 // frame
    tics: 2;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_SARG_RUN5;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_SARG_RUN4

   (
    sprite: Ord(SPR_SARG);    // sprite
    frame: 2;                 // frame
    tics: 2;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_SARG_RUN6;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_SARG_RUN5

   (
    sprite: Ord(SPR_SARG);    // sprite
    frame: 2;                 // frame
    tics: 2;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_SARG_RUN7;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_SARG_RUN6

   (
    sprite: Ord(SPR_SARG);    // sprite
    frame: 3;                 // frame
    tics: 2;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_SARG_RUN8;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_SARG_RUN7

   (
    sprite: Ord(SPR_SARG);    // sprite
    frame: 3;                 // frame
    tics: 2;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_SARG_RUN1;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_SARG_RUN8

   (
    sprite: Ord(SPR_SARG);    // sprite
    frame: 4;                 // frame
    tics: 8;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_SARG_ATK2;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_SARG_ATK1

   (
    sprite: Ord(SPR_SARG);    // sprite
    frame: 5;                 // frame
    tics: 8;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_SARG_ATK3;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_SARG_ATK2

   (
    sprite: Ord(SPR_SARG);    // sprite
    frame: 6;                 // frame
    tics: 8;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_SARG_RUN1;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_SARG_ATK3

   (
    sprite: Ord(SPR_SARG);    // sprite
    frame: 7;                 // frame
    tics: 2;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_SARG_PAIN2;  // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_SARG_PAIN

   (
    sprite: Ord(SPR_SARG);    // sprite
    frame: 7;                 // frame
    tics: 2;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_SARG_RUN1;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_SARG_PAIN2

   (
    sprite: Ord(SPR_SARG);    // sprite
    frame: 8;                 // frame
    tics: 8;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_SARG_DIE2;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_SARG_DIE1

   (
    sprite: Ord(SPR_SARG);    // sprite
    frame: 9;                 // frame
    tics: 8;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_SARG_DIE3;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_SARG_DIE2

   (
    sprite: Ord(SPR_SARG);    // sprite
    frame: 10;                // frame
    tics: 4;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_SARG_DIE4;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_SARG_DIE3

   (
    sprite: Ord(SPR_SARG);    // sprite
    frame: 11;                // frame
    tics: 4;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_SARG_DIE5;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_SARG_DIE4

   (
    sprite: Ord(SPR_SARG);    // sprite
    frame: 12;                // frame
    tics: 4;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_SARG_DIE6;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_SARG_DIE5

   (
    sprite: Ord(SPR_SARG);    // sprite
    frame: 13;                // frame
    tics: -1;                 // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_NULL;        // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_SARG_DIE6

   (
    sprite: Ord(SPR_SARG);    // sprite
    frame: 13;                // frame
    tics: 5;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_SARG_RAISE2;  // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_SARG_RAISE1

   (
    sprite: Ord(SPR_SARG);    // sprite
    frame: 12;                // frame
    tics: 5;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_SARG_RAISE3;  // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_SARG_RAISE2

   (
    sprite: Ord(SPR_SARG);    // sprite
    frame: 11;                // frame
    tics: 5;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_SARG_RAISE4;  // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_SARG_RAISE3

   (
    sprite: Ord(SPR_SARG);    // sprite
    frame: 10;                // frame
    tics: 5;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_SARG_RAISE5;  // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_SARG_RAISE4

   (
    sprite: Ord(SPR_SARG);    // sprite
    frame: 9;                 // frame
    tics: 5;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_SARG_RAISE6;  // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_SARG_RAISE5

   (
    sprite: Ord(SPR_SARG);    // sprite
    frame: 8;                 // frame
    tics: 5;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_SARG_RUN1;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_SARG_RAISE6

   (
    sprite: Ord(SPR_HEAD);    // sprite
    frame: 0;                 // frame
    tics: 10;                 // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_HEAD_STND;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_HEAD_STND

   (
    sprite: Ord(SPR_HEAD);    // sprite
    frame: 0;                 // frame
    tics: 3;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_HEAD_RUN1;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_HEAD_RUN1

   (
    sprite: Ord(SPR_HEAD);    // sprite
    frame: 1;                 // frame
    tics: 5;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_HEAD_ATK2;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_HEAD_ATK1

   (
    sprite: Ord(SPR_HEAD);    // sprite
    frame: 2;                 // frame
    tics: 5;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_HEAD_ATK3;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_HEAD_ATK2

   (
    sprite: Ord(SPR_HEAD);    // sprite
    frame: 32771;             // frame
    tics: 5;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_HEAD_RUN1;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_HEAD_ATK3

   (
    sprite: Ord(SPR_HEAD);    // sprite
    frame: 4;                 // frame
    tics: 3;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_HEAD_PAIN2;  // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_HEAD_PAIN

   (
    sprite: Ord(SPR_HEAD);    // sprite
    frame: 4;                 // frame
    tics: 3;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_HEAD_PAIN3;  // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_HEAD_PAIN2

   (
    sprite: Ord(SPR_HEAD);    // sprite
    frame: 5;                 // frame
    tics: 6;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_HEAD_RUN1;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_HEAD_PAIN3

   (
    sprite: Ord(SPR_HEAD);    // sprite
    frame: 6;                 // frame
    tics: 8;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_HEAD_DIE2;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_HEAD_DIE1

   (
    sprite: Ord(SPR_HEAD);    // sprite
    frame: 7;                 // frame
    tics: 8;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_HEAD_DIE3;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_HEAD_DIE2

   (
    sprite: Ord(SPR_HEAD);    // sprite
    frame: 8;                 // frame
    tics: 8;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_HEAD_DIE4;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_HEAD_DIE3

   (
    sprite: Ord(SPR_HEAD);    // sprite
    frame: 9;                 // frame
    tics: 8;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_HEAD_DIE5;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_HEAD_DIE4

   (
    sprite: Ord(SPR_HEAD);    // sprite
    frame: 10;                // frame
    tics: 8;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_HEAD_DIE6;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_HEAD_DIE5

   (
    sprite: Ord(SPR_HEAD);    // sprite
    frame: 11;                // frame
    tics: -1;                 // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_NULL;        // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_HEAD_DIE6

   (
    sprite: Ord(SPR_HEAD);    // sprite
    frame: 11;                // frame
    tics: 8;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_HEAD_RAISE2;  // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_HEAD_RAISE1

   (
    sprite: Ord(SPR_HEAD);    // sprite
    frame: 10;                // frame
    tics: 8;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_HEAD_RAISE3;  // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_HEAD_RAISE2

   (
    sprite: Ord(SPR_HEAD);    // sprite
    frame: 9;                 // frame
    tics: 8;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_HEAD_RAISE4;  // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_HEAD_RAISE3

   (
    sprite: Ord(SPR_HEAD);    // sprite
    frame: 8;                 // frame
    tics: 8;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_HEAD_RAISE5;  // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_HEAD_RAISE4

   (
    sprite: Ord(SPR_HEAD);    // sprite
    frame: 7;                 // frame
    tics: 8;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_HEAD_RAISE6;  // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_HEAD_RAISE5

   (
    sprite: Ord(SPR_HEAD);    // sprite
    frame: 6;                 // frame
    tics: 8;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_HEAD_RUN1;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_HEAD_RAISE6

   (
    sprite: Ord(SPR_BAL7);    // sprite
    frame: 32768;             // frame
    tics: 4;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_BRBALL2;     // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_BRBALL1

   (
    sprite: Ord(SPR_BAL7);    // sprite
    frame: 32769;             // frame
    tics: 4;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_BRBALL1;     // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_BRBALL2

   (
    sprite: Ord(SPR_BAL7);    // sprite
    frame: 32770;             // frame
    tics: 6;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_BRBALLX2;    // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_BRBALLX1

   (
    sprite: Ord(SPR_BAL7);    // sprite
    frame: 32771;             // frame
    tics: 6;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_BRBALLX3;    // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_BRBALLX2

   (
    sprite: Ord(SPR_BAL7);    // sprite
    frame: 32772;             // frame
    tics: 6;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_NULL;        // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_BRBALLX3

   (
    sprite: Ord(SPR_BOSS);    // sprite
    frame: 0;                 // frame
    tics: 10;                 // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_BOSS_STND2;  // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_BOSS_STND

   (
    sprite: Ord(SPR_BOSS);    // sprite
    frame: 1;                 // frame
    tics: 10;                 // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_BOSS_STND;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_BOSS_STND2

   (
    sprite: Ord(SPR_BOSS);    // sprite
    frame: 0;                 // frame
    tics: 3;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_BOSS_RUN2;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_BOSS_RUN1

   (
    sprite: Ord(SPR_BOSS);    // sprite
    frame: 0;                 // frame
    tics: 3;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_BOSS_RUN3;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_BOSS_RUN2

   (
    sprite: Ord(SPR_BOSS);    // sprite
    frame: 1;                 // frame
    tics: 3;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_BOSS_RUN4;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_BOSS_RUN3

   (
    sprite: Ord(SPR_BOSS);    // sprite
    frame: 1;                 // frame
    tics: 3;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_BOSS_RUN5;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_BOSS_RUN4

   (
    sprite: Ord(SPR_BOSS);    // sprite
    frame: 2;                 // frame
    tics: 3;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_BOSS_RUN6;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_BOSS_RUN5

   (
    sprite: Ord(SPR_BOSS);    // sprite
    frame: 2;                 // frame
    tics: 3;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_BOSS_RUN7;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_BOSS_RUN6

   (
    sprite: Ord(SPR_BOSS);    // sprite
    frame: 3;                 // frame
    tics: 3;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_BOSS_RUN8;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_BOSS_RUN7

   (
    sprite: Ord(SPR_BOSS);    // sprite
    frame: 3;                 // frame
    tics: 3;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_BOSS_RUN1;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_BOSS_RUN8

   (
    sprite: Ord(SPR_BOSS);    // sprite
    frame: 4;                 // frame
    tics: 8;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_BOSS_ATK2;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_BOSS_ATK1

   (
    sprite: Ord(SPR_BOSS);    // sprite
    frame: 5;                 // frame
    tics: 8;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_BOSS_ATK3;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_BOSS_ATK2

   (
    sprite: Ord(SPR_BOSS);    // sprite
    frame: 6;                 // frame
    tics: 8;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_BOSS_RUN1;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_BOSS_ATK3

   (
    sprite: Ord(SPR_BOSS);    // sprite
    frame: 7;                 // frame
    tics: 2;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_BOSS_PAIN2;  // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_BOSS_PAIN

   (
    sprite: Ord(SPR_BOSS);    // sprite
    frame: 7;                 // frame
    tics: 2;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_BOSS_RUN1;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_BOSS_PAIN2

   (
    sprite: Ord(SPR_BOSS);    // sprite
    frame: 8;                 // frame
    tics: 8;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_BOSS_DIE2;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_BOSS_DIE1

   (
    sprite: Ord(SPR_BOSS);    // sprite
    frame: 9;                 // frame
    tics: 8;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_BOSS_DIE3;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_BOSS_DIE2

   (
    sprite: Ord(SPR_BOSS);    // sprite
    frame: 10;                // frame
    tics: 8;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_BOSS_DIE4;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_BOSS_DIE3

   (
    sprite: Ord(SPR_BOSS);    // sprite
    frame: 11;                // frame
    tics: 8;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_BOSS_DIE5;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_BOSS_DIE4

   (
    sprite: Ord(SPR_BOSS);    // sprite
    frame: 12;                // frame
    tics: 8;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_BOSS_DIE6;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_BOSS_DIE5

   (
    sprite: Ord(SPR_BOSS);    // sprite
    frame: 13;                // frame
    tics: 8;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_BOSS_DIE7;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_BOSS_DIE6

   (
    sprite: Ord(SPR_BOSS);    // sprite
    frame: 14;                // frame
    tics: -1;                 // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_NULL;        // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_BOSS_DIE7

   (
    sprite: Ord(SPR_BOSS);    // sprite
    frame: 14;                // frame
    tics: 8;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_BOSS_RAISE2;  // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_BOSS_RAISE1

   (
    sprite: Ord(SPR_BOSS);    // sprite
    frame: 13;                // frame
    tics: 8;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_BOSS_RAISE3;  // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_BOSS_RAISE2

   (
    sprite: Ord(SPR_BOSS);    // sprite
    frame: 12;                // frame
    tics: 8;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_BOSS_RAISE4;  // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_BOSS_RAISE3

   (
    sprite: Ord(SPR_BOSS);    // sprite
    frame: 11;                // frame
    tics: 8;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_BOSS_RAISE5;  // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_BOSS_RAISE4

   (
    sprite: Ord(SPR_BOSS);    // sprite
    frame: 10;                // frame
    tics: 8;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_BOSS_RAISE6;  // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_BOSS_RAISE5

   (
    sprite: Ord(SPR_BOSS);    // sprite
    frame: 9;                 // frame
    tics: 8;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_BOSS_RAISE7;  // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_BOSS_RAISE6

   (
    sprite: Ord(SPR_BOSS);    // sprite
    frame: 8;                 // frame
    tics: 8;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_BOSS_RUN1;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_BOSS_RAISE7

   (
    sprite: Ord(SPR_BOS2);    // sprite
    frame: 0;                 // frame
    tics: 10;                 // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_BOS2_STND2;  // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_BOS2_STND

   (
    sprite: Ord(SPR_BOS2);    // sprite
    frame: 1;                 // frame
    tics: 10;                 // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_BOS2_STND;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_BOS2_STND2

   (
    sprite: Ord(SPR_BOS2);    // sprite
    frame: 0;                 // frame
    tics: 3;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_BOS2_RUN2;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_BOS2_RUN1

   (
    sprite: Ord(SPR_BOS2);    // sprite
    frame: 0;                 // frame
    tics: 3;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_BOS2_RUN3;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_BOS2_RUN2

   (
    sprite: Ord(SPR_BOS2);    // sprite
    frame: 1;                 // frame
    tics: 3;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_BOS2_RUN4;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_BOS2_RUN3

   (
    sprite: Ord(SPR_BOS2);    // sprite
    frame: 1;                 // frame
    tics: 3;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_BOS2_RUN5;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_BOS2_RUN4

   (
    sprite: Ord(SPR_BOS2);    // sprite
    frame: 2;                 // frame
    tics: 3;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_BOS2_RUN6;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_BOS2_RUN5

   (
    sprite: Ord(SPR_BOS2);    // sprite
    frame: 2;                 // frame
    tics: 3;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_BOS2_RUN7;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_BOS2_RUN6

   (
    sprite: Ord(SPR_BOS2);    // sprite
    frame: 3;                 // frame
    tics: 3;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_BOS2_RUN8;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_BOS2_RUN7

   (
    sprite: Ord(SPR_BOS2);    // sprite
    frame: 3;                 // frame
    tics: 3;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_BOS2_RUN1;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_BOS2_RUN8

   (
    sprite: Ord(SPR_BOS2);    // sprite
    frame: 4;                 // frame
    tics: 8;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_BOS2_ATK2;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_BOS2_ATK1

   (
    sprite: Ord(SPR_BOS2);    // sprite
    frame: 5;                 // frame
    tics: 8;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_BOS2_ATK3;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_BOS2_ATK2

   (
    sprite: Ord(SPR_BOS2);    // sprite
    frame: 6;                 // frame
    tics: 8;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_BOS2_RUN1;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_BOS2_ATK3

   (
    sprite: Ord(SPR_BOS2);    // sprite
    frame: 7;                 // frame
    tics: 2;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_BOS2_PAIN2;  // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_BOS2_PAIN

   (
    sprite: Ord(SPR_BOS2);    // sprite
    frame: 7;                 // frame
    tics: 2;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_BOS2_RUN1;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_BOS2_PAIN2

   (
    sprite: Ord(SPR_BOS2);    // sprite
    frame: 8;                 // frame
    tics: 8;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_BOS2_DIE2;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_BOS2_DIE1

   (
    sprite: Ord(SPR_BOS2);    // sprite
    frame: 9;                 // frame
    tics: 8;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_BOS2_DIE3;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_BOS2_DIE2

   (
    sprite: Ord(SPR_BOS2);    // sprite
    frame: 10;                // frame
    tics: 8;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_BOS2_DIE4;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_BOS2_DIE3

   (
    sprite: Ord(SPR_BOS2);    // sprite
    frame: 11;                // frame
    tics: 8;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_BOS2_DIE5;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_BOS2_DIE4

   (
    sprite: Ord(SPR_BOS2);    // sprite
    frame: 12;                // frame
    tics: 8;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_BOS2_DIE6;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_BOS2_DIE5

   (
    sprite: Ord(SPR_BOS2);    // sprite
    frame: 13;                // frame
    tics: 8;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_BOS2_DIE7;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_BOS2_DIE6

   (
    sprite: Ord(SPR_BOS2);    // sprite
    frame: 14;                // frame
    tics: -1;                 // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_NULL;        // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_BOS2_DIE7

   (
    sprite: Ord(SPR_BOS2);    // sprite
    frame: 14;                // frame
    tics: 8;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_BOS2_RAISE2;  // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_BOS2_RAISE1

   (
    sprite: Ord(SPR_BOS2);    // sprite
    frame: 13;                // frame
    tics: 8;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_BOS2_RAISE3;  // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_BOS2_RAISE2

   (
    sprite: Ord(SPR_BOS2);    // sprite
    frame: 12;                // frame
    tics: 8;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_BOS2_RAISE4;  // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_BOS2_RAISE3

   (
    sprite: Ord(SPR_BOS2);    // sprite
    frame: 11;                // frame
    tics: 8;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_BOS2_RAISE5;  // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_BOS2_RAISE4

   (
    sprite: Ord(SPR_BOS2);    // sprite
    frame: 10;                // frame
    tics: 8;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_BOS2_RAISE6;  // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_BOS2_RAISE5

   (
    sprite: Ord(SPR_BOS2);    // sprite
    frame: 9;                 // frame
    tics: 8;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_BOS2_RAISE7;  // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_BOS2_RAISE6

   (
    sprite: Ord(SPR_BOS2);    // sprite
    frame: 8;                 // frame
    tics: 8;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_BOS2_RUN1;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_BOS2_RAISE7

   (
    sprite: Ord(SPR_SKUL);    // sprite
    frame: 32768;             // frame
    tics: 10;                 // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_SKULL_STND2; // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_SKULL_STND

   (
    sprite: Ord(SPR_SKUL);    // sprite
    frame: 32769;             // frame
    tics: 10;                 // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_SKULL_STND;  // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_SKULL_STND2

   (
    sprite: Ord(SPR_SKUL);    // sprite
    frame: 32768;             // frame
    tics: 6;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_SKULL_RUN2;  // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_SKULL_RUN1

   (
    sprite: Ord(SPR_SKUL);    // sprite
    frame: 32769;             // frame
    tics: 6;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_SKULL_RUN1;  // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_SKULL_RUN2

   (
    sprite: Ord(SPR_SKUL);    // sprite
    frame: 32770;             // frame
    tics: 10;                 // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_SKULL_ATK2;  // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_SKULL_ATK1

   (
    sprite: Ord(SPR_SKUL);    // sprite
    frame: 32771;             // frame
    tics: 4;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_SKULL_ATK3;  // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_SKULL_ATK2

   (
    sprite: Ord(SPR_SKUL);    // sprite
    frame: 32770;             // frame
    tics: 4;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_SKULL_ATK4;  // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_SKULL_ATK3

   (
    sprite: Ord(SPR_SKUL);    // sprite
    frame: 32771;             // frame
    tics: 4;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_SKULL_ATK3;  // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_SKULL_ATK4

   (
    sprite: Ord(SPR_SKUL);    // sprite
    frame: 32772;             // frame
    tics: 3;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_SKULL_PAIN2;  // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_SKULL_PAIN

   (
    sprite: Ord(SPR_SKUL);    // sprite
    frame: 32772;             // frame
    tics: 3;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_SKULL_RUN1;  // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_SKULL_PAIN2

   (
    sprite: Ord(SPR_SKUL);    // sprite
    frame: 32773;             // frame
    tics: 6;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_SKULL_DIE2;  // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_SKULL_DIE1

   (
    sprite: Ord(SPR_SKUL);    // sprite
    frame: 32774;             // frame
    tics: 6;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_SKULL_DIE3;  // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_SKULL_DIE2

   (
    sprite: Ord(SPR_SKUL);    // sprite
    frame: 32775;             // frame
    tics: 6;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_SKULL_DIE4;  // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_SKULL_DIE3

   (
    sprite: Ord(SPR_SKUL);    // sprite
    frame: 32776;             // frame
    tics: 6;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_SKULL_DIE5;  // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_SKULL_DIE4

   (
    sprite: Ord(SPR_SKUL);    // sprite
    frame: 9;                 // frame
    tics: 6;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_SKULL_DIE6;  // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_SKULL_DIE5

   (
    sprite: Ord(SPR_SKUL);    // sprite
    frame: 10;                // frame
    tics: 6;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_NULL;        // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_SKULL_DIE6

   (
    sprite: Ord(SPR_SPID);    // sprite
    frame: 0;                 // frame
    tics: 10;                 // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_SPID_STND2;  // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_SPID_STND

   (
    sprite: Ord(SPR_SPID);    // sprite
    frame: 1;                 // frame
    tics: 10;                 // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_SPID_STND;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_SPID_STND2

   (
    sprite: Ord(SPR_SPID);    // sprite
    frame: 0;                 // frame
    tics: 3;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_SPID_RUN2;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_SPID_RUN1

   (
    sprite: Ord(SPR_SPID);    // sprite
    frame: 0;                 // frame
    tics: 3;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_SPID_RUN3;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_SPID_RUN2

   (
    sprite: Ord(SPR_SPID);    // sprite
    frame: 1;                 // frame
    tics: 3;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_SPID_RUN4;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_SPID_RUN3

   (
    sprite: Ord(SPR_SPID);    // sprite
    frame: 1;                 // frame
    tics: 3;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_SPID_RUN5;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_SPID_RUN4

   (
    sprite: Ord(SPR_SPID);    // sprite
    frame: 2;                 // frame
    tics: 3;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_SPID_RUN6;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_SPID_RUN5

   (
    sprite: Ord(SPR_SPID);    // sprite
    frame: 2;                 // frame
    tics: 3;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_SPID_RUN7;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_SPID_RUN6

   (
    sprite: Ord(SPR_SPID);    // sprite
    frame: 3;                 // frame
    tics: 3;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_SPID_RUN8;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_SPID_RUN7

   (
    sprite: Ord(SPR_SPID);    // sprite
    frame: 3;                 // frame
    tics: 3;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_SPID_RUN9;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_SPID_RUN8

   (
    sprite: Ord(SPR_SPID);    // sprite
    frame: 4;                 // frame
    tics: 3;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_SPID_RUN10;  // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_SPID_RUN9

   (
    sprite: Ord(SPR_SPID);    // sprite
    frame: 4;                 // frame
    tics: 3;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_SPID_RUN11;  // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_SPID_RUN10

   (
    sprite: Ord(SPR_SPID);    // sprite
    frame: 5;                 // frame
    tics: 3;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_SPID_RUN12;  // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_SPID_RUN11

   (
    sprite: Ord(SPR_SPID);    // sprite
    frame: 5;                 // frame
    tics: 3;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_SPID_RUN1;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_SPID_RUN12

   (
    sprite: Ord(SPR_SPID);    // sprite
    frame: 32768;             // frame
    tics: 20;                 // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_SPID_ATK2;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_SPID_ATK1

   (
    sprite: Ord(SPR_SPID);    // sprite
    frame: 32774;             // frame
    tics: 4;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_SPID_ATK3;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_SPID_ATK2

   (
    sprite: Ord(SPR_SPID);    // sprite
    frame: 32775;             // frame
    tics: 4;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_SPID_ATK4;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_SPID_ATK3

   (
    sprite: Ord(SPR_SPID);    // sprite
    frame: 32775;             // frame
    tics: 1;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_SPID_ATK2;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_SPID_ATK4

   (
    sprite: Ord(SPR_SPID);    // sprite
    frame: 8;                 // frame
    tics: 3;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_SPID_PAIN2;  // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_SPID_PAIN

   (
    sprite: Ord(SPR_SPID);    // sprite
    frame: 8;                 // frame
    tics: 3;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_SPID_RUN1;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_SPID_PAIN2

   (
    sprite: Ord(SPR_SPID);    // sprite
    frame: 9;                 // frame
    tics: 20;                 // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_SPID_DIE2;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_SPID_DIE1

   (
    sprite: Ord(SPR_SPID);    // sprite
    frame: 10;                // frame
    tics: 10;                 // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_SPID_DIE3;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_SPID_DIE2

   (
    sprite: Ord(SPR_SPID);    // sprite
    frame: 11;                // frame
    tics: 10;                 // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_SPID_DIE4;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_SPID_DIE3

   (
    sprite: Ord(SPR_SPID);    // sprite
    frame: 12;                // frame
    tics: 10;                 // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_SPID_DIE5;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_SPID_DIE4

   (
    sprite: Ord(SPR_SPID);    // sprite
    frame: 13;                // frame
    tics: 10;                 // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_SPID_DIE6;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_SPID_DIE5

   (
    sprite: Ord(SPR_SPID);    // sprite
    frame: 14;                // frame
    tics: 10;                 // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_SPID_DIE7;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_SPID_DIE6

   (
    sprite: Ord(SPR_SPID);    // sprite
    frame: 15;                // frame
    tics: 10;                 // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_SPID_DIE8;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_SPID_DIE7

   (
    sprite: Ord(SPR_SPID);    // sprite
    frame: 16;                // frame
    tics: 10;                 // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_SPID_DIE9;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_SPID_DIE8

   (
    sprite: Ord(SPR_SPID);    // sprite
    frame: 17;                // frame
    tics: 10;                 // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_SPID_DIE10;  // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_SPID_DIE9

   (
    sprite: Ord(SPR_SPID);    // sprite
    frame: 18;                // frame
    tics: 30;                 // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_SPID_DIE11;  // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_SPID_DIE10

   (
    sprite: Ord(SPR_SPID);    // sprite
    frame: 18;                // frame
    tics: -1;                 // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_NULL;        // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_SPID_DIE11

   (
    sprite: Ord(SPR_BSPI);    // sprite
    frame: 0;                 // frame
    tics: 10;                 // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_BSPI_STND2;  // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_BSPI_STND

   (
    sprite: Ord(SPR_BSPI);    // sprite
    frame: 1;                 // frame
    tics: 10;                 // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_BSPI_STND;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_BSPI_STND2

   (
    sprite: Ord(SPR_BSPI);    // sprite
    frame: 0;                 // frame
    tics: 20;                 // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_BSPI_RUN1;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_BSPI_SIGHT

   (
    sprite: Ord(SPR_BSPI);    // sprite
    frame: 0;                 // frame
    tics: 3;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_BSPI_RUN2;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_BSPI_RUN1

   (
    sprite: Ord(SPR_BSPI);    // sprite
    frame: 0;                 // frame
    tics: 3;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_BSPI_RUN3;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_BSPI_RUN2

   (
    sprite: Ord(SPR_BSPI);    // sprite
    frame: 1;                 // frame
    tics: 3;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_BSPI_RUN4;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_BSPI_RUN3

   (
    sprite: Ord(SPR_BSPI);    // sprite
    frame: 1;                 // frame
    tics: 3;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_BSPI_RUN5;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_BSPI_RUN4

   (
    sprite: Ord(SPR_BSPI);    // sprite
    frame: 2;                 // frame
    tics: 3;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_BSPI_RUN6;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_BSPI_RUN5

   (
    sprite: Ord(SPR_BSPI);    // sprite
    frame: 2;                 // frame
    tics: 3;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_BSPI_RUN7;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_BSPI_RUN6

   (
    sprite: Ord(SPR_BSPI);    // sprite
    frame: 3;                 // frame
    tics: 3;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_BSPI_RUN8;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_BSPI_RUN7

   (
    sprite: Ord(SPR_BSPI);    // sprite
    frame: 3;                 // frame
    tics: 3;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_BSPI_RUN9;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_BSPI_RUN8

   (
    sprite: Ord(SPR_BSPI);    // sprite
    frame: 4;                 // frame
    tics: 3;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_BSPI_RUN10;  // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_BSPI_RUN9

   (
    sprite: Ord(SPR_BSPI);    // sprite
    frame: 4;                 // frame
    tics: 3;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_BSPI_RUN11;  // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_BSPI_RUN10

   (
    sprite: Ord(SPR_BSPI);    // sprite
    frame: 5;                 // frame
    tics: 3;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_BSPI_RUN12;  // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_BSPI_RUN11

   (
    sprite: Ord(SPR_BSPI);    // sprite
    frame: 5;                 // frame
    tics: 3;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_BSPI_RUN1;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_BSPI_RUN12

   (
    sprite: Ord(SPR_BSPI);    // sprite
    frame: 32768;             // frame
    tics: 20;                 // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_BSPI_ATK2;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_BSPI_ATK1

   (
    sprite: Ord(SPR_BSPI);    // sprite
    frame: 32774;             // frame
    tics: 4;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_BSPI_ATK3;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_BSPI_ATK2

   (
    sprite: Ord(SPR_BSPI);    // sprite
    frame: 32775;             // frame
    tics: 4;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_BSPI_ATK4;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_BSPI_ATK3

   (
    sprite: Ord(SPR_BSPI);    // sprite
    frame: 32775;             // frame
    tics: 1;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_BSPI_ATK2;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_BSPI_ATK4

   (
    sprite: Ord(SPR_BSPI);    // sprite
    frame: 8;                 // frame
    tics: 3;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_BSPI_PAIN2;  // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_BSPI_PAIN

   (
    sprite: Ord(SPR_BSPI);    // sprite
    frame: 8;                 // frame
    tics: 3;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_BSPI_RUN1;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_BSPI_PAIN2

   (
    sprite: Ord(SPR_BSPI);    // sprite
    frame: 9;                 // frame
    tics: 20;                 // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_BSPI_DIE2;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_BSPI_DIE1

   (
    sprite: Ord(SPR_BSPI);    // sprite
    frame: 10;                // frame
    tics: 7;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_BSPI_DIE3;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_BSPI_DIE2

   (
    sprite: Ord(SPR_BSPI);    // sprite
    frame: 11;                // frame
    tics: 7;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_BSPI_DIE4;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_BSPI_DIE3

   (
    sprite: Ord(SPR_BSPI);    // sprite
    frame: 12;                // frame
    tics: 7;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_BSPI_DIE5;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_BSPI_DIE4

   (
    sprite: Ord(SPR_BSPI);    // sprite
    frame: 13;                // frame
    tics: 7;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_BSPI_DIE6;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_BSPI_DIE5

   (
    sprite: Ord(SPR_BSPI);    // sprite
    frame: 14;                // frame
    tics: 7;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_BSPI_DIE7;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_BSPI_DIE6

   (
    sprite: Ord(SPR_BSPI);    // sprite
    frame: 15;                // frame
    tics: -1;                 // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_NULL;        // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_BSPI_DIE7

   (
    sprite: Ord(SPR_BSPI);    // sprite
    frame: 15;                // frame
    tics: 5;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_BSPI_RAISE2;  // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_BSPI_RAISE1

   (
    sprite: Ord(SPR_BSPI);    // sprite
    frame: 14;                // frame
    tics: 5;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_BSPI_RAISE3;  // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_BSPI_RAISE2

   (
    sprite: Ord(SPR_BSPI);    // sprite
    frame: 13;                // frame
    tics: 5;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_BSPI_RAISE4;  // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_BSPI_RAISE3

   (
    sprite: Ord(SPR_BSPI);    // sprite
    frame: 12;                // frame
    tics: 5;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_BSPI_RAISE5;  // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_BSPI_RAISE4

   (
    sprite: Ord(SPR_BSPI);    // sprite
    frame: 11;                // frame
    tics: 5;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_BSPI_RAISE6;  // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_BSPI_RAISE5

   (
    sprite: Ord(SPR_BSPI);    // sprite
    frame: 10;                // frame
    tics: 5;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_BSPI_RAISE7;  // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_BSPI_RAISE6

   (
    sprite: Ord(SPR_BSPI);    // sprite
    frame: 9;                 // frame
    tics: 5;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_BSPI_RUN1;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_BSPI_RAISE7

   (
    sprite: Ord(SPR_APLS);    // sprite
    frame: 32768;             // frame
    tics: 5;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_ARACH_PLAZ2;  // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_ARACH_PLAZ

   (
    sprite: Ord(SPR_APLS);    // sprite
    frame: 32769;             // frame
    tics: 5;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_ARACH_PLAZ;  // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_ARACH_PLAZ2

   (
    sprite: Ord(SPR_APBX);    // sprite
    frame: 32768;             // frame
    tics: 5;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_ARACH_PLEX2;  // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_ARACH_PLEX

   (
    sprite: Ord(SPR_APBX);    // sprite
    frame: 32769;             // frame
    tics: 5;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_ARACH_PLEX3;  // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_ARACH_PLEX2

   (
    sprite: Ord(SPR_APBX);    // sprite
    frame: 32770;             // frame
    tics: 5;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_ARACH_PLEX4;  // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_ARACH_PLEX3

   (
    sprite: Ord(SPR_APBX);    // sprite
    frame: 32771;             // frame
    tics: 5;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_ARACH_PLEX5;  // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_ARACH_PLEX4

   (
    sprite: Ord(SPR_APBX);    // sprite
    frame: 32772;             // frame
    tics: 5;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_NULL;        // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_ARACH_PLEX5

   (
    sprite: Ord(SPR_CYBR);    // sprite
    frame: 0;                 // frame
    tics: 10;                 // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_CYBER_STND2;  // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_CYBER_STND

   (
    sprite: Ord(SPR_CYBR);    // sprite
    frame: 1;                 // frame
    tics: 10;                 // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_CYBER_STND;  // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_CYBER_STND2

   (
    sprite: Ord(SPR_CYBR);    // sprite
    frame: 0;                 // frame
    tics: 3;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_CYBER_RUN2;  // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_CYBER_RUN1

   (
    sprite: Ord(SPR_CYBR);    // sprite
    frame: 0;                 // frame
    tics: 3;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_CYBER_RUN3;  // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_CYBER_RUN2

   (
    sprite: Ord(SPR_CYBR);    // sprite
    frame: 1;                 // frame
    tics: 3;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_CYBER_RUN4;  // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_CYBER_RUN3

   (
    sprite: Ord(SPR_CYBR);    // sprite
    frame: 1;                 // frame
    tics: 3;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_CYBER_RUN5;  // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_CYBER_RUN4

   (
    sprite: Ord(SPR_CYBR);    // sprite
    frame: 2;                 // frame
    tics: 3;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_CYBER_RUN6;  // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_CYBER_RUN5

   (
    sprite: Ord(SPR_CYBR);    // sprite
    frame: 2;                 // frame
    tics: 3;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_CYBER_RUN7;  // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_CYBER_RUN6

   (
    sprite: Ord(SPR_CYBR);    // sprite
    frame: 3;                 // frame
    tics: 3;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_CYBER_RUN8;  // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_CYBER_RUN7

   (
    sprite: Ord(SPR_CYBR);    // sprite
    frame: 3;                 // frame
    tics: 3;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_CYBER_RUN1;  // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_CYBER_RUN8

   (
    sprite: Ord(SPR_CYBR);    // sprite
    frame: 4;                 // frame
    tics: 6;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_CYBER_ATK2;  // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_CYBER_ATK1

   (
    sprite: Ord(SPR_CYBR);    // sprite
    frame: 5;                 // frame
    tics: 12;                 // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_CYBER_ATK3;  // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_CYBER_ATK2

   (
    sprite: Ord(SPR_CYBR);    // sprite
    frame: 4;                 // frame
    tics: 12;                 // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_CYBER_ATK4;  // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_CYBER_ATK3

   (
    sprite: Ord(SPR_CYBR);    // sprite
    frame: 5;                 // frame
    tics: 12;                 // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_CYBER_ATK5;  // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_CYBER_ATK4

   (
    sprite: Ord(SPR_CYBR);    // sprite
    frame: 4;                 // frame
    tics: 12;                 // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_CYBER_ATK6;  // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_CYBER_ATK5

   (
    sprite: Ord(SPR_CYBR);    // sprite
    frame: 5;                 // frame
    tics: 12;                 // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_CYBER_RUN1;  // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_CYBER_ATK6

   (
    sprite: Ord(SPR_CYBR);    // sprite
    frame: 6;                 // frame
    tics: 10;                 // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_CYBER_RUN1;  // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_CYBER_PAIN

   (
    sprite: Ord(SPR_CYBR);    // sprite
    frame: 7;                 // frame
    tics: 10;                 // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_CYBER_DIE2;  // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_CYBER_DIE1

   (
    sprite: Ord(SPR_CYBR);    // sprite
    frame: 8;                 // frame
    tics: 10;                 // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_CYBER_DIE3;  // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_CYBER_DIE2

   (
    sprite: Ord(SPR_CYBR);    // sprite
    frame: 9;                 // frame
    tics: 10;                 // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_CYBER_DIE4;  // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_CYBER_DIE3

   (
    sprite: Ord(SPR_CYBR);    // sprite
    frame: 10;                // frame
    tics: 10;                 // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_CYBER_DIE5;  // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_CYBER_DIE4

   (
    sprite: Ord(SPR_CYBR);    // sprite
    frame: 11;                // frame
    tics: 10;                 // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_CYBER_DIE6;  // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_CYBER_DIE5

   (
    sprite: Ord(SPR_CYBR);    // sprite
    frame: 12;                // frame
    tics: 10;                 // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_CYBER_DIE7;  // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_CYBER_DIE6

   (
    sprite: Ord(SPR_CYBR);    // sprite
    frame: 13;                // frame
    tics: 10;                 // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_CYBER_DIE8;  // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_CYBER_DIE7

   (
    sprite: Ord(SPR_CYBR);    // sprite
    frame: 14;                // frame
    tics: 10;                 // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_CYBER_DIE9;  // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_CYBER_DIE8

   (
    sprite: Ord(SPR_CYBR);    // sprite
    frame: 15;                // frame
    tics: 30;                 // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_CYBER_DIE10;  // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_CYBER_DIE9

   (
    sprite: Ord(SPR_CYBR);    // sprite
    frame: 15;                // frame
    tics: -1;                 // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_NULL;        // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_CYBER_DIE10

   (
    sprite: Ord(SPR_PAIN);    // sprite
    frame: 0;                 // frame
    tics: 10;                 // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_PAIN_STND;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_PAIN_STND

   (
    sprite: Ord(SPR_PAIN);    // sprite
    frame: 0;                 // frame
    tics: 3;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_PAIN_RUN2;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_PAIN_RUN1

   (
    sprite: Ord(SPR_PAIN);    // sprite
    frame: 0;                 // frame
    tics: 3;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_PAIN_RUN3;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_PAIN_RUN2

   (
    sprite: Ord(SPR_PAIN);    // sprite
    frame: 1;                 // frame
    tics: 3;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_PAIN_RUN4;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_PAIN_RUN3

   (
    sprite: Ord(SPR_PAIN);    // sprite
    frame: 1;                 // frame
    tics: 3;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_PAIN_RUN5;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_PAIN_RUN4

   (
    sprite: Ord(SPR_PAIN);    // sprite
    frame: 2;                 // frame
    tics: 3;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_PAIN_RUN6;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_PAIN_RUN5

   (
    sprite: Ord(SPR_PAIN);    // sprite
    frame: 2;                 // frame
    tics: 3;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_PAIN_RUN1;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_PAIN_RUN6

   (
    sprite: Ord(SPR_PAIN);    // sprite
    frame: 3;                 // frame
    tics: 5;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_PAIN_ATK2;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_PAIN_ATK1

   (
    sprite: Ord(SPR_PAIN);    // sprite
    frame: 4;                 // frame
    tics: 5;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_PAIN_ATK3;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_PAIN_ATK2

   (
    sprite: Ord(SPR_PAIN);    // sprite
    frame: 32773;             // frame
    tics: 5;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_PAIN_ATK4;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_PAIN_ATK3

   (
    sprite: Ord(SPR_PAIN);    // sprite
    frame: 32773;             // frame
    tics: 0;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_PAIN_RUN1;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_PAIN_ATK4

   (
    sprite: Ord(SPR_PAIN);    // sprite
    frame: 6;                 // frame
    tics: 6;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_PAIN_PAIN2;  // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_PAIN_PAIN

   (
    sprite: Ord(SPR_PAIN);    // sprite
    frame: 6;                 // frame
    tics: 6;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_PAIN_RUN1;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_PAIN_PAIN2

   (
    sprite: Ord(SPR_PAIN);    // sprite
    frame: 32775;             // frame
    tics: 8;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_PAIN_DIE2;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_PAIN_DIE1

   (
    sprite: Ord(SPR_PAIN);    // sprite
    frame: 32776;             // frame
    tics: 8;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_PAIN_DIE3;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_PAIN_DIE2

   (
    sprite: Ord(SPR_PAIN);    // sprite
    frame: 32777;             // frame
    tics: 8;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_PAIN_DIE4;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_PAIN_DIE3

   (
    sprite: Ord(SPR_PAIN);    // sprite
    frame: 32778;             // frame
    tics: 8;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_PAIN_DIE5;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_PAIN_DIE4

   (
    sprite: Ord(SPR_PAIN);    // sprite
    frame: 32779;             // frame
    tics: 8;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_PAIN_DIE6;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_PAIN_DIE5

   (
    sprite: Ord(SPR_PAIN);    // sprite
    frame: 32780;             // frame
    tics: 8;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_NULL;        // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_PAIN_DIE6

   (
    sprite: Ord(SPR_PAIN);    // sprite
    frame: 12;                // frame
    tics: 8;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_PAIN_RAISE2;  // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_PAIN_RAISE1

   (
    sprite: Ord(SPR_PAIN);    // sprite
    frame: 11;                // frame
    tics: 8;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_PAIN_RAISE3;  // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_PAIN_RAISE2

   (
    sprite: Ord(SPR_PAIN);    // sprite
    frame: 10;                // frame
    tics: 8;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_PAIN_RAISE4;  // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_PAIN_RAISE3

   (
    sprite: Ord(SPR_PAIN);    // sprite
    frame: 9;                 // frame
    tics: 8;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_PAIN_RAISE5;  // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_PAIN_RAISE4

   (
    sprite: Ord(SPR_PAIN);    // sprite
    frame: 8;                 // frame
    tics: 8;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_PAIN_RAISE6;  // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_PAIN_RAISE5

   (
    sprite: Ord(SPR_PAIN);    // sprite
    frame: 7;                 // frame
    tics: 8;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_PAIN_RUN1;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_PAIN_RAISE6

   (
    sprite: Ord(SPR_SSWV);    // sprite
    frame: 0;                 // frame
    tics: 10;                 // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_SSWV_STND2;  // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_SSWV_STND

   (
    sprite: Ord(SPR_SSWV);    // sprite
    frame: 1;                 // frame
    tics: 10;                 // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_SSWV_STND;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_SSWV_STND2

   (
    sprite: Ord(SPR_SSWV);    // sprite
    frame: 0;                 // frame
    tics: 3;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_SSWV_RUN2;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_SSWV_RUN1

   (
    sprite: Ord(SPR_SSWV);    // sprite
    frame: 0;                 // frame
    tics: 3;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_SSWV_RUN3;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_SSWV_RUN2

   (
    sprite: Ord(SPR_SSWV);    // sprite
    frame: 1;                 // frame
    tics: 3;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_SSWV_RUN4;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_SSWV_RUN3

   (
    sprite: Ord(SPR_SSWV);    // sprite
    frame: 1;                 // frame
    tics: 3;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_SSWV_RUN5;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_SSWV_RUN4

   (
    sprite: Ord(SPR_SSWV);    // sprite
    frame: 2;                 // frame
    tics: 3;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_SSWV_RUN6;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_SSWV_RUN5

   (
    sprite: Ord(SPR_SSWV);    // sprite
    frame: 2;                 // frame
    tics: 3;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_SSWV_RUN7;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_SSWV_RUN6

   (
    sprite: Ord(SPR_SSWV);    // sprite
    frame: 3;                 // frame
    tics: 3;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_SSWV_RUN8;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_SSWV_RUN7

   (
    sprite: Ord(SPR_SSWV);    // sprite
    frame: 3;                 // frame
    tics: 3;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_SSWV_RUN1;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_SSWV_RUN8

   (
    sprite: Ord(SPR_SSWV);    // sprite
    frame: 4;                 // frame
    tics: 10;                 // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_SSWV_ATK2;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_SSWV_ATK1

   (
    sprite: Ord(SPR_SSWV);    // sprite
    frame: 5;                 // frame
    tics: 10;                 // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_SSWV_ATK3;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_SSWV_ATK2

   (
    sprite: Ord(SPR_SSWV);    // sprite
    frame: 32774;             // frame
    tics: 4;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_SSWV_ATK4;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_SSWV_ATK3

   (
    sprite: Ord(SPR_SSWV);    // sprite
    frame: 5;                 // frame
    tics: 6;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_SSWV_ATK5;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_SSWV_ATK4

   (
    sprite: Ord(SPR_SSWV);    // sprite
    frame: 32774;             // frame
    tics: 4;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_SSWV_ATK6;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_SSWV_ATK5

   (
    sprite: Ord(SPR_SSWV);    // sprite
    frame: 5;                 // frame
    tics: 1;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_SSWV_ATK2;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_SSWV_ATK6

   (
    sprite: Ord(SPR_SSWV);    // sprite
    frame: 7;                 // frame
    tics: 3;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_SSWV_PAIN2;  // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_SSWV_PAIN

   (
    sprite: Ord(SPR_SSWV);    // sprite
    frame: 7;                 // frame
    tics: 3;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_SSWV_RUN1;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_SSWV_PAIN2

   (
    sprite: Ord(SPR_SSWV);    // sprite
    frame: 8;                 // frame
    tics: 5;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_SSWV_DIE2;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_SSWV_DIE1

   (
    sprite: Ord(SPR_SSWV);    // sprite
    frame: 9;                 // frame
    tics: 5;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_SSWV_DIE3;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_SSWV_DIE2

   (
    sprite: Ord(SPR_SSWV);    // sprite
    frame: 10;                // frame
    tics: 5;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_SSWV_DIE4;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_SSWV_DIE3

   (
    sprite: Ord(SPR_SSWV);    // sprite
    frame: 11;                // frame
    tics: 5;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_SSWV_DIE5;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_SSWV_DIE4

   (
    sprite: Ord(SPR_SSWV);    // sprite
    frame: 12;                // frame
    tics: -1;                 // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_NULL;        // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_SSWV_DIE5

   (
    sprite: Ord(SPR_SSWV);    // sprite
    frame: 13;                // frame
    tics: 5;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_SSWV_XDIE2;  // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_SSWV_XDIE1

   (
    sprite: Ord(SPR_SSWV);    // sprite
    frame: 14;                // frame
    tics: 5;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_SSWV_XDIE3;  // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_SSWV_XDIE2

   (
    sprite: Ord(SPR_SSWV);    // sprite
    frame: 15;                // frame
    tics: 5;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_SSWV_XDIE4;  // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_SSWV_XDIE3

   (
    sprite: Ord(SPR_SSWV);    // sprite
    frame: 16;                // frame
    tics: 5;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_SSWV_XDIE5;  // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_SSWV_XDIE4

   (
    sprite: Ord(SPR_SSWV);    // sprite
    frame: 17;                // frame
    tics: 5;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_SSWV_XDIE6;  // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_SSWV_XDIE5

   (
    sprite: Ord(SPR_SSWV);    // sprite
    frame: 18;                // frame
    tics: 5;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_SSWV_XDIE7;  // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_SSWV_XDIE6

   (
    sprite: Ord(SPR_SSWV);    // sprite
    frame: 19;                // frame
    tics: 5;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_SSWV_XDIE8;  // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_SSWV_XDIE7

   (
    sprite: Ord(SPR_SSWV);    // sprite
    frame: 20;                // frame
    tics: 5;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_SSWV_XDIE9;  // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_SSWV_XDIE8

   (
    sprite: Ord(SPR_SSWV);    // sprite
    frame: 21;                // frame
    tics: -1;                 // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_NULL;        // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_SSWV_XDIE9

   (
    sprite: Ord(SPR_SSWV);    // sprite
    frame: 12;                // frame
    tics: 5;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_SSWV_RAISE2;  // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_SSWV_RAISE1

   (
    sprite: Ord(SPR_SSWV);    // sprite
    frame: 11;                // frame
    tics: 5;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_SSWV_RAISE3;  // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_SSWV_RAISE2

   (
    sprite: Ord(SPR_SSWV);    // sprite
    frame: 10;                // frame
    tics: 5;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_SSWV_RAISE4;  // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_SSWV_RAISE3

   (
    sprite: Ord(SPR_SSWV);    // sprite
    frame: 9;                 // frame
    tics: 5;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_SSWV_RAISE5;  // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_SSWV_RAISE4

   (
    sprite: Ord(SPR_SSWV);    // sprite
    frame: 8;                 // frame
    tics: 5;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_SSWV_RUN1;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_SSWV_RAISE5

   (
    sprite: Ord(SPR_KEEN);    // sprite
    frame: 0;                 // frame
    tics: -1;                 // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_KEENSTND;    // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_KEENSTND

   (
    sprite: Ord(SPR_KEEN);    // sprite
    frame: 0;                 // frame
    tics: 6;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_COMMKEEN2;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_COMMKEEN

   (
    sprite: Ord(SPR_KEEN);    // sprite
    frame: 1;                 // frame
    tics: 6;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_COMMKEEN3;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_COMMKEEN2

   (
    sprite: Ord(SPR_KEEN);    // sprite
    frame: 2;                 // frame
    tics: 6;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_COMMKEEN4;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_COMMKEEN3

   (
    sprite: Ord(SPR_KEEN);    // sprite
    frame: 3;                 // frame
    tics: 6;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_COMMKEEN5;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_COMMKEEN4

   (
    sprite: Ord(SPR_KEEN);    // sprite
    frame: 4;                 // frame
    tics: 6;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_COMMKEEN6;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_COMMKEEN5

   (
    sprite: Ord(SPR_KEEN);    // sprite
    frame: 5;                 // frame
    tics: 6;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_COMMKEEN7;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_COMMKEEN6

   (
    sprite: Ord(SPR_KEEN);    // sprite
    frame: 6;                 // frame
    tics: 6;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_COMMKEEN8;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_COMMKEEN7

   (
    sprite: Ord(SPR_KEEN);    // sprite
    frame: 7;                 // frame
    tics: 6;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_COMMKEEN9;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_COMMKEEN8

   (
    sprite: Ord(SPR_KEEN);    // sprite
    frame: 8;                 // frame
    tics: 6;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_COMMKEEN10;  // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_COMMKEEN9

   (
    sprite: Ord(SPR_KEEN);    // sprite
    frame: 9;                 // frame
    tics: 6;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_COMMKEEN11;  // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_COMMKEEN10

   (
    sprite: Ord(SPR_KEEN);    // sprite
    frame: 10;                // frame
    tics: 6;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_COMMKEEN12;  // nextstate
    misc1: 0;                 // misc1
    misc2: 0),                // S_COMMKEEN11  // misc2

   (
    sprite: Ord(SPR_KEEN);    // sprite
    frame: 11;                // frame
    tics: -1;                 // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_NULL;        // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_COMMKEEN12

   (
    sprite: Ord(SPR_KEEN);    // sprite
    frame: 12;                // frame
    tics: 4;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_KEENPAIN2;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_KEENPAIN

   (
    sprite: Ord(SPR_KEEN);    // sprite
    frame: 12;                // frame
    tics: 8;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_KEENSTND;    // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_KEENPAIN2

   (
    sprite: Ord(SPR_BBRN);    // sprite
    frame: 0;                 // frame
    tics: -1;                 // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_NULL;        // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_BRAIN

   (
    sprite: Ord(SPR_BBRN);    // sprite
    frame: 1;                 // frame
    tics: 36;                 // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_BRAIN;       // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_BRAIN_PAIN

   (
    sprite: Ord(SPR_BBRN);    // sprite
    frame: 0;                 // frame
    tics: 100;                // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_BRAIN_DIE2;  // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_BRAIN_DIE1

   (
    sprite: Ord(SPR_BBRN);    // sprite
    frame: 0;                 // frame
    tics: 10;                 // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_BRAIN_DIE3;  // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_BRAIN_DIE2

   (
    sprite: Ord(SPR_BBRN);    // sprite
    frame: 0;                 // frame
    tics: 10;                 // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_BRAIN_DIE4;  // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_BRAIN_DIE3

   (
    sprite: Ord(SPR_BBRN);    // sprite
    frame: 0;                 // frame
    tics: -1;                 // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_NULL;        // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_BRAIN_DIE4

   (
    sprite: Ord(SPR_SSWV);    // sprite
    frame: 0;                 // frame
    tics: 10;                 // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_BRAINEYE;    // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_BRAINEYE

   (
    sprite: Ord(SPR_SSWV);    // sprite
    frame: 0;                 // frame
    tics: 181;                // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_BRAINEYE1;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_BRAINEYESEE

   (
    sprite: Ord(SPR_SSWV);    // sprite
    frame: 0;                 // frame
    tics: 150;                // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_BRAINEYE1;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_BRAINEYE1

   (
    sprite: Ord(SPR_BOSF);    // sprite
    frame: 32768;             // frame
    tics: 3;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_SPAWN2;      // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_SPAWN1

   (
    sprite: Ord(SPR_BOSF);    // sprite
    frame: 32769;             // frame
    tics: 3;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_SPAWN3;      // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_SPAWN2

   (
    sprite: Ord(SPR_BOSF);    // sprite
    frame: 32770;             // frame
    tics: 3;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_SPAWN4;      // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_SPAWN3

   (
    sprite: Ord(SPR_BOSF);    // sprite
    frame: 32771;             // frame
    tics: 3;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_SPAWN1;      // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_SPAWN4

   (
    sprite: Ord(SPR_FIRE);    // sprite
    frame: 32768;             // frame
    tics: 4;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_SPAWNFIRE2;  // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_SPAWNFIRE1

   (
    sprite: Ord(SPR_FIRE);    // sprite
    frame: 32769;             // frame
    tics: 4;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_SPAWNFIRE3;  // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_SPAWNFIRE2

   (
    sprite: Ord(SPR_FIRE);    // sprite
    frame: 32770;             // frame
    tics: 4;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_SPAWNFIRE4;  // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_SPAWNFIRE3

   (
    sprite: Ord(SPR_FIRE);    // sprite
    frame: 32771;             // frame
    tics: 4;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_SPAWNFIRE5;  // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_SPAWNFIRE4

   (
    sprite: Ord(SPR_FIRE);    // sprite
    frame: 32772;             // frame
    tics: 4;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_SPAWNFIRE6;  // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_SPAWNFIRE5

   (
    sprite: Ord(SPR_FIRE);    // sprite
    frame: 32773;             // frame
    tics: 4;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_SPAWNFIRE7;  // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_SPAWNFIRE6

   (
    sprite: Ord(SPR_FIRE);    // sprite
    frame: 32774;             // frame
    tics: 4;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_SPAWNFIRE8;  // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_SPAWNFIRE7

   (
    sprite: Ord(SPR_FIRE);    // sprite
    frame: 32775;             // frame
    tics: 4;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_NULL;        // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_SPAWNFIRE8

   (
    sprite: Ord(SPR_MISL);    // sprite
    frame: 32769;             // frame
    tics: 10;                 // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_BRAINEXPLODE2;  // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_BRAINEXPLODE1

   (
    sprite: Ord(SPR_MISL);    // sprite
    frame: 32770;             // frame
    tics: 10;                 // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_BRAINEXPLODE3;  // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_BRAINEXPLODE2

   (
    sprite: Ord(SPR_MISL);    // sprite
    frame: 32771;             // frame
    tics: 10;                 // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_NULL;        // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_BRAINEXPLODE3

   (
    sprite: Ord(SPR_ARM1);    // sprite
    frame: 0;                 // frame
    tics: 6;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_ARM1A;       // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_ARM1

   (
    sprite: Ord(SPR_ARM1);    // sprite
    frame: 32769;             // frame
    tics: 7;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_ARM1;        // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_ARM1A

   (
    sprite: Ord(SPR_ARM2);    // sprite
    frame: 0;                 // frame
    tics: 6;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_ARM2A;       // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_ARM2

   (
    sprite: Ord(SPR_ARM2);    // sprite
    frame: 32769;             // frame
    tics: 6;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_ARM2;        // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_ARM2A

   (
    sprite: Ord(SPR_BAR1);    // sprite
    frame: 0;                 // frame
    tics: 6;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_BAR2;        // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_BAR1

   (
    sprite: Ord(SPR_BAR1);    // sprite
    frame: 1;                 // frame
    tics: 6;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_BAR1;        // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_BAR2

   (
    sprite: Ord(SPR_BEXP);    // sprite
    frame: 32768;             // frame
    tics: 5;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_BEXP2;       // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: MF_EX_TRANSPARENT or MF_EX_WHITELIGHT;
   ),                         // S_BEXP

   (
    sprite: Ord(SPR_BEXP);    // sprite
    frame: 32769;             // frame
    tics: 5;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_BEXP3;       // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: MF_EX_TRANSPARENT or MF_EX_WHITELIGHT;
   ),                         // S_BEXP2

   (
    sprite: Ord(SPR_BEXP);    // sprite
    frame: 32770;             // frame
    tics: 5;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_BEXP4;       // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: MF_EX_TRANSPARENT or MF_EX_WHITELIGHT;
   ),                         // S_BEXP3

   (
    sprite: Ord(SPR_BEXP);    // sprite
    frame: 32771;             // frame
    tics: 10;                 // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_BEXP5;       // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: MF_EX_TRANSPARENT or MF_EX_WHITELIGHT;
   ),                         // S_BEXP4

   (
    sprite: Ord(SPR_BEXP);    // sprite
    frame: 32772;             // frame
    tics: 10;                 // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_NULL;        // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: MF_EX_TRANSPARENT or MF_EX_WHITELIGHT;
   ),                         // S_BEXP5

   (
    sprite: Ord(SPR_FCAN);    // sprite
    frame: 32768;             // frame
    tics: 4;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_BBAR2;       // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_BBAR1

   (
    sprite: Ord(SPR_FCAN);    // sprite
    frame: 32769;             // frame
    tics: 4;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_BBAR3;       // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_BBAR2

   (
    sprite: Ord(SPR_FCAN);    // sprite
    frame: 32770;             // frame
    tics: 4;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_BBAR1;       // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_BBAR3

   (
    sprite: Ord(SPR_BON1);    // sprite
    frame: 0;                 // frame
    tics: 6;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_BON1A;       // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_BON1

   (
    sprite: Ord(SPR_BON1);    // sprite
    frame: 1;                 // frame
    tics: 6;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_BON1B;       // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_BON1A

   (
    sprite: Ord(SPR_BON1);    // sprite
    frame: 2;                 // frame
    tics: 6;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_BON1C;       // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_BON1B

   (
    sprite: Ord(SPR_BON1);    // sprite
    frame: 3;                 // frame
    tics: 6;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_BON1D;       // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_BON1C

   (
    sprite: Ord(SPR_BON1);    // sprite
    frame: 2;                 // frame
    tics: 6;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_BON1E;       // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_BON1D

   (
    sprite: Ord(SPR_BON1);    // sprite
    frame: 1;                 // frame
    tics: 6;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_BON1;        // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_BON1E

   (
    sprite: Ord(SPR_BON2);    // sprite
    frame: 0;                 // frame
    tics: 6;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_BON2A;       // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_BON2

   (
    sprite: Ord(SPR_BON2);    // sprite
    frame: 1;                 // frame
    tics: 6;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_BON2B;       // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_BON2A

   (
    sprite: Ord(SPR_BON2);    // sprite
    frame: 2;                 // frame
    tics: 6;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_BON2C;       // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_BON2B

   (
    sprite: Ord(SPR_BON2);    // sprite
    frame: 3;                 // frame
    tics: 6;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_BON2D;       // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_BON2C

   (
    sprite: Ord(SPR_BON2);    // sprite
    frame: 2;                 // frame
    tics: 6;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_BON2E;       // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_BON2D

   (
    sprite: Ord(SPR_BON2);    // sprite
    frame: 1;                 // frame
    tics: 6;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_BON2;        // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_BON2E

   (
    sprite: Ord(SPR_BKEY);    // sprite
    frame: 0;                 // frame
    tics: 10;                 // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_BKEY2;       // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_BKEY

   (
    sprite: Ord(SPR_BKEY);    // sprite
    frame: 32769;             // frame
    tics: 10;                 // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_BKEY;        // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_BKEY2

   (
    sprite: Ord(SPR_RKEY);    // sprite
    frame: 0;                 // frame
    tics: 10;                 // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_RKEY2;       // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_RKEY

   (
    sprite: Ord(SPR_RKEY);    // sprite
    frame: 32769;             // frame
    tics: 10;                 // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_RKEY;        // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_RKEY2

   (
    sprite: Ord(SPR_YKEY);    // sprite
    frame: 0;                 // frame
    tics: 10;                 // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_YKEY2;       // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_YKEY

   (
    sprite: Ord(SPR_YKEY);    // sprite
    frame: 32769;             // frame
    tics: 10;                 // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_YKEY;        // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_YKEY2

   (
    sprite: Ord(SPR_BSKU);    // sprite
    frame: 0;                 // frame
    tics: 10;                 // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_BSKULL2;     // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_BSKULL

   (
    sprite: Ord(SPR_BSKU);    // sprite
    frame: 32769;             // frame
    tics: 10;                 // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_BSKULL;      // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_BSKULL2

   (
    sprite: Ord(SPR_RSKU);    // sprite
    frame: 0;                 // frame
    tics: 10;                 // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_RSKULL2;     // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_RSKULL

   (
    sprite: Ord(SPR_RSKU);    // sprite
    frame: 32769;             // frame
    tics: 10;                 // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_RSKULL;      // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_RSKULL2

   (
    sprite: Ord(SPR_YSKU);    // sprite
    frame: 0;                 // frame
    tics: 10;                 // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_YSKULL2;     // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_YSKULL

   (
    sprite: Ord(SPR_YSKU);    // sprite
    frame: 32769;             // frame
    tics: 10;                 // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_YSKULL;      // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_YSKULL2

   (
    sprite: Ord(SPR_STIM);    // sprite
    frame: 0;                 // frame
    tics: -1;                 // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_NULL;        // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_STIM

   (
    sprite: Ord(SPR_MEDI);    // sprite
    frame: 0;                 // frame
    tics: -1;                 // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_NULL;        // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_MEDI

   (
    sprite: Ord(SPR_SOUL);    // sprite
    frame: 32768;             // frame
    tics: 6;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_SOUL2;       // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_SOUL

   (
    sprite: Ord(SPR_SOUL);    // sprite
    frame: 32769;             // frame
    tics: 6;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_SOUL3;       // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_SOUL2

   (
    sprite: Ord(SPR_SOUL);    // sprite
    frame: 32770;             // frame
    tics: 6;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_SOUL4;       // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_SOUL3

   (
    sprite: Ord(SPR_SOUL);    // sprite
    frame: 32771;             // frame
    tics: 6;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_SOUL5;       // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_SOUL4

   (
    sprite: Ord(SPR_SOUL);    // sprite
    frame: 32770;             // frame
    tics: 6;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_SOUL6;       // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_SOUL5

   (
    sprite: Ord(SPR_SOUL);    // sprite
    frame: 32769;             // frame
    tics: 6;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_SOUL;        // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_SOUL6

   (
    sprite: Ord(SPR_PINV);    // sprite
    frame: 32768;             // frame
    tics: 6;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_PINV2;       // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_PINV

   (
    sprite: Ord(SPR_PINV);    // sprite
    frame: 32769;             // frame
    tics: 6;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_PINV3;       // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_PINV2

   (
    sprite: Ord(SPR_PINV);    // sprite
    frame: 32770;             // frame
    tics: 6;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_PINV4;       // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_PINV3

   (
    sprite: Ord(SPR_PINV);    // sprite
    frame: 32771;             // frame
    tics: 6;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_PINV;        // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_PINV4

   (
    sprite: Ord(SPR_PSTR);    // sprite
    frame: 32768;             // frame
    tics: -1;                 // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_NULL;        // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_PSTR

   (
    sprite: Ord(SPR_PINS);    // sprite
    frame: 32768;             // frame
    tics: 6;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_PINS2;       // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_PINS

   (
    sprite: Ord(SPR_PINS);    // sprite
    frame: 32769;             // frame
    tics: 6;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_PINS3;       // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_PINS2

   (
    sprite: Ord(SPR_PINS);    // sprite
    frame: 32770;             // frame
    tics: 6;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_PINS4;       // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_PINS3

   (
    sprite: Ord(SPR_PINS);    // sprite
    frame: 32771;             // frame
    tics: 6;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_PINS;        // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_PINS4

   (
    sprite: Ord(SPR_MEGA);    // sprite
    frame: 32768;             // frame
    tics: 6;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_MEGA2;       // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_MEGA

   (
    sprite: Ord(SPR_MEGA);    // sprite
    frame: 32769;             // frame
    tics: 6;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_MEGA3;       // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_MEGA2

   (
    sprite: Ord(SPR_MEGA);    // sprite
    frame: 32770;             // frame
    tics: 6;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_MEGA4;       // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_MEGA3

   (
    sprite: Ord(SPR_MEGA);    // sprite
    frame: 32771;             // frame
    tics: 6;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_MEGA;        // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_MEGA4

   (
    sprite: Ord(SPR_SUIT);    // sprite
    frame: 32768;             // frame
    tics: -1;                 // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_NULL;        // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_SUIT

   (
    sprite: Ord(SPR_PMAP);    // sprite
    frame: 32768;             // frame
    tics: 6;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_PMAP2;       // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_PMAP

   (
    sprite: Ord(SPR_PMAP);    // sprite
    frame: 32769;             // frame
    tics: 6;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_PMAP3;       // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_PMAP2

   (
    sprite: Ord(SPR_PMAP);    // sprite
    frame: 32770;             // frame
    tics: 6;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_PMAP4;       // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_PMAP3

   (
    sprite: Ord(SPR_PMAP);    // sprite
    frame: 32771;             // frame
    tics: 6;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_PMAP5;       // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_PMAP4

   (
    sprite: Ord(SPR_PMAP);    // sprite
    frame: 32770;             // frame
    tics: 6;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_PMAP6;       // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_PMAP5

   (
    sprite: Ord(SPR_PMAP);    // sprite
    frame: 32769;             // frame
    tics: 6;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_PMAP;        // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_PMAP6

   (
    sprite: Ord(SPR_PVIS);    // sprite
    frame: 32768;             // frame
    tics: 6;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_PVIS2;       // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_PVIS

   (
    sprite: Ord(SPR_PVIS);    // sprite
    frame: 1;                 // frame
    tics: 6;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_PVIS;        // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_PVIS2

   (
    sprite: Ord(SPR_CLIP);    // sprite
    frame: 0;                 // frame
    tics: -1;                 // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_NULL;        // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_CLIP

   (
    sprite: Ord(SPR_AMMO);    // sprite
    frame: 0;                 // frame
    tics: -1;                 // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_NULL;        // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_AMMO

   (
    sprite: Ord(SPR_ROCK);    // sprite
    frame: 0;                 // frame
    tics: -1;                 // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_NULL;        // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_ROCK

   (
    sprite: Ord(SPR_BROK);    // sprite
    frame: 0;                 // frame
    tics: -1;                 // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_NULL;        // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_BROK

   (
    sprite: Ord(SPR_CELL);    // sprite
    frame: 0;                 // frame
    tics: -1;                 // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_NULL;        // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_CELL

   (
    sprite: Ord(SPR_CELP);    // sprite
    frame: 0;                 // frame
    tics: -1;                 // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_NULL;        // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_CELP

   (
    sprite: Ord(SPR_SHEL);    // sprite
    frame: 0;                 // frame
    tics: -1;                 // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_NULL;        // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_SHEL

   (
    sprite: Ord(SPR_SBOX);    // sprite
    frame: 0;                 // frame
    tics: -1;                 // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_NULL;        // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_SBOX

   (
    sprite: Ord(SPR_BPAK);    // sprite
    frame: 0;                 // frame
    tics: -1;                 // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_NULL;        // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_BPAK

   (
    sprite: Ord(SPR_BFUG);    // sprite
    frame: 0;                 // frame
    tics: -1;                 // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_NULL;        // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_BFUG

   (
    sprite: Ord(SPR_MGUN);    // sprite
    frame: 0;                 // frame
    tics: -1;                 // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_NULL;        // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_MGUN

   (
    sprite: Ord(SPR_CSAW);    // sprite
    frame: 0;                 // frame
    tics: -1;                 // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_NULL;        // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_CSAW

   (
    sprite: Ord(SPR_LAUN);    // sprite
    frame: 0;                 // frame
    tics: -1;                 // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_NULL;        // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_LAUN

   (
    sprite: Ord(SPR_PLAS);    // sprite
    frame: 0;                 // frame
    tics: -1;                 // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_NULL;        // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_PLAS

   (
    sprite: Ord(SPR_SHOT);    // sprite
    frame: 0;                 // frame
    tics: -1;                 // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_NULL;        // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_SHOT

   (
    sprite: Ord(SPR_SGN2);    // sprite
    frame: 0;                 // frame
    tics: -1;                 // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_NULL;        // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_SHOT2

   (
    sprite: Ord(SPR_COLU);    // sprite
    frame: 32768;             // frame
    tics: -1;                 // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_NULL;        // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_COLU

   (
    sprite: Ord(SPR_SMT2);    // sprite
    frame: 0;                 // frame
    tics: -1;                 // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_NULL;        // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_STALAG

   (
    sprite: Ord(SPR_GOR1);    // sprite
    frame: 0;                 // frame
    tics: 10;                 // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_BLOODYTWITCH2;  // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_BLOODYTWITCH

   (
    sprite: Ord(SPR_GOR1);    // sprite
    frame: 1;                 // frame
    tics: 15;                 // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_BLOODYTWITCH3;  // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_BLOODYTWITCH2

   (
    sprite: Ord(SPR_GOR1);    // sprite
    frame: 2;                 // frame
    tics: 8;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_BLOODYTWITCH4;  // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_BLOODYTWITCH3

   (
    sprite: Ord(SPR_GOR1);    // sprite
    frame: 1;                 // frame
    tics: 6;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_BLOODYTWITCH;  // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_BLOODYTWITCH4

   (
    sprite: Ord(SPR_PLAY);    // sprite
    frame: 13;                // frame
    tics: -1;                 // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_NULL;        // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_DEADTORSO

   (
    sprite: Ord(SPR_PLAY);    // sprite
    frame: 18;                // frame
    tics: -1;                 // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_NULL;        // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_DEADBOTTOM

   (
    sprite: Ord(SPR_POL2);    // sprite
    frame: 0;                 // frame
    tics: -1;                 // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_NULL;        // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_HEADSONSTICK

   (
    sprite: Ord(SPR_POL5);    // sprite
    frame: 0;                 // frame
    tics: -1;                 // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_NULL;        // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_GIBS

   (
    sprite: Ord(SPR_POL4);    // sprite
    frame: 0;                 // frame
    tics: -1;                 // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_NULL;        // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_HEADONASTICK

   (
    sprite: Ord(SPR_POL3);    // sprite
    frame: 32768;             // frame
    tics: 6;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_HEADCANDLES2;  // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_HEADCANDLES

   (
    sprite: Ord(SPR_POL3);    // sprite
    frame: 32769;             // frame
    tics: 6;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_HEADCANDLES;  // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_HEADCANDLES2

   (
    sprite: Ord(SPR_POL1);    // sprite
    frame: 0;                 // frame
    tics: -1;                 // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_NULL;        // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_DEADSTICK

   (
    sprite: Ord(SPR_POL6);    // sprite
    frame: 0;                 // frame
    tics: 6;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_LIVESTICK2;  // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_LIVESTICK

   (
    sprite: Ord(SPR_POL6);    // sprite
    frame: 1;                 // frame
    tics: 8;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_LIVESTICK;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_LIVESTICK2

   (
    sprite: Ord(SPR_GOR2);    // sprite
    frame: 0;                 // frame
    tics: -1;                 // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_NULL;        // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_MEAT2

   (
    sprite: Ord(SPR_GOR3);    // sprite
    frame: 0;                 // frame
    tics: -1;                 // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_NULL;        // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_MEAT3

   (
    sprite: Ord(SPR_GOR4);    // sprite
    frame: 0;                 // frame
    tics: -1;                 // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_NULL;        // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_MEAT4

   (
    sprite: Ord(SPR_GOR5);    // sprite
    frame: 0;                 // frame
    tics: -1;                 // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_NULL;        // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_MEAT5

   (
    sprite: Ord(SPR_SMIT);    // sprite
    frame: 0;                 // frame
    tics: -1;                 // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_NULL;        // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_STALAGTITE

   (
    sprite: Ord(SPR_COL1);    // sprite
    frame: 0;                 // frame
    tics: -1;                 // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_NULL;        // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_TALLGRNCOL

   (
    sprite: Ord(SPR_COL2);    // sprite
    frame: 0;                 // frame
    tics: -1;                 // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_NULL;        // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_SHRTGRNCOL

   (
    sprite: Ord(SPR_COL3);    // sprite
    frame: 0;                 // frame
    tics: -1;                 // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_NULL;        // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_TALLREDCOL

   (
    sprite: Ord(SPR_COL4);    // sprite
    frame: 0;                 // frame
    tics: -1;                 // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_NULL;        // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_SHRTREDCOL

   (
    sprite: Ord(SPR_CAND);    // sprite
    frame: 32768;             // frame
    tics: -1;                 // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_NULL;        // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_CANDLESTIK

   (
    sprite: Ord(SPR_CBRA);    // sprite
    frame: 32768;             // frame
    tics: -1;                 // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_NULL;        // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_CANDELABRA

   (
    sprite: Ord(SPR_COL6);    // sprite
    frame: 0;                 // frame
    tics: -1;                 // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_NULL;        // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_SKULLCOL

   (
    sprite: Ord(SPR_TRE1);    // sprite
    frame: 0;                 // frame
    tics: -1;                 // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_NULL;        // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_TORCHTREE

   (
    sprite: Ord(SPR_TRE2);    // sprite
    frame: 0;                 // frame
    tics: -1;                 // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_NULL;        // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_BIGTREE

   (
    sprite: Ord(SPR_ELEC);    // sprite
    frame: 0;                 // frame
    tics: -1;                 // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_NULL;        // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_TECHPILLAR

   (
    sprite: Ord(SPR_CEYE);    // sprite
    frame: 32768;             // frame
    tics: 6;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_EVILEYE2;    // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_EVILEYE

   (
    sprite: Ord(SPR_CEYE);    // sprite
    frame: 32769;             // frame
    tics: 6;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_EVILEYE3;    // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_EVILEYE2

   (
    sprite: Ord(SPR_CEYE);    // sprite
    frame: 32770;             // frame
    tics: 6;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_EVILEYE4;    // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_EVILEYE3

   (
    sprite: Ord(SPR_CEYE);    // sprite
    frame: 32769;             // frame
    tics: 6;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_EVILEYE;     // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_EVILEYE4

   (
    sprite: Ord(SPR_FSKU);    // sprite
    frame: 32768;             // frame
    tics: 6;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_FLOATSKULL2; // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_FLOATSKULL

   (
    sprite: Ord(SPR_FSKU);    // sprite
    frame: 32769;             // frame
    tics: 6;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_FLOATSKULL3; // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_FLOATSKULL2

   (
    sprite: Ord(SPR_FSKU);    // sprite
    frame: 32770;             // frame
    tics: 6;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_FLOATSKULL;  // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_FLOATSKULL3

   (
    sprite: Ord(SPR_COL5);    // sprite
    frame: 0;                 // frame
    tics: 14;                 // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_HEARTCOL2;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_HEARTCOL

   (
    sprite: Ord(SPR_COL5);    // sprite
    frame: 1;                 // frame
    tics: 14;                 // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_HEARTCOL;    // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_HEARTCOL2

   (
    sprite: Ord(SPR_TBLU);    // sprite
    frame: 32768;             // frame
    tics: 4;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_BLUETORCH2;  // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_BLUETORCH

   (
    sprite: Ord(SPR_TBLU);    // sprite
    frame: 32769;             // frame
    tics: 4;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_BLUETORCH3;  // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_BLUETORCH2

   (
    sprite: Ord(SPR_TBLU);    // sprite
    frame: 32770;             // frame
    tics: 4;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_BLUETORCH4;  // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_BLUETORCH3

   (
    sprite: Ord(SPR_TBLU);    // sprite
    frame: 32771;             // frame
    tics: 4;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_BLUETORCH;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_BLUETORCH4

   (
    sprite: Ord(SPR_TGRN);    // sprite
    frame: 32768;             // frame
    tics: 4;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_GREENTORCH2;  // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_GREENTORCH

   (
    sprite: Ord(SPR_TGRN);    // sprite
    frame: 32769;             // frame
    tics: 4;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_GREENTORCH3;  // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_GREENTORCH2

   (
    sprite: Ord(SPR_TGRN);    // sprite
    frame: 32770;             // frame
    tics: 4;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_GREENTORCH4;  // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_GREENTORCH3

   (
    sprite: Ord(SPR_TGRN);    // sprite
    frame: 32771;             // frame
    tics: 4;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_GREENTORCH;  // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_GREENTORCH4

   (
    sprite: Ord(SPR_TRED);    // sprite
    frame: 32768;             // frame
    tics: 4;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_REDTORCH2;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_REDTORCH

   (
    sprite: Ord(SPR_TRED);    // sprite
    frame: 32769;             // frame
    tics: 4;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_REDTORCH3;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_REDTORCH2

   (
    sprite: Ord(SPR_TRED);    // sprite
    frame: 32770;             // frame
    tics: 4;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_REDTORCH4;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_REDTORCH3

   (
    sprite: Ord(SPR_TRED);    // sprite
    frame: 32771;             // frame
    tics: 4;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_REDTORCH;    // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_REDTORCH4

   (
    sprite: Ord(SPR_SMBT);    // sprite
    frame: 32768;             // frame
    tics: 4;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_BTORCHSHRT2;  // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_BTORCHSHRT

   (
    sprite: Ord(SPR_SMBT);    // sprite
    frame: 32769;             // frame
    tics: 4;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_BTORCHSHRT3;  // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_BTORCHSHRT2

   (
    sprite: Ord(SPR_SMBT);    // sprite
    frame: 32770;             // frame
    tics: 4;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_BTORCHSHRT4;  // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_BTORCHSHRT3

   (
    sprite: Ord(SPR_SMBT);    // sprite
    frame: 32771;             // frame
    tics: 4;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_BTORCHSHRT;  // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_BTORCHSHRT4

   (
    sprite: Ord(SPR_SMGT);    // sprite
    frame: 32768;             // frame
    tics: 4;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_GTORCHSHRT2;  // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_GTORCHSHRT

   (
    sprite: Ord(SPR_SMGT);    // sprite
    frame: 32769;             // frame
    tics: 4;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_GTORCHSHRT3;  // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_GTORCHSHRT2

   (
    sprite: Ord(SPR_SMGT);    // sprite
    frame: 32770;             // frame
    tics: 4;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_GTORCHSHRT4;  // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_GTORCHSHRT3

   (
    sprite: Ord(SPR_SMGT);    // sprite
    frame: 32771;             // frame
    tics: 4;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_GTORCHSHRT;  // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_GTORCHSHRT4

   (
    sprite: Ord(SPR_SMRT);    // sprite
    frame: 32768;             // frame
    tics: 4;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_RTORCHSHRT2;  // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_RTORCHSHRT

   (
    sprite: Ord(SPR_SMRT);    // sprite
    frame: 32769;             // frame
    tics: 4;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_RTORCHSHRT3;  // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_RTORCHSHRT2

   (
    sprite: Ord(SPR_SMRT);    // sprite
    frame: 32770;             // frame
    tics: 4;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_RTORCHSHRT4;  // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_RTORCHSHRT3

   (
    sprite: Ord(SPR_SMRT);    // sprite
    frame: 32771;             // frame
    tics: 4;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_RTORCHSHRT;  // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_RTORCHSHRT4

   (
    sprite: Ord(SPR_HDB1);    // sprite
    frame: 0;                 // frame
    tics: -1;                 // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_NULL;        // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_HANGNOGUTS

   (
    sprite: Ord(SPR_HDB2);    // sprite
    frame: 0;                 // frame
    tics: -1;                 // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_NULL;        // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_HANGBNOBRAIN

   (
    sprite: Ord(SPR_HDB3);    // sprite
    frame: 0;                 // frame
    tics: -1;                 // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_NULL;        // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_HANGTLOOKDN

   (
    sprite: Ord(SPR_HDB4);    // sprite
    frame: 0;                 // frame
    tics: -1;                 // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_NULL;        // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_HANGTSKULL

   (
    sprite: Ord(SPR_HDB5);    // sprite
    frame: 0;                 // frame
    tics: -1;                 // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_NULL;        // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_HANGTLOOKUP

   (
    sprite: Ord(SPR_HDB6);    // sprite
    frame: 0;                 // frame
    tics: -1;                 // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_NULL;        // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_HANGTNOBRAIN

   (
    sprite: Ord(SPR_POB1);    // sprite
    frame: 0;                 // frame
    tics: -1;                 // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_NULL;        // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_COLONGIBS

   (
    sprite: Ord(SPR_POB2);    // sprite
    frame: 0;                 // frame
    tics: -1;                 // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_NULL;        // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_SMALLPOOL

   (
    sprite: Ord(SPR_BRS1);    // sprite
    frame: 0;                 // frame
    tics: -1;                 // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_NULL;        // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_BRAINSTEM

   (
    sprite: Ord(SPR_TLMP);    // sprite
    frame: 32768;             // frame
    tics: 4;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_TECHLAMP2;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_TECHLAMP

   (
    sprite: Ord(SPR_TLMP);    // sprite
    frame: 32769;             // frame
    tics: 4;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_TECHLAMP3;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_TECHLAMP2

   (
    sprite: Ord(SPR_TLMP);    // sprite
    frame: 32770;             // frame
    tics: 4;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_TECHLAMP4;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_TECHLAMP3

   (
    sprite: Ord(SPR_TLMP);    // sprite
    frame: 32771;             // frame
    tics: 4;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_TECHLAMP;    // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_TECHLAMP4

   (
    sprite: Ord(SPR_TLP2);    // sprite
    frame: 32768;             // frame
    tics: 4;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_TECH2LAMP2;  // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_TECH2LAMP

   (
    sprite: Ord(SPR_TLP2);    // sprite
    frame: 32769;             // frame
    tics: 4;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_TECH2LAMP3;  // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_TECH2LAMP2

   (
    sprite: Ord(SPR_TLP2);    // sprite
    frame: 32770;             // frame
    tics: 4;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_TECH2LAMP4;  // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                         // S_TECH2LAMP3

   (
    sprite: Ord(SPR_TLP2);    // sprite
    frame: 32771;             // frame
    tics: 4;                  // tics
    action: (acp1: nil);      // action, will be set after
    nextstate: S_TECH2LAMP;   // nextstate
    misc1: 0;                 // misc1
    misc2: 0;                 // misc2
    flags_ex: 0;
   ),                          // S_TECH2LAMP4

   // New states
   (
    sprite: Ord(SPR_TNT1);
    frame: 0;
    tics: -1;
    action: (acp1: nil);
    nextstate: S_TNT1;
    misc1: 0;
    misc2: 0;
    flags_ex: 0;
   ),                          // S_TNT1

   (
    sprite: Ord(SPR_MISL);
    frame: 32768;
    tics: 1000;
    action: (acp1: nil);
    nextstate: S_GRENADE;
    misc1: 0;
    misc2: 0;
    flags_ex: 0;
   ),                          // S_GRENADE

   (
    sprite: Ord(SPR_MISL);
    frame: 32769;
    tics: 4;
    action: (acp1: nil);
    nextstate: S_DETONATE2;
    misc1: 0;
    misc2: 0;
    flags_ex: 0;
   ),                          // S_DETONATE

   (
    sprite: Ord(SPR_MISL);
    frame: 32770;
    tics: 6;
    action: (acp1: nil);
    nextstate: S_DETONATE3;
    misc1: 0;
    misc2: 0;
    flags_ex: 0;
   ),                          // S_DETONATE2

   (
    sprite: Ord(SPR_MISL);
    frame: 32771;
    tics: 10;
    action: (acp1: nil);
    nextstate: S_NULL;
    misc1: 0;
    misc2: 0;
    flags_ex: 0;
   ),                          // S_DETONATE3

   (
    sprite: Ord(SPR_DOGS);
    frame: 0;
    tics: 10;
    action: (acp1: nil);
    nextstate: S_DOGS_STND2;
    misc1: 0;
    misc2: 0;
    flags_ex: 0;
   ),                          // S_DOGS_STND

   (
    sprite: Ord(SPR_DOGS);
    frame: 1;
    tics: 10;
    action: (acp1: nil);
    nextstate: S_DOGS_STND;
    misc1: 0;
    misc2: 0;
    flags_ex: 0;
   ),                          // S_DOGS_STND2

   (
    sprite: Ord(SPR_DOGS);
    frame: 0;
    tics: 2;
    action: (acp1: nil);
    nextstate: S_DOGS_RUN2;
    misc1: 0;
    misc2: 0;
    flags_ex: 0;
   ),                          // S_DOGS_RUN1

   (
    sprite: Ord(SPR_DOGS);
    frame: 0;
    tics: 2;
    action: (acp1: nil);
    nextstate: S_DOGS_RUN3;
    misc1: 0;
    misc2: 0;
    flags_ex: 0;
   ),                          // S_DOGS_RUN2

   (
    sprite: Ord(SPR_DOGS);
    frame: 1;
    tics: 2;
    action: (acp1: nil);
    nextstate: S_DOGS_RUN4;
    misc1: 0;
    misc2: 0;
    flags_ex: 0;
   ),                          // S_DOGS_RUN3

   (
    sprite: Ord(SPR_DOGS);
    frame: 1;
    tics: 2;
    action: (acp1: nil);
    nextstate: S_DOGS_RUN5;
    misc1: 0;
    misc2: 0;
    flags_ex: 0;
   ),                          // S_DOGS_RUN4

   (
    sprite: Ord(SPR_DOGS);
    frame: 2;
    tics: 2;
    action: (acp1: nil);
    nextstate: S_DOGS_RUN6;
    misc1: 0;
    misc2: 0;
    flags_ex: 0;
   ),                          // S_DOGS_RUN5

   (
    sprite: Ord(SPR_DOGS);
    frame: 2;
    tics: 2;
    action: (acp1: nil);
    nextstate: S_DOGS_RUN7;
    misc1: 0;
    misc2: 0;
    flags_ex: 0;
   ),                          // S_DOGS_RUN6

   (
    sprite: Ord(SPR_DOGS);
    frame: 3;
    tics: 2;
    action: (acp1: nil);
    nextstate: S_DOGS_RUN8;
    misc1: 0;
    misc2: 0;
    flags_ex: 0;
   ),                          // S_DOGS_RUN7

   (
    sprite: Ord(SPR_DOGS);
    frame: 3;
    tics: 2;
    action: (acp1: nil);
    nextstate: S_DOGS_RUN1;
    misc1: 0;
    misc2: 0;
    flags_ex: 0;
   ),                          // S_DOGS_RUN8

   (
    sprite: Ord(SPR_DOGS);
    frame: 4;
    tics: 8;
    action: (acp1: nil);
    nextstate: S_DOGS_ATK2;
    misc1: 0;
    misc2: 0;
    flags_ex: 0;
   ),                          // S_DOGS_ATK1

   (
    sprite: Ord(SPR_DOGS);
    frame: 5;
    tics: 8;
    action: (acp1: nil);
    nextstate: S_DOGS_ATK3;
    misc1: 0;
    misc2: 0;
    flags_ex: 0;
   ),                          // S_DOGS_ATK2

   (
    sprite: Ord(SPR_DOGS);
    frame: 6;
    tics: 8;
    action: (acp1: nil);
    nextstate: S_DOGS_RUN1;
    misc1: 0;
    misc2: 0;
    flags_ex: 0;
   ),                          // S_DOGS_ATK3

   (
    sprite: Ord(SPR_DOGS);
    frame: 7;
    tics: 2;
    action: (acp1: nil);
    nextstate: S_DOGS_PAIN2;
    misc1: 0;
    misc2: 0;
    flags_ex: 0;
   ),                          // S_DOGS_PAIN

   (
    sprite: Ord(SPR_DOGS);
    frame: 7;
    tics: 2;
    action: (acp1: nil);
    nextstate: S_DOGS_RUN1;
    misc1: 0;
    misc2: 0;
    flags_ex: 0;
   ),                          // S_DOGS_PAIN2

   (
    sprite: Ord(SPR_DOGS);
    frame: 8;
    tics: 8;
    action: (acp1: nil);
    nextstate: S_DOGS_DIE2;
    misc1: 0;
    misc2: 0;
    flags_ex: 0;
   ),                          // S_DOGS_DIE1

   (
    sprite: Ord(SPR_DOGS);
    frame: 9;
    tics: 8;
    action: (acp1: nil);
    nextstate: S_DOGS_DIE3;
    misc1: 0;
    misc2: 0;
    flags_ex: 0;
   ),                          // S_DOGS_DIE2

   (
    sprite: Ord(SPR_DOGS);
    frame: 10;
    tics: 4;
    action: (acp1: nil);
    nextstate: S_DOGS_DIE4;
    misc1: 0;
    misc2: 0;
    flags_ex: 0;
   ),                          // S_DOGS_DIE3

   (
    sprite: Ord(SPR_DOGS);
    frame: 11;
    tics: 4;
    action: (acp1: nil);
    nextstate: S_DOGS_DIE5;
    misc1: 0;
    misc2: 0;
    flags_ex: 0;
   ),                          // S_DOGS_DIE4

   (
    sprite: Ord(SPR_DOGS);
    frame: 12;
    tics: 4;
    action: (acp1: nil);
    nextstate: S_DOGS_DIE6;
    misc1: 0;
    misc2: 0;
    flags_ex: 0;
   ),                          // S_DOGS_DIE5

   (
    sprite: Ord(SPR_DOGS);
    frame: 13;
    tics: -1;
    action: (acp1: nil);
    nextstate: S_NULL;
    misc1: 0;
    misc2: 0;
    flags_ex: 0;
   ),                          // S_DOGS_DIE6

   (
    sprite: Ord(SPR_DOGS);
    frame: 13;
    tics: 5;
    action: (acp1: nil);
    nextstate: S_DOGS_RAISE2;
    misc1: 0;
    misc2: 0;
    flags_ex: 0;
   ),                          // S_DOGS_RAISE1

   (
    sprite: Ord(SPR_DOGS);
    frame: 12;
    tics: 5;
    action: (acp1: nil);
    nextstate: S_DOGS_RAISE3;
    misc1: 0;
    misc2: 0;
    flags_ex: 0;
   ),                          // S_DOGS_RAISE2

   (
    sprite: Ord(SPR_DOGS);
    frame: 11;
    tics: 5;
    action: (acp1: nil);
    nextstate: S_DOGS_RAISE4;
    misc1: 0;
    misc2: 0;
    flags_ex: 0;
   ),                          // S_DOGS_RAISE3

   (
    sprite: Ord(SPR_DOGS);
    frame: 10;
    tics: 5;
    action: (acp1: nil);
    nextstate: S_DOGS_RAISE5;
    misc1: 0;
    misc2: 0;
    flags_ex: 0;
   ),                          // S_DOGS_RAISE4

   (
    sprite: Ord(SPR_DOGS);
    frame: 9;
    tics: 5;
    action: (acp1: nil);
    nextstate: S_DOGS_RAISE6;
    misc1: 0;
    misc2: 0;
    flags_ex: 0;
   ),                          // S_DOGS_RAISE5

   (
    sprite: Ord(SPR_DOGS);
    frame: 8;
    tics: 5;
    action: (acp1: nil);
    nextstate: S_DOGS_RUN1;
    misc1: 0;
    misc2: 0;
    flags_ex: 0;
   ),                          // S_DOGS_RAISE6

   (
    sprite: Ord(SPR_BFGG);
    frame: 0;
    tics: 10;
    action: (acp1: nil);
    nextstate: S_OLDBFG2;
    misc1: 0;
    misc2: 0;
    flags_ex: 0;
   ),                          // S_OLDBFG1

   (
    sprite: Ord(SPR_BFGG);
    frame: 1;
    tics: 1;
    action: (acp1: nil);
    nextstate: S_OLDBFG3;
    misc1: 0;
    misc2: 0;
    flags_ex: 0;
   ),                          // S_OLDBFG2

   (
    sprite: Ord(SPR_BFGG);
    frame: 1;
    tics: 1;
    action: (acp1: nil);
    nextstate: S_OLDBFG4;
    misc1: 0;
    misc2: 0;
    flags_ex: 0;
   ),                          // S_OLDBFG3

   (
    sprite: Ord(SPR_BFGG);
    frame: 1;
    tics: 1;
    action: (acp1: nil);
    nextstate: S_OLDBFG5;
    misc1: 0;
    misc2: 0;
    flags_ex: 0;
   ),                          // S_OLDBFG4

   (
    sprite: Ord(SPR_BFGG);
    frame: 1;
    tics: 1;
    action: (acp1: nil);
    nextstate: S_OLDBFG6;
    misc1: 0;
    misc2: 0;
    flags_ex: 0;
   ),                          // S_OLDBFG5

   (
    sprite: Ord(SPR_BFGG);
    frame: 1;
    tics: 1;
    action: (acp1: nil);
    nextstate: S_OLDBFG7;
    misc1: 0;
    misc2: 0;
    flags_ex: 0;
   ),                          // S_OLDBFG6

   (
    sprite: Ord(SPR_BFGG);
    frame: 1;
    tics: 1;
    action: (acp1: nil);
    nextstate: S_OLDBFG8;
    misc1: 0;
    misc2: 0;
    flags_ex: 0;
   ),                          // S_OLDBFG7

   (
    sprite: Ord(SPR_BFGG);
    frame: 1;
    tics: 1;
    action: (acp1: nil);
    nextstate: S_OLDBFG9;
    misc1: 0;
    misc2: 0;
    flags_ex: 0;
   ),                          // S_OLDBFG8

   (
    sprite: Ord(SPR_BFGG);
    frame: 1;
    tics: 1;
    action: (acp1: nil);
    nextstate: S_OLDBFG10;
    misc1: 0;
    misc2: 0;
    flags_ex: 0;
   ),                          // S_OLDBFG9

   (
    sprite: Ord(SPR_BFGG);
    frame: 1;
    tics: 1;
    action: (acp1: nil);
    nextstate: S_OLDBFG11;
    misc1: 0;
    misc2: 0;
    flags_ex: 0;
   ),                          // S_OLDBFG10

   (
    sprite: Ord(SPR_BFGG);
    frame: 1;
    tics: 1;
    action: (acp1: nil);
    nextstate: S_OLDBFG12;
    misc1: 0;
    misc2: 0;
    flags_ex: 0;
   ),                          // S_OLDBFG11

   (
    sprite: Ord(SPR_BFGG);
    frame: 1;
    tics: 1;
    action: (acp1: nil);
    nextstate: S_OLDBFG13;
    misc1: 0;
    misc2: 0;
    flags_ex: 0;
   ),                          // S_OLDBFG12

   (
    sprite: Ord(SPR_BFGG);
    frame: 1;
    tics: 1;
    action: (acp1: nil);
    nextstate: S_OLDBFG14;
    misc1: 0;
    misc2: 0;
    flags_ex: 0;
   ),                          // S_OLDBFG13

   (
    sprite: Ord(SPR_BFGG);
    frame: 1;
    tics: 1;
    action: (acp1: nil);
    nextstate: S_OLDBFG15;
    misc1: 0;
    misc2: 0;
    flags_ex: 0;
   ),                          // S_OLDBFG14

   (
    sprite: Ord(SPR_BFGG);
    frame: 1;
    tics: 1;
    action: (acp1: nil);
    nextstate: S_OLDBFG16;
    misc1: 0;
    misc2: 0;
    flags_ex: 0;
   ),                          // S_OLDBFG15

   (
    sprite: Ord(SPR_BFGG);
    frame: 1;
    tics: 1;
    action: (acp1: nil);
    nextstate: S_OLDBFG17;
    misc1: 0;
    misc2: 0;
    flags_ex: 0;
   ),                          // S_OLDBFG16

   (
    sprite: Ord(SPR_BFGG);
    frame: 1;
    tics: 1;
    action: (acp1: nil);
    nextstate: S_OLDBFG18;
    misc1: 0;
    misc2: 0;
    flags_ex: 0;
   ),                          // S_OLDBFG17

   (
    sprite: Ord(SPR_BFGG);
    frame: 1;
    tics: 1;
    action: (acp1: nil);
    nextstate: S_OLDBFG19;
    misc1: 0;
    misc2: 0;
    flags_ex: 0;
   ),                          // S_OLDBFG18

   (
    sprite: Ord(SPR_BFGG);
    frame: 1;
    tics: 1;
    action: (acp1: nil);
    nextstate: S_OLDBFG20;
    misc1: 0;
    misc2: 0;
    flags_ex: 0;
   ),                          // S_OLDBFG19

   (
    sprite: Ord(SPR_BFGG);
    frame: 1;
    tics: 1;
    action: (acp1: nil);
    nextstate: S_OLDBFG21;
    misc1: 0;
    misc2: 0;
    flags_ex: 0;
   ),                          // S_OLDBFG20

   (
    sprite: Ord(SPR_BFGG);
    frame: 1;
    tics: 1;
    action: (acp1: nil);
    nextstate: S_OLDBFG22;
    misc1: 0;
    misc2: 0;
    flags_ex: 0;
   ),                          // S_OLDBFG21

   (
    sprite: Ord(SPR_BFGG);
    frame: 1;
    tics: 1;
    action: (acp1: nil);
    nextstate: S_OLDBFG23;
    misc1: 0;
    misc2: 0;
    flags_ex: 0;
   ),                          // S_OLDBFG22

   (
    sprite: Ord(SPR_BFGG);
    frame: 1;
    tics: 1;
    action: (acp1: nil);
    nextstate: S_OLDBFG24;
    misc1: 0;
    misc2: 0;
    flags_ex: 0;
   ),                          // S_OLDBFG23

   (
    sprite: Ord(SPR_BFGG);
    frame: 1;
    tics: 1;
    action: (acp1: nil);
    nextstate: S_OLDBFG25;
    misc1: 0;
    misc2: 0;
    flags_ex: 0;
   ),                          // S_OLDBFG24

   (
    sprite: Ord(SPR_BFGG);
    frame: 1;
    tics: 1;
    action: (acp1: nil);
    nextstate: S_OLDBFG26;
    misc1: 0;
    misc2: 0;
    flags_ex: 0;
   ),                          // S_OLDBFG25

   (
    sprite: Ord(SPR_BFGG);
    frame: 1;
    tics: 1;
    action: (acp1: nil);
    nextstate: S_OLDBFG27;
    misc1: 0;
    misc2: 0;
    flags_ex: 0;
   ),                          // S_OLDBFG26

   (
    sprite: Ord(SPR_BFGG);
    frame: 1;
    tics: 1;
    action: (acp1: nil);
    nextstate: S_OLDBFG28;
    misc1: 0;
    misc2: 0;
    flags_ex: 0;
   ),                          // S_OLDBFG27

   (
    sprite: Ord(SPR_BFGG);
    frame: 1;
    tics: 1;
    action: (acp1: nil);
    nextstate: S_OLDBFG29;
    misc1: 0;
    misc2: 0;
    flags_ex: 0;
   ),                          // S_OLDBFG28

   (
    sprite: Ord(SPR_BFGG);
    frame: 1;
    tics: 1;
    action: (acp1: nil);
    nextstate: S_OLDBFG30;
    misc1: 0;
    misc2: 0;
    flags_ex: 0;
   ),                          // S_OLDBFG29

   (
    sprite: Ord(SPR_BFGG);
    frame: 1;
    tics: 1;
    action: (acp1: nil);
    nextstate: S_OLDBFG31;
    misc1: 0;
    misc2: 0;
    flags_ex: 0;
   ),                          // S_OLDBFG30

   (
    sprite: Ord(SPR_BFGG);
    frame: 1;
    tics: 1;
    action: (acp1: nil);
    nextstate: S_OLDBFG32;
    misc1: 0;
    misc2: 0;
    flags_ex: 0;
   ),                          // S_OLDBFG31

   (
    sprite: Ord(SPR_BFGG);
    frame: 1;
    tics: 1;
    action: (acp1: nil);
    nextstate: S_OLDBFG33;
    misc1: 0;
    misc2: 0;
    flags_ex: 0;
   ),                          // S_OLDBFG32

   (
    sprite: Ord(SPR_BFGG);
    frame: 1;
    tics: 1;
    action: (acp1: nil);
    nextstate: S_OLDBFG34;
    misc1: 0;
    misc2: 0;
    flags_ex: 0;
   ),                          // S_OLDBFG33

   (
    sprite: Ord(SPR_BFGG);
    frame: 1;
    tics: 1;
    action: (acp1: nil);
    nextstate: S_OLDBFG35;
    misc1: 0;
    misc2: 0;
    flags_ex: 0;
   ),                          // S_OLDBFG34

   (
    sprite: Ord(SPR_BFGG);
    frame: 1;
    tics: 1;
    action: (acp1: nil);
    nextstate: S_OLDBFG36;
    misc1: 0;
    misc2: 0;
    flags_ex: 0;
   ),                          // S_OLDBFG35

   (
    sprite: Ord(SPR_BFGG);
    frame: 1;
    tics: 1;
    action: (acp1: nil);
    nextstate: S_OLDBFG37;
    misc1: 0;
    misc2: 0;
    flags_ex: 0;
   ),                          // S_OLDBFG36

   (
    sprite: Ord(SPR_BFGG);
    frame: 1;
    tics: 1;
    action: (acp1: nil);
    nextstate: S_OLDBFG38;
    misc1: 0;
    misc2: 0;
    flags_ex: 0;
   ),                          // S_OLDBFG37

   (
    sprite: Ord(SPR_BFGG);
    frame: 1;
    tics: 1;
    action: (acp1: nil);
    nextstate: S_OLDBFG39;
    misc1: 0;
    misc2: 0;
    flags_ex: 0;
   ),                          // S_OLDBFG38

   (
    sprite: Ord(SPR_BFGG);
    frame: 1;
    tics: 1;
    action: (acp1: nil);
    nextstate: S_OLDBFG40;
    misc1: 0;
    misc2: 0;
    flags_ex: 0;
   ),                          // S_OLDBFG39

   (
    sprite: Ord(SPR_BFGG);
    frame: 1;
    tics: 1;
    action: (acp1: nil);
    nextstate: S_OLDBFG41;
    misc1: 0;
    misc2: 0;
    flags_ex: 0;
   ),                          // S_OLDBFG40

   (
    sprite: Ord(SPR_BFGG);
    frame: 1;
    tics: 1;
    action: (acp1: nil);
    nextstate: S_OLDBFG42;
    misc1: 0;
    misc2: 0;
    flags_ex: 0;
   ),                          // S_OLDBFG41

   (
    sprite: Ord(SPR_BFGG);
    frame: 1;
    tics: 0;
    action: (acp1: nil);
    nextstate: S_OLDBFG43;
    misc1: 0;
    misc2: 0;
    flags_ex: 0;
   ),                          // S_OLDBFG42

   (
    sprite: Ord(SPR_BFGG);
    frame: 1;
    tics: 20;
    action: (acp1: nil);
    nextstate: S_BFG;
    misc1: 0;
    misc2: 0;
    flags_ex: 0;
   ),                          // S_OLDBFG43

   (
    sprite: Ord(SPR_PLS1);
    frame: 32768;
    tics: 6;
    action: (acp1: nil);
    nextstate: S_PLS1BALL2;
    misc1: 0;
    misc2: 0;
    flags_ex: 0;
   ),                          // S_PLS1BALL

   (
    sprite: Ord(SPR_PLS1);
    frame: 32769;
    tics: 6;
    action: (acp1: nil);
    nextstate: S_PLS1BALL;
    misc1: 0;
    misc2: 0;
    flags_ex: 0;
   ),                          // S_PLS1BALL2

   (
    sprite: Ord(SPR_PLS1);
    frame: 32770;
    tics: 4;
    action: (acp1: nil);
    nextstate: S_PLS1EXP2;
    misc1: 0;
    misc2: 0;
    flags_ex: 0;
   ),                          // S_PLS1EXP

   (
    sprite: Ord(SPR_PLS1);
    frame: 32771;
    tics: 4;
    action: (acp1: nil);
    nextstate: S_PLS1EXP3;
    misc1: 0;
    misc2: 0;
    flags_ex: 0;
   ),                          // S_PLS1EXP2

   (
    sprite: Ord(SPR_PLS1);
    frame: 32772;
    tics: 4;
    action: (acp1: nil);
    nextstate: S_PLS1EXP4;
    misc1: 0;
    misc2: 0;
    flags_ex: 0;
   ),                          // S_PLS1EXP3

   (
    sprite: Ord(SPR_PLS1);
    frame: 32773;
    tics: 4;
    action: (acp1: nil);
    nextstate: S_PLS1EXP5;
    misc1: 0;
    misc2: 0;
    flags_ex: 0;
   ),                          // S_PLS1EXP4

   (
    sprite: Ord(SPR_PLS1);
    frame: 32774;
    tics: 4;
    action: (acp1: nil);
    nextstate: S_NULL;
    misc1: 0;
    misc2: 0;
    flags_ex: 0;
   ),                          // S_PLS1EXP5

   (
    sprite: Ord(SPR_PLS2);
    frame: 32768;
    tics: 4;
    action: (acp1: nil);
    nextstate: S_PLS2BALL2;
    misc1: 0;
    misc2: 0;
    flags_ex: 0;
   ),                          // S_PLS2BALL

   (
    sprite: Ord(SPR_PLS2);
    frame: 32769;
    tics: 4;
    action: (acp1: nil);
    nextstate: S_PLS2BALL;
    misc1: 0;
    misc2: 0;
    flags_ex: 0;
   ),                          // S_PLS2BALL2

   (
    sprite: Ord(SPR_PLS2);
    frame: 32770;
    tics: 6;
    action: (acp1: nil);
    nextstate: S_PLS2BALLX2;
    misc1: 0;
    misc2: 0;
    flags_ex: 0;
   ),                          // S_PLS2BALLX1

   (
    sprite: Ord(SPR_PLS2);
    frame: 32771;
    tics: 6;
    action: (acp1: nil);
    nextstate: S_PLS2BALLX3;
    misc1: 0;
    misc2: 0;
    flags_ex: 0;
   ),                          // S_PLS2BALLX2

   (
    sprite: Ord(SPR_PLS2);
    frame: 32772;
    tics: 6;
    action: (acp1: nil);
    nextstate: S_NULL;
    misc1: 0;
    misc2: 0;
    flags_ex: 0;
   ),                          // S_PLS2BALLX3

   (
    sprite: Ord(SPR_BON3);
    frame: 0;
    tics: 6;
    action: (acp1: nil);
    nextstate: S_BON3;
    misc1: 0;
    misc2: 0;
    flags_ex: 0;
   ),                          // S_BON3

   (
    sprite: Ord(SPR_BON4);
    frame: 0;
    tics: 6;
    action: (acp1: nil);
    nextstate: S_BON4;
    misc1: 0;
    misc2: 0;
    flags_ex: 0;
   ),                          // S_BON4

   (
    sprite: Ord(SPR_SKUL);
    frame: 0;
    tics: 10;
    action: (acp1: nil);
    nextstate: S_BSKUL_STND;
    misc1: 0;
    misc2: 0;
    flags_ex: 0;
   ),                          // S_BSKUL_STND

   (
    sprite: Ord(SPR_SKUL);
    frame: 1;
    tics: 5;
    action: (acp1: nil);
    nextstate: S_BSKUL_RUN2;
    misc1: 0;
    misc2: 0;
    flags_ex: 0;
   ),                          // S_BSKUL_RUN1

   (
    sprite: Ord(SPR_SKUL);
    frame: 2;
    tics: 5;
    action: (acp1: nil);
    nextstate: S_BSKUL_RUN3;
    misc1: 0;
    misc2: 0;
    flags_ex: 0;
   ),                          // S_BSKUL_RUN2

   (
    sprite: Ord(SPR_SKUL);
    frame: 3;
    tics: 5;
    action: (acp1: nil);
    nextstate: S_BSKUL_RUN4;
    misc1: 0;
    misc2: 0;
    flags_ex: 0;
   ),                          // S_BSKUL_RUN3

   (
    sprite: Ord(SPR_SKUL);
    frame: 0;
    tics: 5;
    action: (acp1: nil);
    nextstate: S_BSKUL_RUN1;
    misc1: 0;
    misc2: 0;
    flags_ex: 0;
   ),                          // S_BSKUL_RUN4

   (
    sprite: Ord(SPR_SKUL);
    frame: 4;
    tics: 4;
    action: (acp1: nil);
    nextstate: S_BSKUL_ATK2;
    misc1: 0;
    misc2: 0;
    flags_ex: 0;
   ),                          // S_BSKUL_ATK1

   (
    sprite: Ord(SPR_SKUL);
    frame: 5;
    tics: 5;
    action: (acp1: nil);
    nextstate: S_BSKUL_ATK3;
    misc1: 0;
    misc2: 0;
    flags_ex: 0;
   ),                          // S_BSKUL_ATK2

   (
    sprite: Ord(SPR_SKUL);
    frame: 5;
    tics: 4;
    action: (acp1: nil);
    nextstate: S_BSKUL_RUN1;
    misc1: 0;
    misc2: 0;
    flags_ex: 0;
   ),                          // S_BSKUL_ATK3

   (
    sprite: Ord(SPR_SKUL);
    frame: 6;
    tics: 4;
    action: (acp1: nil);
    nextstate: S_BSKUL_PAIN2;
    misc1: 0;
    misc2: 0;
    flags_ex: 0;
   ),                          // S_BSKUL_PAIN1

   (
    sprite: Ord(SPR_SKUL);
    frame: 7;
    tics: 2;
    action: (acp1: nil);
    nextstate: S_BSKUL_RUN1;
    misc1: 0;
    misc2: 0;
    flags_ex: 0;
   ),                          // S_BSKUL_PAIN2

   (
    sprite: Ord(SPR_SKUL);
    frame: 8;
    tics: 4;
    action: (acp1: nil);
    nextstate: S_BSKUL_RUN1;
    misc1: 0;
    misc2: 0;
    flags_ex: 0;
   ),                          // S_BSKUL_PAIN3

   (
    sprite: Ord(SPR_SKUL);
    frame: 9;
    tics: 5;
    action: (acp1: nil);
    nextstate: S_BSKUL_DIE2;
    misc1: 0;
    misc2: 0;
    flags_ex: 0;
   ),                          // S_BSKUL_DIE1

   (
    sprite: Ord(SPR_SKUL);
    frame: 10;
    tics: 5;
    action: (acp1: nil);
    nextstate: S_BSKUL_DIE3;
    misc1: 0;
    misc2: 0;
    flags_ex: 0;
   ),                          // S_BSKUL_DIE2

   (
    sprite: Ord(SPR_SKUL);
    frame: 11;
    tics: 5;
    action: (acp1: nil);
    nextstate: S_BSKUL_DIE4;
    misc1: 0;
    misc2: 0;
    flags_ex: 0;
   ),                          // S_BSKUL_DIE3

   (
    sprite: Ord(SPR_SKUL);
    frame: 12;
    tics: 5;
    action: (acp1: nil);
    nextstate: S_BSKUL_DIE5;
    misc1: 0;
    misc2: 0;
    flags_ex: 0;
   ),                          // S_BSKUL_DIE4

   (
    sprite: Ord(SPR_SKUL);
    frame: 13;
    tics: 5;
    action: (acp1: nil);
    nextstate: S_BSKUL_DIE6;
    misc1: 0;
    misc2: 0;
    flags_ex: 0;
   ),                          // S_BSKUL_DIE5

   (
    sprite: Ord(SPR_SKUL);
    frame: 14;
    tics: 5;
    action: (acp1: nil);
    nextstate: S_BSKUL_DIE7;
    misc1: 0;
    misc2: 0;
    flags_ex: 0;
   ),                          // S_BSKUL_DIE6

   (
    sprite: Ord(SPR_SKUL);
    frame: 15;
    tics: 5;
    action: (acp1: nil);
    nextstate: S_BSKUL_DIE8;
    misc1: 0;
    misc2: 0;
    flags_ex: 0;
   ),                          // S_BSKUL_DIE7

   (
    sprite: Ord(SPR_SKUL);
    frame: 16;
    tics: 5;
    action: (acp1: nil);
    nextstate: S_BSKUL_DIE8;
    misc1: 0;
    misc2: 0;
    flags_ex: 0;
   ),                          // S_BSKUL_DIE8

   (
    sprite: Ord(SPR_MISL);
    frame: 32769;
    tics: 8;
    action: (acp1: nil);
    nextstate: S_EXPLODE2;
    misc1: 0;
    misc2: 0;
    flags_ex: 0;
   )                           // S_MUSHROOM

  );

const // Doom Original Sprite Names
  DO_sprnames: array[0..Ord(DO_NUMSPRITES)] of string[4] = (
    'TROO', 'SHTG', 'PUNG', 'PISG', 'PISF', 'SHTF', 'SHT2', 'CHGG', 'CHGF', 'MISG',
    'MISF', 'SAWG', 'PLSG', 'PLSF', 'BFGG', 'BFGF', 'BLUD', 'PUFF', 'BAL1', 'BAL2',
    'PLSS', 'PLSE', 'MISL', 'BFS1', 'BFE1', 'BFE2', 'TFOG', 'IFOG', 'PLAY', 'POSS',
    'SPOS', 'VILE', 'FIRE', 'FATB', 'FBXP', 'SKEL', 'MANF', 'FATT', 'CPOS', 'SARG',
    'HEAD', 'BAL7', 'BOSS', 'BOS2', 'SKUL', 'SPID', 'BSPI', 'APLS', 'APBX', 'CYBR',
    'PAIN', 'SSWV', 'KEEN', 'BBRN', 'BOSF', 'ARM1', 'ARM2', 'BAR1', 'BEXP', 'FCAN',
    'BON1', 'BON2', 'BKEY', 'RKEY', 'YKEY', 'BSKU', 'RSKU', 'YSKU', 'STIM', 'MEDI',
    'SOUL', 'PINV', 'PSTR', 'PINS', 'MEGA', 'SUIT', 'PMAP', 'PVIS', 'CLIP', 'AMMO',
    'ROCK', 'BROK', 'CELL', 'CELP', 'SHEL', 'SBOX', 'BPAK', 'BFUG', 'MGUN', 'CSAW',
    'LAUN', 'PLAS', 'SHOT', 'SGN2', 'COLU', 'SMT2', 'GOR1', 'POL2', 'POL5', 'POL4',
    'POL3', 'POL1', 'POL6', 'GOR2', 'GOR3', 'GOR4', 'GOR5', 'SMIT', 'COL1', 'COL2',
    'COL3', 'COL4', 'CAND', 'CBRA', 'COL6', 'TRE1', 'TRE2', 'ELEC', 'CEYE', 'FSKU',
    'COL5', 'TBLU', 'TGRN', 'TRED', 'SMBT', 'SMGT', 'SMRT', 'HDB1', 'HDB2', 'HDB3',
    'HDB4', 'HDB5', 'HDB6', 'POB1', 'POB2', 'BRS1', 'TLMP', 'TLP2', 'TNT1', 'DOGS',

    'PLS1',
    'PLS2',
    'BON3',
    'BON4',
    // [BH] blood splats', [crispy] unused
    'BLD2',
    // [BH] 100 extra sprite names to use in dehacked patches
    'SP00', 'SP01', 'SP02', 'SP03', 'SP04', 'SP05', 'SP06', 'SP07', 'SP08', 'SP09',
    'SP10', 'SP11', 'SP12', 'SP13', 'SP14', 'SP15', 'SP16', 'SP17', 'SP18', 'SP19',
    'SP20', 'SP21', 'SP22', 'SP23', 'SP24', 'SP25', 'SP26', 'SP27', 'SP28', 'SP29',
    'SP30', 'SP31', 'SP32', 'SP33', 'SP34', 'SP35', 'SP36', 'SP37', 'SP38', 'SP39',
    'SP40', 'SP41', 'SP42', 'SP43', 'SP44', 'SP45', 'SP46', 'SP47', 'SP48', 'SP49',
    'SP50', 'SP51', 'SP52', 'SP53', 'SP54', 'SP55', 'SP56', 'SP57', 'SP58', 'SP59',
    'SP60', 'SP61', 'SP62', 'SP63', 'SP64', 'SP65', 'SP66', 'SP67', 'SP68', 'SP69',
    'SP70', 'SP71', 'SP72', 'SP73', 'SP74', 'SP75', 'SP76', 'SP77', 'SP78', 'SP79',
    'SP80', 'SP81', 'SP82', 'SP83', 'SP84', 'SP85', 'SP86', 'SP87', 'SP88', 'SP89',
    'SP90', 'SP91', 'SP92', 'SP93', 'SP94', 'SP95', 'SP96', 'SP97', 'SP98', 'SP99',
    'NULL', ''
  );

const // Doom Original mobjinfo
  DO_mobjinfo: array[0..Ord(DO_NUMMOBJTYPES) - 1] of mobjinfo_t = (
   (    // MT_PLAYER
    name: 'Player';                   // name
    inheritsfrom: -1;                 // inheritsfrom
    doomednum: -1;                    // doomednum
    spawnstate: Ord(S_PLAY);          // spawnstate
    spawnhealth: 100;                 // spawnhealth
    seestate: Ord(S_PLAY_RUN1);       // seestate
    seesound: Ord(sfx_None);          // seesound
    reactiontime: 0;                  // reactiontime
    attacksound: Ord(sfx_None);       // attacksound
    painstate: Ord(S_PLAY_PAIN);      // painstate
    painchance: 255;                  // painchance
    painsound: Ord(sfx_plpain);       // painsound
    meleestate: Ord(S_NULL);          // meleestate
    missilestate: Ord(S_PLAY_ATK1);   // missilestate
    deathstate: Ord(S_PLAY_DIE1);     // deathstate
    xdeathstate: Ord(S_PLAY_XDIE1);   // xdeathstate
    deathsound: Ord(sfx_pldeth);      // deathsound
    speed: 0;                         // speed
    radius: 16 * FRACUNIT;            // radius
    height: 56 * FRACUNIT;            // height
    mass: 100;                        // mass
    damage: 0;                        // damage
    activesound: Ord(sfx_None);       // activesound
    flags: MF_SOLID or MF_SHOOTABLE or MF_DROPOFF or MF_PICKUP or MF_NOTDMATCH;// flags
    flags_ex: 0;                      // flags_ex
    raisestate: Ord(S_NULL);          // raisestate
    customsound1: 0;                  // customsound1
    customsound2: 0;                  // customsound2
    customsound3: 0;                  // customsound3
    explosiondamage: 0;               // explosiondamage
    explosionradius: 0;               // explosionradius
    meleedamage: 0;                   // meleedamage
    scale: FRACUNIT;                  // scale
   ),
   (    // MT_POSSESSED
    name: 'Trooper';                  // name
    inheritsfrom: -1;                 // inheritsfrom
    doomednum: 3004;                  // doomednum
    spawnstate: Ord(S_POSS_STND);     // spawnstate
    spawnhealth: 20;                  // spawnhealth
    seestate: Ord(S_POSS_RUN1);       // seestate
    seesound: Ord(sfx_posit1);        // seesound
    reactiontime: 8;                  // reactiontime
    attacksound: Ord(sfx_pistol);     // attacksound
    painstate: Ord(S_POSS_PAIN);      // painstate
    painchance: 200;                  // painchance
    painsound: Ord(sfx_popain);       // painsound
    meleestate: Ord(0);               // meleestate
    missilestate: Ord(S_POSS_ATK1);   // missilestate
    deathstate: Ord(S_POSS_DIE1);     // deathstate
    xdeathstate: Ord(S_POSS_XDIE1);   // xdeathstate
    deathsound: Ord(sfx_podth1);      // deathsound
    speed: 8;                         // speed
    radius: 20 * FRACUNIT;            // radius
    height: 56 * FRACUNIT;            // height
    mass: 100;                        // mass
    damage: 0;                        // damage
    activesound: Ord(sfx_posact);     // activesound
    flags: MF_SOLID or MF_SHOOTABLE or MF_COUNTKILL;    // flags
    flags_ex: 0;                      // flags_ex
    raisestate: Ord(S_POSS_RAISE1);   // raisestate
    customsound1: 0;                  // customsound1
    customsound2: 0;                  // customsound2
    customsound3: 0;                  // customsound3
    explosiondamage: 0;               // explosiondamage
    explosionradius: 0;               // explosionradius
    meleedamage: 0;                   // meleedamage
    scale: FRACUNIT;                  // scale
   ),
   (    // MT_SHOTGUY
    name: 'Sargeant';                 // name
    inheritsfrom: -1;                 // inheritsfrom
    doomednum: 9;                     // doomednum
    spawnstate: Ord(S_SPOS_STND);     // spawnstate
    spawnhealth: 30;                  // spawnhealth
    seestate: Ord(S_SPOS_RUN1);       // seestate
    seesound: Ord(sfx_posit2);        // seesound
    reactiontime: 8;                  // reactiontime
    attacksound: Ord(0);              // attacksound
    painstate: Ord(S_SPOS_PAIN);      // painstate
    painchance: 170;                  // painchance
    painsound: Ord(sfx_popain);       // painsound
    meleestate: Ord(0);               // meleestate
    missilestate: Ord(S_SPOS_ATK1);   // missilestate
    deathstate: Ord(S_SPOS_DIE1);     // deathstate
    xdeathstate: Ord(S_SPOS_XDIE1);   // xdeathstate
    deathsound: Ord(sfx_podth2);      // deathsound
    speed: 8;                         // speed
    radius: 20 * FRACUNIT;            // radius
    height: 56 * FRACUNIT;            // height
    mass: 100;                        // mass
    damage: 0;                        // damage
    activesound: Ord(sfx_posact);     // activesound
    flags: MF_SOLID or MF_SHOOTABLE or MF_COUNTKILL;    // flags
    flags_ex: 0;                      // flags_ex
    raisestate: Ord(S_SPOS_RAISE1);   // raisestate
    customsound1: 0;                  // customsound1
    customsound2: 0;                  // customsound2
    customsound3: 0;                  // customsound3
    explosiondamage: 0;               // explosiondamage
    explosionradius: 0;               // explosionradius
    meleedamage: 0;                   // meleedamage
    scale: FRACUNIT;                  // scale
   ),
   (    // MT_VILE
    name: 'Archvile';                 // name
    inheritsfrom: -1;                 // inheritsfrom
    doomednum: 64;                    // doomednum
    spawnstate: Ord(S_VILE_STND);     // spawnstate
    spawnhealth: 700;                 // spawnhealth
    seestate: Ord(S_VILE_RUN1);       // seestate
    seesound: Ord(sfx_vilsit);        // seesound
    reactiontime: 8;                  // reactiontime
    attacksound: Ord(0);              // attacksound
    painstate: Ord(S_VILE_PAIN);      // painstate
    painchance: 10;                   // painchance
    painsound: Ord(sfx_vipain);       // painsound
    meleestate: Ord(0);               // meleestate
    missilestate: Ord(S_VILE_ATK1);   // missilestate
    deathstate: Ord(S_VILE_DIE1);     // deathstate
    xdeathstate: Ord(S_NULL);         // xdeathstate
    deathsound: Ord(sfx_vildth);      // deathsound
    speed: 15;                        // speed
    radius: 20 * FRACUNIT;            // radius
    height: 56 * FRACUNIT;            // height
    mass: 500;                        // mass
    damage: 0;                        // damage
    activesound: Ord(sfx_vilact);     // activesound
    flags: MF_SOLID or MF_SHOOTABLE or MF_COUNTKILL;    // flags
    flags_ex: 0;                      // flags_ex
    raisestate: Ord(S_NULL);          // raisestate
    customsound1: 0;                  // customsound1
    customsound2: 0;                  // customsound2
    customsound3: 0;                  // customsound3
    explosiondamage: 0;               // explosiondamage
    explosionradius: 0;               // explosionradius
    meleedamage: 0;                   // meleedamage
    healstate: Ord(S_VILE_HEAL1);     // healstate
    scale: FRACUNIT;                  // scale
   ),
   (    // MT_FIRE
    name: 'Archvile Attack';          // name
    inheritsfrom: -1;                 // inheritsfrom
    doomednum: -1;                    // doomednum
    spawnstate: Ord(S_FIRE1);         // spawnstate
    spawnhealth: 1000;                // spawnhealth
    seestate: Ord(S_NULL);            // seestate
    seesound: Ord(sfx_None);          // seesound
    reactiontime: 8;                  // reactiontime
    attacksound: Ord(sfx_None);       // attacksound
    painstate: Ord(S_NULL);           // painstate
    painchance: 0;                    // painchance
    painsound: Ord(sfx_None);         // painsound
    meleestate: Ord(S_NULL);          // meleestate
    missilestate: Ord(S_NULL);        // missilestate
    deathstate: Ord(S_NULL);          // deathstate
    xdeathstate: Ord(S_NULL);         // xdeathstate
    deathsound: Ord(sfx_None);        // deathsound
    speed: 0;                         // speed
    radius: 20 * FRACUNIT;            // radius
    height: 16 * FRACUNIT;            // height
    mass: 100;                        // mass
    damage: 0;                        // damage
    activesound: Ord(sfx_None);       // activesound
    flags: MF_NOBLOCKMAP or MF_NOGRAVITY;    // flags
    flags_ex: MF_EX_TRANSPARENT or MF_EX_WHITELIGHT; // flags_ex
    raisestate: Ord(S_NULL);          // raisestate
    customsound1: 0;                  // customsound1
    customsound2: 0;                  // customsound2
    customsound3: 0;                  // customsound3
    explosiondamage: 0;               // explosiondamage
    explosionradius: 0;               // explosionradius
    meleedamage: 0;                   // meleedamage
    scale: FRACUNIT;                  // scale
   ),
   (    // MT_UNDEAD
    name: 'Revenant';                 // name
    inheritsfrom: -1;                 // inheritsfrom
    doomednum: 66;                    // doomednum
    spawnstate: Ord(S_SKEL_STND);     // spawnstate
    spawnhealth: 300;                 // spawnhealth
    seestate: Ord(S_SKEL_RUN1);       // seestate
    seesound: Ord(sfx_skesit);        // seesound
    reactiontime: 8;                  // reactiontime
    attacksound: Ord(0);              // attacksound
    painstate: Ord(S_SKEL_PAIN);      // painstate
    painchance: 100;                  // painchance
    painsound: Ord(sfx_popain);       // painsound
    meleestate: Ord(S_SKEL_FIST1);    // meleestate
    missilestate: Ord(S_SKEL_MISS1);  // missilestate
    deathstate: Ord(S_SKEL_DIE1);     // deathstate
    xdeathstate: Ord(S_NULL);         // xdeathstate
    deathsound: Ord(sfx_skedth);      // deathsound
    speed: 10;                        // speed
    radius: 20 * FRACUNIT;            // radius
    height: 56 * FRACUNIT;            // height
    mass: 500;                        // mass
    damage: 0;                        // damage
    activesound: Ord(sfx_skeact);     // activesound
    flags: MF_SOLID or MF_SHOOTABLE or MF_COUNTKILL;    // flags
    flags_ex: 0;                      // flags_ex
    raisestate: Ord(S_SKEL_RAISE1);   // raisestate
    customsound1: 0;                  // customsound1
    customsound2: 0;                  // customsound2
    customsound3: 0;                  // customsound3
    explosiondamage: 0;               // explosiondamage
    explosionradius: 0;               // explosionradius
    meleedamage: 0;                   // meleedamage
    scale: FRACUNIT;                  // scale
   ),
   (    // MT_TRACER
    name: 'Revenant Fireball';        // name
    inheritsfrom: -1;                 // inheritsfrom
    doomednum: -1;                    // doomednum
    spawnstate: Ord(S_TRACER);        // spawnstate
    spawnhealth: 1000;                // spawnhealth
    seestate: Ord(S_NULL);            // seestate
    seesound: Ord(sfx_skeatk);        // seesound
    reactiontime: 8;                  // reactiontime
    attacksound: Ord(sfx_None);       // attacksound
    painstate: Ord(S_NULL);           // painstate
    painchance: 0;                    // painchance
    painsound: Ord(sfx_None);         // painsound
    meleestate: Ord(S_NULL);          // meleestate
    missilestate: Ord(S_NULL);        // missilestate
    deathstate: Ord(S_TRACEEXP1);     // deathstate
    xdeathstate: Ord(S_NULL);         // xdeathstate
    deathsound: Ord(sfx_barexp);      // deathsound
    speed: 10 * FRACUNIT;             // speed
    radius: 11 * FRACUNIT;            // radius
    height: 8 * FRACUNIT;             // height
    mass: 100;                        // mass
    damage: 10;                       // damage
    activesound: Ord(sfx_None);       // activesound
    flags: MF_NOBLOCKMAP or MF_MISSILE or MF_DROPOFF or MF_NOGRAVITY;    // flags
    flags_ex: 0;                      // flags_ex
    raisestate: Ord(S_NULL);          // raisestate
    customsound1: 0;                  // customsound1
    customsound2: 0;                  // customsound2
    customsound3: 0;                  // customsound3
    explosiondamage: 0;               // explosiondamage
    explosionradius: 0;               // explosionradius
    meleedamage: 0;                   // meleedamage
    scale: FRACUNIT;                  // scale
   ),
   (    // MT_SMOKE
    name: 'Fireball Trail';           // name
    inheritsfrom: -1;                 // inheritsfrom
    doomednum: -1;                    // doomednum
    spawnstate: Ord(S_SMOKE1);        // spawnstate
    spawnhealth: 1000;                // spawnhealth
    seestate: Ord(S_NULL);            // seestate
    seesound: Ord(sfx_None);          // seesound
    reactiontime: 8;                  // reactiontime
    attacksound: Ord(sfx_None);       // attacksound
    painstate: Ord(S_NULL);           // painstate
    painchance: 0;                    // painchance
    painsound: Ord(sfx_None);         // painsound
    meleestate: Ord(S_NULL);          // meleestate
    missilestate: Ord(S_NULL);        // missilestate
    deathstate: Ord(S_NULL);          // deathstate
    xdeathstate: Ord(S_NULL);         // xdeathstate
    deathsound: Ord(sfx_None);        // deathsound
    speed: 0;                         // speed
    radius: 20 * FRACUNIT;            // radius
    height: 16 * FRACUNIT;            // height
    mass: 100;                        // mass
    damage: 0;                        // damage
    activesound: Ord(sfx_None);       // activesound
    flags: MF_NOBLOCKMAP or MF_NOGRAVITY;    // flags
    flags_ex: MF_EX_TRANSPARENT or MF_EX_WHITELIGHT; // flags_ex
    raisestate: Ord(S_NULL);          // raisestate
    customsound1: 0;                  // customsound1
    customsound2: 0;                  // customsound2
    customsound3: 0;                  // customsound3
    explosiondamage: 0;               // explosiondamage
    explosionradius: 0;               // explosionradius
    meleedamage: 0;                   // meleedamage
    scale: FRACUNIT;                  // scale
   ),
   (    // MT_FATSO
    name: 'Mancubus';                 // name
    inheritsfrom: -1;                 // inheritsfrom
    doomednum: 67;                    // doomednum
    spawnstate: Ord(S_FATT_STND);     // spawnstate
    spawnhealth: 600;                 // spawnhealth
    seestate: Ord(S_FATT_RUN1);       // seestate
    seesound: Ord(sfx_mansit);        // seesound
    reactiontime: 8;                  // reactiontime
    attacksound: Ord(0);              // attacksound
    painstate: Ord(S_FATT_PAIN);      // painstate
    painchance: 80;                   // painchance
    painsound: Ord(sfx_mnpain);       // painsound
    meleestate: Ord(S_NULL);          // meleestate
    missilestate: Ord(S_FATT_ATK1);    // missilestate
    deathstate: Ord(S_FATT_DIE1);     // deathstate
    xdeathstate: Ord(S_NULL);         // xdeathstate
    deathsound: Ord(sfx_mandth);      // deathsound
    speed: 8;                         // speed
    radius: 48 * FRACUNIT;            // radius
    height: 64 * FRACUNIT;            // height
    mass: 1000;                       // mass
    damage: 0;                        // damage
    activesound: Ord(sfx_posact);     // activesound
    flags: MF_SOLID or MF_SHOOTABLE or MF_COUNTKILL;    // flags
    flags_ex: 0;                      // flags_ex
    raisestate: Ord(S_FATT_RAISE1);   // raisestate
    customsound1: 0;                  // customsound1
    customsound2: 0;                  // customsound2
    customsound3: 0;                  // customsound3
    explosiondamage: 0;               // explosiondamage
    explosionradius: 0;               // explosionradius
    meleedamage: 0;                   // meleedamage
    scale: FRACUNIT;                  // scale
   ),
   (    // MT_FATSHOT
    name: 'Mancubus Fireball';        // name
    inheritsfrom: -1;                 // inheritsfrom
    doomednum: -1;                    // doomednum
    spawnstate: Ord(S_FATSHOT1);      // spawnstate
    spawnhealth: 1000;                // spawnhealth
    seestate: Ord(S_NULL);            // seestate
    seesound: Ord(sfx_firsht);        // seesound
    reactiontime: 8;                  // reactiontime
    attacksound: Ord(sfx_None);       // attacksound
    painstate: Ord(S_NULL);           // painstate
    painchance: 0;                    // painchance
    painsound: Ord(sfx_None);         // painsound
    meleestate: Ord(S_NULL);          // meleestate
    missilestate: Ord(S_NULL);        // missilestate
    deathstate: Ord(S_FATSHOTX1);     // deathstate
    xdeathstate: Ord(S_NULL);         // xdeathstate
    deathsound: Ord(sfx_firxpl);      // deathsound
    speed: 20 * FRACUNIT;             // speed
    radius: 6 * FRACUNIT;             // radius
    height: 8 * FRACUNIT;             // height
    mass: 100;                        // mass
    damage: 8;                        // damage
    activesound: Ord(sfx_None);       // activesound
    flags: MF_NOBLOCKMAP or MF_MISSILE or MF_DROPOFF or MF_NOGRAVITY;    // flags
    flags_ex: MF_EX_TRANSPARENT or MF_EX_WHITELIGHT; // flags_ex
    raisestate: Ord(S_NULL);          // raisestate
    customsound1: 0;                  // customsound1
    customsound2: 0;                  // customsound2
    customsound3: 0;                  // customsound3
    explosiondamage: 0;               // explosiondamage
    explosionradius: 0;               // explosionradius
    meleedamage: 0;                   // meleedamage
    scale: FRACUNIT;                  // scale
   ),
   (    // MT_CHAINGUY
    name: 'Chaingun Sargeant';        // name
    inheritsfrom: -1;                 // inheritsfrom
    doomednum: 65;                    // doomednum
    spawnstate: Ord(S_CPOS_STND);     // spawnstate
    spawnhealth: 70;                  // spawnhealth
    seestate: Ord(S_CPOS_RUN1);       // seestate
    seesound: Ord(sfx_posit2);        // seesound
    reactiontime: 8;                  // reactiontime
    attacksound: Ord(0);              // attacksound
    painstate: Ord(S_CPOS_PAIN);      // painstate
    painchance: 170;                  // painchance
    painsound: Ord(sfx_popain);       // painsound
    meleestate: Ord(0);               // meleestate
    missilestate: Ord(S_CPOS_ATK1);    // missilestate
    deathstate: Ord(S_CPOS_DIE1);     // deathstate
    xdeathstate: Ord(S_CPOS_XDIE1);    // xdeathstate
    deathsound: Ord(sfx_podth2);      // deathsound
    speed: 8;                         // speed
    radius: 20 * FRACUNIT;            // radius
    height: 56 * FRACUNIT;            // height
    mass: 100;                        // mass
    damage: 0;                        // damage
    activesound: Ord(sfx_posact);     // activesound
    flags: MF_SOLID or MF_SHOOTABLE or MF_COUNTKILL;    // flags
    flags_ex: 0;                      // flags_ex
    raisestate: Ord(S_CPOS_RAISE1);   // raisestate
    customsound1: 0;                  // customsound1
    customsound2: 0;                  // customsound2
    customsound3: 0;                  // customsound3
    explosiondamage: 0;               // explosiondamage
    explosionradius: 0;               // explosionradius
    meleedamage: 0;                   // meleedamage
    scale: FRACUNIT;                  // scale
   ),
   (    // MT_TROOP
    name: 'Imp';                      // name
    inheritsfrom: -1;                 // inheritsfrom
    doomednum: 3001;                  // doomednum
    spawnstate: Ord(S_TROO_STND);     // spawnstate
    spawnhealth: 60;                  // spawnhealth
    seestate: Ord(S_TROO_RUN1);       // seestate
    seesound: Ord(sfx_bgsit1);        // seesound
    reactiontime: 8;                  // reactiontime
    attacksound: Ord(0);              // attacksound
    painstate: Ord(S_TROO_PAIN);      // painstate
    painchance: 200;                  // painchance
    painsound: Ord(sfx_popain);       // painsound
    meleestate: Ord(S_TROO_ATK1);     // meleestate
    missilestate: Ord(S_TROO_ATK1);   // missilestate
    deathstate: Ord(S_TROO_DIE1);     // deathstate
    xdeathstate: Ord(S_TROO_XDIE1);   // xdeathstate
    deathsound: Ord(sfx_bgdth1);      // deathsound
    speed: 8;                         // speed
    radius: 20 * FRACUNIT;            // radius
    height: 56 * FRACUNIT;            // height
    mass: 100;                        // mass
    damage: 0;                        // damage
    activesound: Ord(sfx_bgact);      // activesound
    flags: MF_SOLID or MF_SHOOTABLE or MF_COUNTKILL;    // flags
    flags_ex: 0;                      // flags_ex
    raisestate: Ord(S_TROO_RAISE1);   // raisestate
    customsound1: 0;                  // customsound1
    customsound2: 0;                  // customsound2
    customsound3: 0;                  // customsound3
    explosiondamage: 0;               // explosiondamage
    explosionradius: 0;               // explosionradius
    meleedamage: 0;                   // meleedamage
    scale: FRACUNIT;                  // scale
   ),
   (    // MT_SERGEANT
    name: 'Demon';                    // name
    inheritsfrom: -1;                 // inheritsfrom
    doomednum: 3002;                  // doomednum
    spawnstate: Ord(S_SARG_STND);     // spawnstate
    spawnhealth: 150;                 // spawnhealth
    seestate: Ord(S_SARG_RUN1);       // seestate
    seesound: Ord(sfx_sgtsit);        // seesound
    reactiontime: 8;                  // reactiontime
    attacksound: Ord(sfx_sgtatk);     // attacksound
    painstate: Ord(S_SARG_PAIN);      // painstate
    painchance: 180;                  // painchance
    painsound: Ord(sfx_dmpain);       // painsound
    meleestate: Ord(S_SARG_ATK1);     // meleestate
    missilestate: Ord(0);             // missilestate
    deathstate: Ord(S_SARG_DIE1);     // deathstate
    xdeathstate: Ord(S_NULL);         // xdeathstate
    deathsound: Ord(sfx_sgtdth);      // deathsound
    speed: 10;                        // speed
    radius: 30 * FRACUNIT;            // radius
    height: 56 * FRACUNIT;            // height
    mass: 400;                        // mass
    damage: 0;                        // damage
    activesound: Ord(sfx_dmact);      // activesound
    flags: MF_SOLID or MF_SHOOTABLE or MF_COUNTKILL;    // flags
    flags_ex: 0;                      // flags_ex
    raisestate: Ord(S_SARG_RAISE1);   // raisestate
    customsound1: 0;                  // customsound1
    customsound2: 0;                  // customsound2
    customsound3: 0;                  // customsound3
    explosiondamage: 0;               // explosiondamage
    explosionradius: 0;               // explosionradius
    meleedamage: 0;                   // meleedamage
    scale: FRACUNIT;                  // scale
   ),
   (    // MT_SHADOWS
    name: 'Spectre';                  // name
    inheritsfrom: -1;                 // inheritsfrom
    doomednum: 58;                    // doomednum
    spawnstate: Ord(S_SARG_STND);     // spawnstate
    spawnhealth: 150;                 // spawnhealth
    seestate: Ord(S_SARG_RUN1);       // seestate
    seesound: Ord(sfx_sgtsit);        // seesound
    reactiontime: 8;                  // reactiontime
    attacksound: Ord(sfx_sgtatk);     // attacksound
    painstate: Ord(S_SARG_PAIN);      // painstate
    painchance: 180;                  // painchance
    painsound: Ord(sfx_dmpain);       // painsound
    meleestate: Ord(S_SARG_ATK1);     // meleestate
    missilestate: Ord(0);             // missilestate
    deathstate: Ord(S_SARG_DIE1);     // deathstate
    xdeathstate: Ord(S_NULL);         // xdeathstate
    deathsound: Ord(sfx_sgtdth);      // deathsound
    speed: 10;                        // speed
    radius: 30 * FRACUNIT;            // radius
    height: 56 * FRACUNIT;            // height
    mass: 400;                        // mass
    damage: 0;                        // damage
    activesound: Ord(sfx_dmact);      // activesound
    flags: MF_SOLID or MF_SHOOTABLE or MF_SHADOW or MF_COUNTKILL;    // flags
    flags_ex: 0;                      // flags_ex
    raisestate: Ord(S_SARG_RAISE1);   // raisestate
    customsound1: 0;                  // customsound1
    customsound2: 0;                  // customsound2
    customsound3: 0;                  // customsound3
    explosiondamage: 0;               // explosiondamage
    explosionradius: 0;               // explosionradius
    meleedamage: 0;                   // meleedamage
    scale: FRACUNIT;                  // scale
   ),
   (    // MT_HEAD
    name: 'Cacodemon';                // name
    inheritsfrom: -1;                 // inheritsfrom
    doomednum: 3005;                  // doomednum
    spawnstate: Ord(S_HEAD_STND);     // spawnstate
    spawnhealth: 400;                 // spawnhealth
    seestate: Ord(S_HEAD_RUN1);       // seestate
    seesound: Ord(sfx_cacsit);        // seesound
    reactiontime: 8;                  // reactiontime
    attacksound: Ord(0);              // attacksound
    painstate: Ord(S_HEAD_PAIN);      // painstate
    painchance: 128;                  // painchance
    painsound: Ord(sfx_dmpain);       // painsound
    meleestate: Ord(0);               // meleestate
    missilestate: Ord(S_HEAD_ATK1);    // missilestate
    deathstate: Ord(S_HEAD_DIE1);     // deathstate
    xdeathstate: Ord(S_NULL);         // xdeathstate
    deathsound: Ord(sfx_cacdth);      // deathsound
    speed: 8;                         // speed
    radius: 31 * FRACUNIT;            // radius
    height: 56 * FRACUNIT;            // height
    mass: 400;                        // mass
    damage: 0;                        // damage
    activesound: Ord(sfx_dmact);      // activesound
    flags: MF_SOLID or MF_SHOOTABLE or MF_FLOAT or MF_NOGRAVITY or MF_COUNTKILL;    // flags
    flags_ex: 0;                      // flags_ex
    raisestate: Ord(S_HEAD_RAISE1);   // raisestate
    customsound1: 0;                  // customsound1
    customsound2: 0;                  // customsound2
    customsound3: 0;                  // customsound3
    explosiondamage: 0;               // explosiondamage
    explosionradius: 0;               // explosionradius
    meleedamage: 0;                   // meleedamage
    scale: FRACUNIT;                  // scale
   ),
   (    // MT_BRUISER
    name: 'Baron of Hell';            // name
    inheritsfrom: -1;                 // inheritsfrom
    doomednum: 3003;                  // doomednum
    spawnstate: Ord(S_BOSS_STND);     // spawnstate
    spawnhealth: 1000;                // spawnhealth
    seestate: Ord(S_BOSS_RUN1);       // seestate
    seesound: Ord(sfx_brssit);        // seesound
    reactiontime: 8;                  // reactiontime
    attacksound: Ord(0);              // attacksound
    painstate: Ord(S_BOSS_PAIN);      // painstate
    painchance: 50;                   // painchance
    painsound: Ord(sfx_dmpain);       // painsound
    meleestate: Ord(S_BOSS_ATK1);     // meleestate
    missilestate: Ord(S_BOSS_ATK1);    // missilestate
    deathstate: Ord(S_BOSS_DIE1);     // deathstate
    xdeathstate: Ord(S_NULL);         // xdeathstate
    deathsound: Ord(sfx_brsdth);      // deathsound
    speed: 8;                         // speed
    radius: 24 * FRACUNIT;            // radius
    height: 64 * FRACUNIT;            // height
    mass: 1000;                       // mass
    damage: 0;                        // damage
    activesound: Ord(sfx_dmact);      // activesound
    flags: MF_SOLID or MF_SHOOTABLE or MF_COUNTKILL;    // flags
    flags_ex: 0;                      // flags_ex
    raisestate: Ord(S_BOSS_RAISE1);   // raisestate
    customsound1: 0;                  // customsound1
    customsound2: 0;                  // customsound2
    customsound3: 0;                  // customsound3
    explosiondamage: 0;               // explosiondamage
    explosionradius: 0;               // explosionradius
    meleedamage: 0;                   // meleedamage
    scale: FRACUNIT;                  // scale
   ),
   (    // MT_BRUISERSHOT
    name: 'Baron Fireball';           // name
    inheritsfrom: -1;                 // inheritsfrom
    doomednum: -1;                    // doomednum
    spawnstate: Ord(S_BRBALL1);       // spawnstate
    spawnhealth: 1000;                // spawnhealth
    seestate: Ord(S_NULL);            // seestate
    seesound: Ord(sfx_firsht);        // seesound
    reactiontime: 8;                  // reactiontime
    attacksound: Ord(sfx_None);       // attacksound
    painstate: Ord(S_NULL);           // painstate
    painchance: 0;                    // painchance
    painsound: Ord(sfx_None);         // painsound
    meleestate: Ord(S_NULL);          // meleestate
    missilestate: Ord(S_NULL);        // missilestate
    deathstate: Ord(S_BRBALLX1);      // deathstate
    xdeathstate: Ord(S_NULL);         // xdeathstate
    deathsound: Ord(sfx_firxpl);      // deathsound
    speed: 15 * FRACUNIT;             // speed
    radius: 6 * FRACUNIT;             // radius
    height: 8 * FRACUNIT;             // height
    mass: 100;                        // mass
    damage: 8;                        // damage
    activesound: Ord(sfx_None);       // activesound
    flags: MF_NOBLOCKMAP or MF_MISSILE or MF_DROPOFF or MF_NOGRAVITY;    // flags
    flags_ex: MF_EX_TRANSPARENT or MF_EX_WHITELIGHT; // flags_ex
    raisestate: Ord(S_NULL);          // raisestate
    customsound1: 0;                  // customsound1
    customsound2: 0;                  // customsound2
    customsound3: 0;                  // customsound3
    explosiondamage: 0;               // explosiondamage
    explosionradius: 0;               // explosionradius
    meleedamage: 0;                   // meleedamage
    scale: FRACUNIT;                  // scale
   ),
   (    // MT_KNIGHT
    name: 'Hell Knight';              // name
    inheritsfrom: -1;                 // inheritsfrom
    doomednum: 69;                    // doomednum
    spawnstate: Ord(S_BOS2_STND);     // spawnstate
    spawnhealth: 500;                 // spawnhealth
    seestate: Ord(S_BOS2_RUN1);       // seestate
    seesound: Ord(sfx_kntsit);        // seesound
    reactiontime: 8;                  // reactiontime
    attacksound: Ord(0);              // attacksound
    painstate: Ord(S_BOS2_PAIN);      // painstate
    painchance: 50;                   // painchance
    painsound: Ord(sfx_dmpain);       // painsound
    meleestate: Ord(S_BOS2_ATK1);     // meleestate
    missilestate: Ord(S_BOS2_ATK1);    // missilestate
    deathstate: Ord(S_BOS2_DIE1);     // deathstate
    xdeathstate: Ord(S_NULL);         // xdeathstate
    deathsound: Ord(sfx_kntdth);      // deathsound
    speed: 8;                         // speed
    radius: 24 * FRACUNIT;            // radius
    height: 64 * FRACUNIT;            // height
    mass: 1000;                       // mass
    damage: 0;                        // damage
    activesound: Ord(sfx_dmact);      // activesound
    flags: MF_SOLID or MF_SHOOTABLE or MF_COUNTKILL;    // flags
    flags_ex: 0;                      // flags_ex
    raisestate: Ord(S_BOS2_RAISE1);   // raisestate
    customsound1: 0;                  // customsound1
    customsound2: 0;                  // customsound2
    customsound3: 0;                  // customsound3
    explosiondamage: 0;               // explosiondamage
    explosionradius: 0;               // explosionradius
    meleedamage: 0;                   // meleedamage
    scale: FRACUNIT;                  // scale
   ),
   (    // MT_SKULL
    name: 'Lost Soul';                // name
    inheritsfrom: -1;                 // inheritsfrom
    doomednum: 3006;                  // doomednum
    spawnstate: Ord(S_SKULL_STND);    // spawnstate
    spawnhealth: 100;                 // spawnhealth
    seestate: Ord(S_SKULL_RUN1);      // seestate
    seesound: Ord(0);                 // seesound
    reactiontime: 8;                  // reactiontime
    attacksound: Ord(sfx_sklatk);     // attacksound
    painstate: Ord(S_SKULL_PAIN);     // painstate
    painchance: 256;                  // painchance
    painsound: Ord(sfx_dmpain);       // painsound
    meleestate: Ord(0);               // meleestate
    missilestate: Ord(S_SKULL_ATK1);  // missilestate
    deathstate: Ord(S_SKULL_DIE1);    // deathstate
    xdeathstate: Ord(S_NULL);         // xdeathstate
    deathsound: Ord(sfx_firxpl);      // deathsound
    speed: 8;                         // speed
    radius: 16 * FRACUNIT;            // radius
    height: 56 * FRACUNIT;            // height
    mass: 50;                         // mass
    damage: 3;                        // damage
    activesound: Ord(sfx_dmact);      // activesound
    flags: MF_SOLID or MF_SHOOTABLE or MF_FLOAT or MF_NOGRAVITY;    // flags
    flags_ex: MF_EX_WHITELIGHT;       // flags_ex
    raisestate: Ord(S_NULL);          // raisestate
    customsound1: 0;                  // customsound1
    customsound2: 0;                  // customsound2
    customsound3: 0;                  // customsound3
    explosiondamage: 0;               // explosiondamage
    explosionradius: 0;               // explosionradius
    meleedamage: 0;                   // meleedamage
    scale: FRACUNIT;                  // scale
   ),
   (    // MT_SPIDER
    name: 'Spiderdemon';              // name
    inheritsfrom: -1;                 // inheritsfrom
    doomednum: 7;                     // doomednum
    spawnstate: Ord(S_SPID_STND);     // spawnstate
    spawnhealth: 3000;                // spawnhealth
    seestate: Ord(S_SPID_RUN1);       // seestate
    seesound: Ord(sfx_spisit);        // seesound
    reactiontime: 8;                  // reactiontime
    attacksound: Ord(sfx_shotgn);     // attacksound
    painstate: Ord(S_SPID_PAIN);      // painstate
    painchance: 40;                   // painchance
    painsound: Ord(sfx_dmpain);       // painsound
    meleestate: Ord(0);               // meleestate
    missilestate: Ord(S_SPID_ATK1);   // missilestate
    deathstate: Ord(S_SPID_DIE1);     // deathstate
    xdeathstate: Ord(S_NULL);         // xdeathstate
    deathsound: Ord(sfx_spidth);      // deathsound
    speed: 12;                        // speed
    radius: 128 * FRACUNIT;           // radius
    height: 100 * FRACUNIT;           // height
    mass: 1000;                       // mass
    damage: 0;                        // damage
    activesound: Ord(sfx_dmact);      // activesound
    flags: MF_SOLID or MF_SHOOTABLE or MF_COUNTKILL;    // flags
    flags_ex: 0;                      // flags_ex
    raisestate: Ord(S_NULL);          // raisestate
    customsound1: 0;                  // customsound1
    customsound2: 0;                  // customsound2
    customsound3: 0;                  // customsound3
    explosiondamage: 0;               // explosiondamage
    explosionradius: 0;               // explosionradius
    meleedamage: 0;                   // meleedamage
    scale: FRACUNIT;                  // scale
   ),
   (    // MT_BABY
    name: 'Arachnotron';              // name
    inheritsfrom: -1;                 // inheritsfrom
    doomednum: 68;                    // doomednum
    spawnstate: Ord(S_BSPI_STND);     // spawnstate
    spawnhealth: 500;                 // spawnhealth
    seestate: Ord(S_BSPI_SIGHT);      // seestate
    seesound: Ord(sfx_bspsit);        // seesound
    reactiontime: 8;                  // reactiontime
    attacksound: Ord(0);              // attacksound
    painstate: Ord(S_BSPI_PAIN);      // painstate
    painchance: 128;                  // painchance
    painsound: Ord(sfx_dmpain);       // painsound
    meleestate: Ord(0);               // meleestate
    missilestate: Ord(S_BSPI_ATK1);   // missilestate
    deathstate: Ord(S_BSPI_DIE1);     // deathstate
    xdeathstate: Ord(S_NULL);         // xdeathstate
    deathsound: Ord(sfx_bspdth);      // deathsound
    speed: 12;                        // speed
    radius: 64 * FRACUNIT;            // radius
    height: 64 * FRACUNIT;            // height
    mass: 600;                        // mass
    damage: 0;                        // damage
    activesound: Ord(sfx_bspact);     // activesound
    flags: MF_SOLID or MF_SHOOTABLE or MF_COUNTKILL;    // flags
    flags_ex: 0;                      // flags_ex
    raisestate: Ord(S_BSPI_RAISE1);   // raisestate
    customsound1: 0;                  // customsound1
    customsound2: 0;                  // customsound2
    customsound3: 0;                  // customsound3
    explosiondamage: 0;               // explosiondamage
    explosionradius: 0;               // explosionradius
    meleedamage: 0;                   // meleedamage
    scale: FRACUNIT;                  // scale
   ),
   (    // MT_CYBORG
    name: 'Cyberdemon';               // name
    inheritsfrom: -1;                 // inheritsfrom
    doomednum: 16;                    // doomednum
    spawnstate: Ord(S_CYBER_STND);    // spawnstate
    spawnhealth: 4000;                // spawnhealth
    seestate: Ord(S_CYBER_RUN1);      // seestate
    seesound: Ord(sfx_cybsit);        // seesound
    reactiontime: 8;                  // reactiontime
    attacksound: Ord(0);              // attacksound
    painstate: Ord(S_CYBER_PAIN);     // painstate
    painchance: 20;                   // painchance
    painsound: Ord(sfx_dmpain);       // painsound
    meleestate: Ord(0);               // meleestate
    missilestate: Ord(S_CYBER_ATK1);   // missilestate
    deathstate: Ord(S_CYBER_DIE1);    // deathstate
    xdeathstate: Ord(S_NULL);         // xdeathstate
    deathsound: Ord(sfx_cybdth);      // deathsound
    speed: 16;                        // speed
    radius: 40 * FRACUNIT;            // radius
    height: 110 * FRACUNIT;           // height
    mass: 1000;                       // mass
    damage: 0;                        // damage
    activesound: Ord(sfx_dmact);      // activesound
    flags: MF_SOLID or MF_SHOOTABLE or MF_COUNTKILL;    // flags
    flags_ex: 0;                      // flags_ex
    raisestate: Ord(S_NULL);          // raisestate
    customsound1: 0;                  // customsound1
    customsound2: 0;                  // customsound2
    customsound3: 0;                  // customsound3
    explosiondamage: 0;               // explosiondamage
    explosionradius: 0;               // explosionradius
    meleedamage: 0;                   // meleedamage
    scale: FRACUNIT;                  // scale
   ),
   (    // MT_PAIN
    name: 'Pain Elemental';           // name
    inheritsfrom: -1;                 // inheritsfrom
    doomednum: 71;                    // doomednum
    spawnstate: Ord(S_PAIN_STND);     // spawnstate
    spawnhealth: 400;                 // spawnhealth
    seestate: Ord(S_PAIN_RUN1);       // seestate
    seesound: Ord(sfx_pesit);         // seesound
    reactiontime: 8;                  // reactiontime
    attacksound: Ord(0);              // attacksound
    painstate: Ord(S_PAIN_PAIN);      // painstate
    painchance: 128;                  // painchance
    painsound: Ord(sfx_pepain);       // painsound
    meleestate: Ord(0);               // meleestate
    missilestate: Ord(S_PAIN_ATK1);   // missilestate
    deathstate: Ord(S_PAIN_DIE1);     // deathstate
    xdeathstate: Ord(S_NULL);         // xdeathstate
    deathsound: Ord(sfx_pedth);       // deathsound
    speed: 8;                         // speed
    radius: 31 * FRACUNIT;            // radius
    height: 56 * FRACUNIT;            // height
    mass: 400;                        // mass
    damage: 0;                        // damage
    activesound: Ord(sfx_dmact);      // activesound
    flags: MF_SOLID or MF_SHOOTABLE or MF_FLOAT or MF_NOGRAVITY or MF_COUNTKILL;    // flags
    flags_ex: 0;                      // flags_ex
    raisestate: Ord(S_PAIN_RAISE1);   // raisestate
    customsound1: 0;                  // customsound1
    customsound2: 0;                  // customsound2
    customsound3: 0;                  // customsound3
    explosiondamage: 0;               // explosiondamage
    explosionradius: 0;               // explosionradius
    meleedamage: 0;                   // meleedamage
    scale: FRACUNIT;                  // scale
   ),
   (    // MT_WOLFSS
    name: 'SS Nazi';                  // name
    inheritsfrom: -1;                 // inheritsfrom
    doomednum: 84;                    // doomednum
    spawnstate: Ord(S_SSWV_STND);     // spawnstate
    spawnhealth: 50;                  // spawnhealth
    seestate: Ord(S_SSWV_RUN1);       // seestate
    seesound: Ord(sfx_sssit);         // seesound
    reactiontime: 8;                  // reactiontime
    attacksound: Ord(0);              // attacksound
    painstate: Ord(S_SSWV_PAIN);      // painstate
    painchance: 170;                  // painchance
    painsound: Ord(sfx_popain);       // painsound
    meleestate: Ord(0);               // meleestate
    missilestate: Ord(S_SSWV_ATK1);   // missilestate
    deathstate: Ord(S_SSWV_DIE1);     // deathstate
    xdeathstate: Ord(S_SSWV_XDIE1);   // xdeathstate
    deathsound: Ord(sfx_ssdth);       // deathsound
    speed: 8;                         // speed
    radius: 20 * FRACUNIT;            // radius
    height: 56 * FRACUNIT;            // height
    mass: 100;                        // mass
    damage: 0;                        // damage
    activesound: Ord(sfx_posact);     // activesound
    flags: MF_SOLID or MF_SHOOTABLE or MF_COUNTKILL;    // flags
    flags_ex: 0;                      // flags_ex
    raisestate: Ord(S_SSWV_RAISE1);   // raisestate
    customsound1: 0;                  // customsound1
    customsound2: 0;                  // customsound2
    customsound3: 0;                  // customsound3
    explosiondamage: 0;               // explosiondamage
    explosionradius: 0;               // explosionradius
    meleedamage: 0;                   // meleedamage
    scale: FRACUNIT;                  // scale
   ),
   (    // MT_KEEN
    name: 'Commander Keen';           // name
    inheritsfrom: -1;                 // inheritsfrom
    doomednum: 72;                    // doomednum
    spawnstate: Ord(S_KEENSTND);      // spawnstate
    spawnhealth: 100;                 // spawnhealth
    seestate: Ord(S_NULL);            // seestate
    seesound: Ord(sfx_None);          // seesound
    reactiontime: 8;                  // reactiontime
    attacksound: Ord(sfx_None);       // attacksound
    painstate: Ord(S_KEENPAIN);       // painstate
    painchance: 256;                  // painchance
    painsound: Ord(sfx_keenpn);       // painsound
    meleestate: Ord(S_NULL);          // meleestate
    missilestate: Ord(S_NULL);        // missilestate
    deathstate: Ord(S_COMMKEEN);      // deathstate
    xdeathstate: Ord(S_NULL);         // xdeathstate
    deathsound: Ord(sfx_keendt);      // deathsound
    speed: 0;                         // speed
    radius: 16 * FRACUNIT;            // radius
    height: 72 * FRACUNIT;            // height
    mass: 10000000;                   // mass
    damage: 0;                        // damage
    activesound: Ord(sfx_None);       // activesound
    flags: MF_SOLID or MF_SPAWNCEILING or MF_NOGRAVITY or MF_SHOOTABLE or MF_COUNTKILL;    // flags
    flags_ex: 0;                      // flags_ex
    raisestate: Ord(S_NULL);          // raisestate
    customsound1: 0;                  // customsound1
    customsound2: 0;                  // customsound2
    customsound3: 0;                  // customsound3
    explosiondamage: 0;               // explosiondamage
    explosionradius: 0;               // explosionradius
    meleedamage: 0;                   // meleedamage
    scale: FRACUNIT;                  // scale
   ),
   (    // MT_BOSSBRAIN
    name: 'Big Brain';                // name
    inheritsfrom: -1;                 // inheritsfrom
    doomednum: 88;                    // doomednum
    spawnstate: Ord(S_BRAIN);         // spawnstate
    spawnhealth: 250;                 // spawnhealth
    seestate: Ord(S_NULL);            // seestate
    seesound: Ord(sfx_None);          // seesound
    reactiontime: 8;                  // reactiontime
    attacksound: Ord(sfx_None);       // attacksound
    painstate: Ord(S_BRAIN_PAIN);     // painstate
    painchance: 255;                  // painchance
    painsound: Ord(sfx_bospn);        // painsound
    meleestate: Ord(S_NULL);          // meleestate
    missilestate: Ord(S_NULL);        // missilestate
    deathstate: Ord(S_BRAIN_DIE1);    // deathstate
    xdeathstate: Ord(S_NULL);         // xdeathstate
    deathsound: Ord(sfx_bosdth);      // deathsound
    speed: 0;                         // speed
    radius: 16 * FRACUNIT;            // radius
    height: 16 * FRACUNIT;            // height
    mass: 10000000;                   // mass
    damage: 0;                        // damage
    activesound: Ord(sfx_None);       // activesound
    flags: MF_SOLID or MF_SHOOTABLE;    // flags
    flags_ex: 0;                      // flags_ex
    raisestate: Ord(S_NULL);          // raisestate
    customsound1: 0;                  // customsound1
    customsound2: 0;                  // customsound2
    customsound3: 0;                  // customsound3
    explosiondamage: 0;               // explosiondamage
    explosionradius: 0;               // explosionradius
    meleedamage: 0;                   // meleedamage
    scale: FRACUNIT;                  // scale
   ),
   (    // MT_BOSSSPIT
    name: 'Demon Spawner';            // name
    inheritsfrom: -1;                 // inheritsfrom
    doomednum: 89;                    // doomednum
    spawnstate: Ord(S_BRAINEYE);      // spawnstate
    spawnhealth: 1000;                // spawnhealth
    seestate: Ord(S_BRAINEYESEE);     // seestate
    seesound: Ord(sfx_None);          // seesound
    reactiontime: 8;                  // reactiontime
    attacksound: Ord(sfx_None);       // attacksound
    painstate: Ord(S_NULL);           // painstate
    painchance: 0;                    // painchance
    painsound: Ord(sfx_None);         // painsound
    meleestate: Ord(S_NULL);          // meleestate
    missilestate: Ord(S_NULL);        // missilestate
    deathstate: Ord(S_NULL);          // deathstate
    xdeathstate: Ord(S_NULL);         // xdeathstate
    deathsound: Ord(sfx_None);        // deathsound
    speed: 0;                         // speed
    radius: 20 * FRACUNIT;            // radius
    height: 32 * FRACUNIT;            // height
    mass: 100;                        // mass
    damage: 0;                        // damage
    activesound: Ord(sfx_None);       // activesound
    flags: MF_NOBLOCKMAP or MF_NOSECTOR;    // flags
    flags_ex: 0;                      // flags_ex
    raisestate: Ord(S_NULL);          // raisestate
    customsound1: 0;                  // customsound1
    customsound2: 0;                  // customsound2
    customsound3: 0;                  // customsound3
    explosiondamage: 0;               // explosiondamage
    explosionradius: 0;               // explosionradius
    meleedamage: 0;                   // meleedamage
    scale: FRACUNIT;                  // scale
   ),
   (    // MT_BOSSTARGET
    name: 'Demon Spawn Spot';         // name
    inheritsfrom: -1;                 // inheritsfrom
    doomednum: 87;                    // doomednum
    spawnstate: Ord(S_NULL);          // spawnstate
    spawnhealth: 1000;                // spawnhealth
    seestate: Ord(S_NULL);            // seestate
    seesound: Ord(sfx_None);          // seesound
    reactiontime: 8;                  // reactiontime
    attacksound: Ord(sfx_None);       // attacksound
    painstate: Ord(S_NULL);           // painstate
    painchance: 0;                    // painchance
    painsound: Ord(sfx_None);         // painsound
    meleestate: Ord(S_NULL);          // meleestate
    missilestate: Ord(S_NULL);        // missilestate
    deathstate: Ord(S_NULL);          // deathstate
    xdeathstate: Ord(S_NULL);         // xdeathstate
    deathsound: Ord(sfx_None);        // deathsound
    speed: 0;                         // speed
    radius: 20 * FRACUNIT;            // radius
    height: 32 * FRACUNIT;            // height
    mass: 100;                        // mass
    damage: 0;                        // damage
    activesound: Ord(sfx_None);       // activesound
    flags: MF_NOBLOCKMAP or MF_NOSECTOR;    // flags
    flags_ex: 0;                      // flags_ex
    raisestate: Ord(S_NULL);          // raisestate
    customsound1: 0;                  // customsound1
    customsound2: 0;                  // customsound2
    customsound3: 0;                  // customsound3
    explosiondamage: 0;               // explosiondamage
    explosionradius: 0;               // explosionradius
    meleedamage: 0;                   // meleedamage
    scale: FRACUNIT;                  // scale
   ),
   (    // MT_SPAWNSHOT
    name: 'Demon Spawn Cube';         // name
    inheritsfrom: -1;                 // inheritsfrom
    doomednum: -1;                    // doomednum
    spawnstate: Ord(S_SPAWN1);        // spawnstate
    spawnhealth: 1000;                // spawnhealth
    seestate: Ord(S_NULL);            // seestate
    seesound: Ord(sfx_bospit);        // seesound
    reactiontime: 8;                  // reactiontime
    attacksound: Ord(sfx_None);       // attacksound
    painstate: Ord(S_NULL);           // painstate
    painchance: 0;                    // painchance
    painsound: Ord(sfx_None);         // painsound
    meleestate: Ord(S_NULL);          // meleestate
    missilestate: Ord(S_NULL);        // missilestate
    deathstate: Ord(S_NULL);          // deathstate
    xdeathstate: Ord(S_NULL);         // xdeathstate
    deathsound: Ord(sfx_firxpl);      // deathsound
    speed: 10 * FRACUNIT;             // speed
    radius: 6 * FRACUNIT;             // radius
    height: 32 * FRACUNIT;            // height
    mass: 100;                        // mass
    damage: 3;                        // damage
    activesound: Ord(sfx_None);       // activesound
    flags: MF_NOBLOCKMAP or MF_MISSILE or MF_DROPOFF or MF_NOGRAVITY or MF_NOCLIP;    // flags
    flags_ex: 0;                      // flags_ex
    raisestate: Ord(S_NULL);          // raisestate
    customsound1: 0;                  // customsound1
    customsound2: 0;                  // customsound2
    customsound3: 0;                  // customsound3
    explosiondamage: 0;               // explosiondamage
    explosionradius: 0;               // explosionradius
    meleedamage: 0;                   // meleedamage
    scale: FRACUNIT;                  // scale
   ),
   (    // MT_SPAWNFIRE
    name: 'Demon Spawn Fire';         // name
    inheritsfrom: -1;                 // inheritsfrom
    doomednum: -1;                    // doomednum
    spawnstate: Ord(S_SPAWNFIRE1);    // spawnstate
    spawnhealth: 1000;                // spawnhealth
    seestate: Ord(S_NULL);            // seestate
    seesound: Ord(sfx_None);          // seesound
    reactiontime: 8;                  // reactiontime
    attacksound: Ord(sfx_None);       // attacksound
    painstate: Ord(S_NULL);           // painstate
    painchance: 0;                    // painchance
    painsound: Ord(sfx_None);         // painsound
    meleestate: Ord(S_NULL);          // meleestate
    missilestate: Ord(S_NULL);        // missilestate
    deathstate: Ord(S_NULL);          // deathstate
    xdeathstate: Ord(S_NULL);         // xdeathstate
    deathsound: Ord(sfx_None);        // deathsound
    speed: 0;                         // speed
    radius: 20 * FRACUNIT;            // radius
    height: 16 * FRACUNIT;            // height
    mass: 100;                        // mass
    damage: 0;                        // damage
    activesound: Ord(sfx_None);       // activesound
    flags: MF_NOBLOCKMAP or MF_NOGRAVITY;    // flags
    flags_ex: MF_EX_TRANSPARENT or MF_EX_WHITELIGHT; // flags_ex
    raisestate: Ord(S_NULL);          // raisestate
    customsound1: 0;                  // customsound1
    customsound2: 0;                  // customsound2
    customsound3: 0;                  // customsound3
    explosiondamage: 0;               // explosiondamage
    explosionradius: 0;               // explosionradius
    meleedamage: 0;                   // meleedamage
    scale: FRACUNIT;                  // scale
   ),
   (    // MT_BARREL
    name: 'Barrel';                   // name
    inheritsfrom: -1;                 // inheritsfrom
    doomednum: 2035;                  // doomednum
    spawnstate: Ord(S_BAR1);          // spawnstate
    spawnhealth: 20;                  // spawnhealth
    seestate: Ord(S_NULL);            // seestate
    seesound: Ord(sfx_None);          // seesound
    reactiontime: 8;                  // reactiontime
    attacksound: Ord(sfx_None);       // attacksound
    painstate: Ord(S_NULL);           // painstate
    painchance: 0;                    // painchance
    painsound: Ord(sfx_None);         // painsound
    meleestate: Ord(S_NULL);          // meleestate
    missilestate: Ord(S_NULL);        // missilestate
    deathstate: Ord(S_BEXP);          // deathstate
    xdeathstate: Ord(S_NULL);         // xdeathstate
    deathsound: Ord(sfx_barexp);      // deathsound
    speed: 0;                         // speed
    radius: 10 * FRACUNIT;            // radius
    height: 42 * FRACUNIT;            // height
    mass: 100;                        // mass
    damage: 0;                        // damage
    activesound: Ord(sfx_None);       // activesound
    flags: MF_SOLID or MF_SHOOTABLE or MF_NOBLOOD;    // flags
    flags_ex: 0;                      // flags_ex
    raisestate: Ord(S_NULL);          // raisestate
    customsound1: 0;                  // customsound1
    customsound2: 0;                  // customsound2
    customsound3: 0;                  // customsound3
    explosiondamage: 0;               // explosiondamage
    explosionradius: 0;               // explosionradius
    meleedamage: 0;                   // meleedamage
    scale: FRACUNIT;                  // scale
   ),
   (    // MT_TROOPSHOT
    name: 'Imp Fireball';             // name
    inheritsfrom: -1;                 // inheritsfrom
    doomednum: -1;                    // doomednum
    spawnstate: Ord(S_TBALL1);        // spawnstate
    spawnhealth: 1000;                // spawnhealth
    seestate: Ord(S_NULL);            // seestate
    seesound: Ord(sfx_firsht);        // seesound
    reactiontime: 8;                  // reactiontime
    attacksound: Ord(sfx_None);       // attacksound
    painstate: Ord(S_NULL);           // painstate
    painchance: 0;                    // painchance
    painsound: Ord(sfx_None);         // painsound
    meleestate: Ord(S_NULL);          // meleestate
    missilestate: Ord(S_NULL);        // missilestate
    deathstate: Ord(S_TBALLX1);       // deathstate
    xdeathstate: Ord(S_NULL);         // xdeathstate
    deathsound: Ord(sfx_firxpl);      // deathsound
    speed: 10 * FRACUNIT;             // speed
    radius: 6 * FRACUNIT;             // radius
    height: 8 * FRACUNIT;             // height
    mass: 100;                        // mass
    damage: 3;                        // damage
    activesound: Ord(sfx_None);       // activesound
    flags: MF_NOBLOCKMAP or MF_MISSILE or MF_DROPOFF or MF_NOGRAVITY;    // flags
    flags_ex: MF_EX_TRANSPARENT or MF_EX_WHITELIGHT; // flags_ex
    raisestate: Ord(S_NULL);          // raisestate
    customsound1: 0;                  // customsound1
    customsound2: 0;                  // customsound2
    customsound3: 0;                  // customsound3
    explosiondamage: 0;               // explosiondamage
    explosionradius: 0;               // explosionradius
    meleedamage: 0;                   // meleedamage
    scale: FRACUNIT;                  // scale
   ),
   (    // MT_HEADSHOT
    name: 'Caco Fireball';            // name
    inheritsfrom: -1;                 // inheritsfrom
    doomednum: -1;                    // doomednum
    spawnstate: Ord(S_RBALL1);        // spawnstate
    spawnhealth: 1000;                // spawnhealth
    seestate: Ord(S_NULL);            // seestate
    seesound: Ord(sfx_firsht);        // seesound
    reactiontime: 8;                  // reactiontime
    attacksound: Ord(sfx_None);       // attacksound
    painstate: Ord(S_NULL);           // painstate
    painchance: 0;                    // painchance
    painsound: Ord(sfx_None);         // painsound
    meleestate: Ord(S_NULL);          // meleestate
    missilestate: Ord(S_NULL);        // missilestate
    deathstate: Ord(S_RBALLX1);       // deathstate
    xdeathstate: Ord(S_NULL);         // xdeathstate
    deathsound: Ord(sfx_firxpl);      // deathsound
    speed: 10 * FRACUNIT;             // speed
    radius: 6 * FRACUNIT;             // radius
    height: 8 * FRACUNIT;             // height
    mass: 100;                        // mass
    damage: 5;                        // damage
    activesound: Ord(sfx_None);       // activesound
    flags: MF_NOBLOCKMAP or MF_MISSILE or MF_DROPOFF or MF_NOGRAVITY;    // flags
    flags_ex: MF_EX_TRANSPARENT or MF_EX_WHITELIGHT; // flags_ex
    raisestate: Ord(S_NULL);          // raisestate
    customsound1: 0;                  // customsound1
    customsound2: 0;                  // customsound2
    customsound3: 0;                  // customsound3
    explosiondamage: 0;               // explosiondamage
    explosionradius: 0;               // explosionradius
    meleedamage: 0;                   // meleedamage
    scale: FRACUNIT;                  // scale
   ),
   (    // MT_ROCKET
    name: 'Rocket';                   // name
    inheritsfrom: -1;                 // inheritsfrom
    doomednum: -1;                    // doomednum
    spawnstate: Ord(S_ROCKET);        // spawnstate
    spawnhealth: 1000;                // spawnhealth
    seestate: Ord(S_NULL);            // seestate
    seesound: Ord(sfx_rlaunc);        // seesound
    reactiontime: 8;                  // reactiontime
    attacksound: Ord(sfx_None);       // attacksound
    painstate: Ord(S_NULL);           // painstate
    painchance: 0;                    // painchance
    painsound: Ord(sfx_None);         // painsound
    meleestate: Ord(S_NULL);          // meleestate
    missilestate: Ord(S_NULL);        // missilestate
    deathstate: Ord(S_EXPLODE1);      // deathstate
    xdeathstate: Ord(S_NULL);         // xdeathstate
    deathsound: Ord(sfx_barexp);      // deathsound
    speed: 20 * FRACUNIT;             // speed
    radius: 11 * FRACUNIT;            // radius
    height: 8 * FRACUNIT;             // height
    mass: 100;                        // mass
    damage: 20;                       // damage
    activesound: Ord(sfx_None);       // activesound
    flags: MF_NOBLOCKMAP or MF_MISSILE or MF_DROPOFF or MF_NOGRAVITY;    // flags
    flags_ex: MF_EX_WHITELIGHT;       // flags_ex
    raisestate: Ord(S_NULL);          // raisestate
    customsound1: 0;                  // customsound1
    customsound2: 0;                  // customsound2
    customsound3: 0;                  // customsound3
    explosiondamage: 0;               // explosiondamage
    explosionradius: 0;               // explosionradius
    meleedamage: 0;                   // meleedamage
    scale: FRACUNIT;                  // scale
   ),
   (    // MT_PLASMA
    name: 'Plasma Bullet';            // name
    inheritsfrom: -1;                 // inheritsfrom
    doomednum: -1;                    // doomednum
    spawnstate: Ord(S_PLASBALL);      // spawnstate
    spawnhealth: 1000;                // spawnhealth
    seestate: Ord(S_NULL);            // seestate
    seesound: Ord(sfx_plasma);        // seesound
    reactiontime: 8;                  // reactiontime
    attacksound: Ord(sfx_None);       // attacksound
    painstate: Ord(S_NULL);           // painstate
    painchance: 0;                    // painchance
    painsound: Ord(sfx_None);         // painsound
    meleestate: Ord(S_NULL);          // meleestate
    missilestate: Ord(S_NULL);        // missilestate
    deathstate: Ord(S_PLASEXP);       // deathstate
    xdeathstate: Ord(S_NULL);         // xdeathstate
    deathsound: Ord(sfx_firxpl);      // deathsound
    speed: 25 * FRACUNIT;             // speed
    radius: 13 * FRACUNIT;            // radius
    height: 8 * FRACUNIT;             // height
    mass: 100;                        // mass
    damage: 5;                        // damage
    activesound: Ord(sfx_None);       // activesound
    flags: MF_NOBLOCKMAP or MF_MISSILE or MF_DROPOFF or MF_NOGRAVITY;    // flags
    flags_ex: MF_EX_TRANSPARENT or MF_EX_WHITELIGHT; // flags_ex
    raisestate: Ord(S_NULL);          // raisestate
    customsound1: 0;                  // customsound1
    customsound2: 0;                  // customsound2
    customsound3: 0;                  // customsound3
    explosiondamage: 0;               // explosiondamage
    explosionradius: 0;               // explosionradius
    meleedamage: 0;                   // meleedamage
    scale: FRACUNIT;                  // scale
   ),
   (    // MT_BFG
    name: 'BFG Shot';                 // name
    inheritsfrom: -1;                 // inheritsfrom
    doomednum: -1;                    // doomednum
    spawnstate: Ord(S_BFGSHOT);       // spawnstate
    spawnhealth: 1000;                // spawnhealth
    seestate: Ord(S_NULL);            // seestate
    seesound: Ord(0);                 // seesound
    reactiontime: 8;                  // reactiontime
    attacksound: Ord(sfx_None);       // attacksound
    painstate: Ord(S_NULL);           // painstate
    painchance: 0;                    // painchance
    painsound: Ord(sfx_None);         // painsound
    meleestate: Ord(S_NULL);          // meleestate
    missilestate: Ord(S_NULL);        // missilestate
    deathstate: Ord(S_BFGLAND);       // deathstate
    xdeathstate: Ord(S_NULL);         // xdeathstate
    deathsound: Ord(sfx_rxplod);      // deathsound
    speed: 25 * FRACUNIT;             // speed
    radius: 13 * FRACUNIT;            // radius
    height: 8 * FRACUNIT;             // height
    mass: 100;                        // mass
    damage: 100;                      // damage
    activesound: Ord(sfx_None);       // activesound
    flags: MF_NOBLOCKMAP or MF_MISSILE or MF_DROPOFF or MF_NOGRAVITY;    // flags
    flags_ex: MF_EX_TRANSPARENT or MF_EX_WHITELIGHT; // flags_ex
    raisestate: Ord(S_NULL);          // raisestate
    customsound1: 0;                  // customsound1
    customsound2: 0;                  // customsound2
    customsound3: 0;                  // customsound3
    explosiondamage: 0;               // explosiondamage
    explosionradius: 0;               // explosionradius
    meleedamage: 0;                   // meleedamage
    scale: FRACUNIT;                  // scale
   ),
   (    // MT_ARACHPLAZ
    name: 'Arach. Fireball';          // name
    inheritsfrom: -1;                 // inheritsfrom
    doomednum: -1;                    // doomednum
    spawnstate: Ord(S_ARACH_PLAZ);    // spawnstate
    spawnhealth: 1000;                // spawnhealth
    seestate: Ord(S_NULL);            // seestate
    seesound: Ord(sfx_plasma);        // seesound
    reactiontime: 8;                  // reactiontime
    attacksound: Ord(sfx_None);       // attacksound
    painstate: Ord(S_NULL);           // painstate
    painchance: 0;                    // painchance
    painsound: Ord(sfx_None);         // painsound
    meleestate: Ord(S_NULL);          // meleestate
    missilestate: Ord(S_NULL);        // missilestate
    deathstate: Ord(S_ARACH_PLEX);    // deathstate
    xdeathstate: Ord(S_NULL);         // xdeathstate
    deathsound: Ord(sfx_firxpl);      // deathsound
    speed: 25 * FRACUNIT;             // speed
    radius: 13 * FRACUNIT;            // radius
    height: 8 * FRACUNIT;             // height
    mass: 100;                        // mass
    damage: 5;                        // damage
    activesound: Ord(sfx_None);       // activesound
    flags: MF_NOBLOCKMAP or MF_MISSILE or MF_DROPOFF or MF_NOGRAVITY;    // flags
    flags_ex: MF_EX_TRANSPARENT or MF_EX_WHITELIGHT; // flags_ex
    raisestate: Ord(S_NULL);          // raisestate
    customsound1: 0;                  // customsound1
    customsound2: 0;                  // customsound2
    customsound3: 0;                  // customsound3
    explosiondamage: 0;               // explosiondamage
    explosionradius: 0;               // explosionradius
    meleedamage: 0;                   // meleedamage
    scale: FRACUNIT;                  // scale
   ),
   (    // MT_PUFF
    name: 'Bullet Puff';              // name
    inheritsfrom: -1;                 // inheritsfrom
    doomednum: -1;                    // doomednum
    spawnstate: Ord(S_PUFF1);         // spawnstate
    spawnhealth: 1000;                // spawnhealth
    seestate: Ord(S_NULL);            // seestate
    seesound: Ord(sfx_None);          // seesound
    reactiontime: 8;                  // reactiontime
    attacksound: Ord(sfx_None);       // attacksound
    painstate: Ord(S_NULL);           // painstate
    painchance: 0;                    // painchance
    painsound: Ord(sfx_None);         // painsound
    meleestate: Ord(S_NULL);          // meleestate
    missilestate: Ord(S_NULL);        // missilestate
    deathstate: Ord(S_NULL);          // deathstate
    xdeathstate: Ord(S_NULL);         // xdeathstate
    deathsound: Ord(sfx_None);        // deathsound
    speed: 0;                         // speed
    radius: 20 * FRACUNIT;            // radius
    height: 16 * FRACUNIT;            // height
    mass: 100;                        // mass
    damage: 0;                        // damage
    activesound: Ord(sfx_None);       // activesound
    flags: MF_NOBLOCKMAP or MF_NOGRAVITY;    // flags
    flags_ex: MF_EX_TRANSPARENT or MF_EX_WHITELIGHT; // flags_ex
    raisestate: Ord(S_NULL);          // raisestate
    customsound1: 0;                  // customsound1
    customsound2: 0;                  // customsound2
    customsound3: 0;                  // customsound3
    explosiondamage: 0;               // explosiondamage
    explosionradius: 0;               // explosionradius
    meleedamage: 0;                   // meleedamage
    scale: FRACUNIT;                  // scale
   ),
   (    // MT_BLOOD
    name: 'Blood Splat';              // name
    inheritsfrom: -1;                 // inheritsfrom
    doomednum: -1;                    // doomednum
    spawnstate: Ord(S_BLOOD1);        // spawnstate
    spawnhealth: 1000;                // spawnhealth
    seestate: Ord(S_NULL);            // seestate
    seesound: Ord(sfx_None);          // seesound
    reactiontime: 8;                  // reactiontime
    attacksound: Ord(sfx_None);       // attacksound
    painstate: Ord(S_NULL);           // painstate
    painchance: 0;                    // painchance
    painsound: Ord(sfx_None);         // painsound
    meleestate: Ord(S_NULL);          // meleestate
    missilestate: Ord(S_NULL);        // missilestate
    deathstate: Ord(S_NULL);          // deathstate
    xdeathstate: Ord(S_NULL);         // xdeathstate
    deathsound: Ord(sfx_None);        // deathsound
    speed: 0;                         // speed
    radius: 20 * FRACUNIT;            // radius
    height: 16 * FRACUNIT;            // height
    mass: 100;                        // mass
    damage: 0;                        // damage
    activesound: Ord(sfx_None);       // activesound
    flags: MF_NOBLOCKMAP;             // flags
    flags_ex: MF_EX_TRANSPARENT or MF_EX_REDLIGHT; // flags_ex
    raisestate: Ord(S_NULL);          // raisestate
    customsound1: 0;                  // customsound1
    customsound2: 0;                  // customsound2
    customsound3: 0;                  // customsound3
    explosiondamage: 0;               // explosiondamage
    explosionradius: 0;               // explosionradius
    meleedamage: 0;                   // meleedamage
    scale: FRACUNIT;                  // scale
   ),
   (    // MT_TFOG
    name: 'Teleport Flash';           // name
    inheritsfrom: -1;                 // inheritsfrom
    doomednum: -1;                    // doomednum
    spawnstate: Ord(S_TFOG);          // spawnstate
    spawnhealth: 1000;                // spawnhealth
    seestate: Ord(S_NULL);            // seestate
    seesound: Ord(sfx_None);          // seesound
    reactiontime: 8;                  // reactiontime
    attacksound: Ord(sfx_None);       // attacksound
    painstate: Ord(S_NULL);           // painstate
    painchance: 0;                    // painchance
    painsound: Ord(sfx_None);         // painsound
    meleestate: Ord(S_NULL);          // meleestate
    missilestate: Ord(S_NULL);        // missilestate
    deathstate: Ord(S_NULL);          // deathstate
    xdeathstate: Ord(S_NULL);         // xdeathstate
    deathsound: Ord(sfx_None);        // deathsound
    speed: 0;                         // speed
    radius: 20 * FRACUNIT;            // radius
    height: 16 * FRACUNIT;            // height
    mass: 100;                        // mass
    damage: 0;                        // damage
    activesound: Ord(sfx_None);       // activesound
    flags: MF_NOBLOCKMAP or MF_NOGRAVITY;    // flags
    flags_ex: MF_EX_TRANSPARENT or MF_EX_WHITELIGHT; // flags_ex
    raisestate: Ord(S_NULL);          // raisestate
    customsound1: 0;                  // customsound1
    customsound2: 0;                  // customsound2
    customsound3: 0;                  // customsound3
    explosiondamage: 0;               // explosiondamage
    explosionradius: 0;               // explosionradius
    meleedamage: 0;                   // meleedamage
    scale: FRACUNIT;                  // scale
   ),
   (    // MT_IFOG
    name: 'Item Respawn Fog';         // name
    inheritsfrom: -1;                 // inheritsfrom
    doomednum: -1;                    // doomednum
    spawnstate: Ord(S_IFOG);          // spawnstate
    spawnhealth: 1000;                // spawnhealth
    seestate: Ord(S_NULL);            // seestate
    seesound: Ord(sfx_None);          // seesound
    reactiontime: 8;                  // reactiontime
    attacksound: Ord(sfx_None);       // attacksound
    painstate: Ord(S_NULL);           // painstate
    painchance: 0;                    // painchance
    painsound: Ord(sfx_None);         // painsound
    meleestate: Ord(S_NULL);          // meleestate
    missilestate: Ord(S_NULL);        // missilestate
    deathstate: Ord(S_NULL);          // deathstate
    xdeathstate: Ord(S_NULL);         // xdeathstate
    deathsound: Ord(sfx_None);        // deathsound
    speed: 0;                         // speed
    radius: 20 * FRACUNIT;            // radius
    height: 16 * FRACUNIT;            // height
    mass: 100;                        // mass
    damage: 0;                        // damage
    activesound: Ord(sfx_None);       // activesound
    flags: MF_NOBLOCKMAP or MF_NOGRAVITY;    // flags
    flags_ex: MF_EX_TRANSPARENT or MF_EX_WHITELIGHT; // flags_ex
    raisestate: Ord(S_NULL);          // raisestate
    customsound1: 0;                  // customsound1
    customsound2: 0;                  // customsound2
    customsound3: 0;                  // customsound3
    explosiondamage: 0;               // explosiondamage
    explosionradius: 0;               // explosionradius
    meleedamage: 0;                   // meleedamage
    scale: FRACUNIT;                  // scale
   ),
   (    // MT_TELEPORTMAN
    name: 'Teleport Exit';            // name
    inheritsfrom: -1;                 // inheritsfrom
    doomednum: 14;                    // doomednum
    spawnstate: Ord(S_NULL);          // spawnstate
    spawnhealth: 1000;                // spawnhealth
    seestate: Ord(S_NULL);            // seestate
    seesound: Ord(sfx_None);          // seesound
    reactiontime: 8;                  // reactiontime
    attacksound: Ord(sfx_None);       // attacksound
    painstate: Ord(S_NULL);           // painstate
    painchance: 0;                    // painchance
    painsound: Ord(sfx_None);         // painsound
    meleestate: Ord(S_NULL);          // meleestate
    missilestate: Ord(S_NULL);        // missilestate
    deathstate: Ord(S_NULL);          // deathstate
    xdeathstate: Ord(S_NULL);         // xdeathstate
    deathsound: Ord(sfx_None);        // deathsound
    speed: 0;                         // speed
    radius: 20 * FRACUNIT;            // radius
    height: 16 * FRACUNIT;            // height
    mass: 100;                        // mass
    damage: 0;                        // damage
    activesound: Ord(sfx_None);       // activesound
    flags: MF_NOBLOCKMAP or MF_NOSECTOR;    // flags
    flags_ex: 0;                      // flags_ex
    raisestate: Ord(S_NULL);          // raisestate
    customsound1: 0;                  // customsound1
    customsound2: 0;                  // customsound2
    customsound3: 0;                  // customsound3
    explosiondamage: 0;               // explosiondamage
    explosionradius: 0;               // explosionradius
    meleedamage: 0;                   // meleedamage
    scale: FRACUNIT;                  // scale
   ),
   (    // MT_EXTRABFG
    name: 'BFG Hit';                  // name
    inheritsfrom: -1;                 // inheritsfrom
    doomednum: -1;                    // doomednum
    spawnstate: Ord(S_BFGEXP);        // spawnstate
    spawnhealth: 1000;                // spawnhealth
    seestate: Ord(S_NULL);            // seestate
    seesound: Ord(sfx_None);          // seesound
    reactiontime: 8;                  // reactiontime
    attacksound: Ord(sfx_None);       // attacksound
    painstate: Ord(S_NULL);           // painstate
    painchance: 0;                    // painchance
    painsound: Ord(sfx_None);         // painsound
    meleestate: Ord(S_NULL);          // meleestate
    missilestate: Ord(S_NULL);        // missilestate
    deathstate: Ord(S_NULL);          // deathstate
    xdeathstate: Ord(S_NULL);         // xdeathstate
    deathsound: Ord(sfx_None);        // deathsound
    speed: 0;                         // speed
    radius: 20 * FRACUNIT;            // radius
    height: 16 * FRACUNIT;            // height
    mass: 100;                        // mass
    damage: 0;                        // damage
    activesound: Ord(sfx_None);       // activesound
    flags: MF_NOBLOCKMAP or MF_NOGRAVITY;    // flags
    flags_ex: 0;                      // flags_ex
    raisestate: Ord(S_NULL);          // raisestate
    customsound1: 0;                  // customsound1
    customsound2: 0;                  // customsound2
    customsound3: 0;                  // customsound3
    explosiondamage: 0;               // explosiondamage
    explosionradius: 0;               // explosionradius
    meleedamage: 0;                   // meleedamage
    scale: FRACUNIT;                  // scale
   ),
   (    // MT_MISC0
    name: 'Green Armor';              // name
    inheritsfrom: -1;                 // inheritsfrom
    doomednum: 2018;                  // doomednum
    spawnstate: Ord(S_ARM1);          // spawnstate
    spawnhealth: 1000;                // spawnhealth
    seestate: Ord(S_NULL);            // seestate
    seesound: Ord(sfx_None);          // seesound
    reactiontime: 8;                  // reactiontime
    attacksound: Ord(sfx_None);       // attacksound
    painstate: Ord(S_NULL);           // painstate
    painchance: 0;                    // painchance
    painsound: Ord(sfx_None);         // painsound
    meleestate: Ord(S_NULL);          // meleestate
    missilestate: Ord(S_NULL);        // missilestate
    deathstate: Ord(S_NULL);          // deathstate
    xdeathstate: Ord(S_NULL);         // xdeathstate
    deathsound: Ord(sfx_None);        // deathsound
    speed: 0;                         // speed
    radius: 20 * FRACUNIT;            // radius
    height: 16 * FRACUNIT;            // height
    mass: 100;                        // mass
    damage: 0;                        // damage
    activesound: Ord(sfx_None);       // activesound
    flags: MF_SPECIAL;                // flags
    flags_ex: 0;                      // flags_ex
    raisestate: Ord(S_NULL);          // raisestate
    customsound1: 0;                  // customsound1
    customsound2: 0;                  // customsound2
    customsound3: 0;                  // customsound3
    explosiondamage: 0;               // explosiondamage
    explosionradius: 0;               // explosionradius
    meleedamage: 0;                   // meleedamage
    scale: FRACUNIT;                  // scale
   ),
   (    // MT_MISC1
    name: 'Blue Armor';               // name
    inheritsfrom: -1;                 // inheritsfrom
    doomednum: 2019;                  // doomednum
    spawnstate: Ord(S_ARM2);          // spawnstate
    spawnhealth: 1000;                // spawnhealth
    seestate: Ord(S_NULL);            // seestate
    seesound: Ord(sfx_None);          // seesound
    reactiontime: 8;                  // reactiontime
    attacksound: Ord(sfx_None);       // attacksound
    painstate: Ord(S_NULL);           // painstate
    painchance: 0;                    // painchance
    painsound: Ord(sfx_None);         // painsound
    meleestate: Ord(S_NULL);          // meleestate
    missilestate: Ord(S_NULL);        // missilestate
    deathstate: Ord(S_NULL);          // deathstate
    xdeathstate: Ord(S_NULL);         // xdeathstate
    deathsound: Ord(sfx_None);        // deathsound
    speed: 0;                         // speed
    radius: 20 * FRACUNIT;            // radius
    height: 16 * FRACUNIT;            // height
    mass: 100;                        // mass
    damage: 0;                        // damage
    activesound: Ord(sfx_None);       // activesound
    flags: MF_SPECIAL;                // flags
    flags_ex: 0;                      // flags_ex
    raisestate: Ord(S_NULL);          // raisestate
    customsound1: 0;                  // customsound1
    customsound2: 0;                  // customsound2
    customsound3: 0;                  // customsound3
    explosiondamage: 0;               // explosiondamage
    explosionradius: 0;               // explosionradius
    meleedamage: 0;                   // meleedamage
    scale: FRACUNIT;                  // scale
   ),
   (    // MT_MISC2
    name: 'Health Potion';            // name
    inheritsfrom: -1;                 // inheritsfrom
    doomednum: 2014;                  // doomednum
    spawnstate: Ord(S_BON1);          // spawnstate
    spawnhealth: 1000;                // spawnhealth
    seestate: Ord(S_NULL);            // seestate
    seesound: Ord(sfx_None);          // seesound
    reactiontime: 8;                  // reactiontime
    attacksound: Ord(sfx_None);       // attacksound
    painstate: Ord(S_NULL);           // painstate
    painchance: 0;                    // painchance
    painsound: Ord(sfx_None);         // painsound
    meleestate: Ord(S_NULL);          // meleestate
    missilestate: Ord(S_NULL);        // missilestate
    deathstate: Ord(S_NULL);          // deathstate
    xdeathstate: Ord(S_NULL);         // xdeathstate
    deathsound: Ord(sfx_None);        // deathsound
    speed: 0;                         // speed
    radius: 20 * FRACUNIT;            // radius
    height: 16 * FRACUNIT;            // height
    mass: 100;                        // mass
    damage: 0;                        // damage
    activesound: Ord(sfx_None);       // activesound
    flags: MF_SPECIAL or MF_COUNTITEM;    // flags
    flags_ex: MF_EX_TRANSPARENT or MF_EX_BLUELIGHT;      // flags_ex
    raisestate: Ord(S_NULL);          // raisestate
    customsound1: 0;                  // customsound1
    customsound2: 0;                  // customsound2
    customsound3: 0;                  // customsound3
    explosiondamage: 0;               // explosiondamage
    explosionradius: 0;               // explosionradius
    meleedamage: 0;                   // meleedamage
    scale: FRACUNIT;                  // scale
   ),
   (    // MT_MISC3
    name: 'Armor Helmet';             // name
    inheritsfrom: -1;                 // inheritsfrom
    doomednum: 2015;                  // doomednum
    spawnstate: Ord(S_BON2);          // spawnstate
    spawnhealth: 1000;                // spawnhealth
    seestate: Ord(S_NULL);            // seestate
    seesound: Ord(sfx_None);          // seesound
    reactiontime: 8;                  // reactiontime
    attacksound: Ord(sfx_None);       // attacksound
    painstate: Ord(S_NULL);           // painstate
    painchance: 0;                    // painchance
    painsound: Ord(sfx_None);         // painsound
    meleestate: Ord(S_NULL);          // meleestate
    missilestate: Ord(S_NULL);        // missilestate
    deathstate: Ord(S_NULL);          // deathstate
    xdeathstate: Ord(S_NULL);         // xdeathstate
    deathsound: Ord(sfx_None);        // deathsound
    speed: 0;                         // speed
    radius: 20 * FRACUNIT;            // radius
    height: 16 * FRACUNIT;            // height
    mass: 100;                        // mass
    damage: 0;                        // damage
    activesound: Ord(sfx_None);       // activesound
    flags: MF_SPECIAL or MF_COUNTITEM;    // flags
    flags_ex: 0;                      // flags_ex
    raisestate: Ord(S_NULL);          // raisestate
    customsound1: 0;                  // customsound1
    customsound2: 0;                  // customsound2
    customsound3: 0;                  // customsound3
    explosiondamage: 0;               // explosiondamage
    explosionradius: 0;               // explosionradius
    meleedamage: 0;                   // meleedamage
    scale: FRACUNIT;                  // scale
   ),
   (    // MT_MISC4
    name: 'Blue Keycard';             // name
    inheritsfrom: -1;                 // inheritsfrom
    doomednum: 5;                     // doomednum
    spawnstate: Ord(S_BKEY);          // spawnstate
    spawnhealth: 1000;                // spawnhealth
    seestate: Ord(S_NULL);            // seestate
    seesound: Ord(sfx_None);          // seesound
    reactiontime: 8;                  // reactiontime
    attacksound: Ord(sfx_None);       // attacksound
    painstate: Ord(S_NULL);           // painstate
    painchance: 0;                    // painchance
    painsound: Ord(sfx_None);         // painsound
    meleestate: Ord(S_NULL);          // meleestate
    missilestate: Ord(S_NULL);        // missilestate
    deathstate: Ord(S_NULL);          // deathstate
    xdeathstate: Ord(S_NULL);         // xdeathstate
    deathsound: Ord(sfx_None);        // deathsound
    speed: 0;                         // speed
    radius: 20 * FRACUNIT;            // radius
    height: 16 * FRACUNIT;            // height
    mass: 100;                        // mass
    damage: 0;                        // damage
    activesound: Ord(sfx_None);       // activesound
    flags: MF_SPECIAL or MF_NOTDMATCH;// flags
    flags_ex: MF_EX_BLUELIGHT;        // flags_ex
    raisestate: Ord(S_NULL);          // raisestate
    customsound1: 0;                  // customsound1
    customsound2: 0;                  // customsound2
    customsound3: 0;                  // customsound3
    explosiondamage: 0;               // explosiondamage
    explosionradius: 0;               // explosionradius
    meleedamage: 0;                   // meleedamage
    scale: FRACUNIT;                  // scale
   ),
   (    // MT_MISC5
    name: 'Red Keycard';              // name
    inheritsfrom: -1;                 // inheritsfrom
    doomednum: 13;                    // doomednum
    spawnstate: Ord(S_RKEY);          // spawnstate
    spawnhealth: 1000;                // spawnhealth
    seestate: Ord(S_NULL);            // seestate
    seesound: Ord(sfx_None);          // seesound
    reactiontime: 8;                  // reactiontime
    attacksound: Ord(sfx_None);       // attacksound
    painstate: Ord(S_NULL);           // painstate
    painchance: 0;                    // painchance
    painsound: Ord(sfx_None);         // painsound
    meleestate: Ord(S_NULL);          // meleestate
    missilestate: Ord(S_NULL);        // missilestate
    deathstate: Ord(S_NULL);          // deathstate
    xdeathstate: Ord(S_NULL);         // xdeathstate
    deathsound: Ord(sfx_None);        // deathsound
    speed: 0;                         // speed
    radius: 20 * FRACUNIT;            // radius
    height: 16 * FRACUNIT;            // height
    mass: 100;                        // mass
    damage: 0;                        // damage
    activesound: Ord(sfx_None);       // activesound
    flags: MF_SPECIAL or MF_NOTDMATCH;// flags
    flags_ex: MF_EX_REDLIGHT;         // flags_ex
    raisestate: Ord(S_NULL);          // raisestate
    customsound1: 0;                  // customsound1
    customsound2: 0;                  // customsound2
    customsound3: 0;                  // customsound3
    explosiondamage: 0;               // explosiondamage
    explosionradius: 0;               // explosionradius
    meleedamage: 0;                   // meleedamage
    scale: FRACUNIT;                  // scale
   ),
   (    // MT_MISC6
    name: 'Yellow Keycard';           // name
    inheritsfrom: -1;                 // inheritsfrom
    doomednum: 6;                     // doomednum
    spawnstate: Ord(S_YKEY);          // spawnstate
    spawnhealth: 1000;                // spawnhealth
    seestate: Ord(S_NULL);            // seestate
    seesound: Ord(sfx_None);          // seesound
    reactiontime: 8;                  // reactiontime
    attacksound: Ord(sfx_None);       // attacksound
    painstate: Ord(S_NULL);           // painstate
    painchance: 0;                    // painchance
    painsound: Ord(sfx_None);         // painsound
    meleestate: Ord(S_NULL);          // meleestate
    missilestate: Ord(S_NULL);        // missilestate
    deathstate: Ord(S_NULL);          // deathstate
    xdeathstate: Ord(S_NULL);         // xdeathstate
    deathsound: Ord(sfx_None);        // deathsound
    speed: 0;                         // speed
    radius: 20 * FRACUNIT;            // radius
    height: 16 * FRACUNIT;            // height
    mass: 100;                        // mass
    damage: 0;                        // damage
    activesound: Ord(sfx_None);       // activesound
    flags: MF_SPECIAL or MF_NOTDMATCH;// flags
    flags_ex: MF_EX_YELLOWLIGHT;      // flags_ex
    raisestate: Ord(S_NULL);          // raisestate
    customsound1: 0;                  // customsound1
    customsound2: 0;                  // customsound2
    customsound3: 0;                  // customsound3
    explosiondamage: 0;               // explosiondamage
    explosionradius: 0;               // explosionradius
    meleedamage: 0;                   // meleedamage
    scale: FRACUNIT;                  // scale
   ),
   (    // MT_MISC7
    name: 'Yellow Skull Key';         // name
    inheritsfrom: -1;                 // inheritsfrom
    doomednum: 39;                    // doomednum
    spawnstate: Ord(S_YSKULL);        // spawnstate
    spawnhealth: 1000;                // spawnhealth
    seestate: Ord(S_NULL);            // seestate
    seesound: Ord(sfx_None);          // seesound
    reactiontime: 8;                  // reactiontime
    attacksound: Ord(sfx_None);       // attacksound
    painstate: Ord(S_NULL);           // painstate
    painchance: 0;                    // painchance
    painsound: Ord(sfx_None);         // painsound
    meleestate: Ord(S_NULL);          // meleestate
    missilestate: Ord(S_NULL);        // missilestate
    deathstate: Ord(S_NULL);          // deathstate
    xdeathstate: Ord(S_NULL);         // xdeathstate
    deathsound: Ord(sfx_None);        // deathsound
    speed: 0;                         // speed
    radius: 20 * FRACUNIT;            // radius
    height: 16 * FRACUNIT;            // height
    mass: 100;                        // mass
    damage: 0;                        // damage
    activesound: Ord(sfx_None);       // activesound
    flags: MF_SPECIAL or MF_NOTDMATCH;// flags
    flags_ex: MF_EX_YELLOWLIGHT;      // flags_ex
    raisestate: Ord(S_NULL);          // raisestate
    customsound1: 0;                  // customsound1
    customsound2: 0;                  // customsound2
    customsound3: 0;                  // customsound3
    explosiondamage: 0;               // explosiondamage
    explosionradius: 0;               // explosionradius
    meleedamage: 0;                   // meleedamage
    scale: FRACUNIT;                  // scale
   ),
   (    // MT_MISC8
    name: 'Red Skull Key';            // name
    inheritsfrom: -1;                 // inheritsfrom
    doomednum: 38;                    // doomednum
    spawnstate: Ord(S_RSKULL);        // spawnstate
    spawnhealth: 1000;                // spawnhealth
    seestate: Ord(S_NULL);            // seestate
    seesound: Ord(sfx_None);          // seesound
    reactiontime: 8;                  // reactiontime
    attacksound: Ord(sfx_None);       // attacksound
    painstate: Ord(S_NULL);           // painstate
    painchance: 0;                    // painchance
    painsound: Ord(sfx_None);         // painsound
    meleestate: Ord(S_NULL);          // meleestate
    missilestate: Ord(S_NULL);        // missilestate
    deathstate: Ord(S_NULL);          // deathstate
    xdeathstate: Ord(S_NULL);         // xdeathstate
    deathsound: Ord(sfx_None);        // deathsound
    speed: 0;                         // speed
    radius: 20 * FRACUNIT;            // radius
    height: 16 * FRACUNIT;            // height
    mass: 100;                        // mass
    damage: 0;                        // damage
    activesound: Ord(sfx_None);       // activesound
    flags: MF_SPECIAL or MF_NOTDMATCH;// flags
    flags_ex: MF_EX_REDLIGHT;         // flags_ex
    raisestate: Ord(S_NULL);          // raisestate
    customsound1: 0;                  // customsound1
    customsound2: 0;                  // customsound2
    customsound3: 0;                  // customsound3
    explosiondamage: 0;               // explosiondamage
    explosionradius: 0;               // explosionradius
    meleedamage: 0;                   // meleedamage
    scale: FRACUNIT;                  // scale
   ),
   (    // MT_MISC9
    name: 'Blue Skull Key';           // name
    inheritsfrom: -1;                 // inheritsfrom
    doomednum: 40;                    // doomednum
    spawnstate: Ord(S_BSKULL);        // spawnstate
    spawnhealth: 1000;                // spawnhealth
    seestate: Ord(S_NULL);            // seestate
    seesound: Ord(sfx_None);          // seesound
    reactiontime: 8;                  // reactiontime
    attacksound: Ord(sfx_None);       // attacksound
    painstate: Ord(S_NULL);           // painstate
    painchance: 0;                    // painchance
    painsound: Ord(sfx_None);         // painsound
    meleestate: Ord(S_NULL);          // meleestate
    missilestate: Ord(S_NULL);        // missilestate
    deathstate: Ord(S_NULL);          // deathstate
    xdeathstate: Ord(S_NULL);         // xdeathstate
    deathsound: Ord(sfx_None);        // deathsound
    speed: 0;                         // speed
    radius: 20 * FRACUNIT;            // radius
    height: 16 * FRACUNIT;            // height
    mass: 100;                        // mass
    damage: 0;                        // damage
    activesound: Ord(sfx_None);       // activesound
    flags: MF_SPECIAL or MF_NOTDMATCH;// flags
    flags_ex: MF_EX_BLUELIGHT;        // flags_ex
    raisestate: Ord(S_NULL);          // raisestate
    customsound1: 0;                  // customsound1
    customsound2: 0;                  // customsound2
    customsound3: 0;                  // customsound3
    explosiondamage: 0;               // explosiondamage
    explosionradius: 0;               // explosionradius
    meleedamage: 0;                   // meleedamage
    scale: FRACUNIT;                  // scale
   ),
   (    // MT_MISC10
    name: 'Stim Pack';                // name
    inheritsfrom: -1;                 // inheritsfrom
    doomednum: 2011;                  // doomednum
    spawnstate: Ord(S_STIM);          // spawnstate
    spawnhealth: 1000;                // spawnhealth
    seestate: Ord(S_NULL);            // seestate
    seesound: Ord(sfx_None);          // seesound
    reactiontime: 8;                  // reactiontime
    attacksound: Ord(sfx_None);       // attacksound
    painstate: Ord(S_NULL);           // painstate
    painchance: 0;                    // painchance
    painsound: Ord(sfx_None);         // painsound
    meleestate: Ord(S_NULL);          // meleestate
    missilestate: Ord(S_NULL);        // missilestate
    deathstate: Ord(S_NULL);          // deathstate
    xdeathstate: Ord(S_NULL);         // xdeathstate
    deathsound: Ord(sfx_None);        // deathsound
    speed: 0;                         // speed
    radius: 20 * FRACUNIT;            // radius
    height: 16 * FRACUNIT;            // height
    mass: 100;                        // mass
    damage: 0;                        // damage
    activesound: Ord(sfx_None);       // activesound
    flags: MF_SPECIAL;                // flags
    flags_ex: 0;                      // flags_ex
    raisestate: Ord(S_NULL);          // raisestate
    customsound1: 0;                  // customsound1
    customsound2: 0;                  // customsound2
    customsound3: 0;                  // customsound3
    explosiondamage: 0;               // explosiondamage
    explosionradius: 0;               // explosionradius
    meleedamage: 0;                   // meleedamage
    scale: FRACUNIT;                  // scale
   ),
   (    // MT_MISC11
    name: 'Medical Kit';              // name
    inheritsfrom: -1;                 // inheritsfrom
    doomednum: 2012;                  // doomednum
    spawnstate: Ord(S_MEDI);          // spawnstate
    spawnhealth: 1000;                // spawnhealth
    seestate: Ord(S_NULL);            // seestate
    seesound: Ord(sfx_None);          // seesound
    reactiontime: 8;                  // reactiontime
    attacksound: Ord(sfx_None);       // attacksound
    painstate: Ord(S_NULL);           // painstate
    painchance: 0;                    // painchance
    painsound: Ord(sfx_None);         // painsound
    meleestate: Ord(S_NULL);          // meleestate
    missilestate: Ord(S_NULL);        // missilestate
    deathstate: Ord(S_NULL);          // deathstate
    xdeathstate: Ord(S_NULL);         // xdeathstate
    deathsound: Ord(sfx_None);        // deathsound
    speed: 0;                         // speed
    radius: 20 * FRACUNIT;            // radius
    height: 16 * FRACUNIT;            // height
    mass: 100;                        // mass
    damage: 0;                        // damage
    activesound: Ord(sfx_None);       // activesound
    flags: MF_SPECIAL;                // flags
    flags_ex: 0;                      // flags_ex
    raisestate: Ord(S_NULL);          // raisestate
    customsound1: 0;                  // customsound1
    customsound2: 0;                  // customsound2
    customsound3: 0;                  // customsound3
    explosiondamage: 0;               // explosiondamage
    explosionradius: 0;               // explosionradius
    meleedamage: 0;                   // meleedamage
    scale: FRACUNIT;                  // scale
   ),
   (    // MT_MISC12
    name: 'Soul Sphere';              // name
    inheritsfrom: -1;                 // inheritsfrom
    doomednum: 2013;                  // doomednum
    spawnstate: Ord(S_SOUL);          // spawnstate
    spawnhealth: 1000;                // spawnhealth
    seestate: Ord(S_NULL);            // seestate
    seesound: Ord(sfx_None);          // seesound
    reactiontime: 8;                  // reactiontime
    attacksound: Ord(sfx_None);       // attacksound
    painstate: Ord(S_NULL);           // painstate
    painchance: 0;                    // painchance
    painsound: Ord(sfx_None);         // painsound
    meleestate: Ord(S_NULL);          // meleestate
    missilestate: Ord(S_NULL);        // missilestate
    deathstate: Ord(S_NULL);          // deathstate
    xdeathstate: Ord(S_NULL);         // xdeathstate
    deathsound: Ord(sfx_None);        // deathsound
    speed: 0;                         // speed
    radius: 20 * FRACUNIT;            // radius
    height: 16 * FRACUNIT;            // height
    mass: 100;                        // mass
    damage: 0;                        // damage
    activesound: Ord(sfx_None);       // activesound
    flags: MF_SPECIAL or MF_COUNTITEM;    // flags
    flags_ex: 0;                      // flags_ex
    raisestate: Ord(S_NULL);          // raisestate
    customsound1: 0;                  // customsound1
    customsound2: 0;                  // customsound2
    customsound3: 0;                  // customsound3
    explosiondamage: 0;               // explosiondamage
    explosionradius: 0;               // explosionradius
    meleedamage: 0;                   // meleedamage
    scale: FRACUNIT;                  // scale
   ),
   (    // MT_INV
    name: 'Invulnerability';          // name
    inheritsfrom: -1;                 // inheritsfrom
    doomednum: 2022;                  // doomednum
    spawnstate: Ord(S_PINV);          // spawnstate
    spawnhealth: 1000;                // spawnhealth
    seestate: Ord(S_NULL);            // seestate
    seesound: Ord(sfx_None);          // seesound
    reactiontime: 8;                  // reactiontime
    attacksound: Ord(sfx_None);       // attacksound
    painstate: Ord(S_NULL);           // painstate
    painchance: 0;                    // painchance
    painsound: Ord(sfx_None);         // painsound
    meleestate: Ord(S_NULL);          // meleestate
    missilestate: Ord(S_NULL);        // missilestate
    deathstate: Ord(S_NULL);          // deathstate
    xdeathstate: Ord(S_NULL);         // xdeathstate
    deathsound: Ord(sfx_None);        // deathsound
    speed: 0;                         // speed
    radius: 20 * FRACUNIT;            // radius
    height: 16 * FRACUNIT;            // height
    mass: 100;                        // mass
    damage: 0;                        // damage
    activesound: Ord(sfx_None);       // activesound
    flags: MF_SPECIAL or MF_COUNTITEM;    // flags
    flags_ex: 0;                      // flags_ex
    raisestate: Ord(S_NULL);          // raisestate
    customsound1: 0;                  // customsound1
    customsound2: 0;                  // customsound2
    customsound3: 0;                  // customsound3
    explosiondamage: 0;               // explosiondamage
    explosionradius: 0;               // explosionradius
    meleedamage: 0;                   // meleedamage
    scale: FRACUNIT;                  // scale
   ),
   (    // MT_MISC13
    name: 'Berserk Sphere';           // name
    inheritsfrom: -1;                 // inheritsfrom
    doomednum: 2023;                  // doomednum
    spawnstate: Ord(S_PSTR);          // spawnstate
    spawnhealth: 1000;                // spawnhealth
    seestate: Ord(S_NULL);            // seestate
    seesound: Ord(sfx_None);          // seesound
    reactiontime: 8;                  // reactiontime
    attacksound: Ord(sfx_None);       // attacksound
    painstate: Ord(S_NULL);           // painstate
    painchance: 0;                    // painchance
    painsound: Ord(sfx_None);         // painsound
    meleestate: Ord(S_NULL);          // meleestate
    missilestate: Ord(S_NULL);        // missilestate
    deathstate: Ord(S_NULL);          // deathstate
    xdeathstate: Ord(S_NULL);         // xdeathstate
    deathsound: Ord(sfx_None);        // deathsound
    speed: 0;                         // speed
    radius: 20 * FRACUNIT;            // radius
    height: 16 * FRACUNIT;            // height
    mass: 100;                        // mass
    damage: 0;                        // damage
    activesound: Ord(sfx_None);       // activesound
    flags: MF_SPECIAL or MF_COUNTITEM;    // flags
    flags_ex: 0;                      // flags_ex
    raisestate: Ord(S_NULL);          // raisestate
    customsound1: 0;                  // customsound1
    customsound2: 0;                  // customsound2
    customsound3: 0;                  // customsound3
    explosiondamage: 0;               // explosiondamage
    explosionradius: 0;               // explosionradius
    meleedamage: 0;                   // meleedamage
    scale: FRACUNIT;                  // scale
   ),
   (    // MT_INS
    name: 'Blur Sphere';              // name
    inheritsfrom: -1;                 // inheritsfrom
    doomednum: 2024;                  // doomednum
    spawnstate: Ord(S_PINS);          // spawnstate
    spawnhealth: 1000;                // spawnhealth
    seestate: Ord(S_NULL);            // seestate
    seesound: Ord(sfx_None);          // seesound
    reactiontime: 8;                  // reactiontime
    attacksound: Ord(sfx_None);       // attacksound
    painstate: Ord(S_NULL);           // painstate
    painchance: 0;                    // painchance
    painsound: Ord(sfx_None);         // painsound
    meleestate: Ord(S_NULL);          // meleestate
    missilestate: Ord(S_NULL);        // missilestate
    deathstate: Ord(S_NULL);          // deathstate
    xdeathstate: Ord(S_NULL);         // xdeathstate
    deathsound: Ord(sfx_None);        // deathsound
    speed: 0;                         // speed
    radius: 20 * FRACUNIT;            // radius
    height: 16 * FRACUNIT;            // height
    mass: 100;                        // mass
    damage: 0;                        // damage
    activesound: Ord(sfx_None);       // activesound
    flags: MF_SPECIAL or MF_COUNTITEM;    // flags
    flags_ex: 0;                      // flags_ex
    raisestate: Ord(S_NULL);          // raisestate
    customsound1: 0;                  // customsound1
    customsound2: 0;                  // customsound2
    customsound3: 0;                  // customsound3
    explosiondamage: 0;               // explosiondamage
    explosionradius: 0;               // explosionradius
    meleedamage: 0;                   // meleedamage
    scale: FRACUNIT;                  // scale
   ),
   (    // MT_MISC14
    name: 'Radiation Suit';           // name
    inheritsfrom: -1;                 // inheritsfrom
    doomednum: 2025;                  // doomednum
    spawnstate: Ord(S_SUIT);          // spawnstate
    spawnhealth: 1000;                // spawnhealth
    seestate: Ord(S_NULL);            // seestate
    seesound: Ord(sfx_None);          // seesound
    reactiontime: 8;                  // reactiontime
    attacksound: Ord(sfx_None);       // attacksound
    painstate: Ord(S_NULL);           // painstate
    painchance: 0;                    // painchance
    painsound: Ord(sfx_None);         // painsound
    meleestate: Ord(S_NULL);          // meleestate
    missilestate: Ord(S_NULL);        // missilestate
    deathstate: Ord(S_NULL);          // deathstate
    xdeathstate: Ord(S_NULL);         // xdeathstate
    deathsound: Ord(sfx_None);        // deathsound
    speed: 0;                         // speed
    radius: 20 * FRACUNIT;            // radius
    height: 16 * FRACUNIT;            // height
    mass: 100;                        // mass
    damage: 0;                        // damage
    activesound: Ord(sfx_None);       // activesound
    flags: MF_SPECIAL;                // flags
    flags_ex: 0;                      // flags_ex
    raisestate: Ord(S_NULL);          // raisestate
    customsound1: 0;                  // customsound1
    customsound2: 0;                  // customsound2
    customsound3: 0;                  // customsound3
    explosiondamage: 0;               // explosiondamage
    explosionradius: 0;               // explosionradius
    meleedamage: 0;                   // meleedamage
    scale: FRACUNIT;                  // scale
   ),
   (    // MT_MISC15
    name: 'Computer Map';             // name
    inheritsfrom: -1;                 // inheritsfrom
    doomednum: 2026;                  // doomednum
    spawnstate: Ord(S_PMAP);          // spawnstate
    spawnhealth: 1000;                // spawnhealth
    seestate: Ord(S_NULL);            // seestate
    seesound: Ord(sfx_None);          // seesound
    reactiontime: 8;                  // reactiontime
    attacksound: Ord(sfx_None);       // attacksound
    painstate: Ord(S_NULL);           // painstate
    painchance: 0;                    // painchance
    painsound: Ord(sfx_None);         // painsound
    meleestate: Ord(S_NULL);          // meleestate
    missilestate: Ord(S_NULL);        // missilestate
    deathstate: Ord(S_NULL);          // deathstate
    xdeathstate: Ord(S_NULL);         // xdeathstate
    deathsound: Ord(sfx_None);        // deathsound
    speed: 0;                         // speed
    radius: 20 * FRACUNIT;            // radius
    height: 16 * FRACUNIT;            // height
    mass: 100;                        // mass
    damage: 0;                        // damage
    activesound: Ord(sfx_None);       // activesound
    flags: MF_SPECIAL or MF_COUNTITEM;    // flags
    flags_ex: 0;                      // flags_ex
    raisestate: Ord(S_NULL);          // raisestate
    customsound1: 0;                  // customsound1
    customsound2: 0;                  // customsound2
    customsound3: 0;                  // customsound3
    explosiondamage: 0;               // explosiondamage
    explosionradius: 0;               // explosionradius
    meleedamage: 0;                   // meleedamage
    scale: FRACUNIT;                  // scale
   ),
   (    // MT_MISC16
    name: 'Lite Amp. Visor';          // name
    inheritsfrom: -1;                 // inheritsfrom
    doomednum: 2045;                  // doomednum
    spawnstate: Ord(S_PVIS);          // spawnstate
    spawnhealth: 1000;                // spawnhealth
    seestate: Ord(S_NULL);            // seestate
    seesound: Ord(sfx_None);          // seesound
    reactiontime: 8;                  // reactiontime
    attacksound: Ord(sfx_None);       // attacksound
    painstate: Ord(S_NULL);           // painstate
    painchance: 0;                    // painchance
    painsound: Ord(sfx_None);         // painsound
    meleestate: Ord(S_NULL);          // meleestate
    missilestate: Ord(S_NULL);        // missilestate
    deathstate: Ord(S_NULL);          // deathstate
    xdeathstate: Ord(S_NULL);         // xdeathstate
    deathsound: Ord(sfx_None);        // deathsound
    speed: 0;                         // speed
    radius: 20 * FRACUNIT;            // radius
    height: 16 * FRACUNIT;            // height
    mass: 100;                        // mass
    damage: 0;                        // damage
    activesound: Ord(sfx_None);       // activesound
    flags: MF_SPECIAL or MF_COUNTITEM;    // flags
    flags_ex: 0;                      // flags_ex
    raisestate: Ord(S_NULL);          // raisestate
    customsound1: 0;                  // customsound1
    customsound2: 0;                  // customsound2
    customsound3: 0;                  // customsound3
    explosiondamage: 0;               // explosiondamage
    explosionradius: 0;               // explosionradius
    meleedamage: 0;                   // meleedamage
    scale: FRACUNIT;                  // scale
   ),
   (    // MT_MEGA
    name: 'Mega Sphere';              // name
    inheritsfrom: -1;                 // inheritsfrom
    doomednum: 83;                    // doomednum
    spawnstate: Ord(S_MEGA);          // spawnstate
    spawnhealth: 1000;                // spawnhealth
    seestate: Ord(S_NULL);            // seestate
    seesound: Ord(sfx_None);          // seesound
    reactiontime: 8;                  // reactiontime
    attacksound: Ord(sfx_None);       // attacksound
    painstate: Ord(S_NULL);           // painstate
    painchance: 0;                    // painchance
    painsound: Ord(sfx_None);         // painsound
    meleestate: Ord(S_NULL);          // meleestate
    missilestate: Ord(S_NULL);        // missilestate
    deathstate: Ord(S_NULL);          // deathstate
    xdeathstate: Ord(S_NULL);         // xdeathstate
    deathsound: Ord(sfx_None);        // deathsound
    speed: 0;                         // speed
    radius: 20 * FRACUNIT;            // radius
    height: 16 * FRACUNIT;            // height
    mass: 100;                        // mass
    damage: 0;                        // damage
    activesound: Ord(sfx_None);       // activesound
    flags: MF_SPECIAL or MF_COUNTITEM;    // flags
    flags_ex: 0;                      // flags_ex
    raisestate: Ord(S_NULL);          // raisestate
    customsound1: 0;                  // customsound1
    customsound2: 0;                  // customsound2
    customsound3: 0;                  // customsound3
    explosiondamage: 0;               // explosiondamage
    explosionradius: 0;               // explosionradius
    meleedamage: 0;                   // meleedamage
    scale: FRACUNIT;                  // scale
   ),
   (    // MT_CLIP
    name: 'Ammo Clip';                // name
    inheritsfrom: -1;                 // inheritsfrom
    doomednum: 2007;                  // doomednum
    spawnstate: Ord(S_CLIP);          // spawnstate
    spawnhealth: 1000;                // spawnhealth
    seestate: Ord(S_NULL);            // seestate
    seesound: Ord(sfx_None);          // seesound
    reactiontime: 8;                  // reactiontime
    attacksound: Ord(sfx_None);       // attacksound
    painstate: Ord(S_NULL);           // painstate
    painchance: 0;                    // painchance
    painsound: Ord(sfx_None);         // painsound
    meleestate: Ord(S_NULL);          // meleestate
    missilestate: Ord(S_NULL);        // missilestate
    deathstate: Ord(S_NULL);          // deathstate
    xdeathstate: Ord(S_NULL);         // xdeathstate
    deathsound: Ord(sfx_None);        // deathsound
    speed: 0;                         // speed
    radius: 20 * FRACUNIT;            // radius
    height: 16 * FRACUNIT;            // height
    mass: 100;                        // mass
    damage: 0;                        // damage
    activesound: Ord(sfx_None);       // activesound
    flags: MF_SPECIAL;                // flags
    flags_ex: 0;                      // flags_ex
    raisestate: Ord(S_NULL);          // raisestate
    customsound1: 0;                  // customsound1
    customsound2: 0;                  // customsound2
    customsound3: 0;                  // customsound3
    explosiondamage: 0;               // explosiondamage
    explosionradius: 0;               // explosionradius
    meleedamage: 0;                   // meleedamage
    scale: FRACUNIT;                  // scale
   ),
   (    // MT_MISC17
    name: 'Box of Ammo';              // name
    inheritsfrom: -1;                 // inheritsfrom
    doomednum: 2048;                  // doomednum
    spawnstate: Ord(S_AMMO);          // spawnstate
    spawnhealth: 1000;                // spawnhealth
    seestate: Ord(S_NULL);            // seestate
    seesound: Ord(sfx_None);          // seesound
    reactiontime: 8;                  // reactiontime
    attacksound: Ord(sfx_None);       // attacksound
    painstate: Ord(S_NULL);           // painstate
    painchance: 0;                    // painchance
    painsound: Ord(sfx_None);         // painsound
    meleestate: Ord(S_NULL);          // meleestate
    missilestate: Ord(S_NULL);        // missilestate
    deathstate: Ord(S_NULL);          // deathstate
    xdeathstate: Ord(S_NULL);         // xdeathstate
    deathsound: Ord(sfx_None);        // deathsound
    speed: 0;                         // speed
    radius: 20 * FRACUNIT;            // radius
    height: 16 * FRACUNIT;            // height
    mass: 100;                        // mass
    damage: 0;                        // damage
    activesound: Ord(sfx_None);       // activesound
    flags: MF_SPECIAL;                // flags
    flags_ex: 0;                      // flags_ex
    raisestate: Ord(S_NULL);          // raisestate
    customsound1: 0;                  // customsound1
    customsound2: 0;                  // customsound2
    customsound3: 0;                  // customsound3
    explosiondamage: 0;               // explosiondamage
    explosionradius: 0;               // explosionradius
    meleedamage: 0;                   // meleedamage
    scale: FRACUNIT;                  // scale
   ),
   (    // MT_MISC18
    name: 'Rocket ammo';              // name
    inheritsfrom: -1;                 // inheritsfrom
    doomednum: 2010;                  // doomednum
    spawnstate: Ord(S_ROCK);          // spawnstate
    spawnhealth: 1000;                // spawnhealth
    seestate: Ord(S_NULL);            // seestate
    seesound: Ord(sfx_None);          // seesound
    reactiontime: 8;                  // reactiontime
    attacksound: Ord(sfx_None);       // attacksound
    painstate: Ord(S_NULL);           // painstate
    painchance: 0;                    // painchance
    painsound: Ord(sfx_None);         // painsound
    meleestate: Ord(S_NULL);          // meleestate
    missilestate: Ord(S_NULL);        // missilestate
    deathstate: Ord(S_NULL);          // deathstate
    xdeathstate: Ord(S_NULL);         // xdeathstate
    deathsound: Ord(sfx_None);        // deathsound
    speed: 0;                         // speed
    radius: 20 * FRACUNIT;            // radius
    height: 16 * FRACUNIT;            // height
    mass: 100;                        // mass
    damage: 0;                        // damage
    activesound: Ord(sfx_None);       // activesound
    flags: MF_SPECIAL;                // flags
    flags_ex: 0;                      // flags_ex
    raisestate: Ord(S_NULL);          // raisestate
    customsound1: 0;                  // customsound1
    customsound2: 0;                  // customsound2
    customsound3: 0;                  // customsound3
    explosiondamage: 0;               // explosiondamage
    explosionradius: 0;               // explosionradius
    meleedamage: 0;                   // meleedamage
    scale: FRACUNIT;                  // scale
   ),
   (    // MT_MISC19
    name: 'Box of Rockets';           // name
    inheritsfrom: -1;                 // inheritsfrom
    doomednum: 2046;                  // doomednum
    spawnstate: Ord(S_BROK);          // spawnstate
    spawnhealth: 1000;                // spawnhealth
    seestate: Ord(S_NULL);            // seestate
    seesound: Ord(sfx_None);          // seesound
    reactiontime: 8;                  // reactiontime
    attacksound: Ord(sfx_None);       // attacksound
    painstate: Ord(S_NULL);           // painstate
    painchance: 0;                    // painchance
    painsound: Ord(sfx_None);         // painsound
    meleestate: Ord(S_NULL);          // meleestate
    missilestate: Ord(S_NULL);        // missilestate
    deathstate: Ord(S_NULL);          // deathstate
    xdeathstate: Ord(S_NULL);         // xdeathstate
    deathsound: Ord(sfx_None);        // deathsound
    speed: 0;                         // speed
    radius: 20 * FRACUNIT;            // radius
    height: 16 * FRACUNIT;            // height
    mass: 100;                        // mass
    damage: 0;                        // damage
    activesound: Ord(sfx_None);       // activesound
    flags: MF_SPECIAL;                // flags
    flags_ex: 0;                      // flags_ex
    raisestate: Ord(S_NULL);          // raisestate
    customsound1: 0;                  // customsound1
    customsound2: 0;                  // customsound2
    customsound3: 0;                  // customsound3
    explosiondamage: 0;               // explosiondamage
    explosionradius: 0;               // explosionradius
    meleedamage: 0;                   // meleedamage
    scale: FRACUNIT;                  // scale
   ),
   (    // MT_MISC20
    name: 'Energy Cell';              // name
    inheritsfrom: -1;                 // inheritsfrom
    doomednum: 2047;                  // doomednum
    spawnstate: Ord(S_CELL);          // spawnstate
    spawnhealth: 1000;                // spawnhealth
    seestate: Ord(S_NULL);            // seestate
    seesound: Ord(sfx_None);          // seesound
    reactiontime: 8;                  // reactiontime
    attacksound: Ord(sfx_None);       // attacksound
    painstate: Ord(S_NULL);           // painstate
    painchance: 0;                    // painchance
    painsound: Ord(sfx_None);         // painsound
    meleestate: Ord(S_NULL);          // meleestate
    missilestate: Ord(S_NULL);        // missilestate
    deathstate: Ord(S_NULL);          // deathstate
    xdeathstate: Ord(S_NULL);         // xdeathstate
    deathsound: Ord(sfx_None);        // deathsound
    speed: 0;                         // speed
    radius: 20 * FRACUNIT;            // radius
    height: 16 * FRACUNIT;            // height
    mass: 100;                        // mass
    damage: 0;                        // damage
    activesound: Ord(sfx_None);       // activesound
    flags: MF_SPECIAL;                // flags
    flags_ex: 0;                      // flags_ex
    raisestate: Ord(S_NULL);          // raisestate
    customsound1: 0;                  // customsound1
    customsound2: 0;                  // customsound2
    customsound3: 0;                  // customsound3
    explosiondamage: 0;               // explosiondamage
    explosionradius: 0;               // explosionradius
    meleedamage: 0;                   // meleedamage
    scale: FRACUNIT;                  // scale
   ),
   (    // MT_MISC21
    name: 'Energy Pack';              // name
    inheritsfrom: -1;                 // inheritsfrom
    doomednum: 17;                    // doomednum
    spawnstate: Ord(S_CELP);          // spawnstate
    spawnhealth: 1000;                // spawnhealth
    seestate: Ord(S_NULL);            // seestate
    seesound: Ord(sfx_None);          // seesound
    reactiontime: 8;                  // reactiontime
    attacksound: Ord(sfx_None);       // attacksound
    painstate: Ord(S_NULL);           // painstate
    painchance: 0;                    // painchance
    painsound: Ord(sfx_None);         // painsound
    meleestate: Ord(S_NULL);          // meleestate
    missilestate: Ord(S_NULL);        // missilestate
    deathstate: Ord(S_NULL);          // deathstate
    xdeathstate: Ord(S_NULL);         // xdeathstate
    deathsound: Ord(sfx_None);        // deathsound
    speed: 0;                         // speed
    radius: 20 * FRACUNIT;            // radius
    height: 16 * FRACUNIT;            // height
    mass: 100;                        // mass
    damage: 0;                        // damage
    activesound: Ord(sfx_None);       // activesound
    flags: MF_SPECIAL;                // flags
    flags_ex: 0;                      // flags_ex
    raisestate: Ord(S_NULL);          // raisestate
    customsound1: 0;                  // customsound1
    customsound2: 0;                  // customsound2
    customsound3: 0;                  // customsound3
    explosiondamage: 0;               // explosiondamage
    explosionradius: 0;               // explosionradius
    meleedamage: 0;                   // meleedamage
    scale: FRACUNIT;                  // scale
   ),
   (    // MT_MISC22
    name: 'Shells';                   // name
    inheritsfrom: -1;                 // inheritsfrom
    doomednum: 2008;                  // doomednum
    spawnstate: Ord(S_SHEL);          // spawnstate
    spawnhealth: 1000;                // spawnhealth
    seestate: Ord(S_NULL);            // seestate
    seesound: Ord(sfx_None);          // seesound
    reactiontime: 8;                  // reactiontime
    attacksound: Ord(sfx_None);       // attacksound
    painstate: Ord(S_NULL);           // painstate
    painchance: 0;                    // painchance
    painsound: Ord(sfx_None);         // painsound
    meleestate: Ord(S_NULL);          // meleestate
    missilestate: Ord(S_NULL);        // missilestate
    deathstate: Ord(S_NULL);          // deathstate
    xdeathstate: Ord(S_NULL);         // xdeathstate
    deathsound: Ord(sfx_None);        // deathsound
    speed: 0;                         // speed
    radius: 20 * FRACUNIT;            // radius
    height: 16 * FRACUNIT;            // height
    mass: 100;                        // mass
    damage: 0;                        // damage
    activesound: Ord(sfx_None);       // activesound
    flags: MF_SPECIAL;                // flags
    flags_ex: 0;                      // flags_ex
    raisestate: Ord(S_NULL);          // raisestate
    customsound1: 0;                  // customsound1
    customsound2: 0;                  // customsound2
    customsound3: 0;                  // customsound3
    explosiondamage: 0;               // explosiondamage
    explosionradius: 0;               // explosionradius
    meleedamage: 0;                   // meleedamage
    scale: FRACUNIT;                  // scale
   ),
   (    // MT_MISC23
    name: 'Box of Shells';            // name
    inheritsfrom: -1;                 // inheritsfrom
    doomednum: 2049;                  // doomednum
    spawnstate: Ord(S_SBOX);          // spawnstate
    spawnhealth: 1000;                // spawnhealth
    seestate: Ord(S_NULL);            // seestate
    seesound: Ord(sfx_None);          // seesound
    reactiontime: 8;                  // reactiontime
    attacksound: Ord(sfx_None);       // attacksound
    painstate: Ord(S_NULL);           // painstate
    painchance: 0;                    // painchance
    painsound: Ord(sfx_None);         // painsound
    meleestate: Ord(S_NULL);          // meleestate
    missilestate: Ord(S_NULL);        // missilestate
    deathstate: Ord(S_NULL);          // deathstate
    xdeathstate: Ord(S_NULL);         // xdeathstate
    deathsound: Ord(sfx_None);        // deathsound
    speed: 0;                         // speed
    radius: 20 * FRACUNIT;            // radius
    height: 16 * FRACUNIT;            // height
    mass: 100;                        // mass
    damage: 0;                        // damage
    activesound: Ord(sfx_None);       // activesound
    flags: MF_SPECIAL;                // flags
    flags_ex: 0;                      // flags_ex
    raisestate: Ord(S_NULL);          // raisestate
    customsound1: 0;                  // customsound1
    customsound2: 0;                  // customsound2
    customsound3: 0;                  // customsound3
    explosiondamage: 0;               // explosiondamage
    explosionradius: 0;               // explosionradius
    meleedamage: 0;                   // meleedamage
    scale: FRACUNIT;                  // scale
   ),
   (    // MT_MISC24
    name: 'Backpack';                 // name
    inheritsfrom: -1;                 // inheritsfrom
    doomednum: 8;                     // doomednum
    spawnstate: Ord(S_BPAK);          // spawnstate
    spawnhealth: 1000;                // spawnhealth
    seestate: Ord(S_NULL);            // seestate
    seesound: Ord(sfx_None);          // seesound
    reactiontime: 8;                  // reactiontime
    attacksound: Ord(sfx_None);       // attacksound
    painstate: Ord(S_NULL);           // painstate
    painchance: 0;                    // painchance
    painsound: Ord(sfx_None);         // painsound
    meleestate: Ord(S_NULL);          // meleestate
    missilestate: Ord(S_NULL);        // missilestate
    deathstate: Ord(S_NULL);          // deathstate
    xdeathstate: Ord(S_NULL);         // xdeathstate
    deathsound: Ord(sfx_None);        // deathsound
    speed: 0;                         // speed
    radius: 20 * FRACUNIT;            // radius
    height: 16 * FRACUNIT;            // height
    mass: 100;                        // mass
    damage: 0;                        // damage
    activesound: Ord(sfx_None);       // activesound
    flags: MF_SPECIAL;                // flags
    flags_ex: 0;                      // flags_ex
    raisestate: Ord(S_NULL);          // raisestate
    customsound1: 0;                  // customsound1
    customsound2: 0;                  // customsound2
    customsound3: 0;                  // customsound3
    explosiondamage: 0;               // explosiondamage
    explosionradius: 0;               // explosionradius
    meleedamage: 0;                   // meleedamage
    scale: FRACUNIT;                  // scale
   ),
   (    // MT_MISC25
    name: 'BFG 9000';                 // name
    inheritsfrom: -1;                 // inheritsfrom
    doomednum: 2006;                  // doomednum
    spawnstate: Ord(S_BFUG);          // spawnstate
    spawnhealth: 1000;                // spawnhealth
    seestate: Ord(S_NULL);            // seestate
    seesound: Ord(sfx_None);          // seesound
    reactiontime: 8;                  // reactiontime
    attacksound: Ord(sfx_None);       // attacksound
    painstate: Ord(S_NULL);           // painstate
    painchance: 0;                    // painchance
    painsound: Ord(sfx_None);         // painsound
    meleestate: Ord(S_NULL);          // meleestate
    missilestate: Ord(S_NULL);        // missilestate
    deathstate: Ord(S_NULL);          // deathstate
    xdeathstate: Ord(S_NULL);         // xdeathstate
    deathsound: Ord(sfx_None);        // deathsound
    speed: 0;                         // speed
    radius: 20 * FRACUNIT;            // radius
    height: 16 * FRACUNIT;            // height
    mass: 100;                        // mass
    damage: 0;                        // damage
    activesound: Ord(sfx_None);       // activesound
    flags: MF_SPECIAL;                // flags
    flags_ex: 0;                      // flags_ex
    raisestate: Ord(S_NULL);          // raisestate
    customsound1: 0;                  // customsound1
    customsound2: 0;                  // customsound2
    customsound3: 0;                  // customsound3
    explosiondamage: 0;               // explosiondamage
    explosionradius: 0;               // explosionradius
    meleedamage: 0;                   // meleedamage
    scale: FRACUNIT;                  // scale
   ),
   (    // MT_CHAINGUN
    name: 'Chaingun';                 // name
    inheritsfrom: -1;                 // inheritsfrom
    doomednum: 2002;                  // doomednum
    spawnstate: Ord(S_MGUN);          // spawnstate
    spawnhealth: 1000;                // spawnhealth
    seestate: Ord(S_NULL);            // seestate
    seesound: Ord(sfx_None);          // seesound
    reactiontime: 8;                  // reactiontime
    attacksound: Ord(sfx_None);       // attacksound
    painstate: Ord(S_NULL);           // painstate
    painchance: 0;                    // painchance
    painsound: Ord(sfx_None);         // painsound
    meleestate: Ord(S_NULL);          // meleestate
    missilestate: Ord(S_NULL);        // missilestate
    deathstate: Ord(S_NULL);          // deathstate
    xdeathstate: Ord(S_NULL);         // xdeathstate
    deathsound: Ord(sfx_None);        // deathsound
    speed: 0;                         // speed
    radius: 20 * FRACUNIT;            // radius
    height: 16 * FRACUNIT;            // height
    mass: 100;                        // mass
    damage: 0;                        // damage
    activesound: Ord(sfx_None);       // activesound
    flags: MF_SPECIAL;                // flags
    flags_ex: 0;                      // flags_ex
    raisestate: Ord(S_NULL);          // raisestate
    customsound1: 0;                  // customsound1
    customsound2: 0;                  // customsound2
    customsound3: 0;                  // customsound3
    explosiondamage: 0;               // explosiondamage
    explosionradius: 0;               // explosionradius
    meleedamage: 0;                   // meleedamage
    scale: FRACUNIT;                  // scale
   ),
   (    // MT_MISC26
    name: 'Chainsaw';                 // name
    inheritsfrom: -1;                 // inheritsfrom
    doomednum: 2005;                  // doomednum
    spawnstate: Ord(S_CSAW);          // spawnstate
    spawnhealth: 1000;                // spawnhealth
    seestate: Ord(S_NULL);            // seestate
    seesound: Ord(sfx_None);          // seesound
    reactiontime: 8;                  // reactiontime
    attacksound: Ord(sfx_None);       // attacksound
    painstate: Ord(S_NULL);           // painstate
    painchance: 0;                    // painchance
    painsound: Ord(sfx_None);         // painsound
    meleestate: Ord(S_NULL);          // meleestate
    missilestate: Ord(S_NULL);        // missilestate
    deathstate: Ord(S_NULL);          // deathstate
    xdeathstate: Ord(S_NULL);         // xdeathstate
    deathsound: Ord(sfx_None);        // deathsound
    speed: 0;                         // speed
    radius: 20 * FRACUNIT;            // radius
    height: 16 * FRACUNIT;            // height
    mass: 100;                        // mass
    damage: 0;                        // damage
    activesound: Ord(sfx_None);       // activesound
    flags: MF_SPECIAL;                // flags
    flags_ex: 0;                      // flags_ex
    raisestate: Ord(S_NULL);          // raisestate
    customsound1: 0;                  // customsound1
    customsound2: 0;                  // customsound2
    customsound3: 0;                  // customsound3
    explosiondamage: 0;               // explosiondamage
    explosionradius: 0;               // explosionradius
    meleedamage: 0;                   // meleedamage
    scale: FRACUNIT;                  // scale
   ),
   (    // MT_MISC27
    name: 'Rocket Launcher';          // name
    inheritsfrom: -1;                 // inheritsfrom
    doomednum: 2003;                  // doomednum
    spawnstate: Ord(S_LAUN);          // spawnstate
    spawnhealth: 1000;                // spawnhealth
    seestate: Ord(S_NULL);            // seestate
    seesound: Ord(sfx_None);          // seesound
    reactiontime: 8;                  // reactiontime
    attacksound: Ord(sfx_None);       // attacksound
    painstate: Ord(S_NULL);           // painstate
    painchance: 0;                    // painchance
    painsound: Ord(sfx_None);         // painsound
    meleestate: Ord(S_NULL);          // meleestate
    missilestate: Ord(S_NULL);        // missilestate
    deathstate: Ord(S_NULL);          // deathstate
    xdeathstate: Ord(S_NULL);         // xdeathstate
    deathsound: Ord(sfx_None);        // deathsound
    speed: 0;                         // speed
    radius: 20 * FRACUNIT;            // radius
    height: 16 * FRACUNIT;            // height
    mass: 100;                        // mass
    damage: 0;                        // damage
    activesound: Ord(sfx_None);       // activesound
    flags: MF_SPECIAL;                // flags
    flags_ex: 0;                      // flags_ex
    raisestate: Ord(S_NULL);          // raisestate
    customsound1: 0;                  // customsound1
    customsound2: 0;                  // customsound2
    customsound3: 0;                  // customsound3
    explosiondamage: 0;               // explosiondamage
    explosionradius: 0;               // explosionradius
    meleedamage: 0;                   // meleedamage
    scale: FRACUNIT;                  // scale
   ),
   (    // MT_MISC28
    name: 'Plasma Gun';               // name
    inheritsfrom: -1;                 // inheritsfrom
    doomednum: 2004;                  // doomednum
    spawnstate: Ord(S_PLAS);          // spawnstate
    spawnhealth: 1000;                // spawnhealth
    seestate: Ord(S_NULL);            // seestate
    seesound: Ord(sfx_None);          // seesound
    reactiontime: 8;                  // reactiontime
    attacksound: Ord(sfx_None);       // attacksound
    painstate: Ord(S_NULL);           // painstate
    painchance: 0;                    // painchance
    painsound: Ord(sfx_None);         // painsound
    meleestate: Ord(S_NULL);          // meleestate
    missilestate: Ord(S_NULL);        // missilestate
    deathstate: Ord(S_NULL);          // deathstate
    xdeathstate: Ord(S_NULL);         // xdeathstate
    deathsound: Ord(sfx_None);        // deathsound
    speed: 0;                         // speed
    radius: 20 * FRACUNIT;            // radius
    height: 16 * FRACUNIT;            // height
    mass: 100;                        // mass
    damage: 0;                        // damage
    activesound: Ord(sfx_None);       // activesound
    flags: MF_SPECIAL;                // flags
    flags_ex: 0;                      // flags_ex
    raisestate: Ord(S_NULL);          // raisestate
    customsound1: 0;                  // customsound1
    customsound2: 0;                  // customsound2
    customsound3: 0;                  // customsound3
    explosiondamage: 0;               // explosiondamage
    explosionradius: 0;               // explosionradius
    meleedamage: 0;                   // meleedamage
    scale: FRACUNIT;                  // scale
   ),
   (    // MT_SHOTGUN
    name: 'Shotgun';                  // name
    inheritsfrom: -1;                 // inheritsfrom
    doomednum: 2001;                  // doomednum
    spawnstate: Ord(S_SHOT);          // spawnstate
    spawnhealth: 1000;                // spawnhealth
    seestate: Ord(S_NULL);            // seestate
    seesound: Ord(sfx_None);          // seesound
    reactiontime: 8;                  // reactiontime
    attacksound: Ord(sfx_None);       // attacksound
    painstate: Ord(S_NULL);           // painstate
    painchance: 0;                    // painchance
    painsound: Ord(sfx_None);         // painsound
    meleestate: Ord(S_NULL);          // meleestate
    missilestate: Ord(S_NULL);        // missilestate
    deathstate: Ord(S_NULL);          // deathstate
    xdeathstate: Ord(S_NULL);         // xdeathstate
    deathsound: Ord(sfx_None);        // deathsound
    speed: 0;                         // speed
    radius: 20 * FRACUNIT;            // radius
    height: 16 * FRACUNIT;            // height
    mass: 100;                        // mass
    damage: 0;                        // damage
    activesound: Ord(sfx_None);       // activesound
    flags: MF_SPECIAL;                // flags
    flags_ex: 0;                      // flags_ex
    raisestate: Ord(S_NULL);          // raisestate
    customsound1: 0;                  // customsound1
    customsound2: 0;                  // customsound2
    customsound3: 0;                  // customsound3
    explosiondamage: 0;               // explosiondamage
    explosionradius: 0;               // explosionradius
    meleedamage: 0;                   // meleedamage
    scale: FRACUNIT;                  // scale
   ),
   (    // MT_SUPERSHOTGUN
    name: 'Super Shotgun';            // name
    inheritsfrom: -1;                 // inheritsfrom
    doomednum: 82;                    // doomednum
    spawnstate: Ord(S_SHOT2);         // spawnstate
    spawnhealth: 1000;                // spawnhealth
    seestate: Ord(S_NULL);            // seestate
    seesound: Ord(sfx_None);          // seesound
    reactiontime: 8;                  // reactiontime
    attacksound: Ord(sfx_None);       // attacksound
    painstate: Ord(S_NULL);           // painstate
    painchance: 0;                    // painchance
    painsound: Ord(sfx_None);         // painsound
    meleestate: Ord(S_NULL);          // meleestate
    missilestate: Ord(S_NULL);        // missilestate
    deathstate: Ord(S_NULL);          // deathstate
    xdeathstate: Ord(S_NULL);         // xdeathstate
    deathsound: Ord(sfx_None);        // deathsound
    speed: 0;                         // speed
    radius: 20 * FRACUNIT;            // radius
    height: 16 * FRACUNIT;            // height
    mass: 100;                        // mass
    damage: 0;                        // damage
    activesound: Ord(sfx_None);       // activesound
    flags: MF_SPECIAL;                // flags
    flags_ex: 0;                      // flags_ex
    raisestate: Ord(S_NULL);          // raisestate
    customsound1: 0;                  // customsound1
    customsound2: 0;                  // customsound2
    customsound3: 0;                  // customsound3
    explosiondamage: 0;               // explosiondamage
    explosionradius: 0;               // explosionradius
    meleedamage: 0;                   // meleedamage
    scale: FRACUNIT;                  // scale
   ),
   (    // MT_MISC29
    name: 'Tall Lamp';                // name
    inheritsfrom: -1;                 // inheritsfrom
    doomednum: 85;                    // doomednum
    spawnstate: Ord(S_TECHLAMP);      // spawnstate
    spawnhealth: 1000;                // spawnhealth
    seestate: Ord(S_NULL);            // seestate
    seesound: Ord(sfx_None);          // seesound
    reactiontime: 8;                  // reactiontime
    attacksound: Ord(sfx_None);       // attacksound
    painstate: Ord(S_NULL);           // painstate
    painchance: 0;                    // painchance
    painsound: Ord(sfx_None);         // painsound
    meleestate: Ord(S_NULL);          // meleestate
    missilestate: Ord(S_NULL);        // missilestate
    deathstate: Ord(S_NULL);          // deathstate
    xdeathstate: Ord(S_NULL);         // xdeathstate
    deathsound: Ord(sfx_None);        // deathsound
    speed: 0;                         // speed
    radius: 16 * FRACUNIT;            // radius
    height: 16 * FRACUNIT;            // height
    mass: 100;                        // mass
    damage: 0;                        // damage
    activesound: Ord(sfx_None);       // activesound
    flags: MF_SOLID;                  // flags
    flags_ex: MF_EX_WHITELIGHT;       // flags_ex
    raisestate: Ord(S_NULL);          // raisestate
    customsound1: 0;                  // customsound1
    customsound2: 0;                  // customsound2
    customsound3: 0;                  // customsound3
    explosiondamage: 0;               // explosiondamage
    explosionradius: 0;               // explosionradius
    meleedamage: 0;                   // meleedamage
    scale: FRACUNIT;                  // scale
   ),
   (    // MT_MISC30
    name: 'Tall Lamp 2';              // name
    inheritsfrom: -1;                 // inheritsfrom
    doomednum: 86;                    // doomednum
    spawnstate: Ord(S_TECH2LAMP);     // spawnstate
    spawnhealth: 1000;                // spawnhealth
    seestate: Ord(S_NULL);            // seestate
    seesound: Ord(sfx_None);          // seesound
    reactiontime: 8;                  // reactiontime
    attacksound: Ord(sfx_None);       // attacksound
    painstate: Ord(S_NULL);           // painstate
    painchance: 0;                    // painchance
    painsound: Ord(sfx_None);         // painsound
    meleestate: Ord(S_NULL);          // meleestate
    missilestate: Ord(S_NULL);        // missilestate
    deathstate: Ord(S_NULL);          // deathstate
    xdeathstate: Ord(S_NULL);         // xdeathstate
    deathsound: Ord(sfx_None);        // deathsound
    speed: 0;                         // speed
    radius: 16 * FRACUNIT;            // radius
    height: 16 * FRACUNIT;            // height
    mass: 100;                        // mass
    damage: 0;                        // damage
    activesound: Ord(sfx_None);       // activesound
    flags: MF_SOLID;                  // flags
    flags_ex: MF_EX_WHITELIGHT;       // flags_ex
    raisestate: Ord(S_NULL);          // raisestate
    customsound1: 0;                  // customsound1
    customsound2: 0;                  // customsound2
    customsound3: 0;                  // customsound3
    explosiondamage: 0;               // explosiondamage
    explosionradius: 0;               // explosionradius
    meleedamage: 0;                   // meleedamage
    scale: FRACUNIT;                  // scale
   ),
   (    // MT_MISC31
    name: 'Short Lamp';               // name
    inheritsfrom: -1;                 // inheritsfrom
    doomednum: 2028;                  // doomednum
    spawnstate: Ord(S_COLU);          // spawnstate
    spawnhealth: 1000;                // spawnhealth
    seestate: Ord(S_NULL);            // seestate
    seesound: Ord(sfx_None);          // seesound
    reactiontime: 8;                  // reactiontime
    attacksound: Ord(sfx_None);       // attacksound
    painstate: Ord(S_NULL);           // painstate
    painchance: 0;                    // painchance
    painsound: Ord(sfx_None);         // painsound
    meleestate: Ord(S_NULL);          // meleestate
    missilestate: Ord(S_NULL);        // missilestate
    deathstate: Ord(S_NULL);          // deathstate
    xdeathstate: Ord(S_NULL);         // xdeathstate
    deathsound: Ord(sfx_None);        // deathsound
    speed: 0;                         // speed
    radius: 16 * FRACUNIT;            // radius
    height: 16 * FRACUNIT;            // height
    mass: 100;                        // mass
    damage: 0;                        // damage
    activesound: Ord(sfx_None);       // activesound
    flags: MF_SOLID;                  // flags
    flags_ex: MF_EX_WHITELIGHT;       // flags_ex
    raisestate: Ord(S_NULL);          // raisestate
    customsound1: 0;                  // customsound1
    customsound2: 0;                  // customsound2
    customsound3: 0;                  // customsound3
    explosiondamage: 0;               // explosiondamage
    explosionradius: 0;               // explosionradius
    meleedamage: 0;                   // meleedamage
    scale: FRACUNIT;                  // scale
   ),
   (    // MT_MISC32
    name: 'Tall Gr. Pillar';          // name
    inheritsfrom: -1;                 // inheritsfrom
    doomednum: 30;                    // doomednum
    spawnstate: Ord(S_TALLGRNCOL);    // spawnstate
    spawnhealth: 1000;                // spawnhealth
    seestate: Ord(S_NULL);            // seestate
    seesound: Ord(sfx_None);          // seesound
    reactiontime: 8;                  // reactiontime
    attacksound: Ord(sfx_None);       // attacksound
    painstate: Ord(S_NULL);           // painstate
    painchance: 0;                    // painchance
    painsound: Ord(sfx_None);         // painsound
    meleestate: Ord(S_NULL);          // meleestate
    missilestate: Ord(S_NULL);        // missilestate
    deathstate: Ord(S_NULL);          // deathstate
    xdeathstate: Ord(S_NULL);         // xdeathstate
    deathsound: Ord(sfx_None);        // deathsound
    speed: 0;                         // speed
    radius: 16 * FRACUNIT;            // radius
    height: 16 * FRACUNIT;            // height
    mass: 100;                        // mass
    damage: 0;                        // damage
    activesound: Ord(sfx_None);       // activesound
    flags: MF_SOLID;                  // flags
    flags_ex: 0;                      // flags_ex
    raisestate: Ord(S_NULL);          // raisestate
    customsound1: 0;                  // customsound1
    customsound2: 0;                  // customsound2
    customsound3: 0;                  // customsound3
    explosiondamage: 0;               // explosiondamage
    explosionradius: 0;               // explosionradius
    meleedamage: 0;                   // meleedamage
    scale: FRACUNIT;                  // scale
   ),
   (    // MT_MISC33
    name: 'Short Gr. Pillar';         // name
    inheritsfrom: -1;                 // inheritsfrom
    doomednum: 31;                    // doomednum
    spawnstate: Ord(S_SHRTGRNCOL);    // spawnstate
    spawnhealth: 1000;                // spawnhealth
    seestate: Ord(S_NULL);            // seestate
    seesound: Ord(sfx_None);          // seesound
    reactiontime: 8;                  // reactiontime
    attacksound: Ord(sfx_None);       // attacksound
    painstate: Ord(S_NULL);           // painstate
    painchance: 0;                    // painchance
    painsound: Ord(sfx_None);         // painsound
    meleestate: Ord(S_NULL);          // meleestate
    missilestate: Ord(S_NULL);        // missilestate
    deathstate: Ord(S_NULL);          // deathstate
    xdeathstate: Ord(S_NULL);         // xdeathstate
    deathsound: Ord(sfx_None);        // deathsound
    speed: 0;                         // speed
    radius: 16 * FRACUNIT;            // radius
    height: 16 * FRACUNIT;            // height
    mass: 100;                        // mass
    damage: 0;                        // damage
    activesound: Ord(sfx_None);       // activesound
    flags: MF_SOLID;                  // flags
    flags_ex: 0;                      // flags_ex
    raisestate: Ord(S_NULL);          // raisestate
    customsound1: 0;                  // customsound1
    customsound2: 0;                  // customsound2
    customsound3: 0;                  // customsound3
    explosiondamage: 0;               // explosiondamage
    explosionradius: 0;               // explosionradius
    meleedamage: 0;                   // meleedamage
    scale: FRACUNIT;                  // scale
   ),
   (    // MT_MISC34
    name: 'Tall Red Pillar';          // name
    inheritsfrom: -1;                 // inheritsfrom
    doomednum: 32;                    // doomednum
    spawnstate: Ord(S_TALLREDCOL);    // spawnstate
    spawnhealth: 1000;                // spawnhealth
    seestate: Ord(S_NULL);            // seestate
    seesound: Ord(sfx_None);          // seesound
    reactiontime: 8;                  // reactiontime
    attacksound: Ord(sfx_None);       // attacksound
    painstate: Ord(S_NULL);           // painstate
    painchance: 0;                    // painchance
    painsound: Ord(sfx_None);         // painsound
    meleestate: Ord(S_NULL);          // meleestate
    missilestate: Ord(S_NULL);        // missilestate
    deathstate: Ord(S_NULL);          // deathstate
    xdeathstate: Ord(S_NULL);         // xdeathstate
    deathsound: Ord(sfx_None);        // deathsound
    speed: 0;                         // speed
    radius: 16 * FRACUNIT;            // radius
    height: 16 * FRACUNIT;            // height
    mass: 100;                        // mass
    damage: 0;                        // damage
    activesound: Ord(sfx_None);       // activesound
    flags: MF_SOLID;                  // flags
    flags_ex: 0;                      // flags_ex
    raisestate: Ord(S_NULL);          // raisestate
    customsound1: 0;                  // customsound1
    customsound2: 0;                  // customsound2
    customsound3: 0;                  // customsound3
    explosiondamage: 0;               // explosiondamage
    explosionradius: 0;               // explosionradius
    meleedamage: 0;                   // meleedamage
    scale: FRACUNIT;                  // scale
   ),
   (    // MT_MISC35
    name: 'Short Red Pillar';         // name
    inheritsfrom: -1;                 // inheritsfrom
    doomednum: 33;                    // doomednum
    spawnstate: Ord(S_SHRTREDCOL);    // spawnstate
    spawnhealth: 1000;                // spawnhealth
    seestate: Ord(S_NULL);            // seestate
    seesound: Ord(sfx_None);          // seesound
    reactiontime: 8;                  // reactiontime
    attacksound: Ord(sfx_None);       // attacksound
    painstate: Ord(S_NULL);           // painstate
    painchance: 0;                    // painchance
    painsound: Ord(sfx_None);         // painsound
    meleestate: Ord(S_NULL);          // meleestate
    missilestate: Ord(S_NULL);        // missilestate
    deathstate: Ord(S_NULL);          // deathstate
    xdeathstate: Ord(S_NULL);         // xdeathstate
    deathsound: Ord(sfx_None);        // deathsound
    speed: 0;                         // speed
    radius: 16 * FRACUNIT;            // radius
    height: 16 * FRACUNIT;            // height
    mass: 100;                        // mass
    damage: 0;                        // damage
    activesound: Ord(sfx_None);       // activesound
    flags: MF_SOLID;                  // flags
    flags_ex: 0;                      // flags_ex
    raisestate: Ord(S_NULL);          // raisestate
    customsound1: 0;                  // customsound1
    customsound2: 0;                  // customsound2
    customsound3: 0;                  // customsound3
    explosiondamage: 0;               // explosiondamage
    explosionradius: 0;               // explosionradius
    meleedamage: 0;                   // meleedamage
    scale: FRACUNIT;                  // scale
   ),
   (    // MT_MISC36
    name: 'Pillar w/Skull';           // name
    inheritsfrom: -1;                 // inheritsfrom
    doomednum: 37;                    // doomednum
    spawnstate: Ord(S_SKULLCOL);      // spawnstate
    spawnhealth: 1000;                // spawnhealth
    seestate: Ord(S_NULL);            // seestate
    seesound: Ord(sfx_None);          // seesound
    reactiontime: 8;                  // reactiontime
    attacksound: Ord(sfx_None);       // attacksound
    painstate: Ord(S_NULL);           // painstate
    painchance: 0;                    // painchance
    painsound: Ord(sfx_None);         // painsound
    meleestate: Ord(S_NULL);          // meleestate
    missilestate: Ord(S_NULL);        // missilestate
    deathstate: Ord(S_NULL);          // deathstate
    xdeathstate: Ord(S_NULL);         // xdeathstate
    deathsound: Ord(sfx_None);        // deathsound
    speed: 0;                         // speed
    radius: 16 * FRACUNIT;            // radius
    height: 16 * FRACUNIT;            // height
    mass: 100;                        // mass
    damage: 0;                        // damage
    activesound: Ord(sfx_None);       // activesound
    flags: MF_SOLID;                  // flags
    flags_ex: 0;                      // flags_ex
    raisestate: Ord(S_NULL);          // raisestate
    customsound1: 0;                  // customsound1
    customsound2: 0;                  // customsound2
    customsound3: 0;                  // customsound3
    explosiondamage: 0;               // explosiondamage
    explosionradius: 0;               // explosionradius
    meleedamage: 0;                   // meleedamage
    scale: FRACUNIT;                  // scale
   ),
   (    // MT_MISC37
    name: 'Pillar w/Heart';           // name
    inheritsfrom: -1;                 // inheritsfrom
    doomednum: 36;                    // doomednum
    spawnstate: Ord(S_HEARTCOL);      // spawnstate
    spawnhealth: 1000;                // spawnhealth
    seestate: Ord(S_NULL);            // seestate
    seesound: Ord(sfx_None);          // seesound
    reactiontime: 8;                  // reactiontime
    attacksound: Ord(sfx_None);       // attacksound
    painstate: Ord(S_NULL);           // painstate
    painchance: 0;                    // painchance
    painsound: Ord(sfx_None);         // painsound
    meleestate: Ord(S_NULL);          // meleestate
    missilestate: Ord(S_NULL);        // missilestate
    deathstate: Ord(S_NULL);          // deathstate
    xdeathstate: Ord(S_NULL);         // xdeathstate
    deathsound: Ord(sfx_None);        // deathsound
    speed: 0;                         // speed
    radius: 16 * FRACUNIT;            // radius
    height: 16 * FRACUNIT;            // height
    mass: 100;                        // mass
    damage: 0;                        // damage
    activesound: Ord(sfx_None);       // activesound
    flags: MF_SOLID;                  // flags
    flags_ex: 0;                      // flags_ex
    raisestate: Ord(S_NULL);          // raisestate
    customsound1: 0;                  // customsound1
    customsound2: 0;                  // customsound2
    customsound3: 0;                  // customsound3
    explosiondamage: 0;               // explosiondamage
    explosionradius: 0;               // explosionradius
    meleedamage: 0;                   // meleedamage
    scale: FRACUNIT;                  // scale
   ),
   (    // MT_MISC38
    name: 'Eye in Symbol';            // name
    inheritsfrom: -1;                 // inheritsfrom
    doomednum: 41;                    // doomednum
    spawnstate: Ord(S_EVILEYE);       // spawnstate
    spawnhealth: 1000;                // spawnhealth
    seestate: Ord(S_NULL);            // seestate
    seesound: Ord(sfx_None);          // seesound
    reactiontime: 8;                  // reactiontime
    attacksound: Ord(sfx_None);       // attacksound
    painstate: Ord(S_NULL);           // painstate
    painchance: 0;                    // painchance
    painsound: Ord(sfx_None);         // painsound
    meleestate: Ord(S_NULL);          // meleestate
    missilestate: Ord(S_NULL);        // missilestate
    deathstate: Ord(S_NULL);          // deathstate
    xdeathstate: Ord(S_NULL);         // xdeathstate
    deathsound: Ord(sfx_None);        // deathsound
    speed: 0;                         // speed
    radius: 16 * FRACUNIT;            // radius
    height: 16 * FRACUNIT;            // height
    mass: 100;                        // mass
    damage: 0;                        // damage
    activesound: Ord(sfx_None);       // activesound
    flags: MF_SOLID;                  // flags
    flags_ex: 0;                      // flags_ex
    raisestate: Ord(S_NULL);          // raisestate
    customsound1: 0;                  // customsound1
    customsound2: 0;                  // customsound2
    customsound3: 0;                  // customsound3
    explosiondamage: 0;               // explosiondamage
    explosionradius: 0;               // explosionradius
    meleedamage: 0;                   // meleedamage
    scale: FRACUNIT;                  // scale
   ),
   (    // MT_MISC39
    name: 'Flaming Skulls';           // name
    inheritsfrom: -1;                 // inheritsfrom
    doomednum: 42;                    // doomednum
    spawnstate: Ord(S_FLOATSKULL);    // spawnstate
    spawnhealth: 1000;                // spawnhealth
    seestate: Ord(S_NULL);            // seestate
    seesound: Ord(sfx_None);          // seesound
    reactiontime: 8;                  // reactiontime
    attacksound: Ord(sfx_None);       // attacksound
    painstate: Ord(S_NULL);           // painstate
    painchance: 0;                    // painchance
    painsound: Ord(sfx_None);         // painsound
    meleestate: Ord(S_NULL);          // meleestate
    missilestate: Ord(S_NULL);        // missilestate
    deathstate: Ord(S_NULL);          // deathstate
    xdeathstate: Ord(S_NULL);         // xdeathstate
    deathsound: Ord(sfx_None);        // deathsound
    speed: 0;                         // speed
    radius: 16 * FRACUNIT;            // radius
    height: 16 * FRACUNIT;            // height
    mass: 100;                        // mass
    damage: 0;                        // damage
    activesound: Ord(sfx_None);       // activesound
    flags: MF_SOLID;                  // flags
    flags_ex: 0;                      // flags_ex
    raisestate: Ord(S_NULL);          // raisestate
    customsound1: 0;                  // customsound1
    customsound2: 0;                  // customsound2
    customsound3: 0;                  // customsound3
    explosiondamage: 0;               // explosiondamage
    explosionradius: 0;               // explosionradius
    meleedamage: 0;                   // meleedamage
    scale: FRACUNIT;                  // scale
   ),
   (    // MT_MISC40
    name: 'Grey Tree';                // name
    inheritsfrom: -1;                 // inheritsfrom
    doomednum: 43;                    // doomednum
    spawnstate: Ord(S_TORCHTREE);     // spawnstate
    spawnhealth: 1000;                // spawnhealth
    seestate: Ord(S_NULL);            // seestate
    seesound: Ord(sfx_None);          // seesound
    reactiontime: 8;                  // reactiontime
    attacksound: Ord(sfx_None);       // attacksound
    painstate: Ord(S_NULL);           // painstate
    painchance: 0;                    // painchance
    painsound: Ord(sfx_None);         // painsound
    meleestate: Ord(S_NULL);          // meleestate
    missilestate: Ord(S_NULL);        // missilestate
    deathstate: Ord(S_NULL);          // deathstate
    xdeathstate: Ord(S_NULL);         // xdeathstate
    deathsound: Ord(sfx_None);        // deathsound
    speed: 0;                         // speed
    radius: 16 * FRACUNIT;            // radius
    height: 16 * FRACUNIT;            // height
    mass: 100;                        // mass
    damage: 0;                        // damage
    activesound: Ord(sfx_None);       // activesound
    flags: MF_SOLID;                  // flags
    flags_ex: 0;                      // flags_ex
    raisestate: Ord(S_NULL);          // raisestate
    customsound1: 0;                  // customsound1
    customsound2: 0;                  // customsound2
    customsound3: 0;                  // customsound3
    explosiondamage: 0;               // explosiondamage
    explosionradius: 0;               // explosionradius
    meleedamage: 0;                   // meleedamage
    scale: FRACUNIT;                  // scale
   ),
   (    // MT_MISC41
    name: 'Tall Blue Torch';          // name
    inheritsfrom: -1;                 // inheritsfrom
    doomednum: 44;                    // doomednum
    spawnstate: Ord(S_BLUETORCH);     // spawnstate
    spawnhealth: 1000;                // spawnhealth
    seestate: Ord(S_NULL);            // seestate
    seesound: Ord(sfx_None);          // seesound
    reactiontime: 8;                  // reactiontime
    attacksound: Ord(sfx_None);       // attacksound
    painstate: Ord(S_NULL);           // painstate
    painchance: 0;                    // painchance
    painsound: Ord(sfx_None);         // painsound
    meleestate: Ord(S_NULL);          // meleestate
    missilestate: Ord(S_NULL);        // missilestate
    deathstate: Ord(S_NULL);          // deathstate
    xdeathstate: Ord(S_NULL);         // xdeathstate
    deathsound: Ord(sfx_None);        // deathsound
    speed: 0;                         // speed
    radius: 16 * FRACUNIT;            // radius
    height: 16 * FRACUNIT;            // height
    mass: 100;                        // mass
    damage: 0;                        // damage
    activesound: Ord(sfx_None);       // activesound
    flags: MF_SOLID;                  // flags
    flags_ex: MF_EX_BLUELIGHT;        // flags_ex
    raisestate: Ord(S_NULL);          // raisestate
    customsound1: 0;                  // customsound1
    customsound2: 0;                  // customsound2
    customsound3: 0;                  // customsound3
    explosiondamage: 0;               // explosiondamage
    explosionradius: 0;               // explosionradius
    meleedamage: 0;                   // meleedamage
    scale: FRACUNIT;                  // scale
   ),
   (    // MT_MISC42
    name: 'Tall Green Torch';         // name
    inheritsfrom: -1;                 // inheritsfrom
    doomednum: 45;                    // doomednum
    spawnstate: Ord(S_GREENTORCH);    // spawnstate
    spawnhealth: 1000;                // spawnhealth
    seestate: Ord(S_NULL);            // seestate
    seesound: Ord(sfx_None);          // seesound
    reactiontime: 8;                  // reactiontime
    attacksound: Ord(sfx_None);       // attacksound
    painstate: Ord(S_NULL);           // painstate
    painchance: 0;                    // painchance
    painsound: Ord(sfx_None);         // painsound
    meleestate: Ord(S_NULL);          // meleestate
    missilestate: Ord(S_NULL);        // missilestate
    deathstate: Ord(S_NULL);          // deathstate
    xdeathstate: Ord(S_NULL);         // xdeathstate
    deathsound: Ord(sfx_None);        // deathsound
    speed: 0;                         // speed
    radius: 16 * FRACUNIT;            // radius
    height: 16 * FRACUNIT;            // height
    mass: 100;                        // mass
    damage: 0;                        // damage
    activesound: Ord(sfx_None);       // activesound
    flags: MF_SOLID;                  // flags
    flags_ex: MF_EX_GREENLIGHT;       // flags_ex
    raisestate: Ord(S_NULL);          // raisestate
    customsound1: 0;                  // customsound1
    customsound2: 0;                  // customsound2
    customsound3: 0;                  // customsound3
    explosiondamage: 0;               // explosiondamage
    explosionradius: 0;               // explosionradius
    meleedamage: 0;                   // meleedamage
    scale: FRACUNIT;                  // scale
   ),
   (    // MT_MISC43
    name: 'Tall Red Torch';           // name
    inheritsfrom: -1;                 // inheritsfrom
    doomednum: 46;                    // doomednum
    spawnstate: Ord(S_REDTORCH);      // spawnstate
    spawnhealth: 1000;                // spawnhealth
    seestate: Ord(S_NULL);            // seestate
    seesound: Ord(sfx_None);          // seesound
    reactiontime: 8;                  // reactiontime
    attacksound: Ord(sfx_None);       // attacksound
    painstate: Ord(S_NULL);           // painstate
    painchance: 0;                    // painchance
    painsound: Ord(sfx_None);         // painsound
    meleestate: Ord(S_NULL);          // meleestate
    missilestate: Ord(S_NULL);        // missilestate
    deathstate: Ord(S_NULL);          // deathstate
    xdeathstate: Ord(S_NULL);         // xdeathstate
    deathsound: Ord(sfx_None);        // deathsound
    speed: 0;                         // speed
    radius: 16 * FRACUNIT;            // radius
    height: 16 * FRACUNIT;            // height
    mass: 100;                        // mass
    damage: 0;                        // damage
    activesound: Ord(sfx_None);       // activesound
    flags: MF_SOLID;                  // flags
    flags_ex: MF_EX_REDLIGHT;        // flags_ex
    raisestate: Ord(S_NULL);          // raisestate
    customsound1: 0;                  // customsound1
    customsound2: 0;                  // customsound2
    customsound3: 0;                  // customsound3
    explosiondamage: 0;               // explosiondamage
    explosionradius: 0;               // explosionradius
    meleedamage: 0;                   // meleedamage
    scale: FRACUNIT;                  // scale
   ),
   (    // MT_MISC44
    name: 'Small Blue Torch';         // name
    inheritsfrom: -1;                 // inheritsfrom
    doomednum: 55;                    // doomednum
    spawnstate: Ord(S_BTORCHSHRT);    // spawnstate
    spawnhealth: 1000;                // spawnhealth
    seestate: Ord(S_NULL);            // seestate
    seesound: Ord(sfx_None);          // seesound
    reactiontime: 8;                  // reactiontime
    attacksound: Ord(sfx_None);       // attacksound
    painstate: Ord(S_NULL);           // painstate
    painchance: 0;                    // painchance
    painsound: Ord(sfx_None);         // painsound
    meleestate: Ord(S_NULL);          // meleestate
    missilestate: Ord(S_NULL);        // missilestate
    deathstate: Ord(S_NULL);          // deathstate
    xdeathstate: Ord(S_NULL);         // xdeathstate
    deathsound: Ord(sfx_None);        // deathsound
    speed: 0;                         // speed
    radius: 16 * FRACUNIT;            // radius
    height: 16 * FRACUNIT;            // height
    mass: 100;                        // mass
    damage: 0;                        // damage
    activesound: Ord(sfx_None);       // activesound
    flags: MF_SOLID;                  // flags
    flags_ex: MF_EX_BLUELIGHT;        // flags_ex
    raisestate: Ord(S_NULL);          // raisestate
    customsound1: 0;                  // customsound1
    customsound2: 0;                  // customsound2
    customsound3: 0;                  // customsound3
    explosiondamage: 0;               // explosiondamage
    explosionradius: 0;               // explosionradius
    meleedamage: 0;                   // meleedamage
    scale: FRACUNIT;                  // scale
   ),
   (    // MT_MISC45
    name: 'Small Gr. Torch';          // name
    inheritsfrom: -1;                 // inheritsfrom
    doomednum: 56;                    // doomednum
    spawnstate: Ord(S_GTORCHSHRT);    // spawnstate
    spawnhealth: 1000;                // spawnhealth
    seestate: Ord(S_NULL);            // seestate
    seesound: Ord(sfx_None);          // seesound
    reactiontime: 8;                  // reactiontime
    attacksound: Ord(sfx_None);       // attacksound
    painstate: Ord(S_NULL);           // painstate
    painchance: 0;                    // painchance
    painsound: Ord(sfx_None);         // painsound
    meleestate: Ord(S_NULL);          // meleestate
    missilestate: Ord(S_NULL);        // missilestate
    deathstate: Ord(S_NULL);          // deathstate
    xdeathstate: Ord(S_NULL);         // xdeathstate
    deathsound: Ord(sfx_None);        // deathsound
    speed: 0;                         // speed
    radius: 16 * FRACUNIT;            // radius
    height: 16 * FRACUNIT;            // height
    mass: 100;                        // mass
    damage: 0;                        // damage
    activesound: Ord(sfx_None);       // activesound
    flags: MF_SOLID;                  // flags
    flags_ex: MF_EX_GREENLIGHT;       // flags_ex
    raisestate: Ord(S_NULL);          // raisestate
    customsound1: 0;                  // customsound1
    customsound2: 0;                  // customsound2
    customsound3: 0;                  // customsound3
    explosiondamage: 0;               // explosiondamage
    explosionradius: 0;               // explosionradius
    meleedamage: 0;                   // meleedamage
    scale: FRACUNIT;                  // scale
   ),
   (    // MT_MISC46
    name: 'Small Red Torch';          // name
    inheritsfrom: -1;                 // inheritsfrom
    doomednum: 57;                    // doomednum
    spawnstate: Ord(S_RTORCHSHRT);    // spawnstate
    spawnhealth: 1000;                // spawnhealth
    seestate: Ord(S_NULL);            // seestate
    seesound: Ord(sfx_None);          // seesound
    reactiontime: 8;                  // reactiontime
    attacksound: Ord(sfx_None);       // attacksound
    painstate: Ord(S_NULL);           // painstate
    painchance: 0;                    // painchance
    painsound: Ord(sfx_None);         // painsound
    meleestate: Ord(S_NULL);          // meleestate
    missilestate: Ord(S_NULL);        // missilestate
    deathstate: Ord(S_NULL);          // deathstate
    xdeathstate: Ord(S_NULL);         // xdeathstate
    deathsound: Ord(sfx_None);        // deathsound
    speed: 0;                         // speed
    radius: 16 * FRACUNIT;            // radius
    height: 16 * FRACUNIT;            // height
    mass: 100;                        // mass
    damage: 0;                        // damage
    activesound: Ord(sfx_None);       // activesound
    flags: MF_SOLID;                  // flags
    flags_ex: MF_EX_REDLIGHT;         // flags_ex
    raisestate: Ord(S_NULL);          // raisestate
    customsound1: 0;                  // customsound1
    customsound2: 0;                  // customsound2
    customsound3: 0;                  // customsound3
    explosiondamage: 0;               // explosiondamage
    explosionradius: 0;               // explosionradius
    meleedamage: 0;                   // meleedamage
    scale: FRACUNIT;                  // scale
   ),
   (    // MT_MISC47
    name: 'Brown Stub';               // name
    inheritsfrom: -1;                 // inheritsfrom
    doomednum: 47;                    // doomednum
    spawnstate: Ord(S_STALAGTITE);    // spawnstate
    spawnhealth: 1000;                // spawnhealth
    seestate: Ord(S_NULL);            // seestate
    seesound: Ord(sfx_None);          // seesound
    reactiontime: 8;                  // reactiontime
    attacksound: Ord(sfx_None);       // attacksound
    painstate: Ord(S_NULL);           // painstate
    painchance: 0;                    // painchance
    painsound: Ord(sfx_None);         // painsound
    meleestate: Ord(S_NULL);          // meleestate
    missilestate: Ord(S_NULL);        // missilestate
    deathstate: Ord(S_NULL);          // deathstate
    xdeathstate: Ord(S_NULL);         // xdeathstate
    deathsound: Ord(sfx_None);        // deathsound
    speed: 0;                         // speed
    radius: 16 * FRACUNIT;            // radius
    height: 16 * FRACUNIT;            // height
    mass: 100;                        // mass
    damage: 0;                        // damage
    activesound: Ord(sfx_None);       // activesound
    flags: MF_SOLID;                  // flags
    flags_ex: 0;                      // flags_ex
    raisestate: Ord(S_NULL);          // raisestate
    customsound1: 0;                  // customsound1
    customsound2: 0;                  // customsound2
    customsound3: 0;                  // customsound3
    explosiondamage: 0;               // explosiondamage
    explosionradius: 0;               // explosionradius
    meleedamage: 0;                   // meleedamage
    scale: FRACUNIT;                  // scale
   ),
   (    // MT_MISC48
    name: 'Technical Column';         // name
    inheritsfrom: -1;                 // inheritsfrom
    doomednum: 48;                    // doomednum
    spawnstate: Ord(S_TECHPILLAR);    // spawnstate
    spawnhealth: 1000;                // spawnhealth
    seestate: Ord(S_NULL);            // seestate
    seesound: Ord(sfx_None);          // seesound
    reactiontime: 8;                  // reactiontime
    attacksound: Ord(sfx_None);       // attacksound
    painstate: Ord(S_NULL);           // painstate
    painchance: 0;                    // painchance
    painsound: Ord(sfx_None);         // painsound
    meleestate: Ord(S_NULL);          // meleestate
    missilestate: Ord(S_NULL);        // missilestate
    deathstate: Ord(S_NULL);          // deathstate
    xdeathstate: Ord(S_NULL);         // xdeathstate
    deathsound: Ord(sfx_None);        // deathsound
    speed: 0;                         // speed
    radius: 16 * FRACUNIT;            // radius
    height: 16 * FRACUNIT;            // height
    mass: 100;                        // mass
    damage: 0;                        // damage
    activesound: Ord(sfx_None);       // activesound
    flags: MF_SOLID;                  // flags
    flags_ex: 0;                      // flags_ex
    raisestate: Ord(S_NULL);          // raisestate
    customsound1: 0;                  // customsound1
    customsound2: 0;                  // customsound2
    customsound3: 0;                  // customsound3
    explosiondamage: 0;               // explosiondamage
    explosionradius: 0;               // explosionradius
    meleedamage: 0;                   // meleedamage
    scale: FRACUNIT;                  // scale
   ),
   (    // MT_MISC49
    name: 'Candle';                   // name
    inheritsfrom: -1;                 // inheritsfrom
    doomednum: 34;                    // doomednum
    spawnstate: Ord(S_CANDLESTIK);    // spawnstate
    spawnhealth: 1000;                // spawnhealth
    seestate: Ord(S_NULL);            // seestate
    seesound: Ord(sfx_None);          // seesound
    reactiontime: 8;                  // reactiontime
    attacksound: Ord(sfx_None);       // attacksound
    painstate: Ord(S_NULL);           // painstate
    painchance: 0;                    // painchance
    painsound: Ord(sfx_None);         // painsound
    meleestate: Ord(S_NULL);          // meleestate
    missilestate: Ord(S_NULL);        // missilestate
    deathstate: Ord(S_NULL);          // deathstate
    xdeathstate: Ord(S_NULL);         // xdeathstate
    deathsound: Ord(sfx_None);        // deathsound
    speed: 0;                         // speed
    radius: 20 * FRACUNIT;            // radius
    height: 16 * FRACUNIT;            // height
    mass: 100;                        // mass
    damage: 0;                        // damage
    activesound: Ord(sfx_None);       // activesound
    flags: 0;                         // flags
    flags_ex: MF_EX_WHITELIGHT;       // flags_ex
    raisestate: Ord(S_NULL);          // raisestate
    customsound1: 0;                  // customsound1
    customsound2: 0;                  // customsound2
    customsound3: 0;                  // customsound3
    explosiondamage: 0;               // explosiondamage
    explosionradius: 0;               // explosionradius
    meleedamage: 0;                   // meleedamage
    scale: FRACUNIT;                  // scale
   ),
   (    // MT_MISC50
    name: 'Candelabra';               // name
    inheritsfrom: -1;                 // inheritsfrom
    doomednum: 35;                    // doomednum
    spawnstate: Ord(S_CANDELABRA);    // spawnstate
    spawnhealth: 1000;                // spawnhealth
    seestate: Ord(S_NULL);            // seestate
    seesound: Ord(sfx_None);          // seesound
    reactiontime: 8;                  // reactiontime
    attacksound: Ord(sfx_None);       // attacksound
    painstate: Ord(S_NULL);           // painstate
    painchance: 0;                    // painchance
    painsound: Ord(sfx_None);         // painsound
    meleestate: Ord(S_NULL);          // meleestate
    missilestate: Ord(S_NULL);        // missilestate
    deathstate: Ord(S_NULL);          // deathstate
    xdeathstate: Ord(S_NULL);         // xdeathstate
    deathsound: Ord(sfx_None);        // deathsound
    speed: 0;                         // speed
    radius: 16 * FRACUNIT;            // radius
    height: 16 * FRACUNIT;            // height
    mass: 100;                        // mass
    damage: 0;                        // damage
    activesound: Ord(sfx_None);       // activesound
    flags: MF_SOLID;                  // flags
    flags_ex: MF_EX_YELLOWLIGHT;      // flags_ex
    raisestate: Ord(S_NULL);          // raisestate
    customsound1: 0;                  // customsound1
    customsound2: 0;                  // customsound2
    customsound3: 0;                  // customsound3
    explosiondamage: 0;               // explosiondamage
    explosionradius: 0;               // explosionradius
    meleedamage: 0;                   // meleedamage
    scale: FRACUNIT;                  // scale
   ),
   (    // MT_MISC51
    name: 'Swaying Body';             // name
    inheritsfrom: -1;                 // inheritsfrom
    doomednum: 49;                    // doomednum
    spawnstate: Ord(S_BLOODYTWITCH);    // spawnstate
    spawnhealth: 1000;                // spawnhealth
    seestate: Ord(S_NULL);            // seestate
    seesound: Ord(sfx_None);          // seesound
    reactiontime: 8;                  // reactiontime
    attacksound: Ord(sfx_None);       // attacksound
    painstate: Ord(S_NULL);           // painstate
    painchance: 0;                    // painchance
    painsound: Ord(sfx_None);         // painsound
    meleestate: Ord(S_NULL);          // meleestate
    missilestate: Ord(S_NULL);        // missilestate
    deathstate: Ord(S_NULL);          // deathstate
    xdeathstate: Ord(S_NULL);         // xdeathstate
    deathsound: Ord(sfx_None);        // deathsound
    speed: 0;                         // speed
    radius: 16 * FRACUNIT;            // radius
    height: 68 * FRACUNIT;            // height
    mass: 100;                        // mass
    damage: 0;                        // damage
    activesound: Ord(sfx_None);       // activesound
    flags: MF_SOLID or MF_SPAWNCEILING or MF_NOGRAVITY;    // flags
    flags_ex: 0;                      // flags_ex
    raisestate: Ord(S_NULL);          // raisestate
    customsound1: 0;                  // customsound1
    customsound2: 0;                  // customsound2
    customsound3: 0;                  // customsound3
    explosiondamage: 0;               // explosiondamage
    explosionradius: 0;               // explosionradius
    meleedamage: 0;                   // meleedamage
    scale: FRACUNIT;                  // scale
   ),
   (    // MT_MISC52
    name: 'Hanging Arms Out';         // name
    inheritsfrom: -1;                 // inheritsfrom
    doomednum: 50;                    // doomednum
    spawnstate: Ord(S_MEAT2);         // spawnstate
    spawnhealth: 1000;                // spawnhealth
    seestate: Ord(S_NULL);            // seestate
    seesound: Ord(sfx_None);          // seesound
    reactiontime: 8;                  // reactiontime
    attacksound: Ord(sfx_None);       // attacksound
    painstate: Ord(S_NULL);           // painstate
    painchance: 0;                    // painchance
    painsound: Ord(sfx_None);         // painsound
    meleestate: Ord(S_NULL);          // meleestate
    missilestate: Ord(S_NULL);        // missilestate
    deathstate: Ord(S_NULL);          // deathstate
    xdeathstate: Ord(S_NULL);         // xdeathstate
    deathsound: Ord(sfx_None);        // deathsound
    speed: 0;                         // speed
    radius: 16 * FRACUNIT;            // radius
    height: 84 * FRACUNIT;            // height
    mass: 100;                        // mass
    damage: 0;                        // damage
    activesound: Ord(sfx_None);       // activesound
    flags: MF_SOLID or MF_SPAWNCEILING or MF_NOGRAVITY;    // flags
    flags_ex: 0;                      // flags_ex
    raisestate: Ord(S_NULL);          // raisestate
    customsound1: 0;                  // customsound1
    customsound2: 0;                  // customsound2
    customsound3: 0;                  // customsound3
    explosiondamage: 0;               // explosiondamage
    explosionradius: 0;               // explosionradius
    meleedamage: 0;                   // meleedamage
    scale: FRACUNIT;                  // scale
   ),
   (    // MT_MISC53
    name: 'One-legged Body';          // name
    inheritsfrom: -1;                 // inheritsfrom
    doomednum: 51;                    // doomednum
    spawnstate: Ord(S_MEAT3);         // spawnstate
    spawnhealth: 1000;                // spawnhealth
    seestate: Ord(S_NULL);            // seestate
    seesound: Ord(sfx_None);          // seesound
    reactiontime: 8;                  // reactiontime
    attacksound: Ord(sfx_None);       // attacksound
    painstate: Ord(S_NULL);           // painstate
    painchance: 0;                    // painchance
    painsound: Ord(sfx_None);         // painsound
    meleestate: Ord(S_NULL);          // meleestate
    missilestate: Ord(S_NULL);        // missilestate
    deathstate: Ord(S_NULL);          // deathstate
    xdeathstate: Ord(S_NULL);         // xdeathstate
    deathsound: Ord(sfx_None);        // deathsound
    speed: 0;                         // speed
    radius: 16 * FRACUNIT;            // radius
    height: 84 * FRACUNIT;            // height
    mass: 100;                        // mass
    damage: 0;                        // damage
    activesound: Ord(sfx_None);       // activesound
    flags: MF_SOLID or MF_SPAWNCEILING or MF_NOGRAVITY;    // flags
    flags_ex: 0;                      // flags_ex
    raisestate: Ord(S_NULL);          // raisestate
    customsound1: 0;                  // customsound1
    customsound2: 0;                  // customsound2
    customsound3: 0;                  // customsound3
    explosiondamage: 0;               // explosiondamage
    explosionradius: 0;               // explosionradius
    meleedamage: 0;                   // meleedamage
    scale: FRACUNIT;                  // scale
   ),
   (    // MT_MISC54
    name: 'Hanging Torso';            // name
    inheritsfrom: -1;                 // inheritsfrom
    doomednum: 52;                    // doomednum
    spawnstate: Ord(S_MEAT4);         // spawnstate
    spawnhealth: 1000;                // spawnhealth
    seestate: Ord(S_NULL);            // seestate
    seesound: Ord(sfx_None);          // seesound
    reactiontime: 8;                  // reactiontime
    attacksound: Ord(sfx_None);       // attacksound
    painstate: Ord(S_NULL);           // painstate
    painchance: 0;                    // painchance
    painsound: Ord(sfx_None);         // painsound
    meleestate: Ord(S_NULL);          // meleestate
    missilestate: Ord(S_NULL);        // missilestate
    deathstate: Ord(S_NULL);          // deathstate
    xdeathstate: Ord(S_NULL);         // xdeathstate
    deathsound: Ord(sfx_None);        // deathsound
    speed: 0;                         // speed
    radius: 16 * FRACUNIT;            // radius
    height: 68 * FRACUNIT;            // height
    mass: 100;                        // mass
    damage: 0;                        // damage
    activesound: Ord(sfx_None);       // activesound
    flags: MF_SOLID or MF_SPAWNCEILING or MF_NOGRAVITY;    // flags
    flags_ex: 0;                      // flags_ex
    raisestate: Ord(S_NULL);          // raisestate
    customsound1: 0;                  // customsound1
    customsound2: 0;                  // customsound2
    customsound3: 0;                  // customsound3
    explosiondamage: 0;               // explosiondamage
    explosionradius: 0;               // explosionradius
    meleedamage: 0;                   // meleedamage
    scale: FRACUNIT;                  // scale
   ),
   (    // MT_MISC55
    name: 'Hanging Leg';              // name
    inheritsfrom: -1;                 // inheritsfrom
    doomednum: 53;                    // doomednum
    spawnstate: Ord(S_MEAT5);         // spawnstate
    spawnhealth: 1000;                // spawnhealth
    seestate: Ord(S_NULL);            // seestate
    seesound: Ord(sfx_None);          // seesound
    reactiontime: 8;                  // reactiontime
    attacksound: Ord(sfx_None);       // attacksound
    painstate: Ord(S_NULL);           // painstate
    painchance: 0;                    // painchance
    painsound: Ord(sfx_None);         // painsound
    meleestate: Ord(S_NULL);          // meleestate
    missilestate: Ord(S_NULL);        // missilestate
    deathstate: Ord(S_NULL);          // deathstate
    xdeathstate: Ord(S_NULL);         // xdeathstate
    deathsound: Ord(sfx_None);        // deathsound
    speed: 0;                         // speed
    radius: 16 * FRACUNIT;            // radius
    height: 52 * FRACUNIT;            // height
    mass: 100;                        // mass
    damage: 0;                        // damage
    activesound: Ord(sfx_None);       // activesound
    flags: MF_SOLID or MF_SPAWNCEILING or MF_NOGRAVITY;    // flags
    flags_ex: 0;                      // flags_ex
    raisestate: Ord(S_NULL);          // raisestate
    customsound1: 0;                  // customsound1
    customsound2: 0;                  // customsound2
    customsound3: 0;                  // customsound3
    explosiondamage: 0;               // explosiondamage
    explosionradius: 0;               // explosionradius
    meleedamage: 0;                   // meleedamage
    scale: FRACUNIT;                  // scale
   ),
   (    // MT_MISC56
    name: 'Hanging Arms Out 2';       // name
    inheritsfrom: -1;                 // inheritsfrom
    doomednum: 59;                    // doomednum
    spawnstate: Ord(S_MEAT2);         // spawnstate
    spawnhealth: 1000;                // spawnhealth
    seestate: Ord(S_NULL);            // seestate
    seesound: Ord(sfx_None);          // seesound
    reactiontime: 8;                  // reactiontime
    attacksound: Ord(sfx_None);       // attacksound
    painstate: Ord(S_NULL);           // painstate
    painchance: 0;                    // painchance
    painsound: Ord(sfx_None);         // painsound
    meleestate: Ord(S_NULL);          // meleestate
    missilestate: Ord(S_NULL);        // missilestate
    deathstate: Ord(S_NULL);          // deathstate
    xdeathstate: Ord(S_NULL);         // xdeathstate
    deathsound: Ord(sfx_None);        // deathsound
    speed: 0;                         // speed
    radius: 20 * FRACUNIT;            // radius
    height: 84 * FRACUNIT;            // height
    mass: 100;                        // mass
    damage: 0;                        // damage
    activesound: Ord(sfx_None);       // activesound
    flags: MF_SPAWNCEILING or MF_NOGRAVITY;    // flags
    flags_ex: 0;                      // flags_ex
    raisestate: Ord(S_NULL);          // raisestate
    customsound1: 0;                  // customsound1
    customsound2: 0;                  // customsound2
    customsound3: 0;                  // customsound3
    explosiondamage: 0;               // explosiondamage
    explosionradius: 0;               // explosionradius
    meleedamage: 0;                   // meleedamage
    scale: FRACUNIT;                  // scale
   ),
   (    // MT_MISC57
    name: 'Hanging Torso 2';          // name
    inheritsfrom: -1;                 // inheritsfrom
    doomednum: 60;                    // doomednum
    spawnstate: Ord(S_MEAT4);         // spawnstate
    spawnhealth: 1000;                // spawnhealth
    seestate: Ord(S_NULL);            // seestate
    seesound: Ord(sfx_None);          // seesound
    reactiontime: 8;                  // reactiontime
    attacksound: Ord(sfx_None);       // attacksound
    painstate: Ord(S_NULL);           // painstate
    painchance: 0;                    // painchance
    painsound: Ord(sfx_None);         // painsound
    meleestate: Ord(S_NULL);          // meleestate
    missilestate: Ord(S_NULL);        // missilestate
    deathstate: Ord(S_NULL);          // deathstate
    xdeathstate: Ord(S_NULL);         // xdeathstate
    deathsound: Ord(sfx_None);        // deathsound
    speed: 0;                         // speed
    radius: 20 * FRACUNIT;            // radius
    height: 68 * FRACUNIT;            // height
    mass: 100;                        // mass
    damage: 0;                        // damage
    activesound: Ord(sfx_None);       // activesound
    flags: MF_SPAWNCEILING or MF_NOGRAVITY;    // flags
    flags_ex: 0;                      // flags_ex
    raisestate: Ord(S_NULL);          // raisestate
    customsound1: 0;                  // customsound1
    customsound2: 0;                  // customsound2
    customsound3: 0;                  // customsound3
    explosiondamage: 0;               // explosiondamage
    explosionradius: 0;               // explosionradius
    meleedamage: 0;                   // meleedamage
    scale: FRACUNIT;                  // scale
   ),
   (    // MT_MISC58
    name: 'One-legged Body 2';        // name
    inheritsfrom: -1;                 // inheritsfrom
    doomednum: 61;                    // doomednum
    spawnstate: Ord(S_MEAT3);         // spawnstate
    spawnhealth: 1000;                // spawnhealth
    seestate: Ord(S_NULL);            // seestate
    seesound: Ord(sfx_None);          // seesound
    reactiontime: 8;                  // reactiontime
    attacksound: Ord(sfx_None);       // attacksound
    painstate: Ord(S_NULL);           // painstate
    painchance: 0;                    // painchance
    painsound: Ord(sfx_None);         // painsound
    meleestate: Ord(S_NULL);          // meleestate
    missilestate: Ord(S_NULL);        // missilestate
    deathstate: Ord(S_NULL);          // deathstate
    xdeathstate: Ord(S_NULL);         // xdeathstate
    deathsound: Ord(sfx_None);        // deathsound
    speed: 0;                         // speed
    radius: 20 * FRACUNIT;            // radius
    height: 52 * FRACUNIT;            // height
    mass: 100;                        // mass
    damage: 0;                        // damage
    activesound: Ord(sfx_None);       // activesound
    flags: MF_SPAWNCEILING or MF_NOGRAVITY;    // flags
    flags_ex: 0;                      // flags_ex
    raisestate: Ord(S_NULL);          // raisestate
    customsound1: 0;                  // customsound1
    customsound2: 0;                  // customsound2
    customsound3: 0;                  // customsound3
    explosiondamage: 0;               // explosiondamage
    explosionradius: 0;               // explosionradius
    meleedamage: 0;                   // meleedamage
    scale: FRACUNIT;                  // scale
   ),
   (    // MT_MISC59
    name: 'Hanging Leg 2';            // name
    inheritsfrom: -1;                 // inheritsfrom
    doomednum: 62;                    // doomednum
    spawnstate: Ord(S_MEAT5);         // spawnstate
    spawnhealth: 1000;                // spawnhealth
    seestate: Ord(S_NULL);            // seestate
    seesound: Ord(sfx_None);          // seesound
    reactiontime: 8;                  // reactiontime
    attacksound: Ord(sfx_None);       // attacksound
    painstate: Ord(S_NULL);           // painstate
    painchance: 0;                    // painchance
    painsound: Ord(sfx_None);         // painsound
    meleestate: Ord(S_NULL);          // meleestate
    missilestate: Ord(S_NULL);        // missilestate
    deathstate: Ord(S_NULL);          // deathstate
    xdeathstate: Ord(S_NULL);         // xdeathstate
    deathsound: Ord(sfx_None);        // deathsound
    speed: 0;                         // speed
    radius: 20 * FRACUNIT;            // radius
    height: 52 * FRACUNIT;            // height
    mass: 100;                        // mass
    damage: 0;                        // damage
    activesound: Ord(sfx_None);       // activesound
    flags: MF_SPAWNCEILING or MF_NOGRAVITY;    // flags
    flags_ex: 0;                      // flags_ex
    raisestate: Ord(S_NULL);          // raisestate
    customsound1: 0;                  // customsound1
    customsound2: 0;                  // customsound2
    customsound3: 0;                  // customsound3
    explosiondamage: 0;               // explosiondamage
    explosionradius: 0;               // explosionradius
    meleedamage: 0;                   // meleedamage
    scale: FRACUNIT;                  // scale
   ),
   (    // MT_MISC60
    name: 'Swaying Body 2';           // name
    inheritsfrom: -1;                 // inheritsfrom
    doomednum: 63;                    // doomednum
    spawnstate: Ord(S_BLOODYTWITCH);    // spawnstate
    spawnhealth: 1000;                // spawnhealth
    seestate: Ord(S_NULL);            // seestate
    seesound: Ord(sfx_None);          // seesound
    reactiontime: 8;                  // reactiontime
    attacksound: Ord(sfx_None);       // attacksound
    painstate: Ord(S_NULL);           // painstate
    painchance: 0;                    // painchance
    painsound: Ord(sfx_None);         // painsound
    meleestate: Ord(S_NULL);          // meleestate
    missilestate: Ord(S_NULL);        // missilestate
    deathstate: Ord(S_NULL);          // deathstate
    xdeathstate: Ord(S_NULL);         // xdeathstate
    deathsound: Ord(sfx_None);        // deathsound
    speed: 0;                         // speed
    radius: 20 * FRACUNIT;            // radius
    height: 68 * FRACUNIT;            // height
    mass: 100;                        // mass
    damage: 0;                        // damage
    activesound: Ord(sfx_None);       // activesound
    flags: MF_SPAWNCEILING or MF_NOGRAVITY;    // flags
    flags_ex: 0;                      // flags_ex
    raisestate: Ord(S_NULL);          // raisestate
    customsound1: 0;                  // customsound1
    customsound2: 0;                  // customsound2
    customsound3: 0;                  // customsound3
    explosiondamage: 0;               // explosiondamage
    explosionradius: 0;               // explosionradius
    meleedamage: 0;                   // meleedamage
    scale: FRACUNIT;                  // scale
   ),
   (    // MT_MISC61
    name: 'Dead Cacodemon';           // name
    inheritsfrom: -1;                 // inheritsfrom
    doomednum: 22;                    // doomednum
    spawnstate: Ord(S_HEAD_DIE6);     // spawnstate
    spawnhealth: 1000;                // spawnhealth
    seestate: Ord(S_NULL);            // seestate
    seesound: Ord(sfx_None);          // seesound
    reactiontime: 8;                  // reactiontime
    attacksound: Ord(sfx_None);       // attacksound
    painstate: Ord(S_NULL);           // painstate
    painchance: 0;                    // painchance
    painsound: Ord(sfx_None);         // painsound
    meleestate: Ord(S_NULL);          // meleestate
    missilestate: Ord(S_NULL);        // missilestate
    deathstate: Ord(S_NULL);          // deathstate
    xdeathstate: Ord(S_NULL);         // xdeathstate
    deathsound: Ord(sfx_None);        // deathsound
    speed: 0;                         // speed
    radius: 20 * FRACUNIT;            // radius
    height: 16 * FRACUNIT;            // height
    mass: 100;                        // mass
    damage: 0;                        // damage
    activesound: Ord(sfx_None);       // activesound
    flags: 0;                         // flags
    flags_ex: 0;                      // flags_ex
    raisestate: Ord(S_NULL);          // raisestate
    customsound1: 0;                  // customsound1
    customsound2: 0;                  // customsound2
    customsound3: 0;                  // customsound3
    explosiondamage: 0;               // explosiondamage
    explosionradius: 0;               // explosionradius
    meleedamage: 0;                   // meleedamage
    scale: FRACUNIT;                  // scale
   ),
   (    // MT_MISC62
    name: 'Dead Marine';              // name
    inheritsfrom: -1;                 // inheritsfrom
    doomednum: 15;                    // doomednum
    spawnstate: Ord(S_PLAY_DIE7);     // spawnstate
    spawnhealth: 1000;                // spawnhealth
    seestate: Ord(S_NULL);            // seestate
    seesound: Ord(sfx_None);          // seesound
    reactiontime: 8;                  // reactiontime
    attacksound: Ord(sfx_None);       // attacksound
    painstate: Ord(S_NULL);           // painstate
    painchance: 0;                    // painchance
    painsound: Ord(sfx_None);         // painsound
    meleestate: Ord(S_NULL);          // meleestate
    missilestate: Ord(S_NULL);        // missilestate
    deathstate: Ord(S_NULL);          // deathstate
    xdeathstate: Ord(S_NULL);         // xdeathstate
    deathsound: Ord(sfx_None);        // deathsound
    speed: 0;                         // speed
    radius: 20 * FRACUNIT;            // radius
    height: 16 * FRACUNIT;            // height
    mass: 100;                        // mass
    damage: 0;                        // damage
    activesound: Ord(sfx_None);       // activesound
    flags: 0;                         // flags
    flags_ex: 0;                      // flags_ex
    raisestate: Ord(S_NULL);          // raisestate
    customsound1: 0;                  // customsound1
    customsound2: 0;                  // customsound2
    customsound3: 0;                  // customsound3
    explosiondamage: 0;               // explosiondamage
    explosionradius: 0;               // explosionradius
    meleedamage: 0;                   // meleedamage
    scale: FRACUNIT;                  // scale
   ),
   (    // MT_MISC63
    name: 'Dead Trooper';             // name
    inheritsfrom: -1;                 // inheritsfrom
    doomednum: 18;                    // doomednum
    spawnstate: Ord(S_POSS_DIE5);     // spawnstate
    spawnhealth: 1000;                // spawnhealth
    seestate: Ord(S_NULL);            // seestate
    seesound: Ord(sfx_None);          // seesound
    reactiontime: 8;                  // reactiontime
    attacksound: Ord(sfx_None);       // attacksound
    painstate: Ord(S_NULL);           // painstate
    painchance: 0;                    // painchance
    painsound: Ord(sfx_None);         // painsound
    meleestate: Ord(S_NULL);          // meleestate
    missilestate: Ord(S_NULL);        // missilestate
    deathstate: Ord(S_NULL);          // deathstate
    xdeathstate: Ord(S_NULL);         // xdeathstate
    deathsound: Ord(sfx_None);        // deathsound
    speed: 0;                         // speed
    radius: 20 * FRACUNIT;            // radius
    height: 16 * FRACUNIT;            // height
    mass: 100;                        // mass
    damage: 0;                        // damage
    activesound: Ord(sfx_None);       // activesound
    flags: 0;                         // flags
    flags_ex: 0;                      // flags_ex
    raisestate: Ord(S_NULL);          // raisestate
    customsound1: 0;                  // customsound1
    customsound2: 0;                  // customsound2
    customsound3: 0;                  // customsound3
    explosiondamage: 0;               // explosiondamage
    explosionradius: 0;               // explosionradius
    meleedamage: 0;                   // meleedamage
    scale: FRACUNIT;                  // scale
   ),
   (    // MT_MISC64
    name: 'Dead Demon';               // name
    inheritsfrom: -1;                 // inheritsfrom
    doomednum: 21;                    // doomednum
    spawnstate: Ord(S_SARG_DIE6);     // spawnstate
    spawnhealth: 1000;                // spawnhealth
    seestate: Ord(S_NULL);            // seestate
    seesound: Ord(sfx_None);          // seesound
    reactiontime: 8;                  // reactiontime
    attacksound: Ord(sfx_None);       // attacksound
    painstate: Ord(S_NULL);           // painstate
    painchance: 0;                    // painchance
    painsound: Ord(sfx_None);         // painsound
    meleestate: Ord(S_NULL);          // meleestate
    missilestate: Ord(S_NULL);        // missilestate
    deathstate: Ord(S_NULL);          // deathstate
    xdeathstate: Ord(S_NULL);         // xdeathstate
    deathsound: Ord(sfx_None);        // deathsound
    speed: 0;                         // speed
    radius: 20 * FRACUNIT;            // radius
    height: 16 * FRACUNIT;            // height
    mass: 100;                        // mass
    damage: 0;                        // damage
    activesound: Ord(sfx_None);       // activesound
    flags: 0;                         // flags
    flags_ex: 0;                      // flags_ex
    raisestate: Ord(S_NULL);          // raisestate
    customsound1: 0;                  // customsound1
    customsound2: 0;                  // customsound2
    customsound3: 0;                  // customsound3
    explosiondamage: 0;               // explosiondamage
    explosionradius: 0;               // explosionradius
    meleedamage: 0;                   // meleedamage
    scale: FRACUNIT;                  // scale
   ),
   (    // MT_MISC65
    name: 'Dead Lost Soul';           // name
    inheritsfrom: -1;                 // inheritsfrom
    doomednum: 23;                    // doomednum
    spawnstate: Ord(S_SKULL_DIE6);    // spawnstate
    spawnhealth: 1000;                // spawnhealth
    seestate: Ord(S_NULL);            // seestate
    seesound: Ord(sfx_None);          // seesound
    reactiontime: 8;                  // reactiontime
    attacksound: Ord(sfx_None);       // attacksound
    painstate: Ord(S_NULL);           // painstate
    painchance: 0;                    // painchance
    painsound: Ord(sfx_None);         // painsound
    meleestate: Ord(S_NULL);          // meleestate
    missilestate: Ord(S_NULL);        // missilestate
    deathstate: Ord(S_NULL);          // deathstate
    xdeathstate: Ord(S_NULL);         // xdeathstate
    deathsound: Ord(sfx_None);        // deathsound
    speed: 0;                         // speed
    radius: 20 * FRACUNIT;            // radius
    height: 16 * FRACUNIT;            // height
    mass: 100;                        // mass
    damage: 0;                        // damage
    activesound: Ord(sfx_None);       // activesound
    flags: 0;                         // flags
    flags_ex: 0;                      // flags_ex
    raisestate: Ord(S_NULL);          // raisestate
    customsound1: 0;                  // customsound1
    customsound2: 0;                  // customsound2
    customsound3: 0;                  // customsound3
    explosiondamage: 0;               // explosiondamage
    explosionradius: 0;               // explosionradius
    meleedamage: 0;                   // meleedamage
    scale: FRACUNIT;                  // scale
   ),
   (    // MT_MISC66
    name: 'Dead Imp';                 // name
    inheritsfrom: -1;                 // inheritsfrom
    doomednum: 20;                    // doomednum
    spawnstate: Ord(S_TROO_DIE5);     // spawnstate
    spawnhealth: 1000;                // spawnhealth
    seestate: Ord(S_NULL);            // seestate
    seesound: Ord(sfx_None);          // seesound
    reactiontime: 8;                  // reactiontime
    attacksound: Ord(sfx_None);       // attacksound
    painstate: Ord(S_NULL);           // painstate
    painchance: 0;                    // painchance
    painsound: Ord(sfx_None);         // painsound
    meleestate: Ord(S_NULL);          // meleestate
    missilestate: Ord(S_NULL);        // missilestate
    deathstate: Ord(S_NULL);          // deathstate
    xdeathstate: Ord(S_NULL);         // xdeathstate
    deathsound: Ord(sfx_None);        // deathsound
    speed: 0;                         // speed
    radius: 20 * FRACUNIT;            // radius
    height: 16 * FRACUNIT;            // height
    mass: 100;                        // mass
    damage: 0;                        // damage
    activesound: Ord(sfx_None);       // activesound
    flags: 0;                         // flags
    flags_ex: 0;                      // flags_ex
    raisestate: Ord(S_NULL);          // raisestate
    customsound1: 0;                  // customsound1
    customsound2: 0;                  // customsound2
    customsound3: 0;                  // customsound3
    explosiondamage: 0;               // explosiondamage
    explosionradius: 0;               // explosionradius
    meleedamage: 0;                   // meleedamage
    scale: FRACUNIT;                  // scale
   ),
   (    // MT_MISC67
    name: 'Dead Sargeant';            // name
    inheritsfrom: -1;                 // inheritsfrom
    doomednum: 19;                    // doomednum
    spawnstate: Ord(S_SPOS_DIE5);     // spawnstate
    spawnhealth: 1000;                // spawnhealth
    seestate: Ord(S_NULL);            // seestate
    seesound: Ord(sfx_None);          // seesound
    reactiontime: 8;                  // reactiontime
    attacksound: Ord(sfx_None);       // attacksound
    painstate: Ord(S_NULL);           // painstate
    painchance: 0;                    // painchance
    painsound: Ord(sfx_None);         // painsound
    meleestate: Ord(S_NULL);          // meleestate
    missilestate: Ord(S_NULL);        // missilestate
    deathstate: Ord(S_NULL);          // deathstate
    xdeathstate: Ord(S_NULL);         // xdeathstate
    deathsound: Ord(sfx_None);        // deathsound
    speed: 0;                         // speed
    radius: 20 * FRACUNIT;            // radius
    height: 16 * FRACUNIT;            // height
    mass: 100;                        // mass
    damage: 0;                        // damage
    activesound: Ord(sfx_None);       // activesound
    flags: 0;                         // flags
    flags_ex: 0;                      // flags_ex
    raisestate: Ord(S_NULL);          // raisestate
    customsound1: 0;                  // customsound1
    customsound2: 0;                  // customsound2
    customsound3: 0;                  // customsound3
    explosiondamage: 0;               // explosiondamage
    explosionradius: 0;               // explosionradius
    meleedamage: 0;                   // meleedamage
    scale: FRACUNIT;                  // scale
   ),
   (    // MT_MISC68
    name: 'Guts and Bones';           // name
    inheritsfrom: -1;                 // inheritsfrom
    doomednum: 10;                    // doomednum
    spawnstate: Ord(S_PLAY_XDIE9);    // spawnstate
    spawnhealth: 1000;                // spawnhealth
    seestate: Ord(S_NULL);            // seestate
    seesound: Ord(sfx_None);          // seesound
    reactiontime: 8;                  // reactiontime
    attacksound: Ord(sfx_None);       // attacksound
    painstate: Ord(S_NULL);           // painstate
    painchance: 0;                    // painchance
    painsound: Ord(sfx_None);         // painsound
    meleestate: Ord(S_NULL);          // meleestate
    missilestate: Ord(S_NULL);        // missilestate
    deathstate: Ord(S_NULL);          // deathstate
    xdeathstate: Ord(S_NULL);         // xdeathstate
    deathsound: Ord(sfx_None);        // deathsound
    speed: 0;                         // speed
    radius: 20 * FRACUNIT;            // radius
    height: 16 * FRACUNIT;            // height
    mass: 100;                        // mass
    damage: 0;                        // damage
    activesound: Ord(sfx_None);       // activesound
    flags: 0;                         // flags
    flags_ex: 0;                      // flags_ex
    raisestate: Ord(S_NULL);          // raisestate
    customsound1: 0;                  // customsound1
    customsound2: 0;                  // customsound2
    customsound3: 0;                  // customsound3
    explosiondamage: 0;               // explosiondamage
    explosionradius: 0;               // explosionradius
    meleedamage: 0;                   // meleedamage
    scale: FRACUNIT;                  // scale
   ),
   (    // MT_MISC69
    name: 'Guts and Bones 2';         // name
    inheritsfrom: -1;                 // inheritsfrom
    doomednum: 12;                    // doomednum
    spawnstate: Ord(S_PLAY_XDIE9);    // spawnstate
    spawnhealth: 1000;                // spawnhealth
    seestate: Ord(S_NULL);            // seestate
    seesound: Ord(sfx_None);          // seesound
    reactiontime: 8;                  // reactiontime
    attacksound: Ord(sfx_None);       // attacksound
    painstate: Ord(S_NULL);           // painstate
    painchance: 0;                    // painchance
    painsound: Ord(sfx_None);         // painsound
    meleestate: Ord(S_NULL);          // meleestate
    missilestate: Ord(S_NULL);        // missilestate
    deathstate: Ord(S_NULL);          // deathstate
    xdeathstate: Ord(S_NULL);         // xdeathstate
    deathsound: Ord(sfx_None);        // deathsound
    speed: 0;                         // speed
    radius: 20 * FRACUNIT;            // radius
    height: 16 * FRACUNIT;            // height
    mass: 100;                        // mass
    damage: 0;                        // damage
    activesound: Ord(sfx_None);       // activesound
    flags: 0;                         // flags
    flags_ex: 0;                      // flags_ex
    raisestate: Ord(S_NULL);          // raisestate
    customsound1: 0;                  // customsound1
    customsound2: 0;                  // customsound2
    customsound3: 0;                  // customsound3
    explosiondamage: 0;               // explosiondamage
    explosionradius: 0;               // explosionradius
    meleedamage: 0;                   // meleedamage
    scale: FRACUNIT;                  // scale
   ),
   (    // MT_MISC70
    name: 'Skewered Heads';           // name
    inheritsfrom: -1;                 // inheritsfrom
    doomednum: 28;                    // doomednum
    spawnstate: Ord(S_HEADSONSTICK);    // spawnstate
    spawnhealth: 1000;                // spawnhealth
    seestate: Ord(S_NULL);            // seestate
    seesound: Ord(sfx_None);          // seesound
    reactiontime: 8;                  // reactiontime
    attacksound: Ord(sfx_None);       // attacksound
    painstate: Ord(S_NULL);           // painstate
    painchance: 0;                    // painchance
    painsound: Ord(sfx_None);         // painsound
    meleestate: Ord(S_NULL);          // meleestate
    missilestate: Ord(S_NULL);        // missilestate
    deathstate: Ord(S_NULL);          // deathstate
    xdeathstate: Ord(S_NULL);         // xdeathstate
    deathsound: Ord(sfx_None);        // deathsound
    speed: 0;                         // speed
    radius: 16 * FRACUNIT;            // radius
    height: 16 * FRACUNIT;            // height
    mass: 100;                        // mass
    damage: 0;                        // damage
    activesound: Ord(sfx_None);       // activesound
    flags: MF_SOLID;                  // flags
    flags_ex: 0;                      // flags_ex
    raisestate: Ord(S_NULL);          // raisestate
    customsound1: 0;                  // customsound1
    customsound2: 0;                  // customsound2
    customsound3: 0;                  // customsound3
    explosiondamage: 0;               // explosiondamage
    explosionradius: 0;               // explosionradius
    meleedamage: 0;                   // meleedamage
    scale: FRACUNIT;                  // scale
   ),
   (    // MT_MISC71
    name: 'Pool of Blood';            // name
    inheritsfrom: -1;                 // inheritsfrom
    doomednum: 24;                    // doomednum
    spawnstate: Ord(S_GIBS);          // spawnstate
    spawnhealth: 1000;                // spawnhealth
    seestate: Ord(S_NULL);            // seestate
    seesound: Ord(sfx_None);          // seesound
    reactiontime: 8;                  // reactiontime
    attacksound: Ord(sfx_None);       // attacksound
    painstate: Ord(S_NULL);           // painstate
    painchance: 0;                    // painchance
    painsound: Ord(sfx_None);         // painsound
    meleestate: Ord(S_NULL);          // meleestate
    missilestate: Ord(S_NULL);        // missilestate
    deathstate: Ord(S_NULL);          // deathstate
    xdeathstate: Ord(S_NULL);         // xdeathstate
    deathsound: Ord(sfx_None);        // deathsound
    speed: 0;                         // speed
    radius: 20 * FRACUNIT;            // radius
    height: 16 * FRACUNIT;            // height
    mass: 100;                        // mass
    damage: 0;                        // damage
    activesound: Ord(sfx_None);       // activesound
    flags: 0;                         // flags
    flags_ex: 0;                      // flags_ex
    raisestate: Ord(S_NULL);          // raisestate
    customsound1: 0;                  // customsound1
    customsound2: 0;                  // customsound2
    customsound3: 0;                  // customsound3
    explosiondamage: 0;               // explosiondamage
    explosionradius: 0;               // explosionradius
    meleedamage: 0;                   // meleedamage
    scale: FRACUNIT;                  // scale
   ),
   (    // MT_MISC72
    name: 'Pole with Skull';          // name
    inheritsfrom: -1;                 // inheritsfrom
    doomednum: 27;                    // doomednum
    spawnstate: Ord(S_HEADONASTICK);    // spawnstate
    spawnhealth: 1000;                // spawnhealth
    seestate: Ord(S_NULL);            // seestate
    seesound: Ord(sfx_None);          // seesound
    reactiontime: 8;                  // reactiontime
    attacksound: Ord(sfx_None);       // attacksound
    painstate: Ord(S_NULL);           // painstate
    painchance: 0;                    // painchance
    painsound: Ord(sfx_None);         // painsound
    meleestate: Ord(S_NULL);          // meleestate
    missilestate: Ord(S_NULL);        // missilestate
    deathstate: Ord(S_NULL);          // deathstate
    xdeathstate: Ord(S_NULL);         // xdeathstate
    deathsound: Ord(sfx_None);        // deathsound
    speed: 0;                         // speed
    radius: 16 * FRACUNIT;            // radius
    height: 16 * FRACUNIT;            // height
    mass: 100;                        // mass
    damage: 0;                        // damage
    activesound: Ord(sfx_None);       // activesound
    flags: MF_SOLID;                  // flags
    flags_ex: 0;                      // flags_ex
    raisestate: Ord(S_NULL);          // raisestate
    customsound1: 0;                  // customsound1
    customsound2: 0;                  // customsound2
    customsound3: 0;                  // customsound3
    explosiondamage: 0;               // explosiondamage
    explosionradius: 0;               // explosionradius
    meleedamage: 0;                   // meleedamage
    scale: FRACUNIT;                  // scale
   ),
   (    // MT_MISC73
    name: 'Pile of Skulls';           // name
    inheritsfrom: -1;                 // inheritsfrom
    doomednum: 29;                    // doomednum
    spawnstate: Ord(S_HEADCANDLES);    // spawnstate
    spawnhealth: 1000;                // spawnhealth
    seestate: Ord(S_NULL);            // seestate
    seesound: Ord(sfx_None);          // seesound
    reactiontime: 8;                  // reactiontime
    attacksound: Ord(sfx_None);       // attacksound
    painstate: Ord(S_NULL);           // painstate
    painchance: 0;                    // painchance
    painsound: Ord(sfx_None);         // painsound
    meleestate: Ord(S_NULL);          // meleestate
    missilestate: Ord(S_NULL);        // missilestate
    deathstate: Ord(S_NULL);          // deathstate
    xdeathstate: Ord(S_NULL);         // xdeathstate
    deathsound: Ord(sfx_None);        // deathsound
    speed: 0;                         // speed
    radius: 16 * FRACUNIT;            // radius
    height: 16 * FRACUNIT;            // height
    mass: 100;                        // mass
    damage: 0;                        // damage
    activesound: Ord(sfx_None);       // activesound
    flags: MF_SOLID;                  // flags
    flags_ex: 0;                      // flags_ex
    raisestate: Ord(S_NULL);          // raisestate
    customsound1: 0;                  // customsound1
    customsound2: 0;                  // customsound2
    customsound3: 0;                  // customsound3
    explosiondamage: 0;               // explosiondamage
    explosionradius: 0;               // explosionradius
    meleedamage: 0;                   // meleedamage
    scale: FRACUNIT;                  // scale
   ),
   (    // MT_MISC74
    name: 'Impaled Body';             // name
    inheritsfrom: -1;                 // inheritsfrom
    doomednum: 25;                    // doomednum
    spawnstate: Ord(S_DEADSTICK);     // spawnstate
    spawnhealth: 1000;                // spawnhealth
    seestate: Ord(S_NULL);            // seestate
    seesound: Ord(sfx_None);          // seesound
    reactiontime: 8;                  // reactiontime
    attacksound: Ord(sfx_None);       // attacksound
    painstate: Ord(S_NULL);           // painstate
    painchance: 0;                    // painchance
    painsound: Ord(sfx_None);         // painsound
    meleestate: Ord(S_NULL);          // meleestate
    missilestate: Ord(S_NULL);        // missilestate
    deathstate: Ord(S_NULL);          // deathstate
    xdeathstate: Ord(S_NULL);         // xdeathstate
    deathsound: Ord(sfx_None);        // deathsound
    speed: 0;                         // speed
    radius: 16 * FRACUNIT;            // radius
    height: 16 * FRACUNIT;            // height
    mass: 100;                        // mass
    damage: 0;                        // damage
    activesound: Ord(sfx_None);       // activesound
    flags: MF_SOLID;                  // flags
    flags_ex: 0;                      // flags_ex
    raisestate: Ord(S_NULL);          // raisestate
    customsound1: 0;                  // customsound1
    customsound2: 0;                  // customsound2
    customsound3: 0;                  // customsound3
    explosiondamage: 0;               // explosiondamage
    explosionradius: 0;               // explosionradius
    meleedamage: 0;                   // meleedamage
    scale: FRACUNIT;                  // scale
   ),
   (    // MT_MISC75
    name: 'Twitching Body';           // name
    inheritsfrom: -1;                 // inheritsfrom
    doomednum: 26;                    // doomednum
    spawnstate: Ord(S_LIVESTICK);     // spawnstate
    spawnhealth: 1000;                // spawnhealth
    seestate: Ord(S_NULL);            // seestate
    seesound: Ord(sfx_None);          // seesound
    reactiontime: 8;                  // reactiontime
    attacksound: Ord(sfx_None);       // attacksound
    painstate: Ord(S_NULL);           // painstate
    painchance: 0;                    // painchance
    painsound: Ord(sfx_None);         // painsound
    meleestate: Ord(S_NULL);          // meleestate
    missilestate: Ord(S_NULL);        // missilestate
    deathstate: Ord(S_NULL);          // deathstate
    xdeathstate: Ord(S_NULL);         // xdeathstate
    deathsound: Ord(sfx_None);        // deathsound
    speed: 0;                         // speed
    radius: 16 * FRACUNIT;            // radius
    height: 16 * FRACUNIT;            // height
    mass: 100;                        // mass
    damage: 0;                        // damage
    activesound: Ord(sfx_None);       // activesound
    flags: MF_SOLID;                  // flags
    flags_ex: 0;                      // flags_ex
    raisestate: Ord(S_NULL);          // raisestate
    customsound1: 0;                  // customsound1
    customsound2: 0;                  // customsound2
    customsound3: 0;                  // customsound3
    explosiondamage: 0;               // explosiondamage
    explosionradius: 0;               // explosionradius
    meleedamage: 0;                   // meleedamage
    scale: FRACUNIT;                  // scale
   ),
   (    // MT_MISC76
    name: 'Large Tree';               // name
    inheritsfrom: -1;                 // inheritsfrom
    doomednum: 54;                    // doomednum
    spawnstate: Ord(S_BIGTREE);       // spawnstate
    spawnhealth: 1000;                // spawnhealth
    seestate: Ord(S_NULL);            // seestate
    seesound: Ord(sfx_None);          // seesound
    reactiontime: 8;                  // reactiontime
    attacksound: Ord(sfx_None);       // attacksound
    painstate: Ord(S_NULL);           // painstate
    painchance: 0;                    // painchance
    painsound: Ord(sfx_None);         // painsound
    meleestate: Ord(S_NULL);          // meleestate
    missilestate: Ord(S_NULL);        // missilestate
    deathstate: Ord(S_NULL);          // deathstate
    xdeathstate: Ord(S_NULL);         // xdeathstate
    deathsound: Ord(sfx_None);        // deathsound
    speed: 0;                         // speed
    radius: 32 * FRACUNIT;            // radius
    height: 16 * FRACUNIT;            // height
    mass: 100;                        // mass
    damage: 0;                        // damage
    activesound: Ord(sfx_None);       // activesound
    flags: MF_SOLID;                  // flags
    flags_ex: 0;                      // flags_ex
    raisestate: Ord(S_NULL);          // raisestate
    customsound1: 0;                  // customsound1
    customsound2: 0;                  // customsound2
    customsound3: 0;                  // customsound3
    explosiondamage: 0;               // explosiondamage
    explosionradius: 0;               // explosionradius
    meleedamage: 0;                   // meleedamage
    scale: FRACUNIT;                  // scale
   ),
   (    // MT_MISC77
    name: 'Flaming Barrel';           // name
    inheritsfrom: -1;                 // inheritsfrom
    doomednum: 70;                    // doomednum
    spawnstate: Ord(S_BBAR1);         // spawnstate
    spawnhealth: 1000;                // spawnhealth
    seestate: Ord(S_NULL);            // seestate
    seesound: Ord(sfx_None);          // seesound
    reactiontime: 8;                  // reactiontime
    attacksound: Ord(sfx_None);       // attacksound
    painstate: Ord(S_NULL);           // painstate
    painchance: 0;                    // painchance
    painsound: Ord(sfx_None);         // painsound
    meleestate: Ord(S_NULL);          // meleestate
    missilestate: Ord(S_NULL);        // missilestate
    deathstate: Ord(S_NULL);          // deathstate
    xdeathstate: Ord(S_NULL);         // xdeathstate
    deathsound: Ord(sfx_None);        // deathsound
    speed: 0;                         // speed
    radius: 16 * FRACUNIT;            // radius
    height: 16 * FRACUNIT;            // height
    mass: 100;                        // mass
    damage: 0;                        // damage
    activesound: Ord(sfx_None);       // activesound
    flags: MF_SOLID;                  // flags
    flags_ex: 0;                      // flags_ex
    raisestate: Ord(S_NULL);          // raisestate
    customsound1: 0;                  // customsound1
    customsound2: 0;                  // customsound2
    customsound3: 0;                  // customsound3
    explosiondamage: 0;               // explosiondamage
    explosionradius: 0;               // explosionradius
    meleedamage: 0;                   // meleedamage
    scale: FRACUNIT;                  // scale
   ),
   (    // MT_MISC78
    name: 'Hanging Body 1';           // name
    inheritsfrom: -1;                 // inheritsfrom
    doomednum: 73;                    // doomednum
    spawnstate: Ord(S_HANGNOGUTS);    // spawnstate
    spawnhealth: 1000;                // spawnhealth
    seestate: Ord(S_NULL);            // seestate
    seesound: Ord(sfx_None);          // seesound
    reactiontime: 8;                  // reactiontime
    attacksound: Ord(sfx_None);       // attacksound
    painstate: Ord(S_NULL);           // painstate
    painchance: 0;                    // painchance
    painsound: Ord(sfx_None);         // painsound
    meleestate: Ord(S_NULL);          // meleestate
    missilestate: Ord(S_NULL);        // missilestate
    deathstate: Ord(S_NULL);          // deathstate
    xdeathstate: Ord(S_NULL);         // xdeathstate
    deathsound: Ord(sfx_None);        // deathsound
    speed: 0;                         // speed
    radius: 16 * FRACUNIT;            // radius
    height: 88 * FRACUNIT;            // height
    mass: 100;                        // mass
    damage: 0;                        // damage
    activesound: Ord(sfx_None);       // activesound
    flags: MF_SOLID or MF_SPAWNCEILING or MF_NOGRAVITY;    // flags
    flags_ex: 0;                      // flags_ex
    raisestate: Ord(S_NULL);          // raisestate
    customsound1: 0;                  // customsound1
    customsound2: 0;                  // customsound2
    customsound3: 0;                  // customsound3
    explosiondamage: 0;               // explosiondamage
    explosionradius: 0;               // explosionradius
    meleedamage: 0;                   // meleedamage
    scale: FRACUNIT;                  // scale
   ),
   (    // MT_MISC79
    name: 'Hanging Body 2';           // name
    inheritsfrom: -1;                 // inheritsfrom
    doomednum: 74;                    // doomednum
    spawnstate: Ord(S_HANGBNOBRAIN);    // spawnstate
    spawnhealth: 1000;                // spawnhealth
    seestate: Ord(S_NULL);            // seestate
    seesound: Ord(sfx_None);          // seesound
    reactiontime: 8;                  // reactiontime
    attacksound: Ord(sfx_None);       // attacksound
    painstate: Ord(S_NULL);           // painstate
    painchance: 0;                    // painchance
    painsound: Ord(sfx_None);         // painsound
    meleestate: Ord(S_NULL);          // meleestate
    missilestate: Ord(S_NULL);        // missilestate
    deathstate: Ord(S_NULL);          // deathstate
    xdeathstate: Ord(S_NULL);         // xdeathstate
    deathsound: Ord(sfx_None);        // deathsound
    speed: 0;                         // speed
    radius: 16 * FRACUNIT;            // radius
    height: 88 * FRACUNIT;            // height
    mass: 100;                        // mass
    damage: 0;                        // damage
    activesound: Ord(sfx_None);       // activesound
    flags: MF_SOLID or MF_SPAWNCEILING or MF_NOGRAVITY;    // flags
    flags_ex: 0;                      // flags_ex
    raisestate: Ord(S_NULL);          // raisestate
    customsound1: 0;                  // customsound1
    customsound2: 0;                  // customsound2
    customsound3: 0;                  // customsound3
    explosiondamage: 0;               // explosiondamage
    explosionradius: 0;               // explosionradius
    meleedamage: 0;                   // meleedamage
    scale: FRACUNIT;                  // scale
   ),
   (    // MT_MISC80
    name: 'Hanging Body 3';           // name
    inheritsfrom: -1;                 // inheritsfrom
    doomednum: 75;                    // doomednum
    spawnstate: Ord(S_HANGTLOOKDN);   // spawnstate
    spawnhealth: 1000;                // spawnhealth
    seestate: Ord(S_NULL);            // seestate
    seesound: Ord(sfx_None);          // seesound
    reactiontime: 8;                  // reactiontime
    attacksound: Ord(sfx_None);       // attacksound
    painstate: Ord(S_NULL);           // painstate
    painchance: 0;                    // painchance
    painsound: Ord(sfx_None);         // painsound
    meleestate: Ord(S_NULL);          // meleestate
    missilestate: Ord(S_NULL);        // missilestate
    deathstate: Ord(S_NULL);          // deathstate
    xdeathstate: Ord(S_NULL);         // xdeathstate
    deathsound: Ord(sfx_None);        // deathsound
    speed: 0;                         // speed
    radius: 16 * FRACUNIT;            // radius
    height: 64 * FRACUNIT;            // height
    mass: 100;                        // mass
    damage: 0;                        // damage
    activesound: Ord(sfx_None);       // activesound
    flags: MF_SOLID or MF_SPAWNCEILING or MF_NOGRAVITY;    // flags
    flags_ex: 0;                      // flags_ex
    raisestate: Ord(S_NULL);          // raisestate
    customsound1: 0;                  // customsound1
    customsound2: 0;                  // customsound2
    customsound3: 0;                  // customsound3
    explosiondamage: 0;               // explosiondamage
    explosionradius: 0;               // explosionradius
    meleedamage: 0;                   // meleedamage
    scale: FRACUNIT;                  // scale
   ),
   (    // MT_MISC81
    name: 'Hanging Body 4';           // name
    inheritsfrom: -1;                 // inheritsfrom
    doomednum: 76;                    // doomednum
    spawnstate: Ord(S_HANGTSKULL);    // spawnstate
    spawnhealth: 1000;                // spawnhealth
    seestate: Ord(S_NULL);            // seestate
    seesound: Ord(sfx_None);          // seesound
    reactiontime: 8;                  // reactiontime
    attacksound: Ord(sfx_None);       // attacksound
    painstate: Ord(S_NULL);           // painstate
    painchance: 0;                    // painchance
    painsound: Ord(sfx_None);         // painsound
    meleestate: Ord(S_NULL);          // meleestate
    missilestate: Ord(S_NULL);        // missilestate
    deathstate: Ord(S_NULL);          // deathstate
    xdeathstate: Ord(S_NULL);         // xdeathstate
    deathsound: Ord(sfx_None);        // deathsound
    speed: 0;                         // speed
    radius: 16 * FRACUNIT;            // radius
    height: 64 * FRACUNIT;            // height
    mass: 100;                        // mass
    damage: 0;                        // damage
    activesound: Ord(sfx_None);       // activesound
    flags: MF_SOLID or MF_SPAWNCEILING or MF_NOGRAVITY;    // flags
    flags_ex: 0;                      // flags_ex
    raisestate: Ord(S_NULL);          // raisestate
    customsound1: 0;                  // customsound1
    customsound2: 0;                  // customsound2
    customsound3: 0;                  // customsound3
    explosiondamage: 0;               // explosiondamage
    explosionradius: 0;               // explosionradius
    meleedamage: 0;                   // meleedamage
    scale: FRACUNIT;                  // scale
   ),
   (    // MT_MISC82
    name: 'Hanging Body 5';           // name
    inheritsfrom: -1;                 // inheritsfrom
    doomednum: 77;                    // doomednum
    spawnstate: Ord(S_HANGTLOOKUP);   // spawnstate
    spawnhealth: 1000;                // spawnhealth
    seestate: Ord(S_NULL);            // seestate
    seesound: Ord(sfx_None);          // seesound
    reactiontime: 8;                  // reactiontime
    attacksound: Ord(sfx_None);       // attacksound
    painstate: Ord(S_NULL);           // painstate
    painchance: 0;                    // painchance
    painsound: Ord(sfx_None);         // painsound
    meleestate: Ord(S_NULL);          // meleestate
    missilestate: Ord(S_NULL);        // missilestate
    deathstate: Ord(S_NULL);          // deathstate
    xdeathstate: Ord(S_NULL);         // xdeathstate
    deathsound: Ord(sfx_None);        // deathsound
    speed: 0;                         // speed
    radius: 16 * FRACUNIT;            // radius
    height: 64 * FRACUNIT;            // height
    mass: 100;                        // mass
    damage: 0;                        // damage
    activesound: Ord(sfx_None);       // activesound
    flags: MF_SOLID or MF_SPAWNCEILING or MF_NOGRAVITY;    // flags
    flags_ex: 0;                      // flags_ex
    raisestate: Ord(S_NULL);          // raisestate
    customsound1: 0;                  // customsound1
    customsound2: 0;                  // customsound2
    customsound3: 0;                  // customsound3
    explosiondamage: 0;               // explosiondamage
    explosionradius: 0;               // explosionradius
    meleedamage: 0;                   // meleedamage
    scale: FRACUNIT;                  // scale
   ),
   (    // MT_MISC83
    name: 'Hanging Body 6';           // name
    inheritsfrom: -1;                 // inheritsfrom
    doomednum: 78;                    // doomednum
    spawnstate: Ord(S_HANGTNOBRAIN);  // spawnstate
    spawnhealth: 1000;                // spawnhealth
    seestate: Ord(S_NULL);            // seestate
    seesound: Ord(sfx_None);          // seesound
    reactiontime: 8;                  // reactiontime
    attacksound: Ord(sfx_None);       // attacksound
    painstate: Ord(S_NULL);           // painstate
    painchance: 0;                    // painchance
    painsound: Ord(sfx_None);         // painsound
    meleestate: Ord(S_NULL);          // meleestate
    missilestate: Ord(S_NULL);        // missilestate
    deathstate: Ord(S_NULL);          // deathstate
    xdeathstate: Ord(S_NULL);         // xdeathstate
    deathsound: Ord(sfx_None);        // deathsound
    speed: 0;                         // speed
    radius: 16 * FRACUNIT;            // radius
    height: 64 * FRACUNIT;            // height
    mass: 100;                        // mass
    damage: 0;                        // damage
    activesound: Ord(sfx_None);       // activesound
    flags: MF_SOLID or MF_SPAWNCEILING or MF_NOGRAVITY;    // flags
    flags_ex: 0;                      // flags_ex
    raisestate: Ord(S_NULL);          // raisestate
    customsound1: 0;                  // customsound1
    customsound2: 0;                  // customsound2
    customsound3: 0;                  // customsound3
    explosiondamage: 0;               // explosiondamage
    explosionradius: 0;               // explosionradius
    meleedamage: 0;                   // meleedamage
    scale: FRACUNIT;                  // scale
   ),
   (    // MT_MISC84
    name: 'Pool Of Blood 1';          // name
    inheritsfrom: -1;                 // inheritsfrom
    doomednum: 79;                    // doomednum
    spawnstate: Ord(S_COLONGIBS);     // spawnstate
    spawnhealth: 1000;                // spawnhealth
    seestate: Ord(S_NULL);            // seestate
    seesound: Ord(sfx_None);          // seesound
    reactiontime: 8;                  // reactiontime
    attacksound: Ord(sfx_None);       // attacksound
    painstate: Ord(S_NULL);           // painstate
    painchance: 0;                    // painchance
    painsound: Ord(sfx_None);         // painsound
    meleestate: Ord(S_NULL);          // meleestate
    missilestate: Ord(S_NULL);        // missilestate
    deathstate: Ord(S_NULL);          // deathstate
    xdeathstate: Ord(S_NULL);         // xdeathstate
    deathsound: Ord(sfx_None);        // deathsound
    speed: 0;                         // speed
    radius: 20 * FRACUNIT;            // radius
    height: 16 * FRACUNIT;            // height
    mass: 100;                        // mass
    damage: 0;                        // damage
    activesound: Ord(sfx_None);       // activesound
    flags: MF_NOBLOCKMAP;             // flags
    flags_ex: 0;                      // flags_ex
    raisestate: Ord(S_NULL);          // raisestate
    customsound1: 0;                  // customsound1
    customsound2: 0;                  // customsound2
    customsound3: 0;                  // customsound3
    explosiondamage: 0;               // explosiondamage
    explosionradius: 0;               // explosionradius
    meleedamage: 0;                   // meleedamage
    scale: FRACUNIT;                  // scale
   ),
   (    // MT_MISC85
    name: 'Pool Of Blood 2';          // name
    inheritsfrom: -1;                 // inheritsfrom
    doomednum: 80;                    // doomednum
    spawnstate: Ord(S_SMALLPOOL);     // spawnstate
    spawnhealth: 1000;                // spawnhealth
    seestate: Ord(S_NULL);            // seestate
    seesound: Ord(sfx_None);          // seesound
    reactiontime: 8;                  // reactiontime
    attacksound: Ord(sfx_None);       // attacksound
    painstate: Ord(S_NULL);           // painstate
    painchance: 0;                    // painchance
    painsound: Ord(sfx_None);         // painsound
    meleestate: Ord(S_NULL);          // meleestate
    missilestate: Ord(S_NULL);        // missilestate
    deathstate: Ord(S_NULL);          // deathstate
    xdeathstate: Ord(S_NULL);         // xdeathstate
    deathsound: Ord(sfx_None);        // deathsound
    speed: 0;                         // speed
    radius: 20 * FRACUNIT;            // radius
    height: 16 * FRACUNIT;            // height
    mass: 100;                        // mass
    damage: 0;                        // damage
    activesound: Ord(sfx_None);       // activesound
    flags: MF_NOBLOCKMAP;             // flags
    flags_ex: 0;                      // flags_ex
    raisestate: Ord(S_NULL);          // raisestate
    customsound1: 0;                  // customsound1
    customsound2: 0;                  // customsound2
    customsound3: 0;                  // customsound3
    explosiondamage: 0;               // explosiondamage
    explosionradius: 0;               // explosionradius
    meleedamage: 0;                   // meleedamage
    scale: FRACUNIT;                  // scale
   ),
   (    // MT_MISC86
    name: 'Brain';                    // name
    inheritsfrom: -1;                 // inheritsfrom
    doomednum: 81;                    // doomednum
    spawnstate: Ord(S_BRAINSTEM);     // spawnstate
    spawnhealth: 1000;                // spawnhealth
    seestate: Ord(S_NULL);            // seestate
    seesound: Ord(sfx_None);          // seesound
    reactiontime: 8;                  // reactiontime
    attacksound: Ord(sfx_None);       // attacksound
    painstate: Ord(S_NULL);           // painstate
    painchance: 0;                    // painchance
    painsound: Ord(sfx_None);         // painsound
    meleestate: Ord(S_NULL);          // meleestate
    missilestate: Ord(S_NULL);        // missilestate
    deathstate: Ord(S_NULL);          // deathstate
    xdeathstate: Ord(S_NULL);         // xdeathstate
    deathsound: Ord(sfx_None);        // deathsound
    speed: 0;                         // speed
    radius: 20 * FRACUNIT;            // radius
    height: 16 * FRACUNIT;            // height
    mass: 100;                        // mass
    damage: 0;                        // damage
    activesound: Ord(sfx_None);       // activesound
    flags: MF_NOBLOCKMAP;             // flags
    flags_ex: 0;                      // flags_ex
    raisestate: Ord(S_NULL);          // raisestate
    customsound1: 0;                  // customsound1
    customsound2: 0;                  // customsound2
    customsound3: 0;                  // customsound3
    explosiondamage: 0;               // explosiondamage
    explosionradius: 0;               // explosionradius
    meleedamage: 0;                   // meleedamage
    scale: FRACUNIT;                  // scale
   )
  );

procedure Info_Init(const usethinkers: boolean);
var
  i: integer;
begin
  if states = nil then
  begin
    states := malloc(Ord(DO_NUMSTATES) * SizeOf(state_t));
    memcpy(states, @DO_states, Ord(DO_NUMSTATES) * SizeOf(state_t));
  end;

  if sprnames = nil then
  begin
    sprnames := malloc(Ord(DO_NUMSPRITES) * 4 + 4);
    for i := 0 to Ord(DO_NUMSPRITES) - 1 do
      sprnames[i] := Ord(DO_sprnames[i][1]) +
                     Ord(DO_sprnames[i][2]) shl 8 +
                     Ord(DO_sprnames[i][3]) shl 16 +
                     Ord(DO_sprnames[i][4]) shl 24;
    sprnames[Ord(DO_NUMSPRITES)] := 0;
  end;

  if mobjinfo = nil then
  begin
    mobjinfo := malloc(Ord(DO_NUMMOBJTYPES) * SizeOf(mobjinfo_t));
    memcpy(mobjinfo, @DO_mobjinfo, Ord(DO_NUMMOBJTYPES) * SizeOf(mobjinfo_t));
  end;

  if not usethinkers then
  begin
    for i := 0 to Ord(DO_NUMSTATES) - 1 do
      states[i].action.acp1 := nil;
    exit;
  end;

  states[Ord(S_LIGHTDONE)].action.acp1 := @A_Light0; // S_LIGHTDONE
  states[Ord(S_PUNCH)].action.acp1 := @A_WeaponReady; // S_PUNCH
  states[Ord(S_PUNCHDOWN)].action.acp1 := @A_Lower; // S_PUNCHDOWN
  states[Ord(S_PUNCHUP)].action.acp1 := @A_Raise; // S_PUNCHUP
  states[Ord(S_PUNCH2)].action.acp1 := @A_Punch; // S_PUNCH2
  states[Ord(S_PUNCH5)].action.acp1 := @A_ReFire; // S_PUNCH5
  states[Ord(S_PISTOL)].action.acp1 := @A_WeaponReady; // S_PISTOL
  states[Ord(S_PISTOLDOWN)].action.acp1 := @A_Lower; // S_PISTOLDOWN
  states[Ord(S_PISTOLUP)].action.acp1 := @A_Raise; // S_PISTOLUP
  states[Ord(S_PISTOL2)].action.acp1 := @A_FirePistol; // S_PISTOL2
  states[Ord(S_PISTOL4)].action.acp1 := @A_ReFire; // S_PISTOL4
  states[Ord(S_PISTOLFLASH)].action.acp1 := @A_Light1; // S_PISTOLFLASH
  states[Ord(S_SGUN)].action.acp1 := @A_WeaponReady; // S_SGUN
  states[Ord(S_SGUNDOWN)].action.acp1 := @A_Lower; // S_SGUNDOWN
  states[Ord(S_SGUNUP)].action.acp1 := @A_Raise; // S_SGUNUP
  states[Ord(S_SGUN2)].action.acp1 := @A_FireShotgun; // S_SGUN2
  states[Ord(S_SGUN9)].action.acp1 := @A_ReFire; // S_SGUN9
  states[Ord(S_SGUNFLASH1)].action.acp1 := @A_Light1; // S_SGUNFLASH1
  states[Ord(S_SGUNFLASH2)].action.acp1 := @A_Light2; // S_SGUNFLASH2
  states[Ord(S_DSGUN)].action.acp1 := @A_WeaponReady; // S_DSGUN
  states[Ord(S_DSGUNDOWN)].action.acp1 := @A_Lower; // S_DSGUNDOWN
  states[Ord(S_DSGUNUP)].action.acp1 := @A_Raise; // S_DSGUNUP
  states[Ord(S_DSGUN2)].action.acp1 := @A_FireShotgun2; // S_DSGUN2
  states[Ord(S_DSGUN4)].action.acp1 := @A_CheckReload; // S_DSGUN4
  states[Ord(S_DSGUN5)].action.acp1 := @A_OpenShotgun2; // S_DSGUN5
  states[Ord(S_DSGUN7)].action.acp1 := @A_LoadShotgun2; // S_DSGUN7
  states[Ord(S_DSGUN9)].action.acp1 := @A_CloseShotgun2; // S_DSGUN9
  states[Ord(S_DSGUN10)].action.acp1 := @A_ReFire; // S_DSGUN10
  states[Ord(S_DSGUNFLASH1)].action.acp1 := @A_Light1; // S_DSGUNFLASH1
  states[Ord(S_DSGUNFLASH2)].action.acp1 := @A_Light2; // S_DSGUNFLASH2
  states[Ord(S_CHAIN)].action.acp1 := @A_WeaponReady; // S_CHAIN
  states[Ord(S_CHAINDOWN)].action.acp1 := @A_Lower; // S_CHAINDOWN
  states[Ord(S_CHAINUP)].action.acp1 := @A_Raise; // S_CHAINUP
  states[Ord(S_CHAIN1)].action.acp1 := @A_FireCGun; // S_CHAIN1
  states[Ord(S_CHAIN2)].action.acp1 := @A_FireCGun; // S_CHAIN2
  states[Ord(S_CHAIN3)].action.acp1 := @A_ReFire; // S_CHAIN3
  states[Ord(S_CHAINFLASH1)].action.acp1 := @A_Light1; // S_CHAINFLASH1
  states[Ord(S_CHAINFLASH2)].action.acp1 := @A_Light2; // S_CHAINFLASH2
  states[Ord(S_MISSILE)].action.acp1 := @A_WeaponReady; // S_MISSILE
  states[Ord(S_MISSILEDOWN)].action.acp1 := @A_Lower; // S_MISSILEDOWN
  states[Ord(S_MISSILEUP)].action.acp1 := @A_Raise; // S_MISSILEUP
  states[Ord(S_MISSILE1)].action.acp1 := @A_GunFlash; // S_MISSILE1
  states[Ord(S_MISSILE2)].action.acp1 := @A_FireMissile; // S_MISSILE2
  states[Ord(S_MISSILE3)].action.acp1 := @A_ReFire; // S_MISSILE3
  states[Ord(S_MISSILEFLASH1)].action.acp1 := @A_Light1; // S_MISSILEFLASH1
  states[Ord(S_MISSILEFLASH3)].action.acp1 := @A_Light2; // S_MISSILEFLASH3
  states[Ord(S_MISSILEFLASH4)].action.acp1 := @A_Light2; // S_MISSILEFLASH4
  states[Ord(S_SAW)].action.acp1 := @A_WeaponReady; // S_SAW
  states[Ord(S_SAWB)].action.acp1 := @A_WeaponReady; // S_SAWB
  states[Ord(S_SAWDOWN)].action.acp1 := @A_Lower; // S_SAWDOWN
  states[Ord(S_SAWUP)].action.acp1 := @A_Raise; // S_SAWUP
  states[Ord(S_SAW1)].action.acp1 := @A_Saw; // S_SAW1
  states[Ord(S_SAW2)].action.acp1 := @A_Saw; // S_SAW2
  states[Ord(S_SAW3)].action.acp1 := @A_ReFire; // S_SAW3
  states[Ord(S_PLASMA)].action.acp1 := @A_WeaponReady; // S_PLASMA
  states[Ord(S_PLASMADOWN)].action.acp1 := @A_Lower; // S_PLASMADOWN
  states[Ord(S_PLASMAUP)].action.acp1 := @A_Raise; // S_PLASMAUP
  states[Ord(S_PLASMA1)].action.acp1 := @A_FirePlasma; // S_PLASMA1
  states[Ord(S_PLASMA2)].action.acp1 := @A_ReFire; // S_PLASMA2
  states[Ord(S_PLASMAFLASH1)].action.acp1 := @A_Light1; // S_PLASMAFLASH1
  states[Ord(S_PLASMAFLASH2)].action.acp1 := @A_Light1; // S_PLASMAFLASH2
  states[Ord(S_BFG)].action.acp1 := @A_WeaponReady; // S_BFG
  states[Ord(S_BFGDOWN)].action.acp1 := @A_Lower; // S_BFGDOWN
  states[Ord(S_BFGUP)].action.acp1 := @A_Raise; // S_BFGUP
  states[Ord(S_BFG1)].action.acp1 := @A_BFGsound; // S_BFG1
  states[Ord(S_BFG2)].action.acp1 := @A_GunFlash; // S_BFG2
  states[Ord(S_BFG3)].action.acp1 := @A_FireBFG; // S_BFG3
  states[Ord(S_BFG4)].action.acp1 := @A_ReFire; // S_BFG4
  states[Ord(S_BFGFLASH1)].action.acp1 := @A_Light1; // S_BFGFLASH1
  states[Ord(S_BFGFLASH2)].action.acp1 := @A_Light2; // S_BFGFLASH2
  states[Ord(S_BFGLAND3)].action.acp1 := @A_BFGSpray; // S_BFGLAND3
  states[Ord(S_EXPLODE1)].action.acp1 := @A_Explode; // S_EXPLODE1
  states[Ord(S_PLAY_PAIN2)].action.acp1 := @A_Pain; // S_PLAY_PAIN2
  states[Ord(S_PLAY_DIE2)].action.acp1 := @A_PlayerScream; // S_PLAY_DIE2
  states[Ord(S_PLAY_DIE3)].action.acp1 := @A_Fall; // S_PLAY_DIE3
  states[Ord(S_PLAY_XDIE2)].action.acp1 := @A_XScream; // S_PLAY_XDIE2
  states[Ord(S_PLAY_XDIE3)].action.acp1 := @A_Fall; // S_PLAY_XDIE3
  states[Ord(S_POSS_STND)].action.acp1 := @A_Look; // S_POSS_STND
  states[Ord(S_POSS_STND2)].action.acp1 := @A_Look; // S_POSS_STND2
  states[Ord(S_POSS_RUN1)].action.acp1 := @A_Chase; // S_POSS_RUN1
  states[Ord(S_POSS_RUN2)].action.acp1 := @A_Chase; // S_POSS_RUN2
  states[Ord(S_POSS_RUN3)].action.acp1 := @A_Chase; // S_POSS_RUN3
  states[Ord(S_POSS_RUN4)].action.acp1 := @A_Chase; // S_POSS_RUN4
  states[Ord(S_POSS_RUN5)].action.acp1 := @A_Chase; // S_POSS_RUN5
  states[Ord(S_POSS_RUN6)].action.acp1 := @A_Chase; // S_POSS_RUN6
  states[Ord(S_POSS_RUN7)].action.acp1 := @A_Chase; // S_POSS_RUN7
  states[Ord(S_POSS_RUN8)].action.acp1 := @A_Chase; // S_POSS_RUN8
  states[Ord(S_POSS_ATK1)].action.acp1 := @A_FaceTarget; // S_POSS_ATK1
  states[Ord(S_POSS_ATK2)].action.acp1 := @A_PosAttack; // S_POSS_ATK2
  states[Ord(S_POSS_PAIN2)].action.acp1 := @A_Pain; // S_POSS_PAIN2
  states[Ord(S_POSS_DIE2)].action.acp1 := @A_Scream; // S_POSS_DIE2
  states[Ord(S_POSS_DIE3)].action.acp1 := @A_Fall; // S_POSS_DIE3
  states[Ord(S_POSS_XDIE2)].action.acp1 := @A_XScream; // S_POSS_XDIE2
  states[Ord(S_POSS_XDIE3)].action.acp1 := @A_Fall; // S_POSS_XDIE3
  states[Ord(S_SPOS_STND)].action.acp1 := @A_Look; // S_SPOS_STND
  states[Ord(S_SPOS_STND2)].action.acp1 := @A_Look; // S_SPOS_STND2
  states[Ord(S_SPOS_RUN1)].action.acp1 := @A_Chase; // S_SPOS_RUN1
  states[Ord(S_SPOS_RUN2)].action.acp1 := @A_Chase; // S_SPOS_RUN2
  states[Ord(S_SPOS_RUN3)].action.acp1 := @A_Chase; // S_SPOS_RUN3
  states[Ord(S_SPOS_RUN4)].action.acp1 := @A_Chase; // S_SPOS_RUN4
  states[Ord(S_SPOS_RUN5)].action.acp1 := @A_Chase; // S_SPOS_RUN5
  states[Ord(S_SPOS_RUN6)].action.acp1 := @A_Chase; // S_SPOS_RUN6
  states[Ord(S_SPOS_RUN7)].action.acp1 := @A_Chase; // S_SPOS_RUN7
  states[Ord(S_SPOS_RUN8)].action.acp1 := @A_Chase; // S_SPOS_RUN8
  states[Ord(S_SPOS_ATK1)].action.acp1 := @A_FaceTarget; // S_SPOS_ATK1
  states[Ord(S_SPOS_ATK2)].action.acp1 := @A_SPosAttack; // S_SPOS_ATK2
  states[Ord(S_SPOS_PAIN2)].action.acp1 := @A_Pain; // S_SPOS_PAIN2
  states[Ord(S_SPOS_DIE2)].action.acp1 := @A_Scream; // S_SPOS_DIE2
  states[Ord(S_SPOS_DIE3)].action.acp1 := @A_Fall; // S_SPOS_DIE3
  states[Ord(S_SPOS_XDIE2)].action.acp1 := @A_XScream; // S_SPOS_XDIE2
  states[Ord(S_SPOS_XDIE3)].action.acp1 := @A_Fall; // S_SPOS_XDIE3
  states[Ord(S_VILE_STND)].action.acp1 := @A_Look; // S_VILE_STND
  states[Ord(S_VILE_STND2)].action.acp1 := @A_Look; // S_VILE_STND2
  states[Ord(S_VILE_RUN1)].action.acp1 := @A_VileChase; // S_VILE_RUN1
  states[Ord(S_VILE_RUN2)].action.acp1 := @A_VileChase; // S_VILE_RUN2
  states[Ord(S_VILE_RUN3)].action.acp1 := @A_VileChase; // S_VILE_RUN3
  states[Ord(S_VILE_RUN4)].action.acp1 := @A_VileChase; // S_VILE_RUN4
  states[Ord(S_VILE_RUN5)].action.acp1 := @A_VileChase; // S_VILE_RUN5
  states[Ord(S_VILE_RUN6)].action.acp1 := @A_VileChase; // S_VILE_RUN6
  states[Ord(S_VILE_RUN7)].action.acp1 := @A_VileChase; // S_VILE_RUN7
  states[Ord(S_VILE_RUN8)].action.acp1 := @A_VileChase; // S_VILE_RUN8
  states[Ord(S_VILE_RUN9)].action.acp1 := @A_VileChase; // S_VILE_RUN9
  states[Ord(S_VILE_RUN10)].action.acp1 := @A_VileChase; // S_VILE_RUN10
  states[Ord(S_VILE_RUN11)].action.acp1 := @A_VileChase; // S_VILE_RUN11
  states[Ord(S_VILE_RUN12)].action.acp1 := @A_VileChase; // S_VILE_RUN12
  states[Ord(S_VILE_ATK1)].action.acp1 := @A_VileStart; // S_VILE_ATK1
  states[Ord(S_VILE_ATK2)].action.acp1 := @A_FaceTarget; // S_VILE_ATK2
  states[Ord(S_VILE_ATK3)].action.acp1 := @A_VileTarget; // S_VILE_ATK3
  states[Ord(S_VILE_ATK4)].action.acp1 := @A_FaceTarget; // S_VILE_ATK4
  states[Ord(S_VILE_ATK5)].action.acp1 := @A_FaceTarget; // S_VILE_ATK5
  states[Ord(S_VILE_ATK6)].action.acp1 := @A_FaceTarget; // S_VILE_ATK6
  states[Ord(S_VILE_ATK7)].action.acp1 := @A_FaceTarget; // S_VILE_ATK7
  states[Ord(S_VILE_ATK8)].action.acp1 := @A_FaceTarget; // S_VILE_ATK8
  states[Ord(S_VILE_ATK9)].action.acp1 := @A_FaceTarget; // S_VILE_ATK9
  states[Ord(S_VILE_ATK10)].action.acp1 := @A_VileAttack; // S_VILE_ATK10
  states[Ord(S_VILE_PAIN2)].action.acp1 := @A_Pain; // S_VILE_PAIN2
  states[Ord(S_VILE_DIE2)].action.acp1 := @A_Scream; // S_VILE_DIE2
  states[Ord(S_VILE_DIE3)].action.acp1 := @A_Fall; // S_VILE_DIE3
  states[Ord(S_FIRE1)].action.acp1 := @A_StartFire; // S_FIRE1
  states[Ord(S_FIRE2)].action.acp1 := @A_Fire; // S_FIRE2
  states[Ord(S_FIRE3)].action.acp1 := @A_Fire; // S_FIRE3
  states[Ord(S_FIRE4)].action.acp1 := @A_Fire; // S_FIRE4
  states[Ord(S_FIRE5)].action.acp1 := @A_FireCrackle; // S_FIRE5
  states[Ord(S_FIRE6)].action.acp1 := @A_Fire; // S_FIRE6
  states[Ord(S_FIRE7)].action.acp1 := @A_Fire; // S_FIRE7
  states[Ord(S_FIRE8)].action.acp1 := @A_Fire; // S_FIRE8
  states[Ord(S_FIRE9)].action.acp1 := @A_Fire; // S_FIRE9
  states[Ord(S_FIRE10)].action.acp1 := @A_Fire; // S_FIRE10
  states[Ord(S_FIRE11)].action.acp1 := @A_Fire; // S_FIRE11
  states[Ord(S_FIRE12)].action.acp1 := @A_Fire; // S_FIRE12
  states[Ord(S_FIRE13)].action.acp1 := @A_Fire; // S_FIRE13
  states[Ord(S_FIRE14)].action.acp1 := @A_Fire; // S_FIRE14
  states[Ord(S_FIRE15)].action.acp1 := @A_Fire; // S_FIRE15
  states[Ord(S_FIRE16)].action.acp1 := @A_Fire; // S_FIRE16
  states[Ord(S_FIRE17)].action.acp1 := @A_Fire; // S_FIRE17
  states[Ord(S_FIRE18)].action.acp1 := @A_Fire; // S_FIRE18
  states[Ord(S_FIRE19)].action.acp1 := @A_FireCrackle; // S_FIRE19
  states[Ord(S_FIRE20)].action.acp1 := @A_Fire; // S_FIRE20
  states[Ord(S_FIRE21)].action.acp1 := @A_Fire; // S_FIRE21
  states[Ord(S_FIRE22)].action.acp1 := @A_Fire; // S_FIRE22
  states[Ord(S_FIRE23)].action.acp1 := @A_Fire; // S_FIRE23
  states[Ord(S_FIRE24)].action.acp1 := @A_Fire; // S_FIRE24
  states[Ord(S_FIRE25)].action.acp1 := @A_Fire; // S_FIRE25
  states[Ord(S_FIRE26)].action.acp1 := @A_Fire; // S_FIRE26
  states[Ord(S_FIRE27)].action.acp1 := @A_Fire; // S_FIRE27
  states[Ord(S_FIRE28)].action.acp1 := @A_Fire; // S_FIRE28
  states[Ord(S_FIRE29)].action.acp1 := @A_Fire; // S_FIRE29
  states[Ord(S_FIRE30)].action.acp1 := @A_Fire; // S_FIRE30
  states[Ord(S_TRACER)].action.acp1 := @A_Tracer; // S_TRACER
  states[Ord(S_TRACER2)].action.acp1 := @A_Tracer; // S_TRACER2
  states[Ord(S_SKEL_STND)].action.acp1 := @A_Look; // S_SKEL_STND
  states[Ord(S_SKEL_STND2)].action.acp1 := @A_Look; // S_SKEL_STND2
  states[Ord(S_SKEL_RUN1)].action.acp1 := @A_Chase; // S_SKEL_RUN1
  states[Ord(S_SKEL_RUN2)].action.acp1 := @A_Chase; // S_SKEL_RUN2
  states[Ord(S_SKEL_RUN3)].action.acp1 := @A_Chase; // S_SKEL_RUN3
  states[Ord(S_SKEL_RUN4)].action.acp1 := @A_Chase; // S_SKEL_RUN4
  states[Ord(S_SKEL_RUN5)].action.acp1 := @A_Chase; // S_SKEL_RUN5
  states[Ord(S_SKEL_RUN6)].action.acp1 := @A_Chase; // S_SKEL_RUN6
  states[Ord(S_SKEL_RUN7)].action.acp1 := @A_Chase; // S_SKEL_RUN7
  states[Ord(S_SKEL_RUN8)].action.acp1 := @A_Chase; // S_SKEL_RUN8
  states[Ord(S_SKEL_RUN9)].action.acp1 := @A_Chase; // S_SKEL_RUN9
  states[Ord(S_SKEL_RUN10)].action.acp1 := @A_Chase; // S_SKEL_RUN10
  states[Ord(S_SKEL_RUN11)].action.acp1 := @A_Chase; // S_SKEL_RUN11
  states[Ord(S_SKEL_RUN12)].action.acp1 := @A_Chase; // S_SKEL_RUN12
  states[Ord(S_SKEL_FIST1)].action.acp1 := @A_FaceTarget; // S_SKEL_FIST1
  states[Ord(S_SKEL_FIST2)].action.acp1 := @A_SkelWhoosh; // S_SKEL_FIST2
  states[Ord(S_SKEL_FIST3)].action.acp1 := @A_FaceTarget; // S_SKEL_FIST3
  states[Ord(S_SKEL_FIST4)].action.acp1 := @A_SkelFist; // S_SKEL_FIST4
  states[Ord(S_SKEL_MISS1)].action.acp1 := @A_FaceTarget; // S_SKEL_MISS1
  states[Ord(S_SKEL_MISS2)].action.acp1 := @A_FaceTarget; // S_SKEL_MISS2
  states[Ord(S_SKEL_MISS3)].action.acp1 := @A_SkelMissile; // S_SKEL_MISS3
  states[Ord(S_SKEL_MISS4)].action.acp1 := @A_FaceTarget; // S_SKEL_MISS4
  states[Ord(S_SKEL_PAIN2)].action.acp1 := @A_Pain; // S_SKEL_PAIN2
  states[Ord(S_SKEL_DIE3)].action.acp1 := @A_Scream; // S_SKEL_DIE3
  states[Ord(S_SKEL_DIE4)].action.acp1 := @A_Fall; // S_SKEL_DIE4
  states[Ord(S_FATT_STND)].action.acp1 := @A_Look; // S_FATT_STND
  states[Ord(S_FATT_STND2)].action.acp1 := @A_Look; // S_FATT_STND2
  states[Ord(S_FATT_RUN1)].action.acp1 := @A_Chase; // S_FATT_RUN1
  states[Ord(S_FATT_RUN2)].action.acp1 := @A_Chase; // S_FATT_RUN2
  states[Ord(S_FATT_RUN3)].action.acp1 := @A_Chase; // S_FATT_RUN3
  states[Ord(S_FATT_RUN4)].action.acp1 := @A_Chase; // S_FATT_RUN4
  states[Ord(S_FATT_RUN5)].action.acp1 := @A_Chase; // S_FATT_RUN5
  states[Ord(S_FATT_RUN6)].action.acp1 := @A_Chase; // S_FATT_RUN6
  states[Ord(S_FATT_RUN7)].action.acp1 := @A_Chase; // S_FATT_RUN7
  states[Ord(S_FATT_RUN8)].action.acp1 := @A_Chase; // S_FATT_RUN8
  states[Ord(S_FATT_RUN9)].action.acp1 := @A_Chase; // S_FATT_RUN9
  states[Ord(S_FATT_RUN10)].action.acp1 := @A_Chase; // S_FATT_RUN10
  states[Ord(S_FATT_RUN11)].action.acp1 := @A_Chase; // S_FATT_RUN11
  states[Ord(S_FATT_RUN12)].action.acp1 := @A_Chase; // S_FATT_RUN12
  states[Ord(S_FATT_ATK1)].action.acp1 := @A_FatRaise; // S_FATT_ATK1
  states[Ord(S_FATT_ATK2)].action.acp1 := @A_FatAttack1; // S_FATT_ATK2
  states[Ord(S_FATT_ATK3)].action.acp1 := @A_FaceTarget; // S_FATT_ATK3
  states[Ord(S_FATT_ATK4)].action.acp1 := @A_FaceTarget; // S_FATT_ATK4
  states[Ord(S_FATT_ATK5)].action.acp1 := @A_FatAttack2; // S_FATT_ATK5
  states[Ord(S_FATT_ATK6)].action.acp1 := @A_FaceTarget; // S_FATT_ATK6
  states[Ord(S_FATT_ATK7)].action.acp1 := @A_FaceTarget; // S_FATT_ATK7
  states[Ord(S_FATT_ATK8)].action.acp1 := @A_FatAttack3; // S_FATT_ATK8
  states[Ord(S_FATT_ATK9)].action.acp1 := @A_FaceTarget; // S_FATT_ATK9
  states[Ord(S_FATT_ATK10)].action.acp1 := @A_FaceTarget; // S_FATT_ATK10
  states[Ord(S_FATT_PAIN2)].action.acp1 := @A_Pain; // S_FATT_PAIN2
  states[Ord(S_FATT_DIE2)].action.acp1 := @A_Scream; // S_FATT_DIE2
  states[Ord(S_FATT_DIE3)].action.acp1 := @A_Fall; // S_FATT_DIE3
  states[Ord(S_FATT_DIE10)].action.acp1 := @A_BossDeath; // S_FATT_DIE10
  states[Ord(S_CPOS_STND)].action.acp1 := @A_Look; // S_CPOS_STND
  states[Ord(S_CPOS_STND2)].action.acp1 := @A_Look; // S_CPOS_STND2
  states[Ord(S_CPOS_RUN1)].action.acp1 := @A_Chase; // S_CPOS_RUN1
  states[Ord(S_CPOS_RUN2)].action.acp1 := @A_Chase; // S_CPOS_RUN2
  states[Ord(S_CPOS_RUN3)].action.acp1 := @A_Chase; // S_CPOS_RUN3
  states[Ord(S_CPOS_RUN4)].action.acp1 := @A_Chase; // S_CPOS_RUN4
  states[Ord(S_CPOS_RUN5)].action.acp1 := @A_Chase; // S_CPOS_RUN5
  states[Ord(S_CPOS_RUN6)].action.acp1 := @A_Chase; // S_CPOS_RUN6
  states[Ord(S_CPOS_RUN7)].action.acp1 := @A_Chase; // S_CPOS_RUN7
  states[Ord(S_CPOS_RUN8)].action.acp1 := @A_Chase; // S_CPOS_RUN8
  states[Ord(S_CPOS_ATK1)].action.acp1 := @A_FaceTarget; // S_CPOS_ATK1
  states[Ord(S_CPOS_ATK2)].action.acp1 := @A_CPosAttack; // S_CPOS_ATK2
  states[Ord(S_CPOS_ATK3)].action.acp1 := @A_CPosAttack; // S_CPOS_ATK3
  states[Ord(S_CPOS_ATK4)].action.acp1 := @A_CPosRefire; // S_CPOS_ATK4
  states[Ord(S_CPOS_PAIN2)].action.acp1 := @A_Pain; // S_CPOS_PAIN2
  states[Ord(S_CPOS_DIE2)].action.acp1 := @A_Scream; // S_CPOS_DIE2
  states[Ord(S_CPOS_DIE3)].action.acp1 := @A_Fall; // S_CPOS_DIE3
  states[Ord(S_CPOS_XDIE2)].action.acp1 := @A_XScream; // S_CPOS_XDIE2
  states[Ord(S_CPOS_XDIE3)].action.acp1 := @A_Fall; // S_CPOS_XDIE3
  states[Ord(S_TROO_STND)].action.acp1 := @A_Look; // S_TROO_STND
  states[Ord(S_TROO_STND2)].action.acp1 := @A_Look; // S_TROO_STND2
  states[Ord(S_TROO_RUN1)].action.acp1 := @A_Chase; // S_TROO_RUN1
  states[Ord(S_TROO_RUN2)].action.acp1 := @A_Chase; // S_TROO_RUN2
  states[Ord(S_TROO_RUN3)].action.acp1 := @A_Chase; // S_TROO_RUN3
  states[Ord(S_TROO_RUN4)].action.acp1 := @A_Chase; // S_TROO_RUN4
  states[Ord(S_TROO_RUN5)].action.acp1 := @A_Chase; // S_TROO_RUN5
  states[Ord(S_TROO_RUN6)].action.acp1 := @A_Chase; // S_TROO_RUN6
  states[Ord(S_TROO_RUN7)].action.acp1 := @A_Chase; // S_TROO_RUN7
  states[Ord(S_TROO_RUN8)].action.acp1 := @A_Chase; // S_TROO_RUN8
  states[Ord(S_TROO_ATK1)].action.acp1 := @A_FaceTarget; // S_TROO_ATK1
  states[Ord(S_TROO_ATK2)].action.acp1 := @A_FaceTarget; // S_TROO_ATK2
  states[Ord(S_TROO_ATK3)].action.acp1 := @A_TroopAttack; // S_TROO_ATK3
  states[Ord(S_TROO_PAIN2)].action.acp1 := @A_Pain; // S_TROO_PAIN2
  states[Ord(S_TROO_DIE2)].action.acp1 := @A_Scream; // S_TROO_DIE2
  states[Ord(S_TROO_DIE4)].action.acp1 := @A_Fall; // S_TROO_DIE4
  states[Ord(S_TROO_XDIE2)].action.acp1 := @A_XScream; // S_TROO_XDIE2
  states[Ord(S_TROO_XDIE4)].action.acp1 := @A_Fall; // S_TROO_XDIE4
  states[Ord(S_SARG_STND)].action.acp1 := @A_Look; // S_SARG_STND
  states[Ord(S_SARG_STND2)].action.acp1 := @A_Look; // S_SARG_STND2
  states[Ord(S_SARG_RUN1)].action.acp1 := @A_Chase; // S_SARG_RUN1
  states[Ord(S_SARG_RUN2)].action.acp1 := @A_Chase; // S_SARG_RUN2
  states[Ord(S_SARG_RUN3)].action.acp1 := @A_Chase; // S_SARG_RUN3
  states[Ord(S_SARG_RUN4)].action.acp1 := @A_Chase; // S_SARG_RUN4
  states[Ord(S_SARG_RUN5)].action.acp1 := @A_Chase; // S_SARG_RUN5
  states[Ord(S_SARG_RUN6)].action.acp1 := @A_Chase; // S_SARG_RUN6
  states[Ord(S_SARG_RUN7)].action.acp1 := @A_Chase; // S_SARG_RUN7
  states[Ord(S_SARG_RUN8)].action.acp1 := @A_Chase; // S_SARG_RUN8
  states[Ord(S_SARG_ATK1)].action.acp1 := @A_FaceTarget; // S_SARG_ATK1
  states[Ord(S_SARG_ATK2)].action.acp1 := @A_FaceTarget; // S_SARG_ATK2
  states[Ord(S_SARG_ATK3)].action.acp1 := @A_SargAttack; // S_SARG_ATK3
  states[Ord(S_SARG_PAIN2)].action.acp1 := @A_Pain; // S_SARG_PAIN2
  states[Ord(S_SARG_DIE2)].action.acp1 := @A_Scream; // S_SARG_DIE2
  states[Ord(S_SARG_DIE4)].action.acp1 := @A_Fall; // S_SARG_DIE4
  states[Ord(S_HEAD_STND)].action.acp1 := @A_Look; // S_HEAD_STND
  states[Ord(S_HEAD_RUN1)].action.acp1 := @A_Chase; // S_HEAD_RUN1
  states[Ord(S_HEAD_ATK1)].action.acp1 := @A_FaceTarget; // S_HEAD_ATK1
  states[Ord(S_HEAD_ATK2)].action.acp1 := @A_FaceTarget; // S_HEAD_ATK2
  states[Ord(S_HEAD_ATK3)].action.acp1 := @A_HeadAttack; // S_HEAD_ATK3
  states[Ord(S_HEAD_PAIN2)].action.acp1 := @A_Pain; // S_HEAD_PAIN2
  states[Ord(S_HEAD_DIE2)].action.acp1 := @A_Scream; // S_HEAD_DIE2
  states[Ord(S_HEAD_DIE5)].action.acp1 := @A_Fall; // S_HEAD_DIE5
  states[Ord(S_BOSS_STND)].action.acp1 := @A_Look; // S_BOSS_STND
  states[Ord(S_BOSS_STND2)].action.acp1 := @A_Look; // S_BOSS_STND2
  states[Ord(S_BOSS_RUN1)].action.acp1 := @A_Chase; // S_BOSS_RUN1
  states[Ord(S_BOSS_RUN2)].action.acp1 := @A_Chase; // S_BOSS_RUN2
  states[Ord(S_BOSS_RUN3)].action.acp1 := @A_Chase; // S_BOSS_RUN3
  states[Ord(S_BOSS_RUN4)].action.acp1 := @A_Chase; // S_BOSS_RUN4
  states[Ord(S_BOSS_RUN5)].action.acp1 := @A_Chase; // S_BOSS_RUN5
  states[Ord(S_BOSS_RUN6)].action.acp1 := @A_Chase; // S_BOSS_RUN6
  states[Ord(S_BOSS_RUN7)].action.acp1 := @A_Chase; // S_BOSS_RUN7
  states[Ord(S_BOSS_RUN8)].action.acp1 := @A_Chase; // S_BOSS_RUN8
  states[Ord(S_BOSS_ATK1)].action.acp1 := @A_FaceTarget; // S_BOSS_ATK1
  states[Ord(S_BOSS_ATK2)].action.acp1 := @A_FaceTarget; // S_BOSS_ATK2
  states[Ord(S_BOSS_ATK3)].action.acp1 := @A_BruisAttack; // S_BOSS_ATK3
  states[Ord(S_BOSS_PAIN2)].action.acp1 := @A_Pain; // S_BOSS_PAIN2
  states[Ord(S_BOSS_DIE2)].action.acp1 := @A_Scream; // S_BOSS_DIE2
  states[Ord(S_BOSS_DIE4)].action.acp1 := @A_Fall; // S_BOSS_DIE4
  states[Ord(S_BOSS_DIE7)].action.acp1 := @A_BossDeath; // S_BOSS_DIE7
  states[Ord(S_BOS2_STND)].action.acp1 := @A_Look; // S_BOS2_STND
  states[Ord(S_BOS2_STND2)].action.acp1 := @A_Look; // S_BOS2_STND2
  states[Ord(S_BOS2_RUN1)].action.acp1 := @A_Chase; // S_BOS2_RUN1
  states[Ord(S_BOS2_RUN2)].action.acp1 := @A_Chase; // S_BOS2_RUN2
  states[Ord(S_BOS2_RUN3)].action.acp1 := @A_Chase; // S_BOS2_RUN3
  states[Ord(S_BOS2_RUN4)].action.acp1 := @A_Chase; // S_BOS2_RUN4
  states[Ord(S_BOS2_RUN5)].action.acp1 := @A_Chase; // S_BOS2_RUN5
  states[Ord(S_BOS2_RUN6)].action.acp1 := @A_Chase; // S_BOS2_RUN6
  states[Ord(S_BOS2_RUN7)].action.acp1 := @A_Chase; // S_BOS2_RUN7
  states[Ord(S_BOS2_RUN8)].action.acp1 := @A_Chase; // S_BOS2_RUN8
  states[Ord(S_BOS2_ATK1)].action.acp1 := @A_FaceTarget; // S_BOS2_ATK1
  states[Ord(S_BOS2_ATK2)].action.acp1 := @A_FaceTarget; // S_BOS2_ATK2
  states[Ord(S_BOS2_ATK3)].action.acp1 := @A_BruisAttack; // S_BOS2_ATK3
  states[Ord(S_BOS2_PAIN2)].action.acp1 := @A_Pain; // S_BOS2_PAIN2
  states[Ord(S_BOS2_DIE2)].action.acp1 := @A_Scream; // S_BOS2_DIE2
  states[Ord(S_BOS2_DIE4)].action.acp1 := @A_Fall; // S_BOS2_DIE4
  states[Ord(S_SKULL_STND)].action.acp1 := @A_Look; // S_SKULL_STND
  states[Ord(S_SKULL_STND2)].action.acp1 := @A_Look; // S_SKULL_STND2
  states[Ord(S_SKULL_RUN1)].action.acp1 := @A_Chase; // S_SKULL_RUN1
  states[Ord(S_SKULL_RUN2)].action.acp1 := @A_Chase; // S_SKULL_RUN2
  states[Ord(S_SKULL_ATK1)].action.acp1 := @A_FaceTarget; // S_SKULL_ATK1
  states[Ord(S_SKULL_ATK2)].action.acp1 := @A_SkullAttack; // S_SKULL_ATK2
  states[Ord(S_SKULL_PAIN2)].action.acp1 := @A_Pain; // S_SKULL_PAIN2
  states[Ord(S_SKULL_DIE2)].action.acp1 := @A_Scream; // S_SKULL_DIE2
  states[Ord(S_SKULL_DIE4)].action.acp1 := @A_Fall; // S_SKULL_DIE4
  states[Ord(S_SPID_STND)].action.acp1 := @A_Look; // S_SPID_STND
  states[Ord(S_SPID_STND2)].action.acp1 := @A_Look; // S_SPID_STND2
  states[Ord(S_SPID_RUN1)].action.acp1 := @A_Metal; // S_SPID_RUN1
  states[Ord(S_SPID_RUN2)].action.acp1 := @A_Chase; // S_SPID_RUN2
  states[Ord(S_SPID_RUN3)].action.acp1 := @A_Chase; // S_SPID_RUN3
  states[Ord(S_SPID_RUN4)].action.acp1 := @A_Chase; // S_SPID_RUN4
  states[Ord(S_SPID_RUN5)].action.acp1 := @A_Metal; // S_SPID_RUN5
  states[Ord(S_SPID_RUN6)].action.acp1 := @A_Chase; // S_SPID_RUN6
  states[Ord(S_SPID_RUN7)].action.acp1 := @A_Chase; // S_SPID_RUN7
  states[Ord(S_SPID_RUN8)].action.acp1 := @A_Chase; // S_SPID_RUN8
  states[Ord(S_SPID_RUN9)].action.acp1 := @A_Metal; // S_SPID_RUN9
  states[Ord(S_SPID_RUN10)].action.acp1 := @A_Chase; // S_SPID_RUN10
  states[Ord(S_SPID_RUN11)].action.acp1 := @A_Chase; // S_SPID_RUN11
  states[Ord(S_SPID_RUN12)].action.acp1 := @A_Chase; // S_SPID_RUN12
  states[Ord(S_SPID_ATK1)].action.acp1 := @A_FaceTarget; // S_SPID_ATK1
  states[Ord(S_SPID_ATK2)].action.acp1 := @A_SPosAttack; // S_SPID_ATK2
  states[Ord(S_SPID_ATK3)].action.acp1 := @A_SPosAttack; // S_SPID_ATK3
  states[Ord(S_SPID_ATK4)].action.acp1 := @A_SpidRefire; // S_SPID_ATK4
  states[Ord(S_SPID_PAIN2)].action.acp1 := @A_Pain; // S_SPID_PAIN2
  states[Ord(S_SPID_DIE1)].action.acp1 := @A_Scream; // S_SPID_DIE1
  states[Ord(S_SPID_DIE2)].action.acp1 := @A_Fall; // S_SPID_DIE2
  states[Ord(S_SPID_DIE11)].action.acp1 := @A_BossDeath; // S_SPID_DIE11
  states[Ord(S_BSPI_STND)].action.acp1 := @A_Look; // S_BSPI_STND
  states[Ord(S_BSPI_STND2)].action.acp1 := @A_Look; // S_BSPI_STND2
  states[Ord(S_BSPI_RUN1)].action.acp1 := @A_BabyMetal; // S_BSPI_RUN1
  states[Ord(S_BSPI_RUN2)].action.acp1 := @A_Chase; // S_BSPI_RUN2
  states[Ord(S_BSPI_RUN3)].action.acp1 := @A_Chase; // S_BSPI_RUN3
  states[Ord(S_BSPI_RUN4)].action.acp1 := @A_Chase; // S_BSPI_RUN4
  states[Ord(S_BSPI_RUN5)].action.acp1 := @A_Chase; // S_BSPI_RUN5
  states[Ord(S_BSPI_RUN6)].action.acp1 := @A_Chase; // S_BSPI_RUN6
  states[Ord(S_BSPI_RUN7)].action.acp1 := @A_BabyMetal; // S_BSPI_RUN7
  states[Ord(S_BSPI_RUN8)].action.acp1 := @A_Chase; // S_BSPI_RUN8
  states[Ord(S_BSPI_RUN9)].action.acp1 := @A_Chase; // S_BSPI_RUN9
  states[Ord(S_BSPI_RUN10)].action.acp1 := @A_Chase; // S_BSPI_RUN10
  states[Ord(S_BSPI_RUN11)].action.acp1 := @A_Chase; // S_BSPI_RUN11
  states[Ord(S_BSPI_RUN12)].action.acp1 := @A_Chase; // S_BSPI_RUN12
  states[Ord(S_BSPI_ATK1)].action.acp1 := @A_FaceTarget; // S_BSPI_ATK1
  states[Ord(S_BSPI_ATK2)].action.acp1 := @A_BspiAttack; // S_BSPI_ATK2
  states[Ord(S_BSPI_ATK4)].action.acp1 := @A_SpidRefire; // S_BSPI_ATK4
  states[Ord(S_BSPI_PAIN2)].action.acp1 := @A_Pain; // S_BSPI_PAIN2
  states[Ord(S_BSPI_DIE1)].action.acp1 := @A_Scream; // S_BSPI_DIE1
  states[Ord(S_BSPI_DIE2)].action.acp1 := @A_Fall; // S_BSPI_DIE2
  states[Ord(S_BSPI_DIE7)].action.acp1 := @A_BossDeath; // S_BSPI_DIE7
  states[Ord(S_CYBER_STND)].action.acp1 := @A_Look; // S_CYBER_STND
  states[Ord(S_CYBER_STND2)].action.acp1 := @A_Look; // S_CYBER_STND2
  states[Ord(S_CYBER_RUN1)].action.acp1 := @A_Hoof; // S_CYBER_RUN1
  states[Ord(S_CYBER_RUN2)].action.acp1 := @A_Chase; // S_CYBER_RUN2
  states[Ord(S_CYBER_RUN3)].action.acp1 := @A_Chase; // S_CYBER_RUN3
  states[Ord(S_CYBER_RUN4)].action.acp1 := @A_Chase; // S_CYBER_RUN4
  states[Ord(S_CYBER_RUN5)].action.acp1 := @A_Chase; // S_CYBER_RUN5
  states[Ord(S_CYBER_RUN6)].action.acp1 := @A_Chase; // S_CYBER_RUN6
  states[Ord(S_CYBER_RUN7)].action.acp1 := @A_Metal; // S_CYBER_RUN7
  states[Ord(S_CYBER_RUN8)].action.acp1 := @A_Chase; // S_CYBER_RUN8
  states[Ord(S_CYBER_ATK1)].action.acp1 := @A_FaceTarget; // S_CYBER_ATK1
  states[Ord(S_CYBER_ATK2)].action.acp1 := @A_CyberAttack; // S_CYBER_ATK2
  states[Ord(S_CYBER_ATK3)].action.acp1 := @A_FaceTarget; // S_CYBER_ATK3
  states[Ord(S_CYBER_ATK4)].action.acp1 := @A_CyberAttack; // S_CYBER_ATK4
  states[Ord(S_CYBER_ATK5)].action.acp1 := @A_FaceTarget; // S_CYBER_ATK5
  states[Ord(S_CYBER_ATK6)].action.acp1 := @A_CyberAttack; // S_CYBER_ATK6
  states[Ord(S_CYBER_PAIN)].action.acp1 := @A_Pain; // S_CYBER_PAIN
  states[Ord(S_CYBER_DIE2)].action.acp1 := @A_Scream; // S_CYBER_DIE2
  states[Ord(S_CYBER_DIE6)].action.acp1 := @A_Fall; // S_CYBER_DIE6
  states[Ord(S_CYBER_DIE10)].action.acp1 := @A_BossDeath; // S_CYBER_DIE10
  states[Ord(S_PAIN_STND)].action.acp1 := @A_Look; // S_PAIN_STND
  states[Ord(S_PAIN_RUN1)].action.acp1 := @A_Chase; // S_PAIN_RUN1
  states[Ord(S_PAIN_RUN2)].action.acp1 := @A_Chase; // S_PAIN_RUN2
  states[Ord(S_PAIN_RUN3)].action.acp1 := @A_Chase; // S_PAIN_RUN3
  states[Ord(S_PAIN_RUN4)].action.acp1 := @A_Chase; // S_PAIN_RUN4
  states[Ord(S_PAIN_RUN5)].action.acp1 := @A_Chase; // S_PAIN_RUN5
  states[Ord(S_PAIN_RUN6)].action.acp1 := @A_Chase; // S_PAIN_RUN6
  states[Ord(S_PAIN_ATK1)].action.acp1 := @A_FaceTarget; // S_PAIN_ATK1
  states[Ord(S_PAIN_ATK2)].action.acp1 := @A_FaceTarget; // S_PAIN_ATK2
  states[Ord(S_PAIN_ATK3)].action.acp1 := @A_FaceTarget; // S_PAIN_ATK3
  states[Ord(S_PAIN_ATK4)].action.acp1 := @A_PainAttack; // S_PAIN_ATK4
  states[Ord(S_PAIN_PAIN2)].action.acp1 := @A_Pain; // S_PAIN_PAIN2
  states[Ord(S_PAIN_DIE2)].action.acp1 := @A_Scream; // S_PAIN_DIE2
  states[Ord(S_PAIN_DIE5)].action.acp1 := @A_PainDie; // S_PAIN_DIE5
  states[Ord(S_SSWV_STND)].action.acp1 := @A_Look; // S_SSWV_STND
  states[Ord(S_SSWV_STND2)].action.acp1 := @A_Look; // S_SSWV_STND2
  states[Ord(S_SSWV_RUN1)].action.acp1 := @A_Chase; // S_SSWV_RUN1
  states[Ord(S_SSWV_RUN2)].action.acp1 := @A_Chase; // S_SSWV_RUN2
  states[Ord(S_SSWV_RUN3)].action.acp1 := @A_Chase; // S_SSWV_RUN3
  states[Ord(S_SSWV_RUN4)].action.acp1 := @A_Chase; // S_SSWV_RUN4
  states[Ord(S_SSWV_RUN5)].action.acp1 := @A_Chase; // S_SSWV_RUN5
  states[Ord(S_SSWV_RUN6)].action.acp1 := @A_Chase; // S_SSWV_RUN6
  states[Ord(S_SSWV_RUN7)].action.acp1 := @A_Chase; // S_SSWV_RUN7
  states[Ord(S_SSWV_RUN8)].action.acp1 := @A_Chase; // S_SSWV_RUN8
  states[Ord(S_SSWV_ATK1)].action.acp1 := @A_FaceTarget; // S_SSWV_ATK1
  states[Ord(S_SSWV_ATK2)].action.acp1 := @A_FaceTarget; // S_SSWV_ATK2
  states[Ord(S_SSWV_ATK3)].action.acp1 := @A_CPosAttack; // S_SSWV_ATK3
  states[Ord(S_SSWV_ATK4)].action.acp1 := @A_FaceTarget; // S_SSWV_ATK4
  states[Ord(S_SSWV_ATK5)].action.acp1 := @A_CPosAttack; // S_SSWV_ATK5
  states[Ord(S_SSWV_ATK6)].action.acp1 := @A_CPosRefire; // S_SSWV_ATK6
  states[Ord(S_SSWV_PAIN2)].action.acp1 := @A_Pain; // S_SSWV_PAIN2
  states[Ord(S_SSWV_DIE2)].action.acp1 := @A_Scream; // S_SSWV_DIE2
  states[Ord(S_SSWV_DIE3)].action.acp1 := @A_Fall; // S_SSWV_DIE3
  states[Ord(S_SSWV_XDIE2)].action.acp1 := @A_XScream; // S_SSWV_XDIE2
  states[Ord(S_SSWV_XDIE3)].action.acp1 := @A_Fall; // S_SSWV_XDIE3
  states[Ord(S_COMMKEEN3)].action.acp1 := @A_Scream; // S_COMMKEEN3
  states[Ord(S_COMMKEEN11)].action.acp1 := @A_KeenDie; // S_COMMKEEN11
  states[Ord(S_KEENPAIN2)].action.acp1 := @A_Pain; // S_KEENPAIN2
  states[Ord(S_BRAIN_PAIN)].action.acp1 := @A_BrainPain; // S_BRAIN_PAIN
  states[Ord(S_BRAIN_DIE1)].action.acp1 := @A_BrainScream; // S_BRAIN_DIE1
  states[Ord(S_BRAIN_DIE4)].action.acp1 := @A_BrainDie; // S_BRAIN_DIE4
  states[Ord(S_BRAINEYE)].action.acp1 := @A_Look; // S_BRAINEYE
  states[Ord(S_BRAINEYESEE)].action.acp1 := @A_BrainAwake; // S_BRAINEYESEE
  states[Ord(S_BRAINEYE1)].action.acp1 := @A_BrainSpit; // S_BRAINEYE1
  states[Ord(S_SPAWN1)].action.acp1 := @A_SpawnSound; // S_SPAWN1
  states[Ord(S_SPAWN2)].action.acp1 := @A_SpawnFly; // S_SPAWN2
  states[Ord(S_SPAWN3)].action.acp1 := @A_SpawnFly; // S_SPAWN3
  states[Ord(S_SPAWN4)].action.acp1 := @A_SpawnFly; // S_SPAWN4
  states[Ord(S_SPAWNFIRE1)].action.acp1 := @A_Fire; // S_SPAWNFIRE1
  states[Ord(S_SPAWNFIRE2)].action.acp1 := @A_Fire; // S_SPAWNFIRE2
  states[Ord(S_SPAWNFIRE3)].action.acp1 := @A_Fire; // S_SPAWNFIRE3
  states[Ord(S_SPAWNFIRE4)].action.acp1 := @A_Fire; // S_SPAWNFIRE4
  states[Ord(S_SPAWNFIRE5)].action.acp1 := @A_Fire; // S_SPAWNFIRE5
  states[Ord(S_SPAWNFIRE6)].action.acp1 := @A_Fire; // S_SPAWNFIRE6
  states[Ord(S_SPAWNFIRE7)].action.acp1 := @A_Fire; // S_SPAWNFIRE7
  states[Ord(S_SPAWNFIRE8)].action.acp1 := @A_Fire; // S_SPAWNFIRE8
  states[Ord(S_BRAINEXPLODE3)].action.acp1 := @A_BrainExplode; // S_BRAINEXPLODE3
  states[Ord(S_BEXP2)].action.acp1 := @A_Scream; // S_BEXP2
  states[Ord(S_BEXP4)].action.acp1 := @A_Explode; // S_BEXP4
  // New states
  states[Ord(S_GRENADE)].action.acp1 := @A_Die; // S_GRENADE
  states[Ord(S_DETONATE)].action.acp1 := @A_Scream; // S_DETONATE
  states[Ord(S_DETONATE2)].action.acp1 := @A_Detonate; // S_DETONATE2
  states[Ord(S_DOGS_STND)].action.acp1 := @A_Look; // S_DOGS_STND
  states[Ord(S_DOGS_STND2)].action.acp1 := @A_Look; // S_DOGS_STND2
  states[Ord(S_DOGS_RUN1)].action.acp1 := @A_Chase; // S_DOGS_RUN1
  states[Ord(S_DOGS_RUN2)].action.acp1 := @A_Chase; // S_DOGS_RUN2
  states[Ord(S_DOGS_RUN3)].action.acp1 := @A_Chase; // S_DOGS_RUN3
  states[Ord(S_DOGS_RUN4)].action.acp1 := @A_Chase; // S_DOGS_RUN4
  states[Ord(S_DOGS_RUN5)].action.acp1 := @A_Chase; // S_DOGS_RUN5
  states[Ord(S_DOGS_RUN6)].action.acp1 := @A_Chase; // S_DOGS_RUN6
  states[Ord(S_DOGS_RUN7)].action.acp1 := @A_Chase; // S_DOGS_RUN7
  states[Ord(S_DOGS_RUN8)].action.acp1 := @A_Chase; // S_DOGS_RUN8
  states[Ord(S_DOGS_ATK1)].action.acp1 := @A_FaceTarget; // S_DOGS_ATK1
  states[Ord(S_DOGS_ATK2)].action.acp1 := @A_FaceTarget; // S_DOGS_ATK2
  states[Ord(S_DOGS_ATK3)].action.acp1 := @A_SargAttack; // S_DOGS_ATK3
  states[Ord(S_DOGS_PAIN2)].action.acp1 := @A_Pain; // S_DOGS_PAIN2
  states[Ord(S_DOGS_DIE2)].action.acp1 := @A_Scream; // S_DOGS_DIE2
  states[Ord(S_DOGS_DIE4)].action.acp1 := @A_Fall; // S_DOGS_DIE4
  states[Ord(S_OLDBFG1)].action.acp1 := @A_BFGsound; // S_OLDBFG1
  states[Ord(S_OLDBFG2)].action.acp1 := @A_FireOldBFG; // S_OLDBFG2
  states[Ord(S_OLDBFG3)].action.acp1 := @A_FireOldBFG; // S_OLDBFG3
  states[Ord(S_OLDBFG4)].action.acp1 := @A_FireOldBFG; // S_OLDBFG4
  states[Ord(S_OLDBFG5)].action.acp1 := @A_FireOldBFG; // S_OLDBFG5
  states[Ord(S_OLDBFG6)].action.acp1 := @A_FireOldBFG; // S_OLDBFG6
  states[Ord(S_OLDBFG7)].action.acp1 := @A_FireOldBFG; // S_OLDBFG7
  states[Ord(S_OLDBFG8)].action.acp1 := @A_FireOldBFG; // S_OLDBFG8
  states[Ord(S_OLDBFG9)].action.acp1 := @A_FireOldBFG; // S_OLDBFG9
  states[Ord(S_OLDBFG10)].action.acp1 := @A_FireOldBFG; // S_OLDBFG10
  states[Ord(S_OLDBFG11)].action.acp1 := @A_FireOldBFG; // S_OLDBFG11
  states[Ord(S_OLDBFG12)].action.acp1 := @A_FireOldBFG; // S_OLDBFG12
  states[Ord(S_OLDBFG13)].action.acp1 := @A_FireOldBFG; // S_OLDBFG13
  states[Ord(S_OLDBFG14)].action.acp1 := @A_FireOldBFG; // S_OLDBFG14
  states[Ord(S_OLDBFG15)].action.acp1 := @A_FireOldBFG; // S_OLDBFG15
  states[Ord(S_OLDBFG16)].action.acp1 := @A_FireOldBFG; // S_OLDBFG16
  states[Ord(S_OLDBFG17)].action.acp1 := @A_FireOldBFG; // S_OLDBFG17
  states[Ord(S_OLDBFG18)].action.acp1 := @A_FireOldBFG; // S_OLDBFG18
  states[Ord(S_OLDBFG19)].action.acp1 := @A_FireOldBFG; // S_OLDBFG19
  states[Ord(S_OLDBFG20)].action.acp1 := @A_FireOldBFG; // S_OLDBFG20
  states[Ord(S_OLDBFG21)].action.acp1 := @A_FireOldBFG; // S_OLDBFG21
  states[Ord(S_OLDBFG22)].action.acp1 := @A_FireOldBFG; // S_OLDBFG22
  states[Ord(S_OLDBFG23)].action.acp1 := @A_FireOldBFG; // S_OLDBFG23
  states[Ord(S_OLDBFG24)].action.acp1 := @A_FireOldBFG; // S_OLDBFG24
  states[Ord(S_OLDBFG25)].action.acp1 := @A_FireOldBFG; // S_OLDBFG25
  states[Ord(S_OLDBFG26)].action.acp1 := @A_FireOldBFG; // S_OLDBFG26
  states[Ord(S_OLDBFG27)].action.acp1 := @A_FireOldBFG; // S_OLDBFG27
  states[Ord(S_OLDBFG28)].action.acp1 := @A_FireOldBFG; // S_OLDBFG28
  states[Ord(S_OLDBFG29)].action.acp1 := @A_FireOldBFG; // S_OLDBFG29
  states[Ord(S_OLDBFG30)].action.acp1 := @A_FireOldBFG; // S_OLDBFG30
  states[Ord(S_OLDBFG31)].action.acp1 := @A_FireOldBFG; // S_OLDBFG31
  states[Ord(S_OLDBFG32)].action.acp1 := @A_FireOldBFG; // S_OLDBFG32
  states[Ord(S_OLDBFG33)].action.acp1 := @A_FireOldBFG; // S_OLDBFG33
  states[Ord(S_OLDBFG34)].action.acp1 := @A_FireOldBFG; // S_OLDBFG34
  states[Ord(S_OLDBFG35)].action.acp1 := @A_FireOldBFG; // S_OLDBFG35
  states[Ord(S_OLDBFG36)].action.acp1 := @A_FireOldBFG; // S_OLDBFG36
  states[Ord(S_OLDBFG37)].action.acp1 := @A_FireOldBFG; // S_OLDBFG37
  states[Ord(S_OLDBFG38)].action.acp1 := @A_FireOldBFG; // S_OLDBFG38
  states[Ord(S_OLDBFG39)].action.acp1 := @A_FireOldBFG; // S_OLDBFG39
  states[Ord(S_OLDBFG40)].action.acp1 := @A_FireOldBFG; // S_OLDBFG40
  states[Ord(S_OLDBFG41)].action.acp1 := @A_FireOldBFG; // S_OLDBFG41
  states[Ord(S_OLDBFG42)].action.acp1 := @A_Light0; // S_OLDBFG42
  states[Ord(S_OLDBFG43)].action.acp1 := @A_ReFire; // S_OLDBFG43
  states[Ord(S_BSKUL_STND)].action.acp1 := @A_Look; // S_BSKUL_STND
  states[Ord(S_BSKUL_RUN1)].action.acp1 := @A_Chase; // S_BSKUL_RUN1
  states[Ord(S_BSKUL_RUN2)].action.acp1 := @A_Chase; // S_BSKUL_RUN2
  states[Ord(S_BSKUL_RUN3)].action.acp1 := @A_Chase; // S_BSKUL_RUN3
  states[Ord(S_BSKUL_RUN4)].action.acp1 := @A_Chase; // S_BSKUL_RUN4
  states[Ord(S_BSKUL_ATK1)].action.acp1 := @A_FaceTarget; // S_BSKUL_ATK1
  states[Ord(S_BSKUL_ATK2)].action.acp1 := @A_BetaSkullAttack; // S_BSKUL_ATK2
  states[Ord(S_BSKUL_PAIN2)].action.acp1 := @A_Pain; // S_BSKUL_PAIN2
  states[Ord(S_BSKUL_DIE5)].action.acp1 := @A_Scream; // S_BSKUL_DIE5
  states[Ord(S_BSKUL_DIE7)].action.acp1 := @A_Fall; // S_BSKUL_DIE7
  states[Ord(S_BSKUL_DIE8)].action.acp1 := @A_Stop; // S_BSKUL_DIE8
  states[Ord(S_MUSHROOM)].action.acp1 := @A_Mushroom; // S_MUSHROOM
end;

function Info_GetNewState: integer;
begin
  realloc(states, numstates * SizeOf(state_t), (numstates + 1) * SizeOf(state_t));
  ZeroMemory(@states[numstates], SizeOf(state_t));
  result := numstates;
  inc(numstates);
end;

function Info_GetNewMobjInfo: integer;
begin
  realloc(mobjinfo, nummobjtypes * SizeOf(mobjinfo_t), (nummobjtypes + 1) * SizeOf(mobjinfo_t));
  ZeroMemory(@mobjinfo[nummobjtypes], SizeOf(mobjinfo_t));
  mobjinfo[nummobjtypes].inheritsfrom := -1; // Set to -1
  mobjinfo[nummobjtypes].doomednum := -1; // Set to -1
  mobjinfo[nummobjtypes].scale := FRACUNIT;
  result := nummobjtypes;
  inc(nummobjtypes);
end;

function Info_GetSpriteNumForName(const name: string): integer;
var
  spr_name: string;
  i: integer;
  check: integer;
begin
  result := atoi(name, -1);

  if (result >= 0) and (result < numsprites) and (itoa(result) = name) then
    exit;


  if Length(name) <> 4 then
  begin
    I_Error('Info_GetSpriteNumForName(): Sprite name %s must have 4 characters', [name]);
  end;

  spr_name := strupper(name);

  check := Ord(spr_name[1]) +
           Ord(spr_name[2]) shl 8 +
           Ord(spr_name[3]) shl 16 +
           Ord(spr_name[4]) shl 24;

  for i := 0 to numsprites - 1 do
    if sprnames[i] = check then
    begin
      result := i;
      exit;
    end;

  result := numsprites;

  sprnames[numsprites] := check;
  inc(numsprites);
  realloc(sprnames, numsprites * 4, (numsprites + 1) * 4);
  sprnames[numsprites] := 0;
end;

function Info_GetMobjNumForName(const name: string): integer;
var
  mobj_name: string;
  check: string;
  i: integer;
begin
  if name = '' then
  begin
    result := -1;
    exit;
  end;

  result := atoi(name, -1);

  if (result >= 0) and (result < nummobjtypes) and (itoa(result) = name) then
    exit;

  mobj_name := strupper(strtrim(name));
  if Length(mobj_name) > MOBJINFONAMESIZE then
    SetLength(mobj_name, MOBJINFONAMESIZE);
  for i := nummobjtypes - 1 downto 0 do
  begin
    check := Info_GetMobjName(i);
    check := strupper(strtrim(check));
    if check = mobj_name then
    begin
      result := i;
      exit;
    end;
  end;

  mobj_name := strremovespaces(strupper(strtrim(name)));
  if Length(mobj_name) > MOBJINFONAMESIZE then
    SetLength(mobj_name, MOBJINFONAMESIZE);
  for i := nummobjtypes - 1 downto 0 do
  begin
    check := Info_GetMobjName(i);
    check := strremovespaces(strupper(strtrim(check)));
    if check = mobj_name then
    begin
      result := i;
      exit;
    end;
  end;

  result := -1;
end;

procedure Info_SetMobjName(const mobj_no: integer; const name: string);
var
  i: integer;
  len: integer;
begin
  len := Length(name);
  if len > MOBJINFONAMESIZE then
    len := MOBJINFONAMESIZE;
  for i := 0 to len - 1 do
    mobjinfo[mobj_no].name[i] := name[i + 1];
  for i := len to MOBJINFONAMESIZE - 1 do
    mobjinfo[mobj_no].name[i] := #0;
end;

function Info_GetMobjName(const mobj_no: integer): string;
var
  i: integer;
  p: PChar;
begin
  result := '';
  p := @mobjinfo[mobj_no].name[0];
  for i := 0 to MOBJINFONAMESIZE - 1 do
    if p^ = #0 then
      exit
    else
    begin
      result := result + p^;
      inc(p);
    end;
end;

procedure Info_ShutDown;
var
  i: integer;
begin
  for i := 0 to numstates - 1 do
    if states[i].params <> nil then
      FreeAndNil(states[i].params);

  memfree(states, numstates * SizeOf(state_t));
  memfree(mobjinfo, nummobjtypes * SizeOf(mobjinfo_t));
  memfree(sprnames, numsprites * 4);
end;

function Info_GetInheritance(const imo: Pmobjinfo_t): integer;
var
  mo: Pmobjinfo_t;
  loops: integer;
begin
  mo := imo;
  result := mo.inheritsfrom;

  if result <> -1 then
  begin
    loops := 0;
    while true do
    begin
      mo := @mobjinfo[mo.inheritsfrom];
      if mo.inheritsfrom = -1 then
        exit
      else
        result := mo.inheritsfrom;
    // JVAL: Prevent wrong inheritances of actordef lumps
      inc(loops);
      if loops > nummobjtypes then
      begin
        result := -1;
        break;
      end;
    end;
  end;

  if result = -1 then
    result :=  (PCAST(imo) - PCAST(@mobjinfo[0])) div SizeOf(mobjinfo_t);

end;

end.

