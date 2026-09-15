testStage = "registry catalog, compatibility boundary and presentation"
local Catalog = require("OMHTS_Catalog")
local Presentation = require("OMHTS_Presentation")
local Shop = require("OMHTS_Shop")
local State = require("OMHTS_State")
local modded = traitFixture("MODDED", "example:steadyhands", 3)
local unsupported = traitFixture("UNVERIFIED", "example:unverified", 1)
local free = traitFixture("FREE", "example:professiongrant", 0)
free.free = true
local definitions = Catalog.definitions()
check(Catalog.definition(modded.id) == modded, "loaded mod trait resolved by registry identity")
check(not Catalog.supported(modded), "empty metadata alone cannot certify custom Lua effects")
check(Catalog.price(modded) == 3, "unverified trait still has a display price")
check(not Catalog.registerMembershipTrait("invalid id"), "compatibility registration validates stable namespaced ID")
check(Catalog.registerMembershipTrait(modded.id) and Catalog.registerMembershipTrait(modded.id),
    "membership-only integration registration is idempotent")
check(Catalog.supported(modded), "explicit membership-only integration enables a modded trait")
modded.boosts = { 1 }
check(not Catalog.supported(modded), "integration cannot bypass required effect initialization")
modded.boosts = {}
local store = {}
State.initialize(store)
local owner = player("Compatibility", 0, 88, 0)
local record = State.attach(store, "compatibility", 88, 0)
record.life.creation.status = "granted"
record.life.tokens = 10
testSide = "server"
check(Shop.purchase(owner, record, { lifeId = record.life.id, revision = record.revision,
    traitId = unsupported.id, price = 1 }) == "unsupported", "discovery cannot authorize an unverified purchase")
check(Shop.purchase(owner, record, { lifeId = record.life.id, revision = record.revision,
    traitId = modded.id, price = 3 }) == "purchased" and record.life.tokens == 7 and owner:hasTrait(modded.id),
    "registered mod trait uses normal server debit and effect path")
owner.traits = {}
record = nativeRoundTrip(record)
check(Shop.reconcile(owner, record, false) and owner:hasTrait(modded.id), "modded receipt recovers after serialized reload")
owner.traits["base:allthumbs"] = true
owner.traits[free.id] = true
local snapshot = Shop.snapshot(owner, record)
check(snapshot.spentTokens == 3, "Token tooltip spending comes from server purchase receipts")
local capped = nativeRoundTrip(record)
for index = 2, 100 do capped.life.purchases["old_mod:trait" .. index] = 1 end
check(Shop.purchase(owner, capped, { lifeId = capped.life.id, revision = capped.revision,
    traitId = "base:brave", price = 4 }) == "limit" and capped.life.tokens == 7 and State.isRecord(capped),
    "historical receipts from removed integrations cannot overflow persistent purchase limit")
local owned = Presentation.ownership(owner, snapshot)
local rows = Presentation.rows(definitions, owned, snapshot, "", 1)
check(#rows.positive == 2 and #rows.negative == 1, "all current traits include profession grants and negative traits")
check(rows.negative[1].status == "removal_deferred", "owned negatives inspectable without enabling removal")
check(rows.catalog[1].id == unsupported.id and rows.catalog[1].status == "unsupported", "cheap unsupported mod trait remains visible in price order")
check(#Presentation.rows(definitions, owned, snapshot, "example:", 1).catalog == 1, "search by mod ID only filters unowned catalog")
check(#Presentation.rows(definitions, owned, snapshot, "no-match", 1).positive == 2, "catalog search does not hide current traits")
local available = Presentation.rows(definitions, owned, snapshot, "", 2)
for index = 1, #available.catalog do
    check(available.catalog[index].status == "available", "available filter excludes all disabled rows")
end
local pair = { { id = "x:b", name = "Beta", sortPrice = 2 }, { id = "x:a", name = "Alpha", sortPrice = 2 } }
table.sort(pair, Presentation.cheapestFirst)
check(pair[1].name == "Alpha" and not Presentation.cheapestFirst(pair[1], pair[1]), "equal prices use deterministic strict alphabetical comparison")
check(Presentation.fitName("Éééééééééé", 60) == "Éééé...", "compact labels preserve accented Java string characters")
local emojiShort = Presentation.fitName(testUnicodeLabel, 60)
check(emojiShort == string.sub(testUnicodeLabel, 1, 3) .. "...", "compact labels do not split Java surrogate pairs")
for index = #Catalog.entries + 1, Catalog.MAX_PURCHASE_TRAITS do
    Catalog.registerMembershipTrait("fixture:entry" .. index)
end
check(not Catalog.registerMembershipTrait("fixture:overflow"), "integration count stays within persistence and transport bounds")
testTransportPackets[#testTransportPackets + 1] = Shop.snapshot(owner, record)
for index = 1, 500 do
    traitFixture("BULK" .. index, "bulk:trait" .. index, 1 + index % 8)
end
definitions = Catalog.definitions()
local bulk = Presentation.rows(definitions, owned, snapshot, "bulk:", 1).catalog
check(#bulk == 500 and bulk[1].price == 1 and bulk[500].price == 8, "large mod registry retains every matching trait in ascending price order")
check(#Presentation.rows(definitions, owned, snapshot, "bulk:trait500", 1).catalog == 1, "search reaches the end of a large mod registry")
check(#Presentation.rows(definitions, owned, snapshot, "[", 1).catalog == 0, "search treats Lua pattern characters literally")
for index = 1, 500 do testDefinitions["bulk:trait" .. index] = nil end
Catalog.definitions()
testSide = "client"
