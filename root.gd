extends Node2D

#constant
var x_min: float
var x_max: float
var y_min: float
var y_max: float
var view: Rect2
var h_skip: float
var rotate_speed=2
var player_wide_ratio: float=0.1
var layer_h: float
var board_w_ratio: float=0.09
var board_v_ratio: float=0.2
var g: float
var high: float
var vx_max: float
var vy_max: float
var bottom_offset: Vector2
var move_x_ratio_key=0.05
var color_bg=Color(1,1,1)
var color_fg=Color(0.4,0.4,0.4)
var color_fg_half=Color(0.7,0.7,0.7)
var cap
var cloud

#node
var sprite: Sprite2D
var spriteL: Sprite2D
var spriteR: Sprite2D
var cam: Camera2D
var score_label: Label
var but: TouchScreenButton

#change during a run
var v: Vector2
var layer: int=0
var layer_highest: int=0
var gyro: Vector3
var acce: Vector3
var score: int=0
var fly: bool=false
var board_x_ratio: Array=[]
var board_v: Array=[]
var board_bounce_high: Array=[]
var board_break: Array=[]
var board_on: Array=[]
var board_die: Array=[]
var board_show: Array=[]
var board_shine: Array=[]
var board_fly: Array=[]

#change per run
var best_score: int=0
var last_best_score :int=0
var game:bool=true

func wait_and_do(time: float, callback: Callable):
	var timer = Timer.new()
	add_child(timer)
	timer.wait_time = time
	timer.one_shot = true
	timer.timeout.connect(callback)
	timer.start()

func make_board(para:Dictionary) -> void:
	board_x_ratio.append(randf())
	board_v.append(para.get("v",0))
	board_bounce_high.append(para.get("bounce_high",false))
	board_break.append(para.get("break",false))
	board_on.append(para.get("on",true))
	board_die.append(para.get("die",false))
	board_show.append(para.get("show",true))
	board_shine.append(para.get("shine",false))
	board_fly.append(para.get("fly",false))

func add_board() -> void:
	var r1=randi_range(1,3)
	if r1==3:
		var r2=randi_range(1,7)
		if r2==1 or r2==5:
			#high-bouncing board
			make_board({"bounce_high":true})
		elif r2==6:
			#strike board or face
			make_board({"die":true,"v":randi_range(-1,1)})
		elif r2==3:
			make_board({"fly":true})
		elif r2==2:
			#one-used board
			make_board({"break":true})
		elif r2==7:
			make_board({"shine":true})
		else:
			#cloud
			make_board({"on":false})
	else:
		#normal board
		make_board({"v":randi_range(-1,1)})

func sprite_pos_bottom() -> Vector2:
	return sprite.position+bottom_offset
	
func set_sprite_pos_bottom(v: Vector2) -> void:
	sprite.position=v-bottom_offset

func _ready() -> void:
	#constant
	view=get_viewport_rect()
	x_min=0
	x_max=view.size.x
	y_min=0
	y_max=view.size.y
	layer_h=0.1*view.size.y
	bottom_offset=Vector2(0,player_wide_ratio*view.size.x/2)
	g=view.size.y/2*1.5
	h_skip=(y_max-y_min)/3
	vx_max=view.size.x/sqrt(2*h_skip/g)
	vy_max=sqrt(g*2*h_skip)
	
	cap=preload("res://cap0.png")
	cloud=preload(("res://cloud.png"))
	#node000
	sprite=Sprite2D.new()
	spriteL=Sprite2D.new()
	spriteR=Sprite2D.new()
	sprite.texture = preload("res://bird_l.png")
	spriteL.texture = preload("res://bird_l.png")
	spriteR.texture = preload("res://bird_r.png")
	add_child(sprite)
	add_child(spriteR)
	add_child(spriteL)
	var ori_x=sprite.texture.get_width()
	var ori_y=sprite.texture.get_height()
	sprite.scale=Vector2(player_wide_ratio*view.size.x/ori_x,player_wide_ratio*view.size.x/ori_y)
	spriteR.scale=sprite.scale
	spriteL.scale=sprite.scale
	
	cam=Camera2D.new()
	add_child(cam)
	cam.make_current()
	cam.zoom=Vector2(1,1)
	
	#var font=load("res://wipi.ttc")
	score_label=Label.new()
	add_child(score_label)
	score_label.position=Vector2(cam.position)
	score_label.modulate=color_fg
	#score_label.add_theme_font_override("font",font)
	score_label.add_theme_font_size_override("font_size",24)
	
	start()

