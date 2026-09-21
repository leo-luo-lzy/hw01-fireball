#version 300 es

//This is a vertex shader. While it is called a "shader" due to outdated conventions, this file
//is used to apply matrix transformations to the arrays of vertex data passed to it.
//Since this code is run on your GPU, each vertex is transformed simultaneously.
//If it were run on your CPU, each vertex would have to be processed in a FOR loop, one at a time.
//This simultaneous transformation allows your program to run much faster, especially when rendering
//geometry with millions of vertices.

uniform mat4 u_Model;       // The matrix that defines the transformation of the
                            // object we're rendering. In this assignment,
                            // this will be the result of traversing your scene graph.

uniform mat4 u_ModelInvTr;  // The inverse transpose of the model matrix.
                            // This allows us to transform the object's normals properly
                            // if the object has been non-uniformly scaled.

uniform mat4 u_ViewProj;    // The matrix that defines the camera's transformation.
                            // We've written a static matrix for you to use for HW2,
                            // but in HW3 you'll have to generate one yourself
uniform float u_Time;
uniform float u_NoiseStrength;
uniform float u_TailLength;
uniform int u_Octaves;

in vec4 vs_Pos;             // The array of vertex positions passed to the shader

in vec4 vs_Nor;             // The array of vertex normals passed to the shader

in vec4 vs_Col;             // The array of vertex colors passed to the shader.

out vec4 fs_Nor;            // The array of normals that has been transformed by u_ModelInvTr. This is implicitly passed to the fragment shader.
out vec4 fs_LightVec;       // The direction in which our virtual light lies, relative to each vertex. This is implicitly passed to the fragment shader.
out vec4 fs_Col;            // The color of each vertex. This is implicitly passed to the fragment shader.
out float fs_Noise;
out float fs_TailMask;
out float fs_ColorMask;

const vec4 lightPos = vec4(5, 5, 3, 1); //The position of our virtual light, which is used to compute the shading of
                                        //the geometry in the fragment shader.

vec3 randomGradient3D(vec3 p) {
    float r1 = fract(
        sin(dot(p, vec3(127.1, 311.7, 74.7))) * 43758.5453
    );
    float r2 = fract(
        sin(dot(p, vec3(269.5, 183.3, 246.1))) * 43758.5453
    );

    float z = r1 * 2.0 - 1.0;
    float phi = r2 * 6.28318530718;
    float radius = sqrt(max(0.0, 1.0 - z * z));

    return vec3(radius * cos(phi), radius * sin(phi), z);
}

float perlin3D(vec3 p) {
    vec3 i = floor(p);
    vec3 f = fract(p);

    vec3 g000 = randomGradient3D(i + vec3(0, 0, 0));
    vec3 g100 = randomGradient3D(i + vec3(1, 0, 0));
    vec3 g010 = randomGradient3D(i + vec3(0, 1, 0));
    vec3 g110 = randomGradient3D(i + vec3(1, 1, 0));
    vec3 g001 = randomGradient3D(i + vec3(0, 0, 1));
    vec3 g101 = randomGradient3D(i + vec3(1, 0, 1));
    vec3 g011 = randomGradient3D(i + vec3(0, 1, 1));
    vec3 g111 = randomGradient3D(i + vec3(1, 1, 1));

    float v000 = dot(g000, f - vec3(0, 0, 0));
    float v100 = dot(g100, f - vec3(1, 0, 0));
    float v010 = dot(g010, f - vec3(0, 1, 0));
    float v110 = dot(g110, f - vec3(1, 1, 0));
    float v001 = dot(g001, f - vec3(0, 0, 1));
    float v101 = dot(g101, f - vec3(1, 0, 1));
    float v011 = dot(g011, f - vec3(0, 1, 1));
    float v111 = dot(g111, f - vec3(1, 1, 1));

    vec3 u = f * f * f * (f * (f * 6.0f - 15.0f) + 10.0f);

    float mix00 = mix(v000, v100, u.x);
    float mix10 = mix(v010, v110, u.x);
    float mix01 = mix(v001, v101, u.x);
    float mix11 = mix(v011, v111, u.x);

    float mix0 = mix(mix00, mix10, u.y);
    float mix1 = mix(mix01, mix11, u.y);

    return mix(mix0, mix1, u.z);
}

float fbmPerlin3D(vec3 p,int octaves,float lacunarity,float gain) {
    float sum = 0.0;
    float amp = 1.0;
    float norm = 0.0;

    for (int i = 0; i < octaves; ++i) {
        sum += amp * perlin3D(p);
        norm += amp;
        p *= lacunarity;
        amp *= gain;
    }
    return sum /max(norm, 1e-6);
}

void main()
{
    fs_Col = vs_Col;                         // Pass the vertex colors to the fragment shader for interpolation

    mat3 invTranspose = mat3(u_ModelInvTr);
    fs_Nor = vec4(invTranspose * vec3(vs_Nor), 0);          // Pass the vertex normals to the fragment shader for interpolation.
                                                            // Transform the geometry's normals by the inverse transpose of the
                                                            // model matrix. This is necessary to ensure the normals remain
                                                            // perpendicular to the surface after the surface is transformed by
                                                            // the model matrix.

    float wavex = sin(vs_Pos.x * 3.0 + u_Time);
    float wavey = sin(vs_Pos.y * 5.0 - u_Time * 0.8);
    float wavez = sin(vs_Pos.z * 4.0 + u_Time * 1.2);
    float largeDisplacement = 0.25*(wavex+wavey+wavez)/3.0;
    vec3 displacedPos = vs_Pos.xyz + normalize(vs_Nor.xyz) * largeDisplacement;
    vec3 noisePos = vs_Pos.xyz * 6.0+ vec3(0.2, -0.35, 0.15) * u_Time;
    float detail = fbmPerlin3D(noisePos, u_Octaves, 2.0, 0.55);

    float smallDisplacement = u_NoiseStrength * detail;

    float totalDisplacement = largeDisplacement + smallDisplacement;

    vec3 tailDirection = normalize(vec3(1.0, 1.0, 0.0));
    float alongTail = dot(normalize(vs_Pos.xyz), tailDirection);
    float tailMask = smoothstep(-0.5 , 0.9, alongTail);
    float colorMask = smoothstep(-0.95, 0.95, alongTail);
    fs_TailMask = colorMask;
    fs_ColorMask = colorMask;
    float shapeStrength = mix(0.35, 1.0, tailMask);
    float surfaceDisplacement = totalDisplacement * shapeStrength;
    fs_Noise = surfaceDisplacement;
    displacedPos = vs_Pos.xyz + normalize(vs_Nor.xyz) *surfaceDisplacement;

    vec3 axial = tailDirection * dot(displacedPos, tailDirection);
    vec3 radial = displacedPos - axial;
    float shrink = mix(1.0, 0.3, tailMask);
    float tailLength = u_TailLength * (1.0 + 0.6 * detail);
    displacedPos = axial + radial * shrink;
    displacedPos += tailDirection * tailMask * tailLength;

    vec4 modelposition = u_Model * vec4(displacedPos, 1.0);   // Temporarily store the transformed vertex positions for use below

    fs_LightVec = lightPos - modelposition;  // Compute the direction in which the light source lies

    gl_Position = u_ViewProj * modelposition;// gl_Position is a built-in variable of OpenGL which is
                                             // used to render the final positions of the geometry's vertices
}
