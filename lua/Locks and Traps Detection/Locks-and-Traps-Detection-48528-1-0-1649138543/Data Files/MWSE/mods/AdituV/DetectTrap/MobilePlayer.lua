local Config = require("AdituV.DetectTrap.Config");
local Utility = require("AdituV.DetectTrap.Utility");

-- Proxy for tes3.mobileplayer with extended functionality
local MobilePlayer = {
  -- (Float) the additional chance (from 0 to 1) applied to trap detection.
  -- Intended to be modified by a spell/enchantment, etc.
  trapDetectionBonus = 0,
};

setmetatable(MobilePlayer, MobilePlayer);
MobilePlayer.__index = function (self, key)
  return tes3.mobilePlayer[key];
end

function MobilePlayer.getEffectiveSecurityLevel()
  local security = MobilePlayer.security.current;
  local intelligence = MobilePlayer.intelligence.current;
  local luck = MobilePlayer.luck.current;
  
  return security + (intelligence / 5) + (luck / 10);
end

function MobilePlayer.getFatigueTerm()
  local fFatigueMult = tes3.findGMST(tes3.gmst.fFatigueMult).value;
  local fFatigueBase = tes3.findGMST(tes3.gmst.fFatigueBase).value;
  
  return fFatigueMult*MobilePlayer.fatigue.normalized + fFatigueBase;
end

function MobilePlayer.getTrapDetectProbability()
  local effectiveSecurity = MobilePlayer.getEffectiveSecurityLevel();
  local fatigueTerm = MobilePlayer.getFatigueTerm();  
  local effectiveLevel = fatigueTerm * effectiveSecurity;
  
  local smoother = Utility.mkLogistic(0,1, Config.trapDifficulty.steepness, Config.trapDifficulty.midpoint);
  
  return smoother(effectiveLevel) + MobilePlayer.trapDetectionBonus;
end

return MobilePlayer;