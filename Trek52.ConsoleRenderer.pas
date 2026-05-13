unit Trek52.ConsoleRenderer;

interface

uses
  System.SysUtils,
  Trek52.Engine;

type
  TConsoleRenderer = class(TInterfacedObject, ITrekRenderer)
  private
    procedure SetColor(const Code: string);
    procedure ResetColor;
    procedure WriteColored(const S, Code: string);
    procedure WriteColoredLine(const S, Code: string);
  public
    procedure ClearScreen;
    procedure DrawQuadrant(const Q: TQuadrant);
    procedure DrawGalaxy(const G: TGalaxy; EntX, EntY: Integer);
    procedure DrawStatus(const State: TObject);
    procedure DrawDamage(const State: TObject);
    procedure DrawMessages(const Msgs: TArray<string>);
    procedure DrawPrompt(const Prompt: string);

    // NEW:
    procedure DrawContextHelp(const Command: Char);
    procedure DrawHelpScreen;
    procedure DrawCommandBar;
  end;

implementation

procedure TConsoleRenderer.SetColor(const Code: string);
begin
  Write(#27'[', Code, 'm');
end;

procedure TConsoleRenderer.ResetColor;
begin
  Write(#27'[0m');
end;

procedure TConsoleRenderer.WriteColored(const S, Code: string);
begin
  SetColor(Code);
  Write(S);
  ResetColor;
end;

procedure TConsoleRenderer.WriteColoredLine(const S, Code: string);
begin
  SetColor(Code);
  Write(S);
  ResetColor;
  Writeln;
end;

procedure TConsoleRenderer.ClearScreen;
begin
  Write(#27'[2J'#27'[H');
end;

procedure TConsoleRenderer.DrawQuadrant(const Q: TQuadrant);
var
  y, x: Integer;
  C: Char;
  Color: string;
begin
  SetColor('1;37');
  Writeln('=== QUADRANT ===');
  ResetColor;

  for y := 0 to 7 do
  begin
    for x := 0 to 7 do
    begin
      case Q[y, x] of
        scEmpty:      begin C := '.'; Color := '0;37'; end;
        scStar:       begin C := '*'; Color := '0;33'; end;
        scBase:       begin C := 'B'; Color := '0;36'; end;
        scKlingon:    begin C := 'K'; Color := '0;31'; end;
        scEnterprise: begin C := 'E'; Color := '0;32'; end;
      else
        begin C := '?'; Color := '0;37'; end;
      end;

      Write(' ');
      WriteColored(C, Color);
      Write(' ');
    end;
    Writeln;
  end;
  Writeln;
end;

procedure TConsoleRenderer.DrawGalaxy(const G: TGalaxy; EntX, EntY: Integer);
var
  row, col: Integer;
  cell: TGxyCell;
  s: string;
  erow, ecol: Integer;
  Color: string;
begin
  erow := EntY div 8;
  ecol := EntX div 8;

  SetColor('1;37');
  Writeln('=== GALAXY MAP ===');
  ResetColor;

  for row := 0 to 7 do
  begin
    for col := 0 to 7 do
    begin
      cell := G[row, col];

      if not cell.Scanned then
        s := '***'
      else
        s := Format('%3d', [cell.Klingons * 100 + cell.Bases * 10 + cell.Stars]);

      if (row = erow) and (col = ecol) then
      begin
        Color := '1;32';
        s := '(' + s + ')';
        s := s.PadRight(6);
      end
      else
      begin
        Color := '0;37';
        s := (' ' + s + ' ').PadRight(6);
      end;

      WriteColored(s, Color);
    end;
    Writeln;
  end;
  Writeln;
end;

procedure TConsoleRenderer.DrawStatus(const State: TObject);
var
  G: TGameState;
begin
  G := TGameState(State);

  SetColor('1;37');
  Writeln('=== STATUS ===');
  ResetColor;

  Writeln(Format('ENERGY:    %4d', [G.Energy]));
  Writeln(Format('SHIELDS:   %4d', [G.Shields]));
  Writeln(Format('TORPEDOES: %4d', [G.Torpedoes]));
  Writeln(Format('STARDATES: %4d', [G.Stardates]));
  Writeln(Format('KLINGONS:  %4d', [G.RemainingKlingons]));

  if G.Condition = 'RED' then
    WriteColoredLine('CONDITION: RED', '1;31')
  else if G.Condition = 'DOCKED' then
    WriteColoredLine('CONDITION: DOCKED', '1;36')
  else
    WriteColoredLine('CONDITION: GREEN', '1;32');

  Writeln;
end;

procedure TConsoleRenderer.DrawDamage(const State: TObject);
var
  G: TGameState;
  d: TDamageSystem;
begin
  G := TGameState(State);

  SetColor('1;37');
  Writeln('=== DAMAGE REPORT ===');
  ResetColor;

  for d := Low(TDamageSystem) to High(TDamageSystem) do
  begin
    if G.Damage[d] > 0 then
      WriteColoredLine(
        Format('%-12s : TTR %3d', [G.DamageName(d), G.Damage[d]]),
        '0;31'
      )
    else
      Writeln(Format('%-12s : Working', [G.DamageName(d)]));
  end;
  Writeln;
end;

procedure TConsoleRenderer.DrawMessages(const Msgs: TArray<string>);
var
  s: string;
begin
  if Length(Msgs) = 0 then
    Exit;

  SetColor('1;37');
  Writeln('=== MESSAGES ===');
  ResetColor;

  for s in Msgs do
    Writeln('  ', s);
  Writeln;
end;

procedure TConsoleRenderer.DrawPrompt(const Prompt: string);
begin
  SetColor('1;37');
  Write(Prompt);
  ResetColor;
end;

//
// NEW: Single-line command bar
//
{
procedure TConsoleRenderer.DrawCommandBar;
begin
  SetColor('1;37');
  Writeln('Commands: W=Warp  P=Phasers  T=Torpedoes  S=Shields  L=Scan  A=Abandon  H=Help  Q=Quit');
  ResetColor;
  Writeln;
end;
}

// colorized command bar
procedure TConsoleRenderer.DrawCommandBar;
begin
  // Label
  SetColor('1;37');  // bright white
  Write('Commands: ');
  ResetColor;

  // W = Warp (green)
  WriteColored('W', '1;32'); Write('=Warp  ');

  // P = Phasers (yellow)
  WriteColored('P', '1;33'); Write('=Phasers  ');

  // T = Torpedoes (red)
  WriteColored('T', '1;31'); Write('=Torpedoes  ');

  // S = Shields (cyan)
  WriteColored('S', '1;36'); Write('=Shields  ');

  // L = Scan (white)
  WriteColored('L', '1;37'); Write('=Scan  ');

  // A = Abandon (magenta)
  WriteColored('A', '1;35'); Write('=Abandon  ');

  // H = Help (blue)
  WriteColored('H', '1;34'); Write('=Help  ');

  // Q = Quit (white)
  WriteColored('Q', '1;37'); Write('=Quit');

  Writeln;
  Writeln;
end;


//
// NEW: Full help screen
//
procedure TConsoleRenderer.DrawHelpScreen;
begin
  SetColor('1;37');
  Writeln('=== COMMANDS ===');
  ResetColor;

  Writeln('W = Warp');
  Writeln('P = Phasers');
  Writeln('T = Torpedoes');
  Writeln('S = Shields');
  Writeln('L = Long-range scan');
  Writeln('A = Abandon ship');
  Writeln('H = Help');
  Writeln('Q = Quit game');
  Writeln;

  SetColor('1;37');
  Writeln('=== DIRECTION SYSTEM ===');
  ResetColor;

  Writeln('        4  3  2');
  Writeln('         \ | /');
  Writeln('        5--E--1');
  Writeln('         / | \');
  Writeln('        6  7  8');
  Writeln;

  SetColor('1;37');
  Writeln('=== MOVEMENT ===');
  ResetColor;

  Writeln('Movement inside a quadrant is done using WARP.');
  Writeln('You do not move one sector at a time.');
  Writeln;
  Writeln('- Course (1–8) sets the direction.');
  Writeln('- Warp factor sets the distance.');
  Writeln('- Small warp factors (0.1–0.3) move a few sectors.');
  Writeln('- Larger warp factors move across the quadrant or into the next one.');
  Writeln;
  Writeln('Examples:');
  Writeln('  W, Course=1, Warp=0.1  -> move 1 sector east');
  Writeln('  W, Course=8, Warp=0.2  -> move 2 sectors southeast');
  Writeln('  W, Course=3, Warp=1.0  -> move across the quadrant north');
  Writeln;
end;


//
// NEW: Context-sensitive help
//
procedure TConsoleRenderer.DrawContextHelp(const Command: Char);
begin
  SetColor('1;37');

  case Command of

    'W': begin
      Writeln('=== WARP NAVIGATION ===');
      ResetColor;
      Writeln('        4  3  2');
      Writeln('         \ | /');
      Writeln('        5--E--1');
      Writeln('         / | \');
      Writeln('        6  7  8');
      Writeln('Enter course (1–8) and warp factor.');
    end;

    'T': begin
      Writeln('=== TORPEDO FIRING ARC ===');
      ResetColor;
      Writeln('        4  3  2');
      Writeln('         \ | /');
      Writeln('        5--E--1');
      Writeln('         / | \');
      Writeln('        6  7  8');
      Writeln('Enter torpedo course (1–8).');
    end;

    'P': begin
      Writeln('=== PHASERS ===');
      ResetColor;
      Writeln('Phasers fire in all directions.');
      Writeln('No course required.');
      Writeln('Enter energy amount.');
    end;

    'S': begin
      Writeln('=== SHIELDS ===');
      ResetColor;
      Writeln('Adjust shield energy level.');
      Writeln('No course required.');
    end;

    'L': begin
      Writeln('=== LONG-RANGE SCAN ===');
      ResetColor;
      Writeln('Shows Klingons, bases, and stars in adjacent quadrants.');
      Writeln('No course required.');
    end;

    'A': begin
      Writeln('=== ABANDON SHIP ===');
      ResetColor;
      Writeln('This action ends the game.');
    end;

  end;

  Writeln;
end;

end.

