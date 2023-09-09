local config = require("tew.avni.config")
local util = require("tew.avni.util")
local metadata = toml.loadMetadata("Avni the Ash-hound")

local debugLogOn = config.debugLogOn

local UICreated = 0

local function debugLog(string)
    if debugLogOn then
       mwse.log("[" .. metadata.package.name .. " " .. metadata.package.version or "" .. "] "..string.format("%s", string))
    end
end

local function isAvniDead()
    -- Snatched from Guar Whisperer
    local ref = tes3.getReference("tew_avni")
    if not ref then return false end
    if not ref.mobile then return false end
    local animState = ref.mobile.actionData.animationAttackState
    local isDead = (
        ref.mobile.health.current <= 0 or
        animState == tes3.animationState.dying or
        animState == tes3.animationState.dead
    )
    return isDead
end

local function summonAvni()
    -- Snatched from Guar Whisperer
    debugLog("Starting teleport function.")
    tes3.playSound{
        soundPath = "Vo\\tew\\avni\\tew_avnisummon.mp3",
        reference = tes3.getReference("tew_avni")
    }
    local ref = tes3.getReference("tew_avni")
    local distance = 500
    local isForward = distance >= 0
    local target = tes3.player

    --do a raytest to avoid teleporting into stuff
    local oldCulledValue = target.sceneNode.appCulled
    target.sceneNode.appCulled = true
    local rayResult = tes3.rayTest{
        position = target.position,
        direction = target.sceneNode.rotation:transpose().y * (isForward and 1 or -1),
        maxDistance = math.abs(distance),
        ignore = {target, ref}
    }
    target.sceneNode.appCulled = oldCulledValue

    if rayResult and rayResult.intersection then
        local intersectionDistance = tes3.player.position:distance(rayResult.intersection)
        distance = math.max(0, intersectionDistance - 50) * (isForward and 1 or -1)
    end

    local newPosition = tes3vector3.new(
        target.position.x + ( distance * math.sin(target.orientation.z)),
        target.position.y + ( distance * math.cos(target.orientation.z)),
        target.position.z
    )
    tes3.positionCell{
        reference = ref,
        position = newPosition,
        cell = target.cell
    }
    ref.sceneNode:update()
    ref.sceneNode:updateNodeEffects()
    debugLog("Avni teleported to player.")
end

local function getData()
    debugLog("Getting data.")
    tes3.player.data.Avni = tes3.player.data.Avni or
    {
        fed = 0,
        trust = 0,
        NPCdisabled = false
    }
    timer.start{
        duration = 12,
        type = timer.game,
        iterations = -1,
        callback = function()
            debugLog("Resetting fed values.")
            if tes3.player.data.Avni and tes3.player.data.Avni.fed and tes3.player.data.Avni.fed ~= 0 then
                tes3.player.data.Avni.fed = 0
                debugLog("Fed values reset.")
            end
            if tes3.player.data.Avni.NPCdisabled == false and tes3.getJournalIndex{id = "tew_Avni"} == 100 then
                tes3.setEnabled{
                    reference = tes3.getReference("tew_ulveni_sudras"),
                    toggle = true
                }
                tes3.player.data.Avni.NPCdisabled = true
            end
        end
    }
end

local function showTooltip(text)
    local useColors = config.useColors
    local thisLabel = text
    local tooltip = tes3ui.createTooltipMenu()

    local outerBlock = tooltip:createBlock({ id = tes3ui.registerID("tew_AvniTooltip_outerBlock") })
    outerBlock.flowDirection = "top_to_bottom"
    outerBlock.paddingTop = 6
    outerBlock.paddingBottom = 6
    outerBlock.paddingLeft = 6
    outerBlock.paddingRight = 6
    --outerBlock.maxWidth = 300
    outerBlock.autoWidth = true
    outerBlock.autoHeight = true

    if thisLabel then
        local descriptionText = thisLabel
        local descriptionLabel = outerBlock:createLabel({ id = tes3ui.registerID("tew_AvniTooltip_description"), text = descriptionText })
        descriptionLabel.autoHeight = true
        descriptionLabel.autoWidth = true
        descriptionLabel.wrapText = true
        if useColors then
            descriptionLabel.color = tes3ui.getPalette("notify_color")
        end
    end

    tooltip:updateLayout()
end

