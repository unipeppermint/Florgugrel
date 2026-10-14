import SwiftUI

/// Shared artwork keeps a beast recognizable across the collection and equipped appearances.
struct FlorgugrelBeastArtwork: View {
    let card: BeastCard

    var body: some View {
        Image(card.artworkName)
            .renderingMode(.original)
            .resizable()
            .scaledToFit()
            .aspectRatio(1, contentMode: .fit)
            .accessibilityHidden(true)
    }
}
