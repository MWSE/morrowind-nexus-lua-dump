local cfg = require("herbert100.hiss.config")
local log = mwse.Logger.new()
---@class herbert.HISS.Common
local common = {}

common.register_event = event.register
if cfg.livecoding then
    local livecoding = include("herbert100.livecoding.livecoding")
    if livecoding and livecoding.registerEvent then
        common.register_event = livecoding.registerEvent
    end
end


--- A mapping of menu name to menu ID, for every type of menu supported by this mod.
-- -@type {[string]: integer}
common.IDS = {
    MenuMessage                        = tes3ui.registerID("MenuMessage"),
    MenuNotify1                        = tes3ui.registerID("MenuNotify1"),
    MenuNotify2                        = tes3ui.registerID("MenuNotify2"),
    MenuNotify3                        = tes3ui.registerID("MenuNotify3"),
    MenuMessage_CancelButton           = tes3ui.registerID("MenuMessage_CancelButton"),
    MenuMessage_button_layout          = tes3ui.registerID("MenuMessage_button_layout"),
    MenuMessage_Button                 = tes3ui.registerID("MenuMessage_Button"),
    MenuClassChoice                    = tes3ui.registerID("MenuClassChoice"),
    MenuClassChoice_Questionbutton     = tes3ui.registerID("MenuClassChoice_Questionbutton"),
    MenuChooseClass                    = tes3ui.registerID("MenuChooseClass"),
    MenuChooseClass_OkButton           = tes3ui.registerID("MenuChooseClass_OkButton"),
    MenuChooseClass_Backbutton         = tes3ui.registerID("MenuChooseClass_Backbutton"),
    MenuBirthSign                      = tes3ui.registerID("MenuBirthSign"),
    MenuBirthSign_Okbutton             = tes3ui.registerID("MenuBirthSign_Okbutton"),
    MenuStatReview                     = tes3ui.registerID("MenuStatReview"),
    MenuStatReview_left_main           = tes3ui.registerID("MenuStatReview_left_main"),
    MenuStatReview_race_layout         = tes3ui.registerID("MenuStatReview_race_layout"),
    MenuStatReview_BackButton          = tes3ui.registerID("MenuStatReview_BackButton"),
    MenuClassMessage                   = tes3ui.registerID("MenuClassMessage"),
    MenuClassMessage_cancel_button     = tes3ui.registerID("MenuClassMessage_cancel_button"),
    MenuRaceSex                        = tes3ui.registerID("MenuRaceSex"),
    MenuRaceSex_Backbutton             = tes3ui.registerID("MenuRaceSex_Backbutton"),
    perksMenu                          = tes3ui.registerID("perksMenu"),
    perkOkayButton                     = tes3ui.registerID("perkOkayButton"),
    MenuAttributes                     = tes3ui.registerID("MenuAttributes"),
    MenuSpecialization                 = tes3ui.registerID("MenuSpecialization"),
    MenuOptions                        = tes3ui.registerID("MenuOptions"),

    MenuLoad                           = tes3ui.registerID("MenuLoad"),
    MenuLoad_Okbutton                  = tes3ui.registerID("MenuLoad_Okbutton"),
    MenuSave                           = tes3ui.registerID("MenuSave"),
    MenuSave_Cancelbutton              = tes3ui.registerID("MenuSave_Cancelbutton"),
    MenuPrefs                          = tes3ui.registerID("MenuPrefs"),
    MenuAudio                          = tes3ui.registerID("MenuAudio"),
    MenuCtrls                          = tes3ui.registerID("MenuCtrls"),
    MenuVideo                          = tes3ui.registerID("MenuVideo"),
    MenuPrefs_Okbutton                 = tes3ui.registerID("MenuPrefs_Okbutton"),

    -- scrolls
    MenuScroll                         = tes3ui.registerID("MenuScroll"),
    MenuScroll_Close                   = tes3ui.registerID("MenuScroll_Close"),
    MenuBook_PickupButton              = tes3ui.registerID("MenuBook_PickupButton"),

    -- book
    MenuBook                           = tes3ui.registerID("MenuBook"),
    MenuBook_button_take               = tes3ui.registerID("MenuBook_button_take"),
    MenuBook_button_close              = tes3ui.registerID("MenuBook_button_close"),
    MenuBook_button_prev               = tes3ui.registerID("MenuBook_button_prev"),
    MenuBook_button_next               = tes3ui.registerID("MenuBook_button_next"),

    -- contents menu
    MenuContents                       = tes3ui.registerID("MenuContents"),
    MenuContents_takeallbutton         = tes3ui.registerID("MenuContents_takeallbutton"),
    MenuContents_closebutton           = tes3ui.registerID("MenuContents_closebutton"),
    -- contents menu: UI Expansion
    ["UIEXP:ContentsMenu:FilterBlock"] = tes3ui.registerID("UIEXP:ContentsMenu:FilterBlock"),
    ["UIEXP:FilterButton:weapon"]      = tes3ui.registerID("UIEXP:FilterButton:weapon"),
    ["UIEXP:FilterButton:apparel"]     = tes3ui.registerID("UIEXP:FilterButton:apparel"),
    ["UIEXP:FilterButton:consumable"]  = tes3ui.registerID("UIEXP:FilterButton:consumable"),
    ["UIEXP:FilterButton:ingredient"]  = tes3ui.registerID("UIEXP:FilterButton:ingredient"),
    ["UIEXP:FilterButton:tools"]       = tes3ui.registerID("UIEXP:FilterButton:tools"),
    ["UIEXP:FilterButton:other"]       = tes3ui.registerID("UIEXP:FilterButton:other"),

    MenuMagicSelect                    = tes3ui.registerID("MenuMagicSelect"),
    MenuMagicSelect_button_cancel      = tes3ui.registerID("MenuMagicSelect_button_cancel"),
    MenuInventorySelect                = tes3ui.registerID("MenuInventorySelect"),
    MenuInventorySelect_button_cancel  = tes3ui.registerID("MenuInventorySelect_button_cancel"),
}
common.PREFS_IDS = {
    [common.IDS.MenuPrefs] = true,
    [common.IDS.MenuAudio] = true,
    [common.IDS.MenuCtrls] = true,
    [common.IDS.MenuVideo] = true,
}

