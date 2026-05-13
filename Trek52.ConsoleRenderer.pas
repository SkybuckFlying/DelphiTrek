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

	// NEW CINEMATIC / DEBRIEF METHODS:
	procedure DrawDebrief(Game: TGameState);
	procedure DrawCaptainsLog(Game: TGameState);
	function ComputeMissionGrade(Game: TGameState): string;
	procedure DrawMissionGrade(Game: TGameState);

	// Cinematic effects
	procedure DrawGoodbyeScreen;
	procedure DrawStarfleetSeal;
	procedure WarpCoreHum;
	procedure WarpOutAnimation;
	procedure ScanlineOverlay;
	procedure SelfDestructSequence;
	procedure CRTShutdown;
	procedure FadeOut;
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
  k, b, s2: Integer;
  part: string;
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
      begin
        s := '***';
      end
      else
      begin
        // Extract digits
        k  := cell.Klingons;
        b  := cell.Bases;
        s2 := cell.Stars;

        // Build colorized 3-digit code
        part :=
          #27'[31m' + IntToStr(k)  +   // red for Klingons
          #27'[36m' + IntToStr(b)  +   // cyan for Bases
          #27'[33m' + IntToStr(s2) +   // yellow for Stars
          #27'[0m';

        s := part;
      end;

      // Highlight Enterprise quadrant
      if (row = erow) and (col = ecol) then
      begin
        Color := '1;32'; // green
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
{
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
  Writeln('=== MAP SYMBOLS ===');
  ResetColor;

  Writeln('E = Enterprise (your ship)');
  Writeln('K = Klingon warship');
  Writeln('B = Starbase');
  Writeln('* = Star');
  Writeln('. = Empty space');
  Writeln;

  // === LONG-RANGE SCAN LEGEND ===
  SetColor('1;37');
  Writeln('=== LONG-RANGE SCAN LEGEND ===');
  ResetColor;

  Writeln('Each number is a 3-digit code: K B S');
  Writeln('K = Klingons');
  Writeln('B = Starbases');
  Writeln('S = Stars');
  Writeln;

  Writeln('Examples:');
  Writeln('  102 = 1 Klingon, 0 Bases, 2 Stars');
  Writeln('  006 = 0 Klingons, 0 Bases, 6 Stars');
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
}


