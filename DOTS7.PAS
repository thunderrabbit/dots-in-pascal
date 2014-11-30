
Program Dots7;  (* started Feb 22, 1990 *)

uses graph,crt;
Const   DOTCOLOR    : byte = White;
	LINECOLOR   : byte = Cyan;
	MARKERCOLOR : byte = Yellow;
	MAXDOTS     : byte = 31;
	COLORSET    : Array[0..15] of String[13] =
	   ('Black','Blue','Green','Cyan','Red','Magenta','Brown',
	    'Light Gray','Dark Gray','Light Blue','Light Green',
	    'Light Cyan','Light Red','Light Magenta','Yellow','White');
	XMIN        : integer = 20;
	XMAX        : integer = 400;
	YMIN        : integer = 30;
	YMAX        : integer = 300;

Type  ByteSet     = Set of Byte;

      ArrayOfDots = array[1..31,1..31] of PointType;

      ArrayOfBoxes  = array[0..32,0..32] of record
        Line        : array[1..4] of Boolean;
	Sides       : Byte;
        Filled      : Boolean;
        Color       : Byte;
	    end;

      MarkerType   = record
        Color      : byte;
	Corner     : array[1..4] of PointType;
	BL         : PointType;  (* BL stands for Bottom-Left corner *)
	    end;

      PlayerType  = record
        Color     : byte;
	Name      : string[15];
	Score     : Integer;
	Space     : Byte;
        TextScore : string[3];
	  end;

      TextType    = Record
        Num       : Byte;
        Size      : Byte;
        Space     : Byte;
         end;

Var  DotArray                        : ArrayOfDots;
     BoxArray                        : ArrayOfBoxes;
     Marker,OldMarker                : MarkerType;
     Player1,Player2,CurrentPlayer   : PlayerType;
     Text1,Text2,CurrentText         : TextType;
     Space                           : PointType;
     DotsWidth,DotsHeight,BoxesWidth,
     NumOfBoxes,TotalBoxes,BoxesHeight,
     CoordX,Count,CoordY             : integer;
     GoOk,GridFilled,PlayingMainGame,
     Squashed,HelpNeeded             : Boolean;
     JunkChar                        : Char;
     NumJunk,SquashDir,MaxColor      : Byte;

(******************************************************************************)

Procedure Buzz;
Begin (*Buzz*)
Sound(250);Delay(20);NoSound;End;(*Buzz*)

(******************************************************************************)

Function NextKey:Byte;
Var Junk : Byte;

Begin (*NextKey*)
If KeyPressed
Then begin
  Junk:=ord(Readkey);
  If Junk=0 then Junk:=ord(Readkey);end
Else Junk:=0;
NextKey := Junk;
End; (*NextKey*)

(******************************************************************************)

Procedure StartGraph;
var
  GraphDriver : Integer;
  GraphMode   : Integer;
  ErrCode  : Integer;
  PathToDrivers : String;

Begin (*StartGraph*)
(*  grDriver := Detect;
  InitGraph(grDriver,grMode,'Turbo');
  ErrCode := GraphResult;
  if ErrCode <> grOk then
   WriteLn('Graphics error:',GraphErrorMsg(ErrCode));*)

  GraphDriver := Detect;
  DetectGraph(GraphDriver, GraphMode);

  case GraphDriver of
    CGA        : begin
		   MaxColor := 6;
                   GraphDriver := CGA;
                   GraphMode := CGAC1;
                 end;

    MCGA       : begin
		   MaxColor := 6;
                   case GraphMode of
                     MCGAMed, MCGAHi: GraphMode := MCGAC1;
                   end;
                 end;

    EGA,VGA     : begin
		    MaxColor := 15;
		    GraphMode := EGAHi;
                  end;


    end; (*case*)

  InitGraph(GraphDriver, GraphMode, '');
  ErrCode := GraphResult;
  if ErrCode <> grOk then
  WriteLn('Graphics error:',GraphErrorMsg(ErrCode));

End; (*StartGraph*)

(******************************************************************************)

Procedure ClearBuffer;

Var Junk:Char;
Begin (*ClearBuffer*)
While KeyPressed Do
 begin
  Delay(50);
  Junk:=Readkey;
 end;
End; (*ClearBuffer*)

(******************************************************************************)

Function NumToString(Num : Integer):String;
var Strng : String[4];
Begin (*NumToString*)
  If Num<0 then NumToString:=''
  Else begin
   Str(Num,Strng);
   NumToString:=Strng;end;
End; (*NumToString*)

(******************************************************************************)

Procedure FillBox(X1,Y1,X2,Y2,Color:integer);
 var Corner,OldColor:integer;
     Box : Array[1..4] of PointType;

 Begin (*FillBox*)
  OldColor:=GetColor;
  SetColor(Color);
  Box[1].X:=X1;
  Box[1].Y:=Y1;
  Box[2].X:=X1;
  Box[2].Y:=Y2;
  Box[3].X:=X2;
  Box[3].Y:=Y2;
  Box[4].X:=X2;
  Box[4].Y:=Y1;
  SetFillStyle(1,Color);
  FillPoly(4,Box);
  SetColor(OldColor);
 End; (*FillBox*)

(******************************************************************************)

Procedure WriteMessage(S1,S2,S3:String;Color:Byte);
Var Junk,X,OldColor:Integer;

Begin (*WriteMessage*)
 If PlayingMainGame then  (*If started main game*)
   X:=440 Else X:=100;
 OldColor:=GetColor;
 Buzz;
 SetColor(Color);
 OutTextXY(X,245+CurrentText.Space*0,S1);
 OutTextXY(X,245+CurrentText.Space*1,S2);
 OutTextXY(X,245+CurrentText.Space*2,S3);
  If TextWidth(S1)<TextWidth(S2) then S1:=S2;
  If TextWidth(S1)<TextWidth(S3) then S1:=S3;
 Repeat Until Keypressed;
 FillBox(X,245,X+TextWidth(S1),245+CurrentText.Space*3+3,Black);
 SetColor(OldColor);
End; (*WriteMessage*)

(******************************************************************************)

Procedure AskIfQuit;
Var Junk : Char;

Begin (*AskIfQuit*)
WriteMessage('Do you want to Quit?','Y/N','',LightRed);
Junk:=Readkey;
If Upcase(Junk)='Y'
Then begin
      CloseGraph;
      halt;
     end;
End; (*AskIfQuit*)

