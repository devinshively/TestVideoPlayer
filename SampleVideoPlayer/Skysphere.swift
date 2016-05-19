import GLKit
import CoreGraphics
import QuartzCore

typealias VertexPositionComponent = (GLfloat, GLfloat, GLfloat)
typealias VertexTextureCoordinateComponent = (GLfloat, GLfloat)

struct TextureVertex {
  var position: VertexPositionComponent = (0, 0, 0)
  var texture: VertexTextureCoordinateComponent = (0, 0)
}

class Skysphere: NSObject {
  private let radius: Float
  private let rows: Int
  private let columns: Int
  
  init(radius: Float, rows: Int = 50, columns: Int = 50) {
    self.radius = radius
    self.rows = max(2, rows)
    self.columns = max(3, columns)
    super.init()
    prepareEffect()
    load()
  }
  
  deinit {
    unload()
  }
  
  private let effect = GLKBaseEffect()
  private var vertices = [TextureVertex]()
  private var indices = [UInt32]()
  private var vertexArray: GLuint = 0
  private var vertexBuffer: GLuint = 0
  private var indexBuffer: GLuint = 0
  private var texture: GLuint = 0
  
  private func prepareEffect() {
    effect.colorMaterialEnabled = GLboolean(GL_TRUE)
    effect.useConstantColor = GLboolean(GL_FALSE)
  }
  
  private func load() {
    unload()
    
    generateVertices()
    generateIndicesForTriangleStrip()
    
    glGenVertexArraysOES(1, &vertexArray)
    glBindVertexArrayOES(vertexArray)
    
    glGenBuffers(1, &vertexBuffer)
    glBindBuffer(GLenum(GL_ARRAY_BUFFER), vertexBuffer)
    glBufferData(GLenum(GL_ARRAY_BUFFER), sizeof(TextureVertex) * vertices.count, vertices, GLenum(GL_STATIC_DRAW))
    
    glGenBuffers(1, &indexBuffer)
    glBindBuffer(GLenum(GL_ELEMENT_ARRAY_BUFFER), indexBuffer)
    glBufferData(GLenum(GL_ELEMENT_ARRAY_BUFFER), sizeof(UInt32) * indices.count, indices, GLenum(GL_STATIC_DRAW))
    
    
    let ptr = UnsafePointer<GLfloat>(bitPattern: 0)
    let sizeOfVertex = GLsizei(sizeof(TextureVertex))
    
    glEnableVertexAttribArray(GLuint(GLKVertexAttrib.Position.rawValue))
    glVertexAttribPointer(GLuint(GLKVertexAttrib.Position.rawValue), GLint(3), GLenum(GL_FLOAT), GLboolean(GL_FALSE), sizeOfVertex, ptr)
    
    glEnableVertexAttribArray(GLuint(GLKVertexAttrib.TexCoord0.rawValue))
    glVertexAttribPointer(GLuint(GLKVertexAttrib.TexCoord0.rawValue), GLint(2), GLenum(GL_FLOAT), GLboolean(GL_FALSE), sizeOfVertex, ptr.advancedBy(3))
    
    glBindVertexArrayOES(0)
  }
  
  private func unload() {
    vertices.removeAll()
    indices.removeAll()
    
    glDeleteBuffers(1, &vertexBuffer)
    glDeleteBuffers(1, &indexBuffer)
    glDeleteVertexArraysOES(1, &vertexArray)
    glDeleteTextures(1, &texture)
  }
  
  private func generateVertices() {
    let deltaAlpha = Float(2.0 * M_PI) / Float(columns)
    let deltaBeta = Float(M_PI) / Float(rows)
    for row in 0...rows {
      let beta = Float(row) * deltaBeta
      let y = radius * cosf(beta)
      let tv = Float(row) / Float(rows)
      for col in 0...columns {
        let alpha = Float(col) * deltaAlpha
        let x = radius * sinf(beta) * cosf(alpha)
        let z = radius * sinf(beta) * sinf(alpha)
        
        let position = GLKVector3(v: (x, y, z))
        let tu = Float(col) / Float(columns)
        
        let vertex = TextureVertex(position: position.v, texture: (tu, tv))
        vertices.append(vertex)
      }
    }
  }
  
  private func generateIndicesForTriangleStrip() {
    for row in 1...rows {
      let topRow = row - 1
      let topIndex = (columns + 1) * topRow
      let bottomIndex = topIndex + (columns + 1)
      for col in 0...columns {
        indices.append(UInt32(topIndex + col))
        indices.append(UInt32(bottomIndex + col))
      }
      
      indices.append(UInt32(topIndex))
      indices.append(UInt32(bottomIndex))
    }
  }
  
  func loadTexture(image: UIImage?) {
    guard let image = image else { return }
    
    let width = CGImageGetWidth(image.CGImage)
    let height = CGImageGetHeight(image.CGImage)
    let imageData = UnsafeMutablePointer<GLubyte>(calloc(Int(width * height * 4), sizeof(GLubyte)))
    let imageColorSpace = CGImageGetColorSpace(image.CGImage)
    let bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.PremultipliedLast.rawValue)
    let gc = CGBitmapContextCreate(imageData, width, height, 8, 4 * width, imageColorSpace, bitmapInfo.rawValue)
    CGContextDrawImage(gc, CGRectMake(0, 0, CGFloat(width), CGFloat(height)), image.CGImage)
    
    updateTexture(CGSize(width: width, height: height), imageData: imageData)
    free(imageData)
  }
  
  func updateTexture(size: CGSize, imageData: UnsafeMutablePointer<Void>) {
    if texture == 0 {
      glGenTextures(1, &texture)
      glBindTexture(GLenum(GL_TEXTURE_2D), texture)
      
      glTexParameteri(GLenum(GL_TEXTURE_2D), GLenum(GL_TEXTURE_WRAP_S), GLint(GL_REPEAT))
      glTexParameteri(GLenum(GL_TEXTURE_2D), GLenum(GL_TEXTURE_WRAP_T), GLint(GL_REPEAT))
      glTexParameteri(GLenum(GL_TEXTURE_2D), GLenum(GL_TEXTURE_MAG_FILTER), GLint(GL_LINEAR))
      glTexParameteri(GLenum(GL_TEXTURE_2D), GLenum(GL_TEXTURE_MIN_FILTER), GLint(GL_LINEAR))
    }
    
    glBindTexture(GLenum(GL_TEXTURE_2D), texture)
    glTexImage2D(GLenum(GL_TEXTURE_2D), 0, GLint(GL_RGBA), GLsizei(size.width), GLsizei(size.height), 0, GLenum(GL_BGRA), GLenum(GL_UNSIGNED_BYTE), imageData)
  }
  
  func render(camera: Camera) {
    guard texture != 0 else { return }
    
    glBindVertexArrayOES(vertexArray)
    
    effect.transform.projectionMatrix = camera.projectionMatrix
    effect.transform.modelviewMatrix = camera.viewMatrix
    effect.texture2d0.enabled = GLboolean(GL_TRUE)
    effect.texture2d0.name = texture
    effect.prepareToDraw()
    
    let bufferOffset = UnsafePointer<UInt>(bitPattern: 0)
    glDrawElements(GLenum(GL_TRIANGLE_STRIP), GLsizei(indices.count - 2), GLenum(GL_UNSIGNED_INT), bufferOffset)
    
    glBindVertexArrayOES(0)
  }
}
