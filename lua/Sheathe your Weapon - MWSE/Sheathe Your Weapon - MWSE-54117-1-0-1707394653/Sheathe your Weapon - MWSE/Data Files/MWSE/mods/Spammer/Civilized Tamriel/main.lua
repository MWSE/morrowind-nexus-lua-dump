local mod = {
    name = "Sheathe Your Weapon!",
    ver = "2.0",
    author = "Von Djangos and Spammer",
    cf = { onOff2 = true, key = { keyCode = tes3.scanCode.esc, isShiftDown = false, isAltDown = false, isControlDown = false }, dropDown = 0, slider = 5, sliderpercent = 50, blocked = {
        ["Ald Velothi"] = true
    }, npcs = {}, textfield = "hello", switch = false, whiteList = {} }
}
local cf = mwse.loadConfig(mod.name, mod.cf)


local subtitles = require("Spammer\\Civilized Tamriel\\subtitles")
local common = require("Spammer\\Civilized Tamriel\\common")


local function getGuard(ref)
    return ref and
        not ref.isDead
        and ref.mobile
        and ref.mobile.object
        and not ref.mobile.inCombat
        and ref.mobile.object.isGuard
end

local guard = {}
local voiceOver = {}
local shouldGood = {}
local myTimer = {}
local hostile = {}
local summonLine = {}

local function clearData(ref) -- Flushes the saved variables
    guard[ref] = nil
    voiceOver[ref] = nil
    shouldGood[ref] = nil
    if myTimer[ref] then
        myTimer[ref]:cancel()
        myTimer[ref] = nil
    end
end

local function weaponReady() --Checks if the player actually is wielding a weapon
    return (tes3.mobilePlayer ~= nil)
        and tes3.mobilePlayer.weaponReady
        and (tes3.mobilePlayer.readiedWeapon.object ~= nil)
        and (tes3.mobilePlayer.readiedWeapon.object.objectType == tes3.objectType.weapon)
end

---@param follower tes3reference The guard to reset
---@param skipClear boolean|nil Whether data should be immedialtely cleared or not
local function startWander(follower, skipClear) --Go back patroling
    local wanderRange = common.generateWanderRange(tes3.getPlayerCell())
    local idles = common.generateIdles()
    follower.mobile.weaponReady = follower.mobile.inCombat
    timer.start({
        duration = 1,
        callback = function()
            tes3.setAIWander({ reference = follower, range = wanderRange, reset = true, idles = idles })
        end
    })
    if not skipClear then
        clearData(follower)
    end
end

---@return integer distance from the player
local function getDistance(ref, target) -- How far from the player?
    return ref.position:distance(target.position)
end

local weaponReadied = false
local restingIllegal = false
local guards = false
local summon = nil


---@param e table|weaponReadiedEventData
event.register("weaponReadied", function(e)
    if e.reference ~= tes3.player then return end
    if (e.weaponStack and e.weaponStack.object) then
        if e.weaponStack.object.objectType ~= tes3.objectType.weapon then
            return
        end
        weaponReadied = true
    end
end)
---@param e table|weaponUnreadiedEventData
event.register("weaponUnreadied", function(e)
    if e.reference ~= tes3.player then return end
    if not table.empty(guard) then
        for ref, _ in pairs(guard) do
            if not (ref.mobile.inCombat or ref.isDead) then
                if shouldGood[ref] then
                    local path = common.findPrefix(ref)
                    if not path then return end
                    path = path .. table.choice(common.good)
                    local sub = subtitles[path]
                    voiceOver[ref] = "Vo\\VDQuest\\" .. path
                    tes3.say { reference = ref, soundPath = voiceOver[ref], subtitle = sub }
                    shouldGood[ref] = nil
                end
                --
                startWander(ref, true)
                --]]
            end
            clearData(ref)
        end
    end
    weaponReadied = false
end)




