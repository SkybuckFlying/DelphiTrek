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
      Game.ClearMessages;

      Renderer.DrawPrompt('Command (W/P/T/S/L/A): ');
      Readln(Cmd);
      if Cmd = '' then
        Continue;
      C := UpCase(Cmd[1]);

	  Renderer.DrawContextHelp(C);

      case C of

        'W':  // Warp
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

        'P':  // Phasers
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

        'T':  // Torpedoes
          begin
            Course := ReadIntInRange('Torpedo course (1-8, C=cancel): ', 1, 8);
            if Course = -999999 then
            begin
              Game.AddMessage('Torpedo launch cancelled.');
			  Continue;
            end;

            Game.FireTorpedo(Course);
          end;

        'S':  // Shields
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

        'L':  // Long-range scan
          Game.DoLongRangeScan;

        'A':  // Abandon ship
          begin
            Renderer.DrawPrompt('Abandon ship? (Y/N): ');
            Readln(Cmd);
            if (Cmd <> '') and (UpCase(Cmd[1]) = 'Y') then
            begin
              Game.AddMessage('You have abandoned ship.');
              Break;
            end;
          end;

      else
        Game.AddMessage('Unknown command. Valid commands:');
        Game.AddMessage('  W = Warp');
        Game.AddMessage('  P = Phasers');
        Game.AddMessage('  T = Torpedoes');
        Game.AddMessage('  S = Shields');
        Game.AddMessage('  L = Long-range scan');
        Game.AddMessage('  A = Abandon ship');
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
  repeat
    RunGame;
    Write('Play again? (Y/N): ');
    Readln(Again);
  until (Again = '') or (UpCase(Again[1]) <> 'Y');
end.

