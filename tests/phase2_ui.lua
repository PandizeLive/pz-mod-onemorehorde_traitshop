testStage = "resizable cart UI"
local shop = OneMoreHordeTraitShop
local actor = testPlayers[1]
testSide = "singleplayer"
testTables = {}
Events.OnInitGlobalModData.fire()
actor.traits = {["base:allthumbs"]=true,["base:overweight"]=true,["base:burglar"]=true}
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
check(#window.other.items == 2 and #window.positive.items == 0, "owned zero-cost traits occupy neutral middle panel")
window:onSelect(window.other.items[1].item)
check(window.cartCount == 0, "Other Traits click cannot add to cart")
window.other:onMouseDown(2,2)
testCtrl = true
window:onKeyPress(Keyboard.KEY_A)
check(window.cartCount == 0 and not window:isKeyConsumed(Keyboard.KEY_A), "Other Traits ignore select-all")
testCtrl = false
local originalGetState = shop.getState
shop.getState = function(slot)
    local snapshot = originalGetState(slot)
    snapshot.level = 19
    snapshot.xp = 1000
    snapshot.pendingPrestige = 2
    return snapshot
end
window:refresh()
check(window.progress.title == "1000 / 2000" and window.progress.requiredXP == 2000,
    "XP requirement follows level twenty curve")
check(window.prestige.title == "Prestige: 2", "unclaimed prestige remains visible after death")
shop.getState = originalGetState
window:refresh()
check(string.find(window.progress.tooltip, "Zombie kills", 1, true)
    and string.find(window.progress.tooltip, "Nights survived", 1, true)
    and not string.find(window.progress.tooltip, "Days survived", 1, true),
    "XP tooltip shows active reward names and excludes zero-rate days")
check(window.reset.x == 12 and window.closeButton.x > window.reset.x + window.reset.width
    and window.buy.x == window.width - 12 - window.buy.width
    and window.closeButton.x + window.closeButton.width + 8 == window.buy.x
    and window.reset.y == window.buy.y and window.closeButton.y == window.buy.y,
    "Reset anchors lower-left and Close then Purchase form compact lower-right group")
check(window.closeButton.backgroundColor.r == 0.55 and window.closeButton.backgroundColor.g == 0.08
    and window.reset.backgroundColor.r == 0 and window.reset.textColor.r == 0.95
    and window.reset.borderColor.r == 0.95, "Close and Reset use Horde Night difficulty colors")
check(not window.buy.enable and window.buy.backgroundColor.r == window.buy.backgroundColor.g,
    "empty cart Purchase stays disabled and neutral")
check(window.tokens.textColor == window.prestige.textColor, "currencies have equal visual weight")
check(window.description == nil and window.remove == nil and window.buy.title == "Purchase", "one checkout and no duplicate description footer")
check(window.buy.tooltip == nil and window.reset.tooltip == nil and window.closeButton.tooltip == nil, "actions have no tooltips")
local dex = window.allRows["base:dextrous"]
local reader = window.allRows["base:fastreader"]
window:onSelect(dex)
check(window.cartCount == 1 and not window.cartValid and window.cartReason == "conflict", "conflicting addition visibly blocks checkout")
window:onSelect(window.allRows["base:allthumbs"])
check(window.cartCount == 2 and window.cartValid and window.cartTotal == 6, "negative selection preserves positive cart and resolves conflict")
check(window.buy.enable and window.buy.backgroundColor.g == 0.45 and window.buy.backgroundColorMouseOver.g == 0.7,
    "valid Purchase uses Horde Night confirm green")
for refresh = 1, 12 do
    window:updateCart()
    check(window.buy.enable and window.buy.backgroundColor.r == 0.08 and window.buy.backgroundColor.g == 0.45
        and window.buy.borderColor.g == 0.95, "native setEnable preserves green across valid refresh " .. refresh)
end
local wallet = window.state.tokens
window.state.tokens = window.cartTotal
window:updateCart()
check(window.cartValid and window.buy.enable and window.buy.backgroundColor.g == 0.45,
    "exact-balance cart stays enabled green")
window.state.tokens = window.cartTotal - 1
window:updateCart()
check(not window.cartValid and not window.buy.enable and window.buy.backgroundColor.g == 0.07,
    "insufficient balance becomes disabled neutral")
window.state.tokens = wallet
window:updateCart()
check(window.buy.enable and window.buy.backgroundColor.g == 0.45, "valid cart restores green after native disable")
window.reset:setEnable(false)
check(window.closeButton.borderColor.g == 0.35, "disabling Reset cannot mutate Close border")
window.reset:setEnable(true)
check(window.allRows["base:dextrous"].previewStatus == "available", "queued removal immediately clears conflict shading")
window:onSelect(window.allRows["base:allthumbs"])
check(window.allRows["base:dextrous"].previewStatus == "conflict" and not window.cartValid,
    "toggling removal off restores conflict")
check(not window.buy.enable and window.buy.backgroundColor.g == 0.07, "invalidated cart removes enabled green styling")
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
check(window.list.height > 0 and window.positive.height >= window.positive.itemheight
    and window.other.height >= window.other.itemheight and window.negative.height >= window.negative.itemheight
    and window.positive:getBottom() < window.otherHeadingY and window.other:getBottom() < window.negativeHeadingY
    and window.list:getBottom() < window.receipt.y and window.noticeY + window.fontHeight < window.buy.y,
    "minimum dimensions keep panels receipt notices and buttons separated")
local width, height = window.width, window.height
check(window.reset.x == 12 and window.buy.x + window.buy.width == window.width - 12
    and window.closeButton.x > window.reset.x + window.reset.width, "minimum width preserves both footer groups")
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
testOutput = tostring(testChecks) .. " Phase 2 / v0.5.0 assertions passed."

testFontHeight = 28
testScreenWidth = 1024
testScreenHeight = 768
local large = OMHTS_ShopWindow:new(actor)
large:initialise()
large:instantiate()
check(large.list.height >= 100 and large.negative.height >= large.negative.itemheight
    and large.other.height >= large.other.itemheight and large.positive.height >= large.positive.itemheight
    and large.noticeY + large.fontHeight < large.buy.y,
    "large font layout retains at least a full row in each owned list at 1024 by 768")
large:close()

testFontHeight = window.fontHeight
local probe = ISScrollingListBox:new(0, 0, 250, 160)
probe.parent = window
probe.itemheight = 28
probe.doDrawItem = window.list.doDrawItem
local rowGroups = { "catalog", "positive", "other", "negative", "receipt" }
local heights = { 420, 112, 56 }
for groupIndex = 1, #rowGroups do
    probe.group = rowGroups[groupIndex]
    for sizeIndex = 1, #heights do
        probe.height = heights[sizeIndex]
        local offsets = { 0, -560, probe.height - 49 * probe.itemheight }
        for offsetIndex = 1, #offsets do
            probe:setYScroll(offsets[offsetIndex])
            testDraws = {}
            local expected = {}
            local y = 0
            for index = 1, 49 do
                local row = { id = "test:row" .. index, name = "Row " .. index,
                    group = "catalog", owned = false, previewStatus = "available", price = 1,
                    definition = reader.definition }
                if probe.group == "positive" or probe.group == "negative" or probe.group == "other" then
                    row.group = probe.group
                    row.owned = true
                end
                local label = row.name
                if probe.group == "receipt" then label = getText("UI_OMHTS_ReceiptAdd", label) end
                local screenY = y + probe:getYScroll()
                if screenY + probe.itemheight > 0 and screenY < probe.height then expected[label] = true end
                y = probe:doDrawItem(y, { item = row }, false)
            end
            for index = 1, #testDraws do expected[testDraws[index].text] = nil end
            local missing = false
            for _ in pairs(expected) do missing = true end
            check(not missing and y == 49 * probe.itemheight,
                "all viewport rows render at scroll offset " .. offsetIndex .. " size " .. sizeIndex .. " group " .. probe.group)
        end
    end
end
testOutput = tostring(testChecks) .. " Phase 2 / v0.5.0 assertions passed."
