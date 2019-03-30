unit Simulation;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.ComCtrls, extctrls, Vcl.StdCtrls,
  Vcl.Menus, UTargets, USimulator, TNC, Threads, Data.DB, Data.Win.ADODB, grids,
  Vcl.DBGrids, Bde.DBTables;

const
  EditLabelWidth = 65;
  EditLabelHeight = 34;
  EditLabelWidthGap = 15;
  EditLabelHeightGap = 14;

type

  TForm2 = class(TForm)
    PageControl1: TPageControl;
    SimulationConditions: TTabSheet;
    SimulationOutput: TTabSheet;
    CreateOutput: TGroupBox;
    CreateSection: TGroupBox;
    SimulationParam: TGroupBox;
    RunSimulationSection: TGroupBox;
    SimulationImage: TImage;
    CreateChoice: TComboBox;
    ParamSection: TGroupBox;
    T0Edit: TLabeledEdit;
    TKEdit: TLabeledEdit;
    DTEdit: TLabeledEdit;
    RunSimulationButton: TButton;
    XParam: TLabeledEdit;
    YParam: TLabeledEdit;
    ThirdParam: TLabeledEdit;
    PParam: TLabeledEdit;
    FuelMassParam: TLabeledEdit;
    FuelConsParam: TLabeledEdit;
    CritFuelParam: TLabeledEdit;
    SParam: TLabeledEdit;
    CxParam: TLabeledEdit;
    CreateButton: TButton;
    CreateLog: TMemo;
    TimeLabel: TLabel;
    ADOConnection: TADOConnection;
    ADOQuery: TADOQuery;
    TabSheet1: TTabSheet;
    Memo1: TMemo;
    TableComboBox: TComboBox;
    FieldComboBox: TComboBox;
    ConditionEdit: TEdit;
    StringGrid: TStringGrid;
    ConditionComboBox: TComboBox;
    exeSQLButton: TButton;
    procedure OnResize(Sender: TObject);
    procedure CreateChoiceChange(Sender: TObject);
    procedure SwapActive(choice: boolean);
    procedure OnCreate(Sender: TObject);
    procedure CreateButtonClick(Sender: TObject);
    //procedure DrawSimulation(var msg: TMessage); message WM_DRAW_SIMULATION;
    procedure DrawSimulation(Sender: TObject);//���������
    procedure RunSimulationButtonClick(Sender: TObject);
    procedure DrawCP;
    procedure DrawRLS;
    procedure FormDestroy(Sender: TObject);
    procedure exeSQLButtonClick(Sender: TObject);
    procedure PageControl1Change(Sender: TObject);
    procedure TableComboBoxSelect(Sender: TObject);
  private
    CenterCoordinates: array[0..1] of integer; //����������� ��� ���������, ������������ ����������
    FirstCheck: boolean;                    //��������, ���� �� � ������ ��� �������� ��������� ���������
    Ratio: array[0..1] of real;          //������������ �������� ��� ���������
  public
    { Public declarations }
  end;

var
  Form2: TForm2;
  Simulator: TSimulator;
  RunThread: TRunThread;
  VisThread: TVisThread;

implementation

{$R *.dfm}

procedure TForm2.exeSQLButtonClick(Sender: TObject);
var str: String;
  i, len: Integer;
  k: Integer;
begin
  str := 'SELECT ';
  str := str + FieldComboBox.Items[FieldComboBox.ItemIndex] + ' ';
  str := str + 'FROM ' + TableComboBox.Items[TableComboBox.ItemIndex] + ' ';
  if (FieldComboBox.ItemIndex <> -1) and (ConditionComboBox.ItemIndex <> -1) then begin
    str := str + 'WHERE ' + FieldComboBox.Items[FieldComboBox.ItemIndex] + ' ';
    str := str + ConditionComboBox.Items[ConditionComboBox.ItemIndex] + ' ';
    str := str + ConditionEdit.Text;
  end;
  Memo1.Lines.Add(str);
  ADOQuery.SQL.Clear;
  ADOQuery.SQL.Add(str);
  ADOQuery.Active := True;
  StringGrid.ColCount := 1;
  StringGrid.RowCount := 1;

  StringGrid.Cells[0,0] := FieldComboBox.Items[FieldCOmboBox.ItemIndex];
  k := 1;
  while (not ADOQuery.EOF) do begin
    stringGrid.RowCount := stringGrid.RowCount + 1;
    StringGrid.Cells[0,k] := ADOQuery.FieldByName(FieldComboBox.Items[FieldComboBox.ItemIndex]).asString;
    inc(k);
    ADOQuery.Next;
  end;
  //end;
  ADOQuery.SQL.Clear;