func set_RL():
	spriteL.position=sprite.position-Vector2(view.size.x,0)
	spriteR.position=sprite.position+Vector2(view.size.x,0)
	spriteL.rotation=sprite.rotation
	spriteR.rotation=sprite.rotation

func die():
	game=false
	reset()
	
	but = TouchScreenButton.new()
	add_child(but)
	#but.name="VirtualButton"
	but.texture_normal=preload("res://restart.png")
	but.texture_pressed=preload("res://restart.png")
	var off=but.texture_normal.get_size()
	but.scale=0.3*view.size.x/off.x*Vector2(1,1)
	but.position=view.get_center()-but.scale.x*off/2
	but.action="ui_start"
	but.pressed.connect(_on_but_pressed)

func _on_but_pressed():
	game=true
	start()
	but.queue_free()

func _process(delta: float) -> void:
	gyro = Input.get_gyroscope()
	acce = Input.get_accelerometer()
	if not fly:
		v.y+=g*delta
	v.x=acce.x/9.8*vx_max
	sprite.rotation+=gyro.z*delta
	sprite.position+=v*delta
	if sprite_pos_bottom().x<x_min:
		sprite.position.x=x_max
	if sprite_pos_bottom().x>x_max:
		sprite.position.x=x_min
	if game:
		high=view.size.y-sprite_pos_bottom().y
		var layer_new=floor(high/layer_h)
		if layer_new<layer:
			var ran=board_w_ratio*view.size.x*(1-board_w_ratio)+view.size.x*player_wide_ratio
			var dif=sprite.position.x-board_x_ratio[layer]*view.size.x*(1-board_w_ratio)+view.size.x*player_wide_ratio/2
			while dif<0:
				dif+=view.size.x
			while dif>view.size.x:
				dif-=view.size.x
			if dif<=ran:
				if board_on[layer]:
					#
					if board_die[layer]:
						if board_v[layer]==0:
							die()
						else:
							if randi_range(0,1)==0:
								die()
					if board_bounce_high[layer] or board_fly[layer]:
						v.y=-2*vy_max
					else:
						v.y=-vy_max
					if board_break[layer]:
						board_on[layer]=false
						board_show[layer]=false
					if board_fly[layer]:
						fly=true
						wait_and_do(3,func():fly=false)

					set_sprite_pos_bottom(Vector2(sprite.position.x,view.size.y-layer*layer_h))
					score=layer_highest*4
				elif board_show[layer]:
					board_show[layer]=false
			if OS.get_name() == "Android":
				var vibrator = Engine.get_singleton("AndroidVibrator")
				vibrator.vibrate(100)  # 持續 500 毫秒
		layer=layer_new
		if layer>layer_highest:
			layer_highest=layer
		if cam.position.y>sprite_pos_bottom().y:
			cam.position.y=sprite_pos_bottom().y
		while layer+15>len(board_x_ratio):
			add_board()
		for i in range(20):
			var n=layer-5+i
			board_x_ratio[n]+=board_v[n]*board_v_ratio*delta
			if board_x_ratio[n]>1:
				board_x_ratio[n]=1
				board_v[n]=-1
			elif board_x_ratio[n]<0:
				board_x_ratio[n]=0
				board_v[n]=1
		
		if best_score<score:
			best_score=score
		set_score_label()
		
		if sprite_pos_bottom().y>cam.position.y+view.size.y/2:
			die()
		else:
			queue_redraw()
	else:
		if sprite_pos_bottom().y>cam.position.y+view.size.y/2:
			v.y=-vy_max
			if OS.get_name() == "Android":
				var vibrator = Engine.get_singleton("AndroidVibrator")
				vibrator.vibrate(100)  # 持續 500 毫秒
		queue_redraw()
	set_RL()

