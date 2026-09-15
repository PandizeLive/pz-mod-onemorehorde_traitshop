local State = require("OMHTS_State")

local function verifyDiskState()
    local store = ModData.getOrCreate("OMHTraitShop_State_v1")
    assert(State.initialize(store), "phase1 schema failed")
    local key = "test:disk-persistence"
    local record = store.accounts[key]
    if not record then
        record = State.attach(store, key, 123, 5)
        assert(State.update(record, record.life.id, record.revision, { tokens = 37, xp = 2.5, level = 9 }))
        record.prestige.retained = 1
        record.prestige.earned = 2
        print("[OMHTS TEST] disk stage 1 ready")
    elseif record.life.characterId == 123 then
        assert(record.life.tokens == 37 and record.life.xp == 2.5 and record.life.level == 9, "disk wallet mismatch")
        assert(record.prestige.retained == 1 and record.prestige.earned == 2, "disk prestige mismatch")
        assert(State.settleDeath(record, record.life.id))
        assert(not State.settleDeath(record, record.life.id))
        record = State.attach(store, key, 124, 0)
        assert(record.life.tokens == 0 and record.prestige.pending == 3, "replacement settlement mismatch")
        print("[OMHTS TEST] disk stage 2 ready")
    else
        assert(record.life.characterId == 124 and record.life.tokens == 0 and record.life.level == 0 and record.life.xp == 0)
        assert(record.prestige.pending == 3 and record.prestige.retained == 0 and record.prestige.earned == 0)
        print("[OMHTS TEST] disk stage 3 ready")
    end
end

Events.OnServerStarted.Add(verifyDiskState)
