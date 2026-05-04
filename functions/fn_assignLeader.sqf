#include "..\macros.hpp"

/*
 * TAG_fnc_assignLeader
 *
 * Description:
 *   Checks if the leader slot (player_0) is empty and there are less than 7 players.
 *   If so, randomly selects a present player to become the new leader and groups everyone under them.
 *
 * Arguments:
 *   None
 *
 * Return Value:
 *   None
 *
 * Locality:
 *   Server
 */

if (!isServer) exitWith {};

// Wait for mission start and players to be initialized
waitUntil { time > 0 };

// Give a short delay to ensure players from the lobby are fully loaded
sleep 2;

private _players = allPlayers - entities "HeadlessClient_F";

if (count _players == 0) exitWith {};

private _defaultLeader = missionNamespace getVariable ["player_0", objNull];
private _leaderSlotTaken = isPlayer _defaultLeader;

if (!_leaderSlotTaken && {count _players < 7}) then {
    private _newLeader = selectRandom _players;
    
    // Re-group all players to the new leader
    _players joinSilent _newLeader;
    (group _newLeader) selectLeader _newLeader;
    
    if (DEBUG_MODE) then {
        diag_log format ["[TAG] assignLeader: Default leader (player_0) absent. Assigned %1 as new leader.", name _newLeader];
    };
    
    // Notify players
    [format [localize "STR_TAG_Msg_Leader_Assigned", name _newLeader]] remoteExec ["systemChat", 0];
} else {
    if (DEBUG_MODE) then {
        diag_log "[TAG] assignLeader: Leader slot is taken or 7 players are present.";
    };
};
