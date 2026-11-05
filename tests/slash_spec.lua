-- Comando /bfd (Slash.lua): opciones, debug, reset con confirmación y ayuda. Lo propio de las
-- macros (estado, crear, none) está en macros_spec.lua.
local FakeGame = require("fake_game")

local TOC = "BestFoodDrink.toc"

local function contains(text, fragment)
    assert(text:find(fragment, 1, true), "no aparece «" .. fragment .. "» en:\n" .. text)
end

describe("/bfd", function()
    local env, ns

    before_each(function()
        env, ns = FakeGame.envBoot(TOC)
        env:ClearPrinted()
    end)

    it("'config' y 'opciones' abren el panel del addon", function()
        env:RunSlash("/bfd config")
        env:RunSlash("/bfd opciones")
        local id = ns.settingsCategory:GetID()
        assert.are.same({ id, id }, env:SettingsRegistry().opened)
    end)

    it("/bestfooddrink es un alias de /bfd", function()
        env:RunSlash("/bestfooddrink config")
        assert.are.same({ ns.settingsCategory:GetID() }, env:SettingsRegistry().opened)
    end)

    it("en combate no abre el panel y lo explica", function()
        env:SetCombat(true)
        env:RunSlash("/bfd config")
        assert.are.same({}, env:SettingsRegistry().opened)
        contains(env:Printed(), ns.L.ERR_COMBAT)
    end)

    it("'debug' imprime el diagnóstico de soporte, sin avisos en Forever", function()
        env:RunSlash("/bfd debug")
        local out = env:Printed()
        contains(out, ns.L.DEBUG_HEADER)
        contains(out, env:AddonName() .. " " .. ns.version .. " | enUS")
        contains(out, "Forever | 1.60.1.70291 Interface 16001 | WOW_PROJECT_ID=18")
        contains(out, "HasSecretRestrictions=true")
        contains(out, "Restricciones activas: ninguna")
        contains(out, "Nivel=7 FoodSpell=Food DrinkSpell=Drink")
        assert.is_nil(out:find("AVISO", 1, true))
    end)

    it("'reset' sin confirmar no toca nada y explica cómo confirmar", function()
        env.BestFoodDrinkDB.preferBuffFood = true
        env:RunSlash("/bfd reset")
        assert.is_true(env.BestFoodDrinkDB.preferBuffFood)
        contains(env:Printed(), ns.L.RESET_CONFIRM)
    end)

    it("'reset confirm' y 'reset confirmar' restauran los valores por defecto", function()
        for _, word in ipairs({ "confirm", "confirmar" }) do
            env.BestFoodDrinkDB.preferBuffFood = true
            env:RunSlash("/bfd reset " .. word)
            assert.are.same(ns.DEFAULTS, env.BestFoodDrinkDB)
            contains(env:Printed(), ns.L.RESET_DONE)
        end
        -- La misma tabla: los ajustes de Settings siguen enlazados a ella.
        assert.are.equal(env.BestFoodDrinkDB, ns.db)
    end)

    it("un subcomando desconocido muestra la ayuda", function()
        env:RunSlash("/bfd foo")
        contains(env:Printed(), ns.L.SLASH_HELP)
    end)

    it("no distingue mayúsculas en el comando ni en el subcomando", function()
        env:RunSlash("/BFD DEBUG")
        contains(env:Printed(), ns.L.DEBUG_HEADER)
    end)

    it("en un cliente en español responde en español", function()
        local envES, nsES = FakeGame.envBoot(TOC, { locale = "esES" })
        envES:RunSlash("/bfd reset")
        contains(envES:Printed(), nsES.L.RESET_CONFIRM)
        contains(nsES.L.RESET_CONFIRM, "/bfd reset confirmar")
    end)
end)
