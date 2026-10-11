import Foundation

struct WordCount: Identifiable, Sendable {
    var id: String { word }
    let word: String
    let count: Int
}
struct Person: Identifiable, Sendable {
    let id: String
    var name: String
    var messages = 0
    var counts: [String: Int] = [:]
    var total: Int { counts.values.reduce(0, +) }
    func top(excluding: Set<String>, minimumLetters: Int = 1) -> [WordCount] {
        var items: [WordCount] = []
        for (word, count) in counts where !excluding.contains(word) {
            guard word.filter({ $0.isLetter }).count >= minimumLetters else { continue }
            items.append(WordCount(word: word, count: count))
        }
        items.sort { left, right in
            if left.count == right.count { return left.word < right.word }
            return left.count > right.count
        }
        return Array(items.prefix(10))
    }
}
struct Chat: Identifiable, Sendable {
    let id: String
    let name: String
    let people: [Person]
}
enum AnalysisError: LocalizedError {
    case invalid, empty
    var errorDescription: String? {
        switch self {
        case .invalid: return "Це не JSON-експорт Telegram. Експортуйте історію чату у форматі JSON та відкрийте result.json."
        case .empty: return "В експорті немає повідомлень з іменами авторів. Виберіть іншу переписку."
        }
    }
}
enum Analyzer {
    static let words = try! NSRegularExpression(pattern: #"\p{L}[\p{L}\p{M}]*(?:['’ʼ-][\p{L}\p{M}]+)*"#)
    static let links = try! NSRegularExpression(pattern: #"(?i)(?:https?://|www\.|t\.me/)[^\s]+|[\p{L}\p{N}._%+-]+@[\p{L}\p{N}.-]+\.[\p{L}]{2,}"#)
    static let stopwords = Set("і й та а але або бо що щоб як я ти він вона воно ми ви вони мене мені тебе тобі його її їй нас нам вас вам їх їм це цей ця ці то так ні не на у в до з із зі за по про для від під над при о об ж же би б був була було були є ще вже ну ось там тут чи и но или что чтобы как ты он она оно мы вы они меня мне тебя его её ей их им это этот эта эти нет с со от под бы был была было были есть ещё уже вот ли the a an and or but i you he she it we they me my your our to of in on for is are was were be been am this that with at as not so if then мій моя моє мої твій твоя твоє твої свій своя своє свої хто кого кому чого чому який яка яке які якийсь якась якесь якісь тільки лише просто дуже теж також навіть собі себе все всі всього вся весь десь кудись щось хтось нічого ніхто зараз тоді потім тому через між без раз взагалі типу коротше короче типа бля блін мой моё мои твой твоё твои свой своё свои кто чего почему какой какая какое какие только очень тоже также даже себя всё всего где куда когда потом сейчас потому между вообще блин еще да ага угу ок окей okay ok yeah yes do does did have has had can could would should will just really very also some any all there here from about into than them their its mine yours must might may can't cannot don't doesn't didn't isn't aren't wasn't weren't won't wouldn't shouldn't couldn't i'm you're he's she's it's we're they're i've you've we've they've i'll you'll he'll she'll we'll they'll that's there's what's who's let's whom whose which when where why how more most much many such each other another both either neither during before after again once own same only off out up down over under between being those these itself themselves ourselves yourself himself herself тобою мною вами ними цього цьому цієї цим цих моєї моїх твоєї твоїх собою будь наче ніби нехай хай адже отже тому-то це-то тобой мной этого этому этой этим этих моей моих твоей твоих собой будет будут буду будешь будем будете быть пусть ведь лишь будто зато хотя разве именно".split(separator: " ").map(String.init))
    static func tokens(_ text: String) -> [String] {
        let normalized = text.precomposedStringWithCanonicalMapping.lowercased()
            .replacingOccurrences(of: "’", with: "'").replacingOccurrences(of: "ʼ", with: "'")
        let clean = links.stringByReplacingMatches(in: normalized, range: NSRange(normalized.startIndex..., in: normalized), withTemplate: " ")
        return words.matches(in: clean, range: NSRange(clean.startIndex..., in: clean)).compactMap {
            Range($0.range, in: clean).map { String(clean[$0]) }
        }
    }
    static func messageText(_ value: Any?) -> String {
        if let text = value as? String { return text }
        if let parts = value as? [Any] {
            return parts.map { part -> String in
                if let string = part as? String { return string }
                guard let entity = part as? [String: Any] else { return "" }
                if ["link", "email", "mention", "bot_command"].contains(entity["type"] as? String ?? "") { return " " }
                return entity["text"] as? String ?? ""
            }.joined()
        }
        return ""
    }
    static func parse(_ data: Data) throws -> [Chat] {
        guard let root = (try? JSONSerialization.jsonObject(with: data)) as? [String: Any] else { throw AnalysisError.invalid }
        let raw: [[String: Any]]
        if root["messages"] is [Any] { raw = [root] }
        else if let chats = root["chats"] as? [String: Any], let list = chats["list"] as? [[String: Any]] { raw = list }
        else { throw AnalysisError.invalid }
        var result: [Chat] = []
        for (index, chat) in raw.enumerated() {
            guard let messages = chat["messages"] as? [[String: Any]] else { continue }
            var people: [String: Person] = [:]
            for message in messages where message["type"] as? String == "message" {
                guard let name = message["from"] as? String, !name.isEmpty else { continue }
                let id = message["from_id"] as? String ?? "name:\(name)"
                var person = people[id] ?? Person(id: id, name: name)
                person.name = name
                person.messages += 1
                for word in tokens(messageText(message["text"])) { person.counts[word, default: 0] += 1 }
                people[id] = person
            }
            if !people.isEmpty {
                result.append(Chat(id: "\(index)", name: chat["name"] as? String ?? "Переписка", people: people.values.sorted {
                    $0.messages == $1.messages ? $0.id < $1.id : $0.messages > $1.messages
                }))
            }
        }
        guard !result.isEmpty else { throw AnalysisError.empty }
        return result
    }
    static func csv(_ people: [Person], excluding: Set<String>, minimumLetters: Int = 1, headers: [String] = ["Учасник", "ID", "Місце", "Слово", "Кількість"]) -> String {
        func quote(_ string: String) -> String { "\"" + string.replacingOccurrences(of: "\"", with: "\"\"") + "\"" }
        var rows = [headers.map(quote).joined(separator: ",")]
        for person in people {
            for (index, item) in person.top(excluding: excluding, minimumLetters: minimumLetters).enumerated() {
                rows.append([quote(person.name), quote(person.id), String(index + 1), quote(item.word), String(item.count)].joined(separator: ","))
            }
        }
        return "\u{FEFF}" + rows.joined(separator: "\r\n")
    }
}
