if isServer() then return end

require("ISUI/ISCollapsableWindow")
require("ISUI/ISScrollingListBox")
require("ISUI/ISRichTextPanel")
require("ISUI/ISButton")
require("ISUI/ISTextEntryBox")
require("OMHTS_ClientState")
local TraitShop = require("OMHTS_Bootstrap")
local Catalog = require("OMHTS_Catalog")
local Presentation = require("OMHTS_Presentation")
local GOLD = Presentation.GOLD
local windows = {}

---@class OMHTS_ShopWindow: ISCollapsableWindow
OMHTS_ShopWindow = ISCollapsableWindow:derive("OMHTS_ShopWindow")

---@param self ISScrollingListBox
---@param y number
---@param item table
---@param alt boolean
---@return number
local function drawTrait(self, y, item, alt)
    local row = item.item
    local height = self.itemheight
    if y + height < 0 or y > self.height then return y + height end
    local selected = self.parent.selectedId == row.id
    if selected then
        if row.group == "negative" then
            self:drawRect(1, y, self.width - 2, height, 0.4, 0.45, 0.13, 0.13)
        else
            self:drawRect(1, y, self.width - 2, height, 0.4, 0.13, 0.36, 0.19)
        end
        self:drawRectBorder(1, y, self.width - 2, height, 1, GOLD.r, GOLD.g, GOLD.b)
    elseif alt then
        self:drawRect(1, y, self.width - 2, height, 0.035, 1, 1, 1)
    end
    local r, g, b = 0.92, 0.92, 0.92
    local alpha = 1
    if row.owned then
        r, g, b = GOLD.r, GOLD.g, GOLD.b
    elseif row.status ~= "available" then
        r, g, b = 0.5, 0.5, 0.5
        alpha = 0.45
    end
    local texture = row.definition:getTexture()
    local iconSize = math.min(24, height - 6)
    if texture then
        self:drawTextureScaled(texture, 7, y + (height - iconSize) / 2, iconSize, iconSize, alpha, r, g, b)
    end
    local textY = y + (height - self.parent.fontHeight) / 2
    self:drawText(row.displayName, 38, textY, r, g, b, 1, UIFont.Small)
    if row.group == "catalog" then
        local price = getText("UI_OMHTS_NoPrice")
        if row.price then
            price = tostring(row.price)
        end
        self:drawTextRight(price, self.width - 20, textY, r, g, b, 1, UIFont.Small)
    end
    return y + height
end

---@param self ISButton
---@return nil
local function drawProgress(self)
    ISButton.prerender(self)
    local fraction = math.max(0, math.min(1, self.percent / 100))
    self:setTitle(getText("UI_OMHTS_Percent", tostring(math.floor(fraction * 100))))
    self:drawRect(1, 1, (self.width - 2) * fraction, self.height - 2, 0.85, GOLD.r, GOLD.g, GOLD.b)
end

---@param self OMHTS_ShopWindow
---@param x number
---@param y number
---@param width number
---@param height number
---@param title string
---@param callback function|nil
---@return ISButton
local function addButton(self, x, y, width, height, title, callback)
    local button = ISButton:new(x, y, width, height, title, self, callback)
    button:initialise()
    button:instantiate()
    button.backgroundColor = { r = 0.07, g = 0.07, b = 0.06, a = 0.9 }
    button.backgroundColorMouseOver = { r = 0.15, g = 0.14, b = 0.1, a = 0.9 }
    button.borderColor = { r = GOLD.r, g = GOLD.g, b = GOLD.b, a = 0.25 }
    self:addChild(button)
    return button
end

---@param self OMHTS_ShopWindow
---@param group string
---@param x number
---@param y number
---@param width number
---@param height number
---@return ISScrollingListBox
local function addList(self, group, x, y, width, height)
    local list = ISScrollingListBox:new(x, y, width, height)
    list:initialise()
    list:instantiate()
    list.group = group
    list.itemheight = math.max(30, self.fontHeight + 10)
    list.doDrawItem = drawTrait
    list.drawBorder = true
    list.useStencilForChildren = true
    list.borderColor = { r = 0.4, g = 0.4, b = 0.36, a = 0.55 }
    list.backgroundColor = { r = 0.025, g = 0.025, b = 0.02, a = 0.85 }
    list:setOnMouseDownFunction(self, self.onSelect)
    self:addChild(list)
    return list
end

