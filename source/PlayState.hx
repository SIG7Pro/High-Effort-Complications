package;

import Section.SwagSection;
import Song.SwagSong;
import WiggleEffect.WiggleEffectType;
import flixel.FlxBasic;
import flixel.FlxCamera;
import flixel.FlxG;
import flixel.FlxGame;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.FlxState;
import flixel.FlxSubState;
import flixel.addons.display.FlxGridOverlay;
import flixel.addons.effects.FlxTrail;
import flixel.addons.effects.FlxTrailArea;
import flixel.addons.effects.chainable.FlxEffectSprite;
import flixel.addons.effects.chainable.FlxWaveEffect;
import flixel.addons.transition.FlxTransitionableState;
import flixel.graphics.atlas.FlxAtlas;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.math.FlxMath;
import flixel.math.FlxPoint;
import flixel.math.FlxRect;
import flixel.system.FlxSound;
import flixel.text.FlxText;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.ui.FlxBar;
import flixel.util.FlxCollision;
import flixel.util.FlxColor;
import flixel.util.FlxSort;
import flixel.util.FlxStringUtil;
import flixel.util.FlxTimer;
import haxe.Json;
import lime.utils.Assets;
import lime.app.Application;
import lime.ui.Window;
import openfl.display.BlendMode;
import openfl.display.StageQuality;
import openfl.filters.ShaderFilter;
import openfl.filters.ColorMatrixFilter;
import Controls.KeyboardScheme;
/* Revamped note handling (Cyclycle)
 - Handle notes one at a time
 - Compress chords down into chord objects
 - Handle sustains separately with original (Chad) method
 - Hold array of sustains to avoid checking against when checking antimash
 - Conceptual code (no var declares yet, time declares the millisecond difference between a note's strum time and Conductor.songTime)
    currentlyhandling = 0;
	(in keyShit)
	backendMs = 44;
	frontendMs = 31;
	if(time(notes[currentlyhandling]) < frontEndMs && time(notes[currentlyhandling]) > -backendMs && not_chord(notes[currentlyhandling])){
		if(controlArray[notes[currentlyhandling].noteData]){ // k1P and such
			if(check_for_mash(notes[currentlyhandling].DataVals) && (Mashnt == 0 || (Mashnt == 1 && !mustHitPain[Std.int(curBeat / 4)]))){
				bad_mash(controlArray, notes[currentlyhandling].dataVals);
				return;
			}
			hit(notes[currentlyhandling]);
			currentlyhandling++;
			return;
		}
	} else if(time(notes[currentlyhandling]) < frontEndMs && time(notes[currentlyhandling]) > -backendMs && !not_chord(notes[currentlyhandling])){
		pressedAll = true;
		for(i in notes[currentlyhandling].DataVals){
			if(!controlArray[i])
				pressedAll = false;
			}
		}
		if(check_for_mash(notes[currentlyhandling].DataVals) && (Mashnt == 0 || (Mashnt == 1 && !mustHitPain[Std.int(curBeat / 4)]))){
			bad_mash(controlArray, notes[currentlyhandling].dataVals);
			return;
		}
		hit(notes[currentlyhandling]);
		currentlyhandling++;
		return;
	} else
		miss(notes[currentlyhandling]);
*/

using StringTools;

class PlayState extends MusicBeatState
{
	public static var downscroll:Bool = false;
	public static var curStage:String = '';
	public static var SONG:SwagSong;
	public static var isStoryMode:Bool = false;
	public static var storyWeek:Int = 0;
	public static var Mashnt:Int = 0;
	public static var campaignRating:Float = -1;
	public static var playlistLength:Int = -1;
	private var notesHit:Int = 0; // an average counter to help with rating mean
	public static var Average:String = "N/A";
	private var averageRating:Float = -1; // -1 = N/A, 0 = Shit, 1 = Bad, 2 = Good, 3 = Sick, 4 = Ultra-sick
	public static var breaks:Int = 0; // Amount of stun combo breaks
	public static var misses:Int = 0; // Amount of notes missed
	private var Percentage:Float = 1; // general accuracy, calculated with note timing over note rating
	public static var storyPlaylist:Array<String> = [];
	public static var storyDifficulty:Int = 1;
	public static var NPS:Int = 0;
	private var morePlayers:Array<Character> = [];
	private var ip:Bool = false;
	private var Player2s:Array<Character> = [];
	private var hell:Bool = false;
	private var opn:Bool = false;
	private var opni:Int = 0;
	/* Kade Engine:
	*** 2 vars, 1 for the shown NPS, and 1 for an internal NPS counter.
	*** Increase the NPS counter for every note that's close to hitting range.
	*** 1. Update the shown NPS counter
	*** 2. Reset the internal NPS counter
	*** Do secondly.
	** Me:
	*** 1 global var for the NPS.
	*** When the note passes through the strum line, make an "increase ticket."
	*** The increase ticket increases the NPS, but expires a second after.
	*** The expiry will decrement the NPS again.
	
	Fuck you, Kade Engine, I'm making your shit fold like an ass cheek.
	*/
	var halloweenLevel:Bool = false;
	public static var sixfret:Bool = false;
	public static var ninefret:Bool = false;
	public static var vocals:FlxSound;
	private var doof:DialogueBox;
	private var dad:Character;
	private var gf:Character;
	private var boyfriend:Boyfriend;
	private var bbdetect:BlueBalls;
	public var blueballs_warn:Bool = false;

	public static var notes:FlxTypedGroup<Note>; // please...
	private var unspawnNotes:Array<Note> = [];

	private var strumLine:FlxSprite;
	private var curSection:Int = 0;

	private var camFollow:FlxObject;

	private static var prevCamFollow:FlxObject;

	private var strumLineNotes:FlxTypedGroup<FlxSprite>;
	private var playerStrums:FlxTypedGroup<FlxSprite>;

	private var camZooming:Bool = false;
	private var curSong:String = "";

	private var gfSpeed:Int = 1;
	public static var healthj:Float = 1;
	private var health:Float = 1;
	private var passer:Float = 2;
	private var start:Float = 0;
	private var combo:Int = 0;
	public static var Bprec:Int = 0;
	public static var Bullshit:Bool = false;
	private var healthBarBG:FlxSprite;
	private var healthBar:FlxBar;

	private var TimeBarBG:FlxSprite;
	private var TimeBar:FlxBar;

	private var generatedMusic:Bool = false;
	private var startingSong:Bool = false;

	private var iconP1:HealthIcon;
	private var iconP2:HealthIcon;
	private var camHUD:FlxCamera;
	public static var camHPHUD:FlxCamera;
	private var camGame:FlxCamera;
	public static var centeredNotes:Bool = false;

	var dialogue:Array<String> = ['blah blah blah', 'coolswag'];

	var halloweenBG:FlxSprite;
	var isHalloween:Bool = false;

	var phillyCityLights:FlxTypedGroup<FlxSprite>;
	var phillyTrain:FlxSprite;
	var trainSound:FlxSound;

	var limo:FlxSprite;
	var grpLimoDancers:FlxTypedGroup<BackgroundDancer>;
	var fastCar:FlxSprite;

	var upperBoppers:FlxSprite;
	var bottomBoppers:FlxSprite;
	var santa:FlxSprite;

	var bgGirls:BackgroundGirls;
	var wiggleShit:WiggleEffect = new WiggleEffect();

	var talking:Bool = true;
	var songScore:Int = 0;
	var scoreTxt:FlxText;
	var auxTxt:FlxText;
	

	public static var campaignScore:Int = 0;

	var defaultCamZoom:Float = 1.05;

	// how big to stretch the pixel art assets
	public static var daPixelZoom:Float = 6;

