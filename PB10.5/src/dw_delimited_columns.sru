$PBExportHeader$dw_delimited_columns.sru
Forward
Global Type dw_delimited_columns From datawindow
End Type
Type str_delimiter_desc From structure within dw_delimited_columns
End Type
End Forward

Type str_delimiter_desc From structure
String		iname
Integer		inumber
Integer		ixpos
Integer		iypos
Integer		iheight
String		iLinkedFromLeft[]
String		iLinkedFromRight[]
String		iLinkedButton[]
End Type

Type str_dw_control From structure
String		Name
String		ctype
String		band
String		formatstring
String		editmask
Integer		formattedstringlength
End Type

Global Type dw_delimited_columns From datawindow
Integer Width = 2245
Integer Height = 1468
Boolean VScrollBar = True
Event ue_delimiter_is_moved ( Integer adelimiternumber,  Integer ashift )
Event Move pbm_move
Event lbuttondown pbm_lbuttondown
Event leftbuttonup pbm_lbuttonup
Event MouseMove pbm_mousemove
End Type
Global dw_delimited_columns dw_delimited_columns

Type Prototypes
//----------------------------------------------------------------
Function Long SetCapture( &
	Long hWnd &
	) Library 'user32.dll' Alias For 'SetCapture'
//----------------------------------------------------------------
Function Long GetDC( &
	Long hWnd &
	) Library 'user32.dll' Alias For 'GetDC'
//----------------------------------------------------------------
Function Long ReleaseDC( &
	Long hWnd, &
	Long hDC &
	) Library 'user32.dll' Alias For 'ReleaseDC'
//----------------------------------------------------------------
Function Boolean PatBlt( &
	Long hDC, &
	Long nXLeft, &
	Long nYLeft, &
	Long nWidth, &
	Long nHeight, &
	ULong dwRop &
	) Library 'gdi32.dll' Alias For 'PatBlt'
//----------------------------------------------------------------
Function Boolean ReleaseCapture( ) Library 'user32.dll' Alias For 'ReleaseCapture'


End Prototypes

Type Variables
Public:
Integer iBeginXPos // "Origin" along the X axis for the creation procedure
// column separators. To the left of this position, separators
// will not be created, even if it falls into this area
// right border of any column
Private:
Constant Int LINE_WIDTH = 14 // The width of the drawn line
Constant Int DELIMITER_WIDTH = 100 // Standard separator width
Constant Int BORDER_WIDTH = 9 // Standard border width StyleRaised! at the control
Constant Int BUTTON_WIDTH = 80 // Standard width of the button bound to the column of the data window

Int ii_number_move_delimiter = 0 // Number of movable separator

Int ii_delimiter_xpos, ii_hscroll_pos, ii_shift_on_mousemove
Int ii_left_edge, ii_right_edge
Int iHeaderBottomEdge // The lowest point of the overall title. On it
// determines whether the delimiter crosses the entire header
// top to bottom, or only part of it
str_delimiter_desc iColDelimiter[] // List of separators bound to the data window
str_dw_control iControl[]
Constant ULong DSTINVERT = 5570569 //(DWORD)0x00550009
End Variables

Forward Prototypes
Public Subroutine of_create_delimiters ()
Private Function Integer of_get_left_edge (str_delimiter_desc a_delimiter)
Private Function Integer of_get_right_edge (str_delimiter_desc a_delimiter)
Private Function Integer of_create_delimiter (Readonly str_delimiter_desc a_delimiter)
Private Subroutine of_adjust_columns ()
Public Function Integer Sort ()
Public Subroutine of_create_sort_icons ()
Private Function Integer of_create_sort_icon (Readonly String as_text_name)
Public Subroutine of_setdataobject (Readonly String a_dataobject)
End Prototypes

Event ue_delimiter_is_moved(Integer adelimiternumber, Integer ashift);
Long i, j
For i = 1 To UpperBound( iColDelimiter[ ] )
	If i <> adelimiternumber Then
		If iColDelimiter[adelimiternumber].iheight >= iHeaderBottomEdge And &
			iColDelimiter[adelimiternumber].ixpos < iColDelimiter[i].ixpos &
			Then
		iColDelimiter[i].ixpos = iColDelimiter[i].ixpos + ashift
	End If
