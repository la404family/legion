#include "..\macros.hpp"

/*
 * TAG_fnc_task02
 *
 * Description:
 *   Tâche 02 — Récupération de documents TOP SECRET.
 *   Des documents classifiés sont détenus par un officier ennemi dont la
 *   position exacte est inconnue. Trois lieux suspects sont identifiés
 *   dans la zone, chacun gardé par une escouade ennemie.
 *   Un seul officier (déterminé aléatoirement) détient les vrais documents.
 *
 *   Déroulement :
 *     1. Création de 3 positions suspectes à +350m du leader, dans des bâtiments.
 *     2. Spawn d'un officier + 2-8 gardes par position (patrouilleront autour).
 *     3. L'officier cible (aléatoire) dépose les documents à sa mort.
 *     4. Le joueur récupère les documents via addAction sur le corps.
 *     5. Nettoyage différé des ennemis survivants (>1200m → delete, sinon COMBAT).
 *
 *   La tâche se déclenche automatiquement après la réussite de task_01.
 *   Joue un son de briefing aléatoire (task02_01/02/03) à la création.
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
 *   [] call TAG_fnc_task02;
 */

if (!isServer) exitWith {};

// Attendre que le système de templates civils soit prêt
waitUntil { !isNil "MISSION_fnc_applyCivilianTemplate" };