local nixFood = {
    ["food_kwama_egg_01"] = 1.3,
    ["food_kwama_egg_02"] = 1.2,
    ["ingred_bonemeal_01"] = 0.2,
    ["ingred_crab_meat_01"] = 0.6,
    ["ingred_kwama_cuttle_01"] = 1.5,
    ["ingred_rat_meat_01"] = 0.5,
    ["ingred_scrib_jelly_01"] = 1.2,
    ["ingred_scrib_jerky_01"] = 2.0,
    ["ingred_scuttle_01"] = 1,
    ["ingred_scales_01"] = 0.5,
    ["T_IngFood_MeatCliffracer_01"] = 1,
    ["T_IngFood_MeatGuar_01"] = 1,
    ["T_IngFood_MeatKwama_01"] = 1.5,
    ["T_IngFood_MeatOrnada_01"] = 1.4,
    ["T_IngFood_MeatParastylus_01"] = 0.8,
    ["T_IngFood_MeatRat_01"] = 0.5,
}

-- showInventorySelectMenu works weird so we don't really need this for now
--[[local function isNixFood(e)
    debugLog("Checking if the food is nix-friendly.")
    for food, _ in pairs(nixFood) do
        if e.item.id:lower() == food then return true end
    end
end]]

local function hasNixFood()
    debugLog("Checking if the player has any nix-friendly food.")
    for _, itemStack in pairs(tes3.player.mobile.object.inventory.iterator) do
        if tes3.objectType.ingredient and nixFood[itemStack.object.id] then
            return true
        end
    end
end

local function showFeedMenu()
    tes3ui.showInventorySelectMenu{
        leaveMenuMode = true,
        title = "Feed Avni",
        noResultsText = string.format("I do not have any nix-hound food."),
        filter = function(e)
            return (e.item.objectType == tes3.objectType.ingredient and nixFood[e.item.id]~= nil and nixFood[e.item.id] ~= false)
            end,
        callback = function(e)
            if e.item then
                tes3.player.object.inventory:removeItem{
                    mobile = tes3.mobilePlayer,
                    item = e.item,
                    itemData = e.itemData
                }

                local multiplier = nixFood[e.item.id] or 1

                if multiplier <1 then tes3.messageBox("Avni doesn't seem to be excessively keen on "..e.item.name:lower().."...")
                elseif multiplier >= 1 and multiplier < 1.5 then tes3.messageBox("Avni is happily devouring "..e.item.name:lower()..".")
                elseif multiplier >= 1.5 then tes3.messageBox("Avni sure loves "..e.item.name:lower().."!") end

                debugLog("Fed level before: "..tes3.player.data.Avni.fed)
                debugLog("Trust level before: "..tes3.player.data.Avni.trust)
                tes3.player.data.Avni.fed = tes3.player.data.Avni.fed + multiplier
                if tes3.player.data.Avni.trust <= 50 then
                    tes3.player.data.Avni.trust = (tes3.player.data.Avni.trust + (tes3.player.data.Avni.fed*0.9))
                end

                tes3.playSound{
                    soundPath = "Vo\\tew\\avni\\tew_avnieating.mp3",
                    reference = tes3.getReference("tew_avni")
                }

                debugLog("Avni fed.")
                debugLog("Fed level after: "..tes3.player.data.Avni.fed)
                debugLog("Trust level after: "..tes3.player.data.Avni.trust)

                tes3ui.forcePlayerInventoryUpdate()
                tes3ui.leaveMenuMode()
            end
        end
    }
end