End If
Next

iColDelimiter[adelimiternumber].ixpos = iColDelimiter[adelimiternumber].ixpos + ashift

Of_Adjust_Columns( )
End Event

Event lbuttondown;
If ( flags = 1 ) Then
	/* if you clicked on an object named delimiterN, then take
		number (N) is the number of the movable delimiter
	*/
String ls_object_name
ls_object_name = GetObjectAtPointer( )
If ( Left( ls_object_name, 9 ) <> 'delimiter' ) Then
	Return 0
End If

ii_number_move_delimiter = Integer( Mid( ls_object_name, 10, Pos( ls_object_name, '~t' ) - 10 ) )
If ( ii_number_move_delimiter < 1 ) Then
	Return 0
End If

/* take left, right allowed borders and horizontal scrolling */
ii_left_edge  = Of_Get_Left_Edge( iColDelimiter[ ii_number_move_delimiter ] )
ii_right_edge = Of_Get_Right_Edge( iColDelimiter[ ii_number_move_delimiter ] )
ii_hscroll_pos = Long( Describe( 'DataWindow.HorizontalScrollPosition' ) )

SetCapture( Handle( This ) )

Long ll_DC // HDC
ll_DC = GetDC( Handle( This ) )
ii_delimiter_xpos = iColDelimiter[ ii_number_move_delimiter ].ixpos - ii_hscroll_pos - ( LINE_WIDTH / 2 )
ii_shift_on_mousemove = XPos - ii_delimiter_xpos
patBlt( ll_DC, &
	UnitsToPixels( ii_delimiter_xpos, XUnitsToPixels! ), &
	UnitsToPixels( iColDelimiter[ ii_number_move_delimiter ].iypos, YUnitsToPixels! ), &
	UnitsToPixels( LINE_WIDTH, XUnitsToPixels! ), &
	UnitsToPixels( Height, YUnitsToPixels! ), DSTINVERT )

ReleaseDC( Handle( This ), ll_DC )
End If

Return 0
End Event

Event leftbuttonup;
If ( 0 < ii_number_move_delimiter ) Then
	Long	ll_DC // HDC
	ll_DC = GetDC( Handle( This ) )
	patBlt( ll_DC, &
		UnitsToPixels( ii_delimiter_xpos, XUnitsToPixels! ), &
		UnitsToPixels( iColDelimiter[ ii_number_move_delimiter ].iypos, YUnitsToPixels! ), &
		UnitsToPixels( LINE_WIDTH, XUnitsToPixels! ), &
		UnitsToPixels( Height, YUnitsToPixels! ), DSTINVERT )
	ReleaseDC( Handle( This ), ll_DC )
	ReleaseCapture( )
	
	Event Ue_Delimiter_Is_Moved( ii_number_move_delimiter, ii_delimiter_xpos - iColDelimiter[ ii_number_move_delimiter ].ixpos + ii_hscroll_pos + ( LINE_WIDTH / 2 ) )
	ii_number_move_delimiter = 0
End If
End Event

Event MouseMove;
If ( 0 < ii_number_move_delimiter ) Then
	If ( 0 < ii_left_edge ) And ( XPos + ii_hscroll_pos - ii_shift_on_mousemove < ii_left_edge ) Then
		Return 0
	End If
	If ( 0 < ii_right_edge ) And ( ii_right_edge < XPos + ii_hscroll_pos - ii_shift_on_mousemove ) Then
		Return 0
	End If
	
	ULong	ll_DC // HDC
	ll_DC = GetDC( Handle( This ) )
	patBlt( ll_DC, &
		UnitsToPixels( ii_delimiter_xpos, XUnitsToPixels! ), &
		UnitsToPixels( iColDelimiter[ ii_number_move_delimiter ].iypos, YUnitsToPixels! ), &
		UnitsToPixels( LINE_WIDTH, XUnitsToPixels! ), &
		UnitsToPixels( Height, YUnitsToPixels! ), DSTINVERT )
	ii_delimiter_xpos = XPos - ii_shift_on_mousemove
	patBlt( ll_DC, &
		UnitsToPixels( ii_delimiter_xpos, XUnitsToPixels! ), &
		UnitsToPixels( iColDelimiter[ ii_number_move_delimiter ].iypos, YUnitsToPixels! ), &
		UnitsToPixels( LINE_WIDTH, XUnitsToPixels! ), &
		UnitsToPixels( Height, YUnitsToPixels! ), DSTINVERT )
	ReleaseDC( Handle( This ), ll_DC )
