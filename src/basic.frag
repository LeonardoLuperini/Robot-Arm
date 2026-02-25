#version 410

in vec3 vColor;

// Outputs to COLOR_ATTACHMENT0
layout (location = 0) out vec4 color;

void main(void) {
    color = vec4(vColor, 1.0);
}
