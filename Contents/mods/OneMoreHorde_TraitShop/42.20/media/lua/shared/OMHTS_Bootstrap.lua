local existing = rawget(_G, "OneMoreHordeTraitShop")
if existing then return existing end

local TraitShop = {
    MOD_ID = "OneMoreHorde_TraitShop",
    VERSION = "0.5.0",
    CHECKPOINT = 5,
}
OneMoreHordeTraitShop = TraitShop

if isClient() then
    print("[OMH Trait Shop] v0.5.0 shared loaded: multiplayer-client")
elseif isServer() then
    print("[OMH Trait Shop] v0.5.0 shared loaded: server")
else
    print("[OMH Trait Shop] v0.5.0 shared loaded: singleplayer")
end

return TraitShop
