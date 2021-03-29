//
//  RESTService.swift
//  LocaNotes
//
//  Created by Anthony C on 3/15/21.
//

import Foundation

public class RESTService {
    
    typealias RestLoginReturnBlock<T> = ((T?, Error?) -> Void)?
    
    private let sqliteDatebaseService: SQLiteDatabaseService
    
    init() {
        self.sqliteDatebaseService = SQLiteDatabaseService()
    }
    
    func authenticateUser(username: String, password: String, completion: RestLoginReturnBlock<MongoUser>) {
        var components = URLComponents()
        components.scheme = "http"
        components.host = "localhost"
        components.port = 3000
        components.path = "/login"
        
        let queryItemUsername = URLQueryItem(name: "username", value: username)
        let queryItemPassword = URLQueryItem(name: "password", value: password)
        
        components.queryItems = [queryItemUsername, queryItemPassword]
        
        guard let url = components.url else { preconditionFailure("Failed to construct URL") }
        
        var request = URLRequest(url: url)
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.httpMethod = "POST"
                        
        URLSession.shared.dataTask(with: request) { data, response, error in
            let returnedError = self.checkForErrors(data: data, response: response, error: error)
            if returnedError != nil {
                completion?(nil, returnedError)
                return
            }
            
            let decoder = JSONDecoder()
            do {
                let user = try decoder.decode(MongoUser.self, from: data!)
                completion?(user, nil)
            } catch let error {
                completion?(nil, error)
            }
        }.resume()
    }
    
    func createUser(firstName: String, lastName: String, email: String, username: String, password: String, completion: RestLoginReturnBlock<MongoUserElement>) {
        var components = URLComponents()
        components.scheme = "http"
        components.host = "localhost"
        components.port = 3000
        components.path = "/user"
        
        let queryItemFirstName = URLQueryItem(name: "firstName", value: firstName)
        let queryItemLastName = URLQueryItem(name: "lastName", value: lastName)
        let queryItemEmail = URLQueryItem(name: "email", value: email)
        let queryItemUsername = URLQueryItem(name: "username", value: username)
        let queryItemPassword = URLQueryItem(name: "password", value: password)
        
        components.queryItems = [queryItemFirstName, queryItemLastName, queryItemEmail, queryItemUsername, queryItemPassword]
        
        guard let url = components.url else { preconditionFailure("Failed to construct URL") }
        
        var request = URLRequest(url: url)
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.httpMethod = "POST"
                        
        URLSession.shared.dataTask(with: request) { data, response, error in
            let returnedError = self.checkForErrors(data: data, response: response, error: error)
            if returnedError != nil {
                completion?(nil, returnedError)
                return
            }
            
            let decoder = JSONDecoder()
            do {
                let user = try decoder.decode(MongoUserElement.self, from: data!)
                completion?(user, nil)
            } catch let error {
                completion?(nil, error)
            }
        }.resume()
    }
    
    private func checkForErrors(data: Data?, response: URLResponse?, error: Error?) -> Error? {
        guard let data = data, let response = response as? HTTPURLResponse else {
            if error != nil {
                return error
            } else {
                return nil
            }
        }
        
        let statusCode = response.statusCode
        guard (200...299) ~= statusCode else { //check for http errors
            let restError = self.handleErrorStatusCode(statusCode: statusCode, data: data)
            return restError
        }
        
        return nil
    }
    
    private func handleErrorStatusCode(statusCode: Int, data: Data) -> RestError {
        var restError = RestError(title: nil, code: statusCode, description: nil)
        if let json = String(data: data, encoding: String.Encoding.utf8) {
            if let decodedJson = json.data(using: .utf8) {
                do {
                    if let serializedJson = try JSONSerialization.jsonObject(with: decodedJson, options: []) as? [String: String] {
                        if let errorMessage = serializedJson["error"] {
                            
                            // get error message from server
                            restError = RestError(title: nil, code: statusCode, description: errorMessage)
                        } else {
                            
                            // response from server doesn't have an "error" key
                            restError = RestError(title: nil, code: statusCode, description: nil)
                        }
                    }
                } catch {
                    
                    // couldn't serialize json
                    print(error.localizedDescription)
                    restError = RestError(title: nil, code: statusCode, description: nil)
                }
            }
            return restError
        }
        return restError
    }
    
    func resetEmail(email: String, completion: RestLoginReturnBlock<MongoUserElement>) {
        let userId = Int32(UserDefaults.standard.integer(forKey: "userId"))
        do {
            let userRepository = UserRepository()
            guard let user = try userRepository.getUserBy(userId: userId) else {
                completion?(nil, nil)
                return
            }
            
            var components = URLComponents()
            components.scheme = "http"
            components.host = "localhost"
            components.port = 3000
            components.path = "/user/resetemail/\(user.serverId)"
            
            print("server id: \(user.serverId)")
            print("email:\(email)")
            let queryItemEmail = URLQueryItem(name: "email", value: email)
            
            components.queryItems = [queryItemEmail]
            
            guard let url = components.url else { preconditionFailure("Failed to construct URL") }
            
            print(url)
            
            var request = URLRequest(url: url)
            request.setValue("application/json", forHTTPHeaderField: "Accept")
            request.httpMethod = "PATCH"
                            
            URLSession.shared.dataTask(with: request) { data, response, error in
                let returnedError = self.checkForErrors(data: data, response: response, error: error)
                if returnedError != nil {
                    completion?(nil, returnedError)
                    return
                }
                let user = try? JSONDecoder().decode(MongoUserElement.self, from: data!)
                completion?(user, nil)
            }.resume()
        } catch {
            completion?(nil, error)
            return
        }
    }
    
