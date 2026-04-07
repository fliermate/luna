format PE console
entry start

include 'win32a.inc'

struct  CONSOLE_SCREEN_BUFFER_INFOEX
  cbSize                        dd ?
  dwSize                        dd ?
  dwCursorPosition              dd ?
  wAttributes                   dw ?
  srWindow                      rd 2
  dwMaximumWindowSize           dd ?
  wPopupAttributes              dw ?
  bFullScreenSupported          dd ?
  ColorTable                    rd 10h
ends

LEN equ 711141

section '.data' data readable writable

_filename       db      "luna.mp4.txt",0
_buffer         rb      LEN
_handle         dd      ?
_console        dd      ?
_len            dd      ?
_csbi           CONSOLE_SCREEN_BUFFER_INFOEX

section '.code' code readable executable

start:
        push    0
        push    FILE_ATTRIBUTE_NORMAL
        push    OPEN_EXISTING
        push    0
        push    FILE_SHARE_READ
        push    GENERIC_READ
        push    _filename
        call    [CreateFile]
        cmp     eax, INVALID_HANDLE_VALUE
        mov     dword [_handle], eax
        je      .error
        push    STD_OUTPUT_HANDLE
        call    [GetStdHandle]
        mov     dword [_console], eax
        push    0
        push    _len
        push    LEN
        push    _buffer
        push    dword [_handle]
        call    [ReadFile]
        test    eax, eax
        jz      .error

        mov     [_csbi.cbSize],sizeof.CONSOLE_SCREEN_BUFFER_INFOEX
        push    _csbi
        push    [_console]
        call    [GetConsoleScreenBufferInfoEx]
        mov     [_csbi.dwSize],160 or (40 shl 16)
        mov     [_csbi.srWindow],0
        mov     [_csbi.srWindow+4],160 or (40 shl 16)
        mov     [_csbi.dwMaximumWindowSize],160 or (40 shl 16)
        push    _csbi
        push    [_console]
        call    [SetConsoleScreenBufferInfoEx]

        call    [GetConsoleWindow]
        push    SWP_NOSIZE
        push    0
        push    0
        push    10
        push    40
        push    -1
        push    eax
        call    [SetWindowPos]

        call    Play

.error:
        push    0
        call    [ExitProcess]

Play:
; String split iterator (bitRAKE)
;
; RDI:  string to scan
; RCX:  length of string in characters, >0
; AX:   character to split on

        lea     edi, [_buffer]
        mov     ecx, dword [_len]

.scan:
        mov     al, '$'
        mov     esi, edi
        repnz   scasb
        push    edi
        jnz     .last
        sub     edi, 1               ; don't count the split character in length
.last:
        push    ecx
        sub     edi, esi             ; length without terminator
        ;jz skip

        ;push    0
        ;push    0
        ;call    [SetCursorPos]
        push    0                    ; FUNCTION (address:RSI, length:RDI)
        push    0
        push    edi
        push    esi
        push    dword [_console]
        call    [WriteConsole]
        push    100
        call    [Sleep]
        push    0x1B           ;ESC key
        call    [GetKeyState]
        bt      eax, 15        ; If the high-order bit is 1, the key is down; otherwise, it is up
        jnc      .skip
        add     esp, 8
        jmp     .done

.skip:
        pop     ecx                 ; characters to go
        pop     edi                 ; start
        ;cmp     ecx, 0
        jcxz    .done
        jmp     .scan

.done:
        ret

section '.idata' import readable writable

 library kernel32, 'KERNEL32.DLL',\
         user32,'USER32.DLL'

 import kernel32,\
        GetStdHandle, 'GetStdHandle', \
        WriteConsole, 'WriteConsoleA', \
        GetTickCount, 'GetTickCount', \
        Sleep, 'Sleep', \
        CreateFile, 'CreateFileA', \
        ReadFile, 'ReadFile', \
        ExitProcess,'ExitProcess', \
        GetConsoleWindow,'GetConsoleWindow',\
        GetConsoleScreenBufferInfoEx,'GetConsoleScreenBufferInfoEx',\
        SetConsoleScreenBufferInfoEx,'SetConsoleScreenBufferInfoEx'

 import user32,\
        SetWindowPos,'SetWindowPos',\
        SetCursorPos,'SetCursorPos',\
        GetKeyState, 'GetKeyState'
