import view
import patched_temp_stuff.opengl
import unsigned
import logging
import sdl2

type ShaderAttribute = enum
    saPosition


const vertexShader = """
attribute vec4 position;

void main()
{
    gl_Position = position;
}
"""

const fragmentShader = """
void main()
{
	gl_FragColor = vec4(1.0, 0, 0, 0);
}
"""

proc loadShader(shaderSrc: string, kind: GLenum): GLuint =
    # Create the shader object
    log "compile shader"
    result = glCreateShader(kind)
    if result == 0:
        return
    log "..."

    # Load the shader source
    var srcArray = [shaderSrc.cstring]
    glShaderSource(result, 1, cast[cstringArray](addr srcArray), nil)
    # Compile the shader
    glCompileShader(result)
    # Check the compile status
    var compiled: GLint
    glGetShaderiv(result, GL_COMPILE_STATUS, addr compiled)
    if compiled == 0:
        var infoLen: GLint
        glGetShaderiv(result, GL_INFO_LOG_LENGTH, addr infoLen)
        if infoLen > 1:
            var infoLog : cstring = cast[cstring](alloc(infoLen + 1))
            glGetShaderInfoLog(result, infoLen, nil, infoLog)
            log "Error compiling shader: ", infoLog
            dealloc(infoLog)
        glDeleteShader(result)
    log "done"

type PrimitiveType = enum
    ptTriangles = GL_TRIANGLES
    ptTriangleStrip = GL_TRIANGLE_STRIP
    ptTriangleFan = GL_TRIANGLE_FAN

type GraphicsContext* = ref object of RootObj
    shaderProgram: GLuint

var gCurrentContext: GraphicsContext

proc newGraphicsContext*(): GraphicsContext =
    result.new()
    log "context init"
    when not defined(ios) and not defined(android):
        loadExtensions()
    log glGetString(GL_VERSION)


    let vShader = loadShader(vertexShader, GL_VERTEX_SHADER)
    if vShader == 0:
        log "No vshader!"

    

    log "create program"
    result.shaderProgram = glCreateProgram()
    if result.shaderProgram == 0:
        log "Could not create program: ", glGetError()
    log "created program"
    result.shaderProgram.glAttachShader(vShader)
    result.shaderProgram.glAttachShader(loadShader(fragmentShader, GL_FRAGMENT_SHADER))
    log "link"
    result.shaderProgram.glLinkProgram()
    var linked : GLint
    glGetProgramiv(result.shaderProgram, GL_LINK_STATUS, addr linked)
    if linked == 0:
        log "Could not link!"

    result.shaderProgram.glBindAttribLocation(GLuint(saPosition), "position")
    result.shaderProgram.glUseProgram()
    log "RUNNING"


proc setCurrentContext*(c: GraphicsContext): GraphicsContext {.discardable.} =
    result = gCurrentContext
    gCurrentContext = c

proc currentContext*(): GraphicsContext = gCurrentContext

proc drawVertexes*(c: GraphicsContext, componentCount: int, points: openarray[Coord], pt: PrimitiveType) =
    assert(points.len mod componentCount == 0)
    glEnableVertexAttribArray(GLuint(saPosition))
    glVertexAttribPointer(GLuint(saPosition), GLint(componentCount), cGL_FLOAT, GLboolean(GL_FALSE), 0, cast[pointer](points))
    #glVertexPointer(GLint(componentCount), GLenum(cGL_FLOAT), 0, cast[pointer](points))
    glDrawArrays(cast[GLenum](pt), 0, GLsizei(points.len / componentCount))

#proc drawVertexes*(c: GraphicsContext, points: openarray[Point], pt: PrimitiveType) =
#    glVertexPointer(2, cGL_FLOAT, 0, cast[pointer](points))
#    glDrawArrays(cast[GLenum](pt), 0, GLsizei(points.len))

proc drawRect*(c: GraphicsContext, r: Rect) =
    let points = [r.minX, r.minY,
                r.maxX, r.minY,
                r.maxX, r.maxY,
                r.minX, r.maxY]
    c.drawVertexes(2, points, ptTriangleFan)

