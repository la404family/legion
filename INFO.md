# Informations sur les variables présentes dans l'éditeur

## Variables présentes dans l'éditeur:

- player_0, player_1, player_2, player_3, player_4, player_5, player_6 sont les joueurs jouables.
- ezan_0, ezan_1, ezan_2, ezan_3, ezan_4, ezan_5 sont des Loudspeaker dans le jeu qui produise l'appel a la prière.
- template_01 ... template_xx sont des personnages dans l'éditeur qui servent de gabarit de personnage pour des missions ou des civils...
- Des femmes sont présentes dans l'éditeur grace à un mod les noms des variables pour les femmes sont :
    - Max_Tak_woman1 à  Max_Tak_woman6
    - Max_Taky_woman1 à  Max_Taky_woman5
    - Max_Tak2_woman1 à  Max_Tak2_woman5
- Les hommes sont défini par le mod par : CUP_C_TK_....
- template_01 à template_16 sont des femmes
- template_16 à template_37 sont des hommes...
-  les barbes sont déterminées par la variable CUP_Beard_Brown ou CUP_Beard_Black
- Les chapeaux sont déterminés par : CPU_H_TKI_Lungee_Open_01 à CPU_H_TKI_Lungee_Open_06 ou CPU_H_TKI_Pakol_1_01 à CPU_H_TKI_Pakol_1_05 ou CPU_H_TKI_SkullCap_01 à CPU_H_TKI_SkullCap_06 
- Les chapeaux et les barbes sont réservés aux hommes.
- Toujours ajouter : 0.5 en Z lors d'un spawn (exemple : _bPos set [2, (_bPos select 2) + 0.5];) pour éviter de se retrouver dans le sol.
- heliport_00 est un heliport invisible 