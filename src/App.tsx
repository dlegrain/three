import { useState } from 'react'
import { GPGPUParticles as Gravity }        from './components/GPGPUParticles'
import { GPGPUParticles as Ripple }         from './components/GPGPUParticles_ripple'
import { GPGPUParticles as Constellation }  from './components/GPGPUParticles_constellation'
import { GPGPUParticles as Breath }         from './components/GPGPUParticles_breath'
import './App.css'

const EFFECTS = [
  { id: 'gravity',       label: 'Gravity',       Component: Gravity },
  { id: 'ripple',        label: 'Ripple',         Component: Ripple },
  { id: 'constellation', label: 'Constellation',  Component: Constellation },
  { id: 'breath',        label: 'Breath',         Component: Breath },
] as const

function App() {
  const [activeIdx, setActiveIdx] = useState(0)
  const { Component } = EFFECTS[activeIdx]

  return (
    <div className="app">
      <Component
        color1="#2c64ed"
        color2="#f84242"
        color3="#ffcf03"
        alpha={0.95}
        particleScale={0.75}
        className="particles-canvas"
      />

      <div className="title-wrapper">
        <div className="title-eyebrow">
          <span className="dot" />
          <span>Experimental Interface</span>
          <span className="dot" />
        </div>

        <h1 className="title-main">
          <span className="title-word title-word--diederick">Diederick</span>
          <span className="title-spacer" />
          <span className="title-word title-word--ai">AI</span>
          <span className="title-word title-word--lab">Lab</span>
        </h1>

        <div className="title-sub">
          <span className="title-sub-line" />
          <span className="title-sub-text">Research · Design · Intelligence</span>
          <span className="title-sub-line" />
        </div>
      </div>

      <nav className="effect-toggle">
        {EFFECTS.map((e, i) => (
          <button
            key={e.id}
            className={`effect-btn${i === activeIdx ? ' effect-btn--active' : ''}`}
            onClick={() => setActiveIdx(i)}
          >
            {e.label}
          </button>
        ))}
      </nav>
    </div>
  )
}

export default App
