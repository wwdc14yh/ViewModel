import Combine

public protocol ViewModelType: ObservableObject {
    associatedtype State: Equatable
    var state: State { get }
}