---@param e table|addTempSoundEventData
local function addSound(e)
    if not e.reference then return end
    if not e.isVoiceover then return end
    if not guard[e.reference] then return end
    if not voiceOver[e.reference] then return end
    if voiceOver[e.reference] ~= e.path then return false end
end
event.register("addTempSound", addSound)
event.register("addSoundSound", addSound)

---@param e table|cellChangedEventData
event.register("cellChanged", function(e)
    restingIllegal = false
    guards = false
    if (e.cell.restingIsIllegal or cf.blocked[e.cell.id]) then
        weaponReadied = weaponReady()
        restingIllegal = true
        for ref in e.cell:iterateReferences(tes3.objectType.npc) do
            if getGuard(ref) then
                guards = true
                --debug.log(guards)
                break
            end
        end
    end
    local activeCell = table.invert(tes3.getActiveCells())
    for ref, _ in pairs(hostile) do
        if ref and (activeCell[ref.cell] and (ref.mobile.inCombat or ref.isDead)) or not activeCell[ref.cell] then
            hostile[ref] = nil
        end
    end
end)



---@param state integer
local function realShitWeapon(ref, state)
    if not guard[ref] then return end
    if ref.mobile.isPlayerHidden then
        startWander(ref)
        return
    end
    if (ref.mobile.inCombat or ref.isDead) then 
        clearData(ref)
        return 
    end
    if state == 2 then
        if not weaponReady() then
            if shouldGood[ref] then
                local path = common.findPrefix(ref)
                if not path then return end
                path = path .. table.choice(common.good)
                local sub = subtitles[path]
                voiceOver[ref] = "Vo\\VDQuest\\" .. path
                tes3.say { reference = ref, soundPath = voiceOver[ref], subtitle = sub }
                startWander(ref, true)
            end
            clearData(ref)
        else
            ---@param refs tes3reference
            for refs in pairs(guard) do
                hostile[refs] = true
                tes3.setAIWander { reference = refs, idles = {} }
            end
            timer.start { duration = 2, callback = function()
                if weaponReady() then
                    tes3.mobilePlayer.bounty = tes3.mobilePlayer.bounty + 500
                    for refs in tes3.player.cell:iterateReferences(tes3.objectType.npc) do
                        if getGuard(refs) then
                            hostile[refs] = true
                            refs.mobile:startCombat(tes3.mobilePlayer)
                            clearData(refs)
                        end
                    end
                    --tes3.triggerCrime({ type = tes3.crimeType.attack, victim = ref.mobile, forceDetection = true })
                else
                    for refs in pairs(guard) do
                        hostile[refs] = nil
                    end
                    realShitWeapon(ref, 2)
                end
            end }
        end
    elseif state == 1 then
        if weaponReady() then
            local path = common.findPrefix(ref)
            if not path then return end
            path = path .. table.choice(common.warn2)
            local sub = subtitles[path]
            voiceOver[ref] = "Vo\\VDQuest\\" .. path
            tes3.say { reference = ref, soundPath = voiceOver[ref], subtitle = sub }
            shouldGood[ref] = true
            ref.mobile.weaponReady = true
            myTimer[ref] = timer.start { duration = 5, callback = function()
                realShitWeapon(ref, 2)
            end }
        else
            startWander(ref)
        end
    end
end

local creatures = {
    [tes3.creatureType.undead] = "undead",
    [tes3.creatureType.daedra] = "daedra",
    [tes3.creatureType.normal] = "creature",
}
local function meatWeapon(ref)
    if not guard[ref] then return end
    if (ref.mobile.inCombat or ref.isDead) then 
        clearData(ref)
        return
    end
    local path = common.findPrefix(ref)
    if not path then 
        clearData(ref)
        return
    end
    path = path .. table.choice(common.warn1)
    local sub = subtitles[path]
    voiceOver[ref] = "Vo\\VDQuest\\" .. path
    tes3.say { reference = ref, soundPath = voiceOver[ref], subtitle = sub }
    tes3.setAIFollow { reference = ref, target = tes3.player, reset = true, }
    myTimer[ref] = timer.start { duration = 7, callback = function()
        realShitWeapon(ref, 1)
    end }
