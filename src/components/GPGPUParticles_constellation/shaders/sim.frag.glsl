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

  // Very slow drift from ref — star-like floating
  pos += (refPos - pos) * 0.005;

  // Slow personal drift orbit around refPos
  float orbitSpeed = 0.04 + seed * 0.06;
  float orbitR     = 0.01 + seed2 * 0.02;
  float angle      = uTime * orbitSpeed + seed * 6.28;
  vec2 orbitTarget = refPos + vec2(cos(angle), sin(angle)) * orbitR;
  pos += (orbitTarget - pos) * 0.02;

  // Cursor repulsion: stars scatter when cursor passes
  vec2 toCursor = pos - uMousePos;
  float dCursor = length(toCursor);
  float repulse  = smoothstep(0.2, 0.0, dCursor) * uIsHovering * 0.015;
  if (dCursor > 0.001) pos += normalize(toCursor) * repulse;

  // Twinkle: scale oscillates per particle at personal frequency
  float twinkleSpeed = 0.8 + seed * 1.5;
  float targetScale  = 0.4 + sin(uTime * twinkleSpeed + seed * 20.0) * 0.3;
  // Brighten when cursor is close
  targetScale += smoothstep(0.2, 0.0, dCursor) * uIsHovering * 0.8;
  scale += (targetScale - scale) * 0.08;

  // Velocity = proximity to cursor (for line opacity)
  velocity += (smoothstep(0.25, 0.0, dCursor) * uIsHovering - velocity) * 0.1;

  gl_FragColor = vec4(pos, scale, velocity);
}
