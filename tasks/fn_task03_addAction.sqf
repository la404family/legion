#include "..\macros.hpp"

/*
 * TAG_fnc_task03_addAction
 *
 * Description:
 *   Ajoute la hold action "Libérer l'otage" sur l'otage côté client.
 *   Appelée via remoteExec depuis le serveur après la création de l'otage.
 *   Récupère l'otage depuis la publicVariable TAG_Task03_Hostage.
 *   Le callback signale la libération au serveur via publicVariable.
 *
 * Arguments:
 *   None
 *
 * Return Value:
 *   None
 *
 * Locality:
 *   Client (hasInterface)
 *
 * Example:
 *   [] remoteExec ["TAG_fnc_task03_addAction", 0];
 */

if (!hasInterface) exitWith {};

// Attendre que TAG_Task03_Hostage soit disponible (publicVariable du serveur)
// Pattern identique à fn_task02_addAction : boucle active sur la variable namespace
private _hostage = objNull;
private _waited  = 0;

while { isNull _hostage && _waited < 30 } do {
    sleep 1;
    _hostage = missionNamespace getVariable ["TAG_Task03_Hostage", objNull];
    _waited  = _waited + 1;
};

if (isNull _hostage) exitWith {
    if (DEBUG_MODE) then {
        diag_log "[TAG] task03_addAction: Otage introuvable après 30s — abandon.";
    };
};

if (DEBUG_MODE) then {
    diag_log format ["[TAG] task03_addAction: Otage trouvé en %1s — %2 — pos: %3", _waited, _hostage, getPos _hostage];
};

// ── Hold action "Libérer l'otage" ─────────────────────────────────────────────
[
    _hostage,                                               // Objet cible
    localize "STR_TAG_Task_03_FreeAction",                 // Titre affiché
    "\a3\ui_f\data\IGUI\Cfg\holdactions\holdAction_unbind_ca.paa",  // Icône fermée
    "\a3\ui_f\data\IGUI\Cfg\holdactions\holdAction_unbind_ca.paa",  // Icône ouverte
    // conditionShow : cacher l'action si l'otage est déjà libéré
    "alive _target
        && _target distance _this < 4
        && (_target getVariable ['TAG_Task03_IsCaptive', false])
        && !(missionNamespace getVariable ['TAG_Task03_Freed', false])",
    // conditionProgress : interrompre si le joueur s'éloigne
    "_target distance _this < 4",
    {},                                                     // codeStart  (vide)
    {},                                                     // codeProgress (vide)
    // codeComplete : signaler la libération au serveur
    {
        params ["_target", "_caller", "_actionId", "_arguments"];

        // Anti-déclenchement multiple
        if (missionNamespace getVariable ["TAG_Task03_Freed", false]) exitWith {};

        // Signaler au serveur et à tous les clients
        TAG_Task03_Freed = true;
        publicVariable "TAG_Task03_Freed";

        // Masquer l'action sur l'otage (conditionShow s'en chargera sur les autres clients)
        // La variable TAG_Task03_IsCaptive sera mise à false par le serveur
        _target setVariable ["TAG_Task03_IsCaptive", false, true];

        if (DEBUG_MODE) then {
            diag_log format ["[TAG] task03_addAction: Otage libéré par %1.", name _caller];
        };
    },
    {},                                                     // codeInterrupted (vide)
    [],                                                     // Arguments
    6,                                                      // Durée du maintien (secondes)
    true,                                                   // Supprimer après usage
    false,                                                  // Masquer si inconscient
    false                                                   // Pas d'auto-interaction
] call BIS_fnc_holdActionAdd;

if (DEBUG_MODE) then {
    diag_log format ["[TAG] task03_addAction: Hold action ajoutée sur %1.", _hostage];
};
