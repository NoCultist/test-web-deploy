extends Node

## Single chokepoint for all JavaScriptBridge interop. No other script in the
## project should touch JavaScriptBridge directly.

var _callbacks := []

## Exposes a GDScript callable as window.<js_name>() for the landing page (or
## the parent-frame JS) to call into. The callback trampoline checks
## callable.is_valid() before invoking - this matters because scene-owned
## exposures (e.g. Main.gd's box buttons) re-expose in their own _ready(), and
## once SceneRouter frees that scene the old Callable goes invalid. Rather
## than track scene lifecycles here, an invalid callable is just a no-op,
## same as today's has_method() guards.
func expose(js_name: String, callable: Callable) -> void:
	if not OS.has_feature("web"):
		return
	var trampoline := func(_args: Array):
		if callable.is_valid():
			callable.call()
	var js_callback = JavaScriptBridge.create_callback(trampoline)
	_callbacks.append(js_callback)
	var window := JavaScriptBridge.get_interface("window")
	window.set(js_name, js_callback)

## Calls a function on the landing page (window.parent.<fn_name>(...)) since
## the game runs inside the landing page's iframe. Returns the JS return
## value, or null off-web / if the parent hasn't defined the function.
func call_parent(fn_name: String, args: Array = []) -> Variant:
	if not OS.has_feature("web"):
		return null
	var arg_strs := []
	for arg in args:
		if arg is String:
			arg_strs.append("'%s'" % String(arg).replace("\\", "\\\\").replace("'", "\\'"))
		else:
			arg_strs.append(str(arg))
	var call_expr := "window.parent.%s(%s)" % [fn_name, ", ".join(arg_strs)]
	var code := "(window.parent.%s ? %s : null)" % [fn_name, call_expr]
	return JavaScriptBridge.eval(code, true)
