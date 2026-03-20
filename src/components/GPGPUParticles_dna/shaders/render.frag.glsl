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
  float d = length(uv);

  // Soft circle glow
  float circle = exp(-d * d * 12.0);
  // Hard core dot
  float core = smoothstep(0.18, 0.0, d);

  // Color based on position Y (height along helix) + denature (velocity)
  float yNorm = vLocalPos.y + 0.5;  // 0..1
  vec3 baseCol = mix(uColor1, uColor2, yNorm);
  // Denature: shift toward uColor3 (white/hot)
  vec3 col = mix(baseCol, uColor3, vVelocity * 0.8);

  // Bright core
  col = mix(col, vec3(1.0), core * 0.5);

  float a = uAlpha * circle * smoothstep(0.0, 0.1, vScale);

  if (a < 0.01) discard;
  gl_FragColor = vec4(col, clamp(a, 0.0, 1.0));
}