local function showUI(e)

    if e.activator == tes3.player
    and not isAvniDead()
    and string.startswith(e.target.id, "tew_avni")
    and tes3.getJournalIndex{id = "tew_Avni"} == 100 then

        if UICreated == 0 then
            local useColors = config.useColors

            local messageBoxId = tes3ui.registerID("tew_AvniMenu_Box")
            local menuAvni = tes3ui.createMenu{ id = messageBoxId, fixedFrame = true }
            menuAvni:getContentElement().childAlignX = 0.5
            tes3ui.enterMenuMode(messageBoxId)
            --[[local title = menuAvni:createLabel{id = tes3ui.registerID("tew_AvniMenu_Main"), text = "Avni the Ash-hound"}
            title.color = tes3ui.getPalette("misc_color")]]

            local buttonsBlock = menuAvni:createBlock()
            buttonsBlock.borderTop = 4
            buttonsBlock.autoHeight = true
            buttonsBlock.autoWidth = true
            buttonsBlock.flowDirection = "top_to_bottom"
            buttonsBlock.childAlignX = 0.5

            local followButtonId = tes3ui.registerID("tew_AvniMenu_ButtonFollow")
            local followButton = buttonsBlock:createButton{id = followButtonId, text = "Follow me"}
            if useColors then
                followButton.widget.state = 4
                followButton.widget.idleActive = tes3ui.getPalette("magic_color")
            end
            if tes3.player.data.Avni.trust >= 10 then

                followButton:register( "help", function()
                    showTooltip("Let Avni follow me around.")
                end)
                followButton:register( "mouseClick", function()
                    tes3.setAIFollow{
                        reference = e.target,
                        target = e.activator
                    }
                    tes3ui.leaveMenuMode()
                    menuAvni:destroy()
                    tes3.playSound{
                        soundPath = "Vo\\tew\\avni\\tew_avnifollowing.mp3",
                        reference = tes3.getReference("tew_avni")
                        }
                    UICreated = 0
                    end)
            else
                followButton.widget.state = 2
                followButton:register( "help", function()
                    showTooltip("Avni doesn't trust me enough to follow me around.")
                end)
            end

            --
            local stayButtonId = tes3ui.registerID("tew_AvniMenu_ButtonStay")
            local stayButton = buttonsBlock:createButton{ id = stayButtonId, text = "Stay put"}
            if useColors then
                stayButton.widget.idleActive = {0.6, 1.0, 0.5}
                stayButton.widget.state = 4
            end
            if tes3.player.data.Avni.trust >= 20 then
                stayButton:register( "help", function()
                    showTooltip("Let Avni stay where she is.")
                end)
                stayButton:register( "mouseClick", function()
                    tes3.setAIWander{
                        reference = e.target,
                        idles = {50, 50, 0, 0, 0, 0, 0, 0},
                        range = 0,
                    }
                    tes3ui.leaveMenuMode()
                    menuAvni:destroy()
                    tes3.playSound{
                    soundPath = "Vo\\tew\\avni\\tew_avnisitting.mp3",
                    reference = tes3.getReference("tew_avni")
                    }
                    UICreated = 0
                end)
            else
                stayButton.widget.state = 2
                stayButton:register( "help", function()
                    showTooltip("Avni doesn't trust me enough to stay put.")
                end)
            end

            --
            local restButtonID = tes3ui.registerID("tew_AvniMenu_ButtonRest")
            local restButton = buttonsBlock:createButton{ id = restButtonID, text = "Stay in this area"}
            if useColors then
                restButton.widget.idleActive = {1.0, 1.0, 0.0}
                restButton.widget.state = 4
            end
            if tes3.player.data.Avni.trust >= 30 then
                restButton:register( "help", function()
                    showTooltip("Let Avni make herself comfortable in this area.")
                end)
                restButton:register( "mouseClick", function()
                    tes3.setAIWander{
                        reference = e.target,
                        idles = {50, 50, 0, 0, 0, 0, 0, 0},
                        range = 300,
                    }
                    tes3ui.leaveMenuMode()
                    menuAvni:destroy()
                    tes3.playSound{
                        soundPath = "Vo\\tew\\avni\\tew_avniarea.mp3",
                        reference = tes3.getReference("tew_avni")
                    }
                    UICreated = 0
                end)
            else
                restButton.widget.state = 2
                restButton:register( "help", function()
                    showTooltip("Avni doesn't trust me enough to stay in this area.")
                end)
            end


            --
            local wanderButtonID = tes3ui.registerID("tew_AvniMenu_ButtonWander")
            local wanderButton = buttonsBlock:createButton{ id = wanderButtonID, text = "Go wander around"}
            if useColors then
                wanderButton.widget.idleActive = {0.9, 0.3, 0.5}
                wanderButton.widget.state = 4
            end
            if tes3.player.data.Avni.trust >= 40 then
                wanderButton:register( "help", function()
                    showTooltip("Let Avni explore her surroundings.")
                end)
                wanderButton:register( "mouseClick", function()
                    tes3.setAIWander{
                        reference = e.target,
                        idles = {50, 50, 0, 0, 0, 0, 0, 0},
                        range = 2000,
                    }
                    tes3ui.leaveMenuMode()
                    menuAvni:destroy()
                    tes3.playSound{
                        soundPath = "Vo\\tew\\avni\\tew_avniexplore.mp3",
                        reference = tes3.getReference("tew_avni")
                    }
                    UICreated = 0
                end)
            else
                wanderButton.widget.state = 2
                wanderButton:register( "help", function()
                    showTooltip("Avni doesn't trust me enough to wander around.")
                end)
            end

            --
            local feedButtonID = tes3ui.registerID("tew_AvniMenu_ButtonFeed")
            local feedButton = buttonsBlock:createButton{ id = feedButtonID, text = "Feed Avni"}
            if useColors then
                feedButton.widget.idleActive = tes3ui.getPalette("fatigue_color")
                feedButton.widget.state = 4
            end

            if (hasNixFood()) ~= true then
                feedButton.widget.state = 2
                feedButton:register( "help", function()
                    showTooltip("I don't have any nix-hound food.")
                end)
            elseif tes3.player.data.Avni.fed <= 5 then
                feedButton:register( "help", function()
                    showTooltip("Give Avni something to chew on.")
                end)
                feedButton:register( "mouseClick", function()
                    UICreated = 0
                    menuAvni:destroy()
                    tes3ui.leaveMenuMode()
                    showFeedMenu()
               end)
            elseif tes3.player.data.Avni.fed > 5 then
                feedButton.widget.state = 2
                feedButton:register( "help", function()
                    showTooltip("Avni is full. I can try again tomorrow!")
                end)
            end

            --
            local cancelButtonId = tes3ui.registerID("tew_AvniMenu_ButtonCancel")
            local cancelButton = buttonsBlock:createButton{ id = cancelButtonId, text = "Nevermind"}
            if useColors then
                cancelButton.widget.idleActive = {0.9, 0.7, 1.0}
                cancelButton.widget.state = 4
            end
            cancelButton:register( "help", function()
                showTooltip("Let Avni do whatever she was doing before.")
            end)
            cancelButton:register( "mouseClick", function()
                tes3ui.leaveMenuMode()
                menuAvni:destroy()
                UICreated = 0
            end)

            menuAvni:updateLayout()
        end
        UICreated = 1
    end

