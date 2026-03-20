# Diederick AI Lab — GPGPU Particle Effects

Interactive particle system built with Three.js + React + TypeScript. Each effect runs on the GPU via GPGPU ping-pong render targets and custom GLSL shaders.

## Effects

| Name | Particles | Description |
|---|---|---|
| **Gravity** | 1 024 | Particles float freely. The cursor creates a local gravity field — nearby particles are absorbed, distant ones barely move. |
| **Ripple** | 16 384 | Fixed grid. Each cursor movement triggers a single concentric wave that expands and fades out. |
| **Constellation** | 1 024 | Stars with personal twinkle. Dynamic lines connect nearby particles. The cursor scatters stars and breaks connections. |
| **Breath** | 1 024 | Slow radial breathing pulse (~1.2Hz). The cursor creates a counter-phase zone that contracts when everything else expands. |
| **Vortex** | 4 096 | Particles spiral around the cursor with a tangential force. Additive glow — white core at the centre of the vortex. |
| **DNA** | 1 024 | Rotating double helix projected from 3D. The cursor denatures the strands — they split apart and chaos on hover. |
| **Fracture** | 2 304 | Perfect grid of glass tiles. Cursor or click triggers an expanding shockwave — shards spin away and reassemble. |
| **Aurora** | 4 096 | Breathing ring that follows the cursor with lag. Teardrop particles oriented tangentially to the ring. |

A toggle at the bottom switches between effects.

## Stack

- **Three.js** v0.183 — WebGL renderer, GPGPU ping-pong render targets
- **React** + **TypeScript** — component wrapper
- **Vite** — dev server + build
- **vite-plugin-glsl** — `.glsl` shader imports

## Dev

```bash
./go          # kill port 5120, start Vite, open browser
npm run build # production build → dist/
```

## Deploy

Static site — deploy the `dist/` folder to Netlify (drag & drop or CLI).
