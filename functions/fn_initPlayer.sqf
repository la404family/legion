#include "..\macros.hpp"

/*
 * TAG_fnc_initPlayer
 *
 * Description:
 *   Per-player init logic (JIP compatible).
 *
 * Arguments:
 *   None
 *
 * Return Value:
 *   None
 *
 * Locality:
 *   Client
 */

if (!hasInterface) exitWith {};

// Wait for player to be fully initialized before executing player logic
waitUntil { !isNull player && {player == player} };

// Ajouter un Event Handler pour gérer la mort du joueur s'il est leader
player addEventHandler ["Killed", {
    params ["_unit", "_killer", "_instigator", "_useEffects"];
    
    // Si le joueur tué était le leader de son groupe
    if (leader (group _unit) == _unit) then {
        [group _unit, _unit] remoteExec ["TAG_fnc_manageLeadership", 2];
    };
    
    // Basculer vers une IA s'il y a de la place
    [_unit] spawn TAG_fnc_switchToAI;
}];

// Ajouter le gestionnaire de l'action de soin
[] spawn TAG_fnc_healActionManager;

// Ajouter le gestionnaire des règles d'engagement (RoE)
[] spawn TAG_fnc_roeManager;

// Ajouter le gestionnaire de fouille de bâtiments (CQB)
[] spawn TAG_fnc_searchActionManager;

// Ajouter l'ordre de repli tactique
[] spawn TAG_fnc_retreatActionManager;

// Ajouter l'ordre de formation en ligne
[] spawn TAG_fnc_lineFormationManager;

// Ajouter le gestionnaire de support (Aérien, artillerie, etc)
[] spawn TAG_fnc_supportManager;

if (DEBUG_MODE) then {
    systemChat "[TAG] Player Initialization Started.";
};

// Client logic here (UI, local events, loadout, etc.)

if (DEBUG_MODE) then {
    systemChat "[TAG] Player Initialization Finished.";
};
