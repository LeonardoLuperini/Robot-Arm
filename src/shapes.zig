const std = @import("std");
const zopengl = @import("zopengl");
const za = @import("zalgebra");

const gl = zopengl.bindings;
const uint = gl.Uint;
const int = gl.Int;
const Mat3 = za.Mat3;
const Mat4 = za.Mat4;
const Vec3 = za.Vec3;
const Vec4 = za.Vec4;

pub const Rgb = struct {
    r: f32,
    g: f32,
    b: f32,
};

pub const Cube = struct {
    pos: Vec3 = Vec3.set(0),
    size: f32 = 1,
    color: Rgb = .{
        .r = 0.5,
        .g = 0.5,
        .b = 0.5,
    },
};

pub const RenderableCube = struct {
    // 3 coord (x, y, z) per vertex
    // 1 rgb per vertex, 1 rgb -> 3 values
    const stride: comptime_int = 3+3;
    const n_of_verices: comptime_int = 8;
    // 3 index per triangle, 2 triangle per face, 6 faces
    const n_of_indices: comptime_int = 3*2*6;

    vao: uint,

    pub fn new(cube: Cube) RenderableCube {
        var rc: RenderableCube = .{
            .vao = undefined,
        };
        gl.genVertexArrays(1, &rc.vao);

        rc.bind();
        defer unbind();

        setVertexData(initVertexData(cube));

        setIndices();

        return rc;
    }

    pub fn draw(self: *RenderableCube) void {
        self.bind();
        defer unbind();

        gl.drawElements(gl.TRIANGLES, n_of_indices, gl.UNSIGNED_INT, null);
    }


    fn setIndices() void {
        var index_buffer: uint = undefined;
        gl.genBuffers(1, &index_buffer);
        gl.bindBuffer(gl.ELEMENT_ARRAY_BUFFER, index_buffer);

        const indices: [n_of_indices]uint = .{
               0, 1, 2, 2, 1, 3,  // front
               5, 4, 7, 7, 4, 6,  // back
               4, 0, 6, 6, 0, 2,  // left
               1, 5, 3, 3, 5, 7,  // right
               2, 3, 6, 6, 3, 7,  // top
               4, 5, 0, 0, 5, 1,  // bottom
        };
        gl.bufferData(gl.ELEMENT_ARRAY_BUFFER, @sizeOf(@TypeOf(indices)), &indices, gl.STATIC_DRAW);
    }


    fn setVertexData(vertices: [stride * n_of_verices]f32) void {
        var vbo: uint = undefined;
        gl.genBuffers(1, &vbo);
        gl.bindBuffer(gl.ARRAY_BUFFER, vbo);

        gl.bufferData(gl.ARRAY_BUFFER, @sizeOf(@TypeOf(vertices)), &vertices, gl.STATIC_DRAW);

        const pos_index: uint = 0;
        gl.enableVertexAttribArray(pos_index);
        gl.vertexAttribPointer(pos_index, 3, gl.FLOAT, gl.FALSE, @sizeOf(f32) * stride, @ptrFromInt(0));

        const color_index: uint = 1;
        gl.enableVertexAttribArray(color_index);
        gl.vertexAttribPointer(color_index, 3, gl.FLOAT, gl.FALSE, @sizeOf(f32) * stride, @ptrFromInt(@sizeOf(f32) * 3));
    }

    fn initVertexData(cube: Cube) [stride * n_of_verices]f32 {
        const scale_trans = Mat4.fromScale(Vec3.set(cube.size)).translate(cube.pos);
        // used 0.5 beacuse this way the len of the edge is 1
        const base_vert_pos: [8]Vec3 = .{
                               Vec3.new(-0.5, -0.5,  0.5),
                               Vec3.new( 0.5, -0.5,  0.5),
                               Vec3.new(-0.5,  0.5,  0.5),
                               Vec3.new( 0.5,  0.5,  0.5),
                               Vec3.new(-0.5, -0.5, -0.5),
                               Vec3.new( 0.5, -0.5, -0.5),
                               Vec3.new(-0.5,  0.5, -0.5),
                               Vec3.new( 0.5,  0.5, -0.5),
        };
        var vertices: [stride * n_of_verices]f32 = undefined;

        var new_vert: Vec3 = undefined;
        const r = cube.color.r;
        const g = cube.color.g;
        const b = cube.color.b;

        for (base_vert_pos, 0..) |vertex, i| {
            new_vert = scale_trans.mulByVec3(vertex);
            vertices[i * stride]     = new_vert.x();
            vertices[i * stride + 1] = new_vert.y();
            vertices[i * stride + 2] = new_vert.z();
            vertices[i * stride + 3] = r;
            vertices[i * stride + 4] = g;
            vertices[i * stride + 5] = b;
        }

        return vertices;
    }

    inline fn bind(self: *RenderableCube) void {
        gl.bindVertexArray(self.vao);
    }

    inline fn unbind() void {
        gl.bindVertexArray(0);
    }
};


