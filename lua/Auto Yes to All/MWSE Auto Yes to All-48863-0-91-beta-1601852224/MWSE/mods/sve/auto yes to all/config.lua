local config = mwse.loadConfig("auto yes to all")
local base = {
      acceptMessageTrailer = "[ Auto ^buttonText ]", -- ^buttonText inserts "Yes" or "Yes to All"
      autoYesToAllLoadErrors = true,
      autoYesToAllGamePrompts = true,
      displayMessages = true, -- with stripped Yes/No/Yes to All prompt
      loadErrorTextSubStrings = {
	 [".*"] = false,
	 [tes3.findGMST("sInvalidSaveGameMsg").value] = true,
	 [tes3.findGMST("sLoadingErrorsMsg").value] = true,
	 [tes3.findGMST("sMissingMastersMsg").value] = true,
	 [tes3.findGMST("sChangedMastersMsg").value] = true,
	 [tes3.findGMST("sMastPlugMismatchMsg").value] = true,
	 [tes3.findGMST("sGeneralMastPlugMismatchMsg").value] = true,
	 ["Could not locate global script"] = true, -- why is this not a GMST?.. what others [] = may be  missing?..
	 ["Load Error"] = true,
	 ["Continue running executable?"] = true,
      },
      gamePromptTextSubStrings = {
-- 	 note: this list is neither totally necessary or sufficient, add/delete as preferred:
	 [".*"] = false,
	 [tes3.findGMST("sRestIllegal").value] = true,
	 [tes3.findGMST("sSaveGameDenied").value] = true,
	 [tes3.findGMST("sSaveGameFailed").value] = true,
	 [tes3.findGMST("sMaximumSaveGameMessage").value] = true,
	 [tes3.findGMST("sCreateClassMenuWarning").value] = true,
	 [tes3.findGMST("sNotifyMessage1").value] = true,
	 [tes3.findGMST("sNotifyMessage2").value] = true,
	 [tes3.findGMST("sNotifyMessage3").value] = true,
	 [tes3.findGMST("sNotifyMessage5").value] = true,
	 [tes3.findGMST("sNotifyMessage6").value] = true,
	 [tes3.findGMST("sNotifyMessage6a").value] = true,
	 [tes3.findGMST("sNotifyMessage7").value] = true,
	 [tes3.findGMST("sNotifyMessage8").value] = true,
	 [tes3.findGMST("sNotifyMessage9").value] = true,
	 [tes3.findGMST("sNotifyMessage10").value] = true,
	 [tes3.findGMST("sNotifyMessage11").value] = true,
	 [tes3.findGMST("sNotifyMessage12").value] = true,
	 [tes3.findGMST("sNotifyMessage13").value] = true,
	 [tes3.findGMST("sNotifyMessage14").value] = true,
	 [tes3.findGMST("sNotifyMessage15").value] = true,
	 [tes3.findGMST("sNotifyMessage16").value] = true,
	 [tes3.findGMST("sNotifyMessage16_a").value] = true,
	 [tes3.findGMST("sNotifyMessage17").value] = true,
	 [tes3.findGMST("sNotifyMessage18").value] = true,
	 [tes3.findGMST("sNotifyMessage19").value] = true,
	 [tes3.findGMST("sNotifyMessage20").value] = true,
	 [tes3.findGMST("sNotifyMessage21").value] = true,
	 [tes3.findGMST("sNotifyMessage22").value] = true,
	 [tes3.findGMST("sNotifyMessage23").value] = true,
	 [tes3.findGMST("sNotifyMessage23").value] = true,
	 [tes3.findGMST("sNotifyMessage24").value] = true,
	 [tes3.findGMST("sNotifyMessage25").value] = true,
	 [tes3.findGMST("sNotifyMessage26").value] = true,
	 [tes3.findGMST("sNotifyMessage27").value] = true,
	 [tes3.findGMST("sNotifyMessage28").value] = true,
	 [tes3.findGMST("sNotifyMessage29").value] = true,
	 [tes3.findGMST("sNotifyMessage30").value] = true,
	 [tes3.findGMST("sNotifyMessage31").value] = true,
	 [tes3.findGMST("sNotifyMessage32").value] = true,
	 [tes3.findGMST("sNotifyMessage33").value] = true,
	 [tes3.findGMST("sNotifyMessage34").value] = true,
	 [tes3.findGMST("sNotifyMessage35").value] = true,
	 [tes3.findGMST("sNotifyMessage36").value] = true,
	 [tes3.findGMST("sNotifyMessage37").value] = true,
	 [tes3.findGMST("sNotifyMessage38").value] = true,
	 [tes3.findGMST("sNotifyMessage39").value] = true,
	 [tes3.findGMST("sNotifyMessage40").value] = true,
	 [tes3.findGMST("sNotifyMessage41").value] = true,
	 [tes3.findGMST("sNotifyMessage42").value] = true,
	 [tes3.findGMST("sNotifyMessage43").value] = true,
	 [tes3.findGMST("sNotifyMessage44").value] = true,
	 [tes3.findGMST("sNotifyMessage45").value] = true,
	 [tes3.findGMST("sNotifyMessage46").value] = true,
	 [tes3.findGMST("sNotifyMessage47").value] = true,
	 [tes3.findGMST("sNotifyMessage48").value] = true,
	 [tes3.findGMST("sNotifyMessage49").value] = true,
	 [tes3.findGMST("sNotifyMessage50").value] = true,
	 [tes3.findGMST("sNotifyMessage51").value] = true,
	 [tes3.findGMST("sNotifyMessage52").value] = true,
	 [tes3.findGMST("sNotifyMessage53").value] = true,
	 [tes3.findGMST("sNotifyMessage54").value] = true,
	 [tes3.findGMST("sNotifyMessage64").value] = true,
	 [tes3.findGMST("sNotifyMessage65").value] = true,
	 [tes3.findGMST("sNotifyMessage66").value] = true,
	 [tes3.findGMST("sNotifyMessage67").value] = true,
	 [tes3.findGMST("sWerewolfRefusal").value] = true,
	 [tes3.findGMST("sWerewolfRestMessage").value] = true,
	 [tes3.findGMST("sWerewolfAlarmMessage").value] = true,
	 [tes3.findGMST("sLoadLastSaveMsg").value] = true,
	 [tes3.findGMST("sMessage1").value] = true,
	 [tes3.findGMST("sMessage2").value] = true,
	 [tes3.findGMST("sMessage3").value] = true,
	 [tes3.findGMST("sMessage4").value] = true,
	 [tes3.findGMST("sMessage5").value] = true,
	 [tes3.findGMST("sInventoryMenu1").value] = true,
	 [tes3.findGMST("sLevelUpMenu1").value] = true,
	 [tes3.findGMST("sLevelUpMenu2").value] = true,
	 [tes3.findGMST("sRestMenu4").value] = true,
	 [tes3.findGMST("sServiceTrainingWords").value] = true,
	 [tes3.findGMST("sKilledEssential").value] = true,
	 [tes3.findGMST("sPotionSuccess").value] = true,
	 [tes3.findGMST("sSaveMenuHelp06").value] = true,
	 [tes3.findGMST("sDeleteNote").value] = true,
	 [tes3.findGMST("sQuestionDeleteSpell").value] = true,
	 [tes3.findGMST("sDeleteSpellError").value] = true,
	 [tes3.findGMST("sSetValueMessage01").value] = true,
	 [tes3.findGMST("sVideoWarning").value] = true,
	 [tes3.findGMST("sResChangeWarning").value] = true,
	 [tes3.findGMST("sInventorySelectNoItems").value] = true,
	 [tes3.findGMST("sInventorySelectNoSoul").value] = true,
	 [tes3.findGMST("sInventorySelectNoIngredients").value] = true,
	 [tes3.findGMST("sDisposeCorpseFail").value] = true,
	 [tes3.findGMST("sSleepInterrupt").value] = true,
	 [tes3.findGMST("sMagicContractDisease").value] = true,
      },
}

if config == nil then
--mwse.log("config.lua: auto yes to all.json file not found, returning base")
   mwse.saveConfig("auto yes to all", base, { indent = true })
   return base
end

-- this is to avoid missing entries during development or accidentally user deleted
local modified = false
for key,_ in pairs(base) do
   if config[key] == nil then
      modified = true
      config[key] = base[key]
--mwse.log("config.lua: config[" .. tostring(key) .. "] MISSING, assign as base")
   end
end

if modified then
   mwse.saveConfig("auto yes to all", config)
end
return config

