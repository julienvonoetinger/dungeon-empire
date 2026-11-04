"""Render the invocation sound cues to mono PCM. Run from the project root."""
import math
import random
import wave
from array import array

rate = 22050
rng = random.Random(731)
samples = array('h')
low = air = last = 0.

def ramp(t, a, b):
    x = min(1., max(0., (t-a)/(b-a)))
    return x*x*(3-2*x)

def beat(t, start, decay):
    age = t-start
    return (1-math.exp(-age*28))*math.exp(-age/decay) if age > 0 else 0.

for i in range(45*rate):
    t = i/rate
    noise = rng.uniform(-1, 1)
    air += .12*(noise-air)
    low += .012*(air-low)
    wind = (.48*(1-ramp(t, 1., 4.6)) + .85*ramp(t,22,28.3)*(1-ramp(t,28.5,30.1))
            + .20*ramp(t,40,43))*(.78+.22*math.sin(t*2.3))
    rustle = .11*beat(t,1.1,.52) + .09*beat(t,2.3,.31)
    grit = .25*beat(t,6.2,.18) + .16*beat(t,7.6,.13) + .13*beat(t,9.1,.2)
    breath = .66*ramp(t,17.0,17.32)*(1-ramp(t,17.32,17.85))
    pulse = sum(beat(t,x,.68) for x in (10.5,13.2,16.,18.8,21.6,24.4,27.2))
    pact = beat(t,35.25,1.48)
    drone = .10*ramp(t,5.,9.) + .105*ramp(t,19.,28.) - .11*ramp(t,35.5,40.)
    # Low fifth, its octave, and a close beating minor third. Upper voices
    # recede when the viewpoint enters the presence.
    theta = math.tau*t
    music = ramp(t,16.,27.9)*(1-.83*ramp(t,28.6,30.3))
    value = ((air-low)*(wind+breath) + low*wind*1.3 + (noise-last)*(rustle+grit)
             + (drone+.12*pulse+.25*pact)*math.sin(theta*55)
             + (.045*pulse+.11*pact)*math.sin(theta*82.41)
             + music*(.062*math.sin(theta*130.81)+.045*math.sin(theta*164.81)
                      + .03*math.sin(theta*165.43))
             + .08*ramp(t,28.9,30.2)*(1-ramp(t,38.,44.))*math.sin(theta*110.))
    last = noise
    value *= ramp(t,0,.16)*(1-ramp(t,42.8,45.))
    samples.append(round(max(-1.,min(1.,value))*32760))

with wave.open('assets/game/introduction/invocation/score.wav','wb') as out:
    out.setparams((1,2,rate,0,'NONE','not compressed'))
    out.writeframes(samples.tobytes())
