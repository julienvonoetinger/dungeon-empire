# Vantail lisse : un contour, une texture libre

**Structure validée : « Ok », le 24 octobre 2026.** `selection.json` enregistre
les empreintes exactes. Le rendu préparé est dans [painted-v8](../painted-v8/).

À la demande de l'utilisateur, cette proposition retire les guides de planches
et de poignée à l'intérieur du bois. Le wireframe définit son contour arrondi,
son volume et les occultations, sans imposer le dessin de sa surface.

Les volumes restent ceux de la v7 : deux arches distinctes, mur lisse plein
entre elles à 80 % de leur profondeur, et petit vantail de rayon .26 case.
Les arêtes cachées restent omises. Aucun nouveau joint n'est ajouté.

La texture pourra apporter des planches, des veines ou des décors, tout en
respectant ce masque et la perspective. Poignée et ferrures pourront être
peintes ou préparées séparément ; leur absence du guide ne les interdit pas
dans le rendu final. Une poignée devra rester visible sur les deux faces.

```powershell
node tools/prepare_mobile_nested_arch_wireframe.cjs
```

- `wireframe.png` / `wireframe.svg` : vue de face et perspective dans le couloir.
- `perspective.png` : perspective seule.
- `geometry.json` : volumes et contours ; aucun trait intérieur du bois.

Le rendu `painted-v7/` reste figé ; le script utilise désormais cette géométrie
v8 pour la nouvelle revue. Aucun changement aux sprites du kit actif ou aux
scènes Godot. Aucun test automatisé ajouté ou exécuté.
