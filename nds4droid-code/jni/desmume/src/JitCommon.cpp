/*
	Copyright (C) 2008-2010 DeSmuME team

	This file is free software: you can redistribute it and/or modify
	it under the terms of the GNU General Public License as published by
	the Free Software Foundation, either version 2 of the License, or
	(at your option) any later version.

	This file is distributed in the hope that it will be useful,
	but WITHOUT ANY WARRANTY; without even the implied warranty of
	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
	GNU General Public License for more details.

	You should have received a copy of the GNU General Public License
	along with the this software.  If not, see <http://www.gnu.org/licenses/>.
*/

#include "JitCommon.h"
#include "MMU.h"
#include "armcpu.h"
#include "debug.h"
#ifdef _MSC_VER
#include <Windows.h>
#endif

#ifdef HAVE_JIT

#ifdef MAPPED_JIT_FUNCS
static uintptr_t *JIT_MEM[2][32] = {
	//arm9
	{
		/* 0X*/	DUP2(g_JitLut.ARM9_ITCM),
		/* 1X*/	DUP2(g_JitLut.ARM9_ITCM), // mirror
		/* 2X*/	DUP2(g_JitLut.MAIN_MEM),
		/* 3X*/	DUP2(g_JitLut.SWIRAM),
		/* 4X*/	DUP2(NULL),
		/* 5X*/	DUP2(NULL),
		/* 6X*/		 NULL, 
					 g_JitLut.ARM9_LCDC,	// Plain ARM9-CPU Access (LCDC mode) (max 656KB)
		/* 7X*/	DUP2(NULL),
		/* 8X*/	DUP2(NULL),
		/* 9X*/	DUP2(NULL),
		/* AX*/	DUP2(NULL),
		/* BX*/	DUP2(NULL),
		/* CX*/	DUP2(NULL),
		/* DX*/	DUP2(NULL),
		/* EX*/	DUP2(NULL),
		/* FX*/	DUP2(g_JitLut.ARM9_BIOS)
	},
	//arm7
	{
		/* 0X*/	DUP2(g_JitLut.ARM7_BIOS),
		/* 1X*/	DUP2(NULL),
		/* 2X*/	DUP2(g_JitLut.MAIN_MEM),
		/* 3X*/	     g_JitLut.SWIRAM,
		             g_JitLut.ARM7_ERAM,
		/* 4X*/	     NULL,
		             g_JitLut.ARM7_WIRAM,
		/* 5X*/	DUP2(NULL),
		/* 6X*/		 g_JitLut.ARM7_WRAM,		// VRAM allocated as Work RAM to ARM7 (max. 256K)
					 NULL,
		/* 7X*/	DUP2(NULL),
		/* 8X*/	DUP2(NULL),
		/* 9X*/	DUP2(NULL),
		/* AX*/	DUP2(NULL),
		/* BX*/	DUP2(NULL),
		/* CX*/	DUP2(NULL),
		/* DX*/	DUP2(NULL),
		/* EX*/	DUP2(NULL),
		/* FX*/	DUP2(NULL)
	}
};

static u32 JIT_MASK[2][32] = {
	//arm9
	{
		/* 0X*/	DUP2(0x00007FFF),
		/* 1X*/	DUP2(0x00007FFF),
		/* 2X*/	DUP2(0x003FFFFF), // FIXME _MMU_MAIN_MEM_MASK
		/* 3X*/	DUP2(0x00007FFF),
		/* 4X*/	DUP2(0x00000000),
		/* 5X*/	DUP2(0x00000000),
		/* 6X*/		 0x00000000,
					 0x000FFFFF,
		/* 7X*/	DUP2(0x00000000),
		/* 8X*/	DUP2(0x00000000),
		/* 9X*/	DUP2(0x00000000),
		/* AX*/	DUP2(0x00000000),
		/* BX*/	DUP2(0x00000000),
		/* CX*/	DUP2(0x00000000),
		/* DX*/	DUP2(0x00000000),
		/* EX*/	DUP2(0x00000000),
		/* FX*/	DUP2(0x00007FFF)
	},
	//arm7
	{
		/* 0X*/	DUP2(0x00003FFF),
		/* 1X*/	DUP2(0x00000000),
		/* 2X*/	DUP2(0x003FFFFF),
		/* 3X*/	     0x00007FFF,
		             0x0000FFFF,
		/* 4X*/	     0x00000000,
		             0x0000FFFF,
		/* 5X*/	DUP2(0x00000000),
		/* 6X*/		 0x0003FFFF,
					 0x00000000,
		/* 7X*/	DUP2(0x00000000),
		/* 8X*/	DUP2(0x00000000),
		/* 9X*/	DUP2(0x00000000),
		/* AX*/	DUP2(0x00000000),
		/* BX*/	DUP2(0x00000000),
		/* CX*/	DUP2(0x00000000),
		/* DX*/	DUP2(0x00000000),
		/* EX*/	DUP2(0x00000000),
		/* FX*/	DUP2(0x00000000)
	}
};

