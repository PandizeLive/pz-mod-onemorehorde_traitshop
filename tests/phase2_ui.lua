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
testCtrl = true
window:onSelect(reader)
check(window.cartCount == 3 and window.cartTotal == 8, "ctrl adds individual trait")
window:onSelect(reader)
check(window.cartCount == 2, "ctrl toggles selected trait off")
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
local first = window.list.items[1].item
local third = window.list.items[3].item
window:onSelect(first)
testShift = true
window:onSelect(third)
check(window.cartCount == 3, "shift selects contiguous visible range")
testShift = false
window:onReset()
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
testOutput = tostring(testChecks) .. " Phase 2 / v0.4.0 assertions passed."

testFontHeight = 28
testScreenWidth = 1024
testScreenHeight = 768
local large = OMHTS_ShopWindow:new(actor)
large:initialise()
large:instantiate()
check(large.list.height >= 100 and large.negative.height >= 80 and large.noticeY + large.fontHeight < large.buy.y,
    "large font three-panel layout remains usable at 1024 by 768")
large:close()
testOutput = tostring(testChecks) .. " Phase 2 / v0.4.0 assertions passed."