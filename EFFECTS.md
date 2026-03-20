# Effects Library

## Vortex
**Dossier :** `src/components/GPGPUParticles_vortex/`

4096 particules (64×64 GPGPU) qui tournent en spirale autour du curseur. La force tangentielle crée une rotation orbitale ; une légère aspiration centripète maintient la spirale sans provoquer d'entassement.

### Visuels
- Au repos : nuage diffus avec flottement organique
- Au hover : spirale rotative autour du curseur — les particules tournent en orbite et gardent leur distance
- Glow additif : cercles gaussiens, core blanc au centre de la spirale
- Couleurs : `#1a0aff` (bleu profond) → `#ff3aff` (magenta) → `#ffffff` (blanc, cœur)
- Additive blending → effet lumineux sur fond sombre

### Technique
- GPGPU ping-pong **64×64** (4096 particules)
- Force tangentielle : `tangent = vec2(-toCursor.y, toCursor.x)` (perpendiculaire, normalisée)
- Inward pull faible (`0.004`) pour spirale légère sans clumping au centre
- Force de retour active même en zone vortex (`returnStr = (1 - influence * 0.5) * 0.012`)
- `velocity` encode l'influence vortex → luminosité/couleur

---

## DNA
**Dossier :** `src/components/GPGPUParticles_dna/`

1024 particules (32×32 GPGPU) organisées en double hélice 3D projetée en 2D. La rotation est continue. Le curseur "dénature" l'ADN — les deux brins s'écartent latéralement au survol.

### Visuels
- Double hélice verticale, 8 tours, deux brins (phase opposée = `±PI`)
- Projection perspective simple : `x_proj = cos(angle) * r * (0.7 + sin(angle) * 0.3)`
- Couleur selon hauteur Y : `#00ffcc` (cyan) → `#0066ff` (bleu) → `#ffffff` (blanc, dénaturation)
- Additive blending — les croisements s'illuminent

### Technique
- GPGPU ping-pong **32×32** (1024 particules)
- Index de particule (`idx`) détermine : strand A (idx < 512) ou strand B (idx ≥ 512)
- `helixAngle = tStrand * 8 * 2PI + uTime * 0.8`
- Dénaturation : `targetPos.x += strandSign * denature * 0.15` + chaos seed
- `velocity` encode l'état de dénaturation → shift couleur vers blanc

---

## Fracture
**Dossier :** `src/components/GPGPUParticles_fracture/`

2304 particules (48×48 GPGPU) en grille parfaite — comme des carreaux de verre. Le curseur déclenche une onde de choc qui brise la grille ; les éclats partent en rotation puis se reconstituent.

### Visuels
- Au repos : grille régulière de petits carreaux (`#445566`, gris-bleu)
- Sur hover/click : onde de choc se propageant depuis le curseur (`shockRadius = shockTime * 0.6`)
- Les fragments impactés explosent en direction radiale, tournoient sur eux-mêmes, puis retournent en place
- Couleur au choc : `#445566` → `#ff6600` → `#ffeecc` (orange chaud, éclat)
- Forme : `sdBox` rotaté par seed → carreaux irréguliers, pas des ronds

### Technique
- GPGPU ping-pong **48×48** (2304 particules), grille exacte
- `uShockTime` : timer CPU remis à 0 sur `mouseenter` et `click`, incrémenté chaque frame
- Onde de choc : `onWaveFront = exp(-((distToRest - shockRadius) / 0.08)² * 12)`
- Direction d'explosion : mix 50/50 radiale + fractureDir (seed)
- Retour : spring amorti `pos += normalize(toRef) * min(dist,0.2)/0.2 * returnStr * dist * 5`

---

## Aurora
**Dossier :** `src/components/GPGPUParticles_aurora/`

Anneau de 4096 particules (64×64 GPGPU) qui respire et suit le curseur. Inspiré de Google Antigravity (light theme).

### Visuels
- Teardrops orientés tangentiellement à l'anneau (`sdRoundBox` rotaté vers le centre)
- Gradient : `#2c64ed` → `#f84242` → `#ffcf03`
- L'anneau suit le curseur avec lag (`lerp 0.015`), dérive autonomement sans souris

### Technique
- GPGPU ping-pong **64×64** (4096 particules)
- Rayon oscillant : `0.175 + sin(t)*0.03 + cos(t*3)*0.02`
- Sim shader : lifecycle par seed, attraction smoothstep, bruit multi-fréquences
- Vertex shader : Simplex 3D deux fréquences pour flottement organique

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

16 384 particules (128×128 GPGPU) en grille fixe. Chaque mouvement de curseur déclenche une seule vague concentrique qui se propage depuis le curseur jusqu'au bord de l'écran, puis disparaît.

### Visuels
- Au repos : grille de minuscules points quasi invisibles (gris-bleu très doux)
- Sur mouvement : un unique anneau s'élargit depuis le curseur — les points qu'il traverse grossissent et s'illuminent (`#2c64ed` → `#f84242` → `#ffcf03`)
- Une seule vague par geste (pas de répétition continue) — déclenchée uniquement sur `mousemove`
- Les points restent fixes — seule leur taille et couleur changent au passage de l'onde

### Technique
- GPGPU **128×128** (16 384 particules) en grille régulière, positions fixes (pas de déplacement XY)
- `uWaveTime` : timer remis à 0 sur chaque `mousemove` (cooldown 0.8s), incrémenté chaque frame
- Front de vague : pic gaussien `exp(-diff² * 200)` autour de `waveRadius = uWaveTime * 0.7`
- Fade-out : `smoothstep(1.0, 0.8, waveRadius)` — la vague s'éteint en atteignant le bord

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
- GPGPU ping-pong **64×64** (4096 particules)
- Caméra perspective FOV 40°, z=3.1
- Sim shader : lifecycle par seed (`lifeEnd = 3 + sin(seed2*100)`), attraction smoothstep, fade in/out
- Vertex shader : bruit Simplex 2 fréquences (`*10 * 0.005 * dist` + `*0.5 * 0.02`)
- Rayon oscillant : `0.175 + sin(t)*0.03 + cos(t*3)*0.02`
