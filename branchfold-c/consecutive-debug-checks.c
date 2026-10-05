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

// The second observation executes only when the first is clear.

// IR-LABEL: define {{.*}}amdgpu_kernel void @consecutive_debug_checks(
// IR: [[FIRST:%[a-zA-Z0-9._]+]] = {{.*}}call {{.*}}i1 @llvm.is.debugging.enabled()
// IR-NEXT: br i1 [[FIRST]], label %[[SET:[a-zA-Z0-9._]+]], label %[[SECOND_BLOCK:[a-zA-Z0-9._]+]]
// IR: [[SECOND_BLOCK]]:
// IR-NEXT: [[SECOND:%[a-zA-Z0-9._]+]] = {{.*}}call {{.*}}i1 @llvm.is.debugging.enabled()
// IR-NEXT: br i1 [[SECOND]], label %[[SET]], label %{{[a-zA-Z0-9._]+}}
// IR-NOT: call {{.*}}i1 @llvm.is.debugging.enabled()
// IR: }
// ASM-LABEL: consecutive_debug_checks:
// ASM-NOT: s_getreg_b32
// ASM: s_cbranch_cdbgsys_or_user [[HANDLER:.LBB[0-9_]+]]
// ASM: s_cbranch_cdbgsys_or_user [[HANDLER]]
// ASM-NOT: s_cbranch_cdbg
// ASM-NOT: s_getreg_b32
// ASM: [[HANDLER]]:
// ASM-NEXT: s_trap 2
// ASM: .Lfunc_end

extern _Bool debugging_enabled(void) __asm__("llvm.is.debugging.enabled");

__attribute__((amdgpu_kernel)) void consecutive_debug_checks(void) {
  if (debugging_enabled() || debugging_enabled())
    __builtin_trap();
}
