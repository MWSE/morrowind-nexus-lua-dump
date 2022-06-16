local texts = {
    ['_defaultFaction'] = {
        ['greetings'] = {
            -- Very minor bounty
            [0] = "You still owe AMOUNT Gold for your infractions against the %Faction, %PCName. I won't pressure you to @pay your dues# now, but don't expect us to be friendly.",
            -- Bit more serious
            [100] = "You've wronged us, %PCName. The %Faction will not forget your outstanding dues of AMOUNT Gold and I'd really recommend you @pay your dues# here and now.",
            -- Really quite serious
            [500] = "%PCName, you're wanted by the %Faction for your infractions. You should @pay your dues# of AMOUNT Gold now unless you want to get into more trouble with us.",
            -- We're gonna unalive you (Fallback if there was another greeting more important than ours)
            [1000] = "This is your last chance to @pay your dues# of AMOUNT Gold to the %Faction, %PCName. If you don't I will be forced to do everything in my power to recover them from you."
        },
        ['lastChance'] = {
            ['canPay'] = "This is your last chance to pay your dues of AMOUNT Gold to the %Faction, %PCName. If you don't I will be forced to do everything in my power to recover them from you. Will you pay now?",
            ['cannotPay'] = "The %Faction has put a price on your head, %PCName. A significant one, AMOUNT Gold. And since you don't seem to be able to pay it, I'll have to take it from your corpse."
        }
    }
}

local config = require 'robocroque.factionalbounties.config'
local debug = require 'robocroque.factionalbounties.debug'
local bounties = require 'robocroque.factionalbounties.bounties'

local conversationTarget = nil

local function getTextGroup(group, factionName)
    local factionKey = "_defaultFaction"

    if texts[factionName] ~= nil and texts[factionName][group] ~= nil then
        factionKey = factionName
    end

    return texts[factionKey][group]
end

local function getLastChanceGreetingText(factionName)
    local bounty = bounties.getBounty(factionName) or 0
    local playerGold = tes3.getPlayerGold()

    local textKey = 'canPay'
    if bounty > playerGold then
        textKey = 'cannotPay'
    end

    return getTextGroup('lastChance', factionName)[textKey]:gsub('AMOUNT', bounty)
end

local function getGreeting(factionName)
    local bounty = bounties.getBounty(factionName) or 0

    local greetings = getTextGroup('greetings', factionName)
    
    local match = 0

    for key, val in pairs(greetings) do
        if bounty >= key and key > match then
            match = key
        end
    end

    local text = greetings[match]

    return text:gsub('AMOUNT', bounty)
end

local function updateGlobals(bounty)
    if bounty == nil then
        tes3.setGlobal('crq_FactionalBounties_Bounty', 0)
        tes3.setGlobal('crq_FactionalBounties_CanPay', 1)
        return
    end

    tes3.setGlobal('crq_FactionalBounties_Bounty', bounty)

    local gold = tes3.getPlayerGold()
    local canPay = 0
    if gold >= bounty then
        canPay = 1
    end
    tes3.setGlobal('crq_FactionalBounties_CanPay', canPay)
end

local function resetDispositionModifier (npc)
    if tes3.player.data.factionBountyDispositionModifiers[npc.id] == nil then
        return
    end

    npc.baseDisposition = npc.baseDisposition - tes3.player.data.factionBountyDispositionModifiers[npc.id]
    tes3.player.data.factionBountyDispositionModifiers[npc.id] = nil
end

local function setDispositionModifier (npc, amount)
    resetDispositionModifier(npc)

    tes3.player.data.factionBountyDispositionModifiers[npc.id] = amount
    debug('NPC %s\'s disposition before modification: %s', npc, npc.baseDisposition)
    npc.baseDisposition = npc.baseDisposition + amount
    debug('NPC %s\'s disposition after modification: %s', npc, npc.baseDisposition)
end

