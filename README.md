# Compresseur de Code PB (PB-SuperCodeCompressor)

Compresseur / décompresseur de code PureBasic, pour poster de longs codes sur un forum où la taille des messages est limitée.

La compression est **sans aucune perte** : le lecteur retrouve le code d'origine au caractère près. Avant de copier le résultat, le programme rejoue lui-même la décompression et vérifie qu'elle redonne exactement le code d'origine ; sinon, rien n'est copié.

## Une seule fenêtre, comme un éditeur

On y colle (ou on y glisse) un code pour le compresser, ou un bloc copié sur le forum pour récupérer le code d'origine : le programme reconnaît tout seul ce qu'on lui donne. On peut aussi y glisser un **dossier entier** (sous-dossiers compris) : il devient un seul bloc, un *projet*, recréé à l'identique à la décompression.

Interface dans le thème de Visual Studio 2010, entièrement dessinée par le programme, en **français, anglais et allemand**.

## Deux façons de poster

- **Auto-extractible** : un petit programme PureBasic. Le lecteur le colle dans PureBasic et le lance (F5) : le code d'origine arrive dans son presse-papiers. Il n'a rien à installer.
- **Données seules** : un bloc bien plus court, que le lecteur colle dans ce programme. Le lecteur doit donc avoir ce programme et son fichier de référence.

## Deux méthodes

- **LZMA** : intégrée à PureBasic, rapide.
- **Maximal** : mélange de contextes, en 3 niveaux (format « données seules ») :
  1. la méthode seule (55 contextes et deux listes de mots, française et anglaise) : environ 43 à 58 % de la taille LZMA, rapide ;
  2. la méthode + un petit réseau de neurones (1,4 million de nombres, entraîné sur du code PureBasic public) : souvent 20 à 30 % de mieux que le niveau 1. **Niveau par défaut** ;
  3. 82 contextes de plus + un réseau plus grand (3,3 millions de nombres) : environ 3 % de mieux que le niveau 2, mais la décompression est 1,5 à 3 fois plus lente.

  Le réseau calcule en nombres entiers : le résultat est identique sur tous les PC. Le travail est réparti sur tous les cœurs du processeur.
- **Automatique** : essaie les deux et garde le plus court.

Exemple : le code du programme lui-même (1,17 Mo) tient en **37 869 caractères** au niveau 3, contre 71 673 avec LZMA.

## Écriture du bloc

- **Unicode** : 15 bits par caractère (idéogrammes chinois et syllabes coréennes), environ 2,5 fois plus court que Base64.
- **Base64** : plus long, mais passe absolument partout.

**Protection contre les erreurs** (Unicode, 5 niveaux, de +3,5 % à +30 % de taille) : des caractères de secours (code de Reed-Solomon, comme sur les CD) permettent au programme de réparer tout seul un bloc abîmé.

## Installation

- **PureBasic 6.41, 64 bits.**
- Mettre `Compresseur de Code PB.pb` et `Compresseur_PB_Reference.dat` dans le même dossier. Le fichier de référence contient le texte de référence, les deux réseaux et les deux listes de mots ; sans lui, seule la méthode LZMA marche.
- Méthode Maximal : environ 1,7 Go de mémoire libre (deux fois plus si la vérification se fait en même temps que la compression).
- Au premier lancement, une mesure de quelques secondes choisit la meilleure façon de répartir la décompression sur les cœurs du PC.

Tous les blocs déjà postés restent lisibles, y compris ceux des versions précédentes.

## Licence

Licence MIT (voir le fichier `LICENSE`), avec une exception écrite dans l'en-tête du fichier source : ce que le programme produit (blocs compressés et programmes auto-extractibles, décompresseur compris) peut être posté, copié et utilisé librement, sans mention ni condition. Le code compressé reste à son auteur et garde sa propre licence.

## Crédits

- Le texte de référence contient du code libre d'autres auteurs, sous leurs propres licences : voir les crédits en fin de fichier source.
- Les listes de mots viennent de **wordfreq** (Robyn Speer), sous licence **CC BY-SA 4.0** : la licence MIT ne s'applique pas à elles (voir `CREDITS_listes_de_mots.txt`).
- Créé par **Shadow** (Dieppedalle David), avec l'aide de Claude (Anthropic).

## Anciennes versions

Chaque version garde ses fichiers et son README d'origine dans la page **Releases** (par exemple la [6.4.1](https://github.com/DieppedalleDavid/Compresseur-de-Code-PB/releases/tag/v6.4.1)).
Les blocs postés avec n'importe quelle ancienne version restent lisibles par la nouvelle.
