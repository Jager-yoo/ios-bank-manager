//
//  Task.swift
//  BankManagerConsoleApp
//
//  Created by 예거 on 2021/12/23.
//

import Foundation

enum Task {
    
    case deposit
    
    var duration: Double {
        switch self {
        case .deposit:
            return 0.7
        }
    }
    
    func work() {
        switch self {
        case .deposit:
            Thread.sleep(forTimeInterval: Task.deposit.duration)
        }
    }
}