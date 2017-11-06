pico-8 cartridge // http://www.pico-8.com
version 8
__lua__
--alphastorm beta
--nikhita jayaprakash


-- math library
function m_dist(x1, y1, x2, y2)
	local y_comp = y2 - y1
	local x_comp = x2 - x1
	local sqr_dist = x_comp^2 + y_comp^2
	return sqrt(sqr_dist)
end

-------------------------------------
----------- graphics library ----------
-------------------------------------

fades={
	{1,1,1,1,0,0,0,0},
	{2,2,2,1,1,0,0,0},
	{3,3,4,5,2,1,1,0},
	{4,4,2,2,1,1,1,0},
	{5,5,2,2,1,1,1,0},
	{6,6,13,5,2,1,1,0},
	{7,7,6,13,5,2,1,0},
	{8,8,9,4,5,2,1,0},
	{9,9,4,5,2,1,1,0},
	{10,15,9,4,5,2,1,0},
	{11,11,3,4,5,2,1,0},
	{12,12,13,5,5,2,1,0},
	{13,13,5,5,2,1,1,0},
	{14,9,9,4,5,2,1,0},
	{15,14,9,4,5,2,1,0}
}

function fade(intensity)
	for i=1,15 do
		pal(i, fades[i][intensity], 0)
	end
end


-------------------------------------
----------- vector library ----------
-------------------------------------

function v_init(x,y)
	local v1 = {}
	v1.x = x
	v1.y = y
	return v1
end

function v_add(v1,v2)
	return v_init(v1.x + v2.x, v1.y + v2.y)
end

function v_sub(v1,v2)
	return v_init(v1.x - v2.x, v1.y - v2.y)
end

function v_div(v1, s)
	if(s != 0) then
		return v_init(v1.x / s, v1.y / s)
	end

	return v1
end

function v_mul(v1, s)
	return v_init(v1.x * s, v1.y * s)
end

function v_mag(v1)
	return sqrt((v1.x * v1.x) + (v1.y * v1.y))
end

function v_dist(v1, v2)
	dist = sqrt((v1.x-v2.x)^2 + (v1.y-v2.y)^2)
	if(dist < 0 or dist > 32000) then
		return 32000
	end
	return dist
end

function v_clamp(v1, max_mag)
	if(v_mag(v1) > max_mag) then
		v1 = v_norm(v1)
		v1 = v_mul(v1, max_mag)
	end
	return v1
end

function v_norm(v1)
	if(v_mag(v1) != 0) then
		return v_div(v1, v_mag(v1))
	end
	return nil
end

function v_str(v1)
	return "("..v1.x..","..v1.y..")"
end

function v_print(v1)
	print(v_str(v1))
end

function v_dot(v1,v2)
	return v1.x*v2.x+v1.y*v2.y
end

function v_cross(v1,v2)
	return v1.x*v2.x-v1.y*v2.y
end

function v_angle(v1,v2)
	return atan2(v_cross(v1,v2), v_dot(v1,v2))
end

-- debug library
deb_mode_on = false
deb_states = {"normal","step", "slowmo"}
deb_curt_state = 1
deb_frame_timer = 0

deb_log_buffer = {}
deb_text_buffer = {}
deb_rect_buffer = {}

function deb_start()
	deb_frame_timer = 0
	deb_mode_on = not deb_mode_on
end

function deb_log(msg)
	add(deb_log_buffer, msg)
end

function deb_text(msg, x, y)
	local text_entry = {}
	text_entry.msg = msg
	text_entry.x = x
	text_entry.y = y
	add(deb_text_buffer, text_entry)
end

function deb_rect(x1, y1, x2, y2)
	local rect_entry = {}
	rect_entry.x1 = x1
	rect_entry.y1 = y1
	rect_entry.x2 = x2
	rect_entry.y2 = y2
	add(deb_rect_buffer, rect_entry)
end

function deb_clear_buffers()
	deb_text_buffer = {}
	deb_rect_buffer = {}
	deb_log_buffer  = {}
end

-- physics library
gravity  = v_init(0, 0.5)
air_fric = 0.01
grd_fric = 0.3


function phy_aabb_collide(pos_a, a, pos_b, b)
	if(pos_a.x + a.max.x < pos_b.x + b.min.x or
	   pos_b.x + b.max.x < pos_a.x + a.min.x) then
		return false
	end

	if(pos_a.y + a.max.y < pos_b.y + b.min.y or
	   pos_b.y + b.max.y < pos_a.y + a.min.y) then
		return false
	end

	return true
end

function phy_aabb_init(x,y,w,h)
	local aabb = {}
	aabb.w = w
	aabb.h = h
	aabb.min = v_init(x,y)
	aabb.max = v_init(x+w,y+h)
	return aabb
end

function phy_apply_force(obj, f)
	obj.acc.x += f.x/obj.mass
	obj.acc.y += f.y/obj.mass
end

function phy_screen_to_map(pos)
	return v_div(pos, 8)
end

function phy_map_to_screen(pos)
	return v_mul(pos, 8)
end

function phy_update(obj)

	-- apply gravity
	if(obj.grav) then
	 if(obj == player and (player.s == 5 or player.s == 8 or player.s == 10 or player.s == 12 or player.s == 21)) then
	  gravity = v_init(0, 0.2)
	 end
	 local f_gravity = v_mul(gravity, obj.mass)
	 phy_apply_force(obj, f_gravity)
  gravity = v_init(0, 0.5)
 end
 -- apply ground friction
	if(obj.is_on_ground) then
		phy_apply_friction(obj)
	end

 deb_text(""..obj.vel.x.." ,"..obj.vel.y, obj.pos.x, obj.pos.y - 10)

	obj.vel = v_add(obj.vel, obj.acc)

	if(abs(obj.vel.x) > 0) then
		phy_check_horz_coll(obj)
	end

	if(abs(obj.vel.y) > 0) then
		phy_check_vert_coll(obj)
	end

	obj.pos = v_add(obj.pos, obj.vel)
	obj.acc = v_init(0, 0)
end

function phy_is_solid(x, y)
	local value = mget(x, y)
	return fget(value, 0)
end