	var inCutscene:Bool = false;
	public static function campaignInit()
	{
		PlayState.campaignRating = -1;
		PlayState.playlistLength = -1;
	}
	public static function bti(w:Dynamic):Int
	{
		if(Std.isOfType(w, Array))
			return 1;
		if(Std.isOfType(w, Bool))
			return w ? 1 : 0;
		if(Std.isOfType(w, Int))
			return w;
		return -1;
	}
	public static var bot:Bool = false;
	public static var botType:Int = 0;
	private var R34Screen:FlxSprite;
	private var R34Switch:FlxTimer;
	function restartrand(?_:FlxTimer){
		R34Screen.animation.play('switch');
		var m:FlxTimer = new FlxTimer().start(0.1, function(_:FlxTimer){
			var Ri:Int = Std.int(Math.random()*11);
			var rand:Int = Std.int(Math.random()*10)+10;
			R34Screen.animation.play('r34-$Ri');
			R34Switch = new FlxTimer().start(rand, restartrand);
		});
	}
	override public function create()
	{
		healthj = 1;
		var q:Dynamic = Highscore.getRaw("OH SHI");
		var r:Bool = false;
		if(q != null){
			r=q;
			if(r)
				Main.postfix = "-over";
			else
				Main.postfix = "";
		}
		Main.state.largeImageKey = 'funk${Main.postfix}';
		var precs:String = "";
		Main.timestamp();
		Main.clear();
		trace(FlxG.width + "x" + FlxG.height);
		if(Highscore.getRaw("fps-b") != null){
			FlxG.drawFramerate = FlxG.updateFramerate = Highscore.getRaw("fps-b");
		}
		if(Highscore.getRaw("bt") != null){
			bot = bti(Highscore.getRaw("bt")) > 0;
			if(bot)
				botType = (bti(Highscore.getRaw("bt")) - 1);
			else
				botType = 0;
		}
		if(Highscore.getRaw("bp") != null)
			Bprec = bti(Highscore.getRaw("bp"));
		// var gameCam:FlxCamera = FlxG.camera;
		notesHit = 0;
		averageRating = -1;
		if(Highscore.getRaw("downscroll") != null)
			downscroll = Highscore.getRaw("downscroll");
		if(Highscore.getRaw("center") != null)
			centeredNotes = Highscore.getRaw("center");
		if(Highscore.getRaw("mash-prot") != null)
			Mashnt = Highscore.getRaw("mash-prot");
		breaks = 0;
		misses = 0;
		NPS = 0;
		Average = bot ? "UNRATED" : "N/A";
		camGame = new FlxCamera();
		camHUD = new FlxCamera();
		camHPHUD = new FlxCamera();
		camHUD.bgColor.alpha = 0;
		camHPHUD.bgColor.alpha = 0;

		FlxG.cameras.reset(camGame);
		FlxG.cameras.add(camHUD);
		FlxG.cameras.add(camHPHUD);

		FlxCamera.defaultCameras = [camGame];
		
		FlxG.camera.followLerp = (60 / FlxG.updateFramerate);

		persistentUpdate = true;
		persistentDraw = true;

		if (SONG == null)
			SONG = Song.loadFromJson('tutorial');

		Conductor.mapBPMChanges(SONG);
		Conductor.changeBPM(SONG.bpm);
		var Name:String = SONG.song.toLowerCase();
		sixfret = SONG.sixkey;
		ninefret = SONG.ninekey;
		if(ninefret)
			controls.setKeyboardScheme(KeyboardScheme.NineKeyBullshit, false);
		else
			controls.setKeyboardScheme(KeyboardScheme.Solo, false);
		trace(Name);
		try {
			dialogue = CoolUtil.coolTextFile('assets/data/'+Name+'/'+Name+'-dialogue.txt');
		} catch(_e) {
			trace(Name+" has no dialogue");
			dialogue = [];
		}
		if(Highscore.getRaw("prec") != null)
		{
			ip = Highscore.getRaw("prec");
			if(Highscore.getRaw("hell") != null)
			{
				hell = ip && Highscore.getRaw("hell");
			}
			if(ip)
			{
				if(!Bullshit)
					SONG.speed *= 1.25;
				Conductor.limitSafeFrames(5);
				if(hell)
				{
					precs = " (Hell Mode)";
					if(!Bullshit)
						SONG.speed *= (1.5 / 1.25); // 1.5x
					Conductor.limitSafeFrames(3); // hell
				}
				else
				{
					precs = " (Precision Mode)";
				}
				Bullshit = true;
			}
			else
			{
				Conductor.limitSafeFrames(10);
			}
		}
		Main.setstate(SONG.song + precs);
		if(Name == 'pineappled'){
			defaultCamZoom = 0.9;
			curStage = 'stage';
			var bg:FlxSprite = new FlxSprite(-600, -200).loadGraphic('assets/images/pine/stageback.png');
			bg.antialiasing = true;
			bg.scrollFactor.set(0.9, 0.9);
			bg.active = false;
			add(bg);

			var stageFront:FlxSprite = new FlxSprite(-650, 600).loadGraphic('assets/images/pine/stagefront.png');
			stageFront.setGraphicSize(Std.int(stageFront.width * 1.1));
			stageFront.updateHitbox();
			stageFront.antialiasing = true;
			stageFront.scrollFactor.set(0.9, 0.9);
			stageFront.active = false;
			add(stageFront);

			var stageCurtains:FlxSprite = new FlxSprite(-500, -300).loadGraphic('assets/images/pine/stagecurtains.png');
			stageCurtains.setGraphicSize(Std.int(stageCurtains.width * 0.9));
			stageCurtains.updateHitbox();
			stageCurtains.antialiasing = true;
			stageCurtains.scrollFactor.set(1.3, 1.3);
			stageCurtains.active = false;

			add(stageCurtains);
		} else if(SONG.song.toLowerCase() == 'fool-34' || SONG.song.toLowerCase() == 'vibribbon-reds' || SONG.song.toLowerCase() == 'meatball'){
			curStage = "r34room";
			var Backbone = new FlxSprite(-500, -300);
			Backbone.frames = FlxAtlasFrames.fromSparrow('assets/images/z/r34room.png', 'assets/images/z/r34room.xml');
			Backbone.animation.addByPrefix('switch', 'Rule34 Switch');
			for(i in 0...11)
			{
				Backbone.animation.addByPrefix('r34-$i', 'Rule34 $i-Number', 12, true);
			}
			Backbone.antialiasing = true;
			var R34Instance:Int = Std.int(Math.random()*11);
			var rand:Int = Std.int(Math.random()*10)+10;
			Backbone.animation.play('r34-${R34Instance}');
			R34Screen = Backbone;
			R34Switch = new FlxTimer().start(rand, restartrand);
			add(Backbone);
		} else if(Name == 'brazil-2'){
			defaultCamZoom = 0.9;
			curStage = 'stage';
			var bg:FlxSprite = new FlxSprite(-600, -200).loadGraphic('assets/images/brazil/b2back.png');
			bg.antialiasing = true;
			bg.scrollFactor.set(0.9, 0.9);
			bg.active = false;
			add(bg);

			var stageFront:FlxSprite = new FlxSprite(-650, 600).loadGraphic('assets/images/brazil/b2front.png');
			stageFront.setGraphicSize(Std.int(stageFront.width * 1.1));
			stageFront.updateHitbox();
			stageFront.antialiasing = true;
			stageFront.scrollFactor.set(0.9, 0.9);
			stageFront.active = false;
			add(stageFront);
		} else if(Name == 'brazil'){
			defaultCamZoom = 0.9;
			curStage = 'stage';
			var bg:FlxSprite = new FlxSprite(-600, -200).loadGraphic('assets/images/brazil/stageback.png');
			bg.antialiasing = true;
			bg.scrollFactor.set(0.9, 0.9);
			bg.active = false;
			add(bg);

			var stageFront:FlxSprite = new FlxSprite(-650, 600).loadGraphic('assets/images/brazil/stagefront.png');
			stageFront.setGraphicSize(Std.int(stageFront.width * 1.1));
			stageFront.updateHitbox();
			stageFront.antialiasing = true;
			stageFront.scrollFactor.set(0.9, 0.9);
			stageFront.active = false;
			add(stageFront);

			var stageCurtains:FlxSprite = new FlxSprite(-500, -300).loadGraphic('assets/images/brazil/stagecurtains.png');
			stageCurtains.setGraphicSize(Std.int(stageCurtains.width * 0.9));
			stageCurtains.updateHitbox();
			stageCurtains.antialiasing = true;
			stageCurtains.scrollFactor.set(1.3, 1.3);
			stageCurtains.active = false;

			add(stageCurtains);
		} else if(SONG.song.toLowerCase() == 'ballistic')
		{
			curStage = "sillyboy";
			var Backbone = new FlxSprite(-500, -200);
			Backbone.frames = FlxAtlasFrames.fromSparrow('assets/images/b/BallisticBackground.png', 'assets/images/b/BallisticBackground.xml');
			Backbone.animation.addByPrefix('forevermoving', 'Background Whitty Moving');
			Backbone.antialiasing = true;
			Backbone.animation.play('forevermoving');
			var stageFront:FlxSprite = new FlxSprite(-600, 600).loadGraphic('assets/images/b/whittyFront.png'); // Stole straight from stage code
			stageFront.setGraphicSize(Std.int(stageFront.width * 1.1));
			stageFront.updateHitbox();
			stageFront.antialiasing = true;
			stageFront.scrollFactor.set(0.9, 0.9);
			stageFront.active = false;
			add(stageFront);
			add(Backbone);
		}
		else if (SONG.song.toLowerCase() == 'spookeez' || SONG.song.toLowerCase() == 'monster' || SONG.song.toLowerCase() == 'south')
		{
			curStage = "spooky";
			halloweenLevel = true;

			var hallowTex = FlxAtlasFrames.fromSparrow('assets/images/halloween_bg.png', 'assets/images/halloween_bg.xml');

			halloweenBG = new FlxSprite(-200, -100);
			halloweenBG.frames = hallowTex;
			halloweenBG.animation.addByPrefix('idle', 'halloweem bg0');
			halloweenBG.animation.addByPrefix('lightning', 'halloweem bg lightning strike', 24, false);
			halloweenBG.animation.play('idle');
			halloweenBG.antialiasing = true;
			add(halloweenBG);

			isHalloween = true;
		}
		else if (SONG.song.toLowerCase() == 'pico' || SONG.song.toLowerCase() == 'blammed' || SONG.song.toLowerCase() == 'philly')
		{
			curStage = 'philly';

			var bg:FlxSprite = new FlxSprite(-100).loadGraphic('assets/images/philly/sky.png');
			bg.scrollFactor.set(0.1, 0.1);
			add(bg);

			var city:FlxSprite = new FlxSprite(-10).loadGraphic('assets/images/philly/city.png');
			city.scrollFactor.set(0.3, 0.3);
			city.setGraphicSize(Std.int(city.width * 0.85));
			city.updateHitbox();
			add(city);

			phillyCityLights = new FlxTypedGroup<FlxSprite>();
			add(phillyCityLights);

			for (i in 0...5)
			{
				var light:FlxSprite = new FlxSprite(city.x).loadGraphic('assets/images/philly/win' + i + '.png');
				light.scrollFactor.set(0.3, 0.3);
				light.visible = false;
				light.setGraphicSize(Std.int(light.width * 0.85));
				light.updateHitbox();
				light.antialiasing = true;
				phillyCityLights.add(light);
			}

			var streetBehind:FlxSprite = new FlxSprite(-40, 50).loadGraphic('assets/images/philly/behindTrain.png');
			add(streetBehind);

			phillyTrain = new FlxSprite(2000, 360).loadGraphic('assets/images/philly/train.png');
			add(phillyTrain);

			trainSound = new FlxSound().loadEmbedded('assets/sounds/train_passes' + TitleState.soundExt);
			FlxG.sound.list.add(trainSound);

			// var cityLights:FlxSprite = new FlxSprite().loadGraphic(AssetPaths.win0.png);

			var street:FlxSprite = new FlxSprite(-40, streetBehind.y).loadGraphic('assets/images/philly/street.png');
			add(street);
		}
		else if (SONG.song.toLowerCase() == 'milf' || SONG.song.toLowerCase() == 'satin-panties' || SONG.song.toLowerCase() == 'high')
		{
			curStage = 'limo';
			defaultCamZoom = 0.90;

			var skyBG:FlxSprite = new FlxSprite(-120, -50).loadGraphic('assets/images/limo/limoSunset.png');
			skyBG.scrollFactor.set(0.1, 0.1);
			add(skyBG);

			var bgLimo:FlxSprite = new FlxSprite(-200, 480);
			bgLimo.frames = FlxAtlasFrames.fromSparrow('assets/images/limo/bgLimo.png', 'assets/images/limo/bgLimo.xml');
			bgLimo.animation.addByPrefix('drive', "background limo pink", 24);
			bgLimo.animation.play('drive');
			bgLimo.scrollFactor.set(0.4, 0.4);
			add(bgLimo);

			grpLimoDancers = new FlxTypedGroup<BackgroundDancer>();
			add(grpLimoDancers);

			for (i in 0...5)
			{
				var dancer:BackgroundDancer = new BackgroundDancer((370 * i) + 130, bgLimo.y - 400);
				dancer.scrollFactor.set(0.4, 0.4);
				grpLimoDancers.add(dancer);
			}

			var overlayShit:FlxSprite = new FlxSprite(-500, -600).loadGraphic('assets/images/limo/limoOverlay.png');
			overlayShit.alpha = 0.5;
			// add(overlayShit);

			// var shaderBullshit = new BlendModeEffect(new OverlayShader(), FlxColor.RED);

			// FlxG.camera.setFilters([new ShaderFilter(cast shaderBullshit.shader)]);

			// overlayShit.shader = shaderBullshit;

			var limoTex = FlxAtlasFrames.fromSparrow('assets/images/limo/limoDrive.png', 'assets/images/limo/limoDrive.xml');

			limo = new FlxSprite(-120, 550);
			limo.frames = limoTex;
			limo.animation.addByPrefix('drive', "Limo stage", 24);
			limo.animation.play('drive');
			limo.antialiasing = true;

			fastCar = new FlxSprite(-300, 160).loadGraphic('assets/images/limo/fastCarLol.png');
			// add(limo);
		}
		else if (SONG.song.toLowerCase() == 'cocoa' || SONG.song.toLowerCase() == 'eggnog')
		{
			curStage = 'mall';

			defaultCamZoom = 0.80;

			var bg:FlxSprite = new FlxSprite(-1000, -500).loadGraphic('assets/images/christmas/bgWalls.png');
			bg.antialiasing = true;
			bg.scrollFactor.set(0.2, 0.2);
			bg.active = false;
			bg.setGraphicSize(Std.int(bg.width * 0.8));
			bg.updateHitbox();
			add(bg);

			upperBoppers = new FlxSprite(-240, -90);
			upperBoppers.frames = FlxAtlasFrames.fromSparrow('assets/images/christmas/upperBop.png', 'assets/images/christmas/upperBop.xml');
			upperBoppers.animation.addByPrefix('bop', "Upper Crowd Bob", 24, false);
			upperBoppers.antialiasing = true;
			upperBoppers.scrollFactor.set(0.33, 0.33);
			upperBoppers.setGraphicSize(Std.int(upperBoppers.width * 0.85));
			upperBoppers.updateHitbox();
			add(upperBoppers);

			var bgEscalator:FlxSprite = new FlxSprite(-1100, -600).loadGraphic('assets/images/christmas/bgEscalator.png');
			bgEscalator.antialiasing = true;
			bgEscalator.scrollFactor.set(0.3, 0.3);
			bgEscalator.active = false;
			bgEscalator.setGraphicSize(Std.int(bgEscalator.width * 0.9));
			bgEscalator.updateHitbox();
			add(bgEscalator);

			var tree:FlxSprite = new FlxSprite(370, -250).loadGraphic('assets/images/christmas/christmasTree.png');
			tree.antialiasing = true;
			tree.scrollFactor.set(0.40, 0.40);
			add(tree);

			bottomBoppers = new FlxSprite(-300, 140);
			bottomBoppers.frames = FlxAtlasFrames.fromSparrow('assets/images/christmas/bottomBop.png', 'assets/images/christmas/bottomBop.xml');
			bottomBoppers.animation.addByPrefix('bop', 'Bottom Level Boppers', 24, false);
			bottomBoppers.antialiasing = true;
			bottomBoppers.scrollFactor.set(0.9, 0.9);
			bottomBoppers.setGraphicSize(Std.int(bottomBoppers.width * 1));
			bottomBoppers.updateHitbox();
			add(bottomBoppers);

			var fgSnow:FlxSprite = new FlxSprite(-600, 700).loadGraphic('assets/images/christmas/fgSnow.png');
			fgSnow.active = false;
			fgSnow.antialiasing = true;
			add(fgSnow);

			santa = new FlxSprite(-840, 150);
			santa.frames = FlxAtlasFrames.fromSparrow('assets/images/christmas/santa.png', 'assets/images/christmas/santa.xml');
			santa.animation.addByPrefix('idle', 'santa idle in fear', 24, false);
			santa.antialiasing = true;
			add(santa);
		}
		else if (SONG.song.toLowerCase() == 'winter-horrorland')
		{
			curStage = 'mallEvil';
			var bg:FlxSprite = new FlxSprite(-400, -500).loadGraphic('assets/images/christmas/evilBG.png');
			bg.antialiasing = true;
			bg.scrollFactor.set(0.2, 0.2);
			bg.active = false;
			bg.setGraphicSize(Std.int(bg.width * 0.8));
			bg.updateHitbox();
			add(bg);

			var evilTree:FlxSprite = new FlxSprite(300, -300).loadGraphic('assets/images/christmas/evilTree.png');
			evilTree.antialiasing = true;
			evilTree.scrollFactor.set(0.2, 0.2);
			add(evilTree);

			var evilSnow:FlxSprite = new FlxSprite(-200, 700).loadGraphic("assets/images/christmas/evilSnow.png");
			evilSnow.antialiasing = true;
			add(evilSnow);
		}
		else if(SONG.song.toLowerCase() == 'void' || SONG.song.toLowerCase() == 'screaming')
		{
			curStage = 'spacetime';
			var bg:FlxSprite = new FlxSprite(-600, -200).loadGraphic('assets/images/void.png');
			bg.active = false;
			add(bg);
		}
		else if (SONG.song.toLowerCase() == 'senpai' || SONG.song.toLowerCase() == 'roses')
		{
			curStage = 'school';

			// defaultCamZoom = 0.9;

			var bgSky = new FlxSprite().loadGraphic('assets/images/weeb/weebSky.png');
			bgSky.scrollFactor.set(0.1, 0.1);
			add(bgSky);

			var repositionShit = -200;

			var bgSchool:FlxSprite = new FlxSprite(repositionShit, 0).loadGraphic('assets/images/weeb/weebSchool.png');
			bgSchool.scrollFactor.set(0.6, 0.90);
			add(bgSchool);

			var bgStreet:FlxSprite = new FlxSprite(repositionShit).loadGraphic('assets/images/weeb/weebStreet.png');
			bgStreet.scrollFactor.set(0.95, 0.95);
			add(bgStreet);

			var fgTrees:FlxSprite = new FlxSprite(repositionShit + 170, 130).loadGraphic('assets/images/weeb/weebTreesBack.png');
			fgTrees.scrollFactor.set(0.9, 0.9);
			add(fgTrees);

			var bgTrees:FlxSprite = new FlxSprite(repositionShit - 380, -800);
			var treetex = FlxAtlasFrames.fromSpriteSheetPacker('assets/images/weeb/weebTrees.png', 'assets/images/weeb/weebTrees.txt');
			bgTrees.frames = treetex;
			bgTrees.animation.add('treeLoop', [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18], 12);
			bgTrees.animation.play('treeLoop');
			bgTrees.scrollFactor.set(0.85, 0.85);
			add(bgTrees);

			var treeLeaves:FlxSprite = new FlxSprite(repositionShit, -40);
			treeLeaves.frames = FlxAtlasFrames.fromSparrow('assets/images/weeb/petals.png', 'assets/images/weeb/petals.xml');
			treeLeaves.animation.addByPrefix('leaves', 'PETALS ALL', 24, true);
			treeLeaves.animation.play('leaves');
			treeLeaves.scrollFactor.set(0.85, 0.85);
			add(treeLeaves);

			var widShit = Std.int(bgSky.width * 6);

			bgSky.setGraphicSize(widShit);
			bgSchool.setGraphicSize(widShit);
			bgStreet.setGraphicSize(widShit);
			bgTrees.setGraphicSize(Std.int(widShit * 1.4));
			fgTrees.setGraphicSize(Std.int(widShit * 0.8));
			treeLeaves.setGraphicSize(widShit);

			fgTrees.updateHitbox();
			bgSky.updateHitbox();
			bgSchool.updateHitbox();
			bgStreet.updateHitbox();
			bgTrees.updateHitbox();
			treeLeaves.updateHitbox();

			bgGirls = new BackgroundGirls(-100, 190);
			bgGirls.scrollFactor.set(0.9, 0.9);

			if (SONG.song.toLowerCase() == 'roses')
			{
				bgGirls.getScared();
			}

			bgGirls.setGraphicSize(Std.int(bgGirls.width * daPixelZoom));
			bgGirls.updateHitbox();
			add(bgGirls);
		}
		else if (SONG.song.toLowerCase() == 'thorns')
		{
			curStage = 'schoolEvil';

			var waveEffectBG = new FlxWaveEffect(FlxWaveMode.ALL, 2, -1, 3, 2);
			var waveEffectFG = new FlxWaveEffect(FlxWaveMode.ALL, 2, -1, 5, 2);

			var posX = 400;
			var posY = 200;

			var bg:FlxSprite = new FlxSprite(posX, posY);
			bg.frames = FlxAtlasFrames.fromSparrow('assets/images/weeb/animatedEvilSchool.png', 'assets/images/weeb/animatedEvilSchool.xml');
			bg.animation.addByPrefix('idle', 'background 2', 24);
			bg.animation.play('idle');
			bg.scrollFactor.set(0.8, 0.9);
			bg.scale.set(6, 6);
			add(bg);

			/* 
				var bg:FlxSprite = new FlxSprite(posX, posY).loadGraphic('assets/images/weeb/evilSchoolBG.png');
				bg.scale.set(6, 6);
				// bg.setGraphicSize(Std.int(bg.width * 6));
				// bg.updateHitbox();
				add(bg);

				var fg:FlxSprite = new FlxSprite(posX, posY).loadGraphic('assets/images/weeb/evilSchoolFG.png');
				fg.scale.set(6, 6);
				// fg.setGraphicSize(Std.int(fg.width * 6));
				// fg.updateHitbox();
				add(fg);

				wiggleShit.effectType = WiggleEffectType.DREAMY;
				wiggleShit.waveAmplitude = 0.01;
				wiggleShit.waveFrequency = 60;
				wiggleShit.waveSpeed = 0.8;
			 */

			// bg.shader = wiggleShit.shader;
			// fg.shader = wiggleShit.shader;

			/* 
				var waveSprite = new FlxEffectSprite(bg, [waveEffectBG]);
				var waveSpriteFG = new FlxEffectSprite(fg, [waveEffectFG]);

				// Using scale since setGraphicSize() doesnt work???
				waveSprite.scale.set(6, 6);
				waveSpriteFG.scale.set(6, 6);
				waveSprite.setPosition(posX, posY);
				waveSpriteFG.setPosition(posX, posY);

				waveSprite.scrollFactor.set(0.7, 0.8);
				waveSpriteFG.scrollFactor.set(0.9, 0.8);

				// waveSprite.setGraphicSize(Std.int(waveSprite.width * 6));
				// waveSprite.updateHitbox();
				// waveSpriteFG.setGraphicSize(Std.int(fg.width * 6));
				// waveSpriteFG.updateHitbox();

				add(waveSprite);
				add(waveSpriteFG);
			 */
		} else if(Name == 'pre-mortal' || Name == 'post-mortal'){
			defaultCamZoom = 0.63;
			curStage = 'hallway';
			var bg:FlxSprite = new FlxSprite(-360, -210).loadGraphic('assets/images/cry some more/g.png');
			bg.scrollFactor.set(1, 1);
			bg.active = false;
			add(bg);
		}
		else
		{
			defaultCamZoom = 0.9;
			curStage = 'stage';
			var bg:FlxSprite = new FlxSprite(-600, -200).loadGraphic('assets/images/stageback.png');
			bg.antialiasing = true;
			bg.scrollFactor.set(0.9, 0.9);
			bg.active = false;
			add(bg);

			var stageFront:FlxSprite = new FlxSprite(-650, 600).loadGraphic('assets/images/stagefront.png');
			stageFront.setGraphicSize(Std.int(stageFront.width * 1.1));
			stageFront.updateHitbox();
			stageFront.antialiasing = true;
			stageFront.scrollFactor.set(0.9, 0.9);
			stageFront.active = false;
			add(stageFront);

			var stageCurtains:FlxSprite = new FlxSprite(-500, -300).loadGraphic('assets/images/stagecurtains.png');
			stageCurtains.setGraphicSize(Std.int(stageCurtains.width * 0.9));
			stageCurtains.updateHitbox();
			stageCurtains.antialiasing = true;
			stageCurtains.scrollFactor.set(1.3, 1.3);
			stageCurtains.active = false;

			add(stageCurtains);
		}

		var gfVersion:String = 'gf';

		switch (curStage)
		{
			case 'limo':
				gfVersion = 'gf-car';
			case 'mall' | 'mallEvil':
				gfVersion = 'gf-christmas';
			case 'school':
				gfVersion = 'gf-pixel';
			case 'schoolEvil':
				gfVersion = 'gf-pixel';
			case 'spacetime':
				gfVersion = 'gf-pixel';
		}

		if (curStage == 'limo')
			gfVersion = 'gf-car';

		gf = new Character(400, 130, gfVersion);
		gf.scrollFactor.set(0.95, 0.95);
		
		var alreadyOpheebop:Bool = false;
		var DynamicKey:Dynamic = Highscore.getRaw("OH SHI");
		if(DynamicKey != null && SONG.player1.startsWith('bf')){
			alreadyOpheebop = DynamicKey;
		}
		if(SONG.player1 == 'opheebop-fix' && !alreadyOpheebop){
			Highscore.setRaw("OH SHI", true);
			alreadyOpheebop = true;
		}
		if(alreadyOpheebop){
			var temp:String = ""+SONG.player1;
			SONG.player1 = 'opheebop-fix';
			if(SONG.player2 == 'opheebop-fix')
				SONG.player2 = temp;
		}

		dad = new Character(100, 100, SONG.player2);

		var camPos:FlxPoint = new FlxPoint(dad.getGraphicMidpoint().x, dad.getGraphicMidpoint().y);

		switch (SONG.player2)
		{
			case 'gf':
				dad.setPosition(gf.x, gf.y);
				gf.visible = false;
				if (isStoryMode)
				{
					camPos.x += 600;
					// tweenCamIn();
				}
			case 'opheebop', 'bf-pixel', 'bf':
				dad.y += 350;
			case "spooky":
				dad.y += 200;
			case "haxeflixel":
				dad.y -= 200;
			case "monster":
				dad.y += 100;
			case 'monster-christmas', 'opheebop-fix':
				dad.y += 130;
			case 'dad':
				camPos.x += 400;
			case 'pico':
				camPos.x += 600;
				dad.y += 300;
			case 'parents-christmas':
				dad.x -= 500;
			case 'senpai':
				dad.x += 150;
				dad.y += 360;
				camPos.set(dad.getGraphicMidpoint().x + 300, dad.getGraphicMidpoint().y);
			case 'senpai-angry':
				dad.x += 150;
				dad.y += 360;
				camPos.set(dad.getGraphicMidpoint().x + 300, dad.getGraphicMidpoint().y);
			case 'spirit':
				dad.x -= 150;
				dad.y += 100;
				camPos.set(dad.getGraphicMidpoint().x + 300, dad.getGraphicMidpoint().y);
		}
		
		if(bti(SONG.actors) > 1){
			for(i in 1...SONG.actors){
				var o:Array<Float> = SONG.offsets[i-1];
				var cdad = new Character(100 - (i*120) + o[0], 100 + (i*20) + o[1], SONG.excessPlayers[i-1]);

				switch (SONG.excessPlayers[i-1])
				{
					case 'gf':
						cdad.setPosition(gf.x, gf.y);
						gf.visible = false;
					case 'opheebop', 'bf':
						cdad.y += 350;
					case 'bf-pixel':
						cdad.y += 500;
					case "spooky":
						cdad.y += 200;
					case "haxeflixel":
						cdad.y -= 200;
					case "monster":
						cdad.y += 100;
					case 'monster-christmas', 'opheebop-fix':
						cdad.y += 130;
					case 'pico':
						cdad.y += 300;
					case 'parents-christmas':
						cdad.x -= 500;
					case 'senpai':
						cdad.x += 150;
						cdad.y += 360;
					case 'senpai-angry':
						cdad.x += 150;
						cdad.y += 360;
					case 'spirit':
						cdad.x -= 150;
						cdad.y += 100;
				}
				morePlayers.push(cdad);
			}
		}

		boyfriend = new Boyfriend(770, 450, SONG.player1);
		
		switch(SONG.player1){
			case 'opheebop-fix': // my fever dreams are real
				boyfriend.y -= 220;
			case 'haxeflixel': // HaxeFlixel???? 😳😳😳😳😳😳😳😳😳😳😳😳😳😳😳😳😳😳😳😳😳😳😳😳😳😳😳😳😳😳😳😳😳😳😳😳😳😳😳😳😳😳😳😳😳😳😳😳😳😳😳😳😳😳😳😳😳😳😳😳😳😳😳😳😳😳😳😳😳😳
				boyfriend.y -= 350;
				boyfriend.x -= 200;
		}

		// REPOSITIONING PER STAGE
		switch (curStage)
		{
			case 'limo':
				boyfriend.y -= 220;
				boyfriend.x += 260;

				resetFastCar();
				add(fastCar);

			case 'mall':
				boyfriend.x += 200;

			case 'mallEvil':
				boyfriend.x += 320;
				dad.y -= 80;
			case 'school':
				boyfriend.x += 200;
				boyfriend.y += 220;
				gf.x += 180;
				gf.y += 300;
			case 'schoolEvil':
				// trailArea.scrollFactor.set();

				var evilTrail = new FlxTrail(dad, null, 4, 24, 0.3, 0.069);
				// evilTrail.changeValuesEnabled(false, false, false, false);
				// evilTrail.changeGraphic()
				add(evilTrail);
				// evilTrail.scrollFactor.set(1.1, 1.1);

				boyfriend.x += 200;
				boyfriend.y += 220;
				gf.x += 180;
				gf.y += 300;
		}

		add(gf);

		// Shitty layering but whatev it works LOL
		if (curStage == 'limo')
			add(limo);

		add(dad);
		for(i in morePlayers)
			add(i);
		add(boyfriend);

		doof = new DialogueBox(false, dialogue);
		// doof.x += 70;
		// doof.y = FlxG.height * 0.5;
		doof.scrollFactor.set();
		doof.finishThing = startCountdown;
		Conductor.songPosition = -5000;
		strumLine = new FlxSprite(0, downscroll ? FlxG.height * 0.66 : 50).makeGraphic(FlxG.width, 10);
		strumLine.scrollFactor.set();

		strumLineNotes = new FlxTypedGroup<FlxSprite>();
		add(strumLineNotes);

		playerStrums = new FlxTypedGroup<FlxSprite>();

		// startCountdown();

		generateSong(SONG.song);

		// add(strumLine);

		camFollow = new FlxObject(0, 0, 1, 1);

		camFollow.setPosition(camPos.x, camPos.y);

		if (prevCamFollow != null)
		{
			camFollow = prevCamFollow;
			prevCamFollow = null;
		}

		add(camFollow);

		FlxG.camera.follow(camFollow, LOCKON, 0.04);
		// FlxG.camera.setScrollBounds(0, FlxG.width, 0, FlxG.height);
		FlxG.camera.zoom = defaultCamZoom;
		FlxG.camera.focusOn(camFollow.getPosition());

		FlxG.worldBounds.set(0, 0, FlxG.width, FlxG.height);

		FlxG.fixedTimestep = false;
		healthBarBG = new FlxSprite(0, FlxG.height * 0.86).loadGraphic('assets/images/healthBar.png');
		healthBarBG.screenCenter(X);
		healthBarBG.scrollFactor.set();
		add(healthBarBG);
		
		TimeBarBG = new FlxSprite(0, FlxG.height * 0.04).loadGraphic('assets/images/healthBar.png');
		TimeBarBG.screenCenter(X);
		TimeBarBG.scrollFactor.set();
		add(TimeBarBG);

		healthBar = new FlxBar(healthBarBG.x + 4, healthBarBG.y + 4, RIGHT_TO_LEFT, Std.int(healthBarBG.width - 8), Std.int(healthBarBG.height - 8), this,
			'health', 0, 2);
		healthBar.scrollFactor.set();
		healthBar.createFilledBar(0xFFFF0000, 0xFF66FF33);
		// healthBar
		add(healthBar);

		TimeBar = new FlxBar(TimeBarBG.x + 4, TimeBarBG.y + 4, RIGHT_TO_LEFT, Std.int(TimeBarBG.width - 8), Std.int(TimeBarBG.height - 8), this,
			'passer', 0, 2);
		TimeBar.scrollFactor.set();
		TimeBar.createFilledBar(0xFF66FF33, 0xFF888888);
		// healthBar
		add(TimeBar);

		scoreTxt = new FlxText(healthBarBG.x + healthBarBG.width - 190, (FlxG.height * 0.9) + 10, 0, "", 20);
		auxTxt = new FlxText(healthBarBG.x + healthBarBG.width - 190, (FlxG.height * 0.9) + 30, 0, "", 20); // score text line 2
		scoreTxt.setFormat("assets/fonts/vcr.ttf", 16, FlxColor.WHITE, RIGHT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK); // right is super fucking redundant here, because right-align is automatically done while processing the score
		auxTxt.setFormat("assets/fonts/vcr.ttf", 16, FlxColor.WHITE, RIGHT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK); // right is still done, and I still have to do this for formatting purposes
		scoreTxt.scrollFactor.set();
		auxTxt.scrollFactor.set();
		add(scoreTxt);
		add(auxTxt);

		iconP1 = new HealthIcon(SONG.player1, true);
		iconP1.y = healthBar.y - (iconP1.height / 2);
		add(iconP1);

		iconP2 = new HealthIcon(SONG.player2, false);
		iconP2.y = healthBar.y - (iconP2.height / 2);
		add(iconP2);

		strumLineNotes.cameras = [camHUD];
		notes.cameras = [camHPHUD];
		healthBar.cameras = [camHUD];
		healthBarBG.cameras = [camHUD];
		TimeBar.cameras = [camHUD];
		TimeBarBG.cameras = [camHUD];
		iconP1.cameras = [camHUD];
		iconP2.cameras = [camHUD];
		scoreTxt.cameras = [camHUD];
		auxTxt.cameras = [camHUD];
		doof.cameras = [camHUD];

		// if (SONG.song == 'South')
		// FlxG.camera.alpha = 0.7;
		// UI_camera.zoom = 1;

		// cameras = [FlxG.cameras.list[1]];
		startingSong = true;

		if (isStoryMode)
		{
			switch (curSong.toLowerCase())
			{
				case "winter-horrorland":
					var blackScreen:FlxSprite = new FlxSprite(0, 0).makeGraphic(Std.int(FlxG.width * 2), Std.int(FlxG.height * 2), FlxColor.BLACK);
					add(blackScreen);
					blackScreen.scrollFactor.set();
					camHUD.visible = false;

					new FlxTimer().start(0.1, function(tmr:FlxTimer)
					{
						remove(blackScreen);
						FlxG.sound.play('assets/sounds/Lights_Turn_On' + TitleState.soundExt);
						camFollow.y = -2050;
						camFollow.x += 200;
						FlxG.camera.focusOn(camFollow.getPosition());
						FlxG.camera.zoom = 1.5;

						new FlxTimer().start(0.8, function(tmr:FlxTimer)
						{
							camHUD.visible = true;
							remove(blackScreen);
							FlxTween.tween(FlxG.camera, {zoom: defaultCamZoom}, 2.5, {
								ease: FlxEase.quadInOut,
								onComplete: function(twn:FlxTween)
								{
									startCountdown();
								}
							});
						});
					});
				case 'senpai':
					schoolIntro(doof);
				case 'roses':
					FlxG.sound.play('assets/sounds/ANGRY' + TitleState.soundExt);
					schoolIntro(doof);
				case 'thorns':
					schoolIntro(doof);
				default:
					if(dialogue != null && PlayState.isStoryMode){
						if(dialogue.length == 0){
							startCountdown();
						} else {
							inCutscene = true;
							add(doof);
						}
					} else
						startCountdown();
			}
		}
		else
		{
			switch (curSong.toLowerCase())
			{
				default:
					startCountdown();
			}
		}
		bbdetect = new BlueBalls(this);
		super.create();
	}

