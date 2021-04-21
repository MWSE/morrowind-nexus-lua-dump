local strings = {};

strings.__index = function(self, key)
  mwse.log(string.format("[Detect Trap] MISSING STRING: " .. key));
  return "MISSING STRING";
end
setmetatable(strings,strings);

strings.modName = "Locks and Traps Detection";

strings.trapped = "Trapped";
strings.untrapped = "Untrapped";

strings.locked = "Lock Level: "
strings.unlocked = "Lock Level: Unlocked"
strings.keylocked = "Lock Level: Key Only"

strings.missingMcpFeatureError = "MCP Feature \"%s\" is missing";
strings.errorOccurred = "An error has occurred"
strings.warning = "Warning"

strings.ok = "OK"

strings.initialized = "Initialized Version %s"
strings.mwseOutOfDate = "Your MWSE is out of date! You will need to update to a more recent version to use this mod."

strings.invalidHandlerRegistering = "Invalid handler when registering event \"%s\""
strings.invalidHandlerUnregistering = "Invalid handler when unregistering event \"%s\""


strings.mcm = {
  modName = "Locks and Traps Detection",
  
  modEnabled = "Mod status",
  modEnabledDesc = "By default the mod is on. Restart the game after changing mod status.",
  
  debugMode = "Debug mode",
  debugModeDesc = "By default debug mode is off. Enable extra log messages in MWSE.log",
    
  enchantEffect = "Show enchantment effect",
  enchantEffectDesc = "When this option is on, trapped objects will start glowing with the corresponding enchantment effect on their detection. This is done for better compatibility with Visually Trapped Objects by Anumaril and is recommended to be used with it.",
  
  maxLockLevel = "Maximum lock level",
  maxLockLevelDesc = "Affects minimal accurancy of lock detection. In vanilla game there were no lock with lock level beyond 100. Increase the value of this parameter if you play with mods adding more difficult locks.",
  
  forgetAfter = "Forget locks after: (seconds)",
  forgetAfterDesc = "When remaining purely in exterior cells, forget which containers are trapped after this many"
    .. "real-world seconds spent in-game (not including time spent in menus)",
  
  settings  = "Settings",
  
  difficulty = "Difficulty",
  
  midpoint = "Midpoint",
  midpointDesc = "The effective skill level required to have a 50% chance of detecting a trap.\n"
    .. "Your effective skill level is: Security + (Intelligence / 5) + (Luck / 10).\n"
    .. "Default: 70",
    
  steepness = "Steepness",
  steepnessDesc = "Steepness affects the shape of the probability curve.\n\n"
    .. "High steepness makes the probability increase faster around the midpoint, and increase slower "
    .. "further from the midpoint, and vice versa.  Default: 5.",
    
}

return strings;