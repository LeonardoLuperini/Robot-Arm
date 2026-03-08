const std = @import("std");
const zopengl = @import("zopengl");

const gl = zopengl.bindings;
const uint = c_uint;
const int = c_int;
const allocator = std.heap.c_allocator;

const ShaderError = error{
    ProgramCreationFailed,
    ShaderCreationFailed,

    ShaderCompilationFailed,
    ProgramLinkFailed,
};

program: uint,

pub fn new(comptime vert_path: []const u8, comptime frag_path: []const u8) ShaderError!@This() {
    const vs = try compileShader(gl.VERTEX_SHADER, vert_path);
    errdefer gl.deleteShader(vs);

    const fs = try compileShader(gl.FRAGMENT_SHADER, frag_path);
    errdefer gl.deleteShader(fs);

    const program = gl.createProgram();
    if (program == 0) return ShaderError.ProgramCreationFailed;
    errdefer gl.deleteProgram(program);

    gl.attachShader(program, vs);
    gl.attachShader(program, fs);

    gl.linkProgram(program);
    try checkProgramLink(program);

    // Shader objects are no longer needed after a successful link.
    gl.deleteShader(vs);
    gl.deleteShader(fs);

    logProgramValidation(program);

    return .{ .program = program };
}

pub inline fn use(self: *const @This()) void {
    gl.useProgram(self.program);
}

pub fn deinit(self: *@This()) void {
    if (self.program != 0) {
        gl.deleteProgram(self.program);
        self.program = 0;
    }
}

fn compileShader(comptime shader_type: uint, comptime path: []const u8) ShaderError!uint {
    // “Treat this pointer-to-array as a C pointer, (aka potinter to its first byte).”
    const shader_ptr: [*c]const u8 = @ptrCast(@embedFile(path));
    // “Create an array of C string pointers, because OpenGL expects char**.”
    const shader_ptr_array = [_][*c]const u8{ shader_ptr };

    const shader: uint = gl.createShader(shader_type);
    if (shader == 0) return ShaderError.ShaderCreationFailed;
    errdefer gl.deleteShader(shader);

    //                           ⬐pointer to the first element of an array of C string pointers
    gl.shaderSource(shader, 1, &shader_ptr_array, null);
    gl.compileShader(shader);

    try checkShaderCompile(shader, path);

    return shader;
}

fn checkShaderCompile(shader: uint, comptime path: []const u8) ShaderError!void {
    var compiled: int = undefined;
    gl.getShaderiv(shader, gl.COMPILE_STATUS, &compiled);

    if (compiled == gl.TRUE) return;

    printShaderInfoLog(shader, path);
    return ShaderError.ShaderCompilationFailed;
}

fn checkProgramLink(program: uint) !void {
    var linked: int = undefined;
    gl.getProgramiv(program, gl.LINK_STATUS, &linked);

    if (linked == gl.TRUE) return;

    printProgramInfoLog(program, "Program link failed");
    return ShaderError.ProgramLinkFailed;
}

fn logProgramValidation(program: uint) void {
    var valid: int = undefined;
    gl.getProgramiv(program, gl.VALIDATE_STATUS, &valid);

    if (valid == gl.TRUE) return;

    printProgramInfoLog(program, "Program validation failed (not always fatal)");
}

fn printShaderInfoLog(shader: uint, comptime path: []const u8) void {
    var log_len: int = 0;
    gl.getShaderiv(shader, gl.INFO_LOG_LENGTH, &log_len);

    if (log_len <= 1) {
        std.debug.print(
            \\-------------------------------------
            \\Shader compilation failed: "{s}"
            \\(no compiler log)
            \\-------------------------------------
            \\
        , .{path});
        return;
    }

    const log = allocator.alloc(u8, @intCast(log_len)) catch {
        std.debug.print(
            \\-------------------------------------
            \\Shader compilation failed: "{s}"
            \\(could not allocate compiler log buffer)
            \\-------------------------------------
            \\
        , .{path});
        return;
    };
    defer allocator.free(log);

    var written: int = 0;
    gl.getShaderInfoLog(shader, log_len, &written, log.ptr);

    std.debug.print(
        \\-------------------------------------
        \\Shader compilation failed: "{s}"
        \\{s}
        \\-------------------------------------
        \\
    , .{ path, log[0..@intCast(written)] });
}

fn printProgramInfoLog(program: uint, comptime header: []const u8) void {
    var log_len: int = 0;
    gl.getProgramiv(program, gl.INFO_LOG_LENGTH, &log_len);

    if (log_len <= 1) {
        std.debug.print(
            \\-------------------------------------
            \\{s}
            \\(no linker/validation log)
            \\-------------------------------------
            \\
        , .{header});
        return;
    }

    const log = allocator.alloc(u8, @intCast(log_len)) catch {
        std.debug.print(
            \\-------------------------------------
            \\{s}
            \\(could not allocate linker/validation log buffer)
            \\-------------------------------------
            \\
        , .{header});
        return;
    };
    defer allocator.free(log);

    var written: int = 0;
    gl.getProgramInfoLog(program, log_len, &written, log.ptr);

    std.debug.print(
        \\-------------------------------------
        \\{s}
        \\{s}
        \\-------------------------------------
        \\
    , .{ header, log[0..@intCast(written)] });
}