end;

procedure TForm2.CreateButtonClick(Sender: TObject);
var initParam: array of real;
procedure fillParam;
begin
  setLength(initParam, 9);
  initParam[3]:=strToFloat(ThirdParam.Text);
  initParam[4]:=strToFloat(PParam.Text);
  initParam[5]:=strToFloat(FuelMassParam.Text);
  initParam[6]:=strToFloat(FuelConsParam.Text);
  initParam[7]:=strToFloat(CritFuelParam.Text);
  initParam[8]:=strToFloat(SParam.Text);
  initParam[9]:=strToFloat(CxParam.Text);
end;
procedure showTargetParam;
begin
  CreateLog.Lines.Add('X: ' + floatToStr(initParam[0]) + '; Y: ' + floatToStr(initParam[1]) + '; Mass: ' + floatToStr(initParam[3]));
  CreateLog.Lines.Add('P: ' + floatToStr(InitParam[4]) + '; Fuel Mass: ' + floatToStr(initParam[5]) + '; Fuel Consumption: ' + floatToStr(initParam[6]) + '; Critical Fuel Mass: ' + floatToStr(initParam[7]));
  CreateLog.Lines.Add('Square: ' + floatToStr(initParam[8]) + '; Cx: ' + floatToStr(initParam[9]));
end;
  begin
  setLength(initParam, 4);
  initParam[0] := strToFloat(self.XParam.Text);
  initParam[1] := strToFloat(self.YParam.Text);
  initParam[2] := strToFloat(self.T0Edit.Text);
  initParam[3] := strToFLoat(self.ThirdParam.Text);
  case self.CreateChoice.ItemIndex of
    0:
    begin
      Simulator.CreateCP(initParam);
      CreateLog.Lines.Add('CP Created.');
      CreateLog.Lines.Add('X: ' +  floatToStr(initParam[0]) + '; Y: ' + floatToStr(initParam[1]) + '; Safe Distance: ' + floatToStr(initParam[3]));
      DrawCP;
    end;
    1:
    begin
      Simulator.CreateRLS(InitParam);
      CreateLog.Lines.Add('RLS Created.');
      CreateLog.Lines.Add('X: ' +  floatToStr(initParam[0]) + '; Y: ' + floatToStr(initParam[1]) + '; R Max: ' + floatToStr(initParam[3]));
      DrawRLS;
      if Simulator.CP <> NIl then DrawCP;
    end;
    2:
    begin
      fillParam;
      Simulator.CreateTarget(Air,initParam);
      CreateLog.Lines.Add('Aircraft Created.');
      showTargetParam;
    end;
    3:
    begin
      fillParam;
      Simulator.CreateTarget(Mis,initParam);
      CreateLog.Lines.Add('Missile Created.');
      showTargetParam;
    end;
    4:
    begin
      fillParam;
      Simulator.CreateTarget(SamMis,initParam);
      CreateLog.Lines.Add('SamMissile Created.');
      showTargetParam;
    end;
    else ShowMessage('�� ������ �� �������!');
  end;

end;

procedure TForm2.CreateChoiceChange(Sender: TObject);
begin
  case self.CreateChoice.ItemIndex of
  0: self.ThirdParam.EditLabel.Caption := 'Safe Dist:';
  1: self.ThirdParam.EditLabel.Caption := 'R max:';
  else self.ThirdParam.EditLabel.Caption := 'Mass: ';
  end;
  if (self.CreateChoice.ItemIndex=0) or (self.CreateChoice.ItemIndex=1) then self.SwapActive(false)
  else self.SwapActive(True);
  self.Width := self.Width + 1;
  self.Width := self.Width - 1;
end;

