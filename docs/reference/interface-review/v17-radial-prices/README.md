# Menu radial : taille et coûts

Correction demandée après comparaison avec le PDF « Dungeon Empire — refonte mobile v2 », p.1 et p.3/9 : secteurs jointifs, icônes libérées du texte, bande de prix extérieure et mise en évidence au toucher. Les montants illustratifs du PDF ne remplacent pas les coûts réels.

- Diamètre préféré252→352 unités (+40%). Adaptation à l’espace sûr : indications à côté sur les paysages courts, puis diminution des rayons. Directions des quatre familles inchangées. Icônes agrandies et proportions conservées ; leur rectangle reste dans le secteur.
- Prix dans un anneau24 unités (20 en mode très court), caractères16/14 au lieu de12. Bande sombre au repos, dorée pour une action valide pressée/survolée. Toute la bande appartient à la cible tactile de l’action. Prix gratuit0, prix variable indisponible— ; détails explicites dans la légende.
- Centre « Tout » avec icône de catalogue. Zone tactile réellement circulaire pour ne pas intercepter les coins des familles. Camera/HUD utilisent maintenant le centre dynamique au lieu de(130,130).
- Le radial gère directement ScreenTouch/ScreenDrag et ignore la souris synthétique de ce même doigt. Annulation, multitouch, rotation et glissé aller-retour ne peuvent acheter. Conservation du signal de refus vers l’œil et des règles de transaction.

## Vérification

`tools/verify_build_radial.gd` : session native avec persistance désactivée avant entrée dans l’arbre ; taille/cible extérieure échouaient avant correction. Revue indépendante : petit paysage480×320 corrigé et coins carrés de « Tout » reproduits par quatre vrais clics avant correction. Résultat final1 589 contrôles,0 échec, stderr vide.11 formats de1280×720 à320×568,480×320 et568×299, quatre coins du monde, familles/prix, recadrage, pressions réelles via viewport, achat tactile unique, annulations et centre de catalogue. Échantillons de pixels vérifient la couleur de la bande ; captures inspectées. Rapports complets dans `artifacts/radial-review`, résumé conservé dans `validation.json`.

Tests existants : `verify_master_mobile.gd` (transactions, annulation, commandes et simulation), `verify_mobile_rotation.gd` (227 contrôles). Pas de nouvelle illustration ni texture de production. Pas de test sur téléphone physique, de profil de performance, d’APK, de commit ou de push.

## Pourcentage sous l’œil

Après signalement du débordement de100%, le texte est ancré à l’intérieur peint de la petite pierre (rectangle76,166,78,18 dans le centre230×192), avec police12/10 selon la hauteur96/84 et suppression de son seul contour/ombre. Le pourcentage complet reste affiché. `verify_header_health.gd` mesure les pixels visibles des caractères :16 cas dépassaient avant correction,32 contrôles passent après. Les856 contrôles du bandeau et1589 du radial passent également ; captures de cette page actualisées. `health-validation.json` conserve les mesures et `captures/health-label.png` le détail natif agrandi.
