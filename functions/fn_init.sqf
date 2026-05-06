/*
 * TAG_fnc_init
 *
 * Description:
 *   Global init logic. Safe to run on both client and server.
 *   Delegates to specific init scripts depending on locality.
 *
 * Arguments:
 *   None
 *
 * Return Value:
 *   None
 */

// Lance la cinématique d'introduction pour le serveur et les clients
 [] spawn TAG_fnc_introCinematic;

if (isServer) then {
    [] call TAG_fnc_initServer;
};

if (hasInterface) then {
    [] spawn TAG_fnc_initPlayer; // Use spawn if there are sleeps, otherwise call
};
