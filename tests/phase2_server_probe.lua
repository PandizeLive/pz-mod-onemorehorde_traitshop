local State = require("OMHTS_State")
local Creation = require("OMHTS_Creation")
local Catalog = require("OMHTS_Catalog")
local Shop = require("OMHTS_Shop")
local Effects = require("OMHTS_Effects")

local function verifyNativeShop()
    Translator.loadFiles()
    assert(getText("UI_OMHTS_Buy") == "Purchase")
    assert(getText("Sandbox_OMHTraitShop_NegativeCostMultiplier") == "Negative Cost Multiplier")
    assert(getText("Sandbox_OMHTraitShop_AllowNegativeRemoval") == "Allow Negative Trait Removal")
    local removalOption = getSandboxOptions():getOptionByName("OMHTraitShop.AllowNegativeRemoval")
    assert(removalOption:getValue() == false, "negative removal default changed")
    removalOption:setValue(true)
    assert(Catalog.multiplier(true) == 2, "negative default multiplier")
    local definitions = Catalog.definitions()
    local supported = 0
    local skillTrait
    local recipeTrait
    for index = 0, definitions:size() - 1 do
        local definition = definitions:get(index)
        if Catalog.supported(definition) then
            supported = supported + 1
            if not definition:getXpBoosts():isEmpty() and definition:getGrantedTraits():isEmpty() then
                skillTrait = definition
            end
            if not definition:getGrantedRecipes():isEmpty() then
                recipeTrait = definition
            end
        end
    end
    assert(supported > 10 and skillTrait, "broad native catalog and skills missing")
    if not recipeTrait then
        recipeTrait = Catalog.definition("base:fastreader")
        assert(ScriptManager.instance:getCraftRecipe("Base.MakeToast") ~= nil, "native fixture recipe missing")
        recipeTrait:addGrantedRecipe("Base.MakeToast")
    end
    print("[OMHTS TEST] native registry " .. definitions:size() .. "; supported positives " .. supported)
    local store = ModData.getOrCreate("OMHTraitShop_State_v1")
    assert(State.initialize(store))
    local descriptor = SurvivorFactory.CreateSurvivor()
    descriptor:setCharacterProfession(CharacterProfession.UNEMPLOYED)
    descriptor:setID(4242)
    local player = IsoPlayer.new(getCell(), descriptor, 0, 0, 0)
    player:setUsername("TraitShopNativeProbe")
    player:setHoursSurvived(0)
    local record = store.accounts["test:phase2"]
    if record then descriptor:setID(record.life.characterId) end
    if not record then
        player:getCharacterTraits():add(CharacterTrait.ALL_THUMBS)
        record = State.attach(store, "test:phase2", 4242, 0)
        assert(Creation.settle(player, record))
        assert(State.update(record, record.life.id, record.revision, { tokens = 1000 }))
        local negativePrice = Catalog.price(Catalog.definition("base:allthumbs"))
        local result = Shop.purchase(player, record, { lifeId = record.life.id, revision = record.revision, items = {
            {id="base:dextrous",price=2,remove=false}, {id="base:allthumbs",price=negativePrice,remove=true},
        }})
        assert(result == "purchased", "native mixed cart failed: " .. tostring(result))
        assert(player:hasTrait(CharacterTrait.DEXTROUS) and not player:hasTrait(CharacterTrait.ALL_THUMBS))
        local id = tostring(skillTrait:getType())
        local price = Catalog.price(skillTrait)
        result = Shop.purchase(player, record, { lifeId = record.life.id, revision = record.revision,
            items = {{id=id,price=price,remove=false}} })
        assert(result == "purchased", "native skill purchase failed: " .. tostring(result))
        local boosts = transformIntoKahluaTable(skillTrait:getXpBoosts())
        for perk, amount in pairs(boosts) do
            amount = tonumber(tostring(amount))
            assert(player:getPerkLevel(perk) == amount and player:getXp():getPerkBoost(perk) == amount,
                "native level/boost differs: " .. tostring(perk))
        end
        if not player:hasTrait(recipeTrait:getType()) then
            result = Shop.purchase(player, record, { lifeId=record.life.id,revision=record.revision,
                items={{id=tostring(recipeTrait:getType()),price=Catalog.price(recipeTrait),remove=false}} })
            assert(result == "purchased", "native recipe purchase failed: " .. tostring(result))
        end
        local recipes = recipeTrait:getGrantedRecipes()
        for index=0,recipes:size()-1 do
            assert(player:getKnownRecipes():contains(recipes:get(index)), "native recipe not learned")
        end
        player:getCharacterTraits():add(CharacterTrait.SMOKER)
        player:getStats():set(CharacterStat.NICOTINE_WITHDRAWAL, 0.5)
        player:setTimeSinceLastSmoke(5)
        result = Shop.purchase(player, record, {lifeId=record.life.id,revision=record.revision,
            items={{id="base:smoker",price=Catalog.price(Catalog.definition("base:smoker")),remove=true}}})
        assert(result == "purchased" and not player:hasTrait(CharacterTrait.SMOKER)
            and player:getStats():get(CharacterStat.NICOTINE_WITHDRAWAL) == 0 and player:getTimeSinceLastSmoke() == 0,
            "native Smoker withdrawal cleanup failed")
        assert(not Shop.reconcile(player, record, false), "native repeat applies bonus twice")
        assert(State.isRecord(record) and Effects.valid(record.life.effects))
        print("[OMHTS TEST] native mixed cart, " .. id .. " skill levels/boosts, recipes and idempotence passed")
        print("[OMHTS TEST] disk stage 1 ready")
    elseif record.life.characterId == 4242 then
        player:getCharacterTraits():add(CharacterTrait.ALL_THUMBS)
        local tokens = record.life.tokens
        assert(Shop.reconcile(player, record, false))
        assert(player:hasTrait(CharacterTrait.DEXTROUS) and not player:hasTrait(CharacterTrait.ALL_THUMBS))
        for id, target in pairs(record.life.effects.perks) do
            local perk = Perks.FromString(id)
            assert(player:getXp():getXP(perk) >= target.xp and player:getXp():getPerkBoost(perk) == target.boost,
                "saved native skill effect not restored")
        end
        for recipe in pairs(record.life.effects.recipes) do assert(player:getKnownRecipes():contains(recipe)) end
        assert(not Shop.reconcile(player, record, false) and record.life.tokens == tokens)
        assert(State.settleDeath(record, record.life.id))
        State.attach(store, "test:phase2", 4243, 0)
        print("[OMHTS TEST] disk receipts restore membership, removal, XP, boosts, recipes without charge")
        print("[OMHTS TEST] disk stage 2 ready")
    else
        assert(record.life.characterId == 4243 and record.life.tokens == 0)
        assert(Creation.settle(player, record) and record.life.tokens == 8)
        assert(not Creation.settle(player, record) and not Shop.reconcile(player, record, false))
        assert(not player:hasTrait(CharacterTrait.DEXTROUS))
        assert(record.life.level == 0 and record.prestige.earned == 0)
        print("[OMHTS TEST] replacement has no inherited effects and exactly eight starting Tokens")
        print("[OMHTS TEST] disk stage 3 ready")
    end
    player:removeFromWorld()
end
Events.OnServerStarted.Add(verifyNativeShop)
