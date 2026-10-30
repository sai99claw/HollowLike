"""Original deterministic warm combat Foley; no sampled recordings or speech."""
from pathlib import Path
import json
import wave
import numpy as np
from scipy.signal import butter, sosfilt
ROOT=Path(__file__).resolve().parent.parent
OUT=ROOT/'assets/v30/audio'
FS=44100

def filtered_noise(rng,count,low,high):
    return sosfilt(butter(3,[low,high],btype='bandpass',fs=FS,output='sos'),rng.standard_normal(count))

def render(name,duration,seed):
    rng=np.random.default_rng(seed)
    t=np.arange(round(FS*duration))/FS
    n=len(t)
    if name=='charge_build':
        progress=t/duration
        envelope=np.sin(np.pi*progress*.72)**1.2
        air=filtered_noise(rng,n,110,1250)
        texture=filtered_noise(rng,n,400,2100)
        modulation=.75+.25*np.sin(2*np.pi*(5*t+5*t*t))
        x=(.90*air+.18*texture)*envelope*modulation
        x+=.10*np.sin(2*np.pi*(80*t+20*t*t))*envelope
        x*=np.minimum(1,(duration-t)/.065)
        cutoff=2400
    elif name=='charge_release':
        envelope=(1-np.exp(-t/.009))*np.exp(-t/.102)
        body=filtered_noise(rng,n,65,1100)
        edge=filtered_noise(rng,n,300,2300)*np.exp(-((t-.045)/.038)**2)
        tail=filtered_noise(rng,n,100,650)*np.exp(-((t-.15)/.10)**2)
        x=1.2*body*envelope+.30*edge+.24*tail
        x+=.23*np.sin(2*np.pi*(125*t-55*t*t))*envelope
        cutoff=2550
    elif name=='impact_hit':
        envelope=(1-np.exp(-t/.0025))*np.exp(-t/.019)
        contact=filtered_noise(rng,n,350,2400)
        body=filtered_noise(rng,n,90,550)
        x=(.85*contact+.9*body)*envelope
        x+=.22*np.sin(2*np.pi*(185*t-140*t*t))*np.exp(-t/.026)
        cutoff=2900
    else:
        envelope=(1-np.exp(-t/.003))*np.exp(-t/.038)
        contact=filtered_noise(rng,n,220,2100)
        body=filtered_noise(rng,n,50,700)
        x=.85*contact*envelope+.9*body*np.exp(-t/.071)
        x+=.38*np.sin(2*np.pi*(105*t-46*t*t))*np.exp(-t/.065)
        x+=.12*filtered_noise(rng,n,100,450)*np.exp(-((t-.07)/.045)**2)
        cutoff=2500
    x=sosfilt(butter(5,cutoff,fs=FS,output='sos'),x)
    x-=np.mean(x)
    x*=np.clip(t/.004,0,1)*np.clip((duration-t)/.004,0,1)
    x[0]=0
    x[-1]=0
    x*=.72/(np.max(np.abs(x))+1e-12)
    pcm=np.round(x*32767).astype('<i2')
    path=OUT/(name+'.wav')
    with wave.open(str(path),'wb') as stream:
        stream.setnchannels(1);stream.setsampwidth(2);stream.setframerate(FS);stream.writeframes(pcm.tobytes())
    spectrum=abs(np.fft.rfft(x))**2
    frequency=np.fft.rfftfreq(n,1/FS)
    high_ratio=float(spectrum[frequency>5000].sum()/spectrum.sum())
    centroid=float((frequency*spectrum).sum()/spectrum.sum())
    with wave.open(str(path),'rb') as stream:
        assert stream.getframerate()==FS and stream.getnchannels()==1 and stream.getsampwidth()==2
        recovered=np.frombuffer(stream.readframes(stream.getnframes()),dtype='<i2')/32768
        assert len(recovered)==n and max(abs(recovered))<=.75
        assert recovered[0]==0 and recovered[-1]==0
    assert high_ratio<.01
    return {'file':path.name,'duration_seconds':duration,'sample_rate':FS,'peak':round(float(max(abs(recovered))),5),'power_centroid_hz':round(centroid,1),'power_above_5khz_percent':round(high_ratio*100,5),'seed':seed}

if __name__=='__main__':
    OUT.mkdir(parents=True,exist_ok=True)
    report=[render(*spec) for spec in [('charge_build',.78,3001),('charge_release',.48,3002),('impact_hit',.16,3003),('impact_heavy',.32,3004)]]
    (OUT/'audio-validation.json').write_text(json.dumps(report,indent=2)+'\n')
    print(json.dumps(report,indent=2))
