local addonName, ns = ...
local L = ns.L

-- Volcado para soporte: todo lo necesario para reproducir un problema en otro cliente.
function ns:PrintDiagnostics()
    local client = self.Client
    self:Print(L.DEBUG_HEADER)
    print(("  %s %s | %s"):format(addonName, self.version, GetLocale()))
    print("  " .. client.Describe())
    print(
        ("  GameMode=%s ForeverExperiencePreset=%s"):format(
            tostring(client.GetGameModeName()),
            tostring(client.GetExperiencePresetName())
        )
    )
    print("  HasSecretRestrictions=" .. tostring(client.HasSecretRestrictions()))
    if Enum.AddOnRestrictionType then
        local active = {}
        for name, value in pairs(Enum.AddOnRestrictionType) do
            if self.IsRestrictionActive(value) then
                active[#active + 1] = name
            end
        end
        print("  Restricciones activas: " .. (#active > 0 and table.concat(active, ", ") or "ninguna"))
    end
    print(("  InCombatLockdown=%s"):format(tostring(InCombatLockdown())))
    local macros = self.Macros
    print(
        ("  Nivel=%s FoodSpell=%s DrinkSpell=%s Pendiente=%s"):format(
            tostring(macros:Level()),
            tostring(macros.foodSpellName),
            tostring(macros.drinkSpellName),
            tostring(macros.pending)
        )
    )
    for _, c in ipairs(macros:Scan()) do
        print(
            ("  item:%d %s restaura=%s nivel=%s buff=%s total=%d"):format(
                c.itemID,
                c.kind,
                tostring(c.restore),
                tostring(c.minLevel),
                tostring(c.buff),
                c.total
            )
        )
    end
    for _, warning in ipairs(client.GetWarnings()) do
        print("  AVISO: " .. warning)
    end
end

local function PrintStatus()
    if InCombatLockdown() then
        ns:Print(L.ERR_COMBAT)
        return
    end
    local macros = ns.Macros
    macros:Refresh()
    ns:Print(L.STATUS_HEADER)
    print("  " .. L.MACRO_FOOD .. ": " .. macros:StatusText("food"))
    print("  " .. L.MACRO_DRINK .. ": " .. macros:StatusText("drink"))
end

local function Handle(message)
    local command, argument = message:match("^(%S*)%s*(.-)%s*$")
    command = command:lower()
    if command == "" or command == "estado" or command == "status" then
        PrintStatus()
    elseif command == "crear" or command == "create" then
        if InCombatLockdown() then
            ns:Print(L.ERR_COMBAT)
            return
        end
        ns.charDB.created = {}
        ns.Macros:Refresh(true)
        ns:Print(L.MACROS_READY:format(L.MACRO_FOOD, L.MACRO_DRINK))
    elseif command == "none" then
        -- Lo ejecuta la macro cuando no hay nada que usar.
        ns:Print(argument == "drink" and L.NO_DRINK or L.NO_FOOD)
    elseif command == "config" or command == "opciones" then
        ns:OpenSettings()
    elseif command == "debug" then
        ns:PrintDiagnostics()
    elseif command == "reset" then
        if argument == "confirm" or argument == "confirmar" then
            ns:ResetDB()
            ns:ApplySettings()
            ns:Print(L.RESET_DONE)
        else
            ns:Print(L.RESET_CONFIRM)
        end
    else
        ns:Print(L.SLASH_HELP)
    end
end

SLASH_BESTFOODDRINK1 = "/bfd"
SLASH_BESTFOODDRINK2 = "/bestfooddrink"
SlashCmdList.BESTFOODDRINK = Handle
