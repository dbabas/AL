report 50008 "Payment Days Analysis (DSO)"
{
    // version NAVGR8.00.42603

    DefaultLayout = RDLC;
    RDLCLayout = 'src\report\Payment Days Analysis (DSO).rdlc';
    CaptionML = ELL='Ανάλυση Ημερών Πληρωμής',
                ENU='Payment Days Analysis';
    EnableHyperlinks = true;

    dataset
    {
        dataitem(Customer;Customer)
        {
            RequestFilterFields = "No.";
            dataitem("Cust. Ledger Entry";"Cust. Ledger Entry")
            {
                DataItemLink = "Customer No."=FIELD("No."),"Posting Date"=FIELD("Date Filter");
                DataItemTableView = SORTING("Customer No.","Posting Date","Currency Code") WHERE("Document Type"=FILTER(" "|Payment|Refund));
                RequestFilterFields = "Document No.";

                trigger OnAfterGetRecord();
                begin
                    CLE.RESET;
                    CLEAR(CLE);
                    CLE.CLEARMARKS;
                    with CLE do begin
                      DtldCustLedgEntry1.SETCURRENTKEY("Cust. Ledger Entry No.");
                      DtldCustLedgEntry1.SETRANGE("Cust. Ledger Entry No.","Cust. Ledger Entry"."Entry No.");
                      DtldCustLedgEntry1.SETRANGE(Unapplied,false);
                      if DtldCustLedgEntry1.FINDSET then
                        repeat
                          if DtldCustLedgEntry1."Cust. Ledger Entry No." = DtldCustLedgEntry1."Applied Cust. Ledger Entry No." then begin
                            DtldCustLedgEntry2.INIT;
                            DtldCustLedgEntry2.SETCURRENTKEY("Applied Cust. Ledger Entry No.","Entry Type");
                            DtldCustLedgEntry2.SETRANGE("Applied Cust. Ledger Entry No.",DtldCustLedgEntry1."Applied Cust. Ledger Entry No.");
                            DtldCustLedgEntry2.SETRANGE("Entry Type",DtldCustLedgEntry2."Entry Type"::Application);
                            DtldCustLedgEntry2.SETRANGE(Unapplied,false);
                            if DtldCustLedgEntry2.FINDSET then
                              repeat
                                if DtldCustLedgEntry2."Cust. Ledger Entry No." <> DtldCustLedgEntry2."Applied Cust. Ledger Entry No."
                                then begin
                                  SETCURRENTKEY("Entry No.");
                                  SETRANGE("Entry No.",DtldCustLedgEntry2."Cust. Ledger Entry No.");
                                  if FINDFIRST then
                                    MARK(true);
                                end;
                              until DtldCustLedgEntry2.NEXT = 0;
                          end else begin
                            SETCURRENTKEY("Entry No.");
                            SETRANGE("Entry No.",DtldCustLedgEntry1."Applied Cust. Ledger Entry No.");
                            if FINDFIRST then
                             MARK(true);
                          end;
                        until DtldCustLedgEntry1.NEXT = 0;

                      SETCURRENTKEY("Entry No.");
                      SETRANGE("Entry No.");

                      if "Closed by Entry No." <> 0 then begin
                        "Entry No." := "Cust. Ledger Entry"."Closed by Entry No.";
                        MARK(true);
                      end;

                      SETCURRENTKEY("Closed by Entry No.");
                      SETRANGE("Closed by Entry No.","Cust. Ledger Entry"."Entry No.");
                      if FINDSET then
                        repeat
                          MARK(true);
                        until NEXT = 0;

                      SETCURRENTKEY("Entry No.");
                      SETRANGE("Closed by Entry No.");

                      MARKEDONLY(true);
                      if FIND('-') then
                      repeat
                          tmpCLE:=CLE;
                          tmpCLE."Entry No." := NextEntryNo;
                          NextEntryNo+=1;
                          tmpCLE."Sales (LCY)" := Amount;
                          tmpCLE."Closed by Amount (LCY)":=-"Cust. Ledger Entry"."Amount (LCY)";
                          tmpCLE.Description := "Cust. Ledger Entry"."Document No.";
                          Cheque.SETRANGE("No.", "Cust. Ledger Entry"."External Document No.");
                          if Cheque.FINDFIRST then
                            tmpCLE."Pmt. Discount Date" := Cheque."Value Date"
                          else
                            tmpCLE."Pmt. Discount Date" := "Cust. Ledger Entry"."Posting Date";
                          tmpCLE."Transaction No." := tmpCLE."Pmt. Discount Date"-tmpCLE."Due Date";
                          tmpCLE."Pmt. Disc. Tolerance Date" := tmpCLE."Due Date";
                          tmpCLE."Closed by Entry No.":=tmpCLE."Pmt. Discount Date"-tmpCLE."Pmt. Disc. Tolerance Date";
                          tmpCLE."Last Issued Reminder Level" := tmpCLE."Pmt. Discount Date"-tmpCLE."Posting Date";
                          tmpCLE."Customer No." := FORMAT(tmpCLE."Posting Date",0,9) + FORMAT(tmpCLE."Pmt. Discount Date",0,9);

                          DtldCustLedgEntry3.SETRANGE("Document No.", "Cust. Ledger Entry"."Document No.");
                          DtldCustLedgEntry3.SETRANGE("Entry Type", DtldCustLedgEntry3."Entry Type"::Application);
                          DtldCustLedgEntry3.SETRANGE("Initial Document Type", DtldCustLedgEntry3."Initial Document Type"::Invoice);
                          DtldCustLedgEntry3.SETRANGE("Cust. Ledger Entry No.", CLE."Entry No.");
                          DtldCustLedgEntry3.CALCSUMS(Amount);
                          if DtldCustLedgEntry3.Amount <> 0 then
                            tmpCLE."Amount to Apply" := ABS(DtldCustLedgEntry3.Amount);

                          DtldCustLedgEntry3.SETRANGE("Document No.", CLE."Document No.");
                          DtldCustLedgEntry3.SETRANGE("Entry Type", DtldCustLedgEntry3."Entry Type"::Application);
                          DtldCustLedgEntry3.SETRANGE("Initial Document Type", DtldCustLedgEntry3."Initial Document Type"::Payment);
                          DtldCustLedgEntry3.SETRANGE("Cust. Ledger Entry No.", "Cust. Ledger Entry"."Entry No.");
                          DtldCustLedgEntry3.CALCSUMS(Amount);
                          if DtldCustLedgEntry3.Amount <> 0 then
                            tmpCLE."Amount to Apply" := ABS(DtldCustLedgEntry3.Amount);

                          tmpCLE."MYF Amount" := tmpCLE."Last Issued Reminder Level"*tmpCLE."Amount to Apply";
                          if ExcludeCash then begin
                            if tmpCLE."Last Issued Reminder Level">0 then
                              tmpCLE.INSERT;
                          end else
                            tmpCLE.INSERT;
                      until NEXT = 0;
                    end;
                end;

                trigger OnPreDataItem();
                begin
                    SETAUTOCALCFIELDS("Amount (LCY)");
                    CLE.SETAUTOCALCFIELDS(Amount);
                end;
            }
            dataitem("Integer";"Integer")
            {
                DataItemTableView = SORTING(Number);
                column(CustomerLink;FORMAT(CustomerRecRef.RECORDID,0,10))
                {
                }
                column(CLELink;FORMAT(CLERecRef.RECORDID,0,10))
                {
                }
                column(CLEDocLink;FORMAT(CLEDocRecRef.RECORDID,0,10))
                {
                }
                column(CustomerNo;Customer."No.")
                {
                }
                column(CustomerName;Customer.Name)
                {
                }
                column(CompanyPicture;CompanyInfo.Picture)
                {
                }
                column(PostingDate;tmpCLE."Posting Date")
                {
                }
                column(DocumentNo;tmpCLE."Document No.")
                {
                }
                column(RelatedDocument;tmpCLE.Description)
                {
                }
                column(InitialAmount;tmpCLE."Sales (LCY)")
                {
                }
                column(Payment;tmpCLE."Closed by Amount (LCY)")
                {
                }
                column(PaymentDate;tmpCLE."Pmt. Discount Date")
                {
                }
                column(DocumentDueDate;tmpCLE."Pmt. Disc. Tolerance Date")
                {
                }
                column(DocumentExcess;tmpCLE."Closed by Entry No.")
                {
                }
                column(TotalDays;tmpCLE."Last Issued Reminder Level")
                {
                }
                column(AppliedAmount;tmpCLE."Amount to Apply")
                {
                }
                column(AmountDays;tmpCLE."MYF Amount")
                {
                }
                column(GrandTotalDays;GrandTotalDays)
                {
                }
                column(GrandTotal;GrandTotal)
                {
                }
                dataitem(Totals;"Integer")
                {
                    DataItemTableView = WHERE(Number=CONST(1));
                    column(Result;Result)
                    {
                    }
                    column(OpenResult;OpenResult)
                    {
                    }
                    column(TotalResult;TotalResult)
                    {
                    }

                    trigger OnAfterGetRecord();
                    begin
                        OpenCLE.SETAUTOCALCFIELDS("Remaining Amt. (LCY)");
                        OpenCLE.SETCURRENTKEY("Customer No.");
                        OpenCLE.SETRANGE("Customer No.",Customer."No.");
                        if (DateFrom <> 0D) and (DateTo <> 0D) then
                          OpenCLE.SETFILTER("Posting Date",'%1..%2|%3', DateFrom, DateTo,0D);
                        if OpenCLE.FINDSET then
                          repeat
                            if (OpenCLE."Remaining Amt. (LCY)">0) and (DateTo-OpenCLE."Posting Date">Result) then begin
                              OpenGrandTotalDays += OpenCLE."Remaining Amt. (LCY)"*(DateTo-OpenCLE."Posting Date");
                              OpenGrandTotal += OpenCLE."Remaining Amt. (LCY)";
                            end;
                          until OpenCLE.NEXT=0;
                        if OpenGrandTotal<>0 then
                          OpenResult := OpenGrandTotalDays/OpenGrandTotal;

                        if GrandTotal+OpenGrandTotal<>0 then
                          TotalResult := (GrandTotalDays+OpenGrandTotalDays)/(GrandTotal+OpenGrandTotal);
                    end;
                }

                trigger OnAfterGetRecord();
                begin
                    if Number=1 then
                      tmpCLE.FINDSET
                    else
                      tmpCLE.NEXT;

                    if tmpCLE."Last Issued Reminder Level"<>0 then begin
                      GrandTotalDays += tmpCLE."Last Issued Reminder Level"*tmpCLE."Amount to Apply";
                      GrandTotal += tmpCLE."Amount to Apply";
                    end;
                    if GrandTotal>0 then
                      Result := GrandTotalDays/GrandTotal
                    else
                      Result := 0;

                    CustomerRecRef.SETPOSITION(Customer.GETPOSITION);

                    CLELink.SETFILTER("Document No.", tmpCLE.Description);
                    if CLELink.FINDFIRST then
                      CLERecRef.SETPOSITION(CLELink.GETPOSITION);

                    CLEDocLink.SETFILTER("Document No.", tmpCLE."Document No.");
                    if CLEDocLink.FINDFIRST then
                      CLEDocRecRef.SETPOSITION(CLEDocLink.GETPOSITION);
                end;

                trigger OnPostDataItem();
                begin
                    tmpCLE.RESET;
                    tmpCLE.DELETEALL;
                end;

                trigger OnPreDataItem();
                begin
                    tmpCLE.SETCURRENTKEY("Customer No.");
                    if (DateFrom <> 0D) and (DateTo <> 0D) then
                      tmpCLE.SETFILTER("Posting Date",'%1..%2|%3', DateFrom, DateTo,0D);
                    SETRANGE(Number,1,tmpCLE.COUNT);
                end;
            }

            trigger OnPreDataItem();
            begin
                CustomerRecRef.OPEN(DATABASE::Customer);
                CLERecRef.OPEN(DATABASE::"Cust. Ledger Entry");
                CLEDocRecRef.OPEN(DATABASE::"Cust. Ledger Entry");
            end;
        }
    }

    requestpage
    {
        CaptionML = ELL='Επιλογές',
                    ENU='Options';
        SaveValues = true;

        layout
        {
            area(content)
            {
                Description = 'Options';
                group(Options)
                {
                    CaptionML = ELL='Επιλογές',
                                ENU='Options';
                    field("Date From";DateFrom)
                    {
                    }
                    field("Date To";DateTo)
                    {
                    }
                    field(ExcludeCash;ExcludeCash)
                    {
                        Caption = 'Εξαίρεση Μετρητοίς';
                    }
                }
            }
        }

        actions
        {
        }
    }

    labels
    {
        label(RCLbl001;ELL='Ημ/νία Καταχώρησης',
                       ENU='Posting Date')
        label(RCLbl002;ELL='Αρ. Παραστατικού',
                       ENU='Document No.')
        label(RCLbl003;ELL='Ποσό Παραστατικού',
                       ENU='Document Amount')
        label(RCLbl004;ELL='Πληρωμή',
                       ENU='Payment')
        label(RCLbl005;ELL='Ημ/νία Πληρωμής',
                       ENU='Payment Date')
        label(RCLbl006;ELL='Ημ/νία Λήξης',
                       ENU='Due Date')
        label(RCLbl007;ELL='Υπέρβαση',
                       ENU='Excess')
        label(RCLbl008;ELL='Ημ/νία Λήξης Παραστατικού',
                       ENU='Document Due Date')
        label(RCLbl009;ELL='Υπέρβαση',
                       ENU='Document Excess')
        label(RCLbl010;ELL='Σύνολο Ημερών',
                       ENU='Total Days')
        label(RCLbl011;ELL='Πιστωτικό Όριο Ημέρες',
                       ENU='Credit Limit Days')
        label(RCLbl012;ELL='Ανάλυση ημερών πληρωμής',
                       ENU='Payment days analysis')
        label(RCLbl013;ELL='M.O. Πληρωμής',
                       ENU='AVG Payment')
        label(RCLbl014;ELL='Πελάτης',
                       ENU='Customer')
        label(RCLbl015;ELL='Αρ. Σχετικού Παραστατικού',
                       ENU='Related Document No')
        label(RCLbl016;ELL='M.O. Πελάτη',
                       ENU='AVG Customer')
        label(TitleLbl;ELL='Ανάλυση ημερών πληρωμής',
                       ENU='Payment days analysis')
    }

    trigger OnPreReport();
    begin
        CompanyInfo.GET;
        CompanyInfo.CALCFIELDS(CompanyInfo.Picture);
    end;

    var
        tmpCLE : Record "Cust. Ledger Entry" temporary;
        NextEntryNo : Integer;
        DateFrom : Date;
        DateTo : Date;
        Cheque : Record Cheque;
        CLE : Record "Cust. Ledger Entry";
        RCText01 : TextConst ELL='M.O. Ημερών Πληρωμής',ENU='Avg days to payment';
        CompanyInfo : Record "Company Information";
        DtldCustLedgEntry1 : Record "Detailed Cust. Ledg. Entry";
        DtldCustLedgEntry2 : Record "Detailed Cust. Ledg. Entry";
        DtldCustLedgEntry3 : Record "Detailed Cust. Ledg. Entry";
        CustomerRecRef : RecordRef;
        CLERecRef : RecordRef;
        CLELink : Record "Cust. Ledger Entry";
        CLEDocRecRef : RecordRef;
        CLEDocLink : Record "Cust. Ledger Entry";
        GrandTotalDays : Decimal;
        GrandTotal : Decimal;
        Result : Decimal;
        OpenGrandTotalDays : Decimal;
        OpenGrandTotal : Decimal;
        OpenResult : Decimal;
        OpenCLE : Record "Cust. Ledger Entry";
        TotalResult : Decimal;
        ExcludeCash : Boolean;
}

