import AVFoundation

class VideoReader: NSObject {
  private let singleFrameInterval: NSTimeInterval = 0.02
  private var videoOutput: AVPlayerItemVideoOutput!
  private var playerItem: AVPlayerItem!
  private var videoOutputQueue: dispatch_queue_t!
  
  init(playerItem: AVPlayerItem) {
    self.playerItem = playerItem
    super.init()

    let pixelBufferAttributes = [kCVPixelBufferPixelFormatTypeKey as String : NSNumber(unsignedInt: kCVPixelFormatType_32BGRA)]
    videoOutput = AVPlayerItemVideoOutput(pixelBufferAttributes: pixelBufferAttributes)
    playerItem.addOutput(videoOutput)
  }

  deinit {
    playerItem.removeOutput(videoOutput)
  }
  
  func currentFrame(frameHandler: ((size: CGSize, frameData: UnsafeMutablePointer<Void>) -> (Void))?) {
    guard let pixelBuffer = videoOutput.copyPixelBufferForItemTime(playerItem.currentTime(), itemTimeForDisplay: nil)
      where playerItem?.status == .ReadyToPlay
      else { return }
    
    CVPixelBufferLockBaseAddress(pixelBuffer, kCVPixelBufferLock_ReadOnly)
    
    let width = CVPixelBufferGetWidth(pixelBuffer)
    let height = CVPixelBufferGetHeight(pixelBuffer)
    let baseAddress = CVPixelBufferGetBaseAddress(pixelBuffer)
    frameHandler?(size: CGSize(width: width, height: height), frameData: baseAddress)
    
    CVPixelBufferUnlockBaseAddress(pixelBuffer, kCVPixelBufferLock_ReadOnly)
  }

}
