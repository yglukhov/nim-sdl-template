
import view

type Window* = ref object of View


method draw*(win: Window) =
    discard


method onResize*(w: Window, newSize: Size) =
    discard