	function schoolIntro(?dialogueBox:DialogueBox):Void
	{
		var black:FlxSprite = new FlxSprite(-100, -100).makeGraphic(FlxG.width * 2, FlxG.height * 2, FlxColor.BLACK);
		black.scrollFactor.set();
		add(black);

		var red:FlxSprite = new FlxSprite(-100, -100).makeGraphic(FlxG.width * 2, FlxG.height * 2, 0xFFff1b31);
		red.scrollFactor.set();

		var senpaiEvil:FlxSprite = new FlxSprite();
		senpaiEvil.frames = FlxAtlasFrames.fromSparrow('assets/images/weeb/senpaiCrazy.png', 'assets/images/weeb/senpaiCrazy.xml');
		senpaiEvil.animation.addByPrefix('idle', 'Senpai Pre Explosion', 24, false);
		senpaiEvil.setGraphicSize(Std.int(senpaiEvil.width * 6));
		senpaiEvil.scrollFactor.set();
		senpaiEvil.updateHitbox();
		senpaiEvil.screenCenter();

		if (SONG.song.toLowerCase() == 'roses' || SONG.song.toLowerCase() == 'thorns')
		{
			remove(black);

			if (SONG.song.toLowerCase() == 'thorns')
			{
				add(red);
			}
		}

		new FlxTimer().start(0.3, function(tmr:FlxTimer)
		{
			black.alpha -= 0.15;

			if (black.alpha > 0)
			{
				tmr.reset(0.3);
			}
			else
			{
				if (dialogueBox != null)
				{
					inCutscene = true;

					if (SONG.song.toLowerCase() == 'thorns')
					{
						add(senpaiEvil);
						senpaiEvil.alpha = 0;
						new FlxTimer().start(0.3, function(swagTimer:FlxTimer)
						{
							senpaiEvil.alpha += 0.15;
							if (senpaiEvil.alpha < 1)
							{
								swagTimer.reset();
							}
							else
							{
								senpaiEvil.animation.play('idle');
								FlxG.sound.play('assets/sounds/Senpai_Dies' + TitleState.soundExt, 1, false, null, true, function()
								{
									remove(senpaiEvil);
									remove(red);
									FlxG.camera.fade(FlxColor.WHITE, 0.01, true, function()
									{
										add(dialogueBox);
									}, true);
								});
								new FlxTimer().start(3.2, function(deadTime:FlxTimer)
								{
									FlxG.camera.fade(FlxColor.WHITE, 1.6, false);
								});
							}
						});
					}
					else
					{
						add(dialogueBox);
					}
				}
				else
					startCountdown();

				remove(black);
			}
		});
	}

