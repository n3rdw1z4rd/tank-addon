local debug = false

sbd = {}
db = {}

function sbd:get_debug()
    return (debug)
end

function sbd:set_debug(v)
    v = v or true
    debug = v
end

function sbd:log_debug(...)
    if debug then
        print("|cff888888", ...)
    end
end

function sbd:log_info(...)
    print("|cff00ffff", ...)
end

function sbd:log_error(...)
    print("|cffff8888", ...)
end

function sbd:log_debug_table(tbl)
    table.foreach(tbl, function(k, v)
        sbd:log_debug(k .. ": ", v)
    end)
end

function sbd:count_table_pairs(tbl)
    local count = 0

    for _ in pairs(tbl) do
        count = count + 1
    end

    return count
end

function sbd:contains(tbl, key)
    for k in pairs(tbl) do
        if k == key then
            return true
        end
    end

    return false
end

function sbd:GetOptionDefaults(options)
    local defaults = {}

    for k, v in pairs(options) do
        defaults[k] = v.default    
    end

    return defaults
end

function sbd:GenerateOptionsInterface(addon, options, db, onUpdated)
    local addonTitle = addon:GetName()
    local optionsPanelTitle = addonTitle .. "Options"

    self:log_debug("GenerateOptionsInterface: ", optionsPanelTitle)

    local optionsPanel = CreateFrame("Frame", optionsPanelTitle)
    optionsPanel.name = addonTitle

    local title = optionsPanel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
	title:SetPoint("TOPLEFT", 10, -10)
	title:SetText(addonTitle .. " v" .. addon.version)

    InterfaceOptions_AddCategory(optionsPanel)

    function NewCheckbox(name, label, hpos, vpos, value)
        local checkbox = CreateFrame("CheckButton", name, optionsPanel, "ChatConfigCheckButtonTemplate");
        checkbox:SetPoint("TOPLEFT", hpos, vpos)
        checkbox:SetChecked(value)
        checkbox.tooltip = label;
        getglobal(checkbox:GetName().."Text"):SetText(label);
        return checkbox
    end

    function NewSlider(name, label, hpos, vpos, value, min, max, step)
        local slider = CreateFrame("Slider", name, optionsPanel, "OptionsSliderTemplate");
        slider:SetPoint("TOPLEFT", hpos, vpos);
        slider.tooltip = label;
        getglobal(slider:GetName().."Text"):SetText(label);
        getglobal(slider:GetName().."Low"):SetText(tostring(min));
        getglobal(slider:GetName().."High"):SetText(tostring(max));
        slider:SetMinMaxValues(min, max);
        slider:SetValueStep(step);
        slider:SetValue(value);
        return slider
    end

    function NewSelect(name, label, hpos, vpos, value, values, on_clicked)
        local select = CreateFrame("Frame", name, optionsPanel, "UIDropDownMenuTemplate")
        select:SetPoint("TOPLEFT", hpos - 15, vpos)
        UIDropDownMenu_SetWidth(select, 140)
        select.list = values
        select.tooltip = label;

        function initialize(self)
            local info = UIDropDownMenu_CreateInfo()

            for i, item in pairs(values) do
                info.text = item
                info.arg1 = item
                info.func = function(self, arg1, arg2, checked)
                    value = arg1
                    on_clicked(arg1)
                    UIDropDownMenu_SetSelectedValue(select, self.value, true)
                    UIDropDownMenu_SetText(select, label..": "..value)
                end

                UIDropDownMenu_AddButton(info)
            end

            UIDropDownMenu_SetSelectedValue(select, value)
            UIDropDownMenu_SetText(select, label..": "..value)
        end

        UIDropDownMenu_Initialize(select, initialize)
    end

    local controls = {}
    local lvpos, rvpos = -35, -50

    for k, v in pairs(options) do
        self:log_debug(v.label, ": ", v.default)

        if v.type == "boolean" then
            local checkbox = NewCheckbox(k.."_checkbox", v.label, 10, lvpos, db[k])
            
            checkbox:SetScript("OnClick", function(self, button, down)
                local state = self:GetChecked()
                db[k] = state
                onUpdated()
            end)

            function checkbox:UpdateValue(value)
                self:SetChecked(value)
            end
            
            controls[k] = checkbox

            lvpos = lvpos - 30
        elseif v.type == "number" then
            local slider = NewSlider(k.."_slider", v.label, 200, rvpos, db[k], v.min, v.max, v.step)

            slider:SetScript("OnValueChanged", function(self, value, userInput)
                local val = math.floor(value)
                db[k] = val - (val % v.step)
                onUpdated()
            end);

            function slider:UpdateValue(value)
                self:SetValue(value)
            end

            controls[k] = slider

            rvpos = rvpos - 45
        elseif v.type == "select" then
            NewSelect(k.."_select", v.label, 10, lvpos, db[k], v.values, function(value)
                db[k] = value
                onUpdated()
            end)

            lvpos = lvpos - 30
        end
    end

    optionsPanel.okay = function()
        onUpdated()
    end
    
    optionsPanel.default = function()
        addon:ResetToDefaults()
        onUpdated()
    end
    
    optionsPanel.refresh = function()
        for k, v in pairs(controls) do
            v:UpdateValue(db[k])
        end
    end

    return optionsPanel
end