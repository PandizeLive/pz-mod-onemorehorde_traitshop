testStage = "three-panel UI, selection transfer and hover activation"
local shop = OneMoreHordeTraitShop
local player = testPlayers[1]
local window = OMHTS_ShopWindow:new(player)
window:initialise()
window:instantiate()
window:refresh()
check(#window.list.items > 10 and not window.buy.enable, "full positive registry shown; no purchase preselected")
check(window.positive and window.negative and not window.remove.enable, "owned positive and negative panels exist; removal disabled")
window:onSelect(window.rowsById["base:dextrous"])
check(window.buy.enable and string.find(window.description.text, "dextrous"), "explicit selection enables affordable purchase and compact details")
window.list:setYScroll(-10)
window:refresh()
check(window.selectedId == "base:dextrous" and window.list:getYScroll() == -10, "unchanged refresh preserves selection identity and scroll")
window.search:setText("fastreader")
window:refresh()
check(#window.list.items == 1 and window.selectedId == nil and not window.buy.enable, "search clears hidden selection instead of buying another row")
window:onSelect(window.list.items[1].item)
window:onFilter()
window:refresh()
check(window.filterMode == 2 and #window.list.items == 1, "available filter keeps an affordable searched result")
window:onFilter()
window:refresh()
check(#window.list.items == 0 and not window.buy.enable, "unavailable filter leaves safe empty catalog")
window:onFilter()
window.search:setText("")
window:refresh()
window:onSelect(window.rowsById["base:dextrous"])
window:prerender()
check(window.description:getBottom() < window.height and window.negative:getBottom() == window.list:getBottom(), "three panels and compact footer fit at 1280x720")
check(window.description.height < window.height / 6 and window.positive.width == window.list.width, "description uses shallow footer rather than half the window")
check(window.tokens.width == window.prestige.width and window.tokens.font == window.prestige.font, "Tokens and Prestige receive equal emphasis")
check(string.find(window.tokens.tooltip, "Spent on trait purchases") ~= nil
    and string.find(window.tokens.tooltip, "No prestige was included") ~= nil, "Token sources and deferred prestige are explained in tooltip")
check(not string.find(window.prestige.title, "retained") and string.find(window.prestige.tooltip, "Retained") ~= nil,
    "Prestige displays one total with separate tooltip components")
window.progress.percent = 50
window.progress:prerender()
check(window.progress.title == "50%", "gold progress bar labels its clamped percentage")
window.progress.percent = 200
window.progress:prerender()
check(window.progress.title == "100%", "progress fill cannot overflow past 100 percent")
window.progress.percent = 0
window.list:doDrawItem(0, window.list.items[1], false)
window:onBuy()
window:refresh()
check(not window.buy.enable and shop.purchasePending(0), "click sends one purchase and disables button until response")
local accepted = nativeRoundTrip(testPhase2Snapshot)
accepted.revision = accepted.revision + 1
accepted.tokens = 3
accepted.spentTokens = 2
accepted.offers[1].status = "owned"
accepted.result = "purchased"
shop.acceptState(accepted)
window:refresh()
check(window.rowsById["base:dextrous"].group == "positive" and #window.positive.items == 1,
    "successful server purchase transfers row to owned panel before native sync arrives")
check(window.selectedId == "base:dextrous" and not window.buy.enable, "transferred selection stays on purchased trait and cannot buy twice")
player.traits["base:allthumbs"] = true
window:refresh()
check(#window.negative.items == 1 and window.rowsById["base:allthumbs"].owned, "native negative traits appear without requiring a catalog offer")
window:onSelect(window.rowsById["base:allthumbs"])
window.negative:doDrawItem(0, window.negative.items[1], false)
check(not window.buy.enable and not window.remove.enable, "negative selection never enables purchase or unimplemented removal")
player.traits = {}
window.list.tooltipUI = ISPanel:new(0, 0, 50, 50)
window.list.tooltipUI:addToUIManager()
window:close()
check(not testUI[window.list.tooltipUI], "closing shop removes detached row tooltip")
Events.OnDisconnect.fire()
shop.acceptState(testPhase2Snapshot)
shop.toggleWindow(player)
local managed = nil
for element in pairs(testUI) do
    if element.Type == "OMHTS_ShopWindow" then managed = element end
end
check(managed ~= nil, "toggle adds shop to UI manager")
shop.toggleWindow(player)
check(not testUI[managed], "toggle close removes window from UI manager")
shop.toggleWindow(player)
check(testUI[managed], "toggle reuses window without duplicate controls")
Events.OnDisconnect.fire()
check(not testUI[managed], "disconnect removes window instead of leaving hidden orphan")
testFontHeight = 28
testScreenWidth = 1024
testScreenHeight = 768
local large = OMHTS_ShopWindow:new(player)
large:initialise()
large:instantiate()
check(large.list.height >= 120 and large.negative.height >= 90 and large.description:getBottom() < large.height,
    "large font layout retains usable three-panel lists and footer")
testFontHeight = 18
local sidebar = ISEquippedItem:new(10, 10, 48, 400)
sidebar.chr = player
sidebar.healthBtn = ISButton:new(0, 100, 48, 36)
sidebar:addChild(sidebar.healthBtn)
testMouseX = 70
testMouseY = 120
sidebar:prerender()
local button = sidebar.omhTraitShopButton
check(not button.visible, "hovering hidden shop coordinates cannot open popup")
testMouseX = 20
sidebar:prerender()
check(sidebar.vanillaRenders == 2 and button.visible, "health hover preserves vanilla and opens shop popup")
check(button:getAbsoluteX() == sidebar.healthBtn:getAbsoluteX() + sidebar.healthBtn.width, "hover button touches health hitbox without a dead gap")
testMouseX = button:getAbsoluteX() + 4
sidebar:prerender()
check(button.visible, "pointer can move from health to shop without losing hover")
testMouseX = 500
button.tooltipUI = ISPanel:new(0, 0, 50, 50)
button.tooltipUI:addToUIManager()
sidebar:prerender()
check(not button.visible, "leaving both icons hides popup")
check(not testUI[button.tooltipUI], "hiding shop popup also removes its detached tooltip")
testMouseX = button:getAbsoluteX() + 4
sidebar:prerender()
check(not button.visible, "returning directly to hidden button does not reopen it")
sidebar.traitsPopup = ISPanel:new(10, 110, 96, 36)
testMouseX = 95
sidebar:prerender()
check(not button.visible, "other mod popup cannot activate shop before health hover")
testMouseX = 20
sidebar.healthBtn.isMouseOver = function() return false end
sidebar:prerender()
check(button.visible, "visible TPS health overlay can open shop even when it occludes native health button")
testMouseX = 95
sidebar:prerender()
check(button.visible and button.x == 106, "open shop remains reachable across visible Trait Purchase System popup")
sidebar:setVisible(false)
sidebar:prerender()
check(not button.visible, "hidden sidebar cannot leave a visible detached button")
sidebar:removeFromUIManager()
check(sidebar.vanillaRemoved and not testUI[button] and sidebar.omhTraitShopButton == nil,
    "sidebar removal and size rebuild dispose custom button")
testOutput = tostring(testChecks) .. " Phase 2 assertions passed (transactions, registry integration, transport, UI and hover)."
