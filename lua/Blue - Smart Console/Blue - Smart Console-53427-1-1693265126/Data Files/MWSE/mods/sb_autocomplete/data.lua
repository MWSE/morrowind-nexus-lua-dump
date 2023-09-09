local data = {}

data.commands = {
    "Activate",
    "AddItem",
    "AddSoulGem",
    "AddSpell",
    "AddToLevCreature",
    "AddToLevItem",
    "AddTopic",
    "AIActivate",
    "AIEscort",
    "AIEscortCell",
    "AIFollow",
    "AIFollowCell",
    "AITravel",
    "AIWander",
    "BecomeWerewolf",
    "Begin",
    "BetaComment",
    "BC",
    "Cast",
    "CellChanged",
    "CellUpdate",
    "CenterOnCell",
    "COC",
    "CenterOnExterior",
    "COE",
    "ChangeWeather",
    "Choice",
    "ClearForceJump",
    "ClearForceMoveJump",
    "ClearForceRun",
    "ClearForceSneak",
    "ClearInfoActor",
    "Companion",
    "CreateMaps",
    "Day",
    "DaysPassed",
    "Disable",
    "DisableLevitation",
    "DisablePlayerControls",
    "DisablePlayerFighting",
    "DisablePlayerJumping",
    "DisablePlayerLooking",
    "DisablePlayerMagic",
    "DisablePlayerViewSwitch",
    "DisableTeleporting",
    "DisableVanityMode",
    "DontSaveObject",
    "Drop",
    "DropSoulGem",
    "Else",
    "ElseIf",
    "Enable",
    "EnableBirthMenu",
    "EnableClassMenu",
    "EnableInventoryMenu",
    "EnableLevelupMenu",
    "EnableLevitation",
    "EnableMagicMenu",
    "EnableMapMenu",
    "EnableNameMenu",
    "EnablePlayerControls",
    "EnablePlayerFighting",
    "EnablePlayerJumping",
    "EnablePlayerLooking",
    "EnablePlayerMagic",
    "EnablePlayerViewSwitch",
    "EnableRaceMenu",
    "EnableRest",
    "EnableStatReviewMenu",
    "EnableStatsMenu",
    "EnableTeleporting",
    "EnableVanityMode",
    "End",
    "EndIf",
    "EndWhile",
    "Equip",
    "ExplodeSpell",
    "Face",
    "FadeIn",
    "FadeOut",
    "FadeTo",
    "Fall",
    "FillJournal",
    "FillMap",
    "FixMe",
    "Float",
    "ForceGreeting",
    "ForceJump",
    "ForceMoveJump",
    "ForceRun",
    "ForceSneak",
    "GameHour",
    "GetAcrobatics",
    "GetAgility",
    "GetAIPackageDone",
    "GetAlarm",
    "GetAlchemy",
    "GetAlteration",
    "GetAngle",
    "GetArmorBonus",
    "GetArmorer",
    "GetArmorType",
    "GetAthletics",
    "GetAttackBonus",
    "GetAttacked",
    "GetAxe",
    "GetBlightDisease",
    "GetBlindness",
    "GetBlock",
    "GetBluntWeapon",
    "GetButtonPressed",
    "GetCastPenalty",
    "GetChameleon",
    "GetCollidingActor",
    "GetCollidingPC",
    "GetCommonDisease",
    "GetConjuration",
    "GetCurrentAIPackage",
    "GetCurrentTime",
    "GetCurrentWeather",
    "GetDeadCount",
    "GetDefendBonus",
    "GetDestruction",
    "GetDetected",
    "GetDisabled",
    "GetDisposition",
    "GetDistance",
    "GetEffect",
    "GetEnchant",
    "GetEndurance",
    "GetFactionReaction",
    "GetFatigue",
    "GetFight",
    "GetFlee",
    "GetFlying",
    "GetForceJump",
    "GetForceMoveJump",
    "GetForceRun",
    "GetForceSneak",
    "GetHandToHand",
    "GetHealth",
    "GetHealthGetRatio",
    "GetHeavyArmor",
    "GetHello",
    "GetIllusion",
    "GetIntelligence",
    "GetInterior",
    "GetInvisible",
    "GetItemCount",
    "GetJournalIndex",
    "GetLevel",
    "GetLightArmor",
    "GetLineOfSight",
    "GetLOS",
    "GetLocked",
    "GetLongBlade",
    "GetLuck",
    "GetMagicka",
    "GetMarksman",
    "GetMasserPhase",
    "GetMediumArmor",
    "GetMercantile",
    "GetMysticism",
    "GetParalysis",
    "GetPCCell",
    "GetPCCrimeLevel",
    "GetPCFacRep",
    "GetPCInJail",
    "GetPCJumping",
    "GetPCRank",
    "GetPCRunning",
    "GetPCSleep",
    "GetPCSneaking",
    "GetPCTraveling",
    "GetPCVisionBonus",
    "GetPersonality",
    "GetPlayerControlsDisabled",
    "GetPlayerFightingDisabled",
    "GetPlayerJumpingDisabled",
    "GetPlayerLookingDisabled",
    "GetPlayerMagicDisabled",
    "GetPlayerViewSwitch Broken",
    "GetPos",
    "GetRace",
    "GetReputation",
    "GetResistBlight",
    "GetResistCorprus",
    "GetResistDisease",
    "GetResistFire",
    "GetResistFrost",
    "GetResistMagicka",
    "GetResistNormalWeapons",
    "GetResistParalysis",
    "GetResistPoison",
    "GetResistShock",
    "GetRestoration",
    "GetScale",
    "GetSecondsPassed",
    "GetSecundaPhase",
    "GetSecurity",
    "GetShortBlade",
    "GetSilence",
    "GetSneak",
    "GetSoundPlaying",
    "GetSpear",
    "GetSpeechcraft",
    "GetSpeed",
    "GetSpell",
    "GetSpellEffects",
    "GetSpellReadied",
    "GetSquareRoot",
    "GetStandingActor",
    "GetStandingPC",
    "GetStartingAngle",
    "GetStartingPos",
    "GetStrength",
    "GetSuperJump",
    "GetSwimSpeed",
    "GetTarget",
    "GetUnarmored",
    "GetVanityModeDisabled",
    "GetWaterBreathing",
    "GetWaterLevel",
    "GetWaterWalking",
    "GetWeaponDrawn",
    "GetWeaponType",
    "GetWerewolfKills",
    "GetWillpower",
    "GetWindSpeed",
    "Goodbye",
    "GoToJail",
    "HasItemEquipped",
    "HasSoulGem",
    "Help",
    "HitAttemptOnMe",
    "HitOnMe",
    "HurtCollidingActor",
    "HurtStandingActor",
    "If",
    "IsWerewolf",
    "Journal",
    "Lock",
    "Long",
    "LoopGroup",
    "LowerRank",
    "MenuMode",
    "MenuTest",
    "MessageBox",
    "ModAcrobatics",
    "ModAgility",
    "ModAlarm",
    "ModAlchemy",
    "ModAlteration",
    "ModArmorBonus",
    "ModArmorer",
    "ModAthletics",
    "ModAttackBonus",
    "ModAxe",
    "ModBlindness",
    "ModBlock",
    "ModBluntWeapon",
    "ModCastPenalty",
    "ModChameleon",
    "ModConjuration",
    "ModCurrentFatigue",
    "ModCurrentHealth",
    "ModCurrentMagicka",
    "ModDefendBonus",
    "ModDestruction",
    "ModDisposition",
    "ModEnchant",
    "ModEndurance",
    "ModFactionReaction",
    "ModFatigue",
    "ModFight",
    "ModFlee",
    "ModFlying",
    "ModHandToHand",
    "ModHealth",
    "ModHeavyArmor",
    "ModHello",
    "ModIllusion",
    "ModIntelligence",
    "ModInvisible",
    "ModLightArmor",
    "ModLongBlade",
    "ModLuck",
    "ModMagicka",
    "ModMarksman",
    "ModMediumArmor",
    "ModMercantile",
    "ModMysticism",
    "ModParalysis",
    "ModPCCrimeLevel",
    "ModPCFacRep",
    "ModPCVisionBonus",
    "ModPersonality",
    "ModRegion",
    "ModReputation",
    "ModResistBlight",
    "ModResistCorprus",
    "ModResistDisease",
    "ModResistFire",
    "ModResistFrost",
    "ModResistMagicka",
    "ModResistNormalWeapons",
    "ModResistParalysis",
    "ModResistPoison",
    "ModResistShock",
    "ModRestoration",
    "ModScale",
    "ModSecurity",
    "ModShortBlade",
    "ModSilence",
    "ModSneak",
    "ModSpear",
    "ModSpeechcraft",
    "ModSpeed",
    "ModStrength",
    "ModSuperJump",
    "ModSwimSpeed",
    "ModUnarmored",
    "ModWaterBreathing",
    "ModWaterLevel",
    "ModWaterWalking",
    "ModWillpower",
    "Month",
    "Move",
    "MoveOneToOne",
    "MOTO",
    "MoveWorld",
    "OnActivate",
    "OnDeath",
    "OnKnockout",
    "OnMurder",
    "OnPCAdd",
    "OnPCDrop",
    "OnPCEquip",
    "OnPCHitMe",
    "OnPCRepair",
    "OnPCSoulGemUse",
    "OnRepair",
    "Operators Includes ->, +, -, etc.",
    "OutputObjCounts",
    "OutputRefCounts",
    "OutputRefInfo",
    "ORI",
    "PayFine",
    "PayFineThief",
    "PCClearExpelled",
    "PCExpell",
    "PCExpelled",
    "PCForce1stPerson",
    "PCForce3rdPerson",
    "PCGet3rdPerson",
    "PCJoinFaction",
    "PCLowerRank",
    "PCRace",
    "PCRaiseRank",
    "PCSkipEquip",
    "PCVampire",
    "PCWerewolf",
    "PlaceAtMe",
    "PlaceAtPC",
    "PlaceItem",
    "PlaceItemCell",
    "PlayBink",
    "PlayGroup",
    "PlayLoopSound3D",
    "PlayLoopSound3DVP",
    "PlaySound",
    "PlaySound3D",
    "PlaySound3DVP",
    "PlaySoundVP",
    "Position",
    "PositionCell",
    "PurgeTextures",
    "PT",
    "RaiseRank",
    "Random",
    "RemoveEffects",
    "RemoveFromLevCreature",
    "RemoveFromLevItem",
    "RemoveItem",
    "RemoveSoulGem",
    "RemoveSpell",
    "RemoveSpellEffects",
    "RepairedOnMe",
    "ResetActors",
    "RA",
    "Resurrect",
    "Return",
    "Rotate",
    "RotateWorld",
    "SameFaction",
    "Say",
    "SayDone",
    "ScriptRunning",
    "Set",
    "SetAcrobatics",
    "SetAgility",
    "SetAlarm",
    "SetAlchemy",
    "SetAlteration",
    "SetAngle",
    "SetArmorBonus",
    "SetArmorer",
    "SetAthletics",
    "SetAtStart",
    "SetAttackBonus",
    "SetAxe",
    "SetBlindness",
    "SetBlock",
    "SetBluntWeapon",
    "SetCastPenalty",
    "SetChameleon",
    "SetConjuration",
    "SetDefendBonus",
    "SetDelete",
    "SetDestruction",
    "SetDisposition",
    "SetEnchant",
    "SetEndurance",
    "SetFactionReaction",
    "SetFatigue",
    "SetFight",
    "SetFlee",
    "SetFlying",
    "SetHandToHand",
    "SetHealth",
    "SetHeavyArmor",
    "SetHello",
    "SetIllusion",
    "SetIntelligence",
    "SetInvisible",
    "SetJournalIndex",
    "SetLevel",
    "SetLightArmor",
    "SetLongBlade",
    "SetLuck",
    "SetMagicka",
    "SetMarksman",
    "SetMediumArmor",
    "SetMercantile",
    "SetMysticism",
    "SetParalysis",
    "SetPCCrimeLevel",
    "SetPCFacRep",
    "SetPCVisionBonus",
    "SetPersonality",
    "SetPos",
    "SetReputation",
    "SetResistBlight",
    "SetResistCorprus",
    "SetResistDisease",
    "SetResistFire",
    "SetResistFrost",
    "SetResistMagicka",
    "SetResistNormalWeapons",
    "SetResistParalysis",
    "SetResistPoison",
    "SetResistShock",
    "SetRestoration",
    "SetScale",
    "SetSecurity",
    "SetShortBlade",
    "SetSilence",
    "SetSneak",
    "SetSpear",
    "SetSpeechcraft",
    "SetSpeed",
    "SetStrength",
    "SetSuperJump",
    "SetSwimSpeed",
    "SetUnarmored",
    "SetWaterBreathing",
    "SetWaterLevel",
    "SetWaterWalking",
    "SetWerewolfAcrobatics",
    "SetWillpower",
    "Short",
    "Show",
    "ShowAnim",
    "SA",
    "ShowGroup",
    "SG",
    "ShowMap",
    "ShowRestMenu",
    "ShowScenegraph",
    "SSG",
    "ShowTargets",
    "ST",
    "ShowVars",
    "SV",
    "SkipAnim",
    "StartCombat",
    "StartScript",
    "StayOutside",
    "StopCellTest",
    "SCT",
    "StopCombat",
    "StopScript",
    "StopSound",
    "StreamMusic",
    "TestCells",
    "TestInteriorCells",
    "TestModels",
    "T3D",
    "TestThreadCells",
    "ToggleAI",
    "TAI",
    "ToggleBorders",
    "TB",
    "ToggleCollision",
    "TCL",
    "ToggleCollisionBoxes",
    "TCB",
    "ToggleCollisionGrid",
    "TCG",
    "ToggleCombatStats",
    "TCS",
    "ToggleDebugText",
    "TDT",
    "ToggleDialogueStats",
    "TDS",
    "ToggleFogOfWar",
    "TFOW",
    "ToggleFullHelp",
    "TFH",
    "ToggleGodMode",
    "TGM",
    "ToggleGrid",
    "TG",
    "ToggleKillStats",
    "TKS",
    "ToggleLights",
    "TL",
    "ToggleLoadFade",
    "TLF",
    "ToggleMagicStats",
    "TMS",
    "ToggleMenus",
    "TM",
    "TogglePathGrid",
    "TPG",
    "ToggleScriptOutput",
    "TSO",
    "ToggleScripts",
    "ToggleSky",
    "TS",
    "ToggleStats",
    "TST",
    "ToggleTextureString",
    "TTS",
    "ToggleVanityMode",
    "TVM",
    "ToggleWater",
    "TWA",
    "ToggleWireframe",
    "TWF",
    "ToggleWorld",
    "TW",
    "TurnMoonRed",
    "TurnMoonWhite",
    "UndoWerewolf",
    "Unlock",
    "UsedOnMe",
    "WakeUpPC",
    "While",
    "XBox",
    "Year"
}

