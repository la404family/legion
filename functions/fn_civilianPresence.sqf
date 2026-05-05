#include "..\macros.hpp"

/*
 * TAG_fnc_civilianPresence
 *
 * Description:
 *   Spawns civilians around players continuously and cleans them up when too far.
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

if (isNil "TAG_CiviliansSpawned") then { TAG_CiviliansSpawned = []; };

private _spawnDistance = 500; // Mètres
private _cleanupDistance = 1200; // Mètres
private _maxCivilians = 55; // Nombre maximum de civils en même temps

while {true} do {
    // Nettoyage
    {
        private _civ = _x;
        if (!isNull _civ) then {
            private _farFromAll = true;
            {
                if (isPlayer _x && {(_x distance2D _civ) < _cleanupDistance}) exitWith { _farFromAll = false; };
            } forEach allPlayers;

            if (_farFromAll) then {
                deleteVehicle _civ;
            };
        };
    } forEach TAG_CiviliansSpawned;
    TAG_CiviliansSpawned = TAG_CiviliansSpawned - [objNull];

    // Spawn
    if (count TAG_CiviliansSpawned < _maxCivilians) then {
        // Sélectionner un joueur au hasard
        private _players = allPlayers select { alive _x };
        if (count _players > 0) then {
            private _refPlayer = selectRandom _players;
            private _refPos = getPosATL _refPlayer;

            // Trouver des bâtiments
            private _buildings = nearestObjects [_refPos, ["House", "Building"], _spawnDistance];
            // Filtrer les bâtiments trop proches (ex: pas à moins de 400m)
            _buildings = _buildings select { (_x distance2D _refPlayer) > 400 };

            if (count _buildings > 0) then {
                private _building = selectRandom _buildings;
                private _bPosList = _building buildingPos -1;
                
                if (count _bPosList > 0) then {
                    private _bPos = selectRandom _bPosList;
                    // Ajouter 0.5 en Z
                    _bPos set [2, (_bPos select 2) + 0.5];

                    // Obtenir une classe
                    private _class = "C_man_1";
                    if (!isNil "MISSION_CivilianTemplates" && {count MISSION_CivilianTemplates > 0}) then {
                        private _template = selectRandom MISSION_CivilianTemplates;
                        _class = _template select 0;
                    };

                    private _grp = createGroup civilian;
                    private _civ = _grp createUnit [_class, _bPos, [], 0, "NONE"]; // Utilise setPosATL/ASL en interne, le Z posé à 0.5 aide.
                    _civ setPosASL (AGLToASL _bPos); // Force la position sécurisée

                    TAG_CiviliansSpawned pushBack _civ;

                    // Patrouille
                    [_grp, getPosATL _civ, 200] call BIS_fnc_taskPatrol;
                };
            };
        };
    };

    sleep 10;
};
