local State = require("OMHTS_State")
local Creation = require("OMHTS_Creation")
local Catalog = require("OMHTS_Catalog")
local Shop = require("OMHTS_Shop")

local function verifyNativeShop()
    assert(type(math.min) == "function" and type(math.max) == "function", "game math helpers missing")
    Translator.loadFiles()
    assert(getText("UI_OMHTS_Title") == "OMH: Trait Shop", "UI JSON translations did not load")
    assert(getText("Sandbox_OMHTraitShop_PositiveCostMultiplier") == "Positive Cost Multiplier", "Sandbox JSON translations did not load")
    local store = ModData.getOrCreate("OMHTraitShop_State_v1")
    assert(State.initialize(store))
    local definitions = Catalog.definitions()
    assert(definitions:size() > 10, "full native trait registry missing")
    local unverified = 0
    for index = 0, definitions:size() - 1 do
        local definition = definitions:get(index)
        assert(Catalog.definition(tostring(definition:getType())) == definition, "registry ID lookup mismatch")
        if definition:getCost() > 0 and not definition:isFree() and not Catalog.supported(definition) then
            assert(Catalog.price(definition) > 0, "unverified trait lacks display price")
            unverified = unverified + 1
        end
    end
    assert(unverified > 0, "discovery unexpectedly enables every positive trait")
    assert(string.find(getText("UI_OMHTS_PrestigeTip", "1", "2"), "Retained") ~= nil)
    print("[OMHTS TEST] native registry " .. definitions:size() .. "; visible unverified positives " .. unverified)
    for index = 1, #Catalog.entries do
        local entry = Catalog.entries[index]
        local definition = Catalog.definition(entry.id)
        assert(Catalog.supported(definition), "unsupported catalog entry: " .. entry.id)
        assert(tostring(definition:getType()) == entry.id, "native trait identity mismatch: " .. entry.id)
    end
    local descriptor = SurvivorFactory.CreateSurvivor()
    descriptor:setCharacterProfession(CharacterProfession.UNEMPLOYED)
    descriptor:setID(4242)
    local player = IsoPlayer.new(getCell(), descriptor, 0, 0, 0)
    player:setUsername("TraitShopNativeProbe")
    player:setHoursSurvived(0)
    local container = ItemContainer.new()
    container:setCapacity(10)
    assert(container:getEffectiveCapacity(player) == 10)
    local record = store.accounts["test:phase2"]
    if record then
        descriptor:setID(record.life.characterId)
    end
    if not record then
        assert(Creation.remainingPoints(player) == 8, "unemployed base budget mismatch")
        record = State.attach(store, "test:phase2", 4242, 0)
        assert(Creation.settle(player, record) and record.life.tokens == 8)
        assert(Shop.purchase(player, record, { traitId = "base:dextrous", lifeId = record.life.id,
            revision = record.revision, price = 2 }) == "purchased")
        assert(Shop.purchase(player, record, { traitId = "base:organized", lifeId = record.life.id,
            revision = record.revision, price = 4 }) == "purchased")
        assert(record.life.tokens == 2 and player:hasTrait(CharacterTrait.DEXTROUS))
        assert(container:getEffectiveCapacity(player) == 13, "Organized effect failed")
        print("[OMHTS TEST] native catalog 10/10; starting 8; purchases 2+4; capacity 10->13")
        print("[OMHTS TEST] disk stage 1 ready")
    elseif record.life.characterId == 4242 then
        assert(record.life.tokens == 2 and record.life.creation.tokens == 8)
        assert(record.life.purchases["base:dextrous"] == 2 and record.life.purchases["base:organized"] == 4)
        assert(Shop.reconcile(player, record, false))
        assert(player:hasTrait(CharacterTrait.DEXTROUS) and container:getEffectiveCapacity(player) == 13)
        assert(not Shop.reconcile(player, record, false))
        assert(State.settleDeath(record, record.life.id))
        record = State.attach(store, "test:phase2", 4243, 0)
        print("[OMHTS TEST] native purchase receipts restored effects; death cleared receipts")
        print("[OMHTS TEST] disk stage 2 ready")
    else
        assert(record.life.characterId == 4243 and record.life.tokens == 0)
        assert(Creation.settle(player, record) and record.life.tokens == 8)
        assert(not Creation.settle(player, record) and record.life.tokens == 8)
        assert(not Shop.reconcile(player, record, false))
        assert(not player:hasTrait(CharacterTrait.DEXTROUS) and container:getEffectiveCapacity(player) == 10)
        assert(record.life.level == 0 and record.prestige.earned == 0)
        print("[OMHTS TEST] native replacement receives exactly 8 starting Tokens; no inherited purchases")
        print("[OMHTS TEST] disk stage 3 ready")
    end
    player:removeFromWorld()
end

Events.OnServerStarted.Add(verifyNativeShop)