function phy_check_horz_coll(obj)

	local proj_pos = v_init(obj.pos.x + obj.vel.x, obj.pos.y)

	local side = sgn(obj.vel.x)

	local t_corner = v_init(proj_pos.x, proj_pos.y)
	if(side == 1) then
		t_corner.x += 7
	end

	local b_corner = v_init(proj_pos.x, proj_pos.y + 7)
	if(side == 1) then
		b_corner.x += 7
	end

	-- transform world pos of both corners to map pos
	local t_map_pos = v_div(t_corner,8)
	local b_map_pos = v_div(b_corner,8)

	-- check in the map if the value in both map pos are solid
	if(phy_is_solid(t_map_pos.x, t_map_pos.y) or
	   phy_is_solid(b_map_pos.x, b_map_pos.y)) then
	   obj.vel.x = 0
		   obj.pos.x = (flr(t_map_pos.x) - side) * 8
		   if ((obj.s == 28 or obj.s == 29)) then
		      obj.right = not obj.right
		      if (obj.right) then
		         obj.pos.x += 4
		      else
		         obj.pos.x -= 4
		      end
		   end

		   if ((mget(t_map_pos.x, t_map_pos.y) == 36 or
		       mget(b_map_pos.y, b_map_pos.y) == 36) and obj==player) then
		       player.imeter -= 1
		   end
		   if ((mget(t_map_pos.x, t_map_pos.y) == 33 or
		       mget(b_map_pos.y, b_map_pos.y) == 33) and obj==player) then
		       player.imeter -= 3
		   end
		   if (((mget(t_map_pos.x, t_map_pos.y) == 35 or
		       mget(b_map_pos.y, b_map_pos.y) == 35)and obj==player and player.invincibility <= 0) and
		       g_timer % 15 == 0) then
		       player.imeter -= 1;
		   end
		   if ((mget(t_map_pos.x, t_map_pos.y) == 49 or
		       mget(b_map_pos.y, b_map_pos.y) == 49)and obj==player) then
		      --win = true
		      level += 1
		      if (level == 1) then
		         player.pos.x = 8
		         player.pos.y = 216
		      elseif (level == 2) then
		         player.pos.x = 408
		         player.pos.y = 24
		      elseif (level == 3) then
		         player.pos.x = 408
		         player.pos.y = 176
		      elseif (level == 4) then
		            win = true
		      end
		   end
		   if ((mget(t_map_pos.x, t_map_pos.y) == 50 or
		       mget(b_map_pos.y, b_map_pos.y) == 50)and obj==player) then
		       fall_end = true
		   end

	end

end

function phy_check_vert_coll(obj)

	-- project our vert position
	local proj_pos = v_init(obj.pos.x, obj.pos.y + obj.vel.y)
	local b_proj_pos = v_init(obj.pos.x, obj.pos.y + obj.vel.y+7)

	-- find to which vert side i am going
	local side = sgn(obj.vel.y)

	-- find both corners on that side
	local l_corner = v_init(proj_pos.x, proj_pos.y)
	local bl_corner = v_init(b_proj_pos.x, b_proj_pos.y)

	if(side == 1) then
		l_corner.y += 7
		bl_corner.y += 7
	end

 local br_corner = v_init(b_proj_pos.x+7, b_proj_pos.y)
	local r_corner = v_init(proj_pos.x + 7, proj_pos.y)
	if(side == 1) then
		r_corner.y += 7
		br_corner.y += 7
	end

	-- transform world pos of both corners to map pos
	local l_map_pos = v_div(l_corner,8)
	local r_map_pos = v_div(r_corner,8)
	local bl_map_pos = v_div(bl_corner,8)
	local br_map_pos = v_div(br_corner,8)

 --assuming obj not on ground

 obj.is_on_ground = false

	-- check in the map if the value in both map pos are solid
	if(phy_is_solid(l_map_pos.x, l_map_pos.y) or
	   phy_is_solid(r_map_pos.x, r_map_pos.y)) then
		   obj.vel.y = 0
		   obj.pos.y = (flr(l_map_pos.y) - side) * 8
		   obj.is_on_ground = true
		   if ((mget(l_map_pos.x, l_map_pos.y) == 36 or
		       mget(r_map_pos.y, r_map_pos.y) == 36)and obj==player) then
		       player.imeter -= 1;
		   end
		   if ((mget(l_map_pos.x, l_map_pos.y) == 33 or
		       mget(r_map_pos.y, r_map_pos.y) == 33)and obj==player) then
		       player.imeter -= 3;
		   end
		   if (((mget(l_map_pos.x, l_map_pos.y) == 35 or
		       mget(r_map_pos.y, r_map_pos.y) == 35)and obj==player) and
		       g_timer % 15 == 0 and  player.invincibility <= 0) then
		       player.imeter -= 1;
		   end
		   if ((mget(l_map_pos.x, l_map_pos.y) == 49 or
		       mget(r_map_pos.y, r_map_pos.y) == 49)and obj==player) then
		       --win = true
		       level += 1
		       if (level == 1) then
		         player.pos.x = 8
		         player.pos.y = 216
		       elseif (level == 2) then
		         player.pos.x = 408
		         player.pos.y = 24
		       elseif (level == 3) then
		         player.pos.x = 408
		         player.pos.y = 176
		       elseif (level == 4) then
		             win = true
		       end
		   end
		   if ((mget(l_map_pos.x, l_map_pos.y) == 50 or
		       mget(r_map_pos.y, r_map_pos.y) == 50)and obj==player) then
		       fall_end = true
		   end

	end
if(((phy_is_solid(bl_map_pos.x,bl_map_pos.y) == false) or
	   (phy_is_solid(br_map_pos.x, br_map_pos.y)== false)) and
	  (obj.s ==28 or obj.s == 29)) then
	  obj.right = not obj.right

	  if (obj.right) then
		    obj.pos.x += 4
		   else
		    obj.pos.x -= 4
		 end
	end

end

function phy_apply_friction(obj)
	if (obj == nil) then
		 --print("error: obj is nil", camera_pos.x, camera_pos.y + 80, 2)
		 working = 1
		 return
	elseif (obj.vel.x == nil) then
		 --print("error: obj.vel.x is nil", camera_pos.x, camera_pos.y+80, 2)
		 working = 2
		 return
	--else
		 --if (deb_mode_on) then
		   --print("it's working for now", camera_pos.x, camera_pos.y+80, 2)
		--end
  end
	if((v_mag(obj.vel) != 0) and (abs(obj.vel.x) > 0)) then
		if ((v_norm(obj.vel).x) == nil) then
			 return
		else
			 if (v_norm(obj.vel).x * (-1) == nil) then
				  return
			else
		      local n_vel_x = v_norm(obj.vel).x * (-1)
		      local fric = v_init(n_vel_x * grd_fric, 0)
		      phy_apply_force(obj, fric)
			end
	 end
  end