func re() -> void:
	set_sprite_pos_bottom(view.get_center())
	
func start() -> void:
	set_process(false)
	layer=0
	board_x_ratio=[]
	layer_highest=0
	score=0
	fly=false
	last_best_score=best_score
	sprite.position=Vector2(view.size.x/2,view.size.y*(1-player_wide_ratio/2)-h_skip)
	v=Vector2(0,-vy_max)
	cam.position=view.get_center()
	for i in range(15):
		add_board()
	set_score_label()
	set_process(true)

func reset() -> void:
	set_process(false)
	layer=0
	board_x_ratio=[]
	layer_highest=0
	score=0
	fly=false
	last_best_score=best_score
	sprite.position=Vector2(view.size.x/2,view.size.y*(1-player_wide_ratio/2)-h_skip)
	v=Vector2(0,-vy_max)
	cam.position=view.get_center()
	set_score_label()
	set_process(true)


func _input(event) -> void:
	if event is InputEventKey and event.is_pressed():
		if event.keycode == KEY_LEFT:
			var posx = sprite.position.x-move_x_ratio_key*view.size.x
			if posx<0:
				posx+=view.size.x
			sprite.position.x=posx
		if event.keycode == KEY_RIGHT:
			var posx = sprite.position.x+move_x_ratio_key*view.size.x
			if posx>view.size.x:
				posx-=view.size.x
			sprite.position.x=posx
		
func set_score_label() -> void:
	score_label.position=Vector2(cam.position-view.size/2)
	score_label.text="Best Score: "+str(best_score)+"\n"+"Score: "+str(score)

