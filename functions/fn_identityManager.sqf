#include "..\macros.hpp"

/*
 * TAG_fnc_identityManager
 *
 * Description:
 *   Boucle infinie tournant sur le serveur. Assigne périodiquement une
 *   identité aléatoire aux unités BLUFOR qui n'en ont pas encore.
 *
 * Arguments:
 *   None
 *
 * Locality:
 *   Server
 */

if (!isServer) exitWith {};

private _names_african = [
    ["Moussa Diallo", "Moussa", "Diallo"], ["Mamadou Traoré", "Mamadou", "Traoré"], 
    ["Ibrahim Keita", "Ibrahim", "Keita"], ["Sekou Diop", "Sekou", "Diop"], 
    ["Ousmane Sy", "Ousmane", "Sy"], ["Bakary Sow", "Bakary", "Sow"], 
    ["Ismaël Koné", "Ismaël", "Koné"]
];
private _names_arab = [
    ["Mehdi Benali", "Mehdi", "Benali"], ["Sofiane Haddad", "Sofiane", "Haddad"], 
    ["Karim Mansouri", "Karim", "Mansouri"], ["Mohamed Trabelsi", "Mohamed", "Trabelsi"], 
    ["Walid Belkacem", "Walid", "Belkacem"], ["Hicham Bouzid", "Hicham", "Bouzid"], 
    ["Adel Gharbi", "Adel", "Gharbi"], ["Nassim Saïdi", "Nassim", "Saïdi"], 
    ["Rachid Ziani", "Rachid", "Ziani"], ["Adam Khayat", "Adam", "Khayat"], 
    ["Rayane Meriah", "Rayane", "Meriah"]
];
private _names_asian = [
    ["Minh Tuan Nguyen", "Minh Tuan", "Nguyen"], ["Kevin Chang", "Kevin", "Chang"],
    ["Thomas Vo", "Thomas", "Vo"], ["Nicolas Hoang", "Nicolas", "Hoang"],
    ["Pierre Dang", "Pierre", "Dang"], ["Jun Li", "Jun", "Li"],
    ["Hao Wang", "Hao", "Wang"], ["Kenji Sato", "Kenji", "Sato"],
    ["Jun-ho Kang", "Jun-ho", "Kang"], ["Si-woo Cho", "Si-woo", "Cho"],
    ["Yer Xiong", "Yer", "Xiong"]
];
private _names_pacific = [
    ["Teiva Tehuiotoa", "Teiva", "Tehuiotoa"], ["Manaarii Puarai", "Manaarii", "Puarai"], 
    ["Teva Rohi", "Teva", "Rohi"], ["Manua Tuihani", "Manua", "Tuihani"], 
    ["Keanu Loa", "Keanu", "Loa"], ["Tamatoa Arii", "Tamatoa", "Arii"], 
    ["Ariitea Tehei", "Ariitea", "Tehei"]
];
private _names_standard = [
    ["Julien Martin", "Julien", "Martin"], ["Thomas Bernard", "Thomas", "Bernard"], 
    ["Nicolas Petit", "Nicolas", "Petit"], ["Alexandre Dubois", "Alexandre", "Dubois"], 
    ["Maxime Moreau", "Maxime", "Moreau"], ["Guillaume Laurent", "Guillaume", "Laurent"], 
    ["Lucas Girard", "Lucas", "Girard"], ["Romain Roux", "Romain", "Roux"], 
    ["Clément Fournier", "Clément", "Fournier"], ["Mathieu Bonnet", "Mathieu", "Bonnet"], 
    ["Erwan Le Gall", "Erwan", "Le Gall"], ["Enzo Rossi", "Enzo", "Rossi"], 
    ["Loïc Kerbrat", "Loïc", "Kerbrat"], ["Kevin Martinez", "Kevin", "Martinez"], 
    ["David Rodriguez", "David", "Rodriguez"], ["Sébastien Leroux", "Sébastien", "Leroux"], 
    ["Christophe Chevalier", "Christophe", "Chevalier"], ["Benjamin François", "Benjamin", "François"], 
    ["Florian Robin", "Florian", "Robin"], ["Tiago Da Silva", "Tiago", "Da Silva"], 
    ["Adrien Masson", "Adrien", "Masson"], ["Bastien Sanchez", "Bastien", "Sanchez"], 
    ["Quentin Boyer", "Quentin", "Boyer"], ["Valentin André", "Valentin", "André"], 
    ["Jean-Baptiste Santini", "Jean-Baptiste", "Santini"], ["Rémi Philippe", "Rémi", "Philippe"], 
    ["Jordan Picart", "Jordan", "Picart"], ["Yoann Gautier", "Yoann", "Gautier"], 
    ["Steve Morel", "Steve", "Morel"], ["Dylan Caron", "Dylan", "Caron"], 
    ["Arnaud Perrin", "Arnaud", "Perrin"], ["Thibault Marchand", "Thibault", "Marchand"], 
    ["Dimitri Kowalski", "Dimitri", "Kowalski"], ["Xavier Dupuis", "Xavier", "Dupuis"], 
    ["Cyril Guérin", "Cyril", "Guérin"], ["Laurent Baron", "Laurent", "Baron"], 
    ["Jérôme Huet", "Jérôme", "Huet"], ["Fabien Roy", "Fabien", "Roy"], 
    ["Vincent Colin", "Vincent", "Colin"], ["Olivier Vidal", "Olivier", "Vidal"], 
    ["Pascal Aubert", "Pascal", "Aubert"], ["Éric Rey", "Éric", "Rey"], 
    ["Franck Charpentier", "Franck", "Charpentier"], ["Pierre Tessier", "Pierre", "Tessier"], 
    ["Simon Picard", "Simon", "Picard"], ["Louis Chauvin", "Louis", "Chauvin"], 
    ["Gabin Laporte", "Gabin", "Laporte"], ["Paul Renard", "Paul", "Renard"], 
    ["Victor Langlois", "Victor", "Langlois"], ["Arthur Prévost", "Arthur", "Prévost"], 
    ["Léo Martinet", "Léo", "Martinet"], ["Raphaël Joly", "Raphaël", "Joly"], 
    ["Gabriel Brun", "Gabriel", "Brun"], ["Yassine Faure", "Yassine", "Faure"], 
    ["Cédric Payet", "Cédric", "Payet"], ["Grégory Hoarau", "Grégory", "Hoarau"], 
    ["Stanislav Novak", "Stanislav", "Novak"], ["Alexis Ivanoff", "Alexis", "Ivanoff"], 
    ["Samuel Cohen", "Samuel", "Cohen"], ["Jonathan Lévy", "Jonathan", "Lévy"], 
    ["Anthony Garcia", "Anthony", "Garcia"], ["Damien Dos Santos", "Damien", "Dos Santos"], 
    ["Frédéric Muller", "Frédéric", "Muller"], ["Hans Weber", "Hans", "Weber"], 
    ["Bixente Etcheverry", "Bixente", "Etcheverry"], ["Ange Paoli", "Ange", "Paoli"], 
    ["Étienne Lemaire", "Étienne", "Lemaire"], ["Bruno Vincent", "Bruno", "Vincent"], 
    ["Hugues Lefebvre", "Hugues", "Lefebvre"], ["Mikaël Gauthier", "Mikaël", "Gauthier"], 
    ["Luis Fernandez", "Luis", "Fernandez"], ["Sylvain Blanchard", "Sylvain", "Blanchard"], 
    ["Axel Mercier", "Axel", "Mercier"]
];

