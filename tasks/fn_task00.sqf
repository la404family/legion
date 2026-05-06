#include "..\macros.hpp"

/*
 * TAG_fnc_task00
 *
 * Description:
 *   Tâche 00 — Embarquement.
 *   Crée la première tâche de la mission : le leader et tous les joueurs
 *   doivent monter dans le véhicule allié (vehicule_team) pour débuter
 *   les opérations. La tâche passe à SUCCEEDED dès que tous les joueurs
 *   vivants sont à bord.
 *   Joue un son de briefing aléatoire (task00_01/02/03) à la création.
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
 *   [] call TAG_fnc_task00;
 */

if (!isServer) exitWith {};

// ── Son de briefing ───────────────────────────────────────────────────────────
private _snd = selectRandom ["task00_01", "task00_02", "task00_03"];
[_snd] remoteExec ["playSound", 0];

// ── Création de la tâche ──────────────────────────────────────────────────────
[
    west,
    ["task_00_embark"],
    [
        localize "STR_TAG_Task_00_Desc",
        localize "STR_TAG_Task_00_Title",
        localize "STR_TAG_Task_00_Marker"
    ],
    getPosATL vehicule_team,
    "AUTOASSIGNED",
    5,
    true,
    "move"
] call BIS_fnc_taskCreate;

if (DEBUG_MODE) then {
    diag_log "[TAG] task00: Tâche d'embarquement créée.";
};

// ── Surveillance de complétion (spawné pour permettre waitUntil) ──────────────
[] spawn {

    // Attendre que tous les joueurs vivants soient à bord de vehicule_team
    waitUntil {
        sleep 2;

        // Collecter les joueurs vivants de la coalition
        private _alivePlayers = allPlayers select { alive _x && side _x == west };

        // Si personne de vivant, éviter un faux positif — attendre
        if (count _alivePlayers == 0) exitWith { false };

        // Vrai si chaque joueur vivant est bien passager ou conducteur du véhicule
        private _notBoarded = _alivePlayers select { vehicle _x != vehicule_team };

        (count _notBoarded == 0)
    };

    // Tous à bord — succès
    ["task_00_embark", "SUCCEEDED", true] call BIS_fnc_taskSetState;

    if (DEBUG_MODE) then {
        diag_log "[TAG] task00: Tous les joueurs sont embarqués — tâche réussie.";
    };
};
