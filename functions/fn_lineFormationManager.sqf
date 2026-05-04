#include "..\macros.hpp"

/*
 * TAG_fnc_lineFormationManager
 *
 * Description:
 *   Ajoute l'action "Formation en Ligne et Fumigènes" au joueur leader.
 *   Les IA désactivent l'auto-combat pour sprinter en ignorant les tirs,
 *   se placent en ligne défensive perpendiculaire à la direction du joueur,
 *   lancent une fumigène vers l'avant avec animation réelle (régénérée à 45s),
 *   et redeviennent agressives une fois en position.
 *
 * Locality:
 *   Client
 */

if (!hasInterface) exitWith {};

[] spawn {
    private _fnc_addLineFormationAction = {
        params ["_unit"];
        
        if (_unit getVariable ["TAG_Action_LineFormation_Added", false]) exitWith {};
        _unit setVariable ["TAG_Action_LineFormation_Added", true];

        _unit addAction [
            localize "STR_TAG_Action_LineFormation",
            {
                params ["_target", "_caller", "_actionId", "_arguments"];

                private _squadAI = (units group _caller) select { !isPlayer _x && alive _x && vehicle _x == _x };
                if (count _squadAI == 0) exitWith { 
                    systemChat localize "STR_TAG_Msg_Line_NoAI"; 
                };

                // Ordre vocal du leader
                _caller groupChat localize "STR_TAG_Msg_Line_Ordered";
                _caller playActionNow "gestureAdvance";

                // On spawn TOUT le reste pour pouvoir utiliser sleep
                [_squadAI, _caller] spawn {
                    params ["_squadAI", "_caller"];

                    private _totalAI = count _squadAI;
                    private _playerDir = getDir _caller;
                    private _perpDir = _playerDir + 90;
                    private _spacing = 4;
                    private _totalWidth = (_totalAI - 1) * _spacing;
                    private _forwardDist = 8 + (random 2);

                    // ══════════════════════════════════════════════════════════
                    // ÉTAPE 1 : RASSEMBLEMENT (annule TOUT ordre STOP précédent)
                    // commandFollow = commande REGROUP du menu, l'inverse exact de doStop
                    // ══════════════════════════════════════════════════════════
                    {
                        _x enableAI "MOVE";
                        _x enableAI "PATH";
                        _x enableAI "FSM";
                        _x enableAI "ANIM";
                        _x forceSpeed -1;
                        _x setUnitPos "AUTO";
                    } forEach _squadAI;

                    _squadAI commandFollow _caller;

                    // Laisser le moteur Arma traiter le rassemblement
                    sleep 1;

                    // ══════════════════════════════════════════════════════════
                    // ÉTAPE 2 : POSITIONNEMENT EN LIGNE
                    // ══════════════════════════════════════════════════════════
                    {
                        private _ai = _x;
                        private _index = _forEachIndex;

                        private _lateralOffset = (_index * _spacing) - (_totalWidth / 2);
                        private _posX = (getPos _caller select 0) 
                            + (_forwardDist * sin _playerDir) 
                            + (_lateralOffset * sin _perpDir);
                        private _posY = (getPos _caller select 1) 
                            + (_forwardDist * cos _playerDir) 
                            + (_lateralOffset * cos _perpDir);
                        private _defendPos = [_posX, _posY, 0];

                        [_ai, _defendPos, _playerDir, _caller] spawn {
                            params ["_ai", "_defendPos", "_playerDir", "_caller"];

                            if (!alive _ai) exitWith {};

                            // Configuration sprint
                            _ai disableAI "AUTOCOMBAT";
                            _ai disableAI "SUPPRESSION";
                            _ai disableAI "TARGET";     
                            _ai disableAI "AUTOTARGET"; 
                            _ai setUnitPos "UP";
                            _ai setSpeedMode "FULL";
                            _ai forceSpeed 24;

                            _ai doMove _defendPos;

                            if (alive _ai) then {
                                // ARRIVÉ : Réinitialiser la vitesse forcée
                                _ai forceSpeed -1;
                                
                                // Tous regardent vers l'avant
                                private _lookPos = _caller getPos [100, _playerDir];
                                _ai doWatch _lookPos;
                                sleep 1.5;

                                if (!alive _ai) exitWith {};

                                // Détecter dynamiquement si elle possède un fumigène
                                private _smokeMag = "";
                                {
                                    private _magLower = toLower _x;
                                    if ("smoke" in _magLower || "fumi" in _magLower || "f5" in _magLower) exitWith {
                                        _smokeMag = _x;
                                    };
                                } forEach (magazines _ai);

                                // CINÉMATIQUE DE LANCER DE FUMIGÈNE
                                // Délai aléatoire pour décaler les lancers entre soldats
                                sleep (random 2);
                                if (!alive _ai) exitWith {};

                                if (_smokeMag != "") then {
                                    _ai playActionNow "ThrowGrenade";
                                    sleep 0.7;

                                    if (alive _ai) then {
                                        _ai removeMagazine _smokeMag;
                                        private _ammoClass = getText (configFile >> "CfgMagazines" >> _smokeMag >> "ammo");

                                        if (_ammoClass != "") then {
                                            private _smokePos = _ai modelToWorld [0, 1, 1.5];
                                            private _smoke = _ammoClass createVehicle _smokePos;
                                            _smoke setVelocity [sin _playerDir * 15, cos _playerDir * 15, 6];
                                        };

                                        [_ai, _smokeMag] spawn {
                                            params ["_ai", "_smokeMag"];
                                            sleep 45;
                                            if (alive _ai) then {
                                                _ai addMagazine _smokeMag;
                                            };
                                        };
                                    };
                                };

                                sleep 1;

                                // REPASSAGE EN MODE AGRESSIF
                                _ai enableAI "AUTOCOMBAT";
                                _ai enableAI "SUPPRESSION";
                                _ai enableAI "TARGET";
                                _ai enableAI "AUTOTARGET";
                                _ai setUnitPos "AUTO";
                                _ai setBehaviourStrong "COMBAT";

                                sleep 45;
                                if (alive _ai) then {
                                    _ai doWatch objNull;
                                };
                            };
                        };
                    } forEach _squadAI;
                };
            },
            [],
            5.35,
            false,
            true,
            "",
            // Seulement visible pour le leader avec des IA
            "leader group _target == _target && { { !isPlayer _x } count (units group _target) > 0 }"
        ];
    };

    private _lastPlayer = objNull;
    while {true} do {
        waitUntil { sleep 1; player != _lastPlayer };  
        
        _lastPlayer = player;
        if (!isNull _lastPlayer) then {
            [_lastPlayer] call _fnc_addLineFormationAction;
        };
    };
};
