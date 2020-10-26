local TA = LibStub("AceAddon-3.0"):NewAddon("TankAddon", "AceEvent-3.0", "AceConsole-3.0")
TA.version = GetAddOnMetadata("TankAddon", "Version")
TA.versionString = "TankAddon v" .. GetAddOnMetadata("TankAddon", "Version")

local isTesting = false
local isEnabled = true
local inCombat = false
local playerRole
local threatPercentDivisor = 100
local classNameLocalized, class, classIndex, specIndex, spec
local tauntSpellId, tauntSpellName
local inParty, inRaid
local maxWidth, maxHeight
local maxUnitFrames = 40
local unitFrameColumnCount = 5
local groupGuidList = {}
local db

local ClassData = {
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

local Defaults = {
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

local OptionsTable = {
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

local function log(...)
    if isTesting then
        print(...)
    end
end

local function GetTableCount(tbl)
    local count = 0

    for _ in pairs(tbl) do
        count = count + 1
    end

    return count
end

function TA:OnInitialize()
    log("OnInitialize")
    self:SetupDB()
    self:SetupOptions(self.db)
    self:CreateFrames()
    self.OnInitialize = nil
end

function TA:OnEnable()
    log("OnEnable")
    print(self.versionString, "loaded")

    self:RegisterEvent("PLAYER_ENTERING_WORLD")
    self:RegisterEvent("ACTIVE_TALENT_GROUP_CHANGED")
    self:RegisterEvent("GROUP_ROSTER_UPDATE")
    self:RegisterEvent("UNIT_THREAT_LIST_UPDATE")
    self:RegisterEvent("UNIT_THREAT_SITUATION_UPDATE")
    self:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
    self:RegisterEvent("PLAYER_LEAVE_COMBAT")
    self:RegisterEvent("PLAYER_REGEN_ENABLED")
    self:RegisterEvent("PLAYER_REGEN_DISABLED")
end

function TA:OnDisable()
    log("OnDisable")
end

function TA:PLAYER_ENTERING_WORLD(isInitialLogin, isReloadingUi)
    log("PLAYER_ENTERING_WORLD")
    classNameLocalized, class, classIndex = UnitClass("player")

    self:UpdatePlayerSpec()
    self:UpdatePlayerGroupState()
    self:UpdateGroupGuidList()
    self:UpdateGroupFrameUnits()
end

function TA:ACTIVE_TALENT_GROUP_CHANGED()
    log("ACTIVE_TALENT_GROUP_CHANGED")
    self:UpdatePlayerSpec()
end

function TA:GROUP_ROSTER_UPDATE()
    log("GROUP_ROSTER_UPDATE")
    self:UpdatePlayerSpec()
    self:UpdatePlayerGroupState()
    self:UpdateGroupGuidList()
    self:UpdateGroupFrameUnits()
end

function TA:COMBAT_LOG_EVENT_UNFILTERED(...)
    -- log("COMBAT_LOG_EVENT_UNFILTERED")
    -- local timestamp,
    --     subevent,
    --     _,
    --     sourceGUID,
    --     sourceName,
    --     sourceFlags,
    --     sourceRaidFlags,
    --     destGUID,
    --     destName,
    --     destFlags,
    --     destRaidFlags = CombatLogGetCurrentEventInfo()
    -- if self:InGroup(destGUID) then
    --     log("CLEU:", subevent, sourceName, destName)
    -- end
    -- self:UpdateUnitFramesThreat()
end

function TA:UNIT_THREAT_LIST_UPDATE(_, target)
    log("UNIT_THREAT_LIST_UPDATE")
    self:UpdateUnitFramesThreat()
end

function TA:UNIT_THREAT_SITUATION_UPDATE(_, target)
    log("UNIT_THREAT_SITUATION_UPDATE")
    self:UpdateUnitFramesThreat()
end

function TA:PLAYER_LEAVE_COMBAT()
    log("PLAYER_LEAVE_COMBAT")
    self.GroupFrame:ResetUnitFramesThreat()
end

function TA:PLAYER_REGEN_ENABLED()
    log("PLAYER_REGEN_ENABLED")
    self.GroupFrame:ResetUnitFramesThreat()

    if not db.always_show or not db.enabled then
        self.GroupFrame:Hide()
    end
end

function TA:PLAYER_REGEN_DISABLED()
    log("PLAYER_REGEN_DISABLED")
    self.GroupFrame:ResetUnitFramesThreat()

    if db.enabled and not self.GroupFrame:IsVisible() then
        self.GroupFrame:Show()
    end
end

function TA:UpdatePlayerSpec()
    log("UpdatePlayerSpec")
    specIndex = GetSpecialization()
    spec = specIndex and select(2, GetSpecializationInfo(specIndex)) or "None"

    if ClassData[class] and ClassData[class]["spec"] == spec then
        tauntSpellId, tauntSpellName = ClassData[class]["tauntSpellId"], ClassData[class]["tauntSpellName"]
    end
end

function TA:UpdatePlayerGroupState()
    log("UpdatePlayerGroupState")
    inParty = IsInGroup()
    inRaid = IsInRaid()
    playerRole = UnitGroupRolesAssigned("player")
end

function TA:UpdateGroupGuidList()
    log("UpdateGroupGuidList")
    wipe(groupGuidList)

    if not inRaid and db.include_player then
        groupGuidList["player"] = {
            guid = UnitGUID("player"),
            name = UnitName("player"),
            target = "target"
        }
    end

    if inRaid then
        for i = 1, GetNumGroupMembers() do
            local unit = format("raid%d", i)
            local target = format("raid%dtarget", i)

            if UnitExists(unit) then
                groupGuidList[unit] = {
                    guid = UnitGUID(unit),
                    name = UnitName(unit),
                    target = target
                }
            end
        end
    elseif inParty then
        for i = 1, GetNumSubgroupMembers() do
            local unit = format("party%d", i)
            local target = format("party%dtarget", i)

            if UnitExists(unit) then
                groupGuidList[unit] = {
                    guid = UnitGUID(unit),
                    name = UnitName(unit),
                    target = target
                }
            end
        end
    elseif isTesting then
        for i = 1, maxUnitFrames - 1 do -- minus one here to account for added player unit frame
            local unit = "player"
            local target = "target"

            groupGuidList[unit..i] = {
                guid = UnitGUID("player"),
                name = UnitName("player"),
                target = target
            }
        end
    end
end

function TA:UpdateGroupFrameUnits()
    log("UpdateGroupFrameUnits")
    if groupGuidList then
        local unitCount = GetTableCount(groupGuidList)
        log("unitCount:", unitCount)

        local groupFrameWidth = (db.width + (db.unit_padding)) * unitCount
        local groupFrameHeight = db.height

        if groupFrameWidth > maxWidth then
            groupFrameWidth = maxWidth
            local rows = math.floor(unitCount / unitFrameColumnCount)
            if rows * unitFrameColumnCount < unitCount then rows = rows + 1 end
            groupFrameHeight = ((groupFrameHeight + db.unit_padding) * rows) - db.unit_padding
        end

        groupFrameWidth = groupFrameWidth + (db.frame_padding * 2) - db.unit_padding
        groupFrameHeight = groupFrameHeight + (db.frame_padding * 2)

        self.GroupFrame:SetWidth(groupFrameWidth)
        self.GroupFrame:SetHeight(groupFrameHeight)

        self.GroupFrame:ResetUnitFrames()

        local unitFrameIndex = 1
        local unitFrames = self.GroupFrame:GetChildren()

        for unit, data in pairs(groupGuidList) do
            local unitFrame = self.GroupFrame:GetUnitFrame(format("UnitFrame%d", unitFrameIndex))
            local unitName = data["name"]

            if unitFrame then
                unitFrame:SetBackdropColor(0, 0, 0, 1)

                if unitName ~= UnitName("player") then
                    if playerRole == "TANK" and tauntSpellName then
                        unitFrame:SetAttribute("type", "spell")
                        unitFrame:SetAttribute("spell", tauntSpellName)
                        unitFrame:SetAttribute("unit", data["target"])
                    else
                        unitFrame:SetAttribute("type", "assist")
                        unitFrame:SetAttribute("unit", data["target"])
                    end
                end

                unitFrame.unit = unit
                unitFrame:SetRole(UnitGroupRolesAssigned(unit))
                unitFrame.text:SetText(UnitName(unit))
                unitFrame:Show()
            else
                log("UpdateGroupFrameUnits nil unitFrame for unit:", unit)
            end

            unitFrameIndex = unitFrameIndex + 1
        end
    end
end

function TA:GetGroupUnit(unit)
    log("GetGroupUnit")
    if groupGuidList then
        if groupGuidList[unit] or groupGuidList[UnitGUID(unit)] then
            return unit
        else
            for u, d in pairs(groupGuidList) do
                if d["name"] == unit or d["name"] == UnitName(unit) then
                    return u
                end
            end
        end
    end

    return nil
end

function TA:InGroup(unit)
    log("InGroup")
    if self:GetGroupUnit(unit) then
        return true
    else
        return false
    end
end

function TA:UpdateUnitFramesThreat()
    log("UpdateUnitFramesThreat")
    
    if not inRaid and db.include_player then
        local playerIsTanking, playerThreatStatus, playerThreatPct, playerRawThreatPct, playerThreatValue =
            UnitDetailedThreatSituation("player", "target")

        if playerThreatPct then
            self.GroupFrame:UpdateThreatForUnit("player", (playerThreatPct / threatPercentDivisor))
        end
    end

    local groupGuidList = groupGuidList

    if groupGuidList then
        for unit, data in pairs(groupGuidList) do
            local isTanking, threatStatus, threatPct, rawThreatPct, threatValue =
                UnitDetailedThreatSituation(unit, data["target"])

            if threatPct then
                self.GroupFrame:UpdateThreatForUnit(unit, (threatPct / threatPercentDivisor))
            end

            -- local threatSituation = UnitThreatSituation(unit) or 0

            -- if threatSituation > 0 then
            --     if not self:InGroup(data["target"]) then
            --         -- target is not in group, check threat
            --         local isTanking, threatStatus, threatPct, rawThreatPct, threatValue =
            --             UnitDetailedThreatSituation(unit, data["target"])

            --         if threatPct then
            --             self.GroupFrame:UpdateThreatForUnit(unit, (threatPct / threatPercentDivisor))
            --         end
            --     else
            --         local unitTargetTarget = data["target"] .. "target"

            --         if not self:InGroup(unitTargetTarget) then
            --             local isTanking, threatStatus, threatPct, rawThreatPct, threatValue =
            --                 UnitDetailedThreatSituation(unit, unitTargetTarget)

            --             if threatPct then
            --                 self.GroupFrame:UpdateThreatForUnit(unit, (threatPct / threatPercentDivisor))
            --             end
            --         else
            --             self.GroupFrame:UpdateThreatForUnit(unit, (1 / threatSituation))
            --         end
            --     end
            -- else
            --     self.GroupFrame:UpdateThreatForUnit(unit, 0)
            -- end
        end
    end
end

function TA:SetupDB()
    log("SetupDB")

    self.db = LibStub("AceDB-3.0"):New("TankAddonDB", Defaults, "Default")
    self.db.RegisterCallback(self, "OnProfileChanged", "OnProfileChanged")
    self.db.RegisterCallback(self, "OnProfileCopied", "OnProfileChanged")
    self.db.RegisterCallback(self, "OnProfileReset", "OnProfileChanged")

    db = self.db.profile

    self.SetupDB = nil
end

function TA:SetupOptions()
    log("SetupOptions")
    -- OptionsTable.args.profiles = LibStub("AceDBOptions-3.0"):GetOptionsTable(self.db)

    local ACR = LibStub("AceConfigRegistry-3.0")
    ACR:RegisterOptionsTable("TankAddon", OptionsTable)
    ACR:NotifyChange("TankAddon")

    LibStub("AceConfig-3.0"):RegisterOptionsTable("TankAddon", OptionsTable, { "ta", "tankaddon" })

    self.OptionsFrame = LibStub("AceConfigDialog-3.0"):AddToBlizOptions("TankAddon")

    self.SetupDBAndOptions = nil
end

function TA:OnProfileChanged()
    log("OnProfileChanged")
    self:OnOptionsUpdated()
end

function TA:OnOptionsUpdated()
    log("OnOptionsUpdated")
    maxWidth = ((db.width + (db.unit_padding)) * unitFrameColumnCount) - db.unit_padding
    maxHeight = ((db.height + (db.unit_padding)) * unitFrameColumnCount) - db.unit_padding

    local unitCount = GetTableCount(groupGuidList)
    local groupFrameWidth = (db.width + (db.unit_padding)) * unitCount
    local groupFrameHeight = db.height

    if groupFrameWidth > maxWidth then
        groupFrameWidth = maxWidth
        local rows = math.floor(unitCount / unitFrameColumnCount)
        if rows * unitFrameColumnCount < unitCount then rows = rows + 1 end
        groupFrameHeight = ((groupFrameHeight + db.unit_padding) * rows) - db.unit_padding
    end

    groupFrameWidth = groupFrameWidth + (db.frame_padding * 2) - db.unit_padding
    groupFrameHeight = groupFrameHeight + (db.frame_padding * 2)

    self.GroupFrame:SetWidth(groupFrameWidth)
    self.GroupFrame:SetHeight(groupFrameHeight)

    if (not db.always_show and not inCombat) or not db.enabled then
        self.GroupFrame:Hide()
    elseif db.always_show and db.enabled then
        self.GroupFrame:Show()
    end

    local offsetX = db.frame_padding
    local offsetY = db.frame_padding

    for _, child in ipairs({self.GroupFrame:GetChildren()}) do
        child:SetWidth(db.width)
        child:SetHeight(db.height)
        child.text:SetFont(db.font, db.font_size)

        local unitName = child:GetName()

        if (unitName == "player" and db.include_player) or unitName ~= "player" then
            child.text:SetFont(db.font, db.font_size)
            child:SetPoint("BOTTOMLEFT", self.GroupFrame, offsetX, offsetY)

            offsetX = offsetX + (db.width + db.unit_padding)

            if offsetX > maxWidth then
                offsetX = db.frame_padding
                offsetY = offsetY + (db.height + db.unit_padding)
            end
        end
    end
end

function TA:CreateFrames()
    log("CreateFrames")
    maxWidth = ((db.width + (db.unit_padding)) * unitFrameColumnCount) - db.unit_padding
    maxHeight = ((db.height + (db.unit_padding)) * unitFrameColumnCount) - db.unit_padding

    -- used fix provided by the_notorious_thug
    self.GroupFrame = CreateFrame("Frame", "TankAddonGroupFrame", UIParent, BackdropTemplateMixin and "BackdropTemplate")

    self.GroupFrame:SetFrameStrata("MEDIUM")
    self.GroupFrame:SetMovable(true)
    self.GroupFrame:EnableMouse(true)
    self.GroupFrame:SetBackdrop({ bgFile = "Interface/Tooltips/UI-Tooltip-Background" })
    self.GroupFrame:SetBackdropColor(0, 0, 0, 0.8)
    self.GroupFrame:ClearAllPoints()
    self.GroupFrame:SetPoint("CENTER", UIParent, "BOTTOMLEFT", 1920 / 2, 1080 / 2)
    
    if not db.always_show then
        self.GroupFrame:Hide()
    end

    self.GroupFrame:RegisterForDrag("LeftButton")

    self.GroupFrame:SetScript("OnDragStart", function(self)
        if not db.locked then
            self:StartMoving()
        end
    end)

    self.GroupFrame:SetScript("OnDragStop", function(self)
        if not db.locked then
            self:StopMovingOrSizing()
        end
    end)

    function self.GroupFrame:GetUnitFrame(name)
        for _, child in ipairs({self:GetChildren()}) do
            if child:GetName() == name then
                return child
            end
        end

        return nil
    end
    
    function self.GroupFrame:GetUnitFrameForUnit(unit)
        for _, child in ipairs({self:GetChildren()}) do
            if child.unit == unit then
                return child
            end
        end

        return nil
    end

    function self.GroupFrame:UpdateThreatForUnit(unit, threatPct)
        local child = self:GetUnitFrameForUnit(unit)
        if child then
            child:SetThreatPercent(threatPct)
        else
            log("UpdateThreatForUnit nil child for unit:", unit, ", threatPct:", threatPct)
        end
    end

    function self.GroupFrame:ResetUnitFramesThreat()
        for _, child in ipairs({self:GetChildren()}) do
            child:SetThreatPercent(0)
        end
    end

    function self.GroupFrame:ResetUnitFrames()
        for _, child in ipairs({self:GetChildren()}) do
            child.unit = nil
            child.text:SetText(nil)
            child:Hide()
        end
    end

    local currentUnitOffsetX = db.frame_padding
    local currentUnitOffsetY = db.frame_padding

    for i = 1, maxUnitFrames do
        -- used fix provided by the_notorious_thug
        local button = CreateFrame("Button", format("UnitFrame%d", i), self.GroupFrame, BackdropTemplateMixin and "BackdropTemplate")
        button:SetWidth(db.width)
        button:SetHeight(db.height)
        button:SetBackdrop({ bgFile = "Interface/Tooltips/UI-Tooltip-Background" })
        button:SetPoint("BOTTOMLEFT", parent, currentUnitOffsetX, currentUnitOffsetY)
        button.unit = nil

        button.texture = button:CreateTexture(nil, "PARENT")
        button.texture:SetColorTexture(1, 1, 1, 1)
        button.texture:SetAllPoints(button)
        button.texture:SetGradientAlpha("VERTICAL", 1, 0, 0, 0, 0, 0, 0, 0)

        button.text = button:CreateFontString(nil, "ARTWORK")
        button.text:SetFont(db.font, db.font_size)
        button.text:SetPoint("CENTER", button, "CENTER")

        button.badge = button:CreateTexture(nil, "PARENT")
        button.badge:SetSize(20, 20)
        button.badge:SetTexture(2202478)
        button.badge:SetPoint("TOPLEFT", -5, 5)

        button:Hide()

        function button:SetThreatPercent(alpha)
            button.texture:SetGradientAlpha("VERTICAL", 1, 0, 0, alpha, alpha, 0, 0, 0)
        end

        function button:SetRole(role)
            if role == "TANK" then
                button.badge:SetTexCoord(.523, .757, 0, 1)
            elseif role == "HEALER" then
                button.badge:SetTexCoord(.265, .492, 0, 1)
            elseif role == "DAMAGER" then
                button.badge:SetTexCoord(.007, .242, 0, 1)
            else
                button.badge:SetTexCoord(.76, 1, 0, 1)
            end
        end

        currentUnitOffsetX = currentUnitOffsetX + (db.width + db.unit_padding)

        if currentUnitOffsetX > maxWidth then
            currentUnitOffsetX = db.frame_padding
            currentUnitOffsetY = currentUnitOffsetY + (db.height + db.unit_padding)
        end
    end

    self:OnOptionsUpdated()
end
