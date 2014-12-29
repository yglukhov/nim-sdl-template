import strutils
import sdl2
import opengl
import nimx.sdl_window
import nimx.view
import nimx.logging


const isMobile = defined(ios) or defined(android)

template c(a: string) = discard

log "STARTING!"
var mainWindow = when isMobile:
        newFullscreenSdlWindow()
    else:
        newSdlWindow(newRect(0, 0, 800, 600))

when not defined(ios) and not defined(android):
    loadExtensions()

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

setEventHandler(eventFilter, nil)

# Main loop
var
  evt: TEvent

while runGame:
    discard nextEvent(evt)
    if evt.kind == QuitEvent:
      runGame = false
      break
 
Quit()

