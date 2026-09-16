if isServer() then return end

require("ISUI/ISPanel")
require("ISUI/ISResizeWidget")
require("ISUI/ISScrollingListBox")
require("ISUI/ISButton")
require("ISUI/ISTextEntryBox")
require("OMHTS_ClientState")
local TraitShop = require("OMHTS_Bootstrap")
local Catalog = require("OMHTS_Catalog")
local Presentation = require("OMHTS_Presentation")
local GOLD = Presentation.GOLD
local GREEN = Presentation.GREEN
local RED = Presentation.RED
local windows = {}

---@class OMHTS_ShopWindow: ISPanel
OMHTS_ShopWindow = ISPanel:derive("OMHTS_ShopWindow")

---@param self ISScrollingListBox
---@param y number
---@param item table
---@param alt boolean
---@return number
local function drawTrait(self, y, item, alt)
    local row = item.item
    local height = self.itemheight
    if y + height < 0 or y > self.height then return y + height end
    local color = GREEN
    if row.group == "negative" then
        color = RED
    end
    local selected = self.parent.cart[row.id] == true
    if selected and self.group ~= "receipt" then
        self:drawRect(1, y, self.width - 2, height, 0.18, color.r, color.g, color.b)
        self:drawRectBorder(1, y, self.width - 2, height, 1, GOLD.r, GOLD.g, GOLD.b)
    elseif alt then
        self:drawRect(1, y, self.width - 2, height, 0.035, 1, 1, 1)
    end
    if not row.owned and row.status ~= "available" then
        color = { r = 0.5, g = 0.5, b = 0.5 }
    elseif row.group == "negative" and row.status ~= "available" then
        color = { r = 0.5, g = 0.5, b = 0.5 }
    end
    local texture = row.definition:getTexture()
    local iconSize = math.min(24, height - 6)
    if texture then
        self:drawTextureScaled(texture, 7, y + (height - iconSize) / 2, iconSize, iconSize, 1, color.r, color.g, color.b)
    end
    local textY = y + (height - self.parent.fontHeight) / 2
    local name = row.name
    if self.group == "receipt" then
        local key = "UI_OMHTS_ReceiptAdd"
        if row.group == "negative" then
            key = "UI_OMHTS_ReceiptRemove"
        end
        name = getText(key, name)
    end
    local space = 62
    if row.group ~= "positive" or self.group == "receipt" then
        space = 115
    end
    self:drawText(Presentation.fitName(name, self.width - space), 38, textY,
        color.r, color.g, color.b, 1, UIFont.Small)
    if row.group ~= "positive" then
        local price = getText("UI_OMHTS_NoPrice")
        if row.price then
            price = tostring(row.price)
        end
        self:drawTextRight(price, self.width - 20, textY, color.r, color.g, color.b, 1, UIFont.Small)
    end
    return y + height
end

---@param self ISButton
---@return nil
local function drawProgress(self)
    ISButton.prerender(self)
    self:drawRect(1, 1, (self.width - 2) * math.max(0, math.min(1, self.xp / 100)),
        self.height - 2, 0.85, GOLD.r, GOLD.g, GOLD.b)
end

---@param self OMHTS_ShopWindow
---@param title string
---@param callback function|nil
---@return ISButton
local function addButton(self, title, callback)
    local button = ISButton:new(0, 0, 100, 28, title, self, callback)
    button:initialise()
    button:instantiate()
    button.backgroundColor = { r = 0.07, g = 0.07, b = 0.07, a = 1 }
    button.backgroundColorMouseOver = { r = 0.14, g = 0.14, b = 0.14, a = 1 }
    button.borderColor = { r = 0.4, g = 0.4, b = 0.4, a = 0.6 }
    self:addChild(button)
    return button
end

---@param self ISUIElement
---@param x number
---@param y number
---@param width number
---@param height number
---@return nil
local function place(self, x, y, width, height)
    self:setX(x)
    self:setY(y)
    self:setWidth(width)
    self:setHeight(height)
end

