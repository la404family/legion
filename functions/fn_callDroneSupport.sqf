#include "..\macros.hpp"

/*
 * TAG_fnc_callDroneSupport
 *
 * Description:
 *   Déploie un drone de reconnaissance (Reaper) qui :
 *   - Vole depuis une position éloignée vers le centre de masse du groupe
 *   - Tourne à 100m d'altitude / 100m de rayon pendant 15 minutes
 *   - Est mutuellement invisible aux ennemis et ignore les ennemis
 *   - Marque les positions ennemies détectées sur la carte (±25m d'imprécision,
 *     mise à jour toutes les 5-10 secondes, pool de 5 marqueurs rotatifs)
 *   - Joue un son de confirmation à la demande, un son d'arrivée à tous les joueurs,
 *     et un son de refus si le drone est déjà déployé
 *
 * Arguments:
 *   0: <OBJECT> Demandeur (joueur leader)
 *
 * Return Value:
 *   None
 *
 * Locality:
 *   Server
 *
 * Example:
 *   [player] remoteExec ["TAG_fnc_callDroneSupport", 2];
 */

if (!isServer) exitWith {};

params [
    ["_caller", objNull, [objNull]]
];

// ── Vérification verrou ───────────────────────────────────────────────────────
if (missionNamespace getVariable ["TAG_Drone_Active", false]) exitWith {
    private _snd = selectRandom ["refus_drone_01", "refus_drone_02", "refus_drone_03"];
    [_snd] remoteExec ["playSound", _caller];
    (localize "STR_TAG_Msg_Drone_Denied") remoteExec ["systemChat", _caller];
};

missionNamespace setVariable ["TAG_Drone_Active", true, true];

// Son d'acceptation (uniquement au demandeur)
private _confirmSnd = selectRandom ["drone_01", "drone_02", "drone_03"];
[_confirmSnd] remoteExec ["playSound", _caller];
(localize "STR_TAG_Msg_Drone_Approved") remoteExec ["systemChat", 0];

