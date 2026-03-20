precision highp float;

#include ./simplex.glsl

uniform vec3 uColor1;
uniform vec3 uColor2;
uniform vec3 uColor3;
uniform float uAlpha;
uniform float uTime;
uniform vec2 uRingPos;

varying vec4 vSeeds;
varying float vVelocity;
varying float vScale;
varying vec2 vLocalPos;

// Signed distance — rounded box
float sdRoundBox(in vec2 p, in vec2 b, in vec4 r) {
  r.xy = (p.x > 0.0) ? r.xy : r.zw;
  r.x  = (p.y > 0.0) ? r.x  : r.y;
  vec2 q = abs(p) - b + r.x;
  return min(max(q.x, q.y), 0.0) + length(max(q, 0.0)) - r.x;
}

vec2 rotate(vec2 v, float a) {
  float s = sin(a);
  float c = cos(a);
  return mat2(c, s, -s, c) * v;
}

void main() {
  // Noise-based angle for teardrop orientation
  float noiseAngle = snoise(vec3(vLocalPos * 10.0 + vec2(18.4924, 72.9744), uTime * 0.85));
  float noiseColor = snoise(vec3(vLocalPos * 2.0  + vec2(74.664, 91.556),   uTime * 0.5));
  noiseColor = (noiseColor + 1.0) * 0.5;

  // Orient teardrop tangent to ring
  float angle = atan(vLocalPos.y - uRingPos.y, vLocalPos.x - uRingPos.x);
  vec2 uv = gl_PointCoord.xy - vec2(0.5);
  uv.y *= -1.0;
  uv = rotate(uv, -angle + (noiseAngle * 0.5));

  // 3-stop color gradient driven by noise-colored velocity
  float h = 0.8;
  float progress = smoothstep(0.0, 0.75, pow(noiseColor, 2.0));
  vec3 col = mix(
    mix(uColor1, uColor2, progress / h),
    mix(uColor2, uColor3, (progress - h) / (1.0 - h)),
    step(h, progress)
  );

  // Teardrop shape via sdRoundBox
  float rounded = sdRoundBox(uv, vec2(0.5, 0.2), vec4(0.25));
  rounded = smoothstep(0.1, 0.0, rounded);

  float a = uAlpha * rounded * smoothstep(0.0, 0.2, vScale);

  if (a < 0.01) discard;

  gl_FragColor = vec4(col, clamp(a, 0.0, 1.0));
}
