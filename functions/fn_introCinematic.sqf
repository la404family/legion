if (isServer) then {
    [] spawn {
        diag_log "[INTRO] SERVER: Script démarré (Préparation de la scène de combat)";
        waitUntil { time > 0.1 };

        private _hqPos = [0,0,0];
        if (!isNil "heliport_00" && { !isNull heliport_00 }) then {
            _hqPos = getPosATL heliport_00;
        } else {
            private _fallback = missionNamespace getVariable ["player_0", objNull];
            if (!isNull _fallback) then {
                _hqPos = getPosATL _fallback;
                diag_log "[INTRO] ATTENTION: heliport_00 non trouvé, fallback sur player_0.";
            } else {
                diag_log "[INTRO] ERREUR: heliport_00 introuvable et player_0 indisponible !";
            };
        };

        private _destPos = _hqPos;
        private _combatAngle = random 360;
        private _combatPos = _destPos getPos [800, _combatAngle];
        _combatPos set [2, 0];
        private _flatCheck = _combatPos isFlatEmpty [10, -1, 0.2, 10, 0, false, objNull];
        if (_flatCheck isEqualTo []) then {
            private _safePos = [_combatPos, 0, 300, 10, 0, 0.2, 0, [], _combatPos] call BIS_fnc_findSafePos;
            if (_safePos isEqualType [] && { count _safePos >= 2 } && { _safePos distance2D _combatPos < 500 }) then {
                _combatPos = _safePos;
                _combatPos set [2, 0];
            };
        };

        MISSION_intro_combatPos = _combatPos;
        publicVariable "MISSION_intro_combatPos";

        private _grpOpfor = createGroup east;
        private _grpIndep = createGroup resistance;
        private _fakeUnits = [];

        private _angleOpfor = random 360;
        private _posOpfor = _combatPos getPos [80, _angleOpfor];
        private _posIndep = _combatPos getPos [80, _angleOpfor + 180];

        for "_i" from 1 to 6 do {
            private _u1 = _grpOpfor createUnit ["O_G_Soldier_F", _posOpfor getPos [random 15, random 360], [], 0, "NONE"];
            private _u2 = _grpIndep createUnit ["I_G_Soldier_F", _posIndep getPos [random 15, random 360], [], 0, "NONE"];
            _u1 setDir (_u1 getDir _posIndep);
            _u2 setDir (_u2 getDir _posOpfor);
            _fakeUnits pushBack _u1;
            _fakeUnits pushBack _u2;
        };

        MISSION_intro_unit_opfor = leader _grpOpfor;
        publicVariable "MISSION_intro_unit_opfor";
        MISSION_intro_unit_indep = leader _grpIndep;
        publicVariable "MISSION_intro_unit_indep";

        _grpOpfor setCombatMode "RED";
        _grpIndep setCombatMode "RED";
        _grpOpfor setBehaviour "COMBAT";
        _grpIndep setBehaviour "COMBAT";

        { _x doMove _posIndep } forEach units _grpOpfor;
        { _x doMove _posOpfor } forEach units _grpIndep;

        {
            if (random 1 > 0.5) then { _x setUnitPos "MIDDLE"; } else { _x setUnitPos "DOWN"; };
            _x allowDamage false;
        } forEach _fakeUnits;

        [_fakeUnits] spawn {
            params ["_units"];
            sleep 45;
            { deleteVehicle _x } forEach _units;
        };

        private _startDist = 4500;
        private _startDir = (_destPos getDir _combatPos) - 180;
        private _startPos = _destPos getPos [_startDist, _startDir];
        _startPos set [2, 100];

        private _heliClass = "B_AMF_Heli_Transport_01_F";
        private _heli = createVehicle [_heliClass, _startPos, [], 0, "FLY"];
        _heli setPos _startPos;
        _heli setDir (_heli getDir _destPos);
        _heli flyInHeight 40;
        _heli allowDamage false;

        MISSION_intro_heli = _heli;
        publicVariable "MISSION_intro_heli";

        createVehicleCrew _heli;
        private _crew = crew _heli;
        { _x allowDamage false; } forEach _crew;

        private _grpHeli = group driver _heli;
        _grpHeli setBehaviour "CARELESS";
        _grpHeli setCombatMode "BLUE";

        private _playersObj = [
            missionNamespace getVariable ["player_0", objNull], missionNamespace getVariable ["player_1", objNull],
            missionNamespace getVariable ["player_2", objNull], missionNamespace getVariable ["player_3", objNull],
            missionNamespace getVariable ["player_4", objNull], missionNamespace getVariable ["player_5", objNull],
            missionNamespace getVariable ["player_6", objNull]
        ];
        private _validPlayers = _playersObj select { !isNull _x && alive _x };

        {
            _x moveInCargo _heli;
            if (vehicle _x == _x) then { _x moveInAny _heli; };
            _x assignAsCargo _heli;
        } forEach _validPlayers;

        sleep 1;
        _heli doMove _destPos;
        _heli flyInHeight 40;
        _heli limitspeed 220;

        waitUntil { !alive _heli || { (_heli distance2D _destPos) < 500 } };
        if (!alive _heli) exitWith {};
        _heli setVariable ["landing_started", true, true];

        [_heli, ["door_rear_source", 1]] remoteExec ["animateSource", 0, true];
        [_heli, ["Ramp", 1]] remoteExec ["animateSource", 0, true];

        _heli limitspeed 100;
        waitUntil { !alive _heli || { (_heli distance2D _destPos) < 200 } };
        if (!alive _heli) exitWith {};
        _heli land "GET OUT";

        waitUntil { !alive _heli || { isTouchingGround _heli || ((getPosATL _heli) select 2) < 2 } };
        sleep 2;

        private _unitIndex = 0;
        {
            if (vehicle _x == _heli) then {
                moveOut _x;
                unassignVehicle _x;
                private _dir = getDir _heli;
                private _pos = _heli getPos [8 + (_unitIndex mod 3), _dir + 160];
                _pos set [2, 0];
                _x setPosATL _pos;
                _x setDir _dir;
                _unitIndex = _unitIndex + 1;
            };
        } forEach _validPlayers;

        sleep 5;
        _heli animateSource ["door_rear_source", 0];
        _heli animateSource ["Ramp", 0];

        _heli doMove (_destPos getPos [3000, random 360]);
        _heli flyInHeight 150;
        _heli limitspeed 250;

        sleep 60;
        { deleteVehicle _x } forEach _crew;
        deleteVehicle _heli;
    };
};

