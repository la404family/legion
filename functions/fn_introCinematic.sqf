/*
 * TAG_fnc_introCinematic
 *
 * Description:
 *   Gère l'introduction cinématique avec mise en scène avancée :
 *   - Affrontement INDEPENDENT vs OPFOR
 *   - Caméra fluide (camPrepare / camCommit)
 *   - FOV variables, montage dynamique, attachTo
 *   - Arrivée en Hélicoptère et débarquement sur heliport_00
 */

if (isServer) then {
    [] spawn {
        diag_log "[INTRO] SERVER: Script démarré (Préparation de la scène de combat)";
        waitUntil { time > 0.1 };
        
        // --- 1. Création d'une zone de combat "Milices" aléatoire pour la cinématique ---
        private _hqPos = [0,0,0];
        if (!isNil "heliport_00" && { !isNull heliport_00 }) then {
            _hqPos = getPosATL heliport_00;
        } else {
            // Tentative de fallback
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
        // Recherche d'une zone plate et dégagée (même logique que fn_callAmmoDrop)
        private _flatCheck = _combatPos isFlatEmpty [10, -1, 0.2, 10, 0, false, objNull];
        if (_flatCheck isEqualTo []) then {
            private _safePos = [_combatPos, 0, 300, 10, 0, 0.2, 0, [], _combatPos] call BIS_fnc_findSafePos;
            if (_safePos isEqualType [] && { count _safePos >= 2 } && { _safePos distance2D _combatPos < 500 }) then {
                _combatPos = _safePos;
                _combatPos set [2, 0];
            };
        };
        
        // Variables partagées pour les caméras clientes
        MISSION_intro_combatPos = _combatPos;
        publicVariable "MISSION_intro_combatPos";
        
        private _grpOpfor = createGroup east;
        private _grpIndep = createGroup resistance;
        private _fakeUnits = [];

        // Distancer les deux camps d'environ 100m pour qu'ils ne soient pas entassés
        private _angleOpfor = random 360;
        private _posOpfor = _combatPos getPos [80, _angleOpfor];
        private _posIndep = _combatPos getPos [80, _angleOpfor + 180];

        // Spawn de quelques insurgés/milices (OPFOR O_G_Soldier_F vs INDEP I_G_Soldier_F)
        for "_i" from 1 to 6 do {
            private _u1 = _grpOpfor createUnit ["O_G_Soldier_F", _posOpfor getPos [random 15, random 360], [], 0, "NONE"];
            private _u2 = _grpIndep createUnit ["I_G_Soldier_F", _posIndep getPos [random 15, random 360], [], 0, "NONE"];
            
            // Les forcer à regarder l'adversaire
            _u1 setDir (_u1 getDir _posIndep);
            _u2 setDir (_u2 getDir _posOpfor);
            
            _fakeUnits pushBack _u1;
            _fakeUnits pushBack _u2;
        };

        // Partager les références d'unités avec les clients pour le suivi caméra
        MISSION_intro_unit_opfor = leader _grpOpfor;
        publicVariable "MISSION_intro_unit_opfor";
        MISSION_intro_unit_indep = leader _grpIndep;
        publicVariable "MISSION_intro_unit_indep";

        // Les deux groupes s'avancent l'un vers l'autre et s'engagent
        _grpOpfor setCombatMode "RED";
        _grpIndep setCombatMode "RED";
        _grpOpfor setBehaviour "COMBAT";
        _grpIndep setBehaviour "COMBAT";

        // OPFOR avance vers la position INDEP, INDEP avance vers la position OPFOR
        { _x doMove _posIndep } forEach units _grpOpfor;
        { _x doMove _posOpfor } forEach units _grpIndep;

        {
            if (random 1 > 0.5) then { _x setUnitPos "MIDDLE"; } else { _x setUnitPos "DOWN"; };
            _x allowDamage false; // on ne veut pas qu'ils meurent pendant la cinématique
        } forEach _fakeUnits;
        
        // Supprimer les unités de la scène de guerre après les plans de combat (environ 45s)
        [_fakeUnits] spawn {
            params ["_units"];
            sleep 45;
            { deleteVehicle _x } forEach _units;
        };
        
        // --- 2. Création et gestion de l'hélicoptère ---
        // Distance plus grande pour allonger la cinématique de vol (~4500m)
        private _startDist = 4500; 
        private _startDir = (_destPos getDir _combatPos) - 180; 
        private _startPos = _destPos getPos [_startDist, _startDir];
        _startPos set [2, 100];   
        
        private _heliClass = "B_AMF_Heli_Transport_01_F";
        private _heli = createVehicle [_heliClass, _startPos, [], 0, "FLY"];
        _heli setPos _startPos;
        _heli setDir (_heli getDir _destPos);   
        _heli flyInHeight 40; // Vol TTB (Très Très Bas) immersif
        _heli allowDamage false;                 
        
        MISSION_intro_heli = _heli;
        publicVariable "MISSION_intro_heli";
        
        createVehicleCrew _heli;   
        private _crew = crew _heli;
        { _x allowDamage false; } forEach _crew;   
        
        private _grpHeli = group driver _heli;
        _grpHeli setBehaviour "CARELESS";   
        _grpHeli setCombatMode "BLUE";      

        // Charger les joueurs
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
        _heli limitspeed 220; // Vitesse élevée pour l'effet dynamique

        // La landing sequence
        waitUntil { !alive _heli || { (_heli distance2D _destPos) < 500 } };
        if (!alive _heli) exitWith {};
        _heli setVariable ["landing_started", true, true];
        
        // Ouverture des portes arrières
        [_heli, ["door_rear_source", 1]] remoteExec ["animateSource", 0, true];
        [_heli, ["Ramp", 1]] remoteExec ["animateSource", 0, true];

        _heli limitspeed 100;
        waitUntil { !alive _heli || { (_heli distance2D _destPos) < 200 } };
        if (!alive _heli) exitWith {};
        _heli land "GET OUT";

        waitUntil { !alive _heli || { isTouchingGround _heli || ((getPosATL _heli) select 2) < 2 } };
        sleep 2;
        
        // Ejection des joueurs
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
        // Appliquer l'écusson
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

        private _heli         = MISSION_intro_heli;
        private _combatPos    = MISSION_intro_combatPos;
        private _unitOpfor    = MISSION_intro_unit_opfor;
        private _unitIndep    = MISSION_intro_unit_indep;

        cutText ["", "BLACK FADED", 999];   
        0 fadeSound 0;                       
        disableUserInput true;               
        waitUntil { !isNull player };
        player allowDamage false;            

        // Effets visuels style "Guerre / Dramatique"
        private _ppColor = ppEffectCreate ["ColorCorrections", 1500];   
        _ppColor ppEffectEnable true;
        _ppColor ppEffectAdjust [1, 1.0, -0.01, [0.1, 0.1, 0.1, 0.1], [0.8, 0.8, 0.9, 0.6], [0.2, 0.2, 0.3, 0]]; 
        _ppColor ppEffectCommit 0;   

        private _ppGrain = ppEffectCreate ["FilmGrain", 2005];   
        _ppGrain ppEffectEnable true;
        _ppGrain ppEffectAdjust [0.15, 1.5, 1.5, 0.1, 1.0, false];   
        _ppGrain ppEffectCommit 0;

        // Initialisation de la caméra
        private _cam = "camera" camCreate [_combatPos select 0, _combatPos select 1, 20];
        _cam cameraEffect ["INTERNAL", "BACK"];
        showCinemaBorder true;
        sleep 2;

        // ==========================================
        // CONFIGURATION TEXTE — indépendant de la caméra
        // Modifier ces 4 valeurs pour changer le timing de TOUS les textes
        // ==========================================
        // Cinématique totale ~150s — texte réparti uniformément sur toute la durée
        // 16 segments × 8.9s = 142s — démarre à t≈8s, finit à t≈150s
        private _txtFadeIn  = 0.5;  // Fondu entrant (s)
        private _txtVisible = 7.9;  // Pleine visibilité (s)
        private _txtFadeOut = 0.5;  // Fondu sortant (s)
        private _txtDelay   = 3.0;  // Délai avant le 1er texte (après fondu écran)

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

        // Thread texte — totalement isolé de la caméra
        // titleText "PLAIN" : texte centré STATIQUE, aucun mouvement vertical
        // Note : titleText ne parse pas le HTML — texte brut uniquement
        // Durée identique pour CHAQUE segment : _txtFadeIn + _txtVisible + _txtFadeOut
        [_introTexts, _txtDelay, _txtFadeIn, _txtVisible, _txtFadeOut] spawn {
            params ["_texts", "_delay", "_fadeIn", "_visible", "_fadeOut"];
            sleep _delay;
            {
                // fade in → reste immobile → fade out → silence avant le suivant
                titleText [_x, "PLAIN", _fadeIn];
                sleep (_fadeIn + _visible);
                titleText ["", "PLAIN", _fadeOut];
                sleep _fadeOut;
            } forEach _texts;
        };

        cutText ["", "BLACK IN", 3];
        // Sons ambiants (combat) audibles dès le début — musique après seulement
        3 fadeSound 1;

        // ==========================================
        // PLAN 1 : Vue large plongeante — introduction du conflit
        // Caméra haute, on découvre le champ de bataille de loin
        // ==========================================
        _cam camPreparePos [(_combatPos select 0) - 120, (_combatPos select 1) - 120, 40];
        _cam camPrepareTarget _combatPos;
        _cam camPrepareFOV 0.8;
        _cam camCommitPrepared 0;

        _cam camPreparePos [(_combatPos select 0) - 30, (_combatPos select 1) - 50, 12];
        _cam camPrepareTarget [(_combatPos select 0), (_combatPos select 1), 2];
        _cam camPrepareFOV 0.55;
        _cam camCommitPrepared 10;
        sleep 10;

        // ==========================================
        // PLAN 2 : Suivi épaule — unité OPFOR en approche
        // ==========================================
        detach _cam;
        _cam attachTo [_unitOpfor, [-0.6, -1.8, 0.9]];
        _cam camPrepareTarget (_unitOpfor getPos [5, getDir _unitOpfor]);
        _cam camPrepareFOV 0.5;
        _cam camCommitPrepared 0;
        _cam camPrepareTarget (_unitOpfor getPos [8, getDir _unitOpfor]);
        _cam camPrepareFOV 0.38;
        _cam camCommitPrepared 8;
        sleep 8;

        // ==========================================
        // PLAN 3 : Suivi épaule — unité INDEP en approche
        // ==========================================
        detach _cam;
        _cam attachTo [_unitIndep, [0.6, -1.8, 0.9]];
        _cam camPrepareTarget (_unitIndep getPos [5, getDir _unitIndep]);
        _cam camPrepareFOV 0.5;
        _cam camCommitPrepared 0;
        _cam camPrepareTarget (_unitIndep getPos [8, getDir _unitIndep]);
        _cam camPrepareFOV 0.38;
        _cam camCommitPrepared 8;
        sleep 8;

        // ==========================================
        // PLAN 4 : Vue haute dramatique — la mêlée vue du ciel
        // Caméra en hauteur qui descend lentement vers le combat
        // ==========================================
        detach _cam;
        _cam camPreparePos [(_combatPos select 0) + 5, (_combatPos select 1) + 80, 35];
        _cam camPrepareTarget [(_combatPos select 0), (_combatPos select 1), 1];
        _cam camPrepareFOV 0.6;
        _cam camCommitPrepared 0;

        _cam camPreparePos [(_combatPos select 0) - 10, (_combatPos select 1) + 30, 10];
        _cam camPrepareFOV 0.38;
        _cam camCommitPrepared 14;
        sleep 14;

        // Musique lancée après la scène de combat au sol
        playMusic "intro1a";

        // ==========================================
        // PLAN HELI-A : Poursuite derrière l'hélicoptère — découverte du paysage
        // Caméra 35m derrière, 10m au-dessus : on voit l'horizon défiler
        // ==========================================
        _cam attachTo [_heli, [0, -35, 10]];
        _cam camSetTarget _heli;
        _cam camPrepareFOV 0.8;
        _cam camCommitPrepared 0;
        _cam camPrepareFOV 0.6;
        _cam camCommitPrepared 20;
        sleep 20;

        // ==========================================
        // PLAN HELI-B : Profil droit — vue cinéma classique
        // Caméra 28m sur le flanc droit, légèrement au-dessus — paysage en arrière-plan
        // ==========================================
        detach _cam;
        _cam attachTo [_heli, [28, 0, 6]];
        _cam camSetTarget _heli;
        _cam camPrepareFOV 0.75;
        _cam camCommitPrepared 0;
        _cam camPrepareFOV 0.52;
        _cam camCommitPrepared 20;
        sleep 20;

        // ==========================================
        // PLAN HELI-C : Vue plongeante du ciel — l'hélico vu d'en haut
        // Caméra 65m au-dessus solidaire : on voit l'hélico ET le terrain en dessous
        // ==========================================
        detach _cam;
        _cam attachTo [_heli, [0, 0, 65]];
        _cam camSetTarget _heli;
        _cam camPrepareFOV 0.65;
        _cam camCommitPrepared 0;
        _cam camPrepareFOV 0.45;
        _cam camCommitPrepared 18;
        sleep 18;

        // ==========================================
        // PLAN HELI-D : Caméra fixe au sol sur la LZ — ras des bottes
        // Vue dramatique à 0.3m du sol, 35m à côté — l'hélico grossit dans le cadre
        // ==========================================
        detach _cam;
        _cam camSetTarget objNull;
        private _lzPos = [0,0,0];
        if (!isNil "heliport_00" && { !isNull heliport_00 }) then {
            _lzPos = getPosATL heliport_00;
        } else {
            private _fb = missionNamespace getVariable ["player_0", objNull];
            if (!isNull _fb) then { _lzPos = getPosATL _fb; };
        };
        _cam camPreparePos [(_lzPos select 0) + 35, (_lzPos select 1) - 20, (_lzPos select 2) + 0.3];
        _cam camSetTarget _heli;
        _cam camPrepareFOV 0.85;
        _cam camCommitPrepared 0;
        _cam camPrepareFOV 0.3;  // Zoom fort : l'hélico grossit progressivement
        _cam camCommitPrepared 15;
        sleep 15;

        // ==========================================
        // PLAN HELI-E : Nez-à-nez — l'hélico arrive droit sur la caméra
        // Caméra 80m devant la LZ à hauteur d'homme — l'hélico passe au-dessus
        // ==========================================
        _cam camPreparePos [(_lzPos select 0) - 80, (_lzPos select 1) + 10, (_lzPos select 2) + 1.5];
        _cam camSetTarget _heli;
        _cam camPrepareFOV 0.75;
        _cam camCommitPrepared 0;
        _cam camPrepareFOV 0.35;
        _cam camCommitPrepared 15;
        sleep 15;

        // ==========================================
        // PLAN FINAL : Vue surélevée LZ — atterrissage et débarquement
        // Caméra à 20m de hauteur, large — toute la LZ visible, hélico se pose
        // ==========================================
        _cam camPreparePos [(_lzPos select 0) + 45, (_lzPos select 1) + 45, (_lzPos select 2) + 20];
        _cam camSetTarget _heli;
        _cam camPrepareFOV 0.75;
        _cam camCommitPrepared 0;
        _cam camPrepareFOV 0.5;
        _cam camCommitPrepared 20;
        sleep 20;

        // Attente du débarquement effectif du joueur
        waitUntil { vehicle player == player };

        cutText ["", "BLACK FADED", 1.5];
        sleep 1.5;

        // ==========================================
        // FIN ET NETTOYAGE
        // ==========================================
        _cam cameraEffect ["TERMINATE", "BACK"];   
        camDestroy _cam;                           
        ppEffectDestroy _ppColor;                  
        ppEffectDestroy _ppGrain;                  
        player switchCamera "INTERNAL";   
        
        showCinemaBorder false;           
        player allowDamage true;          
        disableUserInput false;
        disableUserInput true; // Fix engine input glitch
        disableUserInput false;

        cutText ["", "BLACK IN", 3];   
    };
};