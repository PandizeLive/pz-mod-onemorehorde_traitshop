if isServer() then return end

require("OptionScreens/SandboxOptions")
require("ISUI/AdminPanel/ISServerSandboxOptionsUI")
require("OptionScreens/ServerSettingsScreen")
local Config = require("OMHTS_RewardsConfig")
local SandboxUI = {}

---@param panel ISPanel
---@return nil
function SandboxUI.layout(panel)
    local mode = panel.controls["OMHTraitShop.RewardMode"]
    if not mode or panel.omhRewardMode == mode.selected then return end
    panel.omhRewardMode = mode.selected
    local y = 11
    panel.joypadButtonsY = {}
    for index = 1, #panel.settingNames do
        local name = panel.settingNames[index]
        local label = panel.labels[name]
        local control = panel.controls[name]
        local key = string.match(name, "^OMHTraitShop%.(.+)$")
        local visible = true
        if key and Config.defaults[key] ~= nil then
            visible = Config.visible(mode.selected, key)
        end
        label:setVisible(visible)
        control:setVisible(visible)
        if visible then
            label:setY(y)
            control:setY(y)
            y = y + math.max(label:getHeight(), control:getHeight()) + 10
            panel:insertNewLineOfButtons(control)
        end
    end
    panel.joypadIndex = 1
    panel.joypadIndexY = 1
    panel:setYScroll(0)
    panel:setScrollHeight(y)
end

---@param panel ISPanel
---@return ISPanel
function SandboxUI.attach(panel)
    if not panel or not panel.controls or not panel.controls["OMHTraitShop.RewardMode"]
        or panel.omhRewardLayout then return panel end
    panel.omhRewardLayout = true
    local original = panel.prerender
    ---@param self ISPanel
    ---@return nil
    panel.prerender = function(self)
        SandboxUI.layout(self)
        original(self)
    end
    return panel
end

local originalPanel = SandboxOptionsScreen.createPanel
---@param self SandboxOptionsScreen
---@param page table
---@return ISPanel
function SandboxOptionsScreen:createPanel(page)
    return SandboxUI.attach(originalPanel(self, page))
end

local originalAdminPanel = ISServerSandboxOptionsUI.createPanel
---@param self ISServerSandboxOptionsUI
---@param page table
---@return ISPanel
function ISServerSandboxOptionsUI:createPanel(page)
    return SandboxUI.attach(originalAdminPanel(self, page))
end

local originalChildren = ServerSettingsScreen.create
---@param self ServerSettingsScreen
---@return nil
function ServerSettingsScreen:create()
    originalChildren(self)
    local original = self.pageEdit.createPanel
    ---@param page table
    ---@param category table
    ---@param settings table
    ---@return ISPanel
    self.pageEdit.createPanel = function(page, category, settings)
        return SandboxUI.attach(original(page, category, settings))
    end
end

local originalPreset = SandboxOptionsScreen.addPresetToList
---@param self SandboxOptionsScreen
---@param fileName string
---@param text string
---@param userDefined boolean
---@return nil
function SandboxOptionsScreen:addPresetToList(fileName, text, userDefined)
    originalPreset(self, fileName, text, userDefined)
    if not userDefined then
        Config.applyDefault(self.presets[#self.presets].options)
    end
end

return SandboxUI
