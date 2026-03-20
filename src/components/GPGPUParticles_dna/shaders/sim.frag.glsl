precision highp float;

uniform sampler2D uPosition;
uniform sampler2D uPosRefs;
uniform vec2 uMousePos;
uniform float uTime;
uniform float uIsHovering;

#define PI 3.14159265359

vec2 hash(vec2 p) {
  p = vec2(dot(p, vec2(2127.1, 81.17)), dot(p, vec2(1269.5, 283.37)));
  return fract(sin(p) * 43758.5453);
}

void main() {
  vec2 simTexCoords = gl_FragCoord.xy / vec2(32.0, 32.0);
  vec4 pFrame = texture2D(uPosition, simTexCoords);

  float scale    = pFrame.z;
  float velocity = pFrame.w;

  vec2 h = hash(simTexCoords);
  float seed  = h.x;
  float seed2 = h.y;

  // Particle index 0..1023
  float idx = floor(simTexCoords.x * 32.0) + floor(simTexCoords.y * 32.0) * 32.0;
  float total = 1024.0;
  float t = idx / total;

  // Strand: first half = strand A, second half = strand B
  float strandSign = (idx < total * 0.5) ? 1.0 : -1.0;
  float strandIdx  = mod(idx, total * 0.5);
  float tStrand    = strandIdx / (total * 0.5);  // 0..1 along helix

  // DNA helix parameters
  float helixY   = (tStrand - 0.5) * 0.9;        // Y: -0.45 → +0.45
  float helixFreq = 8.0;                           // turns of the helix
  float helixAngle = tStrand * helixFreq * 2.0 * PI + uTime * 0.8;
  float helixR   = 0.18;                           // helix radius

  // 3D helix projected to 2D (X = cos, Y stays, Z = sin → perspective flattening)
  float hx = cos(helixAngle + strandSign * PI) * helixR;
  float hz = sin(helixAngle + strandSign * PI);
  // Simple perspective: closer Z → slightly larger, but just use it for depth cue
  float perspective = 0.7 + hz * 0.3;
  float projectedX = hx * perspective;

  // Base pairs: rungs between strands every N turns
  float isRung  = 0.0;
  float rungFreq = total * 0.25;  // every 256 particles on each strand
  if (seed2 < 0.08) {
    // This particle is a rung particle — interpolate between strands at this Y
    float rungY = helixY;
    float rungT = seed;  // 0=strand A, 1=strand B
    float rungAx = cos(tStrand * helixFreq * 2.0 * PI + uTime * 0.8 + PI) * helixR;
    float rungBx = cos(tStrand * helixFreq * 2.0 * PI + uTime * 0.8 - PI) * helixR;
    projectedX = mix(rungAx, rungBx, rungT);
    isRung = 1.0;
  }

  vec2 targetPos = vec2(projectedX, helixY);

  // Denature on hover: cursor tears the helix apart laterally
  vec2 toCursor = uMousePos - targetPos;
  float distToCursor = length(toCursor);
  float denature = smoothstep(0.35, 0.0, distToCursor) * uIsHovering;

  // Blow strands outward (away from center X) when denatured
  float blowDir = strandSign * (1.0 - isRung);
  targetPos.x += blowDir * denature * 0.15;
  // Also add some chaos
  targetPos.x += (seed - 0.5) * denature * 0.08;
  targetPos.y += (seed2 - 0.5) * denature * 0.06;

  // Smooth move toward target
  vec2 pos = pFrame.xy;
  vec2 toTarget = targetPos - pos;
  float lerpSpeed = 0.06 + denature * 0.04;
  pos += toTarget * lerpSpeed;

  // Scale: always visible (helix never "dies"), modulated by depth cue
  float depthCue = 0.5 + hz * 0.5;  // hz in [-1,1] → depthCue in [0,1]
  float targetScale = (0.4 + depthCue * 0.6) * (1.0 + denature * 0.8);
  if (isRung > 0.5) targetScale *= 0.6;
  scale += (targetScale - scale) * 0.1;

  // Velocity: encodes denature state for rendering
  velocity += (denature - velocity) * 0.12;

  vec2 diff = (pos - pFrame.xy) * 0.3;
  gl_FragColor = vec4(pFrame.xy + diff, scale, velocity);
}
