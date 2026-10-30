"""Deterministic original synthesized combat Foley, no third-party recordings."""
from pathlib import Path
import wave
import numpy as np
from scipy.signal import butter,sosfilt
OUT=Path(__file__).resolve().parent.parent/'assets/v29/audio'
FS=44100
rng=np.random.default_rng(2905)
def noise(n,low,high):
 return sosfilt(butter(2,[low,high],btype='bandpass',fs=FS,output='sos'),rng.normal(0,1,n))
def save(name,duration,kind):
 t=np.arange(int(FS*duration))/FS;n=len(t)
 if kind in ('dash','slash'):
  if kind=='dash':
   env=(1-np.exp(-t/.035))*np.exp(-t/.105)
   x=noise(n,85,1050)*env*1.6+noise(n,330,1600)*np.sin(np.pi*t/duration)**2*.22
   x+=.19*np.sin(2*np.pi*(115*t-45*t*t))*env
   cutoff=1850
  else:
   env=(1-np.exp(-t/.008))*np.exp(-t/.037)
   x=noise(n,190,1850)*env*1.15+noise(n,110,470)*np.exp(-((t-.028)/.022)**2)*.85
   x+=noise(n,520,2300)*np.exp(-((t-.049)/.019)**2)*.24
   cutoff=2600
  x=sosfilt(butter(4,cutoff,fs=FS,output='sos'),x)
 elif kind=='double':
  env=np.sin(np.pi*t/duration)**1.1
  x=noise(n,65,1050)*env+.28*np.sin(2*np.pi*(105*t-28*t*t))*env
  x=sosfilt(butter(4,1800,fs=FS,output='sos'),x)
 else:
  decay=6 if kind=='blast' else 12
  x=noise(n,35,{'blast':2300,'slam':4600}[kind])*np.exp(-t*decay)
  x+=.8*np.sin(2*np.pi*(85*t-25*t*t))*np.exp(-t*8)
  x+=noise(n,1200,15000)*np.exp(-t*60)*.55
  if kind=='slam':x+=noise(n,150,1300)*np.exp(-((t-.08)/.035)**2)*.4
 x*=np.minimum(t/.006,1)*np.minimum((duration-t)/.025,1)
 x=x/(np.max(np.abs(x))+1e-9)*(.66 if kind=='slash' else .70 if kind=='dash' else .82)
 with wave.open(str(OUT/(name+'.wav')),'wb') as f:
  f.setnchannels(1);f.setsampwidth(2);f.setframerate(FS);f.writeframes((x*32767).astype('<i2').tobytes())
for name,duration,kind in [('explosion',.85,'blast'),('ground_slam',.55,'slam'),('dash_wind',.32,'dash'),('double_dash_wind',.42,'double'),('attack_whoosh',.19,'slash')]:save(name,duration,kind)
print('Generated five original 44.1kHz PCM Foley effects')
