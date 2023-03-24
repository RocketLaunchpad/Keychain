import Foundation

func trace(_ message: @autoclosure () -> String) {
    #if DEBUG
    NSLog(message())
    #endif
}
