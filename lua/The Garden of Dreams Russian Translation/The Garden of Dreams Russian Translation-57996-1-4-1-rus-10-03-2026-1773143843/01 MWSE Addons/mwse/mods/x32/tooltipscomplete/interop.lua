local tooltipsComplete = include("Tooltips Complete.interop")
if tooltipsComplete == nil then
    return
end

local tooltipData = {
    -- Alchemy:
    { id = "x32_mtpoison", description = "Медленно распространяющийся яд, которому могут потребоваться недели, чтобы убить свою жертву.", itemType = "alchemy" },

    -- Books:
    { id = "x32_bk_braziersecret", description = "Большая часть текста в этом дневнике закрашена мелкими мазками кисти.", itemType = "book" },
    { id = "x32_bk_oldbook", description = "Зловещие слова о смерти, вот и все, что осталось в этом ветхом томе.", itemType = "book" },
    { id = "x32_misfortunenotebook", description = "Записи о Саде, составленные на основе описаний повторяющихся форм, наблюдаемых разными посетителями.", itemType = "book" },

    -- Clothing:
    { id = "x32_c_butlersgloveleft", description = "Простая левая перчатка из плотной хлопковой ткани, которую обычно носят дворецкие.", itemType = "clothing" },
    { id = "x32_c_butlersgloveleftdisg", description = "Простая левая перчатка из плотной хлопковой ткани, которую обычно носят дворецкие.", itemType = "clothing" },
    { id = "x32_c_buttersgloveright", description = "Простая правая перчатка из плотной хлопковой ткани, которую обычно носят дворецкие.", itemType = "clothing" },
    { id = "x32_c_buttersgloverightdisg", description = "Простая правая перчатка из плотной хлопковой ткани, которую обычно носят дворецкие.", itemType = "clothing" },
    { id = "x32_c_melvindisguise", description = "Кажется, на этот каменный бюст наложено зачарование иллюзии.", itemType = "clothing" },
    { id = "x32_mtpinamuletdoubt", description = "Металлические булавки, благословленные Мефалой для отметки исполненных приказов.", itemType = "clothing" },

    -- Filled Soul Gems:
    { id = "x32_cre_mudcrab", description = "Захваченная душа запертого в клетке грязекраба, найденного в одном из планов Сада.", itemType = "creature" },
    { id = "x32_cre_beast3", description = "Захваченная душа Неудачи, искаженного воплощения Тирел Варас, извращенного силой Поля мертвецов и ее собственными ритуалами, превратившееся в нечто неестественное.", itemType = "creature" },
    { id = "x32_cre_goblinspace", description = "Захваченная душа Бакнами, гоблина обитающего в Пустоте.", itemType = "creature" },
    { id = "x32_cre_golemgarden01", description = "Захваченная душа садового голема, созданного из корней и заключенного в глину. Эти мирные создания неустанно трудятся, поддерживая целостность Сада.", itemType = "creature" },
    { id = "x32_cre_golemgarden02", description = "Захваченная душа садового голема, созданного из корней и заключенного в глину. Эти мирные создания неустанно трудятся, поддерживая целостность Сада.", itemType = "creature" },
    { id = "x32_cre_golemgarden03", description = "Захваченная душа садового голема, созданного из корней и заключенного в глину. Эти мирные создания неустанно трудятся, поддерживая целостность Сада.", itemType = "creature" },
    { id = "x32_cre_kagioun", description = "Захваченная душа кагиуна, огромной рептилии, которая охотится на заблудших духов в Саду.", itemType = "creature" },
    { id = "x32_cre_kagioun_duel", description = "Захваченная душа кагиуна, огромной рептилии, которая охотится на заблудших духов в Саду.", itemType = "creature" },
    { id = "x32_cre_kagiounalpha_q2", description = "Захваченная душа разъяренного кагиуна, который больше и опаснее большинства других, встречающихся в Саду.", itemType = "creature" },
    { id = "x32_dae_atrnebula_noagg", description = "Захваченная душа элементального даэдра. Туманные атронахи состоят из звездного вещества и энергии пустоты. Они не связаны ни с одним определенным Принцем, но считается, что они происходят из царства, известного как Туманность Между Мирами.", itemType = "creature" },
    { id = "x32_dae_atronachnebula", description = "Захваченная душа элементального даэдра. Туманные атронахи состоят из звездного вещества и энергии пустоты. Они не связаны ни с одним определенным Принцем, но считается, что они происходят из царства, известного как Туманность Между Мирами.", itemType = "creature" },
    { id = "x32_dae_atronachnefar", description = "Захваченная душа туманного атронаха, искаженного смертоносной силой Поля мертвецов, представляющего собой мертвый, огненный осколок его прежней формы.", itemType = "creature" },
    { id = "x32_skeleton_hammer01", description = "Захваченная душа скелета-варвара, чьи останки были оживлены для защиты Изменчивых залов.", itemType = "creature" },
    { id = "x32_skeleton_hammer02", description = "Захваченная душа скелета-варвара, чьи останки были оживлены для защиты Изменчивых залов.", itemType = "creature" },
    { id = "x32_und_ashenhusk", description = "Захваченная душа пепельной оболочки, обугленного тела, которое высвободилось от остальных из-за противоестественной силы Поля мертвецов.", itemType = "creature" },
    { id = "x32_und_ashenhusk_boss1", description = "Захваченная душа пепельной оболочки, обугленного тела, которое высвободилось от остальных из-за противоестественной силы Поля мертвецов.", itemType = "creature" },
    { id = "x32_und_ashenhusk_boss2", description = "Захваченная душа пепельной оболочки, обугленного тела, которое высвободилось от остальных из-за противоестественной силы Поля мертвецов.", itemType = "creature" },
    { id = "x32_und_ashenhuskcelest", description = "Захваченная душа пепельной оболочки, подвергшейся воздействию энергии пустоты от туманных атронахов, из-за чего из ее обугленного тела стал прорастать целестин.", itemType = "creature" },
    { id = "x32_und_ashenkag_boss", description = "Захваченная душа пепельного кагиуна, искаженного силой Поля мертвецов после того, как он забрел слишком далеко. Его тело обуглилось и стало нежитью.", itemType = "creature" },
    { id = "x32_und_ashenkagioun", description = "Захваченная душа пепельного кагиуна, искаженного силой Поля мертвецов после того, как он забрел слишком далеко. Его тело обуглилось и стало нежитью.", itemType = "creature" },
    { id = "x32_und_voidghost", description = "Захваченная душа призрака пустоты, таинственного неживого приведения, скитающегося по пустым пространствам Забвения.", itemType = "creature" },

    -- Ingredient:
    { id = "x32_cursedamethystghost", description = "Прозрачный фиолетовый драгоценный камень со скромными магическими свойствами.", itemType = "ingredient" },
    { id = "x32_ingflor_saffron", description = "Редкая багряная пряность, собранная с нежных рылец радужного цветка, ценится за яркий цвет, тонкую горечь и мощные алхимические свойства.", itemType = "ingredient" },
    { id = "x32_ingmine_astralsalt", description = "Кристаллические осадки, собранные с останков туманных атронахов, изгнанных со смертного плана.", itemType = "ingredient" },
    { id = "x32_ingmine_celestine", description = "Светло-серый кристалл, который можно найти в местах с высокой концентрацией энергии пустоты. Помимо ограниченного алхимического применения, он известен своим свойством ярко гореть красным пламенем при попадании в огонь.", itemType = "ingredient" },

    -- Keys:
    { id = "x32_key_floralblue", description = "Золотой ключ с ручкой в форме цветка, инкрустированный синими самоцветами, который открывает Лабораторию в Оранжерее.", itemType = "key" },
    { id = "x32_key_floralgreen", description = "Золотой ключ с ручкой в форме цветка, инкрустированный зелеными самоцветами, который открывает Пальмарий в Оранжерее.", itemType = "key" },
    { id = "x32_key_floralpurple", description = "Золотой ключ с ручкой в форме цветка, инкрустированный пурпурными самоцветами, который открывает Питомник в Оранжерее.", itemType = "key" },
    { id = "x32_key_floralred", description = "Золотой ключ с ручкой в форме цветка, инкрустированный красными самоцветами, который открывает Студию в Оранжерее.", itemType = "key" },
    { id = "x32_key_thehauntedvoid01", description = "Ключ от двери в Блуждающей Пустоте в Саду.", itemType = "key" },
    { id = "x32_key_theshiftinghalls01", description = "Ключ от двери в Изменчивых залах в Саду.", itemType = "key" },

    -- Lights:
    { id = "x32_light_blklanterncarry", description = "Фонарь изготовленный из желтого стекла и темного железа в необычном стиле, излучает свет в огромном радиусе.", itemType = "light" },

    -- Misc Items:
    { id = "x32_misc_artpaintgreen", description = "Картина маслом в раме с изображением фонтана в большой оранжерее.", itemType = "miscItem" },
    { id = "x32_misc_artpainthollow", description = "Картина маслом в раме с изображением скелета, стоящего в каменном коридоре.", itemType = "miscItem" },
    { id = "x32_misc_artpaintisland", description = "Картина маслом в раме с изображением кораблекрушения на острове, под проливным дождем.", itemType = "miscItem" },
    { id = "x32_misc_artpaintrooted", description = "Картина маслом в раме с изображением белых руин в темном лесу.", itemType = "miscItem" },
    { id = "x32_misc_artpaintspace", description = "Картина маслом в раме с изображением горящей жаровни на фоне окна, выходящего в пустоту.", itemType = "miscItem" },
    { id = "x32_misc_artpaintswords", description = "Картина маслом в раме с изображением раздробленного ландшафта, где доминируют гигантские золотые мечи и красные деревья.", itemType = "miscItem" },
    { id = "x32_misc_artsketchsquare01", description = "Акварельный рисунок цветущих растений с заметками, описывающими их внешний вид.", itemType = "miscItem" },
    { id = "x32_misc_artsketchsquare02", description = "Акварельный рисунок цветущего растения с заметками, описывающими его внешний вид.", itemType = "miscItem" },
    { id = "x32_misc_artsketchtall01", description = "Акварельный рисунок цветущего растения с заметками, описывающими его внешний вид.", itemType = "miscItem" },
    { id = "x32_misc_artsketchtall02", description = "Акварельный рисунок цветущего растения с заметками, описывающими его внешний вид.", itemType = "miscItem" },
    { id = "x32_misc_artsketchtall03", description = "Акварельный рисунок цветущего растения с заметками, описывающими его внешний вид.", itemType = "miscItem" },
    { id = "x32_misc_artsketchtall04", description = "Акварельный рисунок цветущего растения с заметками, описывающими его внешний вид.", itemType = "miscItem" },
    { id = "x32_misc_artsketchwide01", description = "Акварельный рисунок ветви с красными листьями с заметками, описывающими ее внешний вид.", itemType = "miscItem" },
    { id = "x32_misc_gardencultivator", description = "Простой садовый инструмент, используемый для рыхления и аэрации почвы.", itemType = "miscItem" },
    { id = "x32_misc_gardenhoe", description = "Простой садовый инструмент, используемый для рыхления почвы и удаления сорняков.", itemType = "miscItem" },
    { id = "x32_misc_gardentrowel", description = "Простой садовый инструмент, используемый для выкапывания лунок и перемещения грунта.", itemType = "miscItem" },
    { id = "x32_misc_gardenwateringcan", description = "Простой садовый инструмент, используемый для полива растений.", itemType = "miscItem" },
    { id = "x32_misc_kagiounhide", description = "Эта толстая шкура красного цвета с белыми и черными пятнами принадлежит кагиуну, обитающему в Cаду.", itemType = "miscItem" },

    --Quest:
    { id = "x32_a_uglyboots", description = "Эти простые кожаные сапоги, сделанные из дубленой шкуры неизвестного животного, некоторые люди могли бы назвать уродливыми.", itemType = "quest" },
    { id = "x32_duelsqletter", description = "Секретный отчет Мораг Тонг, предупреждающий, что братья Седрин представляют собой опасную угрозу внутреннего кровопролития, если оставить их без внимания.", itemType = "quest" },
    { id = "x32_noblesqletter", description = "Письмо, осуждающее Мораг Тонг как еретиков манипуляторов, развязавших войну домов.", itemType = "quest" },
    { id = "x32_doubtwritself", description = "Законный приказ о казни Фавила Ондора из Монастыря Мефалы для Мораг Тонг.", itemType = "scroll" },
    { id = "x32_subtlewritone", description = "Законный приказ о казни Адраса Хлорила для Мораг Тонг.", itemType = "quest" },
    { id = "x32_subtlewritself", description = "Законный приказ о казни Рейнила Ондора из Кальдеры для Мораг Тонг.", itemType = "quest" },
    { id = "x32_subtlewritthree", description = "Законный приказ о казни Саты Дротро для Мораг Тонг.", itemType = "quest" },
    { id = "x32_subtlewrittwo", description = "Законный приказ о казни Фавена Селобара для Мораг Тонг.", itemType = "quest" },
    { id = "x32_violentwritone", description = "Законный приказ о казни Дайнасы Аретил для Мораг Тонг.", itemType = "quest" },
    { id = "x32_violentwritself", description = "Законный приказ о казни Касила Шепарда из окрестностей Гнисиса для Мораг Тонг.", itemType = "quest" },
    { id = "x32_violentwritthree", description = "Законный приказ о казни Гилура Релета для Мораг Тонг.", itemType = "quest" },
    { id = "x32_violentwrittwo", description = "Законный приказ о казни Анары Ондор для Мораг Тонг.", itemType = "quest" },
    { id = "x32_writledgerdoubt", description = "Досье с подробностями возобновления и объемом исполнения судебных приказов о благородной казни в отношении семьи Ондор.", itemType = "quest" },
    { id = "x32_writledgersubtle", description = "Сводный список целей Мораг Тонг с несколькими актуальными приказами, включающий информацию о местоположении жертвы, политические тонкости и предпочтительные методы убийства.", itemType = "quest" },
    { id = "x32_goldthreadmk2", description = "Золотая нить, сплетенная из нитей судьбы.", itemType = "quest" },
    { id = "x32_goldthread", description = "Золотая нить, сплетенная из нитей судьбы.", itemType = "quest" },
    { id = "x32_goldthreadact", description = "Золотая нить, сплетенная из нитей судьбы.", itemType = "quest" },

    -- Scrolls:
    { id = "x32_note_melvindisguise", description = "Пояснения для маскировки под Мелвина в Оранжерее.", itemType = "scroll" },
    { id = "x32_writ_open", description = "Ничем не примечательный приказ о казни.", itemType = "scroll" },
    { id = "x32_writ_rolled", description = "Ничем не примечательный приказ о казни.", itemType = "scroll" },
    { id = "x32_sc_prayerwhitetower", description = "Благочестивая молитва, воспевающая возведение белого города и выражающая надежду, что творения смертных смогут вознестись в божественную обитель.", itemType = "scroll" },

    -- Unique:
    { id = "x32_c_rda", description = "Зачарованное кольцо, полученное от Мастера Искусного Убийства.", itemType = "unique" },
    { id = "x32_c_rsd", description = "Зачарованное кольцо, найденное у курьера Мораг Тонг.", itemType = "unique" },
    { id = "x32_a_fatedhelm", description = "Прочный шлем, который, как говорят, обладает силой возвращать своего носителя с порога смерти.", itemType = "unique" },
    { id = "x32_cen_floralamulet01", description = "Амулет, полученный от Задави в награду за кражу подушек из Оранжереи.", itemType = "unique" },
    { id = "x32_idol_mephala", description = "Резной каменный идол, изображающий даэдрического Принца Мефалу, полученный в награду от Мораг Тонг.", itemType = "unique" },
    { id = "x32_light_creepyidol01", description = "Над коленями этого каменного идола парит яркий золотистый предмет.", itemType = "unique" },
    { id = "x32_misc_goldenpitcher", description = "Золотой кувшин может вместить неограниченное количество воды.", itemType = "unique" },
    { id = "x32_misc_goldenpitcherfull", description = "Золотой кувшин может вместить неограниченное количество воды.", itemType = "unique" },
    { id = "x32_misc_sprouthead", description = "Садового голема можно вырастить заново, если вернуть его горшок обратно в Питомник Оранжереи.", itemType = "unique" },
    { id = "x32_misc_zadavipillow01", description = "Теперь это шелковая подушка Задави.", itemType = "unique" },
    { id = "x32_misc_zadavipillow02", description = "Теперь это шелковая подушка Задави.", itemType = "unique" },
    { id = "x32_misc_zadavipillow03", description = "Теперь это шелковая подушка Задави.", itemType = "unique" },
    { id = "x32_light_goldensword", description = "Сверкающий золотой меч, предложенный Туманными Монархами для помощи в борьбе с Неудачей.", itemType = "unique" },
    { id = "x32_w_goldensword", description = "Сверкающий золотой меч, предложенный Туманными Монархами для помощи в борьбе с Неудачей.", itemType = "unique" },
    { id = "x32_w_medalum", description = "Светящиеся руны, идущие по всей длине клинка этого меча, указывают на его имя - Медалум.", itemType = "unique" },
    { id = "x32_w_medalum_s", description = "Светящиеся руны, идущие по всей длине клинка этого меча, указывают на его имя - Медалум.", itemType = "unique" },

    -- Weapons:
    { id = "x32_w_daedricassassin", description = ".", itemType = "weapon" },
    { id = "x32_w_shardaxe", description = "Энергия пустоты исходит от этого топора, выкованного из туманного атронаха, который добровольно отдал свои останки для ритуала.", itemType = "unique" },
    { id = "x32_w_sharddagger", description = "Энергия пустоты исходит от этого кинжала, выкованного из туманного атронаха, который добровольно отдал свои останки для ритуала.", itemType = "unique" },
    { id = "x32_w_shardspear", description = "Энергия пустоты исходит от этого копья, выкованного из туманного атронаха, который добровольно отдал свои останки для ритуала.", itemType = "unique" },
    { id = "x32_w_shardsword", description = "Энергия пустоты исходит от этого меча, выкованного из туманного атронаха, который добровольно отдал свои останки для ритуала.", itemType = "unique" },
    { id = "x32_w_shardaxedull", description = "Топор, созданный путем связывания останков туманного атронаха.", itemType = "weapon" },
    { id = "x32_w_sharddaggerdull", description = "Кинжал, созданный путем связывания останков туманного атронаха.", itemType = "weapon" },
    { id = "x32_w_shardspeardull", description = "Копье, созданное путем связывания останков туманного атронаха.", itemType = "weapon" },
    { id = "x32_w_shardsworddull", description = "Меч, созданный путем связывания останков туманного атронаха.", itemType = "weapon" }
}
    
for _, data in ipairs(tooltipData) do
    tooltipsComplete.addTooltip(data.id, data.description, data.itemType)
end