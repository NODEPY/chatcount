import SwiftUI
import UniformTypeIdentifiers

@main
struct ChatCountApp: App {
    var body: some Scene {
        WindowGroup("ChatCount") { ContentView().frame(minWidth: 840, minHeight: 660) }
            .defaultSize(width: 1040, height: 790)
    }
}

struct ContentView: View {
    @State private var language = UILanguage.initial
    func t(_ text: String) -> String { translations[text]?[language.rawValue] ?? text }
    @State private var chats: [Chat] = []
    @State private var chatID = ""
    @State private var leftID = ""
    @State private var rightID = ""
    @State private var hideCommon = true
    @State private var minimumLetters = 3
    @State private var ignored = ""
    @State private var loading = false
    @State private var error: String?
    @State private var filename = ""
    var chat: Chat? { chats.first { $0.id == chatID } }
    var excluded: Set<String> { Set(Analyzer.tokens(ignored)).union(hideCommon ? Analyzer.stopwords : []) }
    var selected: [Person] { [leftID, rightID].compactMap { id in chat?.people.first { $0.id == id } } }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 6) {
                    Text("ChatCount").font(.system(size: 25, weight: .semibold))
                    Text(t("Аналіз переписок Telegram")).foregroundStyle(.secondary)
                }
                Spacer()
                Picker(t("Мова"), selection: $language) {
                    ForEach(UILanguage.allCases, id: \.self) { Text($0.name).tag($0) }
                }.frame(width: 180)
                Button(action: open) { Label(t("Відкрити JSON"), systemImage: "folder") }
                    .buttonStyle(.borderedProminent).controlSize(.large).disabled(loading)
            }
            if loading {
                Spacer()
                HStack { Spacer(); ProgressView(t("Рахую слова…")); Spacer() }
                Spacer()
            } else if let chat {
                HStack {
                    if chats.count > 1 {
                        Picker(t("Переписка"), selection: $chatID) {
                            ForEach(chats) { Text($0.name).tag($0.id) }
                        }.frame(maxWidth: 400)
                    } else { Text(chat.name).font(.title3.bold()) }
                    Spacer()
                    Text(filename).font(.caption).foregroundStyle(.secondary).lineLimit(1)
                }
                HStack(spacing: 22) {
                    Toggle(t("Приховати поширені слова"), isOn: $hideCommon)
                        .help(t("Прибирає базовий список службових слів українською, російською та англійською."))
                    Picker(t("Мінімум літер"), selection: $minimumLetters) {
                        ForEach(1...6, id: \.self) { Text("\($0)").tag($0) }
                    }.frame(width: 170)
                }
                HStack {
                    TextField(t("Не рахувати слова: ну, ок…"), text: $ignored).textFieldStyle(.roundedBorder)
                }
                Text(t("Фільтри: українська, English, русский")).font(.caption).foregroundStyle(.secondary)
                ScrollView {
                    HStack(alignment: .top, spacing: 20) {
                        column(id: $leftID, other: rightID)
                        column(id: $rightID, other: leftID)
                    }.padding(2)
                }
                HStack {
                    Text(t("Без різниці регістру · різні форми слів рахуються окремо")).font(.caption).foregroundStyle(.secondary)
                    Spacer()
                    Button(t("Зберегти CSV"), action: save).disabled(selected.isEmpty)
                }
            } else {
                Spacer()
                VStack(spacing: 18) {
                    Text(t("Відкрийте експорт Telegram")).font(.title2.bold())
                    Text(t("Виберіть result.json з експорту Telegram.\nІмена та два рейтинги з’являться автоматично."))
                        .multilineTextAlignment(.center).foregroundStyle(.secondary)
                    VStack(alignment: .leading, spacing: 8) {
                        Text(t("Як отримати файл")).font(.headline)
                        Text(t("1. У Telegram Desktop відкрийте потрібну переписку."))
                        Text(t("2. Меню ⋯ → Export chat history / Експорт історії чату."))
                        Text(t("3. Виберіть JSON. Фото та відео завантажувати не потрібно."))
                    }.padding(20).overlay(RoundedRectangle(cornerRadius: 5).stroke(Color.secondary.opacity(0.25)))
                }.frame(maxWidth: .infinity)
                Spacer()
            }
            Label(t("Переписка обробляється лише на цьому Mac"), systemImage: "lock.shield")
                .font(.caption).foregroundStyle(.secondary)
        }
        .padding(28)
        .onChange(of: chatID) { _ in choosePeople() }
        .alert(t("Не вдалося виконати дію"), isPresented: Binding(get: { error != nil }, set: { if !$0 { error = nil } })) {
            Button(t("Зрозуміло")) { error = nil }
        } message: { Text(t(error ?? "")) }
    }
    @ViewBuilder
    func column(id: Binding<String>, other: String) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            if let chat {
                Picker(t("Учасник"), selection: id) {
                    Text(t("Оберіть учасника")).tag("")
                    ForEach(chat.people.filter { $0.id != other }) { person in
                        Text(chat.people.filter { $0.name == person.name }.count > 1 ? "\(person.name) · \(person.id)" : person.name).tag(person.id)
                    }
                }.labelsHidden()
                if let person = chat.people.first(where: { $0.id == id.wrappedValue }) {
                    Text(person.name).font(.title2.bold()).textSelection(.enabled)
                    Text("\(person.messages) \(t("повідомлень")) · \(person.total) \(t("слів до фільтрів"))").font(.caption).foregroundStyle(.secondary)
                    let top = person.top(excluding: excluded, minimumLetters: minimumLetters)
                    if top.isEmpty { Text(t("За цими фільтрами слів немає. Зменште мінімум літер або вимкніть фільтр.")).foregroundStyle(.secondary).padding(.vertical, 40) }
                    ForEach(Array(top.enumerated()), id: \.element.id) { index, item in
                        VStack(spacing: 7) {
                            HStack {
                                Text(String(format: "%02d", index + 1)).font(.caption.monospacedDigit()).foregroundStyle(.secondary).frame(width: 24)
                                Text(item.word).font(.system(size: 14, weight: .medium)).textSelection(.enabled)
                                Spacer()
                                Text("\(item.count)").font(.body.weight(.semibold)).monospacedDigit()
                            }
                            Divider()
                        }
                    }
                } else {
                    Text(t("Для другої сторони потрібні повідомлення іншого учасника.")).foregroundStyle(.secondary).padding(.vertical, 40)
                }
            }
        }.padding(18).frame(maxWidth: .infinity, alignment: .topLeading)
            .background(Color(nsColor: .controlBackgroundColor))
            .overlay(RoundedRectangle(cornerRadius: 5).stroke(Color.secondary.opacity(0.25)))
    }
    func choosePeople() {
        leftID = chat?.people.first?.id ?? ""
        rightID = chat?.people.dropFirst().first?.id ?? ""
    }
    func open() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.json]
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        guard panel.runModal() == .OK, let url = panel.url else { return }
        loading = true
        Task {
            do {
                let parsed = try await Task.detached(priority: .userInitiated) {
                    try Analyzer.parse(Data(contentsOf: url))
                }.value
                chats = parsed
                chatID = parsed[0].id
                choosePeople()
                filename = url.lastPathComponent
            } catch { self.error = error.localizedDescription }
            loading = false
        }
    }
    func save() {
        let panel = NSSavePanel()
        panel.allowedContentTypes = [.commaSeparatedText]
        panel.nameFieldStringValue = "telegram-top-10.csv"
        guard panel.runModal() == .OK, let url = panel.url else { return }
        do { try Analyzer.csv(selected, excluding: excluded, minimumLetters: minimumLetters, headers: ["Учасник", "ID", "Місце", "Слово", "Кількість"].map(t)).write(to: url, atomically: true, encoding: .utf8) }
        catch { self.error = error.localizedDescription }
    }
}
