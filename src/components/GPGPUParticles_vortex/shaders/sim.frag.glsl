precision highp float;

uniform sampler2D uPosition;
uniform sampler2D uPosRefs;
uniform vec2 uMousePos;
uniform float uTime;
uniform float uIsHovering;
uniform float uVortexStrength;

#define PI 3.14159265359

vec2 hash(vec2 p) {
  p = vec2(dot(p, vec2(2127.1, 81.17)), dot(p, vec2(1269.5, 283.37)));
  return fract(sin(p) * 43758.5453);
}

void main() {
  vec2 simTexCoords = gl_FragCoord.xy / vec2(64.0, 64.0);
  vec4 pFrame = texture2D(uPosition, simTexCoords);

  float scale    = pFrame.z;
  float velocity = pFrame.w;

  vec2 refPos = texture2D(uPosRefs, simTexCoords).xy;

  float seed  = hash(simTexCoords).x;
  float seed2 = hash(simTexCoords).y;

  float time    = uTime * 0.5;
  float lifeEnd = 3.0 + sin(seed2 * 100.0) * 1.0;
  float lifeTime = mod((seed * 100.0) + time, lifeEnd);

  vec2 pos = pFrame.xy;

  // === VORTEX EFFECT ===
  // Vector from particle to cursor
  vec2 toCursor = uMousePos - pos;
  float distToCursor = length(toCursor);

  // Vortex zone influence (soft falloff)
  float vortexRadius = 0.45;
  float influence = smoothstep(vortexRadius, 0.0, distToCursor) * uIsHovering;

  // Tangential force: perpendicular to toCursor → creates rotation
  vec2 tangent = vec2(-toCursor.y, toCursor.x);
  float tangentLen = length(tangent);
  if (tangentLen > 0.0001) tangent /= tangentLen;

  // Inward pull (spiral inward) — kept subtle to avoid magma clump
  float inwardStrength = 0.004 * influence;
  float tangentialStrength = 0.016 * influence * uVortexStrength;

  // Apply tangential spin + very light inward pull
  pos += tangent * tangentialStrength;
  pos += normalize(toCursor + vec2(0.0001)) * inwardStrength * smoothstep(0.0, 0.3, distToCursor);

  // Return force stays active even in vortex zone (prevents clumping at center)
  vec2 toRef = refPos - pos;
  float distToRef = length(toRef);
  float returnStr = (1.0 - influence * 0.5) * 0.012;
  if (distToRef > 0.003) {
    pos += normalize(toRef) * min(distToRef, 0.15) / 0.15 * returnStr;
  }

  // Respawn on new life
  if (lifeTime < 0.01) {
    pos       = refPos;
    pFrame.xy = refPos;
    scale     = 0.0;
  }

  // Scale: birth/death cycle + subtle vortex boost (no inflate)
  float targetScale = smoothstep(0.01, 0.4, lifeTime) - smoothstep(0.5, 1.0, lifeTime / lifeEnd);
  targetScale += influence * 0.4;
  scale += (targetScale - scale) * 0.1;

  // Velocity encodes vortex influence for rendering (color/glow)
  velocity += (influence - velocity) * 0.15;

  vec2 diff = (pos - pFrame.xy) * 0.25;
  gl_FragColor = vec4(pFrame.xy + diff, scale, velocity);
}
