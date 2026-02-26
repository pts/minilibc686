; by pts@fazekas.hu at Thu Feb 26 19:08:47 CET 2026
;
; Compile with: nasm-0.98.39 -O0 -w+orphan-labels -f bin -o tools/cc1-4.1.2 big-tools/cc1-4.1.2.patch.nasm && chmod +x tools/cc1-4.1.2
; 
; $ wget -c https://gcc.gnu.org/pub/gcc/releases/gcc-4.1.2/gcc-4.1.2.tar.bz2
; $ tar xjOf gcc-4.1.2.tar.bz2 gcc-4.1.2/gcc/c.opt >c.opt.4.1.2
;

%if 0
char *__cdecl getenv(const char *name);
int __cdecl main(int argc, char **argv, char **envp);
void __cdecl __noreturn libc_start_main(int (__cdecl *main)(int argc, char **argv, char **envp, void *auxvec), int argc, char **argv, void *auxvec, int (__cdecl *init)(int argc, char **argv, char **envp, void *auxvec), void (*fini)(void), void (*rtld_fini)(void), void *stack_end);
void __cdecl __noreturn exit(int exit_code);
void __cdecl init_block_move_fn(const char *asmspec);
struct tree_s *block_move_fn;
struct tree_s *__cdecl get_identifier_with_length(const char *name, size_t size);
struct tree_s *build_function_type_list(_DWORD, _DWORD, ...);
struct tree_s *__cdecl build_decl(_DWORD, _DWORD, _DWORD);
void __cdecl set_user_assembler_name(struct tree_s *tree, const char *asmspec);

struct cl_option {
  const char *opt_text;
  const char *help;
  unsigned __int16 back_chain;
  unsigned __int8 opt_len;
  enum cl_flags flags;
  void *flag_var;
  enum cl_var_type var_type;
  int var_value;
};

enum __bitmask cl_flags {
  CL_C = 0x1,
  CL_CXX = 0x2,
  CL_OBJC = 0x4,
  CL_OBJCXX = 0x8,
};

enum __dec cl_var_type {
  CLVC_BOOLEAN   = 0,
  CLVC_EQUAL     = 1,
  CLVC_BIT_CLEAR = 2,
  CLVC_BIT_SET   = 3,
  CLVC_STRING    = 4,
};

void init_block_move_fn(const char *asmspec) {
  if(!block_move_fn) {
    tree args, fn;
#ifdef FUNCT_SAME  /* Functionality unchanged. */
#else
    if (flag_objc_direct_dispatch) fn = get_identifier_with_length("__bultin_memcpy", sizeof("__builtin_memcpy") - 1);
    else
#endif
    args = build_function_type_list(ptr_type_node, ptr_type_node, const_ptr_type_node, sizetype, NULL_TREE);
    fn = build_decl(FUNCTION_DECL, fn, args);
    DECL_EXTERNAL(fn) = 1;
    TREE_PUBLIC(fn) = 1;
    DECL_ARTIFICIAL(fn) = 1;
    TREE_NOTHROW(fn) = 1;
    DECL_VISIBILITY(fn) = VISIBILITY_DEFAULT;
    DECL_VISIBILITY_SPECIFIED(fn) = 1;
    block_move_fn = fn;
  }
  if (asmspec) set_user_assembler_name(block_move_fn, asmspec);
}
%endif

bits 32
cpu 386
TEXTBASE equ 0x8048000
%define INFN 'big-tools/cc1-4.1.2.unc.orig'

CL_C equ 1
CL_CXX equ 2
CL_OBJC equ 4
CL_OBJCXX equ 8

init_block_move_fn_vaddr equ 0x817e7d0
init_block_move_fn_after_vaddr equ 0x817e890
block_move_fn equ 0x84c5464
set_user_assembler_name equ $$-TEXTBASE+0x830ce60
get_identifier_with_length equ $$-TEXTBASE+0x82f85d0
build_function_type_list equ $$-TEXTBASE+0x8301010
build_decl equ $$-TEXTBASE+0x8301940
ptr_type_node equ 0x853f514
const_ptr_type_node equ 0x853f518
sizetype equ 0x853b328
cstr_memcpy equ 0x8419ef9  ; db 'memcpy', 0
cstr_memcpy.size equ 6
cstr_builtin_memcpy equ cstr_memcpy-10  ; db '__builtin_memcpy', 0
cstr_builtin_memcpy.size equ 16
flag_objc_direct_dispatch equ 0x852fe54  ; dd ?
cl_option_fobjc_direct_dispactch equ 0x848394c
cl_option_field_flags equ 0xc

incbin INFN, 0, init_block_move_fn_vaddr-TEXTBASE
init_block_move_fn:
.asmspec equ 3*4
	push ebx  ; Save.
	push esi  ; Save.
	mov esi, [esp+.asmspec]
	mov eax, [block_move_fn]
	test eax, eax
	jnz short .maybe_set_user_assembler_name
.build_block_move_fn:
	push byte cstr_memcpy.size
	pop edx
	mov eax, cstr_memcpy
%ifdef FUNCT_SAME  ; Functionality unchanged.
%else
	cmp dword [flag_objc_direct_dispatch], byte 0
	je short .no_change  ; Jump iff -fobjc-direct-dispactch is unspecified.
	add eax, byte cstr_builtin_memcpy-cstr_memcpy  ; EAX := cstr_builtin_memcpy.
	add edx, byte cstr_builtin_memcpy.size-cstr_memcpy.size  ; EDX := cstr_bultin_memcpy.
.no_change:
%endif
	push edx  ; size.
	push eax  ; name.
	call get_identifier_with_length
	times 2 pop edx  ; Clean up arguments of get_identifier_with_length above.
	xchg ebx, eax  ; EBX := result above (EAX); EAX := junk.
	push byte 0  ; NULL_TREE.
	push dword [sizetype]
	push dword [const_ptr_type_node]
	mov eax, [ptr_type_node]
	push eax
	push eax
	call build_function_type_list
	add esp, 5*4  ; Clean up arguments of build_function_type_list above.
	push eax
	push ebx
	push byte 0x1c
	call build_decl
	add esp, byte 3*4  ; Clean up arguments of build_decl above.
	or byte [eax+0x2b], 0x4
	or byte [eax+0x29], 0x10
	or byte [eax+0xe], 0xa
	and byte [eax+0x55], 0x9f
	or byte [eax+0x55], 0x80
	mov [block_move_fn], eax
.maybe_set_user_assembler_name:
	test esi, esi
	jz short .done
	push esi  ; asmspec.
	push eax  ; dword [block_move_fn].
	call set_user_assembler_name
	times 2 pop edx  ; Clean up arguments of get_identifier_with_length above.
.done:	
	pop esi  ; Restore.
	pop ebx  ; Restore.
	ret
times init_block_move_fn_after_vaddr-TEXTBASE-($-$$) db 0
incbin INFN, init_block_move_fn_after_vaddr-TEXTBASE, (cl_option_fobjc_direct_dispactch+cl_option_field_flags-TEXTBASE)-(init_block_move_fn_after_vaddr-TEXTBASE)
	dd CL_C|CL_OBJC|CL_OBJCXX  ; Original value: CL_OBJC|CL_OBJCXX. Adding CL_C to the value to prevent the warning (and the no-op): command line option "-fobjc-direct-dispatch" is valid for ObjC/ObjC++ but not for C 
incbin INFN, cl_option_fobjc_direct_dispactch+cl_option_field_flags+4-TEXTBASE
