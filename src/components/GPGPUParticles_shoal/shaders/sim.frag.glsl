precision highp float;

#include ./simplex.glsl

uniform sampler2D uPosition;
uniform sampler2D uPosRefs;
uniform vec2 uRingPos;
uniform vec2 uMousePos;
uniform float uTime;
uniform float uRingRadius;
uniform float uRingWidth;
uniform float uRingWidth2;
uniform float uRingDisplacement;
uniform float uIsHovering;

vec2 hash2(vec2 p) {
  p = vec2(dot(p, vec2(2127.1, 81.17)), dot(p, vec2(1269.5, 283.37)));
  return fract(sin(p) * 43758.5453);
}

vec2 rotate2D(vec2 v, float a) {
  float s = sin(a); float c = cos(a);
  return vec2(v.x * c - v.y * s, v.x * s + v.y * c);
}

void main() {
  vec2 simTexCoords = gl_FragCoord.xy / vec2(32.0, 32.0);
  vec4 pFrame = texture2D(uPosition, simTexCoords);
  float scale    = pFrame.z;
  float velocity = pFrame.w;

  vec2 refPos = texture2D(uPosRefs, simTexCoords).xy;
  float time  = uTime * 0.5;

  float seed  = hash2(simTexCoords).x;
  float seed2 = hash2(simTexCoords).y;

  vec2 pos = pFrame.xy;

  // Lifetime
  float lifeEnd  = 3. + sin(seed2 * 100.) * 1.;
  float lifeTime = mod((seed * 100.) + time, lifeEnd);

  if (lifeTime < 0.01) {
    pos = refPos;
    scale = 0.;
  }

  // ── Murmuration hover behavior ──────────────────────────────────────────
  // Each particle orbits the cursor at a personal offset angle + radius,
  // creating the shoal/flock effect where particles swirl and reorganize.
  float hoverStrength = smoothstep(0.0, 1.0, uIsHovering);

  // Personal orbit: each particle has a fixed angle slot + small radius variation
  float personalAngle  = seed  * 6.2832;               // evenly-ish spread around the ring
  float personalRadius = 0.08 + seed2 * 0.07;          // tight orbit: 0.08 → 0.15
  float orbitSpeed     = 0.5 + seed * 0.5;             // slow rotation: 0.5 → 1.0 rad/s

  // The ring rotates AND the cursor moves → shoal follows
  float currentAngle = personalAngle + uTime * orbitSpeed * 0.3;
  vec2 orbitOffset   = vec2(cos(currentAngle), sin(currentAngle)) * personalRadius;
  vec2 orbitTarget   = uMousePos + orbitOffset;

  // Blend between resting ring (centered on origin) and orbit around cursor
  vec2 targetPos = mix(refPos, orbitTarget, hoverStrength);

  float distRadius = mix(0.15, 0.05, hoverStrength);
  float dist = length(targetPos - pos);

  vec2 direction = normalize(targetPos - pos + vec2(0.0001));

  // Tangential swirl so particles arc gracefully into orbit
  vec2 tangent = rotate2D(direction, 1.5708);
  float swirlStrength = smoothstep(0.3, 0.0, dist) * hoverStrength * 0.5;
  // Stronger pull when hovering so the ring snaps to cursor quickly
  float pullStrength = mix(1.0, 2.5, hoverStrength);
  pos += (direction + tangent * swirlStrength) * smoothstep(distRadius, 0., dist) * pullStrength;

  // Variable size with hover growth
  float sizeVariation = 0.5 + seed * 1.0;
  float targetScale   = (smoothstep(.01, 0.5, lifeTime) - smoothstep(0.5, 1., lifeTime / lifeEnd)) * sizeVariation;

  // Particles near the cursor grow when hovering
  float mouseProximity = smoothstep(0.35, 0.0, length(pos - uMousePos));
  targetScale += mouseProximity * hoverStrength * 0.6;

  scale += (targetScale - scale) * 0.08;

  // Ring breathing displacement (persists at all times)
  vec2 curentPos = refPos;
  float noise0   = snoise(vec3(curentPos.xy * 0.2 + vec2(18.4924, 72.9744), time * 0.5));
  float dist1    = distance(curentPos.xy + (noise0 * 0.005), uRingPos);
  float ringDist = distance(curentPos.xy, uRingPos);

  float t2 = smoothstep(uRingRadius - (uRingWidth2 * 2.0), uRingRadius, ringDist)
           - smoothstep(uRingRadius, uRingRadius + uRingWidth2, dist1);
  t2 = pow(t2, 3.0);

  float noise1 = snoise(vec3(curentPos.xy * 4.0  + vec2(88.494,  32.4397),  time * 0.35));
  float noise2 = snoise(vec3(curentPos.xy * 4.0  + vec2(50.904, 120.947),   time * 0.35));
  float noise3 = snoise(vec3(curentPos.xy * 20.0 + vec2(18.4924, 72.9744),  time * 0.5));
  float noise4 = snoise(vec3(curentPos.xy * 20.0 + vec2(50.904, 120.947),   time * 0.5));
  vec2 disp = vec2(noise1, noise2) * 0.03 + vec2(noise3, noise4) * 0.005;

  disp.x += sin((refPos.x * 20.0) + (time * 4.0)) * 0.02 * clamp(ringDist, 0.0, 1.0);
  disp.y += cos((refPos.y * 20.0) + (time * 3.0)) * 0.02 * clamp(ringDist, 0.0, 1.0);

  // Ring displacement attenuated when hovering (particles leave their rings)
  pos -= (uRingPos - (curentPos + disp)) * pow(t2, 0.75) * uRingDisplacement * (1.0 - hoverStrength * 0.8);

  vec2 finalPos = pos + disp * (0.5 - hoverStrength * 0.3);
  velocity = lifeTime / lifeEnd;

  gl_FragColor = vec4(finalPos, scale, velocity);
}
