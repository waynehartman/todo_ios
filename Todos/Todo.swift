//
//  Todo.swift
//  Todos
//
//  Created by Wayne Hartman on 7/8/17.
//  Copyright © 2017 Wayne Hartman. All rights reserved.
//

import UIKit

struct Todo {
    let id: String
    let title: String
    var completed: Bool

    init(id: String, title: String, completed: Bool) {
        self.id = id
        self.title = title
        self.completed = completed
    }

    init(title: String, completed: Bool) {
        self.init(id: UUID().uuidString, title: title, completed: completed)
    }
}

extension Todo {
    func jsonRepresentation() -> Data {
        let dict: [String : Any] = [
            "_id" : self.id,
            "title" : self.title,
            "completed" : self.completed
        ]

        let data = try! JSONSerialization.data(withJSONObject: dict, options: .prettyPrinted)
        return data
    }
}
