local this = {}

-- {{{ mod info and such

this.modName = "More Attentive Guards" -- or something
this.author = "Celediel"
this.version = "1.1.6"
this.modInfo = "Guards with some actual spatial awareness!\n\n" ..
"Guards who catch you sneaking will follow you for a bit of" ..
"time, and will also come to the player's rescue if attacked unprovoked."
this.dialogues = require("celediel.MoreAttentiveGuards.dialogues")
this.configString = string.gsub(this.modName, "%s+", "")

-- }}}

-- {{{ NPC stuff or whatever

this.basicIdles = {60, 20, 20, 20, 0, 0, 0, 0}

-- }}}

-- {{{ functions

this.log = function(...) mwse.log("[%s] %s", this.modName, string.format(...)) end

-- https://en.uesp.net/wiki/Tes3Mod:AIWander told me some things about idles
this.generateIdles = function()
    local idles = {}
    -- idles[1] = 0 -- ? idle 1 is not used?
    for i = 1, 4 do idles[i] = math.random(0, 60) end
    idles[5] = 0 -- ? Idle6: Rubbing hands together and showing wares
    for i = 6, 8 do idles[i] = math.random(0, 60) end
    return idles
end

this.generateWanderRange = function(cell)
    -- wander less inside?
    return (cell.isInterior and not cell.behavesAsExterior) and 200 or 2000
end

this.guardDialogue = function(npc, str, target)
    -- target of the dialogue, either an NPC/Creature, or the player's class or race
    -- this is what %s is replaced with in the dialogue string; npc/creature for combat, player for sneak
    local targetOrPlayer
    if target == tes3.mobilePlayer then
        targetOrPlayer = math.random() >= 0.5 and target.object.class.name or target.object.race.name
    else
        targetOrPlayer = target.object.name
    end

    local message = string.format(str, targetOrPlayer)
    local output = string.format("%s: %s", npc, message)

    tes3.messageBox(output)
    return output
end

-- }}}

return this

-- vim:fdm=marker