data.objectType = {
	["alchemy"] = tes3.objectType.alchemy,
	["ammunition"] = tes3.objectType.ammunition,
	["apparatus"] = tes3.objectType.apparatus,
	["armor"] = tes3.objectType.armor,
	["book"] = tes3.objectType.book,
	["clothing"] = tes3.objectType.clothing,
	["ingredient"] = tes3.objectType.ingredient,
	["light"] = tes3.objectType.light,
	["lockpick"] = tes3.objectType.lockpick,
	["miscitem"] = tes3.objectType.miscItem,
	["probe"] = tes3.objectType.probe,
	["repairitem"] = tes3.objectType.repairItem,
	["weapon"] = tes3.objectType.weapon,
}

---@param text string
---@return table
function data.suggestItem(text)
    local suggestions = {}
    local midSuggestions = {}

    for index, value in ipairs(tes3.dataHandler.nonDynamicData.objects) do
        local isDynamicObject = false
        for key, objectType in pairs(data.objectType) do
            if (value.objectType == objectType) then
                isDynamicObject = true
                break
            end
        end
        if (isDynamicObject) then
            if (value.id:lower():startswith(text)) then
                table.insert(suggestions, value.id:lower():contains(" ") and ("\"" .. value.id .. "\"") or value.id)
            elseif (value.id:lower():contains(text)) then
                table.insert(midSuggestions, value.id:lower():contains(" ") and ("\"" .. value.id .. "\"") or value.id)
            end
        end
    end

    for index, value in ipairs(midSuggestions) do
        table.insert(suggestions, value)
    end

    return suggestions
