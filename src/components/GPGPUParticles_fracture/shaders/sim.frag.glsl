precision highp float;

uniform sampler2D uPosition;
uniform sampler2D uPosRefs;
uniform vec2 uMousePos;
uniform float uTime;
uniform float uIsHovering;
uniform float uShockTime;   // time since last shock (reset on click/enter)

#define PI 3.14159265359

vec2 hash(vec2 p) {
  p = vec2(dot(p, vec2(2127.1, 81.17)), dot(p, vec2(1269.5, 283.37)));
  return fract(sin(p) * 43758.5453);
}

float hash1(float n) {
  return fract(sin(n) * 43758.5453);
}

void main() {
  vec2 simTexCoords = gl_FragCoord.xy / vec2(48.0, 48.0);
  vec4 pFrame = texture2D(uPosition, simTexCoords);

  float scale    = pFrame.z;
  float velocity = pFrame.w;

  vec2 refPos = texture2D(uPosRefs, simTexCoords).xy;

  vec2 h = hash(simTexCoords);
  float seed  = h.x;
  float seed2 = h.y;

  vec2 pos = pFrame.xy;

  // === FRACTURE EFFECT ===
  // Distance from cursor to REST position (not current pos)
  vec2 toCursor = uMousePos - refPos;
  float distToRest = length(toCursor);

  // Shockwave: expands from cursor outward
  float shockRadius    = uShockTime * 0.6;        // wave front
  float shockWidth     = 0.08;
  float onWaveFront    = exp(-pow((distToRest - shockRadius) / shockWidth, 2.0) * 12.0);
  float shockActive    = smoothstep(1.2, 0.0, uShockTime);  // fades out over time

  // Each particle has a unique fracture direction (based on seed)
  float fractureAngle = seed * 2.0 * PI + seed2 * PI * 0.5;
  vec2 fractureDir = vec2(cos(fractureAngle), sin(fractureAngle));

  // Also radially outward from cursor
  vec2 radialDir = length(toCursor) > 0.001 ? normalize(-toCursor) : fractureDir;
  vec2 blastDir = mix(radialDir, fractureDir, 0.5);

  // Impact strength: strongest at wave front
  float blastStrength = onWaveFront * shockActive * uIsHovering;

  // Blast impulse stored as velocity (decays over time)
  float blastImpulse = blastStrength * 0.12;

  // Add cursor proximity repulsion (subtle)
  float proximity = smoothstep(0.2, 0.0, distToRest) * uIsHovering;
  blastDir = mix(blastDir, -normalize(toCursor + vec2(0.0001)), 0.3);

  // Apply physics: blast moves particle, then gravity returns it
  pos += blastDir * blastImpulse;

  // Damped spring return to ref pos
  vec2 toRef = refPos - pos;
  float distToRef = length(toRef);
  float returnStr = 0.04 * (1.0 - blastStrength * 0.7);
  if (distToRef > 0.001) {
    pos += normalize(toRef) * min(distToRef, 0.2) / 0.2 * returnStr * distToRef * 5.0;
  }

  // Scale: spike on fracture, fade to normal
  float targetScale = 0.6 + blastStrength * 1.4;
  scale += (targetScale - scale) * (0.08 + blastStrength * 0.1);

  // Velocity encodes blast intensity for color
  velocity += (blastStrength - velocity) * 0.15;

  vec2 diff = (pos - pFrame.xy) * 0.4;
  gl_FragColor = vec4(pFrame.xy + diff, scale, velocity);
}
