- Définition des loadouts de bandits / terroristes (Vanilla / CUP Weapons)
// Format : [Arme Primaire, Chargeur Primaire, Nbre de chargeurs primaires, Arme Secondaire, Chargeur Secondaire, Nbre de chargeurs secondaires, Grenade Fumigène, Nbre Fumi, Soin, Nbre Soin]
// Utilise les conventions SQF de création de loadout (Variables et Array) sans grenades létales ni lanceurs.

private _banditLoadouts = [
    // Profil 1 : Combattant de rue (Assaut court - Vanilla)
    ["arifle_TRG20_F", "30Rnd_556x45_Stanag", 7, "hgun_Rook40_F", "16Rnd_9x21_Mag", 5, "SmokeShell", 2, "FirstAidKit", 2],
    
    // Profil 2 : Pillard SMG (Vanilla)
    ["hgun_PDW2000_F", "30Rnd_9x21_Mag", 7, "hgun_P07_F", "16Rnd_9x21_Mag", 5, "SmokeShell", 2, "FirstAidKit", 2],
    
    // Profil 3 : Éclaireur (Vanilla)
    ["SMG_02_F", "30Rnd_9x21_Mag", 7, "hgun_Rook40_F", "16Rnd_9x21_Mag", 5, "SmokeShell", 2, "FirstAidKit", 2],
    
    // Profil 4 : Braconnier (Carabine et Revolver Lourd - Vanilla)
    ["arifle_Mk20C_F", "30Rnd_556x45_Stanag", 6, "hgun_Pistol_heavy_02_F", "6Rnd_45ACP_Cylinder", 6, "SmokeShell", 2, "FirstAidKit", 2],
    
    // Profil 5 : Mercenaire lourd (Vermin .45 et ACP - Vanilla)
    ["SMG_01_F", "30Rnd_45ACP_Mag_SMG_01", 7, "hgun_ACPC2_F", "9Rnd_45ACP_Mag", 5, "SmokeShell", 2, "FirstAidKit", 2],
    
    // Profil 6 : Survivant / Rebelle (Carabine standard - Vanilla)
    ["arifle_Mk20_F", "30Rnd_556x45_Stanag", 7, "hgun_ACPC2_F", "9Rnd_45ACP_Mag", 5, "SmokeShell", 2, "FirstAidKit", 2],
    
    // Profil 7 : Garde du corps (TRG-21 et 4-five - Vanilla)
    ["arifle_TRG21_F", "30Rnd_556x45_Stanag", 7, "hgun_Pistol_heavy_01_F", "11Rnd_45ACP_Mag", 5, "SmokeShell", 2, "FirstAidKit", 2],
    
    // Profil 8 : Opportuniste ancien modèle (Katiba - Vanilla)
    ["arifle_Katiba_C_F", "30Rnd_65x39_caseless_green", 6, "hgun_Pistol_heavy_02_F", "6Rnd_45ACP_Cylinder", 5, "SmokeShell", 2, "FirstAidKit", 2],
    
    // Profil 9 : Insurgé AK Basique (CUP/Vanilla Apex)
    ["arifle_AKM_F", "30Rnd_762x39_Mag_F", 9, "hgun_Rook40_F", "16Rnd_9x21_Mag", 5, "SmokeShell", 2, "FirstAidKit", 2],
    
    // Profil 10 : Insurgé AK Compact (CUP/Vanilla Apex)
    ["arifle_AKS_F", "30Rnd_545x39_Mag_F", 9, "hgun_Pistol_heavy_02_F", "6Rnd_45ACP_Cylinder", 5, "SmokeShell", 2, "FirstAidKit", 2],

    // Profil 11 : Tireur Emboulé (Fusil Hunter/SKS style - Vanilla)
    ["srifle_DMR_06_camo_F", "20Rnd_762x51_Mag", 8, "hgun_Rook40_F", "16Rnd_9x21_Mag", 5, "SmokeShell", 2, "FirstAidKit", 2],
    
    // Profil 12 : Force de frappe courte portée (Pompe)
    ["sgun_HunterShotgun_01_F", "2Rnd_12Gauge_Pellets", 13, "hgun_P07_F", "16Rnd_9x21_Mag", 5, "SmokeShell", 2, "FirstAidKit", 2],
    
    // Profil 13 : Mitrailleur Léger Rebelle (LMG)
    ["LMG_03_F", "200Rnd_556x45_Box_F", 5, "hgun_Pistol_heavy_01_F", "11Rnd_45ACP_Mag", 5, "SmokeShell", 2, "FirstAidKit", 2],
    
    // Profil 14 : Sniper Local (Fusil de précision léger)
    ["srifle_DMR_01_F", "10Rnd_762x54_Mag", 9, "hgun_P07_F", "16Rnd_9x21_Mag", 5, "SmokeShell", 2, "FirstAidKit", 2]
];

// Définition des sacs à dos disponibles pour les bandits
private _banditBackpacks = [
    "b_Kitbag_cbr",
    "b_Kitbag_rgr",
    "b_Kitbag_sgg",
    "CUP_B_TK_Medic_Desert",
    "B_Messenger_Black_F",
    "B_Messenger_Coyote_F",
    "B_Messenger_Grey_F",
    "B_Messenger_Olive_F",
    "B_TacticalPack_blk",
    "B_TacticalPack_ocamo",
    "CUP_B_RUS_Backpack"
];