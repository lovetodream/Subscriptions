// 
//  DocumentPicker.swift
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

import Foundation
import SwiftUI

struct DocumentPicker: UIViewControllerRepresentable {

    @Binding var fileContent: Data?
    @Binding var fileName: String?

    func makeCoordinator() -> DocumentPickerCoordinator {
        DocumentPickerCoordinator(fileContent: $fileContent, fileName: $fileName)
    }

    func makeUIViewController(context: UIViewControllerRepresentableContext<DocumentPicker>) -> UIDocumentPickerViewController {
        let controller = UIDocumentPickerViewController(forOpeningContentTypes: [.pdf], asCopy: true)
        controller.delegate = context.coordinator
        return controller
    }

    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: UIViewControllerRepresentableContext<DocumentPicker>) {
    }

    class DocumentPickerCoordinator: NSObject, UIDocumentPickerDelegate, UINavigationControllerDelegate {

        @Binding var fileContent: Data?
        @Binding var fileName: String?

        init(fileContent: Binding<Data?>, fileName: Binding<String?>) {
            _fileContent = fileContent
            _fileName = fileName
        }

        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            let fileURL = urls[0]
            do {
                fileContent = try Data(contentsOf: fileURL)
                fileName = fileURL.lastPathComponent
            } catch let error {
                print(error.localizedDescription)
            }
        }

    }

}
