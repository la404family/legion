#include "..\macros.hpp"

/*
 * TAG_fnc_skillManager
 *
 * Description:
 *   Boucle infinie ajustant les capacités (skills) des I.A en fonction de leur faction.
 *   Tourne sur toutes les machines (Serveur, Clients, Headless Clients) mais
 *   ne modifie que les I.A locales à cette machine.
 *
 * Arguments:
 *   None
 *
 * Locality:
 *   Any (exécuté partout)
 */

if (DEBUG_MODE) then {
    diag_log "[TAG] Démarrage du gestionnaire de compétences (skills) des I.A...";
};

while {true} do {
    {
        // On ne cible que les unités en vie, gérées par cette machine (local), et qui sont des IA
        if (alive _x && {local _x} && {!isPlayer _x}) then {
            
            // On utilise une variable pour éviter de re-calculer les statistiques aléatoires
            // toutes les 60 secondes sur les mêmes IA, ce qui changerait leur précision en permanence.
            if !(_x getVariable ["TAG_skillsApplied", false]) then {
                
                private _side = side _x;
                
                // Ennemis (OPFOR et Indépendants)
                if (_side == east || _side == independent) then {
                    _x setSkill ["aimingAccuracy", 0.10 + random 0.15];    
                    _x setSkill ["aimingShake",   0.10 + random 0.20];    
                    _x setSkill ["aimingSpeed",   0.10 + random 0.30];    
                    _x setSkill ["spotDistance",  0.10 + random 0.50];    
                    _x setSkill ["spotTime",      0.10 + random 0.40];    
                    _x setSkill ["courage", 1];
                    _x setSkill ["reloadSpeed", 0.6];
                    _x setSkill ["commanding", 0.4];
                    _x setSkill ["general", 0.5];
                    _x allowFleeing 0;
                    
                    _x setVariable ["TAG_skillsApplied", true];
                };
                
                // Alliés (BLUFOR / WEST)
                if (_side == west) then {
                    // Exception pour le Sniper (player_1)
                    if (!isNil "player_1" && {_x == player_1}) then {
                        _x setSkill ["aimingAccuracy", 0.80 + random 0.15]; // Précision mortelle
                        _x setSkill ["aimingShake",   0.80 + random 0.15];  // Très grande stabilité
                        _x setSkill ["aimingSpeed",   0.70 + random 0.20];    
                        _x setSkill ["spotDistance",  0.90 + random 0.10];  // Vision lointaine
                        _x setSkill ["spotTime",      0.90 + random 0.10];  // Repérage rapide
                        _x setSkill ["courage", 1];
                        _x setSkill ["reloadSpeed", 0.75];
                        _x setSkill ["commanding", 0.6];
                        _x setSkill ["general", 0.85];
                    } else {
                        // Troupes standards
                        _x setSkill ["aimingAccuracy", 0.35 + random 0.15];    
                        _x setSkill ["aimingShake",   0.40 + random 0.20];    
                        _x setSkill ["aimingSpeed",   0.40 + random 0.20];    
                        _x setSkill ["spotDistance",  0.60 + random 0.20];    
                        _x setSkill ["spotTime",      0.65 + random 0.10];    
                        _x setSkill ["courage", 1];
                        _x setSkill ["reloadSpeed", 0.75];
                        _x setSkill ["commanding", 0.6];
                        _x setSkill ["general", 0.65];
                    };
                    _x allowFleeing 0;
                    
                    _x setVariable ["TAG_skillsApplied", true];
                };
            };
        };
    } forEach allUnits;
    
    sleep 60;
};
