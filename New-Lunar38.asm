   ORG 15995 ; pointeur d'adresse pour charger le code du jeux

COLVIRT EQU 20 ; Ligne suivante de l'écran (le nombre de colonnes réelles est < nombre de colonnes maxi (ex : 40 colonnes à l'écran mais 64 pour passer à la ligne suivante)

COLREAL EQU 15 ; Nombre de colonnes visibles à l'écran

COLDIFF EQU 5 ; différence entre COLVIRT et COLREAL

; Pour test crée le sprite en mémoire (A ajouter dans les DATA du basic)
LARGE DEFB 4 ; largeur du sprite du joueur

HAUT DEFB 2 ; hauteur du sprite du joueur

VAISDATA DEFW 15995 ; adresse mémoire datas du sprite du joueur (3E7B)

VAISPOS DEFW 983 ; position de départ du sprite du joueur sur l'écran (15999 / 03D7)

MAPHAUT DEFB 2 ; nombre de lignes de la map à afficher sur l'écran

MAPPOS DEFW 981 ; Position de départ de la map à l'écran

; SPRJOU DEFM "ABCD FGH" ; Exemple de dessin sprite du joueur en mémoire (3E81) => Cas 1 OK

SPRJOU DEFM " BC  FG " ; Exemple de dessin sprite du joueur en mémoire (3E81)

; Fin du test
; Version DATA du BASIC
; DATA 07,03,123,62,215,3,65,66,67,68,...

; Test pour map en mémoire
MAPLINE1 DEFM "X       U     X"

MAPLINE2 DEFM "Y       Z     Y"

;MAPDATA DEFS 500 ; 500 emplacements mémoire pour stockage datas de la map plus tard a augmenter + tard / pour l'instant la map est créée en mémoire par MAPLINE1 et MAPLINE2
; Fin du test

SAVJOU DEFW 0 ; permet de tester le contenu de la ligne suivante du sprite

NBSPAC DEFW 0 ; permet de compter le nombre de lignes du sprite contenant un espace sur un coté en fonction du sens de déplacement demandé

CPTLIG DEFB 0 ; permet de décrémenter le nb de lignes affichées pour un sprite

CPTMAP DEFB 0 ; permet de décrémenter le nb de lignes affichées pour la map

SHWPLAY DEFB 1 ; permet de détecter si le sprite du joueur doit être réaffiché à l'écran
; 1 => affiche à la position de démarrage
; 2 => décale d'une position à gauche
; 3 => décale d'une position à droite
; 4 => décale d'une position en haut @TODO
; 5 => décale d'une position en bas @TODO
; 21 => décale d'une position à gauche avec chevauchement sur la map
; 31 => décale d'une position à droite avec chevauchement sur la map

LEFTSPACES DEFB 0 ; indique si la colonne de gauche du sprite du joueur ne contient que des espaces et chevauche la map à gauche

RIGHTSPACES DEFB 0 ; indique si la colonne de droite du sprite du joueur ne contient que des espaces et chevauche la map à droite

BEGIN
    PUSH IX
    PUSH IY

; Initialisation des paramètres
    LD HL,985 ; position de départ du joueur sur la mémoire écran
    LD (VAISPOS),HL
    LD A,0
    LD (LEFTSPACES),A
    LD (RIGHTSPACES),A

BOUCLE ; Boucle principale du moteur
;    LD E,01 ;
;    RST 20h ; DEFB 31H

    ; Dessine la map à l'écran TODO : gérer le décalage horizontal ou vertical de la map
    LD IX,(VAISDATA)
    LD A,(MAPHAUT) ; Charge dans le compteur le nb de lignes a afficher de la map

    LD HL,MAPLINE1 ; Charge HL et IX avec l'@ de début des données de la map
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

SUITE ; Fin de la boucle principale du moteur
    JP BOUCLE

; TODO : étudier le regroupement du code similaire de GAUCHE et DROITE

