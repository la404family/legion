#include "..\macros.hpp"

/*
 * TAG_fnc_roeManager
 *
 * Description:
 *   Gère les règles d'engagement (RoE) de l'escouade via des actions molette.
 *   Optimisé en utilisant la condition native des addAction plutôt qu'une boucle.
 *   S'adapte automatiquement si le joueur change de personnage (Team Switch).
 *
 * Locality:
 *   Client
 */

if (!hasInterface) exitWith {};

[] spawn {
    private _fnc_addRoeActions = {
        params ["_unit"];
        
        // Empêcher d'ajouter les actions en double
        if (_unit getVariable ["TAG_Action_Roe_Added", false]) exitWith {};
        _unit setVariable ["TAG_Action_Roe_Added", true];

        // Action : INFILTRATION (GHOST)
        _unit addAction [
            localize "STR_TAG_Action_RoE_Stealth",
            {
                params ["_target", "_caller"];
                private _grp = group _caller;
                _grp setCombatMode "BLUE";    // Ne tire jamais
                _grp setBehaviour "STEALTH";  // Chuchote, marche accroupi
                _grp setSpeedMode "LIMITED";  // Marche lente
                
                // Réactiver l'autocombat normal si on vient d'un mode ultra agressif
                { if (!isPlayer _x) then { _x enableAI "AUTOCOMBAT"; }; } forEach units _grp;
                
                systemChat localize "STR_TAG_Msg_RoE_Stealth";
            },
            nil, 6.4, false, true, "", 
            "leader group _target == _target && combatMode group _target != 'BLUE' && { { !isPlayer _x } count (units group _target) > 0 }"
        ];

        // Action : VIGILANCE (AWARE)
        _unit addAction [
            localize "STR_TAG_Action_RoE_Vigilance",
            {
                params ["_target", "_caller"];
                private _grp = group _caller;
                _grp setCombatMode "YELLOW";  // Tire à volonté
                _grp setBehaviour "AWARE";    // Déplacement normal, prêt au combat
                _grp setSpeedMode "NORMAL";   // Vitesse de croisière
                
                { if (!isPlayer _x) then { _x enableAI "AUTOCOMBAT"; }; } forEach units _grp;
                
                systemChat localize "STR_TAG_Msg_RoE_Vigilance";
            },
            nil, 6.3, false, true, "", 
            "leader group _target == _target && combatMode group _target != 'YELLOW' && { { !isPlayer _x } count (units group _target) > 0 }"
        ];

        // Action : ASSAUT (COMBAT)
        _unit addAction [
            localize "STR_TAG_Action_RoE_Assault",
            {
                params ["_target", "_caller"];
                private _grp = group _caller;
                _grp setCombatMode "RED";     // Engagement libre et tir à volonté
                _grp setBehaviour "COMBAT";   // Cherche à couvert, très réactif
                _grp setSpeedMode "NORMAL";
                
                { if (!isPlayer _x) then { _x enableAI "AUTOCOMBAT"; }; } forEach units _grp;
                
                systemChat localize "STR_TAG_Msg_RoE_Assault";
            },
            nil, 6.2, false, true, "", 
            "leader group _target == _target && (combatMode group _target != 'RED' || speedMode group _target != 'NORMAL') && { { !isPlayer _x } count (units group _target) > 0 }"
        ];

        // Action : ULTRA AGRESSIF (CHARGE)
        _unit addAction [
            localize "STR_TAG_Action_RoE_Charge",
            {
                params ["_target", "_caller"];
                private _grp = group _caller;
                _grp setCombatMode "RED";     // Engagement libre
                _grp setBehaviour "COMBAT";
                _grp setSpeedMode "FULL";     // Sprint
                
                // Désactiver "AUTOCOMBAT" oblige l'IA à ignorer la prudence. 
                // Ils ne s'arrêteront plus pour avancer prudemment d'un abri à l'autre, ils sprinteront vers l'objectif.
                { 
                    if (!isPlayer _x) then {
                        _x disableAI "AUTOCOMBAT"; 
                    };
                } forEach units _grp;
                
                systemChat localize "STR_TAG_Msg_RoE_Charge";
            },
            nil, 6.1, false, true, "", 
            "leader group _target == _target && (combatMode group _target != 'RED' || speedMode group _target != 'FULL') && { { !isPlayer _x } count (units group _target) > 0 }"
        ];
    };

    // Boucle de maintien en cas de switch d'IA ou respawn
    private _lastPlayer = objNull;
    while {true} do {
        waitUntil { sleep 1; player != _lastPlayer };  
        
        _lastPlayer = player;
        if (!isNull _lastPlayer) then {
            [_lastPlayer] call _fnc_addRoeActions;
        };
    };
};
