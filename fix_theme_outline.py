with open("scripts/autoload/UiTheme.gd", "r") as f:
    content = f.read()

# Add outline color and size for Buttons
insertion = """	theme.set_color("font_outline_color", "Button", Color(0, 0, 0, 0.85))
	theme.set_constant("outline_size", "Button", 5)
	theme.set_color("font_color", "Button", Color(0.94, 0.96, 1.0))"""

content = content.replace('	theme.set_color("font_color", "Button", Color(0.94, 0.96, 1.0))', insertion)

with open("scripts/autoload/UiTheme.gd", "w") as f:
    f.write(content)
