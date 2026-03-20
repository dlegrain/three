precision highp float;

uniform sampler2D uPosition;
uniform sampler2D uPosRefs;
uniform sampler2D uPosNearest;
uniform vec2 uMousePos;
uniform float uTime;
uniform float uWaveTime;   // seconds since last wave trigger (999 = inactive)
uniform float uIsHovering;

vec2 hash(vec2 p) {
  p = vec2(dot(p, vec2(2127.1, 81.17)), dot(p, vec2(1269.5, 283.37)));
  return fract(sin(p) * 43758.5453);
}

void main() {
  vec2 simTexCoords = gl_FragCoord.xy / vec2(128.0, 128.0);
  vec4 pFrame = texture2D(uPosition, simTexCoords);

  float scale    = pFrame.z;
  float velocity = pFrame.w;

  vec2 refPos = texture2D(uPosRefs, simTexCoords).xy;

  float seed  = hash(simTexCoords).x;
  float seed2 = hash(simTexCoords).y;

  // Positions are fixed on the grid — no XY displacement
  vec2 pos = refPos;

  // Distance from this particle's grid position to cursor (in sim space [-0.5, 0.5])
  float d = length(refPos - uMousePos);

  // Single wave triggered on mousemove: front expands from 0 → 1.0 in ~1.4s
  float waveSpeed  = 0.7;
  float waveRadius = uWaveTime * waveSpeed;

  // Narrow gaussian peak around the expanding front
  float diff  = d - waveRadius;
  float pulse = exp(-diff * diff * 200.0);

  // Fade to zero as ring reaches edge or after wave dies out
  float fadeOut = smoothstep(1.0, 0.8, waveRadius);

  float ripple = pulse * fadeOut;

  // Scale: near-zero at rest, modest peak — 16k points make the ring visible
  float targetScale = 0.02 + ripple * 0.9 + seed * 0.03;
  scale += (targetScale - scale) * 0.2;

  // Velocity = ripple intensity for color
  velocity += (ripple - velocity) * 0.2;

  gl_FragColor = vec4(pos, scale, velocity);
}
