'
' MediaMonkey Script
'
' NAME Kodi MV nfo generator 1.00
' DATE 2/1/2016
' This script is hosted on Github user scott967 repository https://github.com/scott967/Music-video-nfo-generator
'
' based on
' Script: CustomReport 2.8  by trixmoto
'
' ORIGINAL AUTHOR: trixmoto (http://trixmoto.net)
' DATE : 05/03/2011
'
' INSTALL: Copy to Scripts directory and add the following to Scripts.ini 
'          Don't forget to remove comments (') and set the order appropriately
'
' [MV nfo generator]
' FileName=MV_nfo_generator.vbs
' ProcName=CustomReport
' Order=51
' DisplayName=MV nfo generator
' Description=Create Kodi nfo file for MV
' Language=VBScript
' ScriptType=1
'
' FORMAT:
'   Add: A1 - "1" becomes "2"
'   Newline char: C*** - Newline character
'   Divide: D100 - "1" becomes "0.01"
'   Extract: E()2 - "A B C" becomes "B"
'   Format date: Fd/m/Y - "30th Oct 2009" becomes "30/10/2009" - http://uk.php.net/manual/en/function.date.php
'   Hyperlink: H... - Create link in HTML
'   Hyperlink: I... - Create link in HTML using mask 
'   Lowercase: L - "Word" becomes "word"
'   Multiply: M100 - "1" becomes "100"
'   Number: N2 - "1" becomes "1.00"
'   Prefix: P( - "Word" becomes "(Word"
'   Replace: R1=One - "1" becomes "One"
'   Suffix: S) - "Word" becomes "Word)"
'   Title case: T - "WORD" becomes "Word"
'   Uppercase: U - "Word" becomes "WORD"
'   Width: W25% - Column width in HTML
'   Leading zeros: Z2 - "1" becomes "01"
'   Traverse: \1 - "C:\Music\Test.mp3" becomes "Music\Test.mp3"
'
' FIXES: Fixed "OriginalDate" was looking at the "Date" fields
'        Added "OriginalDay" and "OriginalMonth" fields
'        Added "StartTime", "StopTime", "SkipCount" and "TrackType" (MM4 only)   
'

Option Explicit
Dim AppTitle : AppTitle = "MV nfo generator 1.00"
Dim FormatHint : FormatHint = "Add: A1"&Chr(13)&"Newline char: C***"&Chr(13)&"Divide: D100"&Chr(13)&"Extract: E()2"&Chr(13)&"Format date: Fd/m/Y"&Chr(13)&"Hyperlink: H..."&Chr(13)&"Hyperlink: I..."&Chr(13)&"Lowercase: L"&Chr(13)&"Multiply: M100"&Chr(13)&"Number: N2"&Chr(13)&"Prefix: P("&Chr(13)&"Replace: R1=One"&Chr(13)&"Suffix: S)"&Chr(13)&"Title case: T"&Chr(13)&"Uppercase: U"&Chr(13)&"Width: W25%"&Chr(13)&"Leading zeros: Z2"&Chr(13)&"Traverse: \1"
Dim Debug : Debug = False
Dim Pixels : Pixels = 450
Dim ColMax : ColMax = 15
Dim CountAuto : CountAuto = False

Sub CustomReport()
  Dim list : Set list = SDB.CurrentSongList
  If list.Count = 0 Then
    Set list = SDB.AllVisibleSongList
  End If
  Dim yes : yes = True
  Dim iter : Set iter = SDB.Database.OpenSQL("SELECT Count(PlaylistName), Count(DISTINCT PlaylistName) FROM Playlists")
  If Not (iter.ValueByIndex(0) = iter.ValueByIndex(1)) Then
    yes = False
    If list.Count = 0 Then
      Call SDB.MessageBox("CustomReport: There is a playlist name clash, please select tracks or rename.",mtError,Array(mbOk))
      Exit Sub
    End If    
  End If
  
  '********************************************************************'
  '* Form produced by MMVBS Form Creator (http://trixmoto.net/mmvbs)  *'
  '********************************************************************'

  Dim Form1 : Set Form1 = SDB.UI.NewForm
  Form1.BorderStyle = 3
  Form1.Caption = AppTitle
  Form1.StayOnTop = True
  Form1.FormPosition = 4
  Form1.Common.SetRect 0,0,436,165+(25*ColMax)
  Form1.Common.ControlName = "CustomReportName"

  Dim Label1 : Set Label1 = SDB.UI.NewLabel(Form1)
  Label1.Common.SetRect 5,10,65,17
  Label1.Caption = "Format:"

  Dim DropDown1 : Set DropDown1 = SDB.UI.NewDropDown(Form1)
  DropDown1.AddItem("CSV")
  DropDown1.AddItem("HTML")
  DropDown1.AddItem("XLS")
  DropDown1.AddItem("NFO")
  DropDown1.AddItem("TXT")
  DropDown1.AddItem("CD Cover")
  DropDown1.AddItem("CD Tiled")
  DropDown1.AddItem("XLSX")
  DropDown1.ItemIndex = SDB.IniFile.IntValue("MVNfoGenerator","Format")
  DropDown1.Style = 2
  DropDown1.Common.SetRect 60,7,100,21
  DropDown1.Common.ControlName = "Format"
  DropDown1.UseScript = Script.ScriptPath
  DropDown1.OnSelectFunc = "FormatSelect"  
  
  Dim Button8 : Set Button8 = SDB.UI.NewButton(Form1)
  Button8.Common.ControlName = "Delimiter"
  Button8.Caption = ","
  Button8.Common.SetRect 163,7,21,21
  Button8.UseScript = Script.ScriptPath
  Button8.OnClickFunc = "DelimiterClick"
  If DropDown1.ItemIndex > 0 Then
    Button8.Common.Visible = False
  End If
  
  Dim Check2 : Set Check2 = SDB.UI.NewCheckBox(Form1)
  Check2.Common.ControlName = "BackCover"
  Check2.Caption = ""
  Check2.Common.SetRect 165,7,21,21
  Check2.Common.Hint = "Include back cover"
  Check2.Checked = SDB.IniFile.BoolValue("MVNfoGenerator","BackCover")
  If DropDown1.ItemIndex < 5 Then
    Check2.Common.Visible = False
  End If
  
  Dim Label7 : Set Label7 = SDB.UI.NewLabel(Form1)
  Label7.Common.SetRect 190,10,65,17
  Label7.Caption = "Include:"  
  
  Dim DropDown5 : Set DropDown5 = SDB.UI.NewDropDown(Form1)
  DropDown5.AddItem("Selected tracks ("&list.Count&")")
  If yes Or list.Count = 0 Then
    If CountAuto Then
      DropDown5.AddItem("All playlists ("&SumTracks(True)&")")
    Else
      DropDown5.AddItem("All playlists ("&SumTracks(False)&"+)")
    End If
  End If  
  If list.Count > 0 Then 
    If yes Then
      DropDown5.ItemIndex = SDB.IniFile.IntValue("MVNfoGenerator","Source")
    Else      
      DropDown5.ItemIndex = 0
      DropDown5.Common.Enabled = False      
    End If
  Else  
    DropDown5.ItemIndex = 1
    DropDown5.Common.Enabled = False
  End If
  DropDown5.Style = 2
  DropDown5.Common.Width = 162
  DropDown5.Common.Left = 237
  DropDown5.Common.Top = Dropdown1.Common.Top
  DropDown5.Common.ControlName = "Source"    
  
  Dim Check1 : Set Check1 = SDB.UI.NewCheckbox(Form1)
  Check1.Common.SetRect 5,Form1.Common.Height-55,165,17
  Check1.Checked = SDB.IniFile.BoolValue("MVNfoGenerator","Unicode")
  Check1.Common.ControlName = "Unicode"
  Check1.Caption = "Support unicode?"  

  Dim Label2 : Set Label2 = SDB.UI.NewLabel(Form1)
  Label2.Common.SetRect 5,35,65,17
  Label2.Caption = "Filename:"

  Dim Edit1 : Set Edit1 = SDB.UI.NewEdit(Form1)
  Edit1.Common.SetRect 60,32,315,21
  Edit1.Text = upmask(fixpath(SDB.IniFile.StringValue("MVNfoGenerator","Filename")))
  Edit1.Common.ControlName = "Filename"
  Edit1.Common.Hint = "<Y>ear <M>onth <D>ay <H>our Mi<N>ute <S>econd <V>ersion <B>uild"  

  Dim Button1 : Set Button1 = SDB.UI.NewButton(Form1)
  Button1.Caption = ".."
  Button1.Common.SetRect 378,32,21,21
  Button1.UseScript = Script.ScriptPath
  Button1.OnClickFunc = "FilenameClick"
  
  Dim Label8 : Set Label8 = SDB.UI.NewLabel(Form1)
  Label8.Common.SetRect 5,60,65,17
  Label8.Caption = "Title:"

  Dim Edit4 : Set Edit4 = SDB.UI.NewEdit(Form1)
  Edit4.Common.SetRect 60,57,339,21  
  Edit4.Text = SDB.IniFile.StringValue("MVNfoGenerator","Title")
  Edit4.Common.ControlName = "Title"  

  Dim Label3 : Set Label3 = SDB.UI.NewLabel(Form1)
  Label3.Common.SetRect 5,87,65,17
  Label3.Caption = "COLUMNS"
  
  Dim Label4 : Set Label4 = SDB.UI.NewLabel(Form1)
  Label4.Common.SetRect 129,87,65,17
  Label4.Caption = "Order"

  Dim Label5 : Set Label5 = SDB.UI.NewLabel(Form1)
  Label5.Common.SetRect 171,87,65,17
  Label5.Caption = "Heading"

  Dim Label6 : Set Label6 = SDB.UI.NewLabel(Form1)
  Label6.Common.SetRect 275,87,65,17
  Label6.Caption = "Format"
  
  Dim Label9 : Set Label9 = SDB.UI.NewLabel(Form1)
  Label9.Common.SetRect 378,87,65,17
  Label9.Caption = "Sum"      

  'load columns
  Dim i : i = 0
  Dim c : c = SDB.IniFile.IntValue("MVNfoGenerator","Columns")
  Dim y : y = SDB.IniFile.StringValue("MVNfoGenerator","Summary")
  For i = 1 To c
    Dim h : h = 107+((i-1)*25)
    Dim s : s = SDB.IniFile.StringValue("MVNfoGenerator","Column"&i)
    Dim a : a = Split(s,":|:")
    
    Dim DropDown2 : Set DropDown2 = SDB.UI.NewDropDown(Form1)
    DropDown2.Common.SetRect 5,h,120,21
    Call AddColumns(DropDown2)
    DropDown2.Style = 2
    DropDown2.ItemIndex = a(1)
    DropDown2.Common.ControlName = "Column"&i
    
    Dim Edit2 : Set Edit2 = SDB.UI.NewEdit(Form1)
    Edit2.Common.SetRect 171,h,100,21
    Edit2.Text = a(2)
    Edit2.Common.ControlName = "Heading"&i
    
    Dim SpinEdit1 : Set SpinEdit1 = SDB.UI.NewSpinEdit(Form1)
    SpinEdit1.Common.SetRect 129,h,38,21  
    SpinEdit1.MinValue = 0
    SpinEdit1.MaxValue = ColMax    
    SpinEdit1.Value = a(0)
    SpinEdit1.Common.ControlName = "Order"&i

    Dim Edit3 : Set Edit3 = SDB.UI.NewEdit(Form1)
    Edit3.Common.SetRect 275,h,100,21
    Edit3.Text = a(3)
    Edit3.Common.Hint = FormatHint
    Edit3.Common.ControlName = "Format"&i
    
    Dim Check3 : Set Check3 = SDB.UI.NewCheckbox(Form1)
    Check3.Common.SetRect 378,h,21,21
    Check3.Common.ControlName = "Summary"&i
    If Mid(y,i,1) = "Y" Then
      Check3.Checked = True
    Else
      Check3.Checked = False
    End If  
    
    Dim Button3 : Set Button3 = SDB.UI.NewButton(Form1)
    Button3.Caption = "-"
    Button3.UseScript = Script.ScriptPath
    Button3.OnClickFunc = "RemoveClick"
    Button3.Common.SetRect 399,h,21,21
    Button3.Common.ControlName = "Remove"&i
  Next
  
  'new column
  Dim Button2 : Set Button2 = SDB.UI.NewButton(Form1)
  Button2.Caption = "+"
  Button2.UseScript = Script.ScriptPath
  Button2.OnClickFunc = "ColumnClick"
  Button2.Common.SetRect 5,107+(c*25),21,21
  Button2.Common.ControlName = "Button"&(c+1)
  If c < ColMax Then
    Button2.Common.Visible = True
  Else
    Button2.Common.Visible = False
  End If
  
  'buttons
  Dim Button4 : Set Button4 = SDB.UI.NewButton(Form1)
  Button4.Caption = "&Cancel"
  Button4.Cancel = True
  Button4.ModalResult = 2
  Button4.Common.Width = 60
  Button4.Common.Left = Form1.Common.Width - Button4.Common.Width - 20
  Button4.Common.Top = Form1.Common.Height - 58
  
  Dim Button5 : Set Button5 = SDB.UI.NewButton(Form1)
  Button5.Caption = "&Ok"
  Button5.Default = True
  Button5.ModalResult = 1
  Button5.Common.Width = 80
  Button5.Common.Left = Button4.Common.Left - Button5.Common.Width - 5
  Button5.Common.Top = Button4.Common.Top
  
  Dim Button6 : Set Button6 = SDB.UI.NewButton(Form1)
  Button6.Caption = "&Load"
  Button6.Common.Width = 60
  Button6.Common.Left = Button5.Common.Left - Button6.Common.Width - 5
  Button6.Common.Top = Button5.Common.Top
  Button6.UseScript = Script.ScriptPath
  Button6.OnClickFunc = "LoadSettings"
  
  Dim Button7 : Set Button7 = SDB.UI.NewButton(Form1)
  Button7.Caption = "&Save"
  Button7.Common.Width = 60
  Button7.Common.Left = Button6.Common.Left - Button7.Common.Width - 5
  Button7.Common.Top = Button6.Common.Top  
  Button7.UseScript = Script.ScriptPath
  Button7.OnClickFunc = "SaveSettings"

  '*******************************************************************'
  '* End of form                              Richard Lewis (c) 2007 *'
  '*******************************************************************'
  
  'default delimiters
  Dim del1,del2,del3
  If SDB.IniFile.StringValue("MVNfoGenerator","Delim1") = "" Then
    SDB.IniFile.StringValue("MVNfoGenerator","Delim1") = "�"
  End If
  If SDB.IniFile.StringValue("MVNfoGenerator","Delim2") = "" Then
    SDB.IniFile.StringValue("MVNfoGenerator","Delim2") = "�,�"
  End If
  If SDB.IniFile.StringValue("MVNfoGenerator","Delim3") = "" Then
    SDB.IniFile.StringValue("MVNfoGenerator","Delim3") = "�"
  End If  
  
  'show form
  If Not (Form1.ShowModal = 1) Then
    Exit Sub
  End If
  
  'create logfile
  If Debug Then
    Call clear()
    Call out(AppTitle)
  End If
  
  'save source
  Dim o : Set o = Form1.Common.ChildControl("Source")
  Dim Source : Source = o.ItemIndex
  SDB.IniFile.IntValue("MVNfoGenerator","Source") = Source  
  If Debug Then Call out("Source="&Source)
  
  'save format
  Set o = Form1.Common.ChildControl("Format")
  If o Is Nothing Then
    Call SDB.MessageBox("CustomReport: Format setting could not be saved.",mtError,Array(mbOk))
    Exit Sub
  End If
  Dim Format : Format = o.ItemIndex
  SDB.IniFile.IntValue("MVNfoGenerator","Format") = Format
  If Debug Then Call out("Format="&Format)
  
  'save unicode
  Set o = Form1.Common.ChildControl("Unicode")
  Dim Unicode : Unicode = o.Checked
  SDB.IniFile.BoolValue("MVNfoGenerator","Unicode") = Unicode
  If Debug Then Call out("Unicode="&Unicode)
  
  'save backcover
  Set o = Form1.Common.ChildControl("BackCover")
  Dim BackCover : BackCover = o.Checked
  SDB.IniFile.BoolValue("MVNfoGenerator","BackCover") = BackCover
  If Debug Then Call out("BackCover="&BackCover)    
    
  'save filename
  Set o = Form1.Common.ChildControl("Filename")
  If o Is Nothing Then
    Call SDB.MessageBox("MV nfo generator: Filename setting could not be saved.",mtError,Array(mbOk))
    If Debug Then Call out("Filename=Nothing")
    Exit Sub
  End If
  If o.Text = "" Then
    Call SDB.MessageBox("MV nfo generator: Filename has not been specified.",mtError,Array(mbOk))
    If Debug Then Call out("Filename=")
    Exit Sub
  End If  
  Dim Filename : Filename = upmask(o.Text)
  If InStr(Filename,"\") = 0 Then
    Dim wsh : Set wsh = CreateObject("WScript.Shell")
    Dim tmp : tmp = wsh.ExpandEnvironmentStrings("%TEMP%")
    If Right(tmp,1) = "\" Then
      Filename = tmp&Filename
    Else
      Filename = tmp&"\"&Filename
    End If
  End If
  Dim ext : ext = ""
  Select Case DropDown1.ItemIndex
    Case 0 'CSV
      ext = ".csv"
      del1 = GetDelim(1)
      del2 = GetDelim(2)
      del3 = GetDelim(3)
    Case 1 'HTML
      ext = ".htm"
    Case 2 'XLS
      ext = ".xls"
    Case 3 'NFO
      ext = ".nfo"
    Case 4 'TXT
      ext = ".txt"
    Case 5 'CD Cover
      ext = ".htm"
    Case 6 'CD Tiled
      ext = ".htm"
    Case 7 'XLSX
      ext = ".xlsx"            
  End Select  
  If Not Right(Filename,Len(ext)) = ext Then
    If Right(Filename,1) = "\" Then
      Filename = Filename&"MVNfoGenerator"&ext
    Else
      Filename = Filename&"\MVNfoGenerator"&ext
    End If
  End If
  SDB.IniFile.StringValue("MVNfoGenerator","Filename") = Filename    
  If Debug Then Call out("Filename="&Filename)
  
  'save title
  Set o = Form1.Common.ChildControl("Title")
  Dim Title : Title = o.Text
  SDB.IniFile.StringValue("MVNfoGenerator","Title") = Title
  If Debug Then Call out("Title="&Title)  
    
  'save columns
  Dim dic : Set dic = CreateObject("Scripting.Dictionary")
  Dim ys : ys = ""
  i = 1
  c = 0
  Set o = Form1.Common.ChildControl("Column"&i)
  While Not (o Is Nothing)
    If o.ItemIndex > 0 Then
      Dim t : t = FixOrder(Form1.Common.ChildControl("Order"&i).Value)&":|:"&o.ItemIndex&":|:"&Form1.Common.ChildControl("Heading"&i).Text&":|:"&Form1.Common.ChildControl("Format"&i).Text
      dic.Item(t) = "column"
      If Form1.Common.ChildControl("Summary"&i).Checked Then 
        ys = ys&"Y"
      Else
        ys = ys&"N"
      End If
      c = c + 1
      SDB.IniFile.StringValue("MVNfoGenerator","Column"&c) = t
    End If
    i = i + 1  
    Set o = Form1.Common.ChildControl("Column"&i)
  WEnd
  SDB.IniFile.IntValue("MVNfoGenerator","Columns") = c
  If Debug Then Call out("Columns="&c)
  SDB.IniFile.StringValue("MVNfoGenerator","Summary") = ys
  If Debug Then Call out("Summary="&ys)

  Call CustomReportAuto()
End Sub
  
Sub CustomReportAuto()
  'get settings
  Dim Source : Source = SDB.IniFile.IntValue("MVNfoGenerator","Source")
  Dim Format : Format = SDB.IniFile.IntValue("MVNfoGenerator","Format")
  Dim Unicode : Unicode = SDB.IniFile.IntValue("MVNfoGenerator","Unicode")
  Dim BackCover : BackCover = SDB.IniFile.StringValue("MVNfoGenerator","BackCover")
  Dim Filename : Filename = SDB.IniFile.StringValue("MVNfoGenerator","Filename")
  Dim Title : Title = SDB.IniFile.StringValue("MVNfoGenerator","Title")
  Dim Summary : Summary = SDB.IniFile.StringValue("MVNfoGenerator","Summary")
  Dim del1 : del1 = GetDelim(1)
  Dim del2 : del2 = GetDelim(2)
  Dim del3 : del3 = GetDelim(3)
  Dim dic : Set dic = CreateObject("Scripting.Dictionary")
  Dim sum : Set sum = CreateObject("Scripting.Dictionary")  
  Dim i : i = 0
  Dim c : c = SDB.IniFile.IntValue("MVNfoGenerator","Columns")
  For i = 1 To c
    dic.Item(SDB.IniFile.StringValue("MVNfoGenerator","Column"&i)) = "column"
    sum.Item("#"&i) = 0
  Next  

  'check selection
  Dim list : Set list = SDB.CurrentSongList
  If list.Count = 0 Then
    Set list = SDB.AllVisibleSongList
  End If
  Select Case Source
    Case 0
      If list.Count = 0 Then
        Call SDB.MessageBox("MV nfo generator: There are no tracks selected.",mtError,Array(mbOk))
        Exit Sub
      End If          
    Case 1
      Dim itr : Set itr = SDB.Database.OpenSQL("SELECT Count(PlaylistName), Count(DISTINCT PlaylistName) FROM Playlists")
      If Not (itr.ValueByIndex(0) = itr.ValueByIndex(1)) Then
        Call SDB.MessageBox("MV nfo generator: There is a playlist name clash.",mtError,Array(mbOk))
        Exit Sub
      End If    
  End Select
  
  'create progress bar
  Dim p : Set p = SDB.Progress
  p.Value = 0
  p.Text = "MV nfo generator: Initialising..."
  SDB.ProcessMessages  
  Select Case Source
    Case 0
      p.MaxValue = list.Count
    Case 1
      p.MaxValue = SumTracks(True)
  End Select  
  If Debug Then Call out("Tracks="&p.MaxValue)  

  'sort columns
  Dim arr : arr = dic.Keys
  Dim boo : boo = False
  Dim tmp : tmp = ""
  If UBound(arr) > 0 Then
    Do
      boo = True
      For i = 0 To UBound(arr)-1
        If arr(i+1) < arr(i) Then
          boo = False
          tmp = arr(i)
          arr(i) = arr(i+1)
          arr(i+1) = tmp
        End If
      Next
    Loop Until boo
    If Debug Then Call out("(Columns sorted)")
  End If
  
  'generate report path  
  If InStr(Filename,"<") > 0 Then
    Dim dat : dat = Date
    Dim tim : tim = Time  
    Filename = Replace(Filename,"<Y>",lead2(Year(dat)))
    Filename = Replace(Filename,"<M>",lead2(Month(dat)))
    Filename = Replace(Filename,"<D>",lead2(Day(dat)))
    Filename = Replace(Filename,"<H>",lead2(Hour(tim)))
    Filename = Replace(Filename,"<N>",lead2(Minute(tim)))
    Filename = Replace(Filename,"<S>",lead2(Second(tim)))
    Filename = Replace(Filename,"<V>",SDB.VersionString)
    Filename = Replace(Filename,"<B>",SDB.VersionBuild)
  End If  
  If Debug Then Call out("Filename="&Filename)
  Dim fso : Set fso = CreateObject("Scripting.FileSystemObject")
  Dim str : str = Left(Filename,InStrRev(Filename,"\"))
  Call GeneratePath(fso,str)
  If Debug Then Call out("(Path generated)")  
 
  'create report
  Dim f,tar,ex,ws
  Call dic.RemoveAll()
  For i = 0 To UBound(arr)
    tar = Split(arr(i),":|:")
    dic.Item(CStr(i)) = tar(2)
  Next
  Dim bpx : bpx = Int(Pixels*1.25)
  Dim spx : spx = Int(Pixels*0.12)-1  
  Dim fpt : fpt = 8
  Dim tcp : tcp = 4
  If Format = 5 Or Format = 6 Then
    If p.MaxValue > 20 Then
      fpt = 7
      tcp = 3
      If p.MaxValue > 24 Then
        fpt = 6
        If p.MaxValue > 27 Then
          tcp = 2
          If p.MaxValue > 31 Then
            tcp = 1
            If p.MaxValue > 36 Then
              fpt = 5
            End If
          End If
        End If
      End If
    End If
  End If

  'loop through selected songs path is path file to write

  Dim k : k = 0
  Dim mylist : Set mylist = SDB.SelectedSongList

  For k = 0 To mylist.Count-1

    Dim myitm : Set myitm = mylist.Item(k)
    Dim path : path = Left(myitm.Path,InStrRev(myitm.Path,"."))&"nfo"
    Select Case Format
		Case 0 'CSV
		  Set f = fso.CreateTextFile(Filename,True,Unicode)
		  str = FixCSV(dic.Items,del1,del2,del3) 
		  If Not Unicode Then
			str = SDB.ToAscii(str)
		  End If      
		  Call f.WriteLine(str) 
		Case 1 'HTML 
		  Set f = fso.CreateTextFile(Filename,True,Unicode) 
		  If Title = "" Then
			Call f.WriteLine("<html><head><title>"&AppTitle&"</title><style type=""text/css"">")
		  Else
			Call f.WriteLine("<html><head><title>"&Title&"</title><style type=""text/css"">")
		  End If      
		  Call f.WriteLine("body{font-family:'Verdana',sans-serif; background-color:#FFFFFF; font-size:9pt; color:#000000;}")
		  Call f.WriteLine("H1{font-family:'Verdana',sans-serif; font-size:13pt; font-weight:bold; color:#AAAAAA; text-align:left}")
		  Call f.WriteLine("P{font-family:'Verdana',sans-serif; font-size:9pt; color:#000000;}")
		  Call f.WriteLine("TH{font-family:'Verdana',sans-serif; font-size:10pt; font-weight:bold; color:#000000; border-color:#000000; border-style: solid; border-left-width:0px; border-right-width:0px; border-top-width:0px; border-bottom-width:3px;}")
		  Call f.WriteLine("TD{font-family:'Verdana',sans-serif; font-size:9pt; color:#000000; border-color:#000000; border-style: solid; border-left-width:0px; border-right-width:0px; border-top-width:0px; border-bottom-width:1px;}")
		  Call f.WriteLine("</style></head><body>")
		  If Not (Title = "") Then
			Call f.WriteLine("<h1>"&MapXML(Title,False)&"</h1>")
		  End If
		  Call f.WriteLine("<table cellpadding=""4"" cellspacing=""0""><tr align=left><th>")
		  Call f.WriteLine(Replace(Join(dic.Items,"</th><th>"),"<th></th>","<th>&nbsp;</th>"))
		  Call f.WriteLine("</th></tr>")
		Case 2 'XLS
		  On Error Resume Next
		  Set ex = CreateObject("Excel.Application")
		  If Err.Number <> 0 Then
			Err.Clear      
			Call SDB.MessageBox("CustomReport: Excel could not be found.",mtError,Array(mbOk))
			Exit Sub
		  End If
		  On Error GoTo 0      
		  If fso.FileExists(Filename) Then
			Call fso.DeleteFile(Filename)
		  End If      
		  Set f = ex.WorkBooks.Add
		  Set ws = f.Sheets(1)
		  If Not (Title = "") Then
			ws.Name = Title
		  End If
		  tar = dic.Items
		  For i = 0 To UBound(tar)
			ws.Cells(1,i+1).Value = tar(i)
		  Next
		  ws.Rows("1:1").Font.Bold = True
		Case 3 'NFO
		  Set f = fso.CreateTextFile(path,True,Unicode)
		  Call f.WriteLine("<?xml version=""1.0"" encoding=""UTF-8"" standalone=""yes"" ?>")
	      'Call f.WriteLine("<musicvideo title="""&MapXML(Title,True)&""">")
		Case 4 'TXT
		  Set f = fso.CreateTextFile(Filename,True,Unicode)
		  If Not (Title = "") Then
			Call f.WriteLine(Title)
			Call f.WriteLine(BuildUnderline(Title))
		  End If
		  Call f.WriteLine(Join(dic.Items,Chr(9)))
		Case 5 'CD Cover
		  Set f = fso.CreateTextFile(Filename,True,Unicode) 
		  If Title = "" Then
			Call f.WriteLine("<html><head><title>"&AppTitle&"</title><style type=""text/css"">")
		  Else
			Call f.WriteLine("<html><head><title>"&Title&"</title><style type=""text/css"">")
		  End If
		  Call f.WriteLine("body{font-family:'Verdana',sans-serif; background-color:#FFFFFF; font-size:9pt; color:#000000;}")
		  Call f.WriteLine("H1{font-family:'Verdana',sans-serif; font-size:10pt; font-weight:bold; color:#AAAAAA; text-align:left; padding-left:"&tcp&"px;}")
		  Call f.WriteLine("TH{font-family:'Verdana',sans-serif; font-size:9pt; font-weight:bold; color:#000000; border:0px;}")
		  Call f.WriteLine("TD{font-family:'Verdana',sans-serif; font-size:"&fpt&"pt; color:#000000; border:0px;}")
		  Call f.WriteLine("div.box{width:"&(Pixels+1)&"px; height:"&(Pixels+1)&"px; border-width: 1px; border-style: solid;}")
		  If BackCover Then
			Call f.WriteLine("div.back{width:"&bpx&"px;height:"&(Pixels+1)&"px;border-width:1px;border-style:solid;float:left;overflow:hidden;}")
			Call f.WriteLine("div.sp-l{width:"&spx&"px;height:"&(Pixels+1)&"px;white-space:nowrap;float:left;-webkit-transform:translate(200px,195px) rotate(270deg);-moz-transform:translate(200px,195px) rotate(270deg);-o-transform:translate(200px,195px) rotate(270deg);}")
			Call f.WriteLine("div.sp-r{width:"&spx&"px;height:"&(Pixels+1)&"px;white-space:nowrap;float:right;-webkit-transform:translate(-200px,-195px) rotate(90deg);-moz-transform:translate(-200px,-195px) rotate(90deg);-o-transform:translate(-200px,-195px) rotate(90deg);writing-mode:tb-rl;}")
		  End If
		  Call f.WriteLine("</style></head><body><div style=""width:"&((Pixels+3)*2)&"px;height:"&(Pixels+1)&"px;""><div class=""box"" style=""float:left"">")
		  If Not (Title = "") Then
			Call f.WriteLine("<h1>"&MapXML(Title,False)&"</h1>")
		  End If
		  Call f.WriteLine("<table cellpadding="""&tcp&""" cellspacing=""0""><tr align=""left""><th>")
		  Call f.WriteLine(Replace(Join(dic.Items,"</th><th>"),"<th></th>","<th>&nbsp;</th>"))
		  Call f.WriteLine("</th></tr>")
		Case 6 'CD Tiled
		  Set f = fso.CreateTextFile(Filename,True,Unicode) 
		  If Title = "" Then
			Call f.WriteLine("<html><head><title>"&AppTitle&"</title><style type=""text/css"">")
		  Else
			Call f.WriteLine("<html><head><title>"&Title&"</title><style type=""text/css"">")
		  End If
		  Call f.WriteLine("body{font-family:'Verdana',sans-serif; background-color:#FFFFFF; font-size:9pt; color:#000000;}")
		  Call f.WriteLine("H1{font-family:'Verdana',sans-serif; font-size:10pt; font-weight:bold; color:#AAAAAA; text-align:left; padding-left:"&tcp&"px;}")
		  Call f.WriteLine("TH{font-family:'Verdana',sans-serif; font-size:9pt; font-weight:bold; color:#000000; border:0px;}")
		  Call f.WriteLine("TD{font-family:'Verdana',sans-serif; font-size:"&fpt&"pt; color:#000000; border:0px;}")
		  Call f.WriteLine("div.box{width:"&(Pixels+1)&"px; height:"&(Pixels+1)&"px; border-width: 1px; border-style: solid;}")
		  If BackCover Then
			Call f.WriteLine("div.back{width:"&bpx&"px;height:"&(Pixels+1)&"px;border-width:1px;border-style:solid;float:left;overflow:hidden}")
			Call f.WriteLine("div.sp-l{width:"&spx&"px;height:"&(Pixels+1)&"px;white-space:nowrap;float:left;-webkit-transform:translate(200px,195px) rotate(270deg);-moz-transform:translate(200px,195px) rotate(270deg);-o-transform:translate(200px,195px) rotate(270deg);}")
			Call f.WriteLine("div.sp-r{width:"&spx&"px;height:"&(Pixels+1)&"px;white-space:nowrap;float:right;-webkit-transform:translate(-200px,-195px) rotate(90deg);-moz-transform:translate(-200px,-195px) rotate(90deg);-o-transform:translate(-200px,-195px) rotate(90deg);writing-mode:tb-rl;}")        
		  End If      
		  Call f.WriteLine("</style></head><body><div style=""width:"&((Pixels+3)*2)&"px;height:"&(Pixels+1)&"px;""><div class=""box"" style=""float:left"">")
		  If Not (Title = "") Then
			Call f.WriteLine("<h1>"&MapXML(Title,False)&"</h1>")
		  End If
		  Call f.WriteLine("<table cellpadding="""&tcp&""" cellspacing=""0""><tr align=""left""><th>")
		  Call f.WriteLine(Replace(Join(dic.Items,"</th><th>"),"<th></th>","<th>&nbsp;</th>"))
		  Call f.WriteLine("</th></tr>") 
		Case 7 'XLSX
		  On Error Resume Next
		  Set ex = CreateObject("Excel.Application")
		  If Err.Number <> 0 Then
			Err.Clear      
			Call SDB.MessageBox("CustomReport: Excel could not be found.",mtError,Array(mbOk))
			Exit Sub
		  End If
		  On Error GoTo 0      
		  If fso.FileExists(Filename) Then
			Call fso.DeleteFile(Filename)
		  End If      
		  Set f = ex.WorkBooks.Add
		  Set ws = f.Sheets(1)
		  If Not (Title = "") Then
			ws.Name = Title
		  End If
		  tar = dic.Items
		  For i = 0 To UBound(tar)
			ws.Cells(1,i+1).Value = tar(i)
		  Next
		  ws.Rows("1:1").Font.Bold = True           
	  End Select
	  If Debug Then Call out("(Headers written)")
	  
	  'loop through playlists
	  Dim y : y = 1
	  Dim z : z = 0
	  Dim max : max = 0
	  Dim name : name = ""
	  Select Case Source
		Case 0
		  max = 1
		Case 1
		  max = SumPlaylists()
	  End Select
	  If Debug Then Call out("Playlists="&max)
	  For z = 0 To max-1
		If Source = 1 Then
		  c = z+1
		  name = ""
		  Call GetPlaylist(c,list,name)
		  Select Case Format
			Case 0 'CSV
			  str = FixCSV(name,del1,del2,del3) 
			  If Not Unicode Then
				str = SDB.ToAscii(str)
			  End If          
			  Call f.WriteLine(str) 
			Case 1 'HTML
			  Call f.WriteLine("<tr><td colspan=99><b>"&MapXML(name,False)&"</b></td></tr>")
			Case 2 'XLS
			  y = y+1
			  ws.Cells(y,1).Value = name
			Case 3 'NFO
			  Call f.WriteLine("  <Playlist title='"&MapXML(name,True)&"'>")
			Case 4 'TXT
			  If Not Unicode Then
				name = SDB.ToAscii(name)
			  End If      
			  Call f.WriteLine(name)
			Case 5 'CD Cover
			  Call f.WriteLine("<tr><td colspan=99><b>"&MapXML(name,False)&"</b></td></tr>")
			Case 6 'CD Tiled
			  Call f.WriteLine("<tr><td colspan=99><b>"&MapXML(name,False)&"</b></td></tr>")
			Case 7 'XLSX
			  y = y+1
			  ws.Cells(y,1).Value = name                    
		  End Select    
		Else
		  name = "(Selected tracks)"
		End If
		If Debug Then Call out("Playlist="&name)
	 
		'write tracks
		Dim src : src = ""
		Dim srs : Set srs = CreateObject("Scripting.Dictionary")
		If (Debug) And (list.Count = 0) Then
		  Call out("(No tracks)")
		End If
		Dim ico : ico = False
		If (Format = 1) Or (Format = 5) Or (Format = 6) Then
		  If InStr(Join(arr," "),":|:66:|:") > 0 Then
			ico = True
		  End If
		End If
        'check this	run For loop once only one track per file
		'For i = 0 To list.Count-1
		For i = 0 To 0
		  'Dim itm : Set itm = list.Item(i)
		  Dim itm : Set itm = mylist.Item(k)
		  Dim txt : txt = "Writing track "&(i+1)&"/"&(p.MaxValue)&" ("&itm.Title&")..."
		  If Debug Then Call out(txt)
		  p.Text = "CustomReport: "&txt
		  SDB.ProcessMessages
		  
		  'create image
		  If (Format = 5) And (src = "") Then 'CD Cover
			src = Left(Filename,InStrRev(Filename,"."))&"jpg"
			src = GetAlbumArt(itm,src,3)
			src = "file:///"&Replace(src,"\","/")
		  End If
		  If (Format = 6) Or (ico) Then 'CD Tiled or ArtworkIcon
			src = Left(Filename,InStrRev(Filename,".")-1)&i&".jpg"
			src = GetAlbumArt(itm,src,3)
			srs.Item("file:///"&Replace(src,"\","/")) = "#"&i
		  End If
		  
		  'process columns
		  Call dic.RemoveAll()
		  For c = 0 To UBound(arr)                
			'get tag
			tar = Split(arr(c),":|:")
			Dim tag : tag = Translate(tar(1))
			If (Format = 3) And (z = 0) And (i = 0) Then
			  If tar(2) = "" Then
				sum.Item("@"&(c+1)) = tag
			  Else
				sum.Item("@"&(c+1)) = tar(2)
			  End If
			End If  
			
			'get value      
			If CheckColumn(tar(1),Nothing) Then
			  Select Case tar(1)
				Case 50 'Filename
				  str = GetPart(2,itm.Path)
				Case 55 'Folder
				  str = GetPart(1,itm.Path)
				Case 56 'Extension
				  str = GetPart(3,itm.Path)
				Case 57 'ImageCount
				  If itm.AlbumArt Is Nothing Then
					str = "0"
				  Else
					str = CStr(itm.AlbumArt.Count)
				  End If
				Case 58 'ImageTypes
				  str = GetImageTypes(itm)
				Case 59 'TrackBackupIdent
				  str = GetIdentifier(itm.ID)
				Case 60 'AlbumComment
				  str = GetAlbum(1,itm.Album.ID)
				Case 61 'AlbumTracks
				  str = GetAlbum(2,itm.Album.ID)            
				Case 62 'Playlists
				  str = GetPlaylists(itm.ID)
				Case 63 'PlayedDates
				  str = GetPlayedDates(0,itm.ID)
				Case 64 'PlayedDateTimes
				  str = GetPlayedDates(1,itm.ID)
				Case 65 'ImageNames
				  str = GetImageNames(itm)
				Case 66 'ArtworkIcon
				  str = GetArtworkIcon(src,tar(3))
				Case 67 'Index
				  str = i + 1
				Case 68 'PlayedLength
				  str = GetPlayedLength(itm)
				Case 71 'OriginalDate
				  str = GetOriginalDate(itm)
				Case 74
				  str = GetTimeStr(itm.StartTime)
				Case 75 
				  str = GetTimeStr(itm.StopTime)
				Case 77
				  str = GetTrackType(itm.TrackType)
				'!
				Case Else
				  Execute("str = itm."&tag)      
			  End Select
			Else
			  str = ""
			End If
			
			'summary
			If Not (str = "") Then
			  If Mid(Summary,c+1,1) = "Y" Then
				Dim num : num = ParseNumeric(str)
				If num > 0 Then
				  Dim sid : sid = "#"&(c+1)
				  If sum.Exists(sid) Then
					sum.Item(sid) = sum.Item(sid)+num
				  Else
					sum.Item(sid) = num
				  End If
				  If InStr(str,":") > 0 Then
					sum.Item(":"&(c+1)) = 1
				  End If
				End If
			  End If
			End If
			
			'apply format
			On Error Resume Next
			Dim r : r = 0      
			Dim wdt : wdt = ""
			Dim lnk : lnk = ""
			Dim del : del = " "
			Dim htm : htm = False 
			Dim fmt : fmt = tar(3)
			If tar(1) = 66 Then
			  fmt = ""
			Else
			  If InStr("ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789\",UCase(Left(fmt,1))) = 0 Then
				del = Left(fmt,1)
				fmt = Mid(fmt,2)
			  End If
			End If 
			Dim par : par = Split(fmt,del)
			For r = 0 To UBound(par)
			  tmp = ""
			  Select Case UCase(Left(par(r),1))
				Case "A" 'add
				  tmp = str + Mid(par(r),2)
				Case "C" 'newline character
				  tmp = Replace(str,Vbcrlf,Mid(par(r),2))
				Case "D" 'divide
				  tmp = str / Mid(par(r),2)
				Case "E" 'extract
				  tmp = str
				  Dim et : et = Mid(par(r),2)
				  If Left(et,1) = "(" Then
					Dim ei : ei = InStr(et,")")       
					If ei > 1 Then
					  Dim ed : ed = " "                  
					  If ei > 2 Then
						ed = Mid(et,2,ei-2) 
					  End If
					  et = Mid(et,ei+1)
					  ei = Int(et)-1
					  Dim ea : ea = Split(str,ed)
					  If ei <= UBound(ea) Then
						tmp = ea(ei)
					  End If
					End If
				  End If
				Case "F" 'format date
				  Dim df : df = Mid(par(r),2)
				  If df = "" Then
					tmp = str  
				  Else
					tmp = FormatDate(str,df) 
				  End If             
				Case "H" 'hyperlink
				  lnk = Mid(par(r),2)
				  If lnk = "" Then
					lnk = str  
				  End If
				  tmp = BuildHyperlink(Format,lnk,str)
				  htm = True
				Case "I" 'hyperlink with mask
				  lnk = Mid(par(r),2)
				  If lnk = "" Then
					lnk = str
				  Else
					lnk = ProcessMask(itm,lnk)
				  End If
				  tmp = BuildHyperlink(Format,lnk,str)
				  htm = True
				Case "L" 'lowercase
				  tmp = LCase(str)            
				Case "M" 'multiply
				  tmp = str * Mid(par(r),2)
				Case "N" 'number
				  tmp = FormatNumber(str,Mid(par(r),2))            
				Case "P" 'prefix
				  tmp = Mid(par(r),2)&str            
				Case "R" 'replace
				  Dim ri : ri = InStr(par(r),"=")
				  If ri > 0 Then
					tmp = Replace(str,Left(Mid(par(r),2),ri-2),Mid(par(r),ri+1))
				  End If
				Case "S" 'suffix
				  tmp = str&Mid(par(r),2)            
				Case "T" 'title case
				  Dim ti : ti = 0
				  Dim ta : ta = Split(str," ")
				  For ti = 0 To UBound(ta)
					ta(ti) = UCase(Left(ta(ti),1))&LCase(Mid(ta(ti),2))
				  Next
				  tmp = Join(ta," ")
				Case "U" 'uppercase
				  tmp = UCase(str)
				Case "W" 'width
				  tmp = str            
				  wdt = " width="""&Mid(par(r),2)&""""
				Case "Z" 'leading zeros
				  If IsNumeric(Mid(par(r),2)) Then
					Dim zi : zi = Int(Mid(par(r),2))
					Dim zj : zj = InStr(str,".")
					Dim zs : zs = str
					Dim zt : zt = ""
					If zj > 0 Then
					  zs = Left(str,zj-1)
					  zt = Mid(str,zj)
					End If
					If (zi < 1) Then
					  If (zi = 0) And (zs = 0) And (zt <> "") Then
						zs = ""
					  End If
					Else
					  If zi > Len(zs) Then
						While (zi > Len(zs))
						  zs = "0"&zs
						WEnd
					  Else
						While (zi < Len(zs)) And (Left(zs,1) = "0")
						  zs = Mid(zs,2)
						WEnd
					  End If
					End If
					tmp = zs&zt
				  Else
					tmp = str
				  End If
				Case "\" 'traverse
				  tmp = str
				  If IsNumeric(Mid(par(r),2)) Then
					Dim si : si = Int(Mid(par(r),2))
					Dim sp : sp = InStr(tmp,"\")
					While si > 0 And sp > 0 
					  tmp = Mid(tmp,sp+1)
					  si = si - 1
					  sp = InStr(tmp,"\")
					WEnd
				  End If
			  End Select
			  If Err.Number = 0 Then
				str = tmp      
			  Else
				Err.Clear
				Exit For
			  End If
			Next
			On Error GoTo 0      
			
			'display value
			Select Case Format
			  Case 0 'CSV
				'nothing            
			  Case 1 'HTML
				If ico Or htm Then
				  str = "<td"&wdt&">"&str&"</td>"
				Else
				  str = "<td"&wdt&">"&MapXML(str,False)&"</td>"
				End If
			  Case 2 'XLS
				'nothing
			  Case 3 'NFO
				If tar(2) = "" Then
				  str = "<"&tag&">"&MapXML(str,True)&"</"&tag&">"
				Else
				  str = "<"&tar(2)&">"&MapXML(str,True)&"</"&tar(2)&">"
				End If
			  Case 4 'TXT
				'nothing
			  Case 5 'CD Cover
				If ico Or htm Then
				  str = "<td"&wdt&">"&str&"</td>"
				Else
				  str = "<td"&wdt&">"&MapXML(str,False)&"</td>"
				End If
			  Case 6 'CD Tiled
				If ico Or htm Then
				  str = "<td"&wdt&">"&str&"</td>"
				Else
				  str = "<td"&wdt&">"&MapXML(str,False)&"</td>"
				End If
			  Case 7 'XLSX
				'nothing                        
			End Select       
			dic.Item(CStr(c)) = str
		  Next      
		  Select Case Format
			Case 0 'CSV
			  str = FixCSV(dic.Items,del1,del2,del3) 
			  If Not Unicode Then
				str = SDB.ToAscii(str)
			  End If
			  Call f.WriteLine(str)
			Case 1 'HTML
			  Call f.WriteLine("<tr>"&Replace(Join(dic.Items,""),"<td></td>","<td>&nbsp;</td>")&"</tr>")
			Case 2 'XLS
			  tar = dic.Items
			  y = y+1
			  For c = 0 To UBound(tar)
				ws.Cells(y,c+1).Value = tar(c)
			  Next 
			Case 3 'NFO
			  str = ""
			  If Source = 1 Then
				str = "  "
			  End If
			  Call f.WriteLine(str&"  <musicvideo>")
			  Call f.WriteLine(str&"    "&Join(dic.Items,vbcrlf&"    "&str))
			  Call f.WriteLine(str&"  </musicvideo>")
			Case 4 'TXT
			  str = Join(dic.Items,Chr(9))
			  If Not Unicode Then
				str = SDB.ToAscii(str)
			  End If      
			  Call f.WriteLine(str)
			Case 5 'CD Cover
			  Call f.WriteLine("<tr>"&Replace(Join(dic.Items,""),"<td></td>","<td>&nbsp;</td>")&"</tr>")
			Case 6 'CD Tiled
			  Call f.WriteLine("<tr>"&Replace(Join(dic.Items,""),"<td></td>","<td>&nbsp;</td>")&"</tr>")
			Case 7 'XLSX
			  tar = dic.Items
			  y = y+1
			  For c = 0 To UBound(tar)
				ws.Cells(y,c+1).Value = tar(c)
			  Next                     
		  End Select    
		  p.Increase
		  If p.Terminate Then
			Exit For
		  End If
		Next
		
		If (Source = 1) And (Format = 3) Then
		  Call f.WriteLine("  </Playlist>")
		End If
	  Next
	  
	  'summary
	  If InStr(Summary,"Y") > 0 Then
		For i = 1 To Len(Summary)
		  If Mid(Summary,i,1) = "Y" Then
			If sum.Exists(":"&i) Then
			  z = sum.Item("#"&i)
			  sum.Item("#"&i) = MakeTimeStr(z)
			  Call sum.Remove(":"&i)
			End If
		  Else
			sum.Item("#"&i) = ""
		  End If
		Next    
		Select Case Format
		  Case 0 'CSV
			str = FixCSV(sum.Items,del1,del2,del3) 
			If Not Unicode Then
			  str = SDB.ToAscii(str)
			End If      
			Call f.WriteLine(str)
		  Case 1 'HTML
			Call f.WriteLine("<tr>"&Replace("<td><b>"&Join(sum.Items,"</b></td><td><b>")&"</b></td>","<b></b>","<b>&nbsp;</b>")&"</tr>")
		  Case 2 'XLS
			tar = sum.Items
			y = y+1
			For c = 0 To UBound(tar)
			  ws.Cells(y,c+1).Value = tar(c)
			Next 
		  Case 3 'NFO
			str = ""
			If Source = 1 Then
			  str = "  "
			End If
			Call f.WriteLine(str&"  <Summary>")
			tmp = "" 
			For i = 1 To Len(Summary)
			  If i > 1 Then
				tmp = tmp&vbcrlf&"    "&str
			  End If
			  tmp = tmp&"<"&sum.Item("@"&i)&">"&sum.Item("#"&i)&"</"&sum.Item("@"&i)&">"
			Next
			Call f.WriteLine(str&"    "&tmp)
			Call f.WriteLine(str&"  </Summary>")
		  Case 4 'TXT
			str = Join(sum.Items,Chr(9))
			If Not Unicode Then
			  str = SDB.ToAscii(str)
			End If      
			Call f.WriteLine(str)
		  Case 5 'CD Cover
			Call f.WriteLine("<tr>"&Replace("<td><b>"&Join(sum.Items,"</b></td><td><b>")&"</b></td>","<b></b>","<b>&nbsp;</b>")&"</tr>")
		  Case 6 'CD Tiled
			Call f.WriteLine("<tr>"&Replace("<td><b>"&Join(sum.Items,"</b></td><td><b>")&"</b></td>","<b></b>","<b>&nbsp;</b>")&"</tr>")
		  Case 7 'XLSX
			tar = sum.Items
			y = y+1
			For c = 0 To UBound(tar)
			  ws.Cells(y,c+1).Value = tar(c)
			Next                   
		End Select      
	  End If

	  'save file
	  Select Case Format
		Case 0 'CSV
		  Call f.Close()
		  str = ""
		Case 1 'HTML
		  Call f.WriteLine("</table></body></html>")  
		  Call f.Close()
		  str = ""
		Case 2 'XLS
		  If Not (p.Terminate) Then
			On Error Resume Next
			Call f.SaveAs(Filename,56)
			If Not (Err.Number = 0) Then
			  Err.Clear
			  Call f.SaveAs(Filename)
			End If
			On Error Goto 0           
		  End If
		  Call f.Close(False)
		  str = "excel.exe "
		Case 3 'NFO
	      'Call f.WriteLine("</CustomReport>")  
		  Call f.Close()
		  Dim adstreamUnicode, adstreamUtf8 , uniString, sepRegExp, revString
		  Set adstreamUnicode = CreateObject("ADODB.Stream")
		  Set adstreamUtf8 = CreateObject("ADODB.Stream")
		  Set sepRegExp = New RegExp
		  sepRegExp.Global = True
		  sepRegExp.Pattern = " ;(?!(\d\d\d|tou|pma|tg&|sop))"
		  adstreamUnicode.Type = 2
		  adstreamUnicode.Charset = "unicode"
		  adstreamUnicode.LineSeparator = -1
		  adstreamUnicode.Open
		  Call adstreamUnicode.LoadFromFile(path)
		  adstreamUnicode.Position = 0
		  adstreamUtf8.Type = 2
		  adstreamUtf8.Charset = "utf-8"
		  adstreamUtf8.LineSeparator = -1
		  adstreamUtf8.Open
		  Do Until adstreamUnicode.EOS
			uniString = adstreamUnicode.ReadText(-2)
			revString = strReverse(uniString)
			revString = sepRegExp.Replace(revString, " / ")
			uniString = strReverse(revString)
			adstreamUtf8.WriteText uniString, 1
		  Loop
		  adstreamUnicode.Close
		  Call adstreamUtf8.SaveToFile(path, 2)
		  adstreamUtf8.Close
		  Set adstreamUnicode = Nothing
		  Set adstreamUtf8 = Nothing
		  Set sepRegExp = Nothing
		  str = ""
		Case 4 'TXT
		  Call f.Close()
		  str = ""
		Case 5 'CD Cover
		  Call f.WriteLine("</table></div><div class=""box"" style=""float:right""><img src="""&src&""" width="""&(Pixels+1)&"px"" height="""&(Pixels+1)&"px""></div></div>")
		  If BackCover Then
			src = Left(Filename,InStrRev(Filename,".")-1)&"b.jpg"
			src = "file:///"&Replace(GetAlbumArt(itm,src,4),"\","/")
			Call f.WriteLine("<br style=""page-break-after:always;"" /><div class=""back""><div class=""sp-l"">")
			Call f.WriteLine("<b style=""zoom:1;filter:progid:DXImageTransform.Microsoft.BasicImage(rotation=3);"">")
			If Title = "" Then
			  Call f.WriteLine("&nbsp;")
			Else
			  Call f.WriteLine(Title)
			End If
			Call f.WriteLine("</b></div><div style=""float:left""><img src="""&src&""" height="""&(Pixels+1)&"px""></div><div class=""sp-r""><b>")
			If Title = "" Then
			  Call f.WriteLine("&nbsp;")
			Else
			  Call f.WriteLine(Title)
			End If
			Call f.WriteLine("</b></div></div>")
		  End If
		  Call f.WriteLine("</body></html>")        
		  Call f.Close()
		  str = ""
		Case 6 'CD Tiled
		  Call f.WriteLine("</table></div><div class=""box"" style=""float:right"">")
		  c = Sqr(srs.Count)
		  If Not (Right(FormatNumber(c,2),2) = "00") Then
			c = Int(c)+1
		  End If
		  If c > 1 Then
			Pixels = (Pixels \ c)+1
		  End If
		  arr = srs.Keys
		  For i = 0 To UBound(arr)                                                                      
			Call f.Write("<img src="""&arr(i)&""" width="""&Pixels&"px"" height="""&Pixels&"px"" style=""float:left"">")
		  Next
		  Call f.WriteLine("</div></div>")
		  If BackCover Then
			src = Left(Filename,InStrRev(Filename,".")-1)&"b.jpg"
			src = "file:///"&Replace(GetAlbumArt(itm,src,4),"\","/")
			Call f.WriteLine("<br style=""page-break-after:always;"" /><div class=""back""><div class=""sp-l"">")
			Call f.WriteLine("<b style=""zoom:1;filter:progid:DXImageTransform.Microsoft.BasicImage(rotation=3);"">")
			If Title = "" Then
			  Call f.WriteLine("&nbsp;")
			Else
			  Call f.WriteLine(Title)
			End If
			Call f.WriteLine("</b></div><div style=""float:left""><img src="""&src&""" height="""&(Pixels+1)&"px""></div><div class=""sp-r""><b>")
			If Title = "" Then
			  Call f.WriteLine("&nbsp;")
			Else
			  Call f.WriteLine(Title)
			End If
			Call f.WriteLine("</b></div></div>")
		  End If
		  Call f.WriteLine("</body></html>")      
		  Call f.Close()
		  str = ""      
		Case 7 'XLSX
		  If Not (p.Terminate) Then
			On Error Resume Next
			Call f.SaveAs(Filename,51)
			If Not (Err.Number = 0) Then
			  Err.Clear
			  Call f.SaveAs(Filename)
			End If
			On Error Goto 0              
		  End If
		  Call f.Close(False)
		  str = "excel.exe "      
	  End Select  
	  If Debug Then Call out("(File saved)")

    'my For next end
  Next  
  'finish off
  If p.Terminate Then
	p.Text = "MV nfo generator: Cancelled by user..."
	SDB.ProcessMessages
	If fso.FileExists(Filename) Then
	  Call fso.DeleteFile(Filename)
	End If
	If Debug Then Call out("(Cancelled by user)")
  Else 
	p.Text = "MV nfo generator: Awaiting user confirmation..."
	SDB.ProcessMessages  
	If SDB.MessageBox("MV nfo generator: Report complete, display now?",mtConfirmation,Array(mbYes,mbNo)) = mrYes Then
	  Dim wsh : Set wsh = CreateObject("WScript.Shell")
	  Call wsh.Run(str&Chr(34)&Filename&Chr(34),1,0)
	End If
  End If
End Sub

Function ProcessMask(itm,txt)
  Dim tags : tags = "ABCEFGJKLMOPRSTUVWY"
  Dim tagz : tagz = "ABCDEFGHIJKLMNO"
  Dim tag : tag = ""
  While ((InStr(txt,"%") > 0) And (Len(tags) > 0))
    tag = "%"&Left(tags,1)
    tags = Mid(tags,2)
    If InStr(txt,tag) > 0 Then
      txt = Replace(txt,tag,TranslateTag(itm,tag))
    End If
  WEnd
  While ((InStr(txt,"%") > 0) And (Len(tagz) > 0))
    tag = "%Z"&Left(tagz,1)
    tagz = Mid(tagz,2)
    If InStr(txt,tag) > 0 Then
      txt = Replace(txt,tag,TranslateTag(itm,tag))
    End If
  WEnd
  ProcessMask = txt
End Function

Function TranslateTag(itm,tag)
  Select Case tag
    Case "%A"
      TranslateTag = itm.ArtistName
    Case "%B"
      TranslateTag = itm.Bitrate      
    Case "%C"
      TranslateTag = itm.Author
    'D = <Auto Number>
    Case "%E"
      TranslateTag = GetPart(3,itm.Path)
    Case "%F"
      TranslateTag = GetPart(2,itm.Path)
    Case "%G"
      TranslateTag = itm.Genre    
    'H = <Track Length>
    'I = <Playback Time>
    Case "%J"
      TranslateTag = itm.Custom4
    Case "%K"
      TranslateTag = itm.Custom5    
    Case "%L"
      TranslateTag = itm.AlbumName
    Case "%M"
      TranslateTag = itm.BPM
    'N = <Random>
    Case "%O"
      TranslateTag = itm.Path    
    Case "%P"
      TranslateTag = GetPart(1,itm.Path)
    'Q = <Playlist>
    Case "%R"
      TranslateTag = itm.AlbumArtistName    
    Case "%S"
      TranslateTag = itm.Title
    Case "%T"
      TranslateTag = itm.TrackOrderStr
    Case "%U"
      TranslateTag = itm.Custom1
    Case "%V"
      TranslateTag = itm.Custom2
    Case "%W"
      TranslateTag = itm.Custom3     
    'X = <Skip>
    Case "%Y"
      TranslateTag = itm.Year
      If TranslateTag = "0" Then
        TranslateTag = ""
      End If
    Case "%ZA"
      TranslateTag = itm.Mood
    Case "%ZB"
      TranslateTag = itm.Occasion
    Case "%ZC"
      TranslateTag = itm.Tempo
    Case "%ZD"
      TranslateTag = itm.Comment
    Case "%ZE"
      TranslateTag = itm.Encoder
    Case "%ZF"
      TranslateTag = itm.ISRC
    Case "%ZG"
      TranslateTag = itm.Lyricist
    Case "%ZH"
      TranslateTag = itm.OriginalArtist
    Case "%ZI"
      TranslateTag = itm.OriginalLyricist
    Case "%ZJ"
      TranslateTag = itm.OriginalTitle
    Case "%ZK"
      TranslateTag = itm.Publisher
    Case "%ZL"
      TranslateTag = itm.Quality
    Case "%ZM"
      TranslateTag = itm.DiscNumberStr
    Case "%ZN"
      TranslateTag = itm.MusicComposer
    Case "%ZO"
      TranslateTag = itm.Grouping
    Case Else
      TranslateTag = ""
  End Select 
End Function

Sub FormatSelect(Control)
  Dim btn : Set btn = Control.Common.TopParent.Common.ChildControl("Delimiter")
  If Control.ItemIndex = 0 Then
    btn.Common.Visible = True
  Else
    btn.Common.Visible = False
  End If

  Dim edt : Set edt = Control.Common.TopParent.Common.ChildControl("FileName")
  If edt Is Nothing Then
    Exit Sub
  End If
  If edt.Text = "" Then
    Exit Sub
  End If
  
  Dim chk : Set chk = Control.Common.TopParent.Common.ChildControl("BackCover")
  If Control.ItemIndex = 5 Or Control.ItemIndex = 6 Then
    chk.Common.Visible = True
  Else
    chk.Common.Visible = False
  End If  
  
  Dim pos : pos = InStrRev(edt.Text,".")
  If pos > 0 Then
    Dim nam : nam = Left(edt.Text,pos)
    Select Case Control.ItemIndex
      Case 0 'CSV
        edt.Text = nam&"csv"
      Case 1 'HTML
        edt.Text = nam&"htm"
      Case 2 'XLS
        edt.Text = nam&"xls"
      Case 3 'NFO
        edt.Text = nam&"nfo"
      Case 4 'TXT
        edt.Text = nam&"txt"
      Case 5 'CD Cover
        edt.Text = nam&"htm"
      Case 6 'CD Tiled
        edt.Text = nam&"htm"
      Case 7 'XLSX
        edt.Text = nam&"xlsx"                
    End Select
  End If
End Sub

Sub AddColumns(Control)
  Dim i : i = 0
  For i = 0 To 77 '!
    If CheckColumn(i,Control) Then
      Control.AddItem(Translate(i))
    Else
      Control.AddItem("--N/A--")
    End If
  Next
End Sub

Function CheckColumn(i,o)
  CheckColumn = True
  Select Case i
    Case 59
      Dim c : c = SDB.Database.OpenSQL("SELECT Count(*) FROM (SELECT * FROM sqlite_master UNION ALL SELECT * FROM sqlite_temp_master) WHERE type='table' AND tbl_name='TrackBackup' ORDER BY 1").ValueByIndex(0)
      If c = 0 Then
        CheckColumn = False
      End If
    Case 66
      Dim f : f = 0
      If o Is Nothing Then
        f = SDB.IniFile.IntValue("MVNfoGenerator","Format")
      Else
        f = o.Common.TopParent.Common.ChildControl("Format").ItemIndex
      End If
      If f <> 1 And f <> 5 And f <> 6 Then
        CheckColumn = False
      End If
    Case 74
      If SDB.VersionHi < 4 Then
        CheckColumn = False
      End If
    Case 75
      If SDB.VersionHi < 4 Then
        CheckColumn = False
      End If    
    Case 76
      If SDB.VersionHi < 4 Then
        CheckColumn = False
      End If    
    Case 77
      If SDB.VersionHi < 4 Then
        CheckColumn = False
      End If    
  End Select
End Function

Function Translate(i)
  Select Case Int(i)
    Case 1
      Translate = "AlbumArtistName"
    Case 2
      Translate = "AlbumName"
    Case 3
      Translate = "ArtistName"
    Case 4
      Translate = "Author"
    Case 5
      Translate = "Band"
    Case 6
      Translate = "Bitrate"
    Case 7
      Translate = "BPM"
    Case 8
      Translate = "Comment"
    Case 9
      Translate = "Conductor"
    Case 10
      Translate = "Custom1"
    Case 11
      Translate = "Custom2"
    Case 12
      Translate = "Custom3"
    Case 13
      Translate = "DateAdded"
    Case 14
      Translate = "Encoder"
    Case 15
      Translate = "FileLength"
    Case 16
      Translate = "FileModified"
    Case 17
      Translate = "Genre"
    Case 18
      Translate = "Channels"
    Case 19
      Translate = "InvolvedPeople"
    Case 20
      Translate = "ISRC"
    Case 21
      Translate = "LastPlayed"
    Case 22
      Translate = "Lyricist"
    Case 23
      Translate = "Lyrics"
    Case 24
      Translate = "Mood"
    Case 25
      Translate = "MusicComposer"
    Case 26
      Translate = "Occasion"
    Case 27
      Translate = "OriginalArtist"
    Case 28
      Translate = "OriginalLyricist"
    Case 29
      Translate = "OriginalTitle"
    Case 30
      Translate = "OriginalYear"
    Case 31
      Translate = "Path"
    Case 32
      Translate = "PlayCounter"
    Case 33
      Translate = "Publisher"
    Case 34
      Translate = "Quality"
    Case 35
      Translate = "Rating"
    Case 36
      Translate = "RatingString"
    Case 37
      Translate = "SampleRate"
    Case 38
      Translate = "SongLength"
    Case 39
      Translate = "SongLengthString"
    Case 40
      Translate = "Tempo"
    Case 41
      Translate = "Title"  
    Case 42
      Translate = "TrackOrder"
    Case 43
      Translate = "VBR"
    Case 44
      Translate = "Year"
    Case 45 
      Translate = "Copyright"
    Case 46
      Translate = "Custom4"
    Case 47
      Translate = "Custom5" 
    Case 48
      Translate = "DiscNumber"
    Case 49
      Translate = "DiscNumberStr"
    Case 50
      Translate = "Filename"
    Case 51
      Translate = "Grouping"
    Case 52
      Translate = "ID"
    Case 53
      Translate = "PlaylistOrder"
    Case 54  
      Translate = "TrackOrderStr"
    Case 55
      Translate = "Folder"
    Case 56 
      Translate = "Extension"
    Case 57
      Translate = "ImageCount"
    Case 58
      Translate = "ImageTypes"
    Case 59
      Translate = "TrackBackupIdent"
    Case 60
      Translate = "AlbumComment"
    Case 61
      Translate = "AlbumTracks"      
    Case 62
      Translate = "Playlists"
    Case 63
      Translate = "PlayedDates"
    Case 64
      Translate = "PlayedDateTimes"
    Case 65 
      Translate = "ImageNames"
    Case 66
      Translate = "ArtworkIcon"
    Case 67
      Translate = "(Index)"
    Case 68
      Translate = "PlayedLength"
    Case 69
      Translate = "Day"
    Case 70
      Translate = "Month"
    Case 71
      Translate = "OriginalDate"
    Case 72
      Translate = "OriginalDay"
    Case 73
      Translate = "OriginalMonth"
    Case 74
      Translate = "StartTime"
    Case 75 
      Translate = "StopTime"
    Case 76
      Translate = "SkipCount"
    Case 77
      Translate = "TrackType"
    '!
    Case Else
      Translate = "(Nothing)"     
  End Select
End Function

Sub FilenameClick(Control)
  Dim o : Set o = Control.Common.TopParent.Common.ChildControl("Format")
  If o Is Nothing Then
    Exit Sub
  End If
  Dim e : Set e = Control.Common.TopParent.Common.ChildControl("FileName")
  If e Is Nothing Then
    Exit Sub
  End If  
  Dim d : Set d = SDB.CommonDialog
  Select Case o.ItemIndex
    Case 0 'CSV
      d.DefaultExt = ".csv"
      d.Filter = "Comma separated (*.csv)|*.csv|All files (*.*)|*.*"
    Case 1 'HTML
      d.DefaultExt = ".htm"
      d.Filter = "HTML (*.htm)|*.htm|All files (*.*)|*.*"
    Case 2 'XLS
      d.DefaultExt = ".xls"
      d.Filter = "Excel sheet (*.xls)|*.xls|All files (*.*)|*.*"
    Case 3 'NFO
      d.DefaultExt = ".nfo"
      d.Filter = "NFO (*.nfo)|*.nfo|All files (*.*)|*.*"
    Case 4 'TXT
      d.DefaultExt = ".txt"
      d.Filter = "Textfile (*.txt)|*.txt|All files (*.*)|*.*"      
    Case 5 'CD Cover
      d.DefaultExt = ".htm"
      d.Filter = "HTML (*.htm)|*.htm|All files (*.*)|*.*"      
    Case 6 'CD Tiled
      d.DefaultExt = ".htm"
      d.Filter = "HTML (*.htm)|*.htm|All files (*.*)|*.*"
    Case 7 'XLSX
      d.DefaultExt = ".xlsx"
      d.Filter = "Excel sheet (*.xlsx)|*.xlsx|All files (*.*)|*.*"                  
  End Select
  d.Flags = cdlOFNOverwritePrompt + cdlOFNHideReadOnly + cdlOFNNoChangeDir
  If InStr(e.Text,"\") > 0 Then
    d.InitDir = Left(e.Text,InStrRev(e.Text,"\"))
  Else
    d.InitDir = e.Text
  End If
  d.ShowSave
  If d.Ok Then
    e.Text = d.FileName
  End If
End Sub

Sub ColumnClick(Control)
  Dim s : s = Mid(Control.Common.ControlName,7)
  If IsNumeric(s) Then
    Dim Form1 : Set Form1 = Control.Common.TopParent
    Dim h : h = Control.Common.Top
    Dim i : i = Int(s)
    
    Dim DropDown2 : Set DropDown2 = SDB.UI.NewDropDown(Form1)
    DropDown2.Common.SetRect 5,h,120,21
    Call AddColumns(DropDown2)
    DropDown2.Style = 2
    DropDown2.ItemIndex = 0
    DropDown2.Common.ControlName = "Column"&i
    
    Dim Edit2 : Set Edit2 = SDB.UI.NewEdit(Form1)
    Edit2.Common.SetRect 171,h,100,21
    Edit2.Common.ControlName = "Heading"&i
    
    Dim SpinEdit1 : Set SpinEdit1 = SDB.UI.NewSpinEdit(Form1)
    SpinEdit1.Common.SetRect 129,h,38,21
    SpinEdit1.MinValue = 0
    SpinEdit1.MaxValue = ColMax
    If i = 1 Then
      SpinEdit1.Value = 1
    Else
      SpinEdit1.Value = Form1.Common.ChildControl("Order"&(i-1)).Value+1
    End If
    SpinEdit1.Common.ControlName = "Order"&i

    Dim Edit3 : Set Edit3 = SDB.UI.NewEdit(Form1)
    Edit3.Common.SetRect 275,h,100,21
    Edit3.Common.Hint = FormatHint
    Edit3.Common.ControlName = "Format"&i
    
    Dim Check3 : Set Check3 = SDB.UI.NewCheckbox(Form1)
    Check3.Common.SetRect 378,h,21,21
    Check3.Common.ControlName = "Summary"&i
    Check3.Checked = False  
    
    Dim Button3 : Set Button3 = SDB.UI.NewButton(Form1)
    Button3.Caption = "-"
    Button3.UseScript = Script.ScriptPath
    Button3.OnClickFunc = "RemoveClick"
    Button3.Common.SetRect 399,h,21,21
    Button3.Common.ControlName = "Remove"&i    

    Control.Common.ControlName = "Button"&(i+1)    
    If i < ColMax Then
      Control.Common.Top = h+25
    Else
      Control.Common.Visible = False
    End If    
  End If
End Sub

Sub RemoveClick(Control)
  Dim s : s = Mid(Control.Common.ControlName,7)
  If IsNumeric(s) Then
    Dim Form1 : Set Form1 = Control.Common.TopParent
    Dim h : h = Control.Common.Top
    Dim i : i = Int(s)
    Dim b : Set b = Form1.Common.ChildControl("Button"&(i+1))    
    If b Is Nothing Then
      Form1.Common.ChildControl("Column"&i).ItemIndex = 0
      Form1.Common.ChildControl("Heading"&i).Text = ""
      Form1.Common.ChildControl("Format"&i).Text = ""
      Form1.Common.ChildControl("Summary"&i).Checked = False
    Else
      Control.Common.Visible = False
      Form1.Common.ChildControl("Column"&i).Common.Visible = False
      Form1.Common.ChildControl("Column"&i).Common.ControlName = "ColumnN"
      Form1.Common.ChildControl("Heading"&i).Common.Visible = False
      Form1.Common.ChildControl("Heading"&i).Common.ControlName = "HeadingN"
      Form1.Common.ChildControl("Order"&i).Common.Visible = False
      Form1.Common.ChildControl("Order"&i).Common.ControlName = "OrderN"
      Form1.Common.ChildControl("Format"&i).Common.Visible = False
      Form1.Common.ChildControl("Format"&i).Common.ControlName = "FormatN"
      Form1.Common.ChildControl("Summary"&i).Common.Visible = False
      Form1.Common.ChildControl("Summary"&i).Common.ControlName = "SummaryN"         
      b.Common.ControlName = "Button"&i
      If (i-1) < ColMax Then
        b.Common.Top = h
        b.Common.Visible = True
      Else
        b.Common.Visible = False
      End If    
    End If
  End If
End Sub

Function DelimiterClick(Control)
  Dim ini : Set ini = SDB.IniFile
  Dim del1 : del1 = GetDelim(1)
  del1 = SkinnedInputBox("First delimiter (before first value)","MVNfoGenerator",del1,"CustomReportDialog")
  ini.StringValue("MVNfoGenerator","Delim1") = Replace(del1,"""","�")
  Dim del2 : del2 = GetDelim(2)
  del2 = SkinnedInputBox("Middle delimiter (between values)","MVNfoGenerator",del2,"CustomReportDialog")
  ini.StringValue("MVNfoGenerator","Delim2") = Replace(del2,"""","�")
  Dim del3 : del3 = GetDelim(3)
  del3 = SkinnedInputBox("Last delimiter (after last value)","MVNfoGenerator",del3,"CustomReportDialog")
  ini.StringValue("MVNfoGenerator","Delim3") = Replace(del3,"""","�")
End Function

Function GetDelim(i)
  Dim del : del = SDB.IniFile.StringValue("MVNfoGenerator","Delim"&i)
  GetDelim = Replace(del,"�","""")
End Function

Function SetDelim(i,del)
  SDB.IniFile.StringValue("MVNfoGenerator","Delim"&i) = Replace(del,"""","�")
  SetDelim = True
End Function

Function SkinnedInputBox(Text, Caption, Input, PositionName)
   Dim Form, Label, Edt, btnOk, btnCancel, modalResult 

   ' Create the window to be shown 
   Set Form = SDB.UI.NewForm 
   Form.Common.SetRect 100, 100, 360, 130 
   Form.BorderStyle  = 2   ' Resizable 
   Form.FormPosition = 4   ' Screen Center 
   Form.SavePositionName = PositionName 
   Form.Caption = Caption 
      
   ' Create a button that closes the window 
   Set Label = SDB.UI.NewLabel(Form) 
   Label.Caption = Text 
   Label.Common.Left = 5 
   Label.Common.Top = 10 
     
   Set Edt = SDB.UI.NewEdit(Form) 
   Edt.Common.Left = Label.Common.Left 
   Edt.Common.Top = Label.Common.Top + Label.Common.Height + 5 
   Edt.Common.Width = Form.Common.Width - 20 
   Edt.Common.ControlName = "Edit1" 
   Edt.Common.Anchors = 1+2+4 'Left+Top+Right 
   Edt.Text = Input 
       
   ' Create a button that closes the window 
   Set BtnOk = SDB.UI.NewButton(Form) 
   BtnOk.Caption = "&OK" 
   BtnOk.Common.Top = Edt.Common.Top + Edt.Common.Height + 10 
   BtnOk.Common.Hint = "OK" 
   BtnOk.Common.Anchors = 4   ' Right 
   BtnOk.UseScript = Script.ScriptPath 
   BtnOk.Default = True
   BtnOk.ModalResult = 1 
    
   Set BtnCancel = SDB.UI.NewButton(Form) 
   BtnCancel.Caption = "&Cancel" 
   BtnCancel.Common.Left = Form.Common.Width - BtnCancel.Common.Width - 15 
   BtnOK.Common.Left = BtnCancel.Common.Left - BtnOK.Common.Width - 10 
   BtnCancel.Common.Top = BtnOK.Common.Top 
   BtnCancel.Common.Hint = "Cancel" 
   BtnCancel.Common.Anchors = 4   ' Right 
   BtnCancel.UseScript = Script.ScriptPath 
   BtnCancel.Cancel = True
   BtnCancel.ModalResult = 2 
       
   If Form.showModal = 1 Then
     SkinnedInputBox = Edt.Text
   Else
     SkinnedInputBox = ""
   End If  
End Function

Function MapXML(srcstring,apos)
  MapXML = srcstring
  MapXML = Replace(MapXML,"&","&amp;")
  MapXML = Replace(MapXML,"<","&lt;")
  MapXML = Replace(MapXML,">","&gt;")
  MapXML = Replace(MapXML,"""","&quot;")
  If apos Then
    MapXML = Replace(MapXML,"'","&apos;")
  Else
    MapXML = Replace(MapXML,VbCrLf,"<br />")
  End If
  Dim i : i = 1
  While i<=Len(MapXML)
    If (AscW(Mid(MapXML,i,1))>127) Then
      MapXML = Mid(MapXML,1,i-1)+"&#"+CStr(AscW(Mid(MapXML,i,1)))+";"+Mid(MapXML,i+1,Len(MapXML))
    End If
    i = i + 1
  WEnd
End Function

Function SumTracks(b)
  Dim i : i = 0
  Dim t : t = 0
  Dim list : Set list = SDB.PlaylistByTitle("")
  If Not (list Is Nothing) Then
    Dim kids : Set kids = list.ChildPlaylists
    For i = 0 To kids.Count-1
      t = t+SumTracks2(kids.Item(i),b)
    Next
  End If
  SumTracks = t
End Function

Function SumTracks2(list,b)
  SDB.ProcessMessages
  Dim i : i = 0
  Dim t : t = 0
  If Not (list Is Nothing) Then
    If list.isAutoPlaylist Then
      If b Then
        t = list.Tracks.Count
      End If
    Else
      t = list.Tracks.Count
    End If
    Dim kids : Set kids = list.ChildPlaylists
    For i = 0 To kids.Count-1
      t = t+SumTracks2(kids.Item(i),b)
    Next
  End If
  SumTracks2 = t
End Function

Function SumPlaylists
  Dim i : i = 0
  Dim t : t = 0
  Dim list : Set list = SDB.PlaylistByTitle("")
  If Not (list Is Nothing) Then
    Dim kids : Set kids = list.ChildPlaylists
    For i = 0 To kids.Count-1
      t = t+SumPlaylists2(kids.Item(i))
    Next
  End If
  SumPlaylists = t
End Function

Function SumPlaylists2(list)
  SDB.ProcessMessages
  Dim i : i = 0
  Dim t : t = 0
  If Not (list Is Nothing) Then
    t = 1
    Dim kids : Set kids = list.ChildPlaylists
    For i = 0 To kids.Count-1
      t = t+SumPlaylists2(kids.Item(i))
    Next
  End If
  SumPlaylists2 = t
End Function

Sub GetPlaylist(num,lst,nam)
  Dim list : Set list = SDB.PlaylistByTitle(nam)
  If Not (list Is Nothing) Then
    If num = 0 Then
      Set lst = list.Tracks
      nam = list.Title
    Else
      Dim i : i = 0
      Dim kids : Set kids = list.ChildPlaylists
      For i = 0 To kids.Count-1
        num = num-1
        nam = kids.Item(i).Title
        Call GetPlaylist(num,lst,nam)
        If num = 0 Then
          Exit For
        End If
      Next
    End If
  End If
End Sub

Sub Install()
  Dim inip : inip = SDB.ApplicationPath&"Scripts\Scripts.ini"
  Dim inif : Set inif = SDB.Tools.IniFileByPath(inip)
  If Not (inif Is Nothing) Then
    inif.StringValue("MVNfoGenerator","Filename") = "MV_nfo_generator.vbs"
    inif.StringValue("MVNfoGenerator","Procname") = "CustomReport"
    inif.StringValue("MVNfoGeneratorr","Order") = "61"
    inif.StringValue("MVNfoGenerator","DisplayName") = "MV nfo generator"
    inif.StringValue("MVNfoGenerator","Description") = "Create Kodi nfo file for Music videos"
    inif.StringValue("MVNfoGeneratorr","Language") = "VBScript"
    inif.StringValue("MVNfoGenerator","ScriptType") = "1"   
    SDB.RefreshScriptItems
  End If
End Sub

Sub clear()
  Dim wsh : Set wsh = CreateObject("WScript.Shell")
  Dim loc : loc = wsh.ExpandEnvironmentStrings("%TEMP%")
  If Right(loc,1) = "\" Then
    loc = loc&"MVNfoGenerator.log"
  Else
    loc = loc&"\MVNfoGenerator.log"
  End If
  Dim fso : Set fso = CreateObject("Scripting.FileSystemObject")
  Dim logf : Set logf = fso.CreateTextFile(loc,True)
  logf.Close
End Sub

Sub out(txt)
  Dim wsh : Set wsh = CreateObject("WScript.Shell")
  Dim loc : loc = wsh.ExpandEnvironmentStrings("%TEMP%")
  If Right(loc,1) = "\" Then
    loc = loc&"MVNfoGenerator.log"
  Else
    loc = loc&"\MVNfoGenerator.log"
  End If  
  Dim fso : Set fso = CreateObject("Scripting.FileSystemObject")
  Dim logf : Set logf = fso.OpenTextFile(loc,8,True)
  logf.WriteLine(SDB.ToAscii(txt))
  logf.Close
End Sub

Function GetAlbumArt(track,temp,itype)
  GetAlbumArt = ""
  Dim fso : Set fso = SDB.Tools.FileSystem
  Dim pics : Set pics = track.AlbumArt
  If Not (pics Is Nothing) Then
    If pics.Count > 0 Then      
      Dim i : i = 0
      Dim j : j = 0
      For i = 0 To pics.Count-1
        If pics.Item(i).ItemType = itype Then
          j = i
          Exit For  
        End If
      Next
      If pics.Item(j).ItemStorage = 0 Then
        If Not (temp = "") Then
          Dim img : Set img = pics.Item(j).Image
          If Not (img Is Nothing) Then
            Dim outimg : Set outimg = fso.CreateTextFile(temp,True)
            If Not (outimg Is Nothing) Then
              Call outimg.WriteData(img.ImageData,img.ImageDataLen)
              Call outimg.Close()
              GetAlbumArt = temp
            End If
          End If
        End If
      Else
        GetAlbumArt = pics.Item(j).PicturePath
      End If
    End If    
  End If
End Function

Function GetImageTypes(track)
  GetImageTypes = ""
  Dim pics : Set pics = track.AlbumArt
  If Not (pics Is Nothing) Then      
    Dim i : i = 0
    For i = 0 To pics.Count-1 
      If i > 0 Then
        GetImageTypes = GetImageTypes&", "
      End If
      Select Case pics.Item(i).ItemType
        Case 0 
          GetImageTypes = GetImageTypes&"Other"
        Case 1
          GetImageTypes = GetImageTypes&"File icon"
        Case 2 
          GetImageTypes = GetImageTypes&"Other file icon"
        Case 3 
          GetImageTypes = GetImageTypes&"Front cover"
        Case 4 
          GetImageTypes = GetImageTypes&"Back cover"
        Case 5 
          GetImageTypes = GetImageTypes&"Leaflet page"
        Case 6 
          GetImageTypes = GetImageTypes&"Media"
        Case 7 
          GetImageTypes = GetImageTypes&"Lead artist"
        Case 8 
          GetImageTypes = GetImageTypes&"Artist/performer"
        Case 9 
          GetImageTypes = GetImageTypes&"Conductor"
        Case 10
          GetImageTypes = GetImageTypes&"Band/orchestra"
        Case 11
          GetImageTypes = GetImageTypes&"Composer"
        Case 12
          GetImageTypes = GetImageTypes&"Lyricist/text writer"
        Case 13
          GetImageTypes = GetImageTypes&"Recording location"
        Case 14
          GetImageTypes = GetImageTypes&"During recording"
        Case 15
          GetImageTypes = GetImageTypes&"During performance"
        Case 16
          GetImageTypes = GetImageTypes&"Movie/video screen capture"
        Case 17 
          GetImageTypes = GetImageTypes&"A bright coloured fish"
        Case 18 
          GetImageTypes = GetImageTypes&"Illustration"
        Case 19 
          GetImageTypes = GetImageTypes&"Band/artist logotype"
        Case 20 
          GetImageTypes = GetImageTypes&"Publisher/studio logotype"
        Case Else
          GetImageTypes = GetImageTypes&"Unknown"
      End Select
      If pics.Item(i).ItemStorage = 0 Then
        GetImageTypes = GetImageTypes&" (tagged)"
      Else
        GetImageTypes = GetImageTypes&" (linked)"
      End If
    Next
  End If
End Function

Function GetIdentifier(id)
  GetIdentifier = ""
  Dim iter : Set iter = SDB.Database.OpenSQL("SELECT Identifier FROM TrackBackup WHERE ID="&id)
  If Not (iter.EOF) Then
    GetIdentifier = iter.StringByIndex(0)
  End If
End Function

Function GetAlbum(mode,id)
  GetAlbum = ""
  Dim sql : sql = ""
  Select Case mode
    Case 1
      sql = "SELECT Comment FROM Albums WHERE ID="&id
    Case 2
      sql = "SELECT Tracks FROM Albums WHERE ID="&id
    Case 3
      sql = "SELECT Year FROM Albums WHERE ID="&id
  End Select
  Dim iter : Set iter = SDB.Database.OpenSQL(sql)
  If Not (iter.EOF) Then
    Dim val : val = iter.StringByIndex(0)
    If Not IsNull(val) Then
      GetAlbum = val
    End If
  End If
End Function

Function GetPlaylists(id)
  GetPlaylists = ""
  Dim iter : Set iter = SDB.Database.OpenSQL("SELECT PlaylistName FROM Playlists,PlaylistSongs WHERE Playlists.IDPlaylist=PlaylistSongs.IDPlaylist AND PlaylistSongs.IDSong="&id)
  If Not (iter.EOF) Then
    GetPlaylists = iter.StringByIndex(0)
    iter.Next
    While Not (iter.EOF)
      GetPlaylists = GetPlaylists&"; "&iter.StringByIndex(0)
      iter.Next
    WEnd
  End If
End Function

Function GeneratePath(fso,pFolderPath)
  GeneratePath = False
  If Not fso.FolderExists(pFolderPath) Then
    If GeneratePath(fso,fso.GetParentFolderName(pFolderPath)) Then
      GeneratePath = True
      Call fso.CreateFolder(pFolderPath)
    End If
  Else
    GeneratePath = True
  End If
End Function

Sub SaveSettings(Control)
  Dim d : Set d = SDB.CommonDialog
  d.Title = Left(AppTitle,Len(AppTitle)-4)
  d.DefaultExt = ".dat"
  d.Filter = "Data file (*.dat)|*.dat|All files (*.*)|*.*"
  d.Flags = cdlOFNOverwritePrompt + cdlOFNHideReadOnly + cdlOFNNoChangeDir
  d.InitDir = SDB.IniFile.StringValue("MVNfoGenerator","LastInitDir")
  d.ShowSave
  If Not (d.Ok) Then  
    Exit Sub
  End If
  Dim i : i = InStrRev(d.FileName,"\")
  Dim n : n = Mid(d.FileName,i+1)
  Dim str : str = Left(d.FileName,i)
  SDB.IniFile.StringValue("MVNfoGenerator","LastInitDir") = str
  
  Dim fso : Set fso = CreateObject("Scripting.FileSystemObject")
  Call GeneratePath(fso,str)
  Dim f : Set f = fso.CreateTextFile(d.FileName,True,False) 
  Dim p : Set p = Control.Common.TopParent.Common    
  Call f.WriteLine("[CustomReport]")
  Call f.WriteLine("Source="&p.ChildControl("Source").ItemIndex)
  Call f.WriteLine("Format="&p.ChildControl("Format").ItemIndex)
  Call f.WriteLine("Unicode="&p.ChildControl("Unicode").Checked)
  Call f.WriteLine("Filename="&p.ChildControl("Filename").Text)
  Call f.WriteLine("Delimiter1="&GetDelim(1))
  Call f.WriteLine("Delimiter2="&GetDelim(2))
  Call f.WriteLine("Delimiter3="&GetDelim(3))
  Call f.WriteLine("BackCover="&p.ChildControl("BackCover").Checked)
  i = 1
  Dim c : c = 0
  Dim o : Set o = p.ChildControl("Column"&i)
  Dim ys : ys = ""
  While Not (o Is Nothing)
    If o.ItemIndex > 0 Then
      str = p.ChildControl("Order"&i).Value&":|:"&o.ItemIndex&":|:"&p.ChildControl("Heading"&i).Text&":|:"&p.ChildControl("Format"&i).Text
      If p.ChildControl("Summary"&i).Checked Then
        ys = ys&"Y"
      Else
        ys = ys&"N"
      End If
      c = c + 1
      Call f.WriteLine("Column"&c&"="&str)
    End If
    i = i + 1  
    Set o = p.ChildControl("Column"&i)
  WEnd
  Call f.WriteLine("Columns="&c)
  Call f.WriteLine("Summary="&ys)
  Call f.Close()
  Call SDB.MessageBox("CustomReport: Settings saved to '"&n&"'.",mtInformation,Array(mbOk))
End Sub

Sub LoadSettings(Control)
  Dim d : Set d = SDB.CommonDialog
  d.Title = Left(AppTitle,Len(AppTitle)-4)
  d.DefaultExt = ".dat"
  d.Filter = "Data file (*.dat)|*.dat|All files (*.*)|*.*"
  d.Flags = cdlOFNOverwritePrompt + cdlOFNHideReadOnly + cdlOFNNoChangeDir
  d.InitDir = SDB.IniFile.StringValue("MVNfoGenerator","LastInitDir")
  d.ShowOpen
  If Not (d.Ok) Then
    Exit Sub
  End If
  Dim n : n = Mid(d.FileName,InStrRev(d.FileName,"\")+1)
  Dim str : str = Left(d.FileName,InStrRev(d.FileName,"\"))
  SDB.IniFile.StringValue("MVNfoGenerator","LastInitDir") = str
  
  Dim fso : Set fso = CreateObject("Scripting.FileSystemObject")
  Dim f : Set f = fso.OpenTextFile(d.FileName,1,False)
  If f.AtEndOfStream Then
    Call SDB.MessageBox("CustomReport: Settings could not be loaded from '"&n&"'.",mtError,Array(mbOk))
    Exit Sub
  End if  
  Dim s : s = Trim(f.ReadLine)
  If Not (s = "[CustomReport]") Then
    Call SDB.MessageBox("CustomReport: Settings could not be loaded from '"&n&"'.",mtError,Array(mbOk))
    Exit Sub
  End If

  Dim dic : Set dic = CreateObject("Scripting.Dictionary")
  Dim col : col = 0
  Dim ys : ys = ""
  Dim i : i = 0
  Dim p : Set p = Control.Common.TopParent.Common  
  Do While Not f.AtEndOfStream
    s = Trim(f.ReadLine)  
    i = InStr(s,"=")
    If i > 6 Then
      Dim c : c = Left(s,i-1)
      Dim v : v = Mid(s,i+1)
      If Left(c,7) = "Columns" Then
        col = Int(v)
      Else
        Select Case Left(c,6)
          Case "Column"
            dic.Item(c) = v
          Case "Source"
            If IsNumeric(v) Then
              p.ChildControl(c).ItemIndex = Int(v)
            End If
          Case "Format"
            If IsNumeric(v) Then
              p.ChildControl(c).ItemIndex = Int(v)
            End If            
          Case "Unicod"
            If UCase(v) = "TRUE" Then
              p.ChildControl(c).Checked = True
            Else
              p.ChildControl(c).Checked = False
            End If            
          Case "Filena"
            p.ChildControl(c).Text = v
          Case "Delimi"
            Call SetDelim(Int(Mid(c,10,1)),v)
          Case "Summar"
            ys = v
        End Select
      End If
    End If
  Loop
  If Not (col = dic.Count) Or (col > ColMax) Then
    Call SDB.MessageBox("CustomReport: Columns could not be loaded from '"&n&"'.",mtError,Array(mbOk))
    Exit Sub
  End if  
  
  Dim Form1 : Set Form1 = Control.Common.TopParent
  Dim b : b = ColMax+1
  For i = 1 To col
    Dim h : h = 82+((i-1)*25)
    Dim a : a = Split(dic.Item("Column"&i),":|:")
    Dim o : Set o = p.ChildControl("Column"&i)
    If o Is Nothing Then
      Set o = SDB.UI.NewDropDown(Form1)
      o.Common.SetRect 5,h,120,21
      Call AddColumns(o)
      o.Style = 2
      o.Common.ControlName = "Column"&i
    End If
    o.ItemIndex = a(1)    
    Set o = p.ChildControl("Heading"&i)
    If o Is Nothing Then
      Set o = SDB.UI.NewEdit(Form1)
      o.Common.SetRect 171,h,100,21
      o.Common.ControlName = "Heading"&i
    End If
    o.Text = a(2)    
    Set o = p.ChildControl("Order"&i)
    If o Is Nothing Then
      Set o = SDB.UI.NewSpinEdit(Form1)
      o.Common.SetRect 129,h,38,21  
      o.MinValue = 0
      o.MaxValue = ColMax    
      o.Common.ControlName = "Order"&i
    End If
    o.Value = a(0)
    Set o = p.ChildControl("Format"&i)
    If o Is Nothing Then
      Set o = SDB.UI.NewEdit(Form1)
      o.Common.SetRect 275,h,100,21
      o.Common.Hint = FormatHint
      o.Common.ControlName = "Format"&i
    End If
    o.Text = a(3)    
    Set o = p.ChildControl("Summary"&i)
    If o Is Nothing Then
      Set o = SDB.UI.NewCheckbox(Form1)
      o.Common.SetRect 278,h,21,21
      o.Common.ControlName = "Summary"&i
    End If
    If Mid(ys,i,1) = "Y" Then
      o.Checked = True
    Else
      o.Checked = False
    End If    
    Set o = p.ChildControl("Remove"&i)
    If o Is Nothing Then
      Set o = SDB.UI.NewButton(Form1)
      o.Caption = "-"
      o.UseScript = Script.ScriptPath
      o.OnClickFunc = "RemoveClick"
      o.Common.SetRect 399,h,21,21
      o.Common.ControlName = "Remove"&i
    End If
    Set o = p.ChildControl("Button"&i)
    If Not (o Is Nothing) Then
      b = i
    End If
  Next
  
  For i = col+1 To ColMax
    Set o = p.ChildControl("Column"&i)
    If Not (o Is Nothing) Then
      o.Common.Visible = False
      o.Common.ControlName = "ColumnN"
    End If
    Set o = p.ChildControl("Heading"&i)
    If Not (o Is Nothing) Then
      o.Common.Visible = False
      o.Common.ControlName = "HeadingN"
    End If
    Set o = p.ChildControl("Order"&i)
    If Not (o Is Nothing) Then
      o.Common.Visible = False
      o.Common.ControlName = "OrderN"
    End If
    Set o = p.ChildControl("Format"&i)
    If Not (o Is Nothing) Then
      o.Common.Visible = False
      o.Common.ControlName = "FormatN"
    End If
    Set o = p.ChildControl("Summary"&i)
    If Not (o Is Nothing) Then
      o.Common.Visible = False
      o.Common.ControlName = "SummaryN"
    End If    
    Set o = p.ChildControl("Remove"&i)
    If Not (o Is Nothing) Then
      o.Common.Visible = False
      o.Common.ControlName = "RemoveN"
    End If    
    Set o = p.ChildControl("Button"&i)
    If Not (o Is Nothing) Then
      b = i
    End If    
  Next

  Set o = p.ChildControl("Button"&b)
  If Not (o Is Nothing) Then
    o.Common.ControlName = "Button"&(col+1)
    If col < ColMax Then
      o.Common.Top = 82+(col*25)
      o.Common.Visible = True
    Else
      o.Common.Visible = False
    End If
  End If
      
  Call SDB.MessageBox("CustomReport: Settings loaded from '"&n&"'.",mtInformation,Array(mbOk))
End Sub

Function GetPart(mode,path)
  GetPart = ""
  Dim p2 : p2 = InStrRev(path,"\")
  If p2 = 0 Then
    Exit Function
  End If
  If mode = 1 Then 'Folder
    Dim p1 : p1 = InStr(path,"\")
    If p1 < p2 Then
      GetPart = Mid(path,p1+1,p2-p1-1)
    End If
    Exit Function
  End If   
  Dim p3 : p3 = InStrRev(path,".")
  If mode = 2 Then 'Filename
    If p3 > p2 Then
      GetPart = Mid(path,p2+1,p3-p2-1)
    End If
    Exit Function
  End If
  If mode = 3 Then 'Extension
    If p3 > p2 Then
      GetPart = Mid(path,p3+1)
    End If
    Exit Function
  End If
End Function

Function FormatDate(str,fmt)
  Dim arr : arr = Split(fmt,"=")
  Dim dat : dat = Date
  If UBound(arr) > 0 Then
    dat = GetDateKnown(str,arr(0))
    fmt = arr(1)
  Else
    dat = GetDateGuess(str)
  End If
  Dim i : i = 0
  Dim t : t = ""
  For i = 1 To Len(fmt)
    Dim c : c = Mid(fmt,i,1)
    Select Case c
      Case "d"
        t = Day(dat)
        If t < 10 Then
          FormatDate = FormatDate&"0"&t
        Else
          FormatDate = FormatDate&t
        End If
      Case "D"
        FormatDate = FormatDate&WeekDayName(WeekDay(dat),1)
      Case "j"
        FormatDate = FormatDate&Day(dat)
      Case "l"
        FormatDate = FormatDate&WeekDayName(WeekDay(dat))     
      Case "N"
        t = WeekDay(dat)-1
        If t = 0 Then
          FormatDate = FormatDate&"7"
        Else
          FormatDate = FormatDate&t
        End If
      Case "S"
        Select Case Int(Day(dat))
          Case 1,21,31
            FormatDate = FormatDate&"st"
          Case 2,22
            FormatDate = FormatDate&"nd"
          Case 3,23
            FormatDate = FormatDate&"rd"
          Case Else
            FormatDate = FormatDate&"th"
        End Select    
      Case "w"
        FormatDate = FormatDate&(WeekDay(dat)-1)      
      Case "z"
        FormatDate = FormatDate&DatePart("Y",dat)
      Case "W"
        FormatDate = FormatDate&DatePart("WW",dat)
      Case "F"
        FormatDate = FormatDate&MonthName(Month(dat))      
      Case "m"
        t = Month(dat)
        If t < 10 Then
          FormatDate = FormatDate&"0"&t
        Else
          FormatDate = FormatDate&t
        End If      
      Case "M"
        FormatDate = FormatDate&MonthName(Month(dat),1)      
      Case "n"
        FormatDate = FormatDate&Month(dat)      
      Case "t"
        Select Case Int(Month(dat)) 
          Case 4
            t = Int(Year(dat))
            If ((t Mod 4 = 0) And (t Mod 100 <> 0)) Or (t Mod 400 = 0) Then
              FormatDate = FormatDate&"29"
            Else
              FormatDate = FormatDate&"28"
            End If          
          Case 4,69,11
            FormatDate = FormatDate&"30"
          Case Else
            FormatDate = FormatDate&"31"
        End Select            
      Case "L"
        t = Int(Year(dat))
        If ((t Mod 4 = 0) And (t Mod 100 <> 0)) Or (t Mod 400 = 0) Then
          FormatDate = FormatDate&"1"
        Else
          FormatDate = FormatDate&"0"
        End If
      Case "o"
        FormatDate = FormatDate&Year(dat)            
      Case "Y"
        FormatDate = FormatDate&Year(dat)
      Case "y"
        FormatDate = FormatDate&Right(Year(dat),2)
      Case Else
        FormatDate = FormatDate&c
    End Select
  Next
End Function

Function GetDateGuess(str)
  Dim day : day = 0
  Dim mon : mon = 0
  Dim year : year = 0
  Dim mode : mode = 0
  Dim temp : temp = 0
  Dim nums : nums = "" 'mode=1
  Dim alps : alps = "" 'mode=2
  Dim i : i = 0
  For i = 1 To Len(str)
    Dim c : c = Mid(str,i,1)
    If InStr("0123456789",c) > 0 Then
      If (mode <> 1) And (nums <> "") Then
        nums = nums&","
      End If
      mode = 1
      nums = nums&c
    Else
      If InStr("abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ",c) > 0 Then
        If (mode <> 2) And (alps <> "") Then
          alps = alps&","
        End If
        mode = 2
        alps = alps&c
      Else     
        mode = 0
      End If
    End If
  Next 
  Dim arr : arr = Split(UCase(alps),",")
  For i = 0 To UBound(arr)
    Dim s : s = Left(arr(i),3)
    Dim t : t = InStr("JANFEBMARAPRMAYJUNJULAUGSEPOCTNOVDEC",s)-1
    If t > -1 And t/3 = t\3 Then  
      mon = (t/3)+1
      Exit For 
    End If
  Next   
  arr = Split(nums,",")
  i = 0
  Dim l : l = UBound(arr)+1 
  While (i < l And (day<1 Or mon<1 Or year<1))
    Dim j : j = Int(arr(i))
    If j > 31 Then
      year = j
    Else
      If j > 12 Or mon > 0 Then
        day = j
      Else
        If temp < 1 Then
          temp = j
        Else
          If temp = j Then
            day = j
            mon = j
          Else
            day = temp 
            mon = j
          End If
        End If  
      End If
    End If
    If temp > 0 And day > 0 Then
      mon = temp
      temp = 0
    End If
    If temp > 0 And mon > 0 Then
      day = temp
      temp = 0
    End If
    i = i + 1
  WEnd
  Dim cury : cury = DatePart("YYYY",Date)
  If year < 100 Then
    If year < (cury-2000) Then
      year = year + 2000
    Else
      year = year + 1900
    End If
  End If
  GetDateGuess = DateSerial(year,mon,day)
End Function

Function GetDateKnown(str,fmt)
  Dim day : day = 0
  Dim mon : mon = 0
  Dim year : year = 0 
  Dim i : i = 0
  Dim t : t = ""
  For i = 1 To Len(fmt)
    Dim c : c = Mid(fmt,i,1)    
    Select Case c
      Case "d"
        day = Int(Left(str,2))
        str = Mid(str,3)        
      Case "D"
        str = Mid(str,4)
      Case "j"
        t = Left(str,2)
        If IsNumeric(t) Then
          day = Int(t)
          str = Mid(str,3)
        Else
          day = Int(Left(str,1))
          str = Mid(str,2)
        End If
      Case "l"
        t = UCase(Left(str,3))
        Select Case t
          Case "SUN","MON","FRI"
            str = Mid(str,7)
          Case "TUE"
            str = Mid(str,8)     
          Case "THU","SAT"
            str = Mid(str,9)
          Case "WED"
            str = Mid(str,10)
        End Select     
      Case "N"
        str = Mid(str,2)
      Case "S"
        str = Mid(str,3)    
      Case "w"
        str = Mid(str,2)      
      Case "z"
        t = Left(str,3)
        If IsNumeric(t) Then
          day = Int(t)
          str = Mid(str,4)
        Else      
          t = Left(str,2)
          If IsNumeric(t) Then
            day = Int(t)
            str = Mid(str,3)
          Else
            day = Int(Left(str,1))
            str = Mid(str,2)
          End If
        End If
      Case "W"
        t = Left(str,2)
        If IsNumeric(t) Then
          day = Int(t)
          str = Mid(str,3)
        Else
          day = Int(Left(str,1))
          str = Mid(str,2)
        End If
      Case "F"
        t = UCase(Left(str,3))
        Select Case t      
          Case "JAN"
            mon = 1
            str = Mid(str,8)
          Case "FEB"
            mon = 2
            str = Mid(str,9)
          Case "MAR"
            mon = 3
            str = Mid(str,6)
          Case "APR"
            mon = 4
            str = Mid(str,6)
          Case "MAY"
            mon = 5
            str = Mid(str,4)
          Case "JUN"
            mon = 6
            str = Mid(str,5)
          Case "JUL"
            mon = 7
            str = Mid(str,5)
          Case "AUG"
            mon = 8
            str = Mid(str,7)
          Case "SEP"
            mon = 9
            str = Mid(str,10)
          Case "OCT"
            mon = 10
            str = Mid(str,8)
          Case "NOV"
            mon = 11
            str = Mid(str,9)
          Case "DEC"
            mon = 12
            str = Mid(str,9)
        End Select      
      Case "m"      
        mon = Int(Left(str,2))
        str = Mid(str,3)      
      Case "M"
        t = InStr("JANFEBMARAPRMAYJUNJULAUGSEPOCTNOVDEC",s)-1
        If t > -1 And t/3 = t\3 Then  
          mon = (t/3)+1 
        End If
        str = Mid(str,4)      
      Case "n"
        t = Left(str,2)
        If IsNumeric(t) Then
          mon = Int(t)
          str = Mid(str,3)
        Else
          mon = Int(Left(str,1))
          str = Mid(str,2)
        End If      
      Case "t"
        str = Mid(str,3)            
      Case "L"
        str = Mid(str,2)
      Case "o"
        year = Int(Left(str,4))
        str = Mid(str,5)            
      Case "Y"
        year = Int(Left(str,4))
        str = Mid(str,5)
      Case "y"
        year = Int(Left(str,2))
        str = Mid(str,3)
      Case Else
        str = Mid(str,2)
    End Select
  Next
  GetDateKnown = DateSerial(year,mon,day)
End Function

Function GetPlayedDates(inc,sid)
  GetPlayedDates = ""
  Dim iter : Set iter = SDB.Database.OpenSQL("SELECT PlayDate FROM Played WHERE IDSong="&sid)
  If Not (iter.EOF) Then
    Dim beg : beg = DateSerial(1899,12,30)
    Dim sec : sec = 1/86400
    While Not (iter.EOF)
      Dim arr : arr = Split(iter.StringByIndex(0),".")
      Dim tim : tim = ""
      Dim dat : dat = DateAdd("D",arr(0),beg)
      If inc = 1 Then
        Dim tot : tot = ("0."&arr(1))*86400
        Dim secs : secs = tot Mod 60
        tot = (tot-secs)/60
        Dim mins : mins = tot Mod 60
        Dim hour : hour = CLng((tot-mins)/60)
        tim = " "&FormatDateTime(hour&":"&mins&":"&secs)
      End If
      GetPlayedDates = GetPlayedDates&", "&dat&tim
      iter.Next
    WEnd
    GetPlayedDates = Mid(GetPlayedDates,3)
  End If
End Function

Function GetImageNames(itm)
  GetImageNames = ""
  Dim pics : Set pics = itm.AlbumArt
  If Not (pics Is Nothing) Then      
    Dim i : i = 0
    For i = 0 To pics.Count-1 
      If pics.Item(i).ItemStorage = 1 Then
        Dim p : p = pics.Item(i).PicturePath
        GetImageNames = GetImageNames&", "&Mid(p,InStrRev(p,"\")+1)
      End If
    Next
    GetImageNames = Mid(GetImageNames,3)
  End If
End Function

Function GetArtworkIcon(src,wid)
  If Not IsNumeric(wid) Then
    wid = 50
  End If
  If InStr(src,"\") > 0 Then
    src = "file:///"&Replace(src,"\","/")
  End If
  GetArtworkIcon = "<img src="""&src&""" border=""0"" width="""&wid&"px"" height="""&wid&"px"" />"
End Function

Function FixOrder(num)
  If num > 9 Then
    FixOrder = ""&num
  Else
    FixOrder = "0"&num
  End If
End Function

Function BuildHyperlink(fmt,lnk,str)
  Select Case fmt
    Case 0 'CSV
      BuildHyperlink = str&": "&lnk
    Case 1 'HTML
      BuildHyperlink = "<a href="""&lnk&""">"&MapXML(str,False)&"</a>"
    Case 2 'XLS
      BuildHyperlink = "=Hyperlink("""&lnk&""","""&str&""")"
    Case 3 'NFO
      BuildHyperlink = MapXML(str&": "&lnk,True)
    Case 4 'TXT
      BuildHyperlink = str&": "&lnk
    Case 5 'CD Cover
      BuildHyperlink = "<a href="""&lnk&""">"&MapXML(str,False)&"</a>"
    Case 6 'CD Tiled
      BuildHyperlink = "<a href="""&lnk&""">"&MapXML(str,False)&"</a>"
    Case 7 'XLSX
      BuildHyperlink = "=Hyperlink("""&lnk&""","""&str&""")"      
  End Select
End Function  

Function BuildUnderline(str)
  BuildUnderline = ""
  Dim i : i = 0
  Dim l : l = Len(str)
  For i = 1 To l 
    BuildUnderline = BuildUnderline&"-"
  Next
End Function

Function GetPlayedLength(itm)
  Select Case itm.PlayCounter
    Case 0
      GetPlayedLength = "0:00"
    Case 1
      GetPlayedLength = itm.SongLengthString
    Case Else
      GetPlayedLength = GetTimeStr(itm.PlayCounter*itm.SongLength)
  End Select 
End Function

Function GetOriginalDate(itm)
  Dim y : y = itm.OriginalYear
  If y = 0 Then
    GetOriginalDate = ""
  Else
    Dim d : d = itm.OriginalDay
    If d = 0 Then
      d = 1
    End If
    Dim m : m = itm.OriginalMonth
    If m = 0 Then
      m = 1
    End If
    GetOriginalDate = FormatDateTime(DateSerial(y,m,d),2)
  End If
End Function

Function MakeTimeStr(tot)
  Dim secs : secs = tot Mod 60
  tot = (tot-secs)/60
  Dim mins : mins = tot Mod 60
  Dim hour : hour = CLng((tot-mins)/60)
  MakeTimeStr = FormatDateTime(hour&":"&mins&":"&secs)
  Dim chr : chr = Left(MakeTimeStr,1)
  While (chr = "0" Or chr = ":")
    MakeTimeStr = Mid(MakeTimeStr,2)
    If Len(MakeTimeStr) > 4 Then
      chr = Left(MakeTimeStr,1)
    Else
      chr = ""
    End If
  WEnd
End Function

Function ParseNumeric(str)
  If Len(str) = 0 Then
    ParseNumeric = 0
  Else
    If InStr(str,":") > 0 Then
      ParseNumeric = ParseTime(str)
    Else
      If IsNumeric(str) Then
        ParseNumeric = str*1
      Else
        Dim a : a = "0123456789."
        Dim i : i = 0
        Dim s : s = str
        For i = 1 To Len(str)
          If InStr(a,Mid(str,i,1)) = 0 Then
            s = Left(str,i-1)
            Exit For
          End If      
        Next
        If Len(s) = 0 Then
          ParseNumeric = 0
        Else
          ParseNumeric = s*1
        End If
      End If
    End If    
  End If
End Function

Function ParseTime(str)
  Dim arr : arr = Split(str,":")
  Select Case UBound(arr)
    Case 1
      ParseTime = (ParseNumeric(arr(0))*60)+(ParseNumeric(arr(1)))
    Case 2
      ParseTime = (ParseNumeric(arr(0))*1440)+(ParseNumeric(arr(1))*60)+(ParseNumeric(arr(2)))
    Case Else
      ParseTime = 0
  End Select
End Function
     
Function FixCSV(arr,del1,del2,del3)
  Dim i : i = 0
  If IsArray(arr) Then
    FixCSV = del1&Replace(arr(0),Chr(34),Chr(34)&Chr(34))
    For i = 1 To UBound(arr)
      FixCSV = FixCSV&del2&Replace(arr(i),Chr(34),Chr(34)&Chr(34))
    Next
    FixCSV = FixCSV&del3      
  Else
    FixCSV = del1&Replace(arr,Chr(34),Chr(34)&Chr(34))&del3
  End If
End Function    

Function fixpath(loc)
  fixpath = loc
  If InStr(fixpath,"~1") = 0 Then
    Exit Function
  End If
  
  'split path
  Dim p,f,i,fil
  If Right(fixpath,1) = "\" Then
    p = fixpath
    f = ""
  Else
    i = InStrRev(fixpath,"\")
    p = Left(fixpath,i)
    f = Mid(fixpath,i+1)
  End If

  'check path
  Dim fso : Set fso = CreateObject("Scripting.FileSystemObject")  
  If Not fso.FolderExists(p) Then
    Exit Function
  End If
  
  'fix path
  Dim shl : Set shl = CreateObject("Shell.Application")
  For Each fil In fso.GetFolder(p).Files
    p = shl.Namespace(p).ParseName(fil.Name).Path
    p = Left(p,InStrRev(p,"\"))
    Exit For
  Next
  
  'fix filename
  If f = "" Then
    fixpath = p
  Else
    If fso.FileExists(fixpath) Then
      fixpath = shl.Namespace(p).ParseName(f).Path
    Else
      fixpath = p&f
    End If
  End If
End Function

Function cutpath(loc)
  cutpath = loc
  Dim fso : Set fso = CreateObject("Scripting.FileSystemObject")  
  If Not fso.FileExists(loc) Then
    Exit Function
  End If
 
  Dim fil : Set fil = fso.GetFile(loc)
  cutpath = fil.ShortPath
End Function

Function fixmask(loc)
  If InStr(fixmask,"<") > 0 Then
    Dim dat : dat = Date
    Dim tim : tim = Time  
    fixmask = Replace(fixmask,"<Y>",lead2(Year(dat)))
    fixmask = Replace(fixmask,"<M>",lead2(Month(dat)))
    fixmask = Replace(fixmask,"<D>",lead2(Day(dat)))
    fixmask = Replace(fixmask,"<H>",lead2(Hour(tim)))
    fixmask = Replace(fixmask,"<N>",lead2(Minute(tim)))
    fixmask = Replace(fixmask,"<S>",lead2(Second(tim)))
    fixmask = Replace(fixmask,"<V>",SDB.VersionString)
    fixmask = Replace(fixmask,"<B>",SDB.VersionBuild)
  End If
End Function

Function upmask(loc)
  upmask = ""
  Dim l : l = loc
  Dim i : i = InStr(l,"<")
  While i > 0
    Dim j : j = InStr(i,l,">")
    upmask = upmask&Left(l,i)&UCase(Mid(l,i+1,j-i))
    l = Mid(l,j+1)
    i = InStr(l,"<")
  WEnd
  upmask = upmask&l
End Function

Function lead2(temp)
  If temp < 10 Then
    lead2 = "0"&temp
  Else
    lead2 = ""&temp
  End If
End Function
 
Function GetTrackType(typ)
  GetTrackType = ""
  Select Case typ
    Case 0 
      GetTrackType = "Music"
    Case 1
      GetTrackType = "Podcast"
    Case 2 
      GetTrackType = "Audiobook"
    Case 3 
      GetTrackType = "Classical Music"
    Case 4 
      GetTrackType = "Music Video"
    Case 5 
      GetTrackType = "Video"
    Case 6 
      GetTrackType = "TV"
    Case 7 
      GetTrackType = "Video Podcast"
  End Select
End Function 

Function GetTimeStr(mil)
  If mil < 1 Then
    GetTimeStr = "0:00"
  Else
    GetTimeStr = MakeTimeStr(mil/1000)
  End If 
End Function