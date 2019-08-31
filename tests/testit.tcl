lappend auto_path ../release twapi
package require tclwinhooks
package require twapi

# Set keyboard hook for the our GUI window
::winhooks::setHook WH_KEYBOARD [list apply [list { hookNum wParam lParam } {

    puts "Self key hook: $hookNum -> $wParam -> $lParam"

}]]

# Start 2 notepad processes
lassign [::twapi::create_process c:/Windows/notepad.exe] pid1 thread1
puts "PID1: $pid1 THREAD1: $thread1"
lassign [::twapi::create_process c:/Windows/notepad.exe] pid2 thread2
puts "PID1: $pid2 THREAD1: $thread2"

# Wait until notepad windows created
while {
    [twapi::get_toplevel_windows -pids $pid1] eq "" &&
    [twapi::get_toplevel_windows -pids $pid2] eq ""
} {
    puts "Waiting for the notepad windows..."
    after 10
}

# Set revocable keyboard hook for the first notepad windows
::winhooks::setHook -revocable -threadId $thread1 WH_KEYBOARD [list apply [list { hookNum wParam lParam } {

    # block F1
    if { [dict get $lParam vkCode] eq "VK_F1" } {
        puts "NOTEPAD #1 key blocked: [dict get $lParam vkCode]"
        return 1
    }

    # block "a" key
    if { [dict get $lParam vkCode] eq "65" } {
        puts "NOTEPAD #1 key blocked: [dict get $lParam vkCode]"
        return 1
    }

    puts "NOTEPAD #1 key hook: $hookNum -> $wParam -> $lParam"
    return 0

}]]

# Set keyboard hook for the first notepad windows
::winhooks::setHook -threadId $thread2 WH_KEYBOARD [list apply [list { hookNum wParam lParam } {

    puts "NOTEPAD #2 key hook: $hookNum -> $wParam -> $lParam"

}]]