// ── Scénario principal (spawné pour permettre sleep/waitUntil) ────────────────
[_caller] spawn {
    params ["_caller"];

    // Constantes
    private _droneClass     = "B_AMF_REAPER_dynamicLoadout_F";
    private _approachHeight = 300;
    private _loiterHeight   = 100;
    private _loiterRadius   = 500; // 100m trop serré pour voilure fixe à grande vitesse
    private _missionTime    = 900; // 15 minutes
    private _markerPrefix   = "TAG_drone_recon_";
    private _markerCount    = 5;

    // Centre de masse des joueurs actifs
    private _activePlayers = allPlayers select { alive _x };
    if (count _activePlayers == 0) then { _activePlayers = [_caller]; };
    private _centerPos = [0, 0, 0];
    { _centerPos = _centerPos vectorAdd getPos _x; } forEach _activePlayers;
    _centerPos = _centerPos vectorMultiply (1 / count _activePlayers);
    _centerPos set [2, 0];

    // Position de spawn loin hors de vue
    private _spawnDir = random 360;
    private _spawnPos = _centerPos getPos [3000, _spawnDir];
    _spawnPos set [2, _approachHeight];

    // ── Créer le drone ─────────────────────────────────────────────────────────
    private _spawnDir2 = ((_spawnDir + 180) mod 360); // cap vers la zone
    private _drone = createVehicle [_droneClass, _spawnPos, [], 0, "FLY"];
    if (isNull _drone) exitWith {
        missionNamespace setVariable ["TAG_Drone_Active", false, true];
        (localize "STR_TAG_Msg_Drone_Error") remoteExec ["systemChat", 0];
        if (DEBUG_MODE) then { diag_log "[TAG] callDroneSupport: ERREUR createVehicle - classe introuvable."; };
    };

    _drone setPos _spawnPos;
    _drone setDir _spawnDir2;
    _drone flyInHeight _approachHeight;
    _drone allowDamage false;

    // Vitesse initiale indispensable pour un aéronef à voilure fixe
    // (sans vitesse, le Reaper décroche et s'écrase immédiatement)
    private _initialSpeed = 60; // m/s (~216 km/h)
    _drone setVelocity [
        _initialSpeed * (sin _spawnDir2),
        _initialSpeed * (cos _spawnDir2),
        0
    ];

    // createVehicleCrew instancie l'équipage natif défini dans CfgVehicles
    // (plus fiable que B_UAV_AI qui est la classe terminal, pas cockpit)
    createVehicleCrew _drone;
    sleep 0.1; // laisser le moteur initialiser l'équipage

    private _droneGroup = group (driver _drone);
    if (isNull _droneGroup) exitWith {
        deleteVehicle _drone;
        missionNamespace setVariable ["TAG_Drone_Active", false, true];
        (localize "STR_TAG_Msg_Drone_Error") remoteExec ["systemChat", 0];
        if (DEBUG_MODE) then { diag_log "[TAG] callDroneSupport: ERREUR - impossible de récupérer le groupe du pilote."; };
    };

    // Désactiver tout comportement offensif
    _droneGroup setCombatMode "BLUE";
    _droneGroup setBehaviour "CARELESS";
    {
        _x disableAI "TARGET";
        _x disableAI "AUTOTARGET";
        _x disableAI "SUPPRESSION";
        _x allowDamage false;
    } forEach units _droneGroup;

    // Boucle parallèle : empêcher les ennemis de cibler le drone
    [_drone] spawn {
        params ["_drone"];
        while { alive _drone } do {
            sleep 3;
            if (alive _drone) then {
                {
                    if (alive _x) then { _x forgetTarget _drone; };
                } forEach (allUnits select { side _x == east || side _x == independent });
            };
        };
    };

    if (DEBUG_MODE) then {
        diag_log format ["[TAG] callDroneSupport: Drone spawné en %1, approche de %2.", _spawnPos, _centerPos];
    };

    // ── Phase 1 : Approche de la zone ─────────────────────────────────────────
    private _wp = _droneGroup addWaypoint [_centerPos, 0];
    _wp setWaypointType "MOVE";
    _wp setWaypointSpeed "FULL";
    _wp setWaypointCompletionRadius 300;

    waitUntil {
        sleep 5;
        !alive _drone || (_drone distance2D _centerPos < 500)
    };

    if (!alive _drone) exitWith {
        missionNamespace setVariable ["TAG_Drone_Active", false, true];
    };

    if (DEBUG_MODE) then {
        diag_log "[TAG] callDroneSupport: Drone sur zone, passage en loiter.";
    };

    // ── Phase 2 : Annonce et passage en loiter ────────────────────────────────
    private _infoSnd = selectRandom ["drone_info_01", "drone_info_02", "drone_info_03"];
    [_infoSnd] remoteExec ["playSound", 0];
    (localize "STR_TAG_Msg_Drone_Overhead") remoteExec ["systemChat", 0];

    _drone flyInHeight _loiterHeight;

    // Supprimer les waypoints ajoutés (index > 0 uniquement — le wp 0 est permanent)
    private _allWps = waypoints _droneGroup;
    for "_wIdx" from ((count _allWps) - 1) to 1 step -1 do {
        deleteWaypoint (_allWps select _wIdx);
    };

    // Loiter au-dessus du leader du groupe appelant
    private _loiterCenter = getPos (leader (group _caller));
    private _wpLoiter = _droneGroup addWaypoint [_loiterCenter, 0];
    _wpLoiter setWaypointType "LOITER";
    _wpLoiter setWaypointLoiterRadius _loiterRadius;
    _wpLoiter setWaypointLoiterType "CIRCLE";
    _droneGroup setSpeedMode "LIMITED";
    _droneGroup setCurrentWaypoint _wpLoiter;

    // ── Phase 3 : Marquage ennemi (loop parallèle) ────────────────────────────
    private _missionEnd = time + _missionTime;
    [_drone, _markerPrefix, _markerCount, _missionEnd, _caller] spawn {
        params ["_drone", "_prefix", "_max", "_endTime", "_caller"];

        // Pré-créer les pools de marqueurs dot par faction (invisibles au départ)
        private _fnc_initPool = {
            params ["_tag", "_color"];
            for "_i" from 0 to (_max - 1) do {
                private _mn = format ["%1_%2_%3", _prefix, _tag, _i];
                createMarker [_mn, [0, 0, 0]];
                _mn setMarkerShape "ICON";
                _mn setMarkerType "mil_dot";
                _mn setMarkerColor _color;
                _mn setMarkerSize [0.4, 0.4];
                _mn setMarkerText "";
                _mn setMarkerAlpha 0;
            };
        };
        ["opfor", "ColorRed"]    call _fnc_initPool;
        ["indep", "ColorGreen"]  call _fnc_initPool;
        ["civ",   "ColorYellow"] call _fnc_initPool;

        // Indices rotatifs par faction
        private _idxOpfor = 0;
        private _idxIndep = 0;
        private _idxCiv   = 0;

        while { time < _endTime && alive _drone } do {
            sleep (5 + random 5);
            if (!alive _drone) exitWith {};

            private _leaderPos = getPos (leader (group _caller));
            private _scanRadius = 1500;

            // ── OPFOR ──────────────────────────────────────────────────────────
            {
                private _rawPos = getPos _x;
                private _mp = [(_rawPos select 0) + ((random 50)-25), (_rawPos select 1) + ((random 50)-25), 0];
                private _mn = format ["%1_opfor_%2", _prefix, _idxOpfor];
                _mn setMarkerPos _mp;
                _mn setMarkerAlpha 1;
                _idxOpfor = (_idxOpfor + 1) mod _max;
            } forEach (allUnits select { alive _x && side _x == east && (_x distance2D _leaderPos < _scanRadius) });

            // ── Indépendants ───────────────────────────────────────────────────
            {
                private _rawPos = getPos _x;
                private _mp = [(_rawPos select 0) + ((random 50)-25), (_rawPos select 1) + ((random 50)-25), 0];
                private _mn = format ["%1_indep_%2", _prefix, _idxIndep];
                _mn setMarkerPos _mp;
                _mn setMarkerAlpha 1;
                _idxIndep = (_idxIndep + 1) mod _max;
            } forEach (allUnits select { alive _x && side _x == independent && (_x distance2D _leaderPos < _scanRadius) });

            // ── Civils ─────────────────────────────────────────────────────────
            {
                private _rawPos = getPos _x;
                private _mp = [(_rawPos select 0) + ((random 50)-25), (_rawPos select 1) + ((random 50)-25), 0];
                private _mn = format ["%1_civ_%2", _prefix, _idxCiv];
                _mn setMarkerPos _mp;
                _mn setMarkerAlpha 1;
                _idxCiv = (_idxCiv + 1) mod _max;
            } forEach ((entities "Man") select { alive _x && side _x == civilian && (_x distance2D _leaderPos < _scanRadius) });

        };

        // Nettoyage de tous les marqueurs
        {
            private _tag = _x;
            for "_i" from 0 to (_max - 1) do {
                deleteMarker format ["%1_%2_%3", _prefix, _tag, _i];
            };
        } forEach ["opfor", "indep", "civ"];
    };

    // ── Phase 4 : Attendre la fin de mission ──────────────────────────────────
    sleep _missionTime;

    (localize "STR_TAG_Msg_Drone_RTB") remoteExec ["systemChat", 0];

    // Nettoyer les waypoints de loiter
    while { count (waypoints _droneGroup) > 0 } do {
        deleteWaypoint [_droneGroup, 0];
    };

    // Vol de départ
    _drone flyInHeight _approachHeight;
    private _exitDir = random 360;
    private _exitPos = (getPos _drone) getPos [4000, _exitDir];
    _exitPos set [2, _approachHeight];
    private _wpExit = _droneGroup addWaypoint [_exitPos, 0];
    _wpExit setWaypointType "MOVE";
    _wpExit setWaypointSpeed "FULL";

    // Attendre que le drone s'éloigne suffisamment
    waitUntil {
        sleep 5;
        !alive _drone || (_drone distance2D _loiterCenter > 2000)
    };

    // ── Nettoyage final ───────────────────────────────────────────────────────
    { deleteVehicle _x } forEach (crew _drone);
    deleteVehicle _drone;
    deleteGroup _droneGroup;

    missionNamespace setVariable ["TAG_Drone_Active", false, true];

    if (DEBUG_MODE) then {
        diag_log "[TAG] callDroneSupport: Drone supprimé, verrou libéré.";
    };
};
