#version 300 es

precision highp float;

out vec4 out_Col;

float rand(vec2 p) {
    return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

void main() {
      float cellSize = 32.0;
      vec2 cell = floor(gl_FragCoord.xy / cellSize);
      vec2 local = fract(gl_FragCoord.xy / cellSize) * cellSize;

      vec2 randomPosition = vec2(rand(cell + vec2(23.4, 17.3)),rand(cell + vec2(3.71, 29.1)));

      vec2 centerstar = mix(vec2(0.15), vec2(0.85), randomPosition)* cellSize;
      float enabled = step(0.45, rand(cell));

      float radius = mix(0.8, 2.2,rand(cell + vec2(57.3, 71.9)));

      float brightness = mix(0.2, 1.0,rand(cell + vec2(97.6, 47.3)));

      float distanceToStar = length(local - centerstar);

      float star = 1.0 - smoothstep(radius - 0.7,radius + 0.7,distanceToStar);

      vec3 color = vec3(0.005, 0.001, 0.05);
      color += vec3(0.75, 0.95, 1.0) * star * brightness * enabled;
      out_Col = vec4(color, 1.0);
  }