if (hasInterface) then {
    [] spawn {
        {
            if (alive _x && side _x == west) then {
                if (([_x] call BIS_fnc_getUnitInsignia) != "AMF_FRANCE_HV") then {
                    [_x, "AMF_FRANCE_HV"] call BIS_fnc_setUnitInsignia;
                };
            };
        } forEach allUnits;

        diag_log "[INTRO] CLIENT: Script démarré";
        waitUntil {
            !isNil "MISSION_intro_heli" && !isNil "MISSION_intro_combatPos" &&
            !isNil "MISSION_intro_unit_opfor" && !isNil "MISSION_intro_unit_indep"
        };

        private _heli      = MISSION_intro_heli;
        private _combatPos = MISSION_intro_combatPos;
        private _unitOpfor = MISSION_intro_unit_opfor;
        private _unitIndep = MISSION_intro_unit_indep;

        cutText ["", "BLACK FADED", 999];
        0 fadeSound 0;
        disableUserInput true;
        waitUntil { !isNull player };
        player allowDamage false;

        private _ppColor = ppEffectCreate ["ColorCorrections", 1500];
        _ppColor ppEffectEnable true;
        _ppColor ppEffectAdjust [1, 1.0, -0.01, [0.1, 0.1, 0.1, 0.1], [0.8, 0.8, 0.9, 0.6], [0.2, 0.2, 0.3, 0]];
        _ppColor ppEffectCommit 0;

        private _ppGrain = ppEffectCreate ["FilmGrain", 2005];
        _ppGrain ppEffectEnable true;
        _ppGrain ppEffectAdjust [0.15, 1.5, 1.5, 0.1, 1.0, false];
        _ppGrain ppEffectCommit 0;

        private _cam = "camera" camCreate [_combatPos select 0, _combatPos select 1, 20];
        _cam cameraEffect ["INTERNAL", "BACK"];
        showCinemaBorder true;
        sleep 2;

        private _txtFadeIn  = 0.5;
        private _txtVisible = 7.9;
        private _txtFadeOut = 0.5;
        private _txtDelay   = 3.0;

        private _line11 = localize "STR_Intro_Line11_Member";
        if (leader group player == player) then {
            _line11 = localize "STR_Intro_Line11_Leader";
        };
        private _introTexts = [
            localize "STR_Intro_Line1",
            localize "STR_Intro_Line2",
            localize "STR_Intro_Line3",
            localize "STR_Intro_Line4",
            localize "STR_Intro_Line5",
            localize "STR_Intro_Line6",
            localize "STR_Intro_Line7",
            localize "STR_Intro_Line8",
            localize "STR_Intro_Line9",
            localize "STR_Intro_Line10",
            format [_line11, name player],
            localize "STR_Intro_Line12",
            localize "STR_Intro_Line13",
            localize "STR_Intro_Line14",
            localize "STR_Intro_Line15",
            localize "STR_Intro_Line16"
        ];

        [_introTexts, _txtDelay, _txtFadeIn, _txtVisible, _txtFadeOut] spawn {
            params ["_texts", "_delay", "_fadeIn", "_visible", "_fadeOut"];
            sleep _delay;
            {
                titleText [_x, "PLAIN", _fadeIn];
                sleep (_fadeIn + _visible);
                titleText ["", "PLAIN", _fadeOut];
                sleep _fadeOut;
            } forEach _texts;
        };

        cutText ["", "BLACK IN", 3];
        3 fadeSound 1;

        _cam camPreparePos [(_combatPos select 0) - 120, (_combatPos select 1) - 120, 40];
        _cam camPrepareTarget _combatPos;
        _cam camPrepareFOV 0.8;
        _cam camCommitPrepared 0;

        _cam camPreparePos [(_combatPos select 0) - 30, (_combatPos select 1) - 50, 12];
        _cam camPrepareTarget [(_combatPos select 0), (_combatPos select 1), 2];
        _cam camPrepareFOV 0.55;
        _cam camCommitPrepared 10;
        sleep 10;

        detach _cam;
        _cam attachTo [_unitOpfor, [-0.6, -1.8, 0.9]];
        _cam camPrepareTarget (_unitOpfor getPos [5, getDir _unitOpfor]);
        _cam camPrepareFOV 0.5;
        _cam camCommitPrepared 0;
        _cam camPrepareTarget (_unitOpfor getPos [8, getDir _unitOpfor]);
        _cam camPrepareFOV 0.38;
        _cam camCommitPrepared 8;
        sleep 5;

        detach _cam;
        _cam attachTo [_unitIndep, [0.6, -1.8, 0.9]];
        _cam camPrepareTarget (_unitIndep getPos [5, getDir _unitIndep]);
        _cam camPrepareFOV 0.5;
        _cam camCommitPrepared 0;
        _cam camPrepareTarget (_unitIndep getPos [8, getDir _unitIndep]);
        _cam camPrepareFOV 0.38;
        _cam camCommitPrepared 8;
        sleep 5;

        detach _cam;
        _cam camPreparePos [(_combatPos select 0) - 120, (_combatPos select 1) - 120, 40];
        _cam camPrepareTarget _combatPos;
        _cam camPrepareFOV 0.8;
        _cam camCommitPrepared 0;
        playMusic "intro1a";
        _cam camPreparePos [(_combatPos select 0) - 30, (_combatPos select 1) - 50, 12];
        _cam camPrepareTarget [(_combatPos select 0), (_combatPos select 1), 2];
        _cam camPrepareFOV 0.55;
        _cam camCommitPrepared 10;
        sleep 10;

        detach _cam;
        _cam attachTo [_heli, [18, -38, 11]];
        _cam camSetTarget _heli;
        _cam camPrepareFOV 0.58;
        _cam camCommitPrepared 0;

        _cam camPreparePos (getPosATL _heli vectorAdd [22, -45, 13]);
        _cam camPrepareFOV 0.48;
        _cam camCommitPrepared 19;
        sleep 19;

        

        private _lzPos = getPosATL heliport_00;
_cam camPreparePos [
    (_lzPos select 0) + 38,
    (_lzPos select 1) - 25,
    (_lzPos select 2) + 0.35
];
_cam camSetTarget [_heli, 0, 0, 8];           // regarde légèrement vers le haut
_cam camPrepareFOV 0.28;                      // très serré = impact fort
_cam camCommitPrepared 0;

// Zoom out lent pendant l'approche
_cam camPrepareFOV 0.55;
_cam camCommitPrepared 20;

        waitUntil { vehicle player == player };

        cutText ["", "BLACK FADED", 1.5];
        sleep 1.5;

        _cam cameraEffect ["TERMINATE", "BACK"];
        camDestroy _cam;
        ppEffectDestroy _ppColor;
        ppEffectDestroy _ppGrain;
        player switchCamera "INTERNAL";

        showCinemaBorder false;
        player allowDamage true;
        disableUserInput false;
        disableUserInput true;
        disableUserInput false;

        cutText ["", "BLACK IN", 3];
    };
};