end


-- main game

function obj_init(pos, s, mass, collider, grav)
	local game_obj = {}
	game_obj.s    = s
	game_obj.pos  = pos
	game_obj.vel  = v_init(0,0)
	game_obj.acc  = v_init(0,0)
	game_obj.mass = mass
	game_obj.box  = collider
	game_obj.is_on_ground = true
	game_obj.grav = grav
	return game_obj
end

function _init()

 main = true
 inst = false
 bkstory = false
 fall_end = false
 c_end = false
 win = false
 f_timer = 0
 f_increase = false
	enemies = {}
	powerups = {}
	pulses = {}
	p_b_deleted = {}
	e_b_deleted = {}
	b_b_deleted = {}
	g_timer = 0
	scorev = 0
	scored = 0
	level = 0
	deb_clear_timer = 59
	working = 0

	-- player position
	for x=0,128 do
		for y=0,128 do
			local m_tile = mget(x,y)

			local pos = phy_map_to_screen(v_init(x,y))

			-- sprites 1-27 could be the player
			-- i'm going to randomize it for now
			if(m_tile == 1) then

		 	local col = phy_aabb_init(0,0,8,8)
				local ps = flr(rnd(26)) + 1
				if (ps >= 16) ps +=1
				player = obj_init(pos, ps, 1, col, true)
				player.spedup = 0
				player.highjump = 0
				player.etimer = 0
				player.invincibility = 0
				player.vtimer = 0
				player.mtimer = 0
				player.jtimer = 0
				player.btimer = 0
				player.ed = 0
				-- should be called integrity meter?
				player.imeter = 10


				mset(x,y,45)

			-- sprites 28-31 could be the enemy
			elseif(m_tile == 28 or m_tile == 29 or m_tile == 30 or m_tile == 31) then
				local col = phy_aabb_init(0,0,8,8)
				local enemy = obj_init(pos, m_tile, 1, col, true)
			 enemy.stime = 0
			 local rndc = flr(rnd(4))
			 --very approximate english letter frequency
			 --from http://en.algoritmy.net/article/40379/letter-frequency-english
			 local rndl = flr(rnd(105))+1
			 local t = 0
			 if (rndl >= 1 and rndl <= 8) then
			    t = 1
			 elseif (rndl >= 9 and rndl <= 10) then
			    t = 2
			 elseif (rndl >= 11 and rndl <= 14) then
			    t = 3
			 elseif (rndl >= 15 and rndl <= 18) then
			    t = 4
			 elseif (rndl >= 19 and rndl <= 31) then
			    t = 5
			 elseif (rndl >= 32 and rndl <= 33) then
			    t = 6
			 elseif (rndl >= 34 and rndl <= 35) then
			    t = 7
			 elseif (rndl >= 36 and rndl <= 41) then
			    t = 8
			 elseif (rndl >= 42 and rndl <= 48) then
			    t = 9
			 elseif (rndl == 49) then
			    t = 10
			 elseif (rndl == 50) then
			    t = 11
			 elseif (rndl >= 51 and rndl <= 54) then
			    t = 12
			 elseif (rndl >= 54 and rndl <= 56) then
			    t = 13
			 elseif (rndl >= 57 and rndl <= 63) then
			    t = 14
			 elseif (rndl >= 64 and rndl <= 71) then
			    t = 15
			 elseif (rndl >= 72 and rndl <= 73) then
			    t = 17
			 elseif (rndl == 74) then
			    t = 18
			 elseif (rndl >= 75 and rndl <= 80) then
			    t = 19
			 elseif (rndl >= 81 and rndl <= 86) then
			    t = 20
			 elseif (rndl >= 87 and rndl <= 95) then
			    t = 21
			 elseif (rndl >= 96 and rndl <= 98) then
			    t = 22
			 elseif (rndl == 99) then
			    t = 23
		 	elseif (rndl >= 100 and rndl <= 101) then
			    t = 24
			 elseif (rndl == 102) then
			    t = 25
			 elseif (rndl >= 103 and rndl <= 104) then
			    t = 26
			 elseif (rndl == 105) then
			    t = 27
			 end

			 if (m_tile == 28) then
				 enemy.mc = 3 + rndc
				 enemy.d = 4
				 enemy.les = t
				elseif (m_tile == 29) then
				 enemy.mc = 1 + rndc
				 enemy.d = 2
				 enemy.les = t
			 elseif (m_tile == 30) then
				 enemy.mc = 4 + rndc
				 enemy.d = 2
				 enemy.grav = false
				else
				 enemy.mc = 6 + rndc
				 enemy.d = 5
				 enemy.grav = false
			 end
			 enemy.cmeter = enemy.mc
				enemy.right = false
				add(enemies, enemy)
				mset(x,y,45)

			--sprites 40 or 43-44 or 46 could be the powerups
			elseif(m_tile == 40 or m_tile == 43 or m_tile == 44 or m_tile == 46) then
				local col = phy_aabb_init(0,0,8,8)
				local powerup = obj_init(pos, m_tile, 1, col, false)
				add(powerups, powerup)
				mset(x,y,45)

			--boss
			--[[elseif(m_tile == 38) then
			     local col = phy_aabb_init(0,0,8,8)
			     boss = obj_init(pos, m_tile, 1, col, false)
			     boss.mc = 20
			     boss.cmeter = boss.mc
			     boss.d = 10
			     mset(x,y,45)
			     mset(x+1, y, 45)
			     mset(x, y+1, 45)
			     mset(x+1, y+1, 45)]]--
		 end
		end
	end
	-- create a menu item
	menuitem(1,"debug mode",deb_start)

	camera_pos = v_init(0,0)

end

