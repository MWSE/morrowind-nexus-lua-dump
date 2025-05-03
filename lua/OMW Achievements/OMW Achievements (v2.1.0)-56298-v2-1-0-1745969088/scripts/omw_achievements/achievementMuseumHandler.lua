local self = require('openmw.self')
local types = require('openmw.types')
local interfaces = require('openmw.interfaces')
local achievements = require('scripts.omw_achievements.achievements.achievements')

isTorasaDialogue = false
artifactsBeforeTrade = {}
selledArtifacts = {}

local artifactsRecordIds = {
    "ebony_bow_auriel",
    "ebony_shield_auriel",
    "Bipolar Blade",
    "bloodworm_helm_unique",
    "boots of blinding speed[unique]",
    "boots_apostle_unique",
    "longbow_shadows_unique",
    "claymore_chrysamere_unique",
    "cuirass_savior_unique",
    "glass dagger_symmachus_unique",
    "dragonbone_cuirass_unique",
    "ebon_plate_cuirass_unique",
    "towershield_eleidon_unique",
    "dagger_fang_unique",
    "katana_goldbrand_unique",
    "helm_bearclaw_unique",
    "claymore_iceblade_unique",
    "lords_cuirass_unique",
    "mace of molag bal_unique",
    "Mace of Slurring",
    "ring_phynaster_unique",
    "robe_lich_unique",
    "warhammer_crusher_unique",
    "spear_mercy_unique",
    "spell_breaker_unique",
    "staff_hasedoki_unique",
    "staff_magnus_unique",
    "tenpaceboots",
    "longsword_umbra_unique",
    "ring_vampiric_unique",
    "daedric warhammer_ttgd",
    "ring_warlock_unique"
}

local function UiModeChanged(data)

    --- Check for unique achievement "Museum Benefactor"
    local playerInventory = nil
    local temporaryBeforeTable = {}

    if data.newMode == "Dialogue" then
        if data.arg.recordId == "torasa aram" then
            isTorasaDialogue = true
            playerInventory = types.Actor.inventory(self.object)

            for i = 1, #artifactsRecordIds do
                if playerInventory:find(artifactsRecordIds[i]) ~= nil then
                    table.insert(temporaryBeforeTable, artifactsRecordIds[i])
                end
                artifactsBeforeTrade = temporaryBeforeTable
            end

        end
    end

    if data.oldMode == "Dialogue" and isTorasaDialogue == true then

        isTorasaDialogue = false

        local macData = interfaces.storageUtils.getStorage("counters")
        local omwaData = interfaces.storageUtils.getStorage("achievements")
        local museumArtifacts = macData:getCopy("museumArtifacts")

        if #artifactsBeforeTrade ~= 0 then

            local temporaryAfterTable = {}

            playerInventory = types.Actor.inventory(self.object)

            for i = 1, #artifactsBeforeTrade do
                if playerInventory:find(artifactsBeforeTrade[i]) == nil then
                    table.insert(temporaryAfterTable, artifactsBeforeTrade[i])
                end
            end

            selledArtifacts = temporaryAfterTable

            if #selledArtifacts ~= 0 then
                for k = 1, #selledArtifacts do
                    table.insert(museumArtifacts, selledArtifacts[k])
                end
                macData:set("museumArtifacts", museumArtifacts)
            end

        end

        if #museumArtifacts == 32 then
            for i = 1, #achievements do
                if achievements[i].type == "unique" and achievements[i].id == "museum_01" then
                    if omwaData:get(achievements[i].id) == false then
                        self.object:sendEvent('gettingAchievement', {
                            id = achievements[i].id,
                            icon = achievements[i].icon,
                            bgColor = achievements[i].bgColor,
                            name = achievements[i].name,
                            description = achievements[i].description
                        })
                    end
                end
            end
        end

    end

end

return {
    eventHandlers = {
        UiModeChanged = UiModeChanged
    }
}