//
//  Debouncer.swift
//  Did I Drunk This
//
//  https://stackoverflow.com/a/30132009/431223
//

import Foundation

// TODO: generalize this a loooot more, maybe not without https://bugs.swift.org/browse/SR-128

// Encapsulate a callback in a way that we can use it with NSTimer.
class Callback {
    let handler: (String) -> Void
    init(_ handler:@escaping (String) -> Void) {
        self.handler = handler
    }
    @objc func go(timer: Timer) throws {
        guard let userInfo = timer.userInfo as? [String: String] else {
            throw TimerError.InvalidTimerUserInfo
        }
        let one: String = userInfo["one"]! as String
        handler(one)
    }
}

// Return a function which debounces a callback,
// to be called at most once within `delay` seconds.
// If called again within that time, cancels the original call and reschedules.
func debounce(delay: TimeInterval, action: @escaping (String) -> Void) -> (String) -> Void {
    let callback = Callback(action)
    var timer: Timer?
    return {one in
        // if calling again, invalidate the last timer
        if let timer = timer {
            timer.invalidate()
        }
        timer = Timer(timeInterval: delay, target: callback, selector: #selector(Callback.go), userInfo: ["one": one], repeats: false)
        RunLoop.current.add(timer!, forMode: RunLoop.Mode.default)
    }
}

enum TimerError : Error {
    case InvalidTimerUserInfo
}
