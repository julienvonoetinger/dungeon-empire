PALADIN — CHUTE VERS L'AVANT / 2026-11-01

CORRECTION DEMANDÉE
L'utilisateur rejette la chute latérale v5 comme une rotation de tronc. Réutiliser
le mouvement validé pour le Vulpin : genoux au sol, bras vers l'avant, torse au
sol, tête tournée. La v5 reste historique ; seuls les sprites/ancres/phases de
PaladinDeath et le repère d'ombre de mort sont remplacés. Dégâts et locomotion
gardent leurs fichiers et leurs hashes.

SOURCE DE MOUVEMENT
docs/reference/vulpin-review/v24-meshy-dead/render_fall.py est la recette déjà
validée. On adapte les longueurs et les indices d'os au modèle Paladin v3 :
pelvis000, torse004, cou017, tête016/015 ; brasR025/024/023, L021/020/019.
Le buste se plie indépendamment du bassin ; la tête tourne65° dans son repère.
Les genoux reçoivent le corps avant que les bras se tendent. Les avant-bras
tournent avec les poignets pour éviter une torsion brusque dans le gant.
La hauteur s'appuie sur les sommets réels de l'armure et des mains ; la pose
finale garde le torse près du sol, avec des coudes ouverts au-delà de150°.

Les armes doivent être lâchées avant la descente profonde : auparavant, elles
passaient sous le sol ou dans les avant-bras. La rotation s'effectue maintenant
autour du centre réel de chaque accessoire, avec un décalage vers l'extérieur
avant la rotation de chute. À partir de la pose3, les accessoires sont au sol.
Marteau àdroite du personnage, bouclier àgauche, près des genoux. Ils sont rendus
avec le corps, jamais collés en2D ni séparés àl'exécution.

FICHIERS ET RENDU
render_actions.py importe les helpers du rigv5, qui chargent le modèle équipév3.
Il conserve les18poses sources (8dégâts de référence,10mort), mais ne rend que
les40images de mort. Aucun changement de matériaux/mesh/sourceGLB.
320px finaux, maîtres640px, ortho3.25 et échelle.940425532 inchangés. La cible
caméra est abaissée de.72à.46 pour contenir la silhouette allongée ; l'ancre
devient(160,199.224289). La compensation d'ancre conserve le contact au sol
et la taille réelle du héros. Caméras30°, quatre directions non miroir.
10poses en750ms ; dernière pose maintenue. Le rythme n'est pas ralenti.
prepare.cjs remplace uniquement assets/previews/paladin-death etPaladinDeath.tscn.
Il ne touche pas aux dégâts, àla marche ou àla course. Les WebP ajoutent une
pause de revue ; SpriteFrames reste non bouclant. Sources exclues de l'export.

REPRODUCTION (racine du dépôt)
Blender5.2 : --background --python-exit-code 1 --python docs/reference/lithide-review/v6-forward-fall/render_actions.py
Validation : même commande avec verify_saved_actions.py puis verify_choreography.py.
Node/Sharp : node docs/reference/lithide-review/v6-forward-fall/prepare.cjs
Godot : --headless --path . --editor --import
Puis : --path . --script tools/verify_paladin_reactions.gd
Les chemins des exécutables et NODE_PATH sont dans ../v5-reactions/README.txt.
--pilot rend6images représentatives, --measure-only recalcule/sauve sans rendre.
Utiliser un Blender de fond séparé ; pas la scène ouverte de l'utilisateur.

CONTRÔLES
verify_choreography.py vérifie la demande indépendamment du générateur :
genoux bas, torse dirigé vers l'avant, torse/casque près du sol, mains avancées,
coudes tendus et poignets bas. L'ancien fichierv5 échoue sur7critères ; la
correction passe les10contrôles. Ce test ne remplace pas le jugement artistique.
verify_saved_actions.py relit réellement les18poses : contacts, attaches,
intersections équipement/corps, équipement/équipement, hashes et quatre caméras.
Les mains sont incluses aux intersections dès que les armes sont au sol.
Les premiers pilotes ont détecté une tête trop relevée et des intersections
d'équipement pendant le lâcher ; corrections conservées dans la recette.
Scène Godot : commandes de pause/relecture/pas/vitesse et pose finale maintenue,
trois formats, contrôles natifs et captures sous artifacts/paladin-forward-fall.
Résultats finaux :354contrôles natifs réussis, sortie0 et stderr vide ;18poses
relues et10contrôles de chorégraphie réussis.33fichiers dégâts/marche/course ont
exactement les hashes d'avant correction. Une revue indépendante a détecté une
rotation d'ombre partagée avec les dégâts :4échecs reproduits puis corrigés.
Mort :2 117 770octets de PNG,15.625MiB RGBA décodés, même quantité de pixels quev5.

LIMITES
Rendu de poses fixes, aucune simulation physique continue. Les tests d'arêtes
ne prouvent pas toutes les auto-intersections ou les volumes enfermés. Validation
artistique utilisateur et téléphone toujours distinctes. Aucun APK, sauvegarde
joueur, intégration aux raids, commit ou push.
