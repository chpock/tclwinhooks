#ifndef _TCLWINHOOKS
#define _TCLWINHOOKS

/*
 * For C++ compilers, use extern "C"
 */

#ifdef __cplusplus
extern "C" {
#endif

EXTERN void TclWinConvertError(DWORD errCode);

/*
 * Only the _Init function is exported.
 */

extern DLLEXPORT int Tclwinhooks_Init(Tcl_Interp * interp);
extern DLLEXPORT int Tclwinhooks_SafeInit(Tcl_Interp *interp);

/*
 * end block for C++
 */

#ifdef __cplusplus
}
#endif

#endif /* _TCLWINHOOKS */
