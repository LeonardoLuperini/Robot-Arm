const std = @import("std");
const glfw = @import("zglfw");
const zopengl = @import("zopengl");
const za = @import("zalgebra");
const shapes = @import("shapes.zig");
const Shader = @import("shader.zig");

const Cube = shapes.Cube;
const RenCube = shapes.RenderableCube;

const gl   = zopengl.bindings;
const uint = gl.Uint; // c_uint
const int  = gl.Int;  // equal to c_int
const Mat3 = za.Mat3;
const Mat4 = za.Mat4;
const Vec3 = za.Vec3;
const Vec4 = za.Vec4;

const gl_version_major = 4;
const gl_version_minor = 1;
const default_width: comptime_float = 1920;
const default_height: comptime_float = 1080;
const default_aspect: comptime_float = default_width/default_height;
const fovy: comptime_int = 60;
const z_near: comptime_int = 10;
const z_far: comptime_int = 50;

const RenderState = struct {
    shader_program: uint,
    uProj: int,
};

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

    const window = try glfw.createWindow(default_width, default_height, "Hello World", null, null);
    defer window.destroy();

    glfw.makeContextCurrent(window);
    try zopengl.loadCoreProfile(&glfw.getProcAddress, 4, 1);

    _ = window.setFramebufferSizeCallback(framebuffer_size_callback);

    const fb = window.getFramebufferSize();
    gl.viewport(0, 0, fb[0], fb[1]);

    // Shader
    const shader = try Shader.new("basic.vert", "basic.frag");
    shader.use();

    const cube: Cube = .{
        .pos = Vec3.new(0, -10, -25),
        .size = 5

    };

    var rc = RenCube.new(cube);

    // Perspective Matrix
    const projection = za.perspective(fovy, default_aspect, z_near, z_far);
    const uProj = gl.getUniformLocation(shader.program, "uProj");
    gl.uniformMatrix4fv(uProj, 1, gl.FALSE, &projection.data[0]);

    var render_state = RenderState{
        .shader_program = shader.program,
        .uProj = uProj,
    };

    window.setUserPointer(@ptrCast(&render_state));

    gl.clearColor(0.2, 0.2, 0.2, 1);
    while (!glfw.windowShouldClose(window)) {

        gl.clear(gl.COLOR_BUFFER_BIT);

        rc.draw();

        window.swapBuffers();

        glfw.pollEvents();
    }

}

fn framebuffer_size_callback(window: *glfw.Window, fb_w: int, fb_h: int) callconv(.c) void {
    gl.viewport(0, 0, fb_w, fb_h);

    if (fb_h == 0) return; // Protects from division by 0 in case the window is minimmized

    const aspect: f32 = @as(f32, @floatFromInt(fb_w)) / @as(f32, @floatFromInt(fb_h));
    const projection = za.perspective(fovy, aspect, z_near, z_far);

    const rs: RenderState = window.getUserPointer(RenderState).?.*;

    gl.useProgram(rs.shader_program);
    gl.uniformMatrix4fv(rs.uProj, 1, gl.FALSE, &projection.data[0]);
}
