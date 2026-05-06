#include "..\macros.hpp"

/*
 * TAG_fnc_taskManager
 *
 * Description:
 *   Gestionnaire central des tâches de mission.
 *   Crée, assigne et enchaîne toutes les tâches de la mission LA LÉGION ÉTRANGÈRE.
 *   Doit être appelé uniquement sur le serveur depuis fn_initServer.sqf.
 *
 * Arguments:
 *   None
 *
 * Return Value:
 *   None
 *
 * Locality:
 *   Server uniquement (isServer)
 *
 * Example:
 *   [] call TAG_fnc_taskManager;
 */

if (!isServer) exitWith {};

// ══════════════════════════════════════════════════════════════════════════════
// PROPRIÉTAIRE DES TÂCHES
// ══════════════════════════════════════════════════════════════════════════════
// En multijoueur, assigner les tâches au côté entier (west) pour que tous
// les joueurs les reçoivent, y compris les JIP (Join In Progress).
// En solo, on peut utiliser "player" directement.
//
//   private _owner = [west, player] select isMultiplayer;
//
private _owner = west;

// ══════════════════════════════════════════════════════════════════════════════
// RAPPEL — STRUCTURE D'UNE TÂCHE (BIS_fnc_taskCreate)
// ══════════════════════════════════════════════════════════════════════════════
//
// [
//     _owner,           // Qui reçoit la tâche : west, player, group player…
//     _taskID,          // String unique, ex: "t1_nom_tache" — peut être un array
//                       // pour une sous-tâche : ["sous_tache", "tache_parente"]
//     _description,     // Array à 3 éléments :
//                       //   [0] Description longue (HTML basique autorisé : <br/>, <t color='#FF0000'>…)
//                       //   [1] Titre court (affiché dans la liste des tâches)
//                       //   [2] Texte du marqueur sur la carte
//     _destination,     // Position : getMarkerPos "marker", getPosATL obj, objNull (pas de marqueur)
//     _state,           // "CREATED" | "ASSIGNED" | "AUTOASSIGNED" (recommandé)
//     _priority,        // Entier 0-5 — plus haut = plus prioritaire dans la liste
//     _showNotification,// true = notification sonore à la création, false = silencieux
//     _type             // Type d'icône : "attack" | "destroy" | "move" | "kill" |
//                       // "capture" | "defend" | "intel" | "search" | "meet" | "run"
//                       // Liste complète : https://community.bistudio.com/wiki/Arma_3:_Task_Framework
// ] call BIS_fnc_taskCreate;
//
// ──────────────────────────────────────────────────────────────────────────────
// MISE À JOUR APRÈS CRÉATION
// ──────────────────────────────────────────────────────────────────────────────
//   // Changer l'état (SUCCEEDED / FAILED / CANCELED)
//   ["t1_nom_tache", "SUCCEEDED", true] call BIS_fnc_taskSetState;
//                                        // true = afficher notification
//
//   // Modifier description / titre / marqueur
//   ["t1_nom_tache", ["Nouvelle description", "Nouveau titre", "Marqueur"]]
//       call BIS_fnc_taskSetDescription;
//
//   // Modifier la position du marqueur de tâche
//   ["t1_nom_tache", getMarkerPos "nouveau_marker", true] call BIS_fnc_taskSetDestination;
//                                                          // true = afficher sur carte
//
// ──────────────────────────────────────────────────────────────────────────────
// VÉRIFICATIONS
// ──────────────────────────────────────────────────────────────────────────────
//   ["t1_nom_tache"] call BIS_fnc_taskState      // retourne l'état courant
//   ["t1_nom_tache"] call BIS_fnc_taskCompleted  // true si SUCCEEDED
//   ["t1_nom_tache"] call BIS_fnc_taskExists     // true si la tâche existe
//
// ──────────────────────────────────────────────────────────────────────────────
// HIÉRARCHIE DES IDs RECOMMANDÉE POUR CETTE MISSION
// ──────────────────────────────────────────────────────────────────────────────
//   Tâches principales : "main_1_...", "main_2_...", "main_3_..."
//   Tâches secondaires : "side_1_...", "side_2_..."
//   Sous-tâches        : "sub_1_1_...", "sub_1_2_..." (liées à main_1_...)
//
// ══════════════════════════════════════════════════════════════════════════════


