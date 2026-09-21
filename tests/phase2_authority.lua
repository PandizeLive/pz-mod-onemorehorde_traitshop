testStage = "shop authority and authenticated routing"
local authority = OneMoreHordeTraitShop.Authority
testTables = {}
testPlayers = {}
testPackets = {}
testClock = 100000
Events.OnInitGlobalModData.fire()
local alice = player("Alice", 0, 50, 0)
local bob = player("Bob", 0, 51, 0)
local a = authority.getState(alice)
local b = authority.getState(bob)
check(a.tokens == 5 and b.tokens == 5 and a.lifeId ~= b.lifeId, "server creates independent starting wallets")
Events.OnClientCommand.fire("OMHTraitShop", "purchase", alice,
    { traitId = "base:dextrous", lifeId = b.lifeId, revision = b.revision, price = 2 })
check(authority.getState(alice).tokens == 5 and authority.getState(bob).tokens == 5, "foreign life ID cannot spend either wallet")
testClock = testClock + 1000
Events.OnClientCommand.fire("OMHTraitShop", "purchase", alice,
    { traitId = "base:dextrous", lifeId = a.lifeId, revision = a.revision, price = 2 })
check(authority.getState(alice).tokens == 3 and authority.getState(bob).tokens == 5, "command debits only authenticated sender")
local response = testPackets[#testPackets]
check(response.player == alice and response.args.result == "purchased", "purchase receipt routes only to buyer")
check(testTables.OMHTraitShop_State_v1.accounts["user:5:Alice:0"].life.prestigeUnofficial == false,
    "Starting-token purchase does not manufacture unofficial XP provenance")
testClock = testClock + 1000
local count = #testPackets
Events.OnClientCommand.fire("OMHTraitShop", "purchase", alice,
    { traitId = "base:dextrous", lifeId = a.lifeId, revision = a.revision, price = 2 })
check(authority.getState(alice).tokens == 3 and #testPackets == count + 1, "replay returns refreshed state without charging")
count = #testPackets
Events.OnClientCommand.fire("OMHTraitShop", "purchase", alice,
    { traitId = "base:dextrous", lifeId = a.lifeId, revision = a.revision, price = 2 })
check(#testPackets == count + 1 and testPackets[#testPackets].args.result == "busy", "rapid second purchase gets a bounded retry message")
count = #testPackets
Events.OnClientCommand.fire("OMHTraitShop", "purchase", alice,
    { traitId = "base:dextrous", lifeId = a.lifeId, revision = a.revision, price = 2 })
check(#testPackets == count, "purchase command flood throttled")
testTables = nativeRoundTrip(testTables)
Events.OnInitGlobalModData.fire()
local reconnected = player("Alice", 0, 50, 0.1)
local restored = authority.getState(reconnected)
check(restored.tokens == 3 and reconnected:hasTrait("base:dextrous"), "authority reconnect repairs native traits from saved purchase receipt")
reconnected.dead = true
Events.OnCharacterDeath.fire(reconnected)
local replacement = player("Alice", 0, 52, 0)
check(authority.getState(replacement).tokens == 5 and not replacement:hasTrait("base:dextrous"), "death grants only replacement creation points")
testPhase2Snapshot = authority.getState(replacement)
testPlayers = { replacement }
testTransportPackets[#testTransportPackets + 1] = testPhase2Snapshot
testSide = "client"
