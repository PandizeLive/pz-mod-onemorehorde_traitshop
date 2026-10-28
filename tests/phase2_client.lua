testStage = "cart client protocol"
local shop = OneMoreHordeTraitShop
local Catalog = require("OMHTS_Catalog")
shop.acceptState(testPhase2Snapshot)
local function quote(snapshot, id)
    for i=1,#snapshot.offers do if snapshot.offers[i].id == id then return snapshot.offers[i] end end
end
check(shop.getState(0).startingTokens == 5, "client accepts v3 snapshot")
local copy = shop.getState(0)
quote(copy, "base:dextrous").price = 0
check(quote(shop.getState(0), "base:dextrous").price == 2, "nested quotes detached")
local bad = nativeRoundTrip(testPhase2Snapshot)
bad.revision = bad.revision + 1
bad.tokens = 999
bad.offers[2].id = bad.offers[1].id
shop.acceptState(bad)
check(shop.getState(0).tokens == 5, "duplicate quote IDs rejected")
bad = nativeRoundTrip(testPhase2Snapshot)
bad.effects.perks.Cooking = {xp=0/0,boost=2,beforeBoost=1}
shop.acceptState(bad)
check(shop.getState(0).effects.perks.Cooking == nil, "malformed effect targets rejected")
bad = nativeRoundTrip(testPhase2Snapshot)
bad.revision = bad.revision + 1
for i=#bad.offers+1,Catalog.MAX_PURCHASE_TRAITS+1 do bad.offers[i]={id="large:"..i,price=1,status="available"} end
shop.acceptState(bad)
check(shop.getState(0).revision == testPhase2Snapshot.revision, "oversized offer list rejected")
testPackets = {}
check(shop.purchase(testPlayers[1], {["base:dextrous"]=true,["base:fastreader"]=true}), "client submits one cart")
check(#testPackets == 1 and #testPackets[1].args.items == 2 and testPackets[1].args.tokens == nil, "wire includes intentions and prices only")
check(not shop.purchase(testPlayers[1], "base:brave"), "pending cart blocks duplicate submit")
testClock = testClock + 5001
Events.OnTick.fire()
check(testPackets[#testPackets].command == "requestState", "lost response triggers read only")
local accepted = nativeRoundTrip(testPhase2Snapshot)
accepted.revision = accepted.revision + 1
accepted.tokens = 1
accepted.result = "purchased"
accepted.requestRevision = testPhase2Snapshot.revision
quote(accepted,"base:dextrous").status = "owned"
quote(accepted,"base:fastreader").status = "owned"
shop.acceptState(accepted)
check(not shop.purchasePending(0) and shop.getState(0).tokens == 1, "accepted cart settles pending")
shop.acceptState(testPhase2Snapshot)
check(shop.getState(0).tokens == 1, "old response cannot rewind")
check(not shop.purchase(testPlayers[1], "base:dextrous"), "owned trait cannot be submitted")
Events.OnDisconnect.fire()
check(shop.getState(0) == nil and not shop.purchasePending(0), "disconnect clears cache and pending cart")
shop.acceptState(testPhase2Snapshot)

shop.requestState(0,testPlayers[1])
local nonce = testPackets[#testPackets].args.nonce
local verified = nativeRoundTrip(testPhase2Snapshot)
verified.nonce = nonce
verified.effects.perks.Cooking = {xp=100,boost=1,beforeBoost=0}
shop.acceptState(verified)
check(testPlayers[1].skillXP.Cooking == 100 and testPlayers[1].boosts.Cooking == 1,
    "owner applies server skill targets only after current-character handshake")
shop.acceptState(verified)
check(testPlayers[1].skillXP.Cooking == 100, "duplicate client effect snapshots cannot stack bonuses")
local oldPlayer = testPlayers[1]
local replacement = player("Alice",0,99,0)
testPlayers = {replacement}
shop.requestState(0,replacement)
shop.acceptState(verified)
check(replacement.skillXP.Cooking == nil and shop.getState(0) == nil,
    "late old-character handshake cannot apply traits or skills to replacement")
local unsolicited = nativeRoundTrip(verified)
unsolicited.nonce = nil
shop.acceptState(unsolicited)
check(replacement.skillXP.Cooking == nil, "unsolicited old-life snapshot never authorizes effects on new actor")
Events.OnDisconnect.fire()
testPlayers = {oldPlayer}
shop.acceptState(testPhase2Snapshot)
local maximum = nativeRoundTrip(testPhase2Snapshot)
maximum.offers = {}
maximum.effects.perks = {}
for i=1,Catalog.MAX_PURCHASE_TRAITS do
    local id = string.rep("x",125) .. tostring(i)
    maximum.offers[i] = {id=id,price=1000000000,status="removal_disabled"}
end
for i=1,64 do
    maximum.effects.perks[string.rep("x",125)..tostring(i)] = {xp=1000000000,boost=10,beforeBoost=0}
end
testTransportPackets[#testTransportPackets+1] = maximum
check(require("OMHTS_Effects").valid(maximum.effects), "maximum supported effect payload is valid")