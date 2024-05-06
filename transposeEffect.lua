local bs = require("BeefStranger.functions")
local effectMaker = require("BeefStranger.effectMaker")
local logger = require("logging.logger")
local log = logger.getLogger("Transpose") or "Logger Not Found"

--Necessary? No but i need to learn tables
local looseItems = {
    [tes3.objectType.armor] = true,
    [tes3.objectType.book] = true,
    [tes3.objectType.miscItem] = true,
    [tes3.objectType.weapon] = true,
}
--Necessary? No but i need to learn tables
local hasInventory = {
    [tes3.objectType.container] = true,
    [tes3.objectType.creature] = true,
    [tes3.objectType.npc] = true,
}
--Necessary? No but i need to learn tables
local iterateRefs = {
    tes3.objectType.armor,
    tes3.objectType.book,
    tes3.objectType.container,
    tes3.objectType.creature,
    tes3.objectType.ingredient,
    tes3.objectType.miscItem,
    tes3.objectType.npc,
    tes3.objectType.weapon,
}


local function transfer(ref) --Just a little function to tranfer/play effect
    tes3.transferInventory({from = ref, to = tes3.mobilePlayer})
    tes3.createVisualEffect({ lifespan = 1, reference = ref, magicEffectId = 23336, })
end

tes3.claimSpellEffectId("bsTranspose", 23336)
--Loot items from near collision
---@param e tes3magicEffectCollisionEventData
local function onTranspose(e)
    if e.collision then
        local effect = bs.getEffect(e, 23336)
        if effect == nil then return end

        local closest = nil --Variable for storing the nearest item if nothing was in range

        for ref in e.collision.colliderRef.cell:iterateReferences(iterateRefs) do --Set ref to every object in cell, that matches a type in iterateRefs table

            local distance = (e.collision.point:distance(ref.position) / 22.1)    --The distance between the collision point and the position of the iterated ref
            local range = math.max(effect.radius, 1.5)                            --Range is either the effect radius or 1.5, whatever is bigger
            --Check Variables--
            local inRange = (distance <= range)                                   --Returns true if distance to ref is in range of the spell
            local isInventory = hasInventory[ref.object.objectType]                 --Boolean if ref objectType is in containers table
            local isNPC = (ref.object.objectType == tes3.objectType.npc) or (ref.object.objectType == tes3.objectType.creature)         --Boolean if ref is NPC or not
            local noScript = ref.object.script == nil                             --True if ref does not have a script attached
            local looseItem = looseItems[ref.object.objectType]                   --Boolean if ref objectType is in looseItems table

            -- log:debug("%s : %s, %s", container.object.name, distance, inRange)

         ------------------------Just disabled for testing---------------------------------------------------------------
            if inRange and noScript then --Only apply for containers within effects radius
                local owned = tes3.getOwner({reference = ref}) --tes3.getOwner({ reference = container }) == nil
                -- log:debug("Container - %s, Owned = %s, distance - %s, radius - %s", ref.object.name,owned, (distance), effect.radius)

                if not owned and (isInventory and #ref.object.inventory > 0) --[[ and container.lockNode.trap == nil and container.lockNode.locked == false ]] then
                    tes3.messageBox("%s not owned", ref.object.name)

                    if ref.lockNode then
                        if ref.lockNode.trap or ref.lockNode.locked then
                            log:debug("%s is locked/trapped", ref.object.name)
                            goto skip
                        end
                    else
                        log:debug("not locked/trapped proceeding")
                    end

                    if isNPC then
                        if ref.mobile.isDead == false then
                            log:debug("%s not dead skipping", ref.object.name)
                            goto skip
                        end
                    end

                    transfer(ref)

                    -- tes3.transferInventory({ from = ref, to = tes3.mobilePlayer})
                    -- tes3.createVisualEffect({ lifespan = 1, reference = ref, magicEffectId = 23336, })
                    log:debug("Looting - %s, distance - %s, spellRadius - %s", ref.object.name, (distance), effect.radius)

                    ----------------CONTINUE HERE FOR SKIP--------------------------
                    ::skip::
                    ----------------------------------------------------------------
                end

            else
                tes3.createVisualEffect({ lifespan = 1, reference = ref, magicEffectId = 23336, })
            --  -------------------------------------------------------------------------------------------------------------------------------
            --     if owned then
            --         -- tes3.messageBox("%s IS owned by %s", ref.object.name, tes3.getOwner({reference = ref}))
            --         tes3.createVisualEffect({ lifespan = 1, reference = ref, magicEffectId = 23336, })
            --     end
            end

            if not inRange and noScript then --If the spell has an area of 0 then it doesnt tend to actually collide with the object
                if distance <= 5 then --If nothing was found within 1.5ft, grab things under 5ft
                    if closest == nil or distance < e.collision.point:distance(ref.position) / 22.1 then --if object is within 5ft or closer than previous found
                        if (isInventory and #ref.object.inventory > 0) then --If object is in container type table and has something in inventory
                            -- log:debug("type - %s, isDead - %s",(ref.object.objectType == tes3.objectType.npc), ref.mobile.isDead)
                            if isNPC and ref.mobile.isDead then --If its a npc and dead
                                closest = ref
                                log:debug("NPC")
                                transfer(closest)
                                return
                            elseif not isNPC then
                                closest = ref
                                log:debug("looting closest - %s, %s", closest.object.name, distance)
                                transfer(closest)
                                return
                            end
                        end

                        if looseItem and ref.deleted == false then
                            closest = ref
                            if closest.object.name == "Gold" then --Gold piles dont work right, so i have to do this
                                tes3.addItem({reference = tes3.mobilePlayer, item = closest.object, count = closest.object.value})
                                log:debug("Looting Loose nearest %s - %s", closest.object.id, closest.object.value)
                                closest:delete()
                                return
                            else --Add the item to the player, then delete the item
                                tes3.addItem({reference = tes3.mobilePlayer, item = closest.object, count = closest.stackSize})
                                log:debug("Looting Loose nearest - %s, %s, distance - %s, spellRadius - %s", closest.object.name, closest.stackSize, (distance), effect.radius)
                                closest:delete()
                                return
                            end
                        end
                    end
                end
            end
         ------------------------------------------------------------------------------------------------------------------------------
            if inRange and noScript and looseItem and (ref.deleted == false) then
                if ref.object.name == "Gold" then --Gold piles dont work right, so i have to do this
                    tes3.addItem({reference = tes3.mobilePlayer, item = ref.object, count = ref.object.value})
                    log:debug("Looting Loose Gold - %s - %s", ref.object.id, ref.object.value)
                    ref:delete()
                else --Add the item to the player, then delete the item
                    tes3.addItem({reference = tes3.mobilePlayer, item = ref.object, count = ref.stackSize})
                    log:debug("Looting Loose - %s, %s, distance - %s, spellRadius - %s", ref.object.name, ref.stackSize, (distance), effect.radius)
                    ref:delete()
                end
            end
        end
    end
end


local function addEffects()
    local bsTranspose = effectMaker.create({
        id = tes3.effect.bsTranspose,
        name = "Transposistion",
        school = tes3.magicSchool["mysticism"],

        baseCost = 10,
        speed = 3,

        allowSpellmaking = true,
        canCastSelf = false,
        onCollision = onTranspose
    })
end
event.register("magicEffectsResolved", addEffects)