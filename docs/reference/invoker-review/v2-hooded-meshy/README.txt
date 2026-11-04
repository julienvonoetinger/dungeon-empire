INVOCATEUR OCULIN ANCIEN - REFERENCES POUR MESHY
4 novembre 2026

Direction approuvee : silhouette distincte du peuple Oculin, grande capuche
ouverte, long manteau rituel fendu, allure plus voutee et moins massive.
Correction utilisateur : le premier essai encapuchonne ressemblait a un enfant.
Il est conserve dans source/front-young-rejected.png, et ne doit pas etre
utilise dans le pack. La face retenue doit montrer un ancien shaman adulte.

Images individuelles dans meshy/character :
01-front.png - face ; 02-left.png - profil gauche ;
03-back.png - dos ; 04-right.png - profil droit.
Pose neutre, mains libres, fond transparent natif. Ne pas utiliser la planche
four-views.png comme une vue du personnage : elle sert uniquement a comparer.

Sources natives ImageGen et prompts conserves dans source/.
Le premier dessin utilisait la proposition v1 comme reference anatomique.
La correction d'age utilise ce premier dessin et l'ancien du storyboard
(assets/game/introduction/invocation/elder.webp). Les vues suivantes prennent
la nouvelle face comme identite fixe. provenance.json et validation.json
enregistrent les sorties, hashes, dimensions et ecarts de cadrage.

Reproduction du conditionnement :
  $env:NODE_PATH = "$PWD/artifacts/sanctuary-textured/deps/node_modules"
  node docs/reference/invoker-review/v2-hooded-meshy/prepare.cjs

Les PNG individuels sont des copies exactes des images generees : pas de
miroir, assemblage du corps, repeinture procedurale ou deformation d'alignement.
Ce sont des illustrations, pas des vues calibrees d'un meme maillage. Le modele
reconstruit et le passage des membres dans le manteau devront etre verifies
avant les animations. Aucun modele genere ni upload Meshy pendant cette etape.
Sources exclues des exports par docs/.gdignore. Aucun changement du jeu.

Baton rituel ajoute le 4 novembre 2026 : bois noueux, pierre gravee d'un oeil,
bronze use et liens violets. Reference separee dans meshy/accessories/staff.png.
Prompt exact : source/prompt-staff.txt. Source ImageGen :
exec-5389a365-0bb0-4295-9637-66b28cce5943.png.
Les quatre images du corps restent inchangees.

