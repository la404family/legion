#include "..\macros.hpp"

/*
 * TAG_fnc_callToPrayer
 *
 * Description:
 *   Gère l'appel à la prière depuis les minarets positionnés dans l'éditeur.
 *   Chaque minaret (ezan_0 à ezan_4) diffuse le son "ezan" en 3D aux joueurs
 *   situés dans le rayon de portée. Le cycle se répète toutes les 30 minutes
 *   avec un décalage aléatoire initial (5 à 15 minutes).
 *
 * Locality:
 *   Serveur
 *
 * Variables éditeur utilisées:
 *   ezan_0, ezan_1, ezan_2, ezan_3, ezan_4 — objets Loudspeaker
 */

if (!isServer) exitWith {};

private _soundRange   = 2500;
private _minaretsVars = ["ezan_0", "ezan_1", "ezan_2", "ezan_3", "ezan_4", "ezan_5"];

// Délai aléatoire initial avant le premier appel (5 à 15 minutes)
sleep (3 + (random 6));

while {true} do {
    {
        private _varName    = _x;
        private _minaretObj = missionNamespace getVariable [_varName, objNull];

        if (!isNull _minaretObj) then {
            private _nearbyPlayers = allPlayers select { (_x distance _minaretObj) < _soundRange };
            if (count _nearbyPlayers > 0) then {
                [_minaretObj, ["ezan", _soundRange, 1]] remoteExec ["say3D", _nearbyPlayers];
            };
        };

        sleep 0.05;
    } forEach _minaretsVars;

    // Prochain appel dans 30 minutes
    sleep 1800;
};
