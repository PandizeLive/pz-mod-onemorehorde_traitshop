testStage = "creation, migration, transactions and recovery"
local State = require("OMHTS_State")
local Creation = require("OMHTS_Creation")
local Shop = require("OMHTS_Shop")
local Catalog = require("OMHTS_Catalog")
local store = {}
State.initialize(store)
local alice = player("Alice", 0, 40, 0)
testProfession.cost = 5
check(Creation.remainingPoints(alice) == 5, "five unspent creation points reconstruct exactly")
local record = State.attach(store, "user:Alice", 40, 0)
check(Creation.settle(alice, record) and record.life.tokens == 5, "new-life creation grant commits")
check(not Creation.settle(alice, record) and record.life.tokens == 5, "duplicate initialization cannot grant again")
check(record.life.level == 0 and record.life.xp == 0 and record.prestige.earned == 0, "starting Tokens do not generate levels XP or prestige")
alice.traits["base:allthumbs"] = true
alice.traits["test:negative2"] = true
alice.traits["test:negative3"] = true
testOptions.NegativeTraitsPenalty = 1
check(Creation.remainingPoints(alice) == 11, "three negatives count at their actual costs")
testOptions.NegativeTraitsPenalty = 2
check(Creation.remainingPoints(alice) == 10, "one-per-three negative penalty matches vanilla")
testOptions.NegativeTraitsPenalty = 3
check(Creation.remainingPoints(alice) == 10, "one-per-two negative penalty matches vanilla")
testOptions.NegativeTraitsPenalty = 4
check(Creation.remainingPoints(alice) == 9, "all-but-first negative penalty matches vanilla")
testProfession.grants = { "base:allthumbs" }
check(Creation.remainingPoints(alice) == 8, "profession-granted negative is excluded from points and penalty")
testDefinitions["test:negative2"].grants = { "test:negative3" }
check(Creation.remainingPoints(alice) == 7, "nested granted trait is not charged twice")
testDefinitions["test:negative3"].grants = { "test:negative2" }
check(Creation.remainingPoints(alice) == 5, "grant cycles terminate and cannot generate Tokens")
testDefinitions["test:negative2"].grants = {}
testDefinitions["test:negative3"].grants = {}
testProfession.grants = {}
testOptions.NegativeTraitsPenalty = 1
alice.traits = { ["missing:trait"] = true }
check(Creation.remainingPoints(alice) == nil, "unknown starting trait fails closed")
alice.traits = { ["base:organized"] = true }
check(Creation.remainingPoints(alice) == nil, "invalid negative creation budget cannot mint money")
alice.traits = {}
testOptions.CharacterFreePoints = 5
check(Creation.remainingPoints(alice) == 10, "sandbox free points included")
testOptions.CharacterFreePoints = 0
local old = State.attach(store, "legacy", 33, 1)
check(not Creation.settle(alice, old) and old.life.creation.status == "legacy", "existing aged character receives no retroactive grant")
local legacy = nativeRoundTrip(store)
legacy.schema = 1
for _, value in pairs(legacy.accounts) do
    value.life.creation = nil
    value.life.purchases = nil
    value.life.removals = nil
    value.life.effects = nil
end
check(State.initialize(legacy) and legacy.schema == 3, "v1 save migrates explicitly to v3")
check(legacy.accounts["user:Alice"].life.tokens == 5 and legacy.accounts["user:Alice"].life.creation.status == "legacy", "migration preserves wallet and prevents retroactive grants")
check(State.initialize(legacy), "migration is idempotent")
local corrupt = nativeRoundTrip(legacy)
corrupt.schema = 1
check(not State.initialize(corrupt) and corrupt.schema == 1, "ambiguous migration leaves data untouched")
local function checkout(items, overrides)
    local args = { lifeId = record.life.id, revision = record.revision, items = items }
    if overrides then for key, value in pairs(overrides) do args[key] = value end end
    return Shop.purchase(alice, record, args), args
end
local buyDex = { id = "base:dextrous", price = 2, remove = false }
local removeThumbs = { id = "base:allthumbs", price = 4, remove = true }
alice.traits["base:allthumbs"] = true
record.life.tokens = 20
check(checkout({removeThumbs}) == "removal_disabled", "removal disabled by default")
testOptions["OMHTraitShop.AllowNegativeRemoval"] = true
check(checkout({buyDex}) == "conflict", "reverse-only conflict rejected")
check(checkout({buyDex, buyDex}) == "invalid", "duplicate cart lines rejected")
check(checkout({buyDex}, {tokens = 999}) == "invalid", "cart cannot inject wallet")
check(checkout({buyDex}, {lifeId = 999}) == "stale", "foreign life rejected")
check(checkout({{id="base:fastreader", price=0/0, remove=false}}) == "invalid", "NaN quote rejected")
check(checkout({{id="base:fastreader", price=1, remove=false}}) == "price_changed", "price tampering rejected")
check(checkout({buyDex, {id="missing:trait",price=1,remove=false}}) == "unsupported"
    and record.life.tokens == 20 and not alice:hasTrait("base:dextrous"), "invalid later line never partially charges or applies")
record.life.tokens = 5
check(checkout({buyDex, removeThumbs}) == "funds" and alice:hasTrait("base:allthumbs"), "aggregate cost checked before removal")
record.life.tokens = 20
local result, request = checkout({buyDex, removeThumbs})
check(result == "purchased" and record.life.tokens == 14 and alice:hasTrait("base:dextrous")
    and not alice:hasTrait("base:allthumbs"), "mixed cart removes conflict then buys positive for exact combined price")
