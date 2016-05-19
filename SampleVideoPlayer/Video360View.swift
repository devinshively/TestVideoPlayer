import GLKit

class Video360View: GLKView {
  var skysphere: Skysphere?
  
  var camera = Camera() {
    didSet {
      setNeedsDisplay()
    }
  }
  
  override func layoutSubviews() {
    super.layoutSubviews()
    camera.aspect = fabsf(Float(bounds.size.width / bounds.size.height))
  }
  
  override func display() {
    super.display()
    glClearColor(0, 0, 0, 1.0)
    glClear(GLbitfield(GL_COLOR_BUFFER_BIT))
    skysphere?.render(camera)
  }  
}
