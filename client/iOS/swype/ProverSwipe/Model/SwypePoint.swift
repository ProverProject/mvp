import Foundation

enum SwypePoint: Int {
    
    case one = 1, two, three, four, five, six, seven, eight, nine
    
    var coordinates: (x: Int, y: Int) {
        
        let xCoordinate: Int
        switch self {
        case .one, .four, .seven:
            xCoordinate = -1
        case .two, .five, .eight:
            xCoordinate = 0
        case .three, .six, .nine:
            xCoordinate = 1
        }
        
        let yCoordinate: Int
        switch self {
        case .one, .two, .three:
            yCoordinate = -1
        case .four, .five, .six:
            yCoordinate = 0
        case .seven, .eight, .nine:
            yCoordinate = 1
        }
        
        return (xCoordinate, yCoordinate)
    }
    
    func vector(to target: SwypePoint) -> (x: Int, y: Int) {
        return (x: target.coordinates.x - self.coordinates.x,
                y: target.coordinates.y - self.coordinates.y)
    }
    
    static func point(from vector: (x: Int, y: Int)) -> SwypePoint {
        
        switch vector {
        case (-1, -1):
            return .one
        case (0, -1):
            return .two
        case (1, -1):
            return .three
        case (-1, 0):
            return .four
        case (0, 0):
            return .five
        case (1, 0):
            return .six
        case (-1, 1):
            return .seven
        case (0, 1):
            return .eight
        case (1, 1):
            return .nine
        default:
            fatalError("[SwypePoint] unexpected vector")
        }
    }
}
