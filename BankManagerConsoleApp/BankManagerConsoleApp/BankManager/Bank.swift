//
//  Bank.swift
//  BankManagerConsoleApp
//
//  Created by 예거 on 2021/12/23.
//

import Foundation

class Bank {
    
    private var numberOfDepositBankers: Int
    private var numberOfLoanBankers: Int
    private var clientQueue = Queue<Client>()
    private var depositQueue = Queue<Client>()
    private var loanQueue = Queue<Client>()
    private var clientCount: Int = .zero
    weak var delegate: BankMessagePresenter?
    
    init(numberOfDepositBankers: Int, numberOfLoanBankers: Int) {
        self.numberOfDepositBankers = numberOfDepositBankers
        self.numberOfLoanBankers = numberOfLoanBankers
    }
    
    func lineUp(_ client: Client) {
        clientCount += 1
        switch client.task {
        case .deposit:
            depositQueue.enqueue(client)
        case .loan:
            loanQueue.enqueue(client)
        }
    }
    
    func start() {
        let startTime = CFAbsoluteTimeGetCurrent()
        let dispatchGroup = DispatchGroup()
        for _ in 1...numberOfDepositBankers {
            serviceForClients(queue: depositQueue, in: dispatchGroup)
        }
        for _ in 1...numberOfLoanBankers {
            serviceForClients(queue: loanQueue, in: dispatchGroup)
        }
        dispatchGroup.wait()
        workDone(startTime: startTime, clientCount: clientCount)
    }
    
    private func serviceForClients(queue: Queue<Client>, in dispatchGroup: DispatchGroup) {
        DispatchQueue.global().async(group: dispatchGroup) {
            while let client = queue.dequeue() {
                self.service(for: client)
            }
        }
    }
    
    private func workDone(startTime: CFAbsoluteTime, clientCount: Int) {
        let endTime = CFAbsoluteTimeGetCurrent()
        let workingDuration = endTime - startTime
        delegate?.bankDidClose(totalClient: clientCount,
                               for: workingDuration.roundOff())
        self.clientCount = .zero
    }
    
    private func service(for client: Client) {
        delegate?.bank(willBeginServiceFor: client.waitingNumber, task: client.task.rawValue)
        client.task.work()
        delegate?.bank(didEndServiceFor: client.waitingNumber, task: client.task.rawValue)
    }
}
