precision highp float;

uniform sampler2D uPosition;
uniform sampler2D uPosRefs;
uniform sampler2D uPosNearest;
uniform vec2 uMousePos;
uniform float uTime;
uniform float uIsHovering;

vec2 hash(vec2 p) {
  p = vec2(dot(p, vec2(2127.1, 81.17)), dot(p, vec2(1269.5, 283.37)));
  return fract(sin(p) * 43758.5453);
}

void main() {
  vec2 simTexCoords = gl_FragCoord.xy / vec2(32.0, 32.0);
  vec4 pFrame = texture2D(uPosition, simTexCoords);

  float scale    = pFrame.z;
  float velocity = pFrame.w;

  vec2 refPos     = texture2D(uPosRefs,    simTexCoords).xy;
  vec2 nearestPos = texture2D(uPosNearest, simTexCoords).xy;

  float seed  = hash(simTexCoords).x;
  float seed2 = hash(simTexCoords).y;

  float time     = uTime * .5;
  float lifeEnd  = 3. + sin(seed2 * 100.) * 1.;
  float lifeTime = mod((seed * 100.) + time, lifeEnd);

  vec2 disp = vec2(0., 0.);
  vec2 pos  = pFrame.xy;

  float distRadius = 0.15;

  // Gravity field: cursor attracts nearby particles, density shifts organically
  vec2 toCursor = uMousePos - pos;
  float distToCursor = length(toCursor);
  // Smooth gravity: no normalize (avoids jitter), force proportional to distance (spring-like)
  // capped to avoid singularity at very close range
  float gravityStrength = uIsHovering * 0.04;
  pos += toCursor * gravityStrength * smoothstep(0.0, 0.5, distToCursor) * smoothstep(0.8, 0.2, distToCursor);

  // Drift back to refPos — blended with hover so no fighting forces
  vec2 targetPos = refPos;
  vec2 toRef = targetPos - pos;
  float distToRef = length(toRef);
  // Return force weakens when hovering — cursor wins
  float returnStrength = (1.0 - uIsHovering * 0.8) * 0.01;
  if (distToRef > 0.005) {
    pos += normalize(toRef) * min(distToRef, distRadius) / distRadius * returnStrength;
  }

  if (lifeTime < .01) {
    pos       = refPos;
    pFrame.xy = refPos;
    scale     = 0.;
  }

  // Scale
  float targetScale = smoothstep(.01, 0.5, lifeTime) - smoothstep(0.5, 1., lifeTime / lifeEnd);
  targetScale += smoothstep(0.1, 0., smoothstep(0.001, .1, distToCursor)) * 1.5 * uIsHovering;
  float scaleDiff = targetScale - scale;
  scaleDiff *= .1;
  scale += scaleDiff;

  // Final position
  vec2 finalPos = pos + (disp * smoothstep(0.001, distRadius, distToCursor));
  vec2 diff     = finalPos - pFrame.xy;
  diff *= .2;
  velocity = smoothstep(distRadius, .001, distToCursor) * uIsHovering;

  gl_FragColor = vec4(pFrame.xy + diff, scale, velocity);
}
