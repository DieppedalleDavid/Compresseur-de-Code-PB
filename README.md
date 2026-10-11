# Compresseur de Code PB

Compresseur / décompresseur de code PureBasic, pour poster de longs codes sur un forum où la taille des messages est limitée.

La compression est **sans aucune perte** : le lecteur retrouve le code d'origine au caractère près, dans son presse-papiers.

## Deux façons de poster

- **Auto-extractible** : un petit programme PureBasic. Le lecteur le colle dans PureBasic et le lance (F5) : le code d'origine arrive dans son presse-papiers. Il n'a rien à installer.
- **Données seules** : un bloc bien plus court, que le lecteur colle dans l'onglet *Décompresser* de ce programme. Le lecteur doit donc avoir ce programme.

## Deux méthodes

- **LZMA** : intégrée à PureBasic, rapide.
- **Maximal** : environ 17 % plus compact que LZMA. En « données seules », elle propose 5 niveaux, qui ne diffèrent que par la taille du texte de référence lu avant les données : plus il est grand, plus c'est compact, et plus c'est lent.

| Niveau  | Texte de référence |
|---------|--------------------|
| Faible  | 53 Ko              |
| Moyen   | 1,6 Mo (par défaut)|
| Normal  | 2,4 Mo             |
| Élevé   | 5,7 Mo             |
| Maximal | 11,3 Mo            |

La liste des niveaux, dans le programme, indique les temps estimés sur votre PC.

En mode *Automatique*, le programme essaie les deux méthodes et garde le résultat le plus court.

## Installation

1. Il faut **PureBasic 6.41** (le programme a été écrit avec cette version, sous Windows x64).
2. Téléchargez `Compresseur de Code PB.pb` et `Compresseur_PB_Reference.dat`, et mettez-les **dans le même dossier**.
3. Ouvrez `Compresseur de Code PB.pb` dans l'éditeur PureBasic, puis lancez-le (F5) ou compilez-le.

Sans le fichier `Compresseur_PB_Reference.dat`, seule la méthode LZMA fonctionne.

## À savoir avant d'utiliser la méthode Maximal

- **Mémoire** : environ 650 Mo. Pour que la vérification se fasse en même temps que la compression (dans un second thread), il faut environ 1,6 Go de mémoire libre et l'option « thread-safe » ; elle se coche toute seule si vous **ouvrez** le fichier `.pb` dans l'éditeur (pas si vous collez le code dans un onglet vide).
- **Disque** : à la première utilisation, le fichier de référence est décompressé une fois pour toutes, et son texte (11 Mo) est gardé dans `%LOCALAPPDATA%\CompresseurPB`. Avec le réglage « Garder l'état du modèle sur le disque » (coché par défaut), le programme y écrit aussi environ **670 Mo par niveau utilisé**, pour aller bien plus vite les fois suivantes. Décochez ce réglage si vous manquez de place ; supprimez ce dossier pour tout récupérer.
- Les blocs postés avec les anciennes versions (PBC1, PBC2, PBC3) restent lisibles.

## Licence

Licence MIT (voir le fichier [LICENSE](LICENSE)), avec une permission en plus.

En résumé (seul le texte anglais du fichier LICENSE fait foi) :

- Ce programme est libre : vous pouvez l'utiliser, le copier, le modifier et le redistribuer, même dans un logiciel commercial, à condition de garder la mention de copyright et la licence dans les copies.
- Il est fourni « tel quel », sans aucune garantie. L'auteur n'est responsable d'aucun dommage (perte de données, plantage, etc.), ni de l'usage que chacun fait de ce programme ou des codes qu'il compresse. Vous l'utilisez à vos risques.

**Permission en plus** : ce que le programme produit (les blocs compressés et les programmes auto-extractibles, décompresseur compris) peut être posté, copié et utilisé librement, **sans** la mention de licence ni aucune autre condition. Le code compressé reste à son auteur et garde sa propre licence.

## Crédits

Le texte de référence contient du code libre d'autres auteurs (licences MIT, zlib, BSD ou domaine public), inclus tel quel avec leurs mentions de licence. La liste des sources et des auteurs est à la fin de `Compresseur de Code PB.pb`. Merci à eux.

Créé par Shadow, avec l'aide de Claude (Anthropic).
