#include "..\macros.hpp"

/*
 * TAG_fnc_transferLocality
 *
 * Description:
 *   Transfère la localité d'un objet vers un client spécifique.
 *   Nécessaire car setOwner ne peut être exécuté que par le serveur.
 *
 * Arguments:
 *   0: <OBJECT> L'objet à transférer
 *   1: <NUMBER> L'ID réseau (owner ID) du client cible
 *
 * Return Value:
 *   <BOOL> True si le transfert est réussi
 *
 * Locality:
 *   Server
 */

params [
    ["_object", objNull, [objNull]],
    ["_ownerID", 0, [0]]
];

if (!isServer) exitWith { false };
if (isNull _object || _ownerID == 0) exitWith { false };

_object setOwner _ownerID;
true
