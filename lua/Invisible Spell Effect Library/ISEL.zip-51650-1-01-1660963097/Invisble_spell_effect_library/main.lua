local version = "1.01"
--Utility variables
local schoolNames = {}
local diffMode = {player = 1, repo = 2}
local knownEffectsList = {}
local bookText
local spellWasPurchased = false
--Config related variables
local configPath = "isel.config"
local config = mwse.loadConfig(configPath)
if not config then
    config = {}
end

local function initialized()
    mwse.log("Invisible Spell Effect Library Initialized version " .. version)
    schoolNames = { [0]=tes3.findGMST(tes3.gmst.sSchoolAlteration).value,
                        [1]=tes3.findGMST(tes3.gmst.sSchoolConjuration).value,
                        [2]=tes3.findGMST(tes3.gmst.sSchoolDestruction).value,
                        [3]=tes3.findGMST(tes3.gmst.sSchoolIllusion).value,
                        [4]=tes3.findGMST(tes3.gmst.sSchoolMysticism).value,
                        [5]=tes3.findGMST(tes3.gmst.sSchoolRestoration).value,
                        [6]="None"
                    }

end
event.register(tes3.event.initialized, initialized)

--Gets unique spell effects from a given list of spells.
--Only counts them if they can be used in spellmaking or echanting, otherwise no point.
---@param sl tes3spellList
local function getKnownEffectsFromSpellList(sl)
    local effectList = {}
    local effObj
    if sl == nil then return effectList end
    ---@param spell tes3spell
    for k,spell in pairs(sl) do
        ---@param effect tes3effect
        for e,effect in pairs(spell.effects) do
            if effect.object
            then
                effObj = effect.object
                if effectList[effObj.name] == nil and (effObj.allowEnchanting == true or effObj.allowSpellmaking == true)
                then effectList[effObj.name] = {id = effObj.id,name = effObj.name,school = effObj.school}
                end
            end
        end
    end
    return effectList
end

--Generate the displayed text in the spellbook
--FUTURE ENHANCEMENT? See if you can make it auto flow better so there's fewer schools crossing page breaks at weird places
local function generateSpellBookText()

    local effects = knownEffectsList --getKnownEffectsFromSpellList(tes3.player.object.spells)
    local schoolEffects = {}
    local customEffects = {}
    local header = '<DIV ALIGN="CENTER"><FONT COLOR="000000" SIZE="3" FACE="Magic Cards"><BR>\n'
    bookText = header
    local schoolText = ''
    for schoolID,name in pairs(schoolNames) do
        schoolEffects = {}
        if schoolID == 0 then
            schoolText = name .. '</FONT><BR>\n<DIV ALIGN="LEFT"><FONT SIZE="2">'
        elseif schoolID == 6 then
            schoolText = '<DIV ALIGN="CENTER"><FONT SIZE="3"><BR>\n' .. 'No School' .. '</FONT><BR>\n<DIV ALIGN="LEFT"><FONT SIZE="2">'
        else
            schoolText = '<DIV ALIGN="CENTER"><FONT SIZE="3"><BR>\n' .. name .. '</FONT><BR>\n<DIV ALIGN="LEFT"><FONT SIZE="2">'
        end
        for i,effectTab in pairs(effects) do
            --Check if a built in or custom effect.  Custom effects go at the end
            if effectTab.school == schoolID and effectTab.id <= tes3.effect.sEffectSummonCreature05
            then
                table.insert(schoolEffects,effectTab.name)
            elseif effectTab.school == schoolID and effectTab.id > tes3.effect.sEffectSummonCreature05
            then

                table.insert(customEffects,effectTab.name)
            end
        end
          if #schoolEffects > 0 then
            table.sort(schoolEffects)
            for i,effectName in ipairs(schoolEffects) do
                schoolText = schoolText .. '<BR>\n' .. effectName
            end
            schoolText = schoolText .. '</FONT><BR>\n'
            bookText = bookText .. schoolText
        end
    end
    if #customEffects > 0
    then
        schoolText = '<DIV ALIGN="CENTER"><FONT SIZE="3"><BR>\n' .. "Esoterica" .. '</FONT><BR>\n<DIV ALIGN="LEFT"><FONT SIZE="2">'
        table.sort(customEffects)
        for i,effectName in ipairs(customEffects) do
            schoolText = schoolText .. '<BR>\n' .. effectName
        end
        schoolText = schoolText .. '</FONT><BR>\n'
        bookText = bookText .. schoolText

    end
    bookText = bookText .. '<BR>'

    return bookText
end

--If the player knows any qualifying spells and doesn't yet have the spell book, give them the spellbook.
--Returns bool indicating whether or not a spellbook was actually added
local function createSpellBook()
    if table.size(knownEffectsList) > 0 and tes3.getItemCount({reference = tes3.player, item = "isel_known_effects" }) == 0
    then
        tes3.addItem({ reference = tes3.player, item = "isel_known_effects", count = 1, playSound = false })
        return true
    else
        return false
    end
