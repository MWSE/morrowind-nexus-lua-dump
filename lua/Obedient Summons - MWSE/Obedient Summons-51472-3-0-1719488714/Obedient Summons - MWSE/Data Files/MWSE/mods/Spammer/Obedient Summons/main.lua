---@diagnostic disable: undefined-field
local mod = {
    name = "Obedient Summons",
    ver = "2.0",
    cf = {
        onOff = true,
        key = {
            keyCode = tes3.scanCode.l,
            isShiftDown = false,
            isAltDown = false,
            isControlDown = false
        },
        dropDown = 0,
        slider = 5,
        sliderpercent = 50,
        blocked = {},
        npcs = {},
        textfield = "hello",
        switch = false
    }
}
local cf = mwse.loadConfig(mod.name, mod.cf)
local framework = require("OperatorJack.MagickaExpanded")
if not framework then return end
tes3.claimSpellEffectId("soulRelease", 787)

---comment
---@param e table|deathEventData
event.register("death", function(e)
    local doit = e.reference and e.reference.data and e.reference.data.spa_SR_summonnedSoul
    if doit then
        local summon = e.reference
        local position = summon.position
        summon:delete()
        timer.start {
            duration = 0.5,
            callback = function()
                tes3.createVisualEffect {
                    object = "VFX_Summon_Start",
                    repeatCount = 1,
                    position = position
                }
            end
        }
    end
end)

---comment
---@param e table|spellTickEventData
event.register("spellTick", function(e)
    if e.target ~= tes3.player then return end
    local instance = e.effectInstance
    if not (instance.createdData and instance.createdData.object and
        (instance.createdData.object.objectType == tes3.objectType.reference)) then return end
    if not instance.createdData.object.data.spa_SR_summonnedCreature then
        instance.createdData.object.data.spa_SR_summonnedCreature = true
    end
end)

local function valid(summon)
    if (summon and summon.data and summon.data.spa_SR_summonnedSoul) then
        return true
    elseif (summon and summon.data and summon.data.spa_SR_summonnedCreature) then
        return true
    end
    return false
end
---comment
---@param e table|activateEventData
event.register("activate", function(e)
    if e.activator ~= tes3.player then return end
    local summon = e.target
    if not valid(summon) then return end
    tes3.messageBox {
        message = "How may I serve you, Master?",
        buttons = {"Wait here", "Patrol the area", "Follow me", "Show me what you hoard", "Begone"},
        callback = ---comment
        ---@param f buttonPressedEventData
        function(f)
            if f.button == 0 then
                tes3.setAIWander {
                    reference = summon,
                    idles = {60, 20, 20, 0, 0, 0, 0, 0, 0},
                    range = 0,
                    reset = false
                }
            elseif f.button == 1 then
                timer.delayOneFrame(function()
                    tes3.setAIWander {
                        reference = summon,
                        idles = {60, 20, 20, 0, 0, 0, 0, 0, 0},
                        range = 2000,
                        reset = false
                    }
                end)
            elseif f.button == 2 then
                tes3.setAIFollow {reference = summon, target = tes3.player, reset = false}
            elseif f.button == 3 then
                timer.delayOneFrame(function()
                    tes3.showContentsMenu {reference = summon, pickpocket = false}
                end)
            elseif f.button == 4 then
                summon.mobile:kill()
            end
        end
    }
    return false
end, {priority = 100})

---comment
---@param ref tes3reference
---@param location tes3vector3
---@return boolean
local function getDistace(ref, location) return (ref.position:distance(location) <= 200) end

