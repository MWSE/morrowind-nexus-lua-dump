local prefix = '[Cover Yourself!]'
local version = '2.0'

local function log(s, ...)
    mwse.log(prefix .. ' '.. s, ...)
end

if mwse.buildDate == nil or mwse.buildDate < 20200511 then
    event.register('initialized',
    function()
        local msg = 'MWSE is out of date! Update to use this mod.'
        tes3.messageBox(prefix .. '\n' .. msg)
        log(msg)
    end)
    return
end

local config = require('merz.cover_yourself.config')

-- tes3iterator.current is read-only, so we'll have to keep track of it ourselves.
-- Since the game normally traverses the entire list in this section and we override both the getHead and getNext
-- functions, this should not cause any problems.
local current = nil
local is_naked_check

-- Traverse the list until we find a top and bottom (female) or just a bottom (male). If we do, this ensures that at
-- least one item is included in the value calculation for PC Clothing Modifier, resulting in a value > 0.
local function GenderFilter()
    local top = false
    local bottom = false
    if not tes3.mobilePlayer.object.female then
        top = true
    end
    while current ~= nil do
        local type = current.nodeData.object.objectType
        local slot = current.nodeData.object.slot
        local id = current.nodeData.object.id:lower()
        if type == tes3.objectType.clothing and not config.blacklist.clothing[id] then
            if slot == tes3.clothingSlot.pants or slot == tes3.clothingSlot.robe or slot == tes3.clothingSlot.skirt then
                bottom = true
            end
            if slot == tes3.clothingSlot.shirt or slot == tes3.clothingSlot.robe then
                top = true
            end
        elseif type == tes3.objectType.armor and not config.blacklist.armor[id] then
            if slot == tes3.armorSlot.greaves then
                bottom = true
            end
            if slot == tes3.armorSlot.cuirass then
                top = true
            end
        end
        if top and bottom then
            break
        end
        current = current.nextNode
    end
end

-- This is what the game normally does. Traverse the list until we find clothing or armor, or reach the end.
local function NormalFilter()
    while current ~= nil do
        local type = current.nodeData.object.objectType
        if type == tes3.objectType.clothing or type == tes3.objectType.armor then
            break
        end
        current = current.nextNode
    end
end

-- Traverse the list until we find clothing or armor that's not being excluded, or reach the end.
local function SlotFilter()
    while current ~= nil do
        local type = current.nodeData.object.objectType
        local slot = tostring(current.nodeData.object.slot)
        local id = current.nodeData.object.id:lower()
        if (type == tes3.objectType.clothing and not config.blacklist.clothing[id] and config.clothing[slot]) or
            (type == tes3.objectType.armor and not config.blacklist.armor[id] and config.armor[slot]) then
            break
        end
        current = current.nextNode
    end
end

local function Filter()
    if config.smart_filter then
        if is_naked_check then
            if config.gender_filter then
                GenderFilter()
            else
                SlotFilter()
            end
        else
            NormalFilter()
        end
    else
        if config.gender_filter then
            GenderFilter()
        else
            SlotFilter()
        end
    end
end

local function getHead(this, operator, value)
    is_naked_check = (operator == 1 or operator == 4 or operator == 5) and value <= 0
    current = this.head
    Filter()
    return current
end

local function getNext()
    current = current.nextNode
    Filter()
    return current
end

