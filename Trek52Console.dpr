program Trek52Console;

{$APPTYPE CONSOLE}

uses
  System.SysUtils,
  Trek52.Engine,
  Trek52.ConsoleRenderer;

function ReadIntInRange(const Prompt: string; MinVal, MaxVal: Integer; AllowCancel: Boolean = True): Integer;
var
  S: string;
  V: Integer;
begin
  while True do
  begin
    Write(Prompt);
    Readln(S);

    if AllowCancel and (UpperCase(S) = 'C') then
      Exit(-999999);

    if TryStrToInt(S, V) and (V >= MinVal) and (V <= MaxVal) then
      Exit(V);

    Writeln('Invalid input. Enter a number between ', MinVal, ' and ', MaxVal, '.');
    if AllowCancel then
      Writeln('(Or press C to cancel)');
  end;
end;

function ReadFloatInRange(const Prompt: string; MinVal, MaxVal: Double; AllowCancel: Boolean = True): Double;
var
  S: string;
  V: Double;
begin
  while True do
  begin
    Write(Prompt);
    Readln(S);

    if AllowCancel and (UpperCase(S) = 'C') then
      Exit(-999999.0);

    if TryStrToFloat(S, V) and (V >= MinVal) and (V <= MaxVal) then
      Exit(V);

    Writeln('Invalid input. Enter a value between ', MinVal:0:1, ' and ', MaxVal:0:1, '.');
    if AllowCancel then
      Writeln('(Or press C to cancel)');
  end;
end;

procedure PlayRandomShutdown(Renderer: ITrekRenderer);
var
  R: Integer;
begin
  R := Random(4);  // 0..3

  case R of
    0: Renderer.CRTShutdown;
    1: Renderer.FadeOut;
    2: Renderer.SelfDestructSequence;
    3: Renderer.WarpOutAnimation;
  end;
end;


var
  QuitGame: Boolean = False;   // GLOBAL FLAG

procedure RunGame;
var
  Renderer: ITrekRenderer;
  Game: TGameState;
  Cmd: string;
  C: Char;
  Course: Integer;
  WarpFactor: Double;
  EnergyToFire: Integer;
begin
  Renderer := TConsoleRenderer.Create;
  Game := TGameState.Create(Renderer);
  try
    Game.InitializeGame;

    while not Game.GameOver do
    begin
      Game.RefreshScreen;
      Renderer.DrawCommandBar;
      Game.ClearMessages;

      Renderer.DrawPrompt('Command: ');
      Readln(Cmd);
      if Cmd = '' then
        Continue;
      C := UpCase(Cmd[1]);

      Renderer.DrawContextHelp(C);

      case C of

        'H':
          begin
            Renderer.DrawHelpScreen;
            Readln;
            Continue;
          end;

        'W':
          begin
            Course := ReadIntInRange('Course (1-8, C=cancel): ', 1, 8);
            if Course = -999999 then
            begin
              Game.AddMessage('Warp cancelled.');
              Continue;
            end;

            WarpFactor := ReadFloatInRange('Warp factor (0.1-8.0, C=cancel): ', 0.1, 8.0);
            if WarpFactor < 0 then
            begin
              Game.AddMessage('Warp cancelled.');
              Continue;
            end;

            Game.DoWarp(Course, WarpFactor);
          end;

        'P':
          begin
            EnergyToFire := ReadIntInRange(
              'Phaser energy (1-' + IntToStr(Game.Energy) + ', C=cancel): ',
              1, Game.Energy
            );
            if EnergyToFire = -999999 then
            begin
              Game.AddMessage('Phaser firing cancelled.');
              Continue;
            end;

            Game.FirePhasers(EnergyToFire);
          end;

        'T':
          begin
            Course := ReadIntInRange('Torpedo course (1-8, C=cancel): ', 1, 8);
            if Course = -999999 then
            begin
              Game.AddMessage('Torpedo launch cancelled.');
              Continue;
            end;

            Game.FireTorpedo(Course);
          end;

        'S':
          begin
            EnergyToFire := ReadIntInRange(
              'New shield level (0-' + IntToStr(Game.Energy + Game.Shields) + ', C=cancel): ',
              0, Game.Energy + Game.Shields
            );
            if EnergyToFire = -999999 then
            begin
              Game.AddMessage('Shield adjustment cancelled.');
              Continue;
            end;

            Game.SetShields(EnergyToFire);
          end;

        'L':
          Game.DoLongRangeScan;

        'A':
          begin
            Renderer.DrawPrompt('Abandon ship? (Y/N): ');
            Readln(Cmd);
            if (Cmd <> '') and (UpCase(Cmd[1]) = 'Y') then
            begin
              Game.AddMessage('You have abandoned ship.');
              Break;
            end;
          end;

		'Q':
		begin
		  Renderer.DrawPrompt('Quit game? (Y/N/F=fast): ');
		  Readln(Cmd);

		  if Cmd = '' then Continue;

		  case UpCase(Cmd[1]) of

			'N': Continue;  // cancel quit

			'F': begin
			  QuitGame := True;
			  Exit;  // no animations
			end;

			'Y': begin
			  QuitGame := True;

			  // Determine victory or defeat
			  if Game.RemainingKlingons = 0 then
			  begin
				// === OPTION A: VICTORY CINEMATIC ===
				Renderer.DrawStarfleetSeal;
				Sleep(400);

				Renderer.WarpCoreHum;
				Renderer.DrawCaptainsLog(Game);
				Sleep(600);

				Renderer.DrawDebrief(Game);
				Renderer.DrawMissionGrade(Game);

				Writeln;
				Writeln('Press ENTER to continue...');
				Readln;

				Renderer.DrawGoodbyeScreen;
				Sleep(400);

				Renderer.FadeOut;
				Exit;
			  end
			  else
			  begin
				// === OPTION B: DEFEAT CINEMATIC ===
				Renderer.DrawCaptainsLog(Game);
				Renderer.DrawDebrief(Game);

				Writeln;
				Writeln('Press ENTER to continue...');
				Readln;

				PlayRandomShutdown(Renderer);
				Exit;
			  end;
			end;

		  end; // case
		end;


      else
        Game.AddMessage('Unknown command. Press H for help.');
      end;

      Game.CheckGameOver;
    end;

    Game.RefreshScreen;
    Writeln('Game over. Press ENTER to continue...');
    Readln;
  finally
    Game.Free;
  end;
end;

var
  Again: string;

begin
  Randomize;
  QuitGame := False;

  repeat
    RunGame;
    if QuitGame then
      Break;

    Write('Play again? (Y/N): ');
    Readln(Again);
  until (Again = '') or (UpCase(Again[1]) <> 'Y');
end.

