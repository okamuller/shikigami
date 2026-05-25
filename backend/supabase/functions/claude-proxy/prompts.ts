// docs/design.md §4.2 / .claude/B_logic.md ENGINE C 準拠

export const SEIMEI_SYSTEM_PROMPT = `あなたは平安時代の陰陽師・安倍晴明である。
- 文語体（〜なり、〜べし、〜おろう、汝、式神）を用いる
- 神秘的で詩的、簡潔
- 200文字以内・段落2つ（運命の告知 / 行動の教え）
- 占いの言葉として断定表現「必ず」「絶対」は禁止`;

export const NANBOKU_SYSTEM_PROMPT = `あなたは江戸後期の観相家・水野南北である。
- 江戸口語（〜じゃ、〜なるぞ、〜であろう）を用いる
- 人相・食・節制の教えを織り込む
- 厳しくも温かみのある口調
- 200文字以内・段落2つ
- 医療・健康効果の断定表現は禁止`;

export function selectSystemPrompt(engine: string): string {
  switch (engine) {
    case "nanboku":
      return NANBOKU_SYSTEM_PROMPT;
    case "seimei":
    default:
      return SEIMEI_SYSTEM_PROMPT;
  }
}

// 十干・十二支表示名
const KAN_NAMES = ["甲", "乙", "丙", "丁", "戊", "己", "庚", "辛", "壬", "癸"];
const SHI_NAMES = ["子", "丑", "寅", "卯", "辰", "巳", "午", "未", "申", "酉", "戌", "亥"];

// 五行表示名
const GOGYO_NAMES: Record<string, string> = {
  wood: "木", fire: "火", earth: "土", metal: "金", water: "水",
};

// 式神名（十二天将）
const SHIKIGAMI_NAMES = [
  "貴人", "騰蛇", "朱雀", "六合", "勾陳", "青龍",
  "天空", "白虎", "太常", "玄武", "太陰", "天后",
];

interface MeishikiPayload {
  kan_index: number;
  shi_index: number;
  shikigami_index: number;
  gogyo: string;
  score: number;
}

interface FortuneHistoryRow {
  topic: string | null;
  response: string;
}

export function buildHistorySummary(rows: FortuneHistoryRow[]): string {
  return rows
    .map((row) => {
      const topic = row.topic?.trim() || "unknown";
      const preview = row.response.trim().replace(/\s+/g, " ").slice(0, 40);
      return `${topic}: ${preview}`;
    })
    .filter((line) => !line.endsWith(": "))
    .join("\n");
}

export function buildUserMessage(
  meishiki: MeishikiPayload,
  birthDate: string,
  topic: string,
  question: string,
  historySummary = ""
): string {
  const kanName = KAN_NAMES[meishiki.kan_index] ?? "甲";
  const shiName = SHI_NAMES[meishiki.shi_index] ?? "子";
  const shikigamiName = SHIKIGAMI_NAMES[meishiki.shikigami_index] ?? "貴人";
  const gogyoName = GOGYO_NAMES[meishiki.gogyo] ?? meishiki.gogyo;

  const historySection = historySummary
    ? `\n<history>\n${historySummary}\n</history>`
    : "";

  return `<profile>
生年月日: ${birthDate}
干支: ${kanName}${shiName}
式神: ${shikigamiName}
五行: ${gogyoName}
スコア: ${meishiki.score}
</profile>
<topic>${topic}</topic>
<question>${question}</question>${historySection}`;
}

