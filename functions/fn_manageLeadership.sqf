#include "..\macros.hpp"

/*
 * TAG_fnc_manageLeadership
 *
 * Description:
 *   Gère le transfert de commandement lorsqu'un leader de groupe meurt.
 *   Sélectionne un nouveau joueur comme leader et notifie le groupe.
 *
 * Arguments:
 *   0: <GROUP> Le groupe concerné
 *   1: <OBJECT> L'ancien leader qui vient de mourir
 *
 * Return Value:
 *   None
 *
 * Locality:
 *   Server
 */

params [
    ["_group", grpNull, [grpNull]],
    ["_oldLeader", objNull, [objNull]]
];

if (!isServer) exitWith {};
if (isNull _group) exitWith {};

// On utilise spawn pour pouvoir attendre un instant (sleep)
[_group, _oldLeader] spawn {
    params ["_group", "_oldLeader"];
    
    // On laisse une seconde au moteur Arma 3 pour actualiser l'état du groupe
    sleep 1;
    
    // Trouver les joueurs en vie dans le groupe
    private _livingPlayers = (units _group) select { alive _x && isPlayer _x && _x != _oldLeader };
    
    // S'il reste des joueurs en vie dans le groupe
    if (count _livingPlayers > 0) then {
        private _newLeader = leader _group;
        
        // Si le moteur a nommé une IA ou n'a pas actualisé le leader, on force un joueur
        if (!alive _newLeader || !isPlayer _newLeader) then {
            _newLeader = selectRandom _livingPlayers;
            _group selectLeader _newLeader;
        };
        
        // Notification aux membres du groupe
        private _msg = format [localize "STR_TAG_Msg_Leader_Fallen", name _oldLeader, name _newLeader];
        [_msg] remoteExec ["systemChat", _livingPlayers];
        
        if (DEBUG_MODE) then {
            diag_log format ["[TAG] manageLeadership: Ancien leader %1 mort. Nouveau leader: %2", name _oldLeader, name _newLeader];
        };
    } else {
        if (DEBUG_MODE) then {
            diag_log format ["[TAG] manageLeadership: Le leader %1 est mort, mais plus aucun joueur en vie dans le groupe.", name _oldLeader];
        };
    };
};
