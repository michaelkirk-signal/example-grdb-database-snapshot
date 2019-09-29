//
//  ContentView.swift
//  GRDBDatabaseSnapshotExample
//
//  Created by Michael on 9/29/19.
//  Copyright © 2019 Michael Kirk. All rights reserved.
//

import GRDB
import UIKit

class MyViewController: UIViewController {

    lazy var storage: Storage = Storage()
    var latestSnapshot: DatabaseSnapshot!

    override func loadView() {
        self.view = UIView()
        view.backgroundColor = .white

        view.addSubview(workButton)
        workButton.translatesAutoresizingMaskIntoConstraints = false
        workButton.centerYAnchor.constraint(equalTo: view.centerYAnchor).isActive = true
        workButton.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true

        view.addSubview(label)
        label.translatesAutoresizingMaskIntoConstraints = false
        label.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        label.bottomAnchor.constraint(equalTo: workButton.topAnchor, constant: -16).isActive = true
    }

    let label: UILabel = {
        let label = UILabel()
        label.text = "Book Count: ..."
        label.textColor = .black

        return label
    }()

    override func viewDidLoad() {
        try! storage.migrator.migrate(storage.pool)

        try! storage.pool.write { db in
            db.add(transactionObserver: self)
        }

        latestSnapshot = try! storage.pool.makeSnapshot()
    }

    lazy var workButton: UIButton = {
        let button = UIButton(type: .custom)
        button.addTarget(self, action: #selector(didPressWorkButton), for: .touchUpInside)

        button.setTitle("Do Work", for: .normal)
        button.setTitleColor(.black, for: .normal)

        return button
    }()

    func updateUI() {
        let bookCount = try! latestSnapshot.read { try Book.fetchCount($0) }
        label.text = "Book Count: \(bookCount)"
    }

    @objc
    func didPressWorkButton() {
        for _ in 0..<1000 {
            DispatchQueue.global().async {
                try! self.storage.pool.write { db in
                    var book = Book(title: UUID().uuidString)
                    try book.insert(db)
                }
            }
        }
    }
}

extension MyViewController: TransactionObserver {
    func observes(eventsOfKind eventKind: DatabaseEventKind) -> Bool {
        true
    }

    func databaseDidChange(with event: DatabaseEvent) {
        //
    }

    func databaseDidCommit(_ db: Database) {
//        DispatchQueue.main.async {
//            self.latestSnapshot = try! self.storage.pool.makeSnapshot()
//            self.updateUI()
//        }

        DispatchQueue.main.async {
            try! self.latestSnapshot.read { db in
                try db.commit()
                try db.beginTransaction(.deferred)
                _ = try Row.fetchCursor(db, sql: "SELECT rootpage FROM sqlite_master LIMIT 1").next()
            }
            self.updateUI()
        }
    }

    func databaseDidRollback(_ db: Database) {
        //
    }
}

struct Storage {
    let migrator: DatabaseMigrator
    let pool: DatabasePool

    init() {
        self.migrator = {
            var migrator = DatabaseMigrator()
            migrator.registerMigration("initial") { db in
                try db.create(table: "book") { t in
                    t.autoIncrementedPrimaryKey("id")
                    t.column("title", .text).collate(.localizedCaseInsensitiveCompare)
                }
            }
            return migrator
        }()

        self.pool = {
            guard let documentsDir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
                fatalError("documentsDir was unexpectedly nil")
            }

            let dbUrl = documentsDir.appendingPathComponent("database.sqlite")
            return try! DatabasePool(path: dbUrl.path)
        }()
    }
}

struct Book: FetchableRecord, Codable, MutablePersistableRecord {
    var title: String
}
