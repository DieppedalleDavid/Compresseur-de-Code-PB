; ============================================================================
;  Compresseur / Décompresseur de code PureBasic - v6.4.1 (PureBasic 6.41)
;  Créé par Claude Opus 5.5 Extra le 10/10/2026 par Shadow (Dieppedalle David).
;
;  Deux onglets dans une seule fenêtre:
;  - Compresser  : transforme un code en texte à poster sur un forum.
;  - Décompresser: récupère le code d'origine à partir d'un bloc copié
;                   sur le forum (format « données seules »).
;
;  Compresse un code source SANS AUCUNE PERTE et le transforme en texte
;  à poster sur un forum, sous l'une de ces deux formes:
;  - Auto-extractible: un petit programme PureBasic. Le lecteur le colle
;    dans PureBasic et le lance (F5): le code d'origine arrive dans son
;    presse-papiers. Rien à installer.
;  - Données seules: un bloc que le lecteur colle dans l'onglet Décompresser
;    de ce programme. Bien plus court, mais le lecteur doit avoir ce programme.
;    En Unicode, le bloc ne contient QUE des caractères Unicode (format
;    compact) ; en Base64, il garde un en-tête lisible PBC1; ou PBC4;.
;
;  Deux méthodes de compression:
;  - LZMA   : intégrée à PureBasic, décompression en une ligne.
;  - Maximal: mélange de contextes, environ 17 % plus compact que LZMA,
;              mais son décompresseur prend environ 4 000 caractères dans
;              un lanceur auto-extractible. En format « données seules »,
;              il utilise la version 4 (formats PBC4 à PBC8, depuis la
;              v6.1), avec 5 niveaux (Faible, Moyen, Normal, Élevé,
;              Maximal) qui ne diffèrent que par la taille du texte de
;              référence: plus il est grand, plus c'est compact et lent.
;              Faible: l'ancien texte de 53 Ko seul (quelques secondes).
;              Moyen (par défaut): + 1,5 Mo de code de Shadow ; sur du
;              code de Shadow, environ 25 % plus court qu'avec la v6.0.
;              Normal, Élevé, Maximal: + de 0,8 à 9,7 Mo de code libre
;              d'autres auteurs (voir les crédits en fin de fichier) ; sur
;              du code d'autres auteurs, jusqu'à 12 % de mieux, bien plus
;              si l'auteur est dans la référence.
;              Il faut environ 650 Mo de mémoire, et chaque passage relit
;              d'abord tout le texte de référence du niveau (la compression
;              fait deux passages, car elle vérifie en décompressant ; la
;              décompression un seul). La liste des niveaux indique les
;              temps estimés sur ce PC.
;              Depuis la v6.3:
;              - à partir du niveau Moyen, l'état du modèle après la lecture
;                du texte de référence peut être gardé sur le disque (environ
;                670 Mo par niveau, réglage « Garder l'état du modèle sur le
;                disque », coché par défaut). Les fois suivantes, il est relu
;                en quelques secondes au lieu de relire tout le texte ;
;              - si ce programme est compilé avec l'option « thread-safe » et
;                que la mémoire suffit pour deux modèles (environ 1,4 Go), la
;                vérification se fait en même temps que la compression, dans
;                un second thread.
;              Depuis la v6.4, le texte de référence est dans un fichier à
;              côté de ce programme: Compresseur_PB_Reference.dat (0,7 Mo).
;              Il est compressé par la méthode Maximal elle-même: le
;              décompresser, c'est la lecture du texte par le modèle, et
;              l'état du niveau Maximal est prêt au passage. Il n'est
;              décompressé qu'une fois par PC (le texte décompressé, 11 Mo,
;              est gardé sur le disque avec les états). Sans ce fichier, seule
;              la méthode LZMA marche.
;              Les blocs PBC1, PBC2 et PBC3 déjà postés restent lisibles.
;  En mode Automatique, le logiciel essaie les deux et garde le plus court.
;
;  Deux façons d'écrire les données compressées sous forme de texte:
;  - Unicode: 15 bits par caractère (idéogrammes chinois et syllabes
;              coréennes). Environ 2,5 fois plus court que Base64.
;  - Base64 : 6 bits par caractère (lettres, chiffres, + et /).
;              Plus long, mais passe absolument partout.
;
;  Protection contre les erreurs (données seules en Unicode), 5 niveaux:
;  le bloc reçoit des caractères de secours (code de Reed-Solomon, comme
;  sur les CD), répartis sur tout le bloc. L'onglet Décompresser répare alors
;  tout seul un bloc abîmé: caractères faux, manquants ou en trop par ci
;  par là, ou un morceau manquant d'un seul tenant (début, milieu ou fin)
;  presque aussi long que le nombre de caractères de secours.
;    Faible  ×1 : environ +3,5 %      Moyen   ×4 : environ +9 %
;    Normale ×2 : environ +5 %        Élevé   ×8 : environ +16 %
;                                     Maximal ×16: environ +30 %
;
;  Avant de copier le résultat, le logiciel rejoue lui-même la
;  décompression à partir du texte généré et vérifie qu'elle redonne
;  exactement le code d'origine. Sinon, rien n'est copié.
;
; ============================================================================
; 
; ============================================================================
;  LICENCE
;  Copyright (c) 2026 Shadow (Dieppedalle David)
;
;  En résumé (seul le texte anglais ci-dessous fait foi):
;  - Ce programme est libre: vous pouvez l'utiliser, le copier, le modifier
;    et le redistribuer, même dans un logiciel commercial, à condition de
;    garder cette mention de copyright et cette licence dans les copies.
;  - Il est fourni « tel quel », sans aucune garantie. L'auteur n'est
;    responsable d'aucun dommage (perte de données, plantage, etc.), ni de
;    l'usage que chacun fait de ce programme ou des codes qu'il compresse.
;    Vous l'utilisez à vos risques.
;
;  Exception: ce que le programme produit (les blocs compressés et les
;  programmes auto-extractibles, décompresseur compris) peut être posté,
;  copié et utilisé librement, SANS cette mention ni aucune autre condition.
;  Le code compressé reste à son auteur et garde sa propre licence.
;
;  Le texte de référence contient du code libre d'autres auteurs, sous leurs
;  propres licences: voir les crédits en fin de fichier.
;
;  MIT License
;
;  Permission is hereby granted, free of charge, to any person obtaining a
;  copy of this software and associated documentation files (the "Software"),
;  to deal in the Software without restriction, including without limitation
;  the rights to use, copy, modify, merge, publish, distribute, sublicense,
;  and/or sell copies of the Software, and to permit persons to whom the
;  Software is furnished to do so, subject to the following conditions:
;
;  The above copyright notice and this permission notice shall be included in
;  all copies or substantial portions of the Software.
;
;  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
;  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
;  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
;  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
;  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
;  FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
;  DEALINGS IN THE SOFTWARE.
; ============================================================================


EnableExplicit

UseLZMAPacker()

; Nombre de caractères de données par ligne dans le résultat
#LongueurLigne = 1000

; Limite par défaut de phpBB pour la taille d'un message
#LimiteParDefaut = 60000

; Les balises codes comptent aussi dans la limite du forum
#TailleBalisesCode = 13

; Table de 33 valeurs utilisée par la méthode Maximal (copiée dans les lanceurs)
#DonneesSq33$ = "1,2,3,6,10,16,27,45,73,120,194,310,488,747,1101,1546,2047,2549,2994,3348,3607,3785,3901,3975,4022,4050,4068,4079,4085,4089,4092,4093,4094"

Enumeration
  #FenetrePrincipale
EndEnumeration

Enumeration
  #BoutonColler
  #BoutonOuvrir
  #BoutonCompresser
  #TexteFormat
  #ChoixFormat
  #TexteMethode
  #ChoixMethode
  #TexteEncodage
  #ChoixEncodage
  #TexteLangue
  #ChoixLangue
  #CaseOptionsIDE
  #TexteLimite
  #ChampLimite
  #TexteCaracteres
  #TexteProtection
  #ChoixProtection
  #TexteProtectionInfo
  #TexteEntree
  #EditeurEntree
  #TexteSortie
  #EditeurSortie
  #TexteInfos
  #Indicateur
  #Onglets
  #BoutonDecColler
  #BoutonDecCopier
  #BoutonDecEnregistrer
  #EditeurDec
  #TexteInfosDec
  #TexteNiveau
  #ChoixNiveau
  #TexteNiveauInfo
  #CaseGarderEtat
  #BoutonEffacerEtat
EndEnumeration

Enumeration
  #PoliceCode
EndEnumeration

; Barre d'état en bas de la fenêtre: barre de progression et temps
Enumeration
  #BarreEtat
EndEnumeration

; Valeurs des listes
#FormatLanceur = 0
#FormatBloc    = 1

#MethodeAuto    = 0
#MethodeLZMA    = 1
#MethodeMaximal = 2

#EncodageUnicode = 0
#EncodageBase64  = 1

Global CodeOriginal$           ; le code chargé, conservé tel quel
Global DerniereTailleForum     ; taille sur le forum du dernier résultat (0 = aucun résultat)
Global DernierModeBase64       ; encodage utilisé pour le dernier résultat
Global DernierFormat           ; format utilisé pour le dernier résultat
Global FichierReglages$ = GetUserDirectory(#PB_Directory_ProgramData) + "CompresseurPB.prefs"
Global CodeDecompresse$        ; dernier code récupéré dans l'onglet Décompresser
Global EstimationAJour         ; #False: la taille LZMA du code est à recalculer
Global.q EstimationTaille, EstimationLZMA   ; taille du code (UTF-8) et sa taille avec LZMA
Global Dim RapportNiveau.q(4)  ; rapport Maximal / LZMA observé à chaque niveau (pour mille, 0 = inconnu)


; Procédures du programme principal utilisées plus haut que leur définition
Declare SauverReglages()

; ============================================================================
;  PARTIE DÉCOMPRESSION.
;  C'est elle que l'onglet Décompresser utilise chez le lecteur, et c'est
;  aussi elle que l'onglet Compresser rejoue pour vérifier chaque résultat
;  avant de te le donner.
; ============================================================================

; Les 32 768 caractères du mode Unicode (15 bits = 32 768 valeurs):
;  - valeurs 0 à 27 647      -> U+3400 à U+9FFF (idéogrammes)
;  - valeurs 27 648 à 32 767 -> U+AC00 à U+BFFF (syllabes coréennes)
; Tous sont imprimables, ne sont pas des espaces, et ne sont jamais modifiés
; par la normalisation Unicode (NFC) que phpBB applique aux messages.
#DebutPlage1  = $3400
#FinPlage1    = $9FFF
#TaillePlage1 = 27648
#DebutPlage2  = $AC00
#FinPlage2    = $BFFF

Global ErreurDecompression$
Global BlocReconnu        ; #True si un bloc a été reconnu (même s'il n'a pas pu être lu)
Global BlocProtege        ; #True si c'était un bloc protégé contre les erreurs

; Texte de référence: du code PureBasic lu par le modèle AVANT les données,
; pour qu'il connaisse déjà les mots, les habitudes et les passages courants.
; Il est fait de segments:
;   0: l'ancien texte (53 Ko), seul utilisé par les formats PBC2 et PBC3 ;
;   1: le code de Shadow ;
;   2, 3, 4: du code libre d'autres auteurs (voir les crédits en fin de fichier).
; Chaque niveau de la méthode Maximal v4 assemble certains segments, le code
; de Shadow toujours en dernier (voir CompositionNiveau). Le niveau est écrit
; dans le bloc compressé: le lecteur n'a rien à choisir.
; Une fois des blocs postés, NE PLUS CHANGER les segments qu'ils utilisent.
;
; Depuis la v6.4, le texte est dans un fichier à côté du programme
; (#NomFichierReference$): tous les segments, dans l'ordre du niveau Maximal,
; compressés par la méthode v4 elle-même. Le décompresser revient exactement à
; la lecture de ce texte par le modèle: à la fin, l'état du niveau Maximal est
; prêt (DecoderReferenceCM4), et il est gardé sur le disque. Le texte
; décompressé est gardé lui aussi (FichierTexteReference): le fichier n'est
; décompressé qu'une fois par PC. Le niveau Faible et les formats PBC2 et PBC3
; n'ont besoin que du début du fichier (segment 0).
; Le programme garde la table des segments (taille, somme de contrôle) pour
; vérifier tout ce qu'il lit.
#TailleReferenceCourte = 52985
#NbSegments            = 5
#NomFichierReference$  = "Compresseur_PB_Reference.dat"
#MagiqueReference      = 724292591491891792     ; marque du fichier de référence
#VersionReference      = 1
#TailleEnTeteReference = 64                        ; puis 24 octets par segment
#MagiqueTexteReference = 724292651940332112     ; marque du texte gardé sur le disque
#ControleEtatMaximal   = 1096810284597608028   ; somme de contrôle de l'état Maximal (calculée par gen.py)
Global Dim SegmentTaille.q(#NbSegments - 1)
Global Dim SegmentControle.q(#NbSegments - 1)
Global Dim SegmentAdresse.i(#NbSegments - 1)
Global TableReferenceLue
Global CheminReferenceChoisi$   ; fichier de référence indiqué par l'utilisateur (réglages)
Global EtatMaximalPrepare       ; #True si l'opération a préparé l'état Maximal en décompressant le fichier
Global EtatMaximalRefuse        ; #True si cet état a été refusé (somme de contrôle différente: à signaler)
Global ReferenceDecompressee    ; 1 si l'opération a décompressé le début du fichier de référence, 2 s'il l'a décompressé en entier

; Texte de référence assemblé pour un niveau (gardé pour la suite de la séance)
Global *Reference, TailleReference, NiveauReference = -1
Global ErreurReference$        ; raison d'un échec de la procédure ConstruireReference

; Niveaux de compression de la méthode Maximal v4
Enumeration Niveaux
  #NiveauFaible
  #NiveauMoyen
  #NiveauNormal
  #NiveauEleve
  #NiveauMaximal
EndEnumeration

; Vitesse de la méthode Maximal sur ce PC, en unités par seconde (1 unité =
; 1 octet lu par la v3, 4 par la v4). Mesurée à chaque opération, mémorisée.
Global VitesseCM.q = 120000

; Mémoire demandée par la méthode v4 (tables d'environ 600 Mo, plus une marge)
#MemoireMethode4 = 700 * 1024 * 1024

; État du modèle v4 gardé sur le disque (depuis la v6.3). Après la lecture du
; texte de référence d'un niveau (Moyen et au-dessus), tout ce que le modèle a
; appris est écrit dans un fichier d'environ 670 Mo par niveau. Les fois
; suivantes, ce fichier est relu en quelques secondes au lieu de relire tout le
; texte de référence (une à plusieurs minutes).
; Fichier: un en-tête (8 nombres de 8 octets), le texte de référence du
; niveau, puis l'état du modèle et sa somme de contrôle (voir EchangeMemoire).
; Un état n'est gardé qu'après avoir redonné, en étant relu, exactement la même
; décompression que la lecture du texte de référence. Il n'est ensuite utilisé
; que si tout correspond à ce programme: en-tête, taille, texte de référence
; (vérifié segment par segment) et somme de contrôle de l'état.
#TailleEnTeteEtat  = 64
#MagiqueEtat4      = 4995148063411237700     ; marque des fichiers d'état
#VersionEtat4      = 1
#SignatureModele4  = 286787957192737890   ; change dès que la méthode v4 change
#TailleEtatModele4 = 665955816        ; octets écrits par la méthode v4
#MorceauEtat       = 16 * 1024 * 1024        ; lecture et écriture par morceaux de 16 Mo
#ChargementEtat    = 5                       ; temps estimé pour relire un état (secondes)
Global GarderEtat = #True       ; réglage « Garder l'état du modèle sur le disque »
Global EtatAbime                ; #True si un état lu s'est révélé abîmé (il sera effacé)
Global EcritureEtatRatee        ; #True si l'écriture d'un état a échoué (disque plein...)
Global EtatCree                 ; #True si l'opération a gardé un nouvel état
Global FichierEtatLu, FichierEtatEcrit   ; fichiers d'état de l'opération en cours (0 = aucun)

; Vérification en parallèle pendant la compression (depuis la v6.3): un second
; thread décompresse en même temps que la compression avance. La compression
; publie le nombre d'octets déjà produits ; le second thread attend qu'il y en
; ait assez. Il faut l'option « thread-safe » du compilateur, et assez de
; mémoire pour deux modèles.
Global MutexCM4, ParalleleActif, EncodageFini
Global.q OctetsPublies
; Chaque thread a sa propre valeur: #True seulement dans le second thread, qui
; ne doit jamais toucher à la fenêtre (voir AvancementEtat)
Threaded EstFilVerification

; Affichage pendant la lecture ou l'écriture de l'état sur le disque (v6.3.1)
Global.q EtatOctets             ; octets de l'état déjà lus ou écrits
Global EtatRelu                 ; #True si l'opération a relu un état gardé

; Pendant une compression: octets compressés déjà décompressés et vérifiés, et
; code qu'ils redonnent. Le contrôle du bloc fini (voir DecompresserBloc) vérifie
; alors que son texte redonne exactement ces octets, sans tout décompresser une
; seconde fois.
Global *VerifOctets, *VerifCode, VerifNiveau
Global.q VerifZ, VerifT

; Format compact (« données seules » en Unicode): le bloc ne contient que des
; caractères Unicode. Les 8 premiers forment l'en-tête:
;   1: marque du format    2: méthode (1 = LZMA, 2 = Maximal v2, 3 = Maximal v3,
;                                          4 à 8 = Maximal v4, selon le niveau)
;   3-4: taille d'origine  5-6: taille compressée  7-8: somme de contrôle
#MarqueCompacte = $5042
; Bloc protégé contre les erreurs (option, 5 niveaux): voir #MarqueProtegee
; plus bas. Il contient le bloc compact complet avec des caractères de
; secours, et se répare avant d'être lu.


; ----------------------------------------------------------------------------
;  Somme de contrôle du code d'origine: détecte toute donnée abîmée.
;  (même formule que celle calculée par le décompresseur "Maximal")
;  Sans le débogueur (comme les méthodes Maximal): elle passe sur tout le
;  texte de référence quand l'état du modèle est relu (jusqu'à 11 Mo).
; ----------------------------------------------------------------------------
DisableDebugger
Procedure.q Controle(*D, T.q)
  Protected.q i, chk

  For i = 0 To T - 1
    chk = ((chk * 33) + PeekA(*D + i)) % 1000000007
  Next
  ProcedureReturn chk
EndProcedure
EnableDebugger


; ----------------------------------------------------------------------------
;  Mode Unicode: texte -> octets. Même formule que dans les lanceurs.
;  Renvoie le nombre d'octets décodés, ou -1 si un caractère est étranger.
; ----------------------------------------------------------------------------
Procedure DecoderUnicode(Texte$, *Sortie, TailleMax)
  Protected *P.Unicode, a, k, N

  *P = @Texte$
  While *P\u
    If (*P\u < #DebutPlage1 Or *P\u > #FinPlage1) And (*P\u < #DebutPlage2 Or *P\u > #FinPlage2)
      ProcedureReturn -1
    EndIf
    a = (a << 15) | (*P\u - $3400 - Bool(*P\u >= $AC00) * $C00)
    k = k + 15
    While k >= 8
      k = k - 8
      If N < TailleMax
        PokeA(*Sortie + N, (a >> k) & 255)
      EndIf
      N = N + 1
    Wend
    a = a & ((1 << k) - 1)
    *P = *P + 2
  Wend

  ProcedureReturn N
EndProcedure


; ----------------------------------------------------------------------------
;  Caractère Unicode -> valeur 15 bits (0 à 32 767). Même formule que partout.
; ----------------------------------------------------------------------------
Procedure ValeurUnicode(Code)
  ProcedureReturn Code - $3400 - Bool(Code >= $AC00) * $C00
EndProcedure


; ----------------------------------------------------------------------------
;  Valeur 15 bits (0 à 32 767) -> code du caractère Unicode
; ----------------------------------------------------------------------------
Procedure CaractereUnicode(Valeur)
  If Valeur < #TaillePlage1
    ProcedureReturn #DebutPlage1 + Valeur
  Else
    ProcedureReturn #DebutPlage2 + Valeur - #TaillePlage1
  EndIf
EndProcedure


; ----------------------------------------------------------------------------
;  Ne garde du texte que les caractères des deux plages Unicode utilisées
;  (retire espaces, retours à la ligne et tout texte autour du bloc).
; ----------------------------------------------------------------------------
Procedure.s GarderCaracteresUnicode(Texte$)
  Protected Resultat$, *Lecture.Unicode, *Ecriture.Unicode, N

  Resultat$ = Space(Len(Texte$))
  *Lecture = @Texte$
  *Ecriture = @Resultat$
  While *Lecture\u
    If (*Lecture\u >= #DebutPlage1 And *Lecture\u <= #FinPlage1) Or (*Lecture\u >= #DebutPlage2 And *Lecture\u <= #FinPlage2)
      *Ecriture\u = *Lecture\u
      *Ecriture = *Ecriture + 2
      N = N + 1
    EndIf
    *Lecture = *Lecture + 2
  Wend

  ProcedureReturn Left(Resultat$, N)
EndProcedure


; ----------------------------------------------------------------------------
;  PROTECTION CONTRE LES ERREURS (option, 5 niveaux).
;
;  Le bloc compact reçoit des caractères de secours (code de Reed-Solomon,
;  comme sur les CD): 16 par tranche de 1008 caractères au niveau Faible,
;  32 en Normale, 64 en Moyen, 128 en Élevé, 256 en Maximal.
;
;  1. ENTRELACEMENT: le caractère n° s du flux appartient à la tranche
;     s mod T. Un morceau manquant d'un seul tenant se répartit donc sur
;     toutes les tranches: on peut en rattraper presque autant que de
;     caractères de secours, au début, au milieu ou à la fin.
;  2. SEGMENTS: le flux est découpé en segments de 126 caractères, suivis
;     chacun de 2 caractères de « code local » calculés avec le numéro du
;     segment. On retrouve ainsi chaque segment intact n'importe où dans le
;     texte collé, et on répare exactement, dans un segment, 1 caractère
;     faux, ou 1 à 3 caractères en trop, ou 1 caractère manquant.
;  3. Le reste (morceau manquant, dégâts mélangés) est départagé par le code
;     de Reed-Solomon, puis chaque tranche est corrigée.
;  Un en-tête (marque, niveau, longueur) est écrit 3 fois au début et 3 fois
;  à la fin du bloc.
;
;  Calculs dans le corps fini à 32 768 éléments (15 bits = un caractère),
;  polynôme x^15 + x + 1. Les nombres restent tous entre 0 et 65 535: aucun
;  débordement possible, résultat identique sur tous les PC.
;  Note: l'opérateur ! est le OU exclusif bit à bit de PureBasic. Il est
;  toujours écrit entre parenthèses, seul avec ses deux opérandes.
; ----------------------------------------------------------------------------
#RsKMax           = 1008     ; données par tranche, au plus
#RsN1             = 32767    ; nombre d'éléments non nuls du corps
#RsPolynome       = $8003    ; x^15 + x + 1
#SegC             = 126      ; caractères de contenu par segment
#SegT             = 128      ; segment transmis (contenu + 2 de code local)
#EnTeteProtege    = 12       ; 3 copies de (marque, niveau, longueur haute, longueur basse)
#MarqueProtegee   = $5053
#MarqueProtegeeV1 = $5052    ; ancien format (v5.3), plus lu

Global Dim GfExp.l(65535)    ; GfExp(i) = alpha^i (table doublée: pas de modulo)
Global Dim GfLog.l(32767)    ; GfLog(alpha^i) = i
Global Dim RsGen.l(256)      ; polynôme générateur (degré P)
Global Dim RsR.l(256)        ; reste de la division (encodeur)
Global Dim RsMot.l(1279)     ; mot de code en cours de décodage
Global Dim RsEff.l(256)      ; positions des caractères effacés (inconnus)
Global Dim RsS.l(256)        ; syndromes
Global Dim RsGam.l(256)      ; localisateur des effacements
Global Dim RsT.l(256)        ; syndromes modifiés
Global Dim RsC.l(256)        ; localisateur des erreurs (Berlekamp-Massey)
Global Dim RsB.l(256)
Global Dim RsTmp.l(256)
Global Dim RsPsi.l(513)      ; localisateur total
Global Dim RsOm.l(256)       ; évaluateur
Global Dim RsPos.l(513)      ; positions trouvées
Global Dim RsV.l(0)          ; caractères du bloc collé (valeurs 15 bits)
Global Dim RsCharge.l(0)     ; bloc compact (avant protection / après réparation)
Global Dim RsSortie.l(0)     ; bloc protégé
Global Dim SVal.l(0)         ; flux reconstruit
Global Dim SEtat.l(0)        ; 0 sûr, 1 inconnu, 2 douteux, 3 corrigé par le code local
Global Dim AncG.l(0)         ; segments intacts retrouvés: numéro...
Global Dim AncQ.l(0)         ; ... et position dans le bloc collé
Global Dim ZG1.l(0)          ; zones abîmées: premier segment
Global Dim ZG2.l(0)          ; dernier segment
Global Dim ZDeb.l(0)         ; caractères reçus pour la zone: début dans RsV()
Global Dim ZLong.l(0)        ; ... et nombre
Global Dim ZGauche.l(0)      ; 1 si le début de la zone est calé
Global Dim ZDroite.l(0)      ; 1 si la fin de la zone est calée
Global Dim ZAttente.l(0)
Global Dim LocW.l(129)       ; segment en cours (code local)
Global Dim HVal.l(0)         ; contenu d'une hypothèse
Global Dim HInc.l(0)         ; 1 = inconnu
Global Dim HPrem.l(0)        ; première solution retenue
Global Dim HPremInc.l(0)
Global Dim SegSol.l(127)     ; solution pour un segment
Global Dim PelVal.l(0)       ; segments résolus un par un (gauche puis droite)
Global Dim PelEtat.l(0)
Global Dim PelN.l(0)
Global Dim BaseS.l(0)        ; syndromes hors zone, par tranche
Global Dim BaseNbE.l(0)      ; effacements hors zone, par tranche
Global Dim BaseE.l(0)
Global Dim HS.l(0)
Global Dim HNbE.l(0)
Global Dim HE.l(0)
Global Dim CopI.l(31)        ; copies d'en-tête trouvées
Global GfPret, RsGenP, RsNbV
Global PrN, PrP, PrT, PrM, PrG, PrLp
Global EntN, EntLp, EnTeteDebut, EnTeteFin
Global NbAnc, NbZones, LocS0, LocS1, PelPos, PelAmbigus, HToutConnu
Global HypGenre, HypLz, HypRr, HypD, HypNb, HypMin
Global InfZones, InfLocales, InfRS, InfEffacees, InfDouteuses, InfManque, RsTrancheAbimee

DisableDebugger

Procedure GfMul(a, b)
  If a = 0 Or b = 0
    ProcedureReturn 0
  EndIf
  ProcedureReturn GfExp(GfLog(a) + GfLog(b))
EndProcedure

Procedure GfDiv(a, b)
  If a = 0 Or b = 0
    ProcedureReturn 0
  EndIf
  ProcedureReturn GfExp(GfLog(a) + #RsN1 - GfLog(b))
EndProcedure

; Tables du corps fini (une seule fois)
Procedure InitialiserGF()
  Protected i, x

  If GfPret
    ProcedureReturn
  EndIf
  x = 1
  For i = 0 To #RsN1 - 1
    GfExp(i) = x
    GfLog(x) = i
    x = x * 2
    If x >= 32768
      x = (x ! #RsPolynome)
    EndIf
  Next
  For i = #RsN1 To 65535
    GfExp(i) = GfExp(i - #RsN1)
  Next
  GfPret = #True
EndProcedure

; Polynôme générateur pour P caractères de secours
Procedure PreparerGenerateur(P)
  Protected i, k

  If RsGenP = P
    ProcedureReturn
  EndIf
  For i = 0 To 256
    RsGen(i) = 0
  Next
  RsGen(0) = 1
  For k = 0 To P - 1
    For i = k + 1 To 1 Step -1
      RsGen(i) = (RsGen(i - 1) ! GfMul(RsGen(i), GfExp(k)))
    Next
    RsGen(0) = GfMul(RsGen(0), GfExp(k))
  Next
  RsGenP = P
EndProcedure

; Dimensions du bloc protégé pour un niveau N et un bloc compact de lp caractères
Procedure FixerParametres(N, lp)
  PrN = N
  PrLp = lp
  PrP = 16 * N
  PrT = (lp + #RsKMax - 1) / #RsKMax
  PrM = (PrP * PrT) + lp
  PrG = (PrM + #SegC - 1) / #SegC
EndProcedure

; Longueur du contenu du segment g (le dernier peut être plus court)
Procedure LongSeg(g)
  If PrM - (g * #SegC) < #SegC
    ProcedureReturn PrM - (g * #SegC)
  EndIf
  ProcedureReturn #SegC
EndProcedure

; Longueur transmise des segments g1 à g2
Procedure LongueurZone(g1, g2)
  ProcedureReturn (g2 * #SegT) + LongSeg(g2) + 2 - (g1 * #SegT)
EndProcedure

; Encode la tranche t (données RsCharge(j*T + t)) dans le flux SVal(j*T + t)
Procedure RsEncoderTranche(t)
  Protected i, k, f, n, kd, P

  P = PrP
  kd = (PrLp - t + PrT - 1) / PrT
  n = kd + P
  For k = 0 To P - 1
    RsR(k) = 0
  Next
  For i = n - 1 To P Step -1
    f = (RsCharge(((i - P) * PrT) + t) ! RsR(P - 1))
    For k = P - 1 To 1 Step -1
      RsR(k) = (RsR(k - 1) ! GfMul(f, RsGen(k)))
    Next
    RsR(0) = GfMul(f, RsGen(0))
  Next
  For k = 0 To P - 1
    SVal((k * PrT) + t) = RsR(k)
  Next
  For i = 0 To kd - 1
    SVal(((P + i) * PrT) + t) = RsCharge((i * PrT) + t)
  Next
EndProcedure

; Corrige RsMot(0 à n-1), dont les f caractères listés dans RsEff() sont
; inconnus (PrP caractères de secours). Renvoie le nombre de caractères
; corrigés, ou -1 si impossible. On garde toujours au moins 1 caractère de
; secours inutilisé, pour vérifier le résultat.
Procedure RsDecoder(n, f)
  Protected i, j, k, e, v, X, lx, xi, L, m, b, d, nn, coef, nu, nbpos, num, den, Nul, P

  P = PrP
  If f > P - 1
    ProcedureReturn -1
  EndIf
  If f > 0
    For e = 0 To f - 1
      RsMot(RsEff(e)) = 0
    Next
  EndIf

  ; Syndromes S(k) = mot(alpha^k)
  Nul = #True
  For k = 0 To P - 1
    v = 0
    For i = n - 1 To 0 Step -1
      If v <> 0
        v = GfExp(GfLog(v) + k)
      EndIf
      v = (v ! RsMot(i))
    Next
    RsS(k) = v
    If v <> 0
      Nul = #False
    EndIf
  Next
  If Nul
    ProcedureReturn 0
  EndIf

  ; Localisateur des effacements: produit des (1 + X.x)
  For i = 0 To P
    RsGam(i) = 0
  Next
  RsGam(0) = 1
  If f > 0
    For e = 0 To f - 1
      X = GfExp(RsEff(e))
      For i = e + 1 To 1 Step -1
        RsGam(i) = (RsGam(i) ! GfMul(RsGam(i - 1), X))
      Next
    Next
  EndIf

  ; Syndromes modifiés: S.Gamma, tronqué au degré P-1
  For i = 0 To P - 1
    RsT(i) = 0
  Next
  For i = 0 To P - 1
    For j = 0 To f
      If i + j < P
        RsT(i + j) = (RsT(i + j) ! GfMul(RsS(i), RsGam(j)))
      EndIf
    Next
  Next

  ; Berlekamp-Massey: localisateur des erreurs (positions inconnues)
  For i = 0 To P
    RsC(i) = 0
    RsB(i) = 0
  Next
  RsC(0) = 1
  RsB(0) = 1
  L = 0
  m = 1
  b = 1
  If f < P
    For nn = 0 To P - f - 1
      d = RsT(f + nn)
      If L > 0
        For i = 1 To L
          d = (d ! GfMul(RsC(i), RsT(f + nn - i)))
        Next
      EndIf
      If d = 0
        m = m + 1
      ElseIf 2 * L <= nn
        For i = 0 To P
          RsTmp(i) = RsC(i)
        Next
        coef = GfDiv(d, b)
        For i = 0 To P - m
          RsC(i + m) = (RsC(i + m) ! GfMul(coef, RsB(i)))
        Next
        L = nn + 1 - L
        For i = 0 To P
          RsB(i) = RsTmp(i)
        Next
        b = d
        m = 1
      Else
        coef = GfDiv(d, b)
        For i = 0 To P - m
          RsC(i + m) = (RsC(i + m) ! GfMul(coef, RsB(i)))
        Next
        m = m + 1
      EndIf
    Next
  EndIf
  If 2 * L + f > P - 1
    ProcedureReturn -1
  EndIf

  ; Localisateur total Psi = Lambda.Gamma (degré nu = L + f, au plus P)
  nu = L + f
  For i = 0 To nu
    RsPsi(i) = 0
  Next
  For i = 0 To L
    For j = 0 To f
      RsPsi(i + j) = (RsPsi(i + j) ! GfMul(RsC(i), RsGam(j)))
    Next
  Next

  ; Recherche de Chien: la position j est fausse si Psi(alpha^-j) = 0
  nbpos = 0
  For j = 0 To n - 1
    lx = (#RsN1 - j) % #RsN1
    v = 0
    For i = nu To 0 Step -1
      If v <> 0
        v = GfExp(GfLog(v) + lx)
      EndIf
      v = (v ! RsPsi(i))
    Next
    If v = 0
      If nbpos <= 512
        RsPos(nbpos) = j
      EndIf
      nbpos = nbpos + 1
    EndIf
  Next
  If nbpos <> nu
    ProcedureReturn -1
  EndIf

  ; Évaluateur Omega = S.Psi, tronqué au degré P-1
  For i = 0 To P - 1
    RsOm(i) = 0
  Next
  For i = 0 To P - 1
    For j = 0 To nu
      If i + j < P
        RsOm(i + j) = (RsOm(i + j) ! GfMul(RsS(i), RsPsi(j)))
      EndIf
    Next
  Next

  ; Forney: valeur de chaque erreur
  If nu > 0
    For k = 0 To nu - 1
      j = RsPos(k)
      X = GfExp(j)
      lx = (#RsN1 - j) % #RsN1
      xi = GfExp(lx)
      num = 0
      For i = P - 1 To 0 Step -1
        num = (GfMul(num, xi) ! RsOm(i))
      Next
      den = 0
      For i = nu To 1 Step -1
        If i % 2 = 1
          den = (den ! GfMul(RsPsi(i), GfExp((lx * (i - 1)) % #RsN1)))
        EndIf
      Next
      If den = 0
        ProcedureReturn -1
      EndIf
      RsMot(j) = (RsMot(j) ! GfMul(X, GfDiv(num, den)))
    Next
  EndIf

  ; Vérification finale: le mot corrigé doit être un vrai mot de code
  For k = 0 To P - 1
    v = 0
    For i = n - 1 To 0 Step -1
      If v <> 0
        v = GfExp(GfLog(v) + k)
      EndIf
      v = (v ! RsMot(i))
    Next
    If v <> 0
      ProcedureReturn -1
    EndIf
  Next
  ProcedureReturn nu
EndProcedure

; Syndromes du code local du segment rangé dans LocW(0 à L+1): contenu,
; puis les 2 caractères de code local. g >= 0: avec le caractère virtuel
; g + 1 (numéro du segment) ; g = -1: sans.
Procedure SyndromesLocaux(L, g)
  Protected o

  LocS0 = (LocW(L) ! LocW(L + 1))
  LocS1 = (LocW(L) ! GfMul(LocW(L + 1), 2))
  For o = 0 To L - 1
    LocS0 = (LocS0 ! LocW(o))
    LocS1 = (LocS1 ! GfMul(LocW(o), GfExp(2 + o)))
  Next
  If g >= 0
    LocS0 = (LocS0 ! (g + 1))
    LocS1 = (LocS1 ! GfMul(g + 1, GfExp(L + 2)))
  EndIf
EndProcedure

; Position o dans le segment transmis -> indice dans le mot du code local
Procedure IndiceLocal(o, L)
  If o < L
    ProcedureReturn 2 + o
  EndIf
  ProcedureReturn o - L
EndProcedure

; Calcule les 2 caractères de code local du segment g (contenu dans LocW)
Procedure CodeLocal(L, g)
  Protected p1

  LocW(L) = 0
  LocW(L + 1) = 0
  SyndromesLocaux(L, g)
  p1 = GfDiv((LocS0 ! LocS1), 3)
  LocW(L + 1) = p1
  LocW(L) = (LocS0 ! p1)
EndProcedure

; Corrige au plus 1 caractère faux dans le segment LocW (syndromes déjà
; calculés avec le numéro). Renvoie 0 intact, 3 corrigé, 2 non corrigeable.
Procedure CorrigerUn(L)
  Protected e, o

  If LocS0 = 0 And LocS1 = 0
    ProcedureReturn 0
  EndIf
  If LocS0 <> 0 And LocS1 <> 0
    e = (GfLog(LocS1) - GfLog(LocS0) + #RsN1) % #RsN1
    For o = 0 To L + 1
      If IndiceLocal(o, L) = e
        LocW(o) = (LocW(o) ! LocS0)
        ProcedureReturn 3
      EndIf
    Next
  EndIf
  ProcedureReturn 2
EndProcedure

; Protège le bloc compact RsCharge(0 à lp-1) au niveau N: résultat dans
; RsSortie(). Renvoie la longueur du bloc protégé.
Procedure ProtegerValeurs2(lp, N)
  Protected t, g, o, L, pos, c

  InitialiserGF()
  FixerParametres(N, lp)
  PreparerGenerateur(PrP)
  ReDim SVal(PrM)
  For t = 0 To PrT - 1
    RsEncoderTranche(t)
  Next
  ReDim RsSortie((2 * #EnTeteProtege) + PrM + (2 * PrG))
  pos = 0
  For c = 0 To 2
    RsSortie(pos) = #MarqueProtegee
    RsSortie(pos + 1) = N
    RsSortie(pos + 2) = lp / 32768
    RsSortie(pos + 3) = lp % 32768
    pos = pos + 4
  Next
  For g = 0 To PrG - 1
    L = LongSeg(g)
    For o = 0 To L - 1
      LocW(o) = SVal((g * #SegC) + o)
    Next
    CodeLocal(L, g)
    For o = 0 To L + 1
      RsSortie(pos) = LocW(o)
      pos = pos + 1
    Next
  Next
  For c = 0 To 2
    RsSortie(pos) = #MarqueProtegee
    RsSortie(pos + 1) = N
    RsSortie(pos + 2) = lp / 32768
    RsSortie(pos + 3) = lp % 32768
    pos = pos + 4
  Next
  ProcedureReturn pos
EndProcedure

Procedure EstNiveau(N)
  If N = 1 Or N = 2 Or N = 4 Or N = 8 Or N = 16
    ProcedureReturn #True
  EndIf
  ProcedureReturn #False
EndProcedure

; Ressemblance entre les 12 caractères RsV(deb ...) et l'en-tête complet
; attendu (EntN, EntLp): +1 par caractère identique, -1 par différent
Procedure ScoreEntete(deb)
  Protected k, pos, sc, attendu

  sc = 0
  For k = 0 To 11
    pos = deb + k
    If pos >= 0 And pos < RsNbV
      If k % 4 = 0
        attendu = #MarqueProtegee
      ElseIf k % 4 = 1
        attendu = EntN
      ElseIf k % 4 = 2
        attendu = EntLp / 32768
      Else
        attendu = EntLp % 32768
      EndIf
      If RsV(pos) = attendu
        sc = sc + 1
      Else
        sc = sc - 1
      EndIf
    EndIf
  Next
  ProcedureReturn sc
EndProcedure

; En-tête: copies cherchées dans les 15 premiers et les 15 derniers
; caractères, puis vote. Renseigne EntN, EntLp, EnTeteDebut, EnTeteFin.
Procedure LireEntete()
  Protected i, c, cc, nb, nbMax, meilleur, Fin1, Deb2, pos, k, E, sc, scD, scF

  nb = 0
  Fin1 = 15
  If RsNbV < Fin1
    Fin1 = RsNbV
  EndIf
  For i = 0 To Fin1 - 1
    If RsV(i) = #MarqueProtegee
      If i + 3 < RsNbV
        If EstNiveau(RsV(i + 1))
          CopI(nb) = i
          nb = nb + 1
        EndIf
      EndIf
    EndIf
  Next
  Deb2 = 15
  If RsNbV - 15 > Deb2
    Deb2 = RsNbV - 15
  EndIf
  For i = Deb2 To RsNbV - 1
    If RsV(i) = #MarqueProtegee
      If i + 3 < RsNbV
        If EstNiveau(RsV(i + 1))
          CopI(nb) = i
          nb = nb + 1
        EndIf
      EndIf
    EndIf
  Next
  nbMax = 0
  meilleur = -1
  For c = 0 To nb - 1
    cc = 0
    For i = 0 To nb - 1
      If RsV(CopI(i) + 1) = RsV(CopI(c) + 1) And RsV(CopI(i) + 2) = RsV(CopI(c) + 2) And RsV(CopI(i) + 3) = RsV(CopI(c) + 3)
        cc = cc + 1
      EndIf
    Next
    If cc > nbMax
      nbMax = cc
      meilleur = c
    EndIf
  Next
  If nbMax < 2
    ProcedureReturn #False
  EndIf
  pos = CopI(meilleur)
  EntN = RsV(pos + 1)
  EntLp = (RsV(pos + 2) * 32768) + RsV(pos + 3)
  ; Où finit l'en-tête (et où commence la fin) ? Chaque copie trouvée peut
  ; être la 1re, la 2e ou la 3e: on garde la position qui colle le mieux à
  ; l'en-tête complet attendu (+1 par caractère identique, -1 sinon).
  EnTeteDebut = -1
  EnTeteFin = -1
  scD = -100
  scF = -100
  For c = 0 To nb - 1
    i = CopI(c)
    If RsV(i + 1) = EntN And RsV(i + 2) = RsV(pos + 2) And RsV(i + 3) = RsV(pos + 3)
      For k = 0 To 2
        If i < 15
          E = i + (4 * (3 - k))
          sc = ScoreEntete(E - 12)
          If sc > scD
            scD = sc
            EnTeteDebut = E
          EndIf
        Else
          E = i - (4 * k)
          sc = ScoreEntete(E)
          If sc > scF
            scF = sc
            EnTeteFin = E
          EndIf
        EndIf
      Next
    EndIf
  Next
  ProcedureReturn #True
EndProcedure

; Le segment g commence-t-il, intact, à la position q du bloc collé ?
Procedure SegmentValide(q, g)
  Protected L, o

  L = LongSeg(g)
  If q < 0 Or q + L + 2 > RsNbV
    ProcedureReturn #False
  EndIf
  For o = 0 To L + 1
    LocW(o) = RsV(q + o)
  Next
  SyndromesLocaux(L, g)
  If LocS0 = 0 And LocS1 = 0
    ProcedureReturn #True
  EndIf
  ProcedureReturn #False
EndProcedure

; Numéro du segment intact qui commence à la position q, ou -1
Procedure SegmentEn(q)
  Protected essai, L, o, g

  For essai = 0 To 1
    L = -1
    If essai = 0 And PrG >= 2
      L = #SegC
    EndIf
    If essai = 1
      If LongSeg(PrG - 1) <> #SegC Or PrG = 1
        L = LongSeg(PrG - 1)
      EndIf
    EndIf
    If L > 0
      If q + L + 2 <= RsNbV
        For o = 0 To L + 1
          LocW(o) = RsV(q + o)
        Next
        SyndromesLocaux(L, -1)
        g = LocS0 - 1
        If g >= 0 And g < PrG
          If LongSeg(g) = L And LocS1 = GfMul(LocS0, GfExp(L + 2))
            ProcedureReturn g
          EndIf
        EndIf
      EndIf
    EndIf
  Next
  ProcedureReturn -1
EndProcedure

; Retrouve, dans l'ordre, les segments intacts (ancres)
Procedure Synchroniser()
  Protected q, gs, q2, g2, trouve

  NbAnc = 0
  ReDim AncG(PrG + 1)
  ReDim AncQ(PrG + 1)
  q = 0
  gs = 0
  While q < RsNbV
    If gs < PrG
      If SegmentValide(q, gs)
        AncG(NbAnc) = gs
        AncQ(NbAnc) = q
        NbAnc = NbAnc + 1
        q = q + LongSeg(gs) + 2
        gs = gs + 1
        Continue
      EndIf
    EndIf
    trouve = -1
    q2 = q
    While q2 < RsNbV And trouve < 0
      g2 = SegmentEn(q2)
      If g2 >= gs
        trouve = g2
      Else
        q2 = q2 + 1
      EndIf
    Wend
    If trouve < 0
      Break
    EndIf
    AncG(NbAnc) = trouve
    AncQ(NbAnc) = q2
    NbAnc = NbAnc + 1
    q = q2 + LongSeg(trouve) + 2
    gs = trouve + 1
  Wend
EndProcedure

; Zones abîmées: segments manquants entre deux ancres (ou au début / à la fin)
Procedure ConstruireZones()
  Protected a, g, q, gPrec, qFin

  NbZones = 0
  ReDim ZG1(NbAnc + 2)
  ReDim ZG2(NbAnc + 2)
  ReDim ZDeb(NbAnc + 2)
  ReDim ZLong(NbAnc + 2)
  ReDim ZGauche(NbAnc + 2)
  ReDim ZDroite(NbAnc + 2)
  ReDim ZAttente(NbAnc + 2)
  gPrec = -1
  qFin = EnTeteDebut
  For a = 0 To NbAnc
    If a < NbAnc
      g = AncG(a)
      q = AncQ(a)
    Else
      g = PrG
      q = EnTeteFin
    EndIf
    If g > gPrec + 1
      ZG1(NbZones) = gPrec + 1
      ZG2(NbZones) = g - 1
      ZDeb(NbZones) = 0
      ZLong(NbZones) = 0
      ZGauche(NbZones) = 0
      ZDroite(NbZones) = 0
      If qFin < 0 And q >= 0
        ZLong(NbZones) = q
        ZDroite(NbZones) = 1
      ElseIf qFin >= 0 And q < 0
        ZDeb(NbZones) = qFin
        If RsNbV > qFin
          ZLong(NbZones) = RsNbV - qFin
        EndIf
        ZGauche(NbZones) = 1
      ElseIf qFin >= 0 And q >= 0
        ZDeb(NbZones) = qFin
        If q > qFin
          ZLong(NbZones) = q - qFin
        EndIf
        ZGauche(NbZones) = 1
        ZDroite(NbZones) = 1
      EndIf
      NbZones = NbZones + 1
    EndIf
    If a < NbAnc
      gPrec = g
      qFin = q + LongSeg(g) + 2
    EndIf
  Next
EndProcedure

; Hypothèses possibles pour une zone (genre: 0 identité, 1 trou, 2 caractères
; en trop, 3 début calé seulement, 4 fin calée seulement, 5 rien de calé)
Procedure PreparerHypotheses(z)
  HypLz = LongueurZone(ZG1(z), ZG2(z))
  HypRr = ZLong(z)
  HypMin = HypRr
  If HypLz < HypMin
    HypMin = HypLz
  EndIf
  HypD = HypRr - HypLz
  HypNb = 1
  If ZGauche(z) And ZDroite(z)
    If HypD = 0
      HypGenre = 0
    ElseIf HypD < 0
      HypGenre = 1
      HypNb = HypRr + 1
    Else
      HypGenre = 2
      HypNb = HypRr - HypD + 1
    EndIf
  ElseIf ZGauche(z)
    HypGenre = 3
    HypNb = HypMin + 1
  ElseIf ZDroite(z)
    HypGenre = 4
    HypNb = HypMin + 1
  Else
    HypGenre = 5
  EndIf
EndProcedure

; Hypothèse h: position dans les caractères reçus de la zone pour la
; position i de la zone transmise, ou -1 si inconnue
Procedure Source(h, i)
  Protected y

  If HypGenre = 0
    ProcedureReturn i
  ElseIf HypGenre = 1
    If i < h
      ProcedureReturn i
    ElseIf i < h - HypD
      ProcedureReturn -1
    EndIf
    ProcedureReturn i + HypD
  ElseIf HypGenre = 2
    If i < h
      ProcedureReturn i
    EndIf
    ProcedureReturn i + HypD
  ElseIf HypGenre = 3
    y = HypMin - h
    If i < y
      ProcedureReturn i
    EndIf
  ElseIf HypGenre = 4
    y = HypMin - h
    If HypLz - i <= y
      ProcedureReturn HypRr - (HypLz - i)
    EndIf
  EndIf
  ProcedureReturn -1
EndProcedure

; Remplit la zone z selon l'hypothèse h (contenu dans HVal / HInc) et la
; vérifie avec les codes locaux. Renvoie -1 contredite, 0 invérifiable,
; 1 vérifiée par au moins un segment. HToutConnu = aucun caractère inconnu.
Procedure Remplir(z, h)
  Protected g, g1, L, base, o, k, nbInc, posInc, teste, off

  g1 = ZG1(z)
  teste = #False
  HToutConnu = #True
  For g = g1 To ZG2(z)
    L = LongSeg(g)
    base = (g - g1) * #SegT
    nbInc = 0
    posInc = -1
    For o = 0 To L + 1
      k = Source(h, base + o)
      If k < 0
        LocW(o) = 0
        nbInc = nbInc + 1
        posInc = o
      Else
        LocW(o) = RsV(ZDeb(z) + k)
      EndIf
    Next
    SyndromesLocaux(L, g)
    If nbInc = 0
      If LocS0 <> 0 Or LocS1 <> 0
        ProcedureReturn -1
      EndIf
      teste = #True
    ElseIf nbInc = 1
      If LocS1 <> GfMul(LocS0, GfExp(IndiceLocal(posInc, L)))
        ProcedureReturn -1
      EndIf
      LocW(posInc) = LocS0
      nbInc = 0
      teste = #True
    EndIf
    off = (g - g1) * #SegC
    For o = 0 To L - 1
      If nbInc >= 2 And Source(h, base + o) < 0
        HInc(off + o) = 1
        HVal(off + o) = 0
        HToutConnu = #False
      Else
        HInc(off + o) = 0
        HVal(off + o) = LocW(o)
      EndIf
    Next
  Next
  If teste
    ProcedureReturn 1
  EndIf
  ProcedureReturn 0
EndProcedure

; Recopie la solution HVal / HInc de la zone z dans le flux
Procedure Appliquer(z)
  Protected zs, n, off

  zs = ZG1(z) * #SegC
  n = (ZG2(z) * #SegC) + LongSeg(ZG2(z)) - zs
  For off = 0 To n - 1
    If HInc(off)
      SVal(zs + off) = 0
      SEtat(zs + off) = 1
    Else
      SVal(zs + off) = HVal(off)
      SEtat(zs + off) = 0
    EndIf
  Next
EndProcedure

; Segments g1 à g2 perdus: tout devient inconnu
Procedure Effacer(g1, g2)
  Protected s

  For s = g1 * #SegC To (g2 * #SegC) + LongSeg(g2) - 1
    SVal(s) = 0
    SEtat(s) = 1
  Next
  InfEffacees = InfEffacees + 1
EndProcedure

; Zone de la bonne longueur (caractères faux): le code local corrige
; 1 caractère par segment ; sinon le segment est gardé mais marqué douteux.
Procedure CorrectionAlignee(g1, g2, deb)
  Protected g, L, base, o, et

  For g = g1 To g2
    L = LongSeg(g)
    base = deb + ((g - g1) * #SegT)
    For o = 0 To L + 1
      LocW(o) = RsV(base + o)
    Next
    SyndromesLocaux(L, g)
    et = CorrigerUn(L)
    For o = 0 To L - 1
      SVal((g * #SegC) + o) = LocW(o)
      SEtat((g * #SegC) + o) = et
    Next
    If et = 2
      InfDouteuses = InfDouteuses + 1
    Else
      InfLocales = InfLocales + 1
    EndIf
  Next
EndProcedure

; Ajoute la solution LocW(0 à L-1) aux solutions déjà trouvées pour un segment.
; Renvoie le nouveau nombre de solutions différentes (2 = au moins deux).
Procedure AjouterSolution(L, nbSol)
  Protected o

  If nbSol = 0
    For o = 0 To L - 1
      SegSol(o) = LocW(o)
    Next
    ProcedureReturn 1
  EndIf
  For o = 0 To L - 1
    If SegSol(o) <> LocW(o)
      ProcedureReturn 2
    EndIf
  Next
  ProcedureReturn nbSol
EndProcedure

; Résout le segment g à partir des lg caractères reçus RsV(deb ...):
; lg = longueur normale (vérification), 1 de moins (1 manquant), 1 à 3 de
; plus (caractères en trop). Renvoie 0 rien, 1 résolu, 2 ambigu, 3 corrigé
; (seulement si Correction = #True). Solution dans SegSol().
Procedure ResoudreSeg(g, deb, lg, Correction)
  Protected L, d, x, o, nbSol

  L = LongSeg(g)
  d = lg - (L + 2)
  nbSol = 0
  If d = 0
    For o = 0 To L + 1
      LocW(o) = RsV(deb + o)
    Next
    SyndromesLocaux(L, g)
    If LocS0 = 0 And LocS1 = 0
      nbSol = AjouterSolution(L, nbSol)
    EndIf
  ElseIf d = -1
    For x = 0 To L + 1
      For o = 0 To L + 1
        If o < x
          LocW(o) = RsV(deb + o)
        ElseIf o = x
          LocW(o) = 0
        Else
          LocW(o) = RsV(deb + o - 1)
        EndIf
      Next
      SyndromesLocaux(L, g)
      If LocS1 = GfMul(LocS0, GfExp(IndiceLocal(x, L)))
        LocW(x) = LocS0
        nbSol = AjouterSolution(L, nbSol)
      EndIf
    Next
  ElseIf d >= 1 And d <= 3
    For x = 0 To lg - d
      For o = 0 To L + 1
        If o < x
          LocW(o) = RsV(deb + o)
        Else
          LocW(o) = RsV(deb + o + d)
        EndIf
      Next
      SyndromesLocaux(L, g)
      If LocS0 = 0 And LocS1 = 0
        nbSol = AjouterSolution(L, nbSol)
      EndIf
    Next
  Else
    ProcedureReturn 0
  EndIf
  If nbSol = 0 And d = 0 And Correction
    For o = 0 To L + 1
      LocW(o) = RsV(deb + o)
    Next
    SyndromesLocaux(L, g)
    If CorrigerUn(L) = 3
      For o = 0 To L - 1
        SegSol(o) = LocW(o)
      Next
      ProcedureReturn 3
    EndIf
  EndIf
  If nbSol = 0
    ProcedureReturn 0
  EndIf
  If nbSol > 1
    ProcedureReturn 2
  EndIf
  ProcedureReturn 1
EndProcedure

; Résout les segments de la zone un par un, depuis la gauche (sens = 1) ou
; la droite (sens = -1). Renvoie le nombre de segments résolus ; caractères
; reçus consommés dans PelPos ; segments ambigus dans PelAmbigus.
Procedure Peler(z, sens)
  Protected k, g, L, dd, n, r, deb, nz, rang, o, trouve, essai, nb, Correction, ntrouve

  nz = ZG2(z) - ZG1(z) + 1
  rang = 0
  If sens < 0
    rang = 1
  EndIf
  PelPos = 0
  PelAmbigus = 0
  nb = 0
  For k = 0 To nz - 1
    If sens > 0
      g = ZG1(z) + k
    Else
      g = ZG2(z) - k
    EndIf
    L = LongSeg(g)
    trouve = 0
    ntrouve = 0
    For essai = 0 To 5
      If trouve = 0
        dd = 0
        Correction = #False
        If essai = 1
          dd = -1
        ElseIf essai >= 2 And essai <= 4
          dd = essai - 1
        ElseIf essai = 5
          Correction = #True
        EndIf
        n = L + 2 + dd
        If PelPos + n <= ZLong(z)
          If sens > 0
            deb = ZDeb(z) + PelPos
          Else
            deb = ZDeb(z) + ZLong(z) - PelPos - n
          EndIf
          r = ResoudreSeg(g, deb, n, Correction)
          If r > 0
            trouve = r
            ntrouve = n
          EndIf
        EndIf
      EndIf
    Next
    If trouve = 0
      Break
    EndIf
    PelEtat((rang * nz) + k) = trouve
    PelN((rang * nz) + k) = ntrouve
    If trouve = 2
      PelAmbigus = PelAmbigus + 1
    EndIf
    For o = 0 To L - 1
      PelVal((((rang * nz) + k) * #SegC) + o) = SegSol(o)
    Next
    PelPos = PelPos + ntrouve
    nb = nb + 1
  Next
  ProcedureReturn nb
EndProcedure

; Recopie dans le flux les nb premiers segments pelés (rang 0 gauche, 1 droite)
Procedure AppliquerPele(z, rang, nb)
  Protected k, g, L, o, nz, et, s

  nz = ZG2(z) - ZG1(z) + 1
  If nb > 0
    For k = 0 To nb - 1
      If rang = 0
        g = ZG1(z) + k
      Else
        g = ZG2(z) - k
      EndIf
      L = LongSeg(g)
      et = PelEtat((rang * nz) + k)
      For o = 0 To L - 1
        s = (g * #SegC) + o
        If et = 1 Or et = 3
          SVal(s) = PelVal((((rang * nz) + k) * #SegC) + o)
          If et = 1
            SEtat(s) = 0
          Else
            SEtat(s) = 3
          EndIf
        Else
          SVal(s) = 0
          SEtat(s) = 1
        EndIf
      Next
      InfLocales = InfLocales + 1
    Next
  EndIf
EndProcedure

; Une seule hypothèse entièrement vérifiée par les codes locaux ? Elle est
; alors dans HVal / HInc.
Procedure LocalGeneral(z)
  Protected h, v, n, i, trouve

  PreparerHypotheses(z)
  n = (ZG2(z) * #SegC) + LongSeg(ZG2(z)) - (ZG1(z) * #SegC)
  trouve = #False
  For h = 0 To HypNb - 1
    v = Remplir(z, h)
    If v = 1 And HToutConnu
      If trouve = #False
        For i = 0 To n - 1
          HPrem(i) = HVal(i)
        Next
        trouve = #True
      Else
        For i = 0 To n - 1
          If HPrem(i) <> HVal(i)
            ProcedureReturn #False
          EndIf
        Next
      EndIf
    EndIf
  Next
  If trouve
    For i = 0 To n - 1
      HVal(i) = HPrem(i)
      HInc(i) = 0
    Next
    ProcedureReturn #True
  EndIf
  ProcedureReturn #False
EndProcedure

; Les syndromes HS de la tranche t s'expliquent-ils par ses seuls effacements
; (HE) ? (syndromes modifiés de Forney nuls)
Procedure EffacementsSeulementOk(t)
  Protected f, e, i, j, X, tt, P

  P = PrP
  f = HNbE(t)
  For i = 0 To f
    RsGam(i) = 0
  Next
  RsGam(0) = 1
  If f > 0
    For e = 0 To f - 1
      X = GfExp(HE((t * 256) + e))
      For i = e + 1 To 1 Step -1
        RsGam(i) = (RsGam(i) ! GfMul(RsGam(i - 1), X))
      Next
    Next
  EndIf
  For i = f To P - 1
    tt = 0
    For j = 0 To f
      If i - j >= 0
        tt = (tt ! GfMul(HS((t * P) + i - j), RsGam(j)))
      EndIf
    Next
    If tt <> 0
      ProcedureReturn #False
    EndIf
  Next
  ProcedureReturn #True
EndProcedure

; Départage les hypothèses de la zone z avec le code de Reed-Solomon: la
; bonne est celle où chaque tranche s'explique par ses seuls caractères
; inconnus. Solution dans HVal / HInc.
Procedure RsGeneral(z)
  Protected P, nt, s, t, j, k, zs, ze, h, v, n, off, i, verifs, testable, ok, secours

  P = PrP
  nt = PrT
  zs = ZG1(z) * #SegC
  ze = (ZG2(z) * #SegC) + LongSeg(ZG2(z))
  n = ze - zs
  For i = 0 To (nt * P) - 1
    BaseS(i) = 0
  Next
  For t = 0 To nt - 1
    BaseNbE(t) = 0
  Next
  For s = 0 To PrM - 1
    If s < zs Or s >= ze
      t = s % nt
      j = s / nt
      If SEtat(s) = 0 Or SEtat(s) = 3
        If SVal(s) <> 0
          For k = 0 To P - 1
            BaseS((t * P) + k) = (BaseS((t * P) + k) ! GfExp(GfLog(SVal(s)) + ((j * k) % #RsN1)))
          Next
        EndIf
      Else
        If BaseNbE(t) < 256
          BaseE((t * 256) + BaseNbE(t)) = j
        EndIf
        BaseNbE(t) = BaseNbE(t) + 1
      EndIf
    EndIf
  Next

  PreparerHypotheses(z)
  secours = -1
  For h = 0 To HypNb - 1
    v = Remplir(z, h)
    If v < 0
      Continue
    EndIf
    For i = 0 To (nt * P) - 1
      HS(i) = BaseS(i)
    Next
    For t = 0 To nt - 1
      HNbE(t) = BaseNbE(t)
      For i = 0 To 255
        HE((t * 256) + i) = BaseE((t * 256) + i)
      Next
    Next
    For off = 0 To n - 1
      s = zs + off
      t = s % nt
      j = s / nt
      If HInc(off)
        If HNbE(t) < 256
          HE((t * 256) + HNbE(t)) = j
        EndIf
        HNbE(t) = HNbE(t) + 1
      ElseIf HVal(off) <> 0
        For k = 0 To P - 1
          HS((t * P) + k) = (HS((t * P) + k) ! GfExp(GfLog(HVal(off)) + ((j * k) % #RsN1)))
        Next
      EndIf
    Next
    verifs = 0
    testable = #True
    For t = 0 To nt - 1
      verifs = verifs + P - HNbE(t)
      If HNbE(t) > P - 1
        testable = #False
      EndIf
    Next
    If verifs < 3
      testable = #False
    EndIf
    If testable
      ok = #True
      For t = 0 To nt - 1
        If ok
          If EffacementsSeulementOk(t) = #False
            ok = #False
          EndIf
        EndIf
      Next
      If ok
        ProcedureReturn #True
      EndIf
    ElseIf secours < 0
      If ZGauche(z) = 0 Or ZDroite(z) = 0
        secours = h
      EndIf
    EndIf
  Next
  If secours >= 0
    Remplir(z, secours)
    ProcedureReturn #True
  EndIf
  ProcedureReturn #False
EndProcedure

; Répare le bloc protégé RsV(0 à RsNbV-1): bloc compact dans RsCharge().
; Renvoie sa longueur, ou: -1 = pas un bloc protégé, -2 = en-tête illisible,
; -3 = trop abîmé (tranche dans RsTrancheAbimee, manque dans InfManque).
Procedure ReparerValeurs2()
  Protected z, g1, g2, nz, lz, fait, nb, t, n, j, essai, f, res, nbG, nbD, pg, pd, k, r1, r2, s, a, g, o, L, P, nt, e, maxc, maxz

  InitialiserGF()
  InfZones = 0
  InfLocales = 0
  InfRS = 0
  InfEffacees = 0
  InfDouteuses = 0
  InfManque = 0
  RsTrancheAbimee = 0
  If RsNbV < 13
    ProcedureReturn -1
  EndIf
  If LireEntete() = #False
    ProcedureReturn -2
  EndIf
  If EntLp < 9 Or EntLp > (2 * RsNbV) + 1000 Or EntLp > 3000000
    ProcedureReturn -2
  EndIf
  FixerParametres(EntN, EntLp)
  PreparerGenerateur(PrP)
  P = PrP
  nt = PrT
  InfManque = (2 * #EnTeteProtege) + PrM + (2 * PrG) - RsNbV
  ReDim SVal(PrM)
  ReDim SEtat(PrM)
  For s = 0 To PrM - 1
    SVal(s) = 0
    SEtat(s) = 1
  Next

  ; 1. Segments intacts, recopiés tels quels
  Synchroniser()
  If NbAnc > 0
    For a = 0 To NbAnc - 1
      g = AncG(a)
      L = LongSeg(g)
      For o = 0 To L - 1
        SVal((g * #SegC) + o) = RsV(AncQ(a) + o)
        SEtat((g * #SegC) + o) = 0
      Next
    Next
  EndIf

  ; 2. Zones abîmées entre eux
  ConstruireZones()
  InfZones = NbZones
  maxc = 1
  maxz = 1
  If NbZones > 0
    For z = 0 To NbZones - 1
      n = (ZG2(z) * #SegC) + LongSeg(ZG2(z)) - (ZG1(z) * #SegC)
      If n > maxc
        maxc = n
      EndIf
      If ZG2(z) - ZG1(z) + 1 > maxz
        maxz = ZG2(z) - ZG1(z) + 1
      EndIf
    Next
  EndIf
  ReDim HVal(maxc)
  ReDim HInc(maxc)
  ReDim HPrem(maxc)
  ReDim HPremInc(maxc)
  ReDim PelVal(2 * maxz * #SegC)
  ReDim PelEtat(2 * maxz)
  ReDim PelN(2 * maxz)
  ReDim BaseS(nt * P)
  ReDim HS(nt * P)
  ReDim BaseNbE(nt)
  ReDim HNbE(nt)
  ReDim BaseE(nt * 256)
  ReDim HE(nt * 256)

  ; 3a. Ce que les codes locaux savent réparer seuls
  If NbZones > 0
    For z = 0 To NbZones - 1
      ZAttente(z) = 0
      g1 = ZG1(z)
      g2 = ZG2(z)
      lz = LongueurZone(g1, g2)
      fait = #False
      If ZGauche(z) And ZDroite(z)
        If ZLong(z) = lz
          CorrectionAlignee(g1, g2, ZDeb(z))
          fait = #True
        Else
          nb = Peler(z, 1)
          If nb = g2 - g1 + 1 And PelPos = ZLong(z) And PelAmbigus = 0
            AppliquerPele(z, 0, nb)
            fait = #True
          Else
            nb = Peler(z, -1)
            If nb = g2 - g1 + 1 And PelPos = ZLong(z) And PelAmbigus = 0
              AppliquerPele(z, 1, nb)
              fait = #True
            EndIf
          EndIf
        EndIf
      EndIf
      If fait = #False
        If LocalGeneral(z)
          Appliquer(z)
          InfLocales = InfLocales + 1
          fait = #True
        EndIf
      EndIf
      If fait = #False
        ZAttente(z) = 1
      EndIf
    Next

    ; 3b. Le reste, départagé par le code de Reed-Solomon
    For z = 0 To NbZones - 1
      If ZAttente(z)
        g1 = ZG1(z)
        g2 = ZG2(z)
        nz = g2 - g1 + 1
        If RsGeneral(z)
          Appliquer(z)
          InfRS = InfRS + 1
        ElseIf ZGauche(z) And ZDroite(z)
          nbG = Peler(z, 1)
          pg = PelPos
          nbD = Peler(z, -1)
          If nbD > nz - nbG
            nbD = nz - nbG
          EndIf
          pd = 0
          If nbD > 0
            For k = 0 To nbD - 1
              pd = pd + PelN(nz + k)
            Next
          EndIf
          r1 = g1 + nbG
          r2 = g2 - nbD
          If r1 <= r2 And pg + pd <= ZLong(z)
            AppliquerPele(z, 0, nbG)
            AppliquerPele(z, 1, nbD)
            ZG1(NbZones) = r1
            ZG2(NbZones) = r2
            ZDeb(NbZones) = ZDeb(z) + pg
            ZLong(NbZones) = ZLong(z) - pg - pd
            ZGauche(NbZones) = 1
            ZDroite(NbZones) = 1
            If ZLong(NbZones) = LongueurZone(r1, r2)
              CorrectionAlignee(r1, r2, ZDeb(NbZones))
            ElseIf RsGeneral(NbZones)
              Appliquer(NbZones)
              InfRS = InfRS + 1
            Else
              Effacer(r1, r2)
            EndIf
          Else
            Effacer(g1, g2)
          EndIf
        Else
          Effacer(g1, g2)
        EndIf
      EndIf
    Next
  EndIf

  ; 4. Correction finale de chaque tranche
  ReDim RsCharge(EntLp)
  For t = 0 To nt - 1
    n = (PrM - t + nt - 1) / nt
    res = -1
    For essai = 0 To 2
      If res < 0
        f = 0
        For j = 0 To n - 1
          RsMot(j) = SVal((j * nt) + t)
          e = SEtat((j * nt) + t)
          If e = 1 Or (essai >= 1 And e = 2) Or (essai = 2 And e = 3)
            If f < 256
              RsEff(f) = j
            EndIf
            f = f + 1
          EndIf
        Next
        If essai = 0 Or f <= P - 1
          res = RsDecoder(n, f)
        EndIf
      EndIf
    Next
    If res < 0
      RsTrancheAbimee = t + 1
      ProcedureReturn -3
    EndIf
    For j = P To n - 1
      RsCharge(((j - P) * nt) + t) = RsMot(j)
    Next
  Next
  ProcedureReturn EntLp
EndProcedure

EnableDebugger


; ----------------------------------------------------------------------------
;  Le bloc (uniquement des caractères Unicode) est-il un bloc protégé ?
;  Il commence et finit par 3 copies de la marque: on en veut au moins 2
;  parmi les 15 premiers et les 15 derniers caractères (au cas où un bout
;  serait abîmé). Renvoie 1 = bloc protégé, 2 = ancien format (v5.3), 0 = non.
; ----------------------------------------------------------------------------
Procedure EstBlocProtege(Donnees$)
  Protected i, n, v, Nb, NbV1, Debut

  n = Len(Donnees$)
  If n < 13
    ProcedureReturn 0
  EndIf
  For i = 1 To 15
    If i <= n
      v = ValeurUnicode(Asc(Mid(Donnees$, i, 1)))
      If v = #MarqueProtegee
        Nb = Nb + 1
      ElseIf v = #MarqueProtegeeV1
        NbV1 = NbV1 + 1
      EndIf
    EndIf
  Next
  Debut = n - 14
  If Debut < 16
    Debut = 16
  EndIf
  For i = Debut To n
    If ValeurUnicode(Asc(Mid(Donnees$, i, 1))) = #MarqueProtegee
      Nb = Nb + 1
    EndIf
  Next
  If Nb >= 2
    ProcedureReturn 1
  ElseIf NbV1 >= 2
    ProcedureReturn 2
  EndIf
  ProcedureReturn 0
EndProcedure


; ----------------------------------------------------------------------------
;  Nom d'un niveau de protection (N = 1, 2, 4, 8 ou 16)
; ----------------------------------------------------------------------------
Procedure.s NomNiveauProtection(N)
  Select N
    Case 1
      ProcedureReturn "Faible"
    Case 2
      ProcedureReturn "Normale"
    Case 4
      ProcedureReturn "Moyen"
    Case 8
      ProcedureReturn "Élevé"
    Case 16
      ProcedureReturn "Maximal"
  EndSelect
  ProcedureReturn "?"
EndProcedure


; ----------------------------------------------------------------------------
;  Bloc compact -> bloc protégé au niveau N (1, 2, 4, 8 ou 16)
; ----------------------------------------------------------------------------
Procedure.s ProtegerBloc(Bloc$, N)
  Protected i, lp, NbCar, Resultat$, *Lecture.Unicode, *Ecriture.Unicode

  lp = Len(Bloc$)
  ReDim RsCharge(lp)
  *Lecture = @Bloc$
  For i = 0 To lp - 1
    RsCharge(i) = ValeurUnicode(*Lecture\u)
    *Lecture = *Lecture + 2
  Next

  NbCar = ProtegerValeurs2(lp, N)

  Resultat$ = Space(NbCar)
  *Ecriture = @Resultat$
  For i = 0 To NbCar - 1
    *Ecriture\u = CaractereUnicode(RsSortie(i))
    *Ecriture = *Ecriture + 2
  Next
  ProcedureReturn Resultat$
EndProcedure


; ----------------------------------------------------------------------------
;  Bloc protégé (uniquement des caractères Unicode) -> bloc compact réparé.
;  Renvoie "" si le bloc est trop abîmé (raison dans ErreurDecompression$).
; ----------------------------------------------------------------------------
Procedure.s ReparerBloc(Donnees$)
  Protected i, lp, Secours, Niveau$, Resultat$, *Lecture.Unicode, *Ecriture.Unicode

  RsNbV = Len(Donnees$)
  ReDim RsV(RsNbV)
  *Lecture = @Donnees$
  For i = 0 To RsNbV - 1
    RsV(i) = ValeurUnicode(*Lecture\u)
    *Lecture = *Lecture + 2
  Next

  lp = ReparerValeurs2()

  If lp = -1 Or lp = -2
    ErreurDecompression$ = "Bloc protégé, mais ses en-têtes (au début et à la fin du bloc) sont illisibles." + #LF$ + "Recopie le bloc en entier."
    ProcedureReturn ""
  ElseIf lp < 0
    Secours = PrP * PrT
    Niveau$ = "Bloc protégé (niveau " + NomNiveauProtection(PrN) + "), mais trop abîmé pour être réparé: "
    If InfManque > (Secours * 9) / 10
      ErreurDecompression$ = Niveau$ + "il manque environ " + Str(InfManque) + " caractères, et ce niveau ne peut en rattraper qu'environ " + Str(Secours) + "."
    ElseIf InfManque > 0
      ErreurDecompression$ = Niveau$ + "il manque environ " + Str(InfManque) + " caractères, et d'autres sont abîmés à plusieurs endroits."
    ElseIf InfManque < 0
      ErreurDecompression$ = Niveau$ + "il y a environ " + Str(-InfManque) + " caractères en trop, et d'autres sont abîmés."
    Else
      ErreurDecompression$ = Niveau$ + "trop de caractères faux."
    EndIf
    ErreurDecompression$ = ErreurDecompression$ + #LF$ + "Recopie le bloc en entier."
    ProcedureReturn ""
  EndIf

  Resultat$ = Space(lp)
  *Ecriture = @Resultat$
  For i = 0 To lp - 1
    *Ecriture\u = CaractereUnicode(RsCharge(i))
    *Ecriture = *Ecriture + 2
  Next
  ProcedureReturn Resultat$
EndProcedure


; ----------------------------------------------------------------------------
;  Phrase sur l'état d'un bloc protégé, après décompression réussie (vide si
;  le bloc n'était pas protégé)
; ----------------------------------------------------------------------------
Procedure.s CompteRenduProtection()
  Protected Phrase$

  If BlocProtege = #False
    ProcedureReturn ""
  EndIf
  Phrase$ = "Bloc protégé (niveau " + NomNiveauProtection(PrN) + ")"
  If InfZones = 0
    ProcedureReturn Phrase$ + ", reçu intact. "
  EndIf
  Phrase$ = Phrase$ + ": " + Str(InfZones) + " endroit(s) abîmé(s), RÉPARÉ(S)"
  If InfManque > 0
    Phrase$ = Phrase$ + " (" + Str(InfManque) + " caractère(s) manquant(s) retrouvé(s))"
  ElseIf InfManque < 0
    Phrase$ = Phrase$ + " (" + Str(-InfManque) + " caractère(s) en trop retiré(s))"
  EndIf
  ProcedureReturn Phrase$ + ". "
EndProcedure


; ----------------------------------------------------------------------------
;  Le texte n'est-il QU'UN bloc compact, protégé ou non (rien d'autre que des
;  caractères Unicode, à part des espaces et retours à la ligne) ? Sert au
;  démarrage, pour ne jamais se déclencher sur autre chose.
; ----------------------------------------------------------------------------
Procedure EstBlocCompactPur(Texte$)
  Protected SansBlancs$, Unicode$

  SansBlancs$ = RemoveString(RemoveString(RemoveString(RemoveString(Texte$, " "), #TAB$), #CR$), #LF$)
  Unicode$ = GarderCaracteresUnicode(SansBlancs$)
  If Len(Unicode$) > 8 And Len(Unicode$) = Len(SansBlancs$)
    If ValeurUnicode(Asc(Left(Unicode$, 1))) = #MarqueCompacte Or EstBlocProtege(Unicode$) > 0
      ProcedureReturn #True
    EndIf
  EndIf
  ProcedureReturn #False
EndProcedure


; ----------------------------------------------------------------------------
;  Niveaux de compression: composition du texte de référence de chaque niveau
; ----------------------------------------------------------------------------
Procedure LireTableReference()
  Protected i
  Protected.q v

  If TableReferenceLue
    ProcedureReturn
  EndIf
  Restore TableReference
  For i = 0 To #NbSegments - 1
    Read.q v
    SegmentTaille(i) = v
    Read.q v
    SegmentControle(i) = v
  Next
  TableReferenceLue = #True
EndProcedure


; Les segments d'un niveau, dans l'ordre (le code de Shadow, segment 1, en dernier)
Procedure.s CompositionNiveau(Niveau)
  Select Niveau
    Case #NiveauFaible
      ProcedureReturn "0"
    Case #NiveauMoyen
      ProcedureReturn "0,1"
    Case #NiveauNormal
      ProcedureReturn "0,2,1"
    Case #NiveauEleve
      ProcedureReturn "0,2,3,1"
    Case #NiveauMaximal
      ProcedureReturn "0,2,3,4,1"
  EndSelect
  ProcedureReturn "0,1"
EndProcedure


; Niveau ramené dans les bornes (Moyen si la valeur n'est pas valable)
Procedure NiveauValide(Niveau)
  If Niveau < #NiveauFaible Or Niveau > #NiveauMaximal
    ProcedureReturn #NiveauMoyen
  EndIf
  ProcedureReturn Niveau
EndProcedure


; Taille du texte de référence d'un niveau, en octets
Procedure.q TailleNiveau(Niveau)
  Protected Liste$, i
  Protected.q Total

  LireTableReference()
  Liste$ = CompositionNiveau(Niveau)
  For i = 1 To CountString(Liste$, ",") + 1
    Total = Total + SegmentTaille(Val(StringField(Liste$, i, ",")))
  Next
  ProcedureReturn Total
EndProcedure


; Numéro de format écrit dans le bloc (4 = Moyen, la référence de la v6.1)
Procedure CodeNiveau(Niveau)
  Select Niveau
    Case #NiveauFaible
      ProcedureReturn 5
    Case #NiveauNormal
      ProcedureReturn 6
    Case #NiveauEleve
      ProcedureReturn 7
    Case #NiveauMaximal
      ProcedureReturn 8
  EndSelect
  ProcedureReturn 4
EndProcedure


Procedure NiveauDuCode(Code)
  Select Code
    Case 5
      ProcedureReturn #NiveauFaible
    Case 6
      ProcedureReturn #NiveauNormal
    Case 7
      ProcedureReturn #NiveauEleve
    Case 8
      ProcedureReturn #NiveauMaximal
  EndSelect
  ProcedureReturn #NiveauMoyen
EndProcedure


Procedure.s NomNiveau(Niveau)
  Select Niveau
    Case #NiveauFaible
      ProcedureReturn "Faible"
    Case #NiveauNormal
      ProcedureReturn "Normal"
    Case #NiveauEleve
      ProcedureReturn "Élevé"
    Case #NiveauMaximal
      ProcedureReturn "Maximal"
  EndSelect
  ProcedureReturn "Moyen"
EndProcedure


; ----------------------------------------------------------------------------
;  Barre de progression, dans la barre d'état en bas de la fenêtre, pendant
;  les méthodes Maximal v3 et v4 (la v4 peut prendre une ou deux minutes).
;  Une opération (compression ou décompression) prévoit d'abord tout son
;  travail, compté en « unités »: 1 par octet lu par la méthode v3, 4 par
;  octet lu par la méthode v4 (environ 4 fois plus lente). Le temps restant
;  est estimé d'après la vitesse depuis le début de l'opération.
;  Les boucles des méthodes v3 et v4 appellent ProgressionCM() tous les
;  4 096 octets ; cet appel ne change rien au calcul.
; ----------------------------------------------------------------------------
Global ProgresEnCours, ProgresPoids, ProgresEtape$
Global.q ProgresTotal, ProgresFait, ProgresDebut, ProgresDernier
Global.q ProgresOrigine         ; position où commence la passe (fin du texte de référence si l'état est relu)
Global ProgresMesurable         ; #False si l'opération a relu un état: la vitesse n'est pas mesurée
Global.q ProgresHorsTemps, ProgresHorsUnites   ; contrôle d'un nouvel état: exclu de la mesure de vitesse

Procedure.s FormaterDuree(Millisecondes.q)
  Protected.q Secondes

  Secondes = (Millisecondes + 500) / 1000
  If Secondes < 60
    ProcedureReturn Str(Secondes) + " s"
  EndIf
  ProcedureReturn Str(Secondes / 60) + " min " + RSet(Str(Secondes % 60), 2, "0") + " s"
EndProcedure


; La fenêtre reste vivante pendant un calcul: elle se redessine, mais les clics
; sont ignorés. Fermer la fenêtre enregistre les réglages et arrête le programme.
Procedure ViderEvenements()
  Protected Evenement

  Repeat
    Evenement = WindowEvent()
    If Evenement = #PB_Event_CloseWindow
      SauverReglages()
      End
    EndIf
  Until Evenement = 0
EndProcedure


Procedure AfficherProgression(Fait.q)
  Protected.q Ecoule, Reste
  Protected Pourcent, Texte$

  If ProgresTotal <= 0
    ProcedureReturn
  EndIf
  If Fait > ProgresTotal
    Fait = ProgresTotal
  EndIf
  Pourcent = (Fait * 100) / ProgresTotal
  Ecoule = ElapsedMilliseconds() - ProgresDebut
  Texte$ = ProgresEtape$ + ": " + Str(Pourcent) + " %      Écoulé: " + FormaterDuree(Ecoule) + "      Reste: "
  If Fait > ProgresTotal / 100 And Ecoule >= 2000
    Reste = (Ecoule * (ProgresTotal - Fait)) / Fait
    Texte$ = Texte$ + "environ " + FormaterDuree(Reste)
  Else
    Texte$ = Texte$ + "calcul en cours..."
  EndIf
  StatusBarProgress(#BarreEtat, 0, Pourcent)
  StatusBarText(#BarreEtat, 1, Texte$)
  ViderEvenements()
EndProcedure


; Appelée par les boucles des méthodes v3 et v4 (affichage 4 fois par seconde au plus)
Procedure ProgressionCM(Position.q)
  Protected.q Maintenant, Avance

  If ProgresEnCours
    Maintenant = ElapsedMilliseconds()
    If Maintenant - ProgresDernier >= 250
      ProgresDernier = Maintenant
      Avance = Position - ProgresOrigine
      If Avance < 0
        Avance = 0
      EndIf
      AfficherProgression(ProgresFait + (Avance * ProgresPoids))
    EndIf
  EndIf
EndProcedure


; Grise (Etat = #False) ou réactive les boutons et les réglages. Après une
; réactivation, FinOperation() remet chaque réglage dans le bon état.
Procedure ActiverBoutons(Etat)
  Protected Inactif = Bool(Etat = #False)

  DisableGadget(#BoutonColler, Inactif)
  DisableGadget(#BoutonOuvrir, Inactif)
  DisableGadget(#BoutonCompresser, Inactif)
  DisableGadget(#BoutonDecColler, Inactif)
  DisableGadget(#BoutonDecCopier, Inactif)
  DisableGadget(#BoutonDecEnregistrer, Inactif)
  DisableGadget(#ChoixFormat, Inactif)
  DisableGadget(#ChoixMethode, Inactif)
  DisableGadget(#ChoixEncodage, Inactif)
  DisableGadget(#ChoixLangue, Inactif)
  DisableGadget(#CaseOptionsIDE, Inactif)
  DisableGadget(#ChampLimite, Inactif)
  DisableGadget(#ChoixProtection, Inactif)
  DisableGadget(#ChoixNiveau, Inactif)
  DisableGadget(#CaseGarderEtat, Inactif)
  DisableGadget(#BoutonEffacerEtat, Inactif)
EndProcedure


; Début d'une opération longue: Total = tout le travail prévu, en unités
Procedure DebutProgression(Total.q)
  ProgresEnCours = #True
  ProgresTotal = Total
  ProgresFait = 0
  ProgresPoids = 1
  ProgresEtape$ = "Préparation"
  ProgresDebut = ElapsedMilliseconds()
  ProgresDernier = 0
  ProgresOrigine = 0
  ProgresMesurable = #True
  ProgresHorsTemps = 0
  ProgresHorsUnites = 0
  ActiverBoutons(#False)
  AfficherProgression(0)
EndProcedure


Procedure FinProgression()
  Protected.q Ecoule

  If ProgresEnCours
    ProgresEnCours = #False
    ; Vitesse de ce PC: mesurée sur les opérations longues allées au bout
    Ecoule = ElapsedMilliseconds() - ProgresDebut - ProgresHorsTemps
    If ProgresMesurable And Ecoule > 5000 And ProgresFait >= (ProgresTotal * 9) / 10
      VitesseCM = (VitesseCM + (((ProgresFait - ProgresHorsUnites) * 1000) / Ecoule)) / 2
    EndIf
    StatusBarProgress(#BarreEtat, 0, 100)
    StatusBarText(#BarreEtat, 1, "Terminé en " + FormaterDuree(ElapsedMilliseconds() - ProgresDebut) + ".")
    ; Les boutons sont réactivés par l'opération elle-même, quand tout est fini
    ; (voir FinOperation dans le programme principal)
  EndIf
EndProcedure


; Une passe d'une méthode commence (Poids: 1 pour la v3, 4 pour la v4).
; Origine: position du premier octet lu (la fin du texte de référence si l'état
; du modèle est relu depuis le disque, sinon 0).
Procedure CommencerPasse(Etape$, Poids, Origine.q = 0)
  ProgresEtape$ = Etape$
  ProgresPoids = Poids
  ProgresOrigine = Origine
  If Origine > 0
    ProgresMesurable = #False
  EndIf
  If ProgresEnCours
    AfficherProgression(ProgresFait)
  EndIf
EndProcedure


; La passe est finie: Taille = nombre d'octets lus (texte de référence compris,
; sauf s'il n'a pas été relu)
Procedure TerminerPasse(Taille.q)
  ProgresFait = ProgresFait + (Taille * ProgresPoids)
EndProcedure


; Travail d'une passe de la méthode v4 sur un code de T octets, à un niveau
Procedure.q TravailMethode4(T.q, Niveau)
  ProcedureReturn (TailleNiveau(Niveau) + T) * 4
EndProcedure


; ----------------------------------------------------------------------------
;  État du modèle v4 gardé sur le disque: lecture (Sens = 0) ou écriture
;  (Sens = 1) d'une zone de mémoire, par morceaux de 16 Mo, en tenant à jour une
;  somme de contrôle de tout l'état. Renvoie la somme mise à jour, ou -1 si la
;  lecture ou l'écriture a échoué (ou avait déjà échoué: Crc = -1).
;  Somme de contrôle (comme celle de Fletcher): S1 additionne les nombres de 4
;  octets, S2 additionne les valeurs successives de S1 (elle dépend donc aussi
;  de la place de chaque nombre). Les deux sont ramenées sous #PremierEtat tous
;  les 4 096 nombres, sans débordement possible. Crc = (S1 * 2147483648) + S2.
;  Ces procédures peuvent être appelées par la méthode v4 depuis le second
;  thread de vérification: dans ce thread, rien n'est affiché (voir
;  AvancementEtat).
;  EchangeMemoire tourne sans le débogueur, comme les méthodes Maximal: sa
;  boucle passe environ 166 millions de fois à chaque lecture ou écriture de
;  l'état, ce qui est bien plus lent avec le débogueur (programme lancé par F5).
; ----------------------------------------------------------------------------
#PremierEtat = 2147483629

; Affiche où en est la lecture (Sens = 0) ou l'écriture (Sens = 1) de l'état
; sur le disque, et garde la fenêtre vivante. Appelée après chaque morceau de
; 16 Mo. Ne fait rien dans le second thread, ni hors d'une opération.
Procedure AvancementEtat(Sens.q, Morceau.q)
  Protected Pourcent, Texte$

  If EstFilVerification Or ProgresEnCours = #False
    ProcedureReturn
  EndIf
  EtatOctets = EtatOctets + Morceau
  Pourcent = (EtatOctets * 100) / #TailleEtatModele4
  If Pourcent > 100
    Pourcent = 100
  EndIf
  ; L'étape en cours (compression, vérification, contrôle...) est rappelée
  ; devant, pour savoir quelle passe lit ou écrit
  If Sens = 1
    Texte$ = ProgresEtape$ + " — écriture de l'état du modèle sur le disque (1re fois à ce niveau): "
  Else
    Texte$ = ProgresEtape$ + " — lecture de l'état du modèle sur le disque: "
  EndIf
  Texte$ = Texte$ + Str(EtatOctets / (1024 * 1024)) + " Mo sur " + Str(#TailleEtatModele4 / (1024 * 1024)) + " Mo (" + Str(Pourcent) + " %)"
  StatusBarProgress(#BarreEtat, 0, Pourcent)
  StatusBarText(#BarreEtat, 1, Texte$)
  ViderEvenements()
EndProcedure


; Affiche une étape courte (fichiers d'état), sans changer la barre
Procedure AfficherEtape(Texte$)
  If ProgresEnCours
    StatusBarText(#BarreEtat, 1, Texte$)
    ViderEvenements()
  EndIf
EndProcedure


DisableDebugger
Procedure.q EchangeMemoire(Fichier.q, Sens.q, *Adresse, Taille.q, Crc.q)
  Protected.q Fait, Morceau, S1, S2, Reste, Paquet, i
  Protected *L.Long

  If Crc < 0 Or Fichier = 0
    ProcedureReturn -1
  EndIf
  S1 = Crc / 2147483648
  S2 = Crc % 2147483648
  While Fait < Taille
    Morceau = Taille - Fait
    If Morceau > #MorceauEtat
      Morceau = #MorceauEtat
    EndIf
    If Sens = 1
      If WriteData(Fichier, *Adresse + Fait, Morceau) <> Morceau
        ProcedureReturn -1
      EndIf
    Else
      If ReadData(Fichier, *Adresse + Fait, Morceau) <> Morceau
        ProcedureReturn -1
      EndIf
    EndIf
    ; Somme de contrôle du morceau: nombres de 4 octets, puis les derniers octets
    *L = *Adresse + Fait
    Reste = Morceau / 4
    While Reste > 0
      Paquet = Reste
      If Paquet > 4096
        Paquet = 4096
      EndIf
      Reste = Reste - Paquet
      While Paquet > 0
        S1 = S1 + *L\l + 2147483648
        S2 = S2 + S1
        *L = *L + 4
        Paquet = Paquet - 1
      Wend
      S1 = S1 % #PremierEtat
      S2 = S2 % #PremierEtat
    Wend
    For i = (Morceau / 4) * 4 To Morceau - 1
      S1 = (S1 + PeekA(*Adresse + Fait + i)) % #PremierEtat
      S2 = (S2 + S1) % #PremierEtat
    Next
    AvancementEtat(Sens, Morceau)
    Fait = Fait + Morceau
  Wend
  ProcedureReturn (S1 * 2147483648) + S2
EndProcedure
EnableDebugger

; Un tableau entier de l'état (ArraySize donne le plus grand indice)
Procedure.q EchangeTableauL(Fichier.q, Sens.q, Array Tab.l(1), Crc.q)
  ProcedureReturn EchangeMemoire(Fichier, Sens, @Tab(0), (ArraySize(Tab()) + 1) * 4, Crc)
EndProcedure

Procedure.q EchangeTableauA(Fichier.q, Sens.q, Array Tab.a(1), Crc.q)
  ProcedureReturn EchangeMemoire(Fichier, Sens, @Tab(0), ArraySize(Tab()) + 1, Crc)
EndProcedure

Procedure.q EchangeTableauQ(Fichier.q, Sens.q, Array Tab.q(1), Crc.q)
  ProcedureReturn EchangeMemoire(Fichier, Sens, @Tab(0), (ArraySize(Tab()) + 1) * 8, Crc)
EndProcedure

; Somme de contrôle rangée à la fin de l'état (-2 si elle ne peut pas être lue)
Procedure.q LireControleEtat(Fichier.q)
  If Fichier = 0
    ProcedureReturn -2
  EndIf
  If Loc(Fichier) + 8 > Lof(Fichier)
    ProcedureReturn -2
  EndIf
  ProcedureReturn ReadQuad(Fichier)
EndProcedure

Procedure EcrireControleEtat(Fichier.q, Crc.q)
  If Crc < 0 Or Fichier = 0
    EcritureEtatRatee = #True
  ElseIf WriteQuad(Fichier, Crc) = 0
    EcritureEtatRatee = #True
  EndIf
EndProcedure

; L'état lu ne correspond pas à sa somme de contrôle: la méthode v4 repart du
; texte de référence, et le fichier sera effacé à la fin de l'opération
Procedure SignalerEtatAbime()
  EtatAbime = #True
EndProcedure


; ----------------------------------------------------------------------------
;  Travail en parallèle pendant la compression (voir MutexCM4):
;  - la compression publie, tous les 4 096 octets lus, le nombre d'octets
;    compressés déjà produits (et met à jour la barre de progression) ;
;  - le second thread (VerifierCM4) attend qu'un octet soit produit avant de le
;    lire. Quand la compression est finie, il lit 0 au-delà de la fin, comme
;    DecoderCM4.
; ----------------------------------------------------------------------------
Procedure AvancementCM4(Position.q, Produits.q)
  If ParalleleActif
    LockMutex(MutexCM4)
    OctetsPublies = Produits
    UnlockMutex(MutexCM4)
  EndIf
  ProgressionCM(Position)
EndProcedure

Procedure.q AttendreOctets(Position.q)
  Protected.q Dispo
  Protected Fini

  Repeat
    LockMutex(MutexCM4)
    Dispo = OctetsPublies
    Fini = EncodageFini
    UnlockMutex(MutexCM4)
    If Position < Dispo Or Fini
      ProcedureReturn Dispo
    EndIf
    Delay(1)
  ForEver
EndProcedure


; ----------------------------------------------------------------------------
;  Méthode "Maximal": décompresseur par mélange de contextes.
;  Le CORPS de cette procédure est, ligne pour ligne, le texte qui est écrit
;  dans les lanceurs auto-extractibles. Tout est en entiers 64 bits (.q),
;  sans aucun débordement possible: résultat identique sur tous les PC.
;  *C = octets compressés (Z octets), *D = sortie (T octets).
;  Renvoie la somme de contrôle du code décompressé.
; ----------------------------------------------------------------------------
DisableDebugger
Procedure.q DecoderCM(*C, Z.q, T.q, *D)
  Protected.q i, u, v, x, ip, k, x1, x2, wh, ls, pl, ml, mp, chk, pos, h, hm, ab, ma, c0, j, ws, dot, pb, e, pm, px, s, aw, ai, xm, y, er, g, c

  Dim T33.q(32)
  Restore Sq33
  For i = 0 To 32
    Read.q u
    T33(i) = u
  Next
  Dim Sq.q(4094)
  For i = 0 To 4094
    u = (i + 1) % 128
    v = (i + 1) / 128
    Sq(i) = ((T33(v) * (128 - u)) + (T33(v + 1) * u) + 64) / 128
  Next
  Dim St.q(4095)
  v = 0
  For i = 0 To 4094
    While v <= Sq(i)
      St(v) = i - 2047
      v = v + 1
    Wend
  Next
  While v <= 4095
    St(v) = 2047
    v = v + 1
  Wend
  Dim Kr.q(255)
  For i = 0 To 255
    Kr(i) = 8192 / ((2 * i) + 3)
  Next
  Dim P2.q(8)
  P2(0) = 1
  For i = 1 To 8
    P2(i) = P2(i - 1) * 2
  Next
  Dim M.l(12582911)
  For i = 0 To 12582911
    M(i) = 8388608
  Next
  Dim MT.l(1048575)
  Dim MS.q(63)
  For i = 0 To 63
    MS(i) = 8388608
  Next
  Dim W.q(2047)
  For i = 0 To 2047
    W(i) = 16384
  Next
  Dim Ap.q(2162687)
  For i = 0 To 2162687
    u = ((i % 33) * 128) - 1
    If u < 0: u = 0: EndIf
    If u > 4094: u = 4094: EndIf
    Ap(i) = Sq(u) * 16
  Next
  Dim Hi.q(4)
  Dim Hc.q(5)
  Dim Ix.q(6)
  Dim Sv.q(6)
  x = 0: ip = 0
  For k = 1 To 4
    x = x * 256
    If ip < Z: x = x + PeekA(*C + ip): EndIf
    ip = ip + 1
  Next
  x1 = 0: x2 = 4294967295: wh = 0: ls = 0: pl = 0: ml = 0: mp = 0: chk = 0
  For pos = 0 To T - 1
    h = 0
    For k = 0 To 4
      h = ((((h + Hi(k)) + 1) * $6F4F2B) / 256) % $1000000
      If k < 4: Hc(k) = h: EndIf
    Next
    hm = h % $100000
    Hc(4) = (((((wh * 256) + Hi(0)) + 1) * $6F4F2B) / 256) % $1000000
    ab = 0
    If pl + pos - ls < ls: ab = PeekA(*D + pl + pos - ls): EndIf
    Hc(5) = (((((ab * 256) + Hi(0)) + 1048577) * $6F4F2B) / 256) % $1000000
    If ml > 0 And PeekA(*D + mp) = Hi(0)
      If ml < 65535: ml = ml + 1: EndIf
      mp = mp + 1
    Else
      ml = 0
    EndIf
    If ml = 0 And pos >= 5
      mp = MT(hm)
      While mp > 0 And ml < 124 And ml < mp
        If PeekA(*D + mp - ml - 1) <> PeekA(*D + pos - ml - 1): Break: EndIf
        ml = ml + 1
      Wend
    EndIf
    MT(hm) = pos
    ma = Bool(ml > 0)
    c0 = 1
    For j = 0 To 7
      ws = c0 * 8
      dot = 0
      For k = 0 To 5
        Ix(k) = (((((((Hc(k) * 256) + c0) * $2E8BA3) / 1024) % $200000)) + (k * $200000))
        Sv(k) = St(M(Ix(k)) / 4096)
        dot = dot + (W(ws + k) * Sv(k))
      Next
      Sv(6) = 0
      If ma
        pb = PeekA(*D + mp) + 256
        If pb / P2(8 - j) = c0
          u = ml
          If u > 31: u = 31: EndIf
          Ix(6) = (u * 2) + ((pb / P2(7 - j)) % 2)
          Sv(6) = St(MS(Ix(6)) / 4096)
        Else
          ma = 0
        EndIf
      EndIf
      dot = dot + (W(ws + 6) * 256) + (W(ws + 7) * Sv(6))
      e = dot / 65536
      If e > 2047: e = 2047: EndIf
      If e < -2047: e = -2047: EndIf
      pm = Sq(e + 2047)
      px = pm
      s = St(pm) + 2048
      aw = s % 128
      ai = (((Hi(0) * 256) + c0) * 33) + (s / 128)
      pm = (pm + (3 * (((Ap(ai) * (128 - aw)) + (Ap(ai + 1) * aw)) / 2048))) / 4
      If pm < 1: pm = 1: EndIf
      If pm > 4095: pm = 4095: EndIf
      xm = x1 + (((x2 - x1) / 4096) * pm)
      y = Bool(x <= xm)
      If y: x2 = xm: Else: x1 = xm + 1: EndIf
      er = ((y * 4096) - px) * 2
      For k = 0 To 5
        W(ws + k) = W(ws + k) + ((Sv(k) * er) / 1024)
        u = M(Ix(k)) / 256
        v = M(Ix(k)) % 256
        If y: u = u + (((65536 - u) * Kr(v)) / 4096): Else: u = u - ((u * Kr(v)) / 4096): EndIf
        If v < 127: v = v + 1: EndIf
        M(Ix(k)) = (u * 256) + v
      Next
      W(ws + 6) = W(ws + 6) + ((256 * er) / 1024)
      W(ws + 7) = W(ws + 7) + ((Sv(6) * er) / 1024)
      If ma
        u = MS(Ix(6)) / 256
        v = MS(Ix(6)) % 256
        If y: u = u + (((65536 - u) * Kr(v)) / 4096): Else: u = u - ((u * Kr(v)) / 4096): EndIf
        If v < 127: v = v + 1: EndIf
        MS(Ix(6)) = (u * 256) + v
      EndIf
      g = (y * 65536) + (y * 64) - (2 * y)
      Ap(ai) = Ap(ai) + (((g - Ap(ai)) * (128 - aw)) / 8192)
      Ap(ai + 1) = Ap(ai + 1) + (((g - Ap(ai + 1)) * aw) / 8192)
      c0 = (c0 * 2) + y
      While x1 / 16777216 = x2 / 16777216
        x1 = (x1 % 16777216) * 256
        x2 = ((x2 % 16777216) * 256) + 255
        x = (x % 16777216) * 256
        If ip < Z: x = x + PeekA(*C + ip): EndIf
        ip = ip + 1
      Wend
    Next
    c = c0 - 256
    PokeA(*D + pos, c)
    chk = ((chk * 33) + c) % 1000000007
    For k = 4 To 1 Step -1
      Hi(k) = Hi(k - 1)
    Next
    Hi(0) = c
    If c = 10: pl = ls: ls = pos + 1: EndIf
    If (c >= 48 And c <= 57) Or (c >= 65 And c <= 90) Or (c >= 97 And c <= 122) Or c = 95
      wh = ((((wh + c) + 1) * $6F4F2B) / 256) % $1000000
    Else
      wh = 0
    EndIf
  Next

  ProcedureReturn chk
EndProcedure
EnableDebugger


; ----------------------------------------------------------------------------
;  Méthode "Maximal" version 2 (format PBC2): même principe, avec un second
;  mélangeur et le texte de référence lu avant les données.
;  *D contient le texte de référence (P octets) suivi de la place pour T octets.
; ----------------------------------------------------------------------------
DisableDebugger
Procedure.q DecoderCM2(*C, Z.q, T.q, *D, P.q)
  Protected.q i, u, v, x, ip, k, x1, x2, wh, ls, pl, ml, mp, chk, pos, h, hm, ab, ma, c, c0, j, ws, dot, pb, wi, dw, e, r1, r2, pm, s, aw, ai, xm, y, er, e2, g

  Dim T33.q(32)
  Restore Sq33
  For i = 0 To 32
    Read.q u
    T33(i) = u
  Next
  Dim Sq.q(4094)
  For i = 0 To 4094
    u = (i + 1) % 128
    v = (i + 1) / 128
    Sq(i) = ((T33(v) * (128 - u)) + (T33(v + 1) * u) + 64) / 128
  Next
  Dim St.q(4095)
  v = 0
  For i = 0 To 4094
    While v <= Sq(i)
      St(v) = i - 2047
      v = v + 1
    Wend
  Next
  While v <= 4095
    St(v) = 2047
    v = v + 1
  Wend
  Dim Kr.q(255)
  For i = 0 To 255
    Kr(i) = 8192 / ((2 * i) + 3)
  Next
  Dim P2.q(8)
  P2(0) = 1
  For i = 1 To 8
    P2(i) = P2(i - 1) * 2
  Next
  Dim M.l(12582911)
  For i = 0 To 12582911
    M(i) = 8388608
  Next
  Dim MT.l(1048575)
  Dim MS.q(63)
  For i = 0 To 63
    MS(i) = 8388608
  Next
  Dim W.q(2047)
  For i = 0 To 2047
    W(i) = 16384
  Next
  Dim Wx.q(255)
  For i = 0 To 255
    Wx(i) = 16384
  Next
  Dim Ap.q(2162687)
  For i = 0 To 2162687
    u = ((i % 33) * 128) - 1
    If u < 0: u = 0: EndIf
    If u > 4094: u = 4094: EndIf
    Ap(i) = Sq(u) * 16
  Next
  Dim Hi.q(4)
  Dim Hc.q(5)
  Dim Ix.q(6)
  Dim Sv.q(6)
  x = 0: ip = 0
  For k = 1 To 4
    x = x * 256
    If ip < Z: x = x + PeekA(*C + ip): EndIf
    ip = ip + 1
  Next
  x1 = 0: x2 = 4294967295: wh = 0: ls = 0: pl = 0: ml = 0: mp = 0: chk = 0
  For pos = 0 To P + T - 1
    h = 0
    For k = 0 To 4
      h = ((((h + Hi(k)) + 1) * $6F4F2B) / 256) % $1000000
      If k < 4: Hc(k) = h: EndIf
    Next
    hm = h % $100000
    Hc(4) = (((((wh * 256) + Hi(0)) + 1) * $6F4F2B) / 256) % $1000000
    ab = 0
    If pl + pos - ls < ls: ab = PeekA(*D + pl + pos - ls): EndIf
    Hc(5) = (((((ab * 256) + Hi(0)) + 1048577) * $6F4F2B) / 256) % $1000000
    If ml > 0 And PeekA(*D + mp) = Hi(0)
      If ml < 65535: ml = ml + 1: EndIf
      mp = mp + 1
    Else
      ml = 0
    EndIf
    If ml = 0 And pos >= 5
      mp = MT(hm)
      While mp > 0 And ml < 124 And ml < mp
        If PeekA(*D + mp - ml - 1) <> PeekA(*D + pos - ml - 1): Break: EndIf
        ml = ml + 1
      Wend
    EndIf
    MT(hm) = pos
    ma = Bool(ml > 0)
    c = PeekA(*D + pos)
    c0 = 1
    For j = 0 To 7
      ws = c0 * 8
      dot = 0
      For k = 0 To 5
        Ix(k) = (((((((Hc(k) * 256) + c0) * $2E8BA3) / 1024) % $200000)) + (k * $200000))
        Sv(k) = St(M(Ix(k)) / 4096)
        dot = dot + (W(ws + k) * Sv(k))
      Next
      Sv(6) = 0
      If ma
        pb = PeekA(*D + mp) + 256
        If pb / P2(8 - j) = c0
          u = ml
          If u > 31: u = 31: EndIf
          Ix(6) = (u * 2) + ((pb / P2(7 - j)) % 2)
          Sv(6) = St(MS(Ix(6)) / 4096)
        Else
          ma = 0
        EndIf
      EndIf
      u = ml
      If u > 15: u = 15: EndIf
      wi = ((u * 2) + ma) * 8
      dw = 0
      For k = 0 To 5
        dw = dw + (Wx(wi + k) * Sv(k))
      Next
      dot = dot + (W(ws + 6) * 256) + (W(ws + 7) * Sv(6))
      dw = dw + (Wx(wi + 6) * 256) + (Wx(wi + 7) * Sv(6))
      e = dot / 65536
      If e > 2047: e = 2047: EndIf
      If e < -2047: e = -2047: EndIf
      r1 = Sq(e + 2047)
      e = dw / 65536
      If e > 2047: e = 2047: EndIf
      If e < -2047: e = -2047: EndIf
      r2 = Sq(e + 2047)
      pm = Sq(((St(r1) + St(r2)) / 2) + 2047)
      s = St(pm) + 2048
      aw = s % 128
      ai = (((Hi(0) * 256) + c0) * 33) + (s / 128)
      pm = (pm + (3 * (((Ap(ai) * (128 - aw)) + (Ap(ai + 1) * aw)) / 2048))) / 4
      If pm < 1: pm = 1: EndIf
      If pm > 4095: pm = 4095: EndIf
      If pos >= P
        xm = x1 + (((x2 - x1) / 4096) * pm)
        y = Bool(x <= xm)
        If y: x2 = xm: Else: x1 = xm + 1: EndIf
      Else
        y = (c / P2(7 - j)) % 2
      EndIf
      er = ((y * 4096) - r1) * 2
      e2 = ((y * 4096) - r2) * 2
      For k = 0 To 5
        W(ws + k) = W(ws + k) + ((Sv(k) * er) / 1024)
        Wx(wi + k) = Wx(wi + k) + ((Sv(k) * e2) / 1024)
        u = M(Ix(k)) / 256
        v = M(Ix(k)) % 256
        If y: u = u + (((65536 - u) * Kr(v)) / 4096): Else: u = u - ((u * Kr(v)) / 4096): EndIf
        If v < 127: v = v + 1: EndIf
        M(Ix(k)) = (u * 256) + v
      Next
      W(ws + 6) = W(ws + 6) + ((256 * er) / 1024)
      W(ws + 7) = W(ws + 7) + ((Sv(6) * er) / 1024)
      Wx(wi + 6) = Wx(wi + 6) + ((256 * e2) / 1024)
      Wx(wi + 7) = Wx(wi + 7) + ((Sv(6) * e2) / 1024)
      If ma
        u = MS(Ix(6)) / 256
        v = MS(Ix(6)) % 256
        If y: u = u + (((65536 - u) * Kr(v)) / 4096): Else: u = u - ((u * Kr(v)) / 4096): EndIf
        If v < 127: v = v + 1: EndIf
        MS(Ix(6)) = (u * 256) + v
      EndIf
      g = (y * 65536) + (y * 64) - (2 * y)
      Ap(ai) = Ap(ai) + (((g - Ap(ai)) * (128 - aw)) / 8192)
      Ap(ai + 1) = Ap(ai + 1) + (((g - Ap(ai + 1)) * aw) / 8192)
      c0 = (c0 * 2) + y
      While x1 / 16777216 = x2 / 16777216
        x1 = (x1 % 16777216) * 256
        x2 = ((x2 % 16777216) * 256) + 255
        x = (x % 16777216) * 256
        If ip < Z: x = x + PeekA(*C + ip): EndIf
        ip = ip + 1
      Wend
    Next
    c = c0 - 256
    PokeA(*D + pos, c)
    If pos >= P: chk = ((chk * 33) + c) % 1000000007: EndIf
    For k = 4 To 1 Step -1
      Hi(k) = Hi(k - 1)
    Next
    Hi(0) = c
    If c = 10: pl = ls: ls = pos + 1: EndIf
    If (c >= 48 And c <= 57) Or (c >= 65 And c <= 90) Or (c >= 97 And c <= 122) Or c = 95
      wh = ((((wh + c) + 1) * $6F4F2B) / 256) % $1000000
    Else
      wh = 0
    EndIf
  Next

  ProcedureReturn chk
EndProcedure
EnableDebugger


; ----------------------------------------------------------------------------
;  Méthode "Maximal" version 3 (format PBC3, depuis la v6.0): même principe,
;  avec en plus:
;  - une mémoire des derniers bits vus dans chaque contexte (Bh), traduite en
;    probabilité par une table qui apprend (SM) ;
;  - trois contextes de plus: les 8 derniers caractères, le premier mot de
;    la ligne, l'indentation ;
;  - un contrôle des collisions dans les tables (Kc) ;
;  - un troisième mélangeur, qui sait si on est dans du code, dans un texte
;    entre guillemets ou dans un commentaire, et un étage final qui combine
;    les trois mélangeurs ;
;  - une recherche des passages répétés sur 8 caractères avant 5.
;  Mémoire utilisée: environ 130 Mo. Tout reste en entiers 64 bits (.q),
;  sans débordement possible: résultat identique sur tous les PC.
;  *D contient le texte de référence (P octets) suivi de la place pour T octets.
; ----------------------------------------------------------------------------
DisableDebugger
Procedure.q DecoderCM3(*C, Z.q, T.q, *D, P.q)
  Protected.q i, u, v, x, ip, k, x1, x2, wh, ls, pl, ml, mp, chk, fw, fwf, nd, zn, pos, h, hm, ab, h8, ma, c, c0, j, ws, ck, pb, im, wi, wn, dot, dw, dy, e, r1, r2, r3, f, pf, pm, s, aw, ai, xm, y, er, e2, e3, hb, si, n0, n1, hh, g, ef, lt

  Dim T33.q(32)
  Restore Sq33
  For i = 0 To 32
    Read.q u
    T33(i) = u
  Next
  Dim Sq.q(4094)
  For i = 0 To 4094
    u = (i + 1) % 128
    v = (i + 1) / 128
    Sq(i) = ((T33(v) * (128 - u)) + (T33(v + 1) * u) + 64) / 128
  Next
  Dim St.q(4095)
  v = 0
  For i = 0 To 4094
    While v <= Sq(i)
      St(v) = i - 2047
      v = v + 1
    Wend
  Next
  While v <= 4095
    St(v) = 2047
    v = v + 1
  Wend
  Dim Kr.q(255)
  For i = 0 To 255
    Kr(i) = 8192 / ((2 * i) + 3)
  Next
  Dim P2.q(8)
  P2(0) = 1
  For i = 1 To 8
    P2(i) = P2(i - 1) * 2
  Next
  Dim M.l(18874367)
  For i = 0 To 18874367
    M(i) = 8388608
  Next
  Dim Bh.a(18874367)
  Dim Kc.a(18874367)
  Dim SM.q(18431)
  For i = 0 To 18431
    SM(i) = 8388608
  Next
  Dim MT.l(1048575)
  Dim MT2.l(1048575)
  Dim MS.q(63)
  For i = 0 To 63
    MS(i) = 8388608
  Next
  Dim W.q(5119)
  For i = 0 To 5119
    W(i) = 6553
  Next
  Dim Wx.q(639)
  For i = 0 To 639
    Wx(i) = 6553
  Next
  Dim Wc.q(15359)
  For i = 0 To 15359
    Wc(i) = 6553
  Next
  Dim Wf.q(319)
  For i = 0 To 319
    If i % 5 = 3: Wf(i) = 0: Else: Wf(i) = 21845: EndIf
  Next
  Dim Ap.q(2162687)
  For i = 0 To 2162687
    u = ((i % 33) * 128) - 1
    If u < 0: u = 0: EndIf
    If u > 4094: u = 4094: EndIf
    Ap(i) = Sq(u) * 16
  Next
  Dim Hi.q(7)
  Dim Hc.q(8)
  Dim Ix.q(8)
  Dim Sv.q(19)
  x = 0: ip = 0
  For k = 1 To 4
    x = x * 256
    If ip < Z: x = x + PeekA(*C + ip): EndIf
    ip = ip + 1
  Next
  x1 = 0: x2 = 4294967295: wh = 0: ls = 0: pl = 0: ml = 0: mp = 0: chk = 0
  fw = 0: fwf = 0: nd = 0: zn = 0
  For pos = 0 To P + T - 1
    If pos % 4096 = 0: ProgressionCM(pos): EndIf
    h = 0
    For k = 0 To 4
      h = ((((h + Hi(k)) + 1) * $6F4F2B) / 256) % $1000000
      If k < 4: Hc(k) = h: EndIf
    Next
    hm = h % $100000
    Hc(4) = (((((wh * 256) + Hi(0)) + 1) * $6F4F2B) / 256) % $1000000
    ab = 0
    If pl + pos - ls < ls: ab = PeekA(*D + pl + pos - ls): EndIf
    Hc(5) = (((((ab * 256) + Hi(0)) + 1048577) * $6F4F2B) / 256) % $1000000
    For k = 5 To 7
      h = ((((h + Hi(k)) + 1) * $6F4F2B) / 256) % $1000000
    Next
    h8 = h
    Hc(6) = h8
    u = (((((fw * 256) + (wh % 256)) + 1) * $6F4F2B) / 256) % $1000000
    u = (((((u * 256) + ((wh / 256) % 256)) + 1) * $6F4F2B) / 256) % $1000000
    u = (((((u * 256) + (wh / 65536)) + 1) * $6F4F2B) / 256) % $1000000
    Hc(7) = (((((u * 256) + 3) + 1) * $6F4F2B) / 256) % $1000000
    u = (((((nd * 256) + Hi(1)) + 1) * $6F4F2B) / 256) % $1000000
    u = (((((u * 256) + Hi(0)) + 1) * $6F4F2B) / 256) % $1000000
    u = (((((u * 256) + 0) + 1) * $6F4F2B) / 256) % $1000000
    Hc(8) = (((((u * 256) + 4) + 1) * $6F4F2B) / 256) % $1000000
    If ml > 0 And PeekA(*D + mp) = Hi(0)
      If ml < 65535: ml = ml + 1: EndIf
      mp = mp + 1
    Else
      ml = 0
    EndIf
    If ml = 0 And pos >= 8
      mp = MT2(h8 % $100000)
      While mp > 0 And ml < 124 And ml < mp
        If PeekA(*D + mp - ml - 1) <> PeekA(*D + pos - ml - 1): Break: EndIf
        ml = ml + 1
      Wend
    EndIf
    If ml = 0 And pos >= 5
      mp = MT(hm)
      While mp > 0 And ml < 124 And ml < mp
        If PeekA(*D + mp - ml - 1) <> PeekA(*D + pos - ml - 1): Break: EndIf
        ml = ml + 1
      Wend
    EndIf
    MT(hm) = pos
    MT2(h8 % $100000) = pos
    ma = Bool(ml > 0)
    c = PeekA(*D + pos)
    c0 = 1
    For j = 0 To 7
      ws = c0 * 20
      For k = 0 To 8
        Ix(k) = (((((Hc(k) * 256) + c0) * $2E8BA3) / 1024) % $200000) + (k * $200000)
        ck = ((((Hc(k) * 256) + c0) / 4096) % 255) + 1
        If Kc(Ix(k)) <> ck
          Kc(Ix(k)) = ck
          M(Ix(k)) = 8388608
          Bh(Ix(k)) = 0
        EndIf
        Sv(k * 2) = St(M(Ix(k)) / 4096)
        Sv((k * 2) + 1) = St(SM((k * 2048) + Bh(Ix(k)) + (256 * j)) / 4096)
      Next
      Sv(18) = 256
      Sv(19) = 0
      If ma
        pb = PeekA(*D + mp) + 256
        If pb / P2(8 - j) = c0
          u = ml
          If u > 31: u = 31: EndIf
          im = (u * 2) + ((pb / P2(7 - j)) % 2)
          Sv(19) = St(MS(im) / 4096)
        Else
          ma = 0
        EndIf
      EndIf
      u = ml
      If u > 15: u = 15: EndIf
      wi = ((u * 2) + ma) * 20
      wn = ((zn * 256) + Hi(0)) * 20
      dot = 0: dw = 0: dy = 0
      For k = 0 To 19
        dot = dot + (W(ws + k) * Sv(k))
        dw = dw + (Wx(wi + k) * Sv(k))
        dy = dy + (Wc(wn + k) * Sv(k))
      Next
      e = dot / 65536
      If e > 2047: e = 2047: EndIf
      If e < -2047: e = -2047: EndIf
      r1 = Sq(e + 2047)
      e = dw / 65536
      If e > 2047: e = 2047: EndIf
      If e < -2047: e = -2047: EndIf
      r2 = Sq(e + 2047)
      e = dy / 65536
      If e > 2047: e = 2047: EndIf
      If e < -2047: e = -2047: EndIf
      r3 = Sq(e + 2047)
      f = ((j * 2) + ma) * 5
      pf = (Wf(f) * St(r1)) + (Wf(f + 1) * St(r2)) + (Wf(f + 2) * St(r3)) + (Wf(f + 3) * 256)
      e = pf / 65536
      If e > 2047: e = 2047: EndIf
      If e < -2047: e = -2047: EndIf
      pm = Sq(e + 2047)
      pf = pm
      s = St(pm) + 2048
      aw = s % 128
      ai = (((Hi(0) * 256) + c0) * 33) + (s / 128)
      pm = (pm + (3 * (((Ap(ai) * (128 - aw)) + (Ap(ai + 1) * aw)) / 2048))) / 4
      If pm < 1: pm = 1: EndIf
      If pm > 4095: pm = 4095: EndIf
      If pos >= P
        xm = x1 + (((x2 - x1) / 4096) * pm)
        y = Bool(x <= xm)
        If y: x2 = xm: Else: x1 = xm + 1: EndIf
      Else
        y = (c / P2(7 - j)) % 2
      EndIf
      er = ((y * 4096) - r1) * 2
      e2 = ((y * 4096) - r2) * 2
      e3 = ((y * 4096) - r3) * 2
      For k = 0 To 19
        W(ws + k) = W(ws + k) + ((Sv(k) * er) / 4096)
        Wx(wi + k) = Wx(wi + k) + ((Sv(k) * e2) / 4096)
        Wc(wn + k) = Wc(wn + k) + ((Sv(k) * e3) / 4096)
      Next
      For k = 0 To 8
        hb = Bh(Ix(k))
        si = (k * 2048) + hb + (256 * j)
        u = SM(si) / 256
        v = SM(si) % 256
        If y: u = u + (((65536 - u) * Kr(v)) / 4096): Else: u = u - ((u * Kr(v)) / 4096): EndIf
        If v < 127: v = v + 1: EndIf
        SM(si) = (u * 256) + v
        n0 = hb % 8
        n1 = (hb / 8) % 8
        hh = hb / 64
        If y
          If n1 < 7: n1 = n1 + 1: EndIf
          If n0 > 2: n0 = (n0 / 2) + 1: EndIf
        Else
          If n0 < 7: n0 = n0 + 1: EndIf
          If n1 > 2: n1 = (n1 / 2) + 1: EndIf
        EndIf
        Bh(Ix(k)) = n0 + (n1 * 8) + ((((hh * 2) + y) % 4) * 64)
        u = M(Ix(k)) / 256
        v = M(Ix(k)) % 256
        If y: u = u + (((65536 - u) * Kr(v)) / 4096): Else: u = u - ((u * Kr(v)) / 4096): EndIf
        If v < 127: v = v + 1: EndIf
        M(Ix(k)) = (u * 256) + v
      Next
      If ma
        u = MS(im) / 256
        v = MS(im) % 256
        If y: u = u + (((65536 - u) * Kr(v)) / 4096): Else: u = u - ((u * Kr(v)) / 4096): EndIf
        If v < 127: v = v + 1: EndIf
        MS(im) = (u * 256) + v
      EndIf
      g = (y * 65536) + (y * 64) - (2 * y)
      Ap(ai) = Ap(ai) + (((g - Ap(ai)) * (128 - aw)) / 8192)
      Ap(ai + 1) = Ap(ai + 1) + (((g - Ap(ai + 1)) * aw) / 8192)
      ef = ((y * 4096) - pf) * 2
      Wf(f) = Wf(f) + ((St(r1) * ef) / 16384)
      Wf(f + 1) = Wf(f + 1) + ((St(r2) * ef) / 16384)
      Wf(f + 2) = Wf(f + 2) + ((St(r3) * ef) / 16384)
      Wf(f + 3) = Wf(f + 3) + ((256 * ef) / 16384)
      c0 = (c0 * 2) + y
      While x1 / 16777216 = x2 / 16777216
        x1 = (x1 % 16777216) * 256
        x2 = ((x2 % 16777216) * 256) + 255
        x = (x % 16777216) * 256
        If ip < Z: x = x + PeekA(*C + ip): EndIf
        ip = ip + 1
      Wend
    Next
    c = c0 - 256
    PokeA(*D + pos, c)
    If pos >= P: chk = ((chk * 33) + c) % 1000000007: EndIf
    For k = 7 To 1 Step -1
      Hi(k) = Hi(k - 1)
    Next
    Hi(0) = c
    If c = 10
      pl = ls: ls = pos + 1: fw = 0: fwf = 0: nd = 0
    EndIf
    lt = 0
    If (c >= 48 And c <= 57) Or (c >= 65 And c <= 90) Or (c >= 97 And c <= 122) Or c = 95: lt = 1: EndIf
    If lt
      wh = ((((wh + c) + 1) * $6F4F2B) / 256) % $1000000
    Else
      wh = 0
    EndIf
    If c = 32 And fwf = 0 And fw = 0: nd = nd + 1: EndIf
    If fwf = 0
      If lt
        fw = (((((fw * 256) + c) + 1) * $6F4F2B) / 256) % $1000000
      ElseIf fw > 0
        fwf = 1
      EndIf
    EndIf
    If zn = 0
      If c = 59
        zn = 2
      ElseIf c = 34
        zn = 1
      EndIf
    ElseIf zn = 1
      If c = 34 Or c = 10: zn = 0: EndIf
    ElseIf c = 10
      zn = 0
    EndIf
  Next

  ProcedureReturn chk
EndProcedure
EnableDebugger


; ----------------------------------------------------------------------------
;  Méthode "Maximal" version 4 (format PBC4, depuis la v6.1): compression
;  maximale, sans souci du temps ni de la mémoire. Même principe que la v3,
;  avec:
;  - 24 contextes au lieu de 9: en plus, les deux derniers mots, le mot
;    précédent sur la ligne, le premier mot de la ligne précédente, les
;    caractères situés au-dessus (une et deux lignes plus haut), la ligne
;    précédente qui commençait par le même mot, la profondeur des
;    parenthèses, la position dans la ligne (colonne, nombre de mots), ce qui
;    a suivi les mêmes caractères la dernière fois, le caractère prévu par le
;    passage répété ;
;  - cinq mélangeurs au lieu de trois, et deux corrections finales (APM) ;
;  - une recherche des passages répétés sur 16, puis 8, puis 5 caractères ;
;  - des tables 4 fois plus grandes (2^22 cases par contexte).
;  Texte de référence: de 53 Ko à 11 Mo selon le niveau (*Reference), relu
;  en entier à chaque compression ou décompression avant les données, sauf si
;  l'état du modèle est relu depuis le disque (EtatLu, depuis la v6.3).
;  EtatLu / EtatEcrit: fichier d'état à lire avant, ou à écrire à la fin du
;  texte de référence (0 = aucun). Le calcul du modèle lui-même est inchangé.
;  Mémoire utilisée: environ 650 Mo. Tout reste en entiers 64 bits (.q),
;  sans débordement possible: résultat identique sur tous les PC.
;  *D contient le texte de référence (P octets) suivi de la place pour T octets.
; ----------------------------------------------------------------------------
DisableDebugger
Procedure.q DecoderCM4(*C, Z.q, T.q, *D, P.q, EtatLu.q, EtatEcrit.q)
  Protected.q i, u, v, charge, crc, x, ip, k, x1, x2, ml, mp, ma, chk, wh, wp, wc, fw, fwf, pfw, nd, bd, tk, zn, ls, pl, ppl, Debut, h0, h, hm, h8, ab, u2, ab2, a, a1, a2, sr, sf, a3, h16, b, c, c0, j, ws, ck, pb, im, wi, wn, wz, wv, dot, dw, dy, dz, dv, e, r1, r2, r3, r4, r5, f, pf, pm, s, aw, ai, pa, ai2, pa2, xm, y, er, e2, e3, e4, e5, hb, si, n0, n1, hh, g, ef, lt, l1, pos

  Dim T33.q(32)
  Restore Sq33
  For i = 0 To 32
    Read.q u
    T33(i) = u
  Next
  Dim Sq.q(4094)
  For i = 0 To 4094
    u = (i + 1) % 128
    v = (i + 1) / 128
    Sq(i) = ((T33(v) * (128 - u)) + (T33(v + 1) * u) + 64) / 128
  Next
  Dim St.q(4095)
  v = 0
  For i = 0 To 4094
    While v <= Sq(i)
      St(v) = i - 2047
      v = v + 1
    Wend
  Next
  While v <= 4095
    St(v) = 2047
    v = v + 1
  Wend
  Dim Kr.q(255)
  For i = 0 To 255
    Kr(i) = 8192 / ((2 * i) + 3)
  Next
  Dim P2.q(8)
  P2(0) = 1
  For i = 1 To 8
    P2(i) = P2(i - 1) * 2
  Next
  Dim M.l(100663295)
  Dim Bh.a(100663295)
  Dim Kc.a(100663295)
  Dim SM.q(1572863)
  Dim MT.l(1048575)
  Dim MT2.l(1048575)
  Dim MT3.l(1048575)
  Dim MS.q(63)
  Dim W.q(12799)
  Dim Wx.q(1599)
  Dim Wc.q(38399)
  Dim Wz.q(12799)
  Dim Wv.q(12799)
  Dim Wf.q(383)
  Dim Ap.q(2162687)
  Dim Ap2.q(2162687)
  Dim I1.q(255)
  Dim I2.q(65535)
  Dim LF.q(65535)
  Dim LE.q(65535)
  Dim Hi.q(7)
  Dim Hc.q(23)
  Dim Ix.q(23)
  Dim Sv.q(49)
  Dim Es.q(81)
  charge = 0
  If EtatLu <> 0
    crc = 0
    crc = EchangeTableauL(EtatLu, 0, M(), crc)
    crc = EchangeTableauA(EtatLu, 0, Bh(), crc)
    crc = EchangeTableauA(EtatLu, 0, Kc(), crc)
    crc = EchangeTableauQ(EtatLu, 0, SM(), crc)
    crc = EchangeTableauL(EtatLu, 0, MT(), crc)
    crc = EchangeTableauL(EtatLu, 0, MT2(), crc)
    crc = EchangeTableauL(EtatLu, 0, MT3(), crc)
    crc = EchangeTableauQ(EtatLu, 0, MS(), crc)
    crc = EchangeTableauQ(EtatLu, 0, W(), crc)
    crc = EchangeTableauQ(EtatLu, 0, Wx(), crc)
    crc = EchangeTableauQ(EtatLu, 0, Wc(), crc)
    crc = EchangeTableauQ(EtatLu, 0, Wz(), crc)
    crc = EchangeTableauQ(EtatLu, 0, Wv(), crc)
    crc = EchangeTableauQ(EtatLu, 0, Wf(), crc)
    crc = EchangeTableauQ(EtatLu, 0, Ap(), crc)
    crc = EchangeTableauQ(EtatLu, 0, Ap2(), crc)
    crc = EchangeTableauQ(EtatLu, 0, I1(), crc)
    crc = EchangeTableauQ(EtatLu, 0, I2(), crc)
    crc = EchangeTableauQ(EtatLu, 0, LF(), crc)
    crc = EchangeTableauQ(EtatLu, 0, LE(), crc)
    crc = EchangeTableauQ(EtatLu, 0, Hi(), crc)
    crc = EchangeTableauQ(EtatLu, 0, Hc(), crc)
    crc = EchangeTableauQ(EtatLu, 0, Ix(), crc)
    crc = EchangeTableauQ(EtatLu, 0, Sv(), crc)
    crc = EchangeTableauQ(EtatLu, 0, Es(), crc)
    If crc >= 0 And crc = LireControleEtat(EtatLu)
      charge = 1
    Else
      SignalerEtatAbime()
    EndIf
  EndIf
  If charge = 0
    If EtatLu <> 0
      Dim M.l(100663295)
      Dim Bh.a(100663295)
      Dim Kc.a(100663295)
      Dim SM.q(1572863)
      Dim MT.l(1048575)
      Dim MT2.l(1048575)
      Dim MT3.l(1048575)
      Dim MS.q(63)
      Dim W.q(12799)
      Dim Wx.q(1599)
      Dim Wc.q(38399)
      Dim Wz.q(12799)
      Dim Wv.q(12799)
      Dim Wf.q(383)
      Dim Ap.q(2162687)
      Dim Ap2.q(2162687)
      Dim I1.q(255)
      Dim I2.q(65535)
      Dim LF.q(65535)
      Dim LE.q(65535)
      Dim Hi.q(7)
      Dim Hc.q(23)
      Dim Ix.q(23)
      Dim Sv.q(49)
      Dim Es.q(81)
    EndIf
    For i = 0 To 100663295
      M(i) = 8388608
    Next
    For i = 0 To 1572863
      SM(i) = 8388608
    Next
    For i = 0 To 63
      MS(i) = 8388608
    Next
    For i = 0 To 12799
      W(i) = 2621
    Next
    For i = 0 To 1599
      Wx(i) = 2621
    Next
    For i = 0 To 38399
      Wc(i) = 2621
    Next
    For i = 0 To 12799
      Wz(i) = 2621
    Next
    For i = 0 To 12799
      Wv(i) = 2621
    Next
    For i = 0 To 383
      If i % 6 = 3: Wf(i) = 0: Else: Wf(i) = 13107: EndIf
    Next
    For i = 0 To 2162687
      u = ((i % 33) * 128) - 1
      If u < 0: u = 0: EndIf
      If u > 4094: u = 4094: EndIf
      Ap(i) = Sq(u) * 16
    Next
    For i = 0 To 2162687
      u = ((i % 33) * 128) - 1
      If u < 0: u = 0: EndIf
      If u > 4094: u = 4094: EndIf
      Ap2(i) = Sq(u) * 16
    Next
  EndIf
  x = 0: ip = 0
  For k = 1 To 4
    x = x * 256
    If ip < Z: x = x + PeekA(*C + ip): EndIf
    ip = ip + 1
  Next
  x1 = 0: x2 = 4294967295: ml = 0: mp = 0: ma = 0: chk = 0
  wh = 0: wp = 0: wc = 0: fw = 0: fwf = 0: pfw = 0: nd = 0: bd = 0: tk = 0: zn = 0
  ls = 0: pl = 0: ppl = 0
  Debut = 0
  If charge
    i = Es(0): u = Es(1): v = Es(2): ml = Es(3): mp = Es(4): ma = Es(5): wh = Es(6): wp = Es(7)
    wc = Es(8): fw = Es(9): fwf = Es(10): pfw = Es(11): nd = Es(12): bd = Es(13): tk = Es(14): zn = Es(15)
    ls = Es(16): pl = Es(17): ppl = Es(18): h0 = Es(19): h = Es(20): k = Es(21): hm = Es(22): h8 = Es(23)
    ab = Es(24): u2 = Es(25): ab2 = Es(26): a = Es(27): a1 = Es(28): a2 = Es(29): sr = Es(30): sf = Es(31)
    a3 = Es(32): h16 = Es(33): b = Es(34): c = Es(35): c0 = Es(36): j = Es(37): ws = Es(38): ck = Es(39)
    pb = Es(40): im = Es(41): wi = Es(42): wn = Es(43): wz = Es(44): wv = Es(45): dot = Es(46): dw = Es(47)
    dy = Es(48): dz = Es(49): dv = Es(50): e = Es(51): r1 = Es(52): r2 = Es(53): r3 = Es(54): r4 = Es(55)
    r5 = Es(56): f = Es(57): pf = Es(58): pm = Es(59): s = Es(60): aw = Es(61): ai = Es(62): pa = Es(63)
    ai2 = Es(64): pa2 = Es(65): xm = Es(66): y = Es(67): er = Es(68): e2 = Es(69): e3 = Es(70): e4 = Es(71)
    e5 = Es(72): hb = Es(73): si = Es(74): n0 = Es(75): n1 = Es(76): hh = Es(77): g = Es(78): ef = Es(79)
    lt = Es(80): l1 = Es(81)
    Debut = P
  EndIf
  For pos = Debut To P + T - 1
    If pos = P And EtatEcrit <> 0
      Es(0) = i: Es(1) = u: Es(2) = v: Es(3) = ml: Es(4) = mp: Es(5) = ma: Es(6) = wh: Es(7) = wp
      Es(8) = wc: Es(9) = fw: Es(10) = fwf: Es(11) = pfw: Es(12) = nd: Es(13) = bd: Es(14) = tk: Es(15) = zn
      Es(16) = ls: Es(17) = pl: Es(18) = ppl: Es(19) = h0: Es(20) = h: Es(21) = k: Es(22) = hm: Es(23) = h8
      Es(24) = ab: Es(25) = u2: Es(26) = ab2: Es(27) = a: Es(28) = a1: Es(29) = a2: Es(30) = sr: Es(31) = sf
      Es(32) = a3: Es(33) = h16: Es(34) = b: Es(35) = c: Es(36) = c0: Es(37) = j: Es(38) = ws: Es(39) = ck
      Es(40) = pb: Es(41) = im: Es(42) = wi: Es(43) = wn: Es(44) = wz: Es(45) = wv: Es(46) = dot: Es(47) = dw
      Es(48) = dy: Es(49) = dz: Es(50) = dv: Es(51) = e: Es(52) = r1: Es(53) = r2: Es(54) = r3: Es(55) = r4
      Es(56) = r5: Es(57) = f: Es(58) = pf: Es(59) = pm: Es(60) = s: Es(61) = aw: Es(62) = ai: Es(63) = pa
      Es(64) = ai2: Es(65) = pa2: Es(66) = xm: Es(67) = y: Es(68) = er: Es(69) = e2: Es(70) = e3: Es(71) = e4
      Es(72) = e5: Es(73) = hb: Es(74) = si: Es(75) = n0: Es(76) = n1: Es(77) = hh: Es(78) = g: Es(79) = ef
      Es(80) = lt: Es(81) = l1
      crc = 0
      crc = EchangeTableauL(EtatEcrit, 1, M(), crc)
      crc = EchangeTableauA(EtatEcrit, 1, Bh(), crc)
      crc = EchangeTableauA(EtatEcrit, 1, Kc(), crc)
      crc = EchangeTableauQ(EtatEcrit, 1, SM(), crc)
      crc = EchangeTableauL(EtatEcrit, 1, MT(), crc)
      crc = EchangeTableauL(EtatEcrit, 1, MT2(), crc)
      crc = EchangeTableauL(EtatEcrit, 1, MT3(), crc)
      crc = EchangeTableauQ(EtatEcrit, 1, MS(), crc)
      crc = EchangeTableauQ(EtatEcrit, 1, W(), crc)
      crc = EchangeTableauQ(EtatEcrit, 1, Wx(), crc)
      crc = EchangeTableauQ(EtatEcrit, 1, Wc(), crc)
      crc = EchangeTableauQ(EtatEcrit, 1, Wz(), crc)
      crc = EchangeTableauQ(EtatEcrit, 1, Wv(), crc)
      crc = EchangeTableauQ(EtatEcrit, 1, Wf(), crc)
      crc = EchangeTableauQ(EtatEcrit, 1, Ap(), crc)
      crc = EchangeTableauQ(EtatEcrit, 1, Ap2(), crc)
      crc = EchangeTableauQ(EtatEcrit, 1, I1(), crc)
      crc = EchangeTableauQ(EtatEcrit, 1, I2(), crc)
      crc = EchangeTableauQ(EtatEcrit, 1, LF(), crc)
      crc = EchangeTableauQ(EtatEcrit, 1, LE(), crc)
      crc = EchangeTableauQ(EtatEcrit, 1, Hi(), crc)
      crc = EchangeTableauQ(EtatEcrit, 1, Hc(), crc)
      crc = EchangeTableauQ(EtatEcrit, 1, Ix(), crc)
      crc = EchangeTableauQ(EtatEcrit, 1, Sv(), crc)
      crc = EchangeTableauQ(EtatEcrit, 1, Es(), crc)
      EcrireControleEtat(EtatEcrit, crc)
    EndIf
    If pos % 4096 = 0: ProgressionCM(pos): EndIf
    h0 = Hi(0)
    h = 0
    For k = 0 To 7
      h = ((((h + Hi(k)) + 1) * $6F4F2B) / 256) % $1000000
      If k < 4: Hc(k) = h: EndIf
      If k = 4: hm = h % $100000: EndIf
    Next
    h8 = h
    Hc(4) = (((((wh * 256) + h0) + 1) * $6F4F2B) / 256) % $1000000
    ab = 0
    If pl + pos - ls < ls: ab = PeekA(*D + pl + pos - ls): EndIf
    Hc(5) = (((((ab * 256) + h0) + 1048577) * $6F4F2B) / 256) % $1000000
    Hc(6) = h8
    u = (((((wh * 256) + (wp % 256)) + 1) * $6F4F2B) / 256) % $1000000
    u = (((((u * 256) + ((wp / 256) % 256)) + 1) * $6F4F2B) / 256) % $1000000
    u = (((((u * 256) + (wp / 65536)) + 1) * $6F4F2B) / 256) % $1000000
    Hc(7) = (((((u * 256) + (h0 + 2)) + 1) * $6F4F2B) / 256) % $1000000
    u = (((((fw * 256) + (wh % 256)) + 1) * $6F4F2B) / 256) % $1000000
    u = (((((u * 256) + ((wh / 256) % 256)) + 1) * $6F4F2B) / 256) % $1000000
    u = (((((u * 256) + (wh / 65536)) + 1) * $6F4F2B) / 256) % $1000000
    Hc(8) = (((((u * 256) + 3) + 1) * $6F4F2B) / 256) % $1000000
    u2 = u
    v = (h0 * 256) + Hi(1)
    u = (((((nd * 256) + (v % 256)) + 1) * $6F4F2B) / 256) % $1000000
    u = (((((u * 256) + ((v / 256) % 256)) + 1) * $6F4F2B) / 256) % $1000000
    u = (((((u * 256) + (v / 65536)) + 1) * $6F4F2B) / 256) % $1000000
    Hc(9) = (((((u * 256) + 4) + 1) * $6F4F2B) / 256) % $1000000
    u = (((((bd * 256) + (v % 256)) + 1) * $6F4F2B) / 256) % $1000000
    u = (((((u * 256) + ((v / 256) % 256)) + 1) * $6F4F2B) / 256) % $1000000
    u = (((((u * 256) + (v / 65536)) + 1) * $6F4F2B) / 256) % $1000000
    Hc(10) = (((((u * 256) + 6) + 1) * $6F4F2B) / 256) % $1000000
    ab2 = 0
    If pl + pos - ls + 1 < ls: ab2 = PeekA(*D + pl + pos - ls + 1): EndIf
    a = (ab * 256) + ab2
    u = (((((a * 256) + (h0 % 256)) + 1) * $6F4F2B) / 256) % $1000000
    u = (((((u * 256) + ((h0 / 256) % 256)) + 1) * $6F4F2B) / 256) % $1000000
    u = (((((u * 256) + (h0 / 65536)) + 1) * $6F4F2B) / 256) % $1000000
    Hc(11) = (((((u * 256) + 7) + 1) * $6F4F2B) / 256) % $1000000
    u = (((((pfw * 256) + (u2 % 256)) + 1) * $6F4F2B) / 256) % $1000000
    u = (((((u * 256) + ((u2 / 256) % 256)) + 1) * $6F4F2B) / 256) % $1000000
    u = (((((u * 256) + (u2 / 65536)) + 1) * $6F4F2B) / 256) % $1000000
    Hc(12) = (((((u * 256) + 8) + 1) * $6F4F2B) / 256) % $1000000
    Hc(13) = (((((((Hi(1) * 256) + Hi(2)) * 256) + 9) + 1) * $6F4F2B) / 256) % $1000000
    u = (((((wh * 256) + (wc % 256)) + 1) * $6F4F2B) / 256) % $1000000
    u = (((((u * 256) + ((wc / 256) % 256)) + 1) * $6F4F2B) / 256) % $1000000
    u = (((((u * 256) + (wc / 65536)) + 1) * $6F4F2B) / 256) % $1000000
    Hc(14) = (((((u * 256) + 10) + 1) * $6F4F2B) / 256) % $1000000
    a1 = 0: a2 = 0
    If ppl + pos - ls < pl: a1 = PeekA(*D + ppl + pos - ls): EndIf
    If ppl + pos - ls + 1 < pl: a2 = PeekA(*D + ppl + pos - ls + 1): EndIf
    a = (a1 * 256) + a2
    u = (((((a * 256) + (h0 % 256)) + 1) * $6F4F2B) / 256) % $1000000
    u = (((((u * 256) + ((h0 / 256) % 256)) + 1) * $6F4F2B) / 256) % $1000000
    u = (((((u * 256) + (h0 / 65536)) + 1) * $6F4F2B) / 256) % $1000000
    Hc(15) = (((((u * 256) + 14) + 1) * $6F4F2B) / 256) % $1000000
    a = I1(h0)
    u = (((((a * 256) + (h0 % 256)) + 1) * $6F4F2B) / 256) % $1000000
    u = (((((u * 256) + ((h0 / 256) % 256)) + 1) * $6F4F2B) / 256) % $1000000
    u = (((((u * 256) + (h0 / 65536)) + 1) * $6F4F2B) / 256) % $1000000
    Hc(16) = (((((u * 256) + 19) + 1) * $6F4F2B) / 256) % $1000000
    a = I2((Hi(1) * 256) + h0)
    u = (((((a * 256) + (h0 % 256)) + 1) * $6F4F2B) / 256) % $1000000
    u = (((((u * 256) + ((h0 / 256) % 256)) + 1) * $6F4F2B) / 256) % $1000000
    u = (((((u * 256) + (h0 / 65536)) + 1) * $6F4F2B) / 256) % $1000000
    Hc(17) = (((((u * 256) + 17) + 1) * $6F4F2B) / 256) % $1000000
    a = tk
    If a > 15: a = 15: EndIf
    a = (a * 256) + h0
    u = (((((a * 256) + (fw % 256)) + 1) * $6F4F2B) / 256) % $1000000
    u = (((((u * 256) + ((fw / 256) % 256)) + 1) * $6F4F2B) / 256) % $1000000
    u = (((((u * 256) + (fw / 65536)) + 1) * $6F4F2B) / 256) % $1000000
    Hc(18) = (((((u * 256) + 18) + 1) * $6F4F2B) / 256) % $1000000
    a1 = 0: a2 = 0: sr = 0: sf = 0
    If fwf = 1 And fw <> 0: sr = LF(fw % 65536): sf = LE(fw % 65536): EndIf
    If sr + pos - ls < sf: a1 = PeekA(*D + sr + pos - ls): EndIf
    If sr + pos - ls + 1 < sf: a2 = PeekA(*D + sr + pos - ls + 1): EndIf
    a = (a1 * 256) + a2
    u = (((((a * 256) + (v % 256)) + 1) * $6F4F2B) / 256) % $1000000
    u = (((((u * 256) + ((v / 256) % 256)) + 1) * $6F4F2B) / 256) % $1000000
    u = (((((u * 256) + (v / 65536)) + 1) * $6F4F2B) / 256) % $1000000
    Hc(19) = (((((u * 256) + 16) + 1) * $6F4F2B) / 256) % $1000000
    a = pos - ls
    If a > 79: a = 79: EndIf
    Hc(20) = (((((((a * 256) + h0) * 256) + 11) + 1) * $6F4F2B) / 256) % $1000000
    a1 = 0: a3 = 0
    If pl + pos - ls - 1 < ls And pos > ls: a1 = PeekA(*D + pl + pos - ls - 1): EndIf
    If pl + pos - ls + 2 < ls: a3 = PeekA(*D + pl + pos - ls + 2): EndIf
    a = (a1 * 65536) + (ab * 256) + a3
    u = (((((a * 256) + (v % 256)) + 1) * $6F4F2B) / 256) % $1000000
    u = (((((u * 256) + ((v / 256) % 256)) + 1) * $6F4F2B) / 256) % $1000000
    u = (((((u * 256) + (v / 65536)) + 1) * $6F4F2B) / 256) % $1000000
    Hc(21) = (((((u * 256) + 12) + 1) * $6F4F2B) / 256) % $1000000
    If ml > 0 And PeekA(*D + mp) = h0
      If ml < 65535: ml = ml + 1: EndIf
      mp = mp + 1
    Else
      ml = 0
    EndIf
    h16 = 0
    If pos >= 16
      For k = 16 To 1 Step -1
        h16 = ((((h16 + PeekA(*D + pos - k)) + 1) * $6F4F2B) / 256) % $1000000
      Next
    EndIf
    If ml = 0 And pos >= 16
      mp = MT3(h16 % $100000)
      While mp > 0 And ml < 124 And ml < mp
        If PeekA(*D + mp - ml - 1) <> PeekA(*D + pos - ml - 1): Break: EndIf
        ml = ml + 1
      Wend
    EndIf
    If pos >= 16: MT3(h16 % $100000) = pos: EndIf
    If ml = 0 And pos >= 8
      mp = MT2(h8 % $100000)
      While mp > 0 And ml < 124 And ml < mp
        If PeekA(*D + mp - ml - 1) <> PeekA(*D + pos - ml - 1): Break: EndIf
        ml = ml + 1
      Wend
    EndIf
    If ml = 0 And pos >= 5
      mp = MT(hm)
      While mp > 0 And ml < 124 And ml < mp
        If PeekA(*D + mp - ml - 1) <> PeekA(*D + pos - ml - 1): Break: EndIf
        ml = ml + 1
      Wend
    EndIf
    MT(hm) = pos
    MT2(h8 % $100000) = pos
    ma = Bool(ml > 0)
    a = ml
    If a > 15: a = 15: EndIf
    b = 0
    If ma: b = PeekA(*D + mp): EndIf
    u = (((((a * 256) + (b % 256)) + 1) * $6F4F2B) / 256) % $1000000
    u = (((((u * 256) + ((b / 256) % 256)) + 1) * $6F4F2B) / 256) % $1000000
    u = (((((u * 256) + (b / 65536)) + 1) * $6F4F2B) / 256) % $1000000
    Hc(22) = (((((u * 256) + 5) + 1) * $6F4F2B) / 256) % $1000000
    a = 0
    If ma: a = PeekA(*D + mp) + 256: EndIf
    u = (((((a * 256) + (v % 256)) + 1) * $6F4F2B) / 256) % $1000000
    u = (((((u * 256) + ((v / 256) % 256)) + 1) * $6F4F2B) / 256) % $1000000
    u = (((((u * 256) + (v / 65536)) + 1) * $6F4F2B) / 256) % $1000000
    Hc(23) = (((((u * 256) + 13) + 1) * $6F4F2B) / 256) % $1000000
    c = PeekA(*D + pos)
    c0 = 1
    For j = 0 To 7
      ws = c0 * 50
      For k = 0 To 23
        Ix(k) = (((((Hc(k) * 256) + c0) * $2E8BA3) / 1024) % $400000) + (k * $400000)
        ck = ((((Hc(k) * 256) + c0) / 4096) % 255) + 1
        If Kc(Ix(k)) <> ck
          Kc(Ix(k)) = ck
          M(Ix(k)) = 8388608
          Bh(Ix(k)) = 0
        EndIf
        Sv(k * 2) = St(M(Ix(k)) / 4096)
        Sv((k * 2) + 1) = St(SM((k * 65536) + Bh(Ix(k)) + (256 * c0)) / 4096)
      Next
      Sv(48) = 256
      Sv(49) = 0
      If ma
        pb = PeekA(*D + mp) + 256
        If pb / P2(8 - j) = c0
          u = ml
          If u > 31: u = 31: EndIf
          im = (u * 2) + ((pb / P2(7 - j)) % 2)
          Sv(49) = St(MS(im) / 4096)
        Else
          ma = 0
        EndIf
      EndIf
      u = ml
      If u > 15: u = 15: EndIf
      wi = ((u * 2) + ma) * 50
      wn = ((zn * 256) + h0) * 50
      wz = Hi(1) * 50
      wv = ab * 50
      dot = 0: dw = 0: dy = 0: dz = 0: dv = 0
      For k = 0 To 49
        dot = dot + (W(ws + k) * Sv(k))
        dw = dw + (Wx(wi + k) * Sv(k))
        dy = dy + (Wc(wn + k) * Sv(k))
        dz = dz + (Wz(wz + k) * Sv(k))
        dv = dv + (Wv(wv + k) * Sv(k))
      Next
      e = dot / 65536
      If e > 2047: e = 2047: EndIf
      If e < -2047: e = -2047: EndIf
      r1 = Sq(e + 2047)
      e = dw / 65536
      If e > 2047: e = 2047: EndIf
      If e < -2047: e = -2047: EndIf
      r2 = Sq(e + 2047)
      e = dy / 65536
      If e > 2047: e = 2047: EndIf
      If e < -2047: e = -2047: EndIf
      r3 = Sq(e + 2047)
      e = dz / 65536
      If e > 2047: e = 2047: EndIf
      If e < -2047: e = -2047: EndIf
      r4 = Sq(e + 2047)
      e = dv / 65536
      If e > 2047: e = 2047: EndIf
      If e < -2047: e = -2047: EndIf
      r5 = Sq(e + 2047)
      f = ((zn * 16) + (j * 2) + ma) * 6
      pf = (Wf(f) * St(r1)) + (Wf(f + 1) * St(r2)) + (Wf(f + 2) * St(r3)) + (Wf(f + 4) * St(r4)) + (Wf(f + 5) * St(r5)) + (Wf(f + 3) * 256)
      e = pf / 65536
      If e > 2047: e = 2047: EndIf
      If e < -2047: e = -2047: EndIf
      pm = Sq(e + 2047)
      pf = pm
      s = St(pm) + 2048
      aw = s % 128
      ai = (((h0 * 256) + c0) * 33) + (s / 128)
      pa = ((Ap(ai) * (128 - aw)) + (Ap(ai + 1) * aw)) / 2048
      u = (((((Hi(1) * 256) + h0) + 1) * $6F4F2B) / 256) % $1000000
      u = (((((u * 256) + c0) + 1) * $6F4F2B) / 256) % $1000000
      ai2 = ((u % 65536) * 33) + (s / 128)
      pa2 = ((Ap2(ai2) * (128 - aw)) + (Ap2(ai2 + 1) * aw)) / 2048
      pm = ((2 * pm) + (3 * pa) + (3 * pa2)) / 8
      If pm < 1: pm = 1: EndIf
      If pm > 4095: pm = 4095: EndIf
      If pos >= P
        xm = x1 + (((x2 - x1) / 4096) * pm)
        y = Bool(x <= xm)
        If y: x2 = xm: Else: x1 = xm + 1: EndIf
      Else
        y = (c / P2(7 - j)) % 2
      EndIf
      er = ((y * 4096) - r1) * 2
      e2 = ((y * 4096) - r2) * 2
      e3 = ((y * 4096) - r3) * 2
      e4 = ((y * 4096) - r4) * 2
      e5 = ((y * 4096) - r5) * 2
      For k = 0 To 49
        W(ws + k) = W(ws + k) + ((Sv(k) * er) / 8192)
        Wx(wi + k) = Wx(wi + k) + ((Sv(k) * e2) / 8192)
        Wc(wn + k) = Wc(wn + k) + ((Sv(k) * e3) / 8192)
        Wz(wz + k) = Wz(wz + k) + ((Sv(k) * e4) / 8192)
        Wv(wv + k) = Wv(wv + k) + ((Sv(k) * e5) / 8192)
      Next
      For k = 0 To 23
        hb = Bh(Ix(k))
        si = (k * 65536) + hb + (256 * c0)
        u = SM(si) / 256
        v = SM(si) % 256
        If y: u = u + (((65536 - u) * Kr(v)) / 4096): Else: u = u - ((u * Kr(v)) / 4096): EndIf
        If v < 60: v = v + 1: EndIf
        SM(si) = (u * 256) + v
        n0 = hb % 8
        n1 = (hb / 8) % 8
        hh = hb / 64
        If y
          If n1 < 7: n1 = n1 + 1: EndIf
          If n0 > 2: n0 = (n0 / 2) + 1: EndIf
        Else
          If n0 < 7: n0 = n0 + 1: EndIf
          If n1 > 2: n1 = (n1 / 2) + 1: EndIf
        EndIf
        Bh(Ix(k)) = n0 + (n1 * 8) + ((((hh * 2) + y) % 4) * 64)
        u = M(Ix(k)) / 256
        v = M(Ix(k)) % 256
        If y: u = u + (((65536 - u) * Kr(v)) / 4096): Else: u = u - ((u * Kr(v)) / 4096): EndIf
        If v < 127: v = v + 1: EndIf
        M(Ix(k)) = (u * 256) + v
      Next
      If ma
        u = MS(im) / 256
        v = MS(im) % 256
        If y: u = u + (((65536 - u) * Kr(v)) / 4096): Else: u = u - ((u * Kr(v)) / 4096): EndIf
        If v < 127: v = v + 1: EndIf
        MS(im) = (u * 256) + v
      EndIf
      g = (y * 65536) + (y * 64) - (2 * y)
      Ap(ai) = Ap(ai) + (((g - Ap(ai)) * (128 - aw)) / 8192)
      Ap(ai + 1) = Ap(ai + 1) + (((g - Ap(ai + 1)) * aw) / 8192)
      Ap2(ai2) = Ap2(ai2) + (((g - Ap2(ai2)) * (128 - aw)) / 8192)
      Ap2(ai2 + 1) = Ap2(ai2 + 1) + (((g - Ap2(ai2 + 1)) * aw) / 8192)
      ef = ((y * 4096) - pf) * 2
      Wf(f + 0) = Wf(f + 0) + ((St(r1) * ef) / 32768)
      Wf(f + 1) = Wf(f + 1) + ((St(r2) * ef) / 32768)
      Wf(f + 2) = Wf(f + 2) + ((St(r3) * ef) / 32768)
      Wf(f + 3) = Wf(f + 3) + ((256 * ef) / 32768)
      Wf(f + 4) = Wf(f + 4) + ((St(r4) * ef) / 32768)
      Wf(f + 5) = Wf(f + 5) + ((St(r5) * ef) / 32768)
      c0 = (c0 * 2) + y
      While x1 / 16777216 = x2 / 16777216
        x1 = (x1 % 16777216) * 256
        x2 = ((x2 % 16777216) * 256) + 255
        x = (x % 16777216) * 256
        If ip < Z: x = x + PeekA(*C + ip): EndIf
        ip = ip + 1
      Wend
    Next
    c = c0 - 256
    PokeA(*D + pos, c)
    If pos >= P: chk = ((chk * 33) + c) % 1000000007: EndIf
    I1(h0) = ((I1(h0) * 256) + c) % 65536
    v = (Hi(1) * 256) + h0
    I2(v) = ((I2(v) * 256) + c) % 65536
    lt = 0
    If (c >= 48 And c <= 57) Or (c >= 65 And c <= 90) Or (c >= 97 And c <= 122) Or c = 95: lt = 1: EndIf
    l1 = 0
    If (h0 >= 48 And h0 <= 57) Or (h0 >= 65 And h0 <= 90) Or (h0 >= 97 And h0 <= 122) Or h0 = 95: l1 = 1: EndIf
    If c = 10
      tk = 0
    ElseIf c <> 32 And (lt = 0 Or l1 = 0)
      tk = tk + 1
    EndIf
    For k = 7 To 1 Step -1
      Hi(k) = Hi(k - 1)
    Next
    Hi(0) = c
    If c = 10
      If fw <> 0
        LF(fw % 65536) = ls
        LE(fw % 65536) = pos
      EndIf
      ppl = pl: pl = ls: ls = pos + 1: pfw = fw: fw = 0: fwf = 0: nd = 0: bd = 0
    EndIf
    If zn = 0
      If c = 40 And bd < 7
        bd = bd + 1
      ElseIf c = 41 And bd > 0
        bd = bd - 1
      EndIf
    EndIf
    If lt
      If wh = 0: wc = Hi(1): EndIf
      wh = ((((wh + c) + 1) * $6F4F2B) / 256) % $1000000
    Else
      If wh <> 0: wp = wh: EndIf
      wh = 0
    EndIf
    If c = 32 And fwf = 0 And fw = 0: nd = nd + 1: EndIf
    If fwf = 0
      If lt
        fw = (((((fw * 256) + c) + 1) * $6F4F2B) / 256) % $1000000
      ElseIf fw > 0
        fwf = 1
      EndIf
    EndIf
    If zn = 0
      If c = 59
        zn = 2
      ElseIf c = 34
        zn = 1
      EndIf
    ElseIf zn = 1
      If c = 34 Or c = 10: zn = 0: EndIf
    ElseIf c = 10
      zn = 0
    EndIf
  Next

  ProcedureReturn chk
EndProcedure
EnableDebugger


; ----------------------------------------------------------------------------
;  Décodeur du fichier de référence (méthode v4, depuis la v6.4): les mêmes
;  calculs que DecoderCM4, avec P = 0 (tout le texte est compressé). Si EtatFin
;  n'est pas 0, l'état du modèle à la fin est écrit dans ce fichier: c'est
;  exactement l'état après la lecture de ce texte (xm, variable du codage, est
;  remise à 0 comme pendant une lecture).
; ----------------------------------------------------------------------------
DisableDebugger
Procedure.q DecoderReferenceCM4(*C, Z.q, T.q, *D, P.q, EtatLu.q, EtatEcrit.q, EtatFin.q)
  Protected.q i, u, v, charge, crc, x, ip, k, x1, x2, ml, mp, ma, chk, wh, wp, wc, fw, fwf, pfw, nd, bd, tk, zn, ls, pl, ppl, Debut, h0, h, hm, h8, ab, u2, ab2, a, a1, a2, sr, sf, a3, h16, b, c, c0, j, ws, ck, pb, im, wi, wn, wz, wv, dot, dw, dy, dz, dv, e, r1, r2, r3, r4, r5, f, pf, pm, s, aw, ai, pa, ai2, pa2, xm, y, er, e2, e3, e4, e5, hb, si, n0, n1, hh, g, ef, lt, l1, pos

  Dim T33.q(32)
  Restore Sq33
  For i = 0 To 32
    Read.q u
    T33(i) = u
  Next
  Dim Sq.q(4094)
  For i = 0 To 4094
    u = (i + 1) % 128
    v = (i + 1) / 128
    Sq(i) = ((T33(v) * (128 - u)) + (T33(v + 1) * u) + 64) / 128
  Next
  Dim St.q(4095)
  v = 0
  For i = 0 To 4094
    While v <= Sq(i)
      St(v) = i - 2047
      v = v + 1
    Wend
  Next
  While v <= 4095
    St(v) = 2047
    v = v + 1
  Wend
  Dim Kr.q(255)
  For i = 0 To 255
    Kr(i) = 8192 / ((2 * i) + 3)
  Next
  Dim P2.q(8)
  P2(0) = 1
  For i = 1 To 8
    P2(i) = P2(i - 1) * 2
  Next
  Dim M.l(100663295)
  Dim Bh.a(100663295)
  Dim Kc.a(100663295)
  Dim SM.q(1572863)
  Dim MT.l(1048575)
  Dim MT2.l(1048575)
  Dim MT3.l(1048575)
  Dim MS.q(63)
  Dim W.q(12799)
  Dim Wx.q(1599)
  Dim Wc.q(38399)
  Dim Wz.q(12799)
  Dim Wv.q(12799)
  Dim Wf.q(383)
  Dim Ap.q(2162687)
  Dim Ap2.q(2162687)
  Dim I1.q(255)
  Dim I2.q(65535)
  Dim LF.q(65535)
  Dim LE.q(65535)
  Dim Hi.q(7)
  Dim Hc.q(23)
  Dim Ix.q(23)
  Dim Sv.q(49)
  Dim Es.q(81)
  charge = 0
  If EtatLu <> 0
    crc = 0
    crc = EchangeTableauL(EtatLu, 0, M(), crc)
    crc = EchangeTableauA(EtatLu, 0, Bh(), crc)
    crc = EchangeTableauA(EtatLu, 0, Kc(), crc)
    crc = EchangeTableauQ(EtatLu, 0, SM(), crc)
    crc = EchangeTableauL(EtatLu, 0, MT(), crc)
    crc = EchangeTableauL(EtatLu, 0, MT2(), crc)
    crc = EchangeTableauL(EtatLu, 0, MT3(), crc)
    crc = EchangeTableauQ(EtatLu, 0, MS(), crc)
    crc = EchangeTableauQ(EtatLu, 0, W(), crc)
    crc = EchangeTableauQ(EtatLu, 0, Wx(), crc)
    crc = EchangeTableauQ(EtatLu, 0, Wc(), crc)
    crc = EchangeTableauQ(EtatLu, 0, Wz(), crc)
    crc = EchangeTableauQ(EtatLu, 0, Wv(), crc)
    crc = EchangeTableauQ(EtatLu, 0, Wf(), crc)
    crc = EchangeTableauQ(EtatLu, 0, Ap(), crc)
    crc = EchangeTableauQ(EtatLu, 0, Ap2(), crc)
    crc = EchangeTableauQ(EtatLu, 0, I1(), crc)
    crc = EchangeTableauQ(EtatLu, 0, I2(), crc)
    crc = EchangeTableauQ(EtatLu, 0, LF(), crc)
    crc = EchangeTableauQ(EtatLu, 0, LE(), crc)
    crc = EchangeTableauQ(EtatLu, 0, Hi(), crc)
    crc = EchangeTableauQ(EtatLu, 0, Hc(), crc)
    crc = EchangeTableauQ(EtatLu, 0, Ix(), crc)
    crc = EchangeTableauQ(EtatLu, 0, Sv(), crc)
    crc = EchangeTableauQ(EtatLu, 0, Es(), crc)
    If crc >= 0 And crc = LireControleEtat(EtatLu)
      charge = 1
    Else
      SignalerEtatAbime()
    EndIf
  EndIf
  If charge = 0
    If EtatLu <> 0
      Dim M.l(100663295)
      Dim Bh.a(100663295)
      Dim Kc.a(100663295)
      Dim SM.q(1572863)
      Dim MT.l(1048575)
      Dim MT2.l(1048575)
      Dim MT3.l(1048575)
      Dim MS.q(63)
      Dim W.q(12799)
      Dim Wx.q(1599)
      Dim Wc.q(38399)
      Dim Wz.q(12799)
      Dim Wv.q(12799)
      Dim Wf.q(383)
      Dim Ap.q(2162687)
      Dim Ap2.q(2162687)
      Dim I1.q(255)
      Dim I2.q(65535)
      Dim LF.q(65535)
      Dim LE.q(65535)
      Dim Hi.q(7)
      Dim Hc.q(23)
      Dim Ix.q(23)
      Dim Sv.q(49)
      Dim Es.q(81)
    EndIf
    For i = 0 To 100663295
      M(i) = 8388608
    Next
    For i = 0 To 1572863
      SM(i) = 8388608
    Next
    For i = 0 To 63
      MS(i) = 8388608
    Next
    For i = 0 To 12799
      W(i) = 2621
    Next
    For i = 0 To 1599
      Wx(i) = 2621
    Next
    For i = 0 To 38399
      Wc(i) = 2621
    Next
    For i = 0 To 12799
      Wz(i) = 2621
    Next
    For i = 0 To 12799
      Wv(i) = 2621
    Next
    For i = 0 To 383
      If i % 6 = 3: Wf(i) = 0: Else: Wf(i) = 13107: EndIf
    Next
    For i = 0 To 2162687
      u = ((i % 33) * 128) - 1
      If u < 0: u = 0: EndIf
      If u > 4094: u = 4094: EndIf
      Ap(i) = Sq(u) * 16
    Next
    For i = 0 To 2162687
      u = ((i % 33) * 128) - 1
      If u < 0: u = 0: EndIf
      If u > 4094: u = 4094: EndIf
      Ap2(i) = Sq(u) * 16
    Next
  EndIf
  x = 0: ip = 0
  For k = 1 To 4
    x = x * 256
    If ip < Z: x = x + PeekA(*C + ip): EndIf
    ip = ip + 1
  Next
  x1 = 0: x2 = 4294967295: ml = 0: mp = 0: ma = 0: chk = 0
  wh = 0: wp = 0: wc = 0: fw = 0: fwf = 0: pfw = 0: nd = 0: bd = 0: tk = 0: zn = 0
  ls = 0: pl = 0: ppl = 0
  Debut = 0
  If charge
    i = Es(0): u = Es(1): v = Es(2): ml = Es(3): mp = Es(4): ma = Es(5): wh = Es(6): wp = Es(7)
    wc = Es(8): fw = Es(9): fwf = Es(10): pfw = Es(11): nd = Es(12): bd = Es(13): tk = Es(14): zn = Es(15)
    ls = Es(16): pl = Es(17): ppl = Es(18): h0 = Es(19): h = Es(20): k = Es(21): hm = Es(22): h8 = Es(23)
    ab = Es(24): u2 = Es(25): ab2 = Es(26): a = Es(27): a1 = Es(28): a2 = Es(29): sr = Es(30): sf = Es(31)
    a3 = Es(32): h16 = Es(33): b = Es(34): c = Es(35): c0 = Es(36): j = Es(37): ws = Es(38): ck = Es(39)
    pb = Es(40): im = Es(41): wi = Es(42): wn = Es(43): wz = Es(44): wv = Es(45): dot = Es(46): dw = Es(47)
    dy = Es(48): dz = Es(49): dv = Es(50): e = Es(51): r1 = Es(52): r2 = Es(53): r3 = Es(54): r4 = Es(55)
    r5 = Es(56): f = Es(57): pf = Es(58): pm = Es(59): s = Es(60): aw = Es(61): ai = Es(62): pa = Es(63)
    ai2 = Es(64): pa2 = Es(65): xm = Es(66): y = Es(67): er = Es(68): e2 = Es(69): e3 = Es(70): e4 = Es(71)
    e5 = Es(72): hb = Es(73): si = Es(74): n0 = Es(75): n1 = Es(76): hh = Es(77): g = Es(78): ef = Es(79)
    lt = Es(80): l1 = Es(81)
    Debut = P
  EndIf
  For pos = Debut To P + T - 1
    If pos = P And EtatEcrit <> 0
      Es(0) = i: Es(1) = u: Es(2) = v: Es(3) = ml: Es(4) = mp: Es(5) = ma: Es(6) = wh: Es(7) = wp
      Es(8) = wc: Es(9) = fw: Es(10) = fwf: Es(11) = pfw: Es(12) = nd: Es(13) = bd: Es(14) = tk: Es(15) = zn
      Es(16) = ls: Es(17) = pl: Es(18) = ppl: Es(19) = h0: Es(20) = h: Es(21) = k: Es(22) = hm: Es(23) = h8
      Es(24) = ab: Es(25) = u2: Es(26) = ab2: Es(27) = a: Es(28) = a1: Es(29) = a2: Es(30) = sr: Es(31) = sf
      Es(32) = a3: Es(33) = h16: Es(34) = b: Es(35) = c: Es(36) = c0: Es(37) = j: Es(38) = ws: Es(39) = ck
      Es(40) = pb: Es(41) = im: Es(42) = wi: Es(43) = wn: Es(44) = wz: Es(45) = wv: Es(46) = dot: Es(47) = dw
      Es(48) = dy: Es(49) = dz: Es(50) = dv: Es(51) = e: Es(52) = r1: Es(53) = r2: Es(54) = r3: Es(55) = r4
      Es(56) = r5: Es(57) = f: Es(58) = pf: Es(59) = pm: Es(60) = s: Es(61) = aw: Es(62) = ai: Es(63) = pa
      Es(64) = ai2: Es(65) = pa2: Es(66) = xm: Es(67) = y: Es(68) = er: Es(69) = e2: Es(70) = e3: Es(71) = e4
      Es(72) = e5: Es(73) = hb: Es(74) = si: Es(75) = n0: Es(76) = n1: Es(77) = hh: Es(78) = g: Es(79) = ef
      Es(80) = lt: Es(81) = l1
      crc = 0
      crc = EchangeTableauL(EtatEcrit, 1, M(), crc)
      crc = EchangeTableauA(EtatEcrit, 1, Bh(), crc)
      crc = EchangeTableauA(EtatEcrit, 1, Kc(), crc)
      crc = EchangeTableauQ(EtatEcrit, 1, SM(), crc)
      crc = EchangeTableauL(EtatEcrit, 1, MT(), crc)
      crc = EchangeTableauL(EtatEcrit, 1, MT2(), crc)
      crc = EchangeTableauL(EtatEcrit, 1, MT3(), crc)
      crc = EchangeTableauQ(EtatEcrit, 1, MS(), crc)
      crc = EchangeTableauQ(EtatEcrit, 1, W(), crc)
      crc = EchangeTableauQ(EtatEcrit, 1, Wx(), crc)
      crc = EchangeTableauQ(EtatEcrit, 1, Wc(), crc)
      crc = EchangeTableauQ(EtatEcrit, 1, Wz(), crc)
      crc = EchangeTableauQ(EtatEcrit, 1, Wv(), crc)
      crc = EchangeTableauQ(EtatEcrit, 1, Wf(), crc)
      crc = EchangeTableauQ(EtatEcrit, 1, Ap(), crc)
      crc = EchangeTableauQ(EtatEcrit, 1, Ap2(), crc)
      crc = EchangeTableauQ(EtatEcrit, 1, I1(), crc)
      crc = EchangeTableauQ(EtatEcrit, 1, I2(), crc)
      crc = EchangeTableauQ(EtatEcrit, 1, LF(), crc)
      crc = EchangeTableauQ(EtatEcrit, 1, LE(), crc)
      crc = EchangeTableauQ(EtatEcrit, 1, Hi(), crc)
      crc = EchangeTableauQ(EtatEcrit, 1, Hc(), crc)
      crc = EchangeTableauQ(EtatEcrit, 1, Ix(), crc)
      crc = EchangeTableauQ(EtatEcrit, 1, Sv(), crc)
      crc = EchangeTableauQ(EtatEcrit, 1, Es(), crc)
      EcrireControleEtat(EtatEcrit, crc)
    EndIf
    If pos % 4096 = 0: ProgressionCM(pos): EndIf
    h0 = Hi(0)
    h = 0
    For k = 0 To 7
      h = ((((h + Hi(k)) + 1) * $6F4F2B) / 256) % $1000000
      If k < 4: Hc(k) = h: EndIf
      If k = 4: hm = h % $100000: EndIf
    Next
    h8 = h
    Hc(4) = (((((wh * 256) + h0) + 1) * $6F4F2B) / 256) % $1000000
    ab = 0
    If pl + pos - ls < ls: ab = PeekA(*D + pl + pos - ls): EndIf
    Hc(5) = (((((ab * 256) + h0) + 1048577) * $6F4F2B) / 256) % $1000000
    Hc(6) = h8
    u = (((((wh * 256) + (wp % 256)) + 1) * $6F4F2B) / 256) % $1000000
    u = (((((u * 256) + ((wp / 256) % 256)) + 1) * $6F4F2B) / 256) % $1000000
    u = (((((u * 256) + (wp / 65536)) + 1) * $6F4F2B) / 256) % $1000000
    Hc(7) = (((((u * 256) + (h0 + 2)) + 1) * $6F4F2B) / 256) % $1000000
    u = (((((fw * 256) + (wh % 256)) + 1) * $6F4F2B) / 256) % $1000000
    u = (((((u * 256) + ((wh / 256) % 256)) + 1) * $6F4F2B) / 256) % $1000000
    u = (((((u * 256) + (wh / 65536)) + 1) * $6F4F2B) / 256) % $1000000
    Hc(8) = (((((u * 256) + 3) + 1) * $6F4F2B) / 256) % $1000000
    u2 = u
    v = (h0 * 256) + Hi(1)
    u = (((((nd * 256) + (v % 256)) + 1) * $6F4F2B) / 256) % $1000000
    u = (((((u * 256) + ((v / 256) % 256)) + 1) * $6F4F2B) / 256) % $1000000
    u = (((((u * 256) + (v / 65536)) + 1) * $6F4F2B) / 256) % $1000000
    Hc(9) = (((((u * 256) + 4) + 1) * $6F4F2B) / 256) % $1000000
    u = (((((bd * 256) + (v % 256)) + 1) * $6F4F2B) / 256) % $1000000
    u = (((((u * 256) + ((v / 256) % 256)) + 1) * $6F4F2B) / 256) % $1000000
    u = (((((u * 256) + (v / 65536)) + 1) * $6F4F2B) / 256) % $1000000
    Hc(10) = (((((u * 256) + 6) + 1) * $6F4F2B) / 256) % $1000000
    ab2 = 0
    If pl + pos - ls + 1 < ls: ab2 = PeekA(*D + pl + pos - ls + 1): EndIf
    a = (ab * 256) + ab2
    u = (((((a * 256) + (h0 % 256)) + 1) * $6F4F2B) / 256) % $1000000
    u = (((((u * 256) + ((h0 / 256) % 256)) + 1) * $6F4F2B) / 256) % $1000000
    u = (((((u * 256) + (h0 / 65536)) + 1) * $6F4F2B) / 256) % $1000000
    Hc(11) = (((((u * 256) + 7) + 1) * $6F4F2B) / 256) % $1000000
    u = (((((pfw * 256) + (u2 % 256)) + 1) * $6F4F2B) / 256) % $1000000
    u = (((((u * 256) + ((u2 / 256) % 256)) + 1) * $6F4F2B) / 256) % $1000000
    u = (((((u * 256) + (u2 / 65536)) + 1) * $6F4F2B) / 256) % $1000000
    Hc(12) = (((((u * 256) + 8) + 1) * $6F4F2B) / 256) % $1000000
    Hc(13) = (((((((Hi(1) * 256) + Hi(2)) * 256) + 9) + 1) * $6F4F2B) / 256) % $1000000
    u = (((((wh * 256) + (wc % 256)) + 1) * $6F4F2B) / 256) % $1000000
    u = (((((u * 256) + ((wc / 256) % 256)) + 1) * $6F4F2B) / 256) % $1000000
    u = (((((u * 256) + (wc / 65536)) + 1) * $6F4F2B) / 256) % $1000000
    Hc(14) = (((((u * 256) + 10) + 1) * $6F4F2B) / 256) % $1000000
    a1 = 0: a2 = 0
    If ppl + pos - ls < pl: a1 = PeekA(*D + ppl + pos - ls): EndIf
    If ppl + pos - ls + 1 < pl: a2 = PeekA(*D + ppl + pos - ls + 1): EndIf
    a = (a1 * 256) + a2
    u = (((((a * 256) + (h0 % 256)) + 1) * $6F4F2B) / 256) % $1000000
    u = (((((u * 256) + ((h0 / 256) % 256)) + 1) * $6F4F2B) / 256) % $1000000
    u = (((((u * 256) + (h0 / 65536)) + 1) * $6F4F2B) / 256) % $1000000
    Hc(15) = (((((u * 256) + 14) + 1) * $6F4F2B) / 256) % $1000000
    a = I1(h0)
    u = (((((a * 256) + (h0 % 256)) + 1) * $6F4F2B) / 256) % $1000000
    u = (((((u * 256) + ((h0 / 256) % 256)) + 1) * $6F4F2B) / 256) % $1000000
    u = (((((u * 256) + (h0 / 65536)) + 1) * $6F4F2B) / 256) % $1000000
    Hc(16) = (((((u * 256) + 19) + 1) * $6F4F2B) / 256) % $1000000
    a = I2((Hi(1) * 256) + h0)
    u = (((((a * 256) + (h0 % 256)) + 1) * $6F4F2B) / 256) % $1000000
    u = (((((u * 256) + ((h0 / 256) % 256)) + 1) * $6F4F2B) / 256) % $1000000
    u = (((((u * 256) + (h0 / 65536)) + 1) * $6F4F2B) / 256) % $1000000
    Hc(17) = (((((u * 256) + 17) + 1) * $6F4F2B) / 256) % $1000000
    a = tk
    If a > 15: a = 15: EndIf
    a = (a * 256) + h0
    u = (((((a * 256) + (fw % 256)) + 1) * $6F4F2B) / 256) % $1000000
    u = (((((u * 256) + ((fw / 256) % 256)) + 1) * $6F4F2B) / 256) % $1000000
    u = (((((u * 256) + (fw / 65536)) + 1) * $6F4F2B) / 256) % $1000000
    Hc(18) = (((((u * 256) + 18) + 1) * $6F4F2B) / 256) % $1000000
    a1 = 0: a2 = 0: sr = 0: sf = 0
    If fwf = 1 And fw <> 0: sr = LF(fw % 65536): sf = LE(fw % 65536): EndIf
    If sr + pos - ls < sf: a1 = PeekA(*D + sr + pos - ls): EndIf
    If sr + pos - ls + 1 < sf: a2 = PeekA(*D + sr + pos - ls + 1): EndIf
    a = (a1 * 256) + a2
    u = (((((a * 256) + (v % 256)) + 1) * $6F4F2B) / 256) % $1000000
    u = (((((u * 256) + ((v / 256) % 256)) + 1) * $6F4F2B) / 256) % $1000000
    u = (((((u * 256) + (v / 65536)) + 1) * $6F4F2B) / 256) % $1000000
    Hc(19) = (((((u * 256) + 16) + 1) * $6F4F2B) / 256) % $1000000
    a = pos - ls
    If a > 79: a = 79: EndIf
    Hc(20) = (((((((a * 256) + h0) * 256) + 11) + 1) * $6F4F2B) / 256) % $1000000
    a1 = 0: a3 = 0
    If pl + pos - ls - 1 < ls And pos > ls: a1 = PeekA(*D + pl + pos - ls - 1): EndIf
    If pl + pos - ls + 2 < ls: a3 = PeekA(*D + pl + pos - ls + 2): EndIf
    a = (a1 * 65536) + (ab * 256) + a3
    u = (((((a * 256) + (v % 256)) + 1) * $6F4F2B) / 256) % $1000000
    u = (((((u * 256) + ((v / 256) % 256)) + 1) * $6F4F2B) / 256) % $1000000
    u = (((((u * 256) + (v / 65536)) + 1) * $6F4F2B) / 256) % $1000000
    Hc(21) = (((((u * 256) + 12) + 1) * $6F4F2B) / 256) % $1000000
    If ml > 0 And PeekA(*D + mp) = h0
      If ml < 65535: ml = ml + 1: EndIf
      mp = mp + 1
    Else
      ml = 0
    EndIf
    h16 = 0
    If pos >= 16
      For k = 16 To 1 Step -1
        h16 = ((((h16 + PeekA(*D + pos - k)) + 1) * $6F4F2B) / 256) % $1000000
      Next
    EndIf
    If ml = 0 And pos >= 16
      mp = MT3(h16 % $100000)
      While mp > 0 And ml < 124 And ml < mp
        If PeekA(*D + mp - ml - 1) <> PeekA(*D + pos - ml - 1): Break: EndIf
        ml = ml + 1
      Wend
    EndIf
    If pos >= 16: MT3(h16 % $100000) = pos: EndIf
    If ml = 0 And pos >= 8
      mp = MT2(h8 % $100000)
      While mp > 0 And ml < 124 And ml < mp
        If PeekA(*D + mp - ml - 1) <> PeekA(*D + pos - ml - 1): Break: EndIf
        ml = ml + 1
      Wend
    EndIf
    If ml = 0 And pos >= 5
      mp = MT(hm)
      While mp > 0 And ml < 124 And ml < mp
        If PeekA(*D + mp - ml - 1) <> PeekA(*D + pos - ml - 1): Break: EndIf
        ml = ml + 1
      Wend
    EndIf
    MT(hm) = pos
    MT2(h8 % $100000) = pos
    ma = Bool(ml > 0)
    a = ml
    If a > 15: a = 15: EndIf
    b = 0
    If ma: b = PeekA(*D + mp): EndIf
    u = (((((a * 256) + (b % 256)) + 1) * $6F4F2B) / 256) % $1000000
    u = (((((u * 256) + ((b / 256) % 256)) + 1) * $6F4F2B) / 256) % $1000000
    u = (((((u * 256) + (b / 65536)) + 1) * $6F4F2B) / 256) % $1000000
    Hc(22) = (((((u * 256) + 5) + 1) * $6F4F2B) / 256) % $1000000
    a = 0
    If ma: a = PeekA(*D + mp) + 256: EndIf
    u = (((((a * 256) + (v % 256)) + 1) * $6F4F2B) / 256) % $1000000
    u = (((((u * 256) + ((v / 256) % 256)) + 1) * $6F4F2B) / 256) % $1000000
    u = (((((u * 256) + (v / 65536)) + 1) * $6F4F2B) / 256) % $1000000
    Hc(23) = (((((u * 256) + 13) + 1) * $6F4F2B) / 256) % $1000000
    c = PeekA(*D + pos)
    c0 = 1
    For j = 0 To 7
      ws = c0 * 50
      For k = 0 To 23
        Ix(k) = (((((Hc(k) * 256) + c0) * $2E8BA3) / 1024) % $400000) + (k * $400000)
        ck = ((((Hc(k) * 256) + c0) / 4096) % 255) + 1
        If Kc(Ix(k)) <> ck
          Kc(Ix(k)) = ck
          M(Ix(k)) = 8388608
          Bh(Ix(k)) = 0
        EndIf
        Sv(k * 2) = St(M(Ix(k)) / 4096)
        Sv((k * 2) + 1) = St(SM((k * 65536) + Bh(Ix(k)) + (256 * c0)) / 4096)
      Next
      Sv(48) = 256
      Sv(49) = 0
      If ma
        pb = PeekA(*D + mp) + 256
        If pb / P2(8 - j) = c0
          u = ml
          If u > 31: u = 31: EndIf
          im = (u * 2) + ((pb / P2(7 - j)) % 2)
          Sv(49) = St(MS(im) / 4096)
        Else
          ma = 0
        EndIf
      EndIf
      u = ml
      If u > 15: u = 15: EndIf
      wi = ((u * 2) + ma) * 50
      wn = ((zn * 256) + h0) * 50
      wz = Hi(1) * 50
      wv = ab * 50
      dot = 0: dw = 0: dy = 0: dz = 0: dv = 0
      For k = 0 To 49
        dot = dot + (W(ws + k) * Sv(k))
        dw = dw + (Wx(wi + k) * Sv(k))
        dy = dy + (Wc(wn + k) * Sv(k))
        dz = dz + (Wz(wz + k) * Sv(k))
        dv = dv + (Wv(wv + k) * Sv(k))
      Next
      e = dot / 65536
      If e > 2047: e = 2047: EndIf
      If e < -2047: e = -2047: EndIf
      r1 = Sq(e + 2047)
      e = dw / 65536
      If e > 2047: e = 2047: EndIf
      If e < -2047: e = -2047: EndIf
      r2 = Sq(e + 2047)
      e = dy / 65536
      If e > 2047: e = 2047: EndIf
      If e < -2047: e = -2047: EndIf
      r3 = Sq(e + 2047)
      e = dz / 65536
      If e > 2047: e = 2047: EndIf
      If e < -2047: e = -2047: EndIf
      r4 = Sq(e + 2047)
      e = dv / 65536
      If e > 2047: e = 2047: EndIf
      If e < -2047: e = -2047: EndIf
      r5 = Sq(e + 2047)
      f = ((zn * 16) + (j * 2) + ma) * 6
      pf = (Wf(f) * St(r1)) + (Wf(f + 1) * St(r2)) + (Wf(f + 2) * St(r3)) + (Wf(f + 4) * St(r4)) + (Wf(f + 5) * St(r5)) + (Wf(f + 3) * 256)
      e = pf / 65536
      If e > 2047: e = 2047: EndIf
      If e < -2047: e = -2047: EndIf
      pm = Sq(e + 2047)
      pf = pm
      s = St(pm) + 2048
      aw = s % 128
      ai = (((h0 * 256) + c0) * 33) + (s / 128)
      pa = ((Ap(ai) * (128 - aw)) + (Ap(ai + 1) * aw)) / 2048
      u = (((((Hi(1) * 256) + h0) + 1) * $6F4F2B) / 256) % $1000000
      u = (((((u * 256) + c0) + 1) * $6F4F2B) / 256) % $1000000
      ai2 = ((u % 65536) * 33) + (s / 128)
      pa2 = ((Ap2(ai2) * (128 - aw)) + (Ap2(ai2 + 1) * aw)) / 2048
      pm = ((2 * pm) + (3 * pa) + (3 * pa2)) / 8
      If pm < 1: pm = 1: EndIf
      If pm > 4095: pm = 4095: EndIf
      If pos >= P
        xm = x1 + (((x2 - x1) / 4096) * pm)
        y = Bool(x <= xm)
        If y: x2 = xm: Else: x1 = xm + 1: EndIf
      Else
        y = (c / P2(7 - j)) % 2
      EndIf
      er = ((y * 4096) - r1) * 2
      e2 = ((y * 4096) - r2) * 2
      e3 = ((y * 4096) - r3) * 2
      e4 = ((y * 4096) - r4) * 2
      e5 = ((y * 4096) - r5) * 2
      For k = 0 To 49
        W(ws + k) = W(ws + k) + ((Sv(k) * er) / 8192)
        Wx(wi + k) = Wx(wi + k) + ((Sv(k) * e2) / 8192)
        Wc(wn + k) = Wc(wn + k) + ((Sv(k) * e3) / 8192)
        Wz(wz + k) = Wz(wz + k) + ((Sv(k) * e4) / 8192)
        Wv(wv + k) = Wv(wv + k) + ((Sv(k) * e5) / 8192)
      Next
      For k = 0 To 23
        hb = Bh(Ix(k))
        si = (k * 65536) + hb + (256 * c0)
        u = SM(si) / 256
        v = SM(si) % 256
        If y: u = u + (((65536 - u) * Kr(v)) / 4096): Else: u = u - ((u * Kr(v)) / 4096): EndIf
        If v < 60: v = v + 1: EndIf
        SM(si) = (u * 256) + v
        n0 = hb % 8
        n1 = (hb / 8) % 8
        hh = hb / 64
        If y
          If n1 < 7: n1 = n1 + 1: EndIf
          If n0 > 2: n0 = (n0 / 2) + 1: EndIf
        Else
          If n0 < 7: n0 = n0 + 1: EndIf
          If n1 > 2: n1 = (n1 / 2) + 1: EndIf
        EndIf
        Bh(Ix(k)) = n0 + (n1 * 8) + ((((hh * 2) + y) % 4) * 64)
        u = M(Ix(k)) / 256
        v = M(Ix(k)) % 256
        If y: u = u + (((65536 - u) * Kr(v)) / 4096): Else: u = u - ((u * Kr(v)) / 4096): EndIf
        If v < 127: v = v + 1: EndIf
        M(Ix(k)) = (u * 256) + v
      Next
      If ma
        u = MS(im) / 256
        v = MS(im) % 256
        If y: u = u + (((65536 - u) * Kr(v)) / 4096): Else: u = u - ((u * Kr(v)) / 4096): EndIf
        If v < 127: v = v + 1: EndIf
        MS(im) = (u * 256) + v
      EndIf
      g = (y * 65536) + (y * 64) - (2 * y)
      Ap(ai) = Ap(ai) + (((g - Ap(ai)) * (128 - aw)) / 8192)
      Ap(ai + 1) = Ap(ai + 1) + (((g - Ap(ai + 1)) * aw) / 8192)
      Ap2(ai2) = Ap2(ai2) + (((g - Ap2(ai2)) * (128 - aw)) / 8192)
      Ap2(ai2 + 1) = Ap2(ai2 + 1) + (((g - Ap2(ai2 + 1)) * aw) / 8192)
      ef = ((y * 4096) - pf) * 2
      Wf(f + 0) = Wf(f + 0) + ((St(r1) * ef) / 32768)
      Wf(f + 1) = Wf(f + 1) + ((St(r2) * ef) / 32768)
      Wf(f + 2) = Wf(f + 2) + ((St(r3) * ef) / 32768)
      Wf(f + 3) = Wf(f + 3) + ((256 * ef) / 32768)
      Wf(f + 4) = Wf(f + 4) + ((St(r4) * ef) / 32768)
      Wf(f + 5) = Wf(f + 5) + ((St(r5) * ef) / 32768)
      c0 = (c0 * 2) + y
      While x1 / 16777216 = x2 / 16777216
        x1 = (x1 % 16777216) * 256
        x2 = ((x2 % 16777216) * 256) + 255
        x = (x % 16777216) * 256
        If ip < Z: x = x + PeekA(*C + ip): EndIf
        ip = ip + 1
      Wend
    Next
    c = c0 - 256
    PokeA(*D + pos, c)
    If pos >= P: chk = ((chk * 33) + c) % 1000000007: EndIf
    I1(h0) = ((I1(h0) * 256) + c) % 65536
    v = (Hi(1) * 256) + h0
    I2(v) = ((I2(v) * 256) + c) % 65536
    lt = 0
    If (c >= 48 And c <= 57) Or (c >= 65 And c <= 90) Or (c >= 97 And c <= 122) Or c = 95: lt = 1: EndIf
    l1 = 0
    If (h0 >= 48 And h0 <= 57) Or (h0 >= 65 And h0 <= 90) Or (h0 >= 97 And h0 <= 122) Or h0 = 95: l1 = 1: EndIf
    If c = 10
      tk = 0
    ElseIf c <> 32 And (lt = 0 Or l1 = 0)
      tk = tk + 1
    EndIf
    For k = 7 To 1 Step -1
      Hi(k) = Hi(k - 1)
    Next
    Hi(0) = c
    If c = 10
      If fw <> 0
        LF(fw % 65536) = ls
        LE(fw % 65536) = pos
      EndIf
      ppl = pl: pl = ls: ls = pos + 1: pfw = fw: fw = 0: fwf = 0: nd = 0: bd = 0
    EndIf
    If zn = 0
      If c = 40 And bd < 7
        bd = bd + 1
      ElseIf c = 41 And bd > 0
        bd = bd - 1
      EndIf
    EndIf
    If lt
      If wh = 0: wc = Hi(1): EndIf
      wh = ((((wh + c) + 1) * $6F4F2B) / 256) % $1000000
    Else
      If wh <> 0: wp = wh: EndIf
      wh = 0
    EndIf
    If c = 32 And fwf = 0 And fw = 0: nd = nd + 1: EndIf
    If fwf = 0
      If lt
        fw = (((((fw * 256) + c) + 1) * $6F4F2B) / 256) % $1000000
      ElseIf fw > 0
        fwf = 1
      EndIf
    EndIf
    If zn = 0
      If c = 59
        zn = 2
      ElseIf c = 34
        zn = 1
      EndIf
    ElseIf zn = 1
      If c = 34 Or c = 10: zn = 0: EndIf
    ElseIf c = 10
      zn = 0
    EndIf
  Next
  If EtatFin <> 0
    xm = 0
    Es(0) = i: Es(1) = u: Es(2) = v: Es(3) = ml: Es(4) = mp: Es(5) = ma: Es(6) = wh: Es(7) = wp
    Es(8) = wc: Es(9) = fw: Es(10) = fwf: Es(11) = pfw: Es(12) = nd: Es(13) = bd: Es(14) = tk: Es(15) = zn
    Es(16) = ls: Es(17) = pl: Es(18) = ppl: Es(19) = h0: Es(20) = h: Es(21) = k: Es(22) = hm: Es(23) = h8
    Es(24) = ab: Es(25) = u2: Es(26) = ab2: Es(27) = a: Es(28) = a1: Es(29) = a2: Es(30) = sr: Es(31) = sf
    Es(32) = a3: Es(33) = h16: Es(34) = b: Es(35) = c: Es(36) = c0: Es(37) = j: Es(38) = ws: Es(39) = ck
    Es(40) = pb: Es(41) = im: Es(42) = wi: Es(43) = wn: Es(44) = wz: Es(45) = wv: Es(46) = dot: Es(47) = dw
    Es(48) = dy: Es(49) = dz: Es(50) = dv: Es(51) = e: Es(52) = r1: Es(53) = r2: Es(54) = r3: Es(55) = r4
    Es(56) = r5: Es(57) = f: Es(58) = pf: Es(59) = pm: Es(60) = s: Es(61) = aw: Es(62) = ai: Es(63) = pa
    Es(64) = ai2: Es(65) = pa2: Es(66) = xm: Es(67) = y: Es(68) = er: Es(69) = e2: Es(70) = e3: Es(71) = e4
    Es(72) = e5: Es(73) = hb: Es(74) = si: Es(75) = n0: Es(76) = n1: Es(77) = hh: Es(78) = g: Es(79) = ef
    Es(80) = lt: Es(81) = l1
    crc = 0
    crc = EchangeTableauL(EtatFin, 1, M(), crc)
    crc = EchangeTableauA(EtatFin, 1, Bh(), crc)
    crc = EchangeTableauA(EtatFin, 1, Kc(), crc)
    crc = EchangeTableauQ(EtatFin, 1, SM(), crc)
    crc = EchangeTableauL(EtatFin, 1, MT(), crc)
    crc = EchangeTableauL(EtatFin, 1, MT2(), crc)
    crc = EchangeTableauL(EtatFin, 1, MT3(), crc)
    crc = EchangeTableauQ(EtatFin, 1, MS(), crc)
    crc = EchangeTableauQ(EtatFin, 1, W(), crc)
    crc = EchangeTableauQ(EtatFin, 1, Wx(), crc)
    crc = EchangeTableauQ(EtatFin, 1, Wc(), crc)
    crc = EchangeTableauQ(EtatFin, 1, Wz(), crc)
    crc = EchangeTableauQ(EtatFin, 1, Wv(), crc)
    crc = EchangeTableauQ(EtatFin, 1, Wf(), crc)
    crc = EchangeTableauQ(EtatFin, 1, Ap(), crc)
    crc = EchangeTableauQ(EtatFin, 1, Ap2(), crc)
    crc = EchangeTableauQ(EtatFin, 1, I1(), crc)
    crc = EchangeTableauQ(EtatFin, 1, I2(), crc)
    crc = EchangeTableauQ(EtatFin, 1, LF(), crc)
    crc = EchangeTableauQ(EtatFin, 1, LE(), crc)
    crc = EchangeTableauQ(EtatFin, 1, Hi(), crc)
    crc = EchangeTableauQ(EtatFin, 1, Hc(), crc)
    crc = EchangeTableauQ(EtatFin, 1, Ix(), crc)
    crc = EchangeTableauQ(EtatFin, 1, Sv(), crc)
    crc = EchangeTableauQ(EtatFin, 1, Es(), crc)
    EcrireControleEtat(EtatFin, crc)
  EndIf

  ProcedureReturn chk
EndProcedure
EnableDebugger


; ----------------------------------------------------------------------------
;  Y a-t-il assez de mémoire libre pour la méthode v4 ?
; ----------------------------------------------------------------------------
Procedure MemoireMethode4()
  Protected *Essai

  *Essai = AllocateMemory(#MemoireMethode4, #PB_Memory_NoClear)
  If *Essai
    FreeMemory(*Essai)
    ProcedureReturn #True
  EndIf
  ProcedureReturn #False
EndProcedure


; ----------------------------------------------------------------------------
;  Y a-t-il assez de mémoire pour deux modèles v4 à la fois (compression et
;  vérification en parallèle) ? Seulement si le programme est compilé avec
;  l'option « thread-safe ». Essai = #False: estimation rapide pour
;  l'affichage, sans essayer de réserver la mémoire.
; ----------------------------------------------------------------------------
Procedure ParalleleDisponible(Essai)
  Protected Ok
  CompilerIf #PB_Compiler_Thread
    Protected *Essai

    If MutexCM4 And MemoryStatus(#PB_System_FreePhysical) >= (2 * #MemoireMethode4) + (200 * 1024 * 1024)
      Ok = #True
      If Essai
        *Essai = AllocateMemory(2 * #MemoireMethode4, #PB_Memory_NoClear)
        If *Essai
          FreeMemory(*Essai)
        Else
          Ok = #False
        EndIf
      EndIf
    EndIf
  CompilerEndIf
  ProcedureReturn Ok
EndProcedure


; ----------------------------------------------------------------------------
;  Fichiers de l'état du modèle v4: un par niveau (de Moyen à Maximal), dans
;  les données locales de l'utilisateur (pas dans le profil itinérant de
;  Windows, à cause de leur taille). Au niveau Faible, relire le petit texte de
;  référence est plus rapide que relire 670 Mo: rien n'est gardé.
; ----------------------------------------------------------------------------
Procedure.s DossierEtat()
  Protected Dossier$

  Dossier$ = GetEnvironmentVariable("LOCALAPPDATA")
  If Dossier$ = ""
    Dossier$ = GetUserDirectory(#PB_Directory_ProgramData)
  EndIf
  If Right(Dossier$, 1) <> #PS$
    Dossier$ = Dossier$ + #PS$
  EndIf
  ProcedureReturn Dossier$ + "CompresseurPB" + #PS$
EndProcedure


Procedure.s FichierEtat(Niveau)
  ProcedureReturn DossierEtat() + "etat_v4_niveau" + Str(Niveau) + ".bin"
EndProcedure


; Le réglage est coché et le niveau est assez grand pour qu'un état serve
Procedure EtatUtile(Niveau)
  ProcedureReturn Bool(GarderEtat And Niveau >= #NiveauMoyen And Niveau <= #NiveauMaximal)
EndProcedure


; Empreinte du texte de référence d'un niveau (sommes de contrôle et tailles de
; ses segments), écrite dans l'en-tête
Procedure.q SignatureReference(Niveau)
  Protected Liste$, i, n
  Protected.q S

  LireTableReference()
  Liste$ = CompositionNiveau(Niveau)
  For i = 1 To CountString(Liste$, ",") + 1
    n = Val(StringField(Liste$, i, ","))
    S = ((S * 33) + SegmentControle(n)) % 1000000007
    S = ((S * 33) + (SegmentTaille(n) % 1000000007)) % 1000000007
  Next
  ProcedureReturn S
EndProcedure


Procedure.q TailleFichierEtat(Niveau)
  ProcedureReturn #TailleEnTeteEtat + TailleNiveau(Niveau) + #TailleEtatModele4
EndProcedure


; Lit et vérifie l'en-tête d'un fichier d'état ouvert (le fichier se trouve
; ensuite au début du texte de référence)
Procedure EnTeteEtatValide(Fichier, Niveau)
  If Lof(Fichier) <> TailleFichierEtat(Niveau)
    ProcedureReturn #False
  EndIf
  If ReadQuad(Fichier) <> #MagiqueEtat4
    ProcedureReturn #False
  EndIf
  If ReadQuad(Fichier) <> #VersionEtat4
    ProcedureReturn #False
  EndIf
  If ReadQuad(Fichier) <> #SignatureModele4
    ProcedureReturn #False
  EndIf
  If ReadQuad(Fichier) <> Niveau
    ProcedureReturn #False
  EndIf
  If ReadQuad(Fichier) <> TailleNiveau(Niveau)
    ProcedureReturn #False
  EndIf
  If ReadQuad(Fichier) <> SignatureReference(Niveau)
    ProcedureReturn #False
  EndIf
  If ReadQuad(Fichier) <> TailleFichierEtat(Niveau)
    ProcedureReturn #False
  EndIf
  If ReadQuad(Fichier) <> 0
    ProcedureReturn #False
  EndIf
  ProcedureReturn #True
EndProcedure


; Un état gardé et valable existe-t-il pour ce niveau ? (en-tête et taille)
Procedure EtatDisponible(Niveau)
  Protected Fichier, Ok

  If EtatUtile(Niveau) = #False
    ProcedureReturn #False
  EndIf
  If FileSize(FichierEtat(Niveau)) <> TailleFichierEtat(Niveau)
    ProcedureReturn #False
  EndIf
  Fichier = ReadFile(#PB_Any, FichierEtat(Niveau), #PB_File_SharedRead)
  If Fichier
    Ok = EnTeteEtatValide(Fichier, Niveau)
    CloseFile(Fichier)
  EndIf
  ProcedureReturn Ok
EndProcedure


; ----------------------------------------------------------------------------
;  Ouvre l'état d'un niveau pour le lire, et se place juste après le texte de
;  référence. Provisoire = #True: l'état tout juste écrit, pas encore contrôlé
;  (voir ValiderEtat). Si *Reference ne contient pas déjà ce niveau, le texte
;  de référence du fichier y est lu, et vérifié segment par segment avec les
;  sommes de contrôle du programme: il évite de décompresser les segments.
;  Renvoie le numéro du fichier, ou 0 (le fichier est effacé s'il est abîmé).
; ----------------------------------------------------------------------------
Procedure OuvrirEtat(Niveau, Provisoire = #False)
  Protected Fichier, Liste$, i, n, Ok, Abime, Nom$
  Protected.q P, Position
  Protected *Texte

  If EtatUtile(Niveau) = #False
    ProcedureReturn 0
  EndIf
  Nom$ = FichierEtat(Niveau)
  If Provisoire
    Nom$ = Nom$ + ".tmp"
  EndIf
  If FileSize(Nom$) <> TailleFichierEtat(Niveau)
    ProcedureReturn 0
  EndIf
  Fichier = ReadFile(#PB_Any, Nom$, #PB_File_SharedRead)
  If Fichier = 0
    ProcedureReturn 0
  EndIf
  If EnTeteEtatValide(Fichier, Niveau) = #False
    CloseFile(Fichier)
    ProcedureReturn 0
  EndIf

  P = TailleNiveau(Niveau)
  EtatOctets = 0
  If *Reference And NiveauReference = Niveau
    FileSeek(Fichier, #TailleEnTeteEtat + P)
    ProcedureReturn Fichier
  EndIf

  AfficherEtape("Lecture du texte de référence gardé sur le disque (" + Str((P + 524288) / 1048576) + " Mo), et vérification...")
  *Texte = AllocateMemory(P + 16)
  If *Texte
    Abime = #True
    If ReadData(Fichier, *Texte, P) = P
      Abime = #False
      Liste$ = CompositionNiveau(Niveau)
      For i = 1 To CountString(Liste$, ",") + 1
        n = Val(StringField(Liste$, i, ","))
        If Controle(*Texte + Position, SegmentTaille(n)) <> SegmentControle(n)
          Abime = #True
        EndIf
        Position = Position + SegmentTaille(n)
      Next
    EndIf
    Ok = Bool(Abime = #False)
  EndIf

  If Ok = #False
    CloseFile(Fichier)
    If *Texte
      FreeMemory(*Texte)
    EndIf
    If Abime
      DeleteFile(Nom$)
    EndIf
    ProcedureReturn 0
  EndIf

  If *Reference
    FreeMemory(*Reference)
  EndIf
  *Reference = *Texte
  TailleReference = P
  NiveauReference = Niveau
  ProcedureReturn Fichier
EndProcedure


; ----------------------------------------------------------------------------
;  Crée le fichier provisoire (.tmp) où la méthode v4 écrira l'état, avec
;  l'en-tête et le texte de référence du niveau (*Texte, Taille octets).
;  Renvoie le numéro du fichier, ou 0.
; ----------------------------------------------------------------------------
Procedure CreerEtatAvec(Niveau, *Texte, Taille.q, Message$)
  Protected Fichier, Ok, Nom$

  If EtatUtile(Niveau) = #False Or *Texte = 0 Or Taille <> TailleNiveau(Niveau)
    ProcedureReturn 0
  EndIf
  Nom$ = FichierEtat(Niveau) + ".tmp"
  CreateDirectory(DossierEtat())           ; (s'il existe déjà, rien ne change)
  Fichier = CreateFile(#PB_Any, Nom$)
  If Fichier = 0
    ProcedureReturn 0
  EndIf
  EtatOctets = 0
  AfficherEtape(Message$)
  Ok = #True
  If WriteQuad(Fichier, #MagiqueEtat4) = 0
    Ok = #False
  EndIf
  If WriteQuad(Fichier, #VersionEtat4) = 0
    Ok = #False
  EndIf
  If WriteQuad(Fichier, #SignatureModele4) = 0
    Ok = #False
  EndIf
  If WriteQuad(Fichier, Niveau) = 0
    Ok = #False
  EndIf
  If WriteQuad(Fichier, TailleNiveau(Niveau)) = 0
    Ok = #False
  EndIf
  If WriteQuad(Fichier, SignatureReference(Niveau)) = 0
    Ok = #False
  EndIf
  If WriteQuad(Fichier, TailleFichierEtat(Niveau)) = 0
    Ok = #False
  EndIf
  If WriteQuad(Fichier, 0) = 0
    Ok = #False
  EndIf
  If WriteData(Fichier, *Texte, Taille) <> Taille
    Ok = #False
  EndIf
  If Ok = #False
    CloseFile(Fichier)
    DeleteFile(Nom$)
    ProcedureReturn 0
  EndIf
  EcritureEtatRatee = #False
  ProcedureReturn Fichier
EndProcedure


; Fichier provisoire de l'état d'un niveau, avec le texte de référence en mémoire
; (*Reference doit contenir ce niveau)
Procedure CreerEtat(Niveau)
  If *Reference = 0 Or NiveauReference <> Niveau
    ProcedureReturn 0
  EndIf
  ProcedureReturn CreerEtatAvec(Niveau, *Reference, TailleReference, "Écriture du texte de référence sur le disque (" + Str((TailleReference + 524288) / 1048576) + " Mo)...")
EndProcedure


; Ferme le fichier provisoire écrit par la méthode v4. Renvoie #True s'il est
; complet ; sinon (disque plein...) il est effacé.
Procedure FermerEtatEcrit(Fichier, Niveau)
  CloseFile(Fichier)
  If EcritureEtatRatee = #False And FileSize(FichierEtat(Niveau) + ".tmp") = TailleFichierEtat(Niveau)
    ProcedureReturn #True
  EndIf
  DeleteFile(FichierEtat(Niveau) + ".tmp")
  ProcedureReturn #False
EndProcedure


; Ferme un état lu ; s'il s'est révélé abîmé, il est effacé (l'opération, elle,
; est repartie du texte de référence et reste juste). Renvoie #True si l'état
; a bien été relu.
Procedure FermerEtatLu(Fichier, Niveau)
  CloseFile(Fichier)
  If EtatAbime
    AfficherEtape("L'état du modèle gardé sur le disque était abîmé: il est effacé (il sera refait la prochaine fois).")
    DeleteFile(FichierEtat(Niveau))
    EtatAbime = #False
    ProcedureReturn #False
  EndIf
  ProcedureReturn #True
EndProcedure


; ----------------------------------------------------------------------------
;  Contrôle de l'état tout juste écrit (fichier provisoire): la méthode v4 le
;  relit et refait la décompression de *C (Z octets). Il n'est gardé que si
;  elle redonne exactement *Attendu (T octets). Un état gardé a donc toujours
;  donné au moins une fois le même résultat que la lecture du texte de
;  référence. Renvoie 1 si la décompression est juste, 0 si elle est fausse,
;  -1 si l'état n'a pas pu être relu (dans les deux derniers cas, il est effacé).
; ----------------------------------------------------------------------------
Procedure ValiderEtat(Niveau, *C, Z.q, T.q, *Attendu, Etape$)
  Protected Fichier, Resultat, Mesurable
  Protected.q Debut
  Protected *D

  Resultat = -1
  EtatAbime = #False
  Fichier = OuvrirEtat(Niveau, #True)
  If Fichier
    *D = AllocateMemory(TailleReference + T + 16)
    If *D
      CopyMemory(*Reference, *D, TailleReference)
      ; (ce contrôle ne compte pas dans la mesure de la vitesse de ce PC)
      Mesurable = ProgresMesurable
      Debut = ElapsedMilliseconds()
      CommencerPasse(Etape$, 4, TailleReference)
      DecoderCM4(*C, Z, T, *D, TailleReference, Fichier, 0)
      TerminerPasse(T)
      ProgresMesurable = Mesurable
      ProgresHorsTemps = ProgresHorsTemps + (ElapsedMilliseconds() - Debut)
      ProgresHorsUnites = ProgresHorsUnites + (T * 4)
      If EtatAbime = #False
        Resultat = Bool(CompareMemory(*D + TailleReference, *Attendu, T))
      EndIf
      FreeMemory(*D)
    EndIf
    CloseFile(Fichier)
  EndIf
  EtatAbime = #False
  If Resultat = 1
    DeleteFile(FichierEtat(Niveau))        ; un ancien état (abîmé, ou d'une autre version)
    If RenameFile(FichierEtat(Niveau) + ".tmp", FichierEtat(Niveau))
      EtatCree = #True
      ProcedureReturn 1
    EndIf
  EndIf
  DeleteFile(FichierEtat(Niveau) + ".tmp")
  ProcedureReturn Resultat
EndProcedure


; ----------------------------------------------------------------------------
;  Texte de référence (depuis la v6.4): fichier de référence à côté du
;  programme, et texte décompressé gardé sur le disque.
;  Le fichier contient tous les segments dans l'ordre du niveau Maximal
;  (CompositionNiveau), le segment 0 en premier: le niveau Faible et les
;  formats PBC2 et PBC3 n'ont besoin que de son début.
; ----------------------------------------------------------------------------

; Texte décompressé gardé sur le disque: en-tête de 32 octets (marque, version,
; empreinte et taille du texte), puis le texte, dans l'ordre du niveau Maximal
Procedure.s FichierTexteReference()
  ProcedureReturn DossierEtat() + "texte_reference_v4.bin"
EndProcedure


Procedure.q TailleTexteGarde()
  ProcedureReturn 32 + TailleNiveau(#NiveauMaximal)
EndProcedure


; Le texte décompressé est-il gardé sur le disque ? (taille et en-tête)
Procedure TexteGardeDisponible()
  Protected Fichier, Ok

  If FileSize(FichierTexteReference()) <> TailleTexteGarde()
    ProcedureReturn #False
  EndIf
  Fichier = ReadFile(#PB_Any, FichierTexteReference(), #PB_File_SharedRead)
  If Fichier
    Ok = #True
    If ReadQuad(Fichier) <> #MagiqueTexteReference
      Ok = #False
    EndIf
    If ReadQuad(Fichier) <> #VersionReference
      Ok = #False
    EndIf
    If ReadQuad(Fichier) <> SignatureReference(#NiveauMaximal)
      Ok = #False
    EndIf
    If ReadQuad(Fichier) <> TailleNiveau(#NiveauMaximal)
      Ok = #False
    EndIf
    CloseFile(Fichier)
  EndIf
  ProcedureReturn Ok
EndProcedure


; Vérifie les Nombre premiers segments d'un texte rangé dans l'ordre du niveau
; Maximal, puis les met à disposition (SegmentAdresse pointe dans *Texte, qui
; reste en mémoire jusqu'à la fin du programme). Renvoie #False si un segment ne
; correspond pas à sa somme de contrôle (rien n'est alors changé).
Procedure RangerSegments(*Texte, Nombre)
  Protected Liste$, i, n
  Protected.q Position

  Liste$ = CompositionNiveau(#NiveauMaximal)
  For i = 1 To Nombre
    n = Val(StringField(Liste$, i, ","))
    If Controle(*Texte + Position, SegmentTaille(n)) <> SegmentControle(n)
      ProcedureReturn #False
    EndIf
    Position = Position + SegmentTaille(n)
  Next
  Position = 0
  For i = 1 To Nombre
    n = Val(StringField(Liste$, i, ","))
    If SegmentAdresse(n) = 0
      SegmentAdresse(n) = *Texte + Position
    EndIf
    Position = Position + SegmentTaille(n)
  Next
  ProcedureReturn #True
EndProcedure


; Relit le texte gardé sur le disque (environ 11 Mo, en une seconde). Renvoie
; #True si tous les segments sont alors en mémoire. Un texte abîmé est effacé.
Procedure LireTexteGarde()
  Protected Fichier, Ok, Lu
  Protected.q T
  Protected *Texte

  If TexteGardeDisponible() = #False
    ProcedureReturn #False
  EndIf
  T = TailleNiveau(#NiveauMaximal)
  Fichier = ReadFile(#PB_Any, FichierTexteReference(), #PB_File_SharedRead)
  If Fichier = 0
    ProcedureReturn #False
  EndIf
  AfficherEtape("Lecture du texte de référence gardé sur le disque (" + Str((T + 524288) / 1048576) + " Mo), et vérification...")
  *Texte = AllocateMemory(T + 16)
  If *Texte
    FileSeek(Fichier, 32)
    If ReadData(Fichier, *Texte, T) = T
      Lu = #True
      Ok = RangerSegments(*Texte, #NbSegments)
    EndIf
  EndIf
  CloseFile(Fichier)
  If Ok = #False
    If *Texte
      FreeMemory(*Texte)
    EndIf
    If Lu
      DeleteFile(FichierTexteReference())    ; abîmé: il sera refait
    EndIf
  EndIf
  ProcedureReturn Ok
EndProcedure


; Garde sur le disque le texte qui vient d'être décompressé (et vérifié)
Procedure EcrireTexteGarde(*Texte, T.q)
  Protected Fichier, Ok, Nom$

  Nom$ = FichierTexteReference() + ".tmp"
  CreateDirectory(DossierEtat())
  Fichier = CreateFile(#PB_Any, Nom$)
  If Fichier = 0
    ProcedureReturn #False
  EndIf
  AfficherEtape("Écriture du texte de référence décompressé sur le disque (" + Str((T + 524288) / 1048576) + " Mo)...")
  Ok = #True
  If WriteQuad(Fichier, #MagiqueTexteReference) = 0
    Ok = #False
  EndIf
  If WriteQuad(Fichier, #VersionReference) = 0
    Ok = #False
  EndIf
  If WriteQuad(Fichier, SignatureReference(#NiveauMaximal)) = 0
    Ok = #False
  EndIf
  If WriteQuad(Fichier, T) = 0
    Ok = #False
  EndIf
  If WriteData(Fichier, *Texte, T) <> T
    Ok = #False
  EndIf
  CloseFile(Fichier)
  If Ok And FileSize(Nom$) = TailleTexteGarde()
    DeleteFile(FichierTexteReference())
    Ok = Bool(RenameFile(Nom$, FichierTexteReference()) <> 0)
  Else
    Ok = #False
  EndIf
  If Ok = #False
    DeleteFile(Nom$)
  EndIf
  ProcedureReturn Ok
EndProcedure


; L'état gardé du niveau Maximal (fait par la v6.3 ou plus tard) contient aussi
; tout le texte, juste après son en-tête: le relire évite de décompresser le
; fichier de référence. Cet état est-il là (taille et en-tête) ?
Procedure TexteDansEtatMaximal()
  Protected Fichier, Ok

  If FileSize(FichierEtat(#NiveauMaximal)) <> TailleFichierEtat(#NiveauMaximal)
    ProcedureReturn #False
  EndIf
  Fichier = ReadFile(#PB_Any, FichierEtat(#NiveauMaximal), #PB_File_SharedRead)
  If Fichier
    Ok = EnTeteEtatValide(Fichier, #NiveauMaximal)
    CloseFile(Fichier)
  EndIf
  ProcedureReturn Ok
EndProcedure


; Relit le texte dans l'état gardé du niveau Maximal, le vérifie, et le garde
; aussi à part pour les fois suivantes. Renvoie #True si tous les segments sont
; alors en mémoire.
Procedure LireTexteDepuisEtatMaximal()
  Protected Fichier, Ok
  Protected.q T
  Protected *Texte

  If TexteDansEtatMaximal() = #False
    ProcedureReturn #False
  EndIf
  Fichier = ReadFile(#PB_Any, FichierEtat(#NiveauMaximal), #PB_File_SharedRead)
  If Fichier = 0
    ProcedureReturn #False
  EndIf
  If EnTeteEtatValide(Fichier, #NiveauMaximal)
    T = TailleNiveau(#NiveauMaximal)
    AfficherEtape("Lecture du texte de référence dans l'état gardé du niveau Maximal (" + Str((T + 524288) / 1048576) + " Mo), et vérification...")
    *Texte = AllocateMemory(T + 16)
    If *Texte
      If ReadData(Fichier, *Texte, T) = T
        Ok = RangerSegments(*Texte, #NbSegments)
      EndIf
    EndIf
  EndIf
  CloseFile(Fichier)
  If Ok
    EcrireTexteGarde(*Texte, T)
  ElseIf *Texte
    FreeMemory(*Texte)
  EndIf
  ProcedureReturn Ok
EndProcedure


; Où est le fichier de référence ? À côté du programme ; sinon à côté du code
; source compilé (avec F5, le programme est lancé depuis un dossier temporaire) ;
; sinon là où l'utilisateur l'a indiqué une fois. "" s'il est introuvable.
Procedure.s TrouverFichierReference()
  Protected Chemin$

  Chemin$ = GetPathPart(ProgramFilename()) + #NomFichierReference$
  If FileSize(Chemin$) > 0
    ProcedureReturn Chemin$
  EndIf
  Chemin$ = #PB_Compiler_FilePath
  If Right(Chemin$, 1) <> #PS$
    Chemin$ = Chemin$ + #PS$
  EndIf
  Chemin$ = Chemin$ + #NomFichierReference$
  If FileSize(Chemin$) > 0
    ProcedureReturn Chemin$
  EndIf
  If CheminReferenceChoisi$ <> ""
    If FileSize(CheminReferenceChoisi$) > 0
      ProcedureReturn CheminReferenceChoisi$
    EndIf
  EndIf
  ProcedureReturn ""
EndProcedure


; Demande où se trouve le fichier de référence (le chemin est gardé dans les réglages)
Procedure.s ChoisirFichierReference()
  Protected Chemin$

  Chemin$ = OpenFileRequester("Fichier « " + #NomFichierReference$ + " » introuvable: où est-il ?", #NomFichierReference$, "Fichier de référence (*.dat)|*.dat|Tous les fichiers (*.*)|*.*", 0)
  If Chemin$ <> ""
    CheminReferenceChoisi$ = Chemin$
  EndIf
  ProcedureReturn Chemin$
EndProcedure


; Termine l'état du niveau Maximal écrit à la fin de la décompression du fichier
; de référence: le texte est écrit à sa place (juste après l'en-tête), puis
; l'état n'est gardé que s'il est complet et que sa somme de contrôle est
; exactement celle calculée à la fabrication du fichier (#ControleEtatMaximal).
Procedure FinirEtatPrepare(Fichier, *Texte, T.q)
  Protected Ok, Nom$, Lecture

  Nom$ = FichierEtat(#NiveauMaximal) + ".tmp"
  Ok = Bool(EcritureEtatRatee = #False)
  FileSeek(Fichier, #TailleEnTeteEtat)
  If WriteData(Fichier, *Texte, T) <> T
    Ok = #False
  EndIf
  CloseFile(Fichier)
  If Ok
    Ok = #False
    If FileSize(Nom$) = TailleFichierEtat(#NiveauMaximal)
      Lecture = ReadFile(#PB_Any, Nom$, #PB_File_SharedRead)
      If Lecture
        If EnTeteEtatValide(Lecture, #NiveauMaximal)
          FileSeek(Lecture, TailleFichierEtat(#NiveauMaximal) - 8)
          Ok = Bool(ReadQuad(Lecture) = #ControleEtatMaximal)
          If Ok = #False
            EtatMaximalRefuse = #True
          EndIf
        EndIf
        CloseFile(Lecture)
      EndIf
    EndIf
  EndIf
  If Ok
    DeleteFile(FichierEtat(#NiveauMaximal))
    Ok = Bool(RenameFile(Nom$, FichierEtat(#NiveauMaximal)) <> 0)
  EndIf
  If Ok = #False
    DeleteFile(Nom$)
  EndIf
  ProcedureReturn Ok
EndProcedure


; ----------------------------------------------------------------------------
;  Décompresse le fichier de référence: en entier (Tout = #True), ou seulement
;  son début (segment 0). En entier, le modèle a lu tout le texte du niveau
;  Maximal: son état est écrit au passage (si le réglage le permet) et gardé
;  s'il est exact (FinirEtatPrepare), et le texte est gardé sur le disque.
;  Renvoie #False en cas d'échec (raison dans ErreurReference$).
; ----------------------------------------------------------------------------
Procedure DecompresserFichierReference(Tout)
  Protected Chemin$, Fichier, FichierFin, i, n, Ok, Liste$, Etape$
  Protected.q Z, T, Taille
  Protected *C, *D

  If MemoireMethode4() = #False
    ErreurReference$ = "Mémoire insuffisante pour décompresser le fichier de référence (environ 700 Mo de mémoire libre nécessaires)."
    ProcedureReturn #False
  EndIf
  Chemin$ = TrouverFichierReference()
  If Chemin$ = ""
    Chemin$ = ChoisirFichierReference()
  EndIf
  If Chemin$ = ""
    ErreurReference$ = "Le fichier « " + #NomFichierReference$ + " » est introuvable: il doit être à côté du programme."
    ProcedureReturn #False
  EndIf
  Fichier = ReadFile(#PB_Any, Chemin$, #PB_File_SharedRead)
  If Fichier = 0
    ErreurReference$ = "Impossible d'ouvrir le fichier de référence: " + Chemin$
    ProcedureReturn #False
  EndIf

  ; En-tête: tout doit correspondre à ce programme (méthode, segments, tailles,
  ; sommes de contrôle)
  LireTableReference()
  Liste$ = CompositionNiveau(#NiveauMaximal)
  Taille = TailleNiveau(#NiveauMaximal)
  Ok = #True
  If ReadQuad(Fichier) <> #MagiqueReference
    Ok = #False
  EndIf
  If ReadQuad(Fichier) <> #VersionReference
    Ok = #False
  EndIf
  If ReadQuad(Fichier) <> #SignatureModele4
    Ok = #False
  EndIf
  If ReadQuad(Fichier) <> #NbSegments
    Ok = #False
  EndIf
  If ReadQuad(Fichier) <> Taille
    Ok = #False
  EndIf
  Z = ReadQuad(Fichier)
  If ReadQuad(Fichier) <> SignatureReference(#NiveauMaximal)
    Ok = #False
  EndIf
  ReadQuad(Fichier)
  For i = 1 To #NbSegments
    n = Val(StringField(Liste$, i, ","))
    If ReadQuad(Fichier) <> n
      Ok = #False
    EndIf
    If ReadQuad(Fichier) <> SegmentTaille(n)
      Ok = #False
    EndIf
    If ReadQuad(Fichier) <> SegmentControle(n)
      Ok = #False
    EndIf
  Next
  If Z <= 0 Or Lof(Fichier) <> #TailleEnTeteReference + (24 * #NbSegments) + Z
    Ok = #False
  EndIf
  If Ok
    *C = AllocateMemory(Z + 16)
    If *C
      If ReadData(Fichier, *C, Z) <> Z
        Ok = #False
      EndIf
    EndIf
  EndIf
  CloseFile(Fichier)
  If Ok = #False
    If *C
      FreeMemory(*C)
    EndIf
    ErreurReference$ = "Le fichier « " + GetFilePart(Chemin$) + " » ne correspond pas à cette version du programme, ou il est abîmé." + #LF$ + "Utilise celui livré avec ce programme."
    ProcedureReturn #False
  EndIf

  ; Décompression: tout, ou seulement le segment 0 (le premier du fichier)
  T = Taille
  If Tout = #False
    T = SegmentTaille(Val(StringField(Liste$, 1, ",")))
  EndIf
  *D = AllocateMemory(T + 16)
  If *C = 0 Or *D = 0
    If *C
      FreeMemory(*C)
    EndIf
    If *D
      FreeMemory(*D)
    EndIf
    ErreurReference$ = "Mémoire insuffisante pour le texte de référence."
    ProcedureReturn #False
  EndIf
  ; En entier, l'état du niveau Maximal est préparé au passage: le fichier
  ; provisoire reçoit d'abord l'en-tête et la place du texte (encore vide), la
  ; méthode v4 y écrit l'état à la fin, puis le texte est écrit à sa place
  FichierFin = 0
  If Tout And EtatUtile(#NiveauMaximal)
    If EtatDisponible(#NiveauMaximal) = #False
      FichierFin = CreerEtatAvec(#NiveauMaximal, *D, T, "Préparation du fichier d'état du niveau Maximal...")
    EndIf
  EndIf
  If Tout
    Etape$ = "Décompression du fichier de référence (une seule fois sur ce PC)"
  Else
    Etape$ = "Décompression du début du fichier de référence"
  EndIf
  CommencerPasse(Etape$, 4)
  DecoderReferenceCM4(*C, Z, T, *D, 0, 0, 0, FichierFin)
  TerminerPasse(T)
  FreeMemory(*C)
  ReferenceDecompressee = 1 + Bool(Tout)
  If Tout
    Ok = RangerSegments(*D, #NbSegments)
  Else
    Ok = RangerSegments(*D, 1)
  EndIf
  If FichierFin
    If Ok
      EtatMaximalPrepare = FinirEtatPrepare(FichierFin, *D, T)
    Else
      CloseFile(FichierFin)
      DeleteFile(FichierEtat(#NiveauMaximal) + ".tmp")
    EndIf
  EndIf
  If Ok = #False
    FreeMemory(*D)
    ErreurReference$ = "Le fichier de référence ne redonne pas le bon texte: il est abîmé." + #LF$ + "Remplace-le par celui livré avec ce programme."
    ProcedureReturn #False
  EndIf
  If Tout
    EcrireTexteGarde(*D, T)
  EndIf
  ProcedureReturn #True
EndProcedure


; Ce qui manque en mémoire pour une liste de segments: 0 = rien, 1 = seulement
; le segment 0 (le début du fichier suffit), 2 = d'autres segments
Procedure BesoinSegments(Liste$)
  Protected i, n, Besoin

  LireTableReference()
  For i = 1 To CountString(Liste$, ",") + 1
    n = Val(StringField(Liste$, i, ","))
    If SegmentAdresse(n) = 0
      If n = 0
        If Besoin = 0
          Besoin = 1
        EndIf
      Else
        Besoin = 2
      EndIf
    EndIf
  Next
  ProcedureReturn Besoin
EndProcedure


; Met en mémoire les segments d'une liste: depuis le texte gardé sur le disque
; (à part, ou dans l'état gardé du niveau Maximal), sinon en décompressant le
; fichier de référence (son début, ou tout)
Procedure ChargerSegments(Liste$)
  Protected Besoin

  Besoin = BesoinSegments(Liste$)
  If Besoin = 0
    ProcedureReturn #True
  EndIf
  If LireTexteGarde()
    ProcedureReturn #True
  EndIf
  If LireTexteDepuisEtatMaximal()
    ProcedureReturn #True
  EndIf
  ProcedureReturn DecompresserFichierReference(Bool(Besoin = 2))
EndProcedure


; ----------------------------------------------------------------------------
;  Assemble le texte de référence d'un niveau dans *Reference (TailleReference
;  octets). Renvoie #False si le texte ne peut pas être lu (raison dans
;  ErreurReference$) ou si la mémoire manque.
;  Les formats PBC2 et PBC3 utilisent le niveau Faible (l'ancien texte seul).
; ----------------------------------------------------------------------------
Procedure ConstruireReference(Niveau)
  Protected Liste$, i, n
  Protected.q Position

  If *Reference And NiveauReference = Niveau
    ProcedureReturn #True
  EndIf
  ErreurReference$ = ""
  Liste$ = CompositionNiveau(Niveau)
  If ChargerSegments(Liste$) = #False
    If ErreurReference$ = ""
      ErreurReference$ = "Le texte de référence n'a pas pu être lu."
    EndIf
    ProcedureReturn #False
  EndIf

  If *Reference
    FreeMemory(*Reference)
  EndIf
  NiveauReference = -1
  TailleReference = 0
  *Reference = AllocateMemory(TailleNiveau(Niveau) + 16)
  If *Reference = 0
    ErreurReference$ = "Mémoire insuffisante pour le texte de référence du niveau " + NomNiveau(Niveau) + "."
    ProcedureReturn #False
  EndIf
  For i = 1 To CountString(Liste$, ",") + 1
    n = Val(StringField(Liste$, i, ","))
    CopyMemory(SegmentAdresse(n), *Reference + Position, SegmentTaille(n))
    Position = Position + SegmentTaille(n)
  Next
  TailleReference = Position
  NiveauReference = Niveau
  ProcedureReturn #True
EndProcedure


; ----------------------------------------------------------------------------
;  Travail prévu (unités de la barre de progression) pour avoir en mémoire le
;  texte de référence d'un niveau: 0 s'il y est déjà ou s'il est gardé sur le
;  disque, sinon la décompression du fichier de référence (son début, ou tout).
; ----------------------------------------------------------------------------
Procedure.q TravailReference(Niveau)
  Protected Besoin

  Besoin = BesoinSegments(CompositionNiveau(Niveau))
  If Besoin = 0
    ProcedureReturn 0
  EndIf
  If TexteGardeDisponible() Or TexteDansEtatMaximal()
    ProcedureReturn 0
  EndIf
  If Besoin = 1
    ProcedureReturn SegmentTaille(0) * 4
  EndIf
  ProcedureReturn TailleNiveau(#NiveauMaximal) * 4
EndProcedure


; Le modèle relira-t-il un état pour ce niveau ? Soit un état gardé, soit celui
; du niveau Maximal, préparé en décompressant tout le fichier de référence.
Procedure EtatPrevu(Niveau)
  If EtatDisponible(Niveau)
    ProcedureReturn #True
  EndIf
  If Niveau = #NiveauMaximal And EtatUtile(Niveau)
    ProcedureReturn Bool(TravailReference(Niveau) > 0)
  EndIf
  ProcedureReturn #False
EndProcedure


; Travail avant une passe qui relit l'état prévu: la décompression du fichier
; de référence, quand c'est elle qui prépare cet état
Procedure.q TravailAvant(Niveau)
  If EtatDisponible(Niveau)
    ProcedureReturn 0
  EndIf
  ProcedureReturn TravailReference(Niveau)
EndProcedure


; ----------------------------------------------------------------------------
;  Prépare une opération de la méthode v4: le texte de référence du niveau et,
;  si le réglage le permet, l'état du modèle à relire (FichierEtatLu) ou, à
;  défaut, à écrire (FichierEtatEcrit, fichier provisoire). Renvoie #False si
;  le texte de référence ne peut pas être préparé (raison dans
;  ErreurReference$).
; ----------------------------------------------------------------------------
Procedure PreparerNiveau(Niveau)
  FichierEtatLu = 0
  FichierEtatEcrit = 0
  EtatAbime = #False
  If EtatUtile(Niveau)
    FichierEtatLu = OuvrirEtat(Niveau)
  EndIf
  If FichierEtatLu = 0
    If ConstruireReference(Niveau) = #False
      ProcedureReturn #False
    EndIf
    ; La décompression du fichier de référence vient peut-être de préparer l'état
    ; de ce niveau (niveau Maximal)
    If EtatUtile(Niveau)
      FichierEtatLu = OuvrirEtat(Niveau)
    EndIf
    If FichierEtatLu = 0
      FichierEtatEcrit = CreerEtat(Niveau)
    EndIf
  EndIf
  ProcedureReturn #True
EndProcedure


; ----------------------------------------------------------------------------
;  Travail prévu (en unités de la barre de progression) pour une passe de la
;  méthode v4 qui relit l'état (Relu = #True) ou le texte de référence.
; ----------------------------------------------------------------------------
Procedure.q TravailPasse4(T.q, Niveau, Relu)
  If Relu
    ProcedureReturn T * 4
  EndIf
  ProcedureReturn TravailReference(Niveau) + TravailMethode4(T, Niveau)
EndProcedure


; ----------------------------------------------------------------------------
;  Le texte est-il un nombre entier positif (uniquement des chiffres) ?
; ----------------------------------------------------------------------------
Procedure EstNombre(Texte$)
  Protected i

  If Texte$ = "" Or Len(Texte$) > 12
    ProcedureReturn #False
  EndIf
  For i = 1 To Len(Texte$)
    If FindString("0123456789", Mid(Texte$, i, 1)) = 0
      ProcedureReturn #False
    EndIf
  Next
  ProcedureReturn #True
EndProcedure


; ----------------------------------------------------------------------------
;  Le texte (qui commence par PBC1; à PBC8;) est-il un en-tête complet et
;  bien formé ? Évite de prendre pour un bloc un simple "PBC1;" écrit dans un
;  code source ou un message.
; ----------------------------------------------------------------------------
Procedure EnTeteTexteValide(Texte$)
  Protected Methode$, Encodage$

  Methode$  = StringField(Texte$, 2, ";")
  Encodage$ = StringField(Texte$, 3, ";")
  If (Methode$ = "L" Or Methode$ = "M") And (Encodage$ = "U" Or Encodage$ = "B")
    If EstNombre(StringField(Texte$, 4, ";")) And EstNombre(StringField(Texte$, 5, ";")) And EstNombre(StringField(Texte$, 6, ";"))
      ProcedureReturn #True
    EndIf
  EndIf
  ProcedureReturn #False
EndProcedure


; ----------------------------------------------------------------------------
;  Lit un bloc "données seules" et renvoie le code d'origine ("" si échec,
;  avec la raison dans ErreurDecompression$).
;  Deux présentations possibles:
;  - Format compact: uniquement des caractères Unicode (voir #MarqueCompacte).
;  - Format texte:  PBCx;Méthode;Encodage;Taille;TailleCompressée;Contrôle;données;FIN
;      PBC1: Méthode L = LZMA, ou M = Maximal (version 1)
;      PBC2: Méthode M = Maximal version 2 (avec le texte de référence)
;      PBC3: Méthode M = Maximal version 3 (avec le texte de référence)
;      PBC4 à PBC8: Méthode M = Maximal version 4, niveaux Moyen (4), Faible (5),
;                    Normal (6), Élevé (7), Maximal (8)
;      Encodage: U = Unicode, B = Base64
; ----------------------------------------------------------------------------
Procedure.s DecompresserBloc(Texte$)
  Protected Position, Debut, Version, TailleTampon, Methode$, Encodage$, Donnees$, Resultat$, Candidat$, Protection, Attendu
  Protected PropreProgression, Etape$, Niveau, Raccourci, Pret, Reussi, EtatEcrit
  Protected.q T, Z, K, N, Decalage, Origine
  Protected *C, *D

  ErreurDecompression$ = ""
  BlocReconnu = #False
  BlocProtege = #False

  ; Format texte: on cherche un PBC1; à PBC8; suivi d'un en-tête bien formé
  Position = 0
  Debut = FindString(Texte$, "PBC")
  While Debut
    Candidat$ = Mid(Texte$, Debut, 5)
    If Left(Candidat$, 3) = "PBC" And Right(Candidat$, 1) = ";" And FindString("12345678", Mid(Candidat$, 4, 1))
      If EnTeteTexteValide(Mid(Texte$, Debut, 200))
        Position = Debut
        Version = Val(Mid(Texte$, Debut + 3, 1))
        Break
      EndIf
    EndIf
    Debut = FindString(Texte$, "PBC", Debut + 1)
  Wend

  If Position = 0
    ; Pas d'en-tête PBC texte: format compact, uniquement des caractères Unicode
    Donnees$ = GarderCaracteresUnicode(Texte$)

    ; Bloc protégé contre les erreurs: on le répare d'abord (s'il le faut)
    If Len(Donnees$) > 8 And ValeurUnicode(Asc(Left(Donnees$, 1))) <> #MarqueCompacte
      Protection = EstBlocProtege(Donnees$)
      If Protection = 2
        BlocReconnu = #True
        ErreurDecompression$ = "Ce bloc a été protégé avec la version 5.3, dont le format n'est plus lu." + #LF$ + "Ouvre-le avec la version 5.3."
        ProcedureReturn ""
      ElseIf Protection = 1
        BlocReconnu = #True
        BlocProtege = #True
        Donnees$ = ReparerBloc(Donnees$)
        If Donnees$ = ""
          ProcedureReturn ""
        EndIf
      EndIf
    EndIf

    If Len(Donnees$) <= 8 Or ValeurUnicode(Asc(Left(Donnees$, 1))) <> #MarqueCompacte
      If FindString(#LF$ + Texte$, #LF$ + "; Code PureBasic compressé - lancez-le") Or FindString(#LF$ + Texte$, #LF$ + "; Compressed PureBasic code - run it")
        ErreurDecompression$ = "Ce texte est un code auto-extractible: colle-le dans PureBasic et lance-le (F5)."
      Else
        ErreurDecompression$ = "Ce texte n'est pas un bloc compressé."
      EndIf
      ProcedureReturn ""
    EndIf
    BlocReconnu = #True
    Select ValeurUnicode(Asc(Mid(Donnees$, 2, 1)))
      Case 1
        Methode$ = "L"
        Version = 1
      Case 2
        Methode$ = "M"
        Version = 2
      Case 3
        Methode$ = "M"
        Version = 3
      Case 4, 5, 6, 7, 8
        Methode$ = "M"
        Version = ValeurUnicode(Asc(Mid(Donnees$, 2, 1)))
      Default
        If ValeurUnicode(Asc(Mid(Donnees$, 2, 1))) > 8 And ValeurUnicode(Asc(Mid(Donnees$, 2, 1))) < 100
          ErreurDecompression$ = "Ce bloc a été fait avec une version plus récente du Compresseur PB." + #LF$ + "Mets ton programme à jour pour le lire."
          ProcedureReturn ""
        EndIf
        Methode$ = "?"
    EndSelect
    Encodage$ = "U"
    T = (ValeurUnicode(Asc(Mid(Donnees$, 3, 1))) * 32768) + ValeurUnicode(Asc(Mid(Donnees$, 4, 1)))
    Z = (ValeurUnicode(Asc(Mid(Donnees$, 5, 1))) * 32768) + ValeurUnicode(Asc(Mid(Donnees$, 6, 1)))
    K = (ValeurUnicode(Asc(Mid(Donnees$, 7, 1))) * 32768) + ValeurUnicode(Asc(Mid(Donnees$, 8, 1)))
    Donnees$ = Mid(Donnees$, 9)
  Else
    BlocReconnu = #True
    Texte$    = Mid(Texte$, Position)
    Methode$  = StringField(Texte$, 2, ";")
    Encodage$ = StringField(Texte$, 3, ";")
    T = Val(StringField(Texte$, 4, ";"))
    Z = Val(StringField(Texte$, 5, ";"))
    K = Val(StringField(Texte$, 6, ";"))
    Donnees$ = StringField(Texte$, 7, ";")
    Donnees$ = RemoveString(Donnees$, #CR$)
    Donnees$ = RemoveString(Donnees$, #LF$)
    Donnees$ = RemoveString(Donnees$, " ")
    Donnees$ = RemoveString(Donnees$, #TAB$)
  EndIf

  If (Methode$ <> "L" And Methode$ <> "M") Or (Encodage$ <> "U" And Encodage$ <> "B") Or T <= 0 Or T > 500000000 Or Z <= 0 Or Donnees$ = ""
    ErreurDecompression$ = "En-tête invalide: le bloc est incomplet ou abîmé."
    ProcedureReturn ""
  EndIf
  If Version >= 2 And Methode$ <> "M"
    ErreurDecompression$ = "En-tête PBC" + Str(Version) + " invalide: le bloc est incomplet ou abîmé."
    ProcedureReturn ""
  EndIf

  ; Barre de progression (méthodes v3 et v4). Pendant une compression, elle
  ; est déjà prévue: cette décompression est alors la vérification.
  Etape$ = "Vérification"
  ; Formats PBC4 à PBC8: méthode v4, au niveau indiqué par le bloc
  Niveau = #NiveauFaible
  If Version >= 4
    Niveau = NiveauDuCode(Version)
  EndIf
  ; Pendant une compression dont la méthode v4 a déjà été vérifiée (VerifOctets):
  ; seul le texte du bloc reste à contrôler, sans tout décompresser une seconde fois
  Raccourci = Bool(Version >= 4 And *VerifOctets <> 0 And Z = VerifZ And T = VerifT And Niveau = VerifNiveau)
  If ProgresEnCours = #False And Version >= 3
    PropreProgression = #True
    Etape$ = "Décompression"
    If Version >= 4
      Etape$ = Etape$ + " (niveau " + NomNiveau(Niveau) + ")"
    EndIf
    If Version >= 4
      If EtatPrevu(Niveau)
        DebutProgression(TravailAvant(Niveau) + TravailPasse4(T, Niveau, #True))
      ElseIf EtatUtile(Niveau)
        ; Première fois à ce niveau: décompression, puis contrôle de l'état écrit
        DebutProgression(TravailPasse4(T, Niveau, #False) + TravailPasse4(T, Niveau, #True))
      Else
        DebutProgression(TravailPasse4(T, Niveau, #False))
      EndIf
    Else
      DebutProgression(TravailReference(Niveau) + #TailleReferenceCourte + T)
    EndIf
  EndIf

  ; Méthode v4: la mémoire est vérifiée avant de lire le texte de référence
  If Version >= 4
    If MemoireMethode4() = #False
      ErreurDecompression$ = "Mémoire insuffisante: la méthode Maximal v4 a besoin d'environ 700 Mo de mémoire libre." + #LF$ + "Ferme d'autres programmes et réessaie."
      If PropreProgression
        FinProgression()
      EndIf
      ProcedureReturn ""
    EndIf
  EndIf

  ; Formats PBC2 à PBC8: le texte de référence du niveau (l'ancien texte seul
  ; pour PBC2 et PBC3) est placé devant la sortie. Méthode v4: avec l'état du
  ; modèle gardé sur le disque s'il existe (sinon, il sera écrit cette fois)
  FichierEtatLu = 0
  FichierEtatEcrit = 0
  If Version >= 2
    If Version >= 4 And Raccourci = #False
      Pret = PreparerNiveau(Niveau)
    Else
      Pret = ConstruireReference(Niveau)
    EndIf
    If Pret = #False
      ErreurDecompression$ = ErreurReference$
      If PropreProgression
        FinProgression()
      EndIf
      ProcedureReturn ""
    EndIf
    Decalage = TailleReference
  EndIf

  TailleTampon = Len(Donnees$) * 2 + 64
  *C = AllocateMemory(TailleTampon)
  *D = AllocateMemory(Decalage + T + 16)

  If *C = 0 Or *D = 0
    ErreurDecompression$ = "Mémoire insuffisante."
  Else
    ; 1. Texte -> octets compressés
    If Encodage$ = "U"
      N = DecoderUnicode(Donnees$, *C, TailleTampon)
    Else
      N = Base64Decoder(Donnees$, *C, TailleTampon)
    EndIf

    ; Format compact: nombre de caractères de données attendu
    Attendu = ((Z * 8) + 14) / 15
    If N < Z
      If Encodage$ = "U" And Position = 0 And Len(Donnees$) < Attendu
        ErreurDecompression$ = "Le bloc est incomplet: il manque environ " + Str(Attendu - Len(Donnees$)) + " caractères (souvent la fin du bloc)." + #LF$ + "Recopie-le en entier."
      Else
        ErreurDecompression$ = "Les données sont abîmées: recopiez le bloc en entier."
      EndIf
    Else
      ; 2. Décompression
      If Methode$ = "L"
        If UncompressMemory(*C, Z, *D, T, #PB_PackerPlugin_Lzma) <> T
          ErreurDecompression$ = "Les données sont abîmées: la décompression LZMA a échoué."
        EndIf
      ElseIf Version = 2
        CopyMemory(*Reference, *D, Decalage)
        DecoderCM2(*C, Z, T, *D, Decalage)
      ElseIf Version = 3
        CopyMemory(*Reference, *D, Decalage)
        CommencerPasse(Etape$, 1)
        DecoderCM3(*C, Z, T, *D, Decalage)
        TerminerPasse(Decalage + T)
      ElseIf Version >= 4
        CopyMemory(*Reference, *D, Decalage)
        If Raccourci
          ; Ces octets ont déjà été décompressés et vérifiés pendant la compression:
          ; le texte du bloc doit les redonner exactement, puis le contrôle final
          ; porte sur le code qu'ils donnent
          If CompareMemory(*C, *VerifOctets, Z)
            CopyMemory(*VerifCode, *D + Decalage, T)
          Else
            ErreurDecompression$ = "Le texte du bloc ne redonne pas les octets compressés vérifiés."
          EndIf
        Else
          Origine = 0
          If FichierEtatLu
            Origine = Decalage
          EndIf
          CommencerPasse(Etape$, 4, Origine)
          DecoderCM4(*C, Z, T, *D, Decalage, FichierEtatLu, FichierEtatEcrit)
          TerminerPasse(Decalage + T - Origine)
        EndIf
      Else
        DecoderCM(*C, Z, T, *D)
      EndIf

      ; 3. Contrôle final: on ne rend le code que s'il est intact
      If ErreurDecompression$ = ""
        If Controle(*D + Decalage, T) = K
          Reussi = #True
          Resultat$ = PeekS(*D + Decalage, T, #PB_UTF8 | #PB_ByteLength)
        Else
          If Encodage$ = "U" And Position = 0 And Len(Donnees$) > Attendu
            ErreurDecompression$ = "Le bloc contient environ " + Str(Len(Donnees$) - Attendu) + " caractères en trop ou abîmés: recopie-le en entier."
          Else
            ErreurDecompression$ = "Les données sont abîmées: le contrôle final ne correspond pas."
          EndIf
        EndIf
      EndIf
    EndIf
  EndIf

  ; 4. État du modèle de cette opération: un état relu et abîmé est effacé ; un
  ;    état tout juste écrit n'est gardé que s'il redonne la même décompression
  If FichierEtatLu
    EtatRelu = FermerEtatLu(FichierEtatLu, Niveau)
    FichierEtatLu = 0
  EndIf
  If FichierEtatEcrit
    EtatEcrit = FermerEtatEcrit(FichierEtatEcrit, Niveau)
    FichierEtatEcrit = 0
    If EtatEcrit
      If Reussi
        ValiderEtat(Niveau, *C, Z, T, *D + Decalage, "Contrôle de l'état gardé sur le disque")
      Else
        DeleteFile(FichierEtat(Niveau) + ".tmp")
      EndIf
    EndIf
  EndIf

  If *C
    FreeMemory(*C)
  EndIf
  If *D
    FreeMemory(*D)
  EndIf

  If PropreProgression
    FinProgression()
  EndIf
  ProcedureReturn Resultat$
EndProcedure

; ============================================================================
;  FIN DE LA PARTIE DÉCOMPRESSION
; ============================================================================



; ----------------------------------------------------------------------------
;  Méthode "Maximal": compresseur. Modèle strictement identique au
;  décompresseur ci-dessus ; seules changent les lignes de codage.
;  *D = code d'origine (T octets), *O = sortie. Renvoie la taille compressée.
; ----------------------------------------------------------------------------
DisableDebugger
Procedure.q EncoderCM(*D, T.q, *O)
  Protected.q i, u, v, no, x1, x2, wh, ls, pl, ml, mp, chk, pos, h, k, hm, ab, ma, c, c0, j, ws, dot, pb, e, pm, px, s, aw, ai, xm, y, er, g

  Dim T33.q(32)
  Restore Sq33
  For i = 0 To 32
    Read.q u
    T33(i) = u
  Next
  Dim Sq.q(4094)
  For i = 0 To 4094
    u = (i + 1) % 128
    v = (i + 1) / 128
    Sq(i) = ((T33(v) * (128 - u)) + (T33(v + 1) * u) + 64) / 128
  Next
  Dim St.q(4095)
  v = 0
  For i = 0 To 4094
    While v <= Sq(i)
      St(v) = i - 2047
      v = v + 1
    Wend
  Next
  While v <= 4095
    St(v) = 2047
    v = v + 1
  Wend
  Dim Kr.q(255)
  For i = 0 To 255
    Kr(i) = 8192 / ((2 * i) + 3)
  Next
  Dim P2.q(8)
  P2(0) = 1
  For i = 1 To 8
    P2(i) = P2(i - 1) * 2
  Next
  Dim M.l(12582911)
  For i = 0 To 12582911
    M(i) = 8388608
  Next
  Dim MT.l(1048575)
  Dim MS.q(63)
  For i = 0 To 63
    MS(i) = 8388608
  Next
  Dim W.q(2047)
  For i = 0 To 2047
    W(i) = 16384
  Next
  Dim Ap.q(2162687)
  For i = 0 To 2162687
    u = ((i % 33) * 128) - 1
    If u < 0: u = 0: EndIf
    If u > 4094: u = 4094: EndIf
    Ap(i) = Sq(u) * 16
  Next
  Dim Hi.q(4)
  Dim Hc.q(5)
  Dim Ix.q(6)
  Dim Sv.q(6)
  no = 0
  x1 = 0: x2 = 4294967295: wh = 0: ls = 0: pl = 0: ml = 0: mp = 0: chk = 0
  For pos = 0 To T - 1
    h = 0
    For k = 0 To 4
      h = ((((h + Hi(k)) + 1) * $6F4F2B) / 256) % $1000000
      If k < 4: Hc(k) = h: EndIf
    Next
    hm = h % $100000
    Hc(4) = (((((wh * 256) + Hi(0)) + 1) * $6F4F2B) / 256) % $1000000
    ab = 0
    If pl + pos - ls < ls: ab = PeekA(*D + pl + pos - ls): EndIf
    Hc(5) = (((((ab * 256) + Hi(0)) + 1048577) * $6F4F2B) / 256) % $1000000
    If ml > 0 And PeekA(*D + mp) = Hi(0)
      If ml < 65535: ml = ml + 1: EndIf
      mp = mp + 1
    Else
      ml = 0
    EndIf
    If ml = 0 And pos >= 5
      mp = MT(hm)
      While mp > 0 And ml < 124 And ml < mp
        If PeekA(*D + mp - ml - 1) <> PeekA(*D + pos - ml - 1): Break: EndIf
        ml = ml + 1
      Wend
    EndIf
    MT(hm) = pos
    ma = Bool(ml > 0)
    c = PeekA(*D + pos)
    c0 = 1
    For j = 0 To 7
      ws = c0 * 8
      dot = 0
      For k = 0 To 5
        Ix(k) = (((((((Hc(k) * 256) + c0) * $2E8BA3) / 1024) % $200000)) + (k * $200000))
        Sv(k) = St(M(Ix(k)) / 4096)
        dot = dot + (W(ws + k) * Sv(k))
      Next
      Sv(6) = 0
      If ma
        pb = PeekA(*D + mp) + 256
        If pb / P2(8 - j) = c0
          u = ml
          If u > 31: u = 31: EndIf
          Ix(6) = (u * 2) + ((pb / P2(7 - j)) % 2)
          Sv(6) = St(MS(Ix(6)) / 4096)
        Else
          ma = 0
        EndIf
      EndIf
      dot = dot + (W(ws + 6) * 256) + (W(ws + 7) * Sv(6))
      e = dot / 65536
      If e > 2047: e = 2047: EndIf
      If e < -2047: e = -2047: EndIf
      pm = Sq(e + 2047)
      px = pm
      s = St(pm) + 2048
      aw = s % 128
      ai = (((Hi(0) * 256) + c0) * 33) + (s / 128)
      pm = (pm + (3 * (((Ap(ai) * (128 - aw)) + (Ap(ai + 1) * aw)) / 2048))) / 4
      If pm < 1: pm = 1: EndIf
      If pm > 4095: pm = 4095: EndIf
      xm = x1 + (((x2 - x1) / 4096) * pm)
      y = (c / P2(7 - j)) % 2
      If y: x2 = xm: Else: x1 = xm + 1: EndIf
      er = ((y * 4096) - px) * 2
      For k = 0 To 5
        W(ws + k) = W(ws + k) + ((Sv(k) * er) / 1024)
        u = M(Ix(k)) / 256
        v = M(Ix(k)) % 256
        If y: u = u + (((65536 - u) * Kr(v)) / 4096): Else: u = u - ((u * Kr(v)) / 4096): EndIf
        If v < 127: v = v + 1: EndIf
        M(Ix(k)) = (u * 256) + v
      Next
      W(ws + 6) = W(ws + 6) + ((256 * er) / 1024)
      W(ws + 7) = W(ws + 7) + ((Sv(6) * er) / 1024)
      If ma
        u = MS(Ix(6)) / 256
        v = MS(Ix(6)) % 256
        If y: u = u + (((65536 - u) * Kr(v)) / 4096): Else: u = u - ((u * Kr(v)) / 4096): EndIf
        If v < 127: v = v + 1: EndIf
        MS(Ix(6)) = (u * 256) + v
      EndIf
      g = (y * 65536) + (y * 64) - (2 * y)
      Ap(ai) = Ap(ai) + (((g - Ap(ai)) * (128 - aw)) / 8192)
      Ap(ai + 1) = Ap(ai + 1) + (((g - Ap(ai + 1)) * aw) / 8192)
      c0 = (c0 * 2) + y
      While x1 / 16777216 = x2 / 16777216
        PokeA(*O + no, x2 / 16777216)
        no = no + 1
        x1 = (x1 % 16777216) * 256
        x2 = ((x2 % 16777216) * 256) + 255
      Wend
    Next
    chk = ((chk * 33) + c) % 1000000007
    For k = 4 To 1 Step -1
      Hi(k) = Hi(k - 1)
    Next
    Hi(0) = c
    If c = 10: pl = ls: ls = pos + 1: EndIf
    If (c >= 48 And c <= 57) Or (c >= 65 And c <= 90) Or (c >= 97 And c <= 122) Or c = 95
      wh = ((((wh + c) + 1) * $6F4F2B) / 256) % $1000000
    Else
      wh = 0
    EndIf
  Next
  For k = 1 To 4
    PokeA(*O + no, x1 / 16777216)
    no = no + 1
    x1 = (x1 % 16777216) * 256
  Next

  ProcedureReturn no
EndProcedure
EnableDebugger


; ----------------------------------------------------------------------------
;  Méthode "Maximal" version 3 (format PBC3): compresseur. Modèle strictement
;  identique à DecoderCM3 ; seules changent les lignes de codage.
;  *D = texte de référence (P octets) suivi du code d'origine (T octets).
; ----------------------------------------------------------------------------
DisableDebugger
Procedure.q EncoderCM3(*D, T.q, *O, P.q)
  Protected.q i, u, v, no, x1, x2, wh, ls, pl, ml, mp, chk, fw, fwf, nd, zn, pos, h, k, hm, ab, h8, ma, c, c0, j, ws, ck, pb, im, wi, wn, dot, dw, dy, e, r1, r2, r3, f, pf, pm, s, aw, ai, xm, y, er, e2, e3, hb, si, n0, n1, hh, g, ef, lt

  Dim T33.q(32)
  Restore Sq33
  For i = 0 To 32
    Read.q u
    T33(i) = u
  Next
  Dim Sq.q(4094)
  For i = 0 To 4094
    u = (i + 1) % 128
    v = (i + 1) / 128
    Sq(i) = ((T33(v) * (128 - u)) + (T33(v + 1) * u) + 64) / 128
  Next
  Dim St.q(4095)
  v = 0
  For i = 0 To 4094
    While v <= Sq(i)
      St(v) = i - 2047
      v = v + 1
    Wend
  Next
  While v <= 4095
    St(v) = 2047
    v = v + 1
  Wend
  Dim Kr.q(255)
  For i = 0 To 255
    Kr(i) = 8192 / ((2 * i) + 3)
  Next
  Dim P2.q(8)
  P2(0) = 1
  For i = 1 To 8
    P2(i) = P2(i - 1) * 2
  Next
  Dim M.l(18874367)
  For i = 0 To 18874367
    M(i) = 8388608
  Next
  Dim Bh.a(18874367)
  Dim Kc.a(18874367)
  Dim SM.q(18431)
  For i = 0 To 18431
    SM(i) = 8388608
  Next
  Dim MT.l(1048575)
  Dim MT2.l(1048575)
  Dim MS.q(63)
  For i = 0 To 63
    MS(i) = 8388608
  Next
  Dim W.q(5119)
  For i = 0 To 5119
    W(i) = 6553
  Next
  Dim Wx.q(639)
  For i = 0 To 639
    Wx(i) = 6553
  Next
  Dim Wc.q(15359)
  For i = 0 To 15359
    Wc(i) = 6553
  Next
  Dim Wf.q(319)
  For i = 0 To 319
    If i % 5 = 3: Wf(i) = 0: Else: Wf(i) = 21845: EndIf
  Next
  Dim Ap.q(2162687)
  For i = 0 To 2162687
    u = ((i % 33) * 128) - 1
    If u < 0: u = 0: EndIf
    If u > 4094: u = 4094: EndIf
    Ap(i) = Sq(u) * 16
  Next
  Dim Hi.q(7)
  Dim Hc.q(8)
  Dim Ix.q(8)
  Dim Sv.q(19)
  no = 0
  x1 = 0: x2 = 4294967295: wh = 0: ls = 0: pl = 0: ml = 0: mp = 0: chk = 0
  fw = 0: fwf = 0: nd = 0: zn = 0
  For pos = 0 To P + T - 1
    If pos % 4096 = 0: ProgressionCM(pos): EndIf
    h = 0
    For k = 0 To 4
      h = ((((h + Hi(k)) + 1) * $6F4F2B) / 256) % $1000000
      If k < 4: Hc(k) = h: EndIf
    Next
    hm = h % $100000
    Hc(4) = (((((wh * 256) + Hi(0)) + 1) * $6F4F2B) / 256) % $1000000
    ab = 0
    If pl + pos - ls < ls: ab = PeekA(*D + pl + pos - ls): EndIf
    Hc(5) = (((((ab * 256) + Hi(0)) + 1048577) * $6F4F2B) / 256) % $1000000
    For k = 5 To 7
      h = ((((h + Hi(k)) + 1) * $6F4F2B) / 256) % $1000000
    Next
    h8 = h
    Hc(6) = h8
    u = (((((fw * 256) + (wh % 256)) + 1) * $6F4F2B) / 256) % $1000000
    u = (((((u * 256) + ((wh / 256) % 256)) + 1) * $6F4F2B) / 256) % $1000000
    u = (((((u * 256) + (wh / 65536)) + 1) * $6F4F2B) / 256) % $1000000
    Hc(7) = (((((u * 256) + 3) + 1) * $6F4F2B) / 256) % $1000000
    u = (((((nd * 256) + Hi(1)) + 1) * $6F4F2B) / 256) % $1000000
    u = (((((u * 256) + Hi(0)) + 1) * $6F4F2B) / 256) % $1000000
    u = (((((u * 256) + 0) + 1) * $6F4F2B) / 256) % $1000000
    Hc(8) = (((((u * 256) + 4) + 1) * $6F4F2B) / 256) % $1000000
    If ml > 0 And PeekA(*D + mp) = Hi(0)
      If ml < 65535: ml = ml + 1: EndIf
      mp = mp + 1
    Else
      ml = 0
    EndIf
    If ml = 0 And pos >= 8
      mp = MT2(h8 % $100000)
      While mp > 0 And ml < 124 And ml < mp
        If PeekA(*D + mp - ml - 1) <> PeekA(*D + pos - ml - 1): Break: EndIf
        ml = ml + 1
      Wend
    EndIf
    If ml = 0 And pos >= 5
      mp = MT(hm)
      While mp > 0 And ml < 124 And ml < mp
        If PeekA(*D + mp - ml - 1) <> PeekA(*D + pos - ml - 1): Break: EndIf
        ml = ml + 1
      Wend
    EndIf
    MT(hm) = pos
    MT2(h8 % $100000) = pos
    ma = Bool(ml > 0)
    c = PeekA(*D + pos)
    c0 = 1
    For j = 0 To 7
      ws = c0 * 20
      For k = 0 To 8
        Ix(k) = (((((Hc(k) * 256) + c0) * $2E8BA3) / 1024) % $200000) + (k * $200000)
        ck = ((((Hc(k) * 256) + c0) / 4096) % 255) + 1
        If Kc(Ix(k)) <> ck
          Kc(Ix(k)) = ck
          M(Ix(k)) = 8388608
          Bh(Ix(k)) = 0
        EndIf
        Sv(k * 2) = St(M(Ix(k)) / 4096)
        Sv((k * 2) + 1) = St(SM((k * 2048) + Bh(Ix(k)) + (256 * j)) / 4096)
      Next
      Sv(18) = 256
      Sv(19) = 0
      If ma
        pb = PeekA(*D + mp) + 256
        If pb / P2(8 - j) = c0
          u = ml
          If u > 31: u = 31: EndIf
          im = (u * 2) + ((pb / P2(7 - j)) % 2)
          Sv(19) = St(MS(im) / 4096)
        Else
          ma = 0
        EndIf
      EndIf
      u = ml
      If u > 15: u = 15: EndIf
      wi = ((u * 2) + ma) * 20
      wn = ((zn * 256) + Hi(0)) * 20
      dot = 0: dw = 0: dy = 0
      For k = 0 To 19
        dot = dot + (W(ws + k) * Sv(k))
        dw = dw + (Wx(wi + k) * Sv(k))
        dy = dy + (Wc(wn + k) * Sv(k))
      Next
      e = dot / 65536
      If e > 2047: e = 2047: EndIf
      If e < -2047: e = -2047: EndIf
      r1 = Sq(e + 2047)
      e = dw / 65536
      If e > 2047: e = 2047: EndIf
      If e < -2047: e = -2047: EndIf
      r2 = Sq(e + 2047)
      e = dy / 65536
      If e > 2047: e = 2047: EndIf
      If e < -2047: e = -2047: EndIf
      r3 = Sq(e + 2047)
      f = ((j * 2) + ma) * 5
      pf = (Wf(f) * St(r1)) + (Wf(f + 1) * St(r2)) + (Wf(f + 2) * St(r3)) + (Wf(f + 3) * 256)
      e = pf / 65536
      If e > 2047: e = 2047: EndIf
      If e < -2047: e = -2047: EndIf
      pm = Sq(e + 2047)
      pf = pm
      s = St(pm) + 2048
      aw = s % 128
      ai = (((Hi(0) * 256) + c0) * 33) + (s / 128)
      pm = (pm + (3 * (((Ap(ai) * (128 - aw)) + (Ap(ai + 1) * aw)) / 2048))) / 4
      If pm < 1: pm = 1: EndIf
      If pm > 4095: pm = 4095: EndIf
      If pos >= P
        xm = x1 + (((x2 - x1) / 4096) * pm)
        y = (c / P2(7 - j)) % 2
        If y: x2 = xm: Else: x1 = xm + 1: EndIf
      Else
        y = (c / P2(7 - j)) % 2
      EndIf
      er = ((y * 4096) - r1) * 2
      e2 = ((y * 4096) - r2) * 2
      e3 = ((y * 4096) - r3) * 2
      For k = 0 To 19
        W(ws + k) = W(ws + k) + ((Sv(k) * er) / 4096)
        Wx(wi + k) = Wx(wi + k) + ((Sv(k) * e2) / 4096)
        Wc(wn + k) = Wc(wn + k) + ((Sv(k) * e3) / 4096)
      Next
      For k = 0 To 8
        hb = Bh(Ix(k))
        si = (k * 2048) + hb + (256 * j)
        u = SM(si) / 256
        v = SM(si) % 256
        If y: u = u + (((65536 - u) * Kr(v)) / 4096): Else: u = u - ((u * Kr(v)) / 4096): EndIf
        If v < 127: v = v + 1: EndIf
        SM(si) = (u * 256) + v
        n0 = hb % 8
        n1 = (hb / 8) % 8
        hh = hb / 64
        If y
          If n1 < 7: n1 = n1 + 1: EndIf
          If n0 > 2: n0 = (n0 / 2) + 1: EndIf
        Else
          If n0 < 7: n0 = n0 + 1: EndIf
          If n1 > 2: n1 = (n1 / 2) + 1: EndIf
        EndIf
        Bh(Ix(k)) = n0 + (n1 * 8) + ((((hh * 2) + y) % 4) * 64)
        u = M(Ix(k)) / 256
        v = M(Ix(k)) % 256
        If y: u = u + (((65536 - u) * Kr(v)) / 4096): Else: u = u - ((u * Kr(v)) / 4096): EndIf
        If v < 127: v = v + 1: EndIf
        M(Ix(k)) = (u * 256) + v
      Next
      If ma
        u = MS(im) / 256
        v = MS(im) % 256
        If y: u = u + (((65536 - u) * Kr(v)) / 4096): Else: u = u - ((u * Kr(v)) / 4096): EndIf
        If v < 127: v = v + 1: EndIf
        MS(im) = (u * 256) + v
      EndIf
      g = (y * 65536) + (y * 64) - (2 * y)
      Ap(ai) = Ap(ai) + (((g - Ap(ai)) * (128 - aw)) / 8192)
      Ap(ai + 1) = Ap(ai + 1) + (((g - Ap(ai + 1)) * aw) / 8192)
      ef = ((y * 4096) - pf) * 2
      Wf(f) = Wf(f) + ((St(r1) * ef) / 16384)
      Wf(f + 1) = Wf(f + 1) + ((St(r2) * ef) / 16384)
      Wf(f + 2) = Wf(f + 2) + ((St(r3) * ef) / 16384)
      Wf(f + 3) = Wf(f + 3) + ((256 * ef) / 16384)
      c0 = (c0 * 2) + y
      While x1 / 16777216 = x2 / 16777216
        PokeA(*O + no, x2 / 16777216)
        no = no + 1
        x1 = (x1 % 16777216) * 256
        x2 = ((x2 % 16777216) * 256) + 255
      Wend
    Next
    If pos >= P: chk = ((chk * 33) + c) % 1000000007: EndIf
    For k = 7 To 1 Step -1
      Hi(k) = Hi(k - 1)
    Next
    Hi(0) = c
    If c = 10
      pl = ls: ls = pos + 1: fw = 0: fwf = 0: nd = 0
    EndIf
    lt = 0
    If (c >= 48 And c <= 57) Or (c >= 65 And c <= 90) Or (c >= 97 And c <= 122) Or c = 95: lt = 1: EndIf
    If lt
      wh = ((((wh + c) + 1) * $6F4F2B) / 256) % $1000000
    Else
      wh = 0
    EndIf
    If c = 32 And fwf = 0 And fw = 0: nd = nd + 1: EndIf
    If fwf = 0
      If lt
        fw = (((((fw * 256) + c) + 1) * $6F4F2B) / 256) % $1000000
      ElseIf fw > 0
        fwf = 1
      EndIf
    EndIf
    If zn = 0
      If c = 59
        zn = 2
      ElseIf c = 34
        zn = 1
      EndIf
    ElseIf zn = 1
      If c = 34 Or c = 10: zn = 0: EndIf
    ElseIf c = 10
      zn = 0
    EndIf
  Next
  For k = 1 To 4
    PokeA(*O + no, x1 / 16777216)
    no = no + 1
    x1 = (x1 % 16777216) * 256
  Next

  ProcedureReturn no
EndProcedure
EnableDebugger


; ----------------------------------------------------------------------------
;  Méthode "Maximal" version 4 (format PBC4): compresseur. Modèle strictement
;  identique à DecoderCM4 ; seules changent les lignes de codage.
;  *D = texte de référence v4 (P octets) suivi du code d'origine (T octets).
; ----------------------------------------------------------------------------
DisableDebugger
Procedure.q EncoderCM4(*D, T.q, *O, P.q, EtatLu.q, EtatEcrit.q)
  Protected.q i, u, v, charge, crc, no, x1, x2, ml, mp, ma, chk, wh, wp, wc, fw, fwf, pfw, nd, bd, tk, zn, ls, pl, ppl, Debut, h0, h, k, hm, h8, ab, u2, ab2, a, a1, a2, sr, sf, a3, h16, b, c, c0, j, ws, ck, pb, im, wi, wn, wz, wv, dot, dw, dy, dz, dv, e, r1, r2, r3, r4, r5, f, pf, pm, s, aw, ai, pa, ai2, pa2, xm, y, er, e2, e3, e4, e5, hb, si, n0, n1, hh, g, ef, lt, l1, pos

  Dim T33.q(32)
  Restore Sq33
  For i = 0 To 32
    Read.q u
    T33(i) = u
  Next
  Dim Sq.q(4094)
  For i = 0 To 4094
    u = (i + 1) % 128
    v = (i + 1) / 128
    Sq(i) = ((T33(v) * (128 - u)) + (T33(v + 1) * u) + 64) / 128
  Next
  Dim St.q(4095)
  v = 0
  For i = 0 To 4094
    While v <= Sq(i)
      St(v) = i - 2047
      v = v + 1
    Wend
  Next
  While v <= 4095
    St(v) = 2047
    v = v + 1
  Wend
  Dim Kr.q(255)
  For i = 0 To 255
    Kr(i) = 8192 / ((2 * i) + 3)
  Next
  Dim P2.q(8)
  P2(0) = 1
  For i = 1 To 8
    P2(i) = P2(i - 1) * 2
  Next
  Dim M.l(100663295)
  Dim Bh.a(100663295)
  Dim Kc.a(100663295)
  Dim SM.q(1572863)
  Dim MT.l(1048575)
  Dim MT2.l(1048575)
  Dim MT3.l(1048575)
  Dim MS.q(63)
  Dim W.q(12799)
  Dim Wx.q(1599)
  Dim Wc.q(38399)
  Dim Wz.q(12799)
  Dim Wv.q(12799)
  Dim Wf.q(383)
  Dim Ap.q(2162687)
  Dim Ap2.q(2162687)
  Dim I1.q(255)
  Dim I2.q(65535)
  Dim LF.q(65535)
  Dim LE.q(65535)
  Dim Hi.q(7)
  Dim Hc.q(23)
  Dim Ix.q(23)
  Dim Sv.q(49)
  Dim Es.q(81)
  charge = 0
  If EtatLu <> 0
    crc = 0
    crc = EchangeTableauL(EtatLu, 0, M(), crc)
    crc = EchangeTableauA(EtatLu, 0, Bh(), crc)
    crc = EchangeTableauA(EtatLu, 0, Kc(), crc)
    crc = EchangeTableauQ(EtatLu, 0, SM(), crc)
    crc = EchangeTableauL(EtatLu, 0, MT(), crc)
    crc = EchangeTableauL(EtatLu, 0, MT2(), crc)
    crc = EchangeTableauL(EtatLu, 0, MT3(), crc)
    crc = EchangeTableauQ(EtatLu, 0, MS(), crc)
    crc = EchangeTableauQ(EtatLu, 0, W(), crc)
    crc = EchangeTableauQ(EtatLu, 0, Wx(), crc)
    crc = EchangeTableauQ(EtatLu, 0, Wc(), crc)
    crc = EchangeTableauQ(EtatLu, 0, Wz(), crc)
    crc = EchangeTableauQ(EtatLu, 0, Wv(), crc)
    crc = EchangeTableauQ(EtatLu, 0, Wf(), crc)
    crc = EchangeTableauQ(EtatLu, 0, Ap(), crc)
    crc = EchangeTableauQ(EtatLu, 0, Ap2(), crc)
    crc = EchangeTableauQ(EtatLu, 0, I1(), crc)
    crc = EchangeTableauQ(EtatLu, 0, I2(), crc)
    crc = EchangeTableauQ(EtatLu, 0, LF(), crc)
    crc = EchangeTableauQ(EtatLu, 0, LE(), crc)
    crc = EchangeTableauQ(EtatLu, 0, Hi(), crc)
    crc = EchangeTableauQ(EtatLu, 0, Hc(), crc)
    crc = EchangeTableauQ(EtatLu, 0, Ix(), crc)
    crc = EchangeTableauQ(EtatLu, 0, Sv(), crc)
    crc = EchangeTableauQ(EtatLu, 0, Es(), crc)
    If crc >= 0 And crc = LireControleEtat(EtatLu)
      charge = 1
    Else
      SignalerEtatAbime()
    EndIf
  EndIf
  If charge = 0
    If EtatLu <> 0
      Dim M.l(100663295)
      Dim Bh.a(100663295)
      Dim Kc.a(100663295)
      Dim SM.q(1572863)
      Dim MT.l(1048575)
      Dim MT2.l(1048575)
      Dim MT3.l(1048575)
      Dim MS.q(63)
      Dim W.q(12799)
      Dim Wx.q(1599)
      Dim Wc.q(38399)
      Dim Wz.q(12799)
      Dim Wv.q(12799)
      Dim Wf.q(383)
      Dim Ap.q(2162687)
      Dim Ap2.q(2162687)
      Dim I1.q(255)
      Dim I2.q(65535)
      Dim LF.q(65535)
      Dim LE.q(65535)
      Dim Hi.q(7)
      Dim Hc.q(23)
      Dim Ix.q(23)
      Dim Sv.q(49)
      Dim Es.q(81)
    EndIf
    For i = 0 To 100663295
      M(i) = 8388608
    Next
    For i = 0 To 1572863
      SM(i) = 8388608
    Next
    For i = 0 To 63
      MS(i) = 8388608
    Next
    For i = 0 To 12799
      W(i) = 2621
    Next
    For i = 0 To 1599
      Wx(i) = 2621
    Next
    For i = 0 To 38399
      Wc(i) = 2621
    Next
    For i = 0 To 12799
      Wz(i) = 2621
    Next
    For i = 0 To 12799
      Wv(i) = 2621
    Next
    For i = 0 To 383
      If i % 6 = 3: Wf(i) = 0: Else: Wf(i) = 13107: EndIf
    Next
    For i = 0 To 2162687
      u = ((i % 33) * 128) - 1
      If u < 0: u = 0: EndIf
      If u > 4094: u = 4094: EndIf
      Ap(i) = Sq(u) * 16
    Next
    For i = 0 To 2162687
      u = ((i % 33) * 128) - 1
      If u < 0: u = 0: EndIf
      If u > 4094: u = 4094: EndIf
      Ap2(i) = Sq(u) * 16
    Next
  EndIf
  no = 0
  x1 = 0: x2 = 4294967295: ml = 0: mp = 0: ma = 0: chk = 0
  wh = 0: wp = 0: wc = 0: fw = 0: fwf = 0: pfw = 0: nd = 0: bd = 0: tk = 0: zn = 0
  ls = 0: pl = 0: ppl = 0
  Debut = 0
  If charge
    i = Es(0): u = Es(1): v = Es(2): ml = Es(3): mp = Es(4): ma = Es(5): wh = Es(6): wp = Es(7)
    wc = Es(8): fw = Es(9): fwf = Es(10): pfw = Es(11): nd = Es(12): bd = Es(13): tk = Es(14): zn = Es(15)
    ls = Es(16): pl = Es(17): ppl = Es(18): h0 = Es(19): h = Es(20): k = Es(21): hm = Es(22): h8 = Es(23)
    ab = Es(24): u2 = Es(25): ab2 = Es(26): a = Es(27): a1 = Es(28): a2 = Es(29): sr = Es(30): sf = Es(31)
    a3 = Es(32): h16 = Es(33): b = Es(34): c = Es(35): c0 = Es(36): j = Es(37): ws = Es(38): ck = Es(39)
    pb = Es(40): im = Es(41): wi = Es(42): wn = Es(43): wz = Es(44): wv = Es(45): dot = Es(46): dw = Es(47)
    dy = Es(48): dz = Es(49): dv = Es(50): e = Es(51): r1 = Es(52): r2 = Es(53): r3 = Es(54): r4 = Es(55)
    r5 = Es(56): f = Es(57): pf = Es(58): pm = Es(59): s = Es(60): aw = Es(61): ai = Es(62): pa = Es(63)
    ai2 = Es(64): pa2 = Es(65): xm = Es(66): y = Es(67): er = Es(68): e2 = Es(69): e3 = Es(70): e4 = Es(71)
    e5 = Es(72): hb = Es(73): si = Es(74): n0 = Es(75): n1 = Es(76): hh = Es(77): g = Es(78): ef = Es(79)
    lt = Es(80): l1 = Es(81)
    Debut = P
  EndIf
  For pos = Debut To P + T - 1
    If pos = P And EtatEcrit <> 0
      Es(0) = i: Es(1) = u: Es(2) = v: Es(3) = ml: Es(4) = mp: Es(5) = ma: Es(6) = wh: Es(7) = wp
      Es(8) = wc: Es(9) = fw: Es(10) = fwf: Es(11) = pfw: Es(12) = nd: Es(13) = bd: Es(14) = tk: Es(15) = zn
      Es(16) = ls: Es(17) = pl: Es(18) = ppl: Es(19) = h0: Es(20) = h: Es(21) = k: Es(22) = hm: Es(23) = h8
      Es(24) = ab: Es(25) = u2: Es(26) = ab2: Es(27) = a: Es(28) = a1: Es(29) = a2: Es(30) = sr: Es(31) = sf
      Es(32) = a3: Es(33) = h16: Es(34) = b: Es(35) = c: Es(36) = c0: Es(37) = j: Es(38) = ws: Es(39) = ck
      Es(40) = pb: Es(41) = im: Es(42) = wi: Es(43) = wn: Es(44) = wz: Es(45) = wv: Es(46) = dot: Es(47) = dw
      Es(48) = dy: Es(49) = dz: Es(50) = dv: Es(51) = e: Es(52) = r1: Es(53) = r2: Es(54) = r3: Es(55) = r4
      Es(56) = r5: Es(57) = f: Es(58) = pf: Es(59) = pm: Es(60) = s: Es(61) = aw: Es(62) = ai: Es(63) = pa
      Es(64) = ai2: Es(65) = pa2: Es(66) = xm: Es(67) = y: Es(68) = er: Es(69) = e2: Es(70) = e3: Es(71) = e4
      Es(72) = e5: Es(73) = hb: Es(74) = si: Es(75) = n0: Es(76) = n1: Es(77) = hh: Es(78) = g: Es(79) = ef
      Es(80) = lt: Es(81) = l1
      crc = 0
      crc = EchangeTableauL(EtatEcrit, 1, M(), crc)
      crc = EchangeTableauA(EtatEcrit, 1, Bh(), crc)
      crc = EchangeTableauA(EtatEcrit, 1, Kc(), crc)
      crc = EchangeTableauQ(EtatEcrit, 1, SM(), crc)
      crc = EchangeTableauL(EtatEcrit, 1, MT(), crc)
      crc = EchangeTableauL(EtatEcrit, 1, MT2(), crc)
      crc = EchangeTableauL(EtatEcrit, 1, MT3(), crc)
      crc = EchangeTableauQ(EtatEcrit, 1, MS(), crc)
      crc = EchangeTableauQ(EtatEcrit, 1, W(), crc)
      crc = EchangeTableauQ(EtatEcrit, 1, Wx(), crc)
      crc = EchangeTableauQ(EtatEcrit, 1, Wc(), crc)
      crc = EchangeTableauQ(EtatEcrit, 1, Wz(), crc)
      crc = EchangeTableauQ(EtatEcrit, 1, Wv(), crc)
      crc = EchangeTableauQ(EtatEcrit, 1, Wf(), crc)
      crc = EchangeTableauQ(EtatEcrit, 1, Ap(), crc)
      crc = EchangeTableauQ(EtatEcrit, 1, Ap2(), crc)
      crc = EchangeTableauQ(EtatEcrit, 1, I1(), crc)
      crc = EchangeTableauQ(EtatEcrit, 1, I2(), crc)
      crc = EchangeTableauQ(EtatEcrit, 1, LF(), crc)
      crc = EchangeTableauQ(EtatEcrit, 1, LE(), crc)
      crc = EchangeTableauQ(EtatEcrit, 1, Hi(), crc)
      crc = EchangeTableauQ(EtatEcrit, 1, Hc(), crc)
      crc = EchangeTableauQ(EtatEcrit, 1, Ix(), crc)
      crc = EchangeTableauQ(EtatEcrit, 1, Sv(), crc)
      crc = EchangeTableauQ(EtatEcrit, 1, Es(), crc)
      EcrireControleEtat(EtatEcrit, crc)
    EndIf
    If pos % 4096 = 0: AvancementCM4(pos, no): EndIf
    h0 = Hi(0)
    h = 0
    For k = 0 To 7
      h = ((((h + Hi(k)) + 1) * $6F4F2B) / 256) % $1000000
      If k < 4: Hc(k) = h: EndIf
      If k = 4: hm = h % $100000: EndIf
    Next
    h8 = h
    Hc(4) = (((((wh * 256) + h0) + 1) * $6F4F2B) / 256) % $1000000
    ab = 0
    If pl + pos - ls < ls: ab = PeekA(*D + pl + pos - ls): EndIf
    Hc(5) = (((((ab * 256) + h0) + 1048577) * $6F4F2B) / 256) % $1000000
    Hc(6) = h8
    u = (((((wh * 256) + (wp % 256)) + 1) * $6F4F2B) / 256) % $1000000
    u = (((((u * 256) + ((wp / 256) % 256)) + 1) * $6F4F2B) / 256) % $1000000
    u = (((((u * 256) + (wp / 65536)) + 1) * $6F4F2B) / 256) % $1000000
    Hc(7) = (((((u * 256) + (h0 + 2)) + 1) * $6F4F2B) / 256) % $1000000
    u = (((((fw * 256) + (wh % 256)) + 1) * $6F4F2B) / 256) % $1000000
    u = (((((u * 256) + ((wh / 256) % 256)) + 1) * $6F4F2B) / 256) % $1000000
    u = (((((u * 256) + (wh / 65536)) + 1) * $6F4F2B) / 256) % $1000000
    Hc(8) = (((((u * 256) + 3) + 1) * $6F4F2B) / 256) % $1000000
    u2 = u
    v = (h0 * 256) + Hi(1)
    u = (((((nd * 256) + (v % 256)) + 1) * $6F4F2B) / 256) % $1000000
    u = (((((u * 256) + ((v / 256) % 256)) + 1) * $6F4F2B) / 256) % $1000000
    u = (((((u * 256) + (v / 65536)) + 1) * $6F4F2B) / 256) % $1000000
    Hc(9) = (((((u * 256) + 4) + 1) * $6F4F2B) / 256) % $1000000
    u = (((((bd * 256) + (v % 256)) + 1) * $6F4F2B) / 256) % $1000000
    u = (((((u * 256) + ((v / 256) % 256)) + 1) * $6F4F2B) / 256) % $1000000
    u = (((((u * 256) + (v / 65536)) + 1) * $6F4F2B) / 256) % $1000000
    Hc(10) = (((((u * 256) + 6) + 1) * $6F4F2B) / 256) % $1000000
    ab2 = 0
    If pl + pos - ls + 1 < ls: ab2 = PeekA(*D + pl + pos - ls + 1): EndIf
    a = (ab * 256) + ab2
    u = (((((a * 256) + (h0 % 256)) + 1) * $6F4F2B) / 256) % $1000000
    u = (((((u * 256) + ((h0 / 256) % 256)) + 1) * $6F4F2B) / 256) % $1000000
    u = (((((u * 256) + (h0 / 65536)) + 1) * $6F4F2B) / 256) % $1000000
    Hc(11) = (((((u * 256) + 7) + 1) * $6F4F2B) / 256) % $1000000
    u = (((((pfw * 256) + (u2 % 256)) + 1) * $6F4F2B) / 256) % $1000000
    u = (((((u * 256) + ((u2 / 256) % 256)) + 1) * $6F4F2B) / 256) % $1000000
    u = (((((u * 256) + (u2 / 65536)) + 1) * $6F4F2B) / 256) % $1000000
    Hc(12) = (((((u * 256) + 8) + 1) * $6F4F2B) / 256) % $1000000
    Hc(13) = (((((((Hi(1) * 256) + Hi(2)) * 256) + 9) + 1) * $6F4F2B) / 256) % $1000000
    u = (((((wh * 256) + (wc % 256)) + 1) * $6F4F2B) / 256) % $1000000
    u = (((((u * 256) + ((wc / 256) % 256)) + 1) * $6F4F2B) / 256) % $1000000
    u = (((((u * 256) + (wc / 65536)) + 1) * $6F4F2B) / 256) % $1000000
    Hc(14) = (((((u * 256) + 10) + 1) * $6F4F2B) / 256) % $1000000
    a1 = 0: a2 = 0
    If ppl + pos - ls < pl: a1 = PeekA(*D + ppl + pos - ls): EndIf
    If ppl + pos - ls + 1 < pl: a2 = PeekA(*D + ppl + pos - ls + 1): EndIf
    a = (a1 * 256) + a2
    u = (((((a * 256) + (h0 % 256)) + 1) * $6F4F2B) / 256) % $1000000
    u = (((((u * 256) + ((h0 / 256) % 256)) + 1) * $6F4F2B) / 256) % $1000000
    u = (((((u * 256) + (h0 / 65536)) + 1) * $6F4F2B) / 256) % $1000000
    Hc(15) = (((((u * 256) + 14) + 1) * $6F4F2B) / 256) % $1000000
    a = I1(h0)
    u = (((((a * 256) + (h0 % 256)) + 1) * $6F4F2B) / 256) % $1000000
    u = (((((u * 256) + ((h0 / 256) % 256)) + 1) * $6F4F2B) / 256) % $1000000
    u = (((((u * 256) + (h0 / 65536)) + 1) * $6F4F2B) / 256) % $1000000
    Hc(16) = (((((u * 256) + 19) + 1) * $6F4F2B) / 256) % $1000000
    a = I2((Hi(1) * 256) + h0)
    u = (((((a * 256) + (h0 % 256)) + 1) * $6F4F2B) / 256) % $1000000
    u = (((((u * 256) + ((h0 / 256) % 256)) + 1) * $6F4F2B) / 256) % $1000000
    u = (((((u * 256) + (h0 / 65536)) + 1) * $6F4F2B) / 256) % $1000000
    Hc(17) = (((((u * 256) + 17) + 1) * $6F4F2B) / 256) % $1000000
    a = tk
    If a > 15: a = 15: EndIf
    a = (a * 256) + h0
    u = (((((a * 256) + (fw % 256)) + 1) * $6F4F2B) / 256) % $1000000
    u = (((((u * 256) + ((fw / 256) % 256)) + 1) * $6F4F2B) / 256) % $1000000
    u = (((((u * 256) + (fw / 65536)) + 1) * $6F4F2B) / 256) % $1000000
    Hc(18) = (((((u * 256) + 18) + 1) * $6F4F2B) / 256) % $1000000
    a1 = 0: a2 = 0: sr = 0: sf = 0
    If fwf = 1 And fw <> 0: sr = LF(fw % 65536): sf = LE(fw % 65536): EndIf
    If sr + pos - ls < sf: a1 = PeekA(*D + sr + pos - ls): EndIf
    If sr + pos - ls + 1 < sf: a2 = PeekA(*D + sr + pos - ls + 1): EndIf
    a = (a1 * 256) + a2
    u = (((((a * 256) + (v % 256)) + 1) * $6F4F2B) / 256) % $1000000
    u = (((((u * 256) + ((v / 256) % 256)) + 1) * $6F4F2B) / 256) % $1000000
    u = (((((u * 256) + (v / 65536)) + 1) * $6F4F2B) / 256) % $1000000
    Hc(19) = (((((u * 256) + 16) + 1) * $6F4F2B) / 256) % $1000000
    a = pos - ls
    If a > 79: a = 79: EndIf
    Hc(20) = (((((((a * 256) + h0) * 256) + 11) + 1) * $6F4F2B) / 256) % $1000000
    a1 = 0: a3 = 0
    If pl + pos - ls - 1 < ls And pos > ls: a1 = PeekA(*D + pl + pos - ls - 1): EndIf
    If pl + pos - ls + 2 < ls: a3 = PeekA(*D + pl + pos - ls + 2): EndIf
    a = (a1 * 65536) + (ab * 256) + a3
    u = (((((a * 256) + (v % 256)) + 1) * $6F4F2B) / 256) % $1000000
    u = (((((u * 256) + ((v / 256) % 256)) + 1) * $6F4F2B) / 256) % $1000000
    u = (((((u * 256) + (v / 65536)) + 1) * $6F4F2B) / 256) % $1000000
    Hc(21) = (((((u * 256) + 12) + 1) * $6F4F2B) / 256) % $1000000
    If ml > 0 And PeekA(*D + mp) = h0
      If ml < 65535: ml = ml + 1: EndIf
      mp = mp + 1
    Else
      ml = 0
    EndIf
    h16 = 0
    If pos >= 16
      For k = 16 To 1 Step -1
        h16 = ((((h16 + PeekA(*D + pos - k)) + 1) * $6F4F2B) / 256) % $1000000
      Next
    EndIf
    If ml = 0 And pos >= 16
      mp = MT3(h16 % $100000)
      While mp > 0 And ml < 124 And ml < mp
        If PeekA(*D + mp - ml - 1) <> PeekA(*D + pos - ml - 1): Break: EndIf
        ml = ml + 1
      Wend
    EndIf
    If pos >= 16: MT3(h16 % $100000) = pos: EndIf
    If ml = 0 And pos >= 8
      mp = MT2(h8 % $100000)
      While mp > 0 And ml < 124 And ml < mp
        If PeekA(*D + mp - ml - 1) <> PeekA(*D + pos - ml - 1): Break: EndIf
        ml = ml + 1
      Wend
    EndIf
    If ml = 0 And pos >= 5
      mp = MT(hm)
      While mp > 0 And ml < 124 And ml < mp
        If PeekA(*D + mp - ml - 1) <> PeekA(*D + pos - ml - 1): Break: EndIf
        ml = ml + 1
      Wend
    EndIf
    MT(hm) = pos
    MT2(h8 % $100000) = pos
    ma = Bool(ml > 0)
    a = ml
    If a > 15: a = 15: EndIf
    b = 0
    If ma: b = PeekA(*D + mp): EndIf
    u = (((((a * 256) + (b % 256)) + 1) * $6F4F2B) / 256) % $1000000
    u = (((((u * 256) + ((b / 256) % 256)) + 1) * $6F4F2B) / 256) % $1000000
    u = (((((u * 256) + (b / 65536)) + 1) * $6F4F2B) / 256) % $1000000
    Hc(22) = (((((u * 256) + 5) + 1) * $6F4F2B) / 256) % $1000000
    a = 0
    If ma: a = PeekA(*D + mp) + 256: EndIf
    u = (((((a * 256) + (v % 256)) + 1) * $6F4F2B) / 256) % $1000000
    u = (((((u * 256) + ((v / 256) % 256)) + 1) * $6F4F2B) / 256) % $1000000
    u = (((((u * 256) + (v / 65536)) + 1) * $6F4F2B) / 256) % $1000000
    Hc(23) = (((((u * 256) + 13) + 1) * $6F4F2B) / 256) % $1000000
    c = PeekA(*D + pos)
    c0 = 1
    For j = 0 To 7
      ws = c0 * 50
      For k = 0 To 23
        Ix(k) = (((((Hc(k) * 256) + c0) * $2E8BA3) / 1024) % $400000) + (k * $400000)
        ck = ((((Hc(k) * 256) + c0) / 4096) % 255) + 1
        If Kc(Ix(k)) <> ck
          Kc(Ix(k)) = ck
          M(Ix(k)) = 8388608
          Bh(Ix(k)) = 0
        EndIf
        Sv(k * 2) = St(M(Ix(k)) / 4096)
        Sv((k * 2) + 1) = St(SM((k * 65536) + Bh(Ix(k)) + (256 * c0)) / 4096)
      Next
      Sv(48) = 256
      Sv(49) = 0
      If ma
        pb = PeekA(*D + mp) + 256
        If pb / P2(8 - j) = c0
          u = ml
          If u > 31: u = 31: EndIf
          im = (u * 2) + ((pb / P2(7 - j)) % 2)
          Sv(49) = St(MS(im) / 4096)
        Else
          ma = 0
        EndIf
      EndIf
      u = ml
      If u > 15: u = 15: EndIf
      wi = ((u * 2) + ma) * 50
      wn = ((zn * 256) + h0) * 50
      wz = Hi(1) * 50
      wv = ab * 50
      dot = 0: dw = 0: dy = 0: dz = 0: dv = 0
      For k = 0 To 49
        dot = dot + (W(ws + k) * Sv(k))
        dw = dw + (Wx(wi + k) * Sv(k))
        dy = dy + (Wc(wn + k) * Sv(k))
        dz = dz + (Wz(wz + k) * Sv(k))
        dv = dv + (Wv(wv + k) * Sv(k))
      Next
      e = dot / 65536
      If e > 2047: e = 2047: EndIf
      If e < -2047: e = -2047: EndIf
      r1 = Sq(e + 2047)
      e = dw / 65536
      If e > 2047: e = 2047: EndIf
      If e < -2047: e = -2047: EndIf
      r2 = Sq(e + 2047)
      e = dy / 65536
      If e > 2047: e = 2047: EndIf
      If e < -2047: e = -2047: EndIf
      r3 = Sq(e + 2047)
      e = dz / 65536
      If e > 2047: e = 2047: EndIf
      If e < -2047: e = -2047: EndIf
      r4 = Sq(e + 2047)
      e = dv / 65536
      If e > 2047: e = 2047: EndIf
      If e < -2047: e = -2047: EndIf
      r5 = Sq(e + 2047)
      f = ((zn * 16) + (j * 2) + ma) * 6
      pf = (Wf(f) * St(r1)) + (Wf(f + 1) * St(r2)) + (Wf(f + 2) * St(r3)) + (Wf(f + 4) * St(r4)) + (Wf(f + 5) * St(r5)) + (Wf(f + 3) * 256)
      e = pf / 65536
      If e > 2047: e = 2047: EndIf
      If e < -2047: e = -2047: EndIf
      pm = Sq(e + 2047)
      pf = pm
      s = St(pm) + 2048
      aw = s % 128
      ai = (((h0 * 256) + c0) * 33) + (s / 128)
      pa = ((Ap(ai) * (128 - aw)) + (Ap(ai + 1) * aw)) / 2048
      u = (((((Hi(1) * 256) + h0) + 1) * $6F4F2B) / 256) % $1000000
      u = (((((u * 256) + c0) + 1) * $6F4F2B) / 256) % $1000000
      ai2 = ((u % 65536) * 33) + (s / 128)
      pa2 = ((Ap2(ai2) * (128 - aw)) + (Ap2(ai2 + 1) * aw)) / 2048
      pm = ((2 * pm) + (3 * pa) + (3 * pa2)) / 8
      If pm < 1: pm = 1: EndIf
      If pm > 4095: pm = 4095: EndIf
      If pos >= P
        xm = x1 + (((x2 - x1) / 4096) * pm)
        y = (c / P2(7 - j)) % 2
        If y: x2 = xm: Else: x1 = xm + 1: EndIf
      Else
        y = (c / P2(7 - j)) % 2
      EndIf
      er = ((y * 4096) - r1) * 2
      e2 = ((y * 4096) - r2) * 2
      e3 = ((y * 4096) - r3) * 2
      e4 = ((y * 4096) - r4) * 2
      e5 = ((y * 4096) - r5) * 2
      For k = 0 To 49
        W(ws + k) = W(ws + k) + ((Sv(k) * er) / 8192)
        Wx(wi + k) = Wx(wi + k) + ((Sv(k) * e2) / 8192)
        Wc(wn + k) = Wc(wn + k) + ((Sv(k) * e3) / 8192)
        Wz(wz + k) = Wz(wz + k) + ((Sv(k) * e4) / 8192)
        Wv(wv + k) = Wv(wv + k) + ((Sv(k) * e5) / 8192)
      Next
      For k = 0 To 23
        hb = Bh(Ix(k))
        si = (k * 65536) + hb + (256 * c0)
        u = SM(si) / 256
        v = SM(si) % 256
        If y: u = u + (((65536 - u) * Kr(v)) / 4096): Else: u = u - ((u * Kr(v)) / 4096): EndIf
        If v < 60: v = v + 1: EndIf
        SM(si) = (u * 256) + v
        n0 = hb % 8
        n1 = (hb / 8) % 8
        hh = hb / 64
        If y
          If n1 < 7: n1 = n1 + 1: EndIf
          If n0 > 2: n0 = (n0 / 2) + 1: EndIf
        Else
          If n0 < 7: n0 = n0 + 1: EndIf
          If n1 > 2: n1 = (n1 / 2) + 1: EndIf
        EndIf
        Bh(Ix(k)) = n0 + (n1 * 8) + ((((hh * 2) + y) % 4) * 64)
        u = M(Ix(k)) / 256
        v = M(Ix(k)) % 256
        If y: u = u + (((65536 - u) * Kr(v)) / 4096): Else: u = u - ((u * Kr(v)) / 4096): EndIf
        If v < 127: v = v + 1: EndIf
        M(Ix(k)) = (u * 256) + v
      Next
      If ma
        u = MS(im) / 256
        v = MS(im) % 256
        If y: u = u + (((65536 - u) * Kr(v)) / 4096): Else: u = u - ((u * Kr(v)) / 4096): EndIf
        If v < 127: v = v + 1: EndIf
        MS(im) = (u * 256) + v
      EndIf
      g = (y * 65536) + (y * 64) - (2 * y)
      Ap(ai) = Ap(ai) + (((g - Ap(ai)) * (128 - aw)) / 8192)
      Ap(ai + 1) = Ap(ai + 1) + (((g - Ap(ai + 1)) * aw) / 8192)
      Ap2(ai2) = Ap2(ai2) + (((g - Ap2(ai2)) * (128 - aw)) / 8192)
      Ap2(ai2 + 1) = Ap2(ai2 + 1) + (((g - Ap2(ai2 + 1)) * aw) / 8192)
      ef = ((y * 4096) - pf) * 2
      Wf(f + 0) = Wf(f + 0) + ((St(r1) * ef) / 32768)
      Wf(f + 1) = Wf(f + 1) + ((St(r2) * ef) / 32768)
      Wf(f + 2) = Wf(f + 2) + ((St(r3) * ef) / 32768)
      Wf(f + 3) = Wf(f + 3) + ((256 * ef) / 32768)
      Wf(f + 4) = Wf(f + 4) + ((St(r4) * ef) / 32768)
      Wf(f + 5) = Wf(f + 5) + ((St(r5) * ef) / 32768)
      c0 = (c0 * 2) + y
      While x1 / 16777216 = x2 / 16777216
        PokeA(*O + no, x2 / 16777216)
        no = no + 1
        x1 = (x1 % 16777216) * 256
        x2 = ((x2 % 16777216) * 256) + 255
      Wend
    Next
    If pos >= P: chk = ((chk * 33) + c) % 1000000007: EndIf
    I1(h0) = ((I1(h0) * 256) + c) % 65536
    v = (Hi(1) * 256) + h0
    I2(v) = ((I2(v) * 256) + c) % 65536
    lt = 0
    If (c >= 48 And c <= 57) Or (c >= 65 And c <= 90) Or (c >= 97 And c <= 122) Or c = 95: lt = 1: EndIf
    l1 = 0
    If (h0 >= 48 And h0 <= 57) Or (h0 >= 65 And h0 <= 90) Or (h0 >= 97 And h0 <= 122) Or h0 = 95: l1 = 1: EndIf
    If c = 10
      tk = 0
    ElseIf c <> 32 And (lt = 0 Or l1 = 0)
      tk = tk + 1
    EndIf
    For k = 7 To 1 Step -1
      Hi(k) = Hi(k - 1)
    Next
    Hi(0) = c
    If c = 10
      If fw <> 0
        LF(fw % 65536) = ls
        LE(fw % 65536) = pos
      EndIf
      ppl = pl: pl = ls: ls = pos + 1: pfw = fw: fw = 0: fwf = 0: nd = 0: bd = 0
    EndIf
    If zn = 0
      If c = 40 And bd < 7
        bd = bd + 1
      ElseIf c = 41 And bd > 0
        bd = bd - 1
      EndIf
    EndIf
    If lt
      If wh = 0: wc = Hi(1): EndIf
      wh = ((((wh + c) + 1) * $6F4F2B) / 256) % $1000000
    Else
      If wh <> 0: wp = wh: EndIf
      wh = 0
    EndIf
    If c = 32 And fwf = 0 And fw = 0: nd = nd + 1: EndIf
    If fwf = 0
      If lt
        fw = (((((fw * 256) + c) + 1) * $6F4F2B) / 256) % $1000000
      ElseIf fw > 0
        fwf = 1
      EndIf
    EndIf
    If zn = 0
      If c = 59
        zn = 2
      ElseIf c = 34
        zn = 1
      EndIf
    ElseIf zn = 1
      If c = 34 Or c = 10: zn = 0: EndIf
    ElseIf c = 10
      zn = 0
    EndIf
  Next
  For k = 1 To 4
    PokeA(*O + no, x1 / 16777216)
    no = no + 1
    x1 = (x1 % 16777216) * 256
  Next

  ProcedureReturn no
EndProcedure
EnableDebugger


; ----------------------------------------------------------------------------
;  Méthode "Maximal" version 4: vérificateur. Même décompresseur que
;  DecoderCM4, mais il travaille dans un second thread PENDANT la compression:
;  il attend chaque octet compressé jusqu'à ce que la compression l'ait produit
;  (AttendreOctets), et n'affiche rien. Il ne sert que pendant une compression.
;  *C = octets compressés (remplis au fur et à mesure), *D = texte de référence
;  (P octets) suivi de la place pour T octets. Renvoie la somme de contrôle.
; ----------------------------------------------------------------------------
DisableDebugger
Procedure.q VerifierCM4(*C, T.q, *D, P.q, EtatLu.q, EtatEcrit.q)
  Protected.q i, u, v, charge, crc, x, ip, dispo, x1, x2, ml, mp, ma, chk, wh, wp, wc, fw, fwf, pfw, nd, bd, tk, zn, ls, pl, ppl, Debut, h0, h, k, hm, h8, ab, u2, ab2, a, a1, a2, sr, sf, a3, h16, b, c, c0, j, ws, ck, pb, im, wi, wn, wz, wv, dot, dw, dy, dz, dv, e, r1, r2, r3, r4, r5, f, pf, pm, s, aw, ai, pa, ai2, pa2, xm, y, er, e2, e3, e4, e5, hb, si, n0, n1, hh, g, ef, lt, l1, pos

  Dim T33.q(32)
  Restore Sq33
  For i = 0 To 32
    Read.q u
    T33(i) = u
  Next
  Dim Sq.q(4094)
  For i = 0 To 4094
    u = (i + 1) % 128
    v = (i + 1) / 128
    Sq(i) = ((T33(v) * (128 - u)) + (T33(v + 1) * u) + 64) / 128
  Next
  Dim St.q(4095)
  v = 0
  For i = 0 To 4094
    While v <= Sq(i)
      St(v) = i - 2047
      v = v + 1
    Wend
  Next
  While v <= 4095
    St(v) = 2047
    v = v + 1
  Wend
  Dim Kr.q(255)
  For i = 0 To 255
    Kr(i) = 8192 / ((2 * i) + 3)
  Next
  Dim P2.q(8)
  P2(0) = 1
  For i = 1 To 8
    P2(i) = P2(i - 1) * 2
  Next
  Dim M.l(100663295)
  Dim Bh.a(100663295)
  Dim Kc.a(100663295)
  Dim SM.q(1572863)
  Dim MT.l(1048575)
  Dim MT2.l(1048575)
  Dim MT3.l(1048575)
  Dim MS.q(63)
  Dim W.q(12799)
  Dim Wx.q(1599)
  Dim Wc.q(38399)
  Dim Wz.q(12799)
  Dim Wv.q(12799)
  Dim Wf.q(383)
  Dim Ap.q(2162687)
  Dim Ap2.q(2162687)
  Dim I1.q(255)
  Dim I2.q(65535)
  Dim LF.q(65535)
  Dim LE.q(65535)
  Dim Hi.q(7)
  Dim Hc.q(23)
  Dim Ix.q(23)
  Dim Sv.q(49)
  Dim Es.q(81)
  charge = 0
  If EtatLu <> 0
    crc = 0
    crc = EchangeTableauL(EtatLu, 0, M(), crc)
    crc = EchangeTableauA(EtatLu, 0, Bh(), crc)
    crc = EchangeTableauA(EtatLu, 0, Kc(), crc)
    crc = EchangeTableauQ(EtatLu, 0, SM(), crc)
    crc = EchangeTableauL(EtatLu, 0, MT(), crc)
    crc = EchangeTableauL(EtatLu, 0, MT2(), crc)
    crc = EchangeTableauL(EtatLu, 0, MT3(), crc)
    crc = EchangeTableauQ(EtatLu, 0, MS(), crc)
    crc = EchangeTableauQ(EtatLu, 0, W(), crc)
    crc = EchangeTableauQ(EtatLu, 0, Wx(), crc)
    crc = EchangeTableauQ(EtatLu, 0, Wc(), crc)
    crc = EchangeTableauQ(EtatLu, 0, Wz(), crc)
    crc = EchangeTableauQ(EtatLu, 0, Wv(), crc)
    crc = EchangeTableauQ(EtatLu, 0, Wf(), crc)
    crc = EchangeTableauQ(EtatLu, 0, Ap(), crc)
    crc = EchangeTableauQ(EtatLu, 0, Ap2(), crc)
    crc = EchangeTableauQ(EtatLu, 0, I1(), crc)
    crc = EchangeTableauQ(EtatLu, 0, I2(), crc)
    crc = EchangeTableauQ(EtatLu, 0, LF(), crc)
    crc = EchangeTableauQ(EtatLu, 0, LE(), crc)
    crc = EchangeTableauQ(EtatLu, 0, Hi(), crc)
    crc = EchangeTableauQ(EtatLu, 0, Hc(), crc)
    crc = EchangeTableauQ(EtatLu, 0, Ix(), crc)
    crc = EchangeTableauQ(EtatLu, 0, Sv(), crc)
    crc = EchangeTableauQ(EtatLu, 0, Es(), crc)
    If crc >= 0 And crc = LireControleEtat(EtatLu)
      charge = 1
    Else
      SignalerEtatAbime()
    EndIf
  EndIf
  If charge = 0
    If EtatLu <> 0
      Dim M.l(100663295)
      Dim Bh.a(100663295)
      Dim Kc.a(100663295)
      Dim SM.q(1572863)
      Dim MT.l(1048575)
      Dim MT2.l(1048575)
      Dim MT3.l(1048575)
      Dim MS.q(63)
      Dim W.q(12799)
      Dim Wx.q(1599)
      Dim Wc.q(38399)
      Dim Wz.q(12799)
      Dim Wv.q(12799)
      Dim Wf.q(383)
      Dim Ap.q(2162687)
      Dim Ap2.q(2162687)
      Dim I1.q(255)
      Dim I2.q(65535)
      Dim LF.q(65535)
      Dim LE.q(65535)
      Dim Hi.q(7)
      Dim Hc.q(23)
      Dim Ix.q(23)
      Dim Sv.q(49)
      Dim Es.q(81)
    EndIf
    For i = 0 To 100663295
      M(i) = 8388608
    Next
    For i = 0 To 1572863
      SM(i) = 8388608
    Next
    For i = 0 To 63
      MS(i) = 8388608
    Next
    For i = 0 To 12799
      W(i) = 2621
    Next
    For i = 0 To 1599
      Wx(i) = 2621
    Next
    For i = 0 To 38399
      Wc(i) = 2621
    Next
    For i = 0 To 12799
      Wz(i) = 2621
    Next
    For i = 0 To 12799
      Wv(i) = 2621
    Next
    For i = 0 To 383
      If i % 6 = 3: Wf(i) = 0: Else: Wf(i) = 13107: EndIf
    Next
    For i = 0 To 2162687
      u = ((i % 33) * 128) - 1
      If u < 0: u = 0: EndIf
      If u > 4094: u = 4094: EndIf
      Ap(i) = Sq(u) * 16
    Next
    For i = 0 To 2162687
      u = ((i % 33) * 128) - 1
      If u < 0: u = 0: EndIf
      If u > 4094: u = 4094: EndIf
      Ap2(i) = Sq(u) * 16
    Next
  EndIf
  x = 0: ip = 0
  dispo = 0
  x1 = 0: x2 = 4294967295: ml = 0: mp = 0: ma = 0: chk = 0
  wh = 0: wp = 0: wc = 0: fw = 0: fwf = 0: pfw = 0: nd = 0: bd = 0: tk = 0: zn = 0
  ls = 0: pl = 0: ppl = 0
  Debut = 0
  If charge
    i = Es(0): u = Es(1): v = Es(2): ml = Es(3): mp = Es(4): ma = Es(5): wh = Es(6): wp = Es(7)
    wc = Es(8): fw = Es(9): fwf = Es(10): pfw = Es(11): nd = Es(12): bd = Es(13): tk = Es(14): zn = Es(15)
    ls = Es(16): pl = Es(17): ppl = Es(18): h0 = Es(19): h = Es(20): k = Es(21): hm = Es(22): h8 = Es(23)
    ab = Es(24): u2 = Es(25): ab2 = Es(26): a = Es(27): a1 = Es(28): a2 = Es(29): sr = Es(30): sf = Es(31)
    a3 = Es(32): h16 = Es(33): b = Es(34): c = Es(35): c0 = Es(36): j = Es(37): ws = Es(38): ck = Es(39)
    pb = Es(40): im = Es(41): wi = Es(42): wn = Es(43): wz = Es(44): wv = Es(45): dot = Es(46): dw = Es(47)
    dy = Es(48): dz = Es(49): dv = Es(50): e = Es(51): r1 = Es(52): r2 = Es(53): r3 = Es(54): r4 = Es(55)
    r5 = Es(56): f = Es(57): pf = Es(58): pm = Es(59): s = Es(60): aw = Es(61): ai = Es(62): pa = Es(63)
    ai2 = Es(64): pa2 = Es(65): xm = Es(66): y = Es(67): er = Es(68): e2 = Es(69): e3 = Es(70): e4 = Es(71)
    e5 = Es(72): hb = Es(73): si = Es(74): n0 = Es(75): n1 = Es(76): hh = Es(77): g = Es(78): ef = Es(79)
    lt = Es(80): l1 = Es(81)
    Debut = P
  EndIf
  For pos = Debut To P + T - 1
    If pos = P And EtatEcrit <> 0
      Es(0) = i: Es(1) = u: Es(2) = v: Es(3) = ml: Es(4) = mp: Es(5) = ma: Es(6) = wh: Es(7) = wp
      Es(8) = wc: Es(9) = fw: Es(10) = fwf: Es(11) = pfw: Es(12) = nd: Es(13) = bd: Es(14) = tk: Es(15) = zn
      Es(16) = ls: Es(17) = pl: Es(18) = ppl: Es(19) = h0: Es(20) = h: Es(21) = k: Es(22) = hm: Es(23) = h8
      Es(24) = ab: Es(25) = u2: Es(26) = ab2: Es(27) = a: Es(28) = a1: Es(29) = a2: Es(30) = sr: Es(31) = sf
      Es(32) = a3: Es(33) = h16: Es(34) = b: Es(35) = c: Es(36) = c0: Es(37) = j: Es(38) = ws: Es(39) = ck
      Es(40) = pb: Es(41) = im: Es(42) = wi: Es(43) = wn: Es(44) = wz: Es(45) = wv: Es(46) = dot: Es(47) = dw
      Es(48) = dy: Es(49) = dz: Es(50) = dv: Es(51) = e: Es(52) = r1: Es(53) = r2: Es(54) = r3: Es(55) = r4
      Es(56) = r5: Es(57) = f: Es(58) = pf: Es(59) = pm: Es(60) = s: Es(61) = aw: Es(62) = ai: Es(63) = pa
      Es(64) = ai2: Es(65) = pa2: Es(66) = xm: Es(67) = y: Es(68) = er: Es(69) = e2: Es(70) = e3: Es(71) = e4
      Es(72) = e5: Es(73) = hb: Es(74) = si: Es(75) = n0: Es(76) = n1: Es(77) = hh: Es(78) = g: Es(79) = ef
      Es(80) = lt: Es(81) = l1
      crc = 0
      crc = EchangeTableauL(EtatEcrit, 1, M(), crc)
      crc = EchangeTableauA(EtatEcrit, 1, Bh(), crc)
      crc = EchangeTableauA(EtatEcrit, 1, Kc(), crc)
      crc = EchangeTableauQ(EtatEcrit, 1, SM(), crc)
      crc = EchangeTableauL(EtatEcrit, 1, MT(), crc)
      crc = EchangeTableauL(EtatEcrit, 1, MT2(), crc)
      crc = EchangeTableauL(EtatEcrit, 1, MT3(), crc)
      crc = EchangeTableauQ(EtatEcrit, 1, MS(), crc)
      crc = EchangeTableauQ(EtatEcrit, 1, W(), crc)
      crc = EchangeTableauQ(EtatEcrit, 1, Wx(), crc)
      crc = EchangeTableauQ(EtatEcrit, 1, Wc(), crc)
      crc = EchangeTableauQ(EtatEcrit, 1, Wz(), crc)
      crc = EchangeTableauQ(EtatEcrit, 1, Wv(), crc)
      crc = EchangeTableauQ(EtatEcrit, 1, Wf(), crc)
      crc = EchangeTableauQ(EtatEcrit, 1, Ap(), crc)
      crc = EchangeTableauQ(EtatEcrit, 1, Ap2(), crc)
      crc = EchangeTableauQ(EtatEcrit, 1, I1(), crc)
      crc = EchangeTableauQ(EtatEcrit, 1, I2(), crc)
      crc = EchangeTableauQ(EtatEcrit, 1, LF(), crc)
      crc = EchangeTableauQ(EtatEcrit, 1, LE(), crc)
      crc = EchangeTableauQ(EtatEcrit, 1, Hi(), crc)
      crc = EchangeTableauQ(EtatEcrit, 1, Hc(), crc)
      crc = EchangeTableauQ(EtatEcrit, 1, Ix(), crc)
      crc = EchangeTableauQ(EtatEcrit, 1, Sv(), crc)
      crc = EchangeTableauQ(EtatEcrit, 1, Es(), crc)
      EcrireControleEtat(EtatEcrit, crc)
    EndIf
    If pos = P
      For k = 1 To 4
        x = x * 256
        If ip >= dispo: dispo = AttendreOctets(ip): EndIf
        If ip < dispo: x = x + PeekA(*C + ip): EndIf
        ip = ip + 1
      Next
    EndIf
    h0 = Hi(0)
    h = 0
    For k = 0 To 7
      h = ((((h + Hi(k)) + 1) * $6F4F2B) / 256) % $1000000
      If k < 4: Hc(k) = h: EndIf
      If k = 4: hm = h % $100000: EndIf
    Next
    h8 = h
    Hc(4) = (((((wh * 256) + h0) + 1) * $6F4F2B) / 256) % $1000000
    ab = 0
    If pl + pos - ls < ls: ab = PeekA(*D + pl + pos - ls): EndIf
    Hc(5) = (((((ab * 256) + h0) + 1048577) * $6F4F2B) / 256) % $1000000
    Hc(6) = h8
    u = (((((wh * 256) + (wp % 256)) + 1) * $6F4F2B) / 256) % $1000000
    u = (((((u * 256) + ((wp / 256) % 256)) + 1) * $6F4F2B) / 256) % $1000000
    u = (((((u * 256) + (wp / 65536)) + 1) * $6F4F2B) / 256) % $1000000
    Hc(7) = (((((u * 256) + (h0 + 2)) + 1) * $6F4F2B) / 256) % $1000000
    u = (((((fw * 256) + (wh % 256)) + 1) * $6F4F2B) / 256) % $1000000
    u = (((((u * 256) + ((wh / 256) % 256)) + 1) * $6F4F2B) / 256) % $1000000
    u = (((((u * 256) + (wh / 65536)) + 1) * $6F4F2B) / 256) % $1000000
    Hc(8) = (((((u * 256) + 3) + 1) * $6F4F2B) / 256) % $1000000
    u2 = u
    v = (h0 * 256) + Hi(1)
    u = (((((nd * 256) + (v % 256)) + 1) * $6F4F2B) / 256) % $1000000
    u = (((((u * 256) + ((v / 256) % 256)) + 1) * $6F4F2B) / 256) % $1000000
    u = (((((u * 256) + (v / 65536)) + 1) * $6F4F2B) / 256) % $1000000
    Hc(9) = (((((u * 256) + 4) + 1) * $6F4F2B) / 256) % $1000000
    u = (((((bd * 256) + (v % 256)) + 1) * $6F4F2B) / 256) % $1000000
    u = (((((u * 256) + ((v / 256) % 256)) + 1) * $6F4F2B) / 256) % $1000000
    u = (((((u * 256) + (v / 65536)) + 1) * $6F4F2B) / 256) % $1000000
    Hc(10) = (((((u * 256) + 6) + 1) * $6F4F2B) / 256) % $1000000
    ab2 = 0
    If pl + pos - ls + 1 < ls: ab2 = PeekA(*D + pl + pos - ls + 1): EndIf
    a = (ab * 256) + ab2
    u = (((((a * 256) + (h0 % 256)) + 1) * $6F4F2B) / 256) % $1000000
    u = (((((u * 256) + ((h0 / 256) % 256)) + 1) * $6F4F2B) / 256) % $1000000
    u = (((((u * 256) + (h0 / 65536)) + 1) * $6F4F2B) / 256) % $1000000
    Hc(11) = (((((u * 256) + 7) + 1) * $6F4F2B) / 256) % $1000000
    u = (((((pfw * 256) + (u2 % 256)) + 1) * $6F4F2B) / 256) % $1000000
    u = (((((u * 256) + ((u2 / 256) % 256)) + 1) * $6F4F2B) / 256) % $1000000
    u = (((((u * 256) + (u2 / 65536)) + 1) * $6F4F2B) / 256) % $1000000
    Hc(12) = (((((u * 256) + 8) + 1) * $6F4F2B) / 256) % $1000000
    Hc(13) = (((((((Hi(1) * 256) + Hi(2)) * 256) + 9) + 1) * $6F4F2B) / 256) % $1000000
    u = (((((wh * 256) + (wc % 256)) + 1) * $6F4F2B) / 256) % $1000000
    u = (((((u * 256) + ((wc / 256) % 256)) + 1) * $6F4F2B) / 256) % $1000000
    u = (((((u * 256) + (wc / 65536)) + 1) * $6F4F2B) / 256) % $1000000
    Hc(14) = (((((u * 256) + 10) + 1) * $6F4F2B) / 256) % $1000000
    a1 = 0: a2 = 0
    If ppl + pos - ls < pl: a1 = PeekA(*D + ppl + pos - ls): EndIf
    If ppl + pos - ls + 1 < pl: a2 = PeekA(*D + ppl + pos - ls + 1): EndIf
    a = (a1 * 256) + a2
    u = (((((a * 256) + (h0 % 256)) + 1) * $6F4F2B) / 256) % $1000000
    u = (((((u * 256) + ((h0 / 256) % 256)) + 1) * $6F4F2B) / 256) % $1000000
    u = (((((u * 256) + (h0 / 65536)) + 1) * $6F4F2B) / 256) % $1000000
    Hc(15) = (((((u * 256) + 14) + 1) * $6F4F2B) / 256) % $1000000
    a = I1(h0)
    u = (((((a * 256) + (h0 % 256)) + 1) * $6F4F2B) / 256) % $1000000
    u = (((((u * 256) + ((h0 / 256) % 256)) + 1) * $6F4F2B) / 256) % $1000000
    u = (((((u * 256) + (h0 / 65536)) + 1) * $6F4F2B) / 256) % $1000000
    Hc(16) = (((((u * 256) + 19) + 1) * $6F4F2B) / 256) % $1000000
    a = I2((Hi(1) * 256) + h0)
    u = (((((a * 256) + (h0 % 256)) + 1) * $6F4F2B) / 256) % $1000000
    u = (((((u * 256) + ((h0 / 256) % 256)) + 1) * $6F4F2B) / 256) % $1000000
    u = (((((u * 256) + (h0 / 65536)) + 1) * $6F4F2B) / 256) % $1000000
    Hc(17) = (((((u * 256) + 17) + 1) * $6F4F2B) / 256) % $1000000
    a = tk
    If a > 15: a = 15: EndIf
    a = (a * 256) + h0
    u = (((((a * 256) + (fw % 256)) + 1) * $6F4F2B) / 256) % $1000000
    u = (((((u * 256) + ((fw / 256) % 256)) + 1) * $6F4F2B) / 256) % $1000000
    u = (((((u * 256) + (fw / 65536)) + 1) * $6F4F2B) / 256) % $1000000
    Hc(18) = (((((u * 256) + 18) + 1) * $6F4F2B) / 256) % $1000000
    a1 = 0: a2 = 0: sr = 0: sf = 0
    If fwf = 1 And fw <> 0: sr = LF(fw % 65536): sf = LE(fw % 65536): EndIf
    If sr + pos - ls < sf: a1 = PeekA(*D + sr + pos - ls): EndIf
    If sr + pos - ls + 1 < sf: a2 = PeekA(*D + sr + pos - ls + 1): EndIf
    a = (a1 * 256) + a2
    u = (((((a * 256) + (v % 256)) + 1) * $6F4F2B) / 256) % $1000000
    u = (((((u * 256) + ((v / 256) % 256)) + 1) * $6F4F2B) / 256) % $1000000
    u = (((((u * 256) + (v / 65536)) + 1) * $6F4F2B) / 256) % $1000000
    Hc(19) = (((((u * 256) + 16) + 1) * $6F4F2B) / 256) % $1000000
    a = pos - ls
    If a > 79: a = 79: EndIf
    Hc(20) = (((((((a * 256) + h0) * 256) + 11) + 1) * $6F4F2B) / 256) % $1000000
    a1 = 0: a3 = 0
    If pl + pos - ls - 1 < ls And pos > ls: a1 = PeekA(*D + pl + pos - ls - 1): EndIf
    If pl + pos - ls + 2 < ls: a3 = PeekA(*D + pl + pos - ls + 2): EndIf
    a = (a1 * 65536) + (ab * 256) + a3
    u = (((((a * 256) + (v % 256)) + 1) * $6F4F2B) / 256) % $1000000
    u = (((((u * 256) + ((v / 256) % 256)) + 1) * $6F4F2B) / 256) % $1000000
    u = (((((u * 256) + (v / 65536)) + 1) * $6F4F2B) / 256) % $1000000
    Hc(21) = (((((u * 256) + 12) + 1) * $6F4F2B) / 256) % $1000000
    If ml > 0 And PeekA(*D + mp) = h0
      If ml < 65535: ml = ml + 1: EndIf
      mp = mp + 1
    Else
      ml = 0
    EndIf
    h16 = 0
    If pos >= 16
      For k = 16 To 1 Step -1
        h16 = ((((h16 + PeekA(*D + pos - k)) + 1) * $6F4F2B) / 256) % $1000000
      Next
    EndIf
    If ml = 0 And pos >= 16
      mp = MT3(h16 % $100000)
      While mp > 0 And ml < 124 And ml < mp
        If PeekA(*D + mp - ml - 1) <> PeekA(*D + pos - ml - 1): Break: EndIf
        ml = ml + 1
      Wend
    EndIf
    If pos >= 16: MT3(h16 % $100000) = pos: EndIf
    If ml = 0 And pos >= 8
      mp = MT2(h8 % $100000)
      While mp > 0 And ml < 124 And ml < mp
        If PeekA(*D + mp - ml - 1) <> PeekA(*D + pos - ml - 1): Break: EndIf
        ml = ml + 1
      Wend
    EndIf
    If ml = 0 And pos >= 5
      mp = MT(hm)
      While mp > 0 And ml < 124 And ml < mp
        If PeekA(*D + mp - ml - 1) <> PeekA(*D + pos - ml - 1): Break: EndIf
        ml = ml + 1
      Wend
    EndIf
    MT(hm) = pos
    MT2(h8 % $100000) = pos
    ma = Bool(ml > 0)
    a = ml
    If a > 15: a = 15: EndIf
    b = 0
    If ma: b = PeekA(*D + mp): EndIf
    u = (((((a * 256) + (b % 256)) + 1) * $6F4F2B) / 256) % $1000000
    u = (((((u * 256) + ((b / 256) % 256)) + 1) * $6F4F2B) / 256) % $1000000
    u = (((((u * 256) + (b / 65536)) + 1) * $6F4F2B) / 256) % $1000000
    Hc(22) = (((((u * 256) + 5) + 1) * $6F4F2B) / 256) % $1000000
    a = 0
    If ma: a = PeekA(*D + mp) + 256: EndIf
    u = (((((a * 256) + (v % 256)) + 1) * $6F4F2B) / 256) % $1000000
    u = (((((u * 256) + ((v / 256) % 256)) + 1) * $6F4F2B) / 256) % $1000000
    u = (((((u * 256) + (v / 65536)) + 1) * $6F4F2B) / 256) % $1000000
    Hc(23) = (((((u * 256) + 13) + 1) * $6F4F2B) / 256) % $1000000
    c = PeekA(*D + pos)
    c0 = 1
    For j = 0 To 7
      ws = c0 * 50
      For k = 0 To 23
        Ix(k) = (((((Hc(k) * 256) + c0) * $2E8BA3) / 1024) % $400000) + (k * $400000)
        ck = ((((Hc(k) * 256) + c0) / 4096) % 255) + 1
        If Kc(Ix(k)) <> ck
          Kc(Ix(k)) = ck
          M(Ix(k)) = 8388608
          Bh(Ix(k)) = 0
        EndIf
        Sv(k * 2) = St(M(Ix(k)) / 4096)
        Sv((k * 2) + 1) = St(SM((k * 65536) + Bh(Ix(k)) + (256 * c0)) / 4096)
      Next
      Sv(48) = 256
      Sv(49) = 0
      If ma
        pb = PeekA(*D + mp) + 256
        If pb / P2(8 - j) = c0
          u = ml
          If u > 31: u = 31: EndIf
          im = (u * 2) + ((pb / P2(7 - j)) % 2)
          Sv(49) = St(MS(im) / 4096)
        Else
          ma = 0
        EndIf
      EndIf
      u = ml
      If u > 15: u = 15: EndIf
      wi = ((u * 2) + ma) * 50
      wn = ((zn * 256) + h0) * 50
      wz = Hi(1) * 50
      wv = ab * 50
      dot = 0: dw = 0: dy = 0: dz = 0: dv = 0
      For k = 0 To 49
        dot = dot + (W(ws + k) * Sv(k))
        dw = dw + (Wx(wi + k) * Sv(k))
        dy = dy + (Wc(wn + k) * Sv(k))
        dz = dz + (Wz(wz + k) * Sv(k))
        dv = dv + (Wv(wv + k) * Sv(k))
      Next
      e = dot / 65536
      If e > 2047: e = 2047: EndIf
      If e < -2047: e = -2047: EndIf
      r1 = Sq(e + 2047)
      e = dw / 65536
      If e > 2047: e = 2047: EndIf
      If e < -2047: e = -2047: EndIf
      r2 = Sq(e + 2047)
      e = dy / 65536
      If e > 2047: e = 2047: EndIf
      If e < -2047: e = -2047: EndIf
      r3 = Sq(e + 2047)
      e = dz / 65536
      If e > 2047: e = 2047: EndIf
      If e < -2047: e = -2047: EndIf
      r4 = Sq(e + 2047)
      e = dv / 65536
      If e > 2047: e = 2047: EndIf
      If e < -2047: e = -2047: EndIf
      r5 = Sq(e + 2047)
      f = ((zn * 16) + (j * 2) + ma) * 6
      pf = (Wf(f) * St(r1)) + (Wf(f + 1) * St(r2)) + (Wf(f + 2) * St(r3)) + (Wf(f + 4) * St(r4)) + (Wf(f + 5) * St(r5)) + (Wf(f + 3) * 256)
      e = pf / 65536
      If e > 2047: e = 2047: EndIf
      If e < -2047: e = -2047: EndIf
      pm = Sq(e + 2047)
      pf = pm
      s = St(pm) + 2048
      aw = s % 128
      ai = (((h0 * 256) + c0) * 33) + (s / 128)
      pa = ((Ap(ai) * (128 - aw)) + (Ap(ai + 1) * aw)) / 2048
      u = (((((Hi(1) * 256) + h0) + 1) * $6F4F2B) / 256) % $1000000
      u = (((((u * 256) + c0) + 1) * $6F4F2B) / 256) % $1000000
      ai2 = ((u % 65536) * 33) + (s / 128)
      pa2 = ((Ap2(ai2) * (128 - aw)) + (Ap2(ai2 + 1) * aw)) / 2048
      pm = ((2 * pm) + (3 * pa) + (3 * pa2)) / 8
      If pm < 1: pm = 1: EndIf
      If pm > 4095: pm = 4095: EndIf
      If pos >= P
        xm = x1 + (((x2 - x1) / 4096) * pm)
        y = Bool(x <= xm)
        If y: x2 = xm: Else: x1 = xm + 1: EndIf
      Else
        y = (c / P2(7 - j)) % 2
      EndIf
      er = ((y * 4096) - r1) * 2
      e2 = ((y * 4096) - r2) * 2
      e3 = ((y * 4096) - r3) * 2
      e4 = ((y * 4096) - r4) * 2
      e5 = ((y * 4096) - r5) * 2
      For k = 0 To 49
        W(ws + k) = W(ws + k) + ((Sv(k) * er) / 8192)
        Wx(wi + k) = Wx(wi + k) + ((Sv(k) * e2) / 8192)
        Wc(wn + k) = Wc(wn + k) + ((Sv(k) * e3) / 8192)
        Wz(wz + k) = Wz(wz + k) + ((Sv(k) * e4) / 8192)
        Wv(wv + k) = Wv(wv + k) + ((Sv(k) * e5) / 8192)
      Next
      For k = 0 To 23
        hb = Bh(Ix(k))
        si = (k * 65536) + hb + (256 * c0)
        u = SM(si) / 256
        v = SM(si) % 256
        If y: u = u + (((65536 - u) * Kr(v)) / 4096): Else: u = u - ((u * Kr(v)) / 4096): EndIf
        If v < 60: v = v + 1: EndIf
        SM(si) = (u * 256) + v
        n0 = hb % 8
        n1 = (hb / 8) % 8
        hh = hb / 64
        If y
          If n1 < 7: n1 = n1 + 1: EndIf
          If n0 > 2: n0 = (n0 / 2) + 1: EndIf
        Else
          If n0 < 7: n0 = n0 + 1: EndIf
          If n1 > 2: n1 = (n1 / 2) + 1: EndIf
        EndIf
        Bh(Ix(k)) = n0 + (n1 * 8) + ((((hh * 2) + y) % 4) * 64)
        u = M(Ix(k)) / 256
        v = M(Ix(k)) % 256
        If y: u = u + (((65536 - u) * Kr(v)) / 4096): Else: u = u - ((u * Kr(v)) / 4096): EndIf
        If v < 127: v = v + 1: EndIf
        M(Ix(k)) = (u * 256) + v
      Next
      If ma
        u = MS(im) / 256
        v = MS(im) % 256
        If y: u = u + (((65536 - u) * Kr(v)) / 4096): Else: u = u - ((u * Kr(v)) / 4096): EndIf
        If v < 127: v = v + 1: EndIf
        MS(im) = (u * 256) + v
      EndIf
      g = (y * 65536) + (y * 64) - (2 * y)
      Ap(ai) = Ap(ai) + (((g - Ap(ai)) * (128 - aw)) / 8192)
      Ap(ai + 1) = Ap(ai + 1) + (((g - Ap(ai + 1)) * aw) / 8192)
      Ap2(ai2) = Ap2(ai2) + (((g - Ap2(ai2)) * (128 - aw)) / 8192)
      Ap2(ai2 + 1) = Ap2(ai2 + 1) + (((g - Ap2(ai2 + 1)) * aw) / 8192)
      ef = ((y * 4096) - pf) * 2
      Wf(f + 0) = Wf(f + 0) + ((St(r1) * ef) / 32768)
      Wf(f + 1) = Wf(f + 1) + ((St(r2) * ef) / 32768)
      Wf(f + 2) = Wf(f + 2) + ((St(r3) * ef) / 32768)
      Wf(f + 3) = Wf(f + 3) + ((256 * ef) / 32768)
      Wf(f + 4) = Wf(f + 4) + ((St(r4) * ef) / 32768)
      Wf(f + 5) = Wf(f + 5) + ((St(r5) * ef) / 32768)
      c0 = (c0 * 2) + y
      While x1 / 16777216 = x2 / 16777216
        x1 = (x1 % 16777216) * 256
        x2 = ((x2 % 16777216) * 256) + 255
        x = (x % 16777216) * 256
        If ip >= dispo: dispo = AttendreOctets(ip): EndIf
        If ip < dispo: x = x + PeekA(*C + ip): EndIf
        ip = ip + 1
      Wend
    Next
    c = c0 - 256
    PokeA(*D + pos, c)
    If pos >= P: chk = ((chk * 33) + c) % 1000000007: EndIf
    I1(h0) = ((I1(h0) * 256) + c) % 65536
    v = (Hi(1) * 256) + h0
    I2(v) = ((I2(v) * 256) + c) % 65536
    lt = 0
    If (c >= 48 And c <= 57) Or (c >= 65 And c <= 90) Or (c >= 97 And c <= 122) Or c = 95: lt = 1: EndIf
    l1 = 0
    If (h0 >= 48 And h0 <= 57) Or (h0 >= 65 And h0 <= 90) Or (h0 >= 97 And h0 <= 122) Or h0 = 95: l1 = 1: EndIf
    If c = 10
      tk = 0
    ElseIf c <> 32 And (lt = 0 Or l1 = 0)
      tk = tk + 1
    EndIf
    For k = 7 To 1 Step -1
      Hi(k) = Hi(k - 1)
    Next
    Hi(0) = c
    If c = 10
      If fw <> 0
        LF(fw % 65536) = ls
        LE(fw % 65536) = pos
      EndIf
      ppl = pl: pl = ls: ls = pos + 1: pfw = fw: fw = 0: fwf = 0: nd = 0: bd = 0
    EndIf
    If zn = 0
      If c = 40 And bd < 7
        bd = bd + 1
      ElseIf c = 41 And bd > 0
        bd = bd - 1
      EndIf
    EndIf
    If lt
      If wh = 0: wc = Hi(1): EndIf
      wh = ((((wh + c) + 1) * $6F4F2B) / 256) % $1000000
    Else
      If wh <> 0: wp = wh: EndIf
      wh = 0
    EndIf
    If c = 32 And fwf = 0 And fw = 0: nd = nd + 1: EndIf
    If fwf = 0
      If lt
        fw = (((((fw * 256) + c) + 1) * $6F4F2B) / 256) % $1000000
      ElseIf fw > 0
        fwf = 1
      EndIf
    EndIf
    If zn = 0
      If c = 59
        zn = 2
      ElseIf c = 34
        zn = 1
      EndIf
    ElseIf zn = 1
      If c = 34 Or c = 10: zn = 0: EndIf
    ElseIf c = 10
      zn = 0
    EndIf
  Next

  ProcedureReturn chk
EndProcedure
EnableDebugger


; ----------------------------------------------------------------------------
;  Compression et vérification en même temps (seulement si le programme est
;  compilé avec l'option « thread-safe »). Le second thread ne touche ni aux
;  chaînes ni à la fenêtre.
; ----------------------------------------------------------------------------
CompilerIf #PB_Compiler_Thread

Structure ParamVerification
  AdresseC.i      ; octets compressés (remplis au fur et à mesure par la compression)
  T.q             ; taille du code
  AdresseD.i      ; texte de référence, puis place pour le code décompressé
  P.q             ; taille du texte de référence
  Etat.i          ; état du modèle à relire (numéro de fichier), ou 0
  Resultat.q      ; somme de contrôle du code décompressé
EndStructure
Global ParamVerif.ParamVerification
Global VerifParalleleOk

Procedure FilVerification(*Param.ParamVerification)
  EstFilVerification = #True        ; ce thread n'affiche rien (voir AvancementEtat)
  *Param\Resultat = VerifierCM4(*Param\AdresseC, *Param\T, *Param\AdresseD, *Param\P, *Param\Etat, 0)
EndProcedure


; Compresse *Avec (texte de référence + code de Taille octets) dans *ZM, pendant
; que le second thread décompresse dans *Verif. FichierVerif: état du modèle que
; le second thread relit (ou 0). Renvoie la taille compressée, ou -1 si le
; second thread n'a pas pu démarrer (rien n'a été fait). VerifParalleleOk =
; #True si la décompression faite en même temps redonne exactement le code.
Procedure.q CompresserEnParallele(*Avec, Taille.q, *ZM, *Verif, FichierVerif, K.q, Etape$, Origine.q)
  Protected Fil
  Protected.q ZM

  VerifParalleleOk = #False
  CopyMemory(*Reference, *Verif, TailleReference)
  OctetsPublies = 0
  EncodageFini = #False
  ParamVerif\AdresseC = *ZM
  ParamVerif\T = Taille
  ParamVerif\AdresseD = *Verif
  ParamVerif\P = TailleReference
  ParamVerif\Etat = FichierVerif
  ParamVerif\Resultat = -1
  ParalleleActif = #True
  Fil = CreateThread(@FilVerification(), @ParamVerif)
  If Fil = 0
    ParalleleActif = #False
    ProcedureReturn -1
  EndIf

  CommencerPasse(Etape$, 4, Origine)
  ZM = EncoderCM4(*Avec, Taille, *ZM, TailleReference, FichierEtatLu, FichierEtatEcrit)
  TerminerPasse(TailleReference + Taille - Origine)

  ; Tout est produit: le second thread peut finir
  LockMutex(MutexCM4)
  OctetsPublies = ZM
  EncodageFini = #True
  UnlockMutex(MutexCM4)
  ParalleleActif = #False
  ProgresEtape$ = "Fin de la vérification"
  While WaitThread(Fil, 100) = 0
    AfficherProgression(ProgresFait)
  Wend

  VerifParalleleOk = Bool(ParamVerif\Resultat = K And CompareMemory(*Verif + TailleReference, *Avec + TailleReference, Taille))
  ProcedureReturn ZM
EndProcedure

CompilerEndIf


; ----------------------------------------------------------------------------
;  Pourquoi la vérification ne se fait pas en même temps que la compression
;  (texte court, pour l'affichage).
; ----------------------------------------------------------------------------
Procedure.s RaisonSansParallele()
  Protected Raison$
  CompilerIf #PB_Compiler_Thread
    Protected.q Libre, Besoin

    Libre  = MemoryStatus(#PB_System_FreePhysical)
    Besoin = (2 * #MemoireMethode4) + (200 * 1024 * 1024)
    If MutexCM4 = 0
      Raison$ = "second thread impossible"
    ElseIf Libre < Besoin
      Raison$ = "pas assez de mémoire libre pour deux modèles: " + Str(Libre / (1024 * 1024)) + " Mo libres, il en faut " + Str(Besoin / (1024 * 1024))
    Else
      Raison$ = "mémoire refusée pour le second thread"
    EndIf
  CompilerElse
    Raison$ = "option « Activer la gestion des Threads » non cochée dans le compilateur"
  CompilerEndIf
  ProcedureReturn Raison$
EndProcedure


; ----------------------------------------------------------------------------
;  Vérification de la méthode v4 par une décompression complète, quand elle
;  n'a pas été faite en même temps que la compression: relit l'état gardé sur
;  le disque s'il existe, sinon le texte de référence. Renvoie #True si elle
;  redonne exactement *Attendu (T octets).
; ----------------------------------------------------------------------------
Procedure VerifierModele4(*C, Z.q, T.q, *Attendu, Niveau)
  Protected Fichier, Ok
  Protected.q Origine
  Protected *D

  *D = AllocateMemory(TailleReference + T + 16)
  If *D = 0
    ProcedureReturn #False
  EndIf
  EtatAbime = #False
  If EtatUtile(Niveau)
    Fichier = OuvrirEtat(Niveau)
  EndIf
  If Fichier
    Origine = TailleReference
  EndIf
  CopyMemory(*Reference, *D, TailleReference)
  CommencerPasse("Vérification", 4, Origine)
  DecoderCM4(*C, Z, T, *D, TailleReference, Fichier, 0)
  TerminerPasse(TailleReference + T - Origine)
  If Fichier
    FermerEtatLu(Fichier, Niveau)
  EndIf
  Ok = Bool(CompareMemory(*D + TailleReference, *Attendu, T))
  FreeMemory(*D)
  ProcedureReturn Ok
EndProcedure


; ----------------------------------------------------------------------------
;  Travail prévu pour une compression Maximal v4 (unités de la barre de
;  progression). La vérification se fait en même temps (Parallele) ou après ;
;  un état du modèle tout juste écrit est contrôlé avant d'être gardé.
; ----------------------------------------------------------------------------
Procedure.q TravailCompression(T.q, Niveau, Parallele)
  Protected.q Travail

  If EtatPrevu(Niveau)
    Travail = TravailAvant(Niveau) + TravailPasse4(T, Niveau, #True)
    If Parallele = #False
      Travail = Travail + TravailPasse4(T, Niveau, #True)
    EndIf
  Else
    Travail = TravailPasse4(T, Niveau, #False)
    If EtatUtile(Niveau)
      Travail = Travail + TravailPasse4(T, Niveau, #True)
    ElseIf Parallele = #False
      Travail = Travail + TravailMethode4(T, Niveau)
    EndIf
  EndIf
  ProcedureReturn Travail
EndProcedure


; Temps estimés sur ce PC (secondes): compression, et décompression ici
Procedure.q DureeCompression(T.q, Niveau)
  Protected Parallele
  Protected.q Secondes

  Parallele = ParalleleDisponible(#False)
  Secondes = TravailCompression(T, Niveau, Parallele) / VitesseCM
  If EtatPrevu(Niveau)
    Secondes = Secondes + #ChargementEtat
    If Parallele = #False
      Secondes = Secondes + #ChargementEtat
    EndIf
  ElseIf EtatUtile(Niveau)
    Secondes = Secondes + (2 * #ChargementEtat)      ; écriture du nouvel état, puis son contrôle
  EndIf
  ProcedureReturn Secondes
EndProcedure

Procedure.q DureeDecompression(T.q, Niveau)
  Protected.q Secondes

  If EtatPrevu(Niveau)
    ProcedureReturn ((TravailAvant(Niveau) + TravailPasse4(T, Niveau, #True)) / VitesseCM) + #ChargementEtat
  EndIf
  Secondes = TravailPasse4(T, Niveau, #False) / VitesseCM
  If EtatUtile(Niveau)
    Secondes = Secondes + (TravailPasse4(T, Niveau, #True) / VitesseCM) + (2 * #ChargementEtat)
  EndIf
  ProcedureReturn Secondes
EndProcedure

; Temps pour un lecteur qui n'a encore rien sur son PC (la première fois): il
; décompresse le fichier de référence (seulement son début au niveau Faible) ; au
; niveau Maximal, cette décompression prépare déjà l'état du modèle
Procedure.q DureeLecteur(T.q, Niveau)
  LireTableReference()
  If Niveau = #NiveauFaible
    ProcedureReturn ((SegmentTaille(0) * 4) + TravailMethode4(T, Niveau)) / VitesseCM
  ElseIf Niveau = #NiveauMaximal
    ProcedureReturn (((TailleNiveau(#NiveauMaximal) * 4) + (T * 4)) / VitesseCM) + (2 * #ChargementEtat)
  EndIf
  ProcedureReturn ((TailleNiveau(#NiveauMaximal) * 4) + TravailMethode4(T, Niveau)) / VitesseCM
EndProcedure


; ----------------------------------------------------------------------------
;  Écrit un nombre avec des espaces: 30000 -> "30 000"
; ----------------------------------------------------------------------------
Procedure.s FormaterNombre(Nombre)
  Protected Chiffres$, Sortie$, i, n

  Chiffres$ = Str(Nombre)
  n = Len(Chiffres$)
  For i = 1 To n
    Sortie$ = Sortie$ + Mid(Chiffres$, i, 1)
    If i < n And (n - i) % 3 = 0
      Sortie$ = Sortie$ + " "
    EndIf
  Next
  ProcedureReturn Sortie$
EndProcedure


; ----------------------------------------------------------------------------
;  Nombre de caractères que le forum (phpBB) comptera pour ce texte posté
;  entre les balise de code. phpBB compte APRÈS avoir:
;   - remplacé chaque retour à la ligne Windows (2 caractères) par 1 seul ;
;   - remplacé  "  &  <  >  par  &quot;  &amp;  &lt;  &gt;  (6, 5, 4, 4 car.)
; ----------------------------------------------------------------------------
Procedure TailleForum(Texte$)
  Protected Taille

  Taille = Len(Texte$) - CountString(Texte$, #CRLF$)
  Taille = Taille + 5 * CountString(Texte$, Chr(34))
  Taille = Taille + 4 * CountString(Texte$, "&")
  Taille = Taille + 3 * CountString(Texte$, "<")
  Taille = Taille + 3 * CountString(Texte$, ">")

  ProcedureReturn Taille + #TailleBalisesCode
EndProcedure


; ----------------------------------------------------------------------------
;  Lit un fichier .pb et renvoie son texte.
;  Gère l'UTF-8 avec marque (format normal de l'éditeur PureBasic),
;  l'UTF-8 sans marque, et l'ancien format ASCII.
; ----------------------------------------------------------------------------
Procedure.s LireFichier(NomFichier$)
  Protected Texte$, Taille, Fichier, *Brut, *Test, AvecMarque = #False

  Fichier = ReadFile(#PB_Any, NomFichier$)
  If Fichier
    Taille = Lof(Fichier)
    If Taille > 0
      *Brut = AllocateMemory(Taille)
      If *Brut
        ReadData(Fichier, *Brut, Taille)

        ; Marque UTF-8 (BOM) en début de fichier ?
        If Taille >= 3
          If PeekA(*Brut) = $EF And PeekA(*Brut + 1) = $BB And PeekA(*Brut + 2) = $BF
            AvecMarque = #True
          EndIf
        EndIf

        If AvecMarque
          ; La marque n'est pas du code: on la saute
          If Taille > 3
            Texte$ = PeekS(*Brut + 3, Taille - 3, #PB_UTF8 | #PB_ByteLength)
          EndIf
        Else
          ; Sans marque: on essaie l'UTF-8, et on vérifie que la relecture
          ; redonne exactement les mêmes octets. Sinon, c'est de l'ASCII.
          Texte$ = PeekS(*Brut, Taille, #PB_UTF8 | #PB_ByteLength)
          If StringByteLength(Texte$, #PB_UTF8) = Taille
            *Test = AllocateMemory(Taille + 1)
            If *Test
              PokeS(*Test, Texte$, -1, #PB_UTF8)
              If CompareMemory(*Brut, *Test, Taille) = 0
                Texte$ = PeekS(*Brut, Taille, #PB_Ascii)
              EndIf
              FreeMemory(*Test)
            EndIf
          Else
            Texte$ = PeekS(*Brut, Taille, #PB_Ascii)
          EndIf
        EndIf

        FreeMemory(*Brut)
      EndIf
    EndIf
    CloseFile(Fichier)
  EndIf

  ProcedureReturn Texte$
EndProcedure


; ----------------------------------------------------------------------------
;  Retire le bloc "; IDE Options = ..." que l'éditeur PureBasic ajoute à la
;  fin des fichiers (réglages de compilation, invisible dans l'éditeur).
;  Comme l'éditeur, on ne le retire que s'il est vraiment À LA FIN: après sa
;  première ligne, il ne doit y avoir que des commentaires (;) ou des lignes
;  vides. Sinon (par exemple plusieurs codes mis bout à bout), il fait partie
;  du code et rien n'est retiré. Jusqu'à la v6.4, tout ce qui suivait la
;  dernière ligne « ; IDE Options » était coupé, même du code.
; ----------------------------------------------------------------------------
Procedure.s RetirerOptionsIDE(Texte$)
  Protected Position = 0, Trouve = 0, Debut, Fin, k, Longueur
  Protected Reste$, Ligne$, Car$

  ; On cherche la DERNIÈRE occurrence
  Repeat
    Trouve = FindString(Texte$, "; IDE Options = ", Position + 1)
    If Trouve
      Position = Trouve
    EndIf
  Until Trouve = 0
  If Position = 0
    ProcedureReturn Texte$
  EndIf

  ; Elle doit être en début de ligne
  If Position > 1
    If Mid(Texte$, Position - 1, 1) <> #LF$ And Mid(Texte$, Position - 1, 1) <> #CR$
      ProcedureReturn Texte$
    EndIf
  EndIf

  ; Et ne doit être suivie que de commentaires ou de lignes vides (une ligne
  ; à la fois ; les fins de ligne CR seules comptent aussi)
  Reste$ = ReplaceString(Mid(Texte$, Position), #CR$, #LF$)
  Longueur = Len(Reste$)
  Debut = 1
  While Debut <= Longueur
    Fin = FindString(Reste$, #LF$, Debut)
    If Fin = 0
      Fin = Longueur + 1
    EndIf
    Ligne$ = Mid(Reste$, Debut, Fin - Debut)
    ; premier caractère qui n'est ni une espace ni une tabulation
    Car$ = ""
    For k = 1 To Len(Ligne$)
      If Mid(Ligne$, k, 1) <> " " And Mid(Ligne$, k, 1) <> #TAB$
        Car$ = Mid(Ligne$, k, 1)
        Break
      EndIf
    Next
    If Car$ <> "" And Car$ <> ";"
      ProcedureReturn Texte$             ; du code après: ce n'est pas le bloc de fin
    EndIf
    Debut = Fin + 1
  Wend

  ProcedureReturn Left(Texte$, Position - 1)
EndProcedure


; ----------------------------------------------------------------------------
;  Mode Unicode: octets -> texte, 15 bits par caractère
; ----------------------------------------------------------------------------
Procedure.s EncoderUnicode(*Donnees, Taille)
  Protected Sortie$, *Ecriture.Unicode, i, Accu, NbBits

  ; 8 bits par octet, 15 bits par caractère, arrondi au-dessus
  Sortie$ = Space((Taille * 8 + 14) / 15)
  *Ecriture = @Sortie$

  For i = 0 To Taille - 1
    Accu = (Accu << 8) | PeekA(*Donnees + i)
    NbBits = NbBits + 8
    If NbBits >= 15
      NbBits = NbBits - 15
      *Ecriture\u = CaractereUnicode((Accu >> NbBits) & $7FFF)
      *Ecriture = *Ecriture + 2
      Accu = Accu & ((1 << NbBits) - 1)
    EndIf
  Next

  ; Derniers bits, complétés par des zéros
  If NbBits > 0
    *Ecriture\u = CaractereUnicode((Accu << (15 - NbBits)) & $7FFF)
  EndIf

  ProcedureReturn Sortie$
EndProcedure


; ----------------------------------------------------------------------------
;  Octets compressés -> texte, selon l'encodage ("U" ou "B")
; ----------------------------------------------------------------------------
Procedure.s EncoderDonnees(*Donnees, Taille, Encodage$)
  If Encodage$ = "B"
    ProcedureReturn Base64Encoder(*Donnees, Taille)
  Else
    ProcedureReturn EncoderUnicode(*Donnees, Taille)
  EndIf
EndProcedure


; ----------------------------------------------------------------------------
;  Format auto-extractible: fabrique le programme à poster sur le forum
; ----------------------------------------------------------------------------
Procedure.s GenererLanceur(Donnees$, TailleOriginale.q, TailleCompressee.q, K.q, Methode$, Encodage$, Anglais)
  Protected Q$ = Chr(34), L$, Ligne$, Position, Longueur
  Protected Commentaire$, TitreOK$, MessageOK$, TitreErreur$, MessageErreur$

  If Anglais
    Commentaire$   = "; Compressed PureBasic code - run it (F5): the original code is copied to the clipboard"
    TitreOK$       = "Done"
    MessageOK$     = "The original code is in the clipboard. Paste it now, then click OK."
    TitreErreur$   = "Error"
    MessageErreur$ = "The data is damaged: copy the whole message again."
    If Encodage$ = "U"
      MessageErreur$ = MessageErreur$ + " The source file must be UTF-8."
    EndIf
  Else
    Commentaire$   = "; Code PureBasic compressé - lancez-le (F5): le code d'origine est copié dans le presse-papiers"
    TitreOK$       = "Terminé"
    MessageOK$     = "Le code d'origine est dans le presse-papiers. Collez-le maintenant, puis cliquez sur OK."
    TitreErreur$   = "Erreur"
    MessageErreur$ = "Les données sont abîmées: recopiez le message en entier."
    If Encodage$ = "U"
      MessageErreur$ = MessageErreur$ + " Le fichier source doit être en UTF-8."
    EndIf
  EndIf

  L$ = Commentaire$ + #CRLF$
  If Methode$ = "M"
    L$ = L$ + "DisableDebugger" + #CRLF$
    ; Toutes les variables du lanceur en entiers 64 bits, sur tous les PureBasic (32 et 64 bits)
    L$ = L$ + "Define.q T, Z, a, N, i, u, v, x, ip, k, x1, x2, wh, ls, pl, ml, mp, chk, pos, h, hm, ab, ma, c0, j, ws, dot, pb, e, pm, px, s, aw, ai, xm, y, er, g, c" + #CRLF$
  Else
    L$ = L$ + "UseLZMAPacker()" + #CRLF$
  EndIf
  L$ = L$ + "T = " + Str(TailleOriginale) + #CRLF$
  If Encodage$ = "U" Or Methode$ = "M"
    L$ = L$ + "Z = " + Str(TailleCompressee) + #CRLF$
  EndIf
  L$ = L$ + "Restore Donnees" + #CRLF$
  L$ = L$ + "Repeat" + #CRLF$
  L$ = L$ + "  Read.s L$" + #CRLF$
  L$ = L$ + "  B$ = B$ + L$" + #CRLF$
  L$ = L$ + "Until L$ = " + Q$ + Q$ + #CRLF$

  ; 1. Texte -> octets compressés
  If Encodage$ = "B"
    L$ = L$ + "*C = AllocateMemory(Len(B$) + 64)" + #CRLF$
    L$ = L$ + "*D = AllocateMemory(T + 16)" + #CRLF$
    If Methode$ = "M"
      L$ = L$ + "Base64Decoder(B$, *C, Len(B$) + 64)" + #CRLF$
    EndIf
  Else
    L$ = L$ + "*C = AllocateMemory(Len(B$) * 2 + 16)" + #CRLF$
    L$ = L$ + "*D = AllocateMemory(T + 16)" + #CRLF$
    L$ = L$ + "*P.Unicode = @B$" + #CRLF$
    L$ = L$ + "While *P\u" + #CRLF$
    L$ = L$ + "  a = (a << 15) | (*P\u - $3400 - Bool(*P\u >= $AC00) * $C00)" + #CRLF$
    L$ = L$ + "  k = k + 15" + #CRLF$
    L$ = L$ + "  While k >= 8" + #CRLF$
    L$ = L$ + "    k = k - 8" + #CRLF$
    L$ = L$ + "    PokeA(*C + N, (a >> k) & 255)" + #CRLF$
    L$ = L$ + "    N = N + 1" + #CRLF$
    L$ = L$ + "  Wend" + #CRLF$
    L$ = L$ + "  a = a & ((1 << k) - 1)" + #CRLF$
    L$ = L$ + "  *P = *P + 2" + #CRLF$
    L$ = L$ + "Wend" + #CRLF$
  EndIf

  ; 2. Décompression
  If Methode$ = "M"
    ; Le décompresseur Maximal: mêmes lignes que la procédure DecoderCM
    Restore LanceurCM
    Repeat
      Read.s Ligne$
      If Ligne$ <> ""
        L$ = L$ + Ligne$ + #CRLF$
      EndIf
    Until Ligne$ = ""
    L$ = L$ + "If chk = " + Str(K) + #CRLF$
  ElseIf Encodage$ = "B"
    L$ = L$ + "If UncompressMemory(*C, Base64Decoder(B$, *C, Len(B$) + 64), *D, T, #PB_PackerPlugin_Lzma) = T" + #CRLF$
  Else
    L$ = L$ + "If UncompressMemory(*C, Z, *D, T, #PB_PackerPlugin_Lzma) = T" + #CRLF$
  EndIf

  L$ = L$ + "  SetClipboardText(PeekS(*D, T, #PB_UTF8 | #PB_ByteLength))" + #CRLF$
  L$ = L$ + "  MessageRequester(" + Q$ + TitreOK$ + Q$ + ", " + Q$ + MessageOK$ + Q$ + ")" + #CRLF$
  L$ = L$ + "Else" + #CRLF$
  L$ = L$ + "  MessageRequester(" + Q$ + TitreErreur$ + Q$ + ", " + Q$ + MessageErreur$ + Q$ + ")" + #CRLF$
  L$ = L$ + "EndIf" + #CRLF$
  L$ = L$ + "DataSection" + #CRLF$
  L$ = L$ + "  Donnees:" + #CRLF$

  ; Les données, découpées en lignes
  Longueur = Len(Donnees$)
  Position = 1
  While Position <= Longueur
    L$ = L$ + "  Data.s " + Q$ + Mid(Donnees$, Position, #LongueurLigne) + Q$ + #CRLF$
    Position = Position + #LongueurLigne
  Wend

  ; Ligne vide = fin des données
  L$ = L$ + "  Data.s " + Q$ + Q$ + #CRLF$
  If Methode$ = "M"
    L$ = L$ + "  Sq33:" + #CRLF$
    L$ = L$ + "  Data.q " + #DonneesSq33$ + #CRLF$
  EndIf
  L$ = L$ + "EndDataSection" + #CRLF$

  ProcedureReturn L$
EndProcedure


; ----------------------------------------------------------------------------
;  Format données seules: bloc à coller dans l'onglet Décompresser
; ----------------------------------------------------------------------------
Procedure.s GenererBloc(Donnees$, TailleOriginale.q, TailleCompressee.q, K.q, Methode$, Encodage$, Anglais, Version$)
  Protected B$, Position, Longueur, Code

  ; Unicode: format compact, uniquement des caractères Unicode, sans rien d'autre
  If Encodage$ = "U"
    If Methode$ = "L"
      Code = 1
    Else
      Code = Val(Mid(Version$, 4))     ; PBC2 à PBC8
    EndIf
    B$ = Chr(CaractereUnicode(#MarqueCompacte)) + Chr(CaractereUnicode(Code))
    B$ = B$ + Chr(CaractereUnicode(TailleOriginale / 32768)) + Chr(CaractereUnicode(TailleOriginale % 32768))
    B$ = B$ + Chr(CaractereUnicode(TailleCompressee / 32768)) + Chr(CaractereUnicode(TailleCompressee % 32768))
    B$ = B$ + Chr(CaractereUnicode(K / 32768)) + Chr(CaractereUnicode(K % 32768))
    ProcedureReturn B$ + Donnees$
  EndIf

  ; Base64: format texte avec en-tête lisible

  If Anglais
    B$ = "; Compressed PureBasic code - unpack it with the PB Compressor (Décompresser tab)" + #CRLF$
  Else
    B$ = "; Code PureBasic compressé - décompressez-le avec le Compresseur PB (onglet Décompresser)" + #CRLF$
  EndIf
  B$ = B$ + Version$ + ";" + Methode$ + ";" + Encodage$ + ";" + Str(TailleOriginale) + ";" + Str(TailleCompressee) + ";" + Str(K) + ";" + #CRLF$

  Longueur = Len(Donnees$)
  Position = 1
  While Position <= Longueur
    B$ = B$ + Mid(Donnees$, Position, #LongueurLigne) + #CRLF$
    Position = Position + #LongueurLigne
  Wend

  B$ = B$ + ";FIN" + #CRLF$
  ProcedureReturn B$
EndProcedure


; ----------------------------------------------------------------------------
;  Vérification d'un lanceur: rejoue ce que fera le lanceur chez le lecteur,
;  en relisant les lignes "Data.s" directement dans le texte généré.
;  Renvoie #True si on retrouve exactement le code d'origine.
; ----------------------------------------------------------------------------
Procedure VerifierLanceur(Lanceur$, TexteAttendu$, TailleOriginale.q, TailleCompressee.q, K.q, Methode$, Encodage$)
  Protected NbLignes, i, Ligne$, Donnees$, Debut$, LongueurDebut
  Protected *Compresse, *Decompresse, TailleTampon, TailleDecodee
  Protected Ok = #False

  Debut$ = "Data.s " + Chr(34)
  LongueurDebut = Len(Debut$)

  ; 1. On récupère les données dans les lignes "Data.s"
  NbLignes = CountString(Lanceur$, #LF$) + 1
  For i = 1 To NbLignes
    Ligne$ = Trim(RemoveString(StringField(Lanceur$, i, #LF$), #CR$))
    If Left(Ligne$, LongueurDebut) = Debut$ And Len(Ligne$) > LongueurDebut And Right(Ligne$, 1) = Chr(34)
      Donnees$ = Donnees$ + Mid(Ligne$, LongueurDebut + 1, Len(Ligne$) - LongueurDebut - 1)
    EndIf
  Next

  ; 2. Décodage puis décompression, comme le fera le lanceur
  If Donnees$ <> ""
    TailleTampon = Len(Donnees$) * 2 + 64
    *Compresse = AllocateMemory(TailleTampon)
    *Decompresse = AllocateMemory(TailleOriginale + 16)
    If *Compresse And *Decompresse

      If Encodage$ = "B"
        TailleDecodee = Base64Decoder(Donnees$, *Compresse, TailleTampon)
      Else
        ; Le lanceur décompresse Z = TailleCompressee octets: on fait pareil
        If DecoderUnicode(Donnees$, *Compresse, TailleTampon) >= TailleCompressee
          TailleDecodee = TailleCompressee
        EndIf
      EndIf

      If TailleDecodee >= TailleCompressee And TailleCompressee > 0
        If Methode$ = "M"
          If DecoderCM(*Compresse, TailleCompressee, TailleOriginale, *Decompresse) = K
            Ok = Bool(PeekS(*Decompresse, TailleOriginale, #PB_UTF8 | #PB_ByteLength) = TexteAttendu$)
          EndIf
        Else
          If UncompressMemory(*Compresse, TailleDecodee, *Decompresse, TailleOriginale, #PB_PackerPlugin_Lzma) = TailleOriginale
            Ok = Bool(PeekS(*Decompresse, TailleOriginale, #PB_UTF8 | #PB_ByteLength) = TexteAttendu$)
          EndIf
        EndIf
      EndIf

    EndIf
    If *Compresse
      FreeMemory(*Compresse)
    EndIf
    If *Decompresse
      FreeMemory(*Decompresse)
    EndIf
  EndIf

  ProcedureReturn Ok
EndProcedure


; ----------------------------------------------------------------------------
;  Vérifie une sortie, quel que soit son format
; ----------------------------------------------------------------------------
Procedure VerifierSortie(Sortie$, Format, TexteAttendu$, TailleOriginale.q, TailleCompressee.q, K.q, Methode$, Encodage$)
  If Format = #FormatBloc
    ; Exactement ce que fera l'onglet Décompresser chez le lecteur
    ProcedureReturn Bool(DecompresserBloc(Sortie$) = TexteAttendu$)
  Else
    ProcedureReturn VerifierLanceur(Sortie$, TexteAttendu$, TailleOriginale, TailleCompressee, K, Methode$, Encodage$)
  EndIf
EndProcedure


; ----------------------------------------------------------------------------
;  Bandeau vert / rouge: le résultat tient-il dans la limite du forum ?
; ----------------------------------------------------------------------------
Procedure MettreAJourIndicateur()
  Protected Limite, Message$

  Limite = Val(GetGadgetText(#ChampLimite))

  ; Pas encore de résultat: bandeau caché
  If DerniereTailleForum = 0
    HideGadget(#Indicateur, #True)
    ProcedureReturn
  EndIf
  HideGadget(#Indicateur, #False)

  If Limite <= 0
    SetGadgetText(#Indicateur, "  Indique la limite du forum pour savoir si le message passe.")
    SetGadgetColor(#Indicateur, #PB_Gadget_FrontColor, RGB(60, 60, 60))
    SetGadgetColor(#Indicateur, #PB_Gadget_BackColor, RGB(230, 230, 230))

  ElseIf DerniereTailleForum <= Limite
    Message$ = "  ÇA PASSE: " + FormaterNombre(DerniereTailleForum) + " caractères comptés par le forum, sur " + FormaterNombre(Limite) + " autorisés (marge: " + FormaterNombre(Limite - DerniereTailleForum) + ")."
    SetGadgetText(#Indicateur, Message$)
    SetGadgetColor(#Indicateur, #PB_Gadget_FrontColor, RGB(0, 90, 0))
    SetGadgetColor(#Indicateur, #PB_Gadget_BackColor, RGB(200, 240, 200))

  Else
    Message$ = "  TROP LONG: " + FormaterNombre(DerniereTailleForum) + " caractères comptés par le forum, il y en a " + FormaterNombre(DerniereTailleForum - Limite) + " de trop."
    If DernierModeBase64
      Message$ = Message$ + " Essaie l'encodage Unicode, environ 2,5 fois plus court."
    ElseIf DernierFormat = #FormatLanceur
      Message$ = Message$ + " Le format « Données seules » est plus court."
    EndIf
    SetGadgetText(#Indicateur, Message$)
    SetGadgetColor(#Indicateur, #PB_Gadget_FrontColor, RGB(150, 0, 0))
    SetGadgetColor(#Indicateur, #PB_Gadget_BackColor, RGB(250, 205, 205))
  EndIf
EndProcedure


; ----------------------------------------------------------------------------
;  Affiche un texte dans une zone de texte. Un texte énorme écrit sur très peu
;  de lignes (par exemple un bloc compressé de plusieurs centaines de milliers
;  de caractères) bloquerait Windows pendant de longues minutes: on n'en
;  montre alors que le début, suivi de Message$.
; ----------------------------------------------------------------------------
#AffichageMax = 100000

Procedure AfficherTexte(Gadget, Texte$, Message$)
  Protected Longueur

  Longueur = Len(Texte$)
  If Longueur > #AffichageMax And CountString(Texte$, #LF$) < Longueur / 2000
    SetGadgetText(Gadget, Left(Texte$, 3000) + #CRLF$ + #CRLF$ + "[...] Texte de " + FormaterNombre(Longueur) + " caractères, trop long pour être affiché en entier ici " + Message$)
  Else
    SetGadgetText(Gadget, Texte$)
  EndIf
EndProcedure


; ----------------------------------------------------------------------------
;  Charge un code dans le logiciel
; ----------------------------------------------------------------------------
Procedure ChargerCode(Texte$, Origine$)
  Protected Infos$, Limite, TailleSurForum

  CodeOriginal$ = Texte$
  EstimationAJour = #False
  AfficherTexte(#EditeurEntree, Texte$, "(il est bien chargé en entier et sera compressé en entier).")
  SetGadgetText(#EditeurSortie, "")

  TailleSurForum = TailleForum(Texte$)
  Infos$ = "Code chargé depuis " + Origine$ + ": " + FormaterNombre(Len(Texte$)) + " caractères (le forum en compterait " + FormaterNombre(TailleSurForum) + ")."
  Limite = Val(GetGadgetText(#ChampLimite))
  If Limite > 0 And TailleSurForum <= Limite
    Infos$ = Infos$ + " Il passe déjà sans compression."
  EndIf
  SetGadgetText(#TexteInfos, Infos$)

  DerniereTailleForum = 0
  MettreAJourIndicateur()
EndProcedure


Procedure CollerDepuisPressePapiers()
  Protected Texte$ = GetClipboardText()

  If Texte$ = ""
    MessageRequester("Compresseur", "Le presse-papiers ne contient pas de texte." + #LF$ + "Dans PureBasic: Ctrl+A puis Ctrl+C sur ton code.", #PB_MessageRequester_Warning)
  Else
    ChargerCode(Texte$, "le presse-papiers")
  EndIf
EndProcedure


Procedure OuvrirFichier()
  Protected NomFichier$, Texte$

  NomFichier$ = OpenFileRequester("Ouvrir un code PureBasic", "", "Code PureBasic (*.pb;*.pbi)|*.pb;*.pbi|Tous les fichiers (*.*)|*.*", 0)
  If NomFichier$ <> ""
    Texte$ = LireFichier(NomFichier$)
    If Texte$ = ""
      MessageRequester("Compresseur", "Le fichier est vide ou impossible à lire:" + #LF$ + NomFichier$, #PB_MessageRequester_Warning)
    Else
      ChargerCode(Texte$, "« " + GetFilePart(NomFichier$) + " »")
    EndIf
  EndIf
EndProcedure


; ----------------------------------------------------------------------------
;  Ce qui s'est passé avec le fichier de référence pendant l'opération (texte à
;  ajouter au compte rendu, "" si rien)
; ----------------------------------------------------------------------------
Procedure.s CompteRenduReference()
  If EtatMaximalRefuse
    ProcedureReturn #LF$ + "Attention: l'état du niveau Maximal préparé en décompressant le fichier de référence a été refusé (somme de contrôle différente de celle attendue). Rien de faux n'a été produit (le modèle a relu le texte de référence), mais signale-le."
  ElseIf EtatMaximalPrepare
    ProcedureReturn #LF$ + "Le fichier de référence a été décompressé (une seule fois sur ce PC): le texte de référence et l'état du niveau Maximal sont gardés sur le disque."
  ElseIf ReferenceDecompressee = 2
    ProcedureReturn #LF$ + "Le fichier de référence a été décompressé (une seule fois sur ce PC): le texte de référence est gardé sur le disque."
  EndIf
  ProcedureReturn ""
EndProcedure


; ----------------------------------------------------------------------------
;  Onglet Décompresser
; ----------------------------------------------------------------------------

Procedure DecompresserTexte(Texte$)
  Protected Resultat$, Infos$

  SetGadgetText(#TexteInfosDec, "Décompression en cours... (l'avancement et le temps restant s'affichent tout en bas)")
  ViderEvenements()
  EtatCree = #False
  EtatRelu = #False
  EtatMaximalPrepare = #False
  EtatMaximalRefuse = #False
  ReferenceDecompressee = 0

  Resultat$ = DecompresserBloc(Texte$)
  If Resultat$ = ""
    SetGadgetText(#TexteInfosDec, ErreurDecompression$)
    If BlocReconnu
      ; Un bloc est là, mais il n'a pas pu être lu: c'est une vraie erreur
      MessageRequester("Décompresser", ErreurDecompression$, #PB_MessageRequester_Error)
    Else
      ; Rien qui ressemble à un bloc: simple information
      MessageRequester("Décompresser", ErreurDecompression$, #PB_MessageRequester_Info)
    EndIf
  Else
    CodeDecompresse$ = Resultat$
    AfficherTexte(#EditeurDec, Resultat$, "(utilise « Copier le code » ou « Enregistrer en .pb » pour l'avoir en entier).")
    Infos$ = "Code décompressé et vérifié: " + FormaterNombre(Len(Resultat$)) + " caractères. " + CompteRenduProtection() + "Tu peux le copier ou l'enregistrer."
    If EtatCree
      Infos$ = Infos$ + #LF$ + "L'état du modèle a été écrit sur le disque (environ 670 Mo, réglage dans l'onglet Compresser): la prochaine fois à ce niveau, quelques secondes suffiront."
    ElseIf EtatRelu And EtatMaximalPrepare = #False
      Infos$ = Infos$ + #LF$ + "L'état du modèle a été relu depuis le disque (au lieu de relire tout le texte de référence)."
    EndIf
    SetGadgetText(#TexteInfosDec, Infos$ + CompteRenduReference())
  EndIf
EndProcedure


Procedure CollerEtDecompresser()
  Protected Texte$ = GetClipboardText()

  If Texte$ = ""
    MessageRequester("Décompresser", "Le presse-papiers ne contient pas de texte." + #LF$ + "Copie d'abord le bloc compressé sur le forum.", #PB_MessageRequester_Warning)
  Else
    DecompresserTexte(Texte$)
  EndIf
EndProcedure


Procedure CopierCodeDecompresse()
  If CodeDecompresse$ = ""
    MessageRequester("Décompresser", "Rien à copier: décompresse d'abord un bloc.", #PB_MessageRequester_Warning)
  Else
    SetClipboardText(CodeDecompresse$)
    SetGadgetText(#TexteInfosDec, "Code copié dans le presse-papiers: colle-le dans PureBasic.")
  EndIf
EndProcedure


Procedure EnregistrerCodeDecompresse()
  Protected NomFichier$, Fichier

  If CodeDecompresse$ = ""
    MessageRequester("Décompresser", "Rien à enregistrer: décompresse d'abord un bloc.", #PB_MessageRequester_Warning)
    ProcedureReturn
  EndIf

  NomFichier$ = SaveFileRequester("Enregistrer le code", "Code.pb", "Code PureBasic (*.pb)|*.pb|Tous les fichiers (*.*)|*.*", 0)
  If NomFichier$ <> ""
    If GetExtensionPart(NomFichier$) = ""
      NomFichier$ = NomFichier$ + ".pb"
    EndIf
    Fichier = CreateFile(#PB_Any, NomFichier$)
    If Fichier
      ; UTF-8 avec marque: le format normal de l'éditeur PureBasic
      WriteStringFormat(Fichier, #PB_UTF8)
      WriteString(Fichier, CodeDecompresse$, #PB_UTF8)
      CloseFile(Fichier)
      SetGadgetText(#TexteInfosDec, "Code enregistré: " + NomFichier$)
    Else
      MessageRequester("Décompresser", "Impossible de créer le fichier:" + #LF$ + NomFichier$, #PB_MessageRequester_Error)
    EndIf
  EndIf
EndProcedure


; ----------------------------------------------------------------------------
;  Niveau de protection choisi dans la liste (0 = aucune, sinon 1, 2, 4, 8, 16)
; ----------------------------------------------------------------------------
Procedure NiveauProtectionChoisi()
  Select GetGadgetState(#ChoixProtection)
    Case 1
      ProcedureReturn 1
    Case 2
      ProcedureReturn 2
    Case 3
      ProcedureReturn 4
    Case 4
      ProcedureReturn 8
    Case 5
      ProcedureReturn 16
  EndSelect
  ProcedureReturn 0
EndProcedure


; ----------------------------------------------------------------------------
;  Niveau de compression: temps et taille estimés
; ----------------------------------------------------------------------------
Procedure.s DureeApprox(Secondes.q)
  If Secondes < 10
    ProcedureReturn "< 10 s"
  ElseIf Secondes < 60
    ProcedureReturn "≈ " + Str(((Secondes + 4) / 5) * 5) + " s"
  EndIf
  ProcedureReturn "≈ " + ReplaceString(StrF(Secondes / 60.0, 1), ".", ",") + " min"
EndProcedure


; Surcoût de la protection contre les erreurs, pour mille
Procedure SurcoutProtection()
  Select NiveauProtectionChoisi()
    Case 1
      ProcedureReturn 1035
    Case 2
      ProcedureReturn 1050
    Case 4
      ProcedureReturn 1090
    Case 8
      ProcedureReturn 1160
    Case 16
      ProcedureReturn 1300
  EndSelect
  ProcedureReturn 1000
EndProcedure


; Rapports Maximal / LZMA (pour mille) mesurés sur des codes qui ne sont pas
; dans la référence: bas = code de Shadow, haut = code d'autres auteurs
Procedure RapportBas(Niveau)
  Select Niveau
    Case #NiveauFaible
      ProcedureReturn 557
    Case #NiveauMoyen
      ProcedureReturn 392
  EndSelect
  ProcedureReturn 389
EndProcedure


Procedure RapportHaut(Niveau)
  Select Niveau
    Case #NiveauFaible
      ProcedureReturn 607
    Case #NiveauMoyen
      ProcedureReturn 593
    Case #NiveauNormal
      ProcedureReturn 568
    Case #NiveauEleve
      ProcedureReturn 529
  EndSelect
  ProcedureReturn 521
EndProcedure


; Caractères comptés par le forum pour Z octets compressés
Procedure CaracteresForum(Z.q)
  Protected.q Caracteres

  If GetGadgetState(#ChoixEncodage) = #EncodageBase64
    ; Base64: 4 caractères pour 3 octets, plus l'en-tête lisible
    ProcedureReturn (((Z + 2) / 3) * 4) + 150 + #TailleBalisesCode
  EndIf
  ; Unicode, format compact: 15 bits par caractère, 8 caractères d'en-tête
  Caracteres = (((Z * 8) + 14) / 15) + 8
  ProcedureReturn ((Caracteres * SurcoutProtection()) / 1000) + #TailleBalisesCode
EndProcedure


; La protection ne sert qu'en données seules + Unicode
Procedure MettreAJourCaseProtection()
  If GetGadgetState(#ChoixFormat) = #FormatBloc And GetGadgetState(#ChoixEncodage) = #EncodageUnicode
    DisableGadget(#ChoixProtection, #False)
    SetGadgetText(#TexteProtectionInfo, "Le bloc se répare tout seul s'il est un peu abîmé.")
  Else
    DisableGadget(#ChoixProtection, #True)
    SetGadgetText(#TexteProtectionInfo, "(seulement en « Données seules » + Unicode)")
  EndIf
EndProcedure


; Met à jour la liste des niveaux (temps estimés) et l'estimation de taille
Procedure MettreAJourNiveaux()
  Protected Texte$, Info$, *Source, *Z, i, Niveau, Actif, Bas, Haut
  Protected.q Compression, Decompression, Place

  ; 1. Taille du code et taille avec LZMA (refaites seulement si le code a changé)
  If EstimationAJour = #False
    EstimationTaille = 0
    EstimationLZMA = 0
    Texte$ = CodeOriginal$
    If GetGadgetState(#CaseOptionsIDE) = #PB_Checkbox_Unchecked
      Texte$ = RetirerOptionsIDE(Texte$)
    EndIf
    If Texte$ <> ""
      EstimationTaille = StringByteLength(Texte$, #PB_UTF8)
      Place = EstimationTaille + (EstimationTaille / 4) + 1024
      *Source = AllocateMemory(EstimationTaille + 1)
      *Z = AllocateMemory(Place)
      If *Source And *Z
        PokeS(*Source, Texte$, -1, #PB_UTF8)
        EstimationLZMA = CompressMemory(*Source, EstimationTaille, *Z, Place, #PB_PackerPlugin_Lzma, 9)
      EndIf
      If *Source
        FreeMemory(*Source)
      EndIf
      If *Z
        FreeMemory(*Z)
      EndIf
    EndIf
    EstimationAJour = #True
  EndIf

  ; 2. Temps estimés de chaque niveau sur ce PC, d'après la vitesse mesurée et
  ;    l'état du modèle gardé sur le disque (la sélection est remise après, au
  ;    cas où changer un texte l'efface)
  Niveau = NiveauValide(GetGadgetState(#ChoixNiveau))
  For i = #NiveauFaible To #NiveauMaximal
    Compression = DureeCompression(EstimationTaille, i)
    Decompression = DureeDecompression(EstimationTaille, i)
    Texte$ = NomNiveau(i) + ": compression " + DureeApprox(Compression) + ", décompression " + DureeApprox(Decompression)
    If EtatDisponible(i)
      Texte$ = Texte$ + " (état gardé)"
    EndIf
    SetGadgetItemText(#ChoixNiveau, i, Texte$)
  Next
  SetGadgetState(#ChoixNiveau, Niveau)

  ; 3. Le niveau ne sert qu'aux données seules avec la méthode Maximal
  Actif = Bool(GetGadgetState(#ChoixFormat) = #FormatBloc And GetGadgetState(#ChoixMethode) <> #MethodeLZMA)
  DisableGadget(#ChoixNiveau, Bool(Actif = #False))
  If Actif = #False
    SetGadgetText(#TexteNiveauInfo, "(seulement en « Données seules », méthode Maximal ou Automatique)")
    ProcedureReturn
  EndIf

  ; 4. Taille estimée au niveau choisi. Le lecteur, lui, n'a encore rien sur
  ;    son PC: la première fois, il décompresse le fichier de référence.
  Decompression = DureeLecteur(EstimationTaille, Niveau)
  If EstimationLZMA <= 0
    Info$ = "Charge un code pour voir la taille estimée."
  ElseIf RapportNiveau(Niveau) > 0
    Info$ = "≈ " + FormaterNombre(CaracteresForum((EstimationLZMA * RapportNiveau(Niveau)) / 1000)) + " caractères (d'après tes compressions à ce niveau)."
  Else
    Bas = CaracteresForum((EstimationLZMA * RapportBas(Niveau)) / 1000)
    Haut = CaracteresForum((EstimationLZMA * RapportHaut(Niveau)) / 1000)
    Info$ = "≈ " + FormaterNombre(Bas) + " à " + FormaterNombre(Haut) + " caractères (bas: ton code, haut: autres auteurs)."
  EndIf
  If Niveau >= #NiveauMoyen
    Info$ = Info$ + " Lecteur: " + DureeApprox(Decompression) + " la 1re fois (puis < 10 s), 700 Mo de mémoire."
  Else
    Info$ = Info$ + " Lecteur: " + DureeApprox(Decompression) + ", 700 Mo de mémoire."
  EndIf
  SetGadgetText(#TexteNiveauInfo, Info$)
EndProcedure


; ----------------------------------------------------------------------------
;  États du modèle gardés sur le disque: place utilisée, et bouton Effacer
; ----------------------------------------------------------------------------
Procedure.q PlaceEtats()
  Protected i
  Protected.q Total, Taille

  For i = #NiveauMoyen To #NiveauMaximal
    Taille = FileSize(FichierEtat(i))
    If Taille > 0
      Total = Total + Taille
    EndIf
    Taille = FileSize(FichierEtat(i) + ".tmp")
    If Taille > 0
      Total = Total + Taille
    EndIf
  Next
  Taille = FileSize(FichierTexteReference())          ; texte de référence décompressé
  If Taille > 0
    Total = Total + Taille
  EndIf
  ProcedureReturn Total
EndProcedure


Procedure.s FormaterOctets(Taille.q)
  If Taille >= 1024 * 1024 * 1024
    ProcedureReturn ReplaceString(StrF(Taille / (1024.0 * 1024.0 * 1024.0), 1), ".", ",") + " Go"
  EndIf
  ProcedureReturn Str((Taille + (512 * 1024)) / (1024 * 1024)) + " Mo"
EndProcedure


Procedure MettreAJourEtatDisque()
  Protected.q Place

  Place = PlaceEtats()
  If Place > 0
    SetGadgetText(#BoutonEffacerEtat, "Effacer (" + FormaterOctets(Place) + ")")
    DisableGadget(#BoutonEffacerEtat, #False)
  Else
    SetGadgetText(#BoutonEffacerEtat, "Effacer")
    DisableGadget(#BoutonEffacerEtat, #True)
  EndIf
EndProcedure


Procedure EffacerEtats()
  Protected i

  ; Depuis la v6.4, le texte de référence décompressé est effacé aussi: il
  ; faudra redécompresser le fichier de référence (quelques minutes)
  If MessageRequester("Effacer", "Effacer ce qui est gardé sur le disque (" + FormaterOctets(PlaceEtats()) + "): les états du modèle et le texte de référence décompressé ?" + #LF$ + "Ils seront refaits la prochaine fois (quelques minutes pour décompresser le fichier de référence, puis pour chaque niveau).", #PB_MessageRequester_YesNo | #PB_MessageRequester_Warning) <> #PB_MessageRequester_Yes
    ProcedureReturn
  EndIf
  For i = #NiveauMoyen To #NiveauMaximal
    DeleteFile(FichierEtat(i))
    DeleteFile(FichierEtat(i) + ".tmp")
  Next
  DeleteFile(FichierTexteReference())
  DeleteFile(FichierTexteReference() + ".tmp")
  MettreAJourEtatDisque()
  MettreAJourNiveaux()
EndProcedure


; ----------------------------------------------------------------------------
;  Fin d'une opération (compression ou décompression): les clics faits pendant
;  le calcul sont ignorés, puis les boutons et réglages sont réactivés et remis
;  dans le bon état.
; ----------------------------------------------------------------------------
Procedure FinOperation()
  ViderEvenements()
  ActiverBoutons(#True)
  MettreAJourCaseProtection()
  MettreAJourNiveaux()
  MettreAJourIndicateur()
  MettreAJourEtatDisque()
EndProcedure


; ----------------------------------------------------------------------------
;  Teste la réparation d'un bloc protégé sur 3 copies abîmées exprès:
;  un caractère retiré au milieu, un caractère remplacé au début, la fin
;  coupée de 20 caractères. Chacune doit redonner exactement Brut$.
; ----------------------------------------------------------------------------
Procedure TesterProtection(Bloc$, Brut$)
  Protected Abime$, Milieu, Ok

  Ok = #True
  Milieu = Len(Bloc$) / 2
  Abime$ = Left(Bloc$, Milieu) + Mid(Bloc$, Milieu + 2)
  If ReparerBloc(Abime$) <> Brut$ Or InfZones = 0
    Ok = #False
  EndIf
  Abime$ = Left(Bloc$, 19) + Chr(CaractereUnicode((ValeurUnicode(Asc(Mid(Bloc$, 20, 1))) + 1) % 32768)) + Mid(Bloc$, 21)
  If ReparerBloc(Abime$) <> Brut$ Or InfZones = 0
    Ok = #False
  EndIf
  Abime$ = Left(Bloc$, Len(Bloc$) - 20)
  If ReparerBloc(Abime$) <> Brut$ Or InfZones = 0
    Ok = #False
  EndIf
  ProcedureReturn Ok
EndProcedure


; ----------------------------------------------------------------------------
;  Compression complète
; ----------------------------------------------------------------------------
Procedure Compresser()
  Protected Texte$, Format, Methode, Anglais, Encodage$, Pourcentage$, Infos$, Niveau
  Protected.q Taille, K, ZL, ZM
  Protected *Source, *ZL, *ZM, *Avec
  Protected SortieL$, SortieM$, Sortie$, Retenue$, TailleL, TailleM, TailleForumOriginal, TailleForumSortie
  Protected OkL, OkM, NiveauProtection, OkProtection, BrutL$, BrutM$, Brut$, NomMaximal$
  Protected Parallele, VerifOk, EtatEcrit, FichierVerif, Resultat, Etape$, Raison$
  Protected.q Origine
  Protected *Verif

  Texte$ = CodeOriginal$
  If GetGadgetState(#CaseOptionsIDE) = #PB_Checkbox_Unchecked
    Texte$ = RetirerOptionsIDE(Texte$)
  EndIf

  If Texte$ = ""
    MessageRequester("Compresseur", "Aucun code à compresser." + #LF$ + "Colle d'abord ton code ou ouvre un fichier .pb.", #PB_MessageRequester_Warning)
    ProcedureReturn
  EndIf

  Format  = GetGadgetState(#ChoixFormat)
  Niveau  = NiveauValide(GetGadgetState(#ChoixNiveau))
  Methode = GetGadgetState(#ChoixMethode)
  Anglais = GetGadgetState(#ChoixLangue)
  If GetGadgetState(#ChoixEncodage) = #EncodageBase64
    Encodage$ = "B"
  Else
    Encodage$ = "U"
  EndIf

  ; Protection contre les erreurs: seulement en données seules + Unicode
  If Format = #FormatBloc And Encodage$ = "U"
    NiveauProtection = NiveauProtectionChoisi()
  EndIf

  If Format = #FormatBloc And Methode <> #MethodeLZMA
    ; Ce qui va se passer, dit avant de commencer: d'où vient le modèle, et
    ; comment se fait la vérification
    Parallele = ParalleleDisponible(#True)
    If Parallele = #False
      Raison$ = RaisonSansParallele()        ; gardée pour le résumé final
    EndIf
    If EtatDisponible(Niveau)
      Infos$ = "état du modèle relu depuis le disque"
    ElseIf EtatPrevu(Niveau)
      Infos$ = "fichier de référence décompressé (une seule fois sur ce PC): le modèle a alors lu tout le texte de référence, et son état est gardé sur le disque"
    Else
      If TravailReference(Niveau) > 0
        Infos$ = "fichier de référence décompressé (une seule fois sur ce PC), puis "
      EndIf
      If EtatUtile(Niveau)
        Infos$ = Infos$ + "texte de référence lu par le modèle, et état du modèle écrit sur le disque (première fois à ce niveau)"
      Else
        Infos$ = Infos$ + "texte de référence lu par le modèle"
      EndIf
    EndIf
    If Parallele
      Infos$ = Infos$ + ", vérification en même temps (second thread)"
    Else
      Infos$ = Infos$ + ", puis vérification (" + Raison$ + ")"
    EndIf
    SetGadgetText(#TexteInfos, "Compression en cours (niveau " + NomNiveau(Niveau) + "): " + Infos$ + ". L'avancement s'affiche tout en bas.")
    Infos$ = ""
  Else
    SetGadgetText(#TexteInfos, "Compression en cours...")
  EndIf
  ViderEvenements()

  ; Boutons et réglages grisés pendant toute l'opération (voir FinOperation)
  ActiverBoutons(#False)
  EtatCree = #False
  EtatRelu = #False
  EtatMaximalPrepare = #False
  EtatMaximalRefuse = #False
  ReferenceDecompressee = 0

  ; 1. Texte -> octets UTF-8
  Taille = StringByteLength(Texte$, #PB_UTF8)
  *Source = AllocateMemory(Taille + 1)
  If *Source = 0
    FinOperation()
    MessageRequester("Erreur", "Mémoire insuffisante.", #PB_MessageRequester_Error)
    ProcedureReturn
  EndIf
  PokeS(*Source, Texte$, -1, #PB_UTF8)
  K = Controle(*Source, Taille)

  ; Barre de progression: la méthode Maximal v4 lit le texte de référence (ou
  ; relit l'état du modèle gardé sur le disque), compresse et vérifie (en même
  ; temps si un second thread est possible). Voir TravailCompression.
  If Format = #FormatBloc And Methode <> #MethodeLZMA
    DebutProgression(TravailCompression(Taille, Niveau, Parallele))
  EndIf

  ; 2. Méthode LZMA
  If Methode = #MethodeAuto Or Methode = #MethodeLZMA
    *ZL = AllocateMemory(Taille + Taille / 4 + 1024)
    If *ZL
      ZL = CompressMemory(*Source, Taille, *ZL, Taille + Taille / 4 + 1024, #PB_PackerPlugin_Lzma, 9)
      If ZL > 0
        If Format = #FormatBloc
          SortieL$ = GenererBloc(EncoderDonnees(*ZL, ZL, Encodage$), Taille, ZL, K, "L", Encodage$, Anglais, "PBC1")
          If NiveauProtection > 0
            BrutL$ = SortieL$
            SortieL$ = ProtegerBloc(SortieL$, NiveauProtection)
          EndIf
        Else
          SortieL$ = GenererLanceur(EncoderDonnees(*ZL, ZL, Encodage$), Taille, ZL, K, "L", Encodage$, Anglais)
        EndIf
        TailleL = TailleForum(SortieL$)
      EndIf
      FreeMemory(*ZL)
    EndIf
  EndIf

  ; 3. Méthode Maximal
  If Methode = #MethodeAuto Or Methode = #MethodeMaximal
    *ZM = AllocateMemory(Taille + Taille / 2 + 1024)
    If *ZM
      If Format = #FormatBloc
        ; Version 4 (PBC4 à PBC8 selon le niveau): le texte de référence du
        ; niveau choisi est placé devant le code. Le modèle le relit en entier,
        ; ou bien relit l'état gardé sur le disque (voir PreparerNiveau).
        If MemoireMethode4() = #False
          MessageRequester("Erreur", "Mémoire insuffisante: la méthode Maximal v4 a besoin d'environ 700 Mo de mémoire libre." + #LF$ + "Elle est désactivée pour cette fois. Ferme d'autres programmes et réessaie.", #PB_MessageRequester_Error)
        ElseIf PreparerNiveau(Niveau) = #False
          MessageRequester("Erreur", ErreurReference$ + #LF$ + "La méthode Maximal est désactivée pour cette fois.", #PB_MessageRequester_Error)
        Else
          *Avec = AllocateMemory(TailleReference + Taille + 16)
          If *Avec
            CopyMemory(*Reference, *Avec, TailleReference)
            CopyMemory(*Source, *Avec + TailleReference, Taille)
            Origine = 0
            If FichierEtatLu
              Origine = TailleReference
            EndIf
            Etape$ = "Compression (niveau " + NomNiveau(Niveau) + ")"
            ZM = -1

            ; a) Compression, avec la vérification en même temps si possible
            CompilerIf #PB_Compiler_Thread
              If Parallele
                *Verif = AllocateMemory(TailleReference + Taille + 16)
                If *Verif
                  If FichierEtatLu
                    FichierVerif = OuvrirEtat(Niveau)
                  EndIf
                  ZM = CompresserEnParallele(*Avec, Taille, *ZM, *Verif, FichierVerif, K, Etape$ + " et vérification", Origine)
                  If FichierVerif
                    CloseFile(FichierVerif)
                  EndIf
                  FreeMemory(*Verif)
                  VerifOk = VerifParalleleOk
                EndIf
              EndIf
            CompilerEndIf
            If ZM < 0
              Parallele = #False
              CommencerPasse(Etape$, 4, Origine)
              ZM = EncoderCM4(*Avec, Taille, *ZM, TailleReference, FichierEtatLu, FichierEtatEcrit)
              TerminerPasse(TailleReference + Taille - Origine)
            EndIf
            FreeMemory(*Avec)

            ; b) Fichiers d'état: celui qui a été relu est fermé (et effacé s'il
            ;    s'est révélé abîmé) ; celui qui a été écrit reste provisoire
            If FichierEtatLu
              EtatRelu = FermerEtatLu(FichierEtatLu, Niveau)
              FichierEtatLu = 0
            EndIf
            EtatEcrit = #False
            If FichierEtatEcrit
              EtatEcrit = FermerEtatEcrit(FichierEtatEcrit, Niveau)
              FichierEtatEcrit = 0
            EndIf

            ; c) Vérification par une décompression complète, si elle n'a pas été
            ;    faite en même temps. Un état tout juste écrit y sert: il n'est
            ;    gardé que si elle est juste (ValiderEtat). En parallèle, le second
            ;    thread n'a pas pu relire cet état pendant qu'il s'écrivait: il
            ;    est contrôlé à part.
            If Parallele = #False
              Resultat = -1
              If EtatEcrit
                Resultat = ValiderEtat(Niveau, *ZM, ZM, Taille, *Source, "Vérification")
              EndIf
              If Resultat >= 0
                VerifOk = Bool(Resultat = 1)
              Else
                VerifOk = VerifierModele4(*ZM, ZM, Taille, *Source, Niveau)
              EndIf
            ElseIf EtatEcrit
              If VerifOk
                ValiderEtat(Niveau, *ZM, ZM, Taille, *Source, "Contrôle de l'état gardé sur le disque")
              Else
                DeleteFile(FichierEtat(Niveau) + ".tmp")
              EndIf
            EndIf
            If VerifOk = #False And EtatUtile(Niveau)
              ; Prudence: la prochaine fois, tout repartira du texte de référence
              DeleteFile(FichierEtat(Niveau))
            EndIf

            SortieM$ = GenererBloc(EncoderDonnees(*ZM, ZM, Encodage$), Taille, ZM, K, "M", Encodage$, Anglais, "PBC" + Str(CodeNiveau(Niveau)))
            If NiveauProtection > 0
              BrutM$ = SortieM$
              SortieM$ = ProtegerBloc(SortieM$, NiveauProtection)
            EndIf
            TailleM = TailleForum(SortieM$)
          EndIf
        EndIf
      Else
        ; Lanceur auto-extractible: version 1, sans texte de référence
        ZM = EncoderCM(*Source, Taille, *ZM)
        SortieM$ = GenererLanceur(EncoderDonnees(*ZM, ZM, Encodage$), Taille, ZM, K, "M", Encodage$, Anglais)
        TailleM = TailleForum(SortieM$)
      EndIf
      ; (*ZM est gardé jusqu'au contrôle du texte du bloc, plus bas)
    EndIf
  EndIf

  ; 4. Vérification de chaque candidat, puis choix du plus court
  If SortieL$ <> ""
    OkL = VerifierSortie(SortieL$, Format, Texte$, Taille, ZL, K, "L", Encodage$)
  EndIf
  If SortieM$ <> ""
    If Format = #FormatBloc
      ; Méthode v4: le modèle vient d'être vérifié par une décompression complète
      ; (VerifOk). Il reste à contrôler le texte du bloc lui-même: il doit
      ; redonner exactement ces octets compressés, donc ce code.
      If VerifOk
        *VerifOctets = *ZM
        VerifZ = ZM
        *VerifCode = *Source
        VerifT = Taille
        VerifNiveau = Niveau
        OkM = VerifierSortie(SortieM$, Format, Texte$, Taille, ZM, K, "M", Encodage$)
        *VerifOctets = 0
        *VerifCode = 0
        VerifZ = 0
        VerifT = 0
      EndIf
    Else
      OkM = VerifierSortie(SortieM$, Format, Texte$, Taille, ZM, K, "M", Encodage$)
    EndIf
  EndIf
  If *ZM
    FreeMemory(*ZM)
  EndIf
  FreeMemory(*Source)
  FinProgression()

  ; Nom affiché, et rapport Maximal / LZMA retenu pour les estimations suivantes
  ; (MettreAJourNiveaux est appelée par FinOperation, à la fin)
  NomMaximal$ = "Maximal"
  If Format = #FormatBloc
    NomMaximal$ = "Maximal, niveau " + NomNiveau(Niveau)
    If OkM And EstimationAJour And EstimationTaille = Taille And EstimationLZMA > 0
      If RapportNiveau(Niveau) > 0
        RapportNiveau(Niveau) = (RapportNiveau(Niveau) + ((ZM * 1000) / EstimationLZMA)) / 2
      Else
        RapportNiveau(Niveau) = (ZM * 1000) / EstimationLZMA
      EndIf
    EndIf
  EndIf

  If OkL And OkM
    If TailleM < TailleL
      Sortie$ = SortieM$: Retenue$ = NomMaximal$: Brut$ = BrutM$
    Else
      Sortie$ = SortieL$: Retenue$ = "LZMA": Brut$ = BrutL$
    EndIf
  ElseIf OkL
    Sortie$ = SortieL$: Retenue$ = "LZMA": Brut$ = BrutL$
  ElseIf OkM
    Sortie$ = SortieM$: Retenue$ = NomMaximal$: Brut$ = BrutM$
  EndIf

  If Sortie$ = ""
    SetGadgetText(#EditeurSortie, "")
    SetGadgetText(#TexteInfos, "ÉCHEC de la vérification: rien n'a été copié.")
    DerniereTailleForum = 0
    FinOperation()
    MessageRequester("Erreur", "La vérification a échoué: la décompression ne redonne pas exactement le code d'origine." + #LF$ + "Rien n'a été copié dans le presse-papiers.", #PB_MessageRequester_Error)
    ProcedureReturn
  EndIf

  ; 5. Bloc protégé: on vérifie aussi la réparation, sur des copies
  ;    abîmées exprès
  If NiveauProtection > 0
    OkProtection = TesterProtection(Sortie$, Brut$)
  EndIf

  ; 6. Résultat
  AfficherTexte(#EditeurSortie, Sortie$, "(il est copié en entier dans le presse-papiers).")
  SetClipboardText(Sortie$)

  TailleForumOriginal = TailleForum(Texte$)
  TailleForumSortie = TailleForum(Sortie$)
  Pourcentage$ = ReplaceString(StrF(TailleForumSortie * 100.0 / TailleForumOriginal, 1), ".", ",")

  Infos$ = "Retenu: " + Retenue$ + " (" + Pourcentage$ + " % de l'original)"
  If SortieL$ <> ""
    Infos$ = Infos$ + "  |  LZMA: " + FormaterNombre(TailleL)
    If OkL = #False
      Infos$ = Infos$ + " (vérification ratée)"
    EndIf
  EndIf
  If SortieM$ <> ""
    Infos$ = Infos$ + "  |  " + NomMaximal$ + ": " + FormaterNombre(TailleM)
    If OkM = #False
      Infos$ = Infos$ + " (vérification ratée)"
    EndIf
  EndIf
  Infos$ = Infos$ + "  |  Original: " + FormaterNombre(TailleForumOriginal)
  If Len(Texte$) < Len(CodeOriginal$)
    Infos$ = Infos$ + "  |  Bloc « IDE Options » de fin retiré (" + FormaterNombre(Len(CodeOriginal$) - Len(Texte$)) + " caractères)"
  EndIf
  If NiveauProtection > 0
    If OkProtection
      Infos$ = Infos$ + "  |  Protection " + NomNiveauProtection(NiveauProtection) + " (réparation testée)"
    Else
      Infos$ = Infos$ + "  |  Protection " + NomNiveauProtection(NiveauProtection) + " (TEST DE RÉPARATION RATÉ)"
    EndIf
  EndIf
  If Format = #FormatBloc And SortieM$ <> "" And Retenue$ = NomMaximal$
    If Parallele
      Infos$ = Infos$ + "  |  Vérifié en même temps (second thread) et copié."
    Else
      If Raison$ = ""                        ; prévu en parallèle, mais le second thread n'a pas pu partir
        Raison$ = "second thread impossible pendant la compression"
      EndIf
      Infos$ = Infos$ + "  |  Vérifié après la compression (" + Raison$ + ") et copié."
    EndIf
  Else
    Infos$ = Infos$ + "  |  Vérifié et copié."
  EndIf
  If EtatCree
    Infos$ = Infos$ + "  |  État du modèle écrit sur le disque: la prochaine fois, quelques secondes."
  ElseIf EtatRelu And EtatMaximalPrepare = #False
    Infos$ = Infos$ + "  |  État du modèle relu depuis le disque."
  EndIf
  Infos$ = Infos$ + CompteRenduReference()
  SetGadgetText(#TexteInfos, Infos$)

  DerniereTailleForum = TailleForumSortie
  DernierModeBase64 = Bool(Encodage$ = "B")
  DernierFormat = Format
  FinOperation()

  If (SortieL$ <> "" And OkL = #False) Or (SortieM$ <> "" And OkM = #False)
    MessageRequester("Attention", "Une des deux méthodes a échoué à la vérification et a été écartée." + #LF$ + "Le résultat copié est correct. Signale-le pour que je corrige.", #PB_MessageRequester_Warning)
  ElseIf NiveauProtection > 0 And OkProtection = #False
    MessageRequester("Attention", "Le bloc copié est correct, mais le test de réparation (sur une copie abîmée exprès) a échoué." + #LF$ + "La protection ne fonctionne donc pas comme prévu: signale-le pour que je corrige.", #PB_MessageRequester_Warning)
  ElseIf TailleForumSortie >= TailleForumOriginal
    MessageRequester("Attention", "Ce code est trop petit pour que la compression soit utile: la version compressée est plus longue que l'original.", #PB_MessageRequester_Warning)
  EndIf
EndProcedure


; ----------------------------------------------------------------------------
;  Réglages mémorisés d'une utilisation à l'autre
; ----------------------------------------------------------------------------
Procedure ChargerReglages()
  Protected Format, Methode, Encodage, Langue, Limite, Protection, Niveau, i

  Format = #FormatLanceur
  Methode = #MethodeAuto
  Encodage = #EncodageUnicode
  Langue = 0
  Limite = #LimiteParDefaut
  Protection = 2
  Niveau = #NiveauMoyen

  If OpenPreferences(FichierReglages$)
    Format = ReadPreferenceInteger("Format", #FormatLanceur)
    Methode = ReadPreferenceInteger("Methode", #MethodeAuto)
    Encodage = ReadPreferenceInteger("Encodage", ReadPreferenceInteger("Mode", #EncodageUnicode))
    Langue = ReadPreferenceInteger("Langue", 0)
    Limite = ReadPreferenceInteger("Limite", #LimiteParDefaut)
    SetGadgetState(#CaseOptionsIDE, ReadPreferenceInteger("GarderOptionsIDE", 0))
    Protection = ReadPreferenceInteger("NiveauProtection", 2)
    Niveau = ReadPreferenceInteger("Niveau", #NiveauMoyen)
    VitesseCM = ReadPreferenceInteger("VitesseCM", VitesseCM)
    GarderEtat = Bool(ReadPreferenceInteger("GarderEtat", 1) <> 0)
    CheminReferenceChoisi$ = ReadPreferenceString("FichierReference", "")
    For i = #NiveauFaible To #NiveauMaximal
      RapportNiveau(i) = ReadPreferenceInteger("Rapport" + Str(i), 0)
      If RapportNiveau(i) < 0 Or RapportNiveau(i) > 2000
        RapportNiveau(i) = 0
      EndIf
    Next
    ClosePreferences()
  EndIf

  If Format <> #FormatLanceur And Format <> #FormatBloc
    Format = #FormatLanceur
  EndIf
  If Methode < #MethodeAuto Or Methode > #MethodeMaximal
    Methode = #MethodeAuto
  EndIf
  If Encodage <> #EncodageUnicode And Encodage <> #EncodageBase64
    Encodage = #EncodageUnicode
  EndIf
  If Langue <> 0 And Langue <> 1
    Langue = 0
  EndIf
  If Limite < 0
    Limite = #LimiteParDefaut
  EndIf
  If Protection < 0 Or Protection > 5
    Protection = 2
  EndIf
  If Niveau < #NiveauFaible Or Niveau > #NiveauMaximal
    Niveau = #NiveauMoyen
  EndIf
  If VitesseCM < 1000
    VitesseCM = 120000
  EndIf

  SetGadgetState(#ChoixFormat, Format)
  SetGadgetState(#ChoixMethode, Methode)
  SetGadgetState(#ChoixEncodage, Encodage)
  SetGadgetState(#ChoixLangue, Langue)
  SetGadgetText(#ChampLimite, Str(Limite))
  SetGadgetState(#ChoixProtection, Protection)
  SetGadgetState(#ChoixNiveau, Niveau)
  SetGadgetState(#CaseGarderEtat, GarderEtat)
EndProcedure


Procedure SauverReglages()
  Protected i

  If CreatePreferences(FichierReglages$)
    WritePreferenceInteger("Format", GetGadgetState(#ChoixFormat))
    WritePreferenceInteger("Methode", GetGadgetState(#ChoixMethode))
    WritePreferenceInteger("Encodage", GetGadgetState(#ChoixEncodage))
    WritePreferenceInteger("Langue", GetGadgetState(#ChoixLangue))
    WritePreferenceInteger("Limite", Val(GetGadgetText(#ChampLimite)))
    WritePreferenceInteger("GarderOptionsIDE", GetGadgetState(#CaseOptionsIDE))
    WritePreferenceInteger("NiveauProtection", GetGadgetState(#ChoixProtection))
    WritePreferenceInteger("Niveau", GetGadgetState(#ChoixNiveau))
    WritePreferenceInteger("VitesseCM", VitesseCM)
    WritePreferenceInteger("GarderEtat", GarderEtat)
    WritePreferenceString("FichierReference", CheminReferenceChoisi$)
    For i = #NiveauFaible To #NiveauMaximal
      WritePreferenceInteger("Rapport" + Str(i), RapportNiveau(i))
    Next
    ClosePreferences()
  EndIf
EndProcedure


; ----------------------------------------------------------------------------
;  Placement des gadgets quand la fenêtre change de taille
; ----------------------------------------------------------------------------
Procedure Redimensionner()
  Protected Largeur, Hauteur, Zone

  ; Le panneau d'onglets occupe toute la fenêtre ; les gadgets se placent
  ; dans la zone intérieure d'un onglet
  ResizeGadget(#Onglets, 0, 0, WindowWidth(#FenetrePrincipale), WindowHeight(#FenetrePrincipale) - StatusBarHeight(#BarreEtat))
  Largeur = GetGadgetAttribute(#Onglets, #PB_Panel_ItemWidth)
  Hauteur = GetGadgetAttribute(#Onglets, #PB_Panel_ItemHeight)
  If Largeur <= 0
    Largeur = WindowWidth(#FenetrePrincipale) - 8
  EndIf
  If Hauteur <= 0
    Hauteur = WindowHeight(#FenetrePrincipale) - StatusBarHeight(#BarreEtat) - 32
  EndIf

  ; Onglet Compresser
  Zone = (Hauteur - 368) / 2
  If Zone < 50
    Zone = 50
  EndIf

  ResizeGadget(#TexteNiveauInfo, 80, 211,        Largeur - 90, 20)
  ResizeGadget(#TexteEntree,   10, 236,          Largeur - 20, 20)
  ResizeGadget(#EditeurEntree, 10, 258,          Largeur - 20, Zone)
  ResizeGadget(#TexteSortie,   10, 264 + Zone,   Largeur - 20, 20)
  ResizeGadget(#EditeurSortie, 10, 286 + Zone,   Largeur - 20, Zone)
  ResizeGadget(#TexteInfos,    10, Hauteur - 76, Largeur - 20, 40)
  ResizeGadget(#Indicateur,    10, Hauteur - 32, Largeur - 20, 24)

  ; Onglet Décompresser
  ResizeGadget(#EditeurDec,    10, 50,           Largeur - 20, Hauteur - 106)
  ResizeGadget(#TexteInfosDec, 10, Hauteur - 50, Largeur - 20, 42)
EndProcedure


; ============================================================================
;  Programme principal
; ============================================================================
If OpenWindow(#FenetrePrincipale, 0, 0, 930, 790, "Compresseur / Décompresseur PureBasic v6.4.1", #PB_Window_SystemMenu | #PB_Window_MinimizeGadget | #PB_Window_MaximizeGadget | #PB_Window_SizeGadget | #PB_Window_ScreenCentered)

  WindowBounds(#FenetrePrincipale, 900, 560, #PB_Ignore, #PB_Ignore)

  ; Barre d'état: progression (case 0) et temps écoulé / restant (case 1)
  If CreateStatusBar(#BarreEtat, WindowID(#FenetrePrincipale))
    AddStatusBarField(250)
    AddStatusBarField(#PB_Ignore)
  EndIf
  StatusBarProgress(#BarreEtat, 0, 0)
  StatusBarText(#BarreEtat, 1, "Prêt.")

  PanelGadget(#Onglets, 0, 0, 930, 790)

  ; =========================== Onglet Compresser ===========================
  AddGadgetItem(#Onglets, -1, "Compresser")

  ; Ligne 1: actions
  ButtonGadget(#BoutonColler,     10,  10, 220, 30, "Coller depuis le presse-papiers")
  ButtonGadget(#BoutonOuvrir,     240, 10, 170, 30, "Ouvrir un fichier .pb")
  ButtonGadget(#BoutonCompresser, 420, 10, 190, 30, "Compresser et copier")

  ; Ligne 2: format et méthode
  TextGadget(#TexteFormat, 10, 54, 65, 20, "Format:")
  ComboBoxGadget(#ChoixFormat, 80, 50, 250, 24)
  AddGadgetItem(#ChoixFormat, #FormatLanceur, "Auto-extractible (F5 chez le lecteur)")
  AddGadgetItem(#ChoixFormat, #FormatBloc,    "Données seules (onglet Décompresser)")

  TextGadget(#TexteMethode, 345, 54, 65, 20, "Méthode:")
  ComboBoxGadget(#ChoixMethode, 415, 50, 230, 24)
  AddGadgetItem(#ChoixMethode, #MethodeAuto,    "Automatique (le plus court)")
  AddGadgetItem(#ChoixMethode, #MethodeLZMA,    "LZMA")
  AddGadgetItem(#ChoixMethode, #MethodeMaximal, "Maximal (mélange de contextes)")

  ; Ligne 3: encodage et langue
  TextGadget(#TexteEncodage, 10, 86, 65, 20, "Encodage:")
  ComboBoxGadget(#ChoixEncodage, 80, 82, 250, 24)
  AddGadgetItem(#ChoixEncodage, #EncodageUnicode, "Unicode (le plus compact)")
  AddGadgetItem(#ChoixEncodage, #EncodageBase64,  "Base64 (passe partout)")

  TextGadget(#TexteLangue, 345, 86, 125, 20, "Langue du résultat:")
  ComboBoxGadget(#ChoixLangue, 475, 82, 110, 24)
  AddGadgetItem(#ChoixLangue, -1, "Français")
  AddGadgetItem(#ChoixLangue, -1, "English")

  ; Ligne 4: options IDE et limite du forum
  CheckBoxGadget(#CaseOptionsIDE, 10, 114, 400, 24, "Garder le bloc « IDE Options » (réglages de compilation)")
  TextGadget(#TexteLimite, 420, 118, 110, 20, "Limite du forum:")
  StringGadget(#ChampLimite, 535, 114, 80, 24, "", #PB_String_Numeric)
  TextGadget(#TexteCaracteres, 622, 118, 80, 20, "caractères")

  ; Ligne 5: protection contre les erreurs
  TextGadget(#TexteProtection, 10, 150, 75, 20, "Protection:")
  ComboBoxGadget(#ChoixProtection, 80, 146, 250, 24)
  AddGadgetItem(#ChoixProtection, -1, "Aucune")
  AddGadgetItem(#ChoixProtection, -1, "Faible (×1, environ +3,5 %)")
  AddGadgetItem(#ChoixProtection, -1, "Normale (×2, environ +5 %)")
  AddGadgetItem(#ChoixProtection, -1, "Moyen (×4, environ +9 %)")
  AddGadgetItem(#ChoixProtection, -1, "Élevé (×8, environ +16 %)")
  AddGadgetItem(#ChoixProtection, -1, "Maximal (×16, environ +30 %)")
  TextGadget(#TexteProtectionInfo, 345, 150, 500, 20, "")

  ; Ligne 6: niveau de compression (méthode Maximal, données seules), et état
  ; du modèle gardé sur le disque
  Define i
  TextGadget(#TexteNiveau, 10, 186, 65, 20, "Niveau:")
  ComboBoxGadget(#ChoixNiveau, 80, 182, 430, 24)
  CheckBoxGadget(#CaseGarderEtat, 520, 182, 240, 24, "Garder l'état du modèle sur le disque")
  ButtonGadget(#BoutonEffacerEtat, 765, 181, 115, 26, "Effacer")
  For i = #NiveauFaible To #NiveauMaximal
    AddGadgetItem(#ChoixNiveau, i, NomNiveau(i))
  Next
  TextGadget(#TexteNiveauInfo, 80, 211, 840, 20, "")

  ; Zones de texte
  TextGadget(#TexteEntree,   10, 10, 100, 20, "Code d'origine:")
  EditorGadget(#EditeurEntree, 10, 10, 100, 100, #PB_Editor_ReadOnly)
  TextGadget(#TexteSortie,   10, 10, 100, 20, "Résultat à poster sur le forum, entre les balise de code:")
  EditorGadget(#EditeurSortie, 10, 10, 100, 100, #PB_Editor_ReadOnly)
  TextGadget(#TexteInfos,    10, 10, 100, 20, "Colle ton code ou ouvre un fichier .pb, puis clique sur « Compresser et copier ».")
  TextGadget(#Indicateur,    10, 10, 100, 20, "")

  ; ========================== Onglet Décompresser ==========================
  AddGadgetItem(#Onglets, -1, "Décompresser")
  ButtonGadget(#BoutonDecColler,      10,  10, 260, 30, "Coller et décompresser")
  ButtonGadget(#BoutonDecCopier,      280, 10, 200, 30, "Copier le code")
  ButtonGadget(#BoutonDecEnregistrer, 490, 10, 200, 30, "Enregistrer en .pb...")
  EditorGadget(#EditeurDec, 10, 50, 100, 100, #PB_Editor_ReadOnly)
  TextGadget(#TexteInfosDec, 10, 10, 100, 20, "Copie un bloc compressé sur le forum, puis clique sur « Coller et décompresser ».")

  CloseGadgetList()

  If LoadFont(#PoliceCode, "Consolas", 10)
    SetGadgetFont(#EditeurEntree, FontID(#PoliceCode))
    SetGadgetFont(#EditeurSortie, FontID(#PoliceCode))
    SetGadgetFont(#EditeurDec, FontID(#PoliceCode))
  EndIf

  ; Vérification en parallèle (option « thread-safe » du compilateur)
  CompilerIf #PB_Compiler_Thread
    MutexCM4 = CreateMutex()
  CompilerEndIf

  ChargerReglages()
  MettreAJourCaseProtection()
  MettreAJourNiveaux()
  MettreAJourIndicateur()
  MettreAJourEtatDisque()
  Redimensionner()
  BindEvent(#PB_Event_SizeWindow, @Redimensionner(), #FenetrePrincipale)

  ; Le presse-papiers ne contient QU'UN bloc compact ? Onglet Décompresser.
  ; Sinon, on ne fait rien du tout (pas de message).
  Define Presse$ = GetClipboardText()
  If EstBlocCompactPur(Presse$)
    SetGadgetState(#Onglets, 1)
    DecompresserTexte(Presse$)
    FinOperation()
  EndIf

  Repeat
    Select WaitWindowEvent()

      Case #PB_Event_Gadget
        Select EventGadget()
          Case #BoutonColler
            CollerDepuisPressePapiers()
            MettreAJourNiveaux()
          Case #BoutonOuvrir
            OuvrirFichier()
            MettreAJourNiveaux()
          Case #BoutonCompresser
            Compresser()
          Case #ChampLimite
            If EventType() = #PB_EventType_Change
              MettreAJourIndicateur()
            EndIf
          Case #ChoixFormat, #ChoixEncodage
            MettreAJourCaseProtection()
            MettreAJourNiveaux()
          Case #ChoixMethode, #ChoixNiveau, #ChoixProtection
            MettreAJourNiveaux()
          Case #CaseOptionsIDE
            EstimationAJour = #False
            MettreAJourNiveaux()
          Case #CaseGarderEtat
            GarderEtat = Bool(GetGadgetState(#CaseGarderEtat) = #PB_Checkbox_Checked)
            MettreAJourNiveaux()
          Case #BoutonEffacerEtat
            EffacerEtats()
          Case #BoutonDecColler
            CollerEtDecompresser()
            FinOperation()
          Case #BoutonDecCopier
            CopierCodeDecompresse()
          Case #BoutonDecEnregistrer
            EnregistrerCodeDecompresse()
        EndSelect

      Case #PB_Event_CloseWindow
        SauverReglages()
        Break

    EndSelect
  ForEver

EndIf


; ============================================================================
;  Données: table de la méthode Maximal, et lignes du décompresseur Maximal
;  telles qu'elles sont écrites dans les lanceurs (identiques à DecoderCM).
; ============================================================================
DataSection
  Sq33:
  Data.q 1,2,3,6,10,16,27,45,73,120,194,310,488,747,1101,1546,2047,2549,2994,3348,3607,3785,3901,3975,4022,4050,4068,4079,4085,4089,4092,4093,4094

  LanceurCM:
  Data.s "Dim T33.q(32)"
  Data.s "Restore Sq33"
  Data.s "For i = 0 To 32"
  Data.s "Read.q u"
  Data.s "T33(i) = u"
  Data.s "Next"
  Data.s "Dim Sq.q(4094)"
  Data.s "For i = 0 To 4094"
  Data.s "u = (i + 1) % 128"
  Data.s "v = (i + 1) / 128"
  Data.s "Sq(i) = ((T33(v) * (128 - u)) + (T33(v + 1) * u) + 64) / 128"
  Data.s "Next"
  Data.s "Dim St.q(4095)"
  Data.s "v = 0"
  Data.s "For i = 0 To 4094"
  Data.s "While v <= Sq(i)"
  Data.s "St(v) = i - 2047"
  Data.s "v = v + 1"
  Data.s "Wend"
  Data.s "Next"
  Data.s "While v <= 4095"
  Data.s "St(v) = 2047"
  Data.s "v = v + 1"
  Data.s "Wend"
  Data.s "Dim Kr.q(255)"
  Data.s "For i = 0 To 255"
  Data.s "Kr(i) = 8192 / ((2 * i) + 3)"
  Data.s "Next"
  Data.s "Dim P2.q(8)"
  Data.s "P2(0) = 1"
  Data.s "For i = 1 To 8"
  Data.s "P2(i) = P2(i - 1) * 2"
  Data.s "Next"
  Data.s "Dim M.l(12582911)"
  Data.s "For i = 0 To 12582911"
  Data.s "M(i) = 8388608"
  Data.s "Next"
  Data.s "Dim MT.l(1048575)"
  Data.s "Dim MS.q(63)"
  Data.s "For i = 0 To 63"
  Data.s "MS(i) = 8388608"
  Data.s "Next"
  Data.s "Dim W.q(2047)"
  Data.s "For i = 0 To 2047"
  Data.s "W(i) = 16384"
  Data.s "Next"
  Data.s "Dim Ap.q(2162687)"
  Data.s "For i = 0 To 2162687"
  Data.s "u = ((i % 33) * 128) - 1"
  Data.s "If u < 0: u = 0: EndIf"
  Data.s "If u > 4094: u = 4094: EndIf"
  Data.s "Ap(i) = Sq(u) * 16"
  Data.s "Next"
  Data.s "Dim Hi.q(4)"
  Data.s "Dim Hc.q(5)"
  Data.s "Dim Ix.q(6)"
  Data.s "Dim Sv.q(6)"
  Data.s "x = 0: ip = 0"
  Data.s "For k = 1 To 4"
  Data.s "x = x * 256"
  Data.s "If ip < Z: x = x + PeekA(*C + ip): EndIf"
  Data.s "ip = ip + 1"
  Data.s "Next"
  Data.s "x1 = 0: x2 = 4294967295: wh = 0: ls = 0: pl = 0: ml = 0: mp = 0: chk = 0"
  Data.s "For pos = 0 To T - 1"
  Data.s "h = 0"
  Data.s "For k = 0 To 4"
  Data.s "h = ((((h + Hi(k)) + 1) * $6F4F2B) / 256) % $1000000"
  Data.s "If k < 4: Hc(k) = h: EndIf"
  Data.s "Next"
  Data.s "hm = h % $100000"
  Data.s "Hc(4) = (((((wh * 256) + Hi(0)) + 1) * $6F4F2B) / 256) % $1000000"
  Data.s "ab = 0"
  Data.s "If pl + pos - ls < ls: ab = PeekA(*D + pl + pos - ls): EndIf"
  Data.s "Hc(5) = (((((ab * 256) + Hi(0)) + 1048577) * $6F4F2B) / 256) % $1000000"
  Data.s "If ml > 0 And PeekA(*D + mp) = Hi(0)"
  Data.s "If ml < 65535: ml = ml + 1: EndIf"
  Data.s "mp = mp + 1"
  Data.s "Else"
  Data.s "ml = 0"
  Data.s "EndIf"
  Data.s "If ml = 0 And pos >= 5"
  Data.s "mp = MT(hm)"
  Data.s "While mp > 0 And ml < 124 And ml < mp"
  Data.s "If PeekA(*D + mp - ml - 1) <> PeekA(*D + pos - ml - 1): Break: EndIf"
  Data.s "ml = ml + 1"
  Data.s "Wend"
  Data.s "EndIf"
  Data.s "MT(hm) = pos"
  Data.s "ma = Bool(ml > 0)"
  Data.s "c0 = 1"
  Data.s "For j = 0 To 7"
  Data.s "ws = c0 * 8"
  Data.s "dot = 0"
  Data.s "For k = 0 To 5"
  Data.s "Ix(k) = (((((((Hc(k) * 256) + c0) * $2E8BA3) / 1024) % $200000)) + (k * $200000))"
  Data.s "Sv(k) = St(M(Ix(k)) / 4096)"
  Data.s "dot = dot + (W(ws + k) * Sv(k))"
  Data.s "Next"
  Data.s "Sv(6) = 0"
  Data.s "If ma"
  Data.s "pb = PeekA(*D + mp) + 256"
  Data.s "If pb / P2(8 - j) = c0"
  Data.s "u = ml"
  Data.s "If u > 31: u = 31: EndIf"
  Data.s "Ix(6) = (u * 2) + ((pb / P2(7 - j)) % 2)"
  Data.s "Sv(6) = St(MS(Ix(6)) / 4096)"
  Data.s "Else"
  Data.s "ma = 0"
  Data.s "EndIf"
  Data.s "EndIf"
  Data.s "dot = dot + (W(ws + 6) * 256) + (W(ws + 7) * Sv(6))"
  Data.s "e = dot / 65536"
  Data.s "If e > 2047: e = 2047: EndIf"
  Data.s "If e < -2047: e = -2047: EndIf"
  Data.s "pm = Sq(e + 2047)"
  Data.s "px = pm"
  Data.s "s = St(pm) + 2048"
  Data.s "aw = s % 128"
  Data.s "ai = (((Hi(0) * 256) + c0) * 33) + (s / 128)"
  Data.s "pm = (pm + (3 * (((Ap(ai) * (128 - aw)) + (Ap(ai + 1) * aw)) / 2048))) / 4"
  Data.s "If pm < 1: pm = 1: EndIf"
  Data.s "If pm > 4095: pm = 4095: EndIf"
  Data.s "xm = x1 + (((x2 - x1) / 4096) * pm)"
  Data.s "y = Bool(x <= xm)"
  Data.s "If y: x2 = xm: Else: x1 = xm + 1: EndIf"
  Data.s "er = ((y * 4096) - px) * 2"
  Data.s "For k = 0 To 5"
  Data.s "W(ws + k) = W(ws + k) + ((Sv(k) * er) / 1024)"
  Data.s "u = M(Ix(k)) / 256"
  Data.s "v = M(Ix(k)) % 256"
  Data.s "If y: u = u + (((65536 - u) * Kr(v)) / 4096): Else: u = u - ((u * Kr(v)) / 4096): EndIf"
  Data.s "If v < 127: v = v + 1: EndIf"
  Data.s "M(Ix(k)) = (u * 256) + v"
  Data.s "Next"
  Data.s "W(ws + 6) = W(ws + 6) + ((256 * er) / 1024)"
  Data.s "W(ws + 7) = W(ws + 7) + ((Sv(6) * er) / 1024)"
  Data.s "If ma"
  Data.s "u = MS(Ix(6)) / 256"
  Data.s "v = MS(Ix(6)) % 256"
  Data.s "If y: u = u + (((65536 - u) * Kr(v)) / 4096): Else: u = u - ((u * Kr(v)) / 4096): EndIf"
  Data.s "If v < 127: v = v + 1: EndIf"
  Data.s "MS(Ix(6)) = (u * 256) + v"
  Data.s "EndIf"
  Data.s "g = (y * 65536) + (y * 64) - (2 * y)"
  Data.s "Ap(ai) = Ap(ai) + (((g - Ap(ai)) * (128 - aw)) / 8192)"
  Data.s "Ap(ai + 1) = Ap(ai + 1) + (((g - Ap(ai + 1)) * aw) / 8192)"
  Data.s "c0 = (c0 * 2) + y"
  Data.s "While x1 / 16777216 = x2 / 16777216"
  Data.s "x1 = (x1 % 16777216) * 256"
  Data.s "x2 = ((x2 % 16777216) * 256) + 255"
  Data.s "x = (x % 16777216) * 256"
  Data.s "If ip < Z: x = x + PeekA(*C + ip): EndIf"
  Data.s "ip = ip + 1"
  Data.s "Wend"
  Data.s "Next"
  Data.s "c = c0 - 256"
  Data.s "PokeA(*D + pos, c)"
  Data.s "chk = ((chk * 33) + c) % 1000000007"
  Data.s "For k = 4 To 1 Step -1"
  Data.s "Hi(k) = Hi(k - 1)"
  Data.s "Next"
  Data.s "Hi(0) = c"
  Data.s "If c = 10: pl = ls: ls = pos + 1: EndIf"
  Data.s "If (c >= 48 And c <= 57) Or (c >= 65 And c <= 90) Or (c >= 97 And c <= 122) Or c = 95"
  Data.s "wh = ((((wh + c) + 1) * $6F4F2B) / 256) % $1000000"
  Data.s "Else"
  Data.s "wh = 0"
  Data.s "EndIf"
  Data.s "Next"
  Data.s ""

  ; Table des segments du texte de référence: taille, somme de contrôle.
  ; Le texte lui-même est dans le fichier de référence, à côté du programme
  ; (#NomFichierReference$), compressé d'un seul tenant par la méthode v4.
  ; NE JAMAIS MODIFIER les segments utilisés par des blocs déjà postés.
  TableReference:
  Data.q 52985, 934947225
  Data.q 1545285, 263948469
  Data.q 828346, 727537064
  Data.q 3303511, 299593164
  Data.q 5557076, 536586336
EndDataSection


; ============================================================================
;  CRÉDITS DU TEXTE DE RÉFÉRENCE
;  Les segments 2, 3 et 4 du texte de référence contiennent du code libre
;  d'autres auteurs, inclus tel quel (avec leurs mentions de licence) sous
;  forme compressée. Merci à eux.
;
;  Code libre inclus dans le texte de référence (niveaux Normal, Élevé, Maximal)
;  Chaque fichier a été vérifié un par un: seuls les codes sous licence MIT,
;  zlib, BSD, domaine public ou déclarés libres ont été gardés.
;
;  https://github.com/SicroAtGit/PureBasic-CodeArchiv-Rebirth
;    licences: MIT (226 fichiers), PD (1 fichiers), Libre (2 fichiers)
;    auteurs cités dans les fichiers: ts-soft, Sicro, wilbert, Bisonte, walbus, NicTheQuick, Thorsten Hoeppner, David Vogel, Shardik, Michael Suther, TI-994A, Kiffi, CSHW89 (Kevin Jasik), Kevin Jasik (CSHW89), NicTheQuick, mk-soft, hjbremer, ts-soft (Thomas Schulz), Thomas (ts-soft) Schulz, GPI, SBond, 	Martin Langer (alias SBond), Andesdaf, Imhotheb (Andreas Wenzl), gekkonier, Lunasole, Little John, Poshu, remi_meier, uwekel, J. Baker, Michael R. King, Shardik, wilbert, Imhotheb, Werner Albus - www.nachtoptik.de, Project Nayuki, Thorsten1867, Justin, Jürgen Lüthje, True29, Andrew Ferguson, helpy, STARGÅTE
;
;  https://github.com/Hoeppner1867/PureBasic
;    licences: MIT (72 fichiers)
;    auteurs cités dans les fichiers: Thorsten Hoeppner, TI-994A, mk-soft, Sicro, ts-soft, wilbert, Werner Albus - www.nachtoptik.de, Werner Albus, Daniel Beer, Project Nayuki, Martin Guttmann (alias STARGÅTE)
;
;  https://github.com/codeprof/small-PureBasic-projects
;    licences: PD (43 fichiers), MIT (2 fichiers), zlib (4 fichiers)
;    auteurs cités dans les fichiers: codeprof, Stefan Moebius
;
;  https://github.com/deseven/pbsamples
;    licences: PD (15 fichiers)
;    auteurs cités dans les fichiers: (voir le dépôt)
;
;  https://github.com/tajmone/purebasic-archives
;    licences: Libre (2 fichiers), PD (10 fichiers)
;    auteurs cités dans les fichiers: Thomas (ts-soft) Schulz
;
;  Pour les codes sous licence MIT, la mention suivante s'applique (avec le
;  nom de l'auteur indiqué dans chaque code):
;  Permission is hereby granted, free of charge, to any person obtaining a
;  copy of this software and associated documentation files (the "Software"),
;  to deal in the Software without restriction, including without limitation
;  the rights to use, copy, modify, merge, publish, distribute, sublicense,
;  and/or sell copies of the Software, and to permit persons to whom the
;  Software is furnished to do so, subject to the following conditions:
;  The above copyright notice and this permission notice shall be included in
;  all copies or substantial portions of the Software.
;  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
;  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
;  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
;  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
;  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
;  FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
;  DEALINGS IN THE SOFTWARE.
; ============================================================================

; IDE Options = PureBasic 6.41 (Windows - x64)
; CursorPosition = 9584
; FirstLine = 9531
; Folding = ----------------------------
; EnableThread
; EnableXP
; DPIAware
; EnableCompileCount = 11
; EnableBuildCount = 0
; EnableExeConstant