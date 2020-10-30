data = {}

data.ClassData = {
    DEATHKNIGHT = {
        spec = "Blood",
        tauntSpellName = "Dark Command",
        tauntSpellId = 56222
    },
    DEMONHUNTER = {
        spec = "Vengeance",
        tauntSpellName = "Torment",
        tauntSpellId = 185245
    },
    DRUID = {
        spec = "Guardian",
        tauntSpellName = "Growl",
        tauntSpellId = 6795
    },
    MONK = {
        spec = "Brewmaster",
        tauntSpellName = "Provoke",
        tauntSpellId = 115546
    },
    PALADIN = {
        spec = "Protection",
        tauntSpellName = "Hand of Reckoning",
        tauntSpellId = 62124
    },
    WARRIOR = {
        spec = "Protection",
        tauntSpellName = "Taunt",
        tauntSpellId = 355
    }
}

data.Options = {
    enabled = {
        type = "boolean",
        default = true
    },
    locked = {
        type = "boolean",
        default = false
    },
    always_show = {
        type = "boolean",
        default = true
    },
    frame_padding = {
        type = "number",
        min = 5,
        max = 15,
        step = 1,
        default = 5
    },
    -- include_player = true,
    -- includePets = false,
    width = {
        type = "number",
        min = 50,
        max = 120,
        step = 1,
        default = 80
    },
    height = {
        type = "number",
        min = 15,
        max = 50,
        step = 1,
        default = 30
    },
    unit_padding = {
        type = "number",
        min = 0,
        max = 10,
        step = 1,
        default = 5
    },
    -- font = "Fonts/FRIZQT__.TTF",
    font_size = {
        type = "number",
        min = 8,
        max = 18,
        step = 2,
        default = 12
    }
}
