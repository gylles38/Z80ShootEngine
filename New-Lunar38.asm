   ORG 15995 ; pointeur d'adresse pour charger les données du jeux (sprites)
; Pour test crée le sprite en mémoire (A ajouter dans les DATA du basic)
LARGE DEFB 7
HAUT DEFB 3
VAISAD DEFW 15995 ; adresse mémoire datas du sprite du joueur (3E7BH)
VAISPOS DEFW 983 ; position du sprite du joueur sur l'écran (15999 / 03D7H)
; CHAINE DEFM "ABCDEFGHIJKLMNOPQRSTU" ; Dessin sprite du joueur (3E81H)
CHAINE DEFM "ABCDEFG HIJKL MN PQR " ; Dessin sprite du joueur (3E81H)

; Fin du test
; Version DATA du BASIC
; DATA 07,03,123,62,215,3,65,66,67,68,...

; Test pour map
MAPL DEFW 981
MAPR DEFW 995
MAPL2 DEFW 1046 ; (bloc sur la 2eme ligne a gauche du sprite 1 déplacement à gauche possible)
MAPR2 DEFW 1054 ; (bloc sur la 2eme ligne a droite du sprite 1 déplacement à droite possible)
MAPSTR DEFM "                                                                "
; Fin du test

COLUMNS EQU 64 ; Ligne suivante de l'écran
CPTLIG DEFB 0 ; permet de décrémenter le nb de lignes affichées pour un sprite
SHWPLAY DEFB 1 ; permet de détecter si le sprite du joueur doit être réaffiché à l'écran
; 1 => affiche à la position de démarrage
; 2 => décale d'une position à gauche
; 3 => décale d'une position à droite
; 4 => décale d'une position en haut @TODO
; 5 => décale d'une position en bas @TODO

    PUSH IX
    PUSH IY

    ; Test chargement de la map
    LD HL,MAPSTR
    LD DE,962
    LD BC,COLUMNS
    LDIR

    LD HL,MAPSTR
    LD DE,1037
    LD BC,COLUMNS
    LDIR

    LD IX,(MAPL)
    LD (IX),255
    LD IX,(MAPR)
    LD (IX),255

    LD IX,(MAPL2)
    LD (IX),255
    LD IX,(MAPR2)
    LD (IX),255
    ;:Fin du test

BOUCLE
;    LD E,01              ; 
;    RST 20h              ; DEFB 31H
    CP 8                 ; 
    CALL Z,GAUCHE        ; 
    CP 26                ; 
    CALL Z,DROITE        ; 
    CP 77                ; Touche Tir (W)
    CALL Z,TIR           ; Charge l'@ mémoire initiale de la balle gauche et droite sur l'écran

    ; vérifie si le sprite du joueur doit être redessiné
    LD A,(SHWPLAY)
    CP 0 
    JP Z SUITE

    ; Dessine le sprite du joueur à l'écran
    LD HL,(VAISAD) ; Charge HL et DE avec l'@ de début des données du sprite du joueur (largeur)
    LD IX,(VAISAD)
    LD A,(IX+1) ; Charge dans le compteur le nb de lignes du sprite
    LD (CPTLIG),A
    CALL DISSPRIT

SUITE
    JP BOUCLE

; TODO : étudier le regroupement du code similaire de GAUCHE et DROITE

; Décale le sprite du joueur d'une colonne vers la gauche
GAUCHE
    LD HL,(VAISPOS)
    DEC HL

    ; teste si le décalage à gauche est autorisé
    LD A,(HL)
    ; Vérifie si la position est libre
    CP 32
    RET NZ

    LD (VAISPOS),HL
    ; signale le décalage de l'affichage du sprite du joueur à gauche
    LD A,2
    LD (SHWPLAY),A

    RET

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
    LD BC,6
    ADD HL,BC ; (16001 / 3E81H) dessin du sprite
    LD D,(IX+5)
    LD E,(IX+4) ; DE adresse position du sprite sur l'écran
NXTLINE
    LD B,0
    LD C,(IX+0) ; largeur (7)

    LD A,(SHWPLAY)
    CP 3
    JP NZ,DISPLINE
TORIGHT
    EX DE,HL ; premiere ligne ok DE = 983 deuxieme ligne ko DE = 1048 au lieu de 1047
    LD (HL),32
    EX DE,HL
    INC DE

DISPLINE
    LDIR ; (DE) <- (HL) BC--  (983 / 03D7H) <- (16001 / 3E81H) affiche la ligne courante du sprite

    ; Test si décalage du sprite du joueur à gauche
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
    LD BC,COLUMNS
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
FIN
    POP IY
    POP IX
    END
 