common.valid_ids = {}

function common.update_valid_ids()
    log("updating valid ids!")
    table.clear(common.valid_ids)
    for name, is_valid in pairs(cfg.valid_menu_names) do
        if is_valid then
            local id = common.IDS[name] or tes3ui.registerID(name)
            common.valid_ids[id] = true
        end
    end
end

common.update_valid_ids()

--- A mapping between the ID of a menu, and the location of its first button to number.
--- This is only provided for some types of menus.
---@type {[integer]: integer}
common.FIRST_BUTTON_IDS = {
    -- [ids.choose_class] = names.choose_class_ok_btn,
    [common.IDS.MenuChooseClass] = common.IDS.MenuChooseClass_Backbutton,
    [common.IDS.MenuClassChoice] = common.IDS.MenuClassChoice_Questionbutton,
    [common.IDS.MenuBirthSign] = common.IDS.MenuBirthSign_Okbutton,
    [common.IDS.MenuClassMessage] = common.IDS.MenuClassMessage_cancel_button,
    [common.IDS.MenuRaceSex] = common.IDS.MenuRaceSex_Backbutton,
    [common.IDS.perksMenu] = common.IDS.perkOkayButton,
}

--- A set containing the ID of every `MenuNotify` menu.
common.MENU_NOTIFY_IDS = {
    [common.IDS.MenuNotify1] = true,
    [common.IDS.MenuNotify2] = true,
    [common.IDS.MenuNotify3] = true,
}




common._should_skip_next_main_menu_open = false

function common.skip_next_main_menu_open()
    common._should_skip_next_main_menu_open = true
end

---@param e uiActivatedEventData
local function menu_options_activated(e)
    if common._should_skip_next_main_menu_open then
        local return_button = e.element:findChild("MenuOptions_Return_container")
        if return_button then
            return_button:triggerEvent("mouseClick")
            tes3ui.leaveMenuMode()
            e.claim = true
        end
        common._should_skip_next_main_menu_open = false
    end
end



-- Stores the string patterns for each of the numbered labels
-- These could be generated algorithmicly, but there's not really a point.
-- It's only 10 of them, and string patterns are kinda hard to read anyways, so hopefully this makes it a bit clearer.
-- The string at index `i` is the pattern to search for on the `i`th button.
local NUMBERED_LABEL_PATTERNS = {
    "^1%) ",
    "^2%) ",
    "^3%) ",
    "^4%) ",
    "^5%) ",
    "^6%) ",
    "^7%) ",
    "^8%) ",
    "^9%) ",
    "^0%) ",
}

