# CDBG observation reproducers

Debugger-status observations must survive CFG changes, including repeated reads.
Tests assert preservation: lost observations report **FAIL**, without XFAIL.
Raw MIR exposes the bug; IR results depend on the supplied build's lowering.
`pseudo/` contains optional preservation controls.

Requires an LLVM build with AMDGPU, `llvm.is.debugging.enabled`, `opt`, `llc`,
`FileCheck`, and `llvm-lit`. Pseudo controls also require
`SI_DEBUGGING_ENABLED_BRANCH`.

```sh
cmake -S . -B build -DLLVM_BUILD_DIR=/path/to/llvm/build
cmake --build build --target check
```

Add `-DENABLE_PSEUDO_TESTS=ON` at configuration to include pseudo controls.

IR and corresponding MIR use the same filename stem. MIR controls in `pseudo/`
use the same filenames as `branchfold/`.

| Scenario / filename stem | Pass ignoring side effects |
|---|---|
| `branch-to-next` | `branch-folder`; `block-placement` via `updateTerminator` (MIR only) |
| `consecutive-debug-checks` | `branch-folder` |
| `wait-for-two-clear-samples` | `branch-folder` |
| `identical-exit-epilogues` | `branch-folder` (IR: direct `llc`) |
| `bypass-trampoline` | MIR: `tailduplication`; IR: `early-tailduplication` |
| `unused-branch-query` | IR-only preservation control |

`opt -O1` safely converts identical epilogues and unused branch queries to
standalone reads. IR and raw MIR observe SYS_OR_USER.

## Branch comparison

`P`: `test/amdgpu/pseudo-cdbg-relaxation`, pseudo controls enabled
(latest full suite: 17 PASS, 5 FAIL, including C tests).
`nP`: `test/branchfold-intrinsic-relaxation` at `a9208577ee67`,
pseudo controls disabled (1 PASS, 10 FAIL). This branch has no debugging-branch
pseudo.

`IR`: optimized IR checks. `IR CG`: codegen checks for IR inputs, including
direct `llc` runs. `C CG`: codegen checks for C-generated IR.
Shared `IR` and `raw MIR` columns apply to both branches.

| Test | IR | P IR CG | nP IR CG | raw MIR | P pseudo MIR | P C CG | nP C CG |
|---|---|---|---|---|---|---|---|
| `branch-to-next` | PASS | PASS | FAIL | FAIL | PASS | PASS | FAIL |
| `bypass-trampoline` | PASS | PASS | FAIL | FAIL | PASS | PASS | FAIL |
| `consecutive-debug-checks` | PASS | PASS | FAIL | FAIL | PASS | PASS | PASS |
| `identical-exit-epilogues` | PASS | PASS | FAIL | FAIL | PASS | PASS | PASS |
| `wait-for-two-clear-samples` | PASS | PASS | FAIL | FAIL | PASS | PASS | FAIL |
| `unused-branch-query` | PASS | PASS | PASS | — | — | PASS | PASS |

For `identical-exit-epilogues`, optimized pipelines pass; direct `llc` loses the observation.

### nP C vs. IR

| Test | nP C vs. IR |
|---|---|
| `branch-to-next` | Both FAIL: `branch-folder` deletes the only observation. |
| `bypass-trampoline` | Both FAIL: C loses the observation in `branch-folder`; IR loses it in `early-tailduplication`. |
| `consecutive-debug-checks` | C PASS, IR FAIL: different block order triggers deletion only in IR. Swapping the blocks reverses the results. |
| `identical-exit-epilogues` | C PASS, IR FAIL: only direct, unoptimized IR codegen fails. Optimized C and IR preserve a standalone read. |
| `wait-for-two-clear-samples` | Both FAIL: `branch-folder` deletes the second observation. |
| `unused-branch-query` | Both PASS: optimization removes the branch but preserves a standalone read. |