---@return nil
function OMHTS_ShopWindow:createChildren()
    ISCollapsableWindow.createChildren(self)
    local fh = self.fontHeight
    local innerWidth = self.width - 24
    local halfWidth = math.floor((innerWidth - 16) / 2)
    local rightX = 12 + halfWidth + 16
    local y = self:titleBarHeight() + fh + 16
    self.progress = addButton(self, 12, y, innerWidth, fh + 8, getText("UI_OMHTS_Percent", "0"), nil)
    self.progress.percent = 0
    self.progress.prerender = drawProgress
    self.progress:setTooltip(getText("UI_OMHTS_XPDeferred"))
    y = self.progress:getBottom() + 6
    self.tokens = addButton(self, 12, y, halfWidth, fh + 14, getText("UI_OMHTS_Tokens", "-"), nil)
    self.prestige = addButton(self, rightX, y, halfWidth, fh + 14, getText("UI_OMHTS_Prestige", "-"), nil)
    self.tokens:setFont(UIFont.Medium)
    self.prestige:setFont(UIFont.Medium)
    self.tokens.textColor = GOLD
    self.prestige.textColor = GOLD
    self.headingY = self.tokens:getBottom() + 12
    local searchY = self.headingY + fh + 6
    local filterWidth = math.max(112, getTextManager():MeasureStringX(UIFont.Small,
        getText("UI_OMHTS_Filter_3")) + 20)
    self.search = ISTextEntryBox:new("", 12, searchY, halfWidth - filterWidth - 6, fh + 10)
    self.search:initialise()
    self.search:instantiate()
    self.search:setPlaceholderText(getText("UI_OMHTS_Search"))
    self.search:setTooltip(getText("UI_OMHTS_SearchTip"))
    self.search:setClearButton(true)
    self:addChild(self.search)
    self.filter = addButton(self, 12 + halfWidth - filterWidth, searchY, filterWidth, fh + 10,
        getText("UI_OMHTS_Filter_1"), self.onFilter)
    local footerHeight = fh * 3 + 12
    local actionHeight = fh + 12
    local listBottom = self.height - footerHeight - actionHeight - 36
    self.list = addList(self, "catalog", 12, self.search:getBottom() + 6, halfWidth,
        listBottom - self.search:getBottom() - 6)
    local halfHeight = math.floor((listBottom - searchY - fh - 16) / 2)
    self.positive = addList(self, "positive", rightX, searchY, halfWidth, halfHeight)
    self.negativeHeadingY = self.positive:getBottom() + 10
    local negativeY = self.negativeHeadingY + fh + 6
    self.negative = addList(self, "negative", rightX, negativeY, halfWidth, listBottom - negativeY)
    self.lists = { self.list, self.positive, self.negative }
    self.buy = addButton(self, 12, listBottom + 8, halfWidth, actionHeight, getText("UI_OMHTS_Buy"), self.onBuy)
    self.buy:setEnable(false)
    self.remove = addButton(self, rightX, listBottom + 8, halfWidth, actionHeight,
        getText("UI_OMHTS_Remove"), nil)
    self.remove:setEnable(false)
    self.remove:setTooltip(getText("UI_OMHTS_Status_removal_deferred"))
    self.description = ISRichTextPanel:new(12, self.buy:getBottom() + 8, innerWidth, footerHeight)
    self.description:initialise()
    self.description:instantiate()
    self.description.autosetheight = false
    self.description.clip = true
    self.description:addScrollBars()
    self:addChild(self.description)
end

---@param row table
---@return nil
function OMHTS_ShopWindow:onSelect(row)
    self.selectedId = row.id
    self:updateSelection()
end

---@return nil
function OMHTS_ShopWindow:onFilter()
    self.filterMode = self.filterMode % 3 + 1
    self.filter:setTitle(getText("UI_OMHTS_Filter_" .. self.filterMode))
    self.nextRefresh = 0
end

---@return nil
function OMHTS_ShopWindow:onBuy()
    local row = self.rowsById[self.selectedId]
    if not row or row.group ~= "catalog" or row.status ~= "available" then return end
    TraitShop.purchase(self.player, row.id)
    self.nextRefresh = 0
end

---@return nil
function OMHTS_ShopWindow:updateSelection()
    local row = self.rowsById[self.selectedId]
    local pending = TraitShop.purchasePending(self.playerNum)
    self.buy:setEnable(row ~= nil and row.group == "catalog" and row.status == "available" and not pending)
    local title = getText("UI_OMHTS_Buy")
    if pending then
        title = getText("UI_OMHTS_Purchasing")
    elseif row and row.group == "catalog" and row.price then
        title = getText("UI_OMHTS_BuyFor", tostring(row.price))
    end
    self.buy:setTitle(title)
    local text = getText("UI_OMHTS_SelectTrait")
    if row then
        text = "<RGB:0.99,0.88,0.49> " .. row.name .. " <RGB:0.9,0.9,0.9> "
            .. " <LINE> " .. row.description .. " <LINE> " .. getText("UI_OMHTS_Status_" .. row.status)
        self.buy:setTooltip(getText("UI_OMHTS_Status_" .. row.status))
    end
    if self.state and self.state.result then
        text = text .. " <LINE> " .. getText("UI_OMHTS_Result_" .. self.state.result)
    end
    if text ~= self.description.text then
        self.description.text = text
        self.description:paginate()
        self.description:setYScroll(0)
    end
end

