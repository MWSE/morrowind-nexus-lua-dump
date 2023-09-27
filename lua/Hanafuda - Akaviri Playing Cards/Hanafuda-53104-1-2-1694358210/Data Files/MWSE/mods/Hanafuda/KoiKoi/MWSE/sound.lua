local logger = require("Hanafuda.logger")
local config = require("Hanafuda.config")

---@class KoiKoi.Sound
local this = {}

-- todo instance

local soundData = require("Hanafuda.KoiKoi.soundData")

this.se = soundData.se
this.voice = soundData.voice
this.music = soundData.music

---@param t table
---@param excluding integer?
---@return integer?
local function GetRandomIndex(t, excluding)
    if t then
        local size = table.size(t)
        if size > 1 then
            -- If excluding is specified, the excluding index is considered the last index. So the total number is one less.
            local newsize = size
            if excluding ~= nil then
                newsize = newsize - 1
            end
            local index = math.random(newsize)
            if index == excluding then
                index = size
            end
            return index
        elseif size == 1 then
            return 1
        end
    end
    return nil
end

---@param id KoiKoi.SoundEffectId
function this.Play(id)
    local data = soundData.soundData[id]
    -- todo mixchannel fader
    -- todo reference if 3D
    if data then
        -- tes3.playSound performs 3D audio with references, so it crashes when used in the main menu because of no references exist.
        -- but play using soundPath is only tes3.playSound, tes3sound only data loaded by esm, esp.
        if not tes3.onMainMenu() and data.soundPath and table.size(data.soundPath) > 0 then
            local path = table.choice(data.soundPath) ---@type string
            local pitch = 1
            -- Fluctuation to create variation
            -- perhaps normal distribution is better
            pitch = pitch + (math.random() * 0.2 - 0.1)
            logger:trace("SE %d : %s", id, path)
            tes3.playSound({ soundPath = path, mixChannel = tes3.soundMix.effects, volume = data.volume or 1, pitch = pitch })
        elseif data.sound then
            -- todo tes3.playSound version when 3D
            local se = tes3.getSound(data.sound) -- todo cache?
            if se then
                se:play(nil, data.volume or 1)
            else
                logger:warn("wrong sound id: ".. tostring(data.sound))
            end
        else
            logger:warn("invalid sound data: ".. tostring(id))
        end
    else
        logger:warn("invalid sound ID: ".. tostring(id))
    end
end

-- The dialogue corresponding to the opponent's race is not taken into account.
---@param id KoiKoi.VoiceId
---@param reference tes3reference
---@param race string
---@param female boolean
---@param disposition number? Mutual disposition
---@param excluding integer?
---@return integer?
local function PlayVoice(id, reference, race, female, disposition, excluding)
    if not tes3.onMainMenu() then
        local r = soundData.voiceData[string.lower(race)]
        if not r then
            return nil
        end
        local s = r[female and "f" or "m"]
        if not s then
            return nil
        end
        local voice = s[id]
        local index = GetRandomIndex(voice, excluding)
        if index ~= nil then
            local path = voice[index]
            logger:debug("Voice %d : %d %s", id, index, path)
            tes3.removeSound({ reference = reference })
            tes3.say({ reference = reference, soundPath = path })
            return index
        end
    end
    return nil
end

---@param id KoiKoi.VoiceId
---@param reference tes3reference
---@param objectId string
---@param special {[string] : {[KoiKoi.VoiceId] : string[]}} id, VoiceId, file excluding directory
---@param disposition number? Mutual disposition
---@param excluding integer?
---@return integer?
local function PlaySpecialVoice(id, reference, objectId, special, disposition, excluding)
    if special then
        local sp = special[objectId]
        if sp then
            local voice = sp[id]
            local index = GetRandomIndex(voice, excluding)
            if index ~= nil then
                local path = voice[index]
                logger:debug("Special Voice %d %s : %d %s", id, objectId, index, path)
                tes3.removeSound({ reference = reference })
                tes3.say({ reference = reference, soundPath = path })
                return index
            end
        end
    end
    return nil
end

---@param id KoiKoi.VoiceId
---@param creatureId string?
---@return nil
local function PlaySoundGenerator(id, creatureId)
    local data = require("Hanafuda.KoiKoi.MWSE.soundGenData").soundGenData[id]
    if creatureId and data then
        local gen = tes3.getSoundGenerator(creatureId, data.gen)
        if gen and gen.sound then
            -- TODO need removeSound?
            gen.sound:play()
            return nil -- There is only one voice assigned.
        end
    end
    return nil
end