// ══════════════════════════════════════════════════════════════════════════════
// TÂCHE PRINCIPALE 1 — TEMPLATE (À REMPLACER PAR LA VRAIE TÂCHE)
// ══════════════════════════════════════════════════════════════════════════════
//
// INSTRUCTIONS POUR LA PROCHAINE TÂCHE :
// ─────────────────────────────────────
// 1. Dupliquer le bloc ci-dessous pour chaque tâche.
// 2. Remplacer "main_1_example" par l'ID réel de la tâche.
// 3. Remplacer les textes de description (utiliser localize "STR_..." pour le multilingue).
// 4. Remplacer getMarkerPos "marker_example" par le vrai marqueur Eden.
// 5. Choisir le type d'icône adapté à l'action demandée.
// 6. Enchaîner les tâches avec waitUntil ou un trigger (voir section "Enchaînement" plus bas).
//
// [
//     _owner,
//     ["main_1_example"],
//     [
//         "Description détaillée de l'objectif principal.<br/>Soyez précis sur ce qui est attendu.",
//         "Titre de la tâche",
//         "Titre sur la carte"
//     ],
//     getMarkerPos "marker_example",
//     "AUTOASSIGNED",
//     5,
//     true,
//     "attack"
// ] call BIS_fnc_taskCreate;
//
// ══════════════════════════════════════════════════════════════════════════════


// ══════════════════════════════════════════════════════════════════════════════
// TÂCHE SECONDAIRE 1 — TEMPLATE
// ══════════════════════════════════════════════════════════════════════════════
//
// [
//     _owner,
//     ["side_1_example"],
//     [
//         "Description de l'objectif secondaire.",
//         "Titre secondaire",
//         "Titre carte secondaire"
//     ],
//     getMarkerPos "marker_side_example",
//     "AUTOASSIGNED",
//     3,
//     true,
//     "search"
// ] call BIS_fnc_taskCreate;
//
// ══════════════════════════════════════════════════════════════════════════════


// ══════════════════════════════════════════════════════════════════════════════
// SOUS-TÂCHES — TEMPLATE (objectifs composites liés à main_1_example)
// ══════════════════════════════════════════════════════════════════════════════
//
// Passer l'ID comme array ["sous_tache", "parente"] pour créer la hiérarchie.
//
// [
//     _owner,
//     [["sub_1_1_example", "main_1_example"]],
//     [
//         "Sous-objectif 1 : description.",
//         "Sous-objectif 1",
//         "Sous-obj 1"
//     ],
//     getMarkerPos "marker_sub_example",
//     "AUTOASSIGNED",
//     4,
//     false,
//     "move"
// ] call BIS_fnc_taskCreate;
//
// ══════════════════════════════════════════════════════════════════════════════


// ══════════════════════════════════════════════════════════════════════════════
// ENCHAÎNEMENT DES TÂCHES — PATRON RECOMMANDÉ
// ══════════════════════════════════════════════════════════════════════════════
//
// Méthode 1 : waitUntil sur condition de complétion (spawné pour éviter de
//             bloquer l'init serveur)
//
// [] spawn {
//     // Attendre que la tâche 1 soit réussie
//     waitUntil { ["main_1_example"] call BIS_fnc_taskCompleted };
//
//     // Marquer comme succès avec notification
//     ["main_1_example", "SUCCEEDED", true] call BIS_fnc_taskSetState;
//
//     // Créer la tâche suivante
//     [
//         west,
//         ["main_2_example"],
//         [
//             "Description de la tâche suivante.",
//             "Tâche suivante",
//             "Tâche suivante"
//         ],
//         getMarkerPos "marker_2_example",
//         "AUTOASSIGNED",
//         5,
//         true,
//         "defend"
//     ] call BIS_fnc_taskCreate;
// };
//
// Méthode 2 : Trigger Eden avec condition SQF
//             (plus adapté aux triggers de zone ou de véhicule)
//
// Dans la condition du trigger :
//   ["main_1_example"] call BIS_fnc_taskCompleted
//
// Dans l'action On Activation :
//   ["main_1_example", "SUCCEEDED", true] call BIS_fnc_taskSetState;
//
// ══════════════════════════════════════════════════════════════════════════════


// ══════════════════════════════════════════════════════════════════════════════
// LOCALISATION — UTILISER stringtable.xml
// ══════════════════════════════════════════════════════════════════════════════
//
// Pour chaque tâche, ajouter dans stringtable.xml (Package "Tasks") :
//
//   <Key ID="STR_TAG_Task_main_1_desc">
//       <French>Description longue de la tâche 1.</French>
//       <English>Long description for task 1.</English>
//   </Key>
//   <Key ID="STR_TAG_Task_main_1_title">
//       <French>Titre de la tâche 1</French>
//       <English>Task 1 title</English>
//   </Key>
//
// Puis dans ce fichier, remplacer les strings hardcodées par :
//   localize "STR_TAG_Task_main_1_desc"
//   localize "STR_TAG_Task_main_1_title"
//
// ══════════════════════════════════════════════════════════════════════════════


if (DEBUG_MODE) then {
    diag_log "[TAG] fn_taskManager: Gestionnaire de tâches initialisé.";
};
