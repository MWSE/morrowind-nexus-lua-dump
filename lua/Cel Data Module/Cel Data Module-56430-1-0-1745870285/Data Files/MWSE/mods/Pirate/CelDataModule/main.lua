-- Глобальные переменные для хранения названий.
engNameCelData = {}
rusNameCelData = {}
-- Локальные переменные
local modName = "Модуль данных cel"
local modVersion = "1.0"
local confPath = "CelDataModule"
local defaultConfig = {
            logLevel = "INFO"
      }
local config = mwse.loadConfig(confPath, defaultConfig)
local log = mwse.Logger.new{
        name = modName,
        level = config.logLevel,
      }

-- очистка базы
local function CleanBase()
    engNameCelData = {}
    rusNameCelData = {}
    log:info("База очищена")
end

-- Загрузка данных из файлов cel
local function loadCelFile(filename)
    local file = io.open(filename, "r")
    if not file then
        log:trace("Файл не найден: %s", filename)
        return 0
    end
    
    local counter = 0
    local lineNumber = 0
    local isEmpty = true

    for line in file:lines() do
        isEmpty = false
        lineNumber = lineNumber + 1
        local eng, rus = line:match("^([^\t]+)\t([^\t]+)$")
        if eng and rus then
            table.insert(engNameCelData, eng)
            table.insert(rusNameCelData, rus)
            counter = counter + 1
        else
        log:error("Ошибка в строке %d файла %s", lineNumber, filename)
        end
    end
    file:close()

    if isEmpty then
        log:trace("Файл пустой: %s", filename)
    else
        log:trace("Загружено %d/%d записей из файла %s", counter, lineNumber, filename)
    end
    return counter
end

local function init()
    log:trace("Загрузка данных из файлов .cel")
    -- Загружаем cel файлы для всех активных ESP/ESM.
    for _, modFilename in ipairs(tes3.getModList()) do
        local celFile = "Data Files\\" .. modFilename:gsub("%.[eE][sS][pPmM]$", ".cel")
        loadCelFile(celFile)
    end
    
    log:info("Всего загружено: %d записей", #engNameCelData)
end

log:info("Версия: " .. modVersion)
event.register("initialized", init)

-- Меню настройки мода MCM
local LINKS_LIST = {
	{
		text = "Страница мода на Nexusmods",
		url = ""
	},
}
local CREDITS_LIST = {
	{
		text = "Pirate",
		url = "https://next.nexusmods.com/profile/Pirate443?gameId=100",
	},
}
local function addSideBar(component)
	component.sidebar:createCategory(modName.."\nВерсия: "..modVersion)
	component.sidebar:createInfo{ text = "Это вспомогательный модуль, ничего не добавляет в игру. Требуется для некоторых переводов MWSE модов, для русификации названий локаций. При запуске игры загружает данные из файлов cel для всех подключенных файлов esm\\esp в одну общую базу, доступную для других MWSE модов." }

	local linksCategory = component.sidebar:createCategory("Ссылки")
	for _, link in ipairs(LINKS_LIST) do
		linksCategory:createHyperLink{ text = link.text, url = link.url }
		end
	local creditsCategory = component.sidebar:createCategory("Авторы")
	for _, credit in ipairs(CREDITS_LIST) do
		creditsCategory:createHyperLink{ text = credit.text, url = credit.url }
	end
end

local function registerMCM()
    local template = mwse.mcm.createTemplate{ name = modName }
    --headerImagePath = "textures/Achiev_header.dds" }
    template:saveOnClose(confPath, config)
    template:register()

    local page = template:createSideBarPage { name = "Настройки" }
    addSideBar(page)

page:createButton {
        buttonText = "Обновить базу",
        description = "Обновить базу",
        callback = function()
        CleanBase()
        init()
        end
    }

    page:createDropdown{
        label = "Уровень журнала",
        description = "Установите уровень ведения журнала событий mwse.log.",
        options = {
            { label = "TRACE", value = "TRACE"},
            { label = "DEBUG", value = "DEBUG"},
            { label = "INFO", value = "INFO"},
            { label = "WARN", value = "WARN"},
            { label = "ERROR", value = "ERROR"},
            { label = "NONE", value = "NONE"},
        },
        variable =  mwse.mcm.createTableVariable{ id = "logLevel", table = config},
        callback = function(self)
            log.level = self.variable.value
        end
    }
end
event.register("modConfigReady", registerMCM)
