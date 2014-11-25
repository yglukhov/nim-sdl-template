import strutils

# Hopefully these will be fixed one day
import "../patched_temp_stuff/sdl2"
import "../patched_temp_stuff/opengl"


const isMobile = defined(ios) or defined(android)

# Support logging on iOS and android
when defined(macosx) or defined(ios):
    {.emit: """

    #include <CoreFoundation/CoreFoundation.h>
    extern void NSLog(CFStringRef format, ...);

    """.}

    proc NSLog_imported(a: cstring) =
        {.emit: "NSLog(CFSTR(\"%s\"), a);" .}

    proc log(a: varargs[string, `$`]) = NSLog_imported(a.join())
elif defined(android):
    {.emit: """
    #include <android/log.h>
    """.}

    proc droid_log_imported(a: cstring) =
        {.emit: """__android_log_print(ANDROID_LOG_INFO, "NIM_APP", a);""".}
    proc log(a: varargs[string, `$`]) = droid_log_imported(a.join())
else:
    proc log(a: varargs[string, `$`]) = echo a


template c(a: string) = discard

#extern DECLSPEC int SDLCALL SDL_iPhoneSetAnimationCallback(SDL_Window * window, int interval, void (*callback)(void*), void *callbackParam);
proc iPhoneSetAnimationCallback(window: PWindow, interval: int, callback: proc(p: ptr RootObj) {.cdecl.}, callbackParam: ptr RootObj): int {.importc: "SDL_iPhoneSetAnimationCallback", header: "<SDL2/SDL.h>".}

var displayMode : TDisplayMode
discard GetDesktopDisplayMode(0, displayMode)

var flags = SDL_WINDOW_OPENGL or SDL_WINDOW_RESIZABLE
when isMobile:
    flags = flags or SDL_WINDOW_FULLSCREEN

when not isMobile:
    displayMode.w = 800
    displayMode.h = 600

var window = CreateWindow("SDL Skeleton", 0, 0, displayMode.w, displayMode.h, flags)

if window == nil:
    log("Could not create window!")
    quit 1

var r = 0.0
var g = 1.0
var b = 0.0

var dr = 0.02
var dg = 0.03
var db = 0.01

var context = window.GL_CreateContext()

when not defined(ios) and not defined(android):
    loadExtensions()

proc render() =
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

    glClearColor(r, g, b, 1.0)
    glClear(GL_COLOR_BUFFER_BIT or GL_DEPTH_BUFFER_BIT) # Clear color and depth buffers

    window.GL_SwapWindow() # Swap the front and back frame buffers (double buffering)

proc animationCallback(p: ptr RootObj) {.cdecl.} =
    render()

proc reshape(x, y: cint) =
    glViewport(0, 0, x, y)                        # Set the viewport to cover the new window

var runGame = true

proc eventFilter(userdata: pointer; event: ptr TEvent): Bool32 {.cdecl.} =
    case event.kind:
        of FingerMotion:
            log("finger motion")
            return False32
        of FingerDown:
            log("Finger down")
            return False32
        of FingerUp:
            log("Finger up")
            return False32
        of WindowEvent:
            let wndEv = cast[PWindowEvent](event)
            case wndEv.event:
                of WindowEvent_Resized:
                    reshape(wndEv.data1, wndEv.data2)
                    return False32
                else: discard
        of AppWillEnterBackground:
            when defined(ios):
                runGame = false

        else: discard
    log "Event: ", $event.kind
    return True32

when defined(ios):
    discard iPhoneSetAnimationCallback(window, 0, animationCallback, nil)

SetEventFilter(eventFilter, nil)

# Framerate limiter
let MAXFRAMERATE: uint32 = 20 # milli seconds
var frametime: uint32 

proc limitFramerate() =
  var now = GetTicks()
  if frametime > now:
    Delay(frametime - now)
  frametime = frametime + MAXFRAMERATE

# Main loop
var
  evt: TEvent

proc waitOrPollEvent(evt: var TEvent): auto =
    when defined(ios):
        WaitEvent(evt)
    else:
        PollEvent(evt)

while runGame:
  PumpEvents()
  while waitOrPollEvent(evt):
    if evt.kind == QuitEvent:
      runGame = false
      break
    case evt.kind:
      of MouseMotion:
        log "move"
      else: discard
 
  when not defined(ios):
      render()
      limitFramerate()

GL_DeleteContext(context)
DestroyWindow(window)
Quit()

