// 
//  AttachmentView.swift
//  Subscriptions
// 
//  Created by Timo Zacherl on 07.05.22.
// 
//  Copyright © 2022 Timo Zacherl. All rights reserved.
// 
//  This program is licensed under the GPL-3.0 License.
//  A copy of that license should be attached to the bundle.
//  If not, see <https://www.gnu.org/licenses/>
// 

import SwiftUI
import PDFKit

struct AttachmentView: View {
    @Environment(\.managedObjectContext) var viewContext

    var attachment: Attachment

    @State private var showShareMenu = false
    @State private var newTitle = ""
    @State private var showTitleEditor = false
    @FocusState private var isFocused

    var body: some View {
        ZStack(alignment: .bottom) {
            Group {
                if let data = attachment.data {
                    AttachmentDataView(data: data)
                        .ignoresSafeArea(.all, edges: .vertical)
                } else {
                    Text("It seems like the attachment contains no valid data. You might want to remove it.")
                }
            }
            .zIndex(1)

            if showTitleEditor {
                FloatingTextField(color: .constant(.primary),
                                  text: $newTitle,
                                  isFocused: _isFocused,
                                  showColorPicker: false,
                                  textLabel: "Document name",
                                  submitAction: updateTitle)
                    .zIndex(2)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .navigationTitle(attachment.title ?? "Unnamed")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    showShareMenu.toggle()
                } label: {
                    Image(systemName: "square.and.arrow.up")
                }
            }
            ToolbarItem(placement: .principal) {
                HStack(spacing: 2) {
                    Text(attachment.title ?? "Unnamed")
                        .lineLimit(1)
                    Button {
                        withAnimation {
                            showTitleEditor.toggle()
                            isFocused = true
                        }
                    } label: {
                        if showTitleEditor {
                            Label("Cancel editing", systemImage: "xmark")
                                .labelStyle(.iconOnly)
                        } else {
                            Label("Edit document name", systemImage: "pencil")
                                .labelStyle(.iconOnly)
                        }
                    }
                }
            }
        }
        .sheet(isPresented: $showShareMenu) {
            ActivityView(activityItems: [attachment.temporaryFile() as Any])
                .ignoresSafeArea()
        }
    }

    func updateTitle() {
        withAnimation {
            attachment.title = newTitle
            try? viewContext.save()
            showTitleEditor = false
        }
    }
}

struct AttachmentDataView: UIViewRepresentable {
    var data: Data

    func makeUIView(context: Context) -> PDFView {
        let pdfView = PDFView()
        pdfView.document = PDFDocument(data: data)
        pdfView.autoScales = true
        pdfView.displayMode = .singlePageContinuous
        return pdfView
    }

    func updateUIView(_ uiView: PDFView, context: Context) {}
}
