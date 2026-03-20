precision highp float;

#include ./simplex.glsl

attribute vec4 seeds;

uniform sampler2D uGpgpu;
uniform float uTime;
uniform float uParticleScale;
uniform float uPixelRatio;
uniform vec2 uRingPos;

varying vec4 vSeeds;
varying float vVelocity;
varying float vScale;
varying vec2 vLocalPos;

void main() {
  vec4 data = texture2D(uGpgpu, uv);
  vec2 pos   = data.xy;
  float scale = data.z;
  float vel   = data.w;

  vSeeds    = seeds;
  vVelocity = vel;
  vScale    = scale;
  vLocalPos = pos;

  // Distance from ring center — modulates noise amplitude
  float dist = length(pos - uRingPos);

  // Two-frequency simplex noise for organic floating
  float noiseX  = snoise(vec3(pos.xy * 10.0, uTime * 0.2 + 100.0));
  float noiseX2 = snoise(vec3(pos.xy * 0.5,  uTime * 0.15 + 87.0));
  float noiseY  = snoise(vec3(pos.xy * 10.0, uTime * 0.2));
  float noiseY2 = snoise(vec3(pos.xy * 0.5,  uTime * 0.15 + 45.0));

  // High-frequency: more agitated far from target
  pos.x += noiseX  * 0.005 * dist;
  pos.y += noiseY  * 0.005 * dist;

  // Low-frequency: slow global drift
  pos.x += noiseX2 * 0.02;
  pos.y += noiseY2 * 0.02;

  vec4 viewSpace = modelViewMatrix * vec4(pos, 0.0, 1.0);
  gl_Position = projectionMatrix * viewSpace;

  gl_PointSize = (vScale * 7.0) * (uPixelRatio * 0.5) * uParticleScale;
}
