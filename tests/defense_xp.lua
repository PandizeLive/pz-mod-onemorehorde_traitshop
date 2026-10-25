testStage = "shared defense XP"
testSide = "server"
testHorde = false
SandboxVars.OMHTurretsTraps = {DefenseXPEnabled = true, DefenseXPPercent = 50, DefenseXPIncludeOffline = true}
local State = require("OMHTS_State")
local Rewards = require("OMHTS_Rewards")
local Pools = require("OMHTS_DefenseRewards")
local Credit = require("OMHTS_DefenseCredit")
local store = {}
check(State.initialize(store) and Rewards.initialize(store) and Pools.initialize(store), "fresh authoritative schemas")
local bindings = {}
local factions = {}
Faction.getFactions = function() return fixtureList(factions) end
local function faction(name, owner, members)
    return {getName = function() return name end, getOwner = function() return owner end,
        getPlayers = function() return fixtureList(members) end}
end
local function actor(name, id)
    local p = player(name, 0, id, 3)
    p.health = 1
    p.part = {health = 100, scratch = 0, cut = 0, deep = 0, bleed = 0, bullet = false}
    local part = p.part
    function part:getHealth() return self.health end
    function part:getScratchTime() return self.scratch end
    function part:getCutTime() return self.cut end
    function part:getDeepWoundTime() return self.deep end
    function part:getBleedingTime() return self.bleed end
    function part:haveBullet() return self.bullet end
    function p:getHealth() return self.health end
    function p:setAttackedBy(value) self.killer = value end
    function p:getOnlineID() return id end
    function p:getBodyDamage() return {getBodyParts = function() return fixtureList({part}) end} end
    local record = State.attach(store, name, id, 3)
    Pools.attach(store, name, record, name, name)
    Credit.attached(name, name)
    bindings[p] = {record = record, lifeId = record.life.id}
    return p, record
end
Credit.initialize({store = store, bindings = bindings, key = function(p) return p.name end})
local alice, a = actor("Alice", 1)
local bob, b = actor("Bob", 2)
local carol, c = actor("Carol", 3)
local victim, v = actor("Victim", 4)
factions = {faction("Team", "Alice", {"Bob"})}
local function death(owner, horde)
    local zombie = {}
    Credit.zombieFinisher(zombie, owner, horde)
    check(Credit.zombieDeath(zombie), "defense consumes ordinary reward path")
    check(not Credit.zombieDeath(zombie), "same zombie receipt consumed once")
end
death("Alice", false)
check(a.life.xp == .5 and b.life.xp == .5 and c.life.xp == 0, "one half pool shared, no personal owner bonus")
bindings[bob] = nil
death("Alice", false)
check(a.life.xp == 1 and b.life.xp == .5 and store.defense.pending.Bob.amount == .5, "offline share reserved without redistribution")
store = nativeRoundTrip(store)
a, b, c, v = store.accounts.Alice, store.accounts.Bob, store.accounts.Carol, store.accounts.Victim
bindings = {[alice] = {record = a, lifeId = a.life.id}, [carol] = {record = c, lifeId = c.life.id}, [victim] = {record = v, lifeId = v.life.id}}
Credit.initialize({store = store, bindings = bindings, key = function(p) return p.name end})
check(Pools.attach(store, "Bob", b, "Bob", "Bob") and b.life.xp == 1, "native serialization restart delivers exact reserved share")
check(not Pools.attach(store, "Bob", b, "Bob", "Bob") and b.life.xp == 1, "repeated reconnect cannot deliver twice")
bindings[bob] = {record = b, lifeId = b.life.id}
-- A blocked hit and a bleed tick after it must not manufacture an assistant.
Credit.beforeHit(carol, victim, {}, 100)
Credit.afterHit(carol, {}, victim)
check(not store.defense.encounters.Victim, "nominal ignored hit creates no participant")
Credit.beforeHit(carol, victim, {}, 100)
Credit.tick()
victim.part.health = 99
Credit.afterHit(carol, {}, victim)
check(not store.defense.encounters.Victim, "later unrelated health loss cannot confirm a pre-hit callback")
Credit.beforeHit(alice, victim, {}, 1)
victim.part.scratch = 10
Credit.afterHit(alice, {}, victim)
Credit.beforeHit(carol, victim, {}, 1)
victim.part.health = 98
Credit.afterHit(carol, {}, victim)
Credit.beforeHit(carol, victim, {}, 1)
victim.part.health = 97
Credit.afterHit(carol, {}, victim)
Credit.playerInjury(victim, "Alice")
victim.dead = true
check(Rewards.consumePlayer(store, victim, v.life.id), "first death admitted")
check(Credit.playerDeath(victim), "delayed defense death owns settlement")
check(math.abs(a.life.xp - 38.5) < .000001 and math.abs(b.life.xp - 19.75) < .000001
    and math.abs(c.life.xp - 18.75) < .000001, "75 XP: faction 18.75 each, two equal personal assists, owner receives both once")
