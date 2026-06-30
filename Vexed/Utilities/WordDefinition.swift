import SwiftUI
import UIKit

/// SwiftUI wrapper around UIReferenceLibraryViewController (the system dictionary).
struct SystemDictionaryView: UIViewControllerRepresentable {
    let term: String

    func makeUIViewController(context: Context) -> UIReferenceLibraryViewController {
        UIReferenceLibraryViewController(term: term)
    }

    func updateUIViewController(_ uiViewController: UIReferenceLibraryViewController, context: Context) {}
}

extension UIReferenceLibraryViewController {
    /// Returns true if the system dictionary has an entry for this word.
    static func has(_ term: String) -> Bool {
        dictionaryHasDefinition(forTerm: term)
    }
}
