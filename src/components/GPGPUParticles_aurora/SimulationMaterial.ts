import * as THREE from 'three'
import simFrag from './shaders/sim.frag.glsl'

const SIM_SIZE = 256  // 256×256 = 65536 particle slots

const simVert = /* glsl */`
  void main() {
    gl_Position = vec4(position, 1.0);
  }
`

// Generate reference positions: distributed on a large plane (will be masked by ring)
function buildRefTexture(): THREE.DataTexture {
  const total = SIM_SIZE * SIM_SIZE
  const data = new Float32Array(total * 4)

  for (let i = 0; i < total; i++) {
    // Spread over a 2×2 world-unit square
    data[i * 4 + 0] = (Math.random() - 0.5) * 2.0
    data[i * 4 + 1] = (Math.random() - 0.5) * 2.0
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
    data[i * 4 + 0] = (Math.random() - 0.5) * 2.0
    data[i * 4 + 1] = (Math.random() - 0.5) * 2.0
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
        uRingRadius:      { value: 0.175 },
        uRingWidth:       { value: 0.107 },
        uRingWidth2:      { value: 0.05 },
        uRingDisplacement:{ value: 0.15 },
      },
    })

    const mesh = new THREE.Mesh(new THREE.PlaneGeometry(2, 2), this.material)
    this.scene.add(mesh)
  }

  tick(time: number, ringPos: THREE.Vector2, ringRadius: number): THREE.Texture {
    const read  = this.targets[this.pingPong]
    const write = this.targets[1 - this.pingPong]

    this.material.uniforms.uPosition.value  = read.texture
    this.material.uniforms.uTime.value      = time
    this.material.uniforms.uRingPos.value   = ringPos
    this.material.uniforms.uRingRadius.value = ringRadius

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
