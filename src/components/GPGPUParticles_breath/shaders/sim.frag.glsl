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

  vec2 refPos = texture2D(uPosRefs, simTexCoords).xy;

  float seed  = hash(simTexCoords).x;
  float seed2 = hash(simTexCoords).y;

  vec2 pos = pFrame.xy;

  // ── Breath: global in/out pulse at ~0.3Hz ─────────────────────────────
  // Each particle has a slight phase offset based on its position (wave propagation)
  float distFromCenter = length(refPos);
  float phaseOffset    = distFromCenter * 2.5 + seed * 0.8;  // radial wave + personal jitter
  float breathCycle    = sin(uTime * 1.2 + phaseOffset);     // ~0.19Hz breathing

  // Breath expands position away from center
  float breathScale = 1.0 + breathCycle * 0.12;
  vec2 breathPos = refPos * breathScale;

  // ── Cursor counter-phase ────────────────────────────────────────────────
  // Near cursor: invert the breath phase — contracts when others expand
  vec2 toCursor = pos - uMousePos;
  float dCursor = length(toCursor);
  float cursorZone = smoothstep(0.3, 0.0, dCursor) * uIsHovering;

  // Counter-phase: breathe opposite direction
  float counterBreath = sin(uTime * 1.2 + phaseOffset + 3.14159);
  float counterScale  = 1.0 + counterBreath * 0.18;
  vec2 counterPos     = refPos * counterScale;

  // Blend normal breath → counter-breath near cursor
  vec2 targetPos = mix(breathPos, counterPos, cursorZone);

  // Smooth drift to target
  pos += (targetPos - pos) * 0.06;

  // Slow organic micro-drift
  pos += (refPos - pos) * 0.002;

  // Scale: pulses with breath, peaks near cursor (visual pop)
  float breathNorm  = breathCycle * 0.5 + 0.5;
  float targetScale = 0.3 + breathNorm * 0.6 + seed * 0.15;
  targetScale       = mix(targetScale, 0.9 + (1.0 - breathNorm) * 0.4, cursorZone);
  scale += (targetScale - scale) * 0.1;

  // Velocity = counter-phase intensity (drives color contrast)
  velocity += (cursorZone - velocity) * 0.08;

  gl_FragColor = vec4(pos, scale, velocity);
}
