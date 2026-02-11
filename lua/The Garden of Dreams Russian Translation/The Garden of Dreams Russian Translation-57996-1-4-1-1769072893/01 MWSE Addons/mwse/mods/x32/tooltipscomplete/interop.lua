local tooltipsComplete = include("Tooltips Complete.interop")
if tooltipsComplete == nil then
    return
end

local tooltipData = {
    -- Alchemy:
    { id = "X32_MTPoison", description = "Медленно распространяющийся яд, которому могут потребоваться недели, чтобы убить свою жертву.", itemType = "alchemy" },

    -- Books:
    { id = "x32_bk_BrazierSecret", description = "Большая часть текста в этом дневнике закрашена мелкими мазками кисти.", itemType = "book" },
    { id = "x32_bk_oldbook", description = "Зловещие слова о смерти, вот и все, что осталось в этом ветхом томе.", itemType = "book" },
    { id = "x32_MisfortuneNotebook", description = "Записи о Саде, составленные на основе описаний повторяющихся форм, наблюдаемых разными посетителями.", itemType = "book" },

    -- Clothing:
    { id = "x32_c_ButlersGloveLeft", description = "Простая левая перчатка из плотной хлопковой ткани, которую обычно носят дворецкие.", itemType = "clothing" },
    { id = "x32_c_ButlersGloveLeftDisg", description = "Простая левая перчатка из плотной хлопковой ткани, которую обычно носят дворецкие.", itemType = "clothing" },
    { id = "x32_c_ButlersGloveRight", description = "Простая правая перчатка из плотной хлопковой ткани, которую обычно носят дворецкие.", itemType = "clothing" },
    { id = "x32_c_ButlersGloveRightDisg", description = "Простая правая перчатка из плотной хлопковой ткани, которую обычно носят дворецкие.", itemType = "clothing" },
    { id = "x32_c_MelvinDisguise", description = "Кажется, на этот каменный бюст наложено зачарование иллюзии.", itemType = "clothing" },
    { id = "x32_MTPinAmuletDoubt", description = "Металлические булавки, благословленные Мефалой для отметки исполненных приказов.", itemType = "clothing" },

    -- Filled Soul Gems:
    { id = "x32_Cre_Mudcrab", description = "Захваченная душа запертого в клетке грязекраба, найденного в одном из планов Сада.", itemType = "creature" },
    { id = "x32_Cre_Beast3", description = "Захваченная душа Неудачи, искаженного воплощения Тирел Варас, извращенного силой Поля мертвецов и ее собственными ритуалами, превратившееся в нечто неестественное.", itemType = "creature" },
    { id = "x32_Cre_GoblinSpace", description = "Захваченная душа Бакнами, гоблина обитающего в Пустоте.", itemType = "creature" },
    { id = "x32_Cre_GolemGarden01", description = "Захваченная душа садового голема, созданного из корней и заключенного в глину. Эти мирные создания неустанно трудятся, поддерживая целостность Сада.", itemType = "creature" },
    { id = "x32_Cre_GolemGarden02", description = "Захваченная душа садового голема, созданного из корней и заключенного в глину. Эти мирные создания неустанно трудятся, поддерживая целостность Сада.", itemType = "creature" },
    { id = "x32_Cre_GolemGarden03", description = "Захваченная душа садового голема, созданного из корней и заключенного в глину. Эти мирные создания неустанно трудятся, поддерживая целостность Сада.", itemType = "creature" },
    { id = "x32_Cre_Kagioun", description = "Захваченная душа кагиуна, огромной рептилии, которая охотится на заблудших духов в Саду.", itemType = "creature" },
    { id = "x32_Cre_Kagioun_Duel", description = "Захваченная душа кагиуна, огромной рептилии, которая охотится на заблудших духов в Саду.", itemType = "creature" },
    { id = "x32_Cre_KagiounAlpha_Q2", description = "Захваченная душа разъяренного кагиуна, который больше и опаснее большинства других, встречающихся в Саду.", itemType = "creature" },
    { id = "x32_Dae_AtrNebula_noagg", description = "Захваченная душа элементального даэдра. Туманные атронахи состоят из звездного вещества и энергии пустоты. Они не связаны ни с одним определенным Принцем, но считается, что они происходят из царства, известного как Туманность Между Мирами.", itemType = "creature" },
    { id = "x32_Dae_AtronachNebula", description = "Захваченная душа элементального даэдра. Туманные атронахи состоят из звездного вещества и энергии пустоты. Они не связаны ни с одним определенным Принцем, но считается, что они происходят из царства, известного как Туманность Между Мирами.", itemType = "creature" },
    { id = "x32_Dae_AtronachNefar", description = "Захваченная душа туманного атронаха, искаженного смертоносной силой Поля мертвецов, представляющего собой мертвый, огненный осколок его прежней формы.", itemType = "creature" },
    { id = "x32_Skeleton_Hammer01", description = "Захваченная душа скелета-варвара, чьи останки были оживлены для защиты Изменчивых залов.", itemType = "creature" },
    { id = "x32_Skeleton_Hammer02", description = "Захваченная душа скелета-варвара, чьи останки были оживлены для защиты Изменчивых залов.", itemType = "creature" },
    { id = "x32_Und_AshenHusk", description = "Захваченная душа пепельной оболочки, обугленного тела, которое высвободилось от остальных из-за противоестественной силы Поля мертвецов.", itemType = "creature" },
    { id = "x32_Und_AshenHusk_Boss1", description = "Захваченная душа пепельной оболочки, обугленного тела, которое высвободилось от остальных из-за противоестественной силы Поля мертвецов.", itemType = "creature" },
    { id = "x32_Und_AshenHusk_Boss2", description = "Захваченная душа пепельной оболочки, обугленного тела, которое высвободилось от остальных из-за противоестественной силы Поля мертвецов.", itemType = "creature" },
    { id = "x32_Und_AshenHuskCelest", description = "Захваченная душа пепельной оболочки, подвергшейся воздействию энергии пустоты от туманных атронахов, из-за чего из ее обугленного тела стал прорастать целестин.", itemType = "creature" },
    { id = "x32_Und_AshenKag_Boss", description = "Захваченная душа пепельного кагиуна, искаженного силой Поля мертвецов после того, как он забрел слишком далеко. Его тело обуглилось и стало нежитью.", itemType = "creature" },
    { id = "x32_Und_AshenKagioun", description = "Захваченная душа пепельного кагиуна, искаженного силой Поля мертвецов после того, как он забрел слишком далеко. Его тело обуглилось и стало нежитью.", itemType = "creature" },
    { id = "x32_Und_VoidGhost", description = "Захваченная душа призрака пустоты, таинственного неживого приведения, скитающегося по пустым пространствам Забвения.", itemType = "creature" },

    -- Ingredient:
    { id = "x32_CursedAmethystGhost", description = "Прозрачный фиолетовый драгоценный камень со скромными магическими свойствами.", itemType = "ingredient" },
    { id = "x32_IngFlor_Saffron", description = "Редкая багряная пряность, собранная с нежных рылец радужного цветка, ценится за яркий цвет, тонкую горечь и мощные алхимические свойства.", itemType = "ingredient" },
    { id = "x32_IngMine_AstralSalt", description = "Кристаллические осадки, собранные с останков туманных атронахов, изгнанных со смертного плана.", itemType = "ingredient" },
    { id = "x32_IngMine_Celestine", description = "Светло-серый кристалл, который можно найти в местах с высокой концентрацией энергии пустоты. Помимо ограниченного алхимического применения, он известен своим свойством ярко гореть красным пламенем при попадании в огонь.", itemType = "ingredient" },

    -- Keys:
    { id = "x32_Key_FloralBlue", description = "Золотой ключ с ручкой в форме цветка, инкрустированный синими самоцветами, который открывает Лабораторию в Оранжерее.", itemType = "key" },
    { id = "x32_Key_FloralGreen", description = "Золотой ключ с ручкой в форме цветка, инкрустированный зелеными самоцветами, который открывает Пальмарий в Оранжерее.", itemType = "key" },
    { id = "x32_Key_FloralPurple", description = "Золотой ключ с ручкой в форме цветка, инкрустированный пурпурными самоцветами, который открывает Питомник в Оранжерее.", itemType = "key" },
    { id = "x32_Key_FloralRed", description = "Золотой ключ с ручкой в форме цветка, инкрустированный красными самоцветами, который открывает Студию в Оранжерее.", itemType = "key" },
    { id = "x32_Key_TheHauntedVoid01", description = "Ключ от двери в Блуждающей Пустоте в Саду.", itemType = "key" },
    { id = "x32_Key_TheShiftingHalls01", description = "Ключ от двери в Изменчивых залах в Саду.", itemType = "key" },

    -- Lights:
    { id = "x32_Light_BlkLanternCarry", description = "Фонарь изготовленный из желтого стекла и темного железа в необычном стиле, излучает свет в огромном радиусе.", itemType = "light" },

    -- Misc Items:
    { id = "x32_Misc_ArtPaintGreen", description = "Картина маслом в раме с изображением фонтана в большой оранжерее.", itemType = "miscItem" },
    { id = "x32_Misc_ArtPaintHollow", description = "Картина маслом в раме с изображением скелета, стоящего в каменном коридоре.", itemType = "miscItem" },
    { id = "x32_Misc_ArtPaintIsland", description = "Картина маслом в раме с изображением кораблекрушения на острове, под проливным дождем.", itemType = "miscItem" },
    { id = "x32_Misc_ArtPaintRooted", description = "Картина маслом в раме с изображением белых руин в темном лесу.", itemType = "miscItem" },
    { id = "x32_Misc_ArtPaintSpace", description = "Картина маслом в раме с изображением горящей жаровни на фоне окна, выходящего в пустоту.", itemType = "miscItem" },
    { id = "x32_Misc_ArtPaintSwords", description = "Картина маслом в раме с изображением раздробленного ландшафта, где доминируют гигантские золотые мечи и красные деревья.", itemType = "miscItem" },
    { id = "x32_Misc_ArtSketchSquare01", description = "Акварельный рисунок цветущих растений с заметками, описывающими их внешний вид.", itemType = "miscItem" },
    { id = "x32_Misc_ArtSketchSquare02", description = "Акварельный рисунок цветущего растения с заметками, описывающими его внешний вид.", itemType = "miscItem" },
    { id = "x32_Misc_ArtSketchTall01", description = "Акварельный рисунок цветущего растения с заметками, описывающими его внешний вид.", itemType = "miscItem" },
    { id = "x32_Misc_ArtSketchTall02", description = "Акварельный рисунок цветущего растения с заметками, описывающими его внешний вид.", itemType = "miscItem" },
    { id = "x32_Misc_ArtSketchTall03", description = "Акварельный рисунок цветущего растения с заметками, описывающими его внешний вид.", itemType = "miscItem" },
    { id = "x32_Misc_ArtSketchTall04", description = "Акварельный рисунок цветущего растения с заметками, описывающими его внешний вид.", itemType = "miscItem" },
    { id = "x32_Misc_ArtSketchWide01", description = "Акварельный рисунок ветви с красными листьями с заметками, описывающими ее внешний вид.", itemType = "miscItem" },
    { id = "x32_Misc_GardenCultivator", description = "Простой садовый инструмент, используемый для рыхления и аэрации почвы.", itemType = "miscItem" },
    { id = "x32_Misc_GardenHoe", description = "Простой садовый инструмент, используемый для рыхления почвы и удаления сорняков.", itemType = "miscItem" },
    { id = "x32_Misc_GardenTrowel", description = "Простой садовый инструмент, используемый для выкапывания лунок и перемещения грунта.", itemType = "miscItem" },
    { id = "x32_Misc_GardenWateringCan", description = "Простой садовый инструмент, используемый для полива растений.", itemType = "miscItem" },
    { id = "x32_Misc_KagiounHide", description = "Эта толстая шкура красного цвета с белыми и черными пятнами принадлежит кагиуну, обитающему в Cаду.", itemType = "miscItem" },

    --Quest:
    { id = "x32_a_UglyBoots", description = "Эти простые кожаные сапоги, сделанные из дубленой шкуры неизвестного животного, некоторые люди могли бы назвать уродливыми.", itemType = "quest" },
    { id = "x32_DuelSQLetter", description = "Секретный отчет Мораг Тонг, предупреждающий, что братья Седрин представляют собой опасную угрозу внутреннего кровопролития, если оставить их без внимания.", itemType = "quest" },
    { id = "x32_NobleSQLetter", description = "Письмо, осуждающее Мораг Тонг как еретиков манипуляторов, развязавших войну домов.", itemType = "quest" },
    { id = "X32_DoubtWritSelf", description = "Законный приказ о казни Фавила Ондора из Монастыря Мефалы для Мораг Тонг.", itemType = "scroll" },
    { id = "X32_SubtleWritOne", description = "Законный приказ о казни Адраса Хлорила для Мораг Тонг.", itemType = "quest" },
    { id = "X32_SubtleWritSelf", description = "Законный приказ о казни Рейнила Ондора из Кальдеры для Мораг Тонг.", itemType = "quest" },
    { id = "X32_SubtleWritThree", description = "Законный приказ о казни Саты Дротро для Мораг Тонг.", itemType = "quest" },
    { id = "X32_SubtleWritTwo", description = "Законный приказ о казни Фавена Селобара для Мораг Тонг.", itemType = "quest" },
    { id = "X32_ViolentWritOne", description = "Законный приказ о казни Дайнасы Аретил для Мораг Тонг.", itemType = "quest" },
    { id = "X32_ViolentWritSelf", description = "Законный приказ о казни Касила Шепарда из окрестностей Гнисиса для Мораг Тонг.", itemType = "quest" },
    { id = "X32_ViolentWritThree", description = "Законный приказ о казни Гилура Релета для Мораг Тонг.", itemType = "quest" },
    { id = "X32_ViolentWritTwo", description = "Законный приказ о казни Анары Ондор для Мораг Тонг.", itemType = "quest" },
    { id = "X32_WritLedgerDoubt", description = "Досье с подробностями возобновления и объемом исполнения судебных приказов о благородной казни в отношении семьи Ондор.", itemType = "quest" },
    { id = "X32_WritLedgerSubtle", description = "Сводный список целей Мораг Тонг с несколькими актуальными приказами, включающий информацию о местоположении жертвы, политические тонкости и предпочтительные методы убийства.", itemType = "quest" },
    { id = "x32_GoldThreadMk2", description = "Золотая нить, сплетенная из нитей судьбы.", itemType = "quest" },
    { id = "x32_GoldThread", description = "Золотая нить, сплетенная из нитей судьбы.", itemType = "quest" },
    { id = "x32_GoldThreadACT", description = "Золотая нить, сплетенная из нитей судьбы.", itemType = "quest" },

    -- Scrolls:
    { id = "x32_note_MelvinDisguise", description = "Пояснения для маскировки под Мелвина в Оранжерее.", itemType = "scroll" },
    { id = "x32_writ_open", description = "Ничем не примечательный приказ о казни.", itemType = "scroll" },
    { id = "x32_writ_rolled", description = "Ничем не примечательный приказ о казни.", itemType = "scroll" },
    { id = "x32_sc_PrayerWhiteTower", description = "Благочестивая молитва, воспевающая возведение белого города и выражающая надежду, что творения смертных смогут вознестись в божественную обитель.", itemType = "scroll" },

    -- Unique:
    { id = "X32_c_RDA", description = "Зачарованное кольцо, полученное от Мастера Искусного Убийства.", itemType = "unique" },
    { id = "x32_c_RSD", description = "Зачарованное кольцо, найденное у курьера Мораг Тонг.", itemType = "unique" },
    { id = "x32_a_FatedHelm", description = "Прочный шлем, который, как говорят, обладает силой возвращать своего носителя с порога смерти.", itemType = "unique" },
    { id = "x32_cEn_FloralAmulet01", description = "Амулет, полученный от Задави в награду за кражу подушек из Оранжереи.", itemType = "unique" },
    { id = "x32_idol_mephala", description = "Резной каменный идол, изображающий даэдрического Принца Мефалу, полученный в награду от Мораг Тонг.", itemType = "unique" },
    { id = "x32_Light_CreepyIdol01", description = "Над коленями этого каменного идола парит яркий золотистый предмет.", itemType = "unique" },
    { id = "x32_Misc_GoldenPitcher", description = "Золотой кувшин может вместить неограниченное количество воды.", itemType = "unique" },
    { id = "x32_Misc_GoldenPitcherFull", description = "Золотой кувшин может вместить неограниченное количество воды.", itemType = "unique" },
    { id = "x32_Misc_SproutHead", description = "Садового голема можно вырастить заново, если вернуть его горшок обратно в Питомник Оранжереи.", itemType = "unique" },
    { id = "x32_Misc_ZadaviPillow01", description = "Теперь это шелковая подушка Задави.", itemType = "unique" },
    { id = "x32_Misc_ZadaviPillow02", description = "Теперь это шелковая подушка Задави.", itemType = "unique" },
    { id = "x32_Misc_ZadaviPillow03", description = "Теперь это шелковая подушка Задави.", itemType = "unique" },
    { id = "x32_Light_goldensword", description = "Сверкающий золотой меч, предложенный Туманными Монархами для помощи в борьбе с Неудачей.", itemType = "unique" },
    { id = "x32_w_goldensword", description = "Сверкающий золотой меч, предложенный Туманными Монархами для помощи в борьбе с Неудачей.", itemType = "unique" },
    { id = "x32_w_Medalum", description = "Светящиеся руны, идущие по всей длине клинка этого меча, указывают на его имя - Медалум.", itemType = "unique" },
    { id = "x32_w_Medalum_s", description = "Светящиеся руны, идущие по всей длине клинка этого меча, указывают на его имя - Медалум.", itemType = "unique" },

    -- Weapons:
    { id = "x32_w_DaedricAssassin", description = ".", itemType = "weapon" },
    { id = "x32_w_ShardAxe", description = "Энергия пустоты исходит от этого топора, выкованного из туманного атронаха, который добровольно отдал свои останки для ритуала.", itemType = "unique" },
    { id = "x32_w_ShardDagger", description = "Энергия пустоты исходит от этого кинжала, выкованного из туманного атронаха, который добровольно отдал свои останки для ритуала.", itemType = "unique" },
    { id = "x32_w_ShardSpear", description = "Энергия пустоты исходит от этого копья, выкованного из туманного атронаха, который добровольно отдал свои останки для ритуала.", itemType = "unique" },
    { id = "x32_w_ShardSword", description = "Энергия пустоты исходит от этого меча, выкованного из туманного атронаха, который добровольно отдал свои останки для ритуала.", itemType = "unique" },
    { id = "x32_w_ShardAxeDull", description = "Топор, созданный путем связывания останков туманного атронаха.", itemType = "weapon" },
    { id = "x32_w_ShardDaggerDull", description = "Кинжал, созданный путем связывания останков туманного атронаха.", itemType = "weapon" },
    { id = "x32_w_ShardSpearDull", description = "Копье, созданное путем связывания останков туманного атронаха.", itemType = "weapon" },
    { id = "x32_w_ShardSwordDull", description = "Меч, созданный путем связывания останков туманного атронаха.", itemType = "weapon" }
}
    
for _, data in ipairs(tooltipData) do
    tooltipsComplete.addTooltip(data.id, data.description, data.itemType)
end
