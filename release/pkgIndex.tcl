package ifneeded tclwinhooks 0.0.1 \
    "[list load   [file join $dir tclwinhooks[expr { $::tcl_platform(pointerSize) == 8?"64":"" }][info sharedlibextension]] tclwinhooks];\
     [list source [file join $dir tclwinhooks.tcl]]"