	var startTimer:FlxTimer;
	var perfectMode:Bool = false;

	function startCountdown():Void
	{
		inCutscene = false;
		talking = false;
		startedCountdown = true;
		generateStaticArrows(0);
		generateStaticArrows(1);
		Conductor.songPosition = 0;
		Conductor.songPosition -= Conductor.crochet * 5;
		var Keepaway:Bool = true;
		if(!Keepaway){
		}
		var swagCounter:Int = 0;
		var piss:FlxTimer;
		var Fuck:FlxTimer->Void = function(_:FlxTimer) {
			startTimer = new FlxTimer().start(Conductor.crochet / 1000, function(tmr:FlxTimer)
			{
				dad.dance();
				gf.dance();
				for(i in morePlayers){
					i.dance();
				}
				try {
					boyfriend.playAnim('idle');
				} catch(e) {
					// nothing
				}
				var introAssets:Map<String, Array<String>> = new Map<String, Array<String>>();
				introAssets.set('default', ['ready.png', "set.png", "go.png"]);
				introAssets.set('school', [
					'weeb/pixelUI/ready-pixel.png',
					'weeb/pixelUI/set-pixel.png',
					'weeb/pixelUI/date-pixel.png'
				]);
				introAssets.set('schoolEvil', [
					'weeb/pixelUI/ready-pixel.png',
					'weeb/pixelUI/set-pixel.png',
					'weeb/pixelUI/date-pixel.png'
				]);

				var introAlts:Array<String> = introAssets.get('default');
				var altSuffix:String = "";

				for (value in introAssets.keys())
				{
					if (value == curStage)
					{
						introAlts = introAssets.get(value);
						altSuffix = '-pixel';
					}
				}

				switch (swagCounter)

				{
					case 0:
						FlxG.sound.play('assets/sounds/intro3' + altSuffix + TitleState.soundExt, 0.6);
					case 1:
						var ready:FlxSprite = new FlxSprite().loadGraphic('assets/images/' + introAlts[0]);
						ready.scrollFactor.set();
						ready.updateHitbox();

						if (curStage.startsWith('school'))
							ready.setGraphicSize(Std.int(ready.width * daPixelZoom));

						ready.screenCenter();
						add(ready);
						FlxTween.tween(ready, {y: ready.y += 100, alpha: 0}, Conductor.crochet / 1000, {
							ease: FlxEase.cubeInOut,
							onComplete: function(twn:FlxTween)
							{
								ready.destroy();
							}
						});
						FlxG.sound.play('assets/sounds/intro2' + altSuffix + TitleState.soundExt, 0.6);
					case 2:
						var set:FlxSprite = new FlxSprite().loadGraphic('assets/images/' + introAlts[1]);
						set.scrollFactor.set();

						if (curStage.startsWith('school'))
							set.setGraphicSize(Std.int(set.width * daPixelZoom));

						set.screenCenter();
						add(set);
						FlxTween.tween(set, {y: set.y += 100, alpha: 0}, Conductor.crochet / 1000, {
							ease: FlxEase.cubeInOut,
							onComplete: function(twn:FlxTween)
							{
								set.destroy();
							}
						});
						FlxG.sound.play('assets/sounds/intro1' + altSuffix + TitleState.soundExt, 0.6);
					case 3:
						var go:FlxSprite = new FlxSprite().loadGraphic('assets/images/' + introAlts[2]);
						go.scrollFactor.set();

						if (curStage.startsWith('school'))
							go.setGraphicSize(Std.int(go.width * daPixelZoom));

						go.updateHitbox();

						go.screenCenter();
						add(go);
						FlxTween.tween(go, {y: go.y += 100, alpha: 0}, Conductor.crochet / 1000, {
							ease: FlxEase.cubeInOut,
							onComplete: function(twn:FlxTween)
							{
								go.destroy();
							}
						});
						FlxG.sound.play('assets/sounds/introGo' + altSuffix + TitleState.soundExt, 0.6);
					case 4:
				}

				swagCounter++;
				// generateSong('fresh');
			}, 2147483647);
		}
			
		if(bti(SONG.clf) >= 0)
			piss = new FlxTimer().start((Conductor.crochet / 1000) * (SONG.clf + 1) * 4, Fuck);
		else
			Fuck(new FlxTimer());
	}

	var previousFrameTime:Int = 0;
	var lastReportedPlayheadPosition:Int = 0;
	var songTime:Float = 0;
	var wtf:Bool = false;
	var testOffsets:Array<Int> = [0, 0];
	var window:Window;
	function startSong():Void
	{
		window = Application.current.window;
		testOffsets = [window.x, window.y];
		startingSong = false;
		trace('started song, bot type $botType', unspawnNotes.length, bot);
		for(i in unspawnNotes) {
			if(i != null)
				if(bot && botType == 1 && i.mustPress) {
					i.active = true;
					i.KillMe();
				}
		}
		previousFrameTime = FlxG.game.ticks;
		lastReportedPlayheadPosition = 0;
		Main.play();
		wtf = true;
		if (!paused)
			FlxG.sound.playMusic("assets/music/" + SONG.song + "_Inst" + TitleState.soundExt, 1, false);
		FlxG.sound.music.onComplete = endSong;
		vocals.play();
		Main.timestamp(FlxG.sound.music.length / 1000);
	}

	var debugNum:Int = 0;
	private var mustHitPain:Array<Bool> = [];
	private function generateSong(dataPath:String):Void
	{
		// FlxG.log.add(ChartParser.parse());

		var songData = SONG;
		Conductor.changeBPM(songData.bpm);

		curSong = songData.song;

		if (SONG.needsVoices)
			vocals = new FlxSound().loadEmbedded("assets/music/" + curSong + "_Voices" + TitleState.soundExt);
		else
			vocals = new FlxSound();

		FlxG.sound.list.add(vocals);

		notes = new FlxTypedGroup<Note>();
		add(notes);

		var noteData:Array<SwagSection>;
		var noteCount:Int = ninefret ? 9 : sixfret ? 6 : 4;

		// NEW SHIT
		noteData = songData.notes;

		var playerCounter:Int = 0;

		var daBeats:Int = 0; // Not exactly representative of 'daBeats' lol, just how much it has looped
		for (section in noteData)
		{
			var alreadyPushed:Bool = false;
			var coolSection:Int = Std.int(section.lengthInSteps / 4);

			for (songNotes in section.sectionNotes)
			{
				var daStrumTime:Float = songNotes[0];
				var daNoteData:Int = Std.int(songNotes[1] % 5);
				var RAWcat:Dynamic = songNotes[3];
				var RAWrrjmiakfnjksnsdjfesuigfuiafndifgvberuiagboiaenrboavonvoeanfoiwenfwaeoibfiodewasafnewoibvgaewiobaueifewioafe:Dynamic = songNotes[4];
				var daCat:Int = 0;
				var RAWactor:Dynamic = songNotes[5];
				var daActor:Int = 0;
				var Why:Int = 0;
				if(RAWcat != null)
					daCat = RAWcat;
				if(RAWrrjmiakfnjksnsdjfesuigfuiafndifgvberuiagboiaenrboavonvoeanfoiwenfwaeoibfiodewasafnewoibvgaewiobaueifewioafe != null)
					Why = bti(RAWrrjmiakfnjksnsdjfesuigfuiafndifgvberuiagboiaenrboavonvoeanfoiwenfwaeoibfiodewasafnewoibvgaewiobaueifewioafe);
				if(RAWactor != null)
					daActor = RAWactor;
				var gottaHitNote:Bool = section.mustHitSection;

				if (songNotes[1] > 4)
				{
					gottaHitNote = !section.mustHitSection;
				}
				
				if(!alreadyPushed && gottaHitNote){
					mustHitPain.push(true);
					alreadyPushed = true;
				}
				
				var oldNote:Note;
				if (unspawnNotes.length > 0)
					oldNote = unspawnNotes[Std.int(unspawnNotes.length - 1)];
				else
					oldNote = null;

				var swagNote:Note = new Note(daStrumTime, daNoteData, daCat, oldNote, false, true, Why, daActor);
				swagNote.sustainLength = songNotes[2];
				swagNote.scrollFactor.set(0, 0);

				var susLength:Float = swagNote.sustainLength;
				var crochetShit:Float = Conductor.stepCrochet;
				susLength = susLength / crochetShit;
				unspawnNotes.push(swagNote);

				for (susNote in 0...Math.floor(susLength))
				{
					oldNote = unspawnNotes[Std.int(unspawnNotes.length - 1)];

					var sustainNote:Note = new Note(daStrumTime + (crochetShit * susNote) + Conductor.stepCrochet, daNoteData, daCat, oldNote, true, true, Why, daActor);
					sustainNote.scrollFactor.set();
					unspawnNotes.push(sustainNote);

					sustainNote.mustPress = gottaHitNote;

					if (sustainNote.mustPress)
					{
						if(centeredNotes)
							sustainNote.x -= (Note.swagWidth * (noteCount / 2)) + 50;
						sustainNote.x += FlxG.width / 2; // general offset
					}
				}

				swagNote.mustPress = gottaHitNote;

				if (swagNote.mustPress)
				{
					if(centeredNotes)
						swagNote.x -= (Note.swagWidth * (noteCount / 2)) + 50;
					swagNote.x += FlxG.width / 2; // general offset
				}
				else
				{
				}
			}
			if(!alreadyPushed){
				mustHitPain.push(false);
			}
			daBeats++;
		}
		// trace(unspawnNotes.length);
		// playerCounter += 1;

		unspawnNotes.sort(sortByShit);

		generatedMusic = true;
	}

	function sortByShit(Obj1:Note, Obj2:Note):Int
	{
		return FlxSort.byValues(FlxSort.ASCENDING, Obj1.strumTime, Obj2.strumTime);
	}


