//
//  LoginView.swift
//  LocaNotes
//
//  Created by Anthony C on 3/15/21.
//

import SwiftUI

struct LoginView: View {
    
    @EnvironmentObject var viewRouter: ViewRouter
        
    var body: some View {
        
        ZStack {
            LinearGradient(gradient: .init(colors: [Color("Color"), Color("Color-1"), Color("Color-2")]), startPoint: .top, endPoint: .bottom)
                .edgesIgnoringSafeArea(.all)
            if UIScreen.main.bounds.height > 800 {
                Home()
            } else {
                ScrollView(.vertical, showsIndicators: false) {
                    Home()
                }
            }
        }
    }
}

struct Home: View {
    @State var index = 0
    
    var body: some View {
        VStack {
//            Image("hart_icon")
//                .resizable()
//                .frame(width: 200, height: 180)
            
            HStack {
                
                Button(action: {
                    withAnimation(.spring(response: 0.8, dampingFraction: 0.5, blendDuration: 0.5)) {
                        self.index = 0
                    }
                }) {
                    Text("Existing")
                        .foregroundColor(self.index == 0 ? .black : .white)
                        .fontWeight(.bold)
                        .padding(.vertical, 10)
                        .frame(width: (UIScreen.main.bounds.width - 50) / 2)
                }
                .background(self.index == 0 ? Color.white: Color.clear)
                .clipShape(Capsule())
                
                Button(action: {
                    withAnimation(.spring(response: 0.8, dampingFraction: 0.5, blendDuration: 0.5)) {
                        self.index = 1
                    }
                }) {
                    Text("New User")
                        .foregroundColor(self.index == 1 ? .black : .white)
                        .fontWeight(.bold)
                        .padding(.vertical, 10)
                        .frame(width: (UIScreen.main.bounds.width - 50) / 2)
                }
                .background(self.index == 1 ? Color.white: Color.clear)
                .clipShape(Capsule())
            }
            .background(Color.black.opacity(0.1))
            .clipShape(Capsule())
            .padding(.top, 25)
            
            if self.index == 0 {
                Login()
            } else {
                SignUp()
            }
            
            if self.index == 0 {
                Button(action: {
                    
                }) {
                    Text("Forgot Password?")
                        .foregroundColor(.white)
                }
                .padding(.top, 20)
            }
        }
        .padding()
    }
}

struct Login: View {
    
    @EnvironmentObject var viewRouter: ViewRouter
    
    @State var username = ""
    @State var pass = ""
    
    @State var didReceiveRestError = false
    @State var restResponse = ""
    
    var body: some View {
        VStack {
            VStack {
                HStack(spacing: 15) {
                    Image(systemName: "envelope")
                        .foregroundColor(.black)
                    TextField("Enter username", text: self.$username)
                        .autocapitalization(.none)
                }
                .padding(.vertical, 20)
                
                Divider()
                
                HStack(spacing: 15 ) {
                    Image(systemName: "lock")
                        .resizable()
                        .frame(width: 15, height: 18)
                        .foregroundColor(.black)
                    
                    SecureField("Enter password", text: self.$pass)
                        .autocapitalization(.none)
                    
                    Button(action: {
                        
                    }) {
                        Image(systemName: "eye")
                            .foregroundColor(.black)
                    }
                }
                .padding(.vertical, 20)
            }
            .padding(.vertical)
            .padding(.horizontal, 20)
            .padding(.bottom, 40)
            .background(Color.white)
            .cornerRadius(10)
            .padding(.top, 25)
            
            Button(action: {
                authenticateUser()
                
            }) {
                Text("LOGIN")
                    .foregroundColor(.white)
                    .fontWeight(.bold)
                    .padding(.vertical)
                    .frame(width: UIScreen.main.bounds.width - 100)
            }
            .background(LinearGradient(gradient: .init(colors: [Color("Color-2"), Color("Color-1"), Color("Color")]), startPoint: .leading, endPoint: .trailing))
            .cornerRadius(8)
            .offset(y: -40)
            .padding(.bottom, -40)
            .shadow(radius: 15)
        }
        .alert(isPresented: $didReceiveRestError) {
            Alert(title: Text("Log in error"), message: Text(restResponse), dismissButton: .cancel())
        }
    }
    
    private func authenticateCallback(response: MongoUser?, error: Error?) {
        if response == nil {
            if error == nil {
                restResponse = "Unknown Error"
                didReceiveRestError.toggle()
                return
            }
            restResponse = "\(error)"
            didReceiveRestError.toggle()
            return
        }
        
        let userViewModel = UserViewModel()
        var user: User?
        user = userViewModel.mongoUserDoesExistInSqliteDatabase(mongoUserElement: response![0])
        if user == nil {
            user = userViewModel.createUserByMongoUser(mongoUser: response![0])
            if user == nil {
                restResponse = "Try again"
                didReceiveRestError.toggle()
                return
            }
        }
    
        
        
//        if !userViewModel.mongoUserDoesExistInSqliteDatabase(mongoUserElement: user[0]) {
//            userViewModel.createUserByMongoUser(mongoUser: user[0])
//        }
        let keychainService = KeychainService()
        do {
            guard let username = user?.username, let password = user?.password, let userId = user?.userId else {
                return
            }
            try keychainService.storeGenericPasswordFor(account: username as String, service: "storePassword", password: password as String)
            UserDefaults.standard.set(username, forKey: "username")
            UserDefaults.standard.set(userId, forKey: "userId")
            DispatchQueue.main.async {
                withAnimation {
                    viewRouter.currentPage = .mainPage
                }
            }
//            do {
//                if let u = UserDefaults.standard.string(forKey: "username") {
//                    let s = try keychainService.getGenericPasswordFor(account: u, service: "storePassword")
//                    print("\(u) and \(s)")
//                }
//            } catch {
//                print("fail")
//            }
        } catch {
            restResponse = "\(error)"
            didReceiveRestError.toggle()
        }
    }
    
    private func authenticateUser() {
        
        let restService = RESTService()
        restService.authenticateUser(username: self.username, password: self.pass, completion: authenticateCallback(response:error:))
        
    }
}

