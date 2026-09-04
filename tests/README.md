# Prismaze Tests

Core tests are executed headlessly with Godot:

~~~powershell
godot --headless --path D:/Prismaze --script res://tests/test_runner.gd
~~~

The first expected RED result is:

~~~text
FAIL: GridPosition constructs with requested coordinates
GridPosition production script is missing
~~~

Do not add `grid_position.gd` until this failure has been observed with the
actual Godot runtime.
