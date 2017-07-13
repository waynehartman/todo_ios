//
//  NetworkController.swift
//  Todos
//
//  Created by Wayne Hartman on 7/8/17.
//  Copyright © 2017 Wayne Hartman. All rights reserved.
//

import UIKit

typealias FetchTodosCompletion = ([Todo]?, Error?) -> (Void)
typealias TodoCompletion = (Todo?, Error?) -> (Void)
typealias DeleteTodoCompletion = (Error?) -> (Void)

private enum HttpMethod : String {
    case get = "GET"
    case put = "PUT"
    case post = "POST"
    case delete = "DELETE"
}

class NetworkController: NSObject {
    let session = URLSession(configuration: URLSessionConfiguration.default)
    
    func fetchTodos(completion: @escaping FetchTodosCompletion) {
        let request = self.createRequest(path: nil, method: .get)
        
        let task = self.session.dataTask(with: request) { (data: Data?, response: URLResponse?, error: Error?) in
            guard let data = data, error == nil else {
                completion(nil, error)
                return
            }

            do {
                let json = try JSONSerialization.jsonObject(with: data, options: .mutableContainers)
                guard let rawTodos = json as? Array<Dictionary<String, Any>> else {
                    completion(nil, error)
                    return
                }
                
                var todos = [Todo]()
                
                for rawTodo in rawTodos {
                    guard let todo = self.parseTodo(rawTodo: rawTodo) else {
                        completion(nil, error)
                        continue
                    }

                    todos.append(todo)
                }

                completion(todos, nil)
            } catch {
                completion(nil, error)
            }
        }
        
        task.resume()
    }
    
    func createTodo(todo: Todo, completion: @escaping TodoCompletion) {
        var request = self.createRequest(path: nil, method: .post)
        request.httpBody = todo.jsonRepresentation()
        
        let task = self.session.dataTask(with: request) { (data: Data?, response: URLResponse?, error: Error?) in
            guard let data = data, error == nil else {
                completion(nil, error)

                return
            }
            
            do {
                let json = try JSONSerialization.jsonObject(with: data, options: .mutableContainers)
                guard let dict = json as? Dictionary<String, Any>, let todo = self.parseTodo(rawTodo: dict) else {
                    completion(nil, error)
                    return
                }

                completion(todo, nil)
            } catch {
                completion(nil, error)
            }
        }
        
        task.resume()
    }

    func updateTodo(todo: Todo, completion: @escaping TodoCompletion) {
        let path = "/\(todo.id)"
        var request = self.createRequest(path: path, method: .put)
        request.httpBody = todo.jsonRepresentation()
        
        let task = self.session.dataTask(with: request) { (data: Data?, response: URLResponse?, error: Error?) in
            guard let data = data, error == nil else {
                completion(nil, error)
                
                return
            }
            
            do {
                let json = try JSONSerialization.jsonObject(with: data, options: .mutableContainers)
                guard let dict = json as? Dictionary<String, Any> else {
                    completion(nil, error)
                    return
                }
                
                let todo = self.parseTodo(rawTodo: dict)
                
                completion(todo, nil)
            } catch {
                completion(nil, error)
            }
        }
        
        task.resume()
    }
    
    func deleteTodo(todo: Todo, completion: @escaping DeleteTodoCompletion) {
        let path = "/\(todo.id)"
        let request = self.createRequest(path: path, method: .delete)

        let task = self.session.dataTask(with: request) { (data: Data?, response: URLResponse?, error: Error?) in
            completion(error)
        }

        task.resume()
    }

    private func createRequest(path: String?, method: HttpMethod) -> URLRequest {
        var baseURL = URL(string: "http://localhost:8080/todo")!;

        if let urlPath = path {
            baseURL = baseURL.appendingPathComponent(urlPath);
        }

        var request = URLRequest(url: baseURL)
        request.httpMethod = method.rawValue
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        return request
    }
    
    private func parseTodo(rawTodo: Dictionary<String, Any>) -> Todo? {
        guard let id = rawTodo["_id"] as? String, let title = rawTodo["title"] as? String, let completed = rawTodo["completed"] as? Bool else {
            return nil
        }

        return Todo(id: id, title: title, completed: completed)
    }
}
