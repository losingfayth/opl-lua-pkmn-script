--[[
	Pokémon FireRed & LeafGreen Dynamic Difficulty Script with Lua

		This project aims to increase the difficulty of the GameBoy Advance
		Pokémon games FireRed and LeafGreen using an emulator that supports
		Lua scripting.

		The emulator being used is Visual Boy Advance Re-Recording.

		The script works by checking to see whether or not the player has begun
		an encounter, then increasing the level and stats of the opposing
		Pokémon.

	authors: zachary hunter and fayth quinn
--]]

--- Memory Offsets
OPP_START = 0x0202402C -- The offset for the opponent
PLR_START = 0x02024284 -- The offset for the player

OFFSETS = {
	LVL = 84,	-- The offset from START to the Pokémon's level
	HP = 86,	-- The offset from START to the Pokémon's current HP
	ATT = 90,	-- The offset from START to the Pokémon's Attack stat
	DEF = 92,	-- The offset from START to the Pokémon's Defense stat
	SPE = 94,	-- The offset from START to the Pokémon's Speed stat
	SPA = 96,	-- The offset from START to the Pokémon's Special Attack stat
	SPD = 98	-- The offset from START to the Pokémon's Special Defense stat
}

CURR_EN = 0 -- The value of the current encounter

LVL_STEP = 10	-- The level value to add
STAT_STEP = 20	-- The stat value to multiply by

--[[
	Emulator Classes & Methods
		memory - An object representing the virtualized GameBoy Advance memory
			-- readwordunsigned(addr)	- Returns the word at the given memory
										address `addr`
			-- writeword(addr, val)		- Writes the given value `val` to 
										the memory address `addr`

		emu - An object representing the emulator state
			-- frameadvance()			- Progresses the emulation forward
--]]


--- ArrSum
--- @param arr table	- A table of numbers
--- @return	number		- The sum of all numbers in the given array
function ArrSum(arr)

	local sum = 0

	for i = 1, #arr do
		sum = sum + arr[i]
	end

	return sum
	
end

--- Fetch HP
--
-- Retrieves the current HP values for every member of the team that begins at
-- the given offset.
-- 
-- In Lua, all objects are passed by value, not by reference, making functions
-- like this impossible. However, a table (Lua's not-quite equivilent to a list)
-- is passed by value in such a way that allows the table to be modified.
--
--- @param offset number	- The offset for the player or the opponent
--- @param arr table		- The array of HP values associated with that offset
local function fetch_hp(offset, arr)

	for i = 1, 6 do
		arr[i] = memory.readwordunsigned(offset + OFFSETS.HP + 100 * (i - 1))
	end

end

--- Mod Stats
--
-- Modifies the stats and level of a given Pokémon
--
-- Utilizes a generic `for` loop
--
--- @param idx number The index number for the Pokemon to modify
local function mod_stats(idx)

	for label, stat in pairs(OFFSETS) do

		if label == "LVL" then

			memory.writeword(OPP_START + stat + idx, memory.readwordunsigned(OPP_START + stat + idx) + LVL_STEP)

		elseif label ~= "HP" then

			memory.writeword(OPP_START + stat + idx, memory.readwordunsigned(OPP_START + stat + idx) * STAT_STEP)

		end

	end

end


-- Repeat this code continuously
while true do
	
	-- Check to see if the encounter currently ongoing has already been worked on
	if CURR_EN ~= memory.readwordunsigned(OPP_START) then

		-- Start the encounter
		CURR_EN = memory.readwordunsigned(OPP_START)
		
		local plr_hp = {}
		fetch_hp(PLR_START, plr_hp)

		local opp_hp = {}
		fetch_hp(OPP_START, opp_hp)

		-- Increase the stats for all non-fainted party members
		for i = 0, 5 do
			
			local idx = 100 * i -- The additional offset for whichever party 
								-- member is being modified
			
			if opp_hp[i + 1] > 0 then

				-- Call stat mod function
				mod_stats(i)

			end

		end

		--- Lua has block-level scoping for most loops. `repeat` is the exception
		-- While the current battle is going on
		-- (Neither the player or the opponent are out of Pokemon)
		repeat

			-- Is this the same encounter? If not, leave
			if CURR_EN ~= memory.readwordunsigned(OPP_START) then break end

			-- Otherwise, update the HP values
			fetch_hp(PLR_START, plr_hp)
			fetch_hp(OPP_START, opp_hp)

			-- Did either party lose? If so, the current encounter is over
			if ArrSum(plr_hp) == 0 or ArrSum(opp_hp) == 0 then CURR_EN = 0 end

			-- Progress the emulation
			emu.frameadvance()

		until ArrSum(plr_hp) <= 0 or ArrSum(opp_hp) <= 0

	end

	-- Progress the emulation
	emu.frameadvance()

end