---@param self OMHTS_ShopWindow
---@param group string
---@return ISScrollingListBox
local function addList(self, group)
    local list = ISScrollingListBox:new(0, 0, 200, 100)
    list:initialise()
    list:instantiate()
    list.group = group
    list.itemheight = math.max(28, self.fontHeight + 8)
    list.doDrawItem = drawTrait
    list.drawBorder = true
    list.useStencilForChildren = true
    list.borderColor = { r = 0.4, g = 0.4, b = 0.4, a = 0.55 }
    list.backgroundColor = { r = 0.025, g = 0.025, b = 0.025, a = 0.9 }
    if group == "receipt" then
        list:setOnMouseDownFunction(self, self.onReceipt)
    else
        list:setOnMouseDownFunction(self, self.onSelect)
    end
    self:addChild(list)
    return list
end

---@return nil
function OMHTS_ShopWindow:layout()
    local fh = self.fontHeight
    local width = self.width - 24
    local half = math.floor((width - 16) / 2)
    local right = 12 + half + 16
    self.levelY = self.mediumHeight * 2 + 20
    local statsWidth = math.floor(width * 0.31)
    place(self.tokens, 12, self.levelY, statsWidth, fh + self.mediumHeight + 8)
    place(self.prestige, self.width - 12 - statsWidth, self.levelY, statsWidth, fh + self.mediumHeight + 8)
    place(self.progress, 12, self.levelY + fh + self.mediumHeight + 16, width, fh + 8)
    self.headingY = self.progress:getBottom() + 10
    local searchY = self.headingY + fh + 6
    local filterWidth = math.min(120, math.floor(half * 0.43))
    place(self.search, 12, searchY, half - filterWidth - 6, fh + 10)
    place(self.filter, 12 + half - filterWidth, searchY, filterWidth, fh + 10)
    local actionHeight = fh + 12
    local receiptHeight = self.receipt.itemheight * 2
    local bottom = self.height - receiptHeight - fh * 3 - actionHeight - 48
    place(self.list, 12, self.search:getBottom() + 6, half, bottom - self.search:getBottom() - 6)
    local positiveHeight = math.floor((bottom - searchY - fh - 16) / 2)
    place(self.positive, right, searchY, half, positiveHeight)
    self.negativeHeadingY = self.positive:getBottom() + 8
    local negativeY = self.negativeHeadingY + fh + 6
    place(self.negative, right, negativeY, half, bottom - negativeY)
    self.receiptY = bottom + 8
    place(self.receipt, 12, self.receiptY + fh + 6, width, receiptHeight)
    self.totalY = self.receipt:getBottom() + 6
    self.noticeY = self.totalY + fh + 5
    local actionWidth = math.floor((width - 16) / 3)
    local actionY = self.height - actionHeight - 12
    place(self.buy, 12, actionY, actionWidth, actionHeight)
    place(self.reset, 12 + actionWidth + 8, actionY, actionWidth, actionHeight)
    place(self.closeButton, 12 + (actionWidth + 8) * 2, actionY, actionWidth, actionHeight)
    place(self.resizeWidget, self.width - 12, self.height - 12, 12, 12)
end

---@return nil
function OMHTS_ShopWindow:createChildren()
    self.tokens = addButton(self, getText("UI_OMHTS_Tokens", "-"), nil)
    self.prestige = addButton(self, getText("UI_OMHTS_Prestige", "-"), nil)
    self.tokens:setFont(UIFont.Medium)
    self.prestige:setFont(UIFont.Medium)
    self.tokens.textColor = GOLD
    self.prestige.textColor = GOLD
    self.progress = addButton(self, "0 / 100", nil)
    self.progress.xp = 0
    self.progress.prerender = drawProgress
    self.progress.textColor = { r = 1, g = 1, b = 1, a = 1 }
    self.progress:setTooltip(getText("UI_OMHTS_XPDeferred"))
    self.search = ISTextEntryBox:new("", 0, 0, 100, 28)
    self.search:initialise()
    self.search:instantiate()
    self.search:setPlaceholderText(getText("UI_OMHTS_Search"))
    self.search:setTooltip(getText("UI_OMHTS_SearchTip"))
    self.search:setClearButton(true)
    self:addChild(self.search)
    self.filter = addButton(self, getText("UI_OMHTS_Filter_1"), self.onFilter)
    self.list = addList(self, "catalog")
    self.positive = addList(self, "positive")
    self.negative = addList(self, "negative")
    self.receipt = addList(self, "receipt")
    self.lists = { self.list, self.positive, self.negative }
    self.buy = addButton(self, getText("UI_OMHTS_Buy"), self.onBuy)
    self.reset = addButton(self, getText("UI_OMHTS_Reset"), self.onReset)
    self.closeButton = addButton(self, getText("UI_OMHTS_Close"), self.close)
    self.buy:setEnable(false)
    self.resizeWidget = ISResizeWidget:new(0, 0, 12, 12, self)
    self.resizeWidget:initialise()
    self.resizeWidget.resizeFunction = OMHTS_ShopWindow.Resize
    self:addChild(self.resizeWidget)
    self:layout()
