local title = ...
local version = GetAddOnMetadata(title, "Version")

-- sdb:set_debug()

-- local variables:
local isEnabled = true
local inCombat = false
local playerRole
local threatPercentDivisor = 100
local classNameLocalized, class, classIndex
local specIndex, spec
local tauntSpellId, tauntSpellName
local inParty, inRaid
local maxWidth, maxHeight
local maxUnitFrames = 40
local unitFrameColumnCount = 5
local groupGuidList = {}
local include_player = true
local db

-- addon:
local addon = CreateFrame("Frame", title)

-- slash commands:
SLASH_TANKADDON1, SLASH_TANKADDON2 = "/tankaddon", "/ta"

function addon:HandleSlashCommand(msg)
    local _, _, cmd, argsString = string.find(msg, "%s?(%w+)%s?(.*)")
    
    cmd = cmd or "help"
    argsString = argsString or ""

    local slashCmd = "HandleSlashCommand_" .. cmd
    local args = {strsplit(" ", argsString)}

    sdb:log_debug("HandleSlashCommand: ", cmd, argsString)

    if cmd == "help" then
        sdb:log_info("TankAddon v" .. version .. " slash command help")
        sdb:log_info("syntax: /tankaddon (or /ta) command arg1 arg2")
        sdb:log_info("command: 'help': this message")
        sdb:log_info(
            "command: 'get', arg1: OPTION_NAME or 'all': show the value of the OPTION_NAME or values of all options")
        sdb:log_info("command: 'set', arg1: OPTION_NAME, arg2: VALUE: set the OPTION_NAME to the VALUE")
        sdb:log_info("command: 'reset': sets all options to the default values")
    elseif cmd == "get" then
        if sdb:contains(db, args[1]) then
            sdb:log_info(args[1] .. " = ", db[args[1]])
        elseif args[1] == "all" then
            table.foreach(db, function(k, v)
                sdb:log_info(k .. " = ", v)
            end)
        else
            sdb:log_error("unknown property: ", args[1])
        end
    elseif cmd == "set" then
        if sdb:contains(data.Options, args[1]) then
            local val

            if data.Options[args[1]].type == "boolean" then
                val = args[2] == "true" or false
            elseif data.Options[args[1]].type == "number" then
                val = tonumber(args[2])

                if sdb:contains(data.Options[args[1]], "step") then
                    val = val - (val % data.Options[args[1]].step)
                end

                if sdb:contains(data.Options[args[1]], "min") then
                    if val < data.Options[args[1]].min then
                        val = data.Options[args[1]].min
                    end
                end

                if sdb:contains(data.Options[args[1]], "max") then
                    if val > data.Options[args[1]].max then
                        val = data.Options[args[1]].max
                    end
                end
            else
                val = args[2]
            end

            db[args[1]] = val

            sdb:log_info(args[1] .. " = ", db[args[1]])

            self:OnOptionsUpdated()
        else
            sdb:log_error("unknown setting: " .. args[1])
        end
    elseif cmd == "reset" then
        db = sdb:GetOptionDefaults(data.Options)

        table.foreach(db, function(k, v)
            sdb:log_info(k .. " = ", v)
        end)

        self:OnOptionsUpdated()
    elseif cmd == "locals" then
        sdb:log_debug("isEnabled = ", isEnabled)
        sdb:log_debug("inCombat = ", inCombat)
        sdb:log_debug("playerRole = ", playerRole)
        sdb:log_debug("threatPercentDivisor = ", threatPercentDivisor)
        sdb:log_debug("classNameLocalized = ", classNameLocalized)
        sdb:log_debug("class = ", class)
        sdb:log_debug("classIndex = ", classIndex)
        sdb:log_debug("specIndex = ", specIndex)
        sdb:log_debug("spec = ", spec)
        sdb:log_debug("tauntSpellId = ", tauntSpellId)
        sdb:log_debug("tauntSpellName = ", tauntSpellName)
        sdb:log_debug("inParty = ", inParty)
        sdb:log_debug("inRaid = ", inRaid)
        sdb:log_debug("maxWidth = ", maxWidth)
        sdb:log_debug("maxHeight = ", maxHeight)
        sdb:log_debug("maxUnitFrames = ", maxUnitFrames)
        sdb:log_debug("unitFrameColumnCount = ", unitFrameColumnCount)

        sdb:log_debug("groupGuidList:")
        sdb:log_debug_table(groupGuidList)

        sdb:log_debug("db:")
        sdb:log_debug_table(db)
    else
        sdb:log_error("command does not exist:", cmd)
        sdb:log_info("try '/tankaddon help' for help with slash commands")
    end
