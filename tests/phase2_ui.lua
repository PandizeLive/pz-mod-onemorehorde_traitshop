testStage = "resizable cart UI"
local shop = OneMoreHordeTraitShop
local actor = testPlayers[1]
testSide = "singleplayer"
testTables = {}
Events.OnInitGlobalModData.fire()
actor.traits = {["base:allthumbs"]=true}
testOptions["OMHTraitShop.AllowNegativeRemoval"] = true
shop.requestState(0,actor)
shop.toggleWindow(actor)
local window
for item in pairs(testUI) do if item.Type == "OMHTS_ShopWindow" then window = item end end
check(window ~= nil and window.moveWithMouse and window.pin == nil, "shop is movable OMH panel without pinning")
window:prerender()
local brand, subtitle
for i = 1, #testDraws do
    if testDraws[i].text == "One More Horde" then brand = testDraws[i] end
    if testDraws[i].text == "Trait Shop" then subtitle = testDraws[i] end
end
check(brand and brand.font == UIFont.Small and brand.r == 0.85
    and subtitle and subtitle.font == UIFont.Large and subtitle.r == 0.95 and subtitle.g == 0.75,
    "header matches full leaderboard fonts and colors")
check(window.progress.title == "0 / 100", "XP label uses numeric requirement and no percent formatter")
check(window.tokens.textColor == window.prestige.textColor, "currencies have equal visual weight")
check(window.description == nil and window.remove == nil and window.buy.title == "Purchase", "one checkout and no duplicate description footer")
check(window.buy.tooltip == nil and window.reset.tooltip == nil and window.closeButton.tooltip == nil, "actions have no tooltips")
local dex = window.allRows["base:dextrous"]
local reader = window.allRows["base:fastreader"]
window:onSelect(dex)
check(window.cartCount == 1 and not window.cartValid and window.cartReason == "conflict", "conflicting addition visibly blocks checkout")
window:onSelect(window.allRows["base:allthumbs"])
check(window.cartCount == 2 and window.cartValid and window.cartTotal == 6, "negative selection preserves positive cart and resolves conflict")
check(window.allRows["base:dextrous"].previewStatus == "available", "queued removal immediately clears conflict shading")
window:onSelect(window.allRows["base:allthumbs"])
check(window.allRows["base:dextrous"].previewStatus == "conflict" and not window.cartValid,
    "toggling removal off restores conflict")
