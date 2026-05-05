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
        private _combatPos = _destPos getPos [800, random 360];
        _combatPos set [2, 0];
        
        // Variables partagées pour les caméras clientes
        MISSION_intro_combatPos = _combatPos;
        publicVariable "MISSION_intro_combatPos";
        
        private _grpOpfor = createGroup east;
        private _grpIndep = createGroup resistance;
        private _fakeUnits = [];

        // Distancer les deux camps d'environ 100m pour qu'ils ne soient pas entassés
        private _angleOpfor = random 360;
        private _posOpfor = _combatPos getPos [50, _angleOpfor];
        private _posIndep = _combatPos getPos [50, _angleOpfor + 180];

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

        // Forcer le combat statique pour la caméra
        _grpOpfor setCombatMode "RED";
        _grpIndep setCombatMode "RED";
        {
            _x disableAI "PATH";
            if (random 1 > 0.5) then { _x setUnitPos "MIDDLE"; } else { _x setUnitPos "DOWN"; };
            _x allowDamage false; // on ne veut pas qu'ils meurent trop vite pendant la cinématique
        } forEach _fakeUnits;
        
        // Supprimer les unités de la scène de guerre rapidement après que la caméra les ait quittés (environ 30s)
        [_fakeUnits] spawn {
            params ["_units"];
            sleep 30;
            { deleteVehicle _x } forEach _units;
        };
        
        // --- 2. Création et gestion de l'hélicoptère ---
        // Distance réduite pour ne pas faire durer le vol inutilement (environ 2500m)
        private _startDist = 2500; 
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
        waitUntil { !isNil "MISSION_intro_heli" && !isNil "MISSION_intro_combatPos" };  
        
        private _heli = MISSION_intro_heli;
        private _combatPos = MISSION_intro_combatPos;

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

        playMusic "intro1a";    
        3 fadeSound 1;          
        
        // Initialisation de la caméra
        private _cam = "camera" camCreate [_combatPos select 0, _combatPos select 1, 20];
        _cam cameraEffect ["INTERNAL", "BACK"];
        showCinemaBorder true;
        sleep 2;
        
        // Lancement en parallèle des sous-titres, centrés HAUTEUR/LARGEUR (-1, -1) 
        // avec la DUREE EXACTE IDENTIQUE pour chaque texte découpé selon le fichier STORY.md
        // Support multicaviers (Stringtable) et check dynamique (Leader/Membre)
        [] spawn {
            private _line11 = localize "STR_Intro_Line11_Member";
            if (leader group player == player) then {
                _line11 = localize "STR_Intro_Line11_Leader";
            };

            private _texts = [
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
            private _duration = 3.9; // Ajustement du temps pour répartir les 16 segments sur ~62s (taille de l'intro)
            sleep 4; // Attendre le fondu
            
            {
                [
                    format ["<t size='1.1' color='#ffffff' font='PuristaMedium' shadow='2' align='center'>%1</t>", _x],
                    -1, -1, _duration, 1, 0, 780
                ] spawn BIS_fnc_dynamicText;
                sleep _duration;
            } forEach _texts;
        };

        cutText ["", "BLACK IN", 3];   

        // ==========================================
        // PLAN 1 : Vue large et plongeante sur les combats
        // ==========================================
        _cam camPreparePos [(_combatPos select 0) - 80, (_combatPos select 1) - 80, 25];
        _cam camPrepareTarget _combatPos;
        _cam camPrepareFOV 0.75;
        _cam camCommitPrepared 0;

        _cam camPreparePos [(_combatPos select 0) - 20, (_combatPos select 1) - 40, 10];
        _cam camPrepareTarget [(_combatPos select 0), (_combatPos select 1), 2];
        _cam camPrepareFOV 0.6;
        _cam camCommitPrepared 8; // Zoom lent
        sleep 8;

        // ==========================================
        // PLAN 2 : Plan serré (Tension sur l'action)
        // ==========================================
        _cam camPreparePos [(_combatPos select 0) + 15, (_combatPos select 1) + 10, 1.5];
        _cam camPrepareTarget [(_combatPos select 0) - 5, (_combatPos select 1) - 5, 1];
        _cam camPrepareFOV 0.4;
        _cam camCommitPrepared 0;

        _cam camPreparePos [(_combatPos select 0) + 12, (_combatPos select 1) + 12, 1.8];
        _cam camPrepareFOV 0.3; // Encore plus serré
        _cam camCommitPrepared 6;
        sleep 6;
        
        // ==========================================
        // PLAN 3 : Attaché derrière l'hélicoptère (Majestueux)
        // ==========================================
        _cam camPrepareTarget objNull; // Détache la cible fixe
        _cam attachTo [_heli, [-12, -30, 8]]; // Derrière et au dessus
        _cam setVectorDirAndUp [[0, 1, -0.15], [0, 0, 1]];
        _cam camPrepareFOV 0.8;
        _cam camCommitPrepared 0;
        sleep 10;
        
        // ==========================================
        // PLAN 4 : Traveling latéral sur l'hélicoptère (Vitesse et Action)
        // ==========================================
        detach _cam;
        _cam attachTo [_heli, [20, 5, 2]]; // Attaché sur le flanc droit
        _cam setVectorDirAndUp [[-1, -0.2, 0.1], [0, 0, 1]]; // Regarde l'hélico
        _cam camPrepareFOV 0.65;
        _cam camCommitPrepared 0;

        _cam camPrepareFOV 0.5; // Zoom léger sur le profil
        _cam camCommitPrepared 12;
        sleep 12;

        // ==========================================
        // PLAN 5 : Intérieur/Proche porte ou vue depuis le nez
        // ==========================================
        detach _cam;
        _cam attachTo [_heli, [3, 2, -1.5]]; // Très proche de la porte latérale ouverte
        _cam setVectorDirAndUp [[0, -1, 0], [0, 0, 1]]; // Regarde vers l'arrière dans la soute
        _cam camPrepareFOV 0.7;
        _cam camCommitPrepared 0;
        sleep 12;
        
        // ==========================================
        // PLAN 6 : Débarquement final (Fixe regardant atterrir l'hélico)
        // ==========================================
        detach _cam;
        private _lzPos = [0,0,0];
        if (!isNil "heliport_00" && { !isNull heliport_00 }) then {
            _lzPos = getPosATL heliport_00;
        } else {
            private _fb = missionNamespace getVariable ["player_0", objNull];
            if (!isNull _fb) then { _lzPos = getPosATL _fb; };
        };
        
        _cam camPreparePos [(_lzPos select 0) + 30, (_lzPos select 1) - 40, (_lzPos select 2) + 2];
        _cam camPrepareTarget _heli;
        _cam camPrepareFOV 0.7;
        _cam camCommitPrepared 0;

        _cam camPrepareFOV 0.45;
        _cam camCommitPrepared 12; // Suit l'hélico cible en zoomant doucement
        sleep 11;
        
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