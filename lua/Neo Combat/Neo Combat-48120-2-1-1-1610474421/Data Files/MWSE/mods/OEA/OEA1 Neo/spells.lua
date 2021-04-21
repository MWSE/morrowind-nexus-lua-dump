local BlockSpell = tes3spell.create("OEA1_Blocking_Penalty", "Button Block")
if (BlockSpell == nil) then
	BlockSpell = tes3.getObject("OEA1_Blocking_Penalty")
end

BlockSpell.magickaCost = 0
BlockSpell.castType = tes3.spellType.ability
BlockSpell.effects[1].id = tes3.effect.drainSkill
BlockSpell.effects[1].rangeType = tes3.effectRange.self
BlockSpell.effects[1].min = 1000
BlockSpell.effects[1].max = 1000
BlockSpell.effects[1].duration = 0
BlockSpell.effects[1].radius = 0
BlockSpell.effects[1].skill = tes3.skill.block
BlockSpell.effects[1].attribute = nil

local CounterSpell = tes3spell.create("OEA1_Counter_1", "Ready to Counter")
if (CounterSpell == nil) then
	CounterSpell = tes3.getObject("OEA1_Counter_1")
end

CounterSpell.magickaCost = 0
CounterSpell.castType = tes3.spellType.ability
CounterSpell.effects[1].id = tes3.effect.paralyze
CounterSpell.effects[1].rangeType = tes3.effectRange.self
CounterSpell.effects[1].min = 0
CounterSpell.effects[1].max = 0
CounterSpell.effects[1].duration = 0
CounterSpell.effects[1].radius = 0
CounterSpell.effects[1].skill = nil
CounterSpell.effects[1].attribute = nil

CounterSpell.effects[2].id = tes3.effect.sanctuary
CounterSpell.effects[2].rangeType = tes3.effectRange.self
CounterSpell.effects[2].min = 1000
CounterSpell.effects[2].max = 1000
CounterSpell.effects[2].duration = 0
CounterSpell.effects[2].radius = 0
CounterSpell.effects[2].skill = nil
CounterSpell.effects[2].attribute = nil

local RageSpell = tes3spell.create("OEA1_Key_Rage", "Rage")
if (RageSpell == nil) then
	RageSpell = tes3.getObject("OEA1_Key_Rage")
end

RageSpell.magickaCost = 0
RageSpell.castType = tes3.spellType.spell
RageSpell.effects[1].id = tes3.effect.fortifyAttribute
RageSpell.effects[1].rangeType = tes3.effectRange.touch
RageSpell.effects[1].min = 15
RageSpell.effects[1].max = 15
RageSpell.effects[1].duration = 25
RageSpell.effects[1].radius = 1
RageSpell.effects[1].skill = nil
RageSpell.effects[1].attribute = tes3.attribute.speed

RageSpell.effects[2].id = tes3.effect.fortifyAttribute
RageSpell.effects[2].rangeType = tes3.effectRange.touch
RageSpell.effects[2].min = 20
RageSpell.effects[2].max = 20
RageSpell.effects[2].duration = 25
RageSpell.effects[2].radius = 1
RageSpell.effects[2].skill = nil
RageSpell.effects[2].attribute = tes3.attribute.strength

RageSpell.effects[3].id = tes3.effect.fortifyAttack
RageSpell.effects[3].rangeType = tes3.effectRange.touch
RageSpell.effects[3].min = 10
RageSpell.effects[3].max = 10
RageSpell.effects[3].duration = 25
RageSpell.effects[3].radius = 1
RageSpell.effects[3].skill = nil
RageSpell.effects[3].attribute = nil

RageSpell.effects[4].id = tes3.effect.fortifyHealth
RageSpell.effects[4].rangeType = tes3.effectRange.touch
RageSpell.effects[4].min = 10
RageSpell.effects[4].max = 10
RageSpell.effects[4].duration = 25
RageSpell.effects[4].radius = 1
RageSpell.effects[4].skill = nil
RageSpell.effects[4].attribute = nil

local SpeedSpell = tes3spell.create("OEA1_Speed_Drain", "Speed Penalty")
if (SpeedSpell == nil) then
	SpeedSpell = tes3.getObject("OEA1_Speed_Drain")
end

SpeedSpell.magickaCost = 0
SpeedSpell.castType = tes3.spellType.ability
SpeedSpell.effects[1].id = tes3.effect.drainAttribute
SpeedSpell.effects[1].rangeType = tes3.effectRange.self
SpeedSpell.effects[1].min = 25
SpeedSpell.effects[1].max = 25
SpeedSpell.effects[1].duration = 0
SpeedSpell.effects[1].radius = 0
SpeedSpell.effects[1].skill = nil
SpeedSpell.effects[1].attribute = tes3.attribute.speed

local SpeedSpellHand = tes3spell.create("OEA1_Speed_Drain_2", "Unarmed Speed Penalty")
if (SpeedSpellHand == nil) then
	SpeedSpellHand = tes3.getObject("OEA1_Speed_Drain_2")
end

SpeedSpellHand.magickaCost = 0
SpeedSpellHand.castType = tes3.spellType.ability
SpeedSpellHand.effects[1].id = tes3.effect.drainAttribute
SpeedSpellHand.effects[1].rangeType = tes3.effectRange.self
SpeedSpellHand.effects[1].min = 40
SpeedSpellHand.effects[1].max = 40
SpeedSpellHand.effects[1].duration = 0
SpeedSpellHand.effects[1].radius = 0
SpeedSpellHand.effects[1].skill = nil
SpeedSpellHand.effects[1].attribute = tes3.attribute.speed