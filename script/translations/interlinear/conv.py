# Компактный формат -> JSON-строки для InterlinerCreator.
# Строка слова: w|l|ru|en|jp|ч.р.|пад|род|число|время|zv
#   пад: И Р Д В Зв ; род: м ж ср ; число: е м ; пустое поле = пропуск
# "## N" — начало стиха N (для одного стиха — одна json-строка)
import json,sys,re
PD={'И':'Им. п.','Р':'Род. п.','Д':'Дат. п.','В':'Вин. п.','Зв':'Зв. п.'}
R={'м':'м.','ж':'ж.','ср':'ср.'}
CH={'е':'ед. ч.','м':'мн. ч.'}
def conv(text):
    verses=[]; cur=None
    for raw in text.split('\n'):
        s=raw.strip()
        if not s or s.startswith('#!'): continue
        if s.startswith('##'):
            cur=[]; verses.append((int(s[2:].strip()),cur)); continue
        f=s.split('|')
        assert len(f)==11,(len(f),s)
        w,l,ru,en,jp,pos,pd,r,ch,t,zv=[x.strip() for x in f]
        i={'ch-r':pos}
        if pd: i['pd']=PD[pd]
        if r: i['r']=R[r]
        if ch: i['ch']=CH[ch]
        if t: i['t']=t
        cur.append({'w':w,'l':l,'tr':{'ru':ru,'en':en,'jp':jp},'i':i,'zv':zv})
    return verses
def lines(verses):
    return ['  '+json.dumps(ws,ensure_ascii=False,separators=(',',':'))[1:-1]+',' for _,ws in verses]
if __name__=='__main__':
    for l in lines(conv(open(sys.argv[1],encoding='utf-8').read())): print(l)