End If

Return 0
End Event

Public Subroutine of_create_delimiters ();
// Loop over all the data window controls, select from them
// column headings and order them in ascending order of value
// position of the right border.
datastore lDWHeaderList;
lDWHeaderList = Create datastore
lDWHeaderList.DataObject = "d_dw_header_list"

Long i, j, lRow
For i = 1 To UpperBound( iControl )
	If iControl[i].band = "header" And &
		iControl[i].ctype = "text" And &
		Describe( iControl[i].Name + ".Visible" ) = "1" &
		Then
	lRow = lDWHeaderList.InsertRow( 0 )
	lDWHeaderList.Object.Name[lRow] = iControl[i].Name
	lDWHeaderList.Object.X[lRow] = Long( Describe( iControl[i].Name + ".X" ) )
	lDWHeaderList.Object.Y[lRow] = Long( Describe( iControl[i].Name + ".Y" ) )
	lDWHeaderList.Object.Width[lRow] = Long( Describe( iControl[i].Name + ".Width" ) )
	lDWHeaderList.Object.Height[lRow] = Long( Describe( iControl[i].Name + ".Height" ) )
	lDWHeaderList.Object.right_edge[lRow] = lDWHeaderList.Object.X[lRow] + lDWHeaderList.Object.Width[lRow]
	lDWHeaderList.Object.bottom_edge[lRow] = lDWHeaderList.Object.Y[lRow] + lDWHeaderList.Object.Height[lRow]
	If iHeaderBottomEdge < lDWHeaderList.Object.bottom_edge[lRow] Then
		iHeaderBottomEdge = lDWHeaderList.Object.bottom_edge[lRow]
	End If
End If
Next

If lDWHeaderList.RowCount() = 0 Then Return

lDWHeaderList.SetSort( "#2 A, #3 A" )
lDWHeaderList.Sort()

// Create and place dividers in the title bar of the window
// The criterion for placing the separator along the X axis is the left border
// of the "title" element. Moreover, if the border for different headers varies
// within + - 20 points, we consider them the same. Height
// separator will be the sum of heights of all headers with the same left
// border. Y-axis placement is determined by the Y value of the
// top heading from a group with the same left border

Long lX, lY, lWidth, lHeight // separator parameters

i = 0
For lRow = 1 To lDWHeaderList.RowCount()
	If ( lRow = 1 ) Then
		iBeginXPos = lDWHeaderList.Object.X[lRow]
		lX = iBeginXPos
	End If
	If lDWHeaderList.Object.X[lRow] - iBeginXPos > 20 And &
		( lDWHeaderList.Object.X[lRow] - lX > 20 Or lDWHeaderList.Object.Y[lRow] - lY - lHeight > 20 ) &
		Then
	// If the left border of the title element is to the right of the separator
	// (or "reference points" of iBeginPos) at a distance of more than 20 points,
	// create a new separator. A new delimiter is also created if
	// header element does not touch its top border with the bottom
	// the border of the element with the same left border, but located above
	lX = lDWHeaderList.Object.X[lRow]
	lY = lDWHeaderList.Object.Y[lRow]
	lHeight = lDWHeaderList.Object.Height[lRow] + 12
	i ++;
	iColDelimiter[i].iname = 'delimiter' + String( i )
	iColDelimiter[i].inumber = i
	iColDelimiter[i].ixpos = lX - BORDER_WIDTH
	iColDelimiter[i].iypos = lY
	iColDelimiter[i].iheight = lHeight
	j = 1;
	iColDelimiter[i].iLinkedFromRight[j] = lDWHeaderList.Object.Name[lRow]
	Of_Create_Delimiter( iColDelimiter[i] )
