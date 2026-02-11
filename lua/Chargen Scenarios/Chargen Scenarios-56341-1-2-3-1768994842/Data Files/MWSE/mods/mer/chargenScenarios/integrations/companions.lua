local Companions = require("mer.chargenScenarios.component.Companions")
local common = require("mer.chargenScenarios.common")
local logger = common.createLogger("RegisterCompanions")

---@param ref tes3reference
local function initCompanion(ref, topicList)
    if topicList then
        for _, topic in ipairs(topicList) do
            if not pcall(function()
                tes3.addTopic{ topic = topic}
                logger:debug("Added topic: %s", topic)
            end) then
                logger:debug("Failed to add topic: %s", topic)
            end
        end
    end

    local currentDisposition = ref.object.disposition
    if currentDisposition then
        local targetDisposition = 65
        local dispositionChange = targetDisposition - currentDisposition
        logger:debug("Current disposition: %s, Target disposition: %s, Change: %s", currentDisposition, targetDisposition, dispositionChange)
        if dispositionChange > 0 then
            tes3.modDisposition{
                reference = ref,
                value = dispositionChange
            }
        end
    end

    tes3.runLegacyScript{
        reference = ref,
        command = "RaiseRank, Partners"
    }
    tes3.runLegacyScript{
        reference = ref,
        command = "RaiseRank, Partners"
    }

    ref.context.companion = 1
    ref.context.following = 1
    ref.context.rankstatus = 3
end

local function addCMCompanion(ref)
    local cmTopics = {
        "-abilities",
        "-friendship",
        "-relationship",
        "-health",
        "-companionship",
        "-weapon use",
        "-map"
    }
    initCompanion(ref, cmTopics)
    if ref.baseObject.objectType == tes3.objectType.creature then
        ref.context.beastStatus = 1
    end
end

local function addFFCompanion(ref)
    local ffTopics = {
        "abilities",
        "Companionship",
        "Do you think...?",
        "Friendship",
        "meet somewhere",
        "need anything",
        "Relationship",
        "Weapon Use"
    }
    initCompanion(ref, ffTopics)
end