GAUCHE ; Décale le sprite du joueur d'une colonne vers la gauche
    LD A,(LEFTSPACES)
    CP 21
    JP Z,NEXT2 ; la colonne de gauche du sprite contient uniquement des espaces et le sprite chevauche déjà la map à gauche, déplacement interdit

    LD HL,(VAISPOS) ; 985 ; adresse mémoire de la prochaine ligne de la map du sprite à l'écran
    PUSH HL
    LD IX,(VAISDATA)
    LD B,0
    LD C,(IX) ; largeur

    LD HL,SPRJOU ; 16004
    LD (SAVJOU),HL ; pour conserver l'adresse mémoire de la ligne du sprite en cours de contrôle 16004 puis 16008

    LD A,0
    LD (NBSPAC),A ; pour conserver le nombre de lignes du sprite ayant 32 à gauche

    LD A,(HAUT) ; Charge dans le compteur le nb de lignes du sprite
    LD (CPTLIG),A

    ;DEC HL ; 16004
NEXTGAUCHE ; vérifie combien de colonnes a gauche du sprite du joueur sont des espaces
    LD A,(HL) ; (16004) = 32 puis (16008) = 32
    ADD HL,BC ; largeur 4

    CP 32
    JP NZ,NEXTGAUCHE5
    LD A,(NBSPAC)
    INC A
    LD (NBSPAC),A ; incrémente le nombre de lignes du sprite dont la valeur est 32 à gauche

    ; Sort si c'était la dernière ligne du sprite
    LD A,(CPTLIG) ; hauteur
    DEC A
    JP Z,NEXTGAUCHE2 ; dernière ligne du sprite passe au prochain contrôle

    LD (CPTLIG),A ; enregistre le nombre de lignes du sprite du joueur restant à controler

    JP NZ,NEXTGAUCHE

NEXTGAUCHE2 ; si colonne de gauche du sprite du joueur n'a que des espaces...
    LD A,(NBSPAC)
    LD IX,HAUT
    SUB (IX)
    CP 0
    JP NZ,NEXTGAUCHE5 ; pas que des espaces

    ; ...contrôle si au moins un espace chevauche déjà la map à gauche
    LD A,(HAUT)
    LD (NBSPAC),A ; utilise NBSPAC pour compter le nombre de chevauchements, si 0 direction gauche autorisée en mode 21

    LD HL,(VAISPOS) ; 985
    LD DE,981 ; position de la map en dur pour les tests
    SBC HL,DE ; HL contient l'écart entre le début de la ligne de map et la position du vaisseau à l'écran (4)
    PUSH HL
    LD DE,MAPLINE1 ; 16012
    PUSH DE
    LD IX,(VAISDATA)

NEXTGAUCHE3 ; calcule les données pour la ligne suivante du sprite
    ADD HL,DE ; 16016 puis 16031
    DEC HL ; 16015 puis 16030
    LD A,(HL)
    CP 32
    JP NZ,NEXTGAUCHE4 ; au moins une colonne de la map non vide

    POP DE ; 16012
    POP HL ; 4
    LD BC,COLREAL ; 15
    EX DE,HL ; 16012<->4
    ADD HL,BC ; 16027 => MAPLINE2
    LD A,(NBSPAC)
    DEC A
    LD (NBSPAC),A
    CP 0
    JP NZ,NEXTGAUCHE3

NEXTGAUCHE4
    CP 0 ; si <> 0 toutes les colonnes de la map ne sont pas vides (32) il ne faut pas écraser la colonne de la map
    LD A,0
    LD (RIGHTSPACES),A ; désactive le flag de chevauchement à droite
    LD A,2 ; déplacement autorisé à gauche
    LD (SHWPLAY),A
    JP Z,NEXT

    LD A,21 ; 21 => déplacement autorisé à gauche MAIS sans écraser la colonne de la map
    LD (SHWPLAY),A

    JP NEXT

NEXTGAUCHE5 ; vérifie que la map est libre à gauche en mémoire écran
    LD A,(HAUT)
    LD (NBSPAC), A

    LD HL,(VAISPOS) ; 985
    DEC HL ; 984
    LD BC,COLVIRT ; 20

NEXTGAUCHE7
    LD A,(HL)
    CP 32
    JP NZ NEXTGAUCHE8
    LD A,(NBSPAC)
    DEC A
    LD (NBSPAC),A
    ADD HL,BC ; 1004
    CP 0
    JP Z,NEXTGAUCHE8
    JP NEXTGAUCHE7

NEXTGAUCHE8
    LD A,(NBSPAC)
    CP 0
    JP NZ,NEXT
    
    LD A,2 ; 2 => déplacement autorisé à gauche
    LD (SHWPLAY),A
    LD A,0
    LD (RIGHTSPACES),A ; désactive le flag de chevauchement à droite

    JP NEXT