Else
	// If header elements are directly below one another
	// and have the same left border, then just lengthen the separator
	If i > 0 Then
		lHeight = lHeight + lDWHeaderList.Object.Height[lRow] + 12
		iColDelimiter[i].iheight = lHeight
		Modify( iColDelimiter[i].iname + '.Height = ' + String( iColDelimiter[i].iheight ) )
		j ++;
		iColDelimiter[i].iLinkedFromRight[j] = lDWHeaderList.Object.Name[lRow]
	End If
End If

Next



// Determine which header elements to which separator
// anchored to the left
For i = 1 To UpperBound( iColDelimiter )
	j = 1
	For lRow = 1 To lDWHeaderList.RowCount()
		If lDWHeaderList.Object.Busy[lRow] = 0 Then
			If Abs( iColDelimiter[i].ixpos - lDWHeaderList.Object.right_edge[lRow] ) <= 20 Then
				iColDelimiter[i].iLinkedFromLeft[j] = lDWHeaderList.Object.Name[lRow]
				iColDelimiter[i].iLinkedButton[j] = ""
				lDWHeaderList.Object.Busy[lRow] = 1
				j++
			End If
		End If
	Next
Next

// Create the rightmost separator
i = 0
For lRow = 1 To lDWHeaderList.RowCount()
	If lDWHeaderList.Object.Busy[lRow] = 0 Then
		If i = 0 Then
			i = UpperBound( iColDelimiter ) + 1
			iColDelimiter[i].iname = 'delimiter' + String( i )
			iColDelimiter[i].inumber = i
			iColDelimiter[i].ixpos = lDWHeaderList.Object.right_edge[lRow] + 10
			iColDelimiter[i].iypos = lDWHeaderList.Object.Y[lRow]
			iColDelimiter[i].iheight = lDWHeaderList.Object.Height[lRow] + 12
			j = 1;
			iColDelimiter[i].iLinkedFromLeft[j] = lDWHeaderList.Object.Name[lRow]
			Of_Create_Delimiter( iColDelimiter[i] )
		Else
			iColDelimiter[i].iheight = iColDelimiter[i].iheight + lDWHeaderList.Object.Height[lRow] + 12
			Modify( 'delimiter' + String( iColDelimiter[i].inumber ) + '.Height = ' + String( iColDelimiter[i].iheight ) )
			If lDWHeaderList.Object.Y[lRow] < iColDelimiter[i].iypos Then
				iColDelimiter[i].iypos = lDWHeaderList.Object.Y[lRow]
				Modify( iColDelimiter[i].iname + '.y = ' + String( iColDelimiter[i].iypos ) )
			End If
			j ++;
			iColDelimiter[i].iLinkedFromLeft[j] = lDWHeaderList.Object.Name[lRow]
		End If
	End If
Next

String lButtonName, lButtonXPos, lButtonVisible
For i = 1 To UpperBound( iColDelimiter )
	For j = 1 To UpperBound( iColDelimiter[i].iLinkedFromLeft )
		lButtonName = Left( iColDelimiter[i].iLinkedFromLeft[j], Len( iColDelimiter[i].iLinkedFromLeft[j] ) - 2 ) + "_b"
		lButtonXPos = Describe( lButtonName + ".X" )
		lButtonVisible = Describe( lButtonName+".Visible" )
		If lButtonXPos = "!" Or lButtonVisible <> "1" Then
			iColDelimiter[i].iLinkedButton[j] = ""
		Else
			iColDelimiter[i].iLinkedButton[j] = lButtonName
		End If
	Next
Next

Destroy lDWHeaderList

Of_Adjust_Columns( )
End Subroutine

Private Function Integer of_get_left_edge (str_delimiter_desc a_delimiter);
Int li_x, li_LeftEdge, i

For i = 1 To UpperBound( a_delimiter.iLinkedFromLeft[] )
	li_x = Long( Describe( a_delimiter.iLinkedFromLeft[i] + ".X" ) )
	If a_delimiter.iLinkedButton[i] <> "" Then
		li_x += BUTTON_WIDTH
	Else
		li_x += ( DELIMITER_WIDTH / 2 )
	End If
	If li_x < 0 Then li_x = 0
	If li_x > li_LeftEdge Then li_LeftEdge = li_x
