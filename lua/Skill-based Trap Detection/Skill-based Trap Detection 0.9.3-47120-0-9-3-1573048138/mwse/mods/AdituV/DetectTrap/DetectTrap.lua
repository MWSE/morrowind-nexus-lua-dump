local Config = require("AdituV.DetectTrap.Config");
local Effects = require("AdituV.DetectTrap.Magic.Effects");
local Spells = require("AdituV.DetectTrap.Magic.Spells");
local LockData = require("AdituV.DetectTrap.LockData");
local MCPFeature = require("AdituV.DetectTrap.Utility.McpFeature");
local MobilePlayer = require("AdituV.DetectTrap.MobilePlayer");
local Strings = require("AdituV.DetectTrap.Strings");
local Utility = require("AdituV.DetectTrap.Utility");

local DetectTrap = {};

local guiIds = {};

local registerGuiIds = function ()
  guiIds.parent = tes3ui.registerID("DT_Tooltip_Parent");
  guiIds.trapStatus = tes3ui.registerID("DT_Tooltip_Trap");
end

local invalidationTime = 0;

local initMod = function ()
  -- Check that build is after trapDetect event changed to trigger even when no
  -- trap is present
  Utility.checkMwseBuildDate(20190828); 
  Utility.checkCodePatchFeature("Hidden Traps");
  
  math.randomseed( os.time() );
  
  registerGuiIds();
  
  Utility.Log.info("initialized", Config.version);
end

local shouldSuppressTrapInfo = function (ref)
  local suppress = false;
  
  if ref.object.organic then suppress = true end;
  local id = ref.baseObject.id:lower();
  
  if Config.blacklist[id] then suppress = true end;
  if Config.whitelist[id] then suppress = false end;
  
  if suppress then
    Utility.Log.debug("Suppressing trap info for: %s", id);
  end
  
  
  return suppress;
end

local addExtraInfo = function(tooltip, lockData)
  local parent = tooltip:createBlock({id = guiIds.parent});
  parent.autoHeight = true;
  parent.autoWidth = true;
  
  local trapMessage;
  
  if not lockData:getTrapDetected() then
    trapMessage = Strings.unknown;
  elseif lockData.trapped then
    trapMessage = Strings.trapped;
  else
    trapMessage = Strings.untrapped;
  end
  
  parent:createLabel({id=guiIds.trapStatus, text=trapMessage});
end

local onTooltip = function(e)
  if not e.reference then return end;
  
  local ld = LockData.getForReference(e.reference);
  
  if not ld then return end;
  
  if shouldSuppressTrapInfo(e.reference) and (not ld.trapped or Config.alwaysSuppressBlacklist) then
    -- When something should generally not display trapped status, and is
    -- not trapped, then leave tooltip as-is.
    -- If something that should be suppressed is trapped, then ignore the
    -- suppression unless Configured otherwise (alwaysSuppressBlacklist)
    return;
  end
  
  Utility.Log.debug("Checking detection");
  local detected = ld:getTrapDetected();
  local detectedText;
  
  if detected == nil then
    detectedText = "nil";
  elseif detected then
    detectedText = "true";
  else
    detectedText = "false";
  end
  
  Utility.Log.debug("Detection status: %s", detectedText);
  
  if detected ~= nil and ld:getInExterior() then
    if (mwse.simulateTimers.clock > ld:getDetectedAt() + Config.forgetDuration)
      or (ld:getDetectedAt() < invalidationTime) then
      -- The tooltip should have been forgotten already but hasn't been for whatever reason.
      -- Force reattempting detection.
      detected = nil
      
      Utility.Log.debug("Rerolling trap detection: data expired.");
    end
  end
  
  if detected == false and MobilePlayer.getEffectiveSecurityLevel() > ld:getPlayerSkill() then
    -- Player's skill has increased; try again at spotting the trap
    detected = nil;
    
    Utility.Log.debug("Rerolling trap detection: skill increased.");
  end
  
  if detected == nil then
    Utility.Log.debug("Attempting trap detection.");
    ld:attemptDetectTrap();
  end
  
  addExtraInfo(e.tooltip, ld);
end

local onCellChange = function(e)
  -- If we are first loading the game, previousCell will be nil, and this event
  -- should be skipped
  if not e.previousCell then return end;
  
  -- On transitioning from interior -> exterior or vice versa, clear all known
  -- cached lock data
  if (e.previousCell.isInterior and not e.cell.isInterior)
    or (not e.previousCell.isInterior and e.cell.isInterior) then
    LockData.forgetAllKnownData();
  end
end

local onProbeUsed = function(e)
  -- Using a probe will always tell you whether a trap is present
  
  local ld = LockData.getForReference(e.reference);
  if ld then
    ld:setTrapDetected(true);
  end
  
  -- Force refresh tooltip
  e.clearTarget = true;
end

local onActivate = function(e)
  -- Activating an unlocked object will always tell you whether a trap is present
  -- (because either it was trapped and has triggered, so isn't any more, or it
  -- wasn't trapped in the first place)
  
  local ld = LockData.getForReference(e.target);
  
  if ld and not ld.locked then
    ld:setTrapDetected(true);
  end
end

function DetectTrap:new(o)
  o = o or {};
  setmetatable(o, self);
  self.__index = self;
  return o;
end

function DetectTrap:init()
  event.register("initialized", initMod);
  event.register("modConfigReady", function()
    require("AdituV.DetectTrap.MCM");
  end);
  
  -- High priority, but still below Graphic Herbalism
  event.register("uiObjectTooltip", onTooltip, { priority = 150 });
  event.register("cellChanged", onCellChange);
  event.register("trapDisarm", onProbeUsed);
  event.register("activate", onActivate);
  event.register("magicEffectsResolved", function ()
    Effects.registerEffects();
  end);
  event.register("loaded", function()
    Spells.registerSpells();
  end);
end

return DetectTrap;