; RUN: %opt -O1 -S %s | %FileCheck %s --check-prefix=IR
; RUN: %opt -O2 -S %s | %FileCheck %s --check-prefix=IR
; RUN: %opt -O1 -S %s | %llc -mcpu=gfx1150 -O2 -verify-machineinstrs | %FileCheck %s --check-prefix=ASM
; RUN: %opt -O2 -S %s | %llc -mcpu=gfx1150 -O2 -verify-machineinstrs | %FileCheck %s --check-prefix=ASM
; RUN: %opt -O1 -S %s | %llc -mcpu=gfx1150 -O2 -global-isel -global-isel-abort=1 -verify-machineinstrs | %FileCheck %s --check-prefix=ASM

; The second query runs only if the first is clear. Both reach the same handler.
; A terminating trap avoids return unification that would prevent CDBG fusion.

; IR-LABEL: define amdgpu_kernel void @consecutive_debug_checks(
; IR: %first = {{(tail )?}}call i1 @llvm.is.debugging.enabled()
; IR-NEXT: br i1 %first, label %debug, label %second_query
; IR: second_query:
; IR-NEXT: %second = {{(tail )?}}call i1 @llvm.is.debugging.enabled()
; IR-NEXT: br i1 %second, label %debug, label %exit
; IR-NOT: call i1 @llvm.is.debugging.enabled()
; IR: }
; ASM-LABEL: consecutive_debug_checks:
; ASM-NOT: s_getreg_b32
; ASM: s_cbranch_cdbgsys_or_user [[HANDLER:.LBB[0-9_]+]]
; ASM: s_cbranch_cdbgsys_or_user [[HANDLER]]
; ASM-NOT: s_cbranch_cdbg
; ASM-NOT: s_getreg_b32
; ASM: [[HANDLER]]:
; ASM-NEXT: s_trap 2
; ASM: .Lfunc_end

target triple = "amdgpu11.50-amd-amdhsa"

declare noundef i1 @llvm.is.debugging.enabled()

declare void @llvm.trap()

define amdgpu_kernel void @consecutive_debug_checks() {
entry:
  %first = call i1 @llvm.is.debugging.enabled()
  br i1 %first, label %debug, label %second_query

second_query:
  %second = call i1 @llvm.is.debugging.enabled()
  br i1 %second, label %debug, label %exit

exit:
  ret void

debug:
  call void @llvm.trap()
  unreachable
}
