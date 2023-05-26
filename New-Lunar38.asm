   ORG 15995 ; pointeur d'adresse pour charger le code du jeux

COLVIRT EQU 20 ; Ligne suivante de l'écran (le nombre de colonnes réelles est < nombre de colonnes maxi (ex : 40 colonnes à l'écran mais 64 pour passer à la ligne suivante)
COLREAL EQU 15 ; 
COLDIFF EQU 5 ; différence entre COLVIRT et COLREAL

; Pour test crée le sprite en mémoire (A ajouter dans les DATA du basic)
LARGE DEFB 4 ; largeur du sprite du joueur
HAUT DEFB 2 ; hauteur du sprite du joueur
VAISDATA DEFW 15995 ; adresse mémoire datas du sprite du joueur (3E7B)
VAISPOS DEFW 983 ; position de départ du sprite du joueur sur l'écran (15999 / 03D7)
MAPHAUT DEFB 2 ; nombre de lignes de la map à afficher sur l'écran
MAPPOS DEFW 981 ;
; SPRJOU DEFM "ABCD FGH" ; Exemple de dessin sprite du joueur en mémoire (3E81) => Cas 1 OK
SPRJOU DEFM "ABC EFG " ; Exemple de dessin sprite du joueur en mémoire (3E81)

; Fin du test
; Version DATA du BASIC
; DATA 07,03,123,62,215,3,65,66,67,68,...

; Test pour map en mémoire
MAPLINE1 DEFM "X       U     X" ; 3E8C
MAPLINE2 DEFM "Y       Z     Y"
;MAPDATA DEFS 500 ; 500 emplacements mémoire pour stockage datas de la map plus tard a augmenter + tard / pour l'instant la map est créée en mémoire par MAPLINE1 et MAPLINE2
; Fin du test

SAVJOU DEFW 0 ; permet de tester le contenu de la ligne suivante du sprite
SAVECRJOU DEFW 0 ; permet de conserver l'adresse mémoire écran de la position du sprite pour la ligne suivante
NBSPAC DEFW 0 ; permet de compter le nombre de lignes du sprite contenant un espace sur un coté en fonction du sens de déplacement demandé
CPTLIG DEFB 0 ; permet de décrémenter le nb de lignes affichées pour un sprite
CPTMAP DEFB 0 ; permet de décrémenter le nb de lignes affichées pour la map
SHWPLAY DEFB 1 ; permet de détecter si le sprite du joueur doit être réaffiché à l'écran
; 1 => affiche à la position de démarrage
; 2 => décale d'une position à gauche
; 3 => décale d'une position à droite
; 4 => décale d'une position en haut @TODO
; 5 => décale d'une position en bas @TODO

BEGIN
    PUSH IX ; 3eb1
    PUSH IY

; Initialisation des paramètres
    LD HL,985
    LD (VAISPOS),HL

; Boucle principale du moteur
BOUCLE
;    LD E,01              ; 
;    RST 20h              ; DEFB 31H

    ; Dessine la map à l'écran TODO : gérer le décalage horizontal ou vertical de la map
    LD IX,(VAISDATA)
    LD A,(IX+6)         ; Charge dans le compteur le nb de lignes a afficher de la map

    LD HL,MAPLINE1      ; Charge HL et IX avec l'@ de début des données de la map
    LD IX,MAPLINE1

    LD (CPTMAP),A
    CALL DRAWMAP

    ;LD A,8 ; par défaut a gauche pour le test
    CP 8                 ; 
    CALL Z,GAUCHE        ; 
NEXT    
    CP 26                ; 
    CALL Z,DROITE        ; 
NEXT2    
    CP 77                ; Touche Tir (W)
    CALL Z,TIR           ; Charge l'@ mémoire initiale de la balle gauche et droite sur l'écran
NEXT3
    ; Dessine toujours le sprite du joueur à l'écran
    LD HL,SPRJOU
    LD IX,(VAISDATA)
    LD A,(IX+1) ; Charge dans le compteur le nb de lignes du sprite
    LD (CPTLIG),A
    CALL DISSPRIT

SUITE
    JP BOUCLE

; TODO : étudier le regroupement du code similaire de GAUCHE et DROITE

; Décale le sprite du joueur d'une colonne vers la gauche
GAUCHE
    LD HL,SPRJOU 
    LD (SAVJOU),HL ; pour conserver l'adresse mémoire de la ligne du sprite en cours de contrôle
    LD HL,0
    LD (NBSPAC),HL ; pour conserver le nombre de lignes du sprite ayant 32 à gauche

    LD HL,(VAISPOS)
    ; vérifions tout d'abord que le sprite n'est pas déjà dans le cas ou la ligne du sprite à 32 à gauche et qu'il chevauche déjà la map
    LD A,(HL)
    CP 32
    JP NZ,NEXT ; déplacement interdit ; Pas possible de mettre un RET

    DEC HL
    PUSH HL

    LD A,(HAUT) ; Charge dans le compteur le nb de lignes du sprite
    LD (CPTLIG),A

