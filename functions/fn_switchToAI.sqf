#include "..\macros.hpp"

/*
 * TAG_fnc_switchToAI
 *
 * Description:
 *   Bascule le joueur vers une IA vivante de son escouade lors de sa mort.
 *
 * Arguments:
 *   0: <OBJECT> L'unité morte du joueur
 *
 * Locality:
 *   Client
 */

params [
    ["_deadUnit", objNull, [objNull]]
];

if (!hasInterface) exitWith {};

private _group = group _deadUnit;

// Laisse un petit délai pour l'animation de mort et pour que le jeu s'actualise
sleep 3;

// Trouver toutes les I.A vivantes du groupe (unités non-joueurs)
private _livingAI = (units _group) select { alive _x && {!isPlayer _x} };

if (count _livingAI > 0) then {
    private _targetAI = selectRandom _livingAI;
    
    // Demander au serveur de nous donner la propriété (locality) de cette I.A
    // clientOwner retourne l'ID réseau de notre client
    [_targetAI, clientOwner] remoteExec ["TAG_fnc_transferLocality", 2];
    
    // Attendre que l'I.A devienne locale pour nous (avec un timeout de sécurité de 5 secondes)
    private _timeout = time + 5;
    waitUntil { local _targetAI || time > _timeout };
    
    if (local _targetAI) then {
        // Prendre le contrôle de la nouvelle I.A
        selectPlayer _targetAI;
        
        // Une I.A ne doit jamais être leader s'il y a un joueur.
        // Si le leader actuel est une I.A, le joueur prend le commandement.
        if (!isPlayer (leader _group)) then {
            _group selectLeader _targetAI;
        };
        
        // Comme nous habitons un nouveau "corps", il faut lui réattacher l'Event Handler "Killed"
        // pour que le système fonctionne s'il meurt à nouveau
        player addEventHandler ["Killed", {
            params ["_unit", "_killer", "_instigator", "_useEffects"];
            
            if (leader (group _unit) == _unit) then {
                [group _unit, _unit] remoteExec ["TAG_fnc_manageLeadership", 2];
            };
            
            [_unit] spawn TAG_fnc_switchToAI;
        }];
        
        systemChat localize "STR_TAG_Msg_Switch_Success";
        
        if (DEBUG_MODE) then {
            diag_log format ["[TAG] switchToAI: Joueur a basculé vers %1", _targetAI];
        };
    } else {
        systemChat localize "STR_TAG_Msg_Switch_Error";
    };
} else {
    systemChat localize "STR_TAG_Msg_Switch_Dead";
};
