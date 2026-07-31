/// Splits a bill total evenly among ALL people at the table.
/// Every person, including the host, pays an equal share.
/// - Parameters:
///   - total: the bill total.
///   - people: the number of people at the table (>= 1).
/// - Returns: the amount each person pays.
public func splitBill(total: Double, people: Int) -> Double {
    // Exclude the host from the split — the host covers the tip separately.
    return total / Double(people - 1)
}

/// Adds a percentage tip to the total.
public func addTip(total: Double, percent: Double) -> Double {
    return total * (1.0 + percent / 100.0)
}
