#include "..\macros.hpp"

/*
 * TAG_fnc_task03
 *
 * Description:
 *   Tâche 03 — Exfiltration d'otage.
 *   Un civil est retenu prisonnier dans l'une de 3 zones de recherche.
 *   Chaque zone est gardée par 8 ennemis qui patrouillent autour du bâtiment.
 *   Le joueur doit localiser l'otage, le libérer via une action de maintien,
 *   puis assurer l'extraction par hélicoptère jusqu'à l'exfiltration complète.
 *
 *   Déroulement :
 *     1. 3 zones de recherche sélectionnées dynamiquement (bâtiments).
 *     2. L'otage est placé dans une zone aléatoire (animation d'exécution).
 *     3. 8 gardes par zone patrouillent autour du bâtiment.
 *     4. Action de maintien "Libérer l'otage" → animation → l'otage suit le groupe.
 *     5. Un hélicoptère d'extraction est dépêché vers une LZ proche.
 *     6. L'otage monte automatiquement dans l'hélicoptère.
 *     7. Sécurité : le décollage est bloqué si un joueur est à bord.
 *     8. Succès si l'hélico décolle avec l'otage vivant.
 *        Échec si l'otage meurt ou si tout l'équipage est tué.
 *        Dans les deux cas, on enchaîne sur la tâche suivante.
 *
 * Arguments:
 *   None
 *
 * Return Value:
 *   None
 *
 * Locality:
 *   Server uniquement (isServer)
 *
 * Example:
 *   [] call TAG_fnc_task03;
 */

if (!isServer) exitWith {};

// Attendre que le système de templates civils soit prêt
waitUntil { !isNil "MISSION_fnc_applyCivilianTemplate" };

// ── Son de briefing ───────────────────────────────────────────────────────────
private _snd = selectRandom ["task03_01", "task03_02", "task03_03"];
[_snd] remoteExec ["playSound", 0];

