unit Trek52.ConsoleRenderer;

interface

uses
  System.SysUtils,
  Trek52.Engine;

type
  TConsoleRenderer = class(TInterfacedObject, ITrekRenderer)
  public
    procedure ClearScreen;
    procedure DrawQuadrant(const Q: TQuadrant);
    procedure DrawGalaxy(const G: TGalaxy; EntX, EntY: Integer);
    procedure DrawStatus(const State: TObject);
    procedure DrawDamage(const State: TObject);
    procedure DrawMessages(const Msgs: TArray<string>);
    procedure DrawPrompt(const Prompt: string);
  end;

implementation

procedure TConsoleRenderer.ClearScreen;
begin
  Write(#27'[2J'#27'[H');
end;

procedure TConsoleRenderer.DrawQuadrant(const Q: TQuadrant);
var
  y, x: Integer;
  C: Char;
begin
  Writeln('=== QUADRANT ===');
  for y := 0 to 7 do
  begin
    for x := 0 to 7 do
    begin
      case Q[y, x] of
        scEmpty:      C := '.';
        scStar:       C := '*';
        scBase:       C := 'B';
        scKlingon:    C := 'K';
        scEnterprise: C := 'E';
      else
        C := '?';
      end;
      Write(' ', C, ' ');
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
begin
  erow := EntY div 8;
  ecol := EntX div 8;

  Writeln('=== GALAXY MAP ===');
  for row := 0 to 7 do
  begin
    for col := 0 to 7 do
    begin
      cell := G[row, col];

      if not cell.Scanned then
        s := ' *** '
      else
        s := Format('%3d', [cell.Klingons * 100 + cell.Bases * 10 + cell.Stars]);

      if (row = erow) and (col = ecol) then
        s := '(' + s + ')'
      else
        s := ' ' + s + ' ';

      Write(s);
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
  Writeln('=== STATUS ===');
  Writeln(Format('ENERGY:    %4d', [G.Energy]));
  Writeln(Format('SHIELDS:   %4d', [G.Shields]));
  Writeln(Format('TORPEDOES: %4d', [G.Torpedoes]));
  Writeln(Format('STARDATES: %4d', [G.Stardates]));
  Writeln(Format('KLINGONS:  %4d', [G.RemainingKlingons]));
  Writeln(Format('CONDITION: %s', [G.Condition]));
  Writeln;
end;

procedure TConsoleRenderer.DrawDamage(const State: TObject);
var
  G: TGameState;
  d: TDamageSystem;
begin
  G := TGameState(State);
  Writeln('=== DAMAGE REPORT ===');
  for d := Low(TDamageSystem) to High(TDamageSystem) do
  begin
    if G.Damage[d] > 0 then
      Writeln(Format('%-12s : TTR %3d', [G.DamageName(d), G.Damage[d]]))
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

  Writeln('=== MESSAGES ===');
  for s in Msgs do
    Writeln('  ', s);
  Writeln;
end;

procedure TConsoleRenderer.DrawPrompt(const Prompt: string);
begin
  Write(Prompt);
end;

end.