end

---@param text string
---@param type tes3.objectType
local function suggestType(text, type)
    local suggestions = {}
    local midSuggestions = {}

    for index, value in ipairs(tes3.dataHandler.nonDynamicData.objects) do
        if (value.objectType == type) then
            if (value.id:lower():startswith(text)) then
                table.insert(suggestions, value.id:lower():contains(" ") and ("\"" .. value.id .. "\"") or value.id)
            elseif (value.id:lower():contains(text)) then
                table.insert(midSuggestions, value.id:lower():contains(" ") and ("\"" .. value.id .. "\"") or value.id)
            end
        end
    end

    for index, value in ipairs(midSuggestions) do
        table.insert(suggestions, value)
    end

    return suggestions
end

---@param text string
---@return table
function data.suggestCreature(text)
    return suggestType(text, tes3.objectType["creature"])
end

---@param text string
---@return table
function data.suggestSoulGem(text)
    local suggestions = {}
    local midSuggestions = {}

    for index, value in ipairs(tes3.dataHandler.nonDynamicData.objects) do
        if (value.objectType == tes3.objectType["miscItem"] and value.soulGemData) then
            if (value.id:lower():startswith(text)) then
                table.insert(suggestions, value.id:lower():contains(" ") and ("\"" .. value.id .. "\"") or value.id)
            elseif (value.id:lower():contains(text)) then
                table.insert(midSuggestions, value.id:lower():contains(" ") and ("\"" .. value.id .. "\"") or value.id)
            end
        end
    end

    for index, value in ipairs(midSuggestions) do
        table.insert(suggestions, value)
    end

    return suggestions
