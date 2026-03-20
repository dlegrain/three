precision highp float;

#include ./simplex.glsl

#define PI 3.1415926535897932384626433832795

uniform vec3 uColor1;
uniform vec3 uColor2;
uniform vec3 uColor3;
uniform vec2 uMousePos;
uniform vec2 uRez;
uniform float uAlpha;
uniform float uTime;
uniform int uColorScheme;

varying vec4 vSeeds;
varying vec2 vScreenPos;
varying vec2 vLocalPos;
varying float vScale;
varying float vVelocity;

void main() {
  // Soft circle shape
  vec2 uv = gl_PointCoord.xy - vec2(0.5);
  float dist = length(uv);
  float circle = smoothstep(0.5, 0.2, dist);

  // Color driven by ripple velocity (wave intensity): calm grey → vivid colors
  float v = clamp(vVelocity * 1.5, 0.0, 1.0);
  float h = 0.5;
  vec3 col = mix(
    mix(uColor1, uColor2, v / h),
    mix(uColor2, uColor3, (v - h) / (1.0 - h)),
    step(h, v)
  );
  // Calm state: soft grey-blue
  col = mix(vec3(0.75, 0.78, 0.85), col, v);

  float a = uAlpha * circle * smoothstep(0.0, 0.15, vScale);

  if (a < 0.01) discard;

  gl_FragColor = vec4(col, clamp(a, 0.0, 1.0));
}
