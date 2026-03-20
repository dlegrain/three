import * as THREE from 'three'
import renderVert from './shaders/render.vert.glsl'
import renderFrag from './shaders/render.frag.glsl'

const SIM_SIZE = 48

export interface RenderOptions {
  color1: string
  color2: string
  color3: string
  alpha?: number
  particleScale?: number
  pixelRatio?: number
  colorScheme?: number
}

export function createRenderMaterial(opts: RenderOptions): THREE.ShaderMaterial {
  return new THREE.ShaderMaterial({
    vertexShader: renderVert,
    fragmentShader: renderFrag,
    uniforms: {
      uGpgpu:        { value: null },
      uTime:         { value: 0 },
      uParticleScale:{ value: opts.particleScale ?? 1.0 },
      uPixelRatio:   { value: opts.pixelRatio ?? window.devicePixelRatio },
      uColorScheme:  { value: opts.colorScheme ?? 0 },
      uColor1:       { value: new THREE.Color(opts.color1) },
      uColor2:       { value: new THREE.Color(opts.color2) },
      uColor3:       { value: new THREE.Color(opts.color3) },
      uAlpha:        { value: opts.alpha ?? 1.0 },
      uIsHovering:   { value: 0.0 },
      uPulseProgress:{ value: 0.0 },
      uMousePos:     { value: new THREE.Vector2(0, 0) },
      uRez:          { value: new THREE.Vector2(window.innerWidth, window.innerHeight) },
      uWorldScaleX:  { value: 2.0 },
      uWorldScaleY:  { value: 1.1 },
    },
    transparent: true,
    depthWrite: false,
    blending: THREE.NormalBlending,
  })
}

export function createParticleGeometry(): THREE.BufferGeometry {
  const total = SIM_SIZE * SIM_SIZE

  const positions = new Float32Array(total * 3)
  const uvs       = new Float32Array(total * 2)
  const seeds     = new Float32Array(total * 4)

  for (let i = 0; i < total; i++) {
    const col = i % SIM_SIZE
    const row = Math.floor(i / SIM_SIZE)

    uvs[i * 2 + 0] = col / SIM_SIZE
    uvs[i * 2 + 1] = row / SIM_SIZE

    seeds[i * 4 + 0] = Math.random()
    seeds[i * 4 + 1] = Math.random()
    seeds[i * 4 + 2] = Math.random()
    seeds[i * 4 + 3] = Math.random()
  }

  const geo = new THREE.BufferGeometry()
  geo.setAttribute('position', new THREE.BufferAttribute(positions, 3))
  geo.setAttribute('uv',       new THREE.BufferAttribute(uvs,       2))
  geo.setAttribute('seeds',    new THREE.BufferAttribute(seeds,     4))

  return geo
}
