"""Make short original ritual, excavation, and footfall sounds for the intro."""
from pathlib import Path
from array import array
from math import sin, pi, exp
from random import Random
import wave

out = Path(__file__).resolve().parents[4] / 'assets/game/introduction'
rate = 22050
for kind, duration in [('veil',2.65),('earth',3.1),('step',.20)]:
    samples = array('h')
    rng = Random(75)
    rumble = 0
    for i in range(round(duration*rate)):
        t = i/rate
        rumble += .075*(rng.uniform(-1,1)-rumble)
        if kind == 'veil':
            env = sin(pi*t/duration)**2
            sound = env*(.15*sin(2*pi*(63*t+7*t*t))+.06*sin(2*pi*131*t)+rumble*.7)
        elif kind == 'earth':
            env = sin(pi*t/duration)**.6
            sound = env*(rumble*1.2+.095*sin(2*pi*49*t))*(.68+.32*sin(2*pi*2.1*t))
        else:
            env = min(1,t/.011)*exp(-t*24)*min(1,(duration-t)/.02)
            sound = env*(.25*sin(2*pi*(98*t-90*t*t))+rumble*.85)
        samples.append(round(sound*32767))
    with wave.open(str(out / (kind+'.wav')), 'wb') as wav:
        wav.setparams((1,2,rate,0,'NONE','not compressed'))
        wav.writeframes(samples.tobytes())
