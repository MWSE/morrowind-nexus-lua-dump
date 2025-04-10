local metadata = toml.loadMetadata("Terror of Tel Amur")


local template = mwse.mcm.createTemplate {
    name = "Ужас Тель Амура",
    headerImagePath = "\\Textures\\telamur\\telamur-logo.tga" }

local function getAuthors(tab)
    local result = ""
    local last = #tab

    for i, a in ipairs(tab) do
        if (i ~= last) then
            result = result .. a .. ", "
        else
            result = result .. "и " .. a .. "."
        end
    end

    return result
end

local mainPage = template:createPage { label = "Основная страница", noScroll = true }
mainPage:createCategory {
    label = string.format(
        "%s v%s\n\t%s %s\n\n%s\n\n%s",
        "Ужас Тель Амура",
        metadata.package.version,
        "Разработано командой Kwamakaze Kagouti:",
        getAuthors(metadata.package.authors),
        "Мод добавляет цепочку заданий, которая приведет вас к новому уникальному месту - таинственной тельванийской башне в глубинах Молаг Амур. Часть Morrowind Modding Madness 2023.",
        "Если вы видите это, значит MWSE-модуль работает. Наслаждайтесь!"
    )
}

mwse.mcm.register(template)