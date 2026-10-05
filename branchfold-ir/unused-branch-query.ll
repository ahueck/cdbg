; RUN: %opt -O1 -S %s | %FileCheck %s --check-prefix=IR
; RUN: %opt -O2 -S %s | %FileCheck %s --check-prefix=IR
; RUN: %opt -O1 -S %s | %llc -mcpu=gfx1150 -O2 -verify-machineinstrs | %FileCheck %s --check-prefix=ASM
; RUN: %opt -O2 -S %s | %llc -mcpu=gfx1150 -O2 -verify-machineinstrs | %FileCheck %s --check-prefix=ASM
; RUN: %opt -O1 -S %s | %llc -mcpu=gfx1150 -O2 -global-isel -global-isel-abort=1 -verify-machineinstrs | %FileCheck %s --check-prefix=ASM

; opt removes the branch but must retain the unused observation as a status read.

; IR-LABEL: define amdgpu_kernel void @unused_branch_query(
; IR-COUNT-1: call i1 @llvm.is.debugging.enabled()
; IR-NOT: call i1 @llvm.is.debugging.enabled()
; IR: }
; ASM-LABEL: unused_branch_query:
; ASM-NOT: s_cbranch_cdbg
; ASM-COUNT-1: s_getreg_b32
; ASM-NOT: s_getreg_b32
; ASM-NOT: s_cbranch_cdbg
; ASM: s_endpgm

target triple = "amdgpu11.50-amd-amdhsa"

declare noundef i1 @llvm.is.debugging.enabled()

define amdgpu_kernel void @unused_branch_query() {
entry:
  %enabled = call i1 @llvm.is.debugging.enabled()
  br i1 %enabled, label %exit, label %exit

exit:
  ret void
}
