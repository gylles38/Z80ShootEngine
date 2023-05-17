   ORG 15995 ; pointeur d'adresse pour charger les données du jeux (sprites)
; Pour test crée le sprite en mémoire (A ajouter dans les DATA du basic)
LARGE DEFB 4 ; largeur du sprite du joueur
HAUT DEFB 2 ; hauteur du sprite du joueur
VAISAD DEFW 15995 ; adresse mémoire datas du sprite du joueur (3E7BH)
VAISPOS DEFW 983 ; position de départ du sprite du joueur sur l'écran (15999 / 03D7H)
MAPHAUT DEFB 2 ; nombre de lignes de la map à afficher sur l'écran
MAPPOS DEFW 981 ;
SPRJOU DEFM " BCDEFGH" ; Exemple de dessin sprite du joueur (3E81H)

; Fin du test
; Version DATA du BASIC
; DATA 07,03,123,62,215,3,65,66,67,68,...

; Test pour map en mémoire
MAPLINE1 DEFM "X             X" ; 3E8E
MAPLINE2 DEFM "Y             Y"
;MAPDATA DEFS 500 ; 500 emplacements mémoire pour stockage datas de la map plus tard a augmenter + tard / pour l'instant la map est créée en mémoire par MAPLINE1 et MAPLINE2
; Fin du test

COLVIRT EQU 20 ; Ligne suivante de l'écran (le nombre de colonnes réelles est < nombre de colonnes maxi (ex : 40 colonnes à l'écran mais 64 pour passer à la ligne suivante)
COLREAL EQU 15
COLDIFF EQU 5 ; différence entre COLVIRT et COLREAL

SAVJOU DEFW 0 ; permet de tester le contenu de la ligne suivante du sprite
CPTLIG DEFB 0 ; permet de décrémenter le nb de lignes affichées pour un sprite
CPTMAP DEFB 0 ; permet de décrémenter le nb de lignes affichées pour la map
SHWPLAY DEFB 1 ; permet de détecter si le sprite du joueur doit être réaffiché à l'écran
; 1 => affiche à la position de démarrage
; 2 => décale d'une position à gauche
; 3 => décale d'une position à droite
; 4 => décale d'une position en haut @TODO
; 5 => décale d'une position en bas @TODO

    PUSH IX
    PUSH IY

; Boucle principale du moteur
BOUCLE
;    LD E,01              ; 
;    RST 20h              ; DEFB 31H

    ; Dessine la map à l'écran TODO : gérer le décalage horizontal ou vertical de la map
    LD IX,(VAISAD)
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
    CP 77                ; Touche Tir (W)
    CALL Z,TIR           ; Charge l'@ mémoire initiale de la balle gauche et droite sur l'écran

    ; vérifie si le sprite du joueur doit être redessiné
    ;LD A,(SHWPLAY)
    ;CP 0 
    ;JP Z SUITE

    ; Dessine toujours le sprite du joueur à l'écran
    ;LD HL,(VAISAD) ; Charge HL et IX avec l'@ de début des données du sprite du joueur
    LD HL,SPRJOU
    LD IX,(VAISAD)
    LD A,(IX+1) ; Charge dans le compteur le nb de lignes du sprite
    LD (CPTLIG),A
    CALL DISSPRIT

SUITE
    JP BOUCLE

; TODO : étudier le regroupement du code similaire de GAUCHE et DROITE

; Décale le sprite du joueur d'une colonne vers la gauche
GAUCHE
    LD HL,SPRJOU ; pour conserver la ligne du sprite en cours de contrôle
    LD (SAVJOU),HL

    LD HL,(VAISPOS)
    PUSH HL
    DEC HL

    LD IX,(VAISAD)
    LD A,(IX+1) ; Charge dans le compteur le nb de lignes du sprite
    LD (CPTLIG),A

