local prefix = '[Improved Vanilla Leveling Cleanup]'

local function OutOfDate()
    local msg = 'MWSE is out of date! Update to use this mod.'
    tes3.messageBox(prefix .. '\n' .. msg)
    mwse.log(prefix .. ''.. msg)
end

if mwse.buildDate == nil or mwse.buildDate < 20200511 then
    event.register('initialized', OutOfDate)
    return
end

local function RemoveMenu(e)
    if e.button == 0 then
        tes3.player.data.merz_improved_vanilla_leveling = nil
        local msg = 'IVL data removed.'
        tes3.messageBox({ message = prefix .. '\n' .. msg, buttons = { 'Ok' } })
        mwse.log(prefix .. ' ' .. msg)
    else
        local msg = 'No data was removed.'
        tes3.messageBox({ message = prefix .. '\n' .. msg, buttons = { 'Ok' } })
    end
end

local function OnLoaded()
     local save_data = tes3.player.data.merz_improved_vanilla_leveling
     if tes3.player.data.merz_improved_vanilla_leveling == nil then
        local msg = 'No IVL data found.'
        tes3.messageBox({ message = prefix .. '\n' .. msg, buttons = { 'Ok' } })
        mwse.log(prefix .. ' ' .. msg)
    else
        local msg = 'Remove IVL data? This cannot be undone.'
        tes3.messageBox({ message = prefix .. '\n' .. msg, buttons = { 'Remove', 'Cancel' }, callback = RemoveMenu })
    end
end

event.register('loaded', OnLoaded)