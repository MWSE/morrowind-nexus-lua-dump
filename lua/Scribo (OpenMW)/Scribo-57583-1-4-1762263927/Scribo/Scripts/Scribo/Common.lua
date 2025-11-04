local core = require('openmw.core')
local msg = core.l10n('Scribo', 'en')

local inkwellTemplates = {{
    icon = "icons/scribo/ic_ink_ochre.dds",
    name = msg("ochreInk"),
    model = "meshes/scribo/m_ink_ochre.nif",
    colorName = "red",
    colorNameShort = "r",
    color = "b95524",
    value = 20,
    weight = 0.5
}, {
    icon = "icons/scribo/ic_ink_mlchite.dds",
    name = msg("mlchitenk"),
    model = "meshes/scribo/m_ink_mlchite.nif",
    colorName = "green",
    colorNameShort = "gn",
    color = "59914a",
    value = 25,
    weight = 0.5
}, {
    icon = "icons/scribo/ic_ink_dilutd.dds",
    name = msg("dilutdInk"),
    model = "meshes/scribo/m_ink_dilutd.nif",
    colorName = "gray",
    colorNameShort = "g",
    color = "676666",
    value = 5,
    weight = 0.5
}}

local function isGenBook(bookid)
    return string.sub(bookid, 1, 9) == "Generated"
end

local function colorHex2Name(hexColor)
    -- Проверяем специальный случай черного цвета
    if hexColor == "000000" then
        return "black"
    end

    -- Поиск в шаблонах чернильниц
    for _, template in ipairs(inkwellTemplates) do
        if template.color == hexColor then
            return template.colorName
        end
    end

    -- Цвет не найден
    return nil
