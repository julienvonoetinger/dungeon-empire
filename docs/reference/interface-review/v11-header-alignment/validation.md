# Correction du bandeau — 26 octobre 2026

Demandes : mieux positionner textes et icônes, intégrer les jauges, retrouver un œil lisible proche de la maquette, retirer la consigne de construction pendant le raid.

- Le bandeau reste dans les 96/84 unités déjà réservées. Son image utilise davantage cette hauteur ; les deux rainures se trouvent dans la traverse inférieure du PNG (y90..108 sur 135), avec un remplissage en retrait de 2 unités. Icône et valeur forment un groupe centré, mesuré avec la police réellement utilisée. Petits écrans et montants à cinq chiffres sont pris en compte.
- Œil 84/72 au lieu de 76/64. Retouche ImageGen de l’iris à partir de la référence fournie ; la petite taille n’était pas la seule cause, le source comportait une spirale. Pupille/reflet fixes, pulsation de luminosité discrète, mêmes dix secteurs de vie. Le cadre est conservé visuellement, sans revendication de pixels identiques. Sources et prompt exact dans `source/`. Source v10 intacte. Préparation uniforme, alpha natif conservé ; sprite 192×194, 93 552 octets au lieu de 96 262. Aucun changement des atlas du donjon.
- La consigne est recalculée selon raid/exploration des accès/préparation. Le texte de raid ne promet pas une inspection par tap qui n’est pas disponible dans cet état : « Raid en cours · Glissez pour explorer ». En paysage, sa zone commence après les commandes de vitesse.

## Vérification

- `capture_master_header.gd` : 30 captures finales sur 1280×720, 844×390, 568×299, 390×844 et 320×568. Préparation, raid, accès, retour de raid, montant de 38 400 et pause. 150 libellés mesurés : aucun dépassement horizontal ni minimum de police supérieur à la hauteur du contrôle.
- Captures paysage, paysage court, portrait et montant à cinq chiffres inspectées. Les captures avant sont conservées ; certaines contiennent le retour visuel transitoire d’or du montage de la scène, qui ne fait pas partie de la correction. Ce retour est supprimé dans l’outil final de capture.
- Import Godot : sortie 0, stderr vide. Captures finales GPU : sortie 0, stderr vide. `verify_master_mobile.gd` : sortie 0, « Master mobile checks: 0 failures », stderr vide. Ajout de contrôles de transition préparation/raid/accès/retour, en complément des contrôles existants de pose, gestes, sauvegarde, pause et vitesse.
- Scènes de revue et sauvegardes isolées dans le dossier de revue ou `artifacts/`. Aucun accès à la sauvegarde normale du joueur. Caméra, économie, progression et format de sauvegarde inchangés.

Pas de test sur téléphone physique, de profilage mobile ou de validation artistique automatique. La nouvelle apparence attend le retour de l’utilisateur. Aucun commit ni push pour cette correction.
