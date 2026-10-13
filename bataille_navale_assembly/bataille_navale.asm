# ===== Section donnees =====
.data 
    grille:    .space 100 #Grille de char de 10x10 soit 100 octet
    affichage_fin:    .asciiz "Le nombre total de coups dans cette partie est de : "  # Chaine de caracteres affichee a la fin de chaque partie pour indiquer le nombre total de coups

# ===== Section code =====  
.text

# ----- Main ----- 
main:
    jal initPartie
    jal displayGrille
    jal simulationJeu
    j   exit 

# ----- Fonctions -----

# ----- Fonction initPartie -----
# Objectif : Génère une nouvelle partie à chaque appel
# Registres utilises : $a0, $a1

initPartie:
    add     $sp, $sp, -4        # Sauvegarde de la reference du dernier jump
    sw      $ra, 0($sp)

    jal initGrille
    li  $a0, 5
    li  $a1, 65 # 'A' pour Aircraft Carrier (Porte-Avion)
    jal setShip
    li  $a0, 4  
    li  $a1, 66 # 'B' pour Battleship (Cuirassé)
    jal setShip
    li  $a0, 3
    li  $a1, 67 # 'C' pour Cruiser (Croiseur)
    jal setShip
    li  $a0, 3
    li  $a1, 83 # 'S' pour Submarine (Sous-marin)
    jal setShip
    li  $a0, 2
    li  $a1, 68 # 'D' pour Destroyer (Torpilleur)
    jal setShip

    lw      $ra, 0($sp)                 # On recharge la reference 
    add     $sp, $sp, 4                 # du dernier jump
    jr $ra

# ----- Fonction initGrille -----
# Objectif : Charge la grille avec '.' (Case vide)
# Registres utilises : $t[0-3]

initGrille:
    la      $t0, grille     # Chargement de l'adresse de la grille
    li      $t1, 0          # Initialisation du compteur de boucle dans $t1
    li      $t3, 46         # Charge la valeur ASCII de '.'
    boucle_initGrille:
        bge     $t1, 100, end_initGrille # Si $t1 est plus grand ou egal a 100 alors branchement a end_boucle_initGrille
            add     $t2, $t0, $t1   # $t0 + $t1 -> $t2 ($t0 l'adresse du tableau et $t1 la position dans le tableau)
            sb		$t3, 0($t2)		# On place la valeur de $t3 à l'adresse contenue dans $t2
            addi    $t1, $t1, 1     # $t1 += 1 (On augemente le compteur)
            j boucle_initGrille
    end_initGrille:
        jr $ra

# ----- Fonction displayGrille -----
# Objectif : Affiche la grille avec les indicateur de coordonnées
# Registres utilises : $t[0-3], $v0, $a[0-1]

displayGrille:                                
    add     $sp, $sp, -4          # Sauvegarde de la reference du dernier jump
    sw      $ra, 0($sp)         # Sauvegarde de l adresse de retour sur la pile
    jal displayLettres        # Appel de la fonction pour afficher l'entete des colonnes
    la      $t0, grille         #Charge l'adresse de la grille dans $t0
    li      $t1, 0           #Initialisation du compteur de boucle dans $t1
    
    boucle_displayGrille:      
        bge     $t1, 100, end_displayGrille     # Si $t1 est plus grand ou egal a 100 alors branchement a end_displayGrille
            move $a0,$t1                        # Copie le nombre de tours de boucles dans $a0
            jal addLineCount              # Gere le retour a la ligne si besoin + l affichage du numero de la ligne
            add     $t2, $t0, $t1           # $t0 + $t1 -> $t2 ($t0 l'adresse du tableau et $t1 la position dans le tableau)
            lb      $a0, ($t2)              # load byte at $t2(adress) in $a0
            li      $v0, 11                 # code pour l'affichage d'un caractere (char)
            syscall            
	    li $a0,32           # Charge le code ASCII correpondant a un espace dans $a0
	    syscall             # Affiche l espace
            addi    $t1, $t1, 1             # $t1 += 1;
        j boucle_displayGrille      
        
    end_displayGrille:              
        jal addNewLine     # saut de ligne
        jal addNewLine     # de meme
        jal addNewLine
        #les 3 sauts de ligne sont pour s eparer les grilles pour une meilleure lisibilite au niveau de l affichage     
        lw $ra, 0($sp)                 # On recharge la reference 
        add $sp, $sp, 4                # du dernier jump
    jr $ra                          

