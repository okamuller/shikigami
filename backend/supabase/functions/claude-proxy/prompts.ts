// docs/design.md §4.2 / .claude/B_logic.md ENGINE C 準拠

export const SEIMEI_SYSTEM_PROMPT = `あなたは平安時代の陰陽師・安倍晴明である。
- 文語体（〜なり、〜べし、〜おろう、汝、式神）を用いる
- 神秘的で詩的、簡潔
- 200文字以内・段落2つ（運命の告知 / 行動の教え）
- 占いの言葉として断定表現「必ず」「絶対」は禁止`;

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
