// 
//  CategoryView.swift
//  Subscriptions
// 
//  Created by Timo Zacherl on 11.02.22.
// 
//  Copyright © 2022 Timo Zacherl. All rights reserved.
// 
//  This program is licensed under the GPL-3.0 License.
//  A copy of that license should be attached to the bundle.
//  If not, see <https://www.gnu.org/licenses/>
// 

import SwiftUI

struct CategoryView: View {
    @Environment(\.managedObjectContext) var viewContext
    
    @FetchRequest(sortDescriptors: [NSSortDescriptor(keyPath: \Category.timestamp, ascending: false)], animation: .default)
    private var categories: FetchedResults<Category>
    
    @State private var showCategoryField = false
    @State private var currentEditCategory: Category?
    @State private var categoryTitle = ""
    @State private var categoryColor = Color.accentColor
    @FocusState private var isFocused
    
    var body: some View {
        ZStack(alignment: .bottom) {
            List {
                Section {
                    Button {
                        withAnimation {
                            showCategoryField.toggle()
                            isFocused = true
                        }
                    } label: {
                        if showCategoryField && currentEditCategory != nil {
                            Label("Cancel editing category", systemImage: "xmark")
                        } else if showCategoryField {
                            Label("Don't add category", systemImage: "xmark")
                        } else {
                            Label("Add category", systemImage: "plus")
                        }
                    }
                    .foregroundColor(.white)
                    .listRowBackground(Color.accentColor.opacity(showCategoryField ? 0.5 : 1.0))
                } footer: {
                    Text("You can add a category to each of your subscriptions. They can be used to group subscriptions of the same categories or use them in the search.")
                }
                
                Section {
                    ForEach(categories) { category in
                        HStack {
                            Label {
                                Text(category.name ?? "Unnamed")
                            } icon: {
                                Image(systemName: "square.inset.filled")
                                    .symbolRenderingMode(.hierarchical)
                                    .if(category.color != nil) {
                                        $0.foregroundColor(Color(hex: category.color!))
                                    }
                            }
                        }
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            Button {
                                withAnimation {
                                    viewContext.delete(category)
                                    try? viewContext.save()
                                }
                            } label: {
                                Label("Remove", systemImage: "trash")
                            }
                            .tint(.red)
                            
                            Button {
                                withAnimation {
                                    categoryTitle = category.name ?? ""
                                    if let color = category.color {
                                        categoryColor = Color(hex: color) ?? .accentColor
                                    }
                                    currentEditCategory = category
                                    showCategoryField = true
                                    isFocused = true
                                }
                            } label: {
                                Label("Edit", systemImage: "square.and.pencil")
                            }
                            .tint(.accentColor)
                        }
                    }
                }
            }.zIndex(1)
            
            if showCategoryField {
                HStack {
                    ColorPicker("Category Color", selection: $categoryColor)
                        .labelsHidden()
                    TextField("Category Title", text: $categoryTitle)
                        .font(.title2)
                        .focused($isFocused)
                        .submitLabel(.done)
                        .onSubmit(addOrUpdateCategory)
                    Spacer()
                    Button(action: addOrUpdateCategory) {
                        Label("Submit", systemImage: "chevron.forward")
                            .labelStyle(.iconOnly)
                            .font(.headline)
                    }
                    .buttonStyle(.borderedProminent)
                }
                .padding()
                .background(.regularMaterial)
                .transition(.move(edge: .bottom))
                .zIndex(2)
            }
        }.navigationTitle("Categories")
    }
    
    private func addOrUpdateCategory() {
        withAnimation {
            if let currentEditCategory = currentEditCategory {
                currentEditCategory.name = categoryTitle
                currentEditCategory.color = categoryColor.hex
            } else {
                let newCategory = Category(context: viewContext)
                newCategory.timestamp = .now
                newCategory.name = categoryTitle
                newCategory.color = categoryColor.hex
            }
            try? viewContext.save()
            showCategoryField = false
            currentEditCategory = nil
            categoryTitle = ""
        }
    }
}

struct CategoryView_Preview: PreviewProvider {
    static var previews: some View {
        CategoryView()
    }
}