DROITE ; Décale le sprite du joueur d'une colonne vers la droite
    LD A,(RIGHTSPACES)
    CP 31
    JP Z,NEXT2 ; la colonne de droite du sprite contient uniquement des espaces et le sprite chevauche déjà la map à droite, déplacement interdit

    LD HL,(VAISPOS) ; 985 ; adresse mémoire de la prochaine ligne de la map du sprite à l'écran
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
NEXTDROITE ; vérifie combien de colonnes a droite du sprite du joueur sont des espaces
    ADD HL,BC ; largeur 4
    LD A,(HL) ; (16007) = 32 puis (16011) = 32

    CP 32
    JP NZ,NEXTDROITE5 ; la colonne testée n'est pas un espace

    LD A,(NBSPAC)
    INC A
    LD (NBSPAC),A ; incrémente le nombre de lignes du sprite dont la valeur est 32 à droite

    ; Sort si c'était la dernière ligne du sprite
    LD A,(CPTLIG) ; hauteur
    DEC A
    JP Z,NEXTDROITE2 ; dernière ligne du sprite passe au prochain contrôle

    LD (CPTLIG),A ; enregistre le nombre de lignes du sprite du joueur restant à controler

    JP NZ,NEXTDROITE

NEXTDROITE2 ; si colonne de droite du sprite du joueur n'a que des espaces...
    LD A,(NBSPAC)
    LD IX,HAUT
    SUB (IX)
    CP 0
    JP NZ,NEXTDROITE5 ; pas que des espaces

    ; ...contrôle si au moins un espace chevauche déjà la map à droite
    LD A,(HAUT)
    LD (NBSPAC),A ; utilise NBSPAC pour compter le nombre de chevauchements, si 0 direction droite autorisée en mode 31

    LD HL,(VAISPOS) ; 985
    LD DE,981 ; position de la map en dur pour les tests
    SBC HL,DE ; HL contient l'écart entre le début de la ligne de map et la position du vaisseau à l'écran (4)
    PUSH HL
    LD DE,MAPLINE1 ; 16012
    PUSH DE
    LD IX,(VAISDATA)

NEXTDROITE3 ; calcule les données pour la ligne suivante du sprite
    ADD HL,DE ; 16016 puis 16031
    LD B,0
    LD C,(IX) ; largeur du sprite du joueur (4)
    ADD HL,BC ; 16020 puis 16035
    LD A,(HL)
    CP 32
    JP NZ,NEXTDROITE4

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
    CP 0 ; si > 0 toutes les colonnes de la map ne sont pas vides (32) il ne faut pas écraser la colonne de la map
    LD A,0
    LD (LEFTSPACES),A ; désactive le flag de chevauchement à gauche
    LD A,3
    LD (SHWPLAY),A
    JP Z,NEXT2

    LD A,31 ; 31 => déplacement autorisé à droite MAIS sans écraser la colonne de la map
    LD (SHWPLAY),A
    LD (RIGHTSPACES),A

    JP NEXT2

NEXTDROITE5 ; vérifie que la map est libre à droite en mémoire écran
    LD A,(HAUT)
    LD (NBSPAC), A

    LD HL,(VAISPOS) ; 985
    LD B,0
    LD C,(IX) ; 4
    ADD HL,BC ; 989
    LD BC,COLVIRT ; 20

NEXTDROITE7
    LD A,(HL)
    CP 32
    JP NZ NEXTDROITE8
    LD A,(NBSPAC)
    DEC A
    LD (NBSPAC),A
    ADD HL,BC ; 1009
    CP 0
    JP Z,NEXTDROITE8
    JP NEXTDROITE7

NEXTDROITE8
    LD A,(NBSPAC)
    CP 0
    JP NZ,NEXT2

    LD A,3 ; 3 => déplacement autorisé à droite
    LD (SHWPLAY),A

    LD A,0
    LD (LEFTSPACES),A ; désactive le flag de chevauchement à gauche
    JP NEXT2

TIR ; Gère la fonction du tir du sprite du joueur
    JP NEXT3 ; Pas possible de mettre un RET

DISSPRIT ; Fonction permettant d'afficher un sprite à l'écran
    LD DE,(VAISPOS) ; DE adresse position du sprite sur l'écran avant son déplacement