end

SlashCmdList["TANKADDON"] = function(msg)
    addon:HandleSlashCommand(msg)
end

-- registered events:
addon:RegisterEvent("ADDON_LOADED")
addon:RegisterEvent("PLAYER_LOGOUT")
addon:RegisterEvent("PLAYER_ENTERING_WORLD")
addon:RegisterEvent("ACTIVE_TALENT_GROUP_CHANGED")
addon:RegisterEvent("GROUP_ROSTER_UPDATE")
addon:RegisterEvent("UNIT_THREAT_LIST_UPDATE")
addon:RegisterEvent("UNIT_THREAT_SITUATION_UPDATE")
addon:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
addon:RegisterEvent("PLAYER_LEAVE_COMBAT")
addon:RegisterEvent("PLAYER_REGEN_ENABLED")
addon:RegisterEvent("PLAYER_REGEN_DISABLED")

addon:SetScript("OnEvent", function(self, event, ...)
    if self[event] then
        self[event](self, ...)
    end
end)

-- addon functions:
function addon:SetupOptions()
    sdb:log_debug("SetupOptions")

    -- TODO: setup InterfaceOptionsPanel by parsing data.Options
end

function addon:CreateFrames()
    sdb:log_debug("CreateFrames")

    maxWidth = ((db.width + (db.unit_padding)) * unitFrameColumnCount) - db.unit_padding
    maxHeight = ((db.height + (db.unit_padding)) * unitFrameColumnCount) - db.unit_padding
    sdb:log_debug("maxWidth: ", maxWidth, ", maxHeight: ", maxHeight)

    self.GroupFrame =
        CreateFrame("Frame", "TankAddonGroupFrame", UIParent, BackdropTemplateMixin and "BackdropTemplate")

    self.GroupFrame:SetFrameStrata("MEDIUM")
    self.GroupFrame:SetMovable(true)
    self.GroupFrame:EnableMouse(true)
    self.GroupFrame:SetBackdrop({
        bgFile = "Interface/Tooltips/UI-Tooltip-Background"
    })
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
            sdb:log_error("UpdateThreatForUnit nil child for unit:", unit, ", threatPct:", threatPct)
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
        -- local button = CreateFrame("Button", format("UnitFrame%d", i), self.GroupFrame, "SecureActionButtonTemplate")
        local button = CreateFrame("Button", format("UnitFrame%d", i), self.GroupFrame, BackdropTemplateMixin and "BackdropTemplate, SecureActionButtonTemplate")

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
        button.text:SetFont(data.Font, db.font_size)
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

function addon:OnOptionsUpdated()
    sdb:log_debug("OnOptionsUpdated")

    maxWidth = ((db.width + (db.unit_padding)) * unitFrameColumnCount) - db.unit_padding
    maxHeight = ((db.height + (db.unit_padding)) * unitFrameColumnCount) - db.unit_padding

    local unitCount = sdb:count_table_pairs(groupGuidList)
    local groupFrameWidth = (db.width + (db.unit_padding)) * unitCount
    local groupFrameHeight = db.height

    if groupFrameWidth > maxWidth then
        groupFrameWidth = maxWidth
        local rows = math.floor(unitCount / unitFrameColumnCount)
        if rows * unitFrameColumnCount < unitCount then
            rows = rows + 1
        end
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
        child.text:SetFont(data.Font, db.font_size)

        local unitName = child:GetName()

        if (unitName == "player" and db.include_player) or unitName ~= "player" then
            child.text:SetFont(data.Font, db.font_size)
            child:SetPoint("BOTTOMLEFT", self.GroupFrame, offsetX, offsetY)

            offsetX = offsetX + (db.width + db.unit_padding)

            if offsetX > maxWidth then
                offsetX = db.frame_padding
                offsetY = offsetY + (db.height + db.unit_padding)
            end
        end
    end
end

function addon:UpdatePlayerSpec()
    sdb:log_debug("UpdatePlayerSpec")

    specIndex = GetSpecialization()
    spec = specIndex and select(2, GetSpecializationInfo(specIndex)) or "None"

    if data.ClassData[class] and data.ClassData[class]["spec"] == spec then
        tauntSpellId, tauntSpellName = data.ClassData[class]["tauntSpellId"], data.ClassData[class]["tauntSpellName"]
    end
end

function addon:UpdatePlayerGroupState()
    sdb:log_debug("UpdatePlayerGroupState")

    inParty = IsInGroup()
    inRaid = IsInRaid()
    playerRole = UnitGroupRolesAssigned("player")
