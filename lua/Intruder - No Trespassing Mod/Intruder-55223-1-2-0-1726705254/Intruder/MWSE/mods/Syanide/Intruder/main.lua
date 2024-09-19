local config = require("Syanide.Intruder.config")  -- Variable to store the timer
local detectedActors = {}  -- Table to store actors that have seen the player
local cellKeywords = { 
    "House", 
    "Shack", 
    "Trader",
    "Armorer",
    "Pawnbroker",
    "Tailor",
    "Outfitter",
    "Bookseller",
    "Manor",
    "Clothier",
    "The Razor Hole",
    "Alchemist",
    "Smith",
    "Enchanter",
    "Quarters",
    "Bedrooms",
    "General Merchandise",
    "Apothecary",
    "General Goods",
    "Weaponsmith",
    "Healer",
    "Books",
    "St. Delyn Canal ",
    "St. Delyn Waist ",
    "St. Olms Canal ",
    "St. Olms Waist ",
    "Sorcerer",
    "Llaalam Madalas: Mage",
    "Monk",
    "Hut",
    "Enchantress",
    "Baker",
    "Ales",
    "Taxidermist",
    "Residence",
    "Barracks",
    "Housing",
    "Narion the Contained",
    "Tat Shop",
    "Apparel",
    "Bank",
    "Jeweller",
    "Dressing Room",
    "Telvanni Mage",
    "Warehouse",
    "Storage",
    "Dwelling",
    "Chamber",
    "Tower",
    "Tent",
    "Pod",
    "Basement",
    "Farmhouse",
    "Dren Plantation,",
    "Salvage",
    "Gro-Bagrat Plantation",
    "Arano Plantation",
    "The Bug's Breath",
    "Arvel Plantation",
    "Estate",
    "Yurt"  -- Add "Yurt" to the list
}

local function isClanfriend()
    -- Get the Ashlander faction
    local ashlanderFaction = tes3.getFaction("Ashlanders")
    if ashlanderFaction then
        -- Retrieve the player's rank in the Ashlander faction
        local playerRank = ashlanderFaction.playerRank  -- Directly get the player's rank in this faction
        -- Check if player rank is "Clanfriend"
        if playerRank and playerRank >= 0 then
            return true
        end
    end
    return false
end

-- Function to check if playerCell.id matches any keyword in the table
local function isMatchingCell(playerCellId)
    for _, keyword in ipairs(cellKeywords) do
        -- If the keyword is "Yurt" and the player is a Clanfriend, skip it
        if keyword == "Yurt" and isClanfriend() then
            return
        elseif playerCellId:find(keyword) then
            return true
        end
    end
    return false
end

local function decreaseDisposition(actor)
    -- Modify the actor's disposition within the disposition event
    event.register(tes3.event.disposition, function(e)
        if e.reference == actor then
            e.disposition = e.disposition - config.dispositionDecrease
            -- Ensure disposition is not below 0
            if e.disposition < 0 then
                e.disposition = 0
            end
        end
    end)
end

local function onShowRestMenu(e)
    local currentTime = tes3.worldController.hour.value
    if config.noWait then
        local playerCell = tes3.getPlayerCell()
        if config.blacklist[playerCell.id] then
            return
        elseif isMatchingCell(playerCell.id) and (currentTime >= config.startTrespass or currentTime <= config.endTrespass) then
            tes3.messageBox({ message = "You cannot wait or rest while trespassing." })
            -- Prevent the rest menu from showing
            e.block = true
        end
    end
end

local function onCellChanged(e)
    local playerCell = e.cell.id
    -- Cancel any active timer
    for actor, actorInfo in pairs(detectedActors) do
        if actorInfo.timer and not actorInfo.timer.expired then
            actorInfo.timer:cancel()
        end
    end

    for actor, actorInfo in pairs(detectedActors) do
        if actor and actor.mobile then
            if actor.mobile.inCombat then
                -- Log the actor ID and stop combat
                actor.mobile:stopCombat(true) -- Use `true` to forcefully stop combat
            end
        end
    end
    -- Clear detection table when leaving the cell
    detectedActors = {}
end

