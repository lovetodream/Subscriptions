// 
//  AcknowledgementView.swift
//  Subscriptions
// 
//  Created by Timo Zacherl on 22.01.22.
// 
//  Copyright © 2022 Timo Zacherl. All rights reserved.
// 
//  This program is licensed under the GPL-3.0 License.
//  A copy of that license should be attached to the bundle.
//  If not, see <https://www.gnu.org/licenses/>
// 

import SwiftUI

struct AcknowledgementView: View {
    private var licenses: [License] = [License(product: "FaviconFinder",
                                               content: "",
                                               url: URL(string: "https://raw.githubusercontent.com/OpenSesameManager/FaviconFinder/4.0.4/LICENSE.txt")!),
                                       License(product: "SwiftSoup",
                                               content: "",
                                               url: URL(string: "https://raw.githubusercontent.com/scinfu/SwiftSoup/2.3.6/LICENSE")!),
                                       License(product: "Sentry", content: "", url: URL(string: "https://raw.githubusercontent.com/getsentry/sentry-cocoa/master/LICENSE.md")!)]
    
    @State private var selectedLicense: License?
    @State private var loadingLicense: License?
    @State private var failedAttempts: CGFloat = 0.0
    
    var body: some View {
        List {
            Section {
                ForEach(licenses) { license in
                    HStack {
                        Text(license.product)
                        Spacer()
                        Button {
                            withAnimation {
                                loadingLicense = license
                            }
                            getLicense(for: license.url) { lic in
                                if let lic = lic {
                                    withAnimation {
                                        loadingLicense = nil
                                        self.selectedLicense = License(product: license.product, content: lic, url: license.url)
                                    }
                                } else {
                                    withAnimation {
                                        failedAttempts += 1
                                    }
                                }
                            }
                        } label: {
                            if loadingLicense == license {
                                ProgressView()
                            } else {
                                Text("Show License")
                            }
                        }
                        .disabled(loadingLicense != nil)
                    }
                }
            }
            .modifier(Shake(animatableData: failedAttempts))
        }
        .navigationTitle("Acknowledgements")
        .sheet(item: $selectedLicense) { license in
            LicenseView(license: license)
        }
    }
    
    private func getLicense(for url: URL?, completion: @escaping (String?) -> ()) {
        guard let url = url else {
            completion(nil)
            return
        }

        let task = URLSession.shared.dataTask(with: url) {(data, response, error) in
            guard let data = data else {
                completion(nil)
                return
            }
            
            let license = String(data: data, encoding: .utf8)
            
            completion(license)
        }

        task.resume()
    }
    
}

struct AcknowledgementView_Previews: PreviewProvider {
    static var previews: some View {
        AcknowledgementView()
    }
}
