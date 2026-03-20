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
  color1       = '#2c64ed',
  color2       = '#f84242',
  color3       = '#ffcf03',
  alpha        = 0.95,
  particleScale = 0.75,
  className,
}: GPGPUParticlesProps) {
  const canvasRef = useRef<HTMLCanvasElement>(null)

  useEffect(() => {
    const canvas = canvasRef.current
    if (!canvas) return

    // ── Renderer ──────────────────────────────────────────────────────────────
    const pixelRatio = Math.min(window.devicePixelRatio, 2)
    const renderer = new THREE.WebGLRenderer({ canvas, antialias: false, alpha: true })
    renderer.setPixelRatio(pixelRatio)
    renderer.setClearColor(0xffffff, 0)

    // ── Scene & perspective camera (matches Google: FOV 40, z=3.1) ────────────
    const scene  = new THREE.Scene()
    const camera = new THREE.PerspectiveCamera(40, 1, 0.1, 100)
    camera.position.z = 3.1

    const resize = () => {
      const w = canvas.clientWidth
      const h = canvas.clientHeight
      renderer.setSize(w, h, false)
      camera.aspect = w / h
      camera.updateProjectionMatrix()
    }

    resize()
    const ro = new ResizeObserver(resize)
    ro.observe(canvas)

    // ── GPGPU ─────────────────────────────────────────────────────────────────
    const sim = new SimulationRenderer(renderer)

    // ── Render mesh ───────────────────────────────────────────────────────────
    const geometry = createParticleGeometry()
    const material = createRenderMaterial({
      color1, color2, color3, alpha, particleScale, pixelRatio,
    })
    const points = new THREE.Points(geometry, material)
    scene.add(points)

    // ── Mouse tracking ────────────────────────────────────────────────────────
    // Target ring position in world space — updated on mouse move
    const ringTarget = new THREE.Vector2(0, 0)
    const ringPos    = new THREE.Vector2(0, 0)
    const raycaster  = new THREE.Raycaster()
    const plane      = new THREE.Plane(new THREE.Vector3(0, 0, 1), 0)
    const worldHit   = new THREE.Vector3()
    let skipFrame    = false

    const onMouseMove = (e: MouseEvent) => {
      // Skip every other frame for perf
      skipFrame = !skipFrame
      if (skipFrame) return

      const rect = canvas.getBoundingClientRect()
      const ndcX = ((e.clientX - rect.left) / rect.width)  * 2 - 1
      const ndcY = -((e.clientY - rect.top)  / rect.height) * 2 + 1

      raycaster.setFromCamera(new THREE.Vector2(ndcX, ndcY), camera)
      raycaster.ray.intersectPlane(plane, worldHit)
      ringTarget.set(worldHit.x, worldHit.y)
    }

    canvas.addEventListener('mousemove', onMouseMove)

    // ── RAF loop ──────────────────────────────────────────────────────────────
    let raf: number
    const clock = new THREE.Clock()

    const tick = () => {
      raf = requestAnimationFrame(tick)
      const t = clock.getElapsedTime()

      // Ring radius oscillates exactly like Google's implementation
      const ringRadius = 0.175 + Math.sin(t * 1.0) * 0.03 + Math.cos(t * 3.0) * 0.02

      // Ring position follows mouse with lag (slow lerp)
      ringPos.x += (ringTarget.x - ringPos.x) * 0.015
      ringPos.y += (ringTarget.y - ringPos.y) * 0.015

      // If no mouse, drift autonomously via low-freq noise (approximated with sin)
      if (ringTarget.x === 0 && ringTarget.y === 0) {
        ringPos.x = Math.sin(t * 0.3) * 0.2
        ringPos.y = Math.cos(t * 0.2) * 0.15
      }

      // 1. GPGPU simulation step
      const gpgpuTex = sim.tick(t, ringPos, ringRadius)

      // 2. Pass texture + uniforms to render material
      material.uniforms.uGpgpu.value   = gpgpuTex
      material.uniforms.uTime.value    = t
      material.uniforms.uRingPos.value = ringPos

      // 3. Render
      renderer.render(scene, camera)
    }

    tick()

    return () => {
      cancelAnimationFrame(raf)
      ro.disconnect()
      canvas.removeEventListener('mousemove', onMouseMove)
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
      style={{ display: 'block', width: '100%', height: '100%' }}
    />
  )
}