# ----- Fonction displayLettres -----
# Objectif : afficher les lettres de A à J
# Regitres utilises : $t0, $v0, $a0

displayLettres:
    li $v0, 11       # Charge dans $v0 le code systeme 11 (affichage d un caractere)
    li $a0, 32       # Charge dans $a0 le code ASCII 32 correspondant a un espace
    syscall       # Affiche l espace
    syscall        # Affiche un second espace
    syscall          # Affiche un troisieme espace...
    # Ces espaces sont fait pour que l affichage de la ligne de lettres qui correpondent a chaque colonne de la grille soient bien alignes avec ces memes colonnes
    li $t0, 65       # initialise $t0 a 65, code ASCII de la lettre A

    boucleAffichage:
        move $a0, $t0       # Copie la lettre courante (code ASCII) dans $a0 pour l affichage
        li $v0, 11          # Charge le code systeme 11 pour pouvoir afficher le caractere
        syscall            # Affiche la lettre correspondante (pour l entete des colonnes)
        li $v0, 11          # Recharge le code systeme 11 pour afficher un caractere
        li $a0, 32          # Charge un espace dans $a0 pour separer les lettres
        syscall             # Affiche l espace apres la lettre
        addi $t0, $t0, 1                    # incremente $t0 pour passer a la lettre suivante
        ble $t0, 74, boucleAffichage        # Tant que $t0 est inferieur ou egal a 74 (code ASCII de J), on continue la boucle

    jr $ra     

# ----- Fonction addNewLine -----  
# Objectif : fait un retour a la ligne a l'ecran
# Registres utilises : $v0, $a0

addNewLine:
    li      $v0, 11         # Chargement appel systeme 11 (Affichage d'un char)
    li      $a0, 10         # Chargement chaine à afficher -> '\n'
    syscall
    jr      $ra             # Retour à la fonction précendente

# ----- Fonction addLineCount -----
# Objectif : affiche le numero de la ligne
# Registres utilises : $v0, $a0, $a1
# Paramètre : $a1 (Ligne en cours : res du modulo + 1)

addLineCount:
    addi $sp, $sp, -4        # reserve de l espace sur la pile pour sauvegarder l adresse de retour
    sw $ra, 0($sp)           # Sauvegarde de l adresse de retour dans la pile
    li $a1,10               # Charge 10 dans $a1 pour effectuer un modulo par 10, car $a1 est le diviseur dans getModulo
# $a0 nous vient de la fonction addLineCount => c'est le nombre de "tours de boucle" ou plutot l'index de la case à laquelle on se trouve, elle va etre utilisé par get modulo pour voir si divisé par dix le RESTE nous donne 0 ou autre chose
# Si c'est 0 alors c'est que la case à laquelle on est est un multiple de 10 et donc que la prochaine case est une nouvelle LIGNE !!!!
# sinon on n'a pas besoin de sauter de ligne, donc on n'a rien besoin de faire...
# le reste du modulo (ce qui nous intéresse est mis dans $v0) 
# le quotient est mis dans $v1

    jal getModulo            # Appelle la fonction modulo pour savoir si on change de ligne (si $a0 (= index de la case actuelle) mod 10 == 0, alors l'index $a0 correpond au debut d une nouvelle ligne de la grille => tableau de 100 cases avec 10 clonnes par ligne)
	
    bne $v0,0,fin_AddLine   # Si le reste du modulo est different de 0 alors on n affiche rien (fin_AddLine)
    jal addNewLine           # passe a la ligne suivante dans l affichage
    addi $v1,$v1,1           # Incremente le compteur de numero de ligne
    
#ici on passe de toute manière dans si_ligne10, simplement quand la ligne est vraiment la 10 eme on ne met pas d'espaces avant (on saute cette partie)
#donc tous les autres chiffres des lignes 1-9 ont un espace avant pour égaliser avec les 2 chiffres qui composent 10
# ATTENTION : juste avant on a incrémente $v1 avec 1 donc si on est à la ligne n°9 alors $v1 sera égal à 10 !

    beq $v1,10,si_ligne10    # Si on est a la ligne 10 on doit ajouter un espace par rapport aux autres chiffres = si_ligne_10
    li $a0,32                # charge le caractere espace dans $a0
    li $v0,11                # syscall pour afficher un caractere (char)
    syscall                  # Affiche un espace avant le numero de ligne
			
    si_ligne10:
        move $a0,$v1         # Place le numero de ligne dans $a0 pour l affichage
	li $v0,1             # code syscall pour afficher un entier
	syscall               # Affiche le numero de ligne
	li $a0,32             # Charge un espace apres le numero de ligne
	li $v0,11            # Code pour afficher un caractere
	syscall               # Affiche l espace apres le numero
	
    fin_AddLine:
        lw $ra, 0($sp)       # Recharge l adresse de retour depuis la pile
        addi $sp, $sp, 4     # Libere l espace utilise sur la pile
	jr $ra              

