# Raccords du sol et assise du cœur — 24 octobre 2026

## Sol

Le guide visible était coupé à la limite de chaque case. Le calcul de finition
attendait les arêtes complètes des pierres qui traversent cette limite : 18
arêtes étaient donc interprétées comme des coupes ouvertes, sans arrondi ni
biseau. La finition utilise désormais les contours des pierres entières avant
découpage. Le guide magenta visible conserve ses coordonnées.

Une couverture périodique de deux pixels source autour du losange évite ensuite
les filets de transparence dus au filtrage linéaire. Les rangées voisines gardent
les mêmes coordonnées de matière et graines de variation. Le cadre PNG passe de
260×132 à 270×138 ; les limites logiques restent [0,0,0]–[1,1,0].

## Cœur

La tranche du socle échantillonnait les lignes 250–260 de l'ancienne peinture,
incluant son ombre de contact puis rendue opaque sur la face. Elle échantillonne
maintenant la pierre des lignes 242–252. L'assise reste à z=0, le vortex et les
volumes ne changent pas. L'illustration approuvée d'origine reste intacte.

## Reproduction et preuves

Après l'export actif et les captures Godot habituelles :

```powershell
node tools/prepare_isometric_floor_contact_review.cjs
```

`before/` conserve les captures, sprites, catalogue et empreintes précédents.
La planche `comparison.png` montre le motif du sol assemblé au zoom .75 puis
les captures Godot du cœur agrandies ×2. `bevel-only-detail.png` documente l'étape
intermédiaire avant correction des filets de transparence.

Seuls `floor.png` et `heart.png` changent parmi les PNG préparés. La géométrie
figée reste identique. Les 68 captures runtime / 23 scènes sont renouvelées,
ainsi que 21 captures éditeur / cinq scènes. L'éditeur sort à 0 mais conserve
ses diagnostics natifs de fenêtre/progression et de ressources à l'arrêt.
Import runtime et import/export/ouverture du paquet isolé sortent à 0 avec stderr
vide. Le paquet de ressources fait 436 713 octets ; ce n'est pas un APK.

Revue indépendante du code et des images : aucun constat restant. Pas de tests
automatisés, de profilage sur téléphone, de commit ni de push dans cette correction.
