local tooltipsComplete = include("Tooltips Complete.interop")
local tooltipData = {
    { id = "md24_inscguarhide", description = "Старая шкура гуара покрытая какими-то эзотерическими письменами.", itemType = "miscItem" },
    { id = "md24_c_ashbanegirdle", description = "Пояс, изготовленный из мягкой кожи и окрашенный в оттенки огненного заката, излучает легкое тепло, напоминающее огонь Красной Горы.", itemType = "clothing" },
	{ id = "md24_c_stoneofgrounding", description = "Поверхность камня испещрена шрамами от многократных ударов молнии.", itemType = "clothing" },
	{ id = "md24_c_thetwelfthtalisman", description = "В центре талисмана находится большой аквамариновый камень. А если прислушаться, то может показаться, что красочные ракушки, сплетенные вместе кожаными веревочками, нашептывают истории о далеких и забытых берегах.", itemType = "clothing" },
	{ id = "md24_c_thewhirlingband", description = "Гладкое эбонитовое кольцо, украшенное завитыми глифами, которые, кажется, танцуют и извиваются, словно язычки тумана. При ношении кольцо издает слабый гул, будто бы вторя самим ветрам.", itemType = "clothing" },
    { id = "md24_ingcrea_moonjelly", description = "Это светящееся желеобразное вещество добывается из молодых особей нетча, которых обычно называют \"лунными медузами\".", itemType = "ingredient" },
    { id = "md24_ingflor_lotusblood", description = "Редкий цветок Кровавого лотоса, для эшлендерских племен Морровинда, символизирует \"возрождение через смерть\".", itemType = "ingredient" },
    { id = "md24_clumsy_spear", description = "Необычайно острые шипы, на наконечнике этого хитинового копья, зачарован таким образом, чтобы оно лишало противника подвижности.", itemType = "weapon" },
    { id = "md24_sureflight_bow", description = "Этот высококачественный хитиновый лук был изготовлен воином Эрабенимсун и идеально подходит для охоты на дичь.", itemType = "weapon" }
}
local function initialized()
    if tooltipsComplete then
        for _, data in ipairs(tooltipData) do
            tooltipsComplete.addTooltip(data.id, data.description, data.itemType)
        end
    end
end
event.register("initialized", initialized)