# ----- Fonction getModulo ----- 
# Objectif : Fait le modulo (a mod b)
#   $a0 represente le nombre a (doit etre positif)
#   $a1 represente le nombre b (doit etre positif)
# Resultat (reste) dans : $v0
# Resultat (quotient) dans : $v1
# Registres utilises : $a0 et $a1

getModulo: 
    li $v1, 0
    sub     $sp, $sp, 4
    sw      $ra, 0($sp)
    boucle_getModulo:
        blt $a0, $a1, end_getModulo
        addi $v1, $v1, 1
        sub $a0, $a0, $a1
        j boucle_getModulo
    end_getModulo:
    move    $v0, $a0
    lw      $ra, 0($sp)
    add     $sp, $sp, 4
    jr $ra

# ----- Fonction getAleatoire ----- 
# Objectif : Génère un nombre aléatoire de 0 à n-1
#   $a1 represente la valeur max-1
# Resultat dans : $a0
# Registres utilises : $a0, $a1, $v0

getAleatoire:
    li $v0, 42
    syscall
    jr $ra

# ----- Fontion setShip -----
# Objectif : place un bateau de taille donné.
#   $a0 represente la taille en nombre de case du bateau à placer
#   $a1 represente le caraètre pour représenter le bateau
# Registres utilises : $a0, $a1, $s[0-4], $t[0-4]

setShip:
    sub     $sp, $sp, 4
    sw      $ra, 0($sp)     #On sauvegarde l'adresse de retour

    move 	$s0, $a0		# On recopie la taille dans $s0
    move    $s4, $a1        # On recopie le caractere du bateau
    try_setShip:
        #Choix de l'axe (horizontale ou verticale)
        li      $a1, 2          # Définition de la borne surpérieur (Resultat possbile : 0 ou 1)
        jal getAleatoire        # Saut pour obtenir une valeur aléatoire
        move 	$s1, $a0		# On copie le résultat dans $s1
        # Placement en fonction de l'axe
        beq     $s1, 1, placeVerticale  # Si la valuer est 1 alors le bateau sera placer verticalement
        j       placeHorizontale        # Si la valuer est 0 alors le bateau sera placer horizontalement

    end_setShip:
        lw      $ra, 0($sp)
        add     $sp, $sp, 4     # On rétablie l'adresse de retour
    jr $ra
        
# ----- Fontion placeHorizontale -----
# Objectif : place aléatoirement un bateau de manière horizontale.
#   Prends les paramètres de setShip
# Registres utilises : $v0, $a0, $a1, $s[0-4], $t[0-4]