	private function generateStaticArrows(player:Int):Void
	{
		var m:Int = 4;
		if(sixfret){
			m = 6;
		}
		if(ninefret)
			m = 9;
		var Cursed:Bool = false;
		var DynamicKey:Dynamic = Highscore.getRaw("OH SHI");
		if(DynamicKey != null){
			Cursed = DynamicKey;
		}
		for (i in 0...m)
		{
			// FlxG.log.add(i);
			var babyArrow:FlxSprite = new FlxSprite(0, strumLine.y);
			switch (curStage)
			{
				case 'school' | 'schoolEvil' | 'spacetime':
					
					babyArrow.loadGraphic('assets/images/weeb/pixelUI/arrows-pixels.png', true, 17, 17);
					babyArrow.animation.add('green', [8]);
					babyArrow.animation.add('red', [9]);
					babyArrow.animation.add('blue', [7]);
					babyArrow.animation.add('purplel', [6]);
					babyArrow.animation.add('purpleb', [10]);
					babyArrow.animation.add('redb', [11]);
					// https://www.youtube.com/watch?v=Xr4Fp9Nx-tQ
					// Donno why this was pasted here
					babyArrow.setGraphicSize(Std.int(babyArrow.width * daPixelZoom));
					babyArrow.updateHitbox();
					babyArrow.antialiasing = false;

					switch (Math.abs(i))
					{
						case 0:
							babyArrow.animation.add('static', [0]);
							babyArrow.animation.add('pressed', [6, 12], 12, false);
							babyArrow.animation.add('confirm', [18, 24], 24, false);
						case 1:
							babyArrow.x += Note.swagWidth * 1;
							if(sixfret){
								babyArrow.animation.add('static', [2]);
								babyArrow.animation.add('pressed', [8, 14], 12, false);
								babyArrow.animation.add('confirm', [20, 26], 24, false);
							} else {
								babyArrow.animation.add('static', [1]);
								babyArrow.animation.add('pressed', [7, 13], 12, false);
								babyArrow.animation.add('confirm', [19, 25], 24, false);
							}
						case 2:
							babyArrow.x += Note.swagWidth * 2;
							if(sixfret){
								babyArrow.animation.add('static', [3]);
								babyArrow.animation.add('pressed', [9, 15], 12, false);
								babyArrow.animation.add('confirm', [21, 27], 24, false);
							} else {
								babyArrow.animation.add('static', [2]);
								babyArrow.animation.add('pressed', [8, 14], 12, false);
								babyArrow.animation.add('confirm', [20, 26], 24, false);
							}
						case 3:
							babyArrow.x += Note.swagWidth * 3;
							if(sixfret){
								babyArrow.animation.add('static', [4]);
								babyArrow.animation.add('pressed', [10, 16], 12, false);
								babyArrow.animation.add('confirm', [22, 28], 24, false);
							} else {
								babyArrow.animation.add('static', [3]);
								babyArrow.animation.add('pressed', [9, 15], 12, false);
								babyArrow.animation.add('confirm', [21, 27], 24, false);
							}
						case 4:
							babyArrow.x += Note.swagWidth * 4;
							babyArrow.animation.add('static', [1]);
							babyArrow.animation.add('pressed', [7, 13], 12, false);
							babyArrow.animation.add('confirm', [19, 25], 24, false);
						case 5:
							babyArrow.x += Note.swagWidth * 5;
							babyArrow.animation.add('static', [5]);
							babyArrow.animation.add('pressed', [11, 17], 12, false);
							babyArrow.animation.add('confirm', [23, 29], 24, false);
					}

				default:
					babyArrow.frames = FlxAtlasFrames.fromSparrow(
						ninefret ? 
						'assets/images/jic/NOTE_assets.png' :
						Cursed ?
						'assets/images/cursedclient.png' :
						ip ? 
						'assets/images/precision.png' :
						'assets/images/NOTE_assets.png',
						ninefret ? 
						'assets/images/jic/NOTE_assets.xml' :
						'assets/images/NOTE_assets.xml');
					babyArrow.animation.addByPrefix('green', 'arrowUP');
					babyArrow.animation.addByPrefix('blue', 'arrowDOWN');
					babyArrow.animation.addByPrefix('purple', 'arrowLEFT');
					babyArrow.animation.addByPrefix('red', 'arrowRIGHT');

					babyArrow.antialiasing = true;
					babyArrow.setGraphicSize(Std.int(babyArrow.width * 0.7));

					switch (Math.abs(i))
					{
						case 0:
							babyArrow.animation.addByPrefix('static', 'arrowLEFT');
							babyArrow.animation.addByPrefix('pressed', 'left press', 24, false);
							babyArrow.animation.addByPrefix('confirm', 'left confirm', 24, false);
						case 1:
							babyArrow.x += Note.swagWidth * 1;
							babyArrow.animation.addByPrefix('static', sixfret ? 'arrowUP' : 'arrowDOWN');
							babyArrow.animation.addByPrefix('pressed', sixfret ? 'up press' : 'down press', 24, false);
							babyArrow.animation.addByPrefix('confirm', sixfret ? 'up confirm' : 'down confirm', 24, false);
						case 2:
							babyArrow.x += Note.swagWidth * 2;
							babyArrow.animation.addByPrefix('static', sixfret ? 'arrowRIGHT' : 'arrowUP');
							babyArrow.animation.addByPrefix('pressed', sixfret ? 'right press' : 'up press', 24, false);
							babyArrow.animation.addByPrefix('confirm', sixfret ? 'right confirm' : 'up confirm', 24, false);
						case 3:
							babyArrow.x += Note.swagWidth * 3;
							babyArrow.animation.addByPrefix('static', sixfret ? 'arrowLEFT' : 'arrowRIGHT');
							babyArrow.animation.addByPrefix('pressed', sixfret ? (ip||Cursed ? 'left press' : 'leftb press') : 'right press', 24, false);
							babyArrow.animation.addByPrefix('confirm',sixfret ? (ip||Cursed ? 'left confirm' : 'leftb confirm') : 'right confirm', 24, false);
						case 4:
							babyArrow.x += Note.swagWidth * 4;
							if(ninefret){
								babyArrow.animation.addByPrefix('static', 'arrowSPACE');
								babyArrow.animation.addByPrefix('pressed', 'white press', 24, false);
								babyArrow.animation.addByPrefix('confirm', 'white confirm', 24, false);
							}else{
								babyArrow.animation.addByPrefix('static', 'arrowDOWN');
								babyArrow.animation.addByPrefix('pressed', 'down press', 24, false);
								babyArrow.animation.addByPrefix('confirm', 'down confirm', 24, false);
							}
						case 5:
							babyArrow.x += Note.swagWidth * 5;
							if(ninefret){
								babyArrow.animation.addByPrefix('static', 'arrowLEFT');
								babyArrow.animation.addByPrefix('pressed', 'yel press', 24, false);
								babyArrow.animation.addByPrefix('confirm', 'yel confirm', 24, false);
							}else{
								babyArrow.animation.addByPrefix('static', 'arrowRIGHT');
								babyArrow.animation.addByPrefix('pressed', ip||Cursed ?  'right press' : 'rightb press', 24, false);
								babyArrow.animation.addByPrefix('confirm', ip||Cursed ? 'right confirm' : 'rightb confirm', 24, false);
							}
						case 6:
							babyArrow.x += Note.swagWidth * 6;
							babyArrow.animation.addByPrefix('static', 'arrowUP');
							babyArrow.animation.addByPrefix('pressed', 'violet press', 24, false);
							babyArrow.animation.addByPrefix('confirm', 'violet confirm', 24, false);
							babyArrow.flipY = true;
						case 7:
							babyArrow.x += Note.swagWidth * 7;
							babyArrow.animation.addByPrefix('static', 'arrowDOWN');
							babyArrow.animation.addByPrefix('pressed', 'black press', 24, false);
							babyArrow.animation.addByPrefix('confirm', 'black confirm', 24, false);
							babyArrow.flipY = true;
						case 8:
							babyArrow.x += Note.swagWidth * 8;
							babyArrow.animation.addByPrefix('static', 'arrowRIGHT');
							babyArrow.animation.addByPrefix('pressed', 'dark press', 24, false);
							babyArrow.animation.addByPrefix('confirm', 'dark confirm', 24, false);
					}
			}

			if(ninefret){
				babyArrow.scale.x *= (0.55/0.7);
				babyArrow.scale.y *= (0.55/0.7);
			}

			babyArrow.updateHitbox();
			babyArrow.scrollFactor.set();

			if (!isStoryMode)
			{
				babyArrow.y -= 10;
				babyArrow.alpha = 0;
				FlxTween.tween(babyArrow, {y: babyArrow.y + 10, alpha: 1}, 1, {ease: FlxEase.circOut, startDelay: 0.5 + (0.2 * i)});
			}

			babyArrow.ID = i;

			if (player == 1)
			{
				playerStrums.add(babyArrow);
			}

			babyArrow.animation.play('static');
			babyArrow.x += 50;
			if(centeredNotes){
				if(player == 0)
					babyArrow.visible = false;
				babyArrow.x += (FlxG.width / 2) - (Note.swagWidth * (m / 2)) - 50;
			} else
				babyArrow.x += ((FlxG.width / 2) * player);

			strumLineNotes.add(babyArrow);
		}
	}

	function tweenCamIn():Void
	{
		FlxTween.tween(FlxG.camera, {zoom: 1.3}, (Conductor.stepCrochet * 4 / 1000), {ease: FlxEase.elasticInOut});
	}

