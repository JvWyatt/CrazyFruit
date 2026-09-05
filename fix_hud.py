with open("scenes/ui/HUD.tscn", "r") as f:
    content = f.read()

resources_to_add = """[ext_resource type="Texture2D" uid="uid://d1orderbg123" path="res://assets/ui/game/order_progress_bg.png" id="tex_order_bg"]
[ext_resource type="Texture2D" uid="uid://d1orderfill123" path="res://assets/ui/game/order_progress_fill.png" id="tex_order_fill"]
[ext_resource type="Texture2D" uid="uid://d2energybg123" path="res://assets/ui/game/energy_bar_bg.png" id="tex_energy_bg"]
[ext_resource type="Texture2D" uid="uid://d2energyfill123" path="res://assets/ui/game/energy_bar_fill.png" id="tex_energy_fill"]
[ext_resource type="Texture2D" uid="uid://d3streakbg123" path="res://assets/ui/game/streak_bar_bg.png" id="tex_streak_bg"]
[ext_resource type="Texture2D" uid="uid://d3streakfill123" path="res://assets/ui/game/streak_bar_fill.png" id="tex_streak_fill"]
"""

last_ext_index = content.rfind("[ext_resource")
end_of_last_ext = content.find("]", last_ext_index) + 1
content = content[:end_of_last_ext] + "\n" + resources_to_add + content[end_of_last_ext:]

# Simple string replacements
content = content.replace(
    '[node name="OrderProgressBar" type="ProgressBar" parent="TopContainer/VBox"]',
    '[node name="OrderProgressBar" type="TextureProgressBar" parent="TopContainer/VBox"]'
)
content = content.replace(
    '[node name="EnergyBar" type="ProgressBar" parent="TopContainer/VBox/EnergyContainer"]',
    '[node name="EnergyBar" type="TextureProgressBar" parent="TopContainer/VBox/EnergyContainer"]'
)
content = content.replace(
    '[node name="StreakBar" type="ProgressBar" parent="StreakPanel/VBox"]',
    '[node name="StreakBar" type="TextureProgressBar" parent="StreakPanel/VBox"]'
)

# Now we need to append the texture settings just before the next node definition.
# I'll just find the "show_percentage = false" for each and replace it.

content = content.replace(
    'value = 40.0\nshow_percentage = false',
    'value = 40.0\ntexture_under = ExtResource("tex_order_bg")\ntexture_progress = ExtResource("tex_order_fill")\nnine_patch_stretch = true\nstretch_margin_left = 6\nstretch_margin_top = 6\nstretch_margin_right = 6\nstretch_margin_bottom = 6\nshow_percentage = false'
)

content = content.replace(
    'value = 100.0\nshow_percentage = false',
    'value = 100.0\ntexture_under = ExtResource("tex_energy_bg")\ntexture_progress = ExtResource("tex_energy_fill")\nnine_patch_stretch = true\nstretch_margin_left = 6\nstretch_margin_top = 6\nstretch_margin_right = 6\nstretch_margin_bottom = 6\nshow_percentage = false'
)

content = content.replace(
    'value = 0.0\nshow_percentage = false',
    'value = 0.0\ntexture_under = ExtResource("tex_streak_bg")\ntexture_progress = ExtResource("tex_streak_fill")\nnine_patch_stretch = true\nstretch_margin_left = 6\nstretch_margin_top = 6\nstretch_margin_right = 6\nstretch_margin_bottom = 6\nshow_percentage = false'
)

with open("scenes/ui/HUD.tscn", "w") as f:
    f.write(content)
print("Done")
