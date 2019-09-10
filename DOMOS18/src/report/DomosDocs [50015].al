report 50015 "Domos Docs"
{
    // version NAVGR9.00,IMP

    // [GR = Greek Localization]
    // //DOC IMP DB 15/09/16 - Changes during implementation
    // //DOC ISO DB 25/03/18 - Added ISO Logo
    DefaultLayout = RDLC;
    RDLCLayout = 'src\report\Domos Docs.rdlc';

    CaptionML = ELL='Παραστατικά Πωλήσεων/Αγορών/Τεχνικής Υποστήριξης/Ενδοδιακινήσεων',
                ENU='Sales/Purchase/Service/Transfer Documents';
    Permissions = TableData "Sales Header"=rm,
                  TableData "Purchase Header"=rm,
                  TableData "Sales Shipment Header"=rm,
                  TableData "Sales Invoice Header"=rm,
                  TableData "Sales Cr.Memo Header"=rm,
                  TableData "Purch. Rcpt. Header"=rm,
                  TableData "Purch. Inv. Header"=rm,
                  TableData "Purch. Cr. Memo Hdr."=rm,
                  TableData "Transfer Header"=rm,
                  TableData "Transfer Shipment Header"=rm,
                  TableData "Transfer Receipt Header"=rm,
                  TableData "Service Header"=rm,
                  TableData "Service Shipment Header"=rm,
                  TableData "Service Invoice Header"=rm,
                  TableData "Service Cr.Memo Header"=rm,
                  TableData "Return Shipment Header"=rm,
                  TableData "Return Receipt Header"=rm,
                  TableData "Service Return Receipt Header"=rm;

    dataset
    {
        dataitem("Sales Header";"Sales Header")
        {
            DataItemTableView = SORTING("Document Type","No.") ORDER(Ascending);

            trigger OnAfterGetRecord();
            begin
                DocManagment.CopyFromSalesHeader("Sales Header",TmpDocumentHeader,TmpDocumentLine,ReportNumber);
                DocManagment.GetBailments(BailmentLines);
                //DOC IMP DB 15/09/16 -
                IF TmpDocumentHeader."Location Code"='ΝΕΟΧΩΡ' THEN BEGIN
                  CompanyAddress[7] := CompanyInfo.FIELDCAPTION("VAT Registration No.") + ': ' + CompanyInfo."VAT Registration No." + ', ' +
                                       CompanyInfo.FIELDCAPTION("Tax Office") + ': ' + CompanyInfo."Tax Office";
                  CompanyAddress[2] := CompanyInfo.FIELDCAPTION("E-Mail") + ': ' + CompanyInfo."E-Mail";
                  CompanyAddress[3] := CompanyInfo.FIELDCAPTION("Phone No.") + ': ' + CompanyInfo."Phone No." + ', ' +
                                       CompanyInfo.FIELDCAPTION("Fax No.") + ': ' + CompanyInfo."Fax No.";
                  CompanyAddress[5] := 'ΥΠΟΚΑΤΑΣΤΗΜΑ: ' +CompanyInfo."Branch 1 Address";
                  CompanyAddress[6] := 'ΕΔΡΑ: '+CompanyInfo.Address + ', ' + CompanyInfo."Address 2";
                  CompanyAddress[4] := CompanyInfo.City + ', '  + CompanyInfo."Post Code";
                  CompanyAddress[8] := CompanyInfo.FIELDCAPTION("Registration No.") + ': ' + CompanyInfo."Registration No.";
                END;
                //DOC IMP DB 15/09/16 +
                IF NOT CurrReport.PREVIEW THEN BEGIN
                  "No. Printed" += 1;
                  MODIFY;
                  COMMIT;
                END;
            end;

            trigger OnPreDataItem();
            begin
                IF DocumentType = DocumentType::"Sales Order" THEN BEGIN
                  SETRANGE("Document Type","Document Type"::Order);
                  SETFILTER("No.",DocumentNo);
                END;
                IF GETFILTERS = '' THEN BEGIN
                  CurrReport.BREAK;
                END;
            end;
        }
        dataitem("Sales Invoice Header";"Sales Invoice Header")
        {
            DataItemTableView = SORTING("Sell-to Customer No.") ORDER(Ascending);

            trigger OnAfterGetRecord();
            begin
                DocManagment.CopyFromSalesInvoice("Sales Invoice Header",TmpDocumentHeader,TmpDocumentLine,ReportNumber);
                DocManagment.GetBailments(BailmentLines);
                IF NOT CurrReport.PREVIEW THEN BEGIN
                  "No. Printed" += 1;
                  MODIFY;
                  COMMIT;
                END;
            end;

            trigger OnPreDataItem();
            begin
                IF DocumentType = DocumentType::"Sales Invoice" THEN BEGIN
                  SETFILTER("No.",DocumentNo);
                END;
                IF GETFILTERS = '' THEN BEGIN
                  CurrReport.BREAK;
                END;
            end;
        }
        dataitem("Sales Shipment Header";"Sales Shipment Header")
        {
            DataItemTableView = SORTING("No.") ORDER(Ascending);

            trigger OnAfterGetRecord();
            begin
                DocManagment.CopyFromSalesShipment("Sales Shipment Header",TmpDocumentHeader,TmpDocumentLine,ReportNumber);
                DocManagment.GetBailments(BailmentLines);
                IF NOT CurrReport.PREVIEW THEN BEGIN
                  "No. Printed" += 1;
                  MODIFY;
                  COMMIT;
                END;
            end;

            trigger OnPreDataItem();
            begin
                IF DocumentType = DocumentType::"Sales Shipment" THEN BEGIN
                  SETFILTER("No.",DocumentNo);
                END;
                IF GETFILTERS = '' THEN BEGIN
                  CurrReport.BREAK;
                END;
            end;
        }
        dataitem("Sales Cr.Memo Header";"Sales Cr.Memo Header")
        {
            DataItemTableView = SORTING("No.") ORDER(Ascending);

            trigger OnAfterGetRecord();
            begin
                DocManagment.CopyFromSalesCreditMemo("Sales Cr.Memo Header",TmpDocumentHeader,TmpDocumentLine,ReportNumber);
                DocManagment.GetBailments(BailmentLines);
                IF NOT CurrReport.PREVIEW THEN BEGIN
                  "No. Printed" += 1;
                  MODIFY;
                  COMMIT;
                END;
            end;

            trigger OnPreDataItem();
            begin
                IF DocumentType = DocumentType::"Sales Credit Memo" THEN BEGIN
                  SETFILTER("No.",DocumentNo);
                END;
                IF GETFILTERS = '' THEN BEGIN
                  CurrReport.BREAK;
                END;
            end;
        }
        dataitem("Return Receipt Header";"Return Receipt Header")
        {
            DataItemTableView = SORTING("No.") ORDER(Ascending);

            trigger OnAfterGetRecord();
            begin
                DocManagment.CopyFromSalesReturnReceipt("Return Receipt Header",TmpDocumentHeader,TmpDocumentLine,ReportNumber);
                DocManagment.GetBailments(BailmentLines);
                IF NOT CurrReport.PREVIEW THEN BEGIN
                  "No. Printed" += 1;
                  MODIFY;
                  COMMIT;
                END;
            end;

            trigger OnPreDataItem();
            begin
                IF DocumentType = DocumentType::"Return Receipt" THEN BEGIN
                  SETFILTER("No.",DocumentNo);
                END;
                IF GETFILTERS = '' THEN BEGIN
                  CurrReport.BREAK;
                END;
            end;
        }
        dataitem("Purchase Header";"Purchase Header")
        {
            DataItemTableView = SORTING("Document Type","No.") ORDER(Ascending);

            trigger OnAfterGetRecord();
            begin
                DocManagment.CopyFromPurchHeader("Purchase Header",TmpDocumentHeader,TmpDocumentLine,ReportNumber);
                IF NOT CurrReport.PREVIEW THEN BEGIN
                  "No. Printed" += 1;
                  MODIFY;
                  COMMIT;
                END;
            end;

            trigger OnPreDataItem();
            begin
                IF DocumentType = DocumentType::"Purchase Order" THEN BEGIN
                  SETRANGE("Document Type" , "Document Type"::Order);
                  SETFILTER("No.",DocumentNo);
                END;
                IF GETFILTERS = '' THEN BEGIN
                  CurrReport.BREAK;
                END;
            end;
        }
        dataitem("Purch. Inv. Header";"Purch. Inv. Header")
        {
            DataItemTableView = SORTING("No.") ORDER(Ascending);

            trigger OnAfterGetRecord();
            begin
                DocManagment.CopyFromPurchInvoice("Purch. Inv. Header",TmpDocumentHeader,TmpDocumentLine,ReportNumber);
                IF NOT CurrReport.PREVIEW THEN BEGIN
                  "No. Printed" += 1;
                  MODIFY;
                  COMMIT;
                END;
            end;

            trigger OnPreDataItem();
            begin
                IF DocumentType = DocumentType::"Purchase Invoice" THEN BEGIN
                  SETFILTER("No.",DocumentNo);
                END;
                IF GETFILTERS = '' THEN BEGIN
                  CurrReport.BREAK;
                END;
            end;
        }
        dataitem("Purch. Rcpt. Header";"Purch. Rcpt. Header")
        {
            DataItemTableView = SORTING("No.") ORDER(Ascending);

            trigger OnAfterGetRecord();
            begin
                DocManagment.CopyFromPurchReceipt("Purch. Rcpt. Header",TmpDocumentHeader,TmpDocumentLine,ReportNumber);
                IF NOT CurrReport.PREVIEW THEN BEGIN
                  "No. Printed" += 1;
                  MODIFY;
                  COMMIT;
                END;
            end;

            trigger OnPreDataItem();
            begin
                IF DocumentType = DocumentType::"Purchase Receipt" THEN BEGIN
                  SETFILTER("No.",DocumentNo);
                END;
                IF GETFILTERS = '' THEN BEGIN
                  CurrReport.BREAK;
                END;
            end;
        }
        dataitem("Purch. Cr. Memo Hdr.";"Purch. Cr. Memo Hdr.")
        {
            DataItemTableView = SORTING("No.") ORDER(Ascending);

            trigger OnAfterGetRecord();
            begin
                DocManagment.CopyFromPurchCreditMemo("Purch. Cr. Memo Hdr.",TmpDocumentHeader,TmpDocumentLine,ReportNumber);
                IF NOT CurrReport.PREVIEW THEN BEGIN
                  "No. Printed" += 1;
                  MODIFY;
                  COMMIT;
                END;
            end;

            trigger OnPreDataItem();
            begin
                IF DocumentType = DocumentType::"Purchase Credit Memo" THEN BEGIN
                  SETFILTER("No.",DocumentNo);
                END;
                IF GETFILTERS = '' THEN BEGIN
                  CurrReport.BREAK;
                END;
            end;
        }
        dataitem("Return Shipment Header";"Return Shipment Header")
        {
            DataItemTableView = SORTING("No.") ORDER(Ascending);

            trigger OnAfterGetRecord();
            begin
                DocManagment.CopyFromPurchReturnShipment("Return Shipment Header",TmpDocumentHeader,TmpDocumentLine,ReportNumber);
                IF NOT CurrReport.PREVIEW THEN BEGIN
                  "No. Printed" += 1;
                  MODIFY;
                  COMMIT;
                END;
            end;

            trigger OnPreDataItem();
            begin
                IF DocumentType = DocumentType::"Return Shipment" THEN BEGIN
                  SETFILTER("No.",DocumentNo);
                END;
                IF GETFILTERS = '' THEN BEGIN
                  CurrReport.BREAK;
                END;
            end;
        }
        dataitem("Service Header";"Service Header")
        {
            DataItemTableView = SORTING("Document Type","No.") ORDER(Ascending);

            trigger OnAfterGetRecord();
            begin
                DocManagment.CopyFromServiceHeader("Service Header",TmpDocumentHeader,TmpDocumentLine,ReportNumber);
                IF NOT CurrReport.PREVIEW THEN BEGIN
                  "No. Printed" += 1;
                  MODIFY;
                  COMMIT;
                END;
            end;

            trigger OnPreDataItem();
            begin
                IF DocumentType = DocumentType::"Service Order" THEN BEGIN
                  SETRANGE("Document Type","Document Type"::Order);
                  SETFILTER("No.",DocumentNo);
                END;
                IF GETFILTERS = '' THEN BEGIN
                  CurrReport.BREAK;
                END;
            end;
        }
        dataitem("Service Invoice Header";"Service Invoice Header")
        {
            DataItemTableView = SORTING("No.") ORDER(Ascending);

            trigger OnAfterGetRecord();
            begin
                DocManagment.CopyFromServiceInvoice("Service Invoice Header",TmpDocumentHeader,TmpDocumentLine,ReportNumber);
                IF NOT CurrReport.PREVIEW THEN BEGIN
                  "No. Printed" += 1;
                  MODIFY;
                  COMMIT;
                END;
            end;

            trigger OnPreDataItem();
            begin
                IF DocumentType = DocumentType::"Service Invoice" THEN BEGIN
                  SETFILTER("No.",DocumentNo);
                END;
                IF GETFILTERS = '' THEN BEGIN
                  CurrReport.BREAK;
                END;
            end;
        }
        dataitem("Service Shipment Header";"Service Shipment Header")
        {
            DataItemTableView = SORTING("No.") ORDER(Ascending);

            trigger OnAfterGetRecord();
            begin
                DocManagment.CopyFromServiceShipment("Service Shipment Header",TmpDocumentHeader,TmpDocumentLine,ReportNumber);
                IF NOT CurrReport.PREVIEW THEN BEGIN
                  "No. Printed" += 1;
                  MODIFY;
                  COMMIT;
                END;
            end;

            trigger OnPreDataItem();
            begin
                IF DocumentType = DocumentType::"Service Shipment" THEN BEGIN
                  SETFILTER("No.",DocumentNo);
                END;
                IF GETFILTERS = '' THEN BEGIN
                  CurrReport.BREAK;
                END;
            end;
        }
        dataitem("Service Cr.Memo Header";"Service Cr.Memo Header")
        {
            DataItemTableView = SORTING("No.") ORDER(Ascending);

            trigger OnAfterGetRecord();
            begin
                DocManagment.CopyFromServiceCreditMemo("Service Cr.Memo Header",TmpDocumentHeader,TmpDocumentLine,ReportNumber);
                IF NOT CurrReport.PREVIEW THEN BEGIN
                  "No. Printed" += 1;
                  MODIFY;
                  COMMIT;
                END;
            end;

            trigger OnPreDataItem();
            begin
                IF DocumentType = DocumentType::"Service Credit Memo" THEN BEGIN
                  SETFILTER("No.",DocumentNo);
                END;
                IF GETFILTERS = '' THEN BEGIN
                  CurrReport.BREAK;
                END;
            end;
        }
        dataitem("Service Return Receipt Header";"Service Return Receipt Header")
        {
            DataItemTableView = SORTING("No.") ORDER(Ascending);

            trigger OnAfterGetRecord();
            begin
                DocManagment.CopyFromServiceReturnReceipt("Service Return Receipt Header",TmpDocumentHeader,TmpDocumentLine,ReportNumber);
                IF NOT CurrReport.PREVIEW THEN BEGIN
                  "No. Printed" += 1;
                  MODIFY;
                  COMMIT;
                END;
            end;

            trigger OnPreDataItem();
            begin
                IF DocumentType = DocumentType::"Service Return Receipt" THEN BEGIN
                  SETFILTER("No.",DocumentNo);
                END;
                IF GETFILTERS = '' THEN BEGIN
                  CurrReport.BREAK;
                END;
            end;
        }
        dataitem("Transfer Header";"Transfer Header")
        {
            DataItemTableView = SORTING("No.") ORDER(Ascending);

            trigger OnAfterGetRecord();
            begin
                DocManagment.CopyFromTransferOrder("Transfer Header",TmpDocumentHeader,TmpDocumentLine,ReportNumber);
            end;

            trigger OnPreDataItem();
            begin
                IF DocumentType = DocumentType::"Transfer Order" THEN BEGIN
                  SETFILTER("No.",DocumentNo);
                END;
                IF GETFILTERS = '' THEN BEGIN
                  CurrReport.BREAK;
                END;
            end;
        }
        dataitem("Transfer Shipment Header";"Transfer Shipment Header")
        {
            DataItemTableView = SORTING("No.") ORDER(Ascending);

            trigger OnAfterGetRecord();
            begin
                DocManagment.CopyFromTransferShipment("Transfer Shipment Header",TmpDocumentHeader,TmpDocumentLine,ReportNumber);
            end;

            trigger OnPreDataItem();
            begin
                IF DocumentType = DocumentType::"Transfer Shipment" THEN BEGIN
                  SETFILTER("No.",DocumentNo);
                END;
                IF GETFILTERS = '' THEN BEGIN
                  CurrReport.BREAK;
                END;
            end;
        }
        dataitem("Transfer Receipt Header";"Transfer Receipt Header")
        {
            DataItemTableView = SORTING("No.") ORDER(Ascending);

            trigger OnAfterGetRecord();
            begin
                DocManagment.CopyFromTransferReceipt("Transfer Receipt Header",TmpDocumentHeader,TmpDocumentLine,ReportNumber);
            end;

            trigger OnPreDataItem();
            begin
                IF DocumentType = DocumentType::"Transfer Receipt" THEN BEGIN
                  SETFILTER("No.",DocumentNo);
                END;
                IF GETFILTERS = '' THEN BEGIN
                  CurrReport.BREAK;
                END;
            end;
        }
        dataitem(HeaderLoop;"Integer")
        {
            DataItemTableView = SORTING(Number) ORDER(Ascending);
            column(IsTransfer;IsTransfer)
            {
            }
            dataitem(CopyLoop;"Integer")
            {
                DataItemTableView = SORTING(Number) ORDER(Ascending);
                dataitem(DocumentLoop;"Integer")
                {
                    DataItemTableView = SORTING(Number) ORDER(Ascending) WHERE(Number=CONST(1));
                    column(TmpDocumentHeader__Document_No__;TmpDocumentHeader."Document No.")
                    {
                    }
                    column(TmpDocumentHeader__No__Series_Description_;TmpDocumentHeader."No. Series Description")
                    {
                    }
                    column(TmpDocumentHeader__No__;TmpDocumentHeader."No.")
                    {
                    }
                    column(TmpDocumentHeader_Name;TmpDocumentHeader.Name)
                    {
                    }
                    column(TmpDocumentHeader__Tax_Office_;TmpDocumentHeader."Tax Office")
                    {
                    }
                    column(TmpDocumentHeader_Address;TmpDocumentHeader.Address)
                    {
                    }
                    column(TmpDocumentHeader_City______TmpDocumentHeader__Post_Code_;TmpDocumentHeader.City+ ','+TmpDocumentHeader."Post Code")
                    {
                    }
                    column(TmpDocumentHeader__Vat_Registration_No__;TmpDocumentHeader."Vat Registration No.")
                    {
                    }
                    column(TmpDocumentHeader__Posting_Date_;TmpDocumentHeader."Posting Date")
                    {
                    }
                    column(TmpDocumentHeader__Posting_Time_;TmpDocumentHeader."Posting Time")
                    {
                    }
                    column(TmpDocumentHeader_Profession;TmpDocumentHeader.Profession)
                    {
                    }
                    column(CompanyAddress_1_;CompanyAddress[1])
                    {
                    }
                    column(CompanyAddress_2_;CompanyAddress[2])
                    {
                    }
                    column(CompanyAddress_3_;CompanyAddress[3])
                    {
                    }
                    column(CompanyAddress_4_;CompanyAddress[4])
                    {
                    }
                    column(CompanyAddress_5_;CompanyAddress[5])
                    {
                    }
                    column(CompanyInfo_Picture;CompanyInfo.Picture)
                    {
                    }
                    column(CompanyAddress_6_;CompanyAddress[6])
                    {
                    }
                    column(TmpDocumentHeader__Location_Address_;TmpDocumentHeader."Location Address")
                    {
                    }
                    column(TmpDocumentHeader__Ship_To_Address_;TmpDocumentHeader."Ship-To Address")
                    {
                    }
                    column(TmpDocumentHeader__Ship_To_City_______TmpDocumentHeader__Ship_To_Post_Code_;TmpDocumentHeader."Ship-To City"+ ','+TmpDocumentHeader."Ship-To Post Code")
                    {
                    }
                    column(TmpDocumentHeader__Ship_To_Name_;TmpDocumentHeader."Ship-To Name")
                    {
                    }
                    column(TmpDocumentHeader__Transfer_Reason_;TmpDocumentHeader."Transfer Reason")
                    {
                    }
                    column(TmpDocumentHeader__Payment_Method_;TmpDocumentHeader."Payment Method")
                    {
                    }
                    column(NumberOfPages;FORMAT(NumberOfPages))
                    {
                    }
                    column(CompanyAddress_10_;CompanyAddress[10])
                    {
                    }
                    column(CompanyAddress_9_;CompanyAddress[9])
                    {
                    }
                    column(CompanyAddress_8_;CompanyAddress[8])
                    {
                    }
                    column(CompanyAddress_7_;CompanyAddress[7])
                    {
                        Description = 'RCGP5620-0 Added';
                    }
                    column(TmpDocumentHeader__Document_No___Control1103201061;TmpDocumentHeader."Document No.")
                    {
                    }
                    column(TmpDocumentHeader__No__Series_Description__Control1103201072;TmpDocumentHeader."No. Series Description")
                    {
                    }
                    column(TmpDocumentHeader__Posting_Date__Control1103201134;TmpDocumentHeader."Posting Date")
                    {
                    }
                    column(TmpDocumentHeader__Posting_Time__Control1103201138;TmpDocumentHeader."Posting Time")
                    {
                    }
                    column(CompanyAddress_1__Control1103201148;CompanyAddress[1])
                    {
                    }
                    column(CompanyAddress_2__Control1103201155;CompanyAddress[2])
                    {
                    }
                    column(CompanyAddress_3__Control1103201156;CompanyAddress[3])
                    {
                    }
                    column(CompanyAddress_4__Control1103201157;CompanyAddress[4])
                    {
                    }
                    column(CompanyAddress_5__Control1103201158;CompanyAddress[5])
                    {
                    }
                    column(CompanyInfo_Picture_Control1103201210;CompanyInfo.Picture)
                    {
                    }
                    column(CompanyInfo_ISO_Logo;CompanyInfo."ISO Logo")
                    {
                    }
                    column(CompanyAddress_6__Control1103201211;CompanyAddress[6])
                    {
                    }
                    column(PageNo___FORMAT_NumberOfCurrentPage__________FORMAT_NumberOfPages__Control1103201243;PageNo + FORMAT(NumberOfCurrentPage) + '/' + FORMAT(NumberOfPages))
                    {
                    }
                    column(CompanyAddress_10__Control1103201245;CompanyAddress[10])
                    {
                    }
                    column(CompanyAddress_9__Control1103201248;CompanyAddress[9])
                    {
                    }
                    column(CompanyAddress_8__Control1103201249;CompanyAddress[8])
                    {
                    }
                    column(CompanyAddress_7__Control1103201250;CompanyAddress[7])
                    {
                        Description = 'RCGP5620-0 Added';
                    }
                    column(TmpDocumentHeader_Name_Control1103201267;TmpDocumentHeader.Name)
                    {
                    }
                    column(TmpDocumentHeader_Address_Control1103201276;TmpDocumentHeader.Address)
                    {
                    }
                    column(TmpDocumentHeader_City_________TmpDocumentHeader__Post_Code_;TmpDocumentHeader.City + ',' + TmpDocumentHeader."Post Code")
                    {
                    }
                    column(TmpDocumentHeader_Profession_Control1103201286;TmpDocumentHeader.Profession)
                    {
                    }
                    column(TmpDocumentHeader__Vat_Registration_No___Control1103201298;TmpDocumentHeader."Vat Registration No.")
                    {
                    }
                    column(TmpDocumentHeader__Ship_To_Tax_Office_;TmpDocumentHeader."Ship-To Tax Office")
                    {
                    }
                    column(TmpDocumentHeader__Tax_Office__Control1103201305;TmpDocumentHeader."Tax Office")
                    {
                    }
                    column(TmpDocumentHeader__Ship_To_Vat_Registration_No__;TmpDocumentHeader."Ship-To Vat Registration No.")
                    {
                    }
                    column(TmpDocumentHeader__Ship_To_Profession_;TmpDocumentHeader."Ship-To Profession")
                    {
                    }
                    column(TmpDocumentHeader__Ship_To_City__________TmpDocumentHeader__Ship_To_Post_Code_;TmpDocumentHeader."Ship-To City" + ',' + TmpDocumentHeader."Ship-To Post Code")
                    {
                    }
                    column(TmpDocumentHeader__Ship_To_Address__Control1103201313;TmpDocumentHeader."Ship-To Address")
                    {
                    }
                    column(TmpDocumentHeader__Ship_To_Name__Control1103201315;TmpDocumentHeader."Ship-To Name")
                    {
                    }
                    column(TmpDocumentHeader__Ship_To_Code_;TmpDocumentHeader."Ship-To Code")
                    {
                    }
                    column(TmpDocumentHeader__No___Control1103201264;TmpDocumentHeader."No.")
                    {
                    }
                    column(TmpDocumentHeader__Location_Address__Control1103201190;TmpDocumentHeader."Location Address")
                    {
                    }
                    column(TmpDocumentHeader__Transfer_Reason__Control1103201193;TmpDocumentHeader."Transfer Reason")
                    {
                    }
                    column(TempFooterDocumentHeader__Signature_String_1_;TempFooterDocumentHeader."Signature String 1")
                    {
                    }
                    column(TempFooterDocumentHeader__Document_Amount_;TempFooterDocumentHeader."Document Amount")
                    {
                    }
                    column(TempFooterDocumentHeader__Document_Discount_Amount_;TempFooterDocumentHeader."Document Discount Amount")
                    {
                    }
                    column(TempFooterDocumentHeader__Document_Amount_After_Discount_;TempFooterDocumentHeader."Document Amount After Discount")
                    {
                    }
                    column(TempFooterDocumentHeader__Document_VAT_Amount_;TempFooterDocumentHeader."Document VAT Amount")
                    {
                    }
                    column(TempFooterDocumentHeader__Document_Charges_Amount_;TempFooterDocumentHeader."Document Charges Amount")
                    {
                    }
                    column(TempFooterDocumentHeader__Document_Charges_VAT_;TempFooterDocumentHeader."Document Charges VAT")
                    {
                    }
                    column(TempFooterDocumentHeader__Document_Amount_Inc__VAT_;TempFooterDocumentHeader."Document Amount Inc. VAT")
                    {
                    }
                    column(TempFooterDocumentHeader__VAT_Cat__1_;TempFooterDocumentHeader."VAT Cat. 1")
                    {
                    }
                    column(TempFooterDocumentHeader__VAT_Cat__1_net_Amount_;TempFooterDocumentHeader."VAT Cat. 1 net Amount")
                    {
                    }
                    column(TempFooterDocumentHeader__VAT_Cat__1__VAT_Amount_;TempFooterDocumentHeader."VAT Cat. 1  VAT Amount")
                    {
                    }
                    column(TempFooterDocumentHeader__VAT_Cat__2_;TempFooterDocumentHeader."VAT Cat. 2")
                    {
                    }
                    column(TempFooterDocumentHeader__VAT_Cat__2_net_Amount_;TempFooterDocumentHeader."VAT Cat. 2 net Amount")
                    {
                    }
                    column(TempFooterDocumentHeader__VAT_Cat__2__VAT_Amount_;TempFooterDocumentHeader."VAT Cat. 2  VAT Amount")
                    {
                    }
                    column(TempFooterDocumentHeader__VAT_Cat__3_;TempFooterDocumentHeader."VAT Cat. 3")
                    {
                    }
                    column(TempFooterDocumentHeader__VAT_Cat__3_net_Amount_;TempFooterDocumentHeader."VAT Cat. 3 net Amount")
                    {
                    }
                    column(TempFooterDocumentHeader__VAT_Cat__3__VAT_Amount_;TempFooterDocumentHeader."VAT Cat. 3  VAT Amount")
                    {
                    }
                    column(TempFooterDocumentHeader__VAT_Cat__4_;TempFooterDocumentHeader."VAT Cat. 4")
                    {
                    }
                    column(TempFooterDocumentHeader__VAT_Cat__4_net_Amount_;TempFooterDocumentHeader."VAT Cat. 4 net Amount")
                    {
                    }
                    column(TempFooterDocumentHeader__VAT_Cat__4__VAT_Amount_;TempFooterDocumentHeader."VAT Cat. 4  VAT Amount")
                    {
                    }
                    column(TempFooterDocumentHeader__VAT_Cat__5_;TempFooterDocumentHeader."VAT Cat. 5")
                    {
                    }
                    column(TempFooterDocumentHeader__VAT_Cat__5_net_Amount_;TempFooterDocumentHeader."VAT Cat. 5 net Amount")
                    {
                    }
                    column(TempFooterDocumentHeader__VAT_Cat__5__VAT_Amount_;TempFooterDocumentHeader."VAT Cat. 5  VAT Amount")
                    {
                    }
                    column(TempFooterDocumentHeader_Invoice_Discount_Amount_;TempFooterDocumentHeader."Invoice Discount Amount")
                    {
                    }
                    column(TempFooterDocumentHeader__Signature_String_2_;TempFooterDocumentHeader."Signature String 2")
                    {
                    }
                    column(StdComment1;StdComment1)
                    {
                    }
                    column(StdComment2;StdComment2)
                    {
                    }
                    column(StdComment3;StdComment3)
                    {
                    }
                    column(StdComment4;StdComment4)
                    {
                    }
                    column(StdComment5;StdComment5)
                    {
                    }
                    column(StdComment6;StdComment6)
                    {
                    }
                    column(CopyDescription;CopyDescription)
                    {
                    }
                    column(TempFooterDocumentHeader__Old_Balance_;TempFooterDocumentHeader."Old Balance")
                    {
                    }
                    column(TempFooterDocumentHeader__New_Balance_;TempFooterDocumentHeader."New Balance")
                    {
                    }
                    column(TempFooterDocumentHeader__Comments_01_;TempFooterDocumentHeader."Comments 01")
                    {
                    }
                    column(TempFooterDocumentHeader__Comments_02_;TempFooterDocumentHeader."Comments 02")
                    {
                    }
                    column(TempFooterDocumentHeader__Comments_03_;TempFooterDocumentHeader."Comments 03")
                    {
                    }
                    column(TempFooterDocumentHeader__Comments_04_;TempFooterDocumentHeader."Comments 04")
                    {
                    }
                    column(TempFooterDocumentHeader__Comments_05_;TempFooterDocumentHeader."Comments 05")
                    {
                    }
                    column(TempFooterDocumentHeader__Document_Tax_VAT_Amount_;TempFooterDocumentHeader."Document Tax VAT Amount")
                    {
                    }
                    column(TempFooterDocumentHeader__Document_Tax_Amount_;TempFooterDocumentHeader."Document Tax Amount")
                    {
                    }
                    column(InvDiscountAmount;TempFooterDocumentHeader."Invoice Discount Amount")
                    {
                    }
                    column(CompanyInfo__Bank_Name____________CompanyInfo__Bank_Account_No__;CompanyInfo."Bank Name" + '   ' + CompanyInfo."Bank Account No.")
                    {
                    }
                    column(CompanyInfo__Bank_Name_2____________CompanyInfo__Bank_Account_No__2_;CompanyInfo."Bank Name 2" + '   ' + CompanyInfo."Bank Account No. 2")
                    {
                    }
                    column(CompanyInfo__Bank_Name_3____________CompanyInfo__Bank_Account_No__3_;CompanyInfo."Bank Name 3" + '   ' + CompanyInfo."Bank Account No. 3")
                    {
                    }
                    column(CompanyInfo__Bank_Name_4____________CompanyInfo__Bank_Account_No__4_;CompanyInfo."Bank Name 4" + '   ' + CompanyInfo."Bank Account No. 4")
                    {
                    }
                    column(TempFooterDocumentHeader__Tax_Printer_Text_1____TempFooterDocumentHeader__Tax_Printer_Text_2_;TempFooterDocumentHeader."Tax Printer Text 1" + TempFooterDocumentHeader."Tax Printer Text 2")
                    {
                    }
                    column(CodeCaption;CodeCaptionLbl)
                    {
                    }
                    column(VAT__Caption;VAT__CaptionLbl)
                    {
                    }
                    column(Amount_After_DiscountCaption;Amount_After_DiscountCaptionLbl)
                    {
                    }
                    column(Discount_AmountCaption;Discount_AmountCaptionLbl)
                    {
                    }
                    column(Discount__Caption;Discount__CaptionLbl)
                    {
                    }
                    column(AmountCaption;AmountCaptionLbl)
                    {
                    }
                    column(Unit_PriceCaption;Unit_PriceCaptionLbl)
                    {
                    }
                    column(QuantityCaption;QuantityCaptionLbl)
                    {
                    }
                    column(UOMCaption;UOMCaptionLbl)
                    {
                    }
                    column(DescriptionCaption;DescriptionCaptionLbl)
                    {
                    }
                    column(TmpDocumentHeader__No__Series_Description_Caption;TmpDocumentHeader__No__Series_Description_CaptionLbl)
                    {
                    }
                    column(TmpDocumentHeader__Document_No__Caption;TmpDocumentHeader__Document_No__CaptionLbl)
                    {
                    }
                    column(TmpDocumentHeader__Posting_Date_Caption;TmpDocumentHeader__Posting_Date_CaptionLbl)
                    {
                    }
                    column(TmpDocumentHeader__Posting_Time_Caption;TmpDocumentHeader__Posting_Time_CaptionLbl)
                    {
                    }
                    column(TmpDocumentHeader__No__Caption;TmpDocumentHeader__No__CaptionLbl)
                    {
                    }
                    column(TmpDocumentHeader_NameCaption;TmpDocumentHeader_NameCaptionLbl)
                    {
                    }
                    column(TmpDocumentHeader_ProfessionCaption;TmpDocumentHeader_ProfessionCaptionLbl)
                    {
                    }
                    column(Caption;CaptionLbl)
                    {
                    }
                    column(Caption_Control1103201144;Caption_Control1103201144Lbl)
                    {
                    }
                    column(Caption_Control1103201145;Caption_Control1103201145Lbl)
                    {
                    }
                    column(Caption_Control1103201162;Caption_Control1103201162Lbl)
                    {
                    }
                    column(TmpDocumentHeader__Vat_Registration_No__Caption;TmpDocumentHeader__Vat_Registration_No__CaptionLbl)
                    {
                    }
                    column(Caption_Control1103201167;Caption_Control1103201167Lbl)
                    {
                    }
                    column(TmpDocumentHeader_AddressCaption;TmpDocumentHeader_AddressCaptionLbl)
                    {
                    }
                    column(Caption_Control1103201170;Caption_Control1103201170Lbl)
                    {
                    }
                    column(TmpDocumentHeader__Tax_Office_Caption;TmpDocumentHeader__Tax_Office_CaptionLbl)
                    {
                    }
                    column(Caption_Control1103201109;Caption_Control1103201109Lbl)
                    {
                    }
                    column(Caption_Control1103201112;Caption_Control1103201112Lbl)
                    {
                    }
                    column(TmpDocumentHeader__Location_Address_Caption;TmpDocumentHeader__Location_Address_CaptionLbl)
                    {
                    }
                    column(TmpDocumentHeader__Ship_To_Address_Caption;TmpDocumentHeader__Ship_To_Address_CaptionLbl)
                    {
                    }
                    column(Caption_Control1103201038;Caption_Control1103201038Lbl)
                    {
                    }
                    column(TmpDocumentHeader__Ship_To_Name_Caption;TmpDocumentHeader__Ship_To_Name_CaptionLbl)
                    {
                    }
                    column(Caption_Control1103201044;Caption_Control1103201044Lbl)
                    {
                    }
                    column(TmpDocumentHeader__Transfer_Reason_Caption;TmpDocumentHeader__Transfer_Reason_CaptionLbl)
                    {
                    }
                    column(Caption_Control1103201055;Caption_Control1103201055Lbl)
                    {
                    }
                    column(TmpDocumentHeader__Payment_Method_Caption;TmpDocumentHeader__Payment_Method_CaptionLbl)
                    {
                    }
                    column(CodeCaption_Control1103201174;CodeCaption_Control1103201174Lbl)
                    {
                    }
                    column(VAT__Caption_Control1103201175;VAT__Caption_Control1103201175Lbl)
                    {
                    }
                    column(Amount_After_DiscountCaption_Control1103201176;Amount_After_DiscountCaption_Control1103201176Lbl)
                    {
                    }
                    column(Discount_AmountCaption_Control1103201177;Discount_AmountCaption_Control1103201177Lbl)
                    {
                    }
                    column(Discount__Caption_Control1103201178;Discount__Caption_Control1103201178Lbl)
                    {
                    }
                    column(AmountCaption_Control1103201179;AmountCaption_Control1103201179Lbl)
                    {
                    }
                    column(Unit_PriceCaption_Control1103201180;Unit_PriceCaption_Control1103201180Lbl)
                    {
                    }
                    column(QuantityCaption_Control1103201181;QuantityCaption_Control1103201181Lbl)
                    {
                    }
                    column(UOMCaption_Control1103201182;UOMCaption_Control1103201182Lbl)
                    {
                    }
                    column(DescriptionCaption_Control1103201183;DescriptionCaption_Control1103201183Lbl)
                    {
                    }
                    column(TmpDocumentHeader__No__Series_Description__Control1103201072Caption;TmpDocumentHeader__No__Series_Description__Control1103201072CaptionLbl)
                    {
                    }
                    column(TmpDocumentHeader__Document_No___Control1103201061Caption;TmpDocumentHeader__Document_No___Control1103201061CaptionLbl)
                    {
                    }
                    column(TmpDocumentHeader__Posting_Date__Control1103201134Caption;TmpDocumentHeader__Posting_Date__Control1103201134CaptionLbl)
                    {
                    }
                    column(TmpDocumentHeader__Posting_Time__Control1103201138Caption;TmpDocumentHeader__Posting_Time__Control1103201138CaptionLbl)
                    {
                    }
                    column(Ship_FromCaption;Ship_FromCaptionLbl)
                    {
                    }
                    column(Receive_ToCaption;Receive_ToCaptionLbl)
                    {
                    }
                    column(Caption_Control1103201274;Caption_Control1103201274Lbl)
                    {
                    }
                    column(DescriptionCaption_Control1103201275;DescriptionCaption_Control1103201275Lbl)
                    {
                    }
                    column(Caption_Control1103201278;Caption_Control1103201278Lbl)
                    {
                    }
                    column(TmpDocumentHeader_Address_Control1103201276Caption;TmpDocumentHeader_Address_Control1103201276CaptionLbl)
                    {
                    }
                    column(TmpDocumentHeader_Profession_Control1103201286Caption;TmpDocumentHeader_Profession_Control1103201286CaptionLbl)
                    {
                    }
                    column(Caption_Control1103201291;Caption_Control1103201291Lbl)
                    {
                    }
                    column(TmpDocumentHeader__Ship_To_Profession_Caption;TmpDocumentHeader__Ship_To_Profession_CaptionLbl)
                    {
                    }
                    column(Business_Partner_DetailsCaption;Business_Partner_DetailsCaptionLbl)
                    {
                    }
                    column(TmpDocumentHeader__Ship_To_Address__Control1103201313Caption;TmpDocumentHeader__Ship_To_Address__Control1103201313CaptionLbl)
                    {
                    }
                    column(TmpDocumentHeader__Ship_To_Name__Control1103201315Caption;TmpDocumentHeader__Ship_To_Name__Control1103201315CaptionLbl)
                    {
                    }
                    column(TmpDocumentHeader__Ship_To_Code_Caption;TmpDocumentHeader__Ship_To_Code_CaptionLbl)
                    {
                    }
                    column(TmpDocumentHeader__Ship_To_Vat_Registration_No__Caption;TmpDocumentHeader__Ship_To_Vat_Registration_No__CaptionLbl)
                    {
                    }
                    column(Caption_Control1103201300;Caption_Control1103201300Lbl)
                    {
                    }
                    column(TmpDocumentHeader__Vat_Registration_No___Control1103201298Caption;TmpDocumentHeader__Vat_Registration_No___Control1103201298CaptionLbl)
                    {
                    }
                    column(Caption_Control1103201303;Caption_Control1103201303Lbl)
                    {
                    }
                    column(TmpDocumentHeader__Ship_To_Tax_Office_Caption;TmpDocumentHeader__Ship_To_Tax_Office_CaptionLbl)
                    {
                    }
                    column(Caption_Control1103201307;Caption_Control1103201307Lbl)
                    {
                    }
                    column(Caption_Control1103201308;Caption_Control1103201308Lbl)
                    {
                    }
                    column(TmpDocumentHeader__Tax_Office__Control1103201305Caption;TmpDocumentHeader__Tax_Office__Control1103201305CaptionLbl)
                    {
                    }
                    column(Caption_Control1103201311;Caption_Control1103201311Lbl)
                    {
                    }
                    column(Caption_Control1103201314;Caption_Control1103201314Lbl)
                    {
                    }
                    column(Caption_Control1103201316;Caption_Control1103201316Lbl)
                    {
                    }
                    column(Caption_Control1103201318;Caption_Control1103201318Lbl)
                    {
                    }
                    column(TmpDocumentHeader__No___Control1103201264Caption;TmpDocumentHeader__No___Control1103201264CaptionLbl)
                    {
                    }
                    column(Caption_Control1103201266;Caption_Control1103201266Lbl)
                    {
                    }
                    column(Business_Partner_DetailsCaption_Control1103201142;Business_Partner_DetailsCaption_Control1103201142Lbl)
                    {
                    }
                    column(Caption_Control1103201191;Caption_Control1103201191Lbl)
                    {
                    }
                    column(TmpDocumentHeader__Location_Address__Control1103201190Caption;TmpDocumentHeader__Location_Address__Control1103201190CaptionLbl)
                    {
                    }
                    column(Caption_Control1103201194;Caption_Control1103201194Lbl)
                    {
                    }
                    column(TmpDocumentHeader__Transfer_Reason__Control1103201193Caption;TmpDocumentHeader__Transfer_Reason__Control1103201193CaptionLbl)
                    {
                    }
                    column(ISSUEDCaption;ISSUEDCaptionLbl)
                    {
                    }
                    column(RECEIPTCaption;RECEIPTCaptionLbl)
                    {
                    }
                    column(TempFooterDocumentHeader__Old_Balance_Caption;TempFooterDocumentHeader__Old_Balance_CaptionLbl)
                    {
                    }
                    column(TempFooterDocumentHeader__New_Balance_Caption;TempFooterDocumentHeader__New_Balance_CaptionLbl)
                    {
                    }
                    column(TempFooterDocumentHeader__VAT_Cat__1_Caption;TempFooterDocumentHeader__VAT_Cat__1_CaptionLbl)
                    {
                    }
                    column(TempFooterDocumentHeader__VAT_Cat__1_net_Amount_Caption;TempFooterDocumentHeader__VAT_Cat__1_net_Amount_CaptionLbl)
                    {
                    }
                    column(TempFooterDocumentHeader__VAT_Cat__1__VAT_Amount_Caption;TempFooterDocumentHeader__VAT_Cat__1__VAT_Amount_CaptionLbl)
                    {
                    }
                    column(TempFooterDocumentHeader__Document_Amount_Caption;TempFooterDocumentHeader__Document_Amount_CaptionLbl)
                    {
                    }
                    column(TempFooterDocumentHeader__Document_Discount_Amount_Caption;TempFooterDocumentHeader__Document_Discount_Amount_CaptionLbl)
                    {
                    }
                    column(TempFooterDocumentHeader__Document_Amount_After_Discount_Caption;TempFooterDocumentHeader__Document_Amount_After_Discount_CaptionLbl)
                    {
                    }
                    column(TempFooterDocumentHeader__Document_VAT_Amount_Caption;TempFooterDocumentHeader__Document_VAT_Amount_CaptionLbl)
                    {
                    }
                    column(TempFooterDocumentHeader__Document_Charges_Amount_Caption;TempFooterDocumentHeader__Document_Charges_Amount_CaptionLbl)
                    {
                    }
                    column(TempFooterDocumentHeader__Document_Charges_VAT_Caption;TempFooterDocumentHeader__Document_Charges_VAT_CaptionLbl)
                    {
                    }
                    column(TempFooterDocumentHeader__Document_Amount_Inc__VAT_Caption;TempFooterDocumentHeader__Document_Amount_Inc__VAT_CaptionLbl)
                    {
                    }
                    column(TempFooterDocumentHeader_Invoice_Caption;TempFooterDocumentHeader_Invoicelbl)
                    {
                    }
                    column(TempFooterDocument_Line_Captionl;TempFooterDocument_Linelbl)
                    {
                    }
                    column(TempFooterDocument_SumLine_Caption;TempFooterDocument_SumLinelbl)
                    {
                    }
                    column(CommentsCaption;CommentsCaptionLbl)
                    {
                    }
                    column(TempFooterDocumentHeader__Document_Tax_VAT_Amount_Caption;TempFooterDocumentHeader__Document_Tax_VAT_Amount_CaptionLbl)
                    {
                    }
                    column(TempFooterDocumentHeader__Document_Tax_Amount_Caption;TempFooterDocumentHeader__Document_Tax_Amount_CaptionLbl)
                    {
                    }
                    column(InvDiscountAmountCaption;InvDiscountAmountCaptionLbl)
                    {
                    }
                    column(CompanyInfo__Bank_Name____________CompanyInfo__Bank_Account_No__Caption;CompanyInfo__Bank_Name____________CompanyInfo__Bank_Account_No__CaptionLbl)
                    {
                    }
                    column(DocumentLoop_Number;Number)
                    {
                    }
                    column(NumberOfCurrentPage;NumberOfCurrentPage -1)
                    {
                    }
                    column(NumberOfCopies;NumberOfCopies)
                    {
                    }
                    column(NetWeight;TmpDocumentHeader."Net Weight")
                    {
                    }
                    column(PrintLogo;PrintLogo)
                    {
                    }
                    column(TempDocumentHeader_Cust_Phone_Captionlbl;TempDocumentHeader_Cust_Phone_Captionlbl)
                    {
                    }
                    column(TempDocumentHeader_Cust_Phone;TmpDocumentHeader.Phone)
                    {
                    }
                    column(TempDocumentHeader_Shipping_Agent_Captionlbl;TempDocumentHeader_Shipping_Agent_Captionlbl)
                    {
                    }
                    column(TempDocumentHeader_Shipping_Agent;TmpDocumentHeader."Shipping Agent")
                    {
                    }
                    column(Package_Label;Package_Label)
                    {
                    }
                    column(Package_Qty_Label;Package_Qty_Label)
                    {
                    }
                    column(Qty_Label;Qty_Label)
                    {
                    }
                    column(MU_Label;MU_Label)
                    {
                    }
                    dataitem(PagesLoop;"Integer")
                    {
                        DataItemTableView = SORTING(Number) ORDER(Ascending);
                        column(ShowEmptyLine;ShowEmptyLine)
                        {
                        }
                        column(DocLineType;LineType)
                        {
                        }
                        dataitem(LinesLoop;"Integer")
                        {
                            DataItemTableView = SORTING(Number) ORDER(Ascending);
                            column(LineType;FORMAT(TmpDocumentLine.Type,0,'<Number>'))
                            {
                            }
                            column(TmpDocumentLine__VAT___;TmpDocumentLine."VAT %")
                            {
                            }
                            column(TmpDocumentLine__Line_Amount_;TmpDocumentLine."Line Amount")
                            {
                            }
                            column(TmpDocumentLine__AmountAfterDiscount;TmpDocumentLine."Amount After Discount")
                            {
                            }
                            column(TmpDocumentLine__Line_Discount_Amount_;TmpDocumentLine."Line Discount Amount")
                            {
                            }
                            column(TmpDocumentLine__Line_Discount___;TmpDocumentLine."Line Discount %")
                            {
                            }
                            column(TmpDocumentLine_Amount;TmpDocumentLine.Amount)
                            {
                            }
                            column(TmpDocumentLine__Unit_Price_;TmpDocumentLine."Unit Price")
                            {
                                DecimalPlaces = 2:3;
                            }
                            column(TmpDocumentLine_Quantity;TmpDocumentLine.Quantity)
                            {
                            }
                            column(TmpDocumentLine_Description;TmpDocumentLine.Description)
                            {
                            }
                            column(TmpDocumentLine__No__;TmpDocumentLine."No.")
                            {
                            }
                            column(TmpDocumentLine__Unit_Of_Measure_;TmpDocumentLine."Unit Of Measure")
                            {
                            }
                            column(TmpDocumentLine_Description_Control1103201092;TmpDocumentLine.Description)
                            {
                            }
                            column(Temp_Disc_Line_Amount;TmpDiscSum)
                            {
                            }
                            column(LinesLoop_Number;Number)
                            {
                            }
                            column(TmpDocumentLine_Quantity_Base;TmpDocumentLine."Quantity (Base)")
                            {
                            }
                            column(TmpDocumentLine_Base_Unit_Of_Measure_;TmpDocumentLine."Base Unit of Measure")
                            {
                            }
                            column(SalesLineType;TmpDocumentLine.Type)
                            {
                            }

                            trigger OnAfterGetRecord();
                            begin
                                IF GetFirstDocumentLine THEN BEGIN
                                  TmpDocumentLine.FINDSET;
                                  GetFirstDocumentLine := FALSE;
                                END ELSE BEGIN
                                  IF TotalNumberOfLinesDone < NumberOfLines THEN BEGIN
                                    TmpDocumentLine.NEXT;
                                  END;
                                END;
                                NumberOfLinesDone += 1;
                                TotalNumberOfLinesDone += 1;
                                IF TotalNumberOfLinesDone > NumberOfLines  THEN BEGIN
                                  ShowEmptyLine := TRUE;
                                END;
                                IF ShowEmptyLine THEN
                                  CLEAR(TmpDocumentLine);
                                LineType := 1;
                            end;

                            trigger OnPreDataItem();
                            begin
                                SETRANGE(Number,1,MaxLinesPerPage);
                            end;
                        }
                        dataitem(BailmentsLoop;"Integer")
                        {
                            DataItemTableView = SORTING(Number) ORDER(Ascending);
                            column(Text001;Text001)
                            {
                                Description = 'RCGPR008884-03 Added';
                            }
                            column(BailmentLines__VAT___;BailmentLines."VAT %")
                            {
                                Description = 'RCGPR008884-03 Added';
                            }
                            column(BailmentLines__Amount_After_Discount_;BailmentLines."Amount After Discount")
                            {
                                Description = 'RCGPR008884-03 Added';
                            }
                            column(BailmentLines_Amount;BailmentLines.Amount)
                            {
                                Description = 'RCGPR008884-03 Added';
                            }
                            column(BailmentLines__Unit_Price_;BailmentLines."Unit Price")
                            {
                                Description = 'RCGPR008884-03 Added';
                            }
                            column(BailmentLines_Quantity;BailmentLines.Quantity)
                            {
                                Description = 'RCGPR008884-03 Added';
                            }
                            column(BailmentLines__Unit_Of_Measure_;BailmentLines."Unit Of Measure")
                            {
                                Description = 'RCGPR008884-03 Added';
                            }
                            column(BailmentLines_Description;BailmentLines.Description)
                            {
                                Description = 'RCGPR008884-03 Added';
                            }
                            column(BailmentLines__No__;BailmentLines."No.")
                            {
                                Description = 'RCGPR008884-03 Added';
                            }
                            column(BailmentsLoop_Number;Number)
                            {
                            }

                            trigger OnAfterGetRecord();
                            begin
                                IF (NumberOfCurrentPage-1) = NumberOfPages THEN BEGIN
                                  NumberOfLinesDone += 1;
                                  NumberOfBailmentLinesDone += 1;
                                  IF GetFirstBailmentLine THEN BEGIN
                                    BailmentLines.FINDSET;
                                    GetFirstBailmentLine := FALSE;
                                  END ELSE BEGIN
                                    IF NumberOfBailmentLinesDone > NumberOfBailments THEN BEGIN
                                      CLEAR(BailmentLines);
                                    END ELSE BEGIN
                                      BailmentLines.NEXT;
                                    END;
                                  END;
                                END ELSE
                                  CurrReport.BREAK;
                            end;

                            trigger OnPreDataItem();
                            begin
                                IF (NumberOfCurrentPage-1) = NumberOfPages THEN BEGIN
                                  IF MaxBailmentLinesPerPage = 0 THEN BEGIN
                                    CurrReport.BREAK;
                                  END;
                                  SETRANGE(Number,1,MaxBailmentLinesPerPage);
                                  NumberOfLinesDone := 0;
                                  NumberOfBailments := BailmentLines.COUNT;
                                  IF NumberOfBailments=0 THEN
                                    CurrReport.BREAK;
                                  ShowEmptyLine := FALSE;
                                  LineType := 2;
                                END ELSE
                                  CurrReport.BREAK;
                            end;
                        }

                        trigger OnAfterGetRecord();
                        begin
                            NumberOfCurrentPage += 1;
                            NumberOfLinesDone := 0;

                            IF NumberOfCurrentPage > NumberOfPages THEN BEGIN
                              TempFooterDocumentHeader.RESET;
                              TempFooterDocumentHeader.DELETEALL;
                              TempFooterDocumentHeader.INIT;
                              TempFooterDocumentHeader := TmpDocumentHeader;
                              TempFooterDocumentHeader.INSERT;
                              TempFooterDocumentHeader.FINDSET;
                            END;
                        end;

                        trigger OnPreDataItem();
                        begin
                            SETRANGE(Number,1,NumberOfPages);
                        end;
                    }
                }

                trigger OnAfterGetRecord();
                begin
                    GetFirstDocumentLine := NOT TmpDocumentLine.ISEMPTY;
                    GetFirstBailmentLine := NOT BailmentLines.ISEMPTY;
                    ShowEmptyLine := FALSE;
                    NumberOfCopies += 1;
                    NumberOfCurrentPage := 1;
                    NumberOfLinesDone := 0;
                    TotalNumberOfLinesDone := 0;
                    NumberOfBailmentLinesDone := 0;
                    IF TmpDocumentHeader."Number Of Copies" <> 0 THEN BEGIN
                      CASE Number OF
                        1: CopyDescription := TmpDocumentHeader."Document Copy 1 Descr.";
                        2: CopyDescription := TmpDocumentHeader."Document Copy 2 Descr.";
                        3: CopyDescription := TmpDocumentHeader."Document Copy 3 Descr.";
                        4: CopyDescription := TmpDocumentHeader."Document Copy 4 Descr.";
                        5: CopyDescription := TmpDocumentHeader."Document Copy 5 Descr.";
                      END;
                    END;
                end;

                trigger OnPreDataItem();
                begin
                    IF TmpDocumentHeader."Number Of Copies" <> 0 THEN BEGIN
                      SETRANGE(Number,1,TmpDocumentHeader."Number Of Copies")
                    END ELSE BEGIN
                      SETRANGE(Number,1,1);
                    END;
                    NumberOfCopies := 0;
                end;
            }

            trigger OnAfterGetRecord();
            begin
                IsTransfer := ((TmpDocumentHeader."Document Type" IN [TmpDocumentHeader."Document Type"::"Transfer Order",
                TmpDocumentHeader."Document Type"::"Transfer Shipment",TmpDocumentHeader."Document Type"::"Transfer Receipt"]));

                IF Number = 1  THEN BEGIN
                  TmpDocumentHeader.FINDSET;
                END ELSE BEGIN
                  TmpDocumentHeader.NEXT;
                END;
                IF TmpDocumentHeader."Language ID" <> 0 THEN BEGIN
                  CurrReport.LANGUAGE := TmpDocumentHeader."Language ID";
                END;
                TmpDocumentLine.SETRANGE("Document No.",TmpDocumentHeader."Document No.");
                IF (DocumentType = DocumentType::"Sales Invoice") OR (DocumentType = DocumentType::" ") THEN BEGIN
                  IF TmpDocumentLine.FINDSET THEN BEGIN
                    REPEAT
                      TmpDocumentLine."Amount After Discount" := TmpDocumentLine.Amount - TmpDocumentLine."Line Discount Amount";
                      TmpDiscSum += TmpDocumentLine."Line Discount Amount";
                      TmpDocumentLine.MODIFY;
                    UNTIL TmpDocumentLine.NEXT=0;
                  END;
                END;
                BailmentLines.SETRANGE("Document No.",TmpDocumentHeader."Document No.");
                MaxLinesPerPage := TmpDocumentHeader."Maximum Line Per Page";
                MaxBailmentLinesPerPage := TmpDocumentHeader."Maximum Bailments Per Page";
                HasBailment := NOT BailmentLines.ISEMPTY;
                NumberOfLines := TmpDocumentLine.COUNT;
                NumberOfLoops := (NumberOfLines DIV MaxLinesPerPage) * MaxLinesPerPage + (NumberOfLines MOD MaxLinesPerPage);
                IF (NumberOfLines MOD MaxLinesPerPage) <> 0 THEN BEGIN
                  NumberOfLoops += (MaxLinesPerPage - NumberOfLines MOD MaxLinesPerPage);
                END;
                NumberOfPages := NumberOfLoops DIV MaxLinesPerPage;
                IF HasBailment THEN BEGIN
                  IF MaxBailmentLinesPerPage = 0 THEN BEGIN
                    ERROR(Text002);
                  END;
                  NumberOfBailments := BailmentLines.COUNT;
                  NumberOfBailmentsLoops := (NumberOfBailments DIV MaxBailmentLinesPerPage) * MaxBailmentLinesPerPage +
                                            (NumberOfBailments MOD MaxBailmentLinesPerPage);
                  IF (NumberOfBailments MOD MaxBailmentLinesPerPage) <> 0 THEN BEGIN
                    NumberOfBailmentsLoops += (MaxBailmentLinesPerPage - NumberOfBailments MOD MaxBailmentLinesPerPage);
                  END;
                  NumberOfBailmentsPages := NumberOfBailmentsLoops DIV MaxBailmentLinesPerPage;
                  IF NumberOfBailmentsPages > NumberOfPages THEN BEGIN
                    NumberOfPages := NumberOfBailmentsPages;
                  END;
                END;
            end;

            trigger OnPreDataItem();
            begin
                SETRANGE(Number,1,TmpDocumentHeader.COUNT);
            end;
        }
    }

    requestpage
    {

        layout
        {
            area(content)
            {
                group(Options)
                {
                    CaptionML = ELL='Επιλογές',
                                ENU='Options';
                    field(DocumentType;DocumentType)
                    {
                        CaptionML = ELL='Τύπος Παραστατικού',
                                    ENU='Document Type';
                        OptionCaptionML = ELL=' ,Παραγγελίες Πωλήσεων,Τιμολόγια Πωλήσεων,Αποστολές Πωλήσεων,Πιστωτικά Τιμολόγια Πωλήσεων,Παραλαβές Επιστροφών Πωλήσεων,Παραγγελίες Αγορών,Τιμολόγια Αγορών,Παραλαβές Αγορών,Πιστωτικά Τιμολόγια Αγορών,Απ',
                                          ENU=' ,Sales Order,Sales Invoice,Sales Shipment,Sales Credit Memo,Sales Return Receipt,Purchase Order,Purchase Invoice,Purchase Receipt,Purchase Credit Memo,Purchase Return Shipment,Service Order,Service Invoice,Service Shipment,Service Credit Memo,Service Return Receipt,Transfer Order,Transfer Shipment,Transfer Receipt';

                        trigger OnValidate();
                        begin
                            DocumentNo := '';
                        end;
                    }
                    field(DocumentNo;DocumentNo)
                    {
                        CaptionML = ELL='Αρ. Παραστατικού',
                                    ENU='Document No.';

                        trigger OnLookup(Text : Text) : Boolean;
                        var
                            SalesHeader : Record "Sales Header";
                            SalesInvHeader : Record "Sales Invoice Header";
                            SalesShipmentHeader : Record "Sales Shipment Header";
                            SalesCrMemoHeader : Record "Sales Cr.Memo Header";
                            ReturnReceiptHeader : Record "Return Receipt Header";
                            PurchaseHeader : Record "Purchase Header";
                            PurchInvHeader : Record "Purch. Inv. Header";
                            PurchReceiptHeader : Record "Purch. Rcpt. Header";
                            PurchCrmemoHeader : Record "Purch. Cr. Memo Hdr.";
                            ReturnShipmentHeader : Record "Return Shipment Header";
                            "__RCGPR008993-01__" : Integer;
                            ServiceHeader : Record "Service Header";
                            ServiceInvoiceHeader : Record "Service Invoice Header";
                            ServiceShipmentHeader : Record "Service Shipment Header";
                            ServiceCrMemoHeader : Record "Service Cr.Memo Header";
                            ServiceReturnReceiptHeader : Record "Service Return Receipt Header";
                            "__RCGPR010424-01__" : Integer;
                            TransferHeader : Record "Transfer Header";
                            TransferShipmentHeader : Record "Transfer Shipment Header";
                            TransferReceiptHeader : Record "Transfer Receipt Header";
                        begin
                            CASE DocumentType OF
                              DocumentType::" " :
                                BEGIN
                                END;
                              DocumentType::"Sales Order" :
                                BEGIN
                                  SalesHeader.SETRANGE("Document Type",SalesHeader."Document Type"::Order);
                                  IF PAGE.RUNMODAL(0,SalesHeader) = ACTION::LookupOK THEN
                                    DocumentNo := SalesHeader."No.";
                                END;
                              DocumentType::"Sales Invoice" :
                                BEGIN
                                  IF PAGE.RUNMODAL(0, SalesInvHeader) = ACTION::LookupOK THEN
                                    DocumentNo := SalesInvHeader."No.";
                                END;
                              DocumentType::"Sales Shipment" :
                                BEGIN
                                  IF PAGE.RUNMODAL(0,SalesShipmentHeader) = ACTION::LookupOK THEN
                                    DocumentNo := SalesShipmentHeader."No.";
                                END;
                              DocumentType::"Sales Credit Memo" :
                                BEGIN
                                  IF PAGE.RUNMODAL(0, SalesCrMemoHeader) = ACTION::LookupOK THEN
                                    DocumentNo := SalesCrMemoHeader."No.";
                                END;
                              DocumentType::"Return Receipt" :
                                BEGIN
                                  IF PAGE.RUNMODAL(0, ReturnReceiptHeader) = ACTION::LookupOK THEN
                                    DocumentNo := ReturnReceiptHeader."No.";
                                END;
                              DocumentType::"Purchase Order":
                                BEGIN
                                  PurchaseHeader.SETRANGE("Document Type",PurchaseHeader."Document Type"::Order);
                                  IF PAGE.RUNMODAL(0,PurchaseHeader) = ACTION::LookupOK THEN
                                    DocumentNo := PurchaseHeader."No.";
                                END;
                              DocumentType::"Purchase Invoice":
                                BEGIN
                                  IF PAGE.RUNMODAL(0, PurchInvHeader) = ACTION::LookupOK THEN
                                    DocumentNo := PurchInvHeader."No.";
                                END;
                              DocumentType::"Purchase Receipt":
                                BEGIN
                                  IF PAGE.RUNMODAL(0, PurchReceiptHeader) = ACTION::LookupOK THEN
                                    DocumentNo := PurchReceiptHeader."No.";
                                END;
                              DocumentType::"Purchase Credit Memo":
                                BEGIN
                                  IF PAGE.RUNMODAL(0, PurchCrmemoHeader) = ACTION::LookupOK THEN
                                    DocumentNo := PurchCrmemoHeader."No.";
                                END;
                              DocumentType::"Return Shipment":
                                BEGIN
                                  IF PAGE.RUNMODAL(0, ReturnShipmentHeader) = ACTION::LookupOK THEN
                                    DocumentNo := ReturnShipmentHeader."No.";
                                END;
                              DocumentType::"Service Order" :
                                BEGIN
                                  ServiceHeader.SETRANGE("Document Type",ServiceHeader."Document Type"::Order);
                                  IF PAGE.RUNMODAL(0,ServiceHeader) = ACTION::LookupOK THEN
                                    DocumentNo := ServiceHeader."No.";
                                END;
                              DocumentType::"Service Invoice" :
                                BEGIN
                                  IF PAGE.RUNMODAL(0,ServiceInvoiceHeader) = ACTION::LookupOK THEN
                                    DocumentNo := ServiceInvoiceHeader."No.";
                                END;
                              DocumentType::"Service Shipment" :
                                BEGIN
                                  IF PAGE.RUNMODAL(0,ServiceShipmentHeader) = ACTION::LookupOK THEN
                                    DocumentNo := ServiceShipmentHeader."No.";
                                END;
                              DocumentType::"Service Credit Memo" :
                                BEGIN
                                  IF PAGE.RUNMODAL(0,ServiceCrMemoHeader) = ACTION::LookupOK THEN
                                    DocumentNo := ServiceCrMemoHeader."No.";
                                END;
                              DocumentType::"Service Return Receipt" :
                                BEGIN
                                  IF PAGE.RUNMODAL(0,ServiceReturnReceiptHeader) = ACTION::LookupOK THEN
                                    DocumentNo := ServiceReturnReceiptHeader."No.";
                                END;
                              DocumentType::"Transfer Order": BEGIN
                                IF PAGE.RUNMODAL(0,TransferHeader) = ACTION::LookupOK THEN BEGIN
                                  DocumentNo := TransferHeader."No.";
                                END;
                              END;
                              DocumentType::"Transfer Shipment": BEGIN
                                IF PAGE.RUNMODAL(0,TransferShipmentHeader) = ACTION::LookupOK THEN BEGIN
                                  DocumentNo := TransferShipmentHeader."No.";
                                END;
                              END;
                              DocumentType::"Transfer Receipt": BEGIN
                                IF PAGE.RUNMODAL(0,TransferReceiptHeader) = ACTION::LookupOK THEN BEGIN
                                  DocumentNo := TransferReceiptHeader."No.";
                                END;
                              END;
                            END;
                        end;
                    }
                    field(PrintLogo;PrintLogo)
                    {
                        CaptionML = ELL='Εκτ. Λογοτύπου',
                                    ENU='Print Logo';
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
    }

    trigger OnInitReport();
    begin
        PrintLogo := TRUE; //DOC IMP DB 15/09/16 -+
    end;

    trigger OnPreReport();
    begin
        EVALUATE(ReportNumber,DELSTR(CurrReport.OBJECTID(FALSE),1,7));
        CompanyInfo.GET;
        CompanyAddress[1] := CompanyInfo.Name + ', ' + CompanyInfo.Profession;
        CompanyAddress[2] := CompanyInfo.FIELDCAPTION("VAT Registration No.") + ': ' + CompanyInfo."VAT Registration No." + ', ' +
                             CompanyInfo.FIELDCAPTION("Tax Office") + ': ' + CompanyInfo."Tax Office";
        CompanyAddress[3] := CompanyInfo.FIELDCAPTION("E-Mail") + ': ' + CompanyInfo."E-Mail";
        CompanyAddress[4] := CompanyInfo.FIELDCAPTION("Phone No.") + ': ' + CompanyInfo."Phone No." + ', ' +
                             CompanyInfo.FIELDCAPTION("Fax No.") + ': ' + CompanyInfo."Fax No.";
        CompanyAddress[5] := CompanyInfo.Address + ', ' + CompanyInfo."Address 2";
        CompanyAddress[6] := CompanyInfo.City + ', '  + CompanyInfo."Post Code";
        CompanyAddress[7] := CompanyInfo.FIELDCAPTION("Registration No.") + ': ' + CompanyInfo."Registration No.";
        IF CompanyInfo."Branch 1 Address" <> '' THEN BEGIN
          CompanyAddress[8] := BranchAddress1 + ': ' + CompanyInfo."Branch 1 Address";
        END;
        IF CompanyInfo."Branch 2 Address" <> '' THEN BEGIN
          CompanyAddress[9] := BranchAddress2 + ': ' + CompanyInfo."Branch 2 Address";
        END;
        IF CompanyInfo."Branch 3 Address" <> '' THEN BEGIN
          CompanyAddress[10] := BranchAddress3 + ': ' + CompanyInfo."Branch 3 Address";
        END;
        CompanyInfo.CALCFIELDS(Picture);
        CompanyInfo.CALCFIELDS("ISO Logo"); //DOC ISO DB 25/03/2018 -+
    end;

    var
        TmpDocumentHeader : Record "Document Header" temporary;
        TmpDocumentLine : Record "Document Line" temporary;
        CompanyInfo : Record "Company Information";
        TempFooterDocumentHeader : Record "Document Header" temporary;
        BailmentLines : Record "Document Line" temporary;
        DocManagment : Codeunit "Document Management Ext";
        DocumentNo : Code[20];
        CopyDescription : Text[50];
        CompanyAddress : array [20] of Text[250];
        TmpDiscSum : Decimal;
        MaxLinesPerPage : Integer;
        NumberOfCurrentPage : Integer;
        NumberOfPages : Integer;
        NumberOfLines : Integer;
        NumberOfLoops : Integer;
        NumberOfCopies : Integer;
        NumberOfLinesDone : Integer;
        TotalNumberOfLinesDone : Integer;
        NumberOfBailments : Integer;
        NumberOfBailmentsLoops : Integer;
        NumberOfBailmentsPages : Integer;
        NumberOfBailmentLinesDone : Integer;
        MaxBailmentLinesPerPage : Integer;
        ReportNumber : Integer;
        PageNo : TextConst ELL='Σελίδα : ',ENU='Page : ';
        RegNo : TextConst ELL='Α.Μ.Α.Ε',ENU='Reg. No.';
        StdComment1 : TextConst ELL='- Τα εμπορεύματα ταξιδεύουν με κίνδυνο και ευθύνη του αγοραστή.',ENU='- Products are transported on behalf of and at the risk of the buyer';
        StdComment2 : TextConst ELL='- Σε περίπτωση καθυστέρησης πληρωμής πέρα απο τον αναφερόμενο διακανονισμό θα χρεώνεται ο νόμιμος τόκος.',ENU='- Legal interest is charged on any payment after the due date';
        StdComment3 : TextConst ELL='- Η εξόφληση γίνεται μόνο δι'' αποδείξεως εξουσιοδοτημένου προσώπου ή τραπεζικού καταθετηρίου.',ENU='- Payment Of the invoices is proven by a receipt issued by the  Company';
        StdComment4 : TextConst ELL='- Για κάθε διαφορά που θα προκύψει απο την παρούσα πώληση αρμόδια θα είναι τα δικαστήρια.',ENU='- Any disputes hereunder are referred to the Jurisdiction of the Courts';
        StdComment5 : TextConst ELL='- Ο πελάτης ενημερώθηκε για τις ιδιότητες των υλικών που παραλαμβάνει.',ENU='- The client has been informed about the properties of delivered items.';
        StdComment6 : TextConst ELL='- Σας ενημερώνουμε οτι βάση του Ν.2472/97 τηρούμε τα προσωπικά σας στοιχεία στο αρχείο μας και έχετε πρόσβαση σε αυτά σύμφωνα με τον νόμο.',ENU='- We inform you that according to law N.2472/97 we archive your personal information and you have the right to access them. ';
        BranchAddress1 : TextConst ELL='Διεύθυνση Υποκαταστήματος 1',ENU='Branch 1 Address';
        BranchAddress2 : TextConst ELL='Διεύθυνση Υποκαταστήματος 2',ENU='Branch 2 Address';
        BranchAddress3 : TextConst ELL='Διεύθυνση Υποκαταστήματος 3',ENU='Branch 3 Address';
        Text001 : TextConst ELL='Εγγυοδοσία',ENU='Bailments';
        LineType : Integer;
        ShowEmptyLine : Boolean;
        GetFirstDocumentLine : Boolean;
        GetFirstBailmentLine : Boolean;
        IsTransfer : Boolean;
        HasBailment : Boolean;
        Text002 : TextConst ELL='Πρέπει να ορίσετε το πεδίο Γραμμές Εγγυοδοσίας Ανά Σελίδα στον πίνακα Επιλογή Εκτυπώσεων',ENU='You must set field Bailments Per Page at table Report Selections';
        CodeCaptionLbl : TextConst ELL='Κωδικός',ENU='Code';
        VAT__CaptionLbl : TextConst ELL='ΦΠΑ %',ENU='VAT %';
        Amount_After_DiscountCaptionLbl : TextConst ELL='Αξία μετά Έκπτωσης',ENU='Amount After Discount';
        Discount_AmountCaptionLbl : TextConst ELL='Αξία Έκπτωσης',ENU='Discount Amount';
        Discount__CaptionLbl : TextConst ELL='Έκπτωση %',ENU='Discount %';
        AmountCaptionLbl : TextConst ELL='Αξία',ENU='Amount';
        Unit_PriceCaptionLbl : TextConst ELL='Τιμή Μονάδος',ENU='Unit Price';
        QuantityCaptionLbl : TextConst ELL='Ποσότητα',ENU='Quantity';
        UOMCaptionLbl : TextConst ELL='Μ.Μ.',ENU='UOM';
        DescriptionCaptionLbl : TextConst ELL='Περιγραφή',ENU='Description';
        TmpDocumentHeader__No__Series_Description_CaptionLbl : TextConst ELL='Είδος Παραστατικού',ENU='Document Type';
        TmpDocumentHeader__Document_No__CaptionLbl : TextConst ELL='Αρ. Παραστατικού',ENU='Document No.';
        TmpDocumentHeader__Posting_Date_CaptionLbl : TextConst ELL='Ημερομηνία',ENU='Date';
        TmpDocumentHeader__Posting_Time_CaptionLbl : TextConst ELL='Ώρα',ENU='Time';
        TmpDocumentHeader__No__CaptionLbl : TextConst ELL='Κωδικός',ENU='Code';
        TmpDocumentHeader_NameCaptionLbl : TextConst ELL='Επωνυμία',ENU='Name';
        TmpDocumentHeader_ProfessionCaptionLbl : TextConst ELL='Επάγγελμα',ENU='Profession';
        CaptionLbl : TextConst ELL=':',ENU=':';
        Caption_Control1103201144Lbl : TextConst ELL=':',ENU=':';
        Caption_Control1103201145Lbl : TextConst ELL=':',ENU=':';
        Caption_Control1103201162Lbl : TextConst ELL=':',ENU=':';
        TmpDocumentHeader__Vat_Registration_No__CaptionLbl : TextConst ELL='ΑΦΜ',ENU='VAT Reg. No.';
        Caption_Control1103201167Lbl : TextConst ELL=':',ENU=':';
        TmpDocumentHeader_AddressCaptionLbl : TextConst ELL='Διεύθυνση',ENU='Address';
        Caption_Control1103201170Lbl : TextConst ELL=':',ENU=':';
        TmpDocumentHeader__Tax_Office_CaptionLbl : TextConst ELL='ΔΟΥ',ENU='Tax Office';
        Caption_Control1103201109Lbl : TextConst ELL=':',ENU=':';
        Caption_Control1103201112Lbl : TextConst ELL=':',ENU=':';
        TmpDocumentHeader__Location_Address_CaptionLbl : TextConst ELL='Τόπος Αποστολής',ENU='Location Address';
        TmpDocumentHeader__Ship_To_Address_CaptionLbl : TextConst ELL='Τόπος Προορισμού',ENU='Ship-to Address';
        Caption_Control1103201038Lbl : TextConst ELL=':',ENU=':';
        TmpDocumentHeader__Ship_To_Name_CaptionLbl : TextConst ELL='Προορισμός',ENU='Ship-to Name';
        Caption_Control1103201044Lbl : TextConst ELL=':',ENU=':';
        TmpDocumentHeader__Transfer_Reason_CaptionLbl : TextConst ELL='Σκοπός Διακίνησης',ENU='Transfer Reason';
        Caption_Control1103201055Lbl : TextConst ELL=':',ENU=':';
        TmpDocumentHeader__Payment_Method_CaptionLbl : TextConst ELL='Τρόπος Πληρωμής',ENU='Payment Method';
        CodeCaption_Control1103201174Lbl : TextConst ELL='Κωδικός',ENU='Code';
        VAT__Caption_Control1103201175Lbl : TextConst ELL='ΦΠΑ %',ENU='VAT %';
        Amount_After_DiscountCaption_Control1103201176Lbl : TextConst ELL='Αξία μετά Έκπτωσης',ENU='Amount After Discount';
        Discount_AmountCaption_Control1103201177Lbl : TextConst ELL='Αξία Έκπτωσης',ENU='Discount Amount';
        Discount__Caption_Control1103201178Lbl : TextConst ELL='Έκπτωση %',ENU='Discount %';
        AmountCaption_Control1103201179Lbl : TextConst ELL='Αξία',ENU='Amount';
        Unit_PriceCaption_Control1103201180Lbl : TextConst ELL='Τιμή Μονάδος',ENU='Unit Price';
        QuantityCaption_Control1103201181Lbl : TextConst ELL='Ποσότητα',ENU='Quantity';
        UOMCaption_Control1103201182Lbl : TextConst ELL='Μ.Μ.',ENU='UOM';
        DescriptionCaption_Control1103201183Lbl : TextConst ELL='Περιγραφή',ENU='Description';
        TmpDocumentHeader__No__Series_Description__Control1103201072CaptionLbl : TextConst ELL='Είδος Παραστατικού',ENU='Document Type';
        TmpDocumentHeader__Document_No___Control1103201061CaptionLbl : TextConst ELL='Αρ. Παραστατικού',ENU='Document No.';
        TmpDocumentHeader__Posting_Date__Control1103201134CaptionLbl : TextConst ELL='Ημερομηνία',ENU='Date';
        TmpDocumentHeader__Posting_Time__Control1103201138CaptionLbl : TextConst ELL='Ώρα',ENU='Time';
        Ship_FromCaptionLbl : TextConst ELL='Αποστολή Από',ENU='Ship From';
        Receive_ToCaptionLbl : TextConst ELL='Παραλαβή Σε',ENU='Receive To';
        Caption_Control1103201274Lbl : TextConst ELL=':',ENU=':';
        DescriptionCaption_Control1103201275Lbl : TextConst ELL='Περιγραφή',ENU='Description';
        Caption_Control1103201278Lbl : TextConst ELL=':',ENU=':';
        TmpDocumentHeader_Address_Control1103201276CaptionLbl : TextConst ELL='Διεύθυνση',ENU='Address';
        TmpDocumentHeader_Profession_Control1103201286CaptionLbl : TextConst ELL='Επάγγελμα',ENU='Profession';
        Caption_Control1103201291Lbl : TextConst ELL=':',ENU=':';
        TmpDocumentHeader__Ship_To_Profession_CaptionLbl : TextConst ELL='Επάγγελμα',ENU='Profession';
        Business_Partner_DetailsCaptionLbl : TextConst ELL='Στοιχεία Συναλλασσόμενου',ENU='Business Partner Details';
        TmpDocumentHeader__Ship_To_Address__Control1103201313CaptionLbl : TextConst ELL='Διεύθυνση',ENU='Address';
        TmpDocumentHeader__Ship_To_Name__Control1103201315CaptionLbl : TextConst ELL='Επωνυμία',ENU='Name';
        TmpDocumentHeader__Ship_To_Code_CaptionLbl : TextConst ELL='Κωδικός',ENU='Code';
        TmpDocumentHeader__Ship_To_Vat_Registration_No__CaptionLbl : TextConst ELL='ΑΦΜ',ENU='VAT Reg. No.';
        Caption_Control1103201300Lbl : TextConst ELL=':',ENU=':';
        TmpDocumentHeader__Vat_Registration_No___Control1103201298CaptionLbl : TextConst ELL='ΑΦΜ',ENU='VAT Reg. No.';
        Caption_Control1103201303Lbl : TextConst ELL=':',ENU=':';
        TmpDocumentHeader__Ship_To_Tax_Office_CaptionLbl : TextConst ELL='ΔΟΥ',ENU='Tax Office';
        Caption_Control1103201307Lbl : TextConst ELL=':',ENU=':';
        Caption_Control1103201308Lbl : TextConst ELL=':',ENU=':';
        TmpDocumentHeader__Tax_Office__Control1103201305CaptionLbl : TextConst ELL='ΔΟΥ',ENU='Tax Office';
        Caption_Control1103201311Lbl : TextConst ELL=':',ENU=':';
        Caption_Control1103201314Lbl : TextConst ELL=':',ENU=':';
        Caption_Control1103201316Lbl : TextConst ELL=':',ENU=':';
        Caption_Control1103201318Lbl : TextConst ELL=':',ENU=':';
        TmpDocumentHeader__No___Control1103201264CaptionLbl : TextConst ELL='Κωδικός',ENU='Code';
        Caption_Control1103201266Lbl : TextConst ELL=':',ENU=':';
        Business_Partner_DetailsCaption_Control1103201142Lbl : TextConst ELL='Στοιχεία Συναλλασσόμενου',ENU='Business Partner Details';
        Caption_Control1103201191Lbl : TextConst ELL=':',ENU=':';
        TmpDocumentHeader__Location_Address__Control1103201190CaptionLbl : TextConst ELL='Αποθήκη Μεταφοράς',ENU='In Transit Location';
        Caption_Control1103201194Lbl : TextConst ELL=':',ENU=':';
        TmpDocumentHeader__Transfer_Reason__Control1103201193CaptionLbl : TextConst ELL='Σκοπός Διακίνησης',ENU='Transfer Reason';
        ISSUEDCaptionLbl : TextConst ELL='ΕΚΔΟΣΗ',ENU='ISSUED';
        RECEIPTCaptionLbl : TextConst ELL='ΠΑΡΑΛΑΒΗ',ENU='RECEIPT';
        TempFooterDocumentHeader__Old_Balance_CaptionLbl : TextConst ELL='Προηγ. Υπόλ..',ENU='Prev. Balance';
        TempFooterDocumentHeader__New_Balance_CaptionLbl : TextConst ELL='Νέο Υπόλ.',ENU='New Balance';
        TempFooterDocumentHeader__VAT_Cat__1_CaptionLbl : TextConst ELL='ΦΠΑ %',ENU='VAT %';
        TempFooterDocumentHeader__VAT_Cat__1_net_Amount_CaptionLbl : TextConst ELL='Καθαρή Αξία',ENU='Net Amount';
        TempFooterDocumentHeader__VAT_Cat__1__VAT_Amount_CaptionLbl : TextConst ELL='Αξία ΦΠΑ',ENU='VAT Amount';
        TempFooterDocumentHeader__Document_Amount_CaptionLbl : TextConst ELL='Σύνολο Αξίας',ENU='Sum Amount';
        TempFooterDocumentHeader__Document_Discount_Amount_CaptionLbl : TextConst ELL='Σύνολο Έκπτωσης',ENU='Sum Discount';
        TempFooterDocumentHeader__Document_Amount_After_Discount_CaptionLbl : TextConst ELL='Σύνολο Μετά Εκπτ.',ENU='Sum After Disc.';
        TempFooterDocumentHeader__Document_VAT_Amount_CaptionLbl : TextConst ELL='Σύνολο ΦΠΑ',ENU='Sum VAT';
        TempFooterDocumentHeader__Document_Charges_Amount_CaptionLbl : TextConst ELL='Σύνολο Λοιπής Αξίας',ENU='Sum Other Amount';
        TempFooterDocumentHeader__Document_Charges_VAT_CaptionLbl : TextConst ELL='Σύνολο ΦΠΑ Λοιπής',ENU='Sum Other VAT';
        TempFooterDocumentHeader__Document_Amount_Inc__VAT_CaptionLbl : TextConst ELL='Τελική Αξία',ENU='Final Amount';
        CommentsCaptionLbl : TextConst ELL='Παρατηρήσεις',ENU='Comments';
        TempFooterDocumentHeader__Document_Tax_VAT_Amount_CaptionLbl : TextConst ELL='Σύνολο ΦΠΑ Φόρων',ENU='Sum Tax VAT';
        TempFooterDocumentHeader__Document_Tax_Amount_CaptionLbl : TextConst ELL='Σύνολο Φόρων',ENU='Sum Tax Amount';
        InvDiscountAmountCaptionLbl : TextConst ELL='Αξία Έκπτωσης Τιμολογίου',ENU='Invoice Discount Amount';
        CompanyInfo__Bank_Name____________CompanyInfo__Bank_Account_No__CaptionLbl : TextConst ELL='Τραπεζικός Λογαριασμός',ENU='Bank Account';
        TempFooterDocumentHeader_Invoicelbl : TextConst ELL='Έκπτωση Τιμολογίου',ENU='Discount Invoice';
        TempFooterDocument_Linelbl : TextConst ELL='Έκπτωση Γραμμής ',ENU='Discount Line';
        TempFooterDocument_SumLinelbl : TextConst ELL='Σύνολο Μετά Έκπτ. Γρ.',ENU='Sum After Disc. Line';
        DocumentType : Option " ","Sales Order","Sales Invoice","Sales Shipment","Sales Credit Memo","Return Receipt","Purchase Order","Purchase Invoice","Purchase Receipt","Purchase Credit Memo","Return Shipment","Service Order","Service Invoice","Service Shipment","Service Credit Memo","Service Return Receipt","Transfer Order","Transfer Shipment","Transfer Receipt";
        PrintLogo : Boolean;
        TaxLine : Text;
        TempDocumentHeader_Cust_Phone_Captionlbl : TextConst ELL='Τηλέφωνο',ENU='Phone';
        TempDocumentHeader_Shipping_Agent_Captionlbl : TextConst ELL='Μεταφ. Εταιρεία',ENU='Shipping Agent';
        Package_Label : TextConst ELL='Συσκ.',ENU='Package';
        Package_Qty_Label : TextConst ELL='Ποσ. Συσκ.',ENU='Package Qty';
        MU_Label : TextConst ELL='ΜΜ',ENU='MU';
        Qty_Label : TextConst ELL='Ποσ.',ENU='Qty';
}

