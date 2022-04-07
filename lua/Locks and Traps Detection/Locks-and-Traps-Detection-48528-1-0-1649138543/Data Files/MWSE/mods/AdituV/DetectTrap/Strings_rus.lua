local strings_en = require("AdituV.DetectTrap.Strings_en");

local strings = {};

strings.__index = function(self, key)
  mwse.log(string.format("[Обнаружение замков и ловушек] MISSING LOCALISED STRING: %s.  Attempting to default to English", key));
  return strings_en[key];
end
setmetatable(strings, strings);

strings.modName = "Обнаружение замков и ловушек";

strings.trapped = "Ловушка";
strings.untrapped = "Ловушка: Разряжена";

strings.locked = "Замок уровень: "
strings.unlocked = "Замок уровень: Открыто"
strings.keylocked = "Замок уровень: Только ключ"

strings.missingMcpFeatureError = " Необходимая опция MCP \"%s\" не включена";
strings.errorOccurred = "Ошибка"
strings.warning = "Предупреждение"

strings.ok = "Ок"

strings.initialized = "Initialized Version %s"
strings.mwseOutOfDate = "Your MWSE is out of date! You will need to update to a more recent version to use this mod."

strings.invalidHandlerRegistering = "Invalid handler when registering event \"%s\""
strings.invalidHandlerUnregistering = "Invalid handler when unregistering event \"%s\""


strings.mcm = {
  modName = "Обнаружение замков и ловушек",
  
  modEnabled = "Статус мода",
  modEnabledDesc = "По умолчанию мод включен. Изменив статус мода необходимо перезайти в игру.",
  
  debugMode = "Режим отладки",
  debugModeDesc = "По умолчанию выключен. Выводить дополнительные сообщения в MWSE.log",
  
  enchantEffect = "Показывать эффект зачарования",
  enchantEffectDesc = "Когда эта опция включена, при обнаружении ловушки объект начнет блестеть эффектом соответствующего зачарования. Это сделано для лучшей совместимости с Visually Trapped Objects за авторством Anumaril и рекомендуется использовать совместно с данным модом."
  
  maxLockLevel = "Максимальная сложность замка",
  maxLockLevelDesc = "Влияет на минимальную точность определения сложности замка. В оригинальной игре сложность замка не превышает 100. Увеличьте значение этого параметра если играете с модами добавляющие замки большей сложности.",
  
  forgetAfter = "Забывать замки после: (секунды)",
  forgetAfterDesc = "Забывать о том какие замки были проверены спустя данное количество "
    .. "реальных секунд, проведенных в игре (не учитывая время проведенное в меню)",
  
  settings  = "Настройки",
  
  difficulty = "Сложность",
  
  midpoint = "Медиана",
  midpointDesc = "Эффективное значение навыка необходимое чтобы обнаруживать ловушки с 50% вероятностью.\n"
    .. "Эффективное значение навыка расчитывается по следующей формуле:\n"
	.. "Безопасность + (Интеллект / 5) + (Удача / 10).\n"
    .. "Значение по умолчанию: 70",
    
  steepness = "Крутизна",
  steepnessDesc = "Крутизна влияет на форму вероятностной кривой.\n\n"
    .. "Высокая крутизна приводит к тому, что вероятность быстрее возрастает в окрестности медианы,"
    .. " но медленнее вдали от нее, и наоборот.  Значение по умолчанию: 5.",
}

return strings;