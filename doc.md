Documentation officielle
Three.js

https://threejs.org/docs/ — la référence officielle
https://threejs.org/examples/ — des centaines d'exemples avec code source

Claude Code peut aller lire ces pages directement. Dis-lui : "Va sur threejs.org/examples et trouve les exemples de GPGPU particles"

GitHub de référence
Three.js lui-même

https://github.com/mrdoob/three.js — le repo principal, les examples sont dans /examples/
Cherche dans /examples/jsm/ pour les helpers comme GPUComputationRenderer — c'est le helper GPGPU officiel de Three.js

Exemples GPGPU spécifiques dans le repo Three.js :

https://github.com/mrdoob/three.js/blob/master/examples/webgl_gpgpu_birds.html
https://github.com/mrdoob/three.js/blob/master/examples/webgl_gpgpu_water.html
https://github.com/mrdoob/three.js/blob/master/examples/webgpu_compute_particles.html


Pour le bruit Simplex (le flottement organique)

https://github.com/ashima/webgl-noise — la lib de bruit GLSL que Google utilise littéralement dans son code (${zp.noise} qu'on a vu dans les shaders)