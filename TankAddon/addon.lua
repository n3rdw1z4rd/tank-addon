local title = ...
local version = GetAddOnMetadata(title, "Version")

-- sbd:set_debug()

-- local debug variable:
local DEBUG = sbd:get_debug()
local debugUnitCount = 10

-- local variables:
local screenWidth, screenHeight
local playerRole
local threatPercentDivisor = 100
local classNameLocalized, class, classIndex
local specIndex, spec
local tauntSpellId, tauntSpellName
local inParty, inRaid
local maxUnitFrames = 40
local groupGuidList = {}

-- addon:
local addon = CreateFrame("Frame", title, UIParent) -- instead of UIParent, try using the health bar under character
addon.version = version

-- slash commands:
SLASH_TANKADDON1, SLASH_TANKADDON2 = "/tankaddon", "/ta"

function addon:HandleSlashCommand(msg)
    local _, _, cmd, argsString = string.find(msg, "%s?(%w+)%s?(.*)")
    
    cmd = cmd or "help"
    argsString = argsString or ""

    local slashCmd = "HandleSlashCommand_" .. cmd
    local args = {strsplit(" ", argsString)}

    sbd:log_debug("HandleSlashCommand: ", cmd, argsString)

    if cmd == "help" then
        sbd:log_info("TankAddon v" .. version .. " slash command help")
        sbd:log_info("syntax: /tankaddon (or /ta) command arg1 arg2")
        sbd:log_info("command: 'help': this message")
        sbd:log_info(
            "command: 'get', arg1: OPTION_NAME or 'all': show the value of the OPTION_NAME or values of all options")
        sbd:log_info("command: 'set', arg1: OPTION_NAME, arg2: VALUE: set the OPTION_NAME to the VALUE")
        sbd:log_info("command: 'reset': sets all options to the default values")
    elseif cmd == "get" then
        if sbd:contains(db, args[1]) then
            sbd:log_info(args[1] .. " = ", db[args[1]])
        elseif args[1] == "all" then
            table.foreach(db, function(k, v)
                sbd:log_info(k .. " = ", v)
            end)
        else
            sbd:log_error("unknown property: ", args[1])
        end
    elseif cmd == "set" then
        if sbd:contains(data.Options, args[1]) then
            local val

            if data.Options[args[1]].type == "boolean" then
                val = args[2] == "true" or false
            elseif data.Options[args[1]].type == "number" then
                val = tonumber(args[2])

                if sbd:contains(data.Options[args[1]], "step") then
                    val = val - (val % data.Options[args[1]].step)
                end

                if sbd:contains(data.Options[args[1]], "min") then
                    if val < data.Options[args[1]].min then
                        val = data.Options[args[1]].min
                    end
                end

                if sbd:contains(data.Options[args[1]], "max") then
                    if val > data.Options[args[1]].max then
                        val = data.Options[args[1]].max
                    end
                end
            else
                val = args[2]
            end

            db[args[1]] = val

            sbd:log_info(args[1] .. " = ", db[args[1]])

            self:OnOptionsUpdated()
        else
            sbd:log_error("unknown setting: " .. args[1])
        end
    elseif cmd == "reset" then
        self:ResetToDefaults()

        table.foreach(db, function(k, v)
            sbd:log_info(k .. " = ", v)
        end)

        self:OnOptionsUpdated()
    elseif cmd == "locals" then
        sbd:log_debug("class = ", class)
        sbd:log_debug("classIndex = ", classIndex)
        sbd:log_debug("classNameLocalized = ", classNameLocalized)
        sbd:log_debug("inParty = ", inParty)
        sbd:log_debug("inRaid = ", inRaid)
        sbd:log_debug("maxUnitFrames = ", maxUnitFrames)
        sbd:log_debug("playerRole = ", playerRole)
        sbd:log_debug("spec = ", spec)
        sbd:log_debug("specIndex = ", specIndex)
        sbd:log_debug("tauntSpellId = ", tauntSpellId)
        sbd:log_debug("tauntSpellName = ", tauntSpellName)
        sbd:log_debug("threatPercentDivisor = ", threatPercentDivisor)

        sbd:log_debug("groupGuidList:")
        sbd:log_debug_table(groupGuidList)

        sbd:log_debug("db:")
        sbd:log_debug_table(db)
    else
        sbd:log_error("command does not exist:", cmd)
        sbd:log_info("try '/tankaddon help' for help with slash commands")
    end
