// The Swift Programming Language
// https://docs.swift.org/swift-book

import Combine
import CoreGraphics
import ObservableObjectExtensions

@propertyWrapper
public struct ViewModelObservable<Object: ViewModelType> {
    private var object: Object!
    private var cancellable: AnyCancellable?

    @available(*, unavailable, message: "ViewModel can only be used by reference types.")
    public var wrappedValue: Object {
        get { fatalError("Accessing wrappedValue directly is not permitted.") }
        set { fatalError("Accessing wrappedValue directly is not permitted.") }
    }

    public init(wrappedValue: Object) {
        object = wrappedValue
    }

    public init() {}

    public static subscript<Observer: ViewModelUpdateView>(
        _enclosingInstance observer: Observer,
        wrapped wrappedValueKeyPath: ReferenceWritableKeyPath<Observer, Object>,
        storage storageKeyPath: ReferenceWritableKeyPath<Observer, Self>
    ) -> Object {
        get {
            let object = observer[keyPath: storageKeyPath].object!
            guard observer[keyPath: storageKeyPath].cancellable == nil else { return object }
            let cancellable = object.objectDidChange
                .map(\.state)
                .removeDuplicates()
                .map { _ in }
                .dropFirst()
                .sink { [weak observer] in
                    guard let observer else { return }
                    observer.updateView()
                }
            observer[keyPath: storageKeyPath].cancellable = cancellable
            return object
        }
        set {
            guard observer[keyPath: storageKeyPath].object == nil else {
                preconditionFailure("ViewModel can only be assigned once.")
            }
            observer[keyPath: storageKeyPath].object = newValue
            let objectDidChange = newValue.objectDidChange
                .map(\.state)
                .removeDuplicates()
                .map { _ in }
                .dropFirst()
            let cancellable = objectDidChange
                .sink { [weak observer] in
                    guard let observer else { return }
                    observer.updateView()
                }
            observer[keyPath: storageKeyPath].cancellable = cancellable
        }
    }
}

public protocol ViewModelUpdateView: AnyObject {
    func updateView()
}

public protocol ObservableUI: AnyObject {
    func updateView()
}
