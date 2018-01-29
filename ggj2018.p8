pico-8 cartridge // http://www.pico-8.com
version 15
__lua__
function _init()
  music(0)
  t=0
  mode=0
  cam={x=0,y=0,dx=0,dy=0}
  circ_fx = {}
  dust_fx = {}
  player = {
    x=7,
    y=5,
    dx=0,
    dy=0,
    speed=1,
    frame=1,
    step=4,
    t=0,
    sprites={1,2,3,4}
  }
  tooltips={
    {s="arrows to move",x=2,y=1,show=true,activate=false},
    {s="->",x=2,y=9,show=true,activate=false},
    {s="hold z",x=4,y=3,show=false,activate={x=4,y=9}},
    {s="<- and -> adjust satellite",x=2,y=4,show=false,activate={x=4,y=9}},
    {s="x to toggle transmit",x=2,y=14,show=true,activate=false},
  }
  palt(0,false)
  shooting = false
  sats = {}
  boxes = {}
  shot_speed = 3
  shots = {}
  sat_sprites = {52,55,56,57,58}
  sat_colors = {c_52=6,
                c_55=8,
                c_56=9,
                c_57=11,
                c_58=7}
  level = 0
  active_sat = false
  choosing_angle = false
end

function _update()
  if mode==1 then
    update_game()
  elseif mode==2 then
    update_won_game()
  elseif mode==0 then
    update_title_screen()
  end
end

function _draw()
  if mode==1 then
    draw_game()
  elseif mode==2 then
    draw_won_game()
  elseif mode==0 then
    draw_title_screen()
  end
end

function can_move_to(x,y)
  return (not is_solid(x,y)) and
         (not is_hole(x,y))
end

function can_slide(x,y)
  return fget(mget(x,y),2)
end

function is_solid(x,y)
  return (fget(mget(x,y),0) or
          is_box(x,y))
end

function is_hole(x,y)
  return fget(mget(x,y),1)
end

function is_box(x,y)
  return get_box(x,y)
end

function is_sat(x,y)
  return has(sat_sprites,
             mget(flr(x), flr(y)))
end

function adjust_sat(player)
  for sat in all(sats) do
    if (player.x==sat.x and
        player.y==sat.y) then
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
  --sat.angle =0.75-(1/8)
  sat.angle=flr(rnd(8))/8
  if sat.sp==57 or sat.sp==58 then
    sat.powered=true
  else
    sat.powered=false
  end
  add(sats, sat)
end

function create_box(x,y)
  local box = {}
  box.x=x 
  box.y=y
  box.sp=mget(x,y)
  add(boxes,box)
end

function create_circ_fx(x,y)
  local c = {
    x=x,
    y=y,
    r=0,
    c=7
  }
  add(circ_fx,c)
  sfx(2)
end

function update_circ_fx()
  for c in all(circ_fx) do
    c.r+=rnd(1)*4
    if c.r>20 then del(circ_fx, c) end
  end
end

function draw_circ_fx()
  for c in all(circ_fx) do
    circ(c.x, c.y, c.r, c.c)
  end
end

function create_dust_fx(x,y)
  for i=1,10+flr(rnd(10)) do
    local p = {
      x=x*8+flr(rnd(8)),
      y=y*8+6+flr(rnd(2)),
      ttl=flr(rnd(8)),
      c=13
    }
    add(dust_fx,p)
  end
end

function update_dust_fx()
  for p in all(dust_fx) do
    p.ttl-=1
    local dx=flr(rnd(2))
    local dy=flr(rnd(2))
    if flr(rnd(2))==0 then dx*=-1 end
    if flr(rnd(2))==0 then dy*=-1 end
    p.x+=dx
    p.y+=dy
    if p.ttl<0 then del(dust_fx, p) end
  end
end

function draw_dust_fx()
  for p in all(dust_fx) do
    pset(p.x,p.y,p.c)
  end
end

function shoot()
  for sat in all(sats) do
    if sat.powered then
      create_shot(sat.x,
                  sat.y,
                  sat.angle)
    end
  end
  shooting = true
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
  shooting = false
  shots = {}
  sats = {}
  -- iterate through map level cells
  --level*16%128,
  --    flr(level/8)*16
  local xstart = level*16%128
  local ystart = flr(level/8)*16
  cam.x=xstart*8
  cam.y=ystart*8
  for row=xstart,xstart+16 do
    for col=ystart,ystart+16 do
      if has(sat_sprites,
             mget(row, col)) then
        -- initialize the satellites
        -- /w random angles
        -- /w positions
     
        create_sat(row,col)
      end
      
      -- if this is a green spot,
      -- place player here
      if mget(row,col)==32 then
        player.x=row
        player.y=col
        printh("playerx:"..player.x.." playery:"..player.y)
        mset(row,col,5)
      end

      if mget(row,col) == 50 then
        create_box(row,col)
        mset(row,col,6)
      end
    end
  end
