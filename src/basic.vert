#version 410

layout (location = 0) in vec2 aPosition;
layout (location = 1) in vec3 aColor;
out vec3 vColor;

uniform mat4 uProj;

void main(void)
{
    gl_Position = uProj * vec4(aPosition, 0.0, 1.0);
    vColor = aColor;
}
