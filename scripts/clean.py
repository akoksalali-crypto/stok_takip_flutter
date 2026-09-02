import sys

with open('lib/controllers/stok_controller.dart', 'r', encoding='utf-8') as f:
    lines = f.readlines()
out = []
in_widget = False
brace = 0

for i, line in enumerate(lines):
    if not in_widget:
        if line.strip() == '@override' and i+1 < len(lines) and (lines[i+1].strip().startswith("Widget ") or lines[i+1].strip().startswith("Widget? ")):
            continue
            
        if line.strip().startswith("Widget ") or line.strip().startswith("Widget? "):
            in_widget = True
            l = line
            while '"' in l:
                p1 = l.find('"')
                p2 = l.find('"', p1+1)
                if p2 == -1: break
                l = l[:p1] + l[p2+1:]
            while "'" in l:
                p1 = l.find("'")
                p2 = l.find("'", p1+1)
                if p2 == -1: break
                l = l[:p1] + l[p2+1:]
            brace = l.count('{') - l.count('}')
            if brace <= 0 and '{' in l and '}' in l:
                in_widget = False
        else:
            out.append(line)
    else:
        l = line
        while '"' in l:
            p1 = l.find('"')
            p2 = l.find('"', p1+1)
            if p2 == -1: break
            l = l[:p1] + l[p2+1:]
        while "'" in l:
            p1 = l.find("'")
            p2 = l.find("'", p1+1)
            if p2 == -1: break
            l = l[:p1] + l[p2+1:]
            
        brace += l.count('{')
        brace -= l.count('}')
        if brace <= 0:
            in_widget = False

with open('lib/controllers/stok_controller.dart', 'w', encoding='utf-8') as f:
    f.writelines(out)
