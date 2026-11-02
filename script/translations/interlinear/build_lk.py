# Собирает итоговый bib-interliner-lk.rb: исходник + исправление 2:44-45 + главы из lk/lkNN.txt
import sys,os,re,glob
sys.path.insert(0,os.path.dirname(__file__)); from conv import conv,lines
src,dst=sys.argv[1],sys.argv[2]; d=os.path.join(os.path.dirname(__file__),'lk')
L=open(src,encoding='utf-8').read().split('\n')
# Лк 2:44 — запись "γνωστοῖς" оборвана
bad='"jp":"知人の中"},"},'
assert L[35].endswith(bad)
L[35]=L[35][:-len(bad)]+'"jp":"知人の中"},"i":{"ch-r":"прил.","pd":"Дат. п.","ch":"мн. ч.","r":"м."},"zv":"gnōstois"},'
# Лк 2:44 — пропущено δὲ после νομίσαντες
de='{"w":"δὲ","l":"δέ","tr":{"ru":"же","en":"but","jp":"しかし"},"i":{"ch-r":"част."},"zv":"de"},'
k=L[35].index('{"w":"νομίσαντες"'); k=L[35].index('{"w":"αὐτὸν"',k)
L[35]=L[35][:k]+de+L[35][k:]
L.insert(36,lines(conv(open(f'{d}/lk2_45.txt',encoding='utf-8').read()))[0])
for f in sorted(glob.glob(f'{d}/lk[0-9][0-9].txt')):
    ch=int(re.search(r'lk(\d+)',f).group(1))
    s=L.index(f'# Lk ch{ch}'); assert L[s+1]=='json = ['
    e=s+2
    while not L[e].startswith(']; nil'): e+=1
    assert all(not x.strip() for x in L[s+2:e]), f'ch{ch} not empty'
    L[s+2:e]=lines(conv(open(f,encoding='utf-8').read()))
open(dst,'w',encoding='utf-8').write('\n'.join(L))