; teste si le décalage à gauche est autorisé
NXTLEFT
    LD A,(HL) ; charge le contenu de la map à cette adresse

    CP 32
    JP Z NXLEFT2 ; emplacement libre, passe à la ligne suivante

; Doit contrôler la valeur du contenu du sprite du joueur si 32 alors ok
DATLEFT
    LD HL,(SAVJOU)
    LD IX,LARGE ; LD IX,15995
    LD B,0
    LD C,(IX+0) ; (4 largeur d'une ligne sprite du joueur)
    ADD HL,BC
    LD A,(HL)
    CP 32
    JP NZ,EXLEFT2 ; déplacement interdit

NXLEFT2
    ; Sort si c'était la dernière ligne du sprite
    LD A,(CPTLIG) ; hauteur
    DEC A
    JP Z,EXLEFT ; dernière ligne du sprite et déplacement autorisé

    LD (CPTLIG),A

    LD BC,COLVIRT ; (20)
    ADD HL,BC ; Pour le test en cours : 1046 (Avant l'espace du H à la 2eme ligne du sprite du joueur)
   ; DEC HL ;

    JP NXTLEFT

EXLEFT
    ; signale le décalage de l'affichage du sprite du joueur à gauche
    LD A,2
    LD (SHWPLAY),A
    POP HL

EXLEFT2
    LD A,(SHWPLAY)
    CP 2
    JP NZ,NEXT ; déplacement interdit ; Pas possible de mettre un RET
    DEC HL
    LD (VAISPOS),HL ; enregistre la nouvelle position du sprite du joueur
    JP NEXT ; Pas possible de mettre un RET

; Décale le sprite du joueur d'une colonne vers la droite
DROITE
    LD HL,(VAISPOS) ; 983 (A)
    PUSH HL ; sauvegarde @ mémoire du sprite du joueur (15995 / 3E7BH)
    
    LD B,0
    LD C,(IX+0) ; largeur
    ADD HL,BC ; 990 (Après le G)

    ; teste si le décalage à droite est autorisé
    LD A,(HL)
    POP HL ; récupère la sauvegarde de la position actuelle
    ; Vérifie si la position est libre
    CP 32
    RET NZ

    LD (VAISPOS),HL
    ; signale le décalage de l'affichage du sprite du joueur à droite
    LD A,3
    LD (SHWPLAY),A
    RET

; Gère la fonction du tir du sprite du joueur
TIR
    RET

; Fonction permettant d'afficher un sprite à l'écran
DISSPRIT
    ;LD BC,6
    ;ADD HL,BC ; (16001 / 3E81H) dessin du sprite
    LD D,(IX+5)
    LD E,(IX+4) ; DE adresse position du sprite sur l'écran
NXTLINE
    LD B,0
    LD C,(IX+0) ; largeur (7)

    LD A,(SHWPLAY)
    CP 3 ; vrai si décalage à droite
    JP NZ,DISPLINE ; si faux
TORIGHT
    EX DE,HL ; premiere ligne ok DE = 983 deuxieme ligne ko DE = 1048 au lieu de 1047
    LD (HL),32
    EX DE,HL
    INC DE

DISPLINE
    LD A,(DE)
    CP 32
    CALL NZ,NODELEFT
    LDIR ; (DE) <- (HL) BC--  (983 / 03D7H) <- (16001 / 3E81H) affiche la ligne courante du sprite

    ; Test si décalage du sprite du joueur à gauche
    LD A,(SHWPLAY)
    CP 2
    JP NZ,NXTLINE2
TOLEFT ;supprime le caractère de droite de la ligne du sprite du joueur sur l'écran
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
    ; ligne
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

;;;;;;;;;;;;;
NODELEFT ; le caractère du joueur est un espace mais le caractère de la ligne de la map à gauche n'en est pas un, il ne faut donc pas effacer le caractère de la map et passer au caractère suivant à afficher
    INC HL
    INC DE
    DEC BC
    RET
;;;;;;;;;;;;;;
FIN
    POP IY
    POP IX
    END
 
