local Utility = {};

local McpFeature = require("AdituV.DetectTrap.Utility.McpFeature");
local Strings = require("AdituV.DetectTrap.Strings");
local Strings_en = require("AdituV.DetectTrap.Strings_en");
local Config = require("AdituV.DetectTrap.Config");

-- Miscellaneous functions
Utility.checkCodePatchFeature = function(featureId)
  local featureId = featureId:lower();
  
  if not tes3.hasCodePatchFeature(McpFeature[featureId]) then
    Utility.Log.warn("missingMcpFeatureError", featureId);
  end
end

Utility.checkMwseBuildDate = function(datestamp)
  if (mwse.buildDate == nil) or (mwse.buildDate < datestamp) then
    Utility.Log.warn("mwseOutOfDate");
  end
end

Utility.coerceBool = function(x)
  return x and true or false;
end

-- Generates a logistic function (<https://en.wikipedia.org/wiki/Logistic_function>)
-- with the given parameters:
--   minV: the y-coordinate of the lower asymptote
--   maxV: the y-coordinate of the upper asymptote
--   steepness: the steepness of the curve
--   midpoint: the x-coordinate of the curve's midpoint
Utility.mkLogistic = function (minV, maxV, steepness, midpoint)
  return (function (x)
    return minV + (maxV - minV) / (1 + math.exp(-1 * steepness * (x - midpoint)));
  end);
end

-- Logging functions
local logRaw = function(message)
  mwse.log("[Detect Trap] " .. message);
end

local debug = function(message, ...)
  if Config.debugEnabled then
	message = "DEBUG: " .. string.format(message, ...);
	logRaw(message);
  end
end

local info = function(msgId, ...)
  local message = "INFO: " .. string.format(Strings_en[msgId], ...);
  logRaw(message);
end

local warn = function(msgId, ...)
  local message = string.format(Strings[msgId], ...);
  local message_en = "WARN: " .. string.format(Strings_en[msgId], ...);
  
  logRaw(message_en);
  tes3.messageBox(message);  
end

local error = function(msgId, ...)
  local message = string.format(Strings[msgId], ...);
  local message_en = "ERROR: " .. string.format(Strings_en[msgId], ...);
  
  logRaw(message_en);
  tes3.messageBox({
    message = message,
    buttons = { Strings.ok }
  });
end

Utility.Log = {
	debug = debug,
	info = info,
	warn = warn,
	error = error,
};

return Utility;