Unit UTargets;

interface
  uses System.Generics.Collections, UIntegrator, Winapi.Windows, Winapi.Messages, SysUtils, Classes, VCL.Forms, USQL, TNC;

  type

    TPosObject = class                       //Самый базовый класс для всего, кроме симулятора
      public
        CurPosition: TPoint;
        InitPosition: TPoint;
        procedure Move(ti: real);
        constructor Create(initParam: array of real);
        destructor Destroy;
        function GetTime: real;

        property Time: real read GetTime write Move;
      protected
        CurTime: real;
    end;

   (*************************************************************)

    TTarget = class (TPosObject)             //Базовый класс для целей и не только
      public
        TargetType: TTargetType;
        Destroyed: TDestroyedType;
        MoveParam: TTargetMoveParam;
        ResistParam: TResistParam;

        constructor Create(TargetType: TTargetType; initParam: array of real);
        procedure selfDestruct;
        procedure CalcCourse(CP: TPoint);
        procedure CalcTarget(Time,dt: real);

        function GetV: real;
        procedure SetV(newV: real);
        function GetMass: real;
        procedure SetMass(newMass: real);

        destructor Destroy;

        property V: real read GetV write SetV;
        property Mass: real read GetMass write SetMass;

      protected
        Course: real;
        TargetV: real;
        TargetMass: real;
        function CalcMFuel(ti:real): real; virtual; abstract;
        function CalcResist(ti:real): real; virtual; abstract;
        function CalcP(ti: real): real; virtual; abstract;
        function CalcV(ti: real): real; virtual; abstract;
        function CalcX(ti: real): real; virtual; abstract;
        function CalcY(ti: real): real; virtual; abstract;
        function CalcTime(ti: real): real;

    end;

   (*************************************************************)

    TTargetList = class (TList<TTarget>)    //список типа TTarget
      public
        function AddTarget(TargetType: TTargetType; initParam: array of real): integer;
        procedure InsertTarget(index: integer; TargetType: TTargetType; initParam: array of real);
        procedure Clear;
    end;

   (*************************************************************)

    TAircraft = class (TTarget)              //Самолёт-цель
      protected

        constructor Create(initParam: array of real);
        function CalcMFuel(ti:real): real; override;
        function CalcResist(ti:real): real; override;
        function CalcP(ti: real): real; override;
        function CalcV(ti: real): real; override;
        function CalcX(ti: real): real; override;
        function CalcY(ti: real): real; override;

    end;

   (*************************************************************)

    TMissile = class (TTarget)               //Ракета-цель
      protected

        constructor Create(initParam: array of real);
        function CalcMFuel(ti:real): real; override;
        function CalcResist(ti:real): real; override;
        function CalcP(ti: real): real; override;
        function CalcV(ti: real): real; override;
        function CalcX(ti: real): real; override;
        function CalcY(ti: real): real; override;

    end;

   (*************************************************************)

    TSamMissile = class (TMissile)           //Ракета для уничтожения целей
      public

        isLoze: TIsLoze;   //самоуничтожение/полёт/цель поражена
        fly: TMisActivated;      //ожидание цели/цель захвачена

        const Pmin = 0.15;   //минимальное значение для поражения
        const Pmax = 0.9;   //максимальное значение для поражения
        const PReq = 0.1;   //значение, нужное чтобы не самоуничтожиться

        constructor Create(InitParam: Array of real);

        procedure LockTarget(Target: TTarget);   //получение цели и запуск ракеты
        function GetLockTarget: TTarget;         //значение цели

        procedure CheckTarget;
        procedure Explode;                       //взрыв
        procedure selfDestruct;                   //самоуничтожение

        procedure SetLifeTime(time: real);       //время жизни ракеты, при превышении - взрыв
        function GetLifeTime: real;

        procedure CalcTarget(time, dt: real);    //функция правых частей

        property LockedTarget: TTarget read GetLockTarget write LockTarget;  //цель для поражения
        property LifeTime: real read GetLifeTime write SetLifeTime;          //время жизни ракеты

      protected
        const TMax = 50;    //максимальное время жизни
        const DLoze = 5;    //радиус поражения
     (*   const Pmin = 0.2;   //минимальное значение для поражения
        const Pmax = 0.8;   //максимальное значение для поражения
        const PReq = 0.1;   //значение, нужное чтобы не самоуничтожиться *)
        var DelegateTarget: TTarget;  //цель
        time: real;               //время жизни (реальное)

        function CalcMFuel(ti:real): real; override;   //модель движения
        function CalcResist(ti:real): real; override;
        function CalcP(ti: real): real; override;
        function CalcV(ti: real): real; override;
        function CalcX(ti: real): real; override;
        function CalcY(ti: real): real; override;
        function CalcCourse: real;
    end;

   (*************************************************************)

    TCommandPost = class (TPosObject)       //Командный пост, цель для целей)
      public
        SafetyDistance: real;
        procedure Move(ti: real);
        constructor Create(initParam: array of real);
    end;

   (*************************************************************)

    TRLS = class (TPosObject)               //РЛС, а также пункт запуска ракет
      public
        Distance: real;
        Course: real;
        RMax: real;
        SamMissileList: TTargetList;
        WriteSQLSAMMIS: TProcWriteSAM;

        function Peleng(ti: real; Target: TTarget): boolean;

        procedure Move(ti: real);

        procedure SetSamMissileList(SamList: TTargetList);
        procedure SetTargetList(TargetList: TTargetList);
        procedure SetCP(pos: TPoint);

        procedure CheckTargets;
        procedure LaunchMissile(target: integer);

        constructor Create(initParam: array of real);

      protected
        CP: TPoint;
        //SamMissileList: TTargetList;
        TargetList: TTargetList;
        LockedTargets: array of boolean;
        LaunchedMissiles: array of boolean;
        TargetShotDown: array of boolean;
        DistanceToCP: array of real;
        function CalcDist(pos: TPoint): real;
        function CalcTan(dx, dy: real): real;
    end;

   (*************************************************************)

    TTargetIntegrator = Class(TAIntegrator) //интегратор для целей и не только
      public
        procedure Run(proc: TProc; t0: real; tk: real);
    End;

   (*************************************************************)

    
(*************************************************************)
implementation
(*************************************************************)

uses Simulation;

  constructor TPosObject.Create(initParam: array of Real);   //конструктор для объекта-точки
  begin
    self.CurPosition.x := initParam[0];
    self.CurPosition.y := initParam[1];
    self.InitPosition.x := initParam[0];
    self.InitPosition.y := initParam[1];
    self.CurTime := initParam[2];
  end;

  procedure TPosObject.Move(ti: Real);     //передвижение, по факту просто меняет время (сеттер)
  begin
    self.CurTime := ti;
  end;

  function TPosObject.GetTime: real;       //Геттер для времени
  begin
    result := self.CurTime;
  end;

  destructor TPosObject.Destroy;
  begin
    //insert code here
  end;

  (*************************************************************)

  constructor TTarget.Create(TargetType: TTargetType; initParam: array of Real);  //конструктор для цели (базовой)
  begin
    inherited Create(initParam);
    self.TargetType := TargetType;
    self.Destroyed := NotDestroyed;
    self.Mass := initParam[3];
    //сразу инвертируем курс чтобы цели летели на КП, в MOVE не нужен минус.
    with self.MoveParam do begin
      P0 := initParam[4];
      mFuel := initParam[5];
      dm := initParam[6];
      mCritFuel := initParam[7];
    end;
    with self.ResistParam do begin
      S := initParam[8];
      Cx := initParam[9];
    end;
  end;

  function TTarget.GetV: real;          //Геттер для скорости
  begin
    result := self.TargetV;
  end;

  procedure TTarget.SetV(newV: Real);  //Сеттер для скорости (скорость не может быть меньше 0)
  begin
    if newV < 0 then self.TargetV := 0
    else self.TargetV := newV;
  end;

  function TTarget.GetMass;            //Геттер массы
  begin
    result := self.TargetMass;
  end;

  procedure TTarget.SetMass(newMass: Real);    //Сеттер массы, тоже не может быть меньше 0, если такое происходит, то дефолтное значение - 1000
  begin
    if newMass > 0 then self.TargetMass := NewMass
    else self.TargetMass := 1000;
  end;

  function TTarget.CalcTime(ti: Real): real;  //функция для интегратора, изменение времени
  begin
    result := 1;
  end;

  procedure TTarget.CalcCourse(CP: TPoint);   //расчёт курса
  var dx, dy: real;
  begin
    dx := self.CurPosition.x - CP.x;
    dy := self.CurPosition.y - CP.y;
    if (dx <> 0) then self.Course := arctan(self.CurPosition.y/self.CurPosition.x);
    if (dx > 0) then self.Course := self.Course + pi;
    if (dx = 0) then begin
      if dy < 0 then self.Course := pi/2
      else self.Course := -pi/2;
    end;
  end;

  procedure TTarget.selfDestruct;
  begin
    self.Destroyed := Destroyed;
    self.V := 0;
    self.MoveParam.P0 := 0;
  end;

  procedure TTarget.CalcTarget(Time: Real; Dt: Real);   //расчёт самой цели
  begin
  if self.Destroyed = NotDestroyed then begin
    if self.TargetType = Air then
      with self as TAircraft do begin
        self.MoveParam.mFuel := self.MoveParam.mFuel - self.CalcMFuel(time)*dt;
        self.ResistParam.X := self.CalcResist(time);
        self.MoveParam.P := self.CalcP(time);
        self.V := self.V + self.CalcV(time)*dt;
        self.CurPosition.x := self.CurPosition.x + self.CalcX(time)*dt;
        self.CurPosition.y := self.CurPosition.y + self.CalcY(time)*dt;
      end//with end

    else
      with self as TMissile do begin
        self.MoveParam.mFuel := self.MoveParam.mFuel - self.CalcMFuel(time)*dt;
        self.ResistParam.X := self.CalcResist(time);
        self.MoveParam.P := self.CalcP(time);
        self.V := self.V + self.CalcV(time)*dt;
        self.CurPosition.x := self.CurPosition.x + self.CalcX(time)*dt;
        self.CurPosition.y := self.CurPosition.y + self.CalcY(time)*dt;
      end;//with end
    self.Time := time;
    end;
  end;

  destructor TTarget.Destroy;
  begin

  end;

  (*************************************************************)

  constructor TAircraft.Create(initParam: array of Real);  //конструктор самолёта
  begin
    inherited Create(Air, InitParam);
  end;

  function TAircraft.CalcMFuel(ti: Real): real;            //расчёт топлива, для интегратора
  begin
    if self.MoveParam.mFuel > 0 then
      result := self.MoveParam.dm
    else result := 0;
  end;

  function TAircraft.CalcResist(ti: Real): real;          //расчёт резиста (вероятность крайне мала)
  begin
    with self.ResistParam do
      result := Cx*ro*sqr(self.V)*S/2;
  end;

  function TAircraft.CalcP(ti: Real): real;               //расчёт тяги
  begin
    if self.MoveParam.mFuel <= self.MoveParam.mCritFuel then result := self.MoveParam.P0*(self.MoveParam.mFuel/self.MoveParam.mCritFuel)
    else result := self.MoveParam.P0;
  end;

  function TAircraft.CalcV(ti: Real): real;               //расчёт скороти, для интегратора
  begin
    result := (self.MoveParam.P - self.ResistParam.X)/self.mass;
  end;

  function TAircraft.CalcX(ti: Real): real;               //тут считаются координаты
  begin
    result := self.V*cos(self.Course);
  end;

  function TAircraft.CalcY(ti: Real): real;               //тут тоже
  begin
    result := self.V*sin(self.Course);
  end;

  (*************************************************************)

  constructor TMissile.Create(initParam: array of Real);   //конструктор, далее - тоже самое, что и для самолёта
  begin
    inherited Create(Mis, InitParam);
  end;

  function TMissile.CalcMFuel(ti: Real): real;
  begin
    result := (-1)*self.MoveParam.dm;
  end;

  function TMissile.CalcResist(ti: Real): real;
  begin
    with self.ResistParam do
      result := Cx*ro*sqr(self.V)*S/2;
  end;

  function TMissile.CalcP(ti: Real): real;
  begin
    if self.MoveParam.mFuel <= self.MoveParam.mCritFuel then result := self.MoveParam.P0*(self.MoveParam.mFuel/self.MoveParam.mCritFuel)
    else result := self.MoveParam.P0;
  end;

  function TMissile.CalcV(ti: Real): real;
  begin
    result := (self.MoveParam.P - self.ResistParam.X)/self.mass;
  end;

  function TMissile.CalcX(ti: Real): real;
  begin
    result := self.V*cos(self.Course);
  end;

  function TMissile.CalcY(ti: Real): real;
  begin
    result := self.V*sin(self.Course);
  end;

  (*************************************************************)

  constructor TSAMMissile.Create(InitParam: array of Real);  //конструктор
  begin
    inherited Create(initParam);
    self.TargetType := SamMis;
    self.LifeTime := 0;
    self.isLoze := 0;
    self.fly := 0;
    self.DelegateTarget := Nil;
  end;

  function TSAMMissile.CalcMFuel(ti: Real): real;   //см самолёт, всё то же самое
  begin
    result := (-1)*self.MoveParam.dm;
  end;

  function TSAMMissile.CalcResist(ti: Real): real;
  begin
    with self.ResistParam do
      result := Cx*ro*sqr(self.V)*S/2;
  end;

  function TSAMMissile.CalcP(ti: Real): real;
  begin
    if self.MoveParam.mFuel <= self.MoveParam.mCritFuel then result := self.MoveParam.P0*(self.MoveParam.mFuel/self.MoveParam.mCritFuel)
    else result := self.MoveParam.P0;
  end;

  function TSAMMissile.CalcV(ti: Real): real;        //только тут ещё каждый раз просчитывается новый курс
  begin
    result := (self.MoveParam.P - self.ResistParam.X)/self.mass;
  end;

  function TSAMMissile.CalcX(ti: Real): real;
  begin
    result := self.V*cos(self.Course);
  end;

  function TSAMMissile.CalcY(ti: Real): real;
  begin
    result := self.V*sin(self.Course);
  end;

  procedure TSAMMissile.LockTarget(Target: TTarget); //получение цели и запуск
  begin
    if (self.LockedTarget = Nil) and (self.fly = 0) then begin self.DelegateTarget := Target; self.fly := 1; self.isLoze := 0; end;
  end;

  function TSAMMissile.GetLockTarget: TTarget;
  begin
    result := self.DelegateTarget;
  end;

  procedure TSAMMissile.SetLifeTime(time: Real);  //установка времени жизни
  begin
    if time >= 0 then self.time := time
    else self.time := 0;
  end;

  function TSAMMissile.GetLifeTime;
  begin
    result := Self.time;
  end;

  procedure TSAMMissile.CheckTarget;  //проверка на нахождение цели в радиусе поражения
  begin
    if sqrt(sqr(self.CurPosition.x - self.DelegateTarget.CurPosition.x)+sqr(self.CurPosition.x - self.DelegateTarget.CurPosition.x))<= self.DLoze
    then self.Explode
    else
    if self.LifeTime > self.TMax then self.selfDestruct;
  end;

  procedure TSAMMissile.Explode;     //взрыв если цель в радиусе поражения
  var prob: real;
  begin
    randomize;
    prob := random;
    if prob < self.PReq then self.selfDestruct;
    if (prob >= self.Pmin) and (prob <= self.Pmax) then 
    begin 
      self.DelegateTarget.selfDestruct;
      self.isLoze := 1;
      inherited SelfDestruct;
    end;
  end;

  procedure TSAMMissile.selfDestruct;   //протокол самоуничтожения
  begin
    self.IsLoze := -1;
    inherited selfDestruct;
  end;

  procedure TSAMMissile.calcTarget(time, dt: real);  //функция правых частей + просчёт курса на цель + увеличение текущего времени жизни
  begin
    if (Self.fly = 1) and (self.isLoze = 0) then begin
      self.Course := self.CalcCourse;
      inherited calcTarget(time, dt);
      self.LifeTime := self.LifeTime + dt;
    end;
  end;

  function TSAMMissile.CalcCourse: real;
  var dx, dy, c: real;
  begin
    dx := self.DelegateTarget.CurPosition.x - self.CurPosition.x;
    dy := self.DelegateTarget.CurPosition.y - self.CurPosition.y;
    if (dx <> 0) then c := arctan(dy/dx);
    if (dx < 0) then c := c + pi;
    if (dx = 0) then begin
      if dy < 0 then c := -pi/2
      else c := pi/2;
    end;
    result := c;
  end;

  (*************************************************************)

  constructor TCommandPost.Create(initParam: array of Real);  //конструктор для командного поста
  begin
    inherited Create(initParam);
    self.SafetyDistance := initParam[3];
  end;

  procedure TCommandPost.Move(ti: Real);                     //по факту - просто сеттер времени
  begin
    inherited Move(ti);
  end;

  (*************************************************************)

  constructor TRLS.Create(initParam: array of Real);         //конструктор РЛС
  begin
    inherited Create(initParam);
    self.RMax := initParam[3];
    self.Distance := 0;
    self.Course := 0;
  end;

  procedure TRLS.Move(ti: Real);                             //см CP.Move
  begin
    inherited Move(ti);
  end;

  procedure TRLS.SetSamMissileList(SamList: TTargetList);     //Установка списка доступных ракет и ещё некоторые нужные вещи
  var index: integer;
  begin
    if self.SamMissileList = Nil then begin
      self.SamMissileList := SamList;
      SetLength(self.LaunchedMissiles, self.SamMissileList.Count);
      for index := 0 to self.SamMissileList.Count-1 do
        self.LaunchedMissiles[index] := false;
    end;
  end;

  procedure TRLS.SetTargetList(TargetList: TTargetList);  //Установка списка целей и ещё некоторые действия
  var index: integer;
  begin
    if self.TargetList = Nil then
    begin
      self.TargetList := TargetList;
      SetLength(self.DistanceToCP, self.TargetList.Count);
      SetLength(self.LockedTargets, self.TargetList.Count);
      for index := 0 to self.TargetList.Count-1 do begin
        self.DistanceToCP[index] := CalcDist(self.TargetList[index].CurPosition);
        self.LockedTargets[index] := false;
      end;
    end;
  end;

  procedure TRLS.SetCP(pos: TPoint);     //Установка положения CP
  begin
    self.CP := pos;
  end;

  procedure TRLS.CheckTargets;  //проверка целей на возможность сбития
  var index, minIndex: integer;
      minDist: real;
  begin
    for index := 0 to self.TargetList.Count-1 do
      self.DistanceToCP[index] := CalcDist(self.TargetList[index].CurPosition);

    minDist := Rmax+1;
    for index := 0 to Length(self.DistanceToCP)-1 do
      if (Self.DistanceToCP[index] < MinDist) and (self.LockedTargets[index] = false) then
      begin
        minDist := self.DistanceToCP[index]; minIndex := index;
        if minDist <> Rmax+1 then self.LaunchMissile(minIndex);
      end;
  end;

  procedure TRLS.LaunchMissile(target: Integer);
  var availableMis: integer; index: integer; Mis: TSAMMissile;
  begin
    availableMis := -1;
    for index := 0 to self.SamMissileList.Count-1 do begin
      Mis := TSAMMissile(self.SamMissileList[index]);
      if Mis.fly = 0 then begin availableMis := index; break; end;
    end;
    if availableMis <> -1 then 
    begin 
      Mis.LockTarget(self.TargetList[target]); 
      self.LockedTargets[target] := true;
      self.LaunchedMissiles[availableMis] := true;
      self.WriteSQLSAMMIS(Target);
    end;
  end;

  function TRLS.Peleng(ti: Real; Target: TTarget): boolean;    //Проверка на попадание цели в зону обнаружения
  var dx, dy: real;
  begin
    self.Move(ti);
    self.Distance := self.CalcDist(Target.CurPosition);
    if Distance <= self.RMax then begin
      CheckTargets;
      dx := Target.CurPosition.x - self.CurPosition.x;
      dy := Target.CurPosition.y - self.CurPosition.y;
      self.Course := CalcTan(dx, dy);
      result := True;
    end else
      result := False;
  end;

  function TRLS.CalcDist(pos: TPoint):real; //расчёт дистанции до КП
  begin
    result := sqrt(sqr(pos.x - self.CP.x) + sqr(pos.y - self.CP.y));
  end;

  function TRLS.CalcTan(dx: Real; dy: Real): real; //вычисление направления
  var c: real;
  begin
    if dx = 0 then begin
      if dy > 0 then c := pi/2;
      if dy < 0 then c := - pi/2;
      if dy = 0 then c := 0;
    end else
      if dy = 0 then c := 0
      else c := arctan(Dy/dx);
    if dx < 0 then c := c + pi;
    result := c;
  end;

  (*************************************************************)

  function TTargetList.AddTarget(TargetType: TTargetType; initParam: array of Real): integer;  //дабавление цели в список целей
  var Aircraft: TAircraft; Missile: TMissile; SamMissile: TSamMissile;
  begin
    if TargetType = Air then begin Aircraft := TAircraft.Create(initParam); self.Add(Aircraft); end;
    if TargetType = Mis then begin Missile := TMissile.Create(initParam); self.Add(Missile); end;
    if TargetType = SAMMis then begin SamMissile := TSAMMissile.Create(initParam); self.Add(SamMissile); end;

    Aircraft := Nil; Missile := Nil; SamMissile := Nil;
    result := self.Count;
  end;

  procedure TTargetList.InsertTarget(index: integer; TargetType: TTargetType; initParam: array of Real);  //вставка цели с созданием оной
  var Aircraft: TAircraft; Missile: TMissile;
  begin
    if TargetType = Air then Aircraft := TAircraft.Create(initParam)
    else Missile := TMissile.Create(initParam);
    if Aircraft <> Nil then self.Insert(index, Aircraft)
    else self.Insert(index, Missile);
    Aircraft := Nil; Missile := Nil;
  end;

  procedure TTargetList.Clear;    //очистка листа
  var i: integer; target: TTarget;
  begin
    for i := 0 to self.Count - 1 do begin target := self.Items[i]; target.Destroy; end;
    self.Count := 0;
    self.Capacity := 0;
    inherited Clear;
  end;

  (*************************************************************)

  procedure TTargetIntegrator.Run(proc: TProc; t0: real; tk: real);  //процесс интеграции
  var dt, time: real;
  begin
    dt := (tK - T0)/self.num;
    time := t0;
    while time < TK do begin
      proc(time, dt);
      time := time + dt;
    end;//while end
  end;//procedure end

end.
