#include "..\macros.hpp"

/*
 * TAG_fnc_supportManager
 *
 * Description:
 *   Gère l'ajout du menu et des actions de support au joueur leader.
 *   Conçu pour accueillir plusieurs types de supports.
 *
 * Locality:
 *   Client
 */

if (!hasInterface) exitWith {};

[] spawn {
    private _fnc_addSupportActions = {
        params ["_unit"];
        
        if (_unit getVariable ["TAG_Action_Support_Added", false]) exitWith {};
        _unit setVariable ["TAG_Action_Support_Added", true];

        // Action 1 : Soutien Aérien (Hélicoptère)
        _unit addAction [
            localize "STR_TAG_Action_Support_CAS",
            {
                params ["_target", "_caller", "_actionId", "_arguments"];

                // On cible là où le joueur regarde (jusqu'à 2000m)
                private _targetPos = screenToWorld [0.5, 0.5];
                
                // Si le joueur regarde le ciel ou très loin, on centre sur sa position
                if (_caller distance _targetPos > 2000) then {
                    _targetPos = getPos _caller;
                };

                // Envoie la demande au serveur
                [_targetPos, _caller] remoteExec ["TAG_fnc_callAirSupport", 2];
            },
            [],
            4.5,
            false,
            true,
            "",
            "leader group _target == _target"
        ];

        // Action 2 : Livraison de Munitions
        _unit addAction [
            localize "STR_TAG_Action_Support_Ammo",
            {
                params ["_target", "_caller", "_actionId", "_arguments"];

                private _targetPos = screenToWorld [0.5, 0.5];
                if (_caller distance _targetPos > 2000) then {
                    _targetPos = getPos _caller;
                };

                [_targetPos, _caller] remoteExec ["TAG_fnc_callAmmoDrop", 2];
            },
            [],
            4.4,
            false,
            true,
            "",
            "leader group _target == _target"
        ];
    };

    private _lastPlayer = objNull;
    while {true} do {
        waitUntil { sleep 1; player != _lastPlayer };  
        
        _lastPlayer = player;
        if (!isNull _lastPlayer) then {
            [_lastPlayer] call _fnc_addSupportActions;
        };
    };
};
