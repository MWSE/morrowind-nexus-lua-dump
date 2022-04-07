local Config = require("AdituV.DetectTrap.Config");
local LockData = require("AdituV.DetectTrap.LockData");
local MCPFeature = require("AdituV.DetectTrap.Utility.McpFeature");
local MobilePlayer = require("AdituV.DetectTrap.MobilePlayer");
local Strings = require("AdituV.DetectTrap.Strings");
local Utility = require("AdituV.DetectTrap.Utility");

local DetectTrap = {};

local guiIds = {};

local registerGuiIds = function ()
  guiIds.parent = tes3ui.registerID("DT_Tooltip_Parent");
  guiIds.child = tes3ui.registerID("DT_Tooltip_Child");
  guiIds.lockStatus = tes3ui.registerID("DT_Tooltip_Lock")
  guiIds.trapStatus = tes3ui.registerID("DT_Tooltip_Trap");
end

local invalidationTime = 0;

local initMod = function ()
  -- Check that build is after trapDetect event changed to trigger even when no
  -- trap is present
  Utility.checkMwseBuildDate(20190828); 
  Utility.checkCodePatchFeature("Hidden Traps");
  Utility.checkCodePatchFeature("Hidden Locks");
  
  math.randomseed( os.time() );
  
  registerGuiIds();
  
  Utility.Log.info("initialized", Config.version);
end


local addExtraInfo = function(tooltip, lockData, reference)
  local parent = tooltip:createBlock({id = guiIds.parent});
  parent.autoHeight = true;
  parent.autoWidth = true;
  local child = tooltip:createBlock({id = guiIds.child})
  child.autoHeight = true;
  child.autoWidth = true;
  local trapMessage;
  local lockMessage;
  
  if lockData:getTrapDetected() then	-- if trap wasn't detected don't show trap message
	  if lockData.trapped then
		mwse.log("TRAPPED STATUS: %s", lockData.trapped)
		mwse.log("TRAP: %s", lockData.trap)
		trapMessage = Strings.trapped
		if Config.enchantEffect then
			tes3.worldController:applyEnchantEffect(reference.sceneNode, lockData.trap)
			reference.sceneNode:updateNodeEffects()
		end
		if lockData:getTrapDetected() == 2 then
			local trapEffect = tostring(lockData.trap.effects[1])
			trapEffect = string.gsub(trapEffect, "[0-9].*", "")
			trapMessage = trapMessage..": "..trapEffect
		end
	  else
		trapMessage = Strings.untrapped;
	  end
  end
  
  if lockData.locked then
	if lockData.lockLevel == 0 then
		lockMessage	= Strings.keylocked
	elseif lockData:getMinLock() == lockData:getMaxLock() then
		lockMessage = Strings.locked..tostring(lockData:getMinLock())
	elseif lockData:getMinLock() < lockData:getMaxLock() then 
		lockMessage = Strings.locked..tostring(lockData:getMinLock()).." - "..tostring(lockData:getMaxLock())
	end
  elseif lockData:getMinLock() <= lockData:getMaxLock() then
	lockMessage = Strings.unlocked
	lockData:setMaxLock(-1)
	lockData:setMinLock(-1)
  end

  if lockMessage then
	parent:createLabel({id=guiIds.lockStatus, text=lockMessage});
	if trapMessage then
		child:createLabel({id=guiIds.trapStatus, text=trapMessage});
	end
  elseif trapMessage then
	parent:createLabel({id=guiIds.trapStatus, text=trapMessage});
  end
end

