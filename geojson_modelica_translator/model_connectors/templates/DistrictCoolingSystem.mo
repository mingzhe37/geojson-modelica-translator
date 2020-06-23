// within geojson_modelica_translator.model_connectors.templates;

model DistrictCoolingSystem "Example to test the district cooling system."
  extends Modelica.Icons.Example;
{% raw %}
  package MediumW = Buildings.Media.Water "Medium model for water";
  inner parameter DesignDataParallel4GDC datDes(
    nBui=nBui,
    mDis_flow_nominal=sum({bui[i].ets.mDis_flow_nominal for i in 1:nBui})*1.01,
    mCon_flow_nominal={bui[i].ets.mDis_flow_nominal for i in 1:nBui},
    lDis={15,15,15},
    lCon={20,20,20},
    dhDis={0.08,0.05,0.05},
    dhCon={0.05,0.05,0.05})
    "Design data"
    annotation (Placement(transformation(extent={{80,40},{100,60}})));
  parameter Integer nBui=3
  "number of coonected buildings";
  parameter Modelica.SIunits.MassFlowRate mCHW_flow_nominal=cooPla.numChi*(cooPla.perChi.mEva_flow_nominal)
    "Nominal chilled water mass flow rate";
  parameter Modelica.SIunits.MassFlowRate mCW_flow_nominal=cooPla.perChi.mCon_flow_nominal
    "Nominal condenser water mass flow rate";
  parameter Modelica.SIunits.PressureDifference dpCHW_nominal=44.8*1000
    "Nominal chilled water side pressure";
  parameter Modelica.SIunits.PressureDifference dpCW_nominal=46.2*1000
    "Nominal condenser water side pressure";
  parameter Modelica.SIunits.Power QEva_nominal=mCHW_flow_nominal*4200*(5 - 14)
    "Nominal cooling capaciaty (Negative means cooling)";
  parameter Modelica.SIunits.MassFlowRate mMin_flow= 0.2*mCHW_flow_nominal
    "Minimum mass flow rate of single chiller";
  parameter Boolean allowFlowReversal = false;
  // control settings
  parameter Modelica.SIunits.Pressure dpSetPoi=80000
    "Differential pressure setpoint";
  parameter Modelica.SIunits.Pressure pumDP=dpCHW_nominal+dpSetPoi+200000;
  parameter Modelica.SIunits.Temperature TCHWSet=273.15 + 5
    "Chilled water temperature setpoint";
  parameter Modelica.SIunits.Time tWai=30 "Waiting time";
  // pumps
  parameter Buildings.Fluid.Movers.Data.Generic perCHWPum(
    pressure=Buildings.Fluid.Movers.BaseClasses.Characteristics.flowParameters(
      V_flow={0,mCHW_flow_nominal/cooPla.numChi}/1000,
      dp={pumDP,0}))
    "Performance data for chilled water pumps";
  parameter Buildings.Fluid.Movers.Data.Generic perCWPum(
    pressure=Buildings.Fluid.Movers.BaseClasses.Characteristics.flowParameters(
      V_flow=mCW_flow_nominal/1000*{0.2,0.6,1.0,1.2},
      dp=(dpCW_nominal+60000+6000)*{1.2,1.1,1.0,0.6}))
    "Performance data for condenser water pumps";
  parameter Modelica.SIunits.Pressure dpCHWPum_nominal=6000
    "Nominal pressure drop of chilled water pumps";
  parameter Modelica.SIunits.Pressure dpCWPum_nominal=6000
    "Nominal pressure drop of chilled water pumps";
  parameter Modelica.SIunits.PressureDifference dp_nominal=50000
    "Nominal pressure drop in the distribution line";
  Buildings.BoundaryConditions.WeatherData.ReaderTMY3 weaDat(
   final computeWetBulbTemperature=true,
   filNam= Modelica.Utilities.Files.loadResource(
          "modelica://Buildings/Resources/weatherdata/USA_CA_San.Francisco.Intl.AP.724940_TMY3.mos"))
    annotation (Placement(transformation(extent={{-100,-84},{-80,-64}})));
  Buildings.BoundaryConditions.WeatherData.Bus weaBus "Weather data bus"
    annotation (Placement(transformation(extent={{-114,-54},{-94,-34}}),
        iconTransformation(extent={{-114,-54},{-94,-34}})));

  Modelica.Blocks.Sources.BooleanConstant on "On signal of the plant"
    annotation (Placement(transformation(extent={{-100,0},{-80,20}})));

  CentralCoolingPlant cooPla(
    redeclare
      Buildings.Fluid.Chillers.Data.ElectricEIR.ElectricEIRChiller_Trane_CGWD_207kW_3_99COP_None
      perChi,
    perCHWPum=perCHWPum,
    perCWPum=perCWPum,
    mCHW_flow_nominal=mCHW_flow_nominal,
    dpCHW_nominal=dpCHW_nominal,
    QEva_nominal=QEva_nominal,
    mMin_flow=mMin_flow,
    mCW_flow_nominal=mCW_flow_nominal,
    dpCW_nominal=dpCW_nominal,
    TAirInWB_nominal=298.7,
    TCW_nominal=308.15,
    dT_nominal=5.56,
    TMin=288.15,
    PFan_nominal=5000,
    dpCHWPum_nominal=dpCHWPum_nominal,
    dpCWPum_nominal=dpCWPum_nominal,
    tWai=tWai,
    dpSetPoi=dpSetPoi,
    energyDynamics=Modelica.Fluid.Types.Dynamics.FixedInitial)
    "District cooling plant."
    annotation (Placement(transformation(extent={{-34,-46},{-14,-26}})));

  BuildingSpawnZ6WithCoolingIndirectETS bui[nBui](
      each dT_nominal=5,
      each TChiWatSup_nominal=7 + 273.15)
    annotation (Placement(transformation(extent={{20,60},{40,80}})));
    //dp_nominal=100000)
  Buildings.Fluid.Sources.Boundary_pT heaSou(
    redeclare package Medium = MediumW,
    T=313.15,
    nPorts=nBui) "Heating source."
    annotation (Placement(transformation(extent={{-42,70},{-22,90}})));
  Buildings.Fluid.Sources.Boundary_pT heaSin(redeclare package Medium = MediumW,
      nPorts=nBui) "Heating sink"
    annotation (Placement(transformation(extent={{82,72},{62,92}})));
  UnidirectionalParallel disNet(
    redeclare final package Medium = MediumW,
    final nCon=nBui,
    iConDpSen=nBui,
    final mDis_flow_nominal=datDes.mDis_flow_nominal,
    final mCon_flow_nominal=datDes.mCon_flow_nominal,
    final lDis=datDes.lDis,
    final lCon=datDes.lCon,
    final lEnd=datDes.lEnd,
    final dhDis=datDes.dhDis,
    final dhCon=datDes.dhCon,
    final dhEnd=datDes.dhEnd,
    final allowFlowReversal=allowFlowReversal)
    "Distribution network."
    annotation (Placement(transformation(extent={{16,20},{44,32}})));
  Modelica.Blocks.Sources.RealExpression TchiWatSet(y=TCHWSet)
    "Chilled water supply temperature setpoint."
    annotation (Placement(transformation(extent={{-80,-40},{-60,-20}})));
  Modelica.Blocks.Sources.RealExpression TSetChiWatSup[nBui](y=bui.TChiWatSup_nominal)
    "Chilled water supply temperature set point."
    annotation (Placement(transformation(extent={{-60,40},{-40,60}})));
