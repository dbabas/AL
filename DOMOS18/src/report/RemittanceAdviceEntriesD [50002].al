report 50002 "Remittance Advice - Entries-D"
{
    // version NAVGB8.00,QSSD08.00.00.00,IMP

    // //DOC IMP DB 26/08/19 - Copied from a GB database
    DefaultLayout = RDLC;
    RDLCLayout = 'src\report\Remittance Advice - Entries-D.rdlc';

    CaptionML = ENU='Remittance Advice - Entries',
                ENG='Remittance Advice - Entries';
    PreviewMode = PrintLayout;

    dataset
    {
        dataitem("Vendor Ledger Entry";"Vendor Ledger Entry")
        {
            DataItemTableView = SORTING("Vendor No.") WHERE("Document Type"=CONST(Payment));
            RequestFilterFields = "Vendor No.","Posting Date","Currency Code","Entry No.";
            column(CompanyAddr1;CompanyAddr[1])
            {
            }
            column(VendorAddr1;VendorAddr[1])
            {
            }
            column(CompanyAddr2;CompanyAddr[2])
            {
            }
            column(VendorAddr2;VendorAddr[2])
            {
            }
            column(CompanyAddr3;CompanyAddr[3])
            {
            }
            column(VendorAddr3;VendorAddr[3])
            {
            }
            column(CompanyAddr4;CompanyAddr[4])
            {
            }
            column(VendorAddr4;VendorAddr[4])
            {
            }
            column(CompanyAddr5;CompanyAddr[5])
            {
            }
            column(CompanyAddr6;CompanyAddr[6])
            {
            }
            column(VendorAddr5;VendorAddr[5])
            {
            }
            column(VendorAddr6;VendorAddr[6])
            {
            }
            column(CompanyInfoPhoneNo;CompanyInfo."Phone No.")
            {
            }
            column(VendorAddr7;VendorAddr[7])
            {
            }
            column(CompanyInfoVATRegNo;CompanyInfo."VAT Registration No.")
            {
            }
            column(CompanyInfoFaxNo;CompanyInfo."Fax No.")
            {
            }
            column(VendorAddr8;VendorAddr[8])
            {
            }
            column(CompanyInfoBankName;CompanyInfo."Bank Name")
            {
            }
            column(CompanyInfoBankAccNo;CompanyInfo."Bank Account No.")
            {
            }
            column(CompanyInfoBankBranchNo;CompanyInfo."Bank Branch No.")
            {
            }
            column(DocNo_VendLedgEntry;"Vendor Ledger Entry"."Document No.")
            {
            }
            column(EntryNo_VendLedgEntry;"Entry No.")
            {
            }
            column(VendorLedgerEntryVendorNo;"Vendor No.")
            {
            }
            column(RemittanceAdviceCaption;RemittanceAdvCaptionLbl)
            {
            }
            column(PhoneNoCaption;PhoneNoCaptionLbl)
            {
            }
            column(FaxNoCaption;FaxNoCaptionLbl)
            {
            }
            column(VATRegNoCaption;VATRegNoCaptionLbl)
            {
            }
            column(BankNameCaption;BankCaptionLbl)
            {
            }
            column(BankAccountNoCaption;AccNoCaptionLbl)
            {
            }
            column(SortCodeCaption;SortCodeCaptionLbl)
            {
            }
            column(AmountCaption;AmtCaptionLbl)
            {
            }
            column(PmtDiscTakenCaption;PmtDiscTakenCaptionLbl)
            {
            }
            column(RemainingAmtCaption;RemAmtCaptionLbl)
            {
            }
            column(OriginalAmountCaption;OriginalAmtCaptionLbl)
            {
            }
            column(YourDocNoCaption;YourDocNoCaptionLbl)
            {
            }
            column(DocTypeCaption_VendLedgEntry2;VendLedgEntry2.FIELDCAPTION("Document Type"))
            {
            }
            column(OurDocNoCaption;OurDocNoCaptionLbl)
            {
            }
            column(CurrCodeCaption;CurrCodeCaptionLbl)
            {
            }
            column(DocumentDateCaption;DocDateCaptionLbl)
            {
            }
            dataitem(VendLedgEntry2;"Vendor Ledger Entry")
            {
                DataItemTableView = SORTING("Entry No.");
                column(LineAmtLineDiscCurr;-LineAmount - LineDiscount)
                {
                    AutoFormatExpression = "Vendor Ledger Entry"."Currency Code";
                    AutoFormatType = 1;
                }
                column(NegAmount_VendLedgEntry2;-Amount)
                {
                    AutoFormatExpression = "Vendor Ledger Entry"."Currency Code";
                    AutoFormatType = 1;
                }
                column(RemAmt_VendLedgEntry2;-"Remaining Amount")
                {
                    AutoFormatExpression = "Vendor Ledger Entry"."Currency Code";
                    AutoFormatType = 1;
                }
                column(DocType_VendLedgEntry2;"Document Type")
                {
                }
                column(ExtDocNo_VendLedgEntry2;"External Document No.")
                {
                }
                column(LineDiscount_VendLedgEntry2;-LineDiscount)
                {
                    AutoFormatExpression = "Vendor Ledger Entry"."Currency Code";
                    AutoFormatType = 1;
                }
                column(CurrCode_VendLedgEntry2;CurrencyCode("Currency Code"))
                {
                }
                column(DocDateFormat_VendLedgEntry2;FORMAT("Document Date"))
                {
                }
                column(LAmountWDiscCur;LAmountWDiscCur)
                {
                }
                column(EntryNo_VendLedgEntry2;"Entry No.")
                {
                }
                column(PostingDate_VendLedgEntry2;FORMAT("Posting Date"))
                {
                }
                column(DocumentNoVendLedgEntry2;"Document No.")
                {
                }
                dataitem("Detailed Vendor Ledg. Entry";"Detailed Vendor Ledg. Entry")
                {
                    DataItemLink = "Vendor Ledger Entry No."=FIELD("Entry No."),"Initial Document Type"=FIELD("Document Type");
                    DataItemTableView = SORTING("Vendor Ledger Entry No.","Entry Type","Posting Date") WHERE("Entry Type"=CONST(Application),"Document Type"=CONST("Credit Memo"));
                    column(LineDisc_DtldVendLedgEntry;-LineDiscount)
                    {
                        AutoFormatExpression = "Vendor Ledger Entry"."Currency Code";
                        AutoFormatType = 1;
                    }
                    column(VendLedgEntry3RemAmt;-VendLedgEntry3."Remaining Amount")
                    {
                        AutoFormatExpression = "Vendor Ledger Entry"."Currency Code";
                        AutoFormatType = 1;
                    }
                    column(Amt_DtldVendLedgEntry;-Amount)
                    {
                        AutoFormatExpression = "Vendor Ledger Entry"."Currency Code";
                        AutoFormatType = 1;
                    }
                    column(VendLedgEntry3CurrCode;CurrencyCode(VendLedgEntry3."Currency Code"))
                    {
                    }
                    column(VendLedgEntry3DocDateFrmt;FORMAT(VendLedgEntry3."Document Date"))
                    {
                    }
                    column(VendLedgEntry3ExtDocNo;VendLedgEntry3."External Document No.")
                    {
                    }
                    column(DocType_DtldVendLedgEntry;"Document Type")
                    {
                    }
                    column(VendLedgerEntryNo_DtldVendLedgEntry;"Vendor Ledger Entry No.")
                    {
                    }
                    column(VendLedgEntry3PostingDate;FORMAT("Posting Date"))
                    {
                    }
                    column(VendLedgEntry3DocNo;"Document No.")
                    {
                    }
                    column(VendLedgEntry3VendorNo;"Vendor No.")
                    {
                    }

                    trigger OnAfterGetRecord();
                    begin
                        VendLedgEntry3.GET("Applied Vend. Ledger Entry No.");
                        if "Vendor Ledger Entry No." = "Applied Vend. Ledger Entry No." then
                          CurrReport.SKIP;
                        VendLedgEntry3.CALCFIELDS(Amount,"Remaining Amount");
                        LineAmount := VendLedgEntry3.Amount - VendLedgEntry3."Remaining Amount";
                        LineDiscount :=
                          CurrExchRate.ExchangeAmtFCYToFCY(
                            "Posting Date",'',"Currency Code",
                            VendLedgEntry3."Pmt. Disc. Rcd.(LCY)");
                        LineDiscountCurr :=
                          CurrExchRate.ExchangeAmtFCYToFCY(
                            VendLedgEntry3."Posting Date",'',"Vendor Ledger Entry"."Currency Code",
                            VendLedgEntry3."Pmt. Disc. Rcd.(LCY)");

                        VendLedgEntry3.Amount :=
                          VendLedgEntry3.Amount + LineDiscountCurr;
                    end;
                }

                trigger OnAfterGetRecord();
                var
                    DtldVendLedgEntry : Record "Detailed Vendor Ledg. Entry";
                begin
                    CALCFIELDS(Amount,"Remaining Amount");
                    DtldVendLedgEntry.SETRANGE("Vendor Ledger Entry No.","Entry No.");
                    DtldVendLedgEntry.SETRANGE("Entry Type",DtldVendLedgEntry."Entry Type"::Application);
                    DtldVendLedgEntry.SETRANGE("Document Type",DtldVendLedgEntry."Document Type"::Payment);
                    DtldVendLedgEntry.SETRANGE("Document No.","Vendor Ledger Entry"."Document No.");
                    if not DtldVendLedgEntry.FINDFIRST then
                      CurrReport.SKIP;
                    LineAmount := DtldVendLedgEntry.Amount;
                    LineDiscount := CurrExchRate.ExchangeAmtFCYToFCY("Posting Date",'',"Currency Code","Pmt. Disc. Rcd.(LCY)");

                    "Vendor Ledger Entry".Amount += LineDiscount;

                    LAmountWDiscCur := -LineAmount - LineDiscount;
                end;

                trigger OnPreDataItem();
                begin
                    CreateVendLedgEntry := "Vendor Ledger Entry";
                    FindApplnEntriesDtldtLedgEntry;
                    SETCURRENTKEY("Entry No.");
                    SETRANGE("Entry No.");

                    if CreateVendLedgEntry."Closed by Entry No." <> 0 then begin
                      "Entry No." := CreateVendLedgEntry."Closed by Entry No.";
                      MARK(true);
                    end;

                    SETCURRENTKEY("Closed by Entry No.");
                    SETRANGE("Closed by Entry No.",CreateVendLedgEntry."Entry No.");
                    if FIND('-') then
                      repeat
                        MARK(true);
                      until NEXT = 0;

                    SETCURRENTKEY("Entry No.");
                    SETRANGE("Closed by Entry No.");
                    MARKEDONLY(true);
                end;
            }
            dataitem("Integer";"Integer")
            {
                DataItemTableView = SORTING(Number) WHERE(Number=CONST(1));
                column(Amount_VendLedgEntry;"Vendor Ledger Entry".Amount)
                {
                    AutoFormatExpression = "Vendor Ledger Entry"."Currency Code";
                    AutoFormatType = 1;
                }
                column(CurrCode_VendLedgEntry;CurrencyCode("Vendor Ledger Entry"."Currency Code"))
                {
                }
                column(TotalCaption;TotalCaptionLbl)
                {
                }
            }

            trigger OnAfterGetRecord();
            begin
                Vend.GET("Vendor No.");
                FormatAddr.Vendor(VendorAddr,Vend);
                "Vendor Ledger Entry".CALCFIELDS(Amount);
            end;
        }
    }

    requestpage
    {

        layout
        {
        }

        actions
        {
        }
    }

    labels
    {
    }

    trigger OnPreReport();
    begin
        CompanyInfo.GET;
        FormatAddr.Company(CompanyAddr,CompanyInfo);
        GLSetup.GET;
        GLSetup.TESTFIELD("LCY Code");
    end;

    var
        Vend : Record Vendor;
        CompanyInfo : Record "Company Information";
        GLSetup : Record "General Ledger Setup";
        CurrExchRate : Record "Currency Exchange Rate";
        CreateVendLedgEntry : Record "Vendor Ledger Entry";
        VendLedgEntry3 : Record "Vendor Ledger Entry";
        FormatAddr : Codeunit "Format Address";
        VendorAddr : array [8] of Text[50];
        CompanyAddr : array [8] of Text[50];
        LineAmount : Decimal;
        LineDiscount : Decimal;
        LineDiscountCurr : Decimal;
        LAmountWDiscCur : Decimal;
        RemittanceAdvCaptionLbl : TextConst ELL='Ένταλμα Πληρωμής',ENU='Remittance Advice',ENG='Remittance Advice';
        PhoneNoCaptionLbl : TextConst ELL='Τηλέφωνο',ENU='Phone No.',ENG='Phone No.';
        FaxNoCaptionLbl : TextConst ELL='Fax',ENU='Fax No.',ENG='Fax No.';
        VATRegNoCaptionLbl : TextConst ELL='ΑΦΜ',ENU='VAT Reg. No.',ENG='VAT Reg. No.';
        BankCaptionLbl : TextConst ELL='Τράπεζα',ENU='Bank',ENG='Bank';
        AccNoCaptionLbl : TextConst ELL='Λογαριασμός',ENU='Account No.',ENG='Account No.';
        SortCodeCaptionLbl : TextConst ELL='Υποκατάστημα',ENU='Sort Code',ENG='Sort Code';
        AmtCaptionLbl : TextConst ELL='Ποσό',ENU='Amount',ENG='Amount';
        PmtDiscTakenCaptionLbl : TextConst ENU='Pmt. Disc. Taken',ENG='Pmt. Disc. Taken';
        RemAmtCaptionLbl : TextConst ENU='Remaining Amount',ENG='Remaining Amount';
        OriginalAmtCaptionLbl : TextConst ENU='Original Amount',ENG='Original Amount';
        YourDocNoCaptionLbl : TextConst ENU='Your Document No.',ENG='Your Document No.';
        OurDocNoCaptionLbl : TextConst ENU='Our Document No.',ENG='Our Document No.';
        CurrCodeCaptionLbl : TextConst ENU='Curr. Code',ENG='Curr. Code';
        DocDateCaptionLbl : TextConst ELL='Ημερομηνία',ENU='Document Date',ENG='Document Date';
        TotalCaptionLbl : TextConst ELL='Σύνολο',ENU='Total',ENG='Total';

    procedure CurrencyCode(SrcCurrCode : Code[10]) : Code[10];
    begin
        if SrcCurrCode = '' then
          exit(GLSetup."LCY Code");

        exit(SrcCurrCode);
    end;

    local procedure FindApplnEntriesDtldtLedgEntry();
    var
        DtldVendLedgEntry1 : Record "Detailed Vendor Ledg. Entry";
        DtldVendLedgEntry2 : Record "Detailed Vendor Ledg. Entry";
    begin
        DtldVendLedgEntry1.RESET;
        DtldVendLedgEntry1.SETCURRENTKEY("Vendor Ledger Entry No.");
        DtldVendLedgEntry1.SETRANGE("Vendor Ledger Entry No.",CreateVendLedgEntry."Entry No.");
        DtldVendLedgEntry1.SETRANGE(Unapplied,false);
        if DtldVendLedgEntry1.FIND('-') then begin
          repeat
            if DtldVendLedgEntry1."Vendor Ledger Entry No." =
               DtldVendLedgEntry1."Applied Vend. Ledger Entry No."
            then begin
              DtldVendLedgEntry2.RESET;
              DtldVendLedgEntry2.SETCURRENTKEY("Applied Vend. Ledger Entry No.","Entry Type");
              DtldVendLedgEntry2.SETRANGE(
                "Applied Vend. Ledger Entry No.",DtldVendLedgEntry1."Applied Vend. Ledger Entry No.");
              DtldVendLedgEntry2.SETRANGE("Entry Type",DtldVendLedgEntry2."Entry Type"::Application);
              DtldVendLedgEntry2.SETRANGE(Unapplied,false);
              if DtldVendLedgEntry2.FIND('-') then begin
                repeat
                  if DtldVendLedgEntry2."Vendor Ledger Entry No." <>
                     DtldVendLedgEntry2."Applied Vend. Ledger Entry No."
                  then begin
                    VendLedgEntry2.SETCURRENTKEY("Entry No.");
                    VendLedgEntry2.SETRANGE("Entry No.",DtldVendLedgEntry2."Vendor Ledger Entry No.");
                    if VendLedgEntry2.FIND('-') then
                      VendLedgEntry2.MARK(true);
                  end;
                until DtldVendLedgEntry2.NEXT = 0;
              end;
            end else begin
              VendLedgEntry2.SETCURRENTKEY("Entry No.");
              VendLedgEntry2.SETRANGE("Entry No.",DtldVendLedgEntry1."Applied Vend. Ledger Entry No.");
              if VendLedgEntry2.FIND('-') then
                VendLedgEntry2.MARK(true);
            end;
          until DtldVendLedgEntry1.NEXT = 0;
        end;
    end;
}

