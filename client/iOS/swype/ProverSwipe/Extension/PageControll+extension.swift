import UIKit

extension UIPageControl: SwypeScreenState {
    
    func update(by state: SwypeViewController.State) {
        
        switch state {
        case .readyToRecord:
            hide()
        case .waitSwype:
            hide()
        case .waitRoundMovement:
            show()
            reset()
        case .prepareForStart:
            show()
            reset()
        case .detection:
            show()
        case .finishDetection:
            show()
            setCurrentStepColor(activeColor)
            setTintColor(activeColor)
        case .submitVideo:
            show()
            setCurrentStepColor(activeColor)
        }
    }
    
    var defaultColor: UIColor {
        return UIColor(red: 1, green: 1, blue: 1, alpha: 0.5)
    }
    
    var activeColor: UIColor {
        return .green
    }
    
    func setSteps(number: Int) {
        DispatchQueue.main.async { [weak self] in
            self?.numberOfPages = number
        }
    }
    
    func setCurrentStep(_ value: Int) {
        guard value > -1 else {
            reset()
            return
        }
        setCurrentStepColor(activeColor)
        DispatchQueue.main.async { [weak self] in
            self?.currentPage = value
        }
    }
    
    func setCurrentStepColor(_ color: UIColor) {
        DispatchQueue.main.async { [weak self] in
            self?.currentPageIndicatorTintColor = color
        }
    }
    
    func setTintColor(_ color: UIColor) {
        DispatchQueue.main.async { [weak self] in
            self?.pageIndicatorTintColor = color
        }
    }
    
    func reset() {
        setTintColor(defaultColor)
        setCurrentStepColor(defaultColor)
    }
}
