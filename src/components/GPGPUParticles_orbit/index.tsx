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
  color1        = '#2c64ed',
  color2        = '#f84242',
  color3        = '#ffcf03',
  alpha         = 0.95,
  particleScale = 0.75,
  className,
}: GPGPUParticlesProps) {
  const canvasRef = useRef<HTMLCanvasElement>(null)

  useEffect(() => {
    const canvas = canvasRef.current
    if (!canvas) return

    const pixelRatio = Math.min(window.devicePixelRatio, 2)
    const renderer = new THREE.WebGLRenderer({ canvas, antialias: false, alpha: true })
    renderer.setPixelRatio(pixelRatio)
    renderer.setClearColor(0xffffff, 0)

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

    const sim      = new SimulationRenderer(renderer)
    const geometry = createParticleGeometry()
    const material = createRenderMaterial({ color1, color2, color3, alpha, particleScale, pixelRatio })
    const points   = new THREE.Points(geometry, material)
    scene.add(points)

    // ── Mouse state ───────────────────────────────────────────────────────────
    const ringTarget   = new THREE.Vector2(0, 0)
    const ringPos      = new THREE.Vector2(0, 0)
    const mouseWorld   = new THREE.Vector2(0, 0)
    const raycaster    = new THREE.Raycaster()
    const plane        = new THREE.Plane(new THREE.Vector3(0, 0, 1), 0)
    const worldHit     = new THREE.Vector3()
    let isHoveringTarget = 0.0   // 0 or 1 — target value
    let isHovering       = 0.0   // smoothly lerped value
    let skipFrame        = false

    const toWorld = (clientX: number, clientY: number) => {
      const rect = canvas.getBoundingClientRect()
      const ndcX = ((clientX - rect.left) / rect.width)  * 2 - 1
      const ndcY = -((clientY - rect.top)  / rect.height) * 2 + 1
      raycaster.setFromCamera(new THREE.Vector2(ndcX, ndcY), camera)
      raycaster.ray.intersectPlane(plane, worldHit)
      return new THREE.Vector2(worldHit.x, worldHit.y)
    }

    const onMouseMove = (e: MouseEvent) => {
      skipFrame = !skipFrame
      if (skipFrame) return
      const w = toWorld(e.clientX, e.clientY)
      ringTarget.copy(w)
      mouseWorld.copy(w)
    }

    const onMouseEnter = () => { isHoveringTarget = 1.0 }
    const onMouseLeave = () => { isHoveringTarget = 0.0 }

    canvas.addEventListener('mousemove',  onMouseMove)
    canvas.addEventListener('mouseenter', onMouseEnter)
    canvas.addEventListener('mouseleave', onMouseLeave)

    // ── RAF loop ──────────────────────────────────────────────────────────────
    let raf: number
    const clock = new THREE.Clock()

    const tick = () => {
      raf = requestAnimationFrame(tick)
      const t = clock.getElapsedTime()

      // Smooth hover interpolation
      isHovering += (isHoveringTarget - isHovering) * 0.04

      // Ring radius breathes
      const ringRadius = 0.18 + Math.sin(t * 1.0) * 0.03 + Math.cos(t * 3.0) * 0.02

      // Ring center: follows mouse when hovering, drifts autonomously otherwise
      const lerpSpeed = 0.015 + isHovering * 0.03
      ringPos.x += (ringTarget.x - ringPos.x) * lerpSpeed
      ringPos.y += (ringTarget.y - ringPos.y) * lerpSpeed

      if (isHoveringTarget === 0.0) {
        ringTarget.x = Math.sin(t * 0.3) * 0.15
        ringTarget.y = Math.cos(t * 0.2) * 0.1
      }

      const gpgpuTex = sim.tick(t, ringPos, ringRadius, isHovering, mouseWorld)

      material.uniforms.uGpgpu.value       = gpgpuTex
      material.uniforms.uTime.value        = t
      material.uniforms.uRingPos.value     = ringPos
      material.uniforms.uIsHovering.value  = isHovering

      renderer.render(scene, camera)
    }

    tick()

    return () => {
      cancelAnimationFrame(raf)
      ro.disconnect()
      canvas.removeEventListener('mousemove',  onMouseMove)
      canvas.removeEventListener('mouseenter', onMouseEnter)
      canvas.removeEventListener('mouseleave', onMouseLeave)
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