equation
  connect(weaDat.weaBus, weaBus) annotation (Line(
      points={{-80,-74},{-60,-74},{-60,-44},{-104,-44}},
      color={255,204,51},
      thickness=0.5));
  connect(weaBus.TWetBul,cooPla. TWetBul) annotation (Line(
      points={{-104,-44},{-36,-44}},
      color={255,204,51},
      thickness=0.5));
  connect(on.y,cooPla. on) annotation (Line(points={{-79,10},{-44,10},{-44,-28},
          {-36,-28}}, color={255,0,255}));
  connect(disNet.port_bDisRet, cooPla.port_a) annotation (Line(points={{16,22.4},
          {0,22.4},{0,-31},{-14,-31}}, color={0,127,255}));
  connect(cooPla.port_b, disNet.port_aDisSup) annotation (Line(points={{-14,-41},
          {4,-41},{4,26},{16,26}},   color={0,127,255}));
  connect(disNet.port_bDisSup, disNet.port_aDisRet) annotation (Line(points={{44,
          26},{52,26},{52,22.4},{44,22.4}}, color={0,127,255}));
  connect(disNet.dp, cooPla.dpMea) annotation (Line(points={{44.7,27.8},{80,27.8},
          {80,-84},{-46,-84},{-46,-39},{-36,-39}}, color={0,0,127}));
  connect(TchiWatSet.y, cooPla.TCHWSupSet) annotation (Line(points={{-59,-30},{-46,
          -30},{-46,-33},{-36,-33}}, color={0,0,127}));
  for i in 1:nBui loop
  connect(heaSou.ports[i], bui[i].port_a1) annotation (Line(points={{-22,80},{8,
            80},{8,76},{20,76}}, color={0,127,255}));
  connect(heaSin.ports[i], bui[i].port_b1) annotation (Line(points={{62,82},{52,82},
            {52,76},{40,76}},     color={0,127,255}));
  connect(disNet.ports_bCon[i], bui[i].port_a2) annotation (Line(points={{21.6,32},
            {22,32},{22,40},{52,40},{52,64},{40,64}},
                                                color={0,127,255}));
  connect(disNet.ports_aCon[i], bui[i].port_b2) annotation (Line(points={{38.4,32},
            {38.4,40},{8,40},{8,64},{20,64}},color={0,127,255}));
  end for;
  connect(TSetChiWatSup.y, bui.TSetChiWat) annotation (Line(points={{-39,50},{0,
          50},{0,73},{19,73}}, color={0,0,127}));
  annotation (Icon(coordinateSystem(preserveAspectRatio=false)), Diagram(
        coordinateSystem(preserveAspectRatio=false)),
    experiment(
      StartTime=13392000,
      StopTime=13824000,
      Tolerance=1e-06,
      __Dymola_Algorithm="Cvode"));
end DistrictCoolingSystem;
{% endraw %}
