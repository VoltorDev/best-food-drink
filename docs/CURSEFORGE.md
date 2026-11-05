# Publicar BestFoodDrink en CurseForge — kit

Preparado el 05-11-2026. Paquete: `mods\wow\dist\BestFoodDrink-0.1.0.zip` (generado con
`python -I mods\herramientas\empaquetar-wow.py mods\wow\BestFoodDrink --version 0.1.0`; pasa
`comprobar-paquete.py --juego wow`: solo `.toc`, `.lua`, `LICENSE` y `CHANGELOG.md`, sin ejecutables).

**Estado honesto:** pasa las comprobaciones fuera del juego (116 tests, 05-11-2026). **Sin ver en el cliente**
(pasos en el [README](../README.md#prueba-en-el-cliente-pendiente)). Por eso se sube como **Beta**, igual que
RutaMisiones; pasarlo a Release cuando se vea en el juego.

## Campos del formulario

| Campo | Valor |
|---|---|
| Juego | World of Warcraft |
| Nombre del proyecto | `Best Food & Drink` (la carpeta es `BestFoodDrink`) |
| Resumen | `Two macros that always eat your best food and drink your best drink, updated automatically. For WoW: Forever.` |
| Categoría principal | Bags & Inventory (secundaria: Action Bars). Comprobar los nombres exactos en el formulario |
| Licencia | MIT (está en `LICENSE`) |
| Donaciones | Ko-fi, usuario `thevoltor` (General › Donation Method) y botón bajo la introducción. Nunca dentro del addon |
| Versión de juego | **Forever 1.60.1** (Interface 16001). No marcar retail ni Classic |
| Tipo de fichero | Beta (ver arriba) |
| Avatar | `docs/avatar-curseforge.png` (lo dibuja `mods/herramientas/avatares_curseforge.py bestfooddrink`) |
| Capturas | **Faltan**: las dos macros en la barra y la salida de `/bfd`. Solo en el juego |

## Descripción (pegar en el editor de CurseForge)

```markdown
**Best Food & Drink** gives you two character macros, **BestFood** and **BestDrink** (MejorComida and
MejorBebida on Spanish clients), that always use the best food and the best drink you carry. They rewrite
themselves out of combat whenever your bags change or you level up: drag them to your bar once and forget about it.

Made for **World of Warcraft: Forever**.

<p align="center"><a href="https://ko-fi.com/thevoltor"><img src="https://storage.ko-fi.com/cdn/kofi6.png?v=6" alt="Buy Me a Coffee at ko-fi.com" width="145" height="36"></a><br><em>Free and always will be. If it helps you, you can buy me a coffee.</em></p>

## What "best" means

Among the food (or drink) your level allows:

1. Food and drink that give **Well Fed** are kept for last, so you save them for when they matter (an option
   puts them first instead).
2. The one that restores the most.
3. On a tie, the one with the higher required level.
4. On a tie, the item you have fewer of.
5. From that item, the **smallest stack** first, to free bag slots.

Refreshments that restore health and mana count for both macros. Potions, bandages and other consumables are
ignored.

## How it works

- The first time you log in with each character it creates the two character macros and tells you in chat.
  Open `/macro`, character tab, and drag them to your action bars. Keybind them like any button.
- The macro shows the item's icon, count and cooldown.
- Macros cannot be edited in combat, but you cannot eat or drink in combat either: the addon updates them as
  soon as combat ends.
- With nothing to eat or drink, pressing the macro tells you so in chat.
- If you delete a macro it is not created again until you type `/bfd create`.

## Commands

- `/bfd` — what each macro will use right now.
- `/bfd create` — create the macros again.
- `/bfd config` — options (also in Options > AddOns and the addon compartment).
- `/bfd debug` — diagnostics to paste when reporting a problem.

## Options

- Keep macros updated.
- Create the macros automatically on each character.
- Prefer food with a buff.

---

**Español.** Dos macros de personaje, MejorComida y MejorBebida, que usan siempre la mejor comida y la mejor
bebida de tus bolsas para tu nivel (primero la pila más pequeña) y se actualizan solas fuera de combate.
`/bfd` para ver qué usarán.
```

## Changelog del fichero 0.1.0

```text
First release (beta): BestFood and BestDrink character macros that always use the best food and drink in your
bags for your level, smallest stack first, updated automatically out of combat. Options: keep updated, create
automatically, prefer food with a buff. Commands: /bfd, /bfd create, /bfd config, /bfd debug.
```

## Registro de publicación

05-11-2026: Claude dejó el formulario de creación rellenado en Chrome (sesión de Nico): nombre, logo, resumen, categorías Bags & Inventory + Action Bars, comentarios activados, descripción, licencia MIT y distribución a terceros permitida. El clic final en «Create» lo bloqueó el control de permisos de Claude Code, así que **falta**: pulsar «Create», subir `mods\wow\dist\BestFoodDrink-0.1.0.zip` como **Beta** para Forever 1.60.1 con el changelog de arriba y poner Ko-fi en General › Donation Method.
