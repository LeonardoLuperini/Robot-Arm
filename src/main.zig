const std = @import("std");
const glfw = @import("zglfw");
const zopengl = @import("zopengl");

const gl = zopengl.bindings;
const uint = gl.Uint;
const int = gl.Int;
const gl_version_major = 4;
const gl_version_minor = 1;
const sugg_width = 640;
const sugg_height = 480;

var g_proj_loc: int = -1;

const Rgb = struct {
    r: u8,
    g: u8,
    b: u8,
};

const Cube = struct {
    x: f32 = 0,
    y: f32 = 0,
    z: f32 = 0,
    size: f32,
    color: Rgb,
};

const RenderableCube = struct {
    const va: uint;
    fn init(self: *RenderableCube, cube: Cube) void {
        self.va = gl.genVertexArrays(1, &va);

    }
    fn calcVertex(self: *Renderable, cube: Cube) void {

    }
}



pub fn main() !void {
    try glfw.init();
    defer glfw.terminate();

    glfw.windowHint(.client_api, .opengl_api);
    glfw.windowHint(.context_version_major, gl_version_major);
    glfw.windowHint(.context_version_minor, gl_version_minor);
    glfw.windowHint(.opengl_profile, .opengl_core_profile);
    glfw.windowHint(.opengl_forward_compat, true);
    glfw.windowHint(.doublebuffer, true);
    glfw.windowHint(.resizable, true);

    const window = try glfw.createWindow(sugg_width, sugg_height, "Hello World", null, null);
    defer window.destroy();

    glfw.makeContextCurrent(window);
    try zopengl.loadCoreProfile(&glfw.getProcAddress, 4, 1);

    _ = window.setFramebufferSizeCallback(framebuffer_size_callback);

    const fb = window.getFramebufferSize();
    gl.viewport(0, 0, fb[0], fb[1]);

    // VBA
    var va: uint = undefined;
    gl.genVertexArrays(1, &va);
    gl.bindVertexArray(va);

    const position_attib_index: uint = 0;
    gl.enableVertexAttribArray(position_attib_index);

    const color_attrib_index = 1;
    gl.enableVertexAttribArray(color_attrib_index);

    // VBO
    const positions_and_colors = [_]f32 {
    // Positions are given in world coordinates
    //    x    y   r    g    b
        -50, -50, 1.0, 0.0, 0.0,
         50, -50, 0.0, 1.0, 0.0,
         50,  50, 0.0, 0.0, 1.0,
        -50,  50, 1.0, 1.0, 1.0,
    };

    var pos_col_buff: uint = undefined;
    gl.genBuffers(1, &pos_col_buff);
    gl.bindBuffer(gl.ARRAY_BUFFER, pos_col_buff);

    gl.bufferData(gl.ARRAY_BUFFER, @sizeOf(@TypeOf(positions_and_colors)), &positions_and_colors, gl.STATIC_DRAW);

    gl.vertexAttribPointer(position_attib_index, 2, gl.FLOAT, gl.FALSE, @sizeOf(f32)*5, @ptrFromInt(0));
    gl.vertexAttribPointer(color_attrib_index, 3, gl.FLOAT, gl.FALSE, @sizeOf(f32)*5, @ptrFromInt(@sizeOf(f32) * 2));

    // EBO
    const indices = [_]uint{0, 1, 2, 0, 2, 3};
    var index_buffer: uint = undefined;

    gl.genBuffers(1, &index_buffer);
    gl.bindBuffer(gl.ELEMENT_ARRAY_BUFFER, index_buffer);
    gl.bufferData(
        gl.ELEMENT_ARRAY_BUFFER,
        @sizeOf(@TypeOf(indices)),
        &indices,
        gl.STATIC_DRAW
    );

    // Shaders set-up
    const vs = setShader(gl.VERTEX_SHADER, "basic.vert");
    const fs = setShader(gl.FRAGMENT_SHADER, "basic.frag");

    const ps = gl.createProgram();
    gl.attachShader(ps, vs);
    gl.attachShader(ps, fs);

    gl.linkProgram(ps);

    gl.useProgram(ps);

    const proj = ortho(-sugg_width/2, sugg_width/2, sugg_height/2, -sugg_height/2);
    // Link Projection martix to the shader
    g_proj_loc = gl.getUniformLocation(ps, "uProj");
    gl.uniformMatrix4fv(g_proj_loc, 1, gl.FALSE, &proj);

    gl.clearColor(0.2, 0.2, 0.2, 1);
    while (!glfw.windowShouldClose(window)) {

        gl.clear(gl.COLOR_BUFFER_BIT);

        gl.drawElements(gl.TRIANGLES, 6, gl.UNSIGNED_INT, null);

        window.swapBuffers();

        glfw.pollEvents();
    }

}

fn setShader(comptime shader_type: uint, comptime path: []const u8) uint {
    // “Treat this pointer-to-array as a C pointer to its first byte.”
    const shader_ptr: [*c] const u8 = @ptrCast(@embedFile(path));
    // “Create an array of C string pointers, because OpenGL expects char**.”
    const shader_ptr_array = [_][*c]const u8{ shader_ptr };

    const shader: uint = gl.createShader(shader_type);
    //                    ⬐pointer to the first element of an array of C string pointers
    gl.shaderSource(shader, 1, &shader_ptr_array, null);
    gl.compileShader(shader);

    return shader;
}

fn framebuffer_size_callback(window: *glfw.Window, fb_w: c_int, fb_h: c_int) callconv(.c) void {
    _ = window;

    gl.viewport(0, 0, fb_w, fb_h);

    const aspect = @as(f32, @floatFromInt(fb_w)) / @as(f32, @floatFromInt(fb_h));
    const world_h: f32 = sugg_height;
    const world_w: f32 = world_h * aspect;

    const proj = ortho(-world_w/2, world_w/2, world_h/2, -world_h/2);
    gl.uniformMatrix4fv(g_proj_loc, 1, gl.FALSE, &proj);
}

fn ortho(l: f32, r: f32, t: f32, b: f32) [16]f32 {
    // s -> scale
    const sx = 2.0 / (r-l);
    const sy = 2.0 / (t-b);
    // t -> translate
    const tx = -(r+l) / (r-l);
    const ty = -(t+b) / (t-b);

    return .{
        sx,  0,  0,  0,
         0, sy,  0,  0,
         0,  0, -1,  0,
        tx, ty,  0,  1,
    };
}
