#import "EJBindingGameCenter.h"
#import "EJJavaScriptView.h"

@implementation EJBindingGameCenter

- (id)initWithContext:(JSContextRef)ctx argc:(size_t)argc argv:(const JSValueRef [])argv {
	if( self = [super initWithContext:ctx argc:argc argv:argv] ) {
		achievements = [[NSMutableDictionary alloc] init];
	}
	return self;
}

- (void)dealloc {
	[achievements release];
	[super dealloc];
}

- (void)loadAchievements {
	[GKAchievement loadAchievementsWithCompletionHandler:^(NSArray *loadedAchievements, NSError *error) {
		if( !error ) {
			for( GKAchievement *achievement in loadedAchievements ) {
				achievements[achievement.identifier] = achievement;
			}
		}
	}];
}

- (void)gameCenterViewControllerDidFinish:(GKGameCenterViewController *)viewController {
	[viewController.presentingViewController dismissViewControllerAnimated:YES completion:nil];
	viewIsActive = false;
}

// authenticate( callback(error){} )
EJ_BIND_FUNCTION( authenticate, ctx, argc, argv ) {
	__block JSObjectRef callback = NULL;
	if( argc > 0 && JSValueIsObject(ctx, argv[0]) ) {
		callback = JSValueToObject(ctx, argv[0], NULL);
		JSValueProtect(ctx, callback);
	}
	
	GKLocalPlayer.localPlayer.authenticateHandler = ^(UIViewController *viewController, NSError *error) {
		authed = !error;

		if( authed ) {
			NSLog(@"GameKit: Authed.");
			[self loadAchievements];
		}
		else {
			NSLog(@"GameKit: Auth failed: %@", error );
		}
		
		int autoAuth = authed
			? kEJGameCenterAutoAuthSucceeded
			: kEJGameCenterAutoAuthFailed;
		[[NSUserDefaults standardUserDefaults] setObject:@(autoAuth) forKey:kEJGameCenterAutoAuth];
		[[NSUserDefaults standardUserDefaults] synchronize];
		
		if( callback ) {
			JSContextRef gctx = scriptView.jsGlobalContext;
			JSValueRef params[] = { JSValueMakeBoolean(gctx, error) };
			[scriptView invokeCallback:callback thisObject:NULL argc:1 argv:params];
			JSValueUnprotectSafe(gctx, callback);
			
			// Make sure this callback is only called once
			callback = NULL;
		}
	};
	return NULL;
}

// softAuthenticate( callback(error){} )
EJ_BIND_FUNCTION( softAuthenticate, ctx, argc, argv ) {
	// Check if the last auth was successful or never tried and if so, auto auth this time
	int autoAuth = [[[NSUserDefaults standardUserDefaults] objectForKey:kEJGameCenterAutoAuth] intValue];
	if(
		autoAuth == kEJGameCenterAutoAuthNeverTried ||
		autoAuth == kEJGameCenterAutoAuthSucceeded
	) {
		[self _func_authenticate:ctx argc:argc argv:argv];
	}
	else if( argc > 0 && JSValueIsObject(ctx, argv[0]) ) {
		NSLog(@"GameKit: Skipping soft auth.");
		
		JSObjectRef callback = JSValueToObject(ctx, argv[0], NULL);
		JSValueRef params[] = { JSValueMakeBoolean(ctx, true) };
		[scriptView invokeCallback:callback thisObject:NULL argc:1 argv:params];
	}
	return NULL;
}


// reportScore( category, score )
EJ_BIND_FUNCTION( reportScore, ctx, argc, argv ) {
	if( argc < 2 ) { return NULL; }
	if( !authed ) { NSLog(@"GameKit Error: Not authed. Can't report score."); return NULL; }
	
	NSString *category = JSValueToNSString(ctx, argv[0]);
	int64_t score = JSValueToNumberFast(ctx, argv[1]);
	
	JSObjectRef callback = NULL;
	if( argc > 2 && JSValueIsObject(ctx, argv[2]) ) {
		callback = JSValueToObject(ctx, argv[2], NULL);
		JSValueProtect(ctx, callback);
	}
	
	GKScore *s = [[[GKScore alloc] initWithLeaderboardIdentifier:category] autorelease];
	s.value = score;
	[GKScore reportScores:@[s] withCompletionHandler:^(NSError *error) {
		if( callback ) {
			JSContextRef gctx = scriptView.jsGlobalContext;
			JSValueRef params[] = { JSValueMakeBoolean(gctx, error) };
			[scriptView invokeCallback:callback thisObject:NULL argc:1 argv:params];
			JSValueUnprotectSafe(gctx, callback);
		}
	}];
	
	return NULL;
}

