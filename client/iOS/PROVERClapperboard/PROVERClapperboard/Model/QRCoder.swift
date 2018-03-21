import Foundation
import UIKit
import BigInt

struct QRCoder {
  
  func encode(_ block: [UInt8]) -> UIImage {
        
    let bigNumber = BigUInt(Data(block))
    let description = bigNumber.description
    let data = description.data(using: .isoLatin1)
    let transform = CGAffineTransform(scaleX: 5, y: 5)
    
    let qrFilter = CIFilter(name: "CIQRCodeGenerator")!
    qrFilter.setValue(data, forKey: "inputMessage")
    qrFilter.setValue("M", forKey: "inputCorrectionLevel")
    let qrImage = qrFilter.outputImage!
    
    let colorInvertFilter = CIFilter(name: "CIColorInvert")!
    colorInvertFilter.setValue(qrImage, forKey: "inputImage")
    let colorInvertImage = colorInvertFilter.outputImage!
    
    let maskToAlphaFilter = CIFilter(name: "CIMaskToAlpha")!
    maskToAlphaFilter.setValue(colorInvertImage, forKey: "inputImage")
    let maskToAlphaImage = maskToAlphaFilter.outputImage!
    
    let image = UIImage(ciImage: maskToAlphaImage.transformed(by: transform))
    print(image.size)
    
    return image.withRenderingMode(.alwaysTemplate)
  }
}
