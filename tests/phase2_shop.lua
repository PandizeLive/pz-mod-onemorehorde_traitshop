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
end
check(State.initialize(legacy) and legacy.schema == 2, "v1 save migrates explicitly to v2")
check(legacy.accounts["user:Alice"].life.tokens == 5 and legacy.accounts["user:Alice"].life.creation.status == "legacy", "migration preserves wallet and prevents retroactive grants")
check(State.initialize(legacy), "migration is idempotent")
local corrupt = nativeRoundTrip(legacy)
corrupt.schema = 1
check(not State.initialize(corrupt) and corrupt.schema == 1, "ambiguous migration leaves data untouched")
local function purchase(id, overrides)
    local args = { traitId = id, lifeId = record.life.id, revision = record.revision, price = 2 }
    if overrides then for key, value in pairs(overrides) do args[key] = value end end
    return Shop.purchase(alice, record, args), args
end
local before = record.life.tokens
check(purchase("missing:trait") == "unsupported" and record.life.tokens == before, "unlisted trait cannot be purchased")
check(purchase("base:dextrous", { tokens = 999 }) == "invalid", "unknown fields cannot smuggle a balance")
check(purchase("base:dextrous", { price = 0 / 0 }) == "invalid", "NaN price rejected")
check(purchase("base:dextrous", { lifeId = 999 }) == "stale", "wrong life rejected")
check(purchase("base:dextrous", { price = 1 }) == "price_changed", "client price cannot discount purchase")
alice.traits["base:allthumbs"] = true
check(purchase("base:dextrous") == "conflict", "reverse-only trait exclusion enforced")
alice.traits = {}
testOptions["OMHTraitShop.PositiveCostMultiplier"] = 1.1
check(Catalog.price(testDefinitions["base:dextrous"]) == 3, "fractional price rounds up")
check(purchase("base:dextrous") == "price_changed", "settings change between render and click requires new quote")
testOptions["OMHTraitShop.PositiveCostMultiplier"] = 0 / 0
check(purchase("base:dextrous") == "settings", "invalid price settings cannot enable free purchases")
testOptions["OMHTraitShop.PositiveCostMultiplier"] = 1
testDefinitions["base:dextrous"].boosts = { 1 }
check(purchase("base:dextrous") == "unsupported", "modified trait needing XP adapter is excluded")
testDefinitions["base:dextrous"].boosts = {}
testDefinitions["base:dextrous"].recipes = { "recipe" }
check(purchase("base:dextrous") == "unsupported", "modified trait granting recipes is excluded")
testDefinitions["base:dextrous"].recipes = {}
local result, request = purchase("base:dextrous")
check(result == "purchased" and record.life.tokens == 3 and alice:hasTrait("base:dextrous"), "purchase charges authoritative price and applies trait")
check(testSyncs[#testSyncs].flags == 2 and testSyncs[#testSyncs].player == alice, "purchase uses native server-to-owner trait synchronization")
check(Shop.purchase(alice, record, request) == "stale" and record.life.tokens == 3, "replayed request cannot charge twice")
check(purchase("base:dextrous") == "owned" and alice.addCount == 1, "fresh request for owned trait cannot add duplicate native membership")
check(purchase("base:organized", { price = 6 }) == "funds" and record.life.tokens == 3, "insufficient funds rejected")
check(record.life.level == 0 and record.prestige.earned == 0, "purchases cannot generate prestige")
alice.traits = {}
store = nativeRoundTrip(store)
record = store.accounts["user:Alice"]
check(Shop.reconcile(alice, record, false) and alice:hasTrait("base:dextrous"), "persisted receipt recovers a trait absent from older player profile")
check(record.life.tokens == 3 and not Shop.reconcile(alice, record, false), "recovery is idempotent and never recharges")
record.life.purchases["base:fastreader"] = 2
record.life.tokens = 1
check(Shop.reconcile(alice, record, false) and alice:hasTrait("base:fastreader"), "interrupted commit-before-effect recovers the owed trait")
local deadRequest = { lifeId = record.life.id, revision = record.revision, traitId = "base:outdoorsman", price = 2 }
local lifeId = record.life.id
State.settleDeath(record, lifeId)
check(Shop.purchase(alice, record, deadRequest) == "dead", "death before request rejects purchase")
local replacement = player("Alice", 0, 41, 0)
record = State.attach(store, "user:Alice", 41, 0)
Creation.settle(replacement, record)
check(record.life.tokens == 5 and not Shop.reconcile(replacement, record, false), "replacement receives only its own starting grant and no retired purchases")
check(Shop.purchase(replacement, record, deadRequest) == "stale", "old request cannot target replacement wallet")
local snapshot = Shop.snapshot(replacement, record)
check(#snapshot.offers == 10 and snapshot.startingTokens == 5, "bounded shop snapshot contains catalog and creation grant")
testPhase2Snapshot = nativeRoundTrip(snapshot)
testTransportPackets = { snapshot }
