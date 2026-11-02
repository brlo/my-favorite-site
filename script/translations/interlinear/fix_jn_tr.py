# Перезапись переводов (ru|en|jp) в строках, где перевод съехал относительно слов
import json,sys
p=sys.argv[1]; L=open(p,encoding='utf-8').read().split('\n')
T={
187:"""что|what|ことを
Я|I|わたしが
видел|have seen|見た
у|with|もとで
-|the|-
Отца|Father|父の
говорю|speak|話す
и|and|そして
вы|you|あなたがたは
итак|therefore|それで
что|what|ことを
слышали|have heard|聞いた
от|from|から
-|the|-
отца|father|父
делаете|do|行っている
ответили|answered|答えた
и|and|そして
сказали|said|言った
Ему|to Him|彼に
-|the|-
отец|father|父は
наш|our|私たちの
Авраам|Abraham|アブラハム
есть|is|である
говорит|says|言う
им|to them|彼らに
-|-|-
Иисус|Jesus|イエスは
если|if|もし
дети|children|子ども
-|-|-
Авраама|of Abraham|アブラハムの
есть|you are|であるなら
-|the|-
дела|works|わざを
-|-|-
Авраама|of Abraham|アブラハムの
делали бы|you would do|行っているはずだ""",
188:"""теперь|now|今
же|but|しかし
ищете|you seek|求めている
Меня|Me|わたしを
убить|to kill|殺そうと
человека|a man|人を
который|who|～者
-|the|-
истину|truth|真理を
вам|to you|あなたがたに
сказал|have spoken|語った
которую|which|それを
Я слышал|I heard|聞いた
от|from|から
-|-|-
Бога|God|神
этого|this|そのようなことを
Авраам|Abraham|アブラハムは
не|not|～なかった
делал|did|した
вы|you|あなたがたは
делаете|do|行っている
-|the|-
дела|works|わざを
-|of the|-
отца|father|父の
вашего|your|あなたがたの
сказали|they said|言った
тогда|then|そこで
Ему|to Him|彼に
мы|we|私たちは
от|of|から
блуда|fornication|不品行
не|not|ない
рождены|were born|生まれたのでは
одного|one|一人の
Отца|Father|父を
имеем|we have|持っている
-|-|-
Бога|God|神という""",
189:"""сказал|said|言った
им|to them|彼らに
-|-|-
Иисус|Jesus|イエスは
если|if|もし
-|-|-
Бог|God|神が
отец|father|父
ваш|your|あなたがたの
был|were|であったなら
любили|would love|愛したであろう
бы|-|-
Меня|Me|わたしを
Я|I|わたしは
ибо|for|なぜなら
от|from|から
-|-|-
Бога|God|神
изошёл|came forth|出て
и|and|そして
пришёл|have come|来た
и не|nor|～でもない
ибо|for|なぜなら
от|of|から
Себя|Myself|自分
пришёл|I have come|来たのでは
но|but|しかし
Он|He|あの方が
Меня|Me|わたしを
послал|sent|遣わした
по|why|なぜ
чему|-|-
-|-|-
речь|speech|話を
-|-|-
Мою|My|わたしの
не|not|ない
понимаете|you understand|理解し
потому что|because|それは
не|not|ない
можете|you are able|でき
слышать|to hear|聞くことが
-|-|-
слово|word|言葉を
-|-|-
Моё|My|わたしの""",
329:"""приходит|comes|来る
итак|then|そこで
к|to|のところに
Симону|Simon|シモン
Петру|Peter|ペトロ
говорит|says|言う
ему|to Him|彼に
Господи|Lord|主よ
Ты|You|あなたが
мои|my|私の
омываешь|wash|洗うのですか
-|the|-
ноги|feet|足を
ответил|answered|答えた
Иисус|Jesus|イエスは
и|and|そして
сказал|said|言った
ему|to him|彼に
что|what|ことを
Я|I|わたしが
делаю|do|している
ты|you|あなたは
не|not|ない
знаешь|know|知ら
теперь|now|今は
узнаешь|will know|知るであろう
же|but|しかし
после|after|後で
этого|these things|このことの
говорит|says|言う
Ему|to Him|彼に
Пётр|Peter|ペトロは
не|not|決して
не|never|ない
омоешь|shall wash|洗わ
мои|my|私の
-|the|-
ноги|feet|足を
во|to|まで
-|the|-
век|age|永遠に
ответил|answered|答えた
Иисус|Jesus|イエスは
ему|him|彼に""",
331:"""говорит|says|言う
ему|to him|彼に
-|-|-
Иисус|Jesus|イエスは
-|the one who|-
омытый|has bathed|体を洗った者は
не|not|ない
имеет|has|ある
нужды|need|必要は
кроме|except|除いて
как|-|-
-|the|-
ноги|feet|足を
омыть|to wash|洗うこと
но|but|しかし
есть|is|である
чист|clean|清い
весь|wholly|全身が
и|and|そして
вы|you|あなたがたは
чисты|clean|清い
есть|are|である
но|but|しかし
не|not|ではない
все|all|皆が
знал|He knew|知っていた
ибо|for|なぜなら
-|the|-
предающего|one betraying|裏切る者を
Его|Him|ご自分を
по|because of|ゆえに
этому|this|この
сказал|He said|言われた
что|that|と
не|not|ではない
все|all|皆が
чисты|clean|清い
есть|are|のである""",
333:"""если|if|もし
итак|then|それで
Я|I|わたしが
омыл|washed|洗ったのなら
ваши|your|あなたがたの
-|the|-
ноги|feet|足を
-|the|-
Господь|Lord|主
и|and|であり
-|the|-
Учитель|Teacher|師である
и|also|も
вы|you|あなたがた
должны|ought|べきである
друг другу|one another's|互いの
омывать|to wash|洗い合う
-|the|-
ноги|feet|足を
пример|an example|模範を
ибо|for|なぜなら
дал|I have given|与えた
вам|to you|あなたがたに
чтобы|so that|ように
как|just as|～のとおりに
Я|I|わたしが
сделал|did|した
вам|to you|あなたがたに
и|also|も
вы|you|あなたがた
делали|may do|行う""",
335:"""не|not|ではない
о|about|について
всех|all|すべて
вас|of you|あなたがた
говорю|I speak|言っている
Я|I|わたしは
знаю|know|知っている
кого|whom|だれを
избрал|I chose|選んだか
но|but|しかし
чтобы|so that|ためである
-|the|-
Писание|Scripture|聖書が
исполнилось|might be fulfilled|成就する
-|the one|-
ядущий|eating|食べる者が
Мой|My|わたしの
-|the|-
хлеб|bread|パンを
поднял|lifted up|上げた
на|against|に対して
Меня|Me|わたし
-|the|-
пяту|heel|かかとを
свою|his|自分の
от|from|から
ныне|now|今
говорю|I tell|言う
вам|you|あなたがたに
прежде|before|前に
-|-|-
свершения|it happens|起こる
чтобы|so that|ために
уверовали|you may believe|信じる
когда|when|時
свершится|it happens|起こった
что|that|ということを
Я|I|わたしが
есть|am|である""",
336:"""истинно|truly|まことに
истинно|truly|まことに
говорю|I say|言う
вам|to you|あなたがたに
-|the one|-
принимающий|receiving|受け入れる者は
-|-|-
кого|whomever|だれでも
пошлю|I send|わたしが遣わす
Меня|Me|わたしを
принимает|receives|受け入れる
-|the one|-
а|and|そして
Меня|Me|わたしを
принимающий|receiving|受け入れる者は
принимает|receives|受け入れる
-|the One|-
Пославшего|having sent|遣わした方を
Меня|Me|わたしを""",
}
for n,txt in T.items():
    a=json.loads('['+L[n-1].strip().rstrip(',')+']')
    if n==331:
        import unicodedata as u; assert [u.normalize('NFC',x['w']) for x in a[24:27]]==[u.normalize('NFC',s) for s in ['πάντες','καθαροί','ἐστε']],[x['w'] for x in a[22:28]]; del a[25:27]
    rows=[r.split('|') for r in txt.strip().split('\n')]
    assert len(rows)==len(a),(n,len(rows),len(a))
    for x,(ru,en,jp) in zip(a,rows):
        x['tr']={'ru':ru,'en':en,'jp':jp}
        x['w']=x['w'].replace('р','ρ')
    L[n-1]='  '+json.dumps(a,ensure_ascii=False,separators=(',',':'))[1:-1]+','
# 14:16-18 — точечно
a=json.loads('['+L[358].strip().rstrip(',')+']')
for x in a:
    if x['w']=='οὐ' and x['tr']['en']=='cannot': x['tr']['en']='not'
    if x['w']=='δύναται': x['tr']['en']='is able'
    if x['w']=='λαβεῖν': x['tr']={'ru':'принять','en':'to receive','jp':'受け入れることが'}
L[358]='  '+json.dumps(a,ensure_ascii=False,separators=(',',':'))[1:-1]+','
open(p,'w',encoding='utf-8').write('\n'.join(L))
