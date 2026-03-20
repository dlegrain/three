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

varying vec4 vSeeds;
varying vec2 vScreenPos;
varying vec2 vLocalPos;
varying float vScale;
varying float vVelocity;

void main() {
  vec2 uv = gl_PointCoord.xy - vec2(0.5);

  // Soft circle (Gaussian falloff)
  float d = length(uv);
  float circle = exp(-d * d * 14.0);

  // Subtle core highlight (no color shift, just brightness)
  float core = exp(-d * d * 60.0) * vVelocity * 0.5;

  // Color: only blend between color1 and color2 — never reach color3
  float t = smoothstep(0.0, 1.0, vVelocity) * 0.7;
  vec3 col = mix(uColor1, uColor2, t);

  // Slight brightness boost at core, no hue change
  col = mix(col, col * 1.4, core);

  float a = uAlpha * circle * smoothstep(0.0, 0.15, vScale);

  if (a < 0.01) discard;
  gl_FragColor = vec4(col, clamp(a, 0.0, 1.0));
}
