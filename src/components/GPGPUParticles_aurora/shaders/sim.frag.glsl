precision highp float;

#include ./simplex.glsl

uniform sampler2D uPosition;
uniform sampler2D uPosRefs;
uniform vec2 uRingPos;
uniform float uTime;
uniform float uRingRadius;
uniform float uRingWidth;
uniform float uRingWidth2;
uniform float uRingDisplacement;

vec2 hash(vec2 p) {
  p = vec2(dot(p, vec2(2127.1, 81.17)), dot(p, vec2(1269.5, 283.37)));
  return fract(sin(p) * 43758.5453);
}

void main() {
  vec2 simTexCoords = gl_FragCoord.xy / vec2(256.0, 256.0);
  vec4 pFrame = texture2D(uPosition, simTexCoords);
  float scale    = pFrame.z;
  float velocity = pFrame.w;

  vec2 refPos = texture2D(uPosRefs, simTexCoords).xy;
  float time  = uTime * 0.5;

  // Per-particle stable seeds
  float seed  = hash(simTexCoords).x;
  float seed2 = hash(simTexCoords).y;

  vec2 pos = pFrame.xy;

  // Lifetime
  float lifeEnd  = 3. + sin(seed2 * 100.) * 1.;
  float lifeTime = mod((seed * 100.) + time, lifeEnd);

  vec2 targetPos = refPos;
  float distRadius = 0.15;
  float dist = length(targetPos - pos);

  // Respawn at birth
  if (lifeTime < 0.01) {
    pos = refPos;
    scale = 0.;
  }

  // Attraction toward target
  vec2 direction = normalize(targetPos - pos);
  pos += direction * smoothstep(distRadius, 0., dist);

  // Scale: fade in → plateau → fade out
  float targetScale = smoothstep(.01, 0.5, lifeTime) - smoothstep(0.5, 1., lifeTime / lifeEnd);
  scale += (targetScale - scale) * 0.1;

  // Multi-scale displacement noise (ring breathing)
  vec2 curentPos = refPos;
  float noise0 = snoise(vec3(curentPos.xy * 0.2 + vec2(18.4924, 72.9744), time * 0.5));
  float dist1  = distance(curentPos.xy + (noise0 * 0.005), uRingPos);
  float ringDist = distance(curentPos.xy, uRingPos);

  float t  = smoothstep(uRingRadius - (uRingWidth  * 2.0), uRingRadius, ringDist) - smoothstep(uRingRadius, uRingRadius + uRingWidth,  dist1);
  float t2 = smoothstep(uRingRadius - (uRingWidth2 * 2.0), uRingRadius, ringDist) - smoothstep(uRingRadius, uRingRadius + uRingWidth2, dist1);
  t2 = pow(t2, 3.0);

  float noise1 = snoise(vec3(curentPos.xy * 4.0  + vec2(88.494,  32.4397),  time * 0.35));
  float noise2 = snoise(vec3(curentPos.xy * 4.0  + vec2(50.904, 120.947),   time * 0.35));
  float noise3 = snoise(vec3(curentPos.xy * 20.0 + vec2(18.4924, 72.9744),  time * 0.5));
  float noise4 = snoise(vec3(curentPos.xy * 20.0 + vec2(50.904, 120.947),   time * 0.5));
  vec2 disp = vec2(noise1, noise2) * 0.03 + vec2(noise3, noise4) * 0.005;

  disp.x += sin((refPos.x * 20.0) + (time * 4.0)) * 0.02 * clamp(ringDist, 0.0, 1.0);
  disp.y += cos((refPos.y * 20.0) + (time * 3.0)) * 0.02 * clamp(ringDist, 0.0, 1.0);

  pos -= (uRingPos - (curentPos + disp)) * pow(t2, 0.75) * uRingDisplacement;

  vec2 finalPos = pos + disp * 0.5;
  velocity = lifeTime / lifeEnd;

  gl_FragColor = vec4(finalPos, scale, velocity);
}
