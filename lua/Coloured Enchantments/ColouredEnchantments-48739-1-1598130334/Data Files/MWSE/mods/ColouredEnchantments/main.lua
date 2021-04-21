local config = {
    ['toggle'] = {
        ['tint'] = true,
        ['texture'] = false
    },
    ['menues'] = {
        {'MenuMulti', nil},
        {'MenuInventory', 'PartDragMenu_main'}
    },
    ['colours'] = {
        ['default'] = {
            0.06274509803921569,
            0.8549019607843137,
            0.9647058823529412
        },
        ['0'] = {
            1,
            1,
            1
        },
        ['1'] = {
            0.06274509803921569,
            0.8549019607843137,
            0.9647058823529412
        },
        ['2'] = {
            0.06274509803921569,
            0.8549019607843137,
            0.9647058823529412
        },
        ['3'] = {
            0.054901960784313725,
            0.2823529411764706,
            0.9647058823529412
        }
    },
    ['textures'] = {
        ['default'] = 'menu_icon_magic_mini_blank.dds',
        ['weapon_1'] = 'menu_icon_magic_mini_blank.dds',
        ['weapon_2'] = 'menu_icon_magic_mini_blank.dds'
    }
}

local function replaceUI(e)
    for _, menu in pairs(config.menues) do
        local menuPopup = tes3ui.findMenu(tes3ui.registerID(menu[1]))
        if (menuPopup) then
            local subChild = nil
            if (menu[2]) then
                subChild = menuPopup:findChild(tes3ui.registerID(menu[2]))
            end

            local child = nil
            if (subChild) then
                child = subChild:findChild(tes3ui.registerID('MenuMulti_enchantment_icon'))
            else
                child = menuPopup:findChild(tes3ui.registerID('MenuMulti_enchantment_icon'))
            end
            
            if (child) then
                if (config.toggle.texture == true) then
                    child.contentPath = 'Textures\\' .. config.textures['default']
                end

                if (config.toggle.tint == true) then
                    child.color = config.colours['default']
                    if (config.toggle.texture == false) then
                        child.contentPath = 'Textures\\menu_icon_magic_mini_blank.dds'
                    end
                end
            end
        end
    end
end

--------------------------------------------------

local function init()
    event.register('uiEvent', replaceUI)
end

event.register('initialized', init)
