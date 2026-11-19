extends Button


func _make_custom_tooltip(for_text: String) -> Object:
	var term := RegEx.create_from_string("(?i)\\b(attack|block|time action|time rewind)\\b")
	var color := get_theme_color("font_color").to_html(false)
	var description := RichTextLabel.new()
	description.bbcode_enabled = true
	description.fit_content = true
	description.scroll_active = false
	description.autowrap_mode = TextServer.AUTOWRAP_OFF
	description.text = term.sub(for_text, "[color=#%s][b]$1[/b][/color]" % color, true)
	return description