placeHorizontale:
    rechercheH:                    # Debut de la recherche d une position valide
        # ligne : 0-9
        li $a1, 10                 # definit la borne superieure pour le tirage aleatoire de la ligne ($a1 = valeur max-1 dans fonction getAleatoire)
        jal getAleatoire           # Definit un numreo de ligne aleatoire entre 0 et 9
        move $s2, $a0              # Stocke la ligne choisie dans $s2

        # colonne : 0-(10 - taille)
        li $a1, 10                 # Charge la largeur de la grille (10 colonnes)
        sub $a1, $a1, $s0          # Ajuste pour que le bateau (taille = $s0 donne par setship) ne depasse pas horizontalement (limite a ne pas depasser : les colonnes valides vont de 0 a $a1-1)
        jal getAleatoire          #  tire au sort une colonne aleatoire valide (getAleatoire renvoie un nbre entre 0 et $a1-1 dans $a0)
        move $s3, $a0              # Stocke la colonne choisie dans $s3 (colonne ou le bateau commencera horizontalement)

        # index = ligne*10 + colonne
        mul $t0, $s2, 10             # Calcule le decalage de la ligne dans la grille ($s2 = ligne ou le bateau sera place de 0 a 9 et on le multile par 10 pour que cela correponde a la case sans l'index de depart => $t0)
        add $a0, $t0, $s3            # Calcule l index de depart du bateau dans la grille ($s3 est la colonne ou la premiere lettre du bateau va etre pose, si on lui ajoute le decalage de ligne $t0 on a la case de depart du bateau)

        jal verifPlaceHorizontale  # Verifie si l emplacement horizontal est libre
        beq $v0, 1, rechercheH     # Si placement impossible on recommence la recherche

       # placement
       la $t1, grille            # charge l adresse de debut de la grille
       add $t1, $t1, $a0           # Place $t1 sur la premiere case du bateau
       li $t0, 0                   # Initialise le compteur de cases placees

       bouclePlacementH:           
           sb $s4, 0($t1)           # Ecrit le caractere du bateau dans la case courante
           addi $t1, $t1, 1        # Passe a la case suivante HORIZONTALEMENT on ajoute 1 a l index $t1 pour aller a la case suivante sur la MEME ligne)
           addi $t0, $t0, 1           # Incremente le nombre de cases placees
           bne $t0, $s0, bouclePlacementH   # Continue tant que la taille du bateau n est pas atteinte

    j end_setShip                  # Retour a la fin de la fonction setShip

# ----- Fontion verifPlaceHorizontale -----
# Objectif : verifie si le placement (horizontale) est possible.
#   $s0 contient la taille du navire
#   $s2 contient la ligne 
#   $s3 contient la colonne
# Retourne 0 si placement ok, 1 sinon
# Registres utilises : $v0, $t[0-4], $s0, $s2, $s3

verifPlaceHorizontale:
    la $t1, grille                 # Charge l adresse de la grille
    add $t1, $t1, $a0           # Positionne $t1 sur la premiere case a verifier ($a0 est l index calcule par placeHoriontale => pointe sur la premiere case du bateau)
    li $t0, 0                     # Initialise le comtpeur de verification : nombre de cases verifiees

    boucle_verifH:                   
        lb $t2, 0($t1)             # Charge le contenu de la case courante
        bne $t2, 46, erreur_verifH    #Si la case comporte autre chose qu un point => elle est occupee, placement impossible, on sort de la boucle : erreur
        
        addi $t1, $t1, 1                # Passe a la case suivante HORIZONTALEMENT = sur la ligne (+1)
        addi $t0, $t0, 1                # Incremente le nombre de cases verifiees
        bne $t0, $s0, boucle_verifH       # Continue tant que toute la taille du bateau ($s0) n est pas verifiee (on boucle jusqu a ce que $t0 == $s0)
  
        li $v0, 0                  # placement possible on retourne 0
        jr $ra            

	erreur_verifH:                   # Cas ou une case est deja occupee
    	    li $v0, 1              # Placement impossible donc on retourne 1
            jr $ra                 

# ----- Fontion placeVerticale -----
# Objectif : place aléatoirement un bateau de manière verticale.
#   Prends les paramètres de setShip
# Registres utilises : $v0, $a0, $a1, $s[0-4], $t[0-4]

# Meme principe que placeHorizontale mais on incrémente de 10
placeVerticale:
    rechercheV:                    # Debut de la recherche d une position valide
        # ligne : 0-(10 - taille)
        li $a1, 10                # Charge la hauteur de la grille
        sub $a1, $a1, $s0          # Ajuste pour eviter le depassement vertical
        jal getAleatoire          #  tire une ligne aleatoire valide
        
        move $s2, $a0              # Stocke la ligne choisie dans $s2

        # colonne : 0-9
        li $a1, 10               # definit la borne supperieur pour le tirage aleatoire de la colonne ($a1 = valeur max-1 dans fonction getAleatoire)
        jal getAleatoire         # tire une colonne aleatoire
        
        move $s3, $a0              # Stocke la colonne choisie dans $s3

        # index = ligne*10 + colonne
        mul $t0, $s2, 10           # Calcule le decalage de la ligne
        add $a0, $t0, $s3          # Calcule l index de depart du bateau

        jal verifPlaceVerticale    # Verifie si l emplacement vertical est libre
        
        # placement
        beq $v0, 1, rechercheV     # Si placement impossible on recommence
        la $t1, grille            # charge l adresse de la grille
        add $t1, $t1, $a0         # Place $t1 sur la premiere case du bateau
        li $t0, 0                  # Initialise le compteur de placement

    bouclePlaceV:             
        sb $s4, 0($t1)             # Ecrit le caractere du bateau dans la case courante
        addi $t1, $t1, 10          # Passe a la case suivante VERTICALEMENT (on ajoute 10 = nombre de colonnes, pr descendre a la case correspondante sur la ligne SUIVANTE)
        addi $t0, $t0, 1              # Incremente le nombre de cases placees
        bne $t0, $s0, bouclePlaceV     # Continue jusqu a placer tout le bateau

    j end_setShip                  # Retour a la fin de la fonction setShip

