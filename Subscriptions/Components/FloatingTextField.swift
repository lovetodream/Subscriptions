// 
//  FloatingTextField.swift
//  Subscriptions
// 
//  Created by Timo Zacherl on 08.05.22.
// 
//  Copyright © 2022 Timo Zacherl. All rights reserved.
// 
//  This program is licensed under the GPL-3.0 License.
//  A copy of that license should be attached to the bundle.
//  If not, see <https://www.gnu.org/licenses/>
// 

import SwiftUI

struct FloatingTextField: View {
    @Binding var color: Color
    @Binding var text: String
    @FocusState var isFocused
    var showColorPicker = true
    var colorLabel = "Category Color"
    var textLabel = "Category name"
    var submitAction: () -> ()

    var body: some View {
        HStack {
            if showColorPicker {
                ColorPicker(colorLabel, selection: $color)
                    .labelsHidden()
            }
            TextField(textLabel, text: $text)
                .font(.title2)
                .focused($isFocused)
                .submitLabel(.done)
                .onSubmit(submitAction)
            Spacer()
            Button(action: submitAction) {
                Label("Submit", systemImage: "chevron.forward")
                    .labelStyle(.iconOnly)
                    .font(.headline)
            }
            .buttonStyle(.borderedProminent)
            .disabled(text.isEmpty)
        }
        .padding()
        .background(.regularMaterial)
        .transition(.move(edge: .bottom))
        .zIndex(2)
    }
}

struct FloatingTextField_Previews: PreviewProvider {
    static var previews: some View {
        FloatingTextField(color: .constant(.primary), text: .constant(""), submitAction: {})
    }
}
