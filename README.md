# La Légion Étrangère — Kunduz Valley

Mission Arma 3 multijoueur incarnant une escouade de la Légion étrangère française opérant dans la vallée de Kunduz.

---

## Dossier `functions/`

### Initialisation

| Fichier | Logique |
|---|---|
| `fn_init.sqf` | Point d'entrée global. Lance la cinématique d'introduction, puis délègue vers `fn_initServer` côté serveur et `fn_initPlayer` côté client. |
| `fn_initServer.sqf` | Initialisation serveur : collecte les templates civils, lance les boucles de gestion (leaders, identités, badges, appel à la prière, présence civile), et sauvegarde l'équipement initial de chaque slot joueur pour les livraisons de munitions. |
| `fn_initPlayer.sqf` | Initialisation par client (JIP compatible) : attache les event handlers de mort, et démarre les gestionnaires d'actions (soins, RoE, fouille, repli, formation, support). |

---

### Gestion de l'escouade et du commandement

| Fichier | Logique |
|---|---|
| `fn_assignLeader.sqf` | Si le slot leader (`player_0`) est vide et qu'il y a moins de 7 joueurs, sélectionne aléatoirement un joueur présent comme nouveau chef de groupe et regroupe tout le monde sous lui. S'exécute une seule fois au démarrage du serveur. |
| `fn_manageLeadership.sqf` | Déclenché à la mort d'un leader. Cherche un joueur vivant dans le groupe et lui transfère le commandement, avec notification via chat système. |
| `fn_switchToAI.sqf` | À la mort d'un joueur, bascule son contrôle vers une IA vivante du groupe via un transfert de localité, et ré-attache les event handlers nécessaires. |
| `fn_transferLocality.sqf` | Utilitaire serveur : transfère la propriété (locality) d'un objet vers un client identifié par son owner ID réseau (`setOwner`). |

---

### Actions tactiques du leader

| Fichier | Logique |
|---|---|
| `fn_healActionManager.sqf` | Ajoute l'action "Ordonner les soins" au leader. Les IA avec kit médical attendent la fin du combat avant de se soigner elles-mêmes, avec un décalage d'animation entre chaque unité. |
| `fn_roeManager.sqf` | Ajoute des actions molette pour changer les règles d'engagement de l'escouade : Infiltration (GHOST), Vigilance (AWARE), Assaut (COMBAT), Ultra-agressif (CHARGE). Visible uniquement si le joueur est leader. |
| `fn_retreatActionManager.sqf` | Ajoute l'action "Repli tactique". Les IA jettent une fumigène, désactivent l'auto-combat, sprintent et forment un cercle de 360° autour du leader avant de redevenir agressives. |
| `fn_lineFormationManager.sqf` | Ajoute l'action "Formation en ligne". Les IA se positionnent en ligne défensive perpendiculaire à la direction du leader, lancent une fumigène vers l'avant, puis reprennent leur comportement normal. |
| `fn_searchActionManager.sqf` | Ajoute l'action "Fouille de bâtiments" (CQB). Les IA occupent les positions de garnison des bâtiments proches. Une boucle de fond toutes les 2 secondes pré-calcule si des bâtiments valides sont à portée pour optimiser la condition du menu. |
| `fn_supportManager.sqf` | Ajoute le menu de soutien au leader : soutien aérien CAS, livraison de munitions, et livraison de véhicule. Chaque action envoie une requête au serveur via `remoteExec`. |

---

### Soutiens aériens

| Fichier | Logique |
|---|---|
| `fn_callAirSupport.sqf` | Spawne un hélicoptère de soutien armé qui effectue des loiters au-dessus de la position ciblée pendant 120 secondes. Un verrou global empêche deux soutiens simultanés. |
| `fn_callAmmoDrop.sqf` | Spawne un hélicoptère logistique qui largue une caisse de ravitaillement. Le contenu est généré dynamiquement à partir de l'équipement initial sauvegardé des joueurs. |
| `fn_callVehicleDelivery.sqf` | Spawne un hélicoptère qui livre un véhicule tactique par élingage. La position de dépôt est calculée intelligemment sur la route la plus proche du centre de masse des joueurs actifs. |
| `fn_callDroneSupport.sqf` | Spawne un drone Reaper de reconnaissance qui vole vers le groupe depuis 3000m, tourne à 100m d'altitude / 100m de rayon pendant 15 minutes, puis rentre à la base. Le drone est invisible aux ennemis (forgetTarget loop) et ignore lui-même les ennemis. Marque les contacts ennemis détectés dans un rayon de 1500m sur la carte (pool de 5 marqueurs, mise à jour toutes les 5-10s, avec ±25m d'imprécision réaliste). Verrou partagé avec le bouton de support. |

---

### Gestion des identités et apparences

| Fichier | Logique |
|---|---|
| `fn_identityManager.sqf` | Boucle serveur qui assigne périodiquement une identité aléatoire (nom, visage, voix, pitch) aux unités BLUFOR qui n'en ont pas encore. Puise dans des listes de noms multiculturels reflétant la composition réelle de la Légion. |
| `fn_applyIdentity.sqf` | Applique concrètement les données d'identité (visage, nom, voix, pitch) à une unité. Doit être exécuté sur tous les clients via `remoteExec` pour que les effets soient visibles et audibles par tous. |
| `fn_badgeManager.sqf` | Boucle serveur qui vérifie toutes les 60 secondes que toutes les unités BLUFOR portent bien l'insigne de mission (`AMF_FRANCE_HV`). Corrige automatiquement les unités sans insigne. |
| `fn_skillManager.sqf` | Boucle tournant sur toutes les machines. Ajuste les compétences (précision, détection, courage…) des IA locales selon leur faction. Les ennemis sont délibérément affaiblis ; les alliés sont standards, sauf le sniper (`player_1`) qui reçoit des stats élites. Appliqué une seule fois par unité. |
| `fn_templateCollector.sqf` | Collecte les unités `template_XX` placées dans l'éditeur, extrait leur apparence (classe, équipement, visage, pitch, genre), les stocke dans `MISSION_CivilianTemplates`, puis supprime les templates de la carte. Installe aussi le handler `EntityCreated` pour appliquer automatiquement l'apparence aux civils spawnés. |

---

### Ambiance et environnement

| Fichier | Logique |
|---|---|
| `fn_civilianPresence.sqf` | Boucle serveur qui spawne des civils dans les bâtiments autour des joueurs (max 55 simultanément) et les supprime quand ils sont trop éloignés de tous les joueurs. Les civils patrouillent via `BIS_fnc_taskPatrol`. |
| `fn_callToPrayer.sqf` | Diffuse l'appel à la prière en son 3D depuis jusqu'à 6 minarets (`ezan_0`–`ezan_5`) placés dans l'éditeur. Démarre après un délai aléatoire (5–15 min) et se répète toutes les 30 minutes. |
| `fn_introCinematic.sqf` | Cinématique d'introduction : spawne une scène de combat fictive entre OPFOR et forces indépendantes, puis fait survoler la zone par un hélicoptère de transport avec caméra dramatique avant le début de la mission. |
