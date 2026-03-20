import { useEffect, useRef } from 'react'
import * as THREE from 'three'
import { SimulationRenderer } from './SimulationMaterial'
import { createRenderMaterial, createParticleGeometry } from './RenderMaterial'

export interface GPGPUParticlesProps {
  color1?: string
  color2?: string
  color3?: string
  alpha?: number
  particleScale?: number
  className?: string
}

export function GPGPUParticles({
  color1        = '#445566',
  color2        = '#ff6600',
  color3        = '#ffeecc',
  alpha         = 0.92,
  particleScale = 0.85,
  className,
}: GPGPUParticlesProps) {
  const canvasRef = useRef<HTMLCanvasElement>(null)

  useEffect(() => {
    const canvas = canvasRef.current
    if (!canvas) return

    const pixelRatio = Math.min(window.devicePixelRatio, 2)
    const renderer   = new THREE.WebGLRenderer({ canvas, antialias: false, alpha: true })
    renderer.setPixelRatio(pixelRatio)
    renderer.setClearColor(0xffffff, 0)

    const scene  = new THREE.Scene()
    const camera = new THREE.PerspectiveCamera(40, 1, 0.1, 100)
    camera.position.z = 3.1

    const getWorldScale = () => {
      const halfFOV = (40 / 2) * Math.PI / 180
      const halfH   = Math.tan(halfFOV) * camera.position.z
      const halfW   = halfH * camera.aspect
      return { halfW, halfH }
    }

    const sim      = new SimulationRenderer(renderer)
    const geometry = createParticleGeometry()
    const material = createRenderMaterial({ color1, color2, color3, alpha, particleScale, pixelRatio })
    const points   = new THREE.Points(geometry, material)
    scene.add(points)

    const resize = () => {
      const w = canvas.clientWidth
      const h = canvas.clientHeight
      renderer.setSize(w, h, false)
      camera.aspect = w / h
      camera.updateProjectionMatrix()
      material.uniforms.uRez.value.set(w * pixelRatio, h * pixelRatio)
      const { halfW, halfH } = getWorldScale()
      material.uniforms.uWorldScaleX.value = halfW
      material.uniforms.uWorldScaleY.value = halfH
    }

    resize()
    const ro = new ResizeObserver(resize)
    ro.observe(canvas)

    const mouseWorld     = new THREE.Vector2(0, 0)
    const raycaster      = new THREE.Raycaster()
    const plane          = new THREE.Plane(new THREE.Vector3(0, 0, 1), 0)
    const worldHit       = new THREE.Vector3()
    let isHoveringTarget = 0.0
    let isHovering       = 0.0
    let pulseProgress    = 2.0

    // Shock state: resets on mouse enter and on click
    let shockTime        = 99.0
    let lastShockWorld   = new THREE.Vector2(0, 0)
    let skipFrame        = false

    const triggerShock = () => {
      shockTime = 0.0
      lastShockWorld.copy(mouseWorld)
    }

    const onMouseMove = (e: MouseEvent) => {
      skipFrame = !skipFrame
      if (skipFrame) return
      const rect = canvas.getBoundingClientRect()
      const ndcX =  ((e.clientX - rect.left) / rect.width)  * 2 - 1
      const ndcY = -((e.clientY - rect.top)  / rect.height) * 2 + 1
      raycaster.setFromCamera(new THREE.Vector2(ndcX, ndcY), camera)
      raycaster.ray.intersectPlane(plane, worldHit)
      mouseWorld.set(worldHit.x, worldHit.y)
      if (isHoveringTarget === 0.0) { isHoveringTarget = 1.0; pulseProgress = 0.0 }
    }

    const onMouseEnter = () => {
      isHoveringTarget = 1.0
      pulseProgress = 0.0
      triggerShock()
    }
    const onMouseLeave = () => { isHoveringTarget = 0.0; mouseWorld.set(0, 0) }
    const onClick      = () => triggerShock()

    canvas.addEventListener('mousemove',  onMouseMove)
    canvas.addEventListener('mouseenter', onMouseEnter)
    canvas.addEventListener('mouseleave', onMouseLeave)
    canvas.addEventListener('click',      onClick)

    let raf: number
    const clock = new THREE.Clock()

    const tick = () => {
      raf = requestAnimationFrame(tick)
      const t = clock.getElapsedTime()
      const dt = 1 / 60

      const lerpRate = isHoveringTarget > isHovering ? 0.05 : 0.02
      isHovering += (isHoveringTarget - isHovering) * lerpRate

      if (pulseProgress < 2.0) pulseProgress += dt * 0.5

      // Advance shock timer
      if (shockTime < 99.0) shockTime += dt

      const { halfW, halfH } = getWorldScale()

      const gpgpuTex = sim.tick(t, isHovering, mouseWorld, halfW, halfH, shockTime)

      material.uniforms.uGpgpu.value         = gpgpuTex
      material.uniforms.uTime.value          = t
      material.uniforms.uIsHovering.value    = isHovering
      material.uniforms.uPulseProgress.value = pulseProgress
      material.uniforms.uMousePos.value      = mouseWorld

      renderer.render(scene, camera)
    }

    tick()

    return () => {
      cancelAnimationFrame(raf)
      ro.disconnect()
      canvas.removeEventListener('mousemove',  onMouseMove)
      canvas.removeEventListener('mouseenter', onMouseEnter)
      canvas.removeEventListener('mouseleave', onMouseLeave)
      canvas.removeEventListener('click',      onClick)
      sim.dispose()
      geometry.dispose()
      material.dispose()
      renderer.dispose()
    }
  }, [color1, color2, color3, alpha, particleScale])

  return (
    <canvas
      ref={canvasRef}
      className={className}
      style={{ display: 'block', width: '100%', height: '100%', cursor: 'crosshair' }}
    />
  )
}