window:onSelect(window.allRows["base:allthumbs"])
window:onSelect(reader)
check(window.cartCount == 3 and window.cartTotal == 8, "plain click accumulates traits")
window:onSelect(reader)
check(window.cartCount == 2, "plain click toggles selected trait off")
testCtrl = false
window.search:setText("does not match")
window:refresh()
check(#window.list.items == 0 and window.cartCount == 2 and window.cartTotal == 6, "search cannot hide or drop pending receipt items")
window.search:setText("")
window:refresh()
window:onReceipt(dex)
check(window.cartCount == 1 and window.cart["base:allthumbs"], "receipt click removes one choice")
window:onReset()
check(window.cartCount == 0 and actor:hasTrait("base:allthumbs"), "Reset never changes character traits")
window:onSelect(window.allRows["base:allthumbs"])
window.filterMode = 2
window:refresh()
local first = window.list.items[1].item
local third = window.list.items[3].item
window:onSelect(first)
testShift = true
window:onSelect(third)
check(window.cartCount == 4, "shift adds eligible range and preserves the other list")
testShift = false
window:onReset()
window.filterMode = 1
window.search:setText("fastreader")
window:refresh()
window.list:onMouseDown(2,2)
testCtrl = true
window:onKeyPress(Keyboard.KEY_A)
check(window.cartCount == 1 and window.cart["base:fastreader"], "Ctrl+A respects active filtered list")
window.search.focused = true
window:onReset()
window:onKeyPress(Keyboard.KEY_A)
check(window.cartCount == 0 and not window:isKeyConsumed(Keyboard.KEY_A), "search focus preserves Ctrl+A text selection")
window.positive:onMouseDown(2,2)
window:onKeyPress(Keyboard.KEY_A)
check(window.cartCount == 0 and not window:isKeyConsumed(Keyboard.KEY_A), "owned positives never become bulk purchases")
window.negative:onMouseDown(2,2)
window:onKeyPress(Keyboard.KEY_A)
check(window.cartCount == 1 and window.cart["base:allthumbs"] and not window.search:isFocused(),
    "negative list click transfers focus and Ctrl+A selects only removals")
window:onReset()
testOptions["OMHTraitShop.AllowNegativeRemoval"] = false
shop.requestState(0,actor)
window:refresh()
window:onKeyPress(Keyboard.KEY_A)
check(window.cartCount == 0, "Ctrl+A skips disabled removal")
testOptions["OMHTraitShop.AllowNegativeRemoval"] = true
shop.requestState(0,actor)
window.search:setText("")
window:refresh()
window.activeList = window.list
window:onKeyPress(Keyboard.KEY_A)
check(not window.cart["base:dextrous"] and window.cart["base:fastreader"], "select all skips unresolved conflicts")
window:onReset()
window:onSelect(window.allRows["base:allthumbs"])
window.filterMode = 2
window:refresh()
local foundDex = false
for i = 1, #window.list.items do
    if window.list.items[i].item.id == "base:dextrous" then foundDex = true end
end
check(foundDex, "available filter includes positives unlocked by cart removals")
window:onReceipt(window.allRows["base:allthumbs"])
foundDex = false
for i = 1, #window.list.items do
    if window.list.items[i].item.id == "base:dextrous" then foundDex = true end
end
check(not foundDex, "receipt click immediately restores filtered availability")
window.filterMode = 1
window:refresh()
testCtrl = false
window:onSelect(dex)
window:onSelect(window.allRows["base:allthumbs"])
local before = window.state.tokens
window:onBuy()
window:refresh()
check(window.cartCount == 0 and actor:hasTrait("base:dextrous") and not actor:hasTrait("base:allthumbs")
    and window.state.tokens == before - 6, "single Purchase applies mixed cart and clears receipt")
window:Resize(window.minimumWidth,window.minimumHeight)
check(window.list.height > 0 and window.positive.height > 0 and window.negative.height > 0
    and window.list:getBottom() < window.receipt.y and window.noticeY + window.fontHeight < window.buy.y,
    "minimum dimensions keep panels receipt notices and buttons separated")
local width, height = window.width, window.height
local startX, startY = window.x, window.y
local grip = window.resizeWidget
testMouseX = grip:getAbsoluteX() + 6
testMouseY = grip:getAbsoluteY() + 6
grip:onMouseDown(6,6)
testMouseX = testMouseX + 40
testMouseY = testMouseY + 30
for frame = 1, 12 do
    local oldWidth, oldHeight = window.width, window.height
    grip:onMouseMove(40,30)
    -- UIElement.onResize applies deferred anchor deltas after Lua layout.
    if not grip.anchorLeft and grip.anchorRight then grip:setX(grip.x + window.width - oldWidth) end
    if not grip.anchorTop and grip.anchorBottom then grip:setY(grip.y + window.height - oldHeight) end
    check(window.width == width + 40 and window.height == height + 30
        and window.x == startX and window.y == startY
        and grip.x == window.width - 12 and grip.y == window.height - 12,
        "native resize grip stays stable across deferred anchor frame " .. frame)
end
testMouseX = testMouseX - 60
testMouseY = testMouseY - 60
grip:onMouseMoveOutside(-60,-60)
check(window.width == window.minimumWidth and window.height == window.minimumHeight,
    "native outside resize clamps dimensions")
grip:onMouseUpOutside(0,0)
check(not grip.resizing and not grip.capture, "resize releases capture outside panel")
window:onMouseDown(20,window.height - 20)
check(not window.moving, "content and resize area cannot start window drag")
width, height = window.width, window.height
window:onSelect(window.allRows["base:fastreader"])
local tooltip = ISPanel:new(0,0,20,20)
tooltip:addToUIManager()
window.tokens.tooltipUI = tooltip
window:close()
check(not testUI[tooltip] and not window:getIsVisible() and window.cartCount >= 0, "close removes tooltip UI")
shop.toggleWindow(actor)
window:refresh()
check(window.width == width and window.height == height and window.cartCount == 0, "reopen keeps geometry and discards unpaid cart")
window:close()

local sidebar = ISEquippedItem:new(0,0,100,200)
sidebar.chr = actor
sidebar.healthBtn = ISButton:new(10,50,40,40)
sidebar:addChild(sidebar.healthBtn)
sidebar:prerender()
local button = sidebar.omhTraitShopButton
check(button ~= nil and not button:getIsVisible(), "health shop icon starts hidden")
testMouseX = button:getAbsoluteX()+2
testMouseY = button:getAbsoluteY()+2
sidebar:prerender()
check(not button:getIsVisible(), "hidden button area cannot reveal itself")
testMouseX = sidebar.healthBtn:getAbsoluteX()+10
testMouseY = sidebar.healthBtn:getAbsoluteY()+10
sidebar:prerender()
check(button:getIsVisible(), "health hover reveals shop")
testMouseX = button:getAbsoluteX()+2
testMouseY = button:getAbsoluteY()+2
sidebar:prerender()
check(button:getIsVisible(), "visible icon remains open under pointer")
testMouseX = 1000
testMouseY = 1000
sidebar:prerender()
check(not button:getIsVisible(), "leaving health and icon hides icon")
sidebar.traitsPopup = ISPanel:new(10,50,80,40)
testMouseX = 20
testMouseY = 60
sidebar.healthBtn.isMouseOver = function() return false end
sidebar:prerender()
check(button:getIsVisible(), "TPS popup covering health can still reveal shop")
testMouseX = 70
sidebar:prerender()
check(button:getIsVisible(), "visible TPS bridge keeps shop reachable")
sidebar:removeFromUIManager()
Events.OnDisconnect.fire()
testOutput = tostring(testChecks) .. " Phase 2 / v0.4.1 assertions passed."

testFontHeight = 28
testScreenWidth = 1024
testScreenHeight = 768
local large = OMHTS_ShopWindow:new(actor)
large:initialise()
large:instantiate()
check(large.list.height >= 100 and large.negative.height >= 80 and large.noticeY + large.fontHeight < large.buy.y,
    "large font three-panel layout remains usable at 1024 by 768")
large:close()
testOutput = tostring(testChecks) .. " Phase 2 / v0.4.1 assertions passed."
