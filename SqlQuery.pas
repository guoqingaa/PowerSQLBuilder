{
  SQLQuery.
  ------------------------------------------------------------------------------
  Objetivo : Simplificar a execu��o de comandos SQL via codigos livre de
             componentes de terceiros.

  Suporta 2 tipos de componentes do ZeusLIB e FireDAC.
  ------------------------------------------------------------------------------
  Autor : Antonio Julio
  ------------------------------------------------------------------------------
  Esta biblioteca � software livre; voc� pode redistribu�-la e/ou modific�-la
  sob os termos da Licen�a P�blica Geral Menor do GNU conforme publicada pela
  Free Software Foundation; tanto a vers�o 3.29 da Licen�a, ou (a seu crit�rio)
  qualquer vers�o posterior.

  Esta biblioteca � distribu�da na expectativa de que seja �til, por�m, SEM
  NENHUMA GARANTIA; nem mesmo a garantia impl�cita de COMERCIABILIDADE OU
  ADEQUA��O A UMA FINALIDADE ESPEC�FICA. Consulte a Licen�a P�blica Geral Menor
  do GNU para mais detalhes. (Arquivo LICEN�A.TXT ou LICENSE.TXT)

  Voc� deve ter recebido uma c�pia da Licen�a P�blica Geral Menor do GNU junto
  com esta biblioteca; se n�o, escreva para a Free Software Foundation, Inc.,
  no endere�o 59 Temple Street, Suite 330, Boston, MA 02111-1307 USA.
  Voc� tamb�m pode obter uma copia da licen�a em:
  http://www.opensource.org/licenses/lgpl-license.php
}
unit SQLQuery;

interface
uses
  System.SysUtils, System.Classes, Data.DB, PowerSqlBuilder,
  {ZeusLib}
  ZAbstractRODataset, ZAbstractDataset, ZDataset, ZConnection, ZAbstractTable,
  {FireDac}
  FireDAC.Stan.Intf, FireDAC.Stan.Option,FireDAC.Stan.Error,
  FireDAC.UI.Intf, FireDAC.Phys.Intf, FireDAC.Stan.Def, FireDAC.Stan.Pool,
  FireDAC.Stan.Async, FireDAC.Phys, FireDAC.Stan.Param, FireDAC.DatS,
  FireDAC.DApt.Intf,FireDAC.DApt, FireDAC.Phys.PGDef, FireDAC.VCLUI.Wait,
  FireDAC.Comp.UI, FireDAC.Phys.PG, FireDAC.Comp.DataSet, FireDAC.Comp.Client,
  IdBaseComponent, IdComponent, IdRawBase, IdRawClient, IdIcmpClient;

type
  TDataSqlBuilder = class
  private
    FDataSet : TDataSet;
    procedure SetDataSet(const Value: TDataSet);
  public
    property DataSet : TDataSet read FDataSet write SetDataSet;
    function GetI( NameField : WideString ) : Integer; overload;
    function GetL( NameField : WideString ) : Int64; overload;
    function GetW( NameField : WideString ) : WideString; overload;
    function GetA( NameField : WideString ) : AnsiString; overload;
    function GetF( NameField : WideString ) : Double; overload;
    function GetC( NameField : WideString ) : Currency; overload;
    function GetB( NameField : WideString ) : Boolean; overload;
    function GetD( NameField : WideString ) : TDateTime; overload;
  end;

  TSQLQuery = class( TPowerSQLBuilder )
  private
    FData : TDataSqlBuilder;

    procedure SetData(const Value: TDataSqlBuilder);
  public
    property Data : TDataSqlBuilder read FData write SetData;

    function Execute(var Query : TZQuery ) : TSqlQuery; overload;
    function Execute(var Query : TFDQuery ) : TSqlQuery; overload;
    function Open(var query : TZQuery ) : TSqlQuery; overload;
    function Open(var query : TFDQuery ) : TSqlQuery; overload;

    constructor Create; virtual;
    destructor Destroy; override;
  end;

function Ping(const AHost : string) : Boolean;

implementation

{ TSqlQuery }

function TSqlQuery.Execute(var Query: TZQuery): TSqlQuery;
var
  Executed : Boolean;
begin
  if not Ping( Query.Connection.HostName ) then
    raise Exception.Create('Falha de conex�o com o Servidor de banco de dados : ' + Query.Connection.HostName );

  try
    repeat
      Executed := False;
      try
        Query.DisableControls;
        Query.Close;
        Query.SQL.Clear;
        Query.SQL.Add( GetString );
        Query.ExecSQL;

        Executed := True;
      except
        on e: Exception do
        begin
          if Pos( 'MySQL server has gone away' , e.Message ) > 0  then
          begin
            Query.Connection.Disconnect;
            Query.Connection.Connect;
          end
          else
          begin
            raise;
          end;
        end;
      end;
    until (Executed);
  finally
    Query.EnableControls;
    Clear;
    Result := Self;
  end;
end;

function TSqlQuery.Open(var query: TZQuery): TSqlQuery;
var
  Executed : Boolean;
