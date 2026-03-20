import * as THREE from 'three'
import simFrag from './shaders/sim.frag.glsl'

const SIM_SIZE = 256

const simVert = /* glsl */`
  void main() {
    gl_Position = vec4(position, 1.0);
  }
`

// Distribute particles on concentric rings
function buildRefTexture(): THREE.DataTexture {
  const total = SIM_SIZE * SIM_SIZE
  const data = new Float32Array(total * 4)

  const rings = [
    { radius: 0.18, width: 0.15, share: 0.4 },
    { radius: 0.38, width: 0.15, share: 0.35 },
    { radius: 0.58, width: 0.15, share: 0.25 },
  ]

  // Pre-assign each particle slot to a ring
  const ringAssignment: number[] = []
  let cursor = 0
  for (let r = 0; r < rings.length; r++) {
    const count = Math.round(rings[r].share * total)
    for (let k = 0; k < count && cursor < total; k++, cursor++) {
      ringAssignment[cursor] = r
    }
  }
  while (cursor < total) { ringAssignment[cursor++] = 0 }

  for (let i = 0; i < total; i++) {
    const ring = rings[ringAssignment[i]]
    const angle  = Math.random() * Math.PI * 2
    const r      = ring.radius + (Math.random() - 0.5) * ring.width

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
    const r = Math.random() * 0.8
    data[i * 4 + 0] = Math.cos(angle) * r
    data[i * 4 + 1] = Math.sin(angle) * r
    data[i * 4 + 2] = 0.0
    data[i * 4 + 3] = Math.random()
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
  private pingPong = 0
  readonly size = SIM_SIZE

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

    this.material = new THREE.ShaderMaterial({
      vertexShader: simVert,
      fragmentShader: simFrag,
      uniforms: {
        uPosition:        { value: buildInitialPositionTexture() },
        uPosRefs:         { value: buildRefTexture() },
        uRingPos:         { value: new THREE.Vector2(0, 0) },
        uTime:            { value: 0 },
        uRingRadius:      { value: 0.18 },
        uRingWidth:       { value: 0.15 },
        uRingWidth2:      { value: 0.08 },
        uRingDisplacement:{ value: 0.12 },
        uIsHovering:      { value: 0.0 },
        uMousePos:        { value: new THREE.Vector2(0, 0) },
      },
    })

    const mesh = new THREE.Mesh(new THREE.PlaneGeometry(2, 2), this.material)
    this.scene.add(mesh)
  }

  tick(time: number, ringPos: THREE.Vector2, ringRadius: number, isHovering: number, mousePos: THREE.Vector2): THREE.Texture {
    const read  = this.targets[this.pingPong]
    const write = this.targets[1 - this.pingPong]

    this.material.uniforms.uPosition.value   = read.texture
    this.material.uniforms.uTime.value       = time
    this.material.uniforms.uRingPos.value    = ringPos
    this.material.uniforms.uRingRadius.value = ringRadius
    this.material.uniforms.uIsHovering.value = isHovering
    this.material.uniforms.uMousePos.value   = mousePos

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
  }
}