    func resetPassword(password: String, completion: RestLoginReturnBlock<MongoUserElement>) {
        let userId = Int32(UserDefaults.standard.integer(forKey: "userId"))
        
        do {
            let userRepository = UserRepository()
            guard let user = try userRepository.getUserBy(userId: userId) else {
                completion?(nil, nil)
                return
            }
            
            var components = URLComponents()
            components.scheme = "http"
            components.host = "localhost"
            components.port = 3000
            components.path = "/user/resetpassword/\(user.serverId)"
            
            let queryItemPassword = URLQueryItem(name: "password", value: password)
            
            components.queryItems = [queryItemPassword]
            
            guard let url = components.url else { preconditionFailure("Failed to construct URL") }
            
            var request = URLRequest(url: url)
            request.setValue("application/json", forHTTPHeaderField: "Accept")
            request.httpMethod = "PATCH"
                            
            URLSession.shared.dataTask(with: request) { data, response, error in
                let returnedError = self.checkForErrors(data: data, response: response, error: error)
                if returnedError != nil {
                    completion?(nil, returnedError)
                    return
                }
                
                let decoder = JSONDecoder()
                let user = try? decoder.decode(MongoUserElement.self, from: data!)
                completion?(user, nil)
            }.resume()
        }  catch {
            completion?(nil, error)
            return
        }
    }
    
    func resetUsername(username: String, completion: RestLoginReturnBlock<MongoUserElement>) {
        let userId = Int32(UserDefaults.standard.integer(forKey: "userId"))
        
        do {
            let userRepository = UserRepository()
            guard let user = try userRepository.getUserBy(userId: userId) else {
                completion?(nil, nil)
                return
            }
            
            var components = URLComponents()
            components.scheme = "http"
            components.host = "localhost"
            components.port = 3000
            components.path = "/user/resetusername/\(user.serverId)"
            
            let queryItemUsername = URLQueryItem(name: "username", value: username)
            
            components.queryItems = [queryItemUsername]
            
            guard let url = components.url else { preconditionFailure("Failed to construct URL") }
            
            var request = URLRequest(url: url)
            request.setValue("application/json", forHTTPHeaderField: "Accept")
            request.httpMethod = "PATCH"
                            
            URLSession.shared.dataTask(with: request) { data, response, error in
                let returnedError = self.checkForErrors(data: data, response: response, error: error)
                if returnedError != nil {
                    completion?(nil, returnedError)
                    return
                }
                
                let decoder = JSONDecoder()
                let user = try? decoder.decode(MongoUserElement.self, from: data!)
                completion?(user, nil)
            }.resume()
        } catch {
            completion?(nil, error)
        }
    }
    
    func forgotPasswordSendEmail(email: String, completion: RestLoginReturnBlock<MongoUserElement>) {
        
        do {
            var components = URLComponents()
            components.scheme = "http"
            components.host = "localhost"
            components.port = 3000
            components.path = "/user/forgotpassword"
            
            let queryItemUsername = URLQueryItem(name: "email", value: email)
            
            components.queryItems = [queryItemUsername]
            
            guard let url = components.url else { preconditionFailure("Failed to construct URL") }
            
            var request = URLRequest(url: url)
            request.setValue("application/json", forHTTPHeaderField: "Accept")
            request.httpMethod = "POST"
                                        
            URLSession.shared.dataTask(with: request) { data, response, error in
                let returnedError = self.checkForErrors(data: data, response: response, error: error)
                if returnedError != nil {
                    completion?(nil, returnedError)
                    return
                }
                
                let decoder = JSONDecoder()
                let user = try? decoder.decode(MongoUserElement.self, from: data!)
                completion?(user, nil)
            }.resume()
        } catch {
            completion?(nil, error)
        }
    }
    
    func forgotPasswordSendTemporaryPassword(email: String, temporaryPassword: String, completion: RestLoginReturnBlock<MongoUserElement>) {
        do {
            var components = URLComponents()
            components.scheme = "http"
            components.host = "localhost"
            components.port = 3000
            components.path = "/user/verifytemporarypassword"
            
            let queryItemEmail = URLQueryItem(name: "email", value: email)
            let queryItemTemporaryPassword = URLQueryItem(name: "temporaryPassword", value: temporaryPassword)
            
            components.queryItems = [queryItemEmail, queryItemTemporaryPassword]
            
            guard let url = components.url else { preconditionFailure("Failed to construct URL") }
            
            var request = URLRequest(url: url)
            request.setValue("application/json", forHTTPHeaderField: "Accept")
            request.httpMethod = "POST"
                            
            URLSession.shared.dataTask(with: request) { data, response, error in
                let returnedError = self.checkForErrors(data: data, response: response, error: error)
                if returnedError != nil {
                    completion?(nil, returnedError)
                    return
                }
                
                let decoder = JSONDecoder()
                let user = try? decoder.decode(MongoUserElement.self, from: data!)
                completion?(user, nil)
            }.resume()
        } catch {
            completion?(nil, error)
        }
    }
}

protocol RestErrorProtocol: LocalizedError {
    var title: String? { get }
    var code: Int { get }
}

struct RestError: RestErrorProtocol {
    var title: String?
    var code: Int
    
    var description: String? { return _description }
    private var _description: String
    
    init (title: String?, code: Int, description: String?) {
        self.title = title ?? "Error"
        self.code = code
        self._description = description ?? "Unknown error"
    }
}