// showLeaderboard( category )
EJ_BIND_FUNCTION( showLeaderboard, ctx, argc, argv ) {
	if( argc < 1 || viewIsActive ) { return NULL; }
	if( !authed ) { NSLog(@"GameKit Error: Not authed. Can't show leaderboard."); return NULL; }
	
	GKGameCenterViewController* vc = [[GKGameCenterViewController alloc] init];
    vc.viewState = GKGameCenterViewControllerStateLeaderboards;
	vc.leaderboardIdentifier = JSValueToNSString(ctx, argv[0]);
    vc.gameCenterDelegate = self;
    [scriptView.window.rootViewController presentViewController:vc animated:YES completion:nil];
	viewIsActive = true;
	
	return NULL;
}

- (void)reportAchievementWithIdentifier:(NSString *)identifier
	percentage:(float)percentage isIncrement:(BOOL)isIncrement
	ctx:(JSContextRef)ctx callback:(JSObjectRef)callback
{
	if( !authed ) { NSLog(@"GameKit Error: Not authed. Can't report achievment."); return; }
	
	GKAchievement *achievement = achievements[identifier];
	if( achievement ) {		
		// Already reported with same or higher percentage or already at 100%?
		if(
			achievement.percentComplete == 100.0f ||
			(!isIncrement && achievement.percentComplete >= percentage)
		) {
			return;
		}
		
		if( isIncrement ) {
			percentage = MIN( achievement.percentComplete + percentage, 100.0f );
		}
	}
	else {
		achievement = [[[GKAchievement alloc] initWithIdentifier:identifier] autorelease];
	}
	
	achievement.showsCompletionBanner = YES;
	achievement.percentComplete = percentage;
	
	if( callback ) {
		JSValueProtect(ctx, callback);
	}
	
	[GKAchievement reportAchievements:@[achievement] withCompletionHandler:^(NSError *error) {
		achievements[identifier] = achievement;
		
		if( callback ) {
			JSContextRef gctx = scriptView.jsGlobalContext;
			JSValueRef params[] = { JSValueMakeBoolean(gctx, error) };
			[scriptView invokeCallback:callback thisObject:NULL argc:1 argv:params];
			JSValueUnprotectSafe(gctx, callback);
		}
	}];
}

// reportAchievement( identifier, percentage )
EJ_BIND_FUNCTION( reportAchievement, ctx, argc, argv ) {
	if( argc < 2 ) { return NULL; }
	
	NSString *identifier = JSValueToNSString(ctx, argv[0]);
	float percent = JSValueToNumberFast(ctx, argv[1]);
	
	JSObjectRef callback = NULL;
	if( argc > 2 && JSValueIsObject(ctx, argv[2]) ) {
		callback = JSValueToObject(ctx, argv[2], NULL);
	}
	
	[self reportAchievementWithIdentifier:identifier percentage:percent isIncrement:NO ctx:ctx callback:callback];
	return NULL;
}

// reportAchievementAdd( identifier, percentage )
EJ_BIND_FUNCTION( reportAchievementAdd, ctx, argc, argv ) {
	if( argc < 2 ) { return NULL; }
	
	NSString *identifier = JSValueToNSString(ctx, argv[0]);
	float percent = JSValueToNumberFast(ctx, argv[1]);
	
	JSObjectRef callback = NULL;
	if( argc > 2 && JSValueIsObject(ctx, argv[2]) ) {
		callback = JSValueToObject(ctx, argv[2], NULL);
	}
	
	[self reportAchievementWithIdentifier:identifier percentage:percent isIncrement:YES ctx:ctx callback:callback];
	return NULL;
}

// showAchievements()
EJ_BIND_FUNCTION( showAchievements, ctx, argc, argv ) {
	if( viewIsActive ) { return NULL; }
	if( !authed ) { NSLog(@"GameKit Error: Not authed. Can't show achievements."); return NULL; }
	
	GKGameCenterViewController* vc = [[GKGameCenterViewController alloc] init];
    vc.viewState = GKGameCenterViewControllerStateAchievements;
    vc.gameCenterDelegate = self;
    [scriptView.window.rootViewController presentViewController:vc animated:YES completion:nil];
	viewIsActive = true;
	
	return NULL;
}

EJ_BIND_GET(authed, ctx) {
	return JSValueMakeBoolean(ctx, authed);
}



#define InvokeAndUnprotectCallback(callback, error, object) \
	[scriptView invokeCallback:callback thisObject:NULL argc:2 argv: \
		(JSValueRef[]){ \
			JSValueMakeBoolean(scriptView.jsGlobalContext, error), \
			(object ? NSObjectToJSValue(scriptView.jsGlobalContext, object) : scriptView->jsUndefined) \
		} \
	]; \
	JSValueUnprotect(scriptView.jsGlobalContext, callback);

#define ExitWithCallbackOnError(callback, error) \
	if( error ) { \
		InvokeAndUnprotectCallback(callback, error, NULL); \
		return; \
	}

#define GKPlayerToNSDict(player) @{ \
		@"alias": player.alias, \
		@"displayName": player.displayName, \
		@"playerID": player.playerID, \
	}

