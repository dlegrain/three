import { GPGPUParticles } from './components/GPGPUParticles'
import './App.css'

function App() {
  return (
    <div className="app">
      <GPGPUParticles
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
    </div>
  )
}

export default App
