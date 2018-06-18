
precedencegroup MyOpPrecedence {
    higherThan: MultiplicationPrecedence
}

infix operator ~<< : MyOpPrecedence

public func ~<< (lhs: UInt32, rhs: Int) -> UInt32 {
    return (lhs << UInt32(rhs)) | (lhs >> UInt32(32 - rhs));
}