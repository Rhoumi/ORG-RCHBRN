
import("stdfaust.lib");
import("music.lib");

/* Control variables: */

// master volume, pan
vol		= hslider("vol", 0.5, 0, 10, 0.01);		// %
pan		= hslider("pan", 0.5, 0, 1, 0.01);		// %

// excitator and resonator parameters

// excitator decay time [sec]
xdecay		= nentry("decay", 0.01, 0, 1, 0.001);

// resonator #0
hrm0		= nentry("harmonic0", 1, 0, 50, 0.001);		// harmonic
amp0		= nentry("amplitude0", 0.167, 0, 1, 0.001);	// amplitude
decay0		= nentry("decay0", 3.693, 0, 10, 0.001);	// decay time
rq0		= nentry("rq0", 0.002, 0, 1, 0.0001);		// filter 1/Q
// resonator #1
hrm1		= nentry("harmonic1", 3.007, 0, 50, 0.001);	// harmonic
amp1		= nentry("amplitude1", 0.083, 0, 1, 0.001);	// amplitude
decay1		= nentry("decay1", 2.248, 0, 10, 0.001);	// decay time
rq1		= nentry("rq1", 0.002, 0, 1, 0.0001);		// filter 1/Q
// resonator #2
hrm2		= nentry("harmonic2", 4.968, 0, 50, 0.001);	// harmonic
amp2		= nentry("amplitude2", 0.087, 0, 1, 0.001);	// amplitude
decay2		= nentry("decay2", 2.828, 0, 10, 0.001);	// decay time
rq2		= nentry("rq2", 0.002, 0, 1, 0.0001);		// filter 1/Q
// resonator #3
hrm3		= nentry("harmonic3", 8.994, 0, 50, 0.001);	// harmonic
amp3		= nentry("amplitude3", 0.053, 0, 1, 0.001);	// amplitude
decay3		= nentry("decay3", 3.364, 0, 10, 0.001);	// decay time
rq3		= nentry("rq3", 0.002, 0, 1, 0.0001);		// filter 1/Q
// resonator #4
hrm4		= nentry("harmonic4", 12.006, 0, 50, 0.001);	// harmonic
amp4		= nentry("amplitude4", 0.053, 0, 1, 0.001);	// amplitude
decay4		= nentry("decay4", 2.488, 0, 10, 0.001);	// decay time
rq4		= nentry("rq4", 0.002, 0, 1, 0.0001);		// filter 1/Q

// frequency, gain, gate
freq		= nentry("freq", 440, 20, 20000, 1);		// Hz
gain		= nentry("gain", 1, 0, 10, 0.01);		// %
gate		= checkbox("gate");				// 0/1

/* Definition of the resonz filter. This is basically a biquad filter with
   pairs of poles near the desired resonance frequency and zeroes at -1 and
   +1. See Steiglitz for details. */

