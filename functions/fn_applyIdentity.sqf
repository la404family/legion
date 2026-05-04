#include "..\macros.hpp"

/*
 * TAG_fnc_applyIdentity
 *
 * Description:
 *   Applique l'identité (nom, visage, voix, pitch) à une unité.
 *   Doit être exécuté partout (sur tous les clients) pour être visible/audible par tous.
 *
 * Arguments:
 *   0: <OBJECT> L'unité ciblée
 *   1: <ARRAY> Les données du nom ["Nom complet", "Prénom", "Nom de famille"]
 *   2: <STRING> Le visage
 *   3: <STRING> La voix (speaker)
 *   4: <NUMBER> Le pitch de la voix
 *
 * Locality:
 *   Any (appelé via remoteExec)
 */

params [
    ["_unit", objNull, [objNull]],
    ["_nameData", [], [[]]],
    ["_selectedFace", "", [""]],
    ["_selectedSpeaker", "", [""]],
    ["_pitch", 1, [0]]
];

if (isNull _unit || !alive _unit) exitWith {};

_nameData params ["_fullName", "_firstName", "_lastName"];

_unit setFace _selectedFace;

if !(_nameData isEqualTo []) then {
    _unit setName [_fullName, _firstName, _lastName];
};

_unit setSpeaker _selectedSpeaker;
_unit setPitch _pitch;
// Effacer l'identité par défaut de l'éditeur
_unit setIdentity "";

true