end

local function teleportMenu(e)
    if UICreated == 0 and
    e.keyCode == config.summonKey.keyCode and (not tes3.menuMode()) and (not isAvniDead())
    and tes3.getJournalIndex{id = "tew_Avni"} == 100 then
        local useColors = config.useColors
        local messageBoxId = tes3ui.registerID("tew_AvniTelMenu_Box")
        local menuAvniTel = tes3ui.createMenu{ id = messageBoxId, fixedFrame = true }
        menuAvniTel:getContentElement().childAlignX = 0.5
        tes3ui.enterMenuMode(messageBoxId)
        local buttonsBlock = menuAvniTel:createBlock()
        buttonsBlock.borderTop = 4
        buttonsBlock.autoHeight = true
        buttonsBlock.autoWidth = true
        buttonsBlock.flowDirection = "top_to_bottom"
        buttonsBlock.childAlignX = 0.5

        local summonButtonID = tes3ui.registerID("tew_AvniTelMenu_ButtonSummon")
        local summonButton = buttonsBlock:createButton{id = summonButtonID, text = "Summon Avni?"}
        if useColors then
            summonButton.widget.state = 4
            summonButton.widget.idleActive = tes3ui.getPalette("magic_color")
        end

        summonButton:register( "mouseClick", function()
            summonAvni()
            tes3ui.leaveMenuMode()
            menuAvniTel:destroy()
            UICreated = 0
        end)

        local cancelButtonId = tes3ui.registerID("tew_AvniTelMenu_ButtonCancel")
        local cancelButton = buttonsBlock:createButton{ id = cancelButtonId, text = "Nevermind"}
        if useColors then
            cancelButton.widget.idleActive = {0.9, 0.7, 1.0}
            cancelButton.widget.state = 4
        end
        cancelButton:register( "mouseClick", function()
            tes3ui.leaveMenuMode()
            menuAvniTel:destroy()
            UICreated = 0
        end)

        menuAvniTel:updateLayout()
    end

end

local function init()
    if not (metadata) then
		util.metadataMissing()
	end
    debugLog("Mod initialised.")
    event.register("activate", showUI)
    event.register("loaded", getData)
    event.register("key", teleportMenu)

    -- Custom Icon for Skyrim Style Quest Notifications
    local ssqn = include("SSQN.interop")
    if (ssqn)  then
        ssqn.registerQIcon("tew_Avni","\\Icons\\tew\\avni\\quest_avni.tga")
    end
end

event.register("initialized", init)

event.register("modConfigReady", function()
    dofile("Data Files\\MWSE\\mods\\tew\\avni\\mcm.lua")
end)