begin
  if not Ping( Query.Connection.HostName ) then
    raise Exception.Create('Falha de conex�o com o Servidor de banco de dados : ' + Query.Connection.HostName );

  try
    repeat
      Executed := False;
      try
        Query.DisableControls;
        Query.Close;
        Query.SQL.Clear;
        Query.SQL.Add( GetString );
        Query.Open;

        Self.FData.DataSet := (Query as TDataSet);

        Executed := True;
      except
        on e: Exception do
        begin
          if (Pos('SERVER', UpperCase(e.Message) ) > 0) then
          begin
            Query.Connection.Disconnect;
            Query.Connection.Connect;
          end
          else
          begin
            raise;
          end;
        end;
      end;
    until (Executed);
  finally
    Query.EnableControls;
    Clear;
    Result := Self;
  end;
end;

constructor TSqlQuery.Create;
begin
  Self.FData := TDataSqlBuilder.Create;
end;

destructor TSqlQuery.Destroy;
begin
  FreeAndNil( Self.FData );
  inherited;
end;

function TSqlQuery.Execute(var Query: TFDQuery): TSqlQuery;
var
  Executed : Boolean;
begin
  if not Ping( Query.Connection.ConnectionString ) then
    raise Exception.Create('Falha de conex�o com o Servidor de banco de dados : ' + Query.Connection.ConnectionString );

  try
    repeat
      Executed := False;
      try
        Query.DisableControls;
        Query.Close;
        Query.SQL.Clear;
        Query.SQL.Add( GetString );
        Query.ExecSQL;

        Executed := True;
      except
        on e: Exception do
        begin
          if Pos( 'MySQL server has gone away' , e.Message ) > 0  then
          begin
            Query.Connection.Connected := False;
            Query.Connection.Connected := True;
          end
          else
          begin
            raise;
          end;
        end;
      end;
    until (Executed);
  finally
    Query.EnableControls;
    Clear;
    Result := Self;
  end;
end;

function TSqlQuery.Open(var query: TFDQuery): TSqlQuery;
var
  Executed : Boolean;
begin
  if not Ping( Query.Connection.ConnectionString ) then
    raise Exception.Create('Falha de conex�o com o Servidor de banco de dados : ' + Query.Connection.ConnectionString );

  try
    repeat
      Executed := False;
      try
        Query.DisableControls;
        Query.Close;
        Query.SQL.Clear;
        Query.SQL.Add( GetString );
        Query.Open;

        Self.FData.DataSet := Query.DataSource.DataSet;

        Executed := True;
      except
        on e: Exception do
        begin
          if (Pos('SERVER', UpperCase(e.Message) ) > 0) then
          begin
            Query.Connection.Connected := False;
            Query.Connection.Connected := True;
          end
          else
          begin
            raise;
          end;
        end;
      end;
    until (Executed);
  finally
    Query.EnableControls;
    Clear;
    Result := Self;
  end;
end;

procedure TSqlQuery.SetData(const Value: TDataSqlBuilder);
begin
  FData := Value;
end;

{ TSqlFiedBuilder }

function TDataSqlBuilder.GetI(NameField: WideString): Integer;
begin
  Result := Self.FDataSet.FieldByName(NameField).AsInteger;
end;

function TDataSqlBuilder.GetW(NameField: WideString): WideString;
begin
  Result := Self.FDataSet.FieldByName(NameField).AsWideString;
end;

procedure TDataSqlBuilder.SetDataSet(const Value: TDataSet);
begin
  FDataSet := Value;
end;

function TDataSqlBuilder.GetF(NameField: WideString): Double;
begin
  Result := Self.FDataSet.FieldByName(NameField).AsFloat;
end;

function TDataSqlBuilder.GetL(NameField: WideString): Int64;
begin
  Result := Self.FDataSet.FieldByName(NameField).AsLargeInt;
end;

function TDataSqlBuilder.GetB(NameField: WideString): Boolean;
begin
  Result := Self.FDataSet.FieldByName(NameField).AsBoolean;
end;

function TDataSqlBuilder.GetD(NameField: WideString): TDateTime;
begin
  Result := Self.FDataSet.FieldByName(NameField).AsDateTime;
end;

function TDataSqlBuilder.GetA(NameField: WideString): AnsiString;
begin
  Result := Self.FDataSet.FieldByName(NameField).AsAnsiString;
end;

function TDataSqlBuilder.GetC(NameField: WideString): Currency;
begin
  Result := Self.FDataSet.FieldByName(NameField).AsCurrency;
end;

function Ping(const AHost : string) : Boolean;
var
  MyIdIcmpClient : TIdIcmpClient;
begin
  try
    MyIdIcmpClient := TIdIcmpClient.Create(nil);
    MyIdIcmpClient.ReceiveTimeout := 200;
    MyIdIcmpClient.Host := AHost;

    try
      MyIdIcmpClient.Ping;
    except
      Result := False;
      MyIdIcmpClient.Free;
      Exit;
    end;

    result := not (MyIdIcmpClient.ReplyStatus.ReplyStatusType <> rsEcho)
  finally
    FreeAndNil( MyIdIcmpClient );
  end;
end;

end.
