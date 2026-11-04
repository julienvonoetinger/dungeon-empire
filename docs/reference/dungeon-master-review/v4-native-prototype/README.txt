MAITRE D'ENERGIE — PROTOTYPE ANIME NATIF
4 novembre 2026

Ouvrir scenes/previews/EnergyMasterPreview.tscn dans Godot, ou lancer :
  godot --path . res://scenes/previews/EnergyMasterPreview.tscn

Prototype distinct de l'introduction et de l'oeil du HUD. Aucun GameSession,
acces aux sauvegardes, modele Meshy, texture generee ou changement du sanctuaire.

Structure : vraie sphere noire opaque, trois surfaces d'iris courbes,
disque d'accretion incline traversant l'avant et l'arriere, deux arcs d'oeil,
64 particules en MultiMesh. Six surfaces d'energie utilisent un shader spatial
et une seule horloge explicite. Les surfaces arriere sont masquees par la sphere.
Le mouvement de leurs motifs, la rotation et les particules utilisent present().
Le shader n'utilise pas TIME. Les sommets restent statiques hors faible ondulation
GPU ; seuls 64 transformes de particules sont mis a jour cote CPU.

Cycle de 24 secondes : eveil 0-3, formation du regard 4-8, observation jusqu'a
17, relachement jusqu'a 21, dissipation 22-24. Controles : pause/reprise, rejouer,
forcer le regard, rotation automatique, recherche dans le temps et angle de vue.
Le fond du SubViewport est opaque et correspond au fond de l'apercu : cela evite
la double attenuation des effets additifs lors d'une composition alpha. Ce
choix devra etre adapte lors d'une future integration transparente au sanctuaire.

Validation sur Godot 4.7.2, GL Compatibility, RTX4090 : import et compilation
GPU sans erreur ; fixture native artifacts/energy-master/check.gd : zero echec.
Pause/reprise, changement visuel reel, retour au meme instant pixel-identique,
controles en 1280x720,390x844,844x390 et capture a 38 degres verifies.
Le controle negatif -- --missing echoue avec sortie 1 comme attendu.
Revue independante des quatre fichiers et captures : aucun point important.

animation.webp : capture reelle du SubViewport a 480x480, 15 images/s,
24 secondes avec rotation active. 360 captures ; WebP peut regrouper les
images identiques (359 pages finales), duree decodee verifiee a 24 000 ms.
Le programme interactif anime en continu au rythme de rendu ; la capture
WebP a une cadence reduite pour la revue. Les captures sont dans artifacts/.
prepare.cjs reproduit l'encodage et copie les deux captures fixes.

Limites : premier prototype de volume et de mouvement. Les courants restent
proceduraux et ne reproduisent pas exactement le detail peint du concept.
Pas de vraie lentille gravitationnelle/deformation du decor, son, reactions
des Oculins, illumination du sanctuaire ou integration a la mise en scene.
Pas de mesure sur telephone ni sur les autres moteurs de rendu. Validation
artistique attendue avant les prochaines etapes. Aucun commit/push/APK.
