#include "..\macros.hpp"

/*
 * TAG_fnc_callVehicleDelivery
 *
 * Description:
 *   Déploie un hélicoptère logistique pour livrer un véhicule tactique par élingage.
 *   La position de livraison est calculée automatiquement : on recherche la route
 *   la plus proche du centre de masse de tous les joueurs actifs sur le serveur.
 *   Si aucune route n'est trouvée dans le rayon, une position plate dégagée est
 *   utilisée en repli.
 *
 * Arguments:
 *   0: <ARRAY>  Position cible (indice de visée du demandeur) — hint initial
 *   1: <OBJECT> Demandeur (joueur leader)
 *
 * Return Value:
 *   None
 *
 * Locality:
 *   Serveur
 *
 * Public:
 *   No
 *
 * Example:
 *   [screenToWorld [0.5, 0.5], player] remoteExec ["TAG_fnc_callVehicleDelivery", 2];
 */

if (!isServer) exitWith {};

params [
    ["_targetPos", [0,0,0], [[]]],
    ["_caller", objNull, [objNull]]
];

// Vérifier si un soutien aérien est déjà en cours (verrou partagé CAS / Ammo / Véhicule)
if (missionNamespace getVariable ["TAG_AirSupport_Active", false]) exitWith {
    private _snd = selectRandom ["negatif01", "negatif02", "negatif03", "negatif04"];
    [_snd] remoteExec ["playSound", _caller];
    (localize "STR_TAG_Msg_Vehicle_Denied") remoteExec ["systemChat", _caller];
};

// Verrouiller l'espace aérien
missionNamespace setVariable ["TAG_AirSupport_Active", true, true];

if (count _targetPos < 2) then { _targetPos = getPos _caller; };
if (count _targetPos < 3) then { _targetPos set [2, 0]; };

// ── Classe du véhicule (requise pour findEmptyPosition) ─────────────────────
private _vehClass = "AMF_GBC180_PERS_03";

// ── Calcul intelligent de la position de livraison ──────────────────────────
// Centre de masse des joueurs actifs → recherche d'une route propre et dégagée.

private _activePlayers = allPlayers select { alive _x };
if (count _activePlayers == 0) then { _activePlayers = [_caller]; };

private _centerPos = [0, 0, 0];
{ _centerPos = _centerPos vectorAdd getPos _x; } forEach _activePlayers;
_centerPos = _centerPos vectorMultiply (1 / (count _activePlayers));
if (count _centerPos < 3) then { _centerPos set [2, 0]; };

private _dropPos       = +_centerPos;
private _foundGoodRoad = false;

// Fonction locale : teste une liste de routes et retourne la première position propre
private _fnc_testRoads = {
    params ["_roadList", "_strict"];
    private _checkRadius = if (_strict) then { 12 } else { 8 };
    private _badTypes = ["TREE", "SMALL TREE", "BUSH", "ROCK", "ROCKS", "HIDE",
                         "BUILDING", "HOUSE", "WALL", "FENCE"];
    {
        if (_foundGoodRoad) exitWith {};
        private _road    = _x;
        private _roadPos = getPos _road;
        if (!isOnRoad _roadPos) then { continue };

        for "_offset" from -15 to 15 step 5 do {
            if (_foundGoodRoad) exitWith {};

            // Calcul de la position le long du segment de route
            private _roadDir = getDir _road;
            private _testPos = [
                (_roadPos select 0) + _offset * sin(_roadDir),
                (_roadPos select 1) + _offset * cos(_roadDir),
                0
            ];

            if (surfaceIsWater _testPos) then { continue };
            if (!isOnRoad _testPos)      then { continue };

            // Vérification directe des obstacles terrain autour du point
            private _nearBad = nearestTerrainObjects [_testPos, _badTypes, _checkRadius, false, true];
            if (count _nearBad > 0) then { continue };

            // Recherche d'une position vide pour le véhicule
            private _emptyPos = _testPos findEmptyPosition [0, _checkRadius, _vehClass];
            if (count _emptyPos > 0 && { _emptyPos distance2D _testPos <= _checkRadius }) then {
                _dropPos = _emptyPos;
                _dropPos set [2, 0];
                _foundGoodRoad = true;
            };
        };
    } forEach _roadList;
};

// Passe 1 : routes larges et proches (rayon 800 m — critères stricts)
private _allRoads = _centerPos nearRoads 800;
_allRoads = [_allRoads, [], {
    private _info = getRoadInfo _x;
    (_info select 1) + (10000 / ((_x distance2D _centerPos) max 1))
}, "DESCEND"] call BIS_fnc_sortBy;
[_allRoads, true] call _fnc_testRoads;