end

function update_shots()
  for shot in all(shots) do
    if not shot.done then
      shot.fin.x+=sin(shot.angle)*shot_speed
      shot.fin.y+=cos(shot.angle)*shot_speed
      
      if is_solid(shot.fin.x/8,
                  shot.fin.y/8) then
        shot.done=true
      end
      
      if is_sat(shot.fin.x/8,
                shot.fin.y/8) then
         sat = get_sat(shot.fin.x/8,
                       shot.fin.y/8)
         printh("found a sat!!!!!!! "..sat.x)
         
         sat.powered=true
         if sat.sp != 58 then
           shot.done=true
           create_shot(sat.x,
                       sat.y,
                       sat.angle)
         end      
      end
    end
  end
end

function draw_shots()
  for shot in all(shots) do
    for i=-1,1 do
      for j=-1,1 do
        col = t+i+j%15
        line(shot.start.x+i,
             shot.start.y+j,
             shot.fin.x+i,
             shot.fin.y+j,
             col)
      end
    end
  end
end

function get_sat(x,y)
  for sat in all(sats) do
    if sat.x==flr(x) and
       sat.y==flr(y) then
       return sat
    end
  end
end

function get_box(x,y)
  for box in all(boxes) do
    if box.x==flr(x) and
       box.y==flr(y) then
       return box
    end
  end
  return false
end

function create_shot(x,y,angle)
  create_circ_fx(x*8+3,y*8+4)
  create_circ_fx(x*8+3,y*8+4)
  create_circ_fx(x*8+3,y*8+4)
  local shot = {}
  shot.angle = angle
  shot.done = false
  shot.start = {
    x=x*8+3,
    y=y*8+4
  }
  shot.fin = {
    x=shot.start.x+(sin(shot.angle)*shot_speed),
    y=shot.start.y+(cos(shot.angle)*shot_speed)
  }
  add(shots, shot) 
end


function reset_after_shot()
  shooting=false
  shots = {}
  for sat in all(sats) do
    if sat.sp!=57 and sat.sp!=58 then
      sat.powered=false
    end
  end
end

function won_level()
  for sat in all(sats) do
    if not sat.powered then
      return false
    end
  end
  return true
end

function next_level()
  transition_timer = 30*4
  level+=1
  _init_level(level)
end

-->8
function update_game()
  t+=1
  camera(cam.x,cam.y)
  printh("x: "..((level*16)%128).." y:"..(flr(level/8)*16).." mget:"..mget((level*16%128),(flr(level/8)*16)))
  update_circ_fx()
  update_dust_fx()
  if mget(level*16%128,
         flr(level/8)*16) == 16 then
    player.x=7
    player.y=5
    mode+=1
  end
  if choosing_angle and active_sat then
    if btnp(1) then
      active_sat.angle+=1/8
      sfx(2)
    elseif btnp(0) then
      active_sat.angle-=1/8
      sfx(2)
    end
    if not btn(4) then
      choosing_angle=false
    end
    --if btnp(4) then
    --  choosing_angle=false
    --end
  elseif shooting then
    update_shots()
    sfx(0)
    cam.dx=rnd(1)
    cam.dy=rnd(1)
    if flr(rnd(2)) == 0 then
      cam.dx*=-1
    end
    if flr(rnd(2)) == 0 then
      cam.dy*=-1
    end
    camera(cam.x+cam.dx,cam.y+cam.dy)
    if btnp(5) then
      reset_after_shot()
      shooting=false
      shots = {}
    end
    
    -- check win condition
    if won_level() then
      next_level()
    end
  else
    for tooltip in all(tooltips) do
      if tooltip.activate then
        if player.x==tooltip.activate.x and
          player.y==tooltip.activate.y then
          tooltip.show=true
        else
          tooltip.show=false
        end
      end
    end
    if btnp(0) then
      player.dx-=player.speed
      create_dust_fx(player.x, player.y)
      sfx(1)
      player.flipx=true
    elseif btnp(1) then
      player.dx+=player.speed
      create_dust_fx(player.x, player.y)
      sfx(1)
      player.flipx=false
    elseif btnp(2) then
      player.dy-=player.speed
      create_dust_fx(player.x, player.y)
      sfx(1)
    elseif btnp(3) then
      player.dy+=player.speed
      create_dust_fx(player.x, player.y)
      sfx(1)
    end
    -- check if wall or something
    if can_move_to(player.x+player.dx,
                   player.y+player.dy) then
      --move player
      player.x+=player.dx
      player.y+=player.dy
    elseif is_box(player.x+player.dx,
                  player.y+player.dy) then
      box = get_box(player.x+player.dx,
                    player.y+player.dy)
      if can_slide(box.x+player.dx, box.y+player.dy) then
        sfx(3)
        box.x+=player.dx
        box.y+=player.dy
        player.x+=player.dx
        player.y+=player.dy
      end
    end
    player.dx=0
    player.dy=0
    
    -- adjusting sats
    if btn(4) then
      active_sat = adjust_sat(player)
      if active_sat then choosing_angle=true end
    end
    
    -- shoot from powered sats!
    if btnp(5) then shoot() end
    
    -- animation
    player.t=(player.t+1)%player.step
    if (player.t==0) then
      player.frame=(player.frame+1)%#player.sprites
    end
  end
