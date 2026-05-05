#include "..\macros.hpp"

/*
 * TAG_fnc_initServer
 *
 * Description:
 *   Server-only init logic.
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

if (DEBUG_MODE) then {
    diag_log "[TAG] Server Initialization Started.";
};

// Server logic here (spawn units, setup variables, etc.)
[] spawn TAG_fnc_assignLeader;
[] spawn TAG_fnc_identityManager;
[] spawn TAG_fnc_badgeManager;
[] spawn TAG_fnc_callToPrayer;

// Sauvegarde de l'équipement initial de toute l'escouade (Joueurs ET I.A.) pour les livraisons de munitions
private _legionUnits = [];
if (!isNil "player_0") then { _legionUnits pushBack player_0; };
if (!isNil "player_1") then { _legionUnits pushBack player_1; };
if (!isNil "player_2") then { _legionUnits pushBack player_2; };
if (!isNil "player_3") then { _legionUnits pushBack player_3; };
if (!isNil "player_4") then { _legionUnits pushBack player_4; };
if (!isNil "player_5") then { _legionUnits pushBack player_5; };
if (!isNil "player_6") then { _legionUnits pushBack player_6; };

{
    if (!isNull _x) then {
        _x setVariable ["TAG_Initial_Primary", primaryWeapon _x, true];
        _x setVariable ["TAG_Initial_Secondary", secondaryWeapon _x, true];
        _x setVariable ["TAG_Initial_Handgun", handgunWeapon _x, true];
        _x setVariable ["TAG_Initial_Mags", magazines _x, true];
        _x setVariable ["TAG_Initial_Items", items _x + assignedItems _x, true];
        _x setVariable ["TAG_Initial_Backpack", backpack _x, true];
    };
} forEach _legionUnits;

if (DEBUG_MODE) then {
    diag_log "[TAG] Server Initialization Finished.";
};
