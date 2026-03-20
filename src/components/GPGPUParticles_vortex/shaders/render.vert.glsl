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

  // Sim → world
  vec2 worldPos = pos.xy * vec2(uWorldScaleX, uWorldScaleY) * 2.0;

  // Subtle swirl noise displacement
  float noiseX = snoise(vec3(pos.xy * 8.0, uTime * 0.3 + 10.0));
  float noiseY = snoise(vec3(pos.xy * 8.0, uTime * 0.3));

  // In vortex (high velocity), amplify swirl displacement
  float swirl = mix(0.015, 0.04, pos.w);
  worldPos.x += noiseX * swirl;
  worldPos.y += noiseY * swirl;

  vVelocity = pos.w;
  vScale    = pos.z;
  vLocalPos = pos.xy;

  vec4 viewSpace = modelViewMatrix * vec4(vec3(worldPos, 0.0), 1.0);
  gl_Position = projectionMatrix * viewSpace;
  vScreenPos  = gl_Position.xy;

  // In vortex: particles shrink (speed blur illusion) + bright core
  float sizeBoost = 1.0 + pos.w * 1.5;
  gl_PointSize = ((vScale * 6.0) * (uPixelRatio * 0.5) * uParticleScale * sizeBoost) + (0.3 * uPixelRatio);
}