---@param id KoiKoi.VoiceId
---@param mobile tes3mobileCreature|tes3mobileNPC|tes3mobilePlayer? -- todo use weak tes3reference or less dependency
---@param disposition number? Mutual disposition
---@param excluding integer?
---@return integer? -- random choice index
---@return boolean? -- special
function this.PlayVoice(id, mobile, disposition, excluding)
    if not tes3.onMainMenu() and mobile then
        logger:trace("PlayVoice %d %s", id, mobile.object.baseObject.id)

        local types = {
            [tes3.actorType.creature] =
            ---@param m tes3mobileCreature
            ---@return integer? -- random choice index
            ---@return boolean? -- special
            function(m)
                if not config.audio.npcVoice then
                    return nil, nil
                end
                local sp = PlaySpecialVoice(id, m.reference, m.object.baseObject.id, soundData.creatures, disposition, excluding)
                if sp ~= nil then
                    return sp, true
                end
                -- nil
                return PlaySoundGenerator(id, m.object.baseObject.id), false
            end,
            [tes3.actorType.npc] =
            ---@param m tes3mobileNPC
            ---@return integer? -- random choice index
            ---@return boolean? -- special
            function(m)
                if not config.audio.npcVoice then
                    return nil, nil
                end
                local sp = PlaySpecialVoice(id, m.reference, m.object.baseObject.id, soundData.npcs, disposition, excluding)
                if sp ~= nil then
                    return sp, true
                end
                return PlayVoice(id, m.reference, m.object.race.id, m.object.female, disposition, excluding), false
            end,
            [tes3.actorType.player] =
            ---@param m tes3mobilePlayer
            ---@return integer? -- random choice index
            ---@return boolean? -- special
            function(m)
                if not config.audio.playerVoice then
                    return nil, nil
                end
                return PlayVoice(id, m.reference, m.object.race.id, m.object.female, disposition, excluding), false
            end,
        }
        if types[mobile.actorType] then
            return types[mobile.actorType](mobile)
        end
    end
    return nil, nil
end

---@param id KoiKoi.MusicId
function this.PlayMusic(id)
    local data = soundData.musicData[id]
    if data and data.path then
        tes3.streamMusic({ path = soundData.musicData[id].path })
    end
end


