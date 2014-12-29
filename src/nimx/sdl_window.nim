import window
import sdl2
import os
import logging
import view
import opengl
import context

type SdlWindow = ref object of Window
    impl: PWindow
    sdlGlContext: PGLContext
    renderingContext: GraphicsContext

var allWindows : seq[SdlWindow] = @[]

#extern DECLSPEC int SDLCALL SDL_iPhoneSetAnimationCallback(SDL_Window * window, int interval, void (*callback)(void*), void *callbackParam);
#proc iPhoneSetAnimationCallback(window: PWindow, interval: int, callback: proc(p: ptr RootObj) {.cdecl.}, callbackParam: ptr RootObj): int {.importc: "SDL_iPhoneSetAnimationCallback", header: "<SDL2/SDL.h>".}

proc animationCallback(p: pointer) {.cdecl.} =
    cast[SdlWindow](p).draw()

proc init(w: SdlWindow, r: view.Rect) =
    if w.impl == nil:
        log("Could not create window!")
        quit 1
    procCall init(cast[Window](w), r)
    w.sdlGlContext = w.impl.GL_CreateContext()
    w.renderingContext = newGraphicsContext()

    when defined(ios):
        discard iPhoneSetAnimationCallback(w.impl, 0, animationCallback, cast[pointer](w))
    allWindows.add(w)
    discard w.impl.SetData("__nimx_wnd", cast[pointer](w))

proc newFullscreenSdlWindow*(): SdlWindow =
    result.new()
    
    log "Set profile"
    discard GL_SetAttribute(SDL_GL_CONTEXT_PROFILE_MASK, 0x0004)
    discard GL_SetAttribute(SDL_GL_CONTEXT_MAJOR_VERSION, 2)

    var displayMode : TDisplayMode
    discard GetDesktopDisplayMode(0, displayMode)
    let flags = SDL_WINDOW_OPENGL or SDL_WINDOW_FULLSCREEN
    log "Creating window"
    result.impl = CreateWindow(getAppFilename(), 0, 0, displayMode.w, displayMode.h, flags)
    result.init(newRect(0, 0, Coord(displayMode.w), Coord(displayMode.h)))

proc newSdlWindow*(r: view.Rect, title: string = nil): SdlWindow =
    when defined(ios):
        return newFullscreenSdlWindow()
    else:
        result.new()
        let t = if title == nil: getAppFilename() else: title
        result.impl = CreateWindow(t, cint(r.x), cint(r.y), cint(r.width), cint(r.height), SDL_WINDOW_OPENGL or SDL_WINDOW_RESIZABLE)
        result.init(newRect(0, 0, r.width, r.height))

var r = 0.0
var g = 1.0
var b = 0.0

var dr = 0.02
var dg = 0.03
var db = 0.01


method draw(w: SdlWindow) =
    glClearColor(r, g, b, 1.0)
    glClear(GL_COLOR_BUFFER_BIT or GL_DEPTH_BUFFER_BIT) # Clear color and depth buffers
    var oldContext = setCurrentContext(w.renderingContext)

    r += dr
    g += dg
    b += db

    if r > 1.0:
        r = 1.0
        dr = -dr
    elif r < 0.0:
        r = 0.0
        dr = -dr
    if g > 1.0:
        g = 1.0
        dg = -dg
    elif g < 0.0:
        g = 0.0
        dg = -dg
    if b > 1.0:
        b = 1.0
        db = -db
    elif b < 0.0:
        b = 0.0
        db = -db
    currentContext().drawRect(newRect(50, 50, 100, 100))

    w.drawSubviews()
    w.impl.GL_SwapWindow() # Swap the front and back frame buffers (double buffering)
    setCurrentContext(oldContext)

proc waitOrPollEvent(evt: var TEvent): auto =
    when defined(ios):
        WaitEvent(evt)
    else:
        PollEvent(evt)

proc handleSdlEvent(w: SdlWindow, e: TWindowEvent) =
    case e.event:
        of WindowEvent_Resized:
            w.onResize(newSize(cast[Coord](e.data1), cast[Coord](e.data2)))
        else: discard

var eventHandler: TEventFilter
var eventHandlerUserData: pointer

proc eventFilter(userdata: pointer; event: ptr TEvent): Bool32 {.cdecl.} =
    case event.kind:
        of FingerMotion:
            #log("finger motion")
            return False32
        of FingerDown:
            log("Finger down")
            return False32
        of FingerUp:
            log("Finger up")
            return False32
        of WindowEvent:
            let wndEv = cast[PWindowEvent](event)
            let sdlWndId = wndEv.windowID
            let sdlWin = GetWindowFromID(sdlWndId)
            if sdlWin != nil:
                let wnd = cast[SdlWindow](sdlWin.GetData("__nimx_wnd"))
                if wnd != nil:
                    wnd.handleSdlEvent(wndEv[])
        of AppWillEnterBackground:
            when defined(ios):
                #runGame = false
                discard

        else: discard
    log "Event: ", $event.kind
    return True32

proc setEventHandler*(filter: TEventFilter; userdata: pointer) =
    eventHandler = filter
    eventHandlerUserData = userdata
    SetEventFilter(eventFilter, nil)


method onResize*(w: SdlWindow, newSize: Size) =
    glViewport(0, 0, GLSizei(newSize.width), GLsizei(newSize.height))

# Framerate limiter
let MAXFRAMERATE: uint32 = 20 # milli seconds
var frametime: uint32 

proc limitFramerate() =
  var now = GetTicks()
  if frametime > now:
    Delay(frametime - now)
  frametime = frametime + MAXFRAMERATE

proc nextEvent*(evt: var TEvent): bool =
    PumpEvents()
    while waitOrPollEvent(evt):
        var handled = false
        if evt.kind == WindowEvent:
            let winEvt = cast[PWindowEvent](addr evt)
            let sdlWndId = cast[PWindowEvent](addr evt).windowID
            let sdlWin = GetWindowFromID(sdlWndId)
            if sdlWin != nil:
                let wnd = cast[SdlWindow](sdlWin.GetData("__nimx_wnd"))
                if wnd != nil:
                    wnd.handleSdlEvent(winEvt[])
                    handled = true
        if not handled:
            return false
 
    when not defined(ios):
        for wnd in allWindows:
            wnd.draw()
        limitFramerate()