---@return nil
function OMHTS_ShopWindow:refresh()
    local state = TraitShop.getState(self.playerNum)
    self.state = state
    if not state then
        self.buy:setEnable(false)
        return
    end
    self.tokens:setTitle(getText("UI_OMHTS_Tokens", tostring(state.tokens)))
    self.prestige:setTitle(getText("UI_OMHTS_Prestige", tostring(state.retainedPrestige + state.earnedPrestige)))
    self.prestige:setTooltip(getText("UI_OMHTS_PrestigeTip", tostring(state.retainedPrestige), tostring(state.earnedPrestige)))
    self.tokens:setTooltip(getText("UI_OMHTS_TokenTip", tostring(state.startingTokens), tostring(state.spentTokens),
        tostring(state.tokens)) .. "\n\n" .. getText("UI_OMHTS_Creation_" .. state.creationStatus, tostring(state.startingTokens))
        .. "\n\n" .. getText("UI_OMHTS_TokenSourcesDeferred"))
    local owned, ownershipKey = Presentation.ownership(self.player, state)
    local query = string.lower(string.sub(self.search:getInternalText(), 1, 128))
    local parts = { tostring(state.lifeId), tostring(state.revision), ownershipKey, query,
        tostring(self.filterMode), tostring(Catalog.multiplier()) }
    for index = 1, #state.offers do
        local offer = state.offers[index]
        parts[#parts + 1] = offer.id .. ":" .. offer.status .. ":" .. offer.price
    end
    local key = table.concat(parts, "|")
    if key ~= self.rowsKey then
        local groups = Presentation.rows(self.definitions, owned, state, query, self.filterMode)
        self.rowsById = {}
        for index = 1, #self.lists do
            local list = self.lists[index]
            local scroll = list:getYScroll()
            list:clear()
            local rows = groups[list.group]
            for rowIndex = 1, #rows do
                local row = rows[rowIndex]
                local nameWidth = list.width - 60
                if row.group == "catalog" then
                    nameWidth = nameWidth - 80
                end
                row.displayName = Presentation.fitName(row.name, nameWidth)
                list:addItem(row.name, row, row.tooltip)
                self.rowsById[row.id] = row
            end
            list:setYScroll(math.max(math.min(0, list.height - #rows * list.itemheight), math.min(0, scroll)))
        end
        if not self.rowsById[self.selectedId] then
            self.selectedId = nil
        end
        self.rowsKey = key
    end
    self:updateSelection()
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
    local level = "-"
    if self.state then
        level = tostring(self.state.level)
    end
    self:drawTextCentre(getText("UI_OMHTS_Level", level), self.width / 2, self:titleBarHeight() + 6,
        0.95, 0.95, 0.95, 1, UIFont.Medium)
    self:drawText(getText("UI_OMHTS_Catalog", tostring(#self.list.items)), 12, self.headingY,
        0.9, 0.9, 0.9, 1, UIFont.Small)
    self:drawText(getText("UI_OMHTS_Positive", tostring(#self.positive.items)), self.positive.x, self.headingY,
        GOLD.r, GOLD.g, GOLD.b, 1, UIFont.Small)
    self:drawText(getText("UI_OMHTS_Negative", tostring(#self.negative.items)), self.negative.x, self.negativeHeadingY,
        GOLD.r, GOLD.g, GOLD.b, 1, UIFont.Small)
    for index = 1, #self.lists do
        local list = self.lists[index]
        if #list.items == 0 then
            self:drawText(getText("UI_OMHTS_Empty_" .. list.group), list.x + 8, list.y + 8,
                0.5, 0.5, 0.5, 1, UIFont.Small)
        end
    end
end

---@return nil
function OMHTS_ShopWindow:close()
    for _, child in pairs(self.children) do
        if child.tooltipUI then
            child.tooltipUI:setVisible(false)
            child.tooltipUI:removeFromUIManager()
        end
    end
    ISCollapsableWindow.close(self)
    self:removeFromUIManager()
end

---@param player IsoPlayer
---@return OMHTS_ShopWindow
function OMHTS_ShopWindow:new(player)
    local fh = getTextManager():getFontHeight(UIFont.Small)
    local width = math.min(math.max(900, fh * 36), getCore():getScreenWidth() - 40)
    local height = math.min(math.max(650, fh * 25), getCore():getScreenHeight() - 60)
    local window = ISCollapsableWindow.new(self,
        math.floor((getCore():getScreenWidth() - width) / 2),
        math.floor((getCore():getScreenHeight() - height) / 2), width, height)
    window.player = player
    window.playerNum = player:getPlayerNum()
    window.title = getText("UI_OMHTS_Title")
    window.resizable = false
    window.pin = true
    window.fontHeight = fh
    window.nextRefresh = 0
    window.nextRequest = 0
    window.filterMode = 1
    window.rowsById = {}
    window.definitions = Catalog.definitions()
    window.backgroundColor = { r = 0.065, g = 0.062, b = 0.052, a = 0.98 }
    return window
end

---@param player IsoPlayer
---@return nil
function TraitShop.toggleWindow(player)
    if not player or player:isDead() then return end
    local slot = player:getPlayerNum()
    local window = windows[slot]
    if window and (window.player ~= player or window.fontHeight ~= getTextManager():getFontHeight(UIFont.Small)
        or window.width > getCore():getScreenWidth() - 40 or window.height > getCore():getScreenHeight() - 60) then
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
