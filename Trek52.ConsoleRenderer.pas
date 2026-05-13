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
        scEmpty:
          begin
            C := '.';
            Color := '0;37'; // gray/white
          end;
        scStar:
          begin
            C := '*';
            Color := '0;33'; // yellow
          end;
        scBase:
          begin
            C := 'B';
            Color := '0;36'; // cyan
          end;
        scKlingon:
          begin
            C := 'K';
            Color := '0;31'; // red
          end;
        scEnterprise:
          begin
            C := 'E';
            Color := '0;32'; // green
          end;
      else
        begin
          C := '?';
          Color := '0;37';
        end;
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
        Color := '1;32'; // bright green for current quadrant
        s := '(' + s + ')';
        s := s.PadRight(6); // keep fixed width
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
    WriteColoredLine(Format('CONDITION: %s', [G.Condition]), '1;31') // bright red
  else if G.Condition = 'DOCKED' then
    WriteColoredLine(Format('CONDITION: %s', [G.Condition]), '1;36') // bright cyan
  else
    WriteColoredLine(Format('CONDITION: %s', [G.Condition]), '1;32'); // bright green

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
        '0;31' // red for damaged
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

end.