end

function draw_game()
  cls()
  --[[ map(level*16%128,
      flr(level/8)*16, -- begin cells to draw
      0,0, -- screen pos
      16,16)  -- height/width
  ]]--
  map(0,0,0,0,128,128)
  --spr(1,player.x*8, player.y*8)


  -- draw sat angles
  for sat in all(sats) do
    if sat.powered then
      spr(sat.sp, sat.x*8,sat.y*8)
    end
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
  palt(1,true)

  spr(player.sprites[player.frame+1],
      player.x*8, player.y*8,
      1,1,
      player.flipx)

  palt()
  if choosing_angle then
    spr(34, player.x*8, player.y*8)
  end

  -- draw boxes
  for box in all(boxes) do
    spr(box.sp, box.x*8,box.y*8)
  end
  
  -- draw tooltips
  for tooltip in all(tooltips) do
    if tooltip.show then
      rectfill((tooltip.x*8)-2, (tooltip.y*8)-2+cos((t/60)%60)*2, tooltip.x*8+(#tooltip.s*4),(tooltip.y*8)+6+cos((t/60)%60)*2, 13)
      pretty_print(tooltip.s, tooltip.x*8, (tooltip.y*8)+cos((t/60)%60)*2,2)
    end
  end

  --draw fx
  draw_circ_fx()
  draw_dust_fx()
  --circfill(64,64,10,8)
  --circfill(player.x*8,player.y*8,10,1)
  if shooting then
    draw_shots()
  end
end
-->8
function update_title_screen()
  t+=1
  if btnp(4) then
    t=0
    mode+=1
    _init_level(level)
 	end
  -- animation
  player.t=(player.t+1)%player.step
  if (player.t==0) then
    player.frame=(player.frame+1)%#player.sprites
  end
end

function draw_title_screen()
  cls()
  rectfill(0,0,128,128,1)
  pretty_print("phone home",44,54+cos(t/30)*3,1)
  pretty_print("z to start",44,74+cos(t/30)*3,1)
  pretty_print("by sean mccolgan and meng lin",6,104+cos(t+15/30)*3,14)
  pretty_print("for #ggj2018",44,114+cos(t+15/30)*3,14)
  pretty_print("twitter: @mccolgst",30,124+cos(t+15/30)*3,14)
  spr(player.sprites[player.frame+1],
      player.x*8, player.y*8,
      1,1,
      player.flipx)
end

function update_won_game()
  camera()
  t+=1
  -- animation
  player.t=(player.t+1)%player.step
  if (player.t==0) then
    player.frame=(player.frame+1)%#player.sprites
  end
end

function draw_won_game()
  cls()
  rectfill(0,0,128,128,1)
  pretty_print("you won!",46,64+cos(t/30)*3, 1)
  spr(player.sprites[player.frame+1],
      player.x*8, player.y*8,
      1,1,
      player.flipx)
end

function pretty_print(s,x,y,c)
  for i=-1,1 do
    for j=-1,1 do
      print(s,x+i,y+j,7)
    end
  end
  print(s,x,y,c)
end
__gfx__
00000000113333111333333113333331113333111111111111111111000000001110111100000000000000000000000000000000000000000000000000000000
0000000013333331133333311337777113377771111111111d1d1d1d000000000000000000000000000000000000000000000000000000000000000000000000
00700700133777711337777113333331133333311111111111111111000000001111110100000000000000000000000000000000000000000000000000000000
0007700013333331333333333333333313333331111111111d1d1d1d000000001111110100000000000000000000000000000000000000000000000000000000
00077000333333331333333113333331333333331111111111111111000000001111110100000000000000000000000000000000000000000000000000000000
0070070013333331133333311333333113333331111111111d1d1d1d000000000000000000000000000000000000000000000000000000000000000000000000
00000000133333311311113113111131133333311111111111111111000000001110111100000000000000000000000000000000000000000000000000000000
0000000013111131131111311311113113111131111111111d1d1d1d000000001110111100000000000000000000000000000000000000000000000000000000
88888888000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
88888888000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
88888888000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
88888888000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
88888888000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
88888888000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
88888888000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
88888888000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
bbbbbbbb00000000bbb00bbb00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
bbbbbbbb00000000b000000b00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
bbbbbbbb00000000b000000b00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
bbbbbbbb000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
bbbbbbbb000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
bbbbbbbb00000000b000000b00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
bbbbbbbb00000000b000000b00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
bbbbbbbb00000000bbb00bbb00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000022222222666226660000000055511111000000001111000188811111aaa11111bbb11111ccc111110000000000000000000000000000000000000000
00000000221212126222222600000000511511110000000000000010811e1111a1191111b1131111c11c11110000000000000000000000000000000000000000
0000000011211122626226260000000051111611000000001000000081111111a1111111b1111111c11111110000000000000000000000000000000000000000
00000000101011122666666200000000511161110000000010000000e11111119111111131111111c11111110000000000000000000000000000000000000000
000000001011101222666622000000001516115100000000000100011e1111e119111191131111311c1111c10000000000000000000000000000000000000000
000000000021112262266226000000001551111500000000100000001ee1111e19911119133111131cc1111c0000000000000000000000000000000000000000
000000000212121062222226000000001555111500000000001000011eee111e19991119133311131ccc111c0000000000000000000000000000000000000000
000000000001200066622666000000001551555500000000101110111ee1eeee19919999133133331cc1cccc0000000000000000000000000000000000000000
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
00000000000000000000000000000000000000000000000000000000000000006313131313131313131313131313131363131313131313131313131313131313
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000001313131313131313131313131313131313131313131313131313131313131313
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000001313131313131313131313131313131313131313131313131313131313131313
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000001313131313131313131313131313131313131313131313136373631313131313
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000001313131313131313131313131313131313131313131313136363631313131313
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000001313131313131313131313131313131313131313505050505050505050501313
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000001313131313505013505013131313131313131350505050505050505050501313
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000131373636350a350a35013131313131313135050505050505050505050501313
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000001313131313135002501313131313131313135050505050025050505050501313
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000131313131350a350a35050505063731313131350505050505050505050636313
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000131313131350501350505063631313131313131313a3505050a3505050637313
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000001313131313136313136363636313131313131313131350505050505050636313
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000001313131313136313136363736313131313131313131350505050505050131313
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000001313131313137313136363636313131313131313131350505050505050131313
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000001313131313131313131313131313131313131313131313131313131313131313
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000001313131313131313131313131313131313131313131313131313131313131313
__gff__
0000000000000400010000000000000000000000000000000000000000000000000000000000000000000000000000000001030000000200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__map__
3631313131313131313131313131313136313131313131313131313131313131363131313131313131313131313131313631313131313131313131313131313136313131313131313131313131313131363131313131313131313131313131313631313131313131313131313131313110000000000000000000000000000000
3131313131313131313131313131313131313131313131313131313131313131313131313131313131313131313131313131313131313131313131313131313131313131313131313131313131313131313131313131313131313131313131313131313131313131313131313131313100000000000000000000000000000000
3131313131313131313131313131313131373631313131313131313136373131313131313131313131313131313131313131313131313131313131313131313131313131313131313131313131313131313131313131313131313131313131313131313131313131313131313131313100000000000000000000000000000000
3131313131313131313131313131313131363636313131313131313636363131313131313131313136373631313131313131313131313131363736313131313131313131313131313131313131313131313131313131313131313131313131313131313131313131313131313131313100000000000000000000000000000000
3131313131313131313131313131313131313636363131313131363636313131313131313131313136363631313131313131313131313131363636313131313131313131313131313131313131313131313131050505050505370505050531313131053805050505380505050505383100000000000000000000000000000000
3131313131313131313131313131313131313136363631313136363631313131313131310505050505050505050531313131313105050505050505050505313131313131313131313131313131313131313105050505050505050537050531313131380606060606060606060606053100000000000000000000000000000000
3131313131313131313131313131313131313131363636313636363131313131313131050505050505050505050531313131310505050505050505050505313131313131310505310505313131313131313105060606050505050505050531313131050606060632060606060606053100000000000000000000000000000000
313131310505050505050505050505313131313131363805383631313131313131310505050505050505050505053131313105050505050505050505050531313131373636053a053a05313131313131313705063206380505390505060531313131050632060606380606320606393100000000000000000000000000000000
3131313105050505050505053636363131313131313105200531313131313131313105050505052005050505050531313131050505050520050505050505313131313131313105200531313131313131313105060606050505200506060605313131050606060606062006060606053100000000000000000000000000000000
313131313905050505050505363736313131313131310505053131313131313131313105050505050505050505363631313131050505050505050505053636313131313131053a053a050505053637313131050505050505053a06063206053731313805060632063a0606060632053100000000000000000000000000000000
3131313105050505052005053636363131313131313105050531313131313131313131313105050505393905053637313131313131390505053a05050536373131313131310505310505053636313131313131050505050505050506063205313131050506060606060632060606053100000000000000000000000000000000
3131313105050505050505050505053131313131313105050531313131313131313131313131050505050505053636313131313131310505050505050536363131313131313136313136363636313131313131050505050505050505060505313131050505050505050505050505053100000000000000000000000000000000
3131313131313131313131313131313131313131313139053931313131313131313131313131050505050505053131313131313131310505050505050531313131313131313136313136363736313131313131050505050505050505050531313131363636363636050505050505053100000000000000000000000000000000
3131313131313131313131313131313131313131313131313131313131313131313131313131050505050505053131313131313131310505050505050531313131313131313137313136363636313131313131050505050505370538050531313131363636363636380505050505053100000000000000000000000000000000
3131313131313131313131313131313131313131313131313131313131313131313131313131313131313131313131313131313131313131313131313131313131313131313131313131313131313131313131313131313131313131313131313131363637363636363631313131313100000000000000000000000000000000
3131313131313131313131313131313131313131313131313131313131313131313131313131313131313131313131313131313131313131313131313131313131313131313131313131313131313131313131313131313131313131313131313131313131313131313131313131313100000000000000000000000000000000
__sfx__
010600001875424754187540c754307003c700007000c7001870024700307003c700007000c7001870024700307003c700007000c7001870024700307003c700007000c7001870024700307003c700007000c700
000300003c6113061124611186010c601006011860118601006010060100601006010060100601006010060100601006010060100601006010060100601006010060100601006010060100601006010060100601
0101000000100031600416007160091500a1400d14011130151201912022120291202f110361103e1003f10006100051000510005100051000510005100041000410004100041000510006100071000010000100
010500000c652246323c6120000200002000020000200002000020000200002000020000200002000020000200002000020000200002000020000200002000020000200002000020000200002000020000200002
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
011400000c050000000c0000c050000000c0500e050100500e05000000000000e050000000e050100501105013050130000000013050000001305011050100501105000000000001105000000130501105010050
011400000c455004050c4050c455004050c4550e455104550c455004050c4050c455004050c4550e455104550c455004050c4050c455004050c4550e455104550c455004050c4050c455004050c4550e45510455
011400000e45500405004050e455004050e45510455114550e45500405004050e455004050e45510455114550e45500405004050e455004050e45510455114550e45500405004050e455004050e4551045511455
01140000134551340500405134550040513455114551045513455134050040513455004051345511455104550e45500405004050e455004050e45510455114551145500405004051145500405134551145510455
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
011400000c05300005000050000518655000050c053000050c053000050000500005186550000500005000050c053000050000500005186550000500005000050c05300005000050000518655000050c0530c000
011400000c05300005000050000518655000050c053000050c053000050000500005186550000500005000050c05300005000050000518655000050c053000050c053186000c0530c05318655186550c05318655
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0114000024556285362b526305160050600506005060050624556285362b526305160050600506005060050624556285362b526305160050600506005060050624556285362b5263051600506005060050600506
0114000026556295362d526325160050600506005060050626556295362d526325160050600506005060050626556295362d526325160050600506005060050626556295362d5263251600506005060050600506
011400002b556285362f52637516000060000600006000062b556285362f526375160000600006000060000626556295362d5263251600006000060000600006295562d536305263551600006000060000600006
__music__
00 06424344
00 07434344
00 08424344
01 060a1444
00 070a1544
02 080b1644

