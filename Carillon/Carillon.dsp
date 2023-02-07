
import("stdfaust.lib");


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
//( pm.standardBell(strikepos,cutoff,5.5,1.5,gate1)*en.smoothEnvelope(env,gate1) : ef.transpose(10000,10000,shift) : ef.echo(1.5,dur,fb) :co.limiter_1176_R4_mono),
//( pm.standardBell(strikepos,cutoff,5.5,1.5,gate2)*en.smoothEnvelope(env,gate2) : ef.transpose(10000,10000,shift+3) : ef.echo(1.5,dur,fb) :co.limiter_1176_R4_mono),
//( pm.standardBell(strikepos,cutoff,5.5,1.5,gate3)*en.smoothEnvelope(env,gate3) : ef.transpose(10000,10000,shift+7) : ef.echo(1.5,dur,fb) :co.limiter_1176_R4_mono),
//( pm.standardBell(strikepos,cutoff,5.5,1.5,gate4)*en.smoothEnvelope(env,gate4) : ef.transpose(5000,5000,shift+9) : ef.echo(1.5,dur,fb) :co.limiter_1176_R4_mono),
//( pm.standardBell(strikepos,cutoff,5.5,1.5,gate5)*en.smoothEnvelope(env,gate5) : ef.transpose(200,200,shift+10) : ef.echo(1.5,dur,fb) :co.limiter_1176_R4_mono),
//( pm.standardBell(strikepos,cutoff,5.5,1.5,gate6)*en.smoothEnvelope(env,gate6) : ef.transpose(200,200,shift+12) : ef.echo(1.5,dur,fb) :co.limiter_1176_R4_mono),
//( pm.standardBell(strikepos,cutoff,5.5,1.5,gate7)*en.smoothEnvelope(env,gate7) : ef.transpose(200,200,shift+14) : fi.lowpass(3,2500) : ef.echo(1.5,dur,fb) :co.limiter_1176_R4_mono),
//( pm.standardBell(strikepos,cutoff,5.5,1.5,gate8)*en.smoothEnvelope(env,gate8) : ef.transpose(200,200,shift+20) : fi.lowpass(3,2500) : ef.echo(1.5,dur,fb) :co.limiter_1176_R4_mono)
//
/*ETE*/
( pm.standardBell(strikepos,cutoff,5.5,1.5,gate1)*en.smoothEnvelope(env,gate1) : ef.transpose(10000,10000,shift): ef.echo(1.5,dur,fb) :co.limiter_1176_R4_mono ),
( pm.standardBell(strikepos,cutoff,5.5,1.5,gate2)*en.smoothEnvelope(env,gate2) : ef.transpose(10000,10000,shift+3) : ef.echo(1.5,dur,fb) :co.limiter_1176_R4_mono),
( pm.standardBell(strikepos,cutoff,5.5,1.5,gate3)*en.smoothEnvelope(env,gate3) : ef.transpose(10000,10000,shift+5): ef.echo(1.5,dur,fb) :co.limiter_1176_R4_mono ),
( pm.standardBell(strikepos,cutoff,5.5,1.5,gate4)*en.smoothEnvelope(env,gate4) : ef.transpose(8000,2000,shift+8): ef.echo(1.5,dur,fb) :co.limiter_1176_R4_mono ),
( pm.standardBell(strikepos,cutoff,5.5,1.5,gate5)*en.smoothEnvelope(env,gate5) : ef.transpose(200,100,shift+12) : fi.lowpass(3,2500): ef.echo(1.5,dur,fb) :co.limiter_1176_R4_mono),
( pm.standardBell(strikepos,cutoff,5.5,1.5,gate6)*en.smoothEnvelope(env,gate6) : ef.transpose(200,100,shift+20) : fi.lowpass(3,2500): ef.echo(1.5,dur,fb) :co.limiter_1176_R4_mono),
( pm.standardBell(strikepos,cutoff,5.5,1.5,gate7)*en.smoothEnvelope(env,gate7) : ef.transpose(200,200,shift+25) : fi.lowpass(3,2500) : ef.echo(1.5,dur,fb) :co.limiter_1176_R4_mono),
( pm.standardBell(strikepos,cutoff,5.5,1.5,gate8)*en.smoothEnvelope(env,gate8) : ef.transpose(200,200,shift+29) : fi.lowpass(3,2500): ef.echo(1.5,dur,fb) :co.limiter_1176_R4_mono )

:_,_,_,_,_,_,_,_
//:>_,_ //Stereo4IDE
;

