PALADIN — DÉGÂTS ET MORT / 2026-11-01

MISE À JOUR : l'utilisateur a rejeté la chute latérale. La mort est remplacée
par ../v6-forward-fall (genoux puis ventre au sol, comme le Vulpin). Les dégâts
restent dans cettev5. Ne pas réinstaller les anciennes feuilles de mort.
Le script de préparationv5 ne traite désormais que les dégâts ; les anciennes
images/planches de mort sont conservées pour comparaison historique.

Animations de revue, pas encore branchées aux raids. Modèle équipé v3 approuvé,
GLB d'origine, matériaux et textures inchangés. Tout le personnage et ses
accessoires sont rendus ensemble : aucun découpage de membres en sprites.

CHOIX DE MOUVEMENT
Dégâts : 8 poses, 720 ms (65/65/90/115/100/95/90/100). Pieds plantés, recul
du buste jusqu'à14°, bouclier ramené, retour exact à la pose neutre. Pas de
déplacement de la cellule pendant la réaction.
Mort :10 poses,750 ms (55/65/75/85/80/70/70/65/80/105). Les genoux cèdent avant
la rotation latérale. Les bras se replient, les mains lâchent les accessoires
qui se posent à côté. Le corps s'appuie sur l'épaule et la jambe, puis reste
immobile. La répétition est désactivée dans les scènes et les SpriteFrames.
Les WebP de revue répètent avec1.2 seconde de pause ; ce n'est pas la logique
de mort du jeu. Le choix artistique reste à valider par l'utilisateur.

CORRECTIONS DE LA PREMIÈRE PASSE
- Le marteau tenu à la main touchait le sol avant le corps et soutenait la chute.
  Sa libération est maintenant posée en3D et enregistrée dans le fichier source.
- Le bras inférieur trop écarté relevait la masse du corps : les bras se replient
  pendant la chute. Les doigts se desserrent et la hauteur de contact est reprise
  après leur déformation.
- Le marteau tombe autour de Y pour que son manche ET sa tête restent parallèles
  au sol. Une rotation autour de X le faisait rester sur une extrémité de tête.
- Les poses sont CONSTANT dans Blender. Aucune promesse de physique continue ;
  ce sont des poses fixes choisies puis rendues, conformément au pipeline.

REGISTRATION ET QUALITÉ
Caméras30° orthographiques, quatre directions réelles. Même densité que v4 :
256/2.6 = 320/3.25 pixels par unité. Dégâts512→256px, mort640→320px pour contenir
corps et équipement au sol sans réduire le héros ni rogner les images.
Ancre dégâts(128,189.394539), mort(160,221.394539), échelle Godot.940425532.
Lumières tournées avec la caméra, matériaux d'origine,32samples+denoising.
La réduction est uniforme, aucune peinture par script.

SOURCES
- rig.py reprend les helpers géométriques v4 et charge le modèle équipé v3.
  mesh_checks.py reste partagé depuis v4-locomotion.
- render_actions.py : poses, attaches, libération d'équipement, caméras et rendus.
- paladin-action-poses.blend :18poses avec9textures embarquées.
- poses.json : géométrie, contacts, attaches, timings et ancres des caméras.
- verify_saved_actions.py : relecture réelle, contacts et intersections.
- prepare.cjs : réduction/atlas/SpriteFrames/scènes/WebP/planches.
- assets/previews/paladin-hurt et paladin-death :4atlas par action.
- scripts/paladin_action_preview.gd : scène commune isolée, aucun DungeonGame.
- tools/verify_paladin_reactions.gd : comportement natif et captures.
Le répertoire docs est exclu des exports par docs/.gdignore.

REPRODUIRE DEPUIS LA RACINE (PowerShell)
$blender='C:/Program Files/Blender Foundation/Blender 5.2/blender.exe'
$node='C:/Users/A/.cache/codex-runtimes/codex-primary-runtime/dependencies/node/bin/node.exe'
$env:NODE_PATH='C:/Users/A/.cache/codex-runtimes/codex-primary-runtime/dependencies/node/node_modules'
& $blender --background --python-exit-code 1 --python docs/reference/lithide-review/v5-reactions/render_actions.py
& $blender --background --python-exit-code 1 --python docs/reference/lithide-review/v5-reactions/verify_saved_actions.py
& $node docs/reference/lithide-review/v5-reactions/prepare.cjs

Godot : --headless --path . --editor --import, puis
--path . --script tools/verify_paladin_reactions.gd
Exécutable : C:/Program Files (x86)/Steam/steamapps/common/Godot Engine/godot.windows.opt.tools.64.exe
Sur Windows, utiliser Start-Process -PassThru -WindowStyle Hidden, conserver
le Handle puis WaitForExit pour récupérer le vrai code de sortie.
--pilot après -- limite à10images/16samples ; --measure-only ne rend pas.
--death-only ne refait que40images de mort, mais recalcule/sauve les18poses.
Toujours utiliser un Blender de fond distinct, pas une scène ouverte de l'utilisateur.

VALIDATION ET LIMITES
350contrôles natifs réussis, sortie0, stderr vide. Lecture réelle, pause/pas,
retour neutre, maintien du mort, réactivation,×0.5/1/2, répétition facultative,
ancrage et trois formats (1280×720,844×390,720×960). Le paysage court présente
les4vues sur une rangée ; les boutons gardent48px. Le stretch de cette fenêtre
de revue est désactivé temporairement puis restauré à sa fermeture.
Captures et journaux : artifacts/paladin-reactions. Échec initial attendu :
2scènes absentes, avant création des ressources.
Revue indépendante : aucun défaut actionnable après lecture du code, des
résultats et des vues natives/maîtres finales. Cette revue ne remplace pas la
validation artistique de l'utilisateur.
PNG : dégâts1 500 505octets ; mort2 129 029octets ; total3 629 534(~3.63MB).
RGBA décodé :8MiB dégâts,15.625MiB mort,23.625MiB si tout est chargé ensemble.
18poses relues, contacts réels au sol et retour neutre, proportions conservées,
ancres communes et toutes les silhouettes dans les4caméras. Intersections
arêtes/triangles équipement/corps et équipement/équipement contrôlées ; les mains
de prise sont exclues avant libération, incluses dès que les accessoires sont
au sol. Les GLB et le .blend équipé v3 restent inchangés.
Ces contrôles ne prouvent pas toutes les auto-intersections de l'armure, ni les
volumes entièrement contenus. Aucun profilage sur téléphone, APK, intégration
aux raids, sauvegarde joueur, commit ou push. Les ombres des scènes sont de simples
repères de contact, pas un système d'éclairage de gameplay.
