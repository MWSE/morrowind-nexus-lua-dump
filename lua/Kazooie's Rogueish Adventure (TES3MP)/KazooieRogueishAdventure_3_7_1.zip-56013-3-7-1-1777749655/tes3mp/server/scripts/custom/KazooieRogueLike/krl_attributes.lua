local attributes = {{
    id = "cannibal", 
    name = "Cannibal", 
    description = "When you dispose of a corpse, you eat it.\nWhich restores half your health.\n\nYour Restoration skill is set to 0.",
    on_give = function(pid)
        local skill_id = tes3mp.GetSkillId("Restoration")
        tes3mp.SetSkillBase(pid, skill_id, 0)
        tes3mp.SendSkills(pid)

        tes3mp.MessageBox(pid, -1, "Your Restoration has been set to 0.")
    end,
    on_corpse_disposed = function(pid)
        local currentHealth = tes3mp.GetHealthCurrent(pid)
        local baseHealth = tes3mp.GetHealthBase(pid)
        local healthMissing = baseHealth - currentHealth
        local toHeal = math.min(math.floor(baseHealth / 2), healthMissing)

        if toHeal > 0 then
            tes3mp.SetHealthCurrent(pid, currentHealth + toHeal)
            tes3mp.SendStatsDynamic(pid)
        end

        logicHandler.RunConsoleCommandOnPlayer(pid, "PlaySound3D, Swallow", true)
        logicHandler.RunConsoleCommandOnPlayer(pid, "PlaySound3D, WolfHit"..math.random(3), true)
    end
}, {
    id = "gifted", 
    name = "Gifted", 
    description = "You restore 1 Magicka per second.\nYour Magicka can never exceed 30.",
    slow_think = function(pid)
        local currentMagicka = tes3mp.GetMagickaCurrent(pid)

        if currentMagicka > 30 then
            tes3mp.SetMagickaCurrent(pid, 30)
            tes3mp.SetMagickaBase(pid, 30)
            tes3mp.SendStatsDynamic(pid)
        end
    end
}, {
    id = "quiver", 
    name = "Infinite Quiver", 
    description = "You always have 5 Iron Arrows and Bolts.\nEach one has 0 value and 1 weight.",
    global = "krl_atr_quiver",
    slow_think = function(pid)
        local arrowIds = {"krl_infinite_arrow", "krl_infinite_bolt"}

        for _, itemId in pairs(arrowIds) do
            local items = KRL_GetPlayerItem(pid, itemId)
            local itemCount = (items and items.count) or 0

            if itemCount < 5 then
                KRL_GivePlayerItem(pid, itemId, 1)
            end
        end
    end
}, {
    id = "minmax", 
    name = "Minmax", 
    description = "All Major skills get +3.\nAll Minor skills get -3.\nAll other skills get set to 0.",
    on_give = function(pid)
        KRL_MinmaxSkills(pid)
        tes3mp.MessageBox(pid, -1, "Your skills have been adjusted.")
    end
}, {
    id = "randomized", 
    name = "Randomized", 
    description = "Your skills and attributes will be randomly re-arranged.\nHowever, you will get +5 to all skills and attributes.\n\nDue to technical limitations, you must re-join after selecting this.",
    on_give = function(pid)
        KRL_RandomizeSkills(pid)
        tes3mp.MessageBox(pid, -1, "Your skills have been randomized. Please re-join.")
        tes3mp.Kick(pid)
    end
}, {
    id = "small", 
    name = "Small", 
    description = "Makes you small.",
    on_connect = function(pid)
        local player = KRL_GetPlayer(pid)
        player:SetScale(0.75)
    end,
    on_give = function(pid)
        local player = KRL_GetPlayer(pid)
        player:SetScale(0.75)
    end
}, {
    id = "succubus", 
    name = "Succubus", 
    description = "Grants the seduce option in dialogue. Which increases an NPCs disposition towards you by +35.\n\nUsing this ability inflicts Love Sickness which decreases your Personality by 15. Love Sickness is cured when you reach the Inn.\n\nYou cannot use the seduce ability if you have Love Sickness.",
    global = "krl_atr_succubus",
    on_connect = function(pid)
        tes3mp.AddTopic(pid, "seduce")
        tes3mp.SendTopicChanges(pid)

        local spells = Players[pid].data.spellbook or {}

        KRL_LogTable(spells)

        if krl_array(spells).has("krl_love_sick") then
            logicHandler.RunConsoleCommandOnPlayer(pid, "Set krl_lovesick to 1", false)
        end
    end,
    on_inn_entered = function(pid)
        logicHandler.RunConsoleCommandOnPlayer(pid, "Set krl_lovesick to 0", false)
        logicHandler.RunConsoleCommandOnPlayer(pid, "RemoveSpell, krl_love_sick", false)

        tes3mp.ClearSpellbookChanges(pid)
        tes3mp.SetSpellbookChangesAction(pid, enumerations.spellbook.REMOVE)
        tes3mp.AddSpell(pid, "krl_love_sick")
        tes3mp.SendSpellbookChanges(pid)
    end,
    on_give = function(pid)
        tes3mp.AddTopic(pid, "seduce")
        tes3mp.SendTopicChanges(pid)
    end
}, {
    id = "wacky", 
    name = "Wacky World", 
    description = "Strange things can happen in Vvardenfell.",
    global = "krl_wacky",
    on_connect = function(pid)
        tes3mp.AddTopic(pid, "buy corn")
        tes3mp.AddTopic(pid, "my nuts hang")
        tes3mp.SendTopicChanges(pid)
    end,
    on_give = function(pid)
        tes3mp.AddTopic(pid, "buy corn")
        tes3mp.AddTopic(pid, "my nuts hang")
        tes3mp.SendTopicChanges(pid)
    end
}}

