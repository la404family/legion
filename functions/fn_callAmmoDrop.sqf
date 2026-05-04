#include "..\macros.hpp"

/*
 * TAG_fnc_callAmmoDrop
 *
 * Description:
 *   Déploie un hélico logistique pour larguer une caisse de munitions.
 *   Le contenu de la caisse est généré dynamiquement à partir de
 *   l'équipement INITIAL sauvegardé des joueurs.
 *
 * Locality:
 *   Serveur
 */

if (!isServer) exitWith {};

params [
    ["_targetPos", [0,0,0], [[]]],
    ["_caller", objNull, [objNull]]
];

// Vérifier si un soutien est déjà en cours (Verrou partagé avec le CAS)
if (missionNamespace getVariable ["TAG_AirSupport_Active", false]) exitWith {
    private _snd = selectRandom ["negatif01", "negatif02", "negatif03", "negatif04"];
    [_snd] remoteExec ["playSound", _caller];
    (localize "STR_TAG_Msg_Ammo_Denied") remoteExec ["systemChat", _caller];
};

// Verrouiller l'espace aérien
missionNamespace setVariable ["TAG_AirSupport_Active", true, true];

if (count _targetPos < 2) then { _targetPos = getPos _caller; };
if (count _targetPos < 3) then { _targetPos set [2, 0]; };

private _spawnDist = 2000;
private _helicoClass = "B_AMF_Heli_Transport_01_F";  
private _vehClass = "B_supplyCrate_F";  
private _flyHeight = 150;
private _hoverHeight = 15; // Un peu plus haut que le CAS pour le slingload
private _dir = random 360;

// Audios d'acceptation
[] spawn {
    private _snd = selectRandom ["livraison01", "livraison02", "livraison03", "livraison04", "livraison05", "livraison06", "livraison07", "livraison08", "livraison09"];
    _snd remoteExec ["playSound", 0];
};
(localize "STR_TAG_Msg_Ammo_Approved") remoteExec ["systemChat", _caller];

private _spawnPos = _targetPos vectorAdd [(_spawnDist * (sin _dir)), (_spawnDist * (cos _dir)), _flyHeight];
if (count _spawnPos < 3) then { _spawnPos set [2, _flyHeight]; };

private _heli = objNull;
private _spawnAttempts = 0;
while {isNull _heli && _spawnAttempts < 5} do {
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
    (localize "STR_TAG_Msg_Ammo_Error") remoteExec ["systemChat", _caller];
};

// Équipage
private _group = createGroup [WEST, true];
private _crew = [];
private _pilot = _group createUnit ["B_Helipilot_F", [0,0,0], [], 0, "NONE"];
_pilot moveInDriver _heli;
_crew pushBack _pilot;
private _copilot = _group createUnit ["B_Helipilot_F", [0,0,0], [], 0, "NONE"];
_copilot moveInTurret [_heli, [0]];
_crew pushBack _copilot;

private _turrets = allTurrets _heli;
private _gunnerTurrets = _turrets select { _x isNotEqualTo [0] };  
{
    private _gunner = _group createUnit ["B_Soldier_F", [0,0,0], [], 0, "NONE"];
    _gunner moveInTurret [_heli, _x];
    _crew pushBack _gunner;
} forEach _gunnerTurrets;

_group setBehaviour "CARELESS";
_group setCombatMode "RED";
_group setSpeedMode "FULL";

{
    _x disableAI "FSM";        
    _x allowDamage false;      
} forEach _crew;

// Création de la caisse logistique
private _cargo = createVehicle [_vehClass, [0,0,0], [], 0, "NONE"];
_cargo setPos (_heli modelToWorld [0, 0, -15]);
_cargo allowDamage false;
private _originalMass = getMass _cargo;
_cargo setMass 500;  // Poids fixe pour stabiliser l'hélico
_heli setSlingLoad _cargo;

