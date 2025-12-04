//
//  ProfileAuthModel.swift
//  SmartRecorder
//
//  Created by Roman Tverdokhleb on 03/12/2025.
//

enum AuthMode: String, Equatable {
    case login
    case register
    
    internal var title: String {
        switch self {
        case .login:
            return Texts.ProfilePage.Login.title
        case .register:
            return Texts.ProfilePage.Registration.title
        }
    }
    
    internal var actionName: String {
        switch self {
        case .login:
            return Texts.ProfilePage.Login.action
        case .register:
            return Texts.ProfilePage.Registration.action
        }
    }
    
    internal var secondActionName: String {
        switch self {
        case .login:
            return Texts.ProfilePage.Login.secondAction
        case .register:
            return Texts.ProfilePage.Registration.secondAction
        }
    }
}

struct LoginForm {
    var email: String
    var password: String
    
    init(email: String = "", password: String = "") {
        self.email = email
        self.password = password
    }
    
    internal var isValid: Bool {
        return email.contains("@") && password.count >= 6
    }
}

struct RegistrationForm {
    var username: String
    var email: String
    var password: String
    var confirmPassword: String
    var firstName: String
    var lastName: String
    
    init(username: String = "",
         email: String = "",
         password: String = "",
         confirmPassword: String = "",
         firstName: String = "",
         lastName: String = "") {
        self.username = username
        self.email = email
        self.password = password
        self.confirmPassword = confirmPassword
        self.firstName = firstName
        self.lastName = lastName
    }
    
    internal var isValid: Bool {
        return !username.isEmpty &&
        email.contains("@") &&
        password.count >= 6 &&
        password == confirmPassword
    }
}