# ----- Fontion verifPlaceVerticale -----
# Objectif : verifie si le placement (verticale) est possible.
#   $s0 contient la taille du navire
#   $s2 contient la ligne 
#   $s3 contient la colonne
# Retourne 0 si placement ok, 1 sinon
# Registres utilises : $v0, $t[0-4], $s0, $s2, $s3

#De meme que verifPlaceHorizontale => on parcours simplement les cases sur les ligne ssuivantes (+10) au lieu d etre sur la meme ligne pour verifPlaceHorizontale (+1)
verifPlaceVerticale:
    la $t1, grille                 # Charge l adresse de la grille
    add $t1, $t1, $a0            # Positionne $t1 sur la premiere case a verifier ($a0 est l index calcule par placeVertciale => pointe sur la premiere case du bateau)
    li $t0, 0                      # Initialise le compteur de verification : nombre de cases verifiees

    boucle_verifV:                 
        lb $t2, 0($t1)             # Charge le contenu de la case courante
        bne $t2, 46, erreur_verifV     # Si la case n est pas vide alors erreur de placement => elle est occupee, placement impossible, on sort de la boucle : erreur
        
        addi $t1, $t1, 10                # Passe a la case suivante VERTICALEMENT = sur la colonne (+10)
        addi $t0, $t0, 1                # Incremente le nombre de cases verifiees
        bne $t0, $s0, boucle_verifV       # Continue tant que toute la taille du bateau ($s0) n est pas verifiee (on boucle jusqu a ce que $t0 == $s0)

        li $v0, 0                      # placement possible on retourne 0
        jr $ra                        

        erreur_verifV:                    # Cas ou une case est deja occupee
            li $v0, 1              # Placement impossible donc on retourne 1
            jr $ra                     

# ----- Fonction simulationJeu -----
# Objectif : Simule une partie avec une grille déjà généré.
# Registres utilises : $s[0-3]

simulationJeu:
    sub $sp, $sp, 4        # Alloue 4 octets sur la pile pour sauvegarder $ra
    sw $ra, 0($sp)          #Sauvegarde l adresse de retour
    li $s0, 0              # Initialise le compteur de coups effectues : nb_coups
    li $s1, 0              # Initialise le compteur de coups reussis (cases touchees) : nb_coups_but

    tantque_Bt_pas_coule:       # Boucle principale tant que tous les bateaux ne sont pas coules
        li $a1, 100             # Valeur max pour getAleatoire (100 cases = de 0 a 99)
        jal getAleatoire         #genere un index aleatoire
        move $s3, $a0           # Copie l index de la case dans $s3
        la $s2, grille          # Charge l adresse de base de la grille
        add $s2, $s3, $s2       # Adresse de la case cible = grille + index
        jal traque                # Appel de la fonction traque pour tester la case
        blt $s1, 17, tantque_Bt_pas_coule  # Tant que le nombre de cases touchees < 17, continuer

        affichage_nb_coups:     # Affichage du nombre de coups totaux effectues en fin de partie => nb_coups
            li $v0,4            # Syscall pour afficher une chaine de caracteres
	    la $a0,affichage_fin     # Charge la chaine de fin
	    syscall               # Affiche la chaine
	    li $v0,1            # Syscall pour afficher un entier
	    move $a0,$s0          # Charge le nombre de coups nb_coups => $s0
	    syscall               # Affiche le nombre de coups
	    jal addNewLine        # Ajoute une ligne vide pour la lisibilite

    lw $ra, 0($sp)               # Restaure l adresse de retour
    add $sp, $sp, 4               # Libere l espace sur la pile
    jr $ra                        


# ----- Fontion traque -----     
# Objectif : Vérifie la présence d'un navire et le traque de manière récursive
# Registres utilises : $t[8-9], $s[0-3]