local function onCollision(e)
    local position = e.collision and e.collision.point
    if not position then return end
    local caster = e.sourceInstance.caster and e.sourceInstance.caster.mobile
    local summon
    for _, cell in pairs(tes3.getActiveCells()) do
        for ref in cell:iterateReferences(tes3.objectType.miscItem) do
            if (ref and ref.object and ref.object.isSoulGem and ref.itemData and ref.itemData.soul and
                getDistace(ref, position)) then
                summon = tes3.createReference {
                    object = ref.itemData.soul,
                    position = position,
                    cell = cell
                }
                tes3.playSound {sound = "conjuration hit", reference = tes3.player}
                for _, child in ipairs(summon.sceneNode.children) do
                    if child then
                        tes3.createVisualEffect {
                            object = "VFX_Summon_Start",
                            repeatCount = 1,
                            avObject = child
                        }
                    end
                end
                summon.mobile.fight = 30
                tes3.setAIFollow {reference = summon, target = tes3.player, reset = false}
                for _, stack in pairs(summon.object.inventory) do
                    tes3.removeItem {reference = summon, item = stack.object, playSound = false}
                end
                tes3.addItem {reference = summon, item = "random_weapon_melee_basic"}
                summon.data.spa_SR_summonnedSoul = true
                if caster then
                    summon.data.spa_StealSummon_summonnedCreature = {
                        summonner = caster,
                        value = caster:getSkillValue(tes3.skill.conjuration)
                    }
                end
                if ref.itemData.owner then
                    tes3.triggerCrime {
                        criminal = caster,
                        type = tes3.crimeType.theft,
                        victim = ref.itemData.owner,
                        value = ref.object.value
                    }
                end
                ref.itemData = nil
                break
            end
        end
    end
    if not summon then tes3.messageBox("%s", tes3.findGMST("sMagicInvalidTarget").value) end
end

local function addEffect()
    framework.effects.conjuration.createBasicEffect({
        -- Base information.
        id = tes3.effect.soulRelease,
        name = "Soul Release",
        description = "Summons the Soul of a Fallen One contained inside of a Soul Gem.",

        -- Basic dials.
        baseCost = 200.0,

        -- Various flags.
        allowEnchanting = false,
        allowSpellmaking = true,
        canCastSelf = false,
        canCastTouch = false,
        canCastTarget = true,
        hasContinuousVFX = false,
        nonRecastable = false,
        casterLinked = false,
        hasNoDuration = true,
        hasNoMagnitude = true,

        -- Graphics/sounds.
        icon = "Spammer\\Soul_Release_MW.tga",
        lighting = {0.8, 0.8, 0.2},
        -- Required callbacks.
        onTick = function(e) e:trigger() end,
        onCollision = onCollision
    })
end
event.register("magicEffectsResolved", addEffect)

local function registerSpells()
    framework.spells.createBasicSpell({
        id = "Spa_ME_SoulRelease",
        name = "Soul Release",
        effect = tes3.effect.soulRelease,
        rangeType = tes3.effectRange.target
    })
end
event.register("MagickaExpanded:Register", registerSpells)

local count = 0

local function onMobileActivated(e)
    if e.reference.object.objectType ~= tes3.objectType.npc then return end
    if not (e.mobile and e.mobile.object:offersService(tes3.merchantService.spells)) then return end
    if e.reference.data.spammer_srdoonce then return end
    if math.random(0, 100) < 5 then
        tes3.addSpell({reference = e.mobile, spell = "Spa_ME_SoulRelease"})
        -- print(e.mobile.object.name)
        count = 0
    else
        count = count + 1
        -- print(count)
        if count >= 20 then
            tes3.addSpell({reference = e.mobile, spell = "Spa_ME_SoulRelease"})
            -- print(e.mobile.object.name)
            count = 0
        end
    end
    e.reference.data.spammer_srdoonce = true
end
event.register("mobileActivated", onMobileActivated, {priority = -500})

local function getExclusionList()
    local fullbooklist = {}
    for book in tes3.iterateObjects(tes3.objectType.book) do
        if not (string.find(book.id:lower(), "skill")) then
            table.insert(fullbooklist, book.id)
        end
    end
    table.sort(fullbooklist)
    return fullbooklist
end

