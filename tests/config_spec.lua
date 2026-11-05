-- Panel de opciones (Config.lua) con la API Settings: se registra DESPUÉS de cargar las
-- SavedVariables, queda enlazado a esa misma tabla y cada cambio se guarda y se aplica.
local FakeGame = require("fake_game")

local TOC = "BestFoodDrink.toc"

local function countKeys(t)
    local n = 0
    for _ in pairs(t) do
        n = n + 1
    end
    return n
end

describe("opciones en Settings", function()
    it("no registra nada al cargar los ficheros; sí tras el ADDON_LOADED propio", function()
        local env = FakeGame.envNew()
        env.BestFoodDrinkDB = { schema = 1, preferBuffFood = true }
        local ns = env:LoadToc(TOC) or error("el addon no cargó")
        local registry = env:SettingsRegistry()
        assert.are.equal(0, countKeys(registry.settings))

        env:Fire("ADDON_LOADED", env:AddonName(), false)
        assert.are.equal(3, countKeys(registry.settings))
        assert.are.equal(1, #registry.addOnCategories)
        assert.are.equal(ns.settingsCategory, registry.addOnCategories[1])
        assert.are.equal(ns.L.ADDON_TITLE, ns.settingsCategory:GetName())

        local expected = {
            Enabled = "enabled",
            CreateMacros = "createMacros",
            PreferBuffFood = "preferBuffFood",
        }
        for suffix, key in pairs(expected) do
            local setting = registry.settings[env:AddonName() .. "_" .. suffix]
            assert(setting ~= nil, "falta el ajuste " .. suffix)
            assert.are.equal(env.BestFoodDrinkDB, setting.variableTbl) -- la tabla ya cargada, no otra
            assert.are.equal(key, setting.variableKey)
            assert.are.equal("boolean", setting:GetVariableType())
        end
        -- no pisa lo guardado
        assert.is_true(registry.settings[env:AddonName() .. "_PreferBuffFood"]:GetValue())
    end)

    it("crea una casilla por ajuste", function()
        local env = FakeGame.envBoot(TOC)
        local kinds = {}
        for _, control in ipairs(env:SettingsRegistry().controls) do
            kinds[#kinds + 1] = control.kind
        end
        assert.are.same({ "Checkbox", "Checkbox", "Checkbox" }, kinds)
    end)

    it("cambiar una opción la guarda en las SavedVariables", function()
        local env = FakeGame.envBoot(TOC)
        local settings = env:SettingsRegistry().settings
        settings[env:AddonName() .. "_Enabled"]:SetValue(false)
        assert.is_false(env.BestFoodDrinkDB.enabled)
        settings[env:AddonName() .. "_PreferBuffFood"]:SetValue(true)
        assert.is_true(env.BestFoodDrinkDB.preferBuffFood)
    end)

    it("un valor de otro tipo se rechaza, como en el cliente", function()
        local env = FakeGame.envBoot(TOC)
        local setting = env:SettingsRegistry().settings[env:AddonName() .. "_Enabled"]
        assert.has_error(function()
            setting:SetValue("no")
        end)
        assert.is_true(env.BestFoodDrinkDB.enabled)
    end)
end)