local function detectSneak(e)
    local playerCell = tes3.getPlayerCell()
    local currentTime = tes3.worldController.hour.value
    local playerLevel = tes3.player.object.level

    -- Check if the player is in a house or shack at night
    if config.blacklist[playerCell.id] then
        return
    elseif isMatchingCell(playerCell.id) and (currentTime >= config.startTrespass or currentTime <= config.endTrespass) then
        -- Find NPCs near the player
        local mobileList = tes3.findActorsInProximity{ reference = tes3.player, range = 512 }

        for _, mobile in ipairs(mobileList) do
            local actor = mobile.reference

            -- Skip the player and followers
            if actor ~= tes3.player then
                if tes3.testLineOfSight({ reference1 = actor, reference2 = tes3.player }) or (detectedActors[actor] and detectedActors[actor].detected) then
                    
                    -- Skip guards
                    if actor.object.objectType == tes3.objectType.npc and actor.object.isGuard or config.blacklistNpc[actor.object.name] then
                        return
                    else
                        local disposition = actor.object.disposition  -- Get the NPC's base disposition
                        local actorLevel = actor.object.level

                        -- Proceed only if the actor's disposition is less than config.disposition (e.g., 90) 
                        if disposition and disposition >= config.disposition and config.dispOn then
                            return  -- Skip if disposition is too high
                        else
                            if actor and actor.object and actor.object.objectType == tes3.objectType.npc and actor ~= tes3.player then
                                local race = actor.object.race
                                if race and race.id == "Dark Elf" and actor.object.female then
                                    -- If not already detected, mark the actor as having detected the player
                                    if not detectedActors[actor] then
                                        detectedActors[actor] = {
                                            detected = true,
                                            actionTriggered = false,  -- Flag to ensure actions are triggered only once
                                            timer = nil
                                        }
                                    end

                                    local actorInfo = detectedActors[actor]

                                    -- Trigger actions only if they haven't been triggered yet
                                    if not actorInfo.actionTriggered then
                                        actorInfo.actionTriggered = true

                                        tes3.say({ reference = actor, soundPath = "Vo\\d\\f\\Hlo_DF000e.mp3", subtitle = "Get out of here!" })
                                        if config.messagesOn then
                                            tes3.messageBox({ message = actor.object.name .. " asks you to leave." })
                                        end

                                        -- Start the timer and store it in the activeTimer variable
                                        actorInfo.timer = timer.start{
                                            duration = config.timerSeconds,
                                            callback = function()
                                                tes3.triggerCrime({ type = tes3.crimeType.trespass, forceDetection = false })
                                                if config.messagesOn then
                                                    tes3.messageBox({ message = actor.object.name .. " considers you a trespasser." })
                                                end
                                                tes3.say({ reference = actor, soundPath = "Vo\\d\\f\\Hlo_DF027.mp3", subtitle = "Filthy S'wit!" })

                                                if config.decreaseDisposition then
                                                    decreaseDisposition(actor)
                                                end
                                                
                                                if config.combat then
                                                    if config.playerLevel then
                                                        if (actorLevel >= playerLevel) then
                                                            actor.mobile:startCombat(tes3.mobilePlayer)
                                                        else
                                                            if (playerLevel - actorLevel) <= config.level then
                                                                actor.mobile:startCombat(tes3.mobilePlayer)
                                                            end
                                                        end
                                                    else
                                                        actor.mobile:startCombat(tes3.mobilePlayer)
                                                    end
                                                end
                                            end
                                        }
                                    end
                                elseif race and race.id == "Dark Elf"then -- Male Dark Elf
                                    -- If not already detected, mark the actor as having detected the player
                                    if not detectedActors[actor] then
                                        detectedActors[actor] = {
                                            detected = true,
                                            actionTriggered = false,  -- Flag to ensure actions are triggered only once
                                            timer = nil
                                        }
                                    end

                                    local actorInfo = detectedActors[actor]

                                    -- Trigger actions only if they haven't been triggered yet
                                    if not actorInfo.actionTriggered then
                                        actorInfo.actionTriggered = true

                                        tes3.say({ reference = actor, soundPath = "Vo\\ord\\Int_ORM002.mp3", subtitle = "What are you doing? Get out!" })
                                        if config.messagesOn then
                                            tes3.messageBox({ message = actor.object.name .. " asks you to leave." })
                                        end

                                        -- Start the timer and store it in the activeTimer variable
                                        actorInfo.timer = timer.start{
                                            duration = config.timerSeconds,
                                            callback = function()
                                                tes3.triggerCrime({ type = tes3.crimeType.trespass, forceDetection = false })
                                                if config.messagesOn then
                                                    tes3.messageBox({ message = actor.object.name .. " considers you a trespasser." })
                                                end
                                                tes3.say({ reference = actor, soundPath = "Vo\\ord\\Int_ORM001.mp3", subtitle = "Intruder!" })

                                                if config.decreaseDisposition then
                                                    decreaseDisposition(actor)
                                                end
                                                
                                                if config.combat then
                                                    if config.playerLevel then
                                                        if (actorLevel >= playerLevel) then
                                                            actor.mobile:startCombat(tes3.mobilePlayer)
                                                        else
                                                            if (playerLevel - actorLevel) <= config.level then
                                                                actor.mobile:startCombat(tes3.mobilePlayer)
                                                            end
                                                        end
                                                    else
                                                        actor.mobile:startCombat(tes3.mobilePlayer)
                                                    end
                                                end
                                            end
                                        }
                                    end
                                elseif race and race.id == "Argonian" and actor.object.female then
                                    -- If not already detected, mark the actor as having detected the player
                                    if not detectedActors[actor] then
                                        detectedActors[actor] = {
                                            detected = true,
                                            actionTriggered = false,  -- Flag to ensure actions are triggered only once
                                            timer = nil
                                        }
                                    end

                                    local actorInfo = detectedActors[actor]

                                    -- Trigger actions only if they haven't been triggered yet
                                    if not actorInfo.actionTriggered then
                                        actorInfo.actionTriggered = true

                                        tes3.say({ reference = actor, soundPath = "Vo\\a\\f\\Hlo_AF000e.mp3", subtitle = "Get out of here!" })
                                        if config.messagesOn then
                                            tes3.messageBox({ message = actor.object.name .. " asks you to leave." })
                                        end

                                        -- Start the timer and store it in the activeTimer variable
                                        actorInfo.timer = timer.start{
                                            duration = config.timerSeconds,
                                            callback = function()
                                                tes3.triggerCrime({ type = tes3.crimeType.trespass, forceDetection = false })
                                                if config.messagesOn then
                                                    tes3.messageBox({ message = actor.object.name .. " considers you a trespasser." })
                                                end
                                                tes3.say({ reference = actor, soundPath = "Vo\\a\\f\\Thr_AF004.mp3", subtitle = "Hiss!" })

                                                if config.decreaseDisposition then
                                                    decreaseDisposition(actor)
                                                end
                                                
                                                if config.combat then
                                                    if config.playerLevel then
                                                        if (actorLevel >= playerLevel) then
                                                            actor.mobile:startCombat(tes3.mobilePlayer)
                                                        else
                                                            if (playerLevel - actorLevel) <= config.level then
                                                                actor.mobile:startCombat(tes3.mobilePlayer)
                                                            end
                                                        end
                                                    else
                                                        actor.mobile:startCombat(tes3.mobilePlayer)
                                                    end
                                                end
                                            end
                                        }
                                    end
                                elseif race and race.id == "Argonian"then
                                    -- If not already detected, mark the actor as having detected the player
                                    if not detectedActors[actor] then
                                        detectedActors[actor] = {
                                            detected = true,
                                            actionTriggered = false,  -- Flag to ensure actions are triggered only once
                                            timer = nil
                                        }
                                    end

                                    local actorInfo = detectedActors[actor]

                                    -- Trigger actions only if they haven't been triggered yet
                                    if not actorInfo.actionTriggered then
                                        actorInfo.actionTriggered = true

                                        tes3.say({ reference = actor, soundPath = "Vo\\a\\m\\Srv_AM006.mp3", subtitle = "Go away!" })
                                        if config.messagesOn then
                                            tes3.messageBox({ message = actor.object.name .. " asks you to leave." })
                                        end

                                        -- Start the timer and store it in the activeTimer variable
                                        actorInfo.timer = timer.start{
                                            duration = config.timerSeconds,
                                            callback = function()
                                                tes3.triggerCrime({ type = tes3.crimeType.trespass, forceDetection = false })
                                                if config.messagesOn then
                                                    tes3.messageBox({ message = actor.object.name .. " considers you a trespasser." })
                                                end
                                                tes3.say({ reference = actor, soundPath = "Vo\\a\\m\\Hlo_AM022.mp3", subtitle = "Be gone!" })

                                                if config.decreaseDisposition then
                                                    decreaseDisposition(actor)
                                                end
                                                
                                                if config.combat then
                                                    if config.playerLevel then
                                                        if (actorLevel >= playerLevel) then
                                                            actor.mobile:startCombat(tes3.mobilePlayer)
                                                        else
                                                            if (playerLevel - actorLevel) <= config.level then
                                                                actor.mobile:startCombat(tes3.mobilePlayer)
                                                            end
                                                        end
                                                    else
                                                        actor.mobile:startCombat(tes3.mobilePlayer)
                                                    end
                                                end
                                            end
                                        }
                                    end
                                elseif (race and race.id == "Khajiit" and actor.object.female) or (race and race.id == "T_Els_Cathay" and actor.object.female) or (race and race.id == "T_Els_Cathay-raht" and actor.object.female) or (race and race.id == "T_Els_Dagi-raht" and actor.object.female) or (race and race.id == "T_Els_Ohmes" and actor.object.female) or (race and race.id == "T_Els_Ohmes-raht" and actor.object.female) or (race and race.id == "T_Els_Suthay" and actor.object.female) then
                                    -- If not already detected, mark the actor as having detected the player
                                    if not detectedActors[actor] then
                                        detectedActors[actor] = {
                                            detected = true,
                                            actionTriggered = false,  -- Flag to ensure actions are triggered only once
                                            timer = nil
                                        }
                                    end

                                    local actorInfo = detectedActors[actor]

                                    -- Trigger actions only if they haven't been triggered yet
                                    if not actorInfo.actionTriggered then
                                        actorInfo.actionTriggered = true

                                        tes3.say({ reference = actor, soundPath = "Vo\\k\\f\\Hlo_KF000e.mp3", subtitle = "Get out of here!" })
                                        if config.messagesOn then
                                            tes3.messageBox({ message = actor.object.name .. " asks you to leave." })
                                        end

                                        -- Start the timer and store it in the activeTimer variable
                                        actorInfo.timer = timer.start{
                                            duration = config.timerSeconds,
                                            callback = function()
                                                tes3.triggerCrime({ type = tes3.crimeType.trespass, forceDetection = false })
                                                if config.messagesOn then
                                                    tes3.messageBox({ message = actor.object.name .. " considers you a trespasser." })
                                                end
                                                tes3.say({ reference = actor, soundPath = "Vo\\k\\f\\Atk_KF013.mp3", subtitle = "Growl!" })

                                                if config.decreaseDisposition then
                                                    decreaseDisposition(actor)
                                                end
                                                
                                                if config.combat then
                                                    if config.playerLevel then
                                                        if (actorLevel >= playerLevel) then
                                                            actor.mobile:startCombat(tes3.mobilePlayer)
                                                        else
                                                            if (playerLevel - actorLevel) <= config.level then
                                                                actor.mobile:startCombat(tes3.mobilePlayer)
                                                            end
                                                        end
                                                    else
                                                        actor.mobile:startCombat(tes3.mobilePlayer)
                                                    end
                                                end
                                            end
                                        }
                                    end
                                elseif (race and race.id == "Khajiit") or (race and race.id == "T_Els_Cathay") or (race and race.id == "T_Els_Cathay-raht") or (race and race.id == "T_Els_Dagi-raht") or (race and race.id == "T_Els_Ohmes") or (race and race.id == "T_Els_Ohmes-raht") or (race and race.id == "T_Els_Suthay") then
                                    -- If not already detected, mark the actor as having detected the player
                                    if not detectedActors[actor] then
                                        detectedActors[actor] = {
                                            detected = true,
                                            actionTriggered = false,  -- Flag to ensure actions are triggered only once
                                            timer = nil
                                        }
                                    end

                                    local actorInfo = detectedActors[actor]

                                    -- Trigger actions only if they haven't been triggered yet
                                    if not actorInfo.actionTriggered then
                                        actorInfo.actionTriggered = true

                                        tes3.say({ reference = actor, soundPath = "Vo\\k\\m\\Hlo_KM022.mp3", subtitle = "Go away! Do not come back!" })
                                        if config.messagesOn then
                                            tes3.messageBox({ message = actor.object.name .. " asks you to leave." })
                                        end

                                        -- Start the timer and store it in the activeTimer variable
                                        actorInfo.timer = timer.start{
                                            duration = config.timerSeconds,
                                            callback = function()
                                                tes3.triggerCrime({ type = tes3.crimeType.trespass, forceDetection = false })
                                                if config.messagesOn then
                                                    tes3.messageBox({ message = actor.object.name .. " considers you a trespasser." })
                                                end
                                                tes3.say({ reference = actor, soundPath = "Vo\\k\\m\\Atk_KM007.mp3", subtitle = "Growl!" })

                                                if config.decreaseDisposition then
                                                    decreaseDisposition(actor)
                                                end
                                                
                                                if config.combat then
                                                    if config.playerLevel then
                                                        if (actorLevel >= playerLevel) then
                                                            actor.mobile:startCombat(tes3.mobilePlayer)
                                                        else
                                                            if (playerLevel - actorLevel) <= config.level then
                                                                actor.mobile:startCombat(tes3.mobilePlayer)
                                                            end
                                                        end
                                                    else
                                                        actor.mobile:startCombat(tes3.mobilePlayer)
                                                    end
                                                end
                                            end
                                        }
                                    end
                                elseif (race and race.id == "Breton" and actor.object.female) or (race and race.id == "T_Sky_Reachman" and actor.object.female) then
                                    -- If not already detected, mark the actor as having detected the player
                                    if not detectedActors[actor] then
                                        detectedActors[actor] = {
                                            detected = true,
                                            actionTriggered = false,  -- Flag to ensure actions are triggered only once
                                            timer = nil
                                        }
                                    end

                                    local actorInfo = detectedActors[actor]

                                    -- Trigger actions only if they haven't been triggered yet
                                    if not actorInfo.actionTriggered then
                                        actorInfo.actionTriggered = true

                                        tes3.say({ reference = actor, soundPath = "Vo\\b\\f\\Hlo_BF000e.mp3", subtitle = "Get out of here!" })
                                        if config.messagesOn then
                                            tes3.messageBox({ message = actor.object.name .. " asks you to leave." })
                                        end

                                        -- Start the timer and store it in the activeTimer variable
                                        actorInfo.timer = timer.start{
                                            duration = config.timerSeconds,
                                            callback = function()
                                                tes3.triggerCrime({ type = tes3.crimeType.trespass, forceDetection = false })
                                                if config.messagesOn then
                                                    tes3.messageBox({ message = actor.object.name .. " considers you a trespasser." })
                                                end
                                                tes3.say({ reference = actor, soundPath = "Vo\\b\\f\\Fle_BF005.mp3", subtitle = "Go away!" })

                                                if config.decreaseDisposition then
                                                    decreaseDisposition(actor)
                                                end
                                                
                                                if config.combat then
                                                    if config.playerLevel then
                                                        if (actorLevel >= playerLevel) then
                                                            actor.mobile:startCombat(tes3.mobilePlayer)
                                                        else
                                                            if (playerLevel - actorLevel) <= config.level then
                                                                actor.mobile:startCombat(tes3.mobilePlayer)
                                                            end
                                                        end
                                                    else
                                                        actor.mobile:startCombat(tes3.mobilePlayer)
                                                    end
                                                end
                                            end
                                        }
                                    end
                                elseif (race and race.id == "Breton") then
                                    -- If not already detected, mark the actor as having detected the player
                                    if not detectedActors[actor] then
                                        detectedActors[actor] = {
                                            detected = true,
                                            actionTriggered = false,  -- Flag to ensure actions are triggered only once
                                            timer = nil
                                        }
                                    end

                                    local actorInfo = detectedActors[actor]

                                    -- Trigger actions only if they haven't been triggered yet
                                    if not actorInfo.actionTriggered then
                                        actorInfo.actionTriggered = true

                                        tes3.say({ reference = actor, soundPath = "Vo\\b\\m\\Hlo_BM000e.mp3", subtitle = "Get out of here!" })
                                        if config.messagesOn then
                                            tes3.messageBox({ message = actor.object.name .. " asks you to leave." })
                                        end

                                        -- Start the timer and store it in the activeTimer variable
                                        actorInfo.timer = timer.start{
                                            duration = config.timerSeconds,
                                            callback = function()
                                                tes3.triggerCrime({ type = tes3.crimeType.trespass, forceDetection = false })
                                                if config.messagesOn then
                                                    tes3.messageBox({ message = actor.object.name .. " considers you a trespasser." })
                                                end
                                                tes3.say({ reference = actor, soundPath = "Vo\\b\\m\\Hlo_BM000e.mp3", subtitle = "Get out of here!" })

                                                if config.decreaseDisposition then
                                                    decreaseDisposition(actor)
                                                end
                                                
                                                if config.combat then
                                                    if config.playerLevel then
                                                        if (actorLevel >= playerLevel) then
                                                            actor.mobile:startCombat(tes3.mobilePlayer)
                                                        else
                                                            if (playerLevel - actorLevel) <= config.level then
                                                                actor.mobile:startCombat(tes3.mobilePlayer)
                                                            end
                                                        end
                                                    else
                                                        actor.mobile:startCombat(tes3.mobilePlayer)
                                                    end
                                                end
                                            end
                                        }
                                    end
                                elseif (race and race.id == "T_Sky_Reachman") then
                                    -- If not already detected, mark the actor as having detected the player
                                    if not detectedActors[actor] then
                                        detectedActors[actor] = {
                                            detected = true,
                                            actionTriggered = false,  -- Flag to ensure actions are triggered only once
                                            timer = nil
                                        }
                                    end

                                    local actorInfo = detectedActors[actor]

                                    -- Trigger actions only if they haven't been triggered yet
                                    if not actorInfo.actionTriggered then
                                        actorInfo.actionTriggered = true

                                        tes3.say({ reference = actor, soundPath = "Sky\\Vo\\Rc\\m\\Hlo_RcM000d.mp3", subtitle = "You seek to challenge me?" })
                                        if config.messagesOn then
                                            tes3.messageBox({ message = actor.object.name .. " asks you to leave." })
                                        end

                                        -- Start the timer and store it in the activeTimer variable
                                        actorInfo.timer = timer.start{
                                            duration = config.timerSeconds,
                                            callback = function()
                                                tes3.triggerCrime({ type = tes3.crimeType.trespass, forceDetection = false })
                                                if config.messagesOn then
                                                    tes3.messageBox({ message = actor.object.name .. " considers you a trespasser." })
                                                end
                                                tes3.say({ reference = actor, soundPath = "Sky\\Vo\\Rc\\m\\Hlo_RcM000d.mp3", subtitle = "You seek to challenge me?" })

                                                if config.decreaseDisposition then
                                                    decreaseDisposition(actor)
                                                end
                                                
                                                if config.combat then
                                                    if config.playerLevel then
                                                        if (actorLevel >= playerLevel) then
                                                            actor.mobile:startCombat(tes3.mobilePlayer)
                                                        else
                                                            if (playerLevel - actorLevel) <= config.level then
                                                                actor.mobile:startCombat(tes3.mobilePlayer)
                                                            end
                                                        end
                                                    else
                                                        actor.mobile:startCombat(tes3.mobilePlayer)
                                                    end
                                                end
                                            end
                                        }
                                    end
                                elseif (race and race.id == "High Elf" and actor.object.female) then
                                    -- If not already detected, mark the actor as having detected the player
                                    if not detectedActors[actor] then
                                        detectedActors[actor] = {
                                            detected = true,
                                            actionTriggered = false,  -- Flag to ensure actions are triggered only once
                                            timer = nil
                                        }
                                    end

                                    local actorInfo = detectedActors[actor]

                                    -- Trigger actions only if they haven't been triggered yet
                                    if not actorInfo.actionTriggered then
                                        actorInfo.actionTriggered = true

                                        tes3.say({ reference = actor, soundPath = "Vo\\h\\f\\Hlo_HF000e.mp3", subtitle = "Get out of here!" })
                                        if config.messagesOn then
                                            tes3.messageBox({ message = actor.object.name .. " asks you to leave." })
                                        end

                                        -- Start the timer and store it in the activeTimer variable
                                        actorInfo.timer = timer.start{
                                            duration = config.timerSeconds,
                                            callback = function()
                                                tes3.triggerCrime({ type = tes3.crimeType.trespass, forceDetection = false })
                                                if config.messagesOn then
                                                    tes3.messageBox({ message = actor.object.name .. " considers you a trespasser." })
                                                end
                                                tes3.say({ reference = actor, soundPath = "Vo\\h\\f\\Atk_HF011.mp3", subtitle = "It's over for you!" })

                                                if config.decreaseDisposition then
                                                    decreaseDisposition(actor)
                                                end
                                                
                                                if config.combat then
                                                    if config.playerLevel then
                                                        if (actorLevel >= playerLevel) then
                                                            actor.mobile:startCombat(tes3.mobilePlayer)
                                                        else
                                                            if (playerLevel - actorLevel) <= config.level then
                                                                actor.mobile:startCombat(tes3.mobilePlayer)
                                                            end
                                                        end
                                                    else
                                                        actor.mobile:startCombat(tes3.mobilePlayer)
                                                    end
                                                end
                                            end
                                        }
                                    end
                                elseif (race and race.id == "High Elf") then
                                    -- If not already detected, mark the actor as having detected the player
                                    if not detectedActors[actor] then
                                        detectedActors[actor] = {
                                            detected = true,
                                            actionTriggered = false,  -- Flag to ensure actions are triggered only once
                                            timer = nil
                                        }
                                    end

                                    local actorInfo = detectedActors[actor]

                                    -- Trigger actions only if they haven't been triggered yet
                                    if not actorInfo.actionTriggered then
                                        actorInfo.actionTriggered = true

                                        tes3.say({ reference = actor, soundPath = "Vo\\h\\m\\Hlo_HM000e.mp3", subtitle = "Get out of here!" })
                                        if config.messagesOn then
                                            tes3.messageBox({ message = actor.object.name .. " asks you to leave." })
                                        end

                                        -- Start the timer and store it in the activeTimer variable
                                        actorInfo.timer = timer.start{
                                            duration = config.timerSeconds,
                                            callback = function()
                                                tes3.triggerCrime({ type = tes3.crimeType.trespass, forceDetection = false })
                                                if config.messagesOn then
                                                    tes3.messageBox({ message = actor.object.name .. " considers you a trespasser." })
                                                end
                                                tes3.say({ reference = actor, soundPath = "Vo\\h\\m\\Thf_HM001.mp3", subtitle = "Do you take me for a fool? Guards!" })

                                                if config.decreaseDisposition then
                                                    decreaseDisposition(actor)
                                                end
                                                
                                                if config.combat then
                                                    if config.playerLevel then
                                                        if (actorLevel >= playerLevel) then
                                                            actor.mobile:startCombat(tes3.mobilePlayer)
                                                        else
                                                            if (playerLevel - actorLevel) <= config.level then
                                                                actor.mobile:startCombat(tes3.mobilePlayer)
                                                            end
                                                        end
                                                    else
                                                        actor.mobile:startCombat(tes3.mobilePlayer)
                                                    end
                                                end
                                            end
                                        }
                                    end
                                elseif (race and race.id == "Imperial" and actor.object.female) then
                                    -- If not already detected, mark the actor as having detected the player
                                    if not detectedActors[actor] then
                                        detectedActors[actor] = {
                                            detected = true,
                                            actionTriggered = false,  -- Flag to ensure actions are triggered only once
                                            timer = nil
                                        }
                                    end

                                    local actorInfo = detectedActors[actor]

                                    -- Trigger actions only if they haven't been triggered yet
                                    if not actorInfo.actionTriggered then
                                        actorInfo.actionTriggered = true

                                        tes3.say({ reference = actor, soundPath = "Vo\\i\\f\\Hlo_IF000e.mp3", subtitle = "Get out of here!" })
                                        if config.messagesOn then
                                            tes3.messageBox({ message = actor.object.name .. " asks you to leave." })
                                        end

                                        -- Start the timer and store it in the activeTimer variable
                                        actorInfo.timer = timer.start{
                                            duration = config.timerSeconds,
                                            callback = function()
                                                tes3.triggerCrime({ type = tes3.crimeType.trespass, forceDetection = false })
                                                if config.messagesOn then
                                                    tes3.messageBox({ message = actor.object.name .. " considers you a trespasser." })
                                                end
                                                tes3.say({ reference = actor, soundPath = "Vo\\i\\f\\Atk_IF001.mp3", subtitle = "I've trifled with you long enough!" })

                                                if config.decreaseDisposition then
                                                    decreaseDisposition(actor)
                                                end
                                                
                                                if config.combat then
                                                    if config.playerLevel then
                                                        if (actorLevel >= playerLevel) then
                                                            actor.mobile:startCombat(tes3.mobilePlayer)
                                                        else
                                                            if (playerLevel - actorLevel) <= config.level then
                                                                actor.mobile:startCombat(tes3.mobilePlayer)
                                                            end
                                                        end
                                                    else
                                                        actor.mobile:startCombat(tes3.mobilePlayer)
                                                    end
                                                end
                                            end
                                        }
                                    end
                                elseif (race and race.id == "Imperial") then
                                    -- If not already detected, mark the actor as having detected the player
                                    if not detectedActors[actor] then
                                        detectedActors[actor] = {
                                            detected = true,
                                            actionTriggered = false,  -- Flag to ensure actions are triggered only once
                                            timer = nil
                                        }
                                    end

                                    local actorInfo = detectedActors[actor]

                                    -- Trigger actions only if they haven't been triggered yet
                                    if not actorInfo.actionTriggered then
                                        actorInfo.actionTriggered = true

                                        tes3.say({ reference = actor, soundPath = "Vo\\i\\m\\Hlo_IM000e.mp3", subtitle = "Get out of here!" })
                                        if config.messagesOn then
                                            tes3.messageBox({ message = actor.object.name .. " asks you to leave." })
                                        end

                                        -- Start the timer and store it in the activeTimer variable
                                        actorInfo.timer = timer.start{
                                            duration = config.timerSeconds,
                                            callback = function()
                                                tes3.triggerCrime({ type = tes3.crimeType.trespass, forceDetection = false })
                                                if config.messagesOn then
                                                    tes3.messageBox({ message = actor.object.name .. " considers you a trespasser." })
                                                end
                                                tes3.say({ reference = actor, soundPath = "Vo\\i\\m\\Atk_IM001.mp3", subtitle = "I've trifled with you long enough!" })

                                                if config.decreaseDisposition then
                                                    decreaseDisposition(actor)
                                                end
                                                
                                                if config.combat then
                                                    if config.playerLevel then
                                                        if (actorLevel >= playerLevel) then
                                                            actor.mobile:startCombat(tes3.mobilePlayer)
                                                        else
                                                            if (playerLevel - actorLevel) <= config.level then
                                                                actor.mobile:startCombat(tes3.mobilePlayer)
                                                            end
                                                        end
                                                    else
                                                        actor.mobile:startCombat(tes3.mobilePlayer)
                                                    end
                                                end
                                            end
                                        }
                                    end
                                elseif (race and race.id == "Nord" and actor.object.female) then
                                    -- If not already detected, mark the actor as having detected the player
                                    if not detectedActors[actor] then
                                        detectedActors[actor] = {
                                            detected = true,
                                            actionTriggered = false,  -- Flag to ensure actions are triggered only once
                                            timer = nil
                                        }
                                    end

                                    local actorInfo = detectedActors[actor]

                                    -- Trigger actions only if they haven't been triggered yet
                                    if not actorInfo.actionTriggered then
                                        actorInfo.actionTriggered = true

                                        tes3.say({ reference = actor, soundPath = "Vo\\n\\f\\Hlo_NF000e.mp3", subtitle = "Get out of here!" })
                                        if config.messagesOn then
                                            tes3.messageBox({ message = actor.object.name .. " asks you to leave." })
                                        end

                                        -- Start the timer and store it in the activeTimer variable
                                        actorInfo.timer = timer.start{
                                            duration = config.timerSeconds,
                                            callback = function()
                                                tes3.triggerCrime({ type = tes3.crimeType.trespass, forceDetection = false })
                                                if config.messagesOn then
                                                    tes3.messageBox({ message = actor.object.name .. " considers you a trespasser." })
                                                end
                                                tes3.say({ reference = actor, soundPath = "Vo\\n\\f\\Fle_NF001.mp3", subtitle = "Not today!" })

                                                if config.decreaseDisposition then
                                                    decreaseDisposition(actor)
                                                end
                                                
                                                if config.combat then
                                                    if config.playerLevel then
                                                        if (actorLevel >= playerLevel) then
                                                            actor.mobile:startCombat(tes3.mobilePlayer)
                                                        else
                                                            if (playerLevel - actorLevel) <= config.level then
                                                                actor.mobile:startCombat(tes3.mobilePlayer)
                                                            end
                                                        end
                                                    else
                                                        actor.mobile:startCombat(tes3.mobilePlayer)
                                                    end
                                                end
                                            end
                                        }
                                    end
                                elseif (race and race.id == "Nord") then
                                    -- If not already detected, mark the actor as having detected the player
                                    if not detectedActors[actor] then
                                        detectedActors[actor] = {
                                            detected = true,
                                            actionTriggered = false,  -- Flag to ensure actions are triggered only once
                                            timer = nil
                                        }
                                    end

                                    local actorInfo = detectedActors[actor]

                                    -- Trigger actions only if they haven't been triggered yet
                                    if not actorInfo.actionTriggered then
                                        actorInfo.actionTriggered = true

                                        tes3.say({ reference = actor, soundPath = "Vo\\n\\m\\Hlo_NM022.mp3", subtitle = "Get out of here, before you get hurt!" })
                                        if config.messagesOn then
                                            tes3.messageBox({ message = actor.object.name .. " asks you to leave." })
                                        end

                                        -- Start the timer and store it in the activeTimer variable
                                        actorInfo.timer = timer.start{
                                            duration = config.timerSeconds,
                                            callback = function()
                                                tes3.triggerCrime({ type = tes3.crimeType.trespass, forceDetection = false })
                                                if config.messagesOn then
                                                    tes3.messageBox({ message = actor.object.name .. " considers you a trespasser." })
                                                end
                                                tes3.say({ reference = actor, soundPath = "Vo\\n\\m\\Atk_NM004.mp3", subtitle = "Fool!" })

                                                if config.decreaseDisposition then
                                                    decreaseDisposition(actor)
                                                end
                                                
                                                if config.combat then
                                                    if config.playerLevel then
                                                        if (actorLevel >= playerLevel) then
                                                            actor.mobile:startCombat(tes3.mobilePlayer)
                                                        else
                                                            if (playerLevel - actorLevel) <= config.level then
                                                                actor.mobile:startCombat(tes3.mobilePlayer)
                                                            end
                                                        end
                                                    else
                                                        actor.mobile:startCombat(tes3.mobilePlayer)
                                                    end
                                                end
                                            end
                                        }
                                    end
                                elseif (race and race.id == "Orc" and actor.object.female) or (race and race.id == "T_Mw_Malahk_Orc" and actor.object.female) then
                                    -- If not already detected, mark the actor as having detected the player
                                    if not detectedActors[actor] then
                                        detectedActors[actor] = {
                                            detected = true,
                                            actionTriggered = false,  -- Flag to ensure actions are triggered only once
                                            timer = nil
                                        }
                                    end

                                    local actorInfo = detectedActors[actor]

                                    -- Trigger actions only if they haven't been triggered yet
                                    if not actorInfo.actionTriggered then
                                        actorInfo.actionTriggered = true

                                        tes3.say({ reference = actor, soundPath = "Vo\\o\\f\\Hlo_OF000e.mp3", subtitle = "Get out of here!" })
                                        if config.messagesOn then
                                            tes3.messageBox({ message = actor.object.name .. " asks you to leave." })
                                        end

                                        -- Start the timer and store it in the activeTimer variable
                                        actorInfo.timer = timer.start{
                                            duration = config.timerSeconds,
                                            callback = function()
                                                tes3.triggerCrime({ type = tes3.crimeType.trespass, forceDetection = false })
                                                if config.messagesOn then
                                                    tes3.messageBox({ message = actor.object.name .. " considers you a trespasser." })
                                                end
                                                tes3.say({ reference = actor, soundPath = "Vo\\o\\f\\Atk_OF005.mp3", subtitle = "Now you die!" })

                                                if config.decreaseDisposition then
                                                    decreaseDisposition(actor)
                                                end
                                                
                                                if config.combat then
                                                    if config.playerLevel then
                                                        if (actorLevel >= playerLevel) then
                                                            actor.mobile:startCombat(tes3.mobilePlayer)
                                                        else
                                                            if (playerLevel - actorLevel) <= config.level then
                                                                actor.mobile:startCombat(tes3.mobilePlayer)
                                                            end
                                                        end
                                                    else
                                                        actor.mobile:startCombat(tes3.mobilePlayer)
                                                    end
                                                end
                                            end
                                        }
                                    end
                                elseif (race and race.id == "Orc") or (race and race.id == "T_Mw_Malahk_Orc") then
                                    -- If not already detected, mark the actor as having detected the player
                                    if not detectedActors[actor] then
                                        detectedActors[actor] = {
                                            detected = true,
                                            actionTriggered = false,  -- Flag to ensure actions are triggered only once
                                            timer = nil
                                        }
                                    end

                                    local actorInfo = detectedActors[actor]

                                    -- Trigger actions only if they haven't been triggered yet
                                    if not actorInfo.actionTriggered then
                                        actorInfo.actionTriggered = true

                                        tes3.say({ reference = actor, soundPath = "Vo\\o\\m\\Hlo_OM000d.mp3", subtitle = "You seek to challenge me?" })
                                        if config.messagesOn then
                                            tes3.messageBox({ message = actor.object.name .. " asks you to leave." })
                                        end

                                        -- Start the timer and store it in the activeTimer variable
                                        actorInfo.timer = timer.start{
                                            duration = config.timerSeconds,
                                            callback = function()
                                                tes3.triggerCrime({ type = tes3.crimeType.trespass, forceDetection = false })
                                                if config.messagesOn then
                                                    tes3.messageBox({ message = actor.object.name .. " considers you a trespasser." })
                                                end
                                                tes3.say({ reference = actor, soundPath = "Vo\\o\\m\\Atk_OM010.mp3", subtitle = "Escape while you can!" })

                                                if config.decreaseDisposition then
                                                    decreaseDisposition(actor)
                                                end
                                                
                                                if config.combat then
                                                    if config.playerLevel then
                                                        if (actorLevel >= playerLevel) then
                                                            actor.mobile:startCombat(tes3.mobilePlayer)
                                                        else
                                                            if (playerLevel - actorLevel) <= config.level then
                                                                actor.mobile:startCombat(tes3.mobilePlayer)
                                                            end
                                                        end
                                                    else
                                                        actor.mobile:startCombat(tes3.mobilePlayer)
                                                    end
                                                end
                                            end
                                        }
                                    end
                                elseif (race and race.id == "Redguard" and actor.object.female) then
                                    -- If not already detected, mark the actor as having detected the player
                                    if not detectedActors[actor] then
                                        detectedActors[actor] = {
                                            detected = true,
                                            actionTriggered = false,  -- Flag to ensure actions are triggered only once
                                            timer = nil
                                        }
                                    end

                                    local actorInfo = detectedActors[actor]

                                    -- Trigger actions only if they haven't been triggered yet
                                    if not actorInfo.actionTriggered then
                                        actorInfo.actionTriggered = true

                                        tes3.say({ reference = actor, soundPath = "Vo\\r\\f\\Hlo_RF000e.mp3", subtitle = "Get out of here!" })
                                        if config.messagesOn then
                                            tes3.messageBox({ message = actor.object.name .. " asks you to leave." })
                                        end

                                        -- Start the timer and store it in the activeTimer variable
                                        actorInfo.timer = timer.start{
                                            duration = config.timerSeconds,
                                            callback = function()
                                                tes3.triggerCrime({ type = tes3.crimeType.trespass, forceDetection = false })
                                                if config.messagesOn then
                                                    tes3.messageBox({ message = actor.object.name .. " considers you a trespasser." })
                                                end
                                                tes3.say({ reference = actor, soundPath = "Vo\\r\\f\\Thf_RF002.mp3", subtitle = "Guards!" })

                                                if config.decreaseDisposition then
                                                    decreaseDisposition(actor)
                                                end
                                                
                                                if config.combat then
                                                    if config.playerLevel then
                                                        if (actorLevel >= playerLevel) then
                                                            actor.mobile:startCombat(tes3.mobilePlayer)
                                                        else
                                                            if (playerLevel - actorLevel) <= config.level then
                                                                actor.mobile:startCombat(tes3.mobilePlayer)
                                                            end
                                                        end
                                                    else
                                                        actor.mobile:startCombat(tes3.mobilePlayer)
                                                    end
                                                end
                                            end
                                        }
                                    end
                                elseif (race and race.id == "Redguard") then
                                    -- If not already detected, mark the actor as having detected the player
                                    if not detectedActors[actor] then
                                        detectedActors[actor] = {
                                            detected = true,
                                            actionTriggered = false,  -- Flag to ensure actions are triggered only once
                                            timer = nil
                                        }
                                    end

                                    local actorInfo = detectedActors[actor]

                                    -- Trigger actions only if they haven't been triggered yet
                                    if not actorInfo.actionTriggered then
                                        actorInfo.actionTriggered = true

                                        tes3.say({ reference = actor, soundPath = "Vo\\r\\m\\Hlo_RM001.mp3", subtitle = "I think it would be best if you leave, now!" })
                                        if config.messagesOn then
                                            tes3.messageBox({ message = actor.object.name .. " asks you to leave." })
                                        end

                                        -- Start the timer and store it in the activeTimer variable
                                        actorInfo.timer = timer.start{
                                            duration = config.timerSeconds,
                                            callback = function()
                                                tes3.triggerCrime({ type = tes3.crimeType.trespass, forceDetection = false })
                                                if config.messagesOn then
                                                    tes3.messageBox({ message = actor.object.name .. " considers you a trespasser." })
                                                end
                                                tes3.say({ reference = actor, soundPath = "Vo\\r\\m\\Thf_RM002.mp3", subtitle = "Guards!" })

                                                if config.decreaseDisposition then
                                                    decreaseDisposition(actor)
                                                end
                                                
                                                if config.combat then
                                                    if config.playerLevel then
                                                        if (actorLevel >= playerLevel) then
                                                            actor.mobile:startCombat(tes3.mobilePlayer)
                                                        else
                                                            if (playerLevel - actorLevel) <= config.level then
                                                                actor.mobile:startCombat(tes3.mobilePlayer)
                                                            end
                                                        end
                                                    else
                                                        actor.mobile:startCombat(tes3.mobilePlayer)
                                                    end
                                                end
                                            end
                                        }
                                    end
                                elseif (race and race.id == "Wood Elf" and actor.object.female) then
                                    -- If not already detected, mark the actor as having detected the player
                                    if not detectedActors[actor] then
                                        detectedActors[actor] = {
                                            detected = true,
                                            actionTriggered = false,  -- Flag to ensure actions are triggered only once
                                            timer = nil
                                        }
                                    end

                                    local actorInfo = detectedActors[actor]

                                    -- Trigger actions only if they haven't been triggered yet
                                    if not actorInfo.actionTriggered then
                                        actorInfo.actionTriggered = true

                                        tes3.say({ reference = actor, soundPath = "Vo\\w\\f\\Hlo_WF000e.mp3", subtitle = "Get out of here!" })
                                        if config.messagesOn then
                                            tes3.messageBox({ message = actor.object.name .. " asks you to leave." })
                                        end

                                        -- Start the timer and store it in the activeTimer variable
                                        actorInfo.timer = timer.start{
                                            duration = config.timerSeconds,
                                            callback = function()
                                                tes3.triggerCrime({ type = tes3.crimeType.trespass, forceDetection = false })
                                                if config.messagesOn then
                                                    tes3.messageBox({ message = actor.object.name .. " considers you a trespasser." })
                                                end
                                                tes3.say({ reference = actor, soundPath = "Vo\\w\\f\\Atk_WF002.mp3", subtitle = "Fetcher!" })

                                                if config.decreaseDisposition then
                                                    decreaseDisposition(actor)
                                                end
                                                
                                                if config.combat then
                                                    if config.playerLevel then
                                                        if (actorLevel >= playerLevel) then
                                                            actor.mobile:startCombat(tes3.mobilePlayer)
                                                        else
                                                            if (playerLevel - actorLevel) <= config.level then
                                                                actor.mobile:startCombat(tes3.mobilePlayer)
                                                            end
                                                        end
                                                    else
                                                        actor.mobile:startCombat(tes3.mobilePlayer)
                                                    end
                                                end
                                            end
                                        }
                                    end
                                elseif (race and race.id == "Wood Elf") then
                                    -- If not already detected, mark the actor as having detected the player
                                    if not detectedActors[actor] then
                                        detectedActors[actor] = {
                                            detected = true,
                                            actionTriggered = false,  -- Flag to ensure actions are triggered only once
                                            timer = nil
                                        }
                                    end

                                    local actorInfo = detectedActors[actor]

                                    -- Trigger actions only if they haven't been triggered yet
                                    if not actorInfo.actionTriggered then
                                        actorInfo.actionTriggered = true

                                        tes3.say({ reference = actor, soundPath = "Vo\\w\\m\\Hlo_WM024.mp3", subtitle = "You'll get more than you bargained for from me!" })
                                        if config.messagesOn then
                                            tes3.messageBox({ message = actor.object.name .. " asks you to leave." })
                                        end

                                        -- Start the timer and store it in the activeTimer variable
                                        actorInfo.timer = timer.start{
                                            duration = config.timerSeconds,
                                            callback = function()
                                                tes3.triggerCrime({ type = tes3.crimeType.trespass, forceDetection = false })
                                                if config.messagesOn then
                                                    tes3.messageBox({ message = actor.object.name .. " considers you a trespasser." })
                                                end
                                                tes3.say({ reference = actor, soundPath = "Vo\\w\\m\\Atk_WM006.mp3", subtitle = "You chose the wrong Bosmer to mess with!" })

                                                if config.decreaseDisposition then
                                                    decreaseDisposition(actor)
                                                end
                                                
                                                if config.combat then
                                                    if config.playerLevel then
                                                        if (actorLevel >= playerLevel) then
                                                            actor.mobile:startCombat(tes3.mobilePlayer)
                                                        else
                                                            if (playerLevel - actorLevel) <= config.level then
                                                                actor.mobile:startCombat(tes3.mobilePlayer)
                                                            end
                                                        end
                                                    else
                                                        actor.mobile:startCombat(tes3.mobilePlayer)
                                                    end
                                                end
                                            end
                                        }
                                    end
                                elseif (race and race.id == "T_Cnq_ChimeriQuey" and actor.object.female) then
                                    -- If not already detected, mark the actor as having detected the player
                                    if not detectedActors[actor] then
                                        detectedActors[actor] = {
                                            detected = true,
                                            actionTriggered = false,  -- Flag to ensure actions are triggered only once
                                            timer = nil
                                        }
                                    end

                                    local actorInfo = detectedActors[actor]

                                    -- Trigger actions only if they haven't been triggered yet
                                    if not actorInfo.actionTriggered then
                                        actorInfo.actionTriggered = true

                                        tes3.say({ reference = actor, soundPath = "TR\\Vo\\TR_ChiF_Hlo_006.mp3", subtitle = "No, I don't have time for you." })
                                        if config.messagesOn then
                                            tes3.messageBox({ message = actor.object.name .. " asks you to leave." })
                                        end

                                        -- Start the timer and store it in the activeTimer variable
                                        actorInfo.timer = timer.start{
                                            duration = config.timerSeconds,
                                            callback = function()
                                                tes3.triggerCrime({ type = tes3.crimeType.trespass, forceDetection = false })
                                                if config.messagesOn then
                                                    tes3.messageBox({ message = actor.object.name .. " considers you a trespasser." })
                                                end
                                                tes3.say({ reference = actor, soundPath = "TR\\Vo\\ChiF_Hlo_001.mp3", subtitle = "You are repulsive. Get out of here!" })

                                                if config.decreaseDisposition then
                                                    decreaseDisposition(actor)
                                                end
                                                
                                                if config.combat then
                                                    if config.playerLevel then
                                                        if (actorLevel >= playerLevel) then
                                                            actor.mobile:startCombat(tes3.mobilePlayer)
                                                        else
                                                            if (playerLevel - actorLevel) <= config.level then
                                                                actor.mobile:startCombat(tes3.mobilePlayer)
                                                            end
                                                        end
                                                    else
                                                        actor.mobile:startCombat(tes3.mobilePlayer)
                                                    end
                                                end
                                            end
                                        }
                                    end
                                elseif (race and race.id == "T_Cnq_ChimeriQuey") then
                                    -- If not already detected, mark the actor as having detected the player
                                    if not detectedActors[actor] then
                                        detectedActors[actor] = {
                                            detected = true,
                                            actionTriggered = false,  -- Flag to ensure actions are triggered only once
                                            timer = nil
                                        }
                                    end

                                    local actorInfo = detectedActors[actor]

                                    -- Trigger actions only if they haven't been triggered yet
                                    if not actorInfo.actionTriggered then
                                        actorInfo.actionTriggered = true

                                        tes3.say({ reference = actor, soundPath = "TR\\Vo\\TR_ChiM_Hlo_002.mp3", subtitle = "Go away." })
                                        if config.messagesOn then
                                            tes3.messageBox({ message = actor.object.name .. " asks you to leave." })
                                        end

                                        -- Start the timer and store it in the activeTimer variable
                                        actorInfo.timer = timer.start{
                                            duration = config.timerSeconds,
                                            callback = function()
                                                tes3.triggerCrime({ type = tes3.crimeType.trespass, forceDetection = false })
                                                if config.messagesOn then
                                                    tes3.messageBox({ message = actor.object.name .. " considers you a trespasser." })
                                                end
                                                tes3.say({ reference = actor, soundPath = "TR\\Vo\\TR_ChiM_Att_001.mp3", subtitle = "Die!" })

                                                if config.decreaseDisposition then
                                                    decreaseDisposition(actor)
                                                end
                                                
                                                if config.combat then
                                                    if config.playerLevel then
                                                        if (actorLevel >= playerLevel) then
                                                            actor.mobile:startCombat(tes3.mobilePlayer)
                                                        else
                                                            if (playerLevel - actorLevel) <= config.level then
                                                                actor.mobile:startCombat(tes3.mobilePlayer)
                                                            end
                                                        end
                                                    else
                                                        actor.mobile:startCombat(tes3.mobilePlayer)
                                                    end
                                                end
                                            end
                                        }
                                    end
                                elseif (race and race.id == "T_Cnq_Keptu" and actor.object.female) then
                                    -- If not already detected, mark the actor as having detected the player
                                    if not detectedActors[actor] then
                                        detectedActors[actor] = {
                                            detected = true,
                                            actionTriggered = false,  -- Flag to ensure actions are triggered only once
                                            timer = nil
                                        }
                                    end

                                    local actorInfo = detectedActors[actor]

                                    -- Trigger actions only if they haven't been triggered yet
                                    if not actorInfo.actionTriggered then
                                        actorInfo.actionTriggered = true

                                        tes3.say({ reference = actor, soundPath = "TR\\Vo\\TR_KepF_Hlo_001.mp3", subtitle = "Please leave... now." })
                                        if config.messagesOn then
                                            tes3.messageBox({ message = actor.object.name .. " asks you to leave." })
                                        end

                                        -- Start the timer and store it in the activeTimer variable
                                        actorInfo.timer = timer.start{
                                            duration = config.timerSeconds,
                                            callback = function()
                                                tes3.triggerCrime({ type = tes3.crimeType.trespass, forceDetection = false })
                                                if config.messagesOn then
                                                    tes3.messageBox({ message = actor.object.name .. " considers you a trespasser." })
                                                end
                                                tes3.say({ reference = actor, soundPath = "TR\\Vo\\TR_KepF_Attk_001.mp3", subtitle = "Uraaghh!" })

                                                if config.decreaseDisposition then
                                                    decreaseDisposition(actor)
                                                end
                                                
                                                if config.combat then
                                                    if config.playerLevel then
                                                        if (actorLevel >= playerLevel) then
                                                            actor.mobile:startCombat(tes3.mobilePlayer)
                                                        else
                                                            if (playerLevel - actorLevel) <= config.level then
                                                                actor.mobile:startCombat(tes3.mobilePlayer)
                                                            end
                                                        end
                                                    else
                                                        actor.mobile:startCombat(tes3.mobilePlayer)
                                                    end
                                                end
                                            end
                                        }
                                    end
                                elseif (race and race.id == "T_Cnq_Keptu") then
                                    -- If not already detected, mark the actor as having detected the player
                                    if not detectedActors[actor] then
                                        detectedActors[actor] = {
                                            detected = true,
                                            actionTriggered = false,  -- Flag to ensure actions are triggered only once
                                            timer = nil
                                        }
                                    end

                                    local actorInfo = detectedActors[actor]

                                    -- Trigger actions only if they haven't been triggered yet
                                    if not actorInfo.actionTriggered then
                                        actorInfo.actionTriggered = true

                                        tes3.say({ reference = actor, soundPath = "TR\\Vo\\TR_KepM_Hlo_001.mp3", subtitle = "Go away." })
                                        if config.messagesOn then
                                            tes3.messageBox({ message = actor.object.name .. " asks you to leave." })
                                        end

                                        -- Start the timer and store it in the activeTimer variable
                                        actorInfo.timer = timer.start{
                                            duration = config.timerSeconds,
                                            callback = function()
                                                tes3.triggerCrime({ type = tes3.crimeType.trespass, forceDetection = false })
                                                if config.messagesOn then
                                                    tes3.messageBox({ message = actor.object.name .. " considers you a trespasser." })
                                                end
                                                tes3.say({ reference = actor, soundPath = "TR\\Vo\\TR_KepM_Att_003.mp3", subtitle = "Hoogh-hoogh!" })
                                                
                                                if config.decreaseDisposition then
                                                    decreaseDisposition(actor)
                                                end
                                                
                                                if config.combat then
                                                    if config.playerLevel then
                                                        if (actorLevel >= playerLevel) then
                                                            actor.mobile:startCombat(tes3.mobilePlayer)
                                                        else
                                                            if (playerLevel - actorLevel) <= config.level then
                                                                actor.mobile:startCombat(tes3.mobilePlayer)
                                                            end
                                                        end
                                                    else
                                                        actor.mobile:startCombat(tes3.mobilePlayer)
                                                    end
                                                end
                                            end
                                        }
                                    end
                                else
                                    return
                                end
                            end
                        end
                    end
                end
            end
        end
    end
