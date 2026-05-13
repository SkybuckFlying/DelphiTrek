program Trek52Console;

{$APPTYPE CONSOLE}

uses
  System.SysUtils,
  Trek52.Engine,
  Trek52.ConsoleRenderer;

function ReadIntPrompt(const Prompt: string): Integer;
var
  S: string;
begin
  Write(Prompt);
  Readln(S);
  Result := StrToIntDef(S, -1);
end;

function ReadFloatPrompt(const Prompt: string): Double;
var
  S: string;
begin
  Write(Prompt);
  Readln(S);
  Result := StrToFloatDef(S, -1);
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

      case C of
        'W':
          begin
            Course := ReadIntPrompt('Course (1-8): ');
            WarpFactor := ReadFloatPrompt('Warp factor (0.1-8.0): ');
            Game.DoWarp(Course, WarpFactor);
          end;
        'P':
          begin
            EnergyToFire := ReadIntPrompt('Phaser energy to fire: ');
            Game.FirePhasers(EnergyToFire);
          end;
        'T':
          begin
            Course := ReadIntPrompt('Torpedo course (1-8): ');
            Game.FireTorpedo(Course);
          end;
        'S':
          begin
            EnergyToFire := ReadIntPrompt('New shield level: ');
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
      else
        Game.AddMessage('Unknown command.');
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
