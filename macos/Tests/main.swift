import Foundation

func check(_ condition: @autoclosure () -> Bool, _ description: String) {
    if !condition() { fatalError(description) }
    print("PASS: \(description)")
}
let sample = #"""
{"name":"Тест","messages":[
{"type":"message","from":"Оля","from_id":"user1","text":"Привіт привіт ПРИВІТ! П’ять пʼять п'ять. https://example.com/test"},
{"type":"message","from":"Богдан","from_id":"user2","text":["Чай ",{"type":"bold","text":"чай"}," ☕!",{"type":"link","text":"https://foo.bar"}]},
{"type":"service","from":"Оля","from_id":"user1","text":"не рахувати"},
{"type":"message","from":"Оля нове ім’я","from_id":"user1","text":["при",{"type":"bold","text":"віт"}]},
{"type":"message","from":"Богдан","from_id":"user2","text":""},
{"type":"message","from":null,"text":"невідомий"}
]}
"""#.data(using: .utf8)!
let chat = try Analyzer.parse(sample)[0]
check(chat.people.count == 2, "Two authors, service messages skipped")
let a = chat.people.first { $0.id == "user1" }!
let b = chat.people.first { $0.id == "user2" }!
check(a.name == "Оля нове ім’я", "Stable author ID survives name changes")
check(a.counts["привіт"] == 4 && a.counts["п'ять"] == 3 && a.total == 7, "Case, apostrophes, rich-text boundaries and links")
check(b.counts["чай"] == 2 && b.messages == 2, "Rich text and empty media captions")
check(a.top(excluding: ["привіт"]).first?.word == "п'ять", "Excluded words")
check(Analyzer.tokens("hello 123 🙂 email@example.com https://abc.test пів-яблука") == ["hello", "пів-яблука"], "Unicode words and link removal")
let root = try JSONSerialization.jsonObject(with: sample)
let full = try JSONSerialization.data(withJSONObject: ["chats": ["list": [root, root]]])
let fullChats = try Analyzer.parse(full)
check(fullChats.count == 2, "Full-account export keeps chats separate")
let sameNames = #"{"messages":[{"type":"message","from":"A","from_id":"1","text":"b a"},{"type":"message","from":"A","from_id":"2","text":"c"}]}"#.data(using: .utf8)!
let names = try Analyzer.parse(sameNames)[0]
check(names.people.count == 2, "Identical names retain separate identities")
check(names.people.first!.top(excluding: []).map(\.word) == ["a", "b"], "Deterministic tie ordering")
for invalid in ["bad", "{}", "{\"messages\":[]}"] {
    do { _ = try Analyzer.parse(Data(invalid.utf8)); fatalError("Invalid accepted") }
    catch { print("PASS: Invalid or empty export rejected") }
}
check(Analyzer.csv([a, b], excluding: []).contains("\"привіт\",4"), "CSV contains the displayed counts")
print("All analysis tests passed.")
let noisy = Person(id: "filter", name: "Тест", counts: ["я": 100, "не": 90, "і": 80, "просто": 70, "дуже": 60, "кава": 5, "чай": 4, "а-б": 3])
check(noisy.top(excluding: Analyzer.stopwords, minimumLetters: 3).map(\.word) == ["кава", "чай"], "Default filters remove short and common words")
check(noisy.top(excluding: Analyzer.stopwords, minimumLetters: 4).map(\.word) == ["кава"], "Adjustable minimum letter count")
check(!Analyzer.csv([noisy], excluding: Analyzer.stopwords, minimumLetters: 4).contains("чай"), "CSV applies the same length filter")
let multilingual = Person(id: "multi", name: "Test", counts: ["цього": 50, "твоїх": 45, "don't": 40, "should": 35, "этого": 30, "будет": 25, "кава": 5, "coffee": 4, "кофе": 3])
check(multilingual.top(excluding: Analyzer.stopwords, minimumLetters: 3).map(\.word) == ["кава", "coffee", "кофе"], "All three language filters apply together")
for lang in ["uk", "en", "ru"] {
    check(translations.values.allSatisfy { !($0[lang] ?? "").isEmpty }, "Complete interface translations: \(lang)")
}
check(Analyzer.csv([multilingual], excluding: Analyzer.stopwords, headers: ["Person", "ID", "Rank", "Word", "Count"]).contains("\"Person\""), "Localized CSV headings")
