#include "..\macros.hpp"

/*
 * TAG_fnc_healActionManager
 *
 * Description:
 *   Gère l'ajout de l'action "Donner l'ordre de se soigner" au joueur leader.
 *   Contient la logique pour différer les soins en combat et décaler les animations.
 *   S'adapte automatiquement si le joueur change de personnage.
 *
 * Locality:
 *   Client
 */

if (!hasInterface) exitWith {};

[] spawn {
    private _fnc_addHealAction = {
        params ["_unit"];
        
        if (_unit getVariable ["TAG_Action_Heal_Added", false]) exitWith {};
        _unit setVariable ["TAG_Action_Heal_Added", true];

        _unit addAction [
            localize "STR_TAG_Action_Heal",  
            {
                params ["_target", "_caller", "_actionId", "_arguments"];
                
                // Récupération des IA blessées
                private _aiUnits = (units group _caller) select { !isPlayer _x && alive _x && damage _x > 0.1 };
                private _validHealers = [];
                private _noKitCount = 0;

                {
                    if ("FirstAidKit" in items _x || "Medikit" in items _x) then {
                        _validHealers pushBack _x;
                    } else {
                        _noKitCount = _noKitCount + 1;
                    };
                } forEach _aiUnits;

                if (count _validHealers > 0) then {
                    systemChat format [localize "STR_TAG_Msg_Heal_Ordered", count _validHealers];
                    
                    [_validHealers] spawn {
                        params ["_healers"];
                        {
                            private _unit = _x;
                            private _delayBase = _forEachIndex;
                            
                            [_unit, _delayBase] spawn {
                                params ["_unit", "_delayBase"];
                                
                                // OPTIMISATION: On attend que l'IA ne soit plus en statut COMBAT ou n'ait plus de cible proche
                                waitUntil { 
                                    sleep 2; 
                                    !alive _unit || 
                                    (behaviour _unit != "COMBAT" && isNull (_unit findNearestEnemy _unit))
                                };
                                
                                if (alive _unit && damage _unit > 0.1) then {
                                    // Décalage des soins pour ne pas lancer les animations toutes en même temps
                                    sleep (_delayBase * (1.5 + random 1.0));
                                    if (alive _unit) then {
                                        _unit action ["HealSoldierSelf", _unit];
                                    };
                                };
                            };
                        } forEach _healers;
                    };
                } else {
                    if (_noKitCount > 0) then {
                        systemChat localize "STR_TAG_Msg_Heal_NoKit";
                    } else {
                        systemChat localize "STR_TAG_Msg_Heal_NotNeeded";
                    };
                };
            },
            [],
            5.3, 
            false, 
            true, 
            "", 
            // OPTIMISATION: Condition légère évaluée par le moteur. Le menu n'apparaît que pour le leader d'un groupe contenant des I.A.
            "leader group _target == _target && { { !isPlayer _x } count (units group _target) > 0 }"
        ];
    };

    // Boucle de maintien de l'action (en cas de switch d'IA ou de respawn)
    private _lastPlayer = objNull;
    while {true} do {
        waitUntil { sleep 1; player != _lastPlayer };  
        
        _lastPlayer = player;
        if (!isNull _lastPlayer) then {
            [_lastPlayer] call _fnc_addHealAction;
        };
    };
};
