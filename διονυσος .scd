(
s.waitForBoot({

	// ------------------------------------------------------------
	// CLEAN START
	// ------------------------------------------------------------

	s.freeAll;

	~mainBus = Bus.audio(s, 2);


	// ------------------------------------------------------------
// B) MARTIAL FM BRASS + OCTAVE-DOWN PIANO SHADOW
// every brass note is doubled by a piano one octave below
// ------------------------------------------------------------

SynthDef(\randomBrass, {
	arg out=0, freq=60, amp=0.18, pan=0,
	att=0.18, rel=5.5, modIndex=5, ratio=1.5,
	cutoffMul=8, verbMix=0.34,
	pianoAmp=0.19;

	var env, fmMod, car, sig, sig2, air, filterMove;
	var pianoFreq, pianoEnv, hammer, piano, p1, p2, p3, p4, p5;

	env = EnvGen.kr(
		Env.perc(att, rel, curve: [-2, -5]),
		doneAction: 2
	);

	// --------------------------------------------------------
	// FM BRASS CORE
	// --------------------------------------------------------

	fmMod = SinOsc.ar(freq * ratio) * (freq * modIndex * env);
	car = SinOsc.ar(freq + fmMod);

	sig2 = SinOsc.ar((freq * 0.5) + (fmMod * 0.35), 0, 0.35);

	sig = car + sig2;

	sig = (sig * 1.6).distort;
	sig = (sig * 1.25).tanh;

	filterMove = SinOsc.kr(Rand(0.04, 0.18)).range(0.75, 1.35);
	sig = LPF.ar(sig, (freq * cutoffMul * filterMove).clip(180, 9000));

	air = BPF.ar(
		WhiteNoise.ar(0.05),
		(freq * Rand(3.0, 8.0)).clip(300, 7500),
		0.25
	);

	sig = sig + (air * env);

	sig = FreeVerb.ar(
		sig,
		verbMix,
		0.86,
		0.55
	);

	sig = BPeakEQ.ar(sig, 900, 0.7, 2.0);
	sig = BHiShelf.ar(sig, 2500, 0.7, 2.5);


	// --------------------------------------------------------
	// OCTAVE-DOWN DARK PIANO SHADOW
	// same note as brass, always one octave below
	// --------------------------------------------------------

	pianoFreq = freq * 0.5;

	pianoEnv = EnvGen.kr(
		Env.perc(0.005, rel * 0.72, curve: [-4, -6])
	);

	hammer = WhiteNoise.ar(0.25) * EnvGen.kr(
		Env.perc(0.001, 0.035, curve: [-6, -8])
	);

	p1 = BPF.ar(hammer, pianoFreq * 1.00, 0.035) * 1.00;
	p2 = BPF.ar(hammer, pianoFreq * 2.01, 0.025) * 0.65;
	p3 = BPF.ar(hammer, pianoFreq * 3.02, 0.020) * 0.38;
	p4 = BPF.ar(hammer, pianoFreq * 4.08, 0.018) * 0.24;
	p5 = BPF.ar(hammer, pianoFreq * 5.16, 0.014) * 0.16;

	piano = p1 + p2 + p3 + p4 + p5;

	// wooden / metallic low piano body
	piano = piano + SinOsc.ar(pianoFreq, 0, 0.18);
	piano = piano * pianoEnv;

	// darken and place behind the brass
	piano = LPF.ar(piano, 2400);
	piano = HPF.ar(piano, 28);
	piano = (piano * 1.6).tanh;

	piano = FreeVerb.ar(
		piano,
		0.28,
		0.74,
		0.42
	);


	// --------------------------------------------------------
	// MIX BRASS + PIANO
	// --------------------------------------------------------

	sig = (sig * amp) + (piano * pianoAmp);

	Out.ar(out, Pan2.ar(sig * env, pan));
}).add;


	// ------------------------------------------------------------
	// C) LOW HORN
	// every 10 seconds after it enters
	// ------------------------------------------------------------

	SynthDef(\lowHorn, {
		arg out=0, freq=44, amp=0.16, atk=0.25, rel=4.5;

		var env, sig, body;

		env = EnvGen.kr(
			Env.perc(atk, rel, curve: [-3, -4]),
			doneAction: 2
		);

		body =
			LFSaw.ar(freq, 0, 0.7) +
			SinOsc.ar(freq * 2, 0, 0.25) +
			SinOsc.ar(freq * 3.01, 0, 0.12);

		sig = RLPF.ar(
			body,
			XLine.kr(500, 130, rel),
			0.18
		);

		sig = sig + BPF.ar(
			WhiteNoise.ar(0.03),
			freq * 6,
			0.2
		);

		sig = tanh(sig * 1.6);

		sig = Pan2.ar(sig, Rand(-0.35, 0.35));

		Out.ar(out, sig * env * amp);
	}).add;


	// ------------------------------------------------------------
	// D) INDUSTRIAL DISTORTED KICK
	// unpredictable, long body, distorted, but lower in the mix
	// ------------------------------------------------------------

	SynthDef(\industrialKick, {
		arg out=0, amp=0.13, freq=45, rel=2.8, drive=18;

		var env, pitchEnv, sig, click, noise, sub;

		env = EnvGen.kr(
			Env.perc(0.005, rel, curve: [-4, -6]),
			doneAction: 2
		);

		pitchEnv = EnvGen.kr(
			Env(
				[freq * 7, freq * 1.7, freq],
				[0.035, 0.22],
				curve: [-8, -4]
			)
		);

		sub = SinOsc.ar(pitchEnv);

		click = HPF.ar(
			WhiteNoise.ar(0.25) * EnvGen.kr(Env.perc(0.001, 0.035)),
			3500
		);

		noise = BPF.ar(
			BrownNoise.ar(0.35),
			XLine.kr(220, 55, rel),
			0.5
		);

		sig = sub + click + noise;

		// heavy distortion chain
		sig = (sig * drive).tanh;
		sig = (sig * 5.5).tanh;
		sig = Fold.ar(sig, -0.7, 0.7);
		sig = (sig * 2.8).tanh;

		// long industrial body
		sig = LPF.ar(sig, 2600);
		sig = HPF.ar(sig, 25);

		sig = Pan2.ar(sig, Rand(-0.15, 0.15));

		Out.ar(out, sig * env * amp);
	}).add;


	// ------------------------------------------------------------
	// E) DOMINANT F# DEATH INDUSTRIAL DRONE
	// starts first, imposing foundation
	// ------------------------------------------------------------

	SynthDef(\lowFSharpDroneBed, {
		arg out=0, freq=46.25, amp=0.34, pan=0, cutoff=680, verbMix=0.34;

		var sig, env, mod, sub, body, comb, air;

		env = EnvGen.kr(
			Env.asr(8.0, 1.0, 12.0, curve: [-4, 0, -5]),
			gate: 1
		);

		// slow unstable modulation
		mod = SinOsc.kr(0.08).range(0.5, 5.0);

		// phase-modulated industrial core
		body = PMOsc.ar(
			freq,
			freq * mod,
			12
		);

		// deep fundamental support
		sub =
			SinOsc.ar(freq, 0, 0.35) +
			SinOsc.ar(freq * 0.5, 0, 0.18);

		sig = body + sub;

		// resonant metallic cavity
		comb = CombL.ar(
			sig,
			0.25,
			(1 / freq).clip(0.001, 0.2),
			4.5
		);

		sig = sig + (comb * 0.65);

		// death industrial distortion
		sig = (sig * 10).distort;
		sig = (sig * 2.8).tanh;

		// oppressive filtering
		sig = LPF.ar(sig, cutoff);
		sig = HPF.ar(sig, 24);

		// dirty air / distant machinery
		air = BPF.ar(
			BrownNoise.ar(0.10),
			SinOsc.kr(0.013).range(90, 280),
			0.32
		);

		sig = sig + air;

		// dark reverb
		sig = FreeVerb.ar(
			sig,
			verbMix,
			0.72,
			0.28
		);

		sig = Pan2.ar(sig, pan);

		Out.ar(out, sig * env * amp);
	}).add;


	// ------------------------------------------------------------
	// MASTER OUT
	// cleaner, wider, safer
	// ------------------------------------------------------------

	SynthDef(\masterOut, {
		arg in=0, out=0, amp=0.82;

		var sig, wet;

		sig = In.ar(in, 2);

		// remove useless sub rumble
		sig = HPF.ar(sig, 22);

		// subtle stereo widening
		sig = [
			DelayC.ar(sig[0], 0.03, 0.004),
			DelayC.ar(sig[1], 0.03, 0.007)
		] + (sig * 0.92);

		// subtle global dark space
		wet = FreeVerb2.ar(
			sig[0],
			sig[1],
			0.18,
			0.86,
			0.62
		);

		sig = XFade2.ar(sig, wet, -0.35);

		// soft glue
		sig = Compander.ar(
			sig,
			sig,
			0.5,
			1,
			0.45,
			0.01,
			0.25
		);

		sig = tanh(sig * 1.05);

		// safety
		sig = Limiter.ar(sig, 0.9);

		Out.ar(out, sig * amp);
	}).add;


	// ------------------------------------------------------------
	// WAIT UNTIL SYNTHDEFS ARE READY
	// ------------------------------------------------------------

	s.sync;


	// ------------------------------------------------------------
	// START MASTER
	// ------------------------------------------------------------

	~master = Synth(\masterOut, [
		\in, ~mainBus,
		\out, 0,
		\amp, 0.82
	]);


	// ------------------------------------------------------------
	// STAGGERED COMPOSITION START
	// 0 sec  -> F# drone
	// 10 sec -> brass
	// 20 sec -> horn
	// 30 sec -> kick
	// ------------------------------------------------------------

	~startComposition = Routine({

		// 0 sec: F# drone starts alone
		~fsharpDroneBed = Synth(\lowFSharpDroneBed, [
			\out, ~mainBus,
			\freq, 46.25,
			\amp, 0.34,
			\cutoff, 680,
			\verbMix, 0.34,
			\pan, 0
		]);

		"0 sec: F# death industrial drone started".postln;

		10.wait;


		// 10 sec: brass enters
		~brassPattern = Pbind(
			\instrument, \randomBrass,
			\out, ~mainBus,

			\dur, Pwhite(0.55, 3.2, inf),

			\midinote, Pfunc({
				var r;
				r = 1.0.rand;

				if(
					r < 0.42,
					{
						rrand(28, 43)
					},
					{
						if(
							r < 0.84,
							{
								rrand(44, 62)
							},
							{
								rrand(63, 84)
							}
						)
					}
				);
			}),

			// brass volume
			\amp, Pwhite(0.10, 0.24, inf),

			// piano shadow volume, always one octave below brass
            \pianoAmp, Pwhite(0.12, 0.18, inf),

			\att, Pwhite(0.08, 0.38, inf),
			\rel, Pwhite(3.5, 9.5, inf),

			\modIndex, Pwhite(2.5, 9.0, inf),
			\ratio, Prand([0.5, 1.0, 1.25, 1.5, 2.0, 2.5], inf),
			\cutoffMul, Pwhite(4.0, 13.0, inf),
			\verbMix, Pwhite(0.22, 0.48, inf),
			\pan, Pwhite(-0.65, 0.65, inf)
		).play;

		"10 sec: martial FM brass entered".postln;

		10.wait;


		// 20 sec: horn enters
		~hornPattern = Pbind(
			\instrument, \lowHorn,
			\out, ~mainBus,

			\dur, 10,

			\midinote, Prand([
				24, 26, 28, 29, 31, 33, 36
			], inf),

			\amp, Pwhite(0.10, 0.20, inf),
			\atk, Pwhite(0.12, 0.45, inf),
			\rel, Pwhite(3.5, 6.5, inf)
		).play;

		"20 sec: low horn entered".postln;

		10.wait;


		// 30 sec: industrial kick enters
		~kickPattern = Pbind(
			\instrument, \industrialKick,
			\out, ~mainBus,

			\dur, Pwhite(1.8, 12.0, inf),

			\freq, Pwhite(34, 58, inf),

			// deliberately lower in the mix
			\amp, Pwhite(0.08, 0.18, inf),

			\rel, Pwhite(1.4, 4.5, inf),
			\drive, Pwhite(10, 26, inf)
		).play;

		"30 sec: industrial kick entered".postln;

	}).play;


	"COMPOSITION STARTED: drone -> brass -> horn -> kick".postln;

});
)