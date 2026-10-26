# Interface du maître — intégration native

Référence : PDF « Dungeon Empire — refonte mobile v2 » et capture24818 du bandeau, suivis de la demande d’implémentation. La peinture est une adaptation reconstruite depuis la capture, pas un export original de Claude Design.

## Intégré
- Monde plein écran, zoom fixe et panoramique conservés. Bandeau pierre/fer/corruption, vortex animé, dix segments de vie, pourcentage exact, timer de phase et or réels. Jauges passives sans poignée de réglage.
- Trois familles d’objets et le terrain accessibles par quatre quartiers fixes. Une case libre ouvre le radial ; choisir un objet valide pose une fois et arme la répétition. Les cases autorisées sont soulignées dans le plan isométrique. Fermer/Retour ne dépense rien.
- Catalogue à quatre onglets, progression réelle et défilement ; feuilles en bas en portrait et à droite en paysage. Fiches d’objets, réparation avec confirmation et transferts entiers conservés.
- Commandes Catalogue/Accès/Annuler/Pause, retour explicite de pose, guide d’accès géométrique, vitesses1×/2× et bilan compact. Le guide ne prédit pas les décisions de l’IA.
- Sur paysage court, les indications du radial passent à côté des anneaux. Épaisseur utile des quartiers48 unités ; maximum5 variantes rapides par famille, catalogue complet via Tout.

## Vérification
- `tools/verify_master_mobile.gd` : transactions réelles, ouverture sans achat, débit unique, répétition, refus sans débit, conservation de l’outil pendant le pan, pause, HUD sans clic traversant, annulation/multitouch, quatre coins à740×360/320×568/667×375/568×320/568×299, erreur d’écriture affichée, deux pas de simulation bornés à2× et arrêt en pause. Exécution finale : zéro échec, stderr vide.
- `tools/capture_master_mobile.gd` :112 captures GPU natives,16 états sur sept formats. Timer, ressources, familles verrouillées/débloquées, pose, sélection, transfert, pause, résultat, accueil, reset, défaite et erreur de sauvegarde. Mesure des libellés simples : aucun débordement. Vues portrait/paysage, radial court, catalogue et états critiques inspectés visuellement.
- Import Godot4.7.2 : code0, stderr vide. Revue indépendante : erreurs d’écriture masquées, réarmement multitouch, police non-MSDF et petit paysage corrigés. Les échecs comportementaux ont été reproduits avant correction.
- Tests/captures utilisent uniquement des chemins de revue ou `artifacts/`, jamais la sauvegarde normale. Pas de commit ni push.

## Sources et coût
- `source/header.png` et `source/eye.png` générés avec ImageGen intégré ; prompts dans `source/provenance.json`. Recadrage de préparation, alpha natif et réduction uniforme via `tools/prepare_master_ui.cjs`.
- Icônes de pièges composées à partir de l’atlas actuel ; aucun sprite du donjon repeint. Cinzel provient de Google Fonts, licence OFL livrée dans `assets/ui/master/fonts/` ; rendu MSDF.
- Nouveaux fichiers de production : environ520Kio, police comprise. Les PNG du HUD représentent moins de0,8Mio RGBA sans mipmaps. Ce ne sont ni une mesure d’APK ni un profil GPU. Sources/captures restent sous `docs/.gdignore`.

## Limites
- Pas de téléphone physique, gestes multitouch matériels, safe areas de périphérique ou profil de performances mobile validés. Les tests utilisent le flux d’événements natif Godot et des tailles logiques.
- Pas d’audit complet de campagne/sauvegarde ni d’enregistrement/partage de replay. Les nouveaux types de pièges illustratifs, raids multihéros et récompenses inventées du PDF ne sont pas ajoutés.
- L’œil tourne et réagit à la vie/pause ; les six animations émotionnelles illustrées dans la planche ne sont pas encore produites. Le catalogue arme au toucher ; aucune fiche longue-pression supplémentaire n’est incluse dans cette première intégration.
- Le déplacement près d’un bord recadre immédiatement la case ; pas encore de transition de caméra animée.
