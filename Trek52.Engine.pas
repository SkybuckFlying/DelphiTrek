unit Trek52.Engine;

interface

uses
  System.SysUtils,
  System.Math;

type
  TSector = (scEmpty, scStar, scBase, scKlingon, scEnterprise);

  TQuadrant = array[0..7, 0..7] of TSector;

  TGxyCell = record
    Klingons: Integer;
    Bases: Integer;
    Stars: Integer;
    Scanned: Boolean;
  end;

  TGalaxy = array[0..7, 0..7] of TGxyCell;

  TKlingon = record
    Row: Integer;
    Col: Integer;
    Energy: Integer;
  end;

  TDamageSystem = (
    dsWarp, dsShields, dsPhasers, dsTorpedoes,
    dsSRScan, dsLRScan, dsComputer
  );

  TDamageArray = array[TDamageSystem] of Integer;

  ITrekRenderer = interface
    ['{C5F4C5C4-5C3E-4F0F-9C0E-9F0F0C0A0B0C}']
    procedure ClearScreen;
    procedure DrawQuadrant(const Q: TQuadrant);
    procedure DrawGalaxy(const G: TGalaxy; EntX, EntY: Integer);
    procedure DrawStatus(const State: TObject);
    procedure DrawDamage(const State: TObject);
    procedure DrawMessages(const Msgs: TArray<string>);
    procedure DrawPrompt(const Prompt: string);
  end;

  TGameState = class
  private
    FRenderer: ITrekRenderer;
    FMessages: TArray<string>;
    FGameOver: Boolean;
    FCondition: string;
    function RemainingKlingons: Integer;
  public
    Galaxy: TGalaxy;
    Quadrant: TQuadrant;
    Klingons: array[0..2] of TKlingon;

    EnterpriseX: Integer;   // 0..63
    EnterpriseY: Integer;   // 0..63

    Energy: Integer;
    Shields: Integer;
    Torpedoes: Integer;
    Stardates: Integer;

    Damage: TDamageArray;

    constructor Create(ARenderer: ITrekRenderer);

    procedure InitializeGame;
    procedure InitializeQuadrant;

    procedure AddMessage(const S: string);
    procedure ClearMessages;
    procedure RefreshScreen;

    procedure DoWarp(Course: Integer; WarpFactor: Double);
    procedure FirePhasers(EnergyToFire: Integer);
    procedure FireTorpedo(Course: Integer);
    procedure SetShields(NewValue: Integer);
    procedure DoLongRangeScan;

    procedure DoNormalRepairs;
    procedure DoRandomRepair;
    procedure DoRandomDamage;
    procedure UpdateCondition;
    procedure KlingonAttack;

    function DistanceToKlingon(Index: Integer): Double;
    procedure DestroyKlingon(Index: Integer);
    procedure DestroyKlingonAt(Row, Col: Integer);
    function IsDocked: Boolean;
    function DamageName(Sys: TDamageSystem): string;

    procedure CheckGameOver;

    property GameOver: Boolean read FGameOver;
    property Condition: string read FCondition;
  end;

implementation

{ TGameState }

constructor TGameState.Create(ARenderer: ITrekRenderer);
begin
  inherited Create;
  Randomize;
  FRenderer := ARenderer;
  FMessages := [];
  FGameOver := False;
  FCondition := 'GREEN';
end;

procedure TGameState.AddMessage(const S: string);
begin
  FMessages := FMessages + [S];
end;

procedure TGameState.ClearMessages;
begin
  FMessages := [];
end;

procedure TGameState.RefreshScreen;
begin
  if FRenderer = nil then
    Exit;

  FRenderer.ClearScreen;
  FRenderer.DrawQuadrant(Quadrant);
  FRenderer.DrawGalaxy(Galaxy, EnterpriseX, EnterpriseY);
  FRenderer.DrawStatus(Self);
  FRenderer.DrawDamage(Self);
  FRenderer.DrawMessages(FMessages);
