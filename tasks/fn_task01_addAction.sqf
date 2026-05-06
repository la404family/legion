#include "..\macros.hpp"

/*
 * TAG_fnc_task01_addAction
 *
 * Description:
 *   Ajoute l'action d'interaction "Parler au chef de milice" sur le client local.
 *   Appelée via remoteExec depuis le serveur (fn_task01) sur toutes les machines
 *   ayant une interface (hasInterface). Le callback de l'action déclenche le
 *   scénario sur le serveur via remoteExec ["TAG_fnc_task01_runScenario", 2].
 *
 * Arguments:
 *   0: <OBJECT> Le chef de milice
 *   1: <ARRAY>  Les gardes
 *   2: <STRING> ID du marqueur de tâche
 *
 * Return Value:
 *   None
 *
 * Locality:
 *   Client (hasInterface)
 *
 * Example:
 *   [_chief, _guards, "TAG_task01_rdv"] remoteExec ["TAG_fnc_task01_addAction", 0];
 */

if (!hasInterface) exitWith {};

params [
    ["_chief",    objNull, [objNull]],
    ["_guards",   [],      [[]]],
    ["_markerID", "",      [""]]
];

if (isNull _chief) exitWith {};

_chief addAction [
    "<t color='#FFFF00'>Parler au chef de milice</t>",
    {
        params ["_target", "_caller", "_id", "_args"];
        _args params ["_guards", "_markerID"];

        // Anti-déclenchement multiple
        if (missionNamespace getVariable ["TAG_Task01_Triggered", false]) exitWith {};
        missionNamespace setVariable ["TAG_Task01_Triggered", true, true];

        _target removeAction _id;

        // Choisir un scénario aléatoire et l'exécuter sur le serveur
        private _scen = 1 + floor (random 3);
        [_scen, _target, _guards, _markerID] remoteExec ["TAG_fnc_task01_runScenario", 2];
    },
    [_guards, _markerID], // arguments passés au callback
    10,   // priorité
    true, // showWindow
    true, // hideOnUse
    "",   // shortcut
    "alive _target && _this distance _target < 4", // condition
    4     // distance de détection
];
