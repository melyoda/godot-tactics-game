extends TextureProgressBar

func _ready():
	var unit = owner # 'owner' refers to the root of the scene (BaseUnit)
	unit.hp_changed.connect(_update_bar)
	max_value = unit.max_hp
	value = unit.current_hp

func _update_bar(new_hp, _max_hp):
	var tween = create_tween()
	tween.tween_property(self, "value", new_hp, 0.3).set_trans(Tween.TRANS_SINE)