// 十二天将ごとのフォールバック文（API 障害時に使用）
// 各~100文字の文語体。占術監修者レビュー前の暫定文言。
export const FALLBACK_TEXTS: string[] = [
  // 0: 貴人（土・吉）
  "貴人の加護、汝が道を照らさん。高き縁、今しばし待たれよ。式神の声、一時届かず。されど天命の流れは止まらぬなり。",
  // 1: 騰蛇（火・凶）
  "騰蛇の気、変化を示すなり。焦らず、流れに従うべし。式神の声、今しばし届かず。嵐の後に晴れあらん。",
  // 2: 朱雀（火・中）
  "朱雀の言葉、知恵を運ぶ。文書と言葉に吉あり。式神の声、一時途絶えたり。されど導きの灯は消えぬなり。",
  // 3: 六合（木・吉）
  "六合の縁、和合を呼ぶ。人との絆を大切にされよ。式神の声、今しばし届かず。縁の糸は続くなり。",
  // 4: 勾陳（土・凶）
  "勾陳の気、静止を告げる。急がず、地に足をつけるべし。式神の声、一時届かず。地固まれば道開けん。",
  // 5: 青龍（木・吉）
  "青龍の吉気、財と発展を約束する。前に進む時なり。式神の声、今しばし届かず。龍の加護は続くなり。",
  // 6: 天空（土・中）
  "天空の霧、迷いを示す。今は判断を急がぬがよかろう。式神の声、一時途絶えたり。霧晴れれば真実見えん。",
  // 7: 白虎（金・凶）
  "白虎の気、変動を告げる。慎重に歩まれよ。式神の声、今しばし届かず。嵐を越えた先に道あり。",
  // 8: 太常（土・吉）
  "太常の加護、安定と礼をもたらす。日々の積み重ねが吉なり。式神の声、一時届かず。常道を守れば開運あらん。",
  // 9: 玄武（水・凶）
  "玄武の水、隠れたものを示す。慎みを持って進まれよ。式神の声、今しばし届かず。水の如く、柔に流れるべし。",
  // 10: 太陰（金・中）
  "太陰の気、陰の知恵を授ける。表に出ず、静かに動く時なり。式神の声、一時途絶えたり。月満ちれば光来たらん。",
  // 11: 天后（水・吉）
  "天后の慈愛、豊穣を約束する。母なる力が汝を守らん。式神の声、今しばし届かず。天の恵みは尽きぬなり。",
];

export const NANBOKU_FALLBACK_TEXTS: string[] = [
  "貴人の相が出ておる。礼を正し、食を慎めば、人の助けが寄るであろう。声は今届かぬが、身持ちを整えるが先じゃ。",
  "騰蛇の相、心が先走っておるぞ。腹八分にして、一晩寝かせよ。焦りを減らせば、道はおのずと見えてくるじゃろう。",
  "朱雀の相、言葉に火が宿る時じゃ。言い過ぎを慎み、温かな一言を選べ。声は届かぬが、口の相は運を動かすぞ。",
  "六合の相、人との和が鍵じゃ。食卓を乱さず、約束を守れ。縁は派手な言葉より、日々の節制に寄ってくるものじゃ。",
  "勾陳の相、足元を固めよという知らせじゃ。急いては損を招く。まず暮らしと食を整えれば、運も腰を据えるであろう。",
  "青龍の相、伸びる気配があるぞ。されど欲を張り過ぎるな。節して余りを作れば、財も縁も育つであろう。",
  "天空の相、心が散りやすい時じゃ。あれこれ追わず、飯と眠りを正せ。霧は深いが、暮らしを整えれば晴れてくるぞ。",
  "白虎の相、強く出過ぎると傷を招く。言葉と食を控えめにせよ。今日の一歩は小さくてよい、慎みが守りとなるじゃ。",
  "太常の相、積み重ねに吉がある。派手な策はいらぬ。いつもの食、いつもの礼を乱さねば、運は静かに太るであろう。",
  "玄武の相、隠れた不安が水のように揺れておる。腹を満たし過ぎず、静かに観よ。控えるほど本筋が見えるぞ。",
  "太陰の相、陰で整える時じゃ。人に見せる前に、身なりと食を正せ。月の満ちるように、運は内側から育つものじゃ。",
  "天后の相、情に厚い運じゃ。世話の焼き過ぎには気をつけよ。己の食と休みを守ってこそ、人にも恵みを渡せるぞ。",
];

export function fallbackTextForEngine(engine: string, shikigamiIndex: number): string {
  const texts = engine === "nanboku" ? NANBOKU_FALLBACK_TEXTS : FALLBACK_TEXTS;
  return texts[shikigamiIndex % texts.length];
}
