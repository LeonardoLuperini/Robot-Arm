const std = @import("std");
const glfw = @import("zglfw");
const zopengl = @import("zopengl");
const za = @import("zalgebra");
const shapes = @import("shapes.zig");
const Shader = @import("shader.zig");

const Cube = shapes.Cube;
const RenCube = shapes.RenderableCube;

const gl = zopengl.bindings;
const uint = gl.Uint;
const int = gl.Int;
const Mat3 = za.Mat3;
const Mat4 = za.Mat4;
const Vec3 = za.Vec3;
const Vec4 = za.Vec4;

const gl_version_major = 4;
const gl_version_minor = 1;
const sugg_width: comptime_float = 1920;
const sugg_height: comptime_float = 1080;
const aspect: comptime_float = sugg_width/sugg_height;

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

    // Shader
    const shader = try Shader.new("basic.vert", "basic.frag");
    shader.use();

    const cube: Cube = .{
        .pos = Vec3.new(0, -10, -25),
        .size = 5

    };

    var rc = RenCube.new(cube);

    const projection = za.perspective(60, aspect, 10, 50);
    const uProj = gl.getUniformLocation(shader.program, "uProj");
    gl.uniformMatrix4fv(uProj, 1, gl.FALSE, &projection.data[0]);

    gl.clearColor(0.2, 0.2, 0.2, 1);
    while (!glfw.windowShouldClose(window)) {

        gl.clear(gl.COLOR_BUFFER_BIT);

        // gl.drawElements(gl.TRIANGLES, 6, gl.UNSIGNED_INT, null);
        rc.draw();

        window.swapBuffers();

        glfw.pollEvents();
    }

}

fn framebuffer_size_callback(window: *glfw.Window, fb_w: c_int, fb_h: c_int) callconv(.c) void {
    _ = window;
    _ = fb_w;
    _ = fb_h;
}