// Remplissage de la caisse selon les équipements initiaux
clearWeaponCargoGlobal _cargo;
clearMagazineCargoGlobal _cargo;
clearItemCargoGlobal _cargo;
clearBackpackCargoGlobal _cargo;

private _allWeapons = [];
private _allMagazines = [];
private _allItems = [];
private _allBackpacks = [];

private _legionUnits = [];
if (!isNil "player_0") then { _legionUnits pushBack player_0; };
if (!isNil "player_1") then { _legionUnits pushBack player_1; };
if (!isNil "player_2") then { _legionUnits pushBack player_2; };
if (!isNil "player_3") then { _legionUnits pushBack player_3; };
if (!isNil "player_4") then { _legionUnits pushBack player_4; };
if (!isNil "player_5") then { _legionUnits pushBack player_5; };
if (!isNil "player_6") then { _legionUnits pushBack player_6; };

{
    if (!isNull _x && side _x == west) then {
        // Lecture des variables définies par le serveur au début de la mission
        private _pw = _x getVariable ["TAG_Initial_Primary", primaryWeapon _x];
        private _sw = _x getVariable ["TAG_Initial_Secondary", secondaryWeapon _x];
        private _hw = _x getVariable ["TAG_Initial_Handgun", handgunWeapon _x];
        
        if (_pw != "") then { _allWeapons pushBackUnique _pw; };
        if (_sw != "") then { _allWeapons pushBackUnique _sw; };
        if (_hw != "") then { _allWeapons pushBackUnique _hw; };
        
        private _mags = _x getVariable ["TAG_Initial_Mags", magazines _x];
        { _allMagazines pushBackUnique _x; } forEach _mags;
        
        private _itm = _x getVariable ["TAG_Initial_Items", items _x + assignedItems _x];
        { _allItems pushBackUnique _x; } forEach _itm;
        
        private _bp = _x getVariable ["TAG_Initial_Backpack", backpack _x];
        if (_bp != "") then { _allBackpacks pushBackUnique _bp; };
    };
} forEach _legionUnits;

{ _cargo addWeaponCargoGlobal [_x, 2]; } forEach _allWeapons;
{ _cargo addMagazineCargoGlobal [_x, 20]; } forEach _allMagazines;
{ _cargo addItemCargoGlobal [_x, 5]; } forEach _allItems;
{ _cargo addBackpackCargoGlobal [_x, 2]; } forEach _allBackpacks;

_cargo addMagazineCargoGlobal ["SmokeShell", 10];
_cargo addMagazineCargoGlobal ["SmokeShellGreen", 10];
_cargo addItemCargoGlobal ["FirstAidKit", 20];

