precision highp float;

#include ./simplex.glsl

attribute vec4 seeds;

uniform sampler2D uGpgpu;
uniform float uTime;
uniform float uParticleScale;
uniform float uPixelRatio;
uniform float uIsHovering;
uniform float uPulseProgress;
uniform float uWorldScaleX;
uniform float uWorldScaleY;

varying vec4 vSeeds;
varying float vVelocity;
varying vec2 vLocalPos;
varying vec2 vScreenPos;
varying float vScale;

void main() {
  vec4 pos = texture2D(uGpgpu, uv);
  vSeeds = seeds;

  vec2 worldPos = pos.xy * vec2(uWorldScaleX, uWorldScaleY) * 2.0;

  // Subtle organic drift (very minimal for DNA — keep structure clean)
  float noiseX = snoise(vec3(pos.xy * 5.0, uTime * 0.15 + 10.0)) * 0.003;
  float noiseY = snoise(vec3(pos.xy * 5.0, uTime * 0.15)) * 0.003;
  worldPos.x += noiseX;
  worldPos.y += noiseY;

  vVelocity = pos.w;
  vScale    = pos.z;
  vLocalPos = pos.xy;

  vec4 viewSpace = modelViewMatrix * vec4(vec3(worldPos, 0.0), 1.0);
  gl_Position = projectionMatrix * viewSpace;
  vScreenPos  = gl_Position.xy;

  gl_PointSize = ((vScale * 8.0) * (uPixelRatio * 0.5) * uParticleScale) + (0.5 * uPixelRatio);
}
