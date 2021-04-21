local Config = require("AdituV.DetectTrap.Config");
local MobilePlayer = require("AdituV.DetectTrap.MobilePlayer");
local Utility = require("AdituV.DetectTrap.Utility");

local LockData = {
  -- The parent reference this LockData belongs to
  parent = nil,
  
  -- Basic lock info, from the LockAttachment
  key = nil,
  locked = false,
  lockLevel = 0,
  trapped = false,
  trap = nil,
  
  -- Player's knowledge state is implemented in get/set methods, interfacing
  -- directly with the extra data in the parent reference.
  -- trapDetected = nil,
  -- playerSkill = 0,
  -- inExterior,
  -- detectedAt = 0
};

local knownLocks = {};

-- Returns true if `ref` is of an object type that can have lock data
local supportsLockData = function (ref)
  return (ref.object.objectType == tes3.objectType.container)
    or (ref.object.objectType == tes3.objectType.door);
end

-- Returns the extra LockData-related information stored in the reference's
-- data field, creating it if it does not yet exist.
local getExtraData = function(self)
  if not self.parent.data.DT then
    self.parent.data.DT = {};
  end
  
  return self.parent.data.DT;
end

-- Removes the extra LockData-related information from the reference's data field,
-- so it will no longer persist in the save game file.
local clearExtraData = function(self)
  local extraData = self.parent.data.DT;
  if extraData then
    for k,_ in pairs(extraData) do
      extraData[k] = nil;
    end
  end
  self.parent.data.DT = nil;
  
  -- Set to nil instead of {} so that the cache can be garbage collected,
  -- and not persist permanently in the player's save file
end

function LockData:new(o)
  o = o or {};
  setmetatable(o, self);
  self.__index = self;
  return o;
end

-- Attempts to detect whether the lock is trapped based on the player's effective
-- security skill, and updates the LockData state with the results.
function LockData:attemptDetectTrap()
  local detectChance = MobilePlayer.getTrapDetectProbability();
  local rand = math.random();
  
  self:setTrapDetected(rand <= detectChance);
  
  Utility.Log.debug(
    "Detection Roll: %d / %d.  Fails at: %d.",
    math.floor(rand * 1000),
    1000,
    math.floor(detectChance * 1000)
  );
  
end

-- Extra "fields" (get/set pairs)

-- TrapDetected
-- Tristate bool (true/false/nil)
--   true: The trap detection has succeeded.  Display trap state.
--  false: The trap detection has failed.  Display "???"
--    nil: The trap detection has not yet happened.  Attempt detection.
function LockData:getTrapDetected()
  return getExtraData(self).trapDetected;
end

function LockData:setTrapDetected(value)
  if value == nil then
    clearExtraData(self);
  else
    local extraData = getExtraData(self);
    local lockTimer
    
    Utility.Log.debug("setTrapDetected called");
    
    extraData.trapDetected = value;
    self:setPlayerSkill(MobilePlayer.getEffectiveSecurityLevel());
    
    -- If a detection (or attempt) has happened, and the reference is located in
    -- an exterior cell, keep track of the time the attempt happened at so
    -- the player can forget it after a set time
    if self:getInExterior() then
      self:setDetectedAt(mwse.simulateTimers.clock);
      
      -- Also set a timer to delete the data, to try to not bloat the saved game
      -- too much
      lockTimer = timer.start({
        duration = Config.forgetDuration,
        callback = function()
          clearExtraData(self)
        end
      });
    end
    
    knownLocks[#knownLocks + 1] = {
      lock = self,
      timer = lockTimer
    };
  end
end

-- playerSkill
-- The effective Security level at which the player last attempted to
-- detect the trap.
function LockData:getPlayerSkill()
  return getExtraData(self).playerSkill or 0;
end

function LockData:setPlayerSkill(value)
  local extraData = getExtraData(self);
  extraData.playerSkill = value;
end

-- InExterior
-- Whether the locked reference is located in an external cell
-- Read-only
function LockData:getInExterior()
  return self.parent.cell.isInterior and not self.parent.cell.behavesAsExterior;
end

-- DetectedAt
-- The timestamp (in simulation time) at which the lock was last detected
function LockData:getDetectedAt()
  return getExtraData(self).detectedAt or 0;
end

function LockData:setDetectedAt(value)
  local extraData = getExtraData(self);
  extraData.detectedAt = value
end

function LockData.forgetData(ref)
  ref.data.DT = {};
end

function LockData.forgetAllKnownData()
  Utility.Log.debug("Forgetting all known locks' data: %d", #knownLocks);
  for k,v in pairs(knownLocks) do
    clearExtraData(v.lock);
    v.lock = nil;
    
    if v.timer then
      v.timer:cancel();
    end
    
    v.timer = nil;
    knownLocks[k] = nil;
  end
  
  knownLocks = {};
end

-- Returns the lock data for a reference, or nil if it does
-- not support any.
function LockData.getForReference(ref)
  if not supportsLockData(ref) then
    return nil;
  end

  local data = LockData:new();
  data.parent = ref;
  local lockAttachment = ref.attachments.lock;
  
  if lockAttachment then
    data.key = lockAttachment.key;
    data.locked = lockAttachment.locked;
    data.lockLevel = lockAttachment.level;
    data.trap = lockAttachment.trap;
    data.trapped = Utility.coerceBool(lockAttachment.trap);
  end
  
  local extraData = getExtraData(data);
  
  data.trapDetected = extraData.trapDetected;
  data.playerSkill = extraData.playerSkill;
  data.inExterior = not ref.cell.isInterior;
  data.detectedAt = extraData.detectedAt;
  
  return data;
end

return LockData;