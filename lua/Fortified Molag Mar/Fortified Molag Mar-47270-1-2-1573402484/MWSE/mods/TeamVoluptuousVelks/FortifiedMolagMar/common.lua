local config = require("TeamVoluptuousVelks.FortifiedMolagMar.config")

local this = {}
this.debug = function (message)
    if (config.showDebug == true) then
        local prepend = '[Fortified Molag Mar: DEBUG] '
        message = prepend .. message
        mwse.log(message)
        tes3.messageBox(message)
    end
end

this.error = function (message)
    if (config.showErrors == true) then
        local prepend = '[Fortified Molag Mar: ERROR] '
        message = prepend .. message
        mwse.log(message)
        tes3.messageBox(message)
    end
end

this.data = {
    playerData = {
        shrines = {
            ["Furn_shrine_Vivec_cure_02"] = false,
            ["Furn_shrine_Vivec_cure_03"] = false,
            ["ac_shrine_palace"] = false,
            ["ac_shrine_stopmoon"] = false,
            ["ac_shrine_puzzlecanal"] = false,
            ["ac_shrine_koalcave"] = false,
            ["ac_shrine_gnisis"] = false,
        },
        artifactCharged = true,
        variables = {
            hasSpawnedActorsByEnchantedBarrier = false,
            hasSpawnedActorsForSecondTunnelFight = false,
        }
    },
    journalIds = {
        aFriendLost = "FMM_BA_01",
        aFriendMourned = "FMM_BA_02",
        aFriendReturned = "FMM_BA_03",
        aFriendAvenged = "FMM_BA_04",
        aFriendReborn = "FMM_BA_05"
    },
    spellIds = {
        slowTime = "FMM_SlowTimeSpell",
        slowTimeShrine = "FMM_SlowTimeShrineSpell",
        annihilate = "FMM_AnnihilateSpell",
        dispelEnchantedBarrier = "FMM_DispelBarrierSpell",
        banishDaedra = "FMM_LesserBanishDaedraSpell",
        firesOfOblivion = "FMM_FiresOfOblivion",
        gateExplosion = "FMM_NukeGateSpell",
        amuletReflect = "FMM_VivecBlessing"
    },
    enchantmentIds = {
        banishDaedra = "FMM_BanishWeapon_e",
        slowTime = "FMM_SlowTimeRing_e",
        bucketHelm = "FMM_BucketHelmet_e"
    },
    npcIds = {
        armiger = "FMM_SarisLerano",
        indaram = "birer indaram",
        mage = "FMM_Ulyll",
        barrierArmiger1 = "FMM_Armiger_mb_01",
        barrierArmiger2 = "FMM_Armiger_mb_02",
        vivec = "vivec_god",
        dremoraLord = "FMM_DremoraLord",
        cultist = "FMM_Cultist_u",
        weakCultist = "FMM_GenericCultist",
        genericArmiger = "FMM_BuoyantArmigerGuard"
    },
    objectIds = {
        enchantedBarrier = "FMM_EnchantedBarrier",
        cultActivator = "FMM_CultFightMarker",
        ritualSiteActivator = "FMM_RitualSiteMarker",
        evidenceActivator = "FMM_EvidenceMarker",
        amulet = "FMM_Amulet_01",
        giftAmulet = "FMM_Amulet_01v",
        banishWeapon = "FMM_BanishWeapon",
        artifactChargedRing = "FMM_SlowTimeChargedRing",
        artifactDischargedRing = "FMM_SlowTimeDischargedRing",
        artifactShrine = "FMM_TempleShrine",
        firesOfOblivion = "FMM_FiresOfOblivionVFX",
        grateA = "FMM_grate_03a",
        grateB = "FMM_grate_03b",
        grateC = "FMM_grate_04",
        battlementForcefield = "FMM_gate",
        dremoraLordAshes = "FMM_D_AshPile",
        brokenSwordBlade = "FMM_SwordBlade",
        brokenSwordHilt = "FMM_SwordHilt"
    },
    cellIds = {
        underworks = "Molag Mar, Underworks",
        armigersStronghold = "Molag Mar, Armigers Stronghold",
        battlements = "Molag Mar"
    },
    messageBoxes = {
        enchantedBarrierActivate = "The barrier feels cold in touch. You cannot pass through it.",
        mageSkirmishDialogue = "You hear Ulyll yell, 'Be careful!'",
        shrinesCompletedDialogue = "The amulet flashes brightly with blue fire. You feel a great evil leave you.",
        shrinesInProgressDialogue = "You feel a wave of warmth radiating from the amulet.",
        shrinesNoAmuletDialogue = "You pray at the shrine, but then you realize you're not wearing the amulet.",
        shrinesBagGuyDialogue = "As you have finished praying under the shrine, the amulet shatters.",
        mageDeathDialogue = "'Take this,' Ulyll says with his last breath as he gives you the artifact.",
        cultistRetreatDialogue = "Seeing Ulyll use the artifact, the cultists break into flight.",
        artifactShrineWithDischargedArtifact = "Would you like to sacrifice some of your blood and ask for a blessing, or recharge the artifact for a higher price?",
        artifactShrineNoDischargedArtifact = "Would you like to sacrifice some of your blood and ask for a blessing?",
        amuletDischarge = "As you clutch the amulet in your hand and whisper a prayer to Lord Vivec, divine power washes over you. Then, the amulet crumbles to dust."
    },
    markerIds = {
        underworks = {
            barrier = {
                mage = "FMM_b_MageMarker",
                armiger1 = "FMM_b_Armiger01Marker",
                armiger2 = "FMM_b_Armiger02Marker"
            },
            firstSkirmish = {
                cultistLeader = "FMM_fs_CultLeaderMarker",
                cultist1 = "FMM_fs_Cultist01Marker",
                cultist2 = "FMM_fs_Cultist02Marker",
                cultist3 = "FMM_fs_Cultist03Marker",
                cultist4 = "FMM_fs_Cultist04Marker",
                cultist5 = "FMM_fs_Cultist05Marker",
                cultist6 = "FMM_fs_Cultist06Marker",
            },
            secondSkirmish = {
                mage = "FMM_ss_MageMarker",
                armiger1 = "FMM_ss_Armiger01Marker",
                armiger2 = "FMM_ss_Armiger02Marker",
                armiger3 = "FMM_ss_Armiger03Marker",
                armiger4 = "FMM_ss_Armiger04Marker",
                cultistLeader = "FMM_ss_CultLeaderMarker",
                cultist1 = "FMM_ss_Cultist01Marker",
                cultist2 = "FMM_ss_Cultist02Marker",
                cultist3 = "FMM_ss_Cultist03Marker",
                cultist4 = "FMM_ss_Cultist04Marker",
                cultist5 = "FMM_ss_Cultist05Marker",
                cultist6 = "FMM_ss_Cultist06Marker",
                cultist7 = "FMM_ss_Cultist07Marker",
                cultist8 = "FMM_ss_Cultist08Marker",
            }
        },
        battlements = {
            forcefield = "FMM_GateMarker",
            indaram = "FMM_fb_IndaramMarker",
            vivec = "FMM_fb_VivecMarker",
            cultistLeader = "FMM_fb_CultLeaderMarker",
            deadArmiger = "FMM_fb_SarisMarker",
            dremoraLord = "FMM_fb_DremoraMarker",
            dremoraLord2 = "FMM_fb_Dremora2Marker",

            armiger1 = "FMM_fb_Armiger01Marker",
            armiger2 = "FMM_fb_Armiger02Marker",
            armiger3 = "FMM_fb_Armiger03Marker",
            armiger4 = "FMM_fb_Armiger04Marker",

            cultist1 = "FMM_fb_Cultist01Marker",
            cultist2 = "FMM_fb_Cultist02Marker",
            cultist3 = "FMM_fb_Cultist03Marker",
            cultist4 = "FMM_fb_Cultist04Marker",
            cultist5 = "FMM_fb_Cultist05Marker",
            cultist6 = "FMM_fb_Cultist06Marker",
        }
    },

    bannedJournals = {
        ["DA_Malacath"] = 60,
        ["DA_Mehrunes"] = 30,
        ["DA_MolagBal"] = 30,
        ["DA_Sheogorath"] = 60
    }
}


this.shouldPerformRandomEvent = function (percentChanceOfOccurence)
    if (math.random(-1, 101) <= percentChanceOfOccurence) then
        return true
    end
    return false
end

this.getActorsNearTargetPosition = function(cell, targetPosition, distanceLimit)
    local actors = {}
    -- Iterate through the references in the cell.
    for ref in cell:iterateReferences() do
        -- Check that the reference is a creature or NPC.
        if (ref.object.objectType == tes3.objectType.npc or
            ref.object.objectType == tes3.objectType.creature) then
            -- Check that the distance between the reference and the target point is within the distance limit. If so, save the reference.
            local distance = targetPosition:distance(ref.position)
            if (distance <= distanceLimit) then
                table.insert(actors, ref)
            end
        end
    end
    return actors
end

return this