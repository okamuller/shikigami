import Foundation

// docs/local-first-migration.md / docs/requirements.md LF-GEN-01 準拠。
// ClaudeAPI 障害時・オフライン時のフォールバック鑑定生成。
// 式神別・五行別・スコア帯別・悩みカテゴリ別テンプレートを組み合わせて生成する。
// .claude/B_logic.md フォールバック設計: API fail → テンプレートをそのまま返す
final class LocalFortuneGenerator: ClaudeClient, Sendable {

    func generate(request: FortuneRequest) async throws -> FortuneResponse {
        let text = generateText(
            engine: request.engine,
            topic: request.topic,
            shikigamiIndex: request.meishiki.shikigamiIndex,
            gogyo: request.meishiki.gogyo,
            score: request.meishiki.score,
            historyHash: request.historySummaryHash
        )
        return FortuneResponse(
            id: UUID().uuidString,
            text: text,
            cached: false,
            isFallback: true,
            tokensIn: 0,
            tokensOut: 0
        )
    }

    // MARK: - 生成ロジック

    private func generateText(engine: String, topic: String, shikigamiIndex: Int, gogyo: String, score: Int, historyHash: String = "") -> String {
        let si = ((shikigamiIndex % 12) + 12) % 12
        let variant = textVariant(historyHash: historyHash)
        let band = scoreBand(score)
        let topicIdx = topicIndex(topic)
        let isNanboku = engine == "nanboku"

        let opener = isNanboku ? nanbokuOpeners[si][variant] : seimeiOpeners[si][variant]
        let middle = isNanboku ? nanbokuTopicLines[topicIdx] : seimeiTopicLines[topicIdx]
        let closer = isNanboku ? nanbokuCloseLines[band] : seimeiCloseLines[band]

        return "\(opener)\n\(middle) \(closer)"
    }

    // FR-EN-04: 日付パリティと履歴ハッシュの先頭nibble を組み合わせてバリアントを決定する。
    // historyHash が空の場合は日付パリティのみ使用。
    private func textVariant(historyHash: String) -> Int {
        let dayBit = dayOrdinalVariant()
        guard let firstChar = historyHash.first, let nibble = firstChar.hexDigitValue else { return dayBit }
        return (dayBit + nibble) % 2
    }

    private func dayOrdinalVariant() -> Int {
        let cal = Calendar(identifier: .gregorian)
        let ordinal = cal.ordinality(of: .day, in: .era, for: .now) ?? 0
        return ordinal % 2
    }

    private func scoreBand(_ score: Int) -> Int {
        if score <= 69 { return 0 }   // low
        if score <= 84 { return 1 }   // middle
        return 2                       // high
    }

    private func topicIndex(_ topic: String) -> Int {
        switch topic {
        case "love":    return 0
        case "work":    return 1
        case "money":   return 2
        case "health":  return 3
        case "family":  return 4
        case "destiny": return 5
        default:        return 5
        }
    }

    // MARK: - 晴明テンプレート（文語体）

    // 12 式神 × 2 日替わりバリアント
    private let seimeiOpeners: [[String]] = [
        // 0: 貴人（土・吉）
        ["貴人の気、汝が道を高く照らすなり。天の縁、今まさに動かんとするなり。",
         "高貴なる縁の力、今まさに汝に宿る。援けの手、思わぬ方より参るであろう。"],
        // 1: 騰蛇（火・凶）
        ["騰蛇の変化、焦りを戒めるなり。嵐の中にこそ、真の道が見えるなり。",
         "騰蛇の炎、流れの変わり目を告げる。今は静かに気を整えるべし。"],
        // 2: 朱雀（火・中）
        ["朱雀の知恵、言葉に宿るなり。文書と問答に好機が訪れるであろう。",
         "朱雀の気、文書と言葉に吉をもたらす。伝えることで道が開かれるなり。"],
        // 3: 六合（木・吉）
        ["六合の縁、人と人を結ぶなり。和合と協力の時が来たれり。",
         "六合の気、和合を呼ぶ。人との絆を大切にされよ。縁の糸は続くなり。"],
        // 4: 勾陳（土・凶）
        ["勾陳の静、地に足をつけるべし。急がず確かめることが吉なり。",
         "勾陳の気、停滞を告げる。今は動かず、内に力を蓄えるべし。"],
        // 5: 青龍（木・吉）
        ["青龍の吉気、財と発展を運ぶなり。前へ進む好機がまいりたり。",
         "青龍の瑞気、吉祥を告げる。大きな一歩を踏み出す時が来たるなり。"],
        // 6: 天空（土・中）
        ["天空の霧、判断を急がぬ時なり。霧晴れれば真実が見えるであろう。",
         "天空の気、迷いの中に真実が潜む。今は問いを立てて待つがよい。"],
        // 7: 白虎（金・凶）
        ["白虎の鋭気、慎重を要する時なり。変動の兆し、嵐の後に道あり。",
         "白虎の気、変動を告げる。慎重に歩めば、難は越えられるなり。"],
        // 8: 太常（土・吉）
        ["太常の加護、日々の積み重ねに宿る。常道を守る者に福来たるなり。",
         "太常の安定、礼と積み重ねに吉あり。揺るぎない歩みが道を作るなり。"],
        // 9: 玄武（水・凶）
        ["玄武の水、隠れた真実を示すなり。慎みを持ちて静かに観よ。",
         "玄武の気、慎みと静けさを求める。水の如く柔らかに流れるべし。"],
        // 10: 太陰（金・中）
        ["太陰の月光、陰の知恵を授けるなり。表に出ず静かに動く時なり。",
         "太陰の気、内なる知恵を育む時。月満ちれば光は必ず来たるなり。"],
        // 11: 天后（水・吉）
        ["天后の慈愛、豊かな実りをもたらす。縁と絆を育む時が来たれり。",
         "天后の恵み、母なる力が汝を守らん。天の恵みは尽きぬなり。"],
    ]

