// TODO:
// тестить возможность revoke ивентов
// на KEYBOARD event это вроде как не работает
// возможно заработает на соответствующих GETMESSAGE - https://stackoverflow.com/questions/42756284/blocking-windows-mouse-click-using-setwindowshookex

#include <Windows.h>
#include <stdbool.h>
#include <tcl.h>
#include "tclwinhooks.h"

#define MAX_HOOKS 32

HINSTANCE hInstance = NULL;

typedef LRESULT CALLBACK (*HookCallbackRaw) (int nCode, WPARAM wParam, LPARAM lParam);

struct HookCallbackItem {
    HookCallbackRaw lpfn;
    HHOOK           hHook;
    int             idHook;
    DWORD           dwThreadId;
    int             bRevocable;
    Tcl_Interp*     interp;
} HookCallbackItem;

bool HookCallback(unsigned int idHookNum, WPARAM wParam, LPARAM lParam);

#define HOOKITEM_DECLARE(N) LRESULT CALLBACK Hook##N(int nCode, WPARAM wParam, LPARAM lParam)

#define HOOKITEM_REC(N) {Hook##N, NULL, 0, 0, 0, NULL}

#define HOOKITEM_FUNC(N) \
    LRESULT CALLBACK Hook##N(int nCode, WPARAM wParam, LPARAM lParam) { \
        if (nCode >= 0 && HookCallback(N, wParam, lParam)) return 1; \
        return CallNextHookEx(hookCallbackArray[N].hHook, nCode, wParam, lParam); \
    }

HOOKITEM_DECLARE(0); HOOKITEM_DECLARE(1); HOOKITEM_DECLARE(2); HOOKITEM_DECLARE(3); HOOKITEM_DECLARE(4);
HOOKITEM_DECLARE(5); HOOKITEM_DECLARE(6); HOOKITEM_DECLARE(7); HOOKITEM_DECLARE(8); HOOKITEM_DECLARE(9);
HOOKITEM_DECLARE(10); HOOKITEM_DECLARE(11); HOOKITEM_DECLARE(12); HOOKITEM_DECLARE(13); HOOKITEM_DECLARE(14);
HOOKITEM_DECLARE(15); HOOKITEM_DECLARE(16); HOOKITEM_DECLARE(17); HOOKITEM_DECLARE(18); HOOKITEM_DECLARE(19);
HOOKITEM_DECLARE(20); HOOKITEM_DECLARE(21); HOOKITEM_DECLARE(22); HOOKITEM_DECLARE(23); HOOKITEM_DECLARE(24);
HOOKITEM_DECLARE(25); HOOKITEM_DECLARE(26); HOOKITEM_DECLARE(27); HOOKITEM_DECLARE(28); HOOKITEM_DECLARE(29);
HOOKITEM_DECLARE(30); HOOKITEM_DECLARE(31);

struct HookCallbackItem hookCallbackArray[MAX_HOOKS] = {
    HOOKITEM_REC(0), HOOKITEM_REC(1), HOOKITEM_REC(2), HOOKITEM_REC(3), HOOKITEM_REC(4),
    HOOKITEM_REC(5), HOOKITEM_REC(6), HOOKITEM_REC(7), HOOKITEM_REC(8), HOOKITEM_REC(9),
    HOOKITEM_REC(10), HOOKITEM_REC(11), HOOKITEM_REC(12), HOOKITEM_REC(13), HOOKITEM_REC(14),
    HOOKITEM_REC(15), HOOKITEM_REC(16), HOOKITEM_REC(17), HOOKITEM_REC(18), HOOKITEM_REC(19),
    HOOKITEM_REC(20), HOOKITEM_REC(21), HOOKITEM_REC(22), HOOKITEM_REC(23), HOOKITEM_REC(24),
    HOOKITEM_REC(25), HOOKITEM_REC(26), HOOKITEM_REC(27), HOOKITEM_REC(28), HOOKITEM_REC(29),
    HOOKITEM_REC(30), HOOKITEM_REC(31)
};

