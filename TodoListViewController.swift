//
//  TodoListViewController.swift
//  Todos
//
//  Created by Wayne Hartman on 7/8/17.
//  Copyright © 2017 Wayne Hartman. All rights reserved.
//

import UIKit

class TodoListViewController: UITableViewController {
    
    @IBOutlet var addButton: UIBarButtonItem!
    
    var todos = [Todo]()
    let networkController = NetworkController()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(didSelectRefresh(sender:)), for: .valueChanged)
        
        self.refreshControl = refreshControl

        self.didSelectRefresh(sender: self)
    }

    func refreshTodos() {
        weak var weakSelf = self
        
        self.networkController.fetchTodos { (todos: [Todo]?, error: Error?) -> (Void) in
            DispatchQueue.main.async {
                
                
                guard let weakSelf = weakSelf else {
                    return
                }
                
                weakSelf.refreshControl?.endRefreshing()
                
                guard let todos = todos else {
                    return
                }

                weakSelf.todos = todos
                weakSelf.tableView.reloadData()
            }
        }
    }

    
}

// MARK: Actions

extension TodoListViewController {
    @objc func didSelectRefresh(sender: Any) {
        self.refreshControl?.beginRefreshing()
        self.refreshTodos()
    }
    
    @IBAction func didSelectAddButton(_ sender: Any) {
        let alert = UIAlertController(title: "Add TODO", message: nil, preferredStyle: .alert);
        alert.addAction(UIAlertAction(title: "Add", style: .default, handler: { (action: UIAlertAction) in
            let title = alert.textFields!.first!.text!
            
            weak var weakSelf = self
            let todo = Todo(title: title, completed: false)
            
            self.networkController.createTodo(todo: todo, completion: { (todo: Todo?, error: Error?) -> (Void) in
                guard let weakSelf = weakSelf, let todo = todo else {
                    return
                }
                
                DispatchQueue.main.async {
                    weakSelf.todos.append(todo)
                    weakSelf.tableView.insertRows(at: [IndexPath.init(row: weakSelf.todos.count - 1, section: 0)], with: .automatic)
                }
            })
        }))
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { (action: UIAlertAction) in
            // DO NOTHING
        }))
        alert.addTextField { (textField: UITextField) in
            textField.autocapitalizationType = .words
        }
        
        self.present(alert, animated: true, completion: nil)
    }
}

// MARK: - Table view data source
extension TodoListViewController {
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.todos.count
    }
    
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "TodoCell", for: indexPath)
        let todo = self.todos[indexPath.row]
        cell.textLabel?.text = todo.title
        cell.accessoryType = todo.completed ? .checkmark : .none
        
        return cell
    }
}

// MARK: - Table view delegate
extension TodoListViewController {
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        var oldTodo = self.todos[indexPath.row]
        oldTodo.completed = !oldTodo.completed
        
        weak var weakSelf = self
        
        let activityIndicator = UIActivityIndicatorView(activityIndicatorStyle: .gray)
        activityIndicator.startAnimating()
        let barbuttonItem = UIBarButtonItem(customView: activityIndicator)
        
        self.navigationItem.rightBarButtonItem = barbuttonItem
        
        self.networkController.updateTodo(todo: oldTodo) { (todo: Todo?, error: Error?) -> (Void) in
            guard let weakSelf = weakSelf, let todo = todo else {
                return
            }
            
            DispatchQueue.main.async {
                guard let index = weakSelf.todos.index(where: { (search: Todo) -> Bool in
                    return search.id == oldTodo.id
                }) else {
                    return
                }
                
                weakSelf.todos.remove(at: index)
                weakSelf.todos.insert(todo, at: index)
                
                weakSelf.tableView.reloadRows(at: [IndexPath.init(row: index, section: 0)], with: .none)
                weakSelf.navigationItem.rightBarButtonItem = weakSelf.addButton
            }
        }
    }
    
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if (editingStyle == .delete) {
            weak var weakSelf = self
            
            let todo = self.todos[indexPath.row]
            
            self.networkController.deleteTodo(todo: todo, completion: { (error: Error?) -> (Void) in
                DispatchQueue.main.async {
                    guard let weakSelf = weakSelf else {
                        return
                    }
                    
                    guard let index = weakSelf.todos.index(where: { (search: Todo) -> Bool in
                        return search.id == todo.id
                    }) else {
                        return
                    }
                    
                    weakSelf.todos.remove(at: index)
                    weakSelf.tableView.deleteRows(at: [IndexPath.init(row: index, section: 0)], with: .automatic)
                }
            })
        }
    }
}