	override function openSubState(SubState:FlxSubState)
	{
		if (paused)
		{
			if (FlxG.sound.music != null)
			{
				FlxG.sound.music.pause();
				vocals.pause();
			}
			try {
				if (!startTimer.finished)
					startTimer.active = false;
			} catch(_e) {
				//BugHandlerState.text = "START TIMER ACCESSED BEFORE INIT";
				//FlxG.switchState(new BugHandlerState());
			}
		}

		super.openSubState(SubState);
	}
	override function closeSubState()
	{
		if (paused)
		{
			if (FlxG.sound.music != null && !startingSong)
			{
				resyncVocals();
			}
			try {
				if (!startTimer.finished)
					startTimer.active = true;
				paused = false;
				if(!startingSong)
				{
					Main.timestamp((FlxG.sound.music.length - FlxG.sound.music.time) / 1000);
					Main.setstate(SONG.song);
					Main.play();
				}
			} catch(_e) {
				//BugHandlerState.text = "START TIMER ACCESSED BEFORE INIT";
				//FlxG.switchState(new BugHandlerState());
			}
		}

		super.closeSubState();
	}
	public static var toDestroy:Array<Note> = [];
	function resyncVocals():Void
	{
		vocals.pause();

		FlxG.sound.music.play();
		Conductor.songPosition = FlxG.sound.music.time;
		vocals.time = Conductor.songPosition;
		vocals.play();
	}
	public static function rewind(time:Float){
		FlxG.sound.music.pause();
		FlxG.sound.music.time -= (time*1000);
		vocals.pause();
		vocals.time -= (time*1000);
		FlxG.sound.music.play();
		vocals.play();
		Conductor.songPosition -= (time*1000);
		var c:Int = 0;
		var splices:Array<Int> = [];
		for(i in toDestroy){
			///////////////////////////////////////trace('difference '+(i.strumTime - Conductor.songPosition), 'strumdata '+i.noteData);
			if(i.strumTime - Conductor.songPosition < (time*1000) && i.strumTime - Conductor.songPosition > 0){
				i.revive();
				i.wasGoodHit = false;
				i.tooLate = false;
				//i.active = true;
				i.canBeHit = false;
				i.alive = true;
				healthj += 0.00475;
				notes.add(i);
				splices.unshift(c);
			}
			c++;
		}
		for(i in splices){
			toDestroy.splice(i, 1);
		}
	}
	public static function commafy(inum:Float, campaign:Bool = false){
		if(campaign && !isStoryMode) // campaign score outside of story mode shouldn't be possible
			return "---";
		if(inum < 0) // negatives won't work unless I do this
			return '-${commafy(-inum, campaign)}';
		else if(inum == 0) // it'll treat 0 as if it didn't exist
			return "0";
		var o:Array<String> = [];
		while(inum > 0){
			var n = "" + (inum % 1000);
			if(inum / 1000 >= 1)
				n = StringTools.lpad(n, "0", 3);
			o.unshift(n);
			inum = Math.floor(inum / 1000);
		}
		return o.join(',');
	}
	function fcampaigns(){
		if(isStoryMode)
			return ' | CURRENT CAMPAIGN SCORE: ${commafy(campaignScore + songScore, true)}';
		return "";
	}
	function pFormat(){
		var Grade = ["D", "C", "B", "A", "S", "X"][Math.round(Percentage * 4.67)];
		if(Grade == null)
			Grade = "WTF";
		var Breaker = ["M&B", "NB", "NM"][
									((misses > 0 && breaks == 0) ? 1 : 0) +
									((misses == 0 && breaks > 0) ? 2 : 0)
								] + ' (${misses > 0 ? misses + 'M' : ''}${misses > 0 && breaks > 0 ? "+" : ""}${breaks > 0 ? breaks + "B" : ""})';
		if(breaks == 0 && misses == 0)
			return 'FC (NMB) | $Grade | ${FlxMath.roundDecimal(Percentage * 100, 1)}%';
		else 
			return '$Breaker | $Grade | ${FlxMath.roundDecimal(Percentage * 100, 1)}%';
	}
	private var paused:Bool = false;
	var startedCountdown:Bool = false;
	var canPause:Bool = true;
	var wot:Bool = false;
	var e:Float = 0;
	override public function update(elapsed:Float)
	{
		bbdetect.update(elapsed);
		#if !debug
		perfectMode = false;
		#end
		if (FlxG.keys.justPressed.NINE)
		{
			if (iconP1.animation.curAnim.name == 'bf-old')
				iconP1.animation.play(SONG.player1);
			else
				iconP1.animation.play('bf-old');
		}

		switch (curStage)
		{
			case 'philly':
				if (trainMoving)
				{
					trainFrameTiming += elapsed;

					if (trainFrameTiming >= 1 / 24)
					{
						updateTrainPos();
						trainFrameTiming = 0;
					}
				}
				// phillyCityLights.members[curLight].alpha -= (Conductor.crochet / 1000) * FlxG.elapsed;
		}

		super.update(elapsed);
		passer = 2 - ((FlxG.sound.music.time / FlxG.sound.music.length) * 2);

		scoreTxt.text = 'SCORE: ${commafy(songScore)}${fcampaigns()} | AVG. RATING: $Average';
		auxTxt.text = '$NPS NPS | ${pFormat()}';
		scoreTxt.x = healthBarBG.x + healthBarBG.width - scoreTxt.width;
		auxTxt.x = healthBarBG.x + healthBarBG.width - auxTxt.width;

		if (FlxG.keys.justPressed.ENTER && startedCountdown && canPause)
		{
			persistentUpdate = false;
			persistentDraw = true;
			paused = true;
			Main.timestamp();
			Main.setstate(SONG.song + " - Paused");
			Main.pause();
			openSubState(new PauseSubState(boyfriend.getScreenPosition().x, boyfriend.getScreenPosition().y));
		}

		if (FlxG.keys.justPressed.SEVEN)
		{
			FlxG.switchState(new ChartingState());
		}

		// FlxG.watch.addQuick('VOL', vocals.amplitudeLeft);
		// FlxG.watch.addQuick('VOLRight', vocals.amplitudeRight);

		iconP1.setGraphicSize(Std.int(FlxMath.lerp(150, iconP1.width, 0.50)));
		iconP2.setGraphicSize(Std.int(FlxMath.lerp(150, iconP2.width, 0.50)));

		iconP1.updateHitbox();
		iconP2.updateHitbox();

		var iconOffset:Int = 26;

		iconP1.x = healthBar.x + (healthBar.width * (FlxMath.remapToRange(healthBar.percent, 0, 100, 100, 0) * 0.01) - iconOffset);
		iconP2.x = healthBar.x + (healthBar.width * (FlxMath.remapToRange(healthBar.percent, 0, 100, 100, 0) * 0.01)) - (iconP2.width - iconOffset);

		if (health > 2)
			healthj = 2;

		if (healthBar.percent < 20)
			iconP1.animation.curAnim.curFrame = 1;
		else
			iconP1.animation.curAnim.curFrame = 0;

		if (healthBar.percent > 80)
			iconP2.animation.curAnim.curFrame = 1;
		else
			iconP2.animation.curAnim.curFrame = 0;

		/* if (FlxG.keys.justPressed.NINE)
			FlxG.switchState(new Charting()); */

		#if debug
		if (FlxG.keys.justPressed.EIGHT)
			FlxG.switchState(new AnimationDebug(SONG.player2));
		#end

		if (startingSong)
		{
			if (startedCountdown)
			{
				Conductor.songPosition += FlxG.elapsed * 1000;
				if (Conductor.songPosition >= 0)
					startSong();
			}
		}
		else
		{
			// Conductor.songPosition = FlxG.sound.music.time;
			Conductor.songPosition += FlxG.elapsed * 1000;

			if (!paused)
			{
				songTime += FlxG.game.ticks - previousFrameTime;
				previousFrameTime = FlxG.game.ticks;

				// Interpolation type beat
				if (Conductor.lastSongPos != Conductor.songPosition)
				{
					songTime = (songTime + Conductor.songPosition) / 2;
					Conductor.lastSongPos = Conductor.songPosition;
					// Conductor.songPosition += FlxG.elapsed * 1000;
					// trace('MISSED FRAME');
				}
			}

			// Conductor.lastSongPos = FlxG.sound.music.time;
		}

		if (generatedMusic && PlayState.SONG.notes[Std.int(curStep / 16)] != null)
		{
			if (curBeat % 4 == 0)
			{
				// trace(PlayState.SONG.notes[Std.int(curStep / 16)].mustHitSection);
			}
			var _dad:Character = dad;
			if(bti(SONG.actors) > 1)
				if(SONG.notes[Std.int(curStep / 16)].sectionNotes.length > 0)
					if(bti(SONG.notes[Std.int(curStep / 16)].sectionNotes[0][5]) > 0)
						_dad = morePlayers[Std.int(SONG.notes[Std.int(curStep / 16)].sectionNotes[0][5]-1)];

			if (camFollow.x != _dad.getMidpoint().x + 150 && !PlayState.SONG.notes[Std.int(curStep / 16)].mustHitSection)
			{
				camFollow.setPosition(_dad.getMidpoint().x + 150, dad.getMidpoint().y - 100);
				// camFollow.setPosition(lucky.getMidpoint().x - 120, lucky.getMidpoint().y + 210);

				switch (_dad.curCharacter)
				{
					case 'mom':
						camFollow.y = _dad.getMidpoint().y;
					case 'senpai':
						camFollow.y = _dad.getMidpoint().y - 430;
						camFollow.x = _dad.getMidpoint().x - 100;
					case 'senpai-angry':
						camFollow.y = _dad.getMidpoint().y - 430;
						camFollow.x = _dad.getMidpoint().x - 100;
				}

				if (_dad.curCharacter == 'mom')
					vocals.volume = 1;

				if (SONG.song.toLowerCase() == 'tutorial')
				{
					tweenCamIn();
				}
			}

			if (PlayState.SONG.notes[Std.int(curStep / 16)].mustHitSection && camFollow.x != boyfriend.getMidpoint().x - 100)
			{
				camFollow.setPosition(boyfriend.getMidpoint().x - 100, boyfriend.getMidpoint().y - 100);

				switch (curStage)
				{
					case 'limo':
						camFollow.x = boyfriend.getMidpoint().x - 300;
					case 'mall':
						camFollow.y = boyfriend.getMidpoint().y - 200;
					case 'school':
						camFollow.x = boyfriend.getMidpoint().x - 200;
						camFollow.y = boyfriend.getMidpoint().y - 200;
					case 'schoolEvil':
						camFollow.x = boyfriend.getMidpoint().x - 200;
						camFollow.y = boyfriend.getMidpoint().y - 200;
				}

				if (SONG.song.toLowerCase() == 'tutorial')
				{
					FlxTween.tween(FlxG.camera, {zoom: 1}, (Conductor.stepCrochet * 4 / 1000), {ease: FlxEase.elasticInOut});
				}
			}
		}

		if (camZooming)
		{
			FlxG.camera.zoom = FlxMath.lerp(defaultCamZoom, FlxG.camera.zoom, Math.min(0.95 * (60 / FlxG.updateFramerate), 1));
			camHUD.zoom = FlxMath.lerp(1, camHUD.zoom, Math.min(0.95 * (60 / FlxG.updateFramerate), 1));
			camHPHUD.zoom = FlxMath.lerp(1, camHPHUD.zoom, Math.min(0.95 * (60 / FlxG.updateFramerate), 1));
		}

		FlxG.watch.addQuick("beatShit", curBeat);
		FlxG.watch.addQuick("stepShit", curStep);

		if (curSong == 'Fresh')
		{
			switch (curBeat)
			{
				case 16:
					camZooming = true;
					gfSpeed = 2;
				case 48:
					gfSpeed = 1;
				case 80:
					gfSpeed = 2;
				case 112:
					gfSpeed = 1;
				case 163:
					// FlxG.sound.music.stop();
					// FlxG.switchState(new TitleState());
			}
		}

		if (curSong == 'Bopeebo')
		{
			switch (curBeat)
			{
				case 128, 129, 130:
					vocals.volume = 0;
					// FlxG.sound.music.stop();
					// FlxG.switchState(new PlayState());
			}
		}
		// better streaming of shit

		// RESET = Quick Game Over Screen
		if (controls.RESET)
		{
			health = healthj = 0;
			trace("RESET = True");
		}

		// CHEAT = brandon's a pussy
		if (controls.CHEAT)
		{
			healthj += 1;
			trace("User is cheating!");
		}
		health = healthj;
		if (health <= (hell ? 0.25 : 0))
		{
			boyfriend.stunned = true;

			persistentUpdate = false;
			persistentDraw = false;
			paused = true;

			vocals.stop();
			FlxG.sound.music.stop();

			// 1 / 1000 chance for Gitaroo Man easter egg
			if (FlxG.random.bool(0.1))
			{
				// gitaroo man easter egg
				FlxG.switchState(new GitarooPause());
			}
			else
				openSubState(new GameOverSubstate(boyfriend.getScreenPosition().x, boyfriend.getScreenPosition().y));

			// FlxG.switchState(new GameOverState(boyfriend.getScreenPosition().x, boyfriend.getScreenPosition().y));
		}

		if (unspawnNotes[0] != null)
		{
			if (unspawnNotes[0].strumTime - Conductor.songPosition < 1500)
			{
			
				var dunceNote:Note = unspawnNotes[0];
				notes.add(dunceNote);

				var index:Int = unspawnNotes.indexOf(dunceNote);
				unspawnNotes.splice(index, 1);
			}
		}

		if (generatedMusic)
		{
			notes.forEachAlive(function(daNote:Note)
			{
				var activity = !((downscroll && daNote.y < 0) ||
					(!downscroll && daNote.y > FlxG.height));
					
				daNote.active = activity;
				daNote.visible = activity && (centeredNotes ? daNote.mustPress : true);

				daNote.y = downscroll ? 
					strumLine.y - ((daNote.strumTime - Conductor.songPosition) * (0.45 * FlxMath.roundDecimal(SONG.speed, 2))) :
					(strumLine.y - (Conductor.songPosition - daNote.strumTime) * (0.45 * FlxMath.roundDecimal(SONG.speed, 2))); // This definitely should be shortened.
				if(daNote.animation.curAnim.name.substr(-3) == 'end' && downscroll)
					daNote.y += 102.4 / SONG.speed; // not final
				if(daNote.openHold != null){
					if(!daNote.cOpenHold){
						daNote.openHold.x = daNote.x;
						daNote.openHold.cameras = [camHUD];
						add(daNote.openHold);
						daNote.openHold.visible = activity; // why do I have to do this again?
						daNote.cOpenHold = true;
					}
					daNote.openHold.updateHitbox();
				}
				// i am so fucking sorry for this if condition
				if(downscroll)
				{
					if (daNote.isSustainNote
						&& daNote.y - daNote.offset.y >= strumLine.y - Note.swagWidth / 2
						&& (!daNote.mustPress || (daNote.wasGoodHit || (daNote.prevNote.wasGoodHit && !daNote.canBeHit))))
					{
						var swagRect = new FlxRect(0, strumLine.y, FlxG.width, daNote.height * 2);
						swagRect.y /= daNote.scale.y;
						swagRect.height -= swagRect.y;
						daNote.clipRect = swagRect;
						var Deceleration = SONG.notes.length;
						var I = ((8 * Deceleration) / ((Conductor.songPosition / (Conductor.stepCrochet * 4)) + Deceleration)) / (ninefret ? 4 : 1); // Why
						// trace(I);
						if(daNote.mustPress)
							songScore += Std.int(I);
					}
					if(daNote.openHold != null){
						if(daNote.openHold.y - daNote.openHold.offset.y <= strumLine.y - Note.swagWidth / 2 &&
						(!daNote.mustPress || (daNote.wasGoodHit || (daNote.prevNote.wasGoodHit && !daNote.canBeHit)))){
							var SwagRectII = new FlxRect(0, strumLine.y + Note.swagWidth / 2 - daNote.openHold.y, daNote.openHold.width * 2, daNote.openHold.height * 2);
							SwagRectII.y /= 2;
							SwagRectII.height -= SwagRectII.y;
							daNote.openHold.clipRect = SwagRectII;
							remove(daNote.openHold);
						}
					}
				}
				else
				{
					
					if (daNote.isSustainNote
						&& daNote.y + daNote.offset.y <= strumLine.y + Note.swagWidth / 2
						&& (!daNote.mustPress || (daNote.wasGoodHit || (daNote.prevNote.wasGoodHit && !daNote.canBeHit))))
					{
						var swagRect = new FlxRect(0, strumLine.y + Note.swagWidth / 2 - daNote.y, daNote.width * 2, daNote.height * 2);
						swagRect.y /= daNote.scale.y;
						swagRect.height -= swagRect.y;
						daNote.clipRect = swagRect;
						var Deceleration = SONG.notes.length;
						var I = ((8 * Deceleration) / ((Conductor.songPosition / (Conductor.stepCrochet * 4)) + Deceleration)) / (ninefret ? 4 : 1); // Why
						// trace(I);
						if(daNote.mustPress)
							songScore += Std.int(I);
					}
					if(daNote.openHold != null){
						if(daNote.openHold.y + daNote.openHold.offset.y <= strumLine.y + Note.swagWidth / 2 &&
						(!daNote.mustPress || (daNote.wasGoodHit || (daNote.prevNote.wasGoodHit && !daNote.canBeHit)))){
							/*var SwagRectII = new FlxRect(0, strumLine.y + Note.swagWidth / 2 - daNote.openHold.y, daNote.openHold.width * 2, daNote.openHold.height * 2);
							SwagRectII.y /= 2;
							SwagRectII.height -= SwagRectII.y;
							daNote.openHold.clipRect = SwagRectII;*/
							remove(daNote.openHold);
						}
					}
				}

				if (!daNote.mustPress && daNote.wasGoodHit)
				{
					if (SONG.song != 'Tutorial')
						camZooming = true;

					var altAnim:String = "";

					if (SONG.notes[Math.floor(curStep / 16)] != null)
					{
						if (SONG.notes[Math.floor(curStep / 16)].altAnim)
							altAnim = '-alt';
					}
					var _dad = dad;
					if(daNote.actor > 0 && SONG.actors > 1){
						_dad = morePlayers[daNote.actor - 1];
					}

					switch (Math.abs(daNote.noteData))
					{
						case 0:
							_dad.playAnim('singLEFT' + altAnim, true);
						case 1 | 5 | 7:
							if((sixfret && Math.abs(daNote.noteData) == 1) || (ninefret && Math.abs(daNote.noteData) == 5))
								_dad.playAnim('singUP' + altAnim, true);
							else
								_dad.playAnim('singDOWN' + altAnim, true);
						case 2 | 8:
							if(sixfret)
								_dad.playAnim('singRIGHT' + altAnim, true);
							else
								_dad.playAnim('singUP' + altAnim, true);
						case 3 | 6 | 10:
							if((sixfret && Math.abs(daNote.noteData) == 3) || (ninefret &&  Math.abs(daNote.noteData) == 6))
								_dad.playAnim('singLEFT' + altAnim, true);
							else
								_dad.playAnim('singRIGHT' + altAnim, true);
						case 4:
							_dad.playAnim('singUP' + altAnim, true);
					}

					_dad.holdTimer = 0;

					if (SONG.needsVoices)
						vocals.volume = 1;

					if(daNote.openHold != null)
						remove(daNote.openHold);
					
					notes.remove(daNote, true);
					toDestroy.push(daNote);
					daNote.kill();
				}

				// WIP interpolation shit? Need to fix the pause issue
				// daNote.y = (strumLine.y - (songTime - daNote.strumTime) * (0.45 * PlayState.SONG.speed));

				if ((downscroll && daNote.y > FlxG.height - daNote.height) ||
					(!downscroll && daNote.y < -daNote.height))
				{
					if (daNote.isSustainNote && daNote.wasGoodHit)
					{
						if(daNote.openHold != null)
							remove(daNote.openHold);
						notes.remove(daNote, true);
						toDestroy.push(daNote);
						daNote.kill();
					}
					else
					{
						if (daNote.tooLate || !daNote.wasGoodHit)
						{
							healthj -= 0.0475;
							notesHit++;
							misses++;
							if(notesHit > 1)
								Percentage = Percentage * (notesHit - 1) / notesHit;
							else
								Percentage = 2/3;
							if(averageRating == -1)
								averageRating = 1;
							else
								averageRating = averageRating * (notesHit - 1) / notesHit;
							Rate();
							vocals.volume = 0;
						}

						daNote.active = false;
						daNote.visible = false;
						
						if(daNote.openHold != null)
							remove(daNote.openHold);
						notes.remove(daNote, true);
						toDestroy.push(daNote);
						daNote.kill();
					}
				}
			});
		}

		if (!inCutscene)
			keyShit();

		#if debug
		if (FlxG.keys.justPressed.ONE)
			endSong();
		#end
	}
	function Rate():Void
	{
		Average = bot ? "UNRATED" : [
			"N/A",
			"SHIT",
			"BAD",
			"GOOD",
			"SICK",
			"SICK*"
		][Math.round(averageRating + 1)];
	}
	function endSong():Void
	{
		while(toDestroy.length > 0){
			var k=toDestroy[0];
			toDestroy.splice(0, 1);
			if(k != null)
				k.destroy();
		}
		Main.clear();
		if(R34Switch != null)
			R34Switch.cancel();
		canPause = Bullshit = false;
		Main.timestamp();
		FlxG.sound.music.volume = 0;
		vocals.volume = 0;
		if (SONG.validScore && !bot)
		{
			#if !switch
			Highscore.saveScore(SONG.song, songScore, Math.round(averageRating + 1), storyDifficulty);
			#end
		}

		if (isStoryMode)
		{
			campaignScore += songScore;
			if(campaignRating == -1){
				campaignRating = averageRating;
				playlistLength = storyPlaylist.length;
			} else
				campaignRating += averageRating;
			storyPlaylist.remove(storyPlaylist[0]);
			if (storyPlaylist.length <= 0)
			{
				FlxG.sound.playMusic('assets/music/freakyMenu' + TitleState.soundExt);

				transIn = FlxTransitionableState.defaultTransIn;
				transOut = FlxTransitionableState.defaultTransOut;
				FlxG.switchState(new StoryMenuState());
				if(bot) return;

				// if ()
				StoryMenuState.weekUnlocked[Std.int(Math.min(storyWeek + 1, StoryMenuState.weekUnlocked.length - 1))] = true;

				if (SONG.validScore)
				{
					NGio.unlockMedal(60961);
					Highscore.saveWeekScore(storyWeek, campaignScore, Math.round(campaignRating / playlistLength) + 1, storyDifficulty);
				}

				FlxG.save.data.weekUnlocked = StoryMenuState.weekUnlocked;
				FlxG.save.flush();
			}
			else
			{
				var difficulty:String = "";

				if (storyDifficulty == 0)
					difficulty = '-easy';

				if (storyDifficulty == 2)
					difficulty = '-hard';

				if (storyDifficulty == 3)
					difficulty = '-y';

				trace('LOADING NEXT SONG');
				trace(PlayState.storyPlaylist[0].toLowerCase() + difficulty);

				if (SONG.song.toLowerCase() == 'eggnog')
				{
					var blackShit:FlxSprite = new FlxSprite(-FlxG.width * FlxG.camera.zoom,
						-FlxG.height * FlxG.camera.zoom).makeGraphic(FlxG.width * 3, FlxG.height * 3, FlxColor.BLACK);
					blackShit.scrollFactor.set();
					add(blackShit);
					camHUD.visible = false;

					FlxG.sound.play('assets/sounds/Lights_Shut_off' + TitleState.soundExt);
				}

				FlxTransitionableState.skipNextTransIn = true;
				FlxTransitionableState.skipNextTransOut = true;
				prevCamFollow = camFollow;
				try {
					PlayState.SONG = Song.loadFromJson(PlayState.storyPlaylist[0].toLowerCase() + difficulty, PlayState.storyPlaylist[0]);
					FlxG.sound.music.stop();
				} catch(_e) {
					BugHandlerState.text = "SONG IN PLAYLIST DOES NOT EXIST";
					trace(_e);
					FlxG.switchState(new BugHandlerState());
					return;
				}

				FlxG.switchState(new PlayState());
			}
		}
		else
		{
			trace('WENT BACK TO FREEPLAY??');
			FlxG.switchState(new FreeplayState());
		}
	}

	var endingSong:Bool = false;