Next

Return li_LeftEdge
End Function

Private Function Integer of_get_right_edge (str_delimiter_desc a_delimiter);
Long lRightEdge
If a_delimiter.iheight > iHeaderBottomEdge - 20 Then
	// For separators whose height is almost equal to the height of everything
	// header, the right border of possible movement is the right one
	// border of the data window, since moving such a separator
	// causes the other delimiters to be moved to the right of it
	Return lRightEdge
End If

Int lNumber, iXPosMax
Long i
For i = 1 To UpperBound( iColDelimiter )
	If i <> a_delimiter.inumber And iColDelimiter[i].ixpos > a_delimiter.ixpos Then
		If a_delimiter.iypos + 10 > iColDelimiter[i].iypos And a_delimiter.iypos + 10 < iColDelimiter[i].iypos + iColDelimiter[i].iheight Then
			If iXPosMax = 0 Then
				iXPosMax = iColDelimiter[i].ixpos
				lNumber = i
			Else
				If iColDelimiter[i].ixpos < iXPosMax Then
					iXPosMax = iColDelimiter[i].ixpos
					lNumber = i
				End If
			End If
		End If
	End If
Next

lRightEdge = iXPosMax - 30
Int lButtonY, lButtonHeight
For i = 1 To UpperBound( iColDelimiter[lNumber].iLinkedButton )
	If iColDelimiter[lNumber].iLinkedButton[i] <> "" Then
		lButtonY = Long( Describe( iColDelimiter[lNumber].iLinkedButton[i] + ".Y" ) )
		lButtonHeight = Long( Describe( iColDelimiter[lNumber].iLinkedButton[i] + ".Height" ) )
		If  a_delimiter.iypos + 10 > lButtonY And a_delimiter.iypos + 10 < lButtonY + lButtonHeight Then
			lRightEdge = lRightEdge - BUTTON_WIDTH + 20
			Exit
		End If
	End If
Next

Return lRightEdge

End Function

Private Function Integer of_create_delimiter (Readonly str_delimiter_desc a_delimiter);
String ls_create_text

ls_create_text = 'create text(band=header alignment="0" text="" border="0" color="0" ' + &
	'x="' + String( a_delimiter.ixpos ) + '" y="' + String( a_delimiter.iypos ) + '" height="' + String( a_delimiter.iheight ) + '" width="' + String( DELIMITER_WIDTH ) + '" ' + &
	'html.valueishtml="0" name=' + a_delimiter.iname + ' pointer="SizeWE!" visible="1" font.face="MS Sans Serif" font.height="-8" font.weight="700" font.family="2" font.pitch="2" font.charset="204" ' + &
	'background.mode="2" background.color="536870912" )'

If ( Modify( ls_create_text ) <> '' ) Then
	Return 0
End If

Return 1
End Function

Private Subroutine of_adjust_columns ();
SetRedraw( False )

String lHeaderItemName, lDetailItemName
// Set the X coordinates of the header elements using
// the position of the delimiter to which they are attached to the right
Long i, j
For i = 1 To UpperBound( iColDelimiter )
	For j = 1 To UpperBound( iColDelimiter[i].iLinkedFromRight )
		lHeaderItemName = iColDelimiter[i].iLinkedFromRight[j]
		Modify( lHeaderItemName + ".X=" + String( iColDelimiter[i].ixpos + BORDER_WIDTH ) )
		Modify( iColDelimiter[i].iname + '.x = ' + String( iColDelimiter[i].ixpos - DELIMITER_WIDTH/2 ) )
	Next
Next

