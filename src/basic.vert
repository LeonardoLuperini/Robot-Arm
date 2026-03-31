#version 410

layout (location = 0) in vec3 aPosition;
layout (location = 1) in vec3 aColor;
out vec3 vColor;
out vec3 vWorldPos;

uniform mat4 uProj;
uniform mat4 uView;

void main(void) {
    gl_Position = uProj * uView * vec4(aPosition, 1.0);
    vWorldPos = aPosition;
    vColor = aColor;
}