CACHE_ALIGN JitLut g_JitLut;
#else
DS_ALIGN(4096) uintptr_t g_CompiledFuncs[1<<26] = {0};
#endif

#define INVALID_REG_ID ((u32)-1)

RegisterMap::RegisterMap(armcpu_t *armcpu, u32 HostRegCount)
	: m_HostRegCount(HostRegCount)
	, m_SwapData(0)
	, m_Context(NULL)
{
	m_GuestRegs = new GuestReg[GUESTREG_COUNT];
	for (u32 i = R0; i <= R15; i++)
	{
		m_GuestRegs[i].state = GuestReg::GRS_MEM;
		m_GuestRegs[i].hostreg = INVALID_REG_ID;
		m_GuestRegs[i].imm = 0;
		m_GuestRegs[i].adr = &armcpu->R[i];
	}

	m_GuestRegs[CPSR].state = GuestReg::GRS_MEM;
	m_GuestRegs[CPSR].hostreg = INVALID_REG_ID;
	m_GuestRegs[CPSR].imm = 0;
	m_GuestRegs[CPSR].adr = &armcpu->CPSR.val;

	m_HostRegs = new HostReg[HostRegCount];
	for (u32 i = 0; i < HostRegCount; i++)
	{
		m_HostRegs[i].guestreg = INVALID_REG_ID;
		m_HostRegs[i].swapdata = 0;
		m_HostRegs[i].alloced = false;
		m_HostRegs[i].locked = false;
		m_HostRegs[i].dirty = false;
	}
}

RegisterMap::~RegisterMap()
{
	delete [] m_GuestRegs;
	delete [] m_HostRegs;
}

bool RegisterMap::Start(void *context)
{
	if (m_Context)
		PROGINFO("RegisterMap::Start() : Context is not null\n");

	m_SwapData = 0;
	m_Context = context;

	// check
#ifdef DEVELOPER
	for (u32 i = 0; i < GUESTREG_COUNT; i++)
	{
		if (m_GuestRegs[i].state != GuestReg::GRS_MEM)
			PROGINFO("RegisterMap::Start() : GuestRegId[%u] is bad(state)\n", i);

		if (m_GuestRegs[i].hostreg != INVALID_REG_ID)
			PROGINFO("RegisterMap::Start() : GuestRegId[%u] is bad(hostreg)\n", i);

		if (m_GuestRegs[i].imm != 0)
			PROGINFO("RegisterMap::Start() : GuestRegId[%u] is bad(imm)\n", i);
	}

	for (u32 i = 0; i < m_HostRegCount; i++)
	{
		if (m_HostRegs[i].guestreg != INVALID_REG_ID)
			PROGINFO("RegisterMap::Start() : HostReg[%u] is bad(guestreg)\n", i);

		if (m_HostRegs[i].alloced)
			PROGINFO("RegisterMap::Start() : HostReg[%u] is bad(alloced)\n", i);

		if (m_HostRegs[i].locked)
			PROGINFO("RegisterMap::Start() : HostReg[%u] is bad(locked)\n", i);

		if (m_HostRegs[i].dirty)
			PROGINFO("RegisterMap::Start() : HostReg[%u] is bad(dirty)\n", i);
	}
#endif
	return true;
}

