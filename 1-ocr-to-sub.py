import os
from pathlib import Path
import cv2
import easyocr
import Levenshtein

def format(msec):
    ss, ms = divmod(msec, 1000)
    mm, ss = divmod(ss, 60)
    hh, mm= divmod(mm, 60)
    return f"{hh:02.0f}:{mm:02.0f}:{ss:02.0f},{ms:03.0f}"

def mean(lst): 
    if (len(lst) >= 1):
        return sum(lst) / len(lst)
    else:
        return -1

def distance(s1,s2): 
    len0 = len(s1)+len(s2)
    if (len0 == 0):
        return -1
    else:
        return Levenshtein.distance(s1,s2)/len0

reader = easyocr.Reader(['ja'])
path = list(Path('.').glob('1/*'))[0]
video = cv2.VideoCapture(str(path))
f = open(f"3/{path.stem}.srt", "w", encoding="utf-8")
i = 0
text={'t':'1-ocr-to-sub.py','begin':0,'conf':-1}
last_rt = 0

while True:
    ret, frame = video.read()
    if not ret: 
        break

    rt = video.get(cv2.CAP_PROP_POS_MSEC)
    if (rt - last_rt < 100):
        continue
    last_rt = rt

    h, w, _ = frame.shape
    result = reader.readtext(frame[round(h*0.8):, :],paragraph=False,detail=1)
    text_good = ''
    text_bad = ''
    conf_good = []
    conf_bad = []
    for _,t,conf in result:
        if (conf > 0.01):
            text_good += t
            conf_good += [conf]
        else:
            text_bad += t
            conf_bad += [conf]
    conf_good = mean(conf_good)

    new_str_dis = distance(text_good,text['t'])
    if (new_str_dis > 0.3):
        i += 1
        f.write(
                f"{i}\n"
                f"{format(text['begin'])} --> {format(rt-24)}\n"
                f"{text['t']}\n\n"
        )#ignore last frame
        text['begin'] = rt
        print("----- to sub -----")

    print(f"{rt/1000:.3f}", f"{new_str_dis:.2f}", text_good, " | ", f"{conf_good:.2f}", " | ", text_bad, " | ", f"{mean(conf_bad):.2f}")    

    if (new_str_dis > 0.3 or conf_good > text['conf']):    
        text['t'] = text_good
        text['conf'] = conf_good

f.close()
    