--- debugging
function this.CreateSoundPlayer()
    local menuid = "Hanafuda.SoundPlayer"
    local menu = tes3ui.findMenu(menuid)
    if menu then
        menu:destroy()
        tes3ui.leaveMenuMode()
        return
    end

    local params = {
        npc = {
            race = "dark elf",
            gender = "m",
            voiceId = "continue",
        },
        creature = {},
        spnpc = {},
        spcreature = {},
    }

    menu = tes3ui.createMenu({ id = menuid, fixedFrame = true })
    menu.autoWidth = true
    menu.autoHeight = true
    menu.minWidth = 560
    menu.minHeight = 400
    menu.flowDirection = tes3.flowDirection.topToBottom
    local root = menu:createBlock()
    root.widthProportional = 1
    root.heightProportional = 1
    root.autoWidth = true
    root.autoHeight = true
    root.flowDirection = tes3.flowDirection.topToBottom
    local header = root:createBlock()
    header.widthProportional = 1
    header.autoWidth = true
    header.autoHeight = true
    header.flowDirection = tes3.flowDirection.leftToRight

    local lheader = header:createBlock()
    lheader.autoWidth = true
    lheader.autoHeight = true
    lheader.flowDirection = tes3.flowDirection.leftToRight
    local rheader = header:createBlock()
    rheader.widthProportional = 1
    rheader.autoWidth = true
    rheader.autoHeight = true
    rheader.flowDirection = tes3.flowDirection.leftToRight
    rheader.childAlignX = 1
    local play = rheader:createButton({text ="Random Play"})

    ---@param path string
    local function PlayDebugVoice(path)
        if not tes3.onMainMenu() then
            tes3.playSound({ soundPath = path, mixChannel = tes3.soundMix.voice })
        end
        tes3.messageBox("'%s'", path)
    end

    local listid = "voicelist"
    play:register(tes3.uiEvent.mouseClick, function(e)
        local list = menu:findChild(listid)
        if list and list.getContentElement then
            local content = list:getContentElement()
            if content and content.children then
                local choice = table.choice(content.children) ---@type tes3uiElement
                -- or property
                PlayDebugVoice(choice.text)
            end
        end
     end)

    ---@param element tes3uiElement
    ---@param text string
    ---@return tes3uiElement
    local function CreateSelection(element, text)
        local b = element:createTextSelect({ text = text })
        b.borderAllSides = 4
        b.borderRight = 8
        return b
    end

    local parent = root:createBlock()
    parent.widthProportional = 1
    parent.heightProportional = 1
    parent.autoWidth = true
    parent.autoHeight = true
    parent.flowDirection = tes3.flowDirection.leftToRight

    ---@param e tes3uiElement
    local function ActiveRadio(e)
        for _, child in ipairs(e.parent.children) do
            child.widget.state = tes3.uiState.normal
        end
        e.widget.state = tes3.uiState.active
        e:getTopLevelMenu():updateLayout()
    end

    local ui = require("Hanafuda.KoiKoi.MWSE.ui")

    ---@param e tes3uiElement
    ---@param index integer
    local function LoadMenu(e, index)
        ActiveRadio(e)
        parent:destroyChildren()

        local layout = {
            [1] = function()

                local left = parent:createBlock()
                left.widthProportional = 1
                left.heightProportional = 1
                left.autoWidth = true
                left.autoHeight = true
                left.flowDirection = tes3.flowDirection.topToBottom
                local right = parent:createBlock()
                right.widthProportional = 1
                right.heightProportional = 1
                right.autoWidth = true
                right.autoHeight = true
                right.flowDirection = tes3.flowDirection.topToBottom

                local voice = soundData.voiceData
                local function UpdateList()
                    if params.npc.race == nil or params.npc.gender == nil or params.npc.voiceId == nil then
                        return
                    end
                    local list = voice[params.npc.race][params.npc.gender][this.voice[params.npc.voiceId]]
                    if not list then
                        return
                    end

                    right:destroyChildren()
                    local path = ui.CreateSimpleListBox(listid, right, list, function (selectedIndex)
                        PlayDebugVoice(list[selectedIndex])
                    end)
                    right:getTopLevelMenu():updateLayout()
                    ---@diagnostic disable-next-line: param-type-mismatch
                    path.widget:contentsChanged()
                end

                local races = table.keys(voice, true)
                local raceIndex = params.npc.race and table.find(races, params.npc.race) or nil
                local race = ui.CreateSimpleListBox(nil, left, races , function(selectedIndex)
                    params.npc.race = races[selectedIndex]
                    UpdateList()
                end, raceIndex)
                local gender = left:createBlock()
                gender.widthProportional = 1
                gender.autoWidth = true
                gender.autoHeight = true
                gender.flowDirection = tes3.flowDirection.leftToRight
                local ids = table.keys(this.voice, true)
                local idIndex = params.npc.race and table.find(ids, params.npc.voiceId) or nil
                local voiceid = ui.CreateSimpleListBox(nil, left, ids, function (selectedIndex)
                    params.npc.voiceId = ids[selectedIndex]
                    UpdateList()
                end, idIndex )

                ---@param e tes3uiElement
                ---@param female boolean
                local function SetGender(e, female)
                    ActiveRadio(e)
                    params.npc.gender = female and "f" or "m"
                    UpdateList()
                end
                local m = CreateSelection(gender, "Male")
                m:register(tes3.uiEvent.mouseClick,
                function(e)
                    SetGender(e.source, false)
                end)
                local f = CreateSelection(gender, "Female")
                f:register(tes3.uiEvent.mouseClick,
                function(e)
                    SetGender(e.source, true)
                end)
                if params.npc.gender ~= nil then
                    if params.npc.gender == "m" then
                        ActiveRadio(m)
                    else
                        ActiveRadio(f)
                    end
                end

                UpdateList()

                return { race, voiceid }
            end,
            [2] = function()
            end,
            [3] = function()
            end,
            [4] = function()
            end,
        }
        local panes = layout[index]()
        parent:getTopLevelMenu():updateLayout()
        if panes then
            for index, value in ipairs(panes) do
                ---@diagnostic disable-next-line: param-type-mismatch
                value.widget:contentsChanged()
            end
        end
    end

    local button = CreateSelection(lheader, "NPC")
    button:register(tes3.uiEvent.mouseClick,
    ---@param e uiEventEventData
    function(e)
        LoadMenu(e.source, 1)
    end)
    CreateSelection(lheader, "Creature"):register(tes3.uiEvent.mouseClick,
    ---@param e uiEventEventData
    function(e)
        LoadMenu(e.source, 2)
    end)
    CreateSelection(lheader, "SP NPC"):register(tes3.uiEvent.mouseClick,
    ---@param e uiEventEventData
    function(e)
        LoadMenu(e.source, 3)
    end)
    CreateSelection(lheader, "SP Creature"):register(tes3.uiEvent.mouseClick,
    ---@param e uiEventEventData
    function(e)
        LoadMenu(e.source, 4)
    end)
    LoadMenu(button, 1)

    menu:updateLayout()
    tes3ui.enterMenuMode(menuid)

end


return this
