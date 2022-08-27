--- Requires
local permanentCalm = require('biltjan.magicka_awakening.illusion.calm')
local permanentDemoralize = require('biltjan.magicka_awakening.illusion.demoralize')
local permanentFrenzy = require('biltjan.magicka_awakening.illusion.frenzy')
local permanentRally = require('biltjan.magicka_awakening.illusion.rally')
local alluringTrade = require('biltjan.magicka_awakening.illusion.charm')
local persistingShadows = require('biltjan.magicka_awakening.illusion.invisibility')
local stolenVision = require('biltjan.magicka_awakening.illusion.blind')
local enfeeblingLight = require('biltjan.magicka_awakening.illusion.light')
local deafeningSilence = require('biltjan.magicka_awakening.illusion.silence')
local paralyzingTorpor = require('biltjan.magicka_awakening.illusion.paralyze')
local illusionLevelUp = require('biltjan.magicka_awakening.illusion.skillLevelUp')
--- Illusion
event.register(tes3.event.magicEffectRemoved, permanentCalm)
event.register(tes3.event.magicEffectRemoved, permanentDemoralize)
event.register(tes3.event.magicEffectRemoved, permanentFrenzy)
event.register(tes3.event.magicEffectRemoved, permanentRally)
event.register(tes3.event.spellResist, alluringTrade)
event.register(tes3.event.magicEffectRemoved, persistingShadows)
event.register(tes3.event.spellResist, stolenVision)
event.register(tes3.event.spellResist, enfeeblingLight)
event.register(tes3.event.magicEffectRemoved, deafeningSilence)
event.register(tes3.event.magicEffectRemoved, paralyzingTorpor)
-- Illusion level ups
for i = 1, 10, 1 do
	event.register(tes3.event.skillRaised, illusionLevelUp[i])
end
--- Mod configs
local function registerModConfig()
	require("biltjan.magicka_awakening.mcm")
end
event.register("modConfigReady", registerModConfig)
