testStage = "UI lifecycle and hover geometry"
function math.min(a, b) if a < b then return a end return b end
function math.max(a, b) if a > b then return a end return b end
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
    return { getFontHeight = function() return testFontHeight end }
end
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
function Panel:addChild(child) self.children[#self.children + 1] = child; child.parent = self end
function Panel:addToUIManager() testUI[self] = true end
function Panel:removeFromUIManager() testUI[self] = nil end
function Panel:bringToTop() end
function Panel:prerender() end
function Panel:getIsVisible() return self.visible end
function Panel:setVisible(value) self.visible = value end
function Panel:setEnable(value) self.enable = value end
function Panel:setTitle(value) self.title = value end
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
end
function Panel:drawRect(x, y, w, h) check(w >= 0 and h >= 0, "UI rectangle has nonnegative dimensions") end
function Panel:drawTextureScaled() end
function Panel:drawText(text, x, y) testDraws[#testDraws + 1] = { text = text, x = x, y = y } end
Panel.drawTextRight = Panel.drawText
ISCollapsableWindow = Panel:derive("ISCollapsableWindow")
ISScrollingListBox = Panel:derive("ISScrollingListBox")
ISRichTextPanel = Panel:derive("ISRichTextPanel")
ISPanel = Panel
ISButton = Panel:derive("ISButton")
ISEquippedItem = Panel:derive("ISEquippedItem")
function ISEquippedItem:prerender() self.vanillaRenders = (self.vanillaRenders or 0) + 1 end
function ISEquippedItem:removeFromUIManager() self.vanillaRemoved = true; testUI[self] = nil end