NXTLINE
    LD B,0
    LD C,(IX+0) ; largeur (4)

    LD A,(SHWPLAY)
    CP 3 ; vrai si décalage à droite
    JP Z,DISRIGHT 

    CP 31 ; vrai si décalage à droite avec chevauchement
    JP Z,DISRIGHT

    CP 2 ; vrai si décalage à gauche
    JP Z,DISLEFT

    CP 21 ; vrai si décalagé à gauche avec chevauchement
    JP Z,DISLEFT

    JP DISPLINE ; redessine le sprite sans changement de position ; TODO amélioration en détectant son emplacement dans DRAWMAP pour ne plus le redessiner

DISRIGHT
    INC DE
    ; Enregistre la nouvelle position du sprite
    LD (VAISPOS),DE
    JP DISPLINE

DISLEFT
    DEC DE
    LD (VAISPOS),DE
    
DISPLINE
    CP 21
    JP NZ,DISPLINE3
    INC HL
    INC DE
    DEC BC

DISPLINE3
    CP 31
    JP NZ,DISPLINE2
    DEC BC
    JP DISPLINE4

DISPLINE2 ; cas ou aucune direction mais le sprite du joueur chevauche déjà la map à droite, il ne faut pas effacer la colonne droite de la map
    LD A,(RIGHTSPACES)
    CP 31
    JP NZ,DISPLINE5
    DEC BC
    JP DISPLINE4

DISPLINE5 ; cas ou aucune direction mais le sprite du joueur chevauche déjà la map à gauche, il ne faut pas effacer la colonne gauche de la map
    LD A,(LEFTSPACES)
    CP 21
    JP NZ,DISPLINE4

    INC HL
    INC DE
    DEC BC 

DISPLINE4 ; affiche une ligne de sprite
    LDIR ; (DE) <- (HL) BC-- ; affiche la ligne courante du sprite

NXTLINE2
    LD A,(SHWPLAY)
    CP 21
    JP NZ NXTLINE5
    LD (LEFTSPACES),A ; conserve l'information que la colonne de gauche du sprite du joueur à des espaces et que le sprite chevauche déjà la map

NXTLINE5 ; Sort si c'était la dernière ligne du sprite sinon calcule les données nécessaires pour affichage de la prochaine ligne du sprite
    LD A,(CPTLIG) ; hauteur
    DEC A
    JP Z,UPDEND ; sort de la function
    LD (CPTLIG),A

    ; Calcul écran ligne suivante pour DE (nb de colonnes - largeur du sprite)
    EX DE,HL
    LD BC,COLVIRT
    ADD HL,BC

    LD B,0
    LD C,(IX+0) ; largeur
    SBC HL,BC ; HL =1005 BC=16007
    EX DE,HL

    ;Cas particulier du décalage à droite sans écraser la map à droite
    LD A,(SHWPLAY)
    CP 31
    JP NZ,NXTLINE4

    INC HL
    INC DE
    DEC BC
    JP DISPLINE4

NXTLINE4 ; cas ou aucune direction mais le sprite du joueur chevauche déjà la map à droite, il ne faut pas effacer la colonne droite de la map
    LD A,(RIGHTSPACES)
    CP 31
    JP NZ,DISPLINE6
    INC HL
    INC DE
    DEC BC
    JP DISPLINE4

DISPLINE6 ; cas ou aucune direction mais le sprite du joueur chevauche déjà la map à gauche, il ne faut pas effacer la colonne gauche de la map
    LD A,(LEFTSPACES)
    CP 21
    JP NZ,DISPLINE4
    INC HL
    INC DE
    DEC BC
    JP DISPLINE4

NXTLINE3
    EX DE,HL
    LD A,(SHWPLAY)
    CP 21
    JP Z,DISPLINE

    JP DISPLINE4

UPDEND
    LD A,0
    LD (SHWPLAY),A

    RET

DRAWMAP ; affiche la map depuis la mémoire sur l'écran
    ; Test placement de la map en mémoire sur l'écran - simulation sur 2 lignes
    ; ligne 1
    LD DE,(MAPPOS)

    LD BC,COLREAL
    LDIR ;(DE) <- (HL) BC--

    EX DE,HL
    LD BC,COLDIFF
    ADD HL,BC ; calcule l'adresse écran de la ligne suivante
    EX DE,HL

    ; ligne 2
    LD BC,COLREAL
    LDIR
    ;:Fin du test
    RET

FIN
    POP IY
    POP IX
    END
