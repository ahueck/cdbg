; RUN: %opt -O1 -S %s | %FileCheck %s --check-prefix=IR
; RUN: %opt -O2 -S %s | %FileCheck %s --check-prefix=IR
; RUN: %opt -O1 -S %s | %llc -mcpu=gfx1150 -O2 -verify-machineinstrs | %FileCheck %s --check-prefix=ASM
; RUN: %opt -O2 -S %s | %llc -mcpu=gfx1150 -O2 -verify-machineinstrs | %FileCheck %s --check-prefix=ASM
; RUN: %opt -O1 -S %s | %llc -mcpu=gfx1150 -O2 -global-isel -global-isel-abort=1 -verify-machineinstrs | %FileCheck %s --check-prefix=ASM

; llvm.sideeffect preserves the IR trampoline but emits no instruction.
; Six sleeps keep the continuation above the early tail-duplication threshold.

; IR-LABEL: define amdgpu_kernel void @bypass_trampoline(
; IR-COUNT-1: call i1 @llvm.is.debugging.enabled()
; IR-NOT: call i1 @llvm.is.debugging.enabled()
; IR: }
; ASM-LABEL: bypass_trampoline:
; ASM-NOT: s_getreg_b32
; ASM-COUNT-1: s_cbranch_cdbgsys_or_user
; ASM-NOT: s_cbranch_cdbg
; ASM-NOT: s_getreg_b32
; ASM: .Lfunc_end

target triple = "amdgpu11.50-amd-amdhsa"

declare void @llvm.sideeffect()

declare noundef i1 @llvm.is.debugging.enabled()

declare void @llvm.amdgcn.s.sleep(i32 immarg)

define amdgpu_kernel void @bypass_trampoline() {
entry:
  %enabled = call i1 @llvm.is.debugging.enabled()
  br i1 %enabled, label %trampoline, label %continuation

continuation:
  call void @llvm.amdgcn.s.sleep(i32 1)
  call void @llvm.amdgcn.s.sleep(i32 1)
  call void @llvm.amdgcn.s.sleep(i32 1)
  call void @llvm.amdgcn.s.sleep(i32 1)
  call void @llvm.amdgcn.s.sleep(i32 1)
  call void @llvm.amdgcn.s.sleep(i32 1)
  ret void

trampoline:
  call void @llvm.sideeffect()
  br label %continuation
}
