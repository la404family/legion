#include "..\macros.hpp"

/*
 * TAG_fnc_task02_addAction
 *
 * Description:
 *   Ajoute l'action "Ramasser les documents TOP SECRET" sur l'objet document
 *   au sol (Land_Document_01_F). Appelée via remoteExec depuis le serveur.
 *   Le callback supprime l'objet, met la tâche à SUCCEEDED et publie la variable.
 *
 * Arguments:
 *   0: <OBJECT> L'objet document (Land_Document_01_F) posé au sol
 *
 * Return Value:
 *   None
 *
 * Locality:
 *   Client (hasInterface)
 *
 * Example:
 *   [_doc] remoteExec ["TAG_fnc_task02_addAction", 0];
 */

if (!hasInterface) exitWith {};

// Ne PAS utiliser params pour récupérer le document :
// si l'objet n'est pas encore propagé côté client au moment du remoteExec,
// params le capturait comme objNull et la variable locale ne changeait jamais.
// On récupère directement depuis TAG_Task02_Doc (publicVariable du serveur).
private _doc = objNull;
private _waited = 0;

while { isNull _doc && _waited < 30 } do {
    sleep 1;
    _doc = missionNamespace getVariable ["TAG_Task02_Doc", objNull];
    _waited = _waited + 1;
};

if (isNull _doc) exitWith {
    if (DEBUG_MODE) then { diag_log "[TAG] task02_addAction: Document introuvable après 30s — abandon."; };
};

if (DEBUG_MODE) then {
    diag_log format ["[TAG] task02_addAction: Document trouvé en %1s — %2 — pos: %3", _waited, _doc, getPos _doc];
};

_doc addAction [
    "<t color='#00FF88'>Ramasser les documents TOP SECRET</t>",
    {
        params ["_target", "_caller", "_id"];

        // Anti-déclenchement multiple
        if (missionNamespace getVariable ["TAG_Task02_Complete", false]) exitWith {};
        missionNamespace setVariable ["TAG_Task02_Complete", true];
        publicVariable "TAG_Task02_Complete";

        _target removeAction _id;

        // Supprimer le document (toutes machines)
        [_target] remoteExec ["deleteVehicle", 0];

        // Supprimer le marqueur document (toutes machines)
        ["TAG_task02_doc"] remoteExec ["deleteMarker", 0];

        // Passer la tâche à SUCCEEDED sur toutes les machines
        ["task_02_intel", "SUCCEEDED", true] remoteExec ["BIS_fnc_taskSetState", 0];
    },
    [],
    10,      // priorité
    true,    // showWindow
    true,    // hideOnUse
    "",      // shortcut
    "alive player && player distance _target < 5",  // condition : 5m (terrain irrégulier)
    5        // distance maximale d'affichage de l'action (mètres)
];

if (DEBUG_MODE) then {
    diag_log format ["[TAG] task02_addAction: addAction ajouté sur %1", _doc];
};
