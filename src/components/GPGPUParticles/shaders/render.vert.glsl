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

  float noiseX  = snoise(vec3(vec2(pos.xy * 10.), uTime * .2 + 100.));
  float noiseY  = snoise(vec3(vec2(pos.xy * 10.), uTime * .2));
  float noiseX2 = snoise(vec3(vec2(pos.xy * .5),  uTime * .15 + 45.));
  float noiseY2 = snoise(vec3(vec2(pos.xy * .5),  uTime * .15 + 87.));

  float cDist   = length(pos.xy);
  float progress = uPulseProgress;
  float t = smoothstep(progress - .25, progress, cDist) - smoothstep(progress, progress + .25, cDist);
  t *= smoothstep(1., .0, cDist);
  worldPos *= 1. + (t * .02);

  float dist = smoothstep(0., 0.9, pos.w);
  dist = mix(0., dist, uIsHovering);

  worldPos.y += noiseY  * 0.005 * dist;
  worldPos.x += noiseX  * 0.005 * dist;
  worldPos.y += noiseY2 * 0.02;
  worldPos.x += noiseX2 * 0.02;

  vVelocity = pos.w;
  vScale    = pos.z;
  vLocalPos = pos.xy;

  vec4 viewSpace = modelViewMatrix * vec4(vec3(worldPos, 0.), 1.0);
  gl_Position = projectionMatrix * viewSpace;
  vScreenPos  = gl_Position.xy;

  float minScale = .25;
  minScale += float(uColorScheme) * .75;
  gl_PointSize = ((vScale * 7.) * (uPixelRatio * 0.5) * uParticleScale) + (minScale * uPixelRatio);
}
