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

  // Hard star core + soft glow halo
  float core = smoothstep(0.18, 0.0, d);
  float halo = smoothstep(0.5, 0.0, d) * 0.4;
  float shape = core + halo;

  // Color: default dark blue-grey, brightens toward color1/color2 when near cursor
  float proximity = clamp(vVelocity * 2.0, 0.0, 1.0);
  vec3 baseColor  = mix(vec3(0.55, 0.58, 0.72), uColor1, proximity * 0.7);
  baseColor = mix(baseColor, uColor2, smoothstep(0.5, 1.0, proximity) * 0.6);

  float a = uAlpha * shape * smoothstep(0.1, 0.4, vScale);

  if (a < 0.01) discard;

  gl_FragColor = vec4(baseColor, clamp(a, 0.0, 1.0));
}
