#version 300 es

// This is a fragment shader. If you've opened this file first, please
// open and read lambert.vert.glsl before reading on.
// Unlike the vertex shader, the fragment shader actually does compute
// the shading of geometry. For every pixel in your program's output
// screen, the fragment shader is run for every bit of geometry that
// particular pixel overlaps. By implicitly interpolating the position
// data passed into the fragment shader by the vertex shader, the fragment shader
// can compute what color to apply to its pixel based on things like vertex
// position, light position, and vertex color.
precision highp float;

uniform vec4 u_Color; // The color with which to render this instance of geometry.
uniform float u_Time;

// These are the interpolated values out of the rasterizer, so you can't know
// their specific values without knowing the vertices that contributed to them
in vec4 fs_Nor;
in vec4 fs_LightVec;
in vec4 fs_Col;
in float fs_Noise;
in float fs_ColorMask;

out vec4 out_Col; // This is the final output color that you will see on your
                  // screen for the pixel that is currently being processed.

void main()
{
    // Material base color (before shading)
        vec4 diffuseColor = u_Color;

        float heat = 1.0 - 0.95 * fs_ColorMask;

        float noiseStrength = mix(1.0, 3.0, fs_ColorMask);
        heat += noiseStrength * fs_Noise;

        heat += 0.03 * sin(u_Time * 2.0);
        heat = clamp(heat, 0.0, 1.0);

        vec3 darkRed = vec3(0.19, 0.007, 0.0);
        vec3 orange = vec3(1.0, 0.16, 0.01);
        vec3 yellow = vec3(1.0, 0.78, 0.09);
        vec3 White = vec3(1.0, 0.97, 0.85);

        vec3 color = mix(darkRed, orange, smoothstep(0.1, 0.5, heat));
        color = mix(color, yellow, smoothstep(0.4, 0.85, heat));
        color = mix(color, White, smoothstep(0.75, 0.95, heat));


        // Calculate the diffuse term for Lambert shading
        // float diffuseTerm = dot(normalize(fs_Nor), normalize(fs_LightVec));
        // Avoid negative lighting values
        // diffuseTerm = clamp(diffuseTerm, 0, 1);

        float ambientTerm = 0.2;

        // float lightIntensity = diffuseTerm + ambientTerm;   //Add a small float value to the color multiplier
                                                            //to simulate ambient lighting. This ensures that faces that are not
                                                            //lit by our point light are not completely black.

        // Compute final shaded color
        // out_Col = vec4(diffuseColor.rgb * lightIntensity, diffuseColor.a);
        out_Col = vec4(color,1.0);
}
