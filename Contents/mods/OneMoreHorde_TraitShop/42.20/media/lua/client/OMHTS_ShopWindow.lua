if isServer() then return end

require("ISUI/ISCollapsableWindow")
require("ISUI/ISScrollingListBox")
require("ISUI/ISRichTextPanel")
require("ISUI/ISButton")
require("OMHTS_ClientState")
local TraitShop = require("OMHTS_Bootstrap")
local Catalog = require("OMHTS_Catalog")

---@class OMHTS_ShopWindow: ISCollapsableWindow
OMHTS_ShopWindow = ISCollapsableWindow:derive("OMHTS_ShopWindow")
local windows = {}

---@param self ISScrollingListBox
---@param y number
---@param item table
---@param alt boolean
---@return number
local function drawOffer(self, y, item, alt)
    local offer = item.item
    local height = self.itemheight
    if y + height < 0 or y > self.height then return y + height end
    if self.selected == item.index then
        self:drawRect(0, y, self.width, height, 0.35, 0.2, 0.5, 0.3)
    elseif alt then
        self:drawRect(0, y, self.width, height, 0.12, 1, 1, 1)
    end
    local definition = Catalog.definition(offer.id)
    if definition then
        local texture = definition:getTexture()
        if texture then
            self:drawTextureScaled(texture, 8, y + 8, 24, 24, 1, 1, 1, 1)
        end
    end
    local fontHeight = getTextManager():getFontHeight(UIFont.Small)
    self:drawText(item.text, 40, y + 5, 0.95, 0.95, 0.95, 1, UIFont.Small)
    self:drawText(getText("UI_OMHTS_Status_" .. offer.status), 40, y + fontHeight + 7,
        0.65, 0.8, 0.65, 1, UIFont.Small)
    self:drawTextRight(tostring(offer.price), self.width - 18, y + fontHeight + 7,
        1, 0.85, 0.4, 1, UIFont.Small)
    return y + height
end

---@return nil
function OMHTS_ShopWindow:createChildren()
    ISCollapsableWindow.createChildren(self)
    local fontHeight = getTextManager():getFontHeight(UIFont.Small)
    self.contentTop = self:titleBarHeight() + 7 + fontHeight * 6
    self.listWidth = math.floor((self.width - 36) * 0.48)
    local contentHeight = self.height - self.contentTop - fontHeight * 3 - 30
    self.list = ISScrollingListBox:new(12, self.contentTop, self.listWidth, contentHeight)
    self.list:initialise()
    self.list:instantiate()
    self.list.itemheight = math.max(42, fontHeight * 2 + 12)
    self.list.doDrawItem = drawOffer
    self.list.drawBorder = true
    self.list.useStencilForChildren = true
    self:addChild(self.list)
    self.description = ISRichTextPanel:new(self.listWidth + 24, self.contentTop,
        self.width - self.listWidth - 36, contentHeight - fontHeight * 2 - 24)
    self.description:initialise()
    self.description:instantiate()
    self.description.autosetheight = false
    self.description.clip = true
    self.description:addScrollBars()
    self:addChild(self.description)
    self.buy = ISButton:new(self.listWidth + 24, self.contentTop + contentHeight - fontHeight * 2 - 12,
        self.width - self.listWidth - 36, fontHeight * 2 + 12, getText("UI_OMHTS_Buy"), self, self.onBuy)
    self.buy:initialise()
    self.buy:setEnable(false)
    self:addChild(self.buy)
end

---@return nil
function OMHTS_ShopWindow:onBuy()
    local item = self.list.items[self.list.selected]
    if not item then return end
    TraitShop.purchase(self.player, item.item.id)
    self.nextRefresh = 0
end

