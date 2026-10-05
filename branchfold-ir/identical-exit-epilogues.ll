; RUN: %opt -O1 -S %s | %FileCheck %s --check-prefix=IR
; RUN: %opt -O2 -S %s | %FileCheck %s --check-prefix=IR
; RUN: %opt -O1 -S %s | %llc -mcpu=gfx1150 -O2 -verify-machineinstrs | %FileCheck %s --check-prefix=ASM
; RUN: %opt -O2 -S %s | %llc -mcpu=gfx1150 -O2 -verify-machineinstrs | %FileCheck %s --check-prefix=ASM
; RUN: %opt -O1 -S %s | %llc -mcpu=gfx1150 -O2 -global-isel -global-isel-abort=1 -verify-machineinstrs | %FileCheck %s --check-prefix=ASM
; RUN: %llc -mcpu=gfx1150 -O2 -verify-machineinstrs %s -o - | %FileCheck %s --check-prefix=DIRECT
; RUN: %llc -mcpu=gfx1150 -O2 -global-isel -global-isel-abort=1 -verify-machineinstrs %s -o - | %FileCheck %s --check-prefix=DIRECT

; Direct llc merges identical machine epilogues and must retain the query.
; opt merges the IR exits first, leaving a standalone status read.

; IR-LABEL: define amdgpu_kernel void @identical_exit_epilogues(
; IR-COUNT-1: call i1 @llvm.is.debugging.enabled()
; IR-NOT: call i1 @llvm.is.debugging.enabled()
; IR: }
; ASM-LABEL: identical_exit_epilogues:
; ASM-NOT: s_cbranch_cdbg
; ASM-COUNT-1: s_getreg_b32
; ASM-NOT: s_getreg_b32
; ASM-NOT: s_cbranch_cdbg
; ASM: s_endpgm
; DIRECT-LABEL: identical_exit_epilogues:
; DIRECT-NOT: s_getreg_b32
; DIRECT: s_cbranch_cdbgsys_or_user [[EXIT:.LBB[0-9_]+]]
; DIRECT-NOT: s_cbranch_cdbg
; DIRECT: [[EXIT]]:
; DIRECT-NEXT: s_sleep 1
; DIRECT-NEXT: s_endpgm

target triple = "amdgpu11.50-amd-amdhsa"

declare noundef i1 @llvm.is.debugging.enabled()

declare void @llvm.amdgcn.s.sleep(i32 immarg)

define amdgpu_kernel void @identical_exit_epilogues() {
entry:
  %enabled = call i1 @llvm.is.debugging.enabled()
  br i1 %enabled, label %debug_exit, label %normal_exit

normal_exit:
  call void @llvm.amdgcn.s.sleep(i32 1)
  ret void

debug_exit:
  call void @llvm.amdgcn.s.sleep(i32 1)
  ret void
}
