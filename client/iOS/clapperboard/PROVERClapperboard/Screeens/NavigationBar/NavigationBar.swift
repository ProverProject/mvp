import UIKit

class NavigationBar: UINavigationBar {

    override func layoutSubviews() {
        super.layoutSubviews()

        guard barTintColor == nil else { return }

        let size = CGSize(width: bounds.width,
                height: bounds.height + UIApplication.shared.statusBarFrame.height)
        let image = #imageLiteral(resourceName: "background").resizedImage(newSize: size)
        barTintColor = UIColor(patternImage: image)
        tintColor = .white
    }

    override func sizeThatFits(_ size: CGSize) -> CGSize {
        return CGSize(width: UIScreen.main.bounds.width, height: 96)
    }
}
