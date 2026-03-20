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

// Max lines to draw between nearby particles
const MAX_LINES     = 2000
const CONNECT_DIST  = 0.18  // sim space connection threshold

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
    const renderer   = new THREE.WebGLRenderer({ canvas, antialias: true, alpha: true })
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

    // ── Constellation lines ────────────────────────────────────────────────
    const linePositions = new Float32Array(MAX_LINES * 2 * 3)  // 2 vertices × 3 floats per line
    const lineColors    = new Float32Array(MAX_LINES * 2 * 3)
    const lineGeo       = new THREE.BufferGeometry()
    const linePosAttr   = new THREE.BufferAttribute(linePositions, 3)
    const lineColAttr   = new THREE.BufferAttribute(lineColors,    3)
    linePosAttr.setUsage(THREE.DynamicDrawUsage)
    lineColAttr.setUsage(THREE.DynamicDrawUsage)
    lineGeo.setAttribute('position', linePosAttr)
    lineGeo.setAttribute('color',    lineColAttr)
    lineGeo.setDrawRange(0, 0)

    const lineMat  = new THREE.LineBasicMaterial({ vertexColors: true, transparent: true, opacity: 0.35, depthWrite: false })
    const lines    = new THREE.LineSegments(lineGeo, lineMat)
    scene.add(lines)

    // Buffer for reading back GPGPU texture on CPU
    const SIM_SIZE   = sim.size
    const pixelCount = SIM_SIZE * SIM_SIZE
    const gpuReadBuf = new Float32Array(pixelCount * 4)

    // Parsed positions in world space
    const worldPositions = new Float32Array(pixelCount * 2)

    const c1 = new THREE.Color(color1)
    const c2 = new THREE.Color(color2)

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
    let skipFrame        = false

    const onMouseMove = (e: MouseEvent) => {
      skipFrame = !skipFrame
      if (skipFrame) return
      const rect = canvas.getBoundingClientRect()
      const ndcX =  ((e.clientX - rect.left) / rect.width)  * 2 - 1
      const ndcY = -((e.clientY - rect.top)  / rect.height) * 2 + 1
      raycaster.setFromCamera(new THREE.Vector2(ndcX, ndcY), camera)
      raycaster.ray.intersectPlane(plane, worldHit)
      mouseWorld.set(worldHit.x, worldHit.y)
      if (isHoveringTarget === 0.0) isHoveringTarget = 1.0
    }

    const onMouseEnter = () => { isHoveringTarget = 1.0 }
    const onMouseLeave = () => { isHoveringTarget = 0.0; mouseWorld.set(0, 0) }

    const onTouchMove = (e: TouchEvent) => {
      e.preventDefault()
      const t = e.touches[0]
      const rect = canvas.getBoundingClientRect()
      const ndcX =  ((t.clientX - rect.left) / rect.width)  * 2 - 1
      const ndcY = -((t.clientY - rect.top)  / rect.height) * 2 + 1
      raycaster.setFromCamera(new THREE.Vector2(ndcX, ndcY), camera)
      raycaster.ray.intersectPlane(plane, worldHit)
      mouseWorld.set(worldHit.x, worldHit.y)
      isHoveringTarget = 1.0
    }
    const onTouchEnd = () => { isHoveringTarget = 0.0; mouseWorld.set(0, 0) }

    canvas.addEventListener('mousemove',  onMouseMove)
    canvas.addEventListener('mouseenter', onMouseEnter)
    canvas.addEventListener('mouseleave', onMouseLeave)
    canvas.addEventListener('touchmove',  onTouchMove, { passive: false })
    canvas.addEventListener('touchend',   onTouchEnd)

    let raf: number
    const clock = new THREE.Clock()
    let frameCount = 0

    const tick = () => {
      raf = requestAnimationFrame(tick)
      const t = clock.getElapsedTime()
      frameCount++

      const lerpRate = isHoveringTarget > isHovering ? 0.05 : 0.02
      isHovering += (isHoveringTarget - isHovering) * lerpRate

      const { halfW, halfH } = getWorldScale()
      const gpgpuTex = sim.tick(t, isHovering, mouseWorld, halfW, halfH)

      material.uniforms.uGpgpu.value      = gpgpuTex
      material.uniforms.uTime.value       = t
      material.uniforms.uIsHovering.value = isHovering
      material.uniforms.uMousePos.value   = mouseWorld

      // ── Update constellation lines every 2 frames (CPU readback) ──────────
      if (frameCount % 2 === 0) {
        // Read GPGPU positions from GPU
        renderer.readRenderTargetPixels(sim.currentTarget, 0, 0, SIM_SIZE, SIM_SIZE, gpuReadBuf)

        // Convert sim → world space
        for (let i = 0; i < pixelCount; i++) {
          worldPositions[i * 2 + 0] = gpuReadBuf[i * 4 + 0] * halfW * 2.0
          worldPositions[i * 2 + 1] = gpuReadBuf[i * 4 + 1] * halfH * 2.0
        }

        // Build line segments between close particles
        let lineCount = 0
        const mouseSimX = mouseWorld.x / halfW * 0.5
        const mouseSimY = mouseWorld.y / halfH * 0.5

        for (let a = 0; a < pixelCount && lineCount < MAX_LINES; a++) {
          const ax = gpuReadBuf[a * 4 + 0]
          const ay = gpuReadBuf[a * 4 + 1]

          // Skip particles very close to cursor (disrupted zone)
          const dxM = ax - mouseSimX
          const dyM = ay - mouseSimY
          if (isHovering > 0.3 && dxM * dxM + dyM * dyM < 0.012) continue

          for (let b = a + 1; b < pixelCount && lineCount < MAX_LINES; b++) {
            const bx = gpuReadBuf[b * 4 + 0]
            const by = gpuReadBuf[b * 4 + 1]
            const dx = ax - bx
            const dy = ay - by
            const d2 = dx * dx + dy * dy

            if (d2 < CONNECT_DIST * CONNECT_DIST) {
              const d      = Math.sqrt(d2)
              const fade   = 1.0 - d / CONNECT_DIST
              const idx    = lineCount * 6
              // World positions for line endpoints
              linePositions[idx + 0] = worldPositions[a * 2 + 0]
              linePositions[idx + 1] = worldPositions[a * 2 + 1]
              linePositions[idx + 2] = 0
              linePositions[idx + 3] = worldPositions[b * 2 + 0]
              linePositions[idx + 4] = worldPositions[b * 2 + 1]
              linePositions[idx + 5] = 0
              // Color: blend c1→c2 by distance, fade by proximity
              const col = c1.clone().lerp(c2, 1.0 - fade)
              lineColors[idx + 0] = col.r * fade
              lineColors[idx + 1] = col.g * fade
              lineColors[idx + 2] = col.b * fade
              lineColors[idx + 3] = col.r * fade
              lineColors[idx + 4] = col.g * fade
              lineColors[idx + 5] = col.b * fade
              lineCount++
            }
          }
        }

        lineGeo.setDrawRange(0, lineCount * 2)
        linePosAttr.needsUpdate = true
        lineColAttr.needsUpdate = true
      }

      renderer.render(scene, camera)
    }

    tick()

    return () => {
      cancelAnimationFrame(raf)
      ro.disconnect()
      canvas.removeEventListener('mousemove',  onMouseMove)
      canvas.removeEventListener('mouseenter', onMouseEnter)
      canvas.removeEventListener('mouseleave', onMouseLeave)
      canvas.removeEventListener('touchmove',  onTouchMove)
      canvas.removeEventListener('touchend',   onTouchEnd)
      sim.dispose()
      geometry.dispose()
      material.dispose()
      lineGeo.dispose()
      lineMat.dispose()
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
