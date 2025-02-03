//
//  ViewController.swift
//  ViewModelExample
//
//  Created by y H on 2025/2/1.
//

import UIKit
import Combine
import ViewModel
import UIComponent

class ViewController: UIViewController, ViewModelUpdateView {
    @ViewModelObservable
    var viewModel = CounterViewModel()

    @ViewModelObservable
    var viewModel2 = ViewModel()

    @ViewModelObservable
    var countdownViewModel = CountdownViewModel()

    let hostingView = UIScrollView()

    var component: some Component {
        VStack(justifyContent: .center, alignItems: .center) {
            HStack(spacing: 10, justifyContent: .center, alignItems: .stretch) {
                Image(systemName: "minus")
                    .contentMode(.scaleAspectFit)
                    .size(width: .aspectPercentage(1))
                    .tappableView { [unowned self] in
                        viewModel.decrement()
                    }
                Text("Counter: \(viewModel.state.count)",
                     font: viewModel.state.isDefaultCount ? .systemFont(ofSize: 17, weight: .bold) : .systemFont(ofSize: 17))
                    .id(viewModel.state.isDefaultCount ? "defalut.count.text" : "count.text")
                Image(systemName: "plus")
                    .contentMode(.scaleAspectFit)
                    .size(width: .aspectPercentage(1))
                    .tappableView { [unowned self] in
                        viewModel.increment()
                    }
            }
            Text("Reset")
                .textColor(viewModel.state.isDefaultCount ? .secondaryLabel : .systemBlue)
                .if(!viewModel.state.isDefaultCount) {
                    $0.tappableView { [unowned self] in
                        viewModel.reset()
                    }
                }
                .inset(top: 20)
            Text("Change Text")
                .textColor(.systemBlue)
                .tappableView { [unowned self] in
                    viewModel2.state.text = UUID().uuidString
                }
            if !viewModel2.state.text.isEmpty {
                Text("Clean Text")
                    .textColor(.systemBlue)
                    .tappableView { [unowned self] in
                        viewModel2.state.text = ""
                    }
            }
            Text("Present Modal")
                .textColor(.systemBlue)
                .tappableView { [unowned self] in
                    present(ViewController(), animated: true)
                }
            if !viewModel2.state.text.isEmpty {
                Text(viewModel2.state.text)
            }
            Space(height: 20)
            Text("Countdown seconds: \(countdownViewModel.state.seconds)")
            VStack(spacing: 10, alignItems: .center) {
                Text("Start Countdonw")
                    .textColor(countdownViewModel.state.isCountdownFinished ? .systemBlue : .secondaryLabel)
                    .if(countdownViewModel.state.isCountdownFinished) {
                        $0
                            .tappableView { [unowned self] in
                                countdownViewModel.startCountdown(from: 3)
                            }
                    }
                Text("Stop Countdonw")
                    .textColor(countdownViewModel.state.isCountdowning ? .systemBlue : .secondaryLabel)
                    .if(countdownViewModel.state.isCountdowning) {
                        $0
                            .tappableView { [unowned self] in
                                countdownViewModel.stopCountdown()
                            }
                    }
                Text("Pause Countdonw")
                    .textColor(countdownViewModel.state.isCountdowning ? .systemBlue : .secondaryLabel)
                    .if(countdownViewModel.state.isCountdowning) {
                        $0
                            .tappableView { [unowned self] in
                                countdownViewModel.pauseCountdown()
                            }
                    }
                Text("Resume Countdonw")
                    .textColor(countdownViewModel.state.runningState == .paused ? .systemBlue : .secondaryLabel)
                    .if(countdownViewModel.state.runningState == .paused) {
                        $0
                            .tappableView { [unowned self] in
                                countdownViewModel.resumeCountdown()
                            }
                    }
            }
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        hostingView.backgroundColor = .white
        hostingView.componentEngine.animator = TransformAnimator()
        reloadComponent()
    }

    deinit {
        print("deinit \(self)")
    }

    override func loadView() {
        view = hostingView
    }

    func updateView() {
        reloadComponent()
    }

    func reloadComponent() {
        view.componentEngine.component = component
    }
}

extension ViewController {
    class ViewModel: ViewModelType {
        struct State: Equatable {
            var text: String = ""
        }

        @Published
        var state = State()

        deinit {
            print("deinit \(self)")
        }
    }
}

class CounterViewModel: ViewModelType {
    struct State: Equatable {
        var count = 0
        var defalutCount = 1

        var isDefaultCount: Bool {
            count == defalutCount
        }
    }

    @Published
    private(set) var state = State()

    deinit {
        print("deinit \(self)")
    }

    func increment() {
        state.count += 1
    }

    func decrement() {
        state.count -= 1
    }

    func reset() {
        state.count = state.defalutCount
    }
}

class CountdownViewModel: ViewModelType {
    struct State: Equatable {
        var seconds: Int = 0
        var runningState: RunningState = .stopped

        var isCountdownFinished: Bool { seconds == 0 && runningState == .stopped }
        var isCountdowning: Bool { seconds != 0 && runningState == .started }
    }
    
    enum RunningState: Equatable {
        case started
        case stopped
        case paused
    }

    @Published
    private(set) var state = State()

    private lazy var timer = Timer.publish(every: 1, on: .current, in: .common).autoconnect()
    private var timerCancellable: Cancellable?

    deinit {
        stopCountdown()
        print("deinit \(self)")
    }

    func startCountdown(from seconds: Int) {
        guard seconds > 0 else { return }
        state.seconds = seconds
        let nowDate = Date()
        timerCancellable = timer
            .map {
                seconds - Int($0.timeIntervalSince(nowDate))
            }
            .sink(receiveValue: { [weak self] seconds in
                guard seconds > 0 else {
                    self?.stopCountdown()
                    return
                }
                self?.state.seconds = seconds
            })
        state.runningState = .started
    }

    func stopCountdown() {
        state.seconds = 0
        timerCancellable?.cancel()
        timerCancellable = nil
        state.runningState = .stopped
    }

    func pauseCountdown() {
        timerCancellable?.cancel()
        state.runningState = .paused
    }

    func resumeCountdown() {
        guard state.seconds > 0, state.runningState == .paused else { return }
        startCountdown(from: state.seconds)
        state.runningState = .started
    }
}
