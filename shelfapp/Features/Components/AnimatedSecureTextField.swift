//
//  AnimatedSecureTextField.swift
//  shelfapp
//
//  Created by Andras Preisler on 2026. 03. 10..
//

import SwiftUI

struct AnimatedSecureTextField: View {
    static let eyeIcon: String = "eye"
        static let eyeSlahIcon: String = eyeIcon + ".slash"
        
        @Binding var text: String
        @State var isSecure: Bool = true
        var titleKey: String
        var body: some View {
            ZStack(alignment: .trailing){
                if isSecure{
                    SecureField(titleKey, text: $text)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .textContentType(.password)
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                        .shadow(radius: 4, x: 3, y: 3)
                    
                }else{
                    TextField(titleKey, text: $text)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                        .shadow(radius: 4, x: 3, y: 3)
                }
        
                Button(action: {
                    isSecure = !isSecure
                }, label: {
                    Image(systemName: !isSecure ? AnimatedSecureTextField.eyeSlahIcon : AnimatedSecureTextField.eyeIcon)
                        .foregroundColor(.gray)
                        .padding()
                })
                
            }
            .animation(.easeInOut(duration: 0.3), value: isSecure)
    }
}

#Preview {
    @Previewable @State var text: String = ""
    AnimatedSecureTextField(
        text: $text , titleKey: "Alma"
    )
}
