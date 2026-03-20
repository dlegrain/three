# Effects Library

## Shoal
**Dossier :** `src/components/GPGPUParticles_shoal/`

1024 particules (32×32 GPGPU) qui forment un anneau au repos et suivent le curseur comme un banc de poissons — l'anneau tourne sur lui-même et se déforme organiquement.

### Visuels
- Au repos : anneau unique serré centré à l'origine (r ≈ 0.22, width 0.06)
- Au hover : l'anneau se transpose autour du curseur et orbite lentement (r 0.08–0.15)
- Teardrops orientés dans la direction du mouvement au hover, tangents à l'anneau au repos
- Gradient : `#2c64ed` → `#f84242` → `#ffcf03`

### Technique
- GPGPU ping-pong **32×32** (1024 particules)
- Sim shader : orbit angle personnel par seed, vitesse 0.5–1.0 rad/s, pull ×2.5 au hover, composante tangentielle pour l'arc
- `uIsHovering` lerp asymétrique : 0.05 (entrée) / 0.02 (sortie) → settle organique
- Caméra perspective FOV 40°, z=3.1

---

## Orbit
**Dossier :** `src/components/GPGPUParticles_orbit/`

Trois anneaux concentriques de particules GPGPU sur fond blanc. Hover répulsif : les particules s'écartent du curseur et grossissent au passage.

### Visuels
- 3 anneaux : r=0.18 / 0.38 / 0.58 (40% / 35% / 25% des particules)
- Teardrops orientés tangentiellement, tailles variables par seed (0.5×–1.5×)
- Gradient 3 couleurs : `#2c64ed` → `#f84242` → `#ffcf03`
- Hover : répulsion douce + grossissement des particules proches + jitter ×2.5

### Technique
- GPGPU ping-pong 256×256
- Caméra perspective FOV 40°, z=3.1
- Sim shader : lifecycle seed-based, attraction smoothstep, répulsion hover
- Vertex shader : Simplex 3D deux fréquences (`×10 * 0.005 * dist` + `×0.5 * 0.02`)
- `uIsHovering` lerpé 0→1 sur mouseenter/mouseleave (vitesse 0.04/frame)

---

## Gravity
**Dossier :** `src/components/GPGPUParticles_gravity/`

1024 particules (32×32 GPGPU) qui flottent librement sur tout l'écran. Le curseur crée un champ de gravité : les particules proches sont absorbées, les lointaines à peine bougent. La densité se déplace avec le curseur sans migration de groupe.

### Visuels
- Au repos : nuage diffus centré, flottement organique via Simplex 3D
- Au hover : champ gravitationnel — les particules proches convergent vers le curseur, les lointaines restent en place. Effet "trou noir" local
- Pas d'anneau, pas de migration en masse — seulement un déplacement du centre de densité
- Teardrops `#2c64ed` → `#f84242` → `#ffcf03`

### Technique
- GPGPU ping-pong **32×32** (1024 particules)
- Gravité : `pos += toCursor * 0.04 * smoothstep(0.0, 0.5, dist) * smoothstep(0.8, 0.2, dist)` — pas de `normalize`, évite le jitter
- Force de retour vers `refPos` réduite à 20% au hover (`returnStrength = (1 - hover*0.8) * 0.01`) — les deux forces ne se battent pas
- `uIsHovering` lerp asymétrique : 0.05 (entrée) / 0.02 (sortie)
- Vertex shader : Simplex 3D deux fréquences pour flottement organique

---

## Ripple
**Dossier :** `src/components/GPGPUParticles_ripple/`

2304 particules (48×48 GPGPU) disposées en grille régulière, comme une surface d'eau calme. Le curseur génère des ondes concentriques qui se propagent à la vitesse de la lumière (enfin, du GPU).

### Visuels
- Au repos : grille légèrement animée par un bruit lent, couleur gris-bleu doux
- Au hover : ondes concentriques se propagent depuis le curseur, les particules proches s'agrandissent et changent de couleur (`#2c64ed` → `#f84242` → `#ffcf03`)
- Cercles mous (gaussian) au lieu de teardrops
- L'onde s'atténue exponentiellement avec la distance

