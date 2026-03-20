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

  // Ripple: distance from cursor to this particle's rest position
  vec2 toMouse = refPos - uMousePos;
  float d = length(toMouse);

  // Multiple expanding ripple waves emanating from cursor
  float wave1 = sin(d * 18.0 - uTime * 4.0) * 0.5 + 0.5;
  float wave2 = sin(d * 12.0 - uTime * 3.0 + 1.5) * 0.5 + 0.5;

  // Ripple envelope: strong near cursor, fades with distance
  float envelope = exp(-d * 3.5) * uIsHovering;
  float ripple = (wave1 * 0.7 + wave2 * 0.3) * envelope;

  // Particles stay near their grid position, displaced slightly by ripple
  float dispX = sin(d * 20.0 - uTime * 4.5 + seed  * 6.28) * 0.015 * envelope;
  float dispY = cos(d * 20.0 - uTime * 4.5 + seed2 * 6.28) * 0.015 * envelope;

  // Gentle drift back to grid position
  pos += (refPos - pos) * 0.08;
  pos.x += dispX;
  pos.y += dispY;

  // Scale encodes ripple height — used for visual lift
  float targetScale = 0.3 + ripple * 1.2 + seed * 0.2;
  scale += (targetScale - scale) * 0.12;

  // Velocity encodes ripple intensity for color
  velocity += (ripple - velocity) * 0.15;

  gl_FragColor = vec4(pos, scale, velocity);
}