// Passe 2 : rayon élargi à 2000 m — critères légèrement souples
if (!_foundGoodRoad) then {
    _allRoads = _centerPos nearRoads 2000;
    _allRoads = [_allRoads, [], { _x distance2D _centerPos }, "ASCEND"] call BIS_fnc_sortBy;
    [_allRoads, false] call _fnc_testRoads;
};

// Repli ultime : position plate dégagée sans route
if (!_foundGoodRoad) then {
    private _safePos = [_centerPos, 0, 300, 10, 0, 0.35, 0, [], _centerPos] call BIS_fnc_findSafePos;
    if (_safePos isEqualType [] && { count _safePos >= 2 } && { _safePos distance2D _centerPos < 1200 }) then {
        _dropPos = _safePos;
    };
    _dropPos set [2, 0];
};

// ── Paramètres de vol ────────────────────────────────────────────────────────
private _spawnDist   = 2000;
private _helicoClass = "B_AMF_Heli_Transport_01_F";
private _flyHeight   = 150;
private _hoverHeight = 10;
private _dir         = random 360;

private _spawnPos = _dropPos vectorAdd [(_spawnDist * (sin _dir)), (_spawnDist * (cos _dir)), _flyHeight];
if (count _spawnPos < 3) then { _spawnPos set [2, _flyHeight]; };

// ── Spawn de l'hélicoptère ───────────────────────────────────────────────────
private _heli = objNull;
private _spawnAttempts = 0;
while { isNull _heli && _spawnAttempts < 5 } do {
    _spawnAttempts = _spawnAttempts + 1;
    _heli = createVehicle [_helicoClass, _spawnPos, [], 0, "FLY"];
    if (!isNull _heli) then {
        _heli setPos _spawnPos;
        _heli setDir (_dir + 180);
        _heli flyInHeight _flyHeight;
        _heli allowDamage false;
    } else {
        sleep 1;
    };
};

if (isNull _heli) exitWith {
    missionNamespace setVariable ["TAG_AirSupport_Active", false, true];
    (localize "STR_TAG_Msg_Vehicle_Error") remoteExec ["systemChat", _caller];
};

// ── Équipage ─────────────────────────────────────────────────────────────────
private _group = createGroup [WEST, true];
private _crew  = [];

private _pilot = _group createUnit ["B_Helipilot_F", [0,0,0], [], 0, "NONE"];
_pilot moveInDriver _heli;
_crew pushBack _pilot;

private _copilot = _group createUnit ["B_Helipilot_F", [0,0,0], [], 0, "NONE"];
_copilot moveInTurret [_heli, [0]];
_crew pushBack _copilot;

private _turrets       = allTurrets _heli;
private _gunnerTurrets = _turrets select { _x isNotEqualTo [0] };
{
    private _gunner = _group createUnit ["B_Soldier_F", [0,0,0], [], 0, "NONE"];
    _gunner moveInTurret [_heli, _x];
    _crew pushBack _gunner;
} forEach _gunnerTurrets;

_group setBehaviour "CARELESS";
_group setCombatMode "RED";
_group setSpeedMode "FULL";

{ _x disableAI "FSM"; _x allowDamage false; } forEach _crew;

// ── Véhicule en élingage ─────────────────────────────────────────────────────
private _cargo       = createVehicle [_vehClass, [0,0,0], [], 0, "NONE"];
_cargo setPos (_heli modelToWorld [0, 0, -15]);
_cargo allowDamage false;
private _originalMass = getMass _cargo;
_cargo setMass 800;
_heli setSlingLoad _cargo;

// ── Audio d'acceptation ──────────────────────────────────────────────────────
[] spawn {
    private _snd = selectRandom ["livraison01", "livraison02", "livraison03", "livraison04", "livraison05", "livraison06", "livraison07", "livraison08", "livraison09"];
    _snd remoteExec ["playSound", 0];
};
(localize "STR_TAG_Msg_Vehicle_Approved") remoteExec ["systemChat", _caller];

