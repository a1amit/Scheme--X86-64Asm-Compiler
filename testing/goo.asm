;;; prologue-1.asm
;;; The first part of the standard prologue for compiled programs
;;;
;;; Programmer: Mayer Goldberg, 2023

%define T_void 				0
%define T_nil 				1
%define T_char 				2
%define T_string 			3
%define T_closure 			4
%define T_undefined			5
%define T_boolean 			8
%define T_boolean_false 		(T_boolean | 1)
%define T_boolean_true 			(T_boolean | 2)
%define T_number 			16
%define T_integer			(T_number | 1)
%define T_fraction 			(T_number | 2)
%define T_real 				(T_number | 3)
%define T_collection 			32
%define T_pair 				(T_collection | 1)
%define T_vector 			(T_collection | 2)
%define T_symbol 			64
%define T_interned_symbol		(T_symbol | 1)
%define T_uninterned_symbol		(T_symbol | 2)

%define SOB_CHAR_VALUE(reg) 		byte [reg + 1]
%define SOB_PAIR_CAR(reg)		qword [reg + 1]
%define SOB_PAIR_CDR(reg)		qword [reg + 1 + 8]
%define SOB_STRING_LENGTH(reg)		qword [reg + 1]
%define SOB_VECTOR_LENGTH(reg)		qword [reg + 1]
%define SOB_CLOSURE_ENV(reg)		qword [reg + 1]
%define SOB_CLOSURE_CODE(reg)		qword [reg + 1 + 8]

%define OLD_RBP 			qword [rbp]
%define RET_ADDR 			qword [rbp + 8 * 1]
%define ENV 				qword [rbp + 8 * 2]
%define COUNT 				qword [rbp + 8 * 3]
%define PARAM(n) 			qword [rbp + 8 * (4 + n)]
%define AND_KILL_FRAME(n)		(8 * (2 + n))

%define MAGIC				496351

%macro ENTER 0
	enter 0, 0
	and rsp, ~15
%endmacro

%macro LEAVE 0
	leave
%endmacro

%macro assert_type 2
        cmp byte [%1], %2
        jne L_error_incorrect_type
%endmacro

%define assert_void(reg)		assert_type reg, T_void
%define assert_nil(reg)			assert_type reg, T_nil
%define assert_char(reg)		assert_type reg, T_char
%define assert_string(reg)		assert_type reg, T_string
%define assert_symbol(reg)		assert_type reg, T_symbol
%define assert_interned_symbol(reg)	assert_type reg, T_interned_symbol
%define assert_uninterned_symbol(reg)	assert_type reg, T_uninterned_symbol
%define assert_closure(reg)		assert_type reg, T_closure
%define assert_boolean(reg)		assert_type reg, T_boolean
%define assert_integer(reg)		assert_type reg, T_integer
%define assert_fraction(reg)		assert_type reg, T_fraction
%define assert_real(reg)		assert_type reg, T_real
%define assert_pair(reg)		assert_type reg, T_pair
%define assert_vector(reg)		assert_type reg, T_vector

%define sob_void			(L_constants + 0)
%define sob_nil				(L_constants + 1)
%define sob_boolean_false		(L_constants + 2)
%define sob_boolean_true		(L_constants + 3)
%define sob_char_nul			(L_constants + 4)

%define bytes(n)			(n)
%define kbytes(n) 			(bytes(n) << 10)
%define mbytes(n) 			(kbytes(n) << 10)
%define gbytes(n) 			(mbytes(n) << 10)

section .data
L_constants:
	; L_constants + 0:
	db T_void
	; L_constants + 1:
	db T_nil
	; L_constants + 2:
	db T_boolean_false
	; L_constants + 3:
	db T_boolean_true
	; L_constants + 4:
	db T_char, 0x00	; #\nul
	; L_constants + 6:
	db T_string	; "null?"
	dq 5
	db 0x6E, 0x75, 0x6C, 0x6C, 0x3F
	; L_constants + 20:
	db T_string	; "pair?"
	dq 5
	db 0x70, 0x61, 0x69, 0x72, 0x3F
	; L_constants + 34:
	db T_string	; "void?"
	dq 5
	db 0x76, 0x6F, 0x69, 0x64, 0x3F
	; L_constants + 48:
	db T_string	; "char?"
	dq 5
	db 0x63, 0x68, 0x61, 0x72, 0x3F
	; L_constants + 62:
	db T_string	; "string?"
	dq 7
	db 0x73, 0x74, 0x72, 0x69, 0x6E, 0x67, 0x3F
	; L_constants + 78:
	db T_string	; "interned-symbol?"
	dq 16
	db 0x69, 0x6E, 0x74, 0x65, 0x72, 0x6E, 0x65, 0x64
	db 0x2D, 0x73, 0x79, 0x6D, 0x62, 0x6F, 0x6C, 0x3F
	; L_constants + 103:
	db T_string	; "vector?"
	dq 7
	db 0x76, 0x65, 0x63, 0x74, 0x6F, 0x72, 0x3F
	; L_constants + 119:
	db T_string	; "procedure?"
	dq 10
	db 0x70, 0x72, 0x6F, 0x63, 0x65, 0x64, 0x75, 0x72
	db 0x65, 0x3F
	; L_constants + 138:
	db T_string	; "real?"
	dq 5
	db 0x72, 0x65, 0x61, 0x6C, 0x3F
	; L_constants + 152:
	db T_string	; "fraction?"
	dq 9
	db 0x66, 0x72, 0x61, 0x63, 0x74, 0x69, 0x6F, 0x6E
	db 0x3F
	; L_constants + 170:
	db T_string	; "boolean?"
	dq 8
	db 0x62, 0x6F, 0x6F, 0x6C, 0x65, 0x61, 0x6E, 0x3F
	; L_constants + 187:
	db T_string	; "number?"
	dq 7
	db 0x6E, 0x75, 0x6D, 0x62, 0x65, 0x72, 0x3F
	; L_constants + 203:
	db T_string	; "collection?"
	dq 11
	db 0x63, 0x6F, 0x6C, 0x6C, 0x65, 0x63, 0x74, 0x69
	db 0x6F, 0x6E, 0x3F
	; L_constants + 223:
	db T_string	; "cons"
	dq 4
	db 0x63, 0x6F, 0x6E, 0x73
	; L_constants + 236:
	db T_string	; "display-sexpr"
	dq 13
	db 0x64, 0x69, 0x73, 0x70, 0x6C, 0x61, 0x79, 0x2D
	db 0x73, 0x65, 0x78, 0x70, 0x72
	; L_constants + 258:
	db T_string	; "write-char"
	dq 10
	db 0x77, 0x72, 0x69, 0x74, 0x65, 0x2D, 0x63, 0x68
	db 0x61, 0x72
	; L_constants + 277:
	db T_string	; "car"
	dq 3
	db 0x63, 0x61, 0x72
	; L_constants + 289:
	db T_string	; "cdr"
	dq 3
	db 0x63, 0x64, 0x72
	; L_constants + 301:
	db T_string	; "string-length"
	dq 13
	db 0x73, 0x74, 0x72, 0x69, 0x6E, 0x67, 0x2D, 0x6C
	db 0x65, 0x6E, 0x67, 0x74, 0x68
	; L_constants + 323:
	db T_string	; "vector-length"
	dq 13
	db 0x76, 0x65, 0x63, 0x74, 0x6F, 0x72, 0x2D, 0x6C
	db 0x65, 0x6E, 0x67, 0x74, 0x68
	; L_constants + 345:
	db T_string	; "real->integer"
	dq 13
	db 0x72, 0x65, 0x61, 0x6C, 0x2D, 0x3E, 0x69, 0x6E
	db 0x74, 0x65, 0x67, 0x65, 0x72
	; L_constants + 367:
	db T_string	; "exit"
	dq 4
	db 0x65, 0x78, 0x69, 0x74
	; L_constants + 380:
	db T_string	; "integer->real"
	dq 13
	db 0x69, 0x6E, 0x74, 0x65, 0x67, 0x65, 0x72, 0x2D
	db 0x3E, 0x72, 0x65, 0x61, 0x6C
	; L_constants + 402:
	db T_string	; "fraction->real"
	dq 14
	db 0x66, 0x72, 0x61, 0x63, 0x74, 0x69, 0x6F, 0x6E
	db 0x2D, 0x3E, 0x72, 0x65, 0x61, 0x6C
	; L_constants + 425:
	db T_string	; "char->integer"
	dq 13
	db 0x63, 0x68, 0x61, 0x72, 0x2D, 0x3E, 0x69, 0x6E
	db 0x74, 0x65, 0x67, 0x65, 0x72
	; L_constants + 447:
	db T_string	; "integer->char"
	dq 13
	db 0x69, 0x6E, 0x74, 0x65, 0x67, 0x65, 0x72, 0x2D
	db 0x3E, 0x63, 0x68, 0x61, 0x72
	; L_constants + 469:
	db T_string	; "trng"
	dq 4
	db 0x74, 0x72, 0x6E, 0x67
	; L_constants + 482:
	db T_string	; "zero?"
	dq 5
	db 0x7A, 0x65, 0x72, 0x6F, 0x3F
	; L_constants + 496:
	db T_string	; "integer?"
	dq 8
	db 0x69, 0x6E, 0x74, 0x65, 0x67, 0x65, 0x72, 0x3F
	; L_constants + 513:
	db T_string	; "__bin-apply"
	dq 11
	db 0x5F, 0x5F, 0x62, 0x69, 0x6E, 0x2D, 0x61, 0x70
	db 0x70, 0x6C, 0x79
	; L_constants + 533:
	db T_string	; "__bin-add-rr"
	dq 12
	db 0x5F, 0x5F, 0x62, 0x69, 0x6E, 0x2D, 0x61, 0x64
	db 0x64, 0x2D, 0x72, 0x72
	; L_constants + 554:
	db T_string	; "__bin-sub-rr"
	dq 12
	db 0x5F, 0x5F, 0x62, 0x69, 0x6E, 0x2D, 0x73, 0x75
	db 0x62, 0x2D, 0x72, 0x72
	; L_constants + 575:
	db T_string	; "__bin-mul-rr"
	dq 12
	db 0x5F, 0x5F, 0x62, 0x69, 0x6E, 0x2D, 0x6D, 0x75
	db 0x6C, 0x2D, 0x72, 0x72
	; L_constants + 596:
	db T_string	; "__bin-div-rr"
	dq 12
	db 0x5F, 0x5F, 0x62, 0x69, 0x6E, 0x2D, 0x64, 0x69
	db 0x76, 0x2D, 0x72, 0x72
	; L_constants + 617:
	db T_string	; "__bin-add-qq"
	dq 12
	db 0x5F, 0x5F, 0x62, 0x69, 0x6E, 0x2D, 0x61, 0x64
	db 0x64, 0x2D, 0x71, 0x71
	; L_constants + 638:
	db T_string	; "__bin-sub-qq"
	dq 12
	db 0x5F, 0x5F, 0x62, 0x69, 0x6E, 0x2D, 0x73, 0x75
	db 0x62, 0x2D, 0x71, 0x71
	; L_constants + 659:
	db T_string	; "__bin-mul-qq"
	dq 12
	db 0x5F, 0x5F, 0x62, 0x69, 0x6E, 0x2D, 0x6D, 0x75
	db 0x6C, 0x2D, 0x71, 0x71
	; L_constants + 680:
	db T_string	; "__bin-div-qq"
	dq 12
	db 0x5F, 0x5F, 0x62, 0x69, 0x6E, 0x2D, 0x64, 0x69
	db 0x76, 0x2D, 0x71, 0x71
	; L_constants + 701:
	db T_string	; "__bin-add-zz"
	dq 12
	db 0x5F, 0x5F, 0x62, 0x69, 0x6E, 0x2D, 0x61, 0x64
	db 0x64, 0x2D, 0x7A, 0x7A
	; L_constants + 722:
	db T_string	; "__bin-sub-zz"
	dq 12
	db 0x5F, 0x5F, 0x62, 0x69, 0x6E, 0x2D, 0x73, 0x75
	db 0x62, 0x2D, 0x7A, 0x7A
	; L_constants + 743:
	db T_string	; "__bin-mul-zz"
	dq 12
	db 0x5F, 0x5F, 0x62, 0x69, 0x6E, 0x2D, 0x6D, 0x75
	db 0x6C, 0x2D, 0x7A, 0x7A
	; L_constants + 764:
	db T_string	; "__bin-div-zz"
	dq 12
	db 0x5F, 0x5F, 0x62, 0x69, 0x6E, 0x2D, 0x64, 0x69
	db 0x76, 0x2D, 0x7A, 0x7A
	; L_constants + 785:
	db T_string	; "error"
	dq 5
	db 0x65, 0x72, 0x72, 0x6F, 0x72
	; L_constants + 799:
	db T_string	; "__bin-less-than-rr"
	dq 18
	db 0x5F, 0x5F, 0x62, 0x69, 0x6E, 0x2D, 0x6C, 0x65
	db 0x73, 0x73, 0x2D, 0x74, 0x68, 0x61, 0x6E, 0x2D
	db 0x72, 0x72
	; L_constants + 826:
	db T_string	; "__bin-less-than-qq"
	dq 18
	db 0x5F, 0x5F, 0x62, 0x69, 0x6E, 0x2D, 0x6C, 0x65
	db 0x73, 0x73, 0x2D, 0x74, 0x68, 0x61, 0x6E, 0x2D
	db 0x71, 0x71
	; L_constants + 853:
	db T_string	; "__bin-less-than-zz"
	dq 18
	db 0x5F, 0x5F, 0x62, 0x69, 0x6E, 0x2D, 0x6C, 0x65
	db 0x73, 0x73, 0x2D, 0x74, 0x68, 0x61, 0x6E, 0x2D
	db 0x7A, 0x7A
	; L_constants + 880:
	db T_string	; "__bin-equal-rr"
	dq 14
	db 0x5F, 0x5F, 0x62, 0x69, 0x6E, 0x2D, 0x65, 0x71
	db 0x75, 0x61, 0x6C, 0x2D, 0x72, 0x72
	; L_constants + 903:
	db T_string	; "__bin-equal-qq"
	dq 14
	db 0x5F, 0x5F, 0x62, 0x69, 0x6E, 0x2D, 0x65, 0x71
	db 0x75, 0x61, 0x6C, 0x2D, 0x71, 0x71
	; L_constants + 926:
	db T_string	; "__bin-equal-zz"
	dq 14
	db 0x5F, 0x5F, 0x62, 0x69, 0x6E, 0x2D, 0x65, 0x71
	db 0x75, 0x61, 0x6C, 0x2D, 0x7A, 0x7A
	; L_constants + 949:
	db T_string	; "quotient"
	dq 8
	db 0x71, 0x75, 0x6F, 0x74, 0x69, 0x65, 0x6E, 0x74
	; L_constants + 966:
	db T_string	; "remainder"
	dq 9
	db 0x72, 0x65, 0x6D, 0x61, 0x69, 0x6E, 0x64, 0x65
	db 0x72
	; L_constants + 984:
	db T_string	; "set-car!"
	dq 8
	db 0x73, 0x65, 0x74, 0x2D, 0x63, 0x61, 0x72, 0x21
	; L_constants + 1001:
	db T_string	; "set-cdr!"
	dq 8
	db 0x73, 0x65, 0x74, 0x2D, 0x63, 0x64, 0x72, 0x21
	; L_constants + 1018:
	db T_string	; "string-ref"
	dq 10
	db 0x73, 0x74, 0x72, 0x69, 0x6E, 0x67, 0x2D, 0x72
	db 0x65, 0x66
	; L_constants + 1037:
	db T_string	; "vector-ref"
	dq 10
	db 0x76, 0x65, 0x63, 0x74, 0x6F, 0x72, 0x2D, 0x72
	db 0x65, 0x66
	; L_constants + 1056:
	db T_string	; "vector-set!"
	dq 11
	db 0x76, 0x65, 0x63, 0x74, 0x6F, 0x72, 0x2D, 0x73
	db 0x65, 0x74, 0x21
	; L_constants + 1076:
	db T_string	; "string-set!"
	dq 11
	db 0x73, 0x74, 0x72, 0x69, 0x6E, 0x67, 0x2D, 0x73
	db 0x65, 0x74, 0x21
	; L_constants + 1096:
	db T_string	; "make-vector"
	dq 11
	db 0x6D, 0x61, 0x6B, 0x65, 0x2D, 0x76, 0x65, 0x63
	db 0x74, 0x6F, 0x72
	; L_constants + 1116:
	db T_string	; "make-string"
	dq 11
	db 0x6D, 0x61, 0x6B, 0x65, 0x2D, 0x73, 0x74, 0x72
	db 0x69, 0x6E, 0x67
	; L_constants + 1136:
	db T_string	; "numerator"
	dq 9
	db 0x6E, 0x75, 0x6D, 0x65, 0x72, 0x61, 0x74, 0x6F
	db 0x72
	; L_constants + 1154:
	db T_string	; "denominator"
	dq 11
	db 0x64, 0x65, 0x6E, 0x6F, 0x6D, 0x69, 0x6E, 0x61
	db 0x74, 0x6F, 0x72
	; L_constants + 1174:
	db T_string	; "eq?"
	dq 3
	db 0x65, 0x71, 0x3F
	; L_constants + 1186:
	db T_string	; "__integer-to-fracti...
	dq 21
	db 0x5F, 0x5F, 0x69, 0x6E, 0x74, 0x65, 0x67, 0x65
	db 0x72, 0x2D, 0x74, 0x6F, 0x2D, 0x66, 0x72, 0x61
	db 0x63, 0x74, 0x69, 0x6F, 0x6E
	; L_constants + 1216:
	db T_string	; "logand"
	dq 6
	db 0x6C, 0x6F, 0x67, 0x61, 0x6E, 0x64
	; L_constants + 1231:
	db T_string	; "logor"
	dq 5
	db 0x6C, 0x6F, 0x67, 0x6F, 0x72
	; L_constants + 1245:
	db T_string	; "logxor"
	dq 6
	db 0x6C, 0x6F, 0x67, 0x78, 0x6F, 0x72
	; L_constants + 1260:
	db T_string	; "lognot"
	dq 6
	db 0x6C, 0x6F, 0x67, 0x6E, 0x6F, 0x74
	; L_constants + 1275:
	db T_string	; "ash"
	dq 3
	db 0x61, 0x73, 0x68
	; L_constants + 1287:
	db T_string	; "symbol?"
	dq 7
	db 0x73, 0x79, 0x6D, 0x62, 0x6F, 0x6C, 0x3F
	; L_constants + 1303:
	db T_string	; "uninterned-symbol?"
	dq 18
	db 0x75, 0x6E, 0x69, 0x6E, 0x74, 0x65, 0x72, 0x6E
	db 0x65, 0x64, 0x2D, 0x73, 0x79, 0x6D, 0x62, 0x6F
	db 0x6C, 0x3F
	; L_constants + 1330:
	db T_string	; "gensym?"
	dq 7
	db 0x67, 0x65, 0x6E, 0x73, 0x79, 0x6D, 0x3F
	; L_constants + 1346:
	db T_string	; "gensym"
	dq 6
	db 0x67, 0x65, 0x6E, 0x73, 0x79, 0x6D
	; L_constants + 1361:
	db T_string	; "frame"
	dq 5
	db 0x66, 0x72, 0x61, 0x6D, 0x65
	; L_constants + 1375:
	db T_string	; "break"
	dq 5
	db 0x62, 0x72, 0x65, 0x61, 0x6B
	; L_constants + 1389:
	db T_string	; "boolean-false?"
	dq 14
	db 0x62, 0x6F, 0x6F, 0x6C, 0x65, 0x61, 0x6E, 0x2D
	db 0x66, 0x61, 0x6C, 0x73, 0x65, 0x3F
	; L_constants + 1412:
	db T_string	; "boolean-true?"
	dq 13
	db 0x62, 0x6F, 0x6F, 0x6C, 0x65, 0x61, 0x6E, 0x2D
	db 0x74, 0x72, 0x75, 0x65, 0x3F
	; L_constants + 1434:
	db T_string	; "primitive?"
	dq 10
	db 0x70, 0x72, 0x69, 0x6D, 0x69, 0x74, 0x69, 0x76
	db 0x65, 0x3F
	; L_constants + 1453:
	db T_string	; "length"
	dq 6
	db 0x6C, 0x65, 0x6E, 0x67, 0x74, 0x68
	; L_constants + 1468:
	db T_string	; "make-list"
	dq 9
	db 0x6D, 0x61, 0x6B, 0x65, 0x2D, 0x6C, 0x69, 0x73
	db 0x74
	; L_constants + 1486:
	db T_string	; "return"
	dq 6
	db 0x72, 0x65, 0x74, 0x75, 0x72, 0x6E
	; L_constants + 1501:
	db T_string	; "caar"
	dq 4
	db 0x63, 0x61, 0x61, 0x72
	; L_constants + 1514:
	db T_interned_symbol	; caar
	dq L_constants + 1501
	; L_constants + 1523:
	db T_interned_symbol	; car
	dq L_constants + 277
	; L_constants + 1532:
	db T_string	; "cadr"
	dq 4
	db 0x63, 0x61, 0x64, 0x72
	; L_constants + 1545:
	db T_interned_symbol	; cadr
	dq L_constants + 1532
	; L_constants + 1554:
	db T_interned_symbol	; cdr
	dq L_constants + 289
	; L_constants + 1563:
	db T_string	; "cdar"
	dq 4
	db 0x63, 0x64, 0x61, 0x72
	; L_constants + 1576:
	db T_interned_symbol	; cdar
	dq L_constants + 1563
	; L_constants + 1585:
	db T_string	; "cddr"
	dq 4
	db 0x63, 0x64, 0x64, 0x72
	; L_constants + 1598:
	db T_interned_symbol	; cddr
	dq L_constants + 1585
	; L_constants + 1607:
	db T_string	; "caaar"
	dq 5
	db 0x63, 0x61, 0x61, 0x61, 0x72
	; L_constants + 1621:
	db T_interned_symbol	; caaar
	dq L_constants + 1607
	; L_constants + 1630:
	db T_string	; "caadr"
	dq 5
	db 0x63, 0x61, 0x61, 0x64, 0x72
	; L_constants + 1644:
	db T_interned_symbol	; caadr
	dq L_constants + 1630
	; L_constants + 1653:
	db T_string	; "cadar"
	dq 5
	db 0x63, 0x61, 0x64, 0x61, 0x72
	; L_constants + 1667:
	db T_interned_symbol	; cadar
	dq L_constants + 1653
	; L_constants + 1676:
	db T_string	; "caddr"
	dq 5
	db 0x63, 0x61, 0x64, 0x64, 0x72
	; L_constants + 1690:
	db T_interned_symbol	; caddr
	dq L_constants + 1676
	; L_constants + 1699:
	db T_string	; "cdaar"
	dq 5
	db 0x63, 0x64, 0x61, 0x61, 0x72
	; L_constants + 1713:
	db T_interned_symbol	; cdaar
	dq L_constants + 1699
	; L_constants + 1722:
	db T_string	; "cdadr"
	dq 5
	db 0x63, 0x64, 0x61, 0x64, 0x72
	; L_constants + 1736:
	db T_interned_symbol	; cdadr
	dq L_constants + 1722
	; L_constants + 1745:
	db T_string	; "cddar"
	dq 5
	db 0x63, 0x64, 0x64, 0x61, 0x72
	; L_constants + 1759:
	db T_interned_symbol	; cddar
	dq L_constants + 1745
	; L_constants + 1768:
	db T_string	; "cdddr"
	dq 5
	db 0x63, 0x64, 0x64, 0x64, 0x72
	; L_constants + 1782:
	db T_interned_symbol	; cdddr
	dq L_constants + 1768
	; L_constants + 1791:
	db T_string	; "caaaar"
	dq 6
	db 0x63, 0x61, 0x61, 0x61, 0x61, 0x72
	; L_constants + 1806:
	db T_interned_symbol	; caaaar
	dq L_constants + 1791
	; L_constants + 1815:
	db T_string	; "caaadr"
	dq 6
	db 0x63, 0x61, 0x61, 0x61, 0x64, 0x72
	; L_constants + 1830:
	db T_interned_symbol	; caaadr
	dq L_constants + 1815
	; L_constants + 1839:
	db T_string	; "caadar"
	dq 6
	db 0x63, 0x61, 0x61, 0x64, 0x61, 0x72
	; L_constants + 1854:
	db T_interned_symbol	; caadar
	dq L_constants + 1839
	; L_constants + 1863:
	db T_string	; "caaddr"
	dq 6
	db 0x63, 0x61, 0x61, 0x64, 0x64, 0x72
	; L_constants + 1878:
	db T_interned_symbol	; caaddr
	dq L_constants + 1863
	; L_constants + 1887:
	db T_string	; "cadaar"
	dq 6
	db 0x63, 0x61, 0x64, 0x61, 0x61, 0x72
	; L_constants + 1902:
	db T_interned_symbol	; cadaar
	dq L_constants + 1887
	; L_constants + 1911:
	db T_string	; "cadadr"
	dq 6
	db 0x63, 0x61, 0x64, 0x61, 0x64, 0x72
	; L_constants + 1926:
	db T_interned_symbol	; cadadr
	dq L_constants + 1911
	; L_constants + 1935:
	db T_string	; "caddar"
	dq 6
	db 0x63, 0x61, 0x64, 0x64, 0x61, 0x72
	; L_constants + 1950:
	db T_interned_symbol	; caddar
	dq L_constants + 1935
	; L_constants + 1959:
	db T_string	; "cadddr"
	dq 6
	db 0x63, 0x61, 0x64, 0x64, 0x64, 0x72
	; L_constants + 1974:
	db T_interned_symbol	; cadddr
	dq L_constants + 1959
	; L_constants + 1983:
	db T_string	; "cdaaar"
	dq 6
	db 0x63, 0x64, 0x61, 0x61, 0x61, 0x72
	; L_constants + 1998:
	db T_interned_symbol	; cdaaar
	dq L_constants + 1983
	; L_constants + 2007:
	db T_string	; "cdaadr"
	dq 6
	db 0x63, 0x64, 0x61, 0x61, 0x64, 0x72
	; L_constants + 2022:
	db T_interned_symbol	; cdaadr
	dq L_constants + 2007
	; L_constants + 2031:
	db T_string	; "cdadar"
	dq 6
	db 0x63, 0x64, 0x61, 0x64, 0x61, 0x72
	; L_constants + 2046:
	db T_interned_symbol	; cdadar
	dq L_constants + 2031
	; L_constants + 2055:
	db T_string	; "cdaddr"
	dq 6
	db 0x63, 0x64, 0x61, 0x64, 0x64, 0x72
	; L_constants + 2070:
	db T_interned_symbol	; cdaddr
	dq L_constants + 2055
	; L_constants + 2079:
	db T_string	; "cddaar"
	dq 6
	db 0x63, 0x64, 0x64, 0x61, 0x61, 0x72
	; L_constants + 2094:
	db T_interned_symbol	; cddaar
	dq L_constants + 2079
	; L_constants + 2103:
	db T_string	; "cddadr"
	dq 6
	db 0x63, 0x64, 0x64, 0x61, 0x64, 0x72
	; L_constants + 2118:
	db T_interned_symbol	; cddadr
	dq L_constants + 2103
	; L_constants + 2127:
	db T_string	; "cdddar"
	dq 6
	db 0x63, 0x64, 0x64, 0x64, 0x61, 0x72
	; L_constants + 2142:
	db T_interned_symbol	; cdddar
	dq L_constants + 2127
	; L_constants + 2151:
	db T_string	; "cddddr"
	dq 6
	db 0x63, 0x64, 0x64, 0x64, 0x64, 0x72
	; L_constants + 2166:
	db T_interned_symbol	; cddddr
	dq L_constants + 2151
	; L_constants + 2175:
	db T_string	; "list?"
	dq 5
	db 0x6C, 0x69, 0x73, 0x74, 0x3F
	; L_constants + 2189:
	db T_interned_symbol	; list?
	dq L_constants + 2175
	; L_constants + 2198:
	db T_interned_symbol	; null?
	dq L_constants + 6
	; L_constants + 2207:
	db T_interned_symbol	; pair?
	dq L_constants + 20
	; L_constants + 2216:
	db T_string	; "list"
	dq 4
	db 0x6C, 0x69, 0x73, 0x74
	; L_constants + 2229:
	db T_string	; "not"
	dq 3
	db 0x6E, 0x6F, 0x74
	; L_constants + 2241:
	db T_interned_symbol	; not
	dq L_constants + 2229
	; L_constants + 2250:
	db T_string	; "rational?"
	dq 9
	db 0x72, 0x61, 0x74, 0x69, 0x6F, 0x6E, 0x61, 0x6C
	db 0x3F
	; L_constants + 2268:
	db T_interned_symbol	; rational?
	dq L_constants + 2250
	; L_constants + 2277:
	db T_interned_symbol	; integer?
	dq L_constants + 496
	; L_constants + 2286:
	db T_interned_symbol	; fraction?
	dq L_constants + 152
	; L_constants + 2295:
	db T_string	; "list*"
	dq 5
	db 0x6C, 0x69, 0x73, 0x74, 0x2A
	; L_constants + 2309:
	db T_interned_symbol	; list*
	dq L_constants + 2295
	; L_constants + 2318:
	db T_string	; "whatever"
	dq 8
	db 0x77, 0x68, 0x61, 0x74, 0x65, 0x76, 0x65, 0x72
	; L_constants + 2335:
	db T_interned_symbol	; whatever
	dq L_constants + 2318
	; L_constants + 2344:
	db T_string	; "apply"
	dq 5
	db 0x61, 0x70, 0x70, 0x6C, 0x79
	; L_constants + 2358:
	db T_interned_symbol	; apply
	dq L_constants + 2344
	; L_constants + 2367:
	db T_interned_symbol	; __bin-apply
	dq L_constants + 513
	; L_constants + 2376:
	db T_string	; "ormap"
	dq 5
	db 0x6F, 0x72, 0x6D, 0x61, 0x70
	; L_constants + 2390:
	db T_interned_symbol	; ormap
	dq L_constants + 2376
	; L_constants + 2399:
	db T_string	; "map"
	dq 3
	db 0x6D, 0x61, 0x70
	; L_constants + 2411:
	db T_interned_symbol	; map
	dq L_constants + 2399
	; L_constants + 2420:
	db T_string	; "andmap"
	dq 6
	db 0x61, 0x6E, 0x64, 0x6D, 0x61, 0x70
	; L_constants + 2435:
	db T_interned_symbol	; andmap
	dq L_constants + 2420
	; L_constants + 2444:
	db T_string	; "reverse"
	dq 7
	db 0x72, 0x65, 0x76, 0x65, 0x72, 0x73, 0x65
	; L_constants + 2460:
	db T_interned_symbol	; reverse
	dq L_constants + 2444
	; L_constants + 2469:
	db T_string	; "fold-left"
	dq 9
	db 0x66, 0x6F, 0x6C, 0x64, 0x2D, 0x6C, 0x65, 0x66
	db 0x74
	; L_constants + 2487:
	db T_interned_symbol	; fold-left
	dq L_constants + 2469
	; L_constants + 2496:
	db T_string	; "append"
	dq 6
	db 0x61, 0x70, 0x70, 0x65, 0x6E, 0x64
	; L_constants + 2511:
	db T_interned_symbol	; append
	dq L_constants + 2496
	; L_constants + 2520:
	db T_string	; "fold-right"
	dq 10
	db 0x66, 0x6F, 0x6C, 0x64, 0x2D, 0x72, 0x69, 0x67
	db 0x68, 0x74
	; L_constants + 2539:
	db T_interned_symbol	; fold-right
	dq L_constants + 2520
	; L_constants + 2548:
	db T_string	; "+"
	dq 1
	db 0x2B
	; L_constants + 2558:
	db T_integer	; 0
	dq 0
	; L_constants + 2567:
	db T_interned_symbol	; __bin-add-zz
	dq L_constants + 701
	; L_constants + 2576:
	db T_interned_symbol	; __bin-add-qq
	dq L_constants + 617
	; L_constants + 2585:
	db T_interned_symbol	; __integer-to-fractio...
	dq L_constants + 1186
	; L_constants + 2594:
	db T_interned_symbol	; real?
	dq L_constants + 138
	; L_constants + 2603:
	db T_interned_symbol	; __bin-add-rr
	dq L_constants + 533
	; L_constants + 2612:
	db T_interned_symbol	; integer->real
	dq L_constants + 380
	; L_constants + 2621:
	db T_string	; "__bin_integer_to_fr...
	dq 25
	db 0x5F, 0x5F, 0x62, 0x69, 0x6E, 0x5F, 0x69, 0x6E
	db 0x74, 0x65, 0x67, 0x65, 0x72, 0x5F, 0x74, 0x6F
	db 0x5F, 0x66, 0x72, 0x61, 0x63, 0x74, 0x69, 0x6F
	db 0x6E
	; L_constants + 2655:
	db T_interned_symbol	; __bin_integer_to_fra...
	dq L_constants + 2621
	; L_constants + 2664:
	db T_interned_symbol	; fraction->real
	dq L_constants + 402
	; L_constants + 2673:
	db T_interned_symbol	; error
	dq L_constants + 785
	; L_constants + 2682:
	db T_interned_symbol	; +
	dq L_constants + 2548
	; L_constants + 2691:
	db T_string	; "all arguments need ...
	dq 32
	db 0x61, 0x6C, 0x6C, 0x20, 0x61, 0x72, 0x67, 0x75
	db 0x6D, 0x65, 0x6E, 0x74, 0x73, 0x20, 0x6E, 0x65
	db 0x65, 0x64, 0x20, 0x74, 0x6F, 0x20, 0x62, 0x65
	db 0x20, 0x6E, 0x75, 0x6D, 0x62, 0x65, 0x72, 0x73
	; L_constants + 2732:
	db T_string	; "-"
	dq 1
	db 0x2D
	; L_constants + 2742:
	db T_interned_symbol	; __bin-sub-zz
	dq L_constants + 722
	; L_constants + 2751:
	db T_interned_symbol	; __bin-sub-qq
	dq L_constants + 638
	; L_constants + 2760:
	db T_string	; "real"
	dq 4
	db 0x72, 0x65, 0x61, 0x6C
	; L_constants + 2773:
	db T_interned_symbol	; real
	dq L_constants + 2760
	; L_constants + 2782:
	db T_interned_symbol	; __bin-sub-rr
	dq L_constants + 554
	; L_constants + 2791:
	db T_interned_symbol	; -
	dq L_constants + 2732
	; L_constants + 2800:
	db T_string	; "*"
	dq 1
	db 0x2A
	; L_constants + 2810:
	db T_integer	; 1
	dq 1
	; L_constants + 2819:
	db T_interned_symbol	; __bin-mul-zz
	dq L_constants + 743
	; L_constants + 2828:
	db T_interned_symbol	; __bin-mul-qq
	dq L_constants + 659
	; L_constants + 2837:
	db T_interned_symbol	; __bin-mul-rr
	dq L_constants + 575
	; L_constants + 2846:
	db T_interned_symbol	; *
	dq L_constants + 2800
	; L_constants + 2855:
	db T_string	; "/"
	dq 1
	db 0x2F
	; L_constants + 2865:
	db T_interned_symbol	; __bin-div-zz
	dq L_constants + 764
	; L_constants + 2874:
	db T_interned_symbol	; __bin-div-qq
	dq L_constants + 680
	; L_constants + 2883:
	db T_interned_symbol	; __bin-div-rr
	dq L_constants + 596
	; L_constants + 2892:
	db T_interned_symbol	; /
	dq L_constants + 2855
	; L_constants + 2901:
	db T_string	; "fact"
	dq 4
	db 0x66, 0x61, 0x63, 0x74
	; L_constants + 2914:
	db T_interned_symbol	; fact
	dq L_constants + 2901
	; L_constants + 2923:
	db T_interned_symbol	; zero?
	dq L_constants + 482
	; L_constants + 2932:
	db T_string	; "<"
	dq 1
	db 0x3C
	; L_constants + 2942:
	db T_interned_symbol	; <
	dq L_constants + 2932
	; L_constants + 2951:
	db T_string	; "<="
	dq 2
	db 0x3C, 0x3D
	; L_constants + 2962:
	db T_interned_symbol	; <=
	dq L_constants + 2951
	; L_constants + 2971:
	db T_string	; ">"
	dq 1
	db 0x3E
	; L_constants + 2981:
	db T_interned_symbol	; >
	dq L_constants + 2971
	; L_constants + 2990:
	db T_string	; ">="
	dq 2
	db 0x3E, 0x3D
	; L_constants + 3001:
	db T_interned_symbol	; >=
	dq L_constants + 2990
	; L_constants + 3010:
	db T_string	; "="
	dq 1
	db 0x3D
	; L_constants + 3020:
	db T_interned_symbol	; =
	dq L_constants + 3010
	; L_constants + 3029:
	db T_interned_symbol	; __bin-equal-zz
	dq L_constants + 926
	; L_constants + 3038:
	db T_interned_symbol	; __bin-equal-qq
	dq L_constants + 903
	; L_constants + 3047:
	db T_interned_symbol	; __bin-equal-rr
	dq L_constants + 880
	; L_constants + 3056:
	db T_interned_symbol	; __bin-less-than-zz
	dq L_constants + 853
	; L_constants + 3065:
	db T_interned_symbol	; __bin-less-than-qq
	dq L_constants + 826
	; L_constants + 3074:
	db T_interned_symbol	; __bin-less-than-rr
	dq L_constants + 799
	; L_constants + 3083:
	db T_string	; "generic-comparator"
	dq 18
	db 0x67, 0x65, 0x6E, 0x65, 0x72, 0x69, 0x63, 0x2D
	db 0x63, 0x6F, 0x6D, 0x70, 0x61, 0x72, 0x61, 0x74
	db 0x6F, 0x72
	; L_constants + 3110:
	db T_interned_symbol	; generic-comparator
	dq L_constants + 3083
	; L_constants + 3119:
	db T_string	; "all the arguments m...
	dq 33
	db 0x61, 0x6C, 0x6C, 0x20, 0x74, 0x68, 0x65, 0x20
	db 0x61, 0x72, 0x67, 0x75, 0x6D, 0x65, 0x6E, 0x74
	db 0x73, 0x20, 0x6D, 0x75, 0x73, 0x74, 0x20, 0x62
	db 0x65, 0x20, 0x6E, 0x75, 0x6D, 0x62, 0x65, 0x72
	db 0x73
	; L_constants + 3161:
	db T_string	; "char<?"
	dq 6
	db 0x63, 0x68, 0x61, 0x72, 0x3C, 0x3F
	; L_constants + 3176:
	db T_interned_symbol	; char<?
	dq L_constants + 3161
	; L_constants + 3185:
	db T_string	; "char<=?"
	dq 7
	db 0x63, 0x68, 0x61, 0x72, 0x3C, 0x3D, 0x3F
	; L_constants + 3201:
	db T_interned_symbol	; char<=?
	dq L_constants + 3185
	; L_constants + 3210:
	db T_string	; "char=?"
	dq 6
	db 0x63, 0x68, 0x61, 0x72, 0x3D, 0x3F
	; L_constants + 3225:
	db T_interned_symbol	; char=?
	dq L_constants + 3210
	; L_constants + 3234:
	db T_string	; "char>?"
	dq 6
	db 0x63, 0x68, 0x61, 0x72, 0x3E, 0x3F
	; L_constants + 3249:
	db T_interned_symbol	; char>?
	dq L_constants + 3234
	; L_constants + 3258:
	db T_string	; "char>=?"
	dq 7
	db 0x63, 0x68, 0x61, 0x72, 0x3E, 0x3D, 0x3F
	; L_constants + 3274:
	db T_interned_symbol	; char>=?
	dq L_constants + 3258
	; L_constants + 3283:
	db T_interned_symbol	; char->integer
	dq L_constants + 425
	; L_constants + 3292:
	db T_string	; "char-downcase"
	dq 13
	db 0x63, 0x68, 0x61, 0x72, 0x2D, 0x64, 0x6F, 0x77
	db 0x6E, 0x63, 0x61, 0x73, 0x65
	; L_constants + 3314:
	db T_interned_symbol	; char-downcase
	dq L_constants + 3292
	; L_constants + 3323:
	db T_string	; "char-upcase"
	dq 11
	db 0x63, 0x68, 0x61, 0x72, 0x2D, 0x75, 0x70, 0x63
	db 0x61, 0x73, 0x65
	; L_constants + 3343:
	db T_interned_symbol	; char-upcase
	dq L_constants + 3323
	; L_constants + 3352:
	db T_char, 0x41	; #\A
	; L_constants + 3354:
	db T_char, 0x5A	; #\Z
	; L_constants + 3356:
	db T_interned_symbol	; integer->char
	dq L_constants + 447
	; L_constants + 3365:
	db T_char, 0x61	; #\a
	; L_constants + 3367:
	db T_char, 0x7A	; #\z
	; L_constants + 3369:
	db T_string	; "char-ci<?"
	dq 9
	db 0x63, 0x68, 0x61, 0x72, 0x2D, 0x63, 0x69, 0x3C
	db 0x3F
	; L_constants + 3387:
	db T_interned_symbol	; char-ci<?
	dq L_constants + 3369
	; L_constants + 3396:
	db T_string	; "char-ci<=?"
	dq 10
	db 0x63, 0x68, 0x61, 0x72, 0x2D, 0x63, 0x69, 0x3C
	db 0x3D, 0x3F
	; L_constants + 3415:
	db T_interned_symbol	; char-ci<=?
	dq L_constants + 3396
	; L_constants + 3424:
	db T_string	; "char-ci=?"
	dq 9
	db 0x63, 0x68, 0x61, 0x72, 0x2D, 0x63, 0x69, 0x3D
	db 0x3F
	; L_constants + 3442:
	db T_interned_symbol	; char-ci=?
	dq L_constants + 3424
	; L_constants + 3451:
	db T_string	; "char-ci>?"
	dq 9
	db 0x63, 0x68, 0x61, 0x72, 0x2D, 0x63, 0x69, 0x3E
	db 0x3F
	; L_constants + 3469:
	db T_interned_symbol	; char-ci>?
	dq L_constants + 3451
	; L_constants + 3478:
	db T_string	; "char-ci>=?"
	dq 10
	db 0x63, 0x68, 0x61, 0x72, 0x2D, 0x63, 0x69, 0x3E
	db 0x3D, 0x3F
	; L_constants + 3497:
	db T_interned_symbol	; char-ci>=?
	dq L_constants + 3478
	; L_constants + 3506:
	db T_string	; "string-downcase"
	dq 15
	db 0x73, 0x74, 0x72, 0x69, 0x6E, 0x67, 0x2D, 0x64
	db 0x6F, 0x77, 0x6E, 0x63, 0x61, 0x73, 0x65
	; L_constants + 3530:
	db T_interned_symbol	; string-downcase
	dq L_constants + 3506
	; L_constants + 3539:
	db T_string	; "string-upcase"
	dq 13
	db 0x73, 0x74, 0x72, 0x69, 0x6E, 0x67, 0x2D, 0x75
	db 0x70, 0x63, 0x61, 0x73, 0x65
	; L_constants + 3561:
	db T_interned_symbol	; string-upcase
	dq L_constants + 3539
	; L_constants + 3570:
	db T_string	; "list->string"
	dq 12
	db 0x6C, 0x69, 0x73, 0x74, 0x2D, 0x3E, 0x73, 0x74
	db 0x72, 0x69, 0x6E, 0x67
	; L_constants + 3591:
	db T_interned_symbol	; list->string
	dq L_constants + 3570
	; L_constants + 3600:
	db T_string	; "string->list"
	dq 12
	db 0x73, 0x74, 0x72, 0x69, 0x6E, 0x67, 0x2D, 0x3E
	db 0x6C, 0x69, 0x73, 0x74
	; L_constants + 3621:
	db T_interned_symbol	; string->list
	dq L_constants + 3600
	; L_constants + 3630:
	db T_string	; "string<?"
	dq 8
	db 0x73, 0x74, 0x72, 0x69, 0x6E, 0x67, 0x3C, 0x3F
	; L_constants + 3647:
	db T_interned_symbol	; string<?
	dq L_constants + 3630
	; L_constants + 3656:
	db T_string	; "string<=?"
	dq 9
	db 0x73, 0x74, 0x72, 0x69, 0x6E, 0x67, 0x3C, 0x3D
	db 0x3F
	; L_constants + 3674:
	db T_interned_symbol	; string<=?
	dq L_constants + 3656
	; L_constants + 3683:
	db T_string	; "string=?"
	dq 8
	db 0x73, 0x74, 0x72, 0x69, 0x6E, 0x67, 0x3D, 0x3F
	; L_constants + 3700:
	db T_interned_symbol	; string=?
	dq L_constants + 3683
	; L_constants + 3709:
	db T_string	; "string>=?"
	dq 9
	db 0x73, 0x74, 0x72, 0x69, 0x6E, 0x67, 0x3E, 0x3D
	db 0x3F
	; L_constants + 3727:
	db T_interned_symbol	; string>=?
	dq L_constants + 3709
	; L_constants + 3736:
	db T_string	; "string>?"
	dq 8
	db 0x73, 0x74, 0x72, 0x69, 0x6E, 0x67, 0x3E, 0x3F
	; L_constants + 3753:
	db T_interned_symbol	; string>?
	dq L_constants + 3736
	; L_constants + 3762:
	db T_string	; "string-ci<?"
	dq 11
	db 0x73, 0x74, 0x72, 0x69, 0x6E, 0x67, 0x2D, 0x63
	db 0x69, 0x3C, 0x3F
	; L_constants + 3782:
	db T_interned_symbol	; string-ci<?
	dq L_constants + 3762
	; L_constants + 3791:
	db T_string	; "string-ci<=?"
	dq 12
	db 0x73, 0x74, 0x72, 0x69, 0x6E, 0x67, 0x2D, 0x63
	db 0x69, 0x3C, 0x3D, 0x3F
	; L_constants + 3812:
	db T_interned_symbol	; string-ci<=?
	dq L_constants + 3791
	; L_constants + 3821:
	db T_string	; "string-ci=?"
	dq 11
	db 0x73, 0x74, 0x72, 0x69, 0x6E, 0x67, 0x2D, 0x63
	db 0x69, 0x3D, 0x3F
	; L_constants + 3841:
	db T_interned_symbol	; string-ci=?
	dq L_constants + 3821
	; L_constants + 3850:
	db T_string	; "string-ci>=?"
	dq 12
	db 0x73, 0x74, 0x72, 0x69, 0x6E, 0x67, 0x2D, 0x63
	db 0x69, 0x3E, 0x3D, 0x3F
	; L_constants + 3871:
	db T_interned_symbol	; string-ci>=?
	dq L_constants + 3850
	; L_constants + 3880:
	db T_string	; "string-ci>?"
	dq 11
	db 0x73, 0x74, 0x72, 0x69, 0x6E, 0x67, 0x2D, 0x63
	db 0x69, 0x3E, 0x3F
	; L_constants + 3900:
	db T_interned_symbol	; string-ci>?
	dq L_constants + 3880
	; L_constants + 3909:
	db T_interned_symbol	; string-ref
	dq L_constants + 1018
	; L_constants + 3918:
	db T_interned_symbol	; string-length
	dq L_constants + 301
	; L_constants + 3927:
	db T_interned_symbol	; make-vector
	dq L_constants + 1096
	; L_constants + 3936:
	db T_string	; "Usage: (make-vector...
	dq 43
	db 0x55, 0x73, 0x61, 0x67, 0x65, 0x3A, 0x20, 0x28
	db 0x6D, 0x61, 0x6B, 0x65, 0x2D, 0x76, 0x65, 0x63
	db 0x74, 0x6F, 0x72, 0x20, 0x73, 0x69, 0x7A, 0x65
	db 0x20, 0x3F, 0x6F, 0x70, 0x74, 0x69, 0x6F, 0x6E
	db 0x61, 0x6C, 0x2D, 0x64, 0x65, 0x66, 0x61, 0x75
	db 0x6C, 0x74, 0x29
	; L_constants + 3988:
	db T_interned_symbol	; make-string
	dq L_constants + 1116
	; L_constants + 3997:
	db T_string	; "Usage: (make-string...
	dq 43
	db 0x55, 0x73, 0x61, 0x67, 0x65, 0x3A, 0x20, 0x28
	db 0x6D, 0x61, 0x6B, 0x65, 0x2D, 0x73, 0x74, 0x72
	db 0x69, 0x6E, 0x67, 0x20, 0x73, 0x69, 0x7A, 0x65
	db 0x20, 0x3F, 0x6F, 0x70, 0x74, 0x69, 0x6F, 0x6E
	db 0x61, 0x6C, 0x2D, 0x64, 0x65, 0x66, 0x61, 0x75
	db 0x6C, 0x74, 0x29
	; L_constants + 4049:
	db T_string	; "list->vector"
	dq 12
	db 0x6C, 0x69, 0x73, 0x74, 0x2D, 0x3E, 0x76, 0x65
	db 0x63, 0x74, 0x6F, 0x72
	; L_constants + 4070:
	db T_interned_symbol	; list->vector
	dq L_constants + 4049
	; L_constants + 4079:
	db T_interned_symbol	; vector-set!
	dq L_constants + 1056
	; L_constants + 4088:
	db T_interned_symbol	; string-set!
	dq L_constants + 1076
	; L_constants + 4097:
	db T_string	; "vector"
	dq 6
	db 0x76, 0x65, 0x63, 0x74, 0x6F, 0x72
	; L_constants + 4112:
	db T_interned_symbol	; vector
	dq L_constants + 4097
	; L_constants + 4121:
	db T_string	; "vector->list"
	dq 12
	db 0x76, 0x65, 0x63, 0x74, 0x6F, 0x72, 0x2D, 0x3E
	db 0x6C, 0x69, 0x73, 0x74
	; L_constants + 4142:
	db T_interned_symbol	; vector->list
	dq L_constants + 4121
	; L_constants + 4151:
	db T_interned_symbol	; vector-ref
	dq L_constants + 1037
	; L_constants + 4160:
	db T_interned_symbol	; vector-length
	dq L_constants + 323
	; L_constants + 4169:
	db T_string	; "random"
	dq 6
	db 0x72, 0x61, 0x6E, 0x64, 0x6F, 0x6D
	; L_constants + 4184:
	db T_interned_symbol	; random
	dq L_constants + 4169
	; L_constants + 4193:
	db T_interned_symbol	; remainder
	dq L_constants + 966
	; L_constants + 4202:
	db T_interned_symbol	; trng
	dq L_constants + 469
	; L_constants + 4211:
	db T_string	; "positive?"
	dq 9
	db 0x70, 0x6F, 0x73, 0x69, 0x74, 0x69, 0x76, 0x65
	db 0x3F
	; L_constants + 4229:
	db T_interned_symbol	; positive?
	dq L_constants + 4211
	; L_constants + 4238:
	db T_string	; "negative?"
	dq 9
	db 0x6E, 0x65, 0x67, 0x61, 0x74, 0x69, 0x76, 0x65
	db 0x3F
	; L_constants + 4256:
	db T_interned_symbol	; negative?
	dq L_constants + 4238
	; L_constants + 4265:
	db T_string	; "even?"
	dq 5
	db 0x65, 0x76, 0x65, 0x6E, 0x3F
	; L_constants + 4279:
	db T_interned_symbol	; even?
	dq L_constants + 4265
	; L_constants + 4288:
	db T_integer	; 2
	dq 2
	; L_constants + 4297:
	db T_string	; "odd?"
	dq 4
	db 0x6F, 0x64, 0x64, 0x3F
	; L_constants + 4310:
	db T_interned_symbol	; odd?
	dq L_constants + 4297
	; L_constants + 4319:
	db T_string	; "abs"
	dq 3
	db 0x61, 0x62, 0x73
	; L_constants + 4331:
	db T_interned_symbol	; abs
	dq L_constants + 4319
	; L_constants + 4340:
	db T_string	; "equal?"
	dq 6
	db 0x65, 0x71, 0x75, 0x61, 0x6C, 0x3F
	; L_constants + 4355:
	db T_interned_symbol	; equal?
	dq L_constants + 4340
	; L_constants + 4364:
	db T_interned_symbol	; vector?
	dq L_constants + 103
	; L_constants + 4373:
	db T_interned_symbol	; string?
	dq L_constants + 62
	; L_constants + 4382:
	db T_interned_symbol	; number?
	dq L_constants + 187
	; L_constants + 4391:
	db T_interned_symbol	; char?
	dq L_constants + 48
	; L_constants + 4400:
	db T_interned_symbol	; eq?
	dq L_constants + 1174
	; L_constants + 4409:
	db T_string	; "assoc"
	dq 5
	db 0x61, 0x73, 0x73, 0x6F, 0x63
	; L_constants + 4423:
	db T_interned_symbol	; assoc
	dq L_constants + 4409
	; L_constants + 4432:
	db T_string	; "string-append"
	dq 13
	db 0x73, 0x74, 0x72, 0x69, 0x6E, 0x67, 0x2D, 0x61
	db 0x70, 0x70, 0x65, 0x6E, 0x64
	; L_constants + 4454:
	db T_interned_symbol	; string-append
	dq L_constants + 4432
	; L_constants + 4463:
	db T_string	; "vector-append"
	dq 13
	db 0x76, 0x65, 0x63, 0x74, 0x6F, 0x72, 0x2D, 0x61
	db 0x70, 0x70, 0x65, 0x6E, 0x64
	; L_constants + 4485:
	db T_interned_symbol	; vector-append
	dq L_constants + 4463
	; L_constants + 4494:
	db T_string	; "string-reverse"
	dq 14
	db 0x73, 0x74, 0x72, 0x69, 0x6E, 0x67, 0x2D, 0x72
	db 0x65, 0x76, 0x65, 0x72, 0x73, 0x65
	; L_constants + 4517:
	db T_interned_symbol	; string-reverse
	dq L_constants + 4494
	; L_constants + 4526:
	db T_string	; "vector-reverse"
	dq 14
	db 0x76, 0x65, 0x63, 0x74, 0x6F, 0x72, 0x2D, 0x72
	db 0x65, 0x76, 0x65, 0x72, 0x73, 0x65
	; L_constants + 4549:
	db T_interned_symbol	; vector-reverse
	dq L_constants + 4526
	; L_constants + 4558:
	db T_string	; "string-reverse!"
	dq 15
	db 0x73, 0x74, 0x72, 0x69, 0x6E, 0x67, 0x2D, 0x72
	db 0x65, 0x76, 0x65, 0x72, 0x73, 0x65, 0x21
	; L_constants + 4582:
	db T_interned_symbol	; string-reverse!
	dq L_constants + 4558
	; L_constants + 4591:
	db T_string	; "vector-reverse!"
	dq 15
	db 0x76, 0x65, 0x63, 0x74, 0x6F, 0x72, 0x2D, 0x72
	db 0x65, 0x76, 0x65, 0x72, 0x73, 0x65, 0x21
	; L_constants + 4615:
	db T_interned_symbol	; vector-reverse!
	dq L_constants + 4591
	; L_constants + 4624:
	db T_string	; "make-list-thunk"
	dq 15
	db 0x6D, 0x61, 0x6B, 0x65, 0x2D, 0x6C, 0x69, 0x73
	db 0x74, 0x2D, 0x74, 0x68, 0x75, 0x6E, 0x6B
	; L_constants + 4648:
	db T_interned_symbol	; make-list-thunk
	dq L_constants + 4624
	; L_constants + 4657:
	db T_string	; "make-string-thunk"
	dq 17
	db 0x6D, 0x61, 0x6B, 0x65, 0x2D, 0x73, 0x74, 0x72
	db 0x69, 0x6E, 0x67, 0x2D, 0x74, 0x68, 0x75, 0x6E
	db 0x6B
	; L_constants + 4683:
	db T_interned_symbol	; make-string-thunk
	dq L_constants + 4657
	; L_constants + 4692:
	db T_string	; "make-vector-thunk"
	dq 17
	db 0x6D, 0x61, 0x6B, 0x65, 0x2D, 0x76, 0x65, 0x63
	db 0x74, 0x6F, 0x72, 0x2D, 0x74, 0x68, 0x75, 0x6E
	db 0x6B
	; L_constants + 4718:
	db T_interned_symbol	; make-vector-thunk
	dq L_constants + 4692
	; L_constants + 4727:
	db T_string	; "logarithm"
	dq 9
	db 0x6C, 0x6F, 0x67, 0x61, 0x72, 0x69, 0x74, 0x68
	db 0x6D
	; L_constants + 4745:
	db T_interned_symbol	; logarithm
	dq L_constants + 4727
	; L_constants + 4754:
	db T_real	; 1.000000
	dq 1.000000
	; L_constants + 4763:
	db T_string	; "newline"
	dq 7
	db 0x6E, 0x65, 0x77, 0x6C, 0x69, 0x6E, 0x65
	; L_constants + 4779:
	db T_interned_symbol	; newline
	dq L_constants + 4763
	; L_constants + 4788:
	db T_interned_symbol	; write-char
	dq L_constants + 258
	; L_constants + 4797:
	db T_char, 0x0A	; #\newline
	; L_constants + 4799:
	db T_string	; "void"
	dq 4
	db 0x76, 0x6F, 0x69, 0x64
	; L_constants + 4812:
	db T_interned_symbol	; void
	dq L_constants + 4799
	; L_constants + 4821:
	db T_integer	; 4
	dq 4
free_var_0:	; location of *
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 2800

free_var_1:	; location of +
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 2548

free_var_2:	; location of -
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 2732

free_var_3:	; location of /
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 2855

free_var_4:	; location of <
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 2932

free_var_5:	; location of <=
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 2951

free_var_6:	; location of =
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 3010

free_var_7:	; location of >
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 2971

free_var_8:	; location of >=
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 2990

free_var_9:	; location of __bin-add-qq
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 617

free_var_10:	; location of __bin-add-rr
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 533

free_var_11:	; location of __bin-add-zz
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 701

free_var_12:	; location of __bin-apply
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 513

free_var_13:	; location of __bin-div-qq
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 680

free_var_14:	; location of __bin-div-rr
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 596

free_var_15:	; location of __bin-div-zz
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 764

free_var_16:	; location of __bin-equal-qq
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 903

free_var_17:	; location of __bin-equal-rr
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 880

free_var_18:	; location of __bin-equal-zz
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 926

free_var_19:	; location of __bin-less-than-qq
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 826

free_var_20:	; location of __bin-less-than-rr
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 799

free_var_21:	; location of __bin-less-than-zz
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 853

free_var_22:	; location of __bin-mul-qq
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 659

free_var_23:	; location of __bin-mul-rr
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 575

free_var_24:	; location of __bin-mul-zz
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 743

free_var_25:	; location of __bin-sub-qq
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 638

free_var_26:	; location of __bin-sub-rr
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 554

free_var_27:	; location of __bin-sub-zz
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 722

free_var_28:	; location of __bin_integer_to_fraction
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 2621

free_var_29:	; location of __integer-to-fraction
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 1186

free_var_30:	; location of abs
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 4319

free_var_31:	; location of andmap
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 2420

free_var_32:	; location of append
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 2496

free_var_33:	; location of apply
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 2344

free_var_34:	; location of ash
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 1275

free_var_35:	; location of assoc
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 4409

free_var_36:	; location of boolean-false?
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 1389

free_var_37:	; location of boolean-true?
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 1412

free_var_38:	; location of boolean?
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 170

free_var_39:	; location of break
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 1375

free_var_40:	; location of caaaar
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 1791

free_var_41:	; location of caaadr
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 1815

free_var_42:	; location of caaar
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 1607

free_var_43:	; location of caadar
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 1839

free_var_44:	; location of caaddr
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 1863

free_var_45:	; location of caadr
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 1630

free_var_46:	; location of caar
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 1501

free_var_47:	; location of cadaar
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 1887

free_var_48:	; location of cadadr
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 1911

free_var_49:	; location of cadar
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 1653

free_var_50:	; location of caddar
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 1935

free_var_51:	; location of cadddr
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 1959

free_var_52:	; location of caddr
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 1676

free_var_53:	; location of cadr
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 1532

free_var_54:	; location of car
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 277

free_var_55:	; location of cdaaar
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 1983

free_var_56:	; location of cdaadr
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 2007

free_var_57:	; location of cdaar
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 1699

free_var_58:	; location of cdadar
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 2031

free_var_59:	; location of cdaddr
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 2055

free_var_60:	; location of cdadr
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 1722

free_var_61:	; location of cdar
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 1563

free_var_62:	; location of cddaar
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 2079

free_var_63:	; location of cddadr
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 2103

free_var_64:	; location of cddar
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 1745

free_var_65:	; location of cdddar
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 2127

free_var_66:	; location of cddddr
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 2151

free_var_67:	; location of cdddr
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 1768

free_var_68:	; location of cddr
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 1585

free_var_69:	; location of cdr
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 289

free_var_70:	; location of char->integer
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 425

free_var_71:	; location of char-ci<=?
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 3396

free_var_72:	; location of char-ci<?
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 3369

free_var_73:	; location of char-ci=?
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 3424

free_var_74:	; location of char-ci>=?
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 3478

free_var_75:	; location of char-ci>?
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 3451

free_var_76:	; location of char-downcase
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 3292

free_var_77:	; location of char-upcase
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 3323

free_var_78:	; location of char<=?
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 3185

free_var_79:	; location of char<?
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 3161

free_var_80:	; location of char=?
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 3210

free_var_81:	; location of char>=?
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 3258

free_var_82:	; location of char>?
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 3234

free_var_83:	; location of char?
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 48

free_var_84:	; location of collection?
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 203

free_var_85:	; location of cons
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 223

free_var_86:	; location of denominator
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 1154

free_var_87:	; location of display-sexpr
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 236

free_var_88:	; location of eq?
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 1174

free_var_89:	; location of equal?
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 4340

free_var_90:	; location of error
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 785

free_var_91:	; location of even?
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 4265

free_var_92:	; location of exit
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 367

free_var_93:	; location of fact
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 2901

free_var_94:	; location of fold-left
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 2469

free_var_95:	; location of fold-right
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 2520

free_var_96:	; location of fraction->real
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 402

free_var_97:	; location of fraction?
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 152

free_var_98:	; location of frame
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 1361

free_var_99:	; location of gensym
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 1346

free_var_100:	; location of gensym?
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 1330

free_var_101:	; location of integer->char
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 447

free_var_102:	; location of integer->real
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 380

free_var_103:	; location of integer?
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 496

free_var_104:	; location of interned-symbol?
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 78

free_var_105:	; location of length
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 1453

free_var_106:	; location of list
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 2216

free_var_107:	; location of list*
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 2295

free_var_108:	; location of list->string
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 3570

free_var_109:	; location of list->vector
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 4049

free_var_110:	; location of list?
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 2175

free_var_111:	; location of logand
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 1216

free_var_112:	; location of logarithm
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 4727

free_var_113:	; location of lognot
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 1260

free_var_114:	; location of logor
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 1231

free_var_115:	; location of logxor
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 1245

free_var_116:	; location of make-list
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 1468

free_var_117:	; location of make-list-thunk
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 4624

free_var_118:	; location of make-string
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 1116

free_var_119:	; location of make-string-thunk
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 4657

free_var_120:	; location of make-vector
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 1096

free_var_121:	; location of make-vector-thunk
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 4692

free_var_122:	; location of map
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 2399

free_var_123:	; location of negative?
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 4238

free_var_124:	; location of newline
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 4763

free_var_125:	; location of not
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 2229

free_var_126:	; location of null?
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 6

free_var_127:	; location of number?
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 187

free_var_128:	; location of numerator
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 1136

free_var_129:	; location of odd?
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 4297

free_var_130:	; location of ormap
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 2376

free_var_131:	; location of pair?
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 20

free_var_132:	; location of positive?
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 4211

free_var_133:	; location of primitive?
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 1434

free_var_134:	; location of procedure?
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 119

free_var_135:	; location of quotient
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 949

free_var_136:	; location of random
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 4169

free_var_137:	; location of rational?
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 2250

free_var_138:	; location of real
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 2760

free_var_139:	; location of real->integer
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 345

free_var_140:	; location of real?
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 138

free_var_141:	; location of remainder
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 966

free_var_142:	; location of return
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 1486

free_var_143:	; location of reverse
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 2444

free_var_144:	; location of set-car!
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 984

free_var_145:	; location of set-cdr!
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 1001

free_var_146:	; location of string->list
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 3600

free_var_147:	; location of string-append
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 4432

free_var_148:	; location of string-ci<=?
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 3791

free_var_149:	; location of string-ci<?
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 3762

free_var_150:	; location of string-ci=?
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 3821

free_var_151:	; location of string-ci>=?
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 3850

free_var_152:	; location of string-ci>?
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 3880

free_var_153:	; location of string-downcase
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 3506

free_var_154:	; location of string-length
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 301

free_var_155:	; location of string-ref
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 1018

free_var_156:	; location of string-reverse
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 4494

free_var_157:	; location of string-reverse!
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 4558

free_var_158:	; location of string-set!
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 1076

free_var_159:	; location of string-upcase
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 3539

free_var_160:	; location of string<=?
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 3656

free_var_161:	; location of string<?
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 3630

free_var_162:	; location of string=?
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 3683

free_var_163:	; location of string>=?
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 3709

free_var_164:	; location of string>?
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 3736

free_var_165:	; location of string?
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 62

free_var_166:	; location of symbol?
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 1287

free_var_167:	; location of trng
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 469

free_var_168:	; location of uninterned-symbol?
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 1303

free_var_169:	; location of vector
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 4097

free_var_170:	; location of vector->list
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 4121

free_var_171:	; location of vector-append
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 4463

free_var_172:	; location of vector-length
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 323

free_var_173:	; location of vector-ref
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 1037

free_var_174:	; location of vector-reverse
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 4526

free_var_175:	; location of vector-reverse!
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 4591

free_var_176:	; location of vector-set!
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 1056

free_var_177:	; location of vector?
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 103

free_var_178:	; location of void
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 4799

free_var_179:	; location of void?
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 34

free_var_180:	; location of write-char
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 258

free_var_181:	; location of zero?
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 482


extern printf, fprintf, stdout, stderr, fwrite, exit, putchar, getchar
global main
section .text
main:
        enter 0, 0	; building closure for null?
	mov rdi, free_var_126
	mov rsi, L_code_ptr_is_null
	call bind_primitive

	; building closure for pair?
	mov rdi, free_var_131
	mov rsi, L_code_ptr_is_pair
	call bind_primitive

	; building closure for void?
	mov rdi, free_var_179
	mov rsi, L_code_ptr_is_void
	call bind_primitive

	; building closure for char?
	mov rdi, free_var_83
	mov rsi, L_code_ptr_is_char
	call bind_primitive

	; building closure for string?
	mov rdi, free_var_165
	mov rsi, L_code_ptr_is_string
	call bind_primitive

	; building closure for interned-symbol?
	mov rdi, free_var_104
	mov rsi, L_code_ptr_is_symbol
	call bind_primitive

	; building closure for vector?
	mov rdi, free_var_177
	mov rsi, L_code_ptr_is_vector
	call bind_primitive

	; building closure for procedure?
	mov rdi, free_var_134
	mov rsi, L_code_ptr_is_closure
	call bind_primitive

	; building closure for real?
	mov rdi, free_var_140
	mov rsi, L_code_ptr_is_real
	call bind_primitive

	; building closure for fraction?
	mov rdi, free_var_97
	mov rsi, L_code_ptr_is_fraction
	call bind_primitive

	; building closure for boolean?
	mov rdi, free_var_38
	mov rsi, L_code_ptr_is_boolean
	call bind_primitive

	; building closure for number?
	mov rdi, free_var_127
	mov rsi, L_code_ptr_is_number
	call bind_primitive

	; building closure for collection?
	mov rdi, free_var_84
	mov rsi, L_code_ptr_is_collection
	call bind_primitive

	; building closure for cons
	mov rdi, free_var_85
	mov rsi, L_code_ptr_cons
	call bind_primitive

	; building closure for display-sexpr
	mov rdi, free_var_87
	mov rsi, L_code_ptr_display_sexpr
	call bind_primitive

	; building closure for write-char
	mov rdi, free_var_180
	mov rsi, L_code_ptr_write_char
	call bind_primitive

	; building closure for car
	mov rdi, free_var_54
	mov rsi, L_code_ptr_car
	call bind_primitive

	; building closure for cdr
	mov rdi, free_var_69
	mov rsi, L_code_ptr_cdr
	call bind_primitive

	; building closure for string-length
	mov rdi, free_var_154
	mov rsi, L_code_ptr_string_length
	call bind_primitive

	; building closure for vector-length
	mov rdi, free_var_172
	mov rsi, L_code_ptr_vector_length
	call bind_primitive

	; building closure for real->integer
	mov rdi, free_var_139
	mov rsi, L_code_ptr_real_to_integer
	call bind_primitive

	; building closure for exit
	mov rdi, free_var_92
	mov rsi, L_code_ptr_exit
	call bind_primitive

	; building closure for integer->real
	mov rdi, free_var_102
	mov rsi, L_code_ptr_integer_to_real
	call bind_primitive

	; building closure for fraction->real
	mov rdi, free_var_96
	mov rsi, L_code_ptr_fraction_to_real
	call bind_primitive

	; building closure for char->integer
	mov rdi, free_var_70
	mov rsi, L_code_ptr_char_to_integer
	call bind_primitive

	; building closure for integer->char
	mov rdi, free_var_101
	mov rsi, L_code_ptr_integer_to_char
	call bind_primitive

	; building closure for trng
	mov rdi, free_var_167
	mov rsi, L_code_ptr_trng
	call bind_primitive

	; building closure for zero?
	mov rdi, free_var_181
	mov rsi, L_code_ptr_is_zero
	call bind_primitive

	; building closure for integer?
	mov rdi, free_var_103
	mov rsi, L_code_ptr_is_integer
	call bind_primitive

	; building closure for __bin-apply
	mov rdi, free_var_12
	mov rsi, L_code_ptr_bin_apply
	call bind_primitive

	; building closure for __bin-add-rr
	mov rdi, free_var_10
	mov rsi, L_code_ptr_raw_bin_add_rr
	call bind_primitive

	; building closure for __bin-sub-rr
	mov rdi, free_var_26
	mov rsi, L_code_ptr_raw_bin_sub_rr
	call bind_primitive

	; building closure for __bin-mul-rr
	mov rdi, free_var_23
	mov rsi, L_code_ptr_raw_bin_mul_rr
	call bind_primitive

	; building closure for __bin-div-rr
	mov rdi, free_var_14
	mov rsi, L_code_ptr_raw_bin_div_rr
	call bind_primitive

	; building closure for __bin-add-qq
	mov rdi, free_var_9
	mov rsi, L_code_ptr_raw_bin_add_qq
	call bind_primitive

	; building closure for __bin-sub-qq
	mov rdi, free_var_25
	mov rsi, L_code_ptr_raw_bin_sub_qq
	call bind_primitive

	; building closure for __bin-mul-qq
	mov rdi, free_var_22
	mov rsi, L_code_ptr_raw_bin_mul_qq
	call bind_primitive

	; building closure for __bin-div-qq
	mov rdi, free_var_13
	mov rsi, L_code_ptr_raw_bin_div_qq
	call bind_primitive

	; building closure for __bin-add-zz
	mov rdi, free_var_11
	mov rsi, L_code_ptr_raw_bin_add_zz
	call bind_primitive

	; building closure for __bin-sub-zz
	mov rdi, free_var_27
	mov rsi, L_code_ptr_raw_bin_sub_zz
	call bind_primitive

	; building closure for __bin-mul-zz
	mov rdi, free_var_24
	mov rsi, L_code_ptr_raw_bin_mul_zz
	call bind_primitive

	; building closure for __bin-div-zz
	mov rdi, free_var_15
	mov rsi, L_code_ptr_raw_bin_div_zz
	call bind_primitive

	; building closure for error
	mov rdi, free_var_90
	mov rsi, L_code_ptr_error
	call bind_primitive

	; building closure for __bin-less-than-rr
	mov rdi, free_var_20
	mov rsi, L_code_ptr_raw_less_than_rr
	call bind_primitive

	; building closure for __bin-less-than-qq
	mov rdi, free_var_19
	mov rsi, L_code_ptr_raw_less_than_qq
	call bind_primitive

	; building closure for __bin-less-than-zz
	mov rdi, free_var_21
	mov rsi, L_code_ptr_raw_less_than_zz
	call bind_primitive

	; building closure for __bin-equal-rr
	mov rdi, free_var_17
	mov rsi, L_code_ptr_raw_equal_rr
	call bind_primitive

	; building closure for __bin-equal-qq
	mov rdi, free_var_16
	mov rsi, L_code_ptr_raw_equal_qq
	call bind_primitive

	; building closure for __bin-equal-zz
	mov rdi, free_var_18
	mov rsi, L_code_ptr_raw_equal_zz
	call bind_primitive

	; building closure for quotient
	mov rdi, free_var_135
	mov rsi, L_code_ptr_quotient
	call bind_primitive

	; building closure for remainder
	mov rdi, free_var_141
	mov rsi, L_code_ptr_remainder
	call bind_primitive

	; building closure for set-car!
	mov rdi, free_var_144
	mov rsi, L_code_ptr_set_car
	call bind_primitive

	; building closure for set-cdr!
	mov rdi, free_var_145
	mov rsi, L_code_ptr_set_cdr
	call bind_primitive

	; building closure for string-ref
	mov rdi, free_var_155
	mov rsi, L_code_ptr_string_ref
	call bind_primitive

	; building closure for vector-ref
	mov rdi, free_var_173
	mov rsi, L_code_ptr_vector_ref
	call bind_primitive

	; building closure for vector-set!
	mov rdi, free_var_176
	mov rsi, L_code_ptr_vector_set
	call bind_primitive

	; building closure for string-set!
	mov rdi, free_var_158
	mov rsi, L_code_ptr_string_set
	call bind_primitive

	; building closure for make-vector
	mov rdi, free_var_120
	mov rsi, L_code_ptr_make_vector
	call bind_primitive

	; building closure for make-string
	mov rdi, free_var_118
	mov rsi, L_code_ptr_make_string
	call bind_primitive

	; building closure for numerator
	mov rdi, free_var_128
	mov rsi, L_code_ptr_numerator
	call bind_primitive

	; building closure for denominator
	mov rdi, free_var_86
	mov rsi, L_code_ptr_denominator
	call bind_primitive

	; building closure for eq?
	mov rdi, free_var_88
	mov rsi, L_code_ptr_is_eq
	call bind_primitive

	; building closure for __integer-to-fraction
	mov rdi, free_var_29
	mov rsi, L_code_ptr_integer_to_fraction
	call bind_primitive

	; building closure for logand
	mov rdi, free_var_111
	mov rsi, L_code_ptr_logand
	call bind_primitive

	; building closure for logor
	mov rdi, free_var_114
	mov rsi, L_code_ptr_logor
	call bind_primitive

	; building closure for logxor
	mov rdi, free_var_115
	mov rsi, L_code_ptr_logxor
	call bind_primitive

	; building closure for lognot
	mov rdi, free_var_113
	mov rsi, L_code_ptr_lognot
	call bind_primitive

	; building closure for ash
	mov rdi, free_var_34
	mov rsi, L_code_ptr_ash
	call bind_primitive

	; building closure for symbol?
	mov rdi, free_var_166
	mov rsi, L_code_ptr_is_symbol
	call bind_primitive

	; building closure for uninterned-symbol?
	mov rdi, free_var_168
	mov rsi, L_code_ptr_is_uninterned_symbol
	call bind_primitive

	; building closure for gensym?
	mov rdi, free_var_100
	mov rsi, L_code_ptr_is_uninterned_symbol
	call bind_primitive

	; building closure for interned-symbol?
	mov rdi, free_var_104
	mov rsi, L_code_ptr_is_interned_symbol
	call bind_primitive

	; building closure for gensym
	mov rdi, free_var_99
	mov rsi, L_code_ptr_gensym
	call bind_primitive

	; building closure for frame
	mov rdi, free_var_98
	mov rsi, L_code_ptr_frame
	call bind_primitive

	; building closure for break
	mov rdi, free_var_39
	mov rsi, L_code_ptr_break
	call bind_primitive

	; building closure for boolean-false?
	mov rdi, free_var_36
	mov rsi, L_code_ptr_is_boolean_false
	call bind_primitive

	; building closure for boolean-true?
	mov rdi, free_var_37
	mov rsi, L_code_ptr_is_boolean_true
	call bind_primitive

	; building closure for primitive?
	mov rdi, free_var_133
	mov rsi, L_code_ptr_is_primitive
	call bind_primitive

	; building closure for length
	mov rdi, free_var_105
	mov rsi, L_code_ptr_length
	call bind_primitive

	; building closure for make-list
	mov rdi, free_var_116
	mov rsi, L_code_ptr_make_list
	call bind_primitive

	; building closure for return
	mov rdi, free_var_142
	mov rsi, L_code_ptr_return
	call bind_primitive

	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 0	; new rib
	call malloc
	push rax
	mov rdi, 8 * 1	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_03a4:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_03a4
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_03a4
.L_lambda_simple_env_end_03a4:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_03a4:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_03a4
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_03a4
.L_lambda_simple_params_end_03a4:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_03a4
	jmp .L_lambda_simple_end_03a4
.L_lambda_simple_code_03a4:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_03a4
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_03a4:
	enter 0, 0
	; preparing a tail-call
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param x
	push rax
	push 1	; arg count
	mov rax, qword [free_var_54]	; free var car
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 1	; arg count
	mov rax, qword [free_var_54]	; free var car
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; old return address
	push qword [rbp]	; old frame-pointer
	mov rcx, 5
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8]
.L_tc_recycle_frame_loop_04bc:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_04bc
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8
	sub rdx, 8
	jmp .L_tc_recycle_frame_loop_04bc
.L_tc_recycle_frame_done_04bc:
	lea rsp, [rbx + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_03a4:	; new closure is in rax
	mov qword [free_var_46], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void

	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 0	; new rib
	call malloc
	push rax
	mov rdi, 8 * 1	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_03a5:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_03a5
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_03a5
.L_lambda_simple_env_end_03a5:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_03a5:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_03a5
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_03a5
.L_lambda_simple_params_end_03a5:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_03a5
	jmp .L_lambda_simple_end_03a5
.L_lambda_simple_code_03a5:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_03a5
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_03a5:
	enter 0, 0
	; preparing a tail-call
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param x
	push rax
	push 1	; arg count
	mov rax, qword [free_var_69]	; free var cdr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 1	; arg count
	mov rax, qword [free_var_54]	; free var car
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; old return address
	push qword [rbp]	; old frame-pointer
	mov rcx, 5
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8]
.L_tc_recycle_frame_loop_04bd:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_04bd
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8
	sub rdx, 8
	jmp .L_tc_recycle_frame_loop_04bd
.L_tc_recycle_frame_done_04bd:
	lea rsp, [rbx + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_03a5:	; new closure is in rax
	mov qword [free_var_53], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void

	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 0	; new rib
	call malloc
	push rax
	mov rdi, 8 * 1	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_03a6:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_03a6
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_03a6
.L_lambda_simple_env_end_03a6:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_03a6:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_03a6
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_03a6
.L_lambda_simple_params_end_03a6:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_03a6
	jmp .L_lambda_simple_end_03a6
.L_lambda_simple_code_03a6:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_03a6
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_03a6:
	enter 0, 0
	; preparing a tail-call
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param x
	push rax
	push 1	; arg count
	mov rax, qword [free_var_54]	; free var car
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 1	; arg count
	mov rax, qword [free_var_69]	; free var cdr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; old return address
	push qword [rbp]	; old frame-pointer
	mov rcx, 5
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8]
.L_tc_recycle_frame_loop_04be:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_04be
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8
	sub rdx, 8
	jmp .L_tc_recycle_frame_loop_04be
.L_tc_recycle_frame_done_04be:
	lea rsp, [rbx + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_03a6:	; new closure is in rax
	mov qword [free_var_61], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void

	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 0	; new rib
	call malloc
	push rax
	mov rdi, 8 * 1	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_03a7:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_03a7
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_03a7
.L_lambda_simple_env_end_03a7:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_03a7:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_03a7
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_03a7
.L_lambda_simple_params_end_03a7:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_03a7
	jmp .L_lambda_simple_end_03a7
.L_lambda_simple_code_03a7:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_03a7
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_03a7:
	enter 0, 0
	; preparing a tail-call
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param x
	push rax
	push 1	; arg count
	mov rax, qword [free_var_69]	; free var cdr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 1	; arg count
	mov rax, qword [free_var_69]	; free var cdr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; old return address
	push qword [rbp]	; old frame-pointer
	mov rcx, 5
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8]
.L_tc_recycle_frame_loop_04bf:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_04bf
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8
	sub rdx, 8
	jmp .L_tc_recycle_frame_loop_04bf
.L_tc_recycle_frame_done_04bf:
	lea rsp, [rbx + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_03a7:	; new closure is in rax
	mov qword [free_var_68], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void

	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 0	; new rib
	call malloc
	push rax
	mov rdi, 8 * 1	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_03a8:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_03a8
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_03a8
.L_lambda_simple_env_end_03a8:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_03a8:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_03a8
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_03a8
.L_lambda_simple_params_end_03a8:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_03a8
	jmp .L_lambda_simple_end_03a8
.L_lambda_simple_code_03a8:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_03a8
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_03a8:
	enter 0, 0
	; preparing a tail-call
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param x
	push rax
	push 1	; arg count
	mov rax, qword [free_var_46]	; free var caar
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 1	; arg count
	mov rax, qword [free_var_54]	; free var car
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; old return address
	push qword [rbp]	; old frame-pointer
	mov rcx, 5
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8]
.L_tc_recycle_frame_loop_04c0:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_04c0
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8
	sub rdx, 8
	jmp .L_tc_recycle_frame_loop_04c0
.L_tc_recycle_frame_done_04c0:
	lea rsp, [rbx + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_03a8:	; new closure is in rax
	mov qword [free_var_42], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void

	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 0	; new rib
	call malloc
	push rax
	mov rdi, 8 * 1	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_03a9:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_03a9
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_03a9
.L_lambda_simple_env_end_03a9:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_03a9:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_03a9
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_03a9
.L_lambda_simple_params_end_03a9:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_03a9
	jmp .L_lambda_simple_end_03a9
.L_lambda_simple_code_03a9:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_03a9
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_03a9:
	enter 0, 0
	; preparing a tail-call
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param x
	push rax
	push 1	; arg count
	mov rax, qword [free_var_53]	; free var cadr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 1	; arg count
	mov rax, qword [free_var_54]	; free var car
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; old return address
	push qword [rbp]	; old frame-pointer
	mov rcx, 5
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8]
.L_tc_recycle_frame_loop_04c1:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_04c1
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8
	sub rdx, 8
	jmp .L_tc_recycle_frame_loop_04c1
.L_tc_recycle_frame_done_04c1:
	lea rsp, [rbx + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_03a9:	; new closure is in rax
	mov qword [free_var_45], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void

	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 0	; new rib
	call malloc
	push rax
	mov rdi, 8 * 1	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_03aa:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_03aa
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_03aa
.L_lambda_simple_env_end_03aa:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_03aa:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_03aa
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_03aa
.L_lambda_simple_params_end_03aa:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_03aa
	jmp .L_lambda_simple_end_03aa
.L_lambda_simple_code_03aa:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_03aa
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_03aa:
	enter 0, 0
	; preparing a tail-call
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param x
	push rax
	push 1	; arg count
	mov rax, qword [free_var_61]	; free var cdar
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 1	; arg count
	mov rax, qword [free_var_54]	; free var car
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; old return address
	push qword [rbp]	; old frame-pointer
	mov rcx, 5
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8]
.L_tc_recycle_frame_loop_04c2:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_04c2
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8
	sub rdx, 8
	jmp .L_tc_recycle_frame_loop_04c2
.L_tc_recycle_frame_done_04c2:
	lea rsp, [rbx + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_03aa:	; new closure is in rax
	mov qword [free_var_49], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void

	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 0	; new rib
	call malloc
	push rax
	mov rdi, 8 * 1	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_03ab:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_03ab
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_03ab
.L_lambda_simple_env_end_03ab:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_03ab:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_03ab
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_03ab
.L_lambda_simple_params_end_03ab:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_03ab
	jmp .L_lambda_simple_end_03ab
.L_lambda_simple_code_03ab:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_03ab
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_03ab:
	enter 0, 0
	; preparing a tail-call
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param x
	push rax
	push 1	; arg count
	mov rax, qword [free_var_68]	; free var cddr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 1	; arg count
	mov rax, qword [free_var_54]	; free var car
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; old return address
	push qword [rbp]	; old frame-pointer
	mov rcx, 5
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8]
.L_tc_recycle_frame_loop_04c3:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_04c3
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8
	sub rdx, 8
	jmp .L_tc_recycle_frame_loop_04c3
.L_tc_recycle_frame_done_04c3:
	lea rsp, [rbx + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_03ab:	; new closure is in rax
	mov qword [free_var_52], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void

	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 0	; new rib
	call malloc
	push rax
	mov rdi, 8 * 1	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_03ac:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_03ac
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_03ac
.L_lambda_simple_env_end_03ac:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_03ac:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_03ac
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_03ac
.L_lambda_simple_params_end_03ac:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_03ac
	jmp .L_lambda_simple_end_03ac
.L_lambda_simple_code_03ac:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_03ac
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_03ac:
	enter 0, 0
	; preparing a tail-call
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param x
	push rax
	push 1	; arg count
	mov rax, qword [free_var_46]	; free var caar
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 1	; arg count
	mov rax, qword [free_var_69]	; free var cdr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; old return address
	push qword [rbp]	; old frame-pointer
	mov rcx, 5
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8]
.L_tc_recycle_frame_loop_04c4:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_04c4
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8
	sub rdx, 8
	jmp .L_tc_recycle_frame_loop_04c4
.L_tc_recycle_frame_done_04c4:
	lea rsp, [rbx + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_03ac:	; new closure is in rax
	mov qword [free_var_57], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void

	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 0	; new rib
	call malloc
	push rax
	mov rdi, 8 * 1	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_03ad:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_03ad
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_03ad
.L_lambda_simple_env_end_03ad:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_03ad:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_03ad
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_03ad
.L_lambda_simple_params_end_03ad:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_03ad
	jmp .L_lambda_simple_end_03ad
.L_lambda_simple_code_03ad:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_03ad
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_03ad:
	enter 0, 0
	; preparing a tail-call
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param x
	push rax
	push 1	; arg count
	mov rax, qword [free_var_53]	; free var cadr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 1	; arg count
	mov rax, qword [free_var_69]	; free var cdr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; old return address
	push qword [rbp]	; old frame-pointer
	mov rcx, 5
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8]
.L_tc_recycle_frame_loop_04c5:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_04c5
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8
	sub rdx, 8
	jmp .L_tc_recycle_frame_loop_04c5
.L_tc_recycle_frame_done_04c5:
	lea rsp, [rbx + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_03ad:	; new closure is in rax
	mov qword [free_var_60], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void

	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 0	; new rib
	call malloc
	push rax
	mov rdi, 8 * 1	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_03ae:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_03ae
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_03ae
.L_lambda_simple_env_end_03ae:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_03ae:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_03ae
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_03ae
.L_lambda_simple_params_end_03ae:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_03ae
	jmp .L_lambda_simple_end_03ae
.L_lambda_simple_code_03ae:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_03ae
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_03ae:
	enter 0, 0
	; preparing a tail-call
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param x
	push rax
	push 1	; arg count
	mov rax, qword [free_var_61]	; free var cdar
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 1	; arg count
	mov rax, qword [free_var_69]	; free var cdr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; old return address
	push qword [rbp]	; old frame-pointer
	mov rcx, 5
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8]
.L_tc_recycle_frame_loop_04c6:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_04c6
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8
	sub rdx, 8
	jmp .L_tc_recycle_frame_loop_04c6
.L_tc_recycle_frame_done_04c6:
	lea rsp, [rbx + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_03ae:	; new closure is in rax
	mov qword [free_var_64], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void

	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 0	; new rib
	call malloc
	push rax
	mov rdi, 8 * 1	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_03af:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_03af
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_03af
.L_lambda_simple_env_end_03af:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_03af:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_03af
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_03af
.L_lambda_simple_params_end_03af:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_03af
	jmp .L_lambda_simple_end_03af
.L_lambda_simple_code_03af:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_03af
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_03af:
	enter 0, 0
	; preparing a tail-call
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param x
	push rax
	push 1	; arg count
	mov rax, qword [free_var_68]	; free var cddr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 1	; arg count
	mov rax, qword [free_var_69]	; free var cdr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; old return address
	push qword [rbp]	; old frame-pointer
	mov rcx, 5
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8]
.L_tc_recycle_frame_loop_04c7:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_04c7
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8
	sub rdx, 8
	jmp .L_tc_recycle_frame_loop_04c7
.L_tc_recycle_frame_done_04c7:
	lea rsp, [rbx + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_03af:	; new closure is in rax
	mov qword [free_var_67], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void

	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 0	; new rib
	call malloc
	push rax
	mov rdi, 8 * 1	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_03b0:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_03b0
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_03b0
.L_lambda_simple_env_end_03b0:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_03b0:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_03b0
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_03b0
.L_lambda_simple_params_end_03b0:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_03b0
	jmp .L_lambda_simple_end_03b0
.L_lambda_simple_code_03b0:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_03b0
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_03b0:
	enter 0, 0
	; preparing a tail-call
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param x
	push rax
	push 1	; arg count
	mov rax, qword [free_var_46]	; free var caar
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 1	; arg count
	mov rax, qword [free_var_46]	; free var caar
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; old return address
	push qword [rbp]	; old frame-pointer
	mov rcx, 5
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8]
.L_tc_recycle_frame_loop_04c8:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_04c8
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8
	sub rdx, 8
	jmp .L_tc_recycle_frame_loop_04c8
.L_tc_recycle_frame_done_04c8:
	lea rsp, [rbx + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_03b0:	; new closure is in rax
	mov qword [free_var_40], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void

	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 0	; new rib
	call malloc
	push rax
	mov rdi, 8 * 1	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_03b1:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_03b1
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_03b1
.L_lambda_simple_env_end_03b1:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_03b1:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_03b1
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_03b1
.L_lambda_simple_params_end_03b1:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_03b1
	jmp .L_lambda_simple_end_03b1
.L_lambda_simple_code_03b1:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_03b1
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_03b1:
	enter 0, 0
	; preparing a tail-call
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param x
	push rax
	push 1	; arg count
	mov rax, qword [free_var_53]	; free var cadr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 1	; arg count
	mov rax, qword [free_var_46]	; free var caar
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; old return address
	push qword [rbp]	; old frame-pointer
	mov rcx, 5
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8]
.L_tc_recycle_frame_loop_04c9:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_04c9
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8
	sub rdx, 8
	jmp .L_tc_recycle_frame_loop_04c9
.L_tc_recycle_frame_done_04c9:
	lea rsp, [rbx + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_03b1:	; new closure is in rax
	mov qword [free_var_41], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void

	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 0	; new rib
	call malloc
	push rax
	mov rdi, 8 * 1	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_03b2:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_03b2
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_03b2
.L_lambda_simple_env_end_03b2:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_03b2:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_03b2
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_03b2
.L_lambda_simple_params_end_03b2:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_03b2
	jmp .L_lambda_simple_end_03b2
.L_lambda_simple_code_03b2:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_03b2
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_03b2:
	enter 0, 0
	; preparing a tail-call
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param x
	push rax
	push 1	; arg count
	mov rax, qword [free_var_61]	; free var cdar
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 1	; arg count
	mov rax, qword [free_var_46]	; free var caar
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; old return address
	push qword [rbp]	; old frame-pointer
	mov rcx, 5
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8]
.L_tc_recycle_frame_loop_04ca:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_04ca
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8
	sub rdx, 8
	jmp .L_tc_recycle_frame_loop_04ca
.L_tc_recycle_frame_done_04ca:
	lea rsp, [rbx + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_03b2:	; new closure is in rax
	mov qword [free_var_43], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void

	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 0	; new rib
	call malloc
	push rax
	mov rdi, 8 * 1	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_03b3:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_03b3
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_03b3
.L_lambda_simple_env_end_03b3:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_03b3:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_03b3
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_03b3
.L_lambda_simple_params_end_03b3:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_03b3
	jmp .L_lambda_simple_end_03b3
.L_lambda_simple_code_03b3:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_03b3
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_03b3:
	enter 0, 0
	; preparing a tail-call
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param x
	push rax
	push 1	; arg count
	mov rax, qword [free_var_68]	; free var cddr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 1	; arg count
	mov rax, qword [free_var_46]	; free var caar
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; old return address
	push qword [rbp]	; old frame-pointer
	mov rcx, 5
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8]
.L_tc_recycle_frame_loop_04cb:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_04cb
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8
	sub rdx, 8
	jmp .L_tc_recycle_frame_loop_04cb
.L_tc_recycle_frame_done_04cb:
	lea rsp, [rbx + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_03b3:	; new closure is in rax
	mov qword [free_var_44], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void

	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 0	; new rib
	call malloc
	push rax
	mov rdi, 8 * 1	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_03b4:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_03b4
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_03b4
.L_lambda_simple_env_end_03b4:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_03b4:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_03b4
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_03b4
.L_lambda_simple_params_end_03b4:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_03b4
	jmp .L_lambda_simple_end_03b4
.L_lambda_simple_code_03b4:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_03b4
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_03b4:
	enter 0, 0
	; preparing a tail-call
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param x
	push rax
	push 1	; arg count
	mov rax, qword [free_var_46]	; free var caar
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 1	; arg count
	mov rax, qword [free_var_53]	; free var cadr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; old return address
	push qword [rbp]	; old frame-pointer
	mov rcx, 5
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8]
.L_tc_recycle_frame_loop_04cc:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_04cc
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8
	sub rdx, 8
	jmp .L_tc_recycle_frame_loop_04cc
.L_tc_recycle_frame_done_04cc:
	lea rsp, [rbx + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_03b4:	; new closure is in rax
	mov qword [free_var_47], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void

	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 0	; new rib
	call malloc
	push rax
	mov rdi, 8 * 1	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_03b5:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_03b5
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_03b5
.L_lambda_simple_env_end_03b5:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_03b5:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_03b5
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_03b5
.L_lambda_simple_params_end_03b5:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_03b5
	jmp .L_lambda_simple_end_03b5
.L_lambda_simple_code_03b5:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_03b5
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_03b5:
	enter 0, 0
	; preparing a tail-call
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param x
	push rax
	push 1	; arg count
	mov rax, qword [free_var_53]	; free var cadr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 1	; arg count
	mov rax, qword [free_var_53]	; free var cadr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; old return address
	push qword [rbp]	; old frame-pointer
	mov rcx, 5
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8]
.L_tc_recycle_frame_loop_04cd:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_04cd
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8
	sub rdx, 8
	jmp .L_tc_recycle_frame_loop_04cd
.L_tc_recycle_frame_done_04cd:
	lea rsp, [rbx + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_03b5:	; new closure is in rax
	mov qword [free_var_48], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void

	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 0	; new rib
	call malloc
	push rax
	mov rdi, 8 * 1	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_03b6:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_03b6
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_03b6
.L_lambda_simple_env_end_03b6:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_03b6:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_03b6
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_03b6
.L_lambda_simple_params_end_03b6:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_03b6
	jmp .L_lambda_simple_end_03b6
.L_lambda_simple_code_03b6:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_03b6
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_03b6:
	enter 0, 0
	; preparing a tail-call
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param x
	push rax
	push 1	; arg count
	mov rax, qword [free_var_61]	; free var cdar
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 1	; arg count
	mov rax, qword [free_var_53]	; free var cadr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; old return address
	push qword [rbp]	; old frame-pointer
	mov rcx, 5
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8]
.L_tc_recycle_frame_loop_04ce:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_04ce
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8
	sub rdx, 8
	jmp .L_tc_recycle_frame_loop_04ce
.L_tc_recycle_frame_done_04ce:
	lea rsp, [rbx + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_03b6:	; new closure is in rax
	mov qword [free_var_50], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void

	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 0	; new rib
	call malloc
	push rax
	mov rdi, 8 * 1	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_03b7:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_03b7
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_03b7
.L_lambda_simple_env_end_03b7:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_03b7:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_03b7
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_03b7
.L_lambda_simple_params_end_03b7:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_03b7
	jmp .L_lambda_simple_end_03b7
.L_lambda_simple_code_03b7:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_03b7
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_03b7:
	enter 0, 0
	; preparing a tail-call
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param x
	push rax
	push 1	; arg count
	mov rax, qword [free_var_68]	; free var cddr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 1	; arg count
	mov rax, qword [free_var_53]	; free var cadr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; old return address
	push qword [rbp]	; old frame-pointer
	mov rcx, 5
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8]
.L_tc_recycle_frame_loop_04cf:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_04cf
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8
	sub rdx, 8
	jmp .L_tc_recycle_frame_loop_04cf
.L_tc_recycle_frame_done_04cf:
	lea rsp, [rbx + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_03b7:	; new closure is in rax
	mov qword [free_var_51], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void

	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 0	; new rib
	call malloc
	push rax
	mov rdi, 8 * 1	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_03b8:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_03b8
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_03b8
.L_lambda_simple_env_end_03b8:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_03b8:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_03b8
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_03b8
.L_lambda_simple_params_end_03b8:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_03b8
	jmp .L_lambda_simple_end_03b8
.L_lambda_simple_code_03b8:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_03b8
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_03b8:
	enter 0, 0
	; preparing a tail-call
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param x
	push rax
	push 1	; arg count
	mov rax, qword [free_var_46]	; free var caar
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 1	; arg count
	mov rax, qword [free_var_61]	; free var cdar
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; old return address
	push qword [rbp]	; old frame-pointer
	mov rcx, 5
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8]
.L_tc_recycle_frame_loop_04d0:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_04d0
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8
	sub rdx, 8
	jmp .L_tc_recycle_frame_loop_04d0
.L_tc_recycle_frame_done_04d0:
	lea rsp, [rbx + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_03b8:	; new closure is in rax
	mov qword [free_var_55], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void

	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 0	; new rib
	call malloc
	push rax
	mov rdi, 8 * 1	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_03b9:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_03b9
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_03b9
.L_lambda_simple_env_end_03b9:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_03b9:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_03b9
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_03b9
.L_lambda_simple_params_end_03b9:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_03b9
	jmp .L_lambda_simple_end_03b9
.L_lambda_simple_code_03b9:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_03b9
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_03b9:
	enter 0, 0
	; preparing a tail-call
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param x
	push rax
	push 1	; arg count
	mov rax, qword [free_var_53]	; free var cadr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 1	; arg count
	mov rax, qword [free_var_61]	; free var cdar
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; old return address
	push qword [rbp]	; old frame-pointer
	mov rcx, 5
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8]
.L_tc_recycle_frame_loop_04d1:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_04d1
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8
	sub rdx, 8
	jmp .L_tc_recycle_frame_loop_04d1
.L_tc_recycle_frame_done_04d1:
	lea rsp, [rbx + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_03b9:	; new closure is in rax
	mov qword [free_var_56], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void

	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 0	; new rib
	call malloc
	push rax
	mov rdi, 8 * 1	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_03ba:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_03ba
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_03ba
.L_lambda_simple_env_end_03ba:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_03ba:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_03ba
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_03ba
.L_lambda_simple_params_end_03ba:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_03ba
	jmp .L_lambda_simple_end_03ba
.L_lambda_simple_code_03ba:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_03ba
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_03ba:
	enter 0, 0
	; preparing a tail-call
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param x
	push rax
	push 1	; arg count
	mov rax, qword [free_var_61]	; free var cdar
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 1	; arg count
	mov rax, qword [free_var_61]	; free var cdar
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; old return address
	push qword [rbp]	; old frame-pointer
	mov rcx, 5
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8]
.L_tc_recycle_frame_loop_04d2:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_04d2
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8
	sub rdx, 8
	jmp .L_tc_recycle_frame_loop_04d2
.L_tc_recycle_frame_done_04d2:
	lea rsp, [rbx + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_03ba:	; new closure is in rax
	mov qword [free_var_58], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void

	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 0	; new rib
	call malloc
	push rax
	mov rdi, 8 * 1	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_03bb:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_03bb
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_03bb
.L_lambda_simple_env_end_03bb:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_03bb:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_03bb
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_03bb
.L_lambda_simple_params_end_03bb:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_03bb
	jmp .L_lambda_simple_end_03bb
.L_lambda_simple_code_03bb:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_03bb
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_03bb:
	enter 0, 0
	; preparing a tail-call
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param x
	push rax
	push 1	; arg count
	mov rax, qword [free_var_68]	; free var cddr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 1	; arg count
	mov rax, qword [free_var_61]	; free var cdar
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; old return address
	push qword [rbp]	; old frame-pointer
	mov rcx, 5
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8]
.L_tc_recycle_frame_loop_04d3:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_04d3
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8
	sub rdx, 8
	jmp .L_tc_recycle_frame_loop_04d3
.L_tc_recycle_frame_done_04d3:
	lea rsp, [rbx + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_03bb:	; new closure is in rax
	mov qword [free_var_59], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void

	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 0	; new rib
	call malloc
	push rax
	mov rdi, 8 * 1	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_03bc:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_03bc
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_03bc
.L_lambda_simple_env_end_03bc:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_03bc:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_03bc
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_03bc
.L_lambda_simple_params_end_03bc:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_03bc
	jmp .L_lambda_simple_end_03bc
.L_lambda_simple_code_03bc:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_03bc
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_03bc:
	enter 0, 0
	; preparing a tail-call
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param x
	push rax
	push 1	; arg count
	mov rax, qword [free_var_46]	; free var caar
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 1	; arg count
	mov rax, qword [free_var_68]	; free var cddr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; old return address
	push qword [rbp]	; old frame-pointer
	mov rcx, 5
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8]
.L_tc_recycle_frame_loop_04d4:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_04d4
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8
	sub rdx, 8
	jmp .L_tc_recycle_frame_loop_04d4
.L_tc_recycle_frame_done_04d4:
	lea rsp, [rbx + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_03bc:	; new closure is in rax
	mov qword [free_var_62], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void

	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 0	; new rib
	call malloc
	push rax
	mov rdi, 8 * 1	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_03bd:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_03bd
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_03bd
.L_lambda_simple_env_end_03bd:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_03bd:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_03bd
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_03bd
.L_lambda_simple_params_end_03bd:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_03bd
	jmp .L_lambda_simple_end_03bd
.L_lambda_simple_code_03bd:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_03bd
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_03bd:
	enter 0, 0
	; preparing a tail-call
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param x
	push rax
	push 1	; arg count
	mov rax, qword [free_var_53]	; free var cadr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 1	; arg count
	mov rax, qword [free_var_68]	; free var cddr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; old return address
	push qword [rbp]	; old frame-pointer
	mov rcx, 5
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8]
.L_tc_recycle_frame_loop_04d5:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_04d5
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8
	sub rdx, 8
	jmp .L_tc_recycle_frame_loop_04d5
.L_tc_recycle_frame_done_04d5:
	lea rsp, [rbx + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_03bd:	; new closure is in rax
	mov qword [free_var_63], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void

	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 0	; new rib
	call malloc
	push rax
	mov rdi, 8 * 1	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_03be:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_03be
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_03be
.L_lambda_simple_env_end_03be:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_03be:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_03be
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_03be
.L_lambda_simple_params_end_03be:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_03be
	jmp .L_lambda_simple_end_03be
.L_lambda_simple_code_03be:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_03be
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_03be:
	enter 0, 0
	; preparing a tail-call
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param x
	push rax
	push 1	; arg count
	mov rax, qword [free_var_61]	; free var cdar
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 1	; arg count
	mov rax, qword [free_var_68]	; free var cddr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; old return address
	push qword [rbp]	; old frame-pointer
	mov rcx, 5
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8]
.L_tc_recycle_frame_loop_04d6:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_04d6
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8
	sub rdx, 8
	jmp .L_tc_recycle_frame_loop_04d6
.L_tc_recycle_frame_done_04d6:
	lea rsp, [rbx + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_03be:	; new closure is in rax
	mov qword [free_var_65], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void

	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 0	; new rib
	call malloc
	push rax
	mov rdi, 8 * 1	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_03bf:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_03bf
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_03bf
.L_lambda_simple_env_end_03bf:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_03bf:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_03bf
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_03bf
.L_lambda_simple_params_end_03bf:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_03bf
	jmp .L_lambda_simple_end_03bf
.L_lambda_simple_code_03bf:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_03bf
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_03bf:
	enter 0, 0
	; preparing a tail-call
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param x
	push rax
	push 1	; arg count
	mov rax, qword [free_var_68]	; free var cddr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 1	; arg count
	mov rax, qword [free_var_68]	; free var cddr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; old return address
	push qword [rbp]	; old frame-pointer
	mov rcx, 5
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8]
.L_tc_recycle_frame_loop_04d7:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_04d7
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8
	sub rdx, 8
	jmp .L_tc_recycle_frame_loop_04d7
.L_tc_recycle_frame_done_04d7:
	lea rsp, [rbx + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_03bf:	; new closure is in rax
	mov qword [free_var_66], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void

	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 0	; new rib
	call malloc
	push rax
	mov rdi, 8 * 1	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_03c0:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_03c0
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_03c0
.L_lambda_simple_env_end_03c0:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_03c0:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_03c0
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_03c0
.L_lambda_simple_params_end_03c0:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_03c0
	jmp .L_lambda_simple_end_03c0
.L_lambda_simple_code_03c0:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_03c0
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_03c0:
	enter 0, 0
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param e
	push rax
	push 1	; arg count
	mov rax, qword [free_var_126]	; free var null?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	jne .L_or_end_0047
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param e
	push rax
	push 1	; arg count
	mov rax, qword [free_var_131]	; free var pair?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_02ab
	; preparing a tail-call
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param e
	push rax
	push 1	; arg count
	mov rax, qword [free_var_69]	; free var cdr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 1	; arg count
	mov rax, qword [free_var_110]	; free var list?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; old return address
	push qword [rbp]	; old frame-pointer
	mov rcx, 5
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8]
.L_tc_recycle_frame_loop_04d8:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_04d8
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8
	sub rdx, 8
	jmp .L_tc_recycle_frame_loop_04d8
.L_tc_recycle_frame_done_04d8:
	lea rsp, [rbx + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_02ab
.L_if_else_02ab:
	mov rax, L_constants + 2
.L_if_end_02ab:
.L_or_end_0047:
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_03c0:	; new closure is in rax
	mov qword [free_var_110], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void

	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 0	; new rib
	call malloc
	push rax
	mov rdi, 8 * 1	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_opt_env_loop_007a:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_opt_env_end_007a
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_opt_env_loop_007a
.L_lambda_opt_env_end_007a:
	pop rbx
	mov rsi, 0
.L_lambda_opt_params_loop_007a:	; copy params
	cmp rsi, 0
	je .L_lambda_opt_params_end_007a
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_opt_params_loop_007a
.L_lambda_opt_params_end_007a:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_opt_code_007a
	jmp .L_lambda_opt_end_007a
.L_lambda_opt_code_007a:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 0 ;	 check num of args
	je .L_lambda_opt_arity_check_exact_007a ;	 if equal, go to exact arity
	jg .L_lambda_opt_arity_check_more_007a ;	 if greater than, go to arity more
	push qword [rsp + 8 * 2] ;	 else, throw opt arity error
	push 0
	jmp L_error_incorrect_arity_opt
.L_lambda_opt_arity_check_exact_007a:
	mov rax, qword [rsp + 8 * 2] ;	 number of args
	lea rbx, [rsp + 8 * (2 + rax)] ;	 address of last element
	sub rsp, 8
	lea rcx, [rsp + 0] ;	 new start
.L_lambda_opt_shift_entry_007a:
	mov rdx, [rcx + 8]
	mov [rcx], rdx
	add rcx, 8
	cmp rbx, rcx
	jne .L_lambda_opt_shift_entry_007a
.L_lambda_opt_shift_exit_007a:
	mov qword[rbx], sob_nil ;	 place nil
	add rax, 1
	mov qword [rsp + 8 * 2], rax
	jmp .L_lambda_opt_stack_adjusted_007a
.L_lambda_opt_arity_check_more_007a:
	mov rdx, sob_nil ;	 base cdr
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_opt_stack_shrink_loop_exit_007a
.L_lambda_opt_stack_shrink_loop_007a:
	mov rdi, (1 + 8 + 8)
	call malloc
	mov byte[rax], T_pair
	mov SOB_PAIR_CDR(rax), rdx
	mov rdx, rax
	mov rax, qword [rsp + 8 * 2]
	mov rbx, qword [rsp + 8 * (2 + rax)]
	mov SOB_PAIR_CAR(rdx), rbx
	lea rbx, [rsp + 8 * (2 + rax - 1)]
.L_lambda_opt_extra_shift_process_007a:
	mov rcx, [rbx]
	mov [rbx + 8], rcx
	sub rbx, 8
	cmp rsp, rbx
	jle .L_lambda_opt_extra_shift_process_007a
.L_lambda_opt_extra_shift_process_end_007a:
	add rsp, 8
	mov rbx, [rsp + 8 * 2]
	sub rbx, 1
	mov [rsp + 8 * 2], rbx
	cmp qword [rsp + 8 * 2], 1
	jg .L_lambda_opt_stack_shrink_loop_007a
.L_lambda_opt_stack_shrink_loop_exit_007a:
	mov rcx, [rsp + 8 * 2]
	mov rbx, qword [rsp + 8 * (2 + rcx)]
	mov rdi, (1 + 8 + 8)
	call malloc
	mov byte[rax], T_pair
	mov SOB_PAIR_CDR(rax), rdx
	mov SOB_PAIR_CAR(rax), rbx
	mov [rsp + 8 * (2 + rcx)], rax
.L_lambda_opt_stack_adjusted_007a:
	enter 0, 0
	mov rax, PARAM(0)	; param args
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_opt_end_007a:	; new closure is in rax
	mov qword [free_var_106], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void

	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 0	; new rib
	call malloc
	push rax
	mov rdi, 8 * 1	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_03c1:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_03c1
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_03c1
.L_lambda_simple_env_end_03c1:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_03c1:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_03c1
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_03c1
.L_lambda_simple_params_end_03c1:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_03c1
	jmp .L_lambda_simple_end_03c1
.L_lambda_simple_code_03c1:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_03c1
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_03c1:
	enter 0, 0
	mov rax, PARAM(0)	; param x
	cmp rax, sob_boolean_false
	je .L_if_else_02ac
	mov rax, L_constants + 2
	jmp .L_if_end_02ac
.L_if_else_02ac:
	mov rax, L_constants + 3
.L_if_end_02ac:
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_03c1:	; new closure is in rax
	mov qword [free_var_125], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void

	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 0	; new rib
	call malloc
	push rax
	mov rdi, 8 * 1	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_03c2:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_03c2
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_03c2
.L_lambda_simple_env_end_03c2:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_03c2:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_03c2
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_03c2
.L_lambda_simple_params_end_03c2:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_03c2
	jmp .L_lambda_simple_end_03c2
.L_lambda_simple_code_03c2:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_03c2
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_03c2:
	enter 0, 0
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param q
	push rax
	push 1	; arg count
	mov rax, qword [free_var_103]	; free var integer?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	jne .L_or_end_0048
	; preparing a tail-call
	mov rax, PARAM(0)	; param q
	push rax
	push 1	; arg count
	mov rax, qword [free_var_97]	; free var fraction?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; old return address
	push qword [rbp]	; old frame-pointer
	mov rcx, 5
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8]
.L_tc_recycle_frame_loop_04d9:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_04d9
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8
	sub rdx, 8
	jmp .L_tc_recycle_frame_loop_04d9
.L_tc_recycle_frame_done_04d9:
	lea rsp, [rbx + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
.L_or_end_0048:
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_03c2:	; new closure is in rax
	mov qword [free_var_137], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void

	; preparing a non-tail-call
	mov rax, L_constants + 2335
	push rax
	push 1	; arg count
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 0	; new rib
	call malloc
	push rax
	mov rdi, 8 * 1	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_03c3:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_03c3
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_03c3
.L_lambda_simple_env_end_03c3:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_03c3:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_03c3
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_03c3
.L_lambda_simple_params_end_03c3:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_03c3
	jmp .L_lambda_simple_end_03c3
.L_lambda_simple_code_03c3:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_03c3
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_03c3:
	enter 0, 0

	mov rdi, 8
	call malloc
	mov rbx, PARAM(0)	; param run
	mov [rax], rbx	; box run
	mov PARAM(0), rax	; replace param with box
	mov rax, sob_void

	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 1	; new rib
	call malloc
	push rax
	mov rdi, 8 * 2	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_03c4:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
	je .L_lambda_simple_env_end_03c4
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_03c4
.L_lambda_simple_env_end_03c4:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_03c4:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_03c4
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_03c4
.L_lambda_simple_params_end_03c4:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_03c4
	jmp .L_lambda_simple_end_03c4
.L_lambda_simple_code_03c4:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 2
	je .L_lambda_simple_arity_check_ok_03c4
	push qword [rsp + 8 * 2]
	push 2
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_03c4:
	enter 0, 0
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param s
	push rax
	push 1	; arg count
	mov rax, qword [free_var_126]	; free var null?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_02ad
	mov rax, PARAM(0)	; param a
	jmp .L_if_end_02ad
.L_if_else_02ad:
	; preparing a tail-call
	; preparing a non-tail-call
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param s
	push rax
	push 1	; arg count
	mov rax, qword [free_var_69]	; free var cdr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param s
	push rax
	push 1	; arg count
	mov rax, qword [free_var_54]	; free var car
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 2	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var run
	mov rax, qword [rax]
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	mov rax, PARAM(0)	; param a
	push rax
	push 2	; arg count
	mov rax, qword [free_var_85]	; free var cons
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; old return address
	push qword [rbp]	; old frame-pointer
	mov rcx, 6
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8]
.L_tc_recycle_frame_loop_04da:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_04da
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8
	sub rdx, 8
	jmp .L_tc_recycle_frame_loop_04da
.L_tc_recycle_frame_done_04da:
	lea rsp, [rbx + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
.L_if_end_02ad:
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_simple_end_03c4:	; new closure is in rax

	push rax
	mov rax, PARAM(0)	; param run

	pop qword[rax]
	mov rax, sob_void

	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 1	; new rib
	call malloc
	push rax
	mov rdi, 8 * 2	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_opt_env_loop_007b:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
	je .L_lambda_opt_env_end_007b
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_opt_env_loop_007b
.L_lambda_opt_env_end_007b:
	pop rbx
	mov rsi, 0
.L_lambda_opt_params_loop_007b:	; copy params
	cmp rsi, 1
	je .L_lambda_opt_params_end_007b
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_opt_params_loop_007b
.L_lambda_opt_params_end_007b:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_opt_code_007b
	jmp .L_lambda_opt_end_007b
.L_lambda_opt_code_007b:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1 ;	 check num of args
	je .L_lambda_opt_arity_check_exact_007b ;	 if equal, go to exact arity
	jg .L_lambda_opt_arity_check_more_007b ;	 if greater than, go to arity more
	push qword [rsp + 8 * 2] ;	 else, throw opt arity error
	push 1
	jmp L_error_incorrect_arity_opt
.L_lambda_opt_arity_check_exact_007b:
	mov rax, qword [rsp + 8 * 2] ;	 number of args
	lea rbx, [rsp + 8 * (2 + rax)] ;	 address of last element
	sub rsp, 8
	lea rcx, [rsp + 0] ;	 new start
.L_lambda_opt_shift_entry_007b:
	mov rdx, [rcx + 8]
	mov [rcx], rdx
	add rcx, 8
	cmp rbx, rcx
	jne .L_lambda_opt_shift_entry_007b
.L_lambda_opt_shift_exit_007b:
	mov qword[rbx], sob_nil ;	 place nil
	add rax, 1
	mov qword [rsp + 8 * 2], rax
	jmp .L_lambda_opt_stack_adjusted_007b
.L_lambda_opt_arity_check_more_007b:
	mov rdx, sob_nil ;	 base cdr
	cmp qword [rsp + 8 * 2], 2
	je .L_lambda_opt_stack_shrink_loop_exit_007b
.L_lambda_opt_stack_shrink_loop_007b:
	mov rdi, (1 + 8 + 8)
	call malloc
	mov byte[rax], T_pair
	mov SOB_PAIR_CDR(rax), rdx
	mov rdx, rax
	mov rax, qword [rsp + 8 * 2]
	mov rbx, qword [rsp + 8 * (2 + rax)]
	mov SOB_PAIR_CAR(rdx), rbx
	lea rbx, [rsp + 8 * (2 + rax - 1)]
.L_lambda_opt_extra_shift_process_007b:
	mov rcx, [rbx]
	mov [rbx + 8], rcx
	sub rbx, 8
	cmp rsp, rbx
	jle .L_lambda_opt_extra_shift_process_007b
.L_lambda_opt_extra_shift_process_end_007b:
	add rsp, 8
	mov rbx, [rsp + 8 * 2]
	sub rbx, 1
	mov [rsp + 8 * 2], rbx
	cmp qword [rsp + 8 * 2], 2
	jg .L_lambda_opt_stack_shrink_loop_007b
.L_lambda_opt_stack_shrink_loop_exit_007b:
	mov rcx, [rsp + 8 * 2]
	mov rbx, qword [rsp + 8 * (2 + rcx)]
	mov rdi, (1 + 8 + 8)
	call malloc
	mov byte[rax], T_pair
	mov SOB_PAIR_CDR(rax), rdx
	mov SOB_PAIR_CAR(rax), rbx
	mov [rsp + 8 * (2 + rcx)], rax
.L_lambda_opt_stack_adjusted_007b:
	enter 0, 0
	; preparing a tail-call
	mov rax, PARAM(1)	; param s
	push rax
	mov rax, PARAM(0)	; param a
	push rax
	push 2	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var run
	mov rax, qword [rax]
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; old return address
	push qword [rbp]	; old frame-pointer
	mov rcx, 6
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8]
.L_tc_recycle_frame_loop_04db:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_04db
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8
	sub rdx, 8
	jmp .L_tc_recycle_frame_loop_04db
.L_tc_recycle_frame_done_04db:
	lea rsp, [rbx + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_opt_end_007b:	; new closure is in rax
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_03c3:	; new closure is in rax
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	mov qword [free_var_107], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void

	; preparing a non-tail-call
	mov rax, L_constants + 2335
	push rax
	push 1	; arg count
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 0	; new rib
	call malloc
	push rax
	mov rdi, 8 * 1	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_03c5:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_03c5
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_03c5
.L_lambda_simple_env_end_03c5:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_03c5:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_03c5
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_03c5
.L_lambda_simple_params_end_03c5:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_03c5
	jmp .L_lambda_simple_end_03c5
.L_lambda_simple_code_03c5:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_03c5
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_03c5:
	enter 0, 0

	mov rdi, 8
	call malloc
	mov rbx, PARAM(0)	; param run
	mov [rax], rbx	; box run
	mov PARAM(0), rax	; replace param with box
	mov rax, sob_void

	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 1	; new rib
	call malloc
	push rax
	mov rdi, 8 * 2	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_03c6:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
	je .L_lambda_simple_env_end_03c6
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_03c6
.L_lambda_simple_env_end_03c6:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_03c6:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_03c6
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_03c6
.L_lambda_simple_params_end_03c6:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_03c6
	jmp .L_lambda_simple_end_03c6
.L_lambda_simple_code_03c6:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 2
	je .L_lambda_simple_arity_check_ok_03c6
	push qword [rsp + 8 * 2]
	push 2
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_03c6:
	enter 0, 0
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param s
	push rax
	push 1	; arg count
	mov rax, qword [free_var_131]	; free var pair?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_02ae
	; preparing a tail-call
	; preparing a non-tail-call
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param s
	push rax
	push 1	; arg count
	mov rax, qword [free_var_69]	; free var cdr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param s
	push rax
	push 1	; arg count
	mov rax, qword [free_var_54]	; free var car
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 2	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var run
	mov rax, qword [rax]
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	mov rax, PARAM(0)	; param a
	push rax
	push 2	; arg count
	mov rax, qword [free_var_85]	; free var cons
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; old return address
	push qword [rbp]	; old frame-pointer
	mov rcx, 6
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8]
.L_tc_recycle_frame_loop_04dc:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_04dc
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8
	sub rdx, 8
	jmp .L_tc_recycle_frame_loop_04dc
.L_tc_recycle_frame_done_04dc:
	lea rsp, [rbx + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_02ae
.L_if_else_02ae:
	mov rax, PARAM(0)	; param a
.L_if_end_02ae:
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_simple_end_03c6:	; new closure is in rax

	push rax
	mov rax, PARAM(0)	; param run

	pop qword[rax]
	mov rax, sob_void

	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 1	; new rib
	call malloc
	push rax
	mov rdi, 8 * 2	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_opt_env_loop_007c:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
	je .L_lambda_opt_env_end_007c
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_opt_env_loop_007c
.L_lambda_opt_env_end_007c:
	pop rbx
	mov rsi, 0
.L_lambda_opt_params_loop_007c:	; copy params
	cmp rsi, 1
	je .L_lambda_opt_params_end_007c
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_opt_params_loop_007c
.L_lambda_opt_params_end_007c:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_opt_code_007c
	jmp .L_lambda_opt_end_007c
.L_lambda_opt_code_007c:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1 ;	 check num of args
	je .L_lambda_opt_arity_check_exact_007c ;	 if equal, go to exact arity
	jg .L_lambda_opt_arity_check_more_007c ;	 if greater than, go to arity more
	push qword [rsp + 8 * 2] ;	 else, throw opt arity error
	push 1
	jmp L_error_incorrect_arity_opt
.L_lambda_opt_arity_check_exact_007c:
	mov rax, qword [rsp + 8 * 2] ;	 number of args
	lea rbx, [rsp + 8 * (2 + rax)] ;	 address of last element
	sub rsp, 8
	lea rcx, [rsp + 0] ;	 new start
.L_lambda_opt_shift_entry_007c:
	mov rdx, [rcx + 8]
	mov [rcx], rdx
	add rcx, 8
	cmp rbx, rcx
	jne .L_lambda_opt_shift_entry_007c
.L_lambda_opt_shift_exit_007c:
	mov qword[rbx], sob_nil ;	 place nil
	add rax, 1
	mov qword [rsp + 8 * 2], rax
	jmp .L_lambda_opt_stack_adjusted_007c
.L_lambda_opt_arity_check_more_007c:
	mov rdx, sob_nil ;	 base cdr
	cmp qword [rsp + 8 * 2], 2
	je .L_lambda_opt_stack_shrink_loop_exit_007c
.L_lambda_opt_stack_shrink_loop_007c:
	mov rdi, (1 + 8 + 8)
	call malloc
	mov byte[rax], T_pair
	mov SOB_PAIR_CDR(rax), rdx
	mov rdx, rax
	mov rax, qword [rsp + 8 * 2]
	mov rbx, qword [rsp + 8 * (2 + rax)]
	mov SOB_PAIR_CAR(rdx), rbx
	lea rbx, [rsp + 8 * (2 + rax - 1)]
.L_lambda_opt_extra_shift_process_007c:
	mov rcx, [rbx]
	mov [rbx + 8], rcx
	sub rbx, 8
	cmp rsp, rbx
	jle .L_lambda_opt_extra_shift_process_007c
.L_lambda_opt_extra_shift_process_end_007c:
	add rsp, 8
	mov rbx, [rsp + 8 * 2]
	sub rbx, 1
	mov [rsp + 8 * 2], rbx
	cmp qword [rsp + 8 * 2], 2
	jg .L_lambda_opt_stack_shrink_loop_007c
.L_lambda_opt_stack_shrink_loop_exit_007c:
	mov rcx, [rsp + 8 * 2]
	mov rbx, qword [rsp + 8 * (2 + rcx)]
	mov rdi, (1 + 8 + 8)
	call malloc
	mov byte[rax], T_pair
	mov SOB_PAIR_CDR(rax), rdx
	mov SOB_PAIR_CAR(rax), rbx
	mov [rsp + 8 * (2 + rcx)], rax
.L_lambda_opt_stack_adjusted_007c:
	enter 0, 0
	; preparing a tail-call
	; preparing a non-tail-call
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param s
	push rax
	push 1	; arg count
	mov rax, qword [free_var_69]	; free var cdr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param s
	push rax
	push 1	; arg count
	mov rax, qword [free_var_54]	; free var car
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 2	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var run
	mov rax, qword [rax]
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	mov rax, PARAM(0)	; param f
	push rax
	push 2	; arg count
	mov rax, qword [free_var_12]	; free var __bin-apply
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; old return address
	push qword [rbp]	; old frame-pointer
	mov rcx, 6
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8]
.L_tc_recycle_frame_loop_04dd:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_04dd
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8
	sub rdx, 8
	jmp .L_tc_recycle_frame_loop_04dd
.L_tc_recycle_frame_done_04dd:
	lea rsp, [rbx + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_opt_end_007c:	; new closure is in rax
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_03c5:	; new closure is in rax
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	mov qword [free_var_33], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void

	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 0	; new rib
	call malloc
	push rax
	mov rdi, 8 * 1	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_opt_env_loop_007d:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_opt_env_end_007d
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_opt_env_loop_007d
.L_lambda_opt_env_end_007d:
	pop rbx
	mov rsi, 0
.L_lambda_opt_params_loop_007d:	; copy params
	cmp rsi, 0
	je .L_lambda_opt_params_end_007d
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_opt_params_loop_007d
.L_lambda_opt_params_end_007d:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_opt_code_007d
	jmp .L_lambda_opt_end_007d
.L_lambda_opt_code_007d:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1 ;	 check num of args
	je .L_lambda_opt_arity_check_exact_007d ;	 if equal, go to exact arity
	jg .L_lambda_opt_arity_check_more_007d ;	 if greater than, go to arity more
	push qword [rsp + 8 * 2] ;	 else, throw opt arity error
	push 1
	jmp L_error_incorrect_arity_opt
.L_lambda_opt_arity_check_exact_007d:
	mov rax, qword [rsp + 8 * 2] ;	 number of args
	lea rbx, [rsp + 8 * (2 + rax)] ;	 address of last element
	sub rsp, 8
	lea rcx, [rsp + 0] ;	 new start
.L_lambda_opt_shift_entry_007d:
	mov rdx, [rcx + 8]
	mov [rcx], rdx
	add rcx, 8
	cmp rbx, rcx
	jne .L_lambda_opt_shift_entry_007d
.L_lambda_opt_shift_exit_007d:
	mov qword[rbx], sob_nil ;	 place nil
	add rax, 1
	mov qword [rsp + 8 * 2], rax
	jmp .L_lambda_opt_stack_adjusted_007d
.L_lambda_opt_arity_check_more_007d:
	mov rdx, sob_nil ;	 base cdr
	cmp qword [rsp + 8 * 2], 2
	je .L_lambda_opt_stack_shrink_loop_exit_007d
.L_lambda_opt_stack_shrink_loop_007d:
	mov rdi, (1 + 8 + 8)
	call malloc
	mov byte[rax], T_pair
	mov SOB_PAIR_CDR(rax), rdx
	mov rdx, rax
	mov rax, qword [rsp + 8 * 2]
	mov rbx, qword [rsp + 8 * (2 + rax)]
	mov SOB_PAIR_CAR(rdx), rbx
	lea rbx, [rsp + 8 * (2 + rax - 1)]
.L_lambda_opt_extra_shift_process_007d:
	mov rcx, [rbx]
	mov [rbx + 8], rcx
	sub rbx, 8
	cmp rsp, rbx
	jle .L_lambda_opt_extra_shift_process_007d
.L_lambda_opt_extra_shift_process_end_007d:
	add rsp, 8
	mov rbx, [rsp + 8 * 2]
	sub rbx, 1
	mov [rsp + 8 * 2], rbx
	cmp qword [rsp + 8 * 2], 2
	jg .L_lambda_opt_stack_shrink_loop_007d
.L_lambda_opt_stack_shrink_loop_exit_007d:
	mov rcx, [rsp + 8 * 2]
	mov rbx, qword [rsp + 8 * (2 + rcx)]
	mov rdi, (1 + 8 + 8)
	call malloc
	mov byte[rax], T_pair
	mov SOB_PAIR_CDR(rax), rdx
	mov SOB_PAIR_CAR(rax), rbx
	mov [rsp + 8 * (2 + rcx)], rax
.L_lambda_opt_stack_adjusted_007d:
	enter 0, 0
	; preparing a tail-call
	mov rax, L_constants + 2335
	push rax
	push 1	; arg count
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 2	; new rib
	call malloc
	push rax
	mov rdi, 8 * 2	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_03c7:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
	je .L_lambda_simple_env_end_03c7
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_03c7
.L_lambda_simple_env_end_03c7:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_03c7:	; copy params
	cmp rsi, 2
	je .L_lambda_simple_params_end_03c7
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_03c7
.L_lambda_simple_params_end_03c7:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_03c7
	jmp .L_lambda_simple_end_03c7
.L_lambda_simple_code_03c7:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_03c7
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_03c7:
	enter 0, 0

	mov rdi, 8
	call malloc
	mov rbx, PARAM(0)	; param loop
	mov [rax], rbx	; box loop
	mov PARAM(0), rax	; replace param with box
	mov rax, sob_void

	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 1	; new rib
	call malloc
	push rax
	mov rdi, 8 * 3	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_03c8:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 2
	je .L_lambda_simple_env_end_03c8
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_03c8
.L_lambda_simple_env_end_03c8:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_03c8:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_03c8
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_03c8
.L_lambda_simple_params_end_03c8:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_03c8
	jmp .L_lambda_simple_end_03c8
.L_lambda_simple_code_03c8:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_03c8
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_03c8:
	enter 0, 0
	; preparing a non-tail-call
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param s
	push rax
	push 1	; arg count
	mov rax, qword [free_var_54]	; free var car
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 1	; arg count
	mov rax, qword [free_var_131]	; free var pair?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_02af
	; preparing a non-tail-call
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param s
	push rax
	mov rax, qword [free_var_54]	; free var car
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	push rax
	push 2	; arg count
	mov rax, qword [free_var_122]	; free var map
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	mov rax, ENV
	mov rax, qword [rax + 8 * 1]
	mov rax, qword [rax + 8 * 0]	; bound var f
	push rax
	push 2	; arg count
	mov rax, qword [free_var_33]	; free var apply
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	jne .L_or_end_0049
	; preparing a tail-call
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param s
	push rax
	mov rax, qword [free_var_69]	; free var cdr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	push rax
	push 2	; arg count
	mov rax, qword [free_var_122]	; free var map
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 1	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var loop
	mov rax, qword [rax]
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; old return address
	push qword [rbp]	; old frame-pointer
	mov rcx, 5
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8]
.L_tc_recycle_frame_loop_04de:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_04de
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8
	sub rdx, 8
	jmp .L_tc_recycle_frame_loop_04de
.L_tc_recycle_frame_done_04de:
	lea rsp, [rbx + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
.L_or_end_0049:
	jmp .L_if_end_02af
.L_if_else_02af:
	mov rax, L_constants + 2
.L_if_end_02af:
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_03c8:	; new closure is in rax

	push rax
	mov rax, PARAM(0)	; param loop

	pop qword[rax]
	mov rax, sob_void

	; preparing a non-tail-call
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 1]	; bound var s
	push rax
	push 1	; arg count
	mov rax, qword [free_var_131]	; free var pair?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_02b0
	; preparing a tail-call
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 1]	; bound var s
	push rax
	push 1	; arg count
	mov rax, PARAM(0)	; param loop
	mov rax, qword [rax]
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; old return address
	push qword [rbp]	; old frame-pointer
	mov rcx, 5
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8]
.L_tc_recycle_frame_loop_04df:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_04df
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8
	sub rdx, 8
	jmp .L_tc_recycle_frame_loop_04df
.L_tc_recycle_frame_done_04df:
	lea rsp, [rbx + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_02b0
.L_if_else_02b0:
	mov rax, L_constants + 2
.L_if_end_02b0:
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_03c7:	; new closure is in rax
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; old return address
	push qword [rbp]	; old frame-pointer
	mov rcx, 5
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8]
.L_tc_recycle_frame_loop_04e0:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_04e0
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8
	sub rdx, 8
	jmp .L_tc_recycle_frame_loop_04e0
.L_tc_recycle_frame_done_04e0:
	lea rsp, [rbx + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_opt_end_007d:	; new closure is in rax
	mov qword [free_var_130], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void

	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 0	; new rib
	call malloc
	push rax
	mov rdi, 8 * 1	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_opt_env_loop_007e:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_opt_env_end_007e
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_opt_env_loop_007e
.L_lambda_opt_env_end_007e:
	pop rbx
	mov rsi, 0
.L_lambda_opt_params_loop_007e:	; copy params
	cmp rsi, 0
	je .L_lambda_opt_params_end_007e
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_opt_params_loop_007e
.L_lambda_opt_params_end_007e:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_opt_code_007e
	jmp .L_lambda_opt_end_007e
.L_lambda_opt_code_007e:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1 ;	 check num of args
	je .L_lambda_opt_arity_check_exact_007e ;	 if equal, go to exact arity
	jg .L_lambda_opt_arity_check_more_007e ;	 if greater than, go to arity more
	push qword [rsp + 8 * 2] ;	 else, throw opt arity error
	push 1
	jmp L_error_incorrect_arity_opt
.L_lambda_opt_arity_check_exact_007e:
	mov rax, qword [rsp + 8 * 2] ;	 number of args
	lea rbx, [rsp + 8 * (2 + rax)] ;	 address of last element
	sub rsp, 8
	lea rcx, [rsp + 0] ;	 new start
.L_lambda_opt_shift_entry_007e:
	mov rdx, [rcx + 8]
	mov [rcx], rdx
	add rcx, 8
	cmp rbx, rcx
	jne .L_lambda_opt_shift_entry_007e
.L_lambda_opt_shift_exit_007e:
	mov qword[rbx], sob_nil ;	 place nil
	add rax, 1
	mov qword [rsp + 8 * 2], rax
	jmp .L_lambda_opt_stack_adjusted_007e
.L_lambda_opt_arity_check_more_007e:
	mov rdx, sob_nil ;	 base cdr
	cmp qword [rsp + 8 * 2], 2
	je .L_lambda_opt_stack_shrink_loop_exit_007e
.L_lambda_opt_stack_shrink_loop_007e:
	mov rdi, (1 + 8 + 8)
	call malloc
	mov byte[rax], T_pair
	mov SOB_PAIR_CDR(rax), rdx
	mov rdx, rax
	mov rax, qword [rsp + 8 * 2]
	mov rbx, qword [rsp + 8 * (2 + rax)]
	mov SOB_PAIR_CAR(rdx), rbx
	lea rbx, [rsp + 8 * (2 + rax - 1)]
.L_lambda_opt_extra_shift_process_007e:
	mov rcx, [rbx]
	mov [rbx + 8], rcx
	sub rbx, 8
	cmp rsp, rbx
	jle .L_lambda_opt_extra_shift_process_007e
.L_lambda_opt_extra_shift_process_end_007e:
	add rsp, 8
	mov rbx, [rsp + 8 * 2]
	sub rbx, 1
	mov [rsp + 8 * 2], rbx
	cmp qword [rsp + 8 * 2], 2
	jg .L_lambda_opt_stack_shrink_loop_007e
.L_lambda_opt_stack_shrink_loop_exit_007e:
	mov rcx, [rsp + 8 * 2]
	mov rbx, qword [rsp + 8 * (2 + rcx)]
	mov rdi, (1 + 8 + 8)
	call malloc
	mov byte[rax], T_pair
	mov SOB_PAIR_CDR(rax), rdx
	mov SOB_PAIR_CAR(rax), rbx
	mov [rsp + 8 * (2 + rcx)], rax
.L_lambda_opt_stack_adjusted_007e:
	enter 0, 0
	; preparing a tail-call
	mov rax, L_constants + 2335
	push rax
	push 1	; arg count
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 2	; new rib
	call malloc
	push rax
	mov rdi, 8 * 2	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_03c9:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
	je .L_lambda_simple_env_end_03c9
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_03c9
.L_lambda_simple_env_end_03c9:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_03c9:	; copy params
	cmp rsi, 2
	je .L_lambda_simple_params_end_03c9
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_03c9
.L_lambda_simple_params_end_03c9:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_03c9
	jmp .L_lambda_simple_end_03c9
.L_lambda_simple_code_03c9:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_03c9
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_03c9:
	enter 0, 0

	mov rdi, 8
	call malloc
	mov rbx, PARAM(0)	; param loop
	mov [rax], rbx	; box loop
	mov PARAM(0), rax	; replace param with box
	mov rax, sob_void

	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 1	; new rib
	call malloc
	push rax
	mov rdi, 8 * 3	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_03ca:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 2
	je .L_lambda_simple_env_end_03ca
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_03ca
.L_lambda_simple_env_end_03ca:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_03ca:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_03ca
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_03ca
.L_lambda_simple_params_end_03ca:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_03ca
	jmp .L_lambda_simple_end_03ca
.L_lambda_simple_code_03ca:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_03ca
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_03ca:
	enter 0, 0
	; preparing a non-tail-call
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param s
	push rax
	push 1	; arg count
	mov rax, qword [free_var_54]	; free var car
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 1	; arg count
	mov rax, qword [free_var_126]	; free var null?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	jne .L_or_end_004a
	; preparing a non-tail-call
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param s
	push rax
	mov rax, qword [free_var_54]	; free var car
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	push rax
	push 2	; arg count
	mov rax, qword [free_var_122]	; free var map
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	mov rax, ENV
	mov rax, qword [rax + 8 * 1]
	mov rax, qword [rax + 8 * 0]	; bound var f
	push rax
	push 2	; arg count
	mov rax, qword [free_var_33]	; free var apply
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_02b1
	; preparing a tail-call
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param s
	push rax
	mov rax, qword [free_var_69]	; free var cdr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	push rax
	push 2	; arg count
	mov rax, qword [free_var_122]	; free var map
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 1	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var loop
	mov rax, qword [rax]
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; old return address
	push qword [rbp]	; old frame-pointer
	mov rcx, 5
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8]
.L_tc_recycle_frame_loop_04e1:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_04e1
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8
	sub rdx, 8
	jmp .L_tc_recycle_frame_loop_04e1
.L_tc_recycle_frame_done_04e1:
	lea rsp, [rbx + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_02b1
.L_if_else_02b1:
	mov rax, L_constants + 2
.L_if_end_02b1:
.L_or_end_004a:
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_03ca:	; new closure is in rax

	push rax
	mov rax, PARAM(0)	; param loop

	pop qword[rax]
	mov rax, sob_void

	; preparing a non-tail-call
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 1]	; bound var s
	push rax
	push 1	; arg count
	mov rax, qword [free_var_126]	; free var null?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	jne .L_or_end_004b
	; preparing a non-tail-call
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 1]	; bound var s
	push rax
	push 1	; arg count
	mov rax, qword [free_var_131]	; free var pair?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_02b2
	; preparing a tail-call
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 1]	; bound var s
	push rax
	push 1	; arg count
	mov rax, PARAM(0)	; param loop
	mov rax, qword [rax]
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; old return address
	push qword [rbp]	; old frame-pointer
	mov rcx, 5
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8]
.L_tc_recycle_frame_loop_04e2:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_04e2
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8
	sub rdx, 8
	jmp .L_tc_recycle_frame_loop_04e2
.L_tc_recycle_frame_done_04e2:
	lea rsp, [rbx + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_02b2
.L_if_else_02b2:
	mov rax, L_constants + 2
.L_if_end_02b2:
.L_or_end_004b:
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_03c9:	; new closure is in rax
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; old return address
	push qword [rbp]	; old frame-pointer
	mov rcx, 5
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8]
.L_tc_recycle_frame_loop_04e3:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_04e3
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8
	sub rdx, 8
	jmp .L_tc_recycle_frame_loop_04e3
.L_tc_recycle_frame_done_04e3:
	lea rsp, [rbx + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_opt_end_007e:	; new closure is in rax
	mov qword [free_var_31], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void

	; preparing a non-tail-call
	mov rax, L_constants + 2335
	push rax
	mov rax, L_constants + 2335
	push rax
	push 2	; arg count
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 0	; new rib
	call malloc
	push rax
	mov rdi, 8 * 1	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_03cb:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_03cb
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_03cb
.L_lambda_simple_env_end_03cb:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_03cb:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_03cb
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_03cb
.L_lambda_simple_params_end_03cb:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_03cb
	jmp .L_lambda_simple_end_03cb
.L_lambda_simple_code_03cb:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 2
	je .L_lambda_simple_arity_check_ok_03cb
	push qword [rsp + 8 * 2]
	push 2
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_03cb:
	enter 0, 0

	mov rdi, 8
	call malloc
	mov rbx, PARAM(0)	; param map1
	mov [rax], rbx	; box map1
	mov PARAM(0), rax	; replace param with box
	mov rax, sob_void


	mov rdi, 8
	call malloc
	mov rbx, PARAM(1)	; param map-list
	mov [rax], rbx	; box map-list
	mov PARAM(1), rax	; replace param with box
	mov rax, sob_void

	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 2	; new rib
	call malloc
	push rax
	mov rdi, 8 * 2	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_03cc:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
	je .L_lambda_simple_env_end_03cc
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_03cc
.L_lambda_simple_env_end_03cc:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_03cc:	; copy params
	cmp rsi, 2
	je .L_lambda_simple_params_end_03cc
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_03cc
.L_lambda_simple_params_end_03cc:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_03cc
	jmp .L_lambda_simple_end_03cc
.L_lambda_simple_code_03cc:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 2
	je .L_lambda_simple_arity_check_ok_03cc
	push qword [rsp + 8 * 2]
	push 2
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_03cc:
	enter 0, 0
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param s
	push rax
	push 1	; arg count
	mov rax, qword [free_var_126]	; free var null?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_02b3
	mov rax, L_constants + 1
	jmp .L_if_end_02b3
.L_if_else_02b3:
	; preparing a tail-call
	; preparing a non-tail-call
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param s
	push rax
	push 1	; arg count
	mov rax, qword [free_var_69]	; free var cdr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	mov rax, PARAM(0)	; param f
	push rax
	push 2	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var map1
	mov rax, qword [rax]
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	; preparing a non-tail-call
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param s
	push rax
	push 1	; arg count
	mov rax, qword [free_var_54]	; free var car
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 1	; arg count
	mov rax, PARAM(0)	; param f
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 2	; arg count
	mov rax, qword [free_var_85]	; free var cons
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; old return address
	push qword [rbp]	; old frame-pointer
	mov rcx, 6
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8]
.L_tc_recycle_frame_loop_04e4:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_04e4
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8
	sub rdx, 8
	jmp .L_tc_recycle_frame_loop_04e4
.L_tc_recycle_frame_done_04e4:
	lea rsp, [rbx + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
.L_if_end_02b3:
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_simple_end_03cc:	; new closure is in rax

	push rax
	mov rax, PARAM(0)	; param map1

	pop qword[rax]
	mov rax, sob_void

	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 2	; new rib
	call malloc
	push rax
	mov rdi, 8 * 2	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_03cd:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
	je .L_lambda_simple_env_end_03cd
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_03cd
.L_lambda_simple_env_end_03cd:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_03cd:	; copy params
	cmp rsi, 2
	je .L_lambda_simple_params_end_03cd
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_03cd
.L_lambda_simple_params_end_03cd:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_03cd
	jmp .L_lambda_simple_end_03cd
.L_lambda_simple_code_03cd:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 2
	je .L_lambda_simple_arity_check_ok_03cd
	push qword [rsp + 8 * 2]
	push 2
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_03cd:
	enter 0, 0
	; preparing a non-tail-call
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param s
	push rax
	push 1	; arg count
	mov rax, qword [free_var_54]	; free var car
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 1	; arg count
	mov rax, qword [free_var_126]	; free var null?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_02b4
	mov rax, L_constants + 1
	jmp .L_if_end_02b4
.L_if_else_02b4:
	; preparing a tail-call
	; preparing a non-tail-call
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param s
	push rax
	mov rax, qword [free_var_69]	; free var cdr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	push rax
	push 2	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var map1
	mov rax, qword [rax]
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	mov rax, PARAM(0)	; param f
	push rax
	push 2	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 1]	; bound var map-list
	mov rax, qword [rax]
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	; preparing a non-tail-call
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param s
	push rax
	mov rax, qword [free_var_54]	; free var car
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	push rax
	push 2	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var map1
	mov rax, qword [rax]
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	mov rax, PARAM(0)	; param f
	push rax
	push 2	; arg count
	mov rax, qword [free_var_33]	; free var apply
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 2	; arg count
	mov rax, qword [free_var_85]	; free var cons
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; old return address
	push qword [rbp]	; old frame-pointer
	mov rcx, 6
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8]
.L_tc_recycle_frame_loop_04e5:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_04e5
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8
	sub rdx, 8
	jmp .L_tc_recycle_frame_loop_04e5
.L_tc_recycle_frame_done_04e5:
	lea rsp, [rbx + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
.L_if_end_02b4:
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_simple_end_03cd:	; new closure is in rax

	push rax
	mov rax, PARAM(1)	; param map-list

	pop qword[rax]
	mov rax, sob_void

	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 2	; new rib
	call malloc
	push rax
	mov rdi, 8 * 2	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_opt_env_loop_007f:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
	je .L_lambda_opt_env_end_007f
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_opt_env_loop_007f
.L_lambda_opt_env_end_007f:
	pop rbx
	mov rsi, 0
.L_lambda_opt_params_loop_007f:	; copy params
	cmp rsi, 2
	je .L_lambda_opt_params_end_007f
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_opt_params_loop_007f
.L_lambda_opt_params_end_007f:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_opt_code_007f
	jmp .L_lambda_opt_end_007f
.L_lambda_opt_code_007f:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1 ;	 check num of args
	je .L_lambda_opt_arity_check_exact_007f ;	 if equal, go to exact arity
	jg .L_lambda_opt_arity_check_more_007f ;	 if greater than, go to arity more
	push qword [rsp + 8 * 2] ;	 else, throw opt arity error
	push 1
	jmp L_error_incorrect_arity_opt
.L_lambda_opt_arity_check_exact_007f:
	mov rax, qword [rsp + 8 * 2] ;	 number of args
	lea rbx, [rsp + 8 * (2 + rax)] ;	 address of last element
	sub rsp, 8
	lea rcx, [rsp + 0] ;	 new start
.L_lambda_opt_shift_entry_007f:
	mov rdx, [rcx + 8]
	mov [rcx], rdx
	add rcx, 8
	cmp rbx, rcx
	jne .L_lambda_opt_shift_entry_007f
.L_lambda_opt_shift_exit_007f:
	mov qword[rbx], sob_nil ;	 place nil
	add rax, 1
	mov qword [rsp + 8 * 2], rax
	jmp .L_lambda_opt_stack_adjusted_007f
.L_lambda_opt_arity_check_more_007f:
	mov rdx, sob_nil ;	 base cdr
	cmp qword [rsp + 8 * 2], 2
	je .L_lambda_opt_stack_shrink_loop_exit_007f
.L_lambda_opt_stack_shrink_loop_007f:
	mov rdi, (1 + 8 + 8)
	call malloc
	mov byte[rax], T_pair
	mov SOB_PAIR_CDR(rax), rdx
	mov rdx, rax
	mov rax, qword [rsp + 8 * 2]
	mov rbx, qword [rsp + 8 * (2 + rax)]
	mov SOB_PAIR_CAR(rdx), rbx
	lea rbx, [rsp + 8 * (2 + rax - 1)]
.L_lambda_opt_extra_shift_process_007f:
	mov rcx, [rbx]
	mov [rbx + 8], rcx
	sub rbx, 8
	cmp rsp, rbx
	jle .L_lambda_opt_extra_shift_process_007f
.L_lambda_opt_extra_shift_process_end_007f:
	add rsp, 8
	mov rbx, [rsp + 8 * 2]
	sub rbx, 1
	mov [rsp + 8 * 2], rbx
	cmp qword [rsp + 8 * 2], 2
	jg .L_lambda_opt_stack_shrink_loop_007f
.L_lambda_opt_stack_shrink_loop_exit_007f:
	mov rcx, [rsp + 8 * 2]
	mov rbx, qword [rsp + 8 * (2 + rcx)]
	mov rdi, (1 + 8 + 8)
	call malloc
	mov byte[rax], T_pair
	mov SOB_PAIR_CDR(rax), rdx
	mov SOB_PAIR_CAR(rax), rbx
	mov [rsp + 8 * (2 + rcx)], rax
.L_lambda_opt_stack_adjusted_007f:
	enter 0, 0
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param s
	push rax
	push 1	; arg count
	mov rax, qword [free_var_126]	; free var null?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_02b5
	mov rax, L_constants + 1
	jmp .L_if_end_02b5
.L_if_else_02b5:
	; preparing a tail-call
	mov rax, PARAM(1)	; param s
	push rax
	mov rax, PARAM(0)	; param f
	push rax
	push 2	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 1]	; bound var map-list
	mov rax, qword [rax]
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; old return address
	push qword [rbp]	; old frame-pointer
	mov rcx, 6
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8]
.L_tc_recycle_frame_loop_04e6:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_04e6
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8
	sub rdx, 8
	jmp .L_tc_recycle_frame_loop_04e6
.L_tc_recycle_frame_done_04e6:
	lea rsp, [rbx + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
.L_if_end_02b5:
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_opt_end_007f:	; new closure is in rax
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_simple_end_03cb:	; new closure is in rax
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	mov qword [free_var_122], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void

	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 0	; new rib
	call malloc
	push rax
	mov rdi, 8 * 1	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_03ce:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_03ce
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_03ce
.L_lambda_simple_env_end_03ce:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_03ce:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_03ce
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_03ce
.L_lambda_simple_params_end_03ce:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_03ce
	jmp .L_lambda_simple_end_03ce
.L_lambda_simple_code_03ce:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_03ce
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_03ce:
	enter 0, 0
	; preparing a tail-call
	mov rax, PARAM(0)	; param s
	push rax
	mov rax, L_constants + 1
	push rax
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 1	; new rib
	call malloc
	push rax
	mov rdi, 8 * 2	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_03cf:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
	je .L_lambda_simple_env_end_03cf
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_03cf
.L_lambda_simple_env_end_03cf:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_03cf:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_03cf
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_03cf
.L_lambda_simple_params_end_03cf:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_03cf
	jmp .L_lambda_simple_end_03cf
.L_lambda_simple_code_03cf:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 2
	je .L_lambda_simple_arity_check_ok_03cf
	push qword [rsp + 8 * 2]
	push 2
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_03cf:
	enter 0, 0
	; preparing a tail-call
	mov rax, PARAM(0)	; param r
	push rax
	mov rax, PARAM(1)	; param a
	push rax
	push 2	; arg count
	mov rax, qword [free_var_85]	; free var cons
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; old return address
	push qword [rbp]	; old frame-pointer
	mov rcx, 6
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8]
.L_tc_recycle_frame_loop_04e7:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_04e7
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8
	sub rdx, 8
	jmp .L_tc_recycle_frame_loop_04e7
.L_tc_recycle_frame_done_04e7:
	lea rsp, [rbx + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_simple_end_03cf:	; new closure is in rax
	push rax
	push 3	; arg count
	mov rax, qword [free_var_94]	; free var fold-left
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; old return address
	push qword [rbp]	; old frame-pointer
	mov rcx, 7
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8]
.L_tc_recycle_frame_loop_04e8:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_04e8
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8
	sub rdx, 8
	jmp .L_tc_recycle_frame_loop_04e8
.L_tc_recycle_frame_done_04e8:
	lea rsp, [rbx + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_03ce:	; new closure is in rax
	mov qword [free_var_143], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void

	; preparing a non-tail-call
	mov rax, L_constants + 2335
	push rax
	mov rax, L_constants + 2335
	push rax
	push 2	; arg count
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 0	; new rib
	call malloc
	push rax
	mov rdi, 8 * 1	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_03d0:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_03d0
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_03d0
.L_lambda_simple_env_end_03d0:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_03d0:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_03d0
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_03d0
.L_lambda_simple_params_end_03d0:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_03d0
	jmp .L_lambda_simple_end_03d0
.L_lambda_simple_code_03d0:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 2
	je .L_lambda_simple_arity_check_ok_03d0
	push qword [rsp + 8 * 2]
	push 2
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_03d0:
	enter 0, 0

	mov rdi, 8
	call malloc
	mov rbx, PARAM(0)	; param run-1
	mov [rax], rbx	; box run-1
	mov PARAM(0), rax	; replace param with box
	mov rax, sob_void


	mov rdi, 8
	call malloc
	mov rbx, PARAM(1)	; param run-2
	mov [rax], rbx	; box run-2
	mov PARAM(1), rax	; replace param with box
	mov rax, sob_void

	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 2	; new rib
	call malloc
	push rax
	mov rdi, 8 * 2	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_03d1:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
	je .L_lambda_simple_env_end_03d1
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_03d1
.L_lambda_simple_env_end_03d1:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_03d1:	; copy params
	cmp rsi, 2
	je .L_lambda_simple_params_end_03d1
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_03d1
.L_lambda_simple_params_end_03d1:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_03d1
	jmp .L_lambda_simple_end_03d1
.L_lambda_simple_code_03d1:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 2
	je .L_lambda_simple_arity_check_ok_03d1
	push qword [rsp + 8 * 2]
	push 2
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_03d1:
	enter 0, 0
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param sr
	push rax
	push 1	; arg count
	mov rax, qword [free_var_126]	; free var null?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_02b6
	mov rax, PARAM(0)	; param s1
	jmp .L_if_end_02b6
.L_if_else_02b6:
	; preparing a tail-call
	; preparing a non-tail-call
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param sr
	push rax
	push 1	; arg count
	mov rax, qword [free_var_69]	; free var cdr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param sr
	push rax
	push 1	; arg count
	mov rax, qword [free_var_54]	; free var car
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 2	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var run-1
	mov rax, qword [rax]
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	mov rax, PARAM(0)	; param s1
	push rax
	push 2	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 1]	; bound var run-2
	mov rax, qword [rax]
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; old return address
	push qword [rbp]	; old frame-pointer
	mov rcx, 6
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8]
.L_tc_recycle_frame_loop_04e9:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_04e9
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8
	sub rdx, 8
	jmp .L_tc_recycle_frame_loop_04e9
.L_tc_recycle_frame_done_04e9:
	lea rsp, [rbx + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
.L_if_end_02b6:
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_simple_end_03d1:	; new closure is in rax

	push rax
	mov rax, PARAM(0)	; param run-1

	pop qword[rax]
	mov rax, sob_void

	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 2	; new rib
	call malloc
	push rax
	mov rdi, 8 * 2	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_03d2:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
	je .L_lambda_simple_env_end_03d2
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_03d2
.L_lambda_simple_env_end_03d2:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_03d2:	; copy params
	cmp rsi, 2
	je .L_lambda_simple_params_end_03d2
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_03d2
.L_lambda_simple_params_end_03d2:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_03d2
	jmp .L_lambda_simple_end_03d2
.L_lambda_simple_code_03d2:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 2
	je .L_lambda_simple_arity_check_ok_03d2
	push qword [rsp + 8 * 2]
	push 2
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_03d2:
	enter 0, 0
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param s1
	push rax
	push 1	; arg count
	mov rax, qword [free_var_126]	; free var null?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_02b7
	mov rax, PARAM(1)	; param s2
	jmp .L_if_end_02b7
.L_if_else_02b7:
	; preparing a tail-call
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param s2
	push rax
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param s1
	push rax
	push 1	; arg count
	mov rax, qword [free_var_69]	; free var cdr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 2	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 1]	; bound var run-2
	mov rax, qword [rax]
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param s1
	push rax
	push 1	; arg count
	mov rax, qword [free_var_54]	; free var car
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 2	; arg count
	mov rax, qword [free_var_85]	; free var cons
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; old return address
	push qword [rbp]	; old frame-pointer
	mov rcx, 6
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8]
.L_tc_recycle_frame_loop_04ea:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_04ea
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8
	sub rdx, 8
	jmp .L_tc_recycle_frame_loop_04ea
.L_tc_recycle_frame_done_04ea:
	lea rsp, [rbx + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
.L_if_end_02b7:
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_simple_end_03d2:	; new closure is in rax

	push rax
	mov rax, PARAM(1)	; param run-2

	pop qword[rax]
	mov rax, sob_void

	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 2	; new rib
	call malloc
	push rax
	mov rdi, 8 * 2	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_opt_env_loop_0080:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
	je .L_lambda_opt_env_end_0080
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_opt_env_loop_0080
.L_lambda_opt_env_end_0080:
	pop rbx
	mov rsi, 0
.L_lambda_opt_params_loop_0080:	; copy params
	cmp rsi, 2
	je .L_lambda_opt_params_end_0080
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_opt_params_loop_0080
.L_lambda_opt_params_end_0080:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_opt_code_0080
	jmp .L_lambda_opt_end_0080
.L_lambda_opt_code_0080:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 0 ;	 check num of args
	je .L_lambda_opt_arity_check_exact_0080 ;	 if equal, go to exact arity
	jg .L_lambda_opt_arity_check_more_0080 ;	 if greater than, go to arity more
	push qword [rsp + 8 * 2] ;	 else, throw opt arity error
	push 0
	jmp L_error_incorrect_arity_opt
.L_lambda_opt_arity_check_exact_0080:
	mov rax, qword [rsp + 8 * 2] ;	 number of args
	lea rbx, [rsp + 8 * (2 + rax)] ;	 address of last element
	sub rsp, 8
	lea rcx, [rsp + 0] ;	 new start
.L_lambda_opt_shift_entry_0080:
	mov rdx, [rcx + 8]
	mov [rcx], rdx
	add rcx, 8
	cmp rbx, rcx
	jne .L_lambda_opt_shift_entry_0080
.L_lambda_opt_shift_exit_0080:
	mov qword[rbx], sob_nil ;	 place nil
	add rax, 1
	mov qword [rsp + 8 * 2], rax
	jmp .L_lambda_opt_stack_adjusted_0080
.L_lambda_opt_arity_check_more_0080:
	mov rdx, sob_nil ;	 base cdr
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_opt_stack_shrink_loop_exit_0080
.L_lambda_opt_stack_shrink_loop_0080:
	mov rdi, (1 + 8 + 8)
	call malloc
	mov byte[rax], T_pair
	mov SOB_PAIR_CDR(rax), rdx
	mov rdx, rax
	mov rax, qword [rsp + 8 * 2]
	mov rbx, qword [rsp + 8 * (2 + rax)]
	mov SOB_PAIR_CAR(rdx), rbx
	lea rbx, [rsp + 8 * (2 + rax - 1)]
.L_lambda_opt_extra_shift_process_0080:
	mov rcx, [rbx]
	mov [rbx + 8], rcx
	sub rbx, 8
	cmp rsp, rbx
	jle .L_lambda_opt_extra_shift_process_0080
.L_lambda_opt_extra_shift_process_end_0080:
	add rsp, 8
	mov rbx, [rsp + 8 * 2]
	sub rbx, 1
	mov [rsp + 8 * 2], rbx
	cmp qword [rsp + 8 * 2], 1
	jg .L_lambda_opt_stack_shrink_loop_0080
.L_lambda_opt_stack_shrink_loop_exit_0080:
	mov rcx, [rsp + 8 * 2]
	mov rbx, qword [rsp + 8 * (2 + rcx)]
	mov rdi, (1 + 8 + 8)
	call malloc
	mov byte[rax], T_pair
	mov SOB_PAIR_CDR(rax), rdx
	mov SOB_PAIR_CAR(rax), rbx
	mov [rsp + 8 * (2 + rcx)], rax
.L_lambda_opt_stack_adjusted_0080:
	enter 0, 0
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param s
	push rax
	push 1	; arg count
	mov rax, qword [free_var_126]	; free var null?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_02b8
	mov rax, L_constants + 1
	jmp .L_if_end_02b8
.L_if_else_02b8:
	; preparing a tail-call
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param s
	push rax
	push 1	; arg count
	mov rax, qword [free_var_69]	; free var cdr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param s
	push rax
	push 1	; arg count
	mov rax, qword [free_var_54]	; free var car
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 2	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var run-1
	mov rax, qword [rax]
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; old return address
	push qword [rbp]	; old frame-pointer
	mov rcx, 6
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8]
.L_tc_recycle_frame_loop_04eb:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_04eb
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8
	sub rdx, 8
	jmp .L_tc_recycle_frame_loop_04eb
.L_tc_recycle_frame_done_04eb:
	lea rsp, [rbx + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
.L_if_end_02b8:
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_opt_end_0080:	; new closure is in rax
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_simple_end_03d0:	; new closure is in rax
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	mov qword [free_var_32], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void

	; preparing a non-tail-call
	mov rax, L_constants + 2335
	push rax
	push 1	; arg count
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 0	; new rib
	call malloc
	push rax
	mov rdi, 8 * 1	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_03d3:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_03d3
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_03d3
.L_lambda_simple_env_end_03d3:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_03d3:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_03d3
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_03d3
.L_lambda_simple_params_end_03d3:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_03d3
	jmp .L_lambda_simple_end_03d3
.L_lambda_simple_code_03d3:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_03d3
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_03d3:
	enter 0, 0

	mov rdi, 8
	call malloc
	mov rbx, PARAM(0)	; param run
	mov [rax], rbx	; box run
	mov PARAM(0), rax	; replace param with box
	mov rax, sob_void

	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 1	; new rib
	call malloc
	push rax
	mov rdi, 8 * 2	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_03d4:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
	je .L_lambda_simple_env_end_03d4
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_03d4
.L_lambda_simple_env_end_03d4:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_03d4:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_03d4
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_03d4
.L_lambda_simple_params_end_03d4:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_03d4
	jmp .L_lambda_simple_end_03d4
.L_lambda_simple_code_03d4:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 3
	je .L_lambda_simple_arity_check_ok_03d4
	push qword [rsp + 8 * 2]
	push 3
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_03d4:
	enter 0, 0
	; preparing a non-tail-call
	mov rax, PARAM(2)	; param ss
	push rax
	mov rax, qword [free_var_126]	; free var null?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	push rax
	push 2	; arg count
	mov rax, qword [free_var_130]	; free var ormap
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_02b9
	mov rax, PARAM(1)	; param unit
	jmp .L_if_end_02b9
.L_if_else_02b9:
	; preparing a tail-call
	; preparing a non-tail-call
	mov rax, PARAM(2)	; param ss
	push rax
	mov rax, qword [free_var_69]	; free var cdr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	push rax
	push 2	; arg count
	mov rax, qword [free_var_122]	; free var map
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	; preparing a non-tail-call
	; preparing a non-tail-call
	mov rax, PARAM(2)	; param ss
	push rax
	mov rax, qword [free_var_54]	; free var car
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	push rax
	push 2	; arg count
	mov rax, qword [free_var_122]	; free var map
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	mov rax, PARAM(1)	; param unit
	push rax
	mov rax, PARAM(0)	; param f
	push rax
	push 3	; arg count
	mov rax, qword [free_var_33]	; free var apply
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	mov rax, PARAM(0)	; param f
	push rax
	push 3	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var run
	mov rax, qword [rax]
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; old return address
	push qword [rbp]	; old frame-pointer
	mov rcx, 7
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8]
.L_tc_recycle_frame_loop_04ec:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_04ec
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8
	sub rdx, 8
	jmp .L_tc_recycle_frame_loop_04ec
.L_tc_recycle_frame_done_04ec:
	lea rsp, [rbx + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
.L_if_end_02b9:
	leave
	ret AND_KILL_FRAME(3)
.L_lambda_simple_end_03d4:	; new closure is in rax

	push rax
	mov rax, PARAM(0)	; param run

	pop qword[rax]
	mov rax, sob_void

	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 1	; new rib
	call malloc
	push rax
	mov rdi, 8 * 2	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_opt_env_loop_0081:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
	je .L_lambda_opt_env_end_0081
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_opt_env_loop_0081
.L_lambda_opt_env_end_0081:
	pop rbx
	mov rsi, 0
.L_lambda_opt_params_loop_0081:	; copy params
	cmp rsi, 1
	je .L_lambda_opt_params_end_0081
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_opt_params_loop_0081
.L_lambda_opt_params_end_0081:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_opt_code_0081
	jmp .L_lambda_opt_end_0081
.L_lambda_opt_code_0081:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 2 ;	 check num of args
	je .L_lambda_opt_arity_check_exact_0081 ;	 if equal, go to exact arity
	jg .L_lambda_opt_arity_check_more_0081 ;	 if greater than, go to arity more
	push qword [rsp + 8 * 2] ;	 else, throw opt arity error
	push 2
	jmp L_error_incorrect_arity_opt
.L_lambda_opt_arity_check_exact_0081:
	mov rax, qword [rsp + 8 * 2] ;	 number of args
	lea rbx, [rsp + 8 * (2 + rax)] ;	 address of last element
	sub rsp, 8
	lea rcx, [rsp + 0] ;	 new start
.L_lambda_opt_shift_entry_0081:
	mov rdx, [rcx + 8]
	mov [rcx], rdx
	add rcx, 8
	cmp rbx, rcx
	jne .L_lambda_opt_shift_entry_0081
.L_lambda_opt_shift_exit_0081:
	mov qword[rbx], sob_nil ;	 place nil
	add rax, 1
	mov qword [rsp + 8 * 2], rax
	jmp .L_lambda_opt_stack_adjusted_0081
.L_lambda_opt_arity_check_more_0081:
	mov rdx, sob_nil ;	 base cdr
	cmp qword [rsp + 8 * 2], 3
	je .L_lambda_opt_stack_shrink_loop_exit_0081
.L_lambda_opt_stack_shrink_loop_0081:
	mov rdi, (1 + 8 + 8)
	call malloc
	mov byte[rax], T_pair
	mov SOB_PAIR_CDR(rax), rdx
	mov rdx, rax
	mov rax, qword [rsp + 8 * 2]
	mov rbx, qword [rsp + 8 * (2 + rax)]
	mov SOB_PAIR_CAR(rdx), rbx
	lea rbx, [rsp + 8 * (2 + rax - 1)]
.L_lambda_opt_extra_shift_process_0081:
	mov rcx, [rbx]
	mov [rbx + 8], rcx
	sub rbx, 8
	cmp rsp, rbx
	jle .L_lambda_opt_extra_shift_process_0081
.L_lambda_opt_extra_shift_process_end_0081:
	add rsp, 8
	mov rbx, [rsp + 8 * 2]
	sub rbx, 1
	mov [rsp + 8 * 2], rbx
	cmp qword [rsp + 8 * 2], 3
	jg .L_lambda_opt_stack_shrink_loop_0081
.L_lambda_opt_stack_shrink_loop_exit_0081:
	mov rcx, [rsp + 8 * 2]
	mov rbx, qword [rsp + 8 * (2 + rcx)]
	mov rdi, (1 + 8 + 8)
	call malloc
	mov byte[rax], T_pair
	mov SOB_PAIR_CDR(rax), rdx
	mov SOB_PAIR_CAR(rax), rbx
	mov [rsp + 8 * (2 + rcx)], rax
.L_lambda_opt_stack_adjusted_0081:
	enter 0, 0
	; preparing a tail-call
	mov rax, PARAM(2)	; param ss
	push rax
	mov rax, PARAM(1)	; param unit
	push rax
	mov rax, PARAM(0)	; param f
	push rax
	push 3	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var run
	mov rax, qword [rax]
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; old return address
	push qword [rbp]	; old frame-pointer
	mov rcx, 7
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8]
.L_tc_recycle_frame_loop_04ed:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_04ed
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8
	sub rdx, 8
	jmp .L_tc_recycle_frame_loop_04ed
.L_tc_recycle_frame_done_04ed:
	lea rsp, [rbx + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(3)
.L_lambda_opt_end_0081:	; new closure is in rax
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_03d3:	; new closure is in rax
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	mov qword [free_var_94], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void

	; preparing a non-tail-call
	mov rax, L_constants + 2335
	push rax
	push 1	; arg count
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 0	; new rib
	call malloc
	push rax
	mov rdi, 8 * 1	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_03d5:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_03d5
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_03d5
.L_lambda_simple_env_end_03d5:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_03d5:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_03d5
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_03d5
.L_lambda_simple_params_end_03d5:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_03d5
	jmp .L_lambda_simple_end_03d5
.L_lambda_simple_code_03d5:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_03d5
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_03d5:
	enter 0, 0

	mov rdi, 8
	call malloc
	mov rbx, PARAM(0)	; param run
	mov [rax], rbx	; box run
	mov PARAM(0), rax	; replace param with box
	mov rax, sob_void

	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 1	; new rib
	call malloc
	push rax
	mov rdi, 8 * 2	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_03d6:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
	je .L_lambda_simple_env_end_03d6
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_03d6
.L_lambda_simple_env_end_03d6:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_03d6:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_03d6
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_03d6
.L_lambda_simple_params_end_03d6:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_03d6
	jmp .L_lambda_simple_end_03d6
.L_lambda_simple_code_03d6:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 3
	je .L_lambda_simple_arity_check_ok_03d6
	push qword [rsp + 8 * 2]
	push 3
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_03d6:
	enter 0, 0
	; preparing a non-tail-call
	mov rax, PARAM(2)	; param ss
	push rax
	mov rax, qword [free_var_126]	; free var null?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	push rax
	push 2	; arg count
	mov rax, qword [free_var_130]	; free var ormap
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_02ba
	mov rax, PARAM(1)	; param unit
	jmp .L_if_end_02ba
.L_if_else_02ba:
	; preparing a tail-call
	; preparing a non-tail-call
	; preparing a non-tail-call
	mov rax, L_constants + 1
	push rax
	; preparing a non-tail-call
	; preparing a non-tail-call
	mov rax, PARAM(2)	; param ss
	push rax
	mov rax, qword [free_var_69]	; free var cdr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	push rax
	push 2	; arg count
	mov rax, qword [free_var_122]	; free var map
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	mov rax, PARAM(1)	; param unit
	push rax
	mov rax, PARAM(0)	; param f
	push rax
	push 3	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var run
	mov rax, qword [rax]
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 2	; arg count
	mov rax, qword [free_var_85]	; free var cons
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	; preparing a non-tail-call
	mov rax, PARAM(2)	; param ss
	push rax
	mov rax, qword [free_var_54]	; free var car
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	push rax
	push 2	; arg count
	mov rax, qword [free_var_122]	; free var map
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 2	; arg count
	mov rax, qword [free_var_32]	; free var append
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	mov rax, PARAM(0)	; param f
	push rax
	push 2	; arg count
	mov rax, qword [free_var_33]	; free var apply
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; old return address
	push qword [rbp]	; old frame-pointer
	mov rcx, 6
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8]
.L_tc_recycle_frame_loop_04ee:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_04ee
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8
	sub rdx, 8
	jmp .L_tc_recycle_frame_loop_04ee
.L_tc_recycle_frame_done_04ee:
	lea rsp, [rbx + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
.L_if_end_02ba:
	leave
	ret AND_KILL_FRAME(3)
.L_lambda_simple_end_03d6:	; new closure is in rax

	push rax
	mov rax, PARAM(0)	; param run

	pop qword[rax]
	mov rax, sob_void

	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 1	; new rib
	call malloc
	push rax
	mov rdi, 8 * 2	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_opt_env_loop_0082:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
	je .L_lambda_opt_env_end_0082
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_opt_env_loop_0082
.L_lambda_opt_env_end_0082:
	pop rbx
	mov rsi, 0
.L_lambda_opt_params_loop_0082:	; copy params
	cmp rsi, 1
	je .L_lambda_opt_params_end_0082
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_opt_params_loop_0082
.L_lambda_opt_params_end_0082:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_opt_code_0082
	jmp .L_lambda_opt_end_0082
.L_lambda_opt_code_0082:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 2 ;	 check num of args
	je .L_lambda_opt_arity_check_exact_0082 ;	 if equal, go to exact arity
	jg .L_lambda_opt_arity_check_more_0082 ;	 if greater than, go to arity more
	push qword [rsp + 8 * 2] ;	 else, throw opt arity error
	push 2
	jmp L_error_incorrect_arity_opt
.L_lambda_opt_arity_check_exact_0082:
	mov rax, qword [rsp + 8 * 2] ;	 number of args
	lea rbx, [rsp + 8 * (2 + rax)] ;	 address of last element
	sub rsp, 8
	lea rcx, [rsp + 0] ;	 new start
.L_lambda_opt_shift_entry_0082:
	mov rdx, [rcx + 8]
	mov [rcx], rdx
	add rcx, 8
	cmp rbx, rcx
	jne .L_lambda_opt_shift_entry_0082
.L_lambda_opt_shift_exit_0082:
	mov qword[rbx], sob_nil ;	 place nil
	add rax, 1
	mov qword [rsp + 8 * 2], rax
	jmp .L_lambda_opt_stack_adjusted_0082
.L_lambda_opt_arity_check_more_0082:
	mov rdx, sob_nil ;	 base cdr
	cmp qword [rsp + 8 * 2], 3
	je .L_lambda_opt_stack_shrink_loop_exit_0082
.L_lambda_opt_stack_shrink_loop_0082:
	mov rdi, (1 + 8 + 8)
	call malloc
	mov byte[rax], T_pair
	mov SOB_PAIR_CDR(rax), rdx
	mov rdx, rax
	mov rax, qword [rsp + 8 * 2]
	mov rbx, qword [rsp + 8 * (2 + rax)]
	mov SOB_PAIR_CAR(rdx), rbx
	lea rbx, [rsp + 8 * (2 + rax - 1)]
.L_lambda_opt_extra_shift_process_0082:
	mov rcx, [rbx]
	mov [rbx + 8], rcx
	sub rbx, 8
	cmp rsp, rbx
	jle .L_lambda_opt_extra_shift_process_0082
.L_lambda_opt_extra_shift_process_end_0082:
	add rsp, 8
	mov rbx, [rsp + 8 * 2]
	sub rbx, 1
	mov [rsp + 8 * 2], rbx
	cmp qword [rsp + 8 * 2], 3
	jg .L_lambda_opt_stack_shrink_loop_0082
.L_lambda_opt_stack_shrink_loop_exit_0082:
	mov rcx, [rsp + 8 * 2]
	mov rbx, qword [rsp + 8 * (2 + rcx)]
	mov rdi, (1 + 8 + 8)
	call malloc
	mov byte[rax], T_pair
	mov SOB_PAIR_CDR(rax), rdx
	mov SOB_PAIR_CAR(rax), rbx
	mov [rsp + 8 * (2 + rcx)], rax
.L_lambda_opt_stack_adjusted_0082:
	enter 0, 0
	; preparing a tail-call
	mov rax, PARAM(2)	; param ss
	push rax
	mov rax, PARAM(1)	; param unit
	push rax
	mov rax, PARAM(0)	; param f
	push rax
	push 3	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var run
	mov rax, qword [rax]
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; old return address
	push qword [rbp]	; old frame-pointer
	mov rcx, 7
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8]
.L_tc_recycle_frame_loop_04ef:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_04ef
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8
	sub rdx, 8
	jmp .L_tc_recycle_frame_loop_04ef
.L_tc_recycle_frame_done_04ef:
	lea rsp, [rbx + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(3)
.L_lambda_opt_end_0082:	; new closure is in rax
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_03d5:	; new closure is in rax
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	mov qword [free_var_95], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void

	; preparing a non-tail-call
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 0	; new rib
	call malloc
	push rax
	mov rdi, 8 * 1	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_03d7:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_03d7
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_03d7
.L_lambda_simple_env_end_03d7:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_03d7:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_03d7
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_03d7
.L_lambda_simple_params_end_03d7:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_03d7
	jmp .L_lambda_simple_end_03d7
.L_lambda_simple_code_03d7:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 0
	je .L_lambda_simple_arity_check_ok_03d7
	push qword [rsp + 8 * 2]
	push 0
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_03d7:
	enter 0, 0
	; preparing a tail-call
	mov rax, L_constants + 2691
	push rax
	mov rax, L_constants + 2682
	push rax
	push 2	; arg count
	mov rax, qword [free_var_90]	; free var error
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; old return address
	push qword [rbp]	; old frame-pointer
	mov rcx, 6
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8]
.L_tc_recycle_frame_loop_04f0:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_04f0
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8
	sub rdx, 8
	jmp .L_tc_recycle_frame_loop_04f0
.L_tc_recycle_frame_done_04f0:
	lea rsp, [rbx + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(0)
.L_lambda_simple_end_03d7:	; new closure is in rax
	push rax
	push 1	; arg count
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 0	; new rib
	call malloc
	push rax
	mov rdi, 8 * 1	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_03d8:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_03d8
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_03d8
.L_lambda_simple_env_end_03d8:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_03d8:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_03d8
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_03d8
.L_lambda_simple_params_end_03d8:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_03d8
	jmp .L_lambda_simple_end_03d8
.L_lambda_simple_code_03d8:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_03d8
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_03d8:
	enter 0, 0
	; preparing a tail-call
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 1	; new rib
	call malloc
	push rax
	mov rdi, 8 * 2	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_03d9:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
	je .L_lambda_simple_env_end_03d9
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_03d9
.L_lambda_simple_env_end_03d9:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_03d9:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_03d9
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_03d9
.L_lambda_simple_params_end_03d9:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_03d9
	jmp .L_lambda_simple_end_03d9
.L_lambda_simple_code_03d9:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 2
	je .L_lambda_simple_arity_check_ok_03d9
	push qword [rsp + 8 * 2]
	push 2
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_03d9:
	enter 0, 0
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param a
	push rax
	push 1	; arg count
	mov rax, qword [free_var_103]	; free var integer?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_02c6
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param b
	push rax
	push 1	; arg count
	mov rax, qword [free_var_103]	; free var integer?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_02bd
	; preparing a tail-call
	mov rax, PARAM(1)	; param b
	push rax
	mov rax, PARAM(0)	; param a
	push rax
	push 2	; arg count
	mov rax, qword [free_var_11]	; free var __bin-add-zz
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; old return address
	push qword [rbp]	; old frame-pointer
	mov rcx, 6
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8]
.L_tc_recycle_frame_loop_04f1:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_04f1
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8
	sub rdx, 8
	jmp .L_tc_recycle_frame_loop_04f1
.L_tc_recycle_frame_done_04f1:
	lea rsp, [rbx + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_02bd
.L_if_else_02bd:
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param b
	push rax
	push 1	; arg count
	mov rax, qword [free_var_97]	; free var fraction?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_02bc
	; preparing a tail-call
	mov rax, PARAM(1)	; param b
	push rax
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param a
	push rax
	push 1	; arg count
	mov rax, qword [free_var_29]	; free var __integer-to-fraction
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 2	; arg count
	mov rax, qword [free_var_9]	; free var __bin-add-qq
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; old return address
	push qword [rbp]	; old frame-pointer
	mov rcx, 6
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8]
.L_tc_recycle_frame_loop_04f2:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_04f2
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8
	sub rdx, 8
	jmp .L_tc_recycle_frame_loop_04f2
.L_tc_recycle_frame_done_04f2:
	lea rsp, [rbx + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_02bc
.L_if_else_02bc:
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param b
	push rax
	push 1	; arg count
	mov rax, qword [free_var_140]	; free var real?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_02bb
	; preparing a tail-call
	mov rax, PARAM(1)	; param b
	push rax
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param a
	push rax
	push 1	; arg count
	mov rax, qword [free_var_102]	; free var integer->real
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 2	; arg count
	mov rax, qword [free_var_10]	; free var __bin-add-rr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; old return address
	push qword [rbp]	; old frame-pointer
	mov rcx, 6
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8]
.L_tc_recycle_frame_loop_04f3:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_04f3
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8
	sub rdx, 8
	jmp .L_tc_recycle_frame_loop_04f3
.L_tc_recycle_frame_done_04f3:
	lea rsp, [rbx + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_02bb
.L_if_else_02bb:
	; preparing a tail-call
	push 0	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var error
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; old return address
	push qword [rbp]	; old frame-pointer
	mov rcx, 4
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8]
.L_tc_recycle_frame_loop_04f4:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_04f4
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8
	sub rdx, 8
	jmp .L_tc_recycle_frame_loop_04f4
.L_tc_recycle_frame_done_04f4:
	lea rsp, [rbx + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
.L_if_end_02bb:
.L_if_end_02bc:
.L_if_end_02bd:
	jmp .L_if_end_02c6
.L_if_else_02c6:
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param a
	push rax
	push 1	; arg count
	mov rax, qword [free_var_97]	; free var fraction?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_02c5
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param b
	push rax
	push 1	; arg count
	mov rax, qword [free_var_103]	; free var integer?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_02c0
	; preparing a tail-call
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param b
	push rax
	push 1	; arg count
	mov rax, qword [free_var_28]	; free var __bin_integer_to_fraction
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	mov rax, PARAM(0)	; param a
	push rax
	push 2	; arg count
	mov rax, qword [free_var_9]	; free var __bin-add-qq
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; old return address
	push qword [rbp]	; old frame-pointer
	mov rcx, 6
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8]
.L_tc_recycle_frame_loop_04f5:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_04f5
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8
	sub rdx, 8
	jmp .L_tc_recycle_frame_loop_04f5
.L_tc_recycle_frame_done_04f5:
	lea rsp, [rbx + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_02c0
.L_if_else_02c0:
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param b
	push rax
	push 1	; arg count
	mov rax, qword [free_var_97]	; free var fraction?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_02bf
	; preparing a tail-call
	mov rax, PARAM(1)	; param b
	push rax
	mov rax, PARAM(0)	; param a
	push rax
	push 2	; arg count
	mov rax, qword [free_var_9]	; free var __bin-add-qq
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; old return address
	push qword [rbp]	; old frame-pointer
	mov rcx, 6
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8]
.L_tc_recycle_frame_loop_04f6:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_04f6
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8
	sub rdx, 8
	jmp .L_tc_recycle_frame_loop_04f6
.L_tc_recycle_frame_done_04f6:
	lea rsp, [rbx + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_02bf
.L_if_else_02bf:
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param b
	push rax
	push 1	; arg count
	mov rax, qword [free_var_140]	; free var real?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_02be
	; preparing a tail-call
	mov rax, PARAM(1)	; param b
	push rax
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param a
	push rax
	push 1	; arg count
	mov rax, qword [free_var_96]	; free var fraction->real
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 2	; arg count
	mov rax, qword [free_var_10]	; free var __bin-add-rr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; old return address
	push qword [rbp]	; old frame-pointer
	mov rcx, 6
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8]
.L_tc_recycle_frame_loop_04f7:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_04f7
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8
	sub rdx, 8
	jmp .L_tc_recycle_frame_loop_04f7
.L_tc_recycle_frame_done_04f7:
	lea rsp, [rbx + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_02be
.L_if_else_02be:
	; preparing a tail-call
	push 0	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var error
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; old return address
	push qword [rbp]	; old frame-pointer
	mov rcx, 4
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8]
.L_tc_recycle_frame_loop_04f8:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_04f8
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8
	sub rdx, 8
	jmp .L_tc_recycle_frame_loop_04f8
.L_tc_recycle_frame_done_04f8:
	lea rsp, [rbx + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
.L_if_end_02be:
.L_if_end_02bf:
.L_if_end_02c0:
	jmp .L_if_end_02c5
.L_if_else_02c5:
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param a
	push rax
	push 1	; arg count
	mov rax, qword [free_var_140]	; free var real?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_02c4
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param b
	push rax
	push 1	; arg count
	mov rax, qword [free_var_103]	; free var integer?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_02c3
	; preparing a tail-call
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param b
	push rax
	push 1	; arg count
	mov rax, qword [free_var_102]	; free var integer->real
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	mov rax, PARAM(0)	; param a
	push rax
	push 2	; arg count
	mov rax, qword [free_var_10]	; free var __bin-add-rr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; old return address
	push qword [rbp]	; old frame-pointer
	mov rcx, 6
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8]
.L_tc_recycle_frame_loop_04f9:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_04f9
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8
	sub rdx, 8
	jmp .L_tc_recycle_frame_loop_04f9
.L_tc_recycle_frame_done_04f9:
	lea rsp, [rbx + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_02c3
.L_if_else_02c3:
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param b
	push rax
	push 1	; arg count
	mov rax, qword [free_var_97]	; free var fraction?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_02c2
	; preparing a tail-call
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param b
	push rax
	push 1	; arg count
	mov rax, qword [free_var_96]	; free var fraction->real
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	mov rax, PARAM(0)	; param a
	push rax
	push 2	; arg count
	mov rax, qword [free_var_10]	; free var __bin-add-rr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; old return address
	push qword [rbp]	; old frame-pointer
	mov rcx, 6
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8]
.L_tc_recycle_frame_loop_04fa:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_04fa
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8
	sub rdx, 8
	jmp .L_tc_recycle_frame_loop_04fa
.L_tc_recycle_frame_done_04fa:
	lea rsp, [rbx + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_02c2
.L_if_else_02c2:
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param b
	push rax
	push 1	; arg count
	mov rax, qword [free_var_140]	; free var real?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_02c1
	; preparing a tail-call
	mov rax, PARAM(1)	; param b
	push rax
	mov rax, PARAM(0)	; param a
	push rax
	push 2	; arg count
	mov rax, qword [free_var_10]	; free var __bin-add-rr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; old return address
	push qword [rbp]	; old frame-pointer
	mov rcx, 6
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8]
.L_tc_recycle_frame_loop_04fb:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_04fb
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8
	sub rdx, 8
	jmp .L_tc_recycle_frame_loop_04fb
.L_tc_recycle_frame_done_04fb:
	lea rsp, [rbx + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_02c1
.L_if_else_02c1:
	; preparing a tail-call
	push 0	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var error
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; old return address
	push qword [rbp]	; old frame-pointer
	mov rcx, 4
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8]
.L_tc_recycle_frame_loop_04fc:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_04fc
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8
	sub rdx, 8
	jmp .L_tc_recycle_frame_loop_04fc
.L_tc_recycle_frame_done_04fc:
	lea rsp, [rbx + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
.L_if_end_02c1:
.L_if_end_02c2:
.L_if_end_02c3:
	jmp .L_if_end_02c4
.L_if_else_02c4:
	; preparing a tail-call
	push 0	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var error
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; old return address
	push qword [rbp]	; old frame-pointer
	mov rcx, 4
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8]
.L_tc_recycle_frame_loop_04fd:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_04fd
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8
	sub rdx, 8
	jmp .L_tc_recycle_frame_loop_04fd
.L_tc_recycle_frame_done_04fd:
	lea rsp, [rbx + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
.L_if_end_02c4:
.L_if_end_02c5:
.L_if_end_02c6:
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_simple_end_03d9:	; new closure is in rax
	push rax
	push 1	; arg count
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 1	; new rib
	call malloc
	push rax
	mov rdi, 8 * 2	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_03da:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
	je .L_lambda_simple_env_end_03da
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_03da
.L_lambda_simple_env_end_03da:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_03da:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_03da
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_03da
.L_lambda_simple_params_end_03da:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_03da
	jmp .L_lambda_simple_end_03da
.L_lambda_simple_code_03da:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_03da
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_03da:
	enter 0, 0
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 1	; new rib
	call malloc
	push rax
	mov rdi, 8 * 3	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_opt_env_loop_0083:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 2
	je .L_lambda_opt_env_end_0083
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_opt_env_loop_0083
.L_lambda_opt_env_end_0083:
	pop rbx
	mov rsi, 0
.L_lambda_opt_params_loop_0083:	; copy params
	cmp rsi, 1
	je .L_lambda_opt_params_end_0083
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_opt_params_loop_0083
.L_lambda_opt_params_end_0083:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_opt_code_0083
	jmp .L_lambda_opt_end_0083
.L_lambda_opt_code_0083:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 0 ;	 check num of args
	je .L_lambda_opt_arity_check_exact_0083 ;	 if equal, go to exact arity
	jg .L_lambda_opt_arity_check_more_0083 ;	 if greater than, go to arity more
	push qword [rsp + 8 * 2] ;	 else, throw opt arity error
	push 0
	jmp L_error_incorrect_arity_opt
.L_lambda_opt_arity_check_exact_0083:
	mov rax, qword [rsp + 8 * 2] ;	 number of args
	lea rbx, [rsp + 8 * (2 + rax)] ;	 address of last element
	sub rsp, 8
	lea rcx, [rsp + 0] ;	 new start
.L_lambda_opt_shift_entry_0083:
	mov rdx, [rcx + 8]
	mov [rcx], rdx
	add rcx, 8
	cmp rbx, rcx
	jne .L_lambda_opt_shift_entry_0083
.L_lambda_opt_shift_exit_0083:
	mov qword[rbx], sob_nil ;	 place nil
	add rax, 1
	mov qword [rsp + 8 * 2], rax
	jmp .L_lambda_opt_stack_adjusted_0083
.L_lambda_opt_arity_check_more_0083:
	mov rdx, sob_nil ;	 base cdr
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_opt_stack_shrink_loop_exit_0083
.L_lambda_opt_stack_shrink_loop_0083:
	mov rdi, (1 + 8 + 8)
	call malloc
	mov byte[rax], T_pair
	mov SOB_PAIR_CDR(rax), rdx
	mov rdx, rax
	mov rax, qword [rsp + 8 * 2]
	mov rbx, qword [rsp + 8 * (2 + rax)]
	mov SOB_PAIR_CAR(rdx), rbx
	lea rbx, [rsp + 8 * (2 + rax - 1)]
.L_lambda_opt_extra_shift_process_0083:
	mov rcx, [rbx]
	mov [rbx + 8], rcx
	sub rbx, 8
	cmp rsp, rbx
	jle .L_lambda_opt_extra_shift_process_0083
.L_lambda_opt_extra_shift_process_end_0083:
	add rsp, 8
	mov rbx, [rsp + 8 * 2]
	sub rbx, 1
	mov [rsp + 8 * 2], rbx
	cmp qword [rsp + 8 * 2], 1
	jg .L_lambda_opt_stack_shrink_loop_0083
.L_lambda_opt_stack_shrink_loop_exit_0083:
	mov rcx, [rsp + 8 * 2]
	mov rbx, qword [rsp + 8 * (2 + rcx)]
	mov rdi, (1 + 8 + 8)
	call malloc
	mov byte[rax], T_pair
	mov SOB_PAIR_CDR(rax), rdx
	mov SOB_PAIR_CAR(rax), rbx
	mov [rsp + 8 * (2 + rcx)], rax
.L_lambda_opt_stack_adjusted_0083:
	enter 0, 0
	; preparing a tail-call
	mov rax, PARAM(0)	; param s
	push rax
	mov rax, L_constants + 2558
	push rax
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var bin+
	push rax
	push 3	; arg count
	mov rax, qword [free_var_94]	; free var fold-left
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; old return address
	push qword [rbp]	; old frame-pointer
	mov rcx, 7
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8]
.L_tc_recycle_frame_loop_04fe:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_04fe
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8
	sub rdx, 8
	jmp .L_tc_recycle_frame_loop_04fe
.L_tc_recycle_frame_done_04fe:
	lea rsp, [rbx + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_opt_end_0083:	; new closure is in rax
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_03da:	; new closure is in rax
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; old return address
	push qword [rbp]	; old frame-pointer
	mov rcx, 5
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8]
.L_tc_recycle_frame_loop_04ff:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_04ff
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8
	sub rdx, 8
	jmp .L_tc_recycle_frame_loop_04ff
.L_tc_recycle_frame_done_04ff:
	lea rsp, [rbx + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_03d8:	; new closure is in rax
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	mov qword [free_var_1], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void

	; preparing a non-tail-call
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 0	; new rib
	call malloc
	push rax
	mov rdi, 8 * 1	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_03db:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_03db
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_03db
.L_lambda_simple_env_end_03db:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_03db:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_03db
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_03db
.L_lambda_simple_params_end_03db:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_03db
	jmp .L_lambda_simple_end_03db
.L_lambda_simple_code_03db:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 0
	je .L_lambda_simple_arity_check_ok_03db
	push qword [rsp + 8 * 2]
	push 0
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_03db:
	enter 0, 0
	; preparing a tail-call
	mov rax, L_constants + 2691
	push rax
	mov rax, L_constants + 2791
	push rax
	push 2	; arg count
	mov rax, qword [free_var_90]	; free var error
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; old return address
	push qword [rbp]	; old frame-pointer
	mov rcx, 6
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8]
.L_tc_recycle_frame_loop_0500:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0500
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8
	sub rdx, 8
	jmp .L_tc_recycle_frame_loop_0500
.L_tc_recycle_frame_done_0500:
	lea rsp, [rbx + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(0)
.L_lambda_simple_end_03db:	; new closure is in rax
	push rax
	push 1	; arg count
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 0	; new rib
	call malloc
	push rax
	mov rdi, 8 * 1	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_03dc:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_03dc
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_03dc
.L_lambda_simple_env_end_03dc:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_03dc:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_03dc
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_03dc
.L_lambda_simple_params_end_03dc:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_03dc
	jmp .L_lambda_simple_end_03dc
.L_lambda_simple_code_03dc:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_03dc
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_03dc:
	enter 0, 0
	; preparing a tail-call
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 1	; new rib
	call malloc
	push rax
	mov rdi, 8 * 2	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_03dd:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
	je .L_lambda_simple_env_end_03dd
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_03dd
.L_lambda_simple_env_end_03dd:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_03dd:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_03dd
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_03dd
.L_lambda_simple_params_end_03dd:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_03dd
	jmp .L_lambda_simple_end_03dd
.L_lambda_simple_code_03dd:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 2
	je .L_lambda_simple_arity_check_ok_03dd
	push qword [rsp + 8 * 2]
	push 2
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_03dd:
	enter 0, 0
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param a
	push rax
	push 1	; arg count
	mov rax, qword [free_var_103]	; free var integer?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_02d2
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param b
	push rax
	push 1	; arg count
	mov rax, qword [free_var_103]	; free var integer?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_02c9
	; preparing a tail-call
	mov rax, PARAM(1)	; param b
	push rax
	mov rax, PARAM(0)	; param a
	push rax
	push 2	; arg count
	mov rax, qword [free_var_27]	; free var __bin-sub-zz
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; old return address
	push qword [rbp]	; old frame-pointer
	mov rcx, 6
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8]
.L_tc_recycle_frame_loop_0501:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0501
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8
	sub rdx, 8
	jmp .L_tc_recycle_frame_loop_0501
.L_tc_recycle_frame_done_0501:
	lea rsp, [rbx + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_02c9
.L_if_else_02c9:
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param b
	push rax
	push 1	; arg count
	mov rax, qword [free_var_97]	; free var fraction?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_02c8
	; preparing a tail-call
	mov rax, PARAM(1)	; param b
	push rax
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param a
	push rax
	push 1	; arg count
	mov rax, qword [free_var_29]	; free var __integer-to-fraction
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 2	; arg count
	mov rax, qword [free_var_25]	; free var __bin-sub-qq
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; old return address
	push qword [rbp]	; old frame-pointer
	mov rcx, 6
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8]
.L_tc_recycle_frame_loop_0502:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0502
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8
	sub rdx, 8
	jmp .L_tc_recycle_frame_loop_0502
.L_tc_recycle_frame_done_0502:
	lea rsp, [rbx + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_02c8
.L_if_else_02c8:
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param b
	push rax
	push 1	; arg count
	mov rax, qword [free_var_138]	; free var real
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_02c7
	; preparing a tail-call
	mov rax, PARAM(1)	; param b
	push rax
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param a
	push rax
	push 1	; arg count
	mov rax, qword [free_var_102]	; free var integer->real
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 2	; arg count
	mov rax, qword [free_var_26]	; free var __bin-sub-rr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; old return address
	push qword [rbp]	; old frame-pointer
	mov rcx, 6
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8]
.L_tc_recycle_frame_loop_0503:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0503
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8
	sub rdx, 8
	jmp .L_tc_recycle_frame_loop_0503
.L_tc_recycle_frame_done_0503:
	lea rsp, [rbx + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_02c7
.L_if_else_02c7:
	; preparing a tail-call
	push 0	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var error
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; old return address
	push qword [rbp]	; old frame-pointer
	mov rcx, 4
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8]
.L_tc_recycle_frame_loop_0504:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0504
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8
	sub rdx, 8
	jmp .L_tc_recycle_frame_loop_0504
.L_tc_recycle_frame_done_0504:
	lea rsp, [rbx + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
.L_if_end_02c7:
.L_if_end_02c8:
.L_if_end_02c9:
	jmp .L_if_end_02d2
.L_if_else_02d2:
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param a
	push rax
	push 1	; arg count
	mov rax, qword [free_var_97]	; free var fraction?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_02d1
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param b
	push rax
	push 1	; arg count
	mov rax, qword [free_var_103]	; free var integer?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_02cc
	; preparing a tail-call
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param b
	push rax
	push 1	; arg count
	mov rax, qword [free_var_29]	; free var __integer-to-fraction
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	mov rax, PARAM(0)	; param a
	push rax
	push 2	; arg count
	mov rax, qword [free_var_25]	; free var __bin-sub-qq
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; old return address
	push qword [rbp]	; old frame-pointer
	mov rcx, 6
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8]
.L_tc_recycle_frame_loop_0505:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0505
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8
	sub rdx, 8
	jmp .L_tc_recycle_frame_loop_0505
.L_tc_recycle_frame_done_0505:
	lea rsp, [rbx + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_02cc
.L_if_else_02cc:
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param b
	push rax
	push 1	; arg count
	mov rax, qword [free_var_97]	; free var fraction?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_02cb
	; preparing a tail-call
	mov rax, PARAM(1)	; param b
	push rax
	mov rax, PARAM(0)	; param a
	push rax
	push 2	; arg count
	mov rax, qword [free_var_25]	; free var __bin-sub-qq
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; old return address
	push qword [rbp]	; old frame-pointer
	mov rcx, 6
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8]
.L_tc_recycle_frame_loop_0506:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0506
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8
	sub rdx, 8
	jmp .L_tc_recycle_frame_loop_0506
.L_tc_recycle_frame_done_0506:
	lea rsp, [rbx + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_02cb
.L_if_else_02cb:
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param b
	push rax
	push 1	; arg count
	mov rax, qword [free_var_140]	; free var real?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_02ca
	; preparing a tail-call
	mov rax, PARAM(1)	; param b
	push rax
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param a
	push rax
	push 1	; arg count
	mov rax, qword [free_var_96]	; free var fraction->real
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 2	; arg count
	mov rax, qword [free_var_26]	; free var __bin-sub-rr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; old return address
	push qword [rbp]	; old frame-pointer
	mov rcx, 6
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8]
.L_tc_recycle_frame_loop_0507:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0507
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8
	sub rdx, 8
	jmp .L_tc_recycle_frame_loop_0507
.L_tc_recycle_frame_done_0507:
	lea rsp, [rbx + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_02ca
.L_if_else_02ca:
	; preparing a tail-call
	push 0	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var error
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; old return address
	push qword [rbp]	; old frame-pointer
	mov rcx, 4
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8]
.L_tc_recycle_frame_loop_0508:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0508
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8
	sub rdx, 8
	jmp .L_tc_recycle_frame_loop_0508
.L_tc_recycle_frame_done_0508:
	lea rsp, [rbx + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
.L_if_end_02ca:
.L_if_end_02cb:
.L_if_end_02cc:
	jmp .L_if_end_02d1
.L_if_else_02d1:
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param a
	push rax
	push 1	; arg count
	mov rax, qword [free_var_140]	; free var real?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_02d0
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param b
	push rax
	push 1	; arg count
	mov rax, qword [free_var_103]	; free var integer?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_02cf
	; preparing a tail-call
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param b
	push rax
	push 1	; arg count
	mov rax, qword [free_var_102]	; free var integer->real
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	mov rax, PARAM(0)	; param a
	push rax
	push 2	; arg count
	mov rax, qword [free_var_26]	; free var __bin-sub-rr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; old return address
	push qword [rbp]	; old frame-pointer
	mov rcx, 6
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8]
.L_tc_recycle_frame_loop_0509:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0509
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8
	sub rdx, 8
	jmp .L_tc_recycle_frame_loop_0509
.L_tc_recycle_frame_done_0509:
	lea rsp, [rbx + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_02cf
.L_if_else_02cf:
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param b
	push rax
	push 1	; arg count
	mov rax, qword [free_var_97]	; free var fraction?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_02ce
	; preparing a tail-call
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param b
	push rax
	push 1	; arg count
	mov rax, qword [free_var_96]	; free var fraction->real
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	mov rax, PARAM(0)	; param a
	push rax
	push 2	; arg count
	mov rax, qword [free_var_26]	; free var __bin-sub-rr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; old return address
	push qword [rbp]	; old frame-pointer
	mov rcx, 6
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8]
.L_tc_recycle_frame_loop_050a:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_050a
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8
	sub rdx, 8
	jmp .L_tc_recycle_frame_loop_050a
.L_tc_recycle_frame_done_050a:
	lea rsp, [rbx + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_02ce
.L_if_else_02ce:
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param b
	push rax
	push 1	; arg count
	mov rax, qword [free_var_140]	; free var real?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_02cd
	; preparing a tail-call
	mov rax, PARAM(1)	; param b
	push rax
	mov rax, PARAM(0)	; param a
	push rax
	push 2	; arg count
	mov rax, qword [free_var_26]	; free var __bin-sub-rr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; old return address
	push qword [rbp]	; old frame-pointer
	mov rcx, 6
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8]
.L_tc_recycle_frame_loop_050b:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_050b
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8
	sub rdx, 8
	jmp .L_tc_recycle_frame_loop_050b
.L_tc_recycle_frame_done_050b:
	lea rsp, [rbx + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_02cd
.L_if_else_02cd:
	; preparing a tail-call
	push 0	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var error
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; old return address
	push qword [rbp]	; old frame-pointer
	mov rcx, 4
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8]
.L_tc_recycle_frame_loop_050c:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_050c
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8
	sub rdx, 8
	jmp .L_tc_recycle_frame_loop_050c
.L_tc_recycle_frame_done_050c:
	lea rsp, [rbx + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
.L_if_end_02cd:
.L_if_end_02ce:
.L_if_end_02cf:
	jmp .L_if_end_02d0
.L_if_else_02d0:
	; preparing a tail-call
	push 0	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var error
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; old return address
	push qword [rbp]	; old frame-pointer
	mov rcx, 4
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8]
.L_tc_recycle_frame_loop_050d:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_050d
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8
	sub rdx, 8
	jmp .L_tc_recycle_frame_loop_050d
.L_tc_recycle_frame_done_050d:
	lea rsp, [rbx + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
.L_if_end_02d0:
.L_if_end_02d1:
.L_if_end_02d2:
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_simple_end_03dd:	; new closure is in rax
	push rax
	push 1	; arg count
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 1	; new rib
	call malloc
	push rax
	mov rdi, 8 * 2	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_03de:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
	je .L_lambda_simple_env_end_03de
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_03de
.L_lambda_simple_env_end_03de:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_03de:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_03de
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_03de
.L_lambda_simple_params_end_03de:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_03de
	jmp .L_lambda_simple_end_03de
.L_lambda_simple_code_03de:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_03de
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_03de:
	enter 0, 0
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 1	; new rib
	call malloc
	push rax
	mov rdi, 8 * 3	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_opt_env_loop_0084:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 2
	je .L_lambda_opt_env_end_0084
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_opt_env_loop_0084
.L_lambda_opt_env_end_0084:
	pop rbx
	mov rsi, 0
.L_lambda_opt_params_loop_0084:	; copy params
	cmp rsi, 1
	je .L_lambda_opt_params_end_0084
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_opt_params_loop_0084
.L_lambda_opt_params_end_0084:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_opt_code_0084
	jmp .L_lambda_opt_end_0084
.L_lambda_opt_code_0084:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1 ;	 check num of args
	je .L_lambda_opt_arity_check_exact_0084 ;	 if equal, go to exact arity
	jg .L_lambda_opt_arity_check_more_0084 ;	 if greater than, go to arity more
	push qword [rsp + 8 * 2] ;	 else, throw opt arity error
	push 1
	jmp L_error_incorrect_arity_opt
.L_lambda_opt_arity_check_exact_0084:
	mov rax, qword [rsp + 8 * 2] ;	 number of args
	lea rbx, [rsp + 8 * (2 + rax)] ;	 address of last element
	sub rsp, 8
	lea rcx, [rsp + 0] ;	 new start
.L_lambda_opt_shift_entry_0084:
	mov rdx, [rcx + 8]
	mov [rcx], rdx
	add rcx, 8
	cmp rbx, rcx
	jne .L_lambda_opt_shift_entry_0084
.L_lambda_opt_shift_exit_0084:
	mov qword[rbx], sob_nil ;	 place nil
	add rax, 1
	mov qword [rsp + 8 * 2], rax
	jmp .L_lambda_opt_stack_adjusted_0084
.L_lambda_opt_arity_check_more_0084:
	mov rdx, sob_nil ;	 base cdr
	cmp qword [rsp + 8 * 2], 2
	je .L_lambda_opt_stack_shrink_loop_exit_0084
.L_lambda_opt_stack_shrink_loop_0084:
	mov rdi, (1 + 8 + 8)
	call malloc
	mov byte[rax], T_pair
	mov SOB_PAIR_CDR(rax), rdx
	mov rdx, rax
	mov rax, qword [rsp + 8 * 2]
	mov rbx, qword [rsp + 8 * (2 + rax)]
	mov SOB_PAIR_CAR(rdx), rbx
	lea rbx, [rsp + 8 * (2 + rax - 1)]
.L_lambda_opt_extra_shift_process_0084:
	mov rcx, [rbx]
	mov [rbx + 8], rcx
	sub rbx, 8
	cmp rsp, rbx
	jle .L_lambda_opt_extra_shift_process_0084
.L_lambda_opt_extra_shift_process_end_0084:
	add rsp, 8
	mov rbx, [rsp + 8 * 2]
	sub rbx, 1
	mov [rsp + 8 * 2], rbx
	cmp qword [rsp + 8 * 2], 2
	jg .L_lambda_opt_stack_shrink_loop_0084
.L_lambda_opt_stack_shrink_loop_exit_0084:
	mov rcx, [rsp + 8 * 2]
	mov rbx, qword [rsp + 8 * (2 + rcx)]
	mov rdi, (1 + 8 + 8)
	call malloc
	mov byte[rax], T_pair
	mov SOB_PAIR_CDR(rax), rdx
	mov SOB_PAIR_CAR(rax), rbx
	mov [rsp + 8 * (2 + rcx)], rax
.L_lambda_opt_stack_adjusted_0084:
	enter 0, 0
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param s
	push rax
	push 1	; arg count
	mov rax, qword [free_var_126]	; free var null?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_02d3
	; preparing a tail-call
	mov rax, PARAM(0)	; param a
	push rax
	mov rax, L_constants + 2558
	push rax
	push 2	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var bin-
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; old return address
	push qword [rbp]	; old frame-pointer
	mov rcx, 6
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8]
.L_tc_recycle_frame_loop_050e:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_050e
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8
	sub rdx, 8
	jmp .L_tc_recycle_frame_loop_050e
.L_tc_recycle_frame_done_050e:
	lea rsp, [rbx + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_02d3
.L_if_else_02d3:
	; preparing a tail-call
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param s
	push rax
	mov rax, L_constants + 2558
	push rax
	mov rax, qword [free_var_1]	; free var +
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	push rax
	push 3	; arg count
	mov rax, qword [free_var_94]	; free var fold-left
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 1	; arg count
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 2	; new rib
	call malloc
	push rax
	mov rdi, 8 * 4	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_03df:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 3
	je .L_lambda_simple_env_end_03df
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_03df
.L_lambda_simple_env_end_03df:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_03df:	; copy params
	cmp rsi, 2
	je .L_lambda_simple_params_end_03df
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_03df
.L_lambda_simple_params_end_03df:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_03df
	jmp .L_lambda_simple_end_03df
.L_lambda_simple_code_03df:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_03df
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_03df:
	enter 0, 0
	; preparing a tail-call
	mov rax, PARAM(0)	; param b
	push rax
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var a
	push rax
	push 2	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 1]
	mov rax, qword [rax + 8 * 0]	; bound var bin-
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; old return address
	push qword [rbp]	; old frame-pointer
	mov rcx, 6
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8]
.L_tc_recycle_frame_loop_050f:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_050f
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8
	sub rdx, 8
	jmp .L_tc_recycle_frame_loop_050f
.L_tc_recycle_frame_done_050f:
	lea rsp, [rbx + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_03df:	; new closure is in rax
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; old return address
	push qword [rbp]	; old frame-pointer
	mov rcx, 5
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8]
.L_tc_recycle_frame_loop_0510:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0510
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8
	sub rdx, 8
	jmp .L_tc_recycle_frame_loop_0510
.L_tc_recycle_frame_done_0510:
	lea rsp, [rbx + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
.L_if_end_02d3:
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_opt_end_0084:	; new closure is in rax
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_03de:	; new closure is in rax
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; old return address
	push qword [rbp]	; old frame-pointer
	mov rcx, 5
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8]
.L_tc_recycle_frame_loop_0511:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0511
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8
	sub rdx, 8
	jmp .L_tc_recycle_frame_loop_0511
.L_tc_recycle_frame_done_0511:
	lea rsp, [rbx + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_03dc:	; new closure is in rax
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	mov qword [free_var_2], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void

	; preparing a non-tail-call
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 0	; new rib
	call malloc
	push rax
	mov rdi, 8 * 1	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_03e0:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_03e0
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_03e0
.L_lambda_simple_env_end_03e0:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_03e0:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_03e0
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_03e0
.L_lambda_simple_params_end_03e0:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_03e0
	jmp .L_lambda_simple_end_03e0
.L_lambda_simple_code_03e0:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 0
	je .L_lambda_simple_arity_check_ok_03e0
	push qword [rsp + 8 * 2]
	push 0
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_03e0:
	enter 0, 0
	; preparing a tail-call
	mov rax, L_constants + 2691
	push rax
	mov rax, L_constants + 2846
	push rax
	push 2	; arg count
	mov rax, qword [free_var_90]	; free var error
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; old return address
	push qword [rbp]	; old frame-pointer
	mov rcx, 6
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8]
.L_tc_recycle_frame_loop_0512:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0512
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8
	sub rdx, 8
	jmp .L_tc_recycle_frame_loop_0512
.L_tc_recycle_frame_done_0512:
	lea rsp, [rbx + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(0)
.L_lambda_simple_end_03e0:	; new closure is in rax
	push rax
	push 1	; arg count
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 0	; new rib
	call malloc
	push rax
	mov rdi, 8 * 1	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_03e1:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_03e1
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_03e1
.L_lambda_simple_env_end_03e1:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_03e1:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_03e1
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_03e1
.L_lambda_simple_params_end_03e1:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_03e1
	jmp .L_lambda_simple_end_03e1
.L_lambda_simple_code_03e1:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_03e1
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_03e1:
	enter 0, 0
	; preparing a tail-call
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 1	; new rib
	call malloc
	push rax
	mov rdi, 8 * 2	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_03e2:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
	je .L_lambda_simple_env_end_03e2
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_03e2
.L_lambda_simple_env_end_03e2:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_03e2:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_03e2
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_03e2
.L_lambda_simple_params_end_03e2:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_03e2
	jmp .L_lambda_simple_end_03e2
.L_lambda_simple_code_03e2:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 2
	je .L_lambda_simple_arity_check_ok_03e2
	push qword [rsp + 8 * 2]
	push 2
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_03e2:
	enter 0, 0
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param a
	push rax
	push 1	; arg count
	mov rax, qword [free_var_103]	; free var integer?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_02df
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param b
	push rax
	push 1	; arg count
	mov rax, qword [free_var_103]	; free var integer?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_02d6
	; preparing a tail-call
	mov rax, PARAM(1)	; param b
	push rax
	mov rax, PARAM(0)	; param a
	push rax
	push 2	; arg count
	mov rax, qword [free_var_24]	; free var __bin-mul-zz
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; old return address
	push qword [rbp]	; old frame-pointer
	mov rcx, 6
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8]
.L_tc_recycle_frame_loop_0513:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0513
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8
	sub rdx, 8
	jmp .L_tc_recycle_frame_loop_0513
.L_tc_recycle_frame_done_0513:
	lea rsp, [rbx + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_02d6
.L_if_else_02d6:
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param b
	push rax
	push 1	; arg count
	mov rax, qword [free_var_97]	; free var fraction?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_02d5
	; preparing a tail-call
	mov rax, PARAM(1)	; param b
	push rax
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param a
	push rax
	push 1	; arg count
	mov rax, qword [free_var_29]	; free var __integer-to-fraction
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 2	; arg count
	mov rax, qword [free_var_22]	; free var __bin-mul-qq
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; old return address
	push qword [rbp]	; old frame-pointer
	mov rcx, 6
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8]
.L_tc_recycle_frame_loop_0514:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0514
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8
	sub rdx, 8
	jmp .L_tc_recycle_frame_loop_0514
.L_tc_recycle_frame_done_0514:
	lea rsp, [rbx + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_02d5
.L_if_else_02d5:
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param b
	push rax
	push 1	; arg count
	mov rax, qword [free_var_140]	; free var real?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_02d4
	; preparing a tail-call
	mov rax, PARAM(1)	; param b
	push rax
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param a
	push rax
	push 1	; arg count
	mov rax, qword [free_var_102]	; free var integer->real
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 2	; arg count
	mov rax, qword [free_var_23]	; free var __bin-mul-rr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; old return address
	push qword [rbp]	; old frame-pointer
	mov rcx, 6
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8]
.L_tc_recycle_frame_loop_0515:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0515
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8
	sub rdx, 8
	jmp .L_tc_recycle_frame_loop_0515
.L_tc_recycle_frame_done_0515:
	lea rsp, [rbx + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_02d4
.L_if_else_02d4:
	; preparing a tail-call
	push 0	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var error
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; old return address
	push qword [rbp]	; old frame-pointer
	mov rcx, 4
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8]
.L_tc_recycle_frame_loop_0516:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0516
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8
	sub rdx, 8
	jmp .L_tc_recycle_frame_loop_0516
.L_tc_recycle_frame_done_0516:
	lea rsp, [rbx + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
.L_if_end_02d4:
.L_if_end_02d5:
.L_if_end_02d6:
	jmp .L_if_end_02df
.L_if_else_02df:
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param a
	push rax
	push 1	; arg count
	mov rax, qword [free_var_97]	; free var fraction?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_02de
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param b
	push rax
	push 1	; arg count
	mov rax, qword [free_var_103]	; free var integer?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_02d9
	; preparing a tail-call
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param b
	push rax
	push 1	; arg count
	mov rax, qword [free_var_29]	; free var __integer-to-fraction
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	mov rax, PARAM(0)	; param a
	push rax
	push 2	; arg count
	mov rax, qword [free_var_22]	; free var __bin-mul-qq
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; old return address
	push qword [rbp]	; old frame-pointer
	mov rcx, 6
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8]
.L_tc_recycle_frame_loop_0517:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0517
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8
	sub rdx, 8
	jmp .L_tc_recycle_frame_loop_0517
.L_tc_recycle_frame_done_0517:
	lea rsp, [rbx + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_02d9
.L_if_else_02d9:
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param b
	push rax
	push 1	; arg count
	mov rax, qword [free_var_97]	; free var fraction?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_02d8
	; preparing a tail-call
	mov rax, PARAM(1)	; param b
	push rax
	mov rax, PARAM(0)	; param a
	push rax
	push 2	; arg count
	mov rax, qword [free_var_22]	; free var __bin-mul-qq
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; old return address
	push qword [rbp]	; old frame-pointer
	mov rcx, 6
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8]
.L_tc_recycle_frame_loop_0518:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0518
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8
	sub rdx, 8
	jmp .L_tc_recycle_frame_loop_0518
.L_tc_recycle_frame_done_0518:
	lea rsp, [rbx + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_02d8
.L_if_else_02d8:
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param b
	push rax
	push 1	; arg count
	mov rax, qword [free_var_140]	; free var real?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_02d7
	; preparing a tail-call
	mov rax, PARAM(1)	; param b
	push rax
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param a
	push rax
	push 1	; arg count
	mov rax, qword [free_var_96]	; free var fraction->real
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 2	; arg count
	mov rax, qword [free_var_23]	; free var __bin-mul-rr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; old return address
	push qword [rbp]	; old frame-pointer
	mov rcx, 6
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8]
.L_tc_recycle_frame_loop_0519:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0519
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8
	sub rdx, 8
	jmp .L_tc_recycle_frame_loop_0519
.L_tc_recycle_frame_done_0519:
	lea rsp, [rbx + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_02d7
.L_if_else_02d7:
	; preparing a tail-call
	push 0	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var error
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; old return address
	push qword [rbp]	; old frame-pointer
	mov rcx, 4
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8]
.L_tc_recycle_frame_loop_051a:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_051a
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8
	sub rdx, 8
	jmp .L_tc_recycle_frame_loop_051a
.L_tc_recycle_frame_done_051a:
	lea rsp, [rbx + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
.L_if_end_02d7:
.L_if_end_02d8:
.L_if_end_02d9:
	jmp .L_if_end_02de
.L_if_else_02de:
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param a
	push rax
	push 1	; arg count
	mov rax, qword [free_var_140]	; free var real?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_02dd
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param b
	push rax
	push 1	; arg count
	mov rax, qword [free_var_103]	; free var integer?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_02dc
	; preparing a tail-call
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param b
	push rax
	push 1	; arg count
	mov rax, qword [free_var_102]	; free var integer->real
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	mov rax, PARAM(0)	; param a
	push rax
	push 2	; arg count
	mov rax, qword [free_var_23]	; free var __bin-mul-rr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; old return address
	push qword [rbp]	; old frame-pointer
	mov rcx, 6
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8]
.L_tc_recycle_frame_loop_051b:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_051b
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8
	sub rdx, 8
	jmp .L_tc_recycle_frame_loop_051b
.L_tc_recycle_frame_done_051b:
	lea rsp, [rbx + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_02dc
.L_if_else_02dc:
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param b
	push rax
	push 1	; arg count
	mov rax, qword [free_var_97]	; free var fraction?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_02db
	; preparing a tail-call
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param b
	push rax
	push 1	; arg count
	mov rax, qword [free_var_96]	; free var fraction->real
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	mov rax, PARAM(0)	; param a
	push rax
	push 2	; arg count
	mov rax, qword [free_var_23]	; free var __bin-mul-rr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; old return address
	push qword [rbp]	; old frame-pointer
	mov rcx, 6
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8]
.L_tc_recycle_frame_loop_051c:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_051c
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8
	sub rdx, 8
	jmp .L_tc_recycle_frame_loop_051c
.L_tc_recycle_frame_done_051c:
	lea rsp, [rbx + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_02db
.L_if_else_02db:
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param b
	push rax
	push 1	; arg count
	mov rax, qword [free_var_140]	; free var real?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_02da
	; preparing a tail-call
	mov rax, PARAM(1)	; param b
	push rax
	mov rax, PARAM(0)	; param a
	push rax
	push 2	; arg count
	mov rax, qword [free_var_23]	; free var __bin-mul-rr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; old return address
	push qword [rbp]	; old frame-pointer
	mov rcx, 6
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8]
.L_tc_recycle_frame_loop_051d:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_051d
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8
	sub rdx, 8
	jmp .L_tc_recycle_frame_loop_051d
.L_tc_recycle_frame_done_051d:
	lea rsp, [rbx + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_02da
.L_if_else_02da:
	; preparing a tail-call
	push 0	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var error
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; old return address
	push qword [rbp]	; old frame-pointer
	mov rcx, 4
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8]
.L_tc_recycle_frame_loop_051e:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_051e
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8
	sub rdx, 8
	jmp .L_tc_recycle_frame_loop_051e
.L_tc_recycle_frame_done_051e:
	lea rsp, [rbx + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
.L_if_end_02da:
.L_if_end_02db:
.L_if_end_02dc:
	jmp .L_if_end_02dd
.L_if_else_02dd:
	; preparing a tail-call
	push 0	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var error
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; old return address
	push qword [rbp]	; old frame-pointer
	mov rcx, 4
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8]
.L_tc_recycle_frame_loop_051f:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_051f
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8
	sub rdx, 8
	jmp .L_tc_recycle_frame_loop_051f
.L_tc_recycle_frame_done_051f:
	lea rsp, [rbx + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
.L_if_end_02dd:
.L_if_end_02de:
.L_if_end_02df:
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_simple_end_03e2:	; new closure is in rax
	push rax
	push 1	; arg count
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 1	; new rib
	call malloc
	push rax
	mov rdi, 8 * 2	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_03e3:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
	je .L_lambda_simple_env_end_03e3
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_03e3
.L_lambda_simple_env_end_03e3:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_03e3:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_03e3
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_03e3
.L_lambda_simple_params_end_03e3:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_03e3
	jmp .L_lambda_simple_end_03e3
.L_lambda_simple_code_03e3:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_03e3
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_03e3:
	enter 0, 0
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 1	; new rib
	call malloc
	push rax
	mov rdi, 8 * 3	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_opt_env_loop_0085:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 2
	je .L_lambda_opt_env_end_0085
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_opt_env_loop_0085
.L_lambda_opt_env_end_0085:
	pop rbx
	mov rsi, 0
.L_lambda_opt_params_loop_0085:	; copy params
	cmp rsi, 1
	je .L_lambda_opt_params_end_0085
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_opt_params_loop_0085
.L_lambda_opt_params_end_0085:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_opt_code_0085
	jmp .L_lambda_opt_end_0085
.L_lambda_opt_code_0085:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 0 ;	 check num of args
	je .L_lambda_opt_arity_check_exact_0085 ;	 if equal, go to exact arity
	jg .L_lambda_opt_arity_check_more_0085 ;	 if greater than, go to arity more
	push qword [rsp + 8 * 2] ;	 else, throw opt arity error
	push 0
	jmp L_error_incorrect_arity_opt
.L_lambda_opt_arity_check_exact_0085:
	mov rax, qword [rsp + 8 * 2] ;	 number of args
	lea rbx, [rsp + 8 * (2 + rax)] ;	 address of last element
	sub rsp, 8
	lea rcx, [rsp + 0] ;	 new start
.L_lambda_opt_shift_entry_0085:
	mov rdx, [rcx + 8]
	mov [rcx], rdx
	add rcx, 8
	cmp rbx, rcx
	jne .L_lambda_opt_shift_entry_0085
.L_lambda_opt_shift_exit_0085:
	mov qword[rbx], sob_nil ;	 place nil
	add rax, 1
	mov qword [rsp + 8 * 2], rax
	jmp .L_lambda_opt_stack_adjusted_0085
.L_lambda_opt_arity_check_more_0085:
	mov rdx, sob_nil ;	 base cdr
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_opt_stack_shrink_loop_exit_0085
.L_lambda_opt_stack_shrink_loop_0085:
	mov rdi, (1 + 8 + 8)
	call malloc
	mov byte[rax], T_pair
	mov SOB_PAIR_CDR(rax), rdx
	mov rdx, rax
	mov rax, qword [rsp + 8 * 2]
	mov rbx, qword [rsp + 8 * (2 + rax)]
	mov SOB_PAIR_CAR(rdx), rbx
	lea rbx, [rsp + 8 * (2 + rax - 1)]
.L_lambda_opt_extra_shift_process_0085:
	mov rcx, [rbx]
	mov [rbx + 8], rcx
	sub rbx, 8
	cmp rsp, rbx
	jle .L_lambda_opt_extra_shift_process_0085
.L_lambda_opt_extra_shift_process_end_0085:
	add rsp, 8
	mov rbx, [rsp + 8 * 2]
	sub rbx, 1
	mov [rsp + 8 * 2], rbx
	cmp qword [rsp + 8 * 2], 1
	jg .L_lambda_opt_stack_shrink_loop_0085
.L_lambda_opt_stack_shrink_loop_exit_0085:
	mov rcx, [rsp + 8 * 2]
	mov rbx, qword [rsp + 8 * (2 + rcx)]
	mov rdi, (1 + 8 + 8)
	call malloc
	mov byte[rax], T_pair
	mov SOB_PAIR_CDR(rax), rdx
	mov SOB_PAIR_CAR(rax), rbx
	mov [rsp + 8 * (2 + rcx)], rax
.L_lambda_opt_stack_adjusted_0085:
	enter 0, 0
	; preparing a tail-call
	mov rax, PARAM(0)	; param s
	push rax
	mov rax, L_constants + 2810
	push rax
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var bin*
	push rax
	push 3	; arg count
	mov rax, qword [free_var_94]	; free var fold-left
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; old return address
	push qword [rbp]	; old frame-pointer
	mov rcx, 7
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8]
.L_tc_recycle_frame_loop_0520:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0520
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8
	sub rdx, 8
	jmp .L_tc_recycle_frame_loop_0520
.L_tc_recycle_frame_done_0520:
	lea rsp, [rbx + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_opt_end_0085:	; new closure is in rax
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_03e3:	; new closure is in rax
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; old return address
	push qword [rbp]	; old frame-pointer
	mov rcx, 5
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8]
.L_tc_recycle_frame_loop_0521:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0521
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8
	sub rdx, 8
	jmp .L_tc_recycle_frame_loop_0521
.L_tc_recycle_frame_done_0521:
	lea rsp, [rbx + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_03e1:	; new closure is in rax
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	mov qword [free_var_0], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void

	; preparing a non-tail-call
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 0	; new rib
	call malloc
	push rax
	mov rdi, 8 * 1	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_03e4:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_03e4
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_03e4
.L_lambda_simple_env_end_03e4:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_03e4:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_03e4
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_03e4
.L_lambda_simple_params_end_03e4:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_03e4
	jmp .L_lambda_simple_end_03e4
.L_lambda_simple_code_03e4:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 0
	je .L_lambda_simple_arity_check_ok_03e4
	push qword [rsp + 8 * 2]
	push 0
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_03e4:
	enter 0, 0
	; preparing a tail-call
	mov rax, L_constants + 2691
	push rax
	mov rax, L_constants + 2892
	push rax
	push 2	; arg count
	mov rax, qword [free_var_90]	; free var error
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; old return address
	push qword [rbp]	; old frame-pointer
	mov rcx, 6
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8]
.L_tc_recycle_frame_loop_0522:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0522
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8
	sub rdx, 8
	jmp .L_tc_recycle_frame_loop_0522
.L_tc_recycle_frame_done_0522:
	lea rsp, [rbx + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(0)
.L_lambda_simple_end_03e4:	; new closure is in rax
	push rax
	push 1	; arg count
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 0	; new rib
	call malloc
	push rax
	mov rdi, 8 * 1	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_03e5:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_03e5
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_03e5
.L_lambda_simple_env_end_03e5:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_03e5:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_03e5
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_03e5
.L_lambda_simple_params_end_03e5:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_03e5
	jmp .L_lambda_simple_end_03e5
.L_lambda_simple_code_03e5:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_03e5
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_03e5:
	enter 0, 0
	; preparing a tail-call
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 1	; new rib
	call malloc
	push rax
	mov rdi, 8 * 2	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_03e6:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
	je .L_lambda_simple_env_end_03e6
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_03e6
.L_lambda_simple_env_end_03e6:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_03e6:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_03e6
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_03e6
.L_lambda_simple_params_end_03e6:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_03e6
	jmp .L_lambda_simple_end_03e6
.L_lambda_simple_code_03e6:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 2
	je .L_lambda_simple_arity_check_ok_03e6
	push qword [rsp + 8 * 2]
	push 2
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_03e6:
	enter 0, 0
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param a
	push rax
	push 1	; arg count
	mov rax, qword [free_var_103]	; free var integer?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_02eb
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param b
	push rax
	push 1	; arg count
	mov rax, qword [free_var_103]	; free var integer?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_02e2
	; preparing a tail-call
	mov rax, PARAM(1)	; param b
	push rax
	mov rax, PARAM(0)	; param a
	push rax
	push 2	; arg count
	mov rax, qword [free_var_15]	; free var __bin-div-zz
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; old return address
	push qword [rbp]	; old frame-pointer
	mov rcx, 6
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8]
.L_tc_recycle_frame_loop_0523:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0523
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8
	sub rdx, 8
	jmp .L_tc_recycle_frame_loop_0523
.L_tc_recycle_frame_done_0523:
	lea rsp, [rbx + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_02e2
.L_if_else_02e2:
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param b
	push rax
	push 1	; arg count
	mov rax, qword [free_var_97]	; free var fraction?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_02e1
	; preparing a tail-call
	mov rax, PARAM(1)	; param b
	push rax
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param a
	push rax
	push 1	; arg count
	mov rax, qword [free_var_29]	; free var __integer-to-fraction
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 2	; arg count
	mov rax, qword [free_var_13]	; free var __bin-div-qq
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; old return address
	push qword [rbp]	; old frame-pointer
	mov rcx, 6
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8]
.L_tc_recycle_frame_loop_0524:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0524
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8
	sub rdx, 8
	jmp .L_tc_recycle_frame_loop_0524
.L_tc_recycle_frame_done_0524:
	lea rsp, [rbx + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_02e1
.L_if_else_02e1:
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param b
	push rax
	push 1	; arg count
	mov rax, qword [free_var_140]	; free var real?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_02e0
	; preparing a tail-call
	mov rax, PARAM(1)	; param b
	push rax
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param a
	push rax
	push 1	; arg count
	mov rax, qword [free_var_102]	; free var integer->real
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 2	; arg count
	mov rax, qword [free_var_14]	; free var __bin-div-rr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; old return address
	push qword [rbp]	; old frame-pointer
	mov rcx, 6
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8]
.L_tc_recycle_frame_loop_0525:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0525
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8
	sub rdx, 8
	jmp .L_tc_recycle_frame_loop_0525
.L_tc_recycle_frame_done_0525:
	lea rsp, [rbx + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_02e0
.L_if_else_02e0:
	; preparing a tail-call
	push 0	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var error
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; old return address
	push qword [rbp]	; old frame-pointer
	mov rcx, 4
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8]
.L_tc_recycle_frame_loop_0526:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0526
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8
	sub rdx, 8
	jmp .L_tc_recycle_frame_loop_0526
.L_tc_recycle_frame_done_0526:
	lea rsp, [rbx + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
.L_if_end_02e0:
.L_if_end_02e1:
.L_if_end_02e2:
	jmp .L_if_end_02eb
.L_if_else_02eb:
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param a
	push rax
	push 1	; arg count
	mov rax, qword [free_var_97]	; free var fraction?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_02ea
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param b
	push rax
	push 1	; arg count
	mov rax, qword [free_var_103]	; free var integer?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_02e5
	; preparing a tail-call
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param b
	push rax
	push 1	; arg count
	mov rax, qword [free_var_29]	; free var __integer-to-fraction
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	mov rax, PARAM(0)	; param a
	push rax
	push 2	; arg count
	mov rax, qword [free_var_13]	; free var __bin-div-qq
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; old return address
	push qword [rbp]	; old frame-pointer
	mov rcx, 6
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8]
.L_tc_recycle_frame_loop_0527:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0527
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8
	sub rdx, 8
	jmp .L_tc_recycle_frame_loop_0527
.L_tc_recycle_frame_done_0527:
	lea rsp, [rbx + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_02e5
.L_if_else_02e5:
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param b
	push rax
	push 1	; arg count
	mov rax, qword [free_var_97]	; free var fraction?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_02e4
	; preparing a tail-call
	mov rax, PARAM(1)	; param b
	push rax
	mov rax, PARAM(0)	; param a
	push rax
	push 2	; arg count
	mov rax, qword [free_var_13]	; free var __bin-div-qq
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; old return address
	push qword [rbp]	; old frame-pointer
	mov rcx, 6
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8]
.L_tc_recycle_frame_loop_0528:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0528
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8
	sub rdx, 8
	jmp .L_tc_recycle_frame_loop_0528
.L_tc_recycle_frame_done_0528:
	lea rsp, [rbx + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_02e4
.L_if_else_02e4:
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param b
	push rax
	push 1	; arg count
	mov rax, qword [free_var_140]	; free var real?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_02e3
	; preparing a tail-call
	mov rax, PARAM(1)	; param b
	push rax
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param a
	push rax
	push 1	; arg count
	mov rax, qword [free_var_96]	; free var fraction->real
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 2	; arg count
	mov rax, qword [free_var_14]	; free var __bin-div-rr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; old return address
	push qword [rbp]	; old frame-pointer
	mov rcx, 6
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8]
.L_tc_recycle_frame_loop_0529:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0529
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8
	sub rdx, 8
	jmp .L_tc_recycle_frame_loop_0529
.L_tc_recycle_frame_done_0529:
	lea rsp, [rbx + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_02e3
.L_if_else_02e3:
	; preparing a tail-call
	push 0	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var error
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; old return address
	push qword [rbp]	; old frame-pointer
	mov rcx, 4
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8]
.L_tc_recycle_frame_loop_052a:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_052a
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8
	sub rdx, 8
	jmp .L_tc_recycle_frame_loop_052a
.L_tc_recycle_frame_done_052a:
	lea rsp, [rbx + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
.L_if_end_02e3:
.L_if_end_02e4:
.L_if_end_02e5:
	jmp .L_if_end_02ea
.L_if_else_02ea:
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param a
	push rax
	push 1	; arg count
	mov rax, qword [free_var_140]	; free var real?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_02e9
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param b
	push rax
	push 1	; arg count
	mov rax, qword [free_var_103]	; free var integer?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_02e8
	; preparing a tail-call
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param b
	push rax
	push 1	; arg count
	mov rax, qword [free_var_102]	; free var integer->real
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	mov rax, PARAM(0)	; param a
	push rax
	push 2	; arg count
	mov rax, qword [free_var_14]	; free var __bin-div-rr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; old return address
	push qword [rbp]	; old frame-pointer
	mov rcx, 6
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8]
.L_tc_recycle_frame_loop_052b:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_052b
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8
	sub rdx, 8
	jmp .L_tc_recycle_frame_loop_052b
.L_tc_recycle_frame_done_052b:
	lea rsp, [rbx + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_02e8
.L_if_else_02e8:
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param b
	push rax
	push 1	; arg count
	mov rax, qword [free_var_97]	; free var fraction?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_02e7
	; preparing a tail-call
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param b
	push rax
	push 1	; arg count
	mov rax, qword [free_var_96]	; free var fraction->real
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	mov rax, PARAM(0)	; param a
	push rax
	push 2	; arg count
	mov rax, qword [free_var_14]	; free var __bin-div-rr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; old return address
	push qword [rbp]	; old frame-pointer
	mov rcx, 6
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8]
.L_tc_recycle_frame_loop_052c:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_052c
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8
	sub rdx, 8
	jmp .L_tc_recycle_frame_loop_052c
.L_tc_recycle_frame_done_052c:
	lea rsp, [rbx + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_02e7
.L_if_else_02e7:
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param b
	push rax
	push 1	; arg count
	mov rax, qword [free_var_140]	; free var real?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_02e6
	; preparing a tail-call
	mov rax, PARAM(1)	; param b
	push rax
	mov rax, PARAM(0)	; param a
	push rax
	push 2	; arg count
	mov rax, qword [free_var_14]	; free var __bin-div-rr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; old return address
	push qword [rbp]	; old frame-pointer
	mov rcx, 6
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8]
.L_tc_recycle_frame_loop_052d:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_052d
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8
	sub rdx, 8
	jmp .L_tc_recycle_frame_loop_052d
.L_tc_recycle_frame_done_052d:
	lea rsp, [rbx + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_02e6
.L_if_else_02e6:
	; preparing a tail-call
	push 0	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var error
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; old return address
	push qword [rbp]	; old frame-pointer
	mov rcx, 4
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8]
.L_tc_recycle_frame_loop_052e:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_052e
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8
	sub rdx, 8
	jmp .L_tc_recycle_frame_loop_052e
.L_tc_recycle_frame_done_052e:
	lea rsp, [rbx + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
.L_if_end_02e6:
.L_if_end_02e7:
.L_if_end_02e8:
	jmp .L_if_end_02e9
.L_if_else_02e9:
	; preparing a tail-call
	push 0	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var error
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; old return address
	push qword [rbp]	; old frame-pointer
	mov rcx, 4
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8]
.L_tc_recycle_frame_loop_052f:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_052f
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8
	sub rdx, 8
	jmp .L_tc_recycle_frame_loop_052f
.L_tc_recycle_frame_done_052f:
	lea rsp, [rbx + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
.L_if_end_02e9:
.L_if_end_02ea:
.L_if_end_02eb:
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_simple_end_03e6:	; new closure is in rax
	push rax
	push 1	; arg count
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 1	; new rib
	call malloc
	push rax
	mov rdi, 8 * 2	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_03e7:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
	je .L_lambda_simple_env_end_03e7
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_03e7
.L_lambda_simple_env_end_03e7:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_03e7:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_03e7
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_03e7
.L_lambda_simple_params_end_03e7:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_03e7
	jmp .L_lambda_simple_end_03e7
.L_lambda_simple_code_03e7:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_03e7
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_03e7:
	enter 0, 0
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 1	; new rib
	call malloc
	push rax
	mov rdi, 8 * 3	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_opt_env_loop_0086:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 2
	je .L_lambda_opt_env_end_0086
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_opt_env_loop_0086
.L_lambda_opt_env_end_0086:
	pop rbx
	mov rsi, 0
.L_lambda_opt_params_loop_0086:	; copy params
	cmp rsi, 1
	je .L_lambda_opt_params_end_0086
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_opt_params_loop_0086
.L_lambda_opt_params_end_0086:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_opt_code_0086
	jmp .L_lambda_opt_end_0086
.L_lambda_opt_code_0086:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1 ;	 check num of args
	je .L_lambda_opt_arity_check_exact_0086 ;	 if equal, go to exact arity
	jg .L_lambda_opt_arity_check_more_0086 ;	 if greater than, go to arity more
	push qword [rsp + 8 * 2] ;	 else, throw opt arity error
	push 1
	jmp L_error_incorrect_arity_opt
.L_lambda_opt_arity_check_exact_0086:
	mov rax, qword [rsp + 8 * 2] ;	 number of args
	lea rbx, [rsp + 8 * (2 + rax)] ;	 address of last element
	sub rsp, 8
	lea rcx, [rsp + 0] ;	 new start
.L_lambda_opt_shift_entry_0086:
	mov rdx, [rcx + 8]
	mov [rcx], rdx
	add rcx, 8
	cmp rbx, rcx
	jne .L_lambda_opt_shift_entry_0086
.L_lambda_opt_shift_exit_0086:
	mov qword[rbx], sob_nil ;	 place nil
	add rax, 1
	mov qword [rsp + 8 * 2], rax
	jmp .L_lambda_opt_stack_adjusted_0086
.L_lambda_opt_arity_check_more_0086:
	mov rdx, sob_nil ;	 base cdr
	cmp qword [rsp + 8 * 2], 2
	je .L_lambda_opt_stack_shrink_loop_exit_0086
.L_lambda_opt_stack_shrink_loop_0086:
	mov rdi, (1 + 8 + 8)
	call malloc
	mov byte[rax], T_pair
	mov SOB_PAIR_CDR(rax), rdx
	mov rdx, rax
	mov rax, qword [rsp + 8 * 2]
	mov rbx, qword [rsp + 8 * (2 + rax)]
	mov SOB_PAIR_CAR(rdx), rbx
	lea rbx, [rsp + 8 * (2 + rax - 1)]
.L_lambda_opt_extra_shift_process_0086:
	mov rcx, [rbx]
	mov [rbx + 8], rcx
	sub rbx, 8
	cmp rsp, rbx
	jle .L_lambda_opt_extra_shift_process_0086
.L_lambda_opt_extra_shift_process_end_0086:
	add rsp, 8
	mov rbx, [rsp + 8 * 2]
	sub rbx, 1
	mov [rsp + 8 * 2], rbx
	cmp qword [rsp + 8 * 2], 2
	jg .L_lambda_opt_stack_shrink_loop_0086
.L_lambda_opt_stack_shrink_loop_exit_0086:
	mov rcx, [rsp + 8 * 2]
	mov rbx, qword [rsp + 8 * (2 + rcx)]
	mov rdi, (1 + 8 + 8)
	call malloc
	mov byte[rax], T_pair
	mov SOB_PAIR_CDR(rax), rdx
	mov SOB_PAIR_CAR(rax), rbx
	mov [rsp + 8 * (2 + rcx)], rax
.L_lambda_opt_stack_adjusted_0086:
	enter 0, 0
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param s
	push rax
	push 1	; arg count
	mov rax, qword [free_var_126]	; free var null?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_02ec
	; preparing a tail-call
	mov rax, PARAM(0)	; param a
	push rax
	mov rax, L_constants + 2810
	push rax
	push 2	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var bin/
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; old return address
	push qword [rbp]	; old frame-pointer
	mov rcx, 6
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8]
.L_tc_recycle_frame_loop_0530:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0530
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8
	sub rdx, 8
	jmp .L_tc_recycle_frame_loop_0530
.L_tc_recycle_frame_done_0530:
	lea rsp, [rbx + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_02ec
.L_if_else_02ec:
	; preparing a tail-call
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param s
	push rax
	mov rax, L_constants + 2810
	push rax
	mov rax, qword [free_var_0]	; free var *
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	push rax
	push 3	; arg count
	mov rax, qword [free_var_94]	; free var fold-left
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 1	; arg count
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 2	; new rib
	call malloc
	push rax
	mov rdi, 8 * 4	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_03e8:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 3
	je .L_lambda_simple_env_end_03e8
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_03e8
.L_lambda_simple_env_end_03e8:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_03e8:	; copy params
	cmp rsi, 2
	je .L_lambda_simple_params_end_03e8
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_03e8
.L_lambda_simple_params_end_03e8:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_03e8
	jmp .L_lambda_simple_end_03e8
.L_lambda_simple_code_03e8:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_03e8
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_03e8:
	enter 0, 0
	; preparing a tail-call
	mov rax, PARAM(0)	; param b
	push rax
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var a
	push rax
	push 2	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 1]
	mov rax, qword [rax + 8 * 0]	; bound var bin/
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; old return address
	push qword [rbp]	; old frame-pointer
	mov rcx, 6
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8]
.L_tc_recycle_frame_loop_0531:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0531
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8
	sub rdx, 8
	jmp .L_tc_recycle_frame_loop_0531
.L_tc_recycle_frame_done_0531:
	lea rsp, [rbx + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_03e8:	; new closure is in rax
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; old return address
	push qword [rbp]	; old frame-pointer
	mov rcx, 5
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8]
.L_tc_recycle_frame_loop_0532:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0532
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8
	sub rdx, 8
	jmp .L_tc_recycle_frame_loop_0532
.L_tc_recycle_frame_done_0532:
	lea rsp, [rbx + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
.L_if_end_02ec:
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_opt_end_0086:	; new closure is in rax
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_03e7:	; new closure is in rax
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; old return address
	push qword [rbp]	; old frame-pointer
	mov rcx, 5
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8]
.L_tc_recycle_frame_loop_0533:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0533
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8
	sub rdx, 8
	jmp .L_tc_recycle_frame_loop_0533
.L_tc_recycle_frame_done_0533:
	lea rsp, [rbx + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_03e5:	; new closure is in rax
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	mov qword [free_var_3], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void

	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 0	; new rib
	call malloc
	push rax
	mov rdi, 8 * 1	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_03e9:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_03e9
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_03e9
.L_lambda_simple_env_end_03e9:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_03e9:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_03e9
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_03e9
.L_lambda_simple_params_end_03e9:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_03e9
	jmp .L_lambda_simple_end_03e9
.L_lambda_simple_code_03e9:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_03e9
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_03e9:
	enter 0, 0
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param n
	push rax
	push 1	; arg count
	mov rax, qword [free_var_181]	; free var zero?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_02ed
	mov rax, L_constants + 2810
	jmp .L_if_end_02ed
.L_if_else_02ed:
	; preparing a tail-call
	; preparing a non-tail-call
	; preparing a non-tail-call
	mov rax, L_constants + 2810
	push rax
	mov rax, PARAM(0)	; param n
	push rax
	push 2	; arg count
	mov rax, qword [free_var_2]	; free var -
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 1	; arg count
	mov rax, qword [free_var_93]	; free var fact
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	mov rax, PARAM(0)	; param n
	push rax
	push 2	; arg count
	mov rax, qword [free_var_0]	; free var *
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; old return address
	push qword [rbp]	; old frame-pointer
	mov rcx, 6
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8]
.L_tc_recycle_frame_loop_0534:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0534
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8
	sub rdx, 8
	jmp .L_tc_recycle_frame_loop_0534
.L_tc_recycle_frame_done_0534:
	lea rsp, [rbx + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
.L_if_end_02ed:
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_03e9:	; new closure is in rax
	mov qword [free_var_93], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void

	mov rax, L_constants + 0
	mov qword [free_var_4], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void

	mov rax, L_constants + 0
	mov qword [free_var_5], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void

	mov rax, L_constants + 0
	mov qword [free_var_7], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void

	mov rax, L_constants + 0
	mov qword [free_var_8], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void

	mov rax, L_constants + 0
	mov qword [free_var_6], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void

	; preparing a non-tail-call
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 0	; new rib
	call malloc
	push rax
	mov rdi, 8 * 1	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_03ea:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_03ea
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_03ea
.L_lambda_simple_env_end_03ea:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_03ea:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_03ea
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_03ea
.L_lambda_simple_params_end_03ea:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_03ea
	jmp .L_lambda_simple_end_03ea
.L_lambda_simple_code_03ea:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 0
	je .L_lambda_simple_arity_check_ok_03ea
	push qword [rsp + 8 * 2]
	push 0
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_03ea:
	enter 0, 0
	; preparing a tail-call
	mov rax, L_constants + 3119
	push rax
	mov rax, L_constants + 3110
	push rax
	push 2	; arg count
	mov rax, qword [free_var_90]	; free var error
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; old return address
	push qword [rbp]	; old frame-pointer
	mov rcx, 6
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8]
.L_tc_recycle_frame_loop_0535:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0535
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8
	sub rdx, 8
	jmp .L_tc_recycle_frame_loop_0535
.L_tc_recycle_frame_done_0535:
	lea rsp, [rbx + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(0)
.L_lambda_simple_end_03ea:	; new closure is in rax
	push rax
	push 1	; arg count
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 0	; new rib
	call malloc
	push rax
	mov rdi, 8 * 1	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_03eb:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_03eb
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_03eb
.L_lambda_simple_env_end_03eb:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_03eb:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_03eb
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_03eb
.L_lambda_simple_params_end_03eb:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_03eb
	jmp .L_lambda_simple_end_03eb
.L_lambda_simple_code_03eb:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_03eb
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_03eb:
	enter 0, 0
	; preparing a tail-call
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 1	; new rib
	call malloc
	push rax
	mov rdi, 8 * 2	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_03ec:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
	je .L_lambda_simple_env_end_03ec
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_03ec
.L_lambda_simple_env_end_03ec:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_03ec:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_03ec
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_03ec
.L_lambda_simple_params_end_03ec:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_03ec
	jmp .L_lambda_simple_end_03ec
.L_lambda_simple_code_03ec:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 3
	je .L_lambda_simple_arity_check_ok_03ec
	push qword [rsp + 8 * 2]
	push 3
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_03ec:
	enter 0, 0
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 3	; new rib
	call malloc
	push rax
	mov rdi, 8 * 3	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_03ed:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 2
	je .L_lambda_simple_env_end_03ed
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_03ed
.L_lambda_simple_env_end_03ed:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_03ed:	; copy params
	cmp rsi, 3
	je .L_lambda_simple_params_end_03ed
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_03ed
.L_lambda_simple_params_end_03ed:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_03ed
	jmp .L_lambda_simple_end_03ed
.L_lambda_simple_code_03ed:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 2
	je .L_lambda_simple_arity_check_ok_03ed
	push qword [rsp + 8 * 2]
	push 2
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_03ed:
	enter 0, 0
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param a
	push rax
	push 1	; arg count
	mov rax, qword [free_var_103]	; free var integer?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_02f9
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param b
	push rax
	push 1	; arg count
	mov rax, qword [free_var_103]	; free var integer?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_02f0
	; preparing a tail-call
	mov rax, PARAM(1)	; param b
	push rax
	mov rax, PARAM(0)	; param a
	push rax
	push 2	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var comparator-zz
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; old return address
	push qword [rbp]	; old frame-pointer
	mov rcx, 6
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8]
.L_tc_recycle_frame_loop_0536:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0536
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8
	sub rdx, 8
	jmp .L_tc_recycle_frame_loop_0536
.L_tc_recycle_frame_done_0536:
	lea rsp, [rbx + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_02f0
.L_if_else_02f0:
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param b
	push rax
	push 1	; arg count
	mov rax, qword [free_var_97]	; free var fraction?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_02ef
	; preparing a tail-call
	mov rax, PARAM(1)	; param b
	push rax
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param a
	push rax
	push 1	; arg count
	mov rax, qword [free_var_29]	; free var __integer-to-fraction
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 2	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 1]	; bound var comparator-qq
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; old return address
	push qword [rbp]	; old frame-pointer
	mov rcx, 6
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8]
.L_tc_recycle_frame_loop_0537:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0537
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8
	sub rdx, 8
	jmp .L_tc_recycle_frame_loop_0537
.L_tc_recycle_frame_done_0537:
	lea rsp, [rbx + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_02ef
.L_if_else_02ef:
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param b
	push rax
	push 1	; arg count
	mov rax, qword [free_var_140]	; free var real?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_02ee
	; preparing a tail-call
	mov rax, PARAM(1)	; param b
	push rax
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param a
	push rax
	push 1	; arg count
	mov rax, qword [free_var_102]	; free var integer->real
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 2	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 2]	; bound var comparator-rr
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; old return address
	push qword [rbp]	; old frame-pointer
	mov rcx, 6
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8]
.L_tc_recycle_frame_loop_0538:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0538
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8
	sub rdx, 8
	jmp .L_tc_recycle_frame_loop_0538
.L_tc_recycle_frame_done_0538:
	lea rsp, [rbx + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_02ee
.L_if_else_02ee:
	; preparing a tail-call
	push 0	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 1]
	mov rax, qword [rax + 8 * 0]	; bound var exit
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; old return address
	push qword [rbp]	; old frame-pointer
	mov rcx, 4
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8]
.L_tc_recycle_frame_loop_0539:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0539
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8
	sub rdx, 8
	jmp .L_tc_recycle_frame_loop_0539
.L_tc_recycle_frame_done_0539:
	lea rsp, [rbx + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
.L_if_end_02ee:
.L_if_end_02ef:
.L_if_end_02f0:
	jmp .L_if_end_02f9
.L_if_else_02f9:
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param a
	push rax
	push 1	; arg count
	mov rax, qword [free_var_97]	; free var fraction?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_02f8
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param b
	push rax
	push 1	; arg count
	mov rax, qword [free_var_103]	; free var integer?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_02f3
	; preparing a tail-call
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param b
	push rax
	push 1	; arg count
	mov rax, qword [free_var_29]	; free var __integer-to-fraction
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	mov rax, PARAM(0)	; param a
	push rax
	push 2	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 1]	; bound var comparator-qq
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; old return address
	push qword [rbp]	; old frame-pointer
	mov rcx, 6
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8]
.L_tc_recycle_frame_loop_053a:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_053a
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8
	sub rdx, 8
	jmp .L_tc_recycle_frame_loop_053a
.L_tc_recycle_frame_done_053a:
	lea rsp, [rbx + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_02f3
.L_if_else_02f3:
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param b
	push rax
	push 1	; arg count
	mov rax, qword [free_var_97]	; free var fraction?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_02f2
	; preparing a tail-call
	mov rax, PARAM(1)	; param b
	push rax
	mov rax, PARAM(0)	; param a
	push rax
	push 2	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 1]	; bound var comparator-qq
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; old return address
	push qword [rbp]	; old frame-pointer
	mov rcx, 6
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8]
.L_tc_recycle_frame_loop_053b:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_053b
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8
	sub rdx, 8
	jmp .L_tc_recycle_frame_loop_053b
.L_tc_recycle_frame_done_053b:
	lea rsp, [rbx + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_02f2
.L_if_else_02f2:
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param b
	push rax
	push 1	; arg count
	mov rax, qword [free_var_140]	; free var real?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_02f1
	; preparing a tail-call
	mov rax, PARAM(1)	; param b
	push rax
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param a
	push rax
	push 1	; arg count
	mov rax, qword [free_var_96]	; free var fraction->real
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 2	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 2]	; bound var comparator-rr
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; old return address
	push qword [rbp]	; old frame-pointer
	mov rcx, 6
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8]
.L_tc_recycle_frame_loop_053c:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_053c
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8
	sub rdx, 8
	jmp .L_tc_recycle_frame_loop_053c
.L_tc_recycle_frame_done_053c:
	lea rsp, [rbx + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_02f1
.L_if_else_02f1:
	; preparing a tail-call
	push 0	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 1]
	mov rax, qword [rax + 8 * 0]	; bound var exit
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; old return address
	push qword [rbp]	; old frame-pointer
	mov rcx, 4
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8]
.L_tc_recycle_frame_loop_053d:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_053d
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8
	sub rdx, 8
	jmp .L_tc_recycle_frame_loop_053d
.L_tc_recycle_frame_done_053d:
	lea rsp, [rbx + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
.L_if_end_02f1:
.L_if_end_02f2:
.L_if_end_02f3:
	jmp .L_if_end_02f8
.L_if_else_02f8:
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param a
	push rax
	push 1	; arg count
	mov rax, qword [free_var_140]	; free var real?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_02f7
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param b
	push rax
	push 1	; arg count
	mov rax, qword [free_var_103]	; free var integer?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_02f6
	; preparing a tail-call
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param b
	push rax
	push 1	; arg count
	mov rax, qword [free_var_102]	; free var integer->real
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	mov rax, PARAM(0)	; param a
	push rax
	push 2	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 2]	; bound var comparator-rr
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; old return address
	push qword [rbp]	; old frame-pointer
	mov rcx, 6
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8]
.L_tc_recycle_frame_loop_053e:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_053e
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8
	sub rdx, 8
	jmp .L_tc_recycle_frame_loop_053e
.L_tc_recycle_frame_done_053e:
	lea rsp, [rbx + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_02f6
.L_if_else_02f6:
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param b
	push rax
	push 1	; arg count
	mov rax, qword [free_var_97]	; free var fraction?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_02f5
	; preparing a tail-call
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param b
	push rax
	push 1	; arg count
	mov rax, qword [free_var_96]	; free var fraction->real
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	mov rax, PARAM(0)	; param a
	push rax
	push 2	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 2]	; bound var comparator-rr
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; old return address
	push qword [rbp]	; old frame-pointer
	mov rcx, 6
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8]
.L_tc_recycle_frame_loop_053f:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_053f
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8
	sub rdx, 8
	jmp .L_tc_recycle_frame_loop_053f
.L_tc_recycle_frame_done_053f:
	lea rsp, [rbx + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_02f5
.L_if_else_02f5:
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param b
	push rax
	push 1	; arg count
	mov rax, qword [free_var_140]	; free var real?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_02f4
	; preparing a tail-call
	mov rax, PARAM(1)	; param b
	push rax
	mov rax, PARAM(0)	; param a
	push rax
	push 2	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 2]	; bound var comparator-rr
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; old return address
	push qword [rbp]	; old frame-pointer
	mov rcx, 6
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8]
.L_tc_recycle_frame_loop_0540:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0540
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8
	sub rdx, 8
	jmp .L_tc_recycle_frame_loop_0540
.L_tc_recycle_frame_done_0540:
	lea rsp, [rbx + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_02f4
.L_if_else_02f4:
	; preparing a tail-call
	push 0	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 1]
	mov rax, qword [rax + 8 * 0]	; bound var exit
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; old return address
	push qword [rbp]	; old frame-pointer
	mov rcx, 4
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8]
.L_tc_recycle_frame_loop_0541:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0541
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8
	sub rdx, 8
	jmp .L_tc_recycle_frame_loop_0541
.L_tc_recycle_frame_done_0541:
	lea rsp, [rbx + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
.L_if_end_02f4:
.L_if_end_02f5:
.L_if_end_02f6:
	jmp .L_if_end_02f7
.L_if_else_02f7:
	; preparing a tail-call
	push 0	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 1]
	mov rax, qword [rax + 8 * 0]	; bound var exit
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; old return address
	push qword [rbp]	; old frame-pointer
	mov rcx, 4
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8]
.L_tc_recycle_frame_loop_0542:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0542
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8
	sub rdx, 8
	jmp .L_tc_recycle_frame_loop_0542
.L_tc_recycle_frame_done_0542:
	lea rsp, [rbx + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
.L_if_end_02f7:
.L_if_end_02f8:
.L_if_end_02f9:
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_simple_end_03ed:	; new closure is in rax
	leave
	ret AND_KILL_FRAME(3)
.L_lambda_simple_end_03ec:	; new closure is in rax
	push rax
	push 1	; arg count
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 1	; new rib
	call malloc
	push rax
	mov rdi, 8 * 2	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_03ee:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
	je .L_lambda_simple_env_end_03ee
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_03ee
.L_lambda_simple_env_end_03ee:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_03ee:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_03ee
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_03ee
.L_lambda_simple_params_end_03ee:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_03ee
	jmp .L_lambda_simple_end_03ee
.L_lambda_simple_code_03ee:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_03ee
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_03ee:
	enter 0, 0
	; preparing a tail-call
	; preparing a non-tail-call
	mov rax, qword [free_var_20]	; free var __bin-less-than-rr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	push rax
	mov rax, qword [free_var_19]	; free var __bin-less-than-qq
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	push rax
	mov rax, qword [free_var_21]	; free var __bin-less-than-zz
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	push rax
	push 3	; arg count
	mov rax, PARAM(0)	; param make-bin-comparator
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 1	; arg count
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 1	; new rib
	call malloc
	push rax
	mov rdi, 8 * 3	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_03ef:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 2
	je .L_lambda_simple_env_end_03ef
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_03ef
.L_lambda_simple_env_end_03ef:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_03ef:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_03ef
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_03ef
.L_lambda_simple_params_end_03ef:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_03ef
	jmp .L_lambda_simple_end_03ef
.L_lambda_simple_code_03ef:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_03ef
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_03ef:
	enter 0, 0
	; preparing a tail-call
	; preparing a non-tail-call
	mov rax, qword [free_var_17]	; free var __bin-equal-rr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	push rax
	mov rax, qword [free_var_16]	; free var __bin-equal-qq
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	push rax
	mov rax, qword [free_var_18]	; free var __bin-equal-zz
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	push rax
	push 3	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var make-bin-comparator
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 1	; arg count
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 1	; new rib
	call malloc
	push rax
	mov rdi, 8 * 4	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_03f0:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 3
	je .L_lambda_simple_env_end_03f0
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_03f0
.L_lambda_simple_env_end_03f0:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_03f0:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_03f0
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_03f0
.L_lambda_simple_params_end_03f0:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_03f0
	jmp .L_lambda_simple_end_03f0
.L_lambda_simple_code_03f0:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_03f0
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_03f0:
	enter 0, 0
	; preparing a tail-call
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 1	; new rib
	call malloc
	push rax
	mov rdi, 8 * 5	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_03f1:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 4
	je .L_lambda_simple_env_end_03f1
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_03f1
.L_lambda_simple_env_end_03f1:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_03f1:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_03f1
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_03f1
.L_lambda_simple_params_end_03f1:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_03f1
	jmp .L_lambda_simple_end_03f1
.L_lambda_simple_code_03f1:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 2
	je .L_lambda_simple_arity_check_ok_03f1
	push qword [rsp + 8 * 2]
	push 2
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_03f1:
	enter 0, 0
	; preparing a tail-call
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param b
	push rax
	mov rax, PARAM(0)	; param a
	push rax
	push 2	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 1]
	mov rax, qword [rax + 8 * 0]	; bound var bin<?
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 1	; arg count
	mov rax, qword [free_var_125]	; free var not
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; old return address
	push qword [rbp]	; old frame-pointer
	mov rcx, 5
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8]
.L_tc_recycle_frame_loop_0543:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0543
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8
	sub rdx, 8
	jmp .L_tc_recycle_frame_loop_0543
.L_tc_recycle_frame_done_0543:
	lea rsp, [rbx + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_simple_end_03f1:	; new closure is in rax
	push rax
	push 1	; arg count
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 1	; new rib
	call malloc
	push rax
	mov rdi, 8 * 5	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_03f2:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 4
	je .L_lambda_simple_env_end_03f2
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_03f2
.L_lambda_simple_env_end_03f2:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_03f2:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_03f2
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_03f2
.L_lambda_simple_params_end_03f2:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_03f2
	jmp .L_lambda_simple_end_03f2
.L_lambda_simple_code_03f2:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_03f2
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_03f2:
	enter 0, 0
	; preparing a tail-call
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 1	; new rib
	call malloc
	push rax
	mov rdi, 8 * 6	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_03f3:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 5
	je .L_lambda_simple_env_end_03f3
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_03f3
.L_lambda_simple_env_end_03f3:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_03f3:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_03f3
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_03f3
.L_lambda_simple_params_end_03f3:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_03f3
	jmp .L_lambda_simple_end_03f3
.L_lambda_simple_code_03f3:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 2
	je .L_lambda_simple_arity_check_ok_03f3
	push qword [rsp + 8 * 2]
	push 2
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_03f3:
	enter 0, 0
	; preparing a tail-call
	mov rax, PARAM(0)	; param a
	push rax
	mov rax, PARAM(1)	; param b
	push rax
	push 2	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 2]
	mov rax, qword [rax + 8 * 0]	; bound var bin<?
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; old return address
	push qword [rbp]	; old frame-pointer
	mov rcx, 6
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8]
.L_tc_recycle_frame_loop_0544:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0544
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8
	sub rdx, 8
	jmp .L_tc_recycle_frame_loop_0544
.L_tc_recycle_frame_done_0544:
	lea rsp, [rbx + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_simple_end_03f3:	; new closure is in rax
	push rax
	push 1	; arg count
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 1	; new rib
	call malloc
	push rax
	mov rdi, 8 * 6	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_03f4:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 5
	je .L_lambda_simple_env_end_03f4
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_03f4
.L_lambda_simple_env_end_03f4:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_03f4:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_03f4
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_03f4
.L_lambda_simple_params_end_03f4:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_03f4
	jmp .L_lambda_simple_end_03f4
.L_lambda_simple_code_03f4:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_03f4
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_03f4:
	enter 0, 0
	; preparing a tail-call
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 1	; new rib
	call malloc
	push rax
	mov rdi, 8 * 7	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_03f5:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 6
	je .L_lambda_simple_env_end_03f5
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_03f5
.L_lambda_simple_env_end_03f5:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_03f5:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_03f5
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_03f5
.L_lambda_simple_params_end_03f5:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_03f5
	jmp .L_lambda_simple_end_03f5
.L_lambda_simple_code_03f5:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 2
	je .L_lambda_simple_arity_check_ok_03f5
	push qword [rsp + 8 * 2]
	push 2
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_03f5:
	enter 0, 0
	; preparing a tail-call
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param b
	push rax
	mov rax, PARAM(0)	; param a
	push rax
	push 2	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var bin>?
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 1	; arg count
	mov rax, qword [free_var_125]	; free var not
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; old return address
	push qword [rbp]	; old frame-pointer
	mov rcx, 5
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8]
.L_tc_recycle_frame_loop_0545:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0545
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8
	sub rdx, 8
	jmp .L_tc_recycle_frame_loop_0545
.L_tc_recycle_frame_done_0545:
	lea rsp, [rbx + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_simple_end_03f5:	; new closure is in rax
	push rax
	push 1	; arg count
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 1	; new rib
	call malloc
	push rax
	mov rdi, 8 * 7	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_03f6:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 6
	je .L_lambda_simple_env_end_03f6
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_03f6
.L_lambda_simple_env_end_03f6:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_03f6:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_03f6
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_03f6
.L_lambda_simple_params_end_03f6:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_03f6
	jmp .L_lambda_simple_end_03f6
.L_lambda_simple_code_03f6:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_03f6
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_03f6:
	enter 0, 0
	; preparing a tail-call
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 1	; new rib
	call malloc
	push rax
	mov rdi, 8 * 8	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_03f7:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 7
	je .L_lambda_simple_env_end_03f7
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_03f7
.L_lambda_simple_env_end_03f7:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_03f7:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_03f7
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_03f7
.L_lambda_simple_params_end_03f7:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_03f7
	jmp .L_lambda_simple_end_03f7
.L_lambda_simple_code_03f7:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_03f7
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_03f7:
	enter 0, 0
	; preparing a tail-call
	mov rax, L_constants + 2335
	push rax
	push 1	; arg count
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 1	; new rib
	call malloc
	push rax
	mov rdi, 8 * 9	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_03f8:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 8
	je .L_lambda_simple_env_end_03f8
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_03f8
.L_lambda_simple_env_end_03f8:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_03f8:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_03f8
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_03f8
.L_lambda_simple_params_end_03f8:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_03f8
	jmp .L_lambda_simple_end_03f8
.L_lambda_simple_code_03f8:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_03f8
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_03f8:
	enter 0, 0

	mov rdi, 8
	call malloc
	mov rbx, PARAM(0)	; param run
	mov [rax], rbx	; box run
	mov PARAM(0), rax	; replace param with box
	mov rax, sob_void

	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 1	; new rib
	call malloc
	push rax
	mov rdi, 8 * 10	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_03f9:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 9
	je .L_lambda_simple_env_end_03f9
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_03f9
.L_lambda_simple_env_end_03f9:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_03f9:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_03f9
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_03f9
.L_lambda_simple_params_end_03f9:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_03f9
	jmp .L_lambda_simple_end_03f9
.L_lambda_simple_code_03f9:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 2
	je .L_lambda_simple_arity_check_ok_03f9
	push qword [rsp + 8 * 2]
	push 2
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_03f9:
	enter 0, 0
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param s
	push rax
	push 1	; arg count
	mov rax, qword [free_var_126]	; free var null?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	jne .L_or_end_004c
	; preparing a non-tail-call
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param s
	push rax
	push 1	; arg count
	mov rax, qword [free_var_54]	; free var car
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	mov rax, PARAM(0)	; param a
	push rax
	push 2	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 1]
	mov rax, qword [rax + 8 * 0]	; bound var bin-ordering
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_02fa
	; preparing a tail-call
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param s
	push rax
	push 1	; arg count
	mov rax, qword [free_var_69]	; free var cdr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param s
	push rax
	push 1	; arg count
	mov rax, qword [free_var_54]	; free var car
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 2	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var run
	mov rax, qword [rax]
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; old return address
	push qword [rbp]	; old frame-pointer
	mov rcx, 6
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8]
.L_tc_recycle_frame_loop_0546:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0546
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8
	sub rdx, 8
	jmp .L_tc_recycle_frame_loop_0546
.L_tc_recycle_frame_done_0546:
	lea rsp, [rbx + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_02fa
.L_if_else_02fa:
	mov rax, L_constants + 2
.L_if_end_02fa:
.L_or_end_004c:
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_simple_end_03f9:	; new closure is in rax

	push rax
	mov rax, PARAM(0)	; param run

	pop qword[rax]
	mov rax, sob_void

	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 1	; new rib
	call malloc
	push rax
	mov rdi, 8 * 10	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_opt_env_loop_0087:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 9
	je .L_lambda_opt_env_end_0087
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_opt_env_loop_0087
.L_lambda_opt_env_end_0087:
	pop rbx
	mov rsi, 0
.L_lambda_opt_params_loop_0087:	; copy params
	cmp rsi, 1
	je .L_lambda_opt_params_end_0087
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_opt_params_loop_0087
.L_lambda_opt_params_end_0087:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_opt_code_0087
	jmp .L_lambda_opt_end_0087
.L_lambda_opt_code_0087:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1 ;	 check num of args
	je .L_lambda_opt_arity_check_exact_0087 ;	 if equal, go to exact arity
	jg .L_lambda_opt_arity_check_more_0087 ;	 if greater than, go to arity more
	push qword [rsp + 8 * 2] ;	 else, throw opt arity error
	push 1
	jmp L_error_incorrect_arity_opt
.L_lambda_opt_arity_check_exact_0087:
	mov rax, qword [rsp + 8 * 2] ;	 number of args
	lea rbx, [rsp + 8 * (2 + rax)] ;	 address of last element
	sub rsp, 8
	lea rcx, [rsp + 0] ;	 new start
.L_lambda_opt_shift_entry_0087:
	mov rdx, [rcx + 8]
	mov [rcx], rdx
	add rcx, 8
	cmp rbx, rcx
	jne .L_lambda_opt_shift_entry_0087
.L_lambda_opt_shift_exit_0087:
	mov qword[rbx], sob_nil ;	 place nil
	add rax, 1
	mov qword [rsp + 8 * 2], rax
	jmp .L_lambda_opt_stack_adjusted_0087
.L_lambda_opt_arity_check_more_0087:
	mov rdx, sob_nil ;	 base cdr
	cmp qword [rsp + 8 * 2], 2
	je .L_lambda_opt_stack_shrink_loop_exit_0087
.L_lambda_opt_stack_shrink_loop_0087:
	mov rdi, (1 + 8 + 8)
	call malloc
	mov byte[rax], T_pair
	mov SOB_PAIR_CDR(rax), rdx
	mov rdx, rax
	mov rax, qword [rsp + 8 * 2]
	mov rbx, qword [rsp + 8 * (2 + rax)]
	mov SOB_PAIR_CAR(rdx), rbx
	lea rbx, [rsp + 8 * (2 + rax - 1)]
.L_lambda_opt_extra_shift_process_0087:
	mov rcx, [rbx]
	mov [rbx + 8], rcx
	sub rbx, 8
	cmp rsp, rbx
	jle .L_lambda_opt_extra_shift_process_0087
.L_lambda_opt_extra_shift_process_end_0087:
	add rsp, 8
	mov rbx, [rsp + 8 * 2]
	sub rbx, 1
	mov [rsp + 8 * 2], rbx
	cmp qword [rsp + 8 * 2], 2
	jg .L_lambda_opt_stack_shrink_loop_0087
.L_lambda_opt_stack_shrink_loop_exit_0087:
	mov rcx, [rsp + 8 * 2]
	mov rbx, qword [rsp + 8 * (2 + rcx)]
	mov rdi, (1 + 8 + 8)
	call malloc
	mov byte[rax], T_pair
	mov SOB_PAIR_CDR(rax), rdx
	mov SOB_PAIR_CAR(rax), rbx
	mov [rsp + 8 * (2 + rcx)], rax
.L_lambda_opt_stack_adjusted_0087:
	enter 0, 0
	; preparing a tail-call
	mov rax, PARAM(1)	; param s
	push rax
	mov rax, PARAM(0)	; param a
	push rax
	push 2	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var run
	mov rax, qword [rax]
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; old return address
	push qword [rbp]	; old frame-pointer
	mov rcx, 6
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8]
.L_tc_recycle_frame_loop_0547:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0547
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8
	sub rdx, 8
	jmp .L_tc_recycle_frame_loop_0547
.L_tc_recycle_frame_done_0547:
	lea rsp, [rbx + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_opt_end_0087:	; new closure is in rax
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_03f8:	; new closure is in rax
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; old return address
	push qword [rbp]	; old frame-pointer
	mov rcx, 5
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8]
.L_tc_recycle_frame_loop_0548:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0548
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8
	sub rdx, 8
	jmp .L_tc_recycle_frame_loop_0548
.L_tc_recycle_frame_done_0548:
	lea rsp, [rbx + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_03f7:	; new closure is in rax
	push rax
	push 1	; arg count
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 1	; new rib
	call malloc
	push rax
	mov rdi, 8 * 8	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_03fa:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 7
	je .L_lambda_simple_env_end_03fa
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_03fa
.L_lambda_simple_env_end_03fa:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_03fa:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_03fa
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_03fa
.L_lambda_simple_params_end_03fa:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_03fa
	jmp .L_lambda_simple_end_03fa
.L_lambda_simple_code_03fa:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_03fa
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_03fa:
	enter 0, 0
	; preparing a non-tail-call
	mov rax, ENV
	mov rax, qword [rax + 8 * 4]
	mov rax, qword [rax + 8 * 0]	; bound var bin<?
	push rax
	push 1	; arg count
	mov rax, PARAM(0)	; param make-run
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	mov qword [free_var_4], rax	; free var <
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	mov rax, sob_void

	; preparing a non-tail-call
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var bin<=?
	push rax
	push 1	; arg count
	mov rax, PARAM(0)	; param make-run
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	mov qword [free_var_5], rax	; free var <=
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	mov rax, sob_void

	; preparing a non-tail-call
	mov rax, ENV
	mov rax, qword [rax + 8 * 1]
	mov rax, qword [rax + 8 * 0]	; bound var bin>?
	push rax
	push 1	; arg count
	mov rax, PARAM(0)	; param make-run
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	mov qword [free_var_7], rax	; free var >
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	mov rax, sob_void

	; preparing a non-tail-call
	mov rax, ENV
	mov rax, qword [rax + 8 * 2]
	mov rax, qword [rax + 8 * 0]	; bound var bin>=?
	push rax
	push 1	; arg count
	mov rax, PARAM(0)	; param make-run
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	mov qword [free_var_8], rax	; free var >=
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	mov rax, sob_void

	; preparing a non-tail-call
	mov rax, ENV
	mov rax, qword [rax + 8 * 3]
	mov rax, qword [rax + 8 * 0]	; bound var bin=?
	push rax
	push 1	; arg count
	mov rax, PARAM(0)	; param make-run
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	mov qword [free_var_6], rax	; free var =
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	mov rax, sob_void
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_03fa:	; new closure is in rax
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; old return address
	push qword [rbp]	; old frame-pointer
	mov rcx, 5
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8]
.L_tc_recycle_frame_loop_0549:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0549
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8
	sub rdx, 8
	jmp .L_tc_recycle_frame_loop_0549
.L_tc_recycle_frame_done_0549:
	lea rsp, [rbx + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_03f6:	; new closure is in rax
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; old return address
	push qword [rbp]	; old frame-pointer
	mov rcx, 5
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8]
.L_tc_recycle_frame_loop_054a:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_054a
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8
	sub rdx, 8
	jmp .L_tc_recycle_frame_loop_054a
.L_tc_recycle_frame_done_054a:
	lea rsp, [rbx + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_03f4:	; new closure is in rax
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; old return address
	push qword [rbp]	; old frame-pointer
	mov rcx, 5
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8]
.L_tc_recycle_frame_loop_054b:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_054b
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8
	sub rdx, 8
	jmp .L_tc_recycle_frame_loop_054b
.L_tc_recycle_frame_done_054b:
	lea rsp, [rbx + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_03f2:	; new closure is in rax
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; old return address
	push qword [rbp]	; old frame-pointer
	mov rcx, 5
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8]
.L_tc_recycle_frame_loop_054c:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_054c
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8
	sub rdx, 8
	jmp .L_tc_recycle_frame_loop_054c
.L_tc_recycle_frame_done_054c:
	lea rsp, [rbx + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_03f0:	; new closure is in rax
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; old return address
	push qword [rbp]	; old frame-pointer
	mov rcx, 5
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8]
.L_tc_recycle_frame_loop_054d:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_054d
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8
	sub rdx, 8
	jmp .L_tc_recycle_frame_loop_054d
.L_tc_recycle_frame_done_054d:
	lea rsp, [rbx + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_03ef:	; new closure is in rax
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; old return address
	push qword [rbp]	; old frame-pointer
	mov rcx, 5
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8]
.L_tc_recycle_frame_loop_054e:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_054e
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8
	sub rdx, 8
	jmp .L_tc_recycle_frame_loop_054e
.L_tc_recycle_frame_done_054e:
	lea rsp, [rbx + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_03ee:	; new closure is in rax
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; old return address
	push qword [rbp]	; old frame-pointer
	mov rcx, 5
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8]
.L_tc_recycle_frame_loop_054f:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_054f
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8
	sub rdx, 8
	jmp .L_tc_recycle_frame_loop_054f
.L_tc_recycle_frame_done_054f:
	lea rsp, [rbx + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_03eb:	; new closure is in rax
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)

	mov rdi, rax
	call print_sexpr_if_not_void

	mov rax, L_constants + 0
	mov qword [free_var_79], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void

	mov rax, L_constants + 0
	mov qword [free_var_78], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void

	mov rax, L_constants + 0
	mov qword [free_var_80], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void

	mov rax, L_constants + 0
	mov qword [free_var_82], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void

	mov rax, L_constants + 0
	mov qword [free_var_81], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void

	; preparing a non-tail-call
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 0	; new rib
	call malloc
	push rax
	mov rdi, 8 * 1	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_03fb:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_03fb
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_03fb
.L_lambda_simple_env_end_03fb:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_03fb:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_03fb
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_03fb
.L_lambda_simple_params_end_03fb:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_03fb
	jmp .L_lambda_simple_end_03fb
.L_lambda_simple_code_03fb:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_03fb
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_03fb:
	enter 0, 0
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 1	; new rib
	call malloc
	push rax
	mov rdi, 8 * 2	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_opt_env_loop_0088:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
	je .L_lambda_opt_env_end_0088
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_opt_env_loop_0088
.L_lambda_opt_env_end_0088:
	pop rbx
	mov rsi, 0
.L_lambda_opt_params_loop_0088:	; copy params
	cmp rsi, 1
	je .L_lambda_opt_params_end_0088
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_opt_params_loop_0088
.L_lambda_opt_params_end_0088:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_opt_code_0088
	jmp .L_lambda_opt_end_0088
.L_lambda_opt_code_0088:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 0 ;	 check num of args
	je .L_lambda_opt_arity_check_exact_0088 ;	 if equal, go to exact arity
	jg .L_lambda_opt_arity_check_more_0088 ;	 if greater than, go to arity more
	push qword [rsp + 8 * 2] ;	 else, throw opt arity error
	push 0
	jmp L_error_incorrect_arity_opt
.L_lambda_opt_arity_check_exact_0088:
	mov rax, qword [rsp + 8 * 2] ;	 number of args
	lea rbx, [rsp + 8 * (2 + rax)] ;	 address of last element
	sub rsp, 8
	lea rcx, [rsp + 0] ;	 new start
.L_lambda_opt_shift_entry_0088:
	mov rdx, [rcx + 8]
	mov [rcx], rdx
	add rcx, 8
	cmp rbx, rcx
	jne .L_lambda_opt_shift_entry_0088
.L_lambda_opt_shift_exit_0088:
	mov qword[rbx], sob_nil ;	 place nil
	add rax, 1
	mov qword [rsp + 8 * 2], rax
	jmp .L_lambda_opt_stack_adjusted_0088
.L_lambda_opt_arity_check_more_0088:
	mov rdx, sob_nil ;	 base cdr
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_opt_stack_shrink_loop_exit_0088
.L_lambda_opt_stack_shrink_loop_0088:
	mov rdi, (1 + 8 + 8)
	call malloc
	mov byte[rax], T_pair
	mov SOB_PAIR_CDR(rax), rdx
	mov rdx, rax
	mov rax, qword [rsp + 8 * 2]
	mov rbx, qword [rsp + 8 * (2 + rax)]
	mov SOB_PAIR_CAR(rdx), rbx
	lea rbx, [rsp + 8 * (2 + rax - 1)]
.L_lambda_opt_extra_shift_process_0088:
	mov rcx, [rbx]
	mov [rbx + 8], rcx
	sub rbx, 8
	cmp rsp, rbx
	jle .L_lambda_opt_extra_shift_process_0088
.L_lambda_opt_extra_shift_process_end_0088:
	add rsp, 8
	mov rbx, [rsp + 8 * 2]
	sub rbx, 1
	mov [rsp + 8 * 2], rbx
	cmp qword [rsp + 8 * 2], 1
	jg .L_lambda_opt_stack_shrink_loop_0088
.L_lambda_opt_stack_shrink_loop_exit_0088:
	mov rcx, [rsp + 8 * 2]
	mov rbx, qword [rsp + 8 * (2 + rcx)]
	mov rdi, (1 + 8 + 8)
	call malloc
	mov byte[rax], T_pair
	mov SOB_PAIR_CDR(rax), rdx
	mov SOB_PAIR_CAR(rax), rbx
	mov [rsp + 8 * (2 + rcx)], rax
.L_lambda_opt_stack_adjusted_0088:
	enter 0, 0
	; preparing a tail-call
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param s
	push rax
	mov rax, qword [free_var_70]	; free var char->integer
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	push rax
	push 2	; arg count
	mov rax, qword [free_var_122]	; free var map
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var comparator
	push rax
	push 2	; arg count
	mov rax, qword [free_var_33]	; free var apply
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; old return address
	push qword [rbp]	; old frame-pointer
	mov rcx, 6
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8]
.L_tc_recycle_frame_loop_0550:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0550
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8
	sub rdx, 8
	jmp .L_tc_recycle_frame_loop_0550
.L_tc_recycle_frame_done_0550:
	lea rsp, [rbx + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_opt_end_0088:	; new closure is in rax
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_03fb:	; new closure is in rax
	push rax
	push 1	; arg count
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 0	; new rib
	call malloc
	push rax
	mov rdi, 8 * 1	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_03fc:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_03fc
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_03fc
.L_lambda_simple_env_end_03fc:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_03fc:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_03fc
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_03fc
.L_lambda_simple_params_end_03fc:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_03fc
	jmp .L_lambda_simple_end_03fc
.L_lambda_simple_code_03fc:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_03fc
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_03fc:
	enter 0, 0
	; preparing a non-tail-call
	mov rax, qword [free_var_4]	; free var <
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	push rax
	push 1	; arg count
	mov rax, PARAM(0)	; param make-char-comparator
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	mov qword [free_var_79], rax	; free var char<?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	mov rax, sob_void

	; preparing a non-tail-call
	mov rax, qword [free_var_5]	; free var <=
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	push rax
	push 1	; arg count
	mov rax, PARAM(0)	; param make-char-comparator
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	mov qword [free_var_78], rax	; free var char<=?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	mov rax, sob_void

	; preparing a non-tail-call
	mov rax, qword [free_var_6]	; free var =
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	push rax
	push 1	; arg count
	mov rax, PARAM(0)	; param make-char-comparator
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	mov qword [free_var_80], rax	; free var char=?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	mov rax, sob_void

	; preparing a non-tail-call
	mov rax, qword [free_var_7]	; free var >
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	push rax
	push 1	; arg count
	mov rax, PARAM(0)	; param make-char-comparator
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	mov qword [free_var_82], rax	; free var char>?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	mov rax, sob_void

	; preparing a non-tail-call
	mov rax, qword [free_var_8]	; free var >=
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	push rax
	push 1	; arg count
	mov rax, PARAM(0)	; param make-char-comparator
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	mov qword [free_var_81], rax	; free var char>=?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	mov rax, sob_void
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_03fc:	; new closure is in rax
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)

	mov rdi, rax
	call print_sexpr_if_not_void

	mov rax, L_constants + 0
	mov qword [free_var_76], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void

	mov rax, L_constants + 0
	mov qword [free_var_77], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void

	; preparing a non-tail-call
	; preparing a non-tail-call
	; preparing a non-tail-call
	mov rax, L_constants + 3352
	push rax
	push 1	; arg count
	mov rax, qword [free_var_70]	; free var char->integer
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	; preparing a non-tail-call
	mov rax, L_constants + 3365
	push rax
	push 1	; arg count
	mov rax, qword [free_var_70]	; free var char->integer
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 2	; arg count
	mov rax, qword [free_var_2]	; free var -
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 1	; arg count
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 0	; new rib
	call malloc
	push rax
	mov rdi, 8 * 1	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_03fd:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_03fd
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_03fd
.L_lambda_simple_env_end_03fd:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_03fd:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_03fd
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_03fd
.L_lambda_simple_params_end_03fd:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_03fd
	jmp .L_lambda_simple_end_03fd
.L_lambda_simple_code_03fd:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_03fd
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_03fd:
	enter 0, 0
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 1	; new rib
	call malloc
	push rax
	mov rdi, 8 * 2	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_03fe:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
	je .L_lambda_simple_env_end_03fe
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_03fe
.L_lambda_simple_env_end_03fe:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_03fe:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_03fe
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_03fe
.L_lambda_simple_params_end_03fe:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_03fe
	jmp .L_lambda_simple_end_03fe
.L_lambda_simple_code_03fe:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_03fe
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_03fe:
	enter 0, 0
	; preparing a non-tail-call
	mov rax, L_constants + 3354
	push rax
	mov rax, PARAM(0)	; param ch
	push rax
	mov rax, L_constants + 3352
	push rax
	push 3	; arg count
	mov rax, qword [free_var_78]	; free var char<=?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_02fb
	; preparing a tail-call
	; preparing a non-tail-call
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var delta
	push rax
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param ch
	push rax
	push 1	; arg count
	mov rax, qword [free_var_70]	; free var char->integer
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 2	; arg count
	mov rax, qword [free_var_1]	; free var +
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 1	; arg count
	mov rax, qword [free_var_101]	; free var integer->char
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; old return address
	push qword [rbp]	; old frame-pointer
	mov rcx, 5
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8]
.L_tc_recycle_frame_loop_0551:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0551
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8
	sub rdx, 8
	jmp .L_tc_recycle_frame_loop_0551
.L_tc_recycle_frame_done_0551:
	lea rsp, [rbx + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_02fb
.L_if_else_02fb:
	mov rax, PARAM(0)	; param ch
.L_if_end_02fb:
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_03fe:	; new closure is in rax
	mov qword [free_var_76], rax	; free var char-downcase
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	mov rax, sob_void

	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 1	; new rib
	call malloc
	push rax
	mov rdi, 8 * 2	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_03ff:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
	je .L_lambda_simple_env_end_03ff
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_03ff
.L_lambda_simple_env_end_03ff:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_03ff:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_03ff
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_03ff
.L_lambda_simple_params_end_03ff:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_03ff
	jmp .L_lambda_simple_end_03ff
.L_lambda_simple_code_03ff:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_03ff
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_03ff:
	enter 0, 0
	; preparing a non-tail-call
	mov rax, L_constants + 3367
	push rax
	mov rax, PARAM(0)	; param ch
	push rax
	mov rax, L_constants + 3365
	push rax
	push 3	; arg count
	mov rax, qword [free_var_78]	; free var char<=?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_02fc
	; preparing a tail-call
	; preparing a non-tail-call
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var delta
	push rax
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param ch
	push rax
	push 1	; arg count
	mov rax, qword [free_var_70]	; free var char->integer
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 2	; arg count
	mov rax, qword [free_var_2]	; free var -
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 1	; arg count
	mov rax, qword [free_var_101]	; free var integer->char
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; old return address
	push qword [rbp]	; old frame-pointer
	mov rcx, 5
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8]
.L_tc_recycle_frame_loop_0552:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0552
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8
	sub rdx, 8
	jmp .L_tc_recycle_frame_loop_0552
.L_tc_recycle_frame_done_0552:
	lea rsp, [rbx + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_02fc
.L_if_else_02fc:
	mov rax, PARAM(0)	; param ch
.L_if_end_02fc:
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_03ff:	; new closure is in rax
	mov qword [free_var_77], rax	; free var char-upcase
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	mov rax, sob_void
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_03fd:	; new closure is in rax
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)

	mov rdi, rax
	call print_sexpr_if_not_void

	mov rax, L_constants + 0
	mov qword [free_var_72], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void

	mov rax, L_constants + 0
	mov qword [free_var_71], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void

	mov rax, L_constants + 0
	mov qword [free_var_73], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void

	mov rax, L_constants + 0
	mov qword [free_var_75], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void

	mov rax, L_constants + 0
	mov qword [free_var_74], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void

	; preparing a non-tail-call
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 0	; new rib
	call malloc
	push rax
	mov rdi, 8 * 1	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_0400:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_0400
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0400
.L_lambda_simple_env_end_0400:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0400:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_0400
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0400
.L_lambda_simple_params_end_0400:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0400
	jmp .L_lambda_simple_end_0400
.L_lambda_simple_code_0400:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0400
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0400:
	enter 0, 0
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 1	; new rib
	call malloc
	push rax
	mov rdi, 8 * 2	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_opt_env_loop_0089:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
	je .L_lambda_opt_env_end_0089
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_opt_env_loop_0089
.L_lambda_opt_env_end_0089:
	pop rbx
	mov rsi, 0
.L_lambda_opt_params_loop_0089:	; copy params
	cmp rsi, 1
	je .L_lambda_opt_params_end_0089
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_opt_params_loop_0089
.L_lambda_opt_params_end_0089:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_opt_code_0089
	jmp .L_lambda_opt_end_0089
.L_lambda_opt_code_0089:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 0 ;	 check num of args
	je .L_lambda_opt_arity_check_exact_0089 ;	 if equal, go to exact arity
	jg .L_lambda_opt_arity_check_more_0089 ;	 if greater than, go to arity more
	push qword [rsp + 8 * 2] ;	 else, throw opt arity error
	push 0
	jmp L_error_incorrect_arity_opt
.L_lambda_opt_arity_check_exact_0089:
	mov rax, qword [rsp + 8 * 2] ;	 number of args
	lea rbx, [rsp + 8 * (2 + rax)] ;	 address of last element
	sub rsp, 8
	lea rcx, [rsp + 0] ;	 new start
.L_lambda_opt_shift_entry_0089:
	mov rdx, [rcx + 8]
	mov [rcx], rdx
	add rcx, 8
	cmp rbx, rcx
	jne .L_lambda_opt_shift_entry_0089
.L_lambda_opt_shift_exit_0089:
	mov qword[rbx], sob_nil ;	 place nil
	add rax, 1
	mov qword [rsp + 8 * 2], rax
	jmp .L_lambda_opt_stack_adjusted_0089
.L_lambda_opt_arity_check_more_0089:
	mov rdx, sob_nil ;	 base cdr
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_opt_stack_shrink_loop_exit_0089
.L_lambda_opt_stack_shrink_loop_0089:
	mov rdi, (1 + 8 + 8)
	call malloc
	mov byte[rax], T_pair
	mov SOB_PAIR_CDR(rax), rdx
	mov rdx, rax
	mov rax, qword [rsp + 8 * 2]
	mov rbx, qword [rsp + 8 * (2 + rax)]
	mov SOB_PAIR_CAR(rdx), rbx
	lea rbx, [rsp + 8 * (2 + rax - 1)]
.L_lambda_opt_extra_shift_process_0089:
	mov rcx, [rbx]
	mov [rbx + 8], rcx
	sub rbx, 8
	cmp rsp, rbx
	jle .L_lambda_opt_extra_shift_process_0089
.L_lambda_opt_extra_shift_process_end_0089:
	add rsp, 8
	mov rbx, [rsp + 8 * 2]
	sub rbx, 1
	mov [rsp + 8 * 2], rbx
	cmp qword [rsp + 8 * 2], 1
	jg .L_lambda_opt_stack_shrink_loop_0089
.L_lambda_opt_stack_shrink_loop_exit_0089:
	mov rcx, [rsp + 8 * 2]
	mov rbx, qword [rsp + 8 * (2 + rcx)]
	mov rdi, (1 + 8 + 8)
	call malloc
	mov byte[rax], T_pair
	mov SOB_PAIR_CDR(rax), rdx
	mov SOB_PAIR_CAR(rax), rbx
	mov [rsp + 8 * (2 + rcx)], rax
.L_lambda_opt_stack_adjusted_0089:
	enter 0, 0
	; preparing a tail-call
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param s
	push rax
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 1	; new rib
	call malloc
	push rax
	mov rdi, 8 * 3	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_0401:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 2
	je .L_lambda_simple_env_end_0401
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0401
.L_lambda_simple_env_end_0401:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0401:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_0401
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0401
.L_lambda_simple_params_end_0401:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0401
	jmp .L_lambda_simple_end_0401
.L_lambda_simple_code_0401:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0401
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0401:
	enter 0, 0
	; preparing a tail-call
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param ch
	push rax
	push 1	; arg count
	mov rax, qword [free_var_76]	; free var char-downcase
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 1	; arg count
	mov rax, qword [free_var_70]	; free var char->integer
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; old return address
	push qword [rbp]	; old frame-pointer
	mov rcx, 5
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8]
.L_tc_recycle_frame_loop_0553:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0553
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8
	sub rdx, 8
	jmp .L_tc_recycle_frame_loop_0553
.L_tc_recycle_frame_done_0553:
	lea rsp, [rbx + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0401:	; new closure is in rax
	push rax
	push 2	; arg count
	mov rax, qword [free_var_122]	; free var map
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var comparator
	push rax
	push 2	; arg count
	mov rax, qword [free_var_33]	; free var apply
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; old return address
	push qword [rbp]	; old frame-pointer
	mov rcx, 6
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8]
.L_tc_recycle_frame_loop_0554:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0554
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8
	sub rdx, 8
	jmp .L_tc_recycle_frame_loop_0554
.L_tc_recycle_frame_done_0554:
	lea rsp, [rbx + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_opt_end_0089:	; new closure is in rax
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0400:	; new closure is in rax
	push rax
	push 1	; arg count
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 0	; new rib
	call malloc
	push rax
	mov rdi, 8 * 1	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_0402:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_0402
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0402
.L_lambda_simple_env_end_0402:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0402:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_0402
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0402
.L_lambda_simple_params_end_0402:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0402
	jmp .L_lambda_simple_end_0402
.L_lambda_simple_code_0402:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0402
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0402:
	enter 0, 0
	; preparing a non-tail-call
	mov rax, qword [free_var_4]	; free var <
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	push rax
	push 1	; arg count
	mov rax, PARAM(0)	; param make-char-ci-comparator
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	mov qword [free_var_72], rax	; free var char-ci<?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	mov rax, sob_void

	; preparing a non-tail-call
	mov rax, qword [free_var_5]	; free var <=
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	push rax
	push 1	; arg count
	mov rax, PARAM(0)	; param make-char-ci-comparator
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	mov qword [free_var_71], rax	; free var char-ci<=?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	mov rax, sob_void

	; preparing a non-tail-call
	mov rax, qword [free_var_6]	; free var =
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	push rax
	push 1	; arg count
	mov rax, PARAM(0)	; param make-char-ci-comparator
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	mov qword [free_var_73], rax	; free var char-ci=?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	mov rax, sob_void

	; preparing a non-tail-call
	mov rax, qword [free_var_7]	; free var >
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	push rax
	push 1	; arg count
	mov rax, PARAM(0)	; param make-char-ci-comparator
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	mov qword [free_var_75], rax	; free var char-ci>?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	mov rax, sob_void

	; preparing a non-tail-call
	mov rax, qword [free_var_8]	; free var >=
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	push rax
	push 1	; arg count
	mov rax, PARAM(0)	; param make-char-ci-comparator
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	mov qword [free_var_74], rax	; free var char-ci>=?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	mov rax, sob_void
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0402:	; new closure is in rax
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)

	mov rdi, rax
	call print_sexpr_if_not_void

	mov rax, L_constants + 0
	mov qword [free_var_153], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void

	mov rax, L_constants + 0
	mov qword [free_var_159], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void

	; preparing a non-tail-call
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 0	; new rib
	call malloc
	push rax
	mov rdi, 8 * 1	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_0403:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_0403
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0403
.L_lambda_simple_env_end_0403:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0403:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_0403
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0403
.L_lambda_simple_params_end_0403:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0403
	jmp .L_lambda_simple_end_0403
.L_lambda_simple_code_0403:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0403
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0403:
	enter 0, 0
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 1	; new rib
	call malloc
	push rax
	mov rdi, 8 * 2	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_0404:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
	je .L_lambda_simple_env_end_0404
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0404
.L_lambda_simple_env_end_0404:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0404:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_0404
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0404
.L_lambda_simple_params_end_0404:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0404
	jmp .L_lambda_simple_end_0404
.L_lambda_simple_code_0404:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0404
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0404:
	enter 0, 0
	; preparing a tail-call
	; preparing a non-tail-call
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param str
	push rax
	push 1	; arg count
	mov rax, qword [free_var_146]	; free var string->list
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var char-case-converter
	push rax
	push 2	; arg count
	mov rax, qword [free_var_122]	; free var map
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 1	; arg count
	mov rax, qword [free_var_108]	; free var list->string
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; old return address
	push qword [rbp]	; old frame-pointer
	mov rcx, 5
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8]
.L_tc_recycle_frame_loop_0555:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0555
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8
	sub rdx, 8
	jmp .L_tc_recycle_frame_loop_0555
.L_tc_recycle_frame_done_0555:
	lea rsp, [rbx + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0404:	; new closure is in rax
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0403:	; new closure is in rax
	push rax
	push 1	; arg count
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 0	; new rib
	call malloc
	push rax
	mov rdi, 8 * 1	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_0405:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_0405
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0405
.L_lambda_simple_env_end_0405:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0405:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_0405
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0405
.L_lambda_simple_params_end_0405:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0405
	jmp .L_lambda_simple_end_0405
.L_lambda_simple_code_0405:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0405
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0405:
	enter 0, 0
	; preparing a non-tail-call
	mov rax, qword [free_var_76]	; free var char-downcase
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	push rax
	push 1	; arg count
	mov rax, PARAM(0)	; param make-string-case-converter
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	mov qword [free_var_153], rax	; free var string-downcase
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	mov rax, sob_void

	; preparing a non-tail-call
	mov rax, qword [free_var_77]	; free var char-upcase
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	push rax
	push 1	; arg count
	mov rax, PARAM(0)	; param make-string-case-converter
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	mov qword [free_var_159], rax	; free var string-upcase
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	mov rax, sob_void
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0405:	; new closure is in rax
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)

	mov rdi, rax
	call print_sexpr_if_not_void

	mov rax, L_constants + 0
	mov qword [free_var_161], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void

	mov rax, L_constants + 0
	mov qword [free_var_160], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void

	mov rax, L_constants + 0
	mov qword [free_var_162], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void

	mov rax, L_constants + 0
	mov qword [free_var_163], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void

	mov rax, L_constants + 0
	mov qword [free_var_164], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void

	mov rax, L_constants + 0
	mov qword [free_var_149], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void

	mov rax, L_constants + 0
	mov qword [free_var_148], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void

	mov rax, L_constants + 0
	mov qword [free_var_150], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void

	mov rax, L_constants + 0
	mov qword [free_var_151], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void

	mov rax, L_constants + 0
	mov qword [free_var_152], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void

	; preparing a non-tail-call
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 0	; new rib
	call malloc
	push rax
	mov rdi, 8 * 1	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_0406:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_0406
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0406
.L_lambda_simple_env_end_0406:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0406:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_0406
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0406
.L_lambda_simple_params_end_0406:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0406
	jmp .L_lambda_simple_end_0406
.L_lambda_simple_code_0406:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 2
	je .L_lambda_simple_arity_check_ok_0406
	push qword [rsp + 8 * 2]
	push 2
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0406:
	enter 0, 0
	; preparing a tail-call
	mov rax, L_constants + 2335
	push rax
	push 1	; arg count
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 2	; new rib
	call malloc
	push rax
	mov rdi, 8 * 2	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_0407:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
	je .L_lambda_simple_env_end_0407
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0407
.L_lambda_simple_env_end_0407:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0407:	; copy params
	cmp rsi, 2
	je .L_lambda_simple_params_end_0407
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0407
.L_lambda_simple_params_end_0407:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0407
	jmp .L_lambda_simple_end_0407
.L_lambda_simple_code_0407:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0407
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0407:
	enter 0, 0

	mov rdi, 8
	call malloc
	mov rbx, PARAM(0)	; param run
	mov [rax], rbx	; box run
	mov PARAM(0), rax	; replace param with box
	mov rax, sob_void

	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 1	; new rib
	call malloc
	push rax
	mov rdi, 8 * 3	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_0408:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 2
	je .L_lambda_simple_env_end_0408
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0408
.L_lambda_simple_env_end_0408:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0408:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_0408
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0408
.L_lambda_simple_params_end_0408:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0408
	jmp .L_lambda_simple_end_0408
.L_lambda_simple_code_0408:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 5
	je .L_lambda_simple_arity_check_ok_0408
	push qword [rsp + 8 * 2]
	push 5
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0408:
	enter 0, 0
	; preparing a non-tail-call
	mov rax, PARAM(2)	; param len1
	push rax
	mov rax, PARAM(0)	; param i
	push rax
	push 2	; arg count
	mov rax, qword [free_var_6]	; free var =
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_02fd
	; preparing a non-tail-call
	mov rax, PARAM(4)	; param len2
	push rax
	mov rax, PARAM(2)	; param len1
	push rax
	push 2	; arg count
	mov rax, qword [free_var_4]	; free var <
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_02fd
.L_if_else_02fd:
	mov rax, L_constants + 2
.L_if_end_02fd:
	cmp rax, sob_boolean_false
	jne .L_or_end_004d
	; preparing a non-tail-call
	mov rax, PARAM(2)	; param len1
	push rax
	mov rax, PARAM(0)	; param i
	push rax
	push 2	; arg count
	mov rax, qword [free_var_4]	; free var <
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_02ff
	; preparing a non-tail-call
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param i
	push rax
	mov rax, PARAM(3)	; param str2
	push rax
	push 2	; arg count
	mov rax, qword [free_var_155]	; free var string-ref
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param i
	push rax
	mov rax, PARAM(1)	; param str1
	push rax
	push 2	; arg count
	mov rax, qword [free_var_155]	; free var string-ref
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 2	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 1]
	mov rax, qword [rax + 8 * 0]	; bound var char<?
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	jne .L_or_end_004e
	; preparing a non-tail-call
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param i
	push rax
	mov rax, PARAM(3)	; param str2
	push rax
	push 2	; arg count
	mov rax, qword [free_var_155]	; free var string-ref
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param i
	push rax
	mov rax, PARAM(1)	; param str1
	push rax
	push 2	; arg count
	mov rax, qword [free_var_155]	; free var string-ref
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 2	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 1]
	mov rax, qword [rax + 8 * 1]	; bound var char=?
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_02fe
	; preparing a tail-call
	mov rax, PARAM(4)	; param len2
	push rax
	mov rax, PARAM(3)	; param str2
	push rax
	mov rax, PARAM(2)	; param len1
	push rax
	mov rax, PARAM(1)	; param str1
	push rax
	; preparing a non-tail-call
	mov rax, L_constants + 2810
	push rax
	mov rax, PARAM(0)	; param i
	push rax
	push 2	; arg count
	mov rax, qword [free_var_1]	; free var +
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 5	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var run
	mov rax, qword [rax]
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; old return address
	push qword [rbp]	; old frame-pointer
	mov rcx, 9
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8]
.L_tc_recycle_frame_loop_0556:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0556
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8
	sub rdx, 8
	jmp .L_tc_recycle_frame_loop_0556
.L_tc_recycle_frame_done_0556:
	lea rsp, [rbx + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_02fe
.L_if_else_02fe:
	mov rax, L_constants + 2
.L_if_end_02fe:
.L_or_end_004e:
	jmp .L_if_end_02ff
.L_if_else_02ff:
	mov rax, L_constants + 2
.L_if_end_02ff:
.L_or_end_004d:
	leave
	ret AND_KILL_FRAME(5)
.L_lambda_simple_end_0408:	; new closure is in rax

	push rax
	mov rax, PARAM(0)	; param run

	pop qword[rax]
	mov rax, sob_void

	; preparing a tail-call
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 1	; new rib
	call malloc
	push rax
	mov rdi, 8 * 3	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_0409:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 2
	je .L_lambda_simple_env_end_0409
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0409
.L_lambda_simple_env_end_0409:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0409:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_0409
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0409
.L_lambda_simple_params_end_0409:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0409
	jmp .L_lambda_simple_end_0409
.L_lambda_simple_code_0409:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 2
	je .L_lambda_simple_arity_check_ok_0409
	push qword [rsp + 8 * 2]
	push 2
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0409:
	enter 0, 0
	; preparing a tail-call
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param str2
	push rax
	push 1	; arg count
	mov rax, qword [free_var_154]	; free var string-length
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param str1
	push rax
	push 1	; arg count
	mov rax, qword [free_var_154]	; free var string-length
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 2	; arg count
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 2	; new rib
	call malloc
	push rax
	mov rdi, 8 * 4	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_040a:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 3
	je .L_lambda_simple_env_end_040a
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_040a
.L_lambda_simple_env_end_040a:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_040a:	; copy params
	cmp rsi, 2
	je .L_lambda_simple_params_end_040a
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_040a
.L_lambda_simple_params_end_040a:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_040a
	jmp .L_lambda_simple_end_040a
.L_lambda_simple_code_040a:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 2
	je .L_lambda_simple_arity_check_ok_040a
	push qword [rsp + 8 * 2]
	push 2
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_040a:
	enter 0, 0
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param len2
	push rax
	mov rax, PARAM(0)	; param len1
	push rax
	push 2	; arg count
	mov rax, qword [free_var_5]	; free var <=
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_0300
	; preparing a tail-call
	mov rax, PARAM(1)	; param len2
	push rax
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 1]	; bound var str2
	push rax
	mov rax, PARAM(0)	; param len1
	push rax
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var str1
	push rax
	mov rax, L_constants + 2558
	push rax
	push 5	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 1]
	mov rax, qword [rax + 8 * 0]	; bound var run
	mov rax, qword [rax]
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; old return address
	push qword [rbp]	; old frame-pointer
	mov rcx, 9
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8]
.L_tc_recycle_frame_loop_0557:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0557
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8
	sub rdx, 8
	jmp .L_tc_recycle_frame_loop_0557
.L_tc_recycle_frame_done_0557:
	lea rsp, [rbx + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_0300
.L_if_else_0300:
	; preparing a tail-call
	mov rax, PARAM(0)	; param len1
	push rax
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var str1
	push rax
	mov rax, PARAM(1)	; param len2
	push rax
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 1]	; bound var str2
	push rax
	mov rax, L_constants + 2558
	push rax
	push 5	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 1]
	mov rax, qword [rax + 8 * 0]	; bound var run
	mov rax, qword [rax]
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; old return address
	push qword [rbp]	; old frame-pointer
	mov rcx, 9
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8]
.L_tc_recycle_frame_loop_0558:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0558
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8
	sub rdx, 8
	jmp .L_tc_recycle_frame_loop_0558
.L_tc_recycle_frame_done_0558:
	lea rsp, [rbx + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
.L_if_end_0300:
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_simple_end_040a:	; new closure is in rax
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; old return address
	push qword [rbp]	; old frame-pointer
	mov rcx, 6
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8]
.L_tc_recycle_frame_loop_0559:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0559
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8
	sub rdx, 8
	jmp .L_tc_recycle_frame_loop_0559
.L_tc_recycle_frame_done_0559:
	lea rsp, [rbx + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_simple_end_0409:	; new closure is in rax
	push rax
	push 1	; arg count
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 1	; new rib
	call malloc
	push rax
	mov rdi, 8 * 3	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_040b:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 2
	je .L_lambda_simple_env_end_040b
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_040b
.L_lambda_simple_env_end_040b:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_040b:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_040b
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_040b
.L_lambda_simple_params_end_040b:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_040b
	jmp .L_lambda_simple_end_040b
.L_lambda_simple_code_040b:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_040b
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_040b:
	enter 0, 0
	; preparing a tail-call
	mov rax, L_constants + 2335
	push rax
	push 1	; arg count
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 1	; new rib
	call malloc
	push rax
	mov rdi, 8 * 4	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_040c:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 3
	je .L_lambda_simple_env_end_040c
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_040c
.L_lambda_simple_env_end_040c:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_040c:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_040c
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_040c
.L_lambda_simple_params_end_040c:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_040c
	jmp .L_lambda_simple_end_040c
.L_lambda_simple_code_040c:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_040c
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_040c:
	enter 0, 0

	mov rdi, 8
	call malloc
	mov rbx, PARAM(0)	; param run
	mov [rax], rbx	; box run
	mov PARAM(0), rax	; replace param with box
	mov rax, sob_void

	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 1	; new rib
	call malloc
	push rax
	mov rdi, 8 * 5	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_040d:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 4
	je .L_lambda_simple_env_end_040d
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_040d
.L_lambda_simple_env_end_040d:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_040d:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_040d
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_040d
.L_lambda_simple_params_end_040d:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_040d
	jmp .L_lambda_simple_end_040d
.L_lambda_simple_code_040d:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 2
	je .L_lambda_simple_arity_check_ok_040d
	push qword [rsp + 8 * 2]
	push 2
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_040d:
	enter 0, 0
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param strs
	push rax
	push 1	; arg count
	mov rax, qword [free_var_126]	; free var null?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	jne .L_or_end_004f
	; preparing a non-tail-call
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param strs
	push rax
	push 1	; arg count
	mov rax, qword [free_var_54]	; free var car
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	mov rax, PARAM(0)	; param str
	push rax
	push 2	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 1]
	mov rax, qword [rax + 8 * 0]	; bound var binary-string<?
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_0301
	; preparing a tail-call
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param strs
	push rax
	push 1	; arg count
	mov rax, qword [free_var_69]	; free var cdr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param strs
	push rax
	push 1	; arg count
	mov rax, qword [free_var_54]	; free var car
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 2	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var run
	mov rax, qword [rax]
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; old return address
	push qword [rbp]	; old frame-pointer
	mov rcx, 6
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8]
.L_tc_recycle_frame_loop_055a:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_055a
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8
	sub rdx, 8
	jmp .L_tc_recycle_frame_loop_055a
.L_tc_recycle_frame_done_055a:
	lea rsp, [rbx + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_0301
.L_if_else_0301:
	mov rax, L_constants + 2
.L_if_end_0301:
.L_or_end_004f:
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_simple_end_040d:	; new closure is in rax

	push rax
	mov rax, PARAM(0)	; param run

	pop qword[rax]
	mov rax, sob_void

	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 1	; new rib
	call malloc
	push rax
	mov rdi, 8 * 5	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_opt_env_loop_008a:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 4
	je .L_lambda_opt_env_end_008a
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_opt_env_loop_008a
.L_lambda_opt_env_end_008a:
	pop rbx
	mov rsi, 0
.L_lambda_opt_params_loop_008a:	; copy params
	cmp rsi, 1
	je .L_lambda_opt_params_end_008a
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_opt_params_loop_008a
.L_lambda_opt_params_end_008a:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_opt_code_008a
	jmp .L_lambda_opt_end_008a
.L_lambda_opt_code_008a:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1 ;	 check num of args
	je .L_lambda_opt_arity_check_exact_008a ;	 if equal, go to exact arity
	jg .L_lambda_opt_arity_check_more_008a ;	 if greater than, go to arity more
	push qword [rsp + 8 * 2] ;	 else, throw opt arity error
	push 1
	jmp L_error_incorrect_arity_opt
.L_lambda_opt_arity_check_exact_008a:
	mov rax, qword [rsp + 8 * 2] ;	 number of args
	lea rbx, [rsp + 8 * (2 + rax)] ;	 address of last element
	sub rsp, 8
	lea rcx, [rsp + 0] ;	 new start
.L_lambda_opt_shift_entry_008a:
	mov rdx, [rcx + 8]
	mov [rcx], rdx
	add rcx, 8
	cmp rbx, rcx
	jne .L_lambda_opt_shift_entry_008a
.L_lambda_opt_shift_exit_008a:
	mov qword[rbx], sob_nil ;	 place nil
	add rax, 1
	mov qword [rsp + 8 * 2], rax
	jmp .L_lambda_opt_stack_adjusted_008a
.L_lambda_opt_arity_check_more_008a:
	mov rdx, sob_nil ;	 base cdr
	cmp qword [rsp + 8 * 2], 2
	je .L_lambda_opt_stack_shrink_loop_exit_008a
.L_lambda_opt_stack_shrink_loop_008a:
	mov rdi, (1 + 8 + 8)
	call malloc
	mov byte[rax], T_pair
	mov SOB_PAIR_CDR(rax), rdx
	mov rdx, rax
	mov rax, qword [rsp + 8 * 2]
	mov rbx, qword [rsp + 8 * (2 + rax)]
	mov SOB_PAIR_CAR(rdx), rbx
	lea rbx, [rsp + 8 * (2 + rax - 1)]
.L_lambda_opt_extra_shift_process_008a:
	mov rcx, [rbx]
	mov [rbx + 8], rcx
	sub rbx, 8
	cmp rsp, rbx
	jle .L_lambda_opt_extra_shift_process_008a
.L_lambda_opt_extra_shift_process_end_008a:
	add rsp, 8
	mov rbx, [rsp + 8 * 2]
	sub rbx, 1
	mov [rsp + 8 * 2], rbx
	cmp qword [rsp + 8 * 2], 2
	jg .L_lambda_opt_stack_shrink_loop_008a
.L_lambda_opt_stack_shrink_loop_exit_008a:
	mov rcx, [rsp + 8 * 2]
	mov rbx, qword [rsp + 8 * (2 + rcx)]
	mov rdi, (1 + 8 + 8)
	call malloc
	mov byte[rax], T_pair
	mov SOB_PAIR_CDR(rax), rdx
	mov SOB_PAIR_CAR(rax), rbx
	mov [rsp + 8 * (2 + rcx)], rax
.L_lambda_opt_stack_adjusted_008a:
	enter 0, 0
	; preparing a tail-call
	mov rax, PARAM(1)	; param strs
	push rax
	mov rax, PARAM(0)	; param str
	push rax
	push 2	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var run
	mov rax, qword [rax]
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; old return address
	push qword [rbp]	; old frame-pointer
	mov rcx, 6
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8]
.L_tc_recycle_frame_loop_055b:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_055b
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8
	sub rdx, 8
	jmp .L_tc_recycle_frame_loop_055b
.L_tc_recycle_frame_done_055b:
	lea rsp, [rbx + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_opt_end_008a:	; new closure is in rax
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_040c:	; new closure is in rax
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; old return address
	push qword [rbp]	; old frame-pointer
	mov rcx, 5
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8]
.L_tc_recycle_frame_loop_055c:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_055c
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8
	sub rdx, 8
	jmp .L_tc_recycle_frame_loop_055c
.L_tc_recycle_frame_done_055c:
	lea rsp, [rbx + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_040b:	; new closure is in rax
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; old return address
	push qword [rbp]	; old frame-pointer
	mov rcx, 5
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8]
.L_tc_recycle_frame_loop_055d:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_055d
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8
	sub rdx, 8
	jmp .L_tc_recycle_frame_loop_055d
.L_tc_recycle_frame_done_055d:
	lea rsp, [rbx + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0407:	; new closure is in rax
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; old return address
	push qword [rbp]	; old frame-pointer
	mov rcx, 5
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8]
.L_tc_recycle_frame_loop_055e:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_055e
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8
	sub rdx, 8
	jmp .L_tc_recycle_frame_loop_055e
.L_tc_recycle_frame_done_055e:
	lea rsp, [rbx + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_simple_end_0406:	; new closure is in rax
	push rax
	push 1	; arg count
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 0	; new rib
	call malloc
	push rax
	mov rdi, 8 * 1	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_040e:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_040e
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_040e
.L_lambda_simple_env_end_040e:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_040e:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_040e
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_040e
.L_lambda_simple_params_end_040e:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_040e
	jmp .L_lambda_simple_end_040e
.L_lambda_simple_code_040e:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_040e
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_040e:
	enter 0, 0
	; preparing a non-tail-call
	mov rax, qword [free_var_80]	; free var char=?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	push rax
	mov rax, qword [free_var_79]	; free var char<?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	push rax
	push 2	; arg count
	mov rax, PARAM(0)	; param make-string<?
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	mov qword [free_var_161], rax	; free var string<?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	mov rax, sob_void

	; preparing a non-tail-call
	mov rax, qword [free_var_73]	; free var char-ci=?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	push rax
	mov rax, qword [free_var_72]	; free var char-ci<?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	push rax
	push 2	; arg count
	mov rax, PARAM(0)	; param make-string<?
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	mov qword [free_var_149], rax	; free var string-ci<?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	mov rax, sob_void

	; preparing a non-tail-call
	mov rax, qword [free_var_80]	; free var char=?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	push rax
	mov rax, qword [free_var_82]	; free var char>?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	push rax
	push 2	; arg count
	mov rax, PARAM(0)	; param make-string<?
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	mov qword [free_var_164], rax	; free var string>?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	mov rax, sob_void

	; preparing a non-tail-call
	mov rax, qword [free_var_73]	; free var char-ci=?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	push rax
	mov rax, qword [free_var_75]	; free var char-ci>?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	push rax
	push 2	; arg count
	mov rax, PARAM(0)	; param make-string<?
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	mov qword [free_var_152], rax	; free var string-ci>?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	mov rax, sob_void
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_040e:	; new closure is in rax
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)

	mov rdi, rax
	call print_sexpr_if_not_void

	; preparing a non-tail-call
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 0	; new rib
	call malloc
	push rax
	mov rdi, 8 * 1	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_040f:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_040f
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_040f
.L_lambda_simple_env_end_040f:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_040f:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_040f
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_040f
.L_lambda_simple_params_end_040f:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_040f
	jmp .L_lambda_simple_end_040f
.L_lambda_simple_code_040f:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 2
	je .L_lambda_simple_arity_check_ok_040f
	push qword [rsp + 8 * 2]
	push 2
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_040f:
	enter 0, 0
	; preparing a tail-call
	mov rax, L_constants + 2335
	push rax
	push 1	; arg count
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 2	; new rib
	call malloc
	push rax
	mov rdi, 8 * 2	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_0410:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
	je .L_lambda_simple_env_end_0410
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0410
.L_lambda_simple_env_end_0410:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0410:	; copy params
	cmp rsi, 2
	je .L_lambda_simple_params_end_0410
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0410
.L_lambda_simple_params_end_0410:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0410
	jmp .L_lambda_simple_end_0410
.L_lambda_simple_code_0410:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0410
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0410:
	enter 0, 0

	mov rdi, 8
	call malloc
	mov rbx, PARAM(0)	; param run
	mov [rax], rbx	; box run
	mov PARAM(0), rax	; replace param with box
	mov rax, sob_void

	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 1	; new rib
	call malloc
	push rax
	mov rdi, 8 * 3	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_0411:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 2
	je .L_lambda_simple_env_end_0411
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0411
.L_lambda_simple_env_end_0411:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0411:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_0411
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0411
.L_lambda_simple_params_end_0411:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0411
	jmp .L_lambda_simple_end_0411
.L_lambda_simple_code_0411:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 5
	je .L_lambda_simple_arity_check_ok_0411
	push qword [rsp + 8 * 2]
	push 5
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0411:
	enter 0, 0
	; preparing a non-tail-call
	mov rax, PARAM(2)	; param len1
	push rax
	mov rax, PARAM(0)	; param i
	push rax
	push 2	; arg count
	mov rax, qword [free_var_6]	; free var =
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	jne .L_or_end_0050
	; preparing a non-tail-call
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param i
	push rax
	mov rax, PARAM(3)	; param str2
	push rax
	push 2	; arg count
	mov rax, qword [free_var_155]	; free var string-ref
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param i
	push rax
	mov rax, PARAM(1)	; param str1
	push rax
	push 2	; arg count
	mov rax, qword [free_var_155]	; free var string-ref
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 2	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 1]
	mov rax, qword [rax + 8 * 0]	; bound var char<?
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	jne .L_or_end_0050
	; preparing a non-tail-call
	mov rax, PARAM(2)	; param len1
	push rax
	mov rax, PARAM(0)	; param i
	push rax
	push 2	; arg count
	mov rax, qword [free_var_4]	; free var <
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_0303
	; preparing a non-tail-call
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param i
	push rax
	mov rax, PARAM(3)	; param str2
	push rax
	push 2	; arg count
	mov rax, qword [free_var_155]	; free var string-ref
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param i
	push rax
	mov rax, PARAM(1)	; param str1
	push rax
	push 2	; arg count
	mov rax, qword [free_var_155]	; free var string-ref
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 2	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 1]
	mov rax, qword [rax + 8 * 1]	; bound var char=?
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_0302
	; preparing a tail-call
	mov rax, PARAM(4)	; param len2
	push rax
	mov rax, PARAM(3)	; param str2
	push rax
	mov rax, PARAM(2)	; param len1
	push rax
	mov rax, PARAM(1)	; param str1
	push rax
	; preparing a non-tail-call
	mov rax, L_constants + 2810
	push rax
	mov rax, PARAM(0)	; param i
	push rax
	push 2	; arg count
	mov rax, qword [free_var_1]	; free var +
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 5	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var run
	mov rax, qword [rax]
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; old return address
	push qword [rbp]	; old frame-pointer
	mov rcx, 9
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8]
.L_tc_recycle_frame_loop_055f:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_055f
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8
	sub rdx, 8
	jmp .L_tc_recycle_frame_loop_055f
.L_tc_recycle_frame_done_055f:
	lea rsp, [rbx + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_0302
.L_if_else_0302:
	mov rax, L_constants + 2
.L_if_end_0302:
	jmp .L_if_end_0303
.L_if_else_0303:
	mov rax, L_constants + 2
.L_if_end_0303:
.L_or_end_0050:
	leave
	ret AND_KILL_FRAME(5)
.L_lambda_simple_end_0411:	; new closure is in rax

	push rax
	mov rax, PARAM(0)	; param run

	pop qword[rax]
	mov rax, sob_void

	; preparing a tail-call
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 1	; new rib
	call malloc
	push rax
	mov rdi, 8 * 3	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_0412:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 2
	je .L_lambda_simple_env_end_0412
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0412
.L_lambda_simple_env_end_0412:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0412:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_0412
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0412
.L_lambda_simple_params_end_0412:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0412
	jmp .L_lambda_simple_end_0412
.L_lambda_simple_code_0412:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 2
	je .L_lambda_simple_arity_check_ok_0412
	push qword [rsp + 8 * 2]
	push 2
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0412:
	enter 0, 0
	; preparing a tail-call
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param str2
	push rax
	push 1	; arg count
	mov rax, qword [free_var_154]	; free var string-length
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param str1
	push rax
	push 1	; arg count
	mov rax, qword [free_var_154]	; free var string-length
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 2	; arg count
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 2	; new rib
	call malloc
	push rax
	mov rdi, 8 * 4	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_0413:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 3
	je .L_lambda_simple_env_end_0413
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0413
.L_lambda_simple_env_end_0413:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0413:	; copy params
	cmp rsi, 2
	je .L_lambda_simple_params_end_0413
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0413
.L_lambda_simple_params_end_0413:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0413
	jmp .L_lambda_simple_end_0413
.L_lambda_simple_code_0413:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 2
	je .L_lambda_simple_arity_check_ok_0413
	push qword [rsp + 8 * 2]
	push 2
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0413:
	enter 0, 0
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param len2
	push rax
	mov rax, PARAM(0)	; param len1
	push rax
	push 2	; arg count
	mov rax, qword [free_var_5]	; free var <=
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_0304
	; preparing a tail-call
	mov rax, PARAM(1)	; param len2
	push rax
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 1]	; bound var str2
	push rax
	mov rax, PARAM(0)	; param len1
	push rax
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var str1
	push rax
	mov rax, L_constants + 2558
	push rax
	push 5	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 1]
	mov rax, qword [rax + 8 * 0]	; bound var run
	mov rax, qword [rax]
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; old return address
	push qword [rbp]	; old frame-pointer
	mov rcx, 9
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8]
.L_tc_recycle_frame_loop_0560:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0560
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8
	sub rdx, 8
	jmp .L_tc_recycle_frame_loop_0560
.L_tc_recycle_frame_done_0560:
	lea rsp, [rbx + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_0304
.L_if_else_0304:
	; preparing a tail-call
	mov rax, PARAM(0)	; param len1
	push rax
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var str1
	push rax
	mov rax, PARAM(1)	; param len2
	push rax
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 1]	; bound var str2
	push rax
	mov rax, L_constants + 2558
	push rax
	push 5	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 1]
	mov rax, qword [rax + 8 * 0]	; bound var run
	mov rax, qword [rax]
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; old return address
	push qword [rbp]	; old frame-pointer
	mov rcx, 9
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8]
.L_tc_recycle_frame_loop_0561:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0561
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8
	sub rdx, 8
	jmp .L_tc_recycle_frame_loop_0561
.L_tc_recycle_frame_done_0561:
	lea rsp, [rbx + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
.L_if_end_0304:
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_simple_end_0413:	; new closure is in rax
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; old return address
	push qword [rbp]	; old frame-pointer
	mov rcx, 6
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8]
.L_tc_recycle_frame_loop_0562:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0562
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8
	sub rdx, 8
	jmp .L_tc_recycle_frame_loop_0562
.L_tc_recycle_frame_done_0562:
	lea rsp, [rbx + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_simple_end_0412:	; new closure is in rax
	push rax
	push 1	; arg count
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 1	; new rib
	call malloc
	push rax
	mov rdi, 8 * 3	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_0414:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 2
	je .L_lambda_simple_env_end_0414
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0414
.L_lambda_simple_env_end_0414:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0414:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_0414
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0414
.L_lambda_simple_params_end_0414:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0414
	jmp .L_lambda_simple_end_0414
.L_lambda_simple_code_0414:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0414
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0414:
	enter 0, 0
	; preparing a tail-call
	mov rax, L_constants + 2335
	push rax
	push 1	; arg count
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 1	; new rib
	call malloc
	push rax
	mov rdi, 8 * 4	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_0415:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 3
	je .L_lambda_simple_env_end_0415
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0415
.L_lambda_simple_env_end_0415:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0415:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_0415
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0415
.L_lambda_simple_params_end_0415:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0415
	jmp .L_lambda_simple_end_0415
.L_lambda_simple_code_0415:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0415
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0415:
	enter 0, 0

	mov rdi, 8
	call malloc
	mov rbx, PARAM(0)	; param run
	mov [rax], rbx	; box run
	mov PARAM(0), rax	; replace param with box
	mov rax, sob_void

	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 1	; new rib
	call malloc
	push rax
	mov rdi, 8 * 5	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_0416:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 4
	je .L_lambda_simple_env_end_0416
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0416
.L_lambda_simple_env_end_0416:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0416:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_0416
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0416
.L_lambda_simple_params_end_0416:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0416
	jmp .L_lambda_simple_end_0416
.L_lambda_simple_code_0416:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 2
	je .L_lambda_simple_arity_check_ok_0416
	push qword [rsp + 8 * 2]
	push 2
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0416:
	enter 0, 0
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param strs
	push rax
	push 1	; arg count
	mov rax, qword [free_var_126]	; free var null?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	jne .L_or_end_0051
	; preparing a non-tail-call
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param strs
	push rax
	push 1	; arg count
	mov rax, qword [free_var_54]	; free var car
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	mov rax, PARAM(0)	; param str
	push rax
	push 2	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 1]
	mov rax, qword [rax + 8 * 0]	; bound var binary-string<=?
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_0305
	; preparing a tail-call
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param strs
	push rax
	push 1	; arg count
	mov rax, qword [free_var_69]	; free var cdr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param strs
	push rax
	push 1	; arg count
	mov rax, qword [free_var_54]	; free var car
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 2	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var run
	mov rax, qword [rax]
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; old return address
	push qword [rbp]	; old frame-pointer
	mov rcx, 6
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8]
.L_tc_recycle_frame_loop_0563:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0563
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8
	sub rdx, 8
	jmp .L_tc_recycle_frame_loop_0563
.L_tc_recycle_frame_done_0563:
	lea rsp, [rbx + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_0305
.L_if_else_0305:
	mov rax, L_constants + 2
.L_if_end_0305:
.L_or_end_0051:
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_simple_end_0416:	; new closure is in rax

	push rax
	mov rax, PARAM(0)	; param run

	pop qword[rax]
	mov rax, sob_void

	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 1	; new rib
	call malloc
	push rax
	mov rdi, 8 * 5	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_opt_env_loop_008b:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 4
	je .L_lambda_opt_env_end_008b
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_opt_env_loop_008b
.L_lambda_opt_env_end_008b:
	pop rbx
	mov rsi, 0
.L_lambda_opt_params_loop_008b:	; copy params
	cmp rsi, 1
	je .L_lambda_opt_params_end_008b
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_opt_params_loop_008b
.L_lambda_opt_params_end_008b:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_opt_code_008b
	jmp .L_lambda_opt_end_008b
.L_lambda_opt_code_008b:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1 ;	 check num of args
	je .L_lambda_opt_arity_check_exact_008b ;	 if equal, go to exact arity
	jg .L_lambda_opt_arity_check_more_008b ;	 if greater than, go to arity more
	push qword [rsp + 8 * 2] ;	 else, throw opt arity error
	push 1
	jmp L_error_incorrect_arity_opt
.L_lambda_opt_arity_check_exact_008b:
	mov rax, qword [rsp + 8 * 2] ;	 number of args
	lea rbx, [rsp + 8 * (2 + rax)] ;	 address of last element
	sub rsp, 8
	lea rcx, [rsp + 0] ;	 new start
.L_lambda_opt_shift_entry_008b:
	mov rdx, [rcx + 8]
	mov [rcx], rdx
	add rcx, 8
	cmp rbx, rcx
	jne .L_lambda_opt_shift_entry_008b
.L_lambda_opt_shift_exit_008b:
	mov qword[rbx], sob_nil ;	 place nil
	add rax, 1
	mov qword [rsp + 8 * 2], rax
	jmp .L_lambda_opt_stack_adjusted_008b
.L_lambda_opt_arity_check_more_008b:
	mov rdx, sob_nil ;	 base cdr
	cmp qword [rsp + 8 * 2], 2
	je .L_lambda_opt_stack_shrink_loop_exit_008b
.L_lambda_opt_stack_shrink_loop_008b:
	mov rdi, (1 + 8 + 8)
	call malloc
	mov byte[rax], T_pair
	mov SOB_PAIR_CDR(rax), rdx
	mov rdx, rax
	mov rax, qword [rsp + 8 * 2]
	mov rbx, qword [rsp + 8 * (2 + rax)]
	mov SOB_PAIR_CAR(rdx), rbx
	lea rbx, [rsp + 8 * (2 + rax - 1)]
.L_lambda_opt_extra_shift_process_008b:
	mov rcx, [rbx]
	mov [rbx + 8], rcx
	sub rbx, 8
	cmp rsp, rbx
	jle .L_lambda_opt_extra_shift_process_008b
.L_lambda_opt_extra_shift_process_end_008b:
	add rsp, 8
	mov rbx, [rsp + 8 * 2]
	sub rbx, 1
	mov [rsp + 8 * 2], rbx
	cmp qword [rsp + 8 * 2], 2
	jg .L_lambda_opt_stack_shrink_loop_008b
.L_lambda_opt_stack_shrink_loop_exit_008b:
	mov rcx, [rsp + 8 * 2]
	mov rbx, qword [rsp + 8 * (2 + rcx)]
	mov rdi, (1 + 8 + 8)
	call malloc
	mov byte[rax], T_pair
	mov SOB_PAIR_CDR(rax), rdx
	mov SOB_PAIR_CAR(rax), rbx
	mov [rsp + 8 * (2 + rcx)], rax
.L_lambda_opt_stack_adjusted_008b:
	enter 0, 0
	; preparing a tail-call
	mov rax, PARAM(1)	; param strs
	push rax
	mov rax, PARAM(0)	; param str
	push rax
	push 2	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var run
	mov rax, qword [rax]
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; old return address
	push qword [rbp]	; old frame-pointer
	mov rcx, 6
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8]
.L_tc_recycle_frame_loop_0564:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0564
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8
	sub rdx, 8
	jmp .L_tc_recycle_frame_loop_0564
.L_tc_recycle_frame_done_0564:
	lea rsp, [rbx + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_opt_end_008b:	; new closure is in rax
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0415:	; new closure is in rax
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; old return address
	push qword [rbp]	; old frame-pointer
	mov rcx, 5
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8]
.L_tc_recycle_frame_loop_0565:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0565
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8
	sub rdx, 8
	jmp .L_tc_recycle_frame_loop_0565
.L_tc_recycle_frame_done_0565:
	lea rsp, [rbx + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0414:	; new closure is in rax
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; old return address
	push qword [rbp]	; old frame-pointer
	mov rcx, 5
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8]
.L_tc_recycle_frame_loop_0566:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0566
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8
	sub rdx, 8
	jmp .L_tc_recycle_frame_loop_0566
.L_tc_recycle_frame_done_0566:
	lea rsp, [rbx + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0410:	; new closure is in rax
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; old return address
	push qword [rbp]	; old frame-pointer
	mov rcx, 5
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8]
.L_tc_recycle_frame_loop_0567:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0567
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8
	sub rdx, 8
	jmp .L_tc_recycle_frame_loop_0567
.L_tc_recycle_frame_done_0567:
	lea rsp, [rbx + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_simple_end_040f:	; new closure is in rax
	push rax
	push 1	; arg count
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 0	; new rib
	call malloc
	push rax
	mov rdi, 8 * 1	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_0417:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_0417
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0417
.L_lambda_simple_env_end_0417:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0417:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_0417
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0417
.L_lambda_simple_params_end_0417:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0417
	jmp .L_lambda_simple_end_0417
.L_lambda_simple_code_0417:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0417
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0417:
	enter 0, 0
	; preparing a non-tail-call
	mov rax, qword [free_var_80]	; free var char=?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	push rax
	mov rax, qword [free_var_79]	; free var char<?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	push rax
	push 2	; arg count
	mov rax, PARAM(0)	; param make-string<=?
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	mov qword [free_var_160], rax	; free var string<=?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	mov rax, sob_void

	; preparing a non-tail-call
	mov rax, qword [free_var_73]	; free var char-ci=?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	push rax
	mov rax, qword [free_var_72]	; free var char-ci<?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	push rax
	push 2	; arg count
	mov rax, PARAM(0)	; param make-string<=?
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	mov qword [free_var_148], rax	; free var string-ci<=?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	mov rax, sob_void

	; preparing a non-tail-call
	mov rax, qword [free_var_80]	; free var char=?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	push rax
	mov rax, qword [free_var_82]	; free var char>?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	push rax
	push 2	; arg count
	mov rax, PARAM(0)	; param make-string<=?
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	mov qword [free_var_163], rax	; free var string>=?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	mov rax, sob_void

	; preparing a non-tail-call
	mov rax, qword [free_var_73]	; free var char-ci=?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	push rax
	mov rax, qword [free_var_75]	; free var char-ci>?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	push rax
	push 2	; arg count
	mov rax, PARAM(0)	; param make-string<=?
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	mov qword [free_var_151], rax	; free var string-ci>=?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	mov rax, sob_void
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0417:	; new closure is in rax
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)

	mov rdi, rax
	call print_sexpr_if_not_void

	; preparing a non-tail-call
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 0	; new rib
	call malloc
	push rax
	mov rdi, 8 * 1	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_0418:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_0418
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0418
.L_lambda_simple_env_end_0418:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0418:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_0418
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0418
.L_lambda_simple_params_end_0418:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0418
	jmp .L_lambda_simple_end_0418
.L_lambda_simple_code_0418:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0418
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0418:
	enter 0, 0
	; preparing a tail-call
	mov rax, L_constants + 2335
	push rax
	push 1	; arg count
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 1	; new rib
	call malloc
	push rax
	mov rdi, 8 * 2	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_0419:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
	je .L_lambda_simple_env_end_0419
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0419
.L_lambda_simple_env_end_0419:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0419:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_0419
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0419
.L_lambda_simple_params_end_0419:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0419
	jmp .L_lambda_simple_end_0419
.L_lambda_simple_code_0419:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0419
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0419:
	enter 0, 0

	mov rdi, 8
	call malloc
	mov rbx, PARAM(0)	; param run
	mov [rax], rbx	; box run
	mov PARAM(0), rax	; replace param with box
	mov rax, sob_void

	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 1	; new rib
	call malloc
	push rax
	mov rdi, 8 * 3	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_041a:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 2
	je .L_lambda_simple_env_end_041a
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_041a
.L_lambda_simple_env_end_041a:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_041a:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_041a
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_041a
.L_lambda_simple_params_end_041a:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_041a
	jmp .L_lambda_simple_end_041a
.L_lambda_simple_code_041a:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 4
	je .L_lambda_simple_arity_check_ok_041a
	push qword [rsp + 8 * 2]
	push 4
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_041a:
	enter 0, 0
	; preparing a non-tail-call
	mov rax, PARAM(3)	; param len
	push rax
	mov rax, PARAM(0)	; param i
	push rax
	push 2	; arg count
	mov rax, qword [free_var_6]	; free var =
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	jne .L_or_end_0052
	; preparing a non-tail-call
	mov rax, PARAM(3)	; param len
	push rax
	mov rax, PARAM(0)	; param i
	push rax
	push 2	; arg count
	mov rax, qword [free_var_4]	; free var <
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_0307
	; preparing a non-tail-call
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param i
	push rax
	mov rax, PARAM(2)	; param str2
	push rax
	push 2	; arg count
	mov rax, qword [free_var_155]	; free var string-ref
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param i
	push rax
	mov rax, PARAM(1)	; param str1
	push rax
	push 2	; arg count
	mov rax, qword [free_var_155]	; free var string-ref
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 2	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 1]
	mov rax, qword [rax + 8 * 0]	; bound var char=?
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_0306
	; preparing a tail-call
	mov rax, PARAM(3)	; param len
	push rax
	mov rax, PARAM(2)	; param str2
	push rax
	mov rax, PARAM(1)	; param str1
	push rax
	; preparing a non-tail-call
	mov rax, L_constants + 2810
	push rax
	mov rax, PARAM(0)	; param i
	push rax
	push 2	; arg count
	mov rax, qword [free_var_1]	; free var +
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 4	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var run
	mov rax, qword [rax]
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; old return address
	push qword [rbp]	; old frame-pointer
	mov rcx, 8
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8]
.L_tc_recycle_frame_loop_0568:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0568
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8
	sub rdx, 8
	jmp .L_tc_recycle_frame_loop_0568
.L_tc_recycle_frame_done_0568:
	lea rsp, [rbx + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_0306
.L_if_else_0306:
	mov rax, L_constants + 2
.L_if_end_0306:
	jmp .L_if_end_0307
.L_if_else_0307:
	mov rax, L_constants + 2
.L_if_end_0307:
.L_or_end_0052:
	leave
	ret AND_KILL_FRAME(4)
.L_lambda_simple_end_041a:	; new closure is in rax

	push rax
	mov rax, PARAM(0)	; param run

	pop qword[rax]
	mov rax, sob_void

	; preparing a tail-call
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 1	; new rib
	call malloc
	push rax
	mov rdi, 8 * 3	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_041b:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 2
	je .L_lambda_simple_env_end_041b
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_041b
.L_lambda_simple_env_end_041b:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_041b:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_041b
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_041b
.L_lambda_simple_params_end_041b:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_041b
	jmp .L_lambda_simple_end_041b
.L_lambda_simple_code_041b:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 2
	je .L_lambda_simple_arity_check_ok_041b
	push qword [rsp + 8 * 2]
	push 2
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_041b:
	enter 0, 0
	; preparing a tail-call
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param str2
	push rax
	push 1	; arg count
	mov rax, qword [free_var_154]	; free var string-length
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param str1
	push rax
	push 1	; arg count
	mov rax, qword [free_var_154]	; free var string-length
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 2	; arg count
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 2	; new rib
	call malloc
	push rax
	mov rdi, 8 * 4	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_041c:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 3
	je .L_lambda_simple_env_end_041c
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_041c
.L_lambda_simple_env_end_041c:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_041c:	; copy params
	cmp rsi, 2
	je .L_lambda_simple_params_end_041c
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_041c
.L_lambda_simple_params_end_041c:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_041c
	jmp .L_lambda_simple_end_041c
.L_lambda_simple_code_041c:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 2
	je .L_lambda_simple_arity_check_ok_041c
	push qword [rsp + 8 * 2]
	push 2
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_041c:
	enter 0, 0
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param len2
	push rax
	mov rax, PARAM(0)	; param len1
	push rax
	push 2	; arg count
	mov rax, qword [free_var_6]	; free var =
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_0308
	; preparing a tail-call
	mov rax, PARAM(0)	; param len1
	push rax
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 1]	; bound var str2
	push rax
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var str1
	push rax
	mov rax, L_constants + 2558
	push rax
	push 4	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 1]
	mov rax, qword [rax + 8 * 0]	; bound var run
	mov rax, qword [rax]
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; old return address
	push qword [rbp]	; old frame-pointer
	mov rcx, 8
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8]
.L_tc_recycle_frame_loop_0569:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0569
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8
	sub rdx, 8
	jmp .L_tc_recycle_frame_loop_0569
.L_tc_recycle_frame_done_0569:
	lea rsp, [rbx + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_0308
.L_if_else_0308:
	mov rax, L_constants + 2
.L_if_end_0308:
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_simple_end_041c:	; new closure is in rax
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; old return address
	push qword [rbp]	; old frame-pointer
	mov rcx, 6
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8]
.L_tc_recycle_frame_loop_056a:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_056a
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8
	sub rdx, 8
	jmp .L_tc_recycle_frame_loop_056a
.L_tc_recycle_frame_done_056a:
	lea rsp, [rbx + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_simple_end_041b:	; new closure is in rax
	push rax
	push 1	; arg count
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 1	; new rib
	call malloc
	push rax
	mov rdi, 8 * 3	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_041d:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 2
	je .L_lambda_simple_env_end_041d
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_041d
.L_lambda_simple_env_end_041d:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_041d:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_041d
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_041d
.L_lambda_simple_params_end_041d:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_041d
	jmp .L_lambda_simple_end_041d
.L_lambda_simple_code_041d:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_041d
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_041d:
	enter 0, 0
	; preparing a tail-call
	mov rax, L_constants + 2335
	push rax
	push 1	; arg count
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 1	; new rib
	call malloc
	push rax
	mov rdi, 8 * 4	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_041e:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 3
	je .L_lambda_simple_env_end_041e
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_041e
.L_lambda_simple_env_end_041e:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_041e:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_041e
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_041e
.L_lambda_simple_params_end_041e:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_041e
	jmp .L_lambda_simple_end_041e
.L_lambda_simple_code_041e:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_041e
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_041e:
	enter 0, 0

	mov rdi, 8
	call malloc
	mov rbx, PARAM(0)	; param run
	mov [rax], rbx	; box run
	mov PARAM(0), rax	; replace param with box
	mov rax, sob_void

	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 1	; new rib
	call malloc
	push rax
	mov rdi, 8 * 5	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_041f:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 4
	je .L_lambda_simple_env_end_041f
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_041f
.L_lambda_simple_env_end_041f:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_041f:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_041f
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_041f
.L_lambda_simple_params_end_041f:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_041f
	jmp .L_lambda_simple_end_041f
.L_lambda_simple_code_041f:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 2
	je .L_lambda_simple_arity_check_ok_041f
	push qword [rsp + 8 * 2]
	push 2
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_041f:
	enter 0, 0
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param strs
	push rax
	push 1	; arg count
	mov rax, qword [free_var_126]	; free var null?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	jne .L_or_end_0053
	; preparing a non-tail-call
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param strs
	push rax
	push 1	; arg count
	mov rax, qword [free_var_54]	; free var car
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	mov rax, PARAM(0)	; param str
	push rax
	push 2	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 1]
	mov rax, qword [rax + 8 * 0]	; bound var binary-string=?
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_0309
	; preparing a tail-call
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param strs
	push rax
	push 1	; arg count
	mov rax, qword [free_var_69]	; free var cdr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param strs
	push rax
	push 1	; arg count
	mov rax, qword [free_var_54]	; free var car
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 2	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var run
	mov rax, qword [rax]
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; old return address
	push qword [rbp]	; old frame-pointer
	mov rcx, 6
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8]
.L_tc_recycle_frame_loop_056b:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_056b
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8
	sub rdx, 8
	jmp .L_tc_recycle_frame_loop_056b
.L_tc_recycle_frame_done_056b:
	lea rsp, [rbx + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_0309
.L_if_else_0309:
	mov rax, L_constants + 2
.L_if_end_0309:
.L_or_end_0053:
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_simple_end_041f:	; new closure is in rax

	push rax
	mov rax, PARAM(0)	; param run

	pop qword[rax]
	mov rax, sob_void

	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 1	; new rib
	call malloc
	push rax
	mov rdi, 8 * 5	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_opt_env_loop_008c:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 4
	je .L_lambda_opt_env_end_008c
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_opt_env_loop_008c
.L_lambda_opt_env_end_008c:
	pop rbx
	mov rsi, 0
.L_lambda_opt_params_loop_008c:	; copy params
	cmp rsi, 1
	je .L_lambda_opt_params_end_008c
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_opt_params_loop_008c
.L_lambda_opt_params_end_008c:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_opt_code_008c
	jmp .L_lambda_opt_end_008c
.L_lambda_opt_code_008c:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1 ;	 check num of args
	je .L_lambda_opt_arity_check_exact_008c ;	 if equal, go to exact arity
	jg .L_lambda_opt_arity_check_more_008c ;	 if greater than, go to arity more
	push qword [rsp + 8 * 2] ;	 else, throw opt arity error
	push 1
	jmp L_error_incorrect_arity_opt
.L_lambda_opt_arity_check_exact_008c:
	mov rax, qword [rsp + 8 * 2] ;	 number of args
	lea rbx, [rsp + 8 * (2 + rax)] ;	 address of last element
	sub rsp, 8
	lea rcx, [rsp + 0] ;	 new start
.L_lambda_opt_shift_entry_008c:
	mov rdx, [rcx + 8]
	mov [rcx], rdx
	add rcx, 8
	cmp rbx, rcx
	jne .L_lambda_opt_shift_entry_008c
.L_lambda_opt_shift_exit_008c:
	mov qword[rbx], sob_nil ;	 place nil
	add rax, 1
	mov qword [rsp + 8 * 2], rax
	jmp .L_lambda_opt_stack_adjusted_008c
.L_lambda_opt_arity_check_more_008c:
	mov rdx, sob_nil ;	 base cdr
	cmp qword [rsp + 8 * 2], 2
	je .L_lambda_opt_stack_shrink_loop_exit_008c
.L_lambda_opt_stack_shrink_loop_008c:
	mov rdi, (1 + 8 + 8)
	call malloc
	mov byte[rax], T_pair
	mov SOB_PAIR_CDR(rax), rdx
	mov rdx, rax
	mov rax, qword [rsp + 8 * 2]
	mov rbx, qword [rsp + 8 * (2 + rax)]
	mov SOB_PAIR_CAR(rdx), rbx
	lea rbx, [rsp + 8 * (2 + rax - 1)]
.L_lambda_opt_extra_shift_process_008c:
	mov rcx, [rbx]
	mov [rbx + 8], rcx
	sub rbx, 8
	cmp rsp, rbx
	jle .L_lambda_opt_extra_shift_process_008c
.L_lambda_opt_extra_shift_process_end_008c:
	add rsp, 8
	mov rbx, [rsp + 8 * 2]
	sub rbx, 1
	mov [rsp + 8 * 2], rbx
	cmp qword [rsp + 8 * 2], 2
	jg .L_lambda_opt_stack_shrink_loop_008c
.L_lambda_opt_stack_shrink_loop_exit_008c:
	mov rcx, [rsp + 8 * 2]
	mov rbx, qword [rsp + 8 * (2 + rcx)]
	mov rdi, (1 + 8 + 8)
	call malloc
	mov byte[rax], T_pair
	mov SOB_PAIR_CDR(rax), rdx
	mov SOB_PAIR_CAR(rax), rbx
	mov [rsp + 8 * (2 + rcx)], rax
.L_lambda_opt_stack_adjusted_008c:
	enter 0, 0
	; preparing a tail-call
	mov rax, PARAM(1)	; param strs
	push rax
	mov rax, PARAM(0)	; param str
	push rax
	push 2	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var run
	mov rax, qword [rax]
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; old return address
	push qword [rbp]	; old frame-pointer
	mov rcx, 6
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8]
.L_tc_recycle_frame_loop_056c:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_056c
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8
	sub rdx, 8
	jmp .L_tc_recycle_frame_loop_056c
.L_tc_recycle_frame_done_056c:
	lea rsp, [rbx + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_opt_end_008c:	; new closure is in rax
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_041e:	; new closure is in rax
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; old return address
	push qword [rbp]	; old frame-pointer
	mov rcx, 5
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8]
.L_tc_recycle_frame_loop_056d:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_056d
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8
	sub rdx, 8
	jmp .L_tc_recycle_frame_loop_056d
.L_tc_recycle_frame_done_056d:
	lea rsp, [rbx + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_041d:	; new closure is in rax
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; old return address
	push qword [rbp]	; old frame-pointer
	mov rcx, 5
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8]
.L_tc_recycle_frame_loop_056e:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_056e
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8
	sub rdx, 8
	jmp .L_tc_recycle_frame_loop_056e
.L_tc_recycle_frame_done_056e:
	lea rsp, [rbx + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0419:	; new closure is in rax
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; old return address
	push qword [rbp]	; old frame-pointer
	mov rcx, 5
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8]
.L_tc_recycle_frame_loop_056f:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_056f
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8
	sub rdx, 8
	jmp .L_tc_recycle_frame_loop_056f
.L_tc_recycle_frame_done_056f:
	lea rsp, [rbx + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0418:	; new closure is in rax
	push rax
	push 1	; arg count
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 0	; new rib
	call malloc
	push rax
	mov rdi, 8 * 1	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_0420:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_0420
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0420
.L_lambda_simple_env_end_0420:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0420:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_0420
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0420
.L_lambda_simple_params_end_0420:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0420
	jmp .L_lambda_simple_end_0420
.L_lambda_simple_code_0420:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0420
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0420:
	enter 0, 0
	; preparing a non-tail-call
	mov rax, qword [free_var_80]	; free var char=?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	push rax
	push 1	; arg count
	mov rax, PARAM(0)	; param make-string=?
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	mov qword [free_var_162], rax	; free var string=?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	mov rax, sob_void

	; preparing a non-tail-call
	mov rax, qword [free_var_73]	; free var char-ci=?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	push rax
	push 1	; arg count
	mov rax, PARAM(0)	; param make-string=?
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	mov qword [free_var_150], rax	; free var string-ci=?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	mov rax, sob_void
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0420:	; new closure is in rax
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)

	mov rdi, rax
	call print_sexpr_if_not_void

	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 0	; new rib
	call malloc
	push rax
	mov rdi, 8 * 1	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_0421:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_0421
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0421
.L_lambda_simple_env_end_0421:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0421:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_0421
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0421
.L_lambda_simple_params_end_0421:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0421
	jmp .L_lambda_simple_end_0421
.L_lambda_simple_code_0421:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0421
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0421:
	enter 0, 0
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param e
	push rax
	push 1	; arg count
	mov rax, qword [free_var_126]	; free var null?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	jne .L_or_end_0054
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param e
	push rax
	push 1	; arg count
	mov rax, qword [free_var_131]	; free var pair?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_030a
	; preparing a tail-call
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param e
	push rax
	push 1	; arg count
	mov rax, qword [free_var_69]	; free var cdr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 1	; arg count
	mov rax, qword [free_var_110]	; free var list?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; old return address
	push qword [rbp]	; old frame-pointer
	mov rcx, 5
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8]
.L_tc_recycle_frame_loop_0570:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0570
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8
	sub rdx, 8
	jmp .L_tc_recycle_frame_loop_0570
.L_tc_recycle_frame_done_0570:
	lea rsp, [rbx + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_030a
.L_if_else_030a:
	mov rax, L_constants + 2
.L_if_end_030a:
.L_or_end_0054:
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0421:	; new closure is in rax
	mov qword [free_var_110], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void

	; preparing a non-tail-call
	mov rax, qword [free_var_120]	; free var make-vector
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	push rax
	push 1	; arg count
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 0	; new rib
	call malloc
	push rax
	mov rdi, 8 * 1	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_0422:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_0422
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0422
.L_lambda_simple_env_end_0422:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0422:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_0422
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0422
.L_lambda_simple_params_end_0422:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0422
	jmp .L_lambda_simple_end_0422
.L_lambda_simple_code_0422:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0422
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0422:
	enter 0, 0
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 1	; new rib
	call malloc
	push rax
	mov rdi, 8 * 2	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_opt_env_loop_008d:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
	je .L_lambda_opt_env_end_008d
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_opt_env_loop_008d
.L_lambda_opt_env_end_008d:
	pop rbx
	mov rsi, 0
.L_lambda_opt_params_loop_008d:	; copy params
	cmp rsi, 1
	je .L_lambda_opt_params_end_008d
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_opt_params_loop_008d
.L_lambda_opt_params_end_008d:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_opt_code_008d
	jmp .L_lambda_opt_end_008d
.L_lambda_opt_code_008d:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1 ;	 check num of args
	je .L_lambda_opt_arity_check_exact_008d ;	 if equal, go to exact arity
	jg .L_lambda_opt_arity_check_more_008d ;	 if greater than, go to arity more
	push qword [rsp + 8 * 2] ;	 else, throw opt arity error
	push 1
	jmp L_error_incorrect_arity_opt
.L_lambda_opt_arity_check_exact_008d:
	mov rax, qword [rsp + 8 * 2] ;	 number of args
	lea rbx, [rsp + 8 * (2 + rax)] ;	 address of last element
	sub rsp, 8
	lea rcx, [rsp + 0] ;	 new start
.L_lambda_opt_shift_entry_008d:
	mov rdx, [rcx + 8]
	mov [rcx], rdx
	add rcx, 8
	cmp rbx, rcx
	jne .L_lambda_opt_shift_entry_008d
.L_lambda_opt_shift_exit_008d:
	mov qword[rbx], sob_nil ;	 place nil
	add rax, 1
	mov qword [rsp + 8 * 2], rax
	jmp .L_lambda_opt_stack_adjusted_008d
.L_lambda_opt_arity_check_more_008d:
	mov rdx, sob_nil ;	 base cdr
	cmp qword [rsp + 8 * 2], 2
	je .L_lambda_opt_stack_shrink_loop_exit_008d
.L_lambda_opt_stack_shrink_loop_008d:
	mov rdi, (1 + 8 + 8)
	call malloc
	mov byte[rax], T_pair
	mov SOB_PAIR_CDR(rax), rdx
	mov rdx, rax
	mov rax, qword [rsp + 8 * 2]
	mov rbx, qword [rsp + 8 * (2 + rax)]
	mov SOB_PAIR_CAR(rdx), rbx
	lea rbx, [rsp + 8 * (2 + rax - 1)]
.L_lambda_opt_extra_shift_process_008d:
	mov rcx, [rbx]
	mov [rbx + 8], rcx
	sub rbx, 8
	cmp rsp, rbx
	jle .L_lambda_opt_extra_shift_process_008d
.L_lambda_opt_extra_shift_process_end_008d:
	add rsp, 8
	mov rbx, [rsp + 8 * 2]
	sub rbx, 1
	mov [rsp + 8 * 2], rbx
	cmp qword [rsp + 8 * 2], 2
	jg .L_lambda_opt_stack_shrink_loop_008d
.L_lambda_opt_stack_shrink_loop_exit_008d:
	mov rcx, [rsp + 8 * 2]
	mov rbx, qword [rsp + 8 * (2 + rcx)]
	mov rdi, (1 + 8 + 8)
	call malloc
	mov byte[rax], T_pair
	mov SOB_PAIR_CDR(rax), rdx
	mov SOB_PAIR_CAR(rax), rbx
	mov [rsp + 8 * (2 + rcx)], rax
.L_lambda_opt_stack_adjusted_008d:
	enter 0, 0
	; preparing a tail-call
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param xs
	push rax
	push 1	; arg count
	mov rax, qword [free_var_126]	; free var null?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_030d
	mov rax, L_constants + 0
	jmp .L_if_end_030d
.L_if_else_030d:
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param xs
	push rax
	push 1	; arg count
	mov rax, qword [free_var_131]	; free var pair?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_030b
	; preparing a non-tail-call
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param xs
	push rax
	push 1	; arg count
	mov rax, qword [free_var_69]	; free var cdr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 1	; arg count
	mov rax, qword [free_var_126]	; free var null?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_030b
.L_if_else_030b:
	mov rax, L_constants + 2
.L_if_end_030b:
	cmp rax, sob_boolean_false
	je .L_if_else_030c
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param xs
	push rax
	push 1	; arg count
	mov rax, qword [free_var_54]	; free var car
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_030c
.L_if_else_030c:
	; preparing a non-tail-call
	mov rax, L_constants + 3936
	push rax
	mov rax, L_constants + 3927
	push rax
	push 2	; arg count
	mov rax, qword [free_var_90]	; free var error
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
.L_if_end_030c:
.L_if_end_030d:
	push rax
	push 1	; arg count
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 2	; new rib
	call malloc
	push rax
	mov rdi, 8 * 3	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_0423:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 2
	je .L_lambda_simple_env_end_0423
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0423
.L_lambda_simple_env_end_0423:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0423:	; copy params
	cmp rsi, 2
	je .L_lambda_simple_params_end_0423
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0423
.L_lambda_simple_params_end_0423:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0423
	jmp .L_lambda_simple_end_0423
.L_lambda_simple_code_0423:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0423
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0423:
	enter 0, 0
	; preparing a tail-call
	mov rax, PARAM(0)	; param x
	push rax
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var n
	push rax
	push 2	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 1]
	mov rax, qword [rax + 8 * 0]	; bound var asm-make-vector
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; old return address
	push qword [rbp]	; old frame-pointer
	mov rcx, 6
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8]
.L_tc_recycle_frame_loop_0571:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0571
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8
	sub rdx, 8
	jmp .L_tc_recycle_frame_loop_0571
.L_tc_recycle_frame_done_0571:
	lea rsp, [rbx + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0423:	; new closure is in rax
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; old return address
	push qword [rbp]	; old frame-pointer
	mov rcx, 5
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8]
.L_tc_recycle_frame_loop_0572:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0572
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8
	sub rdx, 8
	jmp .L_tc_recycle_frame_loop_0572
.L_tc_recycle_frame_done_0572:
	lea rsp, [rbx + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_opt_end_008d:	; new closure is in rax
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0422:	; new closure is in rax
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	mov qword [free_var_120], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void

	; preparing a non-tail-call
	mov rax, qword [free_var_118]	; free var make-string
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	push rax
	push 1	; arg count
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 0	; new rib
	call malloc
	push rax
	mov rdi, 8 * 1	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_0424:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_0424
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0424
.L_lambda_simple_env_end_0424:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0424:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_0424
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0424
.L_lambda_simple_params_end_0424:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0424
	jmp .L_lambda_simple_end_0424
.L_lambda_simple_code_0424:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0424
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0424:
	enter 0, 0
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 1	; new rib
	call malloc
	push rax
	mov rdi, 8 * 2	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_opt_env_loop_008e:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
	je .L_lambda_opt_env_end_008e
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_opt_env_loop_008e
.L_lambda_opt_env_end_008e:
	pop rbx
	mov rsi, 0
.L_lambda_opt_params_loop_008e:	; copy params
	cmp rsi, 1
	je .L_lambda_opt_params_end_008e
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_opt_params_loop_008e
.L_lambda_opt_params_end_008e:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_opt_code_008e
	jmp .L_lambda_opt_end_008e
.L_lambda_opt_code_008e:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1 ;	 check num of args
	je .L_lambda_opt_arity_check_exact_008e ;	 if equal, go to exact arity
	jg .L_lambda_opt_arity_check_more_008e ;	 if greater than, go to arity more
	push qword [rsp + 8 * 2] ;	 else, throw opt arity error
	push 1
	jmp L_error_incorrect_arity_opt
.L_lambda_opt_arity_check_exact_008e:
	mov rax, qword [rsp + 8 * 2] ;	 number of args
	lea rbx, [rsp + 8 * (2 + rax)] ;	 address of last element
	sub rsp, 8
	lea rcx, [rsp + 0] ;	 new start
.L_lambda_opt_shift_entry_008e:
	mov rdx, [rcx + 8]
	mov [rcx], rdx
	add rcx, 8
	cmp rbx, rcx
	jne .L_lambda_opt_shift_entry_008e
.L_lambda_opt_shift_exit_008e:
	mov qword[rbx], sob_nil ;	 place nil
	add rax, 1
	mov qword [rsp + 8 * 2], rax
	jmp .L_lambda_opt_stack_adjusted_008e
.L_lambda_opt_arity_check_more_008e:
	mov rdx, sob_nil ;	 base cdr
	cmp qword [rsp + 8 * 2], 2
	je .L_lambda_opt_stack_shrink_loop_exit_008e
.L_lambda_opt_stack_shrink_loop_008e:
	mov rdi, (1 + 8 + 8)
	call malloc
	mov byte[rax], T_pair
	mov SOB_PAIR_CDR(rax), rdx
	mov rdx, rax
	mov rax, qword [rsp + 8 * 2]
	mov rbx, qword [rsp + 8 * (2 + rax)]
	mov SOB_PAIR_CAR(rdx), rbx
	lea rbx, [rsp + 8 * (2 + rax - 1)]
.L_lambda_opt_extra_shift_process_008e:
	mov rcx, [rbx]
	mov [rbx + 8], rcx
	sub rbx, 8
	cmp rsp, rbx
	jle .L_lambda_opt_extra_shift_process_008e
.L_lambda_opt_extra_shift_process_end_008e:
	add rsp, 8
	mov rbx, [rsp + 8 * 2]
	sub rbx, 1
	mov [rsp + 8 * 2], rbx
	cmp qword [rsp + 8 * 2], 2
	jg .L_lambda_opt_stack_shrink_loop_008e
.L_lambda_opt_stack_shrink_loop_exit_008e:
	mov rcx, [rsp + 8 * 2]
	mov rbx, qword [rsp + 8 * (2 + rcx)]
	mov rdi, (1 + 8 + 8)
	call malloc
	mov byte[rax], T_pair
	mov SOB_PAIR_CDR(rax), rdx
	mov SOB_PAIR_CAR(rax), rbx
	mov [rsp + 8 * (2 + rcx)], rax
.L_lambda_opt_stack_adjusted_008e:
	enter 0, 0
	; preparing a tail-call
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param chs
	push rax
	push 1	; arg count
	mov rax, qword [free_var_126]	; free var null?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_0310
	mov rax, L_constants + 4
	jmp .L_if_end_0310
.L_if_else_0310:
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param chs
	push rax
	push 1	; arg count
	mov rax, qword [free_var_131]	; free var pair?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_030e
	; preparing a non-tail-call
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param chs
	push rax
	push 1	; arg count
	mov rax, qword [free_var_69]	; free var cdr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 1	; arg count
	mov rax, qword [free_var_126]	; free var null?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_030e
.L_if_else_030e:
	mov rax, L_constants + 2
.L_if_end_030e:
	cmp rax, sob_boolean_false
	je .L_if_else_030f
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param chs
	push rax
	push 1	; arg count
	mov rax, qword [free_var_54]	; free var car
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_030f
.L_if_else_030f:
	; preparing a non-tail-call
	mov rax, L_constants + 3997
	push rax
	mov rax, L_constants + 3988
	push rax
	push 2	; arg count
	mov rax, qword [free_var_90]	; free var error
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
.L_if_end_030f:
.L_if_end_0310:
	push rax
	push 1	; arg count
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 2	; new rib
	call malloc
	push rax
	mov rdi, 8 * 3	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_0425:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 2
	je .L_lambda_simple_env_end_0425
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0425
.L_lambda_simple_env_end_0425:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0425:	; copy params
	cmp rsi, 2
	je .L_lambda_simple_params_end_0425
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0425
.L_lambda_simple_params_end_0425:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0425
	jmp .L_lambda_simple_end_0425
.L_lambda_simple_code_0425:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0425
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0425:
	enter 0, 0
	; preparing a tail-call
	mov rax, PARAM(0)	; param ch
	push rax
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var n
	push rax
	push 2	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 1]
	mov rax, qword [rax + 8 * 0]	; bound var asm-make-string
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; old return address
	push qword [rbp]	; old frame-pointer
	mov rcx, 6
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8]
.L_tc_recycle_frame_loop_0573:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0573
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8
	sub rdx, 8
	jmp .L_tc_recycle_frame_loop_0573
.L_tc_recycle_frame_done_0573:
	lea rsp, [rbx + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0425:	; new closure is in rax
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; old return address
	push qword [rbp]	; old frame-pointer
	mov rcx, 5
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8]
.L_tc_recycle_frame_loop_0574:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0574
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8
	sub rdx, 8
	jmp .L_tc_recycle_frame_loop_0574
.L_tc_recycle_frame_done_0574:
	lea rsp, [rbx + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_opt_end_008e:	; new closure is in rax
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0424:	; new closure is in rax
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	mov qword [free_var_118], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void

	; preparing a non-tail-call
	mov rax, L_constants + 2335
	push rax
	push 1	; arg count
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 0	; new rib
	call malloc
	push rax
	mov rdi, 8 * 1	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_0426:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_0426
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0426
.L_lambda_simple_env_end_0426:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0426:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_0426
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0426
.L_lambda_simple_params_end_0426:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0426
	jmp .L_lambda_simple_end_0426
.L_lambda_simple_code_0426:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0426
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0426:
	enter 0, 0

	mov rdi, 8
	call malloc
	mov rbx, PARAM(0)	; param run
	mov [rax], rbx	; box run
	mov PARAM(0), rax	; replace param with box
	mov rax, sob_void

	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 1	; new rib
	call malloc
	push rax
	mov rdi, 8 * 2	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_0427:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
	je .L_lambda_simple_env_end_0427
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0427
.L_lambda_simple_env_end_0427:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0427:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_0427
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0427
.L_lambda_simple_params_end_0427:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0427
	jmp .L_lambda_simple_end_0427
.L_lambda_simple_code_0427:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 2
	je .L_lambda_simple_arity_check_ok_0427
	push qword [rsp + 8 * 2]
	push 2
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0427:
	enter 0, 0
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param s
	push rax
	push 1	; arg count
	mov rax, qword [free_var_126]	; free var null?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_0311
	; preparing a tail-call
	mov rax, L_constants + 0
	push rax
	mov rax, PARAM(1)	; param i
	push rax
	push 2	; arg count
	mov rax, qword [free_var_120]	; free var make-vector
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; old return address
	push qword [rbp]	; old frame-pointer
	mov rcx, 6
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8]
.L_tc_recycle_frame_loop_0575:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0575
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8
	sub rdx, 8
	jmp .L_tc_recycle_frame_loop_0575
.L_tc_recycle_frame_done_0575:
	lea rsp, [rbx + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_0311
.L_if_else_0311:
	; preparing a tail-call
	; preparing a non-tail-call
	; preparing a non-tail-call
	mov rax, L_constants + 2810
	push rax
	mov rax, PARAM(1)	; param i
	push rax
	push 2	; arg count
	mov rax, qword [free_var_1]	; free var +
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param s
	push rax
	push 1	; arg count
	mov rax, qword [free_var_69]	; free var cdr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 2	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var run
	mov rax, qword [rax]
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 1	; arg count
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 2	; new rib
	call malloc
	push rax
	mov rdi, 8 * 3	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_0428:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 2
	je .L_lambda_simple_env_end_0428
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0428
.L_lambda_simple_env_end_0428:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0428:	; copy params
	cmp rsi, 2
	je .L_lambda_simple_params_end_0428
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0428
.L_lambda_simple_params_end_0428:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0428
	jmp .L_lambda_simple_end_0428
.L_lambda_simple_code_0428:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0428
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0428:
	enter 0, 0
	; preparing a non-tail-call
	; preparing a non-tail-call
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var s
	push rax
	push 1	; arg count
	mov rax, qword [free_var_54]	; free var car
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 1]	; bound var i
	push rax
	mov rax, PARAM(0)	; param v
	push rax
	push 3	; arg count
	mov rax, qword [free_var_176]	; free var vector-set!
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)

	mov rax, PARAM(0)	; param v
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0428:	; new closure is in rax
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; old return address
	push qword [rbp]	; old frame-pointer
	mov rcx, 5
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8]
.L_tc_recycle_frame_loop_0576:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0576
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8
	sub rdx, 8
	jmp .L_tc_recycle_frame_loop_0576
.L_tc_recycle_frame_done_0576:
	lea rsp, [rbx + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
.L_if_end_0311:
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_simple_end_0427:	; new closure is in rax

	push rax
	mov rax, PARAM(0)	; param run

	pop qword[rax]
	mov rax, sob_void

	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 1	; new rib
	call malloc
	push rax
	mov rdi, 8 * 2	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_0429:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
	je .L_lambda_simple_env_end_0429
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0429
.L_lambda_simple_env_end_0429:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0429:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_0429
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0429
.L_lambda_simple_params_end_0429:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0429
	jmp .L_lambda_simple_end_0429
.L_lambda_simple_code_0429:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0429
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0429:
	enter 0, 0
	; preparing a tail-call
	mov rax, L_constants + 2558
	push rax
	mov rax, PARAM(0)	; param s
	push rax
	push 2	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var run
	mov rax, qword [rax]
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; old return address
	push qword [rbp]	; old frame-pointer
	mov rcx, 6
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8]
.L_tc_recycle_frame_loop_0577:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0577
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8
	sub rdx, 8
	jmp .L_tc_recycle_frame_loop_0577
.L_tc_recycle_frame_done_0577:
	lea rsp, [rbx + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0429:	; new closure is in rax
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0426:	; new closure is in rax
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	mov qword [free_var_109], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void

	; preparing a non-tail-call
	mov rax, L_constants + 2335
	push rax
	push 1	; arg count
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 0	; new rib
	call malloc
	push rax
	mov rdi, 8 * 1	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_042a:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_042a
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_042a
.L_lambda_simple_env_end_042a:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_042a:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_042a
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_042a
.L_lambda_simple_params_end_042a:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_042a
	jmp .L_lambda_simple_end_042a
.L_lambda_simple_code_042a:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_042a
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_042a:
	enter 0, 0

	mov rdi, 8
	call malloc
	mov rbx, PARAM(0)	; param run
	mov [rax], rbx	; box run
	mov PARAM(0), rax	; replace param with box
	mov rax, sob_void

	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 1	; new rib
	call malloc
	push rax
	mov rdi, 8 * 2	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_042b:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
	je .L_lambda_simple_env_end_042b
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_042b
.L_lambda_simple_env_end_042b:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_042b:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_042b
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_042b
.L_lambda_simple_params_end_042b:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_042b
	jmp .L_lambda_simple_end_042b
.L_lambda_simple_code_042b:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 2
	je .L_lambda_simple_arity_check_ok_042b
	push qword [rsp + 8 * 2]
	push 2
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_042b:
	enter 0, 0
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param s
	push rax
	push 1	; arg count
	mov rax, qword [free_var_126]	; free var null?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_0312
	; preparing a tail-call
	mov rax, L_constants + 4
	push rax
	mov rax, PARAM(1)	; param i
	push rax
	push 2	; arg count
	mov rax, qword [free_var_118]	; free var make-string
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; old return address
	push qword [rbp]	; old frame-pointer
	mov rcx, 6
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8]
.L_tc_recycle_frame_loop_0578:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0578
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8
	sub rdx, 8
	jmp .L_tc_recycle_frame_loop_0578
.L_tc_recycle_frame_done_0578:
	lea rsp, [rbx + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_0312
.L_if_else_0312:
	; preparing a tail-call
	; preparing a non-tail-call
	; preparing a non-tail-call
	mov rax, L_constants + 2810
	push rax
	mov rax, PARAM(1)	; param i
	push rax
	push 2	; arg count
	mov rax, qword [free_var_1]	; free var +
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param s
	push rax
	push 1	; arg count
	mov rax, qword [free_var_69]	; free var cdr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 2	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var run
	mov rax, qword [rax]
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 1	; arg count
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 2	; new rib
	call malloc
	push rax
	mov rdi, 8 * 3	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_042c:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 2
	je .L_lambda_simple_env_end_042c
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_042c
.L_lambda_simple_env_end_042c:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_042c:	; copy params
	cmp rsi, 2
	je .L_lambda_simple_params_end_042c
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_042c
.L_lambda_simple_params_end_042c:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_042c
	jmp .L_lambda_simple_end_042c
.L_lambda_simple_code_042c:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_042c
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_042c:
	enter 0, 0
	; preparing a non-tail-call
	; preparing a non-tail-call
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var s
	push rax
	push 1	; arg count
	mov rax, qword [free_var_54]	; free var car
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 1]	; bound var i
	push rax
	mov rax, PARAM(0)	; param str
	push rax
	push 3	; arg count
	mov rax, qword [free_var_158]	; free var string-set!
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)

	mov rax, PARAM(0)	; param str
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_042c:	; new closure is in rax
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; old return address
	push qword [rbp]	; old frame-pointer
	mov rcx, 5
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8]
.L_tc_recycle_frame_loop_0579:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0579
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8
	sub rdx, 8
	jmp .L_tc_recycle_frame_loop_0579
.L_tc_recycle_frame_done_0579:
	lea rsp, [rbx + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
.L_if_end_0312:
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_simple_end_042b:	; new closure is in rax

	push rax
	mov rax, PARAM(0)	; param run

	pop qword[rax]
	mov rax, sob_void

	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 1	; new rib
	call malloc
	push rax
	mov rdi, 8 * 2	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_042d:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
	je .L_lambda_simple_env_end_042d
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_042d
.L_lambda_simple_env_end_042d:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_042d:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_042d
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_042d
.L_lambda_simple_params_end_042d:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_042d
	jmp .L_lambda_simple_end_042d
.L_lambda_simple_code_042d:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_042d
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_042d:
	enter 0, 0
	; preparing a tail-call
	mov rax, L_constants + 2558
	push rax
	mov rax, PARAM(0)	; param s
	push rax
	push 2	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var run
	mov rax, qword [rax]
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; old return address
	push qword [rbp]	; old frame-pointer
	mov rcx, 6
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8]
.L_tc_recycle_frame_loop_057a:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_057a
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8
	sub rdx, 8
	jmp .L_tc_recycle_frame_loop_057a
.L_tc_recycle_frame_done_057a:
	lea rsp, [rbx + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_042d:	; new closure is in rax
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_042a:	; new closure is in rax
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	mov qword [free_var_108], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void

	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 0	; new rib
	call malloc
	push rax
	mov rdi, 8 * 1	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_opt_env_loop_008f:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_opt_env_end_008f
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_opt_env_loop_008f
.L_lambda_opt_env_end_008f:
	pop rbx
	mov rsi, 0
.L_lambda_opt_params_loop_008f:	; copy params
	cmp rsi, 0
	je .L_lambda_opt_params_end_008f
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_opt_params_loop_008f
.L_lambda_opt_params_end_008f:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_opt_code_008f
	jmp .L_lambda_opt_end_008f
.L_lambda_opt_code_008f:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 0 ;	 check num of args
	je .L_lambda_opt_arity_check_exact_008f ;	 if equal, go to exact arity
	jg .L_lambda_opt_arity_check_more_008f ;	 if greater than, go to arity more
	push qword [rsp + 8 * 2] ;	 else, throw opt arity error
	push 0
	jmp L_error_incorrect_arity_opt
.L_lambda_opt_arity_check_exact_008f:
	mov rax, qword [rsp + 8 * 2] ;	 number of args
	lea rbx, [rsp + 8 * (2 + rax)] ;	 address of last element
	sub rsp, 8
	lea rcx, [rsp + 0] ;	 new start
.L_lambda_opt_shift_entry_008f:
	mov rdx, [rcx + 8]
	mov [rcx], rdx
	add rcx, 8
	cmp rbx, rcx
	jne .L_lambda_opt_shift_entry_008f
.L_lambda_opt_shift_exit_008f:
	mov qword[rbx], sob_nil ;	 place nil
	add rax, 1
	mov qword [rsp + 8 * 2], rax
	jmp .L_lambda_opt_stack_adjusted_008f
.L_lambda_opt_arity_check_more_008f:
	mov rdx, sob_nil ;	 base cdr
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_opt_stack_shrink_loop_exit_008f
.L_lambda_opt_stack_shrink_loop_008f:
	mov rdi, (1 + 8 + 8)
	call malloc
	mov byte[rax], T_pair
	mov SOB_PAIR_CDR(rax), rdx
	mov rdx, rax
	mov rax, qword [rsp + 8 * 2]
	mov rbx, qword [rsp + 8 * (2 + rax)]
	mov SOB_PAIR_CAR(rdx), rbx
	lea rbx, [rsp + 8 * (2 + rax - 1)]
.L_lambda_opt_extra_shift_process_008f:
	mov rcx, [rbx]
	mov [rbx + 8], rcx
	sub rbx, 8
	cmp rsp, rbx
	jle .L_lambda_opt_extra_shift_process_008f
.L_lambda_opt_extra_shift_process_end_008f:
	add rsp, 8
	mov rbx, [rsp + 8 * 2]
	sub rbx, 1
	mov [rsp + 8 * 2], rbx
	cmp qword [rsp + 8 * 2], 1
	jg .L_lambda_opt_stack_shrink_loop_008f
.L_lambda_opt_stack_shrink_loop_exit_008f:
	mov rcx, [rsp + 8 * 2]
	mov rbx, qword [rsp + 8 * (2 + rcx)]
	mov rdi, (1 + 8 + 8)
	call malloc
	mov byte[rax], T_pair
	mov SOB_PAIR_CDR(rax), rdx
	mov SOB_PAIR_CAR(rax), rbx
	mov [rsp + 8 * (2 + rcx)], rax
.L_lambda_opt_stack_adjusted_008f:
	enter 0, 0
	; preparing a tail-call
	mov rax, PARAM(0)	; param s
	push rax
	push 1	; arg count
	mov rax, qword [free_var_109]	; free var list->vector
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; old return address
	push qword [rbp]	; old frame-pointer
	mov rcx, 5
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8]
.L_tc_recycle_frame_loop_057b:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_057b
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8
	sub rdx, 8
	jmp .L_tc_recycle_frame_loop_057b
.L_tc_recycle_frame_done_057b:
	lea rsp, [rbx + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_opt_end_008f:	; new closure is in rax
	mov qword [free_var_169], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void

	; preparing a non-tail-call
	mov rax, L_constants + 2335
	push rax
	push 1	; arg count
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 0	; new rib
	call malloc
	push rax
	mov rdi, 8 * 1	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_042e:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_042e
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_042e
.L_lambda_simple_env_end_042e:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_042e:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_042e
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_042e
.L_lambda_simple_params_end_042e:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_042e
	jmp .L_lambda_simple_end_042e
.L_lambda_simple_code_042e:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_042e
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_042e:
	enter 0, 0

	mov rdi, 8
	call malloc
	mov rbx, PARAM(0)	; param run
	mov [rax], rbx	; box run
	mov PARAM(0), rax	; replace param with box
	mov rax, sob_void

	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 1	; new rib
	call malloc
	push rax
	mov rdi, 8 * 2	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_042f:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
	je .L_lambda_simple_env_end_042f
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_042f
.L_lambda_simple_env_end_042f:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_042f:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_042f
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_042f
.L_lambda_simple_params_end_042f:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_042f
	jmp .L_lambda_simple_end_042f
.L_lambda_simple_code_042f:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 3
	je .L_lambda_simple_arity_check_ok_042f
	push qword [rsp + 8 * 2]
	push 3
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_042f:
	enter 0, 0
	; preparing a non-tail-call
	mov rax, PARAM(2)	; param n
	push rax
	mov rax, PARAM(1)	; param i
	push rax
	push 2	; arg count
	mov rax, qword [free_var_4]	; free var <
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_0313
	; preparing a tail-call
	; preparing a non-tail-call
	mov rax, PARAM(2)	; param n
	push rax
	; preparing a non-tail-call
	mov rax, L_constants + 2810
	push rax
	mov rax, PARAM(1)	; param i
	push rax
	push 2	; arg count
	mov rax, qword [free_var_1]	; free var +
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	mov rax, PARAM(0)	; param str
	push rax
	push 3	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var run
	mov rax, qword [rax]
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param i
	push rax
	mov rax, PARAM(0)	; param str
	push rax
	push 2	; arg count
	mov rax, qword [free_var_155]	; free var string-ref
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 2	; arg count
	mov rax, qword [free_var_85]	; free var cons
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; old return address
	push qword [rbp]	; old frame-pointer
	mov rcx, 6
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8]
.L_tc_recycle_frame_loop_057c:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_057c
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8
	sub rdx, 8
	jmp .L_tc_recycle_frame_loop_057c
.L_tc_recycle_frame_done_057c:
	lea rsp, [rbx + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_0313
.L_if_else_0313:
	mov rax, L_constants + 1
.L_if_end_0313:
	leave
	ret AND_KILL_FRAME(3)
.L_lambda_simple_end_042f:	; new closure is in rax

	push rax
	mov rax, PARAM(0)	; param run

	pop qword[rax]
	mov rax, sob_void

	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 1	; new rib
	call malloc
	push rax
	mov rdi, 8 * 2	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_0430:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
	je .L_lambda_simple_env_end_0430
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0430
.L_lambda_simple_env_end_0430:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0430:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_0430
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0430
.L_lambda_simple_params_end_0430:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0430
	jmp .L_lambda_simple_end_0430
.L_lambda_simple_code_0430:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0430
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0430:
	enter 0, 0
	; preparing a tail-call
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param str
	push rax
	push 1	; arg count
	mov rax, qword [free_var_154]	; free var string-length
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	mov rax, L_constants + 2558
	push rax
	mov rax, PARAM(0)	; param str
	push rax
	push 3	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var run
	mov rax, qword [rax]
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; old return address
	push qword [rbp]	; old frame-pointer
	mov rcx, 7
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8]
.L_tc_recycle_frame_loop_057d:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_057d
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8
	sub rdx, 8
	jmp .L_tc_recycle_frame_loop_057d
.L_tc_recycle_frame_done_057d:
	lea rsp, [rbx + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0430:	; new closure is in rax
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_042e:	; new closure is in rax
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	mov qword [free_var_146], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void

	; preparing a non-tail-call
	mov rax, L_constants + 2335
	push rax
	push 1	; arg count
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 0	; new rib
	call malloc
	push rax
	mov rdi, 8 * 1	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_0431:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_0431
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0431
.L_lambda_simple_env_end_0431:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0431:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_0431
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0431
.L_lambda_simple_params_end_0431:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0431
	jmp .L_lambda_simple_end_0431
.L_lambda_simple_code_0431:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0431
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0431:
	enter 0, 0

	mov rdi, 8
	call malloc
	mov rbx, PARAM(0)	; param run
	mov [rax], rbx	; box run
	mov PARAM(0), rax	; replace param with box
	mov rax, sob_void

	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 1	; new rib
	call malloc
	push rax
	mov rdi, 8 * 2	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_0432:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
	je .L_lambda_simple_env_end_0432
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0432
.L_lambda_simple_env_end_0432:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0432:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_0432
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0432
.L_lambda_simple_params_end_0432:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0432
	jmp .L_lambda_simple_end_0432
.L_lambda_simple_code_0432:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 3
	je .L_lambda_simple_arity_check_ok_0432
	push qword [rsp + 8 * 2]
	push 3
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0432:
	enter 0, 0
	; preparing a non-tail-call
	mov rax, PARAM(2)	; param n
	push rax
	mov rax, PARAM(1)	; param i
	push rax
	push 2	; arg count
	mov rax, qword [free_var_4]	; free var <
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_0314
	; preparing a tail-call
	; preparing a non-tail-call
	mov rax, PARAM(2)	; param n
	push rax
	; preparing a non-tail-call
	mov rax, L_constants + 2810
	push rax
	mov rax, PARAM(1)	; param i
	push rax
	push 2	; arg count
	mov rax, qword [free_var_1]	; free var +
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	mov rax, PARAM(0)	; param v
	push rax
	push 3	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var run
	mov rax, qword [rax]
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param i
	push rax
	mov rax, PARAM(0)	; param v
	push rax
	push 2	; arg count
	mov rax, qword [free_var_173]	; free var vector-ref
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 2	; arg count
	mov rax, qword [free_var_85]	; free var cons
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; old return address
	push qword [rbp]	; old frame-pointer
	mov rcx, 6
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8]
.L_tc_recycle_frame_loop_057e:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_057e
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8
	sub rdx, 8
	jmp .L_tc_recycle_frame_loop_057e
.L_tc_recycle_frame_done_057e:
	lea rsp, [rbx + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_0314
.L_if_else_0314:
	mov rax, L_constants + 1
.L_if_end_0314:
	leave
	ret AND_KILL_FRAME(3)
.L_lambda_simple_end_0432:	; new closure is in rax

	push rax
	mov rax, PARAM(0)	; param run

	pop qword[rax]
	mov rax, sob_void

	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 1	; new rib
	call malloc
	push rax
	mov rdi, 8 * 2	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_0433:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
	je .L_lambda_simple_env_end_0433
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0433
.L_lambda_simple_env_end_0433:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0433:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_0433
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0433
.L_lambda_simple_params_end_0433:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0433
	jmp .L_lambda_simple_end_0433
.L_lambda_simple_code_0433:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0433
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0433:
	enter 0, 0
	; preparing a tail-call
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param v
	push rax
	push 1	; arg count
	mov rax, qword [free_var_172]	; free var vector-length
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	mov rax, L_constants + 2558
	push rax
	mov rax, PARAM(0)	; param v
	push rax
	push 3	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var run
	mov rax, qword [rax]
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; old return address
	push qword [rbp]	; old frame-pointer
	mov rcx, 7
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8]
.L_tc_recycle_frame_loop_057f:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_057f
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8
	sub rdx, 8
	jmp .L_tc_recycle_frame_loop_057f
.L_tc_recycle_frame_done_057f:
	lea rsp, [rbx + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0433:	; new closure is in rax
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0431:	; new closure is in rax
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	mov qword [free_var_170], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void

	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 0	; new rib
	call malloc
	push rax
	mov rdi, 8 * 1	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_0434:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_0434
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0434
.L_lambda_simple_env_end_0434:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0434:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_0434
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0434
.L_lambda_simple_params_end_0434:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0434
	jmp .L_lambda_simple_end_0434
.L_lambda_simple_code_0434:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0434
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0434:
	enter 0, 0
	; preparing a tail-call
	mov rax, PARAM(0)	; param n
	push rax
	; preparing a non-tail-call
	push 0	; arg count
	mov rax, qword [free_var_167]	; free var trng
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 2	; arg count
	mov rax, qword [free_var_141]	; free var remainder
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; old return address
	push qword [rbp]	; old frame-pointer
	mov rcx, 6
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8]
.L_tc_recycle_frame_loop_0580:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0580
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8
	sub rdx, 8
	jmp .L_tc_recycle_frame_loop_0580
.L_tc_recycle_frame_done_0580:
	lea rsp, [rbx + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0434:	; new closure is in rax
	mov qword [free_var_136], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void

	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 0	; new rib
	call malloc
	push rax
	mov rdi, 8 * 1	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_0435:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_0435
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0435
.L_lambda_simple_env_end_0435:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0435:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_0435
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0435
.L_lambda_simple_params_end_0435:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0435
	jmp .L_lambda_simple_end_0435
.L_lambda_simple_code_0435:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0435
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0435:
	enter 0, 0
	; preparing a tail-call
	mov rax, PARAM(0)	; param x
	push rax
	mov rax, L_constants + 2558
	push rax
	push 2	; arg count
	mov rax, qword [free_var_4]	; free var <
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; old return address
	push qword [rbp]	; old frame-pointer
	mov rcx, 6
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8]
.L_tc_recycle_frame_loop_0581:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0581
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8
	sub rdx, 8
	jmp .L_tc_recycle_frame_loop_0581
.L_tc_recycle_frame_done_0581:
	lea rsp, [rbx + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0435:	; new closure is in rax
	mov qword [free_var_132], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void

	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 0	; new rib
	call malloc
	push rax
	mov rdi, 8 * 1	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_0436:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_0436
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0436
.L_lambda_simple_env_end_0436:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0436:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_0436
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0436
.L_lambda_simple_params_end_0436:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0436
	jmp .L_lambda_simple_end_0436
.L_lambda_simple_code_0436:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0436
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0436:
	enter 0, 0
	; preparing a tail-call
	mov rax, L_constants + 2558
	push rax
	mov rax, PARAM(0)	; param x
	push rax
	push 2	; arg count
	mov rax, qword [free_var_4]	; free var <
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; old return address
	push qword [rbp]	; old frame-pointer
	mov rcx, 6
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8]
.L_tc_recycle_frame_loop_0582:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0582
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8
	sub rdx, 8
	jmp .L_tc_recycle_frame_loop_0582
.L_tc_recycle_frame_done_0582:
	lea rsp, [rbx + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0436:	; new closure is in rax
	mov qword [free_var_123], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void

	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 0	; new rib
	call malloc
	push rax
	mov rdi, 8 * 1	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_0437:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_0437
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0437
.L_lambda_simple_env_end_0437:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0437:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_0437
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0437
.L_lambda_simple_params_end_0437:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0437
	jmp .L_lambda_simple_end_0437
.L_lambda_simple_code_0437:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0437
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0437:
	enter 0, 0
	; preparing a tail-call
	; preparing a non-tail-call
	mov rax, L_constants + 4288
	push rax
	mov rax, PARAM(0)	; param n
	push rax
	push 2	; arg count
	mov rax, qword [free_var_141]	; free var remainder
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 1	; arg count
	mov rax, qword [free_var_181]	; free var zero?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; old return address
	push qword [rbp]	; old frame-pointer
	mov rcx, 5
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8]
.L_tc_recycle_frame_loop_0583:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0583
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8
	sub rdx, 8
	jmp .L_tc_recycle_frame_loop_0583
.L_tc_recycle_frame_done_0583:
	lea rsp, [rbx + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0437:	; new closure is in rax
	mov qword [free_var_91], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void

	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 0	; new rib
	call malloc
	push rax
	mov rdi, 8 * 1	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_0438:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_0438
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0438
.L_lambda_simple_env_end_0438:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0438:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_0438
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0438
.L_lambda_simple_params_end_0438:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0438
	jmp .L_lambda_simple_end_0438
.L_lambda_simple_code_0438:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0438
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0438:
	enter 0, 0
	; preparing a tail-call
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param n
	push rax
	push 1	; arg count
	mov rax, qword [free_var_91]	; free var even?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 1	; arg count
	mov rax, qword [free_var_125]	; free var not
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; old return address
	push qword [rbp]	; old frame-pointer
	mov rcx, 5
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8]
.L_tc_recycle_frame_loop_0584:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0584
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8
	sub rdx, 8
	jmp .L_tc_recycle_frame_loop_0584
.L_tc_recycle_frame_done_0584:
	lea rsp, [rbx + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0438:	; new closure is in rax
	mov qword [free_var_129], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void

	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 0	; new rib
	call malloc
	push rax
	mov rdi, 8 * 1	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_0439:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_0439
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0439
.L_lambda_simple_env_end_0439:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0439:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_0439
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0439
.L_lambda_simple_params_end_0439:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0439
	jmp .L_lambda_simple_end_0439
.L_lambda_simple_code_0439:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0439
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0439:
	enter 0, 0
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param x
	push rax
	push 1	; arg count
	mov rax, qword [free_var_123]	; free var negative?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_0315
	; preparing a tail-call
	mov rax, PARAM(0)	; param x
	push rax
	push 1	; arg count
	mov rax, qword [free_var_2]	; free var -
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; old return address
	push qword [rbp]	; old frame-pointer
	mov rcx, 5
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8]
.L_tc_recycle_frame_loop_0585:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0585
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8
	sub rdx, 8
	jmp .L_tc_recycle_frame_loop_0585
.L_tc_recycle_frame_done_0585:
	lea rsp, [rbx + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_0315
.L_if_else_0315:
	mov rax, PARAM(0)	; param x
.L_if_end_0315:
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0439:	; new closure is in rax
	mov qword [free_var_30], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void

	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 0	; new rib
	call malloc
	push rax
	mov rdi, 8 * 1	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_043a:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_043a
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_043a
.L_lambda_simple_env_end_043a:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_043a:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_043a
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_043a
.L_lambda_simple_params_end_043a:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_043a
	jmp .L_lambda_simple_end_043a
.L_lambda_simple_code_043a:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 2
	je .L_lambda_simple_arity_check_ok_043a
	push qword [rsp + 8 * 2]
	push 2
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_043a:
	enter 0, 0
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param e1
	push rax
	push 1	; arg count
	mov rax, qword [free_var_131]	; free var pair?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_0316
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param e2
	push rax
	push 1	; arg count
	mov rax, qword [free_var_131]	; free var pair?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_0316
.L_if_else_0316:
	mov rax, L_constants + 2
.L_if_end_0316:
	cmp rax, sob_boolean_false
	je .L_if_else_0322
	; preparing a non-tail-call
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param e2
	push rax
	push 1	; arg count
	mov rax, qword [free_var_54]	; free var car
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param e1
	push rax
	push 1	; arg count
	mov rax, qword [free_var_54]	; free var car
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 2	; arg count
	mov rax, qword [free_var_89]	; free var equal?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_0317
	; preparing a tail-call
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param e2
	push rax
	push 1	; arg count
	mov rax, qword [free_var_69]	; free var cdr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param e1
	push rax
	push 1	; arg count
	mov rax, qword [free_var_69]	; free var cdr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 2	; arg count
	mov rax, qword [free_var_89]	; free var equal?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; old return address
	push qword [rbp]	; old frame-pointer
	mov rcx, 6
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8]
.L_tc_recycle_frame_loop_0586:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0586
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8
	sub rdx, 8
	jmp .L_tc_recycle_frame_loop_0586
.L_tc_recycle_frame_done_0586:
	lea rsp, [rbx + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_0317
.L_if_else_0317:
	mov rax, L_constants + 2
.L_if_end_0317:
	jmp .L_if_end_0322
.L_if_else_0322:
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param e1
	push rax
	push 1	; arg count
	mov rax, qword [free_var_177]	; free var vector?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_0319
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param e2
	push rax
	push 1	; arg count
	mov rax, qword [free_var_177]	; free var vector?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_0318
	; preparing a non-tail-call
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param e2
	push rax
	push 1	; arg count
	mov rax, qword [free_var_172]	; free var vector-length
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param e1
	push rax
	push 1	; arg count
	mov rax, qword [free_var_172]	; free var vector-length
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 2	; arg count
	mov rax, qword [free_var_6]	; free var =
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_0318
.L_if_else_0318:
	mov rax, L_constants + 2
.L_if_end_0318:
	jmp .L_if_end_0319
.L_if_else_0319:
	mov rax, L_constants + 2
.L_if_end_0319:
	cmp rax, sob_boolean_false
	je .L_if_else_0321
	; preparing a tail-call
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param e2
	push rax
	push 1	; arg count
	mov rax, qword [free_var_170]	; free var vector->list
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param e1
	push rax
	push 1	; arg count
	mov rax, qword [free_var_170]	; free var vector->list
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 2	; arg count
	mov rax, qword [free_var_89]	; free var equal?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; old return address
	push qword [rbp]	; old frame-pointer
	mov rcx, 6
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8]
.L_tc_recycle_frame_loop_0587:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0587
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8
	sub rdx, 8
	jmp .L_tc_recycle_frame_loop_0587
.L_tc_recycle_frame_done_0587:
	lea rsp, [rbx + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_0321
.L_if_else_0321:
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param e1
	push rax
	push 1	; arg count
	mov rax, qword [free_var_165]	; free var string?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_031b
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param e2
	push rax
	push 1	; arg count
	mov rax, qword [free_var_165]	; free var string?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_031a
	; preparing a non-tail-call
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param e2
	push rax
	push 1	; arg count
	mov rax, qword [free_var_154]	; free var string-length
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param e1
	push rax
	push 1	; arg count
	mov rax, qword [free_var_154]	; free var string-length
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 2	; arg count
	mov rax, qword [free_var_6]	; free var =
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_031a
.L_if_else_031a:
	mov rax, L_constants + 2
.L_if_end_031a:
	jmp .L_if_end_031b
.L_if_else_031b:
	mov rax, L_constants + 2
.L_if_end_031b:
	cmp rax, sob_boolean_false
	je .L_if_else_0320
	; preparing a tail-call
	mov rax, PARAM(1)	; param e2
	push rax
	mov rax, PARAM(0)	; param e1
	push rax
	push 2	; arg count
	mov rax, qword [free_var_162]	; free var string=?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; old return address
	push qword [rbp]	; old frame-pointer
	mov rcx, 6
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8]
.L_tc_recycle_frame_loop_0588:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0588
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8
	sub rdx, 8
	jmp .L_tc_recycle_frame_loop_0588
.L_tc_recycle_frame_done_0588:
	lea rsp, [rbx + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_0320
.L_if_else_0320:
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param e1
	push rax
	push 1	; arg count
	mov rax, qword [free_var_127]	; free var number?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_031c
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param e2
	push rax
	push 1	; arg count
	mov rax, qword [free_var_127]	; free var number?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_031c
.L_if_else_031c:
	mov rax, L_constants + 2
.L_if_end_031c:
	cmp rax, sob_boolean_false
	je .L_if_else_031f
	; preparing a tail-call
	mov rax, PARAM(1)	; param e2
	push rax
	mov rax, PARAM(0)	; param e1
	push rax
	push 2	; arg count
	mov rax, qword [free_var_6]	; free var =
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; old return address
	push qword [rbp]	; old frame-pointer
	mov rcx, 6
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8]
.L_tc_recycle_frame_loop_0589:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0589
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8
	sub rdx, 8
	jmp .L_tc_recycle_frame_loop_0589
.L_tc_recycle_frame_done_0589:
	lea rsp, [rbx + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_031f
.L_if_else_031f:
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param e1
	push rax
	push 1	; arg count
	mov rax, qword [free_var_83]	; free var char?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_031d
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param e2
	push rax
	push 1	; arg count
	mov rax, qword [free_var_83]	; free var char?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_031d
.L_if_else_031d:
	mov rax, L_constants + 2
.L_if_end_031d:
	cmp rax, sob_boolean_false
	je .L_if_else_031e
	; preparing a tail-call
	mov rax, PARAM(1)	; param e2
	push rax
	mov rax, PARAM(0)	; param e1
	push rax
	push 2	; arg count
	mov rax, qword [free_var_80]	; free var char=?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; old return address
	push qword [rbp]	; old frame-pointer
	mov rcx, 6
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8]
.L_tc_recycle_frame_loop_058a:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_058a
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8
	sub rdx, 8
	jmp .L_tc_recycle_frame_loop_058a
.L_tc_recycle_frame_done_058a:
	lea rsp, [rbx + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_031e
.L_if_else_031e:
	; preparing a tail-call
	mov rax, PARAM(1)	; param e2
	push rax
	mov rax, PARAM(0)	; param e1
	push rax
	push 2	; arg count
	mov rax, qword [free_var_88]	; free var eq?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; old return address
	push qword [rbp]	; old frame-pointer
	mov rcx, 6
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8]
.L_tc_recycle_frame_loop_058b:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_058b
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8
	sub rdx, 8
	jmp .L_tc_recycle_frame_loop_058b
.L_tc_recycle_frame_done_058b:
	lea rsp, [rbx + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
.L_if_end_031e:
.L_if_end_031f:
.L_if_end_0320:
.L_if_end_0321:
.L_if_end_0322:
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_simple_end_043a:	; new closure is in rax
	mov qword [free_var_89], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void

	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 0	; new rib
	call malloc
	push rax
	mov rdi, 8 * 1	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_043b:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_043b
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_043b
.L_lambda_simple_env_end_043b:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_043b:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_043b
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_043b
.L_lambda_simple_params_end_043b:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_043b
	jmp .L_lambda_simple_end_043b
.L_lambda_simple_code_043b:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 2
	je .L_lambda_simple_arity_check_ok_043b
	push qword [rsp + 8 * 2]
	push 2
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_043b:
	enter 0, 0
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param s
	push rax
	push 1	; arg count
	mov rax, qword [free_var_126]	; free var null?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_0324
	mov rax, L_constants + 2
	jmp .L_if_end_0324
.L_if_else_0324:
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param a
	push rax
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param s
	push rax
	push 1	; arg count
	mov rax, qword [free_var_46]	; free var caar
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 2	; arg count
	mov rax, qword [free_var_88]	; free var eq?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_0323
	; preparing a tail-call
	mov rax, PARAM(1)	; param s
	push rax
	push 1	; arg count
	mov rax, qword [free_var_54]	; free var car
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; old return address
	push qword [rbp]	; old frame-pointer
	mov rcx, 5
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8]
.L_tc_recycle_frame_loop_058c:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_058c
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8
	sub rdx, 8
	jmp .L_tc_recycle_frame_loop_058c
.L_tc_recycle_frame_done_058c:
	lea rsp, [rbx + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_0323
.L_if_else_0323:
	; preparing a tail-call
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param s
	push rax
	push 1	; arg count
	mov rax, qword [free_var_69]	; free var cdr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	mov rax, PARAM(0)	; param a
	push rax
	push 2	; arg count
	mov rax, qword [free_var_35]	; free var assoc
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; old return address
	push qword [rbp]	; old frame-pointer
	mov rcx, 6
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8]
.L_tc_recycle_frame_loop_058d:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_058d
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8
	sub rdx, 8
	jmp .L_tc_recycle_frame_loop_058d
.L_tc_recycle_frame_done_058d:
	lea rsp, [rbx + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
.L_if_end_0323:
.L_if_end_0324:
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_simple_end_043b:	; new closure is in rax
	mov qword [free_var_35], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void

	; preparing a non-tail-call
	mov rax, L_constants + 2335
	push rax
	mov rax, L_constants + 2335
	push rax
	push 2	; arg count
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 0	; new rib
	call malloc
	push rax
	mov rdi, 8 * 1	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_043c:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_043c
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_043c
.L_lambda_simple_env_end_043c:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_043c:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_043c
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_043c
.L_lambda_simple_params_end_043c:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_043c
	jmp .L_lambda_simple_end_043c
.L_lambda_simple_code_043c:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 2
	je .L_lambda_simple_arity_check_ok_043c
	push qword [rsp + 8 * 2]
	push 2
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_043c:
	enter 0, 0

	mov rdi, 8
	call malloc
	mov rbx, PARAM(0)	; param run
	mov [rax], rbx	; box run
	mov PARAM(0), rax	; replace param with box
	mov rax, sob_void


	mov rdi, 8
	call malloc
	mov rbx, PARAM(1)	; param add
	mov [rax], rbx	; box add
	mov PARAM(1), rax	; replace param with box
	mov rax, sob_void

	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 2	; new rib
	call malloc
	push rax
	mov rdi, 8 * 2	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_043d:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
	je .L_lambda_simple_env_end_043d
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_043d
.L_lambda_simple_env_end_043d:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_043d:	; copy params
	cmp rsi, 2
	je .L_lambda_simple_params_end_043d
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_043d
.L_lambda_simple_params_end_043d:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_043d
	jmp .L_lambda_simple_end_043d
.L_lambda_simple_code_043d:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 3
	je .L_lambda_simple_arity_check_ok_043d
	push qword [rsp + 8 * 2]
	push 3
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_043d:
	enter 0, 0
	; preparing a non-tail-call
	mov rax, PARAM(2)	; param s
	push rax
	push 1	; arg count
	mov rax, qword [free_var_126]	; free var null?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_0325
	mov rax, PARAM(0)	; param target
	jmp .L_if_end_0325
.L_if_else_0325:
	; preparing a tail-call
	; preparing a non-tail-call
	; preparing a non-tail-call
	; preparing a non-tail-call
	mov rax, PARAM(2)	; param s
	push rax
	push 1	; arg count
	mov rax, qword [free_var_54]	; free var car
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 1	; arg count
	mov rax, qword [free_var_154]	; free var string-length
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	mov rax, L_constants + 2558
	push rax
	; preparing a non-tail-call
	mov rax, PARAM(2)	; param s
	push rax
	push 1	; arg count
	mov rax, qword [free_var_54]	; free var car
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	mov rax, PARAM(1)	; param i
	push rax
	mov rax, PARAM(0)	; param target
	push rax
	push 5	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 1]	; bound var add
	mov rax, qword [rax]
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 1	; arg count
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 3	; new rib
	call malloc
	push rax
	mov rdi, 8 * 3	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_043e:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 2
	je .L_lambda_simple_env_end_043e
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_043e
.L_lambda_simple_env_end_043e:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_043e:	; copy params
	cmp rsi, 3
	je .L_lambda_simple_params_end_043e
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_043e
.L_lambda_simple_params_end_043e:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_043e
	jmp .L_lambda_simple_end_043e
.L_lambda_simple_code_043e:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_043e
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_043e:
	enter 0, 0
	; preparing a tail-call
	; preparing a non-tail-call
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 2]	; bound var s
	push rax
	push 1	; arg count
	mov rax, qword [free_var_69]	; free var cdr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	mov rax, PARAM(0)	; param i
	push rax
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var target
	push rax
	push 3	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 1]
	mov rax, qword [rax + 8 * 0]	; bound var run
	mov rax, qword [rax]
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; old return address
	push qword [rbp]	; old frame-pointer
	mov rcx, 7
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8]
.L_tc_recycle_frame_loop_058e:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_058e
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8
	sub rdx, 8
	jmp .L_tc_recycle_frame_loop_058e
.L_tc_recycle_frame_done_058e:
	lea rsp, [rbx + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_043e:	; new closure is in rax
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; old return address
	push qword [rbp]	; old frame-pointer
	mov rcx, 5
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8]
.L_tc_recycle_frame_loop_058f:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_058f
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8
	sub rdx, 8
	jmp .L_tc_recycle_frame_loop_058f
.L_tc_recycle_frame_done_058f:
	lea rsp, [rbx + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
.L_if_end_0325:
	leave
	ret AND_KILL_FRAME(3)
.L_lambda_simple_end_043d:	; new closure is in rax

	push rax
	mov rax, PARAM(0)	; param run

	pop qword[rax]
	mov rax, sob_void

	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 2	; new rib
	call malloc
	push rax
	mov rdi, 8 * 2	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_043f:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
	je .L_lambda_simple_env_end_043f
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_043f
.L_lambda_simple_env_end_043f:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_043f:	; copy params
	cmp rsi, 2
	je .L_lambda_simple_params_end_043f
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_043f
.L_lambda_simple_params_end_043f:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_043f
	jmp .L_lambda_simple_end_043f
.L_lambda_simple_code_043f:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 5
	je .L_lambda_simple_arity_check_ok_043f
	push qword [rsp + 8 * 2]
	push 5
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_043f:
	enter 0, 0
	; preparing a non-tail-call
	mov rax, PARAM(4)	; param limit
	push rax
	mov rax, PARAM(3)	; param j
	push rax
	push 2	; arg count
	mov rax, qword [free_var_4]	; free var <
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_0326
	; preparing a non-tail-call
	; preparing a non-tail-call
	mov rax, PARAM(3)	; param j
	push rax
	mov rax, PARAM(2)	; param str
	push rax
	push 2	; arg count
	mov rax, qword [free_var_155]	; free var string-ref
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	mov rax, PARAM(1)	; param i
	push rax
	mov rax, PARAM(0)	; param target
	push rax
	push 3	; arg count
	mov rax, qword [free_var_158]	; free var string-set!
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)

	; preparing a tail-call
	mov rax, PARAM(4)	; param limit
	push rax
	; preparing a non-tail-call
	mov rax, L_constants + 2810
	push rax
	mov rax, PARAM(3)	; param j
	push rax
	push 2	; arg count
	mov rax, qword [free_var_1]	; free var +
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	mov rax, PARAM(2)	; param str
	push rax
	; preparing a non-tail-call
	mov rax, L_constants + 2810
	push rax
	mov rax, PARAM(1)	; param i
	push rax
	push 2	; arg count
	mov rax, qword [free_var_1]	; free var +
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	mov rax, PARAM(0)	; param target
	push rax
	push 5	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 1]	; bound var add
	mov rax, qword [rax]
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; old return address
	push qword [rbp]	; old frame-pointer
	mov rcx, 9
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8]
.L_tc_recycle_frame_loop_0590:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0590
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8
	sub rdx, 8
	jmp .L_tc_recycle_frame_loop_0590
.L_tc_recycle_frame_done_0590:
	lea rsp, [rbx + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_0326
.L_if_else_0326:
	mov rax, PARAM(1)	; param i
.L_if_end_0326:
	leave
	ret AND_KILL_FRAME(5)
.L_lambda_simple_end_043f:	; new closure is in rax

	push rax
	mov rax, PARAM(1)	; param add

	pop qword[rax]
	mov rax, sob_void

	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 2	; new rib
	call malloc
	push rax
	mov rdi, 8 * 2	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_opt_env_loop_0090:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
	je .L_lambda_opt_env_end_0090
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_opt_env_loop_0090
.L_lambda_opt_env_end_0090:
	pop rbx
	mov rsi, 0
.L_lambda_opt_params_loop_0090:	; copy params
	cmp rsi, 2
	je .L_lambda_opt_params_end_0090
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_opt_params_loop_0090
.L_lambda_opt_params_end_0090:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_opt_code_0090
	jmp .L_lambda_opt_end_0090
.L_lambda_opt_code_0090:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 0 ;	 check num of args
	je .L_lambda_opt_arity_check_exact_0090 ;	 if equal, go to exact arity
	jg .L_lambda_opt_arity_check_more_0090 ;	 if greater than, go to arity more
	push qword [rsp + 8 * 2] ;	 else, throw opt arity error
	push 0
	jmp L_error_incorrect_arity_opt
.L_lambda_opt_arity_check_exact_0090:
	mov rax, qword [rsp + 8 * 2] ;	 number of args
	lea rbx, [rsp + 8 * (2 + rax)] ;	 address of last element
	sub rsp, 8
	lea rcx, [rsp + 0] ;	 new start
.L_lambda_opt_shift_entry_0090:
	mov rdx, [rcx + 8]
	mov [rcx], rdx
	add rcx, 8
	cmp rbx, rcx
	jne .L_lambda_opt_shift_entry_0090
.L_lambda_opt_shift_exit_0090:
	mov qword[rbx], sob_nil ;	 place nil
	add rax, 1
	mov qword [rsp + 8 * 2], rax
	jmp .L_lambda_opt_stack_adjusted_0090
.L_lambda_opt_arity_check_more_0090:
	mov rdx, sob_nil ;	 base cdr
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_opt_stack_shrink_loop_exit_0090
.L_lambda_opt_stack_shrink_loop_0090:
	mov rdi, (1 + 8 + 8)
	call malloc
	mov byte[rax], T_pair
	mov SOB_PAIR_CDR(rax), rdx
	mov rdx, rax
	mov rax, qword [rsp + 8 * 2]
	mov rbx, qword [rsp + 8 * (2 + rax)]
	mov SOB_PAIR_CAR(rdx), rbx
	lea rbx, [rsp + 8 * (2 + rax - 1)]
.L_lambda_opt_extra_shift_process_0090:
	mov rcx, [rbx]
	mov [rbx + 8], rcx
	sub rbx, 8
	cmp rsp, rbx
	jle .L_lambda_opt_extra_shift_process_0090
.L_lambda_opt_extra_shift_process_end_0090:
	add rsp, 8
	mov rbx, [rsp + 8 * 2]
	sub rbx, 1
	mov [rsp + 8 * 2], rbx
	cmp qword [rsp + 8 * 2], 1
	jg .L_lambda_opt_stack_shrink_loop_0090
.L_lambda_opt_stack_shrink_loop_exit_0090:
	mov rcx, [rsp + 8 * 2]
	mov rbx, qword [rsp + 8 * (2 + rcx)]
	mov rdi, (1 + 8 + 8)
	call malloc
	mov byte[rax], T_pair
	mov SOB_PAIR_CDR(rax), rdx
	mov SOB_PAIR_CAR(rax), rbx
	mov [rsp + 8 * (2 + rcx)], rax
.L_lambda_opt_stack_adjusted_0090:
	enter 0, 0
	; preparing a tail-call
	mov rax, PARAM(0)	; param strings
	push rax
	mov rax, L_constants + 2558
	push rax
	; preparing a non-tail-call
	; preparing a non-tail-call
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param strings
	push rax
	mov rax, qword [free_var_154]	; free var string-length
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	push rax
	push 2	; arg count
	mov rax, qword [free_var_122]	; free var map
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	mov rax, qword [free_var_1]	; free var +
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	push rax
	push 2	; arg count
	mov rax, qword [free_var_33]	; free var apply
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 1	; arg count
	mov rax, qword [free_var_118]	; free var make-string
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 3	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var run
	mov rax, qword [rax]
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; old return address
	push qword [rbp]	; old frame-pointer
	mov rcx, 7
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8]
.L_tc_recycle_frame_loop_0591:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0591
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8
	sub rdx, 8
	jmp .L_tc_recycle_frame_loop_0591
.L_tc_recycle_frame_done_0591:
	lea rsp, [rbx + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_opt_end_0090:	; new closure is in rax
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_simple_end_043c:	; new closure is in rax
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	mov qword [free_var_147], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void

	; preparing a non-tail-call
	mov rax, L_constants + 2335
	push rax
	mov rax, L_constants + 2335
	push rax
	push 2	; arg count
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 0	; new rib
	call malloc
	push rax
	mov rdi, 8 * 1	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_0440:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_0440
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0440
.L_lambda_simple_env_end_0440:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0440:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_0440
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0440
.L_lambda_simple_params_end_0440:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0440
	jmp .L_lambda_simple_end_0440
.L_lambda_simple_code_0440:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 2
	je .L_lambda_simple_arity_check_ok_0440
	push qword [rsp + 8 * 2]
	push 2
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0440:
	enter 0, 0

	mov rdi, 8
	call malloc
	mov rbx, PARAM(0)	; param run
	mov [rax], rbx	; box run
	mov PARAM(0), rax	; replace param with box
	mov rax, sob_void


	mov rdi, 8
	call malloc
	mov rbx, PARAM(1)	; param add
	mov [rax], rbx	; box add
	mov PARAM(1), rax	; replace param with box
	mov rax, sob_void

	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 2	; new rib
	call malloc
	push rax
	mov rdi, 8 * 2	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_0441:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
	je .L_lambda_simple_env_end_0441
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0441
.L_lambda_simple_env_end_0441:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0441:	; copy params
	cmp rsi, 2
	je .L_lambda_simple_params_end_0441
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0441
.L_lambda_simple_params_end_0441:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0441
	jmp .L_lambda_simple_end_0441
.L_lambda_simple_code_0441:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 3
	je .L_lambda_simple_arity_check_ok_0441
	push qword [rsp + 8 * 2]
	push 3
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0441:
	enter 0, 0
	; preparing a non-tail-call
	mov rax, PARAM(2)	; param s
	push rax
	push 1	; arg count
	mov rax, qword [free_var_126]	; free var null?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_0327
	mov rax, PARAM(0)	; param target
	jmp .L_if_end_0327
.L_if_else_0327:
	; preparing a tail-call
	; preparing a non-tail-call
	; preparing a non-tail-call
	; preparing a non-tail-call
	mov rax, PARAM(2)	; param s
	push rax
	push 1	; arg count
	mov rax, qword [free_var_54]	; free var car
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 1	; arg count
	mov rax, qword [free_var_172]	; free var vector-length
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	mov rax, L_constants + 2558
	push rax
	; preparing a non-tail-call
	mov rax, PARAM(2)	; param s
	push rax
	push 1	; arg count
	mov rax, qword [free_var_54]	; free var car
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	mov rax, PARAM(1)	; param i
	push rax
	mov rax, PARAM(0)	; param target
	push rax
	push 5	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 1]	; bound var add
	mov rax, qword [rax]
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 1	; arg count
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 3	; new rib
	call malloc
	push rax
	mov rdi, 8 * 3	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_0442:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 2
	je .L_lambda_simple_env_end_0442
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0442
.L_lambda_simple_env_end_0442:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0442:	; copy params
	cmp rsi, 3
	je .L_lambda_simple_params_end_0442
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0442
.L_lambda_simple_params_end_0442:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0442
	jmp .L_lambda_simple_end_0442
.L_lambda_simple_code_0442:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0442
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0442:
	enter 0, 0
	; preparing a tail-call
	; preparing a non-tail-call
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 2]	; bound var s
	push rax
	push 1	; arg count
	mov rax, qword [free_var_69]	; free var cdr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	mov rax, PARAM(0)	; param i
	push rax
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var target
	push rax
	push 3	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 1]
	mov rax, qword [rax + 8 * 0]	; bound var run
	mov rax, qword [rax]
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; old return address
	push qword [rbp]	; old frame-pointer
	mov rcx, 7
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8]
.L_tc_recycle_frame_loop_0592:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0592
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8
	sub rdx, 8
	jmp .L_tc_recycle_frame_loop_0592
.L_tc_recycle_frame_done_0592:
	lea rsp, [rbx + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0442:	; new closure is in rax
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; old return address
	push qword [rbp]	; old frame-pointer
	mov rcx, 5
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8]
.L_tc_recycle_frame_loop_0593:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0593
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8
	sub rdx, 8
	jmp .L_tc_recycle_frame_loop_0593
.L_tc_recycle_frame_done_0593:
	lea rsp, [rbx + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
.L_if_end_0327:
	leave
	ret AND_KILL_FRAME(3)
.L_lambda_simple_end_0441:	; new closure is in rax

	push rax
	mov rax, PARAM(0)	; param run

	pop qword[rax]
	mov rax, sob_void

	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 2	; new rib
	call malloc
	push rax
	mov rdi, 8 * 2	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_0443:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
	je .L_lambda_simple_env_end_0443
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0443
.L_lambda_simple_env_end_0443:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0443:	; copy params
	cmp rsi, 2
	je .L_lambda_simple_params_end_0443
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0443
.L_lambda_simple_params_end_0443:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0443
	jmp .L_lambda_simple_end_0443
.L_lambda_simple_code_0443:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 5
	je .L_lambda_simple_arity_check_ok_0443
	push qword [rsp + 8 * 2]
	push 5
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0443:
	enter 0, 0
	; preparing a non-tail-call
	mov rax, PARAM(4)	; param limit
	push rax
	mov rax, PARAM(3)	; param j
	push rax
	push 2	; arg count
	mov rax, qword [free_var_4]	; free var <
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_0328
	; preparing a non-tail-call
	; preparing a non-tail-call
	mov rax, PARAM(3)	; param j
	push rax
	mov rax, PARAM(2)	; param vec
	push rax
	push 2	; arg count
	mov rax, qword [free_var_173]	; free var vector-ref
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	mov rax, PARAM(1)	; param i
	push rax
	mov rax, PARAM(0)	; param target
	push rax
	push 3	; arg count
	mov rax, qword [free_var_176]	; free var vector-set!
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)

	; preparing a tail-call
	mov rax, PARAM(4)	; param limit
	push rax
	; preparing a non-tail-call
	mov rax, L_constants + 2810
	push rax
	mov rax, PARAM(3)	; param j
	push rax
	push 2	; arg count
	mov rax, qword [free_var_1]	; free var +
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	mov rax, PARAM(2)	; param vec
	push rax
	; preparing a non-tail-call
	mov rax, L_constants + 2810
	push rax
	mov rax, PARAM(1)	; param i
	push rax
	push 2	; arg count
	mov rax, qword [free_var_1]	; free var +
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	mov rax, PARAM(0)	; param target
	push rax
	push 5	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 1]	; bound var add
	mov rax, qword [rax]
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; old return address
	push qword [rbp]	; old frame-pointer
	mov rcx, 9
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8]
.L_tc_recycle_frame_loop_0594:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0594
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8
	sub rdx, 8
	jmp .L_tc_recycle_frame_loop_0594
.L_tc_recycle_frame_done_0594:
	lea rsp, [rbx + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_0328
.L_if_else_0328:
	mov rax, PARAM(1)	; param i
.L_if_end_0328:
	leave
	ret AND_KILL_FRAME(5)
.L_lambda_simple_end_0443:	; new closure is in rax

	push rax
	mov rax, PARAM(1)	; param add

	pop qword[rax]
	mov rax, sob_void

	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 2	; new rib
	call malloc
	push rax
	mov rdi, 8 * 2	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_opt_env_loop_0091:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
	je .L_lambda_opt_env_end_0091
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_opt_env_loop_0091
.L_lambda_opt_env_end_0091:
	pop rbx
	mov rsi, 0
.L_lambda_opt_params_loop_0091:	; copy params
	cmp rsi, 2
	je .L_lambda_opt_params_end_0091
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_opt_params_loop_0091
.L_lambda_opt_params_end_0091:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_opt_code_0091
	jmp .L_lambda_opt_end_0091
.L_lambda_opt_code_0091:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 0 ;	 check num of args
	je .L_lambda_opt_arity_check_exact_0091 ;	 if equal, go to exact arity
	jg .L_lambda_opt_arity_check_more_0091 ;	 if greater than, go to arity more
	push qword [rsp + 8 * 2] ;	 else, throw opt arity error
	push 0
	jmp L_error_incorrect_arity_opt
.L_lambda_opt_arity_check_exact_0091:
	mov rax, qword [rsp + 8 * 2] ;	 number of args
	lea rbx, [rsp + 8 * (2 + rax)] ;	 address of last element
	sub rsp, 8
	lea rcx, [rsp + 0] ;	 new start
.L_lambda_opt_shift_entry_0091:
	mov rdx, [rcx + 8]
	mov [rcx], rdx
	add rcx, 8
	cmp rbx, rcx
	jne .L_lambda_opt_shift_entry_0091
.L_lambda_opt_shift_exit_0091:
	mov qword[rbx], sob_nil ;	 place nil
	add rax, 1
	mov qword [rsp + 8 * 2], rax
	jmp .L_lambda_opt_stack_adjusted_0091
.L_lambda_opt_arity_check_more_0091:
	mov rdx, sob_nil ;	 base cdr
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_opt_stack_shrink_loop_exit_0091
.L_lambda_opt_stack_shrink_loop_0091:
	mov rdi, (1 + 8 + 8)
	call malloc
	mov byte[rax], T_pair
	mov SOB_PAIR_CDR(rax), rdx
	mov rdx, rax
	mov rax, qword [rsp + 8 * 2]
	mov rbx, qword [rsp + 8 * (2 + rax)]
	mov SOB_PAIR_CAR(rdx), rbx
	lea rbx, [rsp + 8 * (2 + rax - 1)]
.L_lambda_opt_extra_shift_process_0091:
	mov rcx, [rbx]
	mov [rbx + 8], rcx
	sub rbx, 8
	cmp rsp, rbx
	jle .L_lambda_opt_extra_shift_process_0091
.L_lambda_opt_extra_shift_process_end_0091:
	add rsp, 8
	mov rbx, [rsp + 8 * 2]
	sub rbx, 1
	mov [rsp + 8 * 2], rbx
	cmp qword [rsp + 8 * 2], 1
	jg .L_lambda_opt_stack_shrink_loop_0091
.L_lambda_opt_stack_shrink_loop_exit_0091:
	mov rcx, [rsp + 8 * 2]
	mov rbx, qword [rsp + 8 * (2 + rcx)]
	mov rdi, (1 + 8 + 8)
	call malloc
	mov byte[rax], T_pair
	mov SOB_PAIR_CDR(rax), rdx
	mov SOB_PAIR_CAR(rax), rbx
	mov [rsp + 8 * (2 + rcx)], rax
.L_lambda_opt_stack_adjusted_0091:
	enter 0, 0
	; preparing a tail-call
	mov rax, PARAM(0)	; param vectors
	push rax
	mov rax, L_constants + 2558
	push rax
	; preparing a non-tail-call
	; preparing a non-tail-call
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param vectors
	push rax
	mov rax, qword [free_var_172]	; free var vector-length
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	push rax
	push 2	; arg count
	mov rax, qword [free_var_122]	; free var map
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	mov rax, qword [free_var_1]	; free var +
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	push rax
	push 2	; arg count
	mov rax, qword [free_var_33]	; free var apply
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 1	; arg count
	mov rax, qword [free_var_120]	; free var make-vector
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 3	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var run
	mov rax, qword [rax]
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; old return address
	push qword [rbp]	; old frame-pointer
	mov rcx, 7
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8]
.L_tc_recycle_frame_loop_0595:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0595
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8
	sub rdx, 8
	jmp .L_tc_recycle_frame_loop_0595
.L_tc_recycle_frame_done_0595:
	lea rsp, [rbx + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_opt_end_0091:	; new closure is in rax
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_simple_end_0440:	; new closure is in rax
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	mov qword [free_var_171], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void

	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 0	; new rib
	call malloc
	push rax
	mov rdi, 8 * 1	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_0444:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_0444
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0444
.L_lambda_simple_env_end_0444:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0444:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_0444
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0444
.L_lambda_simple_params_end_0444:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0444
	jmp .L_lambda_simple_end_0444
.L_lambda_simple_code_0444:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0444
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0444:
	enter 0, 0
	; preparing a tail-call
	; preparing a non-tail-call
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param str
	push rax
	push 1	; arg count
	mov rax, qword [free_var_146]	; free var string->list
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 1	; arg count
	mov rax, qword [free_var_143]	; free var reverse
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 1	; arg count
	mov rax, qword [free_var_108]	; free var list->string
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; old return address
	push qword [rbp]	; old frame-pointer
	mov rcx, 5
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8]
.L_tc_recycle_frame_loop_0596:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0596
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8
	sub rdx, 8
	jmp .L_tc_recycle_frame_loop_0596
.L_tc_recycle_frame_done_0596:
	lea rsp, [rbx + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0444:	; new closure is in rax
	mov qword [free_var_156], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void

	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 0	; new rib
	call malloc
	push rax
	mov rdi, 8 * 1	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_0445:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_0445
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0445
.L_lambda_simple_env_end_0445:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0445:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_0445
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0445
.L_lambda_simple_params_end_0445:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0445
	jmp .L_lambda_simple_end_0445
.L_lambda_simple_code_0445:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0445
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0445:
	enter 0, 0
	; preparing a tail-call
	; preparing a non-tail-call
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param vec
	push rax
	push 1	; arg count
	mov rax, qword [free_var_170]	; free var vector->list
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 1	; arg count
	mov rax, qword [free_var_143]	; free var reverse
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 1	; arg count
	mov rax, qword [free_var_109]	; free var list->vector
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; old return address
	push qword [rbp]	; old frame-pointer
	mov rcx, 5
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8]
.L_tc_recycle_frame_loop_0597:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0597
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8
	sub rdx, 8
	jmp .L_tc_recycle_frame_loop_0597
.L_tc_recycle_frame_done_0597:
	lea rsp, [rbx + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0445:	; new closure is in rax
	mov qword [free_var_174], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void

	; preparing a non-tail-call
	mov rax, L_constants + 2335
	push rax
	push 1	; arg count
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 0	; new rib
	call malloc
	push rax
	mov rdi, 8 * 1	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_0446:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_0446
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0446
.L_lambda_simple_env_end_0446:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0446:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_0446
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0446
.L_lambda_simple_params_end_0446:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0446
	jmp .L_lambda_simple_end_0446
.L_lambda_simple_code_0446:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0446
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0446:
	enter 0, 0

	mov rdi, 8
	call malloc
	mov rbx, PARAM(0)	; param run
	mov [rax], rbx	; box run
	mov PARAM(0), rax	; replace param with box
	mov rax, sob_void

	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 1	; new rib
	call malloc
	push rax
	mov rdi, 8 * 2	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_0447:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
	je .L_lambda_simple_env_end_0447
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0447
.L_lambda_simple_env_end_0447:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0447:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_0447
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0447
.L_lambda_simple_params_end_0447:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0447
	jmp .L_lambda_simple_end_0447
.L_lambda_simple_code_0447:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 3
	je .L_lambda_simple_arity_check_ok_0447
	push qword [rsp + 8 * 2]
	push 3
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0447:
	enter 0, 0
	; preparing a non-tail-call
	mov rax, PARAM(2)	; param j
	push rax
	mov rax, PARAM(1)	; param i
	push rax
	push 2	; arg count
	mov rax, qword [free_var_4]	; free var <
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_0329
	; preparing a tail-call
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param i
	push rax
	mov rax, PARAM(0)	; param str
	push rax
	push 2	; arg count
	mov rax, qword [free_var_155]	; free var string-ref
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 1	; arg count
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 3	; new rib
	call malloc
	push rax
	mov rdi, 8 * 3	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_0448:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 2
	je .L_lambda_simple_env_end_0448
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0448
.L_lambda_simple_env_end_0448:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0448:	; copy params
	cmp rsi, 3
	je .L_lambda_simple_params_end_0448
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0448
.L_lambda_simple_params_end_0448:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0448
	jmp .L_lambda_simple_end_0448
.L_lambda_simple_code_0448:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0448
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0448:
	enter 0, 0
	; preparing a non-tail-call
	; preparing a non-tail-call
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 2]	; bound var j
	push rax
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var str
	push rax
	push 2	; arg count
	mov rax, qword [free_var_155]	; free var string-ref
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 1]	; bound var i
	push rax
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var str
	push rax
	push 3	; arg count
	mov rax, qword [free_var_158]	; free var string-set!
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)

	; preparing a non-tail-call
	mov rax, PARAM(0)	; param ch
	push rax
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 2]	; bound var j
	push rax
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var str
	push rax
	push 3	; arg count
	mov rax, qword [free_var_158]	; free var string-set!
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)

	; preparing a tail-call
	; preparing a non-tail-call
	mov rax, L_constants + 2810
	push rax
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 2]	; bound var j
	push rax
	push 2	; arg count
	mov rax, qword [free_var_2]	; free var -
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	; preparing a non-tail-call
	mov rax, L_constants + 2810
	push rax
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 1]	; bound var i
	push rax
	push 2	; arg count
	mov rax, qword [free_var_1]	; free var +
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var str
	push rax
	push 3	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 1]
	mov rax, qword [rax + 8 * 0]	; bound var run
	mov rax, qword [rax]
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; old return address
	push qword [rbp]	; old frame-pointer
	mov rcx, 7
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8]
.L_tc_recycle_frame_loop_0598:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0598
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8
	sub rdx, 8
	jmp .L_tc_recycle_frame_loop_0598
.L_tc_recycle_frame_done_0598:
	lea rsp, [rbx + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0448:	; new closure is in rax
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; old return address
	push qword [rbp]	; old frame-pointer
	mov rcx, 5
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8]
.L_tc_recycle_frame_loop_0599:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0599
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8
	sub rdx, 8
	jmp .L_tc_recycle_frame_loop_0599
.L_tc_recycle_frame_done_0599:
	lea rsp, [rbx + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_0329
.L_if_else_0329:
	mov rax, PARAM(0)	; param str
.L_if_end_0329:
	leave
	ret AND_KILL_FRAME(3)
.L_lambda_simple_end_0447:	; new closure is in rax

	push rax
	mov rax, PARAM(0)	; param run

	pop qword[rax]
	mov rax, sob_void

	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 1	; new rib
	call malloc
	push rax
	mov rdi, 8 * 2	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_0449:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
	je .L_lambda_simple_env_end_0449
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0449
.L_lambda_simple_env_end_0449:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0449:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_0449
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0449
.L_lambda_simple_params_end_0449:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0449
	jmp .L_lambda_simple_end_0449
.L_lambda_simple_code_0449:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0449
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0449:
	enter 0, 0
	; preparing a tail-call
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param str
	push rax
	push 1	; arg count
	mov rax, qword [free_var_154]	; free var string-length
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 1	; arg count
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 1	; new rib
	call malloc
	push rax
	mov rdi, 8 * 3	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_044a:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 2
	je .L_lambda_simple_env_end_044a
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_044a
.L_lambda_simple_env_end_044a:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_044a:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_044a
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_044a
.L_lambda_simple_params_end_044a:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_044a
	jmp .L_lambda_simple_end_044a
.L_lambda_simple_code_044a:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_044a
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_044a:
	enter 0, 0
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param n
	push rax
	push 1	; arg count
	mov rax, qword [free_var_181]	; free var zero?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_032a
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var str
	jmp .L_if_end_032a
.L_if_else_032a:
	; preparing a tail-call
	; preparing a non-tail-call
	mov rax, L_constants + 2810
	push rax
	mov rax, PARAM(0)	; param n
	push rax
	push 2	; arg count
	mov rax, qword [free_var_2]	; free var -
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	mov rax, L_constants + 2558
	push rax
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var str
	push rax
	push 3	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 1]
	mov rax, qword [rax + 8 * 0]	; bound var run
	mov rax, qword [rax]
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; old return address
	push qword [rbp]	; old frame-pointer
	mov rcx, 7
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8]
.L_tc_recycle_frame_loop_059a:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_059a
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8
	sub rdx, 8
	jmp .L_tc_recycle_frame_loop_059a
.L_tc_recycle_frame_done_059a:
	lea rsp, [rbx + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
.L_if_end_032a:
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_044a:	; new closure is in rax
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; old return address
	push qword [rbp]	; old frame-pointer
	mov rcx, 5
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8]
.L_tc_recycle_frame_loop_059b:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_059b
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8
	sub rdx, 8
	jmp .L_tc_recycle_frame_loop_059b
.L_tc_recycle_frame_done_059b:
	lea rsp, [rbx + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0449:	; new closure is in rax
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0446:	; new closure is in rax
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	mov qword [free_var_157], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void

	; preparing a non-tail-call
	mov rax, L_constants + 2335
	push rax
	push 1	; arg count
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 0	; new rib
	call malloc
	push rax
	mov rdi, 8 * 1	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_044b:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_044b
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_044b
.L_lambda_simple_env_end_044b:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_044b:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_044b
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_044b
.L_lambda_simple_params_end_044b:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_044b
	jmp .L_lambda_simple_end_044b
.L_lambda_simple_code_044b:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_044b
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_044b:
	enter 0, 0

	mov rdi, 8
	call malloc
	mov rbx, PARAM(0)	; param run
	mov [rax], rbx	; box run
	mov PARAM(0), rax	; replace param with box
	mov rax, sob_void

	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 1	; new rib
	call malloc
	push rax
	mov rdi, 8 * 2	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_044c:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
	je .L_lambda_simple_env_end_044c
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_044c
.L_lambda_simple_env_end_044c:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_044c:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_044c
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_044c
.L_lambda_simple_params_end_044c:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_044c
	jmp .L_lambda_simple_end_044c
.L_lambda_simple_code_044c:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 3
	je .L_lambda_simple_arity_check_ok_044c
	push qword [rsp + 8 * 2]
	push 3
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_044c:
	enter 0, 0
	; preparing a non-tail-call
	mov rax, PARAM(2)	; param j
	push rax
	mov rax, PARAM(1)	; param i
	push rax
	push 2	; arg count
	mov rax, qword [free_var_4]	; free var <
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_032b
	; preparing a tail-call
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param i
	push rax
	mov rax, PARAM(0)	; param vec
	push rax
	push 2	; arg count
	mov rax, qword [free_var_173]	; free var vector-ref
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 1	; arg count
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 3	; new rib
	call malloc
	push rax
	mov rdi, 8 * 3	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_044d:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 2
	je .L_lambda_simple_env_end_044d
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_044d
.L_lambda_simple_env_end_044d:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_044d:	; copy params
	cmp rsi, 3
	je .L_lambda_simple_params_end_044d
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_044d
.L_lambda_simple_params_end_044d:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_044d
	jmp .L_lambda_simple_end_044d
.L_lambda_simple_code_044d:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_044d
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_044d:
	enter 0, 0
	; preparing a non-tail-call
	; preparing a non-tail-call
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 2]	; bound var j
	push rax
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var vec
	push rax
	push 2	; arg count
	mov rax, qword [free_var_173]	; free var vector-ref
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 1]	; bound var i
	push rax
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var vec
	push rax
	push 3	; arg count
	mov rax, qword [free_var_176]	; free var vector-set!
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)

	; preparing a non-tail-call
	mov rax, PARAM(0)	; param ch
	push rax
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 2]	; bound var j
	push rax
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var vec
	push rax
	push 3	; arg count
	mov rax, qword [free_var_176]	; free var vector-set!
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)

	; preparing a tail-call
	; preparing a non-tail-call
	mov rax, L_constants + 2810
	push rax
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 2]	; bound var j
	push rax
	push 2	; arg count
	mov rax, qword [free_var_2]	; free var -
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	; preparing a non-tail-call
	mov rax, L_constants + 2810
	push rax
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 1]	; bound var i
	push rax
	push 2	; arg count
	mov rax, qword [free_var_1]	; free var +
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var vec
	push rax
	push 3	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 1]
	mov rax, qword [rax + 8 * 0]	; bound var run
	mov rax, qword [rax]
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; old return address
	push qword [rbp]	; old frame-pointer
	mov rcx, 7
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8]
.L_tc_recycle_frame_loop_059c:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_059c
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8
	sub rdx, 8
	jmp .L_tc_recycle_frame_loop_059c
.L_tc_recycle_frame_done_059c:
	lea rsp, [rbx + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_044d:	; new closure is in rax
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; old return address
	push qword [rbp]	; old frame-pointer
	mov rcx, 5
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8]
.L_tc_recycle_frame_loop_059d:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_059d
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8
	sub rdx, 8
	jmp .L_tc_recycle_frame_loop_059d
.L_tc_recycle_frame_done_059d:
	lea rsp, [rbx + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_032b
.L_if_else_032b:
	mov rax, PARAM(0)	; param vec
.L_if_end_032b:
	leave
	ret AND_KILL_FRAME(3)
.L_lambda_simple_end_044c:	; new closure is in rax

	push rax
	mov rax, PARAM(0)	; param run

	pop qword[rax]
	mov rax, sob_void

	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 1	; new rib
	call malloc
	push rax
	mov rdi, 8 * 2	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_044e:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
	je .L_lambda_simple_env_end_044e
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_044e
.L_lambda_simple_env_end_044e:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_044e:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_044e
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_044e
.L_lambda_simple_params_end_044e:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_044e
	jmp .L_lambda_simple_end_044e
.L_lambda_simple_code_044e:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_044e
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_044e:
	enter 0, 0
	; preparing a tail-call
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param vec
	push rax
	push 1	; arg count
	mov rax, qword [free_var_172]	; free var vector-length
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 1	; arg count
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 1	; new rib
	call malloc
	push rax
	mov rdi, 8 * 3	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_044f:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 2
	je .L_lambda_simple_env_end_044f
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_044f
.L_lambda_simple_env_end_044f:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_044f:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_044f
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_044f
.L_lambda_simple_params_end_044f:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_044f
	jmp .L_lambda_simple_end_044f
.L_lambda_simple_code_044f:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_044f
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_044f:
	enter 0, 0
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param n
	push rax
	push 1	; arg count
	mov rax, qword [free_var_181]	; free var zero?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_032c
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var vec
	jmp .L_if_end_032c
.L_if_else_032c:
	; preparing a tail-call
	; preparing a non-tail-call
	mov rax, L_constants + 2810
	push rax
	mov rax, PARAM(0)	; param n
	push rax
	push 2	; arg count
	mov rax, qword [free_var_2]	; free var -
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	mov rax, L_constants + 2558
	push rax
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var vec
	push rax
	push 3	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 1]
	mov rax, qword [rax + 8 * 0]	; bound var run
	mov rax, qword [rax]
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; old return address
	push qword [rbp]	; old frame-pointer
	mov rcx, 7
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8]
.L_tc_recycle_frame_loop_059e:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_059e
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8
	sub rdx, 8
	jmp .L_tc_recycle_frame_loop_059e
.L_tc_recycle_frame_done_059e:
	lea rsp, [rbx + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
.L_if_end_032c:
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_044f:	; new closure is in rax
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; old return address
	push qword [rbp]	; old frame-pointer
	mov rcx, 5
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8]
.L_tc_recycle_frame_loop_059f:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_059f
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8
	sub rdx, 8
	jmp .L_tc_recycle_frame_loop_059f
.L_tc_recycle_frame_done_059f:
	lea rsp, [rbx + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_044e:	; new closure is in rax
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_044b:	; new closure is in rax
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	mov qword [free_var_175], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void

	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 0	; new rib
	call malloc
	push rax
	mov rdi, 8 * 1	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_0450:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_0450
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0450
.L_lambda_simple_env_end_0450:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0450:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_0450
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0450
.L_lambda_simple_params_end_0450:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0450
	jmp .L_lambda_simple_end_0450
.L_lambda_simple_code_0450:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 2
	je .L_lambda_simple_arity_check_ok_0450
	push qword [rsp + 8 * 2]
	push 2
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0450:
	enter 0, 0
	; preparing a tail-call
	mov rax, L_constants + 2335
	push rax
	push 1	; arg count
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 2	; new rib
	call malloc
	push rax
	mov rdi, 8 * 2	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_0451:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
	je .L_lambda_simple_env_end_0451
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0451
.L_lambda_simple_env_end_0451:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0451:	; copy params
	cmp rsi, 2
	je .L_lambda_simple_params_end_0451
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0451
.L_lambda_simple_params_end_0451:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0451
	jmp .L_lambda_simple_end_0451
.L_lambda_simple_code_0451:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0451
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0451:
	enter 0, 0

	mov rdi, 8
	call malloc
	mov rbx, PARAM(0)	; param run
	mov [rax], rbx	; box run
	mov PARAM(0), rax	; replace param with box
	mov rax, sob_void

	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 1	; new rib
	call malloc
	push rax
	mov rdi, 8 * 3	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_0452:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 2
	je .L_lambda_simple_env_end_0452
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0452
.L_lambda_simple_env_end_0452:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0452:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_0452
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0452
.L_lambda_simple_params_end_0452:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0452
	jmp .L_lambda_simple_end_0452
.L_lambda_simple_code_0452:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0452
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0452:
	enter 0, 0
	; preparing a non-tail-call
	mov rax, ENV
	mov rax, qword [rax + 8 * 1]
	mov rax, qword [rax + 8 * 0]	; bound var n
	push rax
	mov rax, PARAM(0)	; param i
	push rax
	push 2	; arg count
	mov rax, qword [free_var_4]	; free var <
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_032d
	; preparing a tail-call
	; preparing a non-tail-call
	; preparing a non-tail-call
	mov rax, L_constants + 2810
	push rax
	mov rax, PARAM(0)	; param i
	push rax
	push 2	; arg count
	mov rax, qword [free_var_1]	; free var +
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 1	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var run
	mov rax, qword [rax]
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param i
	push rax
	push 1	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 1]
	mov rax, qword [rax + 8 * 1]	; bound var thunk
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 2	; arg count
	mov rax, qword [free_var_85]	; free var cons
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; old return address
	push qword [rbp]	; old frame-pointer
	mov rcx, 6
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8]
.L_tc_recycle_frame_loop_05a0:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_05a0
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8
	sub rdx, 8
	jmp .L_tc_recycle_frame_loop_05a0
.L_tc_recycle_frame_done_05a0:
	lea rsp, [rbx + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_032d
.L_if_else_032d:
	mov rax, L_constants + 1
.L_if_end_032d:
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0452:	; new closure is in rax

	push rax
	mov rax, PARAM(0)	; param run

	pop qword[rax]
	mov rax, sob_void

	; preparing a tail-call
	mov rax, L_constants + 2558
	push rax
	push 1	; arg count
	mov rax, PARAM(0)	; param run
	mov rax, qword [rax]
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; old return address
	push qword [rbp]	; old frame-pointer
	mov rcx, 5
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8]
.L_tc_recycle_frame_loop_05a1:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_05a1
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8
	sub rdx, 8
	jmp .L_tc_recycle_frame_loop_05a1
.L_tc_recycle_frame_done_05a1:
	lea rsp, [rbx + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0451:	; new closure is in rax
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; old return address
	push qword [rbp]	; old frame-pointer
	mov rcx, 5
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8]
.L_tc_recycle_frame_loop_05a2:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_05a2
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8
	sub rdx, 8
	jmp .L_tc_recycle_frame_loop_05a2
.L_tc_recycle_frame_done_05a2:
	lea rsp, [rbx + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_simple_end_0450:	; new closure is in rax
	mov qword [free_var_117], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void

	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 0	; new rib
	call malloc
	push rax
	mov rdi, 8 * 1	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_0453:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_0453
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0453
.L_lambda_simple_env_end_0453:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0453:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_0453
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0453
.L_lambda_simple_params_end_0453:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0453
	jmp .L_lambda_simple_end_0453
.L_lambda_simple_code_0453:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 2
	je .L_lambda_simple_arity_check_ok_0453
	push qword [rsp + 8 * 2]
	push 2
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0453:
	enter 0, 0
	; preparing a tail-call
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param n
	push rax
	push 1	; arg count
	mov rax, qword [free_var_118]	; free var make-string
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 1	; arg count
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 2	; new rib
	call malloc
	push rax
	mov rdi, 8 * 2	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_0454:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
	je .L_lambda_simple_env_end_0454
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0454
.L_lambda_simple_env_end_0454:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0454:	; copy params
	cmp rsi, 2
	je .L_lambda_simple_params_end_0454
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0454
.L_lambda_simple_params_end_0454:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0454
	jmp .L_lambda_simple_end_0454
.L_lambda_simple_code_0454:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0454
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0454:
	enter 0, 0
	; preparing a tail-call
	mov rax, L_constants + 2335
	push rax
	push 1	; arg count
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 1	; new rib
	call malloc
	push rax
	mov rdi, 8 * 3	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_0455:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 2
	je .L_lambda_simple_env_end_0455
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0455
.L_lambda_simple_env_end_0455:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0455:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_0455
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0455
.L_lambda_simple_params_end_0455:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0455
	jmp .L_lambda_simple_end_0455
.L_lambda_simple_code_0455:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0455
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0455:
	enter 0, 0

	mov rdi, 8
	call malloc
	mov rbx, PARAM(0)	; param run
	mov [rax], rbx	; box run
	mov PARAM(0), rax	; replace param with box
	mov rax, sob_void

	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 1	; new rib
	call malloc
	push rax
	mov rdi, 8 * 4	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_0456:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 3
	je .L_lambda_simple_env_end_0456
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0456
.L_lambda_simple_env_end_0456:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0456:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_0456
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0456
.L_lambda_simple_params_end_0456:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0456
	jmp .L_lambda_simple_end_0456
.L_lambda_simple_code_0456:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0456
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0456:
	enter 0, 0
	; preparing a non-tail-call
	mov rax, ENV
	mov rax, qword [rax + 8 * 2]
	mov rax, qword [rax + 8 * 0]	; bound var n
	push rax
	mov rax, PARAM(0)	; param i
	push rax
	push 2	; arg count
	mov rax, qword [free_var_4]	; free var <
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_032e
	; preparing a non-tail-call
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param i
	push rax
	push 1	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 2]
	mov rax, qword [rax + 8 * 1]	; bound var thunk
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	mov rax, PARAM(0)	; param i
	push rax
	mov rax, ENV
	mov rax, qword [rax + 8 * 1]
	mov rax, qword [rax + 8 * 0]	; bound var str
	push rax
	push 3	; arg count
	mov rax, qword [free_var_158]	; free var string-set!
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)

	; preparing a tail-call
	; preparing a non-tail-call
	mov rax, L_constants + 2810
	push rax
	mov rax, PARAM(0)	; param i
	push rax
	push 2	; arg count
	mov rax, qword [free_var_1]	; free var +
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 1	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var run
	mov rax, qword [rax]
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; old return address
	push qword [rbp]	; old frame-pointer
	mov rcx, 5
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8]
.L_tc_recycle_frame_loop_05a3:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_05a3
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8
	sub rdx, 8
	jmp .L_tc_recycle_frame_loop_05a3
.L_tc_recycle_frame_done_05a3:
	lea rsp, [rbx + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_032e
.L_if_else_032e:
	mov rax, ENV
	mov rax, qword [rax + 8 * 1]
	mov rax, qword [rax + 8 * 0]	; bound var str
.L_if_end_032e:
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0456:	; new closure is in rax

	push rax
	mov rax, PARAM(0)	; param run

	pop qword[rax]
	mov rax, sob_void

	; preparing a tail-call
	mov rax, L_constants + 2558
	push rax
	push 1	; arg count
	mov rax, PARAM(0)	; param run
	mov rax, qword [rax]
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; old return address
	push qword [rbp]	; old frame-pointer
	mov rcx, 5
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8]
.L_tc_recycle_frame_loop_05a4:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_05a4
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8
	sub rdx, 8
	jmp .L_tc_recycle_frame_loop_05a4
.L_tc_recycle_frame_done_05a4:
	lea rsp, [rbx + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0455:	; new closure is in rax
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; old return address
	push qword [rbp]	; old frame-pointer
	mov rcx, 5
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8]
.L_tc_recycle_frame_loop_05a5:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_05a5
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8
	sub rdx, 8
	jmp .L_tc_recycle_frame_loop_05a5
.L_tc_recycle_frame_done_05a5:
	lea rsp, [rbx + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0454:	; new closure is in rax
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; old return address
	push qword [rbp]	; old frame-pointer
	mov rcx, 5
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8]
.L_tc_recycle_frame_loop_05a6:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_05a6
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8
	sub rdx, 8
	jmp .L_tc_recycle_frame_loop_05a6
.L_tc_recycle_frame_done_05a6:
	lea rsp, [rbx + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_simple_end_0453:	; new closure is in rax
	mov qword [free_var_119], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void

	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 0	; new rib
	call malloc
	push rax
	mov rdi, 8 * 1	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_0457:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_0457
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0457
.L_lambda_simple_env_end_0457:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0457:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_0457
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0457
.L_lambda_simple_params_end_0457:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0457
	jmp .L_lambda_simple_end_0457
.L_lambda_simple_code_0457:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 2
	je .L_lambda_simple_arity_check_ok_0457
	push qword [rsp + 8 * 2]
	push 2
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0457:
	enter 0, 0
	; preparing a tail-call
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param n
	push rax
	push 1	; arg count
	mov rax, qword [free_var_120]	; free var make-vector
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 1	; arg count
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 2	; new rib
	call malloc
	push rax
	mov rdi, 8 * 2	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_0458:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
	je .L_lambda_simple_env_end_0458
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0458
.L_lambda_simple_env_end_0458:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0458:	; copy params
	cmp rsi, 2
	je .L_lambda_simple_params_end_0458
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0458
.L_lambda_simple_params_end_0458:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0458
	jmp .L_lambda_simple_end_0458
.L_lambda_simple_code_0458:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0458
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0458:
	enter 0, 0
	; preparing a tail-call
	mov rax, L_constants + 2335
	push rax
	push 1	; arg count
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 1	; new rib
	call malloc
	push rax
	mov rdi, 8 * 3	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_0459:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 2
	je .L_lambda_simple_env_end_0459
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0459
.L_lambda_simple_env_end_0459:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0459:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_0459
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0459
.L_lambda_simple_params_end_0459:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0459
	jmp .L_lambda_simple_end_0459
.L_lambda_simple_code_0459:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0459
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0459:
	enter 0, 0

	mov rdi, 8
	call malloc
	mov rbx, PARAM(0)	; param run
	mov [rax], rbx	; box run
	mov PARAM(0), rax	; replace param with box
	mov rax, sob_void

	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 1	; new rib
	call malloc
	push rax
	mov rdi, 8 * 4	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_045a:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 3
	je .L_lambda_simple_env_end_045a
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_045a
.L_lambda_simple_env_end_045a:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_045a:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_045a
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_045a
.L_lambda_simple_params_end_045a:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_045a
	jmp .L_lambda_simple_end_045a
.L_lambda_simple_code_045a:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_045a
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_045a:
	enter 0, 0
	; preparing a non-tail-call
	mov rax, ENV
	mov rax, qword [rax + 8 * 2]
	mov rax, qword [rax + 8 * 0]	; bound var n
	push rax
	mov rax, PARAM(0)	; param i
	push rax
	push 2	; arg count
	mov rax, qword [free_var_4]	; free var <
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_032f
	; preparing a non-tail-call
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param i
	push rax
	push 1	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 2]
	mov rax, qword [rax + 8 * 1]	; bound var thunk
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	mov rax, PARAM(0)	; param i
	push rax
	mov rax, ENV
	mov rax, qword [rax + 8 * 1]
	mov rax, qword [rax + 8 * 0]	; bound var vec
	push rax
	push 3	; arg count
	mov rax, qword [free_var_176]	; free var vector-set!
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)

	; preparing a tail-call
	; preparing a non-tail-call
	mov rax, L_constants + 2810
	push rax
	mov rax, PARAM(0)	; param i
	push rax
	push 2	; arg count
	mov rax, qword [free_var_1]	; free var +
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 1	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var run
	mov rax, qword [rax]
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; old return address
	push qword [rbp]	; old frame-pointer
	mov rcx, 5
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8]
.L_tc_recycle_frame_loop_05a7:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_05a7
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8
	sub rdx, 8
	jmp .L_tc_recycle_frame_loop_05a7
.L_tc_recycle_frame_done_05a7:
	lea rsp, [rbx + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_032f
.L_if_else_032f:
	mov rax, ENV
	mov rax, qword [rax + 8 * 1]
	mov rax, qword [rax + 8 * 0]	; bound var vec
.L_if_end_032f:
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_045a:	; new closure is in rax

	push rax
	mov rax, PARAM(0)	; param run

	pop qword[rax]
	mov rax, sob_void

	; preparing a tail-call
	mov rax, L_constants + 2558
	push rax
	push 1	; arg count
	mov rax, PARAM(0)	; param run
	mov rax, qword [rax]
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; old return address
	push qword [rbp]	; old frame-pointer
	mov rcx, 5
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8]
.L_tc_recycle_frame_loop_05a8:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_05a8
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8
	sub rdx, 8
	jmp .L_tc_recycle_frame_loop_05a8
.L_tc_recycle_frame_done_05a8:
	lea rsp, [rbx + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0459:	; new closure is in rax
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; old return address
	push qword [rbp]	; old frame-pointer
	mov rcx, 5
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8]
.L_tc_recycle_frame_loop_05a9:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_05a9
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8
	sub rdx, 8
	jmp .L_tc_recycle_frame_loop_05a9
.L_tc_recycle_frame_done_05a9:
	lea rsp, [rbx + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0458:	; new closure is in rax
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; old return address
	push qword [rbp]	; old frame-pointer
	mov rcx, 5
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8]
.L_tc_recycle_frame_loop_05aa:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_05aa
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8
	sub rdx, 8
	jmp .L_tc_recycle_frame_loop_05aa
.L_tc_recycle_frame_done_05aa:
	lea rsp, [rbx + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_simple_end_0457:	; new closure is in rax
	mov qword [free_var_121], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void

	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 0	; new rib
	call malloc
	push rax
	mov rdi, 8 * 1	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_045b:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_045b
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_045b
.L_lambda_simple_env_end_045b:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_045b:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_045b
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_045b
.L_lambda_simple_params_end_045b:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_045b
	jmp .L_lambda_simple_end_045b
.L_lambda_simple_code_045b:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 3
	je .L_lambda_simple_arity_check_ok_045b
	push qword [rsp + 8 * 2]
	push 3
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_045b:
	enter 0, 0
	; preparing a non-tail-call
	mov rax, PARAM(2)	; param n
	push rax
	push 1	; arg count
	mov rax, qword [free_var_181]	; free var zero?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_0332
	mov rax, L_constants + 4754
	jmp .L_if_end_0332
.L_if_else_0332:
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param b
	push rax
	mov rax, PARAM(0)	; param a
	push rax
	push 2	; arg count
	mov rax, qword [free_var_4]	; free var <
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_0331
	; preparing a tail-call
	; preparing a non-tail-call
	mov rax, PARAM(2)	; param n
	push rax
	; preparing a non-tail-call
	mov rax, PARAM(0)	; param a
	push rax
	mov rax, PARAM(1)	; param b
	push rax
	push 2	; arg count
	mov rax, qword [free_var_3]	; free var /
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	mov rax, PARAM(0)	; param a
	push rax
	push 3	; arg count
	mov rax, qword [free_var_112]	; free var logarithm
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	mov rax, L_constants + 4754
	push rax
	push 2	; arg count
	mov rax, qword [free_var_1]	; free var +
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; old return address
	push qword [rbp]	; old frame-pointer
	mov rcx, 6
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8]
.L_tc_recycle_frame_loop_05ab:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_05ab
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8
	sub rdx, 8
	jmp .L_tc_recycle_frame_loop_05ab
.L_tc_recycle_frame_done_05ab:
	lea rsp, [rbx + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_0331
.L_if_else_0331:
	; preparing a non-tail-call
	mov rax, PARAM(1)	; param b
	push rax
	mov rax, PARAM(0)	; param a
	push rax
	push 2	; arg count
	mov rax, qword [free_var_6]	; free var =
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_0330
	mov rax, L_constants + 4754
	jmp .L_if_end_0330
.L_if_else_0330:
	; preparing a tail-call
	; preparing a non-tail-call
	; preparing a non-tail-call
	mov rax, L_constants + 2810
	push rax
	mov rax, PARAM(2)	; param n
	push rax
	push 2	; arg count
	mov rax, qword [free_var_2]	; free var -
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	mov rax, PARAM(0)	; param a
	push rax
	mov rax, PARAM(1)	; param b
	push rax
	push 3	; arg count
	mov rax, qword [free_var_112]	; free var logarithm
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	mov rax, L_constants + 4754
	push rax
	push 2	; arg count
	mov rax, qword [free_var_3]	; free var /
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; old return address
	push qword [rbp]	; old frame-pointer
	mov rcx, 6
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8]
.L_tc_recycle_frame_loop_05ac:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_05ac
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8
	sub rdx, 8
	jmp .L_tc_recycle_frame_loop_05ac
.L_tc_recycle_frame_done_05ac:
	lea rsp, [rbx + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
.L_if_end_0330:
.L_if_end_0331:
.L_if_end_0332:
	leave
	ret AND_KILL_FRAME(3)
.L_lambda_simple_end_045b:	; new closure is in rax
	mov qword [free_var_112], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void

	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 0	; new rib
	call malloc
	push rax
	mov rdi, 8 * 1	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_045c:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_045c
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_045c
.L_lambda_simple_env_end_045c:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_045c:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_045c
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_045c
.L_lambda_simple_params_end_045c:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_045c
	jmp .L_lambda_simple_end_045c
.L_lambda_simple_code_045c:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 0
	je .L_lambda_simple_arity_check_ok_045c
	push qword [rsp + 8 * 2]
	push 0
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_045c:
	enter 0, 0
	; preparing a tail-call
	mov rax, L_constants + 4797
	push rax
	push 1	; arg count
	mov rax, qword [free_var_180]	; free var write-char
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; old return address
	push qword [rbp]	; old frame-pointer
	mov rcx, 5
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8]
.L_tc_recycle_frame_loop_05ad:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_05ad
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8
	sub rdx, 8
	jmp .L_tc_recycle_frame_loop_05ad
.L_tc_recycle_frame_done_05ad:
	lea rsp, [rbx + 8]
	pop rbp
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(0)
.L_lambda_simple_end_045c:	; new closure is in rax
	mov qword [free_var_124], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void

	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 0	; new rib
	call malloc
	push rax
	mov rdi, 8 * 1	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_045d:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_045d
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_045d
.L_lambda_simple_env_end_045d:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_045d:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_045d
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_045d
.L_lambda_simple_params_end_045d:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_045d
	jmp .L_lambda_simple_end_045d
.L_lambda_simple_code_045d:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 0
	je .L_lambda_simple_arity_check_ok_045d
	push qword [rsp + 8 * 2]
	push 0
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_045d:
	enter 0, 0
	mov rax, L_constants + 0
	leave
	ret AND_KILL_FRAME(0)
.L_lambda_simple_end_045d:	; new closure is in rax
	mov qword [free_var_178], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void

	; preparing a non-tail-call
	mov rax, L_constants + 4821
	push rax
	; preparing a non-tail-call
	mov rax, L_constants + 4288
	push rax
	mov rax, L_constants + 2810
	push rax
	push 2	; arg count
	mov rax, qword [free_var_1]	; free var +
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 2	; arg count
	mov rax, qword [free_var_0]	; free var *
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)

	mov rdi, rax
	call print_sexpr_if_not_void

        mov rdi, fmt_memory_usage
        mov rsi, qword [top_of_memory]
        sub rsi, memory
        mov rax, 0
        ENTER
        call printf
        LEAVE
        mov rax, 0
        call exit

L_error_fvar_undefined:
        push rax
        mov rdi, qword [stderr]  ; destination
        mov rsi, fmt_undefined_free_var_1
        mov rax, 0
        ENTER
        call fprintf
        LEAVE
        pop rax
        mov rax, qword [rax + 1] ; string
        lea rdi, [rax + 1 + 8]   ; actual characters
        mov rsi, 1               ; sizeof(char)
        mov rdx, qword [rax + 1] ; string-length
        mov rcx, qword [stderr]  ; destination
        mov rax, 0
        ENTER
        call fwrite
        LEAVE
        mov rdi, [stderr]       ; destination
        mov rsi, fmt_undefined_free_var_2
        mov rax, 0
        ENTER
        call fprintf
        LEAVE
        mov rax, -10
        call exit

L_error_non_closure:
        mov rdi, qword [stderr]
        mov rsi, fmt_non_closure
        mov rax, 0
        ENTER
        call fprintf
        LEAVE
        mov rax, -2
        call exit

L_error_improper_list:
	mov rdi, qword [stderr]
	mov rsi, fmt_error_improper_list
	mov rax, 0
        ENTER
	call fprintf
        LEAVE
	mov rax, -7
	call exit

L_error_incorrect_arity_simple:
        mov rdi, qword [stderr]
        mov rsi, fmt_incorrect_arity_simple
        jmp L_error_incorrect_arity_common
L_error_incorrect_arity_opt:
        mov rdi, qword [stderr]
        mov rsi, fmt_incorrect_arity_opt
L_error_incorrect_arity_common:
        pop rdx
        pop rcx
        mov rax, 0
        ENTER
        call fprintf
        LEAVE
        mov rax, -6
        call exit

section .data
fmt_undefined_free_var_1:
        db `!!! The free variable \0`
fmt_undefined_free_var_2:
        db ` was used before it was defined.\n\0`
fmt_incorrect_arity_simple:
        db `!!! Expected %ld arguments, but given %ld\n\0`
fmt_incorrect_arity_opt:
        db `!!! Expected at least %ld arguments, but given %ld\n\0`
fmt_memory_usage:
        db `\n!!! Used %ld bytes of dynamically-allocated memory\n\n\0`
fmt_non_closure:
        db `!!! Attempting to apply a non-closure!\n\0`
fmt_error_improper_list:
	db `!!! The argument is not a proper list!\n\0`

section .bss
memory:
	resb gbytes(1)

section .data
top_of_memory:
        dq memory

section .text
malloc:
        mov rax, qword [top_of_memory]
        add qword [top_of_memory], rdi
        ret

L_code_ptr_return:
	cmp qword [rsp + 8*2], 2
	jne L_error_arg_count_2
	mov rcx, qword [rsp + 8*3]
	assert_integer(rcx)
	mov rcx, qword [rcx + 1]
	cmp rcx, 0
	jl L_error_integer_range
	mov rax, qword [rsp + 8*4]
.L0:
        cmp rcx, 0
        je .L1
	mov rbp, qword [rbp]
	dec rcx
	jg .L0
.L1:
	mov rsp, rbp
	pop rbp
        pop rbx
        mov rcx, qword [rsp + 8*1]
        lea rsp, [rsp + 8*rcx + 8*2]
	jmp rbx

L_code_ptr_make_list:
	enter 0, 0
        cmp COUNT, 1
        je .L0
        cmp COUNT, 2
        je .L1
        jmp L_error_arg_count_12
.L0:
        mov r9, sob_void
        jmp .L2
.L1:
        mov r9, PARAM(1)
.L2:
        mov rcx, PARAM(0)
        assert_integer(rcx)
        mov rcx, qword [rcx + 1]
        cmp rcx, 0
        jl L_error_arg_negative
        mov r8, sob_nil
.L3:
        cmp rcx, 0
        jle .L4
        mov rdi, 1 + 8 + 8
        call malloc
        mov byte [rax], T_pair
        mov qword [rax + 1], r9
        mov qword [rax + 1 + 8], r8
        mov r8, rax
        dec rcx
        jmp .L3
.L4:
        mov rax, r8
        cmp COUNT, 2
        je .L5
        leave
        ret AND_KILL_FRAME(1)
.L5:
	leave
	ret AND_KILL_FRAME(2)

L_code_ptr_is_primitive:
	enter 0, 0
	cmp COUNT, 1
	jne L_error_arg_count_1
	mov rax, PARAM(0)
	assert_closure(rax)
	cmp SOB_CLOSURE_ENV(rax), 0
	jne .L_false
	mov rax, sob_boolean_true
	jmp .L_end
.L_false:
	mov rax, sob_boolean_false
.L_end:
	leave
	ret AND_KILL_FRAME(1)

L_code_ptr_length:
	enter 0, 0
	cmp COUNT, 1
	jne L_error_arg_count_1
	mov rbx, PARAM(0)
	mov rdi, 0
.L:
	cmp byte [rbx], T_nil
	je .L_end
	assert_pair(rbx)
	mov rbx, SOB_PAIR_CDR(rbx)
	inc rdi
	jmp .L
.L_end:
	call make_integer
	leave
	ret AND_KILL_FRAME(1)

L_code_ptr_break:
        cmp qword [rsp + 8 * 2], 0
        jne L_error_arg_count_0
        int3
        mov rax, sob_void
        ret AND_KILL_FRAME(0)        

L_code_ptr_frame:
        enter 0, 0
        cmp COUNT, 0
        jne L_error_arg_count_0

        mov rdi, fmt_frame
        mov rsi, qword [rbp]    ; old rbp
        mov rdx, qword [rsi + 8*1] ; ret addr
        mov rcx, qword [rsi + 8*2] ; lexical environment
        mov r8, qword [rsi + 8*3] ; count
        lea r9, [rsi + 8*4]       ; address of argument 0
        push 0
        push r9
        push r8                   ; we'll use it when printing the params
        mov rax, 0
        
        ENTER
        call printf
        LEAVE

.L:
        mov rcx, qword [rsp]
        cmp rcx, 0
        je .L_out
        mov rdi, fmt_frame_param_prefix
        mov rsi, qword [rsp + 8*2]
        mov rax, 0
        
        ENTER
        call printf
        LEAVE

        mov rcx, qword [rsp]
        dec rcx
        mov qword [rsp], rcx    ; dec arg count
        inc qword [rsp + 8*2]   ; increment index of current arg
        mov rdi, qword [rsp + 8*1] ; addr of addr current arg
        lea r9, [rdi + 8]          ; addr of next arg
        mov qword [rsp + 8*1], r9  ; backup addr of next arg
        mov rdi, qword [rdi]       ; addr of current arg
        call print_sexpr
        mov rdi, fmt_newline
        mov rax, 0
        ENTER
        call printf
        LEAVE
        jmp .L
.L_out:
        mov rdi, fmt_frame_continue
        mov rax, 0
        ENTER
        call printf
        call getchar
        LEAVE
        
        mov rax, sob_void
        leave
        ret AND_KILL_FRAME(0)
        
print_sexpr_if_not_void:
	cmp rdi, sob_void
	je .done
	call print_sexpr
	mov rdi, fmt_newline
	mov rax, 0
	ENTER
	call printf
	LEAVE
.done:
	ret

section .data
fmt_frame:
        db `RBP = %p; ret addr = %p; lex env = %p; param count = %d\n\0`
fmt_frame_param_prefix:
        db `==[param %d]==> \0`
fmt_frame_continue:
        db `Hit <Enter> to continue...\0`
fmt_newline:
	db `\n\0`
fmt_void:
	db `#<void>\0`
fmt_nil:
	db `()\0`
fmt_boolean_false:
	db `#f\0`
fmt_boolean_true:
	db `#t\0`
fmt_char_backslash:
	db `#\\\\\0`
fmt_char_dquote:
	db `#\\"\0`
fmt_char_simple:
	db `#\\%c\0`
fmt_char_null:
	db `#\\nul\0`
fmt_char_bell:
	db `#\\bell\0`
fmt_char_backspace:
	db `#\\backspace\0`
fmt_char_tab:
	db `#\\tab\0`
fmt_char_newline:
	db `#\\newline\0`
fmt_char_formfeed:
	db `#\\page\0`
fmt_char_return:
	db `#\\return\0`
fmt_char_escape:
	db `#\\esc\0`
fmt_char_space:
	db `#\\space\0`
fmt_char_hex:
	db `#\\x%02X\0`
fmt_gensym:
        db `G%ld\0`
fmt_closure:
	db `#<closure at 0x%08X env=0x%08X code=0x%08X>\0`
fmt_lparen:
	db `(\0`
fmt_dotted_pair:
	db ` . \0`
fmt_rparen:
	db `)\0`
fmt_space:
	db ` \0`
fmt_empty_vector:
	db `#()\0`
fmt_vector:
	db `#(\0`
fmt_real:
	db `%f\0`
fmt_fraction:
	db `%ld/%ld\0`
fmt_zero:
	db `0\0`
fmt_int:
	db `%ld\0`
fmt_unknown_scheme_object_error:
	db `\n\n!!! Error: Unknown Scheme-object (RTTI 0x%02X) `
	db `at address 0x%08X\n\n\0`
fmt_dquote:
	db `\"\0`
fmt_string_char:
        db `%c\0`
fmt_string_char_7:
        db `\\a\0`
fmt_string_char_8:
        db `\\b\0`
fmt_string_char_9:
        db `\\t\0`
fmt_string_char_10:
        db `\\n\0`
fmt_string_char_11:
        db `\\v\0`
fmt_string_char_12:
        db `\\f\0`
fmt_string_char_13:
        db `\\r\0`
fmt_string_char_34:
        db `\\"\0`
fmt_string_char_92:
        db `\\\\\0`
fmt_string_char_hex:
        db `\\x%X;\0`

section .text

print_sexpr:
	enter 0, 0
	mov al, byte [rdi]
	cmp al, T_void
	je .Lvoid
	cmp al, T_nil
	je .Lnil
	cmp al, T_boolean_false
	je .Lboolean_false
	cmp al, T_boolean_true
	je .Lboolean_true
	cmp al, T_char
	je .Lchar
	cmp al, T_interned_symbol
	je .Linterned_symbol
        cmp al, T_uninterned_symbol
        je .Luninterned_symbol
	cmp al, T_pair
	je .Lpair
	cmp al, T_vector
	je .Lvector
	cmp al, T_closure
	je .Lclosure
	cmp al, T_real
	je .Lreal
	cmp al, T_fraction
	je .Lfraction
	cmp al, T_integer
	je .Linteger
	cmp al, T_string
	je .Lstring

	jmp .Lunknown_sexpr_type

.Lvoid:
	mov rdi, fmt_void
	jmp .Lemit

.Lnil:
	mov rdi, fmt_nil
	jmp .Lemit

.Lboolean_false:
	mov rdi, fmt_boolean_false
	jmp .Lemit

.Lboolean_true:
	mov rdi, fmt_boolean_true
	jmp .Lemit

.Lchar:
	mov al, byte [rdi + 1]
	cmp al, ' '
	jle .Lchar_whitespace
	cmp al, 92 		; backslash
	je .Lchar_backslash
	cmp al, '"'
	je .Lchar_dquote
	and rax, 255
	mov rdi, fmt_char_simple
	mov rsi, rax
	jmp .Lemit

.Lchar_whitespace:
	cmp al, 0
	je .Lchar_null
	cmp al, 7
	je .Lchar_bell
	cmp al, 8
	je .Lchar_backspace
	cmp al, 9
	je .Lchar_tab
	cmp al, 10
	je .Lchar_newline
	cmp al, 12
	je .Lchar_formfeed
	cmp al, 13
	je .Lchar_return
	cmp al, 27
	je .Lchar_escape
	and rax, 255
	cmp al, ' '
	je .Lchar_space
	mov rdi, fmt_char_hex
	mov rsi, rax
	jmp .Lemit	

.Lchar_backslash:
	mov rdi, fmt_char_backslash
	jmp .Lemit

.Lchar_dquote:
	mov rdi, fmt_char_dquote
	jmp .Lemit

.Lchar_null:
	mov rdi, fmt_char_null
	jmp .Lemit

.Lchar_bell:
	mov rdi, fmt_char_bell
	jmp .Lemit

.Lchar_backspace:
	mov rdi, fmt_char_backspace
	jmp .Lemit

.Lchar_tab:
	mov rdi, fmt_char_tab
	jmp .Lemit

.Lchar_newline:
	mov rdi, fmt_char_newline
	jmp .Lemit

.Lchar_formfeed:
	mov rdi, fmt_char_formfeed
	jmp .Lemit

.Lchar_return:
	mov rdi, fmt_char_return
	jmp .Lemit

.Lchar_escape:
	mov rdi, fmt_char_escape
	jmp .Lemit

.Lchar_space:
	mov rdi, fmt_char_space
	jmp .Lemit

.Lclosure:
	mov rsi, qword rdi
	mov rdi, fmt_closure
	mov rdx, SOB_CLOSURE_ENV(rsi)
	mov rcx, SOB_CLOSURE_CODE(rsi)
	jmp .Lemit

.Linterned_symbol:
	mov rdi, qword [rdi + 1] ; sob_string
	mov rsi, 1		 ; size = 1 byte
	mov rdx, qword [rdi + 1] ; length
	lea rdi, [rdi + 1 + 8]	 ; actual characters
	mov rcx, qword [stdout]	 ; FILE *
	ENTER
	call fwrite
	LEAVE
	jmp .Lend

.Luninterned_symbol:
        mov rsi, qword [rdi + 1] ; gensym counter
        mov rdi, fmt_gensym
        jmp .Lemit
	
.Lpair:
	push rdi
	mov rdi, fmt_lparen
	mov rax, 0
        ENTER
	call printf
        LEAVE
	mov rdi, qword [rsp] 	; pair
	mov rdi, SOB_PAIR_CAR(rdi)
	call print_sexpr
	pop rdi 		; pair
	mov rdi, SOB_PAIR_CDR(rdi)
.Lcdr:
	mov al, byte [rdi]
	cmp al, T_nil
	je .Lcdr_nil
	cmp al, T_pair
	je .Lcdr_pair
	push rdi
	mov rdi, fmt_dotted_pair
	mov rax, 0
        ENTER
	call printf
        LEAVE
	pop rdi
	call print_sexpr
	mov rdi, fmt_rparen
	mov rax, 0
        ENTER
	call printf
        LEAVE
	leave
	ret

.Lcdr_nil:
	mov rdi, fmt_rparen
	mov rax, 0
        ENTER
	call printf
        LEAVE
	leave
	ret

.Lcdr_pair:
	push rdi
	mov rdi, fmt_space
	mov rax, 0
        ENTER
	call printf
        LEAVE
	mov rdi, qword [rsp]
	mov rdi, SOB_PAIR_CAR(rdi)
	call print_sexpr
	pop rdi
	mov rdi, SOB_PAIR_CDR(rdi)
	jmp .Lcdr

.Lvector:
	mov rax, qword [rdi + 1] ; length
	cmp rax, 0
	je .Lvector_empty
	push rdi
	mov rdi, fmt_vector
	mov rax, 0
        ENTER
	call printf
        LEAVE
	mov rdi, qword [rsp]
	push qword [rdi + 1]
	push 1
	mov rdi, qword [rdi + 1 + 8] ; v[0]
	call print_sexpr
.Lvector_loop:
	; [rsp] index
	; [rsp + 8*1] limit
	; [rsp + 8*2] vector
	mov rax, qword [rsp]
	cmp rax, qword [rsp + 8*1]
	je .Lvector_end
	mov rdi, fmt_space
	mov rax, 0
        ENTER
	call printf
        LEAVE
	mov rax, qword [rsp]
	mov rbx, qword [rsp + 8*2]
	mov rdi, qword [rbx + 1 + 8 + 8 * rax] ; v[i]
	call print_sexpr
	inc qword [rsp]
	jmp .Lvector_loop

.Lvector_end:
	add rsp, 8*3
	mov rdi, fmt_rparen
	jmp .Lemit	

.Lvector_empty:
	mov rdi, fmt_empty_vector
	jmp .Lemit

.Lreal:
	push qword [rdi + 1]
	movsd xmm0, qword [rsp]
	add rsp, 8*1
	mov rdi, fmt_real
	mov rax, 1
	ENTER
	call printf
	LEAVE
	jmp .Lend

.Lfraction:
	mov rsi, qword [rdi + 1]
	mov rdx, qword [rdi + 1 + 8]
	cmp rsi, 0
	je .Lrat_zero
	cmp rdx, 1
	je .Lrat_int
	mov rdi, fmt_fraction
	jmp .Lemit

.Lrat_zero:
	mov rdi, fmt_zero
	jmp .Lemit

.Lrat_int:
	mov rdi, fmt_int
	jmp .Lemit

.Linteger:
	mov rsi, qword [rdi + 1]
	mov rdi, fmt_int
	jmp .Lemit

.Lstring:
	lea rax, [rdi + 1 + 8]
	push rax
	push qword [rdi + 1]
	mov rdi, fmt_dquote
	mov rax, 0
	ENTER
	call printf
	LEAVE
.Lstring_loop:
	; qword [rsp]: limit
	; qword [rsp + 8*1]: char *
	cmp qword [rsp], 0
	je .Lstring_end
	mov rax, qword [rsp + 8*1]
	mov al, byte [rax]
	and rax, 255
	cmp al, 7
        je .Lstring_char_7
        cmp al, 8
        je .Lstring_char_8
        cmp al, 9
        je .Lstring_char_9
        cmp al, 10
        je .Lstring_char_10
        cmp al, 11
        je .Lstring_char_11
        cmp al, 12
        je .Lstring_char_12
        cmp al, 13
        je .Lstring_char_13
        cmp al, 34
        je .Lstring_char_34
        cmp al, 92              ; \
        je .Lstring_char_92
        cmp al, ' '
        jl .Lstring_char_hex
        mov rdi, fmt_string_char
        mov rsi, rax
.Lstring_char_emit:
        mov rax, 0
        ENTER
        call printf
        LEAVE
        dec qword [rsp]
        inc qword [rsp + 8*1]
        jmp .Lstring_loop

.Lstring_char_7:
        mov rdi, fmt_string_char_7
        jmp .Lstring_char_emit

.Lstring_char_8:
        mov rdi, fmt_string_char_8
        jmp .Lstring_char_emit
        
.Lstring_char_9:
        mov rdi, fmt_string_char_9
        jmp .Lstring_char_emit

.Lstring_char_10:
        mov rdi, fmt_string_char_10
        jmp .Lstring_char_emit

.Lstring_char_11:
        mov rdi, fmt_string_char_11
        jmp .Lstring_char_emit

.Lstring_char_12:
        mov rdi, fmt_string_char_12
        jmp .Lstring_char_emit

.Lstring_char_13:
        mov rdi, fmt_string_char_13
        jmp .Lstring_char_emit

.Lstring_char_34:
        mov rdi, fmt_string_char_34
        jmp .Lstring_char_emit

.Lstring_char_92:
        mov rdi, fmt_string_char_92
        jmp .Lstring_char_emit

.Lstring_char_hex:
        mov rdi, fmt_string_char_hex
        mov rsi, rax
        jmp .Lstring_char_emit        

.Lstring_end:
	add rsp, 8 * 2
	mov rdi, fmt_dquote
	jmp .Lemit

.Lunknown_sexpr_type:
	mov rsi, fmt_unknown_scheme_object_error
	and rax, 255
	mov rdx, rax
	mov rcx, rdi
	mov rdi, qword [stderr]
	mov rax, 0
        ENTER
	call fprintf
        LEAVE
        leave
        ret

.Lemit:
	mov rax, 0
        ENTER
	call printf
        LEAVE
	jmp .Lend

.Lend:
	LEAVE
	ret

;;; rdi: address of free variable
;;; rsi: address of code-pointer
bind_primitive:
        enter 0, 0
        push rdi
        mov rdi, (1 + 8 + 8)
        call malloc
        pop rdi
        mov byte [rax], T_closure
        mov SOB_CLOSURE_ENV(rax), 0 ; dummy, lexical environment
        mov SOB_CLOSURE_CODE(rax), rsi ; code pointer
        mov qword [rdi], rax
        mov rax, sob_void
        leave
        ret

L_code_ptr_ash:
        enter 0, 0
        cmp COUNT, 2
        jne L_error_arg_count_2
        mov rdi, PARAM(0)
        assert_integer(rdi)
        mov rcx, PARAM(1)
        assert_integer(rcx)
        mov rdi, qword [rdi + 1]
        mov rcx, qword [rcx + 1]
        cmp rcx, 0
        jl .L_negative
.L_loop_positive:
        cmp rcx, 0
        je .L_exit
        sal rdi, cl
        shr rcx, 8
        jmp .L_loop_positive
.L_negative:
        neg rcx
.L_loop_negative:
        cmp rcx, 0
        je .L_exit
        sar rdi, cl
        shr rcx, 8
        jmp .L_loop_negative
.L_exit:
        call make_integer
        leave
        ret AND_KILL_FRAME(2)

L_code_ptr_logand:
        enter 0, 0
        cmp COUNT, 2
        jne L_error_arg_count_2
        mov r8, PARAM(0)
        assert_integer(r8)
        mov r9, PARAM(1)
        assert_integer(r9)
        mov rdi, qword [r8 + 1]
        and rdi, qword [r9 + 1]
        call make_integer
        leave
        ret AND_KILL_FRAME(2)

L_code_ptr_logor:
        enter 0, 0
        cmp COUNT, 2
        jne L_error_arg_count_2
        mov r8, PARAM(0)
        assert_integer(r8)
        mov r9, PARAM(1)
        assert_integer(r9)
        mov rdi, qword [r8 + 1]
        or rdi, qword [r9 + 1]
        call make_integer
        leave
        ret AND_KILL_FRAME(2)

L_code_ptr_logxor:
        enter 0, 0
        cmp COUNT, 2
        jne L_error_arg_count_2
        mov r8, PARAM(0)
        assert_integer(r8)
        mov r9, PARAM(1)
        assert_integer(r9)
        mov rdi, qword [r8 + 1]
        xor rdi, qword [r9 + 1]
        call make_integer
        LEAVE
        ret AND_KILL_FRAME(2)

L_code_ptr_lognot:
        enter 0, 0
        cmp COUNT, 1
        jne L_error_arg_count_1
        mov r8, PARAM(0)
        assert_integer(r8)
        mov rdi, qword [r8 + 1]
        not rdi
        call make_integer
        leave
        ret AND_KILL_FRAME(1)

L_code_ptr_bin_apply:
        ;; fill in for final project
        ;; Expect exactly two arguments
        cmp qword [rsp + 8 * 2], 2
        jne L_error_arg_count_2

        ;; Load the second argument, which must be a closure
        mov r12, qword [rsp + 8 * 3]
        assert_closure(r12)

        ;; r10 points to the portion of the stack that holds the list
        lea r10, [rsp + 8 * 4]
        mov r11, qword [r10]
        mov r9, qword [rsp]

        ;; Count how many elements are in the list
        mov rcx, 0
        mov rsi, r11
.count_loop:
        cmp rsi, sob_nil
        je .count_done
        assert_pair(rsi)
        inc rcx
        mov rsi, SOB_PAIR_CDR(rsi)
        jmp .count_loop

.count_done:
        ;; Allocate space on the stack for the new frame, minus the first 2 items
        lea rbx, [8 * (rcx - 2)]
        sub rsp, rbx

        ;; Prepare to store the new frame at [rsp]
        mov rdi, rsp
        cld

        ;; 1) Place the old return address
        mov rax, r9
        stosq

        ;; 2) Place the closure's environment
        mov rax, SOB_CLOSURE_ENV(r12)
        stosq

        ;; 3) Place the argument count
        mov rax, rcx
        stosq

.args_loop:
        cmp rcx, 0
        je .args_done
        mov rax, SOB_PAIR_CAR(r11)
        stosq
        mov r11, SOB_PAIR_CDR(r11)
        dec rcx
        jmp .args_loop

.args_done:
        ;; Minor pointer adjustment check
        sub rdi, 8
        cmp r10, rdi
        jne .stack_corrupt
        jmp SOB_CLOSURE_CODE(r12)

.stack_corrupt:
        int3

L_code_ptr_is_null:
        enter 0, 0
        cmp COUNT, 1
        jne L_error_arg_count_1
        mov rax, PARAM(0)
        cmp byte [rax], T_nil
        jne .L_false
        mov rax, sob_boolean_true
        jmp .L_end
.L_false:
        mov rax, sob_boolean_false
.L_end:
        leave
        ret AND_KILL_FRAME(1)

L_code_ptr_is_pair:
        enter 0, 0
        cmp COUNT, 1
        jne L_error_arg_count_1
        mov rax, PARAM(0)
        cmp byte [rax], T_pair
        jne .L_false
        mov rax, sob_boolean_true
        jmp .L_end
.L_false:
        mov rax, sob_boolean_false
.L_end:
        leave
        ret AND_KILL_FRAME(1)
        
L_code_ptr_is_void:
        enter 0, 0
        cmp COUNT, 1
        jne L_error_arg_count_1
        mov rax, PARAM(0)
        cmp byte [rax], T_void
        jne .L_false
        mov rax, sob_boolean_true
        jmp .L_end
.L_false:
        mov rax, sob_boolean_false
.L_end:
        leave
        ret AND_KILL_FRAME(1)

L_code_ptr_is_char:
        enter 0, 0
        cmp COUNT, 1
        jne L_error_arg_count_1
        mov rax, PARAM(0)
        cmp byte [rax], T_char
        jne .L_false
        mov rax, sob_boolean_true
        jmp .L_end
.L_false:
        mov rax, sob_boolean_false
.L_end:
        leave
        ret AND_KILL_FRAME(1)

L_code_ptr_is_string:
        enter 0, 0
        cmp COUNT, 1
        jne L_error_arg_count_1
        mov rax, PARAM(0)
        cmp byte [rax], T_string
        jne .L_false
        mov rax, sob_boolean_true
        jmp .L_end
.L_false:
        mov rax, sob_boolean_false
.L_end:
        leave
        ret AND_KILL_FRAME(1)

L_code_ptr_is_symbol:
        enter 0, 0
        cmp COUNT, 1
        jne L_error_arg_count_1
        mov r8, PARAM(0)
        and byte [r8], T_symbol
        jz .L_false
        mov rax, sob_boolean_true
        jmp .L_exit
.L_false:
        mov rax, sob_boolean_false
.L_exit:
        leave
        ret AND_KILL_FRAME(1)

L_code_ptr_is_uninterned_symbol:
        enter 0, 0
        cmp COUNT, 1
        jne L_error_arg_count_1
        mov r8, PARAM(0)
        cmp byte [r8], T_uninterned_symbol
        jne .L_false
        mov rax, sob_boolean_true
        jmp .L_exit
.L_false:
        mov rax, sob_boolean_false
.L_exit:
        leave
        ret AND_KILL_FRAME(1)

L_code_ptr_is_interned_symbol:
        enter 0, 0
        cmp COUNT, 1
        jne L_error_arg_count_1
        mov rax, PARAM(0)
        cmp byte [rax], T_interned_symbol
        jne .L_false
        mov rax, sob_boolean_true
        jmp .L_end
.L_false:
        mov rax, sob_boolean_false
.L_end:
        leave
        ret AND_KILL_FRAME(1)

L_code_ptr_gensym:
        enter 0, 0
        cmp COUNT, 0
        jne L_error_arg_count_0
        inc qword [gensym_count]
        mov rdi, (1 + 8)
        call malloc
        mov byte [rax], T_uninterned_symbol
        mov rcx, qword [gensym_count]
        mov qword [rax + 1], rcx
        leave
        ret AND_KILL_FRAME(0)

L_code_ptr_is_vector:
        enter 0, 0
        cmp COUNT, 1
        jne L_error_arg_count_1
        mov rax, PARAM(0)
        cmp byte [rax], T_vector
        jne .L_false
        mov rax, sob_boolean_true
        jmp .L_end
.L_false:
        mov rax, sob_boolean_false
.L_end:
        leave
        ret AND_KILL_FRAME(1)

L_code_ptr_is_closure:
        enter 0, 0
        cmp COUNT, 1
        jne L_error_arg_count_1
        mov rax, PARAM(0)
        cmp byte [rax], T_closure
        jne .L_false
        mov rax, sob_boolean_true
        jmp .L_end
.L_false:
        mov rax, sob_boolean_false
.L_end:
        leave
        ret AND_KILL_FRAME(1)

L_code_ptr_is_real:
        enter 0, 0
        cmp COUNT, 1
        jne L_error_arg_count_1
        mov rax, PARAM(0)
        cmp byte [rax], T_real
        jne .L_false
        mov rax, sob_boolean_true
        jmp .L_end
.L_false:
        mov rax, sob_boolean_false
.L_end:
        leave
        ret AND_KILL_FRAME(1)

L_code_ptr_is_fraction:
        enter 0, 0
        cmp COUNT, 1
        jne L_error_arg_count_1
        mov rax, PARAM(0)
        cmp byte [rax], T_fraction
        jne .L_false
        mov rax, sob_boolean_true
        jmp .L_end
.L_false:
        mov rax, sob_boolean_false
.L_end:
        leave
        ret AND_KILL_FRAME(1)

L_code_ptr_is_boolean:
        enter 0, 0
        cmp COUNT, 1
        jne L_error_arg_count_1
        mov rax, PARAM(0)
        mov bl, byte [rax]
        and bl, T_boolean
        je .L_false
        mov rax, sob_boolean_true
        jmp .L_end
.L_false:
        mov rax, sob_boolean_false
.L_end:
        leave
        ret AND_KILL_FRAME(1)
        
L_code_ptr_is_boolean_false:
        enter 0, 0
        cmp COUNT, 1
        jne L_error_arg_count_1
        mov rax, PARAM(0)
        mov bl, byte [rax]
        cmp bl, T_boolean_false
        jne .L_false
        mov rax, sob_boolean_true
        jmp .L_end
.L_false:
        mov rax, sob_boolean_false
.L_end:
        leave
        ret AND_KILL_FRAME(1)

L_code_ptr_is_boolean_true:
        enter 0, 0
        cmp COUNT, 1
        jne L_error_arg_count_1
        mov rax, PARAM(0)
        mov bl, byte [rax]
        cmp bl, T_boolean_true
        jne .L_false
        mov rax, sob_boolean_true
        jmp .L_end
.L_false:
        mov rax, sob_boolean_false
.L_end:
        leave
        ret AND_KILL_FRAME(1)

L_code_ptr_is_number:
        enter 0, 0
        cmp COUNT, 1
        jne L_error_arg_count_1
        mov rax, PARAM(0)
        mov bl, byte [rax]
        and bl, T_number
        jz .L_false
        mov rax, sob_boolean_true
        jmp .L_end
.L_false:
        mov rax, sob_boolean_false
.L_end:
        leave
        ret AND_KILL_FRAME(1)
        
L_code_ptr_is_collection:
        enter 0, 0
        cmp COUNT, 1
        jne L_error_arg_count_1
        mov rax, PARAM(0)
        mov bl, byte [rax]
        and bl, T_collection
        je .L_false
        mov rax, sob_boolean_true
        jmp .L_end
.L_false:
        mov rax, sob_boolean_false
.L_end:
        leave
        ret AND_KILL_FRAME(1)

L_code_ptr_cons:
        enter 0, 0
        cmp COUNT, 2
        jne L_error_arg_count_2
        mov rdi, (1 + 8 + 8)
        call malloc
        mov byte [rax], T_pair
        mov rbx, PARAM(0)
        mov SOB_PAIR_CAR(rax), rbx
        mov rbx, PARAM(1)
        mov SOB_PAIR_CDR(rax), rbx
        leave
        ret AND_KILL_FRAME(2)

L_code_ptr_display_sexpr:
        enter 0, 0
        cmp COUNT, 1
        jne L_error_arg_count_1
        mov rdi, PARAM(0)
        call print_sexpr
        mov rax, sob_void
        leave
        ret AND_KILL_FRAME(1)

L_code_ptr_write_char:
        enter 0, 0
        cmp COUNT, 1
        jne L_error_arg_count_1
        mov rax, PARAM(0)
        assert_char(rax)
        mov al, SOB_CHAR_VALUE(rax)
        and rax, 255
        mov rdi, fmt_char
        mov rsi, rax
        mov rax, 0
        ENTER
        call printf
        LEAVE
        mov rax, sob_void
        leave
        ret AND_KILL_FRAME(1)

L_code_ptr_car:
        enter 0, 0
        cmp COUNT, 1
        jne L_error_arg_count_1
        mov rax, PARAM(0)
        assert_pair(rax)
        mov rax, SOB_PAIR_CAR(rax)
        leave
        ret AND_KILL_FRAME(1)
        
L_code_ptr_cdr:
        enter 0, 0
        cmp COUNT, 1
        jne L_error_arg_count_1
        mov rax, PARAM(0)
        assert_pair(rax)
        mov rax, SOB_PAIR_CDR(rax)
        leave
        ret AND_KILL_FRAME(1)
        
L_code_ptr_string_length:
        enter 0, 0
        cmp COUNT, 1
        jne L_error_arg_count_1
        mov rax, PARAM(0)
        assert_string(rax)
        mov rdi, SOB_STRING_LENGTH(rax)
        call make_integer
        leave
        ret AND_KILL_FRAME(1)

L_code_ptr_vector_length:
        enter 0, 0
        cmp COUNT, 1
        jne L_error_arg_count_1
        mov rax, PARAM(0)
        assert_vector(rax)
        mov rdi, SOB_VECTOR_LENGTH(rax)
        call make_integer
        leave
        ret AND_KILL_FRAME(1)

L_code_ptr_real_to_integer:
        enter 0, 0
        cmp COUNT, 1
        jne L_error_arg_count_1
        mov rbx, PARAM(0)
        assert_real(rbx)
        movsd xmm0, qword [rbx + 1]
        cvttsd2si rdi, xmm0
        call make_integer
        leave
        ret AND_KILL_FRAME(1)

L_code_ptr_exit:
        enter 0, 0
        cmp COUNT, 0
        jne L_error_arg_count_0
        mov rax, 0
        call exit

L_code_ptr_integer_to_real:
        enter 0, 0
        cmp COUNT, 1
        jne L_error_arg_count_1
        mov rax, PARAM(0)
        assert_integer(rax)
        push qword [rax + 1]
        cvtsi2sd xmm0, qword [rsp]
        call make_real
        leave
        ret AND_KILL_FRAME(1)

L_code_ptr_fraction_to_real:
        enter 0, 0
        cmp COUNT, 1
        jne L_error_arg_count_1
        mov rax, PARAM(0)
        assert_fraction(rax)
        push qword [rax + 1]
        cvtsi2sd xmm0, qword [rsp]
        push qword [rax + 1 + 8]
        cvtsi2sd xmm1, qword [rsp]
        divsd xmm0, xmm1
        call make_real
        leave
        ret AND_KILL_FRAME(1)

L_code_ptr_char_to_integer:
        enter 0, 0
        cmp COUNT, 1
        jne L_error_arg_count_1
        mov rax, PARAM(0)
        assert_char(rax)
        mov al, byte [rax + 1]
        and rax, 255
        mov rdi, rax
        call make_integer
        leave
        ret AND_KILL_FRAME(1)

L_code_ptr_integer_to_fraction:
        enter 0, 0
        cmp COUNT, 1
        jne L_error_arg_count_1
        mov r8, PARAM(0)
        assert_integer(r8)
        mov rdi, (1 + 8 + 8)
        call malloc
        mov rbx, qword [r8 + 1]
        mov byte [rax], T_fraction
        mov qword [rax + 1], rbx
        mov qword [rax + 1 + 8], 1
        leave
        ret AND_KILL_FRAME(1)

L_code_ptr_integer_to_char:
        enter 0, 0
        cmp COUNT, 1
        jne L_error_arg_count_1
        mov rax, PARAM(0)
        assert_integer(rax)
        mov rbx, qword [rax + 1]
        cmp rbx, 0
        jle L_error_integer_range
        cmp rbx, 256
        jge L_error_integer_range
        mov rdi, (1 + 1)
        call malloc
        mov byte [rax], T_char
        mov byte [rax + 1], bl
        leave
        ret AND_KILL_FRAME(1)

L_code_ptr_trng:
        enter 0, 0
        cmp COUNT, 0
        jne L_error_arg_count_0
        rdrand rdi
        shr rdi, 1
        call make_integer
        leave
        ret AND_KILL_FRAME(0)

L_code_ptr_is_zero:
        enter 0, 0
        cmp COUNT, 1
        jne L_error_arg_count_1
        mov rax, PARAM(0)
        cmp byte [rax], T_integer
        je .L_integer
        cmp byte [rax], T_fraction
        je .L_fraction
        cmp byte [rax], T_real
        je .L_real
        jmp L_error_incorrect_type
.L_integer:
        cmp qword [rax + 1], 0
        je .L_zero
        jmp .L_not_zero
.L_fraction:
        cmp qword [rax + 1], 0
        je .L_zero
        jmp .L_not_zero
.L_real:
        pxor xmm0, xmm0
        push qword [rax + 1]
        movsd xmm1, qword [rsp]
        ucomisd xmm0, xmm1
        je .L_zero
.L_not_zero:
        mov rax, sob_boolean_false
        jmp .L_end
.L_zero:
        mov rax, sob_boolean_true
.L_end:
        leave
        ret AND_KILL_FRAME(1)

L_code_ptr_is_integer:
        enter 0, 0
        cmp COUNT, 1
        jne L_error_arg_count_1
        mov rax, PARAM(0)
        cmp byte [rax], T_integer
        jne .L_false
        mov rax, sob_boolean_true
        jmp .L_exit
.L_false:
        mov rax, sob_boolean_false
.L_exit:
        leave
        ret AND_KILL_FRAME(1)

L_code_ptr_raw_bin_add_rr:
        enter 0, 0
        cmp COUNT, 2
        jne L_error_arg_count_2
        mov rbx, PARAM(0)
        assert_real(rbx)
        mov rcx, PARAM(1)
        assert_real(rcx)
        movsd xmm0, qword [rbx + 1]
        movsd xmm1, qword [rcx + 1]
        addsd xmm0, xmm1
        call make_real
        leave
        ret AND_KILL_FRAME(2)

L_code_ptr_raw_bin_sub_rr:
        enter 0, 0
        cmp COUNT, 2
        jne L_error_arg_count_2
        mov rbx, PARAM(0)
        assert_real(rbx)
        mov rcx, PARAM(1)
        assert_real(rcx)
        movsd xmm0, qword [rbx + 1]
        movsd xmm1, qword [rcx + 1]
        subsd xmm0, xmm1
        call make_real
        leave
        ret AND_KILL_FRAME(2)

L_code_ptr_raw_bin_mul_rr:
        enter 0, 0
        cmp COUNT, 2
        jne L_error_arg_count_2
        mov rbx, PARAM(0)
        assert_real(rbx)
        mov rcx, PARAM(1)
        assert_real(rcx)
        movsd xmm0, qword [rbx + 1]
        movsd xmm1, qword [rcx + 1]
        mulsd xmm0, xmm1
        call make_real
        leave
        ret AND_KILL_FRAME(2)

L_code_ptr_raw_bin_div_rr:
        enter 0, 0
        cmp COUNT, 2
        jne L_error_arg_count_2
        mov rbx, PARAM(0)
        assert_real(rbx)
        mov rcx, PARAM(1)
        assert_real(rcx)
        movsd xmm0, qword [rbx + 1]
        movsd xmm1, qword [rcx + 1]
        pxor xmm2, xmm2
        ucomisd xmm1, xmm2
        je L_error_division_by_zero
        divsd xmm0, xmm1
        call make_real
        leave
        ret AND_KILL_FRAME(2)

L_code_ptr_raw_bin_add_zz:
	enter 0, 0
	cmp COUNT, 2
	jne L_error_arg_count_2
	mov r8, PARAM(0)
	assert_integer(r8)
	mov r9, PARAM(1)
	assert_integer(r9)
	mov rdi, qword [r8 + 1]
	add rdi, qword [r9 + 1]
	call make_integer
	leave
	ret AND_KILL_FRAME(2)

L_code_ptr_raw_bin_add_qq:
        enter 0, 0
        cmp COUNT, 2
        jne L_error_arg_count_2
        mov r8, PARAM(0)
        assert_fraction(r8)
        mov r9, PARAM(1)
        assert_fraction(r9)
        mov rax, qword [r8 + 1] ; num1
        mov rbx, qword [r9 + 1 + 8] ; den 2
        cqo
        imul rbx
        mov rsi, rax
        mov rax, qword [r8 + 1 + 8] ; den1
        mov rbx, qword [r9 + 1]     ; num2
        cqo
        imul rbx
        add rsi, rax
        mov rax, qword [r8 + 1 + 8] ; den1
        mov rbx, qword [r9 + 1 + 8] ; den2
        cqo
        imul rbx
        mov rdi, rax
        call normalize_fraction
        leave
        ret AND_KILL_FRAME(2)

L_code_ptr_raw_bin_sub_zz:
	enter 0, 0
	cmp COUNT, 2
	jne L_error_arg_count_2
	mov r8, PARAM(0)
	assert_integer(r8)
	mov r9, PARAM(1)
	assert_integer(r9)
	mov rdi, qword [r8 + 1]
	sub rdi, qword [r9 + 1]
	call make_integer
	leave
	ret AND_KILL_FRAME(2)

L_code_ptr_raw_bin_sub_qq:
        enter 0, 0
        cmp COUNT, 2
        jne L_error_arg_count_2
        mov r8, PARAM(0)
        assert_fraction(r8)
        mov r9, PARAM(1)
        assert_fraction(r9)
        mov rax, qword [r8 + 1] ; num1
        mov rbx, qword [r9 + 1 + 8] ; den 2
        cqo
        imul rbx
        mov rsi, rax
        mov rax, qword [r8 + 1 + 8] ; den1
        mov rbx, qword [r9 + 1]     ; num2
        cqo
        imul rbx
        sub rsi, rax
        mov rax, qword [r8 + 1 + 8] ; den1
        mov rbx, qword [r9 + 1 + 8] ; den2
        cqo
        imul rbx
        mov rdi, rax
        call normalize_fraction
        leave
        ret AND_KILL_FRAME(2)

L_code_ptr_raw_bin_mul_zz:
	enter 0, 0
	cmp COUNT, 2
	jne L_error_arg_count_2
	mov r8, PARAM(0)
	assert_integer(r8)
	mov r9, PARAM(1)
	assert_integer(r9)
	cqo
	mov rax, qword [r8 + 1]
	mul qword [r9 + 1]
	mov rdi, rax
	call make_integer
	leave
	ret AND_KILL_FRAME(2)

L_code_ptr_raw_bin_mul_qq:
        enter 0, 0
        cmp COUNT, 2
        jne L_error_arg_count_2
        mov r8, PARAM(0)
        assert_fraction(r8)
        mov r9, PARAM(1)
        assert_fraction(r9)
        mov rax, qword [r8 + 1] ; num1
        mov rbx, qword [r9 + 1] ; num2
        cqo
        imul rbx
        mov rsi, rax
        mov rax, qword [r8 + 1 + 8] ; den1
        mov rbx, qword [r9 + 1 + 8] ; den2
        cqo
        imul rbx
        mov rdi, rax
        call normalize_fraction
        leave
        ret AND_KILL_FRAME(2)
        
L_code_ptr_raw_bin_div_zz:
	enter 0, 0
	cmp COUNT, 2
	jne L_error_arg_count_2
	mov r8, PARAM(0)
	assert_integer(r8)
	mov r9, PARAM(1)
	assert_integer(r9)
	mov rdi, qword [r9 + 1]
	cmp rdi, 0
	je L_error_division_by_zero
	mov rsi, qword [r8 + 1]
	call normalize_fraction
	leave
	ret AND_KILL_FRAME(2)

L_code_ptr_raw_bin_div_qq:
        enter 0, 0
        cmp COUNT, 2
        jne L_error_arg_count_2
        mov r8, PARAM(0)
        assert_fraction(r8)
        mov r9, PARAM(1)
        assert_fraction(r9)
        cmp qword [r9 + 1], 0
        je L_error_division_by_zero
        mov rax, qword [r8 + 1] ; num1
        mov rbx, qword [r9 + 1 + 8] ; den 2
        cqo
        imul rbx
        mov rsi, rax
        mov rax, qword [r8 + 1 + 8] ; den1
        mov rbx, qword [r9 + 1] ; num2
        cqo
        imul rbx
        mov rdi, rax
        call normalize_fraction
        leave
        ret AND_KILL_FRAME(2)
        
normalize_fraction:
        push rsi
        push rdi
        call gcd
        mov rbx, rax
        pop rax
        cqo
        idiv rbx
        mov r8, rax
        pop rax
        cqo
        idiv rbx
        mov r9, rax
        cmp r9, 0
        je .L_zero
        cmp r8, 1
        je .L_int
        mov rdi, (1 + 8 + 8)
        call malloc
        mov byte [rax], T_fraction
        mov qword [rax + 1], r9
        mov qword [rax + 1 + 8], r8
        ret
.L_zero:
        mov rdi, 0
        call make_integer
        ret
.L_int:
        mov rdi, r9
        call make_integer
        ret

iabs:
        mov rax, rdi
        cmp rax, 0
        jl .Lneg
        ret
.Lneg:
        neg rax
        ret

gcd:
        call iabs
        mov rbx, rax
        mov rdi, rsi
        call iabs
        cmp rax, 0
        jne .L0
        xchg rax, rbx
.L0:
        cmp rbx, 0
        je .L1
        cqo
        div rbx
        mov rax, rdx
        xchg rax, rbx
        jmp .L0
.L1:
        ret

L_code_ptr_error:
        enter 0, 0
        cmp COUNT, 2
        jne L_error_arg_count_2
        mov rsi, PARAM(0)
        assert_interned_symbol(rsi)
        mov rsi, PARAM(1)
        assert_string(rsi)
        mov rdi, fmt_scheme_error_part_1
        mov rax, 0
        ENTER
        call printf
        LEAVE
        mov rdi, PARAM(0)
        call print_sexpr
        mov rdi, fmt_scheme_error_part_2
        mov rax, 0
        ENTER
        call printf
        LEAVE
        mov rax, PARAM(1)       ; sob_string
        mov rsi, 1              ; size = 1 byte
        mov rdx, qword [rax + 1] ; length
        lea rdi, [rax + 1 + 8]   ; actual characters
        mov rcx, qword [stdout]  ; FILE*
	ENTER
        call fwrite
	LEAVE
        mov rdi, fmt_scheme_error_part_3
        mov rax, 0
        ENTER
        call printf
        LEAVE
        mov rax, -9
        call exit

L_code_ptr_raw_less_than_rr:
        enter 0, 0
        cmp COUNT, 2
        jne L_error_arg_count_2
        mov rsi, PARAM(0)
        assert_real(rsi)
        mov rdi, PARAM(1)
        assert_real(rdi)
        movsd xmm0, qword [rsi + 1]
        movsd xmm1, qword [rdi + 1]
        comisd xmm0, xmm1
        jae .L_false
        mov rax, sob_boolean_true
        jmp .L_exit
.L_false:
        mov rax, sob_boolean_false
.L_exit:
        leave
        ret AND_KILL_FRAME(2)
        
L_code_ptr_raw_less_than_zz:
	enter 0, 0
	cmp COUNT, 2
	jne L_error_arg_count_2
	mov r8, PARAM(0)
	assert_integer(r8)
	mov r9, PARAM(1)
	assert_integer(r9)
	mov rdi, qword [r8 + 1]
	cmp rdi, qword [r9 + 1]
	jge .L_false
	mov rax, sob_boolean_true
	jmp .L_exit
.L_false:
	mov rax, sob_boolean_false
.L_exit:
	leave
	ret AND_KILL_FRAME(2)

L_code_ptr_raw_less_than_qq:
        enter 0, 0
        cmp COUNT, 2
        jne L_error_arg_count_2
        mov rsi, PARAM(0)
        assert_fraction(rsi)
        mov rdi, PARAM(1)
        assert_fraction(rdi)
        mov rax, qword [rsi + 1] ; num1
        cqo
        imul qword [rdi + 1 + 8] ; den2
        mov rcx, rax
        mov rax, qword [rsi + 1 + 8] ; den1
        cqo
        imul qword [rdi + 1]          ; num2
        sub rcx, rax
        jge .L_false
        mov rax, sob_boolean_true
        jmp .L_exit
.L_false:
        mov rax, sob_boolean_false
.L_exit:
        leave
        ret AND_KILL_FRAME(2)

L_code_ptr_raw_equal_rr:
        enter 0, 0
        cmp COUNT, 2
        jne L_error_arg_count_2
        mov rsi, PARAM(0)
        assert_real(rsi)
        mov rdi, PARAM(1)
        assert_real(rdi)
        movsd xmm0, qword [rsi + 1]
        movsd xmm1, qword [rdi + 1]
        comisd xmm0, xmm1
        jne .L_false
        mov rax, sob_boolean_true
        jmp .L_exit
.L_false:
        mov rax, sob_boolean_false
.L_exit:
        leave
        ret AND_KILL_FRAME(2)
        
L_code_ptr_raw_equal_zz:
	enter 0, 0
	cmp COUNT, 2
	jne L_error_arg_count_2
	mov r8, PARAM(0)
	assert_integer(r8)
	mov r9, PARAM(1)
	assert_integer(r9)
	mov rdi, qword [r8 + 1]
	cmp rdi, qword [r9 + 1]
	jne .L_false
	mov rax, sob_boolean_true
	jmp .L_exit
.L_false:
	mov rax, sob_boolean_false
.L_exit:
	leave
	ret AND_KILL_FRAME(2)

L_code_ptr_raw_equal_qq:
        enter 0, 0
        cmp COUNT, 2
        jne L_error_arg_count_2
        mov rsi, PARAM(0)
        assert_fraction(rsi)
        mov rdi, PARAM(1)
        assert_fraction(rdi)
        mov rax, qword [rsi + 1] ; num1
        cqo
        imul qword [rdi + 1 + 8] ; den2
        mov rcx, rax
        mov rax, qword [rdi + 1 + 8] ; den1
        cqo
        imul qword [rdi + 1]          ; num2
        sub rcx, rax
        jne .L_false
        mov rax, sob_boolean_true
        jmp .L_exit
.L_false:
        mov rax, sob_boolean_false
.L_exit:
        leave
        ret AND_KILL_FRAME(2)

L_code_ptr_quotient:
        enter 0, 0
        cmp COUNT, 2
        jne L_error_arg_count_2
        mov rsi, PARAM(0)
        assert_integer(rsi)
        mov rdi, PARAM(1)
        assert_integer(rdi)
        mov rax, qword [rsi + 1]
        mov rbx, qword [rdi + 1]
        cmp rbx, 0
        je L_error_division_by_zero
        cqo
        idiv rbx
        mov rdi, rax
        call make_integer
        leave
        ret AND_KILL_FRAME(2)
        
L_code_ptr_remainder:
        enter 0, 0
        cmp COUNT, 2
        jne L_error_arg_count_2
        mov rsi, PARAM(0)
        assert_integer(rsi)
        mov rdi, PARAM(1)
        assert_integer(rdi)
        mov rax, qword [rsi + 1]
        mov rbx, qword [rdi + 1]
        cmp rbx, 0
        je L_error_division_by_zero
        cqo
        idiv rbx
        mov rdi, rdx
        call make_integer
        leave
        ret AND_KILL_FRAME(2)

L_code_ptr_set_car:
        enter 0, 0
        cmp COUNT, 2
        jne L_error_arg_count_2
        mov rax, PARAM(0)
        assert_pair(rax)
        mov rbx, PARAM(1)
        mov SOB_PAIR_CAR(rax), rbx
        mov rax, sob_void
        leave
        ret AND_KILL_FRAME(2)

L_code_ptr_set_cdr:
        enter 0, 0
        cmp COUNT, 2
        jne L_error_arg_count_2
        mov rax, PARAM(0)
        assert_pair(rax)
        mov rbx, PARAM(1)
        mov SOB_PAIR_CDR(rax), rbx
        mov rax, sob_void
        leave
        ret AND_KILL_FRAME(2)

L_code_ptr_string_ref:
        enter 0, 0
        cmp COUNT, 2
        jne L_error_arg_count_2
        mov rdi, PARAM(0)
        assert_string(rdi)
        mov rsi, PARAM(1)
        assert_integer(rsi)
        mov rdx, qword [rdi + 1]
        mov rcx, qword [rsi + 1]
        cmp rcx, rdx
        jge L_error_integer_range
        cmp rcx, 0
        jl L_error_integer_range
        mov bl, byte [rdi + 1 + 8 + 1 * rcx]
        mov rdi, 2
        call malloc
        mov byte [rax], T_char
        mov byte [rax + 1], bl
        leave
        ret AND_KILL_FRAME(2)

L_code_ptr_vector_ref:
        enter 0, 0
        cmp COUNT, 2
        jne L_error_arg_count_2
        mov rdi, PARAM(0)
        assert_vector(rdi)
        mov rsi, PARAM(1)
        assert_integer(rsi)
        mov rdx, qword [rdi + 1]
        mov rcx, qword [rsi + 1]
        cmp rcx, rdx
        jge L_error_integer_range
        cmp rcx, 0
        jl L_error_integer_range
        mov rax, [rdi + 1 + 8 + 8 * rcx]
        leave
        ret AND_KILL_FRAME(2)

L_code_ptr_vector_set:
        enter 0, 0
        cmp COUNT, 3
        jne L_error_arg_count_3
        mov rdi, PARAM(0)
        assert_vector(rdi)
        mov rsi, PARAM(1)
        assert_integer(rsi)
        mov rdx, qword [rdi + 1]
        mov rcx, qword [rsi + 1]
        cmp rcx, rdx
        jge L_error_integer_range
        cmp rcx, 0
        jl L_error_integer_range
        mov rax, PARAM(2)
        mov qword [rdi + 1 + 8 + 8 * rcx], rax
        mov rax, sob_void
        leave
        ret AND_KILL_FRAME(3)

L_code_ptr_string_set:
        enter 0, 0
        cmp COUNT, 3
        jne L_error_arg_count_3
        mov rdi, PARAM(0)
        assert_string(rdi)
        mov rsi, PARAM(1)
        assert_integer(rsi)
        mov rdx, qword [rdi + 1]
        mov rcx, qword [rsi + 1]
        cmp rcx, rdx
        jge L_error_integer_range
        cmp rcx, 0
        jl L_error_integer_range
        mov rax, PARAM(2)
        assert_char(rax)
        mov al, byte [rax + 1]
        mov byte [rdi + 1 + 8 + 1 * rcx], al
        mov rax, sob_void
        leave
        ret AND_KILL_FRAME(3)

L_code_ptr_make_vector:
        enter 0, 0
        cmp COUNT, 2
        jne L_error_arg_count_2
        mov rcx, PARAM(0)
        assert_integer(rcx)
        mov rcx, qword [rcx + 1]
        cmp rcx, 0
        jl L_error_integer_range
        mov rdx, PARAM(1)
        lea rdi, [1 + 8 + 8 * rcx]
        call malloc
        mov byte [rax], T_vector
        mov qword [rax + 1], rcx
        mov r8, 0
.L0:
        cmp r8, rcx
        je .L1
        mov qword [rax + 1 + 8 + 8 * r8], rdx
        inc r8
        jmp .L0
.L1:
        leave
        ret AND_KILL_FRAME(2)
        
L_code_ptr_make_string:
        enter 0, 0
        cmp COUNT, 2
        jne L_error_arg_count_2
        mov rcx, PARAM(0)
        assert_integer(rcx)
        mov rcx, qword [rcx + 1]
        cmp rcx, 0
        jl L_error_integer_range
        mov rdx, PARAM(1)
        assert_char(rdx)
        mov dl, byte [rdx + 1]
        lea rdi, [1 + 8 + 1 * rcx]
        call malloc
        mov byte [rax], T_string
        mov qword [rax + 1], rcx
        mov r8, 0
.L0:
        cmp r8, rcx
        je .L1
        mov byte [rax + 1 + 8 + 1 * r8], dl
        inc r8
        jmp .L0
.L1:
        leave
        ret AND_KILL_FRAME(2)

L_code_ptr_numerator:
        enter 0, 0
        cmp COUNT, 1
        jne L_error_arg_count_1
        mov rax, PARAM(0)
        assert_fraction(rax)
        mov rdi, qword [rax + 1]
        call make_integer
        leave
        ret AND_KILL_FRAME(1)
        
L_code_ptr_denominator:
        enter 0, 0
        cmp COUNT, 1
        jne L_error_arg_count_1
        mov rax, PARAM(0)
        assert_fraction(rax)
        mov rdi, qword [rax + 1 + 8]
        call make_integer
        leave
        ret AND_KILL_FRAME(1)

L_code_ptr_is_eq:
	enter 0, 0
	cmp COUNT, 2
	jne L_error_arg_count_2
	mov rdi, PARAM(0)
	mov rsi, PARAM(1)
	cmp rdi, rsi
	je .L_eq_true
	mov dl, byte [rdi]
	cmp dl, byte [rsi]
	jne .L_eq_false
	cmp dl, T_char
	je .L_char
	cmp dl, T_interned_symbol
	je .L_interned_symbol
        cmp dl, T_uninterned_symbol
        je .L_uninterned_symbol
	cmp dl, T_real
	je .L_real
	cmp dl, T_fraction
	je .L_fraction
        cmp dl, T_integer
        je .L_integer
	jmp .L_eq_false
.L_integer:
        mov rax, qword [rsi + 1]
        cmp rax, qword [rdi + 1]
        jne .L_eq_false
        jmp .L_eq_true
.L_fraction:
	mov rax, qword [rsi + 1]
	cmp rax, qword [rdi + 1]
	jne .L_eq_false
	mov rax, qword [rsi + 1 + 8]
	cmp rax, qword [rdi + 1 + 8]
	jne .L_eq_false
	jmp .L_eq_true
.L_real:
	mov rax, qword [rsi + 1]
	cmp rax, qword [rdi + 1]
.L_interned_symbol:
	; never reached, because interned_symbols are static!
	; but I'm keeping it in case, I'll ever change
	; the implementation
	mov rax, qword [rsi + 1]
	cmp rax, qword [rdi + 1]
.L_uninterned_symbol:
        mov r8, qword [rdi + 1]
        cmp r8, qword [rsi + 1]
        jne .L_eq_false
        jmp .L_eq_true
.L_char:
	mov bl, byte [rsi + 1]
	cmp bl, byte [rdi + 1]
	jne .L_eq_false
.L_eq_true:
	mov rax, sob_boolean_true
	jmp .L_eq_exit
.L_eq_false:
	mov rax, sob_boolean_false
.L_eq_exit:
	leave
	ret AND_KILL_FRAME(2)

make_real:
        enter 0, 0
        mov rdi, (1 + 8)
        call malloc
        mov byte [rax], T_real
        movsd qword [rax + 1], xmm0
        leave 
        ret
        
make_integer:
        enter 0, 0
        mov rsi, rdi
        mov rdi, (1 + 8)
        call malloc
        mov byte [rax], T_integer
        mov qword [rax + 1], rsi
        leave
        ret
        
L_error_integer_range:
        mov rdi, qword [stderr]
        mov rsi, fmt_integer_range
        mov rax, 0
        ENTER
        call fprintf
        LEAVE
        mov rax, -5
        call exit

L_error_arg_negative:
        mov rdi, qword [stderr]
        mov rsi, fmt_arg_negative
        mov rax, 0
        ENTER
        call fprintf
        LEAVE
        mov rax, -3
        call exit

L_error_arg_count_0:
        mov rdi, qword [stderr]
        mov rsi, fmt_arg_count_0
        mov rdx, COUNT
        mov rax, 0
        ENTER
        call fprintf
        LEAVE
        mov rax, -3
        call exit

L_error_arg_count_1:
        mov rdi, qword [stderr]
        mov rsi, fmt_arg_count_1
        mov rdx, COUNT
        mov rax, 0
        ENTER
        call fprintf
        LEAVE
        mov rax, -3
        call exit

L_error_arg_count_2:
        mov rdi, qword [stderr]
        mov rsi, fmt_arg_count_2
        mov rdx, COUNT
        mov rax, 0
        ENTER
        call fprintf
        LEAVE
        mov rax, -3
        call exit

L_error_arg_count_12:
        mov rdi, qword [stderr]
        mov rsi, fmt_arg_count_12
        mov rdx, COUNT
        mov rax, 0
        ENTER
        call fprintf
        LEAVE
        mov rax, -3
        call exit

L_error_arg_count_3:
        mov rdi, qword [stderr]
        mov rsi, fmt_arg_count_3
        mov rdx, COUNT
        mov rax, 0
        ENTER
        call fprintf
        LEAVE
        mov rax, -3
        call exit
        
L_error_incorrect_type:
        mov rdi, qword [stderr]
        mov rsi, fmt_type
        mov rax, 0
        ENTER
        call fprintf
        LEAVE
        mov rax, -4
        call exit

L_error_division_by_zero:
        mov rdi, qword [stderr]
        mov rsi, fmt_division_by_zero
        mov rax, 0
        ENTER
        call fprintf
        LEAVE
        mov rax, -8
        call exit

section .data
gensym_count:
        dq 0
fmt_char:
        db `%c\0`
fmt_arg_negative:
        db `!!! The argument cannot be negative.\n\0`
fmt_arg_count_0:
        db `!!! Expecting zero arguments. Found %d\n\0`
fmt_arg_count_1:
        db `!!! Expecting one argument. Found %d\n\0`
fmt_arg_count_12:
        db `!!! Expecting one required and one optional argument. Found %d\n\0`
fmt_arg_count_2:
        db `!!! Expecting two arguments. Found %d\n\0`
fmt_arg_count_3:
        db `!!! Expecting three arguments. Found %d\n\0`
fmt_type:
        db `!!! Function passed incorrect type\n\0`
fmt_integer_range:
        db `!!! Incorrect integer range\n\0`
fmt_division_by_zero:
        db `!!! Division by zero\n\0`
fmt_scheme_error_part_1:
        db `\n!!! The procedure \0`
fmt_scheme_error_part_2:
        db ` asked to terminate the program\n`
        db `    with the following message:\n\n\0`
fmt_scheme_error_part_3:
        db `\n\nGoodbye!\n\n\0`