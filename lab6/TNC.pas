unit TNC;
//types and constants
interface

  uses Winapi.Messages;

  const WM_DRAW_SIMULATION = WM_USER+1;      //���������������� ���������, �� ��� ������ �������, �� ������ ������ �������

  type

    TProc = procedure(time,dt: real) of object;  //����������� ��� �������, ����� ��� ����������� (�����)
    TProcWriteSAM = procedure(num: integer) of object;
    TTargetType = (Air, Mis, SAMMis);        //���� �����
    TDestroyedType = (NotDestroyed, Destroyed);        //��������� ��� ���
    TMisActivated = 0..1;                    //������������ �� ������ TSAMMissile
    TIsLoze = -1..1;                         //��� isLoze TSamMissile
    TPoint = record                          //������ �����
      x, y: real;
    end;

   (*************************************************************)

    TTargetMoveParam = record                //��������� ����, ��� ����� � �� ������
      P: real;
      P0: real;
      dm: real;
      mFuel: real;
      mCritFuel: real;
    end;

   (*************************************************************)

    TResistParam = record                    //��������� �������������, ��� ����� � �� ������
      X: real;
      Cx: real;
      S: real;
      const ro = 1.029;
    end;

implementation

end.
