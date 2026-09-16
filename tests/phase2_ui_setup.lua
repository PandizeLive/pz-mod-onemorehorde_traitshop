testStage = "UI lifecycle and hover geometry"
UIFont = { Small = 1, Medium = 2 }
testFontHeight = 18
testScreenWidth = 1280
testScreenHeight = 720
testUI = {}
testDraws = {}
testMouseX = 0
testMouseY = 0
function getCore()
    return { getScreenWidth = function() return testScreenWidth end,
        getScreenHeight = function() return testScreenHeight end }
end
function getTextManager()
    return { getFontHeight = function() return testFontHeight end,
        MeasureStringX = function(self, font, text) return #text * testFontHeight * 0.45 end }
end
function string.sort(a, b) return a > b end
function getText(key, a, b, c)
    local text = UI_EN[key]
    if not text then error("Missing translation: " .. key) end
    local values = { a, b, c }
    for index = 1, #values do text = string.gsub(text, "%%" .. index, values[index]) end
    return text
end
function getMouseX() return testMouseX end
function getMouseY() return testMouseY end
function tryGetTexture(name)
    check(name == "OMHTS_ShopIcon", "custom icon uses extensionless native texture resolver")
    return { name = name }
end
local Panel = {}
Panel.__index = Panel
function Panel:derive(name)
    local value = { Type = name }
    value.__index = value
    return setmetatable(value, self)
end
function Panel:new(x, y, width, height, title, target, callback)
    return setmetatable({ x = x, y = y, width = width, height = height, title = title,
        target = target, callback = callback, children = {}, items = {}, selected = 1,
        visible = true, scroll = 0 }, self)
end
function Panel:initialise() end
function Panel:instantiate()
    if self.created then return end
    self.created = true
    self:createChildren()
end
function Panel:createChildren() end
local nextUIId = 100
function Panel:addChild(child)
    nextUIId = nextUIId + 1
    child.ID = nextUIId
    self.children[child.ID] = child
    child.parent = self
end
function Panel:addToUIManager() testUI[self] = true end
function Panel:removeFromUIManager() testUI[self] = nil end
function Panel:bringToTop() end
function Panel:prerender() end
function Panel:getIsVisible() return self.visible end
function Panel:setVisible(value) self.visible = value end
function Panel:setEnable(value) self.enable = value end
function Panel:setTitle(value) self.title = value end
function Panel:setFont(value) self.font = value end
function Panel:isMouseOver()
    return self.visible and testMouseX >= self:getAbsoluteX() and testMouseY >= self:getAbsoluteY()
        and testMouseX < self:getAbsoluteX() + self.width and testMouseY < self:getAbsoluteY() + self.height
end
function Panel:setX(value) self.x = value end
function Panel:setY(value) self.y = value end
function Panel:getAbsoluteX()
    if self.parent then return self.parent:getAbsoluteX() + self.x end
    return self.x
end
function Panel:getAbsoluteY()
    if self.parent then return self.parent:getAbsoluteY() + self.y end
    return self.y
end
function Panel:getWidth() return self.width end
function Panel:getHeight() return self.height end
function Panel:getBottom() return self.y + self.height end
function Panel:setImage(value) self.image = value end
function Panel:setTooltip(value) self.tooltip = value end
function Panel:setAlwaysOnTop(value) self.alwaysOnTop = value end
function Panel:forceImageSize(w, h) self.iconWidth = w; self.iconHeight = h end
function Panel:titleBarHeight() return testFontHeight + 10 end
function Panel:addScrollBars() end
function Panel:paginate() self.paginated = true end
function Panel:getYScroll() return self.scroll end
function Panel:setYScroll(value) self.scroll = value end
function Panel:close() self.visible = false end
function Panel:clear() self.items = {}; self.selected = 1; self.scroll = 0 end
function Panel:addItem(text, value)
    self.items[#self.items + 1] = { text = text, item = value, index = #self.items + 1 }
    return self.items[#self.items]
end
function Panel:setOnMouseDownFunction(target, callback) self.target = target; self.onmousedown = callback end
function Panel:setPlaceholderText(value) self.placeholder = value end
function Panel:setClearButton(value) self.clearButton = value end
function Panel:getInternalText() return self.title end
function Panel:setText(value) self.title = value end
function Panel:drawRect(x, y, w, h) check(w >= 0 and h >= 0, "UI rectangle has nonnegative dimensions") end
function Panel:drawTextureScaled() end
function Panel:drawText(text, x, y) testDraws[#testDraws + 1] = { text = text, x = x, y = y } end
Panel.drawTextRight = Panel.drawText
Panel.drawTextCentre = Panel.drawText
Panel.drawRectBorder = Panel.drawRect
ISCollapsableWindow = Panel:derive("ISCollapsableWindow")
ISScrollingListBox = Panel:derive("ISScrollingListBox")
ISRichTextPanel = Panel:derive("ISRichTextPanel")
ISPanel = Panel
ISButton = Panel:derive("ISButton")
ISTextEntryBox = Panel:derive("ISTextEntryBox")
function ISTextEntryBox:new(text, x, y, width, height)
    return Panel.new(self, x, y, width, height, text)
end
ISEquippedItem = Panel:derive("ISEquippedItem")
function ISEquippedItem:prerender() self.vanillaRenders = (self.vanillaRenders or 0) + 1 end
function ISEquippedItem:removeFromUIManager() self.vanillaRemoved = true; testUI[self] = nil end

function Panel:setWidth(value) self.width = value end
function Panel:setHeight(value) self.height = value end
ISResizeWidget = Panel:derive("ISResizeWidget")
testCtrl = false
testShift = false
function isCtrlKeyDown() return testCtrl end
function isShiftKeyDown() return testShift end