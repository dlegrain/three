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

  // Inner bright core (extra glow in vortex)
  float core = exp(-d * d * 60.0) * vVelocity * 2.0;

  // Color: velocity drives the gradient
  // Low velocity = uColor1 (rest), high = uColor2/3 (vortex)
  float t = smoothstep(0.0, 1.0, vVelocity);
  vec3 col = mix(uColor1, uColor2, t);
  col = mix(col, uColor3, smoothstep(0.6, 1.0, vVelocity));

  // Add white core flare
  col = mix(col, vec3(1.0), core * 0.8);

  float a = uAlpha * circle * smoothstep(0.0, 0.15, vScale);

  if (a < 0.01) discard;
  gl_FragColor = vec4(col, clamp(a, 0.0, 1.0));
}
