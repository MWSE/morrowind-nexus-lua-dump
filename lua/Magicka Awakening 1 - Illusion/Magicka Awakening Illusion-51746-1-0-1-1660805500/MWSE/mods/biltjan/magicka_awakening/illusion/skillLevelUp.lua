--- Message Box
-- Config
local config = require("biltjan.magicka_awakening.config")

local rallyEnabled = config.rallyEnabled
local rallyLevel = config.rallyIllusionRequirement

local frenzyEnabled = config.frenzyEnabled
local frenzyLevel = config.frenzyIllusionRequirement

local lightEnabled = config.lightEnabled
local lightLevel = config.lightIllusionRequirement

local blindEnabled = config.blindEnabled
local blindLevel = config.blindIllusionRequirement

local calmEnabled = config.calmEnabled
local calmLevel = config.calmIllusionRequirement

local charmEnabled = config.charmEnabled
local charmLevel = config.charmIllusionRequirement

local demoralizeEnabled = config.demoralizeEnabled
local demoralizeLevel = config.demoralizeIllusionRequirement

local silenceEnabled = config.silenceEnabled
local silenceLevel = config.silenceIllusionRequirement

local paralyzeEnabled = config.paralyzeEnabled
local paralyzeLevel = config.paralyzeIllusionRequirement

local invisibilityEnabled = config.invisibilityEnabled
local invisibilityLevel = config.invisibilityIllusionRequirement

-- Rally
--- @param e skillRaisedEventData
local function rally(e)
  -- Check if enabled
  if rallyEnabled then
    if ((e.skill == tes3.skill.illusion) and (e.level == rallyLevel)) then
      tes3.messageBox({message = 'You\'ve reached level ' .. tostring(rallyLevel) .. ' in Illusion. You can now permanently Rally.', duration = 10})
    end
  end
end

-- Frenzy
--- @param e skillRaisedEventData
local function frenzy(e)
  -- Check if enabled
  if frenzyEnabled then
    if ((e.skill == tes3.skill.illusion) and (e.level == frenzyLevel)) then
      tes3.messageBox({message = 'You\'ve reached level ' .. tostring(frenzyLevel) .. ' in Illusion. You can now permanently Frenzy.', duration = 10})
    end
  end
end

-- Light
--- @param e skillRaisedEventData
local function light(e)
  -- Check if enabled
  if lightEnabled then
    if ((e.skill == tes3.skill.illusion) and (e.level == lightLevel)) then
      tes3.messageBox({message = 'You\'ve reached level ' .. tostring(lightLevel) .. ' in Illusion. Your light now inflicts Drain Willpower.', duration = 10})
    end
  end
end

-- Blind
--- @param e skillRaisedEventData
local function blind(e)
  -- Check if enabled
  if blindEnabled then
    if ((e.skill == tes3.skill.illusion) and (e.level == blindLevel)) then
      tes3.messageBox({message = 'You\'ve reached level ' .. tostring(blindLevel) .. ' in Illusion. Your blind now fortifies your attack.', duration = 10})
    end
  end
end

-- Calm
--- @param e skillRaisedEventData
local function calm(e)
  -- Check if enabled
  if calmEnabled then
    if ((e.skill == tes3.skill.illusion) and (e.level == calmLevel)) then
      tes3.messageBox({message = 'You\'ve reached level ' .. tostring(calmLevel) .. ' in Illusion. You can now permanently Calm.', duration = 10})
    end
  end
end

-- Charm
--- @param e skillRaisedEventData
local function charm(e)
  -- Check if enabled
  if charmEnabled then
    if ((e.skill == tes3.skill.illusion) and (e.level == charmLevel)) then
      tes3.messageBox({message = 'You\'ve reached level ' .. tostring(charmLevel) .. ' in Illusion. Your charm now reduce the target\'s mercantile.', duration = 10})
    end
  end
end

-- Demoralize
--- @param e skillRaisedEventData
local function demoralize(e)
  -- Check if enabled
  if demoralizeEnabled then
    if ((e.skill == tes3.skill.illusion) and (e.level == demoralizeLevel)) then
      tes3.messageBox({message = 'You\'ve reached level ' .. tostring(demoralizeLevel) .. ' in Illusion. You can now permanently Demoralize.', duration = 10})
    end
  end
end

-- Silence
--- @param e skillRaisedEventData
local function silence(e)
  -- Check if enabled
  if silenceEnabled then
    if ((e.skill == tes3.skill.illusion) and (e.level == silenceLevel)) then
      tes3.messageBox({message = 'You\'ve reached level ' .. tostring(silenceLevel) .. ' in Illusion. You inflict Sound after your Silence ends.', duration = 10})
    end
  end
end

-- Paralyze
--- @param e skillRaisedEventData
local function paralyze(e)
  -- Check if enabled
  if paralyzeEnabled then
    if ((e.skill == tes3.skill.illusion) and (e.level == paralyzeLevel)) then
      tes3.messageBox({message = 'You\'ve reached level ' .. tostring(paralyzeLevel) .. ' in Illusion. You inflict Drain Speed after your Paralyze ends.', duration = 10})
    end
  end
end

-- Invisibility
--- @param e skillRaisedEventData
local function Invisibility(e)
  -- Check if enabled
  if invisibilityEnabled then
    if ((e.skill == tes3.skill.illusion) and (e.level == invisibilityLevel)) then
      tes3.messageBox({message = 'You\'ve reached level ' .. tostring(invisibilityLevel) .. ' in Illusion. You gain Chameleon after your Invisibility breaks.', duration = 10})
    end
  end
end

return { 
  rally, 
  frenzy,
  light,
  blind,
  calm,
  charm,
  demoralize,
  silence,
  paralyze,
  Invisibility
}