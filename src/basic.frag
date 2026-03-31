#version 410

in vec3 vColor;
in vec3 vWorldPos;

// Outputs to COLOR_ATTACHMENT0
layout (location = 0) out vec4 color;

void main(void) {
    // Compute flat face normal from screen-space derivatives
    vec3 normal = normalize(cross(dFdx(vWorldPos), dFdy(vWorldPos)));

    // Simple directional light pointing down-left-forward
    vec3 lightDir = normalize(vec3(-0.3, 1.0, 0.5));

    // Diffuse: how much the face points toward the light
    float diffuse = max(dot(normal, lightDir), 0.0);

    // Ambient so shadowed faces aren't pure black
    float ambient = 0.15;

    color = vec4(vColor * (ambient + diffuse * (1-ambient)), 1.0);
}