procedure TForm2.OnCreate(Sender: TObject);
var initParam: array[0..2] of real; x,y: real;
begin

  initParam[0] := 0; initParam[1] := 100; initParam[2] := 0.1;
  Simulator := TSimulator.Create(initParam);
  //Simulator.DrawSimulation := self.DrawSimulation;
  Simulator.Owner := self;

  VisThread := TVisThread.Create(true);
  RunThread := TRunThread.Create(true);

  self.Constraints.MinHeight := 550;
  self.Constraints.MinWidth := 700;
  self.PageControl1.Constraints.MinHeight := self.Constraints.MinHeight;
  self.PageControl1.Constraints.MinWidth := self.Constraints.MinWidth;
  self.T0Edit.Text := '0,0';
  self.TKEdit.Text := '100,0';
  self.DTEdit.Text := '0,1';

  self.SimulationImage.Align := alClient;

  self.FirstCheck := True;
  //���������� ������������� ��������������
  x := 500;
  y := self.SimulationImage.Height/self.SimulationImage.Width*500;
  self.Ratio[0] := self.SimulationImage.Width/x/2;
  self.Ratio[1] := self.SimulationImage.Height/y/2;
  //���������� ��������� ������
  self.CenterCoordinates[0] := self.SimulationImage.Width div 2;
  self.CenterCoordinates[1] := self.SimulationImage.Height div 2;

  //���������� ��������� ������
  self.CenterCoordinates[0] := self.SimulationImage.Width div 2;
  self.CenterCoordinates[1] := self.SimulationImage.Height div 2;
  //�������
  self.SimulationImage.Canvas.Brush.Color := VCL.Graphics.clYellow;
  self.SimulationImage.Canvas.Brush.Style := VCL.Graphics.TBrushStyle.bsCross;
  self.SimulationImage.Canvas.Rectangle(0,0,self.SimulationImage.Width,self.SimulationImage.Height);
  //������������ �����
  self.SimulationImage.Canvas.Brush.Color := RGB(255,255,255);
  self.SimulationImage.Canvas.Brush.Style := VCL.Graphics.TBrushStyle.bsSolid;
  self.SimulationImage.Canvas.MoveTo(0, self.CenterCoordinates[1]);
  self.SimulationImage.Canvas.LineTo(self.SimulationImage.Width, self.CenterCoordinates[1]);
  self.SimulationImage.Canvas.MoveTo(self.CenterCoordinates[0], 0);
  self.SimulationImage.Canvas.LineTo(self.CenterCoordinates[0], self.SimulationImage.Height);
  self.PageControl1.ActivePageIndex := 0;
end;

procedure TForm2.OnResize(Sender: TObject);
begin
  self.XParam.Top := self.ParamSection.Top + 25 + 10; self.XParam.Left := self.ParamSection.Left + 30;
  self.YParam.Top := self.XParam.Top; self.YParam.Left := self.XParam.Left + EditLabelWidth + EditLabelWidthGap;
  self.ThirdParam.Top := self.XParam.Top; self.ThirdParam.Left := self.YParam.Left + EditLabelWidth + EditLabelWidthGap;

  self.PParam.Top := self.XParam.Top + EditLabelHeight + 10 + 10; self.PParam.Left := self.XParam.Left;
  self.FuelMassParam.Top := self.PParam.Top; self.FuelMassParam.Left := self.PParam.Left + EditLabelWidth + EditLabelWidthGap;
  self.FuelConsParam.Top := self.PParam.Top; self.FuelConsParam.Left := self.PParam.Left + 2*EditLabelWidth + 2*EditLabelWidthGap;
  self.CritFuelParam.Top := self.PParam.Top; self.CritFuelParam.Left := self.PParam.Left + 3*EditLabelWidth + 3*EditLabelWidthGap;
  self.SParam.Top := self.PParam.Top; self.SParam.Left := self.PParam.Left + 4*EditLabelWidth + 4*EditLabelWidthGap;
  self.CxParam.Top := self.PParam.Top; self.CxParam.Left := self.PParam.Left + 5*EditLabelWidth + 5*EditLabelWidthGap;

  self.CreateChoice.Left := 5;
  self.CreateChoice.Top := 20;

  self.CreateButton.Left := 25;
  self.CreateButton.Top := 70;

  self.RunSimulationButton.Left := self.RunSimulationSection.Width - 150;
  self.RunSimulationButton.Top := self.RunSimulationSection.Top - 175;

  self.SimulationImage.Top := 50;
  self.SimulationImage.Left := 10;
end;

