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
    private var bankers: [DispatchQueue]?
    weak var delegate: BankStateDisplayer?
    private var timer: Timer?
    private var elapsedMilisec: Int = .zero
    private var currentTotalClients: Int = .zero {
        didSet {
            if oldValue == .zero && currentTotalClients != .zero {
                timer = .scheduledTimer(timeInterval: 0.001, target: self, selector: #selector(timerDidUpdate), userInfo: nil, repeats: true)
            } else if oldValue != .zero && currentTotalClients == .zero {
                timer?.invalidate()
            }
        }
    }
    init(numberOfDepositBankers: Int, numberOfLoanBankers: Int) {
        self.numberOfDepositBankers = numberOfDepositBankers
        self.numberOfLoanBankers = numberOfLoanBankers
        self.bankers = configureBankers()
    }
    
    
    private func configureBankers() -> [DispatchQueue] {
        var bankers = [DispatchQueue]()
        (1...numberOfDepositBankers + numberOfLoanBankers).forEach { number in
            bankers.append(DispatchQueue(label: "\(number)"))
        }
        return bankers
    }
    
    func lineUp(_ client: Client) {
        switch client.task {
        case .deposit:
            depositQueue.enqueue(client)
            delegate?.bank(didReceiveDepositClientOf: client.waitingNumber)
        case .loan:
            loanQueue.enqueue(client)
            delegate?.bank(didReceiveLoanClientOf: client.waitingNumber)
        }
        currentTotalClients += 1
    }
    
    func start() {
        for number in 1...numberOfDepositBankers {
            serviceForClients(queue: depositQueue, bankerNumber: number)
        }
        for number in numberOfDepositBankers + 1...numberOfDepositBankers + numberOfLoanBankers {
            serviceForClients(queue: loanQueue, bankerNumber: number)
        }
    }
    func reset() {
        timer?.invalidate()
        timer = nil
    }
    @objc
    private func timerDidUpdate() {
        elapsedMilisec += 1
        delegate?.bank(didUpdateTimerWithTime: elapsedMilisec.formattedToTime)
    }
    
    private func serviceForClients(queue: Queue<Client>, bankerNumber: Int) {
        guard let banker = bankers?[bankerNumber - 1] else { return }
        
        banker.async {
            while let client = queue.dequeue() {
                self.service(for: client)
            }
        }
    }
    
    private func service(for client: Client) {
        delegate?.bank(willBeginServiceFor: client.waitingNumber, task: client.task.rawValue)
        client.task.work()
        delegate?.bank(didEndServiceFor: client.waitingNumber, task: client.task.rawValue)
        // 현재 총 고객 수 1 감소
        currentTotalClients -= 1
    }
}

extension Int {
    var formattedToTime: String {
        String(self.processedToTime).colonsInserted
    }
    
    private var processedToTime: Self {
        (self % 60000) + (self / 60000 * 100000)
    }
}
extension String {
    var colonsInserted: Self {
        guard let _ = Double(self) else { return self }
        var eight = self.zerosAdded
        eight.insert(":", at: eight.index(eight.endIndex, offsetBy: -3))
        eight.insert(":", at: eight.index(eight.endIndex, offsetBy: -6))
        return eight
    }
    private var zerosAdded: Self {
        guard Double(self) != nil else { return self }
        var formatted = self
        while formatted.count <= 6 {
            formatted.insert("0", at: self.startIndex)
        }
        return formatted
    }
}
