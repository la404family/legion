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

        for "_i" from 1 to 20 do {
            private _u1 = _grpOpfor createUnit ["O_G_Soldier_F", _posOpfor getPos [random 30, random 360], [], 0, "NONE"];
            private _u2 = _grpIndep createUnit ["I_G_Soldier_F", _posIndep getPos [random 30, random 360], [], 0, "NONE"];
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
            if (random 1 > 0.5) then { _x setUnitPos "MIDDLE"; } else { _x setUnitPos "UP"; };
            _x allowDamage true;
        } forEach _fakeUnits;

        [_fakeUnits] spawn {
            params ["_units"];
            sleep 45;
            { deleteVehicle _x } forEach _units;
        };

        private _startDist = 3500;
        private _startDir = (_destPos getDir _combatPos) - 180;
        private _startPos = _destPos getPos [_startDist, _startDir];
        _startPos set [2, 80];

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

        _heli limitspeed 150;
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

        private _txtFadeIn  = 0.3;
        private _txtVisible = 5.5; 
        private _txtFadeOut = 0.3;
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
                // Formatage du texte : Police (font) et Taille (size)
                // Arma 3 n'a pas de police "serif" classique intégrée (comme Times New Roman).
                // Polices possibles: "PuristaMedium", "PuristaBold", "RobotoCondensed", "EtelkaNarrowMediumPro", "PuristaLight"
                // Changez size='1.5' pour modifier la taille (ex: 2.0 pour plus grand, 1.0 pour plus petit)
                private _styledText = format ["<t font='EtelkaNarrowMediumPro' size='2.5' shadow='2'>%1</t>", _x];
                
                titleText [_styledText, "PLAIN", _fadeIn, false, true]; // "true" à la fin active le texte structuré
                sleep (_fadeIn + _visible);
                titleText ["", "PLAIN", _fadeOut, false, true];
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
        sleep 9;

       // ==========================================
        // PLAN COMBAT 1 : Vue de haut OPFOR vers INDEP
        // ==========================================
        detach _cam;
        private _posOpfor = getPosATL _unitOpfor;
        private _posIndep = getPosATL _unitIndep;
        private _dirToIndep = _posOpfor getDir _posIndep;
        
        // Position de départ (en retrait et en hauteur)
        _cam camSetPos [(_posOpfor#0) - (sin _dirToIndep * 25), (_posOpfor#1) - (cos _dirToIndep * 25), (_posOpfor#2) + 15];
        _cam camSetTarget _unitIndep;
        _cam camSetFOV 0.45;
        _cam camCommit 0;

        // Mouvement panoramique cinématique vers la cible
        _cam camSetPos [(_posOpfor#0) - (sin _dirToIndep * 10), (_posOpfor#1) - (cos _dirToIndep * 10), (_posOpfor#2) + 8];
        _cam camSetFOV 0.35;
        _cam camCommit 7;
        sleep 10;

        // ==========================================
        // PLAN COMBAT 2 : Vue de haut INDEP vers OPFOR
        // ==========================================
        detach _cam;
        _posOpfor = getPosATL _unitOpfor;
        _posIndep = getPosATL _unitIndep;
        private _dirToOpfor = _posIndep getDir _posOpfor;

        // Position de départ inverse (côté INDEP)
        _cam camSetPos [(_posIndep#0) - (sin _dirToOpfor * 25), (_posIndep#1) - (cos _dirToOpfor * 25), (_posIndep#2) + 15];
        _cam camSetTarget _unitOpfor;
        _cam camSetFOV 0.45;
        _cam camCommit 0;

        // Mouvement panoramique cinématique
        _cam camSetPos [(_posIndep#0) - (sin _dirToOpfor * 10), (_posIndep#1) - (cos _dirToOpfor * 10), (_posIndep#2) + 8];
        _cam camSetFOV 0.35;
        _cam camCommit 7;
        sleep 10;

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
        cutText ["", "BLACK FADED", 1];
        sleep 1;
        cutText ["", "BLACK IN", 1];
        
        private _orbStartTime = time;
        private _orbDuration = 35;
        private _orbitAngle = -90;   
        private _updateInterval = 0.1;   
        private _commitTime = 0.5;       
        while { time < _orbStartTime + _orbDuration } do {
            private _progress = (time - _orbStartTime) / _orbDuration;
            _orbitAngle = -90 + (_progress * 135);
            private _distance = 35 - (_progress * 10);
            private _height = 12;
            private _heliPos = getPosATL _heli;
            private _heliDir = getDir _heli;
            private _finalAngle = _heliDir + _orbitAngle;
            private _camX = (_heliPos select 0) + (sin _finalAngle * _distance);
            private _camY = (_heliPos select 1) + (cos _finalAngle * _distance);
            private _camZ = (_heliPos select 2) + _height;
            _cam camSetPos [_camX, _camY, _camZ];
            _cam camSetTarget _heli;
            _cam camSetFov 0.75;
            _cam camCommit _commitTime;   
            sleep _updateInterval;   
        };
        
        detach _cam;
        cutText ["", "BLACK FADED", 0.5];
        sleep 0.5;
        
        private _lzPos = getPosATL heliport_00;
        private _aerialCamPos = [
            (_lzPos select 0),
            (_lzPos select 1) - 90,
            (_lzPos select 2) + 35
        ];
        _cam camSetPos _aerialCamPos;
        _cam camSetTarget _lzPos;
        _cam camSetFov 0.55;
        _cam camCommit 0;
        waitUntil { camCommitted _cam };
        cutText ["", "BLACK IN", 1];
        
        private _rampOpened = false;
        private _plan5StartTime = time;
        while { !isTouchingGround _heli && (getPos _heli select 2) > 1 && vehicle player != player } do {
            private _progress = (time - _plan5StartTime) / 5;
            private _baseHeight = 35;
            private _descent = _progress * 5;  
            private _finalZ = ((_lzPos select 2) + _baseHeight - _descent) max ((_lzPos select 2) + 2);
            private _newCamPos = [
                (_lzPos select 0) + (sin (time * 5) * 12),
                (_lzPos select 1) - 90 + (cos (time * 5) * 12),
                _finalZ
            ];
            _cam camSetPos _newCamPos;
            _cam camSetFov ((0.55 - (_progress * 0.15)) max 0.2); 
            _cam camCommit 0.5;
            sleep 0.2;
        };

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