HOOKITEM_FUNC(0) HOOKITEM_FUNC(1) HOOKITEM_FUNC(2) HOOKITEM_FUNC(3) HOOKITEM_FUNC(4)
HOOKITEM_FUNC(5) HOOKITEM_FUNC(6) HOOKITEM_FUNC(7) HOOKITEM_FUNC(8) HOOKITEM_FUNC(9)
HOOKITEM_FUNC(10) HOOKITEM_FUNC(11) HOOKITEM_FUNC(12) HOOKITEM_FUNC(13) HOOKITEM_FUNC(14)
HOOKITEM_FUNC(15) HOOKITEM_FUNC(16) HOOKITEM_FUNC(17) HOOKITEM_FUNC(18) HOOKITEM_FUNC(19)
HOOKITEM_FUNC(20) HOOKITEM_FUNC(21) HOOKITEM_FUNC(22) HOOKITEM_FUNC(23) HOOKITEM_FUNC(24)
HOOKITEM_FUNC(25) HOOKITEM_FUNC(26) HOOKITEM_FUNC(27) HOOKITEM_FUNC(28) HOOKITEM_FUNC(29)
HOOKITEM_FUNC(30) HOOKITEM_FUNC(31)

bool HookCallback(unsigned int idHookNum, WPARAM wParam, LPARAM lParam) {

    int ret;

    if (hookCallbackArray[idHookNum].interp == NULL || Tcl_InterpDeleted(hookCallbackArray[idHookNum].interp)) {
        return false;
    }

    Tcl_Obj *objs[5];
    objs[0] = Tcl_NewStringObj("::winhooks::_callback", -1);
    objs[1] = Tcl_NewIntObj(idHookNum);
    objs[2] = Tcl_NewIntObj(hookCallbackArray[idHookNum].idHook);
    objs[3] = Tcl_NewLongObj(wParam);
    objs[4] = Tcl_NewDictObj();

# define ADD_RESULT_INT(NAME, VALUE) \
    Tcl_DictObjPut(hookCallbackArray[idHookNum].interp, \
        objs[4], Tcl_NewStringObj(NAME, -1), \
        Tcl_NewIntObj(VALUE))

# define ADD_RESULT_BOOL(NAME, VALUE) \
    Tcl_DictObjPut(hookCallbackArray[idHookNum].interp, \
        objs[4], Tcl_NewStringObj(NAME, -1), \
        Tcl_NewBooleanObj(VALUE))

    switch (hookCallbackArray[idHookNum].idHook) {

       case WH_KEYBOARD: {
                ADD_RESULT_INT("repeatCount", lParam & 0xFFFF);
                ADD_RESULT_INT("scanCode", (lParam & 0xFF0000) >> 16);
                ADD_RESULT_BOOL("extendedKey", (lParam & 0x1000000) == 0x1000000);
                ADD_RESULT_BOOL("contextCode", (lParam & 0x20000000) == 0x20000000);
                ADD_RESULT_BOOL("previousState", (lParam & 0x40000000) == 0x40000000);
                ADD_RESULT_BOOL("transitionState", (lParam & 0x80000000) == lParam & 0x80000000);
            }
            break;

    }

    ret = Tcl_EvalObjv(hookCallbackArray[idHookNum].interp, 5, objs,
        TCL_EVAL_DIRECT|TCL_EVAL_GLOBAL);

    if (hookCallbackArray[idHookNum].bRevocable && ret == TCL_OK) {

        Tcl_Obj *objResult;
        int iResult;

        objResult = Tcl_GetObjResult(hookCallbackArray[idHookNum].interp);

        if (Tcl_GetBooleanFromObj(hookCallbackArray[idHookNum].interp, objResult, &iResult) == TCL_OK && iResult)
            return true;

    }

    return false;

}