void RegisterMap::End()
{
	if (!m_Context)
		PROGINFO("RegisterMap::End() : Context is null\n");

	UnlockAll();
	FlushAll();

	m_Context = NULL;
}

void RegisterMap::SetImm(GuestRegId reg, u32 imm)
{
	if (reg >= GUESTREG_COUNT)
	{
		PROGINFO("RegisterMap::SetImm() : GuestRegId[%u] invalid\n", (u32)reg);

		return;
	}

	if (m_GuestRegs[reg].state == GuestReg::GRS_MAPPED)
	{
		const u32 hostreg = m_GuestRegs[reg].hostreg;

		if (hostreg == INVALID_REG_ID || m_HostRegs[hostreg].guestreg != reg)
			PROGINFO("RegisterMap::SetImm() : GuestRegId[%u] out of sync\n", (u32)reg);
		
		m_HostRegs[hostreg].guestreg = INVALID_REG_ID;
		m_HostRegs[hostreg].alloced = false;
		m_HostRegs[hostreg].locked = false;
		m_HostRegs[hostreg].dirty = false;
	}

	m_GuestRegs[reg].state = GuestReg::GRS_IMM;
	m_GuestRegs[reg].hostreg = INVALID_REG_ID;
	m_GuestRegs[reg].imm = imm;
}

bool RegisterMap::IsImm(GuestRegId reg) const
{
	if (reg >= GUESTREG_COUNT)
	{
		PROGINFO("RegisterMap::IsImm() : GuestRegId[%u] invalid\n", (u32)reg);

		return false;
	}

	return m_GuestRegs[reg].state == GuestReg::GRS_IMM;
}

u32 RegisterMap::GetImm(GuestRegId reg) const
{
	if (reg >= GUESTREG_COUNT)
	{
		PROGINFO("RegisterMap::GetImm() : GuestRegId[%u] invalid\n", (u32)reg);

		return 0;
	}

	if (m_GuestRegs[reg].state != GuestReg::GRS_IMM)
	{
		PROGINFO("RegisterMap::GetImm() : GuestRegId[%u] is non-imm register\n", (u32)reg);

		return 0;
	}

	return m_GuestRegs[reg].imm;
}

u32 RegisterMap::MapReg(GuestRegId reg, MapFlag mapflag)
{
	if (reg >= GUESTREG_COUNT)
	{
		PROGINFO("RegisterMap::MapReg() : GuestRegId[%u] invalid\n", (u32)reg);

		return INVALID_REG_ID;
	}

	if (m_GuestRegs[reg].state == GuestReg::GRS_MAPPED)
	{
		const u32 hostreg = m_GuestRegs[reg].hostreg;

		if (hostreg == INVALID_REG_ID || m_HostRegs[hostreg].guestreg != reg)
			PROGINFO("RegisterMap::MapReg() : GuestRegId[%u] out of sync\n", (u32)reg);

		if (mapflag & MAP_DIRTY)
			m_HostRegs[hostreg].dirty = true;

		m_HostRegs[hostreg].swapdata = GenSwapData();

		return hostreg;
	}

	const u32 hostreg = AllocHostReg();
	if (hostreg == INVALID_REG_ID)
	{
		PROGINFO("RegisterMap::MapReg() : out of host registers\n");

		return INVALID_REG_ID;
	}

	m_HostRegs[hostreg].guestreg = reg;
	m_HostRegs[hostreg].dirty = (mapflag & MAP_DIRTY);
	m_HostRegs[hostreg].swapdata = GenSwapData();
	if (!(mapflag & MAP_NOTINIT))
	{
		if (m_GuestRegs[reg].state == GuestReg::GRS_MEM)
		{
			LoadGuestRegImp(hostreg, m_GuestRegs[reg].adr);
		}
		else if (m_GuestRegs[reg].state == GuestReg::GRS_IMM)
		{
			LoadImm(hostreg, m_GuestRegs[reg].imm);

			m_HostRegs[hostreg].dirty = true;
		}
	}

	m_GuestRegs[reg].state = GuestReg::GRS_MAPPED;
	m_GuestRegs[reg].hostreg = hostreg;

	return hostreg;
}

