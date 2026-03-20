# Diederick AI Lab — GPGPU Particle Effects

Interactive particle system built with Three.js + React + TypeScript. Each effect runs on the GPU via GPGPU ping-pong render targets and custom GLSL shaders.

## Effects

| Name | Description |
|---|---|
| **Gravity** | Particles float freely. The cursor creates a gravity field — nearby particles are absorbed, distant ones barely move. Density shifts without mass migration. |
| **Ripple** | 16 384 particles on a fixed grid. Each cursor movement triggers a single concentric wave that expands across the screen and fades out. |
| **Constellation** | Stars with personal twinkle. Dynamic lines connect nearby particles, forming living constellations. The cursor scatters stars and breaks local connections. |
| **Breath** | Slow radial breathing pulse (~1.2Hz). The cursor creates a counter-phase zone — when everything expands around it, the cursor area contracts. |

A discrete toggle in the bottom-right corner switches between effects.

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