check(not Rewards.consumePlayer(store, victim, v.life.id), "duplicate PvP death rejected")
check(store.rewards.cooldowns.Alice.Victim == testWorldHours + 48, "combined award consumes one configured account cooldown")
Pools.death(store, "Victim")
victim.dead = false
v = State.attach(store, "Victim", 5, 0)
bindings[victim] = {record = v, lifeId = v.life.id}
Pools.attach(store, "Victim", v, "Victim", "Victim")
Credit.playerInjury(victim, "Alice")
victim.dead = true
local before = a.life.xp
check(Credit.playerDeath(victim) and a.life.xp == before, "victim replacement does not bypass account cooldown")
victim.dead = false
testWorldHours = testWorldHours + 49
Credit.playerInjury(victim, "Alice")
victim.part.health, victim.part.scratch = 100, 0
Credit.recovery(victim)
local recoveryPacket = testPackets[#testPackets]
Credit.recoveryReply("OMHTS_DefenseRecovery", "Checked", victim, {token = recoveryPacket.args.token, recovered = true})
check(not store.defense.encounters.Victim, "complete recovery clears source and assists")
Credit.beginInjury(victim, "first")
check(Credit.waiting(victim), "death waits for an outstanding authorized injury")
Credit.beforeHit(carol, victim, {}, 1)
victim.part.cut = 5
victim.killer = carol
Credit.afterHit(carol, {}, victim)
Credit.finishInjury(victim, "first", "Alice", true)
check(not store.defense.encounters.Victim.owner, "late receipt cannot overwrite newer confirmed player credit")
Credit.beginInjury(victim, "second")
Credit.finishInjury(victim, "second", "Alice", false)
check(not Credit.waiting(victim) and not store.defense.encounters.Victim.owner, "no-injury receipt awards no credit")
Credit.beginInjury(victim, "third")
testClock = testClock + 5001
check(not Credit.waiting(victim), "missing receipt expires without blocking death forever")
Credit.finishInjury(victim, "third", "Alice", true)
check(not store.defense.encounters.Victim.owner, "expired receipt cannot claim a kill")
-- Same-life earned amounts survive changed faction/rates; dead lives do not.
local snapshot = {key = "Bob", username = "Bob", life = b.life.id, online = false, unofficial = true}
Pools.settle(store, Pools.plan(2, .5, {snapshot}, {}, false), nil, testWorldHours, 48)
factions = {}
SandboxVars.OMHTurretsTraps.DefenseXPPercent = 0
check(Pools.attach(store, "Bob", b, "Bob", "Bob") and b.life.xp == 20.75, "earned payout ignores later faction and rate changes")
Pools.settle(store, Pools.plan(2, .5, {snapshot}, {}, false), nil, testWorldHours, 48)
State.settleDeath(b, b.life.id)
b = State.attach(store, "Bob", 6, 0)
check(not Pools.attach(store, "Bob", b, "Bob", "Bob") and b.life.xp == 0, "replacement life inherits no pending reward")
SandboxVars.OMHTurretsTraps.DefenseXPPercent = 50
local solo = Pools.plan(2, .5, {{key = "Solo"}}, {}, false)
check(solo.Solo.amount == 1, "solo receives exactly one half pool")
check(Pools.plan(75,.5,{}, {},true).Alice == nil, "no eligible recipients creates no award")
SandboxVars.OMHTraitShop.RewardMode = 2
local previous = a.life.xp
death("Alice", false)
check(a.life.xp == previous, "survival mode suppresses kill XP")
SandboxVars.OMHTraitShop.RewardMode = 4
SandboxVars.OMHTurretsTraps.DefenseXPEnabled = false
death("Alice", false)
check(a.life.xp == previous, "disabled integration suppresses XP without ordinary fallback")
SandboxVars.OMHTurretsTraps.DefenseXPEnabled = true
Credit.beginInjury(victim, "older-valid")
Credit.beginInjury(victim, "newer-ignored")
Credit.finishInjury(victim, "newer-ignored", "Carol", false)
Credit.finishInjury(victim, "older-valid", "Alice", true)
check(store.defense.encounters.Victim.owner == "Alice", "newer ignored defense cannot erase an earlier confirmed injury")
Credit.beginInjury(victim, "older")
Credit.beginInjury(victim, "newer")
Credit.finishInjury(victim, "newer", "Carol", true)
Credit.finishInjury(victim, "older", "Alice", true)
check(store.defense.encounters.Victim.owner == "Carol", "reordered defense receipts retain newest confirmed source")
Credit.beginInjury(victim, "before-zombie")
victim.killer = {class = "IsoZombie"}
Credit.finishInjury(victim, "before-zombie", "Alice", true)
check(not Credit.playerDeath(victim), "new native attacker invalidates retained defense and late receipt")
victim.killer = nil
Credit.playerInjury(victim, "Alice")
Credit.recovery(victim)
local stale = testPackets[#testPackets].args.token
Credit.playerInjury(victim, "Carol")
Credit.recoveryReply("OMHTS_DefenseRecovery", "Checked", victim, {token = stale, recovered = true})
check(store.defense.encounters.Victim.owner == "Carol", "stale recovery reply cannot clear a newer injury")
bindings[bob] = nil
factions = {faction("Team", "Alice", {"Bob"})}
SandboxVars.OMHTurretsTraps.DefenseXPIncludeOffline = false
previous = a.life.xp
death("Alice", false)
check(a.life.xp == previous + 1 and not store.defense.pending.Bob, "offline toggle excludes pending shares")
previous = a.life.xp
death(nil, false)
check(a.life.xp == previous, "unknown legacy owner receives no invented attribution")
local oldMods = getActivatedMods
getActivatedMods = function() return {contains = function(_, id) return id == "OneMoreHorde_Traps" end} end
SandboxVars.OMHTurretsTraps.TrapsDefenseXPEnabled = false
death("Alice", false)
check(a.life.xp == previous, "traps-only package uses its independent disabled setting")
SandboxVars.OMHTurretsTraps.TrapsDefenseXPEnabled = true
SandboxVars.OMHTurretsTraps.TrapsDefenseXPPercent = 20
SandboxVars.OMHTurretsTraps.TrapsDefenseXPIncludeOffline = false
death("Alice", false)
check(math.abs(a.life.xp - previous - .4) < .000001, "traps-only package uses its independent pool percentage")
getActivatedMods = oldMods
local corrupt = nativeRoundTrip(store)
corrupt.defense.pending.Alice = {life = 1, amount = -1, unofficial = false}
check(not Pools.initialize(corrupt), "invalid pending ledger is preserved and rejected")
-- Horde reward amount and participation gates still apply to the shared pool.
testHorde = true
__modules.OMH_Extensions = {HORDE_REWARD_SCHEMA = 1}
OneMoreHordeDifficultyRuntime = {isTraitShopEnabled = function() return true end,
    isTraitShopEarningOfficial = function() return true end,
    traitShopIdentityStatus = function() return true, true end}
SandboxVars.OMHTraitShop.RewardMode = 3
previous = a.life.xp
death("Alice", {participants = {Alice = {casualty = true, eligibilityStatus = "eligible"}}})
check(a.life.xp == previous, "Horde casualty cannot earn through a defense")
death("Alice", {participants = {Alice = {eligibilityStatus = "eligible"}}})
check(a.life.xp == previous + 2.5, "Horde source uses configured Horde XP before half split")
testHorde = false
testOutput = testChecks .. " defense XP assertions passed"
