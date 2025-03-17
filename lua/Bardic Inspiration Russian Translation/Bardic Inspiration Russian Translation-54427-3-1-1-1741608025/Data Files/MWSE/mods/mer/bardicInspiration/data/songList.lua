
local Song = require("mer.bardicInspiration.Song")
local messages = require("mer.bardicInspiration.messages.messages")

local songList = {
    beginner = {
        {
            name = "Ночи суджаммы",
            path = "mer_bard/beg/1.mp3",
            difficulty = "beginner",
        },
        {
            name = "Под грибным деревом",
            path = "mer_bard/beg/2.mp3",
            difficulty = "beginner",
        },
        {
            name = "Марш легиона",
            path = "mer_bard/beg/3.mp3",
            difficulty = "beginner",
        },
        {
            name = "Когда цветет вереск",
            path = "mer_bard/beg/4.mp3",
            difficulty = "beginner",
        },
        {
            name = "В свете Мары",
            path = "mer_bard/beg/5.mp3",
            difficulty = "beginner",
        },
        {
            name = "Забери меня, Эльсвейр",
            path = "mer_bard/beg/6.mp3",
            difficulty = "beginner",
        },
        {
            name = "Опускается ночь на Балмору",
            path = "mer_bard/beg/7.mp3",
            difficulty = "beginner",
        },
        {
            name = "Стендарр Милосердный",
            path = "mer_bard/beg/8.mp3",
            difficulty = "beginner",
        },
        {
            name = "Я влюбился в аргонианку",
            path = "mer_bard/beg/9.mp3",
            difficulty = "beginner",
        },
        {
            name = "Ода Хла Оуду",
            path = "mer_bard/beg/10.mp3",
            difficulty = "beginner",
        },
        {
            name = "Унеси меня на Секунду",
            path = "mer_bard/beg/11.mp3",
            difficulty = "beginner",
        },
        {
            name = "Над полями Кумму",
            path = "mer_bard/beg/12.mp3",
            difficulty = "beginner",
        },
        {
            name = "Одинокий скриб",
            path = "mer_bard/beg/13.mp3",
            difficulty = "beginner",
        },
        {
            name = "Дитя лунного сахара",
            path = "mer_bard/beg/14.mp3",
            difficulty = "beginner",
        },
        {
            name = "Ведьма и гардероб норда",
            path = "mer_bard/beg/15.mp3",
            difficulty = "beginner",
        },
        {
            name = "Долина ветра",
            path = "mer_bard/beg/16.mp3",
            difficulty = "beginner",
        },
    },
    intermediate = {
        {
            name = "Милашка кагути",
            path = "mer_bard/int/1.mp3",
            difficulty = "intermediate",
        },
        {
            name = "Полет скальных наездников",
            path = "mer_bard/int/2.mp3",
            difficulty = "intermediate",
        },
        {
            name = "Рукава мечты",
            path = "mer_bard/int/3.mp3",
            difficulty = "intermediate",
        },
        {
            name = "Ожидания Ноктюрнал",
            path = "mer_bard/int/4.mp3",
            difficulty = "intermediate",
        },
        {
            name = "Девушка из Альд Велоти",
            path = "mer_bard/int/5.mp3",
            difficulty = "intermediate",
        },
        {
            name = "Маленький квама, который смог",
            path = "mer_bard/int/6.mp3",
            difficulty = "intermediate",
        },
        {
            name = "Озадаченный гуар",
            path = "mer_bard/int/7.mp3",
            difficulty = "intermediate",
        },
        {
            name = "Имперский скакун",
            path = "mer_bard/int/8.mp3",
            difficulty = "intermediate",
        },
        {
            name = "Приключение начинается",
            path = "mer_bard/int/9.mp3",
            difficulty = "intermediate",
        },
        {
            name = "Конец урожая",
            path = "mer_bard/int/10.mp3",
            difficulty = "intermediate",
        },
        {
            name = "Улей квама",
            path = "mer_bard/int/11.mp3",
            difficulty = "intermediate",
        },
        {
            name = "Вой ветра",
            path = "mer_bard/int/12.mp3",
            difficulty = "intermediate",
        },
        {
            name = "Поход на рынок",
            path = "mer_bard/int/13.mp3",
            difficulty = "intermediate",
        },
        {
            name = "Дорога в Балмору",
            path = "mer_bard/int/14.mp3",
            difficulty = "intermediate",
        },
        {
            name = "Дух предка",
            path = "mer_bard/int/15.mp3",
            difficulty = "intermediate",
        },
    },
    advanced = {
        {
            name = "Заводной город",
            path = "mer_bard/pro/1.mp3",
            difficulty = "advanced",
        },
        {
            name = "Воин-поэт",
            path = "mer_bard/pro/2.mp3",
            difficulty = "advanced",
        },
        {
            name = "Пеплопад",
            path = "mer_bard/pro/3.mp3",
            difficulty = "advanced",
        },
        {
            name = "Жига",
            path = "mer_bard/pro/4.mp3",
            difficulty = "advanced",
        },
        {
            name = "Падающий пепел",
            path = "mer_bard/pro/5.mp3",
            difficulty = "advanced",
        },
        {
            name = "Прелюдия № 1",
            path = "mer_bard/pro/6.mp3",
            difficulty = "advanced",
        },
        {
            name = "Фантазия",
            path = "mer_bard/pro/6.mp3",
            difficulty = "advanced",
        },
    }
}
return songList