	private function popUpScore(strumtime:Float):Void
	{
		var noteDiff:Float = Math.abs(strumtime - Conductor.songPosition);
		try {
			boyfriend.playAnim('hey');
		} catch(e) {
			// nothing
		}
		vocals.volume = 1;

		var placement:String = StringTools.lpad(Std.string(combo), "0", 3);

		var coolText:FlxText = new FlxText(0, 0, 0, placement, 32);
		coolText.screenCenter();
		coolText.x = FlxG.width * 0.55;
		//
		var rating:FlxSprite = new FlxSprite();
		var score:Int = 520;
		var iRating:Int = 4;
		var daRating:String = "c";

		if (noteDiff > Conductor.safeZoneOffset * 0.9)
		{
			daRating = 'shit';
			iRating = 0;
			score = 50;
		}
		else if (noteDiff > Conductor.safeZoneOffset * 0.75)
		{
			daRating = 'bad';
			iRating = 1;
			score = 100;
		}
		else if (noteDiff > Conductor.safeZoneOffset * 0.2)
		{
			daRating = 'good';
			iRating = 2;
			score = 200;
		}
		else if (noteDiff > Conductor.safeZoneOffset * 0.125)
		{
			daRating = 'sick';
			iRating = 3;
			score = 350;
		}
		if(true)
		{
			notesHit++;
			songScore += score;
			var MinOffset = (24 / Conductor.safeZoneOffset);
			var Diffshit = 1 - ((Math.max(noteDiff / Conductor.safeZoneOffset, MinOffset) - MinOffset) * 0.6); // sqrt didn't give a fair rolloff
			if(averageRating == -1){
				averageRating = iRating;
				Percentage = Diffshit;
			} else {
				averageRating = (averageRating * (notesHit - 1) + iRating) / notesHit; // average
				Percentage = ((Percentage * (notesHit - 1)) + Diffshit) / notesHit;
			}
			//trace(noteDiff, Conductor.safeZoneOffset, Diffshit, Percentage);
			Rate();
			/* if (combo > 60)
					daRating = 'sick';
				else if (combo > 12)
					daRating = 'good'
				else if (combo > 4)
					daRating = 'bad';
			 */
		}
		var pixelShitPart1:String = "";
		var pixelShitPart2:String = '';

		if (curStage.startsWith('school'))
		{
			pixelShitPart1 = 'weeb/pixelUI/';
			pixelShitPart2 = '-pixel';
		}

		rating.loadGraphic('assets/images/' + pixelShitPart1 + daRating + pixelShitPart2 + ".png");
		rating.screenCenter();
		rating.x = coolText.x - 40;
		rating.y -= 60;
		rating.acceleration.y = 550;
		rating.velocity.y -= FlxG.random.int(140, 175);
		rating.velocity.x -= FlxG.random.int(0, 10);

		var comboSpr:FlxSprite = new FlxSprite().loadGraphic('assets/images/' + pixelShitPart1 + 'combo' + pixelShitPart2 + '.png');
		comboSpr.screenCenter();
		comboSpr.x = coolText.x;
		comboSpr.acceleration.y = 600;
		comboSpr.velocity.y -= 150;

		comboSpr.velocity.x += FlxG.random.int(1, 10);
		add(rating);

		if (!curStage.startsWith('school'))
		{
			rating.setGraphicSize(Std.int(rating.width * 0.7));
			rating.antialiasing = true;
			comboSpr.setGraphicSize(Std.int(comboSpr.width * 0.7));
			comboSpr.antialiasing = true;
		}
		else
		{
			rating.setGraphicSize(Std.int(rating.width * daPixelZoom * 0.7));
			comboSpr.setGraphicSize(Std.int(comboSpr.width * daPixelZoom * 0.7));
		}

		comboSpr.updateHitbox();
		rating.updateHitbox();

		var seperatedScore:Array<String> = (StringTools.lpad(Std.string(combo), "0", 3)).split(""); // 999+ note fix

		var daLoop:Int = 0;
		for (i in seperatedScore)
		{
			var numScore:FlxSprite = new FlxSprite().loadGraphic('assets/images/' + pixelShitPart1 + 'num' + i + pixelShitPart2 + '.png');
			numScore.screenCenter();
			numScore.x = coolText.x + (43 * daLoop) - 90;
			numScore.y += 80;

			if (!curStage.startsWith('school'))
			{
				numScore.antialiasing = true;
				numScore.setGraphicSize(Std.int(numScore.width * 0.5));
			}
			else
			{
				numScore.setGraphicSize(Std.int(numScore.width * daPixelZoom));
			}
			numScore.updateHitbox();

			numScore.acceleration.y = FlxG.random.int(200, 300);
			numScore.velocity.y -= FlxG.random.int(140, 160);
			numScore.velocity.x = FlxG.random.float(-5, 5);

			if (combo >= 10 || combo == 0)
				add(numScore);

			FlxTween.tween(numScore, {alpha: 0}, 0.2, {
				onComplete: function(tween:FlxTween)
				{
					numScore.destroy();
				},
				startDelay: Conductor.crochet * 0.002
			});

			daLoop++;
		}
		/* 
			trace(combo);
			trace(seperatedScore);
		 */

		coolText.text = Std.string(seperatedScore);
		// add(coolText);

		FlxTween.tween(rating, {alpha: 0}, 0.2, {
			startDelay: Conductor.crochet * 0.001
		});

		FlxTween.tween(comboSpr, {alpha: 0}, 0.2, {
			onComplete: function(tween:FlxTween)
			{
				coolText.destroy();
				comboSpr.destroy();

				rating.destroy();
			},
			startDelay: Conductor.crochet * 0.001
		});

		curSection++;
	}
	public static var buttonQueues:Array<Int> = [];
	public static var Queue:Array<FlxTimer> = [];
	public static function enqueue(button:Int, ?offset:Float):Int
	{
		if(offset == null)
		{
			offset = (Conductor.safeZoneOffset / 2200);
		}
		offset -= (1 / FlxG.updateFramerate);
		if(offset <= 0)
			buttonQueues.push(Std.int(button))
		else
			Queue.push(new FlxTimer().start(offset, function(_:FlxTimer)
			{
				buttonQueues.push(Std.int(button));
				Queue.pop();
			}));
		return Queue.length-1;
	}
	public static function dequeue(loc:Int):Void
	{
		if(Queue[loc] == null)
			return;
		Queue[loc].cancel();
		Queue.splice(loc, 1);
	}
	private var balls:FlxTimer;
	public function blueball(time:Float = 0.7):Void
	{
		iconP1.color = 0xFF8888FF;
		this.blueballs_warn = true;
		if(balls != null)
			balls.cancel();
		balls = new FlxTimer().start(time, function(_:FlxTimer){
			iconP1.color = 0xFFFFFFF;
			blueballs_warn = false;
			balls.cancel(); // uhhh
			balls = null;
		});
	}
	public function save_balls():Void
	{
	}
	public function DirectionTables():Array<String>
	{
		if(ninefret)
			return ['LEFT','DOWN','UP','RIGHT','UP','LEFT','DOWN','UP','RIGHT'];
		else if(sixfret)
			return ['LEFT','UP','RIGHT','LEFT','DOWN','RIGHT'];
		else
			return ['LEFT','DOWN','UP','RIGHT', 'UP'];
	}
	private function keyShit():Void
	{
		// HOLDING
		// HOLDING

		var up = controls.UP;
		var right = controls.RIGHT;
		var r2 = controls.R2;
		var l2 = controls.L2;
		var down = controls.DOWN;
		var left = controls.LEFT;
		var k1 = controls.K1;
		var k2 = controls.K2;
		var k3 = controls.K3;
		var k4 = controls.K4;
		var k5 = controls.K5;
		var k6 = controls.K6;
		var k7 = controls.K7;
		var k8 = controls.K8;
		var k9 = controls.K9;

		var upP = controls.UP_P;
		var rightP = controls.RIGHT_P;
		var r2P = controls.R2_P;
		var l2P = controls.L2_P;
		var downP = controls.DOWN_P;
		var leftP = controls.LEFT_P;
		var k1P = controls.K1_P;
		var k2P = controls.K2_P;
		var k3P = controls.K3_P;
		var k4P = controls.K4_P;
		var k5P = controls.K5_P;
		var k6P = controls.K6_P;
		var k7P = controls.K7_P;
		var k8P = controls.K8_P;
		var k9P = controls.K9_P;

		var upR = controls.UP_R;
		var rightR = controls.RIGHT_R;
		var downR = controls.DOWN_R;
		var leftR = controls.LEFT_R;
		var r2R = controls.R2_R;
		var l2R = controls.L2_R;
		var k1R = controls.K1_R;
		var k2R = controls.K2_R;
		var k3R = controls.K3_R;
		var k4R = controls.K4_R;
		var k5R = controls.K5_R;
		var k6R = controls.K6_R;
		var k7R = controls.K7_R;
		var k8R = controls.K8_R;
		var k9R = controls.K9_R;

		var controlArray:Array<Bool> = [leftP, downP, sixfret ? r2P : upP, sixfret ? l2P : rightP, leftP || downP || upP || rightP || l2P || r2P, upP, rightP];
		var relarr:Array<Bool> = [leftR, downR, sixfret ? r2R : upR, sixfret ? l2R : rightR, upR, rightR];
		if(ninefret){
			controlArray = [k1P,k2P,k3P,k4P,false,k5P,k6P,k7P,k8P,false,k9P];
			controlArray[4]=controlArray.contains(true);
			relarr = [k1R,k2R,k3R,k4R,k5R,k6R,k7R,k8R,k9R];
		}
		if(bot)
		{
			up = down = l2 = r2 = left = right = k1=k2=k3=k4=k5=k6=k7=k8=k9 = false; // suppress user input
			upP = downP = l2P = r2P = leftP = rightP = k1P=k2P=k3P=k4P=k5P=k6P=k7P=k8P=k9P = false;
			upR = downR = l2R = r2R = leftR = rightR = k1R=k2R=k3R=k4R=k5R=k6R=k7R=k8R=k9R = false;
			for(i in 0...controlArray.length)
				controlArray[i] = false;
			if(opn)
			{
				playerStrums.forEach(function(a:FlxSprite)
				{
					a.animation.play("static");
				});
				opn = false;
			}
		} else {
			if(opn && relarr[opni])
			{
				playerStrums.forEach(function(a:FlxSprite)
				{
					a.animation.play("static");
				});
				opn = false;
			}
		}
		for(i in 0...buttonQueues.length)
		{
			if(buttonQueues[i] < controlArray.length && bot)
			{
				controlArray[buttonQueues[i]] = true;
			}
			buttonQueues.splice(i, 1);
		}
		// FlxG.watch.addQuick('asdfa', upP);
		if ((upP || rightP || downP || leftP || (sixfret && (l2P || r2P)) || (ninefret && (k1P||k2P||k3P||k4P||k5P||k6P||k7P||k8P||k9P)) || bot) && !boyfriend.stunned && generatedMusic)
		{
			boyfriend.holdTimer = 0;

			var possibleNotes:Array<Note> = [];

			var ignoreList:Array<Int> = [];
			var p:Dynamic = mustHitPain[Std.int(curBeat / 4)];
			var sectionHasHittable:Bool = false;
			if(p != null)
				sectionHasHittable = p;
			notes.forEachAlive(function(daNote:Note)
			{
				if (daNote.canBeHit && daNote.mustPress && !daNote.tooLate)
				{
					// the sorting probably doesn't need to be in here? who cares lol
					possibleNotes.push(daNote);
					possibleNotes.sort((a, b) -> Std.int(a.strumTime - b.strumTime));

					ignoreList.push(daNote.noteData);
				}
			});

			if (possibleNotes.length > 0)
			{
				var daNote = possibleNotes[0];

				if (perfectMode)
					noteCheck(true, daNote);

				// Jump notes
				if (possibleNotes.length >= 2)
				{
					if (possibleNotes[0].strumTime == possibleNotes[1].strumTime)
					{
						for (coolNote in possibleNotes)
						{
							if (controlArray[coolNote.noteData])
								goodNoteHit(coolNote);
							else
							{
								var inIgnoreList:Bool = false;
								for (shit in 0...ignoreList.length)
								{
									if (controlArray[ignoreList[shit]])
										inIgnoreList = true;
								}
								if (!inIgnoreList)
									badNoteCheck();
							}
						}
					}
					else if (possibleNotes[0].noteData == possibleNotes[1].noteData)
					{
						noteCheck(controlArray[daNote.noteData], daNote);
					}
					else
					{
						for (coolNote in possibleNotes)
						{
							noteCheck(controlArray[coolNote.noteData], coolNote);
						}
					}
				}
				else // regular notes?
				{
					noteCheck(controlArray[daNote.noteData], daNote);
				}
				/* 
					if (controlArray[daNote.noteData])
						goodNoteHit(daNote);
				 */
				// trace(daNote.noteData);
				if (daNote.wasGoodHit)
				{
					if(daNote.openHold != null)
						remove(daNote.openHold);
					notes.remove(daNote, true);
					toDestroy.push(daNote);
					daNote.kill();
				}
			}
			else if((!bot && Mashnt < 2)
				&&  !(Mashnt == 1 && !sectionHasHittable))
			{
				notesHit++;
				breaks++;
				if(hell)
				{ // blueballs if you mash in hell mode without protection
					boyfriend.stunned = true;

					persistentUpdate = false;
					persistentDraw = false;
					paused = true;

					vocals.stop();
					FlxG.sound.music.stop();

					if (FlxG.random.bool(0.1))
						FlxG.switchState(new GitarooPause());
					else
						openSubState(new GameOverSubstate(boyfriend.getScreenPosition().x, boyfriend.getScreenPosition().y));
				}
				bbdetect.defer(controlArray, Conductor.songPosition);
				if(notesHit > 1)
					Percentage = Percentage * (notesHit - 1) / notesHit;
				else
					Percentage = 0.9;
				if(averageRating == -1)
					averageRating = 1;
				else
					averageRating = averageRating * (notesHit - 1) / notesHit;
				badNoteCheck();
			}
		}
		if(bot && !boyfriend.stunned && generatedMusic){
			
		}
	if ((up || right || down || left || l2 || r2 || k1||k2||k3||k4||k5||k6||k7||k8||k9) && !boyfriend.stunned && generatedMusic)
		{
			notes.forEachAlive(function(daNote:Note)
			{
				if (daNote.canBeHit && daNote.mustPress && daNote.isSustainNote)
				{
					switch (daNote.noteData)
					{
						// NOTES YOU ARE HOLDING
						case 0:
							if (left||k1)
								goodNoteHit(daNote);
						case 1:
							if (down||k2)
								goodNoteHit(daNote);
						case 2:
							if ((up && !sixfret) || (r2 && sixfret)||k3)
								goodNoteHit(daNote);
						case 3:
							if ((right && !sixfret) || (l2 && sixfret)||k4)
								goodNoteHit(daNote);
						case 4:
							goodNoteHit(daNote);
						case 5:
							if(sixfret && up)
								goodNoteHit(daNote);
							if(k5&&ninefret)
								goodNoteHit(daNote);
						case 6:
							if(sixfret && right)
								goodNoteHit(daNote);
							if(k6&&ninefret)
								goodNoteHit(daNote);
						case 7:
							if(k7&&ninefret)
								goodNoteHit(daNote);
						case 8:
							if(k8&&ninefret)
								goodNoteHit(daNote);
						case 10:
							if(k9&&ninefret)
								goodNoteHit(daNote);
					}
				}
			});
		}

		if (boyfriend.holdTimer > Conductor.stepCrochet * 0.004 && !up && !down && !right && !left)
		{
			if (boyfriend.animation.curAnim.name.startsWith('sing') && !boyfriend.animation.curAnim.name.endsWith('miss'))
			{
				try {
					boyfriend.playAnim('idle');
				} catch(e) {
					// nothing
				}
			}
		}

		playerStrums.forEach(function(spr:FlxSprite)
		{
			if(spr.animation.curAnim == null)
				return;
			switch (spr.ID)
			{
				case 0:
					var m:Bool = ninefret ? k1P : leftP;
					var mr:Bool = ninefret ? k1R : leftR;
					if (m && spr.animation.curAnim.name != 'confirm')
						spr.animation.play('pressed');
					else if (mr || bot)
						spr.animation.play('static');
				case 1:
					var m:Bool = ninefret ? k2P : downP;
					var mr:Bool = ninefret ? k2R : downR;
					if (m && spr.animation.curAnim.name != 'confirm')
						spr.animation.play('pressed');
					else if (mr || bot)
						spr.animation.play('static');
				case 2:
					var m:Bool = ninefret ? k3P : sixfret ? r2P : upP;
					var mr:Bool = ninefret ? k3R : sixfret ? r2R : upR;
					if (m && spr.animation.curAnim.name != 'confirm')
						spr.animation.play('pressed');
					else if (mr || bot)
						spr.animation.play('static');
				case 3:
					var m:Bool = ninefret ? k4P : sixfret ? l2P : rightP;
					var mr:Bool = ninefret ? k4R : sixfret ? l2R : rightR;
					if (m && spr.animation.curAnim.name != 'confirm')
						spr.animation.play('pressed');
					else if (mr || bot)
						spr.animation.play('static');
				case 4:
					var m:Bool = ninefret ? k5P : upP;
					var mr:Bool = ninefret ? k5R : upR;
					if (m && spr.animation.curAnim.name != 'confirm')
						spr.animation.play('pressed');
					else if (mr || bot)
						spr.animation.play('static');
				case 5:
					var m:Bool = ninefret ? k6P : rightP;
					var mr:Bool = ninefret ? k6R : rightR;
					if (m && spr.animation.curAnim.name != 'confirm')
						spr.animation.play('pressed');
					else if (mr || bot)
						spr.animation.play('static');
				case 6:
					if (k7P && spr.animation.curAnim.name != 'confirm')
						spr.animation.play('pressed');
					else if (k7R || bot)
						spr.animation.play('static');
				case 7:
					if (k8P && spr.animation.curAnim.name != 'confirm')
						spr.animation.play('pressed');
					else if (k8R || bot)
						spr.animation.play('static');
				case 8:
					if (k9P && spr.animation.curAnim.name != 'confirm')
						spr.animation.play('pressed');
					else if (k9R || bot)
						spr.animation.play('static');
			}
			if(spr.animation.curAnim == null)
				return;
			if (spr.animation.curAnim.name == 'confirm' && !curStage.startsWith('school'))
			{
				spr.centerOffsets();
				spr.offset.x -= 13;
				spr.offset.y -= 13;
			}
			else
				spr.centerOffsets();
		});
	}

