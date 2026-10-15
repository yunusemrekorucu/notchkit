import SwiftUI
import Defaults

struct TodoWidget: View {
    @EnvironmentObject private var model: NotchViewModel
    @Default(.todos) private var todos
    @Default(.showCompletedTodos) private var showCompleted
    @State private var draft = ""
    @FocusState private var focused: Bool

    private var visible: [TodoItem] {
        todos.filter { showCompleted || !$0.isCompleted }
            .sorted { ($0.isCompleted ? 1 : 0, $0.isPriority ? 0 : 1, $0.createdAt) < ($1.isCompleted ? 1 : 0, $1.isPriority ? 0 : 1, $1.createdAt) }
    }

    var body: some View {
        VStack(spacing: 6) {
            HStack(spacing: 6) {
                Image(systemName: "plus").font(.system(size: 10, weight: .bold)).foregroundStyle(.white.opacity(0.5))
                TextField("New task", text: $draft)
                    .textFieldStyle(.plain)
                    .font(.system(size: 12))
                    .focused($focused)
                    .onSubmit(add)
            }
            .padding(.horizontal, 8).frame(height: 24)
            .background(RoundedRectangle(cornerRadius: 8).fill(.white.opacity(0.08)))

            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 2) {
                    ForEach(visible) { item in row(item) }
                }
            }
            .overlay {
                if visible.isEmpty {
                    Text("No tasks 🎉").font(.system(size: 11)).foregroundStyle(.white.opacity(0.4))
                }
            }
        }
        .onChange(of: focused) { _, value in model.isTyping = value }
    }

    private func row(_ item: TodoItem) -> some View {
        HStack(spacing: 6) {
            Button { update(item) { $0.isCompleted.toggle() } } label: {
                Image(systemName: item.isCompleted ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(item.isCompleted ? .green : .white.opacity(0.6))
            }.buttonStyle(.plain)
            Text(item.title)
                .font(.system(size: 12))
                .strikethrough(item.isCompleted)
                .foregroundStyle(.white.opacity(item.isCompleted ? 0.4 : 0.9))
                .lineLimit(1)
            Spacer(minLength: 0)
            Button { update(item) { $0.isPriority.toggle() } } label: {
                Image(systemName: item.isPriority ? "star.fill" : "star")
                    .font(.system(size: 10))
                    .foregroundStyle(item.isPriority ? .yellow : .white.opacity(0.3))
            }.buttonStyle(.plain)
        }
        .frame(height: 20)
        .contextMenu {
            Button("Delete", role: .destructive) { todos.removeAll { $0.id == item.id } }
        }
    }

    private func add() {
        let title = draft.trimmingCharacters(in: .whitespaces)
        guard !title.isEmpty else { return }
        todos.append(TodoItem(title: title))
        draft = ""
    }

    private func update(_ item: TodoItem, _ change: (inout TodoItem) -> Void) {
        guard let i = todos.firstIndex(where: { $0.id == item.id }) else { return }
        change(&todos[i])
    }
}