end

function addon:ResetToDefaults()
    for k, v in pairs(sbd:GetOptionDefaults(data.Options)) do
        db[k] = v
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
addon:RegisterEvent("PLAYER_LEAVE_COMBAT")
addon:RegisterEvent("PLAYER_REGEN_ENABLED")
addon:RegisterEvent("PLAYER_REGEN_DISABLED")

addon:SetScript("OnEvent", function(self, event, ...)
    if self[event] then
        self[event](self, ...)
    end
end)

-- addon functions:
function addon:CreateFrames()
    sbd:log_debug("CreateFrames")
    
    local maxWidth = (db.unit_width * db.unit_columns) + (db.unit_padding * (db.unit_columns - 1))
    
    if self.GroupFrame then
        self.GroupFrame.destroy()
        self.GroupFrame = nil
    end

    self.GroupFrame = CreateFrame("Frame", "TankAddonGroupFrame", UIParent, BackdropTemplateMixin and "BackdropTemplate")
    self.GroupFrame:SetFrameStrata("MEDIUM")
    self.GroupFrame:SetMovable(true)
    self.GroupFrame:EnableMouse(true)
    self.GroupFrame:SetBackdrop({ bgFile = "Interface/Tooltips/UI-Tooltip-Background" })
    self.GroupFrame:SetBackdropColor(0, 0, 0, 0.8)
    self.GroupFrame:ClearAllPoints()
    self.GroupFrame:SetPoint("CENTER", UIParent, "BOTTOMLEFT", screenWidth / 2, screenHeight / 2)

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
            sbd:log_debug("UpdateThreatForUnit nil child for unit:", unit, ", threatPct:", threatPct)
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

            if not DEBUG then
                child.text:SetText(nil)
            end

            child:Hide()
        end
    end

    local currentUnitOffsetX = db.frame_padding
    local currentUnitOffsetY = db.frame_padding

    for i = 1, maxUnitFrames do
        local button = CreateFrame("Button", format("UnitFrame%d", i), self.GroupFrame, BackdropTemplateMixin and "BackdropTemplate, SecureActionButtonTemplate")

        button:SetWidth(db.unit_width)
        button:SetHeight(db.unit_height)
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

        if DEBUG then
            button.text:SetText(tostring(i))
        end

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

        currentUnitOffsetX = currentUnitOffsetX + (db.unit_width + db.unit_padding)
        
        if currentUnitOffsetX > maxWidth then
            currentUnitOffsetX = db.frame_padding
            currentUnitOffsetY = currentUnitOffsetY + (db.unit_height + db.unit_padding)
        end
    end

    self:OnOptionsUpdated()
end

function addon:OnOptionsUpdated()
    sbd:log_debug("OnOptionsUpdated")
    
    local maxWidth = (db.unit_width * db.unit_columns) + (db.unit_padding * (db.unit_columns - 1))
    
    local unitCount = sbd:count_table_pairs(groupGuidList)
    local columns = unitCount <= db.unit_columns and unitCount or db.unit_columns
    local rows = columns <= db.unit_columns and 1 or math.ceil(unitCount / db.unit_columns)
    local groupFrameWidth = (db.unit_width * columns) + (db.unit_padding * (columns - 1))
    local groupFrameHeight = (db.unit_height * rows) + (db.unit_padding * (rows - 1))

    groupFrameWidth = groupFrameWidth + (db.frame_padding * 2)
    groupFrameHeight = groupFrameHeight + (db.frame_padding * 2)

    self.GroupFrame:SetWidth(groupFrameWidth)
    self.GroupFrame:SetHeight(groupFrameHeight)

    if not db.always_show or not db.enabled then
        self.GroupFrame:Hide()
    elseif db.always_show and db.enabled then
        self.GroupFrame:Show()
    end

    local offsetX = db.frame_padding
    local offsetY = db.frame_padding

    for _, child in ipairs({self.GroupFrame:GetChildren()}) do
        child:SetWidth(db.unit_width)
        child:SetHeight(db.unit_height)
        child.text:SetFont(data.Font, db.font_size)

        local unitName = child:GetName()

        child.text:SetFont(data.Font, db.font_size)
        child:SetPoint("BOTTOMLEFT", self.GroupFrame, offsetX, offsetY)

        offsetX = offsetX + (db.unit_width + db.unit_padding)

        if offsetX > maxWidth then
            offsetX = db.frame_padding
            offsetY = offsetY + (db.unit_height + db.unit_padding)
        end
    end

    self:UpdateGroupFrameUnits()