end;

procedure TGameState.InitializeGame;
var
  r: Double;
  row, col: Integer;
  k, b, s: Integer;
  baseCount: Integer;
begin
  Energy := 3000;
  Shields := 0;
  Torpedoes := 10;
  Stardates := 30;

  for var d := Low(TDamageSystem) to High(TDamageSystem) do
    Damage[d] := 0;

  for row := 0 to 7 do
    for col := 0 to 7 do
    begin
      r := Random;
      k := 0; b := 0; s := 0;

      if r > 0.80 then k := 1;
      if r > 0.95 then k := 2;
      if r > 0.98 then k := 3;

      if Random > 0.96 then b := 1;

      s := Trunc(Random * 8) + 1;

      Galaxy[row, col].Klingons := k;
      Galaxy[row, col].Bases := b;
      Galaxy[row, col].Stars := s;
      Galaxy[row, col].Scanned := False;
    end;

  baseCount := 0;
  for row := 0 to 7 do
    for col := 0 to 7 do
      Inc(baseCount, Galaxy[row, col].Bases);

  if baseCount = 0 then
  begin
    row := Random(8);
    col := Random(8);
    Galaxy[row, col].Bases := 1;
  end;

  EnterpriseX := Random(64);
  EnterpriseY := Random(64);

  Galaxy[EnterpriseY div 8, EnterpriseX div 8].Scanned := True;

  InitializeQuadrant;
  UpdateCondition;
end;

procedure TGameState.InitializeQuadrant;
var
  qx, qy: Integer;
  s, x, y: Integer;
  cell: TGxyCell;
begin
  for y := 0 to 7 do
    for x := 0 to 7 do
      Quadrant[y, x] := scEmpty;

  qx := EnterpriseX div 8;
  qy := EnterpriseY div 8;

  cell := Galaxy[qy, qx];

  Quadrant[EnterpriseY mod 8, EnterpriseX mod 8] := scEnterprise;

  for s := 1 to cell.Stars do
  begin
    repeat
      x := Random(8);
      y := Random(8);
    until Quadrant[y, x] = scEmpty;
    Quadrant[y, x] := scStar;
  end;

  for s := 1 to cell.Bases do
  begin
    repeat
      x := Random(8);
      y := Random(8);
    until Quadrant[y, x] = scEmpty;
    Quadrant[y, x] := scBase;
  end;

  for s := 0 to cell.Klingons - 1 do
  begin
    repeat
      x := Random(8);
      y := Random(8);
    until Quadrant[y, x] = scEmpty;

    Quadrant[y, x] := scKlingon;

    Klingons[s].Row := y;
    Klingons[s].Col := x;
    Klingons[s].Energy := 200;
  end;

  for s := cell.Klingons to 2 do
  begin
    Klingons[s].Row := -1;
    Klingons[s].Col := -1;
    Klingons[s].Energy := 0;
  end;
end;

function TGameState.DistanceToKlingon(Index: Integer): Double;
var
  ex, ey: Integer;
begin
  ex := EnterpriseX mod 8;
  ey := EnterpriseY mod 8;
  Result := Sqrt(Sqr(ex - Klingons[Index].Col) + Sqr(ey - Klingons[Index].Row));
  if Result <= 0 then
    Result := 0.1;
end;

procedure TGameState.DestroyKlingon(Index: Integer);
var
  qx, qy: Integer;
begin
  if (Index < 0) or (Index > 2) then Exit;
  if Klingons[Index].Energy <= 0 then Exit;

  qx := EnterpriseX div 8;
  qy := EnterpriseY div 8;

  if (Klingons[Index].Row >= 0) and (Klingons[Index].Row <= 7) and
     (Klingons[Index].Col >= 0) and (Klingons[Index].Col <= 7) then
    Quadrant[Klingons[Index].Row, Klingons[Index].Col] := scEmpty;

  if Galaxy[qy, qx].Klingons > 0 then
    Dec(Galaxy[qy, qx].Klingons);

  Klingons[Index].Energy := 0;
  Klingons[Index].Row := -1;
  Klingons[Index].Col := -1;