// colorized help screen
{procedure TConsoleRenderer.DrawHelpScreen;
begin
  ClearScreen;

  // === COMMANDS ===
  SetColor('1;36');  // cyan header
  Writeln('=== COMMANDS ===');
  ResetColor;

  SetColor('1;33'); Write('W'); ResetColor; Writeln(' = Warp (move the Enterprise)');
  SetColor('1;33'); Write('P'); ResetColor; Writeln(' = Phasers (energy weapons)');
  SetColor('1;33'); Write('T'); ResetColor; Writeln(' = Torpedoes (photon torpedo launch)');
  SetColor('1;33'); Write('S'); ResetColor; Writeln(' = Shields (adjust shield energy)');
  SetColor('1;33'); Write('L'); ResetColor; Writeln(' = Long-range scan');
  SetColor('1;33'); Write('A'); ResetColor; Writeln(' = Abandon ship');
  SetColor('1;33'); Write('H'); ResetColor; Writeln(' = Help screen');
  SetColor('1;33'); Write('Q'); ResetColor; Writeln(' = Quit game');
  Writeln;

  // === MAP SYMBOLS ===
  SetColor('1;36');
  Writeln('=== MAP SYMBOLS ===');
  ResetColor;

  SetColor('1;32'); Write('E'); ResetColor; Writeln(' = Enterprise (your ship)');
  SetColor('1;31'); Write('K'); ResetColor; Writeln(' = Klingon warship');
  SetColor('1;34'); Write('B'); ResetColor; Writeln(' = Starbase');
  SetColor('1;33'); Write('*'); ResetColor; Writeln(' = Star');
  SetColor('0;37'); Write('.'); ResetColor; Writeln(' = Empty space');
  Writeln;

  // === LONG-RANGE SCAN LEGEND ===
  SetColor('1;36');
  Writeln('=== LONG-RANGE SCAN LEGEND ===');
  ResetColor;

  Writeln('Each number is a 3-digit code: ',
    #27'[31mK'#27'[0m ', #27'[36mB'#27'[0m ', #27'[33mS'#27'[0m');
  Writeln(#27'[31mK'#27'[0m = Klingons');
  Writeln(#27'[36mB'#27'[0m = Starbases');
  Writeln(#27'[33mS'#27'[0m = Stars');
  Writeln;

  Write('  '); Write(#27'[31m1'#27'[36m0'#27'[33m2'#27'[0m'); Writeln(' = 1 Klingon, 0 Bases, 2 Stars');
  Write('  '); Write(#27'[31m0'#27'[36m0'#27'[33m6'#27'[0m'); Writeln(' = 0 Klingons, 0 Bases, 6 Stars');
  Writeln;

  // === DIRECTION SYSTEM ===
  SetColor('1;36');
  Writeln('=== DIRECTION SYSTEM ===');
  ResetColor;

  SetColor('1;35');  // magenta diagram
  Writeln('        4  3  2');
  Writeln('         \ | /');
  Writeln('        5--E--1');
  Writeln('         / | \');
  Writeln('        6  7  8');
  ResetColor;
  Writeln;

  // === MOVEMENT ===
  SetColor('1;36');
  Writeln('=== MOVEMENT ===');
  ResetColor;

  Writeln('Movement inside a quadrant is done using ', #27'[33mWARP'#27'[0m', '.');
  Writeln('You do not move one sector at a time.');
  Writeln;
  Writeln('- Course (', #27'[35m1–8'#27'[0m', ') sets the direction.');
  Writeln('- Warp factor sets the distance.');
  Writeln('- Small warp factors (', #27'[33m0.1–0.3'#27'[0m', ') move a few sectors.');
  Writeln('- Larger warp factors move across the quadrant or into the next one.');
  Writeln;
  Writeln('Examples:');
  Writeln('  ', #27'[33mW'#27'[0m', ', Course=1, Warp=0.1  -> move 1 sector east');
  Writeln('  ', #27'[33mW'#27'[0m', ', Course=8, Warp=0.2  -> move 2 sectors southeast');
  Writeln('  ', #27'[33mW'#27'[0m', ', Course=3, Warp=1.0  -> move across the quadrant north');
  Writeln;

  SetColor('1;32');
  Writeln('Press ENTER to return...');
  ResetColor;
end;
}


procedure TConsoleRenderer.DrawHelpScreen;
begin
//  ClearScreen;

  // === COMMANDS ===
  SetColor('1;36');  // cyan header
  Writeln('=== COMMANDS ===');
  ResetColor;

  WriteColored('W', '1;32'); Writeln(' = Warp (move the Enterprise)');
  WriteColored('P', '1;33'); Writeln(' = Phasers (energy weapons)');
  WriteColored('T', '1;31'); Writeln(' = Torpedoes (photon torpedo launch)');
  WriteColored('S', '1;36'); Writeln(' = Shields (adjust shield energy)');
  WriteColored('L', '1;37'); Writeln(' = Long-range scan');
  WriteColored('A', '1;35'); Writeln(' = Abandon ship');
  WriteColored('H', '1;34'); Writeln(' = Help screen');
  WriteColored('Q', '1;37'); Writeln(' = Quit game');
  Writeln;

  // === MAP SYMBOLS ===
  SetColor('1;36');
  Writeln('=== QUADRANT SYMBOLS ===');
  ResetColor;

  SetColor('1;32'); Write('E'); ResetColor; Writeln(' = Enterprise (your ship)');
  SetColor('1;31'); Write('K'); ResetColor; Writeln(' = Klingon warship');
  SetColor('1;34'); Write('B'); ResetColor; Writeln(' = Starbase');
  SetColor('1;33'); Write('*'); ResetColor; Writeln(' = Star');
  SetColor('0;37'); Write('.'); ResetColor; Writeln(' = Empty space');
  Writeln;

  // === LONG-RANGE SCAN LEGEND ===
  SetColor('1;36');
  Writeln('=== LONG-RANGE SCAN LEGEND ===');
  ResetColor;

  Writeln('Each number is a 3-digit code: ',
    #27'[31mK'#27'[0m ', #27'[36mB'#27'[0m ', #27'[33mS'#27'[0m');
  Writeln(#27'[31mK'#27'[0m = Klingons');
  Writeln(#27'[36mB'#27'[0m = Starbases');
  Writeln(#27'[33mS'#27'[0m = Stars');
  Writeln;

  Write('  '); Write(#27'[31m1'#27'[36m0'#27'[33m2'#27'[0m'); Writeln(' = 1 Klingon, 0 Bases, 2 Stars');
  Write('  '); Write(#27'[31m0'#27'[36m0'#27'[33m6'#27'[0m'); Writeln(' = 0 Klingons, 0 Bases, 6 Stars');
  Writeln;

  // === DIRECTION SYSTEM ===
  SetColor('1;36');
  Writeln('=== DIRECTION SYSTEM ===');
  ResetColor;

  SetColor('1;35');  // magenta diagram
  Writeln('        4  3  2');
  Writeln('         \ | /');
  Writeln('        5--E--1');
  Writeln('         / | \');
  Writeln('        6  7  8');
  ResetColor;
  Writeln;

  // === MOVEMENT ===
  SetColor('1;36');
  Writeln('=== MOVEMENT ===');
  ResetColor;

  Writeln('Movement inside a quadrant is done using ', #27'[33mWARP'#27'[0m', '.');
  Writeln('You do not move one sector at a time.');
  Writeln;
  Writeln('- Course (', #27'[35m1–8'#27'[0m', ') sets the direction.');
  Writeln('- Warp factor sets the distance.');
  Writeln('- Small warp factors (', #27'[33m0.1–0.3'#27'[0m', ') move a few sectors.');
  Writeln('- Larger warp factors move across the quadrant or into the next one.');
  Writeln;
  Writeln('Examples:');
  Writeln('  ', #27'[33mW'#27'[0m', ', Course=1, Warp=0.1  -> move 1 sector east');
  Writeln('  ', #27'[33mW'#27'[0m', ', Course=8, Warp=0.2  -> move 2 sectors southeast');
  Writeln('  ', #27'[33mW'#27'[0m', ', Course=3, Warp=1.0  -> move across the quadrant north');
  Writeln;

  SetColor('1;32');
  Writeln('Press ENTER to return...');
  ResetColor;
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

procedure TConsoleRenderer.DrawDebrief(Game: TGameState);
begin
    SetColor('1;37');
    Writeln('=== MISSION DEBRIEFING ===');
    ResetColor;

    Writeln('Quadrants visited: ', Game.QuadrantsVisited);
    Writeln('Klingons destroyed: ', Game.KlingonsDestroyed);
    Writeln('Bases docked: ', Game.BasesDocked);
    Writeln('Damage repaired: ', Game.RepairsDone);
    Writeln;

    if Game.RemainingKlingons = 0 then
        WriteColoredLine('Federation victory secured.', '1;32')
    else
        WriteColoredLine('Mission incomplete. Klingon threat remains.', '1;31');

    Writeln;
end;

procedure TConsoleRenderer.DrawCaptainsLog(Game: TGameState);
begin
    ClearScreen;
    SetColor('1;33');
    Writeln('CAPTAIN''S LOG - FINAL ENTRY');
    ResetColor;
    Writeln;

    Writeln('Stardate: ', Game.Stardates);
    Writeln('Klingons remaining: ', Game.RemainingKlingons);
    Writeln('Klingons destroyed: ', Game.KlingonsDestroyed);
	Writeln('Quadrants visited: ', Game.QuadrantsVisited);
    Writeln('Bases docked: ', Game.BasesDocked);
    Writeln('Repairs performed: ', Game.RepairsDone);
    Writeln;

    Writeln('Mission terminated by captain''s order.');
    Writeln('All systems powering down.');
    Writeln;
end;

function TConsoleRenderer.ComputeMissionGrade(Game: TGameState): string;
begin
    if (Game.RemainingKlingons = 0) and (Game.Stardates < 20) then
        Result := 'A+'
    else if Game.RemainingKlingons = 0 then
        Result := 'A'
    else if Game.KlingonsDestroyed > 0 then
        Result := 'B'
    else
        Result := 'C-';
end;

procedure TConsoleRenderer.DrawMissionGrade(Game: TGameState);
var
    Grade: string;
begin
    Grade := ComputeMissionGrade(Game);
    SetColor('1;37');
    Writeln('=== MISSION GRADE ===');
    ResetColor;
    WriteColoredLine('Overall performance: ' + Grade, '1;32');
    Writeln;
end;

procedure TConsoleRenderer.DrawGoodbyeScreen;
var
  i: Integer;
begin
  ClearScreen;
  for i := 1 to 3 do
  begin
    SetColor('1;37');
    Writeln('Shutting down systems...');
    ResetColor;
    Sleep(400);
  end;

  for i := 15 downto 0 do
  begin
    SetColor('0;' + IntToStr(i));
    Writeln('Goodbye, Captain.');
    ResetColor;
    Sleep(80);
  end;

  ClearScreen;
end;

procedure TConsoleRenderer.DrawStarfleetSeal;
const
  Seal: array[0..6] of string = (
    '        /\        ',
    '       /  \       ',
    '   ___/____\___   ',
    '  /            \  ',
    '  \ STARFLEET  /  ',
    '   \ COMMAND  /   ',
    '    \________/    '
  );
var
  i, b: Integer;
begin
  ClearScreen;
  for b := 30 downto 0 do
  begin
    ClearScreen;
    SetColor('1;3' + IntToStr(b mod 8));
    for i := 0 to High(Seal) do
      Writeln(Seal[i]);
    ResetColor;
    Sleep(50);
  end;
end;

procedure TConsoleRenderer.WarpCoreHum;
var
  i: Integer;
begin
  for i := 0 to 20 do
  begin
    SetColor('1;3' + IntToStr(i mod 8));
    Write('WARP CORE: HUMMMMMMMMM');
    ResetColor;
    Write(#13);
    Sleep(80);
  end;
  Writeln;
end;

procedure TConsoleRenderer.WarpOutAnimation;
var
  i: Integer;
begin
  ClearScreen;
  for i := 1 to 40 do
  begin
    SetColor('1;37');
    Writeln(StringOfChar('=', i) + '>');
    ResetColor;
    Sleep(20);
	ClearScreen;
  end;

  SetColor('1;34');
  Writeln('*** WARP ENGAGED ***');
  ResetColor;
  Sleep(500);
  ClearScreen;
end;

procedure TConsoleRenderer.ScanlineOverlay;
var
  i: Integer;
begin
  for i := 1 to 25 do
  begin
    SetColor('0;37');
    Writeln(StringOfChar('-', 80));
    ResetColor;
    Sleep(20);
  end;
end;

procedure TConsoleRenderer.SelfDestructSequence;
var
  i: Integer;
begin
  ClearScreen;
  for i := 10 downto 1 do
  begin
    SetColor('1;31');
    Writeln('SELF-DESTRUCT IN: ', i);
    ResetColor;
    Sleep(700);
    ClearScreen;
  end;

  SetColor('1;31');
  Writeln('*** BOOM ***');
  ResetColor;
  Sleep(1000);
  ClearScreen;
end;

procedure TConsoleRenderer.CRTShutdown;
var
  i: Integer;
begin
  for i := 25 downto 1 do
  begin
    ClearScreen;
    SetColor('1;37');
    Writeln(StringOfChar('-', 80));
    ResetColor;
    Sleep(20);
  end;

  ClearScreen;
  SetColor('1;37');
  Writeln('------------------------');
  ResetColor;
  Sleep(200);

  ClearScreen;
end;

procedure TConsoleRenderer.FadeOut;
var
  i: Integer;
begin
  for i := 37 downto 30 do
  begin
    SetColor('1;' + IntToStr(i));
    Writeln(' ');
    ResetColor;
    Sleep(50);
  end;
  ClearScreen;
end;




end.

