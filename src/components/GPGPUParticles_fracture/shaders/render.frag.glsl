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

// Square/shard SDF
float sdBox(vec2 p, vec2 b) {
  vec2 d = abs(p) - b;
  return length(max(d, 0.0)) + min(max(d.x, d.y), 0.0);
}

vec2 rotate(vec2 v, float a) {
  return mat2(cos(a), -sin(a), sin(a), cos(a)) * v;
}

void main() {
  vec2 uv = gl_PointCoord.xy - vec2(0.5);

  // Rotate shard based on seed + velocity (spinning fragments)
  float angle = vSeeds.x * PI * 2.0 + vVelocity * 3.0;
  vec2 ruv = rotate(uv, angle);

  // Irregular shard shape: elongated box
  float aspect = 0.3 + vSeeds.y * 0.4;
  float shard = sdBox(ruv, vec2(0.45, 0.45 * aspect));
  float shardAlpha = smoothstep(0.05, -0.05, shard);

  // Soft glow underneath
  float d = length(uv);
  float glow = exp(-d * d * 8.0) * vVelocity * 1.5;

  // Color: cold → hot on fracture
  float t = smoothstep(0.0, 1.0, vVelocity);
  vec3 col = mix(uColor1, uColor2, t);
  col = mix(col, uColor3, smoothstep(0.5, 1.0, vVelocity));

  // Bright edge highlight on fracture
  float edge = smoothstep(0.0, 0.08, shard) * smoothstep(0.15, 0.0, shard) * vVelocity;
  col = mix(col, vec3(1.0), edge * 0.9 + glow * 0.5);

  float a = uAlpha * shardAlpha * smoothstep(0.0, 0.1, vScale);

  if (a < 0.01) discard;
  gl_FragColor = vec4(col, clamp(a, 0.0, 1.0));
}