---@return nil
function OMHTS_ShopWindow:refresh()
    local state = TraitShop.getState(self.playerNum)
    self.state = state
    if not state then
        self.buy:setEnable(false)
        return
    end
    local selected = self.list.selected
    local scroll = self.list:getYScroll()
    self.list:clear()
    for index = 1, #state.offers do
        local offer = state.offers[index]
        local definition = Catalog.definition(offer.id)
        if definition then
            self.list:addItem(definition:getLabel(), offer)
        end
    end
    self.list.selected = math.max(1, math.min(selected, #self.list.items))
    self.list:setYScroll(scroll)
    local item = self.list.items[self.list.selected]
    local pending = TraitShop.purchasePending(self.playerNum)
    self.buy:setEnable(item ~= nil and item.item.status == "available" and not pending)
    if pending then
        self.buy:setTitle(getText("UI_OMHTS_Purchasing"))
    elseif item then
        self.buy:setTitle(getText("UI_OMHTS_BuyFor", tostring(item.item.price)))
    end
    if item then
        local offer = item.item
        local descriptionKey = offer.id .. ":" .. offer.status .. ":" .. offer.price
        if descriptionKey ~= self.descriptionKey then
            local definition = Catalog.definition(offer.id)
            self.description.text = "<H2> " .. definition:getLabel() .. " <LINE> <TEXT> "
                .. definition:getDescription() .. " <LINE> <LINE> "
                .. getText("UI_OMHTS_Status_" .. offer.status)
            self.description:paginate()
            self.description:setYScroll(0)
            self.descriptionKey = descriptionKey
        end
    end
end

---@return nil
function OMHTS_ShopWindow:prerender()
    ISCollapsableWindow.prerender(self)
    if self.isCollapsed then return end
    if self.player:isDead() or getSpecificPlayer(self.playerNum) ~= self.player then
        self:close()
        return
    end
    local now = getTimestampMs()
    if now >= self.nextRequest then
        TraitShop.requestState(self.playerNum, self.player)
        self.nextRequest = now + 2000
    end
    if now >= self.nextRefresh then
        self:refresh()
        self.nextRefresh = now + 250
    end
    local fontHeight = getTextManager():getFontHeight(UIFont.Small)
    local y = self:titleBarHeight() + 7
    local state = self.state
    if not state then
        self:drawText(getText("UI_OMHTS_Loading"), 12, y, 1, 1, 1, 1, UIFont.Small)
        return
    end
    self:drawText(getText("UI_OMHTS_Tokens", tostring(state.tokens)), 12, y, 1, 0.85, 0.4, 1, UIFont.Medium)
    self:drawTextRight(getText("UI_OMHTS_Level", tostring(state.level)), self.width - 12, y,
        0.9, 0.9, 0.9, 1, UIFont.Small)
    y = y + fontHeight * 2
    self:drawRect(12, y, self.width - 24, fontHeight + 6, 0.75, 0.08, 0.12, 0.09)
    self:drawText(getText("UI_OMHTS_XP", tostring(state.xp)), 18, y + 2, 0.8, 0.8, 0.8, 1, UIFont.Small)
    y = y + fontHeight + 10
    self:drawText(getText("UI_OMHTS_Prestige", tostring(state.earnedPrestige),
        tostring(state.retainedPrestige), tostring(state.pendingPrestige)), 12, y, 0.8, 0.8, 0.8, 1, UIFont.Small)
    local bottom = self.list:getBottom() + 8
    local message = getText("UI_OMHTS_Creation_" .. state.creationStatus, tostring(state.startingTokens))
    self:drawText(message, 12, bottom, 0.7, 0.7, 0.7, 1, UIFont.Small)
    if state.result then
        self:drawText(getText("UI_OMHTS_Result_" .. state.result), 12, bottom + fontHeight + 3,
            0.9, 0.9, 0.9, 1, UIFont.Small)
    end
end

---@return nil
function OMHTS_ShopWindow:close()
    ISCollapsableWindow.close(self)
    self:removeFromUIManager()
end

---@param player IsoPlayer
---@return OMHTS_ShopWindow
function OMHTS_ShopWindow:new(player)
    local fontHeight = getTextManager():getFontHeight(UIFont.Small)
    local width = math.min(math.max(820, fontHeight * 42), getCore():getScreenWidth() - 40)
    local height = math.min(math.max(620, fontHeight * 26), getCore():getScreenHeight() - 60)
    local x = math.floor((getCore():getScreenWidth() - width) / 2)
    local y = math.floor((getCore():getScreenHeight() - height) / 2)
    local window = ISCollapsableWindow.new(self, x, y, width, height)
    window.player = player
    window.playerNum = player:getPlayerNum()
    window.title = getText("UI_OMHTS_Title")
    window.resizable = false
    window.pin = true
    window.nextRefresh = 0
    window.nextRequest = 0
    window.backgroundColor = { r = 0.06, g = 0.08, b = 0.07, a = 0.97 }
    return window
end

---@param player IsoPlayer
---@return nil
function TraitShop.toggleWindow(player)
    if not player or player:isDead() then return end
    local slot = player:getPlayerNum()
    local window = windows[slot]
    if window and window.player ~= player then
        window:close()
        windows[slot] = nil
        window = nil
    end
    if window and window:getIsVisible() then
        window:close()
        return
    end
    if not window then
        window = OMHTS_ShopWindow:new(player)
        window:initialise()
        window:instantiate()
        windows[slot] = window
    end
    window:setVisible(true)
    window:addToUIManager()
    window:bringToTop()
    window.nextRefresh = 0
    window.nextRequest = 0
end

---@return nil
local function resetWindows()
    for _, window in pairs(windows) do
        window:close()
    end
    windows = {}
end

Events.OnDisconnect.Add(resetWindows)
Events.OnInitGlobalModData.Add(resetWindows)