### Technique
- GPGPU **48×48** (2304 particules) en grille régulière avec micro-jitter
- Sim shader : `wave = sin(d * 18.0 - time * 4.0)`, `envelope = exp(-d * 3.5) * hover`
- Pas de lifecycle — les particules restent en place, seule la taille pulse
- Fragment shader : cercle gaussien `exp(-d*d*20.0)`, couleur driven by `vVelocity` (wave intensity)

---

## Constellation
**Dossier :** `src/components/GPGPUParticles_constellation/`

1024 particules fixes comme des étoiles. Des lignes se tracent dynamiquement entre les particules proches, formant des constellations vivantes. Le curseur repousse les étoiles et les fait briller.

### Visuels
- Étoiles avec halo lumineux, scintillement individuel (fréquence et phase personnelles)
- Lignes semi-transparentes entre particules à moins de `0.18` (sim space), couleur `#2c64ed` → `#f84242` qui fade avec la distance
- Curseur : repousse les étoiles proches, les fait briller et rompt les connexions locales
- Ambiance : ciel étoilé vivant, réseau de constellations qui se redessine en temps réel

### Technique
- GPGPU **32×32** (1024 particules) avec orbites personnelles lentes autour de `refPos`
- `LineSegments` dynamiques : lecture GPU chaque 2 frames via `readRenderTargetPixels`, O(n²) avec seuil de distance
- `MAX_LINES = 2000`, `CONNECT_DIST = 0.18`
- Fragment shader : core `smoothstep(0.18, 0)` + halo `smoothstep(0.5, 0) * 0.4`

---

## Breath
**Dossier :** `src/components/GPGPUParticles_breath/`

1024 particules qui respirent en rythme lent. L'onde de respiration se propage radialement depuis le centre (comme des ronds dans l'eau). Le curseur crée une zone de contre-rythme — quand le reste s'expanse, la zone curseur se contracte.

### Visuels
- Au repos : expansion/contraction lente (~1.2Hz) avec propagation radiale (vague qui parcourt l'écran)
- Au hover : zone de contre-phase autour du curseur — les particules y font l'inverse, créent un creux dans la vague. Couleur `#ffcf03` (chaud) vs bleu/rouge au repos
- Cercles gaussiens flous qui gonflent et dégonflent
- Effet hypnotique et organique

### Technique
- GPGPU **32×32** avec `phaseOffset = distFromCenter * 2.5 + seed * 0.8` pour propagation radiale
- `breathCycle = sin(time * 1.2 + phaseOffset)`, amplitude 12% sur position, 60% sur scale
- Contre-phase : `sin(time * 1.2 + phaseOffset + PI)` dans zone `smoothstep(0.3, 0, dCursor) * hover`
- Fragment shader : `exp(-d*d*20.0)` avec couleur lerp `uColor1 → uColor2 → uColor3`

---

## Aurora
**Dossier :** `src/components/GPGPUParticles_aurora/`

Anneau de particules GPGPU sur fond blanc, inspiré de Google Antigravity (light theme).

### Visuels
- Particules en forme de **teardrops orientés** tangentiellement à l'anneau (`sdRoundBox` rotaté)
- Gradient 3 couleurs : `#2c64ed` → `#f84242` → `#ffcf03` (bleu → rouge → jaune)
- L'anneau suit le curseur avec lag, dérive autonomement sans souris

### Technique
- GPGPU ping-pong 256×256 (65k particules)
- Caméra perspective FOV 40°, z=3.1
- Sim shader : lifecycle par seed (`lifeEnd = 3 + sin(seed2*100)`), attraction smoothstep, fade in/out
- Vertex shader : bruit Simplex 2 fréquences (`*10 * 0.005 * dist` + `*0.5 * 0.02`)
- Rayon oscillant : `0.175 + sin(t)*0.03 + cos(t*3)*0.02`
