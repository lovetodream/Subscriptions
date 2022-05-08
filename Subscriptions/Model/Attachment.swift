// 
//  Attachment.swift
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

import PDFKit

extension Attachment {
    func PDF() -> PDFDocument? {
        guard let data = data else { return nil }
        return PDFDocument(data: data)
    }

    func thumbnail(with size: CGSize = CGSize(width: 100, height: 100)) -> UIImage? {
        PDF()?.page(at: 0)?.thumbnail(of: size, for: .artBox)
    }

    func temporaryFile() -> URL? {
        let fileName: String
        if let title = title {
            fileName = title.hasSuffix(".pdf") ? title : "\(title).pdf"
        } else {
            fileName = "\(UUID().uuidString).pdf"
        }
        let tempDirectory = URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
        let targetURL = tempDirectory.appendingPathComponent(fileName)
        FileManager.default.createFile(atPath: targetURL.path, contents: data, attributes: [:])
        return targetURL
    }
}