// Set the width of the header elements, as well as the position and width
// columns, using the position of the separator they are bound to
// left. Along the way, we set the position of the buttons associated with the columns
Long lColX, lWidth
For i = 1 To UpperBound( iColDelimiter )
	For j = 1 To UpperBound( iColDelimiter[i].iLinkedFromLeft )
		lHeaderItemName = iColDelimiter[i].iLinkedFromLeft[j]
		
		lColX = Long( Describe( lHeaderItemName + ".X" ) )
		lWidth = iColDelimiter[i].ixpos - lColX - BORDER_WIDTH
		Modify( lHeaderItemName + ".Width=" + String( lWidth ) )
		Modify( lHeaderItemName + "_sort_icon_a.X=" + String( lWidth + lColX - 60 ) )
		Modify( lHeaderItemName + "_sort_icon_d.X=" + String( lWidth + lColX - 60 ) )
		Modify( lHeaderItemName + "_back_icon.X=" + String( lWidth + lColX - 70 ) )
		Modify( iColDelimiter[i].iname + '.x = ' + String( lColX + lWidth + BORDER_WIDTH - DELIMITER_WIDTH/2 ) )
		
		lDetailItemName = Left( lHeaderItemName, Len( lHeaderItemName ) - 2)
		If Describe( lDetailItemName + ".X" ) = "!" Then
			If lHeaderItemName <> "indent_t" Then
				MessageBox( 'Предупреждение', "Не найдена колонка " + lDetailItemName + " для элемента заголовка " + lHeaderItemName, Information! )
			End If
		Else
			Int li_x, li_width
			li_x = lColX - BORDER_WIDTH - 2
			li_x = UnitsToPixels( li_x, XUnitsToPixels! )
			li_x = PixelsToUnits( li_x, XPixelsToUnits! )
			Modify( lDetailItemName + ".X=" + String( li_x ) )
			If iColDelimiter[i].iLinkedButton[j] = "" Then
				li_width = lWidth + ( 2 * BORDER_WIDTH ) - 4
				li_width = UnitsToPixels( li_width, XUnitsToPixels! )
				li_width = PixelsToUnits( li_width, XPixelsToUnits! )
				Modify( lDetailItemName + ".Width=" + String( li_width ) )
			Else
				li_width = iColDelimiter[i].ixpos - lColX - BUTTON_WIDTH - 6
				li_width = UnitsToPixels( li_width, XUnitsToPixels! )
				li_width = PixelsToUnits( li_width, XPixelsToUnits! )
				Modify( lDetailItemName + ".Width=" + String( li_width ) )
				Modify( iColDelimiter[i].iLinkedButton[j] + ".X=" + String( iColDelimiter[i].ixpos - BUTTON_WIDTH - 8 ) )
			End If
		End If
	Next
Next

SetRedraw( True )
End Subroutine

Public Function Integer Sort ();
Int li_ret

li_ret = Super :: Sort( )
If ( li_ret <> 1 ) Then
	Return li_ret
End If

// reset visible for everyone
String ls_modify_str
Int i
For i = 1 To UpperBound( iControl )
	If ( iControl[i].band = "header" ) And ( iControl[i].ctype = "text" ) And &
		( Describe( iControl[i].Name + ".Visible" ) = "1" ) Then
		ls_modify_str += iControl[i].Name + '_sort_icon_a.Visible = 0~t'
		ls_modify_str += iControl[i].Name + '_sort_icon_d.Visible = 0~t'
		ls_modify_str += iControl[i].Name + '_back_icon.Visible = 0~t'
	End If
Next

String ls_sort
ls_sort = Describe( 'DataWindow.Table.Sort' ) + ','
Do While ( 0 < Pos( ls_sort, ',' ) )
	String ls_col_name, ls_type_sort
	ls_col_name = Trim( Left( ls_sort, Pos( ls_sort, ',' ) - 1 ) )
	ls_sort = Trim( Mid( ls_sort, Pos( ls_sort, ',' ) + 1 ) )
	
	ls_type_sort = Trim( Mid( ls_col_name, Pos( ls_col_name, ' ' ) + 1 ) )
	ls_col_name = Trim( Left( ls_col_name, Pos( ls_col_name, ' ' ) - 1 ) )
	
	If ( Describe( ls_col_name + '.Visible' ) = '1' ) Then
		If ( Lower( ls_type_sort ) = 'a' ) Then
			ls_modify_str += ls_col_name + '_t_sort_icon_a.Visible = 1~t'
			ls_modify_str += ls_col_name + '_t_back_icon.Visible = 1~t'
		End If
		If ( Lower( ls_type_sort ) = 'd' ) Then
			ls_modify_str += ls_col_name + '_t_sort_icon_d.Visible = 1~t'
			ls_modify_str += ls_col_name + '_t_back_icon.Visible = 1~t'
		End If
	End If
