---@diagnostic disable: assign-type-mismatch
local I = require("openmw.interfaces")
local self = require("openmw.self")
local core = require("openmw.core")
local time = require("openmw_aux.time")

local traitType = require("scripts.Frana5usBackgrounds.utils.traitTypes").background

local period = 1
local swordUpgraded = false
local stopCheck

I.CharacterTraits.addTrait {
    id = "akaviriancestry",
    type = traitType,
    name = "Akaviri Ancestry",
    description = (
        "You are in part descended from the Akaviri who invaded Cyrodiil during the Reman Empire. You carry an " ..
        "ancestral Akaviri blade of great power, but unfortunately because you are no true Akaviri, using it cuts you almost " ..
        "as deeply as your enemy. Though, you feel that if you get famous enough, the blade might overlook that." ..
        " However, your blood does protect you from poison somewhat.\n" ..
        "\n" ..
        "Requirements: Imperials only.\n" ..
        "\n" ..
        "+25 pt Resist Poison\n" ..
        "> You start with a katana which will upgrade at 20 reputation"
    ),
    checkDisabled = function()
        ---@diagnostic disable-next-line: undefined-field
        return self.type.records[self.recordId].race ~= "imperial" or core.API_REVISION < 118
    end,
    doOnce = function()
        local selfSpells = self.type.spells(self)
        selfSpells:add("MB_akaviri_sanctuary")

        core.sendGlobalEvent(
            "Frana5usBackgrounds_addItems",
            {
                {
                    player = self,
                    itemId = "MB_akaviri_blade",
                    count = 1,
                    autoEquip = true,
                },
            }
        )
    end,
    onLoad = function()
        if swordUpgraded then return end
        ---@diagnostic disable-next-line: undefined-field
        local rep = self.type.stats.reputation(self)
        stopCheck = time.runRepeatedly(
            function()
                if rep.current >= 20 then
                    core.sendGlobalEvent("Frana5usBackgrounds_upgradeSword", self)
                end
            end,
            period
        )
    end
}

local function onLoad(data)
    if not data then return end
    swordUpgraded = data.swordUpgraded or swordUpgraded
end

local function onSave()
    return {
        swordUpgraded = swordUpgraded
    }
end

return {
    engineHandlers = {
        onLoad = onLoad,
        onSave = onSave,
    },
    eventHandlers = {
        Frana5usBackgrounds_swordUpgraded = function()
            swordUpgraded = true
            stopCheck()
            I.UI.showInteractiveMessage(
                "Your fame has made your sword more agreeable to you. " ..
                "It will now help instead of harm you."
            )
        end
    }
}