procedure TForm2.PageControl1Change(Sender: TObject);
var i: integer;
    tables: TStrings;
begin
  if PageControl1.TabIndex = 2 then begin
    ADOConnection.GetTableNames(TableComboBox.Items, false);
    {for i := 0 to tables.Count-1 do
      TableComboBox.Items.Add(tables[i]); }
  end;

end;

procedure TForm2.RunSimulationButtonClick(Sender: TObject);
begin
  if (Simulator.CP <> Nil) and (Simulator.RLS <> Nil) and (Simulator.Targets.Count <> 0) then begin
    Simulator.T0 := strToFloat(self.T0Edit.Text);
    Simulator.TK := strToFloat(self.TKEdit.Text);
    Simulator.DT := strToFloat(self.DTEdit.Text);
    CreateLog.Lines.Add('Starting Simulation.');
    CreateLog.Lines.Add(floatToStr(Simulator.Tk));
    self.PageControl1.ActivePageIndex := 1;
    RunThread.Resume;
    VisThread.Resume;
    CreateLog.Lines.Add('Simulation Finished.');
  end;
  if Simulator.CP = Nil then ShowMessage('Create CP before Run!');
  if Simulator.RLS = Nil then ShowMessage('Create RLS before Run!');
  if Simulator.Targets.Count = 0 then ShowMessage('Create Targets before Run!');

end;

procedure TForm2.SwapActive(choice: boolean);
begin
  self.PParam.Enabled := choice;
  self.FuelMassParam.Enabled := choice;
  self.FuelConsParam.Enabled := choice;
  self.CritFuelParam.Enabled := choice;
  self.SParam.Enabled := choice;
  self.CxParam.Enabled := choice;
end;

procedure TForm2.TableComboBoxSelect(Sender: TObject);
begin
  ADOConnection.GetFieldNames(TableComboBox.Items[TableComboBox.ItemIndex], FieldComboBox.Items);
  //ADOConnection.GetFieldNames(TableComboBox.Items[TableComboBox.ItemIndex], ConditionColComboBox.Items);
end;

(*procedure TForm2.TableComboBoxChange(Sender: TObject);
begin
  //ADOConnection.GetFieldNames(TableComboBox.Items[TableComboBox.ItemIndex], FieldComboBox.Items);
end;

procedure TForm2.TableComboBoxClick(Sender: TObject);
var tables: TStrings;
  i: Integer;
begin
  ADOConnection.GetTableNames(tables, true);
  for i := 0 to tables.Count-1 do
    TableComboBox.Items.Add(tables[i]);
  FieldComboBox.Enabled := True;
end;  *)

procedure TForm2.DrawSimulation(Sender: TObject);
var target: TTarget;
  k: Integer;
  DrawCoordinates: array[0..3] of integer;
  CurTime: TDateTime;
procedure DrawTarget(i: integer);
begin
  if i = 0 then begin self.SimulationImage.Canvas.Brush.Color := RGB(100,0,0);
  self.SimulationImage.Canvas.Brush.Style := VCL.Graphics.TBrushStyle.bsSolid; end;
  if i = 1 then begin self.SimulationImage.Canvas.Brush.Color := RGB(0,100,100);
  self.SimulationImage.Canvas.Brush.Style := VCL.Graphics.TBrushStyle.bsSolid; end;

  if (Abs(Target.CurPosition.x*self.Ratio[0]+self.CenterCoordinates[0]) <= self.SimulationImage.Width) and
     (Abs(-Target.CurPosition.y*self.Ratio[1]+self.CenterCoordinates[1]) <= self.SimulationImage.Height) then begin
    self.SimulationImage.Canvas.Brush.Color := RGB(255, 0, 0);
    self.SimulationImage.Canvas.Pen.Style := VCL.Graphics.TPenStyle.psClear;
    DrawCoordinates[0] := Trunc(Target.CurPosition.x*self.Ratio[0]+self.CenterCoordinates[0]);
    DrawCoordinates[1] := Trunc(-Target.CurPosition.y*self.Ratio[1]+self.CenterCoordinates[1]);
    DrawCoordinates[2] := DrawCoordinates[0] + 5;
    DrawCoordinates[3] := DrawCoordinates[1] + 5;
    self.SimulationImage.Canvas.Rectangle(DrawCoordinates[0], DrawCoordinates[1],
                                          DrawCoordinates[2], DrawCOordinates[3]);
  end;