u32 RegisterMap::MappedReg(GuestRegId reg)
{
	if (reg >= GUESTREG_COUNT)
	{
		PROGINFO("RegisterMap::MappedReg() : GuestRegId[%u] invalid\n", (u32)reg);

		return INVALID_REG_ID;
	}

	if (m_GuestRegs[reg].state != GuestReg::GRS_MAPPED)
	{
		PROGINFO("RegisterMap::MappedReg() : GuestRegId[%u] is not mapped\n", (u32)reg);

		return INVALID_REG_ID;
	}

	m_HostRegs[m_GuestRegs[reg].hostreg].swapdata = GenSwapData();

	return m_GuestRegs[reg].hostreg;
}

u32 RegisterMap::AllocHostReg()
{
	u32 freereg = INVALID_REG_ID;

	// find a free hostreg
	for (u32 i = 0; i < m_HostRegCount; i++)
	{
		if (!m_HostRegs[i].alloced)
		{
			freereg = i;

			break;
		}
	}

	if (freereg == INVALID_REG_ID)
	{
		// no free hostreg, try swap
	}

	m_HostRegs[freereg].guestreg = INVALID_REG_ID;
	m_HostRegs[freereg].swapdata = 0;
	m_HostRegs[freereg].alloced = true;
	m_HostRegs[freereg].locked = false;
	m_HostRegs[freereg].dirty = false;

	return freereg;
}

void RegisterMap::Lock(u32 reg)
{
	if (reg >= m_HostRegCount)
	{
		PROGINFO("RegisterMap::Lock() : HostReg[%u] invalid\n", (u32)reg);

		return;
	}

	if (!m_HostRegs[reg].alloced)
	{
		PROGINFO("RegisterMap::Lock() : HostReg[%u] is not alloced\n", (u32)reg);

		return;
	}

	m_HostRegs[reg].locked = true;
}

void RegisterMap::Unlock(u32 reg)
{
	if (reg >= m_HostRegCount)
	{
		PROGINFO("RegisterMap::Unlock() : HostReg[%u] invalid\n", (u32)reg);

		return;
	}

	if (!m_HostRegs[reg].alloced)
	{
		PROGINFO("RegisterMap::Unlock() : HostReg[%u] is not alloced\n", (u32)reg);

		return;
	}

	m_HostRegs[reg].locked = false;
}

void RegisterMap::UnlockAll()
{
	for (u32 i = 0; i < m_HostRegCount; i++)
	{
		if (m_HostRegs[i].alloced)
			Unlock(i);
	}
}

void RegisterMap::FlushGuestReg(GuestRegId reg)
{
	if (reg >= GUESTREG_COUNT)
	{
		PROGINFO("RegisterMap::FlushGuestReg() : GuestRegId[%u] invalid\n", (u32)reg);

		return;
	}

	if (m_GuestRegs[reg].state == GuestReg::GRS_MAPPED)
	{
		FlushHostReg(m_GuestRegs[reg].hostreg);
	}
	else if (m_GuestRegs[reg].state == GuestReg::GRS_IMM)
	{
		StoreImm(m_GuestRegs[reg].adr, m_GuestRegs[reg].imm);
	}

	m_GuestRegs[reg].state = GuestReg::GRS_MEM;
	m_GuestRegs[reg].hostreg = INVALID_REG_ID;
	m_GuestRegs[reg].imm = 0;
}

