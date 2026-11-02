import json,sys,re
L=open(sys.argv[1],encoding='utf-8').read().split('\n')
ch=None; bad={}
for n,l in enumerate(L,1):
    m=re.match(r'# \w+ ch(\d+)',l)
    if m: ch=m.group(1)
    s=l.strip()
    if not s.startswith('{'): continue
    try: a=json.loads('['+s.rstrip(',')+']')
    except Exception as e: print('PARSE',n,e); continue
    for x in a:
        tr=x.get('tr') or {}
        miss=[k for k in ('ru','en','jp') if not str(tr.get(k,'')).strip()]
        if miss or not x.get('l') or not x.get('zv'):
            bad.setdefault((ch,n),[]).append(x['w']+':'+','.join(miss))
for k,v in bad.items(): print('ch',k[0],'line',k[1],len(v),v[:8])
