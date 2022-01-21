//
//  IconPicker.swift
//  Subscriptions
//
//  Created by Timo Zacherl on 09.01.22.
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
    
    var searchResults: [String] {
        if searchText.isEmpty {
            return Icons.available
        } else {
            return Icons.available.filter { $0.lowercased().contains(searchText.lowercased()) }
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
                    ForEach(searchResults, id: \.self) { icon in
                        Button {
                            withAnimation {
                                self.isSystemImage = true
                                self.systemImage = icon
                                dismiss()
                            }
                        } label: {
                            Label {
                                Text(icon
                                        .replacingOccurrences(of: ".circle.fill", with: "")
                                        .replacingOccurrences(of: ".rectangle.fill", with: "")
                                        .replacingOccurrences(of: ".square.fill", with: "")
                                        .replacingOccurrences(of: ".shield.fill", with: "")
                                        .replacingOccurrences(of: ".fill", with: "")
                                        .replacingOccurrences(of: ".left", with: "")
                                        .replacingOccurrences(of: ".right", with: "")
                                        .replacingOccurrences(of: ".leading", with: "")
                                        .replacingOccurrences(of: ".trailing", with: "")
                                        .replacingOccurrences(of: ".badge", with: "")
                                        .replacingOccurrences(of: ".", with: " ")
                                        .localizedCapitalized)
                                    .foregroundColor(.label)
                            } icon: {
                                Image(systemName: icon)
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
            IconPicker(image: .constant(UIImage()), systemImage: .constant(""), isSystemImage: .constant(false), color: .constant(.accentColor))
            IconPicker(image: .constant(UIImage()), systemImage: .constant(""), isSystemImage: .constant(false), color: .constant(.accentColor))
                .preferredColorScheme(.dark)
        }
    }
}

struct Shake: GeometryEffect {
    var amount: CGFloat = 10
    var shakesPerUnit = 3
    var animatableData: CGFloat

    func effectValue(size: CGSize) -> ProjectionTransform {
        ProjectionTransform(CGAffineTransform(translationX:
            amount * sin(animatableData * .pi * CGFloat(shakesPerUnit)),
            y: 0))
    }
}

struct Bounce: GeometryEffect {
    var amount: CGFloat = 5
    var shakesPerUnit = 3
    var animatableData: CGFloat

    func effectValue(size: CGSize) -> ProjectionTransform {
        ProjectionTransform(CGAffineTransform(translationX: 0,
            y: amount * sin(animatableData * .pi * CGFloat(shakesPerUnit))))
    }
}