local onTooltip = function(e)
  if not e.reference then return end;
  
  local ld = LockData.getForReference(e.reference);
  
  if not ld then return end;
  
  Utility.Log.debug("Checking detection");
  local detected = ld:getTrapDetected();
  local lock = ( ld.locked and ld:getMaxLock() < ld.lockLevel )
  local detectedText;
  
  
  if detected == nil then
    detectedText = "nil";
  elseif detected then
    detectedText = "true";
  else
    detectedText = "false";
  end
  
  
  
  Utility.Log.debug("Detection status: %s", detectedText);
  Utility.Log.debug("Lock status: %s", tostring(lock));
  if lock then
	Utility.Log.debug("Lock Level = %d", ld.lockLevel)
  end

  if detected ~= nil and ld:getInExterior() then
    if (mwse.simulateTimers.clock > ld:getDetectedAt() + Config.forgetDuration)
      or (ld:getDetectedAt() < invalidationTime) then
      -- The tooltip should have been forgotten already but hasn't been for whatever reason.
      -- Force reattempting detection.
      detected = nil
      Utility.Log.debug("Rerolling detection: data expired.");
    end
  end
  
  if detected == false and MobilePlayer.getEffectiveSecurityLevel() > ld:getPlayerSkill() then
    -- Player's skill has increased; try again at spotting the trap
    detected = nil;
    
    Utility.Log.debug("Rerolling detection: skill increased.");
  end
  
  if detected == nil then
	if ld.trapped then
		Utility.Log.debug("Attempting trap detection.");
		ld:attemptDetectTrap();
	end
  end
  
  if lock then
	Utility.Log.debug("Attempting lock detection.");
	ld:attemptDetectLock()
  end
  
  addExtraInfo(e.tooltip, ld ,e.reference);
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

local onPickUsed = function(e)
	local ld = LockData.getForReference(e.reference);
	if ld and ld.locked and ld:getMinLock() ~= ld:getMaxLock() then
		ld:attemptDetectLock()
		if ld:getMinLock() > ld:getMaxLock() then
			Utility.Log.debug(
				"Min > Max"
			)
			ld:setMinLock(1)
			ld:setMaxLock(100)
		end
	end
	
	e.clearTarget = true;
end

local onProbeUsed = function(e)
  -- Using a probe will always tell you whether a trap is present
  
  local ld = LockData.getForReference(e.reference);
  if ld and ld.trapped and ld:getTrapDetected() ~= 2 then
    ld:attemptDetectTrap()
	if not ld:getTrapDetected() then
		ld:setTrapDetected(true);
	end
  end
  
  -- Force refresh tooltip
  e.clearTarget = true;
end

local onActivate = function(e)
  -- Activating an unlocked object will always tell you whether a trap is present
  -- (because either it was trapped and has triggered, so isn't any more, or it
  -- wasn't trapped in the first place)
  
  local ld = LockData.getForReference(e.target);
  
  if ld and not ld.locked and ld.trapped then
	if not ld:getTrapDetected() then
		ld:setTrapDetected(true);
	end
  end
  if ld and ld.locked and ld:getMinLock() > ld:getMaxLock() then
	Utility.Log.debug(
		"Min > Max"
	)
	ld:setMinLock(1)
	ld:setMaxLock(100)
  end
  
end

local onSpellResist = function(e)
	local ld = LockData.getForReference(e.target);
	if ld and ld.locked and ld.lockLevel == 0 then
		e.resistedPercent = 100
	end
end

function DetectTrap:new(o)
  o = o or {};
  setmetatable(o, self);
  self.__index = self;
  return o;
end

function DetectTrap:init()
  event.register("modConfigReady", function()
    require("AdituV.DetectTrap.MCM");
  end);
  if Config.modEnabled then
	event.register("initialized", initMod);
	-- High priority, but still below Graphic Herbalism
	event.register("uiObjectTooltip", onTooltip, { priority = 150 });
	event.register("cellChanged", onCellChange);
	event.register("trapDisarm", onProbeUsed);
	event.register("lockPick", onPickUsed);
	event.register("activate", onActivate);
	event.register("spellResist", onSpellResist);
  else
	event.unregister("uiObjectTooltip", onTooltip);
	event.unregister("cellChanged", onCellChange);
	event.unregister("trapDisarm", onProbeUsed);
	event.unregister("lockPick", onPickUsed);
	event.unregister("activate", onActivate);
  end
end

return DetectTrap;