// Thread de vol et largage
[_heli, _cargo, _targetPos, _group, _crew, _spawnPos, _originalMass, _hoverHeight, _caller] spawn {
    params ["_heli", "_cargo", "_targetPos", "_group", "_crew", "_homeBase", "_originalMass", "_hoverHeight", "_caller"];
    
    private _dropPos = +_targetPos;
    
    // Recherche automatique d'un point plat et dégagé à moins de 500m
    if (count _dropPos >= 2) then {
        private _flatCheck = _dropPos isFlatEmpty [5, -1, 0.2, 5, 0, false, objNull];
        if (_flatCheck isEqualTo []) then {
            private _safePos = [_dropPos, 0, 150, 5, 0, 0.2, 0, [], _dropPos] call BIS_fnc_findSafePos;
            if (_safePos isEqualType [] && {count _safePos >= 2}) then {
                if (_safePos distance2D _dropPos < 500) then {
                    _dropPos = _safePos;
                    if (count _dropPos < 3) then { _dropPos set [2, 0]; };
                };
            };
        };
    };
    
    // Marqueur temporaire
    private _markerName = format ["livraison_mrk_ammo_%1", floor(random 10000)];
    private _marker = createMarker [_markerName, _dropPos];
    _marker setMarkerType "mil_pickup";
    _marker setMarkerColor "ColorBlue";
    _marker setMarkerText "Drop Logistique";
    
    [_marker] spawn {
        params ["_m"];
        sleep 120;
        deleteMarker _m;
    };
    
    // Vol vers la cible
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
    
    if (!alive _heli) exitWith { missionNamespace setVariable ["TAG_AirSupport_Active", false, true]; };
    
    deleteWaypoint [_group, 0];
    
    // Approche finale et vol stationnaire
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
        ((_heli distance2D _dropPos) < 5) || _positionTimeout > 30 || !alive _heli
    };
    
    if (!alive _heli) exitWith { missionNamespace setVariable ["TAG_AirSupport_Active", false, true]; };
    
    doStop _heli;
    _heli flyInHeight _hoverHeight;
    
    // Descente progressive du colis
    private _dropTimeout = 0;
    private _cargoGrounded = false;
    waitUntil {
        sleep 0.5;
        _dropTimeout = _dropTimeout + 0.5;
        private _newHeight = _hoverHeight - _dropTimeout;
        if (_newHeight < 5) then { _newHeight = 5; };
        
        _heli flyInHeight _newHeight;
        _heli flyInHeightASL [_newHeight, _newHeight, _newHeight];
        
        _cargoGrounded = (getPosATL _cargo select 2) < 3;
        if ((getPosATL _heli select 2) < 4) then {
            _cargoGrounded = true;
        };
        _cargoGrounded || _dropTimeout > 30 || !alive _heli || !alive _cargo
    };
    
    if (!alive _heli || !alive _cargo) exitWith { missionNamespace setVariable ["TAG_AirSupport_Active", false, true]; };
    
    private _dropTime = time;
    sleep 1;
    
    // Détachement
    private _allRopes = ropes _heli;
    { ropeDestroy _x; } forEach _allRopes;
    _heli setSlingLoad objNull;
    
    sleep 1;
    _cargo setVelocity [0, 0, 0];
    _cargo setVectorUp [0, 0, 1];
    _cargo setMass _originalMass;
    _cargo allowDamage true;
    
    (localize "STR_TAG_Msg_Ammo_Dropped") remoteExec ["systemChat", _caller];
    
    // Fumigène de signalisation et nettoyage différé avec effet visuel
    [_cargo] spawn {
        params ["_crate"];
        private _smoke = createVehicle ["SmokeShellGreen", getPos _crate, [], 0, "CAN_COLLIDE"];
        
        sleep 590;  // Attend 9 minutes et 50 secondes
        
        if (alive _crate) then {
            // Créer une fumée blanche épaisse autour de la caisse pour masquer sa disparition
            for "_i" from 0 to 360 step 45 do {
                private _smokePos = _crate getPos [2, _i];
                createVehicle ["SmokeShell", _smokePos, [], 0, "CAN_COLLIDE"];
            };
            
            sleep 10; // Laisse le temps à la fumée de s'épaissir
            
            if (alive _crate) then { 
                deleteVehicle _crate; 
            };
        };
    };
    
    sleep 1;
    
    while {(count (waypoints _group)) > 0} do {
        deleteWaypoint [_group, 0];
    };
    
    // Départ
    _heli flyInHeight 150;
    private _wpHome = _group addWaypoint [_homeBase, 0];
    _wpHome setWaypointType "MOVE";
    _wpHome setWaypointBehaviour "CARELESS";
    _wpHome setWaypointSpeed "FULL";
    _heli doMove _homeBase;
    
    // Libération immédiate de la variable de support
    missionNamespace setVariable ["TAG_AirSupport_Active", false, true];
    
    waitUntil {
        sleep 5;
        (_heli distance2D _targetPos > 1500) || !alive _heli || (time - _dropTime > 180)
    };
    
    { deleteVehicle _x } forEach _crew;
    deleteVehicle _heli;
    deleteGroup _group;
};
