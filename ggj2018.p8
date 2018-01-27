pico-8 cartridge // http://www.pico-8.com
version 15
__lua__
function _init()
  player = {
    x=64/8,
    y=64/8,
    dx=0,
    dy=0,
    speed=1,
  }
  palt(0,false)
  sats = {}
  sat_sprites = {52,55,56,57}
  sat_colors = {c_52=6,
                c_55=8,
                c_56=9,
                c_57=11}
  level = 0
  active_sat = false
  choosing_angle = false
  _init_level(level)
end

function _update()
  if choosing_angle and active_sat then 
    --[[ 
    if btnp(0) then
      active_sat.angle=0.25
    elseif btnp(1) then
      active_sat.angle=0.75
    elseif btnp(2) then
      active_sat.angle=0.5
    elseif btnp(3) then
      active_sat.angle=1
    elseif btnp(4) then
    		choosing_angle = false
    end
    --]]
    if btnp(1) then
      active_sat.angle+=1/8
    elseif btnp(0) then
      active_sat.angle-=1/8
    end
    
    if btnp(4) then
      choosing_angle=false
    end
  else
  
    if btnp(0) then
      player.dx-=player.speed
    elseif btnp(1) then
      player.dx+=player.speed
    elseif btnp(2) then
      player.dy-=player.speed
    elseif btnp(3) then
      player.dy+=player.speed
    end
    -- check if wall or something
    if is_moveable(player.x+player.dx,
                   player.y+player.dy) then
      --move player
      player.x+=player.dx
      player.y+=player.dy
    end
    player.dx=0
    player.dy=0
    if btnp(4) then
      active_sat = activate_sat(player)
      if active_sat then choosing_angle=true end
    end
  end
end

function _draw()
  cls()
  rectfill(0,0,128,128,1)
  map(0,0, -- begin cells to draw
      0,0, -- screen pos
      16,16)  -- height/width
  
  spr(1,player.x*8, player.y*8)
  -- draw sat angles
  for sat in all(sats) do
    line((sat.x*8)+3,
         (sat.y*8)+4,
         (sat.x*8)+3+sin(sat.angle)*6,
         (sat.y*8)+4+cos(sat.angle)*6,
         sat.c)
    circfill((sat.x*8)+3+sin(sat.angle)*6,
             (sat.y*8)+4+cos(sat.angle)*6,
             1,
             sat.c)
  end
  --circfill(64,64,10,8)
  --circfill(player.x*8,player.y*8,10,1)
end

function is_moveable(x,y)
  return (not is_solid(x,y)) and
         (not is_hole(x,y))
end

function is_solid(x,y)
  return fget(mget(x,y),0)
end

function is_hole(x,y)
  return fget(mget(x,y),1)
end

function activate_sat(player)
  for sat in all(sats) do
    printh(" s.x:"..sat.x.." s.y:"..sat.y.." c:"..sat.c)
    if (player.x==sat.x and
        player.y==sat.y) then
       printh("activate sat!")
       sat.angle=1
       return sat
    end
  end
  return false
end

function create_sat(x,y)
  local sat = {}
  sat.x=x
  sat.y=y
  sat.sp=mget(x,y)
  sat.c=sat_colors["c_"..sat.sp]
  sat.angle =rnd(1)
  sat.active=false
  add(sats, sat)
end

function has(list, thing)
  for item in all(list) do
    if item == thing then
      return true
    end
  end
  return false
end

function _init_level(level_idx)
  -- iterate through map level cells
  for row=(level_idx*16),(level_idx*16)+16 do
    for col=1,16 do
      if has(sat_sprites,
             mget(row, col)) then
        -- initialize the satellites
        -- /w random angles
        -- /w positions
     
        create_sat(row,col)
      end
    end
  end
end
__gfx__
00000000111666110006660000066600000000000000000000000000000000001110111100000000000000000000000000000000000000000000000000000000
00000000111565110005660000056500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700111666110006660000066600000000000000000000000000000000001111110100000000000000000000000000000000000000000000000000000000
00077000111ddd110006660000066600000000000000000000000000000000001111110100000000000000000000000000000000000000000000000000000000
00077000111ddd110002220000022200000000000000000000000000000000001111110100000000000000000000000000000000000000000000000000000000
00700700116ddd610062226000622260000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000111d1d110002020000020200000000000000000000000000000000001110111100000000000000000000000000000000000000000000000000000000
00000000116616610066066000660660000000000000000000000000000000001110111100000000000000000000000000000000000000000000000000000000
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
00000000111511110000000000000000555111110000000011110001222111119991111133311111000000000000000000000000000000000000000000000000
00000000555555550000000000000000511511110000000000000010211211119119111131131111000000000000000000000000000000000000000000000000
000000001111115100000000000000005111161100000000100000002111111191111a1131111111000000000000000000000000000000000000000000000000
00000000111111510000000000000000511161110000000010000000211111119111a11131111111000000000000000000000000000000000000000000000000
0000000011111151000000000000000015161151000000000001000112111121191a119113111131000000000000000000000000000000000000000000000000
00000000555555550000000000000000155111150000000010000000122111121991111913311113000000000000000000000000000000000000000000000000
00000000111511110000000000000000155511150000000000100001122211121999111913331113000000000000000000000000000000000000000000000000
00000000111511110000000000000000155155550000000010111011122122221991999913313333000000000000000000000000000000000000000000000000
__gff__
0000000000000000010000000000000000000000000000000000000000000000000000000000000000000000000000000001000000000200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__map__
3131313131313131313131313131313100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3136000000000000313131313131313100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3139000000000000363636363636373100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3100000000000000313131313131313100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3100000000000000000000000000003100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3100000000360000000000000000003100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3100000000000000000000000000003100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3100000000000000000000000000003100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3100000000000000000000000000003100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3100000000000000000000000000003100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3100000000000000310000310000003100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3100000000003131000000000000003100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3100000000000000000000003131003100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3100000000000000310000000000003100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3100000000000000000000000000003100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3131313131313131313131313131313100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