end

--[[Takes two lists of effects and compares them.  Based on mode returns either
--diffMode.player == Return effects in iselrepo that aren't in player
--diffMode.repo == Return effects in player that aren't in iselrepo]]
--Currently unused but I might want it back if I revamp the new effect portion should a spellAdded event come to exist, so leaving it
local function getEffectsMissingFrom(mode, playerList, iselList)
    local diffList = {}
    if mode == diffMode.player
    then
        for k,v in pairs(iselList) do
            if playerList[v.name] == nil then diffList[v.name] = v end
        end
    elseif mode == diffMode.repo
    then
        for k,v in pairs(playerList) do
            if iselList[v.name] == nil then diffList[v.name] = v end
        end
    else return nil
    end
    return diffList
end

--Checks known effects list for any custom effects associated with mods that no longer exist and removes them.
local function cleanModdedEffects()
    for k, effect in pairs(knownEffectsList) do
        --I believe this to be safe when using pairs
        if tes3.getMagicEffect(effect.id) == nil then knownEffectsList[k] = nil end
    end
end

--Adds any effects in the player list not in the knownEffectsList table (player.data["isel_repo"]) to the knownEffectsList
local function buildKnownEffects()
    local playerEffects = getKnownEffectsFromSpellList(tes3.player.object.spells)
    for i,effect in pairs(playerEffects) do
        if knownEffectsList[effect.name] == nil
        then
            knownEffectsList[effect.name] = effect
        end
    end

    if config["auto_generate_spellbook"] == true then createSpellBook() end
    if tes3.getItemCount({reference = tes3.player, item = "isel_known_effects" }) > 0 then generateSpellBookText() end
end

local function saveFileLoaded(e)

    --If no spell effect list has been built for this save, create an empty spell effect list in player.data
    if(tes3.player.data["isel_repo"]) == nil then tes3.player.data["isel_repo"] = {} end
    knownEffectsList = tes3.player.data["isel_repo"]

    --if the book object does not exist in this save game, create it
    if tes3.getObject("isel_known_effects") == nil
    then
        local bookID = "isel_known_effects"
        local bookName = "Your Spellbook"
        local newBook = tes3.createObject({
            objectType = tes3.objectType.book,
            id = bookID,
            name = bookName,
            mesh = [[m\text_octavo_05.nif]],
            icon = [[M\tx_book_04.tga]]
        })
    end

    --In case the player removed custom effect mods since last load
    cleanModdedEffects() 
    --Mostly only useful if this is the first time the save is loaded after newly installing the mod, or the player
    --learned a spell via non vendor means (modded grimoires, quests, etc) and hasn't otherwise triggered a rebuild.
    buildKnownEffects()

end
event.register(tes3.event.loaded, saveFileLoaded)

--Catch when a book is opened.  If it's the ISEL spellbook, display the list of known effects
---@param e bookGetTextEventData
local function getSpellBookText(e)
    if e.book.id == "isel_known_effects"
    then
        e.text = bookText
    end
end
event.register(tes3.event.bookGetText, getSpellBookText)


--FUTURE ENHANCEMENT? Does not work if the spell list is entirely empty, cant copy properties from first element if there's no elements
--[[If SpellMaking or Enchament menu is activated, scans the children of the Magic Effects pane for all effects and compares to known
effects list.  Any known effects not in list are added into list as new TextSelect widgets, and callbacks for handling click
and help events copied from first item in list so that they are handled as normal.  Sort list and update UI.--]]
--- @param e uiActivatedEventData
local function onMenuActivated(e)
    if (e.newlyCreated) then
        --e.element:registerBefore("destroy", onMenuDeactivated)
        local effectLyt = {}
        local propertyName
        if e.element.name == "MenuSpellmaking"
        then
            effectLyt = e.element:findChild("MenuSpellmaking_EffectsScroll"):getContentElement()
            propertyName = "MenuSpellmaking_Effect"
        elseif e.element.name == "MenuEnchantment"
        then
            effectLyt = e.element:findChild("MenuEnchantment_EffectsScroll"):getContentElement()
            propertyName = "MenuEnchantment_Effect"
        --Really shouldn't ever hit this else based on filter in register, but just in case...
        else return
        end
        local effect1 = effectLyt.children[1]
        local startingEffects = {}
        local tmpEffect
        local tmpTextWidget
        for i, effectEntry in pairs(effectLyt.children) do
            startingEffects[effectEntry.text] = effectEntry.text
        end
        for i, knownEffect in pairs(knownEffectsList) do
            if startingEffects[knownEffect.name] == nil
            then
                tmpEffect = tes3.getMagicEffect(knownEffect.id)
                tmpTextWidget = effectLyt:createTextSelect({text = tmpEffect.name})
                tmpTextWidget:setPropertyObject(propertyName,tmpEffect)
                tmpTextWidget:setPropertyCallback("click",effect1:getPropertyCallback("click"))
                tmpTextWidget:setPropertyCallback("help",effect1:getPropertyCallback("help"))
            end
        end
        effectLyt:sortChildren(function(k1,k2) return k1.text < k2.text end  )
        if e.element.name == "MenuSpellmaking" then tes3ui.updateSpellmakingMenu()
        elseif e.element.name == "MenuEnchantment" then tes3ui.updateEnchantingMenu()
        end
    end
end

event.register(tes3.event.uiActivated, onMenuActivated, { filter = "MenuSpellmaking" })
event.register(tes3.event.uiActivated, onMenuActivated, { filter = "MenuEnchantment" })

--[[Used to do a lot, when I needed to get individual purchased spells, but now that code exists to just
pull all the effects needed to sync from the player spell list, and there is a potential need to sync whenever a spell is
purchased in case spells were obtained by other means currently undetectable, now simply sets a flag so that a full sync will be done
when the spell service menu is closed.   This will be rejiggered if an event for spell added to spell list is added--]]
---@param e tes3uiEventData
local function getPurchasedSpell(e)
    --if e.source:getPropertyBool("isel_has_new_effect") == true
    --then
        spellWasPurchased = true
    --end    
end

--When spell service menu closed, check if any spells were purchased. If so, run effect list build
--- @param e uiEventEventData
local function onSpellServiceDeactivated(e)
    if spellWasPurchased == true
    then
        buildKnownEffects()
    end
    spellWasPurchased = false
    

end

--When spell service menu is opened, register click callback on all spells so that purchase flag can be set.
--If new effect annotation is enabled, will * any spells that contain unlearned effectsI shunted
--- @param e uiActivatedEventData
local function onSpellServiceActivate(e)
    if (e.newlyCreated) then
        e.element:registerBefore("destroy", onSpellServiceDeactivated)
        local slist = e.element:findChild("MenuServiceSpells_ServiceList"):getContentElement()
        local spellObj
        local hasNewEffect = false
        for i,spell in pairs(slist.children) do
            spell:registerBefore("mouseClick",getPurchasedSpell)
            spellObj = spell:getPropertyObject("MenuServiceSpells_Spell")
            ---@param v tes3effect
            for k,v in ipairs(spellObj.effects) do
                if v.object ~= nil
                then
                    if knownEffectsList[v.object.name] == nil
                    then
                        hasNewEffect = true
                    end
                end
            end
            if hasNewEffect == true
            then
                spell:setPropertyBool("isel_has_new_effect",true)
                if config["indicate_vendor_new_effects"] == true then spell.text = spell.text .. "*" end
                hasNewEffect = false
            else
                spell:setPropertyBool("isel_has_new_effect",false)
            end

         end
    end
end
event.register(tes3.event.uiActivated, onSpellServiceActivate, { filter = "MenuServiceSpells" })

--Build the mod config menu
local function registerModConfig()
    EasyMCM = require("easyMCM.EasyMCM")
    local template = EasyMCM.createTemplate("Invisible Spell Effect Library")
    template:saveOnClose(configPath, config)
    local page = template:createSideBarPage()

    local toolsCat = page:createCategory("Tools")
    toolsCat:createButton{
        buttonText = "Sync Effects",
        description = "Manually syncs any new spell effects from your spell list to the effect repository.",
        inGameOnly = true,
        callback = (function(self)

                        buildKnownEffects()
                        tes3.messageBox({message = "Effects synced"})
                    end
                    )
    }
    toolsCat:createButton{
        buttonText = "I lost my spell book.",
        description = "Gives you another effects spellbook. If you actually need one.",
        inGameOnly = true,
        callback = (function(self)

                        if createSpellBook() == true
                        then
                            tes3.messageBox({message = "Sigh. Try to keep better track of this one.", duration = 5})
                        else
                            tes3.messageBox({message = "No you didn't.", duration = 5})
                        end

                    end
                    )
    }

    local globalCategory = page:createCategory("Settings")
    globalCategory:createYesNoButton{
        label = "Autogenerate effects spellbook",
        description = "If you don't possess an effects spellbook, will automatically generate one upon loading save or learning a new spell effect.\n"
                     .. "Setting does not affect manual spellbook creation button above.",
        variable = EasyMCM.createTableVariable{
            id = "auto_generate_spellbook",
            table = config,
            defaultSetting = true
            },
    }

    globalCategory:createYesNoButton{
        label = "Indicate vendor spells with new effects?",
        description = "When in vendor spell menu, marks any spells that contain an unlearned spell with an *.",
        variable =  EasyMCM.createTableVariable{
            id = "indicate_vendor_new_effects",
            table = config,
            defaultSetting = true
        },
    }

    EasyMCM.register(template)

end
event.register("modConfigReady",registerModConfig)
