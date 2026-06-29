local async = require('openmw.async')
local ui    = require('openmw.ui')
local util  = require('openmw.util')
local I     = require('openmw.interfaces')
local core  = require('openmw.core')

local waiting = {}
local forbidden = { [227]=true, [228]=true }  -- Win L/R

-- Russian layout symbols → storage key name (layout-independent via physical key)
local ruToKey = {
    -- Row 3 (home row area)
    ['ж']='Semi', ['Ж']='Semi',   -- ; key
    ['э']='Apos', ['Э']='Apos',   -- ' key
    -- Row 4 (bottom row)
    ['б']='Comma',['Б']='Comma',  -- , key
    ['ю']='Period',['Ю']='Period', -- . key
    -- Other commonly used
    ['х']='LBrk', ['Х']='LBrk',   -- [ key
    ['ъ']='RBrk', ['Ъ']='RBrk',   -- ] key
    ['ё']='Grave',['Ё']='Grave',   -- ` key
}

-- Scancode → label map for keys with no printable symbol
local scancodeNames = {
    [40]='Enter', [43]='Tab', [57]='CapsLk',
    [58]='F1',  [59]='F2',  [60]='F3',  [61]='F4',  [62]='F5',
    [63]='F6',  [64]='F7',  [65]='F8',  [66]='F9',  [67]='F10',
    [68]='F11', [69]='F12',
    [73]='Ins', [76]='Del', [75]='PgUp',[78]='PgDn',
    [74]='Home',[77]='End',
    [79]='Right',[80]='Left',[81]='Down',[82]='Up',
    [224]='LCtrl',[225]='LShift',[226]='LAlt',
    [229]='RShift',[230]='RAlt',
    -- Punctuation by scancode (layout-independent)
    [45]='Minus',[46]='Equal',
    [47]='LBrk', [48]='RBrk',
    [49]='Bksl',
    [51]='Semi', -- ;
    [52]='Apos', -- '
    [53]='Grave',-- `
    [54]='Comma',[55]='Period',[56]='Slash',
}

local function makeStorageValue(sym, code)
    -- Forbidden
    if forbidden[code] then return nil end
    -- Escape = cancel (not a value)
    if code == 41 then return nil end

    -- Try scancode first for punctuation/special (layout-independent)
    if scancodeNames[code] then
        return scancodeNames[code]
    end

    -- Printable ASCII symbol
    if sym ~= nil and sym ~= '' then
        local b = string.byte(sym, 1)
        if b ~= nil and b >= 32 and b < 127 then
            if sym == ' ' then return 'Space' end
            return string.upper(sym)
        end
    end

    return nil  -- unknown/non-assignable
end

local symbolLabels = {
    ['Semi']   = ';',
    ['Apos']   = "'",
    ['Comma']  = ',',
    ['Period'] = '.',
    ['Slash']  = '/',
    ['Bksl']   = '\\',
    ['Bksl2']  = '\\',
    ['Grave']  = '`',
    ['Minus']  = '-',
    ['Equal']  = '=',
    ['LBrk']   = '[',
    ['RBrk']   = ']',
    ['Space']  = 'Spc',
}

local function makeLabel(value)
    if value == nil or value == '' then return '?' end
    if value == 'mouse1' then return 'LMB'
    elseif value == 'mouse2' then return 'MMB'
    elseif value == 'mouse3' then return 'RMB'
    elseif value == 'mouse4' then return 'M4'
    elseif value == 'mouse5' then return 'M5'
    elseif symbolLabels[value] then return symbolLabels[value]
    else return value end
end

local DEFAULTS = { bindToggle = 'mouse2', bindType = 'Bksl' }

local function btnSize(label)
    local n = #label
    local w
    if n <= 1 then w = 36
    elseif n <= 3 then w = 50
    elseif n <= 4 then w = 62
    elseif n <= 5 then w = 74
    else w = 90 end
    return util.vector2(w, 26)
end

local function setWaiting(sk, setFn)
    waiting[sk] = { set = setFn }
    pcall(function() core.sendGlobalEvent('AutoAttackMenuWaiting', true) end)
    pcall(function()
        I.Settings.updateRendererArgument('SettingsAutoAttack', sk, { settingKey = sk, waiting = true })
    end)
end

local function clearWaiting(sk, resetToDefault)
    if resetToDefault and waiting[sk] and waiting[sk].set then
        waiting[sk].set(DEFAULTS[sk] or 'mouse2')
    end
    waiting[sk] = nil
    local any = false
    for _ in pairs(waiting) do any = true; break end
    if not any then
        pcall(function() core.sendGlobalEvent('AutoAttackMenuWaiting', false) end)
    end
    pcall(function()
        I.Settings.updateRendererArgument('SettingsAutoAttack', sk, { settingKey = sk, waiting = false })
    end)
end

local function assignValue(sk, val)
    if waiting[sk] and waiting[sk].set then
        waiting[sk].set(val)
    end
    clearWaiting(sk, false)
end

I.Settings.registerRenderer('keyBinding', function(value, set, arg)
    local sk = arg and arg.settingKey or 'unknown'
    if waiting[sk] then waiting[sk].set = set end
    local argWaiting = arg and arg.waiting
    local isWaiting = (waiting[sk] ~= nil) or (argWaiting == true)
    local label = isWaiting and '???' or makeLabel(value)

    return {
        template = I.MWUI.templates.borders,
        props = { size = btnSize(label) },
        events = {
            -- LMB press: enter waiting mode OR assign LMB
            mousePress = async:callback(function(e)
                local btn = e and e.button or 0
                if btn == 1 then
                    if isWaiting or (waiting[sk] ~= nil) then
                        assignValue(sk, 'mouse1')
                    else
                        setWaiting(sk, set)
                    end
                end
            end),
            -- All buttons release: capture non-LMB mouse buttons
            mouseRelease = async:callback(function(e)
                local btn = e and e.button or 0
                if btn >= 2 and btn <= 5 then
                    if isWaiting or (waiting[sk] ~= nil) then
                        local mouseMap = { [2]='mouse2', [3]='mouse3', [4]='mouse4', [5]='mouse5' }
                        assignValue(sk, mouseMap[btn])
                    end
                end
            end),
            keyPress = async:callback(function(e)
                local isW = (waiting[sk] ~= nil)
                if isW and e then
                    if e.code == 41 then  -- Escape → reset to default
                        clearWaiting(sk, true)
                    elseif forbidden[e.code] then
                        -- ignore
                    else
                        local val = makeStorageValue(e.symbol, e.code)
                        if val ~= nil then
                            assignValue(sk, val)
                        end
                        -- unknown key: stay in waiting
                    end
                end
            end),
            -- Catch Cyrillic input that comes as textInput instead of keyPress
            textInput = async:callback(function(text)
                if waiting[sk] ~= nil and text ~= nil then
                    local val = ruToKey[text]
                    if val ~= nil then
                        assignValue(sk, val)
                    end
                    -- non-mapped cyrillic: stay in waiting
                end
            end),
        },
        content = ui.content {
            {
                template = I.MWUI.templates.textNormal,
                type = ui.TYPE.Text,
                props = {
                    text             = label,
                    textSize         = 16,
                    textColor        = isWaiting and util.color.rgb(1, 0.85, 0) or nil,
                    relativePosition = util.vector2(0.5, 0.5),
                    anchor           = util.vector2(0.5, 0.5),
                },
            },
        },
    }
end)