static int SetHook_Cmd(ClientData clientData, Tcl_Interp *interp, int objc, Tcl_Obj *const objv[]) {

    HHOOK hHook;
    DWORD dwThreadId;
    long  lThreadId;
    int   idHook;
    int   bRevocable;
    unsigned int idHookNum = 0;

    if (objc < 3) {
        Tcl_WrongNumArgs(interp, 1, objv, "idHook bRevocable ?dwThreadId?");
        return TCL_ERROR;
    }

    if (Tcl_GetIntFromObj(interp, objv[1], &idHook) != TCL_OK) {
        Tcl_AppendResult(interp, "SetHook error: wrong idHook", NULL);
        return TCL_ERROR;
    }

    if (Tcl_GetBooleanFromObj(interp, objv[2], &bRevocable) != TCL_OK) {
        Tcl_AppendResult(interp, "SetHook error: wrong bRevocable", NULL);
        return TCL_ERROR;
    }

    if (objc < 4) {
        dwThreadId = GetCurrentThreadId();
    } else {
        if (Tcl_GetLongFromObj(interp, objv[3], &lThreadId) != TCL_OK) {
            Tcl_AppendResult(interp, "SetHook error: wrong dwThreadId", NULL);
            return TCL_ERROR;
        }

        dwThreadId = (DWORD)lThreadId;
    }


    for (idHookNum = 0; idHookNum < MAX_HOOKS && hookCallbackArray[idHookNum].hHook != NULL; idHookNum++);

    if (idHookNum == MAX_HOOKS) {
        Tcl_AppendResult(interp, "SetHook error: max number of hooks reached", NULL);
        return TCL_ERROR;
    }

    hHook = SetWindowsHookEx(idHook, hookCallbackArray[idHookNum].lpfn, hInstance, dwThreadId);

    if (hHook == NULL) {
        char buf[25];
        snprintf(buf, 25, "%lu", GetLastError());
        Tcl_AppendResult(interp, "SetHook error: SetWindowsHookEx() failed: ", buf, NULL);
        return TCL_ERROR;
    }

    hookCallbackArray[idHookNum].hHook = hHook;
    hookCallbackArray[idHookNum].idHook = idHook;
    hookCallbackArray[idHookNum].dwThreadId = dwThreadId;
    hookCallbackArray[idHookNum].bRevocable = bRevocable;
    hookCallbackArray[idHookNum].interp = interp;

    Tcl_SetObjResult(interp, Tcl_NewIntObj(idHookNum));

    return TCL_OK;

}

static int ReleaseHook_Cmd(ClientData clientData, Tcl_Interp *interp, int objc, Tcl_Obj *const objv[]) {

    unsigned int idHookNum = 0;

    if (objc < 2) {
        Tcl_WrongNumArgs(interp, 1, objv, "iHookNum");
        return TCL_ERROR;
    }

    if (Tcl_GetIntFromObj(interp, objv[1], &idHookNum) != TCL_OK) {
        Tcl_AppendResult(interp, "ReleaseHook error: wrong iHookNum", NULL);
        return TCL_ERROR;
    }

    if (idHookNum >= MAX_HOOKS) {
        Tcl_AppendResult(interp, "ReleaseHook error: iHookNum value is not within the acceptable range", NULL);
        return TCL_ERROR;
    }

    if (hookCallbackArray[idHookNum].hHook == NULL) {
        Tcl_AppendResult(interp, "ReleaseHook error: iHookNum has already been removed", NULL);
        return TCL_ERROR;
    }

    if (!UnhookWindowsHookEx(hookCallbackArray[idHookNum].hHook)) {
        char buf[25];
        snprintf(buf, 25, "%lu", GetLastError());
        Tcl_AppendResult(interp, "ReleaseHook error: UnhookWindowsHookEx() failed: ", buf, NULL);
        return TCL_ERROR;
    }

    Tcl_SetObjResult(interp, Tcl_NewIntObj(idHookNum));

    return TCL_OK;

}

int Tclwinhooks_Init(Tcl_Interp *interp) {

    static char const pkgNamespace[] = "::winhooks";
    static char const cmdSetHook[] = "::winhooks::SetHook";
    static char const cmdReleaseHook[] = "::winhooks::ReleaseHook";

    if (Tcl_InitStubs(interp, "8.1", 0) == NULL) {
        return TCL_ERROR;
    }

    Tcl_CreateNamespace(interp, pkgNamespace, NULL, NULL);

    Tcl_CreateObjCommand(interp, cmdSetHook, SetHook_Cmd, NULL, NULL);
    Tcl_CreateObjCommand(interp, cmdReleaseHook, ReleaseHook_Cmd, NULL, NULL);

    if (Tcl_PkgProvide(interp, PACKAGE_NAME, PACKAGE_VERSION) != TCL_OK) {
        return TCL_ERROR;
    }

    return TCL_OK;

}

int Tclwinhooks_SafeInit(Tcl_Interp *interp) {
    return Tclwinhooks_Init(interp);
}


BOOL APIENTRY DllMain(HANDLE hModule, DWORD dwReason, LPVOID lpReserved) {

    if (dwReason == DLL_PROCESS_ATTACH) {

        hInstance = (HINSTANCE)hModule;

    } else if (dwReason == DLL_PROCESS_DETACH) {

        for (int idHookNum = 0; idHookNum < MAX_HOOKS; idHookNum++) {

            if (hookCallbackArray[idHookNum].hHook == NULL) continue;

            UnhookWindowsHookEx(hookCallbackArray[idHookNum].hHook);
            hookCallbackArray[idHookNum].hHook = NULL;

        }

    }

    return TRUE;
}

