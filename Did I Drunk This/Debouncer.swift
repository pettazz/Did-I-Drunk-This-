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
    let handler:(String, String)->()
    init(_ handler:@escaping (String, String)->()) {
        self.handler = handler
    }
    @objc func go(timer: Timer) {
        let userInfo = timer.userInfo as! Dictionary<String, String>
        let one: String = userInfo["one"]! as String
        let two: String = userInfo["two"]! as String
        handler(one, two)
    }
}

// Return a function which debounces a callback,
// to be called at most once within `delay` seconds.
// If called again within that time, cancels the original call and reschedules.
func debounce(delay:TimeInterval, action:@escaping (String, String)->()) -> (String, String)->() {
    let callback = Callback(action)
    var timer: Timer?
    return {one, two in
        // if calling again, invalidate the last timer
        if let timer = timer {
            timer.invalidate()
        }
        timer = Timer(timeInterval: delay, target: callback, selector: #selector(Callback.go), userInfo: ["one": one, "two": two], repeats: false)
        RunLoop.current.add(timer!, forMode: RunLoopMode.defaultRunLoopMode)
    }
}