end;

procedure TGameState.DestroyKlingonAt(Row, Col: Integer);
var
  i: Integer;
begin
  for i := 0 to 2 do
    if (Klingons[i].Energy > 0) and
       (Klingons[i].Row = Row) and
       (Klingons[i].Col = Col) then
    begin
      DestroyKlingon(i);
      Exit;
    end;
end;

function TGameState.IsDocked: Boolean;
var
  ex, ey, i, j: Integer;
begin
  ex := EnterpriseX mod 8;
  ey := EnterpriseY mod 8;
  for i := Max(ey - 1, 0) to Min(ey + 1, 7) do
    for j := Max(ex - 1, 0) to Min(ex + 1, 7) do
      if Quadrant[i, j] = scBase then
        Exit(True);
  Result := False;
end;

function TGameState.DamageName(Sys: TDamageSystem): string;
const
  Names: array[TDamageSystem] of string = (
    'Warp Engines', 'Shields', 'Phasers', 'Torpedoes',
    'SR Scanner', 'LR Scanner', 'Computer'
  );
begin
  Result := Names[Sys];
end;

procedure TGameState.DoRandomDamage;
var
  Sys: TDamageSystem;
begin
  Sys := TDamageSystem(Random(7));
  Damage[Sys] := Damage[Sys] + Random(5) + 2;
  AddMessage(DamageName(Sys) + ' damaged.');
end;

procedure TGameState.DoRandomRepair;
var
  Sys: TDamageSystem;
begin
  Sys := TDamageSystem(Random(7));
  if Damage[Sys] > 0 then
  begin
    Damage[Sys] := 0;
    AddMessage(DamageName(Sys) + ' fully repaired.');
  end;
end;

procedure TGameState.DoNormalRepairs;
var
  d: TDamageSystem;
begin
  for d := Low(TDamageSystem) to High(TDamageSystem) do
    if Damage[d] > 0 then
    begin
      Damage[d] := Max(Damage[d] - 1, 0);
      if Damage[d] = 0 then
        AddMessage(DamageName(d) + ' repaired.');
    end;
end;

procedure TGameState.UpdateCondition;
var
  qx, qy, i, j: Integer;
begin
  if IsDocked then
  begin
    Shields := 0;
    Energy := 3000;
    Torpedoes := 10;
    FCondition := 'DOCKED';
    AddMessage('Docked at starbase. Systems recharged.');
    Exit;
  end;

  qx := EnterpriseX div 8;
  qy := EnterpriseY div 8;

  if Galaxy[qy, qx].Klingons > 0 then
    FCondition := 'RED'
  else
    FCondition := 'GREEN';

  // no extra message spam here; condition is shown in status
end;

procedure TGameState.DoWarp(Course: Integer; WarpFactor: Double);
var
  Theta: Double;
  NewX, NewY: Double;
  OldQX, OldQY, NewQX, NewQY: Integer;