end

event.register("simulate", function()
    if not cf.onOff2 then return end
    if not restingIllegal then return end
    if not (weaponReadied or summon) then return end
    if not guards then return end
    local farAway = 500
    local closest
    for ref in tes3.player.cell:iterateReferences(tes3.objectType.npc) do
        if getGuard(ref) and tes3.testLineOfSight { reference1 = ref, reference2 = tes3.player } then
            local distance = getDistance(tes3.player, ref)
            if distance <= farAway then
                farAway = distance
                closest = ref
            end
        end
    end
    if closest then
        if summon and not summonLine[closest] then
            --debug.log(summon.id)
            local prefix = common.findPrefix(closest, true)
            --debug.log(prefix)
            local choice
            local path
            if prefix then
                if prefix == "GuardT" then
                    --debug.log(summon.id)
                    choice = ((summon.level <= 10) and table.choice(common.weak)) or table.choice(common.strong)
                    --debug.log(choice)
                else
                    if summon.id:lower() == "ancestor_ghost_summon" then
                        choice = table.choice(common.ghost)
                    elseif creatures[summon.type] then
                        choice = table.choice(common[creatures[summon.type]])
                    end
                end
            end
            --debug.log(choice)
            if choice then
                path = prefix .. choice
                local voice = "Vo\\VDQuest\\" .. path
                summonLine[closest] = voice
                tes3.say { reference = closest, soundPath = voice, subtitle = subtitles[path] }
            end
            timer.start({
                duration = 30,
                callback = function()
                    summonLine[closest] = nil
                end
            })
            summon = nil
        end
        if weaponReadied and not (guard[closest] or hostile[closest]) then
            guard[closest] = true
            meatWeapon(closest)
            --weaponReadied = false
        end
    end
end)


local bypass
---@param e table|activateEventData
event.register("activate", function(e)
    if e.activator ~= tes3.player then return end
    if guard[e.target] then bypass = e.target end
end)
---@param e table|infoGetTextEventData
event.register("infoGetText", function(e)
    if not bypass then return end
    local ref = bypass
    if e.info.type ~= tes3.dialogueType.greeting then return end
    local text = voiceOver[ref] and string.gsub(voiceOver[ref], "Vo\\VDQuest\\", "")
    --mwse.log("Text = %s", text)
    --mwse.log("Sub = %s", subtitles[text])
    if text and subtitles[text] then
        e.text = subtitles[text]:trim()
        bypass = nil
        timer.frame.delayOneFrame(function() tes3.runLegacyScript { command = "goodbye", reference = ref } end)
    end
end)


event.register("loaded", function()
    for ref, _ in pairs(myTimer) do
        myTimer[ref]:cancel()
        myTimer[ref] = nil
    end
    weaponReadied = false
    restingIllegal = false
    guards = false
    summon = nil
    summonLine = {}
    guard = {}
    voiceOver = {}
    shouldGood = {}
    hostile = {}
    if not tes3.mobilePlayer then return end
    weaponReadied = weaponReady()
end)



---comment
---@param e table|spellTickEventData
event.register("spellTick", function(e)
    if summon then return end
    local probableCaster = e.target and e.target.mobile
    if not probableCaster then return end
    if probableCaster ~= tes3.mobilePlayer then return end
    local instance = e.effectInstance
    local validSummon = instance.createdData
        and instance.createdData.object
        and (instance.createdData.object.objectType == tes3.objectType.reference)
    if not validSummon then return end
    ---@class creature tes3reference
    ---@field baseObject tes3creature
    local creature = instance.createdData.object
    --mwse.log(creature)
    if creature.baseObject.objectType ~= tes3.objectType.creature then return end
    summon = creature.baseObject
end)












