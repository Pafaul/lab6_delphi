unit TNC;
//types and constants
interface

  uses Winapi.Messages;

  const WM_DRAW_SIMULATION = WM_USER+1;      //пользовательское сообщение, но тут вообще события, на всякий случай оставлю

  type

    TProc = procedure(time,dt: real) of object;  //процедурный тип объекта, нужен для интегратора (вроде)
    TProcWriteSAM = procedure(num: integer) of object;
    TTargetType = (Air, Mis, SAMMis);        //Типы целей
    TDestroyedType = (NotDestroyed, Destroyed);        //Уничтожен или нет
    TMisActivated = 0..1;                    //активирована ли ракета TSAMMissile
    TIsLoze = -1..1;                         //для isLoze TSamMissile
    TPoint = record                          //Просто точка
      x, y: real;
    end;

   (*************************************************************)

    TTargetMoveParam = record                //Параметры тяги, для целей и не только
      P: real;
      P0: real;
      dm: real;
      mFuel: real;
      mCritFuel: real;
    end;

   (*************************************************************)

    TResistParam = record                    //Параметры сопротивления, для целей и не только
      X: real;
      Cx: real;
      S: real;
      const ro = 1.029;
    end;

implementation

end.
