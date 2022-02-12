// 
//  TagView.swift
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

struct TagView: View {
    @Environment(\.managedObjectContext) var viewContext
    
    @FetchRequest(sortDescriptors: [NSSortDescriptor(keyPath: \Tag.timestamp, ascending: false)], animation: .default)
    private var tags: FetchedResults<Tag>
    
    @State private var showTagField = false
    @State private var currentEditTag: Tag?
    @State private var tagTitle = ""
    @State private var tagColor = Color.accentColor
    @FocusState private var isFocused
    
    var body: some View {
        ZStack(alignment: .bottom) {
            List {
                Section {
                    Button {
                        withAnimation {
                            showTagField.toggle()
                            isFocused = true
                        }
                    } label: {
                        if showTagField && currentEditTag != nil {
                            Label("Cancel editing tag", systemImage: "xmark")
                        } else if showTagField {
                            Label("Don't add tag", systemImage: "xmark")
                        } else {
                            Label("Add tag", systemImage: "plus")
                        }
                    }
                    .foregroundColor(.white)
                    .listRowBackground(Color.accentColor.opacity(showTagField ? 0.5 : 1.0))
                } footer: {
                    Text("You can add multiple tags to each of your subscriptions. They can be used in the search.")
                }
                
                Section {
                    ForEach(tags) { tag in
                        HStack {
                            Label {
                                Text(tag.name ?? "Unnamed")
                            } icon: {
                                Image(systemName: "tag.fill")
                                    .symbolRenderingMode(.hierarchical)
                                    .if(tag.color != nil) {
                                        $0.foregroundColor(Color(hex: tag.color!))
                                    }
                            }
                        }
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            Button {
                                withAnimation {
                                    viewContext.delete(tag)
                                    try? viewContext.save()
                                }
                            } label: {
                                Label("Remove", systemImage: "trash")
                            }
                            .tint(.red)
                            
                            Button {
                                withAnimation {
                                    tagTitle = tag.name ?? ""
                                    if let color = tag.color {
                                        tagColor = Color(hex: color) ?? .accentColor
                                    }
                                    currentEditTag = tag
                                    showTagField = true
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
            
            if showTagField {
                HStack {
                    ColorPicker("Tag Color", selection: $tagColor)
                        .labelsHidden()
                    TextField("Tag Title", text: $tagTitle)
                        .font(.title2)
                        .focused($isFocused)
                        .submitLabel(.done)
                        .onSubmit(addOrUpdateTag)
                    Spacer()
                    Button(action: addOrUpdateTag) {
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
        }.navigationTitle("Tags")
    }
    
    private func addOrUpdateTag() {
        withAnimation {
            if let currentEditTag = currentEditTag {
                currentEditTag.name = tagTitle
                currentEditTag.color = tagColor.hex
            } else {
                let newTag = Tag(context: viewContext)
                newTag.timestamp = .now
                newTag.name = tagTitle
                newTag.color = tagColor.hex
            }
            try? viewContext.save()
            showTagField = false
            currentEditTag = nil
            tagTitle = ""
        }
    }
}

struct TagView_Previews: PreviewProvider {
    static var previews: some View {
        TagView()
    }
}