Loop

Modify( ls_modify_str )

Return li_ret
End Function

Public Subroutine of_create_sort_icons ();
Int i
For i = 1 To UpperBound( iControl[] )
	If iControl[i].band = "header" And &
		iControl[i].ctype = "text" And &
		Describe( iControl[i].Name + ".Visible" ) = "1" &
		Then
	Of_Create_Sort_Icon( iControl[i].Name )
End If
Next

Sort( )
End Subroutine

Private Function Integer of_create_sort_icon (Readonly String as_text_name);
Int li_x, li_y, li_width, li_height
li_x = Integer( Describe( as_text_name + '.X' ) )
li_y = Integer( Describe( as_text_name + '.Y' ) )
li_width = Integer( Describe( as_text_name + '.Width' ) )
li_height = Integer( Describe( as_text_name + '.Height' ) )
li_x += ( li_width - 60 )

String ls_create_text

ls_create_text = 'create text(band=header alignment="0" text="" border="0" color="33554432" ' + &
	'x="' + String( li_x - 10 ) + '" y="' + String( li_y + 2 ) + '" height="' + String( li_height - 4 ) + '" width="61" ' + &
	'html.valueishtml="0" name=' + as_text_name + '_back_icon visible="0"  font.face="MS Sans Serif" font.height="-8" font.weight="700"  font.family="2" font.pitch="2" font.charset="204" background.mode="2" background.color="67108864" )'

If ( Modify( ls_create_text ) <> '' ) Then
	Return 0
End If

ls_create_text = 'create bitmap(band=header filename="..\resourses\SortA.gif" ' + &
	'x="' + String( li_x ) + '" y="' + String( li_y + 20 ) + '" height="20" width="41" ' + &
	'border="0" name=' + as_text_name + '_sort_icon_a visible="0" )'

If ( Modify( ls_create_text ) <> '' ) Then
	Return 0
End If

ls_create_text = 'create bitmap(band=header filename="..\resourses\SortD.gif" ' + &
	'x="' + String( li_x ) + '" y="' + String( li_y + 20 ) + '" height="20" width="41" ' + &
	'border="0" name=' + as_text_name + '_sort_icon_d visible="0" )'

If ( Modify( ls_create_text ) <> '' ) Then
	Return 0
End If

Return 1
End Function

Public Subroutine of_setdataobject (Readonly String a_dataobject);
If Lower( DataObject ) <> Lower( a_dataobject ) Then
	DataObject = a_dataobject
End If

If IsValid( Object ) Then
	// Gather information about the data window objects
	String lObjectList
	lObjectList = Object.datawindow.Objects + "~t"
	
	Long lBegPos = 1, lEndPos, lXPos, lYPos
	String lControlName
	Boolean lControlExists
	Long i,j
	Do While True
		lEndPos = Pos( lObjectList, "~t", lBegPos )
		If lEndPos = 0 Then Exit
		lControlName = Mid( lObjectList, lBegPos, lEndPos - lBegPos )
		lControlExists = False
		For j = 1 To UpperBound( iControl )
			If lControlName = iControl[j].Name Then
				lControlExists = True
				Exit
			End If
		Next
		If Not lControlExists Then
			i++
			iControl[i].Name = lControlName
			iControl[i].ctype = Describe( lControlName + ".Type" )
			iControl[i].band = Describe( lControlName + ".Band" )
		End If
		lBegPos = lEndPos + 1
	Loop
	
	Of_Create_Sort_Icons( )
	Of_Create_Delimiters( )
End If
End Subroutine

On dw_delimited_columns.Create
End On

On dw_delimited_columns.Destroy
End On

Event Constructor;
Of_SetDataObject( DataObject )
End Event