end

function addon:UpdatePlayerSpec()
    sbd:log_debug("UpdatePlayerSpec")

    specIndex = GetSpecialization()
    spec = specIndex and select(2, GetSpecializationInfo(specIndex)) or "None"

    if data.ClassData[class] and data.ClassData[class]["spec"] == spec then
        tauntSpellId, tauntSpellName = data.ClassData[class]["tauntSpellId"], data.ClassData[class]["tauntSpellName"]
    end
end

function addon:UpdatePlayerGroupState()
    sbd:log_debug("UpdatePlayerGroupState")

    inParty = IsInGroup()
    inRaid = IsInRaid()
    playerRole = UnitGroupRolesAssigned("player")
end

function addon:UpdateGroupGuidList()
    sbd:log_debug("UpdateGroupGuidList")

    wipe(groupGuidList)

    if not inRaid then
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
    elseif DEBUG then
        local count = debugUnitCount > 0 and debugUnitCount or maxUnitFrames

        if groupGuidList["player"] then
            count = count - 1 -- minus one here to account for added player unit frame
        end

        for i = 1, count do
            local unit = "player"
            local target = "target"

            groupGuidList[unit .. i] = {
                guid = UnitGUID("player"),
                name = data.RandomNames[i],
                target = target
            }
        end
    end
end

function addon:UpdateGroupFrameUnits()
    sbd:log_debug("UpdateGroupFrameUnits")

    if groupGuidList then
        local unitCount = sbd:count_table_pairs(groupGuidList)
        local columns = unitCount <= db.unit_columns and unitCount or db.unit_columns
        local rows = math.ceil(unitCount / db.unit_columns)
        local groupFrameWidth = (db.unit_width * columns) + (db.unit_padding * (columns - 1))
        local groupFrameHeight = (db.unit_height * rows) + (db.unit_padding * (rows - 1))

        groupFrameWidth = groupFrameWidth + (db.frame_padding * 2)
        groupFrameHeight = groupFrameHeight + (db.frame_padding * 2)

        self.GroupFrame:SetWidth(groupFrameWidth)
        self.GroupFrame:SetHeight(groupFrameHeight)
        self.GroupFrame:ResetUnitFrames()

        -- set local player to first unit frame:
        local unitFrame = self.GroupFrame:GetUnitFrame("UnitFrame1")
        unitFrame:SetBackdropColor(0, 0, 0, 1)
        unitFrame.unit = "player"
        unitFrame:SetRole(UnitGroupRolesAssigned("player"))
        unitFrame.text:SetText(UnitName("player"))
        unitFrame:Show()

        local unitFrameIndex = 2 -- starting with 2 since local player takes 1

        for unit, data in pairs(groupGuidList) do
            if unit ~= "player" then
                local unitName = data["name"]
                unitFrame = self.GroupFrame:GetUnitFrame(format("UnitFrame%d", unitFrameIndex))
    
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
    
                    if DEBUG then
                        unitFrame.text:SetText(strjoin("_", tostring(unitFrameIndex), UnitName(unit) or unitName))
                    else
                        unitFrame.text:SetText(UnitName(unit))
                    end
    
                    unitFrame:Show()
                else
                    sbd:log_debug("UpdateGroupFrameUnits nil unitFrame for unit:", unit)
                end
    
                unitFrameIndex = unitFrameIndex + 1
            end
        end
    end
end

function addon:GetGroupUnit(unit)
    sbd:log_debug("GetGroupUnit: ", unit)

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
    sbd:log_debug("InGroup: ", unit)

    if self:GetGroupUnit(unit) then
        return true
    else
        return false
    end