function _update()
 if (fall_end == false and c_end == false and win == false and main == false and bkstory == false) then
    if (btnp(1,1)) then
      f_increase = true
    end
    if(f_increase) then
     f_timer += 1
     fade(f_timer)
      if (f_timer == 15) then
       inst = not inst
       f_timer = 0
       fade(1)
       f_increase = false
      end
    end
 end
 if (fall_end == false and c_end == false and win == false and main == false and inst == false and bkstory == false) then


 	if(deb_mode_on) then

		-- enable the cursor
		poke(0x5f2d, 1)

		-- if in debug mode, change debug state to slowmo if player presses a
		if(btnp(5,1)) then
			deb_curt_state += 1
			if(deb_curt_state > #deb_states) then
				deb_curt_state = 1
			end
		end

		if(deb_states[deb_curt_state] == "normal") then
			-- if in debug mode normal, call update normally
			__update()
		elseif(deb_states[deb_curt_state] == "step") then
			-- if in debug mode step, call update whenever player presses key a
			if(btnp(0,1)) then
				__update()
			end
		elseif(deb_states[deb_curt_state] == "slowmo") then
			-- if in debug mode slowmo, call update after every 10th frame
			deb_frame_timer += 1
			if(deb_frame_timer > 5) then
				__update()
				deb_frame_timer = 0
			end
		end

	else
		-- disable the cursor
		poke(0x5f2d, 0)

		-- if not in debug mode, just update game normally
		__update()
	 end
	elseif (fall_end or c_end or win) then
	--game has ended
	 enemies = {}
	 powerups = {}
	 pulses = {}
	-- boss = {}
	elseif (main) then
	    if (btnp(1,1)) then
	     f_increase = true
	    end
	    if (f_increase) then
	     f_timer += 1
      fade(f_timer)
      if (f_timer == 15) then
	      main = false
	      fade(1)
	      inst = true
	      f_timer = 0
	      f_increase = false
	     end
	    end
	elseif (bkstory) then
	    if (btnp(3)) then
	      f_increase = true
	    end
	    if (f_increase) then
	      f_timer += 1
       fade(f_timer)
       if (f_timer == 15) then
	       bkstory = false
	       fade(1)
	       f_timer = 0
	       f_increase = false
	      end
	    end
	end
end

function __update()

 if (player.imeter <= 0) then
    c_end = true
 end

 if (player.spedup > 0) then
    player.spedup -= 1
 end
 if (player.highjump > 0) then
    player.highjump -= 1
 end
 if (player.etimer > 0) then
    player.etimer -= 1
 end
 if (player.invincibility > 0) then
    player.invincibility -= 1
 end
 if (player.invincibility == 1) then
    player.imeter -= 1
 end
 if (player.vtimer > 0) then
    player.vtimer -= 1
 end
 if (player.btimer > 0) then
    player.btimer -= 1
 end
 if (player.mtimer > 0) then
    player.mtimer -= 1
 end
 if (player.mtimer <= 0) then
    player.ed = 0
 end
 if (player.jtimer > 0) then
    player.jtimer -= 1
 end

	if(btn(0) and btn(4) == false) then
	  if (player.spedup > 0) then
	     player.vel.x = -2
	  else
	     player.vel.x = -1
	  end
	end
	if(btn(0) and btn(4) and player.etimer == 0 and player.invincibility == 0) then
	  local col = phy_aabb_init(2,2,4,4)
	  local b = obj_init(v_init(player.pos.x-9, player.pos.y), 52, 1, col, false)
	  b.right = false
	  b.lifetime = 5
	  add(pulses, b)
	  player.etimer = 15
	end
	if(btn(1) and btn(4) == false) then
	  if (player.spedup > 0) then
	     player.vel.x = 2
	  else
	     player.vel.x = 1
	  end
	end
	if(btn(1) and btn(4) and player.etimer == 0 and player.invincibility == 0) then
	  local col = phy_aabb_init(0,0,8,8)
	  local b = obj_init(v_init(player.pos.x+9, player.pos.y), 52, 1, col, false)
	  b.right = true
	  b.lifetime = 5
	  add(pulses, b)
	  player.etimer = 15
	end

	if(btn(2) and (player.is_on_ground or ((player.s == 5 or player.s == 8 or player.s == 10 or player.s == 12 or player.s == 21) and player.jtimer <= 0 and btn(5)))) then
	  if (player.is_on_ground == false) then
	     sfx(4)
	     player.jtimer += 900
	  end
	  if (player.highjump > 0) then
	      if (player.s == 5 or player.s == 8 or player.s == 10 or player.s == 12 or player.s == 21) then
	        player.vel.y = -4
	     else
	        player.vel.y = -7
	     end
	  else
	     if (player.s == 5 or player.s == 8 or player.s == 10 or player.s == 12 or player.s == 21) then
	        player.vel.y = -3
	     else
	        player.vel.y = -5
	     end
	  end
	end

	if (btn(5)) then
	   if(player.s == 9 and player.vtimer <= 0) then
	     sfx(0)
	     player.invincibility += 90
	     player.vtimer += 900
	   end
	   if((player.s == 17 or player.s == 26) and player.btimer <= 0) then
	     sfx(3)
	     for i = 1, #enemies do
	        if (v_dist(player.pos, enemies[i].pos) < 50) then
	          enemies[i].cmeter -= 4
	        end
	     end
	     --[[if (v_dist(player.pos, boss.pos) < 50) then
	        boss.cmeter -= 4]]--
	     end
	     player.imeter -= 2
	     player.btimer += 450
	   end
	   if((player.s == 25 or player.s == 27) and player.mtimer <= 0) then
	     player.mtimer += 180
	     local mystery = flr(rnd(4))
	     if (mystery == 0) then
	        sfx(1)
	        player.ed += 1
	     elseif (mystery == 1 and player.imeter < (10+(4*level))) then
	        sfx(3)
	        player.imeter += 1
	     elseif (mystery == 2 and player.vtimer <= 0) then
	       sfx(0)
	       player.invincibility += 45
	       player.vtimer += 450
	     end
	   end
	end

	for i = 1, #pulses do
	   if (pulses[i].right) then
	     pulses[i].vel.x +=2
	   else
	     pulses[i].vel.x -=2
	   end
	   if (pulses[i].lifetime <= 0) then
	      add(b_b_deleted, pulses[i])
	   end
	   pulses[i].lifetime -=1
 end

--[[if (player.invincibility <= 0 and g_timer % 90 == 0 and v_dist(player.pos, boss.pos) < 50) then
		  player.imeter -= 2
		  deb_log("aoe damage ".. v_dist(player.pos, boss.pos).." "..boss.pos.x.." "..boss.pos.y)
	end

	if(phy_aabb_collide(player.pos, player.box, boss.pos, boss.box)) then
   sfx(2)
			deb_log("boss collision")
			if (player.invincibility <= 0) then
			 player.imeter -= boss.d
			end
			if(player.s == 2 or player.s == 3 or player.s == 4 or player.s == 7 or player.s == 15 or player.s == 18 or player.s == 20 or player.s == 22) then
			  boss.cmeter -= 2
			end
	end]]--

	for i=1,#enemies do
		if(phy_aabb_collide(player.pos, player.box, enemies[i].pos, enemies[i].box)) then
   sfx(2)
			deb_log("enemy collision")
			if (player.invincibility <= 0) then
			 player.imeter -= enemies[i].d
			end
			if(player.s == 2 or player.s == 3 or player.s == 4 or player.s == 7 or player.s == 15 or player.s == 18 or player.s == 20 or player.s == 22) then
			  enemies[i].cmeter -= 2
			end
		end
		if(enemies[i].s == 30 and player.invincibility <= 0 and g_timer % 90 == 0 and v_dist(player.pos, enemies[i].pos) < 50) then
		  player.imeter -= 1
		  deb_log("aoe damage ".. v_dist(player.pos, enemies[i].pos).." "..enemies[i].pos.x.." "..enemies[i].pos.y)
		end

		if (g_timer % 8 == 0) then

	  	if (enemies[i].right and (enemies[i].s==28 or enemies[i].s == 29)) then
	     enemies[i].vel.x +=1
	   elseif ((enemies[i].right == false) and (enemies[i].s==28 or enemies[i].s == 29)) then
	     enemies[i].vel.x -=1
	   end
	 end

	 for j=1, #pulses do
  		if(phy_aabb_collide(pulses[j].pos, pulses[j].box, enemies[i].pos, enemies[i].box)) then
      deb_log("pulse hit")
      if (player.s == 1 or player.s == 6 or player.s == 11 or player.s == 13 or player.s == 14 or player.s == 19 or player.s == 23 or player.s == 24) then
       enemies[i].cmeter -= (2 + player.ed)
      else
       enemies[i].cmeter -= (1 + player.ed)
      end
      sfx(2)
      add(b_b_deleted, pulses[j])
		  end
		for j=1, #enemies do
		    if(enemies[i].s == 30 and j != i and (enemies[j].cmeter < enemies[j].mc) and g_timer % 30 == 0 and v_dist(enemies[j].pos, enemies[i].pos) < 50) then
		      enemies[j].cmeter += 1
		    end
		  --[[ if((enemies[j].cmeter < enemies[j].mc) and g_timer % 60 == 0 and v_dist(boss.pos, enemies[j].pos) < 100) then
		      enemies[j].cmeter += 1]]--
		    end
		end
		if(enemies[i].cmeter <= 0) then
		  add(e_b_deleted, enemies[i])
    if (enemies[i].s == 28 or enemies[i].s == 29) then
		     scorev +=1
		     enemies[i].stime = 1
		  elseif (enemies[i].s == 30 or enemies[i].s == 31) then
		     scored +=1
		     enemies[i].stime = 0
		  end
		  if (enemies[i].s == 28 or enemies[i].s == 29) then
		    enemies[i].s = enemies[i].les
		  end
		  deb_log("enemy deleted")
		end
	end


	--[[for j = 1, #pulses do
		 if(phy_aabb_collide(pulses[j].pos, pulses[j].box, boss.pos, boss.box)) then
      deb_log("pulse hit")
      if (player.s == 1 or player.s == 6 or player.s == 11 or player.s == 13 or player.s == 14 or player.s == 19 or player.s == 23 or player.s == 24) then
       boss.cmeter -= (2 + player.ed)
      else
       boss.cmeter -= (1 + player.ed)
      end
      sfx(2)
      add(b_b_deleted, pulses[j])
		end
	end
 end

	if (boss.cmeter <= 0) then
		   win = true
	end]]--


	for i=1,#powerups do

		if(phy_aabb_collide(player.pos, player.box, powerups[i].pos, powerups[i].box)) then
			deb_log("powerup collision")
			if (powerups[i].s == 40) then
			   player.imeter += 2
			end
			if (powerups[i].s == 43) then
			   player.spedup += 450
			end
			if (powerups[i].s == 44) then
			   player.highjump += 150
			end
			if (powerups[i].s == 46) then
			   player.ed += 1
			   player.mtimer += 300
		 end
	 	add(p_b_deleted, powerups[i])
		end
	end

	for i=1, #p_b_deleted do

			mset(p_b_deleted[i].pos.x,
		     p_b_deleted[i].pos.y, 45)
			del(powerups, p_b_deleted[i])

 end
 for i=1, #e_b_deleted do
	 if(e_b_deleted[i].stime <= 0) then
			mset(e_b_deleted[i].pos.x,
		     e_b_deleted[i].pos.y, 45)
			del(enemies, e_b_deleted[i])
	 else
	  e_b_deleted[i].stime -= 1
	 end

 end
 for i=1, #b_b_deleted do

			mset(b_b_deleted[i].pos.x,
		     b_b_deleted[i].pos.y, 45)
			del(pulses, b_b_deleted[i])

 end
 p_b_deleted = {}
 e_b_deleted = {}
 b_b_deleted = {}
	phy_update(player)
	for i=1, #pulses do
	   phy_update(pulses[i])
	end
	for i=1, #enemies do
	   phy_update(enemies[i])
	end


	camera_pos.x = player.pos.x - 60
	camera_pos.y = player.pos.y - 60

	camera(camera_pos.x, camera_pos.y)

	g_timer += 1




function _draw()

 pal(5, 0)
 if (fall_end == false and c_end == false and win == false and main == false and inst == false and bkstory == false) then

	 __draw()

	 local cursor_pos = v_init(stat(32)-1, stat(33)-1)
  print("im: "..player.imeter, player.pos.x, player.pos.y - 6, 5)
  print("letters saved: "..scorev, player.pos.x, player.pos.y - 11, 5)
  print("csourced: "..scored, player.pos.x, player.pos.y - 16, 5)
	deb_clear_timer -= 1
	if (deb_clear_timer % 60 == 0) then
		 deb_clear_buffers()
		 deb_clear_timer = 59
	end
	 if(deb_mode_on) then

		 -- draw the console
		 local console_y = 100

		 if(cursor_pos.y > console_y) then
			 rectfill(camera_pos.x + 0  , camera_pos.y + 100,
					 camera_pos.x + 128, camera_pos.y + 128, 2)

			 print("console", camera_pos.x + 1, camera_pos.y + console_y, 7)
			 -- draw log messages
			 local log_y = console_y + 10
			 for i=1,#deb_log_buffer do
				 print(deb_log_buffer[i], camera_pos.x + 1, camera_pos.y + log_y, 7)
				 log_y += 10
			 end
		 end

		 -- draw the texts
		 for i=1,#deb_text_buffer do
			 print(deb_text_buffer[i].msg, deb_text_buffer[i].x, deb_text_buffer[i].y, 7)
		 end

		 -- draw the rects
		 for i=1,#deb_rect_buffer do
			 rect(deb_rect_buffer[i].x1, deb_rect_buffer[i].y1,
			 deb_rect_buffer[i].x2, deb_rect_buffer[i].y2, 7)
		 end

		 print("#debug on: "..deb_states[deb_curt_state], camera_pos.x + 1, camera_pos.y + 1, 2)
		 if(deb_states[deb_curt_state] == "step") then
			 print("#press s to update", camera_pos.x + 1, camera_pos.y + 10, 2)
		 elseif(deb_states[deb_curt_state] == "slowmo") then
			 print("#debug on: slowmo", camera_pos.x + 1, camera_pos.y + 1, 2)
		 end

		 -- draw cpu and memory stats
		 print("mem: ".. stat(0), camera_pos.x + 80, camera_pos.y + 1)
		 print("cpu: ".. stat(1), camera_pos.x + 80, camera_pos.y + 10)
		 print("px: ".. player.pos.x, camera_pos.x + 80, camera_pos.y + 20)
		 print("py: ".. player.pos.y, camera_pos.x + 80, camera_pos.y + 30)
		 print("high jump timer: ".. player.highjump, camera_pos.x, camera_pos.y + 30)
		 print("speedup timer: ".. player.spedup, camera_pos.x, camera_pos.y + 40)
		 print("invincibility: " .. player.invincibility, camera_pos.x, camera_pos.y + 50)
		 print("itimer: " .. player.vtimer, camera_pos.x, camera_pos.y + 60)
		 print("mystery timer: "..player.mtimer, camera_pos.x, camera_pos.y + 70)
		 --print("test", camera_pos.x, camera_pos.y + 80)
		 --[[if (working == 1) then
			   print("error: obj is nil", camera_pos.x, camera_pos.y + 80, 2)
		 elseif (working == 2) then
			   print("error: obj.vel.x is nil", camera_pos.x, camera_pos.y+80, 2)
		 else
			  print("it's working for now", camera_pos.x, camera_pos.y+80, 2)
		 end]]--






		 -- draw the cursor
		 spr(0, cursor_pos.x, cursor_pos.y)

   -- making debug log easier to read by messages being drawn for longer

	 end
	elseif (main) then
	   cls()
	   print("alphastorm", 40, 30, 7)
	   print("some letters that may appear: ", 0, 40, 7)
	   for i = 1, 12 do
	       local gs = flr(rnd(26)) +1
	       if (gs >= 16) gs += 1
	       spr(gs,(-10 + (i*10)), 50)
	   end
	   print("press f to start", 0, 60, 7)
	   print("(it doesn't matter which letters", 0, 70, 7)
	   print("are here.)", 0, 80, 7)
	elseif (inst) then
	      cls()
	      print("instructions", 40, 0, 7)
	      print("� and � to move, � to jump", 0, 6, 7)
	      print("z + left or right to fire energy", 0, 12, 7)
	      print("that direction to damage foes", 10, 18, 7)
	      print("letter powers are based on type", 0, 24, 7)
	      print("x to use some special abilities: ", 0, 30, 7)
	      print("(uses are limited by a timer)", 0, 36, 7)
	      print("x and z use a random good effect", 0, 42, 7)
	      print("p and y hurt enemies in an area", 0, 48, 7)
	      print("greatly - and themselves a bit", 0, 54, 7)
       print("e h j l t may jump even in air",0, 60, 7)
       print("i can invoke 1.5 sec invincibile", 0, 66, 7)
	      print("automatic abilities: ", 20, 72, 7)
       print("a f k m n r v w energy stronger", 0, 78, 7)
       print("b c d g o q s u damage foes with", 0, 84, 7)
       print("touch - but letter is also hurt!", 0, 90, 7)
       print("reach small purple square.", 10, 102, 2)
       print("f toggles instructions on/off",0, 108, 7)
	elseif (fall_end) then
	 player.pos.x = 131
	 player.pos.y = 80
	 camera_pos.x = player.pos.x - 60
	 camera_pos.y = player.pos.y - 60
 	camera(camera_pos.x, camera_pos.y)
	 for x=0,128 do
		 for y=0,128 do
		  mset(x, y, flr(rnd(4))+33)
		 end
	 end
	 map(0,0,0,0,128,128)
	 print("you have failed.",camera_pos.x+1, camera_pos.y+20, 5)
	 print("you have fallen out of the",camera_pos.x+1, camera_pos.y+30, 5)
	 print("dimension you ventured to.",camera_pos.x+1, camera_pos.y + 40)
	 print("although relatively safe (for",camera_pos.x+1, camera_pos.y+50, 5)
 	print("now), you cannot get back easily.", camera_pos.x+1, camera_pos.y+60, 5)
	 print("the corruption will spread",camera_pos.x+1, camera_pos.y+70, 5)
	 print("and may overcome every letter.", camera_pos.x+1, camera_pos.y+80, 5)
	elseif (c_end) then
	 player.pos.x = 131
	 player.pos.y = 80
	 camera_pos.x = player.pos.x - 60
	 camera_pos.y = player.pos.y - 60
 	camera(camera_pos.x, camera_pos.y)
	 for x=0,128 do
		 for y=0,128 do
		  mset(x, y, flr(rnd(4))+33)
		 end
	 end
		map(0,0,0,0,128,128)
		print("you have failed.",camera_pos.x+1, camera_pos.y+20, 5)
	 print("you have fallen to corruption",camera_pos.x+1, camera_pos.y+30, 5)
	 print("and became a monster.",camera_pos.x+1, camera_pos.y + 40)
	 print("you now unthinkingly oppose",camera_pos.x+1, camera_pos.y+50, 5)
 	print("those few who bravely fight", camera_pos.x+1, camera_pos.y+60, 5)
	 print("the thing that warps their world.",camera_pos.x+1, camera_pos.y+70, 5)
	 print("it may overcome every letter.", camera_pos.x+1, camera_pos.y+80, 5)
	elseif (win) then
 	player.pos.x = 131
	 player.pos.y = 80
	 camera_pos.x = player.pos.x - 60
	 camera_pos.y = player.pos.y - 60
 	camera(camera_pos.x, camera_pos.y)
	 for x=0,128 do
	 for y=0,128 do
		  mset(x, y, 45)
		 end
	 end
		map(0,0,0,0,128,128)
		print("you have succeeded.",camera_pos.x+1, camera_pos.y+20, 5)
	 print("you have fought the corruption",camera_pos.x+1, camera_pos.y+30, 5)
	 print("and remained yourself.",camera_pos.x+1, camera_pos.y + 40)
	 print("not every letter is safe.",camera_pos.x+1, camera_pos.y+50, 5)
 	print("however, they can be rescued", camera_pos.x+1, camera_pos.y+60, 5)
	 print("because the source of.",camera_pos.x+1, camera_pos.y+70, 5)
	 print("the problem has been destroyed.", camera_pos.x+1, camera_pos.y+80, 5)
 end
end

function obj_draw(obj)
	spr(obj.s, obj.pos.x, obj.pos.y, 1, 1)
end

function __draw()

	cls()

	map(0,0,0,0,128,128)

	foreach(powerups, obj_draw)
	foreach(enemies, obj_draw)
	foreach(pulses, obj_draw)

	-- drawing the player
	obj_draw(player)
	--drawing the huge boss
	--spr(38, boss.pos.x, boss.pos.y, 2, 2)

end
__gfx__
00000000777557777555555777555577755555575555557755555777775557775777777555555555555555555777755555777777557775557557775777555777
00000000775555777577775775577777757777555777777757777777755777775777777577755777777757775777557755777777557775757557775775575577
00700700755775577577755775777777757777755777777757777777557777775777777577755777777757775755577755777777557755757575775775577557
00077000757777577555557757777777757777755555557755555777577777775555555577755777777757775557777755777777555757757575575757777757
00077000755555577575557757777777757777555555557757777777577555575555555577755777757757775555777755777777575757757577575757777757
00700700557777557577755755777777757775575777777757777777577777575777777577755777757757775777557755777777575557757577755757777557
00000000577777757577775775577557757755775777777757777777577755575777777577755777757757775777775555555555575577757577755757775577
00000000577777757555555777555577755557775555557757777777555557775777777555555555755557775777777755555555577577757577755775555777
0000000075555557775557777555555777555557555555557577775757777775577757755777775555777775555555556a6666a6f7799777eeeeeeee82248888
000000007577775775575577757777577757777777755777757777575777775557755775555777577557775577777757aaaaaaaaff999777eeeeeeee84224884
000000007577755775777557757775577757777777755777757777575577775755755775775775577755555777777577aa7aa7aa7fff9997eccc3c3e88428488
000000007557557775777757755555777755557777755777757777577577775775755755775555777775577777775777aaaaaaaa979ff977ebccccce48422488
0000000075555777757757577575777777777577777557777557775775777557757557577775577777755777777577776aa6a6669999ff99eccc3cce48882282
0000000075777777755755577577557777777577777557777557755775577577755555577755557777755777755577776aaaa66699777ff9ecbcccce44288422
0000000075777777775575577577755775577577777557777557755777555577775775577557755777755777557777776a66aaa6997777ffeccccbce42888224
0000000075777777777557557577775777555577777557777555555777755777775775575577775577755777555555556a6666a69777779feeeeeeee24882288
0000000099999999aaaaaaaa11111111ffffffff55566666888dddddd888888877777777888888888ddddd88e000000000eeee00777777775555555555665655
0000000099999999aaaaaaaa11111111ffffffff55555655888d8888dd8888887555555788d88d888ddddd88eeeee0000eeeeee0777777775777777565555556
0000000099999999aaaaaaaa11111111ffffffff66665566888888888d8888887555555788dddd888dddddd80000eeeeee0ee0e0777777775777777555555566
0000000099999999aaaaaaaa11111111ffffffff66666666888888888d888888755555578ddddd888dddddd8eeeeeeeee00ee00e777777775777777555555566
0000000099999999aaaaaaaa11111111ffffffff5555555588888888dd8888887555555788ddddd888ddddd8eeeeeeee000ee000777777775777777565656555
0000000099999999aaaaaaaa11111111ffffffff666655668888888dd88888887555555788dddd88d8dddd8800000eee000ee000777777775777777555555556
0000000099999999aaaaaaaa11111111ffffffff655666668888dddd888888887555555788d8d888dddddd8800eeee00000ee000777777775777777565665565
0000000099999999aaaaaaaa11111111ffffffff555555558888d8888888888877777777888888888888ddd8eee00000000ee000777777775555555555655655
0000000077777777555555555555555500000000000000008888dd88888888880000000000000000000000000000000000000000000000000000000000000000
00000000777777775ffffff555555555000000000000000088888dd8888888880000000000000000000000000000000000000000000000000000000000000000
00000000772222775ffffff5555555550000000000000000888888dd888888880000000000000000000000000000000000000000000000000000000000000000
00000000772222775ffffff55555555500055000000000008888888d888888880000000000000000000000000000000000000000000000000000000000000000
00000000772222775ffffff555555555000550000000000088888888888888880000000000000000000000000000000000000000000000000000000000000000
00000000772222775ffffff55555555500000000000000008888888dddd888880000000000000000000000000000000000000000000000000000000000000000
00000000777777775ffffff55555555500000000000000008888888dddd888880000000000000000000000000000000000000000000000000000000000000000
0000000077777777555555555555555500000000000000008888888dddd888880000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2
d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2
d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2
d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2
d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2
d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2
d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2
d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2
d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2
d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2
d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2
d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2
d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2
d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2
d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2
d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2
d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2
d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2
d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2
d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2
d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2
d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2
d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2
d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2
d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2
d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2
d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2
d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2
d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2
d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2
d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2
d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2
d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2
d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2
d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2
d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2
d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2
d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2
d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2
d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2
d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2
d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2
d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2
d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2
d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2
d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2
d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2
d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2
d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2
d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2
d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2
d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2
d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2
d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2
d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2
d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2
d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2
d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2
d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2
d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2
d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2
d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2
d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2
d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2
__label__
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
ddddddddddddddddfffffffffffffffffffffffffffffffffffffffffffffffffddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
fffffffffffffffffffffffffffffffffdddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddffffffffffffffff
fdddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddffffffffffffffffffffffffffffffffffffffffffffffff
ddddddddddddddddddddddddddddddddddddddddddddddddfffffffffffffffffffffffffffffffffffffffffffffffffddddddddddddddddddddddddddddddd
ddddddddddddddddfffffffffffffffffffffffffffffffffffffffffffffffffddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
fffffffffffffffffffffffffffffffffdddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddffffffffffffffdd
fdddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddfffffffdffffffffffffffffffffffffffffffffffffffff
dddddddddddddddddddddddddddddddddddddddddddddddddffffffffffffffffffffffffffffffffffffffffffffffffddddddddddddddddddddddddddddddd
ddddddddddddddddddddddddddffdffffffffdfffffffffffffffffffffffffffddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
ddddddfffffffffffffffffffffffffffdddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddffffffffffffffff
fddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddfffffffffffffffffffffff
ddddddddddddddddddddddddddddddddddddddddddddddddfffffffffffffffffffffffffffffffffffffffffffffffffddddddddddddddddddddddddddddddd
ddddddddddddddddfffffffffffffffffffffffffffffffffffffffffffffffffddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
fffffffffffffffffffffffffffffffffdddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddffffffffffffffff
fdddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddffffffffffffffffffffffffffffffffffffffffffffffff
ddddddddddddddddddddddddddddddddddddddddddddddddfffffffffffffffffffffffffffffffffffffffffffffffffddddddddddddddddddddddddddddddd
ddddddddddddddddfffffffffffffffffffffffffffffffffffffffffffffffffddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
fffffffffffffffffffffffffffffffffdddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddffffffffffffffff
fdddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddffffffffffffffffffffffffffffffffffffffffffffffff
ddddddddddddddddddddddddddddddddddddddddddddddddfffffffffffffffffffffffffffffffffffffffffffffffffddddddddddddddddddddddddddddddd
ddddddddddddddddfffffffffffffffffffffffffffffffffffffffffffffffffddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
ddddddddddddddddddddddfdddddddddddddddddddddddddddddddddddddddddddddfddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
ddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddfddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd

__gff__
0001010101010101010101010101010100010101010101010101010103030000000101010100000000000005050000000001010101000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__map__
2424242424242424242424242424242424242424242424242424242424242424242424242424242424242424242424242424332121212121212121212121212121212121212121212121212121212121212121212121212121212121212121212121212121212121212121212121212121212121212121212121212121212121
332d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d332d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d33
332d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d332d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2e2d2d2d2d2d2d2d2d2d1e2d2d1f2d312d2d2d2d2d2d2d2d2d2d2d33
332d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d332d2d282d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d1e2d281c2d2d2d2d2d1c2d2d2d2d2d2d2d2d2d2d2d2d2d33333333332d2d2d2d2d3333333333333333332d2d2d2d2d2d2d2d2d2d2d33
332d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d3333333333333333332d2d2d2d2d2d2d2d2d2323232d2833333333332d2d2d2d3333333333332d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d33
332d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d332d2d2d2d2d2d2d2d2d2d2d2d2d2d2d1d2d2d2d2d2d3333332d2d2d2d2d2d2d2d2d2d2d2d2d282d282d2d2d2d2c2d2d2d2d2d2d2d3333332d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d33
332d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d332d2d2d2d2d2d2d2d1c2d2d2d2d2d3333332d2d2d2d2d2d2d2d2d2d2c2d2d1c2d2d2d2d2d2d3323332d2d3333332d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d33
332d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d332d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d332d2d2d2d2d2d2d2d33333333332d2d2d2d2d2d2d2d2d2d2d2d2d2d3333333333332d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d33
332d2d2d2d2d2d252d2d2d2d3333232d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d332d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d33
33012d2d2d2d2d2d2c1d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d332d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d33
333333333333333333332d2d2b2d2d2d2d1d2d2d2d312d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d332d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d33
2d2d2d2d2d2d2d2d2d2d2d2d333333333333333333332d2d32323232323232322d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d332d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d33
2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d332d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d33
3232323232323232323232323232323232322d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d323232323232323232323232323232333232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232
2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d332d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d
2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d332d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d
2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d332d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d
332d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d332d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d
332d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d332d2d2d2d2d2d2d2d2d2d2d2d2d2d2d1f2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d
332d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d1d1d33332d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d332d2d2d2d2d2d2d2d2d2d2d2d33332d3333332d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d
332d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d3333332d2d33333333332d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d332d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d
332d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d332d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d
332d2d2d2d2d2d282d1d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d1c2d2d312d2d2d2d2d2d2d2d2d2d2d332d2d2b33332e28282c2d2d2d2d2d2d312d2d2d1f2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d
332d2d2d2d2d333333332d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d3333333333332d2d2d2d2d2d2d2d2d2d2d333333333333333333332d2d33332d2d2d2d2d2d33332d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d
332d2d2d2d2d2d2d2d2d2d2d2d1d2d2d333333332d2c2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d332d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d
332d2d2d2d2d2d2d2d2d33333333332d2d2d2d2d2d332d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d332d2d2d2d2d2d2d2d2d2d2d2d2d2d3333332d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d
332d2d2d2d2d2d1e1d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d332d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d
332d2d2d3333333333332d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d332d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d
3333332d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d332d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d
2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d332d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d
3232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232332d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d
2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d3232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232
__sfx__
0010000026050080001a7500000000000050002305000000000003235000000290500000000000000001d0500000000000000001c750000001f750000000c0500000000000000000725000000072500000000000
0010000000000162500000000000000003125000000000002c250000000000000000000000000027250000003a2500000029250000000a25000000000000000000000182500000000000174701b4500b47000000
000200002b6500000022650000002265000000000003565000000196502d65022650336500000021650000001d650000000000000000216500f65000000000001e6503f6500000027650000000c6500000000000
001000000000000000261500000018150000002615000000000002b4500000022450000002b45000000000002e15000000241502a0002e0500000000000364500000026450000003745000000000000000000000
0010000000000000000000008350000000c350000001c0500000023050000002f0500000000000360500000000000360500000000000300500000024050010001e050000000b3500000008350000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__music__
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