(******************************************************************************)

Function GetBufferedInput(InputSet:ByteSet):Byte;
var Bite : Byte;
Begin (*GetBufferedInput*)
 Repeat                  (* GetBufferedInput returns a value  *)
  Bite:=NextKey;         (* within the set sent into InputSet *)
 Until Bite in InputSet;
GetBufferedInput:=Bite;
End; (*GetBufferedInput*)

(******************************************************************************)

Function GetNum(XCoord,YCoord,MinNum,MaxNum:integer):Integer;
Var Number,Num  : Integer;

Begin (*GetNum*)
Number:=0;
Repeat
 Num := GetBufferedInput([8,13,48..57]);
 If   Num in[48..57]
 Then begin
  Num:=Num-48;   (*  Num is a digit  0-9 *)
  Number:=Number*10+Num;
  end
 Else
  If   Num=8 then begin
   If   Number>=10
   Then Number:=Trunc(Number/10)
   Else Number:=-1; (* NumToString will return '' *)
   FillBox(XCoord,YCoord,XCoord+50,YCoord+TextHeight('0')+4,Black);end;
                       (* ^ erases number after backspaced ^ *)
  If   Number>MaxNum
  Then begin
   OutTextXY(XCoord,YCoord,NumToString(Number)); (*write num that's too big*)
   Number:=-1;                               (* NumToString will return '' *)
   WriteMessage('The number must be','between '+NumToString(MinNum)+
                ' and '+NumToString(MaxNum),'',LightRed);(*tells user range*)
   ClearBuffer;        (* clears key pressed to get back from WriteMessage *)
   FillBox(XCoord,YCoord,XCoord+50,YCoord+TextHeight('0')+4,Black);end;
                       (* ^ erases number after it was too big ^ *)
 OutTextXY(XCoord,YCoord,NumToString(Number));         (* write new number *)
  If   Number=-1           (* Number would =-1 when Backspaced & Number<10 *)
  Then Number:=0;          (*         OR  if number>30                     *)

Until Num=13;

GetNum:=Number;
End; (*GetNum*)

(******************************************************************************)

Function GetName(X,Y,Color:integer):String;
Var Name    : String[15];
  I,Num,
  OldColor  : Byte;

Begin (*GetName*)
 I:=0;
 OldColor:=GetColor;
 SetColor(Color);
Repeat   (* Get Input *)

 Repeat (* Check Input *)
  Num := NextKey;
 Until Num in[8,13,27,32,65..90,97..122];

		(* Numbers represent : Backspace,Enter,Escape,
                                       Space,A..Z,a..z    *)

 If Not(Num in[8,13,27]) then begin
   I:=I+1;
   Name[0]:=chr(I);
   Name[I] := Chr(Num);end;

 If Num=8 (* Backspace *) then begin
   If I>0 then I:=I-1;
   Name[0]:=chr(I);
   FillBox(X,Y,X+TextWidth(Name+'WW'),Y+CurrentText.Space,Black);end;

 If Num=27 (* Escape *) then AskIfQuit;

 OutTextXY(X,Y,Name);
 If I=15 then Num:=13;

Until Num=13;

GetName:=Name;
SetColor(OldColor);
End; (*GetName*)

(******************************************************************************)

Procedure SetText(Text:TextType);
Begin (*SetText*)
SetTextStyle(Text.Num,HorizDir,Text.Size);
End; (*SetText*)

(******************************************************************************)

Procedure GetSize(var BoxesWidth:integer;var BoxesHeight:integer);
Var OldText : TextType;

Begin (*GetSize*)

OldText:=CurrentText;
CurrentText:=Text2;
SetText(CurrentText);
OutTextXY(100,20+CurrentText.Space*6,'How big do you want the array of dots? ''0'' to quit.');

 OutTextXY(100,20+CurrentText.Space*7,'Width   :');
 BoxesWidth:=GetNum(100+TextWidth('Width   :'),20+CurrentText.Space*7,0,30);
If BoxesWidth = 0 then GoOk:=false;

If GoOk then begin
 OutTextXY(100,20+CurrentText.Space*8,'Height  :');
 BoxesHeight:=GetNum(100+TextWidth('Height  :'),20+CurrentText.Space*8,0,30);end;
if BoxesHeight = 0 then GoOk:=false;
OutTextXY(100,CurrentText.Space*10,'Thinking...');
DotsWidth :=BoxesWidth +1;
DotsHeight:=BoxesHeight+1;
CurrentText:=OldText;
SetText(CurrentText);

End; (*GetSize*)

(******************************************************************************)

Procedure DrawArrows;
var OldColor : Byte;
    OldText  : TextType;
Begin (*DrawArrows*)

OldColor:=GetColor;
OldText:=CurrentText;
CurrentText:=Text1;         (* Turbo can only draw *)
SetText(CurrentText);  (* special characters in Text1. (Default)  *)

            (* The next 5 lines erase arrows at both locations even though
                 there are only arrows at one of the locations.  The lines
                 after those draw the arrows in the correct location. *)
 SetColor(Black);
  OutTextXY(430,64+Player1.Space,chr(219)+chr(219));
  OutTextXY(430,64+Player1.Space+CurrentText.Space,Chr(219)+Chr(219));
  OutTextXY(430,64+Player2.Space,chr(219)+chr(219));
  OutTextXY(430,64+Player2.Space+CurrentText.Space,Chr(219)+Chr(219));

 SetColor(CurrentPlayer.Color);
  OutTextXY(430,64+CurrentPlayer.Space,chr(218)+chr(16));
  OutTextXY(430,64+CurrentPlayer.Space+CurrentText.Space,Chr(192)+chr(16));
SetColor(OldColor);
CurrentText:=OldText;
SetText(CurrentText);
End; (*DrawArrows*)

(******************************************************************************)

Procedure SwitchPlayers;

Begin (*SwitchPlayers*);
 If CurrentPlayer.Color=Player1.Color then begin
    Player1:=CurrentPlayer;
    CurrentPlayer:=Player2;
    end
 else begin
    Player2:=CurrentPlayer;
    CurrentPlayer:=Player1;end;
If PlayingMainGame then DrawArrows;  (* if started main game *);

End; (*SwitchPlayers*)

(******************************************************************************)

Procedure DesignBoard(DotsWidth,DotsHeight:word;
                      Var DotArray:ArrayOfDots;Var Space:PointType;
                      Xmax,Ymax,Xmin,Ymin:Integer);

Var CountX,CountY : word;
    Start : PointType;

Begin (*DesignBoard*)
If DotsHeight>DotsWidth then begin
 Space.X:=Round((Xmax-Xmin)/DotsHeight);
 Space.Y:=Round((Ymax-Ymin)/DotsHeight);end
Else begin  (* Width is > or = Height so same result either case *)
 Space.X:=Round((Xmax-Xmin)/(DotsWidth-1));
 Space.Y:=Round((Ymax-Ymin)/(DotsWidth-1));end;

Start.X:=Round(Xmin+(Xmax-Xmin-Space.X*(DotsWidth+1))/2);
Start.Y:=Round(Ymax-(Ymax-Ymin-Space.Y*(DotsHeight+1))/2);
For CountY:=1 to DotsHeight do
For CountX:=1 to DotsWidth  do begin
DotArray[CountX,CountY].X:=Round(Start.X+CountX*Space.X);
DotArray[CountX,CountY].Y:=Round(Start.Y-CountY*Space.Y);end;
End; (*DesignBoard*)

(******************************************************************************)

Procedure DrawDots(DotArray:ArrayOfDots;DotsWidth,DotsHeight:Word);

  Var X,Y:byte;

Begin (*DrawDots*)
 For Y := 1 to DotsHeight do
 For X := 1 to DotsWidth  do
  PutPixel(DotArray[X,Y].X,DotArray[X,Y].Y,DOTCOLOR);
End; (*DrawDots*)

(******************************************************************************)

Procedure SetMarkerCorners(BLX,BLY,XWidth,YWidth:integer);

(*  BLX and BLY are how far off the dot the Marker.BL is
    This is used when the marker is Squashed
    The X & YWidth are normally = Space.X & Y, respectfully,
    unless the marker is Squashed.                            *)


Begin (*SetMarkerCorners*)
 Marker.Corner[1].X:=
  Round(DotArray[Round(Marker.BL.X),Round(Marker.BL.Y)].X)+BLX;
 Marker.Corner[1].Y:=
  Round(DotArray[Round(Marker.BL.X),Round(Marker.BL.Y)].Y)+BLY;

 Marker.Corner[2].X:=Marker.Corner[1].X;
 Marker.Corner[2].Y:=Marker.Corner[1].Y-YWidth;
 Marker.Corner[3].X:=Marker.Corner[1].X+XWidth;
 Marker.Corner[3].Y:=Marker.Corner[1].Y-YWidth;
 Marker.Corner[4].X:=Marker.Corner[1].X+XWidth;
 Marker.Corner[4].Y:=Marker.Corner[1].Y;

End;  (*SetMarkerCorners*)

(******************************************************************************)

Procedure SetOldMarkerCorners;
Begin (*SetOldMarkerCorners*)
 OldMarker.Corner:=Marker.Corner;
 OldMarker.BL:=Marker.BL;
End; (*SetOldMarkerCorners*)

(******************************************************************************)

Procedure DrawMarker(Marker:MarkerType);
var OldColor : Byte;

Begin (*DrawMarker*)
OldColor:=GetColor;
SetColor(Marker.Color);
Line(Round(Marker.Corner[1].X+1),Round(Marker.Corner[1].Y-1),
     Round(Marker.Corner[3].X-1),Round(Marker.Corner[3].Y+1));
Line(Round(Marker.Corner[2].X+1),Round(Marker.Corner[2].Y+1),
     Round(Marker.Corner[4].X-1),Round(Marker.Corner[4].Y-1));
SetColor(OldColor);
End; (*DrawMarker*)

(******************************************************************************)

Procedure MoveMarker(BoxesWidth,BoxesHeight,Direction:Byte);
Var Moved : Boolean;

Begin (*MoveMarker*)

Moved:=False;

     (* section does appropriate action according to Direction *)

Case Direction of
   (*up*) 72 : Inc(Marker.BL.Y);
 (*down*) 80 : Dec(Marker.BL.Y);
(*Right*) 77 : Inc(Marker.BL.X);
 (*Left*) 75 : Dec(Marker.BL.X);
 (*UpRt*) 73 : begin Inc(Marker.BL.Y);
		     Inc(Marker.BL.X);end;
 (*DnRt*) 81 : begin Dec(Marker.BL.Y);
		     Inc(Marker.BL.X);end;
(*DnLft*) 79 : begin Dec(Marker.BL.Y);
		     Dec(Marker.BL.X);end;
(*UpLft*) 71 : begin Inc(Marker.BL.Y);
		     Dec(Marker.BL.X);end;
 end;  (*Case*)

If Direction in[72,80,77,75] then begin (* Not Diagonal *)

If Marker.BL.X<1           then begin Squashed:=True;SquashDir:=4;
			       Inc(Marker.BL.X);end;
If Marker.BL.Y<1           then begin Squashed:=True;SquashDir:=2;
			       Inc(Marker.BL.Y);end;
If Marker.BL.X>BoxesWidth  then begin Squashed:=True;SquashDir:=6;
			       Dec(Marker.BL.X);end;
If Marker.BL.Y>BoxesHeight then begin Squashed:=True;SquashDir:=8;
			       Dec(Marker.BL.Y);end;
end; (* Not Diagonal *)

If Direction in[71,73,79,81] (* Diagonal *) then

   Case Direction of

   71 : begin If Not((Marker.BL.X<1) and (Marker.BL.Y>BoxesHeight))
              Then Squashed:=False;

	      If (Marker.BL.X<1) xor (Marker.BL.Y>BoxesHeight)
              Then begin
                If Marker.BL.X<1
		Then begin Squashed:=True;
			   SquashDir:=4;Inc(Marker.BL.X);end
		Else begin Squashed:=True;
                           SquashDir:=8;Dec(Marker.BL.Y);end;end;

              If (Marker.BL.X<1) and (Marker.BL.Y>BoxesHeight)
	      Then begin
	       Squashed:=True;SquashDir:=7;
	       Inc(Marker.BL.X);Dec(Marker.BL.Y);end;end; (* case 71 *)


   73 : begin If Not((Marker.BL.X>BoxesWidth) and (Marker.BL.Y>BoxesHeight))
              Then Squashed:=False;

	      If (Marker.BL.X>BoxesWidth) xor (Marker.BL.Y>BoxesHeight)
              Then begin
                If Marker.BL.X>BoxesWidth
		Then begin Squashed:=True;
			   SquashDir:=6;Dec(Marker.BL.X);end
		Else begin Squashed:=True;
                           SquashDir:=8;Dec(Marker.BL.Y);end;end;

              If (Marker.BL.X>BoxesWidth) and (Marker.BL.Y>BoxesHeight)
	      Then begin
	       Squashed:=True;SquashDir:=9;
	       Dec(Marker.BL.X);Dec(Marker.BL.Y);end;end; (* case 73 *)


   79 : begin If Not((Marker.BL.X<1) and (Marker.BL.Y<1))
              Then Squashed:=False;

	      If (Marker.BL.X<1) xor (Marker.BL.Y<1)
              Then begin
                If Marker.BL.X<1
		Then begin Squashed:=True;
			   SquashDir:=4;Inc(Marker.BL.X);end
		Else begin Squashed:=True;
                           SquashDir:=2;Inc(Marker.BL.Y);end;end;

              If (Marker.BL.X<1) and (Marker.BL.Y<1)
	      Then begin
	       Squashed:=True;SquashDir:=1;
	       Inc(Marker.BL.X);Inc(Marker.BL.Y);end;end; (* case 79 *)


   81 : begin If Not((Marker.BL.X>BoxesWidth) and (Marker.BL.Y<1))
              Then Squashed:=False;

	      If (Marker.BL.X>BoxesWidth) xor (Marker.BL.Y<1)
              Then begin
                If Marker.BL.X>BoxesWidth
		Then begin Squashed:=True;
			   SquashDir:=6;Dec(Marker.BL.X);end
		Else begin Squashed:=True;
                           SquashDir:=2;Inc(Marker.BL.Y);end;end;

              If (Marker.BL.X>BoxesWidth) and (Marker.BL.Y<1)
	      Then begin
	       Squashed:=True;SquashDir:=3;
	       Dec(Marker.BL.X);Inc(Marker.BL.Y);end;end; (* case 81 *)

   end  (* Case  *)

End;  (*MoveMarker*)

(******************************************************************************)

Procedure DrawLine(X1,Y1,X2,Y2,Color:Integer);
Var OldColor: Byte;

Begin (*DrawLine*)
 OldColor:=GetColor;
 SetColor(Color);
 Line(DotArray[X1,Y1].X,DotArray[X1,Y1].Y,
      DotArray[X2,Y2].X,DotArray[X2,Y2].Y);
 SetColor(OldColor);
End; (*DrawLine*)

(******************************************************************************)

Procedure UpdateScore(Player:PlayerType);
var OldColor  : Byte;
    OldText   : TextType;

Begin (*UpdateScore*)
OldColor:=GetColor;
OldText:=CurrentText;
CurrentText:=Text2;
SetText(CurrentText);
If Player.Color=Player1.Color
 Then Player1.Score:=Player.Score
 Else Player2.Score:=Player.Score;
SetColor(Player.Color);
OutTextXY(450,60+Player.Space,Player.Name);
Player.TextScore:=NumToString(Player.Score);
FillBox(450,68+Player.Space+(CurrentText.Space*2),
	500,66+Player.Space+CurrentText.Space,Black);(* Erases Score *)
OutTextXY(450,63+Player.Space+CurrentText.Space,Player.TextScore);
SetColor(OldColor);
CurrentText:=OldText;
SetText(CurrentText);
End; (*UpdateScore*)

(******************************************************************************)

Procedure CheckForBox(Var OneFilled:boolean);
Var X,Y : shortint;

(*****************************)
procedure checkandfill(X,Y:byte);
begin (*checkandfill*)
 If (BoxArray[X,Y].Sides=4) and
    (BoxArray[X,Y].Filled=false) then begin
    OneFilled := true;  (* at least one filled *)
    BoxArray[X,Y].Filled:=true;
    BoxArray[X,Y].Color:=CurrentPlayer.Color;
    FillBox(Round(DotArray[X,Y]    .X+1),Round(DotArray[X,Y]    .Y-1),
            Round(DotArray[X+1,Y+1].X-1),Round(DotArray[X+1,Y+1].Y+1),
            CurrentPlayer.Color);
    TotalBoxes:=TotalBoxes+1;
    If TotalBoxes=NumOfBoxes then GridFilled:=True;
    CurrentPlayer.Score:=CurrentPlayer.Score+1;
    If PlayingMainGame then UpdateScore(CurrentPlayer);
    end;
end; (*checkandfill*)
(*****************************)
Begin (*CheckForBox*)
 OneFilled:=false;
 For X:=-1 to 1 do
 For Y:=-1 to 1 do
 Checkandfill(Round(Marker.BL.X)+X,Round(Marker.BL.Y)+Y);
End; (*CheckForBox*)

(******************************************************************************)

Procedure SeeIfAddSideOK(Side:Byte);

Var OneFilled,AddOk : Boolean;

(*****************************)
procedure addside(X,Y,Side:byte);

Begin (*addside*)
 BoxArray[X,Y].Line[Side]:=True;
 BoxArray[X,Y].Sides:=BoxArray[X,Y].Sides+1;
End; (*addside*)
(*****************************)

Begin (*SeeIfAddSideOK*)
AddOk:=False;

  Case Side of
  (*ESC*) 27 : begin (* do nothing *) end;

   (*up*) 72 : If BoxArray[Round(Marker.BL.X),Round(Marker.BL.Y)].Line[2]=false
     then begin Addside(Round(Marker.BL.X),Round(Marker.BL.Y),2);
		Addside(Round(Marker.BL.X),Round(Marker.BL.Y+1),4);
		DrawLine(Marker.BL.X,Marker.BL.Y+1,
			 Marker.BL.X+1,Marker.BL.Y+1,LINECOLOR);
		AddOk:=True;end;
 (*down*) 80 : If BoxArray[Round(Marker.BL.X),Round(Marker.BL.Y)].Line[4]=false
     then begin Addside(Round(Marker.BL.X),Round(Marker.BL.Y),4);
                Addside(Round(Marker.BL.X),Round(Marker.BL.Y-1),2);
                DrawLine(Marker.BL.X,Marker.BL.Y,
                         Marker.BL.X+1,Marker.BL.Y,LINECOLOR);
		AddOk:=True;end;
(*Right*) 77 : If BoxArray[Round(Marker.BL.X),Round(Marker.BL.Y)].Line[3]=false
     then begin Addside(Round(Marker.BL.X),Round(Marker.BL.Y),3);
                Addside(Round(Marker.BL.X+1),Round(Marker.BL.Y),1);
                DrawLine(Marker.BL.X+1,Marker.BL.Y+1,
                         Marker.BL.X+1,Marker.BL.Y,LINECOLOR);
		AddOk:=True;end;
 (*Left*) 75 : If BoxArray[Round(Marker.BL.X),Round(Marker.BL.Y)].Line[1]=false
     then begin Addside(Round(Marker.BL.X),Round(Marker.BL.Y),1);
                Addside(Round(Marker.BL.X-1),Round(Marker.BL.Y),3);
                DrawLine(Marker.BL.X,Marker.BL.Y+1,
                         Marker.BL.X,Marker.BL.Y,LINECOLOR);
		AddOk:=True;end;
 end;  (*Case*)

If AddOk then begin
 CheckForBox(OneFilled);
 If Not(OneFilled) then SwitchPlayers;end
Else (* Add not Ok *) Buzz;

End;  (*SeeIfAddSideOK*)

(******************************************************************************)

Procedure GetLineSide;
Var Junk  : Byte;

Begin (*GetLineSide*)
Repeat
 Junk:=NextKey;
Until Junk<>0;
 If Junk in[27,72,75,77,80] then
 SeeIfAddSideOK(Junk);
End; (*GetLineSide*)

(******************************************************************************)

Procedure SetOldMarkerColor;

Begin (*SetOldMarkerColor*)
OldMarker.Color:=BoxArray[Round(OldMarker.BL.X),Round(OldMarker.BL.Y)].Color;
End; (*SetOldMarkerColor*)

(******************************************************************************)

Procedure DisplayWinner;
var  OldText  : TextType;
     OldColor : Byte;
     Winner   : PlayerType;

Begin (*DisplyWinner*)
OldText:=CurrentText;
OldColor:=GetColor;
CurrentText:=Text2;
SetText(CurrentText);
 If Player1.Score<>Player2.Score then begin
  If Player1.Score>Player2.Score
  then Winner:=Player1
  else Winner:=Player2;
  SetColor(Winner.Color);
  OutTextXY(450,200,Winner.Name);
  OutTextXY(450,200+CurrentText.Space,'WINS ! !');end
 Else (*Tie*) begin
  SetColor(MARKERCOLOR);
  OutTextXY(450,200,'Wow!! A Tie');end;
CurrentText:=OldText;
SetText(CurrentText);
SetColor(OldColor);
End; (*DisplayWinner*)

(*****************************************************************************)

Procedure DrawColorArrows(Color:Byte);
Var OldText:TextType;OldColor:Byte;

Begin (*DrawColorArrows*)
OldText:=CurrentText;
OldColor:=GetColor;

CurrentText:=Text1;         (* Turbo can only draw *)
SetText(CurrentText);  (* special characters in Text1. (Default)  *)

 SetColor(Black);     (* erases arrow by drawing a long black box covering *)
  FillBox(52,20,59,310,Black); (* the entire area where the arrow could be *)

 SetColor(White);
  OutTextXY(52,Color*20+3,Chr(27));
 CurrentText:=OldText;
 SetText(CurrentText);
 SetColor(OldColor);
End; (*DrawColorArrows*)

(******************************************************************************)

Procedure GetPlayerColor(Var Player:PlayerType;CoordX,CoordY:Integer);
Var Color,Junk  : Byte;
    Cont        : Boolean;

Begin (*GetPlayerColor*)

Cont:=False;
Color:=1;
Player.Color:=Color;
FillBox(CoordX,CoordY,CoordX+TextWidth('Light Magenta'),
	CoordY+CurrentText.Space+5,Black); (* Erases old name of color *)
Repeat
 DrawColorArrows(Player.Color);
 OutTextXY(CoordX,CoordY,COLORSET[Color]);

  (* Numbers below represent Enter,Escape,UpArrow,DownArrow *)
 Repeat
  Junk := NextKey;
 Until Junk<>0;
 If Junk in[13,27,72,80]
  Then begin (*Junk in[13,27,72,80]*)
  Case Junk of
   72 : Color:=Color-1;
   80 : Color:=Color+1;
   13 : Cont :=True;
   27 : AskIfQuit;
   end;
 If Color>MaxColor then Color:=1;
 If Color<1  then Color:=MaxColor;
 FillBox(CoordX,CoordY,CoordX+TextWidth(COLORSET[Player.Color]),
	 CoordY+CurrentText.Space+5,Black); (* Erases old name of color *)
 Player.Color:=Color;end (* Junk in[13,27,72,80] *)
  Else begin
    WriteMessage('Use up & down arrow keys to scroll through colors',
                 'Press Enter to choose color; Escape to quit.',
                 '. .press a key. .',LightRed);
    ClearBuffer; end; (* Else *)
Until Cont;
OutTextXY(CoordX,CoordY,COLORSET[Player.Color]);(* Rewrite color after erased*)


End; (*GetPlayerColor*)

(******************************************************************************)

Procedure GetPlayers;
Var J,OldColor : Byte;
    Auto       : Boolean;
    OldText    : TextType;

Begin (*GetPlayers*)
Auto:=False; (* Auto:=False Means user determines info on players *)
 OldColor:=GetColor;
 OldText:=CurrentText;
 CurrentText:=Text2;
 SetText(CurrentText);   (* Sets Text To Triplex Font *)
 SetColor(LightGray);
If Not(Auto) then begin (* User Makes Players *)

 For J:=1 to MaxColor do
  FillBox(10,J*20,50,10+J*20,J); (* Draws Sample Colors *)

 OutTextXY(100,20,'Player one color : ');
 GetPlayerColor(Player1,100+TextWidth('Player one color : '),20);
 OutTextXY(100,20+CurrentText.Space,'Player one type in your name.');
 Player1.Name:=GetName(100,20+CurrentText.Space*2,Player1.Color);
 OutTextXY(100,20+CurrentText.Space*3,'Player two color : ');

 Repeat;
  GoOk:=true;
  GetPlayerColor(Player2,100+TextWidth('Player two color : '),
		 20+CurrentText.Space*3);
  If Player2.Color=Player1.Color then begin
    WriteMessage('Be original. ',Player1.Name+' already got '+
	          COLORSET[Player1.Color]+'.','',LightRed);
    ClearBuffer;
    GoOk:=false;end;
 Until GoOk;

 OutTextXY(100,20+CurrentText.Space*4,'Player two type in your name.');
 Player2.Name:=GetName(100,20+CurrentText.Space*5,Player2.Color);
end;  (* User Makes Players *)

If Auto Then begin (* Computer Makes Players *)
 Player1.Color:=LightRed;
 Player1.Name:='One';
 Player2.Color:=LightBlue;
 Player2.Name:='Two';
end; (* Computer Makes Players *)

 CurrentText:=OldText;
 SetColor(OldColor);
 SetText(CurrentText);

End; (*GetPlayers*)

(******************************************************************************)

Procedure InitGame;
Var  Count1,Count2,Count3 : Byte;

Begin (*InitGame*)
  GoOk:=True;
  GridFilled:=False;
  Squashed:=False;
  HelpNeeded:=False;
  Text1.Num:=0; (*Default*)
  Text1.Size:=1;
  SetText(Text1);
  Text1.Space:=Round(TextHeight('Anything')*5/4);
  Text2.Num:=1; (*Triplex*)
  Text2.Size:=1;
  SetText(Text2);
  Text2.Space:=25;
  CurrentText:=Text2;
  GetPlayers;
  GetSize(BoxesWidth,BoxesHeight);
  If not GoOk
  Then begin
        CloseGraph;
        halt;
       end;
  DesignBoard(DotsWidth,DotsHeight,DotArray,Space,
              XMAX,YMAX,XMIN,YMIN);
  NumOfBoxes:=BoxesWidth*BoxesHeight;
  TotalBoxes:=0;
  For Count1:=0 to BoxesWidth do
  For Count2:=0 to BoxesHeight do begin
  For Count3:=1 to 4 do
  BoxArray[Count1,Count2].Line[Count3]:=False;
  BoxArray[Count1,Count2].Filled:=False;
  BoxArray[Count1,Count2].Sides:=0;
  BoxArray[Count1,Count2].Color:=Black;end;
  For Count1:=1 to 4 do begin
  Marker.Corner[Count1].X:=0;
  Marker.Corner[Count1].Y:=0;end;
  Marker.Color:=MARKERCOLOR;
  Marker.BL.X:=1;
  Marker.BL.Y:=1;
  OldMarker:=Marker;
  Player1.Score:=0;
  Player1.Space:=10;
  Player2.Score:=0;
  Player2.Space:=60;
  CurrentPlayer:=Player1;
  ClearDevice;
  DrawDots(DotArray,DotsWidth,DotsHeight);
  UpdateScore(Player1);UpdateScore(Player2);
  DrawArrows;

End; (*InitGame*)

(******************************************************************************)

Procedure DrawSquashedMarker(Step,Count:Byte);
Var ShiftBLY,ShiftBLX,SpaceX,SpaceY : integer;

Begin (*DrawSquashedMarker*)

  (* The following adjusts the location of the reference corner of the marker
    (Marker.BL.X & Y) by changing ShiftBLX & BLY  and adjusts how wide or
    tall the marker is by changing SpaceX & SpaceY according to what side
    of the grid the marker is being Squashed on.
         Thanks to my dad for helping me on this part. . .      *)


 Case SquashDir of
(*up*) 8 : begin ShiftBLY:=Round(-Space.Y*(Step-Count)/Step);ShiftBLX:=0;
	  SpaceX:=Space.X;SpaceY:=Round(Space.Y*Count/Step);end;
(*dn*) 2 : begin ShiftBLY:=0;ShiftBLX:=0;
          SpaceX:=Space.X;SpaceY:=Round(Space.Y*Count/Step);end;
(*lf*) 4 : begin ShiftBLY:=0;ShiftBLX:=0;
          SpaceX:=Round(Space.X*Count/Step);SpaceY:=Space.Y;end;
(*rt*) 6 : begin ShiftBLY:=0;ShiftBLX:=Round(Space.X*(Step-Count)/Step);
          SpaceX:=Round(Space.X*Count/Step);SpaceY:=Space.Y;end;
(*ul*) 7 : begin ShiftBLY:=Round(-Space.Y*(Step-Count)/Step);ShiftBLX:=0;
          SpaceX:=Round(Space.X*Count/Step);
          SpaceY:=Round(Space.Y*Count/Step);end;
(*ur*) 9 : begin ShiftBLY:=Round(-Space.Y*(Step-Count)/Step);
	  ShiftBLX:=Round(Space.X*(Step-Count)/Step);
          SpaceX:=Round(Space.X*Count/Step);
          SpaceY:=Round(Space.Y*Count/Step);end;
(*dl*) 1 : begin ShiftBLY:=0;ShiftBLX:=0;
	  SpaceX:=Round(Space.X*Count/Step);
          SpaceY:=Round(Space.Y*Count/Step);end;
(*dr*) 3 : begin ShiftBLY:=0;ShiftBLX:=Round(Space.X*(Step-Count)/Step);
          SpaceX:=Round(Space.X*Count/Step);
          SpaceY:=Round(Space.Y*Count/Step);end;

 end; (*case*)

 SetMarkerCorners(ShiftBLX,ShiftBLY,SpaceX,SpaceY);
 SetOldMarkerColor;
 DrawMarker(OldMarker);
 DrawMarker(Marker);
 SetOldMarkerCorners;

End; (*DrawSquashedMarker*)

(******************************************************************************)

Procedure Grunt(Count:Byte);
Var Num:Integer;
Begin (*Grunt*)
Num:=(Count*Count*Count+20);
Sound(Num);Delay(20);NoSound;End;(*Grunt*)

(******************************************************************************)

Procedure UnSquashIt;

Var Step,Count : byte;

Begin (*UnSquashIt*)

Step:=5;
For Count:=Step DownTo 1 do begin DrawSquashedMarker(Step,Count);
Grunt(Count);end;

 ClearBuffer;

For Count:=1 To Step do begin
 DrawSquashedMarker(Step,Count);
 Grunt(Count); end;

Squashed:=False;
End; (*UnSquashIt*)

(******************************************************************************)

Procedure AskIfSwitchPlayers;

Begin (*AskIfSwitchPlayers*)

WriteMessage('Press ''Y'' to','switch players. .','',LightRed);
If UpCase(Chr(NextKey))='Y' then SwitchPlayers;

End; (*AskIfSwitchPlayers*)

(******************************************************************************)

Procedure Help;
       (* This section creates and writes the help screen *)

  Const X1 : integer = 124;
	Y1 : integer = 60;
	X2 : integer = 526;
	Y2 : integer = 240;

Var OldColor,Count,NumJunk,
    CountX,CountY : Byte;
    Junk : Char;
    XLoc,YLoc : Integer;
    OldText : TextType;

(*****************************)
procedure WriteFirstHelpScreen;

begin (*WriteFirstHelpScreen*)

  FillBox(X1-4,Y1-3,X2+4,Y2+3,LightRed);  (* Make outline *)
  FillBox(X1,Y1,X2,Y2,LightBlue);    (*  Make box  *)
  XLoc:=X1+10;YLoc:=Y1+CurrentText.Space div 2;
  OutTextXY(XLoc,YLoc,'               The Game of DOTS');
  YLoc:=YLoc+CurrentText.Space div 2 * 3;
  OutTextXY(XLoc,YLoc,'The object of DOTS is to create boxes by drawing');
  YLoc:=YLoc+CurrentText.Space;
  OutTextXY(XLoc,YLoc,'lines between the points.  If you complete a box');
  YLoc:=YLoc+CurrentText.Space;
  OutTextXY(XLoc,YLoc,'you receive a point and you get to go again.');
  YLoc:=YLoc+Round(CurrentText.Space*5/3);
  OutTextXY(XLoc,YLoc,'        Key : Function');
  Yloc:=YLoc+CurrentText.Space div 2 * 3;
  OutTextXY(XLoc,YLoc,'         F1 : Pulls up Help Screen.');
  YLoc:=YLoc+CurrentText.Space;
  OutTextXY(XLoc,YLoc,'        ESC : Ends game.');
  YLoc:=YLoc+CurrentText.Space;
  OutTextXY(XLoc,YLoc,'      ENTER : Ready to draw line.');
  YLoc:=YLoc+CurrentText.Space;
  OutTextXY(XLoc,YLoc,'          S : Switch players.');
  YLoc:=YLoc+CurrentText.Space div 2 * 3;
  OutTextXY(XLoc,YLoc,'   Arrow keys move marker until you press Enter.');
  YLoc:=YLoc+CurrentText.Space;
  OutTextXY(XLoc,YLoc,'After pressing Enter, press an arrow key to draw');
  YLoc:=YLoc+CurrentText.Space;
  OutTextXY(XLoc,YLoc,'a line on corresponding side of marker.  You may');
  YLoc:=YLoc+CurrentText.Space;
  OutTextXY(XLoc,YLoc,'also use `Diagonal'' keys to move marker.');
  YLoc:=YLoc+CurrentText.Space*2;
  OutTextXY(XLoc,YLoc,'                      Press Enter. . .');
end; (*WriteFirstHelpScreen*)

(*****************************)

procedure WriteSecondHelpScreen;

begin (*WriteSecondHelpScreen*)
     FillBox(X1,Y1,X2,Y2,LightBlue);
     CurrentText:=Text1;
     SetText(CurrentText);
     OldColor:=GetColor;
     SetColor(Yellow);
     XLoc:=X1+15;YLoc:=Y1+Round(CurrentText.Space*8/3);
     OutTextXY(XLoc,YLoc,'     DOTS was written in the Spring of 1990');
     YLoc:=YLoc+CurrentText.Space;
     OutTextXY(XLoc,YLoc,'     for those who like to play but hate to');
     YLoc:=YLoc+CurrentText.Space;
     OutTextXY(XLoc,YLoc,'         draw all those dots. . .');
     YLoc:=YLoc+CurrentText.Space*2;
     OutTextXY(XLoc,YLoc,'       Send questions or comments to');
     YLoc:=YLoc+CurrentText.Space*2;
     OutTextXY(XLoc,YLoc,'              Robert Nugen Jr');
     YLoc:=YLoc+CurrentText.Space;
     OutTextXY(XLoc,YLoc,'              27602 Kathy Ln');
     YLoc:=YLoc+CurrentText.Space;
     OutTextXY(XLoc,YLoc,'              Magnolia, Texas');
     YLoc:=YLoc+CurrentText.Space;
     OutTextXY(XLoc,YLoc,'                  77355');
     YLoc:=YLoc+CurrentText.Space*2;
     OutTextXY(XLoc,YLoc,'    Please give free copies of DOTS to all');
     YLoc:=YLoc+CurrentText.Space;
     OutTextXY(XLoc,YLoc,'           your friends and family.');
     Repeat Until KeyPressed;
     ClearBuffer;
end; (*WriteSecondHelpScreen*)
(*****************************)

Begin (*Help*)

HelpNeeded:=False;
OldColor:=GetColor;
SetColor(Yellow);
OldText:=CurrentText;
CurrentText:=Text1;         (* Default Font *)
SetText(CurrentText);


WriteFirstHelpScreen;

 Repeat
   NumJunk:=NextKey;
 Until NumJunk<>0;
 If NumJunk=13  (* Enter *)
 Then WriteSecondHelpScreen;

  (* the following stuff redraws the game as it was when left.. *)
CurrentText:=OldText;
SetText(CurrentText);
SetColor(OldColor);
ClearDevice;
DrawDots(DotArray,DotsWidth,DotsHeight);
UpdateScore(Player1);UpdateScore(Player2);
DrawArrows;
For CountX:=1 to BoxesWidth do
For CountY:=1 to BoxesHeight do begin
For Count:=1 to 4 do (* count 1-4 *)
 If BoxArray[CountX,CountY].Line[Count]  (* If there is a line there *)

 Then Case Count of
  (*Left*) 1 : DrawLine(CountX,CountY+1,CountX,CountY,LINECOLOR);
    (*Up*) 2 : DrawLine(CountX,CountY+1,CountX+1,CountY+1,LINECOLOR);
 (*Right*) 3 : DrawLine(CountX+1,CountY+1,CountX+1,CountY,LINECOLOR);
  (*Down*) 4 : DrawLine(CountX,CountY,CountX+1,CountY,LINECOLOR);
	 end; (*case*)

  FillBox(Round(DotArray[CountX,CountY]    .X+1),
	  Round(DotArray[CountX,CountY]    .Y-1),
	  Round(DotArray[CountX+1,CountY+1].X-1),
	  Round(DotArray[CountX+1,CountY+1].Y+1),
	  BoxArray[CountX,CountY].Color);

 end; (* for CountY *)
If GridFilled then DisplayWinner;
End; (*Help*)

(******************************************************************************)

Procedure PlayGame;
Var NumJunk,Num : Byte;

Begin (*PlayGame*)
 If Squashed then UnSquashIt;
  SetMarkerCorners(0,0,Space.X,Space.Y);
  SetOldMarkerColor;
  DrawMarker(OldMarker);
  DrawMarker(Marker);
  SetOldMarkerCorners;

   NumJunk:=GetBufferedInput([71..73,75,77,79..81, 27, 13,59,115,83,104]);
                            (* Direction Keys    ,ESC,ENT,F1, s ,S , h *)
  (* Capital 'H' is 72 (same as up) so it can't be used.. sorry   *)

   Case NumJunk of
   (*  Directions UpLeft,Up,URight,Left,Right,DL,D,DR *)
  71,72,73,75,77,79,80,81 : MoveMarker(BoxesWidth,BoxesHeight,NumJunk);
  (* ENTER  *)         13 : If PlayingMainGame then begin
                             Num:=GetBufferedInput([27,72,75,77,80]);
                             SeeIfAddSideOK(Num);end
                            Else GoOk:=False;
  (*`S',`s' *)     83,115 : If PlayingMainGame then AskIfSwitchPlayers;
  (*  ESC   *)         27 : If PlayingMainGame then AskIfQuit
                            Else GoOk:=False;
  (*  F1,h  *)     59,104 : Help;

 end; (*case*)
End; (*PlayGame*)

(******************************************************************************)

Procedure TitleScreen;

Const BOXESWIDTH  : Byte = 2;
      BOXESHEIGHT : Byte = 2;
      MINIGAME    : Array[1..28] of byte=
	   (172,77,72,172,175,75,80,177,77,177,71,172,175,80,
	    175,180,77,72,177,180,80,180,72,75,80,77,72,75);

Var X,Y  : Integer;
    OldText : TextType;
    Min,Max : PointType;
    OldColor,Junk,Count1,
    Count2,Count3: byte;

(**************************************)

procedure ShadowWrite(X,Y:Integer;Letters:String;Color:Byte);

var ShadowX,ShadowY,
	OldColor       : Integer;

begin (* ShadowWrite *)
ShadowX:=Round(X+CurrentText.Size*3/4);
ShadowY:=Round(Y+CurrentText.Size*3/4);
OldColor:=GetColor;
 SetColor(Black);
 OutTextXY(ShadowX,ShadowY,Letters);
 SetColor(Color);
 OutTextXY(X,Y,Letters);
SetColor(OldColor);
end; (* ShadowWrite *)

(*************************************)

Begin (*TitleScreen*)

X:=3;
Y:=7;
OldColor:=GetColor;
OldText :=CurrentText;

FillBox(0,3,GetMaxX,GetMaxY-3,LightGray);

Repeat
 Repeat
  PutPixel(X,Y,White);    (*  Draws Dots on Title Screen  *)
  Y:=Y+28;
 Until Y>=GetMaxY-5;
 X:=X+35;
 Y:=7;
Until X>=GetMaxX-5;

CurrentText.Num:=1;  (* Triplex Font *)
CurrentText.Size:=10;
SetText(CurrentText);
X:=73;                    (*   Draws  *)
Y:=7;                     (*   Title  *)
ShadowWrite(X,Y,'D O T S',Yellow);

CurrentText.Size:=2;
SetText(CurrentText);
CurrentText.Space:=Round(TextHeight('Anything')*5/4);

X:=420;
Y:=210;
ShadowWrite(X,Y,'Written by',LightGreen);
Y:=Y+CurrentText.Space;
ShadowWrite(X-15,Y,'Robert Nugen',LightGreen);

Min.X:=90;
Min.Y:=160;     (*  coordinates of minigame *)
Max.X:=305;
Max.Y:=308;

FillBox(Min.X-15,Min.Y-10,
        Max.X+15,Max.Y+10,Black);

DesignBoard(BOXESWIDTH+1,BOXESHEIGHT+1,DotArray,Space,
            Max.X,Max.Y,Min.X,Min.Y);
DrawDots(DotArray,BOXESWIDTH+1,BOXESHEIGHT+1);

 For Count1:=0 to BOXESWIDTH  do
 For Count2:=0 to BOXESHEIGHT do begin
 For Count3:=1 to 4 do
 BoxArray[Count1,Count2].Line[Count3]:=False;
 BoxArray[Count1,Count2].Filled:=False;
 BoxArray[Count1,Count2].Sides:=0;
 BoxArray[Count1,Count2].Color:=Black;end;
 For Count1:=1 to 4 do begin
 Marker.Corner[Count1].X:=0;
 Marker.Corner[Count1].Y:=0;end;
 Marker.Color:=MARKERCOLOR;
 Marker.BL.X:=1;
 Marker.BL.Y:=1;
 OldMarker:=Marker;
 Player1.Color:=LightBlue;
 Player2.Color:=LightMagenta;
 CurrentPlayer.Color:=Player1.Color;

For Count:=1 to SizeOf(MINIGAME) do begin
 SetMarkerCorners(0,0,Space.X,Space.Y);
 SetOldMarkerColor;
 DrawMarker(OldMarker);
 DrawMarker(Marker);
 SetOldMarkerCorners;
 Delay(120);
  Case MINIGAME[Count] of
   71,72,73,75,77,79,80,81 :
	      MoveMarker(BOXESWIDTH,BOXESHEIGHT,MINIGAME[Count]);
   172,175,177,180   : SeeIfAddSideOK(MINIGAME[Count]-100);
   end; (* Case *)
end; (* For Count *)

ShadowWrite(340,290,'Press Any Key to continue. .',LightGreen);
Repeat Until KeyPressed;
ClearBuffer;  (* Gets KeyPressed out of system *)
ClearDevice;
CurrentText:=OldText;
SetText(CurrentText);
SetColor(OldColor);

End; (*TitleScreen*)

(******************************************************************************)

BEGIN (*main*)

PlayingMainGame:=False;  (* The main game isn't started *)
StartGraph;
TitleScreen;
InitGame;
PlayingMainGame:=True;  (* Starting main game now *)

Repeat
   PlayGame;
Until (GridFilled);

PlayingMainGame:=False;  (* The main game is over *)
DisplayWinner;

Repeat
   PlayGame;  (* This time pressing Return or ESC ends program *);
Until Not(GoOk);

CloseGraph;

END. (*main*)
