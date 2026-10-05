// RUN: %clang -target amdgpu11.50-amd-amdhsa -mcpu=gfx1150 -nogpulib -O1 -S -emit-llvm %s -o %t.O1.clang.ll
// RUN: %opt -O1 -S %t.O1.clang.ll -o %t.O1.ll
// RUN: %FileCheck %s --check-prefix=IR < %t.O1.ll
// RUN: %clang -target amdgpu11.50-amd-amdhsa -mcpu=gfx1150 -nogpulib -O2 -S -emit-llvm %s -o %t.O2.clang.ll
// RUN: %opt -O2 -S %t.O2.clang.ll -o %t.O2.ll
// RUN: %FileCheck %s --check-prefix=IR < %t.O2.ll
// RUN: %llc -mcpu=gfx1150 -O2 -verify-machineinstrs %t.O1.ll -o %t.O1.dag.s
// RUN: %llc -mcpu=gfx1150 -O2 -verify-machineinstrs -global-isel -global-isel-abort=1 %t.O1.ll -o %t.O1.gisel.s
// RUN: %llc -mcpu=gfx1150 -O2 -verify-machineinstrs %t.O2.ll -o %t.O2.dag.s
// RUN: %llc -mcpu=gfx1150 -O2 -verify-machineinstrs -global-isel -global-isel-abort=1 %t.O2.ll -o %t.O2.gisel.s
// RUN: %FileCheck %s --check-prefix=ASM < %t.O1.dag.s
// RUN: %FileCheck %s --check-prefix=ASM < %t.O1.gisel.s
// RUN: %FileCheck %s --check-prefix=ASM < %t.O2.dag.s
// RUN: %FileCheck %s --check-prefix=ASM < %t.O2.gisel.s

// Both machine outcomes reach the next block; retain the observation.

// IR-LABEL: define {{.*}}amdgpu_kernel void @branch_to_next(
// IR-COUNT-1: call {{.*}}i1 @llvm.is.debugging.enabled()
// IR-NOT: call {{.*}}i1 @llvm.is.debugging.enabled()
// IR: }
// ASM-LABEL: branch_to_next:
// ASM-NOT: s_getreg_b32
// ASM-COUNT-1: s_cbranch_cdbgsys_or_user
// ASM-NOT: s_cbranch_cdbg
// ASM-NOT: s_getreg_b32
// ASM: .Lfunc_end

extern _Bool debugging_enabled(void) __asm__("llvm.is.debugging.enabled");
extern void sideeffect(void) __asm__("llvm.sideeffect");

__attribute__((amdgpu_kernel)) void branch_to_next(void) {
  if (debugging_enabled())
    sideeffect();
}
