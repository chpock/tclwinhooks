# Intro
This Tcl extension provides access to winapi function [SetWindowsHookEx()](https://docs.microsoft.com/en-us/windows/win32/api/winuser/nf-winuser-setwindowshookexa). It allows to intercept events sent to various windows from OS.

Only a limited number of hooks are currently supported by this extension.

Hook | Thread | Thread revocable | Global |
------------- | ------------- | ------------ |
WH_CALLWNDPROC | :black_square_button: | :black_square_button: | :black_square_button:
WH_CALLWNDPROCRET | :black_square_button: | :black_square_button: | :black_square_button:
WH_CBT | :black_square_button: | :black_square_button: | :black_square_button:
WH_DEBUG | :black_square_button: | :black_square_button: | :black_square_button:
WH_FOREGROUNDIDLE | :black_square_button: | :black_square_button: | :black_square_button:
WH_GETMESSAGE | :black_square_button: | :black_square_button: | :black_square_button:
WH_JOURNALPLAYBACK | :no_entry: | :no_entry: | :black_square_button:
WH_JOURNALRECORD | :no_entry: | :no_entry: | :black_square_button:
WH_KEYBOARD | :white_check_mark: | :white_check_mark: | :black_square_button:
WH_KEYBOARD_LL | :no_entry: | :no_entry: | :black_square_button:
WH_MOUSE | :black_square_button: | :black_square_button: | :black_square_button:
WH_MOUSE_LL | :no_entry: | :no_entry: | :black_square_button:
WH_MSGFILTER | :black_square_button: | :black_square_button: | :black_square_button:
WH_SHELL | :black_square_button: | :black_square_button: | :black_square_button:
WH_SYSMSGFILTER | :no_entry: | :no_entry: | :black_square_button:

# Procedures
## setHook
This function is used to set hooks.
### Syntax
```tcl
::winhooks::setHook ?-revocable? ?-threadId THREADID? hookType script
```
This procedure sets the specified `hookType` using the callback script `script`. On a successful call, it returns a `hookId`, which can be used to release the hook by procedure `releaseHook`. On error it returns an error code according to [System Error Codes](https://docs.microsoft.com/en-us/windows/win32/debug/system-error-codes).

By default, a hook is set for its process. If the hook should be set for another process (or globaly), then parameter `-threadId` must be used.

Optional parameters:
* `-revocable` - this option allows to revoke the event from callback script. If this option is specified, then the callback script must return boolean value. If the return value from the callback script is **false**, the event will be canceled and will not be processed by the target window.
* `-threadId THREADID` - this option sets the scope of the hook. If it is not specified, then the hook will be set for the current process. If this option is set to `0` then a global hook will be set. If a thread id is specified for this option, events from the specified thread will be hooked.
## releaseHook
This function is used to release hooks.
### Syntax
```tcl
::winhooks::releaseHook hookId
```
The `hookId` parameter is the value that was previosly returned by procedure `setHook`.
# Example
```tcl
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
```
# Links
## General
* [About Messages and Message Queues](https://docs.microsoft.com/en-us/windows/win32/winmsg/about-messages-and-message-queues)
* [Hooks Overview](https://docs.microsoft.com/en-us/windows/win32/winmsg/about-hooks)
* [SetWindowsHookExA function](https://docs.microsoft.com/en-us/windows/win32/api/winuser/nf-winuser-setwindowshookexa)
* [System Error Codes](https://docs.microsoft.com/en-us/windows/win32/debug/system-error-codes)
## Other
* [How to send events to other windows on hooks](https://www.codeproject.com/Articles/1037/Hooks-and-DLLs)
* [Managing Low-Level Keyboard Hooks with the Windows API for VB .NET](https://www.codeguru.com/vb/gen/vb_system/keyboard/article.php/c4831/Managing-LowLevel-Keyboard-Hooks-with-the-Windows-API-for-VB-NET.htm)
* [Hooking the Keyboard](https://www.codeguru.com/cpp/w-p/system/keyboard/article.php/c5699/Hooking-the-Keyboard.htm)