---@type ChargenScenarios.CompanionsFeature.Companion[]
local companions = {
    {
        id = "mer_comp_archer"
    },
    {
        id = "mer_comp_mage",
    },
    {
        id = "mer_comp_thief",
    },
    {
        id = "mer_comp_warrior",
    },
    {
        id = "mer_guar_pack"
    },
    {
        id = "aa_latte_comp01",
        callback = function (ref)
            tes3.setJournalIndex{ id = "aa_lat_00_intro", index = 100 }
            ---@diagnostic disable-next-line: deprecated
            mwscript.startScript{ script = "aa_lat_startup"}
        end
    },
    {
        id = "TDG_blimdim_comp",
        callback = function(ref)
            --journal TDG_bdq 30
            tes3.setJournalIndex{ id = "TDG_bdq", index = 30}
        end
    },
    {
        id = "1em_pdonk3",
        description = "Pack donkey",
        callback = function(ref)
            --Player->AddItem "1em_packdonkring" 1
            tes3.addItem{ reference = tes3.player, item = "1em_packdonkring", count = 1}
            --Set em_donk3 to 1
            tes3.findGlobal("em_donk3").value = 1
            --AddTopic "-missing donkey"
            tes3.addTopic{ topic = "-missing donkey"}
        end
    },
    {
        id = "0_ulf",
        description = "Orange wolf",
        callback = function(ref)
            --player->additem ingred_rat_meat_01 1
            tes3.addItem{ reference = tes3.player, item = "ingred_rat_meat_01", count = 1}
        end
    },
    {
        id = "mdFG_gizmo",
        description = "Fabricant guar",
    },
    {
        id = "2AA_Indiana",
        callback = function(ref)
            local topics = {
                "t0gether",
                "potion of healing",
                "at home",
                "cast a spell",
                "darling",
                "extra gold",
                "extra spells",
                "give me a kiss",
                "armorers hammer",
                "have a rest",
                "heal for a while",
                "remove the armor",
                "change this outfit",
                "my studies",
                "our next combat",
                "poetry",
                "put on the armor",
                "repair armor",
                "repay me",
                "restoring ourselves",
                "restoring some magicka",
                "so happy",
                "teleport back",
                "this adventure",
                "to eat",
                "to sneak" ,
            }
            for _, topic in ipairs(topics) do
                tes3.addTopic{ topic = topic}
            end
            --journal AAA_Indiana 10
            tes3.setJournalIndex{ id = "AAA_Indiana", index = 10}
        end
    },
    {
        id = "cm_clannfear",
        description = "Clannfear",
        callback = addCMCompanion,
    },
    {
        id = "cm_cliff_racer",
        description = "Cliff racer",
        callback = addCMCompanion,
    },
    {
        id = "cm_daedroth",
        description = "Daedroth",
        callback = addCMCompanion,
    },
    {
        id = "cm_goblin_bruiser",
        description = "Goblin",
        callback = addCMCompanion,
    },
    {
        id = "cm_guar",
        description = "Guar",
        callback = addCMCompanion,
    },
    {
        id = "cm_ogrim_titan",
        description = "Ogrim",
        callback = addCMCompanion,
    },
    {
        id = "cm_solva",
        callback = addCMCompanion,
    },
    {
        id = "cm_signild",
        callback = addCMCompanion,
    },
    {
        id = "cm_rorip",
        callback = addCMCompanion,
    },
    {
        id = "cm_laowen",
        callback = addCMCompanion,
    },
    {
        id = "cm_indwela",
        callback = addCMCompanion,
    },
    {
        id = "cm_haseth",
        callback = addCMCompanion,
    },
    {
        id = "cm_bowson",
        callback = addCMCompanion,
    },
    {
        id = "cm_sssari",
        callback = addCMCompanion,
    },
    {
        id = "cm_grimm",
        callback = addCMCompanion,
    },
    {
        id = "cm_draytha",
        callback = addCMCompanion,
    },
    {
        id = "cm_aria",
        callback = addCMCompanion,
    },
    {
        id = "cm_verina",
        callback = addCMCompanion,
    },
    {
        id = "cm_ravashya",
        callback = addCMCompanion,
    },
    {
        id = "cm_gratobek",
        callback = addCMCompanion,
    },
    {
        id = "cm_erendia",
        callback = addCMCompanion,
    },
    {
        id = "cm_drusana",
        callback = addCMCompanion,
    },
    {
        id = "11AA_Laura",
        callback = function(ref)
            ref.context.companion = 1
            tes3.setJournalIndex{ id = "11AA_Laura", index = 10}
        end
    },
    {
        id = "KO_Dawn",
        callback = function(ref)
            local topics = {
                "-Together",
                "-Worth",
                "-Spell",
                "-Health",
                "-Combat",
            }
            for _, topic in ipairs(topics) do
                tes3.addTopic{ topic = topic}
            end
        end
    },
    {
        id = "KO_Lady_Death",
        description = "Battlemage",
    },
    {
        id = "KO_MFae_Companion",
    },
    {
        id = "_MCA_companion_erik",
    },
    {
        id = "_MCA_companion_marianne",
    },
    {
        id = "_MCA_companion_medea",
    },
    {
        id = "_MCA_companion_telania",
    },
    {
        id = "aa_ff_BantamGuar02",
        description = "Bantam guar",
        callback = addFFCompanion,
    },
    {
        id = "aa_cm_centurion_spider",
        description = "Centurion spider",
        callback = addFFCompanion,
    },
    {
        id = "aa_cm_winged twilight",
        description = "Winged twlight",
        callback = addFFCompanion,
    },
    {
        id = "aa_comp_0s_healer",
        callback = addFFCompanion,
    },
    {
        id = "aa_comp_akul",
        callback = addFFCompanion,
    },
    {
        id = "aa_comp_amalie",
        callback = addFFCompanion,
    },
    {
        id = "aa_comp_vasgood",
        callback = addFFCompanion,
    },
    {
        id = "aa_comp_varthaal",
        callback = addFFCompanion,
    },
    {
        id = "aa_comp_valrek",
        callback = addFFCompanion,
    },
    {
        id = "aa_comp_tiar",
        callback = addFFCompanion,
    },
    {
        id = "aa_comp_khyller",
        callback = addFFCompanion,
    },
    {
        id = "aa_comp_kagha",
        callback = addFFCompanion,
    },
    {
        id = "aa_comp_ilditt",
        callback = addFFCompanion,
    },
    {
        id = "aa_comp_hognard",
        callback = addFFCompanion,
    },
    {
        id = "aa_comp_erik",
        callback = addFFCompanion,
    },
    {
        id = "aa_comp_elira",
        callback = addFFCompanion,
    },
    {
        id = "aa_comp_edward",
        callback = addFFCompanion,
    },
    {
        id = "aa_comp_driyami",
        callback = addFFCompanion,
    },
    {
        id = "aa_comp_covis",
        callback = addFFCompanion,
    },
    {
        id = "aa_comp_corneliu",
        callback = addFFCompanion,
    },
    {
        id = "aa_comp_chari",
        callback = addFFCompanion,
    },
    {
        id = "aa_comp_aria",
        callback = addFFCompanion,
    },
    {
        id = "aa_comp_annika",
        callback = addFFCompanion,
    },
    {
        id = "aa_comp_annah",
        callback = addFFCompanion,
    },
    {
        id = "aa_comp_anjoli",
        callback = addFFCompanion,
    },
    {
        id = "aa_comp_ana_indo",
        callback = addFFCompanion,
    },
    {
        id = "1A_comp_PrixiCR",
        description = "Blue cliff racer",
    },
    {
        id = "AA1_Kolka",
        description = "Wolf",
    },
    {
        id = "AA1_Paxon",
        description = "Pack rat",
    },
    {
        id = "AA1_Tetra",
        description = "Pack guar",
    },
    {
        id = "AA1_Henwen",
        description = "Pack boar",
    },
}

for _, companion in ipairs(companions) do
    Companions.addCompanion(companion)
end

event.register("equip", function(e)
    if e.item.id:lower() == "mer_cs_flute_01" then
        --find guar ref and teleport to player
        local guarRef = tes3.getReference("mer_guar_pack")
        if guarRef then
            tes3.positionCell{
                reference = guarRef,
                position = tes3.player.position,
                orientation = tes3.player.orientation,
                cell = tes3.player.cell,
            }
            tes3.messageBox("You summon your guar.")
        else
            logger:debug("Guar ref not found")
            tes3.messageBox("Nothing happens.")
        end
    end
end)