#include "..\macros.hpp"

/*
 * TAG_fnc_searchActionManager
 *
 * Description:
 *   Gère l'ajout de l'action de fouille de bâtiments (CQB) au joueur leader.
 *   Optimisé via une variable d'état globale mise à jour toutes les 2s pour
 *   alléger la condition du addAction (évaluée à chaque frame par le moteur).
 *
 * Locality:
 *   Client
 */

if (!hasInterface) exitWith {};

TAG_Search_BuildingsNearby = false;

[] spawn {
    // -------------------------------------------------------------------------
    // BOUCLE DE MISE À JOUR DE L'ÉTAT (toutes les 2 secondes)
    // -------------------------------------------------------------------------
    [] spawn {
        while {true} do {
            sleep 2;
            if (!isNull player && alive player) then {
                // Cherche les bâtiments à moins de 50m
                private _nearbyBuildings = nearestObjects [player, ["House", "Building"], 50];
                // Vérifie s'il y a des positions de garnison à l'intérieur
                private _validBuildings = _nearbyBuildings select { count (_x buildingPos -1) > 0 };
                TAG_Search_BuildingsNearby = (count _validBuildings > 0);
            } else {
                TAG_Search_BuildingsNearby = false;
            };
        };
    };

    // -------------------------------------------------------------------------
    // FONCTION D'AJOUT D'ACTION
    // -------------------------------------------------------------------------
    private _fnc_addSearchAction = {
        params ["_unit"];
        
        if (_unit getVariable ["TAG_Action_Search_Added", false]) exitWith {};
        _unit setVariable ["TAG_Action_Search_Added", true];

        _unit addAction [
            localize "STR_TAG_Action_Search",
            {
                params ["_target", "_caller", "_actionId", "_arguments"];

                private _nearbyBuildings = nearestObjects [_caller, ["House", "Building"], 50];
                private _validBuildings = _nearbyBuildings select { count (_x buildingPos -1) > 0 };

                if (count _validBuildings == 0) exitWith {
                    systemChat localize "STR_TAG_Msg_Search_NoBuilding";
                };

                private _allPositions = [];
                { _allPositions append (_x buildingPos -1); } forEach _validBuildings;
                if (count _allPositions == 0) exitWith { 
                    systemChat localize "STR_TAG_Msg_Search_NotAccessible"; 
                };

                // Mélanger les positions pour une répartition aléatoire de l'escouade
                _allPositions = _allPositions call BIS_fnc_arrayShuffle;

                private _squadAI = (units group _caller) select { !isPlayer _x && alive _x && vehicle _x == _x };
                if (count _squadAI == 0) exitWith { 
                    systemChat localize "STR_TAG_Msg_Search_NoInfantry"; 
                };

                systemChat format [localize "STR_TAG_Msg_Search_Deploying", count _squadAI];

                // Paramétrage agressif pour investir le bâtiment
                {
                    _x disableAI "AUTOCOMBAT";
                    _x disableAI "SUPPRESSION";
                    _x setUnitPos "UP";
                    _x setBehaviour "AWARE";
                    _x setSpeedMode "FULL";

                    if (count _allPositions > 0) then {
                        private _assignedPos = _allPositions deleteAt 0;
                        _x doMove _assignedPos;
                    } else {
                        // S'il y a plus d'I.A que de pièces, les derniers suivent le joueur
                        _x doFollow _caller;
                    };
                } forEach _squadAI;

                // Rétablissement des paramètres normaux après 3 minutes
                [_squadAI] spawn {
                    params ["_units"];
                    sleep 180;
                    {
                        if (alive _x) then {
                            _x enableAI "AUTOCOMBAT";
                            _x enableAI "SUPPRESSION";
                            _x setUnitPos "AUTO";
                            _x setSpeedMode "NORMAL";
                            _x setBehaviour "AWARE";
                            
                            // Forcer le retour en formation
                            _x doFollow (leader group _x);
                        };
                    } forEach _units;
                    systemChat localize "STR_TAG_Msg_Search_Complete";
                };
            },
            [],
            5.5,
            false,
            true,
            "",
            // CONDITION OPTIMISÉE : N'apparaît que s'il y a des IA ET des bâtiments autour
            "leader group _target == _target && { { !isPlayer _x } count (units group _target) > 0 } && TAG_Search_BuildingsNearby"
        ];
    };

    // -------------------------------------------------------------------------
    // BOUCLE PRINCIPALE - Gestion du switch de joueur
    // -------------------------------------------------------------------------
    private _lastPlayer = objNull;
    while {true} do {
        waitUntil { sleep 1; player != _lastPlayer };
        
        _lastPlayer = player;
        if (!isNull _lastPlayer) then {
            [_lastPlayer] call _fnc_addSearchAction;
        };
    };
};
