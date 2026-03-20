import * as THREE from 'three'
import simFrag from './shaders/sim.frag.glsl'

const SIM_SIZE = 64  // 64×64 = 4096 particles

const simVert = /* glsl */`
  void main() {
    gl_Position = vec4(position, 1.0);
  }
`

function buildRefTexture(): THREE.DataTexture {
  const total = SIM_SIZE * SIM_SIZE
  const data = new Float32Array(total * 4)

  // Scattered cloud — particles will be pulled into vortex from rest
  for (let i = 0; i < total; i++) {
    const angle = Math.random() * Math.PI * 2
    const r = 0.05 + Math.random() * 0.4
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
  material: THREE.ShaderMaterial
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
        uPosition:      { value: buildInitialPositionTexture() },
        uPosRefs:       { value: buildRefTexture() },
        uMousePos:      { value: new THREE.Vector2(0, 0) },
        uTime:          { value: 0 },
        uIsHovering:    { value: 0.0 },
        uVortexStrength:{ value: 1.0 },
      },
    })

    const mesh = new THREE.Mesh(new THREE.PlaneGeometry(2, 2), this.material)
    this.scene.add(mesh)
  }

  tick(time: number, isHovering: number, mouseWorld: THREE.Vector2, worldHalfW: number, worldHalfH: number): THREE.Texture {
    const read  = this.targets[this.pingPong]
    const write = this.targets[1 - this.pingPong]

    const mouseSimX = mouseWorld.x / worldHalfW * 0.5
    const mouseSimY = mouseWorld.y / worldHalfH * 0.5

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
  }
}
