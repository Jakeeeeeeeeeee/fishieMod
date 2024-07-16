local mod = RegisterMod("Jake Mod", 1)
local cowboyHat = Isaac.GetItemIdByName("Dad's Cowboy Hat")
local hfb = Isaac.GetItemIdByName("Happy Fish Boy")

local fishieVariant = Isaac.GetEntityVariantByName("fishie tear")

local floppingFishie = Isaac.GetEntityVariantByName("flopping fishie")


TearVariant.FISHIE = fishieVariant



function mod:EvaluateCache(player, cacheFlags)

    local itemCount = player:GetCollectibleNum(cowboyHat)

    if (cacheFlags & CacheFlag.CACHE_DAMAGE) == CacheFlag.CACHE_DAMAGE then
        player.Damage = player.Damage + itemCount*.5
    end

    if (cacheFlags & CacheFlag.CACHE_LUCK) == CacheFlag.CACHE_LUCK then
        player.Luck = player.Luck + itemCount
    end

    if (cacheFlags & CacheFlag.CACHE_SPEED) == CacheFlag.CACHE_SPEED then
        player.MoveSpeed = player.MoveSpeed + itemCount*.2
    end

    if (cacheFlags & CacheFlag.CACHE_FIREDELAY) == CacheFlag.CACHE_FIREDELAY then
        player.MaxFireDelay = player.MaxFireDelay + itemCount*.5
    end

end

mod:AddCallback(ModCallbacks.MC_EVALUATE_CACHE, mod.EvaluateCache)

local crazyRoulette = Isaac.GetItemIdByName("Crazy Roulette")

local ranPool = -1

function mod:useCrazyRoulette()
    ranPool = math.random(0, ItemPoolType.NUM_ITEMPOOLS - 1)
   
end

mod:AddCallback(ModCallbacks.MC_USE_ITEM, mod.useCrazyRoulette, crazyRoulette)

function mod:OnNewRoom()

   

    if ranPool ~= -1 then
       
        local entities = Isaac:GetRoomEntities()
        
        for i=1, #entities do
            if entities[i].Type == EntityType.ENTITY_PICKUP then
                if entities[i].Variant == PickupVariant.PICKUP_COLLECTIBLE then
                    if entities[i].SubType ~= 0 then
                        local itemPool = Game():GetItemPool()

                        entities[i]:ToPickup():Morph(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_COLLECTIBLE, itemPool:GetCollectible(ranPool), true)
                        Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.POOF01, -1, entities[i].Position, entities[i].Velocity, nil)
                    end
                end
            end
        end
        
         
        
    end

	

end

function mod:initializeFishieTear(data)
	data.FISHIE = true
	data.PreviousSize = 0
	data.hits = 0
end

function mod:isValidTear(spawnerType, spawnerVariant, tearVariant)
	if spawnerType == EntityType.ENTITY_PLAYER and tearVariant ~= EntityType.TEAR_CHAOS_CARD and tearVariant ~= EntityType.TEAR_BOBS_HEAD then
		return true
	elseif spawnerType == EntityType.ENTITY_FAMILIAR and (spawnerVariant == EntityType.FAMILIAR_INCUBUS or spawnerVariant == EntityType.FAMILIAR_FATES_REWARD) then
		return true
	else
		return false
	end
end

function mod:isValidVariant(variant, flags)
	if
	variant == TearVariant.TEAR_TOOTH or
	variant == TearVariant.TEAR_BOBS_HEAD or
	variant == TearVariant.TEAR_CHAOS_CARD or
	variant == TearVariant.TEAR_STONE or
	variant == TearVariant.TEAR_EGG or
	variant == TearVariant.TEAR_RAZOR or
	variant == TearVariant.TEAR_BLACK_TOOTH or
	variant == TearVariant.TEAR_BELIAL or
	variant == TearVariant.TEAR_FIST or
	variant == TearVariant.TEAR_SPORE or
	variant == TearVariant.TEAR_KEY_BLOOD or
	variant == TearVariant.TEAR_ERASER or
	variant == TearVariant.TEAR_GRIDENT or
	variant == TearVariant.TEAR_ROCK then
		return false
	else
		return true
	end
end

function mod:fireFishie(player, fireDirection)

	local velocity = Vector(0,0)
	local shotSpeed = player.ShotSpeed*10
	
	if fireDirection == Direction.DOWN then
		velocity = Vector(0, shotSpeed)
	elseif fireDirection == Direction.UP then
		velocity = Vector(0, -shotSpeed) 
	elseif fireDirection == Direction.LEFT then
		velocity = Vector(-shotSpeed, 0)
	elseif fireDirection == Direction.RIGHT then
		velocity = Vector(shotSpeed, 0)
	end 
	
	local fishieTear = player:FireTear(player.Position, velocity, false, false, false)
	local fishieData = fishieTear:GetData() -- Get tear data
	fishieTear:ChangeVariant(TearVariant.FISHIE)
	mod:initializeFishieTear(fishieData)
	fishieData.DIRECTION = fireDirection
end

