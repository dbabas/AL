report 50001 "Remittance Advice Journal-D"
{
    // version NAVGB5.00.01,PER01,ADV04.06,IMP

    // ///(15/07/03 IA) M1 upgraded from 3.10 to 3.60.
    //                  M1 Added code to remove contact data if present
    // 
    // 001 MG 19/12/12 ADV04.06
    //                 Reformatted report
    // //DOC IMP DB 26/08/19 - Copied from a GB database
    DefaultLayout = RDLC;
    RDLCLayout = 'src\report\Remittance Advice Journal-D.rdlc';

    CaptionML = ENU = 'Remittance Advice - Journal',
                ENG = 'Remittance Advice - Journal';

    dataset
    {
        dataitem(FindVendors; "Gen. Journal Line")
        {
            DataItemTableView = SORTING ("Journal Template Name", "Journal Batch Name", "Line No.");
            RequestFilterFields = "Journal Template Name", "Journal Batch Name", "Posting Date", "Document No.";

            trigger OnAfterGetRecord();
            begin
                if("Account Type" = "Account Type"::Vendor) and
                   ("Account No." <> '')
                then
                    if not VendTemp.GET("Account No.") then begin
                        Vend.GET("Account No.");
                        VendTemp := Vend;
                        VendTemp.INSERT;
                    end;
            end;
        }
        dataitem(Vendor; Vendor)
        {
            DataItemTableView = SORTING ("No.");
            RequestFilterFields = "No.";

            trigger OnPreDataItem();
            begin
                // Dataitem is here just to display request form - filters set by the user will be used later.
                CurrReport.BREAK;
            end;
        }
        dataitem(VendLoop; "Integer")
        {
            DataItemTableView = SORTING (Number);
            column(VendAddr1; VendorAddr[1])
            {
            }
            column(VendAddr2; VendorAddr[2])
            {
            }
            column(CompAddr1; CompanyAddr[1])
            {
            }
            column(CompAddr2; CompanyAddr[2])
            {
            }
            column(VendAddr3; VendorAddr[3])
            {
            }
            column(CompAddr3; CompanyAddr[3])
            {
            }
            column(VendorAddr4; VendorAddr[4])
            {
            }
            column(CompAddr4; CompanyAddr[4])
            {
            }
            column(VendAddr5; VendorAddr[5])
            {
            }
            column(CompAddr5; CompanyAddr[5])
            {
            }
            column(VendAddr6; VendorAddr[6])
            {
            }
            column(CompAddr6; CompanyAddr[6])
            {
            }
            column(VendAddr7; VendorAddr[7])
            {
            }
            column(CompInfoPhoneNo; CompanyInfo."Phone No.")
            {
            }
            column(VendAddr8; VendorAddr[8])
            {
            }
            column(CompInfoFaxNo; CompanyInfo."Fax No.")
            {
            }
            column(CompInfoVATRegNo; CompanyInfo."VAT Registration No.")
            {
            }
            column(CompInfoBankName; CompanyInfo."Bank Name")
            {
            }
            column(CompInfoBankBranchNo; CompanyInfo."Bank Branch No.")
            {
            }
            column(CompInfoBankAccNo; CompanyInfo."Bank Account No.")
            {
            }
            column(VendLoopNumber; Number)
            {
            }
            column(RemittanceAdviceCaption; RemittanceAdviceCaptionLbl)
            {
            }
            column(PhoneNoCaption; PhoneNoCaptionLbl)
            {
            }
            column(FaxNoCaption; FaxNoCaptionLbl)
            {
            }
            column(VATRegNoCaption; VATRegNoCaptionLbl)
            {
            }
            column(BankCaption; BankCaptionLbl)
            {
            }
            column(SortCodeCaption; SortCodeCaptionLbl)
            {
            }
            column(AccNoCaption; AccNoCaptionLbl)
            {
            }
            column(OriginalAmtCaption; OriginalAmtCaptionLbl)
            {
            }
            column(DocDateCaption; DocumentDateCaptionLbl)
            {
            }
            column(DocNoCaption; YourDocumentNoCaptionLbl)
            {
            }
            column(DocTypeCaption; DocTypeCaptionLbl)
            {
            }
            column(CheckNoCaption; OurDocumentNoCaptionLbl)
            {
            }
            column(RemainingAmtCaption; RemainingAmountCaptionLbl)
            {
            }
            column(PmdDiscRecCaption; PmtDiscReceivedCaptionLbl)
            {
            }
            column(PaidAmtCaption; PaymentCurrAmtCaptionLbl)
            {
            }
            column(CurrCodeCaption; CurrCodeCaptionLbl)
            {
            }
            dataitem("Gen. Journal Line"; "Gen. Journal Line")
            {
                DataItemTableView = SORTING ("Journal Template Name", "Journal Batch Name", "Posting Date", "Document No.") WHERE ("Account Type" = CONST (Vendor));
                column(CheckNo; CheckNo)
                {
                }
                column(Amt_GenJournalLine; Amount)
                {
                    AutoFormatExpression = "Gen. Journal Line"."Currency Code";
                    AutoFormatType = 1;
                }
                column(CurrCode; CurrencyCode("Currency Code"))
                {
                }
                column(JnlBatchName_GenJournalLine; "Journal Batch Name")
                {
                }
                column(DocNo_GenJnlLine; "Document No.")
                {
                }
                column(AccNo_GenJournalLine; "Account No.")
                {
                }
                column(AppliestoDocType_GenJnlLine; "Applies-to Doc. Type")
                {
                }
                column(TotalCaption; TotalCaptionLbl)
                {
                }
                column(GJL_PostDate; FORMAT("Gen. Journal Line"."Posting Date", 0, '<Day,2>/<Month,2>/<Year>'))
                {
                }
                dataitem("Vendor Ledger Entry"; "Vendor Ledger Entry")
                {
                    DataItemLink = "Applies-to ID" = FIELD ("Applies-to ID"), "Vendor No." = FIELD ("Account No.");
                    DataItemTableView = SORTING ("Vendor No.", Open, Positive, "Due Date", "Currency Code") WHERE (Open = CONST (true));
                    dataitem("Detailed Vendor Ledg. Entry"; "Detailed Vendor Ledg. Entry")
                    {
                        DataItemLink = "Vendor Ledger Entry No." = FIELD ("Entry No."), "Initial Document Type" = FIELD ("Document Type");
                        DataItemTableView = SORTING ("Vendor Ledger Entry No.", "Entry Type", "Posting Date") WHERE ("Entry Type" = CONST (Application), "Document Type" = CONST ("Credit Memo"));

                        trigger OnAfterGetRecord();
                        begin
                            VendLedgEntry3.GET("Applied Vend. Ledger Entry No.");
                            if "Vendor Ledger Entry No." <> "Applied Vend. Ledger Entry No." then
                                InsertTempEntry(VendLedgEntry3);
                        end;
                    }

                    trigger OnAfterGetRecord();
                    begin
                        InsertTempEntry("Vendor Ledger Entry")
                    end;

                    trigger OnPreDataItem();
                    begin
                        if "Gen. Journal Line"."Applies-to ID" = '' then
                            CurrReport.BREAK;
                    end;
                }
                dataitem(VendLedgEntry2; "Vendor Ledger Entry")
                {
                    DataItemLink = "Document No." = FIELD ("Applies-to Doc. No."), "Vendor No." = FIELD ("Account No."), "Document Type" = FIELD ("Applies-to Doc. Type");
                    DataItemTableView = SORTING ("Vendor No.", Open, Positive, "Due Date") WHERE (Open = CONST (true));
                    dataitem(DetailVendLedgEntry2; "Detailed Vendor Ledg. Entry")
                    {
                        DataItemLink = "Vendor Ledger Entry No." = FIELD ("Entry No."), "Initial Document Type" = FIELD ("Document Type");
                        DataItemTableView = SORTING ("Vendor Ledger Entry No.", "Entry Type", "Posting Date") WHERE ("Entry Type" = CONST (Application), "Document Type" = CONST ("Credit Memo"));

                        trigger OnAfterGetRecord();
                        begin
                            VendLedgEntry3.GET("Applied Vend. Ledger Entry No.");
                            if "Vendor Ledger Entry No." <> "Applied Vend. Ledger Entry No." then
                                InsertTempEntry(VendLedgEntry3);
                        end;
                    }

                    trigger OnAfterGetRecord();
                    begin
                        InsertTempEntry(VendLedgEntry2);
                    end;
                }
                dataitem(PrintLoop; "Integer")
                {
                    DataItemTableView = SORTING (Number);
                    column(AppliedVendLedgEntryTempDocType; FORMAT(AppliedVendLedgEntryTemp."Document Type"))
                    {
                    }
                    column(AppliedVendLedgEntryTempExternalDocNo; AppliedVendLedgEntryTemp."External Document No.")
                    {
                    }
                    column(AppliedVendLedgEntryTempDocDate; FORMAT(AppliedVendLedgEntryTemp."Document Date"))
                    {
                    }
                    column(AppliedVendLedgEntryTempCurrCode; AppliedVendLedgEntryTemp."Currency Code")
                    {
                    }
                    column(AppliedVendLedgEntryTempOriginalAmt; -AppliedVendLedgEntryTemp."Original Amount")
                    {
                    }
                    column(AppliedVendLedgEntryTempRemainingAmt; -AppliedVendLedgEntryTemp."Remaining Amount")
                    {
                    }
                    column(PmdDiscRec; PmdDiscRec)
                    {
                    }
                    column(PaidAmount; PaidAmount)
                    {
                    }
                    column(PrintLoopNumber; Number)
                    {
                    }
                    column(AppliedVendLedgEntryTemp_VendorNo; AppliedVendLedgEntryTemp."Vendor No.")
                    {
                    }
                    column(AppliedVendLedgEntryTemp_Description; AppliedVendLedgEntryTemp.Description)
                    {
                    }
                    column(AppliedVendLedgEntryTemp_DocNo; AppliedVendLedgEntryTemp."Document No.")
                    {
                    }

                    trigger OnAfterGetRecord();
                    begin
                        if Number = 1 then
                            AppliedVendLedgEntryTemp.FIND('-')
                        else
                            AppliedVendLedgEntryTemp.NEXT;
                        if JnlLineRemainingAmount < 0 then
                            CurrReport.SKIP;
                        AppliedVendLedgEntryTemp.CALCFIELDS("Remaining Amount", "Original Amount");

                        // Currency
                        if AppliedVendLedgEntryTemp."Currency Code" <> "Gen. Journal Line"."Currency Code" then begin
                            AppliedVendLedgEntryTemp."Remaining Amount" :=
                            CurrExchRate.ExchangeAmtFCYToFCY(
                              "Gen. Journal Line"."Posting Date",
                              AppliedVendLedgEntryTemp."Currency Code",
                              "Gen. Journal Line"."Currency Code",
                              AppliedVendLedgEntryTemp."Remaining Amount");
                            AppliedVendLedgEntryTemp."Remaining Amount" := ROUND(AppliedVendLedgEntryTemp."Remaining Amount", AmountRoundingPrecision);

                            PmtDiscInvCurr := AppliedVendLedgEntryTemp."Remaining Pmt. Disc. Possible";
                            AppliedVendLedgEntryTemp."Remaining Pmt. Disc. Possible" :=
                            CurrExchRate.ExchangeAmtFCYToFCY(
                              "Gen. Journal Line"."Posting Date",
                              AppliedVendLedgEntryTemp."Currency Code", "Gen. Journal Line"."Currency Code",
                              AppliedVendLedgEntryTemp."Original Pmt. Disc. Possible");
                            AppliedVendLedgEntryTemp."Original Pmt. Disc. Possible" :=
                            ROUND(AppliedVendLedgEntryTemp."Original Pmt. Disc. Possible", AmountRoundingPrecision);
                        end;

                        // Payment Discount
                        if("Gen. Journal Line"."Document Type" = "Gen. Journal Line"."Document Type"::Payment) and
                           (AppliedVendLedgEntryTemp."Document Type" in
                            [AppliedVendLedgEntryTemp."Document Type"::Invoice, AppliedVendLedgEntryTemp."Document Type"::"Credit Memo"]) and
                           ("Gen. Journal Line"."Posting Date" <= AppliedVendLedgEntryTemp."Pmt. Discount Date") and
                           (ABS(AppliedVendLedgEntryTemp."Remaining Amount") >= ABS(AppliedVendLedgEntryTemp."Remaining Pmt. Disc. Possible"))
                        then
                            PmdDiscRec := AppliedVendLedgEntryTemp."Remaining Pmt. Disc. Possible"
                        else
                            PmdDiscRec := 0;

                        AppliedVendLedgEntryTemp."Remaining Amount" := AppliedVendLedgEntryTemp."Remaining Amount" - PmdDiscRec;
                        AppliedVendLedgEntryTemp."Amount to Apply" := AppliedVendLedgEntryTemp."Amount to Apply" - PmdDiscRec;

                        if AppliedVendLedgEntryTemp."Remaining Amount" > 0 then
                            if AppliedVendLedgEntryTemp."Amount to Apply" < 0 then begin
                                PaidAmount := -AppliedVendLedgEntryTemp."Amount to Apply";
                                AppliedVendLedgEntryTemp."Remaining Amount" := AppliedVendLedgEntryTemp."Remaining Amount" - PaidAmount;
                            end else begin
                                PaidAmount := -AppliedVendLedgEntryTemp."Remaining Amount";
                                AppliedVendLedgEntryTemp."Remaining Amount" := 0;
                            end
                        else begin
                            if ABS(AppliedVendLedgEntryTemp."Remaining Amount") > ABS(JnlLineRemainingAmount) then
                                if AppliedVendLedgEntryTemp."Amount to Apply" < 0 then
                                    PaidAmount := ABS(AppliedVendLedgEntryTemp."Amount to Apply")
                                else
                                    PaidAmount := ABS(JnlLineRemainingAmount)
                            else if AppliedVendLedgEntryTemp."Amount to Apply" < 0 then
                                    PaidAmount := ABS(AppliedVendLedgEntryTemp."Amount to Apply")
                                else
                                    PaidAmount := ABS(AppliedVendLedgEntryTemp."Remaining Amount");
                            AppliedVendLedgEntryTemp."Remaining Amount" := AppliedVendLedgEntryTemp."Remaining Amount" + PaidAmount;
                            JnlLineRemainingAmount := JnlLineRemainingAmount - PaidAmount;
                            if JnlLineRemainingAmount < 0 then begin
                                AppliedVendLedgEntryTemp."Remaining Amount" := AppliedVendLedgEntryTemp."Remaining Amount" + JnlLineRemainingAmount;
                                PaidAmount := PaidAmount + AppliedVendLedgEntryTemp."Remaining Amount";
                            end;
                        end;

                        // Numbers to print
                        if AppliedVendLedgEntryTemp."Currency Code" <> "Gen. Journal Line"."Currency Code" then
                            if PmdDiscRec <> 0 then
                                PmdDiscRec := PmtDiscInvCurr;
                        AppliedVendLedgEntryTemp."Remaining Amount" :=
                          CurrExchRate.ExchangeAmtFCYToFCY(
                            "Gen. Journal Line"."Posting Date",
                            "Gen. Journal Line"."Currency Code",
                            AppliedVendLedgEntryTemp."Currency Code",
                            AppliedVendLedgEntryTemp."Remaining Amount");
                    end;

                    trigger OnPostDataItem();
                    begin
                        AppliedVendLedgEntryTemp.DELETEALL;
                    end;

                    trigger OnPreDataItem();
                    begin
                        SETRANGE(Number, 1, AppliedVendLedgEntryTemp.COUNT);
                        JnlLineRemainingAmount := JnlLineRemainingAmount + AppliedDebitAmounts;
                    end;
                }

                trigger OnAfterGetRecord();
                begin
                    if "Document No." <> CheckNo then begin
                        JnlLineRemainingAmount := 0;
                        AppliedDebitAmounts := 0;
                    end;

                    CheckNo := "Document No.";
                    JnlLineRemainingAmount := JnlLineRemainingAmount + Amount;

                    FindAmountRounding;
                    AppliedDebitAmounts := 0;
                end;

                trigger OnPreDataItem();
                begin
                    COPYFILTERS(FindVendors);
                    CurrReport.CREATETOTALS("Gen. Journal Line".Amount);
                    SETRANGE("Account No.", VendTemp."No.");
                end;
            }

            trigger OnAfterGetRecord();
            begin
                if Number = 1 then
                    VendTemp.FIND('-')
                else
                    VendTemp.NEXT;

                FormatAddr.Vendor(VendorAddr, VendTemp);

                if VendTemp.Contact = VendorAddr[1] then
                    VendorAddr[1] := '';  ///M1 to remove contact data if present

                JnlLineRemainingAmount := 0;
            end;

            trigger OnPreDataItem();
            begin
                VendTemp.COPYFILTERS(Vendor);
                SETRANGE(Number, 1, VendTemp.COUNT);
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
        FormatAddr.Company(CompanyAddr, CompanyInfo);
        GLSetup.GET;
    end;

    var
        GLSetup: Record "General Ledger Setup";
        CompanyInfo: Record "Company Information";
        Vend: Record Vendor;
        VendTemp: Record Vendor temporary;
        AppliedVendLedgEntryTemp: Record "Vendor Ledger Entry" temporary;
        CurrExchRate: Record "Currency Exchange Rate";
        Currency: Record Currency;
        VendLedgEntry3: Record "Vendor Ledger Entry";
        FormatAddr: Codeunit "Format Address";
        JnlLineRemainingAmount: Decimal;
        AmountRoundingPrecision: Decimal;
        PmdDiscRec: Decimal;
        PmtDiscInvCurr: Decimal;
        PaidAmount: Decimal;
        AppliedDebitAmounts: Decimal;
        VendorAddr: array[8] of Text[50];
        CompanyAddr: array[8] of Text[50];
        CheckNo: Code[20];
        RemittanceAdviceCaptionLbl: TextConst ELL = 'Ένταλμα Πληρωμής', ENU = 'Remittance Advice', ENG = 'Remittance Advice';
        PhoneNoCaptionLbl: TextConst ELL = 'Τηλέφωνο', ENU = 'Phone No.', ENG = 'Phone No.';
        FaxNoCaptionLbl: TextConst ELL = 'Fax', ENU = 'Fax No.', ENG = 'Fax No.';
        VATRegNoCaptionLbl: TextConst ELL = 'ΑΦΜ', ENU = 'VAT Reg. No.', ENG = 'VAT Reg. No.';
        BankCaptionLbl: TextConst ELL = 'Τράπεζα', ENU = 'Bank', ENG = 'Bank';
        SortCodeCaptionLbl: TextConst ELL = 'Υποκατάστημα', ENU = 'Sort Code', ENG = 'Sort Code';
        AccNoCaptionLbl: TextConst ELL = 'Λογαριασμός', ENU = 'Account No.', ENG = 'Account No.';
        OriginalAmtCaptionLbl: TextConst ENU = 'Original Amount', ENG = 'Original Amount';
        DocumentDateCaptionLbl: TextConst ENU = 'Document Date', ENG = 'Document Date';
        YourDocumentNoCaptionLbl: TextConst ENU = 'Your Document No.', ENG = 'Your Document No.';
        DocTypeCaptionLbl: TextConst ENU = 'Doc. Type', ENG = 'Doc. Type';
        OurDocumentNoCaptionLbl: TextConst ENU = 'Our Document No.', ENG = 'Our Document No.';
        RemainingAmountCaptionLbl: TextConst ENU = 'Remaining Amount', ENG = 'Remaining Amount';
        PmtDiscReceivedCaptionLbl: TextConst ENU = 'Pmt. Disc. Received', ENG = 'Pmt. Disc. Received';
        PaymentCurrAmtCaptionLbl: TextConst ENU = 'Payment Curr. Amount', ENG = 'Payment Curr. Amount';
        CurrCodeCaptionLbl: TextConst ENU = 'Curr. Code', ENG = 'Curr. Code';
        TotalCaptionLbl: TextConst ELL = 'Σύνολο', ENU = 'Total', ENG = 'Total';

    local procedure CurrencyCode(SrcCurrCode: Code[10]): Code[10];
    begin
        if SrcCurrCode = '' then
            exit(GLSetup."LCY Code");

        exit(SrcCurrCode);
    end;

    local procedure FindAmountRounding();
    begin
        if "Gen. Journal Line"."Currency Code" = '' then begin
            Currency.INIT;
            Currency.Code := '';
            Currency.InitRoundingPrecision;
        end else if "Gen. Journal Line"."Currency Code" <> Currency.Code then
                Currency.GET("Gen. Journal Line"."Currency Code");

        AmountRoundingPrecision := Currency."Amount Rounding Precision";
    end;

    local procedure InsertTempEntry(VendLedgEntryToInsert: Record "Vendor Ledger Entry");
    var
        AppAmt: Decimal;
    begin
        AppliedVendLedgEntryTemp := VendLedgEntryToInsert;
        if AppliedVendLedgEntryTemp.INSERT then begin
            // Find Debit amounts, e.g. credit memos
            AppliedVendLedgEntryTemp.CALCFIELDS("Remaining Amt. (LCY)");
            if AppliedVendLedgEntryTemp."Remaining Amt. (LCY)" > 0 then begin
                AppAmt := AppliedVendLedgEntryTemp."Remaining Amt. (LCY)";
                if "Gen. Journal Line"."Currency Code" <> '' then begin
                    AppAmt :=
                    CurrExchRate.ExchangeAmtLCYToFCY(
                      "Gen. Journal Line"."Posting Date",
                      "Gen. Journal Line"."Currency Code",
                      AppAmt,
                      "Gen. Journal Line"."Currency Factor");
                    AppAmt := ROUND(AppAmt, AmountRoundingPrecision);
                end;
                AppliedDebitAmounts := AppliedDebitAmounts + AppAmt;
            end;
        end;
    end;
}