// loadFriends( callback(error, players[]){} )
EJ_BIND_FUNCTION( loadFriends, ctx, argc, argv ) {
	if( argc < 1 || !JSValueIsObject(ctx, argv[0]) ) { return NULL; }
	if( !authed ) { NSLog(@"GameKit Error: Not authed. Can't load Friends."); return NULL; }

	JSObjectRef callback = (JSObjectRef)argv[0];
	JSValueProtect(ctx, callback);

	GKLocalPlayer *player = [GKLocalPlayer localPlayer];
	[player loadFriendPlayersWithCompletionHandler:^(NSArray *friendIds, NSError *error) {
		ExitWithCallbackOnError(callback, error);
		
		[GKPlayer loadPlayersForIdentifiers:friendIds withCompletionHandler:^(NSArray *players, NSError *error) {
			ExitWithCallbackOnError(callback, error);
			
			// Transform GKPlayers Array to Array of NSDictionary so InvokeAndUnprotectCallback
			// is happy to convert it to JSON
			NSMutableArray *playersArray = [NSMutableArray arrayWithCapacity:players.count];
			for( GKPlayer *player in players ) {
				[playersArray addObject: GKPlayerToNSDict(player)];
			}
			InvokeAndUnprotectCallback(callback, error, playersArray);
		}];
	}];

	return NULL;
}


// loadPlayers( playerIds[], callback(error, players[]){} )
EJ_BIND_FUNCTION( loadPlayers, ctx, argc, argv ) {
	if( argc < 2 || !JSValueIsObject(ctx, argv[1]) ) { return NULL; }
	if( !authed ) { NSLog(@"GameKit Error: Not authed. Can't load Players."); return NULL; }

	NSArray *players = (NSArray *)JSValueToNSObject(ctx, argv[0]);
	if( !players || ![players isKindOfClass:NSArray.class] ) {
		return NULL;
	}
	
	JSObjectRef callback = (JSObjectRef)argv[0];
	JSValueProtect(ctx, callback);

	[GKPlayer loadPlayersForIdentifiers:players withCompletionHandler:^(NSArray *players, NSError *error) {
		ExitWithCallbackOnError(callback, error);
		
		// Transform GKPlayers Array to Array of NSDictionary so InvokeAndUnprotectCallback
		// is happy to convert it to JSON
		NSMutableArray *playersArray = [NSMutableArray arrayWithCapacity:players.count];
		for( GKPlayer *player in players ) {
			[playersArray addObject: GKPlayerToNSDict(player)];
		}
		InvokeAndUnprotectCallback(callback, error, playersArray);
	}];
	return NULL;
}


// loadScores( category, rangeStart, rangeEnd, callback(error, scores[]){} )
EJ_BIND_FUNCTION( loadScores, ctx, argc, argv ) {
	if( argc < 4 || !JSValueIsObject(ctx, argv[3]) ) { return NULL; }
	if( !authed ) { NSLog(@"GameKit Error: Not authed. Can't load Scores."); return NULL; }
	
	NSString *category = JSValueToNSString(ctx, argv[0]);
	int start = JSValueToNumberFast(ctx, argv[1]);
	int end = JSValueToNumberFast(ctx, argv[2]);
	JSObjectRef callback = (JSObjectRef)argv[3];
	JSValueProtect(ctx, callback);
		
	GKLeaderboard *request = [[GKLeaderboard alloc] init];
	request.playerScope = GKLeaderboardPlayerScopeGlobal;
	request.timeScope = GKLeaderboardTimeScopeAllTime;
	request.identifier = category;
	request.range = NSMakeRange(start, end);
	
	[request loadScoresWithCompletionHandler: ^(NSArray *scores, NSError *error) {
		ExitWithCallbackOnError(callback, error);
		
		// Build an Array of NSDictionaries for the scores and attach the loaded player
		// info.
		NSMutableArray *scoresArray = [NSMutableArray arrayWithCapacity:scores.count];
		for( GKScore *score in scores ) {
			[scoresArray addObject: @{
				@"category": score.leaderboardIdentifier,
				@"player": GKPlayerToNSDict(score.player),
				@"date": score.date,
				@"formattedValue": score.formattedValue,
				@"value": @(score.value),
				@"rank": @(score.rank)
			}];
		}
		
		InvokeAndUnprotectCallback(callback, error, scoresArray);
	}];
	return NULL;
}

// getLocalPlayerInfo()
EJ_BIND_FUNCTION( getLocalPlayerInfo, ctx, argc, argv ) {
	if( !authed ) { NSLog(@"GameKit Error: Not authed. Can't get Player info."); return NULL; }
	
	GKLocalPlayer * player = [GKLocalPlayer localPlayer];
	return NSObjectToJSValue(ctx, GKPlayerToNSDict(player));
}


#undef InvokeAndUnprotectCallback
#undef ExitWithCallbackOnError
#undef GKPlayerToNSDict

@end
