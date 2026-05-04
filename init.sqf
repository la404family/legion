// init.sqf
// Entry point — minimal, delegates only

// Call the main init function
[] call TAG_fnc_init;
[] spawn TAG_fnc_skillManager;