function KRL_GetAttributeData(id)
    return krl_array(attributes).find(function(attribute)
        return attribute.id == id
    end)
end

function KRL_SelectAttribute(pid)
    KRL_SelectAttributeGUI(pid)
end

function KRL_GetAttributes(pid)
    return Players[pid].data.customVariables.attributes or {}
end

function KRL_HasAttribute(pid, attribute_id)
    local attributes = KRL_GetAttributes(pid)
    return krl_array(attributes).has(attribute_id)
end

function KRL_AddAttribute(pid, attribute_id)
    if KRL_HasAttribute(pid, attribute_id) then return end

    if not Players[pid].data.customVariables.attributes then
        Players[pid].data.customVariables.attributes = {}
    end

    table.insert(Players[pid].data.customVariables.attributes, attribute_id)

    local attribute = KRL_GetAttributeData(attribute_id)

    logicHandler.RunConsoleCommandOnPlayer(pid, "AddSpell, krl_atrg_"..tostring(attribute.id), false)

    if attribute.global then
        logicHandler.RunConsoleCommandOnPlayer(pid, "Set "..attribute.global.." to 1", false)
    end

    if attribute.on_give then
        attribute.on_give(pid)
    end
end

customEventHooks.registerHandler("OnPlayerAuthentified", function(_, pid)
    if not KRL_IsPlayerValid(pid) then return end

    local attributes = KRL_GetAttributes(pid)

    for _, attribute_id in pairs(attributes) do
        local attribute = KRL_GetAttributeData(attribute_id)

        if attribute.global then
            logicHandler.RunConsoleCommandOnPlayer(pid, "Set "..attribute.global.." to 1", false)
        end

        if attribute.on_connect then
            attribute.on_connect(pid)
        end
    end
end)

function KRL_AttributesSlowThink()
    for _, player in pairs(Players) do
        local pid = player.pid

        if KRL_IsPlayerValid(pid) then
            local attribute_ids = KRL_GetAttributes(pid)

            for _, attribute_id in pairs(attribute_ids) do
                local attribute = KRL_GetAttributeData(attribute_id)

                if attribute.slow_think then
                    attribute.slow_think(pid)
                end
            end
        end
    end
end

local attributeGuid = 19208001
local attributeInfoGuid = 19208002

function KRL_SelectAttributeGUI(pid)
    local attribute_names = krl_array(attributes).map(function(attribute)
        return attribute.name
    end)

    local attributes_string = krl_array(attribute_names).join(";")
    attributes_string = attributes_string..";Cancel"

    tes3mp.CustomMessageBox(
        pid, 
        attributeGuid, 
        "Each character may select one trait. Traits provide special abilities or bonuses but often come with downsides.\n\nSelect a trait below to learn more about it.", 
        attributes_string
    )
end

local desired_attributes_map = {}

customEventHooks.registerValidator("OnGUIAction", function(eventStatus, pid, guiId, data)
    if not KRL_IsPlayerValid(pid) then return end
    if guiId ~= attributeGuid then return end

    local selection = tonumber(data)
    local selected_attribute_index = selection + 1

    if selected_attribute_index > #attributes then return end

    local selected_attribute = attributes[selected_attribute_index]

    desired_attributes_map[pid] = selected_attribute_index

    tes3mp.CustomMessageBox(
        pid, 
        attributeInfoGuid, 
        "- "..selected_attribute.name.." -\n\n"..selected_attribute.description, 
        "Select;Back;"
    )
end)

customEventHooks.registerValidator("OnGUIAction", function(eventStatus, pid, guiId, data)
    if not KRL_IsPlayerValid(pid) then return end
    if guiId ~= attributeInfoGuid then return end

    local selection = tonumber(data)

    if selection == 1 then
        KRL_SelectAttributeGUI(pid)
        return
    end

    local desired_attribute_index = desired_attributes_map[pid]
    local current_attributes = KRL_GetAttributes(pid)

    if #current_attributes > 0 then
        tes3mp.MessageBox(pid, -1, "You already have an attribute.")
        return
    end

    local desired_attribute = attributes[desired_attribute_index]

    KRL_AddAttribute(pid, desired_attribute.id)

    tes3mp.MessageBox(pid, -1, "You have selected the "..desired_attribute.name.." attribute.")
end)

customEventHooks.registerValidator("OnObjectActivate", function(_, pid, cellName, objects)
    for _, object in pairs(objects) do
        local refId = object.refId
        Players[pid].data.customVariables.lastActivatedRefId = refId
    end
end)

customEventHooks.registerValidator("OnObjectDelete", function(_, pid, cellName, objects)
    for objectIndex, object in pairs(objects) do
        local refId = object.refId
        local objectData = LoadedCells[cellName].data.objectData or {}
        local item = objectData[objectIndex]

        if item and item.deathState and (item.deathState > 0) then
            for pid, player in pairs(Players) do
                if KRL_IsPlayerValid(pid) then
                    if player.data.customVariables.lastActivatedRefId == refId then
                        local attributes = KRL_GetAttributes(pid)

                        for _, attribute_id in pairs(attributes) do
                            local attribute = KRL_GetAttributeData(attribute_id)

                            if attribute.on_corpse_disposed then
                                attribute.on_corpse_disposed(pid)
                            end
                        end
                    end
                end
            end
        end
    end
end)
