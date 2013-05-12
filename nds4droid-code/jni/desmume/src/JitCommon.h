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

#ifndef JIT_COMMON
#define JIT_COMMON

#include "common.h"
#include <map>

#ifdef HAVE_JIT

#if defined(_WINDOWS) || defined(DESMUME_COCOA)
#define MAPPED_JIT_FUNCS
#elif defined(ANDROID)
#define MAPPED_JIT_FUNCS
#endif

#ifdef MAPPED_JIT_FUNCS
struct JitLut
{
	static const int MAIN_MEM_LEN = 16*1024*1024/2;
	static const int SWIRAM_LEN = 0x8000/2;
	static const int ARM9_ITCM_LEN = 0x8000/2;
	static const int ARM9_LCDC_LEN = 0xA4000/2;
	static const int ARM9_BIOS_LEN = 0x8000/2;
	static const int ARM7_BIOS_LEN = 0x4000/2;
	static const int ARM7_ERAM_LEN = 0x10000/2;
	static const int ARM7_WIRAM_LEN = 0x10000/2;
	static const int ARM7_WRAM_LEN = 0x40000/2;
	static const int JIT_MEM_COUNT = 2;
	static const int JIT_MEM_LEN = 0x4000;

	uintptr_t MAIN_MEM[MAIN_MEM_LEN];
	uintptr_t SWIRAM[SWIRAM_LEN];
	uintptr_t ARM9_ITCM[ARM9_ITCM_LEN];
	uintptr_t ARM9_LCDC[ARM9_LCDC_LEN];
	uintptr_t ARM9_BIOS[ARM9_BIOS_LEN];
	uintptr_t ARM7_BIOS[ARM7_BIOS_LEN];
	uintptr_t ARM7_ERAM[ARM7_ERAM_LEN];
	uintptr_t ARM7_WIRAM[ARM7_WIRAM_LEN];
	uintptr_t ARM7_WRAM[ARM7_WRAM_LEN];

	uintptr_t* JIT_MEM[JIT_MEM_COUNT][JIT_MEM_LEN];
};
extern CACHE_ALIGN JitLut g_JitLut;
#define JITLUT_HANDLE(adr, PROCNUM) g_JitLut.JIT_MEM[PROCNUM][((adr)&0x0FFFC000)>>14][((adr)&0x00003FFE)>>1]
#define JITLUT_HANDLE_PREMASKED(adr, PROCNUM, ofs) g_JitLut.JIT_MEM[PROCNUM][(adr)>>14][(((adr)&0x00003FFE)>>1)+ofs]
#define JITLUT_HANDLE_KNOWNBANK(adr, bank, mask, ofs) g_JitLut.bank[(((adr)&(mask))>>1)+ofs]
#define JITLUT_MAPPED(adr, PROCNUM) g_JitLut.JIT_MEM[PROCNUM][(adr)>>14]
#else
extern uintptr_t g_CompiledFuncs[];
#define JITLUT_HANDLE(adr, PROCNUM) g_CompiledFuncs[((adr) & 0x07FFFFFE) >> 1]
#define JITLUT_HANDLE_PREMASKED(adr, PROCNUM, ofs) JITLUT_HANDLE(adr, PROCNUM)
#define JITLUT_HANDLE_KNOWNBANK(adr, bank, mask, ofs) JITLUT_HANDLE(adr, PROCNUM)
#define JITLUT_MAPPED(adr, PROCNUM) true
#endif

struct JitBlock
{
	const u8 *checkedEntry;
	const u8 *normalEntry;

	u8 *exitPtrs[2];		 // to be able to rewrite the exit jum
	u32 exitAddress[2];	// 0xFFFFFFFF == unknown

	u32 originalAddress;
	u32 originalFirstOpcode; //to be able to restore
	u32 codeSize; 
	u32 originalSize;
	int runCount;	// for profiling.
	int blockNum;
	int flags;

	bool invalid;
	bool linkStatus[2];
	bool ContainsAddress(u32 em_address);

#ifdef _WIN32
	// we don't really need to save start and stop
	// TODO (mb2): ticStart and ticStop -> "local var" mean "in block" ... low priority ;)
	u64 ticStart;		// for profiling - time.
	u64 ticStop;		// for profiling - time.
	u64 ticCounter;	// for profiling - time.
#endif

#ifdef USE_VTUNE
	char blockName[32];
#endif
};

struct GuestReg
{
	enum GuestRegState
	{
		GRS_IMM,
		GRS_MAPPED,
		GRS_MEM,
	};

	GuestRegState state;
	u32 hostreg;
	u32 imm;
	u32 *adr;
};

struct HostReg
{
	u32 guestreg;
	u32 swapdata;
	bool alloced;
	bool locked;
	bool dirty;
};

class RegisterMap
{
public:
	enum GuestRegId
	{
		R0 = 0,
		R1,
		R2,
		R3,
		R4,
		R5,
		R6,
		R7,
		R8,
		R9,
		R10,
		R11,
		R12,
		R13,
		R14,
		R15,
		CPSR,

		GUESTREG_COUNT,
	};

	enum MapFlag
	{
		MAP_NORMAL = 0,
		MAP_DIRTY = 1,
		MAP_NOTINIT = 2,
	};

public:
	RegisterMap(struct armcpu_t *armcpu, u32 HostRegCount);
	virtual ~RegisterMap();

public:
	bool Start(void *context);
	void End();

	void SetImm(GuestRegId reg, u32 imm);
	bool IsImm(GuestRegId reg) const;
	u32 GetImm(GuestRegId reg) const;

	u32 MapReg(GuestRegId reg, MapFlag mapflag = MAP_NORMAL);
	u32 MappedReg(GuestRegId reg);
	u32 AllocHostReg();

	void Lock(u32 reg);
	void Unlock(u32 reg);
	void UnlockAll();

	void FlushGuestReg(GuestRegId reg);
	void FlushHostReg(u32 reg);
	void FlushAll();

protected:
	u32 GenSwapData();

	virtual void StoreGuestRegImp(u32 reg, u32 *adr) = 0;
	virtual void LoadGuestRegImp(u32 reg, u32 *adr) = 0;
	virtual void StoreImm(u32 *adr, u32 data) = 0;
	virtual void LoadImm(u32 reg, u32 data) = 0;

protected:
	GuestReg *m_GuestRegs;

	HostReg *m_HostRegs;
	u32 m_HostRegCount;

	u32 m_SwapData;

	void *m_Context;
};

void JitLutInit();

void JitLutDeInit();

void JitLutReset();

void FlushIcacheSection(u8 *begin, u8 *end);

//extern CACHE_ALIGN u8 g_RecompileCounts[(1<<26)/16];

//FORCEINLINE bool JitBlockModify(u32 adr)
//{
//	u32 mask_adr = (adr & 0x07FFFFFE) >> 4;
//
//	if (((g_RecompileCounts[mask_adr >> 1] >> 4*(mask_adr & 1)) & 0xF) > 8)
//		return false;
//
//	g_RecompileCounts[mask_adr >> 1] += 1 << 4*(mask_adr & 1);
//
//	return true;
//}

#endif //HAVE_JIT

#endif //JIT_COMMON