---@param p herbert.HISS.RegisterMenuButtonParams
local function update_button_text(p)
    log("updating button labels for %s", p)
    local label_changed = false
    if p.update_numbered_button_text then
        log("updating numbered button labels")
        -- only iterate through at most 10 buttons
        for i = 1, math.min(#p.numbered_buttons, 10) do
            local button = p.numbered_buttons[i]
            if not button.text:find(NUMBERED_LABEL_PATTERNS[i]) then
                log("updating %q", button.text)
                button.text = string.format("%i) %s", i % 10, button.text)
                label_changed = true
            end
        end
    end

    local close_btn = p.close_button
    if close_btn and p.update_close_button_text and not close_btn.text:find("^Esc%)") then
        log("updating escape button label")
        label_changed = true
        close_btn.text = "Esc) " .. close_btn.text
    end

    if label_changed then
        p.root:updateLayout()
    end
end


--- A table containing various arguments that are passed to `common.register_key_select_events`
---@class herbert.HISS.RegisterMenuButtonParams
---@field root tes3uiElement
---@field numbered_buttons tes3uiElement[]
---@field close_button tes3uiElement? Dedicated close button. (closed by pressing Escape.)
---@field skip_next_main_menu_open boolean? Optional. Default: true
---@field update_close_button_text boolean? Optional. Default: true
---@field update_numbered_button_text boolean? Optional. Default: true
local RegisterKeySelectParams = {
    numbered_buttons = {},
    skip_next_main_menu_open = true,
    update_close_button_text = true,
    update_numbered_button_text = true,
}
-- Used for assigning default values to parameters
RegisterKeySelectParams.__index = RegisterKeySelectParams



---@type herbert.HISS.RegisterMenuButtonParams[]
local active_data_list = {}

---@param data herbert.HISS.RegisterMenuButtonParams
function common.register_key_select_events(data)
    -- fill in any missing arguments with default values
    setmetatable(data, RegisterKeySelectParams)

    log('trying to register key events on menu')
    if not data.root then
        return
    end
    if not (data.numbered_buttons[1] or data.close_button) then
        return
    end

    for _, existing_data in ipairs(active_data_list) do
        if existing_data == data or existing_data.root == data.root then
            log("skipping %s because it was already added!", data)
            return
        end
    end
    table.insert(active_data_list, data)
    log("added %s to active data list. there are now %s active menus", data, #active_data_list)

    update_button_text(data)

    ---@param e uiEventEventData
    local function remove_data_from_list(e)
        log("removing %s from the data list because %s was destroyed", data, e.source)
        local num_removed = 0
        for i = #active_data_list, 1, -1 do
            local existing_data = active_data_list[i]
            if existing_data == data or existing_data.root == data.root then
                table.remove(active_data_list, i)
                num_removed = num_removed + 1
            end
        end
        log("\tcopies removed: %s", num_removed)
        e.source:forwardEvent(e.property)
    end


    -- make absolutely sure this entry gets removed when the menu is destroyed
    -- This might seem like overkill (and it probably is), but if we fail to remove
    -- something from the active list, there is a decent chance that we will crash.
    for _, button in ipairs(data.numbered_buttons or {}) do
        button:registerBefore(tes3.uiEvent.destroy, remove_data_from_list)
    end
    if data.close_button then
        data.close_button:registerBefore(tes3.uiEvent.destroy, remove_data_from_list)
    end
    data.root:registerBefore(tes3.uiEvent.destroy, remove_data_from_list)
end

--- Callback that looks through all active menu data and clicks appropriate buttons
---@param e keyDownEventData
local function click_option_with_key(e)
    -- We subtract `1` so that escape maps to `0`,
    -- and each number key maps to the corresponding integer value.
    -- (e.g. kc == 1 means the `1` key was pressed.)
    local kc = e.keyCode - 1
    if kc > 10 then
        return
    end

    log:trace("Button was pressed: %q (%s)\n\tactive_data_list: %s", function()
        return tes3.getKeyName(e.keyCode), kc, active_data_list
    end)


    -- iterate in reverse order to ensure that
    -- 1) `table.remove` does not mess up iteration
    -- 2) we check the top-most menus first.
    for i = #active_data_list, 1, -1 do
        local data = active_data_list[i]
        -- need to define these up here so that `goto` works :)
        local menu_name, top_menu
        if not data.root then
            table.remove(active_data_list, i)
            log("skipping because data.root did not exist! %s", data)
            goto next_data
        end

        menu_name = data.root.name or data.root.id

        -- it might seem foolish to update this on every iteration,
        -- but in practice, `#active_data_list` will almost always be be 0 or 1,
        -- so this results in doing less work most of the time, compared to evaluating it outside the loop.
        -- also, our comparison with `data.root` is partially a safety measure against dangling pointers,
        -- so it would be ideal if `top_menu` was not itself dangling.
        top_menu = tes3ui.getMenuOnTop()

        if top_menu ~= data.root then
            log("skipping because %q is not the correct menu (%q)", top_menu, menu_name)
            goto next_data
        end

        if kc == 0 then -- escape
            if data.close_button then
                data.close_button:triggerEvent("mouseClick")
                log("esc was pushed. destroying menu %q....", menu_name)
                e.claim = true -- nobody else can have this event
                if data.skip_next_main_menu_open then
                    common.skip_next_main_menu_open()
                end
                break
            end
        else -- number keys
            local button = data.numbered_buttons and data.numbered_buttons[kc]
            if button then
                log("%q: clicking button %q", menu_name, button.text)
                button:triggerEvent("mouseClick")
                e.claim = true -- nobody else can have this event
                break
            end
        end
        ::next_data::
    end
end

-- event.register(tes3.event.uiActivated, menu_options_activated, { filter = "MenuOptions", priority = 1000 })
common.register_event(tes3.event.uiActivated, menu_options_activated, { filter = "MenuOptions", priority = 1000 })
common.register_event(tes3.event.keyDown, click_option_with_key, { priority = 1000 })

return common