local function onLoaded()
    if tes3.player.data.factionBountyDispositionModifiers == nil then
        tes3.player.data.factionBountyDispositionModifiers = {}
    end
end
event.register(tes3.event.loaded, onLoaded)

local function onActivate(e)
    -- We only care if the PC is activating an NPC.
    if (e.activator ~= tes3.player) or (e.target.object.objectType ~= tes3.objectType.npc) then
        return
    end

    conversationTarget = e.target

    if conversationTarget.object.faction == nil then
        debug('Target %s has no faction', conversationTarget)
        return
    end

    local factionName = conversationTarget.object.faction.name
    local bounty = bounties.getBounty(factionName)

    updateGlobals(bounty)
    if (bounty == nil or bounty == 0) then
        resetDispositionModifier(conversationTarget.object)
    end
end
event.register(tes3.event.activate, onActivate)

local function onInfoGetText(e)
    if e.info.journalIndex ~= nil then
        -- This is journal-related dialogue, let's not mess up any quests for now
        return
    end

    if e.info.type ~= tes3.dialogueType.greeting then
        -- This is not a greeting, this function just messes with greetings
        return
    end

    local isLastChanceGreeting = table.find(factionalBounties.lastChanceGreetings, e.info.id) ~= nil
    local greetingIsBlacklisted = table.find(factionalBounties.blacklistedGreetings, e.info.id) ~= nil 

    local target = conversationTarget
    if target == nil then
        debug('No player target')
        return
    end
    if target.object.objectType ~= tes3.objectType.npc then
        debug('Target %s is no NPC (%s)', target, target.object.objectType)
        return
    end
    if target.object.faction == nil then
        debug('Target %s has no faction', target)
        return
    end

    local factionName = target.object.faction.name
    local bounty = bounties.getBounty(factionName) or 0

    if bounty == 0 then return end

    local dispositionHit = math.max((bounty / 1000) * 100, config.minimumDispositionHit) * -1
    debug('NPC faction: %s, Faction bounty: %s, Disposition hit: %s', factionName, bounty, dispositionHit)
    setDispositionModifier(target.object, dispositionHit)
    tes3ui.updateDialogDisposition()

    if isLastChanceGreeting then
        e.text = getLastChanceGreetingText(factionName)
    else
        if greetingIsBlacklisted then return end

        e.text = e:loadOriginalText() .. "\n\n" .. getGreeting(factionName)
    end
end
event.register(tes3.event.infoGetText, onInfoGetText, { type = tes3.dialogueType.greeting })

local function dialogueEnvironmentCreatedCallback(e)
    local env = e.environment
    local reference = env.reference
    local dialogue = env.dialogue
    local info = env.info

    debug("reference: %s", reference)
    debug("dialogue : %s", dialogue)
    debug("info     : %s", info)

    function env.canAffordToPayFactionalBounty()
        local bounty = bounties.getBounty(reference.object.faction.name)
        local playerGold = tes3.getPlayerGold()
    
        return playerGold >= bounty
    end

    function env.payFactionalBounty()
        local factionName = reference.object.faction.name

        local bounty = bounties.getBounty(factionName)
        debug("Paying bounty of %s for faction %s", bounty, factionName)

        local playerGold = tes3.getPlayerGold()

        if (bounty == 0 or bounty == nil or bounty > playerGold) then
            return false
        end

        local goldItem = tes3.getObject("Gold_001")

        tes3.removeItem({
            reference = tes3.player,
            item = goldItem,
            count = bounty
        })

        tes3.addItem({
            reference = reference,
            item = goldItem,
            count = bounty
        })

        tes3ui.showDialogueMessage({
            text = bounty .. " Gold was removed.",
            style = 1
        })

        bounties.setBounty(factionName, 0)
        resetDispositionModifier(reference.object)
        updateGlobals(0)
        tes3ui.updateDialogDisposition()

        return true
    end
end
event.register(tes3.event.dialogueEnvironmentCreated, dialogueEnvironmentCreatedCallback)