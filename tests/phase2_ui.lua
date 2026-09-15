local shop = OneMoreHordeTraitShop
local player = testPlayers[1]
local window = OMHTS_ShopWindow:new(player)
window:initialise()
window:instantiate()
window:refresh()
check(#window.list.items == 10 and window.buy.enable, "window builds ten offers and enables affordable selected purchase")
check(window.description.paginated and string.find(window.description.text, "dextrous"), "selected trait details rendered")
window.list.selected = 2
window.list:setYScroll(-42)
window:refresh()
check(window.list.selected == 2 and window.list:getYScroll() == -42, "refresh preserves selection and scroll")
check(string.find(window.description.text, "fastreader") ~= nil, "changing selection updates trait details")
window:prerender()
check(window.buy:getBottom() < window.height and window.list:getBottom() < window.height, "shop controls fit at 1280x720")
window.list:doDrawItem(0, window.list.items[1], false)
for index = 1, #testDraws do
    check(testDraws[index].y >= 0 and testDraws[index].y < window.height, "shop text baseline remains in window")
end
window:onBuy()
window:refresh()
check(not window.buy.enable and shop.purchasePending(0), "click sends one purchase and disables button until response")
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
check(large.list.height > 0 and large.description.height > 0 and large.buy:getBottom() < large.height,
    "large font layout retains usable list details and purchase button")
testFontHeight = 18
local sidebar = ISEquippedItem:new(10, 10, 48, 400)
sidebar.chr = player
sidebar.healthBtn = ISButton:new(0, 100, 48, 36)
sidebar:addChild(sidebar.healthBtn)
testMouseX = 20
testMouseY = 120
sidebar:prerender()
local button = sidebar.omhTraitShopButton
check(sidebar.vanillaRenders == 1 and button.visible, "hover wrapper preserves vanilla and shows shop beside health")
check(button:getAbsoluteX() == sidebar.healthBtn:getAbsoluteX() + sidebar.healthBtn.width, "hover button touches health hitbox without a dead gap")
testMouseX = button:getAbsoluteX() + 4
sidebar:prerender()
check(button.visible, "pointer can move from health to shop without losing hover")
testMouseX = 500
sidebar:prerender()
check(not button.visible, "leaving both icons hides popup")
sidebar.traitsPopup = ISPanel:new(10, 110, 96, 36)
testMouseX = 95
sidebar:prerender()
check(button.visible and button.x == 106, "existing Trait Purchase System popup gets adjacent shop icon without overlap")
sidebar:setVisible(false)
sidebar:prerender()
check(not button.visible, "hidden sidebar cannot leave a visible detached button")
sidebar:removeFromUIManager()
check(sidebar.vanillaRemoved and not testUI[button] and sidebar.omhTraitShopButton == nil,
    "sidebar removal and size rebuild dispose custom button")
testOutput = tostring(testChecks) .. " Phase 2 assertions passed (transactions, transport, UI lifecycle and geometry)."