local function registerModConfig()
    local template = mwse.mcm.createTemplate(mod.name)
    template:saveOnClose(mod.name, cf)
    template:register()

    local page = template:createSideBarPage({label = "\"" .. mod.name .. "\" Settings"})
    page.sidebar:createInfo{
        text = "Welcome to \"" .. mod.name .. "\" Configuration Menu. \n \n \n A mod by Spammer."
    }
    page.sidebar:createHyperLink{
        text = "Spammer's Nexus Profile",
        url = "https://www.nexusmods.com/users/140139148?tab=user+files"
    }

    local category0 = page:createCategory(" ")
    category0:createOnOffButton{
        label = " ",
        description = " ",
        variable = mwse.mcm.createTableVariable {id = "onOff", table = cf}
    }

    category0:createKeyBinder{
        label = " ",
        description = " ",
        allowCombinations = false,
        variable = mwse.mcm.createTableVariable {
            id = "key",
            table = cf,
            restartRequired = true,
            defaultSetting = {
                keyCode = tes3.scanCode.l,
                isShiftDown = false,
                isAltDown = false,
                isControlDown = false
            }
        }
    }

    local category1 = page:createCategory(" ")
    local elementGroup = category1:createCategory("")

    elementGroup:createDropdown{
        description = " ",
        options = {
            {label = " ", value = 0}, {label = " ", value = 1}, {label = " ", value = 2},
            {label = " ", value = 3}, {label = " ", value = 4}, {label = " ", value = -1}
        },
        variable = mwse.mcm:createTableVariable{id = "dropDown", table = cf}
    }

    elementGroup:createTextField{
        label = " ",
        variable = mwse.mcm.createTableVariable {id = "textfield", table = cf, numbersOnly = false}
    }

    local category2 = page:createCategory(" ")
    local subcat = category2:createCategory(" ")

    subcat:createSlider{
        label = " ",
        description = " ",
        min = 0,
        max = 10,
        step = 1,
        jump = 1,
        variable = mwse.mcm.createTableVariable {id = "slider", table = cf}
    }

    subcat:createSlider{
        label = " " .. "%s%%",
        description = " ",
        min = 0,
        max = 100,
        step = 1,
        jump = 10,
        variable = mwse.mcm.createTableVariable {id = "sliderpercent", table = cf}
    }

    template:createExclusionsPage{
        label = " ",
        description = " ",
        variable = mwse.mcm.createTableVariable {id = "blocked", table = cf},
        filters = {{label = " ", callback = getExclusionList}}
    }

    template:createExclusionsPage{
        label = " ",
        description = " ",
        variable = mwse.mcm.createTableVariable {id = "npcs", table = cf},
        filters = {{label = "NPCs", type = "Object", objectType = tes3.objectType.npc}}
    }

    local page2 = template:createSideBarPage({label = "Extermination list"})
    page2:createButton{
        buttonText = "Switch",
        callback = function()
            cf.switch = not cf.switch
            local pageBlock = template.elements.pageBlock
            pageBlock:destroyChildren()
            page2:create(pageBlock)
            template.currentPage = page2
            pageBlock:getTopLevelParent():updateLayout()
        end,
        inGameOnly = false
    }
    local category = page2:createCategory("")
    category:createInfo{
        text = "",
        inGameOnly = false,
        postCreate = function(self)
            if cf.switch then
                self.elements.info.text = "Creatures gone extinct:"
                self.elements.info.color = tes3ui.getPalette("journal_finished_quest_pressed_color")
            else
                self.elements.info.text = "Creatures you've killed:"
                self.elements.info.color = tes3ui.getPalette("journal_finished_quest_pressed_color")
            end
        end
    }
    category:createInfo{
        text = "Load a saved game to see this.",
        inGameOnly = true,
        postCreate = function(self)
            if cf.switch then
                if tes3.player then
                    local list = ""
                    for actor, value in pairs(tes3.getKillCounts()) do
                        if (actor.objectType == tes3.objectType.creature) and
                            (value >= tonumber(cf.slider)) then
                            list = actor.name .. "s (RIP)" .. "\n" .. list
                        end
                    end
                    if list == "" then list = "None." end
                    self.elements.info.text = list
                end
            else
                if tes3.player then
                    local list = ""
                    for actor, value in pairs(tes3.getKillCounts()) do
                        if (actor.objectType == tes3.objectType.creature) and actor.cloneCount > 1 then
                            list = actor.name .. "s: " .. value .. "\n" .. list
                        end
                    end
                    if list == "" then list = "None." end
                    self.elements.info.text = list
                end
            end
        end
    }
end -- event.register("modConfigReady", registerModConfig)

local function initialized() print("[" .. mod.name .. ", by Spammer] " .. mod.ver .. " Initialized!") end
event.register("initialized", initialized, {priority = -1000})

