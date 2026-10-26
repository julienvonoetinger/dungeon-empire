# Catalogue direct, timer et jauges — 26 octobre 2026

Rendu natif de `DungeonGame`, après les retours sur la navigation, les marges,
le timer et les indicateurs des coffres/pièges. L'apparence reste ouverte aux
retours ; ce relevé n'est pas une approbation artistique.

- Deux niveaux : famille puis variante. Portes et pièges sont séparés.
- Listes avec icônes de 30 unités, contenu centré verticalement, cartes de
  variantes de 72 unités minimum. Les petits carrés intermédiaires ont été
  rejetés et retirés. Les familles défilent sur les écrans courts.
- Timer fixe, padding de 12 unités ; statut de pause dans son titre sur écran
  court, sous le compteur sur grand écran. Ses règles de décompte sont conservées.
- Ressources dans un bloc indépendant, visible dans les sous-menus ; pas de
  double cadre ni de répétition de l'or/vie dans le menu du domaine.
- Espaces entre les cadres transparents sur la roche existante. Un quadrilatère
  reprend les coordonnées mondiales et le shader de roche, sans nouveau PNG ni
  second rendu du donjon sous l'interface.
- Anneaux dorés avec tas de pièces : remplissage des coffres. Anneaux cuivrés
  avec l'icône du piège : charges restantes. Leur taille de 32 unités d'écran
  reste lisible au redimensionnement ; ils passent au-dessus de la maçonnerie.

`tools/capture_forge_navigation.gd` enregistre 80 présentations sur cinq formats
(740×360, 844×390, 1280×720, 390×844 et 320×568), plus une extension. Les fixtures
sont uniquement en mémoire, processus de jeu arrêté : coffres vides, à moitié
pleins et pleins, pièges épuisés et partiellement chargés, états du menu et du
timer. `presentation.json` décrit la géométrie native des contrôles ; `captures/`
contient les PNG. Les sessions joueur et les anciens relevés restent intacts.
L'import final et la capture native se terminent avec le code 0 et un stderr
vide (`artifacts/forge-navigation-{import,capture}.*.log`). Les vues courtes,
étroites, de catalogue, du domaine et de bas de liste ont été inspectées.

Il s'agit de captures natives et de revue de source, pas de tests automatisés,
de validation tactile sur téléphone ou d'une mesure de performances. Les gestes
de placement et une partie complète n'ont pas été rejoués dans cette passe.

Retour suivant : le bloc ressources utilisait trop peu sa largeur. Les colonnes
s'étendent maintenant : or à gauche, vie à droite, marge extérieure de 14 et
écart icône/valeur de 8. En disposition verticale, les nombres s'alignent à droite.
Dix nouvelles vues natives sur cinq formats sont conservées dans
`../resource-spacing/` ; capture avec `--resource-spacing`, sortie 0/stderr vide.
