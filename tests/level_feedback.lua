testStage = "level feedback"
local shop = OneMoreHordeTraitShop
local originalText = getText
local sounds, halos = {}, {}
function getText(key, value)
    if value then return key .. ":" .. value end
    return key
end
function getSoundManager()
    return { playUISound = function(self, name) sounds[#sounds + 1] = name end }
end
HaloTextHelper = { addText = function(actor, text, separator, r, g, b)
    halos[#halos + 1] = { actor = actor, text = text, r = r, g = g, b = b }
end }

local sides = { "singleplayer", "client" }
for index = 1, #sides do
    testSide = sides[index]
    Events.OnDisconnect.fire()
    sounds, halos = {}, {}
    local actor = player("Feedback", 0, 1234, 0)
    testPlayers = { actor }
    if isClient() then shop.requestState(0, actor) end
    local snapshot = nativeRoundTrip(testSavedSnapshot)
    snapshot.status = "alive"
    snapshot.level = 0
    snapshot.earnedPrestige = 0
    snapshot.revision = 100
    snapshot.effects = { perks = {}, traits = {}, recipes = {} }
    snapshot.nonce = nil
    if isClient() then
        local nonce = testPackets[#testPackets].args.nonce
        shop.acceptState(snapshot)
        snapshot.level = 1
        snapshot.revision = 101
        snapshot.nonce = nonce
        shop.acceptState(snapshot)
        check(#sounds == 0, "initial handshake never celebrates earlier progress")
    else
        shop.acceptState(snapshot)
    end
    check(#sounds == 0, "initial state is quiet: " .. testSide)
    snapshot.nonce = nil
    snapshot.level = snapshot.level + 1
    snapshot.revision = snapshot.revision + 1
    shop.acceptState(snapshot)
    check(#sounds == 1 and sounds[1] == "OMHTS_LevelUp", "normal level uses supplied sound: " .. testSide)
    check(#halos == 1 and halos[1].actor == actor
        and halos[1].text == "UI_OMHTS_LevelUp[br/]UI_OMHTS_LevelUpToken:1"
        and halos[1].r == 231 and halos[1].g == 180 and halos[1].b == 40,
        "level halo belongs to local actor in OMH gold")
    shop.acceptState(snapshot)
    check(#sounds == 1, "duplicate snapshot stays quiet")
    local stale = nativeRoundTrip(snapshot)
    stale.revision = stale.revision - 1
    stale.level = 99
    shop.acceptState(stale)
    check(#sounds == 1, "stale snapshot stays quiet")
    snapshot.level = 10
    snapshot.earnedPrestige = 2
    snapshot.revision = snapshot.revision + 1
    shop.acceptState(snapshot)
    check(#sounds == 2 and sounds[2] == "OMHTS_PrestigeLevelUp" and #halos == 2,
        "multiple levels and prestige milestones use one prestige sound and halo")
    local expectedTokens = 10 - index
    check(halos[2].text == "UI_OMHTS_LevelUp[br/]UI_OMHTS_LevelUpTokens:"
        .. tostring(expectedTokens) .. "[br/]UI_OMHTS_LevelUpPrestige:2",
        "batched reward lines show earned totals independently of wallet balance")
    snapshot.revision = snapshot.revision + 1
    snapshot.tokens = snapshot.tokens + 1
    shop.acceptState(snapshot)
    check(#sounds == 2, "wallet changes do not celebrate")
    actor.dead = true
    snapshot.level = 11
    snapshot.revision = snapshot.revision + 1
    shop.acceptState(snapshot)
    check(#sounds == 2, "dead local actor stays quiet")
    actor.dead = false
    snapshot.status = "dead"
    snapshot.level = 12
    snapshot.revision = snapshot.revision + 1
    shop.acceptState(snapshot)
    check(#sounds == 2, "dead authoritative state stays quiet")
    snapshot.status = "alive"
    snapshot.lifeId = snapshot.lifeId + 1
    snapshot.level = 20
    snapshot.revision = snapshot.revision + 1
    shop.acceptState(snapshot)
    check(#sounds == 2, "new life never celebrates prior progress")
    Events.OnDisconnect.fire()
    shop.acceptState(snapshot)
    check(#sounds == 2, "reconnect remains quiet")
    testPlayers = { player("Replacement", 0, 5678, 0) }
    snapshot.level = 21
    snapshot.revision = snapshot.revision + 1
    shop.acceptState(snapshot)
    check(#sounds == 2, "replacement actor cannot inherit celebration")
end
getText = originalText
Events.OnDisconnect.fire()
testOutput = tostring(testChecks) .. " Phase 1 and level feedback assertions passed."
