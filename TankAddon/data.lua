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

data.Defaults = {
    profile = {
        enabled = true,
        locked = false,
        always_show = true,
        frame_padding = 5,
        include_player = true,
        includePets = false,
        width = 80,
        height = 30,
        unit_padding = 5,
        font = "Fonts/FRIZQT__.TTF",
        font_size = 12
    }
}

data.OptionsTable = {
    name = "TankAddon",
    type = "group",
    args = {
        general = {
            name = "General Options",
            type = "group",
            order = 1,
            args = {
                enabled = {
                    name = "Enabled",
                    type = "toggle",
                    order = 0,
                    width = "full",
                    get = function(i)
                        return db.enabled
                    end,
                    set = function(i, v)
                        db.enabled = v
                        TA:OnOptionsUpdated()
                    end
                },
                locked = {
                    name = "Lock Frame Position",
                    type = "toggle",
                    order = 1,
                    width = "full",
                    get = function(i)
                        return db.locked
                    end,
                    set = function(i, v)
                        db.locked = v
                        TA:OnOptionsUpdated()
                    end
                },
                always_show = {
                    name = "Always Show Frame",
                    type = "toggle",
                    order = 2,
                    width = "full",
                    get = function(i)
                        return db.always_show
                    end,
                    set = function(i, v)
                        db.always_show = v
                        TA:OnOptionsUpdated()
                    end
                },
                frame_padding = {
                    name = "Unit Frame Padding",
                    type = "range",
                    min = 5,
                    max = 15,
                    step = 1,
                    order = 3,
                    width = "full",
                    get = function(i)
                        return db.frame_padding
                    end,
                    set = function(i, v)
                        db.frame_padding = v
                        TA:OnOptionsUpdated()
                    end
                },
                -- include_player = {
                --     name = "Inlcude Player",
                --     type = "toggle",
                --     order = 4,
                --     width = "full",
                --     get = function(i)
                --         return db.include_player
                --     end,
                --     set = function(i, v)
                --         db.include_player = v
                --         TA:OnOptionsUpdated()
                --     end
                -- },
                -- include_pets = {
                --     name = "Inlcude Pets",
                --     type = "toggle",
                --     order = 5,
                --     width = "full",
                --     get = function(i)
                --         return db.include_pets
                --     end,
                --     set = function(i, v)
                --         db.include_pets = v
                --         TA:OnOptionsUpdated()
                --     end
                -- },
                width = {
                    name = "Unit Width",
                    type = "range",
                    min = 50,
                    max = 120,
                    step = 1,
                    order = 6,
                    width = "full",
                    get = function(i)
                        return db.width
                    end,
                    set = function(i, v)
                        db.width = v
                        TA:OnOptionsUpdated()
                    end
                },
                height = {
                    name = "Unit Height",
                    type = "range",
                    min = 15,
                    max = 50,
                    step = 1,
                    order = 7,
                    width = "full",
                    get = function(i)
                        return db.height
                    end,
                    set = function(i, v)
                        db.height = v
                        TA:OnOptionsUpdated()
                    end
                },
                unit_padding = {
                    name = "Unit Padding",
                    type = "range",
                    min = 0,
                    max = 10,
                    step = 1,
                    order = 8,
                    width = "full",
                    get = function(i)
                        return db.unit_padding
                    end,
                    set = function(i, v)
                        db.unit_padding = v
                        TA:OnOptionsUpdated()
                    end
                },
                font_size = {
                    name = "Unit Font Size",
                    type = "range",
                    min = 8,
                    max = 18,
                    step = 2,
                    order = 9,
                    width = "full",
                    get = function(i)
                        return db.font_size
                    end,
                    set = function(i, v)
                        db.font_size = v
                        TA:OnOptionsUpdated()
                    end
                }
            }
        }
    }
}