log('Patching game code...')
-- Rewrite this section of game code to add the current dialogue compare value and operator as arguments to getHead()
-- and call our replacement for tes3iterator getHead(). We also remove the game's filter for amor and clothing, since
-- we need that space for other instructions and it's now redundant anyway.
-- mov eax, dword_7ca464[esi] // dialogue compare value
mwse.memory.writeBytes({ address = 0x4b1065, bytes = { 0x8b, 0x86, 0x64, 0xa4, 0x7c, 0x00 } })
mwse.memory.writeBytes({ address = 0x4b106b, bytes = { 0x50 } })            -- push [eax]
-- mov eax, dword_7ca460[esi] // dialogue compare operator
mwse.memory.writeBytes({ address = 0x4b106c, bytes = { 0x8b, 0x86, 0x60, 0xa4, 0x7c, 0x00 } })
mwse.memory.writeBytes({ address = 0x4b1072, bytes = { 0x50 } })            -- push [eax]
mwse.memory.writeFunctionCall({
    address = 0x4b1073,
    call = getHead,
    signature = {
        this = 'tes3equipmentStackIterator',
        arguments = { 'uint', 'float' },
        returns = 'tes3equipmentStackIteratorNode'
    }
})
mwse.memory.writeBytes({ address = 0x4b1078, bytes = { 0x85, 0xc0 } })      -- test eax, eax
mwse.memory.writeBytes({ address = 0x4b107a, bytes = { 0x74, 0x32 } })      -- jz short 0x4b10ae
mwse.memory.writeNoOperation({ address = 0x4b107c, length = 0xa })          -- no op
mwse.memory.writeBytes({ address = 0x4b1086, bytes = { 0x8b, 0x78, 0x08 }}) -- mov edi, [eax+8]
-- Overwrite the tes3iterator getNext() call to use our implementation instead. Technically, getNext should have
-- "this = 'tes3equipmentStackIterator'" in its signature. However we're keeping track of current separately, and the
-- game will never call this function in this context when current = nil, letting us ignore "this".
mwse.memory.writeFunctionCall({
    address = 0x4b10a5,
    call = getNext,
    signature = { returns = 'tes3equipmentStackIteratorNode' }
})
-- Update the jump instruction to use the appropriate point in the new code above.
mwse.memory.writeByte({ address = 0x4b10ad, byte = 0xd8 })                  --  jnz short 0x4b1086 (0x75 0xd8)
log('done.')

local function SetupMenu()
    local template = mwse.mcm.createTemplate({ name = 'Cover Yourself!' })
    template:saveOnClose('cover_yourself', config)
    template:register()
    local preferences = template:createSideBarPage({ label = 'Preferences' })
    preferences.sidebar:createInfo({ text = 'Cover Yourself! v' .. version .. '\n\nFilter the equipped items list to '
        .. 'change the value of the PC Clothing Modifier check.' })

    -- Transform 'rightGlove' into 'Right Glove'.
    local function pretty(s)
        -- capitalize first letter
        s = s:gsub('^(%l)', string.upper)
        -- add a space, if needed
        return s:gsub('(%l)(%u)', '%1 %2')
    end

    local toggles = preferences:createCategory({ label = 'Filter Options' })
    toggles:createOnOffButton({
        label = 'Smart Filter',
        description = 'Filters equipped items list only when checking for nudity.\n(PC Clothing Modifier <, <=, == 0)\n'
            .. 'All other checks use the full unfiltered equipped items list.',
        variable = mwse.mcm:createTableVariable({
            id = 'smart_filter',
            table = config
        })
    })
    toggles:createOnOffButton({
        label = 'Gender Filter',
        description = 'Filters equipped items list with respect to gender. Male PCs are considered naked if bottomless,'
        .. ' female PCs if bottomless or topless. Per slot settings are ignored if this is "On".',
        variable = mwse.mcm:createTableVariable({
            id = 'gender_filter',
            table = config
        })
    })

    local function createToggles(label, slots, config)
        local toggles = preferences:createCategory({ label = label })
        for slot, id in pairs(slots) do
            toggles:createOnOffButton({
                label = pretty(slot),
                description = 'Set to "Off" to exclude this slot from the PC Clothing Modifier check. This settings is '
                .. 'ignored if "Gender Filter" is "On".',
                variable = mwse.mcm:createTableVariable({
                id = tostring(id),
                table = config
                })
            })
        end
    end

    createToggles('Clothing Slots', tes3.clothingSlot, config.clothing)
    createToggles('Armor Slots', tes3.armorSlot, config.armor)

    local function CreateBlacklist(label, id, obj_type, slots)
        local filters = {}
        for slot, id in pairs(slots) do
            local filter = {
                label = pretty(slot),
                type = 'Object',
                objectType = obj_type,
                objectFilters = {
                    slot = id
                }
            }
            table.insert(filters, filter)
        end
        template:createExclusionsPage({
            label = label,
            description = 'Any item on the blacklist will be excluded from the PC Clothing Modifier check.',
            leftListLabel = 'Blacklist',
            rightListLabel = 'Objects',
            variable = mwse.mcm:createTableVariable({
                id = id,
                table = config.blacklist
            }),
            filters = filters
        })
    end

    CreateBlacklist('Clothing Blacklist', 'clothing', tes3.objectType.clothing, tes3.clothingSlot)
    CreateBlacklist('Armor Blacklist', 'armor', tes3.objectType.armor, tes3.armorSlot)
end

event.register('modConfigReady', SetupMenu)

local function OnInitialized()
    log('Initialized Version ' .. version)
end
event.register('initialized', OnInitialized)