#include "..\macros.hpp"

/*
 * TAG_fnc_badgeManager
 *
 * Description:
 *   Boucle infinie tournant sur le serveur. Assure que toutes les unités BLUFOR
 *   (incluant les joueurs) portent le bon insigne (badge).
 *
 * Arguments:
 *   None
 *
 * Locality:
 *   Server
 */

if (!isServer) exitWith {};

if (DEBUG_MODE) then {
    diag_log "[TAG] Démarrage de la synchronisation des insignes (badges)...";
};

while {true} do {
    private _bluforUnits = allUnits select { side _x == west && alive _x };
    
    {
        private _unit = _x;
        private _currentBadge = [_unit] call BIS_fnc_getUnitInsignia;
        
        if (_currentBadge != "AMF_FRANCE_HV") then {
            // BIS_fnc_setUnitInsignia gère nativement la diffusion réseau (global)
            [_unit, "AMF_FRANCE_HV"] call BIS_fnc_setUnitInsignia;
        };
    } forEach _bluforUnits;
    
    sleep 60;
};
