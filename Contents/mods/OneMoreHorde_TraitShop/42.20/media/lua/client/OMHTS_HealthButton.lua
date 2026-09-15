if isServer() then return end

require("ISUI/ISPanel")
require("ISUI/ISEquippedItem")
require("ISUI/ISButton")
require("OMHTS_ShopWindow")
local TraitShop = require("OMHTS_Bootstrap")
local originalPrerender = ISEquippedItem.prerender
local originalRemove = ISEquippedItem.removeFromUIManager

---@nodiscard
---@param element ISUIElement
---@param x number
---@param y number
---@return boolean
local function contains(element, x, y)
    return x >= element:getAbsoluteX() and x < element:getAbsoluteX() + element:getWidth()
        and y >= element:getAbsoluteY() and y < element:getAbsoluteY() + element:getHeight()
end

---@param sidebar ISEquippedItem
---@return nil
local function openShop(sidebar)
    TraitShop.toggleWindow(sidebar.chr)
end

---@param button ISButton
---@return nil
local function hideButton(button)
    button:setVisible(false)
    if button.tooltipUI then
        button.tooltipUI:setVisible(false)
        button.tooltipUI:removeFromUIManager()
    end
end

---@return nil
function ISEquippedItem:prerender()
    originalPrerender(self)
    if not self.healthBtn or not self:getIsVisible() or not self.healthBtn:getIsVisible() then
        if self.omhTraitShopButton then
            hideButton(self.omhTraitShopButton)
        end
        return
    end
    if not self.omhTraitShopButton then
        local button = ISButton:new(0, 0, self.healthBtn:getWidth(), self.healthBtn:getHeight(), "", self, openShop)
        button:initialise()
        button:instantiate()
        button:setImage(tryGetTexture("OMHTS_ShopIcon"))
        local iconSize = math.floor(self.healthBtn:getHeight() * 0.8)
        button:forceImageSize(iconSize, iconSize)
        button:setTooltip(getText("UI_OMHTS_Title"))
        button.backgroundColor = { r = 0.02, g = 0.03, b = 0.02, a = 0.9 }
        button:setAlwaysOnTop(true)
        button:setVisible(false)
        button:addToUIManager()
        self.omhTraitShopButton = button
    end
    local button = self.omhTraitShopButton
    local x = self.healthBtn:getAbsoluteX() + self.healthBtn:getWidth()
    if self.traitsPopup then
        x = math.max(x, self.traitsPopup:getAbsoluteX() + self.traitsPopup:getWidth())
    end
    button:setX(x)
    button:setY(self.healthBtn:getAbsoluteY())
    local mouseX = getMouseX()
    local mouseY = getMouseY()
    local hover = self.healthBtn:isMouseOver()
    if self.traitsPopup and self.traitsPopup:getIsVisible() and self.traitsPopup:isMouseOver()
        and contains(self.healthBtn, mouseX, mouseY) then
        hover = true
    end
    if button:getIsVisible() and button:isMouseOver() then
        hover = true
    end
    if button:getIsVisible() and self.traitsPopup and self.traitsPopup:getIsVisible()
        and contains(self.traitsPopup, mouseX, mouseY) then
        hover = true
    end
    if hover and not self.chr:isDead() then
        button:setVisible(true)
    else
        hideButton(button)
    end
end

---@return nil
function ISEquippedItem:removeFromUIManager()
    if self.omhTraitShopButton then
        hideButton(self.omhTraitShopButton)
        self.omhTraitShopButton:removeFromUIManager()
        self.omhTraitShopButton = nil
    end
    originalRemove(self)
end