# Remarques :
# Sauvegarde de l'etat courant (adresse de retour $ra et index $3)
# afin de restaurer la position apres chaque appel recursif

traque:
    sub $sp, $sp, 8        # Alloue 8 octets pour sauvegarder $ra et $s3
    sw $ra, 0($sp)         # Sauvegarde $ra
    sw $s3, 4($sp)         # Sauvegarde $s3 : index courant de la case

    lb $t8, 0($s2)           # Charge le contenu de la case cible ($s2 de simulationJeu) pour verifier si on peut tirer
                             # $s2 contient l'adresse mémoire de la case courante (pointeur dans la grille)
    li $t9, 126                   # ~ symbole pour case manquee
    beq $t8, $t9, finTraque      # Si case deja marquee comme manquee, on quitte
    li $t9, 88                    #X symbole pour case touchee
    beq $t8, $t9, finTraque      # Si case deja touchee, on quitte

    addi $s0, $s0, 1       # Incremente le nombre total de coups
    li $t9, 46                    # . symbole case "vide"
    beq $t8, $t9, tirManque      # Si case vide : c est un tir manque (echec)

   toucher:                       # Cas ou un bateau est touche
       addi $s1, $s1, 1           # Incremente le nombre de coups reussis
       li $t8, 88              # Met le symbole X
       sb $t8, 0($s2)            # Stocke le symbole dans la case : marque la case comme touchee
       jal displayGrille           # Affiche la grille apres le tir afin de visualiser l avancement du jeu

   appelRecursif:                 # Verification recursive dans toutes les directions
        # NORD
        ble  $s3, 9, skipNord     # Si index $s3 <= 9 on est sur la premiere ligne (attention ligne 0) : pas de case au nord (au dessus...)
        subi $s2, $s2, 10         # Deplace l adresse vers la case du dessus (pointeur)
        subi $s3, $s3, 10         #Met a jour l index correspondant
        jal traque            # Apple recursif de traque
        
        la $s2, grille            # Recharge l adresse de base de la grille
        lw $s3, 4($sp)            # Recharge l index initial
        add $s2, $s3, $s2            #Repositionne $s2 sur la case d origine

	skipNord:
    	    # SUD
    	    bge  $s3, 90, skipSud   #Si index s3 >= 90, on est sur la derniere ligne : pas de case au sud (en dessous...)
            addi $s2, $s2, 10      # Deplace le pointeur vers la case en dessous
    	    addi $s3, $s3, 10      # Index case dessous
    	    jal traque
    	    
    	    la $s2, grille
    	    lw $s3, 4($sp)
    	    add $s2, $s3, $s2
    	    
    	    skipSud:
    	        # OUEST
                move $a0, $s3
    		li $a1, 10
    		jal getModulo                # Verifie si la case est sur la premiere colonne (mod 10 == 0)
    		beq $v0, $zero, skipOuest        #si oui alors impossible d aller a l ouest on saute 
    		subi $s2, $s2, 1              # Deplace le pointeur vers la case de gauche
                subi $s3, $s3, 1              # Met a jour l index
         	jal traque               
         	
         	la $s2, grille
    		lw $s3, 4($sp)
    		add $s2, $s3, $s2
    
		skipOuest:
    		    # EST
    		    move $a0, $s3
    		    li $a1, 10
    		    jal getModulo         # Verifie si la case est sur la derniere colonne (mod 10 == 9)
    		    
    		    li $t9, 9
   		    beq $v0, $t9, skipEst         # Si oui impossible d aller a l est (droite)
   		    addi $s2, $s2, 1              # Deplace le pointeur $s2 vers la case de droite
    		    addi $s3, $s3, 1              # Met a jour l index $s3
    		    jal traque
    		    
    		    la $s2, grille
    		    lw $s3, 4($sp)
    		    add $s2, $s3, $s2
		    
		    skipEst:
    			j finTraque

    tirManque:
        li $t8, 126                # Met le symbole '~' pour tir manque
        sb $t8, 0($s2)             # Stocke dans la case
        jal displayGrille           # Affiche la grille

    finTraque:
        lw $s3, 4($sp)             # Restaure l index original
        lw $ra, 0($sp)             # Restaure l adresse de retour
        add $sp, $sp, 8            # Libere l espace alloue sur la pile
        jr $ra


exit: 
    li $v0, 10  #Chargement appel systeme 10 (Sortie)
    syscall