; teste si le décalage à gauche est autorisé
NXTLEFT
    LD A,(HL) ; charge le contenu de la map sur l'écran à cette adresse

    CP 32
    JP Z NXLEFT2 ; emplacement ligne de map libre, passe à la ligne suivante

; Doit contrôler la valeur du contenu du sprite du joueur si 32 alors ok
DATLEFT
    LD HL,(SAVJOU)

    LD A,(HL)
    CP 32
    JP NZ,EXLEFT3 ; déplacement interdit
    LD A,(NBSPAC)
    INC A
    LD (NBSPAC),A ; incrémente le nombre de lignes du sprite dont la valeur est 32 à gauche
    POP HL

NXLEFT2
    ; Sort si c'était la dernière ligne du sprite
    LD A,(CPTLIG) ; hauteur
    DEC A
    JP Z,EXLEFT ; dernière ligne du sprite et déplacement autorisé

    LD (CPTLIG),A ; enregistre le nombre de lignes du sprite du joueur restant à controler

    PUSH HL ; 982 premier passage premiere ligne, 1002 deuxieme ligne --- 981 deuxieme passage premiere ligne, 1001 deuxieme ligne
    ; se positionne sur le dessin en mémoire de la prochaine ligne du sprite du joueur
    LD HL,SPRJOU ; Charge HL avec l'@ de début des données de la map
    LD IX,(VAISDATA) ; Charge IX avec l'@ de début des données du joueur (15995)
    LD B,0
    LD C,(IX+0) ; (4) largeur d'une ligne sprite du joueur
    ADD HL,BC ; (16008) 2eme ligne de dessin du sprite du joueur
    LD (SAVJOU),HL

    POP HL
    LD BC,COLVIRT ; (20)
    ADD HL,BC ; (1002) se positionne sur l'adresse de la prochaine ligne de la map à l'écran

    JP NXTLEFT

EXLEFT
    LD A,(NBSPAC)
    LD IX,HAUT
    SUB (IX)
    CP 0
    JP NZ,EXLEFT2
    ; cas particulier ou toutes les colonnes du sprite du joueur on un espace à gauche, il ne faut pas écraser la colonne de la map
    LD A,21 ; 21 => déplacement autorisé à gauche sans écraser la colonne de la map
    LD (SHWPLAY),A
    JP EXLEFT3

EXLEFT2
    ; signale le décalage normal de l'affichage du sprite du joueur à gauche
    LD A,2 ; 2 => déplacement normal autorisé à gauche
    LD (SHWPLAY),A

EXLEFT3
    LD A,(SHWPLAY)
    CP 2
    JP NZ,EXLEFT4

    LD HL,(VAISPOS)
    DEC HL
    LD (VAISPOS),HL ; enregistre la nouvelle position du sprite du joueur
    JP NEXT ; déplacement normal autorisé retourne dans la boucle principale ; Pas possible de mettre un RET

EXLEFT4
    CP 21
    JP NZ,NEXT ; déplacement interdit retourne dans la boucle principale ; Pas possible de mettre un RET

    LD HL,(VAISPOS)
    DEC HL
    LD (VAISPOS),HL ; enregistre la nouvelle position du sprite du joueur
    JP NEXT ; déplacement autorisé sans écraser la colonne de la map ; retourne dans la boucle principale ; Pas possible de mettre un RET

    ; JP NZ,NEXT ; déplacement interdit retourne dans la boucle principale ; Pas possible de mettre un RET

; Décale le sprite du joueur d'une colonne vers la droite
DROITE
    LD HL,(VAISPOS) ; 985 ; adresse mémoire de la prochaine ligne de la map du sprite à l'écran
    LD (SAVECRJOU),HL ; pour conserver l'adresse mémoire de la prochaine ligne de la map du sprite à l'écran
    PUSH HL
    LD IX,(VAISDATA)
    LD B,0
    LD C,(IX) ; largeur

    LD HL,SPRJOU ; 16004
    LD (SAVJOU),HL ; pour conserver l'adresse mémoire de la ligne du sprite en cours de contrôle 16004 puis 16008

    LD A,0
    LD (NBSPAC),A ; pour conserver le nombre de lignes du sprite ayant 32 à droite

    LD A,(HAUT) ; Charge dans le compteur le nb de lignes du sprite
    LD (CPTLIG),A

    DEC HL ; 16004