end

function addon:UpdateGroupGuidList()
    sdb:log_debug("UpdateGroupGuidList")

    wipe(groupGuidList)

    if not inRaid and include_player then
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

            groupGuidList[unit .. i] = {
                guid = UnitGUID("player"),
                name = UnitName("player"),
                target = target
            }
        end
    end
end

function addon:UpdateGroupFrameUnits()
    sdb:log_debug("UpdateGroupFrameUnits")

    if groupGuidList then
        local unitCount = sdb:count_table_pairs(groupGuidList)
        sdb:log_debug("unitCount:", unitCount)

        local groupFrameWidth = (db.width + (db.unit_padding)) * unitCount
        local groupFrameHeight = db.height

        if groupFrameWidth > maxWidth then
            groupFrameWidth = maxWidth
            local rows = math.floor(unitCount / unitFrameColumnCount)
            if rows * unitFrameColumnCount < unitCount then
                rows = rows + 1
            end
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
                sdb:log_debug("UpdateGroupFrameUnits nil unitFrame for unit:", unit)
            end

            unitFrameIndex = unitFrameIndex + 1
        end
    end
end

function addon:GetGroupUnit(unit)
    sdb:log_debug("GetGroupUnit: ", unit)

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

function addon:InGroup(unit)
    sdb:log_debug("InGroup: ", unit)

    if self:GetGroupUnit(unit) then
        return true
    else
        return false
    end
end

function addon:UpdateUnitFramesThreat()
    sdb:log_debug("UpdateUnitFramesThreat")

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

-- event functions:
function addon:ADDON_LOADED(addOnName)
    if addOnName == title then
        sdb:log_debug("ADDON_LOADED")
        sdb:log_info(title .. " v" .. version .. " loaded.")

        db = sdb:GetOptionDefaults(data.Options)

        if TankAddonVars then
            db = TankAddonVars
        end

        sdb:log_debug("saved variables:")
        sdb:log_debug_table(db)

        self:SetupOptions()
        self:CreateFrames()
    end
end

function addon:PLAYER_LOGOUT()
    TankAddonVars = db
end

function addon:PLAYER_ENTERING_WORLD(isInitialLogin, isReloadingUi)
    sdb:log_debug("PLAYER_ENTERING_WORLD")

    classNameLocalized, class, classIndex = UnitClass("player")

    self:UpdatePlayerSpec()
    self:UpdatePlayerGroupState()
    self:UpdateGroupGuidList()
    self:UpdateGroupFrameUnits()

    -- self:UnregisterEvent("PLAYER_ENTERING_WORLD")
end

function addon:ACTIVE_TALENT_GROUP_CHANGED()
    sdb:log_debug("ACTIVE_TALENT_GROUP_CHANGED")
    self:UpdatePlayerSpec()
end

function addon:GROUP_ROSTER_UPDATE()
    sdb:log_debug("GROUP_ROSTER_UPDATE")
    self:UpdatePlayerSpec()
    self:UpdatePlayerGroupState()
    self:UpdateGroupGuidList()
    self:UpdateGroupFrameUnits()
end

function addon:COMBAT_LOG_EVENT_UNFILTERED(...)
    -- sdb:log_debug("COMBAT_LOG_EVENT_UNFILTERED")
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
    --     sdb:log_debug("CLEU:", subevent, sourceName, destName)
    -- end
    -- self:UpdateUnitFramesThreat()
end

function addon:UNIT_THREAT_LIST_UPDATE(_, target)
    sdb:log_debug("UNIT_THREAT_LIST_UPDATE")
    self:UpdateUnitFramesThreat()
end

function addon:UNIT_THREAT_SITUATION_UPDATE(_, target)
    sdb:log_debug("UNIT_THREAT_SITUATION_UPDATE")
    self:UpdateUnitFramesThreat()
end

function addon:PLAYER_LEAVE_COMBAT()
    sdb:log_debug("PLAYER_LEAVE_COMBAT")
    self.GroupFrame:ResetUnitFramesThreat()
end

function addon:PLAYER_REGEN_ENABLED()
    sdb:log_debug("PLAYER_REGEN_ENABLED")
    self.GroupFrame:ResetUnitFramesThreat()

    if not db.always_show or not db.enabled then
        self.GroupFrame:Hide()
    end
end

function addon:PLAYER_REGEN_DISABLED()
    sdb:log_debug("PLAYER_REGEN_DISABLED")
    self.GroupFrame:ResetUnitFramesThreat()

    if db.enabled and not self.GroupFrame:IsVisible() then
        self.GroupFrame:Show()
    end
end
