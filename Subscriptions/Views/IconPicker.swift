//
//  IconPicker.swift
//  Subscriptions
//
//  Created by Timo Zacherl on 09.01.22.
//
//  Copyright © 2022 Timo Zacherl. All rights reserved.
//
//  This program is licensed under the GPL-3.0 License.
//  A copy of that license should be attached to the bundle.
//  If not, see <https://www.gnu.org/licenses/>
//

import SwiftUI
import FaviconFinder

struct IconPicker: View {
    @Environment(\.dismiss) var dismiss
    
    @State private var showGallery = false
    @State private var urlString = "https://"
    @State private var showUrlInput = false
    @State private var errored: CGFloat = 0
    @Binding var image: UIImage
    @Binding var systemImage: String
    @Binding var isSystemImage: Bool
    @Binding var color: Color
    
    private enum Field: Int, Hashable {
        case faviconUrl
    }
    @FocusState private var focusedField: Field?
    
    @State private var searchText = ""
    
    var searchResults: [Icon] {
        if searchText.isEmpty {
            return Icon.list
        } else {
            return Icon.list.filter {
                $0.symbolName.lowercased().contains(searchText.lowercased()) ||
                $0.label.lowercased().contains(searchText.lowercased())
            }
        }
    }

    
    var body: some View {
        NavigationView {
            Form {
                Button {
                    withAnimation {
                        showGallery.toggle()
                    }
                } label: {
                    Text("Choose from gallery")
                }
                
                if showUrlInput {
                    HStack {
                        TextField("https://", text: $urlString)
                            .focused($focusedField, equals: .faviconUrl)
                            .submitLabel(.go)
                            .onSubmit {
                                fetchFavicon()
                            }
                        
                        Spacer()
                        
                        CloseButton(fill: .secondarySystemBackground) {
                            withAnimation {
                                showUrlInput.toggle()
                            }
                        }
                        
                        Button(action: fetchFavicon) {
                            Label("Download logo", systemImage: "square.and.arrow.down")
                        }
                        .labelStyle(.iconOnly)
                        .buttonStyle(.borderless)
                        .disabled(!(urlString.contains("https://") && urlString != "https://"))
                    }
                    .modifier(Shake(animatableData: errored))
                } else {
                    Button {
                        withAnimation {
                            showUrlInput.toggle()
                            focusedField = .faviconUrl
                        }
                    } label: {
                        Text("Load logo (favicon) from URL")
                    }
                }
                
                Section {
                    ForEach(searchResults) { icon in
                        Button {
                            withAnimation {
                                self.isSystemImage = true
                                self.systemImage = icon.symbolName
                                dismiss()
                            }
                        } label: {
                            Label {
                                Text(icon.label)
                                    .foregroundColor(.label)
                            } icon: {
                                Image(systemName: icon.symbolName)
                                    .symbolRenderingMode(.hierarchical)
                                    .foregroundColor(color)
                            }
                        }
                    }
                } header: {
                    Text("Or choose one of these")
                }
            }
            .searchable(text: $searchText)
            .navigationTitle("Choose icon")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    CloseButton {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showGallery) {
                ImagePicker(selectedImage: $image, sourceType: .photoLibrary)
            }
            .onChange(of: image) { _ in
                self.isSystemImage = false
                dismiss()
            }
        }
    }
    
    func fetchFavicon() {
        if let url = URL(string: urlString) {
            Task {
                let icon = try? await FaviconFinder(url: url).downloadFavicon().image.cgImage
                if let icon = icon {
                    withAnimation {
                        self.image = UIImage(cgImage: icon)
                    }
                } else {
                    withAnimation {
                        errored += 1
                    }
                }
            }
        } else {
            withAnimation {
                errored += 1
            }
        }
    }
}

struct IconPicker_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            IconPicker(image: .constant(UIImage()),
                       systemImage: .constant(""),
                       isSystemImage: .constant(false),
                       color: .constant(.accentColor))
            IconPicker(image: .constant(UIImage()),
                       systemImage: .constant(""),
                       isSystemImage: .constant(false),
                       color: .constant(.accentColor))
                .preferredColorScheme(.dark)
        }
    }
}