private _fnc_processUnit = {
    params ["_unit", "_names_african", "_names_arab", "_names_asian", "_names_pacific", "_names_standard"];
    
    private _all_names_typed = [];
    { _all_names_typed pushBack [_x, "Black"]; } forEach _names_african;
    { _all_names_typed pushBack [_x, "Arab"]; } forEach _names_arab;
    { _all_names_typed pushBack [_x, "Asian"]; } forEach _names_asian;
    { _all_names_typed pushBack [_x, "Pacific"]; } forEach _names_pacific;
    { _all_names_typed pushBack [_x, "White"]; } forEach _names_standard;  
    
    if (isNil "TAG_UsedNames") then { TAG_UsedNames = []; };
    
    private _available_names = _all_names_typed select { !((_x select 0 select 0) in TAG_UsedNames) };
    if (count _available_names == 0) then {
        if (DEBUG_MODE) then {
            diag_log "[TAG] WARNING: Tous les noms ont été utilisés ! Reset du cache de noms uniques.";
        };
        TAG_UsedNames = [];
        _available_names = _all_names_typed;
    };
    
    private _selected = selectRandom _available_names;
    private _nameData = _selected select 0;  
    TAG_UsedNames pushBack (_nameData select 0);
    
    private _faceType = _selected select 1;  
    private _faces = [];
    switch (_faceType) do {
        case "Black": { 
            _faces = ["AfricanHead_01","AfricanHead_02","AfricanHead_03"]; 
        };
        case "Arab": { 
            _faces = ["PersianHead_A3_01","PersianHead_A3_02","PersianHead_A3_03","GreekHead_A3_01","GreekHead_A3_02","GreekHead_A3_03","GreekHead_A3_04","GreekHead_A3_05","GreekHead_A3_06"]; 
        };
        case "Asian": {
            _faces = ["AsianHead_A3_01","AsianHead_A3_02","AsianHead_A3_03"];
        };
        case "Pacific": {
            _faces = ["TanoanHead_A3_01","TanoanHead_A3_02","TanoanHead_A3_03","TanoanHead_A3_04","TanoanHead_A3_05"];
        };
        default {  
            _faces = ["WhiteHead_01","WhiteHead_02","WhiteHead_03","WhiteHead_04","WhiteHead_05","WhiteHead_06","WhiteHead_07","WhiteHead_08","WhiteHead_09","WhiteHead_10","WhiteHead_11","WhiteHead_12","WhiteHead_13","WhiteHead_14","WhiteHead_15","WhiteHead_16","WhiteHead_17","WhiteHead_18","WhiteHead_19","WhiteHead_20","WhiteHead_21"];
        };
    };
    
    private _selectedFace = selectRandom _faces;
    private _selectedSpeaker = "";
    switch (_faceType) do {
        case "White": { 
            _selectedSpeaker = "Male01FRE"; 
        };
        case "Black": { 
            _selectedSpeaker = "Male02FRE"; 
        };
        default { 
            _selectedSpeaker = "Male03FRE"; 
        };
    };
    
    private _pitch = 0.90 + (random 0.20);
    
    // Diffusion à tous les clients pour appliquer l'identité
    [_unit, _nameData, _selectedFace, _selectedSpeaker, _pitch] remoteExec ["TAG_fnc_applyIdentity", 0, _unit];
    
    // Marquer l'unité comme traitée
    _unit setVariable ["TAG_IdentitySet", true, true];
    _unit setVariable ["TAG_Identity", [_nameData select 0, _faceType, _selectedFace], true];
};

// Boucle principale
while {true} do {
    {
        private _unit = _x;
        // Application sur toutes les unités de l'ouest (joueurs inclus)
        if (
            side _unit == west && 
            alive _unit && 
            !(_unit getVariable ["TAG_IdentitySet", false])
        ) then {
            [_unit, _names_african, _names_arab, _names_asian, _names_pacific, _names_standard] call _fnc_processUnit;
        };
    } forEach allUnits;
    
    sleep 45;
};
