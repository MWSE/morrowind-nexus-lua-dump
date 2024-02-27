local this = {}

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
    return ((cell.isInterior and not cell.behavesAsExterior) and 200) or 2000
end

--[[
this.playGuardText = function(npc, str, target)
    -- target of the dialogue, either an NPC/Creature, or the player's class or race.
    -- This is what %s is replaced with in the dialogue string; npc/creature for combat, player for sneak
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
--]]


---@param ref tes3reference
---@param spell boolean|nil
---@return string|nil
function this.findPrefix(ref, spell)
    local path
    if (not (spell and ref.object.female)) and (ref.object.race.id:lower() == "imperial") then
        path = "IMguard"
    end
    if (not (spell and ref.object.female)) and ref.object.race.id:lower() == "orc" then
        path = "Orc"
    end
    if ref.object.race.id:lower() == "dark elf" then
        if ref.object.female then
            if not spell then
                path = "DFguard"
            end
        else
            if (not spell) and (ref.object.faction and ref.object.faction.id:lower()) == "temple" then
                path = "Ord"
            elseif spell and (ref.object.faction and ref.object.faction.id:lower() == "telvanni") then
                path = "GuardT"
            elseif spell then
                path = "Guard"
            elseif not spell then
                path = "DMguard"
            end
        end
    end
    return path
end

this.warn1 = {
    "noweap.mp3",
    "noweap2.mp3",
    "noweap3.mp3",
    "noweap4.mp3",
    "noweap5.mp3",
    "noweap6.mp3",
    "noweap7.mp3",
}

this.warn2 = {
    "warn.mp3",
    "warn2.mp3",
    "warn3.mp3",
    "warn4.mp3",
    "warn5.mp3",
    "warn6.mp3",
    "warn7.mp3",
}

this.good = {
    "good.mp3",
    "good2.mp3",
    "good3.mp3",
    "good4.mp3",
    "good5.mp3",
    "good6.mp3",
    "good7.mp3",
}


this.weak = {
    "Summon1.mp3",
    "Summon2.mp3",
    "Summon3.mp3",
    "Summon4.mp3",
    "Summon5.mp3",
}
this.strong = {
    "Summon6.mp3",
    "Summon7.mp3",
    "Summon8.mp3",
    "Summon9.mp3",
    "Summon0.mp3",
}
this.undead = {
    "undead1.mp3",
    "undead2.mp3",
    "undead3.mp3",
    "undead4.mp3",
    "undead5.mp3",
    "ghost3.mp3",
}
this.ghost = {
    "ghost1.mp3",
    "ghost2.mp3",
    "ghost3.mp3",
    "ghost4.mp3",
    "ghost5.mp3",
}
this.daedra = {
    "daedra1.mp3",
    "daedra2.mp3",
    "daedra3.mp3",
    "daedra4.mp3",
    "TSummon6.mp3",
    "ghost3.mp3",
}

this.creature = {
    "undead1.mp3",
    "ghost3.mp3",
    "daedra2.mp3",
}

--[[
-- Plays a random sound of specified type and returns the path of the sound file that was played
this.playGuardVoice = function(mobile, type)
    local distanceCap = 2500 --  sounds further away than this are too quiet to be heard
    local ref = mobile.reference
    local sex = (ref.baseObject.female and "fe" or "") .. "male"
    local race = ref.baseObject.race.id:lower()
    local sound

    -- ordinators have special voices, so here's some hacky shit to incorporate them
    if not ref.baseObject.female and (ref.id:lower():match(ordinator) or ref.object.class.id:lower():match(ordinator)) then
        race = ordinator
    end

    -- make sure the race/sex/type combo exists in the voice data
    if this.dialogues.voice[race] and this.dialogues.voice[race][sex] and this.dialogues.voice[race][sex][type] then
        -- sound will be nil if the race/sex/type combo is an empty table
        sound = table.choice(this.dialogues.voice[race][sex][type])
    end

    local distanceFromPlayer = math.clamp(mobile.position:distance(tes3.mobilePlayer.position), 0, distanceCap) or 0
    local volume = 1 - (distanceFromPlayer / distanceCap)

    -- LuaFormatter off
    if sound then
        tes3.say({
            soundPath = sound.file,
            subtitle = sound.subtitle,
            volume = volume,
            reference = mobile
        })
    end
    -- LuaFormatter on

    return sound and sound.file
end

-- }}}
--]]
return this
