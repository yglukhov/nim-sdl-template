import opengl
import typetraits
#import graphics

type Coord* = float32

type Point* = tuple[x, y: Coord]
type Size* = tuple[width, height: Coord]
type Rect* = tuple[origin: Point, size: Size]

proc x*(r: Rect): Coord = r.origin.x
proc y*(r: Rect): Coord = r.origin.y
proc width*(r: Rect): Coord = r.size.width
proc height*(r: Rect): Coord = r.size.height

proc minX*(r: Rect): Coord = r.x
proc maxX*(r: Rect): Coord = r.x + r.width
proc minY*(r: Rect): Coord = r.y
proc maxY*(r: Rect): Coord = r.y + r.height

type ButtonState = enum
    bsUnknown, bsUp, bsDown

type EventKind = enum
    ekMouseMove, ekMouseAction

type MouseEvent = tuple[position: Point, kind: EventKind, state: ButtonState]

type
    View* = ref TView
    TView = object of RootObj
        frame: Rect
        bounds: Rect
        subviews: seq[View]
        superview: PView

    PView = ptr TView

proc newRect*(x, y, w, h: Coord): Rect =
    result.origin.x = x
    result.origin.y = y
    result.size.width = w
    result.size.height = h

proc newSize*(w, h: Coord): Size =
    result.width = w
    result.height = h

proc new*(a: typedesc[Rect], x, y, w, h: Coord): Rect =
    result.origin.x = x
    result.origin.y = y
    result.size.width = w
    result.size.height = h

method init*(v: View, frame: Rect) =
    v.frame = frame
    v.bounds = Rect.new(0, 0, frame.width, frame.height)
    v.subviews = @[]

proc convertCoordinates*(p: Point, fromView, toView: View): Point =
    if fromView == toView: return p
    if fromView == nil: # p is screen coordinates
        discard
    return p

proc convertCoordinates*(r: Rect, fromView, toView: View): Rect =
    r

method draw*(view: View)

method drawSelf*(view: View) =
    discard

method drawSubviews*(view: View) =
    for i in view.subviews:
        i.draw()

method draw*(view: View) =
    view.drawSelf()
    view.drawSubviews()

method handleMouseEventRecursive(v: View, e: MouseEvent, translatedCoords: Point): bool =
    for i in v.subviews:
        discard 