end

-- Handle when the player activates an actor
local function onActivate(e)
    local playerCell = tes3.getPlayerCell()
    local currentTime = tes3.worldController.hour.value  

    if config.blacklist[playerCell.id] then
        return
    elseif isMatchingCell(playerCell.id) and (currentTime >= config.startTrespass or currentTime <= config.endTrespass) then
        local actor = e.target

        if actor.object.objectType == tes3.objectType.npc and actor.object.isGuard or config.blacklistNpc[actor.object.name] then
            -- Skip guards
            return
        else
        -- Ensure the target is an NPC and not the player
            if actor and actor.object and actor.object.objectType == tes3.objectType.npc and actor ~= tes3.player then
                local disposition = actor.object.disposition -- Get the NPC's disposition towards the player

                    -- Proceed only if the actor's disposition is less than config.disposition (e.g., 90)
                if disposition and disposition >= config.disposition and config.dispOn then
                    return  -- Skip if disposition is too high
                else
                    local race = actor.object.race
                    if race and race.id == "Dark Elf" and actor.object.female then
                        tes3.say({ reference = actor, soundPath = "Vo\\d\\f\\Hlo_DF000e.mp3", subtitle = "Get out of here!" })
                        return false
                    elseif race and race.id == "Dark Elf" then
                        tes3.say({ reference = actor, soundPath = "Vo\\ord\\Int_ORM002.mp3", subtitle = "What are you doing? Get out!" })
                        return false
                    elseif race and race.id == "Argonian" and actor.object.female then
                        tes3.say({ reference = actor, soundPath = "Vo\\a\\f\\Hlo_AF000e.mp3", subtitle = "Get out of here!" })
                        return false
                    elseif race and race.id == "Argonian" then
                        tes3.say({ reference = actor, soundPath = "Vo\\a\\m\\Srv_AM006.mp3", subtitle = "Go away!" })
                        return false
                    elseif race and (race.id == "Khajiit" and actor.object.female) or (race.id == "T_Els_Cathay" and actor.object.female) or (race.id == "T_Els_Cathay-raht" and actor.object.female) or (race.id == "T_Els_Dagi-raht" and actor.object.female) or (race.id == "T_Els_Ohmes" and actor.object.female) or (race.id == "T_Els_Ohmes-raht" and actor.object.female) or (race.id == "T_Els_Suthay" and actor.object.female) then
                        tes3.say({ reference = actor, soundPath = "Vo\\k\\f\\Hlo_KF000e.mp3", subtitle = "Get out of here!" })
                        return false
                    elseif race and (race.id == "Khajiit") or (race.id == "T_Els_Cathay") or (race.id == "T_Els_Cathay-raht") or (race.id == "T_Els_Dagi-raht") or (race.id == "T_Els_Ohmes") or (race.id == "T_Els_Ohmes-raht") or (race.id == "T_Els_Suthay") then
                        tes3.say({ reference = actor, soundPath = "Vo\\k\\m\\Hlo_KM022.mp3", subtitle = "Go away! Do not come back!" })
                        return false
                    elseif race and (race.id == "Breton" and actor.object.female) or (race.id == "T_Sky_Reachman" and actor.object.female) then
                        tes3.say({ reference = actor, soundPath = "Vo\\b\\f\\Hlo_BF000e.mp3", subtitle = "Get out of here!" })
                        return false
                    elseif race and (race.id == "Breton") then
                        tes3.say({ reference = actor, soundPath = "Vo\\b\\m\\Fle_BM003.mp3", subtitle = "Leave me alone!" })
                        return false
                    elseif race and (race.id == "T_Sky_Reachman") then
                        tes3.say({ reference = actor, soundPath = "Sky\\Vo\\Rc\\m\\Atk_RcM010.mp3", subtitle = "Escape while you can." })
                        return false
                    elseif race and race.id == "High Elf" and actor.object.female then
                        tes3.say({ reference = actor, soundPath = "Vo\\h\\f\\Hlo_HF000e.mp3", subtitle = "Get out of here!" })
                        return false
                    elseif race and race.id == "High Elf"then
                        tes3.say({ reference = actor, soundPath = "Vo\\h\\m\\Hlo_HM000e.mp3", subtitle = "Get out of here!" })
                        return false
                    elseif race and (race.id == "Imperial" and actor.object.female) then
                        tes3.say({ reference = actor, soundPath = "Vo\\i\\f\\Hlo_IF000e.mp3", subtitle = "Get out of here!" })
                        return false
                    elseif race and (race.id == "Imperial") then
                        tes3.say({ reference = actor, soundPath = "Vo\\i\\m\\Hlo_IM000e.mp3", subtitle = "Get out of here!" })
                        return false
                    elseif race and race.id == "Nord" and actor.object.female then
                        tes3.say({ reference = actor, soundPath = "Vo\\n\\f\\Hlo_NF000e.mp3", subtitle = "Get out of here!" })
                        return false
                    elseif race and race.id == "Nord" then
                        tes3.say({ reference = actor, soundPath = "Vo\\n\\m\\Hlo_NM022.mp3", subtitle = "Get out of here, before you get hurt!" })
                        return false
                    elseif race and race.id == "Orc" and actor.object.female or race.id == "T_Mw_Malahk_Orc" and actor.object.female then
                        tes3.say({ reference = actor, soundPath = "Vo\\o\\f\\Hlo_OF000e.mp3", subtitle = "Get out of here!" })
                        return false
                    elseif race and race.id == "Orc" or race.id == "T_Mw_Malahk_Orc" then
                        tes3.say({ reference = actor, soundPath = "Vo\\o\\m\\Hlo_OM000d.mp3", subtitle = "You seek to challenge me?" })
                        return false
                    elseif race and race.id == "Redguard" and actor.object.female then
                        tes3.say({ reference = actor, soundPath = "Vo\\r\\f\\Hlo_RF000e.mp3", subtitle = "Get out of here!" })
                        return false
                    elseif race and race.id == "Redguard" then
                        tes3.say({ reference = actor, soundPath = "Vo\\r\\m\\Hlo_RM001.mp3", subtitle = "I think it would be best if you leave, now!" })
                        return false
                    elseif race and (race.id == "Wood Elf" and actor.object.female) then
                        tes3.say({ reference = actor, soundPath = "Vo\\w\\f\\Hlo_WF000e.mp3", subtitle = "Get out of here!" })
                        return false
                    elseif race and (race.id == "Wood Elf") then
                        tes3.say({ reference = actor, soundPath = "Vo\\w\\m\\Hlo_WM024.mp3", subtitle = "You'll get more than you bargained for from me!" })
                        return false
                    elseif race and (race.id == "T_Cnq_ChimeriQuey" and actor.object.female) then
                        tes3.say({ reference = actor, soundPath = "TR\\Vo\\TR_ChiF_Hlo_006.mp3", subtitle = "No, I don't have time for you." })
                        return false
                    elseif race and (race.id == "T_Cnq_ChimeriQuey") then
                        tes3.say({ reference = actor, soundPath = "TR\\Vo\\TR_ChiM_Hlo_002.mp3", subtitle = "Go away." })
                        return false
                    elseif race and (race.id == "T_Cnq_Keptu" and actor.object.female) then
                        tes3.say({ reference = actor, soundPath = "TR\\Vo\\TR_KepF_Hlo_001.mp3", subtitle = "Please leave... now." })
                        return false
                    elseif race and (race.id == "T_Cnq_Keptu") then
                        tes3.say({ reference = actor, soundPath = "TR\\Vo\\TR_KepM_Hlo_001.mp3", subtitle = "Go away." })
                    else
                        return
                    end
                end
            end
        end
    end
end

-- Register events
mwse.log("[Intruder!] Initialized!")
event.register("uiShowRestMenu", onShowRestMenu)
event.register("cellChanged", onCellChanged)
event.register("detectSneak", detectSneak)
event.register("activate", onActivate)