unit UIntegrator;

interface
  type
  TFunc = function (param: real): real;
  PFunc = ^TFunc;

  TAIntegrator = class(TObject)
    public
      procedure Run(var X: array of real; Func: array of TFunc; T0, TK: real); virtual; abstract;
    protected
      const num = 4;
  end;

  TIntegrator = class(TAIntegrator)
    public
      procedure Run(var X: array of Real; Func: array of TFunc; T0: Real; TK: Real); override;
  end;

implementation

  procedure TIntegrator.Run(var X: array of Real; Func: array of TFunc; T0: Real; TK: Real);
  var i: integer; dt, time: real;
  begin
    time := t0;
    dt := (tK - T0)/self.num;
    while time < TK do begin
      for i := 0 to length(X)-1 do
        X[i] := X[i] + (Func[i](time))*dt;
      time := time + dt;
    end;
  end;

end.
