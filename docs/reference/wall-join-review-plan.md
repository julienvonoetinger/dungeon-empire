# Revue des raccords de pierre

Demande du 23 octobre 2026 : corriger d'abord un raccord horizontal et un raccord
vertical et montrer un avant/après agrandi avant généralisation au kit.

## Cause confirmée

Le compositeur choisit une matière, une boîte de texture et un reflet pour chaque
région locale. Une pierre coupée à la frontière de deux cases devient ainsi deux
fragments indépendants. Le traitement périodique du sol ne couvre pas les murs.
Exemple : le dernier fragment de l'assise basse nord utilise `walls-layers`, le
premier de la case suivante `walls-planes`, avec des échelles différentes.

## Proposition de revue

- Réunir les guides et volumes de deux petits assemblages dans le même repère.
- Retrouver les pierres complètes à partir des joints visibles de l'assemblage.
- Les peindre une fois avec les matières actuelles et la finition B.
- Exporter chaque case séparément avec ses propres limites de volume, puis
  réassembler ses PNG pour vérifier le résultat présenté à l'utilisateur.
- Présenter les raccords horizontal, vertical et le retour d'angle en gros plan.

Ce premier export est une revue dédiée, sans remplacement des PNG actifs Godot.
Il permet d'évaluer la continuité. La généralisation devra définir les contextes
locaux réutilisables nécessaires, et ne pas créer de sprite propre à une salle.
La grille, les volumes, la projection et les matières restent ceux du kit actuel.
Aucun test automatisé n'est ajouté ou lancé ; les captures et rapports décrivent
les exports d'images. Aucun commit/push demandé pour cette étape.