NEXTDROITE
    ; vérifie combien de colonnes a droite du sprite du joueur sont des espaces
    ADD HL,BC ; largeur 4
    LD A,(HL) ; (16007) = 32 puis (16011) = 32

    CP 32
    JP NZ,NXTRIGHT 
    LD A,(NBSPAC)
    INC A
    LD (NBSPAC),A ; incrémente le nombre de lignes du sprite dont la valeur est 32 à droite

    ; Sort si c'était la dernière ligne du sprite
    LD A,(CPTLIG) ; hauteur
    DEC A
    JP Z,NEXTDROITE2 ; dernière ligne du sprite passe au prochain contrôle

    LD (CPTLIG),A ; enregistre le nombre de lignes du sprite du joueur restant à controler

    JP NZ,NEXTDROITE

NEXTDROITE2 ; si que des espaces...
    LD A,(NBSPAC)
    LD IX,HAUT
    SUB (IX)
    CP 0
    JP NZ,EXRIGHT2

    ; ...contrôle si au moins un espace chevauche déjà la map à droite
    LD A,(HAUT)
    LD (NBSPAC),A ; utilise NBSPAC pour compter le nombre de chevauchements, si 0 direction droite autorisée en mode 31

    LD HL,MAPLINE1 ; 16012
    LD HL,(VAISPOS) ; 985
    LD DE,981 ; position de la map en dur pour les tests
    SBC HL,DE ; HL contient l'écart entre le début de la ligne de map et la position du vaisseau à l'écran (4)
    PUSH HL
    LD DE,MAPLINE1 ; 16012
    PUSH DE
    LD IX,(VAISDATA)

NEXTDROITE3
    ADC HL,DE ; 16016 puis 16031
    LD B,0
    LD C,(IX) ; largeur du sprite du joueur (4)
    ADD HL,BC ; 16020 puis 16035
    LD A,(HL)
    CP 32
    JP Z,NEXTDROITE4

    POP DE ; 16012
    POP HL ; 4
    LD BC,COLREAL ; 15
    EX DE,HL ; 16012<->4
    ADD HL,BC ; 16027 => MAPLINE2
    LD A,(NBSPAC)
    DEC A
    LD (NBSPAC),A
    CP 0
    JP NZ,NEXTDROITE3

NEXTDROITE4
    CP 0 ; si 0 alors cas particulier ou toutes les colonnes du sprite du joueur on un espace à droite, il ne faut pas écraser la colonne de la map
    JP NZ,NEXT2

    LD A,31 ; 31 => déplacement autorisé à droite MAIS sans écraser la colonne de la map
    LD (SHWPLAY),A

    LD HL,(VAISPOS)
    INC HL
    LD (VAISPOS),HL ; enregistre la nouvelle position du sprite du joueur
    JP NEXT2

; Gère la fonction du tir du sprite du joueur
TIR
    JP NEXT3 ; Pas possible de mettre un RET

; Fonction permettant d'afficher un sprite à l'écran
DISSPRIT
    LD D,(IX+5)
    LD E,(IX+4) ; DE adresse position du sprite sur l'écran
NXTLINE
    LD B,0
    LD C,(IX+0) ; largeur (4)

    LD A,(SHWPLAY)
    CP 3 ; vrai si décalage à droite
    JP NZ,DISPLINE ; si faux

TORIGHT
    ; TODO : la condition n'est sans doute pas bonne dans tous les cas, il faut comparer par rapport aux données de la map
    ; Vérifie que le sprite n'est pas déjà dans le cas ou sa ligne est à 32 sur son coté gauche, qu'il chevauche déjà la map et que la direction est à droite
    LD A,(HL)
    CP 32
    CALL Z,NODELEFT ; c'est le cas, il ne faut donc pas effacer le caractère à gauche car c'est un caractère de la map

    EX DE,HL ; premiere ligne ok DE = 983 deuxieme ligne ok DE = 1047
    LD (HL),32
    EX DE,HL
    INC DE

DISPLINE
   ; LD A,(SHWPLAY)
   ; CP 2 ; vrai si décalage à gauche normal ; TODO : si Décalage à gauche de type 21 que fait t'on ?
   ; JP NZ, DISPLINE2 ; faux

    LD A,(DE)
    CP 32
    ; Vérifie que le sprite n'est pas déjà dans le cas ou sa ligne est à 32 sur son coté gauche, qu'il chevauche déjà la map et que la direction est à gauche    
    CALL NZ,NODELEFT ; c'est le cas, il ne faut donc pas effacer le caractère à gauche car c'est un caractère de la map

    ; Vérifie que le sprite n'est pas déjà dans le cas ou sa ligne est à 32 sur son coté droit, qu'il chevauche déjà la map et que la direction est à gauche
    EX DE,HL
    PUSH HL
    ADD HL,BC
    DEC HL
    LD A,(HL)
    POP HL
    EX DE,HL
    CP 32
    CALL NZ,NODERIGHT ; c'est le cas, il ne faut donc pas effacer le caractère à droite car c'est un caractère de la map