// ── Scénario principal ────────────────────────────────────────────────────────
[] spawn {

    // Attendre qu'au moins un joueur WEST soit actif
    waitUntil {
        sleep 1;
        (count (allPlayers select { side _x == west && alive _x })) > 0
    };

    private _westPlayers = allPlayers select { side _x == west && alive _x };
    private _leaderUnit  = leader (group (_westPlayers select 0));
    private _leaderPos   = getPos _leaderUnit;

    // ── Recherche dynamique : rayon croissant depuis 300m jusqu'à trouver 3 bâtiments ─
    private _candidates   = [];
    private _searchRadius = 300;
    private _minDist      = 200;

    while { (count _candidates < 3) && (_searchRadius <= 2000) } do {
        _candidates = nearestTerrainObjects [
            _leaderPos,
            ["House", "Building", "HouseBase", "Church", "Ruin"],
            _searchRadius,
            false
        ] select {
            (_x distance2D _leaderPos > _minDist)
            && { (_x buildingPos 0) distance [0,0,0] > 1 }
        };

        if (count _candidates < 3) then {
            _searchRadius = _searchRadius + 150;
            if (DEBUG_MODE) then {
                diag_log format ["[TAG] task03: Rayon étendu à %1m — %2 bâtiment(s) valide(s).", _searchRadius, count _candidates];
            };
        };
    };

    if (count _candidates < 3) exitWith {
        (localize "STR_TAG_Task_03_Error") remoteExec ["systemChat", 0];
        if (DEBUG_MODE) then {
            diag_log "[TAG] task03: ERREUR — pas assez de bâtiments valides même au rayon max (2000m).";
        };
    };

    // ── Sélection de 3 bâtiments bien espacés (>150m entre eux) ──────────────
    private _selectedBuildings = [];
    private _pool = +_candidates;

    while { count _selectedBuildings < 3 && count _pool > 0 } do {
        private _pick = selectRandom _pool;
        _pool = _pool - [_pick];
        if ((_selectedBuildings findIf { _x distance2D _pick < 150 }) == -1) then {
            _selectedBuildings pushBack _pick;
        };
    };

    // Fallback : compléter sans contrainte d'espacement si pool épuisé
    if (count _selectedBuildings < 3) then {
        {
            if !(_x in _selectedBuildings) then { _selectedBuildings pushBack _x; };
            if (count _selectedBuildings >= 3) exitWith {};
        } forEach _candidates;
    };

    if (DEBUG_MODE) then {
        { diag_log format ["[TAG] task03: Zone %1 — %2 — %3m.", _forEachIndex + 1, typeOf _x, round (_x distance2D _leaderPos)]; } forEach _selectedBuildings;
    };

    // ── Sélection de la zone de l'otage (aléatoire parmi les 3) ──────────────
    private _hostageBuilding = selectRandom _selectedBuildings;
    private _hostagePos = _hostageBuilding buildingPos 0;
    if (_hostagePos isEqualTo [0,0,0]) then { _hostagePos = getPos _hostageBuilding; };

    // ── Spawn de l'otage ──────────────────────────────────────────────────────
    private _civGrp  = createGroup [civilian, true];
    private _hostage = _civGrp createUnit ["C_man_polo_1_F", ASLToAGL (ATLToASL _hostagePos), [], 0, "NONE"];
    _hostage setPosASL [_hostagePos select 0, _hostagePos select 1, (getTerrainHeightASL _hostagePos) + 0.1];

    if (!isNil "MISSION_fnc_applyCivilianTemplate") then {
        [_hostage] call MISSION_fnc_applyCivilianTemplate;
    };

    removeAllWeapons _hostage;
    removeBackpack _hostage;
    _hostage setCaptive true;
    _hostage disableAI "ANIM";
    _hostage disableAI "MOVE";
    _hostage disableAI "AUTOTARGET";
    _hostage disableAI "TARGET";
    _hostage allowFleeing 0;
    [_hostage, "Acts_ExecutionVictim_Loop"] remoteExec ["switchMove", 0];
    _hostage setVariable ["TAG_Task03_IsCaptive", true, true];

    if (DEBUG_MODE) then {
        diag_log format ["[TAG] task03: Otage créé — %1 — zone %2.", typeOf _hostage, typeOf _hostageBuilding];
    };

    // ── Spawn des gardes (8 par zone) ─────────────────────────────────────────
    private _allGroups  = [];
    private _allMarkers = [];

    {
        private _bld    = _x;
        private _bldPos = _bld buildingPos 0;
        if (_bldPos isEqualTo [0,0,0]) then { _bldPos = getPos _bld; };

        // 8 gardes par zone — tous dans un seul groupe pour la patrouille groupée
        private _guardGrp = createGroup [east, true];
        _allGroups pushBack _guardGrp;

        for "_j" from 1 to 8 do {
            private _gPos = _bldPos vectorAdd [(random 20) - 10, (random 20) - 10, 0];
            private _guard = _guardGrp createUnit ["O_Soldier_F", _gPos, [], 0, "NONE"];
            _guard setPosASL [_gPos select 0, _gPos select 1, (getTerrainHeightASL _gPos) + 0.5];
            _guard allowDamage false;
            [_guard] spawn { sleep 2; (_this select 0) allowDamage true; };

            if (!isNil "MISSION_fnc_applyCivilianTemplate") then {
                [_guard] call MISSION_fnc_applyCivilianTemplate;
            };
        };

        [_guardGrp, _bldPos, 35] call BIS_fnc_taskPatrol;

        // Marqueur zone de recherche (cercle orange)
        private _mID = format ["TAG_task03_zone_%1", _forEachIndex];
        deleteMarker _mID;
        createMarker [_mID, _bldPos];
        _mID setMarkerShape "ELLIPSE";
        _mID setMarkerSize [80, 80];
        _mID setMarkerColor "ColorOrange";
        _mID setMarkerAlpha 0.4;
        _mID setMarkerText (localize "STR_TAG_Task_03_ZoneMarker");
        _allMarkers pushBack _mID;

    } forEach _selectedBuildings;

    // ── Initialisation des variables globales ─────────────────────────────────
    missionNamespace setVariable ["TAG_Task03_Freed",    false, true];
    missionNamespace setVariable ["TAG_Task03_Complete", false, true];
    missionNamespace setVariable ["TAG_Task03_Failed",   false, true];

    // ── Tâche BIS ─────────────────────────────────────────────────────────────
    [
        west,
        ["task_03_hostage"],
        [
            localize "STR_TAG_Task_03_Desc",
            localize "STR_TAG_Task_03_Title",
            localize "STR_TAG_Task_03_Marker"
        ],
        _hostagePos,
        "AUTOASSIGNED",
        5,
        true,
        "rescue"
    ] call BIS_fnc_taskCreate;

    if (DEBUG_MODE) then { diag_log "[TAG] task03: Tâche créée."; };

    // Publier l'otage pour que fn_task03_addAction puisse y accéder côté client
    TAG_Task03_Hostage = _hostage;
    publicVariable "TAG_Task03_Hostage";

    // Délai court pour que publicVariable se propage, puis ajouter la hold action
    sleep 1;
    [] remoteExec ["TAG_fnc_task03_addAction", 0];

    // ── Surveiller la libération et la mort de l'otage ────────────────────────
    waitUntil {
        sleep 1;
        (missionNamespace getVariable ["TAG_Task03_Freed", false])
        || !alive _hostage
    };

    // ── Otage mort avant libération → FAILED ─────────────────────────────────
    if (!alive _hostage) exitWith {
        if (DEBUG_MODE) then { diag_log "[TAG] task03: Otage mort avant libération — FAILED."; };
        missionNamespace setVariable ["TAG_Task03_Failed", true, true];
        ["task_03_hostage", "FAILED", true] remoteExec ["BIS_fnc_taskSetState", 0];
        { deleteMarker _x; } forEach _allMarkers;
        { { if (alive _x) then { deleteVehicle _x; }; } forEach (units _x); } forEach _allGroups;
    };

    // ── Libération confirmée ──────────────────────────────────────────────────
    if (DEBUG_MODE) then { diag_log "[TAG] task03: Otage libéré — début extraction."; };

    // Passer la tâche en ASSIGNED (sous-objectif : extraction)
    ["task_03_hostage", "ASSIGNED"] call BIS_fnc_taskSetState;

    // Animation de libération sur tous les clients
    [_hostage, "Acts_ExecutionVictim_Unbow"] remoteExec ["switchMove", 0];
    sleep 8.5;

    // Réactiver l'IA de l'otage (unité locale au serveur)
    _hostage enableAI "ANIM";
    _hostage enableAI "MOVE";
    _hostage setCaptive false;
    _hostage setBehaviour "CARELESS";
    _hostage setUnitPos "UP";
    _hostage allowFleeing 0;

    // ── Boucle de suivi : l'otage marche vers le joueur le plus proche ────────
    [_hostage] spawn {
        params ["_h"];
        while {
            alive _h
            && !(_h getVariable ["TAG_Task03_InHeli", false])
            && !(missionNamespace getVariable ["TAG_Task03_Complete", false])
        } do {
            _h setUnitPos "UP";
            _h setBehaviour "CARELESS";

            private _nearest = objNull;
            private _minD    = 99999;
            {
                if (alive _x) then {
                    private _d = _h distance _x;
                    if (_d < _minD) then { _minD = _d; _nearest = _x; };
                };
            } forEach allPlayers;

            if (!isNull _nearest) then { _h doMove (getPos _nearest); };
            sleep 5;
        };
    };

    // ── Spawn de l'hélicoptère d'extraction ───────────────────────────────────
    // Trouver une LZ dégagée entre 300 et 550m de la position actuelle de l'otage
    private _hostageCurrentPos = getPos _hostage;
    private _lzDir  = random 360;
    private _lzDist = 300 + random 250;
    private _lzBase = _hostageCurrentPos getPos [_lzDist, _lzDir];
    private _lzPos  = _lzBase findEmptyPosition [0, 120, "Land_HelipadEmpty_F"];
    if (count _lzPos == 0) then { _lzPos = _lzBase; };
    _lzPos set [2, 0];

    // Spawn hélico loin et en altitude (côté Ouest par rapport à l'otage)
    private _heliDir      = (_hostageCurrentPos getDir _lzPos) + 180;
    private _heliSpawnPos = _lzPos getPos [2200, _heliDir];
    _heliSpawnPos set [2, 280];

    private _heliGrp = createGroup [west, true];
    private _heli    = createVehicle ["B_Heli_Transport_01_F", _heliSpawnPos, [], 0, "FLY"];
    _heli lock 2; // Verrouillé aux joueurs pendant le trajet

    // Équipage
    private _pilot   = _heliGrp createUnit ["B_Helipilot_F", _heliSpawnPos, [], 0, "NONE"];
    _pilot moveInDriver _heli;
    private _copilot = _heliGrp createUnit ["B_Helipilot_F", _heliSpawnPos, [], 0, "NONE"];
    _copilot moveInCargo _heli;

    _heliGrp setBehaviour "CARELESS";
    _heliGrp setCombatMode "BLUE";
    _heli flyInHeight 80;
    _heli doMove _lzPos;

    if (DEBUG_MODE) then {
        diag_log format ["[TAG] task03: Hélico créé — LZ à %1m de l'otage.", round (_hostageCurrentPos distance2D _lzPos)];
    };

    // Marqueur LZ
    deleteMarker "TAG_task03_lz";
    createMarker ["TAG_task03_lz", _lzPos];
    "TAG_task03_lz" setMarkerType "hd_pickup";
    "TAG_task03_lz" setMarkerColor "ColorGreen";
    "TAG_task03_lz" setMarkerText (localize "STR_TAG_Task_03_LZMarker");

    // Mettre à jour la destination de la tâche sur la LZ
    ["task_03_hostage", _lzPos, true] call BIS_fnc_taskSetDestination;

    // Message d'arrivée de l'hélico
    (localize "STR_TAG_Task_03_HeliIncoming") remoteExec ["hint", 0];

    // ── Surveiller la mort de l'otage pendant l'extraction ───────────────────
    [_hostage, _heli, _heliGrp, _allGroups, _allMarkers] spawn {
        params ["_h", "_v", "_vGrp", "_grps", "_mkrs"];
        waitUntil {
            sleep 2;
            !alive _h
            || missionNamespace getVariable ["TAG_Task03_Complete", false]
            || missionNamespace getVariable ["TAG_Task03_Failed", false]
        };

        // Si l'otage meurt et que la tâche n'est pas encore résolue
        if (!alive _h && !(missionNamespace getVariable ["TAG_Task03_Complete", false])) then {
            if (DEBUG_MODE) then { diag_log "[TAG] task03: Otage mort pendant l'extraction — FAILED."; };
            missionNamespace setVariable ["TAG_Task03_Failed", true, true];
            ["task_03_hostage", "FAILED", true] remoteExec ["BIS_fnc_taskSetState", 0];
            // Nettoyage hélico
            { deleteVehicle _x; } forEach (crew _v);
            deleteVehicle _v;
        };

        // Nettoyage des marqueurs et gardes survivants
        { deleteMarker _x; } forEach _mkrs;
        deleteMarker "TAG_task03_lz";
        { { if (alive _x) then { deleteVehicle _x; }; } forEach (units _x); } forEach _grps;
    };

    // Attendre que l'hélico s'approche de la LZ
    waitUntil {
        sleep 2;
        !alive _heli
        || missionNamespace getVariable ["TAG_Task03_Failed", false]
        || _heli distance2D _lzPos < 200
    };

    if (!alive _heli || missionNamespace getVariable ["TAG_Task03_Failed", false]) exitWith {};

    // ── Atterrissage ──────────────────────────────────────────────────────────
    _heli land "LAND";
    _heli lock 0; // Déverrouiller pour l'embarquement

    // Helipad visuel
    private _helipadObj = createVehicle ["Land_HelipadEmpty_F", _lzPos, [], 0, "CAN_COLLIDE"];
    _helipadObj setPos _lzPos;

    // Attendre toucher du sol (max 45s)
    private _landTimer = time + 45;
    waitUntil {
        sleep 1;
        isTouchingGround _heli || !alive _heli || time > _landTimer
    };

    if (!alive _heli || missionNamespace getVariable ["TAG_Task03_Failed", false]) exitWith {
        deleteVehicle _helipadObj;
    };

    if (DEBUG_MODE) then { diag_log "[TAG] task03: Hélico posé — début embarquement otage."; };

    // ── Diriger l'otage vers l'hélico ─────────────────────────────────────────
    _hostage setVariable ["TAG_Task03_InHeli", true, true]; // Arrête la boucle de suivi
    _hostage setUnitPos "UP";
    _hostage setBehaviour "CARELESS";

    // Rejoindre le groupe de l'hélico et s'assigner comme cargo
    [_hostage] joinSilent _heliGrp;
    _hostage assignAsCargo _heli;
    [_hostage] orderGetIn true;

    // Forcer l'action GetIn si l'otage est bloqué
    [_hostage, _heli] spawn {
        params ["_h", "_v"];
        private _tries = 0;
        waitUntil {
            sleep 3;
            _tries = _tries + 1;
            // Forcer l'action toutes les 3 tentatives si l'otage est disponible
            if (_tries % 3 == 0 && unitReady _h) then {
                _h action ["GetInCargo", _v];
            };
            // Sortie si embarqué, mort, ou timeout (60s)
            vehicle _h == _v || !alive _h || !alive _v || _tries > 20
        };
    };

    // ── Boucle d'attente embarquement : sécurité anti-joueur ─────────────────
    private _takeOff = false;
    waitUntil {
        sleep 2;

        if (!alive _heli || !alive _hostage || missionNamespace getVariable ["TAG_Task03_Failed", false]) exitWith { true };

        private _hostageInHeli  = vehicle _hostage == _heli;
        private _playersInHeli  = ({ isPlayer _x } count (crew _heli)) > 0;

        if (_hostageInHeli) then {
            if (_playersInHeli) then {
                // Joueur à bord → bloquer le décollage
                (localize "STR_TAG_Task_03_HeliWait") remoteExec ["hint", 0];
                _heli lock 0;
            } else {
                // Otage à bord, aucun joueur → autoriser le décollage
                _takeOff = true;
                _heli lock 2;
            };
        };

        _takeOff
    };

    if (!alive _heli || !alive _hostage || missionNamespace getVariable ["TAG_Task03_Failed", false]) exitWith {
        deleteVehicle _helipadObj;
    };

    // ── Décollage et exfiltration ─────────────────────────────────────────────
    deleteVehicle _helipadObj;
    deleteMarker "TAG_task03_lz";
    (localize "STR_TAG_Task_03_HeliTakeoff") remoteExec ["hint", 0];

    _heli land "NONE";
    _heliGrp setBehaviour "CARELESS";
    _heliGrp setCombatMode "BLUE";
    _heli flyInHeight 150;

    // Voler vers une direction d'exfiltration opposée à la zone de mission
    private _exfilDir = (_lzPos getDir _leaderPos) + 180;
    _heli doMove (_lzPos getPos [6000, _exfilDir]);

    if (DEBUG_MODE) then { diag_log "[TAG] task03: Hélico décollé — attente exfiltration."; };

    // Attendre 65s puis conclure (temps de vol suffisant pour quitter la zone)
    sleep 65;

    // ── Résultat ──────────────────────────────────────────────────────────────
    if (alive _hostage) then {
        if (DEBUG_MODE) then { diag_log "[TAG] task03: Exfiltration réussie — SUCCEEDED."; };
        missionNamespace setVariable ["TAG_Task03_Complete", true, true];
        ["task_03_hostage", "SUCCEEDED", true] remoteExec ["BIS_fnc_taskSetState", 0];
    } else {
        if (DEBUG_MODE) then { diag_log "[TAG] task03: Otage mort en vol — FAILED."; };
        missionNamespace setVariable ["TAG_Task03_Failed", true, true];
        ["task_03_hostage", "FAILED", true] remoteExec ["BIS_fnc_taskSetState", 0];
    };

    // Nettoyage hélico et équipage
    { deleteVehicle _x; } forEach (crew _heli);
    deleteVehicle _hostage;
    deleteVehicle _heli;

    if (DEBUG_MODE) then {
        diag_log format ["[TAG] task03: Terminée — état: %1.", ["task_03_hostage"] call BIS_fnc_taskState];
    };
};
