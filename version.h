#pragma once

#define VER_MAJOR 0
#define VER_MINOR 0
#define VER_REVIS 1
#define VER_BUILD 12

#define _W(arg) L##arg
#define _STR(arg) _W(#arg)
#define STR(arg) _STR(arg)

#ifdef _WIN64
#define PLATFORM L"64-bit"
#define FN_PLATFORM L"64"
#else
#define PLATFORM L"32-bit"
#define FN_PLATFORM L""
#endif

#define PACKAGE_DESC L"tclwinhooks extension DLL "
#define PACKAGE_VERSION STR(VER_MAJOR) L"." STR(VER_MINOR) L"." STR(VER_REVIS) L"." STR(VER_BUILD) L" (" PLATFORM L")"
#define PACKAGE_NAME L"tclwinhooks extension"
#define PACKAGE_FILENAME L"tclwinhooks" FN_PLATFORM L".dll"
#define PACKAGE_OWNER L"Konstantin Kushnir"
#define PACKAGE_COPYRIGHT L"Copyright (c) 2019 Konstantin Kushnir"