void RegisterMap::FlushHostReg(u32 reg)
{
	if (reg >= m_HostRegCount)
	{
		PROGINFO("RegisterMap::FreeHostReg() : HostReg[%u] invalid\n", (u32)reg);

		return;
	}

	if (!m_HostRegs[reg].alloced)
	{
		PROGINFO("RegisterMap::FreeHostReg() : HostReg[%u] is not alloced\n", (u32)reg);

		return;
	}

	if (m_HostRegs[reg].locked)
	{
		PROGINFO("RegisterMap::FreeHostReg() : HostReg[%u] is locked\n", (u32)reg);

		return;
	}

	if (m_HostRegs[reg].guestreg == INVALID_REG_ID)
	{
		//m_HostRegs[reg].guestreg = INVALID_REG_ID;
		m_HostRegs[reg].swapdata = 0;
		m_HostRegs[reg].alloced = false;
		m_HostRegs[reg].locked = false;
		m_HostRegs[reg].dirty = false;
	}
	else
	{
		const u32 guestreg = m_HostRegs[reg].guestreg;

		if (m_GuestRegs[guestreg].state != GuestReg::GRS_MAPPED || m_GuestRegs[guestreg].hostreg != reg)
			PROGINFO("RegisterMap::FlushHostReg() : HostReg[%u] out of sync\n", (u32)reg);

		if (m_HostRegs[reg].dirty)
			StoreGuestRegImp(reg, m_GuestRegs[guestreg].adr);

		m_HostRegs[reg].guestreg = INVALID_REG_ID;
		m_HostRegs[reg].swapdata = 0;
		m_HostRegs[reg].alloced = false;
		m_HostRegs[reg].locked = false;
		m_HostRegs[reg].dirty = false;

		m_GuestRegs[guestreg].state = GuestReg::GRS_MEM;
		m_GuestRegs[guestreg].hostreg = INVALID_REG_ID;
		m_GuestRegs[guestreg].imm = 0;
	}
}

void RegisterMap::FlushAll()
{
	for (u32 i = 0; i < GUESTREG_COUNT; i++)
	{
		FlushGuestReg((GuestRegId)i);
	}

	for (u32 i = 0; i < m_HostRegCount; i++)
	{
		if (m_HostRegs[i].alloced)
			FlushHostReg(i);
	}
}

u32 RegisterMap::GenSwapData()
{
	return m_SwapData++;
}

//CACHE_ALIGN u8 g_RecompileCounts[(1<<26)/16];

void JitLutInit()
{
#ifdef MAPPED_JIT_FUNCS
	JIT_MASK[ARMCPU_ARM9][2*2+0] = _MMU_MAIN_MEM_MASK;
	JIT_MASK[ARMCPU_ARM9][2*2+1] = _MMU_MAIN_MEM_MASK;

	for (int proc = 0; proc < JitLut::JIT_MEM_COUNT; proc++)
	{
		for (int i = 0; i < JitLut::JIT_MEM_LEN; i++)
		{
			g_JitLut.JIT_MEM[proc][i] = JIT_MEM[proc][i>>9] + (((i<<14) & JIT_MASK[proc][i>>9]) >> 1);
		}
	}
#endif
}

void JitLutDeInit()
{
}

void JitLutReset()
{
#ifdef MAPPED_JIT_FUNCS
	memset(g_JitLut.MAIN_MEM,  0, sizeof(g_JitLut.MAIN_MEM));
	memset(g_JitLut.SWIRAM,    0, sizeof(g_JitLut.SWIRAM));
	memset(g_JitLut.ARM9_ITCM, 0, sizeof(g_JitLut.ARM9_ITCM));
	memset(g_JitLut.ARM9_LCDC, 0, sizeof(g_JitLut.ARM9_LCDC));
	memset(g_JitLut.ARM9_BIOS, 0, sizeof(g_JitLut.ARM9_BIOS));
	memset(g_JitLut.ARM7_BIOS, 0, sizeof(g_JitLut.ARM7_BIOS));
	memset(g_JitLut.ARM7_ERAM, 0, sizeof(g_JitLut.ARM7_ERAM));
	memset(g_JitLut.ARM7_WIRAM,0, sizeof(g_JitLut.ARM7_WIRAM));
	memset(g_JitLut.ARM7_WRAM, 0, sizeof(g_JitLut.ARM7_WRAM));
#else
	memset(g_CompiledFuncs, 0, sizeof(g_CompiledFuncs));
#endif
	//memset(g_RecompileCounts,0, sizeof(g_RecompileCounts));
}

void FlushIcacheSection(u8 *begin, u8 *end)
{
#ifdef _MSC_VER
	FlushInstructionCache(GetCurrentProcess(), begin, end - begin);
#else
	__builtin___clear_cache(begin, end);
#endif
}

#endif //HAVE_JIT
