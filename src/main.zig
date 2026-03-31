const std = @import("std");
const glfw = @import("zglfw");
const zopengl = @import("zopengl");
const za = @import("zalgebra");
const shapes = @import("shapes.zig");
const Shader = @import("shader.zig");
const Trackball = @import("trackball.zig").Trackball;

const Cube = shapes.Cube;
const RenCube = shapes.RenderableCube;

const gl   = zopengl.bindings;
const Mat3 = za.Mat3;
const Mat4 = za.Mat4;
const Vec3 = za.Vec3;
const Vec4 = za.Vec4;
const Quat = za.Quat;

const gl_version_major = 4;
const gl_version_minor = 1;
const default_width: comptime_float = 1920;
const default_height: comptime_float = 1080;
const default_aspect: comptime_float = default_width/default_height;
const fovy: comptime_int = 60;
const z_near: comptime_int = 10;
const z_far: comptime_int = 50;

const Window = glfw.Window;
const MouseButton = glfw.MouseButton;
const Action = glfw.Action;
const Mods = glfw.Mods;

const RenderState = struct {
    trackball: *Trackball,
    shader_program: c_uint,
    uProj: c_int,
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
    _ = window.setMouseButtonCallback(mouseButtonCallback);
    _ = window.setCursorPosCallback(cursorPosCallback);

    const fb = window.getFramebufferSize();
    gl.viewport(0, 0, fb[0], fb[1]);

    // Trackball
    var trackball = Trackball.init(@floatFromInt(fb[0]), @floatFromInt(fb[1]));

    // Shader
    const shader = try Shader.new("basic.vert","basic.frag");
    shader.use();

    // Shapes
    const cube: Cube = .{
        .pos = Vec3.new(0, -10, -25),
        .size = 5

    };

    var rc = RenCube.new(cube);

    // Projection Matrix
    const projection = za.perspective(fovy, default_aspect, z_near, z_far);
    const uProj = gl.getUniformLocation(shader.program, "uProj");
    gl.uniformMatrix4fv(uProj, 1, gl.FALSE, &projection.data[0]);

    // View Matrix
    const uView = gl.getUniformLocation(shader.program, "uView");

    // RenderState
    var render_state = RenderState{
        .trackball = &trackball,
        .shader_program = shader.program,
        .uProj = uProj,
    };

    window.setUserPointer(@ptrCast(&render_state));

    gl.enable(gl.DEPTH_TEST);
    gl.clearColor(0.05, 0.05, 0.05, 1);

    while (!glfw.windowShouldClose(window)) {

        gl.clear(gl.COLOR_BUFFER_BIT | gl.DEPTH_BUFFER_BIT);

        const view = getViewMatrix(trackball.getRotation(), cube.pos, 20);
        gl.uniformMatrix4fv(uView, 1, gl.FALSE, &view.data[0]);
        rc.draw();

        window.swapBuffers();

        glfw.pollEvents();
    }

}

fn getViewMatrix(rotation: Quat, target: Vec3, distance: f32) Mat4 {
    const rotation_mat = rotation.toMat4();

    // initial position of the eye around the origin
    const initial_eye = Vec3.new(0, 0, distance);
    // eye rotated around origin
    const rotated_eye = rotation_mat.mulByVec3(initial_eye);
    // eye rotated around target
    const eye = target.add(rotated_eye);

    // Rotate the up vector
    const up = rotation_mat.mulByVec3(Vec3.up());

    return za.lookAt(eye, target, up);
}

fn framebuffer_size_callback(window: *Window, fb_w: c_int, fb_h: c_int) callconv(.c) void {
    gl.viewport(0, 0, fb_w, fb_h);
    if (fb_h == 0) return; // Protects from division by 0 in case the window is minimized
    const state: *RenderState = window.getUserPointer(RenderState).?;

    // Update projection Matrix
    const aspect: f32 = @as(f32, @floatFromInt(fb_w)) / @as(f32, @floatFromInt(fb_h));
    const projection = za.perspective(fovy, aspect, z_near, z_far);
    gl.useProgram(state.shader_program);
    gl.uniformMatrix4fv(state.uProj, 1, gl.FALSE, &projection.data[0]);

    // Update trackball
    state.trackball.resize(@floatFromInt(fb_w), @floatFromInt(fb_h));
}

fn cursorPosCallback(window: *Window, xpos: f64, ypos: f64) callconv(.c) void {
    const state = window.getUserPointer(RenderState).?;
    state.trackball.mouseMove(@floatCast(xpos), @floatCast(ypos));
}

// Action can only be press or release
fn mouseButtonCallback(window: *Window, button: MouseButton, action: Action, mods: Mods) callconv(.c) void {
    _ = mods;

    if (button != MouseButton.left) return;

    const state = window.getUserPointer(RenderState).?;
    const trackball = state.trackball;
    const pos = window.getCursorPos();

    if (action == Action.press) {
        trackball.mouseDown(@floatCast(pos[0]), @floatCast(pos[1]));
    }
    else {
        trackball.mouseUp();
    }
}