end

---@param text string
---@return table
function data.suggestSpell(text)
    return suggestType(text, tes3.objectType["spell"])
end

---@param text string
---@return table
function data.suggestLvlCreature(text)
    return suggestType(text, tes3.objectType["leveledCreature"])
end

---@param text string
---@return table
function data.suggestLvlItem(text)
    return suggestType(text, tes3.objectType["leveledItem"])
end

---@param text string
---@return table
function data.suggestTopic(text)
    return suggestType(text, tes3.objectType["dialogue"])
end

---@param text string
---@return table
function data.suggestCell(text)
    local suggestions = {}
    local midSuggestions = {}

    for index, value in ipairs(tes3.dataHandler.nonDynamicData.cells) do
        if (value.id:lower():startswith(text)) then
            table.insert(suggestions, value.id:lower():contains(" ") and ("\"" .. value.id .. "\"") or value.id)
        elseif (value.id:lower():contains(text)) then
            table.insert(midSuggestions, value.id:lower():contains(" ") and ("\"" .. value.id .. "\"") or value.id)
        end
    end

    for index, value in ipairs(midSuggestions) do
        table.insert(suggestions, value)
    end

    return suggestions
end

---@param text string
---@return table
function data.suggestWeather(text)
    local suggestions = {}
    local midSuggestions = {}

    for key, value in pairs(tes3.weather) do
        if (key:lower():startswith(text)) then
            table.insert(suggestions, key:lower():contains(" ") and ("\"" .. key .. "\"") or key)
        elseif (key:lower():contains(text)) then
            table.insert(midSuggestions, key:lower():contains(" ") and ("\"" .. key .. "\"") or key)
        end
    end

    for index, value in ipairs(midSuggestions) do
        table.insert(suggestions, value)
    end

    return suggestions
