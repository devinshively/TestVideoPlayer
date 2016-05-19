import GLKit
import CoreMotion

class Camera: NSObject {
  private(set) var projectionMatrix = GLKMatrix4()
  private(set) var viewMatrix = GLKMatrix4()
  
  var fovRadians: Float {
    didSet {
      updateProjectionMatrix()
    }
  }
  
  var aspect: Float {
    didSet {
      updateProjectionMatrix()
    }
  }
  
  var nearZ: Float {
    didSet {
      updateProjectionMatrix()
    }
  }
  
  var farZ: Float {
    didSet {
      updateProjectionMatrix()
    }
  }
  
  var yaw: Float = GLKMathDegreesToRadians(90) {
    didSet {
      updateViewMatrix()
    }
  }
  
  var pitch: Float = 0 {
    didSet {
      let maxPitch = GLKMathDegreesToRadians(60)
      let minPitch = GLKMathDegreesToRadians(-105)
      if pitch > maxPitch {
        pitch = maxPitch
      } else if pitch < minPitch {
        pitch = minPitch
      }
      updateViewMatrix()
    }
  }
  
  init(fovRadians: Float = GLKMathDegreesToRadians(65), aspect: Float = 16.0 / 9.0, nearZ: Float = 1, farZ: Float = 100) {
    self.fovRadians = fovRadians
    self.aspect = aspect
    self.nearZ = nearZ
    self.farZ = farZ
    super.init()
    updateProjectionMatrix()
    updateViewMatrix()
  }
  
  private func updateProjectionMatrix() {
    projectionMatrix = GLKMatrix4MakePerspective(fovRadians, aspect, nearZ, farZ)
  }
  
  private func updateViewMatrix() {
    let cosPitch = cosf(pitch)
    let sinPitch = sinf(pitch)
    let cosYaw = cosf(yaw)
    let sinYaw = sinf(yaw)
    
    let xaxis = GLKVector3(v: (cosYaw, 0, -sinYaw))
    let yaxis = GLKVector3(v: (sinYaw * sinPitch, cosPitch, cosYaw * sinPitch))
    let zaxis = GLKVector3(v: (sinYaw * cosPitch, -sinPitch, cosPitch * cosYaw))
    
    viewMatrix = GLKMatrix4(m: (
                                xaxis.x, yaxis.x, zaxis.x, 0,
                                xaxis.y, yaxis.y, zaxis.y, 0,
                                xaxis.z, yaxis.z, zaxis.z, 0,
                                0, 0, 0, 1
                               ))
  }
}