local function showMessageBoxOnWeaponReadied(e)
    if not cf.onOff then return end
    if (e.reference ~= tes3.player) then
        return
    end
    if (tes3.mobilePlayer.cell.restingIsIllegal == false) then
        return
    end
    if (tes3.mobilePlayer.cell.isOrBehavesAsExterior == false and not (string.startswith(tes3.mobilePlayer.cell.id, "Vivec"))) then
        return
    end
    if (tes3.mobilePlayer.inCombat == true) then
        return
    end
    local weaponStack = e.weaponStack
    if (weaponStack and weaponStack.object) then
        tes3.messageBox({
            message = "This is a civilized area. Sheathe back that " .. weaponStack.object.name .. "!",
            buttons = { "Ok.", "Make me!" },
            callback = function(e)
                if (e.button == 0) then
                    tes3.mobilePlayer.weaponReady = false
                elseif (e.button == 1) then
                    tes3.triggerCrime({ type = tes3.crimeType.theft, victim = nil, value = 500, })
                end
            end
        })
    end
end
local skip = false
local function showMessageBoxOnSpellCast(e)
    if not cf.onOff then return end
    if (e.caster ~= tes3.player) then
        return
    end
    if (tes3.mobilePlayer.cell.restingIsIllegal == false) then
        return
    end
    if (tes3.mobilePlayer.cell.isOrBehavesAsExterior == false and not (string.startswith(tes3.mobilePlayer.cell.id, "Vivec"))) then
        return
    end
    if (tes3.mobilePlayer.inCombat == true) then
        return
    end

    if not (e.effect and e.effect.object and e.effect.object.isHarmful) then return end

    if skip then
        skip = false
        return
    end
    e.castChance = 0
    tes3.messageBox({
        message = "This is a civilized area. No spells !",
        buttons = { "Ok.", "Or else?" },
        callback = function(f)
            if (f.button == 1) then
                skip = true
                tes3.triggerCrime({ type = tes3.crimeType.theft, victim = nil, value = 500, })
                tes3.cast({ reference = e.caster, spell = e.source, instant = true })
            end
        end
    })
end


local function getExclusionList()
    local list = {}
    for _, cell in pairs(tes3.dataHandler.nonDynamicData.cells) do
        if not cell.restingIsIllegal then
            table.insert(list, cell.id)
        end
    end
    table.sort(list)
    return list
end

local function registerModConfig()
    local template = mwse.mcm.createTemplate(mod.name)
    template:saveOnClose(mod.name, cf)
    template:register()
    template.onSearch = function(search)
        return string.startswith("spammer", search)
    end
    local page = template:createSideBarPage({ label = "\"" .. mod.name .. "\" Settings" })
    page.sidebar:createInfo { text = "Welcome to \"" .. mod.name .. "\" Configuration Menu. \n \n \n A mod by " .. mod.author .. "." }
    page.sidebar:createHyperlink { text = "Spammer's Nexus Profile", url = "https://www.nexusmods.com/users/140139148?tab=user+files" }
    page.sidebar:createHyperlink { text = "Von Djangos's Nexus Profile", url = "https://www.nexusmods.com/morrowind/users/40926435?tab=user+files" }

    local category0 = page:createCategory("")
    category0:createOnOffButton { label = "Mod On/Off", variable = mwse.mcm.createTableVariable { id = "onOff2", table = cf } }
    template:createExclusionsPage { label = "Cells Whitelist", description = "Cells in which the guards should bully you.", variable = mwse.mcm.createTableVariable { id = "blocked", table = cf }, filters = { { label = "Cells", callback = getExclusionList } } }
end
event.register("modConfigReady", registerModConfig)

local function initialized()
    --event.register("weaponReadied", showMessageBoxOnWeaponReadied)
    --event.register("spellCast", showMessageBoxOnSpellCast)
    print("[" .. mod.name .. ", by " .. mod.author .. "] " .. mod.ver .. " Initialized!")
end
event.register("initialized", initialized, { priority = -1000 })
