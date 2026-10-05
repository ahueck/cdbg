; RUN: %opt -O1 -S %s | %FileCheck %s --check-prefix=IR
; RUN: %opt -O2 -S %s | %FileCheck %s --check-prefix=IR
; RUN: %opt -O1 -S %s | %llc -mcpu=gfx1150 -O2 -verify-machineinstrs | %FileCheck %s --check-prefix=ASM
; RUN: %opt -O2 -S %s | %llc -mcpu=gfx1150 -O2 -verify-machineinstrs | %FileCheck %s --check-prefix=ASM
; RUN: %opt -O1 -S %s | %llc -mcpu=gfx1150 -O2 -global-isel -global-isel-abort=1 -verify-machineinstrs | %FileCheck %s --check-prefix=ASM

; llvm.sideeffect keeps the debug arm through opt but emits no instruction.
; Both machine outcomes reach the next block; the observation must survive.

; IR-LABEL: define amdgpu_kernel void @branch_to_next(
; IR-COUNT-1: call i1 @llvm.is.debugging.enabled()
; IR-NOT: call i1 @llvm.is.debugging.enabled()
; IR: }
; ASM-LABEL: branch_to_next:
; ASM-NOT: s_getreg_b32
; ASM-COUNT-1: s_cbranch_cdbgsys_or_user
; ASM-NOT: s_cbranch_cdbg
; ASM-NOT: s_getreg_b32
; ASM: .Lfunc_end

target triple = "amdgpu11.50-amd-amdhsa"

declare void @llvm.sideeffect()

declare noundef i1 @llvm.is.debugging.enabled()

define amdgpu_kernel void @branch_to_next() {
entry:
  %enabled = call i1 @llvm.is.debugging.enabled()
  br i1 %enabled, label %debug, label %exit

debug:
  call void @llvm.sideeffect()
  br label %exit

exit:
  ret void
}
