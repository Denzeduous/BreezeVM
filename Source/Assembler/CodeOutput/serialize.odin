package CodeOutput

import "assembler:Lexer"

import "breeze:Types"
import "breeze:Bytecode"

// Iterates on a line of BVM Assembly, writing it to the bytecode buffer.
iterate :: proc (code_ctx: ^Code_Context, lex_ctx: ^Lexer.Lexer_Context) {
    Lexer.eat_whitespace (lex_ctx);

    if (Lexer.peek (lex_ctx) == '.') {
        append (
            &code_ctx.procs,

            Types.Procedure {
                code_ctx.off,

                Lexer.get_proc_name (lex_ctx),
                Lexer.get_value     (lex_ctx),
                Lexer.get_value     (lex_ctx),
            },
        );
    }

    else if (Lexer.peek (lex_ctx) == ';') {
        Lexer.eat_comment (lex_ctx);
    }

    else {
        write_instruction (code_ctx, lex_ctx);
    }
}

write_instruction :: proc (code_ctx: ^Code_Context, lex_ctx: ^Lexer.Lexer_Context) {
    Lexer.eat_whitespace (lex_ctx);

    instruction := Lexer.get_instruction (lex_ctx);

    if (instruction == Bytecode.Instruction.GOTO) {
        write_to_code_context (code_ctx, Bytecode.Instruction.JMP);

        label := Lexer.get_word (lex_ctx);
        append (&code_ctx.gotos, Goto {label, code_ctx.off});

        write_to_code_context (code_ctx, u64 (0));

        return;
    }

    else if (instruction == Bytecode.Instruction.GOTOIF) {
        write_to_code_context (code_ctx, Bytecode.Instruction.JMPIF);

        label := Lexer.get_word (lex_ctx);

        append (&code_ctx.gotos, Goto {label, code_ctx.off});

        write_to_code_context (code_ctx, u64 (0));

        return;
    }

    write_to_code_context (code_ctx, instruction);

    if (instruction == Bytecode.Instruction.CALL_PROC_O) {
        append (&code_ctx.proc_calls, Proc_Call {Lexer.get_word (lex_ctx), code_ctx.off});

        write_to_code_context (code_ctx, u64 (0));

        return;
    }

    if (instruction < Bytecode.Instruction._RESERVED_NO_BIT_PREPARED_VALUE_INSTRUCTIONS) do return;

    if (instruction < Bytecode.Instruction._RESERVED_64_BIT_MULTI_VALUE_INSTRUCTIONS) {
        write_to_code_context (code_ctx, Lexer.get_value (lex_ctx));

        return;
    }

    if (instruction < Bytecode.Instruction._RESERVED_72_BIT_INSTRUCTIONS) {
        write_to_code_context (code_ctx, Lexer.get_value (lex_ctx));
        write_to_code_context (code_ctx, Lexer.get_type  (lex_ctx));

        return;
    }

    if (instruction < Bytecode.Instruction._RESERVED_128_BIT_INSTRUCTIONS) {
        write_to_code_context (code_ctx, Lexer.get_value (lex_ctx));
        write_to_code_context (code_ctx, Lexer.get_value (lex_ctx));

        return;
    }

    if (instruction < Bytecode.Instruction._RESERVED_136_BIT_INSTRUCTIONS) {
        write_to_code_context (code_ctx, Lexer.get_value (lex_ctx));
        write_to_code_context (code_ctx, Lexer.get_value (lex_ctx));
        write_to_code_context (code_ctx, Lexer.get_type  (lex_ctx));

        return;
    }
}