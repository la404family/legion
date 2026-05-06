#include "..\macros.hpp"

/*
 * TAG_fnc_task02_addAction
 *
 * Description:
 *   Ajoute l'action "Ramasser les documents TOP SECRET" sur le CORPS de l'officier.
 *   Le corps est une cible large et fiable pour addAction (contrairement au petit
 *   objet document qui est quasiment impossible à cibler au sol).
 *   Le document visuel au sol reste comme indicateur cosmétique.
 *   Appelée via remoteExec depuis le serveur.
 *
 * Arguments:
 *   None — récupère TAG_Task02_Body et TAG_Task02_Doc via publicVariable.
 *
 * Return Value:
 *   None
 *
 * Locality:
 *   Client (hasInterface)
 *
 * Example:
 *   [] remoteExec ["TAG_fnc_task02_addAction", 0];
 */

if (!hasInterface) exitWith {};

// ── Récupérer le corps de l'officier (cible de l'addAction) ──────────────────
// Pattern identique à fn_task03_addAction : boucle active sur la variable namespace.
// TAG_Task02_Body est publié par le serveur AVANT le remoteExec.
private _body   = objNull;
private _waited = 0;

while { isNull _body && _waited < 30 } do {
    sleep 1;
    _body  = missionNamespace getVariable ["TAG_Task02_Body", objNull];
    _waited = _waited + 1;
};

if (isNull _body) exitWith {
    if (DEBUG_MODE) then { diag_log "[TAG] task02_addAction: Corps introuvable après 30s — abandon."; };
};

// Récupérer aussi le document pour le supprimer dans le callback
private _doc = missionNamespace getVariable ["TAG_Task02_Doc", objNull];

if (DEBUG_MODE) then {
    diag_log format ["[TAG] task02_addAction: Corps trouvé en %1s — %2 — pos: %3", _waited, _body, getPos _body];
    diag_log format ["[TAG] task02_addAction: Document — %1", _doc];
};

// ── addAction sur le CORPS de l'officier ────────────────────────────────────
// Le corps est un objet unit (même mort), sa hitbox est large et facilement ciblable.
_body addAction [
    "<t color='#00FF88'>Ramasser les documents TOP SECRET</t>",
    {
        params ["_target", "_caller", "_id"];

        // Anti-déclenchement multiple
        if (missionNamespace getVariable ["TAG_Task02_Complete", false]) exitWith {};
        missionNamespace setVariable ["TAG_Task02_Complete", true];
        publicVariable "TAG_Task02_Complete";

        _target removeAction _id;

        // Supprimer le document visuel au sol (toutes machines)
        private _visualDoc = missionNamespace getVariable ["TAG_Task02_Doc", objNull];
        if (!isNull _visualDoc) then {
            [_visualDoc] remoteExec ["deleteVehicle", 0];
        };

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
    "alive _this && _this distance _target < 6",  // _this = caller, _target = corps
    6        // distance maximale d'affichage de l'action (mètres)
];

if (DEBUG_MODE) then {
    diag_log format ["[TAG] task02_addAction: addAction ajouté sur le corps %1", _body];
};

