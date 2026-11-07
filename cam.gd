extends Camera2D
var zoom_time = 1.1
var r_max=2*Vector2(1,1) #zoom in
var r_min=1*Vector2(1,1) #zoomm out

func _ready()->void:
	print(0)
	#SignalManager.connect("up_signal",Callable(self,"_on_up_signal"))
	position=Vector2(0,0)
	make_current()

func _input(event):
	if event is InputEventMouseButton and event.is_pressed():
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			zoom *= zoom_time
			if zoom > r_max:
				zoom = r_max
		if event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			zoom /= zoom_time
			if zoom < r_min:
				zoom = r_min

func tt():
	print("tt")