end

---@param text string
---@param mobile tes3mobileActor
---@return table
local function suggestInventory(text, mobile)
    local suggestions = {}
    local midSuggestions = {}

    for index, value in ipairs(mobile.inventory) do
        if (value.object.id:lower():startswith(text)) then
            table.insert(suggestions, value.object.id:lower():contains(" ") and ("\"" .. value.object.id .. "\"") or value.object.id)
        elseif (value.object.id:lower():contains(text)) then
            table.insert(midSuggestions, value.object.id:lower():contains(" ") and ("\"" .. value.object.id .. "\"") or value.object.id)
        end
    end

    for index, value in ipairs(midSuggestions) do
        table.insert(suggestions, value)
    end

    return suggestions
end

---@param text string
---@return table
function data.suggestInvPlayer(text)
    return suggestInventory(text, tes3.mobilePlayer)
end

---@param text string
---@param reference tes3reference
---@return table
function data.suggestInvActor(text, reference)
    if (reference) then
        return suggestInventory(text, reference.mobile)
    else
        return {}
    end
end

---@param text string
---@return table
function data.suggestRegion(text)
    return suggestType(text, tes3.objectType["region"])
end

---@param text string
---@return table
function data.suggestESP(text)
    local suggestions = {}
    local midSuggestions = {}

    for index, value in ipairs(tes3.getModList()) do
        if (value.id:lower():startswith(text)) then
            table.insert(suggestions, value.id:lower():contains(" ") and ("\"" .. value.id .. "\"") or value.id)
        elseif (value.id:lower():contains(text)) then
            table.insert(midSuggestions, value.id:lower():contains(" ") and ("\"" .. value.id .. "\"") or value.id)
        end
    end

    for index, value in ipairs(midSuggestions) do
        table.insert(suggestions, value)
    end

    return suggestions
