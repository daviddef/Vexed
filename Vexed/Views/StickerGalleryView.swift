import SwiftUI

struct StickerGalleryView: View {
    private let columns = [GridItem(.adaptive(minimum: 84), spacing: 12)]
    private var words: [String] { WordSticker.collectedWords().sorted() }

    var body: some View {
        ZStack {
            Color(red: 0.06, green: 0.06, blue: 0.09).ignoresSafeArea()
            if words.isEmpty {
                VStack(spacing: 12) {
                    Text("🎨")
                        .font(.system(size: 48))
                    Text("No stickers yet")
                        .font(.system(size: 18, weight: .black, design: .rounded))
                        .foregroundColor(Color(white: 0.4))
                    Text("Spell a new word to earn your first sticker!")
                        .font(.system(size: 13))
                        .foregroundColor(Color(white: 0.3))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                }
            } else {
                ScrollView {
                    VStack(spacing: 4) {
                        Text("\(words.count) word\(words.count == 1 ? "" : "s") collected")
                            .font(.system(size: 12, weight: .bold, design: .rounded))
                            .foregroundColor(Color(white: 0.45))
                            .padding(.top, 12)
                            .padding(.bottom, 8)

                        LazyVGrid(columns: columns, spacing: 12) {
                            ForEach(words, id: \.self) { word in
                                VStack(spacing: 4) {
                                    Text(WordSticker.emoji(for: word))
                                        .font(.system(size: 34))
                                    Text(word.capitalized)
                                        .font(.system(size: 10, weight: .black, design: .rounded))
                                        .foregroundColor(.white)
                                        .lineLimit(1)
                                        .minimumScaleFactor(0.6)
                                }
                                .padding(.vertical, 10)
                                .frame(maxWidth: .infinity)
                                .background(RoundedRectangle(cornerRadius: 14).fill(Color(white: 0.08)))
                                .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color(white: 0.14), lineWidth: 1))
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.bottom, 32)
                    }
                }
            }
        }
        .navigationTitle("My Stickers")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Color(red: 0.06, green: 0.06, blue: 0.09), for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
    }
}
