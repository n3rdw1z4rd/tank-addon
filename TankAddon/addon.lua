local title = ...
local version = GetAddOnMetadata(title, "Version")

sdb:set_debug()

-- local functions:
local function GetTableCount(tbl)
    local count = 0

    for _ in pairs(tbl) do
        count = count + 1
    end

    return count
end

-- addon:
local addon = CreateFrame("Frame", title)

-- registered events:
addon:RegisterEvent("ADDON_LOADED")
-- addon:RegisterEvent("PLAYER_ENTERING_WORLD")
-- addon:RegisterEvent("ACTIVE_TALENT_GROUP_CHANGED")
-- addon:RegisterEvent("GROUP_ROSTER_UPDATE")
-- addon:RegisterEvent("UNIT_THREAT_LIST_UPDATE")
-- addon:RegisterEvent("UNIT_THREAT_SITUATION_UPDATE")
-- addon:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
-- addon:RegisterEvent("PLAYER_LEAVE_COMBAT")
-- addon:RegisterEvent("PLAYER_REGEN_ENABLED")
-- addon:RegisterEvent("PLAYER_REGEN_DISABLED")

addon:SetScript("OnEvent", function(self, event, ...)
    if self[event] then
        self[event](self, ...)
    end
end)

-- addon functions:
-- function self:SetupDB()
-- end

-- function self:SetupOptions()
-- end

-- function self:CreateFrames()
--     sdb:log_debug("CreateFrames")

--     maxWidth = ((db.width + (db.unit_padding)) * unitFrameColumnCount) - db.unit_padding
--     maxHeight = ((db.height + (db.unit_padding)) * unitFrameColumnCount) - db.unit_padding

--     -- used fix provided by the_notorious_thug
--     self.GroupFrame = CreateFrame("Frame", "TankAddonGroupFrame", UIParent, BackdropTemplateMixin and "BackdropTemplate")

--     self.GroupFrame:SetFrameStrata("MEDIUM")
--     self.GroupFrame:SetMovable(true)
--     self.GroupFrame:EnableMouse(true)
--     self.GroupFrame:SetBackdrop({ bgFile = "Interface/Tooltips/UI-Tooltip-Background" })
--     self.GroupFrame:SetBackdropColor(0, 0, 0, 0.8)
--     self.GroupFrame:ClearAllPoints()
--     self.GroupFrame:SetPoint("CENTER", UIParent, "BOTTOMLEFT", 1920 / 2, 1080 / 2)
    
--     if not db.always_show then
--         self.GroupFrame:Hide()
--     end

--     self.GroupFrame:RegisterForDrag("LeftButton")

--     self.GroupFrame:SetScript("OnDragStart", function(self)
--         if not db.locked then
--             self:StartMoving()
--         end
--     end)

--     self.GroupFrame:SetScript("OnDragStop", function(self)
--         if not db.locked then
--             self:StopMovingOrSizing()
--         end
--     end)

--     function self.GroupFrame:GetUnitFrame(name)
--         for _, child in ipairs({self:GetChildren()}) do
--             if child:GetName() == name then
--                 return child
--             end
--         end

--         return nil
--     end
    
--     function self.GroupFrame:GetUnitFrameForUnit(unit)
--         for _, child in ipairs({self:GetChildren()}) do
--             if child.unit == unit then
--                 return child
--             end
--         end

--         return nil
--     end

--     function self.GroupFrame:UpdateThreatForUnit(unit, threatPct)
--         local child = self:GetUnitFrameForUnit(unit)
--         if child then
--             child:SetThreatPercent(threatPct)
--         else
--             sdb:log_error("UpdateThreatForUnit nil child for unit:", unit, ", threatPct:", threatPct)
--         end
--     end

--     function self.GroupFrame:ResetUnitFramesThreat()
--         for _, child in ipairs({self:GetChildren()}) do
--             child:SetThreatPercent(0)
--         end
--     end

--     function self.GroupFrame:ResetUnitFrames()
--         for _, child in ipairs({self:GetChildren()}) do
--             child.unit = nil
--             child.text:SetText(nil)
--             child:Hide()
--         end
--     end

--     local currentUnitOffsetX = db.frame_padding
--     local currentUnitOffsetY = db.frame_padding

--     for i = 1, maxUnitFrames do
--         -- used fix provided by the_notorious_thug
--         local button = CreateFrame("Button", format("UnitFrame%d", i), self.GroupFrame, BackdropTemplateMixin and "BackdropTemplate")
--         button:SetWidth(db.width)
--         button:SetHeight(db.height)
--         button:SetBackdrop({ bgFile = "Interface/Tooltips/UI-Tooltip-Background" })
--         button:SetPoint("BOTTOMLEFT", parent, currentUnitOffsetX, currentUnitOffsetY)
--         button.unit = nil

--         button.texture = button:CreateTexture(nil, "PARENT")
--         button.texture:SetColorTexture(1, 1, 1, 1)
--         button.texture:SetAllPoints(button)
--         button.texture:SetGradientAlpha("VERTICAL", 1, 0, 0, 0, 0, 0, 0, 0)

--         button.text = button:CreateFontString(nil, "ARTWORK")
--         button.text:SetFont(db.font, db.font_size)
--         button.text:SetPoint("CENTER", button, "CENTER")

--         button.badge = button:CreateTexture(nil, "PARENT")
--         button.badge:SetSize(20, 20)
--         button.badge:SetTexture(2202478)
--         button.badge:SetPoint("TOPLEFT", -5, 5)

--         button:Hide()

--         function button:SetThreatPercent(alpha)
--             button.texture:SetGradientAlpha("VERTICAL", 1, 0, 0, alpha, alpha, 0, 0, 0)
--         end

--         function button:SetRole(role)
--             if role == "TANK" then
--                 button.badge:SetTexCoord(.523, .757, 0, 1)
--             elseif role == "HEALER" then
--                 button.badge:SetTexCoord(.265, .492, 0, 1)
--             elseif role == "DAMAGER" then
--                 button.badge:SetTexCoord(.007, .242, 0, 1)
--             else
--                 button.badge:SetTexCoord(.76, 1, 0, 1)
--             end
--         end

--         currentUnitOffsetX = currentUnitOffsetX + (db.width + db.unit_padding)

--         if currentUnitOffsetX > maxWidth then
--             currentUnitOffsetX = db.frame_padding
--             currentUnitOffsetY = currentUnitOffsetY + (db.height + db.unit_padding)
--         end
--     end

--     self:OnOptionsUpdated()
-- end

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

        -- self:SetupOptions()
        -- self:CreateFrames()
    end
end

function addon:PLAYER_LOGOUT()
    TankAddonVars = db
end

-- function addon:PLAYER_ENTERING_WORLD(isInitialLogin, isReloadingUi)
--     sdb:log_debug("PLAYER_ENTERING_WORLD")

--     local classNameLocalized, class, classIndex = UnitClass("player")
--     self.player_class = class

--     self:UpdatePlayerInfo()

--     self:UnregisterEvent("PLAYER_ENTERING_WORLD")
-- end

-- function addon:UpdatePlayerInfo()
--     sdb:log_debug("UpdatePlayerInfo")

--     local specIndex = GetSpecialization()
--     local spec = specIndex and select(2, GetSpecializationInfo(specIndex)) or "None"
--     self.player_spec = spec

--     -- sdb:log_debug("spec: " .. spec)
-- end

    sdb:log_debug("spec: " .. spec)
end