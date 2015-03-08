/*
 * HDroidGUI - Harbour for Android GUI framework
 * HDActivity - Activity class
 */

#include "hbclass.ch"

#define MAX_BACKUPW  16

CLASS HDGUIObject

   CLASS VAR oDefaultParent SHARED

ENDCLASS

CLASS HDWindow INHERIT HDGUIObject

   CLASS VAR aWindows SHARED  INIT {}
   CLASS VAR aBackupW SHARED  INIT {}
   CLASS VAR nIdSch   SHARED  INIT 1
   CLASS VAR lMain    SHARED  INIT .T.

   DATA id
   DATA title
   DATA bInit, bExit

   DATA aItems   INIT {}

   METHOD New( cTitle, bInit, bExit )
   METHOD Init()
   METHOD Close( cId )
   METHOD FindByName( cName )

ENDCLASS

METHOD New( cTitle, bInit, bExit ) CLASS HDWindow

   ::oDefaultParent := Self

   ::title := cTitle
   IF ::lMain
      ::id := "0"
      ::lMain := .F.
   ELSE
      ::id := Ltrim( Str( ++::nIdSch ) )
   ENDIF

   ::bInit := bInit
   ::bExit := bExit

   Aadd( ::aWindows, Self )

   RETURN Self

METHOD Init() CLASS HDWindow

   IF !Empty( ::bInit )
      Eval( ::bInit )
   ENDIF
   RETURN Nil

METHOD Close( cId ) CLASS HDWindow
   LOCAL i, o

   IF !Empty( ::aWindows )
      FOR i := Len( ::aWindows ) TO 1 STEP -1
         IF ( cId == Nil .AND. ::aWindows[i] == Self ) .OR. ( cId != Nil .AND. ::aWindows[i]:id == cId )
            o := ::aWindows[i]
            IF Len( ::aBackupW ) < MAX_BACKUPW
               Aadd( ::aBackupW, o )
            ELSE
               ADel( ::aBackupW, 1 )
               ::aBackupW[MAX_BACKUPW] := o
            ENDIF
            ADel( ::aWindows, i )
            ASize( ::aWindows, Len(::aWindows)-1 )
            EXIT
         ENDIF
      NEXT
      IF !Empty(o) .AND. Valtype( o:bExit ) == "B"
         Eval( o:bExit, o )
      ENDIF
   ENDIF

   RETURN Nil

METHOD FindByName( cName ) CLASS HDWindow
 
   LOCAL aItems := ::aItems, oItem, o

   FOR EACH oItem IN aItems
      IF !Empty( oItem:objname ) .AND. oItem:objname == cName
         RETURN oItem
      ELSEIF __ObjHasMsg( oItem, "AITEMS" ) .AND. !Empty( o := oItem:FindByName( cName ) )
         RETURN o
      ENDIF
   NEXT

   RETURN Nil

CLASS HDActivity INHERIT HDWindow

   DATA oFont
   DATA aMenu

   METHOD New( cTitle, bInit, bExit )
   METHOD Activate()

   METHOD AddMenu( nId, cTitle )
   METHOD EndMenu()
   METHOD AddMenuItem( cTitle, nId, bAction )

   METHOD ToString()

ENDCLASS

METHOD New( cTitle, bInit, bExit ) CLASS HDActivity

   ::Super:New( cTitle, bInit, bExit )

   RETURN Self

METHOD Activate() CLASS HDActivity

   hd_calljava_s_v( ::ToString(), "activ" )

   RETURN Nil

METHOD AddMenu( nId, cTitle ) CLASS HDActivity

   IF Valtype( ::aMenu ) == "A"
   ELSE
      ::aMenu := {}
   ENDIF

   RETURN Nil

METHOD EndMenu() CLASS HDActivity

   RETURN Nil

METHOD AddMenuItem( cTitle, nId, bAction ) CLASS HDActivity

   LOCAL nLen

   IF Valtype( ::aMenu ) != "A"
      RETURN Nil
   ENDIF

   nLen := Len( ::aMenu )
   IF nLen > 0 .AND. Len( ::aMenu[nLen] ) > 3
   ELSE
      nLen ++
      nId := Iif( nId == Nil, nLen, nId )
      AAdd( ::aMenu, { cTitle, nId, bAction } )
   ENDIF

   RETURN Nil

METHOD ToString() CLASS HDActivity

   LOCAL sRet := "act:" + ::id + ",,t:" + ::title + ",,/", i

   IF !Empty( ::aMenu )
      sRet += "menu[("
      FOR i := 1 TO Len( ::aMenu )
         sRet += Iif( i==1, "", ",," ) + ::aMenu[i,1]
      NEXT
      sRet += ")],,/"
   ENDIF

   IF !Empty( ::aItems )
      sRet += ::aItems[1]:ToString()
   ENDIF

   RETURN sRet

CLASS HDDialog INHERIT HDWindow

   DATA aButtons
   DATA nRes

   METHOD New( cTitle, bInit, bExit )
   METHOD Activate()

   METHOD onBtnClick( cName )
   METHOD ToString()

ENDCLASS

METHOD New( cTitle, bInit, bExit ) CLASS HDDialog

   ::Super:New( cTitle, bInit, bExit )

   RETURN Self

METHOD Activate() CLASS HDDialog

   hd_calljava_s_v( ::ToString(), "adlg" )

   RETURN Nil


METHOD onBtnClick( cName ) CLASS HDDialog

   IF !Empty( ::aButtons )
      ::nRes := Ascan( ::aButtons, cName )
   ENDIF

   ::Close()

   RETURN "1"

METHOD ToString() CLASS HDDialog

   LOCAL sRet := "dlg:" + ::id + ",,t:" + ::title + ",,/", i, nLen := Len( ::aItems )

   FOR i := 1 TO nLen
      sRet += ::aItems[i]:ToString() + Iif( i<nLen, ",,/","" )
   NEXT

   RETURN sRet


CLASS HDTimer INHERIT HDGUIObject

   CLASS VAR aTimers       INIT {}
   CLASS VAR nId SHARED    INIT 0

   DATA id
   DATA value
   DATA bAction

   METHOD New( value, bAction )
   METHOD End()

ENDCLASS

METHOD New( value, bAction ) CLASS HDTimer

   ::id := LTrim( Str( ++::nId ) )
   ::value   := value
   ::bAction := bAction

   AAdd( ::aTimers, Self )
   hd_calljava_s_v( "settimer:" + ::id + ":" + LTrim( Str( ::value ) ) )

   RETURN Self

METHOD End() CLASS HDTimer

   LOCAL i := Ascan( ::aTimers, { |o|o:id == ::id } )

   IF i != 0
      ADel( ::aTimers, i )
      ASize( ::aTimers, Len( ::aTimers ) - 1 )
   ENDIF

   hd_calljava_s_v( "killtimer:" + ::id + ":" )

   RETURN Nil
