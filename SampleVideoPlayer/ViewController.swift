import AVFoundation
import GLKit
import CoreMotion

class ViewController: UIViewController {
  
  @IBOutlet var video360View: Video360View?

  private var context: EAGLContext?
  private var skysphere: Skysphere?
  private var videoReader: VideoReader?
  private var motionManager: CMMotionManager?

  var playerItem: AVPlayerItem?
  var player: AVPlayer?
  var displayLink: CADisplayLink?
  var lastUpdate: CFTimeInterval?
  var timeSinceLastUpdate: CFTimeInterval?
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    playerItem = AVPlayerItem(URL: NSURL(string:"http://www.kolor.com/360-videos-files/noa-neal-graffiti-360-music-video-full-hd.mp4")!)
    player = AVPlayer()
    player?.actionAtItemEnd = .Pause
    player?.replaceCurrentItemWithPlayerItem(playerItem)
    player?.play()
    
    video360View?.enableSetNeedsDisplay = false
    displayLink = CADisplayLink(target: self, selector: #selector(ViewController.render(_:)))
    displayLink?.addToRunLoop(NSRunLoop.currentRunLoop(), forMode:NSRunLoopCommonModes)
    displayLink?.frameInterval = 2
    
    setupMotion()
    setupContext()
  
    skysphere = Skysphere(radius: 60)
    video360View?.skysphere = skysphere
    guard let playerItem = playerItem else { return }
    videoReader = VideoReader(playerItem: playerItem)
  }
  
  func updatePlayerItem(playerItem: AVPlayerItem) {
    self.playerItem = playerItem
    videoReader = VideoReader(playerItem: playerItem)
  }
  
  deinit {
    motionManager = nil
    video360View = nil
    displayLink = nil
    if EAGLContext.currentContext() == context {
      EAGLContext.setCurrentContext(nil)
    }
  }
  
  override func removeFromParentViewController() {
    displayLink?.invalidate()
    super.removeFromParentViewController()
  }
  
  func setupContext() {
    // Want to use OpenGL ES 2.0 for wider device support
    context = EAGLContext(API: .OpenGLES3) // .OpenGLES2
    EAGLContext.setCurrentContext(context)
    guard let context = context else { return }
    video360View?.context = context
  }
  
  func setupMotion() {
    motionManager = CMMotionManager()
    motionManager?.deviceMotionUpdateInterval = 0.01
    let queue = NSOperationQueue.mainQueue()
    motionManager?.startDeviceMotionUpdatesToQueue(queue) { [weak self] data, error in
      guard let rotationRate = data?.rotationRate,
        camera = self?.video360View?.camera else { return }
      let orientation = UIApplication.sharedApplication().statusBarOrientation
      switch orientation {
      case .LandscapeLeft:
        camera.pitch += Float(rotationRate.y/100)
        camera.yaw -= Float(rotationRate.x/100)
      case .LandscapeRight:
        camera.pitch -= Float(rotationRate.y/100)
        camera.yaw += Float(rotationRate.x/100)
      case .Portrait:
        camera.pitch += Float(rotationRate.x/100)
        camera.yaw += Float(rotationRate.y/100)
      case .PortraitUpsideDown, .Unknown: break
      }
    }
  }
  
  func render(displayLink: CADisplayLink) {
    if let lastUpdate = lastUpdate {
      timeSinceLastUpdate = displayLink.timestamp - lastUpdate
    }
    lastUpdate = displayLink.timestamp
    videoReader?.currentFrame({ [weak self] size, frameData in
      self?.skysphere?.updateTexture(size, imageData: frameData)
    })
    video360View?.display()
  }
}
