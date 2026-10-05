import shlex

import lit.formats

config.name = "CDBGRepro"
config.test_format = lit.formats.ShTest(execute_external=False)
config.suffixes = [".ll", ".mir", ".c"]
config.test_source_root = config.suite_source_root
config.test_exec_root = config.suite_exec_root
config.excludes = ["build", ".git"]
if not config.enable_pseudo_tests:
    config.excludes.append("pseudo")
config.substitutions.extend([
    ("%clang", shlex.quote(config.clang)),
    ("%opt", shlex.quote(config.opt)),
    ("%llc", shlex.quote(config.llc)),
    ("%FileCheck", shlex.quote(config.filecheck)),
])
