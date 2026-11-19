testStage = "Checkpoint 5 birth capture and XP routing"
local authority = OneMoreHordeTraitShop.Authority
local originalSide = testSide
testSide = "server"
local savedTables = testTables
local savedPlayers = testPlayers
testTables = {}
testPlayers = {}
Events.OnInitGlobalModData.fire()
local newborn = player("BirthTest",0,750,0)
Events.OnNewGame.fire(newborn,nil)
check(testTables.OMHTraitShop_State_v1.creations["user:9:BirthTest:750"] == 0, "server new-game captures zero points explicitly")
testTables = nativeRoundTrip(testTables)
Events.OnInitGlobalModData.fire()
local connected = player("BirthTest",0,750,0.025)
local snapshot = authority.getState(connected)
check(snapshot.creationStatus == "granted" and snapshot.startingTokens == 0, "creation proof survives disk and nonzero first-join age")
check(testTables.OMHTraitShop_State_v1.creations["user:9:BirthTest:750"] == nil, "creation claim consumed")
Events.OnNewGame.fire(connected,nil)
check(testTables.OMHTraitShop_State_v1.creations["user:9:BirthTest:750"] == nil, "duplicate creation event cannot regrant")
check(authority.awardXP(connected,snapshot.lifeId,snapshot.revision,100), "server XP API commits")
local after = authority.getState(connected)
check(after.level == 1 and after.tokens == 1 and after.xp == 0, "server XP API produces level and Token")
check(not authority.awardXP(connected,snapshot.lifeId,snapshot.revision,100), "server replay rejected")
Events.OnClientCommand.fire("OMHTraitShop","awardXP",connected,{amount=1000})
check(authority.getState(connected).tokens == 1, "client cannot award itself XP")
local old = authority.getState(player("Existing",0,751,0.025))
check(old.creationStatus == "legacy" and old.tokens == 0, "old character without birth proof gains nothing")
local wrongAccount = authority.getState(player("Other",0,750,0.025))
check(wrongAccount.creationStatus == "legacy", "descriptor collision cannot claim another account grant")
testTables = savedTables
testPlayers = savedPlayers
testSide = originalSide
Events.OnInitGlobalModData.fire()
