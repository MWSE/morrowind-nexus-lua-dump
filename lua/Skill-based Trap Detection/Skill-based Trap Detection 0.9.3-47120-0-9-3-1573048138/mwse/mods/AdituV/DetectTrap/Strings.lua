local strings_en = require("AdituV.DetectTrap.Strings_en");

local strings = {};

strings.__index = function(self, key)
  mwse.log(string.format("[Detect Trap] MISSING LOCALISED STRING: %s.  Attempting to default to English", key));
  return strings_en[key];
end
setmetatable(strings, strings);

strings.modName = "Detect Trap";

strings.trapped = "Trapped";
strings.untrapped = "Untrapped";
strings.unknown = "???";

strings.missingMcpFeatureError = "MCP's \"%s\" option is not enabled";
strings.errorOccurred = "An error has occurred"
strings.warning = "Warning"

strings.ok = "OK"

strings.initialized = "Initialized Version %s"
strings.mwseOutOfDate = "Your MWSE is out of date! You will need to update to a more recent version to use this mod."

strings.invalidHandlerRegistering = "Invalid handler when registering event \"%s\""
strings.invalidHandlerUnregistering = "Invalid handler when unregistering event \"%s\""

strings.effects = {
  untrap = "Untrap",
  untrapDescription = "This effect removes a trap from a trapped container or door.",
  untrapSuccess = "Your spell has removed the trap from its target.",
};

strings.spells = {
  untrap = "Aditu's Disarm Trap",
}

strings.mcm = {
  modName = "Skill-based Trap Detection",
  
  debugMode = "Debug Mode",
  debugModeDesc = "Enable extra log messages in MWSE.log",
  
  alwaysSuppressBlacklist = "Suppress \"Trapped\" for blacklist",
  alwaysSuppressBlacklistDesc = "By default, the blacklist is ignored when an object is trapped.  Turn this on to "
    .. "never show trapped status for blacklisted objects, even when they're actually trapped.",
  
  forgetAfter = "Forget traps after: (seconds)",
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
    
  objects = "Objects",
    
  blacklist = "Blacklist",
  blacklistDesc = "By default, all doors and containers (except organic containers) are treated as trappable. "
    .. "If you find something that displays trap status that shouldn't, you can manually add it to this list.",
    
  whitelist = "Whitelist",
  whitelistDesc = "By default, all doors and containers (except organic containers) are treated as trappable. "
    .. "If you find something that doesn't display trap status when it should, you can manually add it to this list."
}

return strings;