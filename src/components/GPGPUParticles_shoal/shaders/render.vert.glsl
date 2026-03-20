precision highp float;

#include ./simplex.glsl

attribute vec4 seeds;

uniform sampler2D uGpgpu;
uniform float uTime;
uniform float uParticleScale;
uniform float uPixelRatio;
uniform vec2 uRingPos;
uniform float uIsHovering;

varying vec4 vSeeds;
varying float vVelocity;
varying float vScale;
varying vec2 vLocalPos;
varying vec2 vMotionDir;  // direction of movement for teardrop orientation

void main() {
  vec4 data  = texture2D(uGpgpu, uv);
  vec2 pos   = data.xy;
  float scale = data.z;
  float vel   = data.w;

  vSeeds    = seeds;
  vVelocity = vel;
  vScale    = scale;
  vLocalPos = pos;

  // Distance from ring center
  float dist = length(pos - uRingPos);

  // 3D Simplex — high frequency (fine jitter)
  float noiseX  = snoise(vec3(pos.xy * 10.0, uTime * 0.2 + 100.0));
  float noiseY  = snoise(vec3(pos.xy * 10.0, uTime * 0.2));

  // 3D Simplex — low frequency (slow drift)
  float noiseX2 = snoise(vec3(pos.xy * 0.5,  uTime * 0.15 + 87.0));
  float noiseY2 = snoise(vec3(pos.xy * 0.5,  uTime * 0.15 + 45.0));

  float hoverAmp = 1.0 + uIsHovering * 1.5;
  pos.x += noiseX  * 0.005 * dist * hoverAmp;
  pos.y += noiseY  * 0.005 * dist * hoverAmp;
  pos.x += noiseX2 * 0.02;
  pos.y += noiseY2 * 0.02;

  // Motion direction for frag shader teardrop orientation
  vMotionDir = normalize(vec2(noiseX + noiseX2, noiseY + noiseY2) + vec2(0.0001));

  vec4 viewSpace = modelViewMatrix * vec4(pos, 0.0, 1.0);
  gl_Position = projectionMatrix * viewSpace;

  float sizeVar = 0.5 + seeds.x;
  gl_PointSize = (vScale * 7.0) * (uPixelRatio * 0.5) * uParticleScale * sizeVar;
}
