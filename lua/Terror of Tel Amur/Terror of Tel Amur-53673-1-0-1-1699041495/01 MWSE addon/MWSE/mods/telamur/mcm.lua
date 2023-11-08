local metadata = toml.loadMetadata("Terror of Tel Amur")


local template = mwse.mcm.createTemplate {
    name = metadata.package.name,
    headerImagePath = "\\Textures\\telamur\\telamur-logo.tga" }

local function getAuthors(tab)
    local result = ""
    local last = #tab

    for i, a in ipairs(tab) do
        if (i ~= last) then
            result = result .. a .. ", "
        else
            result = result .. "and " .. a .. "."
        end
    end

    return result
end

local mainPage = template:createPage { label = "Main", noScroll = true }
mainPage:createCategory {
    label = string.format(
        "%s v%s\n\t%s %s\n\n%s\n\n%s",
        metadata.package.name,
        metadata.package.version,
        "by Team Kwamakaze Kagouti:",
        getAuthors(metadata.package.authors),
        metadata.package.description,
        "If you can see this, the MWSE module has successfully loaded. Enjoy!"
    )
}

mwse.mcm.register(template)