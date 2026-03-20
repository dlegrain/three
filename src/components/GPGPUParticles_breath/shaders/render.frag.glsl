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
  vec2 uv = gl_PointCoord.xy - vec2(0.5);
  float d = length(uv);

  // Soft gaussian-like circle — no hard edge
  float circle = exp(-d * d * 20.0);

  // Color: breathe between cool (uColor1) and warm (uColor2/3)
  // vScale encodes breath phase (0.3 → 0.9), vVelocity encodes cursor counter-zone
  float breathPhase = smoothstep(0.3, 0.9, vScale);
  vec3 breathColor  = mix(uColor1, uColor2, breathPhase);

  // Counter-phase zone near cursor glows with uColor3 (warm/yellow)
  vec3 col = mix(breathColor, uColor3, vVelocity * 0.8);

  // Overall opacity follows scale — fades in/out with breath
  float a = uAlpha * circle * smoothstep(0.1, 0.5, vScale);

  if (a < 0.01) discard;

  gl_FragColor = vec4(col, clamp(a, 0.0, 1.0));
}
