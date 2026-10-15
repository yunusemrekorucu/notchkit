import SwiftUI
import Defaults

struct NotesWidget: View {
    @EnvironmentObject private var model: NotchViewModel
    @Default(.notes) private var notes
    @State private var selection: UUID?
    @FocusState private var focused: Bool

    private var index: Int? {
        let id = selection ?? notes.first?.id
        return notes.firstIndex { $0.id == id }
    }

    var body: some View {
        VStack(spacing: 6) {
            HStack(spacing: 4) {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 4) {
                        ForEach(notes) { note in
                            let isSelected = note.id == (selection ?? notes.first?.id)
                            Button { selection = note.id } label: {
                                Image(systemName: note.icon)
                                    .font(.system(size: 10, weight: .semibold))
                                    .foregroundStyle(isSelected ? .black : .white.opacity(0.7))
                                    .frame(width: 22, height: 18)
                                    .background(Capsule().fill(isSelected ? Color.white : .white.opacity(0.1)))
                            }
                            .buttonStyle(.plain)
                            .contextMenu {
                                Button("Notu sil", role: .destructive) { delete(note) }
                            }
                        }
                    }
                }
                Button {
                    let note = Note(text: "", icon: ["note.text", "star.fill", "bird.fill", "cloud.fill", "leaf.fill"].randomElement()!)
                    notes.append(note)
                    selection = note.id
                } label: {
                    Image(systemName: "square.and.pencil").font(.system(size: 11)).foregroundStyle(.white.opacity(0.7))
                }
                .buttonStyle(.plain)
            }

            if let index {
                TextEditor(text: Binding(
                    get: { notes[safe: index]?.text ?? "" },
                    set: { value in
                        guard notes.indices.contains(index) else { return }
                        notes[index].text = value
                        notes[index].updatedAt = .now
                    }))
                    .font(.system(size: 12))
                    .scrollContentBackground(.hidden)
                    .focused($focused)
                    .padding(6)
                    .background(RoundedRectangle(cornerRadius: 10).fill(Color(red: 0.098, green: 0.098, blue: 0.106)))
                    .overlay(alignment: .topLeading) {
                        if notes[safe: index]?.text.isEmpty ?? true {
                            Text("Bir şeyler yaz…").font(.system(size: 12)).foregroundStyle(.white.opacity(0.3))
                                .padding(.leading, 11).padding(.top, 6).allowsHitTesting(false)
                        }
                    }
            }
        }
        .onChange(of: focused) { _, value in model.isTyping = value }
    }

    private func delete(_ note: Note) {
        notes.removeAll { $0.id == note.id }
        if notes.isEmpty { notes = [Note(text: "")] }
        selection = notes.first?.id
    }
}

extension Array {
    subscript(safe index: Int) -> Element? { indices.contains(index) ? self[index] : nil }
}