begin
  if Damage[dsWarp] > 0 then
  begin
    AddMessage('Engines damaged. Max warp 0.2');
    if WarpFactor > 0.2 then
      WarpFactor := 0.2;
  end;

  if WarpFactor * 8 + 5 > Energy then
  begin
    WarpFactor := Max((Energy - 5) / 8, 0);
    AddMessage('Engines shut down due to low energy.');
  end;

  Theta := (Course - 1) * PI / 4;

  NewX := EnterpriseX + Cos(Theta) * WarpFactor * 8;
  NewY := EnterpriseY - Sin(Theta) * WarpFactor * 8;

  if NewX < 0 then NewX := 0;
  if NewX > 63 then NewX := 63;
  if NewY < 0 then NewY := 0;
  if NewY > 63 then NewY := 63;

  OldQX := EnterpriseX div 8;
  OldQY := EnterpriseY div 8;

  EnterpriseX := Round(NewX);
  EnterpriseY := Round(NewY);

  NewQX := EnterpriseX div 8;
  NewQY := EnterpriseY div 8;

  if (OldQX <> NewQX) or (OldQY <> NewQY) then
  begin
    Galaxy[OldQY, OldQX].Scanned := True;
    Galaxy[NewQY, NewQX].Scanned := True;
    InitializeQuadrant;
  end
  else
  begin
    for var y := 0 to 7 do
      for var x := 0 to 7 do
        if Quadrant[y, x] = scEnterprise then
          Quadrant[y, x] := scEmpty;
    Quadrant[EnterpriseY mod 8, EnterpriseX mod 8] := scEnterprise;
  end;

  Energy := Energy - Trunc(WarpFactor * 8 + 5);
  Stardates := Stardates - 1;

  DoNormalRepairs;
  if Random < 0.2 then DoRandomRepair;

  if Random < 0.1 then
  begin
    AddMessage('** SPACE STORM **');
    DoRandomDamage;
  end;

  UpdateCondition;
  KlingonAttack;
end;

procedure TGameState.FirePhasers(EnergyToFire: Integer);
var
  i: Integer;
  Hit: Integer;
  Dist: Double;
begin
  if Damage[dsPhasers] > 0 then
  begin
    AddMessage('Phasers inoperable.');
    Exit;
  end;

  if (EnergyToFire <= 0) or (EnergyToFire > Energy) then
  begin
    AddMessage('Invalid phaser energy.');
    Exit;
  end;

  Energy := Energy - EnergyToFire;

  for i := 0 to 2 do
  begin
    if Klingons[i].Energy <= 0 then
      Continue;

    Dist := DistanceToKlingon(i);
    Hit := Trunc(EnergyToFire / Dist * Random);

    Klingons[i].Energy := Max(Klingons[i].Energy - Hit, 0);

    if Klingons[i].Energy = 0 then
    begin
      AddMessage(IntToStr(Hit) + ' unit hit. Klingon destroyed.');
      DestroyKlingon(i);
    end
    else
      AddMessage(IntToStr(Hit) + ' unit hit on Klingon.');
  end;

  KlingonAttack;
end;

procedure TGameState.FireTorpedo(Course: Integer);
var
  Theta: Double;
  X, Y: Double;
  Step: Integer;
  gx, gy: Integer;
  qx, qy: Integer;
begin
  if Damage[dsTorpedoes] > 0 then
  begin
    AddMessage('Torpedo tubes not operational.');
    Exit;
  end;

  if Torpedoes = 0 then
  begin
    AddMessage('All torpedoes expended.');
    Exit;
  end;

  Torpedoes := Torpedoes - 1;

  Theta := (Course - 1) * PI / 4;

  X := EnterpriseX;
  Y := EnterpriseY;

  qx := EnterpriseX div 8;
  qy := EnterpriseY div 8;

  for Step := 1 to 20 do
  begin
    X := X + Cos(Theta);
    Y := Y - Sin(Theta);

    if (X < 0) or (X > 63) or (Y < 0) or (Y > 63) then
    begin
      AddMessage('Torpedo missed.');
      Exit;
    end;

    gx := Round(X) mod 8;
    gy := Round(Y) mod 8;

    case Quadrant[gy, gx] of
      scKlingon:
        begin
          AddMessage('Direct hit! Klingon destroyed.');
          DestroyKlingonAt(gy, gx);
          Exit;
        end;
      scStar:
        begin
          AddMessage('Torpedo destroyed a star.');
          Quadrant[gy, gx] := scEmpty;
          Dec(Galaxy[qy, qx].Stars);
          Exit;
        end;
      scBase:
        begin
          AddMessage('Starbase destroyed! Command will not be pleased.');
          Quadrant[gy, gx] := scEmpty;
          if Galaxy[qy, qx].Bases > 0 then
            Dec(Galaxy[qy, qx].Bases);
          Exit;
        end;
    end;
  end;

  AddMessage('Torpedo missed.');
  KlingonAttack;
