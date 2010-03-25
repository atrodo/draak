(* **************************************************************** *)
(*     Copyright (C) 1999-2010, Jon Gentle, All right reserved.     *)
(* **************************************************************** *)
(* This program is free software; you can redistribute it under the *)
(* terms of the Artistic License, as specified in the LICENSE file. *)
(* **************************************************************** *)

unit error;

interface

type

  TError = class
    constructor create(own: TObject);
    procedure err(s: string);
    procedure status(s: string);
    procedure stream(s: string);
    procedure newNode(s: string);
    procedure addNode(s: string);
    procedure popNode(s: string);
    procedure compile(s: string);
    procedure assemble(s: string);
    procedure link(s: string);
    private
      owner: TObject;
  end;

implementation

uses Draak, classes;

constructor TError.create(own: TObject);
begin
  if own.ClassType <> TDraak then
    raise EComponentError.Create('Invalid Class type:' + own.ClassName + '.  Expected TDraak');
  owner := own;
end;

procedure TError.err(s: string);
begin
  if not assigned(owner) then exit;
  if Assigned(TDraak(owner).onError) then
    TDraak(owner).onError(self, s);
end;

procedure TError.status(s: string);
begin
  if not assigned(owner) then exit;
  if Assigned(TDraak(owner).onStatus) then
    TDraak(owner).onStatus(self, s);
end;

procedure TError.stream(s: string);
begin
  if not assigned(owner) then exit;
  if Assigned(TDraak(owner).onStream) then
    TDraak(owner).onStream(self, s);
end;

procedure TError.newNode(s: string);
begin
  if not assigned(owner) then exit;
  if Assigned(TDraak(owner).onNodeCreate) then
    TDraak(owner).onNodeCreate(self, s);
end;
procedure TError.addNode(s: string);
begin
  if not assigned(owner) then exit;
  if Assigned(TDraak(owner).onNodeChild) then
    TDraak(owner).onNodeChild(self, s);
end;
procedure TError.popNode(s: string);
begin
  if not assigned(owner) then exit;
  if Assigned(TDraak(owner).onNodePop) then
    TDraak(owner).onNodePop(self, s);
end;

procedure TError.compile(s: string);
begin
  if not assigned(owner) then exit;
  if Assigned(TDraak(owner).onCompile) then
    TDraak(owner).onCompile(self, s);
end;

procedure TError.assemble(s: string);
begin
  if not assigned(owner) then exit;
  if Assigned(TDraak(owner).onAssemble) then
    TDraak(owner).onAssemble(self, s);
end;

procedure TError.link(s: string);
begin
  if not assigned(owner) then exit;
  if Assigned(TDraak(owner).onLink) then
    TDraak(owner).onLink(self, s);
end;

end.