resonz(R,freq)	= f : (+ ~ g)
with {
	f(x)	= a*(x-x');		// feedforward function (two zeros)
	g(y)	= 2*R*c*y - R*R*y';	// feedback function (two poles)
	w	= 2*PI*freq/SR;		// freq in rad per sample period
	c	= 2*R/(1+R*R)*cos(w);	// cosine of pole angle
	s	= sqrt (1-c*c);		// sine of pole angle
	a	= (1-R*R)*s;		// factor to normalize resonance
};

/* The excitator, a short burst of noise. */

excitator(t)	= t : hgroup("1-excitator", adsr(0, xdecay, 0, 0) : *(noise));

/* Bank of 5 resonators. */

resonator(f,t,i,hrm,amp,decay,rq)
		= (f,t,_) : hgroup("2-resonator-%i", g)
with {
	g(f,t)	= resonz(R,h)*(amp*b*env)
	with {
		h	= hrm*f;	// harmonic
		B	= rq*f/SR;	// bandwidth, as fraction of sample rate
		R	= 1-PI*B;	// resonance (pole radius)
		b	= 1/(2*B);	// boost factor = Nyquist/bandwidth
		env	= adsr(0, decay, 0, 0, t);	// envelop
	};
};

resonators(f,t)	= resonator(f,t,0,hrm0,amp0,decay0,rq0)
		+ resonator(f,t,1,hrm1,amp1,decay1,rq1)
		+ resonator(f,t,2,hrm2,amp2,decay2,rq2)
		+ resonator(f,t,3,hrm3,amp3,decay3,rq3)
		+ resonator(f,t,4,hrm4,amp4,decay4,rq4);

/* The synth. */

chime = excitator(gate)*gain <: resonators(freq, gate)
		;//: vgroup("3-master", *(vol) : panner(pan));



/*     ETE       ||||      HIVER            
0                ||||        0
3 semitones      ||||        3     
5 semitones      ||||        7     
8 semitones      ||||        9     
12 semitones     ||||        10         
20 semitones     ||||        12         
25 semitones     ||||        14          
29 semitones     ||||        20       
*/

gate1 = button("h:Gates/gate1");
gate2 = button("h:Gates/gate2");
gate3 = button("h:Gates/gate3");
gate4 = button("h:Gates/gate4");
gate5 = button("h:Gates/gate5");
gate6 = button("h:Gates/gate6");
gate7 = button("h:Gates/gate7");
gate8 = button("h:Gates/gate8");

shift = hslider("v:[2]Carillon/[3]shift[unit: semitones]", 0, -5, +5, 1);
strikepos = hslider("v:[2]Carillon/[1]strikepos",6,0,6,1);
cutoff = hslider("v:[2]Carillon/[1]cutoff",250,20,1000,1);
env = hslider("v:[2]Carillon/[2]enveloppe",0.5,0.05,2,0.01);

dur = hslider("v:[5]Echo/dur",0.7,0.020,1.000,0.01);
fb = hslider("v:[5]Echo/fb",0.25,0,1,0.01);

process = 
///*HIVER*/
((excitator(gate1)*gain <: resonators(415.3/2,gate1):/* fi.lowpass(3,2500) :*/ ef.echo(1.5,dur,fb) :co.limiter_1176_R4_mono)<: dm.dattorro_rev_demo:>_),
((excitator(gate2)*gain <: resonators(493.88/2,gate2):/* fi.lowpass(3,2500) :*/ ef.echo(1.5,dur,fb) :co.limiter_1176_R4_mono)<: dm.dattorro_rev_demo:>_),
((excitator(gate3)*gain <: resonators(554.37/2,gate3):/* fi.lowpass(3,2500) :*/ ef.echo(1.5,dur,fb) :co.limiter_1176_R4_mono)<: dm.dattorro_rev_demo:>_),
((excitator(gate4)*gain <: resonators(659.26/2,gate4):/* fi.lowpass(3,2500) :*/ ef.echo(1.5,dur,fb) :co.limiter_1176_R4_mono)<: dm.dattorro_rev_demo:>_),
((excitator(gate5)*gain <: resonators(830.61/2,gate5) :/* fi.lowpass(3,2500):*/ ef.echo(1.5,dur,fb) :co.limiter_1176_R4_mono)<: dm.dattorro_rev_demo:>_),
((excitator(gate6)*gain <: resonators(1318.51/2,gate6):/* fi.lowpass(3,2500) :*/ ef.echo(1.5,dur,fb) :co.limiter_1176_R4_mono)<: dm.dattorro_rev_demo:>_),
((excitator(gate7)*gain <: resonators(1760/2,gate7) :/* fi.lowpass(3,2500) :*/ ef.echo(1.5,dur,fb) :co.limiter_1176_R4_mono)<: dm.dattorro_rev_demo:>_),
((excitator(gate8)*gain <: resonators(2217.46/2,gate8) :/* fi.lowpass(3,2500) :*/ ef.echo(1.5,dur,fb) :co.limiter_1176_R4_mono)<: dm.dattorro_rev_demo:>_)

/*ETE*/
//( pm.standardBell(strikepos,cutoff,5.5,1.5,gate1)*en.smoothEnvelope(env,gate1) : ef.transpose(10000,10000,shift): ef.echo(1.5,dur,fb) :co.limiter_1176_R4_mono ),
//( pm.standardBell(strikepos,cutoff,5.5,1.5,gate2)*en.smoothEnvelope(env,gate2) : ef.transpose(10000,10000,shift+3) : ef.echo(1.5,dur,fb) :co.limiter_1176_R4_mono),
//( pm.standardBell(strikepos,cutoff,5.5,1.5,gate3)*en.smoothEnvelope(env,gate3) : ef.transpose(10000,10000,shift+5): ef.echo(1.5,dur,fb) :co.limiter_1176_R4_mono ),
//( pm.standardBell(strikepos,cutoff,5.5,1.5,gate4)*en.smoothEnvelope(env,gate4) : ef.transpose(8000,2000,shift+8): ef.echo(1.5,dur,fb) :co.limiter_1176_R4_mono ),
//( pm.standardBell(strikepos,cutoff,5.5,1.5,gate5)*en.smoothEnvelope(env,gate5) : ef.transpose(200,100,shift+12) : fi.lowpass(3,2500): ef.echo(1.5,dur,fb) :co.limiter_1176_R4_mono),
//( pm.standardBell(strikepos,cutoff,5.5,1.5,gate6)*en.smoothEnvelope(env,gate6) : ef.transpose(200,100,shift+20) : fi.lowpass(3,2500): ef.echo(1.5,dur,fb) :co.limiter_1176_R4_mono),
//( pm.standardBell(strikepos,cutoff,5.5,1.5,gate7)*en.smoothEnvelope(env,gate7) : ef.transpose(200,200,shift+25) : fi.lowpass(3,2500) : ef.echo(1.5,dur,fb) :co.limiter_1176_R4_mono),
//( pm.standardBell(strikepos,cutoff,5.5,1.5,gate8)*en.smoothEnvelope(env,gate8) : ef.transpose(200,200,shift+29) : fi.lowpass(3,2500): ef.echo(1.5,dur,fb) :co.limiter_1176_R4_mono )

:_,_,_,_,_,_,_,_
:>_,_ //Stereo4IDE
;

