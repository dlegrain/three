precision highp float;

#include ./simplex.glsl

attribute vec4 seeds;

uniform sampler2D uGpgpu;
uniform float uTime;
uniform float uParticleScale;
uniform float uPixelRatio;
uniform int uColorScheme;
uniform float uIsHovering;
uniform float uPulseProgress;
uniform float uWorldScaleX;   // world half-width  (e.g. 2.006)
uniform float uWorldScaleY;   // world half-height (e.g. 1.128)

varying vec4 vSeeds;
varying float vVelocity;
varying vec2 vLocalPos;
varying vec2 vScreenPos;
varying float vScale;

void main() {
  vec4 pos = texture2D(uGpgpu, uv);
  vSeeds = seeds;

  // Scale from sim space [-0.5,0.5] → world space
  vec2 worldPos = pos.xy * vec2(uWorldScaleX, uWorldScaleY) * 2.0;

  // Gentle slow drift via low-freq noise (not hover-dependent — always active)
  float noiseX2 = snoise(vec3(vec2(pos.xy * .5), uTime * .08 + 45.));
  float noiseY2 = snoise(vec3(vec2(pos.xy * .5), uTime * .08 + 87.));
  worldPos.y += noiseY2 * 0.008;
  worldPos.x += noiseX2 * 0.008;

  vVelocity = pos.w;
  vScale    = pos.z;
  vLocalPos = pos.xy;

  vec4 viewSpace = modelViewMatrix * vec4(vec3(worldPos, 0.), 1.0);
  gl_Position = projectionMatrix * viewSpace;
  vScreenPos  = gl_Position.xy;

  // Point size driven by ripple scale (pos.z) — peaks when wave passes
  gl_PointSize = ((vScale * 5.0) * (uPixelRatio * 0.5) * uParticleScale) + (0.8 * uPixelRatio);
}