    // 6 悩みカテゴリ（晴明）
    private let seimeiTopicLines: [String] = [
        "縁の糸、今まさに動かんとするなり。心を開けば、天の縁は自ずと結ばれる。",       // love
        "仕事の道、着実な歩みに吉あり。焦らず一歩一歩を重ねるべし。",                   // work
        "財の流れ、入りと出を見極めるがよい。今は種を蒔く時、収穫は後に来たる。",       // money
        "体の声、今こそ聞くべし。無理を避け、自然の理に従えば快癒あらん。",             // health
        "家族の絆、言葉よりも行いに現れる。共に過ごす時間を大切にされよ。",             // family
        "運命の流れ、汝は今その岐路に立つ。天の意を読み、進む道を定めるがよい。",       // destiny
    ]

    // 3 スコア帯（晴明）
    private let seimeiCloseLines: [String] = [
        "慎みを持って歩まれよ。地道な積み重ねが未来の礎となるなり。",          // low
        "天の気は中庸なり。丁寧な行いが良き縁を呼び込むであろう。",            // middle
        "吉気満ちる時なり。大きな一歩を踏み出す勇気、今まさに必要なり。",      // high
    ]

    // MARK: - 南北テンプレート（江戸口語）

    // 12 式神 × 2 日替わりバリアント
    private let nanbokuOpeners: [[String]] = [
        // 0: 貴人（土・吉）
        ["貴人の相が出ておるぞ。身を正し礼を尽くせば、助けが寄ってくるじゃ。",
         "高き縁の気じゃ。謙虚な振る舞いが、良い人を引き寄せるであろう。"],
        // 1: 騰蛇（火・凶）
        ["騰蛇の相、心が先走っておるぞ。一息ついて落ち着くがよい。",
         "変化の気じゃ。今は動きすぎず、様子を見るが賢明じゃろう。"],
        // 2: 朱雀（火・中）
        ["朱雀の相、言葉に気をつけよ。一言の丁寧さが縁を作るぞ。",
         "言葉の力が宿る時じゃ。書き物や話し合いに吉が見えるぞ。"],
        // 3: 六合（木・吉）
        ["六合の相、人との和合が鍵じゃ。約束を守り誠実に接すれば道が開けるぞ。",
         "縁を結ぶ気じゃ。人の話に耳を傾ければ、思わぬ縁が生まれるであろう。"],
        // 4: 勾陳（土・凶）
        ["勾陳の相、急ぐと損をするぞ。今は腰を据えて取り組む時じゃ。",
         "地に足をつける気じゃ。焦らず一つ一つ片付けていくがよい。"],
        // 5: 青龍（木・吉）
        ["青龍の相、伸びる気配があるぞ。欲を張り過ぎずに進めば財も縁も育つじゃ。",
         "吉の気が来ておるぞ。節して余りを作れば、運はさらに広がるであろう。"],
        // 6: 天空（土・中）
        ["天空の相、迷いが多い時じゃ。あれこれ考えすぎず、目の前のことをせよ。",
         "霧の中にある気じゃ。静かに待てば答えは自ずと見えてくるであろう。"],
        // 7: 白虎（金・凶）
        ["白虎の相、強く出すぎると傷を招くぞ。今は控えめに動くがよい。",
         "変動の気じゃ。慎重に一歩ずつ進めば、嵐も過ぎ去るであろう。"],
        // 8: 太常（土・吉）
        ["太常の相、積み重ねに吉があるぞ。日々の暮らしを整えれば運は太るじゃ。",
         "安定の気じゃ。いつも通りの丁寧な暮らしが、福を引き寄せるであろう。"],
        // 9: 玄武（水・凶）
        ["玄武の相、隠れた問題があるぞ。腹を満たしすぎず静かに観察せよ。",
         "水の気じゃ。今は深追いせず、流れに任せて観るがよかろう。"],
        // 10: 太陰（金・中）
        ["太陰の相、陰で整える時じゃ。目立たず内側から力をつけるがよい。",
         "陰の力が宿る気じゃ。月の満ちるように、運は静かに育っておるぞ。"],
        // 11: 天后（水・吉）
        ["天后の相、情に厚い運じゃ。世話好きを活かしつつ、己も大切にせよ。",
         "慈愛の気じゃ。周りを助ける心が、やがて己に返ってくるであろう。"],
    ]

    // 6 悩みカテゴリ（南北）
    private let nanbokuTopicLines: [String] = [
        "恋の縁は食と礼に現れるものじゃ。腹八分で心に余裕を作れ。",                   // love
        "仕事の運は焦らぬ者につくぞ。今日の丁寧な一仕事が、明日の信頼を作るじゃ。", // work
        "金の出入りを正せ。散財を戒め、節して蓄えれば財運は回ってくるぞ。",           // money
        "体の相を読めば、食と睡眠が鍵じゃ。腹八分にして早寝早起きを心がけよ。",     // health
        "家の和は食卓から生まれるものじゃ。共に食べることが絆を深めるぞ。",           // family
        "運命は食と行いの積み重ねじゃ。日々を丁寧に生きる者に天は道を開くぞ。",     // destiny
    ]

    // 3 スコア帯（南北）
    private let nanbokuCloseLines: [String] = [
        "今は力を蓄える時じゃ。慎みを忘れず暮らしを整えれば運は必ず回ってくるぞ。", // low
        "運は中程じゃ。欲を出しすぎず今の暮らしを丁寧に続けることが肝心じゃ。",     // middle
        "良い気が満ちておるぞ。この勢いを節して活かせば願いの多くは叶うであろう。", // high
    ]
}
