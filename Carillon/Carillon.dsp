
import("stdfaust.lib");
import ("music.lib");
import("filter.lib");
import("effect.lib");


////////////////////////////////////////////////////////////////////////////////////////////////
//SHIMMER

//Constrols
//PS controls
sm_envelope = hslider("v:[1]EFFECTS/h:SHIMMER/envelope[style:knob]", 1, 0.1,3, 0.05);//parametric_controller(control, envelope, speed, depth)*shift
sm_speed = hslider("v:[1]EFFECTS/h:SHIMMER/speed[style:knob]", 0.1, 0.1, 10, 0.05);
sm_depth = hslider("v:[1]EFFECTS/h:SHIMMER/depth[style:knob]", 0, 0, 1, 0.05);
sm_contrl = hslider("v:[1]EFFECTS/h:SHIMMER/contrl[style:knob]",0.5, 0, 1, 0.05);
sm_shift = hslider("v:[1]EFFECTS/h:SHIMMER/shift[style:knob]", 0, -6, +6, 0.1)*2; //*2 needed to conform with parametric controller output
//Reverb controls
sm_size = hslider("v:[1]EFFECTS/h:SHIMMER/size[style:knob]", 1, 1, 3, 0.05);
sm_diffusion =  hslider("v:[1]EFFECTS/h:SHIMMER/diffusion[style:knob]", 0.5, 0.1, 0.7, 0.05);
sm_feedback =  hslider("v:[1]EFFECTS/h:SHIMMER/feedback[style:knob]", 0, 0, 0.35, 0.05);
sm_hf_damping = hslider("v:[1]EFFECTS/h:SHIMMER/hf damping[style:knob]", 0.005, 0.005, 0.995, 0.005);
//Global 
sm_dry_wet = hslider("v:[1]EFFECTS/h:SHIMMER/dry/wet[style:knob]", 0.5, 0, 1, 0.05);

//Can be add to .lib
mixer(mix) = _*(1 - mix),_*mix:>_;

//Parametric controller, combinate signals from envelope follower and oscillator, can be added to .lib
c_folower_colibration = 6;
parametric_controller(mix, envelope_t, freq, depth) = (amp_follower(envelope_t):_*c_folower_colibration:_*depth,osc(freq)*0.5:_,_*depth):mixer(mix):_+0.5;

//Can be moved to .lib too
X = (_,_)<:(!,_,_,!);
opf(a) = (_+_*(1-a)~@(1)*a); 
allpass_with_fdelay(dt1,coef,dt2,dt2pos) = (_,_ <: (*(coef),_:+:@(dt1):fdelay(dt2,dt2pos)), -) ~ _ : (!,_);
allpass(dt,fb) = (_,_ <: (*(fb),_:+:@(dt)), -) ~ _ : (!,_);
dry_wet_mixer(c,x0,y0,x1,y1) = sel(c,x0,y0), sel(c,x1,y1)
	with { 
			sel(c,x,y) = (1-c)*x + c*y; 
		 };
dry_wet_mixer_mono(c,x0,x1) = y0,y1
	with { 
			y1 = (1-c)*x0;
            y0 = c*x1;
		 };

APFB(dt1,fb1,dtv,dtvpos,dt2,fb2) = _:allpass_with_fdelay(dt1,fb1,dtv,dtvpos):allpass(dt2,fb2);

//PS constants, can be changed to decrease effect delay 
c_samples = 2048;
c_xfade   = 1024;
//PS implementation, copy-pasted from faust repository, see ./examples/pitch_shifter.dsp
transpose (w, x, s, sig)  =
	fdelay1s(d,sig)*fmin(d/x,1) + fdelay1s(d+w,sig)*(1-fmin(d/x,1))
	   	with {
			i = 1 - pow(2, s/12);
			d = i : (+ : +(w) : fmod(_,w)) ~ _;
	        };

shimmer(x,y) = x,y:(_,_:
	(_,X,_:(
	(_*sm_feedback+_*0.3:>APFB(601*sm_size,0.7*sm_diffusion,50,49*(osc(1)+1)/2,613*sm_size,0.75*sm_diffusion)<:opf(sm_hf_damping)),
    (_*sm_feedback+_*0.3:>APFB(2043*sm_size,0.75*sm_diffusion,50,49*(osc(1.5)+1)/2,2087*sm_size,0.75*sm_diffusion)<:opf(sm_hf_damping))
	):X)~(
	(_*sm_feedback:dcblockerat(80)
	:@(4325)<:
	APFB(2337*sm_size,0.7*sm_diffusion,50,49*(osc(0.7)+1)/2,2377*sm_size,0.4*sm_diffusion):@(2969)<:transpose(c_samples,c_xfade,	 
    (x:parametric_controller(sm_contrl, sm_envelope, sm_speed, sm_depth):_*sm_shift))),
	(_*sm_feedback:dcblockerat(80)
	:@(4763)<:
	APFB(1087*sm_size,0.7*sm_diffusion,50,49*(osc(1.3)+1)/2,1113*sm_size,0.4*sm_diffusion):@(3111)<:transpose(c_samples,c_xfade,	 			   
	(y:parametric_controller(sm_contrl, sm_envelope, sm_speed, sm_depth):_*sm_shift)))))
	//:dry_wet_mixer(dry_wet,x,_,y,_)
    ;


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
hrm1		= nentry("harmonic1", 3.007*2, 0, 50, 0.001);	// harmonic
amp1		= nentry("amplitude1", 0.083, 0, 1, 0.001);	// amplitude
decay1		= nentry("decay1", 2.248, 0, 10, 0.001);	// decay time
rq1		= nentry("rq1", 0.002, 0, 1, 0.0001);		// filter 1/Q
// resonator #2
hrm2		= nentry("harmonic2", 4.968*2, 0, 50, 0.001);	// harmonic
amp2		= nentry("amplitude2", 0.087*2, 0, 1, 0.001);	// amplitude
decay2		= nentry("decay2", 2.828, 0, 10, 0.001);	// decay time
rq2		= nentry("rq2", 0.002, 0, 1, 0.0001);		// filter 1/Q
// resonator #3
hrm3		= nentry("harmonic3", 8.994*2, 0, 50, 0.001);	// harmonic
amp3		= nentry("amplitude3", 0.053, 0, 1, 0.001);	// amplitude
decay3		= nentry("decay3", 3.364, 0, 10, 0.001);	// decay time
rq3		= nentry("rq3", 0.002, 0, 1, 0.0001);		// filter 1/Q
// resonator #4
hrm4		= nentry("harmonic4", 12.006*2, 0, 50, 0.001);	// harmonic
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

