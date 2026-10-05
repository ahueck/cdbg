; RUN: %opt -O1 -S %s | %FileCheck %s --check-prefix=IR
; RUN: %opt -O2 -S %s | %FileCheck %s --check-prefix=IR
; RUN: %opt -O1 -S %s | %llc -mcpu=gfx1150 -O2 -verify-machineinstrs | %FileCheck %s --check-prefix=ASM
; RUN: %opt -O2 -S %s | %llc -mcpu=gfx1150 -O2 -verify-machineinstrs | %FileCheck %s --check-prefix=ASM
; RUN: %opt -O1 -S %s | %llc -mcpu=gfx1150 -O2 -global-isel -global-isel-abort=1 -verify-machineinstrs | %FileCheck %s --check-prefix=ASM

; Exit requires two consecutive clear samples. Either set sample restarts the loop.

; IR-LABEL: define amdgpu_kernel void @wait_for_two_clear_samples(
; IR: loop:
; IR-NEXT: {{(tail )?}}call void @llvm.amdgcn.s.sleep(i32 1)
; IR-NEXT: %first = {{(tail )?}}call i1 @llvm.is.debugging.enabled()
; IR-NEXT: br i1 %first, label %loop.backedge, label %second_query
; IR: second_query:
; IR-NEXT: %second = {{(tail )?}}call i1 @llvm.is.debugging.enabled()
; IR-NEXT: br i1 %second, label %loop.backedge, label %exit
; IR-NOT: call i1 @llvm.is.debugging.enabled()
; IR: }
; ASM-LABEL: wait_for_two_clear_samples:
; ASM-NOT: s_getreg_b32
; ASM: [[LOOP:.LBB[0-9_]+]]:
; ASM: s_sleep 1
; ASM: s_cbranch_cdbgsys_or_user [[LOOP]]
; ASM: s_cbranch_cdbgsys_or_user [[LOOP]]
; ASM-NOT: s_cbranch_cdbg
; ASM-NOT: s_getreg_b32
; ASM: .Lfunc_end

target triple = "amdgpu11.50-amd-amdhsa"

declare noundef i1 @llvm.is.debugging.enabled()

declare void @llvm.amdgcn.s.sleep(i32 immarg)

define amdgpu_kernel void @wait_for_two_clear_samples() {
entry:
  br label %loop

loop:
  call void @llvm.amdgcn.s.sleep(i32 1)
  %first = call i1 @llvm.is.debugging.enabled()
  br i1 %first, label %loop, label %second_query

second_query:
  %second = call i1 @llvm.is.debugging.enabled()
  br i1 %second, label %loop, label %exit

exit:
  ret void
}