end;

procedure TGameState.SetShields(NewValue: Integer);
begin
  if Damage[dsShields] > 0 then
  begin
    AddMessage('Shield control inoperable.');
    Exit;
  end;

  if NewValue < 0 then
  begin
    AddMessage('Invalid shield value.');
    Exit;
  end;

  if NewValue > Energy + Shields then
  begin
    AddMessage('Insufficient energy.');
    Exit;
  end;

  Energy := Energy + Shields - NewValue;
  Shields := NewValue;

  AddMessage('Shields set to ' + IntToStr(Shields));
end;

procedure TGameState.DoLongRangeScan;
var
  qx, qy, row, col: Integer;
  line: string;
begin
  if Damage[dsLRScan] > 0 then
  begin
    AddMessage('Long-range scanner inoperable.');
    Exit;
  end;

  qx := EnterpriseX div 8;
  qy := EnterpriseY div 8;

  AddMessage('Long-range scan:');

  for row := Max(qy - 1, 0) to Min(qy + 1, 7) do
  begin
    line := '';
    for col := Max(qx - 1, 0) to Min(qx + 1, 7) do
    begin
      Galaxy[row, col].Scanned := True;
      line := line + Format('%3d ',
        [Galaxy[row, col].Klingons * 100 +
         Galaxy[row, col].Bases * 10 +
         Galaxy[row, col].Stars]);
    end;
    AddMessage(line);
  end;
end;

procedure TGameState.KlingonAttack;
var
  i: Integer;
  Hit, TotalHit: Integer;
  Dist: Double;
begin
  TotalHit := 0;

  for i := 0 to 2 do
  begin
    if Klingons[i].Energy <= 0 then
      Continue;

    Dist := DistanceToKlingon(i);
    Hit := Trunc(Klingons[i].Energy / Dist * (2 + Random));
    TotalHit := TotalHit + Hit;
  end;

  if TotalHit = 0 then Exit;

  if IsDocked then
  begin
    AddMessage('Starbase shields protect the Enterprise.');
    Exit;
  end;

  Shields := Shields - TotalHit;

  AddMessage(IntToStr(TotalHit) + ' unit hit on Enterprise.');

  if Random * Max(Shields, 1) < TotalHit then
    DoRandomDamage;

  if Shields < 0 then
  begin
    AddMessage('The Enterprise has been destroyed.');
    FGameOver := True;
  end;
end;

function TGameState.RemainingKlingons: Integer;
var
  row, col: Integer;
begin
  Result := 0;
  for row := 0 to 7 do
    for col := 0 to 7 do
      Inc(Result, Galaxy[row, col].Klingons);
end;

procedure TGameState.CheckGameOver;
var
  TotalKlingons: Integer;
begin
  TotalKlingons := RemainingKlingons;

  if TotalKlingons = 0 then
  begin
    AddMessage('The Federation has been saved!');
    AddMessage('You are promoted to Admiral.');
    FGameOver := True;
    Exit;
  end;

  if Shields < 0 then
  begin
    AddMessage('The Enterprise has been destroyed.');
    AddMessage('The Federation will be conquered.');
    FGameOver := True;
    Exit;
  end;

  if Energy + Shields <= 0 then
  begin
    AddMessage('The Enterprise is dead in space.');
    AddMessage('The Federation will be conquered.');
    FGameOver := True;
    Exit;
  end;

  if Stardates <= 0 then
  begin
    AddMessage('Time has run out.');
    AddMessage('The Federation has been conquered.');
    FGameOver := True;
    Exit;
  end;
end;

end.