func _draw() -> void:
	draw_rect(Rect2(cam.position-cam.get_viewport_rect().size/2,cam.get_viewport_rect().size),color_bg,true)
	if game:
		var n
		var line_high
		var x_ratio
		for i in range(15):
			n=layer-4+i
			if n>=0 and board_show[n]:
				x_ratio=board_x_ratio[n]
				line_high=view.size.y-n*layer_h
				if line_high<cam.position.y+view.size.y:
					var dis=abs(n-high/layer_h)
					if not board_shine[n]:
						if board_bounce_high[n]:
							draw_line(Vector2(x_ratio*view.size.x*(1-board_w_ratio),line_high),Vector2((x_ratio+board_w_ratio)*view.size.x*(1-board_w_ratio),line_high),color_fg,6)
							draw_line(Vector2(x_ratio*view.size.x*(1-board_w_ratio),line_high),Vector2((x_ratio+board_w_ratio)*view.size.x*(1-board_w_ratio),line_high),color_bg,2)
						elif board_break[n]:
							draw_line(Vector2(x_ratio*view.size.x*(1-board_w_ratio),line_high),Vector2((x_ratio+board_w_ratio)*view.size.x*(1-board_w_ratio),line_high),color_fg,6)
							for j in range(5):
								draw_line(Vector2((x_ratio+board_w_ratio*(2*j)/10)*view.size.x*(1-board_w_ratio),line_high),Vector2((x_ratio+board_w_ratio*(2*j+1)/10)*view.size.x*(1-board_w_ratio),line_high),color_bg,6)
						elif board_die[n]:
							if board_v[n]==0:
								draw_line(Vector2(x_ratio*view.size.x*(1-board_w_ratio),line_high),Vector2((x_ratio+board_w_ratio)*view.size.x*(1-board_w_ratio),line_high),color_fg,6)
								for j in range(3):
									var p1=Vector2((x_ratio+board_w_ratio*(2*j)/6)*view.size.x*(1-board_w_ratio),line_high)
									var p2=Vector2((x_ratio+board_w_ratio*(2*j+1)/6)*view.size.x*(1-board_w_ratio),line_high-board_w_ratio*view.size.x*(1-board_w_ratio)/2)
									var p3=Vector2((x_ratio+board_w_ratio*(2*j+2)/6)*view.size.x*(1-board_w_ratio),line_high)
									var points=[p1,p2,p3]
									var colors=[color_fg,color_fg,color_fg]
									draw_polygon(points,colors)
							else:
								draw_circle(Vector2((x_ratio+board_w_ratio/2)*view.size.x*(1-board_w_ratio),line_high),(board_w_ratio/3)*view.size.x*(1-board_w_ratio),color_fg,false,3)
						elif board_fly[n]:
							draw_line(Vector2(x_ratio*view.size.x*(1-board_w_ratio),line_high),Vector2((x_ratio+board_w_ratio)*view.size.x*(1-board_w_ratio),line_high),color_fg,6)
							#var r=(board_w_ratio/5)*view.size.x*(1-board_w_ratio)
							#draw_circle(Vector2((x_ratio+board_w_ratio/2)*view.size.x*(1-board_w_ratio),line_high-2*r),r,Color(1,0,0),true,3)
							var r=(board_w_ratio)*view.size.x*(1-board_w_ratio)
							var pos=Vector2((x_ratio+board_w_ratio/2)*view.size.x*(1-board_w_ratio),line_high-r/2)
							var siz=Vector2(r*3/4,r/2)
							var rect=Rect2(pos-siz/2,siz)
							draw_texture_rect(cap,rect,false)

						elif not board_on[n]:
							var rect=Rect2(Vector2(x_ratio*view.size.x*(1-board_w_ratio),line_high-6),Vector2((board_w_ratio)*view.size.x*(1-board_w_ratio),12))
							draw_texture_rect(cloud,rect,false)
							#draw_line(Vector2(x_ratio*view.size.x*(1-board_w_ratio),line_high),Vector2((x_ratio+board_w_ratio)*view.size.x*(1-board_w_ratio),line_high),color_fg,10)
							#draw_line(Vector2(x_ratio*view.size.x*(1-board_w_ratio)+2,line_high),Vector2((x_ratio+board_w_ratio)*view.size.x*(1-board_w_ratio)-2,line_high),color_bg,6)
						else:
							draw_line(Vector2(x_ratio*view.size.x*(1-board_w_ratio),line_high),Vector2((x_ratio+board_w_ratio)*view.size.x*(1-board_w_ratio),line_high),color_fg,6)
					elif dis<=2:
						var c=0.4+dis/2*0.6
						draw_line(Vector2(x_ratio*view.size.x*(1-board_w_ratio),line_high),Vector2((x_ratio+board_w_ratio)*view.size.x*(1-board_w_ratio),line_high),Color(c,c,c),6)

		var best_line_high=view.size.y-last_best_score/4*layer_h
		for i in range(10):
			draw_line(Vector2(view.size.x*2*i/20,best_line_high),Vector2(view.size.x*(2*i+1)/20,best_line_high),color_fg,2)
		if fly:
			var r=(board_w_ratio)*view.size.x*(1-board_w_ratio)
			var pos=sprite_pos_bottom()+Vector2(0,-player_wide_ratio*view.size.x-r/3)
			var siz=Vector2(r*3/4,r/2)
			var rect=Rect2(pos-siz/2,siz)
			draw_texture_rect(cap,rect,false)
			#draw_circle(sprite_pos_bottom()+Vector2(0,-player_wide_ratio*view.size.x-2*r),r,Color(1,0,0),true,3)