end

---@param width number
---@param height number
---@return nil
function OMHTS_ShopWindow:Resize(width, height)
    self:setWidth(math.max(self.minimumWidth, math.min(width, getCore():getScreenWidth() - self.x)))
    self:setHeight(math.max(self.minimumHeight, math.min(height, getCore():getScreenHeight() - self.y)))
    self:layout()
    self.rowsKey = nil
    self.nextRefresh = 0
end

---@param row table
---@return nil
function OMHTS_ShopWindow:onSelect(row)
    if TraitShop.purchasePending(self.playerNum) then return end
    self.focusedId = row.id
    self.notice = nil
    if row.group == "positive" then
        self:updateCart()
        return
    end
    local list = self.list
    if row.group == "negative" then
        list = self.negative
    end
    local selectedIndex
    local anchorIndex
    for index = 1, #list.items do
        if list.items[index].item.id == row.id then
            selectedIndex = index
        end
        if list.items[index].item.id == self.anchors[row.group] then
            anchorIndex = index
        end
    end
    if not isCtrlKeyDown() then
        for id in pairs(self.cart) do
            local item = self.allRows[id]
            if item and item.group == row.group then
                self.cart[id] = nil
            end
        end
    end
    if isShiftKeyDown() and anchorIndex and selectedIndex then
        for index = math.min(anchorIndex, selectedIndex), math.max(anchorIndex, selectedIndex) do
            self.cart[list.items[index].item.id] = true
        end
    else
        if self.cart[row.id] then
            self.cart[row.id] = nil
        else
            self.cart[row.id] = true
        end
        self.anchors[row.group] = row.id
    end
    self:updateCart()
end

---@param row table
---@return nil
function OMHTS_ShopWindow:onReceipt(row)
    if TraitShop.purchasePending(self.playerNum) then return end
    self.cart[row.id] = nil
    self.notice = nil
    self:updateCart()
end

---@return nil
function OMHTS_ShopWindow:onReset()
    if TraitShop.purchasePending(self.playerNum) then return end
    self.cart = {}
    self.anchors = {}
    self.notice = nil
    self:updateCart()
end

---@return nil
function OMHTS_ShopWindow:onFilter()
    self.filterMode = self.filterMode % 3 + 1
    self.filter:setTitle(getText("UI_OMHTS_Filter_" .. self.filterMode))
    self.nextRefresh = 0
end

---@return nil
function OMHTS_ShopWindow:onBuy()
    if not self.cartValid then return end
    if TraitShop.purchase(self.player, self.cart) then
        self.submitted = true
        self.notice = nil
        self.nextRefresh = 0
    end
end

