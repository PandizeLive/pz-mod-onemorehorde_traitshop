testStage = "client cache and wire validation"
local shop = OneMoreHordeTraitShop
shop.acceptState(testSavedSnapshot)
check(shop.getState(0).tokens == 7, "client receives valid snapshot")
local copy = shop.getState(0)
copy.tokens = 999
check(shop.getState(0).tokens == 7, "UI gets detached snapshot")
copy = nativeRoundTrip(testSavedSnapshot)
copy.tokens = 12
copy.revision = copy.revision + 1
shop.acceptState(copy)
shop.acceptState(testSavedSnapshot)
check(shop.getState(0).tokens == 12, "out-of-order snapshot cannot rewind cache")
copy.tokens = -1
shop.acceptState(copy)
check(shop.getState(0).tokens == 12, "malformed snapshot rejected")
Events.OnDisconnect.fire()
check(shop.getState(0) == nil, "disconnect clears prior server cache")
testPackets = {}
Events.OnCreatePlayer.fire(0, testPlayers[1])
check(#testPackets == 1 and testPackets[1].command == "requestState", "client requests state only")
testClock = testClock + 5001
Events.OnTick.fire()
check(#testPackets == 2, "lost initial response retried")
shop.acceptState(testSavedSnapshot)
testClock = testClock + 5001
Events.OnTick.fire()
check(#testPackets == 2, "successful response stops retries")
testOutput = tostring(testChecks) .. " Phase 1 assertions passed, including native B42 table serialization."
testTransportPackets = { testSavedSnapshot }