// ── Son de briefing ───────────────────────────────────────────────────────────
private _snd = selectRandom ["task02_01", "task02_02", "task02_03"];
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
    private _minDist      = 200;  // distance minimale depuis le leader

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
                diag_log format ["[TAG] task02: Rayon étendu à %1m — %2 bâtiment(s) valide(s).", _searchRadius, count _candidates];
            };
        };
    };

    if (count _candidates < 3) exitWith {
        (localize "STR_TAG_Task_02_Error") remoteExec ["systemChat", 0];
        if (DEBUG_MODE) then {
            diag_log "[TAG] task02: ERREUR — pas assez de bâtiments valides même au rayon max (2000m).";
        };
    };

    if (DEBUG_MODE) then {
        diag_log format ["[TAG] task02: %1 bâtiment(s) dans un rayon de %2m.", count _candidates, _searchRadius];
    };

    // ── Sélection aléatoire de 3 bâtiments bien espacés entre eux (>150m) ─────
    private _selectedBuildings = [];
    private _pool = +_candidates;

    while { count _selectedBuildings < 3 && count _pool > 0 } do {
        private _pick = selectRandom _pool;
        _pool = _pool - [_pick];
        // Vérifier que le bâtiment est assez loin de ceux déjà sélectionnés
        private _tooClose = (_selectedBuildings findIf { _x distance2D _pick < 150 }) != -1;
        if (!_tooClose) then {
            _selectedBuildings pushBack _pick;
        };
    };

    // Fallback : compléter sans contrainte d'espacement si le pool est épuisé
    if (count _selectedBuildings < 3) then {
        {
            if !(_x in _selectedBuildings) then { _selectedBuildings pushBack _x; };
            if (count _selectedBuildings >= 3) exitWith {};
        } forEach _candidates;
    };

    if (DEBUG_MODE) then {
        {
            diag_log format [
                "[TAG] task02: Bâtiment %1 — %2 — à %3m du leader.",
                _forEachIndex + 1, typeOf _x, round (_x distance2D _leaderPos)
            ];
        } forEach _selectedBuildings;
    };

    // ── Spawn des ennemis sur chaque site ─────────────────────────────────────
    private _officers  = [];
    private _allGroups = [];

    {
        private _bldPos    = _x buildingPos 0;
        private _spawnPos  = [
            _bldPos select 0,
            _bldPos select 1,
            (_bldPos select 2) + 0.5
        ];

        // Officier (porteur potentiel des documents)
        private _oGrp    = createGroup [east, true];
        private _officer = _oGrp createUnit ["O_officer_F", _spawnPos, [], 0, "NONE"];
        _officer setPosASL _spawnPos;
        _officer allowDamage false;
        [_officer] spawn { sleep 2; (_this select 0) allowDamage true; };

        if (!isNil "MISSION_fnc_applyCivilianTemplate") then {
            [_officer] call MISSION_fnc_applyCivilianTemplate;
        };

        _allGroups pushBack _oGrp;
        _officers  pushBack _officer;

        // Gardes (2-8 par site)
        private _numGuards = 2 + floor (random 7);
        private _curGrp    = _oGrp;

        for "_j" from 1 to _numGuards do {
            // Limiter à 3 unités par groupe pour éviter les problèmes de pathfinding
            if (count (units _curGrp) >= 3) then {
                _curGrp = createGroup [east, true];
                _allGroups pushBack _curGrp;
            };

            private _gPos  = _spawnPos vectorAdd [
                (random 10) - 5,
                (random 10) - 5,
                0
            ];
            private _guard = _curGrp createUnit ["O_Soldier_F", _gPos, [], 0, "NONE"];
            _guard setPosASL [
                _gPos select 0,
                _gPos select 1,
                (getTerrainHeightASL _gPos) + 0.5
            ];
            _guard allowDamage false;
            [_guard] spawn { sleep 2; (_this select 0) allowDamage true; };

            if (!isNil "MISSION_fnc_applyCivilianTemplate") then {
                [_guard] call MISSION_fnc_applyCivilianTemplate;
            };
        };

        // Patrouille autour du bâtiment (rayon 25m)
        [_oGrp, _spawnPos, 25] call BIS_fnc_taskPatrol;

    } forEach _selectedBuildings;

    // ── Désigner l'officier cible (détenteur des vrais documents) ─────────────
    private _targetOfficer = selectRandom _officers;
    _targetOfficer setVariable ["TAG_Task02_IsTarget", true, true];

    if (DEBUG_MODE) then {
        diag_log format [
            "[TAG] task02: Officier cible désigné — groupe %1.",
            group _targetOfficer
        ];
    };

    // ── Marqueurs des positions suspectes ─────────────────────────────────────
    private _markers = [];
    {
        private _mID  = format ["TAG_task02_suspect_%1", _forEachIndex];
        private _mPos = _x buildingPos 0;
        deleteMarker _mID;
        createMarker [_mID, _mPos];
        _mID setMarkerType "mil_warning";
        _mID setMarkerColor "ColorRed";
        _mID setMarkerText (localize "STR_TAG_Task_02_SuspectMarker");
        _markers pushBack _mID;
    } forEach _selectedBuildings;

    // Suivi dynamique des marqueurs officiers
    missionNamespace setVariable ["TAG_Task02_Complete", false, true];

    [_officers, _markers] spawn {
        params ["_officers", "_markers"];

        while { !(missionNamespace getVariable ["TAG_Task02_Complete", false]) } do {
            sleep 3;

            {
                private _idx  = _forEachIndex;
                private _mID  = _markers select _idx;
                if (!alive _x) then {
                    deleteMarker _mID;
                } else {
                    _mID setMarkerPos (getPos _x);
                };
            } forEach _officers;
        };

        // Nettoyage final des marqueurs suspects
        { deleteMarker _x; } forEach _markers;
        deleteMarker "TAG_task02_doc";
    };

    // ── Création de la tâche BIS ──────────────────────────────────────────────
    [
        west,
        ["task_02_intel"],
        [
            localize "STR_TAG_Task_02_Desc",
            localize "STR_TAG_Task_02_Title",
            localize "STR_TAG_Task_02_Marker"
        ],
        objNull,
        "AUTOASSIGNED",
        5,
        true,
        "search"
    ] call BIS_fnc_taskCreate;

    if (DEBUG_MODE) then { diag_log "[TAG] task02: Tâche de récupération créée."; };

    // ── Surveiller la mort de l'officier cible ────────────────────────────────
    [_targetOfficer, _allGroups] spawn {
        params ["_target", "_allGroups"];

        waitUntil { sleep 1; !alive _target };

        if (DEBUG_MODE) then { diag_log "[TAG] task02: Officier cible éliminé. Dépôt des documents."; };

        // Spawn du document au sol — getPos/setPos (AGL) + NONE pour éviter collision terrain
        private _bodyPos = getPos _target;
        private _doc = createVehicle ["Land_Document_01_F", _bodyPos, [], 0, "NONE"];
        _doc setPos [_bodyPos select 0, _bodyPos select 1, (_bodyPos select 2) + 0.05];

        // Publier l'objet comme variable globale : fallback si remoteExec arrive avant createVehicle
        TAG_Task02_Doc = _doc;
        publicVariable "TAG_Task02_Doc";

        // Marqueur document
        deleteMarker "TAG_task02_doc";
        private _mDoc = "TAG_task02_doc";
        createMarker [_mDoc, _bodyPos];
        _mDoc setMarkerType "mil_objective";
        _mDoc setMarkerColor "ColorWhite";
        _mDoc setMarkerText (localize "STR_TAG_Task_02_DocMarker");

        // Mettre à jour la destination de la tâche BIS
        ["task_02_intel", _bodyPos, true] call BIS_fnc_taskSetDestination;

        // Attendre 1s que createVehicle se propage aux clients AVANT le remoteExec
        sleep 1;

        // Ajouter l'action de récupération sur le document (tous les clients)
        [_doc] remoteExec ["TAG_fnc_task02_addAction", 0, str _doc];

        // Attendre la récupération ou l'échec
        waitUntil {
            sleep 2;
            (missionNamespace getVariable ["TAG_Task02_Complete", false])
            || { isNull _doc }
        };

        if (!(missionNamespace getVariable ["TAG_Task02_Complete", false])) exitWith {};

        // ── Nettoyage différé des ennemis survivants ──────────────────────────
        {
            private _grp = _x;
            {
                if (alive _x) then {
                    private _alivePlayers = allPlayers select { side _x == west && alive _x };
                    if (count _alivePlayers == 0) exitWith { deleteVehicle _x; };

                    private _nearest = [_alivePlayers, getPos _x] call BIS_fnc_nearestPosition;
                    if (_x distance2D _nearest > 1200) then {
                        deleteVehicle _x;
                    } else {
                        _x doMove (getPos _nearest);
                        _x setBehaviour "COMBAT";
                        _x setSpeedMode "FULL";
                        _x setCombatMode "RED";
                    };
                };
            } forEach (units _grp);
        } forEach _allGroups;

        if (DEBUG_MODE) then { diag_log "[TAG] task02: Nettoyage des groupes ennemis terminé."; };
    };

    // ── Surveillance globale de la tâche ──────────────────────────────────────
    waitUntil {
        sleep 5;
        (["task_02_intel"] call BIS_fnc_taskState) in ["SUCCEEDED", "FAILED", "CANCELED"]
    };

    if (DEBUG_MODE) then {
        diag_log format [
            "[TAG] task02: Terminée — état: %1.",
            ["task_02_intel"] call BIS_fnc_taskState
        ];
    };
};