end

---@param text string
---@return table
function data.suggestJournal(text)
    local suggestions = suggestType(text, tes3.objectType["dialogueInfo"])
    local newSuggestions = {}

    ---@param value tes3dialogueInfo
    for index, value in ipairs(suggestions) do
        if (value.type == tes3.dialogueType["journal"]) then
            table.insert(newSuggestions)
        end
    end

    return newSuggestions
end

---@param text string
---@return table
function data.suggestSound(text)
    return suggestType(text, tes3.objectType["sound"])
end

---@param text string
---@return table
function data.suggestAnimation(text)
    local suggestions = {}
    local midSuggestions = {}

    for key, value in pairs(tes3.animationGroup) do
        if (key:lower():startswith(text)) then
            table.insert(suggestions, key:lower():contains(" ") and ("\"" .. key .. "\"") or key)
        elseif (key:lower():contains(text)) then
            table.insert(midSuggestions, key:lower():contains(" ") and ("\"" .. key .. "\"") or key)
        end
    end

    for index, value in ipairs(midSuggestions) do
        table.insert(suggestions, value)
    end

    return suggestions
end

---@param text string
---@return table
function data.suggestEffect(text)
    local suggestions = {}
    local midSuggestions = {}

    for key, value in pairs(tes3.effect) do
        if (key:lower():startswith(text)) then
            table.insert(suggestions, key:lower():contains(" ") and ("\"" .. key .. "\"") or key)
        elseif (key:lower():contains(text)) then
            table.insert(midSuggestions, key:lower():contains(" ") and ("\"" .. key .. "\"") or key)
        end
    end

    for index, value in ipairs(midSuggestions) do
        table.insert(suggestions, value)
    end

    return suggestions
end

---@param text string
---@return table
function data.suggestScript(text)
    return suggestType(text, tes3.objectType["script"])
end

---@param text string
---@return table
function data.suggestVariable(text)
    local suggestions = {}
    local midSuggestions = {}

    for index, value in ipairs(tes3.dataHandler.nonDynamicData.globals) do
        if (value:lower():startswith(text)) then
            table.insert(suggestions, (value:lower():contains(" ") and ("\"" .. value .. "\"") or value) .. " to")
        elseif (value:lower():contains(text)) then
            table.insert(midSuggestions, (value:lower():contains(" ") and ("\"" .. value .. "\"") or value) .. " to")
        end
    end

    for index, value in ipairs(midSuggestions) do
        table.insert(suggestions, value)
    end

    return suggestions
end

---@param text string
---@return table
function data.suggestVO(text)
    local suggestions = {}
    local midSuggestions = {}
    local voFiles = lfs.walkdir("Data Files/Sound/Vo/")

    for filePath, dir, fileName in voFiles() do
        if (fileName:lower():startswith(text)) then
            table.insert(suggestions, fileName:lower():contains(" ") and ("\"" .. fileName .. "\"") or fileName)
        elseif (fileName:lower():contains(text)) then
            table.insert(midSuggestions, fileName:lower():contains(" ") and ("\"" .. fileName .. "\"") or fileName)
        end
    end

    for index, value in ipairs(midSuggestions) do
        table.insert(suggestions, value)
    end

    return suggestions
end

---@param text string
---@return table
function data.suggestNPC(text)
    return suggestType(text, tes3.objectType["npc"])
end

