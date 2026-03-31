const za = @import("zalgebra");
const Quat = za.Quat;
const Vec3 = za.Vec3;

pub const Trackball = struct {
    last_q: Quat,
    curr_q: Quat,
    start: ?Vec3,
    width: f32,
    height: f32,

    pub fn init(width: f32, height: f32) Trackball {
        return .{
           .last_q = Quat.identity(),
           .curr_q = Quat.identity(),
           .start = null,
           .width = width,
           .height = height,
        };
    }

    pub fn mouseDown(self: *Trackball, mouse_x: f32, mouse_y: f32) void {
        self.start = self.project(mouse_x, mouse_y);
    }

    pub fn mouseMove(self: *Trackball,  mouse_x: f32, mouse_y: f32) void {
        const start = self.start orelse return;
        const curr_pos = self.project(mouse_x, mouse_y);
        self.curr_q = quatFromUnitVectors(curr_pos, start);
    }

    pub fn mouseUp(self: *Trackball) void {
        if (self.start == null) return;

        self.last_q = self.last_q.mul(self.curr_q);
        self.curr_q = Quat.identity();
        self.start = null;
    }

    pub fn getRotation(self: *Trackball) Quat {
        return self.last_q.mul(self.curr_q);
    }

    pub fn resize(self: *Trackball, width: f32, height: f32) void {
        self.width = width;
        self.height = height;
    }

    // This function claculate the projection of coordinates of the mouse on the trackball surfece
    // The trackball surfece is:
    // - A Sphere if the magnitude of the (point) vector is less or equal than r/√2
    // - An Hyperbola otherwise
    // NOTE: This function normalize the resulting vector
    fn project(self: *Trackball, mouse_x: f32, mouse_y: f32) Vec3 {
        const r: f32 = 1.0;

        // This -1 because i need width-1/something (or height) to be equal to 1 and 0/something to be 0
        const resolution = @min(self.width, self.height) - 1;       // #
                                                                    // |  This is here to tranlslate form screen coord to cartesian coord
        const x =   (2 * mouse_x - (self.width  - 1)) / resolution; // |
        const y = - (2 * mouse_y - (self.height - 1)) / resolution; // #

        // d_sq means d²
        const d_sq = x * x + y * y;

        const z = if (d_sq * 2 <= r * r)
            @sqrt(r * r - d_sq)
        else
            ((r * r) / 2.0) / @sqrt(d_sq);

        return Vec3.new(x, y, z).norm();
    }
};

// This function requires normilezed vectors
fn quatFromUnitVectors(p: Vec3, q: Vec3) Quat {
    // When |p| = |q| = 1, the formula simplifies:
    //   w     = dot(p, q) + 1
    //   (xyz) = cross(p, q)
    const quat = Quat.fromVec3(p.dot(q) + 1.0, p.cross(q));

    return if (quat.length() >= 1e-8) quat.norm() else Quat.identity();
}
