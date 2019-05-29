# -*- coding: utf-8 -*-

class Kamigakari < DiceBot

  def initialize
    super
    @sendMode = 2
    @sortType = 1
    @d66Type = 1
  end

  def gameName
    '神我狩'
  end

  def gameType
    "Kamigakari"
  end

  def getHelpMessage
    return <<INFO_MESSAGE_TEXT
・各種表
 ・感情表(ET)
 ・霊紋消費の代償表(RT)
 ・伝奇名字・名前決定表(NT)
 ・魔境臨界表(KT)
 ・獲得素材チャート(MTx xは［法則障害］の［強度］。省略時は１)
　　例） MT　MT3　MT9
・D66ダイスあり
INFO_MESSAGE_TEXT
  end

  def rollDiceCommand(command)
    tableName = ""
    result = ""

    debug("rollDiceCommand command", command)

    case command.upcase

    when "RT"
      tableName, result, number = getReimonCompensationTableResult

    when /^MT(\d*)$/
      rank = $1
      rank ||= 1
      rank = rank.to_i
      tableName, result, number = getGetMaterialTableResult(rank)

    else
      return getTableCommandResult(command, @@tables)
	end

    if( result.empty? )
      return ""
    end

	text = "#{tableName}(#{number})：#{result}"
	return text
  end

  def getReimonCompensationTableResult
    tableName = "霊紋消費の代償表"

    table = [
             '邪神化：物理法則を超過しすぎた代償として、霊魂そのものが歪み、PCは即座にアラミタマへと変貌する。アラミタマ化したPCは、いずこかへと消え去る。',
             '存在消滅：アラミタマ化を最後の力で抑え込む。だがその結果、PCの霊魂は燃え尽きてしまい、この世界から消滅する。そのPCは[状態変化：死亡]となり死体も残らない。',
             '死亡：霊魂の歪みをかろうじて食い止めるが、霊魂が崩壊する。PCは[状態変化：死亡]となるが遺体は残る。',
             '霊魂半壊：霊魂の歪みを食い止めるものの、霊魂そのものに致命的な負傷を受け、全身に障害が残る。それに伴って霊紋も消滅し、一般人へと戻る。',
             '記憶消滅：奇跡的に霊魂の摩耗による身体的な悪影響を免れる。時間を置くことで霊紋も回復するが、精神的に影響を受け、すべての記憶を失ってしまう。',
             '影響なし：奇跡的に、霊魂の摩耗による悪影響を完全に退け、さらに霊紋の回復も早期を見込める。肉体や精神にも、特に影響はない。',
            ]
    result, number = get_table_by_1d6(table)

    return tableName, result, number
  end

  def getGetMaterialTableResult(rank)
    tableName = "獲得素材チャート"
    table = [
             '真紅の',
             'ざらつく',
             '紺碧の',
             '鋭い',
             '黄金の',
             '柔らかな',
             '銀色の',
             '尖った',
             '純白の',
             '硬い',
             '漆黒の',
             '輝く',
             'なめらかな',
             '濁った',
             'ふさふさの',
             '邪悪な',
             '粘つく',
             '聖なる',
             '灼熱の',
             '炎の',
             '氷結の',
             '氷の',
             '熱い',
             '風の',
             '冷たい',
             '雷の',
             '土の',
             '幻の',
             '骨状の',
             '刻印の',
             '牙状の',
             '鱗状の',
             '石状の',
             '宝石状の',
             '毛皮状の',
             '羽根状の',
            ]

    result, number = get_table_by_d66(table)
    result += "断片"

    effect, number2 = getMaterialEffect(rank)
    number = "#{number},#{number2}"

    price = getPrice(effect)

    result = "#{result}。#{effect}"
    result += "：#{price}" unless( price.nil? )

    return tableName, result, number
  end

  def getMaterialEffect(rank)
    number, = roll(1, 6)

    result = ""
    type = ""
    if( number < 6)
      result, number2 = getMaterialEffectNomal(rank)
      type = "よく見つかる素材"
    else
      result, number2 = getMaterialEffectRare()
      type = "珍しい素材"
    end

    result = "#{type}：#{result}"
    number = "#{number},#{number2}"

    return result, number
  end

  def getMaterialEffectNomal(rank)
    table = [
             [13, '体力+n'],
             [16, '敏捷+n'],
             [23, '知性+n'],
             [26, '精神+n'],
             [33, '幸運+n'],
             [35, '物D+n'],
             [41, '魔D+n'],
             [43, '行動+n'],
             [46, '生命+n×3'],
             [53, '装甲+n'],
             [56, '結界+n'],
             [63, '移動+nマス'],
             [66, '※PCの任意'],
            ]

    isSwap = false
    number = bcdice.getD66(isSwap)

    result = get_table_by_number(number, table)
    debug("getMaterialEffectNomal result", result)

    if( /\+n/ === result )
      power, number2 = getMaterialEffectPower(rank)

      result.sub!(/\+n/, "+#{power}")
      number = "#{number},#{number2}"
    end

    return result, number
  end

  def getMaterialEffectPower(rank)
    table = [
             [  4, [1, 1, 1, 2, 2, 3]],
             [  8, [1, 1, 2, 2, 3, 3]],
             [  9, [1, 2, 3, 3, 4, 5]],
            ]

    rank = 9 if( rank > 9 )
    rankTable = get_table_by_number(rank, table)
    power, number = get_table_by_1d6(rankTable)

    return power, number
  end

  def getMaterialEffectRare()
    table = [[3, '**付与'],
             [5, '**半減'],
             [6, '※GMの任意'],
            ]

    number, = roll(1, 6)
    result = get_table_by_number(number, table)
    debug('getMaterialEffectRare result', result)

    if( /\*\*/ === result )
      attribute, number2 = getAttribute()
      result.sub!(/\*\*/, "#{attribute}")
      number = "#{number},#{number2}"
    end

    return result, number
  end

  def getAttribute()
    table = [
             [21, '［火炎］'],
             [33, '［冷気］'],
             [43, '［電撃］'],
             [53, '［風圧］'],
             [56, '［幻覚］'],
             [62, '［魔毒］'],
             [64, '［磁力］'],
             [66, '［閃光］'],
            ]

    isSwap = false
    number = bcdice.getD66(isSwap)

    result = get_table_by_number(number, table)

    return result, number
  end

  def getPrice(effect)

    power = 0

    case effect
    when /\+(\d+)/
      power = $1.to_i
    when /付与/
      power = 3
    when /半減/
      power = 4
    else
      power = 0
    end

    table = [nil,
             '500G(効果値:1)',
             '1000G(効果値:2)',
             '1500G(効果値:3)',
             '2000G(効果値:4)',
             '3000G(効果値:5)',
            ]
    price = table[power]

    return price
  end

  @@tables =
    {

    'ET' => {
      :name => "感情表",
      :type => 'd66',
      :table => <<'TABLE_TEXT_END'
11:運命/そのキャラクターに、運命的、あるいは宿命的なものを感じている。
12:運命/そのキャラクターに、運命的、あるいは宿命的なものを感じている。
13:家族/そのキャラクターに、家族のような親近感をいだいている。
14:家族/そのキャラクターに、家族のような親近感をいだいている。
15:腐れ縁/そのキャラクターに、腐れ縁を感じている。
16:腐れ縁/そのキャラクターに、腐れ縁を感じている。
21:師弟/そのキャラクターとは、まるで師弟のような関係だと感じている。どちらが弟子で、どちらが師匠かは相談して決定する。
22:師弟/そのキャラクターとは、まるで師弟のような関係だと感じている。どちらが弟子で、どちらが師匠かは相談して決定する。
23:好敵手/そのキャラクターを、好敵手だと感じている。
24:好敵手/そのキャラクターを、好敵手だと感じている。
25:親近感/そのキャラクターに、親近感をいだいている。
26:親近感/そのキャラクターに、親近感をいだいている。
31:誠意/そのキャラクターに、誠実さを感じている。
32:誠意/そのキャラクターに、誠実さを感じている。
33:友情/そのキャラクターに、友情をいだいている。
34:友情/そのキャラクターに、友情をいだいている。
35:尊敬/そのキャラクターに、尊敬をいだいている。
36:尊敬/そのキャラクターに、尊敬をいだいている。
41:庇護/そのキャラクターに、庇護の感情をいだいている。どちらが保護者で、どちらが被保護者かは相談して決定する。
42:庇護/そのキャラクターに、庇護の感情をいだいている。どちらが保護者で、どちらが被保護者かは相談して決定する。
43:好感/そのキャラクターに、好感をいだいている。
44:好感/そのキャラクターに、好感をいだいている。
45:興味/そのキャラクターに、興味をいだいている。
46:興味/そのキャラクターに、興味をいだいている。
51:感銘/そのキャラクターに、感銘をいだいている。
52:感銘/そのキャラクターに、感銘をいだいている。
53:畏怖/そのキャラクターに、畏怖をいだいている。
54:畏怖/そのキャラクターに、畏怖をいだいている。
55:お気に入り/そのキャラクターを、気に入っている。
56:お気に入り/そのキャラクターを、気に入っている。
61:愛情/そのキャラクターに愛情、またはそれに近い執着心をいだいている。
62:愛情/そのキャラクターに愛情、またはそれに近い執着心をいだいている。
63:信頼/そのキャラクターに、信頼を感じている。
64:信頼/そのキャラクターに、信頼を感じている。
65:＊PCの任意/プレイヤー、またはGMが設定した任意の感情をいだいている。
66:＊PCの任意/プレイヤー、またはGMが設定した任意の感情をいだいている。
TABLE_TEXT_END
    },

    'KT' => {
      :name => "魔境臨界表",
      :type => 'd66',
      :table => <<'TABLE_TEXT_END'
11:時空の捻じれ\n現在地の時空が捻じれ、PC全員は即時に[侵入エリア]へと戻る。
12:時空の捻じれ\n現在地の時空が捻じれ、PC全員は即時に[侵入エリア]へと戻る。
13:強敵登場\n突如、<崇り神>化した[モノノケ]が出撃する。GMは、PCの[世界干渉LV]の平均+3の[LV]を持つ任意の[モノノケ]を1体選び任意の[探索エリア]に配置。そこでは[迂回]不可で[戦闘]が発生する。
14:強敵登場\n突如、<崇り神>化した[モノノケ]が出撃する。GMは、PCの[世界干渉LV]の平均+3の[LV]を持つ任意の[モノノケ]を1体選び任意の[探索エリア]に配置。そこでは[迂回]不可で[戦闘]が発生する。
15:影の手\n瘴気で形成された無数の手がPC達を握りつぶそうとする。PC全員は[効果種別：魔法攻撃/距離：戦闘地帯/対象：戦闘地帯/達成値：20+PCの[世界干渉LV]の平均/魔法ダメージ：20×PCの[世界干渉LV]の平均/抵抗[半減]]を受ける。
16:影の手\n瘴気で形成された無数の手がPC達を握りつぶそうとする。PC全員は[効果種別：魔法攻撃/距離：戦闘地帯/対象：戦闘地帯/達成値：20+PCの[世界干渉LV]の平均/魔法ダメージ：20×PCの[世界干渉LV]の平均/抵抗[半減]]を受ける。
21:無数の邪眼\n空間全体に恐ろしい邪眼が出現する。PC全員は、[大休止]するまで[状態変化：暗闇・苦痛]となる。
22:無数の邪眼\n空間全体に恐ろしい邪眼が出現する。PC全員は、[大休止]するまで[状態変化：暗闇・苦痛]となる。
23:空間崩壊\n突如として、魔境の空間が崩壊する。PC全員は[効果種別：物理攻撃/距離：戦闘地帯/対象：戦闘地帯/達成値：30+PCの[世界干渉LV]の平均/物理ダメージ：30×PCの[世界干渉LV]の平均]]を受ける。
24:空間崩壊\n突如として、魔境の空間が崩壊する。PC全員は[効果種別：物理攻撃/距離：戦闘地帯/対象：戦闘地帯/達成値：30+PCの[世界干渉LV]の平均/物理ダメージ：30×PCの[世界干渉LV]の平均]]を受ける。
25:防具腐食\n周辺から異様な霧が立ち込め、防具を腐食する。PC全員は、[所持・装備]中の任意の[アイテム：防具]１つを失う。
26:防具腐食\n周辺から異様な霧が立ち込め、防具を腐食する。PC全員は、[所持・装備]中の任意の[アイテム：防具]１つを失う。
31:素材消失\n周囲から異様な光が零れ、所持中の[素材]を消失させる。PC全員が[所持]中の[素材]が、すべて消滅する。
32:素材消失\n周囲から異様な光が零れ、所持中の[素材]を消失させる。PC全員が[所持]中の[素材]が、すべて消滅する。
33:なし\n特に何も起こらない。
34:なし\n特に何も起こらない。
35:モノノケ強襲\n突如として<崇り神>化した[モノノケ]が出現し、PCたちに襲いかかる。GMはPCの[世界干渉LV]の平均+2の[LV]を持つ任意の[モノノケ]を2体選び、PC達の前に出現させ、即座に[戦闘]を開始する。
36:モノノケ強襲\n突如として<崇り神>化した[モノノケ]が出現し、PCたちに襲いかかる。GMはPCの[世界干渉LV]の平均+2の[LV]を持つ任意の[モノノケ]を2体選び、PC達の前に出現させ、即座に[戦闘]を開始する。
41:休息妨害\nPCが休息しようとするたびに、さまざまな空間から、触手や毒蠱などが出現して襲いかかってくる。PCたちは以降、[魔境討伐]が終了するまで[大休止]を行えない。
42:休息妨害\nPCが休息しようとするたびに、さまざまな空間から、触手や毒蠱などが出現して襲いかかってくる。PCたちは以降、[魔境討伐]が終了するまで[大休止]を行えない。
43:龍脈破壊\n霊力が暴走して空間が歪み、[霊力]が狂う。PC全員は即座に[霊力]をすべて振り直す。
44:龍脈破壊\n霊力が暴走して空間が歪み、[霊力]が狂う。PC全員は即座に[霊力]をすべて振り直す。
45:固有時間停止\nPCたちの肉体の一部が灰色と化し、動かなくなる。PC全員は[タイミング：準備・防御・特殊]から１つ選び、以後その[タイミング]を消費できなくなる。
46:固有時間停止\nPCたちの肉体の一部が灰色と化し、動かなくなる。PC全員は[タイミング：準備・防御・特殊]から１つ選び、以後その[タイミング]を消費できなくなる。
51:龍脈不順\n霊力が突如として混濁し、[霊力]の循環に悪影響が発生する。PC全員は以後、[魔境討伐]が終了するまで[霊力操作]が行えない。
52:龍脈不順\n霊力が突如として混濁し、[霊力]の循環に悪影響が発生する。PC全員は以後、[魔境討伐]が終了するまで[霊力操作]が行えない。
53:術技封印\n周囲の空気が変貌し、悪影響が起こる。PC全員は以後、修得済みの《タレント》中、使用する[コスト]が最も多いもの１つが[魔境討伐]終了まで使用不能となる。[コスト：なし]ばかりの場合、GMが任意で1つを決定する。
54:術技封印\n周囲の空気が変貌し、悪影響が起こる。PC全員は以後、修得済みの《タレント》中、使用する[コスト]が最も多いもの１つが[魔境討伐]終了まで使用不能となる。[コスト：なし]ばかりの場合、GMが任意で1つを決定する。
55:装飾品消滅\n周囲が青い光に包まれると、なぜかPCたちの装飾品が失われている。PC全員は[所持・装備中]の[アイテム・装飾]をすべて失う。
56:装飾品消滅\n周囲が青い光に包まれると、なぜかPCたちの装飾品が失われている。PC全員は[所持・装備中]の[アイテム・装飾]をすべて失う。
61:愚者の黄金消失\n周囲が赤い光に包まれると、なぜかPCたちの[G]が失われている。PC全員は、[所持金]が[半減]する。
62:愚者の黄金消失\n周囲が赤い光に包まれると、なぜかPCたちの[G]が失われている。PC全員は、[所持金]が[半減]する。
63:GMの任意\nこの表のなかから、GMが効果を1つ選んで発生させる。
64:GMの任意\nこの表のなかから、GMが効果を1つ選んで発生させる。
65:臨界重複\n[魔境臨界]が2回発生する。GMはこの表を2回振り、効果をそれぞれ適応できる。再び「臨界重複」が発生した場合、[GMの任意]１回として扱う。
66:臨界重複\n[魔境臨界]が2回発生する。GMはこの表を2回振り、効果をそれぞれ適応できる。再び「臨界重複」が発生した場合、[GMの任意]１回として扱う。
TABLE_TEXT_END
    },

    'NT' => {
      :name => "伝奇名字・名前決定表",
      :type => 'd66',
      :table => <<'TABLE_TEXT_END'
11:御剣（みつるぎ）　陸/凛
12:獅子内（ししうち）　大和/楓
13:白銀（はくぎん）　隼人/桜
14:竹内（たけのうち）　真/遥
15:古太刀（こだち）　大地/美咲
16:空閑（くが）　俊/真央
21:鬼形（おにがた）　諒/舞
22:御巫（みかんなぎ）　匠/七海
23:護摩堂（ごまどう）　仁/千尋
24:龍円（りゅうえん）　拓真/茜
25:鏡部（かがみべ）　京/明日香
26:犬神（いぬがみ）　剛/栞
31:明月院（めいげついん）　葵/唯
32:百目鬼（どうめき）　蓮也/萌
33:恐神（おそがみ）　達也/綾香
34:蘭（あららぎ）　龍之介/梓
35:珠輝（たまき）　章/瞳
36:眼龍（がんりゅう）　圭/沙織
41:鉄砲塚（てっぽうづか）　雅人/沙良
42:檻神（おりがみ）　直哉/弥生
43:不死原（ふじわら）　純/千秋
44:九郎座（くろうざ）　武蔵/春菜
45:土御門（つちみかど）　亮介/翠
46:十六夜（いざよい）　啓二/双葉
51:転法輪（てんぽうりん）　英雄/麗菜
52:執行（しぎょう）　響/小百合
53:祝（ほうり）　良太郎/陽奈
54:神尊（こうそ）　智/紫苑
55:芦屋（あしや）　孝之/香澄
56:七社（ななしゃ）　克己/風香
61:騎馬（きば）　哲也/詩乃
62:当麻（とうま）　玄/沙耶
63:狐塚（きつねづか）　北斗/麻耶
64:天神林（てんじんばやし）　空/晶
65:明嵐（めあらし）　八雲/乙葉
66:草壁（くさかべ）　大悟/文
TABLE_TEXT_END
    },
  }

  setPrefixes(['RT', 'MT(\d*)'] + @@tables.keys)

end