---@param text string
---@return table
function data.suggestMusic(text)
    local suggestions = {}
    local midSuggestions = {}
    local voFiles = lfs.walkdir("Data Files/Music/")

    for filePath, dir, fileName in voFiles() do
        if (fileName:lower():startswith(text)) then
            table.insert(suggestions, fileName:lower():contains(" ") and ("\"" .. fileName .. "\"") or fileName)
        elseif (fileName:lower():contains(text)) then
            table.insert(midSuggestions, fileName:lower():contains(" ") and ("\"" .. fileName .. "\"") or fileName)
        end
    end

    for index, value in ipairs(midSuggestions) do
        table.insert(suggestions, value)
    end

    return suggestions
end

---@param text string
---@return table
function data.suggestCreatureNPC(text)
    local suggestions = data.suggestNPC(text)

    for index, value in ipairs(data.suggestCreature(text)) do
        table.insert(suggestions, value)
    end

    return suggestions
end

---@param text string
---@return table
function data.suggestEquip(text)
    local suggestions = suggestType(text, tes3.objectType["armor"])

    for index, value in ipairs(suggestType(text, tes3.objectType["clothing"])) do
        table.insert(suggestions, value)
    end

    for index, value in ipairs(suggestType(text, tes3.objectType["lockpick"])) do
        table.insert(suggestions, value)
    end

    for index, value in ipairs(suggestType(text, tes3.objectType["probe"])) do
        table.insert(suggestions, value)
    end

    for index, value in ipairs(suggestType(text, tes3.objectType["repairItem"])) do
        table.insert(suggestions, value)
    end

    for index, value in ipairs(suggestType(text, tes3.objectType["weapon"])) do
        table.insert(suggestions, value)
    end

    return suggestions
end

---@param text string
---@return table
function data.suggestObject(text)
    local suggestions = {}
    local midSuggestions = {}

    for index, value in ipairs(tes3.dataHandler.nonDynamicData.objects) do
        if (value.id:lower():startswith(text)) then
            table.insert(suggestions, value.id:lower():contains(" ") and ("\"" .. value.id .. "\"") or value.id)
        elseif (value.id:lower():contains(text)) then
            table.insert(midSuggestions, value.id:lower():contains(" ") and ("\"" .. value.id .. "\"") or value.id)
        end
    end

    for index, value in ipairs(midSuggestions) do
        table.insert(suggestions, value)
    end

    return suggestions
end

---@param text string
---@return table
function data.suggestFaction(text)
    local suggestions = {}
    local midSuggestions = {}

    for index, value in ipairs(tes3.dataHandler.nonDynamicData.factions) do
        if (value.id:lower():startswith(text)) then
            table.insert(suggestions, value.id:lower():contains(" ") and ("\"" .. value.id .. "\"") or value.id)
        elseif (value.id:lower():contains(text)) then
            table.insert(midSuggestions, value.id:lower():contains(" ") and ("\"" .. value.id .. "\"") or value.id)
        end
    end

    for index, value in ipairs(midSuggestions) do
        table.insert(suggestions, value)
    end

    return suggestions
end

---@param text string
---@return table
function data.suggestRace(text)
    local suggestions = {}
    local midSuggestions = {}

    for index, value in ipairs(tes3.dataHandler.nonDynamicData.races) do
        if (value.id:lower():startswith(text)) then
            table.insert(suggestions, value.id:lower():contains(" ") and ("\"" .. value.id .. "\"") or value.id)
        elseif (value.id:lower():contains(text)) then
            table.insert(midSuggestions, value.id:lower():contains(" ") and ("\"" .. value.id .. "\"") or value.id)
        end
    end

    for index, value in ipairs(midSuggestions) do
        table.insert(suggestions, value)
    end

    return suggestions
end

---@param text string
---@return table
function data.suggestWeapon(text)
    return suggestType(text, tes3.objectType["weapon"])
end

---@param text string
---@param reference tes3reference
---@return table
function data.suggestSpellActor(text, reference)
    local suggestions = {}
    local midSuggestions = {}

    for index, value in ipairs(tes3.getSpells{target = reference}) do
        if (value.id:lower():startswith(text)) then
            table.insert(suggestions, value.id:lower():contains(" ") and ("\"" .. value.id .. "\"") or value.id)
        elseif (value.id:lower():contains(text)) then
            table.insert(midSuggestions, value.id:lower():contains(" ") and ("\"" .. value.id .. "\"") or value.id)
        end
    end

    for index, value in ipairs(midSuggestions) do
        table.insert(suggestions, value)
    end

    return suggestions
end

return data