end

function addon:UpdateUnitFramesThreat()
    sbd:log_debug("UpdateUnitFramesThreat")

    if not inRaid then
        local playerIsTanking, playerThreatStatus, playerThreatPct, playerRawThreatPct, playerThreatValue =
            UnitDetailedThreatSituation("player", "target")

        if playerThreatPct then
            self.GroupFrame:UpdateThreatForUnit("player", (playerThreatPct / threatPercentDivisor))
        end
    end

    local groupGuidList = groupGuidList

    if groupGuidList then
        for unit, data in pairs(groupGuidList) do
            if UnitExists(unit) then
                local isTanking, threatStatus, threatPct, rawThreatPct, threatValue =
                    UnitDetailedThreatSituation(unit, data["target"])

                if threatPct then
                    self.GroupFrame:UpdateThreatForUnit(unit, (threatPct / threatPercentDivisor))
                end
            end
        end
    end
end

-- event functions:
function addon:ADDON_LOADED(addOnName)
    if addOnName == title then
        sbd:log_debug("ADDON_LOADED")
        sbd:log_info(title .. " v" .. version .. " loaded.")

        db = sbd:GetOptionDefaults(data.Options)

        if TankAddonVars then
            for k, v in pairs(TankAddonVars) do
                db[k] = v
            end
        end

        sbd:log_debug("saved variables:")
        sbd:log_debug_table(db)

        screenWidth = GetScreenWidth() * UIParent:GetEffectiveScale()
        sbd:log_debug("screenWidth: ", screenWidth)

        screenHeight = GetScreenHeight() * UIParent:GetEffectiveScale()
        sbd:log_debug("screenHeight: ", screenHeight)

        sbd:GenerateOptionsInterface(self, data.Options, db, function()
            self:OnOptionsUpdated()
        end)

        self:CreateFrames()
    end
end

function addon:PLAYER_LOGOUT()
    TankAddonVars = db
end

function addon:PLAYER_ENTERING_WORLD(isInitialLogin, isReloadingUi)
    sbd:log_debug("PLAYER_ENTERING_WORLD")

    classNameLocalized, class, classIndex = UnitClass("player")

    self:UpdatePlayerSpec()
    self:UpdatePlayerGroupState()
    self:UpdateGroupGuidList()
    self:UpdateGroupFrameUnits()

    -- self:UnregisterEvent("PLAYER_ENTERING_WORLD")
end

function addon:ACTIVE_TALENT_GROUP_CHANGED()
    sbd:log_debug("ACTIVE_TALENT_GROUP_CHANGED")
    self:UpdatePlayerSpec()
end

function addon:GROUP_ROSTER_UPDATE()
    sbd:log_debug("GROUP_ROSTER_UPDATE")
    self:UpdatePlayerSpec()
    self:UpdatePlayerGroupState()
    self:UpdateGroupGuidList()
    self:UpdateGroupFrameUnits()
end

function addon:UNIT_THREAT_LIST_UPDATE(_, target)
    sbd:log_debug("UNIT_THREAT_LIST_UPDATE")
    self:UpdateUnitFramesThreat()
end

function addon:UNIT_THREAT_SITUATION_UPDATE(_, target)
    sbd:log_debug("UNIT_THREAT_SITUATION_UPDATE")
    self:UpdateUnitFramesThreat()
end

function addon:PLAYER_LEAVE_COMBAT()
    sbd:log_debug("PLAYER_LEAVE_COMBAT")
    self.GroupFrame:ResetUnitFramesThreat()
end

function addon:PLAYER_REGEN_ENABLED()
    sbd:log_debug("PLAYER_REGEN_ENABLED")
    self.GroupFrame:ResetUnitFramesThreat()

    if not db.always_show or not db.enabled then
        self.GroupFrame:Hide()
    end
end

function addon:PLAYER_REGEN_DISABLED()
    sbd:log_debug("PLAYER_REGEN_DISABLED")
    self.GroupFrame:ResetUnitFramesThreat()

    if db.enabled and not self.GroupFrame:IsVisible() then
        self.GroupFrame:Show()
    end
end
