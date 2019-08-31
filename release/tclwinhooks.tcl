
namespace eval ::winhooks {

    variable hooks
    array set hooks [list]

    # from https://docs.microsoft.com/en-us/windows/win32/inputdev/virtual-key-codes
    # turn off autoindent
    #   foreach { - vk code } [regexp -all -inline {(VK_\w+)\n(0x..)} $data] {
    #       puts "        $code $vk"
    #   }
    variable vk_codes
    array set vk_codes {
        0x01 VK_LBUTTON
        0x02 VK_RBUTTON
        0x03 VK_CANCEL
        0x04 VK_MBUTTON
        0x05 VK_XBUTTON1
        0x06 VK_XBUTTON2
        0x08 VK_BACK
        0x09 VK_TAB
        0x0C VK_CLEAR
        0x0D VK_RETURN
        0x10 VK_SHIFT
        0x11 VK_CONTROL
        0x12 VK_MENU
        0x13 VK_PAUSE
        0x14 VK_CAPITAL
        0x15 VK_KANA
        0x15 VK_HANGUEL
        0x15 VK_HANGUL
        0x17 VK_JUNJA
        0x18 VK_FINAL
        0x19 VK_HANJA
        0x19 VK_KANJI
        0x1B VK_ESCAPE
        0x1C VK_CONVERT
        0x1D VK_NONCONVERT
        0x1E VK_ACCEPT
        0x1F VK_MODECHANGE
        0x20 VK_SPACE
        0x21 VK_PRIOR
        0x22 VK_NEXT
        0x23 VK_END
        0x24 VK_HOME
        0x25 VK_LEFT
        0x26 VK_UP
        0x27 VK_RIGHT
        0x28 VK_DOWN
        0x29 VK_SELECT
        0x2A VK_PRINT
        0x2B VK_EXECUTE
        0x2C VK_SNAPSHOT
        0x2D VK_INSERT
        0x2E VK_DELETE
        0x2F VK_HELP
        0x5B VK_LWIN
        0x5C VK_RWIN
        0x5D VK_APPS
        0x5F VK_SLEEP
        0x60 VK_NUMPAD0
        0x61 VK_NUMPAD1
        0x62 VK_NUMPAD2
        0x63 VK_NUMPAD3
        0x64 VK_NUMPAD4
        0x65 VK_NUMPAD5
        0x66 VK_NUMPAD6
        0x67 VK_NUMPAD7
        0x68 VK_NUMPAD8
        0x69 VK_NUMPAD9
        0x6A VK_MULTIPLY
        0x6B VK_ADD
        0x6C VK_SEPARATOR
        0x6D VK_SUBTRACT
        0x6E VK_DECIMAL
        0x6F VK_DIVIDE
        0x70 VK_F1
        0x71 VK_F2
        0x72 VK_F3
        0x73 VK_F4
        0x74 VK_F5
        0x75 VK_F6
        0x76 VK_F7
        0x77 VK_F8
        0x78 VK_F9
        0x79 VK_F10
        0x7A VK_F11
        0x7B VK_F12
        0x7C VK_F13
        0x7D VK_F14
        0x7E VK_F15
        0x7F VK_F16
        0x80 VK_F17
        0x81 VK_F18
        0x82 VK_F19
        0x83 VK_F20
        0x84 VK_F21
        0x85 VK_F22
        0x86 VK_F23
        0x87 VK_F24
        0x90 VK_NUMLOCK
        0x91 VK_SCROLL
        0xA0 VK_LSHIFT
        0xA1 VK_RSHIFT
        0xA2 VK_LCONTROL
        0xA3 VK_RCONTROL
        0xA4 VK_LMENU
        0xA5 VK_RMENU
        0xA6 VK_BROWSER_BACK
        0xA7 VK_BROWSER_FORWARD
        0xA8 VK_BROWSER_REFRESH
        0xA9 VK_BROWSER_STOP
        0xAA VK_BROWSER_SEARCH
        0xAB VK_BROWSER_FAVORITES
        0xAC VK_BROWSER_HOME
        0xAD VK_VOLUME_MUTE
        0xAE VK_VOLUME_DOWN
        0xAF VK_VOLUME_UP
        0xB0 VK_MEDIA_NEXT_TRACK
        0xB1 VK_MEDIA_PREV_TRACK
        0xB2 VK_MEDIA_STOP
        0xB3 VK_MEDIA_PLAY_PAUSE
        0xB4 VK_LAUNCH_MAIL
        0xB5 VK_LAUNCH_MEDIA_SELECT
        0xB6 VK_LAUNCH_APP1
        0xB7 VK_LAUNCH_APP2
        0xBA VK_OEM_1
        0xBB VK_OEM_PLUS
        0xBC VK_OEM_COMMA
        0xBD VK_OEM_MINUS
        0xBE VK_OEM_PERIOD
        0xBF VK_OEM_2
        0xC0 VK_OEM_3
        0xDB VK_OEM_4
        0xDC VK_OEM_5
        0xDD VK_OEM_6
        0xDE VK_OEM_7
        0xDF VK_OEM_8
        0xE2 VK_OEM_102
        0xE5 VK_PROCESSKEY
        0xE7 VK_PACKET
        0xF6 VK_ATTN
        0xF7 VK_CRSEL
        0xF8 VK_EXSEL
        0xF9 VK_EREOF
        0xFA VK_PLAY
        0xFB VK_ZOOM
        0xFC VK_NONAME
        0xFD VK_PA1
        0xFE VK_OEM_CLEAR
    }

}