end
local function colorName2Hex(str, availableColors)
    if str == "grey" then
        str = "gray"
    end

    local colorName
    if availableColors == nil then
        colorName = str
    else
        colorName = availableColors[#availableColors]

        for _, v in ipairs(availableColors) do
            if v == str then
                colorName = str
                break
            end
        end
    end

    if colorName == "blk" then
        colorName = "black"
    end
    if colorName == "black" then
        return "000000"
    end

    for _, inkwell in ipairs(inkwellTemplates) do
        if inkwell.colorName == colorName or inkwell.colorNameShort == colorName then
            return inkwell.color
        end
    end
    return "060606"
end

local function ripHTML(str, asHTML)
    if asHTML then
        return str
    end
    -- Замена <FONT COLOR="цвет"> на {цвет}
    -- str = str:gsub('<FONT[^>]*COLOR=([\'"])(.-)%1', '{%2}')

    str = str:gsub('<%f[FONT](.-)>', function(attrib)
        -- Извлекаем значение атрибута COLOR
        local color = colorHex2Name(attrib:match('[COLOR]=[\'"]([^\'"]+)[\'"]'))

        if color then
            return '{' .. color .. '}'
        else
            return ''
        end
    end)

    -- Замена </FONT> на {}
    str = str:gsub('</FONT>', '{}')

    -- Удаление всех оставшихся HTML-тегов
    str = str:gsub("<[^>]+>", "")
    -- str = str:gsub('<%[^>]*>', '')

    return str
end
local function genHTML(str, availableColors, asHTML)
    if asHTML then
        return str
    end

    -- Font face: "Daedric"
    if #availableColors == 1 then
        -- Доступен только один цвет
        str = str:gsub("%b{}", "") -- убираем все теги цвета
        local color = colorName2Hex(availableColors[1])
        str = '<FONT FACE="Magic Cards" COLOR="' .. color .. '">' .. str .. '</FONT>'
    else
        str = str:gsub('{%}', '</FONT>')
        -- str = str:gsub('{([^}]*)}', '<FONT COLOR="%1">')
        str = str:gsub('{(.-)}', function(colorName)
            -- Извлекаем значение атрибута COLOR
            local color = colorName2Hex(colorName, availableColors)

            if color then
                return '<FONT FACE="Magic Cards" COLOR="' .. color .. '">'
            else
                return ''
            end
        end)
    end
    return '<DIV ALIGN="justify">' .. str .. '</DIV><BR>'
end

-- Вспомогательная функция для проверки наличия элемента в таблице
local function table_contains(table, element)
    for _, value in ipairs(table) do
        if value == element then
            return true
        end
    end
    return false
end

local function ends_with(str, suffix)
    if suffix == "" then
        return true -- Пустая подстрока всегда совпадает
    end
    local str_len = #str
    local suffix_len = #suffix
    if str_len < suffix_len then
        return false -- Строка короче, чем подстрока
    end
    return str:sub(str_len - suffix_len + 1) == suffix
end

return {
    inkwellID = "misc_inkwell",
    quillID = "misc_quill",
    dirtyPageID = "sc_paper plain",
    cleanPageID = "text_paper_roll_01",
    scrollTemplateID = "bk_note",

    emptyScrollName = msg("emptScroll"),
    emptyBookName = msg("emptBook"),
    ripedPageName = msg("ripedPage"),
    emptyTextName = msg("emptText"),
    emptyTitleName = msg("emptTitle"),

    pauseTag = "#EditBookPause",

    inkwellTemplates = inkwellTemplates,

    scrollTemplates = {
        fine = {
            icon = "icons/scribo/ic_sc_fine_txt.dds",
            model = "meshes/scribo/m_sc_fine_txt.nif",
            weight = 2
        },
        rolled = {
            icon = "icons/scribo/ic_sc_rlld_txt.dds",
            model = "meshes/scribo/m_sc_rlld_txt.nif",
            weight = 1
        },
        dirty = {
            icon = "icons/scribo/ic_sc_drty_txt.dds",
            model = "meshes/scribo/m_sc_drty_txt.nif"
        }
    },
    bookTemplates = {{
        name = msg("emptBook"),
        isScroll = false,
        model = "meshes/scribo/m_bk_blnk.nif", -- book.model,
        text = msg("emptText"),
        weight = 2,
        value = 200,
        icon = "icons/scribo/ic_bk_blnk.dds"
    }, {
        name = msg("emptScroll"),
        isScroll = true,
        model = "meshes/scribo/m_sc_fine_blnk.nif", -- book.model,
        text = msg("emptText"),
        weight = 2,
        value = 30,
        icon = "icons/scribo/ic_sc_fine_blnk.dds" -- book.icon
    }, {
        name = msg("ripedPage"),
        isScroll = true,
        text = msg("emptText"),
        weight = 0.2,
        value = 1,
        icon = "icons/scribo/ic_sc_ripd_txt.dds",
        model = "meshes/scribo/m_sc_ripd_txt.nif"
    }},

    origamiTemplates = {
    --     {
    --     name = msg("origamiBoat"),
    --     icon = "icons/scribo/ic_o_boat_txt.dds",
    --     model = "meshes/scribo/m_o_boat_b01.nif",
    --     count = 1,
    --     value = 1,
    --     weight = 0.01
    -- }, 
    {
        name = msg("origamiBoat"),
        icon = "icons/scribo/ic_o_boat_txt.dds",
        model = "meshes/scribo/m_o_boat_b02.nif",
        count = 1,
        value = 1,
        weight = 0.01
    }, {
        name = msg("origamiBoat"),
        icon = "icons/scribo/ic_o_boat_txt.dds",
        model = "meshes/scribo/m_o_boat_s01.nif",
        count = 1,
        value = 1,
        weight = 0.01
    }, 
    -- {
    --     name = msg("origamiBoat"),
    --     icon = "icons/scribo/ic_o_boat_txt.dds",
    --     model = "meshes/scribo/m_o_boat_s02.nif",
    --     count = 1,
    --     value = 1,
    --     weight = 0.01
    -- }, 
    {
        name = msg("origamiBoat"),
        icon = "icons/scribo/ic_o_boat_y.dds",
        model = "meshes/scribo/m_o_boat_s02_Y.nif",
        count = 1,
        value = 1,
        weight = 0.01
    }, {
        name = msg("origamiBoat"),
        icon = "icons/scribo/ic_o_boat_redgreen.dds",
        model = "meshes/scribo/m_o_boat_redgreen.nif",
        count = 1,
        value = 1,
        weight = 0.01
    }, {
        name = msg("origamiDeer"),
        icon = "icons/scribo/ic_o_deer.dds",
        model = "meshes/scribo/m_o_deer_b02.nif",
        count = 1,
        value = 1,
        weight = 0.01
    }, {
        name = msg("origamiDeer"),
        icon = "icons/scribo/ic_o_deer_y.dds",
        model = "meshes/scribo/m_o_deer_b02_y.nif",
        count = 1,
        value = 1,
        weight = 0.01
    }, {
        name = msg("origamiDeer"),
        icon = "icons/scribo/ic_o_deer_black.dds",
        model = "meshes/scribo/m_o_deer_black.nif",
        count = 1,
        value = 1,
        weight = 0.01
    }, {
        
        name = msg("origamiDeer"),
        icon = "icons/scribo/ic_o_deer_blackgray.dds",
        model = "meshes/scribo/m_o_deer_blackgray.nif",
        count = 1,
        value = 1,
        weight = 0.01
        }, {
        name = msg("origamiDeer"),
        icon = "icons/scribo/ic_o_deer_gray.dds",
        model = "meshes/scribo/m_o_deer_gray.nif",
        count = 1,
        value = 1,
        weight = 0.01
        }, {
        name = msg("origamiDeer"),
        icon = "icons/scribo/ic_o_deer_red.dds",
        model = "meshes/scribo/m_o_deer_red.nif",
        count = 1,
        value = 1,
        weight = 0.01
        }, {
        name = msg("origamiDeer"),
        icon = "icons/scribo/ic_o_deer_redgreen.dds",
        model = "meshes/scribo/m_o_deer_redgreen.nif",
        
        count = 1,
        value = 1,
        weight = 0.01
        }, {
        name = msg("origamiFlower"),
        icon = "icons/scribo/ic_o_flwr_gray.dds",
        model = "meshes/scribo/m_o_flwr_gray.nif",
        count = 1,
        value = 1,
        weight = 0.01
        }, {
        
        name = msg("origamiFlower"),
        icon = "icons/scribo/ic_o_flwr_red.dds",
        model = "meshes/scribo/m_o_flwr_red.nif",
        count = 1,
        value = 1,
        weight = 0.01
      }, {
       name = msg("origamiFlower"),
        icon = "icons/scribo/ic_o_flwr_redblackgreen.dds",
        model = "meshes/scribo/m_o_flwr_redblackgreen.nif",
        count = 1,
        value = 1,
        weight = 0.01
        }, {
       name = msg("origamiFlower"),
        icon = "icons/scribo/ic_o_flwr_redgray.dds",
        model = "meshes/scribo/m_o_flwr_redgray.nif",
        count = 1,
        value = 1,
        weight = 0.01
        }, {
       name = msg("origamiFlower"),
        icon = "icons/scribo/ic_o_flwr_redgreen.dds",
        model = "meshes/scribo/m_o_flwr_redgreen.nif",
        count = 1,
        value = 1,
        weight = 0.01
        }, {
        name = msg("origamiFlower"),
        icon = "icons/scribo/ic_o_flwr.dds",
        model = "meshes/scribo/m_o_flwr_text.nif",
        count = 1,
        value = 1,
        weight = 0.01
    }},

    magicOrigamiMessage = {msg("magicOrigami1"), msg("magicOrigami2"), msg("magicOrigami3")},

    isGenBook = isGenBook,
    ripHTML = ripHTML,
    genHTML = genHTML,
    colorName2Hex = colorName2Hex,
    table_contains = table_contains,
    ends_with = ends_with
}