DISPLINE2
    ; vérifie si la colonne de droite du sprite du joueur est un espace
  ;  ADD HL,BC ; ajoute la largeur du sprite du joueur
  ;  DEC HL
  ;  LD A,(HL) ; (SPRJOU)
  ;  CP 32
  ;  JP NZ,NXTRIGHT ; ce n'est pas le cas
    ; vérifie maintenant si l'espace du sprite du joueur est sur un bloc de la map
  ;  PUSH HL
  ;  EX DE,HL ; HL = VAISPOS
  ;  ADD HL,BC
  ;  DEC HL
  ;  LD A,(HL)
;    CP 32
;    CALL NZ,NODERIGHT ; c'est le cas on n'écrase pas la map 

    LDIR ; (DE) <- (HL) BC-- ; affiche la ligne courante du sprite

    ; Test si décalage normal du sprite du joueur à gauche
    LD A,(SHWPLAY)
    CP 2
    JP NZ,NXTLINE2

TOLEFT 
    ; TODO : la condition n'est sans doute pas bonne dans tous les cas, il faut comparer par rapport aux données de la map
    ; Vérifie que le sprite n'est pas déjà dans le cas ou sa ligne est à 32 sur son coté droit, qu'il chevauche déjà la map et que la direction est à gauche
    ;LD A,(HL)
    ;CP 32
    ;CALL Z,NODERIGHT ; c'est le cas, il ne faut donc pas effacer le caractère à gauche car c'est un caractère de la map

    ; Vérifie que le sprite n'est pas déjà dans le cas ou sa ligne est à 32 sur son coté droit, qu'il chevauche déjà la map et que la direction est à gauche
    ;PUSH HL
    DEC HL
    LD A,(HL)
    INC HL
    CP 32
    JP Z,NXTLINE2

    ;supprime le caractère de droite de la ligne du sprite du joueur sur l'écran
    EX DE,HL
    LD (HL),32
    EX DE,HL

NXTLINE2
    ; Sort si c'était la dernière ligne du sprite
    LD A,(CPTLIG) ; hauteur
    DEC A
    JP Z,EXLINE ; sort de la function
    LD (CPTLIG),A

    ; Calcul écran ligne suivante pour DE (nb de colonnes - largeur du sprite)
    EX DE,HL
    LD BC,COLVIRT
    ADD HL,BC

    LD B,0
    LD C,(IX+0) ; largeur
    SBC HL,BC

    ;Cas particulier du décalage à droite
    LD A,(SHWPLAY)
    CP 3
    JP NZ,NXTLINE3
    DEC HL

NXTLINE3
    EX DE,HL

    JP NXTLINE
EXLINE
    ; Enregistre la nouvelle position du sprite
    LD HL,(VAISPOS) ; 983 (A)
    LD A,(SHWPLAY)
    ;CP 2
    ;JP NZ,UPDRIGHT
    ;DEC HL ; Si déplacement à gauche

    CP 3 ; déplacement à droite
    JP NZ,UPDEND
    INC HL ; Si déplacement à droite

UPDEND
    LD (VAISPOS),HL
    LD A,0
    LD (SHWPLAY),A

    RET

DRAWMAP ; affiche la map depuis la mémoire sur l'écran
    ; Test placement de la map en mémoire sur l'écran - simulation sur 2 lignes
    ; ligne 1
    LD DE,981
    LD BC,COLREAL
    LDIR ;(DE) <- (HL) BC--  (981 / 03D7) <- (16024 / 3E98) affiche la ligne courante du sprite

    EX DE,HL
    LD BC,COLDIFF
    ADD HL,BC ; calcule l'adresse écran de la ligne suivante
    EX DE,HL

    ; ligne 2
    LD BC,COLREAL
    LDIR
    ;:Fin du test
    RET

; le caractère du joueur est un espace mais le caractère de la ligne de la map à gauche n'en est pas un, il ne faut donc pas effacer le caractère de la map et passer au caractère suivant à afficher
NODELEFT
    INC HL
    INC DE
    DEC BC
    RET

; le caractère du joueur est un espace mais le caractère de la ligne de la map à droite n'en est pas un, il ne faut donc pas effacer le caractère de la map et passer au caractère suivant à afficher
NODERIGHT
   DEC BC
    RET


FIN
    POP IY
    POP IX
    END
