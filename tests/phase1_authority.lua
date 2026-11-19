testStage = "authority and lifecycle events"
local authority = OneMoreHordeTraitShop.Authority
Events.OnInitGlobalModData.fire()
local alice = player("Alice", 0, 21, 3)
local bob = player("Bob", 0, 22, 3)
testPlayers = { alice, bob }
Events.OnTick.fire()
local initial = authority.getState(alice)
check(initial.lifeId ~= authority.getState(bob).lifeId, "account identities isolated")
check(authority.updateState(alice, initial.lifeId, initial.revision, { tokens = 42, xp = 8.5, level = 4 }), "server mutation commits")
alice.modData = { OMHTraitShop_State_v1 = { tokens = 1000000 } }
check(authority.getState(alice).tokens == 42, "player modData replacement cannot clobber wallet")
local count = #testPackets
Events.OnClientCommand.fire("OMHTraitShop", "setTokens", alice, { tokens = 900 })
Events.OnClientCommand.fire("OMHTraitShop", "requestState", alice, { player = "Bob", tokens = 900 })
Events.OnClientCommand.fire("foreign", "requestState", alice, {})
Events.OnClientCommand.fire("OMHTraitShop", "requestState", alice, nil)
check(#testPackets == count and authority.getState(alice).tokens == 42, "forged commands and malformed reads cannot mutate or route another wallet")
Events.OnClientCommand.fire("OMHTraitShop", "requestState", alice, {})
check(testPackets[#testPackets].player == alice and testPackets[#testPackets].args.tokens == 42, "snapshot addressed only to sender")
count = #testPackets
Events.OnClientCommand.fire("OMHTraitShop", "requestState", alice, {})
check(#testPackets == count, "read flood throttled")
testPlayers = {}
testClock = testClock + 1001
Events.OnTick.fire()
local reconnect = player("Alice", 0, 21, 3)
testPlayers = { reconnect }
testClock = testClock + 1001
Events.OnTick.fire()
check(authority.getState(reconnect).lifeId == initial.lifeId and authority.getState(reconnect).tokens == 42, "new player object reconnect resumes same life")
testTables = nativeRoundTrip(testTables)
Events.OnInitGlobalModData.fire()
check(authority.getState(reconnect).tokens == 42, "runtime reload rebinds native serialized state")
reconnect.dead = true
Events.OnCharacterDeath.fire(reconnect)
Events.OnTick.fire() -- Death settles after the native post-hit callback.
Events.OnCharacterDeath.fire(reconnect)
Events.OnTick.fire() -- Death settles after the native post-hit callback.
local replacement = player("Alice", 0, 23, 0)
testPlayers = { replacement }
testClock = testClock + 1001
Events.OnTick.fire()
check(authority.getState(replacement).tokens == 0 and authority.getState(replacement).lifeId ~= initial.lifeId, "server character-death event clears wallet before replacement")
Events.OnCharacterDeath.fire(reconnect)
Events.OnTick.fire() -- Death settles after the native post-hit callback.
check(authority.getState(replacement).status == "alive", "late retired object event ignored")
local current = authority.getState(replacement)
authority.updateState(replacement, current.lifeId, current.revision, { tokens = 5 })
replacement.dead = true
testClock = testClock + 1001
Events.OnTick.fire()
local another = player("Alice", 0, 24, 0)
check(authority.getState(another).tokens == 0, "scan catches death if event is missed")
replacement.dead = false
local anotherState = authority.getState(another)
check(not authority.updateState(replacement, anotherState.lifeId, anotherState.revision, { tokens = 999 }), "retired player object cannot target newer life even with its revision")
check(authority.getState(bob).tokens == 0, "other account unchanged")
testSide = "singleplayer"
testTables = {}
testPlayers = { player("ignored", 0, 40, 0) }
Events.OnInitGlobalModData.fire()
Events.OnCreatePlayer.fire(0, testPlayers[1])
local sp = authority.getState(testPlayers[1])
check(authority.updateState(testPlayers[1], sp.lifeId, sp.revision, { tokens = 7 }), "singleplayer uses same authority")
testTables = nativeRoundTrip(testTables)
Events.OnInitGlobalModData.fire()
check(authority.getState(testPlayers[1]).tokens == 7, "singleplayer native save/reload preserves wallet")
testSavedSnapshot = authority.getState(testPlayers[1])
testSide = "client"
