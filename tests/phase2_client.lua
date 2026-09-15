testStage = "client purchase state and retry safety"
local shop = OneMoreHordeTraitShop
shop.acceptState(testPhase2Snapshot)
check(shop.getState(0).startingTokens == 5, "client accepts complete shop snapshot")
local copy = shop.getState(0)
copy.offers[1].price = 0
check(shop.getState(0).offers[1].price == 2, "UI cannot modify cached quote through nested table")
local malformed = nativeRoundTrip(testPhase2Snapshot)
malformed.offers[1].price = 0 / 0
shop.acceptState(malformed)
check(shop.getState(0).offers[1].price == 2, "NaN server quote rejected")
malformed = nativeRoundTrip(testPhase2Snapshot)
malformed.revision = malformed.revision + 1
malformed.tokens = 999
malformed.offers[2].id = malformed.offers[1].id
shop.acceptState(malformed)
check(shop.getState(0).tokens == 5, "duplicate dynamic offer IDs cannot enter cache")
malformed = nativeRoundTrip(testPhase2Snapshot)
malformed.revision = malformed.revision + 1
malformed.spentTokens = 0 / 0
shop.acceptState(malformed)
check(shop.getState(0).revision == testPhase2Snapshot.revision, "nonfinite spending breakdown rejected")
malformed = nativeRoundTrip(testPhase2Snapshot)
malformed.revision = malformed.revision + 1
for index = 11, 101 do malformed.offers[index] = { id = "test:large" .. index, price = 1, status = "available" } end
shop.acceptState(malformed)
check(shop.getState(0).revision == testPhase2Snapshot.revision, "oversized dynamic offer list rejected")
testPackets = {}
check(shop.purchase(testPlayers[1], "base:dextrous"), "UI sends selected authoritative quote")
check(shop.purchasePending(0) and not shop.purchase(testPlayers[1], "base:fastreader"), "pending request prevents a second UI spend")
check(#testPackets == 1 and testPackets[1].command == "purchase" and testPackets[1].args.price == 2, "purchase wire carries intent and expected revision only")
testClock = testClock + 5001
Events.OnTick.fire()
check(#testPackets == 2 and testPackets[2].command == "requestState", "lost purchase response triggers read retry not automatic repeat spend")
local accepted = nativeRoundTrip(testPhase2Snapshot)
accepted.revision = accepted.revision + 1
accepted.tokens = 3
accepted.offers[1].status = "owned"
accepted.result = "purchased"
accepted.requestRevision = testPhase2Snapshot.revision
shop.acceptState(accepted)
check(not shop.purchasePending(0) and shop.getState(0).tokens == 3, "updated authority state settles pending purchase")
shop.acceptState(testPhase2Snapshot)
check(shop.getState(0).tokens == 3, "stale response cannot undo successful purchase")
check(not shop.purchase(testPlayers[1], "base:dextrous"), "owned offer cannot be submitted again from UI")
check(shop.purchase(testPlayers[1], "base:fastreader"), "next available offer can be purchased")
testClock = testClock + 11000
Events.OnTick.fire()
check(not shop.purchasePending(0), "unanswered request eventually releases UI without spending again")
Events.OnDisconnect.fire()
check(shop.getState(0) == nil and not shop.purchasePending(0), "disconnect clears shop state and pending intent")
shop.acceptState(testPhase2Snapshot)
testOutput = tostring(testChecks) .. " Phase 2 assertions passed."