// ── Thread de vol et livraison ───────────────────────────────────────────────
[_heli, _cargo, _dropPos, _group, _crew, _spawnPos, _originalMass, _hoverHeight, _caller] spawn {
    params ["_heli", "_cargo", "_dropPos", "_group", "_crew", "_homeBase", "_originalMass", "_hoverHeight", "_caller"];

    // Marqueur temporaire sur la zone de livraison
    private _markerName = format ["vehicle_delivery_mrk_%1", floor(random 10000)];
    private _marker = createMarker [_markerName, _dropPos];
    _marker setMarkerType "mil_pickup";
    _marker setMarkerColor "ColorBlue";
    _marker setMarkerText (localize "STR_TAG_Msg_Vehicle_Marker");
    [_marker] spawn {
        params ["_m"];
        sleep 120;
        deleteMarker _m;
    };

    // ── Phase 1 : Approche longue distance ──────────────────────────────────
    private _wp1 = _group addWaypoint [_dropPos, 0];
    _wp1 setWaypointType "MOVE";
    _wp1 setWaypointBehaviour "CARELESS";
    _wp1 setWaypointSpeed "FULL";
    _heli doMove _dropPos;

    private _approachTimeout = 0;
    waitUntil {
        sleep 1;
        _approachTimeout = _approachTimeout + 1;
        ((_heli distance2D _dropPos) < 200) || _approachTimeout > 180 || !alive _heli
    };

    if (!alive _heli) exitWith {
        missionNamespace setVariable ["TAG_AirSupport_Active", false, true];
    };

    deleteWaypoint _wp1;

    // ── Phase 2 : Approche finale à basse altitude ───────────────────────────
    _heli flyInHeight _hoverHeight;
    _heli flyInHeightASL [_hoverHeight, _hoverHeight, _hoverHeight];

    private _wp2 = _group addWaypoint [_dropPos, 0];
    _wp2 setWaypointType "MOVE";
    _wp2 setWaypointBehaviour "CARELESS";
    _wp2 setWaypointSpeed "FULL";
    _heli doMove _dropPos;

    private _positionTimeout = 0;
    waitUntil {
        sleep 0.5;
        _positionTimeout = _positionTimeout + 0.5;
        ((_heli distance2D _dropPos) < 3) || _positionTimeout > 30 || !alive _heli
    };

    if (!alive _heli) exitWith {
        missionNamespace setVariable ["TAG_AirSupport_Active", false, true];
    };

    doStop _heli;
    _heli flyInHeight _hoverHeight;

    // ── Phase 3 : Descente progressive et largage ────────────────────────────
    private _dropTimeout   = 0;
    private _cargoGrounded = false;
    waitUntil {
        sleep 0.5;
        _dropTimeout = _dropTimeout + 0.5;
        private _newHeight = _hoverHeight - _dropTimeout;
        if (_newHeight < 5) then { _newHeight = 5; };
        _heli flyInHeight _newHeight;
        _heli flyInHeightASL [_newHeight, _newHeight, _newHeight];
        _cargoGrounded = (getPosATL _cargo select 2) < 3;
        if ((getPosATL _heli select 2) < 4) then { _cargoGrounded = true; };
        _cargoGrounded || _dropTimeout > 30 || !alive _heli || !alive _cargo
    };

    if (!alive _heli || !alive _cargo) exitWith {
        missionNamespace setVariable ["TAG_AirSupport_Active", false, true];
    };

    private _dropTime = time;
    sleep 1;

    // Détachement du véhicule
    private _allRopes = ropes _heli;
    { ropeDestroy _x; } forEach _allRopes;
    _heli setSlingLoad objNull;

    sleep 1;
    _cargo setVelocity [0, 0, 0];
    _cargo setVectorUp [0, 0, 1];
    _cargo setMass _originalMass;
    _cargo allowDamage true;
    // Le véhicule reste sur la carte indéfiniment (nettoyage géré séparément)

    (localize "STR_TAG_Msg_Vehicle_Dropped") remoteExec ["systemChat", _caller];

    // Libération immédiate du verrou aérien
    missionNamespace setVariable ["TAG_AirSupport_Active", false, true];

    // ── Phase 4 : Retour à la base ───────────────────────────────────────────
    while { (count (waypoints _group)) > 0 } do {
        deleteWaypoint [_group, 0];
    };

    _heli flyInHeight 150;
    private _wpHome = _group addWaypoint [_homeBase, 0];
    _wpHome setWaypointType "MOVE";
    _wpHome setWaypointBehaviour "CARELESS";
    _wpHome setWaypointSpeed "FULL";
    _heli doMove _homeBase;

    waitUntil {
        sleep 5;
        (_heli distance2D _dropPos > 1500) || !alive _heli || (time - _dropTime > 180)
    };

    { deleteVehicle _x } forEach _crew;
    deleteVehicle _heli;
    deleteGroup _group;
};
