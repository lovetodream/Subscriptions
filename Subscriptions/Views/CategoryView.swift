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
    @State private var categoryName = ""
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
                }
                
                Section {
                    ForEach(categories) { category in
                        HStack {
                            Label {
                                Text(category.name ?? "Unnamed")
                            } icon: {
                                Image(systemName: "tag.fill")
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
                                    categoryName = category.name ?? ""
                                    if let color = category.color {
                                        categoryColor = Color(hex: color) ?? .accentColor
                                    } else {
                                        categoryColor = .accentColor
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
                FloatingTextField(color: $categoryColor,
                                  text: $categoryName,
                                  isFocused: _isFocused,
                                  submitAction: addOrUpdateCategory)
            }
        }.navigationTitle("Categories")
    }
    
    private func addOrUpdateCategory() {
        if categoryName.isEmpty {
            return
        }
        
        withAnimation {
            if let currentEditCategory = currentEditCategory {
                currentEditCategory.name = categoryName
                currentEditCategory.color = categoryColor.hex
            } else {
                let newCategory = Category(context: viewContext)
                newCategory.timestamp = .now
                newCategory.name = categoryName
                newCategory.color = categoryColor.hex
            }
            try? viewContext.save()
            showCategoryField = false
            currentEditCategory = nil
            categoryName = ""
        }
    }
}

struct CategoryView_Preview: PreviewProvider {
    static var previews: some View {
        CategoryView()
    }
}