proc ::winhooks::_callback { hookNum idHook wParam lParam } {

    variable hooks
    variable vk_codes

    if { ![info exists hooks($hookNum)] } {
        return true
    }

    switch -exact -- $idHook {
        2 {; #WH_KEYBOARD
            set hexCode [format "0x%02x" $wParam]
            if { [info exists vk_codes($hexCode)] } {
                dict set lParam vkCode $vk_codes($hexCode)
            } else {
                dict set lParam vkCode $wParam
            }
        }
    }

    uplevel #0 [list {*}[dict get $hooks($hookNum) script] $hookNum $wParam $lParam]

}

proc ::winhooks::setHook { args } {

    variable hooks

    set revocable 0

    for { set i 0 } { $i < [llength $args] } { incr i } {
        switch -exact -- [lindex $args $i] {
            "--" {
                break
            }
            "-revocable" {
                set revocable 1
            }
            "-threadId" {
                incr i
                if { $i == [llength $args] } {
                    return -code error "setHook: no arg for -threadId"
                }
                set threadId [lindex $args $i]
            }
            default {
                incr i -1
                break
            }
        }
    }

    if { [incr i] != ([llength $args] - 2) } {
        return -code error "wrong # args: should be \"setHook ?-revocable? ?-threadId <threadId>? hookType script"
    }

    set hookType [lindex $args $i]
    set script   [lindex $args [incr i]]

    switch -exact -- $hookType {
        "WH_KEYBOARD" {
            set hookTypeId 2
        }
        default {
            return -code error "setHook: unsupported hook type: '$hookType'"
        }
    }

    set cmd [list SetHook $hookTypeId $revocable]

    if { [info exists threadId] } {
        lappend cmd $threadId
    }

    if { [catch $cmd hookNum] } {
        return -code error $hookNum
    }

    set hooks($hookNum) [dict create \
        hookType $hookType \
        script $script \
        revocable $revocable \
    ]

    if { [info exists threadId] } {
        dict set hooks($hookNum) threadId $threadId
    }

    return $hookNum

}

proc ::winhooks::releaseHook { hookNum } {

    variable hooks

    if { ![info exists hooks($hookNum)] } {
        return -code error "releaseHook: wrong # hook: '$hookNum'"
    }

    unset hooks($hookNum)

    if { [catch [list ReleaseHook $hookNum] errmsg] } {
        return -core error $errmsg
    }

    return $hookNum

}