end;
begin
  for k := 0 to (TSimulator(Sender).Targets.Count-1) do begin
    Target := TSimulator(Sender).Targets[k];
    DrawTarget(0);
  end;

  for k := 0 to (TSimulator(Sender).SamMissileList.Count-1) do begin
    Target := TSimulator(Sender).SamMissileList[k];
    DrawTarget(1);
  end;
  CurTime := Now;
  TimeLabel.Caption := TimeToStr(CurTime);
end;

(*procedure TForm2.FieldComboBoxChange(Sender: TObject);
begin
  ADOConnection.GetFieldNames(TableComboBox.Items[TableComboBox.ItemIndex], FieldComboBox.Items);
  ConditionComboBox.Enabled := True;
  ConditionEdit.Enabled := True;
end; *)

procedure TForm2.FormDestroy(Sender: TObject);
begin
  Simulator.Free;
end;

procedure TForm2.DrawCP;
begin
  self.SimulationImage.Canvas.Brush.Color := clFuchsia;
  self.SimulationImage.Canvas.Brush.Style := VCL.Graphics.TBrushStyle.bsDiagCross;
  self.SimulationImage.Canvas.Ellipse(Trunc((Simulator.CP.CurPosition.x - Simulator.CP.SafetyDistance)*Ratio[0] + CenterCoordinates[0]),
                                      Trunc(-(Simulator.CP.CurPosition.y + Simulator.CP.SafetyDistance)*Ratio[1] + CenterCOordinates[1]),
                                      Trunc((Simulator.CP.CurPosition.x + Simulator.CP.SafetyDistance)*Ratio[0] + CenterCoordinates[0]),
                                      Trunc((-Simulator.CP.CurPosition.y+ Simulator.CP.SafetyDistance)*Ratio[1] + CenterCOordinates[1]));
  self.SimulationImage.Canvas.Brush.Color := RGB(100,0,100);
  self.SimulationImage.Canvas.Brush.Style := VCL.Graphics.TBrushStyle.bsSolid;
  self.SimulationImage.Canvas.Rectangle(Trunc(Simulator.CP.CurPosition.x*Ratio[0] + CenterCoordinates[0])-2,
                                        Trunc(-Simulator.CP.CurPosition.y*Ratio[1] + CenterCOordinates[1])-2,
                                        Trunc(Simulator.CP.CurPosition.x*Ratio[0] + CenterCoordinates[0])+2,
                                        Trunc(-Simulator.CP.CurPosition.y*Ratio[1] + CenterCOordinates[1])+2);
end;

procedure TForm2.DrawRLS;
begin
  self.SimulationImage.Canvas.Brush.Color := clAqua;
  self.SimulationImage.Canvas.Brush.Style := VCL.Graphics.TBrushStyle.bsDiagCross;
  self.SimulationImage.Canvas.Ellipse(Trunc((Simulator.RLS.CurPosition.x - Simulator.RLS.RMax)*Ratio[0] + CenterCoordinates[0]),
                                      Trunc(-(Simulator.RLS.CurPosition.y + Simulator.RLS.RMax)*Ratio[1] + CenterCOordinates[1]),
                                      Trunc((Simulator.RLS.CurPosition.x + Simulator.RLS.RMax)*Ratio[0] + CenterCoordinates[0]),
                                      Trunc((-Simulator.RLS.CurPosition.y+ Simulator.RLS.RMax)*Ratio[1] + CenterCOordinates[1]));
  self.SimulationImage.Canvas.Brush.Color := RGB(0,100,100);
  self.SimulationImage.Canvas.Brush.Style := VCL.Graphics.TBrushStyle.bsSolid;
  self.SimulationImage.Canvas.Rectangle(Trunc(Simulator.RLS.CurPosition.x*Ratio[0] + CenterCoordinates[0])-2,
                                        Trunc(-Simulator.RLS.CurPosition.y*Ratio[1] + CenterCOordinates[1])-2,
                                        Trunc(Simulator.RLS.CurPosition.x*Ratio[0] + CenterCoordinates[0])+2,
                                        Trunc(-Simulator.RLS.CurPosition.y*Ratio[1] + CenterCOordinates[1])+2);

end;
end.
