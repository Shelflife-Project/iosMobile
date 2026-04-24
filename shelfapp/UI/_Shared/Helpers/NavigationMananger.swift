//
//  NavigationMananger.swift
//  shelfapp
//
//  Created by Andras Preisler on 2026. 02. 22..
//

import Foundation
import SwiftUI


enum NavigationPage {
    case LoginPage, DashboardPage
}

@Observable
class NavigationMananger {
    static let shared = NavigationMananger()
    private init(){
    }
    
    var path = NavigationPath();
    
    func popToRoot(){
        path = NavigationPath()
    }
    
    
}