function mod:handleFishieTearVariantChanges(tear, data, variant, flags, sprite, player)

	if tear.Variant ~= TearVariant.FISHIE then
		if mod:isValidVariant(variant, flags) then
			tear:ChangeVariant(TearVariant.FISHIE)
			mod:initializeFishieTear(data)
		else
			if not player:HasWeaponType(WeaponType.WEAPON_LUDOVICO_TECHNIQUE) then
				data.FISHIE = false
			end

			tear.SizeMulti = Vector(1,1)
			sprite.Scale = Vector(1,1)
			sprite.Rotation = 0
			sprite.FlipX = false
			sprite.FlipY = false
			tear.Visible = true
		end
	end
end

function mod:setupFishieTear(player, tear, data, variant, flags, sprite)
	
	if mod:isValidTear(tear.SpawnerType, tear.SpawnerVariant, variant) and mod:isValidVariant(variant, flags) then
		tear:ChangeVariant(TearVariant.FISHIE)
		mod:initializeFishieTear(data)
	else
		data.FISHIE = false
	end
end

local fishTears ={}

function mod:updateTearVariant()
	-- Changes tears to Arrow tears and handles updates of the tears
	
	local player = Isaac.GetPlayer(0)
	
	if player:HasCollectible(hfb) then
		local roomEntities = Isaac.GetRoomEntities()
		local fireDirection = player:GetFireDirection()
		local playerData = player:GetData()

		
		if fireDirection ~= -1 then
			if Isaac:GetFrameCount() % (player.MaxFireDelay) == 0 then
				-- mod:fireFishie(player, fireDirection)
			end
		end
		
		local fishieCount = 0

		for i = 1, #roomEntities do
			local entity = roomEntities[i]	
					
			if entity.Type == EntityType.ENTITY_TEAR then
				local tear = entity:ToTear()
				local data = tear:GetData()
				local variant = tear.Variant
				local flags = tear.TearFlags
				local sprite = tear:GetSprite()
				
			    if tear.Variant == TearVariant.FISHIE and data.FISHIE ~= true then
				    mod:initializeFishieTear(data)
			    elseif tear.Variant ~= TearVariant.FISHIE and data.FISHIE == nil then
				    mod:setupFishieTear(player, tear, data, variant, flags, sprite)
			    elseif tear.Variant ~= TearVariant.FISHIE and data.FISHIE == true then
				    mod:handleFishieTearVariantChanges(tear, data, variant, flags, sprite, player)
			    end
				
				

				if tear.Variant == TearVariant.FISHIE then

					table.insert(fishTears, tear)
					
					--Isaac.ConsoleOutput("X: ".. tostring(tear.Velocity.X).."Y: ".. tostring(tear.Velocity.Y))

					if(math.abs(tear.Velocity.X)> math.abs(tear.Velocity.Y)) then
						if(tear.Velocity.X>0) then
							sprite:Play("FlyRight", false); 
						else
							sprite:Play("FlyLeft", false);
						end
					else
						if(tear.Velocity.Y>0) then
							sprite:Play("FlyDown", false);
						else
							sprite:Play("FlyUp", false);
						end
					end

		
				end

			end
		end

		fishTears = {}
	
	end

		
end

local function calculateDistance(vector1, vector2)
	if(vector1 and vector2) then
		local dx = vector2.x - vector1.x
		local dy = vector2.y - vector1.y
		return math.sqrt(dx * dx + dy * dy)
	else
		return 1000
	end
end

function mod:updateFloppers()

	local roomEntities = Isaac.GetRoomEntities()
	local player = Isaac.GetPlayer(0)

	for i = 1, #roomEntities do
		local entity = roomEntities[i]	
		if entity.Variant == floppingFishie then

					
			
			

			local sprite = entity:GetSprite()

			sprite.Offset = Vector(0, -8)

			
			sprite:Play("flop",false)

			entity.GridCollisionClass = EntityGridCollisionClass.GRIDCOLL_GROUND

			if(entity.Velocity.X>0) then
				sprite.FlipX = true
			else
				sprite.FlipX = false
			end

			if (Game():GetFrameCount()%20 ==0) then 
				entity.Velocity=Vector(math.random()*2-1, math.random()*2-1)
			end

			for k = 1, #roomEntities do

				if roomEntities[k].Variant ~= floppingFishie then
					if(calculateDistance(entity.Position, roomEntities[k].Position)<5) then
						roomEntities[k].HitPoints = roomEntities[k].HitPoints - player.Damage
					end
				end
				

			end

			
		end
	end
end

function mod:checkForDeadTears()

	local roomEntities = Isaac.GetRoomEntities()
	for i = 1, #roomEntities do
		local entity = roomEntities[i]	
				
		if entity.Type == EntityType.ENTITY_TEAR then
			local tear = entity:ToTear()
			if tear.Variant == TearVariant.FISHIE then
				if tear:IsDead() then
					Isaac.Spawn(1000,floppingFishie,0,tear.Position,Vector(0,0), nil):ToNPC()
				end
			end
		end
	end
end




-- Add the callback to the mod
mod:AddCallback(ModCallbacks.MC_POST_NEW_ROOM, mod.OnNewRoom)
mod:AddCallback(ModCallbacks.MC_POST_FIRE_TEAR, mod.updateTearVariant)
mod:AddCallback(ModCallbacks.MC_POST_NPC_RENDER, mod.updateFloppers)
mod:AddCallback(ModCallbacks.MC_POST_UPDATE, mod.checkForDeadTears)