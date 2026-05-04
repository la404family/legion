#include "..\macros.hpp"

/*
 * TAG_fnc_retreatActionManager
 *
 * Description:
 *   Ajoute l'action "Repli Tactique" au joueur leader.
 *   Les IA jettent une fumigène, désactivent l'auto-combat pour sprinter 
 *   en ignorant les tirs, forment un cercle à 360° autour du joueur,
 *   et redeviennent agressives une fois en position.
 *
 * Locality:
 *   Client
 */

if (!hasInterface) exitWith {};

[] spawn {
    private _fnc_addRetreatAction = {
        params ["_unit"];
        
        if (_unit getVariable ["TAG_Action_Retreat_Added", false]) exitWith {};
        _unit setVariable ["TAG_Action_Retreat_Added", true];

        _unit addAction [
            localize "STR_TAG_Action_Retreat",
            {
                params ["_target", "_caller", "_actionId", "_arguments"];

                private _squadAI = (units group _caller) select { !isPlayer _x && alive _x && vehicle _x == _x };
                if (count _squadAI == 0) exitWith { 
                    systemChat localize "STR_TAG_Msg_Retreat_NoAI"; 
                };

                // Ordre vocal du leader
                _caller groupChat localize "STR_TAG_Msg_Retreat_Ordered";
                _caller playActionNow "gestureFreeze";

                // On spawn TOUT le reste pour pouvoir utiliser sleep
                [_squadAI, _caller] spawn {
                    params ["_squadAI", "_caller"];

                    private _totalAI = count _squadAI;

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
                    // ÉTAPE 2 : POSITIONNEMENT INDIVIDUEL (360° autour du leader)
                    // ══════════════════════════════════════════════════════════
                    {
                        private _ai = _x;
                        private _index = _forEachIndex;

                        private _angle = (360 / _totalAI) * _index;
                        private _radius = 2 + (random 4);
                        private _defendPos = _caller getPos [_radius, _angle];

                        [_ai, _defendPos, _angle, _caller] spawn {
                            params ["_ai", "_defendPos", "_angle", "_caller"];

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
                                
                                // On se tourne vers l'extérieur pour le 360°
                                private _lookPos = _caller getPos [100, _angle];
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
                                            private _dir = getDir _ai;
                                            _smoke setVelocity [sin _dir * 15, cos _dir * 15, 6];
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
            5.4,
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
            [_lastPlayer] call _fnc_addRetreatAction;
        };
    };
};
