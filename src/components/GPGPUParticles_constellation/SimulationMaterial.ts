import * as THREE from 'three'
import simFrag from './shaders/sim.frag.glsl'

const SIM_SIZE = 32  // 32×32 = 1024 particles

// All simulation positions live in normalized [-0.5, 0.5] space.
// The vertex shader scales them to fill the screen.

const simVert = /* glsl */`
  void main() {
    gl_Position = vec4(position, 1.0);
  }
`

function buildRefTexture(): THREE.DataTexture {
  const total = SIM_SIZE * SIM_SIZE
  const data = new Float32Array(total * 4)

  // Scatter randomly in [-0.4, 0.4] — loose cloud, not a ring
  for (let i = 0; i < total; i++) {
    const angle = Math.random() * Math.PI * 2
    const r = 0.05 + Math.random() * 0.35   // cloud: 0.05 → 0.4
    data[i * 4 + 0] = Math.cos(angle) * r
    data[i * 4 + 1] = Math.sin(angle) * r
    data[i * 4 + 2] = 0.0
    data[i * 4 + 3] = 0.0
  }

  const tex = new THREE.DataTexture(data, SIM_SIZE, SIM_SIZE, THREE.RGBAFormat, THREE.FloatType)
  tex.needsUpdate = true
  return tex
}

function buildInitialPositionTexture(): THREE.DataTexture {
  const total = SIM_SIZE * SIM_SIZE
  const data = new Float32Array(total * 4)
  for (let i = 0; i < total; i++) {
    const angle = Math.random() * Math.PI * 2
    const r = Math.random() * 0.4
    data[i * 4 + 0] = Math.cos(angle) * r
    data[i * 4 + 1] = Math.sin(angle) * r
    data[i * 4 + 2] = 0.0
    data[i * 4 + 3] = 0.0
  }
  const tex = new THREE.DataTexture(data, SIM_SIZE, SIM_SIZE, THREE.RGBAFormat, THREE.FloatType)
  tex.needsUpdate = true
  return tex
}

export class SimulationRenderer {
  private renderer: THREE.WebGLRenderer
  private scene: THREE.Scene
  private camera: THREE.OrthographicCamera
  private material: THREE.ShaderMaterial
  private targets: [THREE.WebGLRenderTarget, THREE.WebGLRenderTarget]
  private nearestTex: THREE.DataTexture
  private nearestData: Float32Array
  private pingPong = 0
  readonly size = SIM_SIZE

  get currentTarget(): THREE.WebGLRenderTarget {
    // Returns the target that was last written (1 - pingPong after tick flips it)
    return this.targets[1 - this.pingPong]
  }

  constructor(renderer: THREE.WebGLRenderer) {
    this.renderer = renderer
    this.scene    = new THREE.Scene()
    this.camera   = new THREE.OrthographicCamera(-1, 1, 1, -1, 0, 1)

    const opts: THREE.RenderTargetOptions = {
      minFilter: THREE.NearestFilter,
      magFilter: THREE.NearestFilter,
      format: THREE.RGBAFormat,
      type: THREE.FloatType,
    }

    this.targets = [
      new THREE.WebGLRenderTarget(SIM_SIZE, SIM_SIZE, opts),
      new THREE.WebGLRenderTarget(SIM_SIZE, SIM_SIZE, opts),
    ]

    const total = SIM_SIZE * SIM_SIZE
    this.nearestData = new Float32Array(total * 4)
    this.nearestTex  = new THREE.DataTexture(this.nearestData, SIM_SIZE, SIM_SIZE, THREE.RGBAFormat, THREE.FloatType)
    this.nearestTex.needsUpdate = true

    this.material = new THREE.ShaderMaterial({
      vertexShader: simVert,
      fragmentShader: simFrag,
      uniforms: {
        uPosition:   { value: buildInitialPositionTexture() },
        uPosRefs:    { value: buildRefTexture() },
        uPosNearest: { value: this.nearestTex },
        uMousePos:   { value: new THREE.Vector2(0, 0) },
        uTime:       { value: 0 },
        uIsHovering: { value: 0.0 },
      },
    })

    const mesh = new THREE.Mesh(new THREE.PlaneGeometry(2, 2), this.material)
    this.scene.add(mesh)
  }

  // mousePos arrives in world space (±2, ±1.1) — convert to sim space (±0.5)
  private updateNearestTexture(mouseSimX: number, mouseSimY: number) {
    const total = SIM_SIZE * SIM_SIZE
    const r = 0.18  // cloud spread radius around cursor in sim space

    for (let i = 0; i < total; i++) {
      // True random cloud: random angle + random radius (fills disk, not ring)
      const angle  = Math.random() * Math.PI * 2
      const radius = r * Math.sqrt(Math.random())  // sqrt for uniform disk distribution
      this.nearestData[i * 4 + 0] = mouseSimX + Math.cos(angle) * radius
      this.nearestData[i * 4 + 1] = mouseSimY + Math.sin(angle) * radius
      this.nearestData[i * 4 + 2] = 0.0
      this.nearestData[i * 4 + 3] = 0.0
    }

    this.nearestTex.needsUpdate = true
  }

  tick(time: number, isHovering: number, mouseWorld: THREE.Vector2, worldHalfW: number, worldHalfH: number): THREE.Texture {
    const read  = this.targets[this.pingPong]
    const write = this.targets[1 - this.pingPong]

    // Convert world coords → sim space [-0.5, 0.5]
    const mouseSimX = mouseWorld.x / worldHalfW * 0.5
    const mouseSimY = mouseWorld.y / worldHalfH * 0.5

    this.updateNearestTexture(mouseSimX, mouseSimY)

    this.material.uniforms.uPosition.value   = read.texture
    this.material.uniforms.uTime.value       = time
    this.material.uniforms.uIsHovering.value = isHovering
    this.material.uniforms.uMousePos.value.set(mouseSimX, mouseSimY)

    this.renderer.setRenderTarget(write)
    this.renderer.render(this.scene, this.camera)
    this.renderer.setRenderTarget(null)

    this.pingPong = 1 - this.pingPong
    return write.texture
  }

  dispose() {
    this.targets[0].dispose()
    this.targets[1].dispose()
    this.material.dispose()
    this.nearestTex.dispose()
  }
}