	public static function harm(damage:Float = 0){
		healthj -= damage;
	}
	
	function noteMiss(direction:Int = 1):Void
	{
		if (!boyfriend.stunned)
		{
			healthj -= 0.04;
			if (combo > 5)
			{
				gf.playAnim('sad');
			}
			combo = 0;

			songScore -= 10;

			FlxG.sound.play('assets/sounds/missnote' + FlxG.random.int(1, 3) + TitleState.soundExt, FlxG.random.float(0.1, 0.2));
			// FlxG.sound.play('assets/sounds/missnote1' + TitleState.soundExt, 1, false);
			// FlxG.log.add('played imss note');

			boyfriend.stunned = true;

			// get stunned for 5 seconds
			new FlxTimer().start(5 / 60, function(tmr:FlxTimer)
			{
				boyfriend.stunned = false;
			});

			switch (direction)
			{
				case 0:
					boyfriend.playAnim('singLEFTmiss', true);
				case 1 | 4 | 6:
					if((sixfret && direction == 1) || (ninefret && direction == 4))
						boyfriend.playAnim('singUPmiss', true);
					else
						boyfriend.playAnim('singDOWNmiss', true);
				case 2 | 7:
					if(sixfret)
						boyfriend.playAnim('singRIGHTmiss', true);
					else
						boyfriend.playAnim('singUPmiss', true);
				case 3 | 5 | 8:
					if((sixfret && direction == 3) || (ninefret && direction == 5))
						boyfriend.playAnim('singLEFTmiss', true);
					else
						boyfriend.playAnim('singRIGHTmiss', true);
			}
		}
	}

	function badNoteCheck()
	{
		// just double pasting this shit cuz fuk u
		// REDO THIS SYSTEM!
		var upP = controls.UP_P;
		var rightP = controls.RIGHT_P;
		var downP = controls.DOWN_P;
		var l2P = controls.L2_P;
		var r2P = controls.R2_P;
		var leftP = controls.LEFT_P;
		var k1P = controls.K1_P;
		var k2P = controls.K2_P;
		var k3P = controls.K3_P;
		var k4P = controls.K4_P;
		var k5P = controls.K5_P;
		var k6P = controls.K6_P;
		var k7P = controls.K7_P;
		var k8P = controls.K8_P;
		var k9P = controls.K9_P;
		if(k1P)
			noteMiss(0);
		if(k2P)
			noteMiss(1);
		if(k3P)
			noteMiss(2);
		if(k4P)
			noteMiss(3);
		if(k5P)
			noteMiss(4);
		if(k6P)
			noteMiss(5);
		if(k7P)
			noteMiss(6);
		if(k8P)
			noteMiss(7);
		if(k9P)
			noteMiss(8);

		if (leftP)
			noteMiss(0);
		if (downP)
			noteMiss(1);
		if ((upP && !sixfret) || (r2P && sixfret))
			noteMiss(2);
		if ((rightP && !sixfret) || (l2P && sixfret))
			noteMiss(3);
		if (upP && sixfret)
			noteMiss(4);
		if (rightP && sixfret)
			noteMiss(5);
	}

	function noteCheck(keyP:Bool, note:Note):Void
	{
		if (keyP)
			goodNoteHit(note);
		else
		{
			badNoteCheck();
		}
	}
	function goodNoteHit(note:Note):Void
	{
		if (!note.wasGoodHit)
		{
			if (!note.isSustainNote)
			{
				popUpScore(note.strumTime);
				combo++;
			}

			if (note.noteData >= 0)
				healthj += 0.023;
			else
				healthj += 0.004;
			
			var upP = controls.UP_P;
			var rightP = controls.RIGHT_P;
			var downP = controls.DOWN_P;
			var leftP = controls.LEFT_P;
			var l2P = controls.R2_P;
			var r2P = controls.L2_P;
			var k1P = controls.K1_P;
			var k2P = controls.K2_P;
			var k3P = controls.K3_P;
			var k4P = controls.K4_P;
			var k5P = controls.K5_P;
			var k6P = controls.K6_P;
			var k7P = controls.K7_P;
			var k8P = controls.K8_P;
			var k9P = controls.K9_P;
			var ndir:Int = ninefret ? (
				k1P ? 0 :
				k2P ? 1 :
				k3P ? 2 :
				k4P ? 3 :
				k5P ? 4 :
				k6P ? 5 :
				k7P ? 6 :
				k8P ? 7 :
				k9P ? 8 : 2
			) : sixfret ? (
				leftP ? 0 :
				downP ? 1 :
				l2P ? 2 : 
				r2P ? 3 :
				upP ? 4 :
				rightP ? 5 : 1
			) : (leftP ? 0 : (
				downP ? 1 : (
				upP ? 2 : (
				rightP ? 3 : 2
			))));
			var direction = (ninefret ?  ["LEFT", "DOWN", "UP", "RIGHT", "UP", "LEFT", "DOWN", "UP", "RIGHT"][ndir] : sixfret ? ["LEFT", "UP", "RIGHT", "LEFT", "DOWN", "RIGHT"][ndir] : ["LEFT", "DOWN", "UP", "RIGHT"][ndir]);
			switch (note.noteData)
			{
				case 0:
					boyfriend.playAnim('singLEFT', true);
				case 1 | 5 | 7:
					if((sixfret && note.noteData == 1) || (ninefret && note.noteData == 5))
						boyfriend.playAnim('singUP', true);
					else
						boyfriend.playAnim('singDOWN', true);
				case 2 | 8:
					if(sixfret)
						boyfriend.playAnim('singRIGHT', true);
					else
						boyfriend.playAnim('singUP', true);
				case 3 | 6 | 10:
					if((sixfret && note.noteData == 3) || (ninefret && note.noteData == 6))
						boyfriend.playAnim('singLEFT', true);
					else
						boyfriend.playAnim('singRIGHT', true);
				case 4:
					boyfriend.playAnim('sing$direction', true);
			}
			if(note.noteData == 4)
			{
				opn = true;
				opni = ndir;
			}
			playerStrums.forEach(function(spr:FlxSprite)
			{ // todo: make open hits cross the entire board **well**
				if (Math.abs(note.noteData - note.Category6key) == spr.ID || opn)
				{
					spr.animation.play('confirm', true);
				}
			});

			note.wasGoodHit = true;
			vocals.volume = 1;

			if (!note.isSustainNote)
			{
				notes.remove(note, true);
				toDestroy.push(note);
				note.kill();
			}
		}
	}

	var fastCarCanDrive:Bool = true;

	function resetFastCar():Void
	{
		fastCar.x = -12600;
		fastCar.y = FlxG.random.int(140, 250);
		fastCar.velocity.x = 0;
		fastCarCanDrive = true;
	}

	function fastCarDrive()
	{
		FlxG.sound.play('assets/sounds/carPass' + FlxG.random.int(0, 1) + TitleState.soundExt, 0.7);

		fastCar.velocity.x = (FlxG.random.int(170, 220) / FlxG.elapsed) * 3;
		fastCarCanDrive = false;
		new FlxTimer().start(2, function(tmr:FlxTimer)
		{
			resetFastCar();
		});
	}

	var trainMoving:Bool = false;
	var trainFrameTiming:Float = 0;

	var trainCars:Int = 8;
	var trainFinishing:Bool = false;
	var trainCooldown:Int = 0;

	function trainStart():Void
	{
		trainMoving = true;
		if (!trainSound.playing)
			trainSound.play(true);
	}

	var startedMoving:Bool = false;

	function updateTrainPos():Void
	{
		if (trainSound.time >= 4700)
		{
			startedMoving = true;
			gf.playAnim('hairBlow');
		}

		if (startedMoving)
		{
			phillyTrain.x -= 400;

			if (phillyTrain.x < -2000 && !trainFinishing)
			{
				phillyTrain.x = -1150;
				trainCars -= 1;

				if (trainCars <= 0)
					trainFinishing = true;
			}

			if (phillyTrain.x < -4000 && trainFinishing)
				trainReset();
		}
	}

	function trainReset():Void
	{
		gf.playAnim('hairFall');
		phillyTrain.x = FlxG.width + 200;
		trainMoving = false;
		// trainSound.stop();
		// trainSound.time = 0;
		trainCars = 8;
		trainFinishing = false;
		startedMoving = false;
	}

	function lightningStrikeShit():Void
	{
		FlxG.sound.play('assets/sounds/thunder_' + FlxG.random.int(1, 2) + TitleState.soundExt);
		halloweenBG.animation.play('lightning');

		lightningStrikeBeat = curBeat;
		lightningOffset = FlxG.random.int(8, 24);

		boyfriend.playAnim('scared', true);
		gf.playAnim('scared', true);
	}

	override function stepHit()
	{
		super.stepHit();
		if (SONG.needsVoices)
		{
			if (vocals.time > Conductor.songPosition + 20 || vocals.time < Conductor.songPosition - 20)
			{
				resyncVocals();
			}
		}

		if (dad.curCharacter == 'spooky' && curStep % 4 == 2)
		{
			// dad.dance();
		}
	}

	var lightningStrikeBeat:Int = 0;
	var lightningOffset:Int = 8;

	override function beatHit()
	{
		super.beatHit();

		if (generatedMusic)
		{
			notes.sort(FlxSort.byY, FlxSort.DESCENDING);
		}

		if (SONG.notes[Math.floor(curStep / 16)] != null)
		{
			if (SONG.notes[Math.floor(curStep / 16)].changeBPM)
			{
				Conductor.changeBPM(SONG.notes[Math.floor(curStep / 16)].bpm);
				FlxG.log.add('CHANGED BPM!');
			}
			// else
			// Conductor.changeBPM(SONG.bpm);

			// Dad doesnt interupt his own notes
			if (SONG.notes[Math.floor(curStep / 16)].mustHitSection){
				dad.dance();
				for(i in morePlayers){
					i.dance();
				}
			}
		}
		// FlxG.log.add('change bpm' + SONG.notes[Std.int(curStep / 16)].changeBPM);
		wiggleShit.update(Conductor.crochet);

		// HARDCODING FOR MILF ZOOMS!
		if (curSong.toLowerCase() == 'milf' && curBeat >= 168 && curBeat < 200 && camZooming && FlxG.camera.zoom < 1.35)
		{
			FlxG.camera.zoom += 0.015;
			camHUD.zoom += 0.03;
			camHPHUD.zoom += 0.03;
		}

		if (camZooming && FlxG.camera.zoom < 1.35 && curBeat % 4 == 0)
		{
			FlxG.camera.zoom += 0.015;
			camHUD.zoom += 0.03;
			camHPHUD.zoom += 0.03;
		}

		iconP1.setGraphicSize(Std.int(iconP1.width + 30));
		iconP2.setGraphicSize(Std.int(iconP2.width + 30));

		iconP1.updateHitbox();
		iconP2.updateHitbox();

		/*if (curBeat % (gfSpeed * 2) == 0)
		{
			gf.dance();
		}*/

		if (!boyfriend.animation.curAnim.name.startsWith("sing"))
		{
			try {
				boyfriend.playAnim('idle');
			} catch(e) {
				// nothing
			}
		}

		if (curBeat % 8 == 7 && curSong == 'Bopeebo')
		{
			boyfriend.playAnim('hey', true);

			if (SONG.song == 'Tutorial' && dad.curCharacter == 'gf')
			{
				dad.playAnim('cheer', true);
			}
		}

		switch (curStage)
		{
			case 'school':
				bgGirls.dance();

			case 'mall':
				upperBoppers.animation.play('bop', true);
				bottomBoppers.animation.play('bop', true);
				santa.animation.play('idle', true);

			case 'limo':
				grpLimoDancers.forEach(function(dancer:BackgroundDancer)
				{
					dancer.dance();
				});

				if (FlxG.random.bool(10) && fastCarCanDrive)
					fastCarDrive();
			case "philly":
				if (!trainMoving)
					trainCooldown++;

				if (curBeat % 4 == 0)
				{
					phillyCityLights.forEach(function(light:FlxSprite)
					{
						light.visible = false;
					});

					curLight = FlxG.random.int(0, phillyCityLights.length - 1);

					phillyCityLights.members[curLight].visible = true;
					// phillyCityLights.members[curLight].alpha = 1;
				}

				if (curBeat % 8 == 4 && FlxG.random.bool(30) && !trainMoving && trainCooldown > 8)
				{
					trainCooldown = FlxG.random.int(-4, 0);
					trainStart();
				}
		}

		if (isHalloween && FlxG.random.bool(10) && curBeat > lightningStrikeBeat + lightningOffset)
		{
			lightningStrikeShit();
		}
	}

	var curLight:Int = 0;
}
