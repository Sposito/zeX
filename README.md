# ZeX: A Scheme-to-Zig Compiler and Runtime

## Overview
ZeX is a Scheme-to-Zig compiler and runtime that leverages Zig's `comptime` features to generate efficient, statically-typed code. The core design philosophy is to precompile as much as possible, while still allowing lazy compilation of new expressions. While self-hosting is a long-term idea, the current focus is on building core functionality such as a basic runtime, modular compilation, incremental builds, and proper integration with Zig.

In particular, ZeX is mindful of two fundamental Scheme features:
1. Macros: Important in the long term, but not implemented in the immediate roadmap.  
2. Tail Call Optimization (TCO): Recognized as a core Scheme requirement, but initially deferred. The design will keep tail calls visible in the AST, ensuring that TCO can be integrated without major rewrites.

## Goals
- Static Compilation: Transform as much Scheme code as possible into native Zig binaries.
- Lazy and Incremental Compilation: Compile new Scheme expressions or functions on demand, minimizing recompilation.
- Modular Approach: Split the runtime and compiled code into Zig modules so they can be managed independently.
- Performance: Leverage Zig for critical paths; rely on faster-than-interpreted performance without over-optimizing prematurely.
- Future-Proofing for TCO and Macros: Keep the design open to implementing proper tail calls and macros when the core system is stable.
- Potential Self-Hosting: A longer-term goal, but not an immediate priority.

## Architecture

### 1. Project Structure
```
/zeX
├── src/
│   ├── zex.zig        ; Frontend: CLI, invoking build, handling inputs
│   ├── lib.zig        ; Core logic: parser, tokenizer, Zig code generator
│   ├── output.zig     ; Generated Zig file with Scheme evaluation capability
│   ├── build.zig      ; Zig build system
│   ├── modules/       
│   │   ├── math.zig   ; Arithmetic module, used on demand
│   │   ├── io.zig     ; Display and input handling
│   │   ├── string.zig ; String functions
│   │   ├── ...
├── tests/
│   ├── ...
├── zig-out/
    ├── bin/
        ├── ...
```

### 2. Compilation Workflow
ZeX follows a three-phase compilation pipeline:

1. Parsing
   - Converts Scheme code into an S-expression tree (Expr).
   - Keeps track of symbol definitions and detects tail positions for future TCO.

2. Code Generation
   - Uses Zig's comptime recursion to generate static code.
   - Includes only necessary modules to avoid bloated binaries.
   - Aims to ensure modular builds that can be incrementally updated.

3. Compilation and Execution
   - ZeX writes compiled Scheme code into `output.zig`.
   - Invokes Zig to produce a native executable.
   - Can optionally link in newly compiled functions as separate modules, instead of recompiling everything.

### 3. Execution Model

#### Precompiled Functions (Eager Compilation)
- Core Scheme features and basic operations are implemented in Zig modules (for example, math operations in math.zig).
- These are compiled and made available by default, so common Scheme primitives do not trigger repeated recompilation.

#### Lazy Compilation for New Expressions
- If ZeX encounters a new function or expression, it generates the associated Zig code on demand and appends it to an existing module or places it in a new module.
- Only the newly introduced functionality is recompiled, allowing for incremental builds.

#### Incremental Compilation Strategy
- Rather than overwriting `output.zig` constantly, ZeX can produce multiple modules that get compiled separately.
- Each module is a self-contained piece of the larger Scheme application.

### 4. Example Workflow

#### Example Scheme Input
```
(@import std)
(display (+ 3 4))
```

#### Generated `output.zig`
```
const std = @import("std");
const math = @import("math");
const lib = @import("lib");

pub fn main() !void {
    var args = std.process.args();
    if (args[2] == "eval") {
        lib.eval(args);
    } else {
        std.debug.print("{}", .{math.sum_u8(3, 4)});
    }
}
```

#### math.zig Module
```
pub fn sum_u8(a: u8, b: u8) u8 {
    return a + b;
}
```
Note that in practice, math.zig may also contain comptime code to handle different numeric types.

#### ZeX Execution Steps
1. Parse Scheme → Generate `output.zig`.
2. Compile `output.zig` to an executable.
3. Run the executable, which then uses the compiled Scheme program logic.

## Next Steps
- Implement user-defined functions with define.  
- Finalize incremental compilation: generate smaller Zig modules that can be dynamically linked.  
- Add a caching mechanism to avoid rebuilding unchanged modules.  
- Expand numeric support beyond basic integer operations.  
- Keep the code generator aware of tail calls, so TCO can be added later without major refactoring.  
- Prepare the parsing and code generation phases to accommodate macros in the future.

## Long-Term Vision
- Implement proper tail call optimization to meet Scheme standards.  
- Introduce macros once the compiler is stable, allowing metaprogramming typical of Scheme.  
- Potentially move towards a self-hosting system that compiles ZeX from within ZeX itself, using Zig as a performance-focused backend.  
- Build a more advanced runtime that includes memory management and additional standard library features.

---

### Summary
ZeX aims to combine the flexibility of Scheme with the performance-oriented design of Zig. By leveraging incremental, lazy compilation and carefully structuring the code generator, ZeX can handle typical Scheme code while still leaving room for advanced features like macros and tail call optimization. The current priority is to solidify the core runtime, parser, and incremental build process, enabling straightforward compilation of basic Scheme programs into efficient native executables.