---@return nil
function OMHTS_ShopWindow:updateCart()
    local scroll = self.receipt:getYScroll()
    self.receipt:clear()
    local rows = {}
    local total = 0
    local reason
    local final = {}
    for id, row in pairs(self.allRows) do
        if row.owned and not (row.group == "negative" and self.cart[id]) then
            final[id] = row
        end
    end
    for id in pairs(self.cart) do
        local row = self.allRows[id]
        if row then
            rows[#rows + 1] = row
            if row.price then
                total = total + row.price
            end
            if row.group == "catalog" then
                final[id] = row
            end
            if row.status ~= "available" and row.status ~= "funds" and row.status ~= "conflict" then
                reason = row.status
            end
        else
            reason = "absent"
        end
    end
    table.sort(rows, Presentation.cheapestFirst)
    for index = 1, #rows do
        local row = rows[index]
        self.receipt:addItem(row.name, row)
        if row.group == "catalog" then
            for id, other in pairs(final) do
                if id ~= row.id and (row.definition:isMutuallyExclusive(other.definition)
                    or other.definition:isMutuallyExclusive(row.definition)) then
                    reason = "conflict"
                end
            end
        end
    end
    if #rows > Catalog.MAX_CART then
        reason = "limit"
    elseif self.state and total > self.state.tokens then
        reason = "funds"
    end
    self.cartTotal = total
    self.cartCount = #rows
    self.cartReason = reason
    self.cartValid = #rows > 0 and reason == nil and self.state ~= nil
        and not TraitShop.purchasePending(self.playerNum)
    self.buy:setEnable(self.cartValid)
    self.reset:setEnable(not TraitShop.purchasePending(self.playerNum))
    self.receipt:setYScroll(math.max(math.min(0, self.receipt.height - #rows * self.receipt.itemheight), math.min(0, scroll)))
end

---@return nil
function OMHTS_ShopWindow:refresh()
    local state = TraitShop.getState(self.playerNum)
    self.state = state
    if not state then
        self.buy:setEnable(false)
        return
    end
    if self.lifeId and self.lifeId ~= state.lifeId then
        self.cart = {}
        self.anchors = {}
    end
    self.lifeId = state.lifeId
    if self.submitted and not TraitShop.purchasePending(self.playerNum) then
        self.submitted = false
        if state.result == "purchased" then
            self.cart = {}
            self.anchors = {}
        end
        if state.result then
            self.notice = getText("UI_OMHTS_Result_" .. state.result)
        end
    end
    self.tokens:setTitle(getText("UI_OMHTS_Tokens", tostring(state.tokens)))
    self.prestige:setTitle(getText("UI_OMHTS_Prestige", tostring(state.retainedPrestige + state.earnedPrestige)))
    self.prestige:setTooltip(getText("UI_OMHTS_PrestigeTip", tostring(state.retainedPrestige), tostring(state.earnedPrestige)))
    self.tokens:setTooltip(getText("UI_OMHTS_TokenTip", tostring(state.startingTokens), tostring(state.spentTokens),
        tostring(state.tokens)) .. "\n\n" .. getText("UI_OMHTS_Creation_" .. state.creationStatus, tostring(state.startingTokens))
        .. "\n\n" .. getText("UI_OMHTS_TokenSourcesDeferred"))
    self.progress.xp = state.xp
    self.progress:setTitle(tostring(math.floor(state.xp)) .. " / 100")
    local owned, ownershipKey = Presentation.ownership(self.player, state)
    local query = Presentation.normalize(string.sub(self.search:getInternalText(), 1, 128))
    local parts = { tostring(state.lifeId), tostring(state.revision), ownershipKey, query, tostring(self.filterMode) }
    for index = 1, #state.offers do
        local offer = state.offers[index]
        parts[#parts + 1] = offer.id .. ":" .. offer.status .. ":" .. offer.price
    end
    local key = table.concat(parts, "|")
    if key ~= self.rowsKey then
        local groups = Presentation.rows(self.definitions, owned, state, query, self.filterMode)
        local all = Presentation.rows(self.definitions, owned, state, "", 1)
        self.allRows = {}
        for _, rows in pairs(all) do
            for index = 1, #rows do
                self.allRows[rows[index].id] = rows[index]
            end
        end
        for index = 1, #self.lists do
            local list = self.lists[index]
            local scroll = list:getYScroll()
            list:clear()
            local rows = groups[list.group]
            for rowIndex = 1, #rows do
                local row = rows[rowIndex]
                local item = list:addItem(row.name, row)
                item.tooltip = row.tooltip
            end
            list:setYScroll(math.max(math.min(0, list.height - #rows * list.itemheight), math.min(0, scroll)))
        end
        self.rowsKey = key
    end
    self:updateCart()
end

---@return nil
function OMHTS_ShopWindow:prerender()
    ISPanel.prerender(self)
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
    local balance = "-"
    if self.state then
        level = tostring(self.state.level)
        balance = tostring(self.state.tokens - self.cartTotal)
    end
    self:drawTextCentre(getText("UI_OMHTS_Brand"), self.width / 2, 8, RED.r, RED.g, RED.b, 1, UIFont.Medium)
    self:drawTextCentre(getText("UI_OMHTS_Subtitle"), self.width / 2, 10 + self.mediumHeight,
        GREEN.r, GREEN.g, GREEN.b, 1, UIFont.Medium)
    self:drawTextCentre(getText("UI_OMHTS_Level"), self.width / 2, self.levelY, 0.91, 0.91, 0.91, 1, UIFont.Small)
    self:drawTextCentre(level, self.width / 2, self.levelY + self.fontHeight + 4, GOLD.r, GOLD.g, GOLD.b, 1, UIFont.Medium)
    self:drawText(getText("UI_OMHTS_Catalog", tostring(#self.list.items)), 12, self.headingY, 0.91, 0.91, 0.91, 1, UIFont.Small)
    self:drawText(getText("UI_OMHTS_Positive", tostring(#self.positive.items)), self.positive.x, self.headingY,
        GREEN.r, GREEN.g, GREEN.b, 1, UIFont.Small)
    self:drawText(getText("UI_OMHTS_Negative", tostring(#self.negative.items)), self.negative.x, self.negativeHeadingY,
        RED.r, RED.g, RED.b, 1, UIFont.Small)
    self:drawText(getText("UI_OMHTS_Receipt", tostring(self.cartCount)), 12, self.receiptY, 0.91, 0.91, 0.91, 1, UIFont.Small)
    self:drawText(getText("UI_OMHTS_Total", tostring(self.cartTotal)), 12, self.totalY, GOLD.r, GOLD.g, GOLD.b, 1, UIFont.Small)
    self:drawTextRight(getText("UI_OMHTS_Remaining", balance), self.width - 12, self.totalY, 0.91, 0.91, 0.91, 1, UIFont.Small)
    local notice = self.notice
    if TraitShop.purchasePending(self.playerNum) then
        notice = getText("UI_OMHTS_Purchasing")
    elseif self.cartReason then
        notice = getText("UI_OMHTS_Status_" .. self.cartReason)
    end
    if notice then
        self:drawText(Presentation.fitName(notice, self.width - 24), 12, self.noticeY, 0.8, 0.8, 0.8, 1, UIFont.Small)
    end
    self:drawTextRight("/", self.width - 2, self.height - self.fontHeight, GOLD.r, GOLD.g, GOLD.b, 0.7, UIFont.Small)
end

---@return nil
function OMHTS_ShopWindow:close()
    for _, child in pairs(self.children) do
        if child.tooltipUI then
            child.tooltipUI:setVisible(false)
            child.tooltipUI:removeFromUIManager()
        end
    end
    self.cart = {}
    self.anchors = {}
    self.notice = nil
    self.submitted = false
    self:setVisible(false)
    self:removeFromUIManager()
end

---@param player IsoPlayer
---@return OMHTS_ShopWindow
function OMHTS_ShopWindow:new(player)
    local fh = getTextManager():getFontHeight(UIFont.Small)
    local screenWidth = getCore():getScreenWidth()
    local screenHeight = getCore():getScreenHeight()
    local width = math.min(math.max(880, fh * 36), screenWidth - 40)
    local height = math.min(math.max(700, fh * 29), screenHeight - 40)
    local window = ISPanel.new(self, math.floor((screenWidth - width) / 2),
        math.floor((screenHeight - height) / 2), width, height)
    window.player = player
    window.playerNum = player:getPlayerNum()
    window.moveWithMouse = true
    window.minimumWidth = math.min(math.max(600, fh * 28), screenWidth - 40)
    window.minimumHeight = math.min(math.max(540, fh * 23 + 100), screenHeight - 40)
    window.fontHeight = fh
    window.mediumHeight = getTextManager():getFontHeight(UIFont.Medium)
    window.nextRefresh = 0
    window.nextRequest = 0
    window.filterMode = 1
    window.allRows = {}
    window.cart = {}
    window.anchors = {}
    window.cartTotal = 0
    window.cartCount = 0
    window.definitions = Catalog.definitions()
    window.backgroundColor = { r = 0.055, g = 0.055, b = 0.055, a = 0.98 }
    return window
end

---@param player IsoPlayer
---@return nil
function TraitShop.toggleWindow(player)
    if not player or player:isDead() then return end
    local slot = player:getPlayerNum()
    local window = windows[slot]
    if window and (window.player ~= player or window.fontHeight ~= getTextManager():getFontHeight(UIFont.Small)
        or window.width > getCore():getScreenWidth() - 40 or window.height > getCore():getScreenHeight() - 40) then
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