check(record.life.removals["base:allthumbs"] == 4 and record.life.purchases["base:dextrous"] == 2, "separate receipts record purchase and removal")
check(Shop.purchase(alice, record, request) == "stale" and record.life.tokens == 14, "replay does not charge twice")
check(testSyncs[#testSyncs].flags == 3, "native sync includes traits and recipes")
check(not Shop.reconcile(alice, record, false), "effect recovery idempotent")
alice.traits = { ["base:allthumbs"] = true }
record = nativeRoundTrip(record)
check(Shop.reconcile(alice, record, false) and not alice:hasTrait("base:allthumbs") and alice:hasTrait("base:dextrous"), "native save roundtrip repairs both sides of mixed cart")
check(record.life.tokens == 14, "receipt repair never charges again")
local cooking = Perks.FromString("Cooking")
local modded = traitFixture("MODDED", "mod:chef", 3)
modded.boosts = {[cooking] = 1}
modded.recipes = {"Soup"}
modded.grants = {"mod:child"}
traitFixture("CHILD", "mod:child", 0).free = true
Catalog.definitions()
alice.skillXP.Cooking = 125
alice.boosts.Cooking = 1
check(Catalog.supported(modded), "modded trait with standard skill recipe and child effects needs no allowlist")
check(checkout({{id="mod:chef",price=3,remove=false}}) == "purchased", "generic modded trait purchased")
check(alice.skillXP.Cooking == 425 and alice.boosts.Cooking == 2 and alice.recipes.Soup
    and alice:hasTrait("mod:child"), "standard effects apply including partial skill XP preservation")
check(not Shop.reconcile(alice, record, false) and alice.skillXP.Cooking == 425, "skill bonuses cannot stack on recovery")
alice.skillXP.Cooking = 500
check(not Shop.reconcile(alice, record, false) and alice.skillXP.Cooking == 500, "later earned XP is never rewound")
local Effects = require("OMHTS_Effects")
local duplicateGrant = Effects.plan(alice, record.life.effects, {["mod:chef"]=false,["mod:child"]=false})
check(duplicateGrant ~= nil, "already owned effects cannot grant a child twice")
local training = traitFixture("TRAINING", "mod:trained", 2)
training.boosts = {[cooking] = 1}
Catalog.definitions()
check(checkout({{id="mod:trained",price=2,remove=false}}) == "purchased" and alice.skillXP.Cooking == 1000,
    "second trait stacks its contribution once")
alice.boosts.Cooking = 0
alice.skillXP.Cooking = 0
check(Shop.reconcile(alice, record, false) and alice.boosts.Cooking == 3 and alice.skillXP.Cooking == 1000,
    "latest cumulative skill receipt repairs rollback older than multiple purchases")
local childParent = traitFixture("CHILD_PARENT", "mod:parent", 1)
childParent.grants = {"mod:paidchild"}
traitFixture("PAID_CHILD", "mod:paidchild", 1)
Catalog.definitions()
local effectPlan, effectReason = Effects.plan(alice, record.life.effects, {["mod:parent"]=false,["mod:paidchild"]=false})
check(effectPlan == nil and effectReason == "conflict", "cart cannot pay twice for a parent and its granted child")
local cycleA = traitFixture("CYCLE_A", "mod:cyclea", 1)
local cycleB = traitFixture("CYCLE_B", "mod:cycleb", 0)
cycleA.grants = {"mod:cycleb"}
cycleB.grants = {"mod:cyclea"}
Catalog.definitions()
effectPlan = Effects.plan(alice, record.life.effects, {["mod:cyclea"]=false})
check(effectPlan == nil, "cyclic grants reject the cart without recursive effects")
local body = traitFixture("BODY", "mod:fitness", 1)
body.boosts = {[Perks.FromString("Fitness")] = 1}
Catalog.definitions()
check(checkout({{id="mod:fitness",price=1,remove=false}}) == "body", "body stat metadata exclusion covers modded IDs")
Catalog.excludeTrait("mod:trained")
check(Catalog.exclusion(training) == "excluded", "integration can exclude known custom incompatibility")
local bad = traitFixture("BAD", "mod:negativegrant", -1)
bad.grants = {"mod:child"}
alice.traits["mod:negativegrant"] = true
Catalog.definitions()
check(checkout({{id="mod:negativegrant",price=2,remove=true}}) == "grants", "negative child-trait cleanup requires adapter")
testProfession.grants = {"test:negative2"}
alice.traits["test:negative2"] = true
check(checkout({{id="test:negative2",price=4,remove=true}}) == "granted", "profession traits cannot be stripped")
testProfession.grants = {}
local snapshot = Shop.snapshot(alice, record)
check(snapshot.spentTokens == 11, "spending breakdown includes removals and all additions")
check(require("OMHTS_Effects").valid(snapshot.effects), "wire skill target shape bounded and valid")
local beforeDeath = record.life.id
check(State.settleDeath(record, beforeDeath) and record.life.tokens == 0, "death clears wallet")
check(not pairs(record.life.effects.traits)(), "death clears trait effect entitlements")
local v2 = nativeRoundTrip(store)
v2.schema = 2
for _, value in pairs(v2.accounts) do
    value.life.removals = nil
    value.life.effects = nil
end
check(State.initialize(v2) and v2.schema == 3, "v2 receipts migrate without new grants or charges")
local corruptV2 = nativeRoundTrip(v2)
corruptV2.schema = 2
for _, value in pairs(corruptV2.accounts) do
    value.life.removals = nil
    value.life.effects = nil
end
corruptV2.accounts["user:Alice"].life.purchases.bad = -5
check(not State.initialize(corruptV2) and corruptV2.schema == 2
    and corruptV2.accounts["user:Alice"].life.effects == nil, "corrupt migration preserves original data")
testProfession.cost = 5
testOptions["OMHTraitShop.AllowNegativeRemoval"] = false
testPhase2Snapshot = snapshot
testTransportPackets = { snapshot }