gate1 = button("v:[0]MODELES/h:[1]Gates/gate1");
gate2 = button("v:[0]MODELES/h:[1]Gates/gate2");
gate3 = button("v:[0]MODELES/h:[1]Gates/gate3");
gate4 = button("v:[0]MODELES/h:[1]Gates/gate4");
gate5 = button("v:[0]MODELES/h:[1]Gates/gate5");
gate6 = button("v:[0]MODELES/h:[1]Gates/gate6");
gate7 = button("v:[0]MODELES/h:[1]Gates/gate7");
gate8 = button("v:[0]MODELES/h:[1]Gates/gate8");

shift = hslider("v:[2]Carillon/[3]shift[unit: semitones]", 0, -5, +5, 1);
strikepos = hslider("v:[2]Carillon/[1]strikepos",6,0,6,1);
cutoff = hslider("v:[2]Carillon/[1]cutoff",250,20,1000,1);
env = hslider("v:[2]Carillon/[2]enveloppe",0.5,0.05,2,0.01);

dur = hslider("v:[1]EFFECTS/v:[5]Echo/dur",0.7,0.020,1.000,0.01);
fb = hslider("v:[1]EFFECTS/v:[5]Echo/fb",0.15,0,1,0.01);

//LPG
at = hslider("v:[2]AR/attack",0.001,0.001,1,0.001);
rt = hslider("v:[2]AR/release",0.5,0.001,1,0.001);

//Frequences
fr1 = 415.3/2;
fr2 = 493.88/2;
fr3 = 554.37/2;
fr4 = 659.26/2;
fr5 = 830.61/2;
fr6 = 1318.51/2;
fr7 = 1760/2;
fr8 = 2217.46/2;


process = 
///*HIVER*/
((excitator(gate1)*gain <: resonators(fr1,gate1)) <: (_*en.ar(at,rt,gate1),_*fi.lowpass(3,fr1)):> ef.echo(1.5,dur,fb) :co.limiter_1176_R4_mono <: shimmer(_,_),_ : _,!,_ : dry_wet_mixer_mono(sm_dry_wet,_,_) :>_),
((excitator(gate2)*gain <: resonators(fr2,gate2)) <: (_*en.ar(at,rt,gate2),_*fi.lowpass(3,fr2)):> ef.echo(1.5,dur,fb) :co.limiter_1176_R4_mono <: shimmer(_,_),_ : _,!,_ : dry_wet_mixer_mono(sm_dry_wet,_,_) :>_),
((excitator(gate3)*gain <: resonators(fr3,gate3)) <: (_*en.ar(at,rt,gate3),_*fi.lowpass(3,fr3)):> ef.echo(1.5,dur,fb) :co.limiter_1176_R4_mono <: shimmer(_,_),_ : _,!,_ : dry_wet_mixer_mono(sm_dry_wet,_,_) :>_),
((excitator(gate4)*gain <: resonators(fr4,gate4)) <: (_*en.ar(at,rt,gate4),_*fi.lowpass(3,fr4)):> ef.echo(1.5,dur,fb) :co.limiter_1176_R4_mono <: shimmer(_,_),_ : _,!,_ : dry_wet_mixer_mono(sm_dry_wet,_,_) :>_),
((excitator(gate5)*gain <: resonators(fr5,gate5)) <: (_*en.ar(at,rt,gate5),_*fi.lowpass(3,fr5)):> ef.echo(1.5,dur,fb) :co.limiter_1176_R4_mono <: shimmer(_,_),_ : _,!,_ : dry_wet_mixer_mono(sm_dry_wet,_,_) :>_),
((excitator(gate6)*gain <: resonators(fr6,gate6)) <: (_*en.ar(at,rt,gate6),_*fi.lowpass(3,fr6)):> ef.echo(1.5,dur,fb) :co.limiter_1176_R4_mono <: shimmer(_,_),_ : _,!,_ : dry_wet_mixer_mono(sm_dry_wet,_,_) :>_),
((excitator(gate7)*gain <: resonators(fr7,gate7)) <: (_*en.ar(at,rt,gate7),_*fi.lowpass(3,fr7)):> ef.echo(1.5,dur,fb) :co.limiter_1176_R4_mono <: shimmer(_,_),_ : _,!,_ : dry_wet_mixer_mono(sm_dry_wet,_,_) :>_),
((excitator(gate8)*gain <: resonators(fr8,gate8)) <: (_*en.ar(at,rt,gate8),_*fi.lowpass(3,fr8)):> ef.echo(1.5,dur,fb) :co.limiter_1176_R4_mono <: shimmer(_,_),_ : _,!,_ : dry_wet_mixer_mono(sm_dry_wet,_,_) :>_)

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

