#include "..\macros.hpp"

/*
 * TAG_fnc_task01
 *
 * Description:
 *   Tâche 01 — Rendez-vous de reconnaissance.
 *   Le groupe doit localiser et rejoindre un chef de milice local réfugié
 *   dans un bâtiment à plus de 350m de leur position initiale.
 *   Le chef détient des informations vitales sur les forces ennemies dans la vallée.
 *
 *   Trois scénarios possibles lors de l'interaction :
 *     1. Coopération  — Le chef livre ses informations voluntairement.   → SUCCEEDED
 *     2. Trahison     — Le chef appelle ses gardes en renfort.           → SUCCEEDED si tous éliminés
 *     3. Mutinerie    — Les gardes retournent le chef.                  → SUCCEEDED si chef survit
 *                                                                        → FAILED si chef tué
 *
 *   La tâche se déclenche automatiquement après la réussite de task_00.
 *   Joue un son de briefing aléatoire (task01_01/02/03) à la création.
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
 *   [] call TAG_fnc_task01;
 */

if (!isServer) exitWith {};

// ── Son de briefing ───────────────────────────────────────────────────────────
private _snd = selectRandom ["task01_01", "task01_02", "task01_03"];
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

    // ── Recherche dynamique : rayon croissant depuis 300m jusqu'à trouver un bâtiment ──
    private _candidates   = [];
    private _searchRadius = 300;
    private _minDist      = 150;  // distance minimale depuis le leader

    while { (count _candidates == 0) && (_searchRadius <= 2000) } do {
        _candidates = nearestTerrainObjects [
            _leaderPos,
            ["House", "Building", "HouseBase", "Church", "Ruin"],
            _searchRadius,
            false
        ] select {
            (_x distance2D _leaderPos > _minDist)
            && { (_x buildingPos 0) distance [0,0,0] > 1 }
        };

        if (count _candidates == 0) then {
            _searchRadius = _searchRadius + 150;
            if (DEBUG_MODE) then {
                diag_log format ["[TAG] task01: Rayon étendu à %1m — aucun bâtiment valide.", _searchRadius];
            };
        };
    };

    if (count _candidates == 0) exitWith {
        (localize "STR_TAG_Task_01_Error") remoteExec ["systemChat", 0];
        if (DEBUG_MODE) then {
            diag_log "[TAG] task01: ERREUR — aucun bâtiment valide trouvé même au rayon max (2000m).";
        };
    };

    if (DEBUG_MODE) then {
        diag_log format ["[TAG] task01: %1 bâtiment(s) valide(s) trouvé(s) dans un rayon de %2m.", count _candidates, _searchRadius];
    };

    private _building   = selectRandom _candidates;
    private _meetingPos = _building buildingPos 0;

    if (DEBUG_MODE) then {
        diag_log format [
            "[TAG] task01: Bâtiment sélectionné (%1) à %2m du leader.",
            typeOf _building, round (_building distance2D _leaderPos)
        ];
    };

    // ── Spawn du chef de milice ───────────────────────────────────────────────
    private _chiefGrp = createGroup [independent, true];
    private _chief    = _chiefGrp createUnit ["I_G_officer_F", _meetingPos, [], 0, "NONE"];

    _chief setPosASL [
        _meetingPos select 0,
        _meetingPos select 1,
        (getTerrainHeightASL _meetingPos) + 0.5
    ];
    _chief allowDamage false;
    [_chief] spawn { sleep 3; (_this select 0) allowDamage true; };

    // Apparence via le système de templates civils (fn_templateCollector)
    if (!isNil "MISSION_fnc_applyCivilianTemplate") then {
        [_chief] call MISSION_fnc_applyCivilianTemplate;
    };

    // Comportement d'attente
    _chief disableAI "MOVE";
    _chief disableAI "ANIM";
    _chief setUnitPos "UP";
    _chief switchMove "Acts_CivilTalking_1";
    _chief setBehaviour "SAFE";
    _chief setCombatMode "BLUE";
    _chief setVariable ["TAG_Task01_Status", "WAIT", true];

    _chief addEventHandler ["AnimDone", {
        params ["_unit"];
        if (alive _unit && (_unit getVariable ["TAG_Task01_Status", "WAIT"] == "WAIT")) then {
            _unit switchMove "Acts_CivilTalking_1";
        };
    }];

    // ── Spawn des gardes ──────────────────────────────────────────────────────
    private _guards    = [];
    private _numGuards = 2 + floor (random 3); // 2 à 4 gardes

    for "_i" from 0 to (_numGuards - 1) do {
        private _gPos  = _meetingPos getPos [6 + random 14, random 360];
        private _gGrp  = createGroup [independent, true];
        private _guard = _gGrp createUnit ["I_G_Soldier_F", _gPos, [], 0, "NONE"];

        _guard setPosASL [
            _gPos select 0,
            _gPos select 1,
            (getTerrainHeightASL _gPos) + 0.5
        ];
        _guard allowDamage false;
        [_guard] spawn { sleep 3; (_this select 0) allowDamage true; };

        if (!isNil "MISSION_fnc_applyCivilianTemplate") then {
            [_guard] call MISSION_fnc_applyCivilianTemplate;
        };

        _guard setBehaviour "SAFE";
        _guard setCombatMode "BLUE";

        // Patrouille locale autour du point de rencontre
        [_guard, _meetingPos] spawn {
            params ["_unit", "_center"];
            _unit setSpeedMode "LIMITED";
            while { alive _unit && behaviour _unit != "COMBAT" } do {
                private _dst = _center getPos [4 + random 18, random 360];
                _unit doMove _dst;
                waitUntil {
                    sleep 1;
                    !alive _unit
                    || _unit distance2D _dst < 2
                    || unitReady _unit
                    || behaviour _unit == "COMBAT"
                };
                sleep (12 + random 20);
            };
        };

        _guards pushBack _guard;
    };

    // ── Marqueur de tâche ─────────────────────────────────────────────────────
    private _markerID = "TAG_task01_rdv";
    deleteMarker _markerID;
    createMarker [_markerID, _meetingPos];
    _markerID setMarkerType "mil_warning";
    _markerID setMarkerColor "ColorOrange";
    _markerID setMarkerText (localize "STR_TAG_Task_01_Marker");

    // ── Création de la tâche BIS ──────────────────────────────────────────────
    [
        west,
        ["task_01_recon"],
        [
            localize "STR_TAG_Task_01_Desc",
            localize "STR_TAG_Task_01_Title",
            localize "STR_TAG_Task_01_Marker"
        ],
        _meetingPos,
        "AUTOASSIGNED",
        5,
        true,
        "meet"
    ] call BIS_fnc_taskCreate;

    if (DEBUG_MODE) then {
        diag_log "[TAG] task01: Tâche de reconnaissance créée.";
    };

    missionNamespace setVariable ["TAG_Task01_Triggered", false, true];

    // ── Définir le scénario (var serveur, appelée via remoteExec client→serveur) ─
    TAG_fnc_task01_runScenario = {
        params [
            ["_scenario", 1,      [0]],
            ["_chief",    objNull, [objNull]],
            ["_guards",   [],      [[]]],
            ["_markerID", "",      [""]]
        ];

        if (!isServer) exitWith {};

        _chief setVariable ["TAG_Task01_Status", "ACTION", true];
        _chief enableAI "ANIM";
        _chief enableAI "MOVE";
        _chief switchMove "";

        switch (_scenario) do {

            // ── Scénario 1 : Coopération ──────────────────────────────────────
            case 1: {
                if (DEBUG_MODE) then { diag_log "[TAG] task01: Scénario 1 — Coopération."; };

                _chief globalChat (localize "STR_TAG_Task_01_S1_Chief");
                deleteMarker _markerID;

                // Gardes immobilisés — la réunion se passe bien
                { _x disableAI "MOVE"; } forEach _guards;

                ["task_01_recon", "SUCCEEDED", true] call BIS_fnc_taskSetState;
            };

            // ── Scénario 2 : Trahison — le chef appelle ses gardes ────────────
            case 2: {
                if (DEBUG_MODE) then { diag_log "[TAG] task01: Scénario 2 — Trahison."; };

                _chief globalChat (localize "STR_TAG_Task_01_S2_Chief");
                deleteMarker _markerID;
                sleep 1.5;

                private _allHostile = [_chief] + _guards;
                {
                    private _hGrp = createGroup [east, true];
                    [_x] joinSilent _hGrp;
                    _x setBehaviour "COMBAT";
                    _x setCombatMode "RED";
                } forEach _allHostile;

                private _targets = allPlayers select { side _x == west && alive _x };
                if (count _targets > 0) then {
                    { _x doFire (selectRandom _targets); } forEach _allHostile;
                };

                waitUntil { sleep 5; ({ alive _x } count _allHostile) == 0 };

                ["task_01_recon", "SUCCEEDED", true] call BIS_fnc_taskSetState;
            };

            // ── Scénario 3 : Mutinerie — les gardes retournent le chef ────────
            case 3: {
                if (DEBUG_MODE) then { diag_log "[TAG] task01: Scénario 3 — Mutinerie."; };

                _chief globalChat (localize "STR_TAG_Task_01_S3_Chief");
                deleteMarker _markerID;
                sleep 1.5;

                // Gardes → OPFOR, attaquent le chef ET les joueurs
                {
                    private _hGrp = createGroup [east, true];
                    [_x] joinSilent _hGrp;
                    _x setBehaviour "COMBAT";
                    _x setCombatMode "RED";
                    _x doFire _chief;
                } forEach _guards;

                // Chef → BLUFOR, se défend
                private _allyGrp = createGroup [west, true];
                [_chief] joinSilent _allyGrp;
                _chief setBehaviour "COMBAT";
                _chief setCombatMode "RED";

                waitUntil {
                    sleep 3;
                    !alive _chief || ({ alive _x } count _guards == 0)
                };

                if (alive _chief) then {
                    ["task_01_recon", "SUCCEEDED", true] call BIS_fnc_taskSetState;
                } else {
                    ["task_01_recon", "FAILED", true] call BIS_fnc_taskSetState;
                };
            };
        };
    };

    // ── Envoyer l'action à tous les clients (JIP inclus via handle str _chief) ─
    [_chief, _guards, _markerID] remoteExec ["TAG_fnc_task01_addAction", 0, str _chief];

    // ── Surveillance : mort anticipée du chef avant interaction ───────────────
    waitUntil {
        sleep 5;

        if (!alive _chief && !(missionNamespace getVariable ["TAG_Task01_Triggered", false])) exitWith {
            if (DEBUG_MODE) then {
                diag_log "[TAG] task01: Chef éliminé avant interaction — FAILED.";
            };
            ["task_01_recon", "FAILED", true] call BIS_fnc_taskSetState;
            deleteMarker _markerID;
            true
        };

        (["task_01_recon"] call BIS_fnc_taskState) in ["SUCCEEDED", "FAILED", "CANCELED"]
    };

    if (DEBUG_MODE) then {
        diag_log format ["[TAG] task01: Terminée — état: %1.", ["task_01_recon"] call BIS_fnc_taskState];
    };

    // ── Nettoyage différé (joueurs à +1500m) ──────────────────────────────────
    waitUntil {
        sleep 10;
        private _alive = allPlayers select { alive _x && side _x == west };
        if (count _alive == 0) exitWith { true };
        (_alive select 0) distance2D _meetingPos > 1500
    };

    { if (alive _x) then { deleteVehicle _x; }; } forEach ([_chief] + _guards);

    if (DEBUG_MODE) then { diag_log "[TAG] task01: Nettoyage terminé."; };
};
