class_name OverlayView
extends Control

# Request another registered page within the current overlay session.
# Gameplay confirmation/cancellation uses separate signals routed by the host.
signal navigation_requested